extends GutTest
## My Stamps in the game (M3 Task 20b, spec §14.21): the palette's STAMPS page (the child's stamps, each with its
## picture; NEW STAMP; the small x deletes after SURE?), the bar that picks a build (BuildPicker under a tap, the
## glow, SAVE STAMP; too big says so) and placing one: every block in one edit, so ONE undo takes it all away.

const NEAR := Vector3i(2, 10, -2)
const ME_AT := Vector3(0.5, 10.0, 4.5)


class EditWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		var old := get_block(pos)
		if old == id:
			return
		cells[pos] = id
		block_changed.emit(pos, old, id)

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func surface_height(_x: int, _z: int) -> int:
		return 0


var world: EditWorld
var _saved: MyStampBook
var book: MyStampBook


func before_each() -> void:
	world = EditWorld.new()
	add_child_autofree(world)
	Session.register_world(world)
	_saved = MyStampBook.current()
	book = MyStampBook.new()
	MyStampBook.use(book, "user://test_my_stamps_%d.json" % OS.get_process_id())


func after_each() -> void:
	Session.register_world(null)
	MyStampBook.use(_saved)
	DirAccess.remove_absolute("user://test_my_stamps_%d.json" % OS.get_process_id())


func after_all() -> void:
	Audio.stop_all()


func _player() -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = world
	add_child_autofree(p)
	p.global_position = ME_AT
	return p


func _tower(at: Vector3i, h: int, id := BlockIds.BRICK) -> Dictionary:
	var b := {}
	for y in h:
		b[at + Vector3i(0, y, 0)] = id
		b[at + Vector3i(1, y, 0)] = id
	return b


# --- Placing ---

func test_a_stamp_of_mine_is_placed_whole_and_one_undo_takes_it_away() -> void:
	book.add(_tower(Vector3i(50, 0, 50), 3))
	var p := _player()
	var interactor: BlockInteractor = p.get_node("BlockInteractor")
	var item := MyStampBook.item_of(0)
	interactor.set_slot_block(0, item)
	assert_true(interactor._stamp(item, NEAR))
	var built := world.cells.values().filter(func(id: int) -> bool: return id == BlockIds.BRICK).size()
	assert_eq(built, 6, "every block of the stamp")
	assert_eq(interactor.undo_size(), 1, "one undo step")
	assert_true(interactor.undo())
	assert_eq(world.cells.values().filter(func(id: int) -> bool: return id == BlockIds.BRICK).size(), 0,
		"one undo takes it all away")


# --- The palette's STAMPS page ---

func _palette() -> BlockPalette:
	var p := BlockPalette.new()
	add_child_autofree(p)
	return p


func test_the_stamps_page_lists_my_stamps_with_their_pictures() -> void:
	book.add(_tower(Vector3i.ZERO, 2))
	book.add(_tower(Vector3i.ZERO, 4, BlockIds.GLASS))
	var p := _palette()
	assert_eq(p.tab_bar.get_tab_title(BlockPalette.STAMPS_TAB), "STAMPS")
	p.open()
	p.show_page(BlockPalette.STAMPS_TAB)
	assert_eq(p.stamps_grid.get_child_count(), 2)
	var first := p.stamps_grid.get_child(0)
	var pick := first.find_child("Pick", true, false) as Button
	assert_eq(pick.tooltip_text, "My Stamp 1")
	var pic := first.find_child("Picture", true, false) as BuildPicture
	assert_not_null(pic, "its own picture")
	assert_true(pic.cells.has(BlockIds.BRICK))
	watch_signals(p)
	pick.pressed.emit()
	assert_signal_emitted_with_parameters(p, "picked", [MyStampBook.item_of(0)])


func test_new_stamp_asks_the_world_for_a_build() -> void:
	var p := _palette()
	p.open()
	p.show_page(BlockPalette.STAMPS_TAB)
	assert_true(p.stamps_hint.visible, "no stamps yet: how to make one")
	watch_signals(p)
	p.new_stamp_button.pressed.emit()
	assert_signal_emitted(p, "new_stamp_requested")
	assert_false(p.visible, "the palette closes: the world is tapped next")


func test_the_small_x_asks_then_deletes() -> void:
	book.add(_tower(Vector3i.ZERO, 2))
	var p := _palette()
	p.open()
	var x := p.stamps_grid.get_child(0).find_child("Delete", true, false) as Button
	x.pressed.emit()
	assert_eq(x.text, "SURE?")
	assert_eq(book.slots(), [0] as Array[int])
	x.pressed.emit()
	assert_eq(book.slots(), [] as Array[int])
	assert_eq(p.stamps_grid.get_child_count(), 0)


func test_the_tabs_show_stamps_in_both_modes() -> void:
	var p := _palette()
	p.counted = true
	p.open()
	assert_false(p.tab_bar.is_tab_hidden(BlockPalette.STAMPS_TAB), "Survivor: stamps are paid with their blocks")
	p.counted = false
	p.open()
	assert_false(p.tab_bar.is_tab_hidden(BlockPalette.STAMPS_TAB))


# --- The picking bar ---

func _bar(p: Player) -> MyStampBar:
	var bar := MyStampBar.new()
	bar.interactor = p.get_node("BlockInteractor")
	bar.world = world
	bar.outline = BuildOutline.new()
	add_child_autofree(bar.outline)
	bar.facing = func() -> Vector3i: return Vector3i(0, 0, -1)
	add_child_autofree(bar)
	return bar


func test_the_bar_picks_a_build_and_saves_it_as_a_stamp() -> void:
	var p := _player()
	var bar := _bar(p)
	var toasts: Array = []
	bar.toast = func(t: String) -> void: toasts.append(t)
	bar.open()
	assert_true(bar.interactor.tap_override.is_valid(), "the next tap on the world picks")
	for c: Vector3i in _tower(NEAR, 3):
		world.cells[c] = BlockIds.BRICK
	assert_true(bar.pick_cell(NEAR))
	assert_eq(bar.step, MyStampBar.PICKED)
	assert_eq((bar.picked.blocks as Dictionary).size(), 6)
	bar.save_button.pressed.emit()
	assert_eq(book.slots(), [0] as Array[int], "saved")
	assert_eq(book.blocks_of(0).size(), 6)
	assert_true(FileAccess.file_exists("user://test_my_stamps_%d.json" % OS.get_process_id()), "kept on this device")
	assert_false(bar.visible)
	assert_false(bar.interactor.tap_override.is_valid(), "the world's taps are its own again")
	assert_string_contains(toasts[-1], "My Stamp 1")
	assert_eq(world.cells.size(), 6, "the build stays in the world")


func test_a_too_big_build_is_refused_with_words() -> void:
	var p := _player()
	var bar := _bar(p)
	bar.open()
	for x in 20:
		world.cells[NEAR + Vector3i(x, 0, 0)] = BlockIds.BRICK
	bar.pick_cell(NEAR)
	assert_eq(bar.step, MyStampBar.PICK, "still picking")
	assert_ne(bar.message.text, "")
	bar.pick_cell(Vector3i(99, 99, 99))
	assert_eq(bar.message.text, BuildPicker.message("not_a_build"))
	bar.close()
	assert_false(bar.interactor.tap_override.is_valid())
