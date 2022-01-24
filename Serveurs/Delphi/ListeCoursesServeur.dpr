program ListeCoursesServeur;
{$APPTYPE CONSOLE}

uses
{$IFDEF LINUX}
  Posix.Stdlib, Posix.SysStat, Posix.SysTypes, Posix.Unistd, Posix.Signal,
  Posix.Fcntl,
{$ENDIF}
  System.SysUtils,
  System.Types,
  IPPeerServer,
  IPPeerAPI,
  IdHTTPWebBrokerBridge,
  Web.WebReq,
  Web.WebBroker,
  WebModuleUnit1 in 'WebModuleUnit1.pas' {WebModule1: TWebModule} ,
  ServerConst1 in 'ServerConst1.pas',
  uDM in 'uDM.pas' {dm: TDataModule};

{$R *.res}

function BindPort(APort: Integer): Boolean;
var
  LTestServer: IIPTestServer;
begin
  Result := True;
  try
    LTestServer := PeerFactory.CreatePeer('', IIPTestServer) as IIPTestServer;
    LTestServer.TestOpenPort(APort, nil);
  except
    Result := False;
  end;
end;

function CheckPort(APort: Integer): Integer;
begin
  if BindPort(APort) then
    Result := APort
  else
    Result := 0;
end;

procedure SetPort(const AServer: TIdHTTPWebBrokerBridge; APort: String);
begin
  if not AServer.Active then
  begin
    APort := APort.Replace(cCommandSetPort, '').Trim;
    if CheckPort(APort.ToInteger) > 0 then
    begin
      AServer.DefaultPort := APort.ToInteger;
      Writeln(Format(sPortSet, [APort]));
    end
    else
      Writeln(Format(sPortInUse, [APort]));
  end
  else
    Writeln(sServerRunning);
  Write(cArrow);
end;

procedure StartServer(const AServer: TIdHTTPWebBrokerBridge);
begin
  if not AServer.Active then
  begin
    if CheckPort(AServer.DefaultPort) > 0 then
    begin
      Writeln(Format(sStartingServer, [AServer.DefaultPort]));
      AServer.Bindings.Clear;
      AServer.Active := True;
    end
    else
      Writeln(Format(sPortInUse, [AServer.DefaultPort.ToString]));
  end
  else
    Writeln(sServerRunning);
  Write(cArrow);
end;

procedure StopServer(const AServer: TIdHTTPWebBrokerBridge);
begin
  if AServer.Active then
  begin
    Writeln(sStoppingServer);
    AServer.Active := False;
    AServer.Bindings.Clear;
    Writeln(sServerStopped);
  end
  else
    Writeln(sServerNotRunning);
  Write(cArrow);
end;

procedure WriteCommands;
begin
  Writeln(sCommands);
  Write(cArrow);
end;

procedure WriteStatus(const AServer: TIdHTTPWebBrokerBridge);
begin
  Writeln(sIndyVersion + AServer.SessionList.Version);
  Writeln(sActive + AServer.Active.ToString(TUseBoolStrs.True));
  Writeln(sPort + AServer.DefaultPort.ToString);
  Writeln(sSessionID + AServer.SessionIDCookieName);
  Write(cArrow);
end;

procedure RunServer(APort: Integer);
var
  LServer: TIdHTTPWebBrokerBridge;
  LResponse: string;
begin
  WriteCommands;
  LServer := TIdHTTPWebBrokerBridge.Create(nil);
  try
    LServer.DefaultPort := APort;
    StartServer(LServer);
    while True do
    begin
      Readln(LResponse);
      LResponse := LowerCase(LResponse);
      if LResponse.StartsWith(cCommandSetPort) then
        SetPort(LServer, LResponse)
      else if sametext(LResponse, cCommandStart) then
        StartServer(LServer)
      else if sametext(LResponse, cCommandStatus) then
        WriteStatus(LServer)
      else if sametext(LResponse, cCommandStop) then
        StopServer(LServer)
      else if sametext(LResponse, cCommandHelp) then
        WriteCommands
      else if sametext(LResponse, cCommandExit) then
        if LServer.Active then
        begin
          StopServer(LServer);
          break
        end
        else
          break
      else
      begin
        Writeln(sInvalidCommand);
        Write(cArrow);
      end;
    end;
  finally
    LServer.Free;
  end;
end;

{$IFDEF LINUX}

const
  // Missing from linux/StdlibTypes.inc !!! <stdlib.h>
  EXIT_FAILURE = 1;
  EXIT_SUCCESS = 0;

var
  pid: pid_t;
  fid: Integer;
  idx: Integer;
  running: Boolean;

procedure HandleSignals(SigNum: Integer); cdecl;
begin
  case SigNum of
    SIGTERM:
      begin
        running := False;
      end;
    SIGHUP:
      begin
        // syslog(LOG_NOTICE, 'daemon: reloading config');
        // Reload configuration
      end;
  end;
end;

procedure RunServerDaemon(APort: Integer);
var
  LServer: TIdHTTPWebBrokerBridge;
begin
  LServer := TIdHTTPWebBrokerBridge.Create(nil);
  try
    LServer.DefaultPort := APort;
    StartServer(LServer);
    while running do
      sleep(100);
  finally
    LServer.Free;
  end;
end;

{$ENDIF}

var
  port: Integer;
  paramvalue: string;

begin
  try
    if findcmdlineswitch('h') then
    begin
      Writeln('ListeCoursesServeur');
      Writeln('(c) 2022 Patrick Prémartin');
      Writeln('');
      Writeln('-h => display this help');
      Writeln('-port number => port number to listen (8080 by default)');
{$IFDEF LINUX}
      Writeln('-daemon => start the server as Linux daemon');
{$ENDIF}
    end
    else
    begin
      if findcmdlineswitch('port', paramvalue, True, [clstvaluenextparam]) then
        port := paramvalue.ToInteger
      else
        port := 8080;

      if WebRequestHandler <> nil then
        WebRequestHandler.WebModuleClass := WebModuleClass;

{$IFDEF LINUX}
      // Want to understand how to create a Linux daemon ?
      // Look at Paolo Rossi blog :
      // https://blog.paolorossi.net/building-a-real-linux-daemon-with-delphi-part-1/
      // https://blog.paolorossi.net/building-a-real-linux-daemon-with-delphi-part-2/
      if findcmdlineswitch('daemon') then
      begin
        // openlog(nil, LOG_PID or LOG_NDELAY, LOG_DAEMON);
        try
          if getppid() > 1 then
          begin
            pid := fork();
            if pid < 0 then
              raise exception.Create('Error forking the process');

            if pid > 0 then
              Halt(EXIT_SUCCESS);

            if setsid() < 0 then
              raise exception.Create
                ('Impossible to create an independent session');

            Signal(SIGCHLD, TSignalHandler(SIG_IGN));
            Signal(SIGHUP, HandleSignals);
            Signal(SIGTERM, HandleSignals);

            pid := fork();
            if pid < 0 then
              raise exception.Create('Error forking the process');

            if pid > 0 then
              Halt(EXIT_SUCCESS);

            for idx := sysconf(_SC_OPEN_MAX) downto 0 do
              __close(idx);

            fid := __open('/dev/null', O_RDWR);
            dup(fid);
            dup(fid);

//            umask(027);

//            chdir('/');
          end;

          running := True;

          RunServerDaemon(port);

          ExitCode := EXIT_SUCCESS;
        except
          on E: exception do
          begin
            // syslog(LOG_ERR, 'Error: ' + E.Message);
            ExitCode := EXIT_FAILURE;
          end;
        end;

        // syslog(LOG_NOTICE, 'daemon stopped');
        // closelog();
      end
      else
{$ENDIF}
        RunServer(port);
    end;
  except
    on E: exception do
      Writeln(E.ClassName, ': ', E.Message);
  end

end.
