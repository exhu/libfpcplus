program refobjtest;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, lfp_refobj_low, lfp_refobj
  { you can add units after this },
  sysutils;

{$R *.res}

var a,b : TRefObject;
    c : TRefObserver;
begin
  a := TRefObject.create;
  b := safeRetain(a);
  c := b.createRefObserver;
  writeln('hello');

  safeRelease(a);
  safeRelease(b);
  FreeAndNil(c);
end.

