class_name NumberAnswerPad
extends VBoxContainer
## Owner #68 (spec §22.1): a number typed on the School's own pad (NumberPad: digits, DELETE, and `.` `/` `-` only when
## the answer needs them), shown grouped by thousands as it is typed (a year is not: "1850"). A keyboard works too
## (desktops and browsers).

signal changed
signal submitted

const KEY := Vector2(150, 64)

var keys: Array[String] = []   # the extra keys
var grouped := true            # false for a year
var typed := ""
var box := Label.new()
var buttons := {}   # key -> Button
var _locked := false


func _init(ex: Dictionary) -> void:
	keys = ExerciseCheck.pad_keys(ex)
	grouped = ExerciseCheck.grouped(ex)
	add_theme_constant_override("separation", 10)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(3 * KEY.x + 20, 76)
	var look := StyleBoxFlat.new()
	look.bg_color = Color.WHITE
	look.set_corner_radius_all(14)
	look.set_border_width_all(4)
	look.border_color = SchoolUi.INK
	frame.add_theme_stylebox_override("panel", look)
	box.name = "Typed"
	box.text = NumberPad.shown("")
	box.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_theme_font_size_override("font_size", 44)
	box.add_theme_color_override("font_color", SchoolUi.INK)
	box.add_theme_constant_override("outline_size", 0)
	frame.add_child(box)
	add_child(frame)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	var layout: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", NumberPad.DELETE, "0"]
	layout.append_array(keys)
	for k in layout:
		var b := SchoolUi.button(k, UiKit.BLUE if k == NumberPad.DELETE else (UiKit.ORANGE if keys.has(k) else Color()), KEY)
		b.name = "Key_" + ("DEL" if k == NumberPad.DELETE else {".": "DOT", "/": "SLASH", "-": "MINUS"}.get(k, k))
		if k == NumberPad.DELETE:
			b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(press.bind(k))
		buttons[k] = b
		grid.add_child(b)
	add_child(grid)


func press(key: String) -> void:
	if _locked:
		return
	typed = NumberPad.press(typed, key, keys)
	box.text = NumberPad.shown(typed, grouped)
	changed.emit()


func response() -> Variant:
	return typed


func is_ready() -> bool:
	return NumberAnswer.is_number(typed)


func mark_wrong() -> void:
	pass   # the number stays, so the child can change it


func mark_right() -> void:
	box.add_theme_color_override("font_color", Color("1f8a3a"))


func lock() -> void:
	_locked = true
	for k: String in buttons:
		(buttons[k] as Button).disabled = true


func show_answer(answer: Variant) -> void:
	typed = str(answer)
	box.text = NumberPad.shown(typed, grouped)
	mark_right()


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or _locked or not is_visible_in_tree():
		return
	var ch := char(k.unicode) if k.unicode > 0 else ""
	if ch.length() == 1 and ((ch >= "0" and ch <= "9") or keys.has(ch)):
		press(ch)
	elif k.keycode == KEY_BACKSPACE:
		press(NumberPad.DELETE)
	elif k.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		submitted.emit()
	else:
		return
	get_viewport().set_input_as_handled()
