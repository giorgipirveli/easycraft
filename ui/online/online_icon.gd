class_name OnlineIcon
extends Control
## The online screens' pictures (M4 Wave 1, Agent C), drawn with shapes: no image files, so nothing
## to license. Pictures come first and words second (spec §5.15), so a child who can't read yet
## still finds HOST, FRIENDS and the stay-safe rules.

const KINDS: Array[StringName] = [&"lock", &"friends", &"grownup", &"heart", &"globe", &"house", &"add_friend",
	&"talk", &"flag", &"gift", &"bottle", &"visit"]   # M4 I: gift, bottle, visit

var kind: StringName = &"globe"
var color := Color.WHITE


func _init(icon_kind: StringName = &"globe", icon_color: Color = Color.WHITE) -> void:
	kind = icon_kind
	color = icon_color
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var u := minf(size.x, size.y) / 16.0   # the picture is 16 x 16 units
	var c := size * 0.5
	var dark := Color(0.08, 0.1, 0.17)
	match kind:
		&"lock":
			draw_arc(c + Vector2(0, -2.2) * u, 3.6 * u, PI, TAU, 20, color, 1.6 * u, true)
			draw_line(c + Vector2(-3.6, -2.2) * u, c + Vector2(-3.6, -0.5) * u, color, 1.6 * u)
			draw_line(c + Vector2(3.6, -2.2) * u, c + Vector2(3.6, -0.5) * u, color, 1.6 * u)
			draw_rect(Rect2(c + Vector2(-5.5, -0.8) * u, Vector2(11, 8) * u), color)
			draw_circle(c + Vector2(0, 2.4) * u, 1.3 * u, dark)
			draw_rect(Rect2(c + Vector2(-0.5, 2.8) * u, Vector2(1, 2.6) * u), dark)
		&"friends":
			_person(c + Vector2(-3.4, 0.6) * u, u * 0.95)
			_person(c + Vector2(3.4, 0.2) * u, u * 1.05)
		&"grownup":
			_person(c + Vector2(-2.6, -0.2) * u, u * 1.25)
			_person(c + Vector2(4.2, 2.4) * u, u * 0.8)
		&"heart":
			var pts := PackedVector2Array()
			for i in 40:
				var t := TAU * i / 40.0
				var x := 16.0 * pow(sin(t), 3)
				var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
				pts.append(c + Vector2(x, y + 1.0) * u * 0.42)
			draw_colored_polygon(pts, color)
		&"globe":
			draw_arc(c, 6.5 * u, 0, TAU, 40, color, 1.2 * u, true)
			draw_line(c + Vector2(-6.5, 0) * u, c + Vector2(6.5, 0) * u, color, 1.0 * u)
			draw_line(c + Vector2(0, -6.5) * u, c + Vector2(0, 6.5) * u, color, 1.0 * u)
			_ellipse(c, Vector2(3.2, 6.5) * u, 1.0 * u)
			draw_line(c + Vector2(-5.6, -3.2) * u, c + Vector2(5.6, -3.2) * u, color, 0.8 * u)
			draw_line(c + Vector2(-5.6, 3.2) * u, c + Vector2(5.6, 3.2) * u, color, 0.8 * u)
		&"house":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -0.5) * u, c + Vector2(0, -7) * u,
				c + Vector2(7, -0.5) * u]), color)
			draw_rect(Rect2(c + Vector2(-5, -0.5) * u, Vector2(10, 7) * u), color)
			draw_rect(Rect2(c + Vector2(-1.4, 2.2) * u, Vector2(2.8, 4.3) * u), dark)
		&"add_friend":
			_person(c + Vector2(-2.2, 0.4) * u, u * 1.1)
			draw_line(c + Vector2(5.2, -4.5) * u, c + Vector2(5.2, 0.5) * u, color, 1.6 * u)
			draw_line(c + Vector2(2.7, -2.0) * u, c + Vector2(7.7, -2.0) * u, color, 1.6 * u)
		&"talk":   # a speech bubble with "!": tell a grown-up
			_ellipse_filled(c + Vector2(0, -1) * u, Vector2(7, 5) * u)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-3, 2.5) * u, c + Vector2(-5.5, 7) * u,
				c + Vector2(0, 3.5) * u]), color)
			draw_rect(Rect2(c + Vector2(-0.6, -4.5) * u, Vector2(1.2, 4) * u), dark)
			draw_circle(c + Vector2(0, 1.2) * u, 0.75 * u, dark)
		&"flag":   # report
			draw_line(c + Vector2(-4.5, -7) * u, c + Vector2(-4.5, 7) * u, color, 1.4 * u)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -6.5) * u, c + Vector2(5.5, -3.8) * u,
				c + Vector2(-4, -1) * u]), color)
		&"gift":   # M4 I: a present with a bow
			draw_rect(Rect2(c + Vector2(-6, -1.5) * u, Vector2(12, 8.5) * u), color)
			draw_rect(Rect2(c + Vector2(-7, -3.5) * u, Vector2(14, 2.5) * u), color)
			draw_rect(Rect2(c + Vector2(-0.9, -3.5) * u, Vector2(1.8, 10.5) * u), dark)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -3.5) * u, c + Vector2(-5, -7) * u, c + Vector2(-4.5, -3.5) * u]), color)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -3.5) * u, c + Vector2(5, -7) * u, c + Vector2(4.5, -3.5) * u]), color)
		&"bottle":   # M4 I: a bottle lying on a wave
			draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -2) * u, c + Vector2(3, -2.5) * u, c + Vector2(5, -1) * u,
				c + Vector2(5, 1) * u, c + Vector2(3, 2.5) * u, c + Vector2(-6, 2) * u]), color)
			draw_rect(Rect2(c + Vector2(5, -0.9) * u, Vector2(2, 1.8) * u), color)
			draw_arc(c + Vector2(-3, 7) * u, 3.0 * u, PI, TAU, 10, color, 0.9 * u, true)
			draw_arc(c + Vector2(3, 7) * u, 3.0 * u, PI, TAU, 10, color, 0.9 * u, true)
		&"visit":   # M4 I: a little house with an open door and a footpath
			draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -1) * u, c + Vector2(0, -7) * u,
				c + Vector2(6, -1) * u]), color)
			draw_rect(Rect2(c + Vector2(-4.5, -1) * u, Vector2(9, 6) * u), color)
			draw_rect(Rect2(c + Vector2(-1.3, 1.2) * u, Vector2(2.6, 3.8) * u), dark)
			for i in 3:
				draw_circle(c + Vector2(-0.5 + i * 0.6, 6.2 + i * 0.6) * u, 0.55 * u, color)


## A person: a round head over round shoulders.
func _person(at: Vector2, k: float) -> void:
	draw_circle(at + Vector2(0, -3.2) * k, 2.3 * k, color)
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		pts.append(at + Vector2(0, 5.2) * k + Vector2(cos(a) * 3.9, sin(a) * 4.0) * k)
	draw_colored_polygon(pts, color)


func _ellipse(at: Vector2, radius: Vector2, width: float) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		pts.append(at + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_polyline(pts, color, width, true)


func _ellipse_filled(at: Vector2, radius: Vector2) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(at + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(pts, color)
