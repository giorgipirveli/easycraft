class_name FlightCockpit
extends Control
## The rocket's cockpit (owner #79: "you just sit into it at steering wheel"; #86: "glowing cockpit screens and a
## hologram of the destination"; spec §25.3), over the game while a RocketFlight flies. Inside the capsule: the hull round
## a big window, the dashboard with glowing screens (SPEED in km/s, HEIGHT, the distance to the destination counting
## down, the trip's real clock, FUEL for every stage), the destination's hologram turning, the steering wheel that turns
## as the child steers, the big THROTTLE lever and the big ACTION button (LIFT-OFF!, STAGE, BURN, LEGS, CHUTE, glowing
## while the rocket waits for it). Outside (the chase camera) the hull and the wheel go and the screens stay.
## Over it all: the words of the trip (and kind steering hints), the countdown's big numbers, the green ring or the target
## to steer into, the clouds' white-out, light speed's flash and the fade at touchdown.
## Controls: touch (big buttons, a drag anywhere else to steer; the mouse on a PC works the same), and on a PC the keys
## (KeysRules: WASD or the arrows steer, Shift the throttle, Space the action, V inside or outside, Esc the menu).
## RocketFlight reads `stick`, `throttle`, `action_held` and hears the signals.
## Owner #106: in the descent the child flies, big dials over the dashboard (HEIGHT in metres, SPEED in m/s in its colour:
## green safe, yellow careful, red too fast, blue going up, with the safe speed; FUEL), the descent's short words on the
## hint line, BURN held for full throttle; the first try's hint card with GO; on the way home after a crash the distance
## screen says TO EARTH.

signal action_pressed
signal view_pressed
signal pause_pressed
signal skip_pressed
## Owner #106: GO on the first try's hint card.
signal go_pressed
## Owner #110 (VR round 4, idea 8): a fingertip poked a dashboard button (CockpitTouchRules: STAGE, LEGS, LIGHTS).
signal poked(button: StringName)

const DASH_H := 200.0
const HULL := 26.0
const DRAG_REACH := 110.0         # px of drag for a full stick
const THROTTLE_SPRING := 3.0      # the lever falls back this fast (per second) when let go
const SCREEN_INK := Color(0.55, 1.0, 0.85)
const SCREEN_BG := Color(0.03, 0.08, 0.1, 0.82)
const DIALS_EVERY := 0.12        # seconds between the dials' new numbers (words cost a little to lay out)
const WORDS := {FlightPlan.THROTTLE: "LIFT-OFF!", FlightPlan.STAGE: "STAGE", FlightPlan.BURN: "BURN",
	FlightPlan.LEGS: "LEGS", FlightPlan.PARACHUTE: "CHUTE", FlightPlan.DESCEND: "BURN"}
## Owner #101 (VR on the Meta Quest): in a headset the cockpit is the capsule's dashboard (VR-RIG's capsule round the
## seated child, its window ahead). Dashboard mode keeps everything in the canvas's bottom band (dashboard_rect: the
## screens, the hologram, the lever, ACTION, the trip's words and the countdown), which VrUi shows on a quad at
## RocketFlight.vr_dashboard(); the 2D hull, the aim ring and the screen's flashes and fades go (the capsule's window
## and the head's own fade are VR-RIG's), and so do INSIDE / OUTSIDE (inside only) and MENU (the controller's menu
## button pauses).
const DASH_REGION_H := 520.0
## The descent panel's small words (HEIGHT, SPEED, FUEL, "safe: under …"): 20 px on a screen, 24 on the dashboard.
const DESCENT_WORDS := 20
## The cockpit showing now is in this group (VrUi finds it).
const GROUP := &"flight_cockpit"

var destination := SpaceRules.MOON
## In a headset: the capsule's dashboard (set_dashboard_mode; off VR false).
var dashboard_mode := false
var skippable := false
## Crew flights (spec §21d.6 phase 2): a crew member's cockpit: the pilot flies, so no throttle, ACTION or steering here
## (the dials, the words, the view and the menu stay).
var crew_member := false
## () -> bool: true while the keys belong to something else over the cockpit (a crew flight's chat bar open): the
## cockpit lets them through and steers with none.
var keys_free: Callable = func() -> bool: return false
## The platform's features ({}: this device): a PC shows its keys on the controls.
var platform := {}

## The child's steering, -1..1 each way (x right, y up).
var stick := Vector2.ZERO
## The throttle, 0..1 (the lever, Shift, a held BURN).
var throttle := 0.0
## The ACTION button (or Space) is held down (a burn).
var action_held := false
## Owner #101/#108 (VR, RocketFlight sets it in a headset): the trigger is the lever, as far as it is squeezed (the
## rocket_throttle action's strength past its dead zone) and at once; squeezed less or let go, it falls back at
## THROTTLE_SPRING. Off VR a held Shift or pad trigger climbs to full as before.
var analog_throttle := false

var lever := FlightThrottle.new()
var action := FlightActionButton.new()
var view_button := TouchButton.new()
var menu_button := TouchButton.new()
var skip_button := TouchButton.new()
var words := Label.new()
var hint := Label.new()
var countdown := Label.new()
## The glowing screens (made at the second frame, _build_screens).
var hologram: TextureRect
var speed_value: Label
var speed_name: Label
var height_value: Label
var height_name: Label
var dist_value: Label
var dist_name: Label
var clock_value: Label
var screens: Array[PanelContainer] = []
var fuel_screen: PanelContainer
var state := {}
## Owner #106: the descent's big dials (drawn; shown in the descent only) and the first try's hint card.
var descent_dials := _DescentDials.new()
var hint_card := PanelContainer.new()
var go_button := TouchButton.new()
## Owner #110 (VR round 4, idea 8; overrides VR-UI's ruling 22 for these three only): in dashboard mode STAGE, LEGS and
## LIGHTS, big buttons in a row over the screens (CockpitTouchRules.button_rects). STAGE and LEGS light up when the
## flight waits for them, LIGHTS while the cabin lights are on; RocketFlight finds the fingertips and calls poke(). A
## drawn button each (never a mouse target: the laser keeps to laser_area). Hidden during the descent (its dials and
## card take the band) and off VR.
var poke_buttons := {}
## How long a poked button stays in (s).
const POKE_DOWN := 0.3

var _frame := _Hull.new()
var _aim := _Aim.new()
var _overlay := _Overlay.new()
var _words_box := PanelContainer.new()
var _drag_index := -1
var _drag_from := Vector2.ZERO
var _drag_stick := Vector2.ZERO
var _keys_action := false
var _holo_material := ShaderMaterial.new()
var _spin := 0.0
var _last_words := ""
var _dials_t := 0.0
var _shows := 0
var _last_time := 0.0


func _ready() -> void:
	name = "Cockpit" if name == "" else name
	add_to_group(GROUP)
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var pc := PlatformRules.keyboard_first(platform if not platform.is_empty() else PlatformRules.current())
	_frame.cockpit = self
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_aim.cockpit = self
	_aim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_aim)
	lever.name = "Throttle"
	lever.key_word = KeysRules.key_text("rocket_throttle") if pc else ""
	add_child(lever)
	action.name = "Action"
	action.round_shape = true
	action.key_word = KeysRules.key_text("rocket_action") if pc else ""
	action.pressed.connect(func() -> void: action_pressed.emit())
	add_child(action)
	for b: Array in [[view_button, "View", "OUTSIDE"], [menu_button, "Menu", "MENU"], [skip_button, "Skip", "SKIP"]]:
		var tb: TouchButton = b[0]
		tb.name = b[1]
		tb.text = b[2]
		tb.round_shape = false
		tb.font_size = 24
		add_child(tb)
	view_button.pressed.connect(func() -> void: view_pressed.emit())
	menu_button.pressed.connect(func() -> void: pause_pressed.emit())
	skip_button.pressed.connect(func() -> void: skip_pressed.emit())
	skip_button.visible = skippable
	lever.visible = not crew_member
	_words_box.name = "Words"
	_words_box.add_theme_stylebox_override("panel", UiKit.box(Color(0.05, 0.08, 0.14, 0.82), 18, 12))
	_words_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_words_box.add_child(v)
	for l: Label in [words, hint]:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
	words.add_theme_font_size_override("font_size", 28)
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	add_child(_words_box)
	_words_box.resized.connect(func() -> void:
		if hint_card.visible:
			_place_hint_card())
	countdown.name = "Countdown"
	countdown.add_theme_font_size_override("font_size", 170)
	countdown.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6))
	countdown.add_theme_constant_override("outline_size", 16)
	countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	countdown.visible = false
	add_child(countdown)
	_build_descent()   # owner #106
	_build_pokes()   # owner #110: STAGE, LEGS, LIGHTS to poke in VR
	_overlay.cockpit = self
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	resized.connect(_layout)
	Vr.started.connect(_on_vr)   # owner #101: the dashboard in a headset
	Vr.ended.connect(_on_vr)
	set_dashboard_mode(Vr.active())
	_layout()


## The canvas's bottom band the dashboard shows (canvas pixels of a cockpit of `s`).
static func dashboard_rect(s: Vector2) -> Rect2:
	return Rect2(0.0, s.y - DASH_REGION_H, s.x, DASH_REGION_H)


## Dashboard mode on (a headset) or off.
func set_dashboard_mode(on: bool) -> void:
	dashboard_mode = on
	_aim.visible = not on
	_overlay.visible = not on
	view_button.visible = not on
	menu_button.visible = not on
	_frame.visible = not on and state.get("view", FlightPlan.INSIDE) == FlightPlan.INSIDE
	_dress_go()
	_show_pokes()
	_layout()


func _on_vr() -> void:
	set_dashboard_mode(Vr.active())


## The size of the descent panel's small words now (owner #101: 24 px on the VR dashboard, VrReadability's floor).
func descent_word_px() -> int:
	return maxi(DESCENT_WORDS, VrReadability.MIN_PX) if dashboard_mode else DESCENT_WORDS


## The hint card's place: the middle of the screen, or in a headset the dashboard's band under the trip's words.
func _place_hint_card() -> void:
	hint_card.reset_size()
	var card := hint_card.get_combined_minimum_size()
	if not dashboard_mode:
		hint_card.position = (size - card) * 0.5
		return
	var band := dashboard_rect(size)
	var top := maxf(band.position.y, _words_box.get_rect().end.y + 8.0)
	hint_card.position = Vector2((size.x - card.x) * 0.5, top + (band.end.y - top - card.y) * 0.5)
	hint_card.position.y = clampf(hint_card.position.y, band.position.y, band.end.y - card.y)


## GO on the first try's hint card: its button, or in a headset the controller's A or the laser's trigger on the card.
func _go() -> void:
	if not hint_card.visible:
		return   # one press is one GO (the laser's click and its finger both reach the card)
	hint_card.visible = false
	go_pressed.emit()


## The controller's button that is GO in a headset (rocket_action's on a Quest: "A").
static func go_key() -> String:
	var specs := GamepadRules.specs_for(&"rocket_action")
	return GamepadRules.spec_word(specs[0], GamepadRules.QUEST) if not specs.is_empty() else "A"


## The hint card's words read aloud: in a headset with how to start (owner #101: the card names the button).
func hint_words() -> String:
	return FlightDescent.HINT + (" Press %s to go!" % go_key() if dashboard_mode else "")


## The part of the dashboard the laser may press (VrUi's quad, canvas pixels): the first try's hint card while it
## shows; otherwise none, the dashboard is a display (ruling 22).
func laser_area() -> Rect2:
	return hint_card.get_global_rect() if dashboard_mode and hint_card.is_visible_in_tree() else Rect2()


## GO's word: "GO!" on a screen, "PRESS A TO GO!" in a headset (the card is on the dashboard, not under a finger).
func _dress_go() -> void:
	_word(go_button, "PRESS %s TO GO!" % go_key() if dashboard_mode else "GO!")
	go_button.custom_minimum_size = Vector2(400 if dashboard_mode else 260, 96)


## In a headset a trigger press with the laser on the card is GO (VrPointer presses the dashboard only there).
func _on_card_input(event: InputEvent) -> void:
	if dashboard_mode and event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		hint_card.accept_event()
		_go()


## Owner #106: the descent's dials and the first try's hint card (hidden until the descent).
func _build_descent() -> void:
	descent_dials.name = "DescentDials"
	descent_dials.cockpit = self
	descent_dials.mouse_filter = Control.MOUSE_FILTER_IGNORE
	descent_dials.visible = false
	add_child(descent_dials)
	hint_card.name = "HintCard"
	hint_card.add_theme_stylebox_override("panel", UiKit.box(Color(0.05, 0.1, 0.18, 0.95), 22, 22))
	hint_card.visible = false
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	hint_card.add_child(v)
	var title := Label.new()
	title.text = "LAND IT YOURSELF!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", FlightDescent.COLORS[FlightDescent.GREEN])
	v.add_child(title)
	var text := Label.new()
	text.text = FlightDescent.HINT
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.custom_minimum_size = Vector2(560, 0)
	text.add_theme_font_size_override("font_size", 26)
	v.add_child(text)
	go_button.name = "Go"
	go_button.text = "GO!"
	go_button.round_shape = false
	go_button.font_size = 34
	go_button.custom_minimum_size = Vector2(260, 96)
	go_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go_button.pressed.connect(_go)
	v.add_child(go_button)
	hint_card.gui_input.connect(_on_card_input)
	add_child(hint_card)
	_dress_go()


# --- Owner #110 (VR round 4, idea 8): the dashboard's poke buttons ------------------------------------------------

func _build_pokes() -> void:
	for b: StringName in CockpitTouchRules.BUTTONS:
		var pb := _PokeButton.new()
		pb.name = "Poke" + CockpitTouchRules.word(b).capitalize()
		pb.word = CockpitTouchRules.word(b)
		pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pb.visible = false
		add_child(pb)
		poke_buttons[b] = pb
	_light(CockpitTouchRules.LIGHTS, true)


## The row shows in dashboard mode, but not while the descent's dials or its card take the band.
func _show_pokes() -> void:
	var on := dashboard_mode and not descent_dials.visible and not hint_card.visible
	for b: StringName in poke_buttons:
		(poke_buttons[b] as Control).visible = on


func _light(b: StringName, on: bool) -> void:
	var pb: _PokeButton = poke_buttons[b]
	if pb.lit != on:
		pb.lit = on
		pb.queue_redraw()


## A fingertip poked `b`: it goes in for POKE_DOWN, and poked(b) says so (lit or dark: the flight decides).
func poke(b: StringName) -> void:
	var pb: _PokeButton = poke_buttons.get(b)
	if pb == null or not pb.is_visible_in_tree():
		return
	pb.down = POKE_DOWN
	pb.queue_redraw()
	poked.emit(b)


## The button a fingertip is close over (it glows), &"" for none.
func set_poke_hover(b: StringName) -> void:
	for k: StringName in poke_buttons:
		var pb: _PokeButton = poke_buttons[k]
		if pb.hovered != (k == b):
			pb.hovered = k == b
			pb.queue_redraw()


## LIGHTS lit while the cabin lights are on.
func set_lights(on: bool) -> void:
	_light(CockpitTouchRules.LIGHTS, on)


func poke_lit(b: StringName) -> bool:
	return poke_buttons.has(b) and (poke_buttons[b] as _PokeButton).lit


func poke_down(b: StringName) -> bool:
	return poke_buttons.has(b) and (poke_buttons[b] as _PokeButton).down > 0.0


func poke_hovered(b: StringName) -> bool:
	return poke_buttons.has(b) and (poke_buttons[b] as _PokeButton).hovered


## The buttons showing now, as canvas rectangles (RocketFlight's fingertips land on them); {} when none shows.
func poke_rects() -> Dictionary:
	var out := {}
	for b: StringName in poke_buttons:
		var pb: Control = poke_buttons[b]
		if pb.is_visible_in_tree():
			out[b] = pb.get_global_rect()
	return out


## A button's word, redrawn only when it changes.
static func _word(b: TouchButton, text: String) -> void:
	if b.text != text:
		b.text = text
		b.queue_redraw()


## Says `text` on the words line (it stays until the next words).
func say(text: String) -> void:
	_last_words = text
	words.text = text


## The flight's state for this frame (RocketFlight._update_cockpit).
func show_state(s: Dictionary) -> void:
	state = s
	_shows += 1
	if _shows >= 2:
		_build_later()
	var inside: bool = s.get("view", FlightPlan.INSIDE) == FlightPlan.INSIDE
	_frame.visible = inside and not dashboard_mode
	_word(view_button, "OUTSIDE" if inside else "INSIDE")
	var waiting: StringName = s.get("waiting", &"")
	var step_action: StringName = s.get("action", &"")
	if action.waiting != (waiting != &""):
		action.waiting = waiting != &""
		action.queue_redraw()
	_word(action, WORDS.get(waiting if waiting != &"" else (step_action if not bool(s.get("done", true)) else &""), ""))
	action.visible = (step_action != &"" or waiting != &"") and not crew_member
	var n := int(s.get("countdown", -1))
	countdown.visible = n > 0
	countdown.text = str(n)
	var h := str(s.get("hint", ""))
	hint.text = h
	hint.visible = h != ""
	var descent: Dictionary = s.get("descent", {})   # owner #106
	descent_dials.visible = not descent.is_empty()
	if descent_dials.visible:
		descent_dials.queue_redraw()
		hint.add_theme_color_override("font_color", FlightDescent.COLORS.get(descent.get("zone", FlightDescent.GREEN),
			Color(1.0, 0.92, 0.45)))
	else:
		hint.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	var card := bool(s.get("descent_held", false)) and not crew_member
	if hint_card.visible != card:
		hint_card.visible = card
		if card:
			_place_hint_card()
			ReadAloud.auto(hint_words())
	if dashboard_mode and hint_card.visible:
		hint.visible = false   # owner #101: on the dashboard the card says it (the band has no room for both)
	if not poke_buttons.is_empty():   # owner #110: STAGE and LEGS light up when the flight waits for them
		_light(CockpitTouchRules.STAGE, waiting == FlightPlan.STAGE and not crew_member)
		_light(CockpitTouchRules.LEGS, waiting == FlightPlan.LEGS and not crew_member)
		_show_pokes()
	_dials_t -= float(s.get("time", 0.0)) - _last_time
	_last_time = float(s.get("time", 0.0))
	if _dials_t <= 0.0 and not (s.get("dials", {}) as Dictionary).is_empty() and not screens.is_empty():
		_dials_t = DIALS_EVERY
		_dials(s.get("dials", {}))
	_aim.queue_redraw()
	_overlay.queue_redraw()
	_frame.queue_redraw()


## The glowing screens, the frame after the rest (a flight's first frame stays short).
func _build_later() -> void:
	if not screens.is_empty():
		return
	_build_screens()
	_build_hologram()
	for c: Control in screens + [fuel_screen, hologram]:
		move_child(c, _aim.get_index() + 1)
	_layout()


func _process(delta: float) -> void:
	_build_later()
	var keys := Input.get_vector(&"rocket_steer_left", &"rocket_steer_right", &"rocket_steer_down", &"rocket_steer_up") \
		if InputMap.has_action(&"rocket_steer_left") and not keys_free.call() else Vector2.ZERO
	stick = _drag_stick if _drag_index != -1 else keys
	var held := lever.held or (InputMap.has_action(&"rocket_throttle") and Input.is_action_pressed(&"rocket_throttle"))
	action_held = action.is_down() or _keys_action
	if lever.held:
		throttle = lever.value
	elif analog_throttle and held:   # owner #101/#108: VR's trigger, as far as it is squeezed
		throttle = maxf(Input.get_action_strength(&"rocket_throttle"), throttle - delta * THROTTLE_SPRING)
	elif held:
		throttle = minf(throttle + delta * 4.0, 1.0)
	else:
		throttle = maxf(throttle - delta * THROTTLE_SPRING, 0.0)
	if action_held and state.get("waiting", &"") in [FlightPlan.BURN, FlightPlan.DESCEND]:
		throttle = 1.0
	lever.value = throttle
	for b: StringName in poke_buttons:   # owner #110: a poked button comes back out
		var pb: _PokeButton = poke_buttons[b]
		if pb.down > 0.0:
			pb.down = maxf(pb.down - delta, 0.0)
			if pb.down == 0.0:
				pb.queue_redraw()
	_spin += delta * 0.05
	_holo_material.set_shader_parameter(&"spin", _spin)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or keys_free.call():
		return
	if event is InputEventKey:
		var k := event as InputEventKey
		if event.is_action(&"pause") or k.keycode == KEY_F1:
			return
		if event.is_action_pressed(&"rocket_action") and not k.echo:
			_keys_action = true
			action_pressed.emit()
		elif event.is_action_released(&"rocket_action"):
			_keys_action = false
		elif event.is_action_pressed(&"rocket_view") and not k.echo:
			view_pressed.emit()
		get_viewport().set_input_as_handled()   # the game under the cockpit never hears the flight's keys
	elif event is InputEventJoypadButton:   # owner #90: a controller's Cross / A and R3 / RS (GamepadRules)
		if dashboard_mode and hint_card.visible and event.is_action_pressed(&"rocket_action"):
			_go()   # owner #101: in a headset A is the hint card's GO (the dashboard is a display)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(&"rocket_action"):
			_keys_action = true
			action_pressed.emit()
			get_viewport().set_input_as_handled()
		elif event.is_action_released(&"rocket_action"):
			_keys_action = false
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(&"rocket_view"):
			view_pressed.emit()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _drag_index == -1 and not crew_member and not _on_a_control(t.position):
			_drag_index = t.index
			_drag_from = t.position
			_drag_stick = Vector2.ZERO
		elif not t.pressed and t.index == _drag_index:
			_drag_index = -1
			_drag_stick = Vector2.ZERO
	elif event is InputEventScreenDrag and (event as InputEventScreenDrag).index == _drag_index:
		var d := ((event as InputEventScreenDrag).position - _drag_from) / DRAG_REACH
		_drag_stick = Vector2(d.x, -d.y).limit_length(1.0)


func _exit_tree() -> void:
	FlightLooks.settle()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		_drag_index = -1
		_drag_stick = Vector2.ZERO
		_keys_action = false


func _on_a_control(pos: Vector2) -> bool:
	for c: Control in [lever, action, view_button, menu_button, skip_button, go_button]:
		if c.is_visible_in_tree() and c.get_global_rect().grow(12.0).has_point(pos):
			return true
	return false


func _layout() -> void:
	var w := size.x
	var h := size.y
	if w < 10.0:
		return
	var dash := h - DASH_H
	lever.position = Vector2(26.0, dash - 150.0)
	lever.size = Vector2(118.0, DASH_H + 130.0)
	action.position = Vector2(w - 222.0, h - 222.0)
	action.size = Vector2(200.0, 200.0)
	menu_button.position = Vector2(18.0, 18.0)
	menu_button.size = Vector2(120.0, 84.0)
	view_button.position = Vector2(w - 190.0, 18.0)
	view_button.size = Vector2(172.0, 84.0)
	skip_button.position = Vector2(w - 372.0, 18.0)
	skip_button.size = Vector2(164.0, 84.0)
	var ww := minf(w - 2.0 * 400.0, 860.0) if skippable else minf(w - 2.0 * 220.0, 860.0)
	var top := 16.0
	if dashboard_mode:   # owner #101: everything in the band the dashboard's quad shows
		top = h - DASH_REGION_H + 8.0
		skip_button.position = Vector2(w - 190.0, top)
	_words_box.position = Vector2((w - ww) * 0.5, top)
	_words_box.size = Vector2(ww, 0.0)
	_words_box.custom_minimum_size = Vector2(ww, 0.0)
	countdown.position = Vector2(0, h - DASH_REGION_H) if dashboard_mode else Vector2(0, h * 0.2)
	countdown.size = Vector2(w, DASH_REGION_H - DASH_H) if dashboard_mode else Vector2(w, h * 0.4)
	descent_dials.size = _DescentDials.SIZE   # owner #106: over the dashboard, between the lever and the action button
	descent_dials.position = Vector2((w - _DescentDials.SIZE.x) * 0.5, dash - _DescentDials.SIZE.y - 18.0)
	var pokes := CockpitTouchRules.button_rects(dashboard_rect(size))   # owner #110
	for b: StringName in poke_buttons:
		(poke_buttons[b] as Control).position = (pokes[b] as Rect2).position
		(poke_buttons[b] as Control).size = (pokes[b] as Rect2).size
	_place_hint_card()
	if screens.is_empty():
		return
	var left := 170.0
	screens[0].position = Vector2(left, dash + 22.0)
	hologram.position = Vector2(left + 262.0, dash + 26.0)
	screens[1].position = Vector2(w - 640.0, dash + 22.0)
	fuel_screen.position = Vector2(w - 372.0, dash + 22.0)
	for c: Control in [_frame, _aim, _overlay]:
		c.position = Vector2.ZERO
		c.size = size


func _build_screens() -> void:
	speed_value = Label.new()
	speed_name = Label.new()
	height_value = Label.new()
	height_name = Label.new()
	dist_value = Label.new()
	dist_name = Label.new()
	clock_value = Label.new()
	fuel_screen = PanelContainer.new()
	var specs := [[speed_name, speed_value, height_name, height_value], [dist_name, dist_value, null, clock_value]]
	for spec: Array in specs:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", _screen_box())
		p.custom_minimum_size = Vector2(250.0, 150.0)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(v)
		for l: Variant in spec:
			if l == null:
				continue
			var label := l as Label
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.add_theme_color_override("font_color", SCREEN_INK)
			label.add_theme_constant_override("outline_size", 0)
			var big := label in [speed_value, height_value, dist_value, clock_value]
			label.add_theme_font_size_override("font_size", 30 if big else 16)
			v.add_child(label)
		add_child(p)
		screens.append(p)
	speed_name.text = "SPEED"
	dist_name.text = "TO THE MOON"
	fuel_screen.name = "Fuel"
	fuel_screen.add_theme_stylebox_override("panel", _screen_box())
	fuel_screen.custom_minimum_size = Vector2(140.0, 150.0)
	fuel_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bars := _FuelBars.new()
	bars.cockpit = self
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fuel_screen.add_child(bars)
	add_child(fuel_screen)


func _build_hologram() -> void:
	var lk := FlightLooks.look(destination)
	_holo_material.shader = load("res://ui/flight/hologram.gdshader")
	FlightLooks.picture(str(lk.map), _holo_material, &"surface")
	_holo_material.set_shader_parameter(&"mode", int(lk.mode))
	hologram = TextureRect.new()
	hologram.name = "Hologram"
	hologram.material = _holo_material
	hologram.texture = _blank()
	hologram.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hologram.size = Vector2(146.0, 146.0)
	hologram.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hologram)


static func _blank() -> Texture2D:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	return ImageTexture.create_from_image(img)


static func _screen_box() -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = SCREEN_BG
	b.set_corner_radius_all(14)
	b.set_content_margin_all(12)
	b.border_color = Color(0.3, 0.95, 0.8, 0.8)
	b.set_border_width_all(2)
	b.shadow_color = Color(0.3, 1.0, 0.85, 0.25)
	b.shadow_size = 8
	return b


func _dials(d: Dictionary) -> void:
	if d.is_empty() or screens.is_empty():
		return
	speed_value.text = "LIGHT SPEED!" if bool(d.get("light_speed", false)) else "%s km/s" % km(float(d.speed))
	height_name.text = "HEIGHT ABOVE %s" % str(d.get("height_of", "Earth")).to_upper()
	height_value.text = "%s km" % km(float(d.height))
	dist_name.text = "TO EARTH" if bool(d.get("home", false)) else "TO %s" % FlightPlan.body_name(destination).to_upper()
	var dist := float(d.get("distance", -1.0))
	dist_value.text = "%s km" % km(dist) if dist >= 0.0 else "far, far away"
	var clock := str(d.get("clock", ""))
	clock_value.text = "TRIP: %s" % clock if clock != "" else "TRIP: ?"


## A distance or a speed as a child reads it: "7.8", "384,400", "225,000,000".
static func km(v: float) -> String:
	if v < 0.0:
		return "?"
	if v < 100.0:
		return "%.1f" % v if v != floorf(v) or v < 10.0 else str(int(v))
	var n := str(roundi(v))
	var out := ""
	var count := 0
	for i in range(n.length() - 1, -1, -1):
		out = n[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out


## The capsule round the window, drawn: the hull at the edges and the dashboard under it, the wheel on it.
class _Hull:
	extends Control
	var cockpit: FlightCockpit

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var dash := h - DASH_H
		var hull := Color(0.12, 0.14, 0.2)
		var edge := Color(0.4, 0.45, 0.55)
		draw_rect(Rect2(0, 0, w, HULL), hull)
		draw_rect(Rect2(0, 0, HULL, h), hull)
		draw_rect(Rect2(w - HULL, 0, HULL, h), hull)
		for corner: Vector2 in [Vector2(HULL, HULL), Vector2(w - HULL, HULL)]:   # the window's cut corners
			var sx := 1.0 if corner.x < w * 0.5 else -1.0
			draw_colored_polygon(PackedVector2Array([corner, corner + Vector2(sx * 40.0, 0), corner + Vector2(0, 40.0)]), hull)
		draw_rect(Rect2(HULL, HULL, w - 2.0 * HULL, dash - HULL), edge, false, 4.0)
		var top := Color(0.16, 0.19, 0.27)
		var bottom := Color(0.07, 0.08, 0.12)
		draw_polygon(PackedVector2Array([Vector2(0, dash - 10), Vector2(w, dash - 10), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([top, top, bottom, bottom]))
		draw_line(Vector2(0, dash - 10), Vector2(w, dash - 10), edge, 3.0)
		for x in [HULL * 0.5, w - HULL * 0.5]:   # rivets
			for i in 6:
				draw_circle(Vector2(x, 60.0 + i * (dash - 90.0) / 5.0), 3.5, edge)
		_wheel(Vector2(w * 0.5, h + 26.0), 170.0)

	func _wheel(c: Vector2, r: float) -> void:
		var turn := cockpit.stick.x * 0.9
		draw_arc(c, r, PI, TAU, 40, Color(0.08, 0.08, 0.1), 26.0, true)
		draw_arc(c, r, PI, TAU, 40, Color(0.35, 0.37, 0.45), 18.0, true)
		for k in 3:
			var a := -PI * 0.5 + turn + (k - 1) * 1.05
			draw_line(c, c + Vector2(cos(a), sin(a)) * r, Color(0.3, 0.32, 0.4), 12.0, true)
		draw_circle(c, 44.0, Color(0.2, 0.22, 0.3))
		draw_circle(c + Vector2(cos(-PI * 0.5 + turn), sin(-PI * 0.5 + turn)) * r, 13.0, Color(1.0, 0.75, 0.2))


## The aim: the rocket's nose (a cross in the middle) and the target (the green ring on the climb, the destination, the
## landing pad) where it is from the nose, with its name; inside only.
class _Aim:
	extends Control
	var cockpit: FlightCockpit

	func _draw() -> void:
		var s := cockpit.state
		if s.get("view", FlightPlan.INSIDE) != FlightPlan.INSIDE or not bool(s.get("steer", false)):
			return
		var c := Vector2(size.x * 0.5, size.y * 0.5)
		var ppd := size.y / 70.0   # pixels a degree (the camera sees 70 degrees up and down)
		var off: Vector2 = s.get("off", Vector2.ZERO)
		var at := c + Vector2(off.x, -off.y) * ppd
		var ink := Color(1, 1, 1, 0.85)
		draw_line(c - Vector2(22, 0), c - Vector2(8, 0), ink, 3.0)
		draw_line(c + Vector2(8, 0), c + Vector2(22, 0), ink, 3.0)
		draw_line(c - Vector2(0, 22), c - Vector2(0, 8), ink, 3.0)
		draw_line(c + Vector2(0, 8), c + Vector2(0, 22), ink, 3.0)
		var on := off.length() <= FlightSteering.ON_TARGET
		var green := Color(0.35, 1.0, 0.45, 0.95) if on else Color(0.35, 1.0, 0.45, 0.7)
		var target: StringName = s.get("target", &"")
		match target:
			&"ring":
				draw_arc(at, 46.0, 0.0, TAU, 40, green, 6.0, true)
			&"dest", &"pad":
				draw_arc(at, 34.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.3, 0.9), 4.0, true)
				var name := atr("Landing pad") if target == &"pad" else str(s.get("target_name", ""))
				var font := get_theme_default_font()
				draw_string_outline(font, at + Vector2(-150, 62), name, HORIZONTAL_ALIGNMENT_CENTER, 300, 22, 5,
					Color(0, 0, 0, 0.8))
				draw_string(font, at + Vector2(-150, 62), name, HORIZONTAL_ALIGNMENT_CENTER, 300, 22, Color(1.0, 0.9, 0.5))


## The clouds' white-out (puffs racing down past the window, then white), light speed's flash, the fade at touchdown.
class _Overlay:
	extends Control
	var cockpit: FlightCockpit

	func _draw() -> void:
		var s := cockpit.state
		var cloud := float(s.get("cloud", 0.0))
		if cloud > 0.01:
			var t := float(s.get("time", 0.0))
			var rng := RandomNumberGenerator.new()
			rng.seed = 11
			for i in 14:
				var x := rng.randf() * size.x
				var y := fposmod(rng.randf() * size.y + t * (700.0 + 300.0 * rng.randf()), size.y + 400.0) - 200.0
				var r := rng.randf_range(90.0, 220.0)
				draw_circle(Vector2(x, y), r, Color(1, 1, 1, clampf(cloud * 1.4, 0.0, 0.85)))
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, smoothstep(0.55, 1.0, cloud)))
		var flash := float(s.get("flash", 0.0))
		if flash > 0.01:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, flash))
		var fade := float(s.get("fade", 0.0))
		if fade > 0.01:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, fade))


## FUEL: a glowing bar for each stage, bottom stage on the left; a stage that fell away shows as gone.
class _FuelBars:
	extends Control
	var cockpit: FlightCockpit

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var font := get_theme_default_font()
		draw_string(font, Vector2(0, 16), atr("FUEL"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, SCREEN_INK)
		var fuel: Array = (cockpit.state.get("dials", {}) as Dictionary).get("fuel", [])
		var n := maxi(fuel.size(), 1)
		var gap := 8.0
		var bw := (size.x - gap * (n - 1)) / n
		var top := 26.0
		var bh := size.y - top - 4.0
		for i in fuel.size():
			var f := float(fuel[i])
			var r := Rect2(i * (bw + gap), top, bw, bh)
			draw_rect(r, Color(0.1, 0.2, 0.2, 0.9))
			if f >= 0.0:
				var col := Color(0.35, 1.0, 0.6) if f > 0.25 else Color(1.0, 0.7, 0.2)
				draw_rect(Rect2(r.position.x, r.end.y - bh * f, bw, bh * f), col)
			else:
				draw_line(r.position, r.end, Color(1, 1, 1, 0.4), 2.0)
			draw_rect(r, SCREEN_INK, false, 1.5)


## Owner #106: the descent's big dials, drawn: HEIGHT (metres, and a bar from the ground), SPEED (m/s falling, in its
## colour: green safe, yellow careful, red too fast, blue going up; the safe speed under it), FUEL (the lander's, a bar).
class _DescentDials:
	extends Control
	const SIZE := Vector2(660, 150)
	var cockpit: FlightCockpit

	func _draw() -> void:
		var d: Dictionary = cockpit.state.get("descent", {})
		if d.is_empty():
			return
		var zone: StringName = d.get("zone", FlightDescent.GREEN)
		var col: Color = FlightDescent.COLORS.get(zone, SCREEN_INK)
		var box := StyleBoxFlat.new()
		box.bg_color = SCREEN_BG
		box.set_corner_radius_all(18)
		box.border_color = col
		box.set_border_width_all(4)
		box.shadow_color = Color(col, 0.35)
		box.shadow_size = 10
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		var font := get_theme_default_font()
		var third := size.x / 3.0
		var h := maxf(float(d.get("h", 0.0)), 0.0)
		var v := float(d.get("v", 0.0))
		var fuel := clampf(float(d.get("fuel", 0.0)), 0.0, 1.0)
		for i in 3:
			var x := third * i
			var title: String = ["HEIGHT", "SPEED", "FUEL"][i]
			draw_string(font, Vector2(x, 30), atr(title), HORIZONTAL_ALIGNMENT_CENTER, third, cockpit.descent_word_px(),
				SCREEN_INK)
		# HEIGHT: the metres, and a bar that empties toward the ground
		draw_string(font, Vector2(0, 82), "%d m" % roundi(h), HORIZONTAL_ALIGNMENT_CENTER, third, 44, Color.WHITE)
		var hb := Rect2(30, 104, third - 60, 16)
		draw_rect(hb, Color(0.1, 0.2, 0.2, 0.9))
		draw_rect(Rect2(hb.position, Vector2(hb.size.x * clampf(h / FlightDescent.START_HEIGHT, 0.0, 1.0), hb.size.y)),
			SCREEN_INK)
		# SPEED: falling (or going up), in its colour, and the safe speed
		var arrow := "up " if v < -0.5 else ""
		draw_string_outline(font, Vector2(third, 82), "%s%.1f m/s" % [arrow, absf(v)], HORIZONTAL_ALIGNMENT_CENTER, third,
			44, 6, Color(0, 0, 0, 0.7))
		draw_string(font, Vector2(third, 82), "%s%.1f m/s" % [arrow, absf(v)], HORIZONTAL_ALIGNMENT_CENTER, third, 44, col)
		draw_string(font, Vector2(third, 124), atr("safe: under %d m/s") % int(float(d.get("safe", 3.0))),
			HORIZONTAL_ALIGNMENT_CENTER, third, cockpit.descent_word_px(), SCREEN_INK)
		# FUEL: the lander's, a bar (orange when low)
		var fb := Rect2(third * 2.0 + 30, 50, third - 60, 34)
		draw_rect(fb, Color(0.1, 0.2, 0.2, 0.9))
		var fc := Color(0.35, 1.0, 0.6) if fuel > 0.25 else Color(1.0, 0.6, 0.2)
		draw_rect(Rect2(fb.position, Vector2(fb.size.x * fuel, fb.size.y)), fc)
		draw_rect(fb, SCREEN_INK, false, 2.0)
		draw_string(font, Vector2(third * 2.0, 124), "%d%%" % roundi(fuel * 100.0), HORIZONTAL_ALIGNMENT_CENTER, third, 26,
			Color.WHITE)


## Owner #110 (VR round 4, idea 8): a dashboard button to poke: lit (amber, glowing) when it is its moment, dark (slate)
## otherwise; it goes in when poked (darker, a little lower) and its edge brightens while a fingertip is close over it.
## Its word is 30 px (VR's 24 px floor).
class _PokeButton:
	extends Control
	const LIT := Color(1.0, 0.72, 0.22)
	const DARK := Color(0.2, 0.24, 0.32)
	var word := ""
	var lit := false
	var hovered := false
	var down := 0.0

	func _draw() -> void:
		var col := LIT if lit else DARK
		var shift := 5.0 if down > 0.0 else 0.0
		var box := StyleBoxFlat.new()
		box.bg_color = col.darkened(0.3) if down > 0.0 else col
		box.set_corner_radius_all(16)
		box.border_color = Color.WHITE if hovered else col.lightened(0.35)
		box.set_border_width_all(5 if hovered else 3)
		if lit:
			box.shadow_color = Color(LIT, 0.45)
			box.shadow_size = 10
		draw_style_box(box, Rect2(Vector2(0.0, shift), size - Vector2(0.0, shift)))
		var ink := Color(0.12, 0.08, 0.02) if lit else Color(0.75, 0.82, 0.92)
		var font := get_theme_default_font()
		draw_string(font, Vector2(0.0, size.y * 0.5 + 11.0 + shift * 0.5), atr(word), HORIZONTAL_ALIGNMENT_CENTER, size.x,
			30, ink)
