unit PPal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, IPPeerClient, REST.Client, Data.Bind.Components,
  Data.Bind.ObjectScope, uApod, FMX.Controls.Presentation, FMX.StdCtrls, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, FireDAC.FMXUI.Wait, Data.DB,
  FireDAC.Comp.Client, FMX.Layouts, FMX.Objects, DateUtils, System.Threading, FMX.TabControl, FMX.ExtCtrls,
  FMX.ScrollBox, FMX.Memo, System.Actions, FMX.ActnList, FMX.StdActns, FMX.MediaLibrary.Actions, FMX.Colors, FMX.Edit,
  FMX.Effects, FMX.Filter.Effects, FMX.DateTimeCtrls;

type
  TPpalFrm = class(TForm)
    sbPpal: TStyleBook;
    tcPpal: TTabControl;
    tiListado: TTabItem;
    tiDetalle: TTabItem;
    vsPpal: TVertScrollBox;
    tmrPpal: TTimer;
    imgDetalle: TImageViewer;
    lbDetalleTitulo: TLabel;
    tbDetalle: TToolBar;
    btBack: TSpeedButton;
    btInfo: TSpeedButton;
    lyDetalleInfo: TLayout;
    memInfoDetalle: TMemo;
    btShared: TSpeedButton;
    alPpal: TActionList;
    acShared: TShowShareSheetAction;
    btTexto: TSpeedButton;
    lyDetalleEdit: TLayout;
    Image1: TImage;
    SepiaEffect1: TSepiaEffect;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    InvertEffect1: TInvertEffect;
    MonochromeEffect1: TMonochromeEffect;
    ToonEffect1: TToonEffect;
    SepiaEffect2: TSepiaEffect;
    InvertEffect2: TInvertEffect;
    ToonEffect2: TToonEffect;
    MonochromeEffect2: TMonochromeEffect;
    ToolBar1: TToolBar;
    btConfig: TSpeedButton;
    btFilter: TSpeedButton;
    DateEdit1: TDateEdit;
    procedure FormCreate(Sender: TObject);
    procedure tmrPpalTimer(Sender: TObject);
    procedure btBackClick(Sender: TObject);
    procedure btInfoClick(Sender: TObject);
    procedure acSharedBeforeExecute(Sender: TObject);
    procedure btTextoClick(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure Image4Click(Sender: TObject);
    procedure Image3Click(Sender: TObject);
    procedure Image2Click(Sender: TObject);
  private
    vlPresiona: TProc<TImage, TApod>;
    vlCurrent: Integer;
    function CreaGridPanel: TGridPanelLayout;
    procedure CreaLinea(pFecha: TDate; pGridPanelLayout: TGridPanelLayout);
  public
    { Public declarations }
  end;

const
  CNS_LIMITE = 50;

var
  PpalFrm: TPpalFrm;

implementation

{$R *.fmx}

procedure TPpalFrm.btInfoClick(Sender: TObject);
begin
  lyDetalleEdit.Visible := False;
  lyDetalleInfo.Visible := not lyDetalleInfo.Visible;
end;

procedure TPpalFrm.btTextoClick(Sender: TObject);
// var
// mRect: TRectF;
begin
  lyDetalleEdit.Visible := not lyDetalleEdit.Visible;
  lyDetalleInfo.Visible := False;

  Image1.Bitmap := imgDetalle.Bitmap;
  Image2.Bitmap := imgDetalle.Bitmap;
  Image3.Bitmap := imgDetalle.Bitmap;
  Image4.Bitmap := imgDetalle.Bitmap;

  // imgDetalle.Bitmap.Canvas.BeginScene();
  // imgDetalle.Bitmap.Canvas.Stroke.Kind := TBrushKind.bkSolid;
  // imgDetalle.Bitmap.Canvas.StrokeThickness := 1;
  // imgDetalle.Bitmap.Canvas.Fill.Color := TAlphaColors.Red;
  // imgDetalle.Bitmap.Canvas.Font.Size := 40;
  // mRect.Create(0, 0, 300, 250);
  // imgDetalle.Bitmap.Canvas.FillText(mRect, 'Hello Text!', false, 100, [TFillTextFlag.ftRightToLeft],
  // TTextAlign.taCenter, TTextAlign.taCenter);
  //
  // imgDetalle.Bitmap.Canvas.EndScene;
end;

function TPpalFrm.CreaGridPanel: TGridPanelLayout;
begin
  Result := TGridPanelLayout.Create(Self);
  Result.RowCollection.Delete(1);
  Result.Align := TAlignLayout.Top;
  Result.Height := 150;
end;

procedure TPpalFrm.CreaLinea(pFecha: TDate; pGridPanelLayout: TGridPanelLayout);
var
  vTask: ITask;
begin
  vTask := TTask.Run(
    procedure
    var
      vApod: TApod;
      vLP: TGridPanelLayout;
      vApodCtrl: TApodCtrl;
    begin
      if vlCurrent <= CNS_LIMITE then
      begin
        if Assigned(pGridPanelLayout) then
          vLP := pGridPanelLayout
        else
          vLP := CreaGridPanel;

        vApod := TApodCache.Trae(FormatDateTime('YYYY-MM-DD', pFecha));

        if vApod.Media_Type = 'image' then
        begin
          TThread.Synchronize(TThread.CurrentThread,
            procedure
            begin
              vLP.Parent := vsPpal;
              vLP.Position.Y := 10000;
            end);

          vApodCtrl := TApodCtrl.Create(vLP, vApod);
          vApodCtrl.DibujaImagen;
          vApodCtrl.OnPresiona := vlPresiona;

          TThread.Synchronize(TThread.CurrentThread,
            procedure
            begin
              vApodCtrl.Parent := vLP;
              Inc(vlCurrent);
            end);
        end;

        if vLP.ControlsCount = 1 then
          CreaLinea(IncDay(pFecha, -1), vLP)
        else
          CreaLinea(IncDay(pFecha, -1), nil);
      end
      else
        TThread.Synchronize(TThread.CurrentThread,
          procedure
          begin
            vlCurrent := 1;
          end);
    end);
end;

procedure TPpalFrm.FormCreate(Sender: TObject);
begin
  tcPpal.ActiveTab := tiListado;
  vlCurrent := 1;
  vlPresiona := (
    procedure(pImage: TImage; pApod: TApod)
    begin
      imgDetalle.Bitmap := pImage.Bitmap;
      lbDetalleTitulo.Text := pApod.Title;

      if pApod.Copyright <> EmptyStr then
        lbDetalleTitulo.Text := lbDetalleTitulo.Text + ' by ' + pApod.Copyright;

      memInfoDetalle.Lines.Text := pApod.Explanation;
      tcPpal.SetActiveTabWithTransition(tiDetalle, TTabTransition.Slide);
      imgDetalle.BestFit;
    end);
end;

procedure TPpalFrm.Image1Click(Sender: TObject);
begin
  SepiaEffect2.Enabled := True;
  InvertEffect2.Enabled := False;
  ToonEffect2.Enabled := False;
  MonochromeEffect2.Enabled := False;
end;

procedure TPpalFrm.Image2Click(Sender: TObject);
begin
  SepiaEffect2.Enabled := False;
  InvertEffect2.Enabled := True;
  ToonEffect2.Enabled := False;
  MonochromeEffect2.Enabled := False;
end;

procedure TPpalFrm.Image3Click(Sender: TObject);
begin
  SepiaEffect2.Enabled := False;
  InvertEffect2.Enabled := False;
  ToonEffect2.Enabled := True;
  MonochromeEffect2.Enabled := False;
end;

procedure TPpalFrm.Image4Click(Sender: TObject);
begin
  SepiaEffect2.Enabled := False;
  InvertEffect2.Enabled := False;
  ToonEffect2.Enabled := False;
  MonochromeEffect2.Enabled := True;
end;

procedure TPpalFrm.acSharedBeforeExecute(Sender: TObject);
begin
  acShared.Bitmap := imgDetalle.Bitmap;
end;

procedure TPpalFrm.btBackClick(Sender: TObject);
begin
  tcPpal.SetActiveTabWithTransition(tiListado, TTabTransition.Slide);
end;

procedure TPpalFrm.tmrPpalTimer(Sender: TObject);
begin
  tmrPpal.Enabled := False;
  CreaLinea(Date, nil);
end;

end.
