unit frmLog;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, MySQL;

type
  TLogWindow = class(TForm)
    btnClear: TButton;
    btnClose: TButton;
    Label4: TLabel;
    MySQLQuery: TEdit;
    btnSend: TButton;
    Bevel1: TBevel;
    btnConfigure: TButton;
    lsLog: TMemo;
    procedure AddLogInfo(sMess: String);
    procedure SendMySQLQuery(sMess: String);
    procedure LoadSettings();
    procedure SaveSettings();

    function DecryptPassword(Password: String): String;
    function EncryptPassword(Password: String): String;

    procedure btnClearClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSendClick(Sender: TObject);
    procedure btnConfigureClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    HaltNow: Boolean;
  end;

var
  LogWindow: TLogWindow;

implementation

uses frmMain;

{$R *.DFM}

procedure TLogWindow.SendMySQLQuery(sMess: String);
var
	MySQL: PMYSQL;
	myResult: PMYSQL_RES;
        Field: PMYSQL_FIELD;
        FieldCount: Longword;
        Lengths: PMYSQL_LENGTHS;
	Row: PMYSQL_ROW;
	Buffer, Line, MyPass, MyUser, MyHost, MyQuery, MyDatabase, sHiddenPass: String;
	MyTime, MyPort, a, i, Width: Integer;

const
        Spaces = '                                                                                                                                                                                                ';
        Equals = '=========================================';
        Dashes = '-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------' + '-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------';

	procedure Fail(Msg: string = '');
	begin
                //if mysql_errno(MySQL) = 0 then exit;
		if Msg = '' then Msg := Format('%d - %s', [mysql_errno(MySQL), mysql_error(MySQL)]);
		Application.MessageBox(PChar(Msg),'Fatal Error',MB_OK+MB_ICONERROR+MB_DEFBUTTON1);
		LogWindow.AddLogInfo(Msg);
                Application.ProcessMessages;
                HaltNow := True;
	end;

begin
        HaltNow := False;
	MyHost := MainForm.MySQLHost.Text;
	MyPort := StrToIntDef(MainForm.MySQLPort.Text, MYSQL_PORT);
	MyUser := MainForm.MySQLUser.Text;
	MyPass := MainForm.MySQLPass.Text;
	MyTime := StrToIntDef(MainForm.MySQLTime.Text, 30);
        MyDatabase := MainForm.MySQLDatabase.Text;
	MyQuery := sMess;

        //SetLength(sHiddenPass, Length(MyPass));
        for a := 0 to Length(MyPass) do sHiddenPass := sHiddenPass + '*';

        if MyHost = '' then
	begin
		Application.MessageBox('Adres serwera MySQL nie mo�e by� ci�giem pustym! Sprawd� konfiguracj�...','B��d!',MB_OK+MB_ICONWARNING+MB_DEFBUTTON1);
		exit;
	end;

        if MyPort = 0 then
	begin
		Application.MessageBox('B��dny port! Sprawd� konfiguracj�...','B��d!',MB_OK+MB_ICONWARNING+MB_DEFBUTTON1);
		exit;
	end;

        if MyUser = '' then
	begin
		Application.MessageBox('Login nie mo�e by� ci�giem pustym! Sprawd� konfiguracj�...','B��d!',MB_OK+MB_ICONWARNING+MB_DEFBUTTON1);
		exit;
	end;

        if MyPass = '' then
	begin
		Application.MessageBox('Has�o nie mo�e by� ci�giem pustym! Sprawd� konfiguracj�...','B��d!',MB_OK+MB_ICONWARNING+MB_DEFBUTTON1);
		exit;
	end;

        if MyDatabase = '' then
	begin
		Application.MessageBox('Nazwa bazy danych nie mo�e by� ci�giem pustym! Sprawd� konfiguracj�...','B��d!',MB_OK+MB_ICONWARNING+MB_DEFBUTTON1);
		exit;
	end;

        if MyQuery = '' then
	begin
		Application.MessageBox('Kwerenda MySQL nie mo�e by� ci�giem pustym! Sprawd� konfiguracj�...','B��d!',MB_OK+MB_ICONWARNING+MB_DEFBUTTON1);
		exit;
	end;

        if MyTime = 0 then
	begin
		Application.MessageBox('B��dny czas timeout! Sprawd� konfiguracj�...','B��d!',MB_OK+MB_ICONWARNING+MB_DEFBUTTON1);
		exit;
	end;

        lsLog.Clear;

        MySQL := mysql_init(nil);
	if MySQL = nil then Fail('B��d utworzenia obiektu PMYSQL! Czy libMySQL.dll jest zainstalowane w systemie?');
	try
		if mysql_options(MySQL, MYSQL_OPT_CONNECT_TIMEOUT, @MyTime) <> 0 then Fail;

                if HaltNow then exit;

                LogWindow.AddLogInfo('Login: "' + MyUser + '". Has�o: "' + sHiddenPass + '"');
                LogWindow.AddLogInfo('��czenie z serwerem MySQL "' + MyHost + '"...');

		if mysql_real_connect(MySQL, pChar(MyHost), pChar(MyUser), pChar(MyPass), nil, MyPort, nil, Integer(False)) = nil then Fail;

                if HaltNow then exit;

		if mysql_get_host_info(MySQL) <> '' then LogWindow.AddLogInfo('Po��czony.');

                if HaltNow then exit;

		LogWindow.AddLogInfo('��czenie z baz� danych "' + MyDatabase + '"...');
		if mysql_select_db(MySQL, PChar(MyDatabase)) <> 0 then Fail();

                if HaltNow then exit;

		LogWindow.AddLogInfo('Wysy�anie kwerendy MySQL:');
                LogWindow.AddLogInfo(MyQuery);
		if mysql_query(MySQL, pChar(MyQuery)) <> 0 then Fail;

                if HaltNow then exit;

                LogWindow.AddLogInfo(Equals);

                myResult := mysql_use_result(MySQL);
                if myResult = nil then Fail;

                Line := '';
                Width := 0;

                Field := mysql_fetch_field(myResult);
                while Field <> nil do
                begin
                        if Line <> '' then
                        begin
                                AppendStr(Line, ' ');
                                Inc(Width);
                        end;

                        AppendStr(Line, Copy(Field.Name + Spaces, 1, Field.Length));
                        Inc(Width, Field.Length);

                        Field := mysql_fetch_field(myResult);
                end;

                LogWindow.AddLogInfo(Line);
                LogWindow.AddLogInfo(Copy(Dashes, 1, Width));

                FieldCount := mysql_num_fields(myResult);

                Row := mysql_fetch_row(myResult);
                while Row <> nil do
                begin
                        Line := '';
                        Lengths := mysql_fetch_lengths(myResult);

                        if Lengths = nil then Fail;

                        for I := 0 to FieldCount - 1 do
                        begin
                                if Line <> '' then AppendStr(Line, ' ');

                                SetString(Buffer, Row[I], Lengths[I]);
                                AppendStr(Line, copy(Buffer + Spaces, 1, mysql_fetch_field_direct(myResult, I).Length));
                        end;

                        LogWindow.AddLogInfo(Line);
                        Row := mysql_fetch_row(myResult);
                end;

                if mysql_eof(myResult) = 0 then Fail;

                LogWindow.AddLogInfo(Equals);

		LogWindow.AddLogInfo('Roz��czanie i zamykanie po��czenia...');
	finally
		mysql_close(MySQL);
	end;
end;

procedure TLogWindow.AddLogInfo(sMess: String);
begin
        lsLog.Lines.Add('['+TimeToStr(Now)+'] '+sMess);
        Application.ProcessMessages;
end;

procedure TLogWindow.btnClearClick(Sender: TObject);
begin
	lsLog.Clear;
end;

procedure TLogWindow.btnCloseClick(Sender: TObject);
begin
	Close;
end;

procedure TLogWindow.FormClose(Sender: TObject; var Action: TCloseAction);
begin
        SaveSettings();
	lsLog.Lines.SaveToFile('LastLog.dat');
end;

procedure TLogWindow.btnSendClick(Sender: TObject);
begin
	SendMySQLQuery(MySQLQuery.Text);
end;

procedure TLogWindow.btnConfigureClick(Sender: TObject);
begin
        MainForm.ShowModal;
end;

procedure TLogWindow.LoadSettings();
var
        loader: TStringList;
begin
	MainForm.MySQLHost.MaxLength := HOSTNAME_LENGTH;
	MainForm.MySQLUser.MaxLength := USERNAME_LENGTH;
	MainForm.MySQLPort.Text := IntToStr(MYSQL_PORT);
	loader:=TStringList.Create;
	if not FileExists('ServerSettings.dat') then
	begin
		loader.Free;
		SaveSettings();
                exit;
	end;
	loader.LoadFromFile('ServerSettings.dat');

	MainForm.MySQLHost.Text:=loader.Values['MySQLHost'];
        MainForm.MySQLPort.Text:=loader.Values['MySQLPort'];
        MainForm.MySQLUser.Text:=loader.Values['MySQLUser'];
	MainForm.MySQLPass.Text:=DecryptPassword(loader.Values['MySQLPass']);
        MainForm.MySQLDatabase.Text:=loader.Values['MySQLDatabase'];
	MainForm.MySQLTime.Text:=loader.Values['MySQLTime'];
        MySQLQuery.Text := loader.Values['MySQLQuery'];
	loader.Free;
end;

procedure TLogWindow.SaveSettings();
var
	saver: TStringList;
begin
	saver:=TStringList.Create;
	saver.Clear;
	saver.Values['MySQLHost']:=MainForm.MySQLHost.Text;
	saver.Values['MySQLPort']:=MainForm.MySQLPort.Text;
        saver.Values['MySQLUser']:=MainForm.MySQLUser.Text;
        saver.Values['MySQLPass']:=EncryptPassword(MainForm.MySQLPass.Text);
        saver.Values['MySQLDatabase']:=MainForm.MySQLDatabase.Text;
	saver.Values['MySQLTime']:=MainForm.MySQLTime.Text;
        saver.Values['MySQLQuery'] := MySQLQuery.Text;
	saver.SaveToFile('ServerSettings.dat');
	saver.Free;
end;

function TLogWindow.EncryptPassword(Password: String): String;
var
	a, rKey: Integer;
	gPass: String;
begin
	rKey:=Random(600)+100;
	gPass:=IntToStr(rKey)+Chr(Random(25)+97);
	for a:=1 to Length(Password) do
	begin
		gPass:=gPass+IntToStr(Ord(Password[a])+rKey)+Chr(Random(25)+97);
	end;
	Result:=gPass;
end;

function TLogWindow.DecryptPassword(Password: String): String;
var
	a, rKey: Integer;
	gPass: String;
begin
	rKey:=StrToIntDef(Copy(Password,1,3),0);
	for a:=1 to (Length(Password)-4) div 4 do
	begin
		gPass:=gPass+Chr(StrToIntDef(Copy(Password,(4*a)+1,3),0)-rKey);
	end;
	Result:=gPass;
end;

procedure TLogWindow.FormShow(Sender: TObject);
begin
        LoadSettings();
end;

end.
