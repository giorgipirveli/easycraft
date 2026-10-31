class_name VrKeyboard
extends PanelContainer
## VR on the Meta Quest (owner #101, P2): a headset has no phone keyboard, so the VR canvas has its own, for any text
## box in it (the name, chat, codes, pet names, the online keys, the invite code, the Shorts maker: no box needs to know
## it). VrUi steps it every frame: when an editable LineEdit or TextEdit in the canvas has the focus it comes up
## (anchored at the canvas's bottom; VrUi puts the panel at the eye), and it types into that box as a keyboard's keys do
## (key events pushed into the canvas, so the box's own rules hold: the longest name, what it lets in, Enter submits,
## its text_changed checks run). A line at its top shows what is typed (the box may be under it). It goes with DONE,
## the controller's B, or the focus moving on; after DONE it stays away until the focus comes back to the box. Its keys
## never take the focus (FOCUS_NONE): the laser presses them; the sticks move a highlight over them and A presses
## (PadFocus hands it the pad while it shows: PadFocus.keyboard).

const ROWS := [["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"], ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
	["a", "s", "d", "f", "g", "h", "j", "k", "l", "-"], ["z", "x", "c", "v", "b", "n", "m", ".", "_", "?"]]
const SHIFT := "SHIFT"
const SPACE := "SPACE"
const DELETE := "DELETE"
const ENTER := "ENTER"
const DONE := "DONE"
## A secret box's SHOW / HIDE (a password: owner #105), shown only for one.
const SHOW := "SHOW"
const BOTTOM := [SHIFT, SPACE, DELETE, ENTER, SHOW, DONE]
const KEY_SIZE := Vector2(104, 72)
## Meta on a box the keyboard knows as a password box (it keeps SHOW / HIDE after SHOW).
const SECRET_BOX := &"vr_secret_box"
const WIDE := {SPACE: 250.0, SHIFT: 170.0, DELETE: 190.0, ENTER: 170.0, SHOW: 150.0, DONE: 170.0}
const KEY_FONT := 32
const GAP := 8
## Over the routed layers and under PadFocus's ring (126) and the laser's dot (127).
const LAYER := 125
## A stick pushed past this moves the highlight one key (again only after it comes back).
const STICK_PUSH := 0.6

## The box it types into (null while hidden).
var target: Control = null
## The VR canvas it lives in (VrUi sets it).
var canvas: SubViewport

var _keys := {}                 # word -> Button
var _rows: Array = []           # Array of Array[Button]: the highlight's grid
var _sel := Vector2i.ZERO        # column, row
var _shift := false
var _dismissed: WeakRef = null   # the box DONE put the keyboard away from
var _line := Label.new()
var _stick := Vector2i.ZERO
var _ring := Ring.new()


func _init() -> void:
	name = "VrKeyboard"
	theme = UiKit.theme()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", UiKit.box(Color(0.06, 0.08, 0.14, 0.97), 24, 18))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", GAP)
	add_child(v)
	_line.name = "Typed"
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line.add_theme_font_size_override("font_size", 34)
	_line.custom_minimum_size = Vector2(0, 48)
	_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(_line)
	for row: Array in ROWS:
		v.add_child(_row(row))
	v.add_child(_row(BOTTOM))
	add_child(_ring)   # over the keys (a PanelContainer gives it the whole keyboard)
	_relabel()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_bottom = -10.0


func _row(words: Array) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", GAP)
	var buttons: Array[Button] = []
	for word: String in words:
		var size := Vector2(WIDE.get(word, KEY_SIZE.x), KEY_SIZE.y)
		var color := UiKit.GREEN if word == DONE else UiKit.BLUE if word in [SHIFT, ENTER] else \
			UiKit.ORANGE if word == DELETE else OnlineUi.PURPLE if word == SHOW else Color()
		var b := UiKit.big_button(word, color, size)
		b.name = "Key_" + word
		b.focus_mode = Control.FOCUS_NONE   # a key never takes the box's focus
		b.add_theme_font_size_override("font_size", KEY_FONT if word.length() == 1 else 26)
		b.set_meta(&"pad_skip", true)   # PadFocus never focuses a key: the keyboard has the pad itself
		b.pressed.connect(_press.bind(word))
		_keys[word] = b
		buttons.append(b)
		h.add_child(b)
	_rows.append(buttons)
	return h


## The key for `word` (a letter either way round).
func key(word: String) -> Button:
	return _keys.get(word if word.length() > 1 else word.to_lower())


## What the box holds now (the keyboard's own line): a secret box's as its dots (owner #105: a password is never shown,
## read aloud or put in any words unless the child presses SHOW).
func shown_text() -> String:
	if target == null or not is_instance_valid(target):
		return ""
	if is_secret(target):
		var dot := (target as LineEdit).secret_character
		return (dot if dot != "" else "•").repeat((target as LineEdit).text.length())
	return str(target.get("text"))


## A box that keeps its words secret (a password field).
static func is_secret(c: Control) -> bool:
	return c is LineEdit and (c as LineEdit).secret


## The key the highlight is on, as it shows.
func selected_word() -> String:
	var b := _selected()
	return b.text if b else ""


## One frame (VrUi): up for the focused box, away when the focus moves on.
func step() -> void:
	var f := canvas.gui_get_focus_owner() if canvas else null
	var box: Control = f if is_box(f) and not is_ancestor_of(f) else null
	if _dismissed != null and _dismissed.get_ref() != box:
		_dismissed = null   # the focus left the box DONE put the keyboard away from
	if box == null or (_dismissed != null and _dismissed.get_ref() == box):
		_hide()
		return
	if box != target or not visible:
		_show(box)
	var typed := shown_text()
	_line.text = typed if typed != "" else str(target.get("placeholder_text"))
	_line.modulate.a = 1.0 if typed != "" else 0.55
	_show_key()


## A box the keyboard types into: an editable LineEdit or TextEdit that shows.
static func is_box(c: Control) -> bool:
	if c == null or not c.is_visible_in_tree():
		return false
	return (c is LineEdit and (c as LineEdit).editable) or (c is TextEdit and (c as TextEdit).editable)


func _show(box: Control) -> void:
	target = box
	visible = true
	_sel = Vector2i.ZERO
	_shift = false
	_relabel()
	PadFocus.keyboard = self
	if box is LineEdit and not (box as LineEdit).is_editing():
		(box as LineEdit).edit()


func _hide() -> void:
	if PadFocus.keyboard == self:
		PadFocus.keyboard = null
	if not visible:
		return
	visible = false
	target = null


func _press(word: String) -> void:
	match word:
		SHIFT:
			_shift = not _shift
			_relabel()
		DONE:
			_dismissed = weakref(target)
			_hide()
		SHOW:
			_toggle_secret()
		SPACE:
			_send.call_deferred(KEY_SPACE, 32)
		DELETE:
			_send.call_deferred(KEY_BACKSPACE, 0)
		ENTER:
			_send.call_deferred(KEY_ENTER, 0)
		_:
			var ch := word.to_upper() if _shift else word
			_send.call_deferred(KEY_NONE, ch.unicode_at(0))
			if _shift:
				_shift = false
				_relabel()


## A key's press and release into the canvas (after the click that pressed it), into the box's focus.
func _send(code: Key, unicode: int) -> void:
	if target == null or not is_instance_valid(target) or canvas == null:
		return
	if target is LineEdit and not (target as LineEdit).is_editing():
		(target as LineEdit).edit()
	for down: bool in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.unicode = unicode
		e.pressed = down
		canvas.push_input(e)


## SHOW / HIDE for a password box only; its word follows the box.
func _show_key() -> void:
	var b := _keys[SHOW] as Button
	var shows := target is LineEdit and (target.has_meta(SECRET_BOX) or is_secret(target))
	if shows and not target.has_meta(SECRET_BOX):
		target.set_meta(SECRET_BOX, true)   # still a password box after SHOW (its words showing)
	b.visible = shows
	if shows:
		b.text = PasswordRules.SHOW if is_secret(target) else PasswordRules.HIDE


## SHOW / HIDE: the field's own toggle when it has one (PasswordField: its SHOW button follows), else the box's.
func _toggle_secret() -> void:
	if not target is LineEdit:
		return
	var host := target.get_parent()
	if host != null and host.has_method(&"toggle"):
		host.call(&"toggle")
	else:
		(target as LineEdit).secret = not (target as LineEdit).secret
	_show_key()


func _relabel() -> void:
	for row: Array in ROWS:
		for word: String in row:
			(_keys[word] as Button).text = word.to_upper() if _shift else word
	if _keys.has(SHIFT):
		(_keys[SHIFT] as Button).modulate = Color(1.3, 1.3, 1.0) if _shift else Color.WHITE
	_paint_selection()

# --- The pad (PadFocus.keyboard) ---

## A pad event while the keyboard shows: true when it was the keyboard's (every one but the menu button's pause).
func pad_input(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		var b := event as InputEventJoypadButton
		if b.button_index == JOY_BUTTON_START:
			return false
		if not b.pressed:
			return true
		match b.button_index:
			JOY_BUTTON_DPAD_LEFT:
				_move(Vector2i.LEFT)
			JOY_BUTTON_DPAD_RIGHT:
				_move(Vector2i.RIGHT)
			JOY_BUTTON_DPAD_UP:
				_move(Vector2i.UP)
			JOY_BUTTON_DPAD_DOWN:
				_move(Vector2i.DOWN)
			JOY_BUTTON_A:
				var k := _selected()
				if k:
					k.pressed.emit()
			JOY_BUTTON_B:
				_press(DONE)
		return true
	if event is InputEventJoypadMotion:
		var m := event as InputEventJoypadMotion
		if m.axis == JOY_AXIS_LEFT_X or m.axis == JOY_AXIS_LEFT_Y:
			var d := Vector2i.ZERO
			if absf(m.axis_value) >= STICK_PUSH:
				d = Vector2i(signi(int(signf(m.axis_value))), 0) if m.axis == JOY_AXIS_LEFT_X \
					else Vector2i(0, signi(int(signf(m.axis_value))))
			var was := _stick.x if m.axis == JOY_AXIS_LEFT_X else _stick.y
			var now := d.x if m.axis == JOY_AXIS_LEFT_X else d.y
			if now != 0 and now != was:
				_move(d)
			if m.axis == JOY_AXIS_LEFT_X:
				_stick.x = now
			else:
				_stick.y = now
		return true
	return false


func _move(dir: Vector2i) -> void:
	var row := clampi(_sel.y + dir.y, 0, _rows.size() - 1)
	var col := _sel.x + dir.x
	if dir.y != 0 and row != _sel.y:   # the key above or below: the nearest by where it stands
		var from := _selected()
		var x := from.get_global_rect().get_center().x if from and from.is_inside_tree() else 0.0
		var best := 0
		var best_d := INF
		for i in (_rows[row] as Array).size():
			var b := (_rows[row] as Array)[i] as Button
			var d := absf(b.get_global_rect().get_center().x - x) if b.is_inside_tree() else float(absi(i - _sel.x))
			if d < best_d:
				best_d = d
				best = i
		col = best
	_sel = Vector2i(clampi(col, 0, (_rows[row] as Array).size() - 1), row)
	_paint_selection()


func _selected() -> Button:
	if _sel.y < 0 or _sel.y >= _rows.size():
		return null
	var row := _rows[_sel.y] as Array
	return row[clampi(_sel.x, 0, row.size() - 1)] as Button


func _paint_selection() -> void:
	_ring.key = _selected() if PadFocus.pad_active() or Vr.active() else null
	_ring.queue_redraw()


## The pad's highlight: the focus ring round the selected key, over the keys (never takes a tap).
class Ring:
	extends Control
	var key: Control

	func _init() -> void:
		name = "KeyRing"
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		if key != null:
			queue_redraw()

	func _draw() -> void:
		if key == null or not is_instance_valid(key) or not key.is_visible_in_tree():
			return
		var r := Rect2(key.global_position - global_position, key.size).grow(6.0)
		draw_style_box(UiKit.focus_shadow(), r.grow(2.0))
		draw_style_box(UiKit.focus_ring(), r)
