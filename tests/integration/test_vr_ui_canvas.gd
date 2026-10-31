extends GutTest
## Owner #101 (VR on the Meta Quest), the panel side: in a headset the root's 2D canvas is not shown, so every
## CanvasLayer of the game's UI goes through UiLayers.route into one VR canvas (Vr.ui_viewport(): a transparent 1280×720
## SubViewport under Vr, shown on the world-space panel). Off VR nothing is made and a layer is its owner's child as
## before. A layer routed before the headset starts (the WebXR route: ENTER VR in the menu) moves in when it starts and
## back to its owner when it ends; a routed layer goes with its owner; it keeps its owner's pause behaviour. PadFocus
## lives in the canvas while VR runs (its focus is the canvas's), and the root's keys and pad events reach it.

var pad: PadFocus
var _old_pad: PadFocus


class Owner:
	extends Node


func before_each() -> void:
	_old_pad = PadFocus.instance
	pad = PadFocus.new()
	add_child_autofree(pad)


func after_each() -> void:
	Vr.simulate(false)
	PadFocus.instance = _old_pad


func _owner(mode := Node.PROCESS_MODE_INHERIT) -> Node:
	var o := Owner.new()
	o.process_mode = mode
	add_child_autofree(o)
	return o


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func test_off_vr_nothing_is_made() -> void:
	var o := _owner()
	var layer := CanvasLayer.new()
	UiLayers.route(layer, o)
	assert_eq(layer.get_parent(), o)
	assert_null(Vr.ui_viewport())
	assert_null(Vr.get_node_or_null("VrUi"), "no canvas, no panel, no pointer off VR")
	assert_false(Vr.ui_wants_pointer())


func test_in_vr_the_canvas_is_one_transparent_1280_by_720_viewport() -> void:
	Vr.simulate(true)
	var vp := Vr.ui_viewport()
	assert_not_null(vp)
	if vp == null:
		return
	assert_eq(vp.size, Vector2i(1280, 720), "the game's canvas size: every screen fits as on a phone")
	assert_true(vp.transparent_bg, "the tray shows only the HUD")
	assert_true(vp.disable_3d, "nothing 3D is drawn twice")
	assert_eq(Vr.ui_viewport(), vp, "one canvas for the whole session")
	assert_true(vp.is_inside_tree())
	assert_eq(vp.process_mode, Node.PROCESS_MODE_PAUSABLE, "a paused game pauses its HUD in VR too")


func test_a_routed_layer_goes_into_the_canvas_and_with_its_owner() -> void:
	Vr.simulate(true)
	var o := _owner()
	var layer := CanvasLayer.new()
	var label := Label.new()
	layer.add_child(label)
	UiLayers.route(layer, o)
	assert_eq(layer.get_parent(), Vr.ui_viewport(), "drawn on the panel")
	assert_eq(label.get_viewport(), Vr.ui_viewport(), "its controls are the canvas's")
	o.free()
	await _frames(1)
	assert_false(is_instance_valid(layer), "freed when its owner leaves the tree")


func test_a_layer_routed_before_the_headset_moves_in_and_back() -> void:
	var o := _owner()
	var layer := CanvasLayer.new()
	UiLayers.route(layer, o)
	Vr.simulate(true)
	assert_eq(layer.get_parent(), Vr.ui_viewport(), "ENTER VR in the menu: the menu's layer moves to the panel")
	Vr.simulate(false)
	assert_eq(layer.get_parent(), o, "the headset is off: back where it was")
	assert_null(Vr.ui_viewport())


func test_a_layer_keeps_its_owners_pause_behaviour() -> void:
	var always := _owner(Node.PROCESS_MODE_ALWAYS)   # an autoload's toast (Music, Session)
	var toast := CanvasLayer.new()
	UiLayers.route(toast, always)
	var world := _owner(Node.PROCESS_MODE_PAUSABLE)   # a world scene (the sandbox)
	var hud := CanvasLayer.new()
	UiLayers.route(hud, world)
	Vr.simulate(true)
	assert_eq(toast.process_mode, Node.PROCESS_MODE_ALWAYS, "runs while paused, as under its autoload")
	assert_eq(hud.process_mode, Node.PROCESS_MODE_INHERIT, "pauses with the canvas, as with its world")
	Vr.simulate(false)
	assert_eq(toast.process_mode, Node.PROCESS_MODE_INHERIT, "back as it was")


func test_pad_focus_lives_in_the_canvas_while_vr_runs() -> void:
	var home := pad.get_parent()
	Vr.simulate(true)
	await _frames(1)
	assert_eq(pad.get_viewport(), Vr.ui_viewport(), "the focus and the ring are the canvas's")
	assert_eq(PadFocus.instance, pad)
	assert_true(pad.pad, "in VR the controllers are the pad: the touch HUD stays hidden")
	pad.set_pad_name("Xbox Wireless Controller")   # a synthetic joypad's name never changes the headset's words
	assert_eq(PadFocus.current_family(), PadFocus.vr_family(), "the CONTROLLER card speaks of the headset's controllers")
	var m := InputEventMouseMotion.new()
	m.position = Vector2(10, 10)
	Vr.ui_viewport().push_input(m, true)
	assert_true(pad.pad, "the laser's mouse never takes the pad away")
	Vr.simulate(false)
	assert_eq(PadFocus.current_family(), GamepadRules.XBOX, "off VR the pad's own words again")
	assert_eq(pad.get_parent(), home, "back where it was")
	assert_eq(PadFocus.instance, pad)


func test_the_roots_pad_and_keys_reach_the_canvas() -> void:
	Vr.simulate(true)
	var o := _owner()
	var layer := CanvasLayer.new()
	var v := VBoxContainer.new()
	v.position = Vector2(100, 100)
	var pressed := []
	for t: String in ["SANDBOX", "SURVIVOR"]:
		var b := Button.new()
		b.name = t
		b.text = t
		b.custom_minimum_size = Vector2(240, 90)
		b.pressed.connect(func() -> void: pressed.append(t))
		v.add_child(b)
	layer.add_child(v)
	UiLayers.route(layer, o)
	PadFocus.watch(v)
	await _frames(3)
	assert_true(PadFocus.menu_has_pad(), "the panel in the canvas has the pad")
	assert_eq(Vr.ui_viewport().gui_get_focus_owner(), v.get_node("SANDBOX"), "the first big button")
	_joy(JOY_BUTTON_DPAD_DOWN)
	assert_eq(Vr.ui_viewport().gui_get_focus_owner(), v.get_node("SURVIVOR"), "the controllers' D-pad moves it")
	_joy(JOY_BUTTON_A)
	assert_eq(pressed, ["SURVIVOR"], "Cross / A presses it once (the root never hands a virtual pad's event in again)")
	var k := InputEventKey.new()
	k.keycode = KEY_ENTER
	k.physical_keycode = KEY_ENTER
	k.pressed = true
	get_tree().root.push_input(k)
	var up := k.duplicate() as InputEventKey
	up.pressed = false
	get_tree().root.push_input(up)
	assert_eq(pressed.size(), 2, "a key (a desktop preview's keyboard) too")


func test_mouse_and_touch_from_the_root_never_reach_the_canvas() -> void:
	# The world's own pointer (a PC's mouse, a finger in the browser) is not the laser: only VrPointer pushes those.
	Vr.simulate(true)
	var o := _owner()
	var layer := CanvasLayer.new()
	var b := Button.new()
	b.position = Vector2(0, 0)
	b.size = Vector2(1280, 720)
	var presses := [0]
	b.pressed.connect(func() -> void: presses[0] += 1)
	layer.add_child(b)
	UiLayers.route(layer, o)
	await _frames(1)
	var m := InputEventMouseButton.new()
	m.button_index = MOUSE_BUTTON_LEFT
	m.position = Vector2(640, 360)
	m.pressed = true
	get_tree().root.push_input(m)
	var r := m.duplicate() as InputEventMouseButton
	r.pressed = false
	get_tree().root.push_input(r)
	assert_eq(presses[0], 0)


## The headset's controllers as VR-RIG's VrInput sends them (VrInput._send): a virtual pad (a device no joypad list
## has) into the canvas first, then to the game (the root) unless the canvas took a press.
func _joy(button: JoyButton) -> void:
	for down: bool in [true, false]:
		var e := InputEventJoypadButton.new()
		e.device = 12
		e.button_index = button
		e.pressed = down
		var vp := Vr.ui_viewport()
		vp.push_input(e)
		if not (down and vp.is_input_handled()):
			get_tree().root.push_input(e)


func test_a_connected_pad_from_the_root_reaches_the_canvas_and_a_virtual_one_does_not() -> void:
	var real := InputEventJoypadButton.new()
	real.device = 0
	var virtual := InputEventJoypadButton.new()
	virtual.device = 12
	var key := InputEventKey.new()
	var mouse := InputEventMouseButton.new()
	assert_true(VrUi.forwards(key), "keys: a desktop preview's keyboard")
	assert_false(VrUi.forwards(mouse), "the root's mouse is never the laser")
	assert_false(VrUi.forwards(virtual), "the headset's virtual pad pushes into the canvas itself")
	assert_eq(VrUi.forwards(real), Input.get_connected_joypads().has(0), "a game controller plugged in")
