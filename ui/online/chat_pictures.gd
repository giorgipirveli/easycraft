class_name ChatPictures
extends RefCounted
## The quick-chat wheel's pictures (M4 Wave 2, Agent E), drawn with shapes like OnlineIcon's (no image
## files, nothing to license), so a child who can't read yet still knows each phrase: a waving hand
## (Hi!), an arrow (Follow me!), an eye (Look!), a ring buoy (Help!), a heart (Thanks!), a star (Good
## job!), stacked blocks (Let's build!) and a hand with motion lines (Bye!).

const KINDS: Array[StringName] = [&"hi", &"follow", &"look", &"help", &"thanks", &"star", &"build", &"bye"]


## Draws picture `kind` into `rect` of `canvas` in `color`.
static func draw(canvas: CanvasItem, kind: StringName, rect: Rect2, color: Color = Color.WHITE) -> void:
	var u := minf(rect.size.x, rect.size.y) / 16.0   # the picture is 16 x 16 units
	var c := rect.get_center()
	var dark := Color(0.08, 0.1, 0.17)
	match kind:
		&"hi":
			_hand(canvas, c + Vector2(0, 1) * u, u, color)
		&"bye":
			_hand(canvas, c + Vector2(1.5, 1) * u, u * 0.9, color)
			for i in 3:
				var r := (2.5 + i * 1.6) * u
				canvas.draw_arc(c + Vector2(1.5, -1) * u, r, PI * 1.05, PI * 1.35, 8, color, 0.8 * u, true)
		&"follow":
			canvas.draw_rect(Rect2(c + Vector2(-6.5, -1.6) * u, Vector2(7.5, 3.2) * u), color)
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(0.5, -5.5) * u, c + Vector2(7, 0) * u,
				c + Vector2(0.5, 5.5) * u]), color)
		&"look":
			var pts := PackedVector2Array()
			for i in 33:
				var a := TAU * i / 32.0
				pts.append(c + Vector2(cos(a) * 7.0, sin(a) * 4.2 * absf(sin(a)) * 1.0) * u)
			canvas.draw_colored_polygon(pts, color)
			canvas.draw_circle(c, 2.8 * u, Color(0.25, 0.55, 0.95))
			canvas.draw_circle(c, 1.3 * u, dark)
		&"help":
			canvas.draw_arc(c, 5.2 * u, 0, TAU, 40, color, 2.6 * u, true)
			for i in 4:
				var a := PI * 0.25 + i * PI * 0.5
				canvas.draw_arc(c, 5.2 * u, a - 0.3, a + 0.3, 8, Color(0.93, 0.27, 0.23), 2.6 * u, true)
		&"thanks":
			var heart := PackedVector2Array()
			for i in 40:
				var t := TAU * i / 40.0
				var x := 16.0 * pow(sin(t), 3)
				var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
				heart.append(c + Vector2(x, y + 1.0) * u * 0.42)
			canvas.draw_colored_polygon(heart, Color(1.0, 0.45, 0.55) if color == Color.WHITE else color)
		&"star":
			var star := PackedVector2Array()
			for i in 10:
				var a := -PI * 0.5 + TAU * i / 10.0
				var r := 7.0 if i % 2 == 0 else 3.0
				star.append(c + Vector2(cos(a), sin(a)) * r * u)
			canvas.draw_colored_polygon(star, Color(1.0, 0.85, 0.25) if color == Color.WHITE else color)
		&"build":
			var s := 4.6 * u
			for cell: Vector2 in [Vector2(-1, 0), Vector2(0, 0), Vector2(-0.5, -1)]:
				var at := c + Vector2(cell.x * s + s * 0.0, cell.y * s + s * 0.1)
				canvas.draw_rect(Rect2(at, Vector2(s, s) * 0.92), color)
				canvas.draw_rect(Rect2(at, Vector2(s, s) * 0.92), dark, false, 0.6 * u)


## An open hand: a palm, four fingers and a thumb.
static func _hand(canvas: CanvasItem, at: Vector2, u: float, color: Color) -> void:
	canvas.draw_rect(Rect2(at + Vector2(-3.5, -1.5) * u, Vector2(7, 6.5) * u), color)
	for i in 4:
		var x := -3.3 + i * 1.9
		canvas.draw_rect(Rect2(at + Vector2(x, -7.0 + absf(i - 1.5) * 0.7) * u, Vector2(1.5, 6) * u), color)
	canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(3.4, 0.5) * u, at + Vector2(6.8, -2.5) * u,
		at + Vector2(7.6, -1.5) * u, at + Vector2(3.6, 3.2) * u]), color)
