{
 OGLOGGWrapper:
   Wrapper for OGG library

   Copyright (c) 2022 by Ilya Medvedkov

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
}

unit OGLOGGWrapper;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, libOGG_dynlite, OGLFastNumList;

type
  TOGGEndian = (oggeLE, oggeBE);

  IOGGIOVec = interface(IUnknown)
    ['{0D1EB404-D501-450F-A463-58A25EC60974}']
    function Ref : pogg_iovec_t;
    procedure AddBuffer(iov_base : Pointer; iov_len: SizeUInt);
    function GetBufferAt(pos : integer) : pogg_iovec_t;
    function Count : Integer;
  end;

  IOGGPage = interface(IUnknown)
    ['{1A5847F0-E92A-497B-933D-026114F3D65B}']
    function Ref : pogg_page;

    procedure ChecksumSet;
    function Version: integer;
    function Continued: Boolean;
    function BoS: Boolean;
    function EoS: Boolean;
    function GranulePos: ogg_int64_t;
    function SerialNo: integer;
    function PageNo: longint;
    function Packets: integer;
  end;

  IOGGPacket = interface(IUnknown)
    ['{4AEE539D-9B8C-4E63-A624-F1A79CC861D8}']
    function Ref : pogg_packet;

    procedure Clear;
  end;

  { IOGGStreamState }

  IOGGStreamState = interface(IUnknown)
    ['{C28D78AA-5EB7-4F18-BBCF-B44892998568}']
    function Ref : pogg_stream_state;

    procedure Init(serialno: integer);
    procedure Done;

    procedure Clear;
    procedure Reset;
    function ResetSerialNo(serialno: integer): integer;
    function Check: Boolean;
    function EoS: Boolean;

    procedure PacketIn(op: IOGGPacket);
    procedure IOVecIn(iov: IOGGIOVec; e_o_s: Boolean;
                          granulepos: ogg_int64_t);
    function PageOutNew : IOGGPage;
    function PageOut(og: IOGGPage) : Boolean;
    function PageOutFill(og: IOGGPage; nfill: integer) : Boolean;
    procedure PageOutToStream(aStr : TStream);
    procedure PagesOutToStream(aStr : TStream);
    procedure SavePacketToStream(aStr : TStream; op: IOGGPacket);
    function Flush(og: IOGGPage): Boolean;
    function FlushFill(og: IOGGPage; nfill: integer): Boolean;

    procedure PageIn(og: IOGGPage);
    function PacketOut(op: IOGGPacket): Boolean;
    function PacketPeek(op: IOGGPacket): Boolean;
  end;

  IOGGSyncState = interface(IUnknown)
    ['{12710DDC-65A6-419B-9D52-66BE05598CE5}']
    function Ref : pogg_sync_state;

    function Init: integer;
    function Done: integer;

    function Clear: integer;
    function Reset: integer;
    function Check: integer;
    function Buffer(size: longint): pointer;
    function Wrote(bytes: longint): integer;
    function PageSeek(og: IOGGPage): longint;
    function PageOut(og: IOGGPage): integer;
  end;

  IOGGPackBuffer = interface(IUnknown)
    ['{239B2C48-5FC5-413C-98E0-A552BB13D606}']
    function Ref : poggpack_buffer;

    procedure SetEndianMode(e : TOGGEndian);
    function  GetEndianMode : TOGGEndian;

    procedure WriteInit;
    function  WriteCheck : integer;
    procedure WriteTrunc(bits: longint);
    procedure WriteAlign;
    procedure WriteCopy(source: pointer; bits: longint);
    procedure Reset;
    procedure WriteClear;
    procedure ReadInit(buf: pbyte; bytes: integer);
    procedure Write(value: cardinal; bits: integer);
    function Look(bits: integer): longint;
    function Look1bit: longint;
    procedure Adv(bits: integer);
    procedure Adv1bit;
    function Read(bits: integer): longint;
    function Read1: longint;
    function Bytes: longint;
    function Bits: longint;
    function GetBuffer: pbyte;
  end;

  { TFastIOVecList }

  TFastIOVecList = class(specialize TFastBaseNumericList<ogg_iovec_t>)
  protected
    function  DoCompare(Item1, Item2 : Pointer) : Integer; override;
  end;

  { TOGGIOVecListed }

  TOGGIOVecListed = class(TInterfacedObject, IOGGIOVec)
  private
    FRef : TFastIOVecList;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddBuffer(iov_base : Pointer; iov_len: SizeUInt);
    function GetBufferAt(pos : integer) : pogg_iovec_t;

    function Count : Integer;

    function Ref : pogg_iovec_t;
  end;

  { TOGGIOVecStatic }

  TOGGIOVecStatic = class(TInterfacedObject, IOGGIOVec)
  private
    FRef : pogg_iovec_t;
    FCount : integer;
    FOwned : Boolean;
  public
    constructor Create(aRef : pogg_iovec_t; aCount : integer; aOwned : Boolean);
    destructor Destroy; override;

    procedure AddBuffer(iov_base : Pointer; iov_len: SizeUInt);
    function GetBufferAt(pos : integer) : pogg_iovec_t;

    function Count : Integer;

    function Ref : pogg_iovec_t;
  end;

  { TOGGIOVecStream }

  TOGGIOVecStream = class(TInterfacedObject, IOGGIOVec)
  private
    FRef : TCustomMemoryStream;
    FOwned : Boolean;
  public
    constructor Create(aRef : TCustomMemoryStream; aOwned : Boolean);
    destructor Destroy; override;

    procedure AddBuffer(iov_base : Pointer; iov_len: SizeUInt);
    function GetBufferAt(pos : integer) : pogg_iovec_t;

    function Count : Integer;

    function Ref : pogg_iovec_t;
  end;

  { TOGGIOVecMemory }

  TOGGIOVecMemory = class(TOGGIOVecStream)
  public
    constructor Create;
  end;

  { TOGGPage }

  TOGGPage = class(TInterfacedObject, IOGGPage)
  private
    FRef : ogg_page;
  public
    function Ref : pogg_page;

    constructor Create;

    procedure ChecksumSet;
    function Version: integer;
    function Continued: Boolean;
    function BoS: Boolean;
    function EoS: Boolean;
    function GranulePos: ogg_int64_t;
    function SerialNo: integer;
    function PageNo: longint;
    function Packets: integer;
  end;

  { TOGGPacket }

  TOGGPacket = class(TInterfacedObject, IOGGPacket)
  private
    FRef : ogg_packet;
  public
    function Ref : pogg_packet;

    constructor Create;

    procedure Clear;
  end;

  { TOGGStreamState }

  TOGGStreamState = class(TInterfacedObject, IOGGStreamState)
  private
    FRef : ogg_stream_state;
    procedure Init(serialno: integer);
    procedure Done;
  public
    function Ref : pogg_stream_state;

    constructor Create(serialno : integer);
    destructor Destroy; override;

    procedure Clear;
    procedure Reset;
    function ResetSerialNo(serialno: integer): integer;
    function Check: Boolean;
    function EoS: Boolean;

    procedure PacketIn(op: IOGGPacket);
    procedure IOVecIn(iov: IOGGIOVec; e_o_s: Boolean;
                          granulepos: ogg_int64_t);
    function PageOutNew : IOGGPage;
    function PageOut(og: IOGGPage) : Boolean;
    function PageOutFill(og: IOGGPage; nfill: integer) : Boolean;
    procedure PageOutToStream(aStr : TStream);
    procedure PagesOutToStream(aStr : TStream);
    procedure SavePacketToStream(aStr : TStream; op: IOGGPacket);
    function Flush(og: IOGGPage): Boolean;
    function FlushFill(og: IOGGPage; nfill: integer): Boolean;

    procedure PageIn(og: IOGGPage);
    function PacketOut(op: IOGGPacket): Boolean;
    function PacketPeek(op: IOGGPacket): Boolean;
  end;

  { TOGGSyncState }

  TOGGSyncState = class(TInterfacedObject, IOGGSyncState)
  private
    FRef : ogg_sync_state;
    function Init: integer;
    function Done: integer;
  public
    function Ref : pogg_sync_state;

    constructor Create;
    destructor Destroy; override;

    function Clear: integer;
    function Reset: integer;
    function Check: integer;
    function Buffer(size: longint): pointer;
    function Wrote(bytes: longint): integer;
    function PageSeek(og: IOGGPage): longint;
    function PageOut(og: IOGGPage): integer;
  end;

  { TOGGPackBuffer }

  TOGGPackBuffer = class(TInterfacedObject, IOGGPackBuffer)
  private
    FRef : oggpack_buffer;
    FEnd : TOGGEndian;
  public
    function Ref : poggpack_buffer;

    constructor Create(aEndian : TOGGEndian);

    procedure SetEndianMode(e : TOGGEndian);
    function  GetEndianMode : TOGGEndian;

    procedure WriteInit;
    function  WriteCheck : integer;
    procedure WriteTrunc(bits: longint);
    procedure WriteAlign;
    procedure WriteCopy(source: pointer; bits: longint);
    procedure Reset;
    procedure WriteClear;
    procedure ReadInit(buf: pbyte; bytes: integer);
    procedure Write(value: cardinal; bits: integer);
    function Look(bits: integer): longint;
    function Look1bit: longint;
    procedure Adv(bits: integer);
    procedure Adv1bit;
    function Read(bits: integer): longint;
    function Read1: longint;
    function Bytes: longint;
    function Bits: longint;
    function GetBuffer: pbyte;
  end;

  { TOGG }

  TOGG = class
  public
    class function NewPackBuffer(aEndian : TOGGEndian) : IOGGPackBuffer;
    class function NewSyncState : IOGGSyncState;
    class function NewStream(serialno : integer) : IOGGStreamState;
    class function NewPacket : IOGGPacket;
    class function NewPage : IOGGPage;
    class function NewIOVecListed : IOGGIOVec;
    class function NewIOVecStatic(aRef : pogg_iovec_t; aCount : integer;
                          aOwned : Boolean) : IOGGIOVec;
    class function NewIOVecStream(aRef : TCustomMemoryStream; aOwned : Boolean
                                       ) : IOGGIOVec;
    class function NewIOVecMemory : IOGGIOVec;

    class function OGGLibsLoad(const aOGGLibs : Array of String) : Boolean;
    class function OGGLibsLoadDefault : Boolean;
    class function IsOGGLibsLoaded : Boolean;
    class function OGGLibsUnLoad : Boolean;
  end;

  { EOGGException }

  EOGGException = class(Exception)
  public
    constructor Create; overload;
  end;

implementation

const
  ERR_INSUF = 'Insufficient data has accumulated to fill a page, or an internal error occurred';
  ERR_INTERNAL = 'Internal error';

{ EOGGException }

constructor EOGGException.Create;
begin
  inherited Create(ERR_INTERNAL);
end;


{ TOGGIOVecMemory }

constructor TOGGIOVecMemory.Create;
begin
  inherited Create(TMemoryStream.Create, true);
end;

{ TOGGIOVecStream }

constructor TOGGIOVecStream.Create(aRef : TCustomMemoryStream; aOwned : Boolean
  );
begin
  FRef := aRef;
  FOwned := aOwned;
end;

destructor TOGGIOVecStream.Destroy;
begin
  if FOwned then FRef.Free;
  inherited Destroy;
end;

procedure TOGGIOVecStream.AddBuffer(iov_base : Pointer; iov_len : SizeUInt);
begin
  FRef.Seek(0, soEnd);
  FRef.Write(iov_base, sizeof(iov_base));
  FRef.Write(iov_len, sizeof(iov_len));
end;

function TOGGIOVecStream.GetBufferAt(pos : integer) : pogg_iovec_t;
begin
  Result := @(pogg_iovec_t(FRef.Memory)[pos]);
end;

function TOGGIOVecStream.Count : Integer;
begin
  Result := FRef.Size div sizeof(ogg_iovec_t);
end;

function TOGGIOVecStream.Ref : pogg_iovec_t;
begin
  Result := pogg_iovec_t(FRef.Memory);
end;

{ TOGGIOVecStatic }

constructor TOGGIOVecStatic.Create(aRef : pogg_iovec_t; aCount : integer;
  aOwned : Boolean);
begin
  FRef := aRef;
  FCount := aCount;
  FOwned := aOwned;
end;

destructor TOGGIOVecStatic.Destroy;
begin
  if FOwned then FreeMemAndNil(FRef);
  inherited Destroy;
end;

procedure TOGGIOVecStatic.AddBuffer(iov_base : Pointer; iov_len : SizeUInt);
begin
  //not supported
end;

function TOGGIOVecStatic.GetBufferAt(pos : integer) : pogg_iovec_t;
begin
  Result := @(pogg_iovec_t(Ref)[pos]);
end;

function TOGGIOVecStatic.Count : Integer;
begin
  Result := FCount;
end;

function TOGGIOVecStatic.Ref : pogg_iovec_t;
begin
  Result := FRef;
end;

{ TOGG }

class function TOGG.NewPackBuffer(aEndian : TOGGEndian) : IOGGPackBuffer;
begin
  Result := TOGGPackBuffer.Create(aEndian) as IOGGPackBuffer;
end;

class function TOGG.NewSyncState : IOGGSyncState;
begin
  Result := TOGGSyncState.Create as IOGGSyncState;
end;

class function TOGG.NewStream(serialno : integer) : IOGGStreamState;
begin
  Result := TOGGStreamState.Create(serialno) as IOGGStreamState;
end;

class function TOGG.NewPacket : IOGGPacket;
begin
  Result := TOGGPacket.Create() as IOGGPacket;
end;

class function TOGG.NewPage : IOGGPage;
begin
  Result := TOGGPage.Create() as IOGGPage;
end;

class function TOGG.NewIOVecListed : IOGGIOVec;
begin
  Result := TOGGIOVecListed.Create as IOGGIOVec;
end;

class function TOGG.NewIOVecStatic(aRef : pogg_iovec_t; aCount : integer;
  aOwned : Boolean) : IOGGIOVec;
begin
  Result := TOGGIOVecStatic.Create(aRef, aCount, aOwned) as IOGGIOVec;
end;

class function TOGG.NewIOVecStream(aRef : TCustomMemoryStream;
  aOwned : Boolean) : IOGGIOVec;
begin
  Result := TOGGIOVecStream.Create(aRef, aOwned) as IOGGIOVec;
end;

class function TOGG.NewIOVecMemory : IOGGIOVec;
begin
  Result := TOGGIOVecMemory.Create as IOGGIOVec;
end;

class function TOGG.OGGLibsLoad(const aOGGLibs : array of String
  ) : Boolean;
begin
  Result := InitOGGInterface(aOGGLibs);
end;

class function TOGG.OGGLibsLoadDefault : Boolean;
begin
  Result := InitOGGInterface(OGGDLL);
end;

class function TOGG.IsOGGLibsLoaded : Boolean;
begin
  Result := IsOGGloaded;
end;

class function TOGG.OGGLibsUnLoad : Boolean;
begin
  Result := DestroyOGGInterface;
end;

{ TFastIOVecList }

function TFastIOVecList.DoCompare(Item1, Item2 : Pointer) : Integer;
begin
  if Item1 > Item2 then
     Result := -1
  else
  if Item1 = Item2 then
     Result := 0
  else
     Result := 1;
end;

{ TOGGPackBuffer }

function TOGGPackBuffer.Ref : poggpack_buffer;
begin
  Result := @FRef;
end;

constructor TOGGPackBuffer.Create(aEndian : TOGGEndian);
begin
  FEnd := aEndian;
end;

procedure TOGGPackBuffer.SetEndianMode(e : TOGGEndian);
begin
  FEnd := e;
end;

function TOGGPackBuffer.GetEndianMode : TOGGEndian;
begin
  Result := Fend;
end;

procedure TOGGPackBuffer.WriteInit;
begin
  case Fend of
    oggeLE: oggpack_writeinit(Ref);
    oggeBE: oggpackB_writeinit(Ref);
  end;
end;

function TOGGPackBuffer.WriteCheck : integer;
begin
  case Fend of
    oggeLE: Result := oggpack_writecheck(Ref);
    oggeBE: Result := oggpackB_writecheck(Ref);
  end;
end;

procedure TOGGPackBuffer.WriteTrunc(bits : longint);
begin
  case Fend of
    oggeLE: oggpack_writetrunc(Ref, bits);
    oggeBE: oggpackB_writetrunc(Ref, bits);
  end;
end;

procedure TOGGPackBuffer.WriteAlign;
begin
  case Fend of
    oggeLE: oggpack_writealign(Ref);
    oggeBE: oggpackB_writealign(Ref);
  end;
end;

procedure TOGGPackBuffer.WriteCopy(source : pointer; bits : longint);
begin
  case Fend of
    oggeLE: oggpack_writecopy(Ref, source, bits);
    oggeBE: oggpackB_writecopy(Ref, source, bits);
  end;
end;

procedure TOGGPackBuffer.Reset;
begin
  case Fend of
    oggeLE:  oggpack_reset(Ref);
    oggeBE: oggpackB_reset(Ref);
  end;
end;

procedure TOGGPackBuffer.WriteClear;
begin
  case Fend of
    oggeLE:  oggpack_writeclear(Ref);
    oggeBE: oggpackB_writeclear(Ref);
  end;
end;

procedure TOGGPackBuffer.ReadInit(buf : pbyte; bytes : integer);
begin
  case Fend of
    oggeLE:  oggpack_readinit(Ref, buf, bytes);
    oggeBE: oggpackB_readinit(Ref, buf, bytes);
  end;
end;

procedure TOGGPackBuffer.Write(value : cardinal; bits : integer);
begin
  case Fend of
    oggeLE:  oggpack_write(Ref, value, bits);
    oggeBE: oggpackB_write(Ref, value, bits);
  end;
end;

function TOGGPackBuffer.Look(bits : integer) : longint;
begin
  case Fend of
    oggeLE: Result :=  oggpack_look(Ref, bits);
    oggeBE: Result :=  oggpackB_look(Ref, bits);
  end;
end;

function TOGGPackBuffer.Look1bit : longint;
begin
  case Fend of
    oggeLE: Result :=  oggpack_look1(Ref);
    oggeBE: Result := oggpackB_look1(Ref);
  end;
end;

procedure TOGGPackBuffer.Adv(bits : integer);
begin
  case Fend of
    oggeLE:  oggpack_adv(Ref, bits);
    oggeBE: oggpackB_adv(Ref, bits);
  end;
end;

procedure TOGGPackBuffer.Adv1bit;
begin
  case Fend of
    oggeLE:  oggpack_adv1(Ref);
    oggeBE: oggpackB_adv1(Ref);
  end;
end;

function TOGGPackBuffer.Read(bits : integer) : longint;
begin
  case Fend of
    oggeLE: Result :=  oggpack_read(Ref, bits);
    oggeBE: Result := oggpackB_read(Ref, bits);
  end;
end;

function TOGGPackBuffer.Read1 : longint;
begin
  case Fend of
    oggeLE: Result :=  oggpack_read1(Ref);
    oggeBE: Result := oggpackB_read1(Ref);
  end;
end;

function TOGGPackBuffer.Bytes : longint;
begin
  case Fend of
    oggeLE: Result :=  oggpack_bytes(Ref);
    oggeBE: Result := oggpackB_bytes(Ref);
  end;
end;

function TOGGPackBuffer.Bits : longint;
begin
  case Fend of
    oggeLE: Result :=  oggpack_bits(Ref);
    oggeBE: Result := oggpackB_bits(Ref);
  end;
end;

function TOGGPackBuffer.GetBuffer : pbyte;
begin
  case Fend of
    oggeLE: Result :=  oggpack_get_buffer(Ref);
    oggeBE: Result := oggpackB_get_buffer(Ref);
  end;
end;

{ TOGGSyncState }

function TOGGSyncState.Init : integer;
begin
  Result := ogg_sync_init(Ref);
end;

function TOGGSyncState.Done : integer;
begin
  Result := ogg_sync_clear(Ref);
end;

function TOGGSyncState.Ref : pogg_sync_state;
begin
  Result := @FRef;
end;

constructor TOGGSyncState.Create;
begin
  FillByte(FRef, Sizeof(FRef), 0);
  Init;
end;

destructor TOGGSyncState.Destroy;
begin
  Done;
  inherited Destroy;
end;

function TOGGSyncState.Clear : integer;
begin
   Result := ogg_sync_clear(Ref);
end;

function TOGGSyncState.Reset : integer;
begin
  Result := ogg_sync_reset(Ref);
end;

function TOGGSyncState.Check : integer;
begin
  Result := ogg_sync_check(Ref);
end;

function TOGGSyncState.Buffer(size : longint) : pointer;
begin
  Result := ogg_sync_buffer(Ref, size);
end;

function TOGGSyncState.Wrote(bytes : longint) : integer;
begin
  Result := ogg_sync_wrote(Ref, bytes);
end;

function TOGGSyncState.PageSeek(og : IOGGPage) : longint;
begin
  Result := ogg_sync_pageseek(Ref, og.Ref);
end;

function TOGGSyncState.PageOut(og : IOGGPage) : integer;
begin
  Result := ogg_sync_pageout(Ref, og.Ref);
end;

{ TOGGStreamState }

procedure TOGGStreamState.Init(serialno : integer);
var R : Integer;
begin
  R := ogg_stream_init(Ref, serialno);
  if R <> 0 then
    raise EOGGException.Create;
end;

procedure TOGGStreamState.Done;
begin
  ogg_stream_clear(Ref);
end;

function TOGGStreamState.Ref : pogg_stream_state;
begin
  Result := @FRef;
end;

constructor TOGGStreamState.Create(serialno : integer);
begin
  FillByte(FRef, sizeof(FRef), 0);
  Init(serialno);
end;

destructor TOGGStreamState.Destroy;
begin
  Done;
  inherited Destroy;
end;

procedure TOGGStreamState.Clear;
begin
   ogg_stream_clear(Ref);
end;

procedure TOGGStreamState.Reset;
var R : Integer;
begin
  R := ogg_stream_reset(Ref);
  if R <> 0 then
    raise EOGGException.Create;
end;

function TOGGStreamState.ResetSerialNo(serialno : integer) : integer;
begin
  Result := ogg_stream_reset_serialno(Ref, serialno);
end;

function TOGGStreamState.Check : Boolean;
begin
  Result := ogg_stream_check(Ref) = 0;
end;

function TOGGStreamState.EoS : Boolean;
begin
  Result := ogg_stream_eos(Ref) <> 0;
end;

procedure TOGGStreamState.PacketIn(op : IOGGPacket);
var R : Integer;
begin
  R := ogg_stream_packetin(Ref, op.Ref);
  if R < 0 then
    raise EOGGException.Create;
end;

procedure TOGGStreamState.IOVecIn(iov : IOGGIOVec; e_o_s : Boolean;
  granulepos : ogg_int64_t);
var R : Integer;
begin
  R := ogg_stream_iovecin(Ref, iov.Ref, iov.count, Byte(e_o_s), granulepos);
  if R < 0 then
    raise EOGGException.Create;
end;

function TOGGStreamState.PageOutNew : IOGGPage;
begin
  Result := TOGG.NewPage;
  if not PageOut(Result) then
    raise EOGGException.Create(ERR_INSUF);
end;

function TOGGStreamState.PageOut(og : IOGGPage) : Boolean;
begin
  Result := ogg_stream_pageout(Ref, og.Ref) <> 0;
end;

function TOGGStreamState.PageOutFill(og : IOGGPage; nfill : integer) : Boolean;
begin
  Result := ogg_stream_pageout_fill(Ref, og.Ref, nfill) <> 0;
end;

procedure TOGGStreamState.PageOutToStream(aStr : TStream);
var og : IOGGPage;
begin
  og := PageOutNew;
  aStr.Write(og.Ref^.header^, og.Ref^.header_len);
  aStr.Write(og.Ref^.body^, og.Ref^.body_len);
end;

procedure TOGGStreamState.PagesOutToStream(aStr : TStream);
var og : IOGGPage;
begin
  og := TOGG.NewPage;
  while PageOut(og) do
  begin
    aStr.Write(og.Ref^.header^, og.Ref^.header_len);
    aStr.Write(og.Ref^.body^, og.Ref^.body_len);
  end;
end;

procedure TOGGStreamState.SavePacketToStream(aStr : TStream; op : IOGGPacket);
begin
  PacketIn(op);
  PagesOutToStream(aStr);
end;

function TOGGStreamState.Flush(og : IOGGPage) : Boolean;
begin
  Result := ogg_stream_flush(Ref, og.Ref) <> 0;
end;

function TOGGStreamState.FlushFill(og : IOGGPage; nfill : integer) : Boolean;
begin
  Result := ogg_stream_flush_fill(Ref, og.Ref, nfill) <> 0;
end;

procedure TOGGStreamState.PageIn(og : IOGGPage);
var R : Integer;
begin
  R := ogg_stream_pagein(Ref, og.Ref);
  if R < 0 then
    raise EOGGException.Create;
end;

function TOGGStreamState.PacketOut(op : IOGGPacket) : Boolean;
var R : Integer;
begin
  R := ogg_stream_packetout(Ref, op.Ref);
  if R = 1 then
    Exit(True) else
  if R = 0 then
    raise EOGGException.Create else
    Exit(False);
end;

function TOGGStreamState.PacketPeek(op : IOGGPacket) : Boolean;
var R : Integer;
begin
  R := ogg_stream_packetpeek(Ref, op.Ref);
  if R = 1 then
    Exit(True) else
  if R = 0 then
    raise EOGGException.Create else
    Exit(False);
end;

{ TOGGPacket }

function TOGGPacket.Ref : pogg_packet;
begin
  Result := @FRef;
end;

constructor TOGGPacket.Create;
begin
  FillByte(FRef, SizeOf(FRef), 0);
end;

procedure TOGGPacket.Clear;
begin
  ogg_packet_clear(Ref);
end;

{ TOGGPage }

function TOGGPage.Ref : pogg_page;
begin
  Result := @FRef;
end;

constructor TOGGPage.Create;
begin
  FillByte(FRef, SizeOf(FRef), 0);
end;

procedure TOGGPage.ChecksumSet;
begin
  ogg_page_checksum_set(Ref);
end;

function TOGGPage.Version : integer;
begin
  Result := ogg_page_version(Ref);
end;

function TOGGPage.Continued : Boolean;
begin
  Result := ogg_page_continued(Ref) > 0;
end;

function TOGGPage.BoS : Boolean;
begin
  Result := ogg_page_bos(Ref) > 0;
end;

function TOGGPage.EoS : Boolean;
begin
  Result := ogg_page_eos(Ref) > 0;
end;

function TOGGPage.GranulePos : ogg_int64_t;
begin
  Result := ogg_page_granulepos(Ref);
end;

function TOGGPage.SerialNo : integer;
begin
  Result := ogg_page_serialno(Ref);
end;

function TOGGPage.PageNo : longint;
begin
  Result := ogg_page_pageno(Ref);
end;

function TOGGPage.Packets : integer;
begin
  Result := ogg_page_packets(Ref);
end;

{ TOGGIOVecListed }

constructor TOGGIOVecListed.Create;
begin
  FRef := TFastIOVecList.Create;
end;

destructor TOGGIOVecListed.Destroy;
begin
  FRef.Free;
  inherited Destroy;
end;

procedure TOGGIOVecListed.AddBuffer(iov_base : Pointer; iov_len : SizeUInt);
var p : ogg_iovec_t;
begin
  p.iov_base := iov_base;
  p.iov_len := iov_len;
  FRef.Add(p);
end;

function TOGGIOVecListed.GetBufferAt(pos : integer) : pogg_iovec_t;
begin
  Result := @(FRef.List^[pos]);
end;

function TOGGIOVecListed.Count : Integer;
begin
  Result := FRef.Count;
end;

function TOGGIOVecListed.Ref : pogg_iovec_t;
begin
  Result := pogg_iovec_t(FRef.List);
end;

end.

