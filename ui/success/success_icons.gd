class_name SuccessIcons
extends RefCounted
## Owner #115 (docs/design/life-skills.md §10: "heard, not read", every line with a picture): Success S2's pictures,
## drawn in code like LifeIcons (which asks here for any name it and LifeIconsMore don't draw: the owner #115 hook): the
## Success areas, the Goal Board's dreams, steps and habits, Talk & Deal's ways of saying things, the Connections Book's
## people (faces with their own clothes: SuccessPeople's "look"), the skills of the Success Stories and a symbol for each
## story (never a portrait of a real person). The same calm style: simple shapes, soft colours, a "no" in soft grey-blue.

const NAMES: Array[String] = [
	# the Success areas and places
	"goal", "handshake", "connections", "story_book", "habit_plant",
	# Goals & Habits
	"tower", "try_again", "goal_plan", "goal_calendar", "plan_card", "friends", "tiny", "honest", "woop", "rocks", "watering_can",
	"toothbrush", "tidy", "planet", "portal", "castle", "build_blocks", "pickaxe", "golem", "wall", "star",
	# Talk & Deal
	"talk_over", "say_back", "cross_arms", "shrug", "sorry", "thank_you", "quiet", "box_red", "box_blue", "box_yellow",
	"please", "bossy", "question_bubble", "fair_not", "promise", "problem_walk", "cart", "stall", "money_deal", "rain_cover",
	"walk_away",
	# The Connections Book
	"helping_hands", "spade", "signs", "postcard",
	"person_amara", "person_tomas", "person_ana", "person_ivan", "person_mei", "person_okafor", "person_kenji", "person_lina",
	"person_omar", "person_sam", "person_gemma", "person_rosa", "person_mo", "person_diaz", "person_ade", "person_kowalski",
	# Success Stories: the skills and the stories' symbols
	"skill_checked", "skill_courage", "skill_generous", "skill_helped", "skill_improve", "skill_kept_going", "skill_luck",
	"skill_notice", "skill_patience", "skill_share", "skill_team", "skill_try_again", "skill_use_what_you_have",
	"skill_start_small",
	"story_lamp", "story_teapot", "story_braille", "story_peanut", "story_plane", "story_orbit", "story_chair", "story_dish",
	"story_traffic", "story_hands", "story_rice", "story_slate", "story_airship", "story_village", "story_eye", "story_school",
	"story_mud_house", "story_mosquito", "story_flask"]

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
const RED := Color("e8544e")
const BLUE := Color("3a7be8")
const YELLOW := Color("ffc93c")
const PURPLE := Color("8b6fd6")
const PINK := Color("e85a9a")
const STONE := Color("9aa7b5")
const LEAF := Color("4f9a3e")
const EARTH := Color("b07a46")
const PAPER := Color("fdf6e3")
## The people's skin tones (a village of all kinds of people), by person.
const SKINS := {"amara": Color("8d5a3b"), "tomas": Color("f2c79b"), "ana": Color("d9a066"), "ivan": Color("f0c8a0"),
	"mei": Color("f3d2a8"), "okafor": Color("6b4429"), "kenji": Color("eac096"), "lina": Color("c98d5e"),
	"omar": Color("b97a4f"), "sam": Color("f2c79b"), "gemma": Color("e3b18a"), "rosa": Color("a8693f"),
	"mo": Color("f2c79b"), "diaz": Color("c48a5c"), "ade": Color("5a3a24"), "kowalski": Color("f4d4b8")}


static func has(name: String) -> bool:
	return NAMES.has(name) or SuccessIconsMarket.has(name)   # owner #115 (S3): the shop's and the market's pictures


## Draws `name` with `p` (0..100 coordinates to the canvas) and `u` (one unit); false for a name not drawn here.
static func paint(ci: CanvasItem, name: String, p: Callable, u: float) -> bool:
	if SuccessIconsMarket.has(name):   # owner #115 (S3)
		return SuccessIconsMarket.paint(ci, name, p, u)
	if name.begins_with("person_"):
		_person(ci, p, u, name.trim_prefix("person_"))
		return true
	match name:
		"goal":
			for i in 4:
				ci.draw_circle(p.call(50, 52), (42 - i * 10) * u, RED if i % 2 == 0 else WHITE)
			ci.draw_line(p.call(86, 16), p.call(52, 50), WOOD, 5 * u, true)
			ci.draw_colored_polygon(PackedVector2Array([p.call(86, 16), p.call(94, 8), p.call(92, 22)]), GOLD)
		"handshake":
			ci.draw_rect(Rect2(p.call(8, 46), Vector2(30, 18) * u), BLUE)
			ci.draw_rect(Rect2(p.call(62, 46), Vector2(30, 18) * u), PURPLE)
			ci.draw_colored_polygon(PackedVector2Array([p.call(34, 44), p.call(58, 40), p.call(68, 52), p.call(56, 66),
				p.call(34, 64)]), SKIN)
			for x: float in [44, 52, 60]:
				ci.draw_line(p.call(x, 46), p.call(x - 4, 62), SKIN.darkened(0.2), 2.5 * u, true)
			_heart(ci, p.call(50, 24), 9 * u, RED.lightened(0.2))
		"connections":
			_book(ci, p, u, Color("2f7f6a"))
			var dots: Array[Vector2] = [Vector2(36, 40), Vector2(64, 40), Vector2(50, 64)]
			for i in 3:
				ci.draw_line(p.call(dots[i].x, dots[i].y), p.call(dots[(i + 1) % 3].x, dots[(i + 1) % 3].y), WHITE, 3 * u, true)
			for d in dots:
				ci.draw_circle(p.call(d.x, d.y), 7 * u, GOLD)
		"story_book":
			_book(ci, p, u, PURPLE)
			_star(ci, p.call(50, 50), 16 * u, GOLD)
		"habit_plant":
			_pot(ci, p, u)
			_sprout(ci, p, u, 3)
		"tower":
			for i in 3:
				var w := 46.0 - i * 10.0
				ci.draw_rect(Rect2(p.call(50 - w * 0.5, 72 - i * 24), Vector2(w, 22) * u), [RED, BLUE, YELLOW][i])
			ci.draw_rect(Rect2(p.call(14, 94), Vector2(72, 4) * u), STONE)
		"try_again", "skill_try_again":
			var c := GOOD if name == "try_again" else BLUE
			ci.draw_arc(p.call(50, 52), 30 * u, -2.4, 2.4, 28, c, 10 * u)
			ci.draw_colored_polygon(PackedVector2Array([p.call(28, 22), p.call(48, 30), p.call(24, 42)]), c)
		"goal_plan":
			_paper(ci, p, u)
			for i in 3:
				ci.draw_line(p.call(40, 32 + i * 18), p.call(72, 32 + i * 18), INK.lightened(0.4), 4 * u)
				_tick(ci, p, u, Vector2(30, 32 + i * 18), 0.45, GOOD if i < 2 else SOFT_NO)
		"goal_calendar":
			_calendar(ci, p, u, 5)
		"plan_card":
			_paper(ci, p, u)
			_clock_face(ci, p.call(36, 40), 12 * u)
			ci.draw_line(p.call(52, 40), p.call(66, 40), INK, 4 * u, true)
			ci.draw_colored_polygon(PackedVector2Array([p.call(66, 34), p.call(74, 40), p.call(66, 46)]), INK)
			_tick(ci, p, u, Vector2(50, 70), 0.8, GOOD)
		"friends":
			_face(ci, p.call(34, 50), 20 * u, SKIN, "smile")
			_face(ci, p.call(66, 50), 20 * u, Color("c98d5e"), "smile")
			_heart(ci, p.call(50, 16), 8 * u, PINK)
		"tiny":
			ci.draw_arc(p.call(50, 50), 36 * u, 0, TAU, 32, SOFT_NO, 4 * u)
			ci.draw_colored_polygon(PackedVector2Array([p.call(50, 50), p.call(50, 14), p.call(70, 20)]), GOOD)
		"honest":
			_heart(ci, p.call(50, 52), 36 * u, RED.lightened(0.15))
			_tick(ci, p, u, Vector2(50, 50), 0.9, WHITE)
		"woop":
			var cols: Array[Color] = [GOLD, SKY, STONE, GOOD]
			for i in 4:
				ci.draw_rect(Rect2(p.call(6 + i * 23, 30), Vector2(19, 40) * u), cols[i])
			_star(ci, p.call(15.5, 50), 7 * u, WHITE)
			ci.draw_circle(p.call(38.5, 50), 6 * u, WHITE)
			ci.draw_colored_polygon(PackedVector2Array([p.call(55, 58), p.call(61, 42), p.call(68, 58)]), WHITE)
			_tick(ci, p, u, Vector2(84.5, 50), 0.5, WHITE)
		"rocks":
			ci.draw_rect(Rect2(p.call(24, 18), Vector2(52, 74) * u), Color(0.8, 0.92, 1.0, 0.6))
			ci.draw_rect(Rect2(p.call(24, 76), Vector2(52, 16) * u), Color("e8d39a"))
			ci.draw_circle(p.call(40, 64), 12 * u, STONE.darkened(0.15))
			ci.draw_circle(p.call(60, 66), 10 * u, STONE)
			for q: Vector2 in [Vector2(36, 46), Vector2(48, 50), Vector2(62, 48)]:
				ci.draw_circle(p.call(q.x, q.y), 4 * u, STONE.lightened(0.2))
			ci.draw_rect(Rect2(p.call(22, 14), Vector2(56, 6) * u), STONE.darkened(0.3))
		"watering_can":
			ci.draw_rect(Rect2(p.call(26, 40), Vector2(40, 36) * u), SKY.darkened(0.1))
			ci.draw_line(p.call(64, 58), p.call(90, 34), SKY.darkened(0.1), 7 * u, true)
			ci.draw_arc(p.call(46, 40), 14 * u, PI, TAU, 12, SKY.darkened(0.25), 5 * u)
			for i in 3:
				_drop(ci, p.call(86 + i * 3, 46 + i * 12), 3.5 * u, SKY)
		"toothbrush":
			ci.draw_line(p.call(14, 80), p.call(70, 30), BLUE, 9 * u, true)
			ci.draw_rect(Rect2(p.call(66, 14), Vector2(22, 14) * u), WHITE)
			for x: float in [68, 74, 80, 86]:
				ci.draw_line(p.call(x, 28), p.call(x, 34), SKY, 3 * u)
			ci.draw_circle(p.call(77, 12), 6 * u, Color("b9e6ff"))
		"tidy":
			ci.draw_rect(Rect2(p.call(18, 50), Vector2(64, 40) * u), WOOD)
			ci.draw_rect(Rect2(p.call(14, 46), Vector2(72, 8) * u), WOOD.darkened(0.2))
			ci.draw_circle(p.call(38, 36), 10 * u, RED)
			ci.draw_rect(Rect2(p.call(54, 22), Vector2(16, 16) * u), BLUE)
			ci.draw_line(p.call(58, 40), p.call(56, 48), INK, 3 * u)
		"planet":
			ci.draw_circle(p.call(50, 50), 38 * u, Color("d9603b"))
			for c: Vector3 in [Vector3(38, 38, 7), Vector3(62, 58, 9), Vector3(44, 66, 5)]:
				ci.draw_circle(p.call(c.x, c.y), c.z * u, Color("b84a2e"))
		"portal":
			ci.draw_rect(Rect2(p.call(22, 10), Vector2(56, 84) * u), STONE.darkened(0.3))
			ci.draw_rect(Rect2(p.call(30, 18), Vector2(40, 70) * u), PURPLE)
			ci.draw_circle(p.call(50, 52), 14 * u, PURPLE.lightened(0.35))
			_star(ci, p.call(50, 52), 7 * u, WHITE)
		"castle":
			ci.draw_rect(Rect2(p.call(14, 40), Vector2(72, 52) * u), STONE)
			for x: float in [14, 70]:
				ci.draw_rect(Rect2(p.call(x, 22), Vector2(16, 20) * u), STONE.darkened(0.1))
				ci.draw_colored_polygon(PackedVector2Array([p.call(x - 2, 22), p.call(x + 8, 8), p.call(x + 18, 22)]), RED)
			ci.draw_rect(Rect2(p.call(42, 64), Vector2(16, 28) * u), WOOD.darkened(0.2))
		"build_blocks":
			ci.draw_rect(Rect2(p.call(14, 58), Vector2(34, 32) * u), GOOD)
			ci.draw_rect(Rect2(p.call(52, 58), Vector2(34, 32) * u), BLUE)
			ci.draw_rect(Rect2(p.call(33, 24), Vector2(34, 32) * u), RED)
		"pickaxe":
			ci.draw_line(p.call(26, 86), p.call(66, 30), WOOD, 8 * u, true)
			ci.draw_arc(p.call(60, 40), 30 * u, -2.6, -0.6, 14, STONE.darkened(0.2), 9 * u)
		"golem":
			ci.draw_rect(Rect2(p.call(20, 20), Vector2(60, 62) * u), STONE)
			for x: float in [36, 64]:
				ci.draw_rect(Rect2(p.call(x - 6, 40), Vector2(12, 10) * u), Color("7ad3ff"))
			ci.draw_arc(p.call(50, 62), 10 * u, 0.3, PI - 0.3, 10, INK, 4 * u)
			ci.draw_rect(Rect2(p.call(20, 20), Vector2(60, 8) * u), LEAF)
		"wall":
			for row in 4:
				for col in 3:
					var x := 10.0 + col * 27.0 + (13.0 if row % 2 == 1 else 0.0)
					ci.draw_rect(Rect2(p.call(minf(x, 64), 20 + row * 17), Vector2(25, 15) * u), RED.darkened(0.15))
		"star":
			_star(ci, p.call(50, 52), 40 * u, GOLD)
		"talk_over":
			_bubble(ci, p, u, Rect2(8, 14, 54, 36), SKY)
			_bubble(ci, p, u, Rect2(38, 40, 54, 36), PINK)
			for i in 3:
				ci.draw_line(p.call(50 + i * 10, 52), p.call(55 + i * 10, 62), WHITE, 3 * u)
		"say_back":
			_bubble(ci, p, u, Rect2(8, 12, 50, 32), SKY)
			_bubble(ci, p, u, Rect2(42, 54, 50, 32), GOOD)
			ci.draw_arc(p.call(50, 50), 16 * u, -1.0, 1.4, 12, INK, 4 * u)
		"cross_arms":
			_face(ci, p.call(50, 36), 24 * u, SKIN, "flat")
			ci.draw_line(p.call(22, 66), p.call(78, 84), SOFT_NO, 12 * u, true)
			ci.draw_line(p.call(78, 66), p.call(22, 84), SOFT_NO.darkened(0.15), 12 * u, true)
		"shrug":
			_face(ci, p.call(50, 46), 22 * u, SKIN, "flat")
			for side: int in [-1, 1]:
				ci.draw_line(p.call(50 + side * 24, 64), p.call(50 + side * 40, 46), SOFT_NO, 7 * u, true)
				ci.draw_circle(p.call(50 + side * 40, 44), 6 * u, SKIN)
		"sorry":
			_face(ci, p.call(50, 40), 26 * u, SKIN, "soft")
			_heart(ci, p.call(50, 82), 12 * u, PINK)
		"thank_you":
			_bubble(ci, p, u, Rect2(10, 14, 80, 56), GOOD)
			_heart(ci, p.call(50, 42), 14 * u, WHITE)
		"quiet":
			_face(ci, p.call(50, 50), 36 * u, SKIN, "none")
			ci.draw_line(p.call(34, 64), p.call(66, 64), INK, 4 * u)
			for x: float in [38, 46, 54, 62]:
				ci.draw_line(p.call(x, 60), p.call(x, 68), INK, 2 * u)
		"box_red", "box_blue", "box_yellow":
			var c: Color = {"box_red": RED, "box_blue": BLUE, "box_yellow": YELLOW}[name]
			ci.draw_colored_polygon(PackedVector2Array([p.call(22, 34), p.call(40, 18), p.call(84, 18), p.call(66, 34)]),
				c.lightened(0.25))
			ci.draw_colored_polygon(PackedVector2Array([p.call(66, 34), p.call(84, 18), p.call(84, 66), p.call(66, 84)]),
				c.darkened(0.2))
			ci.draw_rect(Rect2(p.call(22, 34), Vector2(44, 50) * u), c)
		"please":
			_bubble(ci, p, u, Rect2(10, 14, 80, 56), PURPLE)
			ci.draw_arc(p.call(42, 34), 9 * u, PI, TAU + 0.6, 12, WHITE, 5 * u)
			ci.draw_circle(p.call(42, 56), 3.5 * u, WHITE)
			_heart(ci, p.call(66, 44), 9 * u, PINK.lightened(0.3))
		"bossy":
			ci.draw_rect(Rect2(p.call(14, 46), Vector2(30, 34) * u), SKIN)
			ci.draw_rect(Rect2(p.call(40, 50), Vector2(44, 12) * u), SKIN)
			ci.draw_rect(Rect2(p.call(80, 22), Vector2(8, 26) * u), SOFT_NO)
			ci.draw_circle(p.call(84, 56), 4 * u, SOFT_NO)
		"question_bubble":
			_bubble(ci, p, u, Rect2(10, 14, 80, 56), SKY)
			ci.draw_arc(p.call(50, 34), 10 * u, PI, TAU + 0.6, 12, WHITE, 6 * u)
			ci.draw_line(p.call(56, 42), p.call(50, 48), WHITE, 6 * u)
			ci.draw_circle(p.call(50, 58), 4 * u, WHITE)
		"fair_not":
			ci.draw_line(p.call(50, 20), p.call(50, 86), WOOD, 6 * u)
			ci.draw_line(p.call(18, 30), p.call(82, 50), WOOD, 5 * u, true)
			ci.draw_arc(p.call(18, 38), 12 * u, 0, PI, 10, STONE, 5 * u)
			ci.draw_arc(p.call(82, 58), 12 * u, 0, PI, 10, STONE, 5 * u)
			ci.draw_circle(p.call(82, 62), 6 * u, GOLD)
			ci.draw_rect(Rect2(p.call(34, 86), Vector2(32, 6) * u), WOOD)
		"promise":
			_calendar(ci, p, u, 0)
			_heart(ci, p.call(50, 62), 14 * u, PINK)
		"problem_walk":
			for i in 6:
				ci.draw_circle(p.call(14 + i * 14, 80 - i * 6), 3 * u, STONE)
			_stick(ci, p, u, Vector2(26, 50), TEAL)
			_clock_face(ci, p.call(74, 30), 16 * u)
		"cart":
			ci.draw_rect(Rect2(p.call(16, 36), Vector2(60, 30) * u), WOOD)
			for x: float in [28, 64]:
				ci.draw_circle(p.call(x, 72), 9 * u, INK)
				ci.draw_circle(p.call(x, 72), 4 * u, STONE)
			ci.draw_line(p.call(76, 40), p.call(92, 28), WOOD.darkened(0.2), 5 * u, true)
			ci.draw_rect(Rect2(p.call(26, 24), Vector2(22, 12) * u), Color("d99a4e"))
			ci.draw_rect(Rect2(p.call(50, 26), Vector2(20, 10) * u), Color("d99a4e"))
		"stall":
			ci.draw_rect(Rect2(p.call(14, 54), Vector2(72, 34) * u), WOOD)
			for i in 6:
				ci.draw_rect(Rect2(p.call(10 + i * 13.3, 18), Vector2(13.3, 18) * u), RED if i % 2 == 0 else WHITE)
			for x: float in [14, 82]:
				ci.draw_line(p.call(x + 2, 36), p.call(x + 2, 54), WOOD.darkened(0.3), 4 * u)
			ci.draw_rect(Rect2(p.call(26, 44), Vector2(18, 10) * u), Color("d99a4e"))
		"money_deal":
			for i in 3:
				ci.draw_circle(p.call(30, 76 - i * 12), 16 * u, GOLD.darkened(i * 0.06))
			ci.draw_circle(p.call(70, 44), 24 * u, SOFT_NO.lightened(0.3))
			ci.draw_colored_polygon(PackedVector2Array([p.call(70, 44), p.call(70, 20), p.call(84, 25)]), GOOD)
		"rain_cover":
			ci.draw_arc(p.call(50, 52), 34 * u, PI, TAU, 16, BLUE, 8 * u)
			ci.draw_line(p.call(50, 52), p.call(50, 86), INK, 4 * u)
			for x: float in [20, 40, 62, 82]:
				_drop(ci, p.call(x, 12), 4 * u, SKY)
			ci.draw_rect(Rect2(p.call(30, 66), Vector2(40, 20) * u), WOOD)
		"walk_away":
			ci.draw_rect(Rect2(p.call(58, 14), Vector2(32, 76) * u), GOOD.darkened(0.2))
			ci.draw_rect(Rect2(p.call(62, 18), Vector2(24, 72) * u), Color("cfe9b0"))
			_stick(ci, p, u, Vector2(36, 40), TEAL)
			ci.draw_line(p.call(36, 46), p.call(20, 30), TEAL, 5 * u, true)
		"helping_hands":
			_heart(ci, p.call(50, 36), 18 * u, RED.lightened(0.2))
			for side: int in [-1, 1]:
				ci.draw_colored_polygon(PackedVector2Array([p.call(50, 82), p.call(50 + side * 40, 60), p.call(50 + side * 44, 70),
					p.call(50 + side * 6, 92)]), SKIN.darkened(0.05 if side < 0 else 0.25))
		"spade":
			ci.draw_line(p.call(50, 10), p.call(50, 62), WOOD, 7 * u)
			ci.draw_rect(Rect2(p.call(40, 8), Vector2(20, 7) * u), WOOD.darkened(0.2))
			ci.draw_colored_polygon(PackedVector2Array([p.call(34, 60), p.call(66, 60), p.call(62, 88), p.call(50, 94),
				p.call(38, 88)]), STONE)
		"signs":
			ci.draw_rect(Rect2(p.call(30, 40), Vector2(30, 34) * u), SKIN)
			for i in 4:
				ci.draw_rect(Rect2(p.call(30 + i * 7.5, 18), Vector2(6, 24) * u), SKIN)
			ci.draw_rect(Rect2(p.call(58, 48), Vector2(16, 8) * u), SKIN)
			for i in 3:
				ci.draw_arc(p.call(70, 30), (10 + i * 8) * u, -1.2, 0.2, 8, PURPLE, 3 * u)
		"postcard":
			ci.draw_rect(Rect2(p.call(8, 22), Vector2(84, 56) * u), PAPER)
			ci.draw_rect(Rect2(p.call(8, 22), Vector2(84, 56) * u), STONE, false, 3 * u)
			ci.draw_rect(Rect2(p.call(70, 28), Vector2(16, 18) * u), RED)
			for i in 3:
				ci.draw_line(p.call(16, 40 + i * 10), p.call(52, 40 + i * 10), INK.lightened(0.4), 3 * u)
			_heart(ci, p.call(70, 62), 7 * u, PINK)
		"skill_checked":
			_paper(ci, p, u)
			for i in 3:
				_tick(ci, p, u, Vector2(36, 30 + i * 18), 0.45, GOOD)
				ci.draw_line(p.call(46, 30 + i * 18), p.call(70, 30 + i * 18), INK.lightened(0.4), 3 * u)
			ci.draw_arc(p.call(70, 70), 12 * u, 0, TAU, 16, INK, 4 * u)
			ci.draw_line(p.call(78, 78), p.call(90, 90), INK, 5 * u)
		"skill_courage":
			_heart(ci, p.call(50, 56), 36 * u, WARM)
			_star(ci, p.call(50, 50), 14 * u, WHITE)
		"skill_generous":
			ci.draw_colored_polygon(PackedVector2Array([p.call(10, 70), p.call(60, 62), p.call(76, 74), p.call(34, 90),
				p.call(10, 86)]), SKIN)
			ci.draw_circle(p.call(56, 44), 16 * u, GOLD)
			_heart(ci, p.call(56, 44), 7 * u, RED.lightened(0.2))
		"skill_helped":
			_stick(ci, p, u, Vector2(50, 26), TEAL)
			for side: int in [-1, 1]:
				ci.draw_colored_polygon(PackedVector2Array([p.call(50, 90), p.call(50 + side * 36, 66), p.call(50 + side * 40, 76),
					p.call(50 + side * 4, 96)]), SKIN.darkened(0.05 if side < 0 else 0.25))
		"skill_improve":
			ci.draw_circle(p.call(42, 44), 22 * u, YELLOW)
			ci.draw_rect(Rect2(p.call(34, 64), Vector2(16, 14) * u), STONE)
			ci.draw_line(p.call(76, 82), p.call(76, 26), GOOD, 7 * u)
			ci.draw_colored_polygon(PackedVector2Array([p.call(64, 34), p.call(76, 16), p.call(88, 34)]), GOOD)
		"skill_kept_going":
			ci.draw_polyline(PackedVector2Array([p.call(12, 88), p.call(40, 76), p.call(22, 56), p.call(56, 46), p.call(40, 28),
				p.call(70, 20)]), EARTH, 8 * u, true)
			ci.draw_line(p.call(72, 22), p.call(72, 4), INK, 3 * u)
			ci.draw_colored_polygon(PackedVector2Array([p.call(72, 4), p.call(90, 9), p.call(72, 14)]), RED)
		"skill_luck":
			for a: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				ci.draw_circle(p.call(50 + a.x * 13, 44 + a.y * 13), 15 * u, LEAF.lightened(0.15))
			ci.draw_line(p.call(50, 50), p.call(60, 90), LEAF.darkened(0.2), 5 * u, true)
		"skill_notice":
			ci.draw_arc(p.call(44, 44), 26 * u, 0, TAU, 24, INK, 7 * u)
			ci.draw_circle(p.call(44, 44), 22 * u, Color(0.8, 0.92, 1.0, 0.6))
			ci.draw_circle(p.call(44, 44), 8 * u, INK)
			ci.draw_line(p.call(64, 64), p.call(88, 88), WOOD, 9 * u)
		"skill_patience":
			ci.draw_colored_polygon(PackedVector2Array([p.call(26, 10), p.call(74, 10), p.call(52, 50), p.call(74, 90),
				p.call(26, 90), p.call(48, 50)]), Color(0.8, 0.92, 1.0, 0.7))
			ci.draw_colored_polygon(PackedVector2Array([p.call(34, 90), p.call(66, 90), p.call(50, 70)]), Color("e8d39a"))
			for y: float in [8, 88]:
				ci.draw_rect(Rect2(p.call(20, y), Vector2(60, 6) * u), WOOD)
			ci.draw_line(p.call(50, 70), p.call(50, 58), LEAF, 3 * u)
		"skill_share":
			_book(ci, p, u, BLUE)
			for a: float in [-0.6, 0.0, 0.6]:
				var d := Vector2(sin(a), -cos(a))
				ci.draw_line(p.call(50 + d.x * 20, 30 + d.y * 6), p.call(50 + d.x * 40, 26 + d.y * 22), GOLD, 4 * u, true)
		"skill_team":
			for i in 3:
				_stick(ci, p, u, Vector2(22 + i * 28, 40), [TEAL, PINK, GOLD][i])
			ci.draw_line(p.call(30, 62), p.call(70, 62), INK.lightened(0.3), 3 * u)
		"skill_use_what_you_have":
			for i in 3:
				ci.draw_rect(Rect2(p.call(14 + i * 24, 62), Vector2(22, 14) * u), EARTH)
			ci.draw_rect(Rect2(p.call(26, 46), Vector2(22, 14) * u), EARTH.lightened(0.1))
			ci.draw_rect(Rect2(p.call(50, 46), Vector2(22, 14) * u), EARTH.darkened(0.1))
			ci.draw_arc(p.call(50, 46), 26 * u, PI, TAU, 16, EARTH.darkened(0.25), 6 * u)
			_tick(ci, p, u, Vector2(50, 20), 0.5, GOOD)
		"skill_start_small":
			_sprout(ci, p, u, 1)
			ci.draw_rect(Rect2(p.call(10, 80), Vector2(80, 10) * u), EARTH)
		"story_lamp":
			ci.draw_colored_polygon(PackedVector2Array([p.call(20, 60), p.call(80, 60), p.call(70, 76), p.call(30, 76)]), GOLD)
			ci.draw_arc(p.call(76, 66), 10 * u, -1.6, 1.6, 10, GOLD.darkened(0.3), 4 * u)
			ci.draw_colored_polygon(PackedVector2Array([p.call(22, 60), p.call(10, 52), p.call(24, 54)]), GOLD)
			ci.draw_circle(p.call(12, 44), 9 * u, Color(1, 0.86, 0.3, 0.8))
			ci.draw_rect(Rect2(p.call(20, 78), Vector2(60, 6) * u), WOOD)
		"story_teapot":
			ci.draw_circle(p.call(46, 58), 26 * u, PURPLE.lightened(0.2))
			ci.draw_line(p.call(70, 56), p.call(90, 40), PURPLE.lightened(0.2), 7 * u, true)
			ci.draw_arc(p.call(22, 58), 12 * u, 1.6, 4.7, 10, PURPLE, 5 * u)
			ci.draw_rect(Rect2(p.call(38, 28), Vector2(16, 6) * u), PURPLE)
			for i in 3:
				ci.draw_arc(p.call(84 + i * 3, 26 - i * 6), 4 * u, 0, PI, 6, STONE, 2 * u)
		"story_braille":
			ci.draw_rect(Rect2(p.call(26, 10), Vector2(48, 80) * u), PAPER)
			for r in 3:
				for c in 2:
					var on := (r == 0) or (r == 1 and c == 0)
					ci.draw_circle(p.call(40 + c * 20, 28 + r * 22), 7 * u, INK if on else STONE.lightened(0.3))
		"story_peanut":
			ci.draw_circle(p.call(40, 40), 18 * u, Color("d9b77a"))
			ci.draw_circle(p.call(60, 62), 18 * u, Color("d9b77a"))
			ci.draw_line(p.call(34, 30), p.call(46, 46), Color("b08f55"), 2 * u)
			ci.draw_line(p.call(54, 54), p.call(66, 70), Color("b08f55"), 2 * u)
		"story_plane":
			ci.draw_rect(Rect2(p.call(10, 34), Vector2(80, 6) * u), Color("e8dcc0"))
			ci.draw_rect(Rect2(p.call(10, 54), Vector2(80, 6) * u), Color("e8dcc0"))
			for x: float in [20, 50, 80]:
				ci.draw_line(p.call(x, 40), p.call(x, 54), WOOD, 2 * u)
			ci.draw_rect(Rect2(p.call(44, 40), Vector2(12, 14) * u), STONE)
			ci.draw_line(p.call(56, 47), p.call(88, 47), WOOD, 2 * u)
			ci.draw_rect(Rect2(p.call(84, 40), Vector2(8, 14) * u), Color("e8dcc0"))
		"story_orbit":
			ci.draw_circle(p.call(50, 50), 20 * u, SKY)
			ci.draw_circle(p.call(44, 44), 7 * u, LEAF)
			ci.draw_arc(p.call(50, 50), 38 * u, 0, TAU, 32, INK.lightened(0.4), 2 * u)
			ci.draw_circle(p.call(84, 36), 6 * u, WHITE)
		"story_chair":
			ci.draw_rect(Rect2(p.call(30, 50), Vector2(40, 8) * u), WOOD)
			ci.draw_rect(Rect2(p.call(30, 16), Vector2(8, 42) * u), WOOD)
			for x: float in [32, 64]:
				ci.draw_rect(Rect2(p.call(x, 58), Vector2(5, 30) * u), WOOD.darkened(0.2))
			ci.draw_rect(Rect2(p.call(52, 36), Vector2(14, 14) * u), RED)
		"story_dish":
			ci.draw_circle(p.call(50, 54), 38 * u, Color(0.85, 0.94, 1.0, 0.8))
			ci.draw_arc(p.call(50, 54), 38 * u, 0, TAU, 32, STONE, 3 * u)
			for q: Vector2 in [Vector2(28, 40), Vector2(70, 36), Vector2(30, 72), Vector2(74, 72)]:
				ci.draw_circle(p.call(q.x, q.y), 4 * u, Color("e0c34a"))
			ci.draw_circle(p.call(50, 54), 11 * u, LEAF.lightened(0.3))
		"story_traffic":
			ci.draw_rect(Rect2(p.call(36, 8), Vector2(28, 70) * u), INK)
			ci.draw_circle(p.call(50, 22), 8 * u, RED)
			ci.draw_circle(p.call(50, 43), 8 * u, YELLOW)
			ci.draw_circle(p.call(50, 64), 8 * u, GOOD)
			ci.draw_rect(Rect2(p.call(46, 78), Vector2(8, 16) * u), STONE)
		"story_hands":
			for i in 3:
				var x := 22.0 + i * 28.0
				ci.draw_rect(Rect2(p.call(x - 9, 42), Vector2(18, 40) * u), [SKIN, Color("c98d5e"), Color("8d5a3b")][i])
				ci.draw_circle(p.call(x, 40), 10 * u, [SKIN, Color("c98d5e"), Color("8d5a3b")][i])
			_heart(ci, p.call(50, 18), 9 * u, RED.lightened(0.2))
		"story_rice":
			for i in 3:
				var x := 30.0 + i * 20.0
				ci.draw_line(p.call(x, 90), p.call(x + 6, 24), LEAF, 4 * u, true)
				for k in 4:
					ci.draw_circle(p.call(x + 6 + (k % 2) * 4, 24 + k * 7), 3.5 * u, Color("e8d39a"))
		"story_slate":
			ci.draw_rect(Rect2(p.call(14, 18), Vector2(72, 54) * u), WOOD)
			ci.draw_rect(Rect2(p.call(20, 24), Vector2(60, 42) * u), Color("2f4f4f"))
			for i in 3:
				ci.draw_line(p.call(28, 34 + i * 10), p.call(60 - i * 6, 34 + i * 10), WHITE, 3 * u)
			_stick(ci, p, u, Vector2(74, 64), PINK)
		"story_airship":
			ci.draw_circle(p.call(40, 40), 20 * u, Color("e8dcc0"))
			ci.draw_circle(p.call(62, 40), 20 * u, Color("e8dcc0"))
			ci.draw_rect(Rect2(p.call(40, 20), Vector2(22, 40) * u), Color("e8dcc0"))
			ci.draw_rect(Rect2(p.call(42, 68), Vector2(18, 8) * u), WOOD)
			ci.draw_line(p.call(44, 60), p.call(46, 68), INK, 2 * u)
			ci.draw_line(p.call(58, 60), p.call(56, 68), INK, 2 * u)
		"story_village":
			for i in 3:
				var x := 12.0 + i * 28.0
				ci.draw_rect(Rect2(p.call(x, 52), Vector2(22, 26) * u), [Color("f3e1c0"), Color("cfe9b0"), Color("f6c2d6")][i])
				ci.draw_colored_polygon(PackedVector2Array([p.call(x - 3, 52), p.call(x + 11, 38), p.call(x + 25, 52)]), RED)
			ci.draw_rect(Rect2(p.call(6, 78), Vector2(88, 6) * u), LEAF)
		"story_eye":
			ci.draw_colored_polygon(PackedVector2Array([p.call(8, 50), p.call(30, 32), p.call(70, 32), p.call(92, 50),
				p.call(70, 68), p.call(30, 68)]), WHITE)
			ci.draw_circle(p.call(50, 50), 16 * u, SKY.darkened(0.2))
			ci.draw_circle(p.call(50, 50), 7 * u, INK)
			ci.draw_circle(p.call(45, 45), 3 * u, WHITE)
		"story_school":
			ci.draw_rect(Rect2(p.call(18, 44), Vector2(64, 44) * u), Color("f3e1c0"))
			ci.draw_colored_polygon(PackedVector2Array([p.call(12, 44), p.call(50, 18), p.call(88, 44)]), BLUE)
			ci.draw_rect(Rect2(p.call(44, 64), Vector2(12, 24) * u), WOOD)
			for x: float in [26, 64]:
				ci.draw_rect(Rect2(p.call(x, 54), Vector2(10, 10) * u), SKY)
		"story_mud_house":
			ci.draw_rect(Rect2(p.call(16, 46), Vector2(68, 42) * u), EARTH.lightened(0.15))
			ci.draw_arc(p.call(50, 46), 34 * u, PI, TAU, 18, EARTH, 8 * u)
			ci.draw_arc(p.call(50, 88), 10 * u, PI, TAU, 10, WOOD.darkened(0.3), 8 * u)
		"story_mosquito":
			ci.draw_line(p.call(26, 62), p.call(74, 42), INK, 6 * u, true)
			ci.draw_circle(p.call(76, 40), 6 * u, INK)
			ci.draw_line(p.call(80, 38), p.call(94, 30), INK, 2 * u)
			for x: float in [44, 56]:
				ci.draw_circle(p.call(x, 38), 10 * u, Color(0.8, 0.92, 1.0, 0.7))
			ci.draw_circle(p.call(30, 76), 12 * u, SOFT_NO.lightened(0.3))
			ci.draw_line(p.call(22, 68), p.call(38, 84), WHITE, 3 * u)
		"story_flask":
			ci.draw_colored_polygon(PackedVector2Array([p.call(40, 12), p.call(60, 12), p.call(60, 40), p.call(82, 84),
				p.call(18, 84), p.call(40, 40)]), Color(0.85, 0.94, 1.0, 0.7))
			ci.draw_colored_polygon(PackedVector2Array([p.call(30, 62), p.call(70, 62), p.call(82, 84), p.call(18, 84)]),
				Color(0.55, 0.95, 0.75, 0.9))
			ci.draw_circle(p.call(50, 72), 4 * u, WHITE)
		_:
			return false
	return true


# --- People ------------------------------------------------------------------------------------------------------------

## A friendly face for one of the Connections Book's people, in their colours and clothes (their "look").
static func _person(ci: CanvasItem, p: Callable, u: float, id: String) -> void:
	var data := SuccessPeople.person(id)
	var body := Color(str(data.get("colour", "1fa6a0")))
	var skin: Color = SKINS.get(id, SKIN)
	var look := str(data.get("look", "plain"))
	ci.draw_rect(Rect2(p.call(22, 70), Vector2(56, 30) * u), body)
	if look == "suit":
		ci.draw_colored_polygon(PackedVector2Array([p.call(46, 70), p.call(54, 70), p.call(52, 96), p.call(48, 96)]), RED)
	if look == "wheelchair":
		ci.draw_arc(p.call(80, 84), 13 * u, 0, TAU, 20, INK, 4 * u)
		ci.draw_circle(p.call(80, 84), 3 * u, INK)
	if look in ["headscarf"]:
		ci.draw_circle(p.call(50, 44), 31 * u, body.darkened(0.15))
	ci.draw_circle(p.call(50, 46), 26 * u, skin)
	var hair := Color("3b2a18") if look != "beard" else Color("dcdcdc")
	if look not in ["chef_hat", "hard_hat", "straw_hat", "explorer_hat", "flat_cap", "headscarf"]:
		ci.draw_arc(p.call(50, 44), 26 * u, PI + 0.2, TAU - 0.2, 14, hair, 9 * u)
	for x: float in [41, 59]:
		ci.draw_circle(p.call(x, 46), 3.4 * u, INK)
	ci.draw_arc(p.call(50, 54), 9 * u, 0.4, PI - 0.4, 10, INK, 3 * u)
	match look:
		"chef_hat":
			ci.draw_rect(Rect2(p.call(32, 6), Vector2(36, 18) * u), WHITE)
			ci.draw_circle(p.call(40, 8), 10 * u, WHITE)
			ci.draw_circle(p.call(60, 8), 10 * u, WHITE)
			ci.draw_rect(Rect2(p.call(28, 22), Vector2(44, 6) * u), WHITE)
		"flat_cap":
			ci.draw_rect(Rect2(p.call(26, 20), Vector2(48, 10) * u), Color("6b5a44"))
			ci.draw_rect(Rect2(p.call(50, 26), Vector2(26, 5) * u), Color("5a4a36"))
		"straw_hat":
			ci.draw_rect(Rect2(p.call(12, 24), Vector2(76, 6) * u), Color("e6c35a"))
			ci.draw_rect(Rect2(p.call(32, 12), Vector2(36, 14) * u), Color("e6c35a"))
			ci.draw_rect(Rect2(p.call(32, 22), Vector2(36, 4) * u), RED)
		"goggles":
			for x: float in [40, 60]:
				ci.draw_circle(p.call(x, 26), 7 * u, SKY.lightened(0.3))
			ci.draw_line(p.call(26, 26), p.call(74, 26), INK, 3 * u)
		"hard_hat":
			ci.draw_arc(p.call(50, 30), 24 * u, PI, TAU, 16, YELLOW, 14 * u)
			ci.draw_rect(Rect2(p.call(20, 28), Vector2(60, 6) * u), YELLOW.darkened(0.1))
		"glasses":
			for x: float in [41, 59]:
				ci.draw_arc(p.call(x, 46), 7 * u, 0, TAU, 14, INK, 2.5 * u)
			ci.draw_line(p.call(48, 46), p.call(52, 46), INK, 2.5 * u)
		"beard":
			ci.draw_colored_polygon(PackedVector2Array([p.call(30, 54), p.call(70, 54), p.call(62, 76), p.call(50, 80),
				p.call(38, 76)]), Color("e8e8e8"))
			ci.draw_arc(p.call(50, 58), 6 * u, 0.4, PI - 0.4, 8, INK, 2.5 * u)
		"bow":
			ci.draw_colored_polygon(PackedVector2Array([p.call(62, 16), p.call(76, 8), p.call(76, 26)]), PINK.lightened(0.2))
			ci.draw_colored_polygon(PackedVector2Array([p.call(62, 16), p.call(48, 8), p.call(48, 26)]), PINK.lightened(0.2))
		"pencil":
			ci.draw_line(p.call(70, 24), p.call(84, 44), YELLOW, 4 * u, true)
		"explorer_hat":
			ci.draw_rect(Rect2(p.call(16, 24), Vector2(68, 6) * u), Color("c2a878"))
			ci.draw_rect(Rect2(p.call(32, 10), Vector2(36, 16) * u), Color("c2a878"))
		"headscarf":
			ci.draw_arc(p.call(50, 46), 28 * u, PI + 0.1, TAU - 0.1, 14, body.darkened(0.15), 8 * u)
		"bun":
			ci.draw_circle(p.call(50, 14), 9 * u, hair)


# --- Shapes ------------------------------------------------------------------------------------------------------------

static func _face(ci: CanvasItem, c: Vector2, r: float, skin: Color, mood: String) -> void:
	ci.draw_circle(c, r, skin)
	var e := r * 0.36
	for side: int in [-1, 1]:
		ci.draw_circle(c + Vector2(side * e, -r * 0.15), r * 0.11, INK)
	match mood:
		"smile":
			ci.draw_arc(c + Vector2(0, r * 0.18), r * 0.4, 0.4, PI - 0.4, 10, INK, maxf(r * 0.1, 1.0))
		"flat":
			ci.draw_line(c + Vector2(-r * 0.3, r * 0.38), c + Vector2(r * 0.3, r * 0.38), INK, maxf(r * 0.1, 1.0))
		"soft":
			ci.draw_arc(c + Vector2(0, r * 0.3), r * 0.25, 0.5, PI - 0.5, 8, INK, maxf(r * 0.09, 1.0))
			for side: int in [-1, 1]:
				ci.draw_line(c + Vector2(side * e - r * 0.12, -r * 0.42), c + Vector2(side * e + r * 0.12, -r * 0.42 - side * r * 0.08),
					INK, maxf(r * 0.07, 1.0))


static func _stick(ci: CanvasItem, p: Callable, u: float, head: Vector2, colour: Color) -> void:
	ci.draw_circle(p.call(head.x, head.y), 9 * u, SKIN)
	ci.draw_rect(Rect2(p.call(head.x - 8, head.y + 10), Vector2(16, 24) * u), colour)
	for side: int in [-1, 1]:
		ci.draw_line(p.call(head.x + side * 4, head.y + 34), p.call(head.x + side * 6, head.y + 48), colour.darkened(0.25), 5 * u)


static func _bubble(ci: CanvasItem, p: Callable, u: float, r: Rect2, colour: Color) -> void:
	ci.draw_rect(Rect2(p.call(r.position.x, r.position.y), r.size * u), colour)
	ci.draw_colored_polygon(PackedVector2Array([p.call(r.position.x + r.size.x * 0.2, r.end.y),
		p.call(r.position.x + r.size.x * 0.12, r.end.y + 12), p.call(r.position.x + r.size.x * 0.38, r.end.y)]), colour)


static func _book(ci: CanvasItem, p: Callable, u: float, colour: Color) -> void:
	ci.draw_rect(Rect2(p.call(18, 14), Vector2(64, 74) * u), colour)
	ci.draw_rect(Rect2(p.call(18, 14), Vector2(8, 74) * u), colour.darkened(0.25))
	ci.draw_rect(Rect2(p.call(26, 84), Vector2(56, 6) * u), PAPER)


static func _paper(ci: CanvasItem, p: Callable, u: float) -> void:
	ci.draw_rect(Rect2(p.call(18, 10), Vector2(64, 82) * u), PAPER)
	ci.draw_rect(Rect2(p.call(18, 10), Vector2(64, 82) * u), STONE, false, 3 * u)
	ci.draw_rect(Rect2(p.call(38, 6), Vector2(24, 10) * u), WOOD)


static func _calendar(ci: CanvasItem, p: Callable, u: float, ticks: int) -> void:
	ci.draw_rect(Rect2(p.call(12, 18), Vector2(76, 70) * u), WHITE)
	ci.draw_rect(Rect2(p.call(12, 18), Vector2(76, 16) * u), RED)
	for i in 6:
		var at := Vector2(24 + (i % 3) * 24, 48 + (i / 3) * 22)
		if i < ticks:
			_tick(ci, p, u, at, 0.4, GOOD)
		else:
			ci.draw_rect(Rect2(p.call(at.x - 6, at.y - 6), Vector2(12, 12) * u), STONE.lightened(0.3))


static func _pot(ci: CanvasItem, p: Callable, u: float) -> void:
	ci.draw_colored_polygon(PackedVector2Array([p.call(28, 62), p.call(72, 62), p.call(66, 92), p.call(34, 92)]), Color("c0563a"))
	ci.draw_rect(Rect2(p.call(24, 58), Vector2(52, 8) * u), Color("a8452c"))


## A sprout with `leaves` pairs of leaves.
static func _sprout(ci: CanvasItem, p: Callable, u: float, leaves: int) -> void:
	ci.draw_line(p.call(50, 60), p.call(50, 60 - 12 * leaves - 6), LEAF, 4 * u)
	for i in leaves:
		var y := 52.0 - i * 12.0
		ci.draw_circle(p.call(40, y), 7 * u, LEAF.lightened(0.15))
		ci.draw_circle(p.call(60, y - 4), 7 * u, LEAF.lightened(0.15))


static func _clock_face(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c, r, WHITE)
	ci.draw_arc(c, r, 0, TAU, 20, INK, maxf(r * 0.15, 1.0))
	ci.draw_line(c, c + Vector2(0, -r * 0.65), INK, maxf(r * 0.12, 1.0))
	ci.draw_line(c, c + Vector2(r * 0.5, 0), INK, maxf(r * 0.12, 1.0))


static func _tick(ci: CanvasItem, p: Callable, u: float, at: Vector2, k: float, colour: Color) -> void:
	ci.draw_polyline(PackedVector2Array([p.call(at.x - 14 * k, at.y), p.call(at.x - 4 * k, at.y + 10 * k),
		p.call(at.x + 16 * k, at.y - 12 * k)]), colour, maxf(8 * k, 2.5) * u, true)


static func _star(ci: CanvasItem, c: Vector2, r: float, colour: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + i * PI / 5
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	ci.draw_colored_polygon(pts, colour)


static func _heart(ci: CanvasItem, c: Vector2, r: float, colour: Color) -> void:
	ci.draw_circle(c + Vector2(-r * 0.5, -r * 0.2), r * 0.55, colour)
	ci.draw_circle(c + Vector2(r * 0.5, -r * 0.2), r * 0.55, colour)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 1.02, 0), c + Vector2(r * 1.02, 0), c + Vector2(0, r * 1.05)]),
		colour)


static func _drop(ci: CanvasItem, at: Vector2, r: float, colour: Color) -> void:
	ci.draw_circle(at, r, colour)
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-r, 0), at + Vector2(r, 0), at + Vector2(0, -r * 2.2)]), colour)
