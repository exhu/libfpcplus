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

type

  { TMyRefCls }

  TMyRefCls = class(TRefObject)
    procedure sayHello;
  end;



var a: TMyRefCls;
    b: IRefObject;
    c : TRefObserver;
    o : TObject;
    io : IRefObject;

{ TMyRefCls }

procedure TMyRefCls.sayHello;
begin
  writeln('hello');
end;

begin
  a := TMyRefCls.create;
  b := safeRetain(a);
  c := b.createRefObserver;

  safeRelease(a,a);
  io := c.getIRefObject;
  o := io.asTObject;
  (o as TMyRefCls).sayHello;
  safeRelease(b,b);
  writeln('Is TMyRefCls alive? ', boolean(ptrint(c.getIRefObject)));
  FreeAndNil(c);
end.

