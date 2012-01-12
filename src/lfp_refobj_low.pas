/// low-level implementation of a reference-counted pointer
unit lfp_refobj_low;

{$mode objfpc}{$H+}

interface

//uses
//  Classes, SysUtils;

type

    /// manager a pointer and counters of strong and weak references to it.

{ TRefStruct }
PRefStruct = ^TRefStruct;
TRefStruct = object
    protected
        p : pointer;
		strong : longint; // strong refs counter
		weak : longint; // weak refs counter

	public
        constructor init(pp : pointer);
		destructor done;

		function getPtr : pointer;inline;

		procedure incWeak;inline;
		procedure decWeak;inline;

        procedure incStrong;inline;
		procedure decStrong;inline;

        function mustFreePointer : boolean; // returns true if strong reaches zero
		function noRefsLeft : boolean; // returns true if strong = weak = 0 and this structure must be released
	end;


implementation

{ TRefStruct }

constructor TRefStruct.init(pp: pointer);
begin
  p := pp;
  strong := 1;
  weak := 0;
end;

destructor TRefStruct.done;
begin
end;

function TRefStruct.getPtr: pointer;
begin
  getPtr := p;
end;

procedure TRefStruct.incWeak;
begin
  inc(weak);
end;

procedure TRefStruct.decWeak;
begin
  dec(weak);
end;

procedure TRefStruct.incStrong;
begin
  inc(strong);
end;

procedure TRefStruct.decStrong;
begin
  dec(strong);
end;

function TRefStruct.mustFreePointer: boolean;
begin
  result := strong < 1;
end;

function TRefStruct.noRefsLeft: boolean;
begin
  result := (strong < 1) and (weak < 1);
end;

end.

