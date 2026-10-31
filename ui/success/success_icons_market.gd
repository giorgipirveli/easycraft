class_name SuccessIconsMarket
extends RefCounted
## Owner #115 (S3; docs/design/life-skills.md §10: "heard, not read", every line with a picture): the pictures of My
## Business's shop and the Market Square, drawn in code like Life's and Success S2's (SuccessIcons asks here for a name it
## doesn't draw: the hook is SuccessIcons.has / paint). The goods (bread's friends: the cake and the honey bun; wheat,
## flour, honey), the shop (its front, an honest sign, a blank one, a too-big claim, kind service, the wage, the ledger
## and its bars), the market (the Price Board, prices up, down and the same, the seasons and the market's days, many
## stalls, a fair swap, the shed, the baskets, a storm) and the dice lesson (the dice, the chart going down), and the "no"
## pictures (a fake review, an untrue word) in the calm soft grey-blue. Simple shapes, soft colours.

const NAMES: Array[String] = [
	# the places and the Tool Book
	"shop", "price_board", "ledger", "bars",
	# the goods
	"cake", "honey_bun", "wheat", "flour", "honey",
	# the shop
	"shop_sign", "blank_sign", "fake_claim", "kind_service", "fake_review", "fib", "wage",
	# the market
	"price_up", "price_down", "price_same", "season_spring", "dry_field", "harvest", "snowflake", "festival", "many_stalls",
	"swap", "shed", "baskets", "storm",
	# the dice lesson
	"dice", "chart_down"]

const RED := Color("e8544e")
const BLUE := Color("3a7be8")
const YELLOW := Color("ffc93c")
const GOLD := Color("e8b04a")
const CREAM := Color("f3d2a8")
const PINK := Color("f39ac0")
const GREEN := Color("4fbf6a")
const LEAF := Color("4f9a3e")
const WOOD := Color("a8642a")
const DARK_WOOD := Color("6b4a2a")
const BREAD := Color("d99a4e")
const STONE := Color("9aa7b5")
const PAPER := Color("fdf6e3")
const INK := Color("1f2a4a")
const WHITE := Color("fdfdf8")
const SKY := Color("7ad3ff")
const SOFT_NO := Color("8a9bb8")
const SKIN := Color("f2c79b")


static func has(name: String) -> bool:
	return NAMES.has(name)


## Draws `name` with `p` (0..100 coordinates to the canvas) and `u` (one unit); false for a name not drawn here.
static func paint(ci: CanvasItem, name: String, p: Callable, u: float) -> bool:
	match name:
		"shop":
			ci.draw_rect(Rect2(p.call(14, 40), Vector2(72, 52) * u), Color("fbefd8"))
			for i in 6:
				ci.draw_rect(Rect2(p.call(10 + i * 13.3, 26), Vector2(13.3, 16) * u), RED if i % 2 == 0 else WHITE)
			ci.draw_rect(Rect2(p.call(22, 54), Vector2(30, 24) * u), Color("cfe7ff"))
			_loaf(ci, p, u, Vector2(37, 66), 0.7)
			ci.draw_rect(Rect2(p.call(60, 54), Vector2(18, 38) * u), WOOD)
			ci.draw_rect(Rect2(p.call(30, 12), Vector2(40, 12) * u), DARK_WOOD)
		"price_board":
			ci.draw_rect(Rect2(p.call(10, 14), Vector2(80, 66) * u), Color("2f4a3d"))
			for i in 3:
				var y := 28.0 + i * 18.0
				ci.draw_line(p.call(18, y), p.call(48, y), WHITE, 4 * u)
				ci.draw_circle(p.call(60, y), 4 * u, YELLOW)
				if i == 0:
					_arrow(ci, p, u, Vector2(76, y + 6), -1, GREEN, 0.5)
				elif i == 1:
					_arrow(ci, p, u, Vector2(76, y - 6), 1, BLUE, 0.5)
			ci.draw_rect(Rect2(p.call(20, 80), Vector2(5, 14) * u), DARK_WOOD)
			ci.draw_rect(Rect2(p.call(75, 80), Vector2(5, 14) * u), DARK_WOOD)
		"ledger":
			ci.draw_rect(Rect2(p.call(12, 18), Vector2(76, 66) * u), PAPER)
			ci.draw_line(p.call(50, 18), p.call(50, 84), INK.lightened(0.4), 3 * u)
			for i in 3:
				ci.draw_line(p.call(18, 32 + i * 14), p.call(44, 32 + i * 14), GREEN, 5 * u)
				ci.draw_line(p.call(56, 32 + i * 14), p.call(78 - i * 8, 32 + i * 14), RED, 5 * u)
			ci.draw_line(p.call(18, 76), p.call(82, 76), GOLD, 6 * u)
		"bars":
			ci.draw_line(p.call(12, 84), p.call(90, 84), INK, 4 * u)
			var hs: Array[float] = [26.0, 44.0, 34.0, 60.0]
			for i in 4:
				ci.draw_rect(Rect2(p.call(18 + i * 18, 84 - hs[i]), Vector2(12, hs[i]) * u), BLUE if i != 3 else GOLD)
		"cake":
			ci.draw_rect(Rect2(p.call(18, 50), Vector2(64, 32) * u), CREAM)
			ci.draw_rect(Rect2(p.call(18, 62), Vector2(64, 6) * u), PINK)
			ci.draw_rect(Rect2(p.call(16, 44), Vector2(68, 10) * u), WHITE)
			ci.draw_circle(p.call(50, 36), 7 * u, RED)
			ci.draw_line(p.call(50, 30), p.call(56, 22), LEAF, 3 * u)
		"honey_bun":
			ci.draw_circle(p.call(50, 58), 32 * u, GOLD)
			ci.draw_arc(p.call(50, 58), 18 * u, 0.0, TAU * 0.85, 24, Color("c98d3a"), 5 * u)
			ci.draw_circle(p.call(50, 58), 5 * u, Color("c98d3a"))
			_drop(ci, p.call(76, 82), 5 * u, YELLOW)
		"wheat":
			for x: float in [36.0, 50.0, 64.0]:
				ci.draw_line(p.call(x, 92), p.call(x + (x - 50) * 0.3, 36), LEAF, 3.5 * u)
				for k in 4:
					var y := 30.0 + k * 9.0
					var cx := x + (x - 50) * 0.3
					ci.draw_circle(p.call(cx - 4, y), 4 * u, YELLOW)
					ci.draw_circle(p.call(cx + 4, y + 3), 4 * u, YELLOW)
		"flour":
			ci.draw_colored_polygon(PackedVector2Array([p.call(26, 28), p.call(74, 28), p.call(84, 90), p.call(16, 90)]), WHITE)
			ci.draw_polyline(PackedVector2Array([p.call(26, 28), p.call(74, 28), p.call(84, 90), p.call(16, 90), p.call(26, 28)]),
				STONE, 2.5 * u, true)
			ci.draw_line(p.call(30, 22), p.call(70, 22), STONE, 6 * u)
			_wheat_mark(ci, p, u)
		"honey":
			ci.draw_rect(Rect2(p.call(26, 30), Vector2(48, 60) * u), GOLD)
			ci.draw_rect(Rect2(p.call(22, 20), Vector2(56, 12) * u), WOOD)
			ci.draw_rect(Rect2(p.call(32, 50), Vector2(36, 20) * u), PAPER)
			ci.draw_circle(p.call(50, 60), 5 * u, GOLD.darkened(0.2))
			_drop(ci, p.call(30, 34), 5 * u, YELLOW)
		"shop_sign":
			_signboard(ci, p, u)
			_loaf(ci, p, u, Vector2(32, 38), 0.6)
			ci.draw_circle(p.call(52, 38), 9 * u, CREAM)
			ci.draw_line(p.call(64, 34), p.call(80, 34), INK, 4 * u)
			ci.draw_line(p.call(64, 44), p.call(76, 44), INK, 4 * u)
		"blank_sign":
			_signboard(ci, p, u)
		"fake_claim":
			_signboard(ci, p, u)
			_star(ci, p.call(36, 38), 12 * u, YELLOW)
			ci.draw_line(p.call(56, 26), p.call(56, 42), RED, 5 * u)
			ci.draw_circle(p.call(56, 50), 3 * u, RED)
			ci.draw_arc(p.call(74, 33), 7 * u, PI, TAU * 1.15, 12, INK, 4 * u)
			ci.draw_line(p.call(76, 40), p.call(74, 46), INK, 4 * u)
			ci.draw_circle(p.call(74, 52), 2.5 * u, INK)
		"kind_service":
			ci.draw_circle(p.call(36, 42), 20 * u, SKIN)
			ci.draw_arc(p.call(36, 46), 10 * u, 0.3, PI - 0.3, 12, INK, 3 * u)
			ci.draw_circle(p.call(30, 38), 2.5 * u, INK)
			ci.draw_circle(p.call(42, 38), 2.5 * u, INK)
			_loaf(ci, p, u, Vector2(70, 66), 0.8)
			_heart(ci, p.call(72, 28), 10 * u, RED)
		"fake_review":
			ci.draw_rect(Rect2(p.call(12, 26), Vector2(76, 48) * u), PAPER)
			for i in 5:
				_star(ci, p.call(22 + i * 14, 50), 6 * u, YELLOW)
			ci.draw_line(p.call(16, 22), p.call(84, 78), SOFT_NO, 8 * u, true)
			ci.draw_line(p.call(84, 22), p.call(16, 78), SOFT_NO, 8 * u, true)
		"fib":
			ci.draw_rect(Rect2(p.call(12, 20), Vector2(70, 46) * u), WHITE)
			ci.draw_colored_polygon(PackedVector2Array([p.call(26, 66), p.call(40, 66), p.call(24, 82)]), WHITE)
			ci.draw_polyline(PackedVector2Array([p.call(22, 44), p.call(32, 34), p.call(42, 50), p.call(52, 34), p.call(62, 50),
				p.call(72, 38)]), STONE, 4 * u, true)
			ci.draw_line(p.call(14, 22), p.call(80, 64), SOFT_NO, 7 * u, true)
		"wage":
			for i in 3:
				ci.draw_circle(p.call(30 + i * 4, 76 - i * 8), 16 * u, YELLOW.darkened(i * 0.05))
			ci.draw_circle(p.call(68, 38), 22 * u, WHITE)
			ci.draw_arc(p.call(68, 38), 22 * u, 0.0, TAU, 28, INK, 3 * u)
			ci.draw_line(p.call(68, 38), p.call(68, 24), INK, 4 * u)
			ci.draw_line(p.call(68, 38), p.call(78, 42), INK, 4 * u)
		"price_up", "price_down", "price_same":
			_tag(ci, p, u)
			if name == "price_up":
				_arrow(ci, p, u, Vector2(72, 40), -1, GREEN, 1.0)
			elif name == "price_down":
				_arrow(ci, p, u, Vector2(72, 66), 1, BLUE, 1.0)
			else:
				ci.draw_line(p.call(62, 48), p.call(88, 48), STONE, 6 * u)
				ci.draw_line(p.call(62, 60), p.call(88, 60), STONE, 6 * u)
		"season_spring":
			ci.draw_line(p.call(40, 92), p.call(40, 48), LEAF, 4 * u)
			for k in 5:
				var a := TAU * k / 5.0
				ci.draw_circle(p.call(40 + cos(a) * 12, 40 + sin(a) * 12), 9 * u, PINK)
			ci.draw_circle(p.call(40, 40), 7 * u, YELLOW)
			ci.draw_circle(p.call(74, 26), 8 * u, YELLOW)
			ci.draw_line(p.call(70, 22), p.call(70, 30), INK, 3 * u)
			ci.draw_line(p.call(77, 22), p.call(77, 30), INK, 3 * u)
			ci.draw_circle(p.call(80, 18), 5 * u, Color(1, 1, 1, 0.8))
		"dry_field":
			ci.draw_circle(p.call(76, 22), 14 * u, YELLOW)
			ci.draw_rect(Rect2(p.call(6, 66), Vector2(88, 26) * u), Color("c9a063"))
			ci.draw_polyline(PackedVector2Array([p.call(20, 72), p.call(28, 80), p.call(24, 88)]), DARK_WOOD, 2.5 * u, true)
			ci.draw_polyline(PackedVector2Array([p.call(60, 70), p.call(54, 80), p.call(62, 88)]), DARK_WOOD, 2.5 * u, true)
			for x: float in [16.0, 34.0, 46.0, 72.0, 84.0]:
				ci.draw_line(p.call(x, 66), p.call(x + 2, 54), Color("b89a5a"), 3 * u)
		"harvest":
			for x: float in [30.0, 40.0, 50.0]:
				ci.draw_line(p.call(x, 90), p.call(40, 40), YELLOW.darkened(0.15), 4 * u)
			ci.draw_line(p.call(30, 64), p.call(50, 64), DARK_WOOD, 4 * u)
			for k in 3:
				ci.draw_circle(p.call(34 + k * 6, 34 - (k % 2) * 4), 6 * u, YELLOW)
			ci.draw_circle(p.call(68, 72), 12 * u, RED)
			ci.draw_circle(p.call(82, 80), 10 * u, RED.darkened(0.1))
			ci.draw_line(p.call(68, 60), p.call(70, 54), LEAF, 3 * u)
		"snowflake":
			for k in 3:
				var a := PI * k / 3.0
				ci.draw_line(p.call(50 - cos(a) * 36, 50 - sin(a) * 36), p.call(50 + cos(a) * 36, 50 + sin(a) * 36), SKY.darkened(0.1),
					5 * u, true)
			for k in 6:
				var a := TAU * k / 6.0
				ci.draw_circle(p.call(50 + cos(a) * 30, 50 + sin(a) * 30), 4 * u, WHITE)
			ci.draw_circle(p.call(50, 50), 6 * u, WHITE)
		"festival":
			ci.draw_line(p.call(6, 18), p.call(94, 26), DARK_WOOD, 2.5 * u)
			var cols: Array[Color] = [RED, YELLOW, BLUE, GREEN, PINK]
			for i in 5:
				var x := 12.0 + i * 17.0
				var y := 19.0 + i * 1.6
				ci.draw_colored_polygon(PackedVector2Array([p.call(x, y), p.call(x + 12, y + 1), p.call(x + 6, y + 16)]), cols[i])
			ci.draw_rect(Rect2(p.call(28, 60), Vector2(44, 26) * u), CREAM)
			ci.draw_rect(Rect2(p.call(26, 54), Vector2(48, 8) * u), WHITE)
			ci.draw_circle(p.call(50, 48), 5 * u, RED)
		"many_stalls":
			for i in 4:
				var x := 6.0 + i * 23.0
				ci.draw_rect(Rect2(p.call(x, 50), Vector2(19, 30) * u), WOOD)
				ci.draw_rect(Rect2(p.call(x - 1, 40), Vector2(21, 10) * u), RED if i % 2 == 0 else BLUE)
				ci.draw_circle(p.call(x + 9.5, 46), 4 * u, RED.lightened(0.2))
		"swap":
			ci.draw_circle(p.call(28, 50), 15 * u, RED)
			ci.draw_line(p.call(28, 35), p.call(30, 28), LEAF, 3 * u)
			ci.draw_circle(p.call(72, 54), 13 * u, Color("b8d65a"))
			ci.draw_circle(p.call(72, 40), 9 * u, Color("b8d65a"))
			ci.draw_arc(p.call(50, 50), 34 * u, PI * 1.15, PI * 1.85, 14, INK, 4 * u)
			ci.draw_arc(p.call(50, 50), 34 * u, PI * 0.15, PI * 0.85, 14, INK, 4 * u)
			ci.draw_colored_polygon(PackedVector2Array([p.call(76, 18), p.call(84, 26), p.call(72, 28)]), INK)
			ci.draw_colored_polygon(PackedVector2Array([p.call(24, 82), p.call(16, 74), p.call(28, 72)]), INK)
		"shed":
			ci.draw_rect(Rect2(p.call(16, 40), Vector2(68, 50) * u), WOOD)
			ci.draw_colored_polygon(PackedVector2Array([p.call(10, 42), p.call(50, 14), p.call(90, 42)]), DARK_WOOD)
			ci.draw_rect(Rect2(p.call(40, 56), Vector2(22, 34) * u), DARK_WOOD.darkened(0.3))
			for i in 2:
				ci.draw_rect(Rect2(p.call(20 + i * 50, 66), Vector2(14, 22) * u), Color("e8d39a"))
		"baskets":
			var fills: Array[Color] = [YELLOW, RED, GOLD]
			for i in 3:
				var x := 8.0 + i * 30.0
				ci.draw_circle(p.call(x + 12, 52), 9 * u, fills[i])
				ci.draw_rect(Rect2(p.call(x, 56), Vector2(24, 24) * u), Color("c9a063"))
				ci.draw_line(p.call(x, 64), p.call(x + 24, 64), WOOD, 2 * u)
		"storm":
			ci.draw_circle(p.call(36, 34), 18 * u, STONE)
			ci.draw_circle(p.call(58, 30), 22 * u, STONE.darkened(0.1))
			ci.draw_circle(p.call(76, 40), 14 * u, STONE)
			ci.draw_rect(Rect2(p.call(22, 38), Vector2(62, 16) * u), STONE.darkened(0.05))
			for i in 5:
				ci.draw_line(p.call(26 + i * 12, 62), p.call(22 + i * 12, 80), SKY, 3 * u, true)
		"dice":
			ci.draw_rect(Rect2(p.call(18, 18), Vector2(64, 64) * u), WHITE)
			ci.draw_rect(Rect2(p.call(18, 18), Vector2(64, 64) * u), INK, false, 3 * u)
			for row in 3:
				for col: float in [35.0, 65.0]:
					ci.draw_circle(p.call(col, 32 + row * 18), 6 * u, INK)
		"chart_down":
			ci.draw_line(p.call(12, 14), p.call(12, 88), INK, 3 * u)
			ci.draw_line(p.call(12, 30), p.call(92, 30), STONE, 2 * u)
			ci.draw_polyline(PackedVector2Array([p.call(14, 30), p.call(26, 36), p.call(34, 32), p.call(46, 48), p.call(56, 44),
				p.call(68, 62), p.call(78, 60), p.call(86, 74)]), RED, 4 * u, true)
			ci.draw_colored_polygon(PackedVector2Array([p.call(80, 80), p.call(92, 78), p.call(88, 66)]), RED)
		_:
			return false
	return true


static func _loaf(ci: CanvasItem, p: Callable, u: float, c: Vector2, k: float) -> void:
	ci.draw_circle(p.call(c.x, c.y), 14 * k * u, BREAD)
	ci.draw_rect(Rect2(p.call(c.x - 14 * k, c.y), Vector2(28 * k, 10 * k) * u), BREAD)
	for i in 3:
		ci.draw_line(p.call(c.x - 7 * k + i * 7 * k, c.y - 8 * k), p.call(c.x - 4 * k + i * 7 * k, c.y + 2 * k), BREAD.darkened(0.25),
			2 * u)


static func _signboard(ci: CanvasItem, p: Callable, u: float) -> void:
	ci.draw_rect(Rect2(p.call(26, 58), Vector2(6, 36) * u), DARK_WOOD)
	ci.draw_rect(Rect2(p.call(68, 58), Vector2(6, 36) * u), DARK_WOOD)
	ci.draw_rect(Rect2(p.call(12, 18), Vector2(76, 42) * u), PAPER)
	ci.draw_rect(Rect2(p.call(12, 18), Vector2(76, 42) * u), WOOD, false, 4 * u)


static func _tag(ci: CanvasItem, p: Callable, u: float) -> void:
	ci.draw_colored_polygon(PackedVector2Array([p.call(8, 54), p.call(24, 34), p.call(56, 34), p.call(56, 74), p.call(24, 74)]),
		YELLOW)
	ci.draw_circle(p.call(22, 54), 4 * u, WHITE)
	ci.draw_line(p.call(32, 48), p.call(48, 48), INK, 4 * u)
	ci.draw_line(p.call(32, 60), p.call(44, 60), INK, 4 * u)


## An arrow at `c`: dir -1 points up, 1 points down.
static func _arrow(ci: CanvasItem, p: Callable, u: float, c: Vector2, dir: int, colour: Color, k: float) -> void:
	ci.draw_line(p.call(c.x, c.y), p.call(c.x, c.y + dir * -22 * k), colour, 7 * k * u)
	var tip := c.y + dir * -30 * k
	ci.draw_colored_polygon(PackedVector2Array([p.call(c.x - 12 * k, c.y + dir * -18 * k), p.call(c.x + 12 * k, c.y + dir * -18 * k),
		p.call(c.x, tip)]), colour)


static func _wheat_mark(ci: CanvasItem, p: Callable, u: float) -> void:
	ci.draw_line(p.call(50, 80), p.call(50, 48), YELLOW.darkened(0.2), 3 * u)
	for k in 3:
		ci.draw_circle(p.call(46, 50 + k * 8), 3.5 * u, YELLOW.darkened(0.1))
		ci.draw_circle(p.call(54, 54 + k * 8), 3.5 * u, YELLOW.darkened(0.1))


static func _star(ci: CanvasItem, c: Vector2, r: float, colour: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + PI * i / 5.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(pts, colour)


static func _heart(ci: CanvasItem, c: Vector2, r: float, colour: Color) -> void:
	ci.draw_circle(c + Vector2(-r * 0.5, -r * 0.2), r * 0.55, colour)
	ci.draw_circle(c + Vector2(r * 0.5, -r * 0.2), r * 0.55, colour)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 1.02, 0), c + Vector2(r * 1.02, 0), c + Vector2(0, r * 1.05)]),
		colour)


static func _drop(ci: CanvasItem, at: Vector2, r: float, colour: Color) -> void:
	ci.draw_circle(at, r, colour)
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-r, 0), at + Vector2(r, 0), at + Vector2(0, -r * 2.2)]), colour)
