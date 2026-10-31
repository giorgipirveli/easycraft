class_name MixAnswer
extends VBoxContainer
## The research's "mix the colour" (docs/design/school-curriculum-research.md §5.3): five paint pots (red, yellow, blue,
## white, black); a tap adds a drop to the bowl, which shows the mixed colour (ColourMix) and says the drops in words;
## CLEAR empties it. A miss keeps the bowl: add what it needs.

signal changed

const POT := Vector2(96, 72)

var target := ""
var drops := {}
var pots := {}          # paint -> Button
var clear_button: Button
var bowl: Control
var drops_label: Label
var _locked := false


func _init(ex: Dictionary) -> void:
	target = str(ex.get("target", ""))
	add_theme_constant_override("separation", 12)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bowl = Bowl.new(self)
	add_child(bowl)
	drops_label = SchoolUi.words("", 22, 540)
	add_child(drops_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	for p: String in ColourMix.PAINTS:
		var b := UiKit.big_button(p.to_upper(), Color(), POT)
		b.name = p.capitalize()
		b.focus_mode = Control.FOCUS_NONE
		var paint: Color = ColourMix.PAINT_COLOURS[p]
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(state, UiKit.box(paint.darkened(0.1 if state == "pressed" else 0.0), 14, 4))
		var ink := Color(0.12, 0.12, 0.15) if paint.get_luminance() > 0.55 else Color.WHITE
		for state: String in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(state, ink)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(add.bind(p))
		pots[p] = b
		row.add_child(b)
	add_child(row)
	clear_button = SchoolUi.button("CLEAR", Color(), Vector2(200, 64))
	clear_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	clear_button.pressed.connect(clear)
	add_child(clear_button)
	_relabel()


func add(paint: String) -> void:
	var total := 0
	for k: String in drops:
		total += int(drops[k])
	if _locked or not ColourMix.PAINTS.has(paint) or total >= ColourMix.MAX_DROPS:
		return
	drops[paint] = int(drops.get(paint, 0)) + 1
	_relabel()
	changed.emit()


func clear() -> void:
	if _locked:
		return
	drops.clear()
	_relabel()
	changed.emit()


func bowl_colour() -> Color:
	return ColourMix.colour(drops)


func response() -> Variant:
	return drops.duplicate()


func is_ready() -> bool:
	return not drops.is_empty()


func mark_wrong() -> void:
	pass   # the bowl stays: add what it needs, or CLEAR


func mark_right() -> void:
	bowl.queue_redraw()


func lock() -> void:
	_locked = true
	for p: String in pots:
		(pots[p] as Button).disabled = true
	clear_button.disabled = true


func show_answer(answer: Variant) -> void:
	drops = (answer as Dictionary).duplicate() if answer is Dictionary else {}
	_relabel()


func _relabel() -> void:
	drops_label.text = "In the bowl: " + ColourMix.words(drops) if not drops.is_empty() else "Tap the paints to add drops."
	bowl.queue_redraw()


## The bowl: a round dish of the mixed paint.
class Bowl:
	extends Control
	var owner_answer: MixAnswer

	func _init(o: MixAnswer) -> void:
		owner_answer = o
		custom_minimum_size = Vector2(540, 180)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c + Vector2(0, 6), 84.0, Color(0, 0, 0, 0.25))
		draw_circle(c, 84.0, Color("eeeeee"))
		draw_circle(c, 70.0, owner_answer.bowl_colour())
		draw_arc(c, 84.0, 0.0, TAU, 64, Color("bbbbbb"), 3.0)
