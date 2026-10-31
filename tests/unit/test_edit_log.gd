extends GutTest
## The host's per-chunk edit log (M4 Wave 1 A, spec §17.0): a guest generates the terrain from the
## seed, so the host only sends the cells of a chunk that differ from the generated terrain.


func _pairs(log: EditLog, chunk: Vector3i) -> Dictionary:
	var out := {}
	var e := log.edits(chunk)
	for i in range(0, e.size(), 2):
		out[EditLog.cell_pos(chunk, e[i])] = e[i + 1]
	return out


func test_chunks_and_cells_cover_negative_positions() -> void:
	assert_eq(EditLog.chunk_of(Vector3i(0, 0, 0)), Vector3i.ZERO)
	assert_eq(EditLog.chunk_of(Vector3i(15, 31, 16)), Vector3i(0, 1, 1))
	assert_eq(EditLog.chunk_of(Vector3i(-1, -64, -17)), Vector3i(-1, -4, -2))
	for p: Vector3i in [Vector3i(3, 40, 9), Vector3i(-1, -64, -17), Vector3i(-16, 191, 31)]:
		var c := EditLog.chunk_of(p)
		var cell := EditLog.cell_of(p)
		assert_between(cell, 0, 4095)
		assert_eq(EditLog.cell_pos(c, cell), p, "round trip %s" % p)


func test_cells_are_numbered_like_a_voxel_buffers_bytes() -> void:
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	buf.set_voxel(7, 3, 5, 11, VoxelBuffer.CHANNEL_TYPE)
	buf.decompress_channel(VoxelBuffer.CHANNEL_TYPE)
	var bytes := buf.get_channel_as_byte_array(VoxelBuffer.CHANNEL_TYPE)
	var cell := EditLog.cell_of(Vector3i(3, 5, 11))
	assert_eq(bytes.decode_u16(cell * 2), 7)


func test_an_unknown_chunk_records_nothing() -> void:
	var log := EditLog.new()
	log.record(Vector3i(1, 2, 3), BlockIds.GRASS, BlockIds.RED)
	assert_false(log.knows(Vector3i.ZERO), "the host diffs it against the generator when a guest needs it")


func test_a_new_edit_is_added_and_keeps_what_was_generated() -> void:
	var log := EditLog.new()
	log.learn(Vector3i.ZERO, {})
	log.record(Vector3i(1, 2, 3), BlockIds.GRASS, BlockIds.RED)
	assert_eq(_pairs(log, Vector3i.ZERO), {Vector3i(1, 2, 3): BlockIds.RED})


func test_a_second_edit_of_a_cell_overwrites_the_first() -> void:
	var log := EditLog.new()
	log.learn(Vector3i.ZERO, {})
	log.record(Vector3i(1, 2, 3), BlockIds.GRASS, BlockIds.RED)
	log.record(Vector3i(1, 2, 3), BlockIds.RED, BlockIds.BLUE)
	assert_eq(_pairs(log, Vector3i.ZERO), {Vector3i(1, 2, 3): BlockIds.BLUE})


func test_an_undo_back_to_the_generated_block_leaves_nothing_to_send() -> void:
	var log := EditLog.new()
	log.learn(Vector3i.ZERO, {})
	log.record(Vector3i(1, 2, 3), BlockIds.GRASS, BlockIds.RED)
	log.record(Vector3i(1, 2, 3), BlockIds.RED, BlockIds.BLUE)
	log.record(Vector3i(1, 2, 3), BlockIds.BLUE, BlockIds.GRASS)
	assert_eq(_pairs(log, Vector3i.ZERO), {})
	assert_true(log.knows(Vector3i.ZERO), "still known: nothing differs")


func test_a_learned_diff_keeps_the_generated_blocks_for_undo() -> void:
	var log := EditLog.new()
	var cell := EditLog.cell_of(Vector3i(4, 4, 4))
	log.learn(Vector3i.ZERO, {cell: EditLog.entry(BlockIds.BRICK, BlockIds.STONE)})
	assert_eq(_pairs(log, Vector3i.ZERO), {Vector3i(4, 4, 4): BlockIds.BRICK})
	log.record(Vector3i(4, 4, 4), BlockIds.BRICK, BlockIds.STONE)
	assert_eq(_pairs(log, Vector3i.ZERO), {}, "stone was generated there")


func test_the_edit_count_of_a_chunk() -> void:
	var log := EditLog.new()
	assert_eq(log.edit_count(Vector3i.ZERO), 0, "unknown")
	log.learn(Vector3i.ZERO, {})
	log.record(Vector3i(1, 1, 1), 0, 5)
	log.record(Vector3i(2, 1, 1), 0, 5)
	assert_eq(log.edit_count(Vector3i.ZERO), 2)


func test_edits_are_listed_in_cell_order() -> void:
	var log := EditLog.new()
	log.learn(Vector3i.ZERO, {})
	log.record(Vector3i(9, 9, 9), 0, 5)
	log.record(Vector3i(1, 1, 1), 0, 6)
	var e := log.edits(Vector3i.ZERO)
	assert_eq(e.size(), 4)
	assert_lt(e[0], e[2])


func test_a_chunk_over_the_cap_is_forgotten_and_diffed_when_needed() -> void:
	var log := EditLog.new()
	log.learn(Vector3i.ZERO, {})
	for i in EditLog.CAP:
		log.record(EditLog.cell_pos(Vector3i.ZERO, i), 0, BlockIds.STONE)
	assert_true(log.knows(Vector3i.ZERO), "at the cap")
	log.record(EditLog.cell_pos(Vector3i.ZERO, EditLog.CAP), 0, BlockIds.STONE)
	assert_false(log.knows(Vector3i.ZERO), "over it")
	var big := {}
	for i in EditLog.CAP + 1:
		big[i] = EditLog.entry(BlockIds.STONE, 0)
	log.learn(Vector3i.ONE, big)
	assert_false(log.knows(Vector3i.ONE), "a diff over the cap is not kept either")


func test_the_log_keeps_at_most_max_chunks_forgetting_the_oldest() -> void:
	var log := EditLog.new(3)
	for x in 3:
		log.learn(Vector3i(x, 0, 0), {})
	log.record(Vector3i(0, 0, 0), 0, 1)   # chunk 0 used again: chunk 1 is the oldest now
	log.learn(Vector3i(9, 0, 0), {})
	assert_eq(log.size(), 3)
	assert_true(log.knows(Vector3i(0, 0, 0)))
	assert_false(log.knows(Vector3i(1, 0, 0)))
	assert_true(log.knows(Vector3i(9, 0, 0)))


func test_a_diff_finds_exactly_the_changed_cells() -> void:
	var gen := VoxelBuffer.new()
	gen.create(16, 16, 16)
	gen.fill(BlockIds.STONE, VoxelBuffer.CHANNEL_TYPE)
	var cur := VoxelBuffer.new()
	cur.create(16, 16, 16)
	cur.fill(BlockIds.STONE, VoxelBuffer.CHANNEL_TYPE)
	assert_eq(EditLog.diff(cur, gen), {}, "the same terrain")
	cur.set_voxel(BlockIds.AIR, 0, 0, 0, VoxelBuffer.CHANNEL_TYPE)
	cur.set_voxel(BlockIds.RED, 15, 15, 15, VoxelBuffer.CHANNEL_TYPE)
	cur.set_voxel(BlockIds.GLASS, 3, 7, 2, VoxelBuffer.CHANNEL_TYPE)
	var d := EditLog.diff(cur, gen)
	assert_eq(d.size(), 3)
	assert_eq(d[EditLog.cell_of(Vector3i(15, 15, 15))], EditLog.entry(BlockIds.RED, BlockIds.STONE))
	assert_eq(d[EditLog.cell_of(Vector3i(3, 7, 2))], EditLog.entry(BlockIds.GLASS, BlockIds.STONE))
	assert_eq(d[EditLog.cell_of(Vector3i(0, 0, 0))], EditLog.entry(BlockIds.AIR, BlockIds.STONE))


func test_a_diff_of_a_box_of_any_size_reads_no_further_than_its_bytes() -> void:
	var a := VoxelBuffer.new()
	a.create(3, 3, 3)
	var b := VoxelBuffer.new()
	b.create(3, 3, 3)
	a.set_voxel(BlockIds.RED, 2, 2, 2, VoxelBuffer.CHANNEL_TYPE)
	assert_eq(EditLog.diff(a, b).size(), 1, "the last cell, in the last short word")
