unit OCW.Util.Core;

interface

uses
  System.SysUtils, System.Generics.Collections, System.JSON, System.Rtti, Neslib.Yaml
  {$IF CompilerVersion <= 32.0}, System.JSONConsts, System.TypInfo{$IFEND};

type

  {$IF CompilerVersion <= 32.0}
  TJsonClassHelper = class helper for TJSONObject
  public
    function FindValue(const APath: string): TJSONValue;
  end;

  TJsonValueHelper = class helper for TJSONValue
  public
    function AsType<T>: T; overload;
    function AsTValue(ATypeInfo: PTypeInfo; var AValue: TValue): Boolean;
    function FindValue(const APath: string): TJSONValue;
  end;

  {$IFEND}


  TActiveType = (atSwaggerJSON, atOpenAPiJson, atOpenAPIYaml, atPostManCollection, atNone);

  TSwaggerJson = class
  private
    FJSONObject: TJSONObject;
  public
    constructor Create;
    destructor Destroy; override;
    property JSONObject: TJSONObject read FJSONObject;
  end;

  TOpenAPIJson = class
  private
    FJSONObject: TJSONObject;
  public
    constructor Create;
    destructor Destroy; override;
    property JSONObject: TJSONObject read FJSONObject;
  end;

  TFinalParsingObject = class
  private
    class var FPrifixType: Byte;
    class var FFinalObjectType: TActiveType;
    class var FFinalJson: TObject;
    class var FFinalYaml: IYamlDocument;
    class var FInstance: TFinalParsingObject;
    class function GetInstance: TFinalParsingObject; static;
  public
    class procedure Clear;
    class property Instance: TFinalParsingObject read GetInstance;
    class property PrefixType: Byte read FPrifixType write FPrifixType;
    class property FinalJson: TObject read FFinalJson write FFinalJson;
    class property FinalYaml: IYamlDocument read FFinalYaml write FFinalYaml;
    class property FinalObjectType: TActiveType read FFinalObjectType write FFinalObjectType;
  end;

  IExtractedOpenAPI<T> = interface
   ['{BFA49870-1BDE-4930-8644-9E769AFC2439}']
    function GetExtracted: T;
    procedure SetExtracted(AExtracted: T);
  end;

  TExtractedOpenAPI<T> = class(TInterfacedObject, IExtractedOpenAPI<T>)
    private
      FExtracted: T;
      function GetExtracted: T;
      procedure SetExtracted(AExtracted: T);
    public
      property ExtractedObject: T read GetExtracted write SetExtracted;
  end;


  TJsonObjectHelper = class helper for TJSONObject
  public
    function GetFindValue(const APath: string): string;
  end;

  procedure MarkUsed(const AValue: Variant);
  procedure MarkJsonUsed(const AValue: TJSONArray);
  procedure MarkObjectUsed(const AValue: TObject);

implementation

procedure MarkUsed(const AValue: Variant);
begin
  // Do nothing. This procedure is only to mark variables as used.
  // This will prevent the compiler to show wronge warnings!
end;

procedure MarkJsonUsed(const AValue: TJSONArray);
begin
  // Do nothing. This procedure is only to mark variables as used.
end;

procedure MarkObjectUsed(const AValue: TObject);
begin
  // Do nothing. This procedure is only to mark variables as used.
end;

{ TExtractedOpenAPI<T> }

function TExtractedOpenAPI<T>.GetExtracted: T;
begin
  Result := TValue.From<T>(FExtracted).AsType<T>;
end;

procedure TExtractedOpenAPI<T>.SetExtracted(AExtracted: T);
begin
  FExtracted := AExtracted;
end;

{ TFinalParsingObject }

class procedure TFinalParsingObject.Clear;
begin
  FFinalObjectType := TActiveType.atNone;
  FreeAndNil(FFinalJson);
  FFinalYaml := nil;

  if Assigned(FInstance) then
    FreeAndNil(FInstance);
end;

class function TFinalParsingObject.GetInstance: TFinalParsingObject;
begin
  if FInstance = nil then
  begin
    FInstance := TFinalParsingObject.Create;
    FInstance.FinalJson := nil;
  end;
  Result := FInstance;
end;

{ TSwaggerJson }

constructor TSwaggerJson.Create;
begin
  FJSONObject := TJSONObject.Create;
end;

destructor TSwaggerJson.Destroy;
begin
  if Assigned(FJSONObject) then
    FJSONObject.Free;
  inherited;
end;

{ TOpenAPIJson }

constructor TOpenAPIJson.Create;
begin
  FJSONObject := TJSONObject.Create;
end;

destructor TOpenAPIJson.Destroy;
begin
  if Assigned(FJSONObject) then
    FJSONObject.Free;
  inherited;
end;

{$IF CompilerVersion <= 32.0}
{ TJsonClassHelper }

function TJsonClassHelper.FindValue(const APath: string): TJSONValue;
var
  LParser: TJSONPathParser;
  LCurrentValue: TJSONValue;
begin
  if (Self = nil) or (APath = '') then
    Exit(Self);
  Result := nil;
  LParser := TJSONPathParser.Create(APath);
  LCurrentValue := Self;
  while not LParser.IsEof do
  begin
    case LParser.NextToken of
      TJSONPathParser.TToken.Name:
        if LCurrentValue.ClassType = TJSONObject then
        begin
          LCurrentValue := TJSONObject(LCurrentValue).Values[LParser.TokenName];
          if LCurrentValue = nil then
            Exit;
        end
        else
          Exit;
      TJSONPathParser.TToken.ArrayIndex:
        if LCurrentValue.ClassType = TJSONArray then
          if LParser.TokenArrayIndex < TJSONArray(LCurrentValue).Count then
            LCurrentValue := TJSONArray(LCurrentValue).Items[LParser.TokenArrayIndex]
          else
            Exit
        else
          Exit;
      TJSONPathParser.TToken.Error,
      TJSONPathParser.TToken.Undefined:
        Exit;
      TJSONPathParser.TToken.Eof:
        ;
    end;
  end;
  Result := LCurrentValue;
end;

{TJsonValueHelper}

function TJsonValueHelper.AsTValue(ATypeInfo: PTypeInfo; var AValue: TValue): Boolean;
begin
  Result := True;
  case ATypeInfo^.Kind of
    tkClass:
      TValue.Make(@Self, ATypeInfo, AValue);
  else
      Result := False;
  end;
end;

function TJsonValueHelper.AsType<T>: T;
var
  LTypeInfo: PTypeInfo;
  LValue: TValue;
begin
  LTypeInfo := System.TypeInfo(T);
  if not AsTValue(LTypeInfo, LValue) then
    raise EJSONException.CreateResFmt(@SCannotConvertJSONValueToType,
      [ClassName, LTypeInfo.Name]);
  Result := LValue.AsType<T>;
end;

function TJsonValueHelper.FindValue(const APath: string): TJSONValue;
var
  LParser: TJSONPathParser;
  LCurrentValue: TJSONValue;
begin
  if (Self = nil) or (APath = '') then
    Exit(Self);
  Result := nil;
  LParser := TJSONPathParser.Create(APath);
  LCurrentValue := Self;
  while not LParser.IsEof do
  begin
    case LParser.NextToken of
      TJSONPathParser.TToken.Name:
        if LCurrentValue.ClassType = TJSONObject then
        begin
          LCurrentValue := TJSONObject(LCurrentValue).Values[LParser.TokenName];
          if LCurrentValue = nil then
            Exit;
        end
        else
          Exit;
      TJSONPathParser.TToken.ArrayIndex:
        if LCurrentValue.ClassType = TJSONArray then
          if LParser.TokenArrayIndex < TJSONArray(LCurrentValue).Count then
            LCurrentValue := TJSONArray(LCurrentValue).Items[LParser.TokenArrayIndex]
          else
            Exit
        else
          Exit;
      TJSONPathParser.TToken.Error,
      TJSONPathParser.TToken.Undefined:
        Exit;
      TJSONPathParser.TToken.Eof:
        ;
    end;
  end;
  Result := LCurrentValue;
end;
{$IFEND}

{ TJsonObjectHelper }

function TJsonObjectHelper.GetFindValue(const APath: string): string;
begin
  if Assigned(Self.FindValue(APath)) then
    Result := Self.GetValue(APath).Value
  else
    Result := EmptyStr;
end;

begin
end.
