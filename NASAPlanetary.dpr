program NASAPlanetary;

uses
  System.StartUpCopy,
  FMX.Forms,
  PPal in 'PPal.pas' {PpalFrm},
  uApod in 'Clases\uApod.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TPpalFrm, PpalFrm);
  Application.Run;
end.
