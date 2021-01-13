unit uParameter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

procedure SetParameter;

var
   P_URL_ADD_KEY: String;
   P_LEFT_TEXT: String;
   P_LEFT_EXIT_TEXT: String;
   P_LOGIN_URL_KEY: String;

implementation

procedure SetParameter();
begin
  //后面加KEY就能拼接URL
  P_URL_ADD_KEY          := 'http://www.safeexamclient.com/login/exam/';
  P_LEFT_TEXT            := '提示：考试过程全程锁屏';
  P_LEFT_EXIT_TEXT       := '提示：您真的要退出考试吗？';
  //判断变化后的网址是否含有特征字符
  P_LOGIN_URL_KEY        := 'www.safeexamclient.com/login/exam';

end;


end.

