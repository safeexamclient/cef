program Exam;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  uCEFApplication, //ChenGuang
  Forms, uMain, uFun, uHook, uConfig, uJson, uParameter
  { you can add units after this };

{$R *.res}

begin
    CreateGlobalCEFApp;
    if GlobalCEFApp.StartMainProcess then
      begin
        RequireDerivedFormResource:=True;
        Application.Scaled:=True;
        Application.Initialize;
        Application.CreateForm(TForm1, Form1);
        Application.Run;
      end;
    DestroyGlobalCEFApp;
end.

