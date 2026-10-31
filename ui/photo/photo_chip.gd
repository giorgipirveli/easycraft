class_name PhotoChip
extends TouchButton
## A photo-mode button (M3 Task 16): a TouchButton (multi-touch; on desktop a mouse click arrives as
## an emulated touch) that also draws a picture instead of words: the round shutter, a close cross, or
## a colour swatch behind its label (filters). The HUD's photo button draws HudIcons' camera (M2 Task 17).

enum Glyph { NONE, SHUTTER, CLOSE }

var glyph := Glyph.NONE
var swatch := Color(0, 0, 0, 0)

var _box := StyleBoxFlat.new()


func _draw() -> void:
	match glyph:
		Glyph.SHUTTER:
			_draw_shutter()
			return
		Glyph.CLOSE:
			super()
			var c := size * 0.5
			var r := size.x * 0.2
			var w := maxf(4.0, size.x * 0.07)
			draw_line(c - Vector2(r, r), c + Vector2(r, r), Color.WHITE, w, true)
			draw_line(c + Vector2(-r, r), c + Vector2(r, -r), Color.WHITE, w, true)
			return
	if swatch.a <= 0.0:
		super()
		return
	_box.bg_color = swatch.lightened(0.25) if is_down() else swatch
	_box.border_color = Color(1, 0.85, 0.2) if selected else Color(1, 1, 1, 0.85)
	_box.set_border_width_all(5 if selected else 2)
	_box.set_corner_radius_all(12)
	draw_style_box(_box, Rect2(Vector2.ZERO, size))
	var font := get_theme_default_font()
	var h := font.get_height(font_size)
	draw_string_outline(font, Vector2(0, size.y * 0.5 + h * 0.3), atr(text), HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, 5, Color(0, 0, 0, 0.7))
	draw_string(font, Vector2(0, size.y * 0.5 + h * 0.3), atr(text), HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Color.WHITE)   # M3 Task 21a


## The shutter: a big white ring around a white disc that darkens while pressed.
func _draw_shutter() -> void:
	var c := size * 0.5
	var r := size.x * 0.5
	draw_circle(c, r, Color(0, 0, 0, 0.25))
	draw_arc(c, r - 5.0, 0.0, TAU, 64, Color.WHITE, 8.0, true)
	draw_circle(c, r * 0.72, Color(0.8, 0.8, 0.82) if is_down() else Color.WHITE)
