(******************************************************************************)
(*                               libOGG_dynlite                               *)
(*                   free pascal wrapper around OGG library                   *)
(*                        https://www.xiph.org/ogg/.org/                      *)
(*                                                                            *)
(* Copyright (c) 2022 Ilya Medvedkov                                          *)
(******************************************************************************)
(*                                                                            *)
(* This source  is free software;  you can redistribute  it and/or modify  it *)
(* under the terms of the  GNU Lesser General Public License  as published by *)
(* the Free Software Foundation; either version 3 of the License (LGPL v3).   *)
(*                                                                            *)
(* This code is distributed in the  hope that it will  be useful, but WITHOUT *)
(* ANY  WARRANTY;  without even  the implied  warranty of MERCHANTABILITY  or *)
(* FITNESS FOR A PARTICULAR PURPOSE.                                          *)
(* See the GNU Lesser General Public License for more details.                *)
(*                                                                            *)
(* A copy of the GNU Lesser General Public License is available on the World  *)
(* Wide Web at <https://www.gnu.org/licenses/lgpl-3.0.html>.                  *)
(*                                                                            *)
(******************************************************************************)

unit libOGG_dynlite;

{$mode objfpc}{$H+}

{$packrecords c}
{$MINENUMSIZE 4}

interface

uses dynlibs, SysUtils, ctypes;

const
{$if defined(UNIX) and not defined(darwin)}
  OGGDLL : Array [0..0] of String = ('libogg.so');
{$ELSE}
{$ifdef WINDOWS}
  OGGDLL : Array [0..0] of String = ('ogg.dll');
{$endif}
{$endif}

type
  ogg_int16_t = cInt16;
  ogg_uint16_t = cUInt16;
  ogg_int32_t = cInt32;
  ogg_uint32_t = cUInt32;
  ogg_int64_t = cInt64;
  ogg_uint64_t = cUInt64;

  Pogg_int64_t = ^ogg_int64_t;
  Pogg_int16_t = ^ogg_int16_t;
  Pogg_uint16_t = ^ogg_uint16_t;
  Pogg_int32_t = ^ogg_int32_t;
  Pogg_uint32_t = ^ogg_uint32_t;
  Pogg_uint64_t = ^ogg_uint64_t;

  ogg_iovec_t = record
    iov_base : Pointer;
    iov_len : SizeUInt;
  end;

  pogg_iovec_t= ^ogg_iovec_t;

  oggpack_buffer = record
    endbyte : clong;
    endbit  : cint;

    buffer  : pcuchar;
    ptr     : pcuchar;
    storage : clong;
  end;

  poggpack_buffer = ^oggpack_buffer;

  { ogg_page is used to encapsulate the data in one Ogg bitstream page }

  ogg_page = record
    header          : pcuchar;
    header_len      : clong;
    body            : pcuchar;
    body_len        : clong;
  end;

  pogg_page = ^ogg_page;

  {  ogg_stream_state contains the current encode/decode state of a logical
     Ogg bitstream }

  ogg_stream_state = record
    body_data : pcuchar;             { bytes from packet bodies }
    body_storage : clong;        { storage elements allocated }
    body_fill : clong;           { elements stored; fill mark }
    body_returned : clong;       { elements of fill returned }


    lacing_vals : pcint;        { The values that will go to the segment table }
    granule_vals : Pogg_int64_t;   { granulepos values for headers. Not compact
                                     this way, but it is simple coupled to the
                                     lacing fifo }
    lacing_storage  : clong;
    lacing_fill     : clong;
    lacing_packet   : clong;
    lacing_returned : clong;

    header : Array [0..281] of cuchar;  { working space for header encode }
    header_fill     : cint;

    e_o_s           : cint;        { set when we have buffered the last packet in the
                                        logical bitstream }
    b_o_s           : cint;        { set after we've written the initial page
                                        of a logical bitstream }
    serialno        : clong;
    pageno          : clong;
    packetno        : ogg_int64_t;  { sequence number for decode; the framing
                                      knows where there's a hole in the data,
                                      but we need coupling so that the codec
                                      (which is in a separate abstraction
                                      layer) also knows about the gap }
    granulepos      : ogg_int64_t;
  end;

  pogg_stream_state = ^ogg_stream_state;

  { ogg_packet is used to encapsulate the data and metadata belonging
     to a single raw Ogg/Vorbis packet }

  ogg_packet = record
    packet : pcuchar;
    bytes  : clong;
    b_o_s  : clong;
    e_o_s  : clong;

    granulepos : ogg_int64_t;

    packetno  : ogg_int64_t;     { sequence number for decode; the framing
                                   knows where there's a hole in the data,
                                   but we need coupling so that the codec
                                   (which is in a separate abstraction
                                   layer) also knows about the gap }
  end;

  pogg_packet = ^ogg_packet;

  ogg_sync_state = record
    data : pcuchar;
    storage : cint;
    fill : cint;
    returned : cint;

    unsynced : cint;
    headerbytes : cint;
    bodybytes : cint;
  end;

  pogg_sync_state = ^ogg_sync_state;


{ Ogg BITSTREAM PRIMITIVES: bitstream }

procedure oggpack_writeinit(b: poggpack_buffer);
function  oggpack_writecheck(b: poggpack_buffer): cint;
procedure oggpack_writetrunc(b: poggpack_buffer; bits: clong);
procedure oggpack_writealign(b: poggpack_buffer);
procedure oggpack_writecopy(b: poggpack_buffer; source: pointer; bits: clong);
procedure oggpack_reset(b: poggpack_buffer);
procedure oggpack_writeclear(b: poggpack_buffer);
procedure oggpack_readinit(b: poggpack_buffer; buf: pcuchar; bytes: cint);
procedure oggpack_write(b: poggpack_buffer; value: cardinal; bits: cint);
function oggpack_look(b: poggpack_buffer; bits: cint): clong;
function oggpack_look1(b: poggpack_buffer): clong;
procedure oggpack_adv(b: poggpack_buffer; bits: cint);
procedure oggpack_adv1(b: poggpack_buffer);
function oggpack_read(b: poggpack_buffer; bits: cint): clong;
function oggpack_read1(b: poggpack_buffer): clong;
function oggpack_bytes(b: poggpack_buffer): clong;
function oggpack_bits(b: poggpack_buffer): clong;
function oggpack_get_buffer(b: poggpack_buffer): pcuchar;
procedure oggpackB_writeinit(b: poggpack_buffer);
function oggpackB_writecheck(b: poggpack_buffer): cint;
procedure oggpackB_writetrunc(b: poggpack_buffer; bits: clong);
procedure oggpackB_writealign(b: poggpack_buffer);
procedure oggpackB_writecopy(b: poggpack_buffer; source: pointer; bits: clong);
procedure oggpackB_reset(b: poggpack_buffer);
procedure oggpackB_writeclear(b: poggpack_buffer);
procedure oggpackB_readinit(b: poggpack_buffer; buf: pcuchar; bytes: cint);
procedure oggpackB_write(b: poggpack_buffer; value: cardinal; bits: cint);
function oggpackB_look(b: poggpack_buffer; bits: cint): clong;
function oggpackB_look1(b: poggpack_buffer): clong;
procedure oggpackB_adv(b: poggpack_buffer; bits: cint);
procedure oggpackB_adv1(b: poggpack_buffer);
function oggpackB_read(b: poggpack_buffer; bits: cint): clong;
function oggpackB_read1(b: poggpack_buffer): clong;
function oggpackB_bytes(b: poggpack_buffer): clong;
function oggpackB_bits(b: poggpack_buffer): clong;
function oggpackB_get_buffer(b: poggpack_buffer): pcuchar;

{Ogg BITSTREAM PRIMITIVES: encoding }

function ogg_stream_packetin(os: pogg_stream_state; op: pogg_packet): cint;
function ogg_stream_iovecin(os: pogg_stream_state; iov: pogg_iovec_t; count: cint; e_o_s: clong; granulepos: ogg_int64_t): cint;
function ogg_stream_pageout(os: pogg_stream_state; og: pogg_page): cint;
function ogg_stream_pageout_fill(os: pogg_stream_state; og: pogg_page; nfill: cint): cint;
function ogg_stream_flush(os: pogg_stream_state; og: pogg_page): cint;
function ogg_stream_flush_fill(os: pogg_stream_state; og: pogg_page; nfill: cint): cint;

{ Ogg BITSTREAM PRIMITIVES: decoding }

function ogg_sync_init(oy: pogg_sync_state): cint;
function ogg_sync_clear(oy: pogg_sync_state): cint;
function ogg_sync_reset(oy: pogg_sync_state): cint;
function ogg_sync_destroy(oy: pogg_sync_state): cint;
function ogg_sync_check(oy: pogg_sync_state): cint;
function ogg_sync_buffer(oy: pogg_sync_state; size: clong): pcchar;
function ogg_sync_wrote(oy: pogg_sync_state; bytes: clong): cint;
function ogg_sync_pageseek(oy: pogg_sync_state; og: pogg_page): clong;
function ogg_sync_pageout(oy: pogg_sync_state; og: pogg_page): cint;
function ogg_stream_pagein(os: pogg_stream_state; og: pogg_page): cint;
function ogg_stream_packetout(os: pogg_stream_state; op: pogg_packet): cint;
function ogg_stream_packetpeek(os: pogg_stream_state; op: pogg_packet): cint;

{ Ogg BITSTREAM PRIMITIVES: general }

function ogg_stream_init(os: pogg_stream_state; serialno: cint): cint;
function ogg_stream_clear(os: pogg_stream_state): cint;
function ogg_stream_reset(os: pogg_stream_state): cint;
function ogg_stream_reset_serialno(os: pogg_stream_state; serialno: cint): cint;
function ogg_stream_destroy(os: pogg_stream_state): cint;
function ogg_stream_check(os: pogg_stream_state): cint;
function ogg_stream_eos(os: pogg_stream_state): cint;
procedure ogg_page_checksum_set(og: pogg_page);
function ogg_page_version(const og: pogg_page): cint;
function ogg_page_continued(const og: pogg_page): cint;
function ogg_page_bos(const og: pogg_page): cint;
function ogg_page_eos(const og: pogg_page): cint;
function ogg_page_granulepos(const og: pogg_page): ogg_int64_t;
function ogg_page_serialno(const og: pogg_page): cint;
function ogg_page_pageno(const og: pogg_page): clong;
function ogg_page_packets(const og: pogg_page): cint;
procedure ogg_packet_clear(op: pogg_packet);

function IsOGGloaded: boolean;
function InitOGGInterface(const aLibs : array of String): boolean; overload;
function DestroyOGGInterface: boolean;

implementation

var
  OGGloaded: boolean = False;
  OGGLib: Array of HModule;

resourcestring
  SFailedToLoadOGG = 'Failed to load OGG library';

type
  { Ogg BITSTREAM PRIMITIVES: bitstream }
  p_oggpack_writeinit = procedure(b: poggpack_buffer); cdecl;
  p_oggpack_writecheck = function(b: poggpack_buffer): cint; cdecl;
  p_oggpack_writetrunc = procedure(b: poggpack_buffer; bits: clong); cdecl;
  p_oggpack_writealign = procedure(b: poggpack_buffer); cdecl;
  p_oggpack_writecopy = procedure(b: poggpack_buffer; source: pointer; bits: clong); cdecl;
  p_oggpack_reset = procedure(b: poggpack_buffer); cdecl;
  p_oggpack_writeclear = procedure(b: poggpack_buffer); cdecl;
  p_oggpack_readinit = procedure(b: poggpack_buffer; buf: pcuchar; bytes: cint); cdecl;
  p_oggpack_write = procedure(b: poggpack_buffer; value: cardinal; bits: cint); cdecl;
  p_oggpack_look = function(b: poggpack_buffer; bits: cint): clong; cdecl;
  p_oggpack_look1 = function(b: poggpack_buffer): clong; cdecl;
  p_oggpack_adv = procedure(b: poggpack_buffer; bits: cint); cdecl;
  p_oggpack_adv1 = procedure(b: poggpack_buffer); cdecl;
  p_oggpack_read = function(b: poggpack_buffer; bits: cint): clong; cdecl;
  p_oggpack_read1 = function(b: poggpack_buffer): clong; cdecl;
  p_oggpack_bytes = function(b: poggpack_buffer): clong; cdecl;
  p_oggpack_bits = function(b: poggpack_buffer): clong; cdecl;
  p_oggpack_get_buffer = function(b: poggpack_buffer): pcuchar; cdecl;
  p_oggpackB_writeinit = procedure(b: poggpack_buffer); cdecl;
  p_oggpackB_writecheck = function(b: poggpack_buffer): cint; cdecl;
  p_oggpackB_writetrunc = procedure(b: poggpack_buffer; bits: clong); cdecl;
  p_oggpackB_writealign = procedure(b: poggpack_buffer); cdecl;
  p_oggpackB_writecopy = procedure(b: poggpack_buffer; source: pointer; bits: clong); cdecl;
  p_oggpackB_reset = procedure(b: poggpack_buffer); cdecl;
  p_oggpackB_writeclear = procedure(b: poggpack_buffer); cdecl;
  p_oggpackB_readinit = procedure(b: poggpack_buffer; buf: pcuchar; bytes: cint); cdecl;
  p_oggpackB_write = procedure(b: poggpack_buffer; value: cardinal; bits: cint); cdecl;
  p_oggpackB_look = function(b: poggpack_buffer; bits: cint): clong; cdecl;
  p_oggpackB_look1 = function(b: poggpack_buffer): clong; cdecl;
  p_oggpackB_adv = procedure(b: poggpack_buffer; bits: cint); cdecl;
  p_oggpackB_adv1 = procedure(b: poggpack_buffer); cdecl;
  p_oggpackB_read = function(b: poggpack_buffer; bits: cint): clong; cdecl;
  p_oggpackB_read1 = function(b: poggpack_buffer): clong; cdecl;
  p_oggpackB_bytes = function(b: poggpack_buffer): clong; cdecl;
  p_oggpackB_bits = function(b: poggpack_buffer): clong; cdecl;
  p_oggpackB_get_buffer = function(b: poggpack_buffer): pcuchar; cdecl;

  {Ogg BITSTREAM PRIMITIVES: encoding }
  p_ogg_stream_packetin = function(os: pogg_stream_state;
                                       op: pogg_packet): cint; cdecl;
  p_ogg_stream_iovecin = function(os: pogg_stream_state; iov: pogg_iovec_t;
                                       count: cint; e_o_s: clong;
                                       granulepos: ogg_int64_t): cint; cdecl;
  p_ogg_stream_pageout = function(os: pogg_stream_state;
                                       og: pogg_page): cint; cdecl;
  p_ogg_stream_pageout_fill = function(os: pogg_stream_state;
                                       og: pogg_page;
                                       nfill: cint): cint; cdecl;
  p_ogg_stream_flush = function(os: pogg_stream_state;
                                       og: pogg_page): cint; cdecl;
  p_ogg_stream_flush_fill = function(os: pogg_stream_state;
                                       og: pogg_page;
                                       nfill: cint): cint; cdecl;

  { Ogg BITSTREAM PRIMITIVES: decoding }
  p_ogg_sync_init = function(oy: pogg_sync_state): cint; cdecl;
  p_ogg_sync_clear = function(oy: pogg_sync_state): cint; cdecl;
  p_ogg_sync_reset = function(oy: pogg_sync_state): cint; cdecl;
  p_ogg_sync_destroy = function(oy: pogg_sync_state): cint; cdecl;
  p_ogg_sync_check = function(oy: pogg_sync_state): cint; cdecl;
  p_ogg_sync_buffer = function(oy: pogg_sync_state; size: clong): pcchar; cdecl;
  p_ogg_sync_wrote = function(oy: pogg_sync_state; bytes: clong): cint; cdecl;
  p_ogg_sync_pageseek = function(oy: pogg_sync_state;
                                       og: pogg_page): clong; cdecl;
  p_ogg_sync_pageout = function(oy: pogg_sync_state;
                                       og: pogg_page): cint; cdecl;
  p_ogg_stream_pagein = function(os: pogg_stream_state;
                                       og: pogg_page): cint; cdecl;
  p_ogg_stream_packetout = function(os: pogg_stream_state;
                                       op: pogg_packet): cint; cdecl;
  p_ogg_stream_packetpeek = function(os: pogg_stream_state;
                                       op: pogg_packet): cint; cdecl;

  { Ogg BITSTREAM PRIMITIVES: general }
  p_ogg_stream_init = function(os: pogg_stream_state;
                                       serialno: cint): cint; cdecl;
  p_ogg_stream_clear = function(os: pogg_stream_state): cint; cdecl;
  p_ogg_stream_reset = function(os: pogg_stream_state): cint; cdecl;
  p_ogg_stream_reset_serialno = function(os: pogg_stream_state;
                                       serialno: cint): cint; cdecl;
  p_ogg_stream_destroy = function(os: pogg_stream_state): cint; cdecl;
  p_ogg_stream_check = function(os: pogg_stream_state): cint; cdecl;
  p_ogg_stream_eos = function(os: pogg_stream_state): cint; cdecl;
  p_ogg_page_checksum_set = procedure(og: pogg_page); cdecl;
  p_ogg_page_version = function(const og: pogg_page): cint; cdecl;
  p_ogg_page_continued = function(const og: pogg_page): cint; cdecl;
  p_ogg_page_bos = function(const og: pogg_page): cint; cdecl;
  p_ogg_page_eos = function(const og: pogg_page): cint; cdecl;
  p_ogg_page_granulepos = function(const og: pogg_page): ogg_int64_t; cdecl;
  p_ogg_page_serialno = function(const og: pogg_page): cint; cdecl;
  p_ogg_page_pageno = function(const og: pogg_page): clong; cdecl;
  p_ogg_page_packets = function(const og: pogg_page): cint; cdecl;
  p_ogg_packet_clear = procedure(op: pogg_packet); cdecl;

var
  _oggpack_writeinit: p_oggpack_writeinit = nil;
  _oggpack_writecheck: p_oggpack_writecheck = nil;
  _oggpack_writetrunc: p_oggpack_writetrunc = nil;
  _oggpack_writealign: p_oggpack_writealign = nil;
  _oggpack_writecopy: p_oggpack_writecopy = nil;
  _oggpack_reset: p_oggpack_reset = nil;
  _oggpack_writeclear: p_oggpack_writeclear = nil;
  _oggpack_readinit: p_oggpack_readinit = nil;
  _oggpack_write: p_oggpack_write = nil;
  _oggpack_look: p_oggpack_look = nil;
  _oggpack_look1: p_oggpack_look1 = nil;
  _oggpack_adv: p_oggpack_adv = nil;
  _oggpack_adv1: p_oggpack_adv1 = nil;
  _oggpack_read: p_oggpack_read = nil;
  _oggpack_read1: p_oggpack_read1 = nil;
  _oggpack_bytes: p_oggpack_bytes = nil;
  _oggpack_bits: p_oggpack_bits = nil;
  _oggpack_get_buffer: p_oggpack_get_buffer = nil;
  _oggpackB_writeinit: p_oggpackB_writeinit = nil;
  _oggpackB_writecheck: p_oggpackB_writecheck = nil;
  _oggpackB_writetrunc: p_oggpackB_writetrunc = nil;
  _oggpackB_writealign: p_oggpackB_writealign = nil;
  _oggpackB_writecopy: p_oggpackB_writecopy = nil;
  _oggpackB_reset: p_oggpackB_reset = nil;
  _oggpackB_writeclear: p_oggpackB_writeclear = nil;
  _oggpackB_readinit: p_oggpackB_readinit = nil;
  _oggpackB_write: p_oggpackB_write = nil;
  _oggpackB_look: p_oggpackB_look = nil;
  _oggpackB_look1: p_oggpackB_look1 = nil;
  _oggpackB_adv: p_oggpackB_adv = nil;
  _oggpackB_adv1: p_oggpackB_adv1 = nil;
  _oggpackB_read: p_oggpackB_read = nil;
  _oggpackB_read1: p_oggpackB_read1 = nil;
  _oggpackB_bytes: p_oggpackB_bytes = nil;
  _oggpackB_bits: p_oggpackB_bits = nil;
  _oggpackB_get_buffer: p_oggpackB_get_buffer = nil;
  _ogg_stream_packetin: p_ogg_stream_packetin = nil;
  _ogg_stream_iovecin: p_ogg_stream_iovecin = nil;
  _ogg_stream_pageout: p_ogg_stream_pageout = nil;
  _ogg_stream_pageout_fill: p_ogg_stream_pageout_fill = nil;
  _ogg_stream_flush: p_ogg_stream_flush = nil;
  _ogg_stream_flush_fill: p_ogg_stream_flush_fill = nil;
  _ogg_sync_init: p_ogg_sync_init = nil;
  _ogg_sync_clear: p_ogg_sync_clear = nil;
  _ogg_sync_reset: p_ogg_sync_reset = nil;
  _ogg_sync_destroy: p_ogg_sync_destroy = nil;
  _ogg_sync_check: p_ogg_sync_check = nil;
  _ogg_sync_buffer: p_ogg_sync_buffer = nil;
  _ogg_sync_wrote: p_ogg_sync_wrote = nil;
  _ogg_sync_pageseek: p_ogg_sync_pageseek = nil;
  _ogg_sync_pageout: p_ogg_sync_pageout = nil;
  _ogg_stream_pagein: p_ogg_stream_pagein = nil;
  _ogg_stream_packetout: p_ogg_stream_packetout = nil;
  _ogg_stream_packetpeek: p_ogg_stream_packetpeek = nil;
  _ogg_stream_init: p_ogg_stream_init = nil;
  _ogg_stream_clear: p_ogg_stream_clear = nil;
  _ogg_stream_reset: p_ogg_stream_reset = nil;
  _ogg_stream_reset_serialno: p_ogg_stream_reset_serialno = nil;
  _ogg_stream_destroy: p_ogg_stream_destroy = nil;
  _ogg_stream_check: p_ogg_stream_check = nil;
  _ogg_stream_eos: p_ogg_stream_eos = nil;
  _ogg_page_checksum_set: p_ogg_page_checksum_set = nil;
  _ogg_page_version: p_ogg_page_version = nil;
  _ogg_page_continued: p_ogg_page_continued = nil;
  _ogg_page_bos: p_ogg_page_bos = nil;
  _ogg_page_eos: p_ogg_page_eos = nil;
  _ogg_page_granulepos: p_ogg_page_granulepos = nil;
  _ogg_page_serialno: p_ogg_page_serialno = nil;
  _ogg_page_pageno: p_ogg_page_pageno = nil;
  _ogg_page_packets: p_ogg_page_packets = nil;
  _ogg_packet_clear: p_ogg_packet_clear = nil;

{$IFNDEF WINDOWS}
{ Try to load all library versions until you find or run out }
procedure LoadLibUnix(const aLibs : array of String);
var i : cint;
begin
  for i := 0 to High(aLibs) do
  begin
      OGGLib[i] := LoadLibrary(aLibs[i]);
  end;
end;

{$ELSE WINDOWS}
procedure LoadLibsWin(const aLibs : array of String);
var i : cint;
begin
  for i := 0 to High(aLibs) do
  begin
      OGGLib[i] := LoadLibrary(aLibs[i]);
  end;
end;

{$ENDIF WINDOWS}

function IsOGGloaded: boolean;
begin
  Result := OGGloaded;
end;

procedure UnloadLibraries;
var i : cint;
begin
  OGGloaded := False;
  for i := 0 to High(OGGLib) do
  if OGGLib[i] <> NilHandle then
  begin
    FreeLibrary(OGGLib[i]);
    OGGLib[i] := NilHandle;
  end;
end;

function LoadLibraries(const aLibs : array of String) : boolean;
var i : integer;
begin
  SetLength(OGGLib, Length(aLibs));
  Result := False;
  {$IFDEF WINDOWS}
  LoadLibsWin(aLibs);
  {$ELSE}
  LoadLibUnix(aLibs);
  {$ENDIF}
  for i := 0 to High(aLibs) do
  if OGGLib[i] <> NilHandle then
     Result := true;
end;

function GetProcAddr(const module: Array of HModule; const ProcName: string): Pointer;
var i : cint;
begin
  for i := Low(module) to High(module) do
  if module[i] <> NilHandle then
  begin
    Result := GetProcAddress(module[i], PChar(ProcName));
    if Assigned(Result) then Exit;
  end;
end;

procedure LoadOGGEntryPoints;
begin
  _oggpack_writeinit := p_oggpack_writeinit(GetProcAddr(OGGLib, 'oggpack_writeinit'));
  _oggpack_writecheck := p_oggpack_writecheck(GetProcAddr(OGGLib, 'oggpack_writecheck'));
  _oggpack_writetrunc := p_oggpack_writetrunc(GetProcAddr(OGGLib, 'oggpack_writetrunc'));
  _oggpack_writealign := p_oggpack_writealign(GetProcAddr(OGGLib, 'oggpack_writealign'));
  _oggpack_writecopy := p_oggpack_writecopy(GetProcAddr(OGGLib, 'oggpack_writecopy'));
  _oggpack_reset := p_oggpack_reset(GetProcAddr(OGGLib, 'oggpack_reset'));
  _oggpack_writeclear := p_oggpack_writeclear(GetProcAddr(OGGLib, 'oggpack_writeclear'));
  _oggpack_readinit := p_oggpack_readinit(GetProcAddr(OGGLib, 'oggpack_readinit'));
  _oggpack_write := p_oggpack_write(GetProcAddr(OGGLib, 'oggpack_write'));
  _oggpack_look := p_oggpack_look(GetProcAddr(OGGLib, 'oggpack_look'));
  _oggpack_look1 := p_oggpack_look1(GetProcAddr(OGGLib, 'oggpack_look1'));
  _oggpack_adv := p_oggpack_adv(GetProcAddr(OGGLib, 'oggpack_adv'));
  _oggpack_adv1 := p_oggpack_adv1(GetProcAddr(OGGLib, 'oggpack_adv1'));
  _oggpack_read := p_oggpack_read(GetProcAddr(OGGLib, 'oggpack_read'));
  _oggpack_read1 := p_oggpack_read1(GetProcAddr(OGGLib, 'oggpack_read1'));
  _oggpack_bytes := p_oggpack_bytes(GetProcAddr(OGGLib, 'oggpack_bytes'));
  _oggpack_bits := p_oggpack_bits(GetProcAddr(OGGLib, 'oggpack_bits'));
  _oggpack_get_buffer := p_oggpack_get_buffer(GetProcAddr(OGGLib, 'oggpack_get_buffer'));
  _oggpackB_writeinit := p_oggpackB_writeinit(GetProcAddr(OGGLib, 'oggpackB_writeinit'));
  _oggpackB_writecheck := p_oggpackB_writecheck(GetProcAddr(OGGLib, 'oggpackB_writecheck'));
  _oggpackB_writetrunc := p_oggpackB_writetrunc(GetProcAddr(OGGLib, 'oggpackB_writetrunc'));
  _oggpackB_writealign := p_oggpackB_writealign(GetProcAddr(OGGLib, 'oggpackB_writealign'));
  _oggpackB_writecopy := p_oggpackB_writecopy(GetProcAddr(OGGLib, 'oggpackB_writecopy'));
  _oggpackB_reset := p_oggpackB_reset(GetProcAddr(OGGLib, 'oggpackB_reset'));
  _oggpackB_writeclear := p_oggpackB_writeclear(GetProcAddr(OGGLib, 'oggpackB_writeclear'));
  _oggpackB_readinit := p_oggpackB_readinit(GetProcAddr(OGGLib, 'oggpackB_readinit'));
  _oggpackB_write := p_oggpackB_write(GetProcAddr(OGGLib, 'oggpackB_write'));
  _oggpackB_look := p_oggpackB_look(GetProcAddr(OGGLib, 'oggpackB_look'));
  _oggpackB_look1 := p_oggpackB_look1(GetProcAddr(OGGLib, 'oggpackB_look1'));
  _oggpackB_adv := p_oggpackB_adv(GetProcAddr(OGGLib, 'oggpackB_adv'));
  _oggpackB_adv1 := p_oggpackB_adv1(GetProcAddr(OGGLib, 'oggpackB_adv1'));
  _oggpackB_read := p_oggpackB_read(GetProcAddr(OGGLib, 'oggpackB_read'));
  _oggpackB_read1 := p_oggpackB_read1(GetProcAddr(OGGLib, 'oggpackB_read1'));
  _oggpackB_bytes := p_oggpackB_bytes(GetProcAddr(OGGLib, 'oggpackB_bytes'));
  _oggpackB_bits := p_oggpackB_bits(GetProcAddr(OGGLib, 'oggpackB_bits'));
  _oggpackB_get_buffer := p_oggpackB_get_buffer(GetProcAddr(OGGLib, 'oggpackB_get_buffer'));
  _ogg_stream_packetin := p_ogg_stream_packetin(GetProcAddr(OGGLib, 'ogg_stream_packetin'));
  _ogg_stream_iovecin := p_ogg_stream_iovecin(GetProcAddr(OGGLib, 'ogg_stream_iovecin'));
  _ogg_stream_pageout := p_ogg_stream_pageout(GetProcAddr(OGGLib, 'ogg_stream_pageout'));
  _ogg_stream_pageout_fill := p_ogg_stream_pageout_fill(GetProcAddr(OGGLib, 'ogg_stream_pageout_fill'));
  _ogg_stream_flush := p_ogg_stream_flush(GetProcAddr(OGGLib, 'ogg_stream_flush'));
  _ogg_stream_flush_fill := p_ogg_stream_flush_fill(GetProcAddr(OGGLib, 'ogg_stream_flush_fill'));
  _ogg_sync_init := p_ogg_sync_init(GetProcAddr(OGGLib, 'ogg_sync_init'));
  _ogg_sync_clear := p_ogg_sync_clear(GetProcAddr(OGGLib, 'ogg_sync_clear'));
  _ogg_sync_reset := p_ogg_sync_reset(GetProcAddr(OGGLib, 'ogg_sync_reset'));
  _ogg_sync_destroy := p_ogg_sync_destroy(GetProcAddr(OGGLib, 'ogg_sync_destroy'));
  _ogg_sync_check := p_ogg_sync_check(GetProcAddr(OGGLib, 'ogg_sync_check'));
  _ogg_sync_buffer := p_ogg_sync_buffer(GetProcAddr(OGGLib, 'ogg_sync_buffer'));
  _ogg_sync_wrote := p_ogg_sync_wrote(GetProcAddr(OGGLib, 'ogg_sync_wrote'));
  _ogg_sync_pageseek := p_ogg_sync_pageseek(GetProcAddr(OGGLib, 'ogg_sync_pageseek'));
  _ogg_sync_pageout := p_ogg_sync_pageout(GetProcAddr(OGGLib, 'ogg_sync_pageout'));
  _ogg_stream_pagein := p_ogg_stream_pagein(GetProcAddr(OGGLib, 'ogg_stream_pagein'));
  _ogg_stream_packetout := p_ogg_stream_packetout(GetProcAddr(OGGLib, 'ogg_stream_packetout'));
  _ogg_stream_packetpeek := p_ogg_stream_packetpeek(GetProcAddr(OGGLib, 'ogg_stream_packetpeek'));
  _ogg_stream_init := p_ogg_stream_init(GetProcAddr(OGGLib, 'ogg_stream_init'));
  _ogg_stream_clear := p_ogg_stream_clear(GetProcAddr(OGGLib, 'ogg_stream_clear'));
  _ogg_stream_reset := p_ogg_stream_reset(GetProcAddr(OGGLib, 'ogg_stream_reset'));
  _ogg_stream_reset_serialno := p_ogg_stream_reset_serialno(GetProcAddr(OGGLib, 'ogg_stream_reset_serialno'));
  _ogg_stream_destroy := p_ogg_stream_destroy(GetProcAddr(OGGLib, 'ogg_stream_destroy'));
  _ogg_stream_check := p_ogg_stream_check(GetProcAddr(OGGLib, 'ogg_stream_check'));
  _ogg_stream_eos := p_ogg_stream_eos(GetProcAddr(OGGLib, 'ogg_stream_eos'));
  _ogg_page_checksum_set := p_ogg_page_checksum_set(GetProcAddr(OGGLib, 'ogg_page_checksum_set'));
  _ogg_page_version := p_ogg_page_version(GetProcAddr(OGGLib, 'ogg_page_version'));
  _ogg_page_continued := p_ogg_page_continued(GetProcAddr(OGGLib, 'ogg_page_continued'));
  _ogg_page_bos := p_ogg_page_bos(GetProcAddr(OGGLib, 'ogg_page_bos'));
  _ogg_page_eos := p_ogg_page_eos(GetProcAddr(OGGLib, 'ogg_page_eos'));
  _ogg_page_granulepos := p_ogg_page_granulepos(GetProcAddr(OGGLib, 'ogg_page_granulepos'));
  _ogg_page_serialno := p_ogg_page_serialno(GetProcAddr(OGGLib, 'ogg_page_serialno'));
  _ogg_page_pageno := p_ogg_page_pageno(GetProcAddr(OGGLib, 'ogg_page_pageno'));
  _ogg_page_packets := p_ogg_page_packets(GetProcAddr(OGGLib, 'ogg_page_packets'));
  _ogg_packet_clear := p_ogg_packet_clear(GetProcAddr(OGGLib, 'ogg_packet_clear'));
end;

procedure ClearOGGEntryPoints;
begin
  _oggpack_writeinit := nil;
  _oggpack_writecheck := nil;
  _oggpack_writetrunc := nil;
  _oggpack_writealign := nil;
  _oggpack_writecopy := nil;
  _oggpack_reset := nil;
  _oggpack_writeclear := nil;
  _oggpack_readinit := nil;
  _oggpack_write := nil;
  _oggpack_look := nil;
  _oggpack_look1 := nil;
  _oggpack_adv := nil;
  _oggpack_adv1 := nil;
  _oggpack_read := nil;
  _oggpack_read1 := nil;
  _oggpack_bytes := nil;
  _oggpack_bits := nil;
  _oggpack_get_buffer := nil;
  _oggpackB_writeinit := nil;
  _oggpackB_writecheck := nil;
  _oggpackB_writetrunc := nil;
  _oggpackB_writealign := nil;
  _oggpackB_writecopy := nil;
  _oggpackB_reset := nil;
  _oggpackB_writeclear := nil;
  _oggpackB_readinit := nil;
  _oggpackB_write := nil;
  _oggpackB_look := nil;
  _oggpackB_look1 := nil;
  _oggpackB_adv := nil;
  _oggpackB_adv1 := nil;
  _oggpackB_read := nil;
  _oggpackB_read1 := nil;
  _oggpackB_bytes := nil;
  _oggpackB_bits := nil;
  _oggpackB_get_buffer := nil;
  _ogg_stream_packetin := nil;
  _ogg_stream_iovecin := nil;
  _ogg_stream_pageout := nil;
  _ogg_stream_pageout_fill := nil;
  _ogg_stream_flush := nil;
  _ogg_stream_flush_fill := nil;
  _ogg_sync_init := nil;
  _ogg_sync_clear := nil;
  _ogg_sync_reset := nil;
  _ogg_sync_destroy := nil;
  _ogg_sync_check := nil;
  _ogg_sync_buffer := nil;
  _ogg_sync_wrote := nil;
  _ogg_sync_pageseek := nil;
  _ogg_sync_pageout := nil;
  _ogg_stream_pagein := nil;
  _ogg_stream_packetout := nil;
  _ogg_stream_packetpeek := nil;
  _ogg_stream_init := nil;
  _ogg_stream_clear := nil;
  _ogg_stream_reset := nil;
  _ogg_stream_reset_serialno := nil;
  _ogg_stream_destroy := nil;
  _ogg_stream_check := nil;
  _ogg_stream_eos := nil;
  _ogg_page_checksum_set := nil;
  _ogg_page_version := nil;
  _ogg_page_continued := nil;
  _ogg_page_bos := nil;
  _ogg_page_eos := nil;
  _ogg_page_granulepos := nil;
  _ogg_page_serialno := nil;
  _ogg_page_pageno := nil;
  _ogg_page_packets := nil;
  _ogg_packet_clear := nil;
end;

function InitOGGInterface(const aLibs : array of String): boolean;
begin
  Result := IsOGGloaded;
  if Result then
    exit;
  Result := LoadLibraries(aLibs);
  if not Result then
  begin
    UnloadLibraries;
    Exit;
  end;
  LoadOGGEntryPoints;
  OGGloaded := True;
  Result := True;
end;

function DestroyOGGInterface: boolean;
begin
  Result := not IsOGGloaded;
  if Result then
    exit;
  ClearOGGEntryPoints;
  UnloadLibraries;
  Result := True;
end;


procedure oggpack_writeinit(b: poggpack_buffer);
begin
  if Assigned(_oggpack_writeinit) then
    _oggpack_writeinit(b);
end;

function oggpack_writecheck(b: poggpack_buffer): cint;
begin
  if Assigned(_oggpack_writecheck) then
    Result := _oggpack_writecheck(b)
  else
    Result := 0;
end;

procedure oggpack_writetrunc(b: poggpack_buffer; bits: clong);
begin
  if Assigned(_oggpack_writetrunc) then
    _oggpack_writetrunc(b, bits);
end;

procedure oggpack_writealign(b: poggpack_buffer);
begin
  if Assigned(_oggpack_writealign) then
    _oggpack_writealign(b);
end;

procedure oggpack_writecopy(b: poggpack_buffer; source: pointer; bits: clong);
begin
  if Assigned(_oggpack_writecopy) then
    _oggpack_writecopy(b, source, bits);
end;

procedure oggpack_reset(b: poggpack_buffer);
begin
  if Assigned(_oggpack_reset) then
    _oggpack_reset(b);
end;

procedure oggpack_writeclear(b: poggpack_buffer);
begin
  if Assigned(_oggpack_writeclear) then
    _oggpack_writeclear(b);
end;

procedure oggpack_readinit(b: poggpack_buffer; buf: pcuchar; bytes: cint);
begin
  if Assigned(_oggpack_readinit) then
    _oggpack_readinit(b, buf, bytes);
end;

procedure oggpack_write(b: poggpack_buffer; value: cardinal; bits: cint);
begin
  if Assigned(_oggpack_write) then
    _oggpack_write(b, value, bits);
end;

function oggpack_look(b: poggpack_buffer; bits: cint): clong;
begin
  if Assigned(_oggpack_look) then
    Result := _oggpack_look(b, bits)
  else
    Result := 0;
end;

function oggpack_look1(b: poggpack_buffer): clong;
begin
  if Assigned(_oggpack_look1) then
    Result := _oggpack_look1(b)
  else
    Result := 0;
end;

procedure oggpack_adv(b: poggpack_buffer; bits: cint);
begin
  if Assigned(_oggpack_adv) then
    _oggpack_adv(b, bits);
end;

procedure oggpack_adv1(b: poggpack_buffer);
begin
  if Assigned(_oggpack_adv1) then
    _oggpack_adv1(b);
end;

function oggpack_read(b: poggpack_buffer; bits: cint): clong;
begin
  if Assigned(_oggpack_read) then
    Result := _oggpack_read(b, bits)
  else
    Result := 0;
end;

function oggpack_read1(b: poggpack_buffer): clong;
begin
  if Assigned(_oggpack_read1) then
    Result := _oggpack_read1(b)
  else
    Result := 0;
end;

function oggpack_bytes(b: poggpack_buffer): clong;
begin
  if Assigned(_oggpack_bytes) then
    Result := _oggpack_bytes(b)
  else
    Result := 0;
end;

function oggpack_bits(b: poggpack_buffer): clong;
begin
  if Assigned(_oggpack_bits) then
    Result := _oggpack_bits(b)
  else
    Result := 0;
end;

function oggpack_get_buffer(b: poggpack_buffer): pcuchar;
begin
  if Assigned(_oggpack_get_buffer) then
    Result := _oggpack_get_buffer(b)
  else
    Result := nil;
end;

procedure oggpackB_writeinit(b: poggpack_buffer);
begin
  if Assigned(_oggpackB_writeinit) then
    _oggpackB_writeinit(b);
end;

function oggpackB_writecheck(b: poggpack_buffer): cint;
begin
  if Assigned(_oggpackB_writecheck) then
    Result := _oggpackB_writecheck(b)
  else
    Result := 0;
end;

procedure oggpackB_writetrunc(b: poggpack_buffer; bits: clong);
begin
  if Assigned(_oggpackB_writetrunc) then
    _oggpackB_writetrunc(b, bits);
end;

procedure oggpackB_writealign(b: poggpack_buffer);
begin
  if Assigned(_oggpackB_writealign) then
    _oggpackB_writealign(b);
end;

procedure oggpackB_writecopy(b: poggpack_buffer; source: pointer; bits: clong);
begin
  if Assigned(_oggpackB_writecopy) then
    _oggpackB_writecopy(b, source, bits);
end;

procedure oggpackB_reset(b: poggpack_buffer);
begin
  if Assigned(_oggpackB_reset) then
    _oggpackB_reset(b);
end;

procedure oggpackB_writeclear(b: poggpack_buffer);
begin
  if Assigned(_oggpackB_writeclear) then
    _oggpackB_writeclear(b);
end;

procedure oggpackB_readinit(b: poggpack_buffer; buf: pcuchar; bytes: cint);
begin
  if Assigned(_oggpackB_readinit) then
    _oggpackB_readinit(b, buf, bytes);
end;

procedure oggpackB_write(b: poggpack_buffer; value: cardinal; bits: cint);
begin
  if Assigned(_oggpackB_write) then
    _oggpackB_write(b, value, bits);
end;

function oggpackB_look(b: poggpack_buffer; bits: cint): clong;
begin
  if Assigned(_oggpackB_look) then
    Result := _oggpackB_look(b, bits)
  else
    Result := 0;
end;

function oggpackB_look1(b: poggpack_buffer): clong;
begin
  if Assigned(_oggpackB_look1) then
    Result := _oggpackB_look1(b)
  else
    Result := 0;
end;

procedure oggpackB_adv(b: poggpack_buffer; bits: cint);
begin
  if Assigned(_oggpackB_adv) then
    _oggpackB_adv(b, bits);
end;

procedure oggpackB_adv1(b: poggpack_buffer);
begin
  if Assigned(_oggpackB_adv1) then
    _oggpackB_adv1(b);
end;

function oggpackB_read(b: poggpack_buffer; bits: cint): clong;
begin
  if Assigned(_oggpackB_read) then
    Result := _oggpackB_read(b, bits)
  else
    Result := 0;
end;

function oggpackB_read1(b: poggpack_buffer): clong;
begin
  if Assigned(_oggpackB_read1) then
    Result := _oggpackB_read1(b)
  else
    Result := 0;
end;

function oggpackB_bytes(b: poggpack_buffer): clong;
begin
  if Assigned(_oggpackB_bytes) then
    Result := _oggpackB_bytes(b)
  else
    Result := 0;
end;

function oggpackB_bits(b: poggpack_buffer): clong;
begin
  if Assigned(_oggpackB_bits) then
    Result := _oggpackB_bits(b)
  else
    Result := 0;
end;

function oggpackB_get_buffer(b: poggpack_buffer): pcuchar;
begin
  if Assigned(_oggpackB_get_buffer) then
    Result := _oggpackB_get_buffer(b)
  else
    Result := nil;
end;

function ogg_stream_packetin(os: pogg_stream_state; op: pogg_packet): cint;
begin
  if Assigned(_ogg_stream_packetin) then
    Result := _ogg_stream_packetin(os, op)
  else
    Result := 0;
end;

function ogg_stream_iovecin(os: pogg_stream_state; iov: pogg_iovec_t; count: cint; e_o_s: clong; granulepos: ogg_int64_t): cint;
begin
  if Assigned(_ogg_stream_iovecin) then
    Result := _ogg_stream_iovecin(os, iov, count, e_o_s, granulepos)
  else
    Result := 0;
end;

function ogg_stream_pageout(os: pogg_stream_state; og: pogg_page): cint;
begin
  if Assigned(_ogg_stream_pageout) then
    Result := _ogg_stream_pageout(os, og)
  else
    Result := 0;
end;

function ogg_stream_pageout_fill(os: pogg_stream_state; og: pogg_page; nfill: cint): cint;
begin
  if Assigned(_ogg_stream_pageout_fill) then
    Result := _ogg_stream_pageout_fill(os, og, nfill)
  else
    Result := 0;
end;

function ogg_stream_flush(os: pogg_stream_state; og: pogg_page): cint;
begin
  if Assigned(_ogg_stream_flush) then
    Result := _ogg_stream_flush(os, og)
  else
    Result := 0;
end;

function ogg_stream_flush_fill(os: pogg_stream_state; og: pogg_page; nfill: cint): cint;
begin
  if Assigned(_ogg_stream_flush_fill) then
    Result := _ogg_stream_flush_fill(os, og, nfill)
  else
    Result := 0;
end;

function ogg_sync_init(oy: pogg_sync_state): cint;
begin
  if Assigned(_ogg_sync_init) then
    Result := _ogg_sync_init(oy)
  else
    Result := 0;
end;

function ogg_sync_clear(oy: pogg_sync_state): cint;
begin
  if Assigned(_ogg_sync_clear) then
    Result := _ogg_sync_clear(oy)
  else
    Result := 0;
end;

function ogg_sync_reset(oy: pogg_sync_state): cint;
begin
  if Assigned(_ogg_sync_reset) then
    Result := _ogg_sync_reset(oy)
  else
    Result := 0;
end;

function ogg_sync_destroy(oy: pogg_sync_state): cint;
begin
  if Assigned(_ogg_sync_destroy) then
    Result := _ogg_sync_destroy(oy)
  else
    Result := 0;
end;

function ogg_sync_check(oy: pogg_sync_state): cint;
begin
  if Assigned(_ogg_sync_check) then
    Result := _ogg_sync_check(oy)
  else
    Result := 0;
end;

function ogg_sync_buffer(oy: pogg_sync_state; size: clong): pcchar;
begin
  if Assigned(_ogg_sync_buffer) then
    Result := _ogg_sync_buffer(oy, size)
  else
    Result := nil;
end;

function ogg_sync_wrote(oy: pogg_sync_state; bytes: clong): cint;
begin
  if Assigned(_ogg_sync_wrote) then
    Result := _ogg_sync_wrote(oy, bytes)
  else
    Result := 0;
end;

function ogg_sync_pageseek(oy: pogg_sync_state; og: pogg_page): clong;
begin
  if Assigned(_ogg_sync_pageseek) then
    Result := _ogg_sync_pageseek(oy, og)
  else
    Result := 0;
end;

function ogg_sync_pageout(oy: pogg_sync_state; og: pogg_page): cint;
begin
  if Assigned(_ogg_sync_pageout) then
    Result := _ogg_sync_pageout(oy, og)
  else
    Result := 0;
end;

function ogg_stream_pagein(os: pogg_stream_state; og: pogg_page): cint;
begin
  if Assigned(_ogg_stream_pagein) then
    Result := _ogg_stream_pagein(os, og)
  else
    Result := 0;
end;

function ogg_stream_packetout(os: pogg_stream_state; op: pogg_packet): cint;
begin
  if Assigned(_ogg_stream_packetout) then
    Result := _ogg_stream_packetout(os, op)
  else
    Result := 0;
end;

function ogg_stream_packetpeek(os: pogg_stream_state; op: pogg_packet): cint;
begin
  if Assigned(_ogg_stream_packetpeek) then
    Result := _ogg_stream_packetpeek(os, op)
  else
    Result := 0;
end;

function ogg_stream_init(os: pogg_stream_state; serialno: cint): cint;
begin
  if Assigned(_ogg_stream_init) then
    Result := _ogg_stream_init(os, serialno)
  else
    Result := 0;
end;

function ogg_stream_clear(os: pogg_stream_state): cint;
begin
  if Assigned(_ogg_stream_clear) then
    Result := _ogg_stream_clear(os)
  else
    Result := 0;
end;

function ogg_stream_reset(os: pogg_stream_state): cint;
begin
  if Assigned(_ogg_stream_reset) then
    Result := _ogg_stream_reset(os)
  else
    Result := 0;
end;

function ogg_stream_reset_serialno(os: pogg_stream_state; serialno: cint): cint;
begin
  if Assigned(_ogg_stream_reset_serialno) then
    Result := _ogg_stream_reset_serialno(os, serialno)
  else
    Result := 0;
end;

function ogg_stream_destroy(os: pogg_stream_state): cint;
begin
  if Assigned(_ogg_stream_destroy) then
    Result := _ogg_stream_destroy(os)
  else
    Result := 0;
end;

function ogg_stream_check(os: pogg_stream_state): cint;
begin
  if Assigned(_ogg_stream_check) then
    Result := _ogg_stream_check(os)
  else
    Result := 0;
end;

function ogg_stream_eos(os: pogg_stream_state): cint;
begin
  if Assigned(_ogg_stream_eos) then
    Result := _ogg_stream_eos(os)
  else
    Result := 0;
end;

procedure ogg_page_checksum_set(og: pogg_page);
begin
  if Assigned(_ogg_page_checksum_set) then
    _ogg_page_checksum_set(og);
end;

function ogg_page_version(const og: pogg_page): cint;
begin
  if Assigned(_ogg_page_version) then
    Result := _ogg_page_version(og)
  else
    Result := 0;
end;

function ogg_page_continued(const og: pogg_page): cint;
begin
  if Assigned(_ogg_page_continued) then
    Result := _ogg_page_continued(og)
  else
    Result := 0;
end;

function ogg_page_bos(const og: pogg_page): cint;
begin
  if Assigned(_ogg_page_bos) then
    Result := _ogg_page_bos(og)
  else
    Result := 0;
end;

function ogg_page_eos(const og: pogg_page): cint;
begin
  if Assigned(_ogg_page_eos) then
    Result := _ogg_page_eos(og)
  else
    Result := 0;
end;

function ogg_page_granulepos(const og: pogg_page): ogg_int64_t;
begin
  if Assigned(_ogg_page_granulepos) then
    Result := _ogg_page_granulepos(og)
  else
    Result := 0;
end;

function ogg_page_serialno(const og: pogg_page): cint;
begin
  if Assigned(_ogg_page_serialno) then
    Result := _ogg_page_serialno(og)
  else
    Result := 0;
end;

function ogg_page_pageno(const og: pogg_page): clong;
begin
  if Assigned(_ogg_page_pageno) then
    Result := _ogg_page_pageno(og)
  else
    Result := 0;
end;

function ogg_page_packets(const og: pogg_page): cint;
begin
  if Assigned(_ogg_page_packets) then
    Result := _ogg_page_packets(og)
  else
    Result := 0;
end;

procedure ogg_packet_clear(op: pogg_packet);
begin
  if Assigned(_ogg_packet_clear) then
    _ogg_packet_clear(op);
end;

end.
