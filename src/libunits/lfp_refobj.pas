unit lfp_refobj;

{$mode objfpc}{$H+}
{$interfaces corba}
{assertions on}
{M+}
interface

//uses
//  Classes, SysUtils;

type
  TRefObject = class;
  TRefObserver = class;

  /// base for your interfaces, so that cast to TRefObject can always be made.
  IRefObject = interface ['IRefObject']
    function retain : IRefObject;
    function release : boolean; // returns true if pointer must be set to nil
    function createRefObserver : TRefObserver;
    function asTObject : TObject;
  end;

  /// sets pointer to TRefObject to nil when reference counter = 0
  /// usage:
  /// b := TRefObject.create;
  /// c := safeRetain(b);
  /// a := b.createRefObserver;
  /// a.getTRefObject.dosmth;
  /// FreeAndNil(a);
  /// safeRelease(b,b);
  /// safeRelease(c,c);

  { TRefCounter }
  /// manages the references, used internally
  TRefCounter = class
  private
    strong, weak : longint;
    f_iobj : IRefObject;

  public
    constructor Create(o : IRefObject);

    // thread-safe
    procedure incStrong;inline;
    procedure decStrong;inline;
    procedure incWeak;inline;
    procedure decWeak;inline;

    function tryFreeObj : boolean;inline; // true if freed

    /// true if strong < 1
    function mustFreeIOBJ : boolean;

    /// true if both weak and strong < 1
    function noRefsLeft : boolean;

    property iObj : IRefObject read f_iobj;
  end;


  { TRefObserver }

  TRefObserver = class
    public
      function iref : IRefObject;inline;
      function obj : TObject;inline;

      function getIRefObject : IRefObject;

      destructor Destroy; override;

    //protected
      constructor create(p : TRefCounter);

    private
      refcounter : TRefCounter;

  end;


  { TRefObject }

  TRefObject = class(IRefObject)
    private
      refcounter : TRefCounter;
      magic : integer; // magic number to identify on safeRelease
    public
      constructor create;
	  destructor destroy;override;

    public
      { IRefObject }
	  function retain : IRefObject;
	  function release : boolean; // returns true if object must be disposed
	  function createRefObserver : TRefObserver;
      function asTObject : TObject;
  end;


  function safeRetain(o : IRefObject) : IRefObject;inline;

  /// calls release (if not nil) and assigns nil to the variable
  /// fpc 2.6 does not allow to pass derived classes as var arguments,
  /// so we have to duplicate as untyped.
  procedure safeRelease(o : IRefObject; var vartonil);

implementation
uses sysutils;
const refObjectMagic = $13254769;

function safeRetain(o: IRefObject): IRefObject;
begin
  if o <> nil then
     exit(o.retain);

  result := nil;
end;

procedure safeRelease(o: IRefObject; var vartonil);
begin
  if o <> nil then
     begin
       o.release;
     end;
  pointer(vartonil) := nil;
end;

{ TRefCounter }

constructor TRefCounter.Create(o: IRefObject);
begin
  f_iobj := o;
  strong := 1;
  weak := 0;
end;

procedure TRefCounter.incStrong;
begin
  if ismultithread then
    interlockedIncrement(strong)
  else
    inc(strong);
end;

procedure TRefCounter.decStrong;
begin
  if ismultithread then
    InterLockedDecrement(strong)
  else
    dec(strong);
end;

procedure TRefCounter.incWeak;
begin
  if ismultithread then
    InterLockedIncrement(weak)
  else
    inc(weak);
end;

procedure TRefCounter.decWeak;
begin
  if ismultithread then
    InterLockedDecrement(weak)
  else
    dec(weak);
end;

function TRefCounter.tryFreeObj: boolean;
begin
  if mustFreeIOBJ then
     begin
       f_iobj.asTObject.Free;
       f_iobj := nil;
       exit(true);
     end;

  result := false;
end;


function TRefCounter.mustFreeIOBJ: boolean;
begin
  result := strong < 1;
end;

function TRefCounter.noRefsLeft: boolean;
begin
  result := (strong < 1) and (weak < 1);
end;


{
procedure safeRelease(var o);
var
  p : pointer;
  obj : IRefObject;
begin
  p := pointer(o);
  if p <> nil then
     begin
       obj := IRefObject(p);
       Assert(obj.asTRefObject.magic = refObjectMagic, 'Not an IRefObject');
       if obj.release then
          pointer(o) := nil;

     end;
end;
}

{ TRefObject }

constructor TRefObject.create;
begin
  inherited create;
  refcounter := TRefCounter.create(self);
  magic := refObjectMagic;
end;

destructor TRefObject.destroy;
begin
  if refcounter.noRefsLeft then
      FreeAndNil(refcounter);

  magic := 0;
  inherited destroy;
end;

function TRefObject.retain: IRefObject;
begin
  refcounter.incStrong;
  result := self;
end;

function TRefObject.release: boolean;
begin
  refcounter.decStrong;
  result := refcounter.tryFreeObj;
end;

function TRefObject.createRefObserver: TRefObserver;
begin
  result := TRefObserver.create(refcounter);
end;

function TRefObject.asTObject: TObject;
begin
  result := self;
end;

{ TRefObserver }

function TRefObserver.iref: IRefObject;
begin
  result := refcounter.iObj;
end;

function TRefObserver.obj: TObject;
begin
  result := refcounter.iObj.asTObject;
end;

function TRefObserver.getIRefObject: IRefObject;
begin
  exit(refcounter.iObj);
end;

destructor TRefObserver.Destroy;
begin
 refcounter.decWeak;
 if refcounter.noRefsLeft then
    FreeAndNil(refcounter);
  inherited Destroy;
end;

constructor TRefObserver.create(p: TRefCounter);
begin
  inherited create;
  refcounter := p;
  refcounter.incWeak;
end;

end.

