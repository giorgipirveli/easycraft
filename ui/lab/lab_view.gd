class_name LabView
extends Control
## Spec §23.1: an experiment's small 2D scene (the Lab's step 2, TRY IT), drawn from its model (LabModel) on a paper
## card, with big buttons for every step (taps always work; nothing is dragged). A tap changes the model, redraws and
## tells the Lab (`changed`), which shows what just happened and opens WHAT HAPPENED? once the model is done.
## `make` picks the view for a model's kind.

signal changed

const SIZE := Vector2(1180, 340)
const PAPER := Color("fdf6e3")
const INK := Color("1f2a4a")
const SOFT := Color("6b5a44")
const THING_BUTTON := Vector2(132, 150)

var model: LabModel


func _init(m: LabModel = null) -> void:
	model = m
	name = "Scene"
	custom_minimum_size = SIZE
	clip_contents = true


static func make(m: LabModel) -> LabView:
	if m is LabTank or m is LabMagnet:
		return LabThingsView.new(m)
	if m is LabHeat:
		return LabHeatView.new(m)
	if m is LabColours:
		return LabColoursView.new(m)
	if m is LabPlants:
		return LabPlantsView.new(m)
	if m is LabCircuit:
		return LabCircuitView.new(m)
	return LabView.new(m)


## After a tap (each view plays its own sound): redraw, refresh the buttons, tell the Lab.
func tapped() -> void:
	refresh()
	changed.emit()


## Shows the model's state (subclasses update their buttons and labels, then call this).
func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	paper(Rect2(Vector2.ZERO, size))


func paper(r: Rect2) -> void:
	draw_style_box(UiKit.box(PAPER, 18, 0), r)


## A big button placed at `pos` in the scene.
func place_button(text: String, color: Color, pos: Vector2, min_size: Vector2, font_size: int = 26) -> Button:
	var b := SchoolUi.button(text, color, min_size)
	b.add_theme_font_size_override("font_size", font_size)
	add_child(b)
	b.position = pos
	b.size = b.get_combined_minimum_size()
	return b


## A thing's button: its picture, its name and a line under it (what it did), placed at `pos`.
func thing_button(t: Dictionary, pos: Vector2) -> Button:
	var b := Button.new()
	b.name = "Thing_" + str(t.get("thing", ""))
	b.custom_minimum_size = THING_BUTTON
	b.focus_mode = Control.FOCUS_NONE
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := UiKit.box(Color("ffffff") if state != "pressed" else Color("e8f3ff"), 14, 6)
		box.border_color = Color("c9b99a")
		box.set_border_width_all(3)
		b.add_theme_stylebox_override(state, box)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var pic := LabThings.Picture.new(str(t.get("thing", "")), 74.0)
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(pic)
	var n := _label(str(t.get("name", "")), 19, INK)
	n.name = "Name"
	v.add_child(n)
	var what := _label("", 17, SOFT)
	what.name = "What"
	v.add_child(what)
	b.add_child(v)
	add_child(b)
	b.position = pos
	b.size = THING_BUTTON
	return b


static func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## A label placed in the scene (words it shows, read aloud with the page).
func place_label(text: String, font_size: int, color: Color, pos: Vector2, width: float,
		align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := _label(text, font_size, color)
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = width
	add_child(l)
	l.position = pos
	l.size.x = width
	return l


## Draws `text` centred on `at` (words that are part of the picture).
func text_at(text: String, at: Vector2, font_size: int, color: Color = INK) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, at + Vector2(-w * 0.5, font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
