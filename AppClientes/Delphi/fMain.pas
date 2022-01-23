unit fMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.StdCtrls, FMX.Edit, FMX.Controls.Presentation, FMX.EditBox, FMX.SpinBox,
  FMX.Objects;

type
  TfrmMain = class(TForm)
    lblURLAPIListeCourses: TLabel;
    edtURLAPIListeCourses: TEdit;
    btnSynchronisation: TButton;
    vsbListeCourses: TVertScrollBox;
    gbListeCourses: TGroupBox;
    btnAjoutProduit: TButton;
    aniBlocageEcran: TAniIndicator;
    rectBlocageEcran: TRectangle;
    zoneBlocageEcran: TLayout;
    procedure btnSynchronisationClick(Sender: TObject);
    procedure btnAjoutProduitClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FURLAPIServeurListeCourses: string;
    FIDClient: string;
    FSequenceModifsServeur: integer;
    procedure SetIDClient(const Value: string);
    procedure SetSequenceModifsServeur(const Value: integer);
    procedure SetURLAPIServeurListeCourses(const Value: string);
    function getIDClient: string;
    function getSequenceModifsServeur: integer;
    function getURLAPIServeurListeCourses: string;
    { Déclarations privées }
    /// <summary>
    /// Applique la modication de quantité pour un produit
    /// </summary>
    procedure ChangeQuantiteSurProduit(Sender: TObject);

    /// <summary>
    /// Ajoute un duo Label (=> produit) / Edit (=> quantité) dans la zone de scroll
    /// </summary>
    procedure AjouteProduitEnSaisie(AProduit: string; AQuantite: integer);

    /// <summary>
    /// Bloque l'écran et affiche une animation d'attente
    /// </summary>
    procedure AfficheAnimationAttente;

    /// <summary>
    /// Cache l'animation d'attente et débloque l'écran
    /// </summary>
    procedure MasqueAnimationAttente;
  public
    { Déclarations publiques }
    property IDClient: string read getIDClient write SetIDClient;
    property SequenceModifsServeur: integer read getSequenceModifsServeur
      write SetSequenceModifsServeur;
    property URLAPIServeurListeCourses: string read getURLAPIServeurListeCourses
      write SetURLAPIServeurListeCourses;

    /// <summary>
    /// Charge la liste des courses à l'écran
    /// </summary>
    procedure AfficheListeCourses;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses
  System.IOUtils, System.JSON, uCourses, FMX.DialogService, uAPIListeCourses;

procedure TfrmMain.AfficheAnimationAttente;
begin
  // Masquage ou blocage des composants de saisie pouvant être utilisés avec le clavier
  gbListeCourses.Visible := false;
  btnSynchronisation.Enabled := false;
  // Activation du blocage visuel
  zoneBlocageEcran.Visible := true;
  zoneBlocageEcran.BringToFront;
  aniBlocageEcran.Visible := true;
  aniBlocageEcran.BringToFront;
  aniBlocageEcran.Enabled := true;
end;

procedure TfrmMain.AfficheListeCourses;
var
  produit: tproduit;
begin
  // On vide le contenu de la zone d'affichage de la liste
  while vsbListeCourses.Content.ControlsCount > 0 do
    vsbListeCourses.Content.Controls[0].Free;

  // Parcourir liste des produits
  if courses.Count > 0 then
    for produit in courses do
      AjouteProduitEnSaisie(produit.produit, produit.Quantite);
end;

procedure TfrmMain.AjouteProduitEnSaisie(AProduit: string; AQuantite: integer);
var
  l: TLabel;
  e: TEdit;
begin
  l := TLabel.Create(self);
  l.Parent := vsbListeCourses;
  l.Align := talignlayout.Top;
  l.Margins.Top := 10;
  l.Margins.right := 10;
  l.Margins.bottom := 10;
  l.Margins.left := 10;
  l.Height := 40;
  l.Text := AProduit;
  l.TextSettings.VertAlign := ttextalign.Leading;
  e := TEdit.Create(self);
  e.Parent := l;
  e.Align := talignlayout.bottom;
  e.Text := AQuantite.ToString;
  e.TagString := AProduit;
  e.OnChange := ChangeQuantiteSurProduit;
  e.KeyboardType := TVirtualKeyboardType.NumberPad;
  e.ReturnKeyType := TReturnKeyType.Done;
  e.KillFocusByReturn := true;
end;

procedure TfrmMain.btnAjoutProduitClick(Sender: TObject);
begin
  TDialogService.InputQuery('Courses à faire', ['Produit à ajouter ?'], [''],
    procedure(const AResult: TModalResult; const AValues: array of string)
    begin
      if (AResult = mrOk) and (length(AValues) = 1) then
        AjouteProduitEnSaisie(AValues[0], 0);
    end);
end;

procedure TfrmMain.btnSynchronisationClick(Sender: TObject);
begin
  if edtURLAPIListeCourses.Text.Trim.IsEmpty then
  begin
    edtURLAPIListeCourses.SetFocus;
    raise exception.Create
      ('Veuillez indiquer l''URL du serveur de gestion de la liste des courses.');
  end;

  if (FURLAPIServeurListeCourses <> edtURLAPIListeCourses.Text.Trim) then
  begin
    // Traite la nouvelle URL du serveur
    URLAPIServeurListeCourses := edtURLAPIListeCourses.Text.Trim;

    AfficheAnimationAttente;
    try
      // Appel de l'API serveur : GET /register
      APIEnregistrement(URLAPIServeurListeCourses,
        procedure(AIDClient: string; ASequence: integer)
        begin
          if not AIDClient.IsEmpty then
          begin
            IDClient := AIDClient;
            SequenceModifsServeur := ASequence;
            AfficheListeCourses;
          end;
          MasqueAnimationAttente;
        end);
    except
      MasqueAnimationAttente;
    end;
  end
  else
  begin
    // Envoyer logmodifs locale (API Serveur : POST /courses)
    APICoursesUpload(URLAPIServeurListeCourses, IDClient);

    AfficheAnimationAttente;
    try
      // Recevoir logmodifs distante (API Serveur : GET /courses)
      APICoursesDownload(URLAPIServeurListeCourses, IDClient,
        SequenceModifsServeur,
        procedure(ASequenceEnSortie: integer)
        begin
          if (SequenceModifsServeur <> ASequenceEnSortie) then
          begin
            SequenceModifsServeur := ASequenceEnSortie;
            AfficheListeCourses;
          end;
          MasqueAnimationAttente;
        end);
    except
      MasqueAnimationAttente;
    end;
  end;
end;

procedure TfrmMain.ChangeQuantiteSurProduit(Sender: TObject);
var
  e: TEdit;
begin
  if (Sender is TEdit) then
  begin
    e := Sender as TEdit;
    if not e.TagString.IsEmpty then
      try
        courses.Modifie(e.TagString, e.Text.ToInteger);
      except
        e.SetFocus;
        raise exception.Create
          ('Veuillez indiquer une valeur entière (positive ou négative).');
      end;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FIDClient := '';
  FSequenceModifsServeur := -1;
  FURLAPIServeurListeCourses := '';

  MasqueAnimationAttente;

  edtURLAPIListeCourses.Text := URLAPIServeurListeCourses;
  AfficheListeCourses;
end;

function TfrmMain.getIDClient: string;
begin
  if FIDClient.IsEmpty then
  begin
    if tfile.Exists(tpath.combine(getDossierDeStockage, 'idclient.dat')) then
    begin
      FIDClient := tfile.ReadAllText(tpath.combine(getDossierDeStockage,
        'idclient.dat'));
      result := FIDClient;
    end
    else
      raise exception.Create
        ('Donnée indisponible. Synchroniser avec le serveur.');
  end
  else
    result := FIDClient;
end;

function TfrmMain.getSequenceModifsServeur: integer;
begin
  if FSequenceModifsServeur < 0 then
  begin
    if tfile.Exists(tpath.combine(getDossierDeStockage, 'sequence.dat')) then
    begin
      FSequenceModifsServeur :=
        tfile.ReadAllText(tpath.combine(getDossierDeStockage, 'sequence.dat'))
        .ToInteger;
      result := FSequenceModifsServeur;
    end
    else
      raise exception.Create
        ('Donnée indisponible. Synchroniser avec le serveur.');
  end
  else
    result := FSequenceModifsServeur;
end;

function TfrmMain.getURLAPIServeurListeCourses: string;
begin
  if FURLAPIServeurListeCourses.IsEmpty then
  begin
    if tfile.Exists(tpath.combine(getDossierDeStockage, 'urlapi.dat')) then
    begin
      FURLAPIServeurListeCourses :=
        tfile.ReadAllText(tpath.combine(getDossierDeStockage, 'urlapi.dat'));
      result := FURLAPIServeurListeCourses;
    end
    else
    begin
      result := 'http://localhost:8080';
    end;
  end
  else
    result := FURLAPIServeurListeCourses;
end;

procedure TfrmMain.MasqueAnimationAttente;
begin
  // Cache l'animation et le verrouillage visuel de l'écran
  aniBlocageEcran.Enabled := false;
  zoneBlocageEcran.Visible := false;
  // Réactive les contrôles en saisie
  gbListeCourses.Visible := true;
  btnSynchronisation.Enabled := true;
end;

procedure TfrmMain.SetIDClient(const Value: string);
begin
  FIDClient := Value;
  tfile.writeAllText(tpath.combine(getDossierDeStockage, 'idclient.dat'),
    FIDClient);
end;

procedure TfrmMain.SetSequenceModifsServeur(const Value: integer);
begin
  FSequenceModifsServeur := Value;
  tfile.writeAllText(tpath.combine(getDossierDeStockage, 'sequence.dat'),
    FSequenceModifsServeur.ToString);
end;

procedure TfrmMain.SetURLAPIServeurListeCourses(const Value: string);
begin
  FURLAPIServeurListeCourses := Value;
  tfile.writeAllText(tpath.combine(getDossierDeStockage, 'urlapi.dat'),
    FURLAPIServeurListeCourses);
end;

end.
