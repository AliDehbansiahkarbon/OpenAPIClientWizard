{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}
unit OCW.Util.OpenAPIHelper;

interface

uses
  Vcl.Dialogs, System.Classes, System.Generics.Collections, System.JSON, System.SysUtils,
  Neslib.Yaml, System.TypInfo, System.StrUtils, OCW.Util.PostmanHelper,
  OCW.Util.Core, OCW.Util.Consts {$IFDEF CODESITE}, CodeSiteLogging{$ENDIF};

type
  TParameter = class
  private
    FName: string;
    FOriginalname: string;
    FIn: string;
    FDescription: string;
    FRequired: Boolean;
    FDataType: string;
    function CLeanDataType(ARawDataType: string): string;
    function CleanName(const AName: string): string;
  public
    constructor Create(AName, AIn, ADescription, ADataType: string; ARequired: Boolean);
    property Name: string read FName;
    property Originalname: string read FOriginalname;
    property &In: string read FIn;
    property Description: string read FDescription;
    property Required: Boolean read FRequired;
    property DataType: string read FDataType;
  end;

  TRequestBody = class
  private
    FDescription: string;
    FContentType: string;
    FExample: string;
    FSchemaJson: string;
    FRequired: Boolean;
    FProperties: TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;
    property Description: string read FDescription write FDescription;
    property ContentType: string read FContentType write FContentType;
    property Example: string read FExample write FExample;
    property SchemaJson: string read FSchemaJson write FSchemaJson;
    property Required: Boolean read FRequired write FRequired;
    property Properties: TDictionary<string, string> read FProperties write FProperties;
  end;

  TMethodType = (mtGet, mtPost, mtPut, mtDelete, mtPatch, mtHead, mtOptions, mtTrace, mtConnect, mtUnknown);

  TMethodObject = class(TObject)
  private
    FJsonParams: TJSONObject;
    FMethodName: string;
    FMethodType: TMethodType;
    FMethodSummary: string;
    FMethodDescription: string;
    FParams: TObjectList<TParameter>;
    FRequestBody: TRequestBody;
    class function FindMethodName(AJsonMethod: TJSONPair): string;
    class function BuildFallbackMethodName(const AMethodType, APath: string): string;
    class function RemoveDelphiReservedChars(AValue: string): string;
    class function SchemaDataType(AJsonValue: TJSONValue): string;
    function GetEnumValueByName(const AName: string): TMethodType;
    function GetMethodName: string;
    procedure LoadJsonParameters(AJsonParamArray: TJSONArray);
    procedure LoadYamlParameters(AYamlParamList: TYamlNode);
  public
    constructor CreateJson(AJsonMethod: TJSONPair);
    constructor CreateYaml(AMethodtype: string; AYamlNode: TYamlNode);
    constructor CreatePostman(APostmanItem: TPostmanItem);
    destructor Destroy; override;

    property Params: TObjectList<TParameter> read FParams write FParams;
    property _MethodName: string read GetMethodName;
    property MethodType: TMethodType read FMethodType;
    property RequestBody: TRequestBody read FRequestBody write FRequestBody;
  end;

  TOpenAPIPath = class
  private
    FJsonPath: TJSONPair;
    FPathValue: string;
    FMethods: TObjectList<TMethodObject>;
  public
    constructor CreateJson(AJsonPath: TJSONPair);
    constructor CreateYaml(APath: string; AYamlNode: TYamlNode);
    constructor CreatePostman(APostmanItem: TPostmanItem);
    destructor Destroy; override;

    property Methods: TObjectList<TMethodObject> read FMethods;
    property PathValue: string read FPathValue;
  end;

  TParamListHelper = class helper for TObjectList<TParameter>
    procedure AddEx(AParameter: TParameter);
  end;

implementation

{ TMethodObject }

function YamlScalarToJsonValue(AYamlNode: TYamlNode): TJSONValue;
var
  LvText: string;
begin
  LvText := AYamlNode.ToString;
  Result := TJSONString.Create(LvText);
end;

function YamlNodeToJsonValue(AYamlNode: TYamlNode): TJSONValue;
var
  I: Integer;
  LvObject: TJSONObject;
  LvArray: TJSONArray;
begin
  if AYamlNode.IsNil then
    Exit(TJSONString.Create(EmptyStr));

  if AYamlNode.IsScalar then
    Exit(YamlScalarToJsonValue(AYamlNode));

  if AYamlNode.IsSequence then
  begin
    LvArray := TJSONArray.Create;
    for I := 0 to Pred(AYamlNode.Count) do
      LvArray.AddElement(YamlNodeToJsonValue(AYamlNode.Nodes[I]));

    Exit(LvArray);
  end;

  LvObject := TJSONObject.Create;
  for I := 0 to Pred(AYamlNode.Count) do
    LvObject.AddPair(AYamlNode.Elements[I].Key.ToString, YamlNodeToJsonValue(AYamlNode.Elements[I].Value));

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
    if AYamlNode.Elements[I].Key.ToString.ToLower.Equals(AKey.ToLower) then
    begin
      AValue := AYamlNode.Elements[I].Value;
      Exit(True);
    end;
  end;
end;

constructor TMethodObject.CreateJson(AJsonMethod: TJSONPair);
var
  LvParam: TJSONPair;
  LvParamArray: TJSONArray;
  LvRequestBody, LvContent: TJSONObject;
  LvProperties: TJSONObject;
  LvApplicationNode: TJSONObject;
  LvSchema: TJSONObject;
  LvProperty: TJSONPair;

  I, J: Integer;
begin
  FRequestBody := TRequestBody.Create;
  FParams := TObjectList<TParameter>.Create;
  FMethodName := FindMethodName(AJsonMethod);
  FMethodType := GetEnumValueByName(AJsonMethod.JsonString.Value);

  if AJsonMethod.JsonValue.TryGetValue<TJSONObject>(FJsonParams) then
  begin
    for I := 0 to Pred(FJsonParams.Count) do
    begin
      LvParam := FJsonParams.Pairs[I];
      if LvParam.JsonString.Value.ToLower.Equals(cJson_RequestBody) then
      begin
        if LvParam.JsonValue.TryGetValue<TJSONObject>(LvRequestBody) then
        begin
          if Assigned(LvRequestBody.FindValue(cJson_Description)) then
            FRequestBody.Description := LvRequestBody.GetValue(cJson_Description).Value;

          if Assigned(LvRequestBody.FindValue(cJson_Required)) then
            FRequestBody.Required := LvRequestBody.GetValue(cJson_Required).AsType<Boolean>;

          if Assigned(LvRequestBody.FindValue(cJson_Content)) then
          begin
            LvContent := LvRequestBody.GetValue(cJson_Content) as TJSONObject;

            if Assigned(LvContent.FindValue(cJson_ApplicationJson)) then
            begin
              if LvContent.GetValue(cJson_ApplicationJson) is TJSONObject then
              begin
                LvApplicationNode := LvContent.GetValue(cJson_ApplicationJson) as TJSONObject;
                FRequestBody.ContentType := cJson_ApplicationJson;

                if Assigned(LvApplicationNode.FindValue(cJson_Schema)) then
                begin
                  if LvApplicationNode.FindValue(cJson_Schema) is TJSONObject then
                    FRequestBody.SchemaJson := (LvApplicationNode.FindValue(cJson_Schema) as TJSONObject).ToJSON;

                  if Assigned(LvApplicationNode.FindValue(cJson_Schema).FindValue(cJson_Example)) then
                    FRequestBody.Example := LvApplicationNode.FindValue(cJson_Schema).FindValue(cJson_Example).Value;
                end;

                if Assigned(LvApplicationNode.FindValue(cJson_Schema)) and
                   Assigned(LvApplicationNode.FindValue(cJson_Schema).FindValue(cJson_Properties)) then
                begin
                  if LvApplicationNode.FindValue(cJson_Schema).FindValue(cJson_Properties) is TJSONObject then
                  begin
                    LvProperties := LvApplicationNode.FindValue(cJson_Schema).FindValue(cJson_Properties) as TJSONObject;
                    if Assigned(LvProperties) then
                    begin
                      for j := 0 to LvProperties.Count - 1 do
                      begin
                          LvProperty := LvProperties.Pairs[J];
                          if Assigned(LvProperty) then
                            FRequestBody.Properties.Add(LvProperty.JsonString.Value{prop name}, SchemaDataType(LvProperty.JsonValue){prop type});
                      end;
                    end;
                  end;
                end;
              end;
            end;

            if Assigned(LvContent.FindValue(cJson_ApplicationFormUrlencoded)) then
            begin
              if LvContent.FindValue(cJson_ApplicationFormUrlencoded) is TJSONObject then
              begin
                LvApplicationNode := LvContent.FindValue(cJson_ApplicationFormUrlencoded) as TJSONObject;
                FRequestBody.ContentType := cJson_ApplicationFormUrlencoded;
                LvSchema := nil;
                if Assigned(LvApplicationNode.FindValue(cJson_Schema)) then
                begin
                  LvSchema := LvApplicationNode.GetValue(cJson_Schema) as TJSONObject;
                  FRequestBody.SchemaJson := LvSchema.ToJSON;
                  if Assigned(LvSchema.FindValue(cJson_Example)) then
                    FRequestBody.Example := LvSchema.FindValue(cJson_Example).Value;
                end;

                if Assigned(LvSchema) and Assigned(LvSchema.FindValue(cJson_Properties)) then
                begin
                  LvProperties := LvSchema.FindValue(cJson_Properties) as TJSONObject;
                  for j := 0 to Pred(LvProperties.Count) do
                  begin
                    LvProperty := LvProperties.Pairs[J];
                    if Assigned(LvProperty) then
                      FRequestBody.Properties.Add(LvProperty.JsonString.Value{prop name}, SchemaDataType(LvProperty.JsonValue){prop type});
                  end;
                end;
              end;
            end;

            if Assigned(LvContent.FindValue(cJson_MultipartFormData)) then
            begin
              if LvContent.FindValue(cJson_MultipartFormData) is TJSONObject then
              begin
                LvApplicationNode := LvContent.FindValue(cJson_MultipartFormData) as TJSONObject;
                FRequestBody.ContentType := cJson_MultipartFormData;
                LvSchema := nil;
                if Assigned(LvApplicationNode.FindValue(cJson_Schema)) then
                begin
                  LvSchema := LvApplicationNode.GetValue(cJson_Schema) as TJSONObject;
                  FRequestBody.SchemaJson := LvSchema.ToJSON;
                  if Assigned(LvSchema.FindValue(cJson_Example)) then
                    FRequestBody.Example := LvSchema.FindValue(cJson_Example).Value;
                end;

                if Assigned(LvSchema) and Assigned(LvSchema.FindValue(cJson_Properties)) then
                begin
                  LvProperties := LvSchema.FindValue(cJson_Properties) as TJSONObject;
                  for j := 0 to Pred(LvProperties.Count) do
                  begin
                    LvProperty := LvProperties.Pairs[J];
                    if Assigned(LvProperty) then
                      FRequestBody.Properties.Add(LvProperty.JsonString.Value{prop name}, SchemaDataType(LvProperty.JsonValue){prop type});
                  end;
                end;
              end;
            end;
          end;
        end;
      end;

      if LvParam.JsonString.Value.ToLower.Equals(cJson_Parameters) then
      begin
        if Assigned(LvParam.JsonValue) then
        begin
          if LvParam.JsonValue.TryGetValue<TJSONArray>(LvParamArray) then
            LoadJsonParameters(LvParamArray);
        end;
      end;
    end;
  end;
end;

constructor TMethodObject.CreateYaml(AMethodtype: string; AYamlNode: TYamlNode);
var
  I, J, K: Integer;

  LvYamlParamList: TYamlNode;
  LvYamlRequestBody: TYamlNode;
  LvYamlContent: TYamlNode;
  LvYamlMediaNode: TYamlNode;
  LvYamlSchema: TYamlNode;
  LvYamlProperties: TYamlNode;
  LvSchemaJsonValue: TJSONValue;
  LvContentType: string;
  L: Integer;
begin
  FRequestBody := TRequestBody.Create;
  FParams := TObjectList<TParameter>.Create;
  FMethodType := GetEnumValueByName(AMethodtype);

  for I := 0 to Pred(AYamlNode.Count) do
  begin
    if AYamlNode.Elements[I].Key.ToString.ToLower.Equals(cJson_RequestBody) then //mapping
    begin
      LvYamlRequestBody := AYamlNode.Elements[I].Value;
      for J := 0 to Pred(LvYamlRequestBody.Count) do
      begin
        if LvYamlRequestBody.Elements[J].Key.ToString.ToLower.Equals(cJson_Description) then
          FRequestBody.Description := LvYamlRequestBody.Elements[J].Value.ToString;

        if LvYamlRequestBody.Elements[J].Key.ToString.ToLower.Equals(cJson_Required) then
          FRequestBody.Required := LvYamlRequestBody.Elements[J].Value.ToBoolean;

        if LvYamlRequestBody.Elements[J].Key.ToString.ToLower.Equals(cJson_Content) then
        begin
          LvYamlContent := LvYamlRequestBody.Elements[J].Value;
          LvContentType := EmptyStr;

          if FindYamlChildByKey(LvYamlContent, cJson_ApplicationJson, LvYamlMediaNode) then
            LvContentType := cJson_ApplicationJson
          else if FindYamlChildByKey(LvYamlContent, cJson_ApplicationFormUrlencoded, LvYamlMediaNode) then
            LvContentType := cJson_ApplicationFormUrlencoded
          else if FindYamlChildByKey(LvYamlContent, cJson_MultipartFormData, LvYamlMediaNode) then
            LvContentType := cJson_MultipartFormData;

          if (not LvContentType.IsEmpty) and FindYamlChildByKey(LvYamlMediaNode, cJson_Schema, LvYamlSchema) then
          begin
            FRequestBody.ContentType := LvContentType;
            LvSchemaJsonValue := YamlNodeToJsonValue(LvYamlSchema);
            try
              FRequestBody.SchemaJson := LvSchemaJsonValue.ToJSON;
            finally
              LvSchemaJsonValue.Free;
            end;

            for K := 0 to Pred(LvYamlSchema.Count) do
            begin
              if LvYamlSchema.Elements[K].Key.ToString.ToLower.Equals(cJson_Example) then
                FRequestBody.Example :=  LvYamlSchema.Elements[K].Value.ToString;

              if LvYamlSchema.Elements[K].Key.ToString.ToLower.Equals(cJson_Properties) then
              begin
                LvYamlProperties := LvYamlSchema.Elements[K].Value;

                for L := 0 to Pred(LvYamlProperties.Count) do
                begin
                  FRequestBody.Properties.Add(LvYamlProperties.Elements[L].Key.ToString{prop name},
                                             LvYamlProperties.Elements[L].Value.Elements[0].Value.ToString{prop type});

//                    LvYamlProperties.Elements[M].Value.Elements[1].Value.ToString // description (for future use)
                end;
              end;
            end;
          end;
        end;
      end;
    end;

    if AYamlNode.Elements[I].Key.ToString.ToLower.Equals(cJson_summary) then  //scalar
      FMethodSummary := AYamlNode.Elements[I].Value.ToString;

    if AYamlNode.Elements[I].Key.ToString.ToLower.Equals(cJson_Description) then //scalar
      FMethodDescription := AYamlNode.Elements[I].Value.ToString;

    if AYamlNode.Elements[I].Key.ToString.ToLower.Equals(cJson_Operationid) then //scalar
      FMethodName := AYamlNode.Elements[I].Value.ToString;

    if AYamlNode.Elements[I].Key.ToString.ToLower.Equals(cJson_Parameters) then //sequesnce
    begin
      LvYamlParamList := AYamlNode.Elements[I].Value;
      LoadYamlParameters(LvYamlParamList);
    end;
  end;
end;

procedure TMethodObject.LoadJsonParameters(AJsonParamArray: TJSONArray);
var
  I: Integer;
  LvParameterObj: TJSONObject;
  LvSchemaObj: TJSONObject;
  LvProperties: TJSONObject;
  LvProperty: TJSONPair;
  J: Integer;
  LvName: string;
  LvIn: string;
  LvDescription: string;
  LvType: string;
  LvRequired: Boolean;
  LvParameter: TParameter;
begin
  if not Assigned(AJsonParamArray) then
    Exit;

  for I := 0 to Pred(AJsonParamArray.Count) do
  begin
    if not (AJsonParamArray.Items[I] is TJSONObject) then
      Continue;

    LvParameterObj := AJsonParamArray.Items[I] as TJSONObject;
    LvName := EmptyStr;
    LvIn := EmptyStr;
    LvDescription := EmptyStr;
    LvType := EmptyStr;
    LvRequired := False;

    try
      if Assigned(LvParameterObj.FindValue(cJson_name)) then
        LvName := LvParameterObj.GetValue(cJson_name).Value;

      if Assigned(LvParameterObj.FindValue(cJson_In)) then
        LvIn := LvParameterObj.GetValue(cJson_In).Value;

      if Assigned(LvParameterObj.FindValue(cJson_Description)) then
        LvDescription := LvParameterObj.GetValue(cJson_Description).Value;

      if Assigned(LvParameterObj.FindValue(cJson_Schema)) then
        LvType := SchemaDataType(LvParameterObj.GetValue(cJson_Schema))
      else if Assigned(LvParameterObj.FindValue(cJson_type)) then
        LvType := LvParameterObj.GetValue(cJson_type).Value;

      if Assigned(LvParameterObj.FindValue(cJson_Required)) then
        LvRequired := LvParameterObj.GetValue(cJson_Required).AsType<Boolean>;

      if LvIn.Trim.ToLower.Equals('body') then
      begin
        FRequestBody.Description := LvDescription;
        FRequestBody.Required := LvRequired;
        FRequestBody.ContentType := cJson_ApplicationJson;

        if LvParameterObj.FindValue(cJson_Schema) is TJSONObject then
        begin
          LvSchemaObj := LvParameterObj.FindValue(cJson_Schema) as TJSONObject;
          FRequestBody.SchemaJson := LvSchemaObj.ToJSON;

          if Assigned(LvSchemaObj.FindValue(cJson_Example)) then
            FRequestBody.Example := LvSchemaObj.FindValue(cJson_Example).ToJSON;

          if LvSchemaObj.FindValue(cJson_Properties) is TJSONObject then
          begin
            LvProperties := LvSchemaObj.FindValue(cJson_Properties) as TJSONObject;
            for J := 0 to Pred(LvProperties.Count) do
            begin
              LvProperty := LvProperties.Pairs[J];
              if Assigned(LvProperty) and not FRequestBody.Properties.ContainsKey(LvProperty.JsonString.Value) then
                FRequestBody.Properties.Add(LvProperty.JsonString.Value, SchemaDataType(LvProperty.JsonValue));
            end;
          end;
        end;
        Continue;
      end;

      LvParameter := TParameter.Create(LvName, LvIn, LvDescription, LvType, LvRequired);
    except on E: Exception do
      begin
        LvParameter := nil;
        MarkObjectUsed(LvParameter);
        {$IFDEF CODESITE}
        CodeSite.Send('Parameter Creation Error: ' + E.Message);
        {$ELSE}
          raise Exception.Create('Parameter Creation Error: ' + E.Message);
        {$ENDIF}
      end;
    end;

    if Assigned(LvParameter) then
      FParams.AddEx(LvParameter);
  end;
end;

procedure TMethodObject.LoadYamlParameters(AYamlParamList: TYamlNode);
var
  I, J: Integer;
  LvName: string;
  LvIn: string;
  LvDescription: string;
  LvType: string;
  LvRequired: Boolean;
  LvParameter: TParameter;
begin
  for I := 0 to Pred(AYamlParamList.Count) do
  begin
    LvName := EmptyStr;
    LvIn := EmptyStr;
    LvDescription := EmptyStr;
    LvType := EmptyStr;
    LvRequired := False;

    for J := 0 to Pred(AYamlParamList.Nodes[I].Count) do
    begin
       case IndexStr(AYamlParamList.Nodes[I].Elements[J].Key.ToString.ToLower, [cJson_name, cJson_In, cJson_Description, cJson_Schema, cJson_type, cJson_Required]) of
         0: LvName := AYamlParamList.Nodes[I].Elements[J].Value.ToString;
         1: LvIn := AYamlParamList.Nodes[I].Elements[J].Value.ToString;
         2: LvDescription := AYamlParamList.Nodes[I].Elements[J].Value.ToString;
         3:
         begin
           if AYamlParamList.Nodes[I].Elements[J].Value.Count > 0 then
             LvType := AYamlParamList.Nodes[I].Elements[J].Value.Elements[0].Value.ToString;
         end;
         4: LvType := AYamlParamList.Nodes[I].Elements[J].Value.ToString;
         5: LvRequired := AYamlParamList.Nodes[I].Elements[J].Value.ToBoolean;
       end;
    end;

    LvParameter := TParameter.Create(LvName, LvIn, LvDescription, LvType, LvRequired);
    FParams.AddEx(LvParameter);
  end;
end;

constructor TMethodObject.CreatePostman(APostmanItem: TPostmanItem);
var
  I: Integer;
  LvIn: string;
  LvName: string;
  LvDescription: string;
  LvType: string;
  LvParameter: TParameter;
  LvRequired: Boolean;
  LvQueryParams: TJSONArray;
  LvInPathParams: TJSONArray;
begin
  LvQueryParams := nil;
  LvInPathParams := nil;
  FMethodName := APostmanItem.Name;
  FRequestBody := TRequestBody.Create;
  FParams := TObjectList<TParameter>.Create;

  MarkJsonUsed(LvQueryParams);
  MarkJsonUsed(LvInPathParams);

  if Assigned(APostmanItem.Request) then
  begin
    FMethodType := GetEnumValueByName(APostmanItem.Request.Method);

    if Assigned(APostmanItem.Request.Url) then
    begin
      if Assigned(APostmanItem.Request.Url.Query) then  // Query Params
      begin
        LvQueryParams := APostmanItem.Request.Url.Query as TJSONArray;

        if Assigned(LvQueryParams) then
        begin
          for I := 0 to Pred(LvQueryParams.Count) do
          begin
            LvIn := cPostman_Query;
            LvName := EmptyStr;
            LvDescription := EmptyStr;
            LvType := 'string';

            if Assigned(LvQueryParams.Items[I].FindValue(cPostman_Key)) then
              LvName := LvQueryParams.Items[I].FindValue(cPostman_Key).Value; //param name

            if Assigned(LvQueryParams.Items[I].FindValue(cPostman_Description)) then
              LvDescription := LvQueryParams.Items[I].FindValue(cPostman_Description).Value; //param description

            LvRequired := False; //TODO
            LvParameter := TParameter.Create(LvName, LvIn, LvDescription, LvType, LvRequired);
            FParams.AddEx(LvParameter);
          end;
        end;
      end;

      if Assigned(APostmanItem.Request.Url.Variable) then // In path Variables
      begin
        LvInPathParams := APostmanItem.Request.Url.Variable as TJSONArray;

        if Assigned(LvInPathParams) then
        begin
          for I := 0 to Pred(LvInPathParams.Count) do
          begin
            LvIn := 'path';
            LvName := EmptyStr;
            LvDescription := EmptyStr;
            LvType := 'string';

            if Assigned(LvInPathParams.Items[I].FindValue(cPostman_Key)) then
              LvName := LvInPathParams.Items[I].FindValue(cPostman_Key).Value; //param name

            if Assigned(LvInPathParams.Items[I].FindValue(cPostman_Description)) then
              LvDescription := LvInPathParams.Items[I].FindValue(cPostman_Description).Value; //param description

            LvRequired := False; //TODO

            LvParameter := TParameter.Create(LvName, LvIn, LvDescription, LvType, LvRequired);
            FParams.AddEx(LvParameter);
          end;
        end;
      end;
    end;
    FRequestBody.FExample := APostmanItem.Request.Body.Raw;
  end;
end;

class function TMethodObject.FindMethodName(AJsonMethod: TJSONPair): string;
var
  LvJsonParams: TJSONObject;
  LvJsonParam: TJSONPair;
  I: Integer;
begin
  Result := EmptyStr;
  if AJsonMethod.JsonValue.TryGetValue<TJSONObject>(LvJsonParams) then
  begin
    for I := 0 to LvJsonParams.Count - 1 do
    begin
      LvJsonParam := LvJsonParams.Pairs[I];
      if LvJsonParam.JsonString.Value.ToLower.Equals(cJson_Operationid) then
      begin
        Result := RemoveDelphiReservedChars(LvJsonParam.JsonValue.Value);
        Break;
      end;
    end;

    if Result.Equals(EmptyStr) then
    begin
      for I := 0 to LvJsonParams.Count - 1 do
      begin
        LvJsonParam := LvJsonParams.Pairs[I];
        if LvJsonParam.JsonString.Value.ToLower.Equals(cJson_Summary) then
        begin
          Result := RemoveDelphiReservedChars(RemoveDelphiReservedChars(LvJsonParam.JsonValue.Value));
          Break;
        end;
      end;
    end;
  end;
end;

class function TMethodObject.BuildFallbackMethodName(const AMethodType, APath: string): string;
begin
  Result := RemoveDelphiReservedChars(AMethodType + '_' + APath);
end;

function TMethodObject.GetEnumValueByName(const AName: string): TMethodType;
begin
  if AName.Trim.Equals(EmptyStr) then
    Result := TMethodType.mtUnknown
  else
  begin
    try
      Result := TMethodType(GetEnumValue(TypeInfo(TMethodType), 'mt' + AName));
    except on E: Exception do
      begin
        {$IFDEF CODESITE}CodeSite.Send('Method Type is Unknown: ' + AName);{$ENDIF}
        Result := TMethodType.mtUnknown;
      end;
    end;
  end;
end;

class function TMethodObject.RemoveDelphiReservedChars(AValue: string): string;
const
  ReservedWords: array[0..32] of string = ('and', 'array', 'as', 'begin', 'case', 'class', 'const', 'constructor',
    'destructor', 'div', 'do', 'downto', 'else', 'end', 'except', 'exports', 'file', 'finalization', 'finally',
    'for', 'function', 'if', 'implementation', 'in', 'inherited', 'initialization', 'interface', 'is', 'mod',
    'nil', 'not', 'of', 'or');
var
  I: Integer;
begin
  Result := AValue;
  for I := 1 to Length(Result) do
  begin
    if not CharInSet(Result[I], ['a'..'z', 'A'..'Z', '0'..'9', '_']) then
      Result[I] := '_';
  end;

  while Result.Contains('__') do
    Result := StringReplace(Result, '__', '_', [rfReplaceAll]);

  Result := Result.Trim(['_']);

  if Result.IsEmpty then
    Result := 'GeneratedMethod';

  if CharInSet(Result[1], ['0'..'9']) then
    Result := '_' + Result;

  for I := Low(ReservedWords) to High(ReservedWords) do
  begin
    if Result.ToLower.Equals(ReservedWords[I]) then
      Result := '_' + Result;
  end;
end;

class function TMethodObject.SchemaDataType(AJsonValue: TJSONValue): string;
var
  LvSchema: TJSONObject;
begin
  Result := EmptyStr;
  if not Assigned(AJsonValue) then
    Exit;

  if AJsonValue is TJSONObject then
  begin
    LvSchema := AJsonValue as TJSONObject;

    if Assigned(LvSchema.FindValue(cJson_type)) then
      Exit(LvSchema.GetValue(cJson_type).Value);

    if Assigned(LvSchema.FindValue(cJson_Ref)) then
      Exit('object');

    if Assigned(LvSchema.FindValue(cJson_Items)) then
      Exit('array');
  end;

  Result := AJsonValue.Value;
end;

function TMethodObject.GetMethodName: string;
begin
  Result := RemoveDelphiReservedChars(FMethodName);
end;

destructor TMethodObject.Destroy;
begin
  if Assigned(FRequestBody) then
    FRequestBody.Free;

  if Assigned(FParams) then
    FParams.Free;
  inherited;
end;

{ TParameter }

constructor TParameter.Create(AName, AIn, ADescription, ADataType: string; ARequired: Boolean);
begin
  FName := CleanName(AName);
  FOriginalname := AName;
  FIn := AIn;
  FDescription := ADescription;
  FRequired := ARequired;
  FDataType := CLeanDataType(ADataType);
end;

function TParameter.CleanName(const AName: string): string;
var
  I: Integer;
begin
  Result := AName.Trim;
  for I := 1 to Length(Result) do
  begin
    if not CharInSet(Result[I], ['a'..'z', 'A'..'Z', '0'..'9', '_']) then
      Result[I] := '_';
  end;

  while Result.Contains('__') do
    Result := StringReplace(Result, '__', '_', [rfReplaceAll]);

  Result := Result.Trim(['_']);

  if Result.IsEmpty then
    Result := 'Param';

  if CharInSet(Result[1], ['0'..'9']) then
    Result := '_' + Result;
end;

function TParameter.CLeanDataType(ARawDataType: string): string;
begin
  Result := StringReplace(ARawDataType, '<', EmptyStr, []);
  Result := StringReplace(Result, '>', EmptyStr, []);

  if IndexStr(Result.ToLower, ['string', 'integer', 'boolean', 'number', 'float', 'array', 'object']) = -1 then
  begin
  {$IFDEF CODESITE}
    //CodeSite.Send('Data type cannot be realized: the "' + Result + '" Changed to Variant');
  {$ENDIF}
    Result := 'variant';
  end;

  if Result.Trim.Equals(EmptyStr) then
  begin
  {$IFDEF CODESITE}
    //CodeSite.Send('Empty DataType Changed to Variant!');
  {$ENDIF}
    Result := 'variant';
  end;
end;

{ TOpenAPIPath }
constructor TOpenAPIPath.CreateJson(AJsonPath: TJSONPair);
var
  LvJsonMethods: TJSONObject;
  LvJsonMethod: TJSONPair;
  LvMethodObject: TMethodObject;
  LvPathParameters: TJSONArray;
begin
  FJsonPath := AJsonPath;
  FPathValue := AJsonPath.JsonString.Value;
  FMethods := TObjectList<TMethodObject>.Create;
  LvPathParameters := nil;

  if Assigned(FJsonPath) then
  begin
    if FJsonPath.JsonValue.TryGetValue<TJSONObject>(LvJsonMethods) then
    begin
      if LvJsonMethods.FindValue(cJson_Parameters) is TJSONArray then
        LvPathParameters := LvJsonMethods.FindValue(cJson_Parameters) as TJSONArray;

      for LvJsonMethod in LvJsonMethods do
      begin
        if Assigned(LvJsonMethod) then
        begin
          if IndexStr(LvJsonMethod.JsonString.Value.ToLower, ['get', 'post', 'put', 'delete', 'patch', 'head', 'options', 'trace', 'connect']) = -1 then
            Continue;

          LvMethodObject := nil;
          MarkObjectUsed(LvMethodObject);
          LvMethodObject := TMethodObject.CreateJson(LvJsonMethod);
          if Assigned(LvMethodObject) then
          begin
            if LvMethodObject.FMethodName.Trim.IsEmpty then
              LvMethodObject.FMethodName := TMethodObject.BuildFallbackMethodName(LvJsonMethod.JsonString.Value, FPathValue);
            LvMethodObject.LoadJsonParameters(LvPathParameters);
            FMethods.Add(LvMethodObject);
          end;
        end;
      end;
    end;
  end;
end;

constructor TOpenAPIPath.CreateYaml(APath: string; AYamlNode: TYamlNode);
var
  I: Integer;
  LvMethodObject: TMethodObject;
  LvPathParameters: TYamlNode;
  LvHasPathParameters: Boolean;
begin
  FMethods := TObjectList<TMethodObject>.Create;
  FPathValue := APath;
  LvHasPathParameters := False;

  for I := 0 to Pred(AYamlNode.Count) do
  begin
    if AYamlNode.Elements[I].Key.ToString.ToLower.Equals(cJson_Parameters) then
    begin
      LvPathParameters := AYamlNode.Elements[I].Value;
      LvHasPathParameters := True;
      Break;
    end;
  end;

  for I := 0 to Pred(AYamlNode.Count) do
  begin
    if IndexStr(AYamlNode.Elements[I].Key.ToString.ToLower, ['get', 'post', 'put', 'delete', 'patch', 'head', 'options', 'trace', 'connect']) = -1 then
      Continue;

    LvMethodObject := nil;
    MarkObjectUsed(LvMethodObject);
    LvMethodObject := TMethodObject.CreateYaml(AYamlNode.Elements[I].Key.ToString, AYamlNode.Elements[I].Value);

    if Assigned(LvMethodObject) then
    begin
      if LvMethodObject.FMethodName.Trim.IsEmpty then
        LvMethodObject.FMethodName := TMethodObject.BuildFallbackMethodName(AYamlNode.Elements[I].Key.ToString, FPathValue);
      if LvHasPathParameters then
        LvMethodObject.LoadYamlParameters(LvPathParameters);
      FMethods.Add(LvMethodObject);
    end;
  end;
end;

constructor TOpenAPIPath.CreatePostman(APostmanItem: TPostmanItem);
var
  LvMethodObject: TMethodObject;
  LvPathArray: TJSONArray;
  I: Integer;
begin
  FMethods := TObjectList<TMethodObject>.Create;
  if Assigned(APostmanItem.Request) then
  begin
    if Assigned(APostmanItem.Request.Url) then
    begin
      if APostmanItem.Request.Url.Path is TJSONArray then
      begin
        LvPathArray := APostmanItem.Request.Url.Path as TJSONArray;
        for I := 0 to Pred(LvPathArray.Count) do
          FPathValue := FPathValue + '/' + LvPathArray.Items[I].Value;
      end
      else
        FPathValue := APostmanItem.Request.Url.Raw;
    end;
  end;

  LvMethodObject := nil;
  MarkObjectUsed(LvMethodObject);
  LvMethodObject := TMethodObject.CreatePostman(APostmanItem);

  if Assigned(LvMethodObject) then
    FMethods.Add(LvMethodObject);
end;

destructor TOpenAPIPath.Destroy;
begin
  if Assigned(FMethods) then
    FMethods.Free;
  inherited;
end;

{ TRequestBody }

constructor TRequestBody.Create;
begin
  FProperties := TDictionary<string, string>.Create;
end;

destructor TRequestBody.Destroy;
begin
  FProperties.Free;
  inherited;
end;

{TParamListHelper}
procedure TParamListHelper.AddEx(AParameter: TParameter);
var
  I: Integer;
  LvAllow: Boolean;
begin
  LvAllow := True;
  for I := 0 to Pred(Self.Count) do
  begin
    if Self[I].Name.ToLower.Equals(AParameter.Name.ToLower) then
    begin
      LvAllow := False;
      Break;
    end;
  end;
  if LvAllow then
    Self.Add(AParameter)
  else
    AParameter.Free;
end;
end.
