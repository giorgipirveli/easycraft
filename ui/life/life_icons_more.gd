class_name LifeIconsMore
extends RefCounted
## Owner #112, #113 (Life L2: Safe Streets, The Kitchen, Calm Corner): the second wave of Life's pictures, drawn in code
## like LifeIcons (which asks here for any name it does not draw itself). The same calm style: simple shapes, soft
## colours, a "no" in soft grey-blue, never red; faces are friendly blocky buddies, never scary.

const NAMES: Array[String] = [
	# Safe Streets
	"car", "car_stopped", "kerb", "ear", "booster", "front_seat", "belt_good", "belt_neck", "belt_arm", "van", "red_man",
	"green_man", "light_clothes", "dark_clothes", "helmet", "helmet_back", "traffic_red", "traffic_amber", "traffic_green", "speed",
	"phone_off", "crossing", "bike", "ball", "look_left", "look_right",
	# The Kitchen
	"veg", "water_glass", "fizzy", "knife_bridge", "knife_claw", "knife_wrong", "scales", "cup", "pan", "pan_out",
	"hob_hot", "two_boards", "board", "fridge", "kettle", "kettle_max", "gloves", "big_bag", "small_bags", "hands_wash",
	# Calm Corner
	"face_happy", "face_sad", "face_cross", "face_worried", "face_calm", "balloon", "join", "talk", "share", "worry_school",
	"worry_friend", "worry_dark", "worry_cloud"]

const INK := LifeIcons.INK
const SKIN := LifeIcons.SKIN
const TEAL := LifeIcons.TEAL
const SOFT_NO := LifeIcons.SOFT_NO
const GOOD := LifeIcons.GOOD
const WARM := LifeIcons.WARM
const GOLD := LifeIcons.GOLD
const WOOD := LifeIcons.WOOD
const SKY := LifeIcons.SKY
const WHITE := LifeIcons.WHITE
const ROAD := Color("4a5160")
const CAR := Color("3a7be8")
const RED_SOFT := Color("e8544e")
const AMBER := Color("ffb02e")
const GREEN := Color("3fbf5a")


static func has(name: String) -> bool:
	return NAMES.has(name)


## Draws `name` with `p` (0..100 coordinates to the canvas) and `u` (one unit); false for a name not drawn here.
static func paint(ci: CanvasItem, name: String, p: Callable, u: float) -> bool:
	match name:
		"car", "car_stopped":
			_car(ci, p, u, Vector2(50, 60), 1.0, CAR)
			if name == "car_stopped":
				ci.draw_circle(p.call(80, 22), 14 * u, RED_SOFT.lightened(0.15))
				ci.draw_rect(Rect2(p.call(72, 19), Vector2(16, 6) * u), WHITE)
		"kerb":
			ci.draw_rect(Rect2(p.call(4, 60), Vector2(92, 30) * u), ROAD)
			ci.draw_rect(Rect2(p.call(4, 40), Vector2(92, 20) * u), Color("c9ced6"))
			ci.draw_rect(Rect2(p.call(4, 56), Vector2(92, 6) * u), WHITE)
			_child(ci, p, u, Vector2(50, 8), 0.5, TEAL)
		"ear":
			ci.draw_circle(p.call(42, 50), 26 * u, SKIN)
			ci.draw_arc(p.call(42, 48), 14 * u, -PI * 0.9, PI * 0.5, 14, SKIN.darkened(0.25), 5 * u)
			for i in 3:
				ci.draw_arc(p.call(62, 50), (12 + i * 10) * u, -0.7, 0.7, 10, SKY, 4 * u)
		"booster", "front_seat":
			_car_inside(ci, p, u, name == "booster")
		"belt_good", "belt_neck", "belt_arm":
			_belted(ci, p, u, name)
		"van":
			ci.draw_rect(Rect2(p.call(8, 26), Vector2(70, 50) * u), WHITE)
			ci.draw_rect(Rect2(p.call(8, 26), Vector2(70, 50) * u), Color("9aa7b5"), false, 3 * u)
			ci.draw_rect(Rect2(p.call(58, 34), Vector2(16, 16) * u), SKY)
			for x: float in [24, 64]:
				ci.draw_circle(p.call(x, 78), 8 * u, INK)
			_child(ci, p, u, Vector2(86, 30), 0.5, TEAL)
		"red_man", "green_man":
			ci.draw_rect(Rect2(p.call(24, 8), Vector2(52, 84) * u), INK)
			var on := RED_SOFT if name == "red_man" else GREEN
			ci.draw_circle(p.call(50, 26), 8 * u, on)
			ci.draw_rect(Rect2(p.call(43, 36), Vector2(14, 26) * u), on)
			if name == "red_man":
				ci.draw_line(p.call(46, 62), p.call(46, 82), on, 6 * u)
				ci.draw_line(p.call(54, 62), p.call(54, 82), on, 6 * u)
			else:
				ci.draw_line(p.call(46, 62), p.call(36, 82), on, 6 * u)
				ci.draw_line(p.call(54, 62), p.call(64, 82), on, 6 * u)
		"light_clothes", "dark_clothes":
			var c := Color("fff3b0") if name == "light_clothes" else Color("2b2f3a")
			ci.draw_rect(Rect2(p.call(4, 4), Vector2(92, 92) * u), Color("1f2a4a"))
			_child(ci, p, u, Vector2(50, 12), 0.9, c)
			if name == "light_clothes":
				ci.draw_rect(Rect2(p.call(41, 46), Vector2(18, 5) * u), Color("c8ff6a"))
				for i in 3:
					ci.draw_line(p.call(64 + i * 6, 44 - i * 4), p.call(72 + i * 6, 40 - i * 4), Color("c8ff6a"), 3 * u)
		"helmet", "helmet_back":
			ci.draw_circle(p.call(50, 58), 22 * u, SKIN)
			for x: float in [42, 58]:
				ci.draw_circle(p.call(x, 60), 3.5 * u, INK)
			var tilt := 0.0 if name == "helmet" else -0.5
			var hc: Vector2 = p.call(50, 46) + Vector2(0, -12 if name == "helmet_back" else 0) * u
			ci.draw_set_transform(hc, tilt, Vector2.ONE)
			ci.draw_arc(Vector2.ZERO, 26 * u, PI, TAU, 16, Color("3a7be8"), 12 * u)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if name == "helmet":
				ci.draw_line(p.call(32, 50), p.call(44, 76), Color("2b2f3a"), 3 * u)
				ci.draw_line(p.call(68, 50), p.call(56, 76), Color("2b2f3a"), 3 * u)
		"traffic_red", "traffic_amber", "traffic_green":
			ci.draw_rect(Rect2(p.call(32, 6), Vector2(36, 88) * u), INK)
			var lit := {"traffic_red": 0, "traffic_amber": 1}.get(name, 2) as int
			var colours: Array[Color] = [RED_SOFT, AMBER, GREEN]
			for i in 3:
				ci.draw_circle(p.call(50, 22 + i * 28), 10 * u, colours[i] if i == lit else colours[i].darkened(0.7))
		"speed":
			ci.draw_arc(p.call(50, 62), 36 * u, PI, TAU, 20, WHITE, 6 * u)
			ci.draw_arc(p.call(50, 62), 36 * u, PI * 1.6, TAU, 10, RED_SOFT.lightened(0.2), 6 * u)
			ci.draw_line(p.call(50, 62), p.call(78, 40), INK, 5 * u)
			ci.draw_circle(p.call(50, 62), 6 * u, INK)
		"phone_off":
			ci.draw_rect(Rect2(p.call(30, 12), Vector2(40, 76) * u), INK)
			ci.draw_rect(Rect2(p.call(34, 18), Vector2(32, 54) * u), Color("2b3550"))
			ci.draw_arc(p.call(50, 45), 12 * u, -PI * 0.3, PI * 1.3, 14, SOFT_NO.lightened(0.4), 4 * u)
			ci.draw_line(p.call(50, 30), p.call(50, 44), SOFT_NO.lightened(0.4), 4 * u)
		"crossing":
			ci.draw_rect(Rect2(p.call(4, 30), Vector2(92, 48) * u), ROAD)
			for i in 6:
				ci.draw_rect(Rect2(p.call(10 + i * 14.5, 34), Vector2(8, 40) * u), WHITE)
			_child(ci, p, u, Vector2(16, 2), 0.42, TEAL)
		"bike":
			for x: float in [26, 74]:
				ci.draw_arc(p.call(x, 66), 18 * u, 0, TAU, 18, INK, 5 * u)
			ci.draw_polyline(PackedVector2Array([p.call(26, 66), p.call(44, 40), p.call(66, 40), p.call(74, 66)]), RED_SOFT, 5 * u)
			ci.draw_line(p.call(44, 40), p.call(50, 66), RED_SOFT, 5 * u)
			ci.draw_line(p.call(66, 40), p.call(62, 28), INK, 4 * u)
		"ball":
			ci.draw_circle(p.call(50, 52), 34 * u, Color("ffb02e"))
			ci.draw_arc(p.call(50, 52), 34 * u, -0.5, 0.5, 10, WHITE, 6 * u)
			ci.draw_arc(p.call(50, 52), 34 * u, PI - 0.5, PI + 0.5, 10, WHITE, 6 * u)
			ci.draw_line(p.call(50, 18), p.call(50, 86), WHITE, 5 * u)
		"look_left", "look_right":
			var d := -1.0 if name == "look_left" else 1.0
			for x: float in [36, 64]:
				ci.draw_circle(p.call(x, 40), 13 * u, WHITE)
				ci.draw_circle(p.call(x + d * 6, 40), 6 * u, INK)
			var tip: Vector2 = p.call(50 + d * 38, 76)
			ci.draw_line(p.call(50 - d * 26, 76), tip, GOLD, 8 * u)
			ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(d * 6, 0) * u, tip + Vector2(-d * 12, -12) * u,
				tip + Vector2(-d * 12, 12) * u]), GOLD)
		"veg":
			ci.draw_colored_polygon(PackedVector2Array([p.call(20, 30), p.call(40, 30), p.call(30, 88)]), WARM)
			ci.draw_line(p.call(30, 30), p.call(26, 14), GOOD, 4 * u)
			ci.draw_line(p.call(30, 30), p.call(36, 14), GOOD, 4 * u)
			ci.draw_rect(Rect2(p.call(62, 56), Vector2(8, 30) * u), GOOD.lightened(0.2))
			for c: Vector2 in [Vector2(56, 46), Vector2(70, 40), Vector2(80, 52), Vector2(64, 56)]:
				ci.draw_circle(p.call(c.x, c.y), 11 * u, GOOD.darkened(0.1))
		"water_glass", "fizzy":
			ci.draw_colored_polygon(PackedVector2Array([p.call(30, 16), p.call(70, 16), p.call(64, 90), p.call(36, 90)]),
				Color(1, 1, 1, 0.35))
			var drink := Color(0.55, 0.8, 1.0, 0.85) if name == "water_glass" else Color("b5562a")
			ci.draw_colored_polygon(PackedVector2Array([p.call(32, 36), p.call(68, 36), p.call(64, 90), p.call(36, 90)]), drink)
			if name == "fizzy":
				for c: Vector2 in [Vector2(44, 50), Vector2(54, 62), Vector2(48, 76), Vector2(58, 46)]:
					ci.draw_circle(p.call(c.x, c.y), 3 * u, Color(1, 1, 1, 0.8))
		"knife_bridge", "knife_claw", "knife_wrong":
			_knife(ci, p, u, name)
		"scales":
			ci.draw_rect(Rect2(p.call(14, 60), Vector2(72, 28) * u), WHITE)
			ci.draw_rect(Rect2(p.call(14, 60), Vector2(72, 28) * u), Color("9aa7b5"), false, 3 * u)
			ci.draw_rect(Rect2(p.call(34, 68), Vector2(32, 12) * u), Color("2b3550"))
			ci.draw_string(ThemeDB.fallback_font, p.call(37, 79), "200", HORIZONTAL_ALIGNMENT_LEFT, -1, int(11 * u),
				Color("9fffa8"))
			ci.draw_colored_polygon(PackedVector2Array([p.call(22, 42), p.call(78, 42), p.call(70, 58), p.call(30, 58)]),
				Color("c9ced6"))
		"cup":
			ci.draw_colored_polygon(PackedVector2Array([p.call(26, 20), p.call(70, 20), p.call(66, 88), p.call(30, 88)]),
				Color(1, 1, 1, 0.5))
			ci.draw_colored_polygon(PackedVector2Array([p.call(28, 54), p.call(68, 54), p.call(66, 88), p.call(30, 88)]), WHITE)
			for i in 3:
				ci.draw_line(p.call(26, 36 + i * 17), p.call(38, 36 + i * 17), INK, 3 * u)
			ci.draw_arc(p.call(74, 52), 12 * u, -PI / 2, PI / 2, 10, Color(1, 1, 1, 0.6), 5 * u)
		"pan", "pan_out":
			ci.draw_rect(Rect2(p.call(8, 62), Vector2(84, 26) * u), Color("3b3f4a"))
			ci.draw_circle(p.call(44, 54), 22 * u, Color("6b7380"))
			var out := name == "pan_out"
			ci.draw_line(p.call(62, 50), p.call(96 if out else 78, 50 if out else 36), INK, 7 * u)
			if out:
				ci.draw_line(p.call(88, 62), p.call(88, 92), SOFT_NO, 3 * u)
		"hob_hot":
			ci.draw_rect(Rect2(p.call(8, 30), Vector2(84, 50) * u), Color("2b2f3a"))
			for x: float in [32, 68]:
				ci.draw_arc(p.call(x, 54), 14 * u, 0, TAU, 16, WARM.lightened(0.2), 4 * u)
			ci.draw_circle(p.call(84, 38), 5 * u, WARM)
			for i in 3:
				ci.draw_arc(p.call(32 + i * 18, 22), 6 * u, PI, TAU, 6, Color(1, 0.8, 0.6, 0.7), 3 * u)
		"two_boards", "board":
			ci.draw_rect(Rect2(p.call(10, 40), Vector2(48, 40) * u), WOOD.lightened(0.25))
			ci.draw_circle(p.call(34, 60), 9 * u, GOOD)
			if name == "two_boards":
				ci.draw_rect(Rect2(p.call(50, 22), Vector2(42, 38) * u), RED_SOFT.lightened(0.35))
				ci.draw_circle(p.call(71, 41), 10 * u, Color("f6b5a8"))
			else:
				ci.draw_circle(p.call(46, 54), 9 * u, Color("f6b5a8"))
		"fridge":
			ci.draw_rect(Rect2(p.call(26, 6), Vector2(48, 88) * u), WHITE)
			ci.draw_rect(Rect2(p.call(26, 6), Vector2(48, 88) * u), Color("9aa7b5"), false, 3 * u)
			ci.draw_line(p.call(26, 38), p.call(74, 38), Color("9aa7b5"), 3 * u)
			ci.draw_line(p.call(66, 16), p.call(66, 30), INK, 4 * u)
			ci.draw_string(ThemeDB.fallback_font, p.call(34, 72), "5°", HORIZONTAL_ALIGNMENT_LEFT, -1, int(22 * u), SKY)
		"kettle", "kettle_max":
			ci.draw_rect(Rect2(p.call(24, 26), Vector2(46, 60) * u), Color("c9ced6"))
			ci.draw_arc(p.call(74, 56), 14 * u, -PI / 2, PI / 2, 10, Color("9aa7b5"), 6 * u)
			ci.draw_colored_polygon(PackedVector2Array([p.call(24, 34), p.call(10, 26), p.call(24, 46)]), Color("c9ced6"))
			ci.draw_rect(Rect2(p.call(44, 32), Vector2(8, 48) * u), Color("9fd8ff"))
			var level := 34.0 if name == "kettle_max" else 54.0
			ci.draw_rect(Rect2(p.call(44, level), Vector2(8, 80 - level) * u), SKY)
			ci.draw_line(p.call(40, 40), p.call(56, 40), INK, 2 * u)
			ci.draw_line(p.call(40, 72), p.call(56, 72), INK, 2 * u)
			if name == "kettle_max":
				for i in 3:
					LifeIconsMore._dot(ci, p.call(14 + i * 8, 18 - i * 4), 3 * u, SKY)
		"gloves":
			for x: float in [28, 66]:
				ci.draw_rect(Rect2(p.call(x - 14, 36), Vector2(28, 50) * u), Color("e8544e").lightened(0.2))
				ci.draw_circle(p.call(x, 34), 14 * u, Color("e8544e").lightened(0.2))
				ci.draw_circle(p.call(x - 16, 52), 7 * u, Color("e8544e").lightened(0.2))
				ci.draw_rect(Rect2(p.call(x - 14, 80), Vector2(28, 8) * u), WHITE)
		"big_bag", "small_bags":
			if name == "big_bag":
				ci.draw_rect(Rect2(p.call(26, 22), Vector2(48, 68) * u), Color("f3e6c8"))
				ci.draw_string(ThemeDB.fallback_font, p.call(34, 64), "2 kg", HORIZONTAL_ALIGNMENT_LEFT, -1, int(14 * u), INK)
			else:
				for x: float in [16, 54]:
					ci.draw_rect(Rect2(p.call(x, 40), Vector2(30, 48) * u), Color("f3e6c8"))
					ci.draw_string(ThemeDB.fallback_font, p.call(x + 3, 70), "1 kg", HORIZONTAL_ALIGNMENT_LEFT, -1, int(11 * u),
						INK)
		"hands_wash":
			for x: float in [36, 62]:
				ci.draw_rect(Rect2(p.call(x - 12, 40), Vector2(24, 36) * u), SKIN)
			for c: Vector2 in [Vector2(30, 34), Vector2(50, 28), Vector2(70, 36), Vector2(44, 84), Vector2(60, 86)]:
				ci.draw_circle(p.call(c.x, c.y), 6 * u, Color(1, 1, 1, 0.85))
				ci.draw_arc(p.call(c.x, c.y), 6 * u, 0, TAU, 10, SKY, 2 * u)
		"face_happy", "face_sad", "face_cross", "face_worried", "face_calm":
			_feeling(ci, p, u, name.substr(5))
		"balloon":
			ci.draw_circle(p.call(50, 40), 30 * u, Color("8b6fd6"))
			ci.draw_circle(p.call(40, 30), 7 * u, Color(1, 1, 1, 0.5))
			ci.draw_colored_polygon(PackedVector2Array([p.call(46, 70), p.call(54, 70), p.call(50, 76)]), Color("8b6fd6"))
			ci.draw_polyline(PackedVector2Array([p.call(50, 76), p.call(46, 84), p.call(54, 92)]), INK, 2 * u)
		"join":
			_child(ci, p, u, Vector2(26, 14), 0.75, TEAL)
			_child(ci, p, u, Vector2(50, 14), 0.75, Color("8b6fd6"))
			_child(ci, p, u, Vector2(74, 14), 0.75, WARM)
			ci.draw_line(p.call(34, 46), p.call(42, 46), SKIN, 4 * u)
			ci.draw_line(p.call(58, 46), p.call(66, 46), SKIN, 4 * u)
		"talk":
			ci.draw_rect(Rect2(p.call(10, 14), Vector2(70, 46) * u), WHITE)
			ci.draw_colored_polygon(PackedVector2Array([p.call(22, 60), p.call(36, 60), p.call(20, 76)]), WHITE)
			for i in 3:
				ci.draw_line(p.call(20, 26 + i * 11), p.call(68 - i * 10, 26 + i * 11), INK, 3 * u)
			_heart(ci, p.call(80, 72), 12 * u, RED_SOFT.lightened(0.2))
		"share":
			ci.draw_rect(Rect2(p.call(14, 30), Vector2(48, 56) * u), Color("2b3550"))
			ci.draw_rect(Rect2(p.call(18, 36), Vector2(40, 40) * u), SKY.lightened(0.3))
			ci.draw_line(p.call(58, 40), p.call(86, 18), GOLD, 6 * u)
			ci.draw_colored_polygon(PackedVector2Array([p.call(90, 14), p.call(76, 18), p.call(86, 28)]), GOLD)
		"worry_school":
			ci.draw_rect(Rect2(p.call(22, 14), Vector2(56, 74) * u), WHITE)
			for i in 4:
				ci.draw_line(p.call(30, 28 + i * 12), p.call(70, 28 + i * 12), Color("b9d4e8"), 3 * u)
			ci.draw_string(ThemeDB.fallback_font, p.call(56, 86), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(28 * u),
				Color("8b6fd6"))
		"worry_friend":
			_child(ci, p, u, Vector2(32, 14), 0.8, TEAL)
			_child(ci, p, u, Vector2(70, 14), 0.8, Color("8b6fd6"))
			ci.draw_string(ThemeDB.fallback_font, p.call(46, 30), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(24 * u), INK)
		"worry_dark":
			ci.draw_rect(Rect2(p.call(4, 4), Vector2(92, 92) * u), Color("1f2a4a"))
			ci.draw_circle(p.call(56, 40), 22 * u, Color("ffe9a8"))
			ci.draw_circle(p.call(66, 34), 20 * u, Color("1f2a4a"))
			for c: Vector2 in [Vector2(20, 22), Vector2(30, 70), Vector2(78, 76)]:
				ci.draw_circle(p.call(c.x, c.y), 3 * u, WHITE)
		"worry_cloud":
			for c: Vector3 in [Vector3(34, 54, 18), Vector3(52, 44, 22), Vector3(70, 56, 16), Vector3(52, 62, 18)]:
				ci.draw_circle(p.call(c.x, c.y), c.z * u, Color("b9c3d6"))
		_:
			return false
	return true


static func _dot(ci: CanvasItem, at: Vector2, r: float, colour: Color) -> void:
	ci.draw_circle(at, r, colour)


static func _heart(ci: CanvasItem, at: Vector2, r: float, colour: Color) -> void:
	ci.draw_circle(at + Vector2(-r * 0.5, -r * 0.2), r * 0.52, colour)
	ci.draw_circle(at + Vector2(r * 0.5, -r * 0.2), r * 0.52, colour)
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-r * 0.98, 0), at + Vector2(0, r * 0.95),
		at + Vector2(r * 0.98, 0), at + Vector2(0, -r * 0.4)]), colour)


## A small blocky child: head at `head`, `k` its size (1 = about 70 tall).
static func _child(ci: CanvasItem, p: Callable, u: float, head: Vector2, k: float, colour: Color) -> void:
	ci.draw_circle(p.call(head.x, head.y + 10 * k), 10 * k * u, SKIN)
	ci.draw_rect(Rect2(p.call(head.x - 11 * k, head.y + 22 * k), Vector2(22, 32) * k * u), colour)
	ci.draw_line(p.call(head.x - 5 * k, head.y + 54 * k), p.call(head.x - 6 * k, head.y + 78 * k), Color("3a5aa8"), 7 * k * u)
	ci.draw_line(p.call(head.x + 5 * k, head.y + 54 * k), p.call(head.x + 6 * k, head.y + 78 * k), Color("3a5aa8"), 7 * k * u)


static func _car(ci: CanvasItem, p: Callable, u: float, at: Vector2, k: float, colour: Color) -> void:
	ci.draw_rect(Rect2(p.call(at.x - 40 * k, at.y - 14 * k), Vector2(80, 24) * k * u), colour)
	ci.draw_rect(Rect2(p.call(at.x - 24 * k, at.y - 32 * k), Vector2(44, 20) * k * u), colour.lightened(0.1))
	ci.draw_rect(Rect2(p.call(at.x - 20 * k, at.y - 28 * k), Vector2(16, 13) * k * u), SKY)
	ci.draw_rect(Rect2(p.call(at.x + 0 * k, at.y - 28 * k), Vector2(16, 13) * k * u), SKY)
	for x: float in [-24, 24]:
		ci.draw_circle(p.call(at.x + x * k, at.y + 12 * k), 9 * k * u, INK)
	ci.draw_rect(Rect2(p.call(at.x + 34 * k, at.y - 10 * k), Vector2(6, 6) * k * u), Color("fff3b0"))


static func _car_inside(ci: CanvasItem, p: Callable, u: float, booster: bool) -> void:
	ci.draw_rect(Rect2(p.call(6, 24), Vector2(88, 60) * u), Color("c9ced6"))
	ci.draw_rect(Rect2(p.call(6, 24), Vector2(88, 60) * u), Color("9aa7b5"), false, 3 * u)
	ci.draw_rect(Rect2(p.call(14, 30), Vector2(30, 22) * u), SKY)   # the front
	ci.draw_rect(Rect2(p.call(56, 30), Vector2(30, 22) * u), SKY)   # the back
	ci.draw_circle(p.call(22, 62), 8 * u, INK)   # the wheel: the front seat
	if booster:
		ci.draw_rect(Rect2(p.call(58, 60), Vector2(26, 14) * u), Color("3a7be8"))
		_child(ci, p, u, Vector2(71, 30), 0.42, TEAL)
	else:
		_child(ci, p, u, Vector2(34, 30), 0.42, TEAL)


static func _belted(ci: CanvasItem, p: Callable, u: float, kind: String) -> void:
	ci.draw_circle(p.call(50, 18), 12 * u, SKIN)
	ci.draw_rect(Rect2(p.call(32, 32), Vector2(36, 40) * u), TEAL)
	ci.draw_rect(Rect2(p.call(30, 72), Vector2(40, 18) * u), Color("3a5aa8"))
	var belt := Color("2b2f3a")
	match kind:
		"belt_good":
			ci.draw_line(p.call(62, 32), p.call(36, 70), belt, 6 * u)
			ci.draw_line(p.call(28, 74), p.call(72, 74), belt, 6 * u)
		"belt_neck":
			ci.draw_line(p.call(54, 27), p.call(36, 70), belt, 6 * u)
			ci.draw_line(p.call(28, 74), p.call(72, 74), belt, 6 * u)
		"belt_arm":
			ci.draw_line(p.call(72, 50), p.call(36, 70), belt, 6 * u)
			ci.draw_line(p.call(28, 74), p.call(72, 74), belt, 6 * u)
	if kind != "belt_good":
		ci.draw_circle(p.call(82, 20), 11 * u, SOFT_NO)


static func _knife(ci: CanvasItem, p: Callable, u: float, kind: String) -> void:
	ci.draw_rect(Rect2(p.call(4, 70), Vector2(92, 16) * u), WOOD.lightened(0.25))
	ci.draw_rect(Rect2(p.call(20, 56), Vector2(60, 16) * u), GOOD.lightened(0.3))   # the food
	var blade := Color("c9ced6")
	match kind:
		"knife_bridge":
			ci.draw_arc(p.call(50, 56), 20 * u, PI, TAU, 12, SKIN, 8 * u)
			ci.draw_line(p.call(50, 64), p.call(50, 30), blade, 6 * u)
			ci.draw_rect(Rect2(p.call(46, 14), Vector2(8, 18) * u), INK)
		"knife_claw":
			for i in 3:
				ci.draw_arc(p.call(26 + i * 9, 50), 6 * u, PI * 0.5, PI * 1.5, 6, SKIN, 6 * u)
			ci.draw_line(p.call(58, 70), p.call(58, 36), blade, 6 * u)
			ci.draw_rect(Rect2(p.call(54, 20), Vector2(8, 18) * u), INK)
		"knife_wrong":
			ci.draw_rect(Rect2(p.call(40, 50), Vector2(34, 8) * u), SKIN)
			ci.draw_line(p.call(56, 70), p.call(56, 36), blade, 6 * u)
			ci.draw_rect(Rect2(p.call(52, 20), Vector2(8, 18) * u), INK)
			ci.draw_circle(p.call(84, 22), 11 * u, SOFT_NO)


## A friendly blocky buddy's face showing a feeling (never scary: a cross face is frowning brows and a flat mouth).
static func _feeling(ci: CanvasItem, p: Callable, u: float, feeling: String) -> void:
	var colour: Color = {"happy": Color("ffc93c"), "sad": Color("7aa6e8"), "cross": Color("f0906a"),
		"worried": Color("b9a6e8"), "calm": Color("7fd1b0")}.get(feeling, TEAL)
	ci.draw_rect(Rect2(p.call(14, 14), Vector2(72, 72) * u), colour)
	ci.draw_rect(Rect2(p.call(14, 14), Vector2(72, 72) * u), colour.darkened(0.25), false, 3 * u)
	match feeling:
		"calm":
			for x: float in [36, 64]:
				ci.draw_arc(p.call(x, 44), 7 * u, 0.2, PI - 0.2, 8, INK, 4 * u)
			ci.draw_arc(p.call(50, 60), 10 * u, 0.5, PI - 0.5, 8, INK, 4 * u)
		"sad":
			for x: float in [36, 64]:
				ci.draw_circle(p.call(x, 46), 5 * u, INK)
			ci.draw_line(p.call(28, 34), p.call(42, 30), INK, 3 * u)
			ci.draw_line(p.call(72, 34), p.call(58, 30), INK, 3 * u)
			ci.draw_arc(p.call(50, 74), 12 * u, PI + 0.5, TAU - 0.5, 10, INK, 4 * u)
		"cross":
			for x: float in [36, 64]:
				ci.draw_circle(p.call(x, 46), 5 * u, INK)
			ci.draw_line(p.call(28, 30), p.call(44, 38), INK, 4 * u)
			ci.draw_line(p.call(72, 30), p.call(56, 38), INK, 4 * u)
			ci.draw_line(p.call(38, 66), p.call(62, 66), INK, 4 * u)
		"worried":
			for x: float in [36, 64]:
				ci.draw_circle(p.call(x, 46), 6 * u, INK)
				ci.draw_circle(p.call(x + 2, 44), 2 * u, WHITE)
			ci.draw_line(p.call(28, 34), p.call(42, 28), INK, 3 * u)
			ci.draw_line(p.call(72, 34), p.call(58, 28), INK, 3 * u)
			ci.draw_arc(p.call(50, 68), 6 * u, 0, TAU, 10, INK, 3 * u)
		_:
			for x: float in [36, 64]:
				ci.draw_circle(p.call(x, 44), 6 * u, INK)
				ci.draw_circle(p.call(x + 2, 42), 2 * u, WHITE)
			ci.draw_arc(p.call(50, 58), 16 * u, 0.3, PI - 0.3, 12, INK, 4 * u)
