extends GutTest
## The host's saved-chunk comparison on worker threads (M4 Wave 2 A2, spec §17.0): a chunk the edit
## log does not know is copied and compared with the generator off the main thread (6-9 ms a chunk
## on the desktop, 3-5x on a phone); the result is taken on the main thread, with the changes made
## to the chunk meanwhile replayed over it. It must be the same as the main-thread diff.

const SEED := 20260924
const CH := VoxelBuffer.CHANNEL_TYPE
const CHUNK := Vector3i(1, 1, -2)   # a surface chunk: terrain, air and trees

var generator: MeadowsGenerator
var world: VoxelBuffer   # the host's blocks of CHUNK (what copy() reads)
var copies := [0]
var _copies_lock := Mutex.new()   # two worker threads count at once (a lost += made this test flaky)


func before_each() -> void:
	generator = MeadowsGenerator.new()
	generator.world_seed = SEED
	world = _generated(CHUNK)
	copies = [0]


func _generated(chunk: Vector3i) -> VoxelBuffer:
	var b := VoxelBuffer.new()
	b.create(EditLog.CHUNK, EditLog.CHUNK, EditLog.CHUNK)
	generator.generate_block(b, chunk * EditLog.CHUNK, 0)
	return b


## Reads the host's blocks (on a worker thread): here one buffer stands for the world.
func _copy(_origin: Vector3i, into: VoxelBuffer) -> void:
	into.copy_channel_from(world, CH)
	_copies_lock.lock()
	copies[0] += 1
	_copies_lock.unlock()


func _differ() -> ChunkDiffer:
	return ChunkDiffer.new(generator, _copy)


## Waits (on this thread) until every job is back; the results.
func _collect(d: ChunkDiffer) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var until := Time.get_ticks_msec() + 10000
	while d.size() > 0 and Time.get_ticks_msec() < until:
		out.append_array(d.done())
		OS.delay_msec(1)
	return out


func _edit(pos_in_chunk: Vector3i, id: int) -> Vector3i:
	world.set_voxel(id, pos_in_chunk.x, pos_in_chunk.y, pos_in_chunk.z, CH)
	return CHUNK * EditLog.CHUNK + pos_in_chunk


func test_the_threaded_diff_equals_the_main_thread_diff() -> void:
	_edit(Vector3i(3, 4, 5), BlockIds.BRICK)
	_edit(Vector3i(0, 0, 0), BlockIds.GLASS)
	_edit(Vector3i(15, 15, 15), BlockIds.RED)
	var expected := EditLog.diff(world, _generated(CHUNK))
	assert_eq(expected.size(), 3, "the three edits differ from the generator")
	var d := _differ()
	assert_true(d.start(CHUNK))
	assert_true(d.busy(CHUNK))
	var got := _collect(d)
	assert_eq(got.size(), 1)
	assert_eq(got[0].chunk, CHUNK)
	assert_eq(got[0].cells, expected, "the same cells and entries (id, generated id)")
	assert_gt(float(got[0].ms), 0.0, "the worker's time is measured")
	assert_false(d.busy(CHUNK))
	assert_eq(copies[0], 1)


func test_an_untouched_chunk_has_no_cells() -> void:
	var d := _differ()
	d.start(CHUNK)
	assert_eq(_collect(d)[0].cells, {})


func test_changes_made_while_the_worker_runs_are_replayed_over_its_result() -> void:
	var generated := _generated(CHUNK)
	var kept := _edit(Vector3i(1, 1, 1), BlockIds.BRICK)       # in the save
	var undone := _edit(Vector3i(2, 2, 2), BlockIds.BRICK)     # in the save, undone meanwhile
	var d := _differ()
	d.start(CHUNK)
	# meanwhile on the main thread (the copy may or may not have seen these):
	var fresh := CHUNK * EditLog.CHUNK + Vector3i(7, 7, 7)
	d.changed(fresh, BlockIds.GLASS)
	var gen_undone := generated.get_voxel(2, 2, 2, CH)
	_edit(Vector3i(2, 2, 2), gen_undone)
	d.changed(undone, gen_undone)
	d.changed(kept, BlockIds.RED)   # changed twice: the last one counts
	d.changed(kept, BlockIds.BLUE)
	d.changed(Vector3i(999, 0, 0), BlockIds.RED)   # another chunk: not this job's
	var cells: Dictionary = _collect(d)[0].cells
	assert_eq(cells.size(), 2, "the kept edit and the new one; the undone cell is as generated again")
	assert_eq(cells[EditLog.cell_of(kept)], EditLog.entry(BlockIds.BLUE, generated.get_voxel(1, 1, 1, CH)))
	assert_eq(cells[EditLog.cell_of(fresh)], EditLog.entry(BlockIds.GLASS, generated.get_voxel(7, 7, 7, CH)))
	assert_false(cells.has(EditLog.cell_of(undone)))


func test_a_change_back_to_the_generated_block_is_right_whether_the_copy_saw_it_or_not() -> void:
	var generated := _generated(CHUNK)
	var pos := _edit(Vector3i(4, 4, 4), BlockIds.BRICK)
	var gen := generated.get_voxel(4, 4, 4, CH)
	# The undo lands before the copy is made: the copy is as generated there already.
	_edit(Vector3i(4, 4, 4), gen)
	var d := _differ()
	d.start(CHUNK)
	d.changed(pos, gen)
	assert_eq(_collect(d)[0].cells, {}, "no entry with a wrong 'generated' id (a later edit back would be lost)")


func test_at_most_max_jobs_run_and_one_chunk_once() -> void:
	var d := _differ()
	for i in ChunkDiffer.MAX_JOBS:
		assert_true(d.start(Vector3i(i, 1, 0)), "job %d starts" % i)
	assert_false(d.can_start())
	assert_false(d.start(Vector3i(50, 1, 0)), "full: the chunk waits for a free worker")
	assert_false(d.busy(Vector3i(50, 1, 0)))
	assert_false(d.start(Vector3i(0, 1, 0)), "already running")
	assert_eq(d.size(), ChunkDiffer.MAX_JOBS)
	assert_eq(_collect(d).size(), ChunkDiffer.MAX_JOBS)
	assert_true(d.can_start())


func test_wait_all_finishes_every_job() -> void:
	var d := _differ()
	d.start(CHUNK)
	d.start(CHUNK + Vector3i.RIGHT)
	d.wait_all()
	assert_eq(d.size(), 0)
	assert_eq(copies[0], 2)
