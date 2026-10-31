class_name GamepadRules
extends RefCounted
## Owner #90 (spec §20.3): a game controller (a PlayStation DualSense or DualShock, an Xbox pad, any pad the browser or
## Android knows) plays the whole game. The pure rules: the button table (every action through the input map: the
## joypad events in project.godot come from BINDINGS, tools/setup_input_map.gd), which pad it is by its name and the
## words its buttons have (the CONTROLLER card), the right stick's look, which input came last, and the focus rules
## every menu follows (PadFocus: where the focus starts, where the D-pad takes it, the stick's steps, which button is
## BACK). (PadRules is the jump pads' class; this is the game pad's.)

const PAD := &"pad"
const OTHER := &"other"

const PLAYSTATION := &"playstation"
const XBOX := &"xbox"
const GENERIC := &"generic"   # any other pad: the Xbox letters (most pads a computer knows are XInput ones)
## Owner #101 (VR on the Meta Quest): the Quest's Touch controllers. VrInput plays them as a pad (QUEST_BUTTONS: which
## pad input each control sends), so this one table, PadFocus and the CONTROLLER card work in the headset too.
const QUEST := &"quest"

## The table (docs/devlog/parts/controllers.md, "The buttons"): an action and one pad input, {"button": JoyButton} or
## {"axis": JoyAxis, "value": -1.0 or 1.0}. The world's actions are set aside while a menu has the pad (PadFocus), so
## Cross / A presses a menu's button there without jumping, and the stick moves the focus without walking.
const BINDINGS: Array[Dictionary] = [
	{"action": &"move_forward", "spec": {"axis": JOY_AXIS_LEFT_Y, "value": -1.0}},
	{"action": &"move_back", "spec": {"axis": JOY_AXIS_LEFT_Y, "value": 1.0}},
	{"action": &"move_left", "spec": {"axis": JOY_AXIS_LEFT_X, "value": -1.0}},
	{"action": &"move_right", "spec": {"axis": JOY_AXIS_LEFT_X, "value": 1.0}},
	{"action": &"look_up", "spec": {"axis": JOY_AXIS_RIGHT_Y, "value": -1.0}},
	{"action": &"look_down", "spec": {"axis": JOY_AXIS_RIGHT_Y, "value": 1.0}},
	{"action": &"look_left", "spec": {"axis": JOY_AXIS_RIGHT_X, "value": -1.0}},
	{"action": &"look_right", "spec": {"axis": JOY_AXIS_RIGHT_X, "value": 1.0}},
	{"action": &"jump", "spec": {"button": JOY_BUTTON_A}},
	{"action": &"crouch", "spec": {"button": JOY_BUTTON_B}},
	{"action": &"attack", "spec": {"button": JOY_BUTTON_X}},
	{"action": &"physics_mode", "spec": {"button": JOY_BUTTON_Y}},
	{"action": &"hotbar_prev", "spec": {"button": JOY_BUTTON_LEFT_SHOULDER}},
	{"action": &"hotbar_next", "spec": {"button": JOY_BUTTON_RIGHT_SHOULDER}},
	{"action": &"place", "spec": {"axis": JOY_AXIS_TRIGGER_LEFT, "value": 1.0}},
	{"action": &"break", "spec": {"axis": JOY_AXIS_TRIGGER_RIGHT, "value": 1.0}},
	{"action": &"fly_up", "spec": {"button": JOY_BUTTON_DPAD_UP}},
	{"action": &"fly_down", "spec": {"button": JOY_BUTTON_DPAD_DOWN}},
	{"action": &"blocks", "spec": {"button": JOY_BUTTON_DPAD_LEFT}},
	{"action": &"more", "spec": {"button": JOY_BUTTON_DPAD_RIGHT}},
	{"action": &"size_mode", "spec": {"button": JOY_BUTTON_LEFT_STICK}},
	{"action": &"camera_toggle", "spec": {"button": JOY_BUTTON_RIGHT_STICK}},
	{"action": &"pause", "spec": {"button": JOY_BUTTON_START}},
	{"action": &"map", "spec": {"button": JOY_BUTTON_BACK}},
	{"action": &"map", "spec": {"button": JOY_BUTTON_TOUCHPAD}},
	{"action": &"ui_accept", "spec": {"button": JOY_BUTTON_A}},
	# the rocket flight (owner #79, #87): the left stick steers, R2 / RT the throttle, Cross / A the action, R3 / RS
	# the view (the cockpit's own actions: never the world's while the child flies)
	{"action": &"rocket_steer_up", "spec": {"axis": JOY_AXIS_LEFT_Y, "value": -1.0}},
	{"action": &"rocket_steer_down", "spec": {"axis": JOY_AXIS_LEFT_Y, "value": 1.0}},
	{"action": &"rocket_steer_left", "spec": {"axis": JOY_AXIS_LEFT_X, "value": -1.0}},
	{"action": &"rocket_steer_right", "spec": {"axis": JOY_AXIS_LEFT_X, "value": 1.0}},
	{"action": &"rocket_throttle", "spec": {"axis": JOY_AXIS_TRIGGER_RIGHT, "value": 1.0}},
	{"action": &"rocket_action", "spec": {"button": JOY_BUTTON_A}},
	{"action": &"rocket_view", "spec": {"button": JOY_BUTTON_RIGHT_STICK}},
]
## Actions only a pad has (the keyboard has its own keys for the rest). The input map gets them with these events.
const PAD_ONLY: Array[StringName] = [&"look_up", &"look_down", &"look_left", &"look_right", &"hotbar_prev",
	&"hotbar_next", &"blocks", &"more", &"map"]
## Actions that keep their pad input while a menu has the pad: Options opens and closes the pause menu, the map
## button closes the map, and Cross / A presses the focused button.
const MENU_KEEPS: Array[StringName] = [&"pause", &"map", &"ui_accept"]
## The triggers break and place past half-way (the actions' dead zone; PadFocus passes one press and one release).
const TRIGGER_DEADZONE := 0.5
## A stick or a trigger past this counts as a child playing with the pad (a resting stick is often a little off).
const PUSH := 0.5

## The CONTROLLER card's lines: the actions a line shows (or "stick:left", "stick:right", "menu:…") and what they do.
const CARD_LINES: Array = [
	[[&"stick:left"], "Walk"],
	[[&"stick:right"], "Look around"],
	[[&"jump"], "Jump (twice quickly: fly up)"],
	[[&"break"], "Break a block"],
	[[&"place"], "Place a block, open, talk"],
	[[&"hotbar_prev", &"hotbar_next"], "Pick a block"],
	[[&"attack"], "Attack (hold: draw the bow)"],
	[[&"physics_mode"], "Walk, fly or ghost"],
	[[&"fly_up", &"fly_down"], "Fly up / down"],
	[[&"blocks"], "All the blocks"],
	[[&"more"], "More: map, photo, undo…"],
	[[&"crouch"], "Crouch (in water: dive)"],
	[[&"camera_toggle"], "Camera"],
	[[&"size_mode"], "Size magic"],
	[[&"map"], "Map"],
	[[&"pause"], "Menu"],
	[[&"menu:move", &"menu:press", &"menu:back"], "In menus: move, press, back"],
	[[&"rocket_throttle", &"rocket_action"], "Rocket: go, action"],
]

const _PS_BUTTONS := {JOY_BUTTON_A: "Cross", JOY_BUTTON_B: "Circle", JOY_BUTTON_X: "Square", JOY_BUTTON_Y: "Triangle",
	JOY_BUTTON_LEFT_SHOULDER: "L1", JOY_BUTTON_RIGHT_SHOULDER: "R1", JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3", JOY_BUTTON_START: "Options", JOY_BUTTON_BACK: "Create", JOY_BUTTON_TOUCHPAD: "Touchpad",
	JOY_BUTTON_GUIDE: "PS button"}
const _XBOX_BUTTONS := {JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB", JOY_BUTTON_LEFT_STICK: "LS",
	JOY_BUTTON_RIGHT_STICK: "RS", JOY_BUTTON_START: "Menu", JOY_BUTTON_BACK: "View", JOY_BUTTON_TOUCHPAD: "Touchpad",
	JOY_BUTTON_GUIDE: "Xbox button"}
const _DPAD := {JOY_BUTTON_DPAD_UP: "D-pad up", JOY_BUTTON_DPAD_DOWN: "D-pad down", JOY_BUTTON_DPAD_LEFT: "D-pad left",
	JOY_BUTTON_DPAD_RIGHT: "D-pad right"}
## Owner #101: each Quest control ("<hand>:<control>"; "point" is the pointing hand, "other" the walking one: the
## left-handed setting swaps them) and the pad input VrInput sends for it. The walking hand's stick walks (the left
## stick's axes); the pointing hand's stick turns (snap turn, never look_*); its trigger is TAP (place, use, talk) and
## HOLD (break) on the laser's target (VrInput, TouchClassifier's rule). No CAMERA button: VR is first person only.
const QUEST_BUTTONS := {
	"right:ax": JOY_BUTTON_A,                # A: jump (twice quickly: fly)
	"right:by": JOY_BUTTON_B,                # B: crouch (flying: down)
	"left:ax": JOY_BUTTON_DPAD_RIGHT,        # X: MORE
	"left:by": JOY_BUTTON_DPAD_LEFT,         # Y: BLOCKS
	"left:grip": JOY_BUTTON_LEFT_SHOULDER,   # the hotbar's slot before
	"right:grip": JOY_BUTTON_RIGHT_SHOULDER, # the hotbar's slot after
	"left:menu": JOY_BUTTON_START,           # the menu button: pause
	"other:stick_click": JOY_BUTTON_LEFT_STICK,   # size magic
	"point:stick_click": JOY_BUTTON_Y,       # walk, fly or ghost
	"other:trigger": JOY_BUTTON_X,           # attack
}
## What a control sends instead while the child flies and no menu has the pad (B: down, the D-pad's fly_down).
const QUEST_FLYING := {JOY_BUTTON_B: JOY_BUTTON_DPAD_DOWN}
const _QUEST_WORDS := {JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_DPAD_RIGHT: "X", JOY_BUTTON_DPAD_LEFT: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "Left grip", JOY_BUTTON_RIGHT_SHOULDER: "Right grip", JOY_BUTTON_START: "Menu button",
	JOY_BUTTON_LEFT_STICK: "Click the walking stick", JOY_BUTTON_Y: "Click the turning stick",
	JOY_BUTTON_X: "Other trigger", JOY_BUTTON_DPAD_DOWN: "B"}
const _QUEST_NAMES: Array[String] = ["quest", "oculus", "meta touch"]
const _PS_NAMES: Array[String] = ["dualsense", "dualshock", "playstation", "ps5", "ps4", "ps3", "sony", "054c"]
const _XBOX_NAMES: Array[String] = ["xbox", "xinput", "x-box", "045e", "microsoft"]


## The pad inputs of `action` (the table's specs, in order).
static func specs_for(action: StringName) -> Array:
	var out := []
	for b: Dictionary in BINDINGS:
		if b.action == action:
			out.append(b.spec)
	return out


## Every action that has a pad input, once each, in the table's order.
static func actions() -> Array[StringName]:
	var out: Array[StringName] = []
	for b: Dictionary in BINDINGS:
		if not out.has(b.action):
			out.append(b.action)
	return out


## The actions whose pad inputs a menu sets aside (everything but MENU_KEEPS).
static func world_actions() -> Array[StringName]:
	var out: Array[StringName] = []
	for a in actions():
		if not MENU_KEEPS.has(a):
			out.append(a)
	return out


## The input map's event for one spec (any pad: device -1).
static func make_event(spec: Dictionary) -> InputEvent:
	if spec.has("button"):
		var b := InputEventJoypadButton.new()
		b.device = -1
		b.button_index = spec.button
		return b
	var m := InputEventJoypadMotion.new()
	m.device = -1
	m.axis = spec.axis
	m.axis_value = float(spec.value)
	return m


static func is_pad_event(e: InputEvent) -> bool:
	return e is InputEventJoypadButton or e is InputEventJoypadMotion


## Which hands the event came from: PAD (a pad's button pressed, or a stick or a trigger pushed PUSH far), OTHER (a key,
## a mouse button or a finger pressed), or &"" (nothing to tell: a release, a resting stick, the mouse moving; a
## PlayStation pad's touchpad is a mouse on Android, so the mouse moving never takes the game away from the pad).
static func device_of(e: InputEvent) -> StringName:
	if e is InputEventJoypadButton:
		return PAD if (e as InputEventJoypadButton).pressed else &""
	if e is InputEventJoypadMotion:
		return PAD if absf((e as InputEventJoypadMotion).axis_value) >= PUSH else &""
	if e is InputEventKey:
		var k := e as InputEventKey
		return OTHER if k.pressed and not k.echo else &""
	if e is InputEventMouseButton or e is InputEventScreenTouch:
		return OTHER if e.is_pressed() else &""
	return &""

# --- Which pad, and its words ---

## PLAYSTATION, XBOX or GENERIC from the pad's name (Input.get_joy_name: SDL's name on a computer and Android, the
## Gamepad API's id in a browser, which has the maker's number: 054c Sony, 045e Microsoft). A DualShock 4 on Linux and
## Android calls itself just "Wireless Controller".
static func family(joy_name: String) -> StringName:
	var n := joy_name.to_lower()
	for w in _QUEST_NAMES:
		if n.contains(w):
			return QUEST
	for w in _PS_NAMES:
		if n.contains(w):
			return PLAYSTATION
	if n.ends_with("wireless controller") and not n.contains("xbox"):
		return PLAYSTATION
	for w in _XBOX_NAMES:
		if n.contains(w):
			return XBOX
	return GENERIC


static func button_word(button: int, fam: StringName) -> String:
	if fam == QUEST and _QUEST_WORDS.has(button):
		return str(_QUEST_WORDS[button])
	if _DPAD.has(button):
		return str(_DPAD[button])
	var words: Dictionary = _PS_BUTTONS if fam == PLAYSTATION else _XBOX_BUTTONS
	return str(words.get(button, "Button %d" % button))


static func axis_word(axis: int, fam: StringName) -> String:
	if fam == QUEST:
		match axis:
			JOY_AXIS_TRIGGER_LEFT:
				return "Trigger (tap)"   # owner #101: one trigger: TAP places, HOLD breaks
			JOY_AXIS_TRIGGER_RIGHT:
				return "Trigger (hold)"
			JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y:
				return "Turning stick"
			JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y:
				return "Walking stick"
	match axis:
		JOY_AXIS_TRIGGER_LEFT:
			return "L2" if fam == PLAYSTATION else "LT"
		JOY_AXIS_TRIGGER_RIGHT:
			return "R2" if fam == PLAYSTATION else "RT"
		JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y:
			return "Left stick"
		JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y:
			return "Right stick"
	return "Stick"


static func spec_word(spec: Dictionary, fam: StringName) -> String:
	return button_word(spec.button, fam) if spec.has("button") else axis_word(spec.axis, fam)


## A card line's inputs as the card shows them for a pad of `fam` ("Cross", "L1 / R1", "D-pad up / down", "Touchpad").
static func line_words(line: Array, fam: StringName) -> String:
	if line == [&"stick:left"]:
		return "Left stick"
	if line == [&"stick:right"]:
		return "Right stick"
	if line.size() == 3 and str(line[0]).begins_with("menu:"):
		return "D-pad  %s  %s" % [button_word(JOY_BUTTON_A, fam), button_word(JOY_BUTTON_B, fam)]
	if line == [&"fly_up", &"fly_down"]:
		return "D-pad up / down"
	if line == [&"map"]:   # a PlayStation's own map button is its big touchpad; the rest have View (or Select)
		return button_word(JOY_BUTTON_TOUCHPAD if fam == PLAYSTATION else JOY_BUTTON_BACK, fam)
	var words: Array[String] = []
	for a: StringName in line:
		var specs := specs_for(a)
		if not specs.is_empty():
			words.append(spec_word(specs[0], fam))
	return " / ".join(words)

## L1 / R1: the hotbar's slot before or after `slot` (round from the last to the first).
static func next_slot(slot: int, way: int, size: int) -> int:
	return wrapi(slot + way, 0, maxi(size, 1))


## The CONTROLLER card shows by itself the first time a pad plays in a world (then from the pause menu).
static func card_due(settings: Dictionary) -> bool:
	return not bool(settings.get("pad_seen", false))

# --- The right stick's look ---

## Radians a second sideways at full tilt (NORMAL); up and down turn LOOK_PITCH_SHARE of it.
const LOOK_SPEED := 2.6
const LOOK_PITCH_SHARE := 0.75
const LOOK_DEADZONE := 0.12
## SETTINGS → HELP → Controller look (the profile's "pad_look").
const LOOK_SPEEDS := {"slow": 0.6, "normal": 1.0, "fast": 1.5}
const LOOK_SPEED_ORDER: Array[String] = ["slow", "normal", "fast"]


## The stick past its dead middle, 0..1 long, squared (a small tilt turns slowly for aiming, a full tilt turns fast).
static func look_curve(stick: Vector2) -> Vector2:
	var m := stick.length()
	if m <= LOOK_DEADZONE:
		return Vector2.ZERO
	var t := minf((m - LOOK_DEADZONE) / (1.0 - LOOK_DEADZONE), 1.0)
	return stick / m * t * t


## How far this frame turns (radians: x sideways, y up and down), for CameraRig.look(step, 1.0): the stick to the right
## turns right and pushed up looks up, as the mouse does.
static func look_step(stick: Vector2, delta: float, speed: String) -> Vector2:
	var c := look_curve(stick)
	var k := LOOK_SPEED * float(LOOK_SPEEDS.get(speed, 1.0)) * delta
	return Vector2(c.x * k, c.y * k * LOOK_PITCH_SHARE)

# --- Focus rules (PadFocus follows them on every screen) ---

## Rects whose middles are this close in height are one row.
const ROW_SLOP := 24.0
## The first focus goes to a button at least this share of the biggest one's size (not a little speaker or arrow).
const BIG_SHARE := 0.4
## A stick counts as pushed past STICK_ON, and as let go under STICK_OFF (no flicker in between).
const STICK_ON := 0.6
const STICK_OFF := 0.35
## A held direction steps again after REPEAT_WAIT seconds, then every REPEAT_EVERY.
const REPEAT_WAIT := 0.42
const REPEAT_EVERY := 0.14
## Words on a panel's back button (Circle / B presses it).
const BACK_WORDS: Array[String] = ["BACK", "CLOSE", "X", "✕", "×", "CANCEL", "NOT NOW"]


## Indices of `rects` in reading order: rows from the top (middles within ROW_SLOP), each row left to right.
static func reading_order(rects: Array) -> Array[int]:
	var idx: Array[int] = []
	for i in rects.size():
		idx.append(i)
	idx.sort_custom(func(a: int, b: int) -> bool:
		return (rects[a] as Rect2).get_center().y < (rects[b] as Rect2).get_center().y)
	var out: Array[int] = []
	var row: Array[int] = []
	var row_y := -INF
	for i in idx:
		var y := (rects[i] as Rect2).get_center().y
		if not row.is_empty() and y - row_y > ROW_SLOP:
			out.append_array(_left_to_right(row, rects))
			row.clear()
		if row.is_empty():
			row_y = y
		row.append(i)
	out.append_array(_left_to_right(row, rects))
	return out


static func _left_to_right(row: Array[int], rects: Array) -> Array[int]:
	var r := row.duplicate()
	r.sort_custom(func(a: int, b: int) -> bool: return (rects[a] as Rect2).position.x < (rects[b] as Rect2).position.x)
	return r


## Where the focus starts on a screen: items are {rect, back, later, first}. A panel's own choice (first); else the first
## big button in reading order that is not BACK nor a row of pages (later: a TabBar); else anything; -1 for none.
static func first_focus(items: Array) -> int:
	for i in items.size():
		if bool(items[i].get("first", false)):
			return i
	if items.is_empty():
		return -1
	var rects := items.map(func(it: Dictionary) -> Rect2: return it.rect)
	var biggest := 0.0
	for it: Dictionary in items:
		if not _aside(it):
			biggest = maxf(biggest, (it.rect as Rect2).get_area())
	var order := reading_order(rects)
	for i in order:
		if not _aside(items[i]) and (items[i].rect as Rect2).get_area() >= BIG_SHARE * biggest:
			return i
	for i in order:
		if not bool(items[i].get("back", false)):
			return i
	return order[0]


static func _aside(item: Dictionary) -> bool:
	return bool(item.get("back", false)) or bool(item.get("later", false))


## Where the D-pad (or the stick) takes the focus from `from` in `dir`: the nearest rect ahead, one in line (overlapping
## across) before one off to the side; -1 at the edge (the focus stays: no wrapping round, a child sees where it is).
static func next_focus(from: Rect2, dir: Vector2i, rects: Array) -> int:
	var c := from.get_center()
	var best := -1
	var best_score := INF
	var horizontal := dir.x != 0
	for i in rects.size():
		var r: Rect2 = rects[i]
		if r == from:
			continue
		var rc := r.get_center()
		var along := (rc - c).x * dir.x if horizontal else (rc - c).y * dir.y
		var reach := (from.size.x if horizontal else from.size.y) * 0.25
		if along <= maxf(reach, 1.0):
			continue
		var gap: float
		var cross: float
		var in_line: bool
		if horizontal:
			gap = maxf(0.0, r.position.x - from.end.x if dir.x > 0 else from.position.x - r.end.x)
			cross = absf(rc.y - c.y)
			in_line = r.position.y < from.end.y and r.end.y > from.position.y
		else:
			gap = maxf(0.0, r.position.y - from.end.y if dir.y > 0 else from.position.y - r.end.y)
			cross = absf(rc.x - c.x)
			in_line = r.position.x < from.end.x and r.end.x > from.position.x
		var score := gap + cross * (0.5 if in_line else 2.0) + (0.0 if in_line else 40.0)
		if score < best_score:
			best_score = score
			best = i
	return best


## Every index the D-pad can reach from `start` (tests check that a screen has no button a pad can't get to). The
## indices in `sideways_own` (sliders, a row of pages) use left and right themselves: only up and down leave them.
static func reachable(start: int, rects: Array, sideways_own: Array = []) -> Array[int]:
	var seen: Array[int] = [start]
	var todo: Array[int] = [start]
	while not todo.is_empty():
		var i: int = todo.pop_back()
		for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if d.x != 0 and sideways_own.has(i):
				continue
			var n := next_focus(rects[i], d, rects)
			if n >= 0 and not seen.has(n):
				seen.append(n)
				todo.append(n)
	return seen


## The step a stick pushed to `v` makes, given the step it made before (`was`): a new step once past STICK_ON along its
## main axis, the same step while it stays past STICK_OFF that way, ZERO back in the middle.
static func stick_direction(v: Vector2, was: Vector2i) -> Vector2i:
	if was != Vector2i.ZERO and v.x * was.x + v.y * was.y >= STICK_OFF:
		return was
	if v.length() < STICK_ON:
		return Vector2i.ZERO
	if absf(v.x) >= absf(v.y):
		return Vector2i(1 if v.x > 0.0 else -1, 0)
	return Vector2i(0, 1 if v.y > 0.0 else -1)


## True for a panel's back button's word ("BACK", "◀ BACK", "CLOSE", "X", "NOT NOW"; never "DONE": it keeps a change).
static func is_back_word(text: String) -> bool:
	var t := text.strip_edges().to_upper()
	for mark: String in ["◀", "<", "←", "▶", ">"]:
		t = t.replace(mark, "")
	return BACK_WORDS.has(t.strip_edges())


## A direction held on the D-pad or the stick: it steps at once, again after REPEAT_WAIT, then every REPEAT_EVERY.
class Repeat:
	extends RefCounted
	var dir := Vector2i.ZERO
	var _held := 0.0
	var _next := 0.0

	## The direction held now (ZERO: none). True when this is a new direction, which steps at once.
	func hold(d: Vector2i) -> bool:
		if d == dir:
			return false
		dir = d
		_held = 0.0
		_next = GamepadRules.REPEAT_WAIT
		return d != Vector2i.ZERO

	## Time goes on; true when the held direction steps again.
	func advance(delta: float) -> bool:
		if dir == Vector2i.ZERO:
			return false
		_held += delta
		if _held < _next:
			return false
		_next += GamepadRules.REPEAT_EVERY
		if _next < _held:
			_next = _held + GamepadRules.REPEAT_EVERY
		return true
