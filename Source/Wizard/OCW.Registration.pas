{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit OCW.Registration;

interface

// Note: "Register" method name is case senstive.
procedure Register;

implementation

uses
  ToolsApi,
  DesignIntf,
  System.SysUtils,
  OCW.ProjectWizardEx,
  Winapi.Windows;

procedure Register;
begin
  ForceDemandLoadState(dlDisable);
  TOCWNewProjectWizard.RegisterOCWProjectWizard(sDelphiPersonality);
end;

end.
