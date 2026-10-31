class_name PadFocus
extends Node
## Owner #90: every menu and panel with a game controller, through general means (docs/DEVELOPMENT.md §5 "Game
## controllers"). One per game, under the root (main.gd: install); tests make their own.
##
## - **Which hands:** the last input decides (GamepadRules.device_of): `pad` true after a pad's press or push, false
##   after a key, a click or a finger; `device_changed` tells the HUD (the touch buttons hide) and the cards.
## - **Panels:** a panel is watched (watch: it has the pad while it shows) or takes the focus now (take). The newest
##   panel showing has the pad; closed, the one under it gets it back where the child left it. Content that changes
##   inside a panel (the menu's screens, the School's pages) gets the focus again by itself.
## - **Focus** (GamepadRules: first_focus, next_focus): it starts on the panel's first big button (never BACK); the
##   D-pad and the left stick move it (a step per push, repeating while held), never out of the panel; Cross / A presses
##   (ui_accept); Circle / B goes back (back()); L1 / R1 turn the panel's pages (a TabBar); left and right slide a
##   slider. Buttons made unfocusable for the mouse (FOCUS_NONE) take the pad's focus and are made mouse-only again
##   when the mouse, a finger or the keyboard comes back (then nothing keeps a focus Space could press).
## - **The world's inputs:** while a panel has the pad, the world's pad inputs (GamepadRules.world_actions) are out of
##   the input map, so Cross / A never jumps behind a menu and the stick never walks; they come back when it closes.
## - **Triggers:** one press and one release per squeeze reach the game (a trigger sends many small moves).
## - **The ring** (PadRing, UiKit.focus_ring): over everything, round the focused control, only while a pad is used.
##
## What a panel can say (all optional): meta `pad_first` (start here), `pad_skip` (never focus), `pad_back` (this is the
## BACK button); methods `pad_back() -> bool` (go back yourself; true: done), and on a drawn control `pad_move(dir) ->
## bool` (true: moved inside; false: the focus moves on) and `pad_press() -> bool`.

signal device_changed(pad: bool)

## The game's one PadFocus (null in tests that have none: every static call is then a no-op).
static var instance: PadFocus
## True while back() sends the phone's Back round the tree (the menu never quits the game for a pad's Circle / B).
static var back_from_pad := false
## Owner #101: the VR keyboard (VrKeyboard) while it shows: every pad event goes to its pad_input(event) -> bool first
## (true: it was the keyboard's), so the sticks move over its keys and the screen's focus stays on the box it types in.
static var keyboard: Control = null

var pad := false
var pad_name := ""
var family: StringName = GamepadRules.GENERIC
var ring: PadRing

var _roots: Array[Dictionary] = []   # {ref: WeakRef (Control), order: int (0: never shown yet)}
var _order := 0
var _remembered := {}                # a root's instance id -> WeakRef of its last focused control
var _armed: Array[WeakRef] = []      # FOCUS_NONE controls that took the pad's focus
var _set_aside := {}                 # action -> the pad events taken out while a panel has the pad
var _repeat := GamepadRules.Repeat.new()
var _stick := Vector2.ZERO
var _stick_dir := Vector2i.ZERO
var _triggers := {}                  # "device:axis" -> pressed
var _swallow := {}                   # button -> true: its release is the pad's too
var _active: Control
var _device := -1                    # the pad that played last
var _vr := false                     # owner #101: the headset's controllers are the pad (set_vr)


## Adds the game's PadFocus under `root` (once).
static func install(root: Node) -> PadFocus:
	if instance != null and is_instance_valid(instance):
		return instance
	var p := PadFocus.new()
	p.name = "PadFocus"
	instance = p
	root.add_child.call_deferred(p)
	return p


## `panel` has the pad whenever it shows (the newest shown wins).
static func watch(panel: Control) -> void:
	if instance != null and is_instance_valid(instance) and panel != null:
		instance._watch(panel)


## `panel` has the pad now (a card that just opened); `first`: where the focus starts.
static func take(panel: Control, first: Control = null) -> void:
	if instance == null or not is_instance_valid(instance) or panel == null:
		return
	instance._watch(panel)
	instance._bump(panel)
	if first != null:
		instance._remembered[panel.get_instance_id()] = weakref(first)


## A pad was the last thing used.
static func pad_active() -> bool:
	return instance != null and is_instance_valid(instance) and instance.pad


## A watched panel shows (it has the pad; the world's pad inputs are set aside).
static func menu_has_pad() -> bool:
	return instance != null and is_instance_valid(instance) and instance._pick_active() != null


## The child plays the world with a pad (no panel has it).
static func playing_with_pad() -> bool:
	return pad_active() and not menu_has_pad()


## The pad's family (GamepadRules.PLAYSTATION, XBOX or GENERIC) for its words.
static func current_family() -> StringName:
	return instance.family if instance != null and is_instance_valid(instance) else GamepadRules.GENERIC


func _enter_tree() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ring == null:
		var layer := CanvasLayer.new()
		layer.name = "PadRingLayer"
		layer.layer = 126   # over the menus, the pause menu and MOVE BUTTONS (120)
		add_child(layer)
		ring = PadRing.new()
		layer.add_child(ring)


func _exit_tree() -> void:
	_set_world_inputs(true)
	_disarm()
	if instance == self:
		instance = null


## Owner #101 (VR on the Meta Quest): while VR runs PadFocus lives in the VR canvas (VrUi) and the headset's controllers
## are the pad: it plays as a pad from the start (the touch HUD hides, the menus show the ring), and the laser's mouse
## and finger events into the canvas never take the pad away. Off again, it is as before.
func set_vr(on: bool) -> void:
	if on == _vr:
		return
	_vr = on
	if on:
		_set_pad(true, _device)
	set_pad_name(pad_name)   # the headset's words (vr_family), or the pad's again


## In VR (set_vr).
func in_vr() -> bool:
	return _vr


## The headset's controllers' words on the CONTROLLER card: GamepadRules' QUEST family once the rig (VR-RIG) adds it,
## else the generic pad's.
static func vr_family() -> StringName:
	var rules: Script = GamepadRules
	return StringName(rules.get_script_constant_map().get("QUEST", GamepadRules.GENERIC))


## The pad's name (Input.get_joy_name), which chooses the words (tests set one). In VR the headset's controllers'.
func set_pad_name(joy_name: String) -> void:
	pad_name = joy_name
	var f := vr_family() if _vr else GamepadRules.family(joy_name)
	if f != family:
		family = f
		if pad:
			device_changed.emit(true)


func _process(delta: float) -> void:
	step(delta)


## One frame: which panel has the pad, the world's inputs, the focus (again after new content) and a held direction.
func step(delta: float) -> void:
	var root := _pick_active()
	if root != _active:
		_active = root
		_repeat.hold(Vector2i.ZERO)
	_set_world_inputs(root == null)
	if pad and root != null:
		var f := _focus_owner()
		if f == null or not _inside(root, f) or not f.is_visible_in_tree():
			_focus_into(root)
		elif _repeat.advance(delta):
			_navigate(_repeat.dir)
	ring.target = _focus_owner() if pad else null


func _input(event: InputEvent) -> void:
	var dev := GamepadRules.device_of(event)
	var woke := false
	if dev == GamepadRules.PAD and not pad:
		woke = true
		_set_pad(true, event.device)
	elif dev == GamepadRules.PAD and event.device != _device:
		_device = event.device
		set_pad_name(Input.get_joy_name(event.device))   # another pad took over: its own words
	elif dev == GamepadRules.OTHER and pad and not _vr:   # owner #101: in VR the laser never takes the pad away
		_set_pad(false, -1)
	if not GamepadRules.is_pad_event(event):
		return
	if keyboard != null and is_instance_valid(keyboard) and keyboard.is_visible_in_tree() \
			and bool(keyboard.call(&"pad_input", event)):   # owner #101: the VR keyboard has the pad while it shows
		_handled()
		return
	if event is InputEventJoypadMotion:
		_motion(event as InputEventJoypadMotion, woke)
		return
	var b := event as InputEventJoypadButton
	var root := _pick_active()
	if root == null:
		if b.pressed:
			_drop_hidden_focus()
		return
	if not b.pressed:
		if _swallow.has(b.button_index):
			_swallow.erase(b.button_index)
			_handled()
			if b.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
				_repeat.hold(Vector2i.ZERO)
		return
	if woke:   # the press that woke the pad only shows where the focus is
		_swallow[b.button_index] = true
		_handled()
		_active = root
		_focus_into(root)
		return
	var dir := _dpad_dir(b.button_index)
	if dir != Vector2i.ZERO:
		_swallow[b.button_index] = true
		_handled()
		if _repeat.hold(dir):
			_navigate(dir)
		return
	match b.button_index:
		JOY_BUTTON_A:
			var f := _focus_owner()
			if f != null and _inside(root, f) and f.has_method(&"pad_press") and bool(f.call(&"pad_press")):
				_swallow[b.button_index] = true
				_handled()
		JOY_BUTTON_B:
			_swallow[b.button_index] = true
			_handled()
			back()
		JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
			_swallow[b.button_index] = true
			_handled()
			_turn_page(root, -1 if b.button_index == JOY_BUTTON_LEFT_SHOULDER else 1)


func _set_pad(on: bool, device: int) -> void:
	if on:
		_device = device
		set_pad_name(Input.get_joy_name(device) if device >= 0 else "")
	if on == pad:
		return
	pad = on
	if not on:
		_repeat.hold(Vector2i.ZERO)
		_stick_dir = Vector2i.ZERO
		_disarm()
	device_changed.emit(on)


## Playing (no panel has the pad): a button clicked earlier keeps no hidden focus for Cross / A to press (or for the
## stick to move round the HUD).
func _drop_hidden_focus() -> void:
	var f := _focus_owner()
	if f != null and not (f is LineEdit or f is TextEdit):
		get_viewport().gui_release_focus()


func _motion(m: InputEventJoypadMotion, woke: bool) -> void:
	if m.axis == JOY_AXIS_TRIGGER_LEFT or m.axis == JOY_AXIS_TRIGGER_RIGHT:
		var key := "%d:%d" % [m.device, m.axis]
		var on := m.axis_value >= GamepadRules.TRIGGER_DEADZONE
		if bool(_triggers.get(key, false)) == on:
			_handled()   # one press and one release per squeeze reach the game
		else:
			_triggers[key] = on
		return
	if m.axis != JOY_AXIS_LEFT_X and m.axis != JOY_AXIS_LEFT_Y:
		return
	if m.axis == JOY_AXIS_LEFT_X:
		_stick.x = m.axis_value
	else:
		_stick.y = m.axis_value
	var root := _pick_active()
	if root == null:
		_stick_dir = Vector2i.ZERO
		if absf(m.axis_value) >= GamepadRules.PUSH:
			_drop_hidden_focus()
		return
	_handled()   # the menu's own steps (the engine's would step once per stick event)
	var d := GamepadRules.stick_direction(_stick, _stick_dir)
	if woke:   # the push that woke the pad only shows where the focus is (held on, it repeats later)
		_stick_dir = d
		_repeat.hold(d)
		_active = root
		_focus_into(root)
		return
	if d == _stick_dir:
		return
	_stick_dir = d
	if _repeat.hold(d):
		_navigate(d)


func _handled() -> void:
	var vp := get_viewport()
	if vp:
		vp.set_input_as_handled()


static func _dpad_dir(button: int) -> Vector2i:
	match button:
		JOY_BUTTON_DPAD_UP:
			return Vector2i.UP
		JOY_BUTTON_DPAD_DOWN:
			return Vector2i.DOWN
		JOY_BUTTON_DPAD_LEFT:
			return Vector2i.LEFT
		JOY_BUTTON_DPAD_RIGHT:
			return Vector2i.RIGHT
	return Vector2i.ZERO

# --- Panels ---

func _watch(panel: Control) -> void:
	if _index_of(panel) >= 0:
		return
	_roots.append({"ref": weakref(panel), "order": 0, "id": panel.get_instance_id()})
	if panel.is_inside_tree() and panel.is_visible_in_tree():
		_bump(panel)
	panel.visibility_changed.connect(_on_shown.bind(weakref(panel)))


func _on_shown(ref: WeakRef) -> void:
	var panel := ref.get_ref() as Control
	if panel != null and panel.is_visible_in_tree():
		_bump(panel)


func _bump(panel: Control) -> void:
	var i := _index_of(panel)
	if i >= 0:
		_order += 1
		_roots[i].order = _order


func _index_of(panel: Control) -> int:
	for i in _roots.size():
		if _roots[i].ref.get_ref() == panel:
			return i
	return -1


## The newest watched panel that shows (null: the child is playing).
func _pick_active() -> Control:
	var best: Control = null
	var best_order := 0
	var i := 0
	while i < _roots.size():
		var panel := _roots[i].ref.get_ref() as Control
		if panel == null or panel.is_queued_for_deletion():
			_remembered.erase(_roots[i].id)
			_roots.remove_at(i)
			continue
		i += 1
		if panel.is_inside_tree() and panel.is_visible_in_tree() and int(_roots[i - 1].order) > best_order:
			best = panel
			best_order = int(_roots[i - 1].order)
	return best


## The world's pad inputs out of the input map (a panel has the pad) or back in.
func _set_world_inputs(on: bool) -> void:
	if on == _set_aside.is_empty():
		return
	if on:
		for action: StringName in _set_aside:
			for e: InputEvent in _set_aside[action]:
				if InputMap.has_action(action):
					InputMap.action_add_event(action, e)
		_set_aside.clear()
		return
	for action in GamepadRules.world_actions():
		if not InputMap.has_action(action):
			continue
		var out: Array[InputEvent] = []
		for e: InputEvent in InputMap.action_get_events(action):
			if GamepadRules.is_pad_event(e):
				out.append(e)
		for e in out:
			InputMap.action_erase_event(action, e)
		_set_aside[action] = out
		if pad and Input.is_action_pressed(action):
			Input.action_release(action)   # a held button or stick never stays pressed behind the menu

# --- Focus ---

func _focus_owner() -> Control:
	var vp := get_viewport()
	return vp.gui_get_focus_owner() if vp else null


static func _inside(root: Control, c: Control) -> bool:
	return c == root or root.is_ancestor_of(c)


## The controls in `root` the pad can focus, in tree order (laid out: a control of no size yet is left out).
func candidates(root: Control) -> Array[Control]:
	var all: Array[Control] = []
	_collect(root, all)
	var out: Array[Control] = []
	for c in all:
		if c.size.x > 0.0 and c.size.y > 0.0:
			out.append(c)
	return out


func _collect(n: Node, out: Array[Control]) -> void:
	for child in n.get_children():
		var c := child as Control
		if c == null or not c.visible or c.is_queued_for_deletion():
			continue
		if c.has_meta(&"pad_skip") and bool(c.get_meta(&"pad_skip")):
			continue
		if _focusable(c):
			out.append(c)
			if c is BaseButton or c is TouchButton:
				continue
		_collect(c, out)


static func _focusable(c: Control) -> bool:
	if c is BaseButton:   # a button the mouse passes through is a picture (a card's planet), not a choice
		return not (c as BaseButton).disabled and c.mouse_filter != Control.MOUSE_FILTER_IGNORE
	if c is TouchButton or c is Slider or c is SpinBox:
		return true
	if c is TabBar:
		return (c as TabBar).tab_count > 1
	if c is LineEdit:
		return (c as LineEdit).editable
	if c.has_method(&"pad_move") or c.has_method(&"pad_press"):
		return true
	return false


## Controls that use left and right themselves (a slider, a row of pages): only up and down leave them.
static func sideways_own(c: Control) -> bool:
	return c is Slider or c is SpinBox or c is TabBar


static func is_back_button(c: Control) -> bool:
	if c.has_meta(&"pad_back") and bool(c.get_meta(&"pad_back")):
		return true
	if c is Button:
		return GamepadRules.is_back_word((c as Button).text)
	if c is TouchButton:
		return GamepadRules.is_back_word((c as TouchButton).text)
	return false


## Where the focus goes in `root`: where the child left it, else GamepadRules.first_focus. Waits (for a later frame)
## while the panel is not laid out yet.
func _focus_into(root: Control) -> void:
	var ref: WeakRef = _remembered.get(root.get_instance_id())
	var kept := ref.get_ref() as Control if ref else null
	if kept != null and kept.is_inside_tree() and kept.is_visible_in_tree() and _inside(root, kept) and _focusable(kept):
		_focus(kept, root)
		return
	var list := candidates(root)
	if list.is_empty():
		return   # nothing laid out yet: a later frame
	var items := []
	for c in list:
		items.append({"rect": c.get_global_rect(), "back": is_back_button(c), "later": c is TabBar,
			"first": c.has_meta(&"pad_first") and bool(c.get_meta(&"pad_first"))})
	var i := GamepadRules.first_focus(items)
	if i >= 0:
		_focus(list[i], root)


func _focus(c: Control, root: Control) -> void:
	if c.focus_mode == Control.FOCUS_NONE:
		c.focus_mode = Control.FOCUS_ALL
		_armed.append(weakref(c))
	c.grab_focus()
	_remembered[root.get_instance_id()] = weakref(c)
	var p := c.get_parent()
	while p != null and p != root.get_parent():
		if p is ScrollContainer:
			(p as ScrollContainer).ensure_control_visible.call_deferred(c)
		p = p.get_parent()


## Every armed control mouse-only again, and no focus left that Space could press (a text box keeps its focus).
func _disarm() -> void:
	var f := _focus_owner()
	if f != null and not (f is LineEdit or f is TextEdit):
		get_viewport().gui_release_focus()
	for w in _armed:
		var c := w.get_ref() as Control
		if c != null:
			c.focus_mode = Control.FOCUS_NONE
	_armed.clear()


func _navigate(dir: Vector2i) -> void:
	var root := _pick_active()
	if root == null:
		return
	var f := _focus_owner()
	if f == null or not _inside(root, f):
		_focus_into(root)
		return
	if f.has_method(&"pad_move") and bool(f.call(&"pad_move", dir)):
		return
	if dir.x != 0 and (f is Slider or f is SpinBox):
		var r := f as Range
		var s := r.step if r.step > 0.0 else (r.max_value - r.min_value) / 20.0
		r.value += s * dir.x
		return
	if dir.x != 0 and f is TabBar:   # a row of pages: left and right turn them
		if dir.x > 0:
			(f as TabBar).select_next_available()
		else:
			(f as TabBar).select_previous_available()
		return
	var list := candidates(root)
	var rects := []
	var from := f.get_global_rect()
	for c in list:
		rects.append(c.get_global_rect())
	var i := GamepadRules.next_focus(from, dir, rects)
	if i >= 0:
		_focus(list[i], root)


## L1 / R1: the panel's pages (its first TabBar showing), the next one a child can see.
func _turn_page(root: Control, way: int) -> void:
	for n in root.find_children("*", "TabBar", true, false):
		var t := n as TabBar
		if t.is_visible_in_tree():
			if way > 0:
				t.select_next_available()
			else:
				t.select_previous_available()
			return


## Circle / B: the nearest pad_back() from the focus up (a panel inside another, as a body's card on the Star Map, asks
## the one round it too), else the panel's BACK / CLOSE / X button, else the game's Back (Android's: every screen already
## answers it).
func back() -> void:
	var root := _pick_active()
	if root == null:
		return
	var f := _focus_owner()
	var n: Node = f if f != null and _inside(root, f) else root
	while n != null:
		if n.has_method(&"pad_back") and bool(n.call(&"pad_back")):
			return
		n = n.get_parent()
	var list := candidates(root)
	var rects := []
	var backs: Array[Control] = []
	for c in list:
		if is_back_button(c):
			backs.append(c)
			rects.append(c.get_global_rect())
	if not backs.is_empty():
		press(backs[GamepadRules.reading_order(rects)[0]])
		return
	back_from_pad = true
	get_tree().root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	back_from_pad = false


## Presses `c` as a tap would (its pressed signal; a drawn control's pad_press).
static func press(c: Control) -> void:
	if c.has_method(&"pad_press"):
		c.call(&"pad_press")
	elif c is BaseButton:
		(c as BaseButton).pressed.emit()


## The ring round the pad's focus: UiKit's focus ring, over everything, gently pulsing (still with Reduce motion).
class PadRing:
	extends Control

	const GROW := 7.0
	var target: Control:
		set(value):
			if value != target:
				target = value
				queue_redraw()
	var _box := UiKit.focus_ring()
	var _t := 0.0

	func _init() -> void:
		name = "PadRing"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(delta: float) -> void:
		_t += delta
		if target != null:
			queue_redraw()

	func _draw() -> void:
		if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
			return
		var r := target.get_global_rect().grow(GROW)
		var still := Profile.data != null and bool(Profile.data.settings.get("reduce_motion", false))
		var pulse := 1.0 if still else 0.8 + 0.2 * sin(_t * TAU * 1.2)
		var round_shape := target is TouchButton and (target as TouchButton).round_shape
		if round_shape:
			var c := r.get_center()
			var rad := minf(r.size.x, r.size.y) * 0.5
			draw_arc(c, rad + 2.0, 0.0, TAU, 48, Color(0, 0, 0, 0.55), 9.0, true)
			draw_arc(c, rad, 0.0, TAU, 48, Color(UiKit.FOCUS, pulse), 5.0, true)
			return
		draw_style_box(UiKit.focus_shadow(), r.grow(2.0))
		_box.border_color = Color(UiKit.FOCUS, pulse)
		draw_style_box(_box, r)
