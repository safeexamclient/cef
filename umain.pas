unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, uCEFChromium, uCEFWindowParent, uCEFApplication , uCEFTypes, uCEFInterfaces, uCEFChromiumEvents,
  fpjson, fphttpclient,
  IniFiles;

type

  { TForm1 }

  TForm1 = class(TForm)
    BitBtn_Exit: TBitBtn;
    CEFWindowParent1: TCEFWindowParent;
    Chromium1: TChromium;
    Edit_Exit: TEdit;
    Label_Left: TLabel;
    Label_Right: TLabel;
    Label_Top: TLabel;
    Panel_Top: TPanel;
    Panel_Main: TPanel;
    Panel_Bottom: TPanel;
    Timer1: TTimer;
    Timer2: TTimer;
    Timer3: TTimer;
    procedure BitBtn_ExitClick(Sender: TObject);
    procedure Chromium1AddressChange(Sender: TObject;
      const browser: ICefBrowser; const frame: ICefFrame; const url: ustring);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Label_LeftDblClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Timer3Timer(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

  CONFIG_KEY : String = '';
  CONFIG_URL : String = '';
  CONFIG_NAME : String = '';
  CONFIG_LOCK : String = '';
  CONFIG_PASSWORD : String = '';

  EXAM_URL: String = 'http://www.safeexamclient.com/login';
  EXAM_NAME: String = '安全考试客户端';
  EXAM_LOCK: String = '0';
  EXAM_LOCK_ON_KEY: String = '';
  EXAM_LOCK_OFF_KEY: String = '';
  EXAM_LOCK_PASSWORD: String = '123';
  EXAM_UI_TOP: String = '1';
  EXAM_UI_BOTTOM: String = '1';

  JSON_FLAG : boolean = false ;

procedure CreateGlobalCEFApp;
procedure ReadConfigFile;
function UnicodeToChinese(inputstr: string): string;
procedure StartLock();
procedure StopLock();

implementation

{$R *.lfm}

uses
  uFunction, uHook;

procedure CreateGlobalCEFApp;
begin
  GlobalCEFApp := TCefApplication.Create;
end;

{ TForm1 }

procedure TForm1.FormDestroy(Sender: TObject);
begin
  StopLock;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  //全屏无边框
  Form1.WindowState := wsMaximized;
  Form1.BorderStyle := bsNone;
  //Panel 显示样式
  Panel_Top.Align:=alTop;
  Panel_Top.Color:=clWhite;
  Panel_Top.BevelColor:=clSilver;
  Panel_Top.Height:=60;
  Panel_Bottom.Align:=alBottom;
  Panel_Bottom.Color:=clWhite;
  Panel_Bottom.BevelColor:=clSilver;
  Panel_Bottom.Height:=40;
  Panel_Main.Align:=alClient;
  Panel_Main.Color:=clWhite;
  Panel_Main.BevelColor:=clWhite;
  //Panel_Top 显示样式
  Label_Top.Caption:=EXAM_NAME;
  Label_Top.Font.Size:=16;
  Label_Top.Left:=20;
  Label_Top.Top:= round((Panel_Top.Height - Label_Top.Height) * 0.4);
  Label_Top.Font.Color:=$00505050;
  Label_Top.Font.Name:= 'Microsoft YaHei';
  //Panel_Bottom 显示样式
  Label_Left.Caption:='提示：考试过程全程锁屏';
  Label_Left.Font.Size:=9;
  Label_Left.Left:=20;
  Label_Left.Top:= round((Panel_Bottom.Height - Label_Left.Height)* 0.4);
  Label_Left.Font.Color:=clGray;
  Label_Left.Font.Name:= 'Microsoft YaHei';
  Label_Right.Caption:='Local：' + uFunction.Get_LocalIP();
  Label_Right.Font.Size:=9;
  Label_Right.Left:= (Panel_Bottom.Width - Label_Right.Width - 30);
  Label_Right.Top:= round((Panel_Bottom.Height - Label_Right.Height)* 0.4);
  Label_Right.Font.Color:=clGray;
  Label_Right.Font.Name:= 'Microsoft YaHei';
  //Panel_Main 显示样式
  CEFWindowParent1.Align:=alClient;
  //强制退出 UI
  Edit_Exit.Width:=64;
  Edit_Exit.Height:=28;
  Edit_Exit.Top:=round((Panel_Bottom.Height - Edit_Exit.Height)* 0.5);
  Edit_Exit.Left:= Label_Left.Left + Label_Left.Width + 20 ;
  Edit_Exit.MaxLength:=6;
  Edit_Exit.NumbersOnly:=true;
  BitBtn_Exit.Width:=64;
  BitBtn_Exit.Height:=28;
  BitBtn_Exit.Top:=Edit_Exit.Top-1;
  BitBtn_Exit.Left:=Edit_Exit.Left + Edit_Exit.Width + 10 ;
  BitBtn_Exit.Kind:=bkOK;
  Edit_Exit.Visible:=false;
  BitBtn_Exit.Visible:=false;
  //定时器
  Timer1.Interval:=1000;
  Timer1.Enabled:=true;
  Timer2.Interval:=1000;
  Timer2.Enabled:=false;
  Timer3.Interval:=5000;
  Timer3.Enabled:=true;
  //初始化
  Chromium1.CreateBrowser(CEFWindowParent1, '');
  Chromium1.Initialized;
  //读取INI
  ReadConfigFile;
end;

procedure TForm1.Label_LeftDblClick(Sender: TObject);
begin
  Edit_Exit.Visible := true;
  BitBtn_Exit.Visible := true;
  Edit_Exit.SetFocus;
end;

procedure ReadConfigFile;
var
  Inifile: TIniFile;
begin
  Inifile := TIniFile.Create(ExtractFilePath(ParamStr(0))+'Exam.ini');
  CONFIG_KEY := Inifile.ReadString('CONFIG', 'KEY', '');
  CONFIG_URL := Inifile.ReadString('CONFIG', 'URL', '');
  CONFIG_NAME := Inifile.ReadString('CONFIG', 'NAME', '');
  CONFIG_LOCK := Inifile.ReadString('CONFIG', 'LOCK', '');
  CONFIG_PASSWORD := Inifile.ReadString('CONFIG', 'PASSWORD', EXAM_LOCK_PASSWORD);
  //默认值
  if(trim(CONFIG_URL)='') then
   CONFIG_URL := EXAM_URL;
  if(trim(CONFIG_NAME)='') then
   CONFIG_NAME := EXAM_NAME;
  if(trim(CONFIG_LOCK)='') then
   CONFIG_LOCK := EXAM_LOCK;
  if(trim(CONFIG_LOCK)='ON') then
   CONFIG_LOCK := '1';
  if(trim(CONFIG_PASSWORD)='') then
   CONFIG_PASSWORD := EXAM_LOCK_PASSWORD;
  //释放资源
  Inifile.Free;
end;

//Timer1 - 用于窗体启动时打开默认网址
procedure TForm1.Timer1Timer(Sender: TObject);
begin
  //响应CONFIG_KEY
  if (length(CONFIG_KEY) = 6) then
     Chromium1.LoadURL(EXAM_URL+'/exam/'+CONFIG_KEY)
  else
     begin
        //响应CONFIG_URL
        Chromium1.LoadURL(CONFIG_URL);
        //响应CONFIG_NAME
        Label_top.Caption := CONFIG_NAME;
        //响应CONFIG_LOCK
        if(CONFIG_LOCK = '1')  then
        begin
          StartLock;
        end else
        begin
          StopLock;
        end;
     end;
  Timer1.Enabled:=false;
end;

//Timer2 - 用于隐藏JSON内容
procedure TForm1.Timer2Timer(Sender: TObject);
var
  curr_url:string;
  pos_key:Integer;
begin
  curr_url := Chromium1.DocumentURL;
  pos_key := Pos('login/exam', curr_url);
  //避免显示JSON源码
  if(pos_key = 0) then
  begin
    CEFWindowParent1.Visible:=true;
    Timer2.Enabled:=false;
  end;
end;

//Timer3 - 用于隐藏退出按钮
procedure TForm1.Timer3Timer(Sender: TObject);
begin
  Edit_Exit.Visible := false;
  BitBtn_Exit.Visible := false;
end;

procedure TForm1.Chromium1AddressChange(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame; const url: ustring);
var
  curr_url:string;
  pos_key:Integer;
  jData: TJSONData;
  jObject: TJSONObject;
  code: integer;
  json_string1, json_string2: string;
begin
  curr_url := Chromium1.DocumentURL;

  //监听1 - 登录口令 BEGIN
  pos_key := Pos('login/exam', curr_url);
  if(pos_key > 0) then
  begin
    //避免显示JSON
    Timer2.Enabled:=true;
    Timer2.Interval:=500;
    CEFWindowParent1.Visible:=false;
    //解析JSON
    try
      json_string1 := TFPCustomHTTPClient.SimpleGet(curr_url);
      json_string1 := StringReplace(json_string1, '\/', '/', [rfReplaceAll]);
      //这里要用新变量，否则会重复内容
      json_string2 := UnicodeToChinese(json_string1);
      jData := GetJSON(json_string2, false);
      jObject := TJSONObject(jData);
      code := jObject.Get('code');

      if(code = 1) then
        begin
          //获取JSON数据
          JSON_FLAG:= true;
          EXAM_URL:= jData.FindPath('data.exam_url').AsString;
          EXAM_NAME:= jData.FindPath('data.exam_name').AsString;
          EXAM_LOCK:= jData.FindPath('data.exam_lock').AsString;
          EXAM_LOCK_ON_KEY:= jData.FindPath('data.exam_lock_on_key').AsString;                        {待完善特征值}
          EXAM_LOCK_OFF_KEY:= jData.FindPath('data.exam_lock_off_key').AsString;                      {待完善特征值}
          EXAM_LOCK_PASSWORD:= jData.FindPath('data.exam_lock_password').AsString;
          EXAM_UI_TOP:= jData.FindPath('data.exam_ui_top').AsString;
          EXAM_UI_BOTTOM:= jData.FindPath('data.exam_ui_bottom').AsString;
          //响应JSON设置
          Chromium1.LoadURL(EXAM_URL);     //响应JSON考试网址
          Label_Top.Caption:=EXAM_NAME;    //响应JSON考试名称
          if(EXAM_LOCK = '1')  then        //响应JSON是否锁屏
          begin
            StartLock;
          end else
          begin
            StopLock;
          end;
          if(EXAM_UI_TOP = '0') then       //响应JSON顶部显示
            Panel_Top.Visible:=false;
          if(EXAM_UI_BOTTOM = '0') then    //响应JSON底部显示
            Panel_Bottom.Visible:=false;
        end
      else
        begin
             showmessage('提示：考试口令有误，找不到对应的考试信息，请重新输入');
             Chromium1.LoadURL(EXAM_URL);
        end;
    except
    on E: EHttpClient do
        begin
            showmessage('提示：网络连接故障，或远程服务器没有应答');
            Chromium1.LoadURL(EXAM_URL);
        end;
    end;

  end;
  //监听1 - 登录口令 END

  //监听2 - BEGIN
  pos_key := Pos(EXAM_LOCK_ON_KEY, curr_url);
  if((EXAM_LOCK_ON_KEY <> '') and (pos_key > 0)) then
  begin
    StartLock;
  end;
  //监听2 - END

  //监听3 - BEGIN
  pos_key := Pos(EXAM_LOCK_OFF_KEY, curr_url);
  if((EXAM_LOCK_OFF_KEY <> '') and (pos_key > 0)) then
  begin
    StopLock;
    showmessage('提示：已退出锁屏状态');
  end;
  //监听3 - END

end;

//强制退出
procedure TForm1.BitBtn_ExitClick(Sender: TObject);
var
  pwd : string;
begin
  pwd := CONFIG_PASSWORD;
  if(JSON_FLAG) then
    pwd := EXAM_LOCK_PASSWORD;
  if(Edit_Exit.Text = pwd) then
    Application.Terminate;
end;

function UnicodeToChinese(inputstr: string): string;
var
    index: Integer;
    temp, top, last: string;
begin
    index := 1;
    while index >= 0 do
    begin
        index := Pos('\u', inputstr) - 1;
        if index < 0 then
        begin
            last := inputstr;
            Result := Result + last;
            Exit;
        end;
        top := Copy(inputstr, 1, index); // 取出非编码
        temp := Copy(inputstr, index + 1, 6); // 取出编码如\u4e3f
        Delete(temp, 1, 2);
        Delete(inputstr, 1, index + 6);
        Result := Result + top + WideChar(StrToInt('$' + temp));
    end;
end;

//开始锁屏
procedure StartLock();
begin
  Form1.FormStyle:=fsSystemStayOnTop;
  uHook.HookStart;
end;

//停止锁屏
procedure StopLock();
begin
  Form1.FormStyle:=fsNormal;
  uHook.HookStop;
end;

end.

