unit Oz.Pb.Classes;

interface

uses
  Classes, SysUtils, Oz.Pb.StrBuffer;

const
  TAG_TYPE_BITS = 3;
  TAG_TYPE_MASK = (1 shl TAG_TYPE_BITS) - 1;

  RecursionLimit = 64;

type

{$Region 'EProtobufError'}

  EProtobufError = class(Exception)
  const
    NotImplemented = 0;
    InvalidEndTag = 1;
    InvalidWireType = 2;
    InvalidSize = 3;
    RecursionLimitExceeded = 4;
    MalformedVarint = 5;
    EofEncounterd = 6;
    NegativeSize = 7;
    TruncatedMessage = 8;
    Impossible = 99;
  public
    constructor Create(ErrNo: Integer); overload;
  end;

{$EndRegion}

{$Region 'TWire'}

  TWireType = 0..7;

  TWire = record
  const
    VARINT = 0;
    FIXED64 = 1;
    LENGTH_DELIMITED = 2;
    START_GROUP = 3;
    END_GROUP = 4;
    FIXED32 = 5;
    Names: array [VARINT .. FIXED32] of string = (
      'VARINT',
      'FIXED64',
      'LENGTH_DELIMITED',
      'START_GROUP',
      'END_GROUP',
      'FIXED32');
  end;

{$EndRegion}

{$Region 'TpbTag: Proto field tag'}

  TpbTag = record
  var
    v: Integer;
  public
    // Given a tag value, determines the field number (the upper 29 bits).
    function FieldNumber: Integer; inline;
    // Given a tag value, determines the wire type (the lower 3 bits).
    function WireType: TWireType; inline;
    // Makes a tag value given a field number and wire type.
    procedure MakeTag(FieldNo: Integer; WireType: TWireType); inline;
  end;

{$EndRegion}

{$Region 'TpbInput: Decode data from the buffer and place them to object fields'}

  PpbInput = ^TpbInput;
  TpbInput = record
  const
    RECURSION_LIMIT = 64;
    SIZE_LIMIT = 64 shl 20;  // 64 mb
  private var
    FBuf: PByte;
    FLast: PByte;
    FCurrent: PByte;
    FLastTag: TpbTag;
    FOwnsData: Boolean;
    FRecursionDepth: ShortInt;
    FStack: array [0 .. RECURSION_LIMIT - 1] of PByte;
  public
    procedure Init; overload;
    procedure Init(const pb: TpbInput); overload;
    procedure Init(Buf: PByte; BufSize: Integer; OwnsData: Boolean); overload;
    class function From(const Buf: TBytes): TpbInput; overload; static;
    class function From(Buf: PByte; BufSize: Integer;
      OwnsData: Boolean = False): TpbInput; overload; static;
    procedure Free;

    // I/O routines to file and stream
    procedure SaveToStream(Stream: TStream);
    procedure SaveToFile(const FileName: string);
    procedure LoadFromFile(const FileName: string);
    procedure LoadFromStream(Stream: TStream);
    // Merge messages
    procedure mergeFrom(const builder: TpbInput);
    // No more data
    function Eof: Boolean;
    // Attempt to read a field tag, returning zero if we have reached EOF
    function readTag: TpbTag;
    // Check whether the latter match the value read tag
    // Used to test for nested groups
    procedure checkLastTagWas(value: Integer);
    // Reads and discards a Single field, given its tag value
    function skipField(tag: TpbTag): Boolean;
    // Reads and discards an entire message
    procedure skipMessage;
    // Read a Double field value
    function readDouble: Double;
    // Read a float field value
    function readFloat: Single;
    // Read an Int64 field value
    function readInt64: Int64;
    // Read an Int32 field value
    function readInt32: Integer;
    // Read a fixed64 field value
    function readFixed64: Int64;
    // Read a fixed32 field value
    function readFixed32: Integer;
    // Read a Boolean field value
    function readBoolean: Boolean;
    // Read a string field value
    function readString: string;
    // Read nested message
    procedure readMessage(builder: PpbInput);
    // Read message length, push current FLast to stack, and calc new FLast
    procedure Push;
    // Restore FLast
    procedure Pop;
    // Read a uint32 field value
    function readUInt32: Integer;
    // Read a enum field value
    function readEnum: Integer;
    // Read an sfixed32 field value
    function readSFixed32: Integer;
    // Read an sfixed64 field value
    function readSFixed64: Int64;
    // Read an sint32 field value
    function readSInt32: Integer;
    // Read an sint64 field value
    function readSInt64: Int64;
    // Read a raw Varint from the stream,
    // if larger than 32 bits, discard the upper bits
    function readRawVarint32: Integer;
    // Read a raw Varint
    function readRawVarint64: Int64;
    // Read a 32-bit little-endian Integer
    function readRawLittleEndian32: Integer;
    // Read a 64-bit little-endian Integer
    function readRawLittleEndian64: Int64;
    // Read one byte
    function readRawByte: ShortInt;
    // Read "size" bytes
    procedure readRawBytes(var data; size: Integer);
    function readBytes(size: Integer): TBytes;
    // Skip "size" bytes
    procedure skipRawBytes(size: Integer);
  end;

{$EndRegion}

{$Region 'TpbOutput: Encode the object fields and and write them to buffer'}

  PpbOutput = ^TpbOutput;
  TpbOutput = record
  private
    FBuffer: TSegmentBuffer;
  public
    class function From: TpbOutput; static;
    procedure Free;
    procedure Clear;

    procedure SaveToStream(Stream: TStream); inline;
    procedure SaveToFile(const FileName: string); inline;

    // Encode and write varint
    procedure writeRawVarint32(value: Integer);
    // Encode and write varint
    procedure writeRawVarint64(value: Int64);
    // Encode and write tag
    procedure writeTag(fieldNo: Integer; wireType: Integer);
    // Encode and write single byte
    procedure writeRawByte(value: ShortInt); inline;
    // Encode and write bytes
    procedure writeRawBytes(const value: TBytes);
    // Encode and write string
    procedure writeRawString(const value: string);
    // Write the data with specified size
    procedure writeRawData(const p: Pointer; size: Integer); inline;

    // Get the result as a bytes
    function GetBytes: TBytes; inline;
    // Write a Double field, including tag
    procedure writeDouble(fieldNo: Integer; value: Double);
    // Write a Single field, including tag
    procedure writeFloat(fieldNo: Integer; value: Single);
    // Write a Int64 field, including tag
    procedure writeInt64(fieldNo: Integer; value: Int64);
    // Write a Int64 field, including tag
    procedure writeInt32(fieldNo: Integer; value: Integer);
    // Write a fixed64 field, including tag
    procedure writeFixed64(fieldNo: Integer; value: Int64);
    // Write a fixed32 field, including tag
    procedure writeFixed32(fieldNo: Integer; value: Integer);
    // Write a Boolean field, including tag
    procedure writeBoolean(fieldNo: Integer; value: Boolean);
    // Write a string field, including tag
    procedure writeString(fieldNo: Integer; const value: string);
    // Write a bytes field, including tag
    procedure writeBytes(fieldNo: Integer; const value: TBytes);
    // Write a message field, including tag
    procedure writeMessage(fieldNo: Integer; const msg: TpbOutput);
    //  Write a unsigned Int32 field, including tag
    procedure writeUInt32(fieldNo: Integer; value: Cardinal);
    // Get serialized size
    function getSerializedSize: Integer;
    // Write to buffer
    procedure writeTo(buffer: TpbOutput);
  end;

{$EndRegion}

{$Region 'TpbLoader: Load object'}

  TpbLoader = record
  private
    Fpb: TpbInput;
    function GetPb: PpbInput; inline;
  public
    procedure Init; inline;
    procedure Free; inline;
    property Pb: PpbInput read GetPb;
  end;

{$EndRegion}

{$Region 'TpbSaver: Save a object'}

  TpbSaver = record
  private
    Fpb: TpbOutput;
    function GetPb: PpbOutput; inline;
  public
    procedure Init; inline;
    procedure Free; inline;
    procedure Clear; inline;
    property Pb: PpbOutput read GetPb;
  end;

{$EndRegion}

{$Region 'Procedures'}

function decodeZigZag32(n: Integer): Integer;
function decodeZigZag64(n: Int64): Int64;

{$EndRegion}

implementation

{$Region 'Procedures'}

function decodeZigZag32(n: Integer): Integer;
begin
  Result := (n shr 1) xor -(n and 1);
end;

function decodeZigZag64(n: Int64): Int64;
begin
  Result := (n shr 1) xor -(n and 1);
end;

{$EndRegion}

{$Region 'EProtobufError'}

constructor EProtobufError.Create(ErrNo: Integer);
var Msg: string;
begin
  case ErrNo of
    NotImplemented: Msg := 'Not implemented';
    InvalidEndTag: Msg := 'Pb: invalid end tag';
    InvalidWireType: Msg := 'Pb: invalid wire type';
    InvalidSize: Msg := 'Pb: readString (size <= 0)';
    RecursionLimitExceeded: Msg := 'Pb: recursion Limit Exceeded';
    MalformedVarint: Msg := 'Pb: malformed Varint';
    EofEncounterd: Msg := 'Pb: eof encounterd';
    NegativeSize: Msg := 'Pb: negative Size';
    TruncatedMessage: Msg := 'Pb: truncated Message';
    Impossible: Msg := 'Impossible';
    else Msg := 'Error: ' + IntToStr(ErrNo);
  end;
  Create(Msg);
end;

{$EndRegion}

{$Region 'TpbTag'}

function TpbTag.FieldNumber: Integer;
begin
  Result := v shr TAG_TYPE_BITS;
end;

function TpbTag.WireType: TWireType;
begin
  result := v and TAG_TYPE_MASK;
end;

procedure TpbTag.MakeTag(FieldNo: Integer; WireType: TWireType);
begin
  v := (FieldNo shl TAG_TYPE_BITS) or wireType;
end;

{$EndRegion}

{$Region 'TpbInput'}

procedure TpbInput.Init;
begin
  Self := Default(TpbInput);
end;

procedure TpbInput.Init(Buf: PByte; BufSize: Integer; OwnsData: Boolean);
begin
  FOwnsData := OwnsData;
  FRecursionDepth := 0;
  if not OwnsData then
    FBuf := Buf
  else
  begin
    // allocate a buffer and copy the data
    GetMem(FBuf, BufSize);
    Move(Buf^, FBuf^, BufSize);
  end;
  FCurrent := FBuf;
  FLast := FBuf + BufSize;
end;

procedure TpbInput.Init(const pb: TpbInput);
begin
  FBuf := pb.FBuf;
  FCurrent := FBuf;
  FLast := pb.FLast;
  Self.FOwnsData := False;
end;

class function TpbInput.From(const Buf: TBytes): TpbInput;
begin
  Result.Init(@Buf[0], Length(Buf), False);
end;

class function TpbInput.From(Buf: PByte; BufSize: Integer;
  OwnsData: Boolean = False): TpbInput;
begin
  Result.Init(Buf, BufSize, OwnsData);
end;

function TpbInput.Eof: Boolean;
begin
  Result := FCurrent >= FLast;
end;

procedure TpbInput.Free;
begin
  if FOwnsData then
    FreeMem(FBuf);
  Self := Default(TpbInput);
end;

function TpbInput.readTag: TpbTag;
begin
  if FCurrent < FLast then
    FLastTag.v := readRawVarint32
  else
    FLastTag.v := 0;
  Result := FLastTag;
end;

procedure TpbInput.checkLastTagWas(value: Integer);
begin
  if FLastTag.v <> value then
    EProtobufError.Create(EProtobufError.InvalidEndTag);
end;

function TpbInput.skipField(tag: TpbTag): Boolean;
begin
  Result := True;
  case tag.WireType of
    TWire.VARINT:
      readInt32;
    TWire.FIXED64:
      readRawLittleEndian64;
    TWire.LENGTH_DELIMITED:
      skipRawBytes(readRawVarint32);
    TWire.FIXED32:
      readRawLittleEndian32;
    else
      raise EProtobufError.Create('Protocol buffer: invalid WireType');
  end;
end;

procedure TpbInput.skipMessage;
var tag: TpbTag;
begin
  repeat
    tag := readTag;
  until (tag.v = 0) or (not skipField(tag));
end;

function TpbInput.readDouble: Double;
begin
  readRawBytes(Result, SizeOf(Double));
end;

function TpbInput.readFloat: Single;
begin
  readRawBytes(Result, SizeOf(Single));
end;

function TpbInput.readInt64: Int64;
begin
  Result := readRawVarint64;
end;

function TpbInput.readInt32: Integer;
begin
  Result := readRawVarint32;
end;

function TpbInput.readFixed64: Int64;
begin
  Result := readRawLittleEndian64;
end;

function TpbInput.readFixed32: Integer;
begin
  Result := readRawLittleEndian32;
end;

function TpbInput.readBoolean: Boolean;
begin
  Result := readRawVarint32 <> 0;
end;

function TpbInput.readString: string;
var
  size: Integer;
  buf, text: TBytes;
begin
  size := readRawVarint32;
  if size <= 0 then
     EProtobufError.Create(EProtobufError.InvalidSize);
  // Decode utf8 to string
  buf := readBytes(size);
  text := TEncoding.UTF8.Convert(TEncoding.UTF8, TEncoding.Unicode, buf);
  Result := TEncoding.Unicode.GetString(text);
end;

procedure TpbInput.readMessage(builder: PpbInput);
begin
  readRawVarint32;
  if FRecursionDepth >= RECURSION_LIMIT then
    EProtobufError.Create(EProtobufError.RecursionLimitExceeded);
  Inc(FRecursionDepth);
  builder.mergeFrom(Self);
  checkLastTagWas(0);
  dec(FRecursionDepth);
end;

function TpbInput.readUInt32: Integer;
begin
  Result := readRawVarint32;
end;

function TpbInput.readEnum: Integer;
begin
  Result := readRawVarint32;
end;

function TpbInput.readSFixed32: Integer;
begin
  Result := readRawLittleEndian32;
end;

function TpbInput.readSFixed64: Int64;
begin
  Result := readRawLittleEndian64;
end;

function TpbInput.readSInt32: Integer;
begin
  Result := decodeZigZag32(readRawVarint32);
end;

function TpbInput.readSInt64: Int64;
begin
  Result := decodeZigZag64(readRawVarint64);
end;

function TpbInput.readRawVarint32: Integer;
var
  tmp: ShortInt;
  shift: Integer;
begin
  shift := 0;
  Result := 0;
  repeat
    // for negative numbers number value may be to 10 byte
    if shift >= 64 then
      EProtobufError.Create(EProtobufError.MalformedVarint);
    tmp := readRawByte;
    Result := Result or ((tmp and $7f) shl shift);
    Inc(shift, 7);
  until tmp >= 0;
end;

function TpbInput.readRawVarint64: Int64;
var
  tmp: ShortInt;
  shift: Integer;
  i64: Int64;
begin
  shift := -7;
  Result := 0;
  repeat
    Inc(shift, 7);
    if shift >= 64 then
      EProtobufError.Create(EProtobufError.MalformedVarint);
    tmp := readRawByte;
    i64 := tmp and $7f;
    i64 := i64 shl shift;
    Result := Result or i64;
  until tmp >= 0;
end;

function TpbInput.readRawLittleEndian32: Integer;
begin
  readRawBytes(Result, SizeOf(Result));
end;

function TpbInput.readRawLittleEndian64: Int64;
begin
  readRawBytes(Result, SizeOf(Result));
end;

function TpbInput.readRawByte: ShortInt;
begin
  if FCurrent >= FLast then
    EProtobufError.Create(EProtobufError.EofEncounterd);
  Result := ShortInt(FCurrent^);
  Inc(FCurrent);
end;

procedure TpbInput.readRawBytes(var data; size: Integer);
begin
  if FCurrent > FLast then
    EProtobufError.Create(EProtobufError.EofEncounterd);
  Move(FCurrent^, data, size);
  Inc(FCurrent, size);
end;

function TpbInput.readBytes(size: Integer): TBytes;
begin
  if FCurrent > FLast then
    EProtobufError.Create(EProtobufError.EofEncounterd);
  SetLength(Result, size);
  Move(FCurrent^, Pointer(Result)^, size);
  Inc(FCurrent, size);
end;

procedure TpbInput.skipRawBytes(size: Integer);
begin
  if size < 0 then
    EProtobufError.Create(EProtobufError.NegativeSize);
  if FCurrent > FLast then
    EProtobufError.Create(EProtobufError.TruncatedMessage);
  Inc(FCurrent, size);
end;

procedure TpbInput.SaveToFile(const FileName: string);
var Stream: TStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TpbInput.SaveToStream(Stream: TStream);
begin
  Stream.WriteBuffer(Pointer(FBuf)^, Cardinal(FLastTag) - Cardinal(FBuf) + 1);
end;

procedure TpbInput.LoadFromFile(const FileName: string);
var Stream: TStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TpbInput.LoadFromStream(Stream: TStream);
var
  Size: Integer;
begin
  if FOwnsData then begin
    FreeMem(FBuf);
    FBuf := nil;
  end;
  FOwnsData := True;
  Size := Stream.Size;
  GetMem(FBuf, Size);
  FCurrent := FBuf;
  FLast := FBuf + Size;
  Stream.Position := 0;
  Stream.Read(Pointer(FBuf)^, Size);
end;

procedure TpbInput.mergeFrom(const builder: TpbInput);
begin
  EProtobufError.Create(EProtobufError.NotImplemented);
end;

procedure TpbInput.Push;
var
  Size: Integer;
  Last: PByte;
begin
  FStack[FRecursionDepth] := FLast;
  Inc(FRecursionDepth);
  Size := readInt32;
  Last := FCurrent + Size;
  Assert(Last <= FLast);
  FLast := Last;
end;

procedure TpbInput.Pop;
begin
  Assert(FCurrent = FLast);
  dec(FRecursionDepth);
  FLast := FStack[FRecursionDepth];
end;

{$EndRegion}

{$Region 'TpbOutput'}

class function TpbOutput.From: TpbOutput;
begin
  Result.FBuffer := TSegmentBuffer.Create;
end;

procedure TpbOutput.Free;
begin
  FreeAndNil(FBuffer);
end;

procedure TpbOutput.Clear;
begin
  FBuffer.Clear;
end;

procedure TpbOutput.writeRawByte(value: ShortInt);
begin
  // -128..127
  FBuffer.Add(Byte(value));
end;

procedure TpbOutput.writeRawBytes(const value: TBytes);
begin
  writeRawVarint32(Length(value));
  FBuffer.Add(value);
end;

procedure TpbOutput.writeRawString(const value: string);
var
  bytes, text: TBytes;
begin
  bytes := TEncoding.Unicode.GetBytes(value);
  text := TEncoding.Unicode.Convert(TEncoding.Unicode, TEncoding.UTF8, bytes);
  writeRawVarint32(Length(text));
  FBuffer.Add(text);
end;

procedure TpbOutput.writeRawData(const p: Pointer; size: Integer);
begin
  FBuffer.Add(p, size);
end;

procedure TpbOutput.writeTag(fieldNo, wireType: Integer);
var
  tag: TpbTag;
begin
  tag.MakeTag(fieldNo, wireType);
  writeRawVarint32(tag.v);
end;

procedure TpbOutput.writeRawVarint32(value: Integer);
var b: ShortInt;
begin
  repeat
    b := value and $7F;
    value := value shr 7;
    if value <> 0 then
      b := b + $80;
    writeRawByte(b);
  until value = 0;
end;

procedure TpbOutput.writeRawVarint64(value: Int64);
var b: ShortInt;
begin
  repeat
    b := value and $7F;
    value := value shr 7;
    if value <> 0 then
      b := b + $80;
    writeRawByte(b);
  until value = 0;
end;

procedure TpbOutput.writeBoolean(fieldNo: Integer; value: Boolean);
begin
  writeTag(fieldNo, TWire.VARINT);
  writeRawByte(ord(value));
end;

procedure TpbOutput.writeDouble(fieldNo: Integer; value: Double);
begin
  writeTag(fieldNo, TWire.FIXED64);
  writeRawData(@value, SizeOf(value));
end;

procedure TpbOutput.writeFloat(fieldNo: Integer; value: Single);
begin
  writeTag(fieldNo, TWire.FIXED32);
  writeRawData(@value, SizeOf(value));
end;

procedure TpbOutput.writeFixed32(fieldNo, value: Integer);
begin
  writeTag(fieldNo, TWire.FIXED32);
  writeRawData(@value, SizeOf(value));
end;

procedure TpbOutput.writeFixed64(fieldNo: Integer; value: Int64);
begin
  writeTag(fieldNo, TWire.FIXED64);
  writeRawData(@value, SizeOf(value));
end;

procedure TpbOutput.writeInt32(fieldNo, value: Integer);
begin
  writeTag(fieldNo, TWire.VARINT);
  writeRawVarint32(value);
end;

procedure TpbOutput.writeInt64(fieldNo: Integer; value: Int64);
begin
  writeTag(fieldNo, TWire.VARINT);
  writeRawVarint64(value);
end;

procedure TpbOutput.writeString(fieldNo: Integer; const value: string);
begin
  writeTag(fieldNo, TWire.LENGTH_DELIMITED);
  writeRawString(value);
end;

procedure TpbOutput.writeBytes(fieldNo: Integer; const value: TBytes);
begin
  writeTag(fieldNo, TWire.LENGTH_DELIMITED);
  writeRawBytes(value);
end;

procedure TpbOutput.writeUInt32(fieldNo: Integer; value: Cardinal);
begin
  writeTag(fieldNo, TWire.VARINT);
  writeRawVarint32(value);
end;

procedure TpbOutput.writeMessage(fieldNo: Integer; const msg: TpbOutput);
var sz: Integer;
begin
  writeTag(fieldNo, TWire.LENGTH_DELIMITED);
  sz := msg.getSerializedSize;
  writeRawVarint32(sz);
  msg.writeTo(Self);
end;

function TpbOutput.GetBytes: TBytes;
begin
  result := FBuffer.GetBytes;
end;

procedure TpbOutput.SaveToFile(const FileName: string);
begin
  FBuffer.SaveToFile(FileName);
end;

procedure TpbOutput.SaveToStream(Stream: TStream);
begin
  FBuffer.SaveToStream(Stream);
end;

function TpbOutput.getSerializedSize: Integer;
begin
  result := FBuffer.GetCount;
end;

procedure TpbOutput.writeTo(buffer: TpbOutput);
begin
  buffer.FBuffer.Add(GetBytes);
end;

{$EndRegion}

{$Region 'TpbCustomLoader: Base class for a load object'}

procedure TpbLoader.Init;
begin
  FPb.Init;
end;

procedure TpbLoader.Free;
begin
  FPb.Free;
end;

function TpbLoader.GetPb: PpbInput;
begin
  Result := @FPb;
end;

{$EndRegion}

{$Region 'TpbSaver: Base class save a object'}

procedure TpbSaver.Init;
begin
  FPb := TpbOutput.From;
end;

procedure TpbSaver.Free;
begin
  FPb.Free;
end;

procedure TpbSaver.Clear;
begin
  FPb.Clear;
end;

function TpbSaver.GetPb: PpbOutput;
begin
  Result := @FPb;
end;

{$EndRegion}

end.
