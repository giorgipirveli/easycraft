class_name PadGlyph
extends Control
## Owner #90: a game controller's face button drawn as the child sees it on the pad (the CONTROLLER card): a PlayStation's
## Cross, Circle, Square and Triangle in their colours on a dark button, or an Xbox's (and any other pad's) coloured
## A, B, X and Y. Drawn, not typed: the game's font has no ✕ ○ □ △.

const SIDE := 34.0
const PS_COLORS := {JOY_BUTTON_A: Color("7fb2ff"), JOY_BUTTON_B: Color("ff6b6b"), JOY_BUTTON_X: Color("ff8ad8"),
	JOY_BUTTON_Y: Color("38d6a0")}
const XBOX_COLORS := {JOY_BUTTON_A: Color("3fb34f"), JOY_BUTTON_B: Color("e2433b"), JOY_BUTTON_X: Color("3a7be8"),
	JOY_BUTTON_Y: Color("e8b400")}

var button: int
var family: StringName


func _init(b: int, fam: StringName) -> void:
	button = b
	family = fam
	custom_minimum_size = Vector2(SIDE, SIDE)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 1.0
	if family == GamepadRules.PLAYSTATION:
		draw_circle(c, r, Color(0.12, 0.13, 0.18))
		var col: Color = PS_COLORS.get(button, Color.WHITE)
		var s := r * 0.48
		var w := maxf(2.5, r * 0.16)
		match button:
			JOY_BUTTON_A:   # Cross
				draw_line(c + Vector2(-s, -s), c + Vector2(s, s), col, w, true)
				draw_line(c + Vector2(-s, s), c + Vector2(s, -s), col, w, true)
			JOY_BUTTON_B:   # Circle
				draw_arc(c, s, 0.0, TAU, 32, col, w, true)
			JOY_BUTTON_X:   # Square
				draw_rect(Rect2(c - Vector2(s, s) * 0.9, Vector2(s, s) * 1.8), col, false, w)
			JOY_BUTTON_Y:   # Triangle
				var pts := PackedVector2Array([c + Vector2(0, -s * 1.05), c + Vector2(s * 1.05, s * 0.75),
					c + Vector2(-s * 1.05, s * 0.75), c + Vector2(0, -s * 1.05)])
				draw_polyline(pts, col, w, true)
		return
	draw_circle(c, r, XBOX_COLORS.get(button, Color(0.4, 0.4, 0.45)))
	var word := GamepadRules.button_word(button, family)
	var font := get_theme_default_font()
	var fs := int(r * 1.1)
	var at := Vector2(0, c.y + font.get_ascent(fs) * 0.5 - font.get_descent(fs) * 0.3)
	draw_string(font, at, word, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color.WHITE)
