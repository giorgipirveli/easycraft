class_name VrPointer
extends Node
## VR on the Meta Quest (owner #101), the panel side: the pointing hand's laser into the VR canvas. Each frame the hand's
## ray (Vr.hand_ray of the pointing hand: the right one, the left for a left-handed child) is met with the panel
## (VrPanel.hit); over it, the canvas gets the mouse's moves at that pixel (buttons light up), and the trigger is the
## click: a mouse button and a finger (index 0), as a desktop's mouse is (emulate_touch_from_mouse), so Buttons and the
## HUD's TouchButtons both answer. A squeeze that began on the panel is the panel's until the trigger lets go (a drag on
## a slider, a release off the panel), and the world waits meanwhile: Vr.ui_wants_pointer().
##
## The trigger is read from the hand's XRControllerTracker through the XR server, as VR-RIG's VrInput reads it, so this
## side needs nothing of the rig's nodes. In a desktop preview (--vr-preview) with the mouse free, the mouse is the laser
## and its left button the trigger.

## A squeeze from TRIGGER_ON, let go under TRIGGER_OFF (VrRules.TRIGGER_ON / TRIGGER_OFF in VR-RIG's body).
const TRIGGER_ON := 0.6
const TRIGGER_OFF := 0.35

var panel: VrPanel
var canvas: SubViewport
## () -> Array: [origin, direction] in world space, or [] (default: the pointing hand's ray, a preview's mouse).
var ray_source := Callable()
## () -> bool: the trigger is squeezed (default: the pointing hand's trigger, a preview's left mouse button).
var trigger_source := Callable()

## The ray is over the panel now.
var hovering := false
## The canvas pixel under the ray (valid while hovering).
var pixel := Vector2(-1, -1)
## How far the panel is along the ray (metres; -1 when not hovering): the laser stops there.
var distance := -1.0
## A squeeze that began on the panel is held.
var holding := false
## The laser is a desktop preview's mouse this frame (VrUi keeps that click from the world).
var mouse_laser := false

## Owner #101 with #106: the rocket's dashboard (VrUi's quad) as a second surface, pressed only over `dash_area` (canvas
## pixels: the descent's hint card); everywhere else the dashboard stays a display (ruling 22). VrUi sets all three.
var dash: MeshInstance3D
## The canvas band the dashboard's quad shows (canvas pixels).
var dash_band := Rect2()
## The part of that band the laser may press now (empty: none).
var dash_area := Rect2()
## The laser is on the dashboard's pressable part now (not the panel).
var on_dash := false

## The beam from the hand to the panel, while the panel has the laser (VR-RIG's world laser, VrHand, hides then).
var beam := MeshInstance3D.new()

var _down := false
var _pressed_in := false   # the squeeze's press went into the canvas (its release follows it there)
var _last := Vector2(-1, -1)


## The beam's thickness (m) and its render priority: over the world and VR-RIG's fade, under the panel it ends on.
const BEAM_WIDTH := 0.006
const BEAM_PRIORITY := 126


func _init() -> void:
	name = "VrPointer"
	process_mode = Node.PROCESS_MODE_ALWAYS   # the pause menu is pointed at while the game is paused
	var box := BoxMesh.new()
	box.size = Vector3(BEAM_WIDTH, BEAM_WIDTH, 1.0)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true
	m.render_priority = BEAM_PRIORITY
	m.albedo_color = Color(1, 1, 1, 0.7)
	box.material = m
	beam.mesh = box
	beam.name = "VrBeam"
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.layers = VrPanelRules.LAYERS
	beam.visible = false
	add_child(beam)


## One frame: the ray, the moves and the clicks into the canvas.
func step() -> void:
	if panel == null or canvas == null:
		return
	var ray: Array = ray_source.call() if ray_source.is_valid() else _default_ray()
	var at := VrPanelRules.MISS
	on_dash = false
	if ray.size() == 2:
		var dir := (ray[1] as Vector3).normalized()
		at = panel.hit(ray[0], dir)
		if at.x < 0.0:
			at = _dash_hit(ray[0], dir)
			on_dash = at.x >= 0.0
	hovering = at.x >= 0.0
	distance = at.z if hovering else -1.0
	_place_beam(ray)
	if hovering:
		pixel = Vector2(at.x, at.y) if on_dash else VrPanelRules.pixel(Vector2(at.x, at.y), canvas.size)
		if pixel != _last:
			_move(pixel)
	var down: bool = trigger_source.call() if trigger_source.is_valid() else _default_trigger()
	if down and not _down and hovering:
		_pressed_in = true
		var took := _click(true, pixel)
		holding = took or panel.place == VrPanelRules.EYE or on_dash or over_control()
	elif not down and _down and _pressed_in:
		_pressed_in = false
		holding = false
		_click(false, pixel if hovering else _last)
	_down = down


## The laser is over a part of the canvas that takes it (the world waits): always on the eye panel; on the tray only over
## a control that stops the mouse (the HUD's empty canvas lets the laser through to the world); and while a squeeze the
## canvas took is held (a press a TouchButton or a Button handled; any press on the eye panel).
func wants_pointer() -> bool:
	if holding:
		return true
	if not hovering:
		return false
	return panel.place == VrPanelRules.EYE or on_dash or over_control()


## The laser on the dashboard's pressable part: Vector3(canvas x, canvas y, metres along the ray), or MISS.
func _dash_hit(from: Vector3, dir: Vector3) -> Vector3:
	if dash == null or not dash.visible or not dash.is_inside_tree() or not dash_area.has_area():
		return VrPanelRules.MISS
	var uv := VrPanelRules.hit(dash.global_transform, (dash.mesh as QuadMesh).size, from, dir)
	if uv.x < 0.0:
		return VrPanelRules.MISS
	var p := (dash_band.position + Vector2(uv.x, uv.y) * dash_band.size).round()
	return Vector3(p.x, p.y, uv.z) if dash_area.has_point(p) else VrPanelRules.MISS


## The beam from the hand to where it meets the panel, while the panel has the laser.
func _place_beam(ray: Array) -> void:
	var show := hovering and wants_pointer() and beam.is_inside_tree()
	beam.visible = show
	if not show:
		return
	var from: Vector3 = ray[0]
	var dir := (ray[1] as Vector3).normalized()
	var up := Vector3.UP if absf(dir.y) < 0.99 else Vector3.BACK
	beam.global_transform = Transform3D(Basis.looking_at(dir, up).scaled_local(Vector3(1, 1, distance)),
		from + dir * distance * 0.5)


## A control that stops the mouse is under the laser (a Button, a slider, a box). The HUD's TouchButtons pass the mouse
## through: a press on one is the canvas's because the button handles it (step).
func over_control() -> bool:
	var c := canvas.gui_get_hovered_control()
	return c != null and c.mouse_filter == Control.MOUSE_FILTER_STOP


func _move(at: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = at
	m.global_position = at
	m.relative = at - _last if _last.x >= 0.0 else Vector2.ZERO
	m.button_mask = MOUSE_BUTTON_MASK_LEFT if holding else 0
	canvas.push_input(m, true)
	if holding:
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.position = at
		d.relative = m.relative
		canvas.push_input(d, true)
	_last = at


## Pushes a click (a mouse button and a finger); true when the canvas handled it.
func _click(pressed: bool, at: Vector2) -> bool:
	var b := InputEventMouseButton.new()
	b.button_index = MOUSE_BUTTON_LEFT
	b.pressed = pressed
	b.position = at
	b.global_position = at
	b.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	canvas.push_input(b, true)
	var took := canvas.is_input_handled()
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = pressed
	t.position = at
	canvas.push_input(t, true)
	return took or canvas.is_input_handled()


func _hand() -> StringName:
	var left := Profile.data != null and bool(Profile.data.settings.get("left_handed", false))
	return VrRules.pointing_hand(left)


func _default_ray() -> Array:
	mouse_laser = false
	if _mouse_is_laser():
		var vp := panel.get_viewport()
		var at := vp.get_mouse_position()
		var cam := vp.get_camera_3d()
		mouse_laser = true
		return [cam.project_ray_origin(at), cam.project_ray_normal(at)]
	if Vr.has_method(&"hand_busy") and bool(Vr.call(&"hand_busy", _hand())):
		return []   # owner #110: the hand holds, pulls or builds: its trigger is that thing's, not a panel's
	return Vr.hand_ray(_hand())


## A desktop preview (--vr-preview: VrEntry.previewing) with the mouse free (a captured mouse turns the head): the mouse
## is the laser. Never in a headset, never in the tests' sessions.
func _mouse_is_laser() -> bool:
	if not VrEntry.previewing or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or not panel.is_inside_tree():
		return false
	return panel.get_viewport().get_camera_3d() != null


## The pointing hand's trigger is squeezed: the lead's frozen API, `Vr.trigger_pressed(side)` (VR-RIG's round 3:
## VrRules.trigger_down's hysteresis), once it is there; until then `Vr.trigger(side)` (0..1) with the same rule here
## (squeezed from TRIGGER_ON, let go under TRIGGER_OFF), so the panel and the world never disagree about a squeeze. A
## preview's free mouse: its left button.
func _default_trigger() -> bool:
	var mouse := mouse_laser and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if Vr.has_method(&"trigger_pressed"):
		return bool(Vr.call(&"trigger_pressed", _hand())) or mouse
	var value := float(Vr.call(&"trigger", _hand())) if Vr.has_method(&"trigger") else _tracker_trigger()
	var down := value > TRIGGER_OFF if _down else value >= TRIGGER_ON
	return down or mouse


## The trigger straight from the hand's tracker (before VR-RIG's Vr.trigger): "trigger", else "trigger_click".
func _tracker_trigger() -> float:
	var tracker := XRServer.get_tracker(&"left_hand" if _hand() == VrRules.LEFT else &"right_hand") as XRPositionalTracker
	if tracker == null:
		return 0.0
	for input_name: StringName in [&"trigger", &"trigger_click"]:
		var v: Variant = tracker.get_input(input_name)
		if v is bool:
			return 1.0 if v else 0.0
		if v is float or v is int:
			return float(v)
	return 0.0
