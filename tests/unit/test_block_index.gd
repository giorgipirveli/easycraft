extends GutTest
## M3 Task 21b: an index of 16-block chunks for a few block ids (the trophy shelves): each chunk is copied
## once (a few a look), placed and broken blocks reach it at once on the host, and a guest (whose world
## announces no edits) looks again after a while. The lantern index's pattern (M2 Task 8), for any ids.

var _scans: Array[Vector3i] = []
var _blocks := {}   # cell -> id


func _index() -> BlockIndex:
	_scans.clear()
	var ix := BlockIndex.new([BlockIds.TROPHY_SHELF])
	ix.scan_chunk = func(chunk: Vector3i) -> Array[Vector3i]:
		_scans.append(chunk)
		var out: Array[Vector3i] = []
		for cell: Vector3i in _blocks:
			if BlockIndex.chunk_of(cell) == chunk and _blocks[cell] == BlockIds.TROPHY_SHELF:
				out.append(cell)
		return out
	return ix


func test_finds_the_blocks_near_a_place() -> void:
	_blocks = {Vector3i(3, 3, 3): BlockIds.TROPHY_SHELF, Vector3i(40, 3, 3): BlockIds.TROPHY_SHELF,
		Vector3i(5, 3, 3): BlockIds.STONE}
	var ix := _index()
	var got := ix.near(Vector3(2, 3, 2), 10.0, [100])
	assert_eq(got, [Vector3i(3, 3, 3)] as Array[Vector3i])
	var scanned := _scans.size()
	ix.near(Vector3(2, 3, 2), 10.0, [100])
	assert_eq(_scans.size(), scanned, "each chunk is copied once")


func test_a_few_chunks_a_look() -> void:
	var ix := _index()
	ix.near(Vector3(0, 0, 0), 40.0, [2])
	assert_eq(_scans.size(), 2, "the budget")
	ix.near(Vector3(0, 0, 0), 40.0, [2])
	assert_eq(_scans.size(), 4, "the rest come later")


func test_placed_and_broken_blocks_count_at_once() -> void:
	_blocks = {}
	var ix := _index()
	ix.near(Vector3(8, 8, 8), 4.0, [100])
	ix.note_block(Vector3i(8, 8, 8), BlockIds.AIR, BlockIds.TROPHY_SHELF)
	assert_eq(ix.near(Vector3(8, 8, 8), 4.0, [0]), [Vector3i(8, 8, 8)] as Array[Vector3i])
	ix.note_block(Vector3i(8, 8, 8), BlockIds.TROPHY_SHELF, BlockIds.AIR)
	assert_eq(ix.near(Vector3(8, 8, 8), 4.0, [0]), [] as Array[Vector3i])


func test_a_guest_looks_again_after_a_while() -> void:
	_blocks = {}
	var ix := _index()
	ix.cache_seconds = 2.0
	ix.near(Vector3(8, 8, 8), 4.0, [100])
	_blocks[Vector3i(8, 8, 8)] = BlockIds.TROPHY_SHELF
	assert_eq(ix.near(Vector3(8, 8, 8), 4.0, [100]), [] as Array[Vector3i], "still the old copy")
	ix.advance(2.5)
	assert_eq(ix.near(Vector3(8, 8, 8), 4.0, [100]), [Vector3i(8, 8, 8)] as Array[Vector3i])


func test_chunks_not_loaded_yet_are_not_copied() -> void:
	var ix := _index()
	ix.chunk_ready = func(_c: Vector3i) -> bool: return false
	ix.near(Vector3.ZERO, 4.0, [100])
	assert_eq(_scans.size(), 0)
