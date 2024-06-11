{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit OCW.Splash.Registration;

interface

uses
  Winapi.Windows;

var
  bmSplashScreen: HBITMAP;

const
  OCW_VERSION = 'ver 1.0.0';

implementation

uses
  ToolsAPI, SysUtils, Vcl.Dialogs;

resourcestring
  resPackageName = 'OpenAPIClientWizard ' + OCW_VERSION;
  resLicense = 'Apache License, Version 2.0';
  resAboutTitle = 'OpenAPIClientWizard';
  resAboutDescription = 'https://github.com/alidehbansiahkarbon/OpenAPIClientWizard';

initialization

bmSplashScreen := LoadBitmap(hInstance, 'SPLASH');
(SplashScreenServices as IOTASplashScreenServices).AddPluginBitmap(resPackageName, bmSplashScreen, False, resLicense);

end.
