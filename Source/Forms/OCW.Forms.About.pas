unit OCW.Forms.About;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, DockForm, Winapi.ShellAPI,
  Vcl.Imaging.pngimage,
  OCW.Util.Setting;

type
  TFrm_About = class(TForm)
    Img_Logo: TImage;
    lbl_Name: TLabel;
    lbl_Version: TLabel;
    lbl_Description: TLabel;
    lbl_Github: TLabel;
    LinkLabel_Github: TLinkLabel;
    lbl_ShortVideo: TLabel;
    LinkLabel_ShortVideo: TLinkLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure LinkLabel_GithubLinkClick(Sender: TObject; const Link: string; LinkType: TSysLinkType);
  private
    procedure LoadLogo;
  public
    { Public declarations }
  end;

var
  Frm_About: TFrm_About;

implementation

{$R *.dfm}

procedure TFrm_About.FormCreate(Sender: TObject);
begin
  LoadLogo;
  lbl_Version.Caption := CVersion;
end;

procedure TFrm_About.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Ord(Key) = 27 then
    Close;
end;

procedure TFrm_About.LinkLabel_GithubLinkClick(Sender: TObject; const Link: string; LinkType: TSysLinkType);
begin
  ShellExecute(0, 'Open', PChar(Link), nil, nil, SW_SHOWNORMAL);
end;

procedure TFrm_About.LoadLogo;
var
  LvResStream: TResourceStream;
{$IF CompilerVersion < 32.0}
  LvPngImage: TPngImage;
  LvBmp: TBitmap;
{$ENDIF}
begin
  LvResStream := TResourceStream.Create(HInstance, 'OCWLogo', RT_RCDATA);
  try
  {$IF CompilerVersion < 32.0}
    LvPngImage := TPngImage.Create;
    try
      LvPngImage.LoadFromStream(LvResStream);
      LvBmp := TBitmap.Create;
      try
        LvPngImage.Transparent := False;
        LvPngImage.AssignTo(LvBmp);
        Img_Logo.Picture.Assign(LvBmp);
      finally
        LvBmp.Free;
      end;
    finally
      LvPngImage.Free;
    end;
  {$ELSE}
    Img_Logo.Picture.LoadFromStream(LvResStream);
  {$IFEND}
  finally
    LvResStream.Free;
  end;
end;

end.
