class_name SchoolPictureG5Life
extends RefCounted
## Grade 5 health and PE, design and technology, and projects (owner #70, #73): the picture kinds they add, drawn from
## data onto a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only, no new art; the
## font has no arrows, so they are drawn). Kinds and fields:
## - net_court {players: [[x, y, "a" | "d", tag? (2 letters)]] (1-6; x 0-12, y 0-6 in squares, the net at x 6), spots?:
##   [[x, y, tag (2 letters)]] (0-6, yellow targets), shot?: [player index, spot index] (a dashed line), sport?
##   (SPORTS: "badminton", the default, "tennis" or "volleyball": their lines)}: a net game's court from above; "a"
##   players (your side, on the left) are blue circles, "d" players red squares.
## - gears {gears: [teeth] (1-4, 8-40 each, meshing in a row, left to right, each drawn as big as its teeth), turn?
##   ("cw" | "acw": the first gear's turn, an arrow on it), arrows? ("first", the default, or "all": every gear's arrow,
##   by gear_turns), labels?: [text] (12 letters each, one each), marks? (a white dot on each, to count turns)}.
## - pulleys {sizes: [a, b] (1-6 each: the wheels' sizes), turn?, arrows?, crossed? (a crossed belt), labels?: [text]
##   (one each)} or {lift: 1 | 2 (a fixed pulley, or a fixed and a moving one, lifting a crate), labels? (true: load,
##   effort and the pulleys named)}.
## - cam {shape: CAMS ("round": a disc turning off-centre, "pear", "snail", "oval"), turn? (0-359 degrees, clockwise),
##   labels? (cam, follower, axle, guide), graph? (the follower's height over one turn, beside it)}: a cam turning under
##   its follower in a toy's frame, a flag on top; cam_height gives the follower's height.
## - bridge {type: BRIDGES, spans? (1-4; beam and truss only: piers between), load? (0-1: a crate on the deck that far
##   along), forces? (squash and stretch arrows, with their key), labels? (the parts named), mark? (one of the type's
##   BRIDGE_PARTS, in orange)}: a bridge over a river, seen from the side.
## - views {heights: ["2100", …] (1-5 rows of 1-5 digits 0-5, all as long; the first row at the back, each digit a stack
##   of blocks), show: VIEWS ("model": the blocks drawn in 3D, "plan": from above, "front", "side": from the right, the
##   front on the left), numbers? (the plan's stacks numbered), label? (the view's name under it)}.
## - compass {points? (4 or 8, the default), bearing? (0-359: an orange arrow that way, 0 north, clockwise), degrees?
##   (the points' degrees), hide? (a point shown "?"), needle? (a magnetic needle, its red end north)}: a compass rose.
## - food_web {nodes: [[name (12 letters), col (0-3), row (0-3, 0 at the top)]] (2-8, one to a place), links: [[food,
##   eater]] (1-12 node indexes: the arrow points from the food to what eats it, the way the energy goes), mark? (a
##   node in orange), hide? (a node shown "?")}: plants (nothing eaten before them) green, animals sand.
## - lying {pose: LYING ("back" or "recovery"), labels?}: a person lying on a mat, seen from above: on their back (the
##   head tilted back to open the airway), or in the recovery position.

const KINDS: Array[String] = ["net_court", "gears", "pulleys", "cam", "bridge", "views", "compass", "food_web", "lying"]
const INK := Color("1f2a4a")    # SchoolUi.INK
const PAPER := Color("fdf6e3")  # SchoolUi.PAPER
const ORANGE := Color("f08a1c")
const RED := Color("d9433b")
const BLUE := Color("3a7be8")
const TURNS: Array[String] = ["cw", "acw"]
const MAX_TAG := 2
const MAX_LABEL := 12

const COURT := Vector2(12, 6)
const SPORTS: Array[String] = ["badminton", "tennis", "volleyball"]
const SURFACE := {"badminton": Color("3d8b5f"), "tennis": Color("3f72b5"), "volleyball": Color("e0934a")}
const MAX_COURT_PLAYERS := 6
const MAX_SPOTS := 6
const TEAM := Color("2f6fdc")
const OTHERS := Color("dc3d2d")
const SPOT := Color("fbd02d")

const GEAR_TEETH := Vector2i(8, 40)
const MAX_GEARS := 4
const ARROWS: Array[String] = ["first", "all"]
const GEAR_COLORS: Array[Color] = [Color("f0a53c"), Color("5b9bd5"), Color("6fbf73"), Color("b28ad8")]
const PULLEY_SIZE := Vector2i(1, 6)
const LIFTS: Array[int] = [1, 2]

const CAMS: Array[String] = ["round", "pear", "snail", "oval"]
const WOOD := Color("c98b4f")

const BRIDGES: Array[String] = ["beam", "arch", "truss", "suspension", "cable_stayed"]
const BRIDGE_PARTS := {"beam": ["deck", "pier"], "arch": ["deck", "arch", "abutment", "keystone"],
	"truss": ["deck", "truss", "pier"], "suspension": ["deck", "tower", "cable"],
	"cable_stayed": ["deck", "tower", "cable"]}
const MAX_SPANS := 4
const STONE := Color("a9a397")
const STEEL := Color("6b7a8f")
const WATER := Color("7fb6e8")
const BANK := Color("8fb36a")
const SQUASH := Color("d9433b")
const STRETCH := Color("2f6fdc")

const VIEWS: Array[String] = ["model", "plan", "front", "side"]
const MAX_VIEW := 5
const MAX_STACK := 5
const TOP := Color("f7c46c")
const FRONT := Color("e39a3b")
const SIDE := Color("b86f23")

const POINTS := {4: ["N", "E", "S", "W"], 8: ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]}

const MAX_NODES := 8
const MAX_LINKS := 12
const MAX_NODE := 12
const WEB_COLS := 4
const WEB_ROWS := 4
const PLANT := Color("cdeab0")
const ANIMAL := Color("f3dfb8")

const LYING: Array[String] = ["back", "recovery"]
## A person lying, seen from above: x along the body (head left), y towards their front (up), in body lengths.
const LIE := {
	"back": {"head": Vector2(0.09, 0), "neck": Vector2(0.19, 0), "hip": Vector2(0.55, 0), "le": Vector2(0.36, 0.1),
		"lh": Vector2(0.5, 0.12), "re": Vector2(0.36, -0.1), "rh": Vector2(0.5, -0.12), "lk": Vector2(0.76, 0.05),
		"lf": Vector2(0.97, 0.06), "rk": Vector2(0.76, -0.05), "rf": Vector2(0.97, -0.06)},
	# on the side: the top hand under the cheek, the bottom arm out at a right angle (elbow bent, the hand towards the
	# head), the top knee bent at a right angle in front, the bottom leg straight
	"recovery": {"head": Vector2(0.09, 0), "neck": Vector2(0.19, 0), "hip": Vector2(0.55, 0), "le": Vector2(0.21, 0.12),
		"lh": Vector2(0.12, 0.07), "re": Vector2(0.24, 0.27), "rh": Vector2(0.1, 0.27), "lk": Vector2(0.58, 0.25),
		"lf": Vector2(0.8, 0.24), "rk": Vector2(0.76, -0.01), "rf": Vector2(0.97, -0.02)},
}
const MAT := Color("cfe3f7")
const SKIN := Color("fbe3c8")


# --- The rules the pictures draw by (the lessons teach them; tests check them) --------------------------------------

## Which way each of `n` gears in a row turns when the first turns `first`: meshing gears turn opposite ways.
static func gear_turns(first: String, n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append(first if i % 2 == 0 else ("acw" if first == "cw" else "cw"))
	return out


## Which way two pulleys on a belt turn: the same way on an open belt, opposite ways on a crossed one.
static func pulley_turns(first: String, crossed: bool) -> Array:
	return [first, (("acw" if first == "cw" else "cw") if crossed else first)]


## A cam's edge, as far from its axle as it is along the direction `theta` (degrees, anticlockwise from the right, in
## the cam's own turn: at turn 0 each cam has its highest point, or the start of its rise, at the top).
static func cam_radius(shape: String, theta: float) -> float:
	var t := deg_to_rad(theta - 90.0)
	match shape:
		"round":   # a disc of radius 1 whose centre is 0.35 above the axle
			var e := 0.35
			return e * cos(t) + sqrt(1.0 - e * e * sin(t) * sin(t))
		"oval":
			var a := 1.3
			var b := 0.85
			return 1.0 / sqrt(pow(cos(t) / a, 2) + pow(sin(t) / b, 2))
		"pear":   # round (a rest) most of the way, with a nose
			var off := wrapf(theta - 90.0, -180.0, 180.0)
			if absf(off) >= 75.0:
				return 0.9
			return 0.9 + 0.55 * pow(cos(deg_to_rad(off * 90.0 / 75.0)), 2)
		"snail":   # a slow rise all the way round, then a sudden drop
			return 0.75 + 0.6 * fposmod(theta - 90.0, 360.0) / 360.0
	return 1.0


## How high the follower stands (in the cam's radii) when the cam has turned `turn` degrees clockwise.
static func cam_height(shape: String, turn: float) -> float:
	return cam_radius(shape, 90.0 + turn)


## A block model's front view: the tallest stack in each column, left to right.
static func front_view(rows: Array) -> Array:
	var out: Array = []
	for c in str(rows[0]).length():
		var top := 0
		for r: Variant in rows:
			top = maxi(top, int(str(r)[c]))
		out.append(top)
	return out


## A block model's side view from the right: the tallest stack in each row, the front row first (on the left).
static func side_view(rows: Array) -> Array:
	var out: Array = []
	for i in range(rows.size() - 1, -1, -1):
		var top := 0
		for ch in str(rows[i]):
			top = maxi(top, int(ch))
		out.append(top)
	return out


# --- Checks ------------------------------------------------------------------------------------------------------

## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	match str(p.get("kind", "")):
		"net_court":
			return _court_problem(p)
		"gears":
			var gears: Variant = p.get("gears")
			if not gears is Array or (gears as Array).is_empty() or (gears as Array).size() > MAX_GEARS:
				return "1-%d gears" % MAX_GEARS
			for g: Variant in gears:
				if not _whole(g) or int(g) < GEAR_TEETH.x or int(g) > GEAR_TEETH.y:
					return "a gear has %d-%d teeth" % [GEAR_TEETH.x, GEAR_TEETH.y]
			var why := _turn_problem(p)
			if why != "":
				return why
			return _labels_problem(p, (gears as Array).size())
		"pulleys":
			if p.has("lift"):
				if p.has("sizes") or not _whole(p.lift) or not LIFTS.has(int(p.lift)):
					return "lift is 1 or 2, without sizes"
				return _bool_problem(p, ["labels"])
			var sizes: Variant = p.get("sizes")
			if not sizes is Array or (sizes as Array).size() != 2:
				return "two pulleys' sizes"
			for s: Variant in sizes:
				if not _whole(s) or int(s) < PULLEY_SIZE.x or int(s) > PULLEY_SIZE.y:
					return "a pulley's size is %d-%d" % [PULLEY_SIZE.x, PULLEY_SIZE.y]
			var why := _turn_problem(p)
			if why == "":
				why = _bool_problem(p, ["crossed"])
			if why != "":
				return why
			return _labels_problem(p, 2)
		"cam":
			if not CAMS.has(str(p.get("shape", ""))):
				return "a cam's shape is one of %s" % [CAMS]
			if p.has("turn") and (not _number(p.turn) or float(p.turn) < 0 or float(p.turn) >= 360):
				return "turn is 0-359 degrees"
			return _bool_problem(p, ["labels", "graph"])
		"bridge":
			var type := str(p.get("type", ""))
			if not BRIDGES.has(type):
				return "a bridge's type is one of %s" % [BRIDGES]
			if p.has("spans") and (not type in ["beam", "truss"] or not _whole(p.spans) or int(p.spans) < 1
					or int(p.spans) > MAX_SPANS):
				return "spans are 1-%d, for beam and truss bridges" % MAX_SPANS
			if p.has("load") and (not _number(p.load) or float(p.load) < 0 or float(p.load) > 1):
				return "load is 0-1 along the deck"
			if p.has("mark") and not (BRIDGE_PARTS[type] as Array).has(str(p.mark)):
				return "a %s bridge's parts are %s" % [type, BRIDGE_PARTS[type]]
			return _bool_problem(p, ["forces", "labels"])
		"views":
			var rows: Variant = p.get("heights")
			if not rows is Array or (rows as Array).is_empty() or (rows as Array).size() > MAX_VIEW:
				return "a model has 1-%d rows" % MAX_VIEW
			var width := -1
			var blocks := 0
			for r: Variant in rows:
				if not r is String or str(r).length() < 1 or str(r).length() > MAX_VIEW:
					return "each row is 1-%d digits" % MAX_VIEW
				if width >= 0 and str(r).length() != width:
					return "the rows are all as long"
				width = str(r).length()
				for ch in str(r):
					if not ch.is_valid_int() or int(ch) > MAX_STACK:
						return "each stack is 0-%d blocks" % MAX_STACK
					blocks += int(ch)
			if blocks == 0:
				return "a model has blocks"
			if not VIEWS.has(str(p.get("show", ""))):
				return "show is one of %s" % [VIEWS]
			return _bool_problem(p, ["numbers", "label"])
		"compass":
			var n := int(p.get("points", 8)) if _whole(p.get("points", 8)) else 0
			if not POINTS.has(n):
				return "points is 4 or 8"
			if p.has("bearing") and (not _number(p.bearing) or float(p.bearing) < 0 or float(p.bearing) >= 360):
				return "a bearing is 0-359 degrees"
			if p.has("hide") and not (POINTS[n] as Array).has(str(p.hide)):
				return "hide is one of %s" % [POINTS[n]]
			return _bool_problem(p, ["degrees", "needle"])
		"food_web":
			return _web_problem(p)
		"lying":
			if not LYING.has(str(p.get("pose", ""))):
				return "pose is one of %s" % [LYING]
			return _bool_problem(p, ["labels"])
	return ""


static func _court_problem(p: Dictionary) -> String:
	if not str(p.get("sport", "badminton")) in SPORTS:
		return "a court's sport is one of %s" % [SPORTS]
	var players: Variant = p.get("players")
	if not players is Array or (players as Array).is_empty() or (players as Array).size() > MAX_COURT_PLAYERS:
		return "a court has 1-%d players" % MAX_COURT_PLAYERS
	for pl: Variant in players:
		if not pl is Array or (pl as Array).size() < 3 or (pl as Array).size() > 4:
			return "a player is [x, y, team, tag?]"
		if not _on_court(pl):
			return "a player stands on the court: x 0-12, y 0-6"
		if not str(pl[2]) in ["a", "d"]:
			return "a player's team is a or d"
		if (pl as Array).size() == 4 and (str(pl[3]).length() < 1 or str(pl[3]).length() > MAX_TAG):
			return "a player's tag is 1-%d letters" % MAX_TAG
	var spots: Variant = p.get("spots", [])
	if not spots is Array or (spots as Array).size() > MAX_SPOTS:
		return "0-%d spots" % MAX_SPOTS
	for s: Variant in spots:
		if not s is Array or (s as Array).size() != 3 or not _on_court(s):
			return "a spot is [x, y, tag] on the court"
		if str(s[2]).length() < 1 or str(s[2]).length() > MAX_TAG:
			return "a spot's tag is 1-%d letters" % MAX_TAG
	if p.has("shot"):
		var shot: Variant = p.shot
		if not shot is Array or (shot as Array).size() != 2 or not _whole(shot[0]) or not _whole(shot[1]) \
				or int(shot[0]) < 0 or int(shot[0]) >= (players as Array).size() or int(shot[1]) < 0 \
				or int(shot[1]) >= (spots as Array).size():
			return "shot is [a player's index, a spot's index]"
	return ""


static func _web_problem(p: Dictionary) -> String:
	var nodes: Variant = p.get("nodes")
	if not nodes is Array or (nodes as Array).size() < 2 or (nodes as Array).size() > MAX_NODES:
		return "a food web has 2-%d living things" % MAX_NODES
	var places := {}
	for nd: Variant in nodes:
		if not nd is Array or (nd as Array).size() != 3:
			return "a living thing is [name, col, row]"
		if str(nd[0]).length() < 1 or str(nd[0]).length() > MAX_NODE:
			return "a name is 1-%d letters" % MAX_NODE
		if not _whole(nd[1]) or not _whole(nd[2]) or int(nd[1]) < 0 or int(nd[1]) >= WEB_COLS or int(nd[2]) < 0 \
				or int(nd[2]) >= WEB_ROWS:
			return "col 0-%d, row 0-%d" % [WEB_COLS - 1, WEB_ROWS - 1]
		var at := Vector2i(int(nd[1]), int(nd[2]))
		if places.has(at):
			return "one living thing to a place"
		places[at] = true
	var n := (nodes as Array).size()
	var links: Variant = p.get("links")
	if not links is Array or (links as Array).is_empty() or (links as Array).size() > MAX_LINKS:
		return "1-%d links" % MAX_LINKS
	var seen := {}
	for l: Variant in links:
		if not l is Array or (l as Array).size() != 2 or not _whole(l[0]) or not _whole(l[1]) or int(l[0]) < 0 \
				or int(l[1]) < 0 or int(l[0]) >= n or int(l[1]) >= n or int(l[0]) == int(l[1]):
			return "a link is [food, eater]: two different living things"
		var key := Vector2i(int(l[0]), int(l[1]))
		if seen.has(key):
			return "a link twice"
		seen[key] = true
	for k: String in ["mark", "hide"]:
		if p.has(k) and (not _whole(p[k]) or int(p[k]) < 0 or int(p[k]) >= n):
			return "%s is a living thing's index" % k
	return ""


static func _turn_problem(p: Dictionary) -> String:
	if p.has("turn") and not TURNS.has(str(p.turn)):
		return "turn is cw or acw"
	if p.has("arrows") and not ARROWS.has(str(p.arrows)):
		return "arrows is first or all"
	return _bool_problem(p, ["marks"])


static func _labels_problem(p: Dictionary, n: int) -> String:
	if not p.has("labels"):
		return ""
	var labels: Variant = p.labels
	if not labels is Array or (labels as Array).size() != n:
		return "one label each"
	for l: Variant in labels:
		if str(l).length() < 1 or str(l).length() > MAX_LABEL:
			return "a label is 1-%d letters" % MAX_LABEL
	return ""


static func _bool_problem(p: Dictionary, keys: Array) -> String:
	for k: String in keys:
		if p.has(k) and not p[k] is bool:
			return "%s is true or false" % k
	return ""


static func _on_court(a: Variant) -> bool:
	return a is Array and (a as Array).size() >= 2 and _number(a[0]) and _number(a[1]) and float(a[0]) >= 0 \
		and float(a[0]) <= COURT.x and float(a[1]) >= 0 and float(a[1]) <= COURT.y


static func _number(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT]


static func _whole(v: Variant) -> bool:
	return _number(v) and float(v) == floorf(float(v))


# --- Drawing -------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"net_court":
			_draw_court(pic, font, r, d)
		"gears":
			_draw_gears(pic, font, r, d)
		"pulleys":
			if d.has("lift"):
				_draw_lift(pic, font, r, d)
			else:
				_draw_pulleys(pic, font, r, d)
		"cam":
			_draw_cam(pic, font, r, d)
		"bridge":
			_draw_bridge(pic, font, r, d)
		"views":
			_draw_views(pic, font, r, d)
		"compass":
			_draw_compass(pic, font, r, d)
		"food_web":
			_draw_web(pic, font, r, d)
		"lying":
			_draw_lying(pic, font, r, d)


# --- net_court -----------------------------------------------------------------------------------------------------

static func _draw_court(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var sport := str(d.get("sport", "badminton"))
	var u := minf(r.size.x / (COURT.x + 0.9), r.size.y / (COURT.y + 0.9))
	var court := Rect2(r.get_center() - COURT * u * 0.5, COURT * u)
	ci.draw_rect(court.grow(u * 0.35), Color(SURFACE[sport]).darkened(0.25))
	ci.draw_rect(court, SURFACE[sport])
	var line := Color(1, 1, 1, 0.92)
	var lw := maxf(1.5, u * 0.06)
	var at := func(x: float, y: float) -> Vector2: return court.position + Vector2(x, y) * u
	var hline := func(y: float, x0: float, x1: float) -> void: ci.draw_line(at.call(x0, y), at.call(x1, y), line, lw)
	var vline := func(x: float, y0: float, y1: float) -> void: ci.draw_line(at.call(x, y0), at.call(x, y1), line, lw)
	ci.draw_rect(court, line, false, lw)
	match sport:
		"badminton":   # 13.4 m by 6.1 m: short service lines 1.98 m from the net, singles sidelines 0.46 m in
			var ss := 1.98 * COURT.x / 13.4
			var side := 0.46 * COURT.y / 6.1
			var long := 0.76 * COURT.x / 13.4
			hline.call(side, 0, COURT.x)
			hline.call(COURT.y - side, 0, COURT.x)
			for x: float in [6.0 - ss, 6.0 + ss, long, COURT.x - long]:
				vline.call(x, 0, COURT.y)
			hline.call(COURT.y * 0.5, 0, 6.0 - ss)
			hline.call(COURT.y * 0.5, 6.0 + ss, COURT.x)
		"tennis":   # 23.77 m by 10.97 m: service lines 6.4 m from the net, singles sidelines 1.37 m in
			var sv := 6.4 * COURT.x / 23.77
			var side := 1.37 * COURT.y / 10.97
			hline.call(side, 0, COURT.x)
			hline.call(COURT.y - side, 0, COURT.x)
			vline.call(6.0 - sv, side, COURT.y - side)
			vline.call(6.0 + sv, side, COURT.y - side)
			hline.call(COURT.y * 0.5, 6.0 - sv, 6.0 + sv)
			hline.call(COURT.y * 0.5, 0, 0.2)
			hline.call(COURT.y * 0.5, COURT.x - 0.2, COURT.x)
		_:   # volleyball, 18 m by 9 m: the attack lines 3 m from the net
			vline.call(4.0, 0, COURT.y)
			vline.call(8.0, 0, COURT.y)
	# the net across the middle, its posts just outside the court
	var top: Vector2 = at.call(6.0, -0.3)
	var bottom: Vector2 = at.call(6.0, COURT.y + 0.3)
	ci.draw_line(top, bottom, Color("2b2b33"), maxf(3.0, u * 0.14))
	var k := 0.0
	while k < COURT.y + 0.6:
		var y: float = top.y + k * u
		ci.draw_line(Vector2(top.x - u * 0.12, y), Vector2(top.x + u * 0.12, y), Color(1, 1, 1, 0.55), 1.0)
		k += 0.25
	for pt: Vector2 in [top, bottom]:
		ci.draw_circle(pt, u * 0.14, Color("d5d9e0"))
		ci.draw_arc(pt, u * 0.14, 0, TAU, 12, INK, 1.5)
	var players: Array = d.players
	var spots: Array = d.get("spots", [])
	var tfs := clampi(int(u * 0.46), 10, 24)
	if d.has("shot"):
		var from: Array = players[int(d.shot[0])]
		var to: Array = spots[int(d.shot[1])]
		var a: Vector2 = at.call(float(from[0]), float(from[1]))
		var b: Vector2 = at.call(float(to[0]), float(to[1]))
		ci.draw_dashed_line(a, b, Color.WHITE, maxf(2.0, u * 0.07), u * 0.25)
	for s: Array in spots:
		var c: Vector2 = at.call(float(s[0]), float(s[1]))
		ci.draw_circle(c, u * 0.36, SPOT)
		ci.draw_arc(c, u * 0.36, 0, TAU, 18, INK, 1.5)
		_text(ci, font, c + Vector2(0, tfs * 0.36), str(s[2]), tfs)
	for pl: Array in players:
		var c: Vector2 = at.call(float(pl[0]), float(pl[1]))
		var rad := u * 0.36
		if str(pl[2]) == "a":
			ci.draw_circle(c, rad, TEAM)
			ci.draw_arc(c, rad, 0, TAU, 20, Color.WHITE, 2.0)
		else:
			var sq := Rect2(c - Vector2(rad, rad) * 0.9, Vector2(rad, rad) * 1.8)
			ci.draw_rect(sq, OTHERS)
			ci.draw_rect(sq, Color.WHITE, false, 2.0)
		if pl.size() == 4:
			_text_col(ci, font, c + Vector2(0, tfs * 0.36), str(pl[3]), tfs, Color.WHITE)


# --- gears and pulleys -----------------------------------------------------------------------------------------------

static func _draw_gears(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var teeth: Array = d.gears
	var n := teeth.size()
	var turn := str(d.get("turn", ""))
	var turns := gear_turns(turn if turn != "" else "cw", n)
	var labels: Array = d.get("labels", [])
	var fs := clampi(int(r.size.y * 0.085), 11, 20)
	var label_h := fs * 1.4 if not labels.is_empty() else 0.0
	var total := 0.0
	var tallest := 0.0
	for t: Variant in teeth:
		total += 2.0 * float(t)
		tallest = maxf(tallest, 2.0 * float(t))
	# a pitch radius of k × teeth; room for the teeth and the arrows round the outside
	var k := minf((r.size.x - 8.0) / (total + 10.0), (r.size.y - label_h - 8.0) / (tallest + 12.0))
	var x := r.get_center().x - total * k * 0.5
	var cy := r.position.y + (r.size.y - label_h) * 0.5
	var phase := 0.0
	var prev_tooth_right := true
	var time := SchoolPicture.time_of(ci)   # owner #94: the gears turn (SchoolPictureMotion.gear_spin)
	for i in n:
		var t := int(teeth[i])
		var rad := t * k
		var step := TAU / t
		if i > 0:   # a gap faces the last gear's tooth, or a tooth its gap
			phase = PI + (0.5 * step if prev_tooth_right else 0.0)
		var c := Vector2(x + rad, cy)
		var spin := SchoolPictureMotion.gear_spin(teeth, i, turn, time) if time > 0.0 else 0.0
		_gear(ci, c, rad, t, phase + spin, k, GEAR_COLORS[i % GEAR_COLORS.size()])
		if bool(d.get("marks", false)):
			var mark := c + Vector2(0, -rad * 0.62).rotated(spin)
			ci.draw_circle(mark, maxf(2.5, rad * 0.1), Color.WHITE)
			ci.draw_arc(mark, maxf(2.5, rad * 0.1), 0, TAU, 12, INK, 1.2)
		if turn != "" and (i == 0 or str(d.get("arrows", "first")) == "all"):
			_turn_arrow(ci, c, rad + k * 3.6, str(turns[i]) == "cw", INK, maxf(2.0, k * 0.9))
		if not labels.is_empty():
			_text(ci, font, Vector2(c.x, r.end.y - fs * 0.3), str(labels[i]), fs)
		var f := fposmod(-phase, step) / step
		prev_tooth_right = f < 0.25 or f > 0.75
		x += 2.0 * rad


## A gear: `t` teeth round a pitch circle of radius `rad`, a tooth at angle `phase`, and its axle.
static func _gear(ci: CanvasItem, c: Vector2, rad: float, t: int, phase: float, k: float, col: Color) -> void:
	var h := k * 1.6
	var root := rad - h * 0.55
	var tip := rad + h * 0.55
	var step := TAU / t
	var pts := PackedVector2Array()
	for j in t:
		var a := phase + j * step
		for q: Array in [[-0.27, root], [-0.14, tip], [0.14, tip], [0.27, root]]:
			var ang: float = a + float(q[0]) * step
			pts.append(c + Vector2(cos(ang), sin(ang)) * float(q[1]))
	ci.draw_colored_polygon(pts, col)
	pts.append(pts[0])
	ci.draw_polyline(pts, INK, maxf(1.0, k * 0.25), true)
	ci.draw_arc(c, root * 0.72, 0, TAU, 32, col.darkened(0.25), maxf(1.0, k * 0.3), true)
	ci.draw_circle(c, maxf(3.0, rad * 0.12), INK)
	ci.draw_circle(c, maxf(1.5, rad * 0.05), Color("d5d9e0"))


## A curved arrow round `c` over the top: clockwise (on the page) or anticlockwise.
static func _turn_arrow(ci: CanvasItem, c: Vector2, rad: float, cw: bool, col: Color, w: float) -> void:
	var a0 := deg_to_rad(-145.0)
	var a1 := deg_to_rad(-35.0)
	ci.draw_arc(c, rad, a0, a1, 24, col, w, true)
	var at := a1 if cw else a0
	var tip := c + Vector2(cos(at), sin(at)) * rad
	var dir := Vector2(-sin(at), cos(at)) * (1.0 if cw else -1.0)
	_head(ci, tip + dir * w * 1.5, dir, w * 3.2, col)


static func _draw_pulleys(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var sizes: Array = d.sizes
	var crossed := bool(d.get("crossed", false))
	var turn := str(d.get("turn", ""))
	var turns := pulley_turns(turn if turn != "" else "cw", crossed)
	var labels: Array = d.get("labels", [])
	var fs := clampi(int(r.size.y * 0.085), 11, 20)
	var label_h := fs * 1.4 if not labels.is_empty() else 0.0
	var ra := float(sizes[0])
	var rb := float(sizes[1])
	var gap := maxf(ra, rb) * 1.2 + 1.5
	var span := ra + gap + rb   # centre to centre, in size units
	var wide := 2.0 * (ra + rb) + gap
	var k := minf((r.size.x - 24.0) / wide, (r.size.y - label_h - 16.0) / (2.0 * maxf(ra, rb) + 1.2))
	var cy := r.position.y + (r.size.y - label_h) * 0.5 + k * 0.3
	var c1 := Vector2(r.get_center().x - wide * k * 0.5 + ra * k, cy)
	var c2 := c1 + Vector2(span * k, 0)
	var r1 := ra * k
	var r2 := rb * k
	var time := SchoolPicture.time_of(ci)   # owner #94: the wheels turn with the belt (SchoolPictureMotion.pulley_spin)
	for i in 2:
		var c := c1 if i == 0 else c2
		var rad := r1 if i == 0 else r2
		var spin := SchoolPictureMotion.pulley_spin(sizes, i, turn, crossed, time) if time > 0.0 else 0.0
		ci.draw_circle(c, rad, GEAR_COLORS[i])
		ci.draw_arc(c, rad, 0, TAU, 36, INK, 1.5, true)
		ci.draw_arc(c, rad * 0.82, 0, TAU, 36, Color(GEAR_COLORS[i]).darkened(0.3), maxf(1.5, rad * 0.06), true)
		for s in 4:
			var ang := s * PI / 4.0 + spin
			ci.draw_line(c - Vector2(cos(ang), sin(ang)) * rad * 0.8, c + Vector2(cos(ang), sin(ang)) * rad * 0.8,
				Color(GEAR_COLORS[i]).darkened(0.3), maxf(1.0, rad * 0.05))
		ci.draw_circle(c, maxf(3.0, rad * 0.14), INK)
		if turn != "" and (i == 0 or str(d.get("arrows", "first")) == "all"):
			_turn_arrow(ci, c, rad + maxf(8.0, k * 0.35), str(turns[i]) == "cw", INK, maxf(2.0, k * 0.08))
		if not labels.is_empty():
			_text(ci, font, Vector2(c.x, r.end.y - fs * 0.3), str(labels[i]), fs)
	# the belt round both wheels
	var belt := Color("3b3b44")
	var bw := maxf(2.5, k * 0.1)
	var dist := c1.distance_to(c2)
	if crossed:
		var phi := acos(clampf((r1 + r2) / dist, -1.0, 1.0))
		for s: float in [1.0, -1.0]:
			var nrm := Vector2(cos(phi * s), sin(phi * s))
			ci.draw_line(c1 + nrm * r1, c2 - nrm * r2, belt, bw, true)
		ci.draw_arc(c1, r1, phi, TAU - phi, 32, belt, bw, true)
		ci.draw_arc(c2, r2, phi - PI, PI - phi, 32, belt, bw, true)
	else:
		var phi := acos(clampf((r1 - r2) / dist, -1.0, 1.0))
		for s: float in [1.0, -1.0]:
			var nrm := Vector2(cos(phi * s), sin(phi * s))
			ci.draw_line(c1 + nrm * r1, c2 + nrm * r2, belt, bw, true)
		ci.draw_arc(c1, r1, phi, TAU - phi, 32, belt, bw, true)
		ci.draw_arc(c2, r2, -phi, phi, 32, belt, bw, true)


## A crate lifted by one fixed pulley, or by a fixed and a moving pulley (the rope doubled: half the effort).
static func _draw_lift(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var two := int(d.lift) == 2
	var labels := bool(d.get("labels", false))
	var fs := clampi(int(r.size.y * 0.08), 11, 20)
	var s := minf(r.size.y, r.size.x * 0.8)
	var cx := r.get_center().x
	var beam_y := r.position.y + s * 0.08
	var rope := Color("8a5a36")
	var rw := maxf(2.0, s * 0.012)
	ci.draw_rect(Rect2(Vector2(cx - s * 0.45, beam_y - s * 0.05), Vector2(s * 0.9, s * 0.07)), WOOD)
	ci.draw_rect(Rect2(Vector2(cx - s * 0.45, beam_y - s * 0.05), Vector2(s * 0.9, s * 0.07)), INK, false, 1.5)
	var pr := s * 0.09
	var fixed := Vector2(cx + (s * 0.08 if two else 0.0), beam_y + s * 0.14)
	ci.draw_line(Vector2(fixed.x, beam_y + s * 0.02), fixed, INK, rw)
	var crate := Vector2(s * 0.22, s * 0.18)
	var floor_y := r.position.y + s * 0.95
	var pull_x := fixed.x + pr
	var crate_top: float
	if two:
		var moving := Vector2(fixed.x - pr, floor_y - crate.y - s * 0.26)
		var tie := Vector2(moving.x - pr, beam_y + s * 0.02)
		ci.draw_line(tie, Vector2(tie.x, moving.y), rope, rw)   # from the beam down round the moving pulley
		ci.draw_arc(moving, pr, 0, PI, 16, rope, rw, true)
		ci.draw_line(Vector2(moving.x + pr, moving.y), Vector2(fixed.x - pr, fixed.y), rope, rw)
		_wheel(ci, moving, pr)
		crate_top = moving.y + pr + s * 0.08
		ci.draw_line(moving, Vector2(moving.x, crate_top), INK, rw)
		_crate(ci, Rect2(Vector2(moving.x - crate.x * 0.5, crate_top), crate))
		if labels:
			_text(ci, font, Vector2(moving.x - pr - s * 0.24, moving.y + fs * 0.3), "moving pulley", fs)
			_text(ci, font, Vector2(moving.x, crate_top + crate.y + fs * 1.1), "load", fs)
	else:
		var left := fixed.x - pr
		crate_top = floor_y - crate.y - s * 0.12
		ci.draw_line(Vector2(left, fixed.y), Vector2(left, crate_top), rope, rw)
		_crate(ci, Rect2(Vector2(left - crate.x * 0.5, crate_top), crate))
		if labels:
			_text(ci, font, Vector2(left, crate_top + crate.y + fs * 1.1), "load", fs)
	ci.draw_arc(fixed, pr, PI, TAU, 16, rope, rw, true)
	_wheel(ci, fixed, pr)
	var pull_end := Vector2(pull_x, floor_y - s * 0.22)
	ci.draw_line(Vector2(pull_x, fixed.y), pull_end, rope, rw)
	_arrow(ci, pull_end + Vector2(0, s * 0.02), pull_end + Vector2(0, s * 0.16), RED, maxf(2.5, s * 0.016))
	if labels:
		_text(ci, font, Vector2(pull_x + s * 0.16, pull_end.y + s * 0.1), "effort", fs)
		_text(ci, font, Vector2(fixed.x + pr + s * 0.24, fixed.y + fs * 0.3), "fixed pulley", fs)
	ci.draw_line(Vector2(r.position.x, floor_y), Vector2(r.end.x, floor_y), INK, 2.0)


static func _wheel(ci: CanvasItem, c: Vector2, rad: float) -> void:
	ci.draw_circle(c, rad * 0.86, GEAR_COLORS[1])
	ci.draw_arc(c, rad * 0.86, 0, TAU, 24, INK, 1.5, true)
	ci.draw_circle(c, maxf(2.0, rad * 0.2), INK)


static func _crate(ci: CanvasItem, box: Rect2) -> void:
	ci.draw_rect(box, WOOD)
	ci.draw_rect(box, INK, false, 1.5)
	ci.draw_line(box.position, box.end, Color(INK, 0.5), 1.0)
	ci.draw_line(Vector2(box.end.x, box.position.y), Vector2(box.position.x, box.end.y), Color(INK, 0.5), 1.0)


# --- cam -----------------------------------------------------------------------------------------------------------

static func _draw_cam(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var shape := str(d.shape)
	var time := SchoolPicture.time_of(ci)   # owner #94: the cam turns and the follower rides it
	var turn := SchoolPictureMotion.cam_turn(d, time) if time > 0.0 else float(d.get("turn", 0))
	var graph := bool(d.get("graph", false))
	var labels := bool(d.get("labels", false))
	var fs := clampi(int(r.size.y * 0.075), 10, 18)
	var area := Rect2(r.position, Vector2(r.size.x * (0.48 if graph else 1.0), r.size.y))
	var big := 1.4   # the largest radius of any cam, in cam radii
	if r.size.y < 110.0 and not graph and not labels:   # a small picture (a choice): the cam's shape alone, big
		_cam_shape(ci, r.get_center() + Vector2(0, r.size.y * 0.06), minf(r.size.x, r.size.y) / (2.0 * 1.5), shape, turn)
		return
	var rad := minf(area.size.y / (2.0 * big + 2.2), area.size.x / (2.0 * big + (3.6 if labels else 1.2)))
	var axle := Vector2(area.get_center().x - (rad * 0.6 if labels else 0.0), area.end.y - rad * (big + 0.35))
	# the toy's frame: a box round the cam, its top a guide with a hole for the follower
	var box := Rect2(axle - Vector2(rad * (big + 0.25), rad * (big + 0.3)), Vector2(rad * (big + 0.25) * 2, rad * (big + 0.3) + rad * (big + 0.25)))
	ci.draw_rect(box, Color("f3ead2"))
	ci.draw_rect(box, WOOD.darkened(0.2), false, maxf(2.0, rad * 0.08))
	_cam_shape(ci, axle, rad, shape, turn)
	# the follower: a rod resting on the cam's top, through the guide, a flag on top
	var h := cam_height(shape, turn)
	var foot := axle + Vector2(0, -h * rad)
	var rod_top := Vector2(axle.x, foot.y - rad * 1.5)
	var rw := maxf(3.0, rad * 0.12)
	ci.draw_line(foot, rod_top, Color("6b7a8f"), rw)
	ci.draw_line(foot + Vector2(-rad * 0.22, 0), foot + Vector2(rad * 0.22, 0), Color("6b7a8f"), rw)
	var flag := PackedVector2Array([rod_top, rod_top + Vector2(rad * 0.55, rad * 0.18), rod_top + Vector2(0, rad * 0.36)])
	ci.draw_colored_polygon(flag, ORANGE)
	ci.draw_polyline(PackedVector2Array([flag[0], flag[1], flag[2]]), INK, 1.2, true)
	var guide_y := box.position.y
	ci.draw_rect(Rect2(Vector2(axle.x - rw * 1.4, guide_y - rad * 0.07), Vector2(rw * 2.8, rad * 0.14)), INK, false, 1.5)
	if labels:
		var lx := box.end.x + rad * 0.2
		_label_at(ci, font, Vector2(lx, rod_top.y + rad * 0.55), Vector2(axle.x + rw, rod_top.y + rad * 0.55), "follower", fs)
		_label_at(ci, font, Vector2(lx, guide_y + rad * 0.45), Vector2(axle.x + rw * 1.4, guide_y), "guide", fs)
		_label_at(ci, font, Vector2(lx, axle.y - rad * 0.3), axle + Vector2(rad * 0.5, -rad * 0.3), "cam", fs)
		_label_at(ci, font, Vector2(lx, axle.y + rad * 0.9), axle + Vector2(rad * 0.1, rad * 0.1), "axle", fs)
	if graph:
		var g := Rect2(Vector2(r.position.x + r.size.x * 0.56, r.position.y + fs * 1.6), Vector2(r.size.x * 0.42,
			r.size.y - fs * 3.4))
		ci.draw_line(g.position, Vector2(g.position.x, g.end.y), INK, 2.0)
		ci.draw_line(Vector2(g.position.x, g.end.y), g.end, INK, 2.0)
		var lo := 0.6
		var hi := 1.45
		var line := PackedVector2Array()
		for i in 73:   # the last point is a whole turn: the snail's sudden drop shows as a straight fall
			var t := i * 5.0
			var y := g.end.y - (cam_height(shape, minf(t, 359.9)) - lo) / (hi - lo) * g.size.y
			line.append(Vector2(g.position.x + g.size.x * t / 360.0, y))
		line.append(Vector2(g.end.x, g.end.y - (cam_height(shape, 0.0) - lo) / (hi - lo) * g.size.y))
		ci.draw_polyline(line, BLUE, 2.5, true)
		var now := Vector2(g.position.x + g.size.x * turn / 360.0, g.end.y - (h - lo) / (hi - lo) * g.size.y)
		ci.draw_circle(now, 5.0, ORANGE)
		ci.draw_arc(now, 5.0, 0, TAU, 12, INK, 1.2)
		_text(ci, font, Vector2(g.position.x + fs * 2.2, g.position.y - fs * 0.5), "height", fs)
		_text(ci, font, Vector2(g.position.x, g.end.y + fs * 1.2), "0", fs)
		_text(ci, font, Vector2(g.end.x - fs, g.end.y + fs * 1.2), "1 turn", fs)


## A cam's outline turned `turn` degrees clockwise about its axle at `axle`, `rad` pixels a cam radius, and the arrow of
## its turn.
static func _cam_shape(ci: CanvasItem, axle: Vector2, rad: float, shape: String, turn: float) -> void:
	var pts := PackedVector2Array()
	var steps := 90
	for i in steps + 1:
		var theta := 90.0 + i * 360.0 / steps - (0.001 if i == steps else 0.0)
		var w := deg_to_rad(theta - turn)
		pts.append(axle + Vector2(cos(w), -sin(w)) * cam_radius(shape, theta) * rad)
	ci.draw_colored_polygon(pts, WOOD)
	pts.append(pts[0])
	ci.draw_polyline(pts, INK, maxf(1.5, rad * 0.05), true)
	ci.draw_circle(axle, maxf(3.0, rad * 0.12), INK)
	ci.draw_circle(axle, maxf(1.5, rad * 0.05), Color("d5d9e0"))
	_turn_arrow(ci, axle, rad * 1.52, true, Color(INK, 0.6), maxf(1.5, rad * 0.06))


static func _label_at(ci: CanvasItem, font: Font, at: Vector2, to: Vector2, text: String, fs: int) -> void:
	ci.draw_line(Vector2(at.x - 3.0, at.y - fs * 0.35), to, Color(INK, 0.55), 1.2)
	ci.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)


# --- bridge --------------------------------------------------------------------------------------------------------

static func _draw_bridge(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var type := str(d.type)
	var spans := int(d.get("spans", 1))
	var labels := bool(d.get("labels", false))
	var forces := bool(d.get("forces", false))
	var mark := str(d.get("mark", ""))
	var fs := clampi(int(r.size.y * 0.075), 10, 18)
	var col := func(part: String, base: Color) -> Color: return ORANGE if part == mark else base
	# the river between two banks; an arch needs room under its deck, towers above theirs
	var deck_y := r.position.y + r.size.y * float({"beam": 0.52, "truss": 0.56, "arch": 0.4, "suspension": 0.6,
		"cable_stayed": 0.6}[type])
	var water_y := r.position.y + r.size.y * (0.88 if type == "arch" else 0.78)
	var left := r.position.x + r.size.x * 0.1
	var right := r.end.x - r.size.x * 0.1
	var bank_l := PackedVector2Array([Vector2(r.position.x, deck_y + 4), Vector2(left, deck_y + 4),
		Vector2(left + r.size.x * 0.05, r.end.y), Vector2(r.position.x, r.end.y)])
	var bank_r := PackedVector2Array([Vector2(r.end.x, deck_y + 4), Vector2(right, deck_y + 4),
		Vector2(right - r.size.x * 0.05, r.end.y), Vector2(r.end.x, r.end.y)])
	ci.draw_rect(Rect2(Vector2(left, water_y), Vector2(right - left, r.end.y - water_y)), WATER)
	ci.draw_colored_polygon(bank_l, BANK)
	ci.draw_colored_polygon(bank_r, BANK)
	var deck_h := maxf(5.0, r.size.y * 0.045)
	var lw := maxf(2.0, r.size.y * 0.018)
	var span_w := (right - left) / spans
	var key_at := r.position + Vector2(4.0, fs)   # the forces' key: top left, or between the towers
	match type:
		"beam", "truss":
			for s in range(1, spans):   # the piers
				var px := left + s * span_w
				var pier := Rect2(Vector2(px - deck_h * 0.8, deck_y + deck_h), Vector2(deck_h * 1.6, r.end.y - deck_y - deck_h))
				ci.draw_rect(pier, col.call("pier", STONE))
				ci.draw_rect(pier, INK, false, 1.2)
				if labels and s == 1:
					_label_at(ci, font, Vector2(px + deck_h * 1.5, water_y + fs * 1.3), Vector2(px + deck_h * 0.8,
						water_y + fs * 0.4), "pier", fs)
			var mid_x := left + (int(spans / 2.0) + 0.5) * span_w   # the forces on a middle span
			var th := r.size.y * 0.2
			if type == "truss":
				for s in spans:
					var x0 := left + s * span_w
					var n := 4
					var pts := PackedVector2Array()
					for j in n + 1:
						pts.append(Vector2(x0 + span_w * j / n, deck_y))
						if j < n:
							pts.append(Vector2(x0 + span_w * (j + 0.5) / n, deck_y - th))
					ci.draw_polyline(pts, col.call("truss", STEEL), lw, true)
					ci.draw_line(Vector2(x0 + span_w * 0.5 / n, deck_y - th), Vector2(x0 + span_w * (n - 0.5) / n,
						deck_y - th), col.call("truss", STEEL), lw)
				if labels:
					_label_at(ci, font, Vector2(left + span_w * 0.5 + fs, deck_y - th - fs * 0.8), Vector2(left + span_w * 0.5,
						deck_y - th), "truss", fs)
			if forces:
				var top_y := deck_y - (th if type == "truss" else 0.0) - lw * 3
				_force_pair(ci, Vector2(mid_x, top_y), span_w * 0.16, true)
				_force_pair(ci, Vector2(mid_x, deck_y + deck_h + lw * 3), span_w * 0.16, false)
		"arch":
			var mid := (left + right) * 0.5
			var half := (right - left) * 0.4
			var band := maxf(8.0, r.size.y * 0.075)
			var rise := water_y - deck_y - deck_h - band * 0.6
			var outer := PackedVector2Array()
			var inner := PackedVector2Array()
			for i in 33:
				var a := PI * i / 32.0
				outer.append(Vector2(mid - cos(a) * (half + band * 0.5), water_y - sin(a) * (rise + band * 0.5)))
				inner.append(Vector2(mid - cos(a) * (half - band * 0.5), water_y - sin(a) * (rise - band * 0.5)))
			for i in range(3, 30, 3):   # posts from the arch up to the deck
				var p := outer[i]
				ci.draw_line(p, Vector2(p.x, deck_y + deck_h), STONE.darkened(0.25), lw)
			var arch_poly := outer.duplicate()
			for i in range(inner.size() - 1, -1, -1):
				arch_poly.append(inner[i])
			ci.draw_colored_polygon(arch_poly, col.call("arch", Color("b9aa8f")))
			for i in range(2, 31, 2):   # the stones' joints
				ci.draw_line(inner[i], outer[i], INK, 1.0)
			ci.draw_polyline(outer, INK, 1.2, true)
			ci.draw_polyline(inner, INK, 1.2, true)
			var key := PackedVector2Array([outer[15], outer[17], inner[17], inner[15]])
			ci.draw_colored_polygon(key, col.call("keystone", Color("8c7b5e")))
			key.append(key[0])
			ci.draw_polyline(key, INK, 1.2, true)
			for side: float in [-1.0, 1.0]:   # the abutments the arch pushes into
				var ab := Rect2(Vector2(mid + side * half - band * 1.1, water_y - band * 0.4), Vector2(band * 2.2, band * 1.2))
				ci.draw_rect(ab, col.call("abutment", STONE.darkened(0.3)))
				ci.draw_rect(ab, INK, false, 1.2)
			if labels:
				_label_at(ci, font, Vector2(mid + half * 0.25, water_y - rise * 0.25), inner[24], "arch", fs)
				_label_at(ci, font, Vector2(mid + half * 0.3, deck_y - fs * 0.7), (inner[16] + outer[16]) * 0.5, "keystone", fs)
				_label_at(ci, font, Vector2(mid - half + band * 1.8, water_y + fs * 1.1), Vector2(mid - half + band * 0.9,
					water_y + band * 0.4), "abutment", fs)
			if forces:
				for side: float in [-1.0, 1.0]:
					var p := Vector2(mid + side * half * 0.8, water_y - rise * 0.62)
					var dir := Vector2(side * 0.55, 1.0).normalized()
					_arrow(ci, p - dir * r.size.y * 0.09, p + dir * r.size.y * 0.04, SQUASH, lw * 1.2)
		"suspension":
			var t1 := left + (right - left) * 0.2
			var t2 := right - (right - left) * 0.2
			var top := r.position.y + r.size.y * 0.16
			for tx: float in [t1, t2]:
				var tower := Rect2(Vector2(tx - deck_h * 0.7, top), Vector2(deck_h * 1.4, r.end.y - top))
				ci.draw_rect(tower, col.call("tower", STEEL.lightened(0.2)))
				ci.draw_rect(tower, INK, false, 1.2)
			var cable := PackedVector2Array()
			var sag := deck_y - deck_h * 1.5
			for i in 41:   # anchor to tower, a sag between the towers, tower to anchor
				var x := left + (right - left) * i / 40.0
				var y: float
				if x < t1:
					y = deck_y + deck_h - (x - left) / (t1 - left) * (deck_y + deck_h - top)
				elif x > t2:
					y = deck_y + deck_h - (right - x) / (right - t2) * (deck_y + deck_h - top)
				else:
					var u := (x - t1) / (t2 - t1) * 2.0 - 1.0
					y = sag - (sag - top) * u * u
				cable.append(Vector2(x, y))
			ci.draw_polyline(cable, col.call("cable", Color("c0392b")), lw, true)
			for i in range(1, 40):   # hangers
				var p := cable[i]
				if p.x > t1 + 4 and p.x < t2 - 4 and i % 2 == 0:
					ci.draw_line(p, Vector2(p.x, deck_y), col.call("cable", Color("c0392b")).lightened(0.3), 1.2)
			if labels:
				_label_at(ci, font, Vector2(t2 + deck_h * 1.6, top + fs * 1.4), Vector2(t2 + deck_h * 0.7, top + fs), "tower", fs)
				_label_at(ci, font, Vector2(t1 + deck_h * 2.2, top + fs * 1.4), cable[12], "cable", fs)
			if forces:
				_force_pair(ci, Vector2((t1 + t2) * 0.5, sag - lw * 5), (t2 - t1) * 0.1, false)
				_arrow(ci, Vector2(t1, top - r.size.y * 0.13), Vector2(t1, top - r.size.y * 0.01), SQUASH, lw * 1.2)
				key_at = Vector2((t1 + t2) * 0.5 - fs * 3.0, r.position.y + fs)
		"cable_stayed":
			var tx := (left + right) * 0.5
			var top := r.position.y + r.size.y * 0.16
			var tower := Rect2(Vector2(tx - deck_h * 0.7, top), Vector2(deck_h * 1.4, r.end.y - top))
			ci.draw_rect(tower, col.call("tower", STEEL.lightened(0.2)))
			ci.draw_rect(tower, INK, false, 1.2)
			for i in 5:
				var reach := (right - left) * (0.1 + 0.085 * i)
				var from := Vector2(tx, top + r.size.y * (0.03 + 0.03 * i))
				for side: float in [-1.0, 1.0]:
					ci.draw_line(from, Vector2(tx + side * reach, deck_y), col.call("cable", Color("c0392b")),
						maxf(1.2, lw * 0.6), true)
			if labels:
				_label_at(ci, font, Vector2(tx + deck_h * 1.5, top + fs * 0.2), Vector2(tx + deck_h * 0.7, top), "tower", fs)
				_label_at(ci, font, Vector2(right - fs * 3.0, deck_y - r.size.y * 0.2), Vector2(right - (right - left) * 0.16,
					deck_y - r.size.y * 0.05), "cable", fs)
			if forces:
				_arrow(ci, Vector2(tx, top - r.size.y * 0.13), Vector2(tx, top - r.size.y * 0.01), SQUASH, lw * 1.2)
				var a := Vector2(tx, top + r.size.y * 0.15)
				var b := Vector2(tx - (right - left) * 0.44, deck_y)
				var dir := (a - b).normalized()
				var p := a.lerp(b, 0.5) + Vector2(0, -lw * 3)
				_arrow(ci, p + dir * r.size.y * 0.02, p + dir * r.size.y * 0.1, STRETCH, lw * 1.2)
				_arrow(ci, p - dir * r.size.y * 0.02, p - dir * r.size.y * 0.1, STRETCH, lw * 1.2)
	# the deck over everything
	var deck := Rect2(Vector2(left - r.size.x * 0.04, deck_y), Vector2(right - left + r.size.x * 0.08, deck_h))
	ci.draw_rect(deck, col.call("deck", Color("59606e")))
	ci.draw_rect(deck, INK, false, 1.2)
	if labels:
		_label_at(ci, font, Vector2(right - fs * 2.2, deck_y + deck_h + fs * 1.3), Vector2(right - fs * 2.4, deck_y + deck_h),
			"deck", fs)
	if d.has("load"):
		var lx := left + (right - left) * float(d.load)
		var box := Rect2(Vector2(lx - r.size.y * 0.06, deck_y - r.size.y * 0.1), Vector2(r.size.y * 0.12, r.size.y * 0.1))
		_crate(ci, box)
	if forces:   # the key
		_force_pair(ci, key_at + Vector2(fs * 1.3, -fs * 0.35), fs * 0.9, true)
		ci.draw_string(font, key_at + Vector2(fs * 3.0, 0), "squash", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, SQUASH)
		_force_pair(ci, key_at + Vector2(fs * 1.3, fs * 0.9), fs * 0.9, false)
		ci.draw_string(font, key_at + Vector2(fs * 3.0, fs * 1.25), "stretch", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, STRETCH)


## Two arrows along a line at `c`: pointing in (squash, red) or out (stretch, blue).
static func _force_pair(ci: CanvasItem, c: Vector2, half: float, squash: bool) -> void:
	var w := maxf(2.0, half * 0.12)
	if squash:
		_arrow(ci, c - Vector2(half * 1.6, 0), c - Vector2(half * 0.2, 0), SQUASH, w)
		_arrow(ci, c + Vector2(half * 1.6, 0), c + Vector2(half * 0.2, 0), SQUASH, w)
	else:
		_arrow(ci, c - Vector2(half * 0.2, 0), c - Vector2(half * 1.6, 0), STRETCH, w)
		_arrow(ci, c + Vector2(half * 0.2, 0), c + Vector2(half * 1.6, 0), STRETCH, w)


# --- views ---------------------------------------------------------------------------------------------------------

static func _draw_views(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var rows: Array = d.heights
	var show := str(d.show)
	var fs := clampi(int(r.size.y * 0.08), 10, 20)
	var label := bool(d.get("label", false))
	var area := Rect2(r.position, r.size - Vector2(0, fs * 1.5 if label or show != "model" else fs * 1.3))
	var names := {"model": "", "plan": "plan (from above)", "front": "front view", "side": "side view (from the right)"}
	match show:
		"model":
			_draw_model(ci, font, area, rows, fs)
		"plan":
			var cols := str(rows[0]).length()
			var s := minf(area.size.x / (cols + 1.0), area.size.y / (rows.size() + 0.6))
			var o := area.get_center() - Vector2(cols, rows.size()) * s * 0.5
			for i in rows.size():
				for c in cols:
					var h := int(str(rows[i])[c])
					var cell := Rect2(o + Vector2(c, i) * s, Vector2(s, s))
					ci.draw_rect(cell, TOP if h > 0 else Color.WHITE)
					ci.draw_rect(cell, INK, false, 1.5)
					if h > 0 and bool(d.get("numbers", false)):
						_text(ci, font, cell.get_center() + Vector2(0, s * 0.18), str(h), clampi(int(s * 0.5), 10, 30))
			_text_col(ci, font, Vector2(area.get_center().x, o.y + rows.size() * s + fs * 1.05), "front", fs,
				Color(INK, 0.6))
		"front", "side":
			var tops: Array = front_view(rows) if show == "front" else side_view(rows)
			var high := 1
			for t: Variant in tops:
				high = maxi(high, int(t))
			var s := minf(area.size.x / (tops.size() + 1.0), area.size.y / (high + 0.5))
			var o := Vector2(area.get_center().x - tops.size() * s * 0.5, area.end.y - s * 0.2)
			for c in tops.size():
				for k in int(tops[c]):
					var cell := Rect2(o + Vector2(c * s, -(k + 1) * s), Vector2(s, s))
					ci.draw_rect(cell, FRONT if show == "front" else SIDE)
					ci.draw_rect(cell, INK, false, 1.5)
			ci.draw_line(o - Vector2(s * 0.3, 0), o + Vector2((tops.size() + 0.3) * s, 0), INK, 2.0)
	if label and show != "model":
		_text(ci, font, Vector2(r.get_center().x, r.end.y - fs * 0.2), str(names[show]), fs)


## The blocks drawn in 3D from the front right: the front row nearest, "front" written under it.
static func _draw_model(ci: CanvasItem, font: Font, area: Rect2, rows: Array, fs: int) -> void:
	var cols := str(rows[0]).length()
	var depth := rows.size()
	var high := 1
	for row: Variant in rows:
		for ch in str(row):
			high = maxi(high, int(ch))
	var c30 := cos(PI / 6.0)
	# ex: one step right (x), ey: one step back (y), ez: one step up
	var span_w := (cols + depth) * c30
	var span_h := (cols + depth) * 0.5 + high
	var s := minf(area.size.x / (span_w + 0.4), area.size.y / (span_h + 0.4))
	var ex := Vector2(c30, 0.5) * s
	var ey := Vector2(c30, -0.5) * s
	var ez := Vector2(0, -1) * s
	var origin := area.get_center() - (ex * cols + ey * depth + ez * high) * 0.5
	var at := func(x: float, y: float, z: float) -> Vector2: return origin + ex * x + ey * y + ez * z
	# the ground: every square of the model's base
	for x in cols + 1:
		ci.draw_line(at.call(x, 0, 0), at.call(x, depth, 0), Color(INK, 0.25), 1.0)
	for y in depth + 1:
		ci.draw_line(at.call(0, y, 0), at.call(cols, y, 0), Color(INK, 0.25), 1.0)
	var cubes: Array = []
	for i in depth:
		var y := depth - 1 - i   # row 0 is at the back
		for x in cols:
			for z in int(str(rows[i])[x]):
				cubes.append(Vector3i(x, y, z))
	cubes.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		var ka := a.x - a.y + a.z
		var kb := b.x - b.y + b.z
		return ka < kb if ka != kb else a.z < b.z)
	for cb: Vector3i in cubes:
		var x := float(cb.x)
		var y := float(cb.y)
		var z := float(cb.z)
		var top := PackedVector2Array([at.call(x, y, z + 1), at.call(x + 1, y, z + 1), at.call(x + 1, y + 1, z + 1),
			at.call(x, y + 1, z + 1)])
		var front := PackedVector2Array([at.call(x, y, z), at.call(x + 1, y, z), at.call(x + 1, y, z + 1),
			at.call(x, y, z + 1)])
		var right := PackedVector2Array([at.call(x + 1, y, z), at.call(x + 1, y + 1, z), at.call(x + 1, y + 1, z + 1),
			at.call(x + 1, y, z + 1)])
		for face: Array in [[front, FRONT], [right, SIDE], [top, TOP]]:
			var poly: PackedVector2Array = face[0]
			ci.draw_colored_polygon(poly, face[1])
			var loop := poly.duplicate()
			loop.append(poly[0])
			ci.draw_polyline(loop, INK, 1.3, true)
	var mid: Vector2 = at.call(cols * 0.5, 0, 0)
	_text_col(ci, font, mid + Vector2(-s * 0.35, fs * 1.2), "front", fs, Color(INK, 0.6))


# --- compass -------------------------------------------------------------------------------------------------------

static func _draw_compass(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var n := int(d.get("points", 8))
	var names: Array = POINTS[n]
	var degrees := bool(d.get("degrees", false))
	var c := r.get_center()
	var rad := minf(r.size.x, r.size.y) * 0.5 - 2.0
	var fs := clampi(int(rad * 0.2), 10, 24)
	ci.draw_circle(c, rad, Color("f7f1e1"))
	ci.draw_arc(c, rad, 0, TAU, 64, INK, maxf(2.0, rad * 0.03), true)
	for deg in range(0, 360, 10):   # ticks every 10 degrees, longer every 45 and 90
		var a := deg_to_rad(deg - 90.0)
		var long := 0.12 if deg % 90 == 0 else (0.08 if deg % 45 == 0 else 0.04)
		var dir := Vector2(cos(a), sin(a))
		ci.draw_line(c + dir * rad * (0.98 - long), c + dir * rad * 0.98, INK, 1.5 if deg % 45 == 0 else 1.0)
	# the rose's points (smaller when the degrees are written inside it)
	var ring := rad * (0.34 if degrees else 0.72)
	for i in 8:
		var a := deg_to_rad(i * 45.0 - 90.0)
		var main := i % 2 == 0
		var len := ring * (0.78 if main else 0.5)
		var dir := Vector2(cos(a), sin(a))
		var side := Vector2(-dir.y, dir.x) * ring * (0.1 if main else 0.07)
		var tip := c + dir * len
		ci.draw_colored_polygon(PackedVector2Array([c + side, tip, c - side]), Color("c9d6ea") if main else Color("e2e8f2"))
		ci.draw_polyline(PackedVector2Array([c + side, tip, c - side]), Color(INK, 0.5), 1.0, true)
	for i in names.size():
		var deg := i * 360.0 / names.size()
		var a := deg_to_rad(deg - 90.0)
		var dir := Vector2(cos(a), sin(a))
		var text := "?" if str(d.get("hide", "")) == str(names[i]) else str(names[i])
		var tfs := int(fs * (0.75 if str(names[i]).length() == 2 else 1.0))
		_text_col(ci, font, c + dir * rad * 0.8 + Vector2(0, tfs * 0.36), text, tfs, RED if str(names[i]) == "N" else INK)
		if degrees:
			var dfs := int(fs * 0.62)
			_text_col(ci, font, c + dir * rad * 0.56 + Vector2(0, dfs * 0.36), "%d°" % int(deg), dfs, Color(INK, 0.75))
	if bool(d.get("needle", false)):
		var nd := rad * (0.3 if degrees else 0.5)
		var w := rad * 0.08
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-w, 0), c + Vector2(0, -nd), c + Vector2(w, 0)]), RED)
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-w, 0), c + Vector2(0, nd), c + Vector2(w, 0)]),
			Color.WHITE)
		ci.draw_polyline(PackedVector2Array([c + Vector2(-w, 0), c + Vector2(0, -nd), c + Vector2(w, 0),
			c + Vector2(0, nd), c + Vector2(-w, 0)]), INK, 1.2, true)
	if d.has("bearing"):
		var a := deg_to_rad(float(d.bearing) - 90.0)
		var dir := Vector2(cos(a), sin(a))
		_arrow(ci, c, c + dir * rad * (0.4 if degrees else 0.66), ORANGE, maxf(3.0, rad * 0.05))
	ci.draw_circle(c, maxf(3.0, rad * 0.04), INK)


# --- food web ------------------------------------------------------------------------------------------------------

static func _draw_web(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var nodes: Array = d.nodes
	var links: Array = d.links
	var eats := {}
	for l: Array in links:
		eats[int(l[1])] = true
	var cw := r.size.x / WEB_COLS
	var rh := r.size.y / WEB_ROWS
	var bw := cw * 0.86
	var bh := minf(rh * 0.62, 40.0)
	var widest := 1.0   # the longest name at size 20, so every name fits its box
	for nd: Array in nodes:
		widest = maxf(widest, font.get_string_size(str(nd[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x)
	var fs := clampi(int(minf(bh * 0.5, 20.0 * bw * 0.88 / widest)), 8, 20)
	var boxes: Array[Rect2] = []
	for nd: Array in nodes:
		var cc := r.position + Vector2((int(nd[1]) + 0.5) * cw, (int(nd[2]) + 0.5) * rh)
		boxes.append(Rect2(cc - Vector2(bw, bh) * 0.5, Vector2(bw, bh)))
	for l: Array in links:
		var a := boxes[int(l[0])]
		var b := boxes[int(l[1])]
		var from := _box_edge(a, b.get_center())
		var to := _box_edge(b, a.get_center())
		_arrow(ci, from, to, Color(INK, 0.8), 2.0)
	var time := SchoolPicture.time_of(ci)   # owner #94: energy runs along every arrow, from the food to its eater
	var show := SchoolPictureMotion.fade_in(time)
	if show > 0.0:
		for li in links.size():
			var l: Array = links[li]
			var from := _box_edge(boxes[int(l[0])], boxes[int(l[1])].get_center())
			var to := _box_edge(boxes[int(l[1])], boxes[int(l[0])].get_center())
			var f := fposmod(time / SchoolPictureMotion.WEB_TRIP + li * 0.37, 1.0)
			var dot := from.lerp(to - (to - from).normalized() * 5.0, f)
			ci.draw_circle(dot, 4.5, Color(SchoolPictureMotion.GOLD, show))
			ci.draw_arc(dot, 4.5, 0, TAU, 12, Color(INK, 0.7 * show), 1.2)
	for i in nodes.size():
		var box := boxes[i]
		var style := StyleBoxFlat.new()
		style.bg_color = ORANGE.lightened(0.4) if d.has("mark") and int(d.mark) == i else \
			(ANIMAL if eats.has(i) else PLANT)
		style.set_corner_radius_all(int(bh * 0.3))
		style.border_color = INK
		style.set_border_width_all(2)
		ci.draw_style_box(style, box)
		var text := "?" if d.has("hide") and int(d.hide) == i else str(nodes[i][0])
		_text(ci, font, box.get_center() + Vector2(0, fs * 0.36), text, fs)


## Where the line from `box`'s centre to `to` leaves the box.
static func _box_edge(box: Rect2, to: Vector2) -> Vector2:
	var c := box.get_center()
	var v := to - c
	if v.length() < 0.001:
		return c
	var sx := (box.size.x * 0.5) / absf(v.x) if absf(v.x) > 0.001 else INF
	var sy := (box.size.y * 0.5) / absf(v.y) if absf(v.y) > 0.001 else INF
	return c + v * minf(minf(sx, sy), 1.0)


# --- lying ---------------------------------------------------------------------------------------------------------

static func _draw_lying(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var back := str(d.pose) == "back"
	var pose: Dictionary = LIE[str(d.pose)]
	var labels := bool(d.get("labels", false))
	var fs := clampi(int(r.size.y * 0.075), 10, 18)
	var room := Vector2(r.size.x, r.size.y - (fs * 3.2 if labels else 0.0))
	var unit := minf(room.x * 0.86, room.y * 1.7)
	var mid := Vector2(r.get_center().x - unit * 0.5, r.position.y + (fs * 1.6 if labels else 0.0) + room.y * 0.6)
	var at := func(k: String) -> Vector2:
		var p: Vector2 = pose[k]
		return mid + Vector2(p.x, -p.y) * unit
	var mat := Rect2(mid + Vector2(-unit * 0.04, -unit * 0.34), Vector2(unit * 1.08, unit * 0.5))
	var style := StyleBoxFlat.new()
	style.bg_color = MAT
	style.set_corner_radius_all(int(unit * 0.03))
	ci.draw_style_box(style, mat)
	var w := maxf(3.0, unit * 0.026)
	var neck: Vector2 = at.call("neck")
	var hip: Vector2 = at.call("hip")
	var shoulder := neck.lerp(hip, 0.12)
	var limb := func(from: Vector2, a: String, b: String) -> void:
		ci.draw_polyline(PackedVector2Array([from, at.call(a), at.call(b)]), INK, w, true)
		ci.draw_circle(at.call(b), w * 0.6, INK)
	for pair: Array in [["le", "lh"], ["re", "rh"]]:
		limb.call(shoulder, pair[0], pair[1])
	for pair: Array in [["lk", "lf"], ["rk", "rf"]]:
		limb.call(hip, pair[0], pair[1])
	ci.draw_line(neck, hip, INK, w * 1.3, true)
	var head: Vector2 = at.call("head")
	var hr := unit * 0.06
	ci.draw_circle(head, hr, SKIN)
	ci.draw_arc(head, hr, 0, TAU, 24, INK, w * 0.6, true)
	var chin: Vector2
	if back:   # the face looks up at us, the top of the head to the left: eyes, and a smile towards the chin
		for s: float in [-1.0, 1.0]:
			ci.draw_circle(head + Vector2(-hr * 0.2, s * hr * 0.38), maxf(1.5, hr * 0.12), INK)
		ci.draw_arc(head + Vector2(hr * 0.1, 0), hr * 0.45, -0.9, 0.9, 10, INK, maxf(1.0, w * 0.35), true)
		chin = head + Vector2(hr, 0)
	else:   # on their side, the face towards the top of the page, the chin tilted up
		ci.draw_circle(head + Vector2(-hr * 0.15, -hr * 0.45), maxf(1.5, hr * 0.12), INK)
		var nose := Vector2(-0.45, -1.0).normalized()
		ci.draw_line(head + nose * hr, head + nose * hr * 1.35, INK, maxf(1.5, w * 0.5), true)
		chin = head + Vector2(0.3, -1.0).normalized() * hr
	if labels:
		var words: Array = ["head tilted back", "chin lifted", "arms by the sides"] if back else \
			["head tilted back", "hand under cheek", "top knee bent"]
		var targets: Array = [head + Vector2(-hr, 0), chin, at.call("lh")] if back else [head + Vector2(-hr * 0.7, -hr * 0.7),
			at.call("lh"), at.call("lk")]
		var spots: Array = [r.position + Vector2(0, fs), Vector2(r.position.x, r.end.y - fs * 0.3),
			Vector2(r.end.x, r.position.y + fs)]
		for i in 3:
			var tw := font.get_string_size(str(words[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var p: Vector2 = spots[i]
			var x := p.x - tw if i == 2 else p.x
			ci.draw_string(font, Vector2(x, p.y), str(words[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
			var from := Vector2(x + tw * 0.5, p.y + (fs * 0.25 if i != 1 else -fs * 0.95))
			ci.draw_line(from, targets[i], Color(INK, 0.55), 1.2, true)


# --- helpers -------------------------------------------------------------------------------------------------------

## A straight arrow from `a` to `b`, its head at `b`.
static func _arrow(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var dir := (b - a).normalized()
	if dir == Vector2.ZERO:
		return
	var head := w * 3.2
	ci.draw_line(a, b - dir * head * 0.8, col, w, true)
	_head(ci, b, dir, head, col)


static func _head(ci: CanvasItem, tip: Vector2, dir: Vector2, size: float, col: Color) -> void:
	var side := Vector2(-dir.y, dir.x) * size * 0.55
	ci.draw_colored_polygon(PackedVector2Array([tip, tip - dir * size + side, tip - dir * size - side]), col)


static func _text(ci: CanvasItem, font: Font, center_base: Vector2, text: String, fs: int) -> void:
	_text_col(ci, font, center_base, text, fs, INK)


static func _text_col(ci: CanvasItem, font: Font, center_base: Vector2, text: String, fs: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	ci.draw_string(font, Vector2(center_base.x - w * 0.5, center_base.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
