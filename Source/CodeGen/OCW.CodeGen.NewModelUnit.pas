{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit OCW.CodeGen.NewModelUnit;

interface

uses
  ToolsApi, System.IOUtils, System.JSON, System.Generics.Collections,
  System.StrUtils, System.SysUtils, System.Types, System.Classes,

  OCW.Util.Core,
  OCW.CodeGen.NewUnit,
  OCW.Util.Rest,
  OCW.Util.OpenAPIHelper,
  OCW.Util.Setting;

type
  TNewModelUnitEx = class(TNewUnit)
  private
    function PrepareMainSourceString(ARawSource: string; AUnitName: string): string;
    function PrepareSourceString(ARawSource: string): string;
    function GetSuffix(AMethodType: TMethodType): string;
    function GetPrefix(AMethodType: TMethodType): string;
    function BuildFunctionBody(AMethodObj: TMethodObject): string;
    function RefineParameterList(var AParamList: string): string;
    function ConvertToCamelCase(const AInputStr: string): string;
    function ParameterValueExpression(AParam: TParameter; AUrlEncode: Boolean): string;
    function HasRequestBody(AMethodObj: TMethodObject): Boolean;
    function RequestClassName(AMethodObj: TMethodObject): string;
    function BuildRequestClassSample(const AClassName: string): string;
    procedure GenerateRequestClasses(AMethodObj: TMethodObject; ADefinitions, AImplementations: TStringBuilder; AKnownClasses: TDictionary<string, Boolean>);
    function ConvertAuthenticationType(AAuthType: Byte): string;
    function AddBreaklines(const AText: string; ADelimitter: Char; ABreakLength: Integer = 1000): string;
//    function GenerateRequestClass(const AJSONString: string): string;
  protected
    FIsMainUnit: Boolean;
    FModelClassName: string;
    FOpenAPIPaths: TObjectDictionary<string, TOpenAPIPath>;
    FButtonClickEvents: TDictionary<string, string>;

    function NewImplSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile; override;
  public
    constructor Create(const AModelClassName: string; const APersonality: string = '';
                       AIsMainUnit: Boolean = False; AOpenAPIPaths: TObjectDictionary<string, TOpenAPIPath> = nil);
  end;


implementation
uses
  {$IFDEF CODESITE}CodeSiteLogging,{$ENDIF}
  VCL.Dialogs,
  Neslib.Yaml,
  OCW.CodeGen.Templates,
  OCW.CodeGen.SourceFile;

{ TNewModelUnitEx }

function TNewModelUnitEx.ConvertAuthenticationType(AAuthType: Byte): string;
begin
  Result := 'bearer';
  case AAuthType of
    0: Result := 'No Auth';
    1: Result := 'basic';
    2: Result := 'bearer';
  end;
end;

function TNewModelUnitEx.ConvertToCamelCase(const AInputStr: string): string;
var
  I: Integer;
  LvChar: Char;
begin
  Result := EmptyStr;
  for I := 1 to Length(AInputStr) do
  begin
    LvChar := AInputStr[I];
    if I = 1 then
      Result := Result + UpperCase(LvChar)
    else
      Result := Result + LvChar;
  end;
end;

constructor TNewModelUnitEx.Create(const AModelClassName, APersonality: string; AIsMainUnit: Boolean;
                                   AOpenAPIPaths: TObjectDictionary<string, TOpenAPIPath>);
begin
  Assert(Length(AModelClassName) > 0);
  FAncestorName := EmptyStr;
  FFormName := EmptyStr;
  FImplFileName := EmptyStr;
  FIntfFileName := EmptyStr;
  FModelClassName := AModelClassName;
  FIsMainUnit := AIsMainUnit;
  Personality := APersonality;

  if AIsMainUnit then
    FFormName := 'Frm_Main';

  if AModelClassName.Equals('RestClient') then
    FImplFileName := 'OpenAPITransport.pas';

  if AModelClassName.Equals('ConsoleSample') then
    FImplFileName := 'OpenAPISample.pas';

  if AModelClassName.Equals('Model') then
  begin
    FAncestorName := EmptyStr;
    FFormName := EmptyStr;
    FIntfFileName := EmptyStr;
    FImplFileName := 'OpenAPIClient.pas';
  end;

  FOpenAPIPaths:= AOpenAPIPaths;
end;

//function TNewModelUnitEx.GenerateRequestClass(const AJSONString: string): string;
//var
//  LvJSONValue: TJSONValue;
//  LvJSONObject: TJSONObject;
//  LvModelValue, PromptValue: string;
//  LvClassDef: TStringBuilder;
//begin
//  LvJSONValue := nil;
//  Result := '';
//  try
//    LvJSONValue := TJSONObject.ParseJSONValue(AJSONString);
//  except on E: Exception do
//  {$IFDEF CODESITE}
//    CodeSite.Send('Cannot generate class for : '+ AJSONString + #13 + 'Error: ' + E.Message);
//  {$ENDIF}
//  end;
//
//  if not Assigned(LvJSONValue) then
//    Exit;
//
//  try
//    if LvJSONValue is TJSONObject then
//    begin
//      LvJSONObject := TJSONObject(LvJSONValue);
//
//      // Extract values from JSON
//      LvModelValue := LvJSONObject.GetValue<string>('model');
//      PromptValue := LvJSONObject.GetValue<string>('prompt');
//
//      // Create class definition
//      LvClassDef := TStringBuilder.Create;
//      try
//        LvClassDef.AppendLine('type')
//                .AppendLine('  TGeneratedClass = class')
//                .AppendLine('  private')
//                .AppendLine('    FModel: string;')
//                .AppendLine('    FPrompt: string;')
//                .AppendLine('  public')
//                .AppendLine('    constructor Create(const AModel, APrompt: string);')
//                .AppendLine('    property Model: string read FModel;')
//                .AppendLine('    property Prompt: string read FPrompt;')
//                .AppendLine('  end;')
//                .AppendLine
//                .AppendLine('{ TGeneratedClass }')
//                .AppendLine
//                .AppendLine('constructor TGeneratedClass.Create(const AModel, APrompt: string);')
//                .AppendLine('begin')
//                .AppendLine('  FModel := AModel;')
//                .AppendLine('  FPrompt := APrompt;')
//                .AppendLine('end;');
//
//        Result := LvClassDef.ToString;
//      finally
//        LvClassDef.Free;
//      end;
//    end
//    else
//      raise Exception.Create('Invalid JSON format');
//  finally
//    LvJSONValue.Free;
//  end;
//
//end;

function TNewModelUnitEx.GetPrefix(AMethodType: TMethodType): string;
begin
  Result := EmptyStr;
  if TFinalParsingObject.PrefixType = 1 then
  begin
    case AMethodType of
      mtGet: Result := 'Get_';
      mtPost: Result := 'Post_';
      mtPatch: Result := 'Patch_';
      mtPut: Result := 'Put_';
      mtDelete: Result := 'Delete_';
    end;
  end
  else
    Result := EmptyStr;
end;

function TNewModelUnitEx.GetSuffix(AMethodType: TMethodType): string;
begin
  Result := EmptyStr;
  if TFinalParsingObject.PrefixType = 0 then
  begin
    case AMethodType of
      mtGet: Result := '_Get';
      mtPost: Result := '_Post';
      mtPatch: Result := '_Patch';
      mtPut: Result := '_Put';
      mtDelete: Result := '_Delete';
    end;
  end
  else
    Result := EmptyStr;
end;

function TNewModelUnitEx.ParameterValueExpression(AParam: TParameter; AUrlEncode: Boolean): string;
var
  LvParamName: string;
  LvExpression: string;
begin
  LvParamName := ConvertToCamelCase(AParam.Name);

  if AParam.DataType.ToLower.Equals('integer') then
    LvExpression := 'A' + LvParamName + '.ToString'

  else if AParam.DataType.ToLower.Equals('string') then
    LvExpression := 'A' + LvParamName

  else if AParam.DataType.ToLower.Equals('boolean') then
    LvExpression := 'CastByBooleanSetting(' + 'A' + LvParamName + ', ' + TSingletonSettingObj.Instance.BooleanStringForm.ToString +')'

  else if (AParam.DataType.ToLower.Equals('number')) or (AParam.DataType.ToLower.Equals('float')) then
    LvExpression := 'FloatToStr(' + 'A' + LvParamName + ')'

  else if AParam.DataType.ToLower.Equals('array') then
    LvExpression := 'String.Join('','', A' + LvParamName + ')'
  else if AParam.DataType.ToLower.Equals('object') then
    LvExpression := 'A' + LvParamName + '.ToString'
  else
    LvExpression := 'VarToStr(A' + LvParamName + ')';

  if AUrlEncode then
    Result := 'TNetEncoding.URL.Encode(' + LvExpression + ')'
  else
    Result := LvExpression;
end;

function TNewModelUnitEx.BuildFunctionBody(AMethodObj: TMethodObject): string;
var
  LvParam: TParameter;

  LvInPathParams: string;
  LvQueryParams: string;
  LvAddressExpression: string;
  LvHeaderParams: TStringList;

  LvParameterType: string;
  LvFullParamList: string;
  LvOptionalStatements: string;
  LvLastHeaderIndex: Integer;
  I: Integer;
begin
  Result := EmptyStr;
  LvParameterType := EmptyStr;
  LvInPathParams := EmptyStr;
  LvQueryParams := EmptyStr;
  LvAddressExpression := 'LvStruct.ApiAddress';
  LvFullParamList:= EmptyStr;
  LvOptionalStatements := EmptyStr;
  LvLastHeaderIndex := -1;
  LvHeaderParams := TStringList.Create;
  try
    if Assigned(AMethodObj.Params) then
    begin
      for LvParam in AMethodObj.Params do
      begin
        LvParameterType := LvParam.&In.Trim.ToLower;

        if LvParameterType.Equals('path') then
        begin
          LvInPathParams := ParameterValueExpression(LvParam, True);
          LvAddressExpression := Format('StringReplace(StringReplace(%s, %s, %s, [rfReplaceAll]), %s, %s, [rfReplaceAll])',
            [LvAddressExpression, QuotedStr('{' + LvParam.Originalname + '}'), LvInPathParams,
             QuotedStr(':' + LvParam.Originalname), LvInPathParams]);
        end
        else if LvParameterType.Equals('query') then
        begin
          LvQueryParams := LvQueryParams +
            IfThen(LvQueryParams.IsEmpty, EmptyStr, ' + ') +
            QuotedStr(IfThen(LvQueryParams.IsEmpty, '?', '&') + LvParam.Originalname + '=' ) + ' + ' + ParameterValueExpression(LvParam, True)
        end
        else if LvParameterType.Equals('header') then
        begin
          if LvLastHeaderIndex = -1 then
          begin
            LvLastHeaderIndex := 0;
            LvHeaderParams.Add('LvStruct.CustomHeaders[0] := ' + QuotedStr(LvParam.Originalname) + ';');
            LvHeaderParams.Add('LvStruct.CustomHeaders[1] := ' + ParameterValueExpression(LvParam, False) + ';');
          end
          else
          begin
            Inc(LvLastHeaderIndex, 2);
            LvHeaderParams.Add('LvStruct.CustomHeaders[' + LvLastHeaderIndex.ToString + '] := ' + QuotedStr(LvParam.Originalname) + ';');
            LvHeaderParams.Add('LvStruct.CustomHeaders[' + (LvLastHeaderIndex + 1).ToString + '] := ' + ParameterValueExpression(LvParam, False) + ';');
          end;
        end;
      end;
    end;

    LvFullParamList := LvAddressExpression + IfThen(LvQueryParams.Trim.IsEmpty, EmptyStr, ' + ' + LvQueryParams);

    if HasRequestBody(AMethodObj) then
    begin
      if not AMethodObj.RequestBody.ContentType.Trim.IsEmpty then
        LvOptionalStatements := LvOptionalStatements + '    LvStruct.ContentType := ' + QuotedStr(AMethodObj.RequestBody.ContentType) + ';' + sLineBreak;
      LvOptionalStatements := LvOptionalStatements + '    LvStruct.RequestObject := ARequestObj;' + sLineBreak;
    end;

    if LvHeaderParams.Count > 0 then
      LvOptionalStatements := LvOptionalStatements + '    LvStruct.CustomHeadersCount := ' + LvHeaderParams.Count.ToString + ';' + sLineBreak;

    for I := 0 to Pred(LvHeaderParams.Count) do
      LvOptionalStatements := LvOptionalStatements + '    ' + LvHeaderParams[I] + sLineBreak;

    case AMethodObj.MethodType of
      mtGet: Result := Format(sGetFunctionBody, [AMethodObj._MethodName, LvFullParamList, LvOptionalStatements]);
      mtPost: Result := Format(sPostFunctionBody, [AMethodObj._MethodName, LvFullParamList, LvOptionalStatements]);
      mtPatch: Result := Format(sPatchFunctionBody, [AMethodObj._MethodName, LvFullParamList, LvOptionalStatements]);
      mtPut: Result := Format(sPutFunctionBody, [AMethodObj._MethodName, LvFullParamList, LvOptionalStatements]);
      mtDelete: Result := Format(sDeleteFunctionBody, [AMethodObj._MethodName, LvFullParamList, LvOptionalStatements]);
    end;

    if Result.IsEmpty then
      Result := 'begin' + sLineBreak;
  finally
    LvHeaderParams.Free;
  end;
end;

function TNewModelUnitEx.NewImplSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
var
  lUnitIdent: string;
  lFormName: string;
  lFileName: string;
  LvUnitContent: string;
begin
  lUnitIdent := EmptyStr;
  lFormName := EmptyStr;
  lFileName := EmptyStr;
  LvUnitContent := EmptyStr;

  // http://stackoverflow.com/questions/4196412/how-do-you-retrieve-a-new-unit-name-from-delphis-open-tools-api
  // So using method mentioned by Marco Cantu.

  (BorlandIDEServices as IOTAModuleServices).GetNewModuleAndClassName(EmptyStr, lUnitIdent, lFormName, lFileName);
  if FIsMainUnit then
  begin
    if Assigned(FOpenAPIPaths) then
    begin
      try
        LvUnitContent := PrepareMainSourceString(sMainUnit, lUnitIdent);
        Result := TSourceFile.Create(LvUnitContent, []);
      except on E: Exception do
        begin
          Result := nil;
          raise;
        end;
      end;
    end
    else
      Result := TSourceFile.Create(sMainUnit, [lUnitIdent]);
  end
  else if FModelClassName.Equals('Model') then
  begin
    if Assigned(FOpenAPIPaths) then
    begin
      try
        LvUnitContent := PrepareSourceString(sClientClassUnit);
      except on E: Exception do
        {$IFDEF CODESITE}
          CodeSite.Send('PrepareSourceString(sClientClassUnit)' + #13 + E.Message);
        {$ELSE}
        raise;
        {$ENDIF}
      end;

      Result := TSourceFile.Create(LvUnitContent, []);
    end
    else
      Result := TSourceFile.Create(sClientClassUnit, [lUnitIdent])
  end else if FModelClassName.Equals('RestClient') then
  begin
    LvUnitContent := sRestClientPartOne + sRestClientPartTwo;
    Result := TSourceFile.Create(LvUnitContent, ['OCW']);
  end else if FModelClassName.Equals('ConsoleSample') then
  begin
    Result := TSourceFile.Create(sConsoleSampleUnit, [TSingletonSettingObj.Instance.ConsoleSampleCall,
                                                      TSingletonSettingObj.Instance.ConsoleSampleVars]);
  end;
end;

function CleanDelphiIdentifier(const AValue, AFallback: string): string;
var
  I: Integer;
begin
  Result := AValue.Trim;
  for I := 1 to Length(Result) do
  begin
    if not CharInSet(Result[I], ['a'..'z', 'A'..'Z', '0'..'9', '_']) then
      Result[I] := '_';
  end;

  while Result.Contains('__') do
    Result := StringReplace(Result, '__', '_', [rfReplaceAll]);

  Result := Result.Trim(['_']);
  if Result.IsEmpty then
    Result := AFallback;

  if CharInSet(Result[1], ['0'..'9']) then
    Result := '_' + Result;
end;

function IsDelphiReservedWord(const AIdentifier: string): Boolean;
const
  DelphiReservedWords: array[0..72] of string = (
    'and', 'array', 'as', 'asm', 'begin', 'case', 'class', 'const',
    'constructor', 'destructor', 'dispinterface', 'div', 'do', 'downto',
    'else', 'end', 'except', 'exports', 'file', 'finalization', 'finally',
    'for', 'function', 'goto', 'if', 'implementation', 'in', 'inherited',
    'initialization', 'inline', 'interface', 'is', 'label', 'library',
    'mod', 'nil', 'not', 'object', 'of', 'or', 'out', 'packed',
    'procedure', 'program', 'property', 'raise', 'record', 'repeat',
    'resourcestring', 'set', 'shl', 'shr', 'string', 'then', 'threadvar',
    'to', 'try', 'type', 'unit', 'until', 'uses', 'var', 'while',
    'with', 'xor', 'private', 'protected', 'public', 'published',
    'automated', 'operator', 'helper', 'reference');
var
  I: Integer;
begin
  Result := False;
  for I := Low(DelphiReservedWords) to High(DelphiReservedWords) do
  begin
    if SameText(AIdentifier, DelphiReservedWords[I]) then
      Exit(True);
  end;
end;

function DelphiEscapedIdentifier(const AIdentifier: string): string;
begin
  Result := AIdentifier;
  if IsDelphiReservedWord(Result) then
    Result := '&' + Result;
end;

function DelphiPropertyName(const AValue: string): string;
begin
  Result := CleanDelphiIdentifier(AValue, 'Value');
  Result := UpperCase(Copy(Result, 1, 1)) + Copy(Result, 2, MaxInt);
end;

function DelphiClassName(const AValue: string): string;
begin
  Result := DelphiPropertyName(AValue);
  if not Result.StartsWith('T') then
    Result := 'T' + Result;
end;

function JsonPrimitiveType(AJsonValue: TJSONValue): string;
var
  LvText: string;
  LvInteger: Integer;
  LvFloat: Double;
begin
  Result := 'string';
  if AJsonValue is TJSONNumber then
  begin
    LvText := AJsonValue.Value;
    if TryStrToInt(LvText, LvInteger) then
      Result := 'Integer'
    else if TryStrToFloat(LvText, LvFloat) then
      Result := 'Double'
    else
      Result := 'Double';
  end
  else if AJsonValue is TJSONBool then
    Result := 'Boolean'
  else if AJsonValue is TJSONString then
    Result := 'string';
end;

function SchemaPrimitiveType(const ATypeName, AFormat: string): string;
begin
  Result := 'Variant';
  if ATypeName.Equals('string') then
    Result := 'string'
  else if ATypeName.Equals('integer') then
    Result := 'Integer'
  else if ATypeName.Equals('number') or ATypeName.Equals('float') then
    Result := 'Double'
  else if ATypeName.Equals('boolean') then
    Result := 'Boolean'
  else if ATypeName.Equals('object') then
    Result := 'TJsonObject'
  else if ATypeName.Equals('array') then
    Result := 'TArray<string>';
end;

function TNewModelUnitEx.HasRequestBody(AMethodObj: TMethodObject): Boolean;
begin
  Result := Assigned(AMethodObj) and Assigned(AMethodObj.RequestBody) and
            ((not AMethodObj.RequestBody.SchemaJson.Trim.IsEmpty) or
             (not AMethodObj.RequestBody.Example.Trim.IsEmpty) or
             (AMethodObj.RequestBody.Properties.Count > 0));
end;

function TNewModelUnitEx.RequestClassName(AMethodObj: TMethodObject): string;
begin
  Result := DelphiClassName(GetPrefix(AMethodObj.MethodType) + AMethodObj._MethodName + GetSuffix(AMethodObj.MethodType) + 'Request');
end;

function TNewModelUnitEx.BuildRequestClassSample(const AClassName: string): string;
begin
  Result := AClassName + '.Create';
end;

function CloneJsonValue(AJsonValue: TJSONValue): TJSONValue;
begin
  Result := nil;
  if Assigned(AJsonValue) then
    Result := TJSONObject.ParseJSONValue(AJsonValue.ToJSON);
end;

function CloneJsonObject(AJsonObject: TJSONObject): TJSONObject;
var
  LvValue: TJSONValue;
begin
  Result := nil;
  LvValue := CloneJsonValue(AJsonObject);
  if LvValue is TJSONObject then
    Result := LvValue as TJSONObject
  else
    LvValue.Free;
end;

function JsonPairCloneValue(AJsonValue: TJSONValue): TJSONValue;
begin
  Result := CloneJsonValue(AJsonValue);
  if not Assigned(Result) then
    Result := TJSONString.Create(EmptyStr);
end;

function CodeGenYamlNodeToJsonValue(AYamlNode: TYamlNode): TJSONValue;
var
  I: Integer;
  LvObject: TJSONObject;
  LvArray: TJSONArray;
begin
  if AYamlNode.IsNil then
    Exit(TJSONString.Create(EmptyStr));

  if AYamlNode.IsScalar then
    Exit(TJSONString.Create(AYamlNode.ToString));

  if AYamlNode.IsSequence then
  begin
    LvArray := TJSONArray.Create;
    for I := 0 to Pred(AYamlNode.Count) do
      LvArray.AddElement(CodeGenYamlNodeToJsonValue(AYamlNode.Nodes[I]));

    Exit(LvArray);
  end;

  LvObject := TJSONObject.Create;
  for I := 0 to Pred(AYamlNode.Count) do
    LvObject.AddPair(AYamlNode.Elements[I].Key.ToString, CodeGenYamlNodeToJsonValue(AYamlNode.Elements[I].Value));

  Result := LvObject;
end;

function FindYamlChildByKey(AYamlNode: TYamlNode; const AKey: string; out AValue: TYamlNode): Boolean;
var
  I: Integer;
begin
  Result := False;
  AValue := Default(TYamlNode);
  if AYamlNode.IsNil or not AYamlNode.IsMapping then
    Exit;

  for I := 0 to Pred(AYamlNode.Count) do
  begin
    if AYamlNode.Elements[I].Key.ToString.Equals(AKey) then
    begin
      AValue := AYamlNode.Elements[I].Value;
      Exit(True);
    end;
  end;
end;

function DecodeJsonPointerPart(const AValue: string): string;
begin
  Result := StringReplace(AValue, '~1', '/', [rfReplaceAll]);
  Result := StringReplace(Result, '~0', '~', [rfReplaceAll]);
end;

function ResolveSchemaRef(const ARef: string): TJSONObject;
var
  LvJsonValue: TJSONValue;
  LvPath: string;
  LvParts: TArray<string>;
  LvPart: string;
  LvDecodedPart: string;
  LvYamlNode: TYamlNode;
  LvYamlChild: TYamlNode;
  I: Integer;
begin
  Result := nil;
  if not ARef.StartsWith('#/') then
    Exit;

  LvPath := Copy(ARef, 3, MaxInt);
  LvParts := LvPath.Split(['/']);

  if Assigned(TFinalParsingObject.FinalJson) and (TFinalParsingObject.FinalJson is TJSONObject) then
  begin
    LvJsonValue := TFinalParsingObject.FinalJson as TJSONObject;
    for LvPart in LvParts do
    begin
      LvDecodedPart := DecodeJsonPointerPart(LvPart);
      if not (LvJsonValue is TJSONObject) then
        Exit;

      LvJsonValue := (LvJsonValue as TJSONObject).FindValue(LvDecodedPart);
      if not Assigned(LvJsonValue) then
        Exit;
    end;

    if LvJsonValue is TJSONObject then
      Result := CloneJsonObject(LvJsonValue as TJSONObject);

    Exit;
  end;

  if Assigned(TFinalParsingObject.FinalYaml) then
  begin
    LvYamlNode := TFinalParsingObject.FinalYaml.Root;
    for I := Low(LvParts) to High(LvParts) do
    begin
      if not FindYamlChildByKey(LvYamlNode, DecodeJsonPointerPart(LvParts[I]), LvYamlChild) then
        Exit;

      LvYamlNode := LvYamlChild;
    end;

    LvJsonValue := CodeGenYamlNodeToJsonValue(LvYamlNode);
    if LvJsonValue is TJSONObject then
      Result := LvJsonValue as TJSONObject
    else
      LvJsonValue.Free;
  end;
end;

function RefClassName(const ARef: string): string;
var
  LvName: string;
  LvSlashPos: Integer;
begin
  LvName := ARef;
  LvSlashPos := LastDelimiter('/', LvName);
  if LvSlashPos > 0 then
    LvName := Copy(LvName, LvSlashPos + 1, MaxInt);

  Result := DelphiClassName(DecodeJsonPointerPart(LvName));
end;

function AddOrGetPropertiesObject(AJsonObject: TJSONObject): TJSONObject;
begin
  if AJsonObject.FindValue('properties') is TJSONObject then
    Result := AJsonObject.FindValue('properties') as TJSONObject
  else
  begin
    Result := TJSONObject.Create;
    AJsonObject.AddPair('properties', Result);
  end;
end;

function BuildEffectiveSchema(AJsonObject: TJSONObject): TJSONObject;
var
  LvRefValue: TJSONValue;
  LvComposedArray: TJSONArray;
  LvEffectivePart: TJSONObject;
  LvMergedProperties: TJSONObject;
  LvPartProperties: TJSONObject;
  LvProperty: TJSONPair;
  I, J: Integer;
begin
  Result := nil;
  if not Assigned(AJsonObject) then
    Exit;

  LvRefValue := AJsonObject.FindValue('$ref');
  if Assigned(LvRefValue) then
  begin
    Result := ResolveSchemaRef(LvRefValue.Value);
    if Assigned(Result) then
      Exit;
  end;

  if AJsonObject.FindValue('allOf') is TJSONArray then
  begin
    Result := TJSONObject.Create;
    Result.AddPair('type', 'object');
    LvMergedProperties := AddOrGetPropertiesObject(Result);
    LvComposedArray := AJsonObject.FindValue('allOf') as TJSONArray;
    for I := 0 to Pred(LvComposedArray.Count) do
    begin
      if not (LvComposedArray.Items[I] is TJSONObject) then
        Continue;

      LvEffectivePart := BuildEffectiveSchema(LvComposedArray.Items[I] as TJSONObject);
      try
        if Assigned(LvEffectivePart) and (LvEffectivePart.FindValue('properties') is TJSONObject) then
        begin
          LvPartProperties := LvEffectivePart.FindValue('properties') as TJSONObject;
          for J := 0 to Pred(LvPartProperties.Count) do
          begin
            LvProperty := LvPartProperties.Pairs[J];
            if not Assigned(LvMergedProperties.FindValue(LvProperty.JsonString.Value)) then
              LvMergedProperties.AddPair(LvProperty.JsonString.Value, JsonPairCloneValue(LvProperty.JsonValue));
          end;
        end;
      finally
        LvEffectivePart.Free;
      end;
    end;
    Exit;
  end;

  if AJsonObject.FindValue('oneOf') is TJSONArray then
  begin
    LvComposedArray := AJsonObject.FindValue('oneOf') as TJSONArray;
    if (LvComposedArray.Count > 0) and (LvComposedArray.Items[0] is TJSONObject) then
    begin
      Result := BuildEffectiveSchema(LvComposedArray.Items[0] as TJSONObject);
      if Assigned(Result) then
        Exit;
    end;
  end;

  if AJsonObject.FindValue('anyOf') is TJSONArray then
  begin
    LvComposedArray := AJsonObject.FindValue('anyOf') as TJSONArray;
    if (LvComposedArray.Count > 0) and (LvComposedArray.Items[0] is TJSONObject) then
    begin
      Result := BuildEffectiveSchema(LvComposedArray.Items[0] as TJSONObject);
      if Assigned(Result) then
        Exit;
    end;
  end;

  Result := CloneJsonObject(AJsonObject);
end;

procedure BuildClassFromJsonExample(const AClassName: string; AJsonObject: TJSONObject; ADefinitions, AImplementations: TStringBuilder; AKnownClasses: TDictionary<string, Boolean>); forward;
procedure BuildClassFromJsonSchema(const AClassName: string; ASchemaObject: TJSONObject; ADefinitions, AImplementations: TStringBuilder; AKnownClasses: TDictionary<string, Boolean>); forward;

function SchemaFieldType(const AOwnerClass, APropertyName: string; ASchemaValue: TJSONValue; ADefinitions, AImplementations: TStringBuilder; AKnownClasses: TDictionary<string, Boolean>; AOwnedObjects: TStrings): string;
var
  LvSchema: TJSONObject;
  LvEffectiveSchema: TJSONObject;
  LvItems: TJSONValue;
  LvType: string;
  LvFormat: string;
  LvChildClassName: string;
begin
  Result := 'Variant';
  if not (ASchemaValue is TJSONObject) then
    Exit;

  LvEffectiveSchema := BuildEffectiveSchema(ASchemaValue as TJSONObject);
  try
    if Assigned(LvEffectiveSchema) then
      LvSchema := LvEffectiveSchema
    else
      LvSchema := ASchemaValue as TJSONObject;

    if Assigned((ASchemaValue as TJSONObject).FindValue('$ref')) then
      LvChildClassName := RefClassName((ASchemaValue as TJSONObject).GetValue('$ref').Value)
    else
      LvChildClassName := AOwnerClass + DelphiPropertyName(APropertyName);

    LvType := EmptyStr;
    LvFormat := EmptyStr;
    if Assigned(LvSchema.FindValue('type')) then
      LvType := LvSchema.GetValue('type').Value.ToLower;
    if Assigned(LvSchema.FindValue('format')) then
      LvFormat := LvSchema.GetValue('format').Value.ToLower;

    if LvType.Equals('array') then
    begin
      Result := 'TArray<string>';
      LvItems := LvSchema.FindValue('items');
      if LvItems is TJSONObject then
      begin
        if Assigned((LvItems as TJSONObject).FindValue('$ref')) then
        begin
          LvChildClassName := RefClassName((LvItems as TJSONObject).GetValue('$ref').Value);
          BuildClassFromJsonSchema(LvChildClassName, LvItems as TJSONObject, ADefinitions, AImplementations, AKnownClasses);
          Result := 'TArray<' + LvChildClassName + '>';
        end
        else if Assigned((LvItems as TJSONObject).FindValue('properties')) or
                (Assigned((LvItems as TJSONObject).FindValue('type')) and ((LvItems as TJSONObject).GetValue('type').Value.ToLower = 'object')) or
                Assigned((LvItems as TJSONObject).FindValue('oneOf')) or
                Assigned((LvItems as TJSONObject).FindValue('anyOf')) or
                Assigned((LvItems as TJSONObject).FindValue('allOf')) then
        begin
          LvChildClassName := AOwnerClass + DelphiPropertyName(APropertyName) + 'Item';
          BuildClassFromJsonSchema(LvChildClassName, LvItems as TJSONObject, ADefinitions, AImplementations, AKnownClasses);
          Result := 'TArray<' + LvChildClassName + '>';
        end
        else if Assigned((LvItems as TJSONObject).FindValue('type')) then
          Result := 'TArray<' + SchemaPrimitiveType((LvItems as TJSONObject).GetValue('type').Value.ToLower, '') + '>';
      end;
      Exit;
    end;

    if Assigned(LvSchema.FindValue('properties')) or LvType.Equals('object') or
       Assigned(LvSchema.FindValue('oneOf')) or Assigned(LvSchema.FindValue('anyOf')) or Assigned(LvSchema.FindValue('allOf')) then
    begin
      BuildClassFromJsonSchema(LvChildClassName, LvSchema, ADefinitions, AImplementations, AKnownClasses);
      AOwnedObjects.Add(DelphiPropertyName(APropertyName) + '=' + LvChildClassName);
      Exit(LvChildClassName);
    end;

    Result := SchemaPrimitiveType(LvType, LvFormat);
  finally
    LvEffectiveSchema.Free;
  end;
end;

function ExampleFieldType(const AOwnerClass, APropertyName: string; AJsonValue: TJSONValue; ADefinitions, AImplementations: TStringBuilder; AKnownClasses: TDictionary<string, Boolean>; AOwnedObjects: TStrings): string;
var
  LvArray: TJSONArray;
  LvChildClassName: string;
begin
  Result := 'string';
  if AJsonValue is TJSONObject then
  begin
    LvChildClassName := AOwnerClass + DelphiPropertyName(APropertyName);
    BuildClassFromJsonExample(LvChildClassName, AJsonValue as TJSONObject, ADefinitions, AImplementations, AKnownClasses);
    AOwnedObjects.Add(DelphiPropertyName(APropertyName) + '=' + LvChildClassName);
    Exit(LvChildClassName);
  end;

  if AJsonValue is TJSONArray then
  begin
    LvArray := AJsonValue as TJSONArray;
    if (LvArray.Count > 0) and (LvArray.Items[0] is TJSONObject) then
    begin
      LvChildClassName := AOwnerClass + DelphiPropertyName(APropertyName) + 'Item';
      BuildClassFromJsonExample(LvChildClassName, LvArray.Items[0] as TJSONObject, ADefinitions, AImplementations, AKnownClasses);
      Exit('TArray<' + LvChildClassName + '>');
    end;

    if LvArray.Count > 0 then
      Exit('TArray<' + JsonPrimitiveType(LvArray.Items[0]) + '>');

    Exit('TArray<string>');
  end;

  Result := JsonPrimitiveType(AJsonValue);
end;

procedure AppendClassCode(const AClassName: string; AFields, AProperties, AOwnedObjects: TStrings; ADefinitions, AImplementations: TStringBuilder);
var
  I: Integer;
  LvName: string;
  LvType: string;
  LvSeparatorPos: Integer;
begin
  ADefinitions.AppendLine('  ' + AClassName + ' = class');
  ADefinitions.AppendLine('  private');
  for I := 0 to Pred(AFields.Count) do
    ADefinitions.AppendLine('    ' + AFields[I]);
  ADefinitions.AppendLine('  public');
  ADefinitions.AppendLine('    constructor Create;');
  ADefinitions.AppendLine('    destructor Destroy; override;');
  for I := 0 to Pred(AProperties.Count) do
    ADefinitions.AppendLine('    ' + AProperties[I]);
  ADefinitions.AppendLine('  end;');
  ADefinitions.AppendLine;

  AImplementations.AppendLine('constructor ' + AClassName + '.Create;');
  AImplementations.AppendLine('begin');
  AImplementations.AppendLine('  inherited Create;');
  for I := 0 to Pred(AOwnedObjects.Count) do
  begin
    LvSeparatorPos := Pos('=', AOwnedObjects[I]);
    LvName := Copy(AOwnedObjects[I], 1, LvSeparatorPos - 1);
    LvType := Copy(AOwnedObjects[I], LvSeparatorPos + 1, MaxInt);
    AImplementations.AppendLine('  F' + LvName + ' := ' + LvType + '.Create;');
  end;
  AImplementations.AppendLine('end;');
  AImplementations.AppendLine;

  AImplementations.AppendLine('destructor ' + AClassName + '.Destroy;');
  AImplementations.AppendLine('begin');
  for I := 0 to Pred(AOwnedObjects.Count) do
  begin
    LvSeparatorPos := Pos('=', AOwnedObjects[I]);
    LvName := Copy(AOwnedObjects[I], 1, LvSeparatorPos - 1);
    AImplementations.AppendLine('  F' + LvName + '.Free;');
  end;
  AImplementations.AppendLine('  inherited;');
  AImplementations.AppendLine('end;');
  AImplementations.AppendLine;
end;

procedure BuildClassFromJsonSchema(const AClassName: string; ASchemaObject: TJSONObject; ADefinitions, AImplementations: TStringBuilder; AKnownClasses: TDictionary<string, Boolean>);
var
  I: Integer;
  LvEffectiveSchema: TJSONObject;
  LvSchema: TJSONObject;
  LvProperties: TJSONObject;
  LvProperty: TJSONPair;
  LvPropName: string;
  LvPropType: string;
  LvFields: TStringList;
  LvPropertiesList: TStringList;
  LvOwnedObjects: TStringList;
begin
  if not Assigned(ASchemaObject) or AKnownClasses.ContainsKey(AClassName) then
    Exit;

  AKnownClasses.Add(AClassName, True);
  LvEffectiveSchema := BuildEffectiveSchema(ASchemaObject);
  LvFields := TStringList.Create;
  LvPropertiesList := TStringList.Create;
  LvOwnedObjects := TStringList.Create;
  try
    if Assigned(LvEffectiveSchema) then
      LvSchema := LvEffectiveSchema
    else
      LvSchema := ASchemaObject;

    if Assigned(LvSchema.FindValue('type')) and LvSchema.GetValue('type').Value.ToLower.Equals('array') then
    begin
      LvPropType := SchemaFieldType(AClassName, 'Items', LvSchema, ADefinitions, AImplementations, AKnownClasses, LvOwnedObjects);
      LvFields.Add('FItems: ' + LvPropType + ';');
      LvPropertiesList.Add('property Items: ' + LvPropType + ' read FItems write FItems;');
      AppendClassCode(AClassName, LvFields, LvPropertiesList, LvOwnedObjects, ADefinitions, AImplementations);
      Exit;
    end;

    if LvSchema.FindValue('properties') is TJSONObject then
      LvProperties := LvSchema.FindValue('properties') as TJSONObject
    else
      LvProperties := LvSchema;

    for I := 0 to Pred(LvProperties.Count) do
    begin
      LvProperty := LvProperties.Pairs[I];
      if IndexStr(LvProperty.JsonString.Value.ToLower, ['type', 'required', 'additionalproperties', 'description', 'example', 'examples', 'xml']) > -1 then
        Continue;

      LvPropName := DelphiPropertyName(LvProperty.JsonString.Value);
      LvPropType := SchemaFieldType(AClassName, LvProperty.JsonString.Value, LvProperty.JsonValue, ADefinitions, AImplementations, AKnownClasses, LvOwnedObjects);
      LvFields.Add('F' + LvPropName + ': ' + LvPropType + ';');
      LvPropertiesList.Add('property ' + DelphiEscapedIdentifier(LvPropName) + ': ' + LvPropType + ' read F' + LvPropName + ' write F' + LvPropName + ';');
    end;

    AppendClassCode(AClassName, LvFields, LvPropertiesList, LvOwnedObjects, ADefinitions, AImplementations);
  finally
    LvEffectiveSchema.Free;
    LvFields.Free;
    LvPropertiesList.Free;
    LvOwnedObjects.Free;
  end;
end;

procedure BuildClassFromJsonExample(const AClassName: string; AJsonObject: TJSONObject; ADefinitions, AImplementations: TStringBuilder; AKnownClasses: TDictionary<string, Boolean>);
var
  I: Integer;
  LvProperty: TJSONPair;
  LvPropName: string;
  LvPropType: string;
  LvFields: TStringList;
  LvPropertiesList: TStringList;
  LvOwnedObjects: TStringList;
begin
  if not Assigned(AJsonObject) or AKnownClasses.ContainsKey(AClassName) then
    Exit;

  AKnownClasses.Add(AClassName, True);
  LvFields := TStringList.Create;
  LvPropertiesList := TStringList.Create;
  LvOwnedObjects := TStringList.Create;
  try
    for I := 0 to Pred(AJsonObject.Count) do
    begin
      LvProperty := AJsonObject.Pairs[I];
      LvPropName := DelphiPropertyName(LvProperty.JsonString.Value);
      LvPropType := ExampleFieldType(AClassName, LvProperty.JsonString.Value, LvProperty.JsonValue, ADefinitions, AImplementations, AKnownClasses, LvOwnedObjects);
      LvFields.Add('F' + LvPropName + ': ' + LvPropType + ';');
      LvPropertiesList.Add('property ' + DelphiEscapedIdentifier(LvPropName) + ': ' + LvPropType + ' read F' + LvPropName + ' write F' + LvPropName + ';');
    end;

    AppendClassCode(AClassName, LvFields, LvPropertiesList, LvOwnedObjects, ADefinitions, AImplementations);
  finally
    LvFields.Free;
    LvPropertiesList.Free;
    LvOwnedObjects.Free;
  end;
end;

procedure TNewModelUnitEx.GenerateRequestClasses(AMethodObj: TMethodObject; ADefinitions, AImplementations: TStringBuilder; AKnownClasses: TDictionary<string, Boolean>);
var
  LvJsonValue: TJSONValue;
  LvSchemaObject: TJSONObject;
  LvPropertiesObject: TJSONObject;
  LvProperty: TPair<string, string>;
  LvPropertySchema: TJSONObject;
  LvClassName: string;
begin
  if not HasRequestBody(AMethodObj) then
    Exit;

  LvClassName := RequestClassName(AMethodObj);
  LvJsonValue := nil;
  try
    if not AMethodObj.RequestBody.SchemaJson.Trim.IsEmpty then
      LvJsonValue := TJSONObject.ParseJSONValue(AMethodObj.RequestBody.SchemaJson)
    else if not AMethodObj.RequestBody.Example.Trim.IsEmpty then
      LvJsonValue := TJSONObject.ParseJSONValue(AMethodObj.RequestBody.Example);

    if LvJsonValue is TJSONObject then
    begin
      if Assigned((LvJsonValue as TJSONObject).FindValue('properties')) or Assigned((LvJsonValue as TJSONObject).FindValue('type')) then
        BuildClassFromJsonSchema(LvClassName, LvJsonValue as TJSONObject, ADefinitions, AImplementations, AKnownClasses)
      else
        BuildClassFromJsonExample(LvClassName, LvJsonValue as TJSONObject, ADefinitions, AImplementations, AKnownClasses);
    end
    else if AMethodObj.RequestBody.Properties.Count > 0 then
    begin
      LvSchemaObject := TJSONObject.Create;
      try
        LvSchemaObject.AddPair('type', 'object');
        LvPropertiesObject := TJSONObject.Create;
        LvSchemaObject.AddPair('properties', LvPropertiesObject);
        for LvProperty in AMethodObj.RequestBody.Properties do
        begin
          LvPropertySchema := TJSONObject.Create;
          LvPropertySchema.AddPair('type', LvProperty.Value);
          LvPropertiesObject.AddPair(LvProperty.Key, LvPropertySchema);
        end;

        BuildClassFromJsonSchema(LvClassName, LvSchemaObject, ADefinitions, AImplementations, AKnownClasses);
      finally
        LvSchemaObject.Free;
      end;
    end;
  finally
    LvJsonValue.Free;
  end;
end;

function TNewModelUnitEx.PrepareMainSourceString(ARawSource: string; AUnitName: string): string;
var
  LvParam: TParameter;
  LvMethod: TMethodObject;
  LvOpenAPIPathObject: TOpenAPIPath;

  LvKey: string;
  LvTempStr: string;
  LvBtnName: string;
  LvBtnCallLines: string;
  LvParameterDataType: string;
  LvBtnDefinitionLines: string;
  LvButtonsCreationLines: string;
  LvParamSampleaValueFinalList: string;
  LvRequestVarLines: string;
  LvRequestCreateLines: string;
  LvRequestFreeLines: string;
  LvRequestClassName: string;
begin
  Result := sMainUnit;
  LvBtnName := EmptyStr;
  LvBtnCallLines := EmptyStr;
  LvParameterDataType := EmptyStr;
  LvBtnDefinitionLines := EmptyStr;
  LvButtonsCreationLines := EmptyStr;
  LvParamSampleaValueFinalList := EmptyStr;
  LvRequestVarLines := EmptyStr;
  LvRequestCreateLines := EmptyStr;
  LvRequestFreeLines := EmptyStr;
  LvRequestClassName := EmptyStr;

  for LvKey in FOpenAPIPaths.Keys do
  begin
    LvOpenAPIPathObject := FOpenAPIPaths.Items[LvKey];

    if Assigned(LvOpenAPIPathObject) then
    begin
      if Assigned(LvOpenAPIPathObject.Methods) then
      begin
        if LvOpenAPIPathObject.Methods.Count = 0 then
          raise Exception.Create('Error in preparing maint unit, OpenAPIPathObject.Method.Count = 0');

        for LvMethod in LvOpenAPIPathObject.Methods do
        begin
          LvBtnName := LvMethod._MethodName;
          LvParamSampleaValueFinalList := EmptyStr;
          LvRequestVarLines := EmptyStr;
          LvRequestCreateLines := EmptyStr;
          LvRequestFreeLines := EmptyStr;

          if Assigned(LvMethod.Params) then
          begin
            for LvParam in LvMethod.Params do
            begin
              LvParameterDataType := LvParam.DataType.Trim.ToLower;
              LvParamSampleaValueFinalList := IfThen(LvParamSampleaValueFinalList.IsEmpty, EmptyStr, LvParamSampleaValueFinalList + ',');

              if (LvParameterDataType.Equals('string') or LvParameterDataType.Equals('variant')) then
                LvParamSampleaValueFinalList := LvParamSampleaValueFinalList + IfThen(LvParamSampleaValueFinalList.IsEmpty, EmptyStr, ' ') + QuotedStr('')
              else if LvParameterDataType.Equals('integer') then
                LvParamSampleaValueFinalList := LvParamSampleaValueFinalList + IfThen(LvParamSampleaValueFinalList.IsEmpty, EmptyStr, ' ') + '0'
              else if LvParameterDataType.Equals('boolean') then
                LvParamSampleaValueFinalList := LvParamSampleaValueFinalList + IfThen(LvParamSampleaValueFinalList.IsEmpty, EmptyStr, ' ') + 'False'
              else if (LvParameterDataType.Equals('number')) or (LvParameterDataType.Equals('float')) then
                LvParamSampleaValueFinalList := LvParamSampleaValueFinalList + IfThen(LvParamSampleaValueFinalList.IsEmpty, EmptyStr, ' ') + '0'
              else if LvParameterDataType.Equals('array') then
                LvParamSampleaValueFinalList := LvParamSampleaValueFinalList + IfThen(LvParamSampleaValueFinalList.IsEmpty, EmptyStr, ' ') + '[]'
              else if LvParameterDataType.Equals('object') then
                LvParamSampleaValueFinalList := LvParamSampleaValueFinalList + IfThen(LvParamSampleaValueFinalList.IsEmpty, EmptyStr, ' ') + 'nil';


              if RightStr(LvParamSampleaValueFinalList, 1).Equals(',') then
                LvParamSampleaValueFinalList := LeftStr(LvParamSampleaValueFinalList, Pred(Length(LvParamSampleaValueFinalList)));
            end;
          end;

          if HasRequestBody(LvMethod) then
          begin
            LvRequestClassName := RequestClassName(LvMethod);
            if LvParamSampleaValueFinalList.IsEmpty then
              LvParamSampleaValueFinalList := 'LvRequestObj'
            else
              LvParamSampleaValueFinalList := LvParamSampleaValueFinalList + ', LvRequestObj';

            LvRequestVarLines := '  LvRequestObj: ' + LvRequestClassName + ';' + sLineBreak;
            LvRequestCreateLines := '  LvRequestObj := ' + BuildRequestClassSample(LvRequestClassName) + ';' + sLineBreak;
            LvRequestFreeLines := '    LvRequestObj.Free;' + sLineBreak;
          end;

          LvBtnDefinitionLines := LvBtnDefinitionLines + sLineBreak + Format('    procedure %0:sClick(Sender: TObject);', ['Btn_' + LvBtnName]);
          LvTempStr:= GetPrefix(LvMethod.MethodType) + LvBtnName + GetSuffix(LvMethod.MethodType) + '(' + LvParamSampleaValueFinalList + ')';
          LvBtnCallLines := LvBtnCallLines + sLineBreak + Format(sButtonOnClickEvent, ['Btn_' + LvBtnName, LvTempStr,
                                                                                       LvRequestVarLines, LvRequestCreateLines,
                                                                                       LvRequestFreeLines]);
          LvButtonsCreationLines := LvButtonsCreationLines + '  AddButton(' +  QuotedStr(GetPrefix(LvMethod.MethodType) + LvBtnName + GetSuffix(LvMethod.MethodType)) + ', ' + 'Btn_' + LvBtnName + 'Click);' + sLineBreak;
        end;
      end;
    end
    else
      raise Exception.Create('Error in preparing maint unit, OpenAPIPathObject is null');
  end;

  if not LvBtnCallLines.IsEmpty then
    Result := Format(ARawSource, [AUnitName, LvBtnDefinitionLines, LvBtnCallLines, LvButtonsCreationLines])
  else
    raise Exception.Create('Error in preparing maint unit, Buttons'' Call Lines are empty');
end;

function TNewModelUnitEx.PrepareSourceString(ARawSource: string): string;
var
  LvKey: string;
  LvOpenAPIPathObject: TOpenAPIPath;
  LvMethod: TMethodObject;
  LvParam: TParameter;

  LvAllGetfunctionHeaders: string;
  LvAllGetFunctionImplementation: string;
  LvAllPostfunctionHeaders: string;
  LvAllPostFunctionImplementation: string;
  LvAllPatchfunctionHeaders: string;
  LvAllPatchFunctionImplementation: string;
  LvAllPutfunctionHeaders: string;
  LvAllPutFunctionImplementation: string;
  LvAllDeletefunctionHeaders: string;
  LvAllDeleteFunctionImplementation: string;

  LvParameterDataType: string;
  LvParamFinalList: string;
  LvMethodListAddition: string;
  LvRequestClassName: string;
  LvRequestClassDefinitions: TStringBuilder;
  LvRequestClassImplementations: TStringBuilder;
  LvKnownRequestClasses: TDictionary<string, Boolean>;

  LvSetting: TSingletonSettingObj;
begin
  LvAllGetfunctionHeaders := EmptyStr;
  LvAllGetFunctionImplementation := EmptyStr;
  LvAllPostfunctionHeaders := EmptyStr;
  LvAllPostFunctionImplementation := EmptyStr;
  LvAllPutfunctionHeaders := EmptyStr;
  LvAllPutFunctionImplementation := EmptyStr;
  LvAllDeletefunctionHeaders := EmptyStr;
  LvAllDeleteFunctionImplementation := EmptyStr;
  LvParamFinalList := EmptyStr;
  LvMethodListAddition := EmptyStr;
  LvRequestClassDefinitions := TStringBuilder.Create;
  LvRequestClassImplementations := TStringBuilder.Create;
  LvKnownRequestClasses := TDictionary<string, Boolean>.Create;
  try

  for LvKey in FOpenAPIPaths.Keys do
  begin
    LvOpenAPIPathObject := FOpenAPIPaths.Items[LvKey];

    if Assigned(LvOpenAPIPathObject) then
    begin
      for LvMethod in LvOpenAPIPathObject.Methods do
      begin
        GenerateRequestClasses(LvMethod, LvRequestClassDefinitions, LvRequestClassImplementations, LvKnownRequestClasses);
        LvParamFinalList := EmptyStr;
        if Assigned(LvMethod.Params) then
        begin
          for LvParam in LvMethod.Params do
          begin
            LvParameterDataType := LvParam.DataType.Trim.ToLower;
            if IndexStr(LvParameterDataType, ['string', 'integer', 'boolean', 'variant']) > -1 then
            begin
              LvParamFinalList := IfThen(LvParamFinalList.IsEmpty, EmptyStr, LvParamFinalList + ';') + ' A' + ConvertToCamelCase(LvParam.Name) + ': ' + LvParam.DataType;
            end else if (LvParameterDataType.Equals('number')) or (LvParameterDataType.Equals('float')) then
            begin
              LvParamFinalList := IfThen(LvParamFinalList.IsEmpty, EmptyStr, LvParamFinalList +  ';') + ' A' + ConvertToCamelCase(LvParam.Name) + ': ' + 'real';
            end else if LvParameterDataType.Equals('array') then
            begin
              LvParamFinalList := IfThen(LvParamFinalList.IsEmpty, EmptyStr, LvParamFinalList +  ';') + ' A' + ConvertToCamelCase(LvParam.Name) + ': ' + 'array of string';
            end else if LvParameterDataType.Equals('object') then
            begin
              LvParamFinalList := IfThen(LvParamFinalList.IsEmpty, EmptyStr, LvParamFinalList +  ';') + ' A' + ConvertToCamelCase(LvParam.Name) + ': ' + 'TJsonObject';
            end;
          end;
        end;

        RefineParameterList(LvParamFinalList);
        if Assigned(LvMethod.RequestBody) then
        begin
          LvRequestClassName := RequestClassName(LvMethod);
          if Assigned(LvMethod.RequestBody.Properties) then
          begin
            if HasRequestBody(LvMethod) then
            begin
              if not LvParamFinalList.IsEmpty then
                LvParamFinalList := Concat('(', LvParamFinalList, '; ARequestObj: ', LvRequestClassName, ' = nil', ')')
              else
                LvParamFinalList := '(ARequestObj: ' + LvRequestClassName + ' = nil)';
            end
            else if not LvParamFinalList.IsEmpty then
              LvParamFinalList := Concat('(', LvParamFinalList, ')');
          end;

          if (not LvMethod.RequestBody.Example.IsEmpty) and (not LvParamFinalList.Contains('ARequestObj:')) then
          begin
            if not LvParamFinalList.IsEmpty then
              LvParamFinalList := Concat('(', LvParamFinalList, '; ARequestObj: ', LvRequestClassName, ' = nil', ')')
            else
              LvParamFinalList := '(ARequestObj: ' + LvRequestClassName + ' = nil)';
          end;
        end;

        RefineParameterList(LvParamFinalList);

        case LvMethod.MethodType of
          mtGet:
          begin
            LvAllGetfunctionHeaders :=
                                   LvAllGetfunctionHeaders + sLineBreak + '    ' +
                                   Format(sFunctionHeader, [GetPrefix(mtGet) + LvMethod._MethodName + GetSuffix(mtGet), LvParamFinalList]);

            LvAllGetFunctionImplementation :=
                                       LvAllGetFunctionImplementation + sLineBreak +
                                       Format(sFunctionImplementation, [GetPrefix(mtGet) + LvMethod._MethodName + GetSuffix(mtGet), LvParamFinalList, BuildFunctionBody(LvMethod)]);
          end;

          mtPost:
          begin
            LvAllPostfunctionHeaders :=
                                    LvAllPostfunctionHeaders + sLineBreak + '    ' +
                                    Format(sFunctionHeader, [GetPrefix(mtPost) + LvMethod._MethodName + GetSuffix(mtPost), LvParamFinalList]);


            LvAllPostFunctionImplementation :=
                                       LvAllPostFunctionImplementation + sLineBreak +
                                       Format(sFunctionImplementation, [GetPrefix(mtPost) + LvMethod._MethodName + GetSuffix(mtPost), LvParamFinalList, BuildFunctionBody(LvMethod)]);
          end;

          mtPatch:
          begin
            LvAllPatchfunctionHeaders :=
                                    LvAllPatchfunctionHeaders + sLineBreak + '    ' +
                                    Format(sFunctionHeader, [GetPrefix(mtPatch) + LvMethod._MethodName + GetSuffix(mtPatch), LvParamFinalList]);


            LvAllPatchFunctionImplementation :=
                                       LvAllPatchFunctionImplementation + sLineBreak +
                                       Format(sFunctionImplementation, [GetPrefix(mtPatch) + LvMethod._MethodName + GetSuffix(mtPatch), LvParamFinalList, BuildFunctionBody(LvMethod)]);
          end;

          mtPut:
          begin
            LvAllPutfunctionHeaders :=
                                   LvAllPutfunctionHeaders + sLineBreak + '    ' +
                                   Format(sFunctionHeader, [GetPrefix(mtPut) + LvMethod._MethodName + GetSuffix(mtPut), LvParamFinalList]);


            LvAllPutFunctionImplementation :=
                                       LvAllPutFunctionImplementation + sLineBreak +
                                       Format(sFunctionImplementation, [GetPrefix(mtPut) + LvMethod._MethodName + GetSuffix(mtPut), LvParamFinalList, BuildFunctionBody(LvMethod)]);
          end;

          mtDelete:
          begin
            LvAllDeletefunctionHeaders :=
                                      LvAllDeletefunctionHeaders + sLineBreak + '    ' +
                                      Format(sFunctionHeader, [GetPrefix(mtDelete) + LvMethod._MethodName + GetSuffix(mtDelete), LvParamFinalList]);


            LvAllDeleteFunctionImplementation :=
                                       LvAllDeleteFunctionImplementation + sLineBreak +
                                       Format(sFunctionImplementation, [GetPrefix(mtDelete) + LvMethod._MethodName + GetSuffix(mtDelete), LvParamFinalList, BuildFunctionBody(LvMethod)]);
          end;
        end;

        LvMethodListAddition := LvMethodListAddition +
                                '  ' + '.AddX(' + QuotedStr(LvMethod._MethodName) + ', ' +
                                QuotedStr(LvOpenAPIPathObject.PathValue) + ')' + sLineBreak;
      end;
    end;
  end;

  LvMethodListAddition := Concat(LvMethodListAddition.TrimRight, ';');

  LvSetting := TSingletonSettingObj.Instance;
  Result := Format(ARawSource, [LvSetting.BaseURL, LvSetting.UserName,
                                LvSetting.Password, LvSetting.BearerToken, ConvertAuthenticationType(LvSetting.AuthType),
                                IfThen(LvAllGetfunctionHeaders.Trim.Equals(EmptyStr), '', AddBreaklines(LvAllGetfunctionHeaders, ';') + sLineBreak),
                                IfThen(LvAllPostfunctionHeaders.Trim.Equals(EmptyStr), '', AddBreaklines(LvAllPostfunctionHeaders, ';') + sLineBreak),
                                IfThen(LvAllPatchfunctionHeaders.Trim.Equals(EmptyStr), '', AddBreaklines(LvAllPatchfunctionHeaders, ';') + sLineBreak),
                                IfThen(LvAllPutfunctionHeaders.Trim.Equals(EmptyStr), '', AddBreaklines(LvAllPutfunctionHeaders, ';') + sLineBreak),
                                IfThen(LvAllDeletefunctionHeaders.Trim.Equals(EmptyStr), '', AddBreaklines(LvAllDeletefunctionHeaders, ';') + sLineBreak),
                                IfThen(LvMethodListAddition.Trim.Equals(EmptyStr), '', AddBreaklines(LvMethodListAddition, ';') + sLineBreak),
                                IfThen(LvAllGetFunctionImplementation.Trim.Equals(EmptyStr), '', AddBreaklines(LvAllGetFunctionImplementation, '+') + sLineBreak),
                                IfThen(LvAllPostFunctionImplementation.Trim.Equals(EmptyStr), '', AddBreaklines(LvAllPostFunctionImplementation, '+') + sLineBreak),
                                IfThen(LvAllPatchFunctionImplementation.Trim.Equals(EmptyStr), '', AddBreaklines(LvAllPatchFunctionImplementation, '+') + sLineBreak),
                                IfThen(LvAllPutFunctionImplementation.Trim.Equals(EmptyStr), '', AddBreaklines(LvAllPutFunctionImplementation, '+') + sLineBreak),
                                IfThen(LvAllDeleteFunctionImplementation.Trim.Equals(EmptyStr), '', AddBreaklines(LvAllDeleteFunctionImplementation, '+') + sLineBreak),
                                LvRequestClassDefinitions.ToString,
                                LvRequestClassImplementations.ToString]);
  finally
    LvRequestClassDefinitions.Free;
    LvRequestClassImplementations.Free;
    LvKnownRequestClasses.Free;
  end;

  //0: BaseURL
  //1: UserName
  //2: Password
  //3: Token or API Key
  //4: GetMethods Definition
  //5: PostMethods Definition
  //6: patchMethods Definition
  //7: PutMethods Definition
  //8: DeleteMethod_Definition
  //9: Add Paths
  //10: GetMethod Implementations
  //11: PostMethod Implementations
  //12: PatchMethod Implementations
  //13: PutMethod Implementations
  //14 DeleteMethod Implementations

  {$IFDEF CODESITE}
    //CodeSite.Send('Result of the Source String Preparation= ' + Result);
  {$ENDIF}
end;

function TNewModelUnitEx.RefineParameterList(var AParamList: string): string;
begin
  if not AParamList.IsEmpty then
  begin
    if RightStr(AParamList, 1) = ';' then
      AParamList := LeftStr(AParamList, Length(AParamList) - 1);// Remove the last extra semi colon

    AParamList := StringReplace(AParamList, '((', '(', [rfReplaceAll]);
    AParamList := StringReplace(AParamList, '))', ')', [rfReplaceAll]);
    AParamList := StringReplace(AParamList, ';;', '; ', [rfReplaceAll]);
    AParamList := StringReplace(AParamList, '(;', '(', [rfReplaceAll]);
    AParamList := StringReplace(AParamList, '( ', '(', [rfReplaceAll]);
  end;
end;

function TNewModelUnitEx.AddBreaklines(const AText: string; ADelimitter: Char; ABreakLength: Integer): string;
var
  I: Integer;
  LvLength: Integer;
  LvBrokenText: string;
begin
  LvBrokenText := '';
  Result := AText;
  if (not AText.Contains(ADelimitter)) or (AText.Length <= ABreakLength) then
    Exit;

  I := 1; // string index starts with 1 in Delphi!
  LvLength := Length(AText);

  while I <= LvLength do
  begin
    LvBrokenText := LvBrokenText + AText[I];

    if I mod ABreakLength = 0 then
    begin
      if AText[I] = ADelimitter then
        LvBrokenText := LvBrokenText + sLineBreak + '    '
      else
      begin
        Inc(I);
        while (I <= LvLength) do
        begin
          if AText[I] <> ADelimitter then
            LvBrokenText := LvBrokenText + AText[I]
          else
            Break;

          Inc(I);
        end;
        if I <= LvLength then
          LvBrokenText := LvBrokenText + ADelimitter + sLineBreak + '    ';
      end;
    end;
    Inc(I);
  end;

  Result := LvBrokenText;
end;

end.
