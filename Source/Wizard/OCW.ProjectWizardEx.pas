{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit OCW.ProjectWizardEx;

interface

uses
  System.Classes, Vcl.Dialogs, VCL.Graphics, System.JSON, System.SysUtils,
  System.IOUtils, VCL.Controls, VCL.Forms, WinApi.Windows, System.Rtti, System.StrUtils,
  PlatformAPI, ToolsApi, DccStrs, ExpertsRepository, System.Generics.Collections,

  OCW.Forms.NewProjectWizard,
  OCW.CodeGen.NewOCWProject,
  OCW.CodeGen.NewModelUnit,
  OCW.Util.OpenAPIHelper,
  OCW.Util.PostmanHelper,
  OCW.Util.Setting,
  OCW.Util.Core,
  Neslib.Yaml;

type
  TOCWNewProjectWizard = class
  private
    class var GlobalTempOpenAPIPathObjects: TObjectDictionary<string, TOpenAPIPath>;
    class procedure GetOpenAPIPathsObject(AExtractedOpenAPI: TFinalParsingObject);
    class procedure PrepareConsoleSampleCall;
    class procedure CreateMainUnit(AExtractedOpenAPI: TFinalParsingObject; const APersonality: string; AModuleServices: IOTAModuleServices; AProject: IOTAProject);
    class function CreateModelUnit(AExtractedOpenAPI: TFinalParsingObject; const APersonality: string; AModuleServices: IOTAModuleServices; AProject: IOTAProject): IOTAModule;
    class function CreateConsoleSampleUnit(const APersonality: string; AModuleServices: IOTAModuleServices; AProject: IOTAProject): IOTAModule;
  public
    class procedure RegisterOCWProjectWizard(const APersonality: string);
  end;

implementation
{$IFDEF CODESITE}
uses
  CodeSiteLogging;
{$ENDIF}

resourcestring
  sNewOCWProjectCaption = 'OpenAPI Client Project(Code Generator)';
  sNewOCWCProjectHint = 'Create New OpenAPI Client Project' + #13 + 'https://github.com/AliDehbansiahkarbon';

{ TOCVNewProjectWizard }

class procedure TOCWNewProjectWizard.CreateMainUnit(AExtractedOpenAPI: TFinalParsingObject; const APersonality: string;
                                                   AModuleServices: IOTAModuleServices; AProject: IOTAProject);
var
  LvMainUnit: IOTAModule;
  LvMainCreator: IOTACreator;
begin
  GetOpenAPIPathsObject(AExtractedOpenAPI);

  if Assigned(GlobalTempOpenAPIPathObjects) then
  begin
    if GlobalTempOpenAPIPathObjects.Count > 0 then
    begin
      LvMainCreator := TNewModelUnitEx.Create('UMain', APersonality, True, GlobalTempOpenAPIPathObjects);
      LvMainUnit := AModuleServices.CreateModule(LvMainCreator);
      if AProject <> nil then
        AProject.AddFile(LvMainUnit.FileName, False);
    end;
  end;
end;

class function TOCWNewProjectWizard.CreateModelUnit(AExtractedOpenAPI: TFinalParsingObject; const APersonality: string; AModuleServices: IOTAModuleServices; AProject: IOTAProject): IOTAModule;
var
  LvModelCreator: IOTACreator;
begin
  Result := nil;
  if Assigned(GlobalTempOpenAPIPathObjects) then
  begin
    if GlobalTempOpenAPIPathObjects.Count > 0 then
    begin
      LvModelCreator := TNewModelUnitEx.Create('Model', APersonality, False, GlobalTempOpenAPIPathObjects);

      Result := AModuleServices.CreateModule(LvModelCreator);
      if AProject <> nil then
        AProject.AddFile(Result.FileName, True);
    end;
  end;
end;

class function TOCWNewProjectWizard.CreateConsoleSampleUnit(const APersonality: string; AModuleServices: IOTAModuleServices; AProject: IOTAProject): IOTAModule;
var
  LvSampleCreator: IOTACreator;
begin
  Result := nil;
  LvSampleCreator := TNewModelUnitEx.Create('ConsoleSample', APersonality);
  Result := AModuleServices.CreateModule(LvSampleCreator);
  if AProject <> nil then
    AProject.AddFile(Result.FileName, True);
end;

class procedure TOCWNewProjectWizard.PrepareConsoleSampleCall;
var
  LvKey: string;
  LvPath: TOpenAPIPath;
  LvMethod: TMethodObject;
  LvMethodName: string;
  LvParams: string;
  LvDataType: string;
  LvMenuLines: string;
  LvCaseLines: string;
  LvVarLines: string;
  LvSampleIndex: Integer;

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

    if Result.IsEmpty then
      Result := AFallback;

    if not CharInSet(Result[1], ['a'..'z', 'A'..'Z', '_']) then
      Result := '_' + Result;
  end;

  function DelphiClassName(const AValue: string): string;
  begin
    Result := CleanDelphiIdentifier(AValue, 'OpenAPIRequest');
    if not Result.StartsWith('T') then
      Result := 'T' + Result;
  end;

  function BuildMethodName(AMethod: TMethodObject): string;
  begin
    Result := AMethod._MethodName;

    case TFinalParsingObject.PrefixType of
      0:
        case AMethod.MethodType of
          mtGet: Result := Result + '_Get';
          mtPost: Result := Result + '_Post';
          mtPatch: Result := Result + '_Patch';
          mtPut: Result := Result + '_Put';
          mtDelete: Result := Result + '_Delete';
        end;
      1:
        case AMethod.MethodType of
          mtGet: Result := 'Get_' + Result;
          mtPost: Result := 'Post_' + Result;
          mtPatch: Result := 'Patch_' + Result;
          mtPut: Result := 'Put_' + Result;
          mtDelete: Result := 'Delete_' + Result;
        end;
    end;
  end;

  function BuildRequestClassName(AMethod: TMethodObject): string;
  begin
    Result := DelphiClassName(BuildMethodName(AMethod) + 'Request');
  end;

  function HasRequestBody(AMethod: TMethodObject): Boolean;
  begin
    Result := Assigned(AMethod) and Assigned(AMethod.RequestBody) and
              ((AMethod.RequestBody.Properties.Count > 0) or
               (not AMethod.RequestBody.SchemaJson.Trim.IsEmpty) or
               (not AMethod.RequestBody.Example.Trim.IsEmpty));
  end;

  function BuildSampleParams(AMethod: TMethodObject): string;
  var
    LvSampleParam: TParameter;
  begin
    Result := EmptyStr;
    if not Assigned(AMethod.Params) then
      Exit;

    for LvSampleParam in AMethod.Params do
    begin
      LvDataType := LvSampleParam.DataType.Trim.ToLower;
      if not Result.IsEmpty then
        Result := Result + ', ';

      if (LvDataType = 'string') or (LvDataType = 'variant') then
        Result := Result + QuotedStr('')
      else if LvDataType = 'integer' then
        Result := Result + '0'
      else if LvDataType = 'boolean' then
        Result := Result + 'False'
      else if (LvDataType = 'number') or (LvDataType = 'float') then
        Result := Result + '0'
      else if LvDataType = 'array' then
        Result := Result + '[]'
      else
        Result := Result + 'nil';
    end;

    if HasRequestBody(AMethod) then
    begin
      if not Result.IsEmpty then
        Result := Result + ', ';
      Result := Result + 'RequestObj' + LvSampleIndex.ToString;
    end;
  end;
begin
  TSingletonSettingObj.Instance.ConsoleSampleCall :=
    '    Writeln(''OpenAPI client wrapper is ready. Call the generated methods on Client.'');' + sLineBreak;
  TSingletonSettingObj.Instance.ConsoleSampleVars := EmptyStr;

  if not Assigned(GlobalTempOpenAPIPathObjects) then
    Exit;

  LvMenuLines := EmptyStr;
  LvCaseLines := EmptyStr;
  LvVarLines := EmptyStr;
  LvSampleIndex := 0;

  for LvKey in GlobalTempOpenAPIPathObjects.Keys do
  begin
    LvPath := GlobalTempOpenAPIPathObjects.Items[LvKey];
    if not Assigned(LvPath) or not Assigned(LvPath.Methods) or (LvPath.Methods.Count = 0) then
      Continue;

    for LvMethod in LvPath.Methods do
    begin
      Inc(LvSampleIndex);
      LvMethodName := BuildMethodName(LvMethod);
      LvParams := BuildSampleParams(LvMethod);

      if HasRequestBody(LvMethod) then
        LvVarLines := LvVarLines +
          '  RequestObj' + LvSampleIndex.ToString + ': ' + BuildRequestClassName(LvMethod) + ';' + sLineBreak;

      LvMenuLines := LvMenuLines +
        '    Writeln(' + QuotedStr(Format('  %d. %s', [LvSampleIndex, LvMethodName])) + ');' + sLineBreak;

      LvCaseLines := LvCaseLines +
        '      ' + LvSampleIndex.ToString + ':' + sLineBreak +
        '        begin' + sLineBreak +
        '          Writeln(' + QuotedStr('Calling ' + LvMethodName + '...') + ');' + sLineBreak +
        IfThen(HasRequestBody(LvMethod),
          '          RequestObj' + LvSampleIndex.ToString + ' := ' + BuildRequestClassName(LvMethod) + '.Create;' + sLineBreak +
          '          try' + sLineBreak,
          EmptyStr) +
        '          Response := Client.' + LvMethodName + '(' + LvParams + ');' + sLineBreak +
        '          Writeln(Response);' + sLineBreak +
        IfThen(HasRequestBody(LvMethod),
          '          finally' + sLineBreak +
          '            RequestObj' + LvSampleIndex.ToString + '.Free;' + sLineBreak +
          '          end;' + sLineBreak,
          EmptyStr) +
        '        end;' + sLineBreak;
    end;
  end;

  if LvSampleIndex = 0 then
    Exit;

  TSingletonSettingObj.Instance.ConsoleSampleVars := LvVarLines;
  TSingletonSettingObj.Instance.ConsoleSampleCall :=
    '    Writeln(''OpenAPI API usage samples:'');' + sLineBreak +
    LvMenuLines +
    '    Writeln;' + sLineBreak +
    '    Write(''Select a sample number and press Enter, or leave blank to exit: '');' + sLineBreak +
    '    Readln(Choice);' + sLineBreak +
    '    case StrToIntDef(Trim(Choice), 0) of' + sLineBreak +
    LvCaseLines +
    '    else' + sLineBreak +
    '      Writeln(''No sample selected.'');' + sLineBreak +
    '    end;' + sLineBreak;
end;

class procedure TOCWNewProjectWizard.GetOpenAPIPathsObject(AExtractedOpenAPI: TFinalParsingObject);
var
  LvJsonPaths: TJSONObject;
  LvJsonPath: TJSONPair;

  LvYamlDoc: IYamlDocument;
  LvYamlPaths: TYamlNode;

  LvPostmanCollection: TPostmanCollection;
  I, J: Integer;
begin
  if GlobalTempOpenAPIPathObjects.Count > 0 then
    Exit;

  try
    case AExtractedOpenAPI.FinalObjectType of
      atSwaggerJSON, atOpenAPiJson:
      begin
        try
          LvJsonPaths := TJSONObject(AExtractedOpenAPI.FinalJson).GetValue('paths') as TJSONObject;
        except on E: exception do
          begin
            LvJsonPaths := nil;
            MarkObjectUsed(LvJsonPaths);
            {$IFDEF CODESITE}
            CodeSite.Send('(atSwaggerJSON, atOpenAPiJson), Cannot load from Json: ' + E.Message);
            {$ELSE}
            raise;
            {$ENDIF}
          end;
        end;

        if Assigned(LvJsonPaths) then
        begin
          if LvJsonPaths.Count > 0 then
          begin
            for LvJsonPath in LvJsonPaths do
              GlobalTempOpenAPIPathObjects.Add(LvJsonPath.JsonString.Value, TOpenAPIPath.CreateJson(LvJsonPath));
          end;
        end;
      end;

      atOpenAPIYaml:
      begin
        LvYamlDoc := AExtractedOpenAPI.FinalYaml;

        if Assigned(LvYamlDoc) then
        begin
          if LvYamlDoc.Root.count > 0 then
          begin
            for I := 0 to Pred(LvYamlDoc.Root.count) do
            begin
              if LvYamlDoc.Root.Elements[I].Key.ToString.ToLower.Equals('paths') then
              begin
                LvYamlPaths := LvYamlDoc.Root.Elements[I].Value;
                for J := 0 to Pred(LvYamlPaths.Count) do
                  GlobalTempOpenAPIPathObjects.Add(LvYamlPaths.Elements[J].Key.ToString, TOpenAPIPath.CreateYaml(LvYamlPaths.Elements[J].Key.ToString, LvYamlPaths.Elements[J].Value));
              end;
            end;
          end;
        end;
      end;

      atPostManCollection:
      begin
        if Assigned(AExtractedOpenAPI.FinalJson) then
        begin
          LvPostmanCollection := TPostmanCollection.Create;
          try
            LvPostmanCollection.LoadFromJson(TJSONObject(AExtractedOpenAPI.FinalJson));
          except on E:Exception do
            {$IFDEF CODESITE}
              CodeSite.Send('atPostManCollection, Cannot load from Json: ' + E.Message);
            {$ELSE}
              raise;
            {$ENDIF}
          end;

          if LvPostmanCollection.Items.Count > 0 then
          begin
            for I := 0 to Pred(LvPostmanCollection.Items.Count) do
            begin
              if not Assigned(LvPostmanCollection.Items[I]) then
                Continue;

              if not Assigned(LvPostmanCollection.Items[I].Request) then
                Continue;

              try
                GlobalTempOpenAPIPathObjects.Add(LvPostmanCollection.Items[I].Name + '_' + I.ToString, TOpenAPIPath.CreatePostman(LvPostmanCollection.Items[I]));
              except on E: Exception do
                {$IFDEF CODESITE}
                  CodeSite.Send('Cannot extract method: ' + LvPostmanCollection.Items[I].Name + #13 + E.Message);
                {$ELSE}
                  raise;
                {$ENDIF}
              end;
            end;
          end;
        end;
      end;
    end;
  except on E: Exception do
    begin
      GlobalTempOpenAPIPathObjects := nil;
      raise;
    end;
  end;
end;

class procedure TOCWNewProjectWizard.RegisterOCWProjectWizard(const APersonality: string);
begin
  RegisterPackageWizard(TExpertsRepositoryProjectWizardWithProc.Create(APersonality, sNewOCWCProjectHint, sNewOCWProjectCaption,
    'OCW.Wizard.NewProjectWizard', // do not localize
    'OpenAPIClientWizard', 'Ali Dehbansiahkarbon - https://github.com/alidehbansiahkarbon/OpenAPIClientWizard', // do not localize
    procedure
    var
      LvWizardForm: TFrm_OCWNewProject;
      LvModuleServices: IOTAModuleServices;
      LvProject: IOTAProject;
      LvConfig: IOTABuildConfiguration;

      LvRestClientUnit: IOTAModule;
      LvModelUnit: IOTAModule;
      LvConsoleSampleUnit: IOTAModule;
      LvRestClientCreator: IOTACreator;

      LvProjectSourceCreator: IOTACreator;
    begin
      LvModelUnit := nil;
      LvConsoleSampleUnit := nil;
      TFinalParsingObject.Clear;
      LvWizardForm := TFrm_OCWNewProject.Create(nil);
      GlobalTempOpenAPIPathObjects := TObjectDictionary<string, TOpenAPIPath>.Create;
      TSingletonSettingObj.Instance.RegisterFormClassForTheming(TFrm_OCWNewProject, LvWizardForm);

      if LvWizardForm.ShowModal = mrOk then
      begin
        Screen.Cursor := crHourGlass;
        try
          if not LvWizardForm.AddToProjectGroup then
            (BorlandIDEServices as IOTAModuleServices).CloseAll;

          GetOpenAPIPathsObject(LvWizardForm.ExtractedSpecification);
          PrepareConsoleSampleCall;

          LvModuleServices := (BorlandIDEServices as IOTAModuleServices);

          // Create Project Source
          LvProjectSourceCreator := TOCWProjectFile.Create(APersonality, 'OCWNewProject');
          LvModuleServices.CreateModule(LvProjectSourceCreator);
          LvProject := GetActiveProject;

          LvConfig := (LvProject.ProjectOptions as IOTAProjectOptionsConfigurations).BaseConfiguration;
          LvConfig.SetValue(sUnitSearchPath, '$(OCW)');
          if TSingletonSettingObj.Instance.OutputType = potSampleVCL then
            LvConfig.SetValue(sFramework, 'VCL');

          //Create Main Unit
          if TSingletonSettingObj.Instance.OutputType = potSampleVCL then
            CreateMainUnit(LvWizardForm.ExtractedSpecification, APersonality, LvModuleServices, LvProject);

          //Create RestClient Unit
          LvRestClientCreator := TNewModelUnitEx.Create('RestClient', APersonality);
          LvRestClientUnit := LvModuleServices.CreateModule(LvRestClientCreator);
          if LvProject <> nil then
            LvProject.AddFile(LvRestClientUnit.FileName, True);

          // Create Model Units
          if (Assigned(LvWizardForm.ExtractedSpecification.FinalJson)) or (Assigned(LvWizardForm.ExtractedSpecification.FinalYaml)) then
            LvModelUnit := CreateModelUnit(LvWizardForm.ExtractedSpecification, APersonality, LvModuleServices, LvProject);

          if TSingletonSettingObj.Instance.OutputType = potSampleConsole then
            LvConsoleSampleUnit := CreateConsoleSampleUnit(APersonality, LvModuleServices, LvProject);

          // Force to save project to be cimpile-able
          if LvProject.Save(False, True) then
          begin
            LvRestClientUnit.Save(False, True);

            if Assigned(LvModelUnit) then
              LvModelUnit.Save(False, True);

            if Assigned(LvConsoleSampleUnit) then
              LvConsoleSampleUnit.Save(False, True);
          end;
        finally
          try
            Screen.Cursor := crDefault;
            LvWizardForm.Free;
            if Assigned(GlobalTempOpenAPIPathObjects) then
              GlobalTempOpenAPIPathObjects.Free;
            TFinalParsingObject.Clear;
          except
          end;
        end;
      end
      else
      begin
        try
          Screen.Cursor := crDefault;
          LvWizardForm.Free;
          if Assigned(GlobalTempOpenAPIPathObjects) then
            GlobalTempOpenAPIPathObjects.Free;

          TFinalParsingObject.Clear;
        except on E: Exception do
        end;
      end;
    end,
    function: Cardinal
    begin
      Result := LoadIcon(HInstance, 'OCWProjectIcon');
    end, TArray<string>.Create(cWin32Platform, cWin64Platform), nil));
end;
end.
