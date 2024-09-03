unit OCW.Util.PostmanHelper;

interface

uses
  System.Json, System.SysUtils, System.Generics.Collections,
  OCW.Util.Consts,
  OCW.Util.Core
  {$IFDEF CODESITE}, CodeSiteLogging{$ENDIF};

type
  TPostmanAuth = class
  private
    FType: string;
    FBearer: TJSONValue;
  public
    property AuthType: string read FType write FType;
    property Bearer: TJSONValue read FBearer write FBearer;
  end;

  TPostmanHeader = class
  private
    FKey: string;
    FValue: string;
    FType: string;
    FDisabled: Boolean;
  public
    property Key: string read FKey write FKey;
    property Value: string read FValue write FValue;
    property DataType: string read FType write FType;
    property Disabled: Boolean read FDisabled write FDisabled;
  end;

  TPostmanUrl = class
  private
    FRaw: string;
    FProtocol: string;
    FHost: TJSONValue;
    FPath: TJSONValue;
    FQuery: TJSONValue; // Add Query property
    FVariable: TJSONValue; // Add Variable property
  public
    property Raw: string read FRaw write FRaw;
    property Protocol: string read FProtocol write FProtocol;
    property Host: TJSONValue read FHost write FHost;
    property Path: TJSONValue read FPath write FPath;
    property Query: TJSONValue read FQuery write FQuery; // Add Query property
    property Variable: TJSONValue read FVariable write FVariable; // Add Variable property
  end;

  TPostmanBodyOptions = class
  private
    FRawOptions: TJSONValue;
  public
    property RawOptions: TJSONValue read FRawOptions write FRawOptions;
  end;

  TPostmanBody = class
  private
    FMode: string;
    FRaw: string;
    FOptions: TPostmanBodyOptions;
  public
    constructor Create;
    destructor Destroy; override;
    property Mode: string read FMode write FMode;
    property Raw: string read FRaw write FRaw;
    property Options: TPostmanBodyOptions read FOptions write FOptions;
  end;

  TPostmanRequest = class
  private
    FAuth: TPostmanAuth;
    FMethod: string;
    FHeader: TJSONValue;
    FBody: TPostmanBody;
    FUrl: TPostmanUrl;
  public
    constructor Create;
    destructor Destroy; override;
    property Auth: TPostmanAuth read FAuth write FAuth;
    property Method: string read FMethod write FMethod;
    property Header: TJSONValue read FHeader write FHeader;
    property Body: TPostmanBody read FBody write FBody;
    property Url: TPostmanUrl read FUrl write FUrl;
  end;

  TProtocolProfileBehavior = class
  private
    FDisableBodyPruning: Boolean;
  public
    property DisableBodyPruning: Boolean read FDisableBodyPruning write FDisableBodyPruning;
  end;

  TPostmanItem = class
  private
    FName: string;
    FRequest: TPostmanRequest;
    FResponse: TJSONValue;
    FProtocolProfileBehavior: TProtocolProfileBehavior;
  public
    constructor Create;
    destructor Destroy; override;
    property Name: string read FName write FName;
    property Request: TPostmanRequest read FRequest write FRequest;
    property Response: TJSONValue read FResponse write FResponse;
    property ProtocolProfileBehavior: TProtocolProfileBehavior read FProtocolProfileBehavior write FProtocolProfileBehavior;
  end;

  TPostmanVariable = class
  private
    FKey: string;
    FValue: string;
    FType: string;
  public
    property Key: string read FKey write FKey;
    property Value: string read FValue write FValue;
    property &Type: string read FType write FType;
  end;

  TPostmanCollection = class
  private
    FInfo: TJSONValue;
    FItems: TObjectList<TPostmanItem>;
    FVariables: TJSONValue; // Add Variables property
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromJson(AJsonValue: TJSONObject);
    procedure LoadItem(AItemsJsonObj: TJSONArray);
    procedure LoadValues(AItem: TPostmanItem; AItemsJsonObj: TJSONObject);

    property Info: TJSONValue read FInfo write FInfo;
    property Items: TObjectList<TPostmanItem> read FItems write FItems;
    property Variables: TJSONValue read FVariables write FVariables; // Add Variables property
  end;

implementation

{ TRequest }

constructor TPostmanRequest.Create;
begin
  FAuth := TPostmanAuth.Create;
  FBody := TPostmanBody.Create;
  FUrl := TPostmanUrl.Create;
end;

destructor TPostmanRequest.Destroy;
begin
  FAuth.Free;
  FBody.Free;
  FUrl.Free;
  inherited;
end;

{ TItem }

constructor TPostmanItem.Create;
begin
  FRequest := nil;
  FProtocolProfileBehavior := TProtocolProfileBehavior.Create;
end;

destructor TPostmanItem.Destroy;
begin
  if Assigned(FRequest) then
    FRequest.Free;

  FProtocolProfileBehavior.Free;
  inherited;
end;

{ TCollection }

constructor TPostmanCollection.Create;
begin
  FItems := TObjectList<TPostmanItem>.Create(True);
end;

destructor TPostmanCollection.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TPostmanCollection.LoadFromJson(AJsonValue: TJSONObject);
var
  LvItem: TPostmanItem;
  LvItemsArray: TJSONArray;
  LvJsonObj: TJSONObject;
  I: Integer;
begin
  if AJsonValue is TJSONObject then
  begin
    try
      LvJsonObj := AJsonValue as TJSONObject;

      // Load info property
      if Assigned(LvJsonObj.FindValue(cPostman_Info)) then
        FInfo := LvJsonObj.FindValue(cPostman_Info);

      // Load variables property
      if Assigned(LvJsonObj.FindValue(cPostman_Variables)) then
        FVariables := LvJsonObj.FindValue(cPostman_Variables);

      // Load items array
      if Assigned(LvJsonObj.FindValue(cPostman_Item)) then
      begin
        LvItemsArray := LvJsonObj.FindValue(cPostman_Item) as TJSONArray;
        for I := 0 to Pred(lvItemsArray.Count) do
        begin
          if LvItemsArray.Items[I] is TJSONObject  then
          begin
            LvItem := TPostmanItem.Create;
            LoadValues(LvItem, (LvItemsArray.Items[I] as TJSONObject))
          end
          else if LvItemsArray.Items[I] is TJSONArray  then
            LoadItem(LvItemsArray.Items[I] as TJSONArray);
        end;
      end;
    except on E: Exception do
      raise Exception.Create('Invalid JSON format: ' + E.Message);
    end;

  end
  else
    raise Exception.Create('Invalid JSON format');
end;

procedure TPostmanCollection.LoadItem(AItemsJsonObj: TJSONArray);
var
  I: Integer;
  LvItem: TPostmanItem;
begin
  if Assigned(AItemsJsonObj) then
  begin
    for I := 0 to Pred(AItemsJsonObj.Count) do
    begin
      if AItemsJsonObj.Items[I] is TJSONObject then
      begin
        LvItem := TPostmanItem.Create;
        LoadValues(LvItem, AItemsJsonObj.Items[I] as TJSONObject);
        FItems.Add(LvItem);
      end
      else if AItemsJsonObj.Items[I] is TJSONArray then
        LoadItem(AItemsJsonObj.Items[I] as TJSONArray);
    end;
  end;
end;

procedure TPostmanCollection.LoadValues(AItem: TPostmanItem; AItemsJsonObj: TJSONObject);
var
  LvUrlJsonObject: TJSONObject;
  LvRequestJsonObject: TJSONObject;
  LvItem: TPostmanItem;
begin
  if Assigned(AItemsJsonObj) then
  begin
    if not Assigned(AItemsJsonObj.FindValue(cPostman_Request)) then
      Exit;

    // Load item properties
    if Assigned(AItemsJsonObj.FindValue(cPostman_Name)) then
      AItem.Name := StringReplace(AItemsJsonObj.FindValue(cPostman_Name).Value.Trim, ' ', '_', [rfReplaceAll, rfIgnoreCase]);

    // Load request
    if Assigned(AItemsJsonObj.FindValue(cPostman_Request)) then
    begin
      AItem.Request := TPostmanRequest.Create;

      LvRequestJsonObject := AItemsJsonObj.FindValue(cPostman_Request) as TJSONObject;

      AItem.Request.Method := LvRequestJsonObject.GetFindValue(cPostman_Method);

      // Load request authentication
      if Assigned(LvRequestJsonObject.FindValue(cPostman_Auth)) then
      begin
        if Assigned(LvRequestJsonObject.GetValue(cPostman_Auth).FindValue(cPostman_Type)) then
          AItem.Request.Auth.AuthType := LvRequestJsonObject.GetValue(cPostman_Auth).FindValue(cPostman_Type).Value;

        if Assigned(LvRequestJsonObject.FindValue(cPostman_Auth).FindValue(cPostman_Bearer)) then
          AItem.Request.Auth.Bearer := LvRequestJsonObject.GetValue(cPostman_Auth).FindValue(cPostman_Bearer);
      end;

      // Load request URL
      if Assigned(LvRequestJsonObject.FindValue(cPostman_Url)) then
      begin
        LvUrlJsonObject := LvRequestJsonObject.FindValue(cPostman_Url) as TJSONObject;

        AItem.Request.Url.Raw := LvUrlJsonObject.GetFindValue(cPostman_Raw);
        AItem.Request.Url.Protocol := LvUrlJsonObject.GetFindValue(cPostman_Protocol);

        if Assigned(LvUrlJsonObject.FindValue(cPostman_Host)) then
          AItem.Request.Url.Host := LvUrlJsonObject.GetValue(cPostman_Host);

        if Assigned(LvUrlJsonObject.FindValue(cPostman_Path)) then
          AItem.Request.Url.Path := LvUrlJsonObject.GetValue(cPostman_Path);

        if Assigned(LvUrlJsonObject.FindValue(cPostman_Query)) then
          AItem.Request.Url.Query := LvUrlJsonObject.GetValue(cPostman_Query); // Load Query

        if Assigned(LvUrlJsonObject.FindValue(cPostman_variable)) then
          AItem.Request.Url.Variable := LvUrlJsonObject.GetValue(cPostman_variable); // Load Variable
      end;

      // Load request headers
      if Assigned(LvRequestJsonObject.FindValue(cPostman_Header)) then
        AItem.Request.Header := LvRequestJsonObject.GetValue(cPostman_Header);


      // Load request body
      if Assigned(LvRequestJsonObject.FindValue(cPostman_Body)) then
      begin
        if Assigned(LvRequestJsonObject.FindValue(cPostman_Body).FindValue(cPostman_mode)) then
          AItem.Request.Body.Mode := LvRequestJsonObject.FindValue(cPostman_Body).GetValue<string>(cPostman_mode);

        if Assigned(LvRequestJsonObject.FindValue(cPostman_Body).FindValue(cPostman_Raw)) then
          AItem.Request.Body.Raw := LvRequestJsonObject.FindValue(cPostman_Body).GetValue<string>(cPostman_Raw);

        if Assigned(LvRequestJsonObject.FindValue(cPostman_Body).FindValue(cPostman_Options)) then
        begin
          if Assigned(LvRequestJsonObject.FindValue(cPostman_Body).FindValue(cPostman_Options).FindValue(cPostman_Raw)) then
            AItem.Request.Body.Options.RawOptions := LvRequestJsonObject.FindValue(cPostman_Body).FindValue(cPostman_Options).FindValue(cPostman_Raw);
        end;
      end;
    end;

    // Load response
    if Assigned(AItemsJsonObj.FindValue(cPostman_Response)) then
      AItem.Response := AItemsJsonObj.GetValue(cPostman_Response);


    // Load protocol profile behavior
    if Assigned(AItemsJsonObj.FindValue(cPostman_ProtocolProfileBehavior)) then
    begin
      if Assigned(AItemsJsonObj.GetValue(cPostman_ProtocolProfileBehavior).FindValue(cPostman_DisableBodyPruning)) then
        AItem.ProtocolProfileBehavior.DisableBodyPruning := TJSONObject(AItemsJsonObj.GetValue(cPostman_ProtocolProfileBehavior)).GetValue<Boolean>(cPostman_DisableBodyPruning);
    end;

    // Load child items
    if Assigned(AItemsJsonObj.FindValue(cPostman_Item)) then
    begin
      if AItemsJsonObj.GetValue(cPostman_Item) is TJSONObject then
      begin
        LvItem := TPostmanItem.Create;
        LoadValues(LvItem, AItemsJsonObj.GetValue(cPostman_Item) as TJSONObject);
      end
      else if AItemsJsonObj.GetValue(cPostman_Item) is TJSONArray then
        LoadItem(AItemsJsonObj.FindValue(cPostman_Item) as TJSONArray);
    end;
    FItems.Add(AItem);
  end;
end;

{ TPostmanBody }

constructor TPostmanBody.Create;
begin
  FOptions := TPostmanBodyOptions.Create;
end;

destructor TPostmanBody.Destroy;
begin
  FOptions.Free;
  inherited;
end;

end.

