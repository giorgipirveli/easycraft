class_name SchoolPictureG7Hum
extends RefCounted
## Owner #70 and #73, grade 7 history, geography and citizenship (research §6.7): the picture kinds they add, drawn from
## data onto a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only, no new art; the
## font has no arrows, so they are drawn). A diagram's `labels` name its parts in bands along its top and bottom, each
## with a line to its part; `mark` (a part) is orange and `hide` (a part) shows "?". Kinds and fields:
## - hand_press {view: PRESS_VIEWS, labels?, mark?, hide? (a part of PRESS_PARTS: the press view); word (the type view:
##   1-8 letters), print? (the printed word under the type; true), hide_print? (the printed word shown "?")}: a
##   printer's wooden hand press from the side, or a line of metal type set as a mirror of the page (type_order).
## - voyage_map {routes?: [{name (14 letters), points: [[lat, long]] (2-10)}] (0-4), places?: [{lat, long, label (14
##   letters)}] (0-8), lat_step? (LAT_STEPS; 30), long_step? (LONG_STEPS; 30), window? ({lat: [lo, hi], long: [lo, hi]}:
##   whole degrees, at least 10 each way, the map zoomed to that part of the world, every route and place inside it)}:
##   the world as a grid of latitude and longitude (no coastlines, as grade 5's latlong), with voyages as coloured routes
##   (a route crossing the 180° line leaves one edge and comes back at the other) and a key.
## - pole_star {angle (5-85 whole degrees), labels?, hide? (the angle shown "?")}: a sailor at night measuring how high
##   the Pole Star stands above the horizon: in the northern hemisphere that angle is the ship's latitude.
## - columbian_exchange {to_old: [text (18 letters)] (1-6), to_new: [text] (1-6), hide? (an item, shown "?")}: what
##   crossed the Atlantic after 1492: from the Americas to Europe, Africa and Asia along the top arrow, and back along
##   the bottom one.
## - dome_profile {style: DOME_STYLES ("ottoman": a mosque's great dome on half-domes, pencil minarets; "mughal": a tomb's
##   onion dome on a drum, chhatris, a great arch, minarets on a platform), labels?, mark?, hide? (DOME_PARTS[style])}.
## - charbagh {labels?, mark?, hide? (GARDEN_PARTS)}: a Mughal tomb garden from above, the way the Taj Mahal is laid
##   out: the gateway, a square garden in four parts split by water channels meeting at a pool, the tomb on its platform
##   at the far end, and the river behind.
## - sky_model {model: SKY_MODELS ("earth": Ptolemy's heavens, the Earth in the middle; "sun": Copernicus's, the Sun in
##   the middle; "jupiter": Galileo's notes of Jupiter's moons night by night), labels?, mark?, hide? (a body of
##   `bodies`), nights (jupiter: 1-4 nights, each 0-4 moons at whole positions -8 to 8, not 0, in Jupiter's widths)}.
## - family_tree {people: [{name (20 letters), years? (12 letters), row (0-4), col (0-5)}] (2-10, one to a place),
##   links: [[parent, child]] (the parent in an earlier row), couples?: [[a, b]] (the same row), mark?, hide? (a
##   person's index: the name shown "?")}: a royal family tree; a child's line starts under a couple when its parent has
##   one.
## - plate_section {type: PLATE_TYPES ("divergent", "subduction", "collision": cross-sections; "transform": from above),
##   labels?, mark?, hide? (PLATE_PARTS[type])}: plates moving at a boundary, their movement as arrows.
## - rock_cycle {labels? (the processes; true), mark?, hide? (a step of ROCK_STEPS or a process of ROCK_PROCESSES)}: the
##   rock cycle as a ring (rock_next, process_after).
## - soil_profile {labels?, mark?, hide? (HORIZONS)}: a cut through soil: the O, A, B, C and R layers from the leaf
##   litter down to the bedrock, with roots, worms and stones.
## - glacial_valley {view: GLACIER_VIEWS ("compare": a river's V-shaped valley beside a glacier's U-shaped one;
##   "landforms": a glaciated mountain valley; "corrie": a corrie's cross-section with its glacier), labels?, mark?,
##   hide? (GLACIER_PARTS[view])}.
## - coast_view {view: COAST_VIEWS ("headland": a headland's crack, cave, arch, stack and stump; "drift": longshore drift
##   and groynes from above; "bays": headlands and bays on hard and soft rock from above), labels?, mark?, hide?
##   (COAST_PARTS[view])}.
## - nutrient_cycle {stores: [biomass, litter, soil] (1-5 each: the circles' sizes), flows?: [fall, decay, uptake] (1-5:
##   the arrows' widths), name? (20 letters), labels?}: an ecosystem's nutrient stores and flows (Gersmehl's model).
## - step_chain {steps: [text (24 letters)] (2-7), loop? (the last step leads back to the first), mark?, hide? (a step's
##   index), title? (32 letters)}: steps in order joined by arrows, in one row or two.
## - break_even {fixed (1-100,000 gold), cost (gold an item, 0 or more), price (more than cost), max (items, 2-1,000;
##   the break-even point inside it), point? (the break-even point marked), hide? (its number shown "?")}: a small
##   business's costs and takings as lines, the loss before they cross and the profit after (break_even_items).
## - cut_axis_bars {bars: [[label (10 letters), value]] (2-4), from (the axis's start, 0 or more, below every value), to
##   (at least every value), step (2-10 steps from `from` to `to`), full? (the same bars beside it on an axis from 0),
##   title? (24 letters)}: a column chart whose axis may not start at 0, so its bars' heights mislead (bar_ratio).

const KINDS: Array[String] = ["hand_press", "voyage_map", "pole_star", "columbian_exchange", "dome_profile",
	"charbagh", "sky_model", "family_tree", "plate_section", "rock_cycle", "soil_profile", "glacial_valley",
	"coast_view", "nutrient_cycle", "step_chain", "break_even", "cut_axis_bars"]
const INK := Color("1f2a4a")    # SchoolUi.INK
const PAPER := Color("fdf6e3")  # SchoolUi.PAPER
const ORANGE := Color("f08a1c")
const SOFT := Color("fce2b8")
const RED := Color("d9433b")
const BLUE := Color("3a7be8")
const SEA := Color("7fb6e8")
const DEEP := Color("3f86d0")
const SKY := Color("dcecf8")
const GRASS := Color("9fcf7f")
const EARTH := Color("b98a5a")
const SAND := Color("f2d48a")
const STONE := Color("a7a39a")
const DARK_STONE := Color("7c776d")
const WOOD := Color("a86b3c")
const ICE := Color("cfe9f7")
const MAGMA := Color("e8562a")
const MANTLE := Color("f0a060")

const PRESS_VIEWS: Array[String] = ["press", "type"]
const PRESS_PARTS: Array[String] = ["screw", "bar", "platen", "type", "paper", "ink balls"]
const MAX_WORD := 8
const METAL := Color("9aa1ab")

const LAT_STEPS: Array[int] = [10, 15, 20, 30, 45]
const LONG_STEPS: Array[int] = [15, 20, 30, 45, 60, 90]
const MAX_ROUTES := 4
const MAX_ROUTE_NAME := 14
const MAX_ROUTE_POINTS := 10
const MAX_PLACES := 8
const MAX_PLACE := 14
const ROUTE_COLOURS: Array[Color] = [Color("d9433b"), Color("1f5fbf"), Color("2e8b3e"), Color("8e44ad")]

const MAX_GOODS := 6
const MAX_GOOD := 18

const DOME_STYLES: Array[String] = ["ottoman", "mughal"]
const DOME_PARTS := {"ottoman": ["main dome", "half-dome", "minaret", "balcony"],
	"mughal": ["onion dome", "drum", "chhatri", "iwan", "minaret", "platform"]}
const LEAD := Color("8e9aa8")
const MARBLE := Color("f7f4ec")
const STONE_WALL := Color("e6d8bc")

const GARDEN_PARTS: Array[String] = ["gateway", "garden", "water channel", "pool", "tomb", "river"]

const SKY_MODELS: Array[String] = ["earth", "sun", "jupiter"]
const MAX_NIGHTS := 4
const MAX_MOONS := 4
const MOON_REACH := 8
const BODY_COLOURS := {"Earth": Color("3f86d0"), "Moon": Color("b8bcc4"), "Mercury": Color("9c8f84"),
	"Venus": Color("e9cf8c"), "Sun": Color("f7c531"), "Mars": Color("d0573a"), "Jupiter": Color("d9a066"),
	"Saturn": Color("e3c98e")}

const MAX_PEOPLE := 10
const MAX_PERSON := 20
const MAX_YEARS_TEXT := 12
const TREE_ROWS := 5
const TREE_COLS := 6

const PLATE_TYPES: Array[String] = ["divergent", "subduction", "collision", "transform"]
const PLATE_PARTS := {"divergent": ["ridge", "magma", "new crust", "plate"],
	"subduction": ["oceanic plate", "continental plate", "trench", "volcano", "magma"],
	"collision": ["fold mountains", "continental plate"],
	"transform": ["fault", "plate", "road"]}
const OCEAN_CRUST := Color("5f6f6a")
const LAND_CRUST := Color("b08a5c")

const ROCK_STEPS: Array[String] = ["magma", "igneous rock", "sediment", "sedimentary rock", "metamorphic rock"]
## The process that turns each step into the next (the same order).
const ROCK_PROCESSES: Array[String] = ["cooling", "weathering and erosion", "pressing and cementing",
	"heat and pressure", "melting"]
const ROCK_COLOURS: Array[Color] = [Color("f08a5a"), Color("b3b6bd"), Color("f2d48a"), Color("d9b98a"), Color("b9a3c9")]

const HORIZONS: Array[String] = ["leaf litter", "topsoil", "subsoil", "broken rock", "bedrock"]
const HORIZON_LETTERS: Array[String] = ["O", "A", "B", "C", "R"]
const HORIZON_COLOURS: Array[Color] = [Color("3b2a1a"), Color("6b4a2b"), Color("a07a4f"), Color("c2b8a6"),
	Color("8d8d8d")]

const GLACIER_VIEWS: Array[String] = ["compare", "landforms", "corrie"]
const GLACIER_PARTS := {"compare": ["V-shaped valley", "U-shaped valley", "steep sides", "flat floor"],
	"landforms": ["pyramidal peak", "arete", "corrie", "tarn", "hanging valley", "ribbon lake", "moraine"],
	"corrie": ["back wall", "plucking", "abrasion", "freeze-thaw", "lip"]}

const COAST_VIEWS: Array[String] = ["headland", "drift", "bays"]
const COAST_PARTS := {"headland": ["crack", "cave", "arch", "stack", "stump", "wave-cut platform"],
	"drift": ["swash", "backwash", "prevailing wind", "groyne", "beach"],
	"bays": ["headland", "bay", "hard rock", "soft rock", "beach"]}
const CLIFF := Color("e9e0c8")

const NUTRIENT_STORES: Array[String] = ["biomass", "litter", "soil"]
const NUTRIENT_FLOWS: Array[String] = ["leaves fall", "decay", "roots take up"]

const MAX_STEPS := 7
const MAX_STEP := 24
const MAX_TITLE := 32

const MAX_FIXED := 100000
const MAX_PRICE := 10000.0
const MAX_ITEMS := 1000
const COSTS := Color("d9433b")
const TAKINGS := Color("1f5fbf")

const MAX_BARS := 4
const MAX_BAR_LABEL := 10
const MAX_CHART_TITLE := 24
const BAR := Color("5b8fd9")


# --- The rules the pictures draw by (the lessons teach them; tests check them) --------------------------------------

## Type is set as a mirror of the page: seen from above, its letters run right to left (each one flipped), so "CAT" is
## set "TAC".
static func type_order(word: String) -> String:
	return word.reverse()


## The heavens from the middle outwards: Ptolemy's ("earth") or Copernicus's ("sun").
static func bodies(model: String) -> Array[String]:
	if model == "earth":
		return ["Earth", "Moon", "Mercury", "Venus", "Sun", "Mars", "Jupiter", "Saturn"]
	if model == "sun":
		return ["Sun", "Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn"]
	return ["Jupiter"]


## The rock cycle's next step.
static func rock_next(step: String) -> String:
	return ROCK_STEPS[(ROCK_STEPS.find(step) + 1) % ROCK_STEPS.size()]


## The process that turns `step` into the next one.
static func process_after(step: String) -> String:
	return ROCK_PROCESSES[ROCK_STEPS.find(step)]


## How many items a business must sell to cover its fixed costs: each item sold brings in price − cost towards them.
static func break_even_items(fixed: float, cost: float, price: float) -> float:
	return fixed / (price - cost)


## How many times taller bar b looks than bar a on an axis starting at `from`.
static func bar_ratio(a: float, b: float, from: float) -> float:
	return (b - from) / (a - from)


# --- Checks -------------------------------------------------------------------------------------------------------------

## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	var kind := str(p.get("kind", ""))
	match kind:
		"hand_press":
			return _press_problem(p)
		"voyage_map":
			return _voyage_problem(p)
		"pole_star":
			if not _whole(p.get("angle")) or int(p.angle) < 5 or int(p.angle) > 85:
				return "pole_star: angle is 5-85 whole degrees"
			return _flags_problem(p, ["labels", "hide"])
		"columbian_exchange":
			var all: Array = []
			for key: String in ["to_old", "to_new"]:
				var goods: Variant = p.get(key)
				if not goods is Array or (goods as Array).is_empty() or (goods as Array).size() > MAX_GOODS:
					return "columbian_exchange: %s is 1-%d items" % [key, MAX_GOODS]
				for g: Variant in goods:
					if not g is String or str(g).length() > MAX_GOOD or str(g).strip_edges() == "":
						return "columbian_exchange: an item is 1-%d letters" % MAX_GOOD
					all.append(str(g))
			if p.has("hide") and not all.has(str(p.hide)):
				return "columbian_exchange: hide is one of the items"
			return ""
		"dome_profile":
			var style := str(p.get("style", ""))
			if not DOME_STYLES.has(style):
				return "dome_profile: style is one of %s" % [DOME_STYLES]
			return _parts_problem(p, DOME_PARTS[style])
		"charbagh":
			return _parts_problem(p, GARDEN_PARTS)
		"sky_model":
			return _sky_problem(p)
		"family_tree":
			return _tree_problem(p)
		"plate_section":
			var type := str(p.get("type", ""))
			if not PLATE_TYPES.has(type):
				return "plate_section: type is one of %s" % [PLATE_TYPES]
			return _parts_problem(p, PLATE_PARTS[type])
		"rock_cycle":
			return _parts_problem(p, ROCK_STEPS + ROCK_PROCESSES)
		"soil_profile":
			return _parts_problem(p, HORIZONS)
		"glacial_valley":
			var view := str(p.get("view", ""))
			if not GLACIER_VIEWS.has(view):
				return "glacial_valley: view is one of %s" % [GLACIER_VIEWS]
			return _parts_problem(p, GLACIER_PARTS[view])
		"coast_view":
			var view := str(p.get("view", ""))
			if not COAST_VIEWS.has(view):
				return "coast_view: view is one of %s" % [COAST_VIEWS]
			return _parts_problem(p, COAST_PARTS[view])
		"nutrient_cycle":
			for key: String in ["stores", "flows"]:
				if key == "flows" and not p.has(key):
					continue
				var v: Variant = p.get(key)
				if not v is Array or (v as Array).size() != 3:
					return "nutrient_cycle: %s is three sizes" % key
				for s: Variant in v:
					if not _whole(s) or int(s) < 1 or int(s) > 5:
						return "nutrient_cycle: every size is 1-5"
			if p.has("name") and (not p.name is String or str(p.name).length() > 20):
				return "nutrient_cycle: a name of up to 20 letters"
			return _flags_problem(p, ["labels"])
		"step_chain":
			var steps: Variant = p.get("steps")
			if not steps is Array or (steps as Array).size() < 2 or (steps as Array).size() > MAX_STEPS:
				return "step_chain: 2-%d steps" % MAX_STEPS
			for s: Variant in steps:
				if not s is String or str(s).strip_edges() == "" or str(s).length() > MAX_STEP:
					return "step_chain: a step is 1-%d letters" % MAX_STEP
			for key: String in ["mark", "hide"]:
				if p.has(key) and (not _whole(p[key]) or int(p[key]) < 0 or int(p[key]) >= (steps as Array).size()):
					return "step_chain: %s is a step's index" % key
			if p.has("title") and (not p.title is String or str(p.title).length() > MAX_TITLE):
				return "step_chain: a title of up to %d letters" % MAX_TITLE
			return _flags_problem(p, ["loop"])
		"break_even":
			if not _number(p.get("fixed")) or float(p.fixed) < 1.0 or float(p.fixed) > MAX_FIXED:
				return "break_even: fixed is 1-%d gold" % MAX_FIXED
			if not _number(p.get("cost")) or not _number(p.get("price")) or float(p.cost) < 0.0 \
					or float(p.price) <= float(p.cost) or float(p.price) > MAX_PRICE:
				return "break_even: 0 <= cost < price <= %d" % int(MAX_PRICE)
			if not _whole(p.get("max")) or int(p.max) < 2 or int(p.max) > MAX_ITEMS:
				return "break_even: max is 2-%d items" % MAX_ITEMS
			if break_even_items(float(p.fixed), float(p.cost), float(p.price)) > int(p.max) * 0.9:
				return "break_even: the break-even point is inside the chart"
			return _flags_problem(p, ["point", "hide"])
		"cut_axis_bars":
			return _bars_problem(p)
	return "unknown picture kind '%s'" % kind


static func _flags_problem(p: Dictionary, keys: Array) -> String:
	for key: String in keys:
		if p.has(key) and not p[key] is bool:
			return "%s: %s is true or false" % [p.kind, key]
	return ""


## `labels` true or false; `mark` and `hide` parts of `parts`.
static func _parts_problem(p: Dictionary, parts: Array) -> String:
	for key: String in ["mark", "hide"]:
		if p.has(key) and not parts.has(str(p[key])):
			return "%s: %s is one of %s" % [p.kind, key, parts]
	return _flags_problem(p, ["labels"])


static func _press_problem(p: Dictionary) -> String:
	var view := str(p.get("view", ""))
	if not PRESS_VIEWS.has(view):
		return "hand_press: view is one of %s" % [PRESS_VIEWS]
	if view == "press":
		return _parts_problem(p, PRESS_PARTS)
	var word: Variant = p.get("word")
	if not word is String or str(word).length() < 1 or str(word).length() > MAX_WORD:
		return "hand_press: a word of 1-%d letters" % MAX_WORD
	for ch in str(word):
		if not ((ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z")):
			return "hand_press: the word is letters only"
	return _flags_problem(p, ["print", "hide_print"])


static func _on_globe(lat: Variant, long: Variant) -> bool:
	return _number(lat) and _number(long) and absf(float(lat)) <= 90.0 and absf(float(long)) <= 180.0


static func _voyage_problem(p: Dictionary) -> String:
	var win := [-90.0, 90.0, -180.0, 180.0]
	if p.has("window"):
		var w: Variant = p.window
		if not w is Dictionary:
			return "voyage_map: window is {lat: [lo, hi], long: [lo, hi]}"
		for key: String in ["lat", "long"]:
			var span: Variant = w.get(key)
			var most := 90 if key == "lat" else 180
			if not span is Array or (span as Array).size() != 2 or not _whole(span[0]) or not _whole(span[1]) \
					or int(span[1]) - int(span[0]) < 10 or int(span[0]) < -most or int(span[1]) > most:
				return "voyage_map: the window's %s is [lo, hi], whole degrees, at least 10 apart" % key
		win = [float(w.lat[0]), float(w.lat[1]), float(w.long[0]), float(w.long[1])]
	var routes: Variant = p.get("routes", [])
	if not routes is Array or (routes as Array).size() > MAX_ROUTES:
		return "voyage_map: up to %d routes" % MAX_ROUTES
	for route: Variant in routes:
		if not route is Dictionary or not route.get("name") is String or str(route.name).strip_edges() == "" \
				or str(route.name).length() > MAX_ROUTE_NAME:
			return "voyage_map: a route has a name of 1-%d letters" % MAX_ROUTE_NAME
		var pts: Variant = route.get("points")
		if not pts is Array or (pts as Array).size() < 2 or (pts as Array).size() > MAX_ROUTE_POINTS:
			return "voyage_map: a route has 2-%d points" % MAX_ROUTE_POINTS
		for pt: Variant in pts:
			if not pt is Array or (pt as Array).size() != 2 or not _on_globe(pt[0], pt[1]):
				return "voyage_map: a point is [lat, long] on the globe"
			if not _in_window(win, float(pt[0]), float(pt[1])):
				return "voyage_map: every point is inside the window"
	var places: Variant = p.get("places", [])
	if not places is Array or (places as Array).size() > MAX_PLACES:
		return "voyage_map: up to %d places" % MAX_PLACES
	for pl: Variant in places:
		if not pl is Dictionary or not _on_globe(pl.get("lat"), pl.get("long")) or not pl.get("label") is String \
				or str(pl.label).length() > MAX_PLACE or str(pl.label).strip_edges() == "":
			return "voyage_map: a place is {lat, long, label (1-%d letters)}" % MAX_PLACE
		if not _in_window(win, float(pl.lat), float(pl.long)):
			return "voyage_map: every place is inside the window"
	if p.has("lat_step") and not LAT_STEPS.has(int(p.lat_step) if _whole(p.lat_step) else -1):
		return "voyage_map: lat_step is one of %s" % [LAT_STEPS]
	if p.has("long_step") and not LONG_STEPS.has(int(p.long_step) if _whole(p.long_step) else -1):
		return "voyage_map: long_step is one of %s" % [LONG_STEPS]
	return ""


static func _in_window(win: Array, lat: float, long: float) -> bool:
	return lat >= float(win[0]) and lat <= float(win[1]) and long >= float(win[2]) and long <= float(win[3])


static func _sky_problem(p: Dictionary) -> String:
	var model := str(p.get("model", ""))
	if not SKY_MODELS.has(model):
		return "sky_model: model is one of %s" % [SKY_MODELS]
	if model != "jupiter":
		return _parts_problem(p, bodies(model))
	var nights: Variant = p.get("nights")
	if not nights is Array or (nights as Array).is_empty() or (nights as Array).size() > MAX_NIGHTS:
		return "sky_model: jupiter has 1-%d nights" % MAX_NIGHTS
	for night: Variant in nights:
		if not night is Array or (night as Array).size() > MAX_MOONS:
			return "sky_model: a night has 0-%d moons" % MAX_MOONS
		var seen := {}
		for m: Variant in night:
			if not _whole(m) or int(m) == 0 or absi(int(m)) > MOON_REACH or seen.has(int(m)):
				return "sky_model: a moon is at a different whole place, -%d to %d, not 0" % [MOON_REACH, MOON_REACH]
			seen[int(m)] = true
	return _flags_problem(p, ["labels"])


static func _tree_problem(p: Dictionary) -> String:
	var people: Variant = p.get("people")
	if not people is Array or (people as Array).size() < 2 or (people as Array).size() > MAX_PEOPLE:
		return "family_tree: 2-%d people" % MAX_PEOPLE
	var n := (people as Array).size()
	var places := {}
	for person: Variant in people:
		if not person is Dictionary or not person.get("name") is String or str(person.name).strip_edges() == "" \
				or str(person.name).length() > MAX_PERSON:
			return "family_tree: a person has a name of 1-%d letters" % MAX_PERSON
		if person.has("years") and (not person.years is String or str(person.years).length() > MAX_YEARS_TEXT):
			return "family_tree: years are up to %d letters" % MAX_YEARS_TEXT
		if not _whole(person.get("row")) or int(person.row) < 0 or int(person.row) >= TREE_ROWS:
			return "family_tree: a row is 0-%d" % (TREE_ROWS - 1)
		if not _number(person.get("col")) or float(person.col) < 0.0 or float(person.col) > TREE_COLS - 1:
			return "family_tree: a col is 0-%d" % (TREE_COLS - 1)
		var key := "%d:%s" % [int(person.row), str(float(person.col))]
		if places.has(key):
			return "family_tree: two people in one place"
		places[key] = true
	for key: String in ["links", "couples"]:
		if key == "couples" and not p.has(key):
			continue
		var pairs: Variant = p.get(key)
		if not pairs is Array:
			return "family_tree: %s is a list of pairs" % key
		for pair: Variant in pairs:
			if not pair is Array or (pair as Array).size() != 2 or not _whole(pair[0]) or not _whole(pair[1]) \
					or int(pair[0]) < 0 or int(pair[0]) >= n or int(pair[1]) < 0 or int(pair[1]) >= n:
				return "family_tree: a pair of people's indexes"
			var a: Dictionary = people[int(pair[0])]
			var b: Dictionary = people[int(pair[1])]
			if key == "links" and int(a.row) >= int(b.row):
				return "family_tree: a parent is in an earlier row than the child"
			if key == "couples" and int(a.row) != int(b.row):
				return "family_tree: a couple is in one row"
	for key: String in ["mark", "hide"]:
		if p.has(key) and (not _whole(p[key]) or int(p[key]) < 0 or int(p[key]) >= n):
			return "family_tree: %s is a person's index" % key
	return ""


static func _bars_problem(p: Dictionary) -> String:
	var bars: Variant = p.get("bars")
	if not bars is Array or (bars as Array).size() < 2 or (bars as Array).size() > MAX_BARS:
		return "cut_axis_bars: 2-%d bars" % MAX_BARS
	if not (_number(p.get("from")) and _number(p.get("to")) and _number(p.get("step"))):
		return "cut_axis_bars: numbers from, to and step"
	var from := float(p.from)
	var to := float(p.to)
	var step := float(p.step)
	if from < 0.0 or step <= 0.0 or to <= from:
		return "cut_axis_bars: 0 <= from < to, and a step"
	var steps := (to - from) / step
	if not is_equal_approx(steps, roundf(steps)) or roundi(steps) < 2 or roundi(steps) > 10:
		return "cut_axis_bars: 2-10 steps from `from` to `to`"
	for b: Variant in bars:
		if not b is Array or (b as Array).size() != 2 or not b[0] is String or str(b[0]).length() > MAX_BAR_LABEL \
				or not _number(b[1]):
			return "cut_axis_bars: a bar is [label (up to %d letters), value]" % MAX_BAR_LABEL
		if float(b[1]) <= from or float(b[1]) > to:
			return "cut_axis_bars: every value is above `from` and at most `to`"
	if p.has("title") and (not p.title is String or str(p.title).length() > MAX_CHART_TITLE):
		return "cut_axis_bars: a title of up to %d letters" % MAX_CHART_TITLE
	return _flags_problem(p, ["full"])


static func _whole(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT and is_equal_approx(float(v), roundf(float(v)))


static func _number(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT]


# --- Drawing ----------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"hand_press":
			_draw_press(pic, font, r, d)
		"voyage_map":
			_draw_voyages(pic, font, r, d)
		"pole_star":
			_draw_pole_star(pic, font, r, d)
		"columbian_exchange":
			_draw_exchange(pic, font, r, d)
		"dome_profile":
			_draw_dome(pic, font, r, d)
		"charbagh":
			_draw_charbagh(pic, font, r, d)
		"sky_model":
			_draw_sky(pic, font, r, d)
		"family_tree":
			_draw_tree(pic, font, r, d)
		"plate_section":
			_draw_plates(pic, font, r, d)
		"rock_cycle":
			_draw_rock_cycle(pic, font, r, d)
		"soil_profile":
			_draw_soil(pic, font, r, d)
		"glacial_valley":
			_draw_glacier(pic, font, r, d)
		"coast_view":
			_draw_coast(pic, font, r, d)
		"nutrient_cycle":
			_draw_nutrients(pic, font, r, d)
		"step_chain":
			_draw_chain(pic, font, r, d)
		"break_even":
			_draw_break_even(pic, font, r, d)
		"cut_axis_bars":
			_draw_cut_bars(pic, font, r, d)


static func _fs(r: Rect2, per: float = 14.0) -> int:
	return clampi(int(minf(r.size.y / per, r.size.x / (per * 2.0))), 9, 18)


static func _text_w(font: Font, text: String, fs: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


## Text centred on `c`, with a white edge so it reads over lines.
static func _say(ci: CanvasItem, font: Font, c: Vector2, text: String, fs: int, colour: Color = INK,
		edge: bool = true) -> void:
	var w := _text_w(font, text, fs)
	var base := Vector2(c.x - w * 0.5, c.y + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5)
	if edge:
		ci.draw_string_outline(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color.WHITE)
	ci.draw_string(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)


## Text starting at `at` (left, vertically centred), or ending there when `right`.
static func _say_from(ci: CanvasItem, font: Font, at: Vector2, text: String, fs: int, colour: Color = INK,
		right: bool = false, edge: bool = true) -> void:
	var w := _text_w(font, text, fs)
	_say(ci, font, Vector2(at.x - w * 0.5 if right else at.x + w * 0.5, at.y), text, fs, colour, edge)


## The largest size up to `fs` at which `text` fits in `room` pixels (at least 8).
static func _fit(font: Font, text: String, fs: int, room: float) -> int:
	var f := fs
	while f > 8 and _text_w(font, text, f) > room:
		f -= 1
	return f


static func _arrow(ci: CanvasItem, from: Vector2, to: Vector2, colour: Color, width: float) -> void:
	if from.distance_to(to) < 1.0:
		return
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


static func _poly(ci: CanvasItem, pts: Array, fill: Color, line: Color = INK, width: float = 1.5) -> void:
	var p := PackedVector2Array(pts)
	ci.draw_colored_polygon(p, fill)
	if width > 0.0:
		p.append(p[0])
		ci.draw_polyline(p, line, width, true)


## A label's words and colour: orange when marked, "?" when hidden.
static func _label_of(d: Dictionary, key: String, words: String) -> Array:
	if d.has("hide") and str(d.hide) == key:
		return ["?", ORANGE]
	return [words, ORANGE if d.has("mark") and str(d.mark) == key else INK]


## The height of a band of labels.
static func _band(fs: int) -> float:
	return fs * 1.45 + 6.0


## `r` less its label bands (when the picture has labels).
static func _inner(r: Rect2, fs: int, labels: bool) -> Rect2:
	if not labels:
		return r
	var b := _band(fs)
	return Rect2(r.position + Vector2(0, b), r.size - Vector2(0, 2.0 * b))


## Part labels in bands along the top and bottom of `r` (a part goes to the band nearer its anchor, or to the top when
## it is in `tops`), spread so they never overlap, each with a line to its anchor; orange when marked, "?" when hidden.
static func _label_parts(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary, anchors: Dictionary, fs: int,
		tops: Array = []) -> void:
	for on_top: bool in [true, false]:
		var row: Array = []
		for part: String in anchors:
			var at: Vector2 = anchors[part]
			var top := tops.has(part) if not tops.is_empty() else at.y < r.get_center().y
			if top == on_top:
				row.append([at.x, 0.0, part, _label_of(d, part, part)])
		if row.is_empty():
			continue
		var lfs := fs
		while lfs > 8:
			var total := 0.0
			for b: Array in row:
				total += _text_w(font, str(b[3][0]), lfs) + 16.0
			if total <= r.size.x:
				break
			lfs -= 1
		for b: Array in row:
			b[1] = _text_w(font, str(b[3][0]), lfs) + 10.0
		var centres := _spread(row, r.position.x + 1.0, r.end.x - 1.0, 5.0)
		var h := lfs * 1.35 + 4.0
		var ly := r.position.y + h * 0.5 + 1.0 if on_top else r.end.y - h * 0.5 - 1.0
		for k in row.size():
			var b: Array = row[k]
			var said: Array = b[3]
			var at: Vector2 = anchors[str(b[2])]
			var marked: bool = said[1] == ORANGE
			ci.draw_line(at, Vector2(centres[k], ly + (h * 0.5 if on_top else -h * 0.5)), INK, 1.5, true)
			ci.draw_circle(at, 3.0, ORANGE if marked else INK)
			_box(ci, Rect2(centres[k] - float(b[1]) * 0.5, ly - h * 0.5, float(b[1]), h), SOFT if marked else Color.WHITE,
				ORANGE if marked else INK, 5, 2 if marked else 1)
			_say(ci, font, Vector2(centres[k], ly), str(said[0]), lfs, INK, false)


## Centres for boxes [wanted centre, width, …] in a row from lo to hi, at least `gap` apart, as near their wanted
## centres as the room allows.
static func _spread(boxes: Array, lo: float, hi: float, gap: float) -> Array[float]:
	var order: Array = range(boxes.size())
	order.sort_custom(func(a: int, b: int) -> bool: return float(boxes[a][0]) < float(boxes[b][0]))
	var left: Array[float] = []
	left.resize(boxes.size())
	var edge := lo
	for i: int in order:
		left[i] = maxf(float(boxes[i][0]) - float(boxes[i][1]) * 0.5, edge)
		edge = left[i] + float(boxes[i][1]) + gap
	edge = hi
	for k in range(order.size() - 1, -1, -1):
		var i: int = order[k]
		left[i] = minf(left[i], edge - float(boxes[i][1]))
		edge = left[i] - gap
	var out: Array[float] = []
	for i in boxes.size():
		out.append(maxf(left[i], lo) + float(boxes[i][1]) * 0.5)
	return out


## A point of a unit box `a` (fractions of its width and height).
static func _at(a: Rect2, fx: float, fy: float) -> Vector2:
	return a.position + Vector2(a.size.x * fx, a.size.y * fy)


static func _pts(a: Rect2, fracs: Array) -> Array:
	var out: Array = []
	for f: Vector2 in fracs:
		out.append(_at(a, f.x, f.y))
	return out


## The widest box of aspect `ratio` (width ÷ height) centred in `r`.
static func _fit_box(r: Rect2, ratio: float) -> Rect2:
	var w := minf(r.size.x, r.size.y * ratio)
	var h := w / ratio
	return Rect2(r.get_center() - Vector2(w, h) * 0.5, Vector2(w, h))


# --- The printing press -----------------------------------------------------------------------------------------------

static func _draw_press(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 14.0)
	if str(d.view) == "type":
		_draw_type(ci, font, r, d, fs)
		return
	var labels := bool(d.get("labels", false))
	var a := _fit_box(_inner(r, fs, labels), 1.5)
	var anchors := {}
	var wood_dark := WOOD.darkened(0.25)
	# The frame: two cheeks, the head beam and the feet.
	_poly(ci, _pts(a, [Vector2(0.30, 0.04), Vector2(0.36, 0.04), Vector2(0.36, 1.0), Vector2(0.30, 1.0)]), WOOD)
	_poly(ci, _pts(a, [Vector2(0.64, 0.04), Vector2(0.70, 0.04), Vector2(0.70, 1.0), Vector2(0.64, 1.0)]), WOOD)
	_poly(ci, _pts(a, [Vector2(0.27, 0.04), Vector2(0.73, 0.04), Vector2(0.73, 0.16), Vector2(0.27, 0.16)]), wood_dark)
	# The screw, its threads, and the bar that turns it.
	var s0 := _at(a, 0.475, 0.16)
	var s1 := _at(a, 0.525, 0.44)
	ci.draw_rect(Rect2(s0, s1 - s0), METAL)
	for k in 6:
		var y := s0.y + (s1.y - s0.y) * (k + 0.5) / 6.0
		ci.draw_line(Vector2(s0.x, y + 3.0), Vector2(s1.x, y - 3.0), DARK_STONE, 1.5)
	ci.draw_rect(Rect2(s0, s1 - s0), INK, false, 1.5)
	ci.draw_line(_at(a, 0.5, 0.33), _at(a, 0.14, 0.40), wood_dark, maxf(4.0, a.size.y * 0.025), true)
	ci.draw_circle(_at(a, 0.14, 0.40), maxf(4.0, a.size.y * 0.025), wood_dark)
	anchors["screw"] = _at(a, 0.5, 0.24)
	anchors["bar"] = _at(a, 0.22, 0.385)
	# The platen: the flat block the screw presses down.
	_poly(ci, _pts(a, [Vector2(0.39, 0.44), Vector2(0.61, 0.44), Vector2(0.61, 0.50), Vector2(0.39, 0.50)]), Color("c9a27a"))
	anchors["platen"] = _at(a, 0.58, 0.47)
	# The bed that rolls in and out, with the inked type (the forme) on it and the paper on its hinged frame.
	_poly(ci, _pts(a, [Vector2(0.24, 0.60), Vector2(0.98, 0.60), Vector2(0.98, 0.66), Vector2(0.24, 0.66)]), wood_dark)
	_poly(ci, _pts(a, [Vector2(0.40, 0.555), Vector2(0.60, 0.555), Vector2(0.60, 0.60), Vector2(0.40, 0.60)]), Color("3a3f47"))
	for k in 7:
		var x := a.position.x + a.size.x * (0.415 + k * 0.026)
		ci.draw_line(Vector2(x, a.position.y + a.size.y * 0.566), Vector2(x + a.size.x * 0.014, a.position.y + a.size.y * 0.566),
			Color("c8ccd2"), 2.0)
	anchors["type"] = _at(a, 0.45, 0.575)
	_poly(ci, _pts(a, [Vector2(0.72, 0.60), Vector2(0.96, 0.60), Vector2(0.99, 0.40), Vector2(0.77, 0.40)]), Color.WHITE)
	for k in 4:
		var y := 0.45 + k * 0.035
		ci.draw_line(_at(a, 0.79 - (y - 0.40) * 0.25, y), _at(a, 0.94 - (y - 0.40) * 0.15, y), Color("9aa1ab"), 1.5)
	anchors["paper"] = _at(a, 0.88, 0.47)
	# The ink balls: leather pads on handles, for dabbing ink on the type.
	for k in 2:
		var x := 0.08 + k * 0.1
		ci.draw_line(_at(a, x, 0.58), _at(a, x, 0.74), wood_dark, 3.0)
		ci.draw_circle(_at(a, x, 0.57), a.size.y * 0.05, Color("5a3b22"))
		ci.draw_arc(_at(a, x, 0.57), a.size.y * 0.05, 0.0, TAU, 16, INK, 1.5)
	_poly(ci, _pts(a, [Vector2(0.03, 0.74), Vector2(0.23, 0.74), Vector2(0.23, 0.78), Vector2(0.03, 0.78)]), wood_dark)
	ci.draw_line(_at(a, 0.0, 1.0), _at(a, 1.0, 1.0), INK, 2.0)
	anchors["ink balls"] = _at(a, 0.13, 0.52)
	if labels:
		_label_parts(ci, font, r, d, anchors, fs, ["screw", "bar", "paper"])


## A line of type as the printer sets it, and the word it prints.
static func _draw_type(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary, fs: int) -> void:
	var word := str(d.word)
	var shown := type_order(word)
	var prints := bool(d.get("print", true))
	var n := word.length()
	var bs := minf(r.size.x / (n + 1.0), r.size.y * (0.42 if prints else 0.75))
	var top := r.position.y + (r.size.y * 0.06 if prints else (r.size.y - bs) * 0.5)
	var x0 := r.get_center().x - bs * n * 0.5
	var lfs := clampi(int(bs * 0.62), 9, 64)
	for i in n:
		var cell := Rect2(x0 + i * bs + 2.0, top, bs - 4.0, bs)
		ci.draw_rect(cell, METAL)
		ci.draw_rect(Rect2(cell.position, Vector2(cell.size.x, cell.size.y * 0.12)), METAL.lightened(0.25))
		ci.draw_rect(cell, INK, false, 1.5)
		var ch := shown[i]
		var w := _text_w(font, ch, lfs)
		var c := cell.get_center()
		var base_y := c.y + (font.get_ascent(lfs) - font.get_descent(lfs)) * 0.5
		# Each letter flipped left to right on its block.
		ci.draw_set_transform(Vector2(c.x, 0.0), 0.0, Vector2(-1.0, 1.0))
		ci.draw_string(font, Vector2(-w * 0.5, base_y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, lfs, Color("20242a"))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not prints:
		return
	var y0 := top + bs + 6.0
	var paper := Rect2(r.position.x + r.size.x * 0.12, r.end.y - bs * 1.05, r.size.x * 0.76, bs)
	_arrow(ci, Vector2(r.get_center().x, y0), Vector2(r.get_center().x, paper.position.y - 3.0), INK, 3.0)
	_say_from(ci, font, Vector2(r.get_center().x + 12.0, (y0 + paper.position.y) * 0.5), "prints", fs, INK)
	ci.draw_rect(paper, Color.WHITE)
	ci.draw_rect(paper, INK, false, 1.5)
	var hidden := bool(d.get("hide_print", false))
	var text := "?" if hidden else word
	_say(ci, font, paper.get_center(), text, _fit(font, text, lfs, paper.size.x - 8.0), ORANGE if hidden else INK, false)


# --- Voyages on the world's grid --------------------------------------------------------------------------------------

## A place on the map `m` showing the window [lat lo, lat hi, long lo, long hi].
static func _map_xy(m: Rect2, lat: float, long: float, win: Array = [-90.0, 90.0, -180.0, 180.0]) -> Vector2:
	return Vector2(m.position.x + (long - float(win[2])) / (float(win[3]) - float(win[2])) * m.size.x,
		m.position.y + (float(win[1]) - lat) / (float(win[1]) - float(win[0])) * m.size.y)


static func _draw_voyages(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 15.0)
	var zoom := d.has("window")
	var win: Array = [float(d.window.lat[0]), float(d.window.lat[1]), float(d.window.long[0]), float(d.window.long[1])] \
		if zoom else [-90.0, 90.0, -180.0, 180.0]
	var edge := fs * 1.3 if zoom else 0.0   # room for the longitudes under a zoomed map
	var m := _fit_box(Rect2(r.position, r.size - Vector2(0, edge)), (float(win[3]) - float(win[2])) / (float(win[1]) - float(win[0])))
	ci.draw_rect(m, Color("e3f0fa"))
	var lat_step := int(d.get("lat_step", 30))
	var long_step := int(d.get("long_step", 30))
	var taken: Array[Rect2] = []   # the grid's own labels, then each place's name
	for lat in range(-90 + lat_step, 90, lat_step):
		if lat <= float(win[0]) or lat >= float(win[1]):
			continue
		var y := _map_xy(m, lat, 0, win).y
		ci.draw_line(Vector2(m.position.x, y), Vector2(m.end.x, y), INK if lat == 0 else Color("a9c3dc"), 2.5 if lat == 0 else 1.0)
		if (m.size.y > 150.0 or zoom) and lat != 0:
			var words := "%d°%s" % [absi(lat), "N" if lat > 0 else "S"]
			_say_from(ci, font, Vector2(m.end.x - 3.0, y - fs * 0.45), words, fs - 3, Color("5a7896"), true, false)
			var lw := _text_w(font, words, fs - 3)
			taken.append(Rect2(m.end.x - 3.0 - lw, y - fs * 0.95, lw, fs))
	for long in range(-180 + long_step, 180, long_step):
		if long <= float(win[2]) or long >= float(win[3]):
			continue
		var x := _map_xy(m, 0, long, win).x
		ci.draw_line(Vector2(x, m.position.y), Vector2(x, m.end.y), INK if long == 0 else Color("a9c3dc"), 2.5 if long == 0 else 1.0)
		if zoom:
			_say(ci, font, Vector2(x, m.end.y + fs * 0.7), "%d°%s" % [absi(long), "E" if long > 0 else "W"] if long != 0 else "0°",
				fs - 3, Color("5a7896"), false)
	ci.draw_rect(m, INK, false, 2.0)
	var routes: Array = d.get("routes", [])
	var lw := maxf(2.5, m.size.y / 70.0)
	for k in routes.size():
		var colour := ROUTE_COLOURS[k % ROUTE_COLOURS.size()]
		var pts: Array = routes[k].points
		for i in range(1, pts.size()):
			var a: Array = pts[i - 1]
			var b: Array = pts[i]
			var segs := _wrap(float(a[0]), float(a[1]), float(b[0]), float(b[1]))
			for s in segs.size():
				var seg: Array = segs[s]
				var p0 := _map_xy(m, float(seg[0]), float(seg[1]), win)
				var p1 := _map_xy(m, float(seg[2]), float(seg[3]), win)
				if i == pts.size() - 1 and s == segs.size() - 1:   # the voyage's last leg ends in an arrowhead
					_arrow(ci, p0, p1, colour, lw)
				else:
					ci.draw_line(p0, p1, colour, lw, true)
		ci.draw_circle(_map_xy(m, float(pts[0][0]), float(pts[0][1]), win), lw * 1.3, colour)
	# Each place's name beside its dot: to the right, the left, above or below, wherever it is clear of the others.
	var places: Array = d.get("places", [])
	var dots: Array[Rect2] = []
	for pl: Dictionary in places:
		dots.append(Rect2(_map_xy(m, float(pl.lat), float(pl.long), win) - Vector2(5, 5), Vector2(10, 10)))
	for i in places.size():
		var p := dots[i].get_center()
		var text := str(places[i].label)
		var tw := _text_w(font, text, fs - 1)
		var th := fs * 1.1
		var tries: Array[Rect2] = [Rect2(p.x + 7.0, p.y - th, tw, th), Rect2(p.x - 7.0 - tw, p.y - th, tw, th),
			Rect2(p.x - tw * 0.5, p.y - th - 7.0, tw, th), Rect2(p.x - tw * 0.5, p.y + 7.0, tw, th),
			Rect2(p.x + 7.0, p.y, tw, th), Rect2(p.x - 7.0 - tw, p.y, tw, th)]
		var box := tries[0] if p.x + 7.0 + tw < m.end.x else tries[1]
		for t in tries:
			if t.position.x < m.position.x or t.end.x > m.end.x or t.position.y < m.position.y or t.end.y > m.end.y:
				continue
			var clear := true
			for k in taken.size():
				clear = clear and not t.grow(1.0).intersects(taken[k])
			for k in dots.size():
				clear = clear and (k == i or not t.intersects(dots[k]))
			if clear:
				box = t
				break
		taken.append(box)
		_say(ci, font, box.get_center(), text, fs - 1, INK)
	for dot in dots:
		ci.draw_circle(dot.get_center(), 4.5, INK)
	if routes.is_empty():
		return
	# The key, in the far south where no voyage goes.
	var kh := fs * 1.3
	var kw := 0.0
	for route: Dictionary in routes:
		kw = maxf(kw, _text_w(font, str(route.name), fs - 1))
	var key := Rect2(m.position.x + 4.0, m.end.y - 4.0 - kh * routes.size() - 6.0, kw + fs * 2.6, kh * routes.size() + 6.0)
	_box(ci, key, Color(1, 1, 1, 0.92), INK, 4, 1)
	for k in routes.size():
		var y := key.position.y + 3.0 + kh * (k + 0.5)
		ci.draw_line(Vector2(key.position.x + 5.0, y), Vector2(key.position.x + fs * 1.6, y), ROUTE_COLOURS[k % 4], lw, true)
		_say_from(ci, font, Vector2(key.position.x + fs * 1.9, y), str(routes[k].name), fs - 1, INK, false, false)


## A leg of a voyage as line pieces [lat0, long0, lat1, long1]: two when it crosses the 180° line (the shorter way
## round the globe).
static func _wrap(lat0: float, long0: float, lat1: float, long1: float) -> Array:
	var dl := long1 - long0
	if absf(dl) <= 180.0:
		return [[lat0, long0, lat1, long1]]
	var edge0 := -180.0 if dl > 0.0 else 180.0   # going west from long0 to the left edge, or east to the right
	var run0 := absf(long0 - edge0)
	var run1 := absf(long1 + edge0)
	var t := run0 / (run0 + run1)
	var lat_c := lat0 + (lat1 - lat0) * t
	return [[lat0, long0, lat_c, edge0], [lat_c, -edge0, lat1, long1]]


# --- The Pole Star ----------------------------------------------------------------------------------------------------

const NIGHT_STARS: Array[Vector2] = [Vector2(0.62, 0.12), Vector2(0.82, 0.22), Vector2(0.93, 0.08), Vector2(0.72, 0.42),
	Vector2(0.9, 0.5), Vector2(0.55, 0.3), Vector2(0.08, 0.1), Vector2(0.25, 0.06), Vector2(0.4, 0.14),
	Vector2(0.97, 0.35), Vector2(0.78, 0.6), Vector2(0.64, 0.55)]


static func _draw_pole_star(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var angle := float(d.angle)
	var horizon := r.position.y + r.size.y * 0.8
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, horizon - r.position.y)), Color("1b2747"))
	ci.draw_rect(Rect2(r.position.x, horizon, r.size.x, r.end.y - horizon), Color("24497a"))
	for k in 3:
		var y := horizon + (r.end.y - horizon) * (k + 1) / 4.0
		for s in 5:
			var x := r.position.x + r.size.x * fmod(0.1 + 0.2 * s + 0.07 * k, 0.96)
			ci.draw_arc(Vector2(x, y), 6.0, PI * 1.1, PI * 1.9, 6, Color("8fb3dd"), 1.5)
	var o := Vector2(r.position.x + r.size.x * 0.16, horizon)
	var dir := Vector2(cos(deg_to_rad(angle)), -sin(deg_to_rad(angle)))
	var reach := minf((r.end.x - o.x) * 0.92 / maxf(dir.x, 0.05), (horizon - r.position.y - fs * 1.6) / maxf(-dir.y, 0.05))
	var star := o + dir * reach
	for f: Vector2 in NIGHT_STARS:
		var p := r.position + Vector2(r.size.x * f.x, (horizon - r.position.y) * f.y)
		if p.distance_to(star) > 24.0 and absf((p - o).angle() + deg_to_rad(angle)) > 0.08:
			ci.draw_circle(p, 1.8, Color("e8eefc"))
	# The ship, the horizon ahead and the line of sight to the star.
	_poly(ci, [o + Vector2(-26, -2), o + Vector2(20, -2), o + Vector2(12, 8), o + Vector2(-18, 8)], Color("7a4a2a"),
		Color("e8eefc"), 1.0)
	ci.draw_line(o + Vector2(-4, -2), o + Vector2(-4, -34), Color("e8eefc"), 2.0)
	_poly(ci, [o + Vector2(-2, -32), o + Vector2(14, -10), o + Vector2(-2, -10)], Color("f2ead8"), Color("e8eefc"), 1.0)
	ci.draw_line(o, Vector2(r.end.x - 4.0, horizon), Color.WHITE, 2.0)
	ci.draw_dashed_line(o, star, Color("ffe27a"), 2.0, 8.0)
	var arc_r := minf(reach * 0.34, r.size.y * 0.32)
	ci.draw_arc(o, arc_r, -deg_to_rad(angle), 0.0, 24, ORANGE, 3.0, true)
	var hidden := bool(d.get("hide", false))
	var mid := o + Vector2(cos(deg_to_rad(angle * 0.5)), -sin(deg_to_rad(angle * 0.5))) * (arc_r + fs * 1.3)
	_say(ci, font, mid, "?" if hidden else "%d°" % int(angle), fs + 1, ORANGE if hidden else INK)
	# The Pole Star: a bright four-pointed star.
	for k in 4:
		var v := Vector2.from_angle(k * PI * 0.5) * 11.0
		ci.draw_line(star - v, star + v, Color("fff4b0"), 2.0, true)
	ci.draw_circle(star, 4.5, Color("fffbe0"))
	if bool(d.get("labels", false)):
		var right := star.x + _text_w(font, "Pole Star", fs) + 20.0 < r.end.x
		_say_from(ci, font, star + Vector2(14.0 if right else -14.0, 0.0), "Pole Star", fs, INK, not right)
		_say_from(ci, font, Vector2(r.end.x - 6.0, horizon - fs * 0.7), "horizon", fs - 1, INK, true)


# --- The Columbian exchange -------------------------------------------------------------------------------------------

static func _draw_exchange(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 14.0)
	var bw := r.size.x * 0.2
	var left := Rect2(r.position.x, r.position.y + r.size.y * 0.08, bw, r.size.y * 0.84)
	var right := Rect2(r.end.x - bw, left.position.y, bw, left.size.y)
	_box(ci, left, Color("d7efc8"), INK, 8, 2)
	_box(ci, right, Color("f6e1bd"), INK, 8, 2)
	_words_in(ci, font, left, ["The", "Americas"], fs)
	_words_in(ci, font, right, ["Europe,", "Africa", "and Asia"], fs)
	var x0 := left.end.x + 8.0
	var x1 := right.position.x - 8.0
	for k in 2:
		var goods: Array = d.to_old if k == 0 else d.to_new
		var y := r.position.y + r.size.y * (0.27 if k == 0 else 0.73)
		var colour := Color("2e8b3e") if k == 0 else Color("a0522d")
		_arrow(ci, Vector2(x0 if k == 0 else x1, y), Vector2(x1 if k == 0 else x0, y), colour, 5.0)
		var per_row := mini(3, goods.size())
		var rows := ceili(goods.size() / 3.0)
		var cw := (x1 - x0) / per_row - 6.0
		var ch := minf(fs * 1.6, r.size.y * 0.2)
		var cfs := fs
		for g: Variant in goods:
			cfs = mini(cfs, _fit(font, "?" if str(g) == str(d.get("hide", "")) else str(g), fs, cw - 8.0))
		for i in goods.size():
			var row := i / 3
			var col := i % 3
			var in_row := per_row if row < rows - 1 or goods.size() % 3 == 0 else goods.size() % 3
			var cx := (x0 + x1) * 0.5 + (col - (in_row - 1) * 0.5) * (cw + 6.0)
			var cy := y - ch * 0.62 if row == 0 else y + ch * 0.62   # the first row above the arrow, the second below
			var hidden := d.has("hide") and str(d.hide) == str(goods[i])
			var chip := Rect2(cx - cw * 0.5, cy - ch * 0.5, cw, ch)
			_box(ci, chip, SOFT if hidden else Color.WHITE, ORANGE if hidden else colour, 6, 2)
			_say(ci, font, chip.get_center(), "?" if hidden else str(goods[i]), cfs, INK, false)


## Lines of words centred in a box.
static func _words_in(ci: CanvasItem, font: Font, box: Rect2, lines: Array, fs: int) -> void:
	var f := fs
	for l: Variant in lines:
		f = mini(f, _fit(font, str(l), fs, box.size.x - 8.0))
	var lh := f * 1.25
	var y0 := box.get_center().y - lh * (lines.size() - 1) * 0.5
	for i in lines.size():
		_say(ci, font, Vector2(box.get_center().x, y0 + i * lh), str(lines[i]), f, INK, false)


# --- Domes ------------------------------------------------------------------------------------------------------------

static func _draw_dome(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 14.0)
	var labels := bool(d.get("labels", false))
	var a := _fit_box(_inner(r, fs, labels), 1.9)
	ci.draw_rect(a, SKY)
	var anchors := {}
	if str(d.style) == "ottoman":
		_ottoman(ci, a, anchors)
	else:
		_mughal(ci, a, anchors)
	ci.draw_line(_at(a, 0.0, 1.0), _at(a, 1.0, 1.0), INK, 2.0)
	if labels:
		_label_parts(ci, font, r, d, anchors, fs)


## A slender minaret with balconies and a pointed cap, from ground level `base` to `top` (fractions of `a`).
static func _minaret(ci: CanvasItem, a: Rect2, x: float, top: float, base: float, colour: Color, cap: Color,
		balconies: int) -> Array:
	var w := 0.013
	_poly(ci, _pts(a, [Vector2(x - w, top + 0.1), Vector2(x + w, top + 0.1), Vector2(x + w, base), Vector2(x - w, base)]),
		colour, INK, 1.0)
	_poly(ci, _pts(a, [Vector2(x - w * 1.1, top + 0.1), Vector2(x + w * 1.1, top + 0.1), Vector2(x, top)]), cap, INK, 1.0)
	var out: Array = []
	for k in balconies:
		var y := top + 0.16 + k * (base - top - 0.3) / maxf(balconies, 1)
		_poly(ci, _pts(a, [Vector2(x - w * 2.0, y), Vector2(x + w * 2.0, y), Vector2(x + w * 1.4, y + 0.025),
			Vector2(x - w * 1.4, y + 0.025)]), colour.darkened(0.15), INK, 1.0)
		out.append(_at(a, x + w * 2.0, y + 0.012))
	return out


## A half-disc dome of radius rx (fraction of the width), sitting on y (fraction of the height).
static func _dome_arc(a: Rect2, cx: float, y: float, rx: float, ry: float, from: float = PI, to: float = TAU) -> Array:
	var out: Array = []
	for k in 25:
		var t := from + (to - from) * k / 24.0
		out.append(_at(a, cx + cos(t) * rx, y + sin(t) * ry))
	return out


static func _ottoman(ci: CanvasItem, a: Rect2, anchors: Dictionary) -> void:
	# The prayer hall, its windows, the drum and the great dome over two half-domes; small domes at the corners.
	_poly(ci, _pts(a, [Vector2(0.24, 0.62), Vector2(0.76, 0.62), Vector2(0.76, 1.0), Vector2(0.24, 1.0)]), STONE_WALL)
	for k in 9:
		var x := 0.27 + k * 0.057
		_poly(ci, _pts(a, [Vector2(x, 0.8), Vector2(x + 0.025, 0.8), Vector2(x + 0.025, 0.9), Vector2(x, 0.9)]),
			Color("6d7f99"), INK, 1.0)
		ci.draw_arc(_at(a, x + 0.0125, 0.8), a.size.x * 0.0125, PI, TAU, 8, INK, 1.0)
	_poly(ci, _dome_arc(a, 0.33, 0.62, 0.075, 0.13, PI, PI * 1.5) + [_at(a, 0.405, 0.62)], LEAD)
	_poly(ci, _dome_arc(a, 0.67, 0.62, 0.075, 0.13, PI * 1.5, TAU) + [_at(a, 0.595, 0.62)], LEAD)
	_poly(ci, _dome_arc(a, 0.27, 0.62, 0.03, 0.06), LEAD)
	_poly(ci, _dome_arc(a, 0.73, 0.62, 0.03, 0.06), LEAD)
	_poly(ci, _pts(a, [Vector2(0.39, 0.46), Vector2(0.61, 0.46), Vector2(0.61, 0.62), Vector2(0.39, 0.62)]), STONE_WALL)
	for k in 7:
		var x := 0.405 + k * 0.03
		_poly(ci, _pts(a, [Vector2(x, 0.5), Vector2(x + 0.012, 0.5), Vector2(x + 0.012, 0.58), Vector2(x, 0.58)]),
			Color("6d7f99"), INK, 0.8)
	_poly(ci, _dome_arc(a, 0.5, 0.46, 0.115, 0.3), LEAD)
	ci.draw_line(_at(a, 0.5, 0.16), _at(a, 0.5, 0.08), Color("c9a227"), 2.5)
	ci.draw_circle(_at(a, 0.5, 0.11), 3.0, Color("c9a227"))
	anchors["main dome"] = _at(a, 0.47, 0.22)
	anchors["half-dome"] = _at(a, 0.64, 0.56)
	# Four pencil minarets, the inner pair taller.
	var balcony: Array = []
	for m: Vector2 in [Vector2(0.1, 0.1), Vector2(0.18, 0.2), Vector2(0.82, 0.2), Vector2(0.9, 0.1)]:
		var b := _minaret(ci, a, m.x, m.y, 1.0, STONE_WALL, LEAD, 3 if m.y < 0.15 else 2)
		if balcony.is_empty():
			balcony = b
	anchors["minaret"] = _at(a, 0.9, 0.7)
	anchors["balcony"] = balcony[0]


## An onion dome: a bulb wider than its drum, narrowing to a point.
static func _onion(a: Rect2, cx: float, base: float, half: float, tall: float) -> Array:
	var profile: Array[Vector2] = [Vector2(1.0, 0.0), Vector2(1.16, 0.12), Vector2(1.24, 0.28), Vector2(1.14, 0.46),
		Vector2(0.86, 0.62), Vector2(0.5, 0.76), Vector2(0.2, 0.88), Vector2(0.0, 1.0)]
	var out: Array = []
	for p: Vector2 in profile:
		out.append(_at(a, cx + half * p.x, base - tall * p.y))
	for k in range(profile.size() - 2, -1, -1):
		out.append(_at(a, cx - half * profile[k].x, base - tall * profile[k].y))
	return out


static func _chhatri(ci: CanvasItem, a: Rect2, cx: float, base: float, half: float) -> void:
	_poly(ci, _pts(a, [Vector2(cx - half, base - 0.07), Vector2(cx + half, base - 0.07), Vector2(cx + half, base),
		Vector2(cx - half, base)]), MARBLE, Color("8f8a7c"), 1.0)
	ci.draw_line(_at(a, cx, base - 0.07), _at(a, cx, base), Color("8f8a7c"), 1.0)
	_poly(ci, _dome_arc(a, cx, base - 0.07, half * 1.1, 0.07), MARBLE, Color("8f8a7c"), 1.0)


static func _mughal(ci: CanvasItem, a: Rect2, anchors: Dictionary) -> void:
	var edge := Color("8f8a7c")
	# The platform, the tomb with its great arch (iwan) and smaller arches, the drum and the onion dome.
	_poly(ci, _pts(a, [Vector2(0.05, 0.9), Vector2(0.95, 0.9), Vector2(0.95, 1.0), Vector2(0.05, 1.0)]), Color("e9dcc6"), edge)
	anchors["platform"] = _at(a, 0.2, 0.95)
	_poly(ci, _pts(a, [Vector2(0.28, 0.5), Vector2(0.72, 0.5), Vector2(0.72, 0.9), Vector2(0.28, 0.9)]), MARBLE, edge)
	_poly(ci, _pts(a, [Vector2(0.45, 0.9), Vector2(0.45, 0.66), Vector2(0.47, 0.6), Vector2(0.5, 0.56), Vector2(0.53, 0.6),
		Vector2(0.55, 0.66), Vector2(0.55, 0.9)]), Color("cfd8e3"), edge)
	for x: float in [0.32, 0.62]:
		for y: float in [0.56, 0.74]:
			_poly(ci, _pts(a, [Vector2(x, y + 0.13), Vector2(x, y + 0.05), Vector2(x + 0.03, y), Vector2(x + 0.06, y + 0.05),
				Vector2(x + 0.06, y + 0.13)]), Color("dde3ea"), edge, 1.0)
	anchors["iwan"] = _at(a, 0.5, 0.75)
	_poly(ci, _pts(a, [Vector2(0.4, 0.4), Vector2(0.6, 0.4), Vector2(0.6, 0.5), Vector2(0.4, 0.5)]), MARBLE, edge)
	anchors["drum"] = _at(a, 0.58, 0.45)
	_poly(ci, _onion(a, 0.5, 0.4, 0.1, 0.32), MARBLE, edge)
	ci.draw_line(_at(a, 0.5, 0.08), _at(a, 0.5, 0.02), Color("c9a227"), 2.5)
	anchors["onion dome"] = _at(a, 0.45, 0.22)
	_chhatri(ci, a, 0.33, 0.5, 0.035)
	_chhatri(ci, a, 0.67, 0.5, 0.035)
	anchors["chhatri"] = _at(a, 0.67, 0.4)
	# Four minarets at the platform's corners (two seen), each with a chhatri on top.
	for x: float in [0.1, 0.9]:
		_poly(ci, _pts(a, [Vector2(x - 0.014, 0.28), Vector2(x + 0.014, 0.28), Vector2(x + 0.018, 0.9), Vector2(x - 0.018, 0.9)]),
			MARBLE, edge)
		for y: float in [0.48, 0.68]:
			_poly(ci, _pts(a, [Vector2(x - 0.026, y), Vector2(x + 0.026, y), Vector2(x + 0.022, y + 0.02), Vector2(x - 0.022, y + 0.02)]),
				MARBLE, edge, 1.0)
		_chhatri(ci, a, x, 0.28, 0.024)
	anchors["minaret"] = _at(a, 0.9, 0.6)


# --- A Mughal garden --------------------------------------------------------------------------------------------------

static func _draw_charbagh(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 14.0)
	var labels := bool(d.get("labels", false))
	var a := _fit_box(_inner(r, fs, labels), 2.1)
	var anchors := {}
	# From the left: the gateway, the square garden, the tomb's platform, the river.
	var g := a.size.y * 0.94
	var garden := Rect2(a.position.x + a.size.x * 0.1, a.get_center().y - g * 0.5, g, g)
	var river := Rect2(a.end.x - a.size.x * 0.1, a.position.y, a.size.x * 0.1, a.size.y)
	var platform := Rect2(garden.end.x + a.size.x * 0.02, garden.position.y, river.position.x - garden.end.x - a.size.x * 0.03,
		garden.size.y)
	ci.draw_rect(river, SEA)
	for k in 4:
		var y := river.position.y + river.size.y * (k + 0.5) / 4.0
		ci.draw_arc(Vector2(river.get_center().x, y), river.size.x * 0.25, PI * 1.1, PI * 1.9, 6, DEEP, 1.5)
	anchors["river"] = river.get_center() + Vector2(0, river.size.y * 0.3)
	var gate := Rect2(a.position.x + a.size.x * 0.02, garden.get_center().y - g * 0.14, garden.position.x - a.position.x - a.size.x * 0.02, g * 0.28)
	_box(ci, gate, Color("c98f6a"), INK, 3, 2)
	ci.draw_rect(Rect2(gate.end.x - gate.size.x * 0.35, gate.get_center().y - gate.size.y * 0.15, gate.size.x * 0.35, gate.size.y * 0.3), Color("6b4a2b"))
	anchors["gateway"] = gate.get_center()
	ci.draw_rect(garden, Color("e8dcc0"))
	var bed := g * 0.5
	for qx in 2:
		for qy in 2:
			for bx in 2:
				for by in 2:
					var cell := Rect2(garden.position + Vector2(qx * bed + bx * bed * 0.5, qy * bed + by * bed * 0.5), Vector2(bed * 0.5, bed * 0.5))
					ci.draw_rect(cell.grow(-g * 0.022), Color("8fcf6f"))
	for k in 12:
		var t := (k + 0.5) / 12.0
		for p: Vector2 in [Vector2(t, 0.5 - 0.06), Vector2(0.5 - 0.06, t)]:
			if absf(t - 0.5) > 0.08:
				ci.draw_circle(garden.position + p * g, g * 0.018, Color("2f7d32"))
	var cw := g * 0.05
	ci.draw_rect(Rect2(garden.position.x, garden.get_center().y - cw * 0.5, g, cw), DEEP)
	ci.draw_rect(Rect2(garden.get_center().x - cw * 0.5, garden.position.y, cw, g), DEEP)
	ci.draw_rect(Rect2(garden.get_center() - Vector2(g, g) * 0.07, Vector2(g, g) * 0.14), SEA)
	ci.draw_rect(Rect2(garden.get_center() - Vector2(g, g) * 0.07, Vector2(g, g) * 0.14), DEEP, false, 2.0)
	ci.draw_rect(garden, INK, false, 2.0)
	anchors["garden"] = garden.position + Vector2(g * 0.25, g * 0.25)
	anchors["water channel"] = garden.position + Vector2(g * 0.75, g * 0.5)
	anchors["pool"] = garden.get_center()
	# The platform with the mosque and the guest house on either side of the tomb, and minarets at its corners.
	ci.draw_rect(platform, Color("eadfca"))
	ci.draw_rect(platform, INK, false, 2.0)
	var t := platform.size.x * 0.34
	var tc := platform.get_center()
	var oct: Array = []
	for k in 8:
		oct.append(tc + Vector2.from_angle(PI / 8.0 + k * PI / 4.0) * t * 0.62)
	_poly(ci, oct, MARBLE, INK, 1.5)
	ci.draw_circle(tc, t * 0.3, Color("dfe4ea"))
	ci.draw_arc(tc, t * 0.3, 0.0, TAU, 24, INK, 1.5)
	for s: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		ci.draw_circle(tc + s * t * 0.62, t * 0.07, MARBLE)
		ci.draw_arc(tc + s * t * 0.62, t * 0.07, 0.0, TAU, 12, INK, 1.0)
	anchors["tomb"] = tc
	for y: float in [platform.position.y + platform.size.y * 0.1, platform.end.y - platform.size.y * 0.24]:
		var hall := Rect2(tc.x - platform.size.x * 0.3, y, platform.size.x * 0.6, platform.size.y * 0.14)
		ci.draw_rect(hall, Color("c98f6a"))
		ci.draw_rect(hall, INK, false, 1.0)
		for k in 3:
			ci.draw_circle(Vector2(hall.position.x + hall.size.x * (k + 0.5) / 3.0, hall.get_center().y), hall.size.y * 0.3, Color("eadfca"))
	if labels:
		_label_parts(ci, font, r, d, anchors, fs, ["gateway", "garden", "pool", "tomb"])


# --- The heavens ------------------------------------------------------------------------------------------------------

static func _draw_sky(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 14.0)
	var model := str(d.model)
	if model == "jupiter":
		_draw_jupiter(ci, font, r, d, fs)
		return
	var list := bodies(model)
	var labels := bool(d.get("labels", false))
	var title := ("Ptolemy: the Earth in the middle" if model == "earth" else "Copernicus: the Sun in the middle") \
		if labels else ""
	var top := r.position.y + (fs * 1.4 if labels else 0.0)
	var c := Vector2(r.get_center().x, (top + r.end.y) * 0.5)
	var rx := r.size.x * 0.47
	var ry := (r.end.y - top) * 0.47
	var n := list.size() - 1
	var angles: Array[float] = [0.0, 3.4, 0.75, 2.75, 5.85, 3.8, 0.35, 2.45]   # near the sides, never the top or bottom
	for k in range(1, list.size()):
		var t := float(k) / n
		var pts := PackedVector2Array()
		for s in 49:
			var th := TAU * s / 48.0
			pts.append(c + Vector2(cos(th) * rx * t, sin(th) * ry * t))
		ci.draw_polyline(pts, Color("b7c3d6"), 1.2, true)
	for k in list.size():
		var name := list[k]
		var t := float(k) / n
		var p := c + Vector2(cos(angles[k]) * rx * t, sin(angles[k]) * ry * t)
		var size := {"Sun": 0.09, "Earth": 0.05, "Jupiter": 0.055, "Saturn": 0.045}.get(name, 0.03) as float
		var radius := clampf(r.size.y * size, 3.0, 22.0)
		var said: Array = _label_of(d, name, name)
		if name == "Saturn":
			ci.draw_arc(p, radius * 1.7, 0.0, TAU, 24, Color("b39a62"), 2.0)
		ci.draw_circle(p, radius, BODY_COLOURS[name])
		ci.draw_arc(p, radius, 0.0, TAU, 20, ORANGE if said[1] == ORANGE else INK, 3.0 if said[1] == ORANGE else 1.0)
		if name == "Earth" and model == "sun":
			ci.draw_circle(p + Vector2(radius * 1.6, -radius * 0.9), maxf(2.0, radius * 0.35), BODY_COLOURS["Moon"])
		if labels or said[0] == "?":
			var right := cos(angles[k]) >= 0.0 or k == 0
			_say_from(ci, font, p + Vector2((radius + 4.0) * (1.0 if right else -1.0), -radius - fs * 0.35), str(said[0]),
				fs - 1, INK if said[1] == INK else ORANGE, not right)
	if title != "":
		_say_from(ci, font, Vector2(r.position.x + 2.0, r.position.y + fs * 0.7), title, _fit(font, title, fs, r.size.x - 4.0))


## Galileo's notes of January 1610: Jupiter and the "stars" beside it, night after night.
static func _draw_jupiter(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary, fs: int) -> void:
	var nights: Array = d.nights
	var rh := r.size.y / nights.size()
	var lw := _text_w(font, "Night 4", fs) + 10.0
	var x0 := r.position.x + lw
	var x1 := r.end.x - 8.0
	var cx := (x0 + x1) * 0.5
	var unit := (x1 - x0) * 0.5 / (MOON_REACH + 0.8)
	var jr := minf(unit * 0.55, rh * 0.28)
	for i in nights.size():
		var y := r.position.y + rh * (i + 0.5)
		ci.draw_line(Vector2(x0, y + rh * 0.45), Vector2(x1, y + rh * 0.45), Color("e3d6b8"), 1.0)
		_say_from(ci, font, Vector2(r.position.x + 2.0, y), "Night %d" % (i + 1), fs, INK, false, false)
		ci.draw_circle(Vector2(cx, y), jr, Color("f3e6c8"))
		ci.draw_arc(Vector2(cx, y), jr, 0.0, TAU, 24, INK, 2.0)
		ci.draw_line(Vector2(cx - jr * 0.8, y - jr * 0.3), Vector2(cx + jr * 0.8, y - jr * 0.3), INK, 1.0)
		ci.draw_line(Vector2(cx - jr * 0.8, y + jr * 0.3), Vector2(cx + jr * 0.8, y + jr * 0.3), INK, 1.0)
		for m: Variant in nights[i]:
			var p := Vector2(cx + int(m) * unit, y)
			var s := maxf(3.0, jr * 0.35)
			ci.draw_line(p - Vector2(s, 0), p + Vector2(s, 0), INK, 2.0)
			ci.draw_line(p - Vector2(0, s), p + Vector2(0, s), INK, 2.0)
			ci.draw_line(p - Vector2(s, s) * 0.7, p + Vector2(s, s) * 0.7, INK, 1.2)
			ci.draw_line(p - Vector2(s, -s) * 0.7, p + Vector2(s, -s) * 0.7, INK, 1.2)


# --- A family tree ----------------------------------------------------------------------------------------------------

static func _draw_tree(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 15.0)
	var people: Array = d.people
	var rows := 1
	var cols := 1.0
	for p: Dictionary in people:
		rows = maxi(rows, int(p.row) + 1)
		cols = maxf(cols, float(p.col) + 1.0)
	var cw := r.size.x / cols
	var rh := r.size.y / rows
	var bw := minf(cw - 8.0, fs * 9.0)
	var bh := minf(rh - 12.0, fs * 2.8)
	var centre := func(p: Dictionary) -> Vector2:
		return Vector2(r.position.x + cw * (float(p.col) + 0.5), r.position.y + rh * (int(p.row) + 0.5))
	var partner := {}
	for c: Array in d.get("couples", []):
		partner[int(c[0])] = int(c[1])
		partner[int(c[1])] = int(c[0])
		var a: Vector2 = centre.call(people[int(c[0])])
		var b: Vector2 = centre.call(people[int(c[1])])
		ci.draw_line(Vector2(minf(a.x, b.x) + bw * 0.5, a.y - 3.0), Vector2(maxf(a.x, b.x) - bw * 0.5, a.y - 3.0), INK, 2.0)
		ci.draw_line(Vector2(minf(a.x, b.x) + bw * 0.5, a.y + 3.0), Vector2(maxf(a.x, b.x) - bw * 0.5, a.y + 3.0), INK, 2.0)
	for l: Array in d.links:
		var parent: Vector2 = centre.call(people[int(l[0])])
		var child: Vector2 = centre.call(people[int(l[1])])
		var from := Vector2(parent.x, parent.y + bh * 0.5)
		if partner.has(int(l[0])):
			var other: Vector2 = centre.call(people[int(partner[int(l[0])])])
			from = Vector2((parent.x + other.x) * 0.5, parent.y)
		var to := Vector2(child.x, child.y - bh * 0.5)
		var mid := to.y - (rh - bh) * 0.5
		ci.draw_polyline(PackedVector2Array([from, Vector2(from.x, mid), Vector2(to.x, mid), to]), INK, 2.0)
	for i in people.size():
		var p: Dictionary = people[i]
		var c: Vector2 = centre.call(p)
		var marked := d.has("mark") and int(d.mark) == i
		var hidden := d.has("hide") and int(d.hide) == i
		var box := Rect2(c - Vector2(bw, bh) * 0.5, Vector2(bw, bh))
		_box(ci, box, SOFT if marked or hidden else Color("fffaf0"), ORANGE if marked or hidden else INK, 6, 2)
		var name := "?" if hidden else str(p.name)
		var years := str(p.get("years", ""))
		var lines: Array = [name]
		var nfs := _fit(font, name, fs, bw - 6.0)
		if nfs < fs - 2 and name.contains(" ") and not hidden:   # a long name on two lines
			var cut := name.rfind(" ", name.length() / 2 + 2)
			if cut <= 0:
				cut = name.find(" ")
			lines = [name.substr(0, cut), name.substr(cut + 1)]
			nfs = mini(_fit(font, str(lines[0]), fs, bw - 6.0), _fit(font, str(lines[1]), fs, bw - 6.0))
		if years != "":
			lines.append(years)
		var lh := minf(nfs * 1.15, (bh - 4.0) / lines.size())
		nfs = mini(nfs, int(lh / 1.1))
		for k in lines.size():
			var is_years := years != "" and k == lines.size() - 1
			_say(ci, font, Vector2(c.x, c.y + (k - (lines.size() - 1) * 0.5) * lh), str(lines[k]),
				maxi(8, nfs - (1 if is_years else 0)), Color("5a6378") if is_years else INK, false)


# --- Plate boundaries -------------------------------------------------------------------------------------------------

static func _draw_plates(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 14.0)
	var labels := bool(d.get("labels", false))
	var a := _inner(r, fs, labels)
	var anchors := {}
	match str(d.type):
		"divergent":
			ci.draw_rect(Rect2(a.position, Vector2(a.size.x, a.size.y * 0.25)), SKY)
			ci.draw_rect(Rect2(_at(a, 0, 0.25), Vector2(a.size.x, a.size.y * 0.3)), SEA)
			ci.draw_rect(Rect2(_at(a, 0, 0.62), Vector2(a.size.x, a.size.y * 0.38)), MANTLE)
			_poly(ci, _pts(a, [Vector2(0, 0.52), Vector2(0.42, 0.40), Vector2(0.47, 0.37), Vector2(0.47, 0.52), Vector2(0.4, 0.66),
				Vector2(0, 0.66)]), OCEAN_CRUST)
			_poly(ci, _pts(a, [Vector2(1, 0.52), Vector2(0.58, 0.40), Vector2(0.53, 0.37), Vector2(0.53, 0.52), Vector2(0.6, 0.66),
				Vector2(1, 0.66)]), OCEAN_CRUST)
			_poly(ci, _pts(a, [Vector2(0.47, 0.37), Vector2(0.53, 0.37), Vector2(0.53, 0.52), Vector2(0.6, 0.66), Vector2(0.66, 0.9),
				Vector2(0.34, 0.9), Vector2(0.4, 0.66), Vector2(0.47, 0.52)]), MAGMA, INK, 1.0)
			for s: float in [-1.0, 1.0]:
				_poly(ci, _pts(a, [Vector2(0.5 + s * 0.03, 0.375), Vector2(0.5 + s * 0.075, 0.36), Vector2(0.5 + s * 0.075, 0.5),
					Vector2(0.5 + s * 0.03, 0.52)]), Color("8a9a92"), INK, 1.0)
				_arrow(ci, _at(a, 0.5 + s * 0.2, 0.5), _at(a, 0.5 + s * 0.36, 0.55), Color.WHITE, 4.0)
				_arrow(ci, _at(a, 0.5 + s * 0.08, 0.8), _at(a, 0.5 + s * 0.3, 0.8), Color("9a3b12"), 3.0)
			anchors["ridge"] = _at(a, 0.5, 0.36)
			anchors["magma"] = _at(a, 0.5, 0.8)
			anchors["new crust"] = _at(a, 0.56, 0.44)
			anchors["plate"] = _at(a, 0.15, 0.6)
		"subduction":
			ci.draw_rect(a, SKY)
			ci.draw_rect(Rect2(_at(a, 0, 0.3), Vector2(a.size.x * 0.55, a.size.y * 0.25)), SEA)
			ci.draw_rect(Rect2(_at(a, 0, 0.62), Vector2(a.size.x, a.size.y * 0.38)), MANTLE)
			_poly(ci, _pts(a, [Vector2(0, 0.5), Vector2(0.44, 0.5), Vector2(0.72, 1.0), Vector2(0.58, 1.0), Vector2(0.4, 0.64),
				Vector2(0, 0.64)]), OCEAN_CRUST)
			_poly(ci, _pts(a, [Vector2(0.47, 0.5), Vector2(0.5, 0.36), Vector2(0.68, 0.3), Vector2(0.74, 0.14), Vector2(0.76, 0.13),
				Vector2(0.8, 0.28), Vector2(1, 0.3), Vector2(1, 0.78), Vector2(0.8, 0.78), Vector2(0.62, 0.72)]), LAND_CRUST)
			ci.draw_rect(Rect2(_at(a, 0.5, 0.3), Vector2(a.size.x * 0.5, a.size.y * 0.02)), GRASS)
			_poly(ci, _pts(a, [Vector2(0.44, 0.5), Vector2(0.455, 0.56), Vector2(0.47, 0.5)]), Color("2f5f95"))
			var pipe := _pts(a, [Vector2(0.745, 0.15), Vector2(0.755, 0.15), Vector2(0.72, 0.6), Vector2(0.66, 0.84), Vector2(0.64, 0.84),
				Vector2(0.7, 0.6)])
			_poly(ci, pipe, MAGMA, INK, 1.0)
			ci.draw_circle(_at(a, 0.75, 0.1), a.size.y * 0.03, Color("8a8a8a"))
			ci.draw_circle(_at(a, 0.78, 0.05), a.size.y * 0.04, Color("a0a0a0"))
			_arrow(ci, _at(a, 0.1, 0.57), _at(a, 0.3, 0.57), Color.WHITE, 4.0)
			_arrow(ci, _at(a, 0.96, 0.6), _at(a, 0.84, 0.6), Color.WHITE, 4.0)
			anchors["oceanic plate"] = _at(a, 0.2, 0.6)
			anchors["continental plate"] = _at(a, 0.9, 0.5)
			anchors["trench"] = _at(a, 0.455, 0.54)
			anchors["volcano"] = _at(a, 0.75, 0.14)
			anchors["magma"] = _at(a, 0.68, 0.76)
		"collision":
			ci.draw_rect(a, SKY)
			ci.draw_rect(Rect2(_at(a, 0, 0.7), Vector2(a.size.x, a.size.y * 0.3)), MANTLE)
			var peak: Array = _pts(a, [Vector2(0, 0.45), Vector2(0.3, 0.44), Vector2(0.38, 0.3), Vector2(0.44, 0.18), Vector2(0.5, 0.08),
				Vector2(0.56, 0.2), Vector2(0.62, 0.28), Vector2(0.7, 0.44), Vector2(1, 0.45), Vector2(1, 0.72), Vector2(0.6, 0.74),
				Vector2(0.5, 0.95), Vector2(0.4, 0.74), Vector2(0, 0.72)])
			_poly(ci, peak, LAND_CRUST)
			for k in 4:   # folded layers
				var y := 0.5 + k * 0.05
				var pts := PackedVector2Array()
				for s in 21:
					var x := s / 20.0
					var lift := maxf(0.0, 1.0 - absf(x - 0.5) / 0.22) * 0.25
					pts.append(_at(a, x, y - lift + sin(x * 40.0) * lift * 0.2))
				ci.draw_polyline(pts, LAND_CRUST.darkened(0.3), 1.5, true)
			ci.draw_colored_polygon(PackedVector2Array(_pts(a, [Vector2(0.46, 0.14), Vector2(0.5, 0.08), Vector2(0.54, 0.16)])),
				Color.WHITE)
			_arrow(ci, _at(a, 0.05, 0.6), _at(a, 0.25, 0.6), Color.WHITE, 4.0)
			_arrow(ci, _at(a, 0.95, 0.6), _at(a, 0.75, 0.6), Color.WHITE, 4.0)
			anchors["fold mountains"] = _at(a, 0.5, 0.1)
			anchors["continental plate"] = _at(a, 0.15, 0.66)
		"transform":
			_poly(ci, _pts(a, [Vector2(0, 0), Vector2(0.5, 0), Vector2(0.49, 0.3), Vector2(0.51, 0.6), Vector2(0.5, 1.0), Vector2(0, 1.0)]),
				Color("c9dfa9"))
			_poly(ci, _pts(a, [Vector2(1, 0), Vector2(0.5, 0), Vector2(0.49, 0.3), Vector2(0.51, 0.6), Vector2(0.5, 1.0), Vector2(1, 1.0)]),
				Color("dfd2a0"))
			ci.draw_polyline(PackedVector2Array(_pts(a, [Vector2(0.5, 0), Vector2(0.49, 0.3), Vector2(0.51, 0.6), Vector2(0.5, 1.0)])),
				RED, 4.0, true)
			ci.draw_rect(Rect2(_at(a, 0.0, 0.38), Vector2(a.size.x * 0.495, a.size.y * 0.1)), Color("7d828c"))
			ci.draw_rect(Rect2(_at(a, 0.505, 0.58), Vector2(a.size.x * 0.495, a.size.y * 0.1)), Color("7d828c"))
			for k in 5:
				ci.draw_line(_at(a, 0.04 + k * 0.1, 0.43), _at(a, 0.08 + k * 0.1, 0.43), Color.WHITE, 2.0)
				ci.draw_line(_at(a, 0.54 + k * 0.1, 0.63), _at(a, 0.58 + k * 0.1, 0.63), Color.WHITE, 2.0)
			_arrow(ci, _at(a, 0.25, 0.9), _at(a, 0.25, 0.62), INK, 5.0)
			_arrow(ci, _at(a, 0.75, 0.1), _at(a, 0.75, 0.4), INK, 5.0)
			anchors["fault"] = _at(a, 0.5, 0.15)
			anchors["plate"] = _at(a, 0.1, 0.8)
			anchors["road"] = _at(a, 0.8, 0.63)
	if labels:
		_label_parts(ci, font, r, d, anchors, fs)


# --- The rock cycle ---------------------------------------------------------------------------------------------------

static func _draw_rock_cycle(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 14.0)
	var c := r.get_center()
	var rx := r.size.x * 0.36
	var ry := r.size.y * 0.36
	var angles: Array[float] = [PI * 0.5, PI * 0.9, PI * 1.3, PI * 1.7, PI * 0.1]   # magma at the bottom, then round
	var boxes: Array[Rect2] = []
	for i in ROCK_STEPS.size():
		var said: Array = _label_of(d, ROCK_STEPS[i], ROCK_STEPS[i])
		var p := c + Vector2(cos(angles[i]) * rx, sin(angles[i]) * ry)
		var bfs := _fit(font, str(said[0]), fs, r.size.x * 0.3)
		var w := _text_w(font, str(said[0]), bfs) + 16.0
		var h := bfs * 1.7
		var box := Rect2(p - Vector2(w, h) * 0.5, Vector2(w, h))
		box.position.x = clampf(box.position.x, r.position.x, r.end.x - w)
		box.position.y = clampf(box.position.y, r.position.y, r.end.y - h)
		boxes.append(box)
	var labels := bool(d.get("labels", true))
	for i in ROCK_STEPS.size():
		var a := boxes[i]
		var b := boxes[(i + 1) % boxes.size()]
		var from := _edge_toward(a, b.get_center())
		var to := _edge_toward(b, a.get_center())
		_arrow(ci, from, to, Color("6b5b45"), 3.0)
		var said: Array = _label_of(d, ROCK_PROCESSES[i], ROCK_PROCESSES[i])
		if labels or said[0] == "?":
			var mid := (from + to) * 0.5
			var inward := mid + (c - mid) * 0.22
			var pfs := _fit(font, str(said[0]), fs - 2, r.size.x * 0.32)
			_say(ci, font, inward, str(said[0]), pfs, ORANGE if said[1] == ORANGE else Color("5a4632"))
	for i in ROCK_STEPS.size():
		var said: Array = _label_of(d, ROCK_STEPS[i], ROCK_STEPS[i])
		var marked: bool = said[1] == ORANGE
		_box(ci, boxes[i], ROCK_COLOURS[i] if not marked else SOFT, ORANGE if marked else INK, 8, 3 if marked else 2)
		_say(ci, font, boxes[i].get_center(), str(said[0]), _fit(font, str(said[0]), fs, r.size.x * 0.3), INK, false)


## Where a line from a box's centre towards `p` leaves the box.
static func _edge_toward(box: Rect2, p: Vector2) -> Vector2:
	var c := box.get_center()
	var v := p - c
	if v.length() < 0.001:
		return c
	var sx := (box.size.x * 0.5) / maxf(absf(v.x), 0.001)
	var sy := (box.size.y * 0.5) / maxf(absf(v.y), 0.001)
	return c + v * minf(minf(sx, sy), 1.0) + v.normalized() * 3.0


# --- A soil's layers --------------------------------------------------------------------------------------------------

static func _draw_soil(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 14.0)
	var labels := bool(d.get("labels", false))
	var col := Rect2(r.position.x + r.size.x * 0.04, r.position.y + r.size.y * 0.1, r.size.x * (0.44 if labels else 0.92),
		r.size.y * 0.9)
	var thick: Array[float] = [0.1, 0.22, 0.24, 0.2, 0.24]
	# The grass on top, with roots reaching down.
	ci.draw_rect(Rect2(col.position.x, r.position.y, col.size.x, col.position.y - r.position.y), SKY)
	var y := col.position.y
	var tops: Array[float] = []
	for i in HORIZONS.size():
		var h := col.size.y * thick[i]
		tops.append(y)
		ci.draw_rect(Rect2(col.position.x, y, col.size.x, h), HORIZON_COLOURS[i])
		y += h
	for k in 14:
		var x := col.position.x + col.size.x * (k + 0.5) / 14.0
		ci.draw_line(Vector2(x, col.position.y), Vector2(x - 3.0, col.position.y - r.size.y * 0.07), Color("3f8f2f"), 2.0)
		if k % 3 == 1:
			ci.draw_polyline(PackedVector2Array([Vector2(x, col.position.y), Vector2(x + 4.0, tops[1] + col.size.y * 0.08),
				Vector2(x - 2.0, tops[2] - 4.0)]), Color("d9c7a0"), 1.2)
	for k in 3:   # worms in the topsoil
		var w0 := Vector2(col.position.x + col.size.x * (0.2 + 0.3 * k), tops[1] + col.size.y * (0.08 + 0.04 * k))
		ci.draw_polyline(PackedVector2Array([w0, w0 + Vector2(6, -3), w0 + Vector2(12, 0), w0 + Vector2(18, -3)]),
			Color("e89aa0"), 3.0, true)
	for k in 9:   # stones in the subsoil, broken rock below
		ci.draw_circle(Vector2(col.position.x + col.size.x * fmod(0.13 + k * 0.37, 1.0), tops[2] + col.size.y * (0.05 + 0.02 * (k % 4))),
			3.0, Color("d6cdbd"))
	for k in 7:
		var p := Vector2(col.position.x + col.size.x * fmod(0.08 + k * 0.29, 0.9), tops[3] + col.size.y * (0.03 + 0.03 * (k % 4)))
		_poly(ci, [p, p + Vector2(14, -3), p + Vector2(18, 8), p + Vector2(3, 10)], Color("9a9a9a"), INK, 1.0)
	for k in 3:
		var x := col.position.x + col.size.x * (0.25 + 0.25 * k)
		ci.draw_polyline(PackedVector2Array([Vector2(x, tops[4] + 4.0), Vector2(x + 6.0, tops[4] + col.size.y * 0.1),
			Vector2(x + 2.0, col.end.y - 4.0)]), Color("5f5f5f"), 1.5)
	ci.draw_rect(col, INK, false, 2.0)
	for i in HORIZONS.size():
		if d.has("mark") and str(d.mark) == HORIZONS[i]:
			ci.draw_rect(Rect2(col.position.x + 2.0, tops[i] + 2.0, col.size.x - 4.0, col.size.y * thick[i] - 4.0), ORANGE,
				false, 4.0)
	for i in HORIZONS.size():
		var h := col.size.y * thick[i]
		var mid := tops[i] + h * 0.5
		_say(ci, font, Vector2(col.position.x + fs * 0.8, mid), HORIZON_LETTERS[i], _fit(font, "O", fs, 40.0),
			Color.WHITE if i != 3 else INK, false)
		if labels:
			var said: Array = _label_of(d, HORIZONS[i], HORIZONS[i])
			var lx := col.end.x + 16.0
			ci.draw_line(Vector2(col.end.x - 6.0, mid), Vector2(lx - 4.0, mid), INK, 1.5)
			var text := "%s  %s" % [HORIZON_LETTERS[i], said[0]]
			var lfs := _fit(font, text, fs, r.end.x - lx - 2.0)
			_say_from(ci, font, Vector2(lx, mid), text, mini(lfs, int(h * 0.8) + 4), ORANGE if said[1] == ORANGE else INK)


# --- Glaciers ---------------------------------------------------------------------------------------------------------

static func _draw_glacier(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 14.0)
	var labels := bool(d.get("labels", false))
	var a := _inner(r, fs, labels)
	var anchors := {}
	var rock := Color("9a9f8a")
	var tops: Array = []
	match str(d.view):
		"compare":
			ci.draw_rect(a, SKY)
			var left := Rect2(a.position, Vector2(a.size.x * 0.48, a.size.y))
			var right := Rect2(a.position + Vector2(a.size.x * 0.52, 0), Vector2(a.size.x * 0.48, a.size.y))
			_poly(ci, _pts(left, [Vector2(0, 0.1), Vector2(0.46, 0.9), Vector2(0.54, 0.9), Vector2(1, 0.1), Vector2(1, 1),
				Vector2(0, 1)]), GRASS.darkened(0.1))
			_poly(ci, _pts(left, [Vector2(0.46, 0.9), Vector2(0.54, 0.9), Vector2(0.52, 0.94), Vector2(0.48, 0.94)]), DEEP, DEEP, 1.0)
			var u: Array = [_at(right, 0, 0.1)]
			for k in 21:
				var t := k / 20.0
				u.append(_at(right, 0.12 + 0.76 * t, 0.9 - 0.55 * pow(absf(t - 0.5) * 2.0, 4.0) - 0.0))
			u += [_at(right, 1, 0.1), _at(right, 1, 1), _at(right, 0, 1)]
			_poly(ci, u, GRASS.darkened(0.1))
			ci.draw_dashed_line(_at(right, 0.2, 0.25), _at(right, 0.5, 0.88), INK, 1.5, 6.0)
			ci.draw_dashed_line(_at(right, 0.8, 0.25), _at(right, 0.5, 0.88), INK, 1.5, 6.0)
			ci.draw_rect(Rect2(_at(right, 0.35, 0.885), Vector2(right.size.x * 0.3, 4.0)), DEEP)
			anchors["V-shaped valley"] = _at(left, 0.3, 0.6)
			anchors["U-shaped valley"] = _at(right, 0.5, 0.7)
			anchors["steep sides"] = _at(right, 0.14, 0.6)
			anchors["flat floor"] = _at(right, 0.7, 0.89)
			tops = ["V-shaped valley", "U-shaped valley"]
		"landforms":
			ci.draw_rect(a, SKY)
			_poly(ci, _pts(a, [Vector2(0.14, 0.52), Vector2(0.3, 0.05), Vector2(0.4, 0.3), Vector2(0.47, 0.22), Vector2(0.53, 0.3),
				Vector2(0.58, 0.2), Vector2(0.64, 0.14), Vector2(0.84, 0.52)]), rock, INK, 1.2)
			_poly(ci, _pts(a, [Vector2(0.3, 0.05), Vector2(0.34, 0.3), Vector2(0.4, 0.3)]), rock.darkened(0.2), INK, 0.0)
			_poly(ci, _pts(a, [Vector2(0.3, 0.05), Vector2(0.27, 0.14), Vector2(0.33, 0.14)]), Color.WHITE, INK, 0.0)
			_poly(ci, _pts(a, [Vector2(0.64, 0.14), Vector2(0.61, 0.2), Vector2(0.67, 0.2)]), Color.WHITE, INK, 0.0)
			# The corrie: a bowl under the ridge, a tarn in it.
			_poly(ci, _dome_arc(a, 0.5, 0.33, 0.07, 0.1, 0.0, PI), rock.darkened(0.25), INK, 1.0)
			ci.draw_set_transform(_at(a, 0.5, 0.38), 0.0, Vector2(1.0, 0.35))
			ci.draw_circle(Vector2.ZERO, a.size.x * 0.035, DEEP)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			# The U-shaped valley coming towards us, its ribbon lake, the hanging valley and its waterfall, the moraine.
			_poly(ci, _pts(a, [Vector2(0, 0.42), Vector2(0.2, 0.5), Vector2(0.42, 0.56), Vector2(0.3, 1.0), Vector2(0, 1.0)]),
				Color("8fbf6f"), INK, 1.2)
			_poly(ci, _pts(a, [Vector2(1, 0.44), Vector2(0.8, 0.5), Vector2(0.58, 0.56), Vector2(0.7, 1.0), Vector2(1, 1.0)]),
				Color("8fbf6f"), INK, 1.2)
			_poly(ci, _pts(a, [Vector2(0.42, 0.56), Vector2(0.58, 0.56), Vector2(0.7, 1.0), Vector2(0.3, 1.0)]), Color("b9dc9a"), INK, 0.0)
			_poly(ci, _pts(a, [Vector2(0.47, 0.6), Vector2(0.53, 0.6), Vector2(0.62, 0.9), Vector2(0.38, 0.9)]), DEEP, INK, 0.0)
			_poly(ci, _pts(a, [Vector2(0.84, 0.47), Vector2(0.9, 0.44), Vector2(0.9, 0.5), Vector2(0.86, 0.52)]), Color("6f9f4f"), INK, 1.0)
			ci.draw_polyline(PackedVector2Array(_pts(a, [Vector2(0.86, 0.52), Vector2(0.84, 0.6), Vector2(0.86, 0.68), Vector2(0.83, 0.78)])),
				Color.WHITE, 3.0, true)
			for k in 7:
				ci.draw_arc(_at(a, 0.33 + k * 0.057, 0.955), a.size.x * 0.03, PI, TAU, 10, Color("8a6a3a"), 3.0)
			anchors["pyramidal peak"] = _at(a, 0.3, 0.07)
			anchors["arete"] = _at(a, 0.56, 0.22)
			anchors["corrie"] = _at(a, 0.45, 0.35)
			anchors["tarn"] = _at(a, 0.52, 0.38)
			anchors["hanging valley"] = _at(a, 0.88, 0.47)
			anchors["ribbon lake"] = _at(a, 0.5, 0.75)
			anchors["moraine"] = _at(a, 0.62, 0.94)
			tops = ["pyramidal peak", "arete", "corrie", "tarn"]
		"corrie":
			ci.draw_rect(a, SKY)
			var slope: Array = _pts(a, [Vector2(0, 0.1), Vector2(0.18, 0.12), Vector2(0.22, 0.2), Vector2(0.26, 0.62),
				Vector2(0.36, 0.78), Vector2(0.52, 0.8), Vector2(0.64, 0.66), Vector2(0.7, 0.64), Vector2(0.78, 0.74),
				Vector2(1, 0.9), Vector2(1, 1), Vector2(0, 1)])
			_poly(ci, slope, rock, INK, 1.5)
			_poly(ci, _pts(a, [Vector2(0.24, 0.3), Vector2(0.4, 0.34), Vector2(0.62, 0.42), Vector2(0.66, 0.64), Vector2(0.52, 0.78),
				Vector2(0.36, 0.76), Vector2(0.27, 0.62)]), ICE, Color("7fb6e8"), 2.0)
			ci.draw_arc(_at(a, 0.44, 0.58), a.size.y * 0.15, PI * 0.2, PI * 1.3, 16, Color("3f86d0"), 3.0, true)
			_arrow(ci, _at(a, 0.47, 0.72), _at(a, 0.58, 0.64), Color("3f86d0"), 3.0)
			for k in 3:   # plucked pieces pulled from the back wall
				var p := _at(a, 0.27, 0.42 + k * 0.08)
				_poly(ci, [p, p + Vector2(8, -2), p + Vector2(10, 5), p + Vector2(2, 7)], DARK_STONE, INK, 1.0)
				_arrow(ci, p + Vector2(12, 3), p + Vector2(28, 3), INK, 2.0)
			for k in 4:   # scratches on the floor
				ci.draw_line(_at(a, 0.34 + k * 0.05, 0.775), _at(a, 0.37 + k * 0.05, 0.785), INK, 1.5)
			for k in 3:   # frost cracks above the ice
				var p := _at(a, 0.2 + k * 0.012, 0.16 + k * 0.03)
				ci.draw_polyline(PackedVector2Array([p, p + Vector2(6, 4), p + Vector2(3, 9)]), INK, 1.5)
			anchors["back wall"] = _at(a, 0.23, 0.28)
			anchors["plucking"] = _at(a, 0.3, 0.5)
			anchors["abrasion"] = _at(a, 0.42, 0.78)
			anchors["freeze-thaw"] = _at(a, 0.21, 0.18)
			anchors["lip"] = _at(a, 0.66, 0.65)
			tops = ["back wall", "freeze-thaw", "lip"]
	if labels:
		_label_parts(ci, font, r, d, anchors, fs, tops)


# --- Coasts -----------------------------------------------------------------------------------------------------------

static func _draw_coast(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 14.0)
	var labels := bool(d.get("labels", false))
	var a := _inner(r, fs, labels)
	var anchors := {}
	var tops: Array = []
	match str(d.view):
		"headland":
			ci.draw_rect(a, SKY)
			ci.draw_rect(Rect2(_at(a, 0, 0.72), Vector2(a.size.x, a.size.y * 0.28)), SEA)
			ci.draw_rect(Rect2(_at(a, 0.55, 0.72), Vector2(a.size.x * 0.42, a.size.y * 0.035)), Color(0.55, 0.45, 0.35, 0.55))
			# The headland: its cliff face with a crack, a cave and an arch; then a stack and a stump out at sea.
			_poly(ci, _pts(a, [Vector2(0, 0.14), Vector2(0.55, 0.16), Vector2(0.56, 0.72), Vector2(0, 0.72)]), CLIFF, INK, 1.5)
			ci.draw_rect(Rect2(_at(a, 0, 0.1), Vector2(a.size.x * 0.55, a.size.y * 0.05)), GRASS)
			ci.draw_polyline(PackedVector2Array(_pts(a, [Vector2(0.12, 0.72), Vector2(0.125, 0.6), Vector2(0.115, 0.5),
				Vector2(0.12, 0.42)])), INK, 2.0)
			_poly(ci, _dome_arc(a, 0.26, 0.72, 0.045, 0.14) , Color("5a4a3a"), INK, 1.0)
			_poly(ci, _dome_arc(a, 0.43, 0.72, 0.055, 0.3), SKY, INK, 1.0)
			ci.draw_rect(Rect2(_at(a, 0.375, 0.72), Vector2(a.size.x * 0.11, a.size.y * 0.02)), SEA)
			_poly(ci, _pts(a, [Vector2(0.64, 0.24), Vector2(0.71, 0.26), Vector2(0.72, 0.72), Vector2(0.63, 0.72)]), CLIFF, INK, 1.5)
			ci.draw_rect(Rect2(_at(a, 0.64, 0.21), Vector2(a.size.x * 0.07, a.size.y * 0.035)), GRASS)
			_poly(ci, _pts(a, [Vector2(0.83, 0.66), Vector2(0.9, 0.65), Vector2(0.91, 0.72), Vector2(0.82, 0.72)]), CLIFF, INK, 1.5)
			for k in 8:
				var x := 0.05 + k * 0.12
				ci.draw_arc(_at(a, x, 0.84 + (k % 2) * 0.06), a.size.x * 0.02, PI * 1.1, PI * 1.9, 6, Color.WHITE, 2.0)
			anchors["crack"] = _at(a, 0.12, 0.5)
			anchors["cave"] = _at(a, 0.26, 0.66)
			anchors["arch"] = _at(a, 0.43, 0.5)
			anchors["stack"] = _at(a, 0.675, 0.4)
			anchors["stump"] = _at(a, 0.865, 0.68)
			anchors["wave-cut platform"] = _at(a, 0.76, 0.74)
			tops = ["crack", "arch", "stack"]
		"drift":
			ci.draw_rect(Rect2(a.position, Vector2(a.size.x, a.size.y * 0.3)), GRASS)
			ci.draw_rect(Rect2(_at(a, 0, 0.3), Vector2(a.size.x, a.size.y * 0.25)), SAND)
			ci.draw_rect(Rect2(_at(a, 0, 0.55), Vector2(a.size.x, a.size.y * 0.45)), SEA)
			for gx: float in [0.55, 0.8]:
				_poly(ci, _pts(a, [Vector2(gx - 0.16, 0.55), Vector2(gx, 0.55), Vector2(gx, 0.66)]), SAND, INK, 0.0)
				ci.draw_rect(Rect2(_at(a, gx, 0.28), Vector2(maxf(4.0, a.size.x * 0.01), a.size.y * 0.42)), WOOD.darkened(0.3))
			var zig: Array = []
			for k in 5:
				zig.append(_at(a, 0.06 + k * 0.09, 0.53))
				zig.append(_at(a, 0.105 + k * 0.09, 0.36))
			for k in range(zig.size() - 1):
				_arrow(ci, zig[k], zig[k + 1], Color("c0392b") if k % 2 == 0 else DEEP, 2.5)
			_arrow(ci, _at(a, 0.14, 0.95), _at(a, 0.3, 0.7), INK, 4.0)
			_arrow(ci, _at(a, 0.2, 0.25), _at(a, 0.45, 0.25), Color("7a5a2a"), 3.0)
			_say_from(ci, font, _at(a, 0.47, 0.25), "longshore drift", fs - 2, Color("5a4632"), false, false)
			anchors["swash"] = (zig[2] + zig[3]) * 0.5
			anchors["backwash"] = (zig[5] + zig[6]) * 0.5
			anchors["prevailing wind"] = _at(a, 0.22, 0.82)
			anchors["groyne"] = _at(a, 0.8, 0.4)
			anchors["beach"] = _at(a, 0.67, 0.42)
			tops = ["swash", "groyne", "beach"]
		"bays":
			ci.draw_rect(a, SEA)
			var bands: Array = [[0.0, 0.2, true], [0.2, 0.45, false], [0.45, 0.62, true], [0.62, 0.85, false], [0.85, 1.0, true]]
			for b: Array in bands:
				var x0 := float(b[0])
				var x1 := float(b[1])
				var hard := bool(b[2])
				if hard:
					_poly(ci, _pts(a, [Vector2(x0, 0), Vector2(x1, 0), Vector2(x1, 0.78), Vector2((x0 + x1) * 0.5, 0.84),
						Vector2(x0, 0.78)]), STONE, INK, 0.0)
				else:
					var shore: Array = [_at(a, x0, 0)]
					for k in 13:
						var t := k / 12.0
						shore.append(_at(a, x0 + (x1 - x0) * t, 0.46 + 0.32 * pow(absf(t - 0.5) * 2.0, 2.0)))
					shore.append(_at(a, x1, 0))
					_poly(ci, shore, Color("d9c79a"), INK, 0.0)
					var beach: Array = []
					for k in 13:
						var t := k / 12.0
						beach.append(_at(a, x0 + (x1 - x0) * t, 0.46 + 0.32 * pow(absf(t - 0.5) * 2.0, 2.0)))
					for k in range(12, -1, -1):
						var t := k / 12.0
						beach.append(_at(a, x0 + (x1 - x0) * t, 0.42 + 0.3 * pow(absf(t - 0.5) * 2.0, 2.0)))
					_poly(ci, beach, SAND, INK, 0.0)
			ci.draw_rect(Rect2(a.position, Vector2(a.size.x, a.size.y * 0.1)), GRASS)
			anchors["headland"] = _at(a, 0.535, 0.8)
			anchors["bay"] = _at(a, 0.32, 0.62)
			anchors["hard rock"] = _at(a, 0.1, 0.3)
			anchors["soft rock"] = _at(a, 0.74, 0.25)
			anchors["beach"] = _at(a, 0.33, 0.44)
			tops = ["hard rock", "soft rock", "beach"]
	if labels:
		_label_parts(ci, font, r, d, anchors, fs, tops)


# --- Nutrient cycles --------------------------------------------------------------------------------------------------

static func _draw_nutrients(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 14.0)
	var labels := bool(d.get("labels", false))
	var stores: Array = d.stores
	var flows: Array = d.get("flows", [3, 3, 3])
	var top := r.position.y + (fs * 1.4 if d.has("name") else 0.0)
	var h := r.end.y - top
	var big := minf(h * 0.22, r.size.x * 0.11)
	# Biomass at the top, litter at the bottom left, soil at the bottom right.
	var centres: Array[Vector2] = [Vector2(r.get_center().x, top + h * 0.3), Vector2(r.position.x + r.size.x * 0.3,
		top + h * 0.74), Vector2(r.position.x + r.size.x * 0.7, top + h * 0.74)]
	var mid := (centres[0] + centres[1] + centres[2]) / 3.0
	var colours: Array[Color] = [Color("5fae4a"), Color("c98f4a"), Color("7a5a3a")]
	var radii: Array[float] = []
	for i in 3:
		radii.append(big * (0.35 + 0.65 * (int(stores[i]) - 1) / 4.0))
	for i in 3:
		var a := centres[i]
		var b := centres[(i + 1) % 3]
		var dir := (b - a).normalized()
		var from := a + dir * (radii[i] + 4.0)
		var to := b - dir * (radii[(i + 1) % 3] + 4.0)
		var width := 1.5 + 2.0 * int(flows[i])
		_arrow(ci, from, to, Color("6b5b45"), width)
		if labels:   # each flow's name outside its arrow, away from the middle
			var half := (from + to) * 0.5
			var away := (half - mid).normalized()
			var text := NUTRIENT_FLOWS[i]
			var at := half + away * (width + fs * 0.9)
			if absf(away.x) > 0.5:
				_say_from(ci, font, at, text, fs - 1, Color("5a4632"), away.x < 0.0)
			else:
				_say(ci, font, at, text, fs - 1, Color("5a4632"))
	for i in 3:
		ci.draw_circle(centres[i], radii[i], colours[i])
		ci.draw_arc(centres[i], radii[i], 0.0, TAU, 32, INK, 2.0)
		var side := -1.0 if i < 2 else 1.0   # biomass and litter named on their left, soil on its right
		_say_from(ci, font, centres[i] + Vector2(side * (radii[i] + 6.0), 0.0), NUTRIENT_STORES[i], fs, INK, side < 0.0)
	if d.has("name"):
		_say_from(ci, font, Vector2(r.position.x + 2.0, r.position.y + fs * 0.7), str(d.name), fs, INK)


# --- A chain of steps -------------------------------------------------------------------------------------------------

static func _draw_chain(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 14.0)
	var steps: Array = d.steps
	var n := steps.size()
	var top := r.position.y
	if d.has("title"):
		_say_from(ci, font, Vector2(r.position.x + 2.0, top + fs * 0.7), str(d.title), _fit(font, str(d.title), fs, r.size.x - 4.0))
		top += fs * 1.5
	var loop := bool(d.get("loop", false))
	var rows := 1 if n <= 4 else 2
	var per := ceili(float(n) / rows)
	var gap := maxf(18.0, r.size.x * 0.04)
	var left := 16.0 if loop else 0.0   # room for the loop's way back
	var bw := (r.size.x - left - gap * (per - 1)) / per
	var room_y := r.end.y - top - (fs * 1.2 if loop else 0.0)
	var bh := minf(fs * 3.2, (room_y - gap * (rows - 1)) / rows)
	var total_h := bh * rows + gap * (rows - 1)
	var y0 := top + (room_y - total_h) * 0.5
	var boxes: Array[Rect2] = []
	for i in n:
		var row := i / per
		var col := i % per
		boxes.append(Rect2(r.position.x + left + col * (bw + gap), y0 + row * (bh + gap), bw, bh))
	for i in range(1, n):
		var a := boxes[i - 1]
		var b := boxes[i]
		if is_equal_approx(a.position.y, b.position.y):
			_arrow(ci, Vector2(a.end.x + 2.0, a.get_center().y), Vector2(b.position.x - 2.0, b.get_center().y), INK, 3.0)
		else:   # down to the next row's first step
			var midy := a.end.y + gap * 0.5
			ci.draw_polyline(PackedVector2Array([Vector2(a.get_center().x, a.end.y + 1.0), Vector2(a.get_center().x, midy),
				Vector2(b.get_center().x, midy)]), INK, 3.0)
			_arrow(ci, Vector2(b.get_center().x, midy), Vector2(b.get_center().x, b.position.y - 2.0), INK, 3.0)
	if loop:   # from the last step down, round the left edge and back into the first
		var last := boxes[n - 1]
		var first := boxes[0]
		var ly := last.end.y + fs * 0.9
		var lx := r.position.x + 6.0
		ci.draw_polyline(PackedVector2Array([Vector2(last.get_center().x, last.end.y + 1.0), Vector2(last.get_center().x, ly),
			Vector2(lx, ly), Vector2(lx, first.get_center().y)]), Color("2e8b3e"), 3.0)
		_arrow(ci, Vector2(lx, first.get_center().y), Vector2(first.position.x - 2.0, first.get_center().y), Color("2e8b3e"), 3.0)
	for i in n:
		var marked := d.has("mark") and int(d.mark) == i
		var hidden := d.has("hide") and int(d.hide) == i
		_box(ci, boxes[i], SOFT if marked or hidden else Color("fffaf0"), ORANGE if marked or hidden else INK, 8, 2)
		var text := "?" if hidden else str(steps[i])
		_text_in(ci, font, boxes[i], text, fs)


## Text in a box, on two lines when one is too wide.
static func _text_in(ci: CanvasItem, font: Font, box: Rect2, text: String, fs: int) -> void:
	var room := box.size.x - 8.0
	if _text_w(font, text, fs) <= room or not text.contains(" "):
		_say(ci, font, box.get_center(), text, _fit(font, text, fs, room), INK, false)
		return
	var cut := text.rfind(" ", text.length() / 2 + 2)
	if cut <= 0:
		cut = text.find(" ")
	var lines := [text.substr(0, cut), text.substr(cut + 1)]
	var f := mini(_fit(font, lines[0], fs, room), _fit(font, lines[1], fs, room))
	f = mini(f, int(box.size.y / 2.4))
	_say(ci, font, box.get_center() - Vector2(0, f * 0.6), lines[0], maxi(f, 8), INK, false)
	_say(ci, font, box.get_center() + Vector2(0, f * 0.6), lines[1], maxi(f, 8), INK, false)


# --- Break-even -------------------------------------------------------------------------------------------------------

static func _draw_break_even(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 15.0)
	var fixed := float(d.fixed)
	var cost := float(d.cost)
	var price := float(d.price)
	var most_items := int(d.max)
	var top_gold := maxf(price * most_items, fixed + cost * most_items)
	var y_step := _nice_step(top_gold / 5.0)
	top_gold = ceilf(top_gold / y_step) * y_step
	var x_step := _nice_step(most_items / 5.0)
	var left := _text_w(font, _gold(top_gold), fs - 2) + 10.0
	var plot := Rect2(r.position.x + left, r.position.y + fs * 1.5, r.size.x - left - 8.0, r.size.y - fs * 3.2)
	var at := func(items: float, gold: float) -> Vector2:
		return Vector2(plot.position.x + plot.size.x * items / most_items, plot.end.y - plot.size.y * gold / top_gold)
	var be := break_even_items(fixed, cost, price)
	# Loss before break-even, profit after: the gap between the lines shaded.
	ci.draw_colored_polygon(PackedVector2Array([at.call(0.0, 0.0), at.call(0.0, fixed), at.call(be, price * be)]),
		Color(0.85, 0.26, 0.23, 0.18))
	ci.draw_colored_polygon(PackedVector2Array([at.call(be, price * be), at.call(float(most_items), fixed + cost * most_items),
		at.call(float(most_items), price * most_items)]), Color(0.18, 0.55, 0.24, 0.2))
	var g := 0.0
	while g <= top_gold + 0.001:
		var y: float = at.call(0.0, g).y
		ci.draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), Color("e3dccb"), 1.0)
		_say_from(ci, font, Vector2(plot.position.x - 4.0, y), _gold(g), fs - 2, INK, true, false)
		g += y_step
	var it := 0.0
	while it <= most_items + 0.001:
		var x: float = at.call(it, 0.0).x
		ci.draw_line(Vector2(x, plot.end.y), Vector2(x, plot.end.y + 4.0), INK, 1.5)
		_say(ci, font, Vector2(x, plot.end.y + fs * 0.8), _gold(it), fs - 2, INK, false)
		it += x_step
	ci.draw_dashed_line(at.call(0.0, fixed), at.call(float(most_items), fixed), Color("8a8a8a"), 1.5, 6.0)
	ci.draw_line(at.call(0.0, fixed), at.call(float(most_items), fixed + cost * most_items), COSTS, 3.0, true)
	ci.draw_line(at.call(0.0, 0.0), at.call(float(most_items), price * most_items), TAKINGS, 3.0, true)
	ci.draw_line(Vector2(plot.position.x, plot.position.y), Vector2(plot.position.x, plot.end.y), INK, 2.0)
	ci.draw_line(Vector2(plot.position.x, plot.end.y), Vector2(plot.end.x, plot.end.y), INK, 2.0)
	_say_from(ci, font, Vector2(plot.end.x, plot.end.y + fs * 1.7), "items sold", fs - 1, INK, true, false)
	var kx := r.position.x + 4.0
	for e: Array in [["costs", COSTS], ["takings", TAKINGS], ["loss", Color(0.85, 0.26, 0.23, 0.5)], ["profit",
			Color(0.18, 0.55, 0.24, 0.55)]]:
		ci.draw_rect(Rect2(kx, r.position.y + fs * 0.25, fs * 0.9, fs * 0.9), e[1])
		_say_from(ci, font, Vector2(kx + fs * 1.1, r.position.y + fs * 0.7), str(e[0]), fs - 1, INK, false, false)
		kx += fs * 2.0 + _text_w(font, str(e[0]), fs - 1)
	if bool(d.get("point", false)) or bool(d.get("hide", false)):
		var p: Vector2 = at.call(be, price * be)
		ci.draw_dashed_line(p, Vector2(p.x, plot.end.y), INK, 1.5, 5.0)
		ci.draw_circle(p, 6.0, ORANGE)
		ci.draw_arc(p, 6.0, 0.0, TAU, 16, INK, 1.5)
		var hidden := bool(d.get("hide", false))
		var text := "break-even: %s" % ("?" if hidden else "%s items" % _gold(be))
		_say_from(ci, font, p + Vector2(-10.0, -fs * 0.9), text, fs - 1, ORANGE if hidden else INK, true)


static func _nice_step(raw: float) -> float:
	var p := pow(10.0, floorf(log(maxf(raw, 0.0001)) / log(10.0)))
	for m: float in [1.0, 2.0, 2.5, 5.0, 10.0]:
		if m * p >= raw - 0.000001:
			return m * p
	return 10.0 * p


## A number as the lessons write gold: 1,200, 4.5, 2.25.
static func _gold(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return GenKit.fmt(roundi(v))
	if is_equal_approx(v * 10.0, roundf(v * 10.0)):
		return "%.1f" % v
	return "%.2f" % v


# --- A chart with a cut axis ------------------------------------------------------------------------------------------

static func _draw_cut_bars(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 15.0)
	var top := r.position.y
	if d.has("title"):
		_say_from(ci, font, Vector2(r.position.x + 2.0, top + fs * 0.7), str(d.title), fs)
		top += fs * 1.5
	var area := Rect2(r.position.x, top, r.size.x, r.end.y - top)
	var full := bool(d.get("full", false))
	var from := float(d.from)
	var to := float(d.to)
	if not full:
		_bar_chart(ci, font, area, d.bars, from, to, float(d.step), fs, "")
		return
	var half := Rect2(area.position, Vector2(area.size.x * 0.49, area.size.y))
	_bar_chart(ci, font, half, d.bars, from, to, float(d.step), fs, "axis from %s" % _gold(from))
	var step0 := _nice_step(to / 5.0)
	_bar_chart(ci, font, Rect2(area.position + Vector2(area.size.x * 0.51, 0), half.size), d.bars, 0.0,
		ceilf(to / step0) * step0, step0, fs, "axis from 0")


static func _bar_chart(ci: CanvasItem, font: Font, r: Rect2, bars: Array, from: float, to: float, step: float, fs: int,
		caption: String) -> void:
	var left := _text_w(font, _gold(to), fs - 2) + 10.0
	var bottom := fs * 1.4 + (fs * 1.3 if caption != "" else 0.0)
	var plot := Rect2(r.position.x + left, r.position.y + fs * 1.1, r.size.x - left - 6.0, r.size.y - bottom - fs * 1.1)
	var y_of := func(v: float) -> float:
		return plot.end.y - plot.size.y * (v - from) / (to - from)
	var v := from
	while v <= to + 0.0001:
		var y: float = y_of.call(v)
		ci.draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), Color("e3dccb"), 1.0)
		_say_from(ci, font, Vector2(plot.position.x - 4.0, y), _gold(v), fs - 2, INK, true, false)
		v += step
	var slot := plot.size.x / bars.size()
	for i in bars.size():
		var val := float(bars[i][1])
		var x := plot.position.x + slot * (i + 0.5)
		var y: float = y_of.call(val)
		var bw := slot * 0.56
		ci.draw_rect(Rect2(x - bw * 0.5, y, bw, plot.end.y - y), BAR)
		ci.draw_rect(Rect2(x - bw * 0.5, y, bw, plot.end.y - y), INK, false, 1.5)
		_say(ci, font, Vector2(x, y - fs * 0.6), _gold(val), fs - 2, INK)
		_say(ci, font, Vector2(x, plot.end.y + fs * 0.75), str(bars[i][0]), _fit(font, str(bars[i][0]), fs - 1, slot - 2.0),
			INK, false)
	ci.draw_line(Vector2(plot.position.x, plot.position.y), Vector2(plot.position.x, plot.end.y), INK, 2.0)
	ci.draw_line(Vector2(plot.position.x, plot.end.y), Vector2(plot.end.x, plot.end.y), INK, 2.0)
	if from > 0.0:   # the axis's break: it does not start at 0
		var bx := plot.position.x
		var by := plot.end.y - 10.0
		ci.draw_rect(Rect2(bx - 6.0, by - 5.0, 12.0, 10.0), PAPER)
		ci.draw_line(Vector2(bx - 7.0, by - 1.0), Vector2(bx + 7.0, by - 6.0), RED, 2.0)
		ci.draw_line(Vector2(bx - 7.0, by + 5.0), Vector2(bx + 7.0, by), RED, 2.0)
	if caption != "":
		_say(ci, font, Vector2(r.get_center().x, r.end.y - fs * 0.6), caption, fs - 1, RED if from > 0.0 else INK, false)
