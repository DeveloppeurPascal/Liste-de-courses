unit uDM;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  FireDAC.Stan.StorageBin, System.json;

type
  Tdm = class(TDataModule)
    tabCourses: TFDMemTable;
    tabClients: TFDMemTable;
    tabLogModifs: TFDMemTable;
    tabClientsid: TStringField;
    tabCoursesproduit: TStringField;
    tabCoursesquantite: TIntegerField;
    tabLogModifssequence: TIntegerField;
    tabLogModifsid: TStringField;
    tabLogModifsproduit: TStringField;
    tabLogModifsquantite: TIntegerField;
    FDStanStorageBinLink1: TFDStanStorageBinLink;

    procedure DataModuleCreate(Sender: TObject);
  private
    { Déclarations privées }

    /// <summary>
    /// Retourne le dossier dans lequel sont stockés les données
    /// </summary>
    function getDossierDeStockage: string;

    /// <summary>
    /// Retourne le numéro de séquence le plus élevé de la log des modifs
    /// </summary>
    function getMaxNumeroSequence: Integer;
  public
    { Déclarations publiques }

    /// <summary>
    /// Permet de s'assurer qu'un ID est bien dans la liste des clients
    ///
    /// Retourne True si l'ID est dans la table "clients"
    /// Retourne False dans le cas contraire
    /// </summary>
    function isClient(id: string): boolean;

    /// <summary>
    /// Retourne un ID unique pour l'enregistrement d'un nouveau client
    /// </summary>
    function getNewClientID: string;

    /// <summary>
    /// Retourne la liste de courses actuele avec le numéro de séquence pris en charge
    /// </summary>
    procedure getCourses(out courses: tjsonarray; out sequence: Integer);

    /// <summary>
    /// Prend en compte les modifications demandées par le client "id"
    /// </summary>
    procedure EnregistreModifications(id: string; chg: tjsonarray);

    /// <summary>
    /// Retourne la liste des changements effectués par les autres clients que celui ayant cet "id" à partir du numéro de séquence suivant
    /// Retourne également le plus grand numéro de séquence traité en sortie
    /// </summary>
    procedure getLogModifs(id: string; SequenceEnEntree: Integer;
      out chg: tjsonarray; out SequenceEnSortie: Integer);
  end;

var
  dm: Tdm;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}
{$R *.dfm}

uses
  System.IOUtils;

procedure Tdm.DataModuleCreate(Sender: TObject);
var
  folder: string;
begin
  folder := getDossierDeStockage;
  writeln('Données stockées dans le dossier :');
  writeln(folder);

  if tfile.Exists(tpath.combine(folder, 'courses.bin')) then
    tabCourses.LoadFromFile(tpath.combine(folder, 'courses.bin'));
  tabCourses.Open;

  if tfile.Exists(tpath.combine(folder, 'clients.bin')) then
    tabClients.LoadFromFile(tpath.combine(folder, 'clients.bin'));
  tabClients.Open;

  if tfile.Exists(tpath.combine(folder, 'logmodifs.bin')) then
    tabLogModifs.LoadFromFile(tpath.combine(folder, 'logmodifs.bin'));
  tabLogModifs.Open;
end;

procedure Tdm.EnregistreModifications(id: string; chg: tjsonarray);
var
  jsv: tjsonvalue;
  jso: tjsonobject;
  produit: string;
  quantite: Integer;
  sequence: Integer;
begin
  if id.IsEmpty then
    exit;
  if (not assigned(chg)) or (chg.Count < 1) then
    exit;
  monitorenter(tabCourses);
  try
    monitorenter(tabLogModifs);
    try
      sequence := getMaxNumeroSequence + 1;

      for jsv in chg do
        IF assigned(jsv) and (jsv is tjsonobject) then
        begin
          jso := jsv as tjsonobject;
          if (jso.TryGetValue<string>('produit', produit) and
            jso.TryGetValue<Integer>('qte', quantite)) then
          begin
            // on modifie le produit dans la liste de courses ou on l'ajoute
            tabCourses.First;
            while not(tabCourses.Eof or (tabCourses.FieldByName('produit')
              .AsString.ToLower = produit.ToLower)) do
              tabCourses.Next;
            if tabCourses.Eof then
            begin // produit absent => on l'ajoute
              tabCourses.Append;
              tabCourses.FieldByName('produit').AsString := produit;
              tabCourses.FieldByName('quantite').Asinteger := quantite;
              tabCourses.post;
            end
            else
            begin // produit présent => on change sa quantité
              tabCourses.Edit;
              tabCourses.FieldByName('quantite').Asinteger :=
                tabCourses.FieldByName('quantite').Asinteger + quantite;
              tabCourses.post;
            end;

            // on ajoute la modification dans la log des modifications
            tabLogModifs.Append;
            tabLogModifs.FieldByName('id').AsString := id;
            tabLogModifs.FieldByName('sequence').Asinteger := sequence;
            tabLogModifs.FieldByName('produit').AsString := produit;
            tabLogModifs.FieldByName('quantite').Asinteger := quantite;
            tabLogModifs.post;
          end;
        end;
      tabCourses.SaveToFile(tpath.combine(getDossierDeStockage, 'courses.bin'));
      tabLogModifs.SaveToFile(tpath.combine(getDossierDeStockage,
        'logmodifs.bin'));
    finally
      monitorexit(tabLogModifs);
    end;
  finally
    monitorexit(tabCourses);
  end;
end;

function Tdm.getMaxNumeroSequence: Integer;
begin
  result := -1;
  tabLogModifs.First;
  while not tabLogModifs.Eof do
  begin
    if result < tabLogModifs.FieldByName('sequence').Asinteger then
      result := tabLogModifs.FieldByName('sequence').Asinteger;
    tabLogModifs.Next;
  end;
end;

procedure Tdm.getCourses(out courses: tjsonarray; out sequence: Integer);
begin
  monitorenter(tabCourses);
  try
    monitorenter(tabLogModifs);
    try
      // Récupère la liste des courses
      courses := tjsonarray.Create;
      tabCourses.First;
      while not tabCourses.Eof do
      begin
        if tabCourses.FieldByName('quantite').Asinteger <> 0 then
          courses.Add(tjsonobject.Create.AddPair('produit',
            tabCourses.FieldByName('produit').AsString).AddPair('qte',
            tabCourses.FieldByName('quantite').Asinteger));
        tabCourses.Next;
      end;
      // Récupère le dernier numéro de séquence utilisé pour créer la liste de courses
      sequence := getMaxNumeroSequence;
    finally
      monitorexit(tabLogModifs);
    end;
  finally
    monitorexit(tabCourses);
  end;
end;

function Tdm.getDossierDeStockage: string;
begin
  result := tpath.combine(tpath.GetDocumentsPath,
    tpath.combine('ESILV-WebDevelopment', 'ListeCoursesServeur'));
  if not tdirectory.Exists(result) then
    tdirectory.CreateDirectory(result);
end;

procedure Tdm.getLogModifs(id: string; SequenceEnEntree: Integer;
  out chg: tjsonarray; out SequenceEnSortie: Integer);
begin
  chg := tjsonarray.Create;
  SequenceEnSortie := SequenceEnEntree;

  monitorenter(tabLogModifs);
  try
    tabLogModifs.First;
    while not tabLogModifs.Eof do
    begin
      if (tabLogModifs.FieldByName('id').AsString <> id) and
        (tabLogModifs.FieldByName('sequence').Asinteger > SequenceEnEntree) then
      begin
        if (SequenceEnSortie < tabLogModifs.FieldByName('sequence').Asinteger)
        then
          SequenceEnSortie := tabLogModifs.FieldByName('sequence').Asinteger;
        chg.Add(tjsonobject.Create.AddPair('produit',
          tabLogModifs.FieldByName('produit').AsString).AddPair('qte',
          tabLogModifs.FieldByName('quantite').Asinteger));
      end;
      tabLogModifs.Next;
    end;
  finally
    monitorexit(tabLogModifs);
  end;
end;

function Tdm.getNewClientID: string;
var
  i: Integer;
  nb: Integer;
begin
  repeat
    result := '';
    for i := 1 to 50 do
    begin
      nb := random(26 + 26 + 10);
      case nb of
        0 .. 9: // chiffres de 0 à 9
          result := result + chr(ord('0') + nb);
        (10 + 0) .. (10 + 25): // lettres de a à z
          result := result + chr(ord('a') + nb - 10);
        (10 + 26 + 0) .. (10 + 26 + 25): // lettres de A à Z
          result := result + chr(ord('A') + nb - 10 - 26);
      end;
    end;
  until not isClient(result);
  monitorenter(tabClients);
  try
    tabClients.Append;
    tabClients.FieldByName('id').AsString := result;
    tabClients.post;
    tabClients.SaveToFile(tpath.combine(getDossierDeStockage, 'clients.bin'));
  finally
    monitorexit(tabClients);
  end;
end;

function Tdm.isClient(id: string): boolean;
begin
  result := false;
  monitorenter(tabClients);
  try
    tabClients.First;
    while not(tabClients.Eof or (tabClients.FieldByName('id').AsString = id)) do
      tabClients.Next;
    result := not tabClients.Eof;
  finally
    monitorexit(tabClients);
  end;
end;

initialization

dm := Tdm.Create(nil);

finalization

dm.Free;

end.
