{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit OCW.CodeGen.SourceFile;

interface

uses
  System.SysUtils,
  System.Classes,
  ToolsAPI;

type
  TSourceFile = class(TInterfacedObject, IOTAFile)
  private
    FSource: string;
  public
    function GetSource: string;
    function GetAge: TDateTime;
    constructor Create(const Source: string; const Args: array of const );
  end;

implementation

{ TSourceFile }

constructor TSourceFile.Create(const Source: string; const Args: array of const );
begin
  inherited Create;
  FSource := Format(Source, Args);
end;

function TSourceFile.GetAge: TDateTime;
begin
  Result := Now;
end;

function TSourceFile.GetSource: string;
begin
  Result := FSource;
end;

end.

