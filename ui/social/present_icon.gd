class_name PresentIcon
extends Control
## Owner #81, #82: a present's picture, drawn (pictures first for children who read little): a rocket part (a fuel
## tank), seeds (a sprout), a buddy egg (a spotted egg), a treasure map piece (a torn map with a red X), on a round tile
## of the present's colour (FriendPresents.color_of).

var kind := ""


func _init(p_kind: String = "", side: float = 64.0) -> void:
	kind = p_kind
	name = "PresentIcon"
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size * 0.5
	var u := s / 100.0
	draw_circle(c, s * 0.5, FriendPresents.color_of(kind).darkened(0.25))
	var ink := Color("fdf6e3")
	match kind:
		"rocket_part":   # a fuel tank: a capsule with bands
			draw_rect(Rect2(c + Vector2(-16, -26) * u, Vector2(32, 52) * u), ink)
			draw_circle(c + Vector2(0, -26) * u, 16 * u, ink)
			draw_circle(c + Vector2(0, 26) * u, 16 * u, ink)
			for y: float in [-12.0, 12.0]:
				draw_rect(Rect2(c + Vector2(-16, y - 3) * u, Vector2(32, 6) * u), Color("d9463b"))
		"seeds":   # a sprout from a seed
			draw_line(c + Vector2(0, 30) * u, c + Vector2(0, -8) * u, Color("8dff8a"), 6 * u)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6) * u, c + Vector2(-26, -26) * u,
				c + Vector2(-6, -30) * u]), Color("8dff8a"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -2) * u, c + Vector2(26, -18) * u,
				c + Vector2(8, -28) * u]), Color("8dff8a"))
			draw_circle(c + Vector2(0, 32) * u, 10 * u, Color("a8642a"))
		"buddy_egg":   # a spotted egg
			var egg := PackedVector2Array()
			for i in 32:
				var a := TAU * i / 32.0
				egg.append(c + Vector2(cos(a) * 24, sin(a) * (34 if sin(a) < 0 else 28) + 4) * u)
			draw_colored_polygon(egg, ink)
			for p: Vector2 in [Vector2(-8, -10), Vector2(10, 4), Vector2(-4, 16)]:
				draw_circle(c + p * u, 5 * u, Color("7b4bd6"))
		"map_piece":   # a torn map with a path and a red X
			draw_colored_polygon(PackedVector2Array([c + Vector2(-30, -24) * u, c + Vector2(30, -28) * u,
				c + Vector2(26, 0) * u, c + Vector2(32, 26) * u, c + Vector2(-28, 28) * u, c + Vector2(-32, 2) * u]), ink)
			draw_polyline(PackedVector2Array([c + Vector2(-20, 18) * u, c + Vector2(-6, 6) * u, c + Vector2(4, 12) * u,
				c + Vector2(12, -4) * u]), Color("a8642a"), 3 * u)
			draw_line(c + Vector2(10, -16) * u, c + Vector2(22, -4) * u, Color("d9463b"), 5 * u)
			draw_line(c + Vector2(22, -16) * u, c + Vector2(10, -4) * u, Color("d9463b"), 5 * u)
