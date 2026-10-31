extends GutTest
## Owner #110, VR round 4 idea 5 (VR-HANDS; docs/devlog/parts/vr-r4-hands.md): the Build Table with fake hands
## (Vr.simulate) on a real Player and the host's own edits. MORE has BUILD TABLE and MODEL VIEW only in a headset; a
## block is placed on the table with the trigger where the hand is, and a hold breaks one; a block stands on the table
## or on another; two hands on the rim turn the build, one lifts the table within hand height; the buttons are poked;
## SAVE STAMP puts it in My Stamps; WAKE IT builds it in front of the child and asks the wand; the School's board is the
## table in VR (its check reads the table's cells); nothing off VR.

const ME_AT := Vector3(0.5, 10.0, 0.5)
const DT := 1.0 / 72.0


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


class Owner:
	extends Node


var world: EditWorld
var p: Player
var interactor: BlockInteractor
var _mode_before: StringName
var _settings := {}
var _old_pad: PadFocus
var _book_path := ""


func before_each() -> void:
	_settings = Profile.data.settings.duplicate()
	_old_pad = PadFocus.instance
	PadFocus.instance = null
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	_book_path = "user://test_vr_r4_table_%d.json" % OS.get_process_id()
	MyStampBook.use(MyStampBook.new(), _book_path)
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
	PadFocus.instance = _old_pad
	Input.flush_buffered_events()
	Game.mode = _mode_before
	Session.register_world(null)
	MyStampBook.use(null)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_book_path))
	Profile.data.settings.clear()
	Profile.data.settings.merge(_settings)


func _frame() -> void:
	Vr.step_physics()
	Vr.step(DT)
	Input.flush_buffered_events()
	p.rig._process(DT)
	p._process(DT)


func _table() -> VrBuildTable:
	Vr.open_build_table()
	_frame()
	return Vr.build_table


## The pointing hand placed so its building point is at `local` (the table's space).
func _build_at(t: VrBuildTable, local: Vector3) -> void:
	var at := t.global_transform * local
	var grip := at - Vr.rig.global_basis * Vector3(0, 0, -VrBuildTable.REACH_AHEAD)
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vr.rig.global_transform.affine_inverse() * grip))
	_frame()


func _hand_at(side: StringName, world_at: Vector3) -> void:
	Vr.sim_hand(side, Transform3D(Basis(), Vr.rig.global_transform.affine_inverse() * world_at))


func _tap() -> void:
	Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0)
	_frame()
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)
	_frame()


func _cell_middle(c: Vector3i) -> Vector3:
	return (Vector3(c) + Vector3(0.5, 0.5, 0.5)) * BuildTableRules.CELL


func test_more_has_build_table_and_model_view_only_in_a_headset() -> void:
	var o := Owner.new()
	add_child_autofree(o)
	var layer := CanvasLayer.new()
	var hud := Hud.new()
	layer.add_child(hud)
	UiLayers.route(layer, o)
	hud.setup(p, "Kid", false, false)
	for i in 40:
		_frame()
	var names := []
	for b: TouchButton in hud.more.buttons():
		names.append(b.text)
	assert_has(names, "BUILD TABLE", "owner #110: MORE → BUILD TABLE in VR")
	assert_has(names, "MODEL VIEW", "and MODEL VIEW (the Sandbox)")
	Vr.simulate(false)
	await get_tree().process_frame
	names.clear()
	for b: TouchButton in hud.more.buttons():
		names.append(b.text)
	assert_does_not_have(names, "BUILD TABLE", "off VR the MORE panel is as before")


func test_the_table_opens_at_hand_height_in_front_of_the_child() -> void:
	var t := _table()
	assert_not_null(t)
	var eye := Vr.head_transform().origin
	assert_almost_eq(t.global_position.y, eye.y - BuildTableRules.BELOW, 0.01, "at hand height")
	var near_edge := t.global_transform * Vector3(BuildTableRules.SIDE * BuildTableRules.CELL * 0.5, 0, BuildTableRules.SIDE * BuildTableRules.CELL)
	var flat := Vector2(near_edge.x - eye.x, near_edge.z - eye.z).length()
	assert_almost_eq(flat, BuildTableRules.AHEAD, 0.05, "its near edge just ahead")


func test_a_tap_places_the_selected_block_where_the_hand_is() -> void:
	var t := _table()
	_build_at(t, _cell_middle(Vector3i(5, 0, 10)))
	assert_eq(t.ghost, Vector3i(5, 0, 10), "the ghost snaps to the cell")
	assert_true(Vr.hand_busy(VrRules.RIGHT), "the laser is off: the hand builds at the table")
	var buzzes := Vr.haptics
	_tap()
	assert_eq(t.cells.get(Vector3i(5, 0, 10)), BlockIds.STONE, "placed with the trigger")
	assert_gt(Vr.haptics, buzzes, "a click in the hand")
	assert_eq(world.cells.size(), 0, "the world is untouched")


func test_a_block_stands_on_the_table_or_on_another() -> void:
	var t := _table()
	_build_at(t, _cell_middle(Vector3i(5, 3, 10)))
	assert_eq(t.ghost, BuildTableRules.NO_CELL, "in the air: nowhere")
	t.cells[Vector3i(5, 2, 10)] = BlockIds.STONE
	_frame()
	assert_eq(t.ghost, Vector3i(5, 3, 10), "on top of another: fine")


func test_a_hold_on_a_table_block_breaks_it() -> void:
	var t := _table()
	t.cells[Vector3i(3, 0, 12)] = BlockIds.STONE
	t.rebuild()
	_build_at(t, _cell_middle(Vector3i(3, 0, 12)))
	assert_eq(t.touched_cell, Vector3i(3, 0, 12))
	Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0)
	for i in 30:
		_frame()
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)
	_frame()
	assert_false(t.cells.has(Vector3i(3, 0, 12)), "held: it broke")


func test_two_hands_on_the_rim_turn_the_build_a_quarter() -> void:
	var t := _table()
	t.cells = {Vector3i(0, 0, 0): BlockIds.STONE}
	var w := BuildTableRules.SIDE * BuildTableRules.CELL
	var mid := Vector3(w * 0.5, 0.0, w * 0.5)
	var r := w * 0.5 + 0.02
	_hand_at(VrRules.LEFT, t.global_transform * (mid + Vector3(-r, 0, 0)))
	_hand_at(VrRules.RIGHT, t.global_transform * (mid + Vector3(r, 0, 0)))
	_frame()
	Vr.sim_input(VrRules.LEFT, &"grip", 1.0)
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	_frame()
	var a := deg_to_rad(60.0)   # counter-clockwise seen from above
	_hand_at(VrRules.LEFT, t.global_transform * (mid + Vector3(-r * cos(a), 0, r * sin(a))))
	_hand_at(VrRules.RIGHT, t.global_transform * (mid + Vector3(r * cos(a), 0, -r * sin(a))))
	_frame()
	assert_true(t.cells.has(Vector3i(0, 0, 15)), "turned a quarter with the hands: the far-left block to the near-left")
	Vr.sim_input(VrRules.LEFT, &"grip", 0.0)
	Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)
	_frame()


func test_one_hand_on_the_rim_lifts_the_table_but_never_above_hand_height() -> void:
	var t := _table()
	var start := t.global_transform * Vector3(-0.02, 0.0, 0.8)
	_hand_at(VrRules.LEFT, start)
	_frame()
	Vr.sim_input(VrRules.LEFT, &"grip", 1.0)
	_frame()
	_hand_at(VrRules.LEFT, start + Vector3(0.1, 0.1, 0.0))
	_frame()
	assert_almost_eq(t.global_position.y, Vr.head_transform().origin.y - BuildTableRules.BELOW + 0.1, 0.01, "lifted")
	_hand_at(VrRules.LEFT, start + Vector3(0.0, 2.0, 0.0))
	_frame()
	assert_almost_eq(t.global_position.y, Vr.head_transform().origin.y - BuildTableRules.HEIGHT_MIN, 0.01,
		"never above the hands' height")
	Vr.sim_input(VrRules.LEFT, &"grip", 0.0)
	_frame()


func test_save_stamp_puts_the_build_in_my_stamps() -> void:
	var t := _table()
	t.cells = {Vector3i(4, 0, 8): BlockIds.STONE, Vector3i(5, 0, 8): BlockIds.GLASS}
	t.press(&"save")
	assert_eq(MyStampBook.current().slots().size(), 1, "a stamp of the child's own")
	assert_eq(MyStampBook.current().blocks_of(MyStampBook.current().slots()[0]).size(), 2)


func test_wake_it_builds_it_in_front_of_the_child_and_asks_the_wand() -> void:
	var t := _table()
	t.cells = {Vector3i(4, 0, 8): BlockIds.STONE, Vector3i(4, 1, 8): BlockIds.STONE}
	var sparks := []
	var heard := func(_peer: int, at: Vector3i) -> void: sparks.append(at)
	Session.spark_requested.connect(heard)
	t.press(&"wake")
	Session.spark_requested.disconnect(heard)
	var forward := Blueprints.facing_for_yaw(p.rig.yaw)
	var anchor := Vector3i(p.global_position.floor()) + forward * VrBuildTable.WAKE_AHEAD
	assert_eq(world.get_block(anchor), BlockIds.STONE, "the build stands in front of the child")
	assert_eq(world.get_block(anchor + Vector3i.UP), BlockIds.STONE)
	assert_eq(sparks.size(), 1, "the wand asked to wake it")
	assert_true(t.cells.is_empty(), "off the table: it walks in the world now")


func test_poking_a_button_with_the_fingertip_presses_it() -> void:
	var t := _table()
	t.cells = {Vector3i(1, 0, 1): BlockIds.STONE}
	var model := Vr.hand_models[VrRules.RIGHT] as VrHandModel
	var off := model.global_transform.affine_inverse() * model.fingertip()
	var target := t.global_transform * (t.button_at(&"clear") + Vector3(0, VrBuildTable.BUTTON_SIZE.y * 0.5, 0))
	var grip := target - Vr.rig.global_basis * off
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vr.rig.global_transform.affine_inverse() * grip))
	_frame()
	assert_eq(int(t.presses.get(&"clear", 0)), 1, "poked: CLEAR")
	assert_true(t.cells.is_empty())
	_frame()
	assert_eq(int(t.presses.get(&"clear", 0)), 1, "once a poke")


func test_the_schools_board_is_the_table_in_vr() -> void:
	Vr.ui_viewport()
	var o := Owner.new()
	add_child_autofree(o)
	var layer := CanvasLayer.new()
	var b := BuildBoard.new({"board": {"cols": 4, "rows": 3, "block": BlockIds.STONE, "view": "wall", "given": [[0, 0]]},
		"goal": {"kind": "count", "n": 3}})
	layer.add_child(b)
	UiLayers.route(layer, o)
	await get_tree().process_frame
	_frame()
	var t := Vr.build_table
	assert_not_null(t, "the board came: the table is it")
	assert_eq(t.board, b)
	assert_eq(t.size, Vector3i(4, 3, 1), "a wall: four across, three up")
	assert_true(t.cells.has(Vector3i(0, 0, 0)), "its given block")
	_build_at(t, _cell_middle(Vector3i(1, 0, 0)))
	_tap()
	_build_at(t, _cell_middle(Vector3i(2, 0, 0)))
	_tap()
	assert_eq(b.cells().size(), 3, "the board has what the table has")
	assert_true(BuildCheck.check(b.goal, b.board, b.cells()), "its check reads them, unchanged")
	layer.queue_free()
	await get_tree().process_frame
	_frame()
	assert_null(Vr.build_table, "the round over: the table goes")


func test_off_vr_there_is_no_table() -> void:
	Vr.simulate(false)
	Vr.open_build_table()
	assert_null(Vr.build_table)
