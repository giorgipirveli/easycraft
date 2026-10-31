class_name DiscoveryStrip
extends Control
## Owner #132 (W1), stage 2: a small card at the top middle while a crystal's play runs (flat; in a headset the crystal
## itself shows it all): a speaker that says the challenge again, what to do as numbers or a picture (MAKE: the number;
## ORDER: rising steps, smallest first), and a cross that ends the play quietly (nothing lost). No words to read
## (owner #133). Only the card takes a touch; the rest is the world's.

signal left

var card := PanelContainer.new()
var goal := Label.new()
var steps := Steps.new()
var cross := Button.new()
var _line := ""


## Rising steps, smallest first (ORDER's picture).
class Steps:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(110, 72)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x / 4.0
		for i in 4:
			var h := size.y * (0.3 + 0.7 * i / 3.0)
			draw_rect(Rect2(i * w + 4, size.y - h, w - 8, h), Color("ffe066").lerp(Color("4fd1ff"), i / 3.0))


func _init() -> void:
	name = "DiscoveryStrip"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	card.name = "Card"
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.92), 22, 10))
	card.anchor_left = 0.5
	card.anchor_right = 0.5
	card.offset_left = -170
	card.offset_top = HootCard.SPOT.y
	add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var speaker := ReadAloud.button(func() -> String: return _line, 64.0)
	speaker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(speaker)
	goal.name = "Goal"
	goal.add_theme_font_size_override("font_size", 52)
	goal.add_theme_color_override("font_color", Color("ffe066"))
	goal.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	goal.add_theme_constant_override("outline_size", 8)
	goal.custom_minimum_size = Vector2(150, 72)
	goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	goal.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	row.add_child(goal)
	row.add_child(steps)
	cross.name = "Leave"
	cross.custom_minimum_size = Vector2(64, 64)
	cross.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cross.add_theme_stylebox_override("normal", UiKit.box(Color(0.2, 0.24, 0.36), 32, 8))
	cross.add_theme_stylebox_override("hover", UiKit.box(Color(0.26, 0.3, 0.44), 32, 8))
	cross.add_theme_stylebox_override("pressed", UiKit.box(Color(0.16, 0.18, 0.28), 32, 8))
	var x := HootCard.Cross.new()
	x.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cross.add_child(x)
	cross.pressed.connect(func() -> void: left.emit())
	row.add_child(cross)


## Shows challenge `c` (its spoken line is what the speaker says again).
func show_for(c: Dictionary) -> void:
	_line = str(c.get("say", ""))
	var make := str(c.get("kind", "")) == "make"
	goal.visible = make
	goal.text = str(c.get("shown", "")) if make else ""
	steps.visible = not make
	if not visible:
		visible = true
		UiMotion.pop_in(card)


func hide_strip() -> void:
	visible = false


func blockers() -> Array[Control]:
	return [card] as Array[Control]
