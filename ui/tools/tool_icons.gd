class_name ToolIcons
extends Control
## Owner #117 (docs/design/life-skills.md §13, "The Tool Book"): every tool's picture, drawn in code (no assets), big and
## plain like Life's pictures (LifeIcons): for the flat tool tray and the Tool Book. ToolBook.icon(id) names one; a
## motion's own picture ("motion_strike" ...) stands in for a tool without one.

const NAMES: Array[String] = ["trowel", "level", "plumb", "tape", "square", "hammer", "saw", "shovel", "bucket", "brush",
	"mixer", "drill", "hard_hat", "goggles", "gloves", "screwdriver", "spanner", "pliers", "knife", "jug", "whisk", "scales",
	"tap", "broom", "scissors", "cloth", "extinguisher", "coins", "phone", "camera", "thermometer", "magnifier", "pump",
	"compass", "device", "tool", "safety"]
## A motion's picture is its best-known tool's.
const MOTION_PICTURES := {"strike": "hammer", "stroke": "saw", "twist": "screwdriver", "squeeze": "pliers",
	"press": "device", "spread": "trowel", "measure": "tape", "pour": "jug", "aim": "level", "cut": "scissors"}
const INK := Color("1f2a4a")
const STEEL := Color("a9b3bf")
const WOOD := Color("b07a45")
const YELLOW := Color("f2c230")
const ORANGE := Color("f08a1c")
const RED := Color("d9473b")
const BLUE := Color("3a7be8")
const GREEN := Color("2fae4e")
const WHITE := Color("f4f4f0")

var icon := "tool"
var px := 96.0


## Owner #118 (Life L3b): a name only Life's pictures draw (LifeIcons: the life jacket, the CO alarm, the fuse box, the
## trainer pen...) is drawn by them, so the Tool Book shows every Life tool with its own picture.
static func has(name: String) -> bool:
	return NAMES.has(name) or (name.begins_with("motion_") and MOTION_PICTURES.has(name.substr(7))) or LifeIcons.has(name)


## The drawing for a name (a motion's tool for "motion_*", "tool" for an unknown one).
static func resolve(name: String) -> String:
	if name.begins_with("motion_"):
		return str(MOTION_PICTURES.get(name.substr(7), "tool"))
	return name if NAMES.has(name) or LifeIcons.has(name) else "tool"


func _init(name_: String = "tool", size_px: float = 96.0) -> void:
	icon = resolve(name_)
	px = size_px
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not NAMES.has(icon) and LifeIcons.has(icon):   # Life L3b: Life's own picture, the same size
		var life := LifeIcons.new(icon, px)
		life.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(life)


func _draw() -> void:
	if not NAMES.has(icon) and LifeIcons.has(icon):
		return   # Life L3b: Life's own picture (the child) draws it
	var s := px / 100.0
	var c := Vector2(px, px) * 0.5
	match icon:
		"trowel":
			_poly([Vector2(20, 70), Vector2(62, 28), Vector2(80, 46), Vector2(38, 88)], s, STEEL)
			_bar(Vector2(62, 28), Vector2(78, 12), 8, s, WOOD)
		"level":
			draw_rect(Rect2(Vector2(8, 40) * s, Vector2(84, 20) * s), YELLOW)
			draw_rect(Rect2(Vector2(42, 44) * s, Vector2(16, 12) * s), GREEN.lightened(0.3))
			draw_circle(Vector2(50, 50) * s, 4 * s, WHITE)
		"plumb":
			draw_rect(Rect2(Vector2(42, 8) * s, Vector2(16, 12) * s), ORANGE)
			_bar(Vector2(50, 20), Vector2(50, 70), 2, s, INK)
			_poly([Vector2(40, 70), Vector2(60, 70), Vector2(50, 92)], s, STEEL)
		"tape":
			draw_rect(Rect2(Vector2(12, 30) * s, Vector2(40, 40) * s), YELLOW)
			draw_circle(Vector2(32, 50) * s, 10 * s, INK)
			draw_rect(Rect2(Vector2(52, 58) * s, Vector2(40, 8) * s), YELLOW.lightened(0.35))
			for i in 4:
				_bar(Vector2(58 + i * 9, 58), Vector2(58 + i * 9, 62), 1.5, s, INK)
		"square":
			draw_rect(Rect2(Vector2(20, 14) * s, Vector2(10, 72) * s), STEEL)
			draw_rect(Rect2(Vector2(20, 76) * s, Vector2(62, 10) * s), STEEL)
		"hammer":
			_bar(Vector2(30, 88), Vector2(56, 34), 9, s, WOOD)
			_poly([Vector2(34, 22), Vector2(76, 16), Vector2(80, 32), Vector2(40, 40)], s, INK)
		"saw":
			_poly([Vector2(14, 40), Vector2(80, 30), Vector2(80, 62), Vector2(14, 58)], s, STEEL)
			for i in 7:
				_poly([Vector2(16 + i * 9, 58), Vector2(21 + i * 9, 58), Vector2(18 + i * 9, 64)], s, STEEL.darkened(0.2))
			draw_rect(Rect2(Vector2(78, 28) * s, Vector2(16, 36) * s), RED)
		"shovel":
			_bar(Vector2(50, 8), Vector2(50, 60), 6, s, WOOD)
			_poly([Vector2(32, 60), Vector2(68, 60), Vector2(64, 86), Vector2(50, 94), Vector2(36, 86)], s, INK.lightened(0.2))
		"bucket":
			_poly([Vector2(22, 30), Vector2(78, 30), Vector2(70, 88), Vector2(30, 88)], s, BLUE)
			draw_arc(Vector2(50, 30) * s, 28 * s, PI, TAU, 16, INK, 3 * s)
		"brush":
			_bar(Vector2(50, 8), Vector2(50, 52), 8, s, WOOD)
			draw_rect(Rect2(Vector2(34, 52) * s, Vector2(32, 10) * s), STEEL)
			draw_rect(Rect2(Vector2(32, 62) * s, Vector2(36, 28) * s), YELLOW.darkened(0.2))
		"mixer":
			draw_rect(Rect2(Vector2(30, 66) * s, Vector2(40, 24) * s), RED)
			draw_circle(Vector2(50, 46) * s, 26 * s, ORANGE)
			draw_circle(Vector2(50, 40) * s, 10 * s, INK.lightened(0.3))
		"drill":
			draw_rect(Rect2(Vector2(20, 30) * s, Vector2(50, 22) * s), GREEN)
			draw_rect(Rect2(Vector2(36, 52) * s, Vector2(16, 34) * s), INK)
			_bar(Vector2(70, 41), Vector2(92, 41), 4, s, STEEL)
		"hard_hat", "safety":
			draw_circle(Vector2(50, 58) * s, 32 * s, YELLOW)
			draw_rect(Rect2(Vector2(10, 58) * s, Vector2(80, 30) * s), Color(0, 0, 0, 0))
			draw_rect(Rect2(Vector2(10, 58) * s, Vector2(80, 10) * s), YELLOW.darkened(0.15))
		"goggles":
			draw_rect(Rect2(Vector2(8, 46) * s, Vector2(84, 6) * s), INK)
			draw_circle(Vector2(34, 50) * s, 15 * s, Color(0.7, 0.88, 1.0))
			draw_circle(Vector2(66, 50) * s, 15 * s, Color(0.7, 0.88, 1.0))
		"gloves":
			_poly([Vector2(26, 90), Vector2(26, 40), Vector2(34, 22), Vector2(46, 22), Vector2(50, 40), Vector2(62, 34),
				Vector2(66, 44), Vector2(56, 60), Vector2(56, 90)], s, ORANGE)
		"screwdriver":
			_bar(Vector2(22, 78), Vector2(46, 54), 14, s, RED)
			_bar(Vector2(46, 54), Vector2(84, 16), 4, s, STEEL)
		"spanner":
			_bar(Vector2(24, 76), Vector2(70, 30), 9, s, STEEL)
			draw_circle(Vector2(74, 26) * s, 14 * s, STEEL)
			draw_circle(Vector2(80, 20) * s, 7 * s, Color(0, 0, 0, 0))
		"pliers":
			_bar(Vector2(30, 90), Vector2(48, 46), 8, s, RED)
			_bar(Vector2(70, 90), Vector2(52, 46), 8, s, RED)
			_poly([Vector2(42, 46), Vector2(58, 46), Vector2(54, 10), Vector2(46, 10)], s, STEEL)
		"knife":
			_poly([Vector2(20, 60), Vector2(70, 34), Vector2(76, 40), Vector2(30, 68)], s, STEEL)
			_bar(Vector2(72, 36), Vector2(92, 26), 9, s, BLUE)
		"jug":
			_poly([Vector2(26, 22), Vector2(70, 22), Vector2(66, 88), Vector2(30, 88)], s, WHITE)
			_poly([Vector2(26, 22), Vector2(14, 16), Vector2(26, 34)], s, WHITE)
			for i in 3:
				_bar(Vector2(32, 40 + i * 14), Vector2(44, 40 + i * 14), 2, s, BLUE)
		"whisk":
			_bar(Vector2(50, 90), Vector2(50, 56), 7, s, WOOD)
			for i in 3:
				draw_arc(Vector2(50, 34) * s, (8 + i * 6) * s, 0, TAU, 20, STEEL, 2.5 * s)
		"scales":
			draw_rect(Rect2(Vector2(20, 60) * s, Vector2(60, 26) * s), WHITE)
			draw_rect(Rect2(Vector2(30, 66) * s, Vector2(40, 12) * s), INK)
			_poly([Vector2(14, 56), Vector2(86, 56), Vector2(76, 46), Vector2(24, 46)], s, STEEL)
		"tap":
			draw_rect(Rect2(Vector2(20, 30) * s, Vector2(50, 14) * s), STEEL)
			draw_rect(Rect2(Vector2(56, 44) * s, Vector2(14, 22) * s), STEEL)
			draw_rect(Rect2(Vector2(30, 18) * s, Vector2(24, 8) * s), BLUE)
			draw_circle(Vector2(63, 78) * s, 5 * s, BLUE.lightened(0.3))
		"broom":
			_bar(Vector2(50, 8), Vector2(50, 60), 6, s, WOOD)
			_poly([Vector2(30, 60), Vector2(70, 60), Vector2(80, 92), Vector2(20, 92)], s, YELLOW.darkened(0.3))
		"scissors":
			draw_arc(Vector2(30, 74) * s, 12 * s, 0, TAU, 20, RED, 5 * s)
			draw_arc(Vector2(62, 74) * s, 12 * s, 0, TAU, 20, RED, 5 * s)
			_bar(Vector2(36, 64), Vector2(66, 14), 4, s, STEEL)
			_bar(Vector2(56, 64), Vector2(30, 14), 4, s, STEEL)
		"cloth":
			_poly([Vector2(18, 30), Vector2(82, 22), Vector2(78, 80), Vector2(22, 84)], s, WHITE)
			_bar(Vector2(40, 30), Vector2(40, 80), 6, s, RED.lightened(0.4))
		"extinguisher":
			draw_rect(Rect2(Vector2(34, 30) * s, Vector2(32, 60) * s), RED)
			draw_rect(Rect2(Vector2(40, 16) * s, Vector2(20, 14) * s), INK)
			_bar(Vector2(60, 20), Vector2(84, 40), 4, s, INK)
		"coins":
			for i in 3:
				draw_circle(Vector2(38 + i * 12, 70 - i * 14) * s, 18 * s, YELLOW.darkened(0.05 * i))
		"phone":
			draw_rect(Rect2(Vector2(30, 10) * s, Vector2(40, 80) * s), INK)
			draw_rect(Rect2(Vector2(35, 18) * s, Vector2(30, 56) * s), Color("9fd8ff"))
		"camera":
			draw_rect(Rect2(Vector2(14, 34) * s, Vector2(72, 46) * s), INK)
			draw_circle(Vector2(50, 57) * s, 15 * s, STEEL)
			draw_circle(Vector2(50, 57) * s, 8 * s, BLUE)
		"thermometer":
			_bar(Vector2(50, 12), Vector2(50, 70), 10, s, WHITE)
			_bar(Vector2(50, 40), Vector2(50, 70), 5, s, RED)
			draw_circle(Vector2(50, 78) * s, 11 * s, RED)
		"magnifier":
			draw_arc(Vector2(42, 40) * s, 24 * s, 0, TAU, 28, INK, 6 * s)
			draw_circle(Vector2(42, 40) * s, 20 * s, Color(0.75, 0.9, 1.0, 0.7))
			_bar(Vector2(58, 58), Vector2(84, 86), 9, s, WOOD)
		"pump":
			draw_rect(Rect2(Vector2(40, 30) * s, Vector2(20, 60) * s), BLUE)
			_bar(Vector2(30, 22), Vector2(70, 22), 6, s, INK)
			_bar(Vector2(50, 22), Vector2(50, 30), 4, s, STEEL)
		"compass":
			draw_circle(c, 38 * s, WHITE)
			draw_arc(c, 38 * s, 0, TAU, 28, INK, 4 * s)
			_poly([Vector2(50, 16), Vector2(58, 50), Vector2(42, 50)], s, RED)
			_poly([Vector2(42, 50), Vector2(58, 50), Vector2(50, 84)], s, INK)
		"device":
			draw_rect(Rect2(Vector2(16, 20) * s, Vector2(68, 60) * s), INK.lightened(0.15))
			draw_rect(Rect2(Vector2(24, 28) * s, Vector2(52, 18) * s), Color("9fd8ff"))
			for i in 3:
				draw_circle(Vector2(32 + i * 18, 64) * s, 6 * s, [GREEN, YELLOW, RED][i])
		_:
			_bar(Vector2(24, 76), Vector2(76, 24), 10, s, STEEL)


func _poly(points: Array, s: float, colour: Color) -> void:
	var pts := PackedVector2Array()
	for p: Vector2 in points:
		pts.append(p * s)
	draw_colored_polygon(pts, colour)


func _bar(a: Vector2, b: Vector2, width: float, s: float, colour: Color) -> void:
	draw_line(a * s, b * s, colour, width * s, true)
