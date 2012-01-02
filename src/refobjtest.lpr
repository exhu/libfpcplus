program refobjtest;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, lfp_refobj
  { you can add units after this },
  sysutils;

{$R *.res}

var a: TRefObject;
    b: IRefObject;
    c : TRefObserver;
begin
  a := TRefObject.create;
  b := safeRetain(a);
  c := b.createRefObserver;
  writeln('hello');

  safeRelease(a,a);
  safeRelease(b,b);
  FreeAndNil(c);
end.

