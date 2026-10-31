extends GutTest
## A guest's copy of the host's edits (M4 Wave 1 A): the generator writes them over the terrain it
## makes from the seed, on worker threads, so a chunk that loads (or loads again) comes out edited.


func _buffer(id: int = BlockIds.STONE) -> VoxelBuffer:
	var b := VoxelBuffer.new()
	b.create(16, 16, 16)
	b.fill(id, VoxelBuffer.CHANNEL_TYPE)
	return b


func test_a_list_and_single_changes_are_written_over_a_chunk() -> void:
	var o := EditOverlay.new()
	o.put_list(Vector3i(1, 2, 3), PackedInt32Array([EditLog.cell_of(Vector3i(0, 0, 0)), BlockIds.RED]))
	o.put_cell(Vector3i(16 + 5, 32 + 6, 48 + 7), BlockIds.GLASS)
	o.put_cell(Vector3i(16, 32, 48), BlockIds.BLUE)   # overwrites the list's cell
	var b := _buffer()
	o.apply(b, Vector3i(16, 32, 48))
	assert_eq(b.get_voxel(0, 0, 0, VoxelBuffer.CHANNEL_TYPE), BlockIds.BLUE)
	assert_eq(b.get_voxel(5, 6, 7, VoxelBuffer.CHANNEL_TYPE), BlockIds.GLASS)
	assert_eq(b.get_voxel(1, 1, 1, VoxelBuffer.CHANNEL_TYPE), BlockIds.STONE, "the rest is as generated")
	assert_eq(o.cell_count(), 2)


func test_other_chunks_are_left_alone() -> void:
	var o := EditOverlay.new()
	o.put_cell(Vector3i(-1, -1, -1), BlockIds.RED)
	var b := _buffer()
	o.apply(b, Vector3i.ZERO)
	assert_true(b.is_uniform(VoxelBuffer.CHANNEL_TYPE), "nothing written")
	var c := _buffer()
	o.apply(c, Vector3i(-16, -16, -16))
	assert_eq(c.get_voxel(15, 15, 15, VoxelBuffer.CHANNEL_TYPE), BlockIds.RED)


func test_the_edits_of_a_chunk_can_be_read_back() -> void:
	var o := EditOverlay.new()
	o.put_cell(Vector3i(2, 3, 4), BlockIds.RED)
	var e := o.edits(Vector3i.ZERO)
	assert_eq(e, PackedInt32Array([EditLog.cell_of(Vector3i(2, 3, 4)), BlockIds.RED]))
	assert_eq(o.edits(Vector3i.ONE), PackedInt32Array())


func test_the_generator_writes_the_edits_over_the_seeds_terrain() -> void:
	var base := MeadowsGenerator.new()
	base.world_seed = 4242
	var o := EditOverlay.new()
	var gen := EditedGenerator.new()
	gen.base = base
	gen.overlay = o
	var origin := Vector3i(0, 32, 0)
	var plain := VoxelBuffer.new()
	plain.create(16, 16, 16)
	base.generate_block(plain, origin, 0)
	o.put_cell(origin + Vector3i(3, 4, 5), BlockIds.PURPLE)
	var edited := VoxelBuffer.new()
	edited.create(16, 16, 16)
	gen.generate_block(edited, origin, 0)
	var d := EditLog.diff(edited, plain)
	assert_eq(d.keys(), [EditLog.cell_of(Vector3i(3, 4, 5))], "exactly the edit differs")


func test_worker_threads_can_read_while_the_main_thread_writes() -> void:
	var o := EditOverlay.new()
	var task := WorkerThreadPool.add_group_task(func(i: int) -> void:
		var b := _buffer()
		o.apply(b, Vector3i(0, (i % 4) * 16, 0)), 64)
	for i in 2000:
		o.put_cell(Vector3i(i % 16, (i / 16) % 64, 0), BlockIds.BRICK)
	WorkerThreadPool.wait_for_group_task_completion(task)
	assert_eq(o.cell_count(), 1024)


## M4 Task 10 review I: a guest's overlay never shrank; WorldSync now forgets a chunk the guest's terrain unloaded.
func test_a_chunks_edits_can_be_forgotten() -> void:
	var o := EditOverlay.new()
	var c := Vector3i(1, 2, 3)
	o.put_list(c, PackedInt32Array([EditLog.cell_of(Vector3i(0, 0, 0)), BlockIds.RED, EditLog.cell_of(Vector3i(1, 0, 0)), BlockIds.RED]))
	o.put_cell(Vector3i(2, 3, 4), BlockIds.GLASS)
	assert_eq(o.cell_count(), 3)
	assert_eq(o.chunk_count(), 2)
	o.forget(c)
	assert_false(o.has_chunk(c))
	assert_eq(o.edits(c), PackedInt32Array())
	assert_eq(o.cell_count(), 1)
	assert_eq(o.chunk_count(), 1)
	assert_true(o.has_chunk(Vector3i.ZERO), "the other chunk stays")
	o.forget(Vector3i(9, 9, 9))
	assert_eq(o.cell_count(), 1, "nothing there: nothing changes")
