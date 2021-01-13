unit uConfig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles;

procedure ReadConfigFile;

var
   KEY: String;
   URL: String;
   NAME: String;
   LOCK: String;
   PASSWORD: String;

implementation

procedure ReadConfigFile();
var
  Inifile: TIniFile;
begin
  //读取参数
  Inifile := TIniFile.Create(ExtractFilePath(ParamStr(0))+'Exam.ini');
  KEY := Inifile.ReadString('CONFIG', 'KEY', '');
  URL := Inifile.ReadString('CONFIG', 'URL', '');
  NAME := Inifile.ReadString('CONFIG', 'NAME', '');
  LOCK := Inifile.ReadString('CONFIG', 'LOCK', '');
  PASSWORD := Inifile.ReadString('CONFIG', 'PASSWORD', '');
  //默认值（上面的第3个参数就是默认值，但不准确）
  if(trim(URL)='') then
   URL := 'http://www.safeexamclient.com/login';
  if(trim(NAME)='') then
   NAME := '安全考试客户端';
  if(trim(LOCK)='') then
   LOCK := 'OFF';
  //释放资源
  Inifile.Free;
end;


end.

