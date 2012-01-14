program refobjtest;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes,
  sysutils,
  lfp_refobj;

{$R *.res}

type

  IMy1 = interface(IRefObject)
       procedure say1;
  end;

  IMy2 = interface(IRefObject)
       procedure say2;
  end;

  { TMyRefCls }

  TMyRefCls = class(TRefObject, IMy1, IMy2)
    procedure sayHello;
    procedure say1;
    procedure say2;
  end;

  { TTestHolder }

  TTestHolder = class(IRefObject)
    private
      fholder : TRefHolder;


    public
      constructor create;
      destructor destroy;override;
      property holder : TRefHolder read fholder implements IRefObject;
  end;


var a: TMyRefCls;
    b: IRefObject;
    c : TRefObserver;
    o : TObject;
    io : IRefObject;
    i1 : IMy1;
    i2 : IMy2;
    holder : TTestHolder;

constructor TTestHolder.create;
begin
  inherited create;

  fholder := TRefHolder.create(self);
end;

destructor TTestHolder.destroy;
begin
  holder.Free;
  inherited destroy;
end;

{ TMyRefCls }

procedure TMyRefCls.sayHello;
begin
  writeln('hello');
end;

procedure TMyRefCls.say1;
begin
  writeln('say1');
end;

procedure TMyRefCls.say2;
begin
  writeln('say2');
end;

begin
  a := TMyRefCls.create;
  b := safeRetain(a);
  i1 := a;
  safeRetain(i1);
  i2 := a;

  writeln('i1 = ', ptrint(i1), ' i2 = ', ptrint(i2));

  i1.say1;
  i2.say2;

  safeRelease(i1, i1);
  c := b.createRefObserver;

  safeRelease(a,a);
  io := c.getIRefObjectRetained;
  o := io.asTObject;
  (o as TMyRefCls).sayHello;
  safeRelease(b,b);
  writeln('Is TMyRefCls alive? ', c.valid);

  safeRelease(io,io);
  writeln(c.valid);
  FreeAndNil(c);

  holder := TTestHolder.create;
  io := holder.holder;
  writeln('io = ', ptrint(io));
  io.retain;
  io.release;
  io.release;
end.

