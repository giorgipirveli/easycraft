class_name RiddlePanel
extends Control
## A riddle note or the Wanderer's riddle, shown big (M2 Task 16). Children who can't read yet go by the
## pictures: a note shows its pictures in a row (a temple's plates in the order to step on them, with
## arrows between), and the Wanderer's three answers are big picture buttons with a short word under each.
## Texts stay short, so they can be read aloud later. A full-screen overlay: a tap outside closes it.

const PICTURE_SIZE := Vector2(96, 96)
const CHOICE_SIZE := Vector2(150, 150)

var text_label := Label.new()
var _panel := PanelContainer.new()
var _pictures := HBoxContainer.new()
var _choices := HBoxContainer.new()
var _on_pick: Callable


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("f6ecd0")
	paper.border_color = Color("9c6b34")
	paper.set_border_width_all(6)
	paper.set_corner_radius_all(18)
	paper.set_content_margin_all(26)
	_panel.add_theme_stylebox_override("panel", paper)
	add_child(_panel)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(column)
	TextSize.mark(text_label, 34)   # M5 Task 1: TEXT SIZE
	text_label.add_theme_color_override("font_color", Color("3b2a18"))
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size.x = 560
	column.add_child(ReadAloud.with_speaker(text_label, column))   # M3 Task 21a: the speaker reads the note
	for row in [_pictures, _choices]:
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 16)
		column.add_child(row)


## A note: its text and pictures (in order, arrows between them).
func show_note(text: String, pictures: Array) -> void:
	_clear()
	text_label.text = text
	ReadAloud.auto(text)   # M3 Task 21a: "Read to me"
	for i in pictures.size():
		if i > 0:
			var arrow := Label.new()
			arrow.text = "→"
			arrow.add_theme_font_size_override("font_size", 56)
			arrow.add_theme_color_override("font_color", Color("9c6b34"))
			_pictures.add_child(arrow)
		_pictures.add_child(_picture(int(pictures[i]), PICTURE_SIZE))
	_open()


## The Wanderer's riddle: the question and three picture buttons; on_pick(index) gets the tapped one.
func show_riddle(question: String, choices: Array, on_pick: Callable) -> void:
	_clear()
	text_label.text = question
	ReadAloud.auto(question)   # M3 Task 21a: "Read to me"
	_on_pick = on_pick
	for i in choices.size():
		var b := Button.new()
		b.custom_minimum_size = CHOICE_SIZE
		b.icon = Pictures.texture(int(choices[i]))
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.text = Riddles.word(int(choices[i]))
		TextSize.mark(b, 28)   # M5 Task 1: TEXT SIZE
		b.pressed.connect(_pick.bind(i))
		_choices.add_child(b)
	_open()


func choice_buttons() -> Array[Button]:
	var out: Array[Button] = []
	for c in _choices.get_children():
		if c is Button and not c.is_queued_for_deletion():
			out.append(c)
	return out


func picture_ids() -> Array[int]:
	var out: Array[int] = []
	for c in _pictures.get_children():
		if c is TextureRect and not c.is_queued_for_deletion():
			out.append(int(c.get_meta(&"picture")))
	return out


func close() -> void:
	visible = false
	_on_pick = Callable()


func _pick(i: int) -> void:
	Audio.play(&"ui_click")
	var pick := _on_pick
	close()
	if pick.is_valid():
		pick.call(i)


func _open() -> void:
	visible = true
	Audio.play(&"ui_click")


func _clear() -> void:
	for row in [_pictures, _choices]:
		for c in row.get_children():
			row.remove_child(c)
			c.queue_free()


func _picture(id: int, size: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Pictures.texture(id)
	t.custom_minimum_size = size
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.set_meta(&"picture", id)
	return t


## Taps on the dimmed area (outside the paper) close it.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()
