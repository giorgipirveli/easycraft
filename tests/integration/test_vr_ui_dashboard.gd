extends GutTest
## Owner #101 (VR on the Meta Quest, P3 with VR-RIG): in a headset the rocket's cockpit is a dashboard in the capsule.
## FlightCockpit's dashboard mode keeps its screens, hologram, lever, ACTION and the trip's words in the canvas's bottom
## band (no 2D hull, aim ring or flashes: the capsule's window and the head's fade are VR-RIG's), and VrUi shows that
## band on a quad at the flight's dashboard (RocketFlight.vr_dashboard(): RocketFlight/VrSeat/VrCapsule/Dashboard, +Z
## to the child), on the flight's layer so the head sees it in space. While it flies the tray goes (the HUD is the
## flight's); a pause still comes to the eye. Off VR the cockpit is as it was.

var _old_pad: PadFocus
var _old_voice: ReadAloud.Voice
var _old_queue: SpeechQueue
var _read_to_me := false
var spy := Spy.new()


## Hears what is read aloud.
class Spy:
	extends ReadAloud.Voice
	var heard: Array[String] = []

	func has_voice(_language: String) -> bool:
		return true

	func speak(text: String, _language: String) -> void:
		heard.append(text)


## Stands in for RocketFlight: its dashboard node (0.55 m ahead, 0.32 m down, tilted 35° to the eyes).
class FakeFlight:
	extends Node3D
	var dash := Node3D.new()

	func _ready() -> void:
		dash.name = "Dashboard"
		add_child(dash)
		dash.position = Vector3(0.0, 1.28, -0.55)
		dash.rotation = Vector3(deg_to_rad(-35.0), 0.0, 0.0)

	func vr_dashboard() -> Node3D:
		return dash


func before_each() -> void:
	_old_pad = PadFocus.instance
	PadFocus.instance = null
	_old_voice = ReadAloud.voice
	spy = Spy.new()
	ReadAloud.voice = spy
	_old_queue = ReadAloud.queue
	ReadAloud.queue = SpeechQueue.new()   # a fresh one: the same line is not read again within 6 s
	_read_to_me = bool(Profile.data.settings.read_to_me)
	Profile.data.settings.read_to_me = true


func after_each() -> void:
	Vr.simulate(false)
	get_tree().paused = false
	PadFocus.instance = _old_pad
	ReadAloud.voice = _old_voice
	ReadAloud.queue = _old_queue
	Profile.data.settings.read_to_me = _read_to_me


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _flight() -> Dictionary:
	var flight := FakeFlight.new()
	add_child_autofree(flight)
	var layer := CanvasLayer.new()
	var cockpit := FlightCockpit.new()
	layer.add_child(cockpit)
	UiLayers.route(layer, flight)
	return {"flight": flight, "cockpit": cockpit}


func test_off_vr_the_cockpit_is_as_it_was() -> void:
	var f := _flight()
	await _frames(2)
	var c := f.cockpit as FlightCockpit
	assert_false(c.dashboard_mode)
	assert_true(c.view_button.visible, "INSIDE / OUTSIDE")
	assert_true(c.menu_button.visible)


func test_in_vr_the_cockpit_keeps_to_its_dashboard_band() -> void:
	Vr.simulate(true)
	var f := _flight()
	await _frames(3)
	var c := f.cockpit as FlightCockpit
	assert_true(c.dashboard_mode)
	assert_false(c.view_button.visible, "INSIDE only in a headset")
	assert_false(c.menu_button.visible, "the controller's menu button pauses")
	var band := FlightCockpit.dashboard_rect(c.size)
	for part: Control in [c.lever, c.action, c.get_node("Words")]:
		var r := part.get_global_rect()
		assert_true(band.grow(1.0).encloses(r), "%s in the band %s: %s" % [part.name, band, r])


func test_vr_shows_the_band_on_the_flights_dashboard_and_the_tray_goes() -> void:
	Vr.simulate(true)
	var f := _flight()
	await _frames(3)
	var ui := VrUi.instance
	var dash := ui.dashboard
	assert_true(dash.visible, "the dashboard's quad")
	var anchor: Node3D = (f.flight as FakeFlight).dash
	assert_almost_eq(dash.global_transform.origin, anchor.global_transform.origin, Vector3.ONE * 0.001)
	assert_almost_eq(dash.global_transform.basis.z, anchor.global_transform.basis.z, Vector3.ONE * 0.001, "+Z to the child")
	assert_true(dash.layers & RocketFlight.LAYER != 0, "seen in space")
	var m := (dash.mesh as QuadMesh).material as StandardMaterial3D
	var band := FlightCockpit.dashboard_rect((f.cockpit as FlightCockpit).size)
	var c := Vector2(VrPanelRules.CANVAS)
	assert_almost_eq(Vector2(m.uv1_offset.x, m.uv1_offset.y), band.position / c, Vector2(0.001, 0.001), "the band's part")
	assert_almost_eq(Vector2(m.uv1_scale.x, m.uv1_scale.y), band.size / c, Vector2(0.001, 0.001))
	assert_eq(ui.panel.place, VrPanelRules.HIDDEN, "no tray while flying: the HUD is the flight's")
	get_tree().paused = true   # the menu button: the pause menu
	await _frames(1)
	assert_eq(ui.panel.place, VrPanelRules.EYE, "a pause still comes to the eye")
	get_tree().paused = false
	(f.flight as Node).free()
	await _frames(2)
	assert_false(dash.visible, "landed: the dashboard goes")
	assert_eq(ui.panel.place, VrPanelRules.HIDDEN, "and playing again: the HUD waits for the raised forearm (owner #127)")


## Owner #106's Moon landing in a headset: the descent's panel (HEIGHT, SPEED, FUEL) and the first try's hint card are
## on the dashboard (inside its band), every word on them 24 px or more, and the hint card's GO is the controller's A
## (the dashboard is a display: the laser does not press it).
func _descending(f: Dictionary) -> FlightCockpit:
	var c := f.cockpit as FlightCockpit
	c.show_state({"descent": {"h": 42.0, "v": 2.5, "zone": FlightDescent.GREEN, "fuel": 0.6, "safe": 3.0},
		"descent_held": true, "time": 1.0, "hint": FlightDescent.HINT})
	return c


func test_the_descents_panel_and_hint_card_are_on_the_dashboard_and_readable() -> void:
	Vr.simulate(true)
	var f := _flight()
	await _frames(3)
	var c := _descending(f)
	await _frames(3)
	var band := FlightCockpit.dashboard_rect(c.size)
	assert_true(c.descent_dials.visible)
	assert_true(band.encloses(c.descent_dials.get_global_rect()), "HEIGHT, SPEED and FUEL in the band: %s in %s" % [
		c.descent_dials.get_global_rect(), band])
	assert_false(c.descent_dials.get_global_rect().intersects(c.get_node("Words").get_global_rect()),
		"under the trip's words, not over them")
	assert_gte(c.descent_word_px(), VrReadability.MIN_PX, "the panel's small words 24 px on the dashboard")
	assert_true(c.hint_card.visible, "the first try's hint card")
	assert_true(band.encloses(c.hint_card.get_global_rect()), "on the dashboard: %s in %s" % [c.hint_card.get_global_rect(),
		band])
	assert_false(c.hint_card.get_global_rect().intersects(c.get_node("Words").get_global_rect()),
		"under the trip's words, not over them: %s and %s" % [c.hint_card.get_global_rect(),
		c.get_node("Words").get_global_rect()])
	assert_eq(VrReadability.too_small(c.hint_card), [] as Array[String], "its words 24 px or more")
	assert_gte(c.go_button.font_size, VrReadability.MIN_PX)
	watch_signals(c)
	var a := InputEventJoypadButton.new()
	a.device = 12
	a.button_index = JOY_BUTTON_A
	a.pressed = true
	Vr.ui_viewport().push_input(a)
	assert_signal_emitted(c, "go_pressed", "the controller's A is GO")
	assert_signal_not_emitted(c, "action_pressed", "not the ACTION as well")
	assert_false(c.hint_card.visible)


func test_off_vr_the_descent_is_as_it_was() -> void:
	var f := _flight()
	await _frames(3)
	var c := _descending(f)
	await _frames(3)
	assert_eq(c.descent_word_px(), 20, "the flat screen's sizes")
	var mid := c.size * 0.5
	assert_almost_eq(c.hint_card.get_global_rect().get_center(), mid, Vector2(2, 2), "the card in the middle")
	assert_eq(c.go_button.text, "GO!", "the flat screen's GO")
	assert_eq(spy.heard, [FlightDescent.HINT] as Array[String], "the card's words read aloud, as they were")


## In a headset the hint card says how to start: its GO names the controller's button (rocket_action's on a Quest: A),
## and it is read aloud with the card.
func test_in_vr_the_hint_card_says_press_a() -> void:
	Vr.simulate(true)
	var f := _flight()
	await _frames(3)
	var c := _descending(f)
	await _frames(3)
	assert_eq(c.go_button.text, "PRESS A TO GO!")
	assert_eq(VrReadability.too_small(c.hint_card), [] as Array[String], "24 px or more")
	var go := c.go_button.get_global_rect()
	assert_true(c.hint_card.get_global_rect().encloses(go), "the longer word fits the card: %s" % go)
	assert_true(FlightCockpit.dashboard_rect(c.size).encloses(c.hint_card.get_global_rect()), "still on the dashboard")
	assert_eq(spy.heard.size(), 1)
	if spy.heard.size() == 1:
		assert_true(spy.heard[0].begins_with(FlightDescent.HINT), "the card's words")
		assert_true(spy.heard[0].ends_with("Press A to go!"), "and how to start: %s" % spy.heard[0])


## The laser on the hint card (on the dashboard's quad) and a trigger press there is GO too; the rest of the dashboard
## stays a display (ruling 22): the laser over its dials or its ACTION presses nothing.
var _aim := [Vector2(-1, -1)]
var _squeeze := [false]


func _dash_ray(ui: VrUi, c: FlightCockpit) -> Array:
	if _aim[0].x < 0.0:
		return [Vector3(0.0, 1.2, 0.0), Vector3.UP]
	var band := FlightCockpit.dashboard_rect(c.size)
	var uv: Vector2 = (_aim[0] - band.position) / band.size
	var qs := (ui.dashboard.mesh as QuadMesh).size
	var t := ui.dashboard.global_transform
	var spot := t * Vector3((uv.x - 0.5) * qs.x, (0.5 - uv.y) * qs.y, 0.0)
	return [spot + t.basis.z * 0.45, -t.basis.z]


func _laser_press(ui: VrUi, at: Vector2) -> void:
	_aim[0] = at
	ui.step(0.0)
	_squeeze[0] = true
	ui.step(0.0)
	_squeeze[0] = false
	ui.step(0.0)


func test_in_vr_the_laser_and_trigger_on_the_hint_card_is_go() -> void:
	Vr.simulate(true)
	var f := _flight()
	await _frames(3)
	var c := _descending(f)
	await _frames(3)
	var ui := VrUi.instance
	ui.set_process(false)   # the test steps it
	ui.pointer.ray_source = func() -> Array: return _dash_ray(ui, c)
	ui.pointer.trigger_source = func() -> bool: return _squeeze[0]
	watch_signals(c)
	for off_card: Vector2 in [c.lever.get_global_rect().get_center(), c.action.get_global_rect().get_center()]:
		_aim[0] = off_card
		ui.step(0.0)
		assert_false(ui.pointer.hovering, "the dashboard off the card is a display: %s" % off_card)
		_laser_press(ui, off_card)
	assert_signal_not_emitted(c, "action_pressed", "the dashboard's ACTION is not pressed by the laser")
	assert_signal_not_emitted(c, "go_pressed")
	assert_true(c.hint_card.visible)
	_aim[0] = c.hint_card.get_global_rect().position + Vector2(40, 30)   # the card's corner, not its GO
	ui.step(0.0)
	assert_true(ui.pointer.hovering, "the laser meets the card on the dashboard")
	assert_true(ui.pointer.beam.visible, "and shows its beam there")
	assert_true(Vr.ui_wants_pointer())
	assert_true(c.hint_card.visible)
	_laser_press(ui, _aim[0])
	assert_signal_emit_count(c, "go_pressed", 1, "a trigger press on the card is GO")
	assert_false(c.hint_card.visible)
	_aim[0] = c.hint_card.get_global_rect().get_center()
	ui.step(0.0)
	assert_false(ui.pointer.hovering, "the card gone: the dashboard is a display again")


func test_in_vr_the_laser_on_go_presses_it_once() -> void:
	Vr.simulate(true)
	var f := _flight()
	await _frames(3)
	var c := _descending(f)
	await _frames(3)
	var ui := VrUi.instance
	ui.set_process(false)
	ui.pointer.ray_source = func() -> Array: return _dash_ray(ui, c)
	ui.pointer.trigger_source = func() -> bool: return _squeeze[0]
	watch_signals(c)
	_laser_press(ui, c.go_button.get_global_rect().get_center())
	assert_signal_emit_count(c, "go_pressed", 1, "GO once (the button and the card are one press)")
	assert_false(c.hint_card.visible)
