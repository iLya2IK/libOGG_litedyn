{
 OGLOGGWrapper:
   Wrapper for OGG library

   Copyright (c) 2022-2023 by Ilya Medvedkov

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
    function PageInIgnoreErrors(og: IOGGPage): Integer;
    function PacketOut(op: IOGGPacket): Boolean;
    function PacketOutIgnoreErrors(op: IOGGPacket): Integer;
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

  { IOGGComment }

  IOGGComment = interface(IUnknown)
    ['{E4D5A74F-91D3-44EC-9CC8-40669CEBB75E}']
    function Ref : Pointer;

    procedure Init;
    procedure Done;

    procedure Add(const comment: String);
    procedure AddTag(const tag, value: String);
    function Query(const tag: String; index: integer): String;
    function QueryCount(const tag: String): integer;
  end;

  TOGGEncDecType = (edtEncoder, edtDecoder);

  { IOGGEncDec }

  IOGGEncDec = interface(IUnknown)
    ['{5881282E-DEF3-40B1-ABC3-87ABFF82E878}']
    function InternalType : TOGGEncDecType;
    function Ready : Boolean;
  end;

  TOGGSoundEncoderMode = (oemCBR, oemVBR);
  TOGGSoundDataMode = (odmBytes, odmSamples);

  { TOGGSoundAbstractEncDec }

  TOGGSoundAbstractEncDec = class
  protected
    function GetBitdepth : Cardinal; virtual; abstract;
    function GetBitrate : Cardinal; virtual; abstract;
    function GetChannels : Cardinal; virtual; abstract;
    function GetFrequency : Cardinal; virtual; abstract;
    function GetVersion : Integer; virtual; abstract;

    procedure SetBitdepth({%H-}AValue : Cardinal); virtual;
    procedure SetBitrate({%H-}AValue : Cardinal); virtual;
    procedure SetChannels({%H-}AValue : Cardinal); virtual;
    procedure SetFrequency({%H-}AValue : Cardinal); virtual;

    procedure Done; virtual; abstract;
  public
    function DataMode  : TOGGSoundDataMode; virtual; abstract;
    function Comments : IOGGComment; virtual; abstract;
    function InternalType : TOGGEncDecType; virtual; abstract;
    function Ready : Boolean; virtual; abstract;

    property Channels : Cardinal read GetChannels write SetChannels;
    property Frequency : Cardinal read GetFrequency write SetFrequency;
    property Bitrate : Cardinal read GetBitrate write SetBitrate;
    property Bitdepth : Cardinal read GetBitdepth write SetBitdepth;
    property Version : Integer read GetVersion;
  end;

  { TOGGSoundEncoder }

  TOGGSoundEncoder = class(TOGGSoundAbstractEncDec)
  protected
    function GetMode : TOGGSoundEncoderMode; virtual; abstract;
    function GetQuality : Single; virtual; abstract;
    procedure SetMode({%H-}AValue : TOGGSoundEncoderMode); virtual;
    procedure SetQuality({%H-}AValue : Single); virtual;

    procedure Init(aMode : TOGGSoundEncoderMode;
                   aChannels : Cardinal;
                   aFreq, aBitrate, aBitdepth : Cardinal;
                   aQuality : Single;
                   aComments : IOGGComment); virtual; abstract;

    //method to write encoded data
    function DoWrite({%H-}Buffer : Pointer; {%H-}BufferSize : Integer) : Integer; virtual;
  public
    function InternalType : TOGGEncDecType; override;

    //method to encode raw pcm data
    function  WriteData({%H-}Buffer : Pointer; {%H-}Count : Integer; {%H-}Par : Pointer) : Integer; virtual;
    //method to encode header/comments
    procedure WriteHeader({%H-}Par : Pointer); virtual;
    //method to close encoder (write last packet/flush/finalize encoder)
    procedure Close({%H-}Par : Pointer); virtual;
    //method to flush encoder (write last packet/flush encoder)
    procedure Flush({%H-}Par : Pointer); virtual;

    property Quality : Single read GetQuality write SetQuality;
    property Mode : TOGGSoundEncoderMode read GetMode write SetMode;
  end;

  { TOGGSoundDecoder }

  TOGGSoundDecoder = class(TOGGSoundAbstractEncDec)
  protected
    procedure Init; virtual; abstract;

    //method to read encoded data from stream
    function DoRead({%H-}_ptr : Pointer; {%H-}_nbytes : Integer) : Integer; virtual;
    //method to seek in encoded stream
    function DoSeek({%H-}_offset:Int64; {%H-}_whence:Integer): Integer; virtual;
    //method to tell current position in encoded stream
    function DoTell:Int64; virtual;
  public
    //method to read decoded data
    function  ReadData({%H-}Buffer : Pointer; {%H-}Count : Integer; {%H-}Par : Pointer) : Integer; virtual;
    //method to reset decoder
    procedure ResetToStart; virtual;

    function InternalType : TOGGEncDecType; override;
  end;


  { TOGGSoundFile }

  TOGGSoundFile = class
  private
    fStream: TStream;

    //encoder/decoder spec
    fEncDec : TOGGSoundAbstractEncDec;
  protected
    procedure Clean; virtual;
    procedure WriteHeader; virtual;
    function InitEncoder(aMode : TOGGSoundEncoderMode;
                   aChannels : Cardinal;
                   aFreq, aBitrate, aBitdepth : Cardinal;
                   aQuality : Single;
                   aComments : IOGGComment) : TOGGSoundEncoder; virtual;
                                                                abstract;
    function InitDecoder : TOGGSoundDecoder; virtual; abstract;
  public
    destructor Destroy; override;

    function Stream : TStream; virtual;

    function LoadFromFile(const aFileName : String; const aInMemory : Boolean
      ) : Boolean; virtual;
    function LoadFromStream(Str : TStream) : Boolean; virtual;
    function ReadData(Buffer : Pointer; BufferSize : Integer; Ptr : Pointer) : Integer; virtual;
    procedure ResetToStart; virtual;
    function Decoder : TOGGSoundDecoder;
    function DecoderReady : Boolean; virtual;

    function SaveToFile(const aFileName : String;
      amode : TOGGSoundEncoderMode;
      achannels : Integer;
      afreq, abitrate, abitdepth : Cardinal;
      base_quality : Single;
      aComments : IOGGComment) : Boolean; virtual;
    function SaveToStream(Str : TStream;
      amode : TOGGSoundEncoderMode;
      achannels : Integer;
      afreq, abitrate, abitdepth : Cardinal;
      base_quality : Single;
      aComments : IOGGComment) : Boolean; virtual;
    function WriteSamples(Buffer : Pointer; Count : Integer; Ptr : Pointer
      ) : Integer; virtual;
    procedure StopStreaming; virtual;
    function Encoder : TOGGSoundEncoder;
    function EncoderReady : Boolean; virtual;

    function SamplesToBytes(s : Integer) : Integer; virtual;
    function BytesToSamples(b : Integer) : Integer; virtual;

    function Frequency : Cardinal; virtual;
    function Bitrate  : Cardinal; virtual;
    function Bitdepth : Cardinal; virtual;
    function Channels : Cardinal; virtual;
    function Version  : Cardinal; virtual;
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

  { TOGGRefPage }

  TOGGRefPage = class(TInterfacedObject, IOGGPage)
  private
    FPRef : pogg_page;
  public
    function Ref : pogg_page; inline;

    constructor Create(aRef : pogg_page);

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

  { TOGGUniqPage }

  TOGGUniqPage = class(TOGGRefPage)
  private
    FRef : ogg_page;
  public
    constructor Create;
  end;

  { TOGGRefPacket }

  TOGGRefPacket = class(TInterfacedObject, IOGGPacket)
  private
    FPRef : pogg_packet;
  public
    function Ref : pogg_packet; inline;

    constructor Create(aRef : pogg_packet);

    procedure Clear;
  end;

  { TOGGUniqPacket }

  TOGGUniqPacket = class(TOGGRefPacket)
  private
    FRef : ogg_packet;
  public
    constructor Create;
  end;

  { TOGGRefStreamState }

  TOGGRefStreamState = class(TInterfacedObject, IOGGStreamState)
  private
    FPRef : pogg_stream_state;
    procedure Init(serialno: integer);
    procedure Done;
  public
    function Ref : pogg_stream_state; inline;

    constructor Create(aRef : pogg_stream_state);

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
    function PageInIgnoreErrors(og: IOGGPage): Integer;
    function PacketOut(op: IOGGPacket): Boolean;
    function PacketOutIgnoreErrors(op: IOGGPacket): Integer;
    function PacketPeek(op: IOGGPacket): Boolean;
  end;

  { TOGGUniqStreamState }

  TOGGUniqStreamState = class(TOGGRefStreamState)
  private
    FRef : ogg_stream_state;
  public
    constructor Create(serialno : integer);
    destructor Destroy; override;
  end;

  { TOGGRefSyncState }

  TOGGRefSyncState = class(TInterfacedObject, IOGGSyncState)
  private
    FPRef : pogg_sync_state;
    function Init: integer;
    function Done: integer;
  public
    function Ref : pogg_sync_state; inline;

    constructor Create(aRef : pogg_sync_state);

    function Clear: integer;
    function Reset: integer;
    function Check: integer;
    function Buffer(size: longint): pointer;
    function Wrote(bytes: longint): integer;
    function PageSeek(og: IOGGPage): longint;
    function PageOut(og: IOGGPage): integer;
  end;

  { TOGGUniqSyncState }

  TOGGUniqSyncState = class(TOGGRefSyncState)
  private
    FRef : ogg_sync_state;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  { TOGGRefPackBuffer }

  TOGGRefPackBuffer = class(TInterfacedObject, IOGGPackBuffer)
  private
    FPRef : poggpack_buffer;
    FEnd : TOGGEndian;
  public
    function Ref : poggpack_buffer; inline;

    constructor Create(aRef : poggpack_buffer; aEndian : TOGGEndian);

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

  { TOGGUniqPackBuffer }

  TOGGUniqPackBuffer = class(TOGGRefPackBuffer)
  private
    FRef : oggpack_buffer;
  public
    constructor Create(aEndian : TOGGEndian);
  end;

  { TOGG }

  TOGG = class
  public
    class function NewPackBuffer(aEndian : TOGGEndian) : IOGGPackBuffer;
    class function RefPackBuffer(aRef : poggpack_buffer; aEndian : TOGGEndian) : IOGGPackBuffer;
    class function NewSyncState : IOGGSyncState;
    class function RefSyncState(st : pogg_sync_state) : IOGGSyncState;
    class function NewStream(serialno : integer) : IOGGStreamState;
    class function RefStream(st : pogg_stream_state) : IOGGStreamState;
    class function NewPacket : IOGGPacket;
    class function RefPacket(st : pogg_packet) : IOGGPacket;
    class function NewPage : IOGGPage;
    class function RefPage(st : pogg_page) : IOGGPage;
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

{ TOGGSoundAbstractEncDec }

procedure TOGGSoundAbstractEncDec.SetBitdepth(AValue : Cardinal);
begin
  //do nothing
end;

procedure TOGGSoundAbstractEncDec.SetBitrate(AValue : Cardinal);
begin
  //do nothing
end;

procedure TOGGSoundAbstractEncDec.SetChannels(AValue : Cardinal);
begin
  //do nothing
end;

procedure TOGGSoundAbstractEncDec.SetFrequency(AValue : Cardinal);
begin
  //do nothing
end;

{ TOGGSoundEncoder }

procedure TOGGSoundEncoder.SetMode(AValue : TOGGSoundEncoderMode);
begin
  //do nothing
end;

procedure TOGGSoundEncoder.SetQuality(AValue : Single);
begin
  //do nothing
end;

function TOGGSoundEncoder.WriteData(Buffer : Pointer; Count : Integer;
  Par : Pointer) : Integer;
begin
  Result := -1;
end;

procedure TOGGSoundEncoder.WriteHeader(Par : Pointer);
begin
  //do nothing
end;

procedure TOGGSoundEncoder.Close(Par : Pointer);
begin
  //do nothing
end;

procedure TOGGSoundEncoder.Flush(Par : Pointer);
begin
  //do nothing
end;

function TOGGSoundEncoder.DoWrite(Buffer : Pointer; BufferSize : Integer
  ) : Integer;
begin
  Result := -1;
end;

function TOGGSoundEncoder.InternalType : TOGGEncDecType;
begin
  Result := edtEncoder;
end;

{ TOGGSoundDecoder }

function TOGGSoundDecoder.ReadData(Buffer : Pointer; Count : Integer;
  Par : Pointer) : Integer;
begin
  Result := -1;
end;

procedure TOGGSoundDecoder.ResetToStart;
begin
  //do nothing
end;

function TOGGSoundDecoder.DoRead(_ptr : Pointer; _nbytes : Integer) : Integer;
begin
  Result := -1;
end;

function TOGGSoundDecoder.DoSeek(_offset : Int64; _whence : Integer) : Integer;
begin
  Result := -1;
end;

function TOGGSoundDecoder.DoTell : Int64;
begin
  Result := -1;
end;

function TOGGSoundDecoder.InternalType : TOGGEncDecType;
begin
  Result := edtDecoder;
end;

{ TOGGSoundFile }

procedure TOGGSoundFile.Clean;
begin
  if Assigned(fEncDec) then
    FreeAndNil(fEncDec);
  if Assigned(fStream) then
    FreeAndNil(fStream);
end;

procedure TOGGSoundFile.WriteHeader;
begin
  if EncoderReady then
    Encoder.WriteHeader(nil);
end;

function TOGGSoundFile.SamplesToBytes(s : Integer) : Integer;
begin
  Result := (s * (Bitdepth div 8)) * Channels;
end;

function TOGGSoundFile.BytesToSamples(b : Integer) : Integer;
begin
  Result := (b div (Bitdepth div 8)) div Channels;
end;

destructor TOGGSoundFile.Destroy;
begin
  Clean;
  inherited Destroy;
end;

function TOGGSoundFile.LoadFromFile(const aFileName : String;
  const aInMemory : Boolean) : Boolean;
var
  cFilestream : TFileStream;
  cStr : TStream;
begin
  if aInMemory then
  begin
    cFilestream := TFileStream.Create(aFileName, fmOpenRead);
    if Assigned(cFilestream) then
    begin
      try
        cStr := TMemoryStream.Create;
        cStr.CopyFrom(cFilestream, cFilestream.Size);
        cStr.Position := 0;
      finally
        cFilestream.Free;
      end;
    end else
      cStr := nil;
  end
  else
    cStr := TFileStream.Create(aFileName, fmOpenRead);

  Result := LoadFromStream(cStr);
end;

function TOGGSoundFile.LoadFromStream(Str : TStream) : Boolean;
begin
  Clean;

  fStream := Str;

  try
    fEncDec :=  InitDecoder;
    Result := fEncDec.Ready;
  except
    on e : Exception do Result := false;
  end;
end;

function TOGGSoundFile.ReadData(Buffer : Pointer; BufferSize : Integer;
  Ptr : Pointer) : Integer;
var
  Size, Res, samples: Integer;
begin
  if Assigned(fStream) and DecoderReady then
  begin
    Size := 0;

    if Decoder.DataMode = odmBytes then
    begin
      while (Size < BufferSize) do begin
        Res := Decoder.ReadData(@(PByte(Buffer)[Size]),
                                   BufferSize - Size,
                                   Ptr);
        if Res > 0 then inc(Size, Res) else break;
      end;
      Result := Size;
    end else
    begin
      samples := BytesToSamples(BufferSize);
      while (Size < samples) do begin
        Res := Decoder.ReadData(@(PByte(Buffer)[SamplesToBytes(Size)]),
                                   samples - Size,
                                   Ptr);
        if Res > 0 then inc(Size, Res) else break;
      end;
      Result := SamplesToBytes(Size);
    end;
  end else
    Result := -1;
end;

procedure TOGGSoundFile.ResetToStart;
begin
  if DecoderReady then
    Decoder.ResetToStart;
end;

function TOGGSoundFile.Decoder : TOGGSoundDecoder;
begin
  Result := TOGGSoundDecoder(fEncDec);
end;

function TOGGSoundFile.DecoderReady : Boolean;
begin
  Result := Assigned(fEncDec) and
            (fEncDec.InternalType = edtDecoder) and
            fEncDec.Ready;
end;

function TOGGSoundFile.Stream : TStream;
begin
  Result := fStream;
end;

function TOGGSoundFile.SaveToFile(const aFileName : String;
  amode : TOGGSoundEncoderMode; achannels : Integer; afreq, abitrate,
  abitdepth : Cardinal; base_quality : Single; aComments : IOGGComment
  ) : Boolean;
var
  Str : TFileStream;
begin
  Str := TFileStream.Create(aFileName, fmOpenWrite or fmCreate);
  if Assigned(Str) then
    Result := SaveToStream(Str, amode, achannels, afreq,
                                abitrate, abitdepth,
                                base_quality, aComments) else
      Result := false;
end;

function TOGGSoundFile.SaveToStream(Str : TStream;
  amode : TOGGSoundEncoderMode; achannels : Integer; afreq, abitrate,
  abitdepth : Cardinal; base_quality : Single; aComments : IOGGComment
  ) : Boolean;
begin
  Clean;

  fStream := Str;

  try
    try
      fEncDec :=  InitEncoder(amode,achannels, afreq,
                              abitrate, abitdepth,
                              base_quality, aComments);
      Result := fEncDec.Ready;
    except
      on e : Exception do Result := false;
    end;
  finally
    if Result then
      WriteHeader;
  end;
end;

function TOGGSoundFile.WriteSamples(Buffer : Pointer;
                                           Count : Integer;
                                           Ptr : Pointer) : Integer;
var
  Size, Res, BuffCount : Integer;
begin
  if Assigned(fStream) and EncoderReady then
  begin
    if Count > 0 then
    begin
      Size := 0;

      if Decoder.DataMode = odmBytes then
      begin
        BuffCount := SamplesToBytes(Count);
        while Size < BuffCount do
        begin
          Res := Encoder.WriteData(@(PByte(Buffer)[Size]),
                                   BuffCount - Size,
                                   Ptr);
          if Res <= 0 then Break;
          Inc(Size, Res);
        end;
        Result := BytesToSamples(Size);
      end else
      begin
        while Size < Count do
        begin
          Res := Encoder.WriteData(@(PByte(Buffer)[Size]),
                                   Count - Size,
                                   Ptr);
          if Res <= 0 then Break;
          Inc(Size, Res);
        end;
        Result := Size;
      end;
    end else
      Result := 0;
  end else
    Result := -1;
end;

procedure TOGGSoundFile.StopStreaming;
begin
  if EncoderReady then
     Encoder.Close(nil);
end;

function TOGGSoundFile.Encoder : TOGGSoundEncoder;
begin
  Result := TOGGSoundEncoder(fEncDec);
end;

function TOGGSoundFile.EncoderReady : Boolean;
begin
  Result := Assigned(fEncDec) and
            (fEncDec.InternalType = edtEncoder) and
            fEncDec.Ready;
end;

function TOGGSoundFile.Frequency : Cardinal;
begin
  if Assigned(fEncDec) then
    Result := fEncDec.Frequency else
    Result := 0;
end;

function TOGGSoundFile.Bitrate : Cardinal;
begin
  if Assigned(fEncDec) then
    Result := fEncDec.Bitrate else
    Result := 0;
end;

function TOGGSoundFile.Bitdepth : Cardinal;
begin
  if Assigned(fEncDec) then
    Result := fEncDec.Bitdepth else
    Result := 0;
end;

function TOGGSoundFile.Channels : Cardinal;
begin
  if Assigned(fEncDec) then
    Result := fEncDec.Channels else
    Result := 0;
end;

function TOGGSoundFile.Version : Cardinal;
begin
  if Assigned(fEncDec) then
    Result := fEncDec.Version else
    Result := 0;
end;

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
  Result := TOGGUniqPackBuffer.Create(aEndian) as IOGGPackBuffer;
end;

class function TOGG.RefPackBuffer(aRef : poggpack_buffer; aEndian : TOGGEndian
  ) : IOGGPackBuffer;
begin
  Result := TOGGRefPackBuffer.Create(aRef, aEndian) as IOGGPackBuffer;
end;

class function TOGG.NewSyncState : IOGGSyncState;
begin
  Result := TOGGUniqSyncState.Create as IOGGSyncState;
end;

class function TOGG.RefSyncState(st : pogg_sync_state) : IOGGSyncState;
begin
  Result := TOGGRefSyncState.Create(st) as IOGGSyncState;
end;

class function TOGG.NewStream(serialno : integer) : IOGGStreamState;
begin
  Result := TOGGUniqStreamState.Create(serialno) as IOGGStreamState;
end;

class function TOGG.RefStream(st : pogg_stream_state) : IOGGStreamState;
begin
  Result := TOGGRefStreamState.Create(st) as IOGGStreamState;
end;

class function TOGG.NewPacket : IOGGPacket;
begin
  Result := TOGGUniqPacket.Create() as IOGGPacket;
end;

class function TOGG.RefPacket(st : pogg_packet) : IOGGPacket;
begin
  Result := TOGGRefPacket.Create(st) as IOGGPacket;
end;

class function TOGG.NewPage : IOGGPage;
begin
  Result := TOGGUniqPage.Create() as IOGGPage;
end;

class function TOGG.RefPage(st : pogg_page) : IOGGPage;
begin
  Result := TOGGRefPage.Create(st) as IOGGPage;
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

{ TOGGRefPackBuffer }

function TOGGRefPackBuffer.Ref : poggpack_buffer;
begin
  Result := FPRef;
end;

constructor TOGGRefPackBuffer.Create( aRef : poggpack_buffer; aEndian : TOGGEndian);
begin
  FPRef := aRef;
  FEnd := aEndian;
end;

procedure TOGGRefPackBuffer.SetEndianMode(e : TOGGEndian);
begin
  FEnd := e;
end;

function TOGGRefPackBuffer.GetEndianMode : TOGGEndian;
begin
  Result := Fend;
end;

procedure TOGGRefPackBuffer.WriteInit;
begin
  case Fend of
    oggeLE: oggpack_writeinit(Ref);
    oggeBE: oggpackB_writeinit(Ref);
  end;
end;

function TOGGRefPackBuffer.WriteCheck : integer;
begin
  case Fend of
    oggeLE: Result := oggpack_writecheck(Ref);
    oggeBE: Result := oggpackB_writecheck(Ref);
  end;
end;

procedure TOGGRefPackBuffer.WriteTrunc(bits : longint);
begin
  case Fend of
    oggeLE: oggpack_writetrunc(Ref, bits);
    oggeBE: oggpackB_writetrunc(Ref, bits);
  end;
end;

procedure TOGGRefPackBuffer.WriteAlign;
begin
  case Fend of
    oggeLE: oggpack_writealign(Ref);
    oggeBE: oggpackB_writealign(Ref);
  end;
end;

procedure TOGGRefPackBuffer.WriteCopy(source : pointer; bits : longint);
begin
  case Fend of
    oggeLE: oggpack_writecopy(Ref, source, bits);
    oggeBE: oggpackB_writecopy(Ref, source, bits);
  end;
end;

procedure TOGGRefPackBuffer.Reset;
begin
  case Fend of
    oggeLE:  oggpack_reset(Ref);
    oggeBE: oggpackB_reset(Ref);
  end;
end;

procedure TOGGRefPackBuffer.WriteClear;
begin
  case Fend of
    oggeLE:  oggpack_writeclear(Ref);
    oggeBE: oggpackB_writeclear(Ref);
  end;
end;

procedure TOGGRefPackBuffer.ReadInit(buf : pbyte; bytes : integer);
begin
  case Fend of
    oggeLE:  oggpack_readinit(Ref, buf, bytes);
    oggeBE: oggpackB_readinit(Ref, buf, bytes);
  end;
end;

procedure TOGGRefPackBuffer.Write(value : cardinal; bits : integer);
begin
  case Fend of
    oggeLE:  oggpack_write(Ref, value, bits);
    oggeBE: oggpackB_write(Ref, value, bits);
  end;
end;

function TOGGRefPackBuffer.Look(bits : integer) : longint;
begin
  case Fend of
    oggeLE: Result :=  oggpack_look(Ref, bits);
    oggeBE: Result :=  oggpackB_look(Ref, bits);
  end;
end;

function TOGGRefPackBuffer.Look1bit : longint;
begin
  case Fend of
    oggeLE: Result :=  oggpack_look1(Ref);
    oggeBE: Result := oggpackB_look1(Ref);
  end;
end;

procedure TOGGRefPackBuffer.Adv(bits : integer);
begin
  case Fend of
    oggeLE:  oggpack_adv(Ref, bits);
    oggeBE: oggpackB_adv(Ref, bits);
  end;
end;

procedure TOGGRefPackBuffer.Adv1bit;
begin
  case Fend of
    oggeLE:  oggpack_adv1(Ref);
    oggeBE: oggpackB_adv1(Ref);
  end;
end;

function TOGGRefPackBuffer.Read(bits : integer) : longint;
begin
  case Fend of
    oggeLE: Result :=  oggpack_read(Ref, bits);
    oggeBE: Result := oggpackB_read(Ref, bits);
  end;
end;

function TOGGRefPackBuffer.Read1 : longint;
begin
  case Fend of
    oggeLE: Result :=  oggpack_read1(Ref);
    oggeBE: Result := oggpackB_read1(Ref);
  end;
end;

function TOGGRefPackBuffer.Bytes : longint;
begin
  case Fend of
    oggeLE: Result :=  oggpack_bytes(Ref);
    oggeBE: Result := oggpackB_bytes(Ref);
  end;
end;

function TOGGRefPackBuffer.Bits : longint;
begin
  case Fend of
    oggeLE: Result :=  oggpack_bits(Ref);
    oggeBE: Result := oggpackB_bits(Ref);
  end;
end;

function TOGGRefPackBuffer.GetBuffer : pbyte;
begin
  case Fend of
    oggeLE: Result :=  oggpack_get_buffer(Ref);
    oggeBE: Result := oggpackB_get_buffer(Ref);
  end;
end;

{ TOGGUniqPackBuffer }

constructor TOGGUniqPackBuffer.Create(aEndian : TOGGEndian);
begin
  inherited Create(@FRef, aEndian);
end;

{ TOGGRefSyncState }

function TOGGRefSyncState.Init : integer;
begin
  Result := ogg_sync_init(Ref);
end;

function TOGGRefSyncState.Done : integer;
begin
  Result := ogg_sync_clear(Ref);
end;

function TOGGRefSyncState.Ref : pogg_sync_state;
begin
  Result := FPRef;
end;

constructor TOGGRefSyncState.Create(aRef : pogg_sync_state);
begin
  FPRef := aRef;
end;

function TOGGRefSyncState.Clear : integer;
begin
   Result := ogg_sync_clear(Ref);
end;

function TOGGRefSyncState.Reset : integer;
begin
  Result := ogg_sync_reset(Ref);
end;

function TOGGRefSyncState.Check : integer;
begin
  Result := ogg_sync_check(Ref);
end;

function TOGGRefSyncState.Buffer(size : longint) : pointer;
begin
  Result := ogg_sync_buffer(Ref, size);
end;

function TOGGRefSyncState.Wrote(bytes : longint) : integer;
begin
  Result := ogg_sync_wrote(Ref, bytes);
end;

function TOGGRefSyncState.PageSeek(og : IOGGPage) : longint;
begin
  Result := ogg_sync_pageseek(Ref, og.Ref);
end;

function TOGGRefSyncState.PageOut(og : IOGGPage) : integer;
begin
  Result := ogg_sync_pageout(Ref, og.Ref);
end;

{ TOGGUniqSyncState }

constructor TOGGUniqSyncState.Create;
begin
  FillByte(FRef, Sizeof(FRef), 0);
  inherited Create(@FRef);
  Init;
end;

destructor TOGGUniqSyncState.Destroy;
begin
  Done;
  inherited Destroy;
end;

{ TOGGRefStreamState }

procedure TOGGRefStreamState.Init(serialno : integer);
var R : Integer;
begin
  R := ogg_stream_init(Ref, serialno);
  if R <> 0 then
    raise EOGGException.Create;
end;

procedure TOGGRefStreamState.Done;
begin
  ogg_stream_clear(Ref);
end;

function TOGGRefStreamState.Ref : pogg_stream_state;
begin
  Result := FPRef;
end;

constructor TOGGRefStreamState.Create(aRef : pogg_stream_state);
begin
  FPRef := aRef;
end;

procedure TOGGRefStreamState.Clear;
begin
   ogg_stream_clear(Ref);
end;

procedure TOGGRefStreamState.Reset;
var R : Integer;
begin
  R := ogg_stream_reset(Ref);
  if R <> 0 then
    raise EOGGException.Create;
end;

function TOGGRefStreamState.ResetSerialNo(serialno : integer) : integer;
begin
  Result := ogg_stream_reset_serialno(Ref, serialno);
end;

function TOGGRefStreamState.Check : Boolean;
begin
  Result := ogg_stream_check(Ref) = 0;
end;

function TOGGRefStreamState.EoS : Boolean;
begin
  Result := ogg_stream_eos(Ref) <> 0;
end;

procedure TOGGRefStreamState.PacketIn(op : IOGGPacket);
var R : Integer;
begin
  R := ogg_stream_packetin(Ref, op.Ref);
  if R < 0 then
    raise EOGGException.Create;
end;

procedure TOGGRefStreamState.IOVecIn(iov : IOGGIOVec; e_o_s : Boolean;
  granulepos : ogg_int64_t);
var R : Integer;
begin
  R := ogg_stream_iovecin(Ref, iov.Ref, iov.count, Byte(e_o_s), granulepos);
  if R < 0 then
    raise EOGGException.Create;
end;

function TOGGRefStreamState.PageOutNew : IOGGPage;
begin
  Result := TOGG.NewPage;
  if not PageOut(Result) then
    raise EOGGException.Create(ERR_INSUF);
end;

function TOGGRefStreamState.PageOut(og : IOGGPage) : Boolean;
begin
  Result := ogg_stream_pageout(Ref, og.Ref) <> 0;
end;

function TOGGRefStreamState.PageOutFill(og : IOGGPage; nfill : integer) : Boolean;
begin
  Result := ogg_stream_pageout_fill(Ref, og.Ref, nfill) <> 0;
end;

procedure TOGGRefStreamState.PageOutToStream(aStr : TStream);
var og : IOGGPage;
begin
  og := PageOutNew;
  aStr.Write(og.Ref^.header^, og.Ref^.header_len);
  aStr.Write(og.Ref^.body^, og.Ref^.body_len);
end;

procedure TOGGRefStreamState.PagesOutToStream(aStr : TStream);
var og : IOGGPage;
begin
  og := TOGG.NewPage;
  while PageOut(og) do
  begin
    aStr.Write(og.Ref^.header^, og.Ref^.header_len);
    aStr.Write(og.Ref^.body^, og.Ref^.body_len);
  end;
end;

procedure TOGGRefStreamState.SavePacketToStream(aStr : TStream; op : IOGGPacket);
begin
  PacketIn(op);
  PagesOutToStream(aStr);
end;

function TOGGRefStreamState.Flush(og : IOGGPage) : Boolean;
begin
  Result := ogg_stream_flush(Ref, og.Ref) <> 0;
end;

function TOGGRefStreamState.FlushFill(og : IOGGPage; nfill : integer) : Boolean;
begin
  Result := ogg_stream_flush_fill(Ref, og.Ref, nfill) <> 0;
end;

procedure TOGGRefStreamState.PageIn(og : IOGGPage);
var R : Integer;
begin
  R := ogg_stream_pagein(Ref, og.Ref);
  if R < 0 then
    raise EOGGException.Create;
end;

function TOGGRefStreamState.PageInIgnoreErrors(og : IOGGPage) : Integer;
begin
  Result := ogg_stream_pagein(Ref, og.Ref);
end;

function TOGGRefStreamState.PacketOut(op : IOGGPacket) : Boolean;
var R : Integer;
begin
  R := ogg_stream_packetout(Ref, op.Ref);
  if R = 1 then
    Exit(True) else
  if R < 0 then
    raise EOGGException.Create else
    Exit(False);
end;

function TOGGRefStreamState.PacketOutIgnoreErrors(op : IOGGPacket) : Integer;
begin
  Result := ogg_stream_packetout(Ref, op.Ref);
end;

function TOGGRefStreamState.PacketPeek(op : IOGGPacket) : Boolean;
var R : Integer;
begin
  R := ogg_stream_packetpeek(Ref, op.Ref);
  if R = 1 then
    Exit(True) else
  if R < 0 then
    raise EOGGException.Create else
    Exit(False);
end;

{ TOGGUniqStreamState }

constructor TOGGUniqStreamState.Create(serialno : integer);
begin
  FillByte(FRef, sizeof(FRef), 0);
  inherited Create(@FRef);
  Init(serialno);
end;

destructor TOGGUniqStreamState.Destroy;
begin
  Done;
  inherited Destroy;
end;

{ TOGGRefPacket }

function TOGGRefPacket.Ref : pogg_packet;
begin
  Result := FPRef;
end;

constructor TOGGRefPacket.Create(aRef : pogg_packet);
begin
  FPRef := aRef;
end;

procedure TOGGRefPacket.Clear;
begin
  ogg_packet_clear(FPRef);
end;

{ TOGGUniqPacket }

constructor TOGGUniqPacket.Create;
begin
  FillByte(FRef, Sizeof(FRef), 0);
  inherited Create(@FRef);
end;

{ TOGGRefPage }

function TOGGRefPage.Ref : pogg_page;
begin
  Result := FPRef;
end;

constructor TOGGRefPage.Create(aRef : pogg_page);
begin
  FPRef := aRef;
end;

procedure TOGGRefPage.ChecksumSet;
begin
  ogg_page_checksum_set(FPRef);
end;

function TOGGRefPage.Version : integer;
begin
  Result := ogg_page_version(FPRef);
end;

function TOGGRefPage.Continued : Boolean;
begin
  Result := ogg_page_continued(FPRef) > 0;
end;

function TOGGRefPage.BoS : Boolean;
begin
  Result := ogg_page_bos(FPRef) > 0;
end;

function TOGGRefPage.EoS : Boolean;
begin
  Result := ogg_page_eos(FPRef) > 0;
end;

function TOGGRefPage.GranulePos : ogg_int64_t;
begin
  Result := ogg_page_granulepos(FPRef);
end;

function TOGGRefPage.SerialNo : integer;
begin
  Result := ogg_page_serialno(FPRef);
end;

function TOGGRefPage.PageNo : longint;
begin
  Result := ogg_page_pageno(FPRef);
end;

function TOGGRefPage.Packets : integer;
begin
  Result := ogg_page_packets(FPRef);
end;

{ TOGGUniqPage }

constructor TOGGUniqPage.Create;
begin
  FillByte(FRef, SizeOf(FRef), 0);
  inherited Create(@FRef);
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

