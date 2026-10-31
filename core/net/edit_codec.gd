class_name EditCodec
extends RefCounted
## World edits on the wire (M4 Wave 1 A, spec §17.0): the host packs, for one guest and one frame,
## records of two kinds into one packet: a chunk's edit list (EditLog: the cells that differ from the
## generated terrain) and single changes as they happen. A packet over COMPRESS_OVER bytes is
## deflated (a stamp's 1,600 cells squeeze to a fraction). open() reads a packet defensively: a
## guest drops anything malformed instead of crashing or allocating what a packet claims.
##   packet: [u8 flags] (+ [u32 raw size] when deflated) then the records
##   LIST:   [u8 1][i32 cx][i32 cy][i32 cz][u16 n] n × [u16 cell][u16 id]
##   CELLS:  [u8 2][u16 n] n × [i32 x][i16 y][i32 z][u16 id]

const LIST := &"list"
const CELLS := &"cells"
const FLAG_DEFLATE := 1
const COMPRESS_OVER := 256
const MAX_RAW_BYTES := 1 << 20
const MAX_ID := 1023
const MIN_Y := -64
const MAX_Y := 192
const _KIND_LIST := 1
const _KIND_CELLS := 2
const _LIST_ENTRY := 4
const CELL_BYTES := 12


## One chunk's list, edits = [cell, id, cell, id, ...] (EditLog.edits).
static func pack_list(chunk: Vector3i, edits: PackedInt32Array) -> PackedByteArray:
	var n := edits.size() / 2
	var out := PackedByteArray()
	out.resize(15 + n * _LIST_ENTRY)
	out[0] = _KIND_LIST
	out.encode_s32(1, chunk.x)
	out.encode_s32(5, chunk.y)
	out.encode_s32(9, chunk.z)
	out.encode_u16(13, n)
	for i in n:
		out.encode_u16(15 + i * _LIST_ENTRY, edits[i * 2])
		out.encode_u16(17 + i * _LIST_ENTRY, edits[i * 2 + 1])
	return out


## Single changes: cells = [[Vector3i, id], ...] (at most 65,535).
static func pack_cells(cells: Array) -> PackedByteArray:
	var n := mini(cells.size(), 0xffff)
	var out := PackedByteArray()
	out.resize(3 + n * CELL_BYTES)
	out[0] = _KIND_CELLS
	out.encode_u16(1, n)
	for i in n:
		var p: Vector3i = cells[i][0]
		var o := 3 + i * CELL_BYTES
		out.encode_s32(o, p.x)
		out.encode_s16(o + 4, p.y)
		out.encode_s32(o + 6, p.z)
		out.encode_u16(o + 10, int(cells[i][1]))
	return out


## Bytes of one CELLS record with n cells, and of one LIST record with n edits (for budgets).
static func cells_bytes(n: int) -> int:
	return 3 + n * CELL_BYTES


static func list_bytes(n: int) -> int:
	return 15 + n * _LIST_ENTRY


## Records -> one packet (deflated when that helps).
static func seal(records: PackedByteArray) -> PackedByteArray:
	var out := PackedByteArray([0])
	if records.size() > COMPRESS_OVER:
		var packed := records.compress(FileAccess.COMPRESSION_DEFLATE)
		if packed.size() + 4 < records.size():
			out[0] = FLAG_DEFLATE
			out.resize(5)
			out.encode_u32(1, records.size())
			out.append_array(packed)
			return out
	out.append_array(records)
	return out


## A packet -> its records: {kind: LIST, chunk, edits} / {kind: CELLS, cells}; [] when malformed.
## Cells outside a chunk or the world's height and ids over MAX_ID are left out.
static func open(packet: PackedByteArray) -> Array:
	if packet.is_empty():
		return []
	var body := packet.slice(1)
	if packet[0] & FLAG_DEFLATE:
		if packet.size() < 5:
			return []
		var raw_size := packet.decode_u32(1)
		if raw_size == 0 or raw_size > MAX_RAW_BYTES:
			return []
		body = packet.slice(5).decompress(raw_size, FileAccess.COMPRESSION_DEFLATE)
		if body.size() != raw_size:
			return []
	var out := []
	var o := 0
	while o < body.size():
		var kind := body[o]
		if kind == _KIND_LIST:
			if o + 15 > body.size():
				return []
			var chunk := Vector3i(body.decode_s32(o + 1), body.decode_s32(o + 5), body.decode_s32(o + 9))
			var n := body.decode_u16(o + 13)
			o += 15
			if o + n * _LIST_ENTRY > body.size():
				return []
			var edits := PackedInt32Array()
			for i in n:
				var cell := body.decode_u16(o + i * _LIST_ENTRY)
				var id := body.decode_u16(o + i * _LIST_ENTRY + 2)
				if cell < 4096 and id <= MAX_ID:
					edits.append(cell)
					edits.append(id)
			o += n * _LIST_ENTRY
			out.append({"kind": LIST, "chunk": chunk, "edits": edits})
		elif kind == _KIND_CELLS:
			if o + 3 > body.size():
				return []
			var n := body.decode_u16(o + 1)
			o += 3
			if o + n * CELL_BYTES > body.size():
				return []
			var cells := []
			for i in n:
				var c := o + i * CELL_BYTES
				var p := Vector3i(body.decode_s32(c), body.decode_s16(c + 4), body.decode_s32(c + 6))
				var id := body.decode_u16(c + 10)
				if p.y >= MIN_Y and p.y < MAX_Y and id <= MAX_ID:
					cells.append([p, id])
			o += n * CELL_BYTES
			out.append({"kind": CELLS, "cells": cells})
		else:
			return []
	return out
