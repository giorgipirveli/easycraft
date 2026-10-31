class_name EditOverlay
extends RefCounted
## A guest's copy of the host's edits (M4 Wave 1 A, spec §17.0), per 16³ chunk: the lists the host
## sends when a chunk comes into view and every single change after that. EditedGenerator writes
## them over the terrain it makes from the seed, so a chunk that loads, or unloads and loads again,
## comes out as the host has it. The generator runs on worker threads: every access holds the lock.
## M4 Task 10 review I: WorldSync forgets a chunk the guest's terrain unloaded for a while (forget), and
## the host sends its list again when it comes back into the guest's view, so this stays about one view.

var _lock := Mutex.new()
var _chunks := {}   # chunk -> Dictionary[cell -> id]
var _cells := 0


## Adds a chunk's list (EditLog.edits: [cell, id, ...]) to what is known of the chunk.
func put_list(chunk: Vector3i, edits: PackedInt32Array) -> void:
	_lock.lock()
	var cells: Dictionary = _chunks.get(chunk, {})
	for i in range(0, edits.size() - 1, 2):
		if not cells.has(edits[i]):
			_cells += 1
		cells[edits[i]] = edits[i + 1]
	if not cells.is_empty():
		_chunks[chunk] = cells
	_lock.unlock()


func put_cell(pos: Vector3i, id: int) -> void:
	var chunk := EditLog.chunk_of(pos)
	var cell := EditLog.cell_of(pos)
	_lock.lock()
	var cells: Dictionary = _chunks.get(chunk, {})
	if not cells.has(cell):
		_cells += 1
	cells[cell] = id
	_chunks[chunk] = cells
	_lock.unlock()


## [cell, id, ...] of a chunk, in cell order.
func edits(chunk: Vector3i) -> PackedInt32Array:
	_lock.lock()
	var cells: Dictionary = _chunks.get(chunk, {}).duplicate()
	_lock.unlock()
	var keys := cells.keys()
	keys.sort()
	var out := PackedInt32Array()
	for k: int in keys:
		out.append(k)
		out.append(cells[k])
	return out


func has_chunk(chunk: Vector3i) -> bool:
	_lock.lock()
	var yes := _chunks.has(chunk)
	_lock.unlock()
	return yes


## Drops what is known of a chunk (its list comes again with the chunk).
func forget(chunk: Vector3i) -> void:
	_lock.lock()
	var cells: Dictionary = _chunks.get(chunk, {})
	_cells -= cells.size()
	_chunks.erase(chunk)
	_lock.unlock()


func chunk_count() -> int:
	_lock.lock()
	var n := _chunks.size()
	_lock.unlock()
	return n


func cell_count() -> int:
	return _cells


func clear() -> void:
	_lock.lock()
	_chunks.clear()
	_cells = 0
	_lock.unlock()


## Writes the known edits inside the box of `buf` at `origin` (world cells) into it.
func apply(buf: VoxelBuffer, origin: Vector3i) -> void:
	var size := buf.get_size()
	var last := origin + size - Vector3i.ONE
	var c0 := EditLog.chunk_of(origin)
	var c1 := EditLog.chunk_of(last)
	var found := []
	_lock.lock()
	if not _chunks.is_empty():
		for cz in range(c0.z, c1.z + 1):
			for cy in range(c0.y, c1.y + 1):
				for cx in range(c0.x, c1.x + 1):
					var c := Vector3i(cx, cy, cz)
					if _chunks.has(c):
						found.append([c, (_chunks[c] as Dictionary).duplicate()])
	_lock.unlock()
	for pair: Array in found:
		var cells: Dictionary = pair[1]
		for cell: int in cells:
			var l := EditLog.cell_pos(pair[0], cell) - origin
			if l.x >= 0 and l.y >= 0 and l.z >= 0 and l.x < size.x and l.y < size.y and l.z < size.z:
				buf.set_voxel(cells[cell], l.x, l.y, l.z, VoxelBuffer.CHANNEL_TYPE)
