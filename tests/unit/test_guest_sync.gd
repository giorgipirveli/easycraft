extends GutTest
## What the host still owes one guest (M4 Wave 1 A): chunk lists for chunks that came into the
## guest's view, then single changes for chunks the guest has; changes first, lists nearest first,
## within the frame's byte budget, and never a single change ahead of its chunk's list.

var lists := {}   # chunk -> edits a fake log returns
var asked: Array[Vector3i] = []


func _list_of(chunk: Vector3i) -> Variant:
	asked.append(chunk)
	return lists.get(chunk, PackedInt32Array())


func before_each() -> void:
	lists = {}
	asked = []


func test_a_chunk_in_view_sends_its_list_once() -> void:
	var g := GuestSync.new()
	lists[Vector3i(1, 2, 0)] = PackedInt32Array([7, BlockIds.RED])
	g.chunk_entered(Vector3i(1, 2, 0))
	assert_true(g.has_work())
	var got := EditCodec.open(EditCodec.seal(g.take(4096, Vector3.ZERO, _list_of)))
	assert_eq(got.size(), 1)
	assert_eq(got[0].chunk, Vector3i(1, 2, 0))
	assert_false(g.has_work())
	g.chunk_entered(Vector3i(1, 2, 0))   # it came into view again: the guest has it already
	assert_false(g.has_work())


## M4 Task 10 review I: a guest forgets the edits of chunks it unloaded, so a chunk the host sees coming into its view
## again is forgotten here (WorldSync) and owed its list once more.
func test_a_forgotten_chunk_is_owed_its_list_again() -> void:
	var g := GuestSync.new()
	var c := Vector3i(1, 2, 0)
	lists[c] = PackedInt32Array([7, BlockIds.RED])
	g.chunk_entered(c)
	g.take(4096, Vector3.ZERO, _list_of)
	assert_true(g.has_chunk(c))
	g.forget(c)
	assert_false(g.has_chunk(c))
	g.changed(Vector3i(16, 32, 0), BlockIds.GLASS)
	assert_false(g.has_work(), "no single change for a chunk it doesn't have (the list will carry it)")
	g.chunk_entered(c)
	var got := EditCodec.open(EditCodec.seal(g.take(4096, Vector3.ZERO, _list_of)))
	assert_eq(got.size(), 1)
	assert_eq(got[0].chunk, c, "the list again")


func test_a_chunk_without_edits_costs_no_bytes() -> void:
	var g := GuestSync.new()
	g.chunk_entered(Vector3i.ZERO)
	assert_eq(g.take(4096, Vector3.ZERO, _list_of), PackedByteArray())
	assert_true(g.has_chunk(Vector3i.ZERO))
	g.chunk_as_generated(Vector3i.ONE)
	assert_true(g.has_chunk(Vector3i.ONE))
	assert_false(g.has_work())


func test_a_change_in_a_chunk_the_guest_has_goes_as_a_single_change() -> void:
	var g := GuestSync.new()
	g.chunk_as_generated(Vector3i.ZERO)
	g.changed(Vector3i(3, 3, 3), BlockIds.GLASS)
	var got := EditCodec.open(EditCodec.seal(g.take(4096, Vector3.ZERO, _list_of)))
	assert_eq(got[0].cells, [[Vector3i(3, 3, 3), BlockIds.GLASS]])


func test_a_change_in_a_chunk_whose_list_is_still_owed_waits_for_the_list() -> void:
	var g := GuestSync.new()
	g.chunk_entered(Vector3i.ZERO)
	g.changed(Vector3i(3, 3, 3), BlockIds.GLASS)   # the list, made later, will carry it
	g.changed(Vector3i(99, 3, 3), BlockIds.GLASS)  # a chunk the guest never saw: nothing
	lists[Vector3i.ZERO] = PackedInt32Array([EditLog.cell_of(Vector3i(3, 3, 3)), BlockIds.GLASS])
	var got := EditCodec.open(EditCodec.seal(g.take(4096, Vector3.ZERO, _list_of)))
	assert_eq(got.size(), 1)
	assert_eq(got[0].kind, EditCodec.LIST)


func test_changes_go_before_lists_and_lists_nearest_first() -> void:
	var g := GuestSync.new()
	g.chunk_as_generated(Vector3i(0, 0, 0))
	for c: Vector3i in [Vector3i(9, 0, 0), Vector3i(2, 0, 0), Vector3i(5, 0, 0)]:
		lists[c] = PackedInt32Array([1, 1])
		g.chunk_entered(c)
	g.changed(Vector3i(1, 1, 1), BlockIds.RED)
	var got := EditCodec.open(EditCodec.seal(g.take(4096, Vector3(40, 8, 8), _list_of)))
	assert_eq(got[0].kind, EditCodec.CELLS)
	assert_eq([got[1].chunk, got[2].chunk, got[3].chunk], [Vector3i(2, 0, 0), Vector3i(5, 0, 0), Vector3i(9, 0, 0)])


func test_the_budget_stops_the_lists_and_the_rest_waits_for_the_next_frame() -> void:
	var g := GuestSync.new()
	for x in 3:
		lists[Vector3i(x, 0, 0)] = PackedInt32Array([1, 1, 2, 2])
		g.chunk_entered(Vector3i(x, 0, 0))
	var one := EditCodec.pack_list(Vector3i.ZERO, PackedInt32Array([1, 1, 2, 2])).size()
	var first := EditCodec.open(EditCodec.seal(g.take(one + 1, Vector3.ZERO, _list_of)))
	assert_eq(first.size(), 1, "one list fits")
	assert_eq(asked.size(), 1, "a list is made only when it is sent (it can't go stale)")
	assert_true(g.has_work())
	assert_eq(EditCodec.open(EditCodec.seal(g.take(one * 5, Vector3.ZERO, _list_of))).size(), 2)
	assert_false(g.has_work())


func test_one_record_always_goes_even_over_the_budget() -> void:
	var g := GuestSync.new()
	var big := PackedInt32Array()
	for i in 400:
		big.append_array([i, BlockIds.STONE])
	lists[Vector3i.ZERO] = big
	g.chunk_entered(Vector3i.ZERO)
	assert_eq(EditCodec.open(EditCodec.seal(g.take(100, Vector3.ZERO, _list_of)))[0].edits.size(), 800)


func test_many_changes_are_split_over_frames_in_order() -> void:
	var g := GuestSync.new()
	g.chunk_as_generated(Vector3i.ZERO)
	for i in 300:
		g.changed(Vector3i(i % 16, (i / 16) % 16, 0), i % 30)
	var seen := []
	for frame in 20:
		for rec: Dictionary in EditCodec.open(EditCodec.seal(g.take(600, Vector3.ZERO, _list_of))):
			seen.append_array(rec.cells)
	assert_eq(seen.size(), 300)
	assert_eq(seen[0][1], 0)
	assert_eq(seen[299][1], 299 % 30)


func test_a_list_that_is_not_ready_waits_and_one_that_is_gone_is_dropped() -> void:
	var g := GuestSync.new()
	g.chunk_entered(Vector3i.ZERO)
	g.chunk_entered(Vector3i.ONE)
	var ready := {"answer": null}
	var list_of := func(c: Vector3i) -> Variant: return ready.answer if c == Vector3i.ONE else false
	assert_eq(g.take(4096, Vector3.ZERO, list_of), PackedByteArray(), "the host could not diff this frame")
	assert_false(g.has_chunk(Vector3i.ZERO), "no longer loaded on the host: dropped, it comes into view again")
	assert_true(g.has_work(), "the other one waits")
	g.chunk_entered(Vector3i.ZERO)
	assert_true(g.has_work())
	ready.answer = PackedInt32Array([5, 5])
	var got := EditCodec.open(EditCodec.seal(g.take(4096, Vector3.ZERO, list_of)))
	assert_eq(got.size(), 1)
	assert_true(g.has_chunk(Vector3i.ONE))


func test_a_list_being_made_elsewhere_does_not_hold_back_a_list_that_is_ready() -> void:
	var g := GuestSync.new()
	g.chunk_entered(Vector3i(0, 0, 0))   # nearest, but its diff is still on a worker thread
	g.chunk_entered(Vector3i(3, 0, 0))   # known: ready now
	lists[Vector3i(3, 0, 0)] = PackedInt32Array([5, BlockIds.RED])
	var list_of := func(c: Vector3i) -> Variant:
		asked.append(c)
		return null if c == Vector3i.ZERO else lists[c]
	var got := EditCodec.open(EditCodec.seal(g.take(4096, Vector3.ZERO, list_of)))
	assert_eq(got.size(), 1)
	assert_eq(got[0].chunk, Vector3i(3, 0, 0), "the ready list went this frame")
	assert_eq(asked, [Vector3i.ZERO, Vector3i(3, 0, 0)], "each asked once")
	assert_true(g.has_work(), "the skipped one is still owed")
	assert_false(g.has_chunk(Vector3i.ZERO))


func test_a_frame_asks_about_a_bounded_number_of_lists_that_are_not_ready() -> void:
	var g := GuestSync.new()
	for x in 40:
		g.chunk_entered(Vector3i(x, 0, 0))
	var none := func(c: Vector3i) -> Variant:
		asked.append(c)
		return null
	assert_eq(g.take(4096, Vector3.ZERO, none), PackedByteArray())
	assert_eq(asked.size(), GuestSync.MAX_SKIPS, "nearest first, then it stops for this frame")
	assert_eq(asked[0], Vector3i.ZERO)
	assert_eq(g.pending(), 40)
