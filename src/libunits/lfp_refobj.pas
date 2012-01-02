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
  IRefObject = interface
    function retain : TRefObject;
    function release : boolean; // returns true if pointer must be set to nil
    function createRefObserver : TRefObserver;
    function asTRefObject : TRefObject;
    function clone : TRefObject;
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
	  function retain : TRefObject;
	  function release : boolean; // returns true if object must be disposed
	  function createRefObserver : TRefObserver;
      function asTRefObject : TRefObject;
      function clone : TRefObject;
  end;


  function safeRetain(o : IRefObject) : TRefObject;inline;
  procedure safeRelease(o : IRefObject; var vo);
  procedure safeRelease(o : TRefObject; var vo);

implementation
uses sysutils;
const refObjectMagic = $13254769;

function safeRetain(o: IRefObject): TRefObject;
begin
  if o <> nil then
     exit(o.retain);

  result := nil;
end;

procedure safeRelease(o: IRefObject; var vo);
begin
  if o <> nil then
     begin
       if o.release then
          pointer(vo) := nil;
     end;
end;

procedure safeRelease(o: TRefObject; var vo);
begin
  if o <> nil then
     begin
       if o.release then
          pointer(vo) := nil;
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

function TRefObject.retain: TRefObject;
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

function TRefObject.asTRefObject: TRefObject;
begin
  result := self;
end;

function TRefObject.clone: TRefObject;
begin
  result := nil; // not supported
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

