unit uFunction;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Messages, Dialogs, Classes, Windows, Winsock, StrUtils;

function Get_LocalIP():String;

implementation

//得到本地机器的IP，若有多个IP，只取第一个
function Get_LocalIP():String;
type
  TaPInAddr = array [0..10] of PInAddr;
  PaPInAddr = ^TaPInAddr;
var
  phe : PHostEnt;
  pptr : PaPInAddr;
  Buffer : array [0..63] of char;
  I : Integer;
  GInitData : TWSADATA;
begin
  WSAStartup($101, GInitData);
  Result := ' ';
  GetHostName(Buffer, SizeOf(Buffer));
  phe :=GetHostByName(buffer);
  if phe = nil then Exit;
  pptr := PaPInAddr(Phe^.h_addr_list);
  I := 0;
  while pptr^[I] <> nil do begin
  if i=0
  then result:=StrPas(inet_ntoa(pptr^[I]^))
  else result:=result+ ', '+StrPas(inet_ntoa(pptr^[I]^));
  Inc(I);
  end;
  WSACleanup;
  //主机名 phe.h_name
  //此时的 result 可能是多个IP的，如 192.168.0.1,192.168.78.1
  if pos(',', result) > 0 then
    result := LeftStr(result, pos(',', result)-1);
end;


end.


