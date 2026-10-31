extends GutTest
## Owner #101 (VR on the Meta Quest), the panel side: the pointing hand's laser into the VR canvas (VrPointer). Over the
## panel the canvas gets the mouse's moves at that pixel and the trigger clicks as a mouse button and a finger, so menu
## Buttons and the HUD's TouchButtons both answer. On the eye panel the laser is always the panel's; on the tray only
## over something pressable (the HUD's empty canvas lets it through to the world). A squeeze that began on the panel
## stays the panel's until it lets go, released where the laser left (nothing sticks). A ring shows where it points.

const HEAD := Transform3D(Basis(), Vector3(0, 1.6, 0))

var ui: VrUi
var trigger := [false]
var aim := [Vector2(-1, -1)]   # the canvas pixel the hand points at (-1: away)
var _old_pad: PadFocus


class Owner:
	extends Node


func before_each() -> void:
	_old_pad = PadFocus.instance
	PadFocus.instance = null
	Vr.simulate(true)
	Vr.ui_viewport()
	ui = VrUi.instance
	ui.set_process(false)   # the test steps it
	ui.panel.head_source = func() -> Transform3D: return HEAD
	ui.pointer.trigger_source = func() -> bool: return trigger[0]
	ui.pointer.ray_source = _ray
	trigger[0] = false
	aim[0] = Vector2(-1, -1)


func after_each() -> void:
	ui.panel.hand_source = Callable()
	Vr.simulate(false)
	PadFocus.instance = _old_pad


## A ray from the right hand's spot to the panel's pixel aim[0] (none when aim is off the canvas).
func _ray() -> Array:
	if aim[0].x < 0.0:
		return [Vector3(0.25, 1.2, -0.2), Vector3.UP]
	var uv: Vector2 = aim[0] / Vector2(VrPanelRules.CANVAS)
	var p := ui.panel.global_transform * Vector3((uv.x - 0.5) * ui.panel.size.x, (0.5 - uv.y) * ui.panel.size.y, 0.0)
	var from := Vector3(0.25, 1.2, -0.2)
	return [from, (p - from).normalized()]


func _layer_with(c: Control) -> CanvasLayer:
	var o := Owner.new()
	add_child_autofree(o)
	var layer := CanvasLayer.new()
	layer.add_child(c)
	UiLayers.route(layer, o)
	return layer


func _button(rect: Rect2) -> Button:
	var b := Button.new()
	b.text = "OK"
	b.position = rect.position
	b.size = rect.size
	_layer_with(b)
	return b


func _frame() -> void:
	ui.step(1.0 / 60.0)


func test_the_laser_clicks_a_menu_button_on_the_eye_panel() -> void:
	ui.panel.set_place(VrPanelRules.EYE)
	var b := _button(Rect2(500, 300, 280, 120))
	var presses := [0]
	b.pressed.connect(func() -> void: presses[0] += 1)
	await get_tree().process_frame
	ui.panel.set_place(VrPanelRules.HIDDEN)   # placed for the head now (the menu stands in front)
	ui.panel.set_place(VrPanelRules.EYE)
	aim[0] = Vector2(640, 360)
	ui.pointer.step()
	assert_true(ui.pointer.hovering)
	assert_almost_eq(ui.pointer.pixel, Vector2(640, 360), Vector2(1.5, 1.5), "the canvas pixel under the laser")
	assert_almost_eq(ui.pointer.distance, 1.45, 0.3, "the laser stops at the panel")
	assert_true(Vr.ui_wants_pointer(), "on the eye panel the world waits")
	trigger[0] = true
	ui.pointer.step()
	trigger[0] = false
	ui.pointer.step()
	assert_eq(presses[0], 1, "squeeze and let go: one press")


func test_on_the_tray_only_pressable_things_take_the_laser() -> void:
	var b := _button(Rect2(560, 600, 160, 100))   # the HUD's hotbar spot
	await get_tree().process_frame
	ui.panel.set_place(VrPanelRules.TRAY)
	aim[0] = Vector2(640, 200)   # the HUD's empty middle
	ui.pointer.step()
	assert_true(ui.pointer.hovering)
	assert_false(Vr.ui_wants_pointer(), "the empty canvas lets the laser through to the world")
	trigger[0] = true
	ui.pointer.step()
	assert_false(Vr.ui_wants_pointer(), "a squeeze there is the world's (TAP / HOLD)")
	trigger[0] = false
	ui.pointer.step()
	aim[0] = Vector2(640, 650)
	ui.pointer.step()
	assert_true(Vr.ui_wants_pointer(), "over a button the world waits")
	assert_true(b.is_hovered(), "the button lights up under the laser")


func test_a_hud_touch_button_answers_the_trigger() -> void:
	var t := TouchButton.new()
	t.text = "JUMP"
	t.position = Vector2(1100, 560)
	t.size = Vector2(120, 120)
	var presses := [0]
	t.pressed.connect(func() -> void: presses[0] += 1)
	_layer_with(t)
	await get_tree().process_frame
	ui.panel.set_place(VrPanelRules.TRAY)
	aim[0] = Vector2(1160, 620)
	ui.pointer.step()
	trigger[0] = true
	ui.pointer.step()
	assert_eq(presses[0], 1, "a finger at that pixel")
	assert_true(t.is_down())
	assert_true(Vr.ui_wants_pointer(), "the button took the squeeze: the world waits")
	trigger[0] = false
	ui.pointer.step()
	assert_false(t.is_down(), "let go")


func test_a_squeeze_let_go_off_the_panel_lets_go_where_it_left() -> void:
	ui.panel.set_place(VrPanelRules.EYE)
	var b := _button(Rect2(500, 300, 280, 120))
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	await get_tree().process_frame
	aim[0] = Vector2(640, 360)
	ui.pointer.step()
	trigger[0] = true
	ui.pointer.step()
	assert_true(b.button_pressed or b.is_pressed() or ui.pointer.holding)
	aim[0] = Vector2(-1, -1)   # the hand swings away, still squeezing
	ui.pointer.step()
	assert_true(Vr.ui_wants_pointer(), "still the panel's: the world never gets half a squeeze")
	trigger[0] = false
	ui.pointer.step()
	assert_false(ui.pointer.holding)
	assert_false(Vr.ui_wants_pointer())
	assert_false(b.is_pressed(), "nothing stays pressed")


func test_a_beam_reaches_the_panel_while_the_panel_has_the_laser() -> void:
	ui.panel.set_place(VrPanelRules.EYE)
	aim[0] = Vector2(640, 360)
	ui.pointer.step()
	var beam := ui.pointer.beam
	assert_true(beam.visible, "on the eye panel: the panel's beam (the rig's world laser hides)")
	var from: Vector3 = _ray()[0]
	var end := beam.global_transform * Vector3(0, 0, -0.5)
	var hit := ui.panel.global_transform * Vector3.ZERO
	assert_almost_eq(beam.global_transform * Vector3(0, 0, 0.5), from, Vector3.ONE * 0.01, "from the hand")
	assert_almost_eq(end, hit, Vector3.ONE * 0.01, "to the panel")
	ui.panel.set_place(VrPanelRules.TRAY)
	aim[0] = Vector2(640, 200)   # the HUD's empty middle: the world's laser, not the panel's
	ui.pointer.step()
	assert_false(beam.visible)


func test_the_ring_shows_where_the_laser_points() -> void:
	# owner #127: playing, the HUD shows on the raised forearm: the ring is on that panel
	ui.panel.hand_source = func() -> Transform3D: return Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-0.05, 1.4, -0.35))
	ui.panel.set_place(VrPanelRules.EYE)
	aim[0] = Vector2(320, 180)
	_frame()
	assert_almost_eq(ui.cursor.at, Vector2(320, 180), Vector2(1.5, 1.5))
	aim[0] = Vector2(-1, -1)
	_frame()
	assert_eq(ui.cursor.at, Vector2(-1, -1), "away from the panel: no ring")


func test_the_panel_draws_over_everything_and_the_loading_room_over_a_black_fade() -> void:
	ui.panel.set_place(VrPanelRules.EYE)
	var panel_mat := (ui.panel.mesh as QuadMesh).material as StandardMaterial3D
	assert_eq(panel_mat.render_priority, Material.RENDER_PRIORITY_MAX, "a menu shows in VR-RIG's fade (its sphere: 100)")
	assert_true(panel_mat.no_depth_test, "a wall nearer than the panel never hides a menu")
	var sky := ui.room.get_node("Sky") as MeshInstance3D
	var sky_mat := (sky.mesh as SphereMesh).material as StandardMaterial3D
	assert_between(sky_mat.render_priority, 101, Material.RENDER_PRIORITY_MAX - 1, "over a fade, under the panel")
	for n: GeometryInstance3D in [ui.panel, ui.pointer.beam, sky]:
		assert_true(n.layers & RocketFlight.LAYER != 0, "%s shows in a flight's space too (the head draws its layers)" % n.name)
		assert_true(n.layers & 1 != 0, "%s shows in the world" % n.name)


func test_the_panel_stands_where_the_place_rules_say() -> void:
	ui.panel.set_place(VrPanelRules.HIDDEN)
	ui.panel.set_place(VrPanelRules.EYE)
	assert_true(ui.panel.visible)
	assert_almost_eq(ui.panel.global_transform.origin, VrPanelRules.eye_transform(HEAD).origin, Vector3.ONE * 0.001)
	ui.panel.set_place(VrPanelRules.TRAY)
	assert_almost_eq(ui.panel.global_transform.origin, VrPanelRules.tray_transform(HEAD.origin, 0.0).origin,
		Vector3.ONE * 0.001)
	assert_eq(ui.panel.size, VrPanelRules.TRAY_SIZE)
