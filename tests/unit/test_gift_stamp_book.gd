extends GutTest
## Friends' builds as stamps on this device (M4 Wave 3, agent I): GiftStampBook keeps opened gifts (and
## a bottle's tiny build) in user://gifts.json, one hotbar item id per slot (ItemIds.GIFT_STAMP_FIRST +
## slot); every one can be deleted by the child; Blueprints places them like the M1 stamps; the
## child's own picked builds wait on the "mine" shelf to be sent later.

var DIR := "user://test_gift_stamp_book_%d/" % OS.get_process_id()
var _saved: GiftStampBook


func before_all() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	_saved = GiftStampBook.current()


func after_each() -> void:
	GiftStampBook.use(_saved)
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func _cube(n: int, id: int = BlockIds.PLANKS) -> String:
	var b := {}
	for x in n:
		for y in n:
			for z in n:
				b[Vector3i(x, y, z)] = id
	return BuildCodec.encode(b)


func test_a_gift_takes_the_lowest_free_slot_and_its_item_id() -> void:
	var book := GiftStampBook.new()
	assert_eq(book.add(_cube(2), "Mia_2", "uid-mia"), 0)
	assert_eq(book.add(_cube(3, BlockIds.BRICK), "Pip_7", "uid-pip"), 1)
	assert_true(book.remove(0))
	assert_eq(book.add(_cube(1), "Mia_2", "uid-mia"), 0, "a free slot is used again")
	assert_eq(GiftStampBook.item_of(1), ItemIds.GIFT_STAMP_FIRST + 1)
	assert_eq(GiftStampBook.slot_of(ItemIds.GIFT_STAMP_FIRST + 1), 1)
	assert_eq(GiftStampBook.slot_of(ItemIds.WAND), -1)
	assert_eq(book.stamp(1).from, "Pip_7")
	assert_eq(book.blocks_of(1).size(), 27)


func test_a_broken_build_or_a_full_book_is_refused() -> void:
	var book := GiftStampBook.new()
	assert_eq(book.add("junk", "Mia_2", "uid"), -1)
	assert_eq(book.add(_cube(9), "Mia_2", "uid"), -1, "bigger than a gift")
	for i in GiftStampBook.SLOTS:
		assert_eq(book.add(_cube(1), "Mia_2", "uid"), i)
	assert_eq(book.add(_cube(1), "Mia_2", "uid"), -1, "full")
	assert_true(book.is_full())


func test_items_ids_know_gift_stamps() -> void:
	var book := GiftStampBook.new()
	GiftStampBook.use(book)
	var slot := book.add(_cube(2), "Mia_2", "uid-mia")
	var item := GiftStampBook.item_of(slot)
	assert_true(ItemIds.is_gift_stamp(item))
	assert_true(ItemIds.is_stamp(item), "placed like the M1 stamps")
	assert_true(ItemIds.is_hotbar_valid(item))
	assert_false(ItemIds.is_item(item), "not a catalogue item: never given, never sold")
	assert_eq(ItemIds.display_name(item), "Gift from Mia_2")
	assert_not_null(BlockIcons.icon(item))
	assert_false(ItemIds.is_gift_stamp(ItemIds.GIFT_STAMP_FIRST + GiftStampBook.SLOTS))
	for id in ItemIds.ALL:
		assert_false(ItemIds.is_gift_stamp(id), "no other item in the gift range: %d" % id)
	for id in range(1, 256):
		assert_false(ItemIds.is_gift_stamp(id), "no block in it: %d" % id)


func test_blueprints_place_a_gift_on_the_tapped_spot_facing_away() -> void:
	var book := GiftStampBook.new()
	GiftStampBook.use(book)
	var b := {Vector3i(0, 0, 0): BlockIds.PLANKS, Vector3i(1, 0, 0): BlockIds.GLASS, Vector3i(0, 1, 2): BlockIds.LIGHT}
	var slot := book.add(BuildCodec.encode(b), "Mia_2", "uid")
	var local := Blueprints.local(GiftStampBook.item_of(slot))
	assert_eq(local.size(), 3)
	assert_true(local.has(Vector3i(-1, 0, 0)) and local.has(Vector3i(0, 0, 0)), "centred on the tap: %s" % [local.keys()])
	assert_eq(local[Vector3i(-1, 1, 2)], BlockIds.LIGHT, "from the tap, away from the player")
	var edits := Blueprints.place(GiftStampBook.item_of(slot), Vector3i(10, 5, 10), Vector3i(0, 0, -1))
	assert_eq(edits.size(), 3)
	book.remove(slot)
	assert_eq(Blueprints.local(GiftStampBook.item_of(slot)), {}, "a deleted gift places nothing")
	assert_eq(Blueprints.place(GiftStampBook.item_of(slot), Vector3i.ZERO, Vector3i(0, 0, -1)), [])


func test_it_is_kept_on_the_device_and_read_back_carefully() -> void:
	var book := GiftStampBook.new()
	book.add(_cube(2), "Mia_2", "uid-mia", GiftStampBook.KIND_BOTTLE, 1234)
	book.keep_mine(_cube(3, BlockIds.BRICK))
	var path := DIR + "gifts.json"
	assert_eq(book.save_to(path), OK)
	var back := GiftStampBook.load_from(path)
	assert_eq(back.slots(), [0])
	assert_eq(back.stamp(0).kind, GiftStampBook.KIND_BOTTLE)
	assert_eq(back.stamp(0).at, 1234)
	assert_eq(back.mine.size(), 1)
	# A hand-edited file: bad stamps, a duplicated slot, a slot out of range, a bad name, broken types.
	var messy := JSON.stringify({"version": 1, "stamps": [
		{"slot": 0, "from": "Mia_2", "from_id": "u", "build": _cube(2), "kind": "gift", "at": 5},
		{"slot": 0, "from": "Pip_7", "from_id": "u", "build": _cube(2), "kind": "gift", "at": 5},
		{"slot": 99, "from": "Pip_7", "from_id": "u", "build": _cube(2), "kind": "gift", "at": 5},
		{"slot": 1, "from": "call me 555 1234", "from_id": "u", "build": _cube(2), "kind": "gift", "at": 5},
		{"slot": 2, "from": "Pip_7", "from_id": "u", "build": "junk", "kind": "gift", "at": 5},
		{"slot": "3", "from": "Pip_7", "from_id": "u", "build": _cube(2)},
		"x"], "mine": ["junk", 5, _cube(2)]})
	var clean := GiftStampBook.from_json(messy)
	assert_eq(clean.slots(), [0])
	assert_eq(clean.stamp(0).from, "Mia_2")
	assert_eq(clean.mine.size(), 1)
	assert_eq(GiftStampBook.from_json("not json").slots(), [])


func test_the_childs_own_shelf_keeps_the_last_eight_builds_once_each() -> void:
	var book := GiftStampBook.new()
	for i in 10:
		book.keep_mine(_cube(1, BlockIds.RED + (i % 5)))
	assert_eq(book.mine.size(), 5, "the same build is kept once")
	for n in range(1, 9):
		book.keep_mine(_cube(n % 8 + 1, BlockIds.BRICK))
	assert_eq(book.mine.size(), GiftStampBook.MINE_MAX)
	assert_eq(book.mine[book.mine.size() - 1], _cube(1, BlockIds.BRICK), "newest last")


func test_everything_from_one_player_goes_at_once() -> void:
	var book := GiftStampBook.new()
	book.add(_cube(1), "Mia_2", "uid-mia")
	book.add(_cube(1), "Pip_7", "uid-pip")
	book.add(_cube(2), "Mia_2", "uid-mia")
	assert_eq(book.remove_from("uid-mia"), 2)
	assert_eq(book.slots(), [1])
