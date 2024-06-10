{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit OCW.Util.Setting;

interface

uses
  ToolsAPI, System.SysUtils, System.Classes, Vcl.Forms, DockForm;

const
  CVersion = 'v1.0.0.0';

type
  TSingletonSettingObj = class(TObject)
  private
    FBaseURL: string;
    FBearerToken: string;
    FUserName: string;
    FPassword: string;
    FVersion: Byte;
    FAuthType: Byte;
    FBooleanStringForm: Integer;
    class var FInstance: TSingletonSettingObj;
    class function GetInstance: TSingletonSettingObj; static;
  public
    constructor Create;
    destructor Destroy; override;
    class procedure RegisterFormClassForTheming(const AFormClass: TCustomFormClass; const Component: TComponent); static;

    property BaseURL: string read FBaseURL write FBaseURL;
    property BearerToken: string read FBearerToken write FBearerToken;
    property UserName: string read FUserName write FUserName;
    property Password: string read FPassword write FPassword;
    property Version: Byte read FVersion write FVersion;
    property AuthType: Byte read FAuthType write FAuthType;
    property BooleanStringForm: Integer read FBooleanStringForm write FBooleanStringForm;

    class property Instance: TSingletonSettingObj read GetInstance;
  end;


implementation

{ TSingletonSettingObj }

constructor TSingletonSettingObj.Create;
begin
 inherited;
end;

destructor TSingletonSettingObj.Destroy;
begin
  inherited;
end;

class function TSingletonSettingObj.GetInstance: TSingletonSettingObj;
begin
  if not Assigned(FInstance) then
    FInstance := TSingletonSettingObj.Create;
  Result := FInstance;
end;

class procedure TSingletonSettingObj.RegisterFormClassForTheming(const AFormClass: TCustomFormClass; const Component: TComponent);
{$IF CompilerVersion >= 32.0}
Var
{$IF CompilerVersion > 33.0} // Breaking change to the Open Tools API - They fixed the wrongly defined interface
  ITS: IOTAIDEThemingServices;
{$ELSE}
  ITS: IOTAIDEThemingServices250;
{$IFEND}
{$IFEND}
begin
{$IF CompilerVersion >= 32.0}
{$IF CompilerVersion > 33.0}
  If Supports(BorlandIDEServices, IOTAIDEThemingServices, ITS) Then
{$ELSE}
  If Supports(BorlandIDEServices, IOTAIDEThemingServices250, ITS) Then
{$IFEND}
    If ITS.IDEThemingEnabled Then
    begin
      ITS.RegisterFormClass(AFormClass);
      If Assigned(Component) Then
        ITS.ApplyTheme(Component);
    end;
{$IFEND}
end;

end.
