class_name SchoolPictureG8Hum
extends RefCounted
## Owner #70, #73 and #111, grade 8 history, geography and citizenship (research §6.8): the picture kinds they add, drawn
## from data onto a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only, no new art;
## the font has no arrows, so they are drawn). Diagrams name their parts with grade 7's labels (SchoolPictureG7Hum's
## bands along the top and bottom, each with a line to its part); `mark` (a part) is orange and `hide` (a part) shows "?".
## Kinds and fields:
## - steam_engine {labels?, mark?, hide? (STEAM_PARTS)}: a beam engine like James Watt's, from the side: the fire under
##   the boiler, the steam pipe to the cylinder, the piston and its rod, the rocking beam on its pillar, the rod down to
##   the flywheel, and Watt's separate condenser in a tub of cold water.
## - greenhouse {labels?, mark?, hide? (GREENHOUSE_PARTS), more? (a thicker blanket of greenhouse gases: more heat kept
##   in)}: sunlight passes through the atmosphere and warms the Earth; the Earth gives off heat; some escapes to space and
##   some is kept in by the greenhouse gases.
## - scatter_plot {points: [[x, y, label? (12 letters)]] (2-12), x_name, y_name (24 letters), x_from? (0), x_to, x_step,
##   y_from? (0), y_to, y_step (2-10 steps each way; every point inside), line? (the trend line through the points),
##   mark? (a point's index, orange)}: a scatter graph (income and life expectancy, risk and return).
## - pop_pyramid {bands: [[label (8 letters), left, right]] (3-10, the youngest first: drawn at the bottom), top (the
##   scale's end, more than every bar), step (2-10 steps to top), left_name? ("males"), right_name? ("females"), mark?
##   (a band's index), title? (28 letters)}: a population pyramid: each age band's share (%) as bars out from the middle.
## - tourism_cycle {labels? (the stages named along the curve), mark?, hide? (TOURISM_PARTS), paths? (after stagnation
##   the resort's two futures: rejuvenation or decline)}: Butler's tourism area life cycle: visitors over time.
## - ocean_zones {labels? (each zone named), depths? (the depth of each zone's floor), life? (creatures of each zone),
##   mark?, hide? (ZONES)}: the ocean from its sunlit surface down to the trenches, each zone darker (zone_at).
## - projection {view: PROJECTIONS ("globe": the Earth as a ball; "mercator": straight compass courses, stretched near
##   the poles; "equal_area": every area true, shapes squashed (Gall-Peters); "compromise": a bit of each (Robinson);
##   "azimuthal": round the North Pole, true distances from it), circles? (same-sized circles on the globe, drawn as the
##   map shows them: Tissot's circles), mark? (a latitude, whole degrees, -80 to 80, drawn orange)}: the world's grid of
##   latitude and longitude every 30° (no coastlines, as grade 5's latlong) on a map projection (stretch, mercator_y).
## - parliament_seats {groups: [[name (12 letters), seats (1 or more)]] (1-6; at most 700 seats), majority? (the seat
##   that makes a majority marked), mark? (a group's index), title? (24 letters)}: a parliament's seats as dots in a half
##   circle, each group its colour, from the left (majority).
## - receipt {shop (20 letters), lines: [[item (16 letters), price (gold, 0 or more)]] (1-6), date? (12), total? (the
##   total line), hide_total? (the total shown "?"), paid? (12: "card"), mark? (a line's index), note? (26)}: a till
##   receipt (receipt_total).
## - balance_scale {left, right: [reason (24 letters)] (0-4 each; one at least), left_name, right_name (14 letters),
##   weights? ([[n, …], [n, …]]: each reason's weight, more than 0; 1 each without), tilt? ("left", "right", "level":
##   otherwise the heavier side goes down), title? (30 letters)}: reasons weighed on a balance (tilt).

const KINDS: Array[String] = ["steam_engine", "greenhouse", "scatter_plot", "pop_pyramid", "tourism_cycle",
	"ocean_zones", "projection", "parliament_seats", "receipt", "balance_scale"]
const H := preload("res://ui/school/school_picture_g7hum.gd")
const INK := Color("1f2a4a")    # SchoolUi.INK
const PAPER := Color("fdf6e3")  # SchoolUi.PAPER
const ORANGE := Color("f08a1c")
const SOFT := Color("fce2b8")
const RED := Color("d9433b")
const BLUE := Color("3a7be8")
const GREEN := Color("3fa34d")
const SEA := Color("9fd0f2")
const GRID := Color("4f6f99")
const METAL := Color("9aa1ab")
const COPPER := Color("c87a3c")
const WOOD := Color("a86b3c")
const BRICK := Color("a8503a")

const STEAM_PARTS: Array[String] = ["fire", "boiler", "steam pipe", "cylinder", "piston", "beam", "condenser",
	"flywheel"]
const GREENHOUSE_PARTS: Array[String] = ["Sun", "sunlight", "atmosphere", "greenhouse gases", "heat escaping",
	"heat kept in", "Earth"]

const MAX_POINTS := 12
const MAX_POINT_LABEL := 12
const MAX_AXIS_NAME := 24

const MAX_BANDS := 10
const MAX_BAND_LABEL := 8
const MAX_PYRAMID_TITLE := 28
const LEFT_BAR := Color("5b8fd9")
const RIGHT_BAR := Color("e8748a")

## Butler's (1980) stages, in order, and the two futures after stagnation.
const TOURISM_STAGES: Array[String] = ["exploration", "involvement", "development", "consolidation", "stagnation"]
const TOURISM_PARTS: Array[String] = ["exploration", "involvement", "development", "consolidation", "stagnation",
	"rejuvenation", "decline"]

const ZONES: Array[String] = ["sunlight zone", "twilight zone", "midnight zone", "abyss", "trenches"]
## Each zone's floor in metres (the deepest trench: about 11,000 m).
const ZONE_FLOORS: Array[int] = [200, 1000, 4000, 6000, 11000]
const ZONE_COLOURS: Array[Color] = [Color("7fc8f0"), Color("3a7bbf"), Color("1d3f73"), Color("12254a"), Color("08112a")]

const PROJECTIONS: Array[String] = ["globe", "mercator", "equal_area", "compromise", "azimuthal"]
const PROJECTION_NAMES := {"globe": "the globe", "mercator": "Mercator", "equal_area": "equal-area (Gall-Peters)",
	"compromise": "compromise (Robinson)", "azimuthal": "azimuthal (round the North Pole)"}
const MERCATOR_EDGE := 80.0
const AZIMUTHAL_EDGE := -60.0
## Robinson's (1963) table: every 5° from the equator to the pole, each parallel's length (X) and height (Y).
const ROBINSON_X: Array[float] = [1.0, 0.9986, 0.9954, 0.99, 0.9822, 0.973, 0.96, 0.9427, 0.9216, 0.8962, 0.8679,
	0.835, 0.7986, 0.7597, 0.7186, 0.6732, 0.6213, 0.5722, 0.5322]
const ROBINSON_Y: Array[float] = [0.0, 0.062, 0.124, 0.186, 0.248, 0.31, 0.372, 0.434, 0.4958, 0.5571, 0.6176, 0.6769,
	0.7346, 0.7903, 0.8435, 0.8936, 0.9394, 0.9761, 1.0]
const TISSOT := Color(0.85, 0.26, 0.23, 0.45)

const MAX_GROUPS := 6
const MAX_GROUP_NAME := 12
const MAX_SEATS := 700
const MAX_SEATS_TITLE := 24
const GROUP_COLOURS: Array[Color] = [Color("d9433b"), Color("3a7be8"), Color("3fa34d"), Color("f0b43c"), Color("8e44ad"),
	Color("9aa1ad")]

const MAX_LINES := 6
const MAX_SHOP := 20
const MAX_ITEM := 16
const MAX_RECEIPT_SHORT := 12
const MAX_NOTE := 26

const MAX_REASONS := 4
const MAX_REASON := 24
const MAX_SIDE := 14
const MAX_SCALE_TITLE := 30
const TILTS: Array[String] = ["left", "right", "level"]


# --- The rules the pictures draw by (the lessons teach them; tests check them) --------------------------------------

## Mercator's stretch at a latitude: every length there is drawn 1 ÷ cos(latitude) times too long (2 at 60°), so an
## area looks that squared times too big.
static func stretch(lat: float) -> float:
	return 1.0 / cos(deg_to_rad(lat))


## How high a latitude sits on a Mercator map (in the globe's radii from the equator): the lines spread apart towards
## the poles.
static func mercator_y(lat: float) -> float:
	return log(tan(PI / 4.0 + deg_to_rad(lat) / 2.0))


## A majority: more than half of the seats.
static func majority(seats: int) -> int:
	return seats / 2 + 1


## The ocean's zone at a depth in metres.
static func zone_at(depth: float) -> String:
	for i in ZONES.size():
		if depth < ZONE_FLOORS[i] or i == ZONES.size() - 1:
			return ZONES[i]
	return ZONES[-1]


## The tourism cycle's next stage ("" after stagnation: the resort's future depends on what it does).
static func stage_after(stage: String) -> String:
	var i := TOURISM_STAGES.find(stage)
	return TOURISM_STAGES[i + 1] if i >= 0 and i < TOURISM_STAGES.size() - 1 else ""


static func receipt_total(lines: Array) -> float:
	var total := 0.0
	for l: Variant in lines:
		total += float(l[1])
	return total


## Which way the balance tips: "left", "right" or "level".
static func tilt(d: Dictionary) -> String:
	if d.has("tilt"):
		return str(d.tilt)
	var sums: Array[float] = [0.0, 0.0]
	for side in 2:
		var reasons: Array = d.get("left" if side == 0 else "right", [])
		for i in reasons.size():
			sums[side] += float(d.weights[side][i]) if d.has("weights") else 1.0
	if is_equal_approx(sums[0], sums[1]):
		return "level"
	return "left" if sums[0] > sums[1] else "right"


# --- Checks -------------------------------------------------------------------------------------------------------------

## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	var kind := str(p.get("kind", ""))
	match kind:
		"steam_engine":
			return H._parts_problem(p, STEAM_PARTS)
		"greenhouse":
			var why := H._parts_problem(p, GREENHOUSE_PARTS)
			return why if why != "" else H._flags_problem(p, ["more"])
		"scatter_plot":
			return _scatter_problem(p)
		"pop_pyramid":
			return _pyramid_problem(p)
		"tourism_cycle":
			var why := H._parts_problem(p, TOURISM_PARTS)
			if why == "":
				why = H._flags_problem(p, ["paths"])
			if why == "" and not bool(p.get("paths", false)):
				for key: String in ["mark", "hide"]:
					if str(p.get(key, "")) in ["rejuvenation", "decline"]:
						return "tourism_cycle: %s is a future after stagnation: paths must be true" % key
			return why
		"ocean_zones":
			var why := H._parts_problem(p, ZONES)
			return why if why != "" else H._flags_problem(p, ["depths", "life"])
		"projection":
			if not PROJECTIONS.has(str(p.get("view", ""))):
				return "projection: view is one of %s" % [PROJECTIONS]
			if p.has("mark") and (not H._whole(p.mark) or absi(int(p.mark)) > int(MERCATOR_EDGE)
					or (str(p.view) == "azimuthal" and int(p.mark) < int(AZIMUTHAL_EDGE))):
				return "projection: mark is a latitude in whole degrees, -80 to 80 (on the map)"
			return H._flags_problem(p, ["circles"])
		"parliament_seats":
			return _seats_problem(p)
		"receipt":
			return _receipt_problem(p)
		"balance_scale":
			return _scale_problem(p)
	return "unknown picture kind '%s'" % kind


static func _short(v: Variant, most: int) -> bool:
	return v is String and str(v).strip_edges() != "" and str(v).length() <= most


static func _steps_ok(from: float, to: float, step: float) -> bool:
	if step <= 0.0 or to <= from:
		return false
	var n := (to - from) / step
	return is_equal_approx(n, roundf(n)) and roundi(n) >= 2 and roundi(n) <= 10


static func _scatter_problem(p: Dictionary) -> String:
	for key: String in ["x_name", "y_name"]:
		if not _short(p.get(key), MAX_AXIS_NAME):
			return "scatter_plot: %s is 1-%d letters" % [key, MAX_AXIS_NAME]
	for key: String in ["x_from", "x_to", "x_step", "y_from", "y_to", "y_step"]:
		if (p.has(key) or not key.ends_with("from")) and not H._number(p.get(key)):
			return "scatter_plot: %s is a number" % key
	var xf := float(p.get("x_from", 0))
	var yf := float(p.get("y_from", 0))
	if not _steps_ok(xf, float(p.x_to), float(p.x_step)) or not _steps_ok(yf, float(p.y_to), float(p.y_step)):
		return "scatter_plot: 2-10 steps from each axis's start to its end"
	var pts: Variant = p.get("points")
	if not pts is Array or (pts as Array).size() < 2 or (pts as Array).size() > MAX_POINTS:
		return "scatter_plot: 2-%d points" % MAX_POINTS
	for pt: Variant in pts:
		if not pt is Array or (pt as Array).size() < 2 or (pt as Array).size() > 3 or not H._number(pt[0]) \
				or not H._number(pt[1]):
			return "scatter_plot: a point is [x, y, label?]"
		if float(pt[0]) < xf or float(pt[0]) > float(p.x_to) or float(pt[1]) < yf or float(pt[1]) > float(p.y_to):
			return "scatter_plot: every point is inside the axes"
		if (pt as Array).size() == 3 and not _short(pt[2], MAX_POINT_LABEL):
			return "scatter_plot: a point's label is 1-%d letters" % MAX_POINT_LABEL
	if p.has("mark") and (not H._whole(p.mark) or int(p.mark) < 0 or int(p.mark) >= (pts as Array).size()):
		return "scatter_plot: mark is a point's index"
	return H._flags_problem(p, ["line"])


static func _pyramid_problem(p: Dictionary) -> String:
	if not H._number(p.get("top")) or not H._number(p.get("step")) or not _steps_ok(0.0, float(p.top), float(p.step)):
		return "pop_pyramid: 2-10 steps from 0 to top"
	var bands: Variant = p.get("bands")
	if not bands is Array or (bands as Array).size() < 3 or (bands as Array).size() > MAX_BANDS:
		return "pop_pyramid: 3-%d bands" % MAX_BANDS
	for b: Variant in bands:
		if not b is Array or (b as Array).size() != 3 or not _short(b[0], MAX_BAND_LABEL) or not H._number(b[1]) \
				or not H._number(b[2]):
			return "pop_pyramid: a band is [label (1-%d letters), left, right]" % MAX_BAND_LABEL
		if float(b[1]) < 0.0 or float(b[2]) < 0.0 or float(b[1]) > float(p.top) or float(b[2]) > float(p.top):
			return "pop_pyramid: every bar is 0 to top"
	for key: String in ["left_name", "right_name"]:
		if p.has(key) and not _short(p[key], MAX_BAND_LABEL):
			return "pop_pyramid: %s is 1-%d letters" % [key, MAX_BAND_LABEL]
	if p.has("title") and not _short(p.title, MAX_PYRAMID_TITLE):
		return "pop_pyramid: a title of 1-%d letters" % MAX_PYRAMID_TITLE
	if p.has("mark") and (not H._whole(p.mark) or int(p.mark) < 0 or int(p.mark) >= (bands as Array).size()):
		return "pop_pyramid: mark is a band's index"
	return ""


static func _seats_problem(p: Dictionary) -> String:
	var groups: Variant = p.get("groups")
	if not groups is Array or (groups as Array).is_empty() or (groups as Array).size() > MAX_GROUPS:
		return "parliament_seats: 1-%d groups" % MAX_GROUPS
	var total := 0
	for g: Variant in groups:
		if not g is Array or (g as Array).size() != 2 or not _short(g[0], MAX_GROUP_NAME) or not H._whole(g[1]) \
				or int(g[1]) < 1:
			return "parliament_seats: a group is [name (1-%d letters), seats (1 or more)]" % MAX_GROUP_NAME
		total += int(g[1])
	if total < 2 or total > MAX_SEATS:
		return "parliament_seats: 2-%d seats in all" % MAX_SEATS
	if p.has("mark") and (not H._whole(p.mark) or int(p.mark) < 0 or int(p.mark) >= (groups as Array).size()):
		return "parliament_seats: mark is a group's index"
	if p.has("title") and not _short(p.title, MAX_SEATS_TITLE):
		return "parliament_seats: a title of 1-%d letters" % MAX_SEATS_TITLE
	return H._flags_problem(p, ["majority"])


static func _receipt_problem(p: Dictionary) -> String:
	if not _short(p.get("shop"), MAX_SHOP):
		return "receipt: a shop's name of 1-%d letters" % MAX_SHOP
	var lines: Variant = p.get("lines")
	if not lines is Array or (lines as Array).is_empty() or (lines as Array).size() > MAX_LINES:
		return "receipt: 1-%d lines" % MAX_LINES
	for l: Variant in lines:
		if not l is Array or (l as Array).size() != 2 or not _short(l[0], MAX_ITEM) or not H._number(l[1]) \
				or float(l[1]) < 0.0:
			return "receipt: a line is [item (1-%d letters), price (0 or more)]" % MAX_ITEM
	for key: String in ["date", "paid"]:
		if p.has(key) and not _short(p[key], MAX_RECEIPT_SHORT):
			return "receipt: %s is 1-%d letters" % [key, MAX_RECEIPT_SHORT]
	if p.has("note") and not _short(p.note, MAX_NOTE):
		return "receipt: a note of 1-%d letters" % MAX_NOTE
	if p.has("mark") and (not H._whole(p.mark) or int(p.mark) < 0 or int(p.mark) >= (lines as Array).size()):
		return "receipt: mark is a line's index"
	return H._flags_problem(p, ["total", "hide_total"])


static func _scale_problem(p: Dictionary) -> String:
	for key: String in ["left_name", "right_name"]:
		if not _short(p.get(key), MAX_SIDE):
			return "balance_scale: %s is 1-%d letters" % [key, MAX_SIDE]
	var count := 0
	for key: String in ["left", "right"]:
		var reasons: Variant = p.get(key, [])
		if not reasons is Array or (reasons as Array).size() > MAX_REASONS:
			return "balance_scale: %s is 0-%d reasons" % [key, MAX_REASONS]
		for t: Variant in reasons:
			if not _short(t, MAX_REASON):
				return "balance_scale: a reason is 1-%d letters" % MAX_REASON
		count += (reasons as Array).size()
	if count == 0:
		return "balance_scale: one reason at least"
	if p.has("weights"):
		var w: Variant = p.weights
		if not w is Array or (w as Array).size() != 2:
			return "balance_scale: weights is [[left …], [right …]]"
		for side in 2:
			var reasons: Array = p.get("left" if side == 0 else "right", [])
			if not w[side] is Array or (w[side] as Array).size() != reasons.size():
				return "balance_scale: a weight for every reason"
			for n: Variant in w[side]:
				if not H._number(n) or float(n) <= 0.0:
					return "balance_scale: every weight is more than 0"
	if p.has("tilt") and not TILTS.has(str(p.tilt)):
		return "balance_scale: tilt is one of %s" % [TILTS]
	if p.has("title") and not _short(p.title, MAX_SCALE_TITLE):
		return "balance_scale: a title of 1-%d letters" % MAX_SCALE_TITLE
	return ""


# --- Drawing ----------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"steam_engine":
			_draw_engine(pic, font, r, d)
		"greenhouse":
			_draw_greenhouse(pic, font, r, d)
		"scatter_plot":
			_draw_scatter(pic, font, r, d)
		"pop_pyramid":
			_draw_pyramid(pic, font, r, d)
		"tourism_cycle":
			_draw_tourism(pic, font, r, d)
		"ocean_zones":
			_draw_ocean(pic, font, r, d)
		"projection":
			_draw_projection(pic, font, r, d)
		"parliament_seats":
			_draw_seats(pic, font, r, d)
		"receipt":
			_draw_receipt(pic, font, r, d)
		"balance_scale":
			_draw_scale(pic, font, r, d)


## A number as the lessons write it: 1,200, 4.5, 2.25.
static func _num(v: float) -> String:
	return H._gold(v)


## Axis numbers along a scale: a line and a number every step.
static func _scale_values(from: float, to: float, step: float) -> Array[float]:
	var out: Array[float] = []
	var n := roundi((to - from) / step)
	for k in n + 1:
		out.append(from + k * step)
	return out


# --- A steam engine ---------------------------------------------------------------------------------------------------

static func _draw_engine(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := H._fs(r, 14.0)
	var labels := bool(d.get("labels", false))
	var a := H._fit_box(H._inner(r, fs, labels), 1.7)
	var anchors := {}
	var line_w := maxf(2.0, a.size.y * 0.012)
	# The engine house's floor.
	ci.draw_line(H._at(a, 0.0, 0.98), H._at(a, 1.0, 0.98), INK, 2.0)
	# The fire in its brick hearth, under the boiler.
	H._poly(ci, H._pts(a, [Vector2(0.03, 0.86), Vector2(0.27, 0.86), Vector2(0.27, 0.98), Vector2(0.03, 0.98)]), BRICK)
	for k in 4:
		var x := 0.06 + k * 0.055
		H._poly(ci, H._pts(a, [Vector2(x, 0.97), Vector2(x + 0.045, 0.97), Vector2(x + 0.022, 0.87 - (k % 2) * 0.03)]),
			ORANGE if k % 2 == 0 else RED, INK, 0.0)
	anchors["fire"] = H._at(a, 0.15, 0.93)
	# The boiler: a copper drum.
	H._box(ci, Rect2(H._at(a, 0.04, 0.52), Vector2(a.size.x * 0.22, a.size.y * 0.33)), COPPER, INK, 14, 2)
	for k in 3:
		var x := 0.09 + k * 0.06
		ci.draw_line(H._at(a, x, 0.53), H._at(a, x, 0.84), COPPER.darkened(0.25), 1.5)
	anchors["boiler"] = H._at(a, 0.15, 0.62)
	# The steam pipe: up from the boiler and across into the cylinder.
	var pipe := PackedVector2Array([H._at(a, 0.15, 0.52), H._at(a, 0.15, 0.42), H._at(a, 0.30, 0.42), H._at(a, 0.30, 0.52),
		H._at(a, 0.34, 0.52)])
	ci.draw_polyline(pipe, METAL.darkened(0.3), line_w * 3.0, true)
	ci.draw_polyline(pipe, METAL, line_w * 1.8, true)
	anchors["steam pipe"] = H._at(a, 0.22, 0.42)
	# The cylinder and its piston; the piston rod goes up to the beam.
	var cyl := Rect2(H._at(a, 0.34, 0.46), Vector2(a.size.x * 0.11, a.size.y * 0.40))
	ci.draw_rect(cyl, Color("c9ced6"))
	ci.draw_rect(cyl, INK, false, 2.0)
	var piston := Rect2(Vector2(cyl.position.x + 2.0, cyl.position.y + cyl.size.y * 0.3), Vector2(cyl.size.x - 4.0,
		cyl.size.y * 0.1))
	ci.draw_rect(piston, METAL.darkened(0.35))
	ci.draw_line(Vector2(cyl.get_center().x, piston.position.y), H._at(a, 0.395, 0.17), INK, line_w * 1.5)
	anchors["piston"] = Vector2(cyl.position.x + cyl.size.x * 0.75, piston.get_center().y)
	anchors["cylinder"] = Vector2(cyl.get_center().x, cyl.position.y + cyl.size.y * 0.8)
	# The condenser in its tub of cold water, piped from the cylinder's foot.
	H._poly(ci, H._pts(a, [Vector2(0.47, 0.74), Vector2(0.60, 0.74), Vector2(0.60, 0.98), Vector2(0.47, 0.98)]), SEA)
	ci.draw_rect(Rect2(H._at(a, 0.50, 0.80), Vector2(a.size.x * 0.07, a.size.y * 0.14)), METAL)
	ci.draw_rect(Rect2(H._at(a, 0.50, 0.80), Vector2(a.size.x * 0.07, a.size.y * 0.14)), INK, false, 1.5)
	ci.draw_line(H._at(a, 0.45, 0.83), H._at(a, 0.50, 0.83), METAL.darkened(0.3), line_w * 2.0)
	anchors["condenser"] = H._at(a, 0.535, 0.87)
	# The pillar and the rocking beam.
	H._poly(ci, H._pts(a, [Vector2(0.64, 0.20), Vector2(0.68, 0.20), Vector2(0.70, 0.98), Vector2(0.62, 0.98)]), Color("d8c7a5"))
	var beam := PackedVector2Array([H._at(a, 0.37, 0.15), H._at(a, 0.89, 0.15), H._at(a, 0.89, 0.20), H._at(a, 0.37, 0.20)])
	H._poly(ci, Array(beam), WOOD)
	ci.draw_circle(H._at(a, 0.66, 0.175), maxf(3.0, a.size.y * 0.018), INK)
	anchors["beam"] = H._at(a, 0.78, 0.175)
	# The connecting rod down to the flywheel's crank, and the flywheel with its spokes.
	var wc := H._at(a, 0.87, 0.64)
	var wr := a.size.y * 0.27
	var crank := wc + Vector2(0, -wr * 0.45)
	ci.draw_line(H._at(a, 0.875, 0.20), crank, INK, line_w * 1.5)
	ci.draw_arc(wc, wr, 0.0, TAU, 40, METAL.darkened(0.4), line_w * 2.5, true)
	for k in 6:
		var ang := k * TAU / 6.0
		ci.draw_line(wc, wc + Vector2(cos(ang), sin(ang)) * wr, METAL.darkened(0.4), line_w)
	ci.draw_circle(wc, maxf(3.0, wr * 0.1), INK)
	ci.draw_circle(crank, maxf(2.5, wr * 0.06), ORANGE)
	anchors["flywheel"] = wc + Vector2(wr * 0.7, wr * 0.7)
	for part: String in STEAM_PARTS:
		if d.get("mark", "") == part or d.get("hide", "") == part:
			ci.draw_circle(anchors[part], 6.0, ORANGE)
	if labels:
		H._label_parts(ci, font, r, d, anchors, fs, ["steam pipe", "piston", "beam", "boiler"])


# --- The greenhouse effect ------------------------------------------------------------------------------------------

static func _draw_greenhouse(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := H._fs(r, 14.0)
	var labels := bool(d.get("labels", false))
	var a := H._fit_box(H._inner(r, fs, labels), 2.0)
	var more := bool(d.get("more", false))
	var anchors := {}
	# Space, the atmosphere, the air near the ground, the Earth.
	ci.draw_rect(Rect2(a.position, Vector2(a.size.x, a.size.y * 0.24)), Color("1c2550"))
	ci.draw_rect(Rect2(H._at(a, 0.0, 0.24), Vector2(a.size.x, a.size.y * 0.56)), Color("cfe6f7"))
	var gas_top := 0.30 if more else 0.34
	var gas_h := 0.20 if more else 0.12
	ci.draw_rect(Rect2(H._at(a, 0.0, gas_top), Vector2(a.size.x, a.size.y * gas_h)), Color(0.55, 0.62, 0.70, 0.55 if more else 0.35))
	var dots := 70 if more else 36
	for k in dots:
		var fx := fmod(0.5 + k * 0.7548777, 1.0)
		var fy := gas_top + gas_h * (0.1 + 0.8 * fmod(0.5 + k * 0.5698403, 1.0))
		ci.draw_circle(H._at(a, fx, fy), maxf(1.8, a.size.y * 0.013), Color("5b6b80"))
	anchors["atmosphere"] = H._at(a, 0.08, 0.66)
	anchors["greenhouse gases"] = H._at(a, 0.50, gas_top + gas_h * 0.5)
	var ground := PackedVector2Array()
	for k in 21:
		var fx := k / 20.0
		ground.append(H._at(a, fx, 0.80 + 0.06 * pow(fx - 0.5, 2.0) * 4.0))
	ground.append(H._at(a, 1.0, 1.0))
	ground.append(H._at(a, 0.0, 1.0))
	ci.draw_colored_polygon(ground, Color("7fbf5a"))
	ci.draw_polyline(ground.slice(0, 21), INK, 1.5, true)
	anchors["Earth"] = H._at(a, 0.30, 0.92)
	# The Sun and its light, straight through the air to the ground.
	var sun := H._at(a, 0.08, 0.12)
	var sr := a.size.y * 0.085
	for k in 8:
		var ang := k * TAU / 8.0
		ci.draw_line(sun + Vector2(cos(ang), sin(ang)) * sr * 1.2, sun + Vector2(cos(ang), sin(ang)) * sr * 1.6, Color("ffd23f"), 2.0)
	ci.draw_circle(sun, sr, Color("ffc93c"))
	anchors["Sun"] = sun + Vector2(sr, 0)
	for k in 2:
		H._arrow(ci, H._at(a, 0.15 + k * 0.08, 0.17), H._at(a, 0.30 + k * 0.10, 0.80), Color("e0a800"), 3.0)
	anchors["sunlight"] = H._at(a, 0.262, 0.55)
	# Heat from the ground: one wave escapes to space; one (two with more gases) is sent back down.
	_wave_arrow(ci, H._at(a, 0.58, 0.81), H._at(a, 0.66, 0.05), RED, 1.5 if more else 3.0)
	anchors["heat escaping"] = H._at(a, 0.635, 0.20)
	var backs := 2 if more else 1
	for k in backs:
		var x0 := 0.71 + k * 0.14
		var bounce := gas_top + gas_h * 0.5
		_wave_arrow(ci, H._at(a, x0, 0.81), H._at(a, x0 + 0.02, bounce), RED, 3.0)
		ci.draw_line(H._at(a, x0 + 0.02, bounce), H._at(a, x0 + 0.07, bounce), RED, 2.0)
		_wave_arrow(ci, H._at(a, x0 + 0.07, bounce), H._at(a, x0 + 0.09, 0.79), RED, 3.0)
	anchors["heat kept in"] = H._at(a, 0.79, 0.62)
	for part: String in GREENHOUSE_PARTS:
		if d.get("mark", "") == part or d.get("hide", "") == part:
			ci.draw_circle(anchors[part], 6.0, ORANGE)
	if labels:
		H._label_parts(ci, font, r, d, anchors, fs, ["Sun", "greenhouse gases", "heat escaping"])


## A wavy arrow (heat) from `from` to `to`.
static func _wave_arrow(ci: CanvasItem, from: Vector2, to: Vector2, colour: Color, width: float) -> void:
	var dir := to - from
	var side := Vector2(-dir.y, dir.x).normalized()
	var pts := PackedVector2Array()
	var n := 24
	for k in n - 3:
		var t := float(k) / n
		pts.append(from + dir * t + side * sin(t * TAU * 3.0) * 4.0)
	ci.draw_polyline(pts, colour, width, true)
	H._arrow(ci, pts[pts.size() - 1], to, colour, width)


# --- A scatter graph --------------------------------------------------------------------------------------------------

static func _draw_scatter(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := H._fs(r, 15.0)
	var xf := float(d.get("x_from", 0))
	var yf := float(d.get("y_from", 0))
	var xt := float(d.x_to)
	var yt := float(d.y_to)
	var left := H._text_w(font, _num(yt), fs - 2) + 10.0
	var plot := Rect2(r.position.x + left, r.position.y + fs * 1.6, r.size.x - left - 10.0, r.size.y - fs * 3.4)
	var at := func(x: float, y: float) -> Vector2:
		return Vector2(plot.position.x + plot.size.x * (x - xf) / (xt - xf), plot.end.y - plot.size.y * (y - yf) / (yt - yf))
	for v in _scale_values(yf, yt, float(d.y_step)):
		var y: float = at.call(xf, v).y
		ci.draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), Color("e3dccb"), 1.0)
		H._say_from(ci, font, Vector2(plot.position.x - 4.0, y), _num(v), fs - 2, INK, true, false)
	for v in _scale_values(xf, xt, float(d.x_step)):
		var x: float = at.call(v, yf).x
		ci.draw_line(Vector2(x, plot.end.y), Vector2(x, plot.end.y + 4.0), INK, 1.5)
		H._say(ci, font, Vector2(x, plot.end.y + fs * 0.8), _num(v), fs - 2, INK, false)
	ci.draw_line(plot.position, Vector2(plot.position.x, plot.end.y), INK, 2.0)
	ci.draw_line(Vector2(plot.position.x, plot.end.y), plot.end, INK, 2.0)
	H._say_from(ci, font, Vector2(r.position.x + 2.0, r.position.y + fs * 0.6), str(d.y_name), fs - 1, INK, false, false)
	H._say_from(ci, font, Vector2(plot.end.x, plot.end.y + fs * 1.8), str(d.x_name), fs - 1, INK, true, false)
	var pts: Array = d.points
	if bool(d.get("line", false)):
		var fit := _trend(pts)
		var x0 := xf
		var x1 := xt
		var y0 := clampf(fit.x + fit.y * x0, yf, yt)
		var y1 := clampf(fit.x + fit.y * x1, yf, yt)
		if not is_zero_approx(fit.y):
			x0 = (y0 - fit.x) / fit.y
			x1 = (y1 - fit.x) / fit.y
		ci.draw_dashed_line(at.call(x0, y0), at.call(x1, y1), Color("8a8a8a"), 2.0, 8.0)
	for i in pts.size():
		var p: Vector2 = at.call(float(pts[i][0]), float(pts[i][1]))
		var marked := d.has("mark") and int(d.mark) == i
		ci.draw_circle(p, 7.0 if marked else 5.0, ORANGE if marked else BLUE)
		ci.draw_arc(p, 7.0 if marked else 5.0, 0.0, TAU, 16, INK, 1.5)
		if (pts[i] as Array).size() == 3:
			var text := str(pts[i][2])
			var w := H._text_w(font, text, fs - 2)
			var right := p.x + 9.0 + w > plot.end.x
			H._say_from(ci, font, Vector2(p.x - 9.0 if right else p.x + 9.0, p.y - fs * 0.45), text, fs - 2,
				ORANGE.darkened(0.2) if marked else INK, right)


## The least-squares line through the points: Vector2(intercept, slope).
static func _trend(pts: Array) -> Vector2:
	var n := float(pts.size())
	var sx := 0.0
	var sy := 0.0
	var sxx := 0.0
	var sxy := 0.0
	for p: Variant in pts:
		sx += float(p[0])
		sy += float(p[1])
		sxx += float(p[0]) * float(p[0])
		sxy += float(p[0]) * float(p[1])
	var den := n * sxx - sx * sx
	if is_zero_approx(den):
		return Vector2(sy / n, 0.0)
	var slope := (n * sxy - sx * sy) / den
	return Vector2((sy - slope * sx) / n, slope)


# --- A population pyramid -------------------------------------------------------------------------------------------

static func _draw_pyramid(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := H._fs(r, 15.0)
	var top := r.position.y
	if d.has("title"):
		H._say_from(ci, font, Vector2(r.position.x + 2.0, top + fs * 0.6), str(d.title), H._fit(font, str(d.title), fs,
			r.size.x - 4.0))
		top += fs * 1.4
	var bands: Array = d.bands
	var left_name := str(d.get("left_name", "males"))
	var right_name := str(d.get("right_name", "females"))
	var mid_w := 0.0
	for b: Variant in bands:
		mid_w = maxf(mid_w, H._text_w(font, str(b[0]), fs - 2))
	mid_w += 12.0
	var names_h := fs * 1.3
	var scale_h := fs * 1.3
	var area := Rect2(r.position.x, top + names_h, r.size.x, r.end.y - top - names_h - scale_h)
	var cx := area.get_center().x
	var half := (area.size.x - mid_w) * 0.5 - 4.0
	var bh := area.size.y / bands.size()
	var peak := float(d.top)
	H._say(ci, font, Vector2(cx - mid_w * 0.5 - half * 0.5, top + names_h * 0.5), left_name, fs - 1, LEFT_BAR.darkened(0.3), false)
	H._say(ci, font, Vector2(cx + mid_w * 0.5 + half * 0.5, top + names_h * 0.5), right_name, fs - 1, RIGHT_BAR.darkened(0.3), false)
	for v in _scale_values(0.0, peak, float(d.step)):
		var off := half * v / peak
		for side: float in [-1.0, 1.0]:
			var x := cx + side * (mid_w * 0.5 + off)
			ci.draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), Color("e3dccb"), 1.0)
			H._say(ci, font, Vector2(x, area.end.y + fs * 0.7), _num(v), fs - 3, INK, false)
	for i in bands.size():
		var b: Array = bands[i]
		var y := area.end.y - (i + 1) * bh
		var marked := d.has("mark") and int(d.mark) == i
		var lw := half * float(b[1]) / peak
		var rw := half * float(b[2]) / peak
		var rl := Rect2(cx - mid_w * 0.5 - lw, y + 1.5, lw, bh - 3.0)
		var rr := Rect2(cx + mid_w * 0.5, y + 1.5, rw, bh - 3.0)
		ci.draw_rect(rl, ORANGE if marked else LEFT_BAR)
		ci.draw_rect(rr, ORANGE if marked else RIGHT_BAR)
		if lw > 0.5:
			ci.draw_rect(rl, INK, false, 1.0)
		if rw > 0.5:
			ci.draw_rect(rr, INK, false, 1.0)
		H._say(ci, font, Vector2(cx, y + bh * 0.5), str(b[0]), H._fit(font, str(b[0]), mini(fs - 2, int(bh * 0.9)), mid_w - 4.0),
			ORANGE.darkened(0.2) if marked else INK, false)
	H._say(ci, font, Vector2(cx, area.end.y + fs * 0.7), "%", fs - 3, INK, false)


# --- The tourism area life cycle ------------------------------------------------------------------------------------

## Where each stage sits along the time axis (its middle), from 0 to 1; the futures after stagnation start at 0.80.
const STAGE_AT := {"exploration": 0.06, "involvement": 0.20, "development": 0.40, "consolidation": 0.61,
	"stagnation": 0.75, "rejuvenation": 0.93, "decline": 0.93}


static func _visitors(t: float) -> float:
	return 0.06 + 0.84 / (1.0 + exp(-11.0 * (t - 0.42)))


static func _draw_tourism(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := H._fs(r, 14.0)
	var labels := bool(d.get("labels", false))
	var inner := H._inner(r, fs, labels)
	var paths := bool(d.get("paths", false))
	var plot := Rect2(inner.position + Vector2(fs * 1.4, 4.0), inner.size - Vector2(fs * 1.4 + 6.0, fs * 1.4 + 4.0))
	var at := func(t: float, v: float) -> Vector2:
		return Vector2(plot.position.x + plot.size.x * t, plot.end.y - plot.size.y * v)
	# The stages' bands under the curve.
	var edges: Array[float] = [0.0, 0.13, 0.28, 0.52, 0.70, 0.80]
	for k in 5:
		var stage := TOURISM_STAGES[k]
		var marked := str(d.get("mark", "")) == stage or str(d.get("hide", "")) == stage
		ci.draw_rect(Rect2(at.call(edges[k], 1.0), Vector2(plot.size.x * (edges[k + 1] - edges[k]), plot.size.y)),
			SOFT if marked else (Color("f4efe2") if k % 2 == 0 else Color("faf6ec")))
	ci.draw_line(plot.position, Vector2(plot.position.x, plot.end.y), INK, 2.0)
	ci.draw_line(Vector2(plot.position.x, plot.end.y), plot.end, INK, 2.0)
	H._say_from(ci, font, Vector2(plot.end.x, plot.end.y + fs * 0.8), "time", fs - 1, INK, true, false)
	H._say_from(ci, font, Vector2(plot.position.x + 4.0, plot.position.y + fs * 0.6), "visitors", fs - 1, INK, false, false)
	var curve := PackedVector2Array()
	for k in 41:
		var t := 0.80 * k / 40.0
		curve.append(at.call(t, _visitors(t)))
	ci.draw_polyline(curve, BLUE, 3.0, true)
	var end_v := _visitors(0.80)
	if paths:
		var up := PackedVector2Array()
		var down := PackedVector2Array()
		for k in 11:
			var t := 0.80 + 0.20 * k / 10.0
			up.append(at.call(t, minf(end_v + 0.9 * pow((t - 0.80) / 0.20, 1.4) * 0.12, 0.99)))
			down.append(at.call(t, end_v - 0.45 * pow((t - 0.80) / 0.20, 1.2)))
		ci.draw_polyline(up, GREEN, 3.0, true)
		ci.draw_polyline(down, RED, 3.0, true)
	var anchors := {}
	for stage: String in TOURISM_STAGES:
		var t: float = STAGE_AT[stage]
		anchors[stage] = at.call(t, _visitors(t))
	if paths:
		anchors["rejuvenation"] = at.call(0.93, minf(end_v + 0.9 * pow(0.65, 1.4) * 0.12, 0.99))
		anchors["decline"] = at.call(0.93, end_v - 0.45 * pow(0.65, 1.2))
	for part: String in anchors:
		if d.get("mark", "") == part or d.get("hide", "") == part:
			ci.draw_circle(anchors[part], 6.0, ORANGE)
		else:
			ci.draw_circle(anchors[part], 3.5, INK)
	if labels:
		H._label_parts(ci, font, r, d, anchors, fs, ["development", "consolidation", "stagnation", "rejuvenation"])


# --- The ocean's zones -------------------------------------------------------------------------------------------------

static func _draw_ocean(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := H._fs(r, 13.0)
	var depths := bool(d.get("depths", false))
	var left := (H._text_w(font, "11,000 m", fs - 2) + 8.0) if depths else 0.0
	var sea := Rect2(r.position + Vector2(left, r.size.y * 0.08), Vector2(r.size.x - left, r.size.y * 0.92))
	ci.draw_rect(Rect2(Vector2(sea.position.x, r.position.y), Vector2(sea.size.x, r.size.y * 0.08)), Color("dcecf8"))
	# Five bands; the trenches are a narrow cleft in the abyss's floor.
	var shares: Array[float] = [0.17, 0.20, 0.24, 0.21, 0.18]
	var y := sea.position.y
	var bands: Array[Rect2] = []
	for i in ZONES.size():
		var h := sea.size.y * shares[i]
		bands.append(Rect2(sea.position.x, y, sea.size.x, h))
		y += h
	for i in 4:
		ci.draw_rect(bands[i], ZONE_COLOURS[i])
	var t := bands[4]
	ci.draw_rect(t, Color("6b5a48"))
	var cleft := PackedVector2Array([Vector2(t.position.x + t.size.x * 0.55, t.position.y), Vector2(t.position.x + t.size.x * 0.85,
		t.position.y), Vector2(t.position.x + t.size.x * 0.72, t.end.y)])
	ci.draw_colored_polygon(cleft, ZONE_COLOURS[4])
	ci.draw_line(Vector2(sea.position.x, sea.position.y), Vector2(sea.end.x, sea.position.y), Color("1f5fbf"), 2.0)
	if bool(d.get("life", false)):
		_ocean_life(ci, bands)
	for i in ZONES.size():
		var zone := ZONES[i]
		var marked := str(d.get("mark", "")) == zone
		var hidden := str(d.get("hide", "")) == zone
		if marked or hidden:
			ci.draw_rect(bands[i].grow(-2.0), ORANGE, false, 3.0)
		if bool(d.get("labels", false)) or hidden:
			var text := "?" if hidden else zone
			var c := Color.WHITE if i > 0 or marked else INK
			var at := Vector2(bands[i].position.x + bands[i].size.x * 0.06, bands[i].get_center().y)
			if i == 4:
				at.x = bands[i].position.x + bands[i].size.x * 0.06
			H._say_from(ci, font, at, text, H._fit(font, text, fs, bands[i].size.x * 0.45), c, false, false)
		if depths:
			var bottom := ZONE_FLOORS[i]
			var fy := bands[i].end.y if i < 4 else bands[i].end.y - 2.0
			ci.draw_line(Vector2(sea.position.x - 4.0, fy), Vector2(sea.position.x, fy), INK, 1.5)
			H._say_from(ci, font, Vector2(sea.position.x - 6.0, fy - (fs * 0.35 if i == 4 else 0.0)), "%s m" % GenKit.fmt(bottom),
				fs - 2, INK, true, false)
	if depths:
		H._say_from(ci, font, Vector2(sea.position.x - 6.0, sea.position.y), "0 m", fs - 2, INK, true, false)


static func _fish(ci: CanvasItem, c: Vector2, size: float, colour: Color, facing: float = 1.0) -> void:
	var body := PackedVector2Array()
	for k in 16:
		var ang := k * TAU / 16.0
		body.append(c + Vector2(cos(ang) * size, sin(ang) * size * 0.45))
	ci.draw_colored_polygon(body, colour)
	var tail := c + Vector2(-facing * size * 0.9, 0)
	ci.draw_colored_polygon(PackedVector2Array([tail, tail + Vector2(-facing * size * 0.6, -size * 0.45),
		tail + Vector2(-facing * size * 0.6, size * 0.45)]), colour)
	ci.draw_circle(c + Vector2(facing * size * 0.5, -size * 0.1), maxf(1.0, size * 0.1), INK)


static func _ocean_life(ci: CanvasItem, bands: Array[Rect2]) -> void:
	var s := clampf(bands[0].size.y * 0.42, 5.0, 20.0)
	var b := bands[0]
	for k in 18:   # plankton near the light
		ci.draw_circle(b.position + Vector2(b.size.x * fmod(0.53 + k * 0.137, 0.45) + b.size.x * 0.5, b.size.y * (0.2 + fmod(k * 0.29, 0.6))),
			1.6, Color("2e8b3e"))
	_fish(ci, b.position + Vector2(b.size.x * 0.62, b.size.y * 0.55), s, Color("f0b43c"))
	_fish(ci, b.position + Vector2(b.size.x * 0.80, b.size.y * 0.35), s * 0.8, Color("f0b43c"), -1.0)
	b = bands[1]   # lanternfish, with lights along their sides
	for k in 2:
		var c := b.position + Vector2(b.size.x * (0.6 + k * 0.2), b.size.y * (0.4 + k * 0.25))
		_fish(ci, c, s * 0.8, Color("8fa3b8"), 1.0 if k == 0 else -1.0)
		for j in 3:
			ci.draw_circle(c + Vector2((j - 1) * s * 0.4, s * 0.2), 1.5, Color("fff27a"))
	b = bands[2]   # an anglerfish and its glowing lure
	var ac := b.position + Vector2(b.size.x * 0.72, b.size.y * 0.55)
	_fish(ci, ac, s * 1.1, Color("4a3a52"))
	ci.draw_line(ac + Vector2(s * 0.5, -s * 0.4), ac + Vector2(s * 1.4, -s * 0.9), Color("8a7a92"), 1.5)
	ci.draw_circle(ac + Vector2(s * 1.4, -s * 0.9), 3.0, Color("fff27a"))
	b = bands[3]   # sea cucumbers on the abyssal plain
	for k in 2:
		var c := b.position + Vector2(b.size.x * (0.62 + k * 0.17), b.size.y * 0.82)
		var body := PackedVector2Array()
		for j in 14:
			var ang := j * TAU / 14.0
			body.append(c + Vector2(cos(ang) * s, sin(ang) * s * 0.35))
		ci.draw_colored_polygon(body, Color("d98aa0"))
	b = bands[4]   # a tiny shrimp-like amphipod at the bottom of the cleft
	var tc := b.position + Vector2(b.size.x * 0.72, b.size.y * 0.75)
	ci.draw_arc(tc, s * 0.4, PI, TAU, 8, Color("f2e6d0"), 2.0)


# --- Map projections ----------------------------------------------------------------------------------------------------

## A point of the globe on the view, in its own units (the map's box is fitted to them): Vector2.INF when the globe's
## far side hides it.
static func _project(view: String, lat: float, long: float) -> Vector2:
	var phi := deg_to_rad(lat)
	var lam := deg_to_rad(long)
	match view:
		"mercator":
			return Vector2(lam, -mercator_y(clampf(lat, -MERCATOR_EDGE, MERCATOR_EDGE)))
		"equal_area":   # Gall-Peters: a cylinder cut at 45°
			return Vector2(lam * cos(PI / 4.0), -sin(phi) / cos(PI / 4.0))
		"compromise":
			var a := clampf(absf(lat), 0.0, 90.0) / 5.0
			var i := mini(int(a), 17)
			var f := a - i
			var x := ROBINSON_X[i] + (ROBINSON_X[i + 1] - ROBINSON_X[i]) * f
			var y := ROBINSON_Y[i] + (ROBINSON_Y[i + 1] - ROBINSON_Y[i]) * f
			return Vector2(0.8487 * x * lam, -1.3523 * y * signf(lat))
		"azimuthal":   # round the North Pole: distance from it is true
			var rho := (90.0 - lat) / 180.0 * PI
			return Vector2(rho * sin(lam), rho * cos(lam))
		_:   # the globe, seen from above 20° N
			var phi0 := deg_to_rad(20.0)
			var cos_c := sin(phi0) * sin(phi) + cos(phi0) * cos(phi) * cos(lam)
			if cos_c < 0.0:
				return Vector2.INF
			return Vector2(cos(phi) * sin(lam), -(cos(phi0) * sin(phi) - sin(phi0) * cos(phi) * cos(lam)))


## The view's extent in its own units: Rect2 of every point it draws.
static func _extent(view: String) -> Rect2:
	match view:
		"mercator":
			var y := mercator_y(MERCATOR_EDGE)
			return Rect2(-PI, -y, TAU, 2.0 * y)
		"equal_area":
			return Rect2(-PI * cos(PI / 4.0), -1.0 / cos(PI / 4.0), TAU * cos(PI / 4.0), 2.0 / cos(PI / 4.0))
		"compromise":
			return Rect2(-0.8487 * PI, -1.3523, 2.0 * 0.8487 * PI, 2.0 * 1.3523)
		"azimuthal":
			var rho := (90.0 - AZIMUTHAL_EDGE) / 180.0 * PI
			return Rect2(-rho, -rho, 2.0 * rho, 2.0 * rho)
	return Rect2(-1.0, -1.0, 2.0, 2.0)


## Lines of latitude or longitude cut where the view cannot draw them (the globe's far side).
static func _graticule_line(view: String, points: Array) -> Array:
	var runs: Array = []
	var run := PackedVector2Array()
	for p: Vector2 in points:
		if p == Vector2.INF:
			if run.size() > 1:
				runs.append(run)
			run = PackedVector2Array()
		else:
			run.append(p)
	if run.size() > 1:
		runs.append(run)
	return runs


static func _draw_projection(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := H._fs(r, 15.0)
	var view := str(d.view)
	var ext := _extent(view)
	var room := Rect2(r.position, r.size - Vector2(0, fs * 1.4))
	var box := H._fit_box(room, ext.size.x / ext.size.y)
	var to_px := func(p: Vector2) -> Vector2:
		return box.position + (p - ext.position) / ext.size * box.size
	var lat_lo := AZIMUTHAL_EDGE if view == "azimuthal" else (-MERCATOR_EDGE if view == "mercator" else -90.0)
	var lat_hi := MERCATOR_EDGE if view == "mercator" else 90.0
	# The sea: the map's outline filled.
	var outline := PackedVector2Array()
	match view:
		"globe", "azimuthal":
			var c: Vector2 = to_px.call(Vector2.ZERO)
			ci.draw_circle(c, box.size.x * 0.5, SEA)
			ci.draw_arc(c, box.size.x * 0.5, 0.0, TAU, 64, INK, 2.0, true)
		"compromise":
			for k in 37:
				outline.append(to_px.call(_project(view, 90.0 - k * 5.0, 180.0)))
			for k in 37:
				outline.append(to_px.call(_project(view, -90.0 + k * 5.0, -180.0)))
			ci.draw_colored_polygon(outline, SEA)
			var closed := outline.duplicate()
			closed.append(outline[0])
			ci.draw_polyline(closed, INK, 2.0, true)
		_:
			ci.draw_rect(box, SEA)
			ci.draw_rect(box, INK, false, 2.0)
	# Lines of latitude every 30° and of longitude every 30°.
	for lat in [-60, -30, 0, 30, 60]:
		if lat < lat_lo:
			continue
		var pts: Array = []
		for k in 73:
			var p := _project(view, float(lat), -180.0 + k * 5.0)
			pts.append(p if p == Vector2.INF else to_px.call(p))
		for run: PackedVector2Array in _graticule_line(view, pts):
			ci.draw_polyline(run, GRID, 2.0 if lat == 0 else 1.2, true)
	for long in range(-180, 181, 30):
		if view in ["globe", "azimuthal"] and long == 180:
			continue
		var pts: Array = []
		for k in 37:
			var lat := lat_lo + (lat_hi - lat_lo) * k / 36.0
			var p := _project(view, lat, float(long))
			pts.append(p if p == Vector2.INF else to_px.call(p))
		for run: PackedVector2Array in _graticule_line(view, pts):
			ci.draw_polyline(run, GRID, 1.2, true)
	# Tissot's circles: the same circle (6° across on the globe) at each crossing, drawn as the map draws it.
	if bool(d.get("circles", false)):
		for lat in [-60, -30, 0, 30, 60]:
			if lat < lat_lo + 8.0:
				continue
			for long in [-120, -60, 0, 60, 120]:
				var ring := PackedVector2Array()
				var seen := true
				for k in 24:
					var q := _circle_point(float(lat), float(long), 7.0, k * TAU / 24.0)
					var p := _project(view, q.x, q.y)
					if p == Vector2.INF:
						seen = false
						break
					ring.append(to_px.call(p))
				if seen:
					ci.draw_colored_polygon(ring, TISSOT)
	if d.has("mark"):
		var pts: Array = []
		for k in 73:
			var p := _project(view, float(d.mark), -180.0 + k * 5.0)
			pts.append(p if p == Vector2.INF else to_px.call(p))
		for run: PackedVector2Array in _graticule_line(view, pts):
			ci.draw_polyline(run, ORANGE, 3.5, true)
		var label := "%d° %s" % [absi(int(d.mark)), "N" if int(d.mark) >= 0 else "S"]
		if int(d.mark) == 0:
			label = "the equator"
		var at: Vector2 = to_px.call(_project(view, float(d.mark), -170.0 if view != "globe" else 0.0))
		if at.x < r.position.x or view == "azimuthal":
			at = to_px.call(_project(view, float(d.mark), 90.0 if view == "azimuthal" else 0.0))
		H._say_from(ci, font, at + Vector2(4.0, -fs * 0.6), label, fs - 1, ORANGE.darkened(0.25), false)
	var name := str(PROJECTION_NAMES[view])
	H._say(ci, font, Vector2(r.get_center().x, r.end.y - fs * 0.6), name, H._fit(font, name, fs, r.size.x - 4.0), INK, false)


## The point `radius` degrees from (lat, long) along the bearing `bearing` (radians from north), on the globe.
static func _circle_point(lat: float, long: float, radius: float, bearing: float) -> Vector2:
	var phi := deg_to_rad(lat)
	var dl := deg_to_rad(radius)
	var phi2 := asin(sin(phi) * cos(dl) + cos(phi) * sin(dl) * cos(bearing))
	var lam2 := atan2(sin(bearing) * sin(dl) * cos(phi), cos(dl) - sin(phi) * sin(phi2))
	return Vector2(rad_to_deg(phi2), long + rad_to_deg(lam2))


# --- A parliament's seats ---------------------------------------------------------------------------------------------

static func _draw_seats(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := H._fs(r, 15.0)
	var groups: Array = d.groups
	var total := 0
	for g: Variant in groups:
		total += int(g[1])
	var top := r.position.y
	if d.has("title"):
		H._say_from(ci, font, Vector2(r.position.x + 2.0, top + fs * 0.6), str(d.title), fs)
		top += fs * 1.3
	var key_h := fs * 1.5 * ceilf(groups.size() / 3.0)
	var room := Rect2(r.position.x, top, r.size.x, r.end.y - top - key_h)
	var outer := minf(room.size.x * 0.5, room.size.y) - 2.0
	var centre := Vector2(room.get_center().x, room.position.y + 2.0 + outer)
	var inner := outer * 0.38
	# Rows of seats: each row's seats in proportion to its length, so the dots sit evenly.
	var rows := clampi(roundi(sqrt(total / 4.0)), 1, 14)
	var radii: Array[float] = []
	var length := 0.0
	for k in rows:
		var rad := inner + (outer - inner) * ((k + 0.5) / rows)
		radii.append(rad)
		length += rad
	var seats: Array = []   # [angle, radius]
	var given := 0
	for k in rows:
		var n := roundi(total * radii[k] / length) if k < rows - 1 else total - given
		n = maxi(n, 1) if total - given > 0 else 0
		n = mini(n, total - given)
		given += n
		for j in n:
			var ang := PI * (1.0 - (j + 0.5) / n) if n > 0 else PI * 0.5
			seats.append([ang, radii[k]])
	seats.sort_custom(func(a: Array, b: Array) -> bool: return _seat_before(a, b))
	var gap := (outer - inner) / rows
	for k in rows:
		var in_row := maxi(roundi(total * radii[k] / length), 1)
		gap = minf(gap, PI * radii[k] / in_row)
	var dot := clampf(gap * 0.42, 1.5, 12.0)
	var g := 0
	var left_in := int(groups[0][1])
	for i in seats.size():
		while i >= left_in and g < groups.size() - 1:
			g += 1
			left_in += int(groups[g][1])
		var p := centre + Vector2(cos(float(seats[i][0])), -sin(float(seats[i][0]))) * float(seats[i][1])
		var colour := GROUP_COLOURS[g % GROUP_COLOURS.size()]
		ci.draw_circle(p, dot, colour)
		if d.has("mark") and int(d.mark) == g:
			ci.draw_arc(p, dot + 1.0, 0.0, TAU, 10, INK, 1.5)
	if bool(d.get("majority", false)) and total >= 2:
		var need := majority(total)
		var ang := PI * (1.0 - float(need) / total)
		ci.draw_line(centre + Vector2(cos(ang), -sin(ang)) * (inner - 6.0), centre + Vector2(cos(ang), -sin(ang)) * (outer + 2.0),
			INK, 2.0)
		H._say(ci, font, centre + Vector2(0, -inner * 0.45), "majority: %s" % GenKit.fmt(need), fs - 1, INK)
	var kx := r.position.x + 4.0
	var ky := room.end.y + fs * 0.75
	var col_w := r.size.x / 3.0
	for i in groups.size():
		var x := kx + (i % 3) * col_w
		var y := ky + (i / 3) * fs * 1.5
		var marked := d.has("mark") and int(d.mark) == i
		ci.draw_rect(Rect2(x, y - fs * 0.45, fs * 0.9, fs * 0.9), GROUP_COLOURS[i % GROUP_COLOURS.size()])
		var text := "%s: %s" % [groups[i][0], GenKit.fmt(int(groups[i][1]))]
		H._say_from(ci, font, Vector2(x + fs * 1.1, y), text, H._fit(font, text, fs - 1, col_w - fs * 1.4),
			ORANGE.darkened(0.25) if marked else INK, false, false)


## Seats from the left of the half circle to the right; in one direction, the inner row first.
static func _seat_before(a: Array, b: Array) -> bool:
	if not is_equal_approx(float(a[0]), float(b[0])):
		return float(a[0]) > float(b[0])
	return float(a[1]) < float(b[1])


# --- A till receipt ---------------------------------------------------------------------------------------------------

## A price as a till prints it: 30, 4.50, 2.25.
static func _price(v: float) -> String:
	return GenKit.fmt(roundi(v)) if is_equal_approx(v, roundf(v)) else "%.2f" % v


static func _draw_receipt(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var lines: Array = d.lines
	var rows := 2 + lines.size() + (2 if bool(d.get("total", false)) else 0) + (1 if d.has("paid") else 0) \
		+ (1 if d.has("note") else 0)
	var lh := (r.size.y - 14.0) / (rows + 0.4)
	var fs := clampi(int(minf(lh / 1.3, r.size.x / 22.0)), 7, mini(18, H._fs(r, 12.0) + 2))
	lh = minf(lh, fs * 1.6)
	var w := minf(r.size.x * 0.9, fs * 18.0)
	var slip := Rect2(r.get_center().x - w * 0.5, r.position.y + 2.0, w, minf(r.size.y - 4.0, lh * (rows + 0.4) + 12.0))
	var zig := PackedVector2Array([slip.position, Vector2(slip.end.x, slip.position.y)])
	var teeth := 12
	for k in teeth + 1:
		zig.append(Vector2(slip.end.x - slip.size.x * k / teeth, slip.end.y - (6.0 if k % 2 == 1 else 0.0)))
	ci.draw_colored_polygon(zig, Color.WHITE)
	var closed := zig.duplicate()
	closed.append(zig[0])
	ci.draw_polyline(closed, Color("b9b2a3"), 1.5, true)
	var y := slip.position.y + lh * 0.7
	var lx := slip.position.x + fs * 0.7
	var rx := slip.end.x - fs * 0.7
	H._say(ci, font, Vector2(slip.get_center().x, y), str(d.shop), H._fit(font, str(d.shop), fs + 1, w - fs), INK, false)
	y += lh
	if d.has("date"):
		H._say(ci, font, Vector2(slip.get_center().x, y), str(d.date), fs - 2, Color("6b7280"), false)
	ci.draw_dashed_line(Vector2(lx, y + lh * 0.5), Vector2(rx, y + lh * 0.5), Color("9aa1ad"), 1.0, 4.0)
	y += lh
	for i in lines.size():
		if d.has("mark") and int(d.mark) == i:
			ci.draw_rect(Rect2(lx - 3.0, y - lh * 0.5, rx - lx + 6.0, lh), SOFT)
		H._say_from(ci, font, Vector2(lx, y), str(lines[i][0]), fs, INK, false, false)
		H._say_from(ci, font, Vector2(rx, y), _price(float(lines[i][1])), fs, INK, true, false)
		y += lh
	if bool(d.get("total", false)):
		ci.draw_line(Vector2(lx, y - lh * 0.45), Vector2(rx, y - lh * 0.45), INK, 1.5)
		H._say_from(ci, font, Vector2(lx, y), "TOTAL", fs, INK, false, false)
		var hidden := bool(d.get("hide_total", false))
		H._say_from(ci, font, Vector2(rx, y), "?" if hidden else _price(receipt_total(lines)), fs,
			ORANGE if hidden else INK, true, false)
		y += lh
	if d.has("paid"):
		H._say(ci, font, Vector2(slip.get_center().x, y), "Paid by %s" % d.paid, fs - 2, Color("6b7280"), false)
		y += lh
	if d.has("note"):
		H._say(ci, font, Vector2(slip.get_center().x, y), str(d.note), H._fit(font, str(d.note), fs - 2, w - fs),
			Color("6b7280"), false)


# --- Reasons on a balance ---------------------------------------------------------------------------------------------

static func _draw_scale(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := H._fs(r, 15.0)
	var top := r.position.y + 2.0
	if d.has("title"):
		H._say(ci, font, Vector2(r.get_center().x, top + fs * 0.6), str(d.title), H._fit(font, str(d.title), fs,
			r.size.x - 4.0), INK, false)
		top += fs * 1.4
	var way := tilt(d)
	var ang := 0.0 if way == "level" else (-0.12 if way == "right" else 0.12)
	var cx := r.get_center().x
	var names_h := fs * 1.3
	var base_y := r.end.y - names_h
	var arm := r.size.x * 0.30
	var pivot := Vector2(cx, base_y - maxf((base_y - top) * 0.22, arm * sin(0.12) + fs))
	# The stand.
	ci.draw_line(pivot, Vector2(cx, base_y), INK, 3.0)
	H._poly(ci, [Vector2(cx - fs * 1.6, base_y), Vector2(cx + fs * 1.6, base_y), Vector2(cx, base_y - fs * 1.0)], Color("c9ced6"))
	# The beam: the heavier side goes down (ang > 0: the left).
	var dir := Vector2(cos(ang), -sin(ang))
	var ends: Array[Vector2] = [pivot - dir * arm, pivot + dir * arm]
	ci.draw_line(ends[0], ends[1], WOOD, 5.0, true)
	ci.draw_circle(pivot, 5.0, INK)
	var most := maxi((d.get("left", []) as Array).size(), (d.get("right", []) as Array).size())
	var highest_pan := minf(ends[0].y, ends[1].y) - fs * 0.5
	var box_h := clampf((highest_pan - top) / maxi(most, 1) - 3.0, 9.0, fs * 1.45)
	for side in 2:
		var end := ends[side]
		var pan_y := end.y - fs * 0.5
		var pw := arm * 0.48
		ci.draw_line(end, Vector2(end.x, pan_y), INK, 2.0)
		ci.draw_polyline(PackedVector2Array([Vector2(end.x - pw, pan_y - 5.0), Vector2(end.x - pw * 0.85, pan_y),
			Vector2(end.x + pw * 0.85, pan_y), Vector2(end.x + pw, pan_y - 5.0)]), INK, 3.0, true)
		var reasons: Array = d.get("left" if side == 0 else "right", [])
		var bw := arm * 0.92
		for i in reasons.size():
			var box := Rect2(end.x - bw * 0.5, pan_y - 2.0 - (i + 1) * (box_h + 3.0), bw, box_h)
			H._box(ci, box, Color("eaf2ff") if side == 0 else Color("fdebe6"), BLUE if side == 0 else RED, 5, 1)
			H._say(ci, font, box.get_center(), str(reasons[i]), H._fit(font, str(reasons[i]), mini(fs - 2, int(box_h * 0.8)),
				bw - 6.0), INK, false)
		var name := str(d.left_name if side == 0 else d.right_name)
		H._say(ci, font, Vector2(end.x, r.end.y - names_h * 0.5), name, fs, BLUE.darkened(0.2) if side == 0 else RED.darkened(0.1), false)
