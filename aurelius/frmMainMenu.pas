unit frmMainMenu;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, RVScroll, RichView, RVStyle;

type
  TMainMenu = class(TForm)
    Back: TPaintBox;
    RVStyle1: TRVStyle;
    rv: TRichView;
    Edit1: TEdit;
    Button1: TButton;
    Timer1: TTimer;
    procedure FormPaint(Sender: TObject);
    procedure AnimateAdd(Tekst: String; Style: Integer; NewLine: Boolean);
    procedure Edit1KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ProcessCommand(Command: String);
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    rvLines: Integer;
  public
    { Public declarations }
  end;

var
  MainMenu: TMainMenu;

implementation

uses frmSetup, frmBack, frmIntro, Procs, frmHelp, frmNewGame;

{$R *.DFM}

procedure TMainMenu.FormPaint(Sender: TObject);
begin
DrawOutline(Back,'Konsola');
end;

procedure TMainMenu.AnimateAdd(Tekst: String; Style: Integer; NewLine: Boolean);
var
        a: Integer;
begin
if NewLine then
begin
        rv.AddTextNL('',Style,0,0);
        Inc(rvLines);
        if rvLines>=7 then
        begin
                rvLines:=1;
                rv.Clear;
        end;
end;
for a:=1 to Length(Tekst) do
begin
        rv.Add(Copy(Tekst,a,1),Style);
        rv.Format;
        MakeDelay(20);
end;
rv.ScrollTo(rv.DocumentHeight);
end;

procedure TMainMenu.Edit1KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
        ucmd: String;
begin
if (Key=13) and (Edit1.Text<>'') then
begin
        Edit1.Enabled:=False;
        ucmd:=Edit1.Text;
        Edit1.Text:='';
        ucmd:=AnsiLowerCase(ucmd);
        AnimateAdd('> '+ucmd,1,True);
        ProcessCommand(ucmd);
        Edit1.Enabled:=True;
        Edit1.SetFocus;
end;
end;

procedure TMainMenu.ProcessCommand(Command: String);
var
        MRCode: Integer;
begin
if Pos(' ', Command)<>0 then
begin
        AnimateAdd('Polecenie nie mo�e zawiera� znaku odst�pu.',0,True);
        exit;
end;
if (Command='zamknij') or (Command='koniec') or (Command='zako�cz') then
begin
        ShowCursor(True);
        MRCode:=ShowInfo('Potwierd� zerwanie po��czenia...','Czy napewno chcesz przerwa� po��czenie z obecn� bramk� Aureliusa ???',2);
        ShowCursor(False);
        if MRCode=7 then exit;
        Application.ProcessMessages;
        {AnimateAdd('Trwa zamykanie systemu...',0,True);
        MakeDelay(1000);
        AnimateAdd('### Wyrzucenie �wiadomo�ci...',0,True);
        MakeDelay(1000);
        AnimateAdd(' OK',1,False);
        MakeDelay(200);
        AnimateAdd('### Deaktywuj� transformacje G-G...',0,True);
        MakeDelay(1000);
        AnimateAdd(' OK',1,False);
        MakeDelay(1000);
        AnimateAdd('Do zobaczenia...',0,True);
        MakeDelay(200);}
        ShowCursor(True);
        BackForm.EndGame;
        exit;
end;
if (Command='konfiguruj') or (Command='konfiguracja') then
begin
        AnimateAdd('Otwieram modu� konfiguracyjny...',0,True);
        MakeDelay(500);
        ShowCursor(True);
        SetupForm.ShowModal;
        ShowCursor(False);
        if SetupForm.ModalResult=mrCancel then MainMenu.AnimateAdd('Konfiguracja anulowana...',0,True);
        if SetupForm.ModalResult=mrOK then MainMenu.AnimateAdd('Konfiguracja zapisana...',0,True);
        exit;
end;
if (Command='nowy') or (Command='utw�rz_nowy') then
begin
        AnimateAdd('Otwieram modu� kreacji nowego obrazu...',0,True);
        MakeDelay(500);
        ShowCursor(True);
        NewGame.ShowModal;
        ShowCursor(False);
        exit;
end;
if (Command='poka�_intro') or (Command='intro') then
begin
        AnimateAdd('Usi�d� wygodnie i zrelaksuj si�...',0,True);
        MakeDelay(500);
        with BackForm.mm do
        begin
                Stop;
                Eject;
                Close;
        end;
        IntroForm.ShowIntro;
        with BackForm.mm do
        begin
                FileName:=DataPath+'main.mid';
                Wait:=True;
                Open;
                Play;
        end;
        AnimateAdd('Prezentacja zako�czona...',0,True);
        exit;
end;
if Command='wersja' then
begin
        AnimateAdd('System ',0,True);
        AnimateAdd(' Aurelius ',1,False);
        AnimateAdd('(wersja '+GameVersion+')',0,False);
        exit;
end;
if Command='pomoc' then
begin
        AnimateAdd('Odczytuj� dane systemu pomocy...',0,True);
        Help.TrybPracy.Caption:='Help';
        Help.OpenHelp;
        AnimateAdd(' OK',1,False);
        MakeDelay(500);
        AnimateAdd('Otwieram modu� pomocy...',0,True);
        MakeDelay(500);
        Help.rvText.Clear;
        Help.rvText.Add('Wybierz interesuj�cy Ci� temat z listy znajduj�cej si� po lewej stronie.',0);
        Help.rvText.Format;
        ShowCursor(True);
        Help.ShowModal;
        ShowCursor(False);
        AnimateAdd('Po��czenie zamkni�te...',0,True);
        exit;
end;
if (Command='historia') or (Command='historia_gry') then
begin
        AnimateAdd('Odczytuj� dane...',0,True);
        Help.TrybPracy.Caption:='History';
        Help.OpenHelp;
        AnimateAdd(' OK',1,False);
        MakeDelay(500);
        AnimateAdd('Otwieram modu�...',0,True);
        MakeDelay(500);
        Help.rvText.Clear;
        Help.rvText.Add('Modu� ten pozwala �ledzi� zmiany w kolejnych wersjach i wydaniach gry.',0);
        Help.rvText.Add(' Wybierz interesuj�c� Ci� dat� z listy znajduj�cej si� po lewej stronie.',0);
        Help.rvText.Format;
        ShowCursor(True);
        Help.ShowModal;
        ShowCursor(False);
        AnimateAdd('Po��czenie zamkni�te...',0,True);
        exit;
end;
{if Command='test' then
begin
        ShowCursor(True);
        ShowInfo('Testowanie...','To jest tylko informacja testowa i absolutnie nic wi�cej !!!',1);
        ShowCursor(False);
        exit;
end;}
AnimateAdd('Polecenie nieznane...',0,True);
end;

procedure TMainMenu.FormShow(Sender: TObject);
begin
ShowCursor(False);
Timer1.Enabled:=True;
end;

procedure TMainMenu.Timer1Timer(Sender: TObject);
begin
Timer1.Enabled:=False;
{Randomize;
AnimateAdd('### Aktywuj� transformacje G-G...',0,True);
MakeDelay(1000);
AnimateAdd(' OK',1,False);
MakeDelay(200);
AnimateAdd('### Transport �wiadomo�ci...',0,True);
MakeDelay(1000);
AnimateAdd(' OK',1,False);
MakeDelay(200);
AnimateAdd('### Wej�cie do systemu w w�le ',0,True);
AnimateAdd(IntToStr(Random(99999))+'.'+IntToStr(Random(99999)),1,False);
AnimateAdd(' ',0,True);
MakeDelay(1000);
AnimateAdd('Aurelius '+GameVersion,1,True);
AnimateAdd(' Witaj w systemie Podr�niku!',0,False);
AnimateAdd('Dost�p do pomocy on-line: wpisz',0,True);
AnimateAdd(' pomoc',1,False);
AnimateAdd('...',0,False);
rvLines:=6;}
Edit1.Enabled:=True;
Edit1.SetFocus;
end;

end.
