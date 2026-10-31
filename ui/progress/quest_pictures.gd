class_name QuestPictures
extends RefCounted
## Owner #45a (spec §14.17): the pictures of the new board goals, the quest givers, their stories' steps and
## keepsakes, drawn in code like ProgressPictures' own (a few shapes each, no textures, no materials).
## ProgressPictures.SOURCES lists them as [&"quest", name]; `draw` fills the square `r` of `ci`.

const DARK := Color(0.1, 0.12, 0.2, 0.95)
const INK := Color.WHITE
const SKIN := Color("f1c27d")

const NAMES: Array[StringName] = [&"mummy", &"scorpion", &"serpent", &"pyramid", &"yeti", &"bat", &"giant", &"gummy",
	&"sneaker", &"cake", &"fox", &"parrot", &"horse", &"camel", &"penguin", &"medal", &"dragon", &"scroll", &"bell",
	&"star_jar", &"scarab", &"compass", &"snow_globe", &"ice_crown", &"cupcake", &"recipe", &"tilly", &"zara", &"bram",
	&"mimi"]


static func draw(ci: CanvasItem, what: StringName, r: Rect2, dim: bool) -> void:
	var u := r.size.x
	var p := func(x: float, y: float) -> Vector2: return r.position + Vector2(x, y) * r.size
	var c := func(col: Color) -> Color: return Color(0, 0, 0, 0.75) if dim else col
	var rect := func(x: float, y: float, w: float, h: float, col: Color) -> void:
		ci.draw_rect(Rect2(p.call(x, y), Vector2(w, h) * u), c.call(col))
	var dot := func(x: float, y: float, rad: float, col: Color) -> void:
		ci.draw_circle(p.call(x, y), u * rad, c.call(col))
	var poly := func(pts: Array, col: Color) -> void:
		var out := PackedVector2Array()
		for q: Vector2 in pts:
			out.append(p.call(q.x, q.y))
		ci.draw_colored_polygon(out, c.call(col))
	var eyes := func(y: float, gap: float, col: Color) -> void:
		dot.call(0.5 - gap, y, 0.045, col)
		dot.call(0.5 + gap, y, 0.045, col)
	match what:
		&"mummy":
			rect.call(0.24, 0.14, 0.52, 0.74, Color("efe6cf"))
			for i in 5:
				rect.call(0.22, 0.2 + i * 0.14, 0.56, 0.035, Color("c9bb98"))
			rect.call(0.3, 0.36, 0.4, 0.12, DARK)
			eyes.call(0.42, 0.1, Color("ffe082"))
		&"scorpion":
			ci.draw_arc(p.call(0.66, 0.36), u * 0.2, PI * 0.5, PI * 1.9, 16, c.call(Color("c0702c")), u * 0.08)
			poly.call([Vector2(0.78, 0.12), Vector2(0.9, 0.2), Vector2(0.8, 0.26)], Color("5d3a1a"))
			rect.call(0.14, 0.52, 0.5, 0.2, Color("c0702c"))
			for x: float in [0.18, 0.3, 0.42, 0.54]:
				rect.call(x, 0.72, 0.04, 0.12, Color("8d4f1e"))
			ci.draw_arc(p.call(0.12, 0.5), u * 0.08, PI * 0.8, PI * 2.2, 10, c.call(Color("8d4f1e")), u * 0.05)
			dot.call(0.22, 0.58, 0.03, DARK)
		&"serpent":
			var sand := Color("d8a24a")
			ci.draw_arc(p.call(0.36, 0.5), u * 0.2, -PI * 0.5, PI * 0.5, 14, c.call(sand), u * 0.12)
			ci.draw_arc(p.call(0.64, 0.5), u * 0.2, PI * 0.5, PI * 1.5, 14, c.call(sand), u * 0.12)
			dot.call(0.64, 0.3, 0.12, Color("b07a2a"))
			dot.call(0.6, 0.27, 0.03, DARK)
			rect.call(0.0, 0.84, 1.0, 0.16, Color("f0d08a"))
		&"pyramid":
			poly.call([Vector2(0.5, 0.12), Vector2(0.92, 0.84), Vector2(0.08, 0.84)], Color("e0b25c"))
			poly.call([Vector2(0.5, 0.12), Vector2(0.92, 0.84), Vector2(0.5, 0.84)], Color("c4933f"))
			poly.call([Vector2(0.5, 0.12), Vector2(0.58, 0.26), Vector2(0.42, 0.26)], Color("ffd23f"))
			rect.call(0.44, 0.64, 0.12, 0.2, DARK)
		&"yeti":
			dot.call(0.5, 0.52, 0.38, Color("f5f8ff"))
			rect.call(0.3, 0.38, 0.4, 0.34, Color("9fb8d6"))
			eyes.call(0.48, 0.09, DARK)
			rect.call(0.4, 0.62, 0.2, 0.05, DARK)
		&"bat":
			poly.call([Vector2(0.5, 0.42), Vector2(0.04, 0.26), Vector2(0.14, 0.52), Vector2(0.06, 0.66), Vector2(0.5, 0.56)],
				Color("6f8fcf"))
			poly.call([Vector2(0.5, 0.42), Vector2(0.96, 0.26), Vector2(0.86, 0.52), Vector2(0.94, 0.66), Vector2(0.5, 0.56)],
				Color("6f8fcf"))
			dot.call(0.5, 0.5, 0.13, Color("b3d4ff"))
			eyes.call(0.48, 0.05, DARK)
		&"giant":
			rect.call(0.2, 0.26, 0.6, 0.62, Color("8fb7e8"))
			poly.call([Vector2(0.2, 0.26), Vector2(0.3, 0.06), Vector2(0.4, 0.26), Vector2(0.5, 0.04), Vector2(0.6, 0.26),
				Vector2(0.7, 0.06), Vector2(0.8, 0.26)], Color("e6f5ff"))
			eyes.call(0.46, 0.12, Color("1f4e8c"))
			rect.call(0.3, 0.66, 0.4, 0.14, Color("e6f5ff"))
		&"gummy":
			var red := Color("ef4b5b")
			dot.call(0.32, 0.2, 0.1, red)
			dot.call(0.68, 0.2, 0.1, red)
			dot.call(0.5, 0.34, 0.22, red)
			rect.call(0.3, 0.46, 0.4, 0.42, red)
			eyes.call(0.32, 0.08, DARK)
			dot.call(0.5, 0.4, 0.04, Color("ffcdd2"))
		&"sneaker":
			poly.call([Vector2(0.2, 0.9), Vector2(0.2, 0.36), Vector2(0.5, 0.1), Vector2(0.8, 0.36), Vector2(0.8, 0.9),
				Vector2(0.65, 0.78), Vector2(0.5, 0.9), Vector2(0.35, 0.78)], Color(0.72, 0.5, 0.95, 0.8))
			eyes.call(0.42, 0.1, Color("fff59d"))
		&"cake":
			rect.call(0.14, 0.58, 0.72, 0.28, Color("f48fb1"))
			rect.call(0.24, 0.34, 0.52, 0.24, Color("fff3e0"))
			rect.call(0.34, 0.16, 0.32, 0.18, Color("f48fb1"))
			eyes.call(0.7, 0.12, DARK)
			dot.call(0.5, 0.12, 0.05, Color("e53935"))
		&"fox":
			var fur := Color("f08a3c")
			poly.call([Vector2(0.12, 0.1), Vector2(0.38, 0.3), Vector2(0.2, 0.46)], fur)
			poly.call([Vector2(0.88, 0.1), Vector2(0.62, 0.3), Vector2(0.8, 0.46)], fur)
			poly.call([Vector2(0.14, 0.34), Vector2(0.86, 0.34), Vector2(0.5, 0.9)], fur)
			poly.call([Vector2(0.3, 0.6), Vector2(0.7, 0.6), Vector2(0.5, 0.9)], Color("fff3e0"))
			eyes.call(0.5, 0.13, DARK)
			dot.call(0.5, 0.86, 0.04, DARK)
		&"parrot":
			dot.call(0.5, 0.36, 0.2, Color("43a047"))
			poly.call([Vector2(0.34, 0.46), Vector2(0.66, 0.46), Vector2(0.58, 0.92), Vector2(0.42, 0.92)], Color("43a047"))
			poly.call([Vector2(0.6, 0.36), Vector2(0.8, 0.42), Vector2(0.62, 0.5)], Color("ffb300"))
			dot.call(0.5, 0.32, 0.04, DARK)
			rect.call(0.4, 0.6, 0.2, 0.1, Color("e53935"))
		&"horse":
			poly.call([Vector2(0.3, 0.9), Vector2(0.3, 0.3), Vector2(0.5, 0.1), Vector2(0.8, 0.34), Vector2(0.7, 0.46),
				Vector2(0.54, 0.4), Vector2(0.56, 0.9)], Color("8d5a35"))
			poly.call([Vector2(0.3, 0.3), Vector2(0.5, 0.1), Vector2(0.4, 0.08), Vector2(0.22, 0.4)], Color("3e2723"))
			dot.call(0.56, 0.26, 0.035, DARK)
		&"camel":
			var tan := Color("d4a35c")
			dot.call(0.4, 0.44, 0.16, tan)
			rect.call(0.16, 0.46, 0.56, 0.2, tan)
			for x: float in [0.2, 0.34, 0.54, 0.66]:
				rect.call(x, 0.64, 0.06, 0.26, tan)
			rect.call(0.68, 0.24, 0.1, 0.3, tan)
			rect.call(0.68, 0.18, 0.2, 0.1, tan)
			dot.call(0.82, 0.22, 0.025, DARK)
		&"penguin":
			dot.call(0.5, 0.56, 0.32, Color("263238"))
			dot.call(0.5, 0.62, 0.22, Color("fafafa"))
			dot.call(0.5, 0.26, 0.18, Color("263238"))
			eyes.call(0.24, 0.07, INK)
			poly.call([Vector2(0.44, 0.32), Vector2(0.56, 0.32), Vector2(0.5, 0.4)], Color("ffb300"))
		&"medal":
			poly.call([Vector2(0.3, 0.06), Vector2(0.44, 0.06), Vector2(0.56, 0.44), Vector2(0.42, 0.44)], Color("1e88e5"))
			poly.call([Vector2(0.56, 0.06), Vector2(0.7, 0.06), Vector2(0.58, 0.44), Vector2(0.44, 0.44)], Color("e53935"))
			dot.call(0.5, 0.64, 0.26, Color("ffd23f"))
			dot.call(0.5, 0.64, 0.17, Color("fff3c4"))
		&"dragon":
			var green := Color("43a047")
			poly.call([Vector2(0.5, 0.46), Vector2(0.06, 0.16), Vector2(0.2, 0.56)], Color("81c784"))
			poly.call([Vector2(0.5, 0.46), Vector2(0.94, 0.16), Vector2(0.8, 0.56)], Color("81c784"))
			rect.call(0.34, 0.4, 0.32, 0.4, green)
			rect.call(0.4, 0.18, 0.2, 0.24, green)
			eyes.call(0.26, 0.05, Color("fff59d"))
			rect.call(0.28, 0.66, 0.44, 0.08, Color("8d6e63"))   # the saddle
		&"scroll":
			rect.call(0.2, 0.18, 0.6, 0.64, Color("fff3d6"))
			dot.call(0.2, 0.18, 0.08, Color("c8995c"))
			dot.call(0.8, 0.82, 0.08, Color("c8995c"))
			for i in 3:
				rect.call(0.3, 0.32 + i * 0.14, 0.4, 0.04, Color("8d6e63"))
			ProgressPictures._star(ci, p.call(0.66, 0.7), u * 0.1, u * 0.045, c.call(Color("ffd23f")))
		&"bell":
			poly.call([Vector2(0.5, 0.12), Vector2(0.74, 0.3), Vector2(0.8, 0.74), Vector2(0.2, 0.74), Vector2(0.26, 0.3)],
				Color("ffd23f"))
			rect.call(0.16, 0.72, 0.68, 0.08, Color("c99a12"))
			dot.call(0.5, 0.84, 0.07, Color("c99a12"))
		&"star_jar":
			rect.call(0.24, 0.24, 0.52, 0.66, Color(0.8, 0.92, 1.0, 0.6))
			rect.call(0.22, 0.14, 0.56, 0.1, Color("8d6e63"))
			ProgressPictures._star(ci, p.call(0.5, 0.58), u * 0.2, u * 0.09, c.call(Color("ffd23f")))
		&"scarab":
			dot.call(0.5, 0.56, 0.28, Color("ffd23f"))
			dot.call(0.5, 0.24, 0.12, Color("c99a12"))
			rect.call(0.49, 0.32, 0.02, 0.5, Color("c99a12"))
			for s: float in [-1.0, 1.0]:
				rect.call(0.5 + s * 0.3 - 0.06, 0.42, 0.12, 0.04, Color("c99a12"))
				rect.call(0.5 + s * 0.3 - 0.06, 0.62, 0.12, 0.04, Color("c99a12"))
		&"compass":
			dot.call(0.5, 0.5, 0.4, Color("c99a12"))
			dot.call(0.5, 0.5, 0.32, Color("fff8e1"))
			poly.call([Vector2(0.5, 0.2), Vector2(0.58, 0.5), Vector2(0.42, 0.5)], Color("e53935"))
			poly.call([Vector2(0.5, 0.8), Vector2(0.58, 0.5), Vector2(0.42, 0.5)], Color("455a64"))
		&"snow_globe":
			dot.call(0.5, 0.44, 0.34, Color(0.75, 0.9, 1.0, 0.8))
			rect.call(0.24, 0.76, 0.52, 0.14, Color("8d6e63"))
			poly.call([Vector2(0.5, 0.26), Vector2(0.64, 0.56), Vector2(0.36, 0.56)], Color("2e7d32"))
			for q: Vector2 in [Vector2(0.3, 0.3), Vector2(0.66, 0.26), Vector2(0.72, 0.5), Vector2(0.28, 0.56)]:
				dot.call(q.x, q.y, 0.025, INK)
		&"ice_crown":
			poly.call([Vector2(0.12, 0.76), Vector2(0.12, 0.3), Vector2(0.3, 0.52), Vector2(0.5, 0.18), Vector2(0.7, 0.52),
				Vector2(0.88, 0.3), Vector2(0.88, 0.76)], Color("b3e5fc"))
			rect.call(0.12, 0.7, 0.76, 0.1, Color("4fc3f7"))
			dot.call(0.5, 0.56, 0.06, Color("1e88e5"))
		&"cupcake":
			poly.call([Vector2(0.24, 0.52), Vector2(0.76, 0.52), Vector2(0.68, 0.9), Vector2(0.32, 0.9)], Color("8d6e63"))
			dot.call(0.5, 0.44, 0.24, Color("f8bbd0"))
			dot.call(0.5, 0.3, 0.16, Color("fce4ec"))
			dot.call(0.5, 0.14, 0.07, Color("d32f2f"))
		&"recipe":
			rect.call(0.18, 0.14, 0.64, 0.74, Color("e57373"))
			rect.call(0.26, 0.2, 0.5, 0.62, Color("fff8e1"))
			for i in 3:
				rect.call(0.34, 0.32 + i * 0.14, 0.34, 0.04, Color("8d6e63"))
			dot.call(0.62, 0.72, 0.06, Color("f48fb1"))
		&"tilly", &"zara", &"bram", &"mimi", &"nell", &"mira":
			_face(what, dot, rect, poly, eyes)
		_:
			rect.call(0.3, 0.3, 0.4, 0.4, Color("b0bec5"))


## A giver's face: skin, eyes, a smile and what makes each one easy to tell apart (a straw hat, an explorer's
## hat, a fur hood, a baker's hat).
static func _face(who: StringName, dot: Callable, rect: Callable, poly: Callable, eyes: Callable) -> void:
	match who:
		&"bram":
			dot.call(0.5, 0.54, 0.4, Color("8d6e63"))    # the fur hood
			dot.call(0.5, 0.56, 0.28, Color("fff8e1"))
	dot.call(0.5, 0.56, 0.24, SKIN)
	eyes.call(0.52, 0.09, DARK)
	rect.call(0.4, 0.66, 0.2, 0.04, DARK)
	dot.call(0.36, 0.62, 0.035, Color("ff9aa2"))
	dot.call(0.64, 0.62, 0.035, Color("ff9aa2"))
	match who:
		&"tilly":
			rect.call(0.1, 0.3, 0.8, 0.06, Color("e8c872"))
			rect.call(0.28, 0.16, 0.44, 0.14, Color("e8c872"))
			rect.call(0.28, 0.26, 0.44, 0.04, Color("e04b3c"))
		&"zara":
			poly.call([Vector2(0.08, 0.36), Vector2(0.92, 0.36), Vector2(0.72, 0.28), Vector2(0.66, 0.1), Vector2(0.34, 0.1),
				Vector2(0.28, 0.28)], Color("d7b98a"))
			rect.call(0.28, 0.26, 0.44, 0.04, Color("6d4c41"))
		&"mimi":
			dot.call(0.36, 0.2, 0.12, INK)
			dot.call(0.5, 0.14, 0.13, INK)
			dot.call(0.64, 0.2, 0.12, INK)
			rect.call(0.3, 0.24, 0.4, 0.1, INK)
		&"mira":   # the cave guide: a blue explorer's helmet with a glowing teal lamp
			poly.call([Vector2(0.24, 0.36), Vector2(0.76, 0.36), Vector2(0.7, 0.18), Vector2(0.5, 0.12), Vector2(0.3, 0.18)],
				Color("3f51b5"))
			dot.call(0.5, 0.24, 0.07, Color("8ff7e8"))
		&"nell":   # the dragon keeper: a teal headband with two little orange dragon horns
			rect.call(0.26, 0.3, 0.48, 0.08, Color("26a69a"))
			poly.call([Vector2(0.3, 0.31), Vector2(0.4, 0.31), Vector2(0.33, 0.12)], Color("ff9800"))
			poly.call([Vector2(0.6, 0.31), Vector2(0.7, 0.31), Vector2(0.67, 0.12)], Color("ff9800"))
