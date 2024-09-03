{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit OCW.ProjectWizardEx;

interface

uses
  System.Classes, Vcl.Dialogs, VCL.Graphics, System.JSON, System.SysUtils,
  System.IOUtils, VCL.Controls, VCL.Forms, WinApi.Windows, System.Rtti,
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
    class procedure CreateMainUnit(AExtractedOpenAPI: TFinalParsingObject; const APersonality: string; AModuleServices: IOTAModuleServices; AProject: IOTAProject);
    class function CreateModelUnit(AExtractedOpenAPI: TFinalParsingObject; const APersonality: string; AModuleServices: IOTAModuleServices; AProject: IOTAProject): IOTAModule;
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
                GlobalTempOpenAPIPathObjects.Add(LvPostmanCollection.Items[I].Name, TOpenAPIPath.CreatePostman(LvPostmanCollection.Items[I]));
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
var
  LvModelUnit: IOTAModule;
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
      LvRestClientCreator: IOTACreator;

      LvProjectSourceCreator: IOTACreator;
    begin
      TFinalParsingObject.Instance.Clear;
      LvWizardForm := TFrm_OCWNewProject.Create(nil);
      GlobalTempOpenAPIPathObjects := TObjectDictionary<string, TOpenAPIPath>.Create;
      TSingletonSettingObj.Instance.RegisterFormClassForTheming(TFrm_OCWNewProject, LvWizardForm);

      if LvWizardForm.ShowModal = mrOk then
      begin
        try
          if not LvWizardForm.AddToProjectGroup then
            (BorlandIDEServices as IOTAModuleServices).CloseAll;

          LvModuleServices := (BorlandIDEServices as IOTAModuleServices);

          // Create Project Source
          LvProjectSourceCreator := TOCWProjectFile.Create(APersonality, 'OCWNewProject');
          LvModuleServices.CreateModule(LvProjectSourceCreator);
          LvProject := GetActiveProject;

          LvConfig := (LvProject.ProjectOptions as IOTAProjectOptionsConfigurations).BaseConfiguration;
          LvConfig.SetValue(sUnitSearchPath, '$(OCW)');
          LvConfig.SetValue(sFramework, 'VCL');

          //Create Main Unit
          CreateMainUnit(LvWizardForm.ExtractedSpecification, APersonality, LvModuleServices, LvProject);

          //Create RestClient Unit
          LvRestClientCreator := TNewModelUnitEx.Create('RestClient', APersonality);
          LvRestClientUnit := LvModuleServices.CreateModule(LvRestClientCreator);
          if LvProject <> nil then
            LvProject.AddFile(LvRestClientUnit.FileName, True);

          // Create Model Units
          if (Assigned(LvWizardForm.ExtractedSpecification.FinalJson)) or (Assigned(LvWizardForm.ExtractedSpecification.FinalYaml)) then
            LvModelUnit := CreateModelUnit(LvWizardForm.ExtractedSpecification, APersonality, LvModuleServices, LvProject);

          // Force to save project to be cimpile-able
          if LvProject.Save(False, True) then
          begin
            LvRestClientUnit.Save(False, True);

            if Assigned(LvModelUnit) then
              LvModelUnit.Save(False, True);
          end;
        finally
          try
            LvWizardForm.Free;
            if Assigned(GlobalTempOpenAPIPathObjects) then
              GlobalTempOpenAPIPathObjects.Free;
            TFinalParsingObject.Instance.Clear;
          except
          end;
        end;
      end
      else
      begin
        try
          LvWizardForm.Free;
          if Assigned(GlobalTempOpenAPIPathObjects) then
            GlobalTempOpenAPIPathObjects.Free;

          TFinalParsingObject.Instance.Clear;
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
