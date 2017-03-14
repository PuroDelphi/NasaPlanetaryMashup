unit uApodCtrl;

interface

uses FMX.Layouts, FMX.Types, FMX.StdCtrls, FMX.ExtCtrls, FMX.Objects, FMX.Dialogs, uApod, System.SysUtils,
  System.Classes, NetEncoding, System.Threading;

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

implementation

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
  if pCodificado <> EmptyStr then
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
    DecoImagen(FApod.FotoBin);
  end;
end;

procedure TApodCtrl.SetTitle(const pValue: String);
begin
  FlbTitle.Text := pValue;
end;

end.
