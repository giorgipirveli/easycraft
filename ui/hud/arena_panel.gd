class_name ArenaPanel
extends Control
## Monster Wave's result panel (owner feedback #44, spec §12.20): a centred card after a run — "What a run!", the
## time, the waves and the gold (ArenaRules.result_line), "A new best!" — with PLAY AGAIN and LEAVE as equal big
## buttons; after the raid boss "You beat the raid boss!" with NEXT UNIVERSE (when the next universe is there and
## the child plays alone) and STAY. A tap hides it and says what was chosen (the sandbox acts on it).

signal again_pressed
signal leave_pressed
signal next_pressed

const SIZE := Vector2(640, 360)
const BUTTON := Vector2(270, 116)
const WON_TITLE := "You beat the raid boss!"
const RUN_TITLE := "What a run!"
const BEST_WORDS := "A new best!"
const SOON_WORDS := "The next universe is coming soon!"

var _title := Label.new()
var _line := Label.new()
var _best := Label.new()
var _note := Label.new()
var _row := HBoxContainer.new()


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -SIZE.x * 0.5
	offset_right = SIZE.x * 0.5
	offset_top = -SIZE.y * 0.5 - 30.0
	offset_bottom = SIZE.y * 0.5 - 30.0
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.1, 0.17, 0.94)
	box.set_corner_radius_all(22)
	box.set_content_margin_all(22)
	box.border_color = Color("ffd23f")
	box.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel", box)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	for l: Label in [_title, _line, _best, _note]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		l.add_theme_constant_override("outline_size", 6)
		col.add_child(l)
	_title.add_theme_font_size_override("font_size", 38)
	_title.add_theme_color_override("font_color", Color("ffd23f"))
	_line.add_theme_font_size_override("font_size", 26)
	_best.add_theme_font_size_override("font_size", 24)
	_best.add_theme_color_override("font_color", Color("8cf07a"))
	_note.add_theme_font_size_override("font_size", 20)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 24)
	col.add_child(_row)


## Shows a run's result (ArenaDirector.result_shown).
func show_result(r: Dictionary) -> void:
	var won := bool(r.get("won", false))
	_title.text = WON_TITLE if won else RUN_TITLE
	_line.text = ArenaRules.result_line(float(r.get("seconds", 0.0)), int(r.get("cleared", 0)), int(r.get("gold", 0)))
	_best.text = BEST_WORDS if bool(r.get("new_best", false)) else ""
	_best.visible = _best.text != ""
	var next := int(r.get("next", 0))
	_note.text = SOON_WORDS if won and next <= 0 else ""
	_note.visible = _note.text != ""
	for b in _row.get_children():
		_row.remove_child(b)
		b.queue_free()
	if won:
		if next > 0:
			_add_button(ArenaRules.NEXT_WORD, UiKit.ORANGE, next_pressed)
		_add_button(ArenaRules.STAY_WORD, UiKit.GREEN, again_pressed)
	else:
		_add_button(ArenaRules.AGAIN_WORD, UiKit.GREEN, again_pressed)
		_add_button(ArenaRules.LEAVE_WORD, UiKit.BLUE, leave_pressed)
	visible = true
	move_to_front()


func _add_button(word: String, color: Color, said: Signal) -> void:
	var b := UiKit.big_button(word, color, BUTTON)
	b.add_theme_font_size_override("font_size", 28)   # the HUD has no menu theme: big words of their own
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	b.add_theme_constant_override("outline_size", 4)
	b.pressed.connect(func() -> void:
		visible = false
		said.emit())
	_row.add_child(b)


func buttons() -> Array[Button]:
	var out: Array[Button] = []
	for b in _row.get_children():
		if b is Button and not b.is_queued_for_deletion():
			out.append(b)
	return out


func button_words() -> Array[String]:
	var out: Array[String] = []
	for b in buttons():
		out.append(b.text)
	return out


func title_text() -> String:
	return _title.text


func line_text() -> String:
	return _line.text


func best_text() -> String:
	return _best.text


func note_text() -> String:
	return _note.text


## Taps on the panel never reach the world behind it.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		accept_event()
