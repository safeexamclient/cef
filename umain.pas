unit uMain;

{$mode objfpc}{$H+}

{$I cef.inc}  //ChenGuang

interface

uses
  Windows, Messages, Variants, Menus,
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, uCEFChromium, uCEFWindowParent, uCEFInterfaces, uCEFApplication , uCEFChromiumEvents, uCEFTypes;

type

  { TForm1 }

  TForm1 = class(TForm)
    BitBtn_Exit: TBitBtn;
    CEFWindowParent1: TCEFWindowParent;
    Chromium1: TChromium;
    Edit_Exit: TEdit;
    Label_Top: TLabel;
    Label_Left: TLabel;
    Label_Right: TLabel;
    Panel_Main: TPanel;
    Panel_Top: TPanel;
    Panel_Bottom: TPanel;
    Timer1: TTimer;
    Timer2: TTimer;
    Timer3: TTimer;
    //系统事件
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Timer3Timer(Sender: TObject);
    //自定义事件
    procedure BitBtn_ExitClick(Sender: TObject);
    procedure Label_LeftDblClick(Sender: TObject);
    //CEF屏蔽右键
    procedure  Chromium1BeforeContextMenu(Sender: TObject;
      const browser: ICefBrowser;
      const frame: ICefFrame;
      const params: ICefContextMenuParams;
      const model: ICefMenuModel);
    //CEF地址改变
    procedure Chromium1AddressChange(Sender: TObject;
      const browser: ICefBrowser; const frame: ICefFrame; const url: ustring);

  private

  public

  end;

var
  Form1: TForm1;
  JSON_FLAG : boolean = false ;
  procedure CreateGlobalCEFApp;
  procedure StartLock;
  procedure StopLock;

implementation

{$R *.lfm}

uses
  uFun, uHook, uConfig, uJson, uParameter;

//创建全局变量后方可使用CEF
procedure CreateGlobalCEFApp;
begin
  GlobalCEFApp := TCefApplication.Create;
end;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  //Timer1用于显示考试网址
  Timer1.Interval:=1000;
  Timer1.Enabled:=true;
  //Timer2用于隐藏退出按钮
  Timer2.Interval:=5000;
  Timer2.Enabled:=true;
  //Timer3用于监控当前网址变化
  Timer3.Interval:=1000;
  Timer3.Enabled:=true;
  //全屏显示
  Self.WindowState:=wsMaximized;   //最大化
  Self.BorderStyle:=bsNone;        //无边框
  //上中下Panel样式
  Panel_Top.Color:=clWhite;
  Panel_Top.BevelColor:=clSilver;
  Panel_Top.Height:=60;
  Panel_Bottom.Color:=clWhite;
  Panel_Bottom.BevelColor:=clSilver;
  Panel_Bottom.Height:=40;
  Panel_Main.Color:=clWhite;
  Panel_Main.BevelColor:=clWhite;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  //必须要先创建
  Chromium1.CreateBrowser(CEFWindowParent1, '');
  Chromium1.Initialized;
  //读取初始化常量
  uParameter.SetParameter;
  //读取本地配置文件
  uConfig.ReadConfigFile;
  //判断本地锁屏参数
  if(uConfig.LOCK = 'ON') then
  begin
    StartLock;
  end;
  //顶部文字
  Label_Top.Caption:= uConfig.NAME;
  Label_Top.Font.Size:=16;
  Label_Top.Left:=20;
  Label_Top.Top:= round((Panel_Top.Height - Label_Top.Height) * 0.4);
  Label_Top.Font.Color:=$00505050;
  Label_Top.Font.Name:= 'Microsoft YaHei';
  //左边文字
  Label_Left.Caption:=uParameter.P_LEFT_TEXT;
  Label_Left.Font.Size:=9;
  Label_Left.Left:=20;
  Label_Left.Top:= round((Panel_Bottom.Height - Label_Left.Height)* 0.4);
  Label_Left.Font.Color:=clGray;
  Label_Left.Font.Name:= 'Microsoft YaHei';
  //右边文字
  Label_Right.Caption:='Local：'+uFun.Get_LocalIP();
  Label_Right.Font.Size:=9;
  Label_Right.Left:= (Panel_Bottom.Width - Label_Right.Width - 50);
  Label_Right.Top:= round((Panel_Bottom.Height - Label_Right.Height)* 0.4);
  Label_Right.Font.Color:=clGray;
  Label_Right.Font.Name:= 'Microsoft YaHei';
  //退出按钮
  BitBtn_Exit.Visible:=false;
  Edit_Exit.Visible:=false;

end;

//双击左下方文字，显示退出按扭
procedure TForm1.Label_LeftDblClick(Sender: TObject);
begin
  Label_Left.Caption:=uParameter.P_LEFT_EXIT_TEXT;
  //设置大小
  BitBtn_Exit.Height:=28;
  BitBtn_Exit.Width:=65;
  Edit_Exit.Height:=28;
  Edit_Exit.Width:=60;
  //设置位置
  Edit_Exit.Visible:=true;
  Edit_Exit.Top:=round((Panel_Bottom.Height - BitBtn_Exit.Height)* 0.5);
  Edit_Exit.Left := (Label_Left.Left + Label_Left.Width + 10);
  BitBtn_Exit.Visible:=true;
  BitBtn_Exit.Top:= Edit_Exit.Top;
  BitBtn_Exit.Left := Edit_Exit.Left + 70;
  //获取焦点
  Edit_Exit.SetFocus;
end;

//窗体销毁
procedure TForm1.FormDestroy(Sender: TObject);
begin
  //停止锁屏
  uHook.HookStop;
end;

//退出系统
procedure TForm1.BitBtn_ExitClick(Sender: TObject);
begin
  //如果JSON
  if(JSON_FLAG = true) then
  begin
    if(Edit_Exit.Text = uJson.exam_lock_password) then
    begin
         Application.Terminate;
    end;
  end;
  //如果CONFIG
  if(JSON_FLAG = false) then
  begin
    if(Edit_Exit.Text = uConfig.PASSWORD) then
    begin
         Application.Terminate;
    end;
  end;
end;

//当网址改变的时候，读取并处理Json内容
procedure TForm1.Chromium1AddressChange(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame; const url: ustring);
var
  curr_url:string;  //当前网页URL
  pos_key:Integer;  //查询关键词的位置
begin
  curr_url := Chromium1.DocumentURL;
  pos_key := Pos(uParameter.P_LOGIN_URL_KEY, curr_url);
  if(pos_key > 0) then
  begin
    uJson.ReadJSONString(curr_url);
    //响应 Json 里的 exam_name
    Label_Top.Caption:=uJson.exam_name;
    //响应 Json 里的 exam_url
    Chromium1.LoadURL(uJson.exam_url);
    //响应 Json 里的 exam_lock
    if(uJson.exam_lock = '1') then
    begin
      StartLock;
    end;
    if(uJson.exam_lock = '0') then
    begin
      StopLock;
    end;
    //响应 Json 里的 exam_ui_top
    if(NOT(uJson.exam_ui_top = '1')) then
    begin
      Panel_Top.Visible:=false;
    end;
    //响应 Json 里的 exam_ui_bottom
    if(NOT(uJson.exam_ui_bottom = '1')) then
    begin
      Panel_Bottom.Visible:=false;
    end;
    //响应 Json 里的 exam_ui_buttom_left_text
    if(NOT(uJson.exam_ui_buttom_left_text = '')) then
    begin
      Label_Left.Caption := uJson.exam_ui_buttom_left_text;
    end;
    //响应 Json 里的 exam_ui_buttom_right_text
    if(NOT(uJson.exam_ui_buttom_right_text = '')) then
      Label_Right.Caption := uJson.exam_ui_buttom_right_text
    else
      Label_Right.Caption := 'Local：'+uFun.Get_LocalIP();
    //若内容被JSON重新定义，则需修正位置
    Label_Right.Left:= (Panel_Bottom.Width - Label_Right.Width - 30);
    //当前是JSON
    JSON_FLAG := true;
  end;
end;

//打开指定网页
procedure TForm1.Timer1Timer(Sender: TObject);
begin
  //CreateBrowser后需要点时间，故等1秒后打开
  if(Length(uConfig.KEY) > 5) then
      //从配置文件中读取密钥
      Chromium1.LoadURL(uParameter.P_URL_ADD_KEY + uConfig.KEY)
  else
      //从配置文件中读取网址
      Chromium1.LoadURL(uConfig.URL);
  Timer1.Enabled:=false;
  //右侧显示在WIN7下显示有误，故微调纠正
  Label_Right.Left:= (Panel_Bottom.Width - Label_Right.Width - 30);
end;

//隐藏退出按钮
procedure TForm1.Timer2Timer(Sender: TObject);
begin
  if(uJson.exam_ui_buttom_left_text = '') then
      Label_Left.Caption:=uParameter.P_LEFT_TEXT
  else
      Label_Left.Caption:=uJson.exam_ui_buttom_left_text;
  Edit_Exit.Visible:=false;
  BitBtn_Exit.Visible:=false;
end;

//屏蔽浏览器区域的右键
procedure TForm1.Chromium1BeforeContextMenu(Sender: TObject;
  const browser: ICefBrowser;
  const frame: ICefFrame;
  const params: ICefContextMenuParams;
  const model: ICefMenuModel);
begin
  model.Clear;
end;

//响应Json里的 exam_lock_on_key 和 exam_lock_off_key 参数
procedure TForm1.Timer3Timer(Sender: TObject);
var
  curr_url:string;  //当前网页URL
  pos_key:Integer;  //查询关键词的位置
begin
  //监控当前网址变化
  curr_url := Chromium1.DocumentURL;
  //开启
  if(NOT(uJson.exam_lock_on_key = '')) then
    begin
    pos_key := Pos(uJson.exam_lock_on_key, curr_url);
    if(pos_key > 0) then
    begin
      StartLock;
    end;
  end;
  //关闭
  if(NOT(uJson.exam_lock_off_key = '')) then
  begin
    pos_key := Pos(uJson.exam_lock_off_key, curr_url);
    if(pos_key > 0) then
    begin
      StopLock;
    end;
  end;
end;

//开始锁屏
procedure StartLock();
begin
  //置于顶部
  Form1.FormStyle:=fsSystemStayOnTop;
  //启动锁屏
  uHook.HookStart;
end;

//停止锁屏
procedure StopLock();
begin
  Form1.FormStyle:=fsNormal;
  uHook.HookStop;
end;

end.

