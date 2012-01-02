unit lfp_refobj;

{$mode objfpc}{$H+}
{$interfaces corba}
{assertions on}

interface

uses
  lfp_refobj_low;
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
  { TRefObserver }

  TRefObserver = class
    public
      function getTRefObject : TRefObject;

      destructor Destroy; override;

    //protected
      constructor create(p : PRefStruct);

    private
      refstruct : PRefStruct;

  end;


  { TRefObject }

  TRefObject = class(IRefObject)
    private
      refstruct : PRefStruct;
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
       if o.release then
          pointer(vartonil) := nil;
     end;
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
  new(refstruct, init(self));
  magic := refObjectMagic;
end;

destructor TRefObject.destroy;
begin
  if refstruct^.noRefsLeft then
      dispose(refstruct, done);

  magic := 0;
  inherited destroy;
end;

function TRefObject.retain: IRefObject;
begin
  refstruct^.incStrong;
  result := self;
end;

function TRefObject.release: boolean;
begin
  refstruct^.decStrong;
  if refstruct^.mustFreePointer then
     begin
       Free;
       exit(true);
     end;

  result := false;
end;

function TRefObject.createRefObserver: TRefObserver;
begin
  result := TRefObserver.create(refstruct);
end;

function TRefObject.asTObject: TObject;
begin
  result := self;
end;

{ TRefObserver }

function TRefObserver.getTRefObject: TRefObject;
begin
  if refstruct <> nil then
     exit(TRefObject(refstruct^.getPtr));

  result := nil;
end;

destructor TRefObserver.Destroy;
begin
  //if (refstruct <> nil) then
  //begin
     refstruct^.decWeak;
     if refstruct^.noRefsLeft then
        dispose(refstruct, done);
  //end;

  inherited Destroy;
end;

constructor TRefObserver.create(p: PRefStruct);
begin
  refstruct := p;
  refstruct^.incWeak;
end;

end.

