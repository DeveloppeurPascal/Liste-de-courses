unit WebModuleUnit1;

interface

uses
  System.SysUtils, System.Classes, Web.HTTPApp;

type
  TWebModule1 = class(TWebModule)
    procedure WebModule1DefaultHandlerAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModule1IdentificationClientAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModule1EnvoiDeModificationsAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModule1ChargementDesModificationAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  WebModuleClass: TComponentClass = TWebModule1;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

uses uDM, System.JSON;

{$R *.dfm}

procedure TWebModule1.WebModule1ChargementDesModificationAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  id: string;
  SequenceEnEntree, SequenceEnSortie: integer;
  chg: tjsonarray;
  jso: tjsonobject;
begin
  // GET /courses
  if (Request.QueryFields.IndexOfName('id') < 0) then
  begin // paramètre "ID" absent
    Response.StatusCode := 400;
    Response.Content := '"id" absent';
  end
  else
  begin
    id := Request.QueryFields.Values['id'];
    if not dm.isClient(id) then
    begin // "id" absent de la liste des ID clients
      Response.StatusCode := 400;
      Response.Content := '"id" inconnu';
    end
    else if (Request.QueryFields.IndexOfName('seq') < 0) then
    begin // paramètre "seq" absent
      Response.StatusCode := 400;
      Response.Content := '"seq" absent';
    end
    else
    begin
      try
        SequenceEnEntree := Request.QueryFields.Values['seq'].ToInteger;
        jso := tjsonobject.Create;
        try
          dm.getLogModifs(id, SequenceEnEntree, chg, SequenceEnSortie);
          jso.AddPair('chg', chg);
          jso.AddPair('sequence', SequenceEnSortie);
          Response.StatusCode := 200;
          Response.ContentType := 'application/json';
          Response.CustomHeaders.Add('Access-Control-Allow-Origin=*');
          Response.Content := jso.tojson;
        finally
          jso.Free;
        end;
      except
        Response.StatusCode := 400;
        Response.Content := '"seq" en erreur';
      end;
    end;
  end;
end;

procedure TWebModule1.WebModule1DefaultHandlerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  Response.Content := '<html>' +
    '<head><title>Serveur Liste Courses</title></head>' +
    '<body>Serveur Liste Courses</body>' + '</html>';
end;

procedure TWebModule1.WebModule1EnvoiDeModificationsAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  id: string;
  chg: tjsonarray;
begin
  // POST /courses
  if (Request.ContentFields.IndexOfName('id') < 0) then
  begin // paramètre "ID" absent
    Response.StatusCode := 400;
    Response.Content := '"id" absent';
  end
  else
  begin
    id := Request.ContentFields.Values['id'];
    if not dm.isClient(id) then
    begin // "id" absent de la liste des ID clients
      Response.StatusCode := 400;
      Response.Content := '"id" inconnu';
    end
    else if (Request.ContentFields.IndexOfName('chg') < 0) then
    begin // paramètre "chg" absent
      Response.StatusCode := 400;
      Response.Content := '"chg" absent';
    end
    else
    begin
      try
        chg := tjsonarray.ParseJSONValue(Request.ContentFields.Values['chg'])
          as tjsonarray;
        dm.EnregistreModifications(id, chg);
        Response.StatusCode := 200;
        Response.Content := 'OK';
      except
        Response.StatusCode := 400;
        Response.Content := 'parsing "chg" en erreur';
      end;
    end;
  end;
end;

procedure TWebModule1.WebModule1IdentificationClientAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  jso: tjsonobject;
  courses: tjsonarray;
  sequence: integer;
begin
  // GET /register
  jso := tjsonobject.Create;
  try
    jso.AddPair('id', dm.getNewClientID);
    dm.getCourses(courses, sequence);
    jso.AddPair('courses', courses);
    jso.AddPair('sequence', sequence);
    // avant 11 Alexandria : jso.AddPair('sequence', tjsonnumber.Create(sequence));
    Response.StatusCode := 200;
    Response.ContentType := 'application/json';
    Response.CustomHeaders.Add('Access-Control-Allow-Origin=*');
    Response.Content := jso.tojson;
  finally
    jso.Free;
  end;
end;

end.
