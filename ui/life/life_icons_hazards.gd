class_name LifeIconsHazards
extends RefCounted
## Owner #118 (Life L3b: Electricity Safety, Safe with Animals, Medical Emergencies, and fire and heat in The Kitchen and
## Fire Escape): the fourth wave of Life's pictures, drawn in code like LifeIcons (which asks here after LifeIconsDanger).
## The same calm style: simple shapes, soft colours, a "no" in soft grey-blue, never red; electricity is a small yellow
## zigzag, never a flash; dogs are friendly blocky dogs (a warning dog shows its signs, never a bite); people are blocky
## figures, never hurt.

const NAMES: Array[String] = [
	# Electricity Safety
	"hands_dry", "hands_wet", "plug", "plug_broken", "fork_socket", "frayed", "socket_one", "socket_many", "kite_lines",
	"kite_field", "tree_lines", "substation", "fuse_box", "rcd", "two_stuck", "line_down", "help_ok",
	# Safe with Animals
	"ask_owner", "dog_hug", "dog_sleep", "dog_happy", "dog_warning", "be_a_tree", "swat", "cow_edge", "snake", "no_feed",
	# Medical Emergencies
	"lean_forward", "head_back", "spacer", "auto_pen", "cushion", "nothing_mouth", "hands_off",
	# Fire and heat, choking
	"tap_cold", "tap_hot", "grapes", "grapes_cut", "water_pan", "pan_lid", "cling_film",
	# the hooks: Real Builder's saw, Safe Streets' crossing
	"goggles_on", "car_close"]

const INK := LifeIcons.INK
const SKIN := LifeIcons.SKIN
const TEAL := LifeIcons.TEAL
const SOFT_NO := LifeIcons.SOFT_NO
const GOOD := LifeIcons.GOOD
const GOLD := LifeIcons.GOLD
const WOOD := LifeIcons.WOOD
const SKY := LifeIcons.SKY
const WHITE := LifeIcons.WHITE
const SPARK := Color("ffd23f")
const PLUG := Color("f4f6f8")
const WALL := Color("e9e4d8")
const GRASS := Color("7cc46a")
const DOG := Color("c98a4a")
const ORANGE := Color("ff7a2e")
const FLAME := LifeIcons.FLAME
const WATER := Color("5aa8e6")


static func has(name: String) -> bool:
	return NAMES.has(name)


## Draws `name` with `p` (0..100 coordinates to the canvas) and `u` (one unit); false for a name not drawn here.
static func paint(ci: CanvasItem, name: String, p: Callable, u: float) -> bool:
	match name:
		"hands_dry", "hands_wet":
			for x: float in [30, 62]:
				ci.draw_rect(Rect2(p.call(x - 12, 34), Vector2(24, 40) * u), SKIN)
				for f in 4:
					ci.draw_rect(Rect2(p.call(x - 12 + f * 6, 22), Vector2(5, 14) * u), SKIN)
			if name == "hands_wet":
				for d: Vector2 in [Vector2(22, 82), Vector2(40, 88), Vector2(58, 84), Vector2(74, 90)]:
					ci.draw_circle(p.call(d.x, d.y), 4 * u, WATER)
				_spark(ci, p, u, Vector2(84, 30), 0.8)
			else:
				ci.draw_rect(Rect2(p.call(12, 78), Vector2(76, 12) * u), Color("f6b5a8"))
				_tick(ci, p, u, Vector2(82, 20))
		"plug":
			_plug(ci, p, u, Vector2(50, 46), 1.0)
			ci.draw_line(p.call(50, 64), p.call(50, 94), INK, 5 * u)
		"plug_broken":
			_plug(ci, p, u, Vector2(50, 46), 1.0)
			ci.draw_line(p.call(40, 34), p.call(52, 50), INK, 3 * u)
			ci.draw_line(p.call(52, 50), p.call(46, 62), INK, 3 * u)
			ci.draw_line(p.call(50, 64), p.call(58, 80), INK, 5 * u)
			ci.draw_line(p.call(50, 82), p.call(50, 94), INK, 5 * u)
		"fork_socket":
			_socket(ci, p, u, Vector2(36, 50), 1.0)
			ci.draw_line(p.call(56, 50), p.call(92, 30), Color("c9ced6"), 5 * u)
			for k in 3:
				ci.draw_line(p.call(56, 50), p.call(48, 44 + k * 6), Color("c9ced6"), 2.5 * u)
			_cross(ci, p, u, Vector2(80, 76))
		"frayed":
			ci.draw_line(p.call(6, 60), p.call(42, 54), INK, 9 * u)
			ci.draw_line(p.call(58, 50), p.call(94, 44), INK, 9 * u)
			for k in 3:
				ci.draw_line(p.call(42, 54), p.call(58, 50), [Color("c0563a"), Color("3a7be8"), Color("e8c84a")][k],
					2.5 * u)
			_spark(ci, p, u, Vector2(50, 34), 0.6)
		"socket_one":
			_socket(ci, p, u, Vector2(50, 50), 1.1)
			_plug(ci, p, u, Vector2(50, 50), 0.55)
			_tick(ci, p, u, Vector2(82, 20))
		"socket_many":
			_socket(ci, p, u, Vector2(30, 56), 0.9)
			ci.draw_rect(Rect2(p.call(40, 40), Vector2(30, 30) * u), PLUG)
			ci.draw_rect(Rect2(p.call(40, 40), Vector2(30, 30) * u), INK, false, 2 * u)
			ci.draw_rect(Rect2(p.call(66, 30), Vector2(26, 26) * u), PLUG)
			ci.draw_rect(Rect2(p.call(66, 30), Vector2(26, 26) * u), INK, false, 2 * u)
			for at: Vector2 in [Vector2(56, 78), Vector2(80, 64), Vector2(86, 20), Vector2(70, 14)]:
				ci.draw_rect(Rect2(p.call(at.x - 5, at.y - 5), Vector2(10, 10) * u), INK)
			ci.draw_arc(p.call(50, 54), 30 * u, -2.6, -1.8, 6, ORANGE, 3 * u)
		"kite_lines", "kite_field", "tree_lines":
			ci.draw_rect(Rect2(p.call(0, 80), Vector2(100, 20) * u), GRASS)
			if name != "kite_field":
				_pylon(ci, p, u)
			if name == "tree_lines":
				ci.draw_rect(Rect2(p.call(46, 50), Vector2(8, 32) * u), WOOD)
				ci.draw_circle(p.call(50, 40), 16 * u, Color("3f8a3a"))
				_spark(ci, p, u, Vector2(60, 22), 0.5)
			else:
				var at := Vector2(56, 24) if name == "kite_lines" else Vector2(60, 26)
				ci.draw_colored_polygon(PackedVector2Array([p.call(at.x, at.y - 12), p.call(at.x + 9, at.y),
					p.call(at.x, at.y + 12), p.call(at.x - 9, at.y)]), Color("e85a9a"))
				ci.draw_line(p.call(at.x, at.y + 12), p.call(30 if name == "kite_field" else 40, 78), INK, 1.5 * u)
				if name == "kite_field":
					LifeIconsMore._child(ci, p, u, Vector2(26, 50), 0.4, TEAL)
					_tick(ci, p, u, Vector2(84, 16))
		"substation":
			ci.draw_rect(Rect2(p.call(0, 82), Vector2(100, 18) * u), GRASS)
			for x in range(8, 96, 10):
				ci.draw_line(p.call(x, 38), p.call(x, 84), Color("9aa3ad"), 3 * u)
			ci.draw_line(p.call(6, 40), p.call(94, 40), Color("9aa3ad"), 3 * u)
			ci.draw_rect(Rect2(p.call(32, 46), Vector2(36, 22) * u), SPARK)
			ci.draw_colored_polygon(PackedVector2Array([p.call(50, 49), p.call(60, 65), p.call(40, 65)]), INK)
			ci.draw_circle(p.call(76, 76), 6 * u, Color("e85a9a"))
		"fuse_box":
			ci.draw_rect(Rect2(p.call(14, 18), Vector2(72, 64) * u), WHITE)
			ci.draw_rect(Rect2(p.call(14, 18), Vector2(72, 64) * u), INK, false, 3 * u)
			ci.draw_rect(Rect2(p.call(22, 34), Vector2(14, 30) * u), Color("e8544e"))
			for k in 4:
				ci.draw_rect(Rect2(p.call(42 + k * 10, 38), Vector2(7, 22) * u), INK.lightened(0.3))
			_tick(ci, p, u, Vector2(80, 14))
		"rcd":
			ci.draw_rect(Rect2(p.call(28, 14), Vector2(44, 72) * u), WHITE)
			ci.draw_rect(Rect2(p.call(28, 14), Vector2(44, 72) * u), INK, false, 3 * u)
			ci.draw_rect(Rect2(p.call(40, 52), Vector2(20, 26) * u), INK.lightened(0.3))
			ci.draw_circle(p.call(50, 32), 9 * u, Color("3a7be8"))
			_text(ci, p, u, Vector2(46, 36), "T")
		"two_stuck":
			_figure(ci, p, u, Vector2(32, 20), INK.lightened(0.45))
			_figure(ci, p, u, Vector2(66, 20), TEAL)
			ci.draw_line(p.call(40, 48), p.call(58, 48), SKIN, 6 * u)
			_spark(ci, p, u, Vector2(32, 62), 0.6)
			_spark(ci, p, u, Vector2(68, 62), 0.6)
			_cross(ci, p, u, Vector2(86, 16))
		"line_down":
			ci.draw_rect(Rect2(p.call(0, 70), Vector2(100, 30) * u), Color("c9b68a"))
			ci.draw_rect(Rect2(p.call(76, 14), Vector2(6, 58) * u), WOOD)
			ci.draw_line(p.call(78, 18), p.call(30, 78), INK, 3 * u)
			for r: float in [10, 18]:
				ci.draw_arc(p.call(30, 80), r * u, PI, TAU, 12, SPARK, 2.5 * u)
			LifeIconsMore._child(ci, p, u, Vector2(6, 22), 0.55, TEAL)
		"help_ok":
			ci.draw_rect(Rect2(p.call(10, 70), Vector2(80, 10) * u), Color("dfe7f5"))
			ci.draw_circle(p.call(26, 62), 9 * u, SKIN)
			ci.draw_rect(Rect2(p.call(34, 56), Vector2(40, 14) * u), INK.lightened(0.45))
			LifeIconsMore._child(ci, p, u, Vector2(66, 8), 0.6, TEAL)
			LifeIconsMore._heart(ci, p.call(84, 22), 8 * u, Color("e85a9a"))
		"ask_owner":
			_figure(ci, p, u, Vector2(66, 10), Color("7b5cd6"))
			LifeIconsMore._child(ci, p, u, Vector2(16, 30), 0.6, TEAL)
			_dog(ci, p, u, Vector2(56, 82), 0.55, false)
			ci.draw_circle(p.call(40, 22), 9 * u, WHITE)
			_text(ci, p, u, Vector2(36, 27), "?")
		"dog_hug":
			_dog(ci, p, u, Vector2(56, 80), 0.8, false)
			LifeIconsMore._child(ci, p, u, Vector2(24, 26), 0.6, TEAL)
			ci.draw_line(p.call(34, 50), p.call(58, 50), SKIN, 6 * u)
			_cross(ci, p, u, Vector2(86, 16))
		"dog_sleep":
			ci.draw_rect(Rect2(p.call(10, 78), Vector2(80, 8) * u), WOOD)
			_dog(ci, p, u, Vector2(50, 76), 0.8, false, true)
			for k in 3:
				_text(ci, p, u, Vector2(70 + k * 8, 34 - k * 8), "z")
		"dog_happy":
			_dog(ci, p, u, Vector2(50, 80), 1.0, false)
			ci.draw_arc(p.call(22, 54), 10 * u, -1.2, 0.4, 8, INK, 2 * u)
		"dog_warning":
			_dog(ci, p, u, Vector2(50, 80), 1.0, true)
		"be_a_tree":
			ci.draw_rect(Rect2(p.call(0, 88), Vector2(100, 12) * u), GRASS)
			ci.draw_circle(p.call(50, 22), 11 * u, SKIN)
			ci.draw_rect(Rect2(p.call(38, 32), Vector2(24, 36) * u), TEAL)
			ci.draw_rect(Rect2(p.call(34, 40), Vector2(32, 10) * u), TEAL.darkened(0.2))   # arms folded in
			ci.draw_line(p.call(44, 68), p.call(44, 88), Color("3a5aa8"), 7 * u)
			ci.draw_line(p.call(56, 68), p.call(56, 88), Color("3a5aa8"), 7 * u)
			ci.draw_line(p.call(47, 26), p.call(53, 26), INK, 2 * u)   # eyes down
			ci.draw_circle(p.call(80, 50), 10 * u, Color("3f8a3a"))
			ci.draw_rect(Rect2(p.call(78, 58), Vector2(4, 30) * u), WOOD)
		"swat":
			ci.draw_line(p.call(30, 76), p.call(70, 30), SKIN, 10 * u)
			ci.draw_circle(p.call(76, 22), 8 * u, Color("ffd23f"))
			ci.draw_line(p.call(72, 22), p.call(80, 22), INK, 3 * u)
			_cross(ci, p, u, Vector2(22, 22))
		"cow_edge":
			ci.draw_rect(Rect2(p.call(6, 6), Vector2(88, 88) * u), GRASS)
			ci.draw_rect(Rect2(p.call(6, 6), Vector2(88, 88) * u), WOOD, false, 4 * u)
			for at: Vector2 in [Vector2(46, 46), Vector2(60, 58)]:
				ci.draw_rect(Rect2(p.call(at.x - 9, at.y - 6), Vector2(18, 12) * u), WHITE)
				ci.draw_rect(Rect2(p.call(at.x - 4, at.y - 4), Vector2(6, 5) * u), INK)
			ci.draw_arc(p.call(50, 50), 36 * u, 0.3, 2.6, 14, GOLD, 3 * u)
			LifeIconsMore._child(ci, p, u, Vector2(14, 64), 0.3, TEAL)
		"snake":
			ci.draw_rect(Rect2(p.call(0, 74), Vector2(100, 26) * u), Color("c9b68a"))
			var pts := PackedVector2Array()
			for k in 9:
				pts.append(p.call(14 + k * 9, 70 + (6 if k % 2 == 0 else -6)))
			ci.draw_polyline(pts, Color("6d8a1f"), 7 * u)
			ci.draw_circle(p.call(88, 66), 5 * u, Color("6d8a1f"))
		"no_feed":
			ci.draw_rect(Rect2(p.call(18, 54), Vector2(30, 12) * u), Color("d99a4e"))
			ci.draw_colored_polygon(PackedVector2Array([p.call(64, 40), p.call(90, 54), p.call(64, 70)]), ORANGE)
			ci.draw_circle(p.call(62, 55), 10 * u, ORANGE)
			_cross(ci, p, u, Vector2(36, 26))
		"lean_forward", "head_back":
			ci.draw_rect(Rect2(p.call(24, 70), Vector2(40, 8) * u), WOOD)
			ci.draw_rect(Rect2(p.call(36, 40), Vector2(18, 32) * u), TEAL)
			if name == "lean_forward":
				ci.draw_circle(p.call(62, 38), 11 * u, SKIN)
				ci.draw_line(p.call(54, 48), p.call(66, 42), SKIN.darkened(0.15), 5 * u)   # the hand pinching
				_tick(ci, p, u, Vector2(84, 16))
			else:
				ci.draw_circle(p.call(40, 24), 11 * u, SKIN)
				_cross(ci, p, u, Vector2(84, 16))
		"spacer":
			ci.draw_rect(Rect2(p.call(16, 42), Vector2(56, 22) * u), Color(0.8, 0.88, 0.96, 0.9))
			ci.draw_rect(Rect2(p.call(16, 42), Vector2(56, 22) * u), INK, false, 2 * u)
			ci.draw_rect(Rect2(p.call(72, 48), Vector2(12, 10) * u), INK.lightened(0.3))
			ci.draw_rect(Rect2(p.call(6, 30), Vector2(12, 40) * u), Color("3a7be8"))
		"auto_pen":
			ci.draw_rect(Rect2(p.call(40, 14), Vector2(20, 62) * u), WHITE)
			ci.draw_rect(Rect2(p.call(40, 14), Vector2(20, 62) * u), INK, false, 2 * u)
			ci.draw_rect(Rect2(p.call(40, 6), Vector2(20, 10) * u), Color("3a7be8"))
			ci.draw_rect(Rect2(p.call(40, 76), Vector2(20, 12) * u), ORANGE)
			_arrow_up(ci, p, u, Vector2(24, 30))
		"cushion":
			ci.draw_rect(Rect2(p.call(14, 52), Vector2(72, 24) * u), Color("e85a9a").lightened(0.3))
			ci.draw_circle(p.call(50, 44), 12 * u, SKIN)
			_tick(ci, p, u, Vector2(84, 16))
		"nothing_mouth":
			ci.draw_circle(p.call(46, 50), 22 * u, SKIN)
			ci.draw_line(p.call(38, 60), p.call(54, 60), INK, 3 * u)
			ci.draw_line(p.call(62, 62), p.call(92, 50), Color("c9ced6"), 5 * u)
			_cross(ci, p, u, Vector2(84, 20))
		"hands_off":
			ci.draw_rect(Rect2(p.call(10, 74), Vector2(80, 8) * u), Color("dfe7f5"))
			ci.draw_circle(p.call(24, 66), 8 * u, SKIN)
			ci.draw_rect(Rect2(p.call(32, 62), Vector2(44, 10) * u), TEAL)
			for x: float in [30, 64]:
				ci.draw_rect(Rect2(p.call(x, 22), Vector2(14, 18) * u), SKIN)
			ci.draw_arc(p.call(50, 34), 28 * u, 0.0, TAU, 20, SOFT_NO, 3 * u)
		"tap_cold", "tap_hot":
			ci.draw_rect(Rect2(p.call(30, 30), Vector2(8, 30) * u), Color("c3cbd4"))
			ci.draw_rect(Rect2(p.call(30, 30), Vector2(30, 8) * u), Color("c3cbd4"))
			var c := Color("3a7be8") if name == "tap_cold" else Color("e8544e")
			ci.draw_circle(p.call(34, 22), 8 * u, c)
			for k in 3:
				ci.draw_circle(p.call(56, 46 + k * 10), 3 * u, WATER)
			if name == "tap_hot":
				for k in 3:
					ci.draw_arc(p.call(70 + k * 8, 40), 6 * u, PI, TAU, 6, Color(1, 1, 1, 0.8), 2 * u)
		"grapes", "grapes_cut":
			for k in 6:
				var at := Vector2(42 + (k % 3) * 10 + (5 if k >= 3 else 0), 40 + (k / 3) * 12)
				if name == "grapes":
					ci.draw_circle(p.call(at.x, at.y), 7 * u, Color("8a4fd6"))
				else:
					ci.draw_rect(Rect2(p.call(at.x - 5, at.y - 3), Vector2(6, 6) * u), Color("8a4fd6"))
					ci.draw_rect(Rect2(p.call(at.x + 1, at.y - 3), Vector2(4, 6) * u), Color("b48ae8"))
			ci.draw_line(p.call(52, 26), p.call(54, 34), Color("3f8a3a"), 3 * u)
			if name == "grapes_cut":
				_tick(ci, p, u, Vector2(84, 16))
		"water_pan":
			ci.draw_rect(Rect2(p.call(20, 62), Vector2(50, 16) * u), Color("6b7380"))
			ci.draw_line(p.call(70, 66), p.call(94, 62), INK, 5 * u)
			ci.draw_colored_polygon(PackedVector2Array([p.call(30, 62), p.call(45, 38), p.call(60, 62)]), FLAME)
			ci.draw_circle(p.call(46, 22), 6 * u, WATER)
			_cross(ci, p, u, Vector2(80, 22))
		"pan_lid":
			ci.draw_rect(Rect2(p.call(20, 60), Vector2(50, 18) * u), Color("6b7380"))
			ci.draw_line(p.call(70, 64), p.call(94, 60), INK, 5 * u)
			ci.draw_rect(Rect2(p.call(16, 52), Vector2(58, 8) * u), Color("9aa7b5"))
			ci.draw_rect(Rect2(p.call(40, 44), Vector2(10, 8) * u), INK)
			_tick(ci, p, u, Vector2(84, 16))
		"cling_film":
			ci.draw_circle(p.call(40, 54), 18 * u, SKIN)
			ci.draw_rect(Rect2(p.call(18, 38), Vector2(46, 32) * u), Color(0.85, 0.93, 1.0, 0.55))
			ci.draw_rect(Rect2(p.call(66, 22), Vector2(22, 12) * u), Color("c9ced6"))
		"goggles_on":
			ci.draw_circle(p.call(50, 52), 26 * u, SKIN)
			ci.draw_rect(Rect2(p.call(26, 40), Vector2(48, 16) * u), Color(0.6, 0.85, 1.0, 0.85))
			ci.draw_rect(Rect2(p.call(26, 40), Vector2(48, 16) * u), INK, false, 3 * u)
			for k in 4:
				ci.draw_rect(Rect2(p.call(70 + (k % 2) * 8, 12 + k * 5), Vector2(4, 4) * u), Color(0.92, 0.86, 0.72))
		"car_close":
			ci.draw_rect(Rect2(p.call(0, 60), Vector2(100, 40) * u), Color("4a5160"))
			LifeIconsMore._car(ci, p, u, Vector2(30, 70), 0.5, Color("3a7be8"))
			ci.draw_rect(Rect2(p.call(52, 66), Vector2(20, 8) * u), Color(1.0, 0.82, 0.3, 0.7))
			LifeIconsMore._child(ci, p, u, Vector2(76, 24), 0.55, TEAL)
		_:
			return false
	return true


# --- Shared shapes -----------------------------------------------------------------------------------------------------

static func _tick(ci: CanvasItem, p: Callable, u: float, at: Vector2) -> void:
	ci.draw_line(p.call(at.x - 8, at.y), p.call(at.x - 2, at.y + 7), GOOD, 5 * u)
	ci.draw_line(p.call(at.x - 2, at.y + 7), p.call(at.x + 10, at.y - 8), GOOD, 5 * u)


## A soft "no": a grey-blue cross (never red).
static func _cross(ci: CanvasItem, p: Callable, u: float, at: Vector2) -> void:
	ci.draw_line(p.call(at.x - 9, at.y - 9), p.call(at.x + 9, at.y + 9), SOFT_NO, 5 * u)
	ci.draw_line(p.call(at.x + 9, at.y - 9), p.call(at.x - 9, at.y + 9), SOFT_NO, 5 * u)


## A small yellow zigzag: electricity (never a flash).
static func _spark(ci: CanvasItem, p: Callable, u: float, at: Vector2, k: float) -> void:
	ci.draw_polyline(PackedVector2Array([p.call(at.x - 6 * k, at.y - 12 * k), p.call(at.x + 4 * k, at.y - 2 * k),
		p.call(at.x - 4 * k, at.y + 2 * k), p.call(at.x + 6 * k, at.y + 12 * k)]), SPARK, 4 * k * u)


static func _plug(ci: CanvasItem, p: Callable, u: float, at: Vector2, k: float) -> void:
	ci.draw_rect(Rect2(p.call(at.x - 16 * k, at.y - 18 * k), Vector2(32, 36) * k * u), PLUG)
	ci.draw_rect(Rect2(p.call(at.x - 16 * k, at.y - 18 * k), Vector2(32, 36) * k * u), INK, false, 2 * u)
	for x: float in [-8, 8]:
		ci.draw_rect(Rect2(p.call(at.x + x * k - 2 * k, at.y - 28 * k), Vector2(4, 10) * k * u), Color("c9a646"))


static func _socket(ci: CanvasItem, p: Callable, u: float, at: Vector2, k: float) -> void:
	ci.draw_rect(Rect2(p.call(at.x - 22 * k, at.y - 22 * k), Vector2(44, 44) * k * u), WALL.lightened(0.5))
	ci.draw_rect(Rect2(p.call(at.x - 22 * k, at.y - 22 * k), Vector2(44, 44) * k * u), INK, false, 2 * u)
	for x: float in [-8, 8]:
		ci.draw_rect(Rect2(p.call(at.x + x * k - 2 * k, at.y - 6 * k), Vector2(4, 10) * k * u), INK)


static func _pylon(ci: CanvasItem, p: Callable, u: float) -> void:
	for x: float in [14, 86]:
		ci.draw_line(p.call(x, 82), p.call(x, 10), Color("9aa3ad"), 4 * u)
		ci.draw_line(p.call(x - 8, 14), p.call(x + 8, 14), Color("9aa3ad"), 3 * u)
	for y: float in [14, 20]:
		ci.draw_line(p.call(14, y), p.call(86, y + 4), INK, 1.5 * u)


static func _figure(ci: CanvasItem, p: Callable, u: float, head: Vector2, colour: Color) -> void:
	ci.draw_circle(p.call(head.x, head.y), 10 * u, SKIN)
	ci.draw_rect(Rect2(p.call(head.x - 11, head.y + 11), Vector2(22, 34) * u), colour)
	ci.draw_line(p.call(head.x - 5, head.y + 45), p.call(head.x - 6, head.y + 70), Color("3a5aa8"), 7 * u)
	ci.draw_line(p.call(head.x + 5, head.y + 45), p.call(head.x + 6, head.y + 70), Color("3a5aa8"), 7 * u)


## A friendly blocky dog standing (feet at `feet`); `warning`: its signs (stiff, ears up, tail high, a hard stare);
## `lying`: asleep.
static func _dog(ci: CanvasItem, p: Callable, u: float, feet: Vector2, k: float, warning: bool, lying: bool = false) -> void:
	var body_y := feet.y - (12 if lying else 26) * k
	ci.draw_rect(Rect2(p.call(feet.x - 24 * k, body_y - 8 * k), Vector2(44, 18) * k * u), DOG)
	if not lying:
		for x: float in [-20, -8, 8, 16]:
			ci.draw_rect(Rect2(p.call(feet.x + x * k, body_y + 8 * k), Vector2(5, 18) * k * u), DOG.darkened(0.15))
	var head := Vector2(feet.x + 26 * k, body_y - (2 if lying else 12) * k)
	ci.draw_rect(Rect2(p.call(head.x - 9 * k, head.y - 9 * k), Vector2(20, 18) * k * u), DOG.lightened(0.1))
	ci.draw_rect(Rect2(p.call(head.x + 8 * k, head.y - 2 * k), Vector2(8, 8) * k * u), DOG.lightened(0.2))
	if lying:
		ci.draw_line(p.call(head.x - 2 * k, head.y - 2 * k), p.call(head.x + 4 * k, head.y - 2 * k), INK, 2 * u)
	else:
		ci.draw_circle(p.call(head.x + 2 * k, head.y - 3 * k), 2.2 * k * u, INK)
	if warning:
		ci.draw_rect(Rect2(p.call(head.x - 7 * k, head.y - 18 * k), Vector2(5, 10) * k * u), DOG.darkened(0.2))   # ears up
		ci.draw_line(p.call(feet.x - 24 * k, body_y - 6 * k), p.call(feet.x - 30 * k, body_y - 26 * k), DOG.darkened(0.2),
			5 * k * u)   # the tail held high and stiff
		ci.draw_line(p.call(head.x + 8 * k, head.y + 5 * k), p.call(head.x + 15 * k, head.y + 5 * k), WHITE, 2 * k * u)
		ci.draw_line(p.call(head.x - 4 * k, head.y - 8 * k), p.call(head.x + 6 * k, head.y - 6 * k), INK, 2 * k * u)
	else:
		ci.draw_rect(Rect2(p.call(head.x - 9 * k, head.y - 6 * k), Vector2(5, 12) * k * u), DOG.darkened(0.2))   # soft ears
		ci.draw_line(p.call(feet.x - 24 * k, body_y - 2 * k), p.call(feet.x - 32 * k, body_y + 4 * k), DOG.darkened(0.2),
			4 * k * u)   # a loose, low tail


static func _arrow_up(ci: CanvasItem, p: Callable, u: float, at: Vector2) -> void:
	ci.draw_line(p.call(at.x, at.y + 16), p.call(at.x, at.y - 10), Color("3a7be8"), 4 * u)
	ci.draw_colored_polygon(PackedVector2Array([p.call(at.x - 7, at.y - 6), p.call(at.x, at.y - 16),
		p.call(at.x + 7, at.y - 6)]), Color("3a7be8"))


static func _text(ci: CanvasItem, p: Callable, u: float, at: Vector2, t: String) -> void:
	ci.draw_string(ThemeDB.fallback_font, p.call(at.x, at.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, int(14 * u), INK)
