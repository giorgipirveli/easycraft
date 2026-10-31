extends GutTest
## Owner #110 (VR-HANDS, the research's task 0, Vivecraft's touch hotbar) with owner #116's bricks: the hotbar on the
## other wrist (VrWrist's strip of the HUD's own hotbar) is touchable. The pointing hand's index finger on a slot picks
## it; its grip there takes that slot's block into the hand as a brick. With a real HUD in the VR canvas.

class FloorWorld:
	extends WorldService

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < 80 else BlockIds.AIR


class Owner:
	extends Node


const DT := 1.0 / 72.0

var p: Player
var interactor: BlockInteractor
var hud: Hud
var ui: VrUi
var _old_pad: PadFocus
var _settings := {}


func before_each() -> void:
	_settings = Profile.data.settings.duplicate()
	_old_pad = PadFocus.instance
	PadFocus.instance = null
	var w := FloorWorld.new()
	autofree(w)
	p = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.set_process_unhandled_input(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3(0.5, 80, 0.5)
	interactor = p.get_node("BlockInteractor") as BlockInteractor
	interactor.set_process_unhandled_input(false)
	interactor.hotbar[3] = BlockIds.BRICK
	interactor.hotbar[5] = BlockIds.GLASS
	Vr.simulate(true)
	Vr.anchor(p, &"feet")
	Vr.ui_viewport()
	ui = VrUi.instance
	ui.set_process(false)
	var o := Owner.new()
	add_child_autofree(o)
	var layer := CanvasLayer.new()
	hud = Hud.new()
	layer.add_child(hud)
	UiLayers.route(layer, o)
	hud.setup(p, "Kid", false, false)
	hud.hotbar.notification(Container.NOTIFICATION_SORT_CHILDREN)   # the row laid out now (a game frame does it)
	# the off hand (left) held up in front, palm down; the pointing hand resting
	Vr.sim_hand(VrRules.LEFT, Transform3D(Basis(), Vector3(-0.15, 1.15, -0.35)))
	_frame()
	_frame()


func after_each() -> void:
	Vr.simulate(false)
	Vr.anchor(null)
	PadFocus.instance = _old_pad
	Input.flush_buffered_events()
	Profile.data.settings.clear()
	Profile.data.settings.merge(_settings)


func _frame() -> void:
	Vr.step_physics()
	Vr.step(DT)
	ui.step(DT)
	Input.flush_buffered_events()
	p.rig._process(DT)
	p._process(DT)


## The world point of hotbar slot `i` on the wrist strip.
func _slot_point(i: int) -> Vector3:
	var strip := ui.wrist.part(&"hotbar")
	var size := (strip.mesh as QuadMesh).size
	var m := (strip.mesh as QuadMesh).material as StandardMaterial3D
	var c := Vector2(VrPanelRules.CANVAS)
	var origin := Vector2(m.uv1_offset.x, m.uv1_offset.y) * c
	var span := Vector2(m.uv1_scale.x, m.uv1_scale.y) * c
	var px := (hud.hotbar.get_child(i) as Control).get_global_rect().get_center()
	var u := (px - origin) / span
	return strip.global_transform * Vector3((u.x - 0.5) * size.x, (0.5 - u.y) * size.y, 0.0)


## The pointing hand placed so that `point(model)` is at `at` (world).
func _right_so_that(at: Vector3, fingertip: bool) -> void:
	var model := Vr.hand_models[VrRules.RIGHT] as VrHandModel
	var off := model.global_transform.affine_inverse() * (model.fingertip() if fingertip else model.global_position)
	var grip_world := at - Vr.rig.global_basis * off
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vr.rig.global_transform.affine_inverse() * grip_world))
	_frame()


func test_the_hotbar_rides_on_the_other_wrist() -> void:
	assert_true(ui.wrist.part(&"hotbar").visible, "the strip is there to touch")
	for i in 10:
		assert_eq(Vr.bricks.wrist_slot(_slot_point(i), 0.02), i, "slot %d found where it shows" % i)


func test_the_index_finger_on_a_wrist_slot_picks_it() -> void:
	assert_eq(interactor.selected_slot, 0)
	_right_so_that(_slot_point(5), true)
	assert_eq(interactor.selected_slot, 5, "touched: slot 6 picked")
	var buzzes := Vr.haptics
	_frame()
	assert_eq(Vr.haptics, buzzes, "once a touch, not every frame")


func test_the_grip_on_a_wrist_slot_takes_its_block_as_a_brick() -> void:
	_right_so_that(_slot_point(3), false)
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	_frame()
	assert_eq(interactor.selected_slot, 3)
	assert_eq(Vr.bricks.held(VrRules.RIGHT), BlockIds.BRICK, "a brick from the wrist")


func test_far_from_the_wrist_nothing_is_touched() -> void:
	_right_so_that(_slot_point(5) + Vector3(0.0, 0.0, 0.2), true)
	assert_eq(interactor.selected_slot, 0)
