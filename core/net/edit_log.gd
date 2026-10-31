class_name EditLog
extends RefCounted
## The host's log of edited cells per 16³ chunk (M4 Wave 1 A, spec §17.0). A guest generates the
## terrain from the seed, so the host sends it only the cells of a chunk that differ from the
## generated terrain: the chunk's list when the chunk comes into the guest's view, then each change.
## A chunk is either unknown (never looked at, too many edits, or forgotten to save memory: the host
## diffs its blocks against the generator when a guest needs it, then learns the result) or known:
## every cell not listed is as generated, so the block a cell had before its first edit is the
## generated one, and an edit back to it (an undo) takes the cell off the list.
## Cells are numbered like a VoxelBuffer's bytes: y + 16 * (x + 16 * z).

const CHUNK := 16
## Cells kept per chunk. A chunk with more is forgotten and diffed whenever a guest needs it.
const CAP := 512
const CH := VoxelBuffer.CHANNEL_TYPE

var _max_chunks: int
var _chunks := {}   # chunk -> Dictionary[cell -> entry(id, generated id)]
var _used := {}     # chunk -> tick of its last use (the least recently used is forgotten first)
var _tick := 0


## Keeps at most max_chunks chunks (known chunks with no edits count too).
func _init(max_chunks: int = 4096) -> void:
	_max_chunks = maxi(max_chunks, 1)


static func chunk_of(pos: Vector3i) -> Vector3i:
	return Vector3i(pos.x >> 4, pos.y >> 4, pos.z >> 4)


static func cell_of(pos: Vector3i) -> int:
	return (pos.y & 15) + CHUNK * ((pos.x & 15) + CHUNK * (pos.z & 15))


static func cell_pos(chunk: Vector3i, cell: int) -> Vector3i:
	return chunk * CHUNK + Vector3i((cell >> 4) & 15, cell & 15, cell >> 8)


## One cell's entry: the id there now and the generated one.
static func entry(id: int, generated: int) -> int:
	return (id & 0xffff) | ((generated & 0xffff) << 16)


func knows(chunk: Vector3i) -> bool:
	return _chunks.has(chunk)


func size() -> int:
	return _chunks.size()


## The chunk's differing cells (cell -> entry), from a diff or {} for an untouched chunk. A diff
## over the cap is not kept.
func learn(chunk: Vector3i, cells: Dictionary) -> void:
	if cells.size() > CAP:
		forget(chunk)
		return
	_chunks[chunk] = cells.duplicate()
	_touch(chunk)
	if _chunks.size() > _max_chunks:
		_forget_oldest()


## A cell changed from old_id to new_id (WorldService.block_changed).
func record(pos: Vector3i, old_id: int, new_id: int) -> void:
	var chunk := chunk_of(pos)
	var cells: Dictionary = _chunks.get(chunk, {})
	if not _chunks.has(chunk):
		return
	var cell := cell_of(pos)
	var generated: int = (int(cells[cell]) >> 16) if cells.has(cell) else old_id
	if new_id == generated:
		cells.erase(cell)
	else:
		cells[cell] = entry(new_id, generated)
		if cells.size() > CAP:
			forget(chunk)
			return
	_touch(chunk)


## How many cells of a known chunk differ from the generated terrain (0 when unknown).
func edit_count(chunk: Vector3i) -> int:
	return (_chunks[chunk] as Dictionary).size() if _chunks.has(chunk) else 0


## [cell, id, cell, id, ...] in cell order.
func edits(chunk: Vector3i) -> PackedInt32Array:
	if _chunks.has(chunk):
		_touch(chunk)
	return flat(_chunks.get(chunk, {}))


## Cells (cell -> entry) as [cell, id, cell, id, ...] in cell order.
static func flat(cells: Dictionary) -> PackedInt32Array:
	var keys := cells.keys()
	keys.sort()
	var out := PackedInt32Array()
	out.resize(keys.size() * 2)
	for i in keys.size():
		out[i * 2] = keys[i]
		out[i * 2 + 1] = int(cells[keys[i]]) & 0xffff
	return out


func forget(chunk: Vector3i) -> void:
	_chunks.erase(chunk)
	_used.erase(chunk)


func clear() -> void:
	_chunks.clear()
	_used.clear()


## The cells where `current` differs from `generated` (two buffers of one size; for a chunk the
## keys are its cells, for another box the index in its bytes): cell -> entry.
## Compares 4 cells at a time; the buffers are copied, never changed.
static func diff(current: VoxelBuffer, generated: VoxelBuffer) -> Dictionary:
	return diff_bytes(bytes_of(current), bytes_of(generated))


## diff() over two buffers' ids (bytes_of).
static func diff_bytes(a: PackedByteArray, b: PackedByteArray) -> Dictionary:
	var out := {}
	if a == b or a.size() != b.size():
		return out
	for off in range(0, a.size(), 8):
		if off + 8 <= a.size() and a.decode_u64(off) == b.decode_u64(off):
			continue
		for k in range(off, mini(off + 8, a.size()), 2):
			var now := a.decode_u16(k)
			var was := b.decode_u16(k)
			if now != was:
				out[k >> 1] = entry(now, was)
	return out


## The block ids of a buffer, 16-bit little-endian (the buffer is copied, never changed).
static func bytes_of(buf: VoxelBuffer) -> PackedByteArray:
	var copy := VoxelBuffer.new()
	copy.create(buf.get_size().x, buf.get_size().y, buf.get_size().z)
	copy.copy_channel_from(buf, CH)
	copy.decompress_channel(CH)
	return copy.get_channel_as_byte_array(CH)


func _touch(chunk: Vector3i) -> void:
	_tick += 1
	_used[chunk] = _tick


func _forget_oldest() -> void:
	var oldest: Variant = null
	var oldest_tick := 0
	for c: Vector3i in _used:
		if oldest == null or int(_used[c]) < oldest_tick:
			oldest = c
			oldest_tick = _used[c]
	if oldest != null:
		forget(oldest)
