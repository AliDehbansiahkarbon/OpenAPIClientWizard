object Frm_OCWNewProject: TFrm_OCWNewProject
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsToolWindow
  Caption = 'OpenAPI Client Project Wizard'
  ClientHeight = 412
  ClientWidth = 504
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
    Width = 504
    Height = 412
    Align = alClient
    TabOrder = 0
    DesignSize = (
      504
      412)
    object lbl_Validation: TLabel
      Left = 15
      Top = 383
      Width = 164
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Json structure is not valid!'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
      Visible = False
    end
    object btnAbout: TSpeedButton
      Left = 437
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
      Left = 272
      Top = 383
      Anchors = [akRight, akBottom]
      IndicatorSize = aisSmall
    end
    object Btn_Cancel: TButton
      Left = 303
      Top = 381
      Width = 75
      Height = 26
      Anchors = [akRight, akBottom]
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
    object Btn_Create: TButton
      Left = 384
      Top = 381
      Width = 118
      Height = 26
      Anchors = [akRight, akBottom]
      Caption = 'Create Client Project'
      ModalResult = 1
      TabOrder = 2
      OnClick = Btn_CreateClick
    end
    object grpDoc: TGroupBox
      Left = 14
      Top = 38
      Width = 479
      Height = 219
      TabOrder = 3
      object Label4: TLabel
        Left = 77
        Top = 18
        Width = 84
        Height = 15
        Caption = 'Format/Version:'
      end
      object edt_DocURL: TEdit
        Left = 26
        Top = 125
        Width = 423
        Height = 23
        TabOrder = 3
        TextHint = 'https://learn.openapis.org/examples/tictactoe.yaml'
      end
      object edt_SpecFile: TEdit
        Left = 26
        Top = 67
        Width = 425
        Height = 23
        TabOrder = 1
        OnDblClick = edt_SpecFileDblClick
      end
      object rb_Download_URL: TRadioButton
        Left = 11
        Top = 98
        Width = 169
        Height = 17
        Caption = 'API Doc URL to download:'
        TabOrder = 2
      end
      object rb_SelectFile: TRadioButton
        Left = 11
        Top = 44
        Width = 150
        Height = 17
        Caption = 'Select file(Offline Mode):'
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
        Left = 26
        Top = 186
        Width = 423
        Height = 23
        TabOrder = 5
      end
      object Btn_OpenFile: TButton
        Left = 425
        Top = 69
        Width = 24
        Height = 19
        Caption = '...'
        TabOrder = 6
        OnClick = Btn_OpenFileClick
      end
      object rb_GetBaseURL: TRadioButton
        Left = 11
        Top = 163
        Width = 124
        Height = 17
        Caption = 'Base URL(Rest GET):'
        TabOrder = 7
      end
    end
    object grpOtherOptions: TGroupBox
      Left = 15
      Top = 263
      Width = 479
      Height = 98
      Caption = 'Other Options'
      TabOrder = 4
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
