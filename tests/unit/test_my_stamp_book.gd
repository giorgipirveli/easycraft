extends GutTest
## My Stamps (M3 Task 20b, spec §14.21, research C2): the child's own small builds (at most 16 blocks a side and
## EditBatch.MAX_BATCH blocks, so one stamp is always one edit and one undo) kept on this device
## (user://my_stamps.json), one hotbar item id per slot (ItemIds.MY_STAMP_FIRST + slot, 495-499), placed by
## Blueprints like the preset stamps.

var DIR := "user://test_my_stamp_book_%d/" % OS.get_process_id()
var _saved: MyStampBook


func before_all() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	_saved = MyStampBook.current()


func after_each() -> void:
	MyStampBook.use(_saved)
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func _box(size: Vector3i, id := BlockIds.PLANKS, at := Vector3i(100, 20, -40)) -> Dictionary:
	var b := {}
	for x in size.x:
		for y in size.y:
			for z in size.z:
				b[at + Vector3i(x, y, z)] = id
	return b


func test_the_item_ids_are_the_allocated_ones_and_no_block_or_item_takes_them() -> void:
	assert_eq(ItemIds.MY_STAMP_FIRST, 495)
	assert_eq(MyStampBook.SLOTS, ItemIds.MY_STAMP_SLOTS)
	assert_eq(ItemIds.MY_STAMP_FIRST + MyStampBook.SLOTS - 1, 499)
	for id in range(ItemIds.MY_STAMP_FIRST, ItemIds.MY_STAMP_FIRST + MyStampBook.SLOTS):
		assert_true(ItemIds.is_my_stamp(id))
		assert_true(ItemIds.is_stamp(id), "placed like the M1 stamps")
		assert_true(ItemIds.is_hotbar_valid(id))
		assert_false(BlockIds.is_valid(id), "no block has it: %d" % id)
		assert_false(ItemIds.ALL.has(id), "no catalogue item has it: %d" % id)
		assert_false(ItemIds.is_gift_stamp(id))
	assert_false(ItemIds.is_my_stamp(ItemIds.MY_STAMP_FIRST - 1))
	assert_false(ItemIds.is_my_stamp(ItemIds.MY_STAMP_FIRST + MyStampBook.SLOTS))


func test_a_build_is_saved_into_the_lowest_free_slot_from_its_lowest_corner() -> void:
	var book := MyStampBook.new()
	assert_eq(book.add(_box(Vector3i(2, 3, 1))), 0)
	assert_eq(book.add(_box(Vector3i(1, 1, 1), BlockIds.BRICK)), 1)
	var b := book.blocks_of(0)
	assert_eq(b.size(), 6)
	assert_true(b.has(Vector3i.ZERO), "from its lowest corner")
	assert_true(b.has(Vector3i(1, 2, 0)))
	assert_true(book.remove(0))
	assert_eq(book.add(_box(Vector3i(1, 1, 1))), 0, "a free slot is used again")
	assert_eq(book.name_of(1), "My Stamp 2")
	assert_eq(MyStampBook.item_of(1), ItemIds.MY_STAMP_FIRST + 1)
	assert_eq(MyStampBook.slot_of(ItemIds.MY_STAMP_FIRST + 1), 1)
	assert_eq(MyStampBook.slot_of(ItemIds.WAND), -1)


func test_the_size_cap() -> void:
	var book := MyStampBook.new()
	assert_eq(MyStampBook.refusal(_box(Vector3i(16, 1, 16))), "", "16 a side is fine")
	assert_eq(MyStampBook.refusal(_box(Vector3i(17, 1, 1))), "too_big", "17 long is too big")
	assert_eq(MyStampBook.refusal(_box(Vector3i(1, 17, 1))), "too_big")
	assert_eq(MyStampBook.refusal(_box(Vector3i(16, 7, 16))), "too_many", "more blocks than one edit takes")
	assert_eq(MyStampBook.refusal({}), "empty")
	assert_eq(book.add(_box(Vector3i(17, 1, 1))), -1)
	assert_eq(book.stamps.size(), 0)
	for code in ["too_big", "too_many", "empty", "full"]:
		assert_ne(MyStampBook.message(code), "", code)


func test_a_full_book_says_so() -> void:
	var book := MyStampBook.new()
	for i in MyStampBook.SLOTS:
		assert_eq(book.add(_box(Vector3i.ONE)), i)
	assert_true(book.is_full())
	assert_eq(MyStampBook.refusal(_box(Vector3i.ONE), book), "full")
	assert_eq(book.add(_box(Vector3i.ONE)), -1)


func test_it_places_like_the_preset_stamps() -> void:
	var book := MyStampBook.new()
	MyStampBook.use(book)
	book.add(_box(Vector3i(3, 2, 2), BlockIds.BRICK))
	var edits := Blueprints.place(MyStampBook.item_of(0), Vector3i(10, 5, 10), Vector3i(0, 0, -1))
	assert_eq(edits.size(), 12, "every block, nothing more")
	for e: Array in edits:
		assert_eq(e[1], BlockIds.BRICK)
		assert_eq((e[0] as Vector3i).y - 5, clampi((e[0] as Vector3i).y - 5, 0, 1), "standing on the tapped spot")
	assert_lte(edits.size(), EditBatch.MAX_BATCH)
	assert_eq(ItemIds.display_name(MyStampBook.item_of(0)), "My Stamp 1")
	assert_not_null(BlockIcons.icon(MyStampBook.item_of(0)), "an icon for the hotbar")
	assert_eq(Blueprints.place(MyStampBook.item_of(3), Vector3i.ZERO, Vector3i(0, 0, -1)), [], "an empty slot places nothing")


func test_it_is_kept_on_this_device() -> void:
	var book := MyStampBook.new()
	book.add(_box(Vector3i(2, 2, 2), BlockIds.GLASS))
	book.add(_box(Vector3i(1, 3, 1), BlockIds.LOG))
	assert_eq(book.save_to(DIR + "my_stamps.json"), OK)
	var back := MyStampBook.load_from(DIR + "my_stamps.json")
	assert_eq(back.slots(), [0, 1] as Array[int])
	assert_eq(back.blocks_of(0).size(), 8)
	assert_eq(back.blocks_of(1).values(), [BlockIds.LOG, BlockIds.LOG, BlockIds.LOG])


func test_a_broken_file_never_breaks_it() -> void:
	for text in ["", "junk", "[]", "{\"stamps\": 5}", "{\"stamps\": [{\"slot\": 99, \"build\": \"x\"}, 7, {\"slot\": 1}]}"]:
		var book := MyStampBook.from_json(text)
		assert_eq(book.stamps.size(), 0, text)
