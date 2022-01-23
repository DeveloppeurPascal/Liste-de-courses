unit uAPIListeCourses;

interface

uses system.SysUtils;

type
  TAPIEnregistrementProc = reference to procedure(AIDClient: string;
    ASequence: integer);
  TAPICoursesDownloadProc = reference to procedure(ASequenceEnSortie: integer);

procedure APIEnregistrement(URLServeur: string;
  Callback: TAPIEnregistrementProc);
procedure APICoursesUpload(URLServeur: string; IDClient: string);
procedure APICoursesDownload(URLServeur: string; IDClient: string;
  SequenceEnEntree: integer; Callback: TAPICoursesDownloadProc);

implementation

uses
  system.Net.HttpClient, system.Threading, system.Classes, system.JSON,
  uCourses;

procedure APIEnregistrement(URLServeur: string;
  Callback: TAPIEnregistrementProc);
begin
  ttask.Run(
    procedure
    var
      serveur: thttpclient;
      reponse: ihttpresponse;
      IDClient: string;
      sequence: integer;
      jso: tjsonobject;
      tabCourses: tjsonarray;
    begin
      IDClient := '';
      sequence := -1;
      try
        serveur := thttpclient.Create;
        try
          reponse := serveur.Get(URLServeur + '/register');
          case reponse.StatusCode of
            200:
              begin
                jso := tjsonobject.ParseJSONValue(reponse.ContentAsString)
                  as tjsonobject;
                if assigned(jso) then
                  try
                    if jso.TryGetValue<string>('id', IDClient) and
                      jso.TryGetValue<integer>('sequence', sequence) and
                      jso.TryGetValue<tjsonarray>('courses', tabCourses) then
                      courses.LoadFromJSONArray(tabCourses);
                  finally
                    jso.Free;
                  end;
              end;
          end;
        finally
          serveur.Free;
        end;
      except
      end;
      tthread.Synchronize(nil,
        procedure
        begin
          Callback(IDClient, sequence);
        end);
    end);
end;

procedure APICoursesUpload(URLServeur: string; IDClient: string);
begin
  ttask.Run(
    procedure
    var
      serveur: thttpclient;
      reponse: ihttpresponse;
      tabModifs: tjsonarray;
      Params: TStringList;
    begin
      try
        serveur := thttpclient.Create;
        try
          tabModifs := logmodifs.SaveToJSONArray;
          try
            Params := TStringList.Create;
            try
              Params.AddPair('id', IDClient);
              Params.AddPair('chg', tabModifs.tojson);
              reponse := serveur.post(URLServeur + '/courses', Params);
            finally
              Params.Free;
            end;
          finally
            tabModifs.Free;
          end;
          case reponse.StatusCode of
            200:
              begin
                // Envoi ok, on vide la liste de modifications locales
                logmodifs.Clear;
                logmodifs.SaveToFile;
              end;
          end;
        finally
          serveur.Free;
        end;
      except
      end;
    end);
end;

procedure APICoursesDownload(URLServeur: string; IDClient: string;
SequenceEnEntree: integer; Callback: TAPICoursesDownloadProc);
begin
  ttask.Run(
    procedure
    var
      serveur: thttpclient;
      reponse: ihttpresponse;
      SequenceEnSortie: integer;
      jso: tjsonobject;
      tabModifs: tjsonarray;
    begin
      SequenceEnSortie := SequenceEnEntree;
      try
        serveur := thttpclient.Create;
        try
          reponse := serveur.Get(URLServeur + '/courses?id=' + IDClient +
            '&seq=' + SequenceEnEntree.ToString);
          case reponse.StatusCode of
            200:
              begin
                jso := tjsonobject.ParseJSONValue(reponse.ContentAsString)
                  as tjsonobject;
                if assigned(jso) then
                  try
                    if jso.TryGetValue<integer>('sequence', SequenceEnSortie)
                      and jso.TryGetValue<tjsonarray>('chg', tabModifs) then
                      courses.AppliqueModifications(tabModifs);
                  finally
                    jso.Free;
                  end;
              end;
          end;
        finally
          serveur.Free;
        end;
      except
      end;
      tthread.Synchronize(nil,
        procedure
        begin
          Callback(SequenceEnSortie);
        end);
    end);
end;

end.
