{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit OCW.CodeGen.Templates;

interface

resourcestring
  // 0 - project name
  // 1 - Project name Abbreviation
  sOCWPR =
    'program %0:s;' + sLineBreak +
    sLineBreak +
    'uses' + sLineBreak +
    '  Vcl.Forms,' + sLineBreak +
    '  Vcl.ExtCtrls;' + sLineBreak +
     sLineBreak +
    '{$R *.res}' + sLineBreak +
    sLineBreak +
    'var' + sLineBreak +
    '  Tmr: TTimer;' + sLineBreak +

    sLineBreak +
    'begin' + sLineBreak +
    '  Application.Initialize;' + sLineBreak +
    '  Application.MainFormOnTaskbar := True;' + sLineBreak +
    '  Application.CreateForm(TFrm_Main, Frm_Main);' + sLineBreak +
    sLineBreak +
    '  Tmr := TTimer.Create(Frm_Main);' + sLineBreak +
    '  Tmr.Interval := 10;' + sLineBreak +
    '  Tmr.OnTimer := Frm_Main.Timer1Timer;' + sLineBreak +
    '  Tmr.Enabled := True;' + sLineBreak +
    sLineBreak +
    '  Application.Run;' + sLineBreak +
    'end.';

  // Path for unit1 to be clear : C:\Users\Current windows Username\Documents\Embarcadero\Studio\Projects
  // 0: UnitName
  // 1: Additional functions
  // 2: Button events
  // 3: Necessary Buttons addition

  sMainUnit =
    'unit %0:s;' + sLineBreak +
    sLineBreak +
    'interface' + sLineBreak +
    sLineBreak +
    'uses' + sLineBreak +
    '  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,' + sLineBreak +
    '  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Math, ClientClass;' + sLineBreak +
    sLineBreak +
    'type' + sLineBreak +
    '  TFrm_Main = class(TForm)' + sLineBreak +
    '    procedure Timer1Timer(Sender: TObject);' + sLineBreak +
    '    %1:s' + sLineBreak +
    '  private' + sLineBreak +
    '    FGridPanel: TGridPanel;' + sLineBreak +
    '    FWidth: Integer;' + sLineBreak +
    '    FButtonCount: Integer;' + sLineBreak +
    '    FMemo: TMemo;' + sLineBreak +
    '    FMaximumWidth: Integer;' + sLineBreak +
    '    procedure AddGridPanel;' + sLineBreak +
    '    procedure AddButton(ACaption: string; AProc: TNotifyEvent);' + sLineBreak +
    '    procedure CreateUIObjects;' + sLineBreak +
    '  public' + sLineBreak +
    '    { Public declarations }' + sLineBreak +
    '  end;' + sLineBreak +
    sLineBreak +
    'var' + sLineBreak +
    '  Frm_Main: TFrm_Main;' + sLineBreak +
    sLineBreak +
    'implementation' + sLineBreak +
    sLineBreak +
    '{$R *.dfm}' + sLineBreak +
    sLineBreak +
    'procedure TFrm_Main.Timer1Timer(Sender: TObject);' + sLineBreak +
    'begin' + sLineBreak +
    '  TTimer(Sender).Enabled := False;' + sLineBreak +
    '  CreateUIObjects;' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'procedure TFrm_Main.AddButton(ACaption: string; AProc: TNotifyEvent);' + sLineBreak +
    'begin' + sLineBreak +
    '  Inc(FButtonCount);' + sLineBreak +
    '  with TButton.Create(Self) do' + sLineBreak +
    '  begin' + sLineBreak +
    '    Parent := FGridPanel;' + sLineBreak +
    '    OnClick := AProc;' + sLineBreak +
    '    Caption := ACaption;' + sLineBreak +
    '    Width := Canvas.TextWidth(Caption) + 12;' + sLineBreak +
    '    FMaximumWidth := Max(Width, FMaximumWidth);' + sLineBreak +
    '    Height := 32;' + sLineBreak +
    '    if FButtonCount < 5 then' + sLineBreak +
    '      FWidth := FWidth + Width;' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'procedure TFrm_Main.AddGridPanel;' + sLineBreak +
    'var' + sLineBreak +
    '  LvColumn: TColumnItem;' + sLineBreak +
    '  LvRow: TRowItem;' + sLineBreak +
    'begin' + sLineBreak +
    '  FGridPanel := TGridPanel.Create(Self);' + sLineBreak +
    sLineBreak +
    '  with FGridPanel do' + sLineBreak +
    '  begin' + sLineBreak +
    '    Parent := Self;' + sLineBreak +
    '    AlignWithMargins := True;' + sLineBreak +
    '    Left := 10;' + sLineBreak +
    '    Top := 10;' + sLineBreak +
    '    Width := 301;' + sLineBreak +
    '    Height := 403;' + sLineBreak +
    '    Margins.Left := 10;' + sLineBreak +
    '    Margins.Top := 10;' + sLineBreak +
    '    Align := alClient;' + sLineBreak +
    '    BevelEdges := [];' + sLineBreak +
    '    BevelOuter := bvNone;' + sLineBreak +
    '    Caption := '''';' + sLineBreak +
    '    ShowCaption := False;' + sLineBreak +
    '    TabOrder := 0;' + sLineBreak +
    sLineBreak +
    '    ColumnCollection.Clear;' + sLineBreak +
    '    ColumnCollection.Add.SizeStyle := ssAuto;' + sLineBreak +
    '    ColumnCollection.Add.SizeStyle := ssAuto;' + sLineBreak +
    '    ColumnCollection.Add.SizeStyle := ssAuto;' + sLineBreak +
    '    ColumnCollection.Add.SizeStyle := ssAuto;' + sLineBreak +
    sLineBreak +
    '    RowCollection.Clear;' + sLineBreak +
    '    RowCollection.Add.SizeStyle := ssAuto;' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    '//=========================================' +
    ' %2:s' + sLineBreak +
    '//=========================================' +
    sLineBreak +
    'procedure TFrm_Main.CreateUIObjects;' + sLineBreak +
    'var' + sLineBreak +
    '  I: Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  FButtonCount := 0;' + sLineBreak +
    '  FWidth := 0;' + sLineBreak +
    '  AddGridPanel;' + sLineBreak +
    sLineBreak +
    '  %3:s' + sLineBreak +

    '  for I := 0 to Pred(Self.ComponentCount) do' + sLineBreak +
    '  begin' + sLineBreak +
    '    if Self.Components[I] is TButton then' + sLineBreak +
    '      TButton(Self.Components[I]).Width := FMaximumWidth;' + sLineBreak +
    '  end;' + sLineBreak +
    sLineBreak +
    '  for I := 0 to Pred(FGridPanel.ColumnCollection.Count) do' + sLineBreak +
    '    FGridPanel.ColumnCollection.Items[I].SizeStyle := ssAuto;' + sLineBreak +
    sLineBreak +
    '  for I := 0 to Pred(FGridPanel.RowCollection.Count) do' + sLineBreak +
    '    FGridPanel.RowCollection.Items[I].SizeStyle := ssAuto;' + sLineBreak +
    sLineBreak +
    '  FGridPanel.Align := alLeft;' + sLineBreak +
    sLineBreak +
    '  FMemo := TMemo.Create(Self);' + sLineBreak +
    '  with FMemo do' + sLineBreak +
    '  begin' + sLineBreak +
    '    Align := alClient;' + sLineBreak +
    '    ScrollBars := ssBoth;' + sLineBreak +
    '    Parent := Self;' + sLineBreak +
    '  end;' + sLineBreak +
    sLineBreak +
    '  if FGridPanel.ColumnCollection.Count > 3 then' + sLineBreak +
    '    FGridPanel.Width := 4 * FMaximumWidth;' + sLineBreak +
    sLineBreak +
    sLineBreak +
    '  Self.Width := Max(300, (FWidth + 361));' + sLineBreak +
    '  Self.Height := Max(300, ((35 * FGridPanel.RowCollection.Count)));' + sLineBreak +
    '  Self.WindowState := wsMaximized;' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'end.';


  sRestClientPartOne =
    'unit URestClient;' + sLineBreak +
    sLineBreak +
    'interface' + sLineBreak +
    sLineBreak +
    'uses' + sLineBreak +
    '  System.Classes, System.SysUtils, VCL.Dialogs, System.Net.URLClient, System.Net.HttpClient,' + sLineBreak +
    '  System.Net.HttpClientComponent, System.NetEncoding, Rest.Json;' + sLineBreak +
    sLineBreak +
    'type' + sLineBreak +
    '  TApiStructure = class' + sLineBreak +
    '  private' + sLineBreak +
    '    FRequestObject: TObject;' + sLineBreak +
    '    FApiAddress: string;' + sLineBreak +
    '    FToken: String;' + sLineBreak +
    '    FAuthType: String;' + sLineBreak +
    '    FMethod: String;' + sLineBreak +
    '    FCustomHeaders: TArray<string>;' + sLineBreak +
    '    FContentType: string;' + sLineBreak +
    '    FAccept: string;' + sLineBreak +
    '    FTimeOut: Integer;' + sLineBreak +
    '    FUsername: string;' + sLineBreak +
    '    FPassword: string;' + sLineBreak +
    '    procedure SetCustomHeadersCount(AValue: Integer);' + sLineBreak +
    '    function GetCustomHeadersCount: Integer;' + sLineBreak +
    '  public' + sLineBreak +
    '    constructor Create;' + sLineBreak +
    '    property RequestObject: TObject read FRequestObject write FRequestObject;' + sLineBreak +
    '    property ApiAddress: string read FApiAddress write FApiAddress;' + sLineBreak +
    '    property Token: string read FToken write FToken;' + sLineBreak +
    '    property AuthType: string read FAuthType write FAuthType;' + sLineBreak +
    '    property Method: string read FMethod write FMethod;' + sLineBreak +
    '    property CustomHeaders: TArray<string> read FCustomHeaders write FCustomHeaders;' + sLineBreak +
    '    property ContentType: string read FContentType write FContentType;' + sLineBreak +
    '    property Accept: string read FAccept write FAccept;' + sLineBreak +
    '    property TimeOut: Integer read FTimeOut write FTimeOut;' + sLineBreak +
    '    property Username: string read FUsername write FUsername;' + sLineBreak +
    '    property Password: string read FPassword write FPassword;' + sLineBreak +
    '    property CustomHeadersCount: Integer read GetCustomHeadersCount write SetCustomHeadersCount;' + sLineBreak +
    '  end;' + sLineBreak +
    sLineBreak +
    '  function SendToAPI(AApiStruct: TApiStructure): string;' + sLineBreak +
    sLineBreak +
    'implementation' + sLineBreak +
    sLineBreak +
    'function CreateNetHttp(AApiAddress, AContentType, AAccept:String; ATimeOut: Integer): TNetHTTPClient;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := TNetHTTPClient.Create(nil);' + sLineBreak +
    '  Result.HandleRedirects := Pos(''https://'', AApiAddress) > 0;' + sLineBreak +
    '  Result.ConnectionTimeout := ATimeOut; //5 minutes' + sLineBreak +
    '  Result.ResponseTimeout := ATimeOut; //5 minutes' + sLineBreak +
    '  Result.AcceptCharSet := ''utf-8'';' + sLineBreak +
    '  if AContentType = '''' then' + sLineBreak +
    '    Result.ContentType := ''application/json''' + sLineBreak +
    '  else' + sLineBreak +
    '    Result.ContentType := AContentType;' + sLineBreak +
    sLineBreak +
    '  if AAccept.IsEmpty then' + sLineBreak +
    '    Result.Accept := ''application/json''' + sLineBreak +
    '  else' + sLineBreak +
    '    Result.Accept := AAccept;' + sLineBreak +
    sLineBreak +
    '  Result.AcceptEncoding := ''utf-8'';' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'function SendToAPI(AApiStruct: TApiStructure): string;' + sLineBreak +
    'var' + sLineBreak +
    '  I: Integer;' + sLineBreak +
    '  LvHttp: TNetHTTPClient;' + sLineBreak +
    '  LvResponseStream, LvRequestStream: TStringStream;' + sLineBreak +
    '  LvRequestString: string;' + sLineBreak +
    '  LvHeaders: TNetHeaders;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := '''';' + sLineBreak +
    '  if AApiStruct.ApiAddress = '''' then' + sLineBreak +
    '    Exit;' + sLineBreak +
    sLineBreak +
    '  LvHttp := CreateNetHttp(AApiStruct.ApiAddress, AApiStruct.ContentType, AApiStruct.Accept, AApiStruct.TimeOut);' + sLineBreak +
    '  LvResponseStream := TStringStream.Create('''', TEncoding.UTF8);' + sLineBreak +
    '  try' + sLineBreak +
    '    if AApiStruct.Token <> '''' then' + sLineBreak +
    '    begin' + sLineBreak +
    '      SetLength(LvHeaders, 1);' + sLineBreak +
    '      LvHeaders[0].Name := ''Authorization'';' + sLineBreak +
    '      LvHeaders[0].Value := AApiStruct.AuthType + '' '' + AApiStruct.Token;' + sLineBreak +
    '    end' + sLineBreak +
    '    else if AApiStruct.AuthType.ToLower.Trim = ''basic'' then' + sLineBreak +
    '    begin' + sLineBreak +
    '      SetLength(LvHeaders, 1);' + sLineBreak +
    '      LvHeaders[0].Name := ''Authorization'';' + sLineBreak +
    '      LvHeaders[0].Value := ''Basic '' + TNetEncoding.Base64.Encode(Format(''%%s:%%s'', [AApiStruct.Username.Trim, AApiStruct.Password.Trim]));' + sLineBreak +
    '    end;' + sLineBreak;

  sRestClientPartTwo =
    sLineBreak +
    '    if Length(AApiStruct.CustomHeaders) > 0 then' + sLineBreak +
    '    begin' + sLineBreak +
    '      for I := 0 to Length(AApiStruct.CustomHeaders) - 1 do' + sLineBreak +
    '      begin' + sLineBreak +
    '        if Odd(I) then Continue;' + sLineBreak +
    '        if AApiStruct.CustomHeaders[I] <> '''' then' + sLineBreak +
    '        begin' + sLineBreak +
    '          SetLength(LvHeaders, length(LvHeaders) + 1);' + sLineBreak +
    '          LvHeaders[length(LvHeaders) - 1].Name := AApiStruct.CustomHeaders[I];' + sLineBreak +
    '          LvHeaders[length(LvHeaders) - 1].Value := AApiStruct.CustomHeaders[I + 1];' + sLineBreak +
    '        end;' + sLineBreak +
    '      end;' + sLineBreak +
    '    end;' + sLineBreak +
    '    LvRequestString := '''';' + sLineBreak +
    '    if AApiStruct.RequestObject <> nil then' + sLineBreak +
    '    begin' + sLineBreak +
    '      if AApiStruct.RequestObject.ClassName <> ''TStringStream'' then' + sLineBreak +
    '        LvRequestString := Rest.Json.TJson.ObjectToJsonString(AApiStruct.RequestObject, [TJsonOption.joIgnoreEmptyStrings, TJsonOption.joIgnoreEmptyArrays])' + sLineBreak +
    '      else' + sLineBreak +
    '        LvRequestString := TStringStream(AApiStruct.RequestObject).DataString;' + sLineBreak +
    '    end;' + sLineBreak +
    sLineBreak +
    '    LvRequestStream := TStringStream.Create(LvRequestString, TEncoding.UTF8);' + sLineBreak +
    '    try' + sLineBreak +
    '      if (AApiStruct.Method = ''POST'') then' + sLineBreak +
    '        LvHttp.Post(AApiStruct.ApiAddress, LvRequestStream, LvResponseStream, LvHeaders)' + sLineBreak +
    '      else if (AApiStruct.Method = ''GET'') then' + sLineBreak +
    '        LvHttp.Get(AApiStruct.ApiAddress, LvResponseStream, LvHeaders)' + sLineBreak +
    sLineBreak +
    '    except on E:Exception do' + sLineBreak +
    '      begin' + sLineBreak +
    '        Result := '''';' + sLineBreak +
    '        ShowMessage(E.Message);' + sLineBreak +
    '        Exit;' + sLineBreak +
    '      end;' + sLineBreak +
    '    end;' + sLineBreak +
    sLineBreak +
    '    Result := LvResponseStream.DataString;' + sLineBreak +
    '  finally' + sLineBreak +
    '    FreeAndNil(LvHttp);' + sLineBreak +
    '    FreeAndNil(LvResponseStream);' + sLineBreak +
    '    FreeAndNil(LvRequestStream);' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    '{ TApiStructure }' + sLineBreak +
    sLineBreak +
    'constructor TApiStructure.Create;' + sLineBreak +
    'begin' + sLineBreak +
    '  FTimeOut := 30000; // Default timeout for connection and response timeout = 5 minutes!' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +

    'function TApiStructure.GetCustomHeadersCount: Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := Length(FCustomHeaders);' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'procedure TApiStructure.SetCustomHeadersCount(AValue: Integer);' + sLineBreak +
    'begin' + sLineBreak +
    '  SetLength(FCustomHeaders, AValue);' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'end.';

  //=============================
  //0: Function's name
  //1: Parentheses + Parameters
  //2: Function's body
  sFunctionHeader =
    'function %0:s%1:s: string;';

  sFunctionImplementation =
    'function TClientClass.%0:s%1:s: string;' + sLineBreak +
    '%2:s' + sLineBreak +
    //sLineBreak +
    'end;' + sLineBreak;

  //==================================
  //0: MethodName
  //1: In-path and Quesry parameters
  //2: Request Object creation
  //3: Header parameters count
  //4: Header parameters count
  sGetFunctionBody =
    'var' + sLineBreak +
    '  LvStruct: TApiStructure;' + sLineBreak +
    'begin' + sLineBreak +
    '  LvStruct := NewApiStructure(''GET'', ''%0:s'');' + sLineBreak +
    '  try' + sLineBreak +
    '    LvStruct.ApiAddress := LvStruct.ApiAddress%1:s;' + sLineBreak +
    '    %2:s' + sLineBreak +
    '    %3:s' + sLineBreak +
    '    %4:s' + sLineBreak +
    '    Result := SendToAPI(LvStruct);' + sLineBreak +
    '  finally' + sLineBreak +
    '    LvStruct.Free;' + sLineBreak +
    '  end;';


  //==================================
  //0: MethodName
  //1: In-path and Quesry parameters
  //2: Request Object creation
  //3: Header parameters count
  //4: Header parameters count
  sPostFunctionBody =
    'var' + sLineBreak +
    '  LvStruct: TApiStructure;' + sLineBreak +
    'begin' + sLineBreak +
    '  LvStruct := NewApiStructure(''POST'', ''%0:s'');' + sLineBreak +
    '  try' + sLineBreak +
    '    LvStruct.ApiAddress := LvStruct.ApiAddress%1:s;' + sLineBreak +
    '    %2:s' + sLineBreak +
    '    %3:s' + sLineBreak +
    '    %4:s' + sLineBreak +
    '    Result := SendToAPI(LvStruct);' + sLineBreak +
    '  finally' + sLineBreak +
    '    LvStruct.Free;' + sLineBreak +
    '  end;';

  //==================================
  //0: MethodName
  //1: In-path and Quesry parameters
  //2: Request Object creation
  //3: Header parameters count
  //4: Header parameters count
  sPatchFunctionBody =
    'var' + sLineBreak +
    '  LvStruct: TApiStructure;' + sLineBreak +
    'begin' + sLineBreak +
    '  LvStruct := NewApiStructure(''PATCH'', ''%0:s'');' + sLineBreak +
    '  try' + sLineBreak +
    '    LvStruct.ApiAddress := LvStruct.ApiAddress%1:s;' + sLineBreak +
    '    %2:s' + sLineBreak +
    '    %3:s' + sLineBreak +
    '    %4:s' + sLineBreak +
    '    Result := SendToAPI(LvStruct);' + sLineBreak +
    '  finally' + sLineBreak +
    '    LvStruct.Free;' + sLineBreak +
    '  end;';

  //==================================
  //0: MethodName
  //1: In-path and Quesry parameters
  //2: Request Object creation
  //3: Header parameters count
  //4: Header parameters count
  sPutFunctionBody =
    'var' + sLineBreak +
    '  LvStruct: TApiStructure;' + sLineBreak +
    'begin' + sLineBreak +
    '  LvStruct := NewApiStructure(''PUT'', ''%0:s'');' + sLineBreak +
    '  try' + sLineBreak +
    '    LvStruct.ApiAddress := LvStruct.ApiAddress%1:s;' + sLineBreak +
    '    %2:s' + sLineBreak +
    '    %3:s' + sLineBreak +
    '    %4:s' + sLineBreak +
    '    Result := SendToAPI(LvStruct);' + sLineBreak +
    '  finally' + sLineBreak +
    '    LvStruct.Free;' + sLineBreak +
    '  end;';

  //==================================
  //0: MethodName
  //1: In-path and Quesry parameters
  //2: Request Object creation
  //3: Header parameters count
  //4: Header parameters count
  sDeleteFunctionBody =
    'var' + sLineBreak +
    '  LvStruct: TApiStructure;' + sLineBreak +
    'begin' + sLineBreak +
    '  LvStruct := NewApiStructure(''DELETE'', ''%0:s'');' + sLineBreak +
    '  try' + sLineBreak +
    '    LvStruct.ApiAddress := LvStruct.ApiAddress%1:s;' + sLineBreak +
    '    %2:s' + sLineBreak +
    '    %3:s' + sLineBreak +
    '    %4:s' + sLineBreak +
    '    Result := SendToAPI(LvStruct);' + sLineBreak +
    '  finally' + sLineBreak +
    '    LvStruct.Free;' + sLineBreak +
    '  end;';

  //0: BaseURL
  //1: UserName
  //2: Password
  //3: Token or API Key
  //4: Authentication Type
  //5: GetMethods Definition
  //6: PostMethods Definition
  //7: PatchMethods Definition
  //8: PutMethods Definition
  //9: DeleteMethod_Definition
  //10: Add Paths
  //11: GetMethod Implementations
  //12: PostMethod Implementations
  //13: PatchMethod Implementations
  //14: PutMethod Implementations
  //15: DeleteMethod Implementations

  sClientClassUnit =
    'unit ClientClass;' + sLineBreak +
    sLineBreak +
    'interface' + sLineBreak +
    sLineBreak +
    'uses' + sLineBreak +
    '  System.SysUtils, System.Generics.Collections,System.StrUtils, URestClient;' + sLineBreak +
    sLineBreak +
    'const' + sLineBreak +
    '    cBaseURL = ''%0:s'';' + sLineBreak +
    '    cUsername = ''%1:s'';' + sLineBreak +
    '    cPassword = ''%2:s'';' + sLineBreak +
    '    cToken = ''%3:s'';' + sLineBreak +
    '    cAuthType = ''%4:s'';' + sLineBreak +
    sLineBreak +
    'type' + sLineBreak +
    '  TDicHelper = class helper for TDictionary<string,string>' + sLineBreak +
    '    function AddX(AKey: string; AValue: string): TDictionary<string, string>;' + sLineBreak +
    '  end;' + sLineBreak +
    sLineBreak +
    '  TClientClass = class' + sLineBreak +
    '  private' + sLineBreak +
    '    FPaths: TDictionary<string, string>;' + sLineBreak +
    '    procedure SetPaths;' + sLineBreak +
    '    function NewApiStructure(AMethodType: string; AMethodName: string): TApiStructure;' + sLineBreak +
    '    function CastByBooleanSetting(ABoolValue: Boolean; AConvertType: Byte): string;' + sLineBreak +
    '  public' + sLineBreak +
    '    constructor Create;' + sLineBreak +
    '    destructor Destroy; override;' + sLineBreak +
    '    %5:s' + //sLineBreak +
    '    %6:s' + //sLineBreak +
    '    %7:s' + //sLineBreak +
    '    %8:s' + //sLineBreak +
    '    %9:s' + //sLineBreak +
    sLineBreak +
    '    property Paths: TDictionary<string, string> read FPaths;' + sLineBreak +
    '  end;' + sLineBreak +
    sLineBreak +
    'implementation' + sLineBreak +
    sLineBreak +
    '{ TClientClass }' + sLineBreak +
    sLineBreak +
    'constructor TClientClass.Create;' + sLineBreak +
    'begin' + sLineBreak +
    '  FPaths := TDictionary<string, string>.Create;' + sLineBreak +
    '  SetPaths;' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'destructor TClientClass.Destroy;' + sLineBreak +
    'begin' + sLineBreak +
    '  FPaths.Free;' + sLineBreak +
    '  inherited;' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'function TClientClass.NewApiStructure(AMethodType: string; AMethodName: string): TApiStructure;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := TApiStructure.Create;' + sLineBreak +
    '  with Result do' + sLineBreak +
    '  begin' + sLineBreak +
    '    ApiAddress := cBaseURL + FPaths.Items[AMethodName];' + sLineBreak +
    '    AuthType := cAuthType;' + sLineBreak +
    '    Method := AMethodType;' + sLineBreak +
    '    Token := cToken;' + sLineBreak +
    '    Username := cUsername;' + sLineBreak +
    '    Password := cPassword;' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'function TClientClass.CastByBooleanSetting(ABoolValue: Boolean; AConvertType: Byte): string;' + sLineBreak +
    'begin' + sLineBreak +
    '  {0: true-false' + sLineBreak +
    '  1: 1-0' + sLineBreak +
    '  2: yes-no' + sLineBreak +
    '  3: y-n' + sLineBreak +
    '  4: on-off' + sLineBreak +
    '  }' + sLineBreak +
    '  case AConvertType of' + sLineBreak +
    '    0: IfThen(ABoolValue, QuotedStr(''true''), QuotedStr(''false''));' + sLineBreak +
    '    1: IfThen(ABoolValue, QuotedStr(''1''), QuotedStr(''0''));' + sLineBreak +
    '    2: IfThen(ABoolValue, QuotedStr(''yes''), QuotedStr(''no''));' + sLineBreak +
    '    3: IfThen(ABoolValue, QuotedStr(''y''), QuotedStr(''n''));' + sLineBreak +
    '    4: IfThen(ABoolValue, QuotedStr(''on''), QuotedStr(''off''));' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'procedure TClientClass.SetPaths;' + sLineBreak +
    'begin' + sLineBreak +
    '  FPaths' + sLineBreak +
    '%10:s' + sLineBreak +
    'end;' + sLineBreak +

    '%11:s' + //sLineBreak +
    '%12:s' + //sLineBreak +
    '%13:s' + //sLineBreak +
    '%14:s' + //sLineBreak +
    '%15:s' + //sLineBreak +

    '{TDicHelper}' + sLineBreak +
    sLineBreak +
    'function TDicHelper.AddX(AKey: string; AValue: string): TDictionary<string,string>;' + sLineBreak +
    'begin' + sLineBreak +
    '  Self.Add(AKey, AValue);' + sLineBreak +
    '  Result := Self;' + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'end.';

    // 0: Button Name
    // 1: Method's calling line
    sButtonOnClickEvent =
    'procedure TFrm_Main.%0:sClick(Sender: TObject);' + sLineBreak +
    'var' + sLineBreak +
    '  LvClient: TClientClass;' + sLineBreak +
    '  LvResponseStr: string;' + sLineBreak +
    'begin' + sLineBreak +
    '  LvClient := TClientClass.Create;' + sLineBreak +
    '  try' + sLineBreak +
    '    LvResponseStr := LvClient.%1:s;' + sLineBreak +
    '    FMemo.Lines.Clear;' + sLineBreak +
    '    FMemo.Lines.Add(LvResponseStr);' + sLineBreak +
    '    {' + sLineBreak +
    '    ...' + sLineBreak +
    '    Do something with the result(LvResponseStr), cast to a new object, parse the Json, etc.' + sLineBreak +
    '    ...' + sLineBreak +
    '    }' + sLineBreak +
    '  finally' + sLineBreak +
    '    LvClient.Free;' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak;

implementation

end.
