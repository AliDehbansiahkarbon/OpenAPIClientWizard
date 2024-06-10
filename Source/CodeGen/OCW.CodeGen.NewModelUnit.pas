{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit OCW.CodeGen.NewModelUnit;

interface

uses
  ToolsApi, System.IOUtils, System.JSON, System.Generics.Collections,
  System.StrUtils, System.SysUtils, System.Types,

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
    function AddCastings(AParam: TParameter): string;
    function ConvertAuthenticationType(AAuthType: Byte): string;
    function AddBreaklines(const AText: string; ADelimitter: Char; ABreakLength: Integer = 1000): string;
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
  OCW.CodeGen.Templates,
  OCW.CodeGen.SourceFile;

{ TNewModelUnitEx }

function TNewModelUnitEx.ConvertAuthenticationType(AAuthType: Byte): string;
begin
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
  Result := '';
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
  FAncestorName := '';
  FFormName := '';
  FImplFileName := '';
  FIntfFileName := '';
  FModelClassName := AModelClassName;
  FIsMainUnit := AIsMainUnit;
  Personality := APersonality;

  if AIsMainUnit then
    FFormName := 'Frm_Main';

  if AModelClassName.Equals('RestClient') then
    FImplFileName := 'URestClient.pas';

  if AModelClassName.Equals('Model') then
  begin
    FAncestorName := '';
    FFormName := '';
    FIntfFileName := '';
    FImplFileName := 'ClientClass.pas';
  end;

  FOpenAPIPaths:= AOpenAPIPaths;
end;

function TNewModelUnitEx.GetPrefix(AMethodType: TMethodType): string;
begin
  if TFinalParsingObject.PrefixType = 1 then
  begin
    case AMethodType of
      mtGet: Result := 'Get_';
      mtPost: Result := 'Post_';
      mtPut: Result := 'Put_';
      mtDelete: Result := 'Delete_';
    end;
  end
  else
    Result := EmptyStr;
end;

function TNewModelUnitEx.GetSuffix(AMethodType: TMethodType): string;
begin
  if TFinalParsingObject.PrefixType = 0 then
  begin
    case AMethodType of
      mtGet: Result := '_Get';
      mtPost: Result := '_Post';
      mtPut: Result := '_Put';
      mtDelete: Result := '_Delete';
    end;
  end
  else
    Result := EmptyStr;
end;

function TNewModelUnitEx.AddCastings(AParam: TParameter): string;
var
  LvParamName: string;
begin
  LvParamName := ConvertToCamelCase(AParam.Name);

  if AParam.DataType.ToLower.Equals('integer') then
    Result := ' + A' + LvParamName + '.ToString'

  else if AParam.DataType.ToLower.Equals('string') then
    Result := ' + A' + LvParamName

  else if AParam.DataType.ToLower.Equals('boolean') then
    Result := ' + CastByBooleanSetting(' + 'A' + LvParamName + ', ' + TSingletonSettingObj.Instance.BooleanStringForm.ToString +')'

  else if (AParam.DataType.ToLower.Equals('number')) or (AParam.DataType.ToLower.Equals('float')) then
    Result := ' + FloatToStr(' + 'A' + LvParamName + ')'

  else if AParam.DataType.ToLower.Equals('array') then
    Result := ' + [A' + LvParamName + ']'
  else
    Result := ' + A' + LvParamName;
end;

function TNewModelUnitEx.BuildFunctionBody(AMethodObj: TMethodObject): string;
var
  LvParam: TParameter;

  LvQueryParams: string;
  LvInPathParams: string;
  LvParameterType: string;
  LvFullParamList: string;
  LvRequestObjectSection: string;
begin
  Result := EmptyStr;
  LvParameterType := EmptyStr;
  LvInPathParams := EmptyStr;
  LvQueryParams := EmptyStr;
  LvFullParamList:= EmptyStr;
  LvRequestObjectSection := EmptyStr;

  if Assigned(AMethodObj.Params) then
  begin
    for LvParam in AMethodObj.Params do
    begin
      LvParameterType := LvParam.&In.Trim.ToLower;

      if LvParameterType.Equals('path') then
        LvInPathParams := LvInPathParams + IfThen(LvInPathParams.IsEmpty, EmptyStr, ' + ') + QuotedStr('/') + AddCastings(LvParam)
      else if LvParameterType.Equals('query') then
        LvQueryParams := LvQueryParams +
          IfThen(LvQueryParams.IsEmpty, EmptyStr, ' + ') +
          QuotedStr(IfThen(LvQueryParams.IsEmpty, '?', '&') + LvParam.Name + '=' ) + AddCastings(LvParam);
    end;
  end;

  LvFullParamList := LvInPathParams + IfThen((LvInPathParams.Trim.IsEmpty or LvQueryParams.Trim.IsEmpty), EmptyStr, ' + ') +  LvQueryParams;
  LvFullParamList := IfThen(LvFullParamList.Trim.IsEmpty, EmptyStr, Concat(' + ', LvFullParamList.TrimRight));

  if AMethodObj.RequestBody.Properties.Count > 0 then
    LvRequestObjectSection := 'LvStruct.RequestObject := ARequestObj;' + sLineBreak;

  case AMethodObj.MethodType of
    mtGet: Result := Format(sGetFunctionBody, [AMethodObj._MethodName, LvFullParamList, LvRequestObjectSection]);
    mtPost: Result := Format(sPostFunctionBody, [AMethodObj._MethodName, LvFullParamList, LvRequestObjectSection]);
    mtPut: Result := Format(sPutFunctionBody, [AMethodObj._MethodName, LvFullParamList, LvRequestObjectSection]);
    mtDelete: Result := Format(sDeleteFunctionBody, [AMethodObj._MethodName, LvFullParamList, LvRequestObjectSection]);
  end;

  if Result.IsEmpty then
    Result := 'begin' + sLineBreak;
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
          CodeSite.Send('253/PrepareSourceString(sClientClassUnit)' + #13 + E.Message);
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
begin
  Result := sMainUnit;
  LvBtnName := EmptyStr;
  LvBtnCallLines := EmptyStr;
  LvParameterDataType := EmptyStr;
  LvBtnDefinitionLines := EmptyStr;
  LvButtonsCreationLines := EmptyStr;
  LvParamSampleaValueFinalList := EmptyStr;

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

          LvBtnDefinitionLines := LvBtnDefinitionLines + sLineBreak + Format('    procedure %0:sClick(Sender: TObject);', ['Btn_' + LvBtnName]);
          LvTempStr:= GetPrefix(LvMethod.MethodType) + LvBtnName + GetSuffix(LvMethod.MethodType) + '(' + LvParamSampleaValueFinalList + ')';
          LvBtnCallLines := LvBtnCallLines + sLineBreak + Format(sButtonOnClickEvent, ['Btn_' + LvBtnName, LvTempStr ]);
          LvButtonsCreationLines := LvButtonsCreationLines + '  AddButton(' +  QuotedStr('Btn_' + LvBtnName) + ', ' + 'Btn_' + LvBtnName + 'Click);' + sLineBreak;
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
  LvAllPutfunctionHeaders: string;
  LvAllPutFunctionImplementation: string;
  LvAllDeletefunctionHeaders: string;
  LvAllDeleteFunctionImplementation: string;

  LvParameterDataType: string;
  LvParamFinalList: string;
  LvMethodListAddition: string;

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

  for LvKey in FOpenAPIPaths.Keys do
  begin
    LvOpenAPIPathObject := FOpenAPIPaths.Items[LvKey];

    if Assigned(LvOpenAPIPathObject) then
    begin
      for LvMethod in LvOpenAPIPathObject.Methods do
      begin
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
          if Assigned(LvMethod.RequestBody.Properties) then
          begin
            if LvMethod.RequestBody.Properties.Count > 0 then
            begin
              if not LvParamFinalList.IsEmpty then
                LvParamFinalList := Concat('(', LvParamFinalList, '; ARequestObj: TObject = nil', ')')
              else
                LvParamFinalList := '(ARequestObj: TObject = nil)';
            end else if not LvParamFinalList.IsEmpty then
              LvParamFinalList := Concat('(', LvParamFinalList, ')');
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
                                IfThen(LvAllPutfunctionHeaders.Trim.Equals(EmptyStr), '', AddBreaklines(LvAllPutfunctionHeaders, ';') + sLineBreak),
                                IfThen(LvAllDeletefunctionHeaders.Trim.Equals(EmptyStr), '', AddBreaklines(LvAllDeletefunctionHeaders, ';') + sLineBreak),
                                IfThen(LvMethodListAddition.Trim.Equals(EmptyStr), '', AddBreaklines(LvMethodListAddition, ';') + sLineBreak),
                                IfThen(LvAllGetFunctionImplementation.Trim.Equals(EmptyStr), '', AddBreaklines(LvAllGetFunctionImplementation, '+') + sLineBreak),
                                IfThen(LvAllPostFunctionImplementation.Trim.Equals(EmptyStr), '', AddBreaklines(LvAllPostFunctionImplementation, '+') + sLineBreak),
                                IfThen(LvAllPutFunctionImplementation.Trim.Equals(EmptyStr), '', AddBreaklines(LvAllPutFunctionImplementation, '+') + sLineBreak),
                                IfThen(LvAllDeleteFunctionImplementation.Trim.Equals(EmptyStr), '', AddBreaklines(LvAllDeleteFunctionImplementation, '+') + sLineBreak)]);

  //0: BaseURL
  //1: UserName
  //2: Password
  //3: Token or API Key
  //4: GetMethods Definition
  //5: PostMethods Definition
  //6: PutMethods Definition
  //7: DeleteMethod_Definition
  //8: Add Paths
  //9: GetMethod Implementations
  //10: PostMethod Implementations
  //11: PutMethod Implementations
  //12 DeleteMethod Implementations

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
