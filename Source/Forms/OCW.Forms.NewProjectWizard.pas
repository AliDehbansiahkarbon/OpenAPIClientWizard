{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit OCW.Forms.NewProjectWizard;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.Generics.Collections,
  System.JSON, Vcl.WinXCtrls, Vcl.Buttons, DockForm, Neslib.Yaml, System.Rtti,
  System.Net.HttpClientComponent, System.IOUtils,

  OCW.Util.Core,
  OCW.Util.Rest,
  OCW.Util.Setting,
  OCW.Forms.About,
  OCW.Util.PostmanHelper, Vcl.ExtCtrls;

type
  TFrm_OCWNewProject = class(TForm)
    Btn_Create: TButton;
    Btn_Cancel: TButton;
    ActivityMonitor: TActivityIndicator;
    grpDoc: TGroupBox;
    edt_DocURL: TEdit;
    edt_SpecFile: TEdit;
    rb_Download_URL: TRadioButton;
    rb_SelectFile: TRadioButton;
    lbl_Title: TLabel;
    Label4: TLabel;
    cbb_Version: TComboBox;
    grpOtherOptions: TGroupBox;
    Label2: TLabel;
    cbb_BooleanStringForm: TComboBox;
    btnAbout: TSpeedButton;
    lbl_Validation: TLabel;
    chk_AddToProjectGroup: TCheckBox;
    edt_BaseURL: TEdit;
    Btn_OpenFile: TButton;
    FOD: TFileOpenDialog;
    cbb_Prefix: TComboBox;
    lbl_prefix: TLabel;
    pnl_Main: TPanel;
    rb_GetBaseURL: TRadioButton;
    procedure Btn_CreateClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnAboutClick(Sender: TObject);
    procedure Btn_OpenFileClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure edt_SpecFileDblClick(Sender: TObject);
  private
    FExtractedSpec: TFinalParsingObject;
    FLastPath: string;
    function GetAddToProjectGroup: boolean;
    function InputsValidation: Boolean;
    function DownloadFileFromURL(const AURL: string; ATempFileName: string): Boolean;
    { Private declarations }
  public
    property AddToProjectGroup: boolean read GetAddToProjectGroup;
    property ExtractedSpecification: TFinalParsingObject read FExtractedSpec;
  end;

var
  Frm_OCWNewProject: TFrm_OCWNewProject;

implementation
{$IFDEF CODESITE}
uses
  CodeSiteLogging;
{$ENDIF}

{$R *.dfm}

{ TFrm_OCWNewProject }

procedure TFrm_OCWNewProject.Btn_CreateClick(Sender: TObject);
var
  LvIsValid: Boolean;
  LvAPIStruct: TApiStructure;
  LvTempFileName: string;
begin
  LvIsValid := False;
  MarkUsed(LvIsValid);
  lbl_Validation.Visible := False;
  ActivityMonitor.Animate := True;

  if not InputsValidation then
  begin
    ActivityMonitor.Animate := False;
    lbl_Validation.Caption := 'Fill the necessary fields please!';
    lbl_Validation.Visible := True;
    Self.ModalResult := mrNone;
    Exit;
  end;

  try
    FExtractedSpec.PrefixType := cbb_Prefix.ItemIndex;
    if rb_SelectFile.Checked then
      LvIsValid := TValidator.IsValid(edt_SpecFile.Text, TActiveType(cbb_Version.ItemIndex), FExtractedSpec)
    else if rb_Download_URL.Checked then
    begin
      try
        LvTempFileName := TPath.Combine(TPath.GetTempPath, TPath.GetFileName(Edt_DocURL.Text));
        if DownloadFileFromURL(Edt_DocURL.Text, LvTempFileName) then
          LvIsValid := TValidator.IsValid(LvTempFileName, TActiveType(cbb_Version.ItemIndex), FExtractedSpec)
        else
          ShowMessage('Failed to download the file.');
      except on E: Exception do
        ShowMessage('Failed to create temp file:' + E.Message);
      end;
    end
    else
    begin
      LvAPIStruct := TApiStructure.Create;
      try
        with LvAPIStruct do
        begin
          ApiAddress := edt_BaseURL.Text;
          AuthType := 'basic';
          Method := 'GET';
          Token := EmptyStr;
          Username := EmptyStr;
          Password := EmptyStr;
          SpecType := TActiveType(cbb_Version.ItemIndex);
        end;

        LvIsValid := TValidator.IsValid(LvAPIStruct, FExtractedSpec);
      finally
        LvAPIStruct.Free;
      end;
    end;

    if not LvIsValid then
    begin
      case cbb_Version.ItemIndex of
        0: //Swagger(Json) - v2.2.x
        begin
          lbl_Validation.Caption := 'The Swagger Json structure is not valid!';
          lbl_Validation.Visible := True;
          Self.ModalResult := mrNone;
        end;

        1: //OpenAPI(Json) - v3.x
        begin
          lbl_Validation.Caption := 'The OpenAPI Json structure is not valid!';
          lbl_Validation.Visible := True;
          Self.ModalResult := mrNone;
        end;

        2: //OpenAPI(Yaml) - v3.x
        begin
          lbl_Validation.Caption := 'The OpenAPI Yaml structure is not valid!';
          lbl_Validation.Visible := True;
          Self.ModalResult := mrNone;
        end;

        3: //Postman Collection(Json) - v2.1
        begin
          lbl_Validation.Caption := 'The PostmanCollection structure is not valid!';
          lbl_Validation.Visible := True;
          Self.ModalResult := mrNone;
        end;
      end;
    end
    else
    begin
      with TSingletonSettingObj.Instance do
      begin
        BaseURL := edt_BaseURL.Text;
        BearerToken := EmptyStr;
        UserName := EmptyStr;
        Password := EmptyStr;
        Version := cbb_Version.ItemIndex;
        AuthType := 0;
        BooleanStringForm := cbb_BooleanStringForm.ItemIndex;
      end;

      Self.ModalResult := mrOk;
    end;
  finally
    ActivityMonitor.Animate := False;
  end;
end;

procedure TFrm_OCWNewProject.Btn_OpenFileClick(Sender: TObject);
begin
  try
    if not string.IsNullOrEmpty(edt_SpecFile.Text) then
      FOD.DefaultFolder := ExtractFileDir(edt_SpecFile.Text);
  except
  end;

  FOD.FileTypes.Clear;
  with FOD.FileTypes.Add do
  begin
    case cbb_Version.ItemIndex of
      0:
      begin
        DisplayName := 'Swagger File';
        FileMask := '*.json';
      end;
      1:
      begin
        DisplayName := 'OpenAPI Json File';
        FileMask := '*.json';
      end;
      2:
      begin
        DisplayName := 'OpenAPI Yaml File';
        FileMask := '*.Yaml';
      end;
      3:
      begin
        DisplayName := 'Postman Collection File';
        FileMask := '*.json';
      end;
    end;
  end;

  if not FLastPath.IsEmpty then
    FOD.DefaultFolder := FLastPath;

  if FOD.Execute then
  begin
    edt_SpecFile.Text := FOD.FileName;
    FLastPath := ExtractFilePath(FOD.FileName);
  end;
end;

procedure TFrm_OCWNewProject.edt_SpecFileDblClick(Sender: TObject);
begin
  Btn_OpenFile.Click;
end;

procedure TFrm_OCWNewProject.FormCreate(Sender: TObject);
begin
  FExtractedSpec := TFinalParsingObject.Instance;
end;

procedure TFrm_OCWNewProject.FormDestroy(Sender: TObject);
begin
  try
    if Assigned(FExtractedSpec.Instance) then
      FExtractedSpec.Instance.Free;
  except
  end;
end;

procedure TFrm_OCWNewProject.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Ord(Key) = 27 then
    Btn_Cancel.Click;
end;

function TFrm_OCWNewProject.GetAddToProjectGroup: boolean;
begin
  Result := chk_AddToProjectGroup.Checked;
end;

procedure TFrm_OCWNewProject.btnAboutClick(Sender: TObject);
var
  LvAboutForm: TFrm_About;
begin
  if Sender.ClassName.Equals('TSpeedButton') then
  begin
    LvAboutForm := TFrm_About.Create(nil);
    begin
      TSingletonSettingObj.Instance.RegisterFormClassForTheming(TFrm_About, LvAboutForm);
      LvAboutForm.ShowModal;
      LvAboutForm.Free;
    end;
  end;
end;

function TFrm_OCWNewProject.InputsValidation: Boolean;
begin
  Result := False;

  if cbb_Version.ItemIndex < 0 then
  begin
    ShowMessage('The OpenAPI specefication file must be provided.');
    cbb_Version.SelectAll;
    cbb_Version.DroppedDown := True;
    Exit;
  end;

  if rb_SelectFile.Checked then
  begin
    if Trim(edt_SpecFile.Text).Equals(EmptyStr) then
    begin
      ShowMessage('The OpenAPI specefication file must be provided.');
      edt_SpecFile.SetFocus;
      Exit;
    end;

    if not FileExists(edt_SpecFile.Text) then
    begin
      ShowMessage('The OpenAPI specefication file doesn''t exist.');
      edt_SpecFile.SetFocus;
      Exit;
    end;
  end
  else if Trim(edt_DocURL.Text).Equals(EmptyStr) then
  begin
    ShowMessage('OpenAPI specefication URL must be provided.');
    if edt_DocURL.CanFocus then
      edt_DocURL.SetFocus;
    Exit;


    if Trim(edt_BaseURL.Text).Equals(EmptyStr) then
    begin
      ShowMessage('The Base URL must be provided.');
      if edt_BaseURL.CanFocus then
        edt_BaseURL.SetFocus;
      Exit;
    end;

    if cbb_BooleanStringForm.ItemIndex = -1 then
    begin
      ShowMessage('Select one approche to deal with boolean values.');
      if cbb_BooleanStringForm.CanFocus then
        cbb_BooleanStringForm.SetFocus;

      Exit;
    end;
  end;

  Result := True;
end;

function TFrm_OCWNewProject.DownloadFileFromURL(const AURL: string; ATempFileName: string): Boolean;
var
  LvHttpClient: TNetHTTPClient;
  LvFileStream: TFileStream;
begin
  Result := False;
  MarkUsed(Result);
  LvHttpClient := TNetHTTPClient.Create(nil);
  try
    try
      LvFileStream := TFileStream.Create(ATempFileName, fmCreate);
      try
        LvHttpClient.Get(AURL, LvFileStream);
        Result := True;
      finally
        LvFileStream.Free;
      end;
    except
      on E: Exception do
      begin
        Result := False;
        MarkUsed(Result);
        raise Exception.Create('Error downloading file: ' + E.Message);
      end;
    end;
  finally
    LvHttpClient.Free;
  end;
end;

end.
