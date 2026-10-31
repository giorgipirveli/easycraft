class_name SavingBar
extends Control
## A have/need bar of gold (M3 Task 21b; research R3): gold fills it toward something on the saving list; full, it
## turns green with a tick. Drawn in code (no textures). Used on the book's SAVING page and, small, under the
## HUD's gold (GoldCounter) for the first thing on the list.

const EMPTY := Color(0.1, 0.08, 0.05, 0.45)
const FILL := Color("ffcf3a")
const FULL := Color("5ccf5c")
const RIM := Color(0.25, 0.16, 0.08, 0.9)

var have := 0
var need := 1
var show_words := true
var font_size := 18

var _bg := StyleBoxFlat.new()
var _fill := StyleBoxFlat.new()


func _init(px: Vector2 = Vector2(300, 28)) -> void:
	custom_minimum_size = px
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_have_need(hn: Vector2i) -> void:
	have = maxi(hn.x, 0)
	need = maxi(hn.y, 1)
	queue_redraw()


func fraction() -> float:
	return clampf(float(have) / float(need), 0.0, 1.0)


func is_full() -> bool:
	return have >= need


func words() -> String:
	return SavingRules.bar_words(Vector2i(have, need))


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var radius := int(size.y * 0.5)
	_bg.bg_color = EMPTY
	_bg.border_color = RIM
	_bg.set_border_width_all(2)
	_bg.set_corner_radius_all(radius)
	draw_style_box(_bg, r)
	var f := fraction()
	if f > 0.0:
		_fill.bg_color = FULL if is_full() else FILL
		_fill.set_corner_radius_all(radius)
		draw_style_box(_fill, Rect2(Vector2(2, 2), Vector2(maxf((size.x - 4) * f, size.y - 4), size.y - 4)))
	if show_words:
		var font := get_theme_default_font()
		var text := words()
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var at := Vector2((size.x - w) * 0.5, size.y * 0.5 + font_size * 0.35)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, 0.6))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
