{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit OCW.Util.Rest;

interface

uses
  System.Classes, System.SysUtils, VCL.Dialogs, System.Net.URLClient, System.Net.HttpClient,
  System.Net.HttpClientComponent, System.NetEncoding, Rest.Json, System.JSON, System.StrUtils,
  System.Generics.Collections, Neslib.Yaml, System.Rtti,
  OCW.Util.Core,
  OCW.Util.Consts;

type
  TApiStructure = class
  private
    FRequestObject: TObject;
    FApiAddress: String;
    FToken: String;
    FAuthType: String;
    FMethod: String;
    FCustomHeaders: TArray<string>;
    FContentType: String;
    FAccept: String;
    FTimeOut: Integer;
    FUsername: string;
    FPassword: string;
    FSpecType: TActiveType;
  public
    constructor Create;
    function CallAPI: String;

    property RequestObject: TObject read FRequestObject write FRequestObject;
    property ApiAddress: String read FApiAddress write FApiAddress;
    property Token: String read FToken write FToken;
    property AuthType: String read FAuthType write FAuthType;
    property Method: String read FMethod write FMethod;
    property CustomHeaders: TArray<string> read FCustomHeaders write FCustomHeaders;
    property ContentType: String read FContentType write FContentType;
    property Accept: String read FAccept write FAccept;
    property TimeOut: Integer read FTimeOut write FTimeOut;
    property Username: string read FUsername write FUsername;
    property Password: string read FPassword write FPassword;
    property SpecType: TActiveType read FSpecType write FSpecType;
  end;

  TValidator = class
  public
    class function IsValid(AApiStruct: TApiStructure; AExtractedSpec: TFinalParsingObject): Boolean; overload;
    class function IsValid(AFile: string; AActiveType: TActiveType; AExtractedSpec: TFinalParsingObject): Boolean; overload;
  end;

implementation
{$IFDEF CODESITE}
uses
  CodeSiteLogging;
{$ENDIF}

function CreateNetHttp(const AApiAddress, AContentType, AAccept:string; ATimeOut: Integer): TNetHTTPClient;
begin
  Result := TNetHTTPClient.Create(nil);
  Result.HandleRedirects := Pos('https://', AApiAddress) > 0;
  Result.ConnectionTimeout := ATimeOut; //5 minutes
  Result.ResponseTimeout := ATimeOut; //5 minutes
  Result.AcceptCharSet := Utf8AcceptCharSet;
  if AContentType = EmptyStr then
    Result.ContentType := cJson_ApplicationJson
  else
    Result.ContentType := AContentType;

  if AAccept.IsEmpty then
    Result.Accept := cJson_ApplicationJson
  else
    Result.Accept := AAccept;

  Result.AcceptEncoding := Utf8AcceptCharSet;
end;

{ TApiStructure }

constructor TApiStructure.Create;
begin
  FTimeOut := 30000; // Default timeout for connection and response timeout = 5 minutes!
end;

function TApiStructure.CallAPI: String;
var
  I: Integer;
  LvHttp: TNetHTTPClient;
  LvResponseStream, LvRequestStream: TStringStream;
  LvRequestString: String;
  LvHeaders: TNetHeaders;
begin
  Result := EmptyStr;
  if FApiAddress.Equals(EmptyStr) then
    Exit;

  LvHttp := CreateNetHttp(FApiAddress, FContentType, FAccept, FTimeOut);
  LvResponseStream := TStringStream.Create(EmptyStr, TEncoding.UTF8);
  try
    if not FToken.Equals(EmptyStr) then
    begin
      SetLength(LvHeaders,1);
      LvHeaders[0].Name := 'Authorization';
      LvHeaders[0].Value := FAuthType + ' ' + FToken;
    end
    else if FAuthType.ToLower.Trim = 'basic' then
    begin
      SetLength(LvHeaders,1);
      LvHeaders[0].Name := 'Authorization';
      LvHeaders[0].Value := FAuthType + ' ' + TNetEncoding.Base64.Encode(Format('%s:%s', [FUsername.Trim, FPassword.Trim]));
    end;

    if Length(FCustomHeaders) > 0 then
    begin
      for I := 0 to Length(FCustomHeaders) - 1 do
      begin
        if Odd(I) then Continue;
        if FCustomHeaders[I] <> EmptyStr then
        begin
          SetLength(LvHeaders, length(LvHeaders) + 1);
          LvHeaders[length(LvHeaders) - 1].Name := FCustomHeaders[I];
          LvHeaders[length(LvHeaders) - 1].Value := FCustomHeaders[I + 1];
        end;
      end;
    end;
    LvRequestString := EmptyStr;
    if FRequestObject <> nil then
    begin
      if FRequestObject.ClassName <> 'TStringStream' then
        LvRequestString := Rest.Json.TJson.ObjectToJsonString(FRequestObject, [TJsonOption.joIgnoreEmptyStrings, TJsonOption.joIgnoreEmptyArrays])
      else
        LvRequestString := TStringStream(FRequestObject).DataString;
    end;

    LvRequestStream := TStringStream.Create(LvRequestString, TEncoding.UTF8);
    try
      if (FMethod = 'POST') then
        LvHttp.Post(FApiAddress, LvRequestStream, LvResponseStream, LvHeaders)
      else if (FMethod = 'GET') then
        LvHttp.Get(FApiAddress, LvResponseStream, LvHeaders)

    except on E:Exception do
      begin
        Result := EmptyStr;
        ShowMessage(E.Message);
        Exit;
      end;
    end;

    Result := LvResponseStream.DataString;
  finally
    FreeAndNil(LvHttp);
    FreeAndNil(LvResponseStream);
    FreeAndNil(LvRequestStream);
  end;
end;

{ TValidator }

class function TValidator.IsValid(AApiStruct: TApiStructure; AExtractedSpec: TFinalParsingObject): Boolean;
var
  LvResponse: string;
begin
  Result := False;
  try
    LvResponse := AApiStruct.CallAPI;

    if not LvResponse.Trim.IsEmpty then
    begin
      AExtractedSpec.FinalObjectType := AApiStruct.SpecType;

      case AApiStruct.SpecType of
        atSwaggerJSON, atOpenAPiJson, atPostManCollection: AExtractedSpec.FinalJson := TJSONObject.ParseJSONValue(LvResponse);

        atOpenAPIYaml:
          AExtractedSpec.FinalYaml := TYamlDocument.Load(TStringStream.Create(LvResponse));
      end;

      if (Assigned(AExtractedSpec.FinalJson)) or (Assigned(AExtractedSpec.FinalYaml)) then
        Result := True;
    end;
  except on E: Exception do
    Result := False;
  end;
end;

class function TValidator.IsValid(AFile: string; AActiveType: TActiveType; AExtractedSpec: TFinalParsingObject): Boolean;
var
  LvTempList: TStringList;
  LvFileContent: string;
begin
  Result := False;
  LvTempList := TStringList.Create;
  try
    try
      LvTempList.LoadFromFile(AFile, TEncoding.UTF8);
      LvFileContent := LvTempList.Text.Trim;

      if not LvFileContent.Trim.IsEmpty then
      begin
        AExtractedSpec.FinalObjectType := AActiveType;

        case AActiveType of
          atSwaggerJSON, atOpenAPiJson, atPostManCollection: AExtractedSpec.FinalJson := TJSONObject.ParseJSONValue(LvFileContent);

          atOpenAPIYaml: AExtractedSpec.FinalYaml := TYamlDocument.Load(TStringStream.Create(LvFileContent));
        end;

        if Assigned(AExtractedSpec.FinalJson) or Assigned(AExtractedSpec.FinalYaml) then
          Result := True;
      end
      else
      begin
        {$IFDEF CODESITE}
        CodeSite.Send('File is blank!');
        {$ENDIF}
      end;
    except on E: Exception do
      begin
        Result := False;
        MarkUsed(Result);
        {$IFDEF CODESITE}
          CodeSite.Send('Validation exception ' + E.Message);
        {$ELSE}
          raise Exception.Create('Validation Error:' + E.Message);
        {$ENDIF}
      end;
    end;
  finally
    LvTempList.Free;
  end;
end;

end.
