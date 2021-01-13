unit uJson;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  fpjson, fphttpclient;

procedure ReadJSONString(theurl:string);
function UnicodeToChinese(inputstr: string): string;

var
   //主要参数
   exam_url: String = '';
   exam_name: String = '';
   //锁屏参数
   exam_lock: String = '';
   exam_lock_on_key: String = '';
   exam_lock_off_key: String = '';
   exam_lock_password: String = '';
   //界面参数
   exam_ui_top: String = '';
   exam_ui_bottom: String = '';
   exam_ui_buttom_left_text: String = '';
   exam_ui_buttom_right_text: String = '';

implementation

procedure ReadJSONString(theurl:string);
var
  jData: TJSONData;
  jObject: TJSONObject;
  temp1,temp2: string;
begin
  try
    //得到unicode的json字符串
    temp1 := TFPCustomHTTPClient.SimpleGet(theurl);
    //把反斜杠替换一下
    temp1:= StringReplace(temp1, '\/', '/', [rfReplaceAll]);
    //把unicode转成中文
    temp2:= UnicodeToChinese(temp1);
    //读取相关的值
    jData := GetJSON(temp2, false);
    jObject := TJSONObject(jData);
    //主要参数
    exam_url := jObject.Get('exam_url');
    exam_name := jObject.Get('exam_name');
    //锁屏参数
    exam_lock := jObject.Get('exam_lock');
    exam_lock_on_key:= jObject.Get('exam_lock_on_key');
    exam_lock_off_key:= jObject.Get('exam_lock_off_key');
    exam_lock_password:= jObject.Get('exam_lock_password');
    //界面参数
    exam_ui_top:= jObject.Get('exam_ui_top');
    exam_ui_bottom:= jObject.Get('exam_ui_bottom');
    exam_ui_buttom_left_text:= jObject.Get('exam_ui_buttom_left_text');
    exam_ui_buttom_right_text:= jObject.Get('exam_ui_buttom_right_text');
  except
    on E: EHttpClient do
    //Memo1.Append(e.message)
  end;
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
        top := Copy(inputstr, 1, index); // 取出 编码字符前的 非 unic 编码的字符，如数字
        temp := Copy(inputstr, index + 1, 6); // 取出编码，包括 \u,如\u4e3f
        Delete(temp, 1, 2);
        Delete(inputstr, 1, index + 6);
        Result := Result + top + WideChar(StrToInt('$' + temp));
    end;
end;

end.

