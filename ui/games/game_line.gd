class_name GameLine
extends PanelContainer
## The HUD's round line for the co-op games (M4 Wave 3, agent H): top-centre where the wave line sits (a
## round never runs with a wave or the boss), short words and the round's clock — "Hide! 0:27", "Find them!
## 1 of 3 found · 2:41", "Stars: 12 · 1:05 · Best 23" (GameWords). A label, never a button: it never takes
## a tap. Hidden while no round is on; the GamesDirector's line_changed drives it.

const FONT_SIZE := 20
const PANEL := Color(0.08, 0.1, 0.17, 0.85)

var label := Label.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL
	box.set_corner_radius_all(16)
	box.content_margin_left = 14
	box.content_margin_right = 14
	add_theme_stylebox_override("panel", box)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	add_child(label)


## The round's line now ("" hides it).
func show_line(text: String) -> void:
	label.text = text
	visible = text != ""
