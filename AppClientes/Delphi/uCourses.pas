unit uCourses;

interface

uses
  system.Generics.Collections, system.JSON;

type
  TProduit = class
  private
    FQuantite: integer;
    FProduit: string;
    procedure SetProduit(const Value: string);
    procedure SetQuantite(const Value: integer);
  public
    property Produit: string read FProduit write SetProduit;
    property Quantite: integer read FQuantite write SetQuantite;
    constructor Create(AProduit: string; AQuantite: integer);
  end;

  TProduitList = class(TObjectList<TProduit>)
  public
    constructor Create;
    procedure Modifie(AProduit: string; AQuantite: integer;
      AjouteAHistorique: boolean = true);
    procedure SaveToFile;
    procedure LoadFromFile;
    procedure LoadFromJSONArray(ACourses: TJSONArray);
    procedure AppliqueModifications(AModifs: TJSONArray);
    function ChercheProduit(AProduit: string): TProduit;
  end;

  TModifsASynchroniser = class(TObjectQueue<TProduit>)
  public
    constructor Create;
    procedure AjouteModification(AProduit: string; AQuantite: integer);
    procedure SaveToFile;
    procedure LoadFromFile;
    function SaveToJSONArray: TJSONArray;
  end;

var
  Courses: TProduitList;
  LogModifs: TModifsASynchroniser;

function getDossierDeStockage: string;

implementation

uses
  system.SysUtils, system.IOUtils;

function getDossierDeStockage: string;
begin
  result := tpath.combine(tpath.GetDocumentsPath,
    tpath.combine('ESILV-WebDevelopment', 'ListeCourses'));
{$IF Defined(CPU32BITS)}
  result := result + '-32';
{$ELSE IF Defined(CPU64BITS)}
  result := result + '-64';
{$ENDIF}
{$IFDEF DEBUG}
  result := result + '-debug';
{$ENDIF}
  if not tdirectory.Exists(result) then
    tdirectory.CreateDirectory(result);
end;

{ TProduit }

constructor TProduit.Create(AProduit: string; AQuantite: integer);
begin
  inherited Create;
  Produit := AProduit;
  Quantite := AQuantite;
end;

procedure TProduit.SetProduit(const Value: string);
begin
  FProduit := Value;
end;

procedure TProduit.SetQuantite(const Value: integer);
begin
  FQuantite := Value;
end;

{ TProduitList }

procedure TProduitList.AppliqueModifications(AModifs: TJSONArray);
var
  JSV: TJSONValue;
  JSO: TJSONObject;
  ProduitLib: string;
  Quantite: integer;
  Produit: TProduit;
begin
  // Chargement des données provenant du tableau JSON
  if assigned(AModifs) and (AModifs.Count > 0) then
    for JSV in AModifs do
      if JSV is TJSONObject then
      begin
        JSO := JSV as TJSONObject;
        if JSO.TryGetValue<string>('produit', ProduitLib) and
          JSO.TryGetValue<integer>('qte', Quantite) then
        begin
          Produit := ChercheProduit(ProduitLib);
          if assigned(Produit) then
            Produit.Quantite := Produit.Quantite + Quantite
          else
            Add(TProduit.Create(ProduitLib, Quantite));
        end;
      end;
  // Enregistrement de la nouvelle liste
  SaveToFile;
end;

function TProduitList.ChercheProduit(AProduit: string): TProduit;
var
  i: integer;
begin
  result := nil;
  for i := 0 to Count - 1 do
    if items[i].Produit.tolower = AProduit.tolower then
    begin
      result := items[i];
      break;
    end;
end;

constructor TProduitList.Create;
begin
  inherited Create;
  LoadFromFile;
end;

procedure TProduitList.LoadFromFile;
var
  JSA: TJSONArray;
  JSV: TJSONValue;
  JSO: TJSONObject;
  Produit: string;
  Quantite: integer;
begin
  clear;
  if tfile.Exists(tpath.combine(getDossierDeStockage, 'courses.dat')) then
    try
      JSA := TJSONArray.ParseJSONValue
        (tfile.ReadAllText(tpath.combine(getDossierDeStockage, 'courses.dat')))
        as TJSONArray;
      if assigned(JSA) and (JSA.Count > 0) then
        for JSV in JSA do
          if JSV is TJSONObject then
          begin
            JSO := JSV as TJSONObject;
            if JSO.TryGetValue<string>('p', Produit) and
              JSO.TryGetValue<integer>('q', Quantite) then
              Modifie(Produit, Quantite, false);
          end;
    finally
      JSA.Free;
    end;
end;

procedure TProduitList.LoadFromJSONArray(ACourses: TJSONArray);
var
  JSV: TJSONValue;
  JSO: TJSONObject;
  Produit: string;
  Quantite: integer;
begin
  // Effacement de la liste
  clear;
  // Chargement des données provenant du tableau JSON
  if assigned(ACourses) and (ACourses.Count > 0) then
    for JSV in ACourses do
      if JSV is TJSONObject then
      begin
        JSO := JSV as TJSONObject;
        if JSO.TryGetValue<string>('produit', Produit) and
          JSO.TryGetValue<integer>('qte', Quantite) then
          Modifie(Produit, Quantite, false);
      end;
  // Enregistrement de la nouvelle liste
  SaveToFile;
  // Réinitialisation de la log des modifs
  LogModifs.clear;
  // Enregistrement de la log de modifications vidée
  LogModifs.SaveToFile;
end;

procedure TProduitList.Modifie(AProduit: string; AQuantite: integer;
  AjouteAHistorique: boolean);
var
  Produit: TProduit;
begin
  // Chercher si le produit est dans la liste
  Produit := ChercheProduit(AProduit);

  if assigned(Produit) then
  begin // Le Produit existe => modification
    // Enregistrer la différence avec la valeur précédente au niveau de la log
    if AjouteAHistorique then
      LogModifs.AjouteModification(AProduit, AQuantite - Produit.Quantite);

    // Modifie le produit dans la liste des courses
    Produit.Quantite := AQuantite;
  end
  else
  begin // Le Produit n'existe pas => ajout
    // Enregistrer la quanté au niveau de la log
    if AjouteAHistorique then
      LogModifs.AjouteModification(AProduit, AQuantite);

    // Ajoute le produit à la liste des courses
    Add(TProduit.Create(AProduit, AQuantite));
  end;

  // Sauvegarder la liste
  SaveToFile;

end;

procedure TProduitList.SaveToFile;
var
  JSA: TJSONArray;
  i: integer;
begin
  JSA := TJSONArray.Create;
  try
    for i := 0 to Count - 1 do
      if items[i].Quantite <> 0 then
        JSA.Add(TJSONObject.Create.AddPair('p', items[i].Produit).AddPair('q',
          items[i].Quantite));
    tfile.WriteAllText(tpath.combine(getDossierDeStockage, 'courses.dat'),
      JSA.ToJSON);
  finally
    JSA.Free;
  end;
end;

{ TModifsASynchroniser }

procedure TModifsASynchroniser.AjouteModification(AProduit: string;
  AQuantite: integer);
begin
  // On ajoute la modification dans la file d'attente
  Enqueue(TProduit.Create(AProduit, AQuantite));
  // Sauvegarde la liste des modifications
  SaveToFile;
end;

constructor TModifsASynchroniser.Create;
begin
  inherited Create;
  LoadFromFile;
end;

procedure TModifsASynchroniser.LoadFromFile;
var
  JSA: TJSONArray;
  JSV: TJSONValue;
  JSO: TJSONObject;
  Produit: string;
  Quantite: integer;
begin
  clear;
  if tfile.Exists(tpath.combine(getDossierDeStockage, 'logmodifs.dat')) then
    try
      JSA := TJSONArray.ParseJSONValue
        (tfile.ReadAllText(tpath.combine(getDossierDeStockage, 'logmodifs.dat'))
        ) as TJSONArray;
      if assigned(JSA) and (JSA.Count > 0) then
        for JSV in JSA do
          if JSV is TJSONObject then
          begin
            JSO := JSV as TJSONObject;
            if JSO.TryGetValue<string>('produit', Produit) and
              JSO.TryGetValue<integer>('qte', Quantite) then
              AjouteModification(Produit, Quantite);
          end;
    finally
      JSA.Free;
    end;
end;

procedure TModifsASynchroniser.SaveToFile;
var
  JSA: TJSONArray;
  i: integer;
begin
  JSA := SaveToJSONArray;
  try
    tfile.WriteAllText(tpath.combine(getDossierDeStockage, 'logmodifs.dat'),
      JSA.ToJSON);
  finally
    JSA.Free;
  end;
end;

function TModifsASynchroniser.SaveToJSONArray: TJSONArray;
var
  i: integer;
begin
  result := TJSONArray.Create;
  for i := 0 to Count - 1 do
    if List[i].Quantite <> 0 then
      result.Add(TJSONObject.Create.AddPair('produit', List[i].Produit)
        .AddPair('qte', List[i].Quantite));
end;

initialization

Courses := TProduitList.Create;
LogModifs := TModifsASynchroniser.Create;

finalization

LogModifs.Free;
Courses.Free;

end.
