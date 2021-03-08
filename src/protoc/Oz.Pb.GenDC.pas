(* Protocol buffer code generator, for Delphi
 * Copyright (c) 2020 Marat Shaimardanov
 *
 * This file is part of Protocol buffer code generator, for Delphi
 * is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this file. If not, see <https://www.gnu.org/licenses/>.
 *)

unit Oz.Pb.GenDC;

interface

uses
  System.SysUtils, Oz.Cocor.Utils, Oz.Pb.Tab, Oz.Pb.CustomGen;

{$Region 'TGenDC: code generator for delphi'}
type

  TGenDC = class(TCustomGen)
  protected
    function MapCollection: string; override;
    function RepeatedCollection: string; override;
    function CreateName: string; override;
    procedure GenUses; override;
    procedure GenDecl(Load: Boolean); override;
    procedure GenEntityType(msg: PObj); override;
    procedure GenEntityDecl; override;
    procedure GenEntityImpl(msg: PObj); override;
    procedure GenLoadDecl(msg: PObj); override;
    procedure GenSaveDecl(msg: PObj); override;
    procedure GenLoadImpl; override;
    procedure GenSaveProc; override;
    procedure GenLoadMethod(msg: PObj); override;
    function GenRead(msg: PObj): string; override;
    procedure GenFieldRead(msg: PObj); override;
    procedure GenSaveImpl(msg: PObj); override;
  end;

{$EndRegion}

implementation

uses
  Oz.Pb.Parser;

{$Region 'TGenDC'}

function TGenDC.MapCollection: string;
begin
  Result := 'TDictionary<%s, %s>';
end;

function TGenDC.RepeatedCollection: string;
begin
  Result := 'TList<%s>';
end;

procedure TGenDC.GenUses;
begin
  Wrln('uses');
  Wrln('  System.Classes, System.SysUtils, Generics.Collections, Oz.Pb.Classes;');
  Wrln;
end;

procedure TGenDC.GenDecl(Load: Boolean);
begin
  if Load then
  begin
    Wrln('type');
    Wrln('  TLoad<T: constructor> = procedure(var Value: T) of object;');
    Wrln('  TLoadPair<Key, Value> = procedure(var Pair: TPair<Key, Value>) of object;');
    Wrln('private');
    Wrln('  procedure LoadObj<T: constructor>(var obj: T; Load: TLoad<T>);');
    Wrln('  procedure LoadList<T: constructor>(const List: TList<T>; Load: TLoad<T>);');
  end
  else
  begin
    Wrln('type');
    Wrln('  TSave<T> = procedure(const S: TpbSaver; const Value: T);');
    Wrln('  TSavePair<Key, Value> = procedure(const S: TpbSaver; const Pair: TPair<Key, Value>);');
    Wrln('private');
    Wrln('  procedure SaveObj<T>(const obj: T; Save: TSave<T>; Tag: Integer);');
    Wrln('  procedure SaveList<T>(const List: TList<T>; Save: TSave<T>; Tag: Integer);');
    Wrln('  procedure SaveMap<Key, Value>(const Map: TDictionary<Key, Value>;');
    Wrln('    Save: TSavePair<Key, Value>; Tag: Integer);');
  end;
end;

function TGenDC.CreateName: string;
begin
  Result := 'Create';
end;

procedure TGenDC.GenEntityDecl;
begin
  Wrln('constructor Create;');
  Wrln('destructor Destroy; override;');
end;

procedure TGenDC.GenEntityImpl(msg: PObj);
var
  typ: PType;
  t: string;
  x: PObj;
begin
  typ := msg.typ;
  // parameterless constructor
  t := msg.AsType;
  Wrln('constructor %s.Create;', [t]);
  Wrln('begin');
  Indent;
  try
    Wrln('inherited Create;');
    x := typ.dsc;
    while x <> tab.Guard do
    begin
      FieldInit(x);
      x := x.next;
    end;
  finally
    Dedent;
  end;
  Wrln('end;');
  Wrln;

  Wrln('destructor %s.Destroy;', [t]);
  Wrln('begin');
  Indent;
  try
    x := typ.dsc;
    while x <> tab.Guard do
    begin
      FieldFree(x);
      x := x.next;
    end;
    Wrln('inherited Destroy;');
  finally
    Dedent;
  end;
end;

procedure TGenDC.GenEntityType(msg: PObj);
begin
  Wrln('%s = class', [msg.AsType]);
end;

procedure TGenDC.GenLoadDecl(msg: PObj);
var
  t: string;
begin
  t := msg.AsType;
  Wrln('procedure Load%s(var Value: %s);', [msg.DelphiName, t]);
end;

procedure TGenDC.GenSaveDecl(msg: PObj);
begin
  Wrln('class procedure Save%s(const S: TpbSaver; const Value: %s); static;',
    [msg.DelphiName, msg.AsType]);
end;

procedure TGenDC.GenLoadImpl;
begin
  Wrln('{ TLoadHelper }');
  Wrln;
  Wrln('procedure TLoadHelper.LoadObj<T>(var obj: T; Load: TLoad<T>);');
  Wrln('begin');
  Wrln('  Pb.Push;');
  Wrln('  try');
  Wrln('    obj := T.Create;');
  Wrln('    Load(obj);');
  Wrln('  finally');
  Wrln('    Pb.Pop;');
  Wrln('  end;');
  Wrln('end;');
  Wrln;
  Wrln('procedure TLoadHelper.LoadList<T>(const List: TList<T>; Load: TLoad<T>);');
  Wrln('var');
  Wrln('  obj: T;');
  Wrln('begin');
  Wrln('  Pb.Push;');
  Wrln('  try');
  Wrln('    obj := T.Create;');
  Wrln('    Load(obj);');
  Wrln('    List.Add(obj);');
  Wrln('  finally');
  Wrln('    Pb.Pop;');
  Wrln('  end;');
  Wrln('end;');
  Wrln;
end;

procedure TGenDC.GenLoadMethod(msg: PObj);
var
  s, t: string;
begin
  s := msg.DelphiName;
  t := msg.AsType;
  Wrln('procedure %s.Load%s(var Value: %s);', [GetBuilderName(True), s, t]);
end;

function TGenDC.GenRead(msg: PObj): string;
begin
  Result := Format('Load%s(%s.Create)', [msg.DelphiName, msg.AsType]);
end;

procedure TGenDC.GenFieldRead(msg: PObj);
var
  o: TFieldOptions;
  n, t: string;
begin
  o := msg.aux as TFieldOptions;
  n := 'F' + AsCamel(msg.name);
  t := AsCamel(msg.typ.declaration.name);
  if o.Rule <> TFieldRule.Repeated then
    Wrln('LoadObj<T%s>(Value.%s, Load%s);', [t, n, t])
  else
    Wrln('LoadList<T%s>(Value.%s, Load%s);', [t, Plural(n), t]);
end;

procedure TGenDC.GenSaveProc;
begin
  Wrln('{ TSaveHelper }');
  Wrln;
  Wrln('procedure TSaveHelper.SaveObj<T>(const obj: T; Save: TSave<T>; Tag: Integer);');
  Wrln('var');
  Wrln('  h: TpbSaver;');
  Wrln('begin');
  Wrln('  h.Init;');
  Wrln('  try');
  Wrln('    Save(h, obj);');
  Wrln('    Pb.writeMessage(tag, h.Pb^);');
  Wrln('  finally');
  Wrln('    h.Free;');
  Wrln('  end;');
  Wrln('end;');
  Wrln;
  Wrln('procedure TSaveHelper.SaveList<T>(const List: TList<T>; Save: TSave<T>; Tag: Integer);');
  Wrln('var');
  Wrln('  i: Integer;');
  Wrln('  h: TpbSaver;');
  Wrln('  Item: T;');
  Wrln('begin');
  Wrln('  h.Init;');
  Wrln('  try');
  Wrln('    for i := 0 to List.Count - 1 do');
  Wrln('    begin');
  Wrln('      h.Clear;');
  Wrln('      Item := List[i];');
  Wrln('      Save(h, Item);');
  Wrln('      Pb.writeMessage(tag, h.Pb^);');
  Wrln('    end;');
  Wrln('  finally');
  Wrln('    h.Free;');
  Wrln('  end;');
  Wrln('end;');
  Wrln;
  Wrln('procedure TSaveHelper.SaveMap<Key, Value>(const Map: TDictionary<Key, Value>;');
  Wrln('  Save: TSavePair<Key, Value>; Tag: Integer);');
  Wrln('var');
  Wrln('  h: TpbSaver;');
  Wrln('  Pair: TPair<Key, Value>;');
  Wrln('begin');
  Wrln('  h.Init;');
  Wrln('  try');
  Wrln('    for Pair in Map do');
  Wrln('    begin');
  Wrln('      h.Clear;');
  Wrln('      Save(h, Pair);');
  Wrln('      Pb.writeMessage(tag, h.Pb^);');
  Wrln('    end;');
  Wrln('  finally');
  Wrln('    h.Free;');
  Wrln('  end;');
  Wrln('end;');
  Wrln;
end;

procedure TGenDC.GenSaveImpl(msg: PObj);
var
  s, t: string;
begin
  s := msg.DelphiName;
  t := msg.AsType;
  Wrln('class procedure %s.Save%s(const S: TpbSaver; const Value: %s);',
    [GetBuilderName(False), s, t]);
end;

{$EndRegion}

end.
