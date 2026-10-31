class_name GuestSync
extends RefCounted
## What the host still owes one guest of the world (M4 Wave 1 A, spec §17.0). The guest generates
## the terrain from the seed; the host sends it the edit list of each chunk that comes into its
## view (once), then every later change in a chunk it has, as a single change. take() packs one
## frame's worth: single changes first (in order), then lists, nearest chunk first, within the byte
## budget (one record always goes, so a big one is never stuck).
## Order is what keeps the guest right: a list is made from the log at the moment it is packed and
## goes out in that frame's packet, and the chunk counts as the guest's from then on, so every
## later change follows it; a change in a chunk whose list is still owed is not sent at all (the
## list will carry it).

const CELLS_PER_RECORD := 256
## Lists that are not ready (made on a worker thread) a frame asks about before it stops.
const MAX_SKIPS := 8

var _has := {}       # chunk -> true: the guest has this chunk's list (or it has no edits)
var _owed := {}      # chunk -> true: its list is still to send
var _cells: Array = []   # [pos, id] single changes to send, in order
var _skipped := {}   # chunk -> true: its list was not ready in this take


func chunk_entered(chunk: Vector3i) -> void:
	if not _has.has(chunk):
		_owed[chunk] = true


## A chunk the host knows has no edits: nothing to send, and later changes go as single changes.
func chunk_as_generated(chunk: Vector3i) -> void:
	_owed.erase(chunk)
	_has[chunk] = true


## M4 Task 10 review I: the chunk came into the guest's view again (the guest may have forgotten its edits):
## it no longer counts as the guest's, so chunk_entered owes its list again. A list still owed stays owed.
func forget(chunk: Vector3i) -> void:
	_has.erase(chunk)


func has_chunk(chunk: Vector3i) -> bool:
	return _has.has(chunk)


func changed(pos: Vector3i, id: int) -> void:
	if _has.has(EditLog.chunk_of(pos)):
		_cells.append([pos, id])


func has_work() -> bool:
	return not _cells.is_empty() or not _owed.is_empty()


## Lists and single changes still to send.
func pending() -> int:
	return _owed.size() + _cells.size()


## Records (EditCodec) for this frame. list_of(chunk) -> PackedInt32Array (the chunk's edits, made
## now), null (not ready this frame, e.g. its diff runs on a worker thread: the next chunk is asked;
## after MAX_SKIPS of them the frame stops), or false (the host has not got the chunk loaded any
## more: drop it; it comes into view again).
func take(budget: int, near: Vector3, list_of: Callable) -> PackedByteArray:
	var out := PackedByteArray()
	while not _cells.is_empty():
		var room := (budget - out.size() - EditCodec.cells_bytes(0)) / EditCodec.CELL_BYTES
		var n := mini(mini(_cells.size(), CELLS_PER_RECORD), room)
		if n <= 0:
			if not out.is_empty():
				return out
			n = 1
		out.append_array(EditCodec.pack_cells(_cells.slice(0, n)))
		_cells = _cells.slice(n)
	_skipped.clear()
	while _owed.size() > _skipped.size() and (out.is_empty() or out.size() + EditCodec.list_bytes(1) <= budget):
		var chunk := _nearest(near)
		var edits: Variant = list_of.call(chunk)
		if edits == null:
			_skipped[chunk] = true
			if _skipped.size() >= MAX_SKIPS:
				break
			continue
		_owed.erase(chunk)
		if edits is bool:
			continue
		_has[chunk] = true
		if (edits as PackedInt32Array).is_empty():
			continue
		out.append_array(EditCodec.pack_list(chunk, edits))
	return out


func _nearest(near: Vector3) -> Vector3i:
	var best := Vector3i.ZERO
	var best_d := INF
	for c: Vector3i in _owed:
		if _skipped.has(c):
			continue
		var d := near.distance_squared_to(Vector3(c * EditLog.CHUNK) + Vector3.ONE * (EditLog.CHUNK * 0.5))
		if d < best_d:
			best_d = d
			best = c
	return best
