extends GutTest
## M3 Task 8: the building tools in the hand (BuildToolUser, a child of the BlockInteractor): LINE and FILL take two
## taps and build with the block held last; COPY copies a box and pastes it turned with the child (TURN, NEW
## COPY); paint paints (its mirror copy too); REWIND records this player's edits (tools and undos included) and
## opens the time-lapse; the wand offers Build-and-Wear for a small build and wakes a big one as before.

const ME_AT := Vector3(0.5, 10.0, 0.5)


## Stands in for the terrain: grass below y = 10, air above, plus `cells`; copies boxes like the real one.
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

	func copy_box(origin: Vector3i, size: Vector3i) -> VoxelBuffer:
		var buf := VoxelBuffer.new()
		buf.create(size.x, size.y, size.z)
		for x in size.x:
			for y in size.y:
				for z in size.z:
					buf.set_voxel(get_block(origin + Vector3i(x, y, z)), x, y, z, VoxelBuffer.CHANNEL_TYPE)
		return buf


var world: EditWorld
var me: Player
var interactor: BlockInteractor
var tools: BuildToolUser
var _said: Array = []
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	Session.tool_reset()
	world = EditWorld.new()
	add_child_autofree(world)
	Session.register_world(world)
	me = load("res://entities/player/player.tscn").instantiate()
	me.name = str(multiplayer.get_unique_id())
	me.world = world
	add_child_autofree(me)
	me.set_physics_process(false)
	me.global_position = ME_AT
	me._spawned = true
	interactor = me.get_node("BlockInteractor")
	tools = interactor.tools
	tools.said.connect(_on_said)
	Session.magic_feedback.connect(_on_said)
	_said.clear()


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_said)
	Game.mode = _mode_before
	Session.register_world(null)
	Session.survivor_reset()
	Session.tool_reset()


func _on_said(text: String) -> void:
	_said.append(text)


func _hold(id: int) -> void:
	interactor.set_slot_block(interactor.selected_slot, id)


func _count(id: int) -> int:
	var n := 0
	for c: Vector3i in world.cells:
		if world.cells[c] == id:
			n += 1
	return n

# --- LINE and FILL ---------------------------------------------------------------------------------------------

func test_a_line_of_the_block_held_last_in_two_taps() -> void:
	_hold(BlockIds.BRICK)
	_hold(ItemIds.LINE_TOOL)
	assert_eq(tools.held_block(), BlockIds.BRICK, "the block held last")
	assert_true(tools.tap(ItemIds.LINE_TOOL, Vector3i(2, 10, -2)))
	assert_eq(_count(BlockIds.BRICK), 0, "the first tap only marks an end")
	assert_has(_said, BuildToolUser.OTHER_END)
	assert_eq(tools.hint(), BuildToolUser.OTHER_END)
	assert_true(tools.tap(ItemIds.LINE_TOOL, Vector3i(6, 12, -2)))
	assert_eq(_count(BlockIds.BRICK), 7, "4 across and 2 up, face to face")
	assert_eq(world.get_block(Vector3i(6, 12, -2)), BlockIds.BRICK)
	assert_eq(interactor.undo_size(), 1)
	assert_true(interactor.undo())
	assert_eq(_count(BlockIds.BRICK), 0, "one undo takes the whole line")


func test_fill_builds_the_box_and_says_when_it_is_too_big() -> void:
	_hold(BlockIds.GLASS)
	_hold(ItemIds.FILL_TOOL)
	tools.tap(ItemIds.FILL_TOOL, Vector3i(3, 10, -3))
	tools.tap(ItemIds.FILL_TOOL, Vector3i(5, 12, -6))
	assert_eq(_count(BlockIds.GLASS), 36, "3 x 3 x 4")
	tools.tap(ItemIds.FILL_TOOL, Vector3i(-20, 10, -20))
	tools.tap(ItemIds.FILL_TOOL, Vector3i(20, 12, 20))
	assert_eq(_count(BlockIds.GLASS), 36, "nothing more")
	assert_has(_said, PowerTools.message(PowerTools.TOO_BIG))


## Before any block is held in this game (a saved world opened with a tool in the hand), the hotbar's first block.
func test_the_first_block_of_the_hotbar_until_one_is_held() -> void:
	interactor.hotbar[0] = ItemIds.LINE_TOOL
	interactor.hotbar[1] = BlockIds.GLASS
	tools.material = 0
	assert_eq(tools.held_block(), BlockIds.GLASS)
	_hold(BlockIds.PAINTED_RED)
	_hold(ItemIds.LINE_TOOL)
	assert_eq(tools.held_block(), BlockIds.PAINTED_RED)


func test_holding_something_else_forgets_the_first_tap() -> void:
	_hold(ItemIds.FILL_TOOL)
	tools.tap(ItemIds.FILL_TOOL, Vector3i(3, 10, -3))
	assert_ne(tools.first, BuildToolUser.NO_CELL)
	_hold(BlockIds.STONE)
	assert_eq(tools.first, BuildToolUser.NO_CELL)
	_hold(ItemIds.LINE_TOOL)
	tools.tap(ItemIds.LINE_TOOL, Vector3i(3, 10, -3))
	tools.cancel()
	assert_eq(tools.first, BuildToolUser.NO_CELL, "CANCEL")
	assert_eq(tools.hint(), "LINE: tap two spots")


func test_the_power_tools_say_sandbox_only_in_survivor() -> void:
	Game.mode = ModeRules.SURVIVOR
	Session.set_inventory(me.peer_id, Inventory.new())
	_hold(ItemIds.LINE_TOOL)
	var cam := me.camera()
	assert_not_null(cam)
	var before := _count(BlockIds.STONE)
	tools.tap(ItemIds.LINE_TOOL, Vector3i(2, 10, -2))
	tools.tap(ItemIds.LINE_TOOL, Vector3i(4, 10, -2))
	assert_eq(_count(BlockIds.STONE), before, "the host refuses it")
	assert_has(_said, Session.TOOLS_SANDBOX_ONLY)

# --- COPY ----------------------------------------------------------------------------------------------------

func test_copy_two_corners_then_paste_it_turned_with_you() -> void:
	world.cells[Vector3i(10, 10, -5)] = BlockIds.RED
	world.cells[Vector3i(11, 10, -5)] = BlockIds.BLUE
	world.cells[Vector3i(10, 11, -5)] = BlockIds.YELLOW
	_hold(ItemIds.COPY_TOOL)
	me.rig.yaw = 0.0   # looking north (-Z)
	tools.tap(ItemIds.COPY_TOOL, Vector3i(10, 10, -5))
	tools.tap(ItemIds.COPY_TOOL, Vector3i(11, 11, -5))
	assert_eq(tools.clipboard.size(), 3)
	assert_eq(tools.hint(), BuildToolUser.PASTE_HINT)
	assert_true(tools.paste(Vector3i(0, 10, -4)))
	assert_eq(_count(BlockIds.RED), 2)
	var red := Vector3i.ZERO
	for c: Vector3i in world.cells:
		if world.cells[c] == BlockIds.RED and c.x < 5:
			red = c
	assert_eq(world.get_block(red + Vector3i(1, 0, 0)), BlockIds.BLUE, "the same way round")
	assert_eq(world.get_block(red + Vector3i(0, 1, 0)), BlockIds.YELLOW)
	assert_eq(interactor.undo_size(), 1)
	tools.turn()
	assert_true(tools.paste(Vector3i(-6, 10, -6)))
	var red2 := Vector3i.ZERO
	for c: Vector3i in world.cells:
		if world.cells[c] == BlockIds.RED and c.x < -2:
			red2 = c
	assert_eq(world.get_block(red2 + Vector3i(0, 0, 1)), BlockIds.BLUE, "TURN: a quarter to the right")
	tools.new_copy()
	assert_eq(tools.clipboard, {})


func test_copy_is_capped_and_needs_blocks() -> void:
	_hold(ItemIds.COPY_TOOL)
	tools.tap(ItemIds.COPY_TOOL, Vector3i(0, 10, 0))
	tools.tap(ItemIds.COPY_TOOL, Vector3i(16, 10, 0))
	assert_has(_said, PowerTools.message(PowerTools.TOO_BIG_COPY))
	tools.tap(ItemIds.COPY_TOOL, Vector3i(0, 20, 0))
	tools.tap(ItemIds.COPY_TOOL, Vector3i(3, 22, 3))
	assert_has(_said, BuildToolUser.NOTHING_TO_COPY)
	assert_eq(tools.clipboard, {})

# --- Paint ---------------------------------------------------------------------------------------------------

func test_paint_and_its_mirror_copy() -> void:
	world.cells[Vector3i(3, 9, 0)] = BlockIds.STONE
	world.cells[Vector3i(-4, 9, 0)] = BlockIds.STONE
	interactor.mirror_enabled = true
	interactor.mirror_axis = MirrorRules.Axis.X
	interactor.mirror_plane = 0
	assert_true(tools.paint(Vector3i(3, 9, 0), ItemIds.PAINT_PURPLE))
	assert_eq(world.get_block(Vector3i(3, 9, 0)), BlockIds.PAINTED_PURPLE)
	assert_eq(world.get_block(MirrorRules.mirror(Vector3i(3, 9, 0), MirrorRules.Axis.X, 0)), BlockIds.PAINTED_PURPLE)
	world.cells[Vector3i(5, 10, 0)] = BlockIds.BED
	tools.paint(Vector3i(5, 10, 0), ItemIds.PAINT_PURPLE)
	assert_has(_said, "Beds can't be painted!")

# --- Build Rewind --------------------------------------------------------------------------------------------

func test_rewind_records_this_players_edits_undos_and_tools() -> void:
	assert_true(tools.rewind_at(Vector3i(0, 10, -3)))
	assert_true(tools.rewind.active)
	assert_has(_said, BuildToolUser.REWIND_STARTED)
	Session.request_set_block(Vector3i(1, 10, -3), BlockIds.PLANKS)
	Session.request_set_block(Vector3i(1, 11, -3), BlockIds.PLANKS)
	interactor.undo()
	world.cells[Vector3i(2, 9, -3)] = BlockIds.STONE
	tools.paint(Vector3i(2, 9, -3), ItemIds.PAINT_RED)
	Session.request_set_block(Vector3i(0, 10, 40), BlockIds.PLANKS)   # beyond 32 blocks of the spot
	assert_eq(tools.rewind.size(), 4)
	assert_eq(tools.rewind.edit(2), {"pos": Vector3i(1, 11, -3), "old": BlockIds.PLANKS, "new": BlockIds.AIR}, "the undo")
	assert_eq(tools.rewind.edit(3), {"pos": Vector3i(2, 9, -3), "old": BlockIds.STONE, "new": BlockIds.PAINTED_RED})
	watch_signals(tools)
	tools.rewind_at(Vector3i(0, 10, -3))
	assert_signal_emitted(tools, "rewind_requested", "a second tap opens the time-lapse")
	tools.restart_rewind()
	assert_false(tools.rewind.active)

# --- Build-and-Wear ------------------------------------------------------------------------------------------

func test_the_wand_offers_wear_for_a_small_build_only() -> void:
	world.cells[Vector3i(4, 10, -4)] = BlockIds.RED
	world.cells[Vector3i(4, 11, -4)] = BlockIds.PAINTED_PINK
	watch_signals(tools)
	assert_false(tools.offer_wear(Vector3i(4, 10, -4)), "no card in this game: the wand wakes it as before")
	tools.wear_enabled = true
	assert_true(tools.offer_wear(Vector3i(4, 10, -4)))
	assert_signal_emitted(tools, "wear_requested")
	for x in 6:
		world.cells[Vector3i(10 + x, 10, -4)] = BlockIds.BLUE
	assert_false(tools.offer_wear(Vector3i(10, 10, -4)), "6 long: the wand wakes a buddy")
	assert_false(tools.offer_wear(Vector3i(0, 9, 0)), "the ground is no build")


func test_wearing_a_build_turns_it_to_face_forward_and_saves_it_in_the_look() -> void:
	var profile := ProfileData.new()
	var picked := BuildPicker.pick(Vector3i(4, 10, -4), func(p: Vector3i) -> int:
		return {Vector3i(4, 10, -4): BlockIds.RED, Vector3i(5, 10, -4): BlockIds.BLUE}.get(p, BlockIds.AIR), 5, 125)
	var words := BuildToolUser.wear(profile, picked, WearRules.HAT, Vector3i(0, 0, -1))
	assert_eq(words, "You are wearing your build as a hat!")
	var blocks := WearRules.blocks_of(profile.avatar.builds[WearRules.HAT])
	assert_eq(blocks, {Vector3i(0, 0, 0): BlockIds.RED, Vector3i(1, 0, 0): BlockIds.BLUE}, "red on the child's left")
	BuildToolUser.wear(profile, picked, WearRules.WINGS, Vector3i(0, 0, 1))   # the child looked south at it
	assert_eq(WearRules.blocks_of(profile.avatar.builds[WearRules.WINGS]),
		{Vector3i(0, 0, 0): BlockIds.BLUE, Vector3i(1, 0, 0): BlockIds.RED}, "seen from the other side")
