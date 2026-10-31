extends GutTest


func test_lifo() -> void:
	var u := UndoStack.new()
	u.push(Vector3i(1, 0, 0), 0, 3)
	u.push(Vector3i(2, 0, 0), 0, 4)
	assert_eq(u.pop().pos, Vector3i(2, 0, 0))
	assert_eq(u.pop().pos, Vector3i(1, 0, 0))
	assert_eq(u.pop(), {})


func test_entry_keeps_old_and_new_ids() -> void:
	var u := UndoStack.new()
	u.push(Vector3i(5, 6, 7), 2, 9)
	var e := u.pop()
	assert_eq(e.old_id, 2)
	assert_eq(e.new_id, 9)


func test_capacity_drops_oldest() -> void:
	var u := UndoStack.new(20)
	for i in 25:
		u.push(Vector3i(i, 0, 0), 0, 1)
	assert_eq(u.size(), 20)
	var last := {}
	while u.size() > 0:
		last = u.pop()
	assert_eq(last.pos, Vector3i(5, 0, 0))


func test_clear() -> void:
	var u := UndoStack.new()
	u.push(Vector3i.ZERO, 0, 1)
	u.clear()
	assert_eq(u.size(), 0)


func test_batch_is_one_undo_step() -> void:
	var u := UndoStack.new()
	u.push(Vector3i(0, 0, 0), 0, 1)
	u.push_batch([{"pos": Vector3i(1, 0, 0), "old_id": 0, "new_id": 2}, {"pos": Vector3i(-1, 0, 0), "old_id": 0, "new_id": 2}])
	assert_eq(u.size(), 2)
	var e := u.pop()
	assert_eq((e.batch as Array).size(), 2)
	assert_eq(u.pop().pos, Vector3i(0, 0, 0))


func test_empty_batch_is_ignored() -> void:
	var u := UndoStack.new()
	u.push_batch([])
	assert_eq(u.size(), 0)
