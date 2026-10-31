extends GutTest
## Owner #116 (2026-10-16 15:04: "using vr it should be possible to build a house for example like in real world, take
## brick or stones and put in apropriate place"), VR-HANDS (docs/devlog/parts/vr-r4-hands.md): hand building in the world
## with fake hands (Vr.simulate) on a real Player and the host's own edits. Take a block with the grip (over the shoulder
## from the bag, from the wrist hotbar, or out of a wall), carry it as a brick, a life-size ghost on the cell it goes in,
## let go and it is placed (the laser's place request: one undo, Survivor's bag), a wall row by row, the brick back to
## the bag in the air; Survivor's drop; nothing off VR.

const ME_AT := Vector3(0.5, 10.0, 0.5)
const DT := 1.0 / 72.0


## Grass below y = 10, air above, plus `cells`.
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


var world: EditWorld
var p: Player
var interactor: BlockInteractor
var _mode_before: StringName
var _settings := {}


func before_each() -> void:
	_settings = Profile.data.settings.duplicate()
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	world = EditWorld.new()
	add_child_autofree(world)
	Session.register_world(world)
	p = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = world
	add_child_autofree(p)
	p.set_physics_process(false)
	p.set_process_unhandled_input(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = ME_AT
	interactor = p.get_node("BlockInteractor") as BlockInteractor
	interactor.set_process_unhandled_input(false)
	interactor.hotbar[0] = BlockIds.STONE
	interactor.select_slot(0)
	Vr.simulate(true)
	Vr.anchor(p, &"feet")
	_frame()


func after_each() -> void:
	Vr.simulate(false)
	Vr.anchor(null)
	Input.flush_buffered_events()
	Game.mode = _mode_before
	Session.register_world(null)
	Session.survivor_reset()
	Profile.data.settings.clear()
	Profile.data.settings.merge(_settings)


func _frame(delta: float = DT) -> void:
	Vr.step_physics()
	Vr.step(delta)
	Input.flush_buffered_events()
	p.rig._process(delta)
	p._process(delta)


## The right hand (palm along -Z) with its brick's middle at `world_at`.
func _brick_at(world_at: Vector3) -> void:
	var grip_world := world_at + Vr.rig.global_basis * Vector3(0, 0, VrBrickRules.AHEAD)
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vr.rig.global_transform.affine_inverse() * grip_world))
	_frame()


func _hand_local_at(world_at: Vector3) -> void:
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vr.rig.global_transform.affine_inverse() * world_at))
	_frame()


func _grip(value: float) -> void:
	Vr.sim_input(VrRules.RIGHT, &"grip", value)
	_frame()


func _over_the_shoulder() -> void:
	var head := Vr.rig.global_transform.affine_inverse() * Vr.head_transform()
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), head.origin + head.basis * Vector3(0.15, 0.05, 0.15)))
	_frame()


func _take_from_the_bag() -> void:
	_over_the_shoulder()
	_grip(1.0)


func test_over_the_shoulder_the_grip_takes_the_selected_block_as_a_brick() -> void:
	_take_from_the_bag()
	assert_eq(Vr.bricks.held(VrRules.RIGHT), BlockIds.STONE, "a stone brick in the hand")
	assert_false(Input.is_action_pressed(&"hotbar_next"), "the grip took a brick, not the hotbar's step")
	var brick := Vr.bricks.brick_node(VrRules.RIGHT)
	assert_true(brick != null and brick.visible, "it shows in the hand")
	assert_almost_eq(brick.scale.x, VrBrickRules.BRICK, 0.0001, "brick-sized: 12 cm")
	assert_true(Vr.hand_busy(VrRules.RIGHT), "the hand is building: its trigger is not the laser's")


func test_the_ghost_shows_the_cell_and_letting_go_places_it_with_one_undo() -> void:
	_take_from_the_bag()
	var cell := Vector3i(0, 10, -1)   # on the grass in front of the feet
	_brick_at(Vector3(0.5, 10.3, -0.5))
	assert_eq(Vr.bricks.ghost_cell(VrRules.RIGHT), cell, "the cell next to the brick, on the ground")
	var ghost := Vr.bricks.ghost_node(VrRules.RIGHT)
	assert_true(ghost.visible, "a life-size see-through ghost")
	assert_almost_eq(ghost.global_position, Vector3(cell) + Vector3(0.5, 0.5, 0.5), Vector3.ONE * 0.001)
	var buzzes := Vr.haptics
	_grip(0.0)
	assert_eq(world.get_block(cell), BlockIds.STONE, "placed through the host")
	assert_eq(interactor.undo_size(), 1, "the laser's own undo")
	assert_gt(Vr.haptics, buzzes, "a soft click in the hand")
	assert_eq(Vr.bricks.held(VrRules.RIGHT), 0, "the hand is empty again")
	assert_false(ghost.visible)


func test_a_brick_let_go_in_the_air_goes_back_to_the_bag() -> void:
	_take_from_the_bag()
	_brick_at(Vector3(0.5, 11.6, -1.5))
	assert_eq(Vr.bricks.ghost_cell(VrRules.RIGHT), VrBrickRules.NO_CELL, "touching nothing")
	_grip(0.0)
	assert_eq(world.cells.size(), 0, "nothing placed")
	assert_eq(Vr.bricks.held(VrRules.RIGHT), 0)


func test_a_wall_goes_up_row_by_row() -> void:
	for y in [10, 11]:
		_take_from_the_bag()
		_brick_at(Vector3(1.5, float(y) + 0.3, -0.5))
		assert_eq(Vr.bricks.ghost_cell(VrRules.RIGHT), Vector3i(1, y, -1), "row %d on the one below" % (y - 9))
		_grip(0.0)
	assert_eq(world.get_block(Vector3i(1, 11, -1)), BlockIds.STONE, "two rows")


func test_the_grip_takes_a_block_out_of_a_wall_and_it_can_go_back_in_elsewhere() -> void:
	var wall := Vector3i(1, 10, -1)
	world.cells[wall] = BlockIds.BRICK
	_hand_local_at(Vector3(1.5, 10.5, 0.03))   # the palm 3 cm from the wall's face
	_grip(1.0)
	assert_eq(world.get_block(wall), BlockIds.AIR, "out of the wall (the host's break)")
	assert_eq(Vr.bricks.held(VrRules.RIGHT), BlockIds.BRICK, "the brick in the hand")
	_brick_at(Vector3(-0.5, 10.3, -0.5))
	_grip(0.0)
	assert_eq(world.get_block(Vector3i(-1, 10, -1)), BlockIds.BRICK, "laid somewhere else")


func test_a_brick_just_laid_comes_back_out_with_the_grip() -> void:
	_take_from_the_bag()
	_brick_at(Vector3(0.5, 10.3, -0.5))
	_grip(0.0)
	var cell := Vector3i(0, 10, -1)
	assert_eq(world.get_block(cell), BlockIds.STONE, "laid")
	_hand_local_at(Vector3(0.5, 10.5, -0.5))   # the hand in it
	_grip(1.0)
	assert_eq(world.get_block(cell), BlockIds.AIR, "taken back out")
	assert_eq(Vr.bricks.held(VrRules.RIGHT), BlockIds.STONE, "in the hand again")
	_grip(0.0)


func test_in_survivor_the_hand_holds_the_blocks_drop_and_laying_it_uses_one_from_the_bag() -> void:
	Game.mode = ModeRules.SURVIVOR
	var inv := Inventory.new()
	Session.set_inventory(p.peer_id, inv)
	var wall := Vector3i(1, 10, -1)
	world.cells[wall] = BlockIds.GRASS
	_hand_local_at(Vector3(1.5, 10.5, -0.5))   # the hand in the block
	_grip(1.0)
	var drop := GatherRules.drop(BlockIds.GRASS, GatherRules.pickaxe_tier(inv))
	assert_eq(Vr.bricks.held(VrRules.RIGHT), drop, "Survivor's drop of a grass block")
	assert_eq(inv.count(drop), 1, "the host gave it to the bag")
	_brick_at(Vector3(-0.5, 10.3, -0.5))
	_grip(0.0)
	assert_eq(world.get_block(Vector3i(-1, 10, -1)), drop)
	assert_eq(inv.count(drop), 0, "laying it used it")


func test_with_nothing_to_take_the_grip_still_steps_the_hotbar() -> void:
	_hand_local_at(Vector3(0.7, 11.3, -0.4))
	_grip(1.0)
	assert_true(Input.is_action_pressed(&"hotbar_next"), "in the air, nothing near: as before")
	assert_eq(Vr.bricks.held(VrRules.RIGHT), 0)


func test_a_tool_in_the_slot_opens_the_bag_instead() -> void:
	interactor.hotbar[0] = ItemIds.SWORD
	interactor.select_slot(0)
	_take_from_the_bag()
	assert_eq(Vr.bricks.held(VrRules.RIGHT), 0, "a sword is no brick")
	assert_eq(Vr.bricks.bag_opened, 1, "the bag (BLOCKS) opens")


func test_off_vr_there_are_no_bricks() -> void:
	Vr.simulate(false)
	assert_null(Vr.bricks)
	assert_true(interactor.place_block(Vector3i(0, 10, -1), BlockIds.STONE), "the laser's place, as before")
	assert_eq(world.get_block(Vector3i(0, 10, -1)), BlockIds.STONE)
