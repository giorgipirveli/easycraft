class_name ShortsIcon
extends Control
## The Shorts' button pictures (owner #94, spec §5.12b), drawn with UI draw calls (no image files, nothing to license):
## shorts (a tall screen with a play sign: the Theater's SHORTS tab), heart, heart_full, star, book, up, down, speaker,
## speaker_off, bulb (LEARN IT), cross (EXIT), gear (grown-ups), tick (seen).

var shape := &"star"
var colour := Color.WHITE


func _init(p_shape: StringName = &"star", side: float = 36.0, p_colour: Color = Color.WHITE) -> void:
	shape = p_shape
	colour = p_colour
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_shape(s: StringName, c: Color = colour) -> void:
	if s != shape or c != colour:
		shape = s
		colour = c
		queue_redraw()


func _draw() -> void:
	var u := minf(size.x, size.y)
	var o := (size - Vector2(u, u)) * 0.5
	var at := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * u
	var w := maxf(2.0, u * 0.09)
	match shape:
		&"shorts":
			var box := StyleBoxFlat.new()
			box.bg_color = Color(0, 0, 0, 0)
			box.border_color = colour
			box.set_border_width_all(int(maxf(2.0, u * 0.08)))
			box.set_corner_radius_all(int(u * 0.12))
			draw_style_box(box, Rect2(at.call(0.24, 0.04), Vector2(0.52, 0.92) * u))
			draw_colored_polygon(PackedVector2Array([at.call(0.42, 0.34), at.call(0.64, 0.5), at.call(0.42, 0.66)]), colour)
		&"heart", &"heart_full":
			var pts := PackedVector2Array()
			for i in 41:
				var t := TAU * i / 40.0
				pts.append(at.call(0.5, 0.52) + Vector2(16.0 * pow(sin(t), 3.0),
					-(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))) * u * 0.027)
			if shape == &"heart_full":
				draw_colored_polygon(pts, colour)
			else:
				draw_polyline(pts, colour, w, true)
		&"star":
			var pts := SchoolUi.star_points(at.call(0.5, 0.53), u * 0.46)
			draw_colored_polygon(pts, colour)
		&"book":
			draw_colored_polygon(PackedVector2Array([at.call(0.06, 0.2), at.call(0.48, 0.28), at.call(0.48, 0.9), at.call(0.06, 0.82)]), colour)
			draw_colored_polygon(PackedVector2Array([at.call(0.52, 0.28), at.call(0.94, 0.2), at.call(0.94, 0.82), at.call(0.52, 0.9)]), colour)
		&"up", &"down":
			var s := 1.0 if shape == &"down" else -1.0
			draw_colored_polygon(PackedVector2Array([at.call(0.5, 0.5 + 0.34 * s), at.call(0.12, 0.5 - 0.22 * s),
				at.call(0.88, 0.5 - 0.22 * s)]), colour)
		&"speaker", &"speaker_off":
			draw_rect(Rect2(at.call(0.1, 0.38), Vector2(0.16, 0.24) * u), colour)
			draw_colored_polygon(PackedVector2Array([at.call(0.26, 0.38), at.call(0.5, 0.16), at.call(0.5, 0.84), at.call(0.26, 0.62)]), colour)
			if shape == &"speaker":
				for i in 2:
					draw_arc(at.call(0.5, 0.5), u * (0.18 + 0.14 * i), -0.8, 0.8, 12, colour, w * 0.8, true)
			else:
				draw_line(at.call(0.62, 0.34), at.call(0.9, 0.66), colour, w, true)
				draw_line(at.call(0.9, 0.34), at.call(0.62, 0.66), colour, w, true)
		&"bulb":
			draw_circle(at.call(0.5, 0.4), u * 0.28, colour)
			draw_rect(Rect2(at.call(0.37, 0.66), Vector2(0.26, 0.2) * u), colour)
			for i in 3:
				var a := -PI * 0.5 + (i - 1) * 0.9
				draw_line(at.call(0.5, 0.4) + Vector2(cos(a), sin(a)) * u * 0.34, at.call(0.5, 0.4) + Vector2(cos(a), sin(a)) * u * 0.46,
					colour, w * 0.8, true)
		&"cross":
			draw_line(at.call(0.2, 0.2), at.call(0.8, 0.8), colour, w * 1.4, true)
			draw_line(at.call(0.8, 0.2), at.call(0.2, 0.8), colour, w * 1.4, true)
		&"gear":
			draw_circle(at.call(0.5, 0.5), u * 0.3, colour)
			for i in 8:
				var a := TAU * i / 8.0
				draw_line(at.call(0.5, 0.5) + Vector2(cos(a), sin(a)) * u * 0.25, at.call(0.5, 0.5) + Vector2(cos(a), sin(a)) * u * 0.44,
					colour, u * 0.13)
			draw_circle(at.call(0.5, 0.5), u * 0.12, Color(0, 0, 0, 0.55))
		&"tick":
			draw_polyline(PackedVector2Array([at.call(0.16, 0.54), at.call(0.4, 0.78), at.call(0.86, 0.24)]), colour, w * 1.3, true)
		# MAKE MY SHORT's pictures: a camera (How I built it), a planet (3 facts), stairs of blocks (Step by step), a pencil
		# (type your own words), a note (music), a plus (MAKE A SHORT), a bin (DELETE), a person (MY SHORTS).
		&"camera":
			MyShortDrawers.draw_camera(self, Rect2(o, Vector2(u, u)), colour)
		&"planet":
			draw_circle(at.call(0.5, 0.5), u * 0.26, colour)
			var ring := PackedVector2Array()
			for i in 33:
				var a := TAU * i / 32.0
				ring.append(at.call(0.5, 0.5) + Vector2(cos(a) * u * 0.46, sin(a) * u * 0.14).rotated(-0.35))
			draw_polyline(ring, colour, w * 0.8, true)
		&"stairs":
			for i in 3:
				for k in i + 1:
					draw_rect(Rect2(at.call(0.08 + 0.29 * i, 0.66 - 0.29 * k), Vector2(0.26, 0.26) * u), colour)
		&"pencil":
			var tip: Vector2 = at.call(0.16, 0.84)
			var dir := Vector2(1, -1).normalized()
			var side := dir.orthogonal() * u * 0.1
			draw_colored_polygon(PackedVector2Array([tip + dir * u * 0.18 + side, tip + dir * u * 0.86 + side,
				tip + dir * u * 0.86 - side, tip + dir * u * 0.18 - side]), colour)
			draw_colored_polygon(PackedVector2Array([tip, tip + dir * u * 0.16 + side, tip + dir * u * 0.16 - side]), colour)
		&"music":
			draw_circle(at.call(0.3, 0.76), u * 0.13, colour)
			draw_circle(at.call(0.74, 0.66), u * 0.13, colour)
			draw_line(at.call(0.42, 0.76), at.call(0.42, 0.18), colour, w)
			draw_line(at.call(0.86, 0.66), at.call(0.86, 0.1), colour, w)
			draw_line(at.call(0.42, 0.2), at.call(0.86, 0.1), colour, w * 1.6)
		&"plus":
			draw_line(at.call(0.5, 0.14), at.call(0.5, 0.86), colour, w * 1.7)
			draw_line(at.call(0.14, 0.5), at.call(0.86, 0.5), colour, w * 1.7)
		&"bin":
			draw_rect(Rect2(at.call(0.22, 0.3), Vector2(0.56, 0.6) * u), colour)
			draw_rect(Rect2(at.call(0.14, 0.18), Vector2(0.72, 0.08) * u), colour)
			draw_rect(Rect2(at.call(0.4, 0.1), Vector2(0.2, 0.08) * u), colour)
		&"person":
			draw_circle(at.call(0.5, 0.3), u * 0.17, colour)
			draw_colored_polygon(PackedVector2Array([at.call(0.18, 0.92), at.call(0.24, 0.62), at.call(0.5, 0.52),
				at.call(0.76, 0.62), at.call(0.82, 0.92)]), colour)
