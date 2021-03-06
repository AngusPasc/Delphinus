{
#########################################################
# Copyright by Alexander Benikowski                     #
# This unit is part of the Delphinus project hosted on  #
# https://github.com/Memnarch/Delphinus                 #
#########################################################
}
unit Delphinus.SetupDialog;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs,
  DN.PackageProvider.Intf,
  DN.Package.Intf,
  DN.Package.Version.Intf,
  DN.Installer.Intf,
  DN.Uninstaller.Intf,
  StdCtrls,
  DN.Types,
  DN.Setup.Intf,
  Delphinus.Forms,
  ComCtrls,
  ExtCtrls,
  DN.ComCtrls.Helper;

const
  CStart = WM_USER + 1;

type
  TSetupDialogMode = (sdmInstall, sdmInstallDirectory, sdmUninstall, sdmUninstallDirectory, sdmUpdate);

  TSetupDialog = class(TForm)
    mLog: TMemo;
    pcSteps: TPageControl;
    tsMainPage: TTabSheet;
    tsLog: TTabSheet;
    btnOK: TButton;
    btnCancel: TButton;
    Image1: TImage;
    lbNameInstallUpdate: TLabel;
    cbVersion: TComboBox;
    Label1: TLabel;
    lbLicenseAnotation: TLabel;
    Label3: TLabel;
    lbLicenseType: TLabel;
    btnLicense: TButton;
    tsProgress: TTabSheet;
    pbProgress: TProgressBar;
    btnCloseProgress: TButton;
    lbAction: TLabel;
    btnShowLog: TButton;
    procedure HandleOK(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnLicenseClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnShowLogClick(Sender: TObject);
  private
    { Private declarations }
    FMode: TSetupDialogMode;
    FPackage: IDNPackage;
    FInstalledComponentDirectory: string;
    FDirectoryToInstall: string;
    FSetup: IDNSetup;
    FSetupIsRunning: Boolean;
    procedure Log(const AMessage: string);
    procedure HandleLogMessage(AType: TMessageType; const AMessage: string);
    procedure HandleProgress(const ATask, AItem: string; AProgress, AMax: Int64);
    procedure InitMainPage();
    procedure InitVersionSelection();
    procedure Execute();
    procedure SetupFinished;
    function GetSelectedVersion: IDNPackageVersion;
  public
    { Public declarations }
    constructor Create(const ASetup: IDNSetup); reintroduce;
    function ExecuteInstallation(const APackage: IDNPackage): Boolean;
    function ExecuteInstallationFromDirectory(const ADirectory: string): Boolean;
    function ExecuteUninstallation(const APackage: IDNPackage): Boolean;
    function ExecuteUninstallationFromDirectory(const ADirectory: string): Boolean;
    function ExecuteUpdate(const APackage: IDNPackage): Boolean;
  end;

var
  SetupDialog: TSetupDialog;

implementation

uses
  IOUtils,
  StrUtils,
  DN.JSonFile.InstalledInfo,
  Delphinus.LicenseDialog;

{$R *.dfm}

{ TSetupDialog }

procedure TSetupDialog.btnLicenseClick(Sender: TObject);
var
  LDialog: TLicenseDialog;
begin
  LDialog := TLicenseDialog.Create(nil);
  try
    LDialog.Package := FPackage;
    LDialog.ShowModal();
  finally
    LDialog.Free;
  end;
end;

procedure TSetupDialog.btnShowLogClick(Sender: TObject);
begin
  pcSteps.ActivePage := tsLog;
end;

constructor TSetupDialog.Create(const ASetup: IDNSetup);
begin
  inherited Create(nil);
  FSetup := ASetup;
  FSetup.OnMessage := HandleLogMessage;
  FSetup.OnProgress := HandleProgress;
end;

procedure TSetupDialog.Execute;
var
  LThread: TThread;
begin
  FSetupIsRunning := True;
  mLog.Clear;
  pbProgress.Position := 0;
  pbProgress.State := pbsNormal;
  pcSteps.ActivePage := tsProgress;
  LThread := TThread.CreateAnonymousThread(
    procedure
    begin
      try
        case FMode of
          sdmInstall: FSetup.Install(FPackage, GetSelectedVersion());
          sdmInstallDirectory: FSetup.InstallDirectory(FDirectoryToInstall);
          sdmUninstall: FSetup.Uninstall(FPackage);
          sdmUninstallDirectory: FSetup.UninstallDirectory(FInstalledComponentDirectory);
          sdmUpdate: FSetup.Update(FPackage, GetSelectedVersion());
        end;
      finally
        TThread.Synchronize(nil, SetupFinished);
      end;
    end);
  LThread.Start;
end;

function TSetupDialog.ExecuteInstallation(const APackage: IDNPackage): Boolean;
begin
  FPackage := APackage;
  FMode := sdmInstall;
  Result := ShowModal() <> mrCancel;
end;

function TSetupDialog.ExecuteInstallationFromDirectory(
  const ADirectory: string): Boolean;
begin
  FDirectoryToInstall := ADirectory;
  FMode := sdmInstallDirectory;
  Result := ShowModal() <> mrCancel;
end;

function TSetupDialog.ExecuteUninstallation(const APackage: IDNPackage): Boolean;
begin
  FPackage := APackage;
  FMode := sdmUninstall;
  Result := ShowModal() <> mrCancel;;
end;

function TSetupDialog.ExecuteUninstallationFromDirectory(
  const ADirectory: string): Boolean;
begin
  FInstalledComponentDirectory := ADirectory;
  FMode := sdmUninstallDirectory;
  Result := ShowModal() <> mrCancel;
end;

function TSetupDialog.ExecuteUpdate(const APackage: IDNPackage): Boolean;
begin
  FPackage := APackage;
  FMode := sdmUpdate;
  Result := ShowModal() <> mrCancel;
end;

procedure TSetupDialog.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not FSetupIsRunning;
  if not CanClose then
    MessageDlg('You can not close the dialog while the setup is running, please wait', mtInformation, [mbOK], 0)
  else if (ModalResult = mrCancel) and (pcSteps.ActivePageIndex > 0) then
    ModalResult := mrOk;
end;

procedure TSetupDialog.FormShow(Sender: TObject);
begin
  InitMainPage();
end;

function TSetupDialog.GetSelectedVersion: IDNPackageVersion;
begin
  if Assigned(FPackage) and (cbVersion.ItemIndex > -1) then
    Result := FPackage.Versions[cbVersion.ItemIndex]
  else
    Result := nil;
end;

procedure TSetupDialog.HandleLogMessage(AType: TMessageType;
  const AMessage: string);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      case AType of
        mtNotification: Log(AMessage);
        mtWarning: Log('Warning: ' + AMessage);
        mtError:
        begin
          Log('Error: ' + AMessage);
          pbProgress.State := pbsError;
        end;
      end;
    end
  );
end;

procedure TSetupDialog.HandleOK(Sender: TObject);
begin
  Execute();
end;

procedure TSetupDialog.HandleProgress(const ATask, AItem: string; AProgress, AMax: Int64);
begin
  TThread.Queue(nil,
  procedure
  begin
    lbAction.Caption := IfThen(AItem <> '', AItem, ATask);
    pbProgress.Position := Round(AProgress / AMax * pbProgress.Max);
  end
  );
end;

procedure TSetupDialog.InitMainPage;
begin
  pcSteps.ActivePage := tsMainPage;
  case FMode of
    sdmInstall:
    begin
      btnOK.Caption := 'Install';
      lbNameInstallUpdate.Caption := FPackage.Name;
      lbLicenseType.Caption := FPackage.LicenseType;
      btnLicense.Visible := lbLicenseType.Caption <> '';
      if Assigned(FPackage.Picture) then
        Image1.Picture.Assign(FPackage.Picture);
      InitVersionSelection();
    end;
//    sdmInstallDirectory: ;
    sdmUninstall:
    begin
      btnOK.Caption := 'Uninstall';
      lbNameInstallUpdate.Caption := FPackage.Name;
      lbLicenseType.Caption := FPackage.LicenseType;
      if Assigned(FPackage.Picture) then
        Image1.Picture.Assign(FPackage.Picture);
      Label1.Visible := False;
      cbVersion.Visible := False;
      lbLicenseAnotation.Visible := False;
      btnLicense.Visible := False;
    end;
//    sdmUninstallDirectory: ;
    sdmUpdate:
    begin
      btnOK.Caption := 'Update';
      lbNameInstallUpdate.Caption := FPackage.Name;
      if Assigned(FPackage.Picture) then
        Image1.Picture.Assign(FPackage.Picture);
      InitVersionSelection();
    end;
  end;
end;

procedure TSetupDialog.InitVersionSelection;
var
  i: Integer;
begin
  cbVersion.Enabled := FPackage.Versions.Count > 0;
  for i := 0 to FPackage.Versions.Count - 1 do
  begin
    cbVersion.Items.Add(FPackage.Versions[i].Name);
  end;
  cbVersion.ItemIndex := 0;
end;

procedure TSetupDialog.Log(const AMessage: string);
begin
  mLog.Lines.Add(AMessage);
end;

procedure TSetupDialog.SetupFinished;
begin
  btnCloseProgress.Enabled := True;
  btnShowLog.Enabled := True;
  FSetupIsRunning := False;
end;

end.
