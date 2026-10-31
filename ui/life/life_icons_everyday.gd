class_name LifeIconsEveryday
extends RefCounted
## Owner #112, #118 (Life L3c: Online City, Find Your Way, Home Helper): the fifth wave of Life's pictures, drawn in code
## like LifeIcons (which asks here after LifeIconsHazards). The same calm style: simple shapes, soft colours, a "no" in
## soft grey-blue, never red. Online, a stranger is only a grey "?" on a screen, never a face; a scam is a little fishing
## hook; nothing real: no brands, no real sites. Find Your Way's people are blocky figures, nobody is ever shown grabbing or
## following. Home Helper's chores are plain things: baskets, socks, bins, a plant, a dog, a smoke alarm.

const NAMES: Array[String] = [
	# Online City
	"tablet", "tap_new", "sad_screen", "private", "photo_send", "block", "report", "meet_up", "lock_strong", "lock_weak",
	"scam_hook", "download", "close_x", "news", "photo_changed", "think_post", "link", "friend_request", "break_time",
	"bedtime_screen",
	# Find Your Way
	"stay_here", "walk_off", "name_badge", "parent_kids", "teacher_line", "landmark", "cloud", "leave_things", "metro_map",
	"metro_ticket", "yellow_line", "platform_edge", "train", "compass_rose", "help_point", "grid_map",
	# Home Helper
	"whites", "colours", "red_sock", "socks_pair", "tshirt_fold", "soil_dry", "soil_wet", "dog_lead", "vet", "bin_paper",
	"bin_plastic", "bin_glass", "bin_food", "battery_box", "smoke_test", "label_30", "label_40", "label_hand",
	"label_no_tumble", "washing_label", "knife_down", "knife_up", "table_set"]

const INK := LifeIcons.INK
const SKIN := LifeIcons.SKIN
const TEAL := LifeIcons.TEAL
const SOFT_NO := LifeIcons.SOFT_NO
const GOOD := LifeIcons.GOOD
const GOLD := LifeIcons.GOLD
const WOOD := LifeIcons.WOOD
const SKY := LifeIcons.SKY
const WHITE := LifeIcons.WHITE
const SCREEN := Color("9fd8ff")
const FRAME := Color("1f2a4a")
const SOIL := Color("8a5a34")
const GRASS := Color("7cc46a")
const PAPER := Color("3a7be8")     # the game's practice bins: paper blue, plastic and cans yellow, glass green, food brown
const PLASTIC := Color("f2c230")
const GLASS := Color("2fae4e")
const FOOD := Color("8a5a34")
const LINE_GREEN := Color("2fae4e")
const LINE_RED := Color("e8544e")
const PLATFORM := Color("c9ced6")
const WARM := Color("ffd23f")


static func has(name: String) -> bool:
	return NAMES.has(name)


## Draws `name` with `p` (0..100 coordinates to the canvas) and `u` (one unit); false for a name not drawn here.
static func paint(ci: CanvasItem, name: String, p: Callable, u: float) -> bool:
	if not NAMES.has(name):
		return false
	match name:
		# --- Online City ---
		"tablet":
			_tablet(ci, p, u)
			for i in 4:
				ci.draw_rect(Rect2(p.call(26 + (i % 2) * 26, 30 + (i / 2) * 22), Vector2(20, 16) * u),
					[LINE_GREEN, PAPER, WARM, Color("e85a9a")][i])
		"tap_new":
			_tablet(ci, p, u)
			ci.draw_rect(Rect2(p.call(36, 34), Vector2(28, 22) * u), WARM)
			_text(ci, p, u, Vector2(38, 50), "NEW")
			_finger(ci, p, u, Vector2(60, 62))
		"sad_screen":
			_tablet(ci, p, u, Color("b8c2d6"))
			ci.draw_circle(p.call(50, 48), 16 * u, Color("fdfdf8"))
			for x: float in [44, 56]:
				ci.draw_circle(p.call(x, 44), 2.2 * u, INK)
			ci.draw_arc(p.call(50, 60), 7 * u, PI + 0.4, TAU - 0.4, 8, INK, 2 * u)
			LifeIconsMore._child(ci, p, u, Vector2(86, 52), 0.42, TEAL)
		"private":
			_padlock(ci, p, u, Vector2(50, 54), 1.1, GOOD)
			LifeIcons._person(ci, p, u, Vector2(22, 16), 0.5, TEAL)
		"photo_send":
			_tablet(ci, p, u)
			_photo(ci, p, u, Vector2(66, 26), 0.8)
			LifeIconsDanger._arrow(ci, p, u, Vector2(46, 50), Vector2(86, 16), SOFT_NO)
			_mystery(ci, p, u, Vector2(88, 78))
		"block":
			ci.draw_circle(p.call(50, 50), 36 * u, SOFT_NO)
			ci.draw_circle(p.call(50, 50), 28 * u, WHITE)
			ci.draw_line(p.call(30, 30), p.call(70, 70), SOFT_NO, 8 * u)
			_text(ci, p, u, Vector2(30, 96), "BLOCK")
		"report":
			ci.draw_line(p.call(30, 16), p.call(30, 88), INK, 5 * u)
			ci.draw_colored_polygon(PackedVector2Array([p.call(32, 18), p.call(78, 30), p.call(32, 44)]), Color("3a7be8"))
			_text(ci, p, u, Vector2(36, 70), "REPORT")
		"meet_up":
			ci.draw_rect(Rect2(p.call(0, 80), Vector2(100, 20) * u), GRASS)
			ci.draw_rect(Rect2(p.call(30, 62), Vector2(40, 6) * u), WOOD)
			LifeIconsMore._child(ci, p, u, Vector2(22, 20), 0.6, TEAL)
			_mystery(ci, p, u, Vector2(76, 46))
			_cross(ci, p, u, Vector2(86, 14))
		"lock_strong":
			_padlock(ci, p, u, Vector2(50, 56), 1.2, GOOD)
			for i in 3:
				ci.draw_circle(p.call(34 + i * 16, 18), 4 * u, GOLD)
		"lock_weak":
			_padlock(ci, p, u, Vector2(50, 56), 1.2, SOFT_NO, true)
		"scam_hook":
			ci.draw_line(p.call(50, 0), p.call(50, 44), INK, 2 * u)
			ci.draw_arc(p.call(42, 50), 8 * u, -0.2, PI, 10, Color("9aa3ad"), 4 * u)
			ci.draw_rect(Rect2(p.call(24, 64), Vector2(52, 26) * u), WHITE)
			ci.draw_rect(Rect2(p.call(24, 64), Vector2(52, 26) * u), INK, false, 2 * u)
			for i in 4:
				ci.draw_circle(p.call(34 + i * 10, 77), 3 * u, INK)
		"download":
			ci.draw_rect(Rect2(p.call(22, 66), Vector2(56, 20) * u), SOFT_NO)
			ci.draw_line(p.call(50, 14), p.call(50, 60), INK, 7 * u)
			ci.draw_colored_polygon(PackedVector2Array([p.call(36, 46), p.call(64, 46), p.call(50, 64)]), INK)
		"close_x":
			ci.draw_rect(Rect2(p.call(14, 20), Vector2(72, 60) * u), WHITE)
			ci.draw_rect(Rect2(p.call(14, 20), Vector2(72, 60) * u), INK, false, 2 * u)
			ci.draw_rect(Rect2(p.call(66, 22), Vector2(18, 16) * u), Color("dfe3ea"))
			ci.draw_line(p.call(70, 25), p.call(80, 35), INK, 3 * u)
			ci.draw_line(p.call(80, 25), p.call(70, 35), INK, 3 * u)
			_tick(ci, p, u, Vector2(46, 58))
		"news":
			ci.draw_rect(Rect2(p.call(16, 18), Vector2(68, 66) * u), WHITE)
			ci.draw_rect(Rect2(p.call(16, 18), Vector2(68, 66) * u), INK, false, 2 * u)
			ci.draw_rect(Rect2(p.call(22, 24), Vector2(56, 10) * u), INK)
			for i in 4:
				ci.draw_line(p.call(22, 44 + i * 9), p.call(78 - (i % 2) * 14, 44 + i * 9), SOFT_NO, 3 * u)
			ci.draw_circle(p.call(84, 20), 10 * u, GOLD)
			_text(ci, p, u, Vector2(80, 25), "?")
		"photo_changed":
			_photo(ci, p, u, Vector2(42, 48), 1.4)
			ci.draw_line(p.call(64, 76), p.call(88, 46), WOOD, 5 * u)
			for d: Vector2 in [Vector2(88, 40), Vector2(80, 36), Vector2(92, 50)]:
				ci.draw_circle(p.call(d.x, d.y), 3 * u, WARM)
		"think_post":
			for c: Vector3 in [Vector3(56, 32, 22), Vector3(30, 66, 6), Vector3(22, 80, 4)]:
				ci.draw_circle(p.call(c.x, c.y), c.z * u, WHITE)
				ci.draw_arc(p.call(c.x, c.y), c.z * u, 0, TAU, 16, INK, 2 * u)
			_photo(ci, p, u, Vector2(56, 32), 0.7)
		"link":
			for x: float in [36, 62]:
				ci.draw_arc(p.call(x, 50), 14 * u, 0, TAU, 16, Color("3a7be8"), 6 * u)
			_cross(ci, p, u, Vector2(84, 18))
		"friend_request":
			_tablet(ci, p, u)
			_mystery(ci, p, u, Vector2(44, 48))
			ci.draw_rect(Rect2(p.call(56, 56), Vector2(16, 16) * u), SOFT_NO)
			ci.draw_line(p.call(64, 58), p.call(64, 70), WHITE, 3 * u)
			ci.draw_line(p.call(58, 64), p.call(70, 64), WHITE, 3 * u)
		"break_time":
			LifeIconsMore._child(ci, p, u, Vector2(50, 18), 0.8, TEAL)
			ci.draw_line(p.call(42, 44), p.call(24, 14), SKIN, 6 * u)
			ci.draw_line(p.call(58, 44), p.call(76, 14), SKIN, 6 * u)
			ci.draw_circle(p.call(84, 70), 8 * u, Color(0.6, 0.8, 1.0))
		"bedtime_screen":
			ci.draw_rect(Rect2(p.call(0, 0), Vector2(100, 100) * u), Color("2b3a66"))
			ci.draw_circle(p.call(30, 30), 14 * u, WARM)
			ci.draw_circle(p.call(36, 26), 12 * u, Color("2b3a66"))
			ci.draw_rect(Rect2(p.call(52, 58), Vector2(34, 24) * u), FRAME)
			ci.draw_rect(Rect2(p.call(55, 61), Vector2(28, 18) * u), Color("4a5160"))
			_text(ci, p, u, Vector2(14, 80), "z z")
		# --- Find Your Way ---
		"stay_here":
			ci.draw_circle(p.call(50, 84), 26 * u, Color(0.3, 0.85, 0.4, 0.5))
			LifeIconsMore._child(ci, p, u, Vector2(50, 6), 0.95, TEAL)
		"walk_off":
			ci.draw_rect(Rect2(p.call(0, 88), Vector2(100, 12) * u), Color("d8d2c4"))
			for i in 4:
				ci.draw_circle(p.call(26 + i * 16, 86 - (i % 2) * 4), 3 * u, SOFT_NO)
			LifeIconsMore._child(ci, p, u, Vector2(80, 10), 0.75, Color(0.12, 0.65, 0.63, 0.55))
			_cross(ci, p, u, Vector2(20, 20))
		"name_badge":
			LifeIcons._person(ci, p, u, Vector2(50, 6), 1.05, Color("3fbf5a"))
			ci.draw_rect(Rect2(p.call(54, 40), Vector2(14, 8) * u), WHITE)
		"parent_kids":
			LifeIcons._person(ci, p, u, Vector2(40, 4), 1.05, Color("e85a9a"))
			LifeIconsMore._child(ci, p, u, Vector2(70, 40), 0.55, TEAL)
			LifeIconsMore._child(ci, p, u, Vector2(16, 44), 0.5, GOLD)
		"teacher_line":
			LifeIcons._person(ci, p, u, Vector2(18, 6), 1.0, Color("7b5cd6"))
			for i in 3:
				LifeIconsMore._child(ci, p, u, Vector2(42 + i * 20, 32), 0.6, [TEAL, GOLD, Color("e85a9a")][i])
		"landmark":
			ci.draw_rect(Rect2(p.call(0, 74), Vector2(100, 26) * u), Color("5aa8e6"))
			ci.draw_arc(p.call(50, 76), 34 * u, PI, TAU, 16, Color("e8544e"), 8 * u)
			ci.draw_rect(Rect2(p.call(10, 60), Vector2(80, 6) * u), Color("e8544e"))
		"cloud":
			for c: Vector3 in [Vector3(36, 52, 16), Vector3(56, 44, 20), Vector3(72, 54, 14)]:
				ci.draw_circle(p.call(c.x, c.y), c.z * u, Color("dfe7f5"))
			LifeIconsDanger._arrow(ci, p, u, Vector2(30, 82), Vector2(78, 82), SOFT_NO)
		"leave_things":
			ci.draw_rect(Rect2(p.call(14, 52), Vector2(40, 34) * u), Color("e8544e"))
			ci.draw_rect(Rect2(p.call(24, 44), Vector2(20, 10) * u), Color("c0304a"))
			LifeIconsDanger._arrow(ci, p, u, Vector2(60, 60), Vector2(92, 60), GOOD)
		"metro_map":
			ci.draw_rect(Rect2(p.call(8, 8), Vector2(84, 84) * u), WHITE)
			ci.draw_line(p.call(12, 50), p.call(88, 50), LINE_GREEN, 6 * u)
			ci.draw_line(p.call(50, 12), p.call(50, 88), LINE_RED, 6 * u)
			for at: Vector2 in [Vector2(22, 50), Vector2(78, 50), Vector2(50, 22), Vector2(50, 78)]:
				ci.draw_circle(p.call(at.x, at.y), 4 * u, WHITE)
				ci.draw_arc(p.call(at.x, at.y), 4 * u, 0, TAU, 10, INK, 2 * u)
			ci.draw_circle(p.call(50, 50), 7 * u, WHITE)
			ci.draw_arc(p.call(50, 50), 7 * u, 0, TAU, 12, INK, 3 * u)
		"metro_ticket":
			ci.draw_rect(Rect2(p.call(12, 30), Vector2(76, 44) * u), Color("ffd23f"))
			ci.draw_rect(Rect2(p.call(12, 30), Vector2(76, 44) * u), INK, false, 2 * u)
			ci.draw_rect(Rect2(p.call(18, 40), Vector2(14, 10) * u), Color("c9a646"))
			_text(ci, p, u, Vector2(46, 58), "M")
			ci.draw_arc(p.call(78, 52), 6 * u, -0.8, 0.8, 6, INK, 2 * u)
			ci.draw_arc(p.call(78, 52), 11 * u, -0.8, 0.8, 6, INK, 2 * u)
		"yellow_line", "platform_edge":
			ci.draw_rect(Rect2(p.call(0, 60), Vector2(100, 40) * u), PLATFORM)
			ci.draw_rect(Rect2(p.call(0, 66), Vector2(100, 5) * u), WARM)
			ci.draw_rect(Rect2(p.call(0, 90), Vector2(100, 10) * u), Color("4a5160"))
			if name == "yellow_line":
				LifeIconsMore._child(ci, p, u, Vector2(50, -18), 0.85, TEAL)
				_tick(ci, p, u, Vector2(84, 16))
			else:
				LifeIconsMore._child(ci, p, u, Vector2(50, 4), 0.85, Color(0.12, 0.65, 0.63, 0.6))
				_cross(ci, p, u, Vector2(84, 16))
		"train":
			ci.draw_rect(Rect2(p.call(10, 30), Vector2(80, 44) * u), Color("e8544e"))
			for x: float in [18, 42, 66]:
				ci.draw_rect(Rect2(p.call(x, 38), Vector2(16, 14) * u), SCREEN)
			for x: float in [24, 76]:
				ci.draw_circle(p.call(x, 78), 6 * u, INK)
		"compass_rose":
			ci.draw_circle(p.call(50, 50), 40 * u, WHITE)
			ci.draw_arc(p.call(50, 50), 40 * u, 0, TAU, 24, INK, 3 * u)
			ci.draw_colored_polygon(PackedVector2Array([p.call(44, 50), p.call(50, 14), p.call(56, 50)]), Color("e8544e"))
			ci.draw_colored_polygon(PackedVector2Array([p.call(44, 50), p.call(50, 86), p.call(56, 50)]), SOFT_NO)
			_text(ci, p, u, Vector2(45, 12), "N")
		"help_point":
			ci.draw_rect(Rect2(p.call(30, 10), Vector2(40, 80) * u), Color("3a7be8"))
			ci.draw_circle(p.call(50, 36), 10 * u, WARM)
			for i in 3:
				ci.draw_line(p.call(40, 58 + i * 7), p.call(60, 58 + i * 7), WHITE, 2 * u)
		"grid_map":
			ci.draw_rect(Rect2(p.call(14, 10), Vector2(76, 76) * u), Color("dff0d0"))
			for i in 5:
				ci.draw_line(p.call(14 + i * 19, 10), p.call(14 + i * 19, 86), INK, 1.5 * u)
				ci.draw_line(p.call(14, 10 + i * 19), p.call(90, 10 + i * 19), INK, 1.5 * u)
			ci.draw_rect(Rect2(p.call(52, 48), Vector2(19, 19) * u), Color(1.0, 0.82, 0.25, 0.8))
			_text(ci, p, u, Vector2(58, 98), "C")
		# --- Home Helper ---
		"whites", "colours":
			ci.draw_rect(Rect2(p.call(14, 50), Vector2(72, 40) * u), Color("c9a46a"))
			if name == "whites":
				for i in 3:
					ci.draw_rect(Rect2(p.call(20 + i * 20, 36 + (i % 2) * 6), Vector2(18, 18) * u), WHITE)
			else:
				for i in 3:
					ci.draw_rect(Rect2(p.call(20 + i * 20, 36 + (i % 2) * 6), Vector2(18, 18) * u),
						[Color("e8544e"), Color("3a7be8"), Color("2fae4e")][i])
		"red_sock":
			_sock(ci, p, u, Vector2(40, 20), Color("e8544e"))
			ci.draw_rect(Rect2(p.call(60, 60), Vector2(30, 26) * u), Color("f6c6d6"))
		"socks_pair":
			_sock(ci, p, u, Vector2(26, 18), Color("e8544e"))
			_sock(ci, p, u, Vector2(52, 18), Color("e8544e"))
		"tshirt_fold":
			ci.draw_rect(Rect2(p.call(30, 30), Vector2(40, 46) * u), Color("3a7be8"))
			ci.draw_rect(Rect2(p.call(14, 30), Vector2(16, 18) * u), Color("3a7be8").darkened(0.15))
			LifeIconsDanger._arrow(ci, p, u, Vector2(18, 58), Vector2(40, 46), INK)
		"soil_dry", "soil_wet":
			ci.draw_rect(Rect2(p.call(20, 56), Vector2(60, 36) * u), Color("c0563a"))
			ci.draw_rect(Rect2(p.call(22, 54), Vector2(56, 8) * u), SOIL.lightened(0.25) if name == "soil_dry" else SOIL.darkened(0.3))
			ci.draw_line(p.call(50, 54), p.call(50, 24), Color("3f8a3a"), 4 * u)
			ci.draw_circle(p.call(40, 26), 9 * u, Color("4f9a3e"))
			ci.draw_circle(p.call(60, 22), 9 * u, Color("4f9a3e"))
			if name == "soil_dry":
				_finger(ci, p, u, Vector2(70, 42))
			else:
				for d: Vector2 in [Vector2(30, 44), Vector2(70, 40), Vector2(50, 10)]:
					LifeIcons._drop(ci, p.call(d.x, d.y), 5 * u, Color("5aa8e6"))
		"dog_lead":
			LifeIconsHazards._dog(ci, p, u, Vector2(40, 86), 1.0, false)
			ci.draw_line(p.call(70, 50), p.call(90, 14), Color("e8544e"), 3 * u)
		"vet":
			LifeIcons._person(ci, p, u, Vector2(26, 6), 1.0, WHITE)
			ci.draw_rect(Rect2(p.call(20, 30), Vector2(12, 4) * u), Color("3fbf5a"))
			ci.draw_rect(Rect2(p.call(24, 26), Vector2(4, 12) * u), Color("3fbf5a"))
			LifeIconsHazards._dog(ci, p, u, Vector2(60, 90), 0.8, false)
		"bin_paper", "bin_plastic", "bin_glass", "bin_food":
			var c: Color = {"bin_paper": PAPER, "bin_plastic": PLASTIC, "bin_glass": GLASS, "bin_food": FOOD}[name]
			_bin(ci, p, u, c)
			match name:
				"bin_paper":
					ci.draw_rect(Rect2(p.call(38, 48), Vector2(24, 18) * u), WHITE)
				"bin_plastic":
					ci.draw_rect(Rect2(p.call(44, 44), Vector2(12, 26) * u), Color("cfe8f8"))
				"bin_glass":
					ci.draw_rect(Rect2(p.call(42, 48), Vector2(16, 20) * u), Color(0.75, 0.95, 0.85))
				"bin_food":
					ci.draw_circle(p.call(50, 58), 9 * u, Color("e8544e"))
		"battery_box":
			ci.draw_rect(Rect2(p.call(18, 40), Vector2(64, 48) * u), GLASS)
			ci.draw_rect(Rect2(p.call(36, 18), Vector2(28, 14) * u), INK)
			ci.draw_rect(Rect2(p.call(46, 12), Vector2(8, 6) * u), Color("c9a646"))
			_text(ci, p, u, Vector2(30, 70), "+ -")
		"smoke_test":
			ci.draw_circle(p.call(50, 40), 30 * u, WHITE)
			ci.draw_arc(p.call(50, 40), 30 * u, 0, TAU, 20, INK, 2 * u)
			ci.draw_circle(p.call(50, 40), 9 * u, Color("e8544e"))
			_finger(ci, p, u, Vector2(56, 52))
			for r: float in [38.0, 44.0]:
				ci.draw_arc(p.call(50, 40), r * u, -0.5, 0.5, 6, SOFT_NO, 2 * u)
		"label_30", "label_40":
			_label_tag(ci, p, u)
			_tub(ci, p, u, Vector2(50, 50))
			_text(ci, p, u, Vector2(42, 60), "30" if name == "label_30" else "40")
		"label_hand":
			_label_tag(ci, p, u)
			_tub(ci, p, u, Vector2(50, 50))
			ci.draw_rect(Rect2(p.call(44, 36), Vector2(12, 16) * u), SKIN)
		"label_no_tumble":
			_label_tag(ci, p, u)
			ci.draw_rect(Rect2(p.call(32, 32), Vector2(36, 36) * u), INK, false, 3 * u)
			ci.draw_arc(p.call(50, 50), 12 * u, 0, TAU, 16, INK, 3 * u)
			ci.draw_line(p.call(28, 28), p.call(72, 72), SOFT_NO, 4 * u)
			ci.draw_line(p.call(72, 28), p.call(28, 72), SOFT_NO, 4 * u)
		"washing_label":
			_label_tag(ci, p, u)
			_tub(ci, p, u, Vector2(38, 40), 0.6)
			ci.draw_colored_polygon(PackedVector2Array([p.call(58, 46), p.call(66, 32), p.call(74, 46)]), INK)
			ci.draw_rect(Rect2(p.call(32, 56), Vector2(14, 14) * u), INK, false, 2 * u)
			ci.draw_rect(Rect2(p.call(58, 58), Vector2(16, 8) * u), INK)
		"knife_down", "knife_up":
			ci.draw_rect(Rect2(p.call(28, 30), Vector2(44, 60) * u), Color("dfe3ea"))
			ci.draw_rect(Rect2(p.call(28, 30), Vector2(44, 60) * u), INK, false, 2 * u)
			var down := name == "knife_down"
			ci.draw_rect(Rect2(p.call(46, 12 if down else 52), Vector2(8, 18) * u), WOOD)
			ci.draw_colored_polygon(PackedVector2Array([p.call(46, 30 if down else 52), p.call(54, 30 if down else 52),
				p.call(50, 80 if down else 18)]), Color("a9b3bf"))
			if down:
				_tick(ci, p, u, Vector2(84, 16))
			else:
				_cross(ci, p, u, Vector2(84, 16))
		"table_set":
			ci.draw_rect(Rect2(p.call(4, 60), Vector2(92, 30) * u), WOOD)
			ci.draw_circle(p.call(50, 62), 18 * u, WHITE)
			ci.draw_line(p.call(24, 48), p.call(24, 78), Color("a9b3bf"), 3 * u)
			ci.draw_line(p.call(76, 48), p.call(76, 78), Color("a9b3bf"), 3 * u)
			ci.draw_rect(Rect2(p.call(78, 34), Vector2(10, 14) * u), Color("5aa8e6"))
	return true


static func _tablet(ci: CanvasItem, p: Callable, u: float, screen: Color = SCREEN) -> void:
	ci.draw_rect(Rect2(p.call(14, 16), Vector2(72, 68) * u), FRAME)
	ci.draw_rect(Rect2(p.call(19, 21), Vector2(62, 58) * u), screen)


static func _finger(ci: CanvasItem, p: Callable, u: float, at: Vector2) -> void:
	ci.draw_rect(Rect2(p.call(at.x - 4, at.y), Vector2(9, 24) * u), SKIN)
	ci.draw_circle(p.call(at.x + 0.5, at.y), 4.5 * u, SKIN)


static func _padlock(ci: CanvasItem, p: Callable, u: float, at: Vector2, k: float, colour: Color, open := false) -> void:
	ci.draw_arc(p.call(at.x + (10 * k if open else 0.0), at.y - 14 * k), 13 * k * u, PI, TAU, 12, INK, 5 * k * u)
	ci.draw_rect(Rect2(p.call(at.x - 20 * k, at.y - 14 * k), Vector2(40, 32) * k * u), colour)
	ci.draw_circle(p.call(at.x, at.y + 1 * k), 4 * k * u, INK)


static func _photo(ci: CanvasItem, p: Callable, u: float, at: Vector2, k: float) -> void:
	ci.draw_rect(Rect2(p.call(at.x - 14 * k, at.y - 12 * k), Vector2(28, 24) * k * u), WHITE)
	ci.draw_rect(Rect2(p.call(at.x - 14 * k, at.y - 12 * k), Vector2(28, 24) * k * u), INK, false, 1.5 * u)
	ci.draw_circle(p.call(at.x, at.y - 2 * k), 6 * k * u, SKIN)
	ci.draw_rect(Rect2(p.call(at.x - 8 * k, at.y + 4 * k), Vector2(16, 6) * k * u), TEAL)


## Someone online you can't see: a grey round with a "?", never a face.
static func _mystery(ci: CanvasItem, p: Callable, u: float, at: Vector2) -> void:
	ci.draw_circle(p.call(at.x, at.y), 12 * u, Color("b8c2d6"))
	_text(ci, p, u, Vector2(at.x - 4, at.y + 5), "?")


static func _sock(ci: CanvasItem, p: Callable, u: float, top: Vector2, colour: Color) -> void:
	ci.draw_rect(Rect2(p.call(top.x, top.y), Vector2(16, 44) * u), colour)
	ci.draw_rect(Rect2(p.call(top.x, top.y + 44), Vector2(28, 14) * u), colour)
	for i in 3:
		ci.draw_rect(Rect2(p.call(top.x, top.y + 6 + i * 12), Vector2(16, 4) * u), WHITE)


static func _bin(ci: CanvasItem, p: Callable, u: float, colour: Color) -> void:
	ci.draw_rect(Rect2(p.call(24, 30), Vector2(52, 60) * u), colour)
	ci.draw_rect(Rect2(p.call(20, 22), Vector2(60, 10) * u), colour.darkened(0.2))


static func _label_tag(ci: CanvasItem, p: Callable, u: float) -> void:
	ci.draw_rect(Rect2(p.call(16, 12), Vector2(68, 80) * u), WHITE)
	ci.draw_rect(Rect2(p.call(16, 12), Vector2(68, 80) * u), INK, false, 2 * u)


## A washing tub (the care label's wash symbol).
static func _tub(ci: CanvasItem, p: Callable, u: float, at: Vector2, k: float = 1.0) -> void:
	ci.draw_polyline(PackedVector2Array([p.call(at.x - 22 * k, at.y - 16 * k), p.call(at.x - 16 * k, at.y + 18 * k),
		p.call(at.x + 16 * k, at.y + 18 * k), p.call(at.x + 22 * k, at.y - 16 * k)]), INK, 3 * u)
	ci.draw_polyline(PackedVector2Array([p.call(at.x - 22 * k, at.y - 12 * k), p.call(at.x - 11 * k, at.y - 16 * k),
		p.call(at.x, at.y - 12 * k), p.call(at.x + 11 * k, at.y - 16 * k), p.call(at.x + 22 * k, at.y - 12 * k)]), INK, 2 * u)


static func _tick(ci: CanvasItem, p: Callable, u: float, at: Vector2) -> void:
	LifeIconsHazards._tick(ci, p, u, at)


static func _cross(ci: CanvasItem, p: Callable, u: float, at: Vector2) -> void:
	LifeIconsHazards._cross(ci, p, u, at)


static func _text(ci: CanvasItem, p: Callable, u: float, at: Vector2, t: String) -> void:
	LifeIconsHazards._text(ci, p, u, at, t)
