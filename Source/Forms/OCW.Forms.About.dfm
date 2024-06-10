object Frm_About: TFrm_About
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'About'
  ClientHeight = 179
  ClientWidth = 356
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  TextHeight = 15
  object Img_Logo: TImage
    Left = 8
    Top = 8
    Width = 81
    Height = 65
    Proportional = True
    Stretch = True
  end
  object lbl_Name: TLabel
    Left = 93
    Top = 27
    Width = 176
    Height = 23
    Caption = 'OpenAPIClientWizard'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbl_Version: TLabel
    Left = 273
    Top = 33
    Width = 56
    Height = 15
    Caption = 'lbl_Version'
  end
  object lbl_Description: TLabel
    Left = 48
    Top = 81
    Width = 259
    Height = 48
    AutoSize = False
    Caption = 
      'An IDE plug-in(Project wizard) to generate OpenAPI cleint projec' +
      't automatically  by Ali Dehbansiahkarbon.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    WordWrap = True
  end
  object lbl_Github: TLabel
    Left = 48
    Top = 135
    Width = 43
    Height = 15
    Caption = 'GitHub:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lbl_ShortVideo: TLabel
    Left = 45
    Top = 156
    Width = 68
    Height = 15
    Caption = 'Short video:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LinkLabel_Github: TLinkLabel
    Left = 97
    Top = 133
    Width = 206
    Height = 21
    Caption = 
      '<a href="https://github.com/AliDehbansiahkarbon/ChatGPTWizard">h' +
      'ttps://github.com/ChatGPTWizard</a>'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnLinkClick = LinkLabel_GithubLinkClick
  end
  object LinkLabel_ShortVideo: TLinkLabel
    Left = 119
    Top = 151
    Width = 186
    Height = 21
    Caption = 
      '<a href="https://www.youtube.com/watch?v=jHFmmmrk3BU">https://yo' +
      'utu.be/jHFmmmrk3BU</a>'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnLinkClick = LinkLabel_GithubLinkClick
  end
end
