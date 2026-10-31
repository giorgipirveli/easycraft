class_name LabThings
extends RefCounted
## Spec §23: the things the Lab's experiments use (LabModels.THINGS), drawn in code in a square (UI draw calls only, no
## art files; our own friendly look): a wooden block, a pebble, an ice cube, an iron nail, a leaf, a gold ring, a
## sponge, a glass marble, a paper clip, a coil of copper wire and a food tin.

const INK := Color("1f2a4a")


## Draws `thing` into `r` on `ci` (from its _draw).
static func draw(ci: CanvasItem, thing: String, r: Rect2) -> void:
	var s := minf(r.size.x, r.size.y)
	var c := r.get_center()
	var u := s / 16.0   # one unit of a 16 x 16 design
	match thing:
		"wood":
			var box := Rect2(c - Vector2(6, 4) * u, Vector2(12, 8) * u)
			ci.draw_rect(box, Color("c8904e"))
			for i in 3:
				var y := box.position.y + (2 + i * 2.2) * u
				ci.draw_line(Vector2(box.position.x + u, y), Vector2(box.end.x - u, y + 0.4 * u), Color("9c6a33"), maxf(1.0, u * 0.5))
			ci.draw_circle(box.position + Vector2(8.5, 5.2) * u, u * 0.9, Color("9c6a33"))
			ci.draw_rect(box, INK, false, maxf(1.0, u * 0.4))
		"stone":
			_blob(ci, c, Vector2(6.5, 4.8) * u, Color("8f959c"), Color("6f757c"))
			ci.draw_circle(c + Vector2(-2, -1.5) * u, u * 0.9, Color("b3b8be"))
		"ice":
			var box := Rect2(c - Vector2(5, 5) * u, Vector2(10, 10) * u)
			ci.draw_rect(box, Color("bfe9fb"))
			ci.draw_rect(Rect2(box.position + Vector2(1, 1) * u, Vector2(3, 6) * u), Color("eafaff"))
			ci.draw_rect(box, Color("5aa9cf"), false, maxf(1.0, u * 0.5))
		"iron":   # a nail: a flat head and a pointed shaft, lying across
			var a := c + Vector2(-6, -1) * u
			var b := c + Vector2(6, 1) * u
			ci.draw_line(a, b, Color("7d8792"), u * 1.6)
			ci.draw_line(a + Vector2(0, -2.2) * u, a + Vector2(0, 2.2) * u, Color("5d6772"), u * 1.4)
			ci.draw_colored_polygon(PackedVector2Array([b + Vector2(0, -0.8) * u, b + Vector2(2.2, 0.3) * u,
				b + Vector2(0, 0.8) * u]), Color("7d8792"))
			ci.draw_line(a + Vector2(1, -0.4) * u, b + Vector2(-1, -0.4) * u, Color("b8c1ca"), maxf(1.0, u * 0.4))
		"leaf":
			var pts := PackedVector2Array()
			for i in 17:
				var t := float(i) / 16.0
				var x := lerpf(-6.5, 6.5, t)
				pts.append(c + Vector2(x, -sin(t * PI) * 4.2) * u)
			for i in range(15, 0, -1):
				var t := float(i) / 16.0
				var x := lerpf(-6.5, 6.5, t)
				pts.append(c + Vector2(x, sin(t * PI) * 4.2) * u)
			ci.draw_colored_polygon(pts, Color("58b848"))
			ci.draw_line(c + Vector2(-7.5, 0.5) * u, c + Vector2(6.5, 0) * u, Color("2f7d2a"), maxf(1.0, u * 0.5))
		"gold":   # a ring
			ci.draw_arc(c, 4.6 * u, 0, TAU, 32, Color("e8b923"), 2.2 * u)
			ci.draw_arc(c, 4.6 * u, -2.6, -1.6, 8, Color("fff1a6"), 0.8 * u)
		"sponge":
			var box := Rect2(c - Vector2(6, 4) * u, Vector2(12, 8) * u)
			ci.draw_rect(box, Color("f6d44a"))
			for p: Vector2 in [Vector2(2, 2), Vector2(6, 1.5), Vector2(9.5, 3), Vector2(4, 5.5), Vector2(8, 6), Vector2(1.5, 6)]:
				ci.draw_circle(box.position + p * u, u * 0.8, Color("d6a91e"))
			ci.draw_rect(box, Color("b88a12"), false, maxf(1.0, u * 0.4))
		"glass":   # a marble
			ci.draw_circle(c, 5 * u, Color("a8def0"))
			ci.draw_arc(c, 3 * u, 0.4, 2.6, 12, Color("2fa3c9"), 1.2 * u)
			ci.draw_circle(c + Vector2(-1.8, -1.8) * u, 1.2 * u, Color("f2fcff"))
			ci.draw_arc(c, 5 * u, 0, TAU, 32, Color("5aa9cf"), maxf(1.0, u * 0.4))
		"clip":   # a paper clip: a loop within a loop
			var w := maxf(1.5, u * 0.9)
			var col := Color("8e98a4")
			ci.draw_polyline(PackedVector2Array([c + Vector2(4, 2.5) * u, c + Vector2(-5, 2.5) * u]), col, w)
			ci.draw_arc(c + Vector2(-5, 0) * u, 2.5 * u, PI * 0.5, PI * 1.5, 10, col, w)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-5, -2.5) * u, c + Vector2(6, -2.5) * u]), col, w)
			ci.draw_arc(c + Vector2(6, -0.75) * u, 1.75 * u, -PI * 0.5, PI * 0.5, 10, col, w)
			ci.draw_polyline(PackedVector2Array([c + Vector2(6, 1) * u, c + Vector2(-3, 1) * u]), col, w)
			ci.draw_arc(c + Vector2(-3, 0) * u, 1 * u, PI * 0.5, PI * 1.5, 8, col, w)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-3, -1) * u, c + Vector2(3, -1) * u]), col, w)
		"copper":   # a coil of copper wire
			for i in 5:
				var x := -5.0 + i * 2.5
				ci.draw_arc(c + Vector2(x, 0) * u, 2.8 * u, PI * 0.15, PI * 1.85, 12, Color("c46a2a"), 0.9 * u)
			ci.draw_line(c + Vector2(5, 2.2) * u, c + Vector2(7.5, 4.5) * u, Color("c46a2a"), 0.9 * u)
		"tin":   # a food tin: a steel can with a label
			var box := Rect2(c - Vector2(4.5, 6) * u, Vector2(9, 12) * u)
			ci.draw_rect(box, Color("aeb7c1"))
			ci.draw_rect(Rect2(box.position + Vector2(0, 3) * u, Vector2(9, 6) * u), Color("e4572e"))
			ci.draw_rect(Rect2(box.position + Vector2(1.5, 4.8) * u, Vector2(6, 2.4) * u), Color("fdf6e3"))
			for y: float in [0.8, 11.2]:
				ci.draw_line(box.position + Vector2(0, y) * u, box.position + Vector2(9, y) * u, Color("7d8792"), maxf(1.0, u * 0.5))
			ci.draw_rect(box, Color("5d6772"), false, maxf(1.0, u * 0.4))
		_:
			ci.draw_circle(c, 4 * u, Color("cccccc"))


## Whether `thing` has its own drawing (the content test: every thing a scene names can be drawn).
static func knows(thing: String) -> bool:
	return LabModels.THINGS.has(thing)


static func _blob(ci: CanvasItem, c: Vector2, radius: Vector2, fill: Color, edge: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		var wobble := 1.0 + 0.08 * sin(a * 3.0)
		pts.append(c + Vector2(cos(a) * radius.x, sin(a) * radius.y) * wobble)
	ci.draw_colored_polygon(pts, fill)
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, edge, maxf(1.0, radius.x * 0.08))


## A Control that draws one thing in its square.
class Picture:
	extends Control
	var thing := ""

	func _init(t: String = "", px: float = 64.0) -> void:
		thing = t
		custom_minimum_size = Vector2(px, px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := minf(size.x, size.y)
		LabThings.draw(self, thing, Rect2((size - Vector2(s, s)) * 0.5, Vector2(s, s)))
