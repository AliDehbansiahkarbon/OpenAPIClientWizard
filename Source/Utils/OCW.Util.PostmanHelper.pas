unit OCW.Util.PostmanHelper;

interface

uses
  System.Json, System.SysUtils, System.Generics.Collections
  {$IF CompilerVersion <= 32.0},OCW.Util.Core{$ENDIF}
  {$IFDEF CODESITE}, CodeSiteLogging {$ENDIF};

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
      if Assigned(LvJsonObj.FindValue('info')) then
        FInfo := LvJsonObj.FindValue('info');

      // Load variables property
      if Assigned(LvJsonObj.FindValue('variables')) then
        FVariables := LvJsonObj.FindValue('variables');

      // Load items array
      if Assigned(LvJsonObj.FindValue('item')) then
      begin
        LvItemsArray := LvJsonObj.FindValue('item') as TJSONArray;
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
    if not Assigned(AItemsJsonObj.FindValue('request')) then
      Exit;

    // Load item properties
    if Assigned(AItemsJsonObj.FindValue('name')) then
      AItem.Name := StringReplace(AItemsJsonObj.FindValue('name').Value.Trim, ' ', '_', [rfReplaceAll, rfIgnoreCase]);

    // Load request
    if Assigned(AItemsJsonObj.FindValue('request')) then
    begin
      AItem.Request := TPostmanRequest.Create;

      LvRequestJsonObject := AItemsJsonObj.FindValue('request') as TJSONObject;

      if Assigned(LvRequestJsonObject.FindValue('method')) then
        AItem.Request.Method := LvRequestJsonObject.GetValue('method').Value;

      // Load request authentication
      if Assigned(LvRequestJsonObject.FindValue('auth')) then
      begin
        if Assigned(LvRequestJsonObject.GetValue('auth').FindValue('type')) then
          AItem.Request.Auth.AuthType := LvRequestJsonObject.GetValue('auth').FindValue('type').Value;

        if Assigned(LvRequestJsonObject.FindValue('auth').FindValue('bearer')) then
          AItem.Request.Auth.Bearer := LvRequestJsonObject.GetValue('auth').FindValue('bearer');
      end;

      // Load request URL
      if Assigned(LvRequestJsonObject.FindValue('url')) then
      begin
        LvUrlJsonObject := LvRequestJsonObject.FindValue('url') as TJSONObject;

        if Assigned(LvUrlJsonObject.FindValue('raw')) then
          AItem.Request.Url.Raw := LvUrlJsonObject.GetValue('raw').Value;

        if Assigned(LvUrlJsonObject.FindValue('protocol')) then
          AItem.Request.Url.Protocol := LvUrlJsonObject.GetValue('protocol').Value;

        if Assigned(LvUrlJsonObject.FindValue('host')) then
          AItem.Request.Url.Host := LvUrlJsonObject.GetValue('host');

        if Assigned(LvUrlJsonObject.FindValue('path')) then
          AItem.Request.Url.Path := LvUrlJsonObject.GetValue('path');

        if Assigned(LvUrlJsonObject.FindValue('query')) then
          AItem.Request.Url.Query := LvUrlJsonObject.GetValue('query'); // Load Query

        if Assigned(LvUrlJsonObject.FindValue('variable')) then
          AItem.Request.Url.Variable := LvUrlJsonObject.GetValue('variable'); // Load Variable
      end;


      // Load request headers
      if Assigned(LvRequestJsonObject.FindValue('header')) then
        AItem.Request.Header := LvRequestJsonObject.GetValue('header');


      // Load request body
      if Assigned(LvRequestJsonObject.FindValue('body')) then
      begin
        if Assigned(LvRequestJsonObject.FindValue('body').FindValue('mode')) then
          AItem.Request.Body.Mode := LvRequestJsonObject.FindValue('body').GetValue<string>('mode');

        if Assigned(LvRequestJsonObject.FindValue('body').FindValue('raw')) then
          AItem.Request.Body.Raw := LvRequestJsonObject.FindValue('body').GetValue<string>('raw');

        if Assigned(LvRequestJsonObject.FindValue('body').FindValue('options')) then
        begin
          if Assigned(LvRequestJsonObject.FindValue('body').FindValue('options').FindValue('raw')) then
            AItem.Request.Body.Options.RawOptions := LvRequestJsonObject.FindValue('body').FindValue('options').FindValue('raw');
        end;
      end;
    end;

    // Load response
    if Assigned(AItemsJsonObj.FindValue('response')) then
      AItem.Response := AItemsJsonObj.GetValue('response');


    // Load protocol profile behavior
    if Assigned(AItemsJsonObj.FindValue('protocolProfileBehavior')) then
    begin
      if Assigned(AItemsJsonObj.GetValue('protocolProfileBehavior').FindValue('disableBodyPruning')) then
        AItem.ProtocolProfileBehavior.DisableBodyPruning := TJSONObject(AItemsJsonObj.GetValue('protocolProfileBehavior')).GetValue<Boolean>('disableBodyPruning');
    end;

    // Load child items
    if Assigned(AItemsJsonObj.FindValue('item')) then
    begin
      if AItemsJsonObj.GetValue('item') is TJSONObject then
      begin
        LvItem := TPostmanItem.Create;
        LoadValues(LvItem, AItemsJsonObj.GetValue('item') as TJSONObject);
      end
      else if AItemsJsonObj.GetValue('item') is TJSONArray then
        LoadItem(AItemsJsonObj.FindValue('item') as TJSONArray);
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

