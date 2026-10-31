class_name PhotoFrameOverlay
extends Control
## Draws the chosen photo frame (PhotoFrames) over the picture; it is saved with the photo. Only draw
## calls on a full-screen Control: no textures, no materials.

const PAPER := Color(0.97, 0.96, 0.92)
const INK := Color(0.2, 0.2, 0.26)
const FILM := Color(0.06, 0.06, 0.07)
const GOLD := Color(0.93, 0.74, 0.2)
const GOLD_DARK := Color(0.55, 0.38, 0.05)
const STAR_COLORS: Array[Color] = [Color("ffd23f"), Color("ff6fa8"), Color("54d2ff"), Color("7ee06a")]

var frame := PhotoFrames.Frame.NONE:
	set(value):
		frame = value
		visible = value != PhotoFrames.Frame.NONE
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	resized.connect(queue_redraw)


func _draw() -> void:
	var inner := PhotoFrames.inner_rect(frame, size)
	var h := size.y
	match frame:
		PhotoFrames.Frame.PHOTO:
			_border(inner, PAPER)
			var font := get_theme_default_font()
			var fs := int(h * 0.055)
			var y := inner.end.y + (size.y - inner.end.y) * 0.5 + fs * 0.35
			draw_string(font, Vector2(0, y), "EasyCraft", HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, INK)
		PhotoFrames.Frame.FILM:
			_border(inner, FILM)
			var hole := Vector2(h * 0.035, h * 0.05)
			var step := h * 0.075
			var x := step * 0.5
			while x < size.x:
				for bar_top: float in [0.0, inner.end.y]:
					var y := bar_top + (h * 0.11 - hole.y) * 0.5
					draw_rect(Rect2(Vector2(x, y), hole), PAPER.darkened(0.08))
				x += step
		PhotoFrames.Frame.STARS:
			_border(inner, Color(1.0, 0.55, 0.75))
			var r := h * 0.06
			var corners: Array[Vector2] = [inner.position, Vector2(inner.end.x, inner.position.y),
				Vector2(inner.position.x, inner.end.y), inner.end]
			for i in corners.size():
				_star(corners[i], r, STAR_COLORS[i % STAR_COLORS.size()])
			var n := 6
			for i in n:   # small stars along the top and bottom edges
				var sx := inner.position.x + inner.size.x * (i + 0.5) / n
				_star(Vector2(sx, inner.position.y), r * 0.45, STAR_COLORS[(i + 1) % STAR_COLORS.size()])
				_star(Vector2(sx, inner.end.y), r * 0.45, STAR_COLORS[(i + 2) % STAR_COLORS.size()])
		PhotoFrames.Frame.GOLD:
			_border(inner, GOLD)
			var line := maxf(2.0, h * 0.006)
			draw_rect(inner.grow(-line * 0.5), GOLD_DARK, false, line)
			draw_rect(Rect2(Vector2.ZERO, size).grow(-line * 1.5), GOLD_DARK, false, line)
			for c: Vector2 in [inner.position, Vector2(inner.end.x, inner.position.y), Vector2(inner.position.x, inner.end.y), inner.end]:
				draw_circle(c, h * 0.035, GOLD)
				draw_circle(c, h * 0.018, GOLD_DARK)


## Fills everything outside `inner`.
func _border(inner: Rect2, color: Color) -> void:
	draw_rect(Rect2(0, 0, size.x, inner.position.y), color)
	draw_rect(Rect2(0, inner.end.y, size.x, size.y - inner.end.y), color)
	draw_rect(Rect2(0, inner.position.y, inner.position.x, inner.size.y), color)
	draw_rect(Rect2(inner.end.x, inner.position.y, size.x - inner.end.x, inner.size.y), color)


func _star(center: Vector2, radius: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var r := radius if i % 2 == 0 else radius * 0.45
		var a := -PI * 0.5 + i * PI / 5.0
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, color)
	pts.append(pts[0])
	draw_polyline(pts, Color(1, 1, 1, 0.9), maxf(1.5, radius * 0.08), true)
