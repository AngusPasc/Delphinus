unit DN.JSonFile.Installation;

interface

uses
  Types,
  JSOn,
  DBXJSon,
  DN.JSOnFile,
  DN.Compiler.Intf;

type
  TSearchPath = record
    Path: string;
    CompilerMin: Integer;
    CompilerMax: Integer;
    Platforms: TDNCompilerPlatforms;
  end;

  TFolder = record
    Folder: string;
    Recursive: Boolean;
    Filter: string;
    Base: string;
    CompilerMin: Integer;
    CompilerMax: Integer;
  end;

  TProject = record
    Project: string;
    CompilerMin: Integer;
    CompilerMax: Integer;
  end;

  TInstallationFile = class(TJSonFile)
  private
    FSourceFolders: TArray<TFolder>;
    FSearchPath: TArray<TSearchPath>;
    FProjects: TArray<TProject>;
  protected
    procedure Load(const ARoot: TJSONObject); override;
    function GetPlatforms(const APlatforms: string): TDNCompilerPlatforms;
  public
    property SearchPathes: TArray<TSearchPath> read FSearchPath;
    property SourceFolders: TArray<TFolder> read FSourceFolders;
    property Projects: TArray<TProject> read FProjects;
  end;

implementation

uses
  SysUtils,
  StrUtils;

{ TInstallationFile }

function TInstallationFile.GetPlatforms(
  const APlatforms: string): TDNCompilerPlatforms;
var
  LPlatforms: TStringDynArray;
  LPlatform: string;
begin
  LPlatforms := SplitString(APlatforms, ';');
  if Length(LPlatforms) > 0 then
  begin
    Result := [];
    for LPlatform in LPlatforms do
    begin
      if SameText(LPlatform, 'Win32') then
        Result := Result + [cpWin32]
      else if SameText(LPlatform, 'Win64') then
        Result := Result + [cpWin64]
      else if SameText(LPlatform, 'OSX32') then
        Result := Result + [cpOSX32]
    end;
  end
  else
  begin
    Result := [cpWin32];
  end;
end;

procedure TInstallationFile.Load(const ARoot: TJSONObject);
var
  LArray: TJSonArray;
  LItem: TJSONObject;
  i: Integer;
  LCompiler: Integer;
begin
  inherited;
  if ReadArray(ARoot, 'search_pathes', LArray) then
  begin
    SetLength(FSearchPath, LArray.Count);
    for i := 0 to Pred(LArray.Count) do
    begin
      LItem := LArray.Items[i] as TJSONObject;
      FSearchPath[i].Path := ReadString(LItem, 'pathes');
      LCompiler := ReadInteger(LItem, 'compiler');
      if LCompiler > 0 then
      begin
        FSearchPath[i].CompilerMin := LCompiler;
        FSearchPath[i].CompilerMax := LCompiler;
      end
      else
      begin
        FSearchPath[i].CompilerMin := ReadInteger(LItem, 'compiler_min');
        FSearchPath[i].CompilerMax := ReadInteger(LItem, 'compiler_max');
      end;
      FSearchPath[i].Platforms := GetPlatforms(ReadString(LItem, 'platforms'));
    end;
  end;

  if ReadArray(ARoot, 'source_folders', LArray) then
  begin
    SetLength(FSourceFolders, LArray.Count);
    for i := 0 to Pred(LArray.Count) do
    begin
      LItem := LArray.Items[i] as TJSONObject;
      FSourceFolders[i].Folder := ReadString(LItem, 'folder');
      FSourceFolders[i].Base := ReadString(LItem, 'base');
      FSourceFolders[i].Recursive := ReadBoolean(LItem, 'recursive');
      FSourceFolders[i].Filter := ReadString(LItem, 'filter');
      LCompiler := ReadInteger(LItem, 'compiler');
      if LCompiler > 0 then
      begin
        FSourceFolders[i].CompilerMin := LCompiler;
        FSourceFolders[i].CompilerMax := LCompiler;
      end
      else
      begin
        FSourceFolders[i].CompilerMin := ReadInteger(LItem, 'compiler_min');
        FSourceFolders[i].CompilerMax := ReadInteger(LItem, 'compiler_max');
      end;
    end;
  end;

  if ReadArray(ARoot, 'projects', LArray) then
  begin
    SetLength(FProjects, LArray.Count);
    for i := 0 to Pred(LArray.Count) do
    begin
      LItem := LArray.Items[i] as TJSONObject;
      FProjects[i].Project := ReadString(LItem, 'project');
      LCompiler := ReadInteger(LItem, 'compiler');
      if LCompiler > 0 then
      begin
        FProjects[i].CompilerMin := LCompiler;
        FProjects[i].CompilerMax := LCompiler;
      end
      else
      begin
        FProjects[i].CompilerMin := ReadInteger(LItem, 'compiler_min');
        FProjects[i].CompilerMax := ReadInteger(LItem, 'compiler_max');
      end;
    end;
  end;
end;

end.
