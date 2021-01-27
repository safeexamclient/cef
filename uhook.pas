unit uHook;

{$mode objfpc}{$H+}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Controls, Forms,
  Dialogs, StdCtrls, Registry;
type
  tagKBDLLHOOKSTRUCT = packed record
    vkCode : DWORD;
    scanCode : DWORD;
    flags : DWORD;
    time : DWORD;
    dwExtraInfo : DWORD;
  end;
  KBDLLHOOKSTRUCT = tagKBDLLHOOKSTRUCT;
  PKBDLLHOOKSTRUCT = ^KBDLLHOOKSTRUCT;

const
  WH_KEYBOARD_LL = 13;
  LLKHF_ALTDOWN = $20;

  procedure HookStart;                       //启动键盘钩子
  procedure HookStop;                        //停止键盘钩子
  function LowLevelKeyboardProc(nCode: Integer; wParam: WPARAM; lParam: LPARAM) : LRESULT; stdcall;  //键盘钩子

var
  hhkLowLevelKybd:HHOOK;

implementation

//开始键盘勾子
procedure HookStart;
begin
  if hhkLowLevelKybd=0 then
    hhkLowLevelKybd:=SetWindowsHookExW(WH_KEYBOARD_LL,@LowLevelKeyboardProc, Hinstance,0);
end;

//停止键盘勾子
procedure HookStop;
begin
  if (hhkLowLevelKybd<>0) and UnhookWindowsHookEx(hhkLowLevelKybd) then
   hhkLowLevelKybd:=0;
end;

//低级键盘勾子
function LowLevelKeyboardProc(nCode: Integer;wParam: WPARAM;lParam: LPARAM):LRESULT; stdcall;
var
  fEatKeystroke :   BOOL;
  p : PKBDLLHOOKSTRUCT;
begin
  Result:=0;
  fEatKeystroke:=FALSE;
  p:=PKBDLLHOOKSTRUCT(lParam);
  if (nCode=HC_ACTION) then
  begin
     //if(p^.vkCode=VK_TAB) then showmessage('按的是VK_TAB');
     case wParam of
      WM_KEYDOWN,
      WM_SYSKEYDOWN,
      WM_KEYUP,
      WM_SYSKEYUP:
      fEatKeystroke:=
        ((p^.vkCode=VK_TAB) and ((p^.flags and LLKHF_ALTDOWN) <> 0)) or
        ((p^.vkCode=VK_ESCAPE) and ((p^.flags and LLKHF_ALTDOWN) <> 0))or
        ((p^.vkCode=VK_Lwin) and (p^.vkCode=68))or
        ((p^.vkCode=VK_Rwin) and (p^.vkCode=68))or
        (p^.vkCode=VK_F7) or
        (p^.vkCode=VK_F8) or
        (p^.vkCode=VK_F9) or
        (p^.vkCode=VK_F10) or
        (p^.vkCode=VK_F11) or
        (p^.vkCode=VK_F12) or
        (p^.vkCode=VK_Lwin) or
        (p^.vkCode=VK_Rwin) or
        (p^.vkCode=VK_apps) or
        ((p^.vkCode=VK_ESCAPE) and ((GetKeyState(VK_CONTROL) and $8000) <> 0)) or
        ((p^.vkCode=VK_F4) and ((p^.flags and LLKHF_ALTDOWN) <> 0)) or
        ((p^.vkCode=VK_SPACE) and ((p^.flags and LLKHF_ALTDOWN) <> 0)) or
        (((p^.vkCode=VK_CONTROL) and (p^.vkCode = LLKHF_ALTDOWN and p^.flags) and (p^.vkCode=VK_Delete)))
    end;
  end;
  if fEatKeystroke=True then
    Result:=1;
  if nCode <> 0 then
    Result := CallNextHookEx(0,nCode,wParam,lParam);
end;

end.

