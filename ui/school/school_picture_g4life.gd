class_name SchoolPictureG4Life
extends RefCounted
## Grade 4 health and PE, design and technology, and projects (owner #70, #73): the picture kinds they add, drawn from
## data onto a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only, no new art; the
## font has no arrows or signs, so they are drawn). Kinds and fields:
## - circuit {parts: [PARTS] (2-6, round a loop of wire, clockwise from the top), switch? ("open" or "closed", the
##   default; only with a switch), gap? (what bridges the gap, 14 letters; only with a gap; none: an empty gap), lit?
##   (bulbs and LEDs glow, a buzzer sounds, a motor's fan spins), names? (each part's name beside it)}: a circuit drawn
##   as its real parts: a battery (a cell, + at its copper end), a bulb in its holder, a switch, a buzzer, a motor with a
##   fan, an LED, or a gap between two clips.
## - beach_flags {flags: [FLAGS] (1-4, side by side), labels?: [text] (14 letters each, one each)}: the beach safety
##   flags on their poles: red over yellow (swim between them), red (danger: never go in), black and white quarters
##   (surfboards and kayaks, no swimming) and the orange windsock (wind blowing out to sea: no inflatables).
## - food_label {rows: [[name (10 letters), amount (8), LEVELS level]] (1-5 boxes side by side), per? (16 letters,
##   default "per 100 g"), name? (the food, 24 letters)}: a front-of-pack label's traffic lights: green LOW, amber MED,
##   red HIGH, "none" a white box (no colour, as energy), "?" a grey box to work out.
## - pitch {cols (6-14), rows (4-9), players: [[x, y, "a" | "d", tag? (2 letters)]] (1-12; x 0-cols, y 0-rows, in
##   squares from the top left), ball? (the index of the player who has it), layout? (LAYOUTS: "invasion" (the default:
##   goals at both ends, a halfway line, a centre circle), "rounders" (the batting and bowling squares and four posts,
##   numbered the way the batters run) or "court" (lines only))}: a games area seen from above; "a" players (your team)
##   are blue circles, "d" players (the other team) red squares, each with its tag.
## - site_plan {rows: ["..T~", …] (1-8 rows of 1-12 SYMBOLS, all as long), grid? (letters along the bottom, numbers up
##   the side, 1 at the bottom), north? (true: a north arrow), key? (a key of the symbols shown)}: a place seen from above
##   on squares: "." open land, "~" water, "=" a bridge, "T" trees, "#" a field of crops, "H" a house, "M" a mill, "p" a
##   path, "^" a hill, "r" rocks; orienteering's purple marks: "S" the start (a triangle), "F" the finish (a double
##   circle), "1"-"9" controls (circles, numbered).
## - chassis {axles: ["square" | "crooked"] (1-3, front to back), wheels? ("same", the default, or "mixed": one wheel
##   smaller), labels? (chassis, axle, axle holder and wheel named)}: a model vehicle seen from above: the chassis, the
##   axles through their holders, a wheel at each end; a crooked axle is not at right angles to the chassis.
## - hand {labels: [text] (5, 12 letters each, thumb first)}: the helping hand: a trusted adult on each finger.

const KINDS: Array[String] = ["circuit", "beach_flags", "food_label", "pitch", "site_plan", "chassis", "hand"]
const INK := Color("1f2a4a")    # SchoolUi.INK
const PAPER := Color("fdf6e3")  # SchoolUi.PAPER

const PARTS: Array[String] = ["cell", "bulb", "switch", "buzzer", "motor", "led", "gap"]
const PART_NAMES := {"cell": "battery", "bulb": "bulb", "switch": "switch", "buzzer": "buzzer", "motor": "motor",
	"led": "LED", "gap": "gap"}
const MAX_PARTS := 6
const MAX_GAP := 14
const WIRE := Color("b03a2e")
## Where n parts sit on the loop: [edge (0 top, 1 right, 2 bottom, 3 left), how far along it (clockwise)].
const SLOTS := {2: [[0, 0.5], [2, 0.5]], 3: [[0, 0.5], [1, 0.5], [2, 0.5]], 4: [[0, 0.5], [1, 0.5], [2, 0.5], [3, 0.5]],
	5: [[0, 0.3], [0, 0.7], [1, 0.5], [2, 0.5], [3, 0.5]],
	6: [[0, 0.3], [0, 0.7], [1, 0.5], [2, 0.3], [2, 0.7], [3, 0.5]]}

const FLAGS: Array[String] = ["red_yellow", "red", "chequered", "windsock"]
const FLAG_RED := Color("e0342b")
const FLAG_YELLOW := Color("fbd02d")
const WINDSOCK := Color("f5821f")
const MAX_FLAGS := 4
const MAX_LABEL := 14

const LEVELS: Array[String] = ["low", "medium", "high", "none", "?"]
const LEVEL_COLORS := {"low": Color("78c25a"), "medium": Color("f6b638"), "high": Color("e5513d"), "none": Color.WHITE,
	"?": Color("d5d9e0")}
const LEVEL_WORDS := {"low": "LOW", "medium": "MED", "high": "HIGH", "none": "", "?": "?"}
const MAX_LABEL_ROWS := 5
const MAX_NUTRIENT := 10
const MAX_AMOUNT := 8
const MAX_PER := 16
const MAX_FOOD := 24

const LAYOUTS: Array[String] = ["invasion", "rounders", "court"]
const PITCH_COLS := Vector2i(6, 14)
const PITCH_ROWS := Vector2i(4, 9)
const MAX_PLAYERS := 12
const GRASS := Color("74b85c")
const TEAM := Color("2f6fdc")
const OTHERS := Color("dc3d2d")

const SYMBOLS: Array[String] = [".", "~", "=", "T", "#", "H", "M", "p", "^", "r", "S", "F", "1", "2", "3", "4", "5", "6",
	"7", "8", "9"]
const SYMBOL_NAMES := {".": "open land", "~": "water", "=": "bridge", "T": "trees", "#": "field", "H": "house",
	"M": "mill", "p": "path", "^": "hill", "r": "rocks", "S": "start", "F": "finish"}
const MAX_PLAN := Vector2i(12, 8)
const LAND := Color("d9ecb6")
const WATER := Color("7fb6e8")
const PURPLE := Color("b8237a")

const AXLES: Array[String] = ["square", "crooked"]
const WHEELS: Array[String] = ["same", "mixed"]
const MAX_AXLES := 3
const CROOKED := 0.26   # radians: about 15 degrees off square

const FINGERS := 5
const MAX_NAME := 12
const SKIN := Color("fbe3c8")


## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	match str(p.get("kind", "")):
		"circuit":
			var parts: Variant = p.get("parts")
			if not parts is Array or (parts as Array).size() < 2 or (parts as Array).size() > MAX_PARTS:
				return "a circuit has 2-%d parts" % MAX_PARTS
			for part: Variant in parts:
				if not PARTS.has(str(part)):
					return "a part is one of %s" % [PARTS]
			if (parts as Array).count("gap") > 1:
				return "a circuit has at most one gap"
			if p.has("switch") and (not (parts as Array).has("switch") or not str(p.switch) in ["open", "closed"]):
				return "switch is open or closed, and only with a switch"
			if p.has("gap") and (not (parts as Array).has("gap") or str(p.gap).length() < 1 or str(p.gap).length() > MAX_GAP):
				return "gap names what is in the gap in 1-%d letters, and only with a gap" % MAX_GAP
			for k: String in ["lit", "names"]:
				if p.has(k) and not p[k] is bool:
					return "%s is true or false" % k
		"beach_flags":
			return _list_problem(p, "flags", FLAGS, MAX_FLAGS, MAX_LABEL)
		"food_label":
			var rows: Variant = p.get("rows")
			if not rows is Array or (rows as Array).is_empty() or (rows as Array).size() > MAX_LABEL_ROWS:
				return "a food label has 1-%d boxes" % MAX_LABEL_ROWS
			for row: Variant in rows:
				if not row is Array or (row as Array).size() != 3:
					return "a box is [name, amount, level]"
				if str(row[0]).length() < 1 or str(row[0]).length() > MAX_NUTRIENT or str(row[1]).length() > MAX_AMOUNT:
					return "a box's name is 1-%d letters and its amount at most %d" % [MAX_NUTRIENT, MAX_AMOUNT]
				if not LEVELS.has(str(row[2])):
					return "a level is one of %s" % [LEVELS]
			if str(p.get("per", "")).length() > MAX_PER or str(p.get("name", "")).length() > MAX_FOOD:
				return "per is at most %d letters, the food's name %d" % [MAX_PER, MAX_FOOD]
		"pitch":
			var cols := int(p.get("cols", 0))
			var rows := int(p.get("rows", 0))
			if cols < PITCH_COLS.x or cols > PITCH_COLS.y or rows < PITCH_ROWS.x or rows > PITCH_ROWS.y:
				return "a pitch is %d-%d squares long and %d-%d wide" % [PITCH_COLS.x, PITCH_COLS.y, PITCH_ROWS.x,
					PITCH_ROWS.y]
			if not str(p.get("layout", "invasion")) in LAYOUTS:
				return "a layout is one of %s" % [LAYOUTS]
			var players: Variant = p.get("players")
			if not players is Array or (players as Array).is_empty() or (players as Array).size() > MAX_PLAYERS:
				return "a pitch has 1-%d players" % MAX_PLAYERS
			for pl: Variant in players:
				if not pl is Array or (pl as Array).size() < 3 or (pl as Array).size() > 4:
					return "a player is [x, y, team, tag?]"
				if typeof(pl[0]) not in [TYPE_INT, TYPE_FLOAT] or typeof(pl[1]) not in [TYPE_INT, TYPE_FLOAT] \
						or float(pl[0]) < 0 or float(pl[0]) > cols or float(pl[1]) < 0 or float(pl[1]) > rows:
					return "a player stands on the pitch: x 0-%d, y 0-%d" % [cols, rows]
				if not str(pl[2]) in ["a", "d"]:
					return "a player's team is a or d"
				if (pl as Array).size() == 4 and (str(pl[3]).length() < 1 or str(pl[3]).length() > 2):
					return "a player's tag is 1-2 letters"
			if p.has("ball") and (typeof(p.ball) not in [TYPE_INT, TYPE_FLOAT] or int(p.ball) < 0
					or int(p.ball) >= (players as Array).size()):
				return "ball is the index of a player"
		"site_plan":
			var rows: Variant = p.get("rows")
			if not rows is Array or (rows as Array).is_empty() or (rows as Array).size() > MAX_PLAN.y:
				return "a plan has 1-%d rows" % MAX_PLAN.y
			var width := -1
			for r: Variant in rows:
				if not r is String or str(r).length() < 1 or str(r).length() > MAX_PLAN.x:
					return "each row of a plan is 1-%d letters" % MAX_PLAN.x
				if width >= 0 and str(r).length() != width:
					return "the rows of a plan are all as long"
				width = str(r).length()
				for ch in str(r):
					if not SYMBOLS.has(ch):
						return "a plan's letters are %s" % [SYMBOLS]
			for k: String in ["grid", "north", "key"]:
				if p.has(k) and not p[k] is bool:
					return "%s is true or false" % k
		"chassis":
			var axles: Variant = p.get("axles")
			if not axles is Array or (axles as Array).is_empty() or (axles as Array).size() > MAX_AXLES:
				return "a chassis has 1-%d axles" % MAX_AXLES
			for a: Variant in axles:
				if not AXLES.has(str(a)):
					return "an axle is one of %s" % [AXLES]
			if not str(p.get("wheels", "same")) in WHEELS:
				return "wheels are one of %s" % [WHEELS]
		"hand":
			var labels: Variant = p.get("labels")
			if not labels is Array or (labels as Array).size() != FINGERS:
				return "a hand has %d labels, thumb first" % FINGERS
			for l: Variant in labels:
				if str(l).length() < 1 or str(l).length() > MAX_NAME:
					return "a label is 1-%d letters" % MAX_NAME
	return ""


## `p[key]`: 1-most names from `known`; `p.labels`, when there, one short text each.
static func _list_problem(p: Dictionary, key: String, known: Array, most: int, longest: int) -> String:
	var list: Variant = p.get(key)
	if not list is Array or (list as Array).is_empty() or (list as Array).size() > most:
		return "%s: 1-%d of them" % [key, most]
	for v: Variant in list:
		if not known.has(str(v)):
			return "%s: '%s' is not one of %s" % [key, v, known]
	if p.has("labels"):
		var labels: Variant = p.labels
		if not labels is Array or (labels as Array).size() != (list as Array).size():
			return "one label for each of the %s" % key
		for l: Variant in labels:
			if str(l).length() > longest:
				return "a label is at most %d letters" % longest
	return ""


static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"circuit":
			_draw_circuit(pic, font, r, d)
		"beach_flags":
			_draw_flags(pic, font, r, d)
		"food_label":
			_draw_label(pic, font, r, d)
		"pitch":
			_draw_pitch(pic, font, r, d)
		"site_plan":
			_draw_plan(pic, font, r, d)
		"chassis":
			_draw_chassis(pic, font, r, d)
		"hand":
			_draw_hand(pic, font, r, d)


# --- circuit ---------------------------------------------------------------------------------------------------------

static func _draw_circuit(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var parts: Array = d.parts
	var names := bool(d.get("names", false))
	var lit := bool(d.get("lit", false))
	var closed := str(d.get("switch", "closed")) == "closed"
	var gap_text := str(d.get("gap", ""))
	var slots: Array = SLOTS[parts.size()]
	var fs := clampi(int(r.size.y * 0.08), 12, 20)
	var label_of := func(i: int) -> String:
		if str(parts[i]) == "gap" and gap_text != "":
			return gap_text
		return str(PART_NAMES[str(parts[i])]) if names else ""
	# room for the words beside the parts on the left and right edges
	var side_w := 0.0
	for i in parts.size():
		if int(slots[i][0]) in [1, 3]:
			side_w = maxf(side_w, font.get_string_size(label_of.call(i), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var has_words := names or gap_text != ""
	var part_l := clampf(minf(r.size.x, r.size.y) * 0.42, 26.0, 96.0)
	var inset_y := part_l * 0.45 + (fs * 1.3 if has_words else 4.0)
	var inset_x := part_l * 0.45 + (side_w + 8.0 if side_w > 0.0 else 4.0)
	var loop := Rect2(r.position + Vector2(inset_x, inset_y), r.size - Vector2(inset_x, inset_y) * 2.0)
	var w := maxf(3.0, part_l * 0.06)
	ci.draw_rect(loop, WIRE, false, w)
	# owner #94: a working circuit's current flows round the wire from the cell's + end (the parts cover it)
	var time := SchoolPicture.time_of(ci)
	var show := SchoolPictureMotion.fade_in(time)
	if show > 0.0:
		var round_loop := PackedVector2Array([loop.position, Vector2(loop.end.x, loop.position.y), loop.end,
			Vector2(loop.position.x, loop.end.y), loop.position])
		SchoolPictureMotion.flow_dots(ci, round_loop, time, SchoolPictureMotion.CURRENT_PX_S
			* SchoolPictureMotion.circuit_way(parts), maxf(18.0, part_l * 0.4), Color(SchoolPictureMotion.GOLD, show),
			w * 0.75)
	for i in parts.size():
		var edge := int(slots[i][0])
		var t := float(slots[i][1])
		var pos: Vector2
		var angle := 0.0
		var normal: Vector2
		match edge:
			0:
				pos = loop.position + Vector2(loop.size.x * t, 0)
				normal = Vector2.UP
			1:
				pos = Vector2(loop.end.x, loop.position.y + loop.size.y * t)
				angle = PI * 0.5
				normal = Vector2.RIGHT
			2:
				pos = Vector2(loop.end.x - loop.size.x * t, loop.end.y)
				normal = Vector2.DOWN
			_:
				pos = Vector2(loop.position.x, loop.end.y - loop.size.y * t)
				angle = -PI * 0.5
				normal = Vector2.LEFT
		ci.draw_set_transform(pos, angle, Vector2.ONE)
		_part(ci, str(parts[i]), part_l, w, lit, closed, gap_text != "", time * 9.0)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var words: String = label_of.call(i)
		if words == "":
			continue
		var tw := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var reach := part_l * 0.42 + 4.0
		var at := pos + normal * reach
		match edge:
			0:
				at += Vector2(-tw * 0.5, 0)
			2:
				at += Vector2(-tw * 0.5, fs * 0.9)
			1:
				at += Vector2(0, fs * 0.36)
			_:
				at += Vector2(-tw, fs * 0.36)
		ci.draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)


## One part at the origin, along x (the wire's way), its top towards -y.
static func _part(ci: CanvasItem, part: String, l: float, w: float, lit: bool, closed: bool, filled: bool,
		spin: float = 0.0) -> void:
	match part:
		"cell":
			var body := Rect2(Vector2(-l * 0.38, -l * 0.17), Vector2(l * 0.72, l * 0.34))
			ci.draw_rect(body, Color("33373d"))
			ci.draw_rect(Rect2(Vector2(l * 0.12, -l * 0.17), Vector2(l * 0.22, l * 0.34)), Color("d9822b"))
			ci.draw_rect(Rect2(Vector2(l * 0.34, -l * 0.07), Vector2(l * 0.06, l * 0.14)), Color("9aa1ad"))
			ci.draw_rect(body, INK, false, 1.5)
			var s := l * 0.07   # + at the copper end, - at the other
			ci.draw_line(Vector2(l * 0.23 - s, 0), Vector2(l * 0.23 + s, 0), Color.WHITE, 2.0)
			ci.draw_line(Vector2(l * 0.23, -s), Vector2(l * 0.23, s), Color.WHITE, 2.0)
			ci.draw_line(Vector2(-l * 0.28 - s, 0), Vector2(-l * 0.28 + s, 0), Color.WHITE, 2.0)
		"bulb":
			var rad := l * 0.2
			var glass := Vector2(0, -l * 0.14 - rad)
			if lit:
				for k in 8:
					var a := TAU * k / 8.0
					var dir := Vector2(cos(a), sin(a))
					ci.draw_line(glass + dir * rad * 1.25, glass + dir * rad * 1.7, Color("f5b700"), 2.0)
			ci.draw_circle(glass, rad, Color("ffe066") if lit else Color("eef4fb"))
			ci.draw_arc(glass, rad, 0, TAU, 24, Color("7d8aa0"), 1.5)
			ci.draw_polyline(PackedVector2Array([Vector2(-rad * 0.3, -l * 0.14), Vector2(-rad * 0.3, glass.y),
				Vector2(-rad * 0.1, glass.y - rad * 0.25), Vector2(rad * 0.1, glass.y), Vector2(rad * 0.3, glass.y - rad * 0.25),
				Vector2(rad * 0.3, -l * 0.14)]), Color("d98b1c") if lit else Color("6b7280"), 1.5)
			ci.draw_rect(Rect2(Vector2(-l * 0.1, -l * 0.14), Vector2(l * 0.2, l * 0.07)), Color("b8c0cc"))
			ci.draw_rect(Rect2(Vector2(-l * 0.22, -l * 0.07), Vector2(l * 0.44, l * 0.14)), Color("6b7280"))
		"led":
			if lit:
				ci.draw_circle(Vector2(0, -l * 0.2), l * 0.22, Color(1.0, 0.3, 0.25, 0.3))
			ci.draw_rect(Rect2(Vector2(-l * 0.16, -l * 0.05), Vector2(l * 0.32, l * 0.1)), Color("6b7280"))
			var red := Color("ff4d3d") if lit else Color("b3261e")
			ci.draw_rect(Rect2(Vector2(-l * 0.09, -l * 0.2), Vector2(l * 0.18, l * 0.15)), red)
			ci.draw_circle(Vector2(0, -l * 0.2), l * 0.09, red)
		"switch":
			ci.draw_rect(Rect2(Vector2(-l * 0.38, -l * 0.07), Vector2(l * 0.76, l * 0.14)), Color("e3c9a0"))
			var a := Vector2(-l * 0.28, 0)
			var b := Vector2(l * 0.28, 0)
			var end := b + Vector2(l * 0.04, -l * 0.03) if closed else a + Vector2(cos(-0.62), sin(-0.62)) * l * 0.58
			ci.draw_circle(a, l * 0.055, Color("4b5563"))
			ci.draw_circle(b, l * 0.055, Color("4b5563"))
			ci.draw_line(a, end, Color("8b93a1"), maxf(3.0, l * 0.05))
			ci.draw_circle(end, l * 0.04, Color("8b93a1"))
		"buzzer":
			if lit:
				for k in 2:
					ci.draw_arc(Vector2.ZERO, l * (0.32 + 0.09 * k), -PI * 0.78, -PI * 0.22, 12, INK, 2.0)
			ci.draw_circle(Vector2.ZERO, l * 0.23, Color("2e3440"))
			ci.draw_circle(Vector2.ZERO, l * 0.08, Color("6b7280"))
		"motor":
			var body := Rect2(Vector2(-l * 0.22, -l * 0.15), Vector2(l * 0.44, l * 0.3))
			ci.draw_rect(body, Color("b8c0cc"))
			ci.draw_rect(body, INK, false, 1.5)
			var hub := Vector2(0, -l * 0.33)
			ci.draw_line(Vector2(0, -l * 0.15), hub, Color("6b7280"), 2.5)
			var blade := l * 0.16
			var tilt := 0.5 + spin if lit else 0.0   # owner #94: a working motor's fan spins
			for k in 2:
				var a := tilt + PI * k
				ci.draw_line(hub, hub + Vector2(cos(a), sin(a) * 0.35) * blade, Color("2f6fdc"), maxf(3.0, l * 0.06))
			if lit:
				ci.draw_arc(hub, blade * 1.3, -PI * 0.9, -PI * 0.1, 12, INK, 1.5)
		"gap":
			ci.draw_rect(Rect2(Vector2(-l * 0.3, -w * 2.0), Vector2(l * 0.6, w * 4.0)), PAPER)
			if filled:   # what bridges the gap, in a colour that tells nothing
				ci.draw_rect(Rect2(Vector2(-l * 0.25, -l * 0.07), Vector2(l * 0.5, l * 0.14)), Color("c9cfd9"))
				ci.draw_rect(Rect2(Vector2(-l * 0.25, -l * 0.07), Vector2(l * 0.5, l * 0.14)), INK, false, 1.2)
			for sx: float in [-1.0, 1.0]:
				ci.draw_rect(Rect2(Vector2(sx * l * 0.3 - l * 0.06, -l * 0.05), Vector2(l * 0.12, l * 0.1)), Color("4b5563"))


# --- beach flags -----------------------------------------------------------------------------------------------------

static func _draw_flags(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var flags: Array = d.flags
	var labels: Array = d.get("labels", [])
	var n := flags.size()
	var fs := clampi(int(r.size.y * 0.09), 12, 22)
	var label_room := fs * 1.6 if not labels.is_empty() else 0.0
	var ground := r.end.y - label_room - r.size.y * 0.1
	ci.draw_rect(Rect2(Vector2(r.position.x, ground), Vector2(r.size.x, r.end.y - ground)), Color("f2dfae"))
	var cell_w := r.size.x / n
	var fw := minf(cell_w * 0.5, (ground - r.position.y) * 0.62)
	var fh := fw * 0.66
	for i in n:
		var cx := r.position.x + cell_w * (i + 0.5)
		var px := cx - fw * 0.5
		var top := r.position.y + 4.0
		ci.draw_line(Vector2(px, top - 2.0), Vector2(px, ground + 4.0), Color("6b7280"), maxf(3.0, fw * 0.05))
		var f := Rect2(Vector2(px, top), Vector2(fw, fh))
		match str(flags[i]):
			"red_yellow":
				ci.draw_rect(Rect2(f.position, Vector2(fw, fh * 0.5)), FLAG_RED)
				ci.draw_rect(Rect2(f.position + Vector2(0, fh * 0.5), Vector2(fw, fh * 0.5)), FLAG_YELLOW)
				ci.draw_rect(f, INK, false, 1.5)
			"red":
				ci.draw_rect(f, FLAG_RED)
				ci.draw_rect(f, INK, false, 1.5)
			"chequered":
				for q in 4:
					var cell := Rect2(f.position + Vector2(fw * 0.5 * (q % 2), fh * 0.5 * (q / 2)), f.size * 0.5)
					ci.draw_rect(cell, Color("1b1b1b") if (q % 2) == (q / 2) else Color.WHITE)
				ci.draw_rect(f, INK, false, 1.5)
			_:   # the windsock: a cone blown out from the pole
				var sock := PackedVector2Array([Vector2(px, top), Vector2(px + fw * 1.05, top + fh * 0.22),
					Vector2(px + fw * 1.05, top + fh * 0.58), Vector2(px, top + fh * 0.8)])
				ci.draw_colored_polygon(sock, WINDSOCK)
				ci.draw_polyline(sock + PackedVector2Array([sock[0]]), INK, 1.5)
				ci.draw_line(Vector2(px + fw * 0.45, top + fh * 0.1), Vector2(px + fw * 0.45, top + fh * 0.7),
					Color(1, 1, 1, 0.8), 2.0)
		if not labels.is_empty():
			_text(ci, font, Vector2(cx, r.end.y - fs * 0.35), str(labels[i]), fs)


# --- food label ------------------------------------------------------------------------------------------------------

static func _draw_label(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var rows: Array = d.rows
	var n := rows.size()
	var fs := clampi(int(r.size.y * 0.075), 11, 18)
	var top := r.position.y
	if str(d.get("name", "")) != "":
		_text(ci, font, Vector2(r.get_center().x, top + fs * 1.1), str(d.name), fs + 2)
		top += fs * 1.7
	var per := str(d.get("per", "per 100 g"))
	var bottom := r.end.y - fs * 1.5
	var gap := 8.0
	var bw := minf((r.size.x - gap * (n - 1)) / n, 150.0)
	var bh := minf(bottom - top, bw * 1.3)
	var x := r.get_center().x - (bw * n + gap * (n - 1)) * 0.5
	var y := top + (bottom - top - bh) * 0.5
	var box_fs := clampi(int(minf(bw * 0.15, bh * 0.14)), 10, 20)
	for row: Array in rows:
		var level := str(row[2])
		var sb := StyleBoxFlat.new()
		sb.bg_color = LEVEL_COLORS[level]
		sb.set_corner_radius_all(int(minf(bw, bh) * 0.18))
		sb.border_color = INK
		sb.set_border_width_all(2)
		var box := Rect2(Vector2(x, y), Vector2(bw, bh))
		ci.draw_style_box(sb, box)
		var cx := box.get_center().x
		_text(ci, font, Vector2(cx, y + bh * 0.24), str(row[0]), box_fs)
		_text(ci, font, Vector2(cx, y + bh * 0.52), str(row[1]), box_fs + 3)
		if level == "?":
			_text(ci, font, Vector2(cx, y + bh * 0.84), "?", box_fs + 6)
		else:
			_text(ci, font, Vector2(cx, y + bh * 0.82), str(LEVEL_WORDS[level]), box_fs)
		x += bw + gap
	_text(ci, font, Vector2(r.get_center().x, r.end.y - fs * 0.3), per, fs)


# --- pitch -----------------------------------------------------------------------------------------------------------

static func _draw_pitch(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var cols := int(d.cols)
	var rows := int(d.rows)
	var layout := str(d.get("layout", "invasion"))
	var ends := 1.0 if layout == "invasion" else 0.2
	var u := minf(r.size.x / (cols + ends), r.size.y / (rows + 0.2))
	var field := Rect2(r.get_center() - Vector2(cols, rows) * u * 0.5, Vector2(cols, rows) * u)
	ci.draw_rect(field, GRASS)
	for k in range(0, cols, 2):   # mown stripes
		ci.draw_rect(Rect2(field.position + Vector2(k * u, 0), Vector2(u, rows * u)), Color(1, 1, 1, 0.07))
	var line := Color(1, 1, 1, 0.9)
	var lw := maxf(2.0, u * 0.07)
	ci.draw_rect(field, line, false, lw)
	match layout:
		"invasion":
			var mid := field.get_center()
			ci.draw_line(Vector2(mid.x, field.position.y), Vector2(mid.x, field.end.y), line, lw)
			ci.draw_arc(mid, u * 1.1, 0, TAU, 32, line, lw)
			for side: float in [-1.0, 1.0]:
				var gx: float = field.position.x if side < 0 else field.end.x
				var goal := Rect2(Vector2(gx - (u * 0.45 if side < 0 else 0.0), mid.y - u), Vector2(u * 0.45, u * 2.0))
				ci.draw_rect(goal, Color(1, 1, 1, 0.35))
				ci.draw_rect(goal, Color.WHITE, false, lw)
		"court":
			ci.draw_line(Vector2(field.get_center().x, field.position.y), Vector2(field.get_center().x, field.end.y), line, lw)
		_:   # rounders: the batting square at the bottom, the bowling square in the middle, posts 1-4 anticlockwise
			var sq := u * 0.9
			var bat := field.position + Vector2(cols * 0.5, rows - 0.75) * u
			var bowl := field.position + Vector2(cols * 0.5, rows * 0.48) * u
			ci.draw_rect(Rect2(bat - Vector2(sq, sq) * 0.5, Vector2(sq, sq)), line, false, lw)
			ci.draw_rect(Rect2(bowl - Vector2(sq, sq) * 0.5, Vector2(sq, sq)), line, false, lw)
			var posts := [Vector2(0.84, 0.64), Vector2(0.8, 0.2), Vector2(0.2, 0.2), Vector2(0.16, 0.64)]
			var pfs := clampi(int(u * 0.4), 10, 22)
			for k in 4:   # a yellow post with its number
				var at: Vector2 = field.position + Vector2(cols, rows) * (posts[k] as Vector2) * u
				ci.draw_circle(at, u * 0.3, Color("fbd02d"))
				ci.draw_arc(at, u * 0.3, 0, TAU, 16, INK, 1.5)
				_text(ci, font, at + Vector2(0, pfs * 0.36), str(k + 1), pfs)
	var players: Array = d.players
	var tfs := clampi(int(u * 0.46), 10, 24)
	for i in players.size():
		var pl: Array = players[i]
		var at := field.position + Vector2(float(pl[0]), float(pl[1])) * u
		var rad := u * 0.36
		if str(pl[2]) == "a":
			ci.draw_circle(at, rad, TEAM)
			ci.draw_arc(at, rad, 0, TAU, 20, Color.WHITE, 2.0)
		else:
			var sq := Rect2(at - Vector2(rad, rad) * 0.9, Vector2(rad, rad) * 1.8)
			ci.draw_rect(sq, OTHERS)
			ci.draw_rect(sq, Color.WHITE, false, 2.0)
		if pl.size() == 4:
			var tw := font.get_string_size(str(pl[3]), HORIZONTAL_ALIGNMENT_LEFT, -1, tfs).x
			ci.draw_string(font, at + Vector2(-tw * 0.5, tfs * 0.36), str(pl[3]), HORIZONTAL_ALIGNMENT_LEFT, -1, tfs,
				Color.WHITE)
		if d.has("ball") and int(d.ball) == i:
			var b := at + Vector2(rad * 0.95, rad * 0.8)
			ci.draw_circle(b, u * 0.15, Color.WHITE)
			ci.draw_arc(b, u * 0.15, 0, TAU, 12, INK, 1.5)


# --- site plan -------------------------------------------------------------------------------------------------------

static func _draw_plan(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var rows: Array = d.rows
	var cols := str(rows[0]).length()
	var grid := bool(d.get("grid", false))
	var north := bool(d.get("north", true))
	var key := bool(d.get("key", false))
	var fs := clampi(int(r.size.y * 0.075), 11, 18)
	var shown: Array[String] = []
	for s: String in SYMBOLS:
		var name := _symbol_name(s)
		for row: String in rows:
			if row.contains(s) and not shown.has(name):
				shown.append(name)
	var key_w := minf(r.size.x * 0.3, 150.0) if key else 0.0
	var north_w := fs * 2.0 if north else 0.0
	var side := fs * 1.4 if grid else 0.0
	var room := Vector2(r.size.x - key_w - north_w - side, r.size.y - side)
	var u := minf(minf(room.x / cols, room.y / rows.size()), 64.0)
	var map_size := Vector2(cols, rows.size()) * u
	var origin := Vector2(r.position.x + side + (room.x - map_size.x) * 0.5, r.position.y + (room.y - map_size.y) * 0.5)
	for y in rows.size():
		for x in cols:
			_symbol(ci, font, Rect2(origin + Vector2(x, y) * u, Vector2(u, u)), str(rows[y])[x])
	for x in cols + 1:   # the squares, to count
		ci.draw_line(origin + Vector2(x * u, 0), origin + Vector2(x * u, map_size.y), Color(1, 1, 1, 0.55), 1.0)
	for y in rows.size() + 1:
		ci.draw_line(origin + Vector2(0, y * u), origin + Vector2(map_size.x, y * u), Color(1, 1, 1, 0.55), 1.0)
	ci.draw_rect(Rect2(origin, map_size), INK, false, 2.0)
	if grid:
		for x in cols:
			_text(ci, font, origin + Vector2((x + 0.5) * u, map_size.y + fs * 1.15), char(65 + x), fs)
		for y in rows.size():
			_text(ci, font, origin + Vector2(-side * 0.5, (y + 0.5) * u + fs * 0.36), str(rows.size() - y), fs)
	if north:
		var base := Vector2(origin.x + map_size.x + north_w * 0.55, origin.y + fs * 2.6)
		var tip := base - Vector2(0, fs * 1.4)
		ci.draw_line(base, tip + Vector2(0, fs * 0.4), INK, 2.5)
		ci.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(fs * 0.4, fs * 0.6), tip - Vector2(fs * 0.4,
			-fs * 0.6)]), INK)
		_text(ci, font, tip - Vector2(0, fs * 0.3), "N", fs)
	if key:
		var kx := r.end.x - key_w + 6.0
		var line := minf(r.size.y / maxf(shown.size(), 1.0), fs * 1.8)
		var ky := r.get_center().y - line * shown.size() * 0.5
		for name in shown:
			var s := _symbol_for(name)
			var sw := Rect2(Vector2(kx, ky + (line - fs * 1.2) * 0.5), Vector2(fs * 1.2, fs * 1.2))
			_symbol(ci, font, sw, s)
			ci.draw_rect(sw, INK, false, 1.0)
			ci.draw_string(font, Vector2(kx + fs * 1.6, ky + line * 0.5 + fs * 0.36), name, HORIZONTAL_ALIGNMENT_LEFT, -1,
				fs, INK)
			ky += line


static func _symbol_name(s: String) -> String:
	return "control" if s.is_valid_int() else str(SYMBOL_NAMES[s])


static func _symbol_for(name: String) -> String:
	if name == "control":
		return "1"
	for s: String in SYMBOL_NAMES:
		if SYMBOL_NAMES[s] == name:
			return s
	return "."


static func _symbol(ci: CanvasItem, font: Font, c: Rect2, s: String) -> void:
	var u := c.size.x
	var mid := c.get_center()
	match s:
		"~":
			ci.draw_rect(c, WATER)
			ci.draw_arc(mid + Vector2(-u * 0.12, 0), u * 0.14, PI, TAU, 8, Color(1, 1, 1, 0.7), 1.5)
			ci.draw_arc(mid + Vector2(u * 0.16, 0), u * 0.14, PI, TAU, 8, Color(1, 1, 1, 0.7), 1.5)
		"=":
			ci.draw_rect(c, WATER)
			ci.draw_rect(Rect2(c.position + Vector2(0, u * 0.22), Vector2(u, u * 0.56)), Color("a0673a"))
			for k in 4:
				var x := c.position.x + u * (0.12 + 0.25 * k)
				ci.draw_line(Vector2(x, c.position.y + u * 0.22), Vector2(x, c.position.y + u * 0.78), Color("6e4323"), 1.5)
		"T":
			ci.draw_rect(c, Color("8cc27a"))
			for p: Vector2 in [Vector2(0.3, 0.32), Vector2(0.7, 0.4), Vector2(0.42, 0.72)]:
				ci.draw_circle(c.position + p * u, u * 0.19, Color("2f7a35"))
		"#":
			ci.draw_rect(c, Color("f0cf65"))
			for k in 4:
				var y := c.position.y + u * (0.15 + 0.23 * k)
				ci.draw_line(Vector2(c.position.x + u * 0.1, y), Vector2(c.end.x - u * 0.1, y), Color("b58a22"), 1.5)
		"H":
			ci.draw_rect(c, LAND)
			var wall := Rect2(c.position + Vector2(u * 0.22, u * 0.45), Vector2(u * 0.56, u * 0.4))
			ci.draw_rect(wall, Color("efe8d8"))
			ci.draw_rect(wall, INK, false, 1.0)
			ci.draw_colored_polygon(PackedVector2Array([c.position + Vector2(u * 0.14, u * 0.47), c.position + Vector2(u * 0.5,
				u * 0.14), c.position + Vector2(u * 0.86, u * 0.47)]), Color("c0392b"))
		"M":
			ci.draw_rect(c, LAND)
			ci.draw_circle(mid, u * 0.32, Color("c79a64"))
			for k in 4:
				var a := PI * 0.25 * k * 2.0 + PI * 0.25
				ci.draw_line(mid - Vector2(cos(a), sin(a)) * u * 0.32, mid + Vector2(cos(a), sin(a)) * u * 0.32,
					Color("6e4323"), 2.0)
			ci.draw_arc(mid, u * 0.32, 0, TAU, 20, Color("6e4323"), 1.5)
		"p":
			ci.draw_rect(c, Color("e7cfa2"))
		"^":
			ci.draw_rect(c, LAND)
			for k in 3:
				ci.draw_arc(mid + Vector2(0, u * 0.1), u * (0.12 + 0.12 * k), 0, TAU, 16, Color("9a5b2b"), 1.5)
		"r":
			ci.draw_rect(c, LAND)
			for p: Vector2 in [Vector2(0.32, 0.4), Vector2(0.62, 0.3), Vector2(0.55, 0.68)]:
				ci.draw_circle(c.position + p * u, u * 0.12, Color("8b93a1"))
		_:
			ci.draw_rect(c, LAND)
			var w := maxf(2.0, u * 0.07)
			if s == "S":
				var h := u * 0.34
				var tri := PackedVector2Array([mid + Vector2(0, -h), mid + Vector2(h * 0.9, h * 0.6), mid + Vector2(-h * 0.9,
					h * 0.6)])
				ci.draw_polyline(tri + PackedVector2Array([tri[0]]), PURPLE, w)
			elif s == "F":
				ci.draw_arc(mid, u * 0.34, 0, TAU, 24, PURPLE, w)
				ci.draw_arc(mid, u * 0.22, 0, TAU, 24, PURPLE, w)
			elif s.is_valid_int():
				ci.draw_arc(mid, u * 0.34, 0, TAU, 24, PURPLE, w)
				var fs := clampi(int(u * 0.4), 9, 22)
				_text_col(ci, font, mid + Vector2(0, fs * 0.36), s, fs, PURPLE)


# --- chassis ---------------------------------------------------------------------------------------------------------

static func _draw_chassis(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var axles: Array = d.axles
	var labels := bool(d.get("labels", false))
	var mixed := str(d.get("wheels", "same")) == "mixed"
	var fs := clampi(int(r.size.y * 0.08), 11, 20)
	var label_w := minf(r.size.x * 0.3, 140.0) if labels else 0.0
	var area := Rect2(r.position, Vector2(r.size.x - label_w, r.size.y))
	var length := area.size.x * 0.72
	var width := minf(area.size.y * 0.42, length * 0.42)
	var body := Rect2(area.get_center() - Vector2(length, width) * 0.5, Vector2(length, width))
	ci.draw_rect(body, Color("d8b384"))
	ci.draw_rect(body, Color("8a5a36"), false, 2.0)
	var reach := width * 0.5 + width * 0.32   # half an axle
	var dia := width * 0.62
	var thick := maxf(6.0, width * 0.16)
	var aw := maxf(3.0, width * 0.05)
	var targets := {}
	for i in axles.size():
		var t := 0.5 if axles.size() == 1 else 0.14 + 0.72 * i / (axles.size() - 1)
		var centre := Vector2(body.position.x + length * t, body.get_center().y)
		var a := PI * 0.5 + (CROOKED if str(axles[i]) == "crooked" else 0.0)
		var dir := Vector2(cos(a), sin(a))
		var ends := [centre - dir * reach, centre + dir * reach]
		ci.draw_line(ends[0], ends[1], Color("8b93a1"), aw)
		for sgn: float in [-1.0, 1.0]:   # the axle holders at the chassis' edges
			var hold := centre + dir * sgn * width * 0.38
			ci.draw_line(hold - dir * width * 0.1, hold + dir * width * 0.1, Color("f3f0e6"), aw * 2.6)
			ci.draw_line(hold - dir * width * 0.1, hold + dir * width * 0.1, Color("9aa1ad"), 1.0)
		for k in 2:
			var small := mixed and i == axles.size() - 1 and k == 1
			var wd := dia * (0.5 if small else 1.0)
			var along := Vector2(-dir.y, dir.x)   # a wheel's rim runs across its axle
			var e: Vector2 = ends[k]
			var pts := PackedVector2Array([e - along * wd * 0.5 - dir * thick * 0.5, e + along * wd * 0.5 - dir * thick * 0.5,
				e + along * wd * 0.5 + dir * thick * 0.5, e - along * wd * 0.5 + dir * thick * 0.5])
			ci.draw_colored_polygon(pts, Color("2e3440"))
			if i == axles.size() - 1 and k == 0:
				targets["wheel"] = e
		if i == axles.size() - 1:   # the back axle, nearest the words
			targets["axle"] = centre - dir * (width * 0.5 + width * 0.12)
			targets["axle holder"] = centre - dir * width * 0.38
	targets["chassis"] = body.position + Vector2(length * 0.5, width * 0.3)
	if not labels:
		return
	var names := ["chassis", "axle", "axle holder", "wheel"]
	var x := r.end.x - label_w + 10.0
	var step := r.size.y / (names.size() + 1)
	for k in names.size():
		var y := r.position.y + step * (k + 1)
		ci.draw_string(font, Vector2(x, y + fs * 0.36), names[k], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
		var to: Vector2 = targets[names[k]]
		ci.draw_line(Vector2(x - 4.0, y), to, Color(INK, 0.7), 1.5)
		ci.draw_circle(to, 3.0, INK)


# --- the helping hand ------------------------------------------------------------------------------------------------

static func _draw_hand(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var labels: Array = d.labels
	var fs := clampi(int(r.size.y * 0.08), 11, 20)
	var palm_r := minf(r.size.y * 0.2, r.size.x * 0.1)
	var centre := Vector2(r.get_center().x, r.end.y - palm_r * 1.25)
	# thumb, index, middle, ring and little finger: their angle (degrees from right, up is -90) and length
	var fingers := [[-168.0, 0.95], [-122.0, 1.25], [-90.0, 1.4], [-58.0, 1.25], [-22.0, 1.0]]
	var width := palm_r * 0.46
	var tips: Array[Vector2] = []
	for f: Array in fingers:
		var a := deg_to_rad(float(f[0]))
		var dir := Vector2(cos(a), sin(a))
		var base := centre + dir * palm_r * 0.6
		var tip := centre + dir * palm_r * (0.9 + float(f[1]))
		ci.draw_line(base, tip, INK, width + 4.0)
		ci.draw_circle(tip, (width + 4.0) * 0.5, INK)
		tips.append(tip)
	ci.draw_circle(centre, palm_r + 2.0, INK)
	for i in fingers.size():
		var a := deg_to_rad(float(fingers[i][0]))
		var dir := Vector2(cos(a), sin(a))
		ci.draw_line(centre + dir * palm_r * 0.6, tips[i], SKIN, width)
		ci.draw_circle(tips[i], width * 0.5, SKIN)
	ci.draw_circle(centre, palm_r, SKIN)
	_text(ci, font, centre + Vector2(0, fs * 0.36), "me", fs)
	for i in fingers.size():
		var a := deg_to_rad(float(fingers[i][0]))
		var dir := Vector2(cos(a), sin(a))
		var text := str(labels[i])
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var at: Vector2 = tips[i] + dir * (width * 0.5 + fs * 0.5)
		var x := at.x - tw * 0.5
		if dir.x > 0.3:
			x = at.x
		elif dir.x < -0.3:
			x = at.x - tw
		x = clampf(x, r.position.x, r.end.x - tw)
		ci.draw_string(font, Vector2(x, at.y + fs * (0.36 if absf(dir.y) < 0.5 else 0.1)), text, HORIZONTAL_ALIGNMENT_LEFT,
			-1, fs, INK)


# --- helpers ---------------------------------------------------------------------------------------------------------

static func _text(ci: CanvasItem, font: Font, center_base: Vector2, text: String, fs: int) -> void:
	_text_col(ci, font, center_base, text, fs, INK)


static func _text_col(ci: CanvasItem, font: Font, center_base: Vector2, text: String, fs: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	ci.draw_string(font, Vector2(center_base.x - w * 0.5, center_base.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
