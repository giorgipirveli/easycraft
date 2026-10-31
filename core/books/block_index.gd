class_name BlockIndex
extends RefCounted
## Where a few kinds of block are (M3 Task 21b: the trophy shelves), from an index of 16-block chunks: a chunk
## is copied once (one bulk copy and a native search: `scan_chunk`), at most a budget of chunks a look, nearest
## first; blocks placed and broken reach it at once on the host (`note_block` from WorldService.block_changed);
## a guest's world announces no edits, so its chunks are looked at again after `cache_seconds`. The pattern of
## the lanterns' index (DefenseDirector, M2 Task 8), for any block ids. Never a box copy per frame or per body.

const CHUNK := 16
const MAX_CHUNKS := 512            # the index forgets everything past this (it fills again as needed)

## scan_chunk(chunk: Vector3i) -> Array[Vector3i]: every cell of one of `ids` in that chunk.
var scan_chunk: Callable
## chunk_ready(chunk: Vector3i) -> bool: the chunk is loaded (a copy would read real blocks). Unset: always.
var chunk_ready: Callable
## A guest's copy of a chunk is looked at again after this long (0: never; the host hears every edit).
var cache_seconds := 0.0
var ids: Array[int] = []

var _chunks := {}                  # chunk -> {"at": clock when copied, "cells": Array[Vector3i]}
var _clock := 0.0


func _init(block_ids: Array[int] = []) -> void:
	ids = block_ids.duplicate()


static func chunk_of(cell: Vector3i) -> Vector3i:
	return Vector3i(floori(cell.x / float(CHUNK)), floori(cell.y / float(CHUNK)), floori(cell.z / float(CHUNK)))


func advance(delta: float) -> void:
	_clock += delta


## The indexed cells within `radius` of `pos`. Chunks not copied yet (or too old) are copied first, nearest
## first, at most budget[0] of them (the budget is shared by the caller's looks and counted down).
func near(pos: Vector3, radius: float, budget: Array) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var lo := chunk_of(Vector3i((pos - Vector3.ONE * radius).floor()))
	var hi := chunk_of(Vector3i((pos + Vector3.ONE * radius).floor()))
	var missing: Array[Vector3i] = []
	for x in range(lo.x, hi.x + 1):
		for y in range(lo.y, hi.y + 1):
			for z in range(lo.z, hi.z + 1):
				var c := Vector3i(x, y, z)
				var entry: Variant = _chunks.get(c)
				if entry == null or (cache_seconds > 0.0 and _clock - float(entry.at) >= cache_seconds):
					missing.append(c)
				else:
					_collect(entry.cells, pos, radius, out)
	if missing.is_empty() or budget.is_empty() or int(budget[0]) <= 0 or not scan_chunk.is_valid():
		return out
	var middle := pos / CHUNK
	missing.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		return (Vector3(a) + Vector3.ONE * 0.5).distance_squared_to(middle) < (Vector3(b) + Vector3.ONE * 0.5).distance_squared_to(middle))
	for c in missing:
		if int(budget[0]) <= 0:
			break
		if chunk_ready.is_valid() and not chunk_ready.call(c):
			continue
		budget[0] = int(budget[0]) - 1
		var found: Array[Vector3i] = []
		found.assign(scan_chunk.call(c))
		if _chunks.size() >= MAX_CHUNKS and not _chunks.has(c):
			_chunks.clear()
		_chunks[c] = {"at": _clock, "cells": found}
		_collect(found, pos, radius, out)
	return out


static func _collect(cells: Array[Vector3i], pos: Vector3, radius: float, out: Array[Vector3i]) -> void:
	for cell in cells:
		if (Vector3(cell) + Vector3.ONE * 0.5).distance_to(pos) <= radius:
			out.append(cell)


## A block changed (the host's WorldService.block_changed): a chunk already copied follows it at once.
func note_block(pos: Vector3i, old_id: int, new_id: int) -> void:
	if not (ids.has(old_id) or ids.has(new_id)):
		return
	var entry: Variant = _chunks.get(chunk_of(pos))
	if entry == null:
		return
	var cells: Array[Vector3i] = entry.cells
	if ids.has(new_id):
		if not cells.has(pos):
			cells.append(pos)
	else:
		cells.erase(pos)
