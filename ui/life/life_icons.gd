class_name LifeIcons
extends Control
## Owner #112, #113 (docs/design/life-skills.md §10: "heard, not read", every line with a picture): Life's pictures,
## drawn in code from simple shapes (our own art, spec §3c; nothing loaded): the picture answers of the Experiences and
## their before-and-after checks, the ten areas, the three tracks and the Passport's stamps. Calm and friendly: no
## injuries, no scary faces; a "no" is a soft grey-blue, never red. `LifeIcons.new(name, px)` is a Control showing one;
## `paint(ci, name, rect)` draws one anywhere.

const NAMES: Array[String] = ["tick", "cross", "buddy", "buddy_hurt", "toy", "teddy", "food", "house", "question",
	"rocket", "ambulance", "fire_engine", "police", "talking", "sleeping", "phone", "door", "cloth", "water", "clock",
	"recovery", "lying", "sitting", "grown_up", "ice", "butter", "hands_chest", "tummy", "arm", "cough", "back", "aed",
	"bed", "firefighter", "low", "stand", "candle", "apple", "book", "hand", "arrow", "roll", "run", "tree", "small_fire",
	"big_fire", "extinguisher", "coins", "robot", "sweets", "jar", "bank", "bread", "milk", "message", "lock",
	# the ten areas
	"heart", "smile", "people", "shield", "screen", "map", "bulb", "leaf",
	# the tracks and the Passport
	"track_little", "track_middle", "track_big", "stamp_done", "stamp_self", "stamp_expert", "passport"]

const INK := Color("1f2a4a")
const SKIN := Color("f2c79b")
const TEAL := Color("1fa6a0")
const SOFT_NO := Color("6b7a99")
const GOOD := Color("2fae4e")
const WARM := Color("f08a1c")
const FLAME := Color("ff9d2e")
const FLAME_IN := Color("ffd23f")
const GOLD := Color("ffc93c")
const WOOD := Color("a8642a")
const SKY := Color("5aa8e6")
const SMOKE := Color(0.62, 0.64, 0.7, 0.85)
const WHITE := Color("fdfdf8")

var icon := ""


static func has(name: String) -> bool:
	return NAMES.has(name) or LifeIconsMore.has(name) or LifeIconsDanger.has(name) or LifeIconsHazards.has(name) \
		or SuccessIcons.has(name) or LifeIconsEveryday.has(name)   # Life L2's, L3a's, L3b's and L3c's pictures (owner
		# #112, #118); Success S2's (owner #115)


func _init(name: String = "", px: float = 96.0) -> void:
	icon = name
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	paint(self, icon, Rect2(Vector2.ZERO, size))


## Draws picture `name` in `r` (a square inside it; nothing for an unknown name).
static func paint(ci: CanvasItem, name: String, r: Rect2) -> void:
	var s := minf(r.size.x, r.size.y)
	var o := r.position + (r.size - Vector2(s, s)) * 0.5
	var u := s / 100.0
	var p := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * u
	if not NAMES.has(name):
		if SuccessIcons.has(name):   # owner #115: Success S2's pictures
			SuccessIcons.paint(ci, name, p, u)
			return
		if not LifeIconsMore.paint(ci, name, p, u):   # Life L2's pictures (owner #112)
			if not LifeIconsDanger.paint(ci, name, p, u):   # Life L3a's (owner #118)
				if not LifeIconsHazards.paint(ci, name, p, u):   # Life L3b's (owner #118)
					LifeIconsEveryday.paint(ci, name, p, u)   # Life L3c's (owner #112, #118)
		return
	match name:
		"tick":
			ci.draw_circle(p.call(50, 50), 44 * u, GOOD)
			ci.draw_polyline(PackedVector2Array([p.call(28, 52), p.call(44, 68), p.call(74, 34)]), WHITE, 9 * u, true)
		"cross":
			ci.draw_circle(p.call(50, 50), 44 * u, SOFT_NO)
			ci.draw_line(p.call(32, 32), p.call(68, 68), WHITE, 9 * u, true)
			ci.draw_line(p.call(68, 32), p.call(32, 68), WHITE, 9 * u, true)
		"buddy", "buddy_hurt", "talking", "sleeping", "cough":
			_face(ci, p, u, TEAL if name != "talking" and name != "sleeping" and name != "cough" else SKIN, name)
		"toy":
			ci.draw_circle(p.call(50, 52), 38 * u, Color("e8544e"))
			ci.draw_arc(p.call(50, 52), 38 * u, -0.6, 0.6, 12, FLAME_IN, 10 * u)
			ci.draw_arc(p.call(50, 52), 38 * u, PI - 0.6, PI + 0.6, 12, Color("3a7be8"), 10 * u)
			ci.draw_circle(p.call(38, 38), 7 * u, Color(1, 1, 1, 0.6))
		"teddy":
			for e: Vector2 in [Vector2(26, 26), Vector2(74, 26)]:
				ci.draw_circle(p.call(e.x, e.y), 14 * u, WOOD)
			ci.draw_circle(p.call(50, 54), 36 * u, WOOD.lightened(0.15))
			ci.draw_circle(p.call(50, 66), 14 * u, Color("e6c39a"))
			for e: Vector2 in [Vector2(38, 46), Vector2(62, 46)]:
				ci.draw_circle(p.call(e.x, e.y), 4.5 * u, INK)
			ci.draw_circle(p.call(50, 62), 5 * u, INK)
		"food":
			ci.draw_circle(p.call(50, 56), 38 * u, WHITE)
			ci.draw_circle(p.call(50, 56), 28 * u, Color("f3e6c8"))
			ci.draw_circle(p.call(40, 52), 9 * u, Color("e8544e"))
			ci.draw_circle(p.call(58, 60), 9 * u, GOOD)
			ci.draw_rect(Rect2(p.call(45, 38), Vector2(16, 10) * u), Color("e8b65a"))
		"house":
			_house(ci, p, u)
		"question":
			ci.draw_circle(p.call(50, 50), 44 * u, Color("8b6fd6"))
			ci.draw_arc(p.call(50, 40), 14 * u, PI, TAU + 0.6, 14, WHITE, 8 * u)
			ci.draw_line(p.call(58, 52), p.call(50, 60), WHITE, 8 * u)
			ci.draw_circle(p.call(50, 74), 5 * u, WHITE)
		"rocket":
			ci.draw_colored_polygon(PackedVector2Array([p.call(50, 8), p.call(66, 34), p.call(66, 72), p.call(34, 72),
				p.call(34, 34)]), WHITE)
			ci.draw_colored_polygon(PackedVector2Array([p.call(34, 56), p.call(20, 80), p.call(34, 74)]), Color("e8544e"))
			ci.draw_colored_polygon(PackedVector2Array([p.call(66, 56), p.call(80, 80), p.call(66, 74)]), Color("e8544e"))
			ci.draw_circle(p.call(50, 42), 9 * u, SKY)
			ci.draw_colored_polygon(PackedVector2Array([p.call(40, 72), p.call(50, 94), p.call(60, 72)]), FLAME)
		"ambulance", "fire_engine", "police":
			_vehicle(ci, p, u, name)
		"phone":
			ci.draw_rect(Rect2(p.call(28, 8), Vector2(44, 84) * u), INK)
			ci.draw_rect(Rect2(p.call(32, 16), Vector2(36, 58) * u), Color("9fd8ff"))
			ci.draw_circle(p.call(50, 83), 5 * u, Color(1, 1, 1, 0.7))
			ci.draw_line(p.call(40, 36), p.call(44, 48), GOOD, 5 * u)
			ci.draw_line(p.call(44, 48), p.call(58, 54), GOOD, 5 * u)
		"door":
			ci.draw_rect(Rect2(p.call(22, 8), Vector2(56, 86) * u), GOOD.darkened(0.2))
			ci.draw_rect(Rect2(p.call(30, 14), Vector2(40, 80) * u), WOOD)
			ci.draw_circle(p.call(62, 56), 4.5 * u, GOLD)
		"cloth":
			ci.draw_rect(Rect2(p.call(18, 24), Vector2(64, 54) * u), WHITE)
			for y: float in [36, 48, 60]:
				ci.draw_line(p.call(24, y), p.call(76, y), Color("b9d4e8"), 3 * u)
			ci.draw_rect(Rect2(p.call(18, 24), Vector2(64, 54) * u), Color("9db3c7"), false, 3 * u)
		"water":
			ci.draw_rect(Rect2(p.call(20, 10), Vector2(50, 14) * u), Color("9aa7b5"))
			ci.draw_rect(Rect2(p.call(56, 16), Vector2(14, 22) * u), Color("9aa7b5"))
			for d: Vector2 in [Vector2(63, 52), Vector2(56, 72), Vector2(70, 84)]:
				_drop(ci, p.call(d.x, d.y), 9 * u, SKY)
		"clock":
			ci.draw_circle(p.call(50, 50), 42 * u, WHITE)
			ci.draw_arc(p.call(50, 50), 42 * u, 0, TAU, 40, INK, 5 * u)
			ci.draw_line(p.call(50, 50), p.call(50, 22), INK, 6 * u)
			ci.draw_line(p.call(50, 50), p.call(70, 56), INK, 6 * u)
		"recovery":
			_floor(ci, p, u)
			ci.draw_circle(p.call(20, 64), 9 * u, SKIN)
			ci.draw_line(p.call(30, 68), p.call(64, 70), TEAL, 10 * u)
			ci.draw_polyline(PackedVector2Array([p.call(64, 70), p.call(76, 56), p.call(86, 74)]), Color("3a5aa8"), 8 * u)
			ci.draw_polyline(PackedVector2Array([p.call(40, 66), p.call(46, 54), p.call(30, 54)]), TEAL, 6 * u)
		"lying":
			_floor(ci, p, u)
			ci.draw_circle(p.call(18, 68), 9 * u, SKIN)
			ci.draw_line(p.call(28, 70), p.call(66, 70), TEAL, 10 * u)
			ci.draw_line(p.call(66, 70), p.call(88, 72), Color("3a5aa8"), 8 * u)
		"sitting":
			_floor(ci, p, u)
			ci.draw_circle(p.call(40, 30), 10 * u, SKIN)
			ci.draw_line(p.call(40, 40), p.call(40, 72), TEAL, 11 * u)
			ci.draw_polyline(PackedVector2Array([p.call(40, 74), p.call(66, 74), p.call(70, 82)]), Color("3a5aa8"), 8 * u)
		"grown_up":
			_person(ci, p, u, Vector2(36, 18), 1.0, Color("7b5cd6"))
			_person(ci, p, u, Vector2(70, 46), 0.6, TEAL)
		"ice":
			for c: Vector2 in [Vector2(22, 46), Vector2(52, 40), Vector2(36, 62)]:
				ci.draw_rect(Rect2(p.call(c.x, c.y), Vector2(28, 28) * u), Color("bfe9ff"))
				ci.draw_rect(Rect2(p.call(c.x, c.y), Vector2(28, 28) * u), Color("7cc6ee"), false, 2.5 * u)
		"butter":
			ci.draw_rect(Rect2(p.call(12, 64), Vector2(76, 14) * u), WHITE)
			ci.draw_colored_polygon(PackedVector2Array([p.call(26, 64), p.call(30, 40), p.call(72, 40), p.call(76, 64)]),
				Color("ffe27a"))
		"hands_chest":
			ci.draw_rect(Rect2(p.call(16, 46), Vector2(68, 44) * u), TEAL)
			ci.draw_circle(p.call(50, 54), 18 * u, SKIN)
			ci.draw_circle(p.call(50, 46), 14 * u, SKIN.darkened(0.08))
			ci.draw_line(p.call(50, 30), p.call(50, 14), WARM, 4 * u)
			ci.draw_colored_polygon(PackedVector2Array([p.call(42, 22), p.call(58, 22), p.call(50, 34)]), WARM)
		"tummy":
			_person(ci, p, u, Vector2(50, 10), 1.0, TEAL)
			ci.draw_arc(p.call(50, 64), 12 * u, 0, TAU, 20, WARM, 4 * u)
		"arm":
			ci.draw_polyline(PackedVector2Array([p.call(18, 30), p.call(54, 50), p.call(70, 22)]), SKIN, 16 * u)
			ci.draw_circle(p.call(72, 18), 10 * u, SKIN)
		"back":
			ci.draw_circle(p.call(40, 22), 12 * u, Color("5a3b2a"))
			ci.draw_rect(Rect2(p.call(26, 34), Vector2(28, 44) * u), TEAL)
			ci.draw_circle(p.call(68, 44), 10 * u, SKIN)
			ci.draw_line(p.call(68, 44), p.call(54, 46), SKIN, 8 * u)
		"aed":
			ci.draw_rect(Rect2(p.call(14, 18), Vector2(72, 64) * u), GOOD)
			_heart(ci, p.call(50, 52), 24 * u, WHITE)
			ci.draw_polyline(PackedVector2Array([p.call(54, 32), p.call(44, 52), p.call(56, 52), p.call(46, 72)]),
				GOOD.darkened(0.3), 5 * u)
		"bed":
			ci.draw_rect(Rect2(p.call(10, 50), Vector2(80, 20) * u), Color("7b8ed6"))
			ci.draw_rect(Rect2(p.call(10, 36), Vector2(10, 46) * u), WOOD)
			ci.draw_rect(Rect2(p.call(80, 44), Vector2(10, 38) * u), WOOD)
			ci.draw_rect(Rect2(p.call(20, 42), Vector2(18, 10) * u), WHITE)
		"firefighter":
			ci.draw_circle(p.call(50, 58), 26 * u, SKIN)
			ci.draw_colored_polygon(PackedVector2Array([p.call(18, 46), p.call(26, 22), p.call(74, 22), p.call(82, 46)]),
				FLAME_IN)
			ci.draw_rect(Rect2(p.call(14, 44), Vector2(72, 8) * u), FLAME_IN.darkened(0.15))
			for e: Vector2 in [Vector2(42, 60), Vector2(58, 60)]:
				ci.draw_circle(p.call(e.x, e.y), 3.5 * u, INK)
			ci.draw_arc(p.call(50, 66), 8 * u, 0.3, PI - 0.3, 8, INK, 3 * u)
		"low", "stand":
			ci.draw_rect(Rect2(p.call(4, 6), Vector2(92, 30) * u), SMOKE)
			if name == "low":
				ci.draw_circle(p.call(30, 64), 10 * u, SKIN)
				ci.draw_polyline(PackedVector2Array([p.call(38, 70), p.call(70, 70), p.call(76, 86)]), TEAL, 10 * u)
				ci.draw_line(p.call(40, 72), p.call(36, 88), TEAL, 7 * u)
			else:
				_person(ci, p, u, Vector2(50, 14), 1.0, TEAL)
		"candle":
			ci.draw_rect(Rect2(p.call(40, 40), Vector2(20, 50) * u), WHITE)
			_flame(ci, p.call(50, 30), 12 * u)
			ci.draw_rect(Rect2(p.call(70, 10), Vector2(18, 80) * u), Color("c46aa0"))
		"apple":
			ci.draw_circle(p.call(50, 58), 32 * u, Color("e8544e"))
			ci.draw_line(p.call(50, 28), p.call(54, 14), WOOD, 5 * u)
			ci.draw_colored_polygon(PackedVector2Array([p.call(56, 22), p.call(74, 14), p.call(64, 28)]), GOOD)
		"book":
			ci.draw_rect(Rect2(p.call(22, 16), Vector2(56, 70) * u), Color("3a7be8"))
			ci.draw_rect(Rect2(p.call(28, 16), Vector2(6, 70) * u), Color("2a5bb8"))
			ci.draw_rect(Rect2(p.call(40, 30), Vector2(30, 8) * u), WHITE)
		"hand":
			ci.draw_rect(Rect2(p.call(30, 40), Vector2(40, 40) * u), SKIN)
			for i in 4:
				ci.draw_rect(Rect2(p.call(30 + i * 10.5, 14 + absf(i - 1.5) * 4), Vector2(8, 30) * u), SKIN)
			ci.draw_line(p.call(30, 54), p.call(16, 40), SKIN, 9 * u)
			ci.draw_rect(Rect2(p.call(30, 80), Vector2(40, 12) * u), TEAL)
		"arrow":
			ci.draw_arc(p.call(50, 56), 30 * u, PI, TAU - 0.5, 20, GOOD, 10 * u)
			var tip: Vector2 = p.call(50, 56) + Vector2(cos(TAU - 0.5), sin(TAU - 0.5)) * 30 * u
			ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-12, -10) * u, tip + Vector2(14, -2) * u,
				tip + Vector2(-4, 16) * u]), GOOD)
		"roll":
			ci.draw_arc(p.call(50, 50), 34 * u, 0.2, PI - 0.2, 16, Color("8b6fd6"), 6 * u)
			ci.draw_arc(p.call(50, 50), 34 * u, PI + 0.2, TAU - 0.2, 16, Color("8b6fd6"), 6 * u)
			ci.draw_circle(p.call(50, 36), 9 * u, SKIN)
			ci.draw_line(p.call(50, 46), p.call(50, 66), TEAL, 10 * u)
		"run":
			ci.draw_circle(p.call(56, 18), 10 * u, SKIN)
			ci.draw_line(p.call(54, 28), p.call(46, 56), TEAL, 10 * u)
			ci.draw_polyline(PackedVector2Array([p.call(46, 56), p.call(62, 70), p.call(58, 88)]), Color("3a5aa8"), 7 * u)
			ci.draw_polyline(PackedVector2Array([p.call(46, 56), p.call(30, 72), p.call(18, 70)]), Color("3a5aa8"), 7 * u)
			ci.draw_polyline(PackedVector2Array([p.call(52, 34), p.call(70, 44), p.call(78, 32)]), TEAL, 6 * u)
		"tree":
			ci.draw_rect(Rect2(p.call(44, 56), Vector2(12, 36) * u), WOOD)
			ci.draw_circle(p.call(50, 40), 30 * u, GOOD)
			ci.draw_circle(p.call(36, 50), 18 * u, GOOD.darkened(0.1))
			ci.draw_circle(p.call(64, 50), 18 * u, GOOD.darkened(0.1))
		"small_fire":
			ci.draw_colored_polygon(PackedVector2Array([p.call(30, 56), p.call(70, 56), p.call(64, 90), p.call(36, 90)]),
				Color("9aa7b5"))
			_flame(ci, p.call(50, 44), 16 * u)
		"big_fire":
			for f: Vector3 in [Vector3(30, 50, 22), Vector3(70, 50, 22), Vector3(50, 40, 32)]:
				_flame(ci, p.call(f.x, f.y), f.z * u)
			ci.draw_rect(Rect2(p.call(4, 4), Vector2(92, 16) * u), SMOKE)
		"extinguisher":
			ci.draw_rect(Rect2(p.call(36, 30), Vector2(28, 62) * u), Color("d9463b"))
			ci.draw_rect(Rect2(p.call(40, 18), Vector2(20, 12) * u), INK)
			ci.draw_polyline(PackedVector2Array([p.call(60, 22), p.call(80, 26), p.call(84, 44)]), INK, 5 * u)
			ci.draw_rect(Rect2(p.call(40, 50), Vector2(20, 14) * u), WHITE)
		"coins":
			for i in 3:
				var c: Vector2 = p.call(50, 78 - i * 12)
				ci.draw_rect(Rect2(c - Vector2(28, 0) * u, Vector2(56, 10) * u), GOLD.darkened(0.2))
				ci.draw_rect(Rect2(c - Vector2(28, 6) * u, Vector2(56, 8) * u), GOLD)
			ci.draw_circle(p.call(50, 36), 24 * u, GOLD)
			ci.draw_arc(p.call(50, 36), 16 * u, 0, TAU, 20, GOLD.darkened(0.25), 3 * u)
		"robot":
			ci.draw_rect(Rect2(p.call(24, 26), Vector2(52, 44) * u), Color("9aa7b5"))
			ci.draw_line(p.call(50, 26), p.call(50, 12), INK, 4 * u)
			ci.draw_circle(p.call(50, 10), 5 * u, Color("e8544e"))
			for e: Vector2 in [Vector2(38, 44), Vector2(62, 44)]:
				ci.draw_circle(p.call(e.x, e.y), 7 * u, SKY)
			ci.draw_rect(Rect2(p.call(36, 58), Vector2(28, 5) * u), INK)
			ci.draw_rect(Rect2(p.call(30, 72), Vector2(40, 20) * u), Color("7d8a99"))
		"sweets":
			ci.draw_circle(p.call(50, 50), 20 * u, Color("e85a9a"))
			ci.draw_colored_polygon(PackedVector2Array([p.call(32, 50), p.call(12, 36), p.call(12, 64)]), Color("f0a0c8"))
			ci.draw_colored_polygon(PackedVector2Array([p.call(68, 50), p.call(88, 36), p.call(88, 64)]), Color("f0a0c8"))
		"jar":
			ci.draw_rect(Rect2(p.call(26, 26), Vector2(48, 66) * u), Color(0.8, 0.92, 1.0, 0.6))
			ci.draw_rect(Rect2(p.call(30, 14), Vector2(40, 12) * u), WOOD)
			for i in 3:
				ci.draw_rect(Rect2(p.call(32, 80 - i * 9), Vector2(36, 7) * u), GOLD)
			ci.draw_colored_polygon(PackedVector2Array([p.call(50, 36), p.call(56, 46), p.call(56, 56), p.call(44, 56),
				p.call(44, 46)]), WHITE)
		"bank":
			ci.draw_colored_polygon(PackedVector2Array([p.call(10, 34), p.call(50, 10), p.call(90, 34)]), Color("c49a12"))
			for x: float in [18, 36, 56, 74]:
				ci.draw_rect(Rect2(p.call(x, 38), Vector2(9, 40) * u), WHITE)
			ci.draw_rect(Rect2(p.call(10, 80), Vector2(80, 10) * u), Color("c49a12"))
		"bread":
			ci.draw_circle(p.call(50, 54), 34 * u, Color("d99a4e"))
			ci.draw_rect(Rect2(p.call(16, 54), Vector2(68, 30) * u), Color("d99a4e"))
			for x: float in [36, 50, 64]:
				ci.draw_line(p.call(x - 6, 40), p.call(x + 6, 56), Color("f3c98a"), 4 * u)
		"milk":
			ci.draw_rect(Rect2(p.call(30, 30), Vector2(40, 62) * u), WHITE)
			ci.draw_colored_polygon(PackedVector2Array([p.call(30, 30), p.call(40, 14), p.call(60, 14), p.call(70, 30)]),
				Color("dfe9f5"))
			ci.draw_rect(Rect2(p.call(30, 50), Vector2(40, 16) * u), SKY)
		"message":
			ci.draw_rect(Rect2(p.call(12, 24), Vector2(76, 52) * u), WHITE)
			ci.draw_polyline(PackedVector2Array([p.call(12, 24), p.call(50, 54), p.call(88, 24)]), Color("9db3c7"), 4 * u)
			ci.draw_rect(Rect2(p.call(12, 24), Vector2(76, 52) * u), Color("9db3c7"), false, 3 * u)
		"lock":
			ci.draw_arc(p.call(50, 42), 18 * u, PI, TAU, 14, Color("9aa7b5"), 8 * u)
			ci.draw_rect(Rect2(p.call(26, 42), Vector2(48, 44) * u), GOLD)
			ci.draw_circle(p.call(50, 60), 6 * u, INK)
			ci.draw_line(p.call(50, 62), p.call(50, 74), INK, 4 * u)
		"heart":
			_heart(ci, p.call(50, 54), 40 * u, Color("e8544e"))
		"smile":
			ci.draw_circle(p.call(50, 50), 42 * u, FLAME_IN)
			for e: Vector2 in [Vector2(36, 42), Vector2(64, 42)]:
				ci.draw_circle(p.call(e.x, e.y), 5 * u, INK)
			ci.draw_arc(p.call(50, 54), 20 * u, 0.4, PI - 0.4, 12, INK, 5 * u)
		"people":
			_person(ci, p, u, Vector2(34, 18), 0.85, Color("7b5cd6"))
			_person(ci, p, u, Vector2(66, 18), 0.85, WARM)
		"shield":
			ci.draw_colored_polygon(PackedVector2Array([p.call(50, 8), p.call(86, 20), p.call(80, 60), p.call(50, 92),
				p.call(20, 60), p.call(14, 20)]), GOOD)
			ci.draw_rect(Rect2(p.call(44, 30), Vector2(12, 40) * u), WHITE)
			ci.draw_rect(Rect2(p.call(30, 44), Vector2(40, 12) * u), WHITE)
		"screen":
			ci.draw_rect(Rect2(p.call(10, 18), Vector2(80, 54) * u), INK)
			ci.draw_rect(Rect2(p.call(16, 24), Vector2(68, 42) * u), Color("9fd8ff"))
			ci.draw_rect(Rect2(p.call(40, 72), Vector2(20, 14) * u), INK)
			_heart(ci, p.call(50, 46), 14 * u, Color("e85a9a"))
		"map":
			ci.draw_colored_polygon(PackedVector2Array([p.call(10, 20), p.call(36, 12), p.call(64, 22), p.call(90, 14),
				p.call(90, 82), p.call(64, 90), p.call(36, 80), p.call(10, 88)]), Color("cfe9b0"))
			ci.draw_polyline(PackedVector2Array([p.call(18, 74), p.call(40, 50), p.call(62, 58), p.call(80, 30)]),
				Color("9aa7b5"), 5 * u)
			_drop(ci, p.call(70, 32), 12 * u, Color("e8544e"))
		"bulb":
			ci.draw_circle(p.call(50, 40), 28 * u, FLAME_IN)
			ci.draw_rect(Rect2(p.call(38, 64), Vector2(24, 20) * u), Color("9aa7b5"))
			for a in 5:
				var ang := PI + a * PI / 4.0
				ci.draw_line(p.call(50, 40) + Vector2(cos(ang), sin(ang)) * 34 * u,
					p.call(50, 40) + Vector2(cos(ang), sin(ang)) * 44 * u, FLAME_IN, 4 * u)
		"leaf":
			ci.draw_circle(p.call(50, 50), 40 * u, SKY)
			ci.draw_colored_polygon(PackedVector2Array([p.call(28, 70), p.call(36, 30), p.call(74, 24), p.call(66, 62)]),
				GOOD)
			ci.draw_line(p.call(28, 70), p.call(66, 34), GOOD.darkened(0.3), 3 * u)
		"track_little", "track_middle", "track_big":
			var k := {"track_little": 0.55, "track_middle": 0.78, "track_big": 1.0}[name] as float
			_person(ci, p, u, Vector2(50, 92 - 80 * k), k, {"track_little": Color("ffb347"), "track_middle": Color("3a7be8"),
				"track_big": Color("7b5cd6")}[name] as Color)
		"stamp_done", "stamp_self", "stamp_expert":
			var ink: Color = {"stamp_done": GOOD, "stamp_self": Color("3a7be8"), "stamp_expert": GOLD.darkened(0.2)}[name]
			ci.draw_circle(p.call(50, 50), 44 * u, Color(1, 0.98, 0.92, 0.95))
			ci.draw_arc(p.call(50, 50), 44 * u, 0, TAU, 40, ink, 6 * u)
			ci.draw_arc(p.call(50, 50), 36 * u, 0, TAU, 40, ink, 2 * u)
			if name == "stamp_done":
				ci.draw_polyline(PackedVector2Array([p.call(30, 52), p.call(44, 66), p.call(72, 36)]), ink, 8 * u, true)
			elif name == "stamp_self":
				_person(ci, p, u, Vector2(50, 22), 0.6, ink)
			else:
				ci.draw_colored_polygon(SchoolUi.star_points(p.call(50, 52), 28 * u), ink)
		"passport":
			ci.draw_rect(Rect2(p.call(18, 8), Vector2(64, 84) * u), Color("2f7f6a"))
			ci.draw_arc(p.call(50, 44), 18 * u, 0, TAU, 24, GOLD, 4 * u)
			ci.draw_line(p.call(32, 44), p.call(68, 44), GOLD, 3 * u)
			ci.draw_rect(Rect2(p.call(32, 72), Vector2(36, 6) * u), GOLD)


static func _face(ci: CanvasItem, p: Callable, u: float, colour: Color, kind: String) -> void:
	ci.draw_rect(Rect2(p.call(14, 14), Vector2(72, 72) * u), colour)
	ci.draw_rect(Rect2(p.call(14, 14), Vector2(72, 72) * u), colour.darkened(0.25), false, 3 * u)
	if kind == "sleeping":
		for x: float in [36, 64]:
			ci.draw_arc(p.call(x, 44), 7 * u, 0.2, PI - 0.2, 8, INK, 4 * u)
		ci.draw_line(p.call(70, 18), p.call(84, 18), INK, 3 * u)
		ci.draw_line(p.call(84, 18), p.call(70, 30), INK, 3 * u)
		ci.draw_line(p.call(70, 30), p.call(84, 30), INK, 3 * u)
	else:
		for x: float in [36, 64]:
			ci.draw_circle(p.call(x, 44), 6 * u, INK)
			ci.draw_circle(p.call(x + 2, 42), 2 * u, WHITE)
	match kind:
		"talking":
			ci.draw_circle(p.call(50, 66), 8 * u, Color("8a3a3a"))
			for i in 2:
				ci.draw_arc(p.call(84, 60), (8 + i * 8) * u, -0.7, 0.7, 8, INK, 3 * u)
		"cough":
			ci.draw_circle(p.call(50, 66), 6 * u, Color("8a3a3a"))
			for c: Vector2 in [Vector2(80, 66), Vector2(90, 58), Vector2(88, 74)]:
				ci.draw_circle(p.call(c.x, c.y), 6 * u, Color(1, 1, 1, 0.85))
		"sleeping":
			ci.draw_arc(p.call(50, 66), 8 * u, 0.3, PI - 0.3, 8, INK, 3 * u)
		_:
			ci.draw_arc(p.call(50, 60), 14 * u, 0.4, PI - 0.4, 10, INK, 4 * u)
	if kind == "buddy_hurt":
		ci.draw_rect(Rect2(p.call(56, 18), Vector2(26, 9) * u), Color("f3d2a8"))
		ci.draw_rect(Rect2(p.call(64, 12), Vector2(9, 21) * u), Color("f3d2a8"))


static func _person(ci: CanvasItem, p: Callable, u: float, head: Vector2, k: float, colour: Color) -> void:
	ci.draw_circle(p.call(head.x, head.y + 8 * k), 9 * k * u, SKIN)
	ci.draw_rect(Rect2(p.call(head.x - 10 * k, head.y + 18 * k), Vector2(20, 34) * k * u), colour)
	ci.draw_line(p.call(head.x - 5 * k, head.y + 52 * k), p.call(head.x - 7 * k, head.y + 78 * k), Color("3a5aa8"),
		7 * k * u)
	ci.draw_line(p.call(head.x + 5 * k, head.y + 52 * k), p.call(head.x + 7 * k, head.y + 78 * k), Color("3a5aa8"),
		7 * k * u)


static func _house(ci: CanvasItem, p: Callable, u: float) -> void:
	ci.draw_rect(Rect2(p.call(20, 44), Vector2(60, 46) * u), Color("f3e1c0"))
	ci.draw_colored_polygon(PackedVector2Array([p.call(10, 48), p.call(50, 12), p.call(90, 48)]), Color("c0563a"))
	ci.draw_rect(Rect2(p.call(42, 62), Vector2(16, 28) * u), WOOD)
	ci.draw_rect(Rect2(p.call(26, 54), Vector2(12, 12) * u), SKY)


static func _vehicle(ci: CanvasItem, p: Callable, u: float, kind: String) -> void:
	var body: Color = {"ambulance": WHITE, "fire_engine": Color("d9463b"), "police": Color("3a5aa8")}[kind]
	ci.draw_rect(Rect2(p.call(8, 36), Vector2(84, 40) * u), body)
	ci.draw_rect(Rect2(p.call(8, 36), Vector2(84, 40) * u), body.darkened(0.3), false, 3 * u)
	ci.draw_rect(Rect2(p.call(66, 42), Vector2(20, 14) * u), SKY)
	ci.draw_rect(Rect2(p.call(30, 28), Vector2(14, 8) * u), Color("3a7be8") if kind != "fire_engine" else SKY)
	for x: float in [26, 74]:
		ci.draw_circle(p.call(x, 78), 9 * u, INK)
	match kind:
		"ambulance":
			ci.draw_rect(Rect2(p.call(32, 48), Vector2(18, 6) * u), Color("d9463b"))
			ci.draw_rect(Rect2(p.call(38, 42), Vector2(6, 18) * u), Color("d9463b"))
		"fire_engine":
			ci.draw_line(p.call(14, 30), p.call(60, 30), WHITE, 4 * u)
			for x in range(18, 60, 8):
				ci.draw_line(p.call(x, 26), p.call(x, 34), WHITE, 2 * u)
		"police":
			ci.draw_rect(Rect2(p.call(14, 52), Vector2(46, 8) * u), WHITE)


static func _floor(ci: CanvasItem, p: Callable, u: float) -> void:
	ci.draw_rect(Rect2(p.call(4, 80), Vector2(92, 8) * u), Color("c9b48a"))


static func _drop(ci: CanvasItem, at: Vector2, r: float, colour: Color) -> void:
	ci.draw_circle(at, r, colour)
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-r * 0.92, -r * 0.35), at + Vector2(0, -r * 2.0),
		at + Vector2(r * 0.92, -r * 0.35)]), colour)


static func _flame(ci: CanvasItem, at: Vector2, r: float) -> void:
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-r, r * 0.6), at + Vector2(-r * 0.6, -r * 0.5),
		at + Vector2(0, -r * 1.6), at + Vector2(r * 0.6, -r * 0.5), at + Vector2(r, r * 0.6)]), FLAME)
	ci.draw_circle(at + Vector2(0, r * 0.3), r * 0.62, FLAME)
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-r * 0.45, r * 0.5), at + Vector2(0, -r * 0.7),
		at + Vector2(r * 0.45, r * 0.5)]), FLAME_IN)


static func _heart(ci: CanvasItem, at: Vector2, r: float, colour: Color) -> void:
	ci.draw_circle(at + Vector2(-r * 0.5, -r * 0.2), r * 0.52, colour)
	ci.draw_circle(at + Vector2(r * 0.5, -r * 0.2), r * 0.52, colour)
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-r * 0.98, 0), at + Vector2(0, r * 0.95),
		at + Vector2(r * 0.98, 0), at + Vector2(0, -r * 0.4)]), colour)
