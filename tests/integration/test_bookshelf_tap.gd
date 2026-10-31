extends GutTest
## M3 Task 21b: a tap on a BOOKSHELF within reach opens the books (the interactor's bookshelf_tapped; the sandbox
## opens the book on the memories), whatever is in the hand — no block is placed against it; a hold still breaks it.

const SHELF := Vector3i(2, 10, 0)
const ME_AT := Vector3(0.5, 10.0, 4.5)


## Stands in for the terrain: a dictionary of cells, all loaded.
class EditWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.GRASS if pos.y < 10 else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		var old := get_block(pos)
		if old == id:
			return
		cells[pos] = id
		block_changed.emit(pos, old, id)

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func surface_height(_x: int, _z: int) -> int:
		return 9


var world: EditWorld
var me: Player
var interactor: BlockInteractor
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	world = EditWorld.new()
	add_child_autofree(world)
	world.cells[SHELF] = BlockIds.BOOKSHELF
	Session.register_world(world)
	me = load("res://entities/player/player.tscn").instantiate()
	me.name = str(multiplayer.get_unique_id())
	me.world = world
	add_child_autofree(me)
	me.set_physics_process(false)
	me.global_position = ME_AT
	interactor = me.get_node("BlockInteractor")


func after_each() -> void:
	Game.mode = _mode_before
	Session.register_world(null)
	Session.survivor_reset()


func _look_at_shelf() -> Vector2:
	me.viewer.free()
	me.rig.process_mode = Node.PROCESS_MODE_DISABLED     # the test aims the camera
	me.camera().look_at_from_position(me.eye_position(), Vector3(SHELF) + Vector3(0.5, 0.5, 0.5))
	return interactor.get_viewport().get_visible_rect().size * 0.5


func test_a_tap_on_a_bookshelf_opens_the_books_whatever_is_in_the_hand() -> void:
	var center := _look_at_shelf()
	var got: Array[Vector3i] = []
	interactor.bookshelf_tapped.connect(func(cell: Vector3i) -> void: got.append(cell))
	for item in [BlockIds.PLANKS, ItemIds.SWORD, ItemIds.WAND]:
		interactor.hotbar[0] = item
		interactor.select_slot(0)
		assert_true(interactor.place_at_screen(center), ItemIds.display_name(item))
	assert_eq(got, [SHELF, SHELF, SHELF] as Array[Vector3i])
	assert_eq(world.cells.values().count(BlockIds.PLANKS), 0, "no plank was placed against it")
	assert_eq(world.get_block(SHELF), BlockIds.BOOKSHELF)


func test_holding_a_finger_on_a_bookshelf_still_breaks_it() -> void:
	var center := _look_at_shelf()
	assert_true(interactor.break_at_screen(center))
	assert_eq(world.get_block(SHELF), BlockIds.AIR)


func test_other_blocks_are_built_on_as_before() -> void:
	world.cells[SHELF] = BlockIds.STONE
	var center := _look_at_shelf()
	var got: Array[Vector3i] = []
	interactor.bookshelf_tapped.connect(func(cell: Vector3i) -> void: got.append(cell))
	interactor.hotbar[0] = BlockIds.PLANKS
	interactor.select_slot(0)
	assert_true(interactor.place_at_screen(center))
	assert_eq(got, [] as Array[Vector3i])
	assert_eq(world.cells.values().count(BlockIds.PLANKS), 1, "a plank against the stone")
