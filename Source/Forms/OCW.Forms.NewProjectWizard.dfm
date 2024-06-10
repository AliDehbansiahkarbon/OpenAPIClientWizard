object Frm_OCWNewProject: TFrm_OCWNewProject
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsToolWindow
  Caption = 'OpenAPI Client Project Wizard'
  ClientHeight = 561
  ClientWidth = 511
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  TextHeight = 15
  object pnl_Main: TPanel
    Left = 0
    Top = 0
    Width = 511
    Height = 561
    Align = alClient
    TabOrder = 0
    DesignSize = (
      511
      561)
    object lbl_Validation: TLabel
      Left = 15
      Top = 532
      Width = 199
      Height = 21
      Anchors = [akLeft, akBottom]
      Caption = 'Json structure is not valid!'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
      Visible = False
      ExplicitTop = 661
    end
    object btnAbout: TSpeedButton
      Left = 444
      Top = 12
      Width = 41
      Height = 22
      Anchors = [akTop, akRight]
      Caption = 'About'
      OnClick = btnAboutClick
      ExplicitLeft = 446
    end
    object lbl_Title: TLabel
      Left = 15
      Top = 17
      Width = 386
      Height = 15
      Caption = 
        'Select specification file(YAML or JSON) or the online documentat' +
        'ion URL.'
    end
    object ActivityMonitor: TActivityIndicator
      Left = 279
      Top = 532
      Anchors = [akRight, akBottom]
      IndicatorSize = aisSmall
    end
    object Btn_Cancel: TButton
      Left = 310
      Top = 530
      Width = 75
      Height = 26
      Anchors = [akRight, akBottom]
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
    object Btn_Create: TButton
      Left = 391
      Top = 530
      Width = 118
      Height = 26
      Anchors = [akRight, akBottom]
      Caption = 'Create Client Project'
      ModalResult = 1
      TabOrder = 2
      OnClick = Btn_CreateClick
    end
    object grpAuthorization: TGroupBox
      Left = 14
      Top = 229
      Width = 479
      Height = 168
      Caption = 'Authorization'
      TabOrder = 3
      object lblAuth: TLabel
        Left = 17
        Top = 34
        Width = 102
        Height = 15
        Caption = 'Authorization Type:'
      end
      object lblUsername: TLabel
        Left = 25
        Top = 74
        Width = 56
        Height = 15
        Caption = 'Username:'
        Enabled = False
      end
      object lblPassword: TLabel
        Left = 28
        Top = 102
        Width = 53
        Height = 15
        Caption = 'Password:'
        Enabled = False
      end
      object lblBearerToken: TLabel
        Left = 11
        Top = 130
        Width = 70
        Height = 15
        Caption = 'Bearer Token:'
        Enabled = False
      end
      object cbbAuth: TComboBox
        Left = 125
        Top = 31
        Width = 121
        Height = 23
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 0
        Text = 'No Auth'
        OnChange = cbbAuthChange
        Items.Strings = (
          'No Auth'
          'Basic'
          'Bearer Token')
      end
      object edt_Username: TEdit
        Left = 84
        Top = 71
        Width = 381
        Height = 23
        Enabled = False
        TabOrder = 1
      end
      object edt_Password: TEdit
        Left = 84
        Top = 99
        Width = 381
        Height = 23
        Enabled = False
        TabOrder = 2
      end
      object edt_BearerToken: TEdit
        Left = 84
        Top = 127
        Width = 381
        Height = 23
        Enabled = False
        TabOrder = 3
      end
    end
    object grpDoc: TGroupBox
      Left = 14
      Top = 38
      Width = 479
      Height = 185
      TabOrder = 4
      object Label4: TLabel
        Left = 77
        Top = 18
        Width = 84
        Height = 15
        Caption = 'Format/Version:'
      end
      object Label6: TLabel
        Left = 9
        Top = 157
        Width = 51
        Height = 15
        Caption = 'Base URL:'
      end
      object edt_DocURL: TEdit
        Left = 40
        Top = 118
        Width = 425
        Height = 23
        TabOrder = 3
        TextHint = 'https://learn.openapis.org/examples/tictactoe.yaml'
      end
      object edt_SpecFile: TEdit
        Left = 40
        Top = 67
        Width = 425
        Height = 23
        TabOrder = 1
        OnDblClick = edt_SpecFileDblClick
      end
      object rb_API_URL: TRadioButton
        Left = 16
        Top = 96
        Width = 95
        Height = 17
        Caption = 'API Doc URL'
        TabOrder = 2
      end
      object rb_SelectFile: TRadioButton
        Left = 13
        Top = 44
        Width = 79
        Height = 17
        Caption = 'Select file'
        Checked = True
        TabOrder = 0
        TabStop = True
      end
      object cbb_Version: TComboBox
        Left = 169
        Top = 15
        Width = 192
        Height = 23
        Style = csDropDownList
        TabOrder = 4
        Items.Strings = (
          'Swagger(Json) - v2.2.x'
          'OpenAPI(Json) - v3.x'
          'OpenAPI(Yaml) - v3.x'
          'Postman Collection(Json) - v2.1')
      end
      object edt_BaseURL: TEdit
        Left = 65
        Top = 154
        Width = 400
        Height = 23
        TabOrder = 5
      end
      object Btn_OpenFile: TButton
        Left = 439
        Top = 69
        Width = 24
        Height = 19
        Caption = '...'
        TabOrder = 6
        OnClick = Btn_OpenFileClick
      end
    end
    object grpOtherOptions: TGroupBox
      Left = 14
      Top = 403
      Width = 479
      Height = 98
      Caption = 'Other Options'
      TabOrder = 5
      object Label2: TLabel
        Left = 20
        Top = 73
        Width = 161
        Height = 15
        Caption = 'Set Boolean Values in query as:'
      end
      object lbl_prefix: TLabel
        Left = 20
        Top = 48
        Width = 213
        Height = 15
        Caption = 'Add Mehtod type to function names as: '
        WordWrap = True
      end
      object cbb_BooleanStringForm: TComboBox
        Left = 186
        Top = 70
        Width = 81
        Height = 23
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 0
        Text = 'true/false'
        Items.Strings = (
          'true/false'
          '1/0'
          'yes/no'
          'y/n'
          'on/off')
      end
      object chk_AddToProjectGroup: TCheckBox
        Left = 20
        Top = 25
        Width = 197
        Height = 17
        Caption = 'Add to the existing projectGroup'
        TabOrder = 1
      end
      object cbb_Prefix: TComboBox
        Left = 236
        Top = 44
        Width = 103
        Height = 23
        Style = csDropDownList
        ItemIndex = 1
        TabOrder = 2
        Text = 'Prefix'
        Items.Strings = (
          'Suffix'
          'Prefix'
          'Original names')
      end
    end
  end
  object FOD: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = []
    Left = 424
    Top = 80
  end
end
