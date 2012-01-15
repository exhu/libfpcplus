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
  IRefObject = interface
    ['IRefObject']
    function Retain: IRefObject;
    function Release: boolean; // returns true if pointer must be set to nil
    function CreateRefObserver: TRefObserver;
    function AsTObject: TObject;
  end;

  /// sets pointer to TRefObject to nil when reference counter = 0
  /// usage:
  /// b := TRefObject.create;
  /// c := safeRetain(b);
  /// a := b.createRefObserver;
  /// t := a.getIRefObjectRetained;
  /// t.dosmth;
  /// safeRelease(t);
  /// FreeAndNil(a);
  /// safeRelease(b,b);
  /// safeRelease(c,c);

  { TRefCounter }
  /// manages the references, used internally
  TRefCounter = class
  private
    strong, weak: longint;
    f_iobj: IRefObject;

  public
    constructor Create(o: IRefObject);

    // thread-safe
    procedure IncStrong; inline;
    procedure DecStrong; inline;
    procedure IncWeak; inline;
    procedure DecWeak; inline;

    function TryFreeObj: boolean; inline; // true if freed

    /// true if strong < 1
    function MustFreeIOBJ: boolean; inline;

    /// true if both weak and strong < 1
    function NoRefsLeft: boolean; inline;

    property iObj: IRefObject read f_iobj;
  end;


  { TRefObserver }

  TRefObserver = class
  public
    function Valid: boolean;
    function GetIRefObjectRetained: IRefObject;

    destructor Destroy; override;

    //protected
    constructor Create(p: TRefCounter);

  private
    refcounter: TRefCounter;

  end;


  { TRefObject }

  TRefObject = class(IRefObject)
  private
    refcounter: TRefCounter;
    magic: integer; // magic number to identify on safeRelease
  public
    constructor Create;
    destructor Destroy; override;

  public
    { IRefObject }
    function Retain: IRefObject; virtual;
    function Release: boolean; virtual; // returns true if object must be disposed
    function CreateRefObserver: TRefObserver; virtual;
    function AsTObject: TObject; virtual;
  end;


  { TRefHolder }

  TRefHolder = class(TRefObject, IRefObject)
    constructor Create(AObj: TObject);
    function AsTObject: TObject; override;

  private
    obj: TObject;
  end;


function SafeRetain(o: IRefObject): IRefObject; inline;

/// calls release (if not nil) and assigns nil to the variable
/// fpc 2.6 does not allow to pass derived classes as var arguments,
/// so we have to duplicate as untyped.
procedure SafeRelease(o: IRefObject; var vartonil);

implementation

uses SysUtils;

const
  refObjectMagic = $13254769;

function SafeRetain(o: IRefObject): IRefObject;
begin
  if o <> nil then
    exit(o.retain);

  Result := nil;
end;

procedure SafeRelease(o: IRefObject; var vartonil);
begin
  if o <> nil then
  begin
    o.Release;
  end;
  pointer(vartonil) := nil;
end;

{ TRefHolder }

constructor TRefHolder.Create(AObj: TObject);
begin
  inherited Create;
  obj := AObj;
end;

function TRefHolder.AsTObject: TObject;
begin
  Result := obj;
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
  //if ismultithread then
  interlockedIncrement(strong);
  //else
  //  inc(strong);
end;

procedure TRefCounter.decStrong;
begin
  //if ismultithread then
  InterLockedDecrement(strong);
  //else
  //  dec(strong);
end;

procedure TRefCounter.incWeak;
begin
  //if ismultithread then
  InterLockedIncrement(weak);
  //else
  //  inc(weak);
end;

procedure TRefCounter.decWeak;
begin
  //if ismultithread then
  InterLockedDecrement(weak);
  //else
  //  dec(weak);
end;

function TRefCounter.TryFreeObj: boolean;
var
  tmp_obj: IRefObject;
begin
  if mustFreeIOBJ then
  begin
    tmp_obj := f_iobj;
    f_iobj := nil;
    tmp_obj.asTObject.Free;
    exit(True);
  end;

  Result := False;
end;


function TRefCounter.MustFreeIOBJ: boolean;
begin
  Result := strong < 1;
end;

function TRefCounter.NoRefsLeft: boolean;
begin
  Result := (strong < 1) and (weak < 1);
end;


{ TRefObject }

constructor TRefObject.Create;
begin
  inherited Create;
  refcounter := TRefCounter.Create(self);
  magic := refObjectMagic;
end;

destructor TRefObject.Destroy;
begin
  if refcounter.noRefsLeft then
    FreeAndNil(refcounter);

  magic := 0;
  inherited Destroy;
end;

function TRefObject.Retain: IRefObject;
begin
  refcounter.incStrong;
  Result := self;
end;

function TRefObject.Release: boolean;
begin
  refcounter.decStrong;
  Result := refcounter.tryFreeObj;
end;

function TRefObject.CreateRefObserver: TRefObserver;
begin
  Result := TRefObserver.Create(refcounter);
end;

function TRefObject.AsTObject: TObject;
begin
  Result := self;
end;

{ TRefObserver }

function TRefObserver.Valid: boolean;
begin
  Result := refcounter.iObj <> nil;
end;

function TRefObserver.GetIRefObjectRetained: IRefObject;
begin
  Result := safeRetain(refcounter.iObj);
end;

destructor TRefObserver.Destroy;
begin
  refcounter.decWeak;
  if refcounter.noRefsLeft then
    FreeAndNil(refcounter);
  inherited Destroy;
end;

constructor TRefObserver.Create(p: TRefCounter);
begin
  inherited Create;

  Assert(p <> nil);

  refcounter := p;
  refcounter.incWeak;
end;

end.

