unit Forms.Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus,
  ActnList, StdActns, ExtCtrls;

type

{ TfrmMain }
  TfrmMain = class(TForm)
    actFileRestart: TAction;
    ActionList: TActionList;
    btnFileRestart: TButton;
    actFileExit: TFileExit;
    chbDryRun: TCheckBox;
    MainMenu: TMainMenu;
    memScript: TMemo;
    mnuFile: TMenuItem;
    mnuFileRestart: TMenuItem;
    mnuFileSep1: TMenuItem;
    mnuFileExit: TMenuItem;
    panButtons: TPanel;
    procedure actFileRestartExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure InitShortcuts;
    procedure RestartApplication;
  public

  end;

var
  frmMain: TfrmMain;

implementation

uses
  LCLType,
  Process
;

const
//'' + LineEnding +
  cWindowsScriptName = 'restart.bat';
  cWindowsScript =
    '@echo off' + LineEnding +
    'echo Restarting Noso...' + LineEnding +
    'TIMEOUT 5' + LineEnding +
    'tasklist /FI "IMAGENAME eq APPFILENAME" 2>NUL | find /I /N "APPFILENAME">NUL' + LineEnding+
    'if "%ERRORLEVEL%"=="0" taskkill /F /im APPFILENAME' + LineEnding +
    'start APPFILENAME';

  cLinuxScriptName = 'restart.sh';
  cLinuxScript =
    'for x in 5 4 3 2 1; do' + LineEnding +
    'echo -ne "Restarting in ${x}\r"' + LineEnding +
    'sleep 1' + LineEnding +
    'done' + LineEnding +
    'PID=$(ps ux | grep -v grep | grep -i APPFILENAME | cut -d" " -f 2)' + LineEnding +
    'if [ "${PID}" != "" ]; then' + LineEnding +
    'kill ${PID}' + LineEnding +
    'fi' + LineEnding +
    './APPFILENAME';

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  InitShortcuts;
end;

procedure TfrmMain.actFileRestartExecute(Sender: TObject);
begin
  actFileRestart.Enabled:= False;
  Application.ProcessMessages;

  RestartApplication;

  if chbDryRun.Checked then
  begin
    Application.ProcessMessages;
    actFileRestart.Enabled:= True;
  end;
end;

procedure TfrmMain.InitShortcuts;
begin
{$IFDEF LINUX}
  actFileExit.ShortCut := KeyToShortCut(VK_Q, [ssCtrl]);
{$ENDIF}
{$IFDEF WINDOWS}
  actFileExit.ShortCut := KeyToShortCut(VK_X, [ssAlt]);
{$ENDIF}
end;

procedure TfrmMain.RestartApplication;
var
  sAppFileName: String;
  sScript: String;
  sOutput: String;
  msScript: TStringStream;
  process: TProcess;
  index: Integer;
begin
  sAppFileName:= ExtractFileName(Application.ExeName);
  {$IFDEF LINUX}
  sScript:= StringReplace(cLinuxScript, 'APPFILENAME', sAppFileName, [rfReplaceAll]);
  {$ELSE}
  sScript:= StringReplace(cWindowsScript, 'APPFILENAME', sAppFileName, [rfReplaceAll]);
  {$ENDIF}
  memScript.Clear;
  memScript.Lines.Text:= sScript;
  Application.ProcessMessages;

  if not chbDryRun.Checked then
  begin
    msScript:= TStringStream.Create(sScript);
    {$IFDEF LINUX}
    msScript.SaveToFile(cLinuxScriptName);
    {$ELSE}
    msScript.SaveToFile(cWindowsScriptName);
    {$ENDIF}

    process := TProcess.Create(nil);
    try
      process.InheritHandles := False;
      process.Options := [];
      process.ShowWindow := swoShow;
      for index := 1 to GetEnvironmentVariableCount do
      begin
        process.Environment.Add(GetEnvironmentString(index));
      end;
      {$IFDEF LINUX}
      process.Executable := 'bash';
      process.Parameters.Add(cLinuxScriptName);
      {$ELSE}
      process.Executable := cWindowsScriptName;
      {$ENDIF}
      process.Execute;
    finally
       Process.Free;
    end;

    Close;
  end;
end;

end.

