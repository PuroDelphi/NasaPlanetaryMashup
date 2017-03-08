unit uApod;

interface

uses FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, FireDAC.FMXUI.Wait, Data.DB,
  FireDAC.Comp.Client, System.Classes, IPPeerClient, REST.Client, Data.Bind.Components,
  Data.Bind.ObjectScope, System.Threading, System.SysUtils, JSON, FMX.Dialogs, FireDAC.DApt, System.Net.URLClient,
  System.Net.HttpClient, System.Net.HttpClientComponent, NetEncoding, FMX.Layouts, FMX.Types, FMX.StdCtrls,
  FMX.ExtCtrls, FMX.Objects;

type
  TApod = class
  private
    FFecha: String;
    FExplanation: String;
    FCopyright: String;
    FHDUrl: String;
    FMedia_Type: String;
    FService_Version: String;
    FTitle: String;
    FURL: String;
    FFotoBin: String;
    function TraeFoto(pURL: String): TStringStream; overload;
  public
    procedure TraeFoto; overload;

    /// <summary>
    /// Fecha en formato String YYYY-MM-DD
    /// </summary>
    /// <remarks>
    /// Esta es la fecha de la foto, se ha elegido este formato debido a que
    /// es el mismo formato que tiene la API APOD de la NASA
    /// </remarks>
    property Fecha: String read FFecha write FFecha;
    property Explanation: String read FExplanation write FExplanation;
    property Copyright: String read FCopyright write FCopyright;
    property HDUrl: String read FHDUrl write FHDUrl;
    property Media_Type: String read FMedia_Type write FMedia_Type;
    property Service_Version: String read FService_Version write FService_Version;
    property Title: String read FTitle write FTitle;
    property URL: String read FURL write FURL;
    property FotoBin: String read FFotoBin write FFotoBin;
  end;

type
  TApodDB = class
  private
    FFecha: String;
    FConexion: TFDConnection;
  public

    class procedure Guarda(pApod: TApod); static;
    /// <param name="pFecha">
    /// YYYY-MM-DD
    /// </param>
    class function Trae(pFecha: String): TApod; overload; static;
    function Trae: TApod; overload;

    constructor Create(pOwner: TComponent; pFecha: String);
  end;

type
  TApodREST = class
  private
  public
    class function Trae(pFecha: String = ''): TApod; static;
  end;

type
  TApodCache = class

  public
    class function Trae(pFecha: String = ''): TApod; static;
  end;

type
  TApodCtrl = class(TLayout)
  private
    FApod: TApod;
    FlbTitle: TLabel;
    FImagen: TImage;
    FAni: TAniIndicator;
    FOnPresiona: TProc<TImage, TApod>;
    procedure SetTitle(const pValue: String);
    function GetTitle: String;
    procedure SetApod(const pValue: TApod);
    procedure HaceClick(Sender: TObject);
    procedure DecoImagen(pCodificado: String);
  public
    property OnPresiona: TProc<TImage, TApod> read FOnPresiona write FOnPresiona;

    procedure DibujaImagen;
    property Apod: TApod read FApod write SetApod;
    property Title: String read GetTitle write SetTitle;
    property Imagen: TImage read FImagen write FImagen;
    constructor Create(pComponent: TComponent; pApod: TApod);
    destructor Destroy; override;
  end;

const
  APIKey = 'BOwzfiaAjoqr6r0wdhhjbOAx1IdhMKHrhnaIJL8K';
  BaseURL = 'https://api.nasa.gov/planetary/apod?api_key=' + APIKey;

implementation

{ TApodDB }

constructor TApodDB.Create(pOwner: TComponent; pFecha: String);
begin
  FFecha := pFecha;

  FConexion := TFDConnection.Create(pOwner);
  FConexion.DriverName := 'SQLite';
  FConexion.Params.AddPair('Database', IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0))) + 'DB\FotoNasa.db');
end;

class procedure TApodDB.Guarda(pApod: TApod);
var
  vQ: TFDQuery;
  vApodDB: TApodDB;
begin
  vApodDB := TApodDB.Create(nil, pApod.Fecha);

  vQ := TFDQuery.Create(nil);
  try
    vQ.Connection := vApodDB.FConexion;
    vQ.ExecSQL
      ('insert into APOD(fecha, explanation, copyright, hdurl, media_type, service_version, title, url, FotoBin)' +
      'values(:fecha, :explanation, :copyright, :hdurl, :media_type, :service_version, :title, :url, :FotoBin)',
      [pApod.Fecha, pApod.Explanation, pApod.Copyright, pApod.HDUrl, pApod.Media_Type, pApod.Service_Version,
      pApod.Title, pApod.URL, pApod.FotoBin], [TFieldType.ftString, TFieldType.ftString, TFieldType.ftString,
      TFieldType.ftString, TFieldType.ftString, TFieldType.ftString, TFieldType.ftString, TFieldType.ftString,
      TFieldType.ftString]);
  finally
    vQ.DisposeOf;
    vApodDB.DisposeOf;
  end;
end;

function TApodDB.Trae: TApod;
var
  vQ: TFDQuery;
begin
  Result := nil;
  vQ := TFDQuery.Create(nil);
  try
    vQ.Connection := FConexion;
    vQ.SQL.Add
      ('select fecha, explanation, copyright, hdurl, media_type, service_version, title, url, FotoBin from APOD');

    if FFecha <> EmptyStr then
      vQ.SQL.Add('where fecha = ''' + FFecha + '''')
    else
      vQ.SQL.Add('where fecha = ''' + FormatDateTime('YYYY-MM-DD', Date) + '''');

    vQ.Open;

    if vQ.RecordCount > 0 then
    begin
      Result := TApod.Create;
      Result.Fecha := vQ.FieldByName('Fecha').AsString;
      Result.Explanation := vQ.FieldByName('Explanation').AsString;
      Result.Copyright := vQ.FieldByName('Copyright').AsString;
      Result.HDUrl := vQ.FieldByName('HDUrl').AsString;
      Result.Media_Type := vQ.FieldByName('Media_Type').AsString;
      Result.Service_Version := vQ.FieldByName('Service_Version').AsString;
      Result.Title := vQ.FieldByName('Title').AsString;
      Result.URL := vQ.FieldByName('URL').AsString;
      Result.FotoBin := vQ.FieldByName('FotoBin').AsString;
    end;
  finally
    vQ.DisposeOf;
  end;
end;

class function TApodDB.Trae(pFecha: String): TApod;
var
  vApodDB: TApodDB;
begin
  vApodDB := TApodDB.Create(nil, pFecha);
  try
    Result := vApodDB.Trae;
  finally
    vApodDB.DisposeOf;
  end;
end;

{ TApodREST }

class function TApodREST.Trae(pFecha: String = ''): TApod;
var
  vClient: TRESTClient;
  vRequest: TRESTRequest;
  vResponse: TRESTResponse;

  vJSONValue: TJSONValue;
begin
  vClient := TRESTClient.Create(BaseURL);
  vRequest := TRESTRequest.Create(nil);
  vResponse := TRESTResponse.Create(nil);
  try
    vClient.BaseURL := BaseURL;

    if pFecha <> EmptyStr then
      vClient.BaseURL := vClient.BaseURL + '&date=' + pFecha;

    vRequest.Client := vClient;
    vRequest.Response := vResponse;

    vRequest.Execute;

    vJSONValue := TJSONObject.ParseJSONValue(vResponse.Content);
    try
      Result := TApod.Create;
      Result.Fecha := pFecha;
      Result.Explanation := vJSONValue.GetValue('explanation', '');
      Result.Copyright := vJSONValue.GetValue('copyright', '');
      Result.HDUrl := vJSONValue.GetValue('hdurl', '');
      Result.Media_Type := vJSONValue.GetValue('media_type', '');
      Result.Service_Version := vJSONValue.GetValue('service_version', '');
      Result.Title := vJSONValue.GetValue('title', '');
      Result.URL := vJSONValue.GetValue('url', '');
    finally
      vJSONValue.DisposeOf;
    end;
  finally
    vClient.DisposeOf;
    vRequest.DisposeOf;
    vResponse.DisposeOf;
  end;
end;

function TApod.TraeFoto(pURL: String): TStringStream;
var
  vHTTP: TNetHTTPClient;
begin
  vHTTP := TNetHTTPClient.Create(nil);
  try
    Result := TStringStream.Create;
    vHTTP.Get(pURL, Result);
    Result.Position := 0;
  finally
    vHTTP.DisposeOf;
  end;
end;

{ TApodCache }

class function TApodCache.Trae(pFecha: String): TApod;
begin
  Result := TApodDB.Trae(pFecha);

  if not Assigned(Result) then
  begin
    Result := TApodREST.Trae(pFecha);
    // TApodDB.Guarda(Result);
  end;
end;

{ TApodCtrl }

constructor TApodCtrl.Create(pComponent: TComponent; pApod: TApod);
begin
  inherited Create(pComponent);

  Align := TAlignLayout.Client;

  FlbTitle := TLabel.Create(Self);
  FlbTitle.Align := TAlignLayout.Top;
  FlbTitle.Parent := Self;

  FImagen := TImage.Create(Self);
  FImagen.Align := TAlignLayout.Client;
  FImagen.WrapMode := TImageWrapMode.Stretch;
  FImagen.OnClick := HaceClick;
  FImagen.Parent := Self;

  SetApod(pApod);
end;

procedure TApodCtrl.DecoImagen(pCodificado: String);
var
  vEncode, vDecode: TStringStream;
begin
  vEncode := TStringStream.Create(pCodificado);
  try
    vDecode := TStringStream.Create;

    TNetEncoding.Base64.Decode(vEncode, vDecode);
    vDecode.Position := 0;

    TThread.Synchronize(TThread.CurrentThread,
      procedure
      begin
        FImagen.Bitmap.LoadFromStream(vDecode);
      end);
  finally
    vEncode.DisposeOf
  end;
end;

destructor TApodCtrl.Destroy;
begin
  FlbTitle.DisposeOf;
  FImagen.DisposeOf;
  inherited;
end;

procedure TApodCtrl.DibujaImagen;
// var
// vTask: ITask;
begin
  if FApod.Media_Type = 'image' then
  begin
    // vTask :=
    TTask.Run(
      procedure
      begin
        FAni := TAniIndicator.Create(nil);
        try
          FAni.Align := TAlignLayout.HorzCenter;
          FAni.Enabled := True;
          TThread.Synchronize(TThread.CurrentThread,
            procedure
            begin
              FAni.Parent := Self;
            end);

          if FApod.FotoBin = EmptyStr then
          begin
            FApod.TraeFoto;
            TApodDB.Guarda(FApod);
          end;

          DecoImagen(FApod.FotoBin);

        finally
          TThread.Synchronize(TThread.CurrentThread,
            procedure
            begin
              FAni.Enabled := False;
              FAni.DisposeOf;
            end);
        end;
      end);
  end;
end;

function TApodCtrl.GetTitle: String;
begin
  Result := FlbTitle.Text;
end;

procedure TApodCtrl.HaceClick(Sender: TObject);
begin
  if Assigned(FOnPresiona) then
    OnPresiona(TImage(Sender), FApod);
end;

procedure TApodCtrl.SetApod(const pValue: TApod);
var
  vEncode, vDecode: TStringStream;
begin
  FApod := pValue;

  if Assigned(FApod) then
  begin
    FlbTitle.Text := pValue.Title;

    if pValue.FotoBin <> EmptyStr then
      DecoImagen(FApod.FotoBin);
  end;
end;

procedure TApodCtrl.SetTitle(const pValue: String);
begin
  FlbTitle.Text := pValue;
end;

procedure TApod.TraeFoto;
var
  vStreamEncode: TStringStream;
begin
  vStreamEncode := TStringStream.Create;
  try
    TBase64Encoding.Base64.Encode(TraeFoto(FURL), vStreamEncode);
    vStreamEncode.Position := 0;

    FFotoBin := vStreamEncode.DataString;
  finally
    vStreamEncode.DisposeOf;
  end;
end;

end.
