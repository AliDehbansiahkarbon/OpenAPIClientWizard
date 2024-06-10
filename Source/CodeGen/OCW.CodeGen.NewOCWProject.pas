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
  OCW.CodeGen.Templates;

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
  Result := 'VCL';
end;

function TOCWProjectFile.NewProjectSource(const ProjectName: string): IOTAFile;
begin
  Result := TSourceFile.Create(sOCWPR, [ProjectName, 'OCW', 'OCW']);
end;

end.
