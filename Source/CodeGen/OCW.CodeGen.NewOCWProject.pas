{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit OCW.CodeGen.NewOCWProject;

interface

uses
  ToolsAPI,
  OCW.CodeGen.NewProject;

type
  TOCWProjectFile = class(TNewProjectEx)
  private
  protected
    function NewProjectSource(const ProjectName: string): IOTAFile; override;
    function GetFrameworkType: string; override;
  public
    constructor Create; overload;
    constructor Create(APersonality: string; AProjectName: string); overload;
  end;

implementation

uses
  System.SysUtils,
  OCW.CodeGen.SourceFile,
  OCW.CodeGen.Templates,
  OCW.Util.Setting;

{ TOCWProjectFile }

constructor TOCWProjectFile.Create(APersonality: string; AProjectName: string);
begin
  Create;
  Personality := APersonality;
end;

constructor TOCWProjectFile.Create;
begin
  inherited;
end;

function TOCWProjectFile.GetFrameworkType: string;
begin
  if TSingletonSettingObj.Instance.OutputType = potSampleVCL then
    Result := 'VCL'
  else
    Result := EmptyStr;
end;

function TOCWProjectFile.NewProjectSource(const ProjectName: string): IOTAFile;
begin
  case TSingletonSettingObj.Instance.OutputType of
    potSampleConsole:
      Result := TSourceFile.Create(sConsolePR, [ProjectName]);
    potWrapperOnly:
      Result := TSourceFile.Create(sWrapperOnlyPR, [ProjectName]);
  else
    Result := TSourceFile.Create(sOCWPR, [ProjectName, 'OCW', 'OCW']);
  end;
end;

end.
