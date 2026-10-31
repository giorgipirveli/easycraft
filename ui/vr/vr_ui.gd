class_name VrUi
extends Node
## VR on the Meta Quest (owner #101; docs/superpowers/plans/2026-10-15-vr-quest.md), the panel side: the VR canvas and
## what shows it. Made under Vr the first time Vr.ui_viewport() is asked while a session runs (UiLayers.route, the
## session's start), and gone when it ends (Vr.ended); off VR none of this exists.
##
## - **The canvas** (`viewport`, "VrCanvas"): a transparent 1280×720 SubViewport, the game's own canvas size, so every
##   screen lays out as on a phone. Every routed CanvasLayer is drawn there (UiLayers). It pauses with the game (a
##   layer keeps its owner's pause behaviour), draws nothing 3D, and is drawn only while the panel shows.
## - **PadFocus** moves in (the focus, the ring and the menus' pad all live in the canvas) and treats the controllers as
##   the pad (the touch HUD stays hidden, the laser never takes the pad away); it goes back where it was after.
## - **The root's keys and a connected pad's events** go on into the canvas (the forwarder: a desktop preview's keyboard
##   and game controller reach the panels). The headset's controllers come as VR-RIG's virtual pad, which pushes its
##   events into the canvas first itself (VrInput._send), so the forwarder leaves that device alone (never twice). The
##   root's mouse and fingers never go in (the laser is VrPointer's).
## - **The panel** (VrPanel) shows the canvas: EYE while a panel has the pad, the game is paused or a world loads, else
##   the TRAY with the HUD (VrPanelRules.place_for). **The pointer** (VrPointer) is the laser into it; a ring on the
##   canvas shows where it points. **The loading room** (VrLoadingRoom) surrounds the child while a world loads.
## - P2: **the readability pass** (VrReadability: no word under 24 px in the canvas, light words on buttons outlined),
##   **the keyboard** (VrKeyboard, for any focused text box; the eye panel while it shows), **the break card**
##   (VrBreakCard after VR COMFORT's Break minutes, `worn`), **the wrist and the toast strip** (VrWrist, while playing).
## - P3 with VR-RIG: **the rocket's dashboard** (FlightCockpit's bottom band on a quad at RocketFlight.vr_dashboard();
##   no tray while flying).

const CANVAS_NAME := &"VrCanvas"
## The laser's dot on the canvas: over every layer (PadFocus's ring is 126).
const CURSOR_LAYER := 127

static var instance: VrUi

var viewport := SubViewport.new()
var panel := VrPanel.new()
var pointer := VrPointer.new()
var room := VrLoadingRoom.new()
var cursor := Cursor.new()
## P2: the canvas's own keyboard for any focused text box (VrKeyboard).
var keyboard := VrKeyboard.new()
## P2: the break card (VrBreakCard) and the seconds spent in the headset this session.
var break_card := VrBreakCard.new()
var worn := 0.0
var _break_at := 0.0
## P3 (with VR-RIG): the rocket's dashboard, the cockpit's bottom band on a quad at RocketFlight.vr_dashboard().
var dashboard := MeshInstance3D.new()
## Its width in metres (its height follows the band's shape).
const DASHBOARD_WIDTH := 0.72
var _dash_cockpit: WeakRef = null   # the cockpit the flight below was found for
var _dash_flight: WeakRef = null
var _dash_search_at := 0
## P2: the hotbar, hearts and gold on the other wrist, and the toast strip over the gaze (VrWrist).
var wrist := VrWrist.new()

var _pad: PadFocus   # PadFocus while it lives in the canvas
var _pad_home: WeakRef   # where it lived before
var _to_lift: Array[WeakRef] = []   # controls that came into the canvas since the last frame (VrReadability)


## The canvas host under `host` (Vr): made once a session asks for it.
static func ensure(host: Node) -> VrUi:
	if instance != null and is_instance_valid(instance) and not instance.is_queued_for_deletion():
		return instance
	var ui := VrUi.new()
	instance = ui
	host.add_child(ui)
	return ui


## The laser is over a part of the canvas that takes it (Vr.ui_wants_pointer).
static func wants_pointer() -> bool:
	return instance != null and is_instance_valid(instance) and instance.pointer.wants_pointer()


func _init() -> void:
	name = "VrUi"
	process_mode = Node.PROCESS_MODE_ALWAYS   # the head and the panel never freeze with a paused game
	process_priority = -100   # before the world's own reading of the trigger (the rig asks Vr.ui_wants_pointer)
	viewport.name = CANVAS_NAME
	viewport.size = VrPanelRules.CANVAS
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.gui_disable_input = false
	viewport.process_mode = Node.PROCESS_MODE_PAUSABLE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var dot := CanvasLayer.new()
	dot.name = "VrCursorLayer"
	dot.layer = CURSOR_LAYER
	dot.process_mode = Node.PROCESS_MODE_ALWAYS
	dot.add_child(cursor)
	viewport.add_child(dot)
	var keys := CanvasLayer.new()
	keys.name = "VrKeyboardLayer"
	keys.layer = VrKeyboard.LAYER
	keys.process_mode = Node.PROCESS_MODE_ALWAYS   # typing in the pause menu's pages too
	keyboard.canvas = viewport
	keys.add_child(keyboard)
	viewport.add_child(keys)
	var rest := CanvasLayer.new()
	rest.name = "VrBreakLayer"
	rest.layer = VrBreakCard.LAYER
	rest.process_mode = Node.PROCESS_MODE_ALWAYS
	rest.add_child(break_card)
	viewport.add_child(rest)
	break_card.back.connect(func() -> void: _break_at = worn)
	add_child(panel)
	pointer.panel = panel
	pointer.canvas = viewport
	pointer.dash = dashboard
	add_child(pointer)
	room.head_source = panel.head
	add_child(room)
	_build_dashboard()
	wrist.head_source = panel.head
	add_child(wrist)


func _ready() -> void:
	panel.show_canvas(viewport.get_texture())
	wrist.texture = viewport.get_texture()
	if not Vr.ended.is_connected(_on_ended):
		Vr.ended.connect(_on_ended)
	UiLayers.move_all_in(viewport)
	_keep_pad_focus()
	TextSize.refresh(get_tree())   # BIG in a headset (TextSize.VR_KEY)
	VrReadability.lift_tree(viewport)
	get_tree().node_added.connect(_on_node_added)
	step(0.0)


func _process(delta: float) -> void:
	step(delta)


## One frame: PadFocus in the canvas, the panel's place, the laser, the loading room, the canvas drawn only when shown.
func step(delta: float) -> void:
	_keep_pad_focus()
	_lift_new()
	var loading := is_inside_tree() and get_tree().get_first_node_in_group(LoadingCard.GROUP) != null
	var paused := is_inside_tree() and get_tree().paused
	var was := panel.place
	keyboard.step()
	_count_worn(delta)
	paused = paused or break_card.visible
	var flying := _step_dashboard()
	var want := VrPanelRules.place_for(PadFocus.menu_has_pad() or keyboard.visible or break_card.visible, paused,
		loading)
	var playing := want == VrPanelRules.TRAY and not flying
	if want == VrPanelRules.TRAY and not VrEntry.previewing:   # owner #127: the HUD only on a raised forearm (a shield)
		var up := VrPanelRules.shield_up(panel.head(), panel.hand(), panel.place == VrPanelRules.SHIELD)
		want = VrPanelRules.SHIELD if up else VrPanelRules.HIDDEN
	panel.set_place(VrPanelRules.HIDDEN if flying and want != VrPanelRules.EYE else want)   # flying: the dashboard
	if panel.place != VrPanelRules.HIDDEN:
		pointer.dash_area = Rect2()   # a pause or a menu at the eye: only the panel is pressed
	_step_wrist(delta, playing and panel.place != VrPanelRules.SHIELD)
	if VrEntry.previewing and panel.place != was:   # --vr-preview: where the panel went, for the developer's log
		print("VR_PREVIEW place=%s layers=%d loading=%s paused=%s" % [panel.place, UiLayers.routed().size(), loading, paused])
	panel.step(delta)
	pointer.step()
	cursor.point(pointer.pixel if pointer.hovering else Vector2(-1, -1), pointer.holding)
	room.set_open(loading)
	room.step()
	var mode := SubViewport.UPDATE_ALWAYS if panel.visible else SubViewport.UPDATE_DISABLED
	if viewport.render_target_update_mode != mode:
		viewport.render_target_update_mode = mode


func _build_dashboard() -> void:
	dashboard.name = "VrDashboard"
	var quad := QuadMesh.new()
	quad.size = Vector2(DASHBOARD_WIDTH, DASHBOARD_WIDTH * FlightCockpit.DASH_REGION_H / VrPanelRules.CANVAS.x)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_PREMULT_ALPHA
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	m.disable_receive_shadows = true
	m.render_priority = 1   # inside VR-RIG's capsule (depth-tested like it), a screen set in its dashboard
	m.albedo_texture = viewport.get_texture()
	quad.material = m
	dashboard.mesh = quad
	dashboard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dashboard.layers = VrPanelRules.LAYERS
	dashboard.top_level = true
	dashboard.visible = false
	add_child(dashboard)


## The rocket's dashboard while a cockpit in its dashboard mode shows in the canvas: the cockpit's bottom band on the
## quad, at the flight's dashboard node (whatever offers vr_dashboard(): RocketFlight). True while it shows.
func _step_dashboard() -> bool:
	var cockpit := get_tree().get_first_node_in_group(FlightCockpit.GROUP) as FlightCockpit if is_inside_tree() else null
	var anchor: Node3D = null
	if cockpit != null and cockpit.dashboard_mode and cockpit.is_visible_in_tree() and cockpit.get_viewport() == viewport:
		var flight := _flight_of(cockpit)
		if flight != null:
			anchor = flight.call(&"vr_dashboard") as Node3D
	var show := anchor != null and is_instance_valid(anchor) and anchor.is_inside_tree()
	dashboard.visible = show
	pointer.dash_area = Rect2()
	if not show:
		return false
	dashboard.global_transform = anchor.global_transform
	var band := FlightCockpit.dashboard_rect(cockpit.size)
	band.position += cockpit.get_global_rect().position
	pointer.dash_band = band
	pointer.dash_area = cockpit.laser_area()   # owner #106's hint card: the one part of the dashboard the laser presses
	var m := (dashboard.mesh as QuadMesh).material as StandardMaterial3D
	var c := Vector2(VrPanelRules.CANVAS)
	m.uv1_offset = Vector3(band.position.x / c.x, band.position.y / c.y, 0.0)
	m.uv1_scale = Vector3(band.size.x / c.x, band.size.y / c.y, 1.0)
	return true


## The node that flies `cockpit` (the first one offering vr_dashboard(), looked for once per cockpit).
func _flight_of(cockpit: FlightCockpit) -> Node:
	if _dash_cockpit != null and _dash_cockpit.get_ref() == cockpit:
		var known := _dash_flight.get_ref() as Node if _dash_flight else null
		if known != null and known.is_inside_tree():
			return known
	if _dash_cockpit != null and _dash_cockpit.get_ref() == cockpit and Time.get_ticks_msec() < _dash_search_at:
		return null   # looked a moment ago and found none: once a second at most
	_dash_cockpit = weakref(cockpit)
	_dash_flight = null
	_dash_search_at = Time.get_ticks_msec() + 1000
	for n in get_tree().root.find_children("*", "Node3D", true, false):
		if n.has_method(&"vr_dashboard"):
			_dash_flight = weakref(n)
			return n
	return null


## The wrist strips and the toast strip while the child plays (the tray's time), from the HUD in the canvas.
## `playing`: the HUD is the child's (no menu in front): the strips ride on the wrist, unless the shield shows it all.
func _step_wrist(delta: float, playing: bool) -> void:
	var hud := get_tree().get_first_node_in_group(Hud.GROUP) as Control if is_inside_tree() else null
	var rects := {}
	if hud != null and hud.get_viewport() == viewport and hud.is_visible_in_tree() and hud.has_method(&"vr_rects"):
		rects = hud.call(&"vr_rects")
	wrist.step(delta, rects, playing)


## The time in the headset, and the break card when it is due (VrBreakCard.due; VR COMFORT's Break).
func _count_worn(delta: float) -> void:
	worn += delta
	if break_card.visible:
		return
	var minutes := int(VrComfortPage.value_of(Profile.data.settings, VrRules.BREAK_MINUTES)) if Profile.data else 0
	if VrBreakCard.due(worn, minutes, _break_at):
		break_card.open(minutes)


## A control came into the canvas: its words are lifted next frame (after its screen has sized them).
func _on_node_added(n: Node) -> void:
	if n is Control and viewport.is_ancestor_of(n):
		_to_lift.append(weakref(n))


func _lift_new() -> void:
	if _to_lift.is_empty():
		return
	for w in _to_lift:
		var c := w.get_ref() as Control
		if c != null and c.is_inside_tree():
			VrReadability.lift(c)
	_to_lift.clear()


## The root's keys and pad events on into the canvas (never its mouse or fingers: the laser is the canvas's pointer).
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and pointer.mouse_laser and pointer.hovering:
		get_viewport().set_input_as_handled()   # a preview's click on the panel is the panel's (no mouse capture)
		return
	if not forwards(event):
		return
	viewport.push_input(event)
	if viewport.is_input_handled():
		get_viewport().set_input_as_handled()


## The world's camera for a HUD control: its own viewport's off VR (as before); in VR the HUD is in the canvas, which
## has none: the headset's (Vr.camera), else the window's (a desktop preview).
static func world_camera(n: Node) -> Camera3D:
	if not Vr.active():
		return n.get_viewport().get_camera_3d()
	if Vr.camera != null and is_instance_valid(Vr.camera):
		return Vr.camera
	return n.get_tree().root.get_camera_3d()


## The events the root hands on to the canvas: keys and actions, and a connected pad's buttons and sticks (a game
## controller beside a desktop preview). A virtual pad's events (VR-RIG's VrInput: the headset's controllers, a device
## no joypad list has) are pushed into the canvas by VrInput itself before they reach the root: never twice.
static func forwards(event: InputEvent) -> bool:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return Input.get_connected_joypads().has(event.device)
	return event is InputEventKey or event is InputEventAction


func _keep_pad_focus() -> void:
	var p := PadFocus.instance
	if p == null or not is_instance_valid(p) or not p.is_inside_tree() or p.get_parent() == viewport:
		if p != null and is_instance_valid(p) and p.get_parent() == viewport:
			p.set_vr(true)
		return
	_pad = p
	_pad_home = weakref(p.get_parent())
	p.get_parent().remove_child(p)
	viewport.add_child(p)
	PadFocus.instance = p
	p.set_vr(true)


func _on_ended() -> void:
	if instance == self:
		instance = null
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)
	if PadFocus.keyboard == keyboard:
		PadFocus.keyboard = null
	VrReadability.restore_tree(viewport)   # every word at its own size again, before the layers go home
	UiLayers.move_all_out(viewport)
	if _pad != null and is_instance_valid(_pad) and _pad.get_parent() == viewport:
		viewport.remove_child(_pad)
		_pad.set_vr(false)
		var home := _pad_home.get_ref() as Node if _pad_home else null
		(home if home != null and home.is_inside_tree() else get_tree().root).add_child(_pad)
		PadFocus.instance = _pad
	if Vr.ended.is_connected(_on_ended):
		Vr.ended.disconnect(_on_ended)
	TextSize.refresh(get_tree())   # the flat screen's own text size again (Vr is no longer active when it ends)
	get_parent().remove_child(self)
	queue_free()


## The laser's dot on the canvas: a ring, filled while the trigger is held. Never takes a tap.
class Cursor:
	extends Control

	const RADIUS := 11.0
	var at := Vector2(-1, -1)
	var pressed := false

	func _init() -> void:
		name = "VrCursor"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func point(p: Vector2, down: bool) -> void:
		if p == at and down == pressed:
			return
		at = p
		pressed = down
		queue_redraw()

	func _draw() -> void:
		if at.x < 0.0:
			return
		draw_circle(at, RADIUS + 3.0, Color(0, 0, 0, 0.55))
		draw_circle(at, RADIUS, Color(1, 1, 1, 0.95) if pressed else Color(1, 1, 1, 0.35))
		draw_arc(at, RADIUS, 0.0, TAU, 32, Color.WHITE, 3.0, true)
