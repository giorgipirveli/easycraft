class_name TheaterStill
extends Control
## The desktop and headless stand-in for the Theater's player (M3 Task 17): a still picture drawn
## from the video (its channel's colour, a pattern from its id and a big play sign) with the title
## under it. It is what `TheaterPanel` shows where Android shows the real embedded player, so every
## rule and button can be tried without a phone.

var video: Dictionary = {}
var _title := Label.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_constant_override("outline_size", 8)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.anchor_left = 0.0
	_title.anchor_right = 1.0
	_title.anchor_top = 0.66
	_title.anchor_bottom = 0.95
	_title.offset_left = 18.0
	_title.offset_right = -18.0
	add_child(_title)


func show_video(v: Dictionary) -> void:
	video = v
	_title.text = str(v.get("title", ""))
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var base: Color = video.get("color", TheaterChannels.DEFAULT_COLOR)
	draw_rect(r, base.darkened(0.55))
	# A few soft stripes that differ per video, so NEXT visibly changes the picture.
	var h := hash(str(video.get("id", "")))
	for i in 5:
		var y := size.y * (0.08 + 0.12 * i)
		var w := size.x * (0.3 + 0.1 * ((h >> (i * 3)) & 7))
		draw_rect(Rect2(Vector2((size.x - w) * 0.5, y), Vector2(w, size.y * 0.06)), base.lightened(0.1 * i).darkened(0.2))
	var c := Vector2(size.x * 0.5, size.y * 0.42)
	var rad := minf(size.x, size.y) * 0.2
	draw_circle(c, rad, Color(1, 1, 1, 0.9))
	var t := rad * 0.5
	draw_colored_polygon(PackedVector2Array([c + Vector2(-t * 0.7, -t), c + Vector2(t, 0), c + Vector2(-t * 0.7, t)]), base.darkened(0.3))
