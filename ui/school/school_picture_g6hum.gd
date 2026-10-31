class_name SchoolPictureG6Hum
extends RefCounted
## Owner #70 and #73, grade 6 history, geography and citizenship (research §6.6): the picture kinds they add, drawn from
## data onto a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only, no new art; the
## font has no arrows, so they are drawn). Kinds and fields:
## - event_timeline {from, to (whole years, BC below 0; at most 3,000 years), step (1-12 steps from `from` to `to`),
##   events: [[year, label (22 letters)]] (1-6, from-to; no year 0), eras?: [[from, to, name (20 letters)]] (0-3 shaded
##   periods under the line), mark? (an event's index, orange), hide? (an event's index: its label shown "?")}: a
##   timeline with its years under it (a span across AD 1 writes "BC" and "AD" and marks where they meet) and the events'
##   labels in up to three rows above it.
## - quipu {cords: [n] (1-5 numbers, 0-9,999), names?: [text] (one each, 10 letters), labels? (each number under its
##   cord), places? (the rows "1000s", "100s", "10s", "1s" named at the left)}: an Inca knotted-string record: a main cord
##   with a pendant cord for each number, its places from the top (thousands) to the bottom (ones); in every place but
##   the ones a digit is that many single knots (drawn in columns of up to 5, so they can be counted), in the ones place
##   1 is a figure-of-eight knot and 2-9 a long knot of that many turns; 0 is no knot (quipu_digits, knot_kind).
## - feudal_pyramid {mark? (a level of LEVELS, orange), hide? (a level shown "?"), arrows? (land given down the left,
##   service and loyalty up the right)}: the feudal system: the king at the top, then barons, knights and peasants, each
##   band wider (more people).
## - castle_type {type: CASTLES ("motte_bailey", "stone_keep": from the side; "concentric": from above), labels?}: the
##   Normans' castles, their parts named (CASTLE_PARTS).
## - dot_density {areas: [{name (12 letters), people (0-80 dots), km2 (1-9 squares)}] (1-3), each? (people a dot stands
##   for, 1-1,000; a key when above 1)}: areas of land as squares of 1 km² with their people as dots, for population
##   density (people ÷ km²).
## - city_zones {labels? (true), mark? (a zone of ZONES, orange), hide? (its name shown "?")}: a city's land use in rings:
##   the city centre (CBD), the inner city, the suburbs and the rural-urban fringe.
## - os_map {e0, n0 (the grid numbers of the bottom-left lines, 0-98), cols (2-6), rows (2-5), hills?: [{e, n, heights:
##   [m] (1-5 contours, rising), top? (a spot height above the last), size? (3-20 tenths of a square: the lowest ring's
##   radius), steep? (SIDES: the contours bunch on that side)}] (0-2), river?: [[e, n]] (2-12 points), symbols?: [{what
##   (SYMBOLS), e, n}] (0-8), points?: [{e, n, label (1-3 letters)}] (0-5), km? (a 1 km scale bar: one square)}: a
##   detailed map like an Ordnance Survey map at 1:25,000. Every e and n is in tenths of a square: e 324 is 4 tenths east
##   of grid line 32, so a point's six-figure grid reference is its e and n (six_figure) and its square's four-figure one
##   the lines at its bottom-left (four_figure). Small ticks mark the tenths along the bottom and up the side.
## - climograph {temp: [12 °C], rain: [12 mm], t_from? (0), t_top, t_step, r_top, r_step (the two scales with as many
##   steps, 2-10), name? (20 letters), mark? (a month 0-11, orange)}: a climate graph: rain as blue bars (mm, the scale
##   on the right) and temperature as a red line (°C, on the left), the months J to D under them.
## - river_course {view: VIEWS ("long": the long profile from source to mouth, with each course's valley under it;
##   "plan": a river from above, from its source in the hills to the sea; "meander": one bend from above; "waterfall": a
##   waterfall from the side), labels?, mark? (a label of the view's RIVER_LABELS, orange), hide? (a label shown "?")}.
## - layer_map {w (3-12), h (2-8), layers: [{name (14 letters), what (THINGS), cells: [h rows of w "#" or "."]}] (1-4),
##   view? ("overlay", the default: every layer on one map, with a key; "stack": the layers as sheets, one above
##   another)}: a map in layers, as a GIS shows it. Areas (water, flood, trees, road) fill their cells; places (houses,
##   schools, shops, bus stops) are drawn in theirs.
## - savings_growth {start (1-100,000 gold), rate (0.5-50 % a year), years (1-6), simple? (a grey bar beside each for
##   simple interest), values? (each bar's gold on top)}: savings growing with compound interest: each year's bar is the
##   money saved (blue) and the interest so far (gold) (compound).

const KINDS: Array[String] = ["event_timeline", "quipu", "feudal_pyramid", "castle_type", "dot_density", "city_zones",
	"os_map", "climograph", "river_course", "layer_map", "savings_growth"]
const INK := Color("1f2a4a")    # SchoolUi.INK
const PAPER := Color("fdf6e3")  # SchoolUi.PAPER
const ORANGE := Color("f08a1c")
const SOFT := Color("fce2b8")
const RED := Color("d9433b")
const BLUE := Color("3a7be8")
const WATER := Color("7fb6e8")
const DEEP := Color("3f86d0")
const GRASS := Color("bfe0a0")
const EARTH := Color("b98a5a")
const SAND := Color("f2d48a")
const STONE := Color("a7a39a")
const DARK_STONE := Color("7c776d")
const WOOD := Color("a86b3c")

const MAX_SPAN := 3000
const MAX_STEPS := 12
const MAX_EVENTS := 6
const MAX_EVENT := 22
const MAX_ERAS := 3
const MAX_ERA := 20
const ERA_COLOURS: Array[Color] = [Color("dcebfb"), Color("fde7c4"), Color("dff2d4")]

const MAX_CORDS := 5
const QUIPU_MAX := 9999
const MAX_CORD_NAME := 10
const CORD_COLOURS: Array[Color] = [Color("c0392b"), Color("2e86c1"), Color("d4ac0d"), Color("239b56"), Color("8e44ad")]
const KNOT := Color("5a3b22")
const MAIN_CORD := Color("8a6a4a")

const LEVELS: Array[String] = ["king", "barons", "knights", "peasants"]
const LEVEL_NAMES := {"king": "King", "barons": "Barons", "knights": "Knights", "peasants": "Peasants"}
const LEVEL_COLOURS: Array[Color] = [Color("f5c542"), Color("b18ad8"), Color("9fb7cf"), Color("a8d08d")]

const CASTLES: Array[String] = ["motte_bailey", "stone_keep", "concentric"]
const CASTLE_PARTS := {"motte_bailey": ["motte", "keep", "bailey", "palisade", "ditch"],
	"stone_keep": ["keep", "curtain wall", "gatehouse", "tower", "moat"],
	"concentric": ["outer wall", "inner wall", "tower", "gatehouse", "moat"]}

const MAX_AREAS := 3
const MAX_AREA_NAME := 12
const MAX_DOTS := 80
const MAX_KM2 := 9

const ZONES: Array[String] = ["cbd", "inner_city", "suburbs", "fringe"]
const ZONE_NAMES := {"cbd": "City centre (CBD)", "inner_city": "Inner city", "suburbs": "Suburbs",
	"fringe": "Rural-urban fringe"}
const ZONE_COLOURS := {"cbd": Color("b8bec9"), "inner_city": Color("f3c9a0"), "suburbs": Color("fbeeb0"),
	"fringe": Color("cfe8b8")}

const SIDES: Array[String] = ["n", "e", "s", "w"]
const SYMBOLS: Array[String] = ["worship", "school", "farm", "car_park", "campsite", "viewpoint", "castle", "bridge"]
const MAX_HILLS := 2
const MAX_CONTOURS := 5
const MAX_RIVER := 12
const MAX_SYMBOLS := 8
const MAX_MAP_POINTS := 5
const OS_PAPER := Color("fbf7ea")
const OS_GRID := Color("6f9fd8")
const CONTOUR := Color("c8742f")

const MONTHS := "JFMAMJJASOND"
const MAX_CLIMATE_STEPS := 10
const RAIN_BAR := Color("5b9bd5")

const VIEWS: Array[String] = ["long", "plan", "meander", "waterfall"]
const RIVER_LABELS := {"long": ["source", "waterfall", "mouth", "upper course", "middle course", "lower course",
		"V-shaped valley", "floodplain"],
	"plan": ["source", "tributary", "confluence", "meander", "ox-bow lake", "mouth"],
	"meander": ["erosion", "deposition", "river cliff", "slip-off slope", "fastest flow"],
	"waterfall": ["hard rock", "soft rock", "overhang", "plunge pool", "gorge"]}

const THINGS: Array[String] = ["water", "flood", "trees", "road", "houses", "schools", "shops", "bus_stops"]
const AREA_THINGS: Array[String] = ["water", "flood", "trees", "road"]
const MAX_LAYERS := 4
const MAX_LAYER_NAME := 14
const LAYER_W := Vector2i(3, 12)
const LAYER_H := Vector2i(2, 8)
const LAYER_VIEWS: Array[String] = ["overlay", "stack"]

const MAX_YEARS := 6
const MAX_START := 100000
const SAVED := Color("5b8fd9")
const INTEREST := Color("f2b632")
const SIMPLE := Color("a9b0bb")


# --- The rules the pictures draw by (the lessons teach them; tests check them) --------------------------------------

## A year as the timeline writes it: 500 BC, AD 500 (when the line reaches back into BC) or 1066.
static func year_text(y: int, with_ad: bool = false) -> String:
	if y < 0:
		return "%d BC" % -y
	return ("AD %d" % y) if with_ad else str(y)


## A quipu cord's digits, the thousands first: 3042 -> [3, 0, 4, 2].
static func quipu_digits(n: int) -> Array[int]:
	return [n / 1000 % 10, n / 100 % 10, n / 10 % 10, n % 10]


## The knot a quipu ties for `digit` in a place (`ones`: the ones place, at the bottom): "none" for 0; in the ones
## place "eight" (a figure-of-eight knot) for 1 and "long" (a long knot of `digit` turns) for 2-9; elsewhere "single"
## (that many single knots in a cluster).
static func knot_kind(digit: int, ones: bool) -> String:
	if digit == 0:
		return "none"
	if not ones:
		return "single"
	return "eight" if digit == 1 else "long"


## A point's six-figure grid reference: its easting then its northing, each 3 digits (324, 617 -> "324617").
static func six_figure(e: int, n: int) -> String:
	return "%03d%03d" % [e, n]


## The four-figure reference of the square a point is in: the grid lines at its bottom-left (324, 617 -> "3261").
static func four_figure(e: int, n: int) -> String:
	return "%02d%02d" % [e / 10, n / 10]


## Savings of `start` gold after `years` years at `rate` % compound interest (each year's interest is added and earns
## interest the next year), to the nearest hundredth of a gold.
static func compound(start: float, rate: float, years: int) -> float:
	var v := start
	for _y in years:
		v = snappedf(v * (1.0 + rate / 100.0), 0.01)
	return v


## The same with simple interest: the interest on `start` only, each year.
static func simple(start: float, rate: float, years: int) -> float:
	return snappedf(start + start * rate / 100.0 * years, 0.01)


# --- Checks -----------------------------------------------------------------------------------------------------------

## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	match str(p.get("kind", "")):
		"event_timeline":
			return _timeline_problem(p)
		"quipu":
			return _quipu_problem(p)
		"feudal_pyramid":
			for key: String in ["mark", "hide"]:
				if p.has(key) and not LEVELS.has(str(p[key])):
					return "feudal_pyramid: %s is one of %s" % [key, LEVELS]
			return _flags_problem(p, ["arrows"])
		"castle_type":
			if not CASTLES.has(str(p.get("type", ""))):
				return "castle_type: type is one of %s" % [CASTLES]
			return _flags_problem(p, ["labels"])
		"dot_density":
			return _density_problem(p)
		"city_zones":
			for key: String in ["mark", "hide"]:
				if p.has(key) and not ZONES.has(str(p[key])):
					return "city_zones: %s is one of %s" % [key, ZONES]
			return _flags_problem(p, ["labels"])
		"os_map":
			return _os_problem(p)
		"climograph":
			return _climate_problem(p)
		"river_course":
			var view := str(p.get("view", ""))
			if not VIEWS.has(view):
				return "river_course: view is one of %s" % [VIEWS]
			for key: String in ["mark", "hide"]:
				if p.has(key) and not (RIVER_LABELS[view] as Array).has(str(p[key])):
					return "river_course: %s is one of %s" % [key, RIVER_LABELS[view]]
			return _flags_problem(p, ["labels"])
		"layer_map":
			return _layer_problem(p)
		"savings_growth":
			if not _whole(p.get("start")) or int(p.start) < 1 or int(p.start) > MAX_START:
				return "savings_growth: start is 1-%d gold" % MAX_START
			if not _number(p.get("rate")) or float(p.rate) < 0.5 or float(p.rate) > 50.0:
				return "savings_growth: rate is 0.5-50 (%)"
			if not _whole(p.get("years")) or int(p.years) < 1 or int(p.years) > MAX_YEARS:
				return "savings_growth: years is 1-%d" % MAX_YEARS
			return _flags_problem(p, ["simple", "values"])
	return "unknown picture kind '%s'" % str(p.get("kind", ""))


static func _flags_problem(p: Dictionary, keys: Array) -> String:
	for key: String in keys:
		if p.has(key) and not p[key] is bool:
			return "%s: %s is true or false" % [p.kind, key]
	return ""


static func _timeline_problem(p: Dictionary) -> String:
	if not (_whole(p.get("from")) and _whole(p.get("to")) and _whole(p.get("step"))):
		return "event_timeline: whole years from and to, and a whole step"
	var from := int(p.from)
	var to := int(p.to)
	var step := int(p.step)
	if to <= from or to - from > MAX_SPAN:
		return "event_timeline: from before to, at most %d years" % MAX_SPAN
	if step <= 0 or (to - from) % step != 0 or (to - from) / step > MAX_STEPS:
		return "event_timeline: 1-%d equal steps from `from` to `to`" % MAX_STEPS
	var events: Variant = p.get("events")
	if not events is Array or (events as Array).is_empty() or (events as Array).size() > MAX_EVENTS:
		return "event_timeline: 1-%d events" % MAX_EVENTS
	for e: Variant in events:
		if not e is Array or (e as Array).size() != 2 or not _whole(e[0]) or not e[1] is String:
			return "event_timeline: an event is [year, label]"
		if int(e[0]) < from or int(e[0]) > to or int(e[0]) == 0:
			return "event_timeline: an event's year is on the line (and there is no year 0)"
		if str(e[1]).strip_edges() == "" or str(e[1]).length() > MAX_EVENT:
			return "event_timeline: an event's label is 1-%d letters" % MAX_EVENT
	var eras: Variant = p.get("eras", [])
	if not eras is Array or (eras as Array).size() > MAX_ERAS:
		return "event_timeline: 0-%d eras" % MAX_ERAS
	for e: Variant in eras:
		if not e is Array or (e as Array).size() != 3 or not _whole(e[0]) or not _whole(e[1]) or not e[2] is String:
			return "event_timeline: an era is [from, to, name]"
		if int(e[0]) < from or int(e[1]) > to or int(e[1]) <= int(e[0]):
			return "event_timeline: an era is on the line"
		if str(e[2]).strip_edges() == "" or str(e[2]).length() > MAX_ERA:
			return "event_timeline: an era's name is 1-%d letters" % MAX_ERA
	for key: String in ["mark", "hide"]:
		if p.has(key) and not (_whole(p[key]) and int(p[key]) >= 0 and int(p[key]) < (events as Array).size()):
			return "event_timeline: %s is an event's index" % key
	return ""


static func _quipu_problem(p: Dictionary) -> String:
	var cords: Variant = p.get("cords")
	if not cords is Array or (cords as Array).is_empty() or (cords as Array).size() > MAX_CORDS:
		return "quipu: 1-%d cords" % MAX_CORDS
	for c: Variant in cords:
		if not _whole(c) or int(c) < 0 or int(c) > QUIPU_MAX:
			return "quipu: a cord's number is 0-%d" % QUIPU_MAX
	if p.has("names"):
		if not p.names is Array or (p.names as Array).size() != (cords as Array).size():
			return "quipu: one name for each cord"
		for n: Variant in p.names:
			if not n is String or str(n).strip_edges() == "" or str(n).length() > MAX_CORD_NAME:
				return "quipu: a name is 1-%d letters" % MAX_CORD_NAME
	return _flags_problem(p, ["labels", "places"])


static func _density_problem(p: Dictionary) -> String:
	var areas: Variant = p.get("areas")
	if not areas is Array or (areas as Array).is_empty() or (areas as Array).size() > MAX_AREAS:
		return "dot_density: 1-%d areas" % MAX_AREAS
	for a: Variant in areas:
		if not a is Dictionary:
			return "dot_density: an area is {name, people, km2}"
		var name: Variant = a.get("name")
		if not name is String or str(name).strip_edges() == "" or str(name).length() > MAX_AREA_NAME:
			return "dot_density: a name is 1-%d letters" % MAX_AREA_NAME
		if not _whole(a.get("people")) or int(a.people) < 0 or int(a.people) > MAX_DOTS:
			return "dot_density: people is 0-%d dots" % MAX_DOTS
		if not _whole(a.get("km2")) or int(a.km2) < 1 or int(a.km2) > MAX_KM2:
			return "dot_density: km2 is 1-%d squares" % MAX_KM2
	if p.has("each") and not (_whole(p.each) and int(p.each) >= 1 and int(p.each) <= 1000):
		return "dot_density: each is 1-1000 people"
	return ""


static func _os_problem(p: Dictionary) -> String:
	if not _whole(p.get("cols")) or int(p.cols) < 2 or int(p.cols) > 6:
		return "os_map: cols is 2-6"
	if not _whole(p.get("rows")) or int(p.rows) < 2 or int(p.rows) > 5:
		return "os_map: rows is 2-5"
	if not _whole(p.get("e0")) or int(p.e0) < 0 or int(p.e0) + int(p.cols) > 99:
		return "os_map: e0 is 0-%d" % (99 - int(p.cols))
	if not _whole(p.get("n0")) or int(p.n0) < 0 or int(p.n0) + int(p.rows) > 99:
		return "os_map: n0 is 0-%d" % (99 - int(p.rows))
	var hills: Variant = p.get("hills", [])
	if not hills is Array or (hills as Array).size() > MAX_HILLS:
		return "os_map: 0-%d hills" % MAX_HILLS
	for h: Variant in hills:
		if not h is Dictionary or not _on_map(p, h.get("e"), h.get("n")):
			return "os_map: a hill is {e, n, heights} on the map"
		var heights: Variant = h.get("heights")
		if not heights is Array or (heights as Array).is_empty() or (heights as Array).size() > MAX_CONTOURS:
			return "os_map: a hill has 1-%d contours" % MAX_CONTOURS
		var last := -1
		for v: Variant in heights:
			if not _whole(v) or int(v) <= last:
				return "os_map: contour heights are whole metres, rising"
			last = int(v)
		if h.has("top") and not (_whole(h.top) and int(h.top) > last):
			return "os_map: a hill's top is above its last contour"
		if h.has("size") and not (_whole(h.size) and int(h.size) >= 3 and int(h.size) <= 20):
			return "os_map: a hill's size is 3-20 tenths"
		if h.has("steep") and not SIDES.has(str(h.steep)):
			return "os_map: steep is one of %s" % [SIDES]
	var river: Variant = p.get("river", [])
	if not river is Array or (river as Array).size() == 1 or (river as Array).size() > MAX_RIVER:
		return "os_map: a river is 2-%d points" % MAX_RIVER
	for q: Variant in river:
		if not q is Array or (q as Array).size() != 2 or not _on_map(p, q[0], q[1]):
			return "os_map: a river's point is [e, n] on the map"
	var symbols: Variant = p.get("symbols", [])
	if not symbols is Array or (symbols as Array).size() > MAX_SYMBOLS:
		return "os_map: 0-%d symbols" % MAX_SYMBOLS
	for s: Variant in symbols:
		if not s is Dictionary or not SYMBOLS.has(str(s.get("what", ""))) or not _on_map(p, s.get("e"), s.get("n")):
			return "os_map: a symbol is {what: %s, e, n} on the map" % [SYMBOLS]
	var points: Variant = p.get("points", [])
	if not points is Array or (points as Array).size() > MAX_MAP_POINTS:
		return "os_map: 0-%d points" % MAX_MAP_POINTS
	for q: Variant in points:
		if not q is Dictionary or not _on_map(p, q.get("e"), q.get("n")):
			return "os_map: a point is {e, n, label} on the map"
		var label: Variant = q.get("label")
		if not label is String or str(label).strip_edges() == "" or str(label).length() > 3:
			return "os_map: a point's label is 1-3 letters"
	return _flags_problem(p, ["km"])


## Whether e and n (tenths of a square) are on the map.
static func _on_map(p: Dictionary, e: Variant, n: Variant) -> bool:
	return _whole(e) and _whole(n) and int(e) >= int(p.e0) * 10 and int(e) <= (int(p.e0) + int(p.cols)) * 10 \
		and int(n) >= int(p.n0) * 10 and int(n) <= (int(p.n0) + int(p.rows)) * 10


static func _climate_problem(p: Dictionary) -> String:
	for key: String in ["temp", "rain"]:
		var v: Variant = p.get(key)
		if not v is Array or (v as Array).size() != 12:
			return "climograph: %s has 12 months" % key
		for x: Variant in v:
			if not _number(x):
				return "climograph: %s is numbers" % key
	for key: String in ["t_top", "t_step", "r_top", "r_step"]:
		if not _whole(p.get(key)):
			return "climograph: %s is a whole number" % key
	if p.has("t_from") and not _whole(p.t_from):
		return "climograph: t_from is a whole number"
	var t_from := int(p.get("t_from", 0))
	var t_steps := 0
	var r_steps := 0
	if int(p.t_step) > 0 and int(p.t_top) > t_from and (int(p.t_top) - t_from) % int(p.t_step) == 0:
		t_steps = (int(p.t_top) - t_from) / int(p.t_step)
	if int(p.r_step) > 0 and int(p.r_top) > 0 and int(p.r_top) % int(p.r_step) == 0:
		r_steps = int(p.r_top) / int(p.r_step)
	if t_steps < 2 or t_steps > MAX_CLIMATE_STEPS or r_steps != t_steps:
		return "climograph: both scales have the same 2-%d equal steps" % MAX_CLIMATE_STEPS
	for x: Variant in p.temp:
		if float(x) < t_from or float(x) > int(p.t_top):
			return "climograph: every temperature is on its scale"
	for x: Variant in p.rain:
		if float(x) < 0.0 or float(x) > int(p.r_top):
			return "climograph: every month's rain is on its scale"
	if p.has("name") and (not p.name is String or str(p.name).length() > 20):
		return "climograph: a name of up to 20 letters"
	if p.has("mark") and not (_whole(p.mark) and int(p.mark) >= 0 and int(p.mark) < 12):
		return "climograph: mark is a month, 0-11"
	return ""


static func _layer_problem(p: Dictionary) -> String:
	if not _whole(p.get("w")) or int(p.w) < LAYER_W.x or int(p.w) > LAYER_W.y:
		return "layer_map: w is %d-%d" % [LAYER_W.x, LAYER_W.y]
	if not _whole(p.get("h")) or int(p.h) < LAYER_H.x or int(p.h) > LAYER_H.y:
		return "layer_map: h is %d-%d" % [LAYER_H.x, LAYER_H.y]
	var layers: Variant = p.get("layers")
	if not layers is Array or (layers as Array).is_empty() or (layers as Array).size() > MAX_LAYERS:
		return "layer_map: 1-%d layers" % MAX_LAYERS
	for l: Variant in layers:
		if not l is Dictionary or not THINGS.has(str(l.get("what", ""))):
			return "layer_map: a layer is {name, what: %s, cells}" % [THINGS]
		var name: Variant = l.get("name")
		if not name is String or str(name).strip_edges() == "" or str(name).length() > MAX_LAYER_NAME:
			return "layer_map: a layer's name is 1-%d letters" % MAX_LAYER_NAME
		var cells: Variant = l.get("cells")
		if not cells is Array or (cells as Array).size() != int(p.h):
			return "layer_map: a layer's cells are %d rows" % int(p.h)
		for row: Variant in cells:
			if not row is String or str(row).length() != int(p.w):
				return "layer_map: every row is %d cells" % int(p.w)
			for ch in str(row):
				if ch != "#" and ch != ".":
					return "layer_map: a cell is # or ."
	if p.has("view") and not LAYER_VIEWS.has(str(p.view)):
		return "layer_map: view is one of %s" % [LAYER_VIEWS]
	return ""


static func _whole(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT and is_equal_approx(float(v), roundf(float(v)))


static func _number(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT]


# --- Drawing ----------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"event_timeline":
			_draw_timeline(pic, font, r, d)
		"quipu":
			_draw_quipu(pic, font, r, d)
		"feudal_pyramid":
			_draw_pyramid(pic, font, r, d)
		"castle_type":
			_draw_castle(pic, font, r, d)
		"dot_density":
			_draw_density(pic, font, r, d)
		"city_zones":
			_draw_zones(pic, font, r, d)
		"os_map":
			_draw_os_map(pic, font, r, d)
		"climograph":
			_draw_climograph(pic, font, r, d)
		"river_course":
			_draw_river(pic, font, r, d)
		"layer_map":
			_draw_layers(pic, font, r, d)
		"savings_growth":
			_draw_savings(pic, font, r, d)


static func _fs(r: Rect2, per: float = 14.0) -> int:
	return clampi(int(minf(r.size.y / per, r.size.x / (per * 2.0))), 9, 18)


static func _text_w(font: Font, text: String, fs: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


## Text centred on `c`, with a paper-coloured edge so it reads over lines.
static func _say(ci: CanvasItem, font: Font, c: Vector2, text: String, fs: int, colour: Color = INK,
		edge: bool = true) -> void:
	var w := _text_w(font, text, fs)
	var base := Vector2(c.x - w * 0.5, c.y + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5)
	if edge:
		ci.draw_string_outline(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color.WHITE)
	ci.draw_string(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)


## Text starting at `at` (left, vertically centred), or ending there when `right`.
static func _say_from(ci: CanvasItem, font: Font, at: Vector2, text: String, fs: int, colour: Color = INK,
		right: bool = false) -> void:
	var w := _text_w(font, text, fs)
	_say(ci, font, Vector2(at.x - w * 0.5 if right else at.x + w * 0.5, at.y), text, fs, colour)


static func _arrow(ci: CanvasItem, from: Vector2, to: Vector2, colour: Color, width: float) -> void:
	var dir := (to - from).normalized()
	var head := maxf(8.0, width * 3.0)
	ci.draw_line(from, to - dir * head * 0.6, colour, width, true)
	var side := Vector2(-dir.y, dir.x)
	ci.draw_colored_polygon(PackedVector2Array([to, to - dir * head + side * head * 0.5, to - dir * head - side * head * 0.5]),
		colour)


static func _box(ci: CanvasItem, rect: Rect2, fill: Color, border: Color, radius: int = 6, width: int = 2) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	ci.draw_style_box(sb, rect)


## A label's colour and words: orange when marked, "?" when hidden.
static func _label_of(d: Dictionary, key: String, words: String) -> Array:
	if d.has("hide") and str(d.hide) == key:
		return ["?", ORANGE]
	return [words, ORANGE if d.has("mark") and str(d.mark) == key else INK]


# --- Timeline ---------------------------------------------------------------------------------------------------------

static func _draw_timeline(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var from := int(d.from)
	var to := int(d.to)
	var step := int(d.step)
	var with_ad := from < 0
	var fs := clampi(int(minf(r.size.y / 11.0, r.size.x / 30.0)), 9, 17)
	var events: Array = d.events
	var order: Array = range(events.size())
	order.sort_custom(func(a: int, b: int) -> bool: return int(events[a][0]) < int(events[b][0]))
	var edge := maxf(_text_w(font, year_text(from, with_ad), fs), _text_w(font, year_text(to, with_ad), fs)) * 0.5 + 6.0
	var x0 := r.position.x + edge
	var x1 := r.end.x - edge
	# Each label's box, in the lowest row (nearest the line) where it fits beside the others.
	var boxes := {}   # event index -> [box left, width, row]
	var row_ends: Array[float] = []
	for i: int in order:
		var text := "?" if d.has("hide") and int(d.hide) == i else str(events[i][1])
		var tw := _text_w(font, text, fs) + 12.0
		var x := _tl_x(x0, x1, from, to, float(events[i][0]))
		var bx := clampf(x - tw * 0.5, r.position.x, r.end.x - tw)
		var row := -1
		for k in row_ends.size():
			if bx >= row_ends[k] + 6.0:
				row = k
				break
		if row < 0 and row_ends.size() < 4:
			row_ends.append(-INF)
			row = row_ends.size() - 1
		elif row < 0:   # four rows full: the row whose last box ends first
			row = 0
			for k in row_ends.size():
				if row_ends[k] < row_ends[row]:
					row = k
			bx = maxf(bx, row_ends[row] + 6.0)
		row_ends[row] = bx + tw
		boxes[i] = [bx, tw, row, text]
	var rows := row_ends.size()
	var eras: Array = d.get("eras", [])
	var below := fs * 1.7 + (fs * 1.9 if not eras.is_empty() else 0.0)
	var row_h := minf(fs * 2.2, (r.size.y - below - 14.0) / maxf(rows, 1))
	var y := r.position.y + (r.size.y - rows * row_h - below - 8.0) * 0.5 + rows * row_h + 6.0
	# Eras: shaded bands under the years.
	for i in eras.size():
		var e: Array = eras[i]
		var a := _tl_x(x0, x1, from, to, float(e[0]))
		var b := _tl_x(x0, x1, from, to, float(e[1]))
		var band := Rect2(a, y + fs * 1.6, b - a, fs * 1.6)
		ci.draw_rect(band, ERA_COLOURS[i % ERA_COLOURS.size()])
		ci.draw_rect(band, INK, false, 1.0)
		var efs := fs - 2
		while efs > 8 and _text_w(font, str(e[2]), efs) > band.size.x - 4.0:
			efs -= 1
		_say(ci, font, band.get_center(), str(e[2]), efs, INK, false)
	# The line and its years.
	ci.draw_line(Vector2(x0, y), Vector2(x1, y), INK, 3.0)
	var steps := (to - from) / step
	var widest := 0.0
	for k in steps + 1:
		widest = maxf(widest, _text_w(font, year_text(from + k * step, with_ad), fs - 1))
	var every := maxi(1, ceili((widest + 8.0) / ((x1 - x0) / steps)))
	for k in steps + 1:
		var yr := from + k * step
		var x := _tl_x(x0, x1, from, to, float(yr))
		ci.draw_line(Vector2(x, y - 6.0), Vector2(x, y + 6.0), INK, 2.0)
		if yr == 0:   # no year 0: where BC meets AD
			ci.draw_line(Vector2(x, y - 12.0), Vector2(x, y + 12.0), RED, 3.0)
			_say_from(ci, font, Vector2(x - 4.0, y + fs * 0.9), "BC", fs - 2, RED, true)
			_say_from(ci, font, Vector2(x + 4.0, y + fs * 0.9), "AD", fs - 2, RED)
		elif k % every == 0 or k == steps:
			_say(ci, font, Vector2(x, y + fs * 0.9), year_text(yr, with_ad), fs - 1, INK, false)
	# The events: a leader line from each dot to its label (the far rows first, so nearer boxes sit on their lines).
	for pass_row in range(rows - 1, -1, -1):
		for i: int in order:
			var b: Array = boxes[i]
			if int(b[2]) != pass_row:
				continue
			var x := _tl_x(x0, x1, from, to, float(events[i][0]))
			var marked := d.has("mark") and int(d.mark) == i
			var ly := y - 8.0 - (pass_row + 0.5) * row_h
			var bh := minf(fs * 1.4, row_h - 3.0)
			ci.draw_line(Vector2(x, y), Vector2(x, ly + bh * 0.5), INK, 1.5)
			_box(ci, Rect2(float(b[0]), ly - bh * 0.5, float(b[1]), bh), SOFT if marked else Color.WHITE,
				ORANGE if marked else INK, 5, 2)
			_say(ci, font, Vector2(float(b[0]) + float(b[1]) * 0.5, ly), str(b[3]), fs, INK, false)
	for i: int in order:
		var marked := d.has("mark") and int(d.mark) == i
		ci.draw_circle(Vector2(_tl_x(x0, x1, from, to, float(events[i][0])), y), 6.0, ORANGE if marked else INK)


static func _tl_x(x0: float, x1: float, from: int, to: int, year: float) -> float:
	return x0 + (year - from) / float(to - from) * (x1 - x0)


# --- Quipu ------------------------------------------------------------------------------------------------------------

static func _draw_quipu(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var cords: Array = d.cords
	var fs := _fs(r, 13.0)
	var biggest := 0
	for c: Variant in cords:
		biggest = maxi(biggest, int(c))
	var places := clampi(str(biggest).length(), 1, 4)
	var names: Array = d.get("names", [])
	var labels := bool(d.get("labels", false))
	var under := (fs * 1.5 if not names.is_empty() else 0.0) + (fs * 1.5 if labels else 0.0)
	var words := ["1000s", "100s", "10s", "1s"].slice(4 - places)
	var left := (_text_w(font, "1000s", fs) + 14.0) if bool(d.get("places", false)) else 6.0
	var cord_top := r.position.y + 10.0
	var cord_bottom := r.end.y - under - 4.0
	var gap := (cord_bottom - cord_top - 10.0) / (places + 0.2)
	ci.draw_line(Vector2(r.position.x + left - 4.0, cord_top), Vector2(r.end.x - 4.0, cord_top), MAIN_CORD, 7.0, true)
	var spacing := (r.end.x - 4.0 - (r.position.x + left)) / cords.size()
	var most := 1   # the most knots in one column (up to 5; a sixth starts a second column), so a cluster fits its row
	for c: Variant in cords:
		for digit in quipu_digits(int(c)):
			most = maxi(most, mini(digit, 5))
	var rk := clampf(minf(gap * 0.9 / (most * 1.75 + 0.6), spacing / 9.0), 2.5, 10.0)
	if bool(d.get("places", false)):
		for k in places:
			var py := cord_top + 10.0 + gap * (k + 0.55)
			ci.draw_dashed_line(Vector2(r.position.x + left - 6.0, py), Vector2(r.end.x - 6.0, py), Color("c9b89a"), 1.5, 6.0)
			_say_from(ci, font, Vector2(r.position.x + 2.0, py), words[k], fs - 1, INK)
	for i in cords.size():
		var x := r.position.x + left + spacing * (i + 0.5)
		var colour := CORD_COLOURS[i % CORD_COLOURS.size()]
		ci.draw_line(Vector2(x, cord_top), Vector2(x, cord_bottom), colour, 4.0, true)
		ci.draw_circle(Vector2(x, cord_top), 5.0, colour.darkened(0.3))
		var digits := quipu_digits(int(cords[i]))
		for k in places:
			var digit := digits[4 - places + k]
			var cy := cord_top + 10.0 + gap * (k + 0.55)
			match knot_kind(digit, k == places - 1):
				"single":   # a column of up to 5 knots, the rest in a second column beside it, so they can be counted
					var tall := mini(digit, 5)
					for s in digit:
						var col := s / 5
						var row := s % 5
						var kx := x + (0.0 if digit <= 5 else (col - 0.5) * rk * 2.3)
						var at := Vector2(kx, cy + (row - (tall - 1) * 0.5) * rk * 1.75)
						ci.draw_circle(at, rk, KNOT)
						ci.draw_arc(at, rk, 0.0, TAU, 12, KNOT.lightened(0.35), 1.0)
				"eight":
					ci.draw_arc(Vector2(x, cy - rk * 0.75), rk * 0.8, 0.0, TAU, 16, KNOT, 3.0)
					ci.draw_arc(Vector2(x, cy + rk * 0.75), rk * 0.8, 0.0, TAU, 16, KNOT, 3.0)
				"long":
					var h := (digit + 1) * rk * 0.9 * minf(1.0, (5 * 1.75 + 0.6) / ((digit + 1) * 0.9))
					_box(ci, Rect2(x - rk, cy - h * 0.5, rk * 2.0, h), KNOT, KNOT.darkened(0.3), int(rk), 1)
					for t in digit:
						var ty := cy - h * 0.5 + (t + 1) * h / (digit + 1)
						ci.draw_line(Vector2(x - rk * 0.9, ty + rk * 0.25), Vector2(x + rk * 0.9, ty - rk * 0.25),
							Color("d8b48a"), 1.5)
		var ty := cord_bottom + fs * 0.8
		if not names.is_empty():
			_say(ci, font, Vector2(x, ty), str(names[i]), fs - 1, INK, false)
			ty += fs * 1.5
		if labels:
			_say(ci, font, Vector2(x, ty), GenKit.fmt(int(cords[i])), fs, INK, false)


# --- The feudal system ------------------------------------------------------------------------------------------------

static func _draw_pyramid(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var arrows := bool(d.get("arrows", false))
	var side := (_text_w(font, "service", fs) + 26.0) if arrows else 0.0
	var h := r.size.y - 6.0
	var w := minf(r.size.x - 2.0 * side - 8.0, h * 1.5)
	var apex := Vector2(r.get_center().x, r.position.y + 3.0)
	var base_y := apex.y + h
	var half := w * 0.5
	var bands: Array[float] = [0.0, 0.3, 0.52, 0.74, 1.0]   # the king's band is the tallest, so his name fits
	for i in LEVELS.size():
		var t0 := bands[i]
		var t1 := bands[i + 1]
		var y0 := apex.y + h * t0
		var y1 := apex.y + h * t1
		var poly := PackedVector2Array([Vector2(apex.x - half * t0, y0), Vector2(apex.x + half * t0, y0),
			Vector2(apex.x + half * t1, y1), Vector2(apex.x - half * t1, y1)])
		var said: Array = _label_of(d, LEVELS[i], str(LEVEL_NAMES[LEVELS[i]]))
		ci.draw_colored_polygon(poly, ORANGE.lightened(0.35) if said[1] == ORANGE else LEVEL_COLOURS[i])
		poly.append(poly[0])
		ci.draw_polyline(poly, INK, 2.0, true)
		var ty := y0 + (y1 - y0) * (0.66 if i == 0 else 0.5)
		var room := half * (t0 + t1) * (0.66 if i == 0 else 1.0) * 2.0 * 0.5
		var lfs := fs
		while lfs > 8 and _text_w(font, str(said[0]), lfs) > room * 1.6:
			lfs -= 1
		_say(ci, font, Vector2(apex.x, ty), str(said[0]), lfs, INK, false)
	if arrows:
		var lx := apex.x - half - side * 0.5
		var rx := apex.x + half + side * 0.5
		_arrow(ci, Vector2(lx, apex.y + h * 0.25), Vector2(lx, base_y - 4.0), Color("2f7d32"), 4.0)
		_say(ci, font, Vector2(lx, apex.y + h * 0.14), "land", fs, Color("2f7d32"))
		_arrow(ci, Vector2(rx, base_y - 4.0), Vector2(rx, apex.y + h * 0.25), Color("7a3fb0"), 4.0)
		_say(ci, font, Vector2(rx, apex.y + h * 0.08), "service", fs - 1, Color("7a3fb0"))
		_say(ci, font, Vector2(rx, apex.y + h * 0.08 + fs * 1.1), "loyalty", fs - 1, Color("7a3fb0"))


# --- Castles ----------------------------------------------------------------------------------------------------------

static func _draw_castle(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var labels := bool(d.get("labels", false))
	var names: Dictionary = {}   # part -> where its leader line starts
	var type := str(d.type)
	var sky := r
	if type == "concentric":
		_concentric(ci, r, names)
	else:
		var ground := r.position.y + r.size.y * 0.78
		ci.draw_rect(Rect2(r.position.x, ground, r.size.x, r.end.y - ground), GRASS)
		if type == "motte_bailey":
			_motte_bailey(ci, r, ground, names)
		else:
			_stone_keep(ci, r, ground, names)
	if not labels:
		return
	var parts: Array = CASTLE_PARTS[type]
	for on_top: bool in [true, false]:   # labels along the top and bottom edges, spread so they never overlap
		var row: Array = []
		for part: String in parts:
			var from: Vector2 = names.get(part, sky.get_center())
			if (from.y < r.get_center().y) == on_top:
				row.append([from.x, _text_w(font, part, fs) + 10.0, part])
		var centres := _spread(row, r.position.x, r.end.x, 6.0)
		var ly := r.position.y + fs * 0.9 if on_top else r.end.y - fs * 0.9
		for k in row.size():
			var part := str(row[k][2])
			var tw := float(row[k][1])
			var lx := centres[k]
			ci.draw_line(names[part], Vector2(lx, ly + (fs * 0.7 if on_top else -fs * 0.7)), INK, 1.5)
			_box(ci, Rect2(lx - tw * 0.5, ly - fs * 0.7, tw, fs * 1.4), Color.WHITE, INK, 5, 1)
			_say(ci, font, Vector2(lx, ly), part, fs, INK, false)


## Centres for boxes [wanted centre, width, …] in a row from lo to hi, in the order they are wanted, at least `gap`
## apart (as near their wanted centres as the room allows).
static func _spread(boxes: Array, lo: float, hi: float, gap: float) -> Array[float]:
	var order: Array = range(boxes.size())
	order.sort_custom(func(a: int, b: int) -> bool: return float(boxes[a][0]) < float(boxes[b][0]))
	var left: Array[float] = []
	left.resize(boxes.size())
	var edge := lo
	for i: int in order:   # left to right: no box before the last one's end
		left[i] = maxf(float(boxes[i][0]) - float(boxes[i][1]) * 0.5, edge)
		edge = left[i] + float(boxes[i][1]) + gap
	edge = hi
	for k in range(order.size() - 1, -1, -1):   # right to left: none past the edge
		var i: int = order[k]
		left[i] = minf(left[i], edge - float(boxes[i][1]))
		edge = left[i] - gap
	var out: Array[float] = []
	for i in boxes.size():
		out.append(maxf(left[i], lo) + float(boxes[i][1]) * 0.5)
	return out


static func _battlements(ci: CanvasItem, x0: float, x1: float, y: float, s: float, colour: Color) -> void:
	var x := x0
	while x + s <= x1 + 0.5:
		ci.draw_rect(Rect2(x, y - s, s * 0.6, s), colour)
		x += s


static func _motte_bailey(ci: CanvasItem, r: Rect2, ground: float, names: Dictionary) -> void:
	var w := r.size.x
	var x := r.position.x
	var h := ground - r.position.y
	# the ditch round the motte, then the motte (a mound of earth) with its wooden keep
	var ditch := PackedVector2Array([Vector2(x + w * 0.05, ground), Vector2(x + w * 0.09, ground + h * 0.1),
		Vector2(x + w * 0.5, ground + h * 0.1), Vector2(x + w * 0.54, ground)])
	ci.draw_colored_polygon(ditch, Color("8fb7d6"))
	var motte := PackedVector2Array([Vector2(x + w * 0.08, ground), Vector2(x + w * 0.2, ground - h * 0.42),
		Vector2(x + w * 0.34, ground - h * 0.42), Vector2(x + w * 0.47, ground)])
	ci.draw_colored_polygon(motte, Color("93b872"))
	ci.draw_polyline(motte, Color("5f7f45"), 2.0, true)
	var keep := Rect2(x + w * 0.21, ground - h * 0.82, w * 0.12, h * 0.4)
	ci.draw_rect(keep, WOOD)
	for k in 5:
		var px := keep.position.x + keep.size.x * (k + 0.5) / 5.0
		ci.draw_line(Vector2(px, keep.position.y), Vector2(px, keep.end.y), WOOD.darkened(0.3), 1.0)
	_battlements(ci, keep.position.x, keep.end.x, keep.position.y, keep.size.x / 4.0, WOOD)
	# the bailey: a yard with huts, inside a palisade of pointed stakes
	var bx0 := x + w * 0.55
	var bx1 := x + w * 0.95
	var huts: Array[float] = [0.62, 0.75]
	for hx: float in huts:
		var hut := Rect2(x + w * hx, ground - h * 0.3, w * 0.07, h * 0.14)   # behind the palisade, their tops show
		ci.draw_rect(hut, Color("d9b98c"))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(hut.position.x - 3.0, hut.position.y),
			Vector2(hut.get_center().x, hut.position.y - h * 0.08), Vector2(hut.end.x + 3.0, hut.position.y)]), Color("9a6b3a"))
	var stake := maxf(5.0, w * 0.018)
	var sx := bx0
	while sx < bx1:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(sx, ground), Vector2(sx, ground - h * 0.2),
			Vector2(sx + stake * 0.5, ground - h * 0.25), Vector2(sx + stake, ground - h * 0.2), Vector2(sx + stake, ground)]),
			WOOD if int((sx - bx0) / stake) % 2 == 0 else WOOD.darkened(0.15))
		sx += stake
	# a bridge from the bailey up to the keep
	ci.draw_line(Vector2(bx0, ground - h * 0.2), Vector2(x + w * 0.33, ground - h * 0.45), WOOD.darkened(0.2), 4.0)
	names["motte"] = Vector2(x + w * 0.14, ground - h * 0.18)
	names["keep"] = Vector2(keep.get_center().x, keep.position.y - 4.0)
	names["bailey"] = Vector2(x + w * 0.65, ground - h * 0.27)
	names["palisade"] = Vector2(x + w * 0.9, ground - h * 0.22)
	names["ditch"] = Vector2(x + w * 0.46, ground + h * 0.06)


static func _stone_keep(ci: CanvasItem, r: Rect2, ground: float, names: Dictionary) -> void:
	var w := r.size.x
	var x := r.position.x
	var h := ground - r.position.y
	ci.draw_rect(Rect2(x, ground, w, h * 0.08), Color("8fb7d6"))   # the moat in front
	var keep := Rect2(x + w * 0.4, ground - h * 0.8, w * 0.2, h * 0.8)
	ci.draw_rect(keep, STONE)
	_battlements(ci, keep.position.x, keep.end.x, keep.position.y, keep.size.x / 5.0, STONE)
	for k in 3:
		for j in 2:
			ci.draw_rect(Rect2(keep.position.x + keep.size.x * (0.25 + 0.4 * j), keep.position.y + keep.size.y * (0.12 + 0.2 * k),
				keep.size.x * 0.1, keep.size.y * 0.08), DARK_STONE)
	var wall := Rect2(x + w * 0.1, ground - h * 0.38, w * 0.8, h * 0.38)
	ci.draw_rect(wall, Color("b8b3a8"))
	_battlements(ci, wall.position.x, wall.end.x, wall.position.y, wall.size.x / 24.0, Color("b8b3a8"))
	for tx: float in [0.06, 0.86]:
		var tower := Rect2(x + w * tx, ground - h * 0.52, w * 0.08, h * 0.52)
		ci.draw_rect(tower, STONE)
		_battlements(ci, tower.position.x, tower.end.x, tower.position.y, tower.size.x / 3.0, STONE)
	var gate := Rect2(x + w * 0.44, ground - h * 0.26, w * 0.12, h * 0.26)
	ci.draw_rect(Rect2(gate.position.x - w * 0.03, ground - h * 0.46, gate.size.x + w * 0.06, h * 0.46), STONE)
	_battlements(ci, gate.position.x - w * 0.03, gate.end.x + w * 0.03, ground - h * 0.46, (gate.size.x + w * 0.06) / 4.0,
		STONE)
	ci.draw_rect(gate, Color("4a3b2c"))
	ci.draw_circle(Vector2(gate.get_center().x, gate.position.y), gate.size.x * 0.5, Color("4a3b2c"))
	ci.draw_line(Vector2(gate.position.x, ground), Vector2(gate.end.x, ground), WOOD, 5.0)   # the drawbridge, down
	names["keep"] = Vector2(keep.get_center().x - keep.size.x * 0.25, keep.position.y - 4.0)
	names["curtain wall"] = Vector2(x + w * 0.25, wall.position.y + 2.0)
	names["gatehouse"] = Vector2(gate.get_center().x, ground - h * 0.1)
	names["tower"] = Vector2(x + w * 0.9, ground - h * 0.5)
	names["moat"] = Vector2(x + w * 0.2, ground + h * 0.04)


static func _concentric(ci: CanvasItem, r: Rect2, names: Dictionary) -> void:
	var c := r.get_center()
	var s := minf(r.size.y * 0.46, r.size.x * 0.3)
	ci.draw_rect(Rect2(r.position, r.size), GRASS)
	ci.draw_rect(Rect2(c - Vector2(s, s), Vector2(2 * s, 2 * s)), Color("8fb7d6"))   # the moat
	ci.draw_rect(Rect2(c - Vector2(s, s) * 0.84, Vector2(s, s) * 1.68), Color("d9d0b8"))   # the outer ward
	var outer := Rect2(c - Vector2(s, s) * 0.84, Vector2(s, s) * 1.68)
	ci.draw_rect(outer, STONE, false, maxf(4.0, s * 0.07))
	var inner := Rect2(c - Vector2(s, s) * 0.55, Vector2(s, s) * 1.1)
	ci.draw_rect(inner, Color("cfe3b0"))   # the inner ward
	ci.draw_rect(inner, DARK_STONE, false, maxf(6.0, s * 0.11))
	for rect: Rect2 in [outer, inner]:
		var rad := maxf(5.0, s * (0.07 if rect == outer else 0.1))
		for corner: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
			ci.draw_circle(corner, rad, DARK_STONE if rect == inner else STONE)
			ci.draw_arc(corner, rad, 0.0, TAU, 16, INK, 1.5)
	var gate := Rect2(c.x - s * 0.12, c.y + s * 0.5, s * 0.24, s * 0.44)
	ci.draw_rect(gate, DARK_STONE)
	ci.draw_rect(Rect2(c.x - s * 0.05, c.y + s * 0.5, s * 0.1, s * 0.44), Color("4a3b2c"))
	ci.draw_rect(Rect2(c.x - s * 0.06, c.y + s * 0.94, s * 0.12, s * 0.12), WOOD)   # the bridge over the moat
	names["outer wall"] = Vector2(outer.position.x + outer.size.x * 0.3, outer.position.y)
	names["inner wall"] = Vector2(inner.end.x, inner.get_center().y - s * 0.2)
	names["tower"] = Vector2(outer.end.x, outer.position.y)
	names["gatehouse"] = Vector2(gate.position.x, gate.get_center().y)
	names["moat"] = Vector2(c.x + s * 0.6, c.y + s * 0.92)


# --- Population density -----------------------------------------------------------------------------------------------

static func _draw_density(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var areas: Array = d.areas
	var fs := _fs(r, 13.0)
	var each := int(d.get("each", 1))
	var key := fs * 1.4 if each > 1 else 0.0
	var panel_w := r.size.x / areas.size()
	var room_h := r.size.y - fs * 2.9 - key
	for i in areas.size():
		var a: Dictionary = areas[i]
		var km2 := int(a.km2)
		var cols := ceili(sqrt(float(km2)))
		var rows := ceili(float(km2) / cols)
		var s := minf(panel_w * 0.84 / cols, room_h / rows)
		var origin := Vector2(r.position.x + panel_w * (i + 0.5) - cols * s * 0.5, r.position.y + (room_h - rows * s) * 0.5)
		var cells: Array[Rect2] = []
		for k in km2:
			var cell := Rect2(origin + Vector2(k % cols, k / cols) * s, Vector2(s, s))
			cells.append(cell)
			ci.draw_rect(cell, GRASS)
			ci.draw_rect(cell, Color("6d9a4f"), false, 1.5)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(str(a.name))
		var dot := clampf(s * 0.05, 2.0, 5.0)
		for k in int(a.people):
			var cell := cells[k % cells.size()]
			var p := cell.position + Vector2(rng.randf_range(0.12, 0.88), rng.randf_range(0.12, 0.88)) * s
			ci.draw_circle(p, dot, INK)
		var cx := r.position.x + panel_w * (i + 0.5)
		_say(ci, font, Vector2(cx, r.position.y + room_h + fs * 0.9), str(a.name), fs, INK, false)
		_say(ci, font, Vector2(cx, r.position.y + room_h + fs * 2.2), "%d km²" % km2, fs - 1, INK, false)
	if each > 1:
		var ky := r.end.y - key * 0.5
		var words := "= %s people" % GenKit.fmt(each)
		var kw := _text_w(font, words, fs - 1) + 14.0
		ci.draw_circle(Vector2(r.get_center().x - kw * 0.5, ky), 4.0, INK)
		_say_from(ci, font, Vector2(r.get_center().x - kw * 0.5 + 10.0, ky), words, fs - 1)


# --- City zones -------------------------------------------------------------------------------------------------------

static func _draw_zones(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var labels := bool(d.get("labels", true))
	var rad := minf(r.size.y * 0.47, r.size.x * (0.26 if labels else 0.47))
	var c := Vector2(r.position.x + (rad + 6.0 if labels else r.size.x * 0.5), r.get_center().y)
	var radii: Array[float] = [0.28, 0.52, 0.8, 1.0]   # cbd, inner city, suburbs, fringe
	for i in range(ZONES.size() - 1, -1, -1):
		var z := ZONES[i]
		var marked := d.has("mark") and str(d.mark) == z
		ci.draw_circle(c, rad * radii[i], ORANGE.lightened(0.4) if marked else ZONE_COLOURS[z])
		ci.draw_arc(c, rad * radii[i], 0.0, TAU, 48, INK, 1.5)
	# What each ring is like: fields and trees, houses with gardens, rows of houses, tall offices.
	for k in 10:
		var a := TAU * k / 10.0 + 0.2
		var p := c + Vector2(cos(a), sin(a)) * rad * 0.9
		ci.draw_circle(p, rad * 0.035, Color("4f8a3a"))
	for k in 12:
		var a := TAU * k / 12.0
		var p := c + Vector2(cos(a), sin(a)) * rad * 0.66
		var hs := rad * 0.045
		ci.draw_rect(Rect2(p - Vector2(hs, hs * 0.6), Vector2(hs * 2.0, hs * 1.4)), Color("e7d3a6"))
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-hs * 1.2, -hs * 0.6), p + Vector2(0, -hs * 1.5),
			p + Vector2(hs * 1.2, -hs * 0.6)]), Color("c0533a"))
	for k in 8:
		var a := TAU * k / 8.0 + 0.3
		var p := c + Vector2(cos(a), sin(a)) * rad * 0.4
		ci.draw_rect(Rect2(p - Vector2(rad * 0.06, rad * 0.025), Vector2(rad * 0.12, rad * 0.05)), Color("a0522d"))
	for k in 3:
		var bw := rad * 0.07
		var bh := rad * (0.22 + 0.06 * k)
		ci.draw_rect(Rect2(c.x + (k - 1.5) * bw * 1.3, c.y + rad * 0.1 - bh, bw, bh), Color("5d6d7e"))
	if not labels:
		return
	var tx := c.x + rad + 16.0
	for i in ZONES.size():
		var z := ZONES[i]
		var said: Array = _label_of(d, z, str(ZONE_NAMES[z]))
		var ty := r.position.y + r.size.y * (0.14 + 0.24 * i)
		var ring := rad * (radii[i] - (radii[i] - (radii[i - 1] if i > 0 else 0.0)) * 0.5)
		var a := -0.9 + 0.55 * i
		var from := c + Vector2(cos(a), sin(a)) * ring
		ci.draw_line(from, Vector2(tx - 4.0, ty), INK, 1.5)
		ci.draw_circle(from, 3.0, INK)
		var lfs := fs
		while lfs > 8 and _text_w(font, str(said[0]), lfs) > r.end.x - tx - 2.0:
			lfs -= 1
		_say_from(ci, font, Vector2(tx, ty), str(said[0]), lfs, said[1])


# --- A detailed map ---------------------------------------------------------------------------------------------------

static func _draw_os_map(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 15.0)
	var cols := int(d.cols)
	var rows := int(d.rows)
	var e0 := int(d.e0)
	var n0 := int(d.n0)
	var km := bool(d.get("km", false))
	var left := _text_w(font, "99", fs) + 8.0
	var bottom := fs + 8.0 + (fs * 1.6 if km else 0.0)
	var s := minf((r.size.x - left - 8.0) / cols, (r.size.y - bottom - 6.0) / rows)
	var map := Rect2(Vector2(r.position.x + left + (r.size.x - left - 8.0 - s * cols) * 0.5, r.position.y + 4.0),
		Vector2(s * cols, s * rows))
	ci.draw_rect(map, OS_PAPER)
	# Contours: rings round each hill's top, bunched on its steep side; their heights on the other side.
	for hill: Dictionary in d.get("hills", []):
		var heights: Array = hill.heights
		var m := heights.size()
		var centre := _os_at(map, s, e0, n0, float(hill.e), float(hill.n))
		var big := float(hill.get("size", 8)) / 10.0 * s
		var dir := Vector2.ZERO
		match str(hill.get("steep", "")):
			"n": dir = Vector2(0, -1)
			"e": dir = Vector2(1, 0)
			"s": dir = Vector2(0, 1)
			"w": dir = Vector2(-1, 0)
		for k in m:
			var rad := big * (m - k) / float(m)
			var shift := dir * (big - rad) * 0.8
			var pts := PackedVector2Array()
			for a in 49:
				var t := TAU * a / 48.0
				var wobble := 1.0 + 0.07 * sin(3.0 * t + float(hill.e)) + 0.04 * cos(5.0 * t + float(hill.n))
				pts.append(centre + shift + Vector2(cos(t), sin(t)) * rad * wobble)
			ci.draw_polyline(pts, CONTOUR, 2.0, true)
			var label_at := centre + shift + (-dir if dir != Vector2.ZERO else Vector2(0, 1)) * rad
			_say(ci, font, label_at, str(int(heights[k])), maxi(fs - 3, 8), CONTOUR)
		if hill.has("top"):
			var top: Vector2 = centre + dir * big * 0.8
			ci.draw_circle(top, 3.0, INK)
			_say_from(ci, font, top + Vector2(5.0, 0.0), "%d" % int(hill.top), maxi(fs - 2, 8), INK)
	# The river.
	var river: Array = d.get("river", [])
	if river.size() >= 2:
		var pts := PackedVector2Array()
		for q: Variant in river:
			pts.append(_os_at(map, s, e0, n0, float(q[0]), float(q[1])))
		ci.draw_polyline(_smooth(pts), DEEP, maxf(3.0, s * 0.06), true)
	# The grid (blue lines, 1 km apart) and its numbers.
	for i in cols + 1:
		var x := map.position.x + i * s
		ci.draw_line(Vector2(x, map.position.y), Vector2(x, map.end.y), OS_GRID, 1.5)
		_say(ci, font, Vector2(x, map.end.y + fs * 0.8), "%02d" % (e0 + i), fs, OS_GRID.darkened(0.3), false)
	for j in rows + 1:
		var y := map.end.y - j * s
		ci.draw_line(Vector2(map.position.x, y), Vector2(map.end.x, y), OS_GRID, 1.5)
		_say_from(ci, font, Vector2(map.position.x - 4.0, y), "%02d" % (n0 + j), fs, OS_GRID.darkened(0.3), true)
	for i in cols * 10 + 1:   # tenths along the bottom and up the side, for six-figure references
		if i % 10 != 0:
			var tick := s * (0.1 if i % 5 == 0 else 0.05)
			var x := map.position.x + i * s / 10.0
			ci.draw_line(Vector2(x, map.end.y), Vector2(x, map.end.y - tick), OS_GRID.darkened(0.2), 1.0)
	for j in rows * 10 + 1:
		if j % 10 != 0:
			var tick := s * (0.1 if j % 5 == 0 else 0.05)
			var y := map.end.y - j * s / 10.0
			ci.draw_line(Vector2(map.position.x, y), Vector2(map.position.x + tick, y), OS_GRID.darkened(0.2), 1.0)
	ci.draw_rect(map, INK, false, 2.0)
	# Symbols and points.
	var sym := clampf(s * 0.2, 9.0, 18.0)
	for q: Dictionary in d.get("symbols", []):
		_os_symbol(ci, font, _os_at(map, s, e0, n0, float(q.e), float(q.n)), str(q.what), sym)
	for q: Dictionary in d.get("points", []):
		var p := _os_at(map, s, e0, n0, float(q.e), float(q.n))
		ci.draw_circle(p, 5.0, RED)
		ci.draw_arc(p, 5.0, 0.0, TAU, 16, Color.WHITE, 1.5)
		_say_from(ci, font, p + Vector2(7.0, -fs * 0.5), str(q.label), fs + 1, RED)
	if km:   # one square is 1 km
		var y := map.end.y + fs * 2.0
		ci.draw_rect(Rect2(map.position.x, y - 4.0, s, 8.0), INK)
		ci.draw_rect(Rect2(map.position.x + s * 0.5, y - 3.0, s * 0.5 - 1.0, 6.0), Color.WHITE)
		_say(ci, font, Vector2(map.position.x, y + fs * 0.8), "0", fs - 1, INK, false)
		_say_from(ci, font, Vector2(map.position.x + s + 4.0, y), "1 km", fs - 1)


## Where e and n (tenths of a square) are on the map drawn from grid lines e0 and n0, `s` pixels a square.
static func _os_at(map: Rect2, s: float, e0: int, n0: int, e: float, n: float) -> Vector2:
	return Vector2(map.position.x + (e - e0 * 10) / 10.0 * s, map.end.y - (n - n0 * 10) / 10.0 * s)


## A line through `pts`, rounded (Catmull-Rom).
static func _smooth(pts: PackedVector2Array) -> PackedVector2Array:
	if pts.size() < 3:
		return pts
	var out := PackedVector2Array()
	for i in pts.size() - 1:
		var p0 := pts[maxi(i - 1, 0)]
		var p1 := pts[i]
		var p2 := pts[i + 1]
		var p3 := pts[mini(i + 2, pts.size() - 1)]
		for k in 8:
			var t := k / 8.0
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
				+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t3))
	out.append(pts[pts.size() - 1])
	return out


static func _os_symbol(ci: CanvasItem, font: Font, p: Vector2, what: String, s: float) -> void:
	match what:
		"worship":   # a place of worship with a tower: a black square with a cross on it
			ci.draw_rect(Rect2(p - Vector2(s, s) * 0.45, Vector2(s, s) * 0.9), INK)
			ci.draw_line(p + Vector2(0, -s * 0.45), p + Vector2(0, -s * 1.3), INK, 2.0)
			ci.draw_line(p + Vector2(-s * 0.35, -s * 0.95), p + Vector2(s * 0.35, -s * 0.95), INK, 2.0)
		"school":
			_say(ci, font, p, "Sch", int(s * 1.3), INK)
		"farm":
			_say(ci, font, p, "Fm", int(s * 1.3), INK)
		"car_park":
			_box(ci, Rect2(p - Vector2(s, s) * 0.7, Vector2(s, s) * 1.4), BLUE, BLUE, 2, 1)
			_say(ci, font, p, "P", int(s * 1.3), Color.WHITE, false)
		"campsite":
			_box(ci, Rect2(p - Vector2(s, s) * 0.8, Vector2(s, s) * 1.6), BLUE, BLUE, 2, 1)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 0.6, s * 0.5), p + Vector2(0, -s * 0.6),
				p + Vector2(s * 0.6, s * 0.5)]), Color.WHITE)
		"viewpoint":   # a fan of lines
			for k in 7:
				var a := PI + PI * k / 6.0
				ci.draw_line(p, p + Vector2(cos(a), sin(a)) * s * 1.2, BLUE, 2.0)
			ci.draw_circle(p, s * 0.25, BLUE)
		"castle":
			ci.draw_rect(Rect2(p - Vector2(s * 0.8, s * 0.2), Vector2(s * 1.6, s * 0.8)), DARK_STONE)
			_battlements(ci, p.x - s * 0.8, p.x + s * 0.8, p.y - s * 0.2, s * 0.53, DARK_STONE)
		"bridge":   # two short lines across the river
			ci.draw_line(p + Vector2(-s, -s * 0.35), p + Vector2(s, -s * 0.35), INK, 2.5)
			ci.draw_line(p + Vector2(-s, s * 0.35), p + Vector2(s, s * 0.35), INK, 2.5)


# --- Climate graph ----------------------------------------------------------------------------------------------------

static func _draw_climograph(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 15.0)
	var t_from := int(d.get("t_from", 0))
	var t_top := int(d.t_top)
	var t_step := int(d.t_step)
	var r_top := int(d.r_top)
	var r_step := int(d.r_step)
	var steps := (t_top - t_from) / t_step
	var name := str(d.get("name", ""))
	var left := _text_w(font, "−20", fs) + 10.0
	var right := _text_w(font, "500", fs) + 10.0
	var top := fs * 1.6 + (fs * 1.2 if name != "" else 0.0)
	var plot := Rect2(Vector2(r.position.x + left, r.position.y + top),
		Vector2(r.size.x - left - right, r.size.y - top - fs * 1.4))
	if name != "":
		_say(ci, font, Vector2(r.get_center().x, r.position.y + fs * 0.6), name, fs, INK, false)
	_say(ci, font, Vector2(plot.position.x - left * 0.45, plot.position.y - fs * 0.8), "°C", fs - 1, RED, false)
	_say(ci, font, Vector2(plot.end.x + right * 0.45, plot.position.y - fs * 0.8), "mm", fs - 1, DEEP, false)
	for k in steps + 1:
		var y := plot.end.y - plot.size.y * k / steps
		ci.draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), Color("d5dbe6"), 1.0)
		var t := t_from + k * t_step
		var tt := ("−%d" % -t) if t < 0 else str(t)
		_say_from(ci, font, Vector2(plot.position.x - 5.0, y), tt, fs - 1, RED, true)
		_say_from(ci, font, Vector2(plot.end.x + 5.0, y), str(k * r_step), fs - 1, DEEP)
	var bw := plot.size.x / 12.0
	var line := PackedVector2Array()
	for m in 12:
		var x := plot.position.x + bw * m
		var rain := float(d.rain[m])
		var bh := plot.size.y * rain / r_top
		var marked := d.has("mark") and int(d.mark) == m
		ci.draw_rect(Rect2(x + bw * 0.12, plot.end.y - bh, bw * 0.76, bh), RAIN_BAR)
		if marked:
			ci.draw_rect(Rect2(x + 1.0, plot.position.y, bw - 2.0, plot.size.y), ORANGE, false, 3.0)
		_say(ci, font, Vector2(x + bw * 0.5, plot.end.y + fs * 0.75), MONTHS[m], fs - 1, ORANGE if marked else INK, false)
		var temp := float(d.temp[m])
		line.append(Vector2(x + bw * 0.5, plot.end.y - plot.size.y * (temp - t_from) / float(t_top - t_from)))
	if t_from < 0:   # 0 °C
		var zy := plot.end.y - plot.size.y * (0.0 - t_from) / float(t_top - t_from)
		ci.draw_line(Vector2(plot.position.x, zy), Vector2(plot.end.x, zy), Color("8a95a8"), 1.5)
	ci.draw_polyline(line, RED, 3.0, true)
	for p in line:
		ci.draw_circle(p, 3.5, RED)
	ci.draw_rect(plot, INK, false, 2.0)


# --- Rivers -----------------------------------------------------------------------------------------------------------

static func _draw_river(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 14.0)
	var names := {}   # label -> [where its words go, where its line points]
	match str(d.view):
		"long":
			_river_long(ci, r, fs, names)
		"plan":
			_river_plan(ci, r, names)
		"meander":
			_river_meander(ci, r, names)
		"waterfall":
			_river_waterfall(ci, r, names)
	if not bool(d.get("labels", false)):
		return
	for key: String in RIVER_LABELS[str(d.view)]:
		if not names.has(key):
			continue
		var said: Array = _label_of(d, key, key)
		var at: Vector2 = names[key][0]
		var to: Vector2 = names[key][1]
		var tw := _text_w(font, str(said[0]), fs) + 10.0
		var c := Vector2(clampf(at.x, r.position.x + tw * 0.5, r.end.x - tw * 0.5),
			clampf(at.y, r.position.y + fs * 0.7, r.end.y - fs * 0.7))
		if to != at:
			ci.draw_line(c, to, INK, 1.5)
			ci.draw_circle(to, 2.5, INK)
		_box(ci, Rect2(c.x - tw * 0.5, c.y - fs * 0.7, tw, fs * 1.4), Color.WHITE, ORANGE if said[1] == ORANGE else INK, 5,
			2 if said[1] == ORANGE else 1)
		_say(ci, font, c, str(said[0]), fs, said[1], false)


## The long profile: steep near the source, flatter towards the mouth, a waterfall's step in the upper course; each
## course's valley drawn under it.
static func _river_long(ci: CanvasItem, r: Rect2, fs: int, names: Dictionary) -> void:
	var prof := Rect2(r.position + Vector2(0, fs * 1.6), Vector2(r.size.x, r.size.y * 0.62 - fs * 1.6))
	var x0 := prof.position.x + 4.0
	var x1 := prof.end.x - prof.size.x * 0.1
	var high := prof.position.y + prof.size.y * 0.08
	var sea := prof.end.y - prof.size.y * 0.14
	var fall := 0.24
	var ground := PackedVector2Array([Vector2(x0, prof.end.y)])
	var river := PackedVector2Array()
	for k in 81:
		var t := k / 80.0
		var p := Vector2(x0 + (x1 - x0) * t, _long_height(sea, high, fall, t))
		if absf(t - fall) < 0.0001:
			p.y = _long_height(sea, high, fall, fall - 0.001)
		ground.append(p)
		river.append(p)
		if k == int(fall * 80.0):
			ground.append(Vector2(p.x + 1.0, _long_height(sea, high, fall, fall + 0.001)))
			river.append(Vector2(p.x + 1.0, _long_height(sea, high, fall, fall + 0.001)))
	ground.append(Vector2(x1, prof.end.y))
	ci.draw_rect(Rect2(x1 - 2.0, sea, prof.end.x - x1 + 2.0, prof.end.y - sea), WATER)
	ci.draw_colored_polygon(ground, Color("c9a77c"))
	ci.draw_polyline(river, DEEP, 4.0, true)
	for t: float in [1.0 / 3.0, 2.0 / 3.0]:
		var x := x0 + (x1 - x0) * t
		ci.draw_dashed_line(Vector2(x, prof.position.y - fs * 0.6), Vector2(x, prof.end.y), INK, 1.5, 6.0)
	var third := (x1 - x0) / 3.0
	var fall_at := Vector2(x0 + (x1 - x0) * fall, _long_height(sea, high, fall, fall))
	names["source"] = [Vector2(x0 + (x1 - x0) * 0.14, high + fs * 0.9), Vector2(x0 + 2.0, high)]
	names["waterfall"] = [fall_at + Vector2(fs * 3.2, -fs * 1.2), fall_at]
	names["mouth"] = [Vector2(x1 - fs * 2.0, sea - fs * 1.8), Vector2(x1, sea)]
	names["upper course"] = [Vector2(x0 + third * 0.5, prof.position.y - fs * 0.6), Vector2(x0 + third * 0.5, prof.position.y - fs * 0.6)]
	names["middle course"] = [Vector2(x0 + third * 1.5, prof.position.y - fs * 0.6), Vector2(x0 + third * 1.5, prof.position.y - fs * 0.6)]
	names["lower course"] = [Vector2(x0 + third * 2.5, prof.position.y - fs * 0.6), Vector2(x0 + third * 2.5, prof.position.y - fs * 0.6)]
	# Each course's valley, seen end on: a narrow V, a wider valley, a wide flat floodplain.
	var vy := prof.end.y + 8.0
	var vh := r.end.y - vy - fs * 1.6
	for i in 3:
		var cx := x0 + third * (i + 0.5)
		var half := third * 0.42
		var shapes: Array[Vector3] = [Vector3(0.0, 1.0, 0.08), Vector3(0.25, 0.7, 0.14), Vector3(0.7, 0.35, 0.22)]
		var floor_half := shapes[i].x * half
		var depth := vh * shapes[i].y
		var valley := PackedVector2Array([Vector2(cx - half, vy), Vector2(cx - floor_half - half * 0.08, vy + depth),
			Vector2(cx + floor_half + half * 0.08, vy + depth), Vector2(cx + half, vy)])
		var land := PackedVector2Array([Vector2(cx - half, vy), Vector2(cx - half, vy + vh), Vector2(cx + half, vy + vh),
			Vector2(cx + half, vy)])
		ci.draw_colored_polygon(land, Color("c9a77c"))
		ci.draw_colored_polygon(valley, PAPER)
		ci.draw_polyline(valley, Color("7a5a3a"), 2.0, true)
		var water_w := shapes[i].z * half
		ci.draw_rect(Rect2(cx - water_w, vy + depth - vh * 0.08, water_w * 2.0, vh * 0.08), DEEP)
	names["V-shaped valley"] = [Vector2(x0 + third * 0.5, r.end.y - fs * 0.7), Vector2(x0 + third * 0.5, vy + vh * 0.5)]
	names["floodplain"] = [Vector2(x0 + third * 2.5, r.end.y - fs * 0.7), Vector2(x0 + third * 2.5 + third * 0.2, vy + vh * 0.33)]


## The long profile's height `t` of the way from the source (0) to the mouth (1): steep, then flatter, and a step down
## at the waterfall (`fall`).
static func _long_height(sea: float, high: float, fall: float, t: float) -> float:
	var y := sea - (sea - high) * pow(1.0 - t, 2.2)
	return y + (0.0 if t < fall else (sea - high) * 0.1 * (1.0 - t) / (1.0 - fall))


## From above: hills at the source, a tributary meeting the river, meanders and an ox-bow lake, the mouth at the sea.
static func _river_plan(ci: CanvasItem, r: Rect2, names: Dictionary) -> void:
	ci.draw_rect(r, GRASS)
	ci.draw_rect(Rect2(_frac(r, 0.9, 0.0), Vector2(r.size.x * 0.1, r.size.y)), WATER)
	for hill: Vector2 in [Vector2(0.05, 0.12), Vector2(0.14, 0.06), Vector2(0.03, 0.3), Vector2(0.12, 0.9)]:
		var c := _frac(r, hill.x, hill.y)
		var s := r.size.y * 0.09
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s, s * 0.6), c + Vector2(0, -s * 0.6),
			c + Vector2(s, s * 0.6)]), Color("a78a63"))
	var main_pts: Array[Vector2] = [Vector2(0.07, 0.2), Vector2(0.17, 0.3), Vector2(0.3, 0.42), Vector2(0.4, 0.48)]
	for k in 17:   # meanders
		var t := k / 16.0
		main_pts.append(Vector2(0.42 + 0.4 * t, 0.5 + 0.14 * sin(t * TAU * 1.5)))
	main_pts.append(Vector2(0.9, 0.5))
	var main := PackedVector2Array()
	for p: Vector2 in main_pts:
		main.append(_frac(r, p.x, p.y))
	var smooth := _smooth(main)
	for i in smooth.size() - 1:   # wider downstream
		var t := float(i) / smooth.size()
		ci.draw_line(smooth[i], smooth[i + 1], DEEP, 2.5 + t * 6.0, true)
	var trib := PackedVector2Array([_frac(r, 0.12, 0.85), _frac(r, 0.2, 0.7), _frac(r, 0.26, 0.55), _frac(r, 0.3, 0.42)])
	ci.draw_polyline(_smooth(trib), DEEP, 3.0, true)
	var bow_c := _frac(r, 0.62, 0.84)
	ci.draw_arc(bow_c, r.size.y * 0.1, PI * 0.05, PI * 0.95, 24, DEEP, 7.0)   # an ox-bow lake: a cut-off bend
	# The estuary widens into the sea.
	ci.draw_colored_polygon(PackedVector2Array([_frac(r, 0.84, 0.47), _frac(r, 0.9, 0.4), _frac(r, 0.9, 0.6),
		_frac(r, 0.84, 0.53)]), DEEP)
	names["source"] = [_frac(r, 0.2, 0.1), main[0]]
	names["tributary"] = [_frac(r, 0.3, 0.9), _frac(r, 0.2, 0.7)]
	names["confluence"] = [_frac(r, 0.34, 0.2), _frac(r, 0.3, 0.42)]
	names["meander"] = [_frac(r, 0.6, 0.14), _frac(r, 0.52, 0.37)]
	names["ox-bow lake"] = [_frac(r, 0.84, 0.9), bow_c + Vector2(r.size.y * 0.1, 0)]
	names["mouth"] = [_frac(r, 0.8, 0.22), _frac(r, 0.88, 0.47)]


## The point `x` and `y` of the way across and down `r`.
static func _frac(r: Rect2, x: float, y: float) -> Vector2:
	return r.position + Vector2(x * r.size.x, y * r.size.y)


## One bend from above: fast, deep water on the outside wears the bank away into a river cliff; slow water on the
## inside drops sand and gravel in a slip-off slope.
static func _river_meander(ci: CanvasItem, r: Rect2, names: Dictionary) -> void:
	ci.draw_rect(r, GRASS)
	var c := Vector2(r.get_center().x, r.position.y + r.size.y * 0.72)
	var rad := minf(r.size.y * 0.5, r.size.x * 0.3)
	var w := rad * 0.36
	var outer := _arc(c, rad + w * 0.5, PI + 0.5, -0.5, 40)
	var inner := _arc(c, rad - w * 0.5, -0.5, PI + 0.5, 40)
	var river := outer.duplicate()
	river.append_array(inner)
	ci.draw_colored_polygon(river, WATER)
	# the river cliff (outside) and the slip-off slope (inside)
	var cliff := _arc(c, rad + w * 0.5, PI * 0.72, PI * 0.28, 16)
	var cliff_back := _arc(c, rad + w * 0.8, PI * 0.28, PI * 0.72, 16)
	var band := cliff.duplicate()
	band.append_array(cliff_back)
	ci.draw_colored_polygon(band, Color("9a6b3a"))
	for k in 9:
		var a := PI * (0.3 + 0.44 * k / 8.0)
		ci.draw_line(c + Vector2(cos(a), -sin(a)) * (rad + w * 0.5), c + Vector2(cos(a), -sin(a)) * (rad + w * 0.8),
			Color("5e3f1f"), 1.5)
	var slope := _arc(c, rad - w * 0.5, PI * 0.25, PI * 0.75, 16)
	var slope_in := _arc(c, rad - w * 0.05, PI * 0.68, PI * 0.32, 16)
	var sand := slope.duplicate()
	sand.append_array(slope_in)
	ci.draw_colored_polygon(sand, SAND)
	ci.draw_polyline(outer, Color("3d6b2f"), 2.0, true)
	ci.draw_polyline(inner, Color("3d6b2f"), 2.0, true)
	var fast := _arc(c, rad + w * 0.28, PI + 0.4, -0.4, 40)
	for i in range(0, fast.size() - 1, 2):
		ci.draw_line(fast[i], fast[i + 1], DEEP.darkened(0.2), 2.0)
	for a: float in [PI * 0.85, PI * 0.5, PI * 0.15]:   # the way the water flows
		var p := c + Vector2(cos(a), -sin(a)) * rad
		var tangent := Vector2(sin(a), cos(a))
		_arrow(ci, p - tangent * w * 0.35, p + tangent * w * 0.35, Color.WHITE, 3.0)
	var top := c + Vector2(0, -rad)
	names["erosion"] = [Vector2(r.position.x + r.size.x * 0.16, r.position.y + r.size.y * 0.1), c + Vector2(cos(PI * 0.7),
		-sin(PI * 0.7)) * (rad + w * 0.5)]
	names["river cliff"] = [Vector2(r.position.x + r.size.x * 0.84, r.position.y + r.size.y * 0.1), c + Vector2(cos(PI * 0.35),
		-sin(PI * 0.35)) * (rad + w * 0.65)]
	names["fastest flow"] = [Vector2(r.position.x + r.size.x * 0.14, r.position.y + r.size.y * 0.45), c + Vector2(cos(PI * 0.85),
		-sin(PI * 0.85)) * (rad + w * 0.28)]
	names["deposition"] = [Vector2(c.x - rad * 0.35, c.y + r.size.y * 0.12), top + Vector2(-w * 0.3, w * 0.8)]
	names["slip-off slope"] = [Vector2(c.x + rad * 0.35, c.y - rad * 0.15), top + Vector2(w * 0.2, w * 0.75)]


## Points on a circle round `c` from angle a0 to a1 (anticlockwise from the right, y up).
static func _arc(c: Vector2, radius: float, a0: float, a1: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in n + 1:
		var a := a0 + (a1 - a0) * k / n
		out.append(c + Vector2(cos(a), -sin(a)) * radius)
	return out


## From the side: hard rock over soft rock; the soft rock wears away faster under the hard, leaving an overhang; the
## water drops into a plunge pool; the waterfall moves back, leaving a gorge downstream.
static func _river_waterfall(ci: CanvasItem, r: Rect2, names: Dictionary) -> void:
	ci.draw_rect(r, Color("dfeefa"))
	# the gorge's far wall behind the lower river
	ci.draw_colored_polygon(PackedVector2Array([_frac(r, 0.5, 0.35), _frac(r, 1.0, 0.35), _frac(r, 1.0, 0.7),
		_frac(r, 0.5, 0.7)]), Color("c2b39c"))
	# hard rock on top, reaching past the soft rock (the overhang)
	ci.draw_colored_polygon(PackedVector2Array([_frac(r, 0.0, 0.3), _frac(r, 0.52, 0.3), _frac(r, 0.52, 0.45),
		_frac(r, 0.0, 0.45)]), DARK_STONE)
	ci.draw_colored_polygon(PackedVector2Array([_frac(r, 0.0, 0.45), _frac(r, 0.42, 0.45), _frac(r, 0.46, 0.7),
		_frac(r, 0.5, 0.95), _frac(r, 0.0, 0.95)]), Color("d6b98f"))
	ci.draw_colored_polygon(PackedVector2Array([_frac(r, 0.5, 0.95), _frac(r, 0.46, 0.7), _frac(r, 0.62, 0.72),
		_frac(r, 0.62, 0.95)]), Color("d6b98f"))
	ci.draw_colored_polygon(PackedVector2Array([_frac(r, 0.62, 0.72), _frac(r, 1.0, 0.72), _frac(r, 1.0, 0.95),
		_frac(r, 0.62, 0.95)]), Color("d6b98f"))
	for k in 5:   # layers in the soft rock
		var y := 0.52 + k * 0.08
		ci.draw_line(_frac(r, 0.0, y), _frac(r, 0.4, y), Color("b8986a"), 1.5)
	# the plunge pool, the falling water, the river above and below
	ci.draw_colored_polygon(PackedVector2Array([_frac(r, 0.46, 0.7), _frac(r, 0.5, 0.86), _frac(r, 0.58, 0.86),
		_frac(r, 0.62, 0.72)]), DEEP)
	ci.draw_rect(Rect2(_frac(r, 0.0, 0.26), Vector2(r.size.x * 0.52, r.size.y * 0.04)), DEEP)
	ci.draw_colored_polygon(PackedVector2Array([_frac(r, 0.52, 0.26), _frac(r, 0.56, 0.3), _frac(r, 0.56, 0.74),
		_frac(r, 0.5, 0.74), _frac(r, 0.52, 0.3)]), WATER)
	ci.draw_rect(Rect2(_frac(r, 0.6, 0.68), Vector2(r.size.x * 0.4, r.size.y * 0.04)), DEEP)
	names["hard rock"] = [_frac(r, 0.2, 0.12), _frac(r, 0.25, 0.38)]
	names["soft rock"] = [_frac(r, 0.2, 0.9), _frac(r, 0.25, 0.7)]
	names["overhang"] = [_frac(r, 0.35, 0.58), _frac(r, 0.5, 0.45)]
	names["plunge pool"] = [_frac(r, 0.72, 0.9), _frac(r, 0.54, 0.8)]
	names["gorge"] = [_frac(r, 0.82, 0.15), _frac(r, 0.82, 0.5)]


# --- Layers (GIS) -----------------------------------------------------------------------------------------------------

static func _draw_layers(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 14.0)
	var w := int(d.w)
	var h := int(d.h)
	var layers: Array = d.layers
	if str(d.get("view", "overlay")) == "stack":
		var widest := 0.0
		for l: Dictionary in layers:
			widest = maxf(widest, _text_w(font, str(l.name), fs))
		var n := layers.size()
		var room := Vector2(r.size.x - widest - 20.0, r.size.y / (n * 0.62 + 0.4))
		var cell := minf(room.x / (w + h * 0.6), room.y / h)
		var gap := (r.size.y - 12.0 - h * cell * 0.5) / maxf(n - 1, 1)   # the top sheet reaches the top
		for k in n:   # the first layer at the bottom
			var l: Dictionary = layers[k]
			var origin := Vector2(r.position.x + 4.0, r.end.y - 6.0 - k * gap)
			var sheet := PackedVector2Array([_skew(origin, cell, h, 0, 0), _skew(origin, cell, h, w, 0), _skew(origin, cell, h, w, h), _skew(origin, cell, h, 0, h)])
			ci.draw_colored_polygon(sheet, Color(1, 1, 1, 0.9))
			for y in h:
				var row := str(l.cells[y])
				for x in w:
					if row[x] == "#":
						var poly := PackedVector2Array([_skew(origin, cell, h, x, y), _skew(origin, cell, h, x + 1, y), _skew(origin, cell, h, x + 1, y + 1),
							_skew(origin, cell, h, x, y + 1)])
						ci.draw_colored_polygon(poly, _thing_colour(str(l.what)))
			sheet.append(sheet[0])
			ci.draw_polyline(sheet, INK, 2.0, true)
			_say_from(ci, font, _skew(origin, cell, h, w, h * 0.5) + Vector2(10.0, 0.0), str(l.name), fs)
		return
	var key_w := 0.0
	for l: Dictionary in layers:
		key_w = maxf(key_w, _text_w(font, str(l.name), fs) + fs * 2.4)
	var cell := minf((r.size.x - key_w - 12.0) / w, r.size.y / h)
	var map := Rect2(r.position + Vector2(0, (r.size.y - h * cell) * 0.5), Vector2(w * cell, h * cell))
	ci.draw_rect(map, Color("f4f1e4"))
	for pass_areas: bool in [true, false]:
		for l: Dictionary in layers:
			if AREA_THINGS.has(str(l.what)) != pass_areas:
				continue
			for y in h:
				var row := str(l.cells[y])
				for x in w:
					if row[x] == "#":
						_thing(ci, Rect2(map.position + Vector2(x, y) * cell, Vector2(cell, cell)), str(l.what))
	for x in w + 1:
		ci.draw_line(map.position + Vector2(x * cell, 0), map.position + Vector2(x * cell, map.size.y), Color("c9c3ae"), 1.0)
	for y in h + 1:
		ci.draw_line(map.position + Vector2(0, y * cell), map.position + Vector2(map.size.x, y * cell), Color("c9c3ae"), 1.0)
	ci.draw_rect(map, INK, false, 2.0)
	var kx := map.end.x + 12.0
	for k in layers.size():
		var l: Dictionary = layers[k]
		var ky := r.position.y + fs * 1.2 + k * fs * 2.0
		var sw := fs * 1.4
		_thing(ci, Rect2(kx, ky - sw * 0.5, sw, sw), str(l.what))
		ci.draw_rect(Rect2(kx, ky - sw * 0.5, sw, sw), INK, false, 1.0)
		_say_from(ci, font, Vector2(kx + sw + 6.0, ky), str(l.name), fs)


## A sheet lying flat, seen at a slant: cell (x, y) of a layer h cells deep drawn from `origin`.
static func _skew(origin: Vector2, cell: float, h: int, x: float, y: float) -> Vector2:
	return origin + Vector2(x * cell + (h - y) * cell * 0.6, -(h - y) * cell * 0.5)


static func _thing_colour(what: String) -> Color:
	match what:
		"water":
			return DEEP
		"flood":
			return Color(0.36, 0.6, 0.95, 0.55)
		"trees":
			return Color("4f9a3a")
		"road":
			return Color("8b8f99")
		"houses":
			return Color("c0533a")
		"schools":
			return Color("e0a100")
		"shops":
			return Color("8e44ad")
	return Color("16a085")   # bus stops


static func _thing(ci: CanvasItem, c: Rect2, what: String) -> void:
	var col := _thing_colour(what)
	var m := c.get_center()
	var s := c.size.x
	match what:
		"water", "road":
			ci.draw_rect(c, col)
		"flood":
			ci.draw_rect(c, col)
			for k in 3:
				var off := s * (k + 0.5) / 3.0
				ci.draw_line(c.position + Vector2(off, 0), c.position + Vector2(0, off), Color(0.2, 0.4, 0.8, 0.8), 1.5)
		"trees":
			ci.draw_rect(c, Color("d6ecc4"))
			for q: Vector2 in [Vector2(0.3, 0.35), Vector2(0.68, 0.4), Vector2(0.45, 0.72)]:
				ci.draw_circle(c.position + q * s, s * 0.17, col)
		"houses":
			ci.draw_rect(Rect2(m + Vector2(-s * 0.25, -s * 0.05), Vector2(s * 0.5, s * 0.32)), Color("f3e2c2"))
			ci.draw_colored_polygon(PackedVector2Array([m + Vector2(-s * 0.33, -s * 0.05), m + Vector2(0, -s * 0.33),
				m + Vector2(s * 0.33, -s * 0.05)]), col)
		"schools":
			ci.draw_rect(Rect2(m + Vector2(-s * 0.32, -s * 0.12), Vector2(s * 0.64, s * 0.4)), col)
			ci.draw_line(m + Vector2(0, -s * 0.12), m + Vector2(0, -s * 0.42), INK, 1.5)
			ci.draw_colored_polygon(PackedVector2Array([m + Vector2(0, -s * 0.42), m + Vector2(s * 0.2, -s * 0.35),
				m + Vector2(0, -s * 0.28)]), RED)
		"shops":
			ci.draw_rect(Rect2(m + Vector2(-s * 0.3, -s * 0.1), Vector2(s * 0.6, s * 0.36)), Color("f3e2c2"))
			for k in 4:
				ci.draw_rect(Rect2(m + Vector2(-s * 0.32 + k * s * 0.16, -s * 0.28), Vector2(s * 0.16, s * 0.18)),
					col if k % 2 == 0 else Color.WHITE)
		_:   # a bus stop: a sign on a pole
			ci.draw_line(m + Vector2(0, s * 0.35), m + Vector2(0, -s * 0.1), INK, 2.0)
			ci.draw_circle(m + Vector2(0, -s * 0.18), s * 0.17, col)


# --- Savings ----------------------------------------------------------------------------------------------------------

static func _draw_savings(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 15.0)
	var start := float(d.start)
	var rate := float(d.rate)
	var years := int(d.years)
	var with_simple := bool(d.get("simple", false))
	var values := bool(d.get("values", false))
	var most := compound(start, rate, years)
	var key := fs * 1.5
	var plot := Rect2(r.position + Vector2(4.0, key + (fs * 1.2 if values else 4.0)),
		Vector2(r.size.x - 8.0, r.size.y - key - fs * 1.6 - (fs * 1.2 if values else 4.0)))
	var slot := plot.size.x / (years + 1)
	var bw := slot * (0.36 if with_simple else 0.6)
	for k in years + 1:
		var x := plot.position.x + slot * (k + 0.5)
		var total := compound(start, rate, k)
		var bx := x - (bw if with_simple else bw * 0.5)
		ci.draw_rect(Rect2(bx, _bar_y(plot, most, start), bw, plot.end.y - _bar_y(plot, most, start)), SAVED)
		ci.draw_rect(Rect2(bx, _bar_y(plot, most, total), bw, _bar_y(plot, most, start) - _bar_y(plot, most, total)), INTEREST)
		ci.draw_rect(Rect2(bx, _bar_y(plot, most, total), bw, plot.end.y - _bar_y(plot, most, total)), INK, false, 1.5)
		if values:
			_say(ci, font, Vector2(bx + bw * 0.5, _bar_y(plot, most, total) - fs * 0.7), _gold(total), fs - 2, INK)
		if with_simple:
			var plain := simple(start, rate, k)
			ci.draw_rect(Rect2(x, _bar_y(plot, most, plain), bw, plot.end.y - _bar_y(plot, most, plain)), SIMPLE)
			ci.draw_rect(Rect2(x, _bar_y(plot, most, plain), bw, plot.end.y - _bar_y(plot, most, plain)), INK, false, 1.5)
			if values and k == years:   # the last simple bar's gold, inside it
				_say(ci, font, Vector2(x + bw * 0.5, _bar_y(plot, most, plain) + fs * 0.8), _gold(plain), fs - 2, INK)
		_say(ci, font, Vector2(x, plot.end.y + fs * 0.8), "year %d" % k if k > 0 else "start", fs - 1, INK, false)
	ci.draw_line(Vector2(plot.position.x, plot.end.y), Vector2(plot.end.x, plot.end.y), INK, 2.0)
	var entries: Array = [["saved", SAVED], ["interest", INTEREST]]
	if with_simple:
		entries.append(["simple interest", SIMPLE])
	var kx := r.position.x + 6.0
	for e: Array in entries:
		ci.draw_rect(Rect2(kx, r.position.y + key * 0.5 - fs * 0.45, fs * 0.9, fs * 0.9), e[1])
		_say_from(ci, font, Vector2(kx + fs * 1.2, r.position.y + key * 0.5), str(e[0]), fs - 1)
		kx += fs * 1.2 + _text_w(font, str(e[0]), fs - 1) + fs * 1.2


static func _bar_y(plot: Rect2, most: float, v: float) -> float:
	return plot.end.y - plot.size.y * v / most


static func _gold(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return GenKit.fmt(roundi(v))
	return "%.2f" % v
