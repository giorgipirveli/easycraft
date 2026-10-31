class_name SchoolPictureG6Health
extends RefCounted
## Grade 6 health and PE, design and technology, and projects (owner #70, #73; research §6.6): the picture kinds they
## add, drawn from data onto a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only,
## no new art; the font has no arrows, so they are drawn). Kinds and fields:
## - lever_class {pivot, load, effort (0-10 along the bar, all different), tags?: {pivot?, load?, effort?} (12 letters
##   each), values?: {load?, effort?} (8 letters: "60 N", "?"), scale? (marks along the bar numbered by their distance
##   from the pivot), names? (true: the words pivot, load and effort, or their tags; false for labelling)}: a lever, its load a crate and its effort an arrow that pushes down when the load is across the
##   pivot and lifts up when it is on the same side (effort_up); its class is what sits in the middle (lever_kind).
## - linkage {type: LINKAGES ("reverse", "parallel", "bell_crank", "crank_slider"), move? ("left" | "right", the
##   default: the input rod's push), output? (true, the default: the output's arrow, by linkage_output), labels?
##   (input, output and a fixed pivot named)}: bars joined by pivots: fixed pivots dark, moving pivots open.
## - truss {panels (2-6), forces? (the top chord red: squashed; the bottom chord blue: stretched; a key), numbers?
##   (each triangle numbered, to count), load? (a load pressing down on the middle), mark? (TRUSS_PARTS, orange)}: a
##   Warren truss on two supports: 2p − 1 triangles, 4p − 1 bars, 2p + 1 joints (truss_counts).
## - struct_force {forces: [STRUCT_FORCES] (1-5, each once), names? (true), hide? (an index: its name "?"), mark? (an
##   index, orange)}: compression, tension, bending, torsion and shear, each a bar with its arrows.
## - biomimicry {pair: PAIRS, show? ("both", the default, "nature" or "design"), names? (true)}: something in nature
##   and the design that copies it: a burdock burr and hook-and-loop, a kingfisher's beak and a bullet train's nose,
##   honeycomb and a honeycomb panel, a lotus leaf and self-cleaning paint, a humpback whale's flipper and a bumpy
##   turbine blade, a termite mound and a building cooled by its chimneys.
## - material_swatch {samples: [MATERIALS] (1-4, each once), names? (true), hide? (an index), mark? (an index)}:
##   samples of woods, boards, metals, plastics and composites, each with its look (grain, shine, weave, stones).
## - design_style {style: STYLES ("arts_crafts", "bauhaus"), object: OBJECTS ("pattern", "chair", "lamp"), label? (the
##   style's name under it)}: a design in the style: leafy, handmade and decorated, or simple, geometric and made by
##   machine.
## - sensor_system {input: SENSORS, process? (16 letters, in the chip), output: OUTPUTS, headings? (true: INPUT,
##   PROCESS, OUTPUT), hide? ("input" | "process" | "output": shown "?")}: a systems diagram, three boxes and arrows.
## - threshold_graph {readings: [0-top] (3-10), labels: [text] (as many, 6 letters), threshold (0 < t < top), below?
##   (true, the default: the output is on below the threshold; false: above it), name? (24 letters), top? (10-1,000,
##   100), show_on? (the readings that switch the output on, orange)}: a sensor's readings as a line, the threshold a
##   dashed line (on_at).
## - breath_box {count? (2-8, 4), mark? (a side 0-3: breathe in, hold, breathe out, hold, in orange), words? (true)}:
##   box breathing round a square, clockwise from the top left.
## - control_rings {inside: [text] (1-4, 18 letters), outside: [text] (1-4), titles? (true)}: the circle of control:
##   what I can control inside the circle, what I cannot outside it.
## - food_thermo {value? (-25 to 100 whole °C: the thermometer's reading, and a pointer), mark? (ZONES, orange), hide?
##   (a zone's name "?"), labels? (true)}: a food thermometer lying down with its zones: the freezer (−18 °C or
##   colder), the fridge (0-5 °C), the danger zone (above 5 °C, below 63 °C), hot (63 °C and above) (zone_of).
## - microbe_split {steps (0-5), minutes? (10-60, 20: the time between splits), times? (true: each row's time)}: one
##   bacterium splitting in two, again and again: 1, 2, 4, 8 … a row for each split.
## - weather_kit {tools: [TOOLS] (1-4, each once), names? (true), hide? (an index), mark? (an index)}: a weather
##   station's instruments: a thermometer, a rain gauge, a wind vane, an anemometer and a barometer.
## - access_fm {mark? (0-7), hide? (0-7: its word "?"), words? (true)}: a specification's checklist ACCESS FM:
##   Aesthetics, Cost, Customer, Environment, Safety, Size, Function, Materials, in two rows.
## - talk_test {mark? (INTENSITIES), words? (true)}: how hard you are working, by how well you can talk: light (you can
##   sing), moderate (talk, but not sing), vigorous (only a few words), a heart beating harder along it.
## - fast_signs {mark? (0-3), hide? (0-3: its word "?"), words? (true)}: FAST, the signs of a stroke: Face (one side
##   drooping), Arms (one drifting down), Speech (muddled), Time to call 999.
## - track_field {view: VIEWS ("marks", "set": a sprinter in the blocks from the side; "relay": the takeover zone from
##   above; "long_jump": the runway, board and pit from the side; "triple_jump": the footprints from above), labels?,
##   marks?: [a, b] (long jump: two marks in the sand, metres from the take-off line, 1-9), measure? (long jump: the tape
##   to the nearest mark, jump_length), phases?: [hop, step, jump] (triple jump: metres, 1-7 each)}.

const KINDS: Array[String] = ["lever_class", "linkage", "truss", "struct_force", "biomimicry", "material_swatch",
	"design_style", "sensor_system", "threshold_graph", "breath_box", "control_rings", "food_thermo", "microbe_split",
	"weather_kit", "access_fm", "talk_test", "fast_signs", "track_field"]
const INK := Color("1f2a4a")    # SchoolUi.INK
const PAPER := Color("fdf6e3")  # SchoolUi.PAPER
const ORANGE := Color("f08a1c")
const RED := Color("d9433b")
const BLUE := Color("3a7be8")
const GREEN := Color("3fa34d")
const GREY := Color("9aa1ad")
const WOOD := Color("c98b4f")
const SAND := Color("ecd9a0")
const MAX_TAG := 12
const MAX_VALUE := 8

const LINKAGES: Array[String] = ["reverse", "parallel", "bell_crank", "crank_slider"]
const MOVES: Array[String] = ["left", "right"]
const TRUSS_PARTS: Array[String] = ["top", "bottom", "diagonal"]
const STRUCT_FORCES: Array[String] = ["compression", "tension", "bending", "torsion", "shear"]
const PAIRS: Array[String] = ["burr", "kingfisher", "honeycomb", "lotus", "whale_fin", "termite"]
const NATURE_NAMES := {"burr": "burdock burr", "kingfisher": "kingfisher's beak", "honeycomb": "honeycomb",
	"lotus": "lotus leaf", "whale_fin": "humpback's flipper", "termite": "termite mound"}
const DESIGN_NAMES := {"burr": "hook-and-loop", "kingfisher": "bullet train's nose", "honeycomb": "honeycomb panel",
	"lotus": "self-cleaning paint", "whale_fin": "bumpy turbine blade", "termite": "cooled building"}
const SHOWS: Array[String] = ["both", "nature", "design"]
const MATERIALS: Array[String] = ["oak", "pine", "plywood", "mdf", "steel", "aluminium", "copper", "brass", "acrylic",
	"polythene", "melamine", "carbon_fibre", "concrete"]
const MATERIAL_NAMES := {"oak": "oak", "pine": "pine", "plywood": "plywood", "mdf": "MDF", "steel": "steel",
	"aluminium": "aluminium", "copper": "copper", "brass": "brass", "acrylic": "acrylic", "polythene": "polythene",
	"melamine": "melamine", "carbon_fibre": "carbon fibre", "concrete": "concrete"}
const MAX_SAMPLES := 4
const STYLES: Array[String] = ["arts_crafts", "bauhaus"]
const STYLE_NAMES := {"arts_crafts": "Arts and Crafts", "bauhaus": "Bauhaus"}
const OBJECTS: Array[String] = ["pattern", "chair", "lamp"]
const SENSORS: Array[String] = ["light", "heat", "moisture", "sound", "motion", "push", "tilt", "magnet"]
const SENSOR_NAMES := {"light": "light sensor", "heat": "temperature sensor", "moisture": "moisture sensor",
	"sound": "sound sensor", "motion": "motion sensor", "push": "push switch", "tilt": "tilt switch",
	"magnet": "reed switch"}
const OUTPUTS: Array[String] = ["lamp", "led", "buzzer", "motor", "fan", "pump"]
const OUTPUT_NAMES := {"lamp": "lamp", "led": "LED", "buzzer": "buzzer", "motor": "motor", "fan": "fan",
	"pump": "water pump"}
const BOXES: Array[String] = ["input", "process", "output"]
const MAX_PROCESS := 16
const MAX_READINGS := 10
const MAX_READING_LABEL := 6
const MAX_NAME := 24
const MAX_RING := 18
const MAX_RING_WORDS := 4
const ZONES: Array[String] = ["freezer", "fridge", "danger", "hot"]
const ZONE_NAMES := {"freezer": "freezer", "fridge": "fridge", "danger": "danger zone", "hot": "hot"}
const ZONE_SPANS := {"freezer": [-25, -18], "fridge": [0, 5], "danger": [5, 63], "hot": [63, 100]}
const ZONE_COLORS := {"freezer": Color("5b9bd5"), "fridge": Color("9ccbe8"), "danger": Color("e8746a"),
	"hot": Color("f0a53c")}
const THERMO := Vector2i(-25, 100)
const MAX_SPLITS := 5
const TOOLS: Array[String] = ["thermometer", "rain_gauge", "wind_vane", "anemometer", "barometer"]
const TOOL_NAMES := {"thermometer": "thermometer", "rain_gauge": "rain gauge", "wind_vane": "wind vane",
	"anemometer": "anemometer", "barometer": "barometer"}
const ACCESS_FM: Array[String] = ["Aesthetics", "Cost", "Customer", "Environment", "Safety", "Size", "Function",
	"Materials"]
const INTENSITIES: Array[String] = ["light", "moderate", "vigorous"]
const TALK_WORDS := {"light": "you can sing", "moderate": "talk, not sing", "vigorous": "a few words"}
const FAST_WORDS: Array[String] = ["Face", "Arms", "Speech", "Time"]
const VIEWS: Array[String] = ["marks", "set", "relay", "long_jump", "triple_jump"]
const PIT_M := 10.0
## A sprinter in the blocks, from the side, facing right: x forwards, y up, in body heights; the start line at x 0.
## "r" is the near side (the front leg), "l" the far side (drawn paler); elbow e, hand h, knee k, foot f.
const SPRINT := {
	"marks": {"head": Vector2(0.06, 0.43), "neck": Vector2(-0.02, 0.40), "hip": Vector2(-0.30, 0.30),
		"re": Vector2(-0.02, 0.21), "rh": Vector2(-0.02, 0.02), "le": Vector2(0.0, 0.21), "lh": Vector2(0.0, 0.02),
		"rk": Vector2(-0.10, 0.18), "rf": Vector2(-0.28, 0.03), "lk": Vector2(-0.22, 0.03), "lf": Vector2(-0.47, 0.06)},
	"set": {"head": Vector2(0.08, 0.44), "neck": Vector2(0.0, 0.41), "hip": Vector2(-0.26, 0.46),
		"re": Vector2(-0.01, 0.21), "rh": Vector2(-0.02, 0.02), "le": Vector2(0.01, 0.21), "lh": Vector2(0.0, 0.02),
		"rk": Vector2(-0.17, 0.22), "rf": Vector2(-0.30, 0.03), "lk": Vector2(-0.29, 0.21), "lf": Vector2(-0.47, 0.06)},
}

# --- The rules the pictures draw by (the lessons teach them; tests check them) --------------------------------------

## A lever's class: 1 with the pivot in the middle (a seesaw), 2 with the load in the middle (a wheelbarrow), 3 with
## the effort in the middle (tweezers).
static func lever_kind(pivot: int, load: int, effort: int) -> int:
	var order := [pivot, load, effort]
	order.sort()
	if order[1] == pivot:
		return 1
	return 2 if order[1] == load else 3


## Whether the effort lifts up (the load on the same side of the pivot) rather than pushing down (across the pivot).
static func effort_up(pivot: int, load: int, effort: int) -> bool:
	return signi(load - pivot) == signi(effort - pivot)


## Which way a linkage's output moves when its input rod is pushed `move` ("left" or "right"): a reverse linkage turns
## it round, a parallel linkage keeps it, a bell crank turns it through a right angle (right -> down), and a crank and
## slider turns a wheel's turning into a slide back and forth.
static func linkage_output(type: String, move: String) -> String:
	match type:
		"reverse":
			return "left" if move == "right" else "right"
		"parallel":
			return move
		"bell_crank":
			return "down" if move == "right" else "up"
	return "back and forth"


## A Warren truss of `panels` panels along its bottom: its triangles, bars and joints.
static func truss_counts(panels: int) -> Dictionary:
	return {"triangles": 2 * panels - 1, "bars": 4 * panels - 1, "joints": 2 * panels + 1}


## The food thermometer's zone of `t` °C: "freezer" (−18 or colder), "fridge" (0-5), "danger" (above 5, below 63),
## "hot" (63 and above); "" between the freezer and the fridge.
static func zone_of(t: int) -> String:
	if t <= -18:
		return "freezer"
	if t >= 0 and t <= 5:
		return "fridge"
	if t > 5 and t < 63:
		return "danger"
	return "hot" if t >= 63 else ""


## A long jump's length: from the take-off line to the nearest mark in the sand.
static func jump_length(marks: Array) -> float:
	var out := INF
	for m: Variant in marks:
		out = minf(out, float(m))
	return out


## Whether a sensor's output is on at each reading: below the threshold (`below`), or above it.
static func on_at(readings: Array, threshold: float, below: bool) -> Array:
	var out: Array = []
	for v: Variant in readings:
		out.append(float(v) < threshold if below else float(v) > threshold)
	return out


## Where a label's part is drawn on a picture of `size` (for label exercises): a lever's "pivot", "load" and "effort"
## (or their tags), a sensor system's "input", "process" and "output" (or the sensor's and the output's names), a
## weather kit's instruments by name, a truss's "top chord", "bottom chord", "diagonal" and "support"; (-1, -1) when
## the picture has no such part.
static func part_at(p: Dictionary, label: String, size: Vector2) -> Vector2:
	var r := _rect(size)
	var none := Vector2(-1, -1)
	match str(p.get("kind", "")):
		"lever_class":
			var g := _lever_geo(p, r)
			var tags: Dictionary = p.get("tags", {})
			for part: String in ["pivot", "load", "effort"]:
				if label == part or label == str(tags.get(part, "")):
					return g[part]
		"sensor_system":
			var names := {"input": str(SENSOR_NAMES.get(str(p.get("input", "")), "")),
				"output": str(OUTPUT_NAMES.get(str(p.get("output", "")), ""))}
			for i in BOXES.size():
				if label == BOXES[i] or label == str(names.get(BOXES[i], "-")):
					return _sensor_boxes(r)[i].get_center()
		"weather_kit":
			var tools: Array = p.get("tools", [])
			for i in tools.size():
				if label == str(TOOL_NAMES.get(str(tools[i]), "")):
					return _tile(r, tools.size(), i, bool(p.get("names", true))).get_center()
		"truss":
			var g := _truss_geo(int(p.get("panels", 2)), r, bool(p.get("forces", false)))
			var bottom: Array = g.bottom
			var top: Array = g.top
			var mid := (bottom.size() - 1) / 2
			match label:
				"top chord":
					return (top[0] as Vector2).lerp(top[1], 0.5)
				"bottom chord":
					return (bottom[mid] as Vector2).lerp(bottom[mid + 1], 0.5)
				"diagonal":
					return (bottom[0] as Vector2).lerp(top[0], 0.5)
				"support":
					return (bottom[0] as Vector2) + Vector2(0, g.support * 0.5)
	return none


# --- Checks ------------------------------------------------------------------------------------------------------

## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	match str(p.get("kind", "")):
		"lever_class":
			for k: String in ["pivot", "load", "effort"]:
				if not _whole(p.get(k)) or int(p[k]) < 0 or int(p[k]) > 10:
					return "%s is 0-10 along the bar" % k
			if int(p.pivot) == int(p.load) or int(p.pivot) == int(p.effort) or int(p.load) == int(p.effort):
				return "the pivot, load and effort are in different places"
			for k: String in ["tags", "values"]:
				if not p.has(k):
					continue
				if not p[k] is Dictionary:
					return "%s is a dictionary" % k
				var allowed: Array = ["pivot", "load", "effort"] if k == "tags" else ["load", "effort"]
				for key: Variant in p[k]:
					if not allowed.has(str(key)):
						return "%s names %s" % [k, allowed]
					var n := str(p[k][key]).length()
					if n < 1 or n > (MAX_TAG if k == "tags" else MAX_VALUE):
						return "a %s is 1-%d letters" % [k.trim_suffix("s"), MAX_TAG if k == "tags" else MAX_VALUE]
			return _bool_problem(p, ["scale", "names"])
		"linkage":
			if not LINKAGES.has(str(p.get("type", ""))):
				return "a linkage's type is one of %s" % [LINKAGES]
			if p.has("move") and not MOVES.has(str(p.move)):
				return "move is left or right"
			return _bool_problem(p, ["output", "labels"])
		"truss":
			if not _whole(p.get("panels")) or int(p.panels) < 2 or int(p.panels) > 6:
				return "a truss has 2-6 panels"
			if p.has("mark") and not TRUSS_PARTS.has(str(p.mark)):
				return "mark is one of %s" % [TRUSS_PARTS]
			return _bool_problem(p, ["forces", "numbers", "load"])
		"struct_force":
			return _list_problem(p, "forces", STRUCT_FORCES, 5, ["names"])
		"biomimicry":
			if not PAIRS.has(str(p.get("pair", ""))):
				return "a pair is one of %s" % [PAIRS]
			if p.has("show") and not SHOWS.has(str(p.show)):
				return "show is both, nature or design"
			return _bool_problem(p, ["names"])
		"material_swatch":
			return _list_problem(p, "samples", MATERIALS, MAX_SAMPLES, ["names"])
		"design_style":
			if not STYLES.has(str(p.get("style", ""))) or not OBJECTS.has(str(p.get("object", ""))):
				return "a style of %s and an object of %s" % [STYLES, OBJECTS]
			return _bool_problem(p, ["label"])
		"sensor_system":
			if not SENSORS.has(str(p.get("input", ""))):
				return "an input is one of %s" % [SENSORS]
			if not OUTPUTS.has(str(p.get("output", ""))):
				return "an output is one of %s" % [OUTPUTS]
			if p.has("process") and (str(p.process).length() < 1 or str(p.process).length() > MAX_PROCESS):
				return "a process is 1-%d letters" % MAX_PROCESS
			if p.has("hide") and not BOXES.has(str(p.hide)):
				return "hide is input, process or output"
			return _bool_problem(p, ["headings"])
		"threshold_graph":
			var top := float(p.get("top", 100))
			if not _number(p.get("top", 100)) or top < 10 or top > 1000:
				return "top is 10-1,000"
			var readings: Variant = p.get("readings")
			var labels: Variant = p.get("labels")
			if not readings is Array or (readings as Array).size() < 3 or (readings as Array).size() > MAX_READINGS:
				return "3-%d readings" % MAX_READINGS
			if not labels is Array or (labels as Array).size() != (readings as Array).size():
				return "a label for each reading"
			for v: Variant in readings:
				if not _number(v) or float(v) < 0 or float(v) > top:
					return "a reading is 0-top"
			for l: Variant in labels:
				if str(l).length() < 1 or str(l).length() > MAX_READING_LABEL:
					return "a label is 1-%d letters" % MAX_READING_LABEL
			if not _number(p.get("threshold")) or float(p.threshold) <= 0 or float(p.threshold) >= top:
				return "a threshold is between 0 and top"
			if p.has("name") and (str(p.name).length() < 1 or str(p.name).length() > MAX_NAME):
				return "a name is 1-%d letters" % MAX_NAME
			return _bool_problem(p, ["below", "show_on"])
		"breath_box":
			if p.has("count") and (not _whole(p.count) or int(p.count) < 2 or int(p.count) > 8):
				return "count is 2-8"
			if p.has("mark") and (not _whole(p.mark) or int(p.mark) < 0 or int(p.mark) > 3):
				return "mark is a side 0-3"
			return _bool_problem(p, ["words"])
		"control_rings":
			for k: String in ["inside", "outside"]:
				var words: Variant = p.get(k)
				if not words is Array or (words as Array).is_empty() or (words as Array).size() > MAX_RING_WORDS:
					return "%s has 1-%d words" % [k, MAX_RING_WORDS]
				for w: Variant in words:
					if str(w).length() < 1 or str(w).length() > MAX_RING:
						return "a word is 1-%d letters" % MAX_RING
			return _bool_problem(p, ["titles"])
		"food_thermo":
			if p.has("value") and (not _whole(p.value) or int(p.value) < THERMO.x or int(p.value) > THERMO.y):
				return "value is %d to %d °C" % [THERMO.x, THERMO.y]
			for k: String in ["mark", "hide"]:
				if p.has(k) and not ZONES.has(str(p[k])):
					return "%s is one of %s" % [k, ZONES]
			return _bool_problem(p, ["labels"])
		"microbe_split":
			if not _whole(p.get("steps")) or int(p.steps) < 0 or int(p.steps) > MAX_SPLITS:
				return "steps is 0-%d" % MAX_SPLITS
			if p.has("minutes") and (not _whole(p.minutes) or int(p.minutes) < 10 or int(p.minutes) > 60):
				return "minutes is 10-60"
			return _bool_problem(p, ["times"])
		"weather_kit":
			return _list_problem(p, "tools", TOOLS, 4, ["names"])
		"access_fm":
			return _index_problem(p, 8, ["words"])
		"talk_test":
			if p.has("mark") and not INTENSITIES.has(str(p.mark)):
				return "mark is one of %s" % [INTENSITIES]
			return _bool_problem(p, ["words"])
		"fast_signs":
			return _index_problem(p, 4, ["words"])
		"track_field":
			var view := str(p.get("view", ""))
			if not VIEWS.has(view):
				return "a view is one of %s" % [VIEWS]
			if p.has("marks"):
				var marks: Variant = p.marks
				if view != "long_jump" or not marks is Array or (marks as Array).size() != 2:
					return "marks: two marks in a long jump's pit"
				for m: Variant in marks:
					if not _number(m) or float(m) < 1 or float(m) > 9:
						return "a mark is 1-9 m from the take-off line"
			if p.has("phases"):
				var phases: Variant = p.phases
				if view != "triple_jump" or not phases is Array or (phases as Array).size() != 3:
					return "phases: a triple jump's hop, step and jump"
				for m: Variant in phases:
					if not _number(m) or float(m) < 1 or float(m) > 7:
						return "a phase is 1-7 m"
			if p.has("measure") and (view != "long_jump" or not p.has("marks")):
				return "measure needs a long jump's marks"
			return _bool_problem(p, ["labels", "measure"])
	return ""


static func _list_problem(p: Dictionary, key: String, known: Array[String], most: int, bools: Array) -> String:
	var items: Variant = p.get(key)
	if not items is Array or (items as Array).is_empty() or (items as Array).size() > most:
		return "%s: 1-%d of %s" % [key, most, known]
	var seen := {}
	for it: Variant in items:
		if not known.has(str(it)) or seen.has(str(it)):
			return "%s: each one of %s, once" % [key, known]
		seen[str(it)] = true
	return _index_problem(p, (items as Array).size(), bools)


static func _index_problem(p: Dictionary, n: int, bools: Array) -> String:
	for k: String in ["mark", "hide"]:
		if p.has(k) and (not _whole(p[k]) or int(p[k]) < 0 or int(p[k]) >= n):
			return "%s is an index 0-%d" % [k, n - 1]
	return _bool_problem(p, bools)


static func _bool_problem(p: Dictionary, keys: Array) -> String:
	for k: String in keys:
		if p.has(k) and not p[k] is bool:
			return "%s is true or false" % k
	return ""


static func _number(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT]


static func _whole(v: Variant) -> bool:
	return _number(v) and float(v) == floorf(float(v))


# --- Drawing -------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"lever_class":
			_draw_lever(pic, font, r, d)
		"linkage":
			_draw_linkage(pic, font, r, d)
		"truss":
			_draw_truss(pic, font, r, d)
		"struct_force":
			_draw_struct_forces(pic, font, r, d)
		"biomimicry":
			_draw_biomimicry(pic, font, r, d)
		"material_swatch":
			_draw_swatches(pic, font, r, d)
		"design_style":
			_draw_style(pic, font, r, d)
		"sensor_system":
			_draw_sensor_system(pic, font, r, d)
		"threshold_graph":
			_draw_threshold(pic, font, r, d)
		"breath_box":
			_draw_breath_box(pic, font, r, d)
		"control_rings":
			_draw_rings(pic, font, r, d)
		"food_thermo":
			_draw_food_thermo(pic, font, r, d)
		"microbe_split":
			_draw_microbes(pic, font, r, d)
		"weather_kit":
			_draw_weather_kit(pic, font, r, d)
		"access_fm":
			_draw_access_fm(pic, font, r, d)
		"talk_test":
			_draw_talk_test(pic, font, r, d)
		"fast_signs":
			_draw_fast(pic, font, r, d)
		"track_field":
			_draw_track(pic, font, r, d)


## The drawing area of a SchoolPicture of `size` (its MARGIN all round).
static func _rect(size: Vector2) -> Rect2:
	return Rect2(Vector2(SchoolPicture.MARGIN, SchoolPicture.MARGIN), size - Vector2(2, 2) * SchoolPicture.MARGIN)


static func _fs(r: Rect2, k: float = 0.085, lo: int = 10, hi: int = 22) -> int:
	return clampi(int(r.size.y * k), lo, hi)


## Tile `i` of `n` side by side in `r` (the drawing, above its name when `names`).
static func _tile(r: Rect2, n: int, i: int, names: bool) -> Rect2:
	var w := r.size.x / n
	var fs := _fs(r)
	var h := r.size.y - (fs * 1.6 if names else 0.0)
	return Rect2(Vector2(r.position.x + w * i + w * 0.08, r.position.y + 2), Vector2(w * 0.84, h - 4))


## The name under tile `i` ("?" when hidden; orange when marked).
static func _tile_name(ci: CanvasItem, font: Font, r: Rect2, n: int, i: int, text: String, d: Dictionary) -> void:
	var fs := _fs(r)
	var w := r.size.x / n
	var hidden := d.has("hide") and int(d.hide) == i
	var col := ORANGE if d.has("mark") and int(d.mark) == i else INK
	var t := "?" if hidden else text
	var size := _fit(font, t, w * 0.96, fs)
	_text_col(ci, font, Vector2(r.position.x + w * (i + 0.5), r.end.y - fs * 0.35), t, size, col)


## The mark's orange frame round tile `i`.
static func _tile_mark(ci: CanvasItem, tile: Rect2, d: Dictionary, i: int) -> void:
	if d.has("mark") and int(d.mark) == i:
		ci.draw_rect(tile.grow(3), ORANGE, false, 4.0)


# --- lever_class ---------------------------------------------------------------------------------------------------

## Where a lever's parts are drawn in `r`: {pivot, load, effort (the parts' centres), left, span, beam_y, thick, tri,
## crate, fs, up}.
static func _lever_geo(d: Dictionary, r: Rect2) -> Dictionary:
	var fs := _fs(r, 0.085, 10, 20)
	var crate := minf(r.size.y * 0.22, r.size.x * 0.085)
	var left := r.position.x + maxf(r.size.x * 0.07, crate * 0.6)
	var span := r.size.x - 2.0 * (left - r.position.x)
	var tri := minf(r.size.y * 0.2, span * 0.08)
	var thick := maxf(6.0, r.size.y * 0.045)
	# centred up and down: the crate, its words and the effort's arrow above the bar, the pivot and its name below
	var spare := maxf(0.0, r.size.y - (crate + fs * 2.8 + thick) - (tri + fs * 1.5))
	var ground := r.end.y - fs * 1.5 - spare * 0.5
	var beam_y := ground - tri
	var pivot := int(d.get("pivot", 0))
	var load := int(d.get("load", 0))
	var effort := int(d.get("effort", 0))
	var at := func(v: int) -> float: return left + span * v / 10.0
	var up := effort_up(pivot, load, effort)
	var arrow := crate * 1.25
	return {"left": left, "span": span, "beam_y": beam_y, "thick": thick, "tri": tri, "crate": crate, "fs": fs,
		"ground": ground, "up": up, "arrow": arrow,
		"pivot": Vector2(at.call(pivot), beam_y + tri * 0.6),
		"load": Vector2(at.call(load), beam_y - thick * 0.5 - crate * 0.5),
		"effort": Vector2(at.call(effort), beam_y - thick * 0.5 - 3.0 - arrow * 0.5)}


static func _draw_lever(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var g := _lever_geo(d, r)
	var fs: int = g.fs
	var tags: Dictionary = d.get("tags", {})
	var values: Dictionary = d.get("values", {})
	var beam_y: float = g.beam_y
	var thick: float = g.thick
	var tri: float = g.tri
	var crate: float = g.crate
	var px: float = (g.pivot as Vector2).x
	ci.draw_line(Vector2(r.position.x, g.ground), Vector2(r.end.x, g.ground), GREY, 2.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(px, beam_y + thick * 0.5), Vector2(px + tri * 0.6, g.ground),
		Vector2(px - tri * 0.6, g.ground)]), Color("7b8494"))
	ci.draw_rect(Rect2(Vector2(g.left, beam_y - thick * 0.5), Vector2(g.span, thick)), WOOD.darkened(0.25))
	if bool(d.get("scale", false)):
		var sfs := maxi(8, int(fs * 0.7))
		for v in 11:
			var x: float = g.left + g.span * v / 10.0
			ci.draw_line(Vector2(x, beam_y - thick * 0.5), Vector2(x, beam_y + thick * 0.5), PAPER, 1.5)
			if v != int(d.pivot):
				_text_col(ci, font, Vector2(x, beam_y + thick * 0.5 + sfs * 1.05), str(absi(v - int(d.pivot))), sfs,
					Color(INK, 0.7))
	var lc: Vector2 = g.load
	var box := Rect2(lc - Vector2(crate, crate) * 0.5, Vector2(crate, crate))
	ci.draw_rect(box, Color("c98b4a"))
	ci.draw_rect(box, Color("7a4b22"), false, 2.0)
	ci.draw_line(box.position, box.end, Color("7a4b22"), 1.5)
	ci.draw_line(Vector2(box.end.x, box.position.y), Vector2(box.position.x, box.end.y), Color("7a4b22"), 1.5)
	var ec: Vector2 = g.effort
	var half: float = float(g.arrow) * 0.5
	var w := maxf(3.0, thick * 0.55)
	if bool(g.up):   # lifting: the arrow points up from the bar
		_arrow(ci, ec + Vector2(0, half), ec - Vector2(0, half), RED, w)
	else:
		_arrow(ci, ec - Vector2(0, half), ec + Vector2(0, half), RED, w)
	var names := bool(d.get("names", true))
	if names:
		_text(ci, font, Vector2(px, g.ground + fs * 1.15), str(tags.get("pivot", "pivot")), fs)
	var ltop := box.position.y - fs * 0.35
	if names:
		_text(ci, font, Vector2(lc.x, ltop), str(tags.get("load", "load")), fs)
	if values.has("load"):
		_text_col(ci, font, Vector2(lc.x, ltop - fs * 1.05), str(values.load), fs, BLUE)
	var etop := ec.y - half - fs * 0.35
	if names:
		_text(ci, font, Vector2(ec.x, etop), str(tags.get("effort", "effort")), fs)
	if values.has("effort"):
		_text_col(ci, font, Vector2(ec.x, etop - fs * 1.05), str(values.effort), fs, RED)


# --- linkage -------------------------------------------------------------------------------------------------------

static func _draw_linkage(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var type := str(d.type)
	var move := str(d.get("move", "right"))
	var labels := bool(d.get("labels", false))
	var show_out := bool(d.get("output", true))
	var fs := _fs(r, 0.08, 10, 20)
	var area := Rect2(r.position + Vector2(0, fs * 0.4), r.size - Vector2(0, fs * 0.8))
	var at := func(x: float, y: float) -> Vector2: return area.position + Vector2(x * area.size.x, y * area.size.y)
	var bar := maxf(5.0, area.size.y * 0.045)
	var pin := bar * 0.75
	var rod_col := Color("8e98a8")
	var link_col := Color("5b6b86")
	var arrow_w := maxf(3.0, bar * 0.6)
	var arrow_len := area.size.x * 0.1
	var dir_of := func(way: String) -> Vector2:
		return {"left": Vector2.LEFT, "right": Vector2.RIGHT, "up": Vector2.UP, "down": Vector2.DOWN}.get(way, Vector2.RIGHT)
	var out := linkage_output(type, move)
	var fixed: Array[Vector2] = []
	var moving: Array[Vector2] = []
	var in_at: Vector2
	var out_at: Vector2
	match type:
		"reverse", "parallel":
			var xs: Array = [0.5] if type == "reverse" else [0.34, 0.66]
			for x: float in xs:
				ci.draw_line(at.call(x, 0.18), at.call(x, 0.82), link_col, bar, true)
				fixed.append(at.call(x, 0.5))
				moving.append(at.call(x, 0.18))
				moving.append(at.call(x, 0.82))
			var first: float = xs[0]
			var last: float = xs[-1]
			ci.draw_line(at.call(0.06, 0.18), at.call(first, 0.18), rod_col, bar, true)
			if type == "reverse":
				ci.draw_line(at.call(last, 0.82), at.call(0.94, 0.82), rod_col, bar, true)
				out_at = at.call(0.94, 0.82)
			else:
				ci.draw_line(at.call(first, 0.82), at.call(last, 0.82), rod_col, bar, true)
				ci.draw_line(at.call(last, 0.18), at.call(0.94, 0.18), rod_col, bar, true)
				out_at = at.call(0.94, 0.18)
			in_at = at.call(0.06, 0.18)
		"bell_crank":
			var corner: Vector2 = at.call(0.46, 0.62)
			var arm_up: Vector2 = at.call(0.46, 0.16)
			var arm_right: Vector2 = at.call(0.78, 0.62)
			ci.draw_polyline(PackedVector2Array([arm_up, corner, arm_right]), link_col, bar, true)
			ci.draw_line(at.call(0.08, 0.16), arm_up, rod_col, bar, true)
			ci.draw_line(arm_right, at.call(0.78, 0.96), rod_col, bar, true)
			fixed.append(corner)
			moving.append(arm_up)
			moving.append(arm_right)
			in_at = at.call(0.08, 0.16)
			out_at = at.call(0.78, 0.96)
		"crank_slider":
			var c: Vector2 = at.call(0.24, 0.5)
			var rad := area.size.y * 0.3
			ci.draw_circle(c, rad, Color("dfe6ef"))
			ci.draw_arc(c, rad, 0, TAU, 40, link_col, maxf(2.0, bar * 0.5), true)
			var crank_pin := c + Vector2(cos(-0.9), sin(-0.9)) * rad * 0.7
			ci.draw_line(c, crank_pin, link_col, bar, true)
			var slider := Rect2(at.call(0.66, 0.5) - Vector2(area.size.x * 0.06, area.size.y * 0.1),
				Vector2(area.size.x * 0.12, area.size.y * 0.2))
			var guide := Rect2(Vector2(slider.position.x - area.size.x * 0.06, slider.position.y - 4),
				Vector2(area.size.x * 0.34, slider.size.y + 8))
			ci.draw_line(guide.position, Vector2(guide.end.x, guide.position.y), INK, 2.0)
			ci.draw_line(Vector2(guide.position.x, guide.end.y), guide.end, INK, 2.0)
			ci.draw_rect(slider, Color("c9d6ea"))
			ci.draw_rect(slider, link_col, false, 2.0)
			ci.draw_line(crank_pin, slider.get_center(), rod_col, bar, true)
			fixed.append(c)
			moving.append(crank_pin)
			moving.append(slider.get_center())
			_turn_arrow(ci, c, rad * 1.18, true, RED, arrow_w * 0.8)
			in_at = c + Vector2(0, -rad * 1.18)
			out_at = Vector2(slider.get_center().x, slider.end.y + area.size.y * 0.12)
			if show_out:
				var half := area.size.x * 0.07
				_arrow(ci, out_at, out_at + Vector2(half, 0), BLUE, arrow_w)
				_arrow(ci, out_at, out_at - Vector2(half, 0), BLUE, arrow_w)
	for f in fixed:   # a fixed pivot: a dark pin in a grey mount
		ci.draw_circle(f, pin * 1.9, Color("7b8494"))
		ci.draw_circle(f, pin * 1.1, INK)
	for m in moving:
		ci.draw_circle(m, pin, PAPER)
		ci.draw_arc(m, pin, 0, TAU, 16, INK, 2.0, true)
	if type != "crank_slider":
		var dv: Vector2 = dir_of.call(move)
		var a0 := in_at + Vector2(0, -bar * 2.2)
		_arrow(ci, a0 - dv * arrow_len * 0.5, a0 + dv * arrow_len * 0.5, RED, arrow_w)
		if show_out:
			var ov: Vector2 = dir_of.call(out)
			var o0 := out_at + (Vector2(0, bar * 2.2) if type != "bell_crank" else Vector2(bar * 2.6, -arrow_len * 0.6))
			_arrow(ci, o0 - ov * arrow_len * 0.5, o0 + ov * arrow_len * 0.5, BLUE, arrow_w)
	if labels:
		var sfs := maxi(9, int(fs * 0.9))
		_text_col(ci, font, in_at + Vector2(area.size.x * 0.06, -bar * 2.2 - sfs * 0.9), "input", sfs, RED)
		var out_label := out_at + Vector2(-area.size.x * 0.06, bar * 2.2 + sfs * 1.6)
		if type == "bell_crank":
			out_label = out_at + Vector2(-area.size.x * 0.09, -sfs * 0.2)
		elif type == "parallel":
			out_label = out_at + Vector2(-area.size.x * 0.06, -bar * 2.2 - sfs * 0.9)
		elif type == "crank_slider":
			out_label = out_at + Vector2(0, sfs * 1.6)
		if out_label.y > r.end.y:
			out_label.y = r.end.y
		_text_col(ci, font, out_label, "output", sfs, BLUE)
		var f0: Vector2 = fixed[0]
		var fx := f0 + Vector2(pin * 3.0, pin * 3.5 + sfs * 0.9)
		if type == "crank_slider":   # under the wheel
			fx = Vector2(f0.x - area.size.x * 0.08, minf(r.end.y, f0.y + area.size.y * 0.3 + sfs * 1.3))
		var tw := font.get_string_size("fixed pivot", HORIZONTAL_ALIGNMENT_LEFT, -1, sfs).x
		ci.draw_string(font, Vector2(minf(fx.x, r.end.x - tw), fx.y), "fixed pivot", HORIZONTAL_ALIGNMENT_LEFT, -1, sfs,
			INK)


static func _turn_arrow(ci: CanvasItem, c: Vector2, rad: float, cw: bool, col: Color, w: float) -> void:
	var a0 := -PI * 0.85
	var a1 := -PI * 0.25
	ci.draw_arc(c, rad, a0, a1, 16, col, w, true)
	var end_a := a1 if cw else a0
	var tip := c + Vector2(cos(end_a), sin(end_a)) * rad
	var tangent := Vector2(-sin(end_a), cos(end_a)) * (1.0 if cw else -1.0)
	_head(ci, tip + tangent * w, tangent, w * 3.2, col)


# --- truss ---------------------------------------------------------------------------------------------------------

## A Warren truss's joints in `r`: {bottom: [p + 1 points], top: [p points], support (its supports' height), fs}.
static func _truss_geo(panels: int, r: Rect2, key: bool) -> Dictionary:
	var fs := _fs(r, 0.08, 10, 20)
	var room := Rect2(r.position + Vector2(0, fs * 1.8), r.size - Vector2(0, fs * (1.8 + (2.4 if key else 0.4))))
	var support := minf(room.size.y * 0.16, 26.0)
	var panel := minf(room.size.x * 0.92 / panels, (room.size.y - support) / 0.9)
	var h := panel * 0.87
	var left := room.get_center().x - panel * panels * 0.5
	var base := room.position.y + (room.size.y - support + h) * 0.5
	var bottom: Array = []
	var top: Array = []
	for i in panels + 1:
		bottom.append(Vector2(left + panel * i, base))
	for i in panels:
		top.append(Vector2(left + panel * (i + 0.5), base - h))
	return {"bottom": bottom, "top": top, "support": support, "fs": fs, "panel": panel}


static func _draw_truss(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var panels := int(d.panels)
	var forces := bool(d.get("forces", false))
	var g := _truss_geo(panels, r, forces)
	var bottom: Array = g.bottom
	var top: Array = g.top
	var fs: int = g.fs
	var w := maxf(4.0, float(g.panel) * 0.07)
	var mark := str(d.get("mark", ""))
	var top_col := RED if forces else INK
	var bottom_col := BLUE if forces else INK
	var diag_col := Color("5b6b86")
	if mark == "top":
		top_col = ORANGE
	elif mark == "bottom":
		bottom_col = ORANGE
	elif mark == "diagonal":
		diag_col = ORANGE
	for i in panels:
		ci.draw_line(bottom[i], top[i], diag_col, w * 0.8, true)
		ci.draw_line(top[i], bottom[i + 1], diag_col, w * 0.8, true)
	for i in panels - 1:
		ci.draw_line(top[i], top[i + 1], top_col, w, true)
	for i in panels:
		ci.draw_line(bottom[i], bottom[i + 1], bottom_col, w, true)
	for p: Vector2 in bottom + top:
		ci.draw_circle(p, w * 0.75, INK)
	var s: float = g.support
	for p: Vector2 in [bottom[0], bottom[-1]]:
		ci.draw_colored_polygon(PackedVector2Array([p, p + Vector2(-s * 0.6, s), p + Vector2(s * 0.6, s)]), Color("7b8494"))
		ci.draw_line(p + Vector2(-s, s), p + Vector2(s, s), INK, 2.0)
	if bool(d.get("numbers", false)):
		var nfs := clampi(int(float(g.panel) * 0.28), 9, fs)
		var n := 1
		for i in panels:
			var up: Vector2 = ((bottom[i] as Vector2) + bottom[i + 1] + top[i]) / 3.0
			_text(ci, font, up + Vector2(0, nfs * 0.4), str(n), nfs)
			n += 1
			if i < panels - 1:
				var down: Vector2 = ((top[i] as Vector2) + top[i + 1] + bottom[i + 1]) / 3.0
				_text(ci, font, down + Vector2(0, nfs * 0.4), str(n), nfs)
				n += 1
	if bool(d.get("load", false)):
		var mid: Vector2 = ((bottom[0] as Vector2) + bottom[-1]) * 0.5
		var tip := Vector2(mid.x, (top[0] as Vector2).y - w * 1.5)
		_arrow(ci, tip - Vector2(0, fs * 1.7), tip, INK, w)
		ci.draw_string(font, tip + Vector2(w * 2.0, -fs * 1.0), "load", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	if forces:
		var ky := r.end.y - fs * 0.3
		var sfs := maxi(9, int(fs * 0.85))
		var t1 := "red: squashed (compression)"
		var t2 := "blue: stretched (tension)"
		ci.draw_string(font, Vector2(r.position.x, ky - sfs * 1.2), t1, HORIZONTAL_ALIGNMENT_LEFT, r.size.x, sfs, RED)
		ci.draw_string(font, Vector2(r.position.x, ky), t2, HORIZONTAL_ALIGNMENT_LEFT, r.size.x, sfs, BLUE)


# --- struct_force --------------------------------------------------------------------------------------------------

static func _draw_struct_forces(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var forces: Array = d.forces
	var names := bool(d.get("names", true))
	for i in forces.size():
		var t := _tile(r, forces.size(), i, names)
		_tile_mark(ci, t, d, i)
		_struct_force(ci, t, str(forces[i]))
		if names:
			_tile_name(ci, font, r, forces.size(), i, str(forces[i]), d)


static func _struct_force(ci: CanvasItem, t: Rect2, what: String) -> void:
	var c := t.get_center()
	var u := minf(t.size.x, t.size.y * 1.4)
	var w := maxf(3.0, u * 0.04)
	var steel := Color("a9b4c4")
	match what:
		"compression":   # a short, fat block squashed from both ends
			var b := Rect2(c - Vector2(u * 0.2, u * 0.16), Vector2(u * 0.4, u * 0.32))
			ci.draw_rect(b, steel)
			ci.draw_rect(b, INK, false, 2.0)
			_arrow(ci, Vector2(b.position.x - u * 0.28, c.y), Vector2(b.position.x - 2, c.y), RED, w)
			_arrow(ci, Vector2(b.end.x + u * 0.28, c.y), Vector2(b.end.x + 2, c.y), RED, w)
		"tension":   # a long, thin bar pulled from both ends
			var b := Rect2(c - Vector2(u * 0.26, u * 0.06), Vector2(u * 0.52, u * 0.12))
			ci.draw_rect(b, steel)
			ci.draw_rect(b, INK, false, 2.0)
			_arrow(ci, Vector2(b.position.x + 2, c.y), Vector2(b.position.x - u * 0.2, c.y), BLUE, w)
			_arrow(ci, Vector2(b.end.x - 2, c.y), Vector2(b.end.x + u * 0.2, c.y), BLUE, w)
		"bending":   # a beam on two supports, sagging under a load
			var pts := PackedVector2Array()
			for k in 13:
				var x := -0.4 + 0.8 * k / 12.0
				pts.append(c + Vector2(x * u, u * 0.1 * (1.0 - pow(x / 0.4, 2)) + u * 0.02))
			ci.draw_polyline(pts, INK, u * 0.08, true)
			for sx: float in [-0.4, 0.4]:
				var p := c + Vector2(sx * u, u * 0.08)
				ci.draw_colored_polygon(PackedVector2Array([p, p + Vector2(-u * 0.06, u * 0.12), p + Vector2(u * 0.06, u * 0.12)]),
					Color("7b8494"))
			_arrow(ci, c + Vector2(0, -u * 0.3), c + Vector2(0, u * 0.04), RED, w)
		"torsion":   # a rod twisted opposite ways at its ends
			var b := Rect2(c - Vector2(u * 0.36, u * 0.06), Vector2(u * 0.72, u * 0.12))
			ci.draw_rect(b, steel)
			ci.draw_rect(b, INK, false, 2.0)
			for k in 4:   # the twist lines
				var x := b.position.x + b.size.x * (k + 1) / 5.0
				ci.draw_line(Vector2(x - u * 0.03, b.position.y), Vector2(x + u * 0.03, b.end.y), INK, 1.2)
			for side: float in [-1.0, 1.0]:
				var e := c + Vector2(side * u * 0.36, 0)
				var rad := u * 0.14
				var from := -PI * 0.5 - 1.2
				var to := -PI * 0.5 + 1.2
				ci.draw_arc(e, rad, from, to, 12, ORANGE if side < 0 else RED, w, true)
				var end_a := to if side < 0 else from
				var tip := e + Vector2(cos(end_a), sin(end_a)) * rad
				var tg := Vector2(-sin(end_a), cos(end_a)) * (1.0 if side < 0 else -1.0)
				_head(ci, tip + tg * w, tg, w * 3.0, ORANGE if side < 0 else RED)
		"shear":   # two blocks pushed past each other
			var top := Rect2(c + Vector2(-u * 0.24, -u * 0.14), Vector2(u * 0.44, u * 0.14))
			var bot := Rect2(c + Vector2(-u * 0.2, 0), Vector2(u * 0.44, u * 0.14))
			for b: Rect2 in [top, bot]:
				ci.draw_rect(b, steel)
				ci.draw_rect(b, INK, false, 2.0)
			_arrow(ci, Vector2(top.position.x - u * 0.2, top.get_center().y), Vector2(top.position.x - 2, top.get_center().y), RED, w)
			_arrow(ci, Vector2(bot.end.x + u * 0.2, bot.get_center().y), Vector2(bot.end.x + 2, bot.get_center().y), RED, w)


# --- biomimicry ----------------------------------------------------------------------------------------------------

static func _draw_biomimicry(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var pair := str(d.pair)
	var show := str(d.get("show", "both"))
	var names := bool(d.get("names", true))
	var sides: Array[String] = []
	sides.append_array(["nature", "design"] if show == "both" else [show])
	var n := sides.size()
	for i in n:
		var t := _tile(r, n, i, names)
		if n == 2:   # room for the arrow between them
			t = t.grow_individual(0, 0, -t.size.x * 0.08, 0) if i == 0 else t.grow_individual(-t.size.x * 0.08, 0, 0, 0)
		var box := _square(t)
		if sides[i] == "nature":
			_nature(ci, box, pair)
		else:
			_design(ci, box, pair)
		if names:
			var text := str(NATURE_NAMES[pair]) if sides[i] == "nature" else str(DESIGN_NAMES[pair])
			_tile_name(ci, font, r, n, i, text, {})
	if n == 2:
		var mid := r.get_center() - Vector2(0, _fs(r) * 0.8 if names else 0.0)
		var len := r.size.x * 0.06
		_arrow(ci, mid - Vector2(len, 0), mid + Vector2(len, 0), ORANGE, maxf(3.0, r.size.y * 0.02))


## The biggest square in `t`, centred.
static func _square(t: Rect2) -> Rect2:
	var s := minf(t.size.x, t.size.y)
	return Rect2(t.get_center() - Vector2(s, s) * 0.5, Vector2(s, s))


static func _nature(ci: CanvasItem, b: Rect2, pair: String) -> void:
	var c := b.get_center()
	var s := b.size.x
	var w := maxf(1.5, s * 0.015)
	match pair:
		"burr":   # a round seed head covered in hooked spines
			var brown := Color("8a6a3a")
			for k in 20:
				var a := TAU * k / 20.0
				var dir := Vector2(cos(a), sin(a))
				var tip := c + dir * s * 0.42
				ci.draw_line(c + dir * s * 0.2, tip, brown, w * 1.2, true)
				var side := Vector2(-dir.y, dir.x)
				ci.draw_polyline(PackedVector2Array([tip, tip + side * s * 0.04, tip + side * s * 0.05 - dir * s * 0.04]),
					brown, w * 1.2, true)
			ci.draw_circle(c, s * 0.22, Color("a8864a"))
			ci.draw_arc(c, s * 0.22, 0, TAU, 24, brown, w, true)
		"kingfisher":   # a head with a long, pointed beak
			var head := c + Vector2(-s * 0.14, 0)
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(s * 0.1, -s * 0.07), c + Vector2(s * 0.46, s * 0.02),
				head + Vector2(s * 0.1, s * 0.06)]), Color("2b2b2b"))
			ci.draw_circle(head, s * 0.2, Color("2f8fd0"))
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-s * 0.1, s * 0.08), head + Vector2(s * 0.14, s * 0.04),
				head + Vector2(s * 0.02, s * 0.2), head + Vector2(-s * 0.16, s * 0.16)]), Color("f08a3c"))
			ci.draw_circle(head + Vector2(s * 0.06, -s * 0.05), s * 0.03, Color.WHITE)
			ci.draw_circle(head + Vector2(s * 0.065, -s * 0.05), s * 0.018, INK)
		"honeycomb":   # six-sided wax cells, some full of honey
			var rad := s * 0.11
			var k := 0
			for row in 4:
				for col in 4:
					var p := b.position + Vector2(s * 0.14 + col * rad * 1.73 + (rad * 0.87 if row % 2 == 1 else 0.0),
						s * 0.16 + row * rad * 1.5)
					var hexa := _hexagon(p, rad)
					ci.draw_colored_polygon(hexa, Color("f2b632") if (k * 7) % 3 == 0 else Color("fbe29a"))
					hexa.append(hexa[0])
					ci.draw_polyline(hexa, Color("b07a14"), w * 1.2, true)
					k += 1
		"lotus":   # a round leaf with water beads rolling off
			ci.draw_set_transform(c + Vector2(0, s * 0.08), 0, Vector2(1, 0.5))
			ci.draw_circle(Vector2.ZERO, s * 0.44, Color("5fae52"))
			ci.draw_arc(Vector2.ZERO, s * 0.44, 0, TAU, 32, Color("3a7a32"), w * 2, true)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			for q: Vector2 in [Vector2(-0.18, 0.02), Vector2(0.05, 0.1), Vector2(0.2, 0.0), Vector2(-0.02, -0.05)]:
				_drop(ci, c + q * s + Vector2(0, s * 0.04), s * 0.045)
		"whale_fin":   # a long flipper, its front edge lined with bumps (tubercles)
			var root := c + Vector2(-s * 0.42, -s * 0.02)
			var tip := c + Vector2(s * 0.44, s * 0.16)
			var along := tip - root
			var up := Vector2(along.y, -along.x).normalized()   # towards the front (leading) edge
			var width := func(t: float) -> float: return s * 0.13 * sin(PI * pow(t, 0.55)) + s * 0.01
			var poly := PackedVector2Array()
			for k in 21:
				var t := k / 20.0
				poly.append(root + along * t + up * float(width.call(t)) * 0.55)
			for k in range(20, -1, -1):
				var t := k / 20.0
				poly.append(root + along * t - up * float(width.call(t)) * 0.45)
			ci.draw_colored_polygon(poly, Color("6f7f94"))
			for k in 7:
				var t := 0.12 + k * 0.11
				var wv: float = width.call(t)
				ci.draw_circle(root + along * t + up * wv * 0.55, maxf(2.0, wv * 0.22), Color("6f7f94"))
			var belly := PackedVector2Array()
			for k in 21:
				var t := k / 20.0
				belly.append(root + along * t - up * float(width.call(t)) * 0.1)
			ci.draw_polyline(belly, Color("c9d1da"), maxf(1.5, s * 0.02), true)
		"termite":   # a tall mound with air flowing up through it
			var base := c + Vector2(0, s * 0.42)
			var poly := PackedVector2Array([base + Vector2(-s * 0.36, 0), base + Vector2(-s * 0.2, -s * 0.5),
				base + Vector2(-s * 0.1, -s * 0.78), base + Vector2(0, -s * 0.84), base + Vector2(s * 0.1, -s * 0.72),
				base + Vector2(s * 0.2, -s * 0.46), base + Vector2(s * 0.36, 0)])
			ci.draw_colored_polygon(poly, Color("c07a45"))
			ci.draw_line(base + Vector2(-s * 0.45, 0), base + Vector2(s * 0.45, 0), Color("7a4b22"), w * 2)
			_arrow(ci, base + Vector2(-s * 0.44, -s * 0.06), base + Vector2(-s * 0.2, -s * 0.06), BLUE, w * 2)
			_arrow(ci, base + Vector2(0, -s * 0.3), base + Vector2(0, -s * 0.9), RED, w * 2)


static func _design(ci: CanvasItem, b: Rect2, pair: String) -> void:
	var c := b.get_center()
	var s := b.size.x
	var w := maxf(1.5, s * 0.015)
	match pair:
		"burr":   # hook-and-loop: hooks on one strip catch loops on the other
			var top := Rect2(c + Vector2(-s * 0.42, -s * 0.3), Vector2(s * 0.84, s * 0.12))
			var bot := Rect2(c + Vector2(-s * 0.42, s * 0.18), Vector2(s * 0.84, s * 0.12))
			ci.draw_rect(top, Color("3f6fbf"))
			ci.draw_rect(bot, Color("3f6fbf").lightened(0.25))
			for k in 8:
				var x := top.position.x + s * 0.06 + k * s * 0.1
				ci.draw_polyline(PackedVector2Array([Vector2(x, top.end.y), Vector2(x, c.y + s * 0.02),
					Vector2(x + s * 0.03, c.y + s * 0.05), Vector2(x + s * 0.05, c.y + s * 0.01)]), INK, w * 1.2, true)
				ci.draw_arc(Vector2(x + s * 0.035, bot.position.y - s * 0.06), s * 0.045, PI * 0.9, TAU + PI * 0.1, 10,
					Color("2a3f6a"), w * 1.2, true)
		"kingfisher":   # a train with a long, pointed nose
			var body := Rect2(c + Vector2(-s * 0.46, -s * 0.12), Vector2(s * 0.5, s * 0.22))
			ci.draw_rect(body, Color("e8ecf2"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(body.end.x, body.position.y),
				Vector2(body.end.x + s * 0.4, body.end.y - s * 0.02), Vector2(body.end.x, body.end.y)]), Color("e8ecf2"))
			ci.draw_line(Vector2(body.position.x, body.position.y + s * 0.13), Vector2(body.end.x + s * 0.34,
				body.position.y + s * 0.19), Color("2f6fdc"), w * 3)
			for k in 4:
				ci.draw_rect(Rect2(body.position + Vector2(s * (0.04 + k * 0.11), s * 0.03), Vector2(s * 0.07, s * 0.06)),
					Color("5b6b86"))
			ci.draw_polyline(PackedVector2Array([Vector2(body.position.x, body.position.y), Vector2(body.end.x, body.position.y),
				Vector2(body.end.x + s * 0.4, body.end.y - s * 0.02), Vector2(body.position.x, body.end.y),
				Vector2(body.position.x, body.position.y)]), INK, w, true)
			ci.draw_line(Vector2(b.position.x, body.end.y + s * 0.05), Vector2(b.end.x, body.end.y + s * 0.05), INK, w * 2)
			for k in 3:
				ci.draw_circle(Vector2(body.position.x + s * (0.08 + k * 0.18), body.end.y + s * 0.02), s * 0.03, INK)
		"honeycomb":   # a light, strong panel: two skins with a honeycomb core between
			var skin := Color("b8c2cf")
			var top := Rect2(c + Vector2(-s * 0.44, -s * 0.24), Vector2(s * 0.88, s * 0.07))
			var bot := Rect2(c + Vector2(-s * 0.44, s * 0.17), Vector2(s * 0.88, s * 0.07))
			ci.draw_rect(Rect2(Vector2(top.position.x, top.end.y), Vector2(top.size.x, bot.position.y - top.end.y)),
				Color("eef1f5"))
			var rad := (bot.position.y - top.end.y) * 0.3
			for row in 2:
				for col in 7:
					var p := Vector2(top.position.x + rad + col * rad * 1.73 + (rad * 0.87 if row == 1 else 0.0),
						top.end.y + rad * 0.95 + row * rad * 1.5)
					if p.x + rad < top.end.x:
						var hexa := _hexagon(p, rad)
						hexa.append(hexa[0])
						ci.draw_polyline(hexa, Color("6b7a8f"), w, true)
			ci.draw_rect(top, skin)
			ci.draw_rect(bot, skin)
			ci.draw_rect(top, INK, false, w)
			ci.draw_rect(bot, INK, false, w)
		"lotus":   # a painted wall: rain beads and rolls off, taking the dirt with it
			var wall := Rect2(c + Vector2(-s * 0.36, -s * 0.4), Vector2(s * 0.72, s * 0.8))
			ci.draw_rect(wall, Color("f4efe4"))
			ci.draw_rect(wall, INK, false, w)
			for q: Vector2 in [Vector2(-0.2, -0.25), Vector2(0.05, -0.1), Vector2(0.22, -0.3), Vector2(-0.1, 0.1),
					Vector2(0.18, 0.15)]:
				var p := c + q * s
				ci.draw_line(p - Vector2(0, s * 0.12), p, Color(BLUE, 0.35), w * 2, true)
				_drop(ci, p, s * 0.04)
				ci.draw_circle(p + Vector2(s * 0.01, s * 0.015), s * 0.008, Color("7a5b3a"))
		"whale_fin":   # a wind turbine whose blades have bumps along their front edges
			var hub := c + Vector2(0, -s * 0.12)
			ci.draw_line(hub, c + Vector2(0, s * 0.46), GREY, s * 0.05)
			for k in 3:
				var a := -PI * 0.5 + TAU * k / 3.0
				var dir := Vector2(cos(a), sin(a))
				var side := Vector2(-dir.y, dir.x)
				var blade := PackedVector2Array([hub + side * s * 0.03, hub + dir * s * 0.34 + side * s * 0.01,
					hub + dir * s * 0.36, hub + dir * s * 0.3 - side * s * 0.04, hub - side * s * 0.04])
				ci.draw_colored_polygon(blade, Color("e8ecf2"))
				ci.draw_polyline(blade, INK, w, true)
				for j in 4:
					ci.draw_circle(hub + dir * s * (0.08 + j * 0.065) + side * s * 0.028, s * 0.014, Color("e8ecf2"))
					ci.draw_arc(hub + dir * s * (0.08 + j * 0.065) + side * s * 0.028, s * 0.014, 0, TAU, 8, INK, 1.0)
			ci.draw_circle(hub, s * 0.04, GREY)
		"termite":   # a building cooled like a mound: cool air in low, warm air out through chimneys
			var base := c + Vector2(0, s * 0.42)
			var block := Rect2(base + Vector2(-s * 0.36, -s * 0.56), Vector2(s * 0.72, s * 0.56))
			ci.draw_rect(block, Color("d8d2c6"))
			ci.draw_rect(block, INK, false, w)
			for x: float in [-0.24, 0.0, 0.24]:
				ci.draw_rect(Rect2(base + Vector2(x * s - s * 0.04, -s * 0.72), Vector2(s * 0.08, s * 0.16)), Color("a9a397"))
			for row in 3:
				for col in 4:
					ci.draw_rect(Rect2(block.position + Vector2(s * (0.06 + col * 0.17), s * (0.07 + row * 0.16)),
						Vector2(s * 0.09, s * 0.08)), Color("7fb6e8"))
			ci.draw_line(base + Vector2(-s * 0.46, 0), base + Vector2(s * 0.46, 0), INK, w * 2)
			_arrow(ci, base + Vector2(-s * 0.48, -s * 0.05), base + Vector2(-s * 0.34, -s * 0.05), BLUE, w * 2)
			for x: float in [-0.24, 0.24]:
				_arrow(ci, base + Vector2(x * s, -s * 0.74), base + Vector2(x * s, -s * 0.92), RED, w * 2)


static func _hexagon(c: Vector2, rad: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in 6:
		var a := PI / 6.0 + TAU * k / 6.0
		out.append(c + Vector2(cos(a), sin(a)) * rad)
	return out


static func _drop(ci: CanvasItem, c: Vector2, rad: float) -> void:
	ci.draw_circle(c, rad, Color("8cc8f0"))
	ci.draw_arc(c, rad, 0, TAU, 12, Color("3a7be8"), maxf(1.0, rad * 0.15), true)
	ci.draw_circle(c + Vector2(-rad * 0.35, -rad * 0.35), rad * 0.25, Color.WHITE)


# --- material_swatch -----------------------------------------------------------------------------------------------

static func _draw_swatches(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var samples: Array = d.samples
	var names := bool(d.get("names", true))
	for i in samples.size():
		var t := _square(_tile(r, samples.size(), i, names))
		t = t.grow(-t.size.x * 0.04)
		_swatch(ci, t, str(samples[i]))
		ci.draw_rect(t, INK, false, 1.5)
		_tile_mark(ci, t, d, i)
		if names:
			_tile_name(ci, font, r, samples.size(), i, str(MATERIAL_NAMES[str(samples[i])]), d)


static func _swatch(ci: CanvasItem, t: Rect2, m: String) -> void:
	var s := t.size.x
	var p := t.position
	var shine := func(base: Color) -> void:
		ci.draw_rect(t, base)
		for k in 6:   # soft diagonal highlight
			var a := 0.28 - absf(k - 2.5) * 0.08
			ci.draw_line(p + Vector2(s * (0.1 + k * 0.05), s), p + Vector2(s * (0.5 + k * 0.05), 0), Color(1, 1, 1, a),
				s * 0.05)
	match m:
		"oak", "pine":
			var base := Color("a8743f") if m == "oak" else Color("e8c98a")
			var grain := Color("6e4520") if m == "oak" else Color("b8844a")
			ci.draw_rect(t, base)
			for k in 7:
				var pts := PackedVector2Array()
				for j in 11:
					pts.append(p + Vector2(s * j / 10.0, s * (0.08 + k * 0.14) + sin(j * 0.9 + k) * s * 0.025))
				ci.draw_polyline(pts, grain, maxf(1.0, s * 0.012), true)
			if m == "pine":   # a knot
				ci.draw_set_transform(p + Vector2(s * 0.62, s * 0.55), 0.3, Vector2(1, 0.6))
				ci.draw_circle(Vector2.ZERO, s * 0.08, Color("8a5a2a"))
				ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			else:   # the oak's rays: little flecks
				for k in 6:
					ci.draw_line(p + Vector2(s * (0.1 + k * 0.15), s * (0.2 + (k % 3) * 0.25)),
						p + Vector2(s * (0.16 + k * 0.15), s * (0.2 + (k % 3) * 0.25)), Color("d9a86a"), maxf(1.5, s * 0.02))
		"plywood":   # a face veneer, and its edge of layers
			ci.draw_rect(Rect2(p, Vector2(s, s * 0.62)), Color("e2c28c"))
			for k in 5:
				ci.draw_rect(Rect2(p + Vector2(0, s * (0.62 + k * 0.076)), Vector2(s, s * 0.076)),
					Color("d4a864") if k % 2 == 0 else Color("a8743f"))
		"mdf":
			ci.draw_rect(t, Color("b89063"))
			for k in 40:
				var q := Vector2(fposmod(k * 37.0, 100.0), fposmod(k * 61.0, 100.0)) / 100.0
				ci.draw_circle(p + q * s, maxf(1.0, s * 0.01), Color("8e6a42"))
		"steel":
			shine.call(Color("8e98a4"))
			for k in 3:
				ci.draw_circle(p + Vector2(s * (0.2 + k * 0.27), s * (0.75 - k * 0.1)), s * 0.03, Color("a0522d"))
		"aluminium":
			shine.call(Color("c9d1da"))
		"copper":
			shine.call(Color("c26a3a"))
		"brass":
			shine.call(Color("c9a93b"))
		"acrylic":   # clear: see the paper through it, a bright edge
			ci.draw_rect(t, Color(0.75, 0.88, 0.98, 0.45))
			ci.draw_rect(t.grow(-s * 0.06), Color(1, 1, 1, 0.25), false, s * 0.04)
			ci.draw_line(p + Vector2(s * 0.15, s * 0.8), p + Vector2(s * 0.8, s * 0.15), Color(1, 1, 1, 0.8), s * 0.04)
		"polythene":   # milky, soft and crinkled
			ci.draw_rect(t, Color("eef0f0"))
			for k in 4:
				ci.draw_line(p + Vector2(s * (0.1 + k * 0.2), s * 0.1), p + Vector2(s * (0.2 + k * 0.2), s * 0.9),
					Color("d0d6d8"), maxf(1.0, s * 0.02), true)
		"melamine":   # a hard, glossy worktop surface
			ci.draw_rect(t, Color("f6f3ec"))
			for k in 30:
				var q := Vector2(fposmod(k * 29.0, 100.0), fposmod(k * 47.0, 100.0)) / 100.0
				ci.draw_circle(p + q * s, maxf(1.0, s * 0.012), Color("9aa1ad"))
			ci.draw_line(p + Vector2(s * 0.05, s * 0.3), p + Vector2(s * 0.3, s * 0.05), Color(1, 1, 1, 0.9), s * 0.05)
		"carbon_fibre":   # a dark twill weave
			ci.draw_rect(t, Color("2b2f36"))
			var n := 6
			for i in n:
				for j in n:
					if (i + j) % 2 == 0:
						ci.draw_rect(Rect2(p + Vector2(i, j) * s / n, Vector2(s / n, s / n * 0.5)), Color("4a505a"))
					else:
						ci.draw_rect(Rect2(p + Vector2(i, j) * s / n, Vector2(s / n * 0.5, s / n)), Color("40454e"))
		"concrete":   # grey, with stones and little holes
			ci.draw_rect(t, Color("b5b3ad"))
			for k in 18:
				var q := Vector2(fposmod(k * 43.0, 90.0) + 5, fposmod(k * 71.0, 90.0) + 5) / 100.0
				ci.draw_circle(p + q * s, s * (0.02 + fposmod(k * 13.0, 3.0) * 0.012),
					Color("8f8c85") if k % 3 else Color("d8d5ce"))


# --- design_style --------------------------------------------------------------------------------------------------

static func _draw_style(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var style := str(d.style)
	var label := bool(d.get("label", false))
	var fs := _fs(r)
	var area := Rect2(r.position, r.size - Vector2(0, fs * 1.6 if label else 0.0))
	match str(d.object):
		"pattern":
			var b := Rect2(area.position + Vector2(area.size.x * 0.1, 0), Vector2(area.size.x * 0.8, area.size.y))
			if style == "arts_crafts":
				_pattern_arts(ci, b)
			else:
				_pattern_bauhaus(ci, b)
			ci.draw_rect(b, INK, false, 2.0)
		"chair":
			if style == "arts_crafts":
				_chair_arts(ci, _square(area))
			else:
				_chair_bauhaus(ci, _square(area))
		"lamp":
			if style == "arts_crafts":
				_lamp_arts(ci, _square(area))
			else:
				_lamp_bauhaus(ci, _square(area))
	if label:
		_text(ci, font, Vector2(r.get_center().x, r.end.y - fs * 0.3), str(STYLE_NAMES[style]), fs)


## A leafy, handmade repeat: curling stems, leaves and flowers on a dark background.
static func _pattern_arts(ci: CanvasItem, b: Rect2) -> void:
	ci.draw_rect(b, Color("26375a"))
	var cell := minf(b.size.x / 4.0, b.size.y / 2.0)
	var cols := int(b.size.x / cell)
	var rows := int(b.size.y / cell)
	var off := b.position + (b.size - Vector2(cols, rows) * cell) * 0.5
	for i in cols:
		for j in rows:
			var c := off + Vector2(i + 0.5, j + 0.5) * cell
			var stem := PackedVector2Array()
			for k in 13:
				var t := k / 12.0
				stem.append(c + Vector2((t - 0.5) * cell * 0.9, sin(t * TAU) * cell * 0.18))
			ci.draw_polyline(stem, Color("7fa65a"), maxf(1.5, cell * 0.035), true)
			for k in 3:   # leaves along it
				var t := 0.2 + k * 0.3
				var p := c + Vector2((t - 0.5) * cell * 0.9, sin(t * TAU) * cell * 0.18)
				ci.draw_set_transform(p + Vector2(0, -cell * 0.08 if k % 2 == 0 else cell * 0.08), 0.6 if k % 2 == 0 else -0.6,
					Vector2(1, 0.45))
				ci.draw_circle(Vector2.ZERO, cell * 0.1, Color("5d8a45"))
				ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			var f := c + Vector2(0, -cell * 0.28)   # a flower
			for k in 5:
				var a := TAU * k / 5.0
				ci.draw_circle(f + Vector2(cos(a), sin(a)) * cell * 0.07, cell * 0.06, Color("c8503f"))
			ci.draw_circle(f, cell * 0.04, Color("f2c230"))


## Simple shapes in the primary colours, black lines and white space.
static func _pattern_bauhaus(ci: CanvasItem, b: Rect2) -> void:
	ci.draw_rect(b, Color("f7f5ef"))
	var u := minf(b.size.x, b.size.y)
	var c := b.get_center()
	ci.draw_rect(Rect2(b.position + Vector2(b.size.x * 0.08, b.size.y * 0.12), Vector2(u * 0.42, u * 0.42)), Color("2a52be"))
	ci.draw_circle(c + Vector2(b.size.x * 0.12, -b.size.y * 0.05), u * 0.26, Color("d9302c"))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-b.size.x * 0.1, b.size.y * 0.45),
		c + Vector2(b.size.x * 0.1, -b.size.y * 0.05), c + Vector2(b.size.x * 0.3, b.size.y * 0.45)]), Color("f2c230"))
	ci.draw_line(Vector2(b.position.x, c.y + b.size.y * 0.22), Vector2(b.end.x, c.y + b.size.y * 0.22), INK, u * 0.03)
	ci.draw_line(Vector2(b.position.x + b.size.x * 0.72, b.position.y), Vector2(b.position.x + b.size.x * 0.72, b.end.y),
		INK, u * 0.02)


## A wooden chair: tall back posts, a curved top rail with a heart cut out, spindles and a woven rush seat.
static func _chair_arts(ci: CanvasItem, b: Rect2) -> void:
	var s := b.size.x
	var p := b.position
	var oak := Color("8a5a2a")
	var w := s * 0.045
	var seat_y := s * 0.58
	for x: float in [0.28, 0.72]:
		ci.draw_line(p + Vector2(x * s, s * 0.08), p + Vector2(x * s, s * 0.98), oak, w, true)
	var rail := PackedVector2Array()
	for k in 11:
		var t := k / 10.0
		rail.append(p + Vector2(s * (0.28 + t * 0.44), s * (0.12 - sin(t * PI) * 0.04)))
	ci.draw_polyline(rail, oak, w * 1.6, true)
	var heart := p + Vector2(s * 0.5, s * 0.1)   # the carved heart
	ci.draw_circle(heart + Vector2(-s * 0.012, 0), s * 0.013, PAPER)
	ci.draw_circle(heart + Vector2(s * 0.012, 0), s * 0.013, PAPER)
	ci.draw_colored_polygon(PackedVector2Array([heart + Vector2(-s * 0.025, s * 0.003), heart + Vector2(s * 0.025, s * 0.003),
		heart + Vector2(0, s * 0.03)]), PAPER)
	for k in 4:
		var x := 0.36 + k * 0.093
		ci.draw_line(p + Vector2(x * s, s * 0.16), p + Vector2(x * s, seat_y), oak, w * 0.5, true)
	var seat := Rect2(p + Vector2(s * 0.24, seat_y), Vector2(s * 0.52, s * 0.08))
	ci.draw_rect(seat, Color("d9b26a"))
	for k in 12:
		ci.draw_line(seat.position + Vector2(seat.size.x * k / 12.0, 0), seat.position + Vector2(seat.size.x * (k + 0.8) / 12.0,
			seat.size.y), Color("b08a44"), 1.5)
	ci.draw_line(p + Vector2(s * 0.28, s * 0.84), p + Vector2(s * 0.72, s * 0.84), oak, w * 0.6)


## A tubular steel chair: one bent tube from the floor, up the front, along the seat and up the back; black straps.
static func _chair_bauhaus(ci: CanvasItem, b: Rect2) -> void:
	var s := b.size.x
	var p := b.position
	var steel := Color("7b8494")
	var w := s * 0.035
	var tube := PackedVector2Array([p + Vector2(s * 0.18, s * 0.94), p + Vector2(s * 0.8, s * 0.94),
		p + Vector2(s * 0.72, s * 0.58), p + Vector2(s * 0.3, s * 0.58), p + Vector2(s * 0.24, s * 0.12)])
	ci.draw_polyline(tube, steel, w, true)
	for q: Vector2 in [Vector2(0.8, 0.94), Vector2(0.72, 0.58), Vector2(0.3, 0.58)]:
		ci.draw_circle(p + q * s, w * 0.5, steel)
	ci.draw_line(p + Vector2(s * 0.34, s * 0.54), p + Vector2(s * 0.7, s * 0.54), INK, s * 0.07)
	ci.draw_line(p + Vector2(s * 0.27, s * 0.2), p + Vector2(s * 0.3, s * 0.44), INK, s * 0.07)


## A leafy lamp: a curved metal base, a stem with leaves, and a tulip of amber glass.
static func _lamp_arts(ci: CanvasItem, b: Rect2) -> void:
	var s := b.size.x
	var c := b.get_center()
	var copper := Color("b0623a")
	ci.draw_set_transform(c + Vector2(0, s * 0.42), 0, Vector2(1, 0.3))
	ci.draw_circle(Vector2.ZERO, s * 0.22, copper)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var stem := PackedVector2Array()
	for k in 9:
		var t := k / 8.0
		stem.append(c + Vector2(sin(t * PI * 2) * s * 0.03, s * (0.4 - t * 0.55)))
	ci.draw_polyline(stem, copper, s * 0.03, true)
	for k in 2:
		ci.draw_set_transform(c + Vector2(s * (0.06 if k == 0 else -0.06), s * (0.12 - k * 0.14)), 0.7 if k == 0 else -0.7,
			Vector2(1, 0.4))
		ci.draw_circle(Vector2.ZERO, s * 0.06, Color("6f8f4a"))
		ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var top := c + Vector2(0, -s * 0.16)
	var shade := PackedVector2Array([top, top + Vector2(-s * 0.2, -s * 0.06), top + Vector2(-s * 0.16, -s * 0.28),
		top + Vector2(-s * 0.06, -s * 0.2), top + Vector2(0, -s * 0.32), top + Vector2(s * 0.06, -s * 0.2),
		top + Vector2(s * 0.16, -s * 0.28), top + Vector2(s * 0.2, -s * 0.06)])
	ci.draw_colored_polygon(shade, Color("f0b44c"))
	shade.append(shade[0])
	ci.draw_polyline(shade, copper, 2.0, true)


## A lamp of plain shapes: a round glass base, a straight stem and a half-sphere shade.
static func _lamp_bauhaus(ci: CanvasItem, b: Rect2) -> void:
	var s := b.size.x
	var c := b.get_center()
	ci.draw_set_transform(c + Vector2(0, s * 0.42), 0, Vector2(1, 0.25))
	ci.draw_circle(Vector2.ZERO, s * 0.2, Color(0.8, 0.9, 0.95, 0.8))
	ci.draw_arc(Vector2.ZERO, s * 0.2, 0, TAU, 32, GREY, 3.0)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	ci.draw_line(c + Vector2(0, s * 0.4), c + Vector2(0, -s * 0.12), Color("9aa1ad"), s * 0.025)
	var dome := PackedVector2Array()
	for k in 17:
		var a := PI + PI * k / 16.0
		dome.append(c + Vector2(0, -s * 0.06) + Vector2(cos(a), sin(a)) * s * 0.26)
	ci.draw_colored_polygon(dome, Color("f7f5ef"))
	dome.append(dome[0])
	ci.draw_polyline(dome, GREY, 2.0, true)


# --- sensor_system -------------------------------------------------------------------------------------------------

static func _sensor_boxes(r: Rect2) -> Array[Rect2]:
	var fs := _fs(r)
	var top := r.position.y + fs * 1.5
	var h := r.size.y - fs * 1.5
	var w := r.size.x * 0.26
	var gap := (r.size.x - 3 * w) / 2.0
	var out: Array[Rect2] = []
	for i in 3:
		out.append(Rect2(Vector2(r.position.x + i * (w + gap), top), Vector2(w, h)))
	return out


static func _draw_sensor_system(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var boxes := _sensor_boxes(r)
	var fs := _fs(r)
	var hide := str(d.get("hide", ""))
	var cols: Array[Color] = [Color("d6ebd2"), Color("dfe6f5"), Color("f7e1c6")]
	for i in 3:
		var b := boxes[i]
		var style := StyleBoxFlat.new()
		style.bg_color = cols[i]
		style.set_corner_radius_all(int(minf(b.size.x, b.size.y) * 0.08))
		style.border_color = INK
		style.set_border_width_all(2)
		ci.draw_style_box(style, b)
		if bool(d.get("headings", true)):
			_text(ci, font, Vector2(b.get_center().x, r.position.y + fs * 1.05), BOXES[i].to_upper(), fs)
		var icon := Rect2(b.position + Vector2(b.size.x * 0.15, b.size.y * 0.06), Vector2(b.size.x * 0.7, b.size.y * 0.6))
		var name := ""
		if hide == BOXES[i]:
			_text_col(ci, font, icon.get_center() + Vector2(0, fs), "?", fs * 2, INK)
		else:
			match i:
				0:
					_sensor_icon(ci, _square(icon), str(d.input))
					name = str(SENSOR_NAMES[str(d.input)])
				1:
					_chip(ci, _square(icon))
					name = str(d.get("process", "microcontroller"))
				2:
					_output_icon(ci, _square(icon), str(d.output))
					name = str(OUTPUT_NAMES[str(d.output)])
		if name != "":
			var nfs := _fit(font, name, b.size.x * 0.94, fs)
			_text(ci, font, Vector2(b.get_center().x, b.end.y - b.size.y * 0.1), name, nfs)
		if i < 2:
			var a := Vector2(b.end.x + 3, b.get_center().y)
			var z := Vector2(boxes[i + 1].position.x - 3, b.get_center().y)
			_arrow(ci, a, z, INK, maxf(2.5, r.size.y * 0.018))


static func _sensor_icon(ci: CanvasItem, b: Rect2, what: String) -> void:
	var c := b.get_center()
	var s := b.size.x
	var w := maxf(1.5, s * 0.04)
	match what:
		"light":   # the sun
			ci.draw_circle(c, s * 0.2, Color("f2c230"))
			for k in 8:
				var a := TAU * k / 8.0
				ci.draw_line(c + Vector2(cos(a), sin(a)) * s * 0.28, c + Vector2(cos(a), sin(a)) * s * 0.42, Color("e0a020"), w)
		"heat":   # a thermometer
			ci.draw_rect(Rect2(c + Vector2(-s * 0.07, -s * 0.42), Vector2(s * 0.14, s * 0.62)), Color.WHITE)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.07, -s * 0.42), Vector2(s * 0.14, s * 0.62)), INK, false, w * 0.6)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.035, -s * 0.1), Vector2(s * 0.07, s * 0.32)), RED)
			ci.draw_circle(c + Vector2(0, s * 0.28), s * 0.13, RED)
		"moisture":   # a drop of water over soil
			var drop := PackedVector2Array([c + Vector2(0, -s * 0.4)])
			for k in 13:
				var a := -PI * 0.15 + PI * 1.3 * k / 12.0
				drop.append(c + Vector2(0, s * 0.08) + Vector2(cos(a), sin(a)) * s * 0.22)
			ci.draw_colored_polygon(drop, Color("5b9bd5"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.4, s * 0.34), Vector2(s * 0.8, s * 0.1)), Color("8a5a36"))
		"sound":   # a speaker and sound waves
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.36, -s * 0.1), c + Vector2(-s * 0.2, -s * 0.1),
				c + Vector2(-s * 0.02, -s * 0.28), c + Vector2(-s * 0.02, s * 0.28), c + Vector2(-s * 0.2, s * 0.1),
				c + Vector2(-s * 0.36, s * 0.1)]), INK)
			for k in 3:
				ci.draw_arc(c + Vector2(-s * 0.02, 0), s * (0.14 + k * 0.1), -0.8, 0.8, 10, INK, w, true)
		"motion":   # a dome that sees warm, moving bodies
			ci.draw_arc(c + Vector2(0, s * 0.1), s * 0.22, PI, TAU, 16, INK, w, true)
			ci.draw_colored_polygon(_half_disc(c + Vector2(0, s * 0.1), s * 0.22), Color("f3f0e8"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.3, s * 0.1), Vector2(s * 0.6, s * 0.12)), GREY)
			for k in 3:
				ci.draw_arc(c + Vector2(0, s * 0.1), s * (0.3 + k * 0.07), PI * 1.2, PI * 1.8, 10, Color(RED, 0.7), w * 0.7, true)
		"push":   # a push button
			ci.draw_rect(Rect2(c + Vector2(-s * 0.32, s * 0.05), Vector2(s * 0.64, s * 0.24)), GREY)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.14, -s * 0.12), Vector2(s * 0.28, s * 0.18)), RED)
			_arrow(ci, c + Vector2(0, -s * 0.45), c + Vector2(0, -s * 0.16), INK, w)
		"tilt":   # a tube, tilted, with a ball inside
			ci.draw_set_transform(c, -0.4, Vector2.ONE)
			ci.draw_rect(Rect2(Vector2(-s * 0.36, -s * 0.1), Vector2(s * 0.72, s * 0.2)), Color("e8ecf2"))
			ci.draw_rect(Rect2(Vector2(-s * 0.36, -s * 0.1), Vector2(s * 0.72, s * 0.2)), INK, false, w * 0.7)
			ci.draw_circle(Vector2(s * 0.24, 0), s * 0.08, GREY.darkened(0.3))
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"magnet":   # a horseshoe magnet
			ci.draw_arc(c + Vector2(0, -s * 0.05), s * 0.24, PI, TAU, 16, RED, s * 0.14, true)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.31, -s * 0.05), Vector2(s * 0.14, s * 0.3)), RED)
			ci.draw_rect(Rect2(c + Vector2(s * 0.17, -s * 0.05), Vector2(s * 0.14, s * 0.3)), RED)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.31, s * 0.17), Vector2(s * 0.14, s * 0.08)), Color("e8ecf2"))
			ci.draw_rect(Rect2(c + Vector2(s * 0.17, s * 0.17), Vector2(s * 0.14, s * 0.08)), Color("e8ecf2"))


static func _half_disc(c: Vector2, rad: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in 13:
		var a := PI + PI * k / 12.0
		out.append(c + Vector2(cos(a), sin(a)) * rad)
	return out


## A microcontroller: a chip with legs.
static func _chip(ci: CanvasItem, b: Rect2) -> void:
	var c := b.get_center()
	var s := b.size.x
	var body := Rect2(c - Vector2(s * 0.3, s * 0.22), Vector2(s * 0.6, s * 0.44))
	for k in 5:
		var x := body.position.x + body.size.x * (k + 0.5) / 5.0
		ci.draw_line(Vector2(x, body.position.y - s * 0.1), Vector2(x, body.end.y + s * 0.1), GREY, maxf(2.0, s * 0.04))
	ci.draw_rect(body, Color("2b2f36"))
	ci.draw_circle(body.position + Vector2(s * 0.07, s * 0.07), s * 0.03, GREY)


static func _output_icon(ci: CanvasItem, b: Rect2, what: String) -> void:
	var c := b.get_center()
	var s := b.size.x
	var w := maxf(1.5, s * 0.04)
	match what:
		"lamp":
			ci.draw_circle(c + Vector2(0, -s * 0.08), s * 0.24, Color("fde58a"))
			ci.draw_arc(c + Vector2(0, -s * 0.08), s * 0.24, 0, TAU, 20, INK, w * 0.7, true)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.1, s * 0.16), Vector2(s * 0.2, s * 0.16)), GREY)
		"led":
			ci.draw_colored_polygon(_half_disc(c + Vector2(0, -s * 0.04), s * 0.16), RED)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.16, -s * 0.04), Vector2(s * 0.32, s * 0.16)), RED)
			ci.draw_line(c + Vector2(-s * 0.07, s * 0.12), c + Vector2(-s * 0.07, s * 0.42), GREY, w)
			ci.draw_line(c + Vector2(s * 0.07, s * 0.12), c + Vector2(s * 0.07, s * 0.36), GREY, w)
		"buzzer":
			ci.draw_circle(c + Vector2(-s * 0.08, 0), s * 0.2, INK)
			ci.draw_circle(c + Vector2(-s * 0.08, 0), s * 0.05, GREY)
			for k in 2:
				ci.draw_arc(c + Vector2(-s * 0.08, 0), s * (0.3 + k * 0.1), -0.7, 0.7, 10, INK, w, true)
		"motor":
			ci.draw_circle(c, s * 0.26, Color("c9d6ea"))
			ci.draw_arc(c, s * 0.26, 0, TAU, 24, INK, w, true)
			ci.draw_line(c + Vector2(s * 0.26, 0), c + Vector2(s * 0.44, 0), INK, w * 1.5)
			_turn_arrow(ci, c, s * 0.34, true, BLUE, w)
		"fan":
			for k in 3:
				var a := TAU * k / 3.0
				ci.draw_set_transform(c + Vector2(cos(a), sin(a)) * s * 0.16, a, Vector2(1, 0.45))
				ci.draw_circle(Vector2.ZERO, s * 0.16, Color("5b9bd5"))
				ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			ci.draw_circle(c, s * 0.06, INK)
		"pump":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.3, -s * 0.12), Vector2(s * 0.36, s * 0.3)), GREY)
			ci.draw_line(c + Vector2(s * 0.06, -s * 0.02), c + Vector2(s * 0.34, -s * 0.02), GREY.darkened(0.2), w * 2)
			_drop(ci, c + Vector2(s * 0.36, s * 0.16), s * 0.07)


# --- threshold_graph -----------------------------------------------------------------------------------------------

static func _draw_threshold(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var readings: Array = d.readings
	var labels: Array = d.labels
	var top := float(d.get("top", 100))
	var th := float(d.threshold)
	var below := bool(d.get("below", true))
	var fs := _fs(r, 0.075, 9, 18)
	var name := str(d.get("name", ""))
	var plot := Rect2(r.position + Vector2(fs * 2.6, fs * (2.0 if name != "" else 0.6)),
		r.size - Vector2(fs * 3.0, fs * (3.4 if name != "" else 2.0)))
	if name != "":
		ci.draw_string(font, r.position + Vector2(0, fs * 0.9), name, HORIZONTAL_ALIGNMENT_LEFT, r.size.x, fs, INK)
	var y_of := func(v: float) -> float: return plot.end.y - plot.size.y * v / top
	for k in 6:
		var v := top * k / 5.0
		var y: float = y_of.call(v)
		ci.draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), Color(INK, 0.15), 1.0)
		var t := str(int(v)) if v == floorf(v) else "%.1f" % v
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ci.draw_string(font, Vector2(plot.position.x - tw - 4, y + fs * 0.35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	ci.draw_line(plot.position, Vector2(plot.position.x, plot.end.y), INK, 2.0)
	ci.draw_line(Vector2(plot.position.x, plot.end.y), plot.end, INK, 2.0)
	var n := readings.size()
	var step := plot.size.x / n
	var pts := PackedVector2Array()
	for i in n:
		pts.append(Vector2(plot.position.x + step * (i + 0.5), y_of.call(float(readings[i]))))
		var lab := str(labels[i])
		_text(ci, font, Vector2(pts[i].x, plot.end.y + fs * 1.1), lab, _fit(font, lab, step * 0.98, fs))
	var ty: float = y_of.call(th)
	var x := plot.position.x
	while x < plot.end.x:   # the threshold, dashed
		ci.draw_line(Vector2(x, ty), Vector2(minf(x + 10, plot.end.x), ty), ORANGE, 2.5)
		x += 16
	ci.draw_polyline(pts, BLUE, 3.0, true)
	var on := on_at(readings, th, below)
	var show_on := bool(d.get("show_on", false))
	for i in n:
		ci.draw_circle(pts[i], 5.0, ORANGE if show_on and bool(on[i]) else BLUE)
	var tt := "threshold %s" % (str(int(th)) if th == floorf(th) else str(th))
	var tfs := maxi(9, int(fs * 0.85))
	var tw := font.get_string_size(tt, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs).x
	ci.draw_string(font, Vector2(plot.end.x - tw, ty - 4), tt, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs, ORANGE.darkened(0.2))


# --- breath_box ----------------------------------------------------------------------------------------------------

static func _draw_breath_box(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var n := int(d.get("count", 4))
	var words := bool(d.get("words", true))
	var fs := _fs(r, 0.08, 10, 20)
	var side := minf(r.size.y - fs * 3.2, r.size.x * 0.5)
	var c := r.get_center()
	var sq := Rect2(c - Vector2(side, side) * 0.5, Vector2(side, side))
	var corners: Array[Vector2] = [sq.position, Vector2(sq.end.x, sq.position.y), sq.end, Vector2(sq.position.x, sq.end.y)]
	var texts: Array[String] = ["breathe in %d" % n, "hold %d" % n, "breathe out %d" % n, "hold %d" % n]
	var w := maxf(4.0, side * 0.035)
	ci.draw_rect(sq, Color("e8f2fb"))
	for i in 4:
		var a := corners[i]
		var b := corners[(i + 1) % 4]
		var col := ORANGE if d.has("mark") and int(d.mark) == i else BLUE
		ci.draw_line(a, b, col, w, true)
		_head(ci, a.lerp(b, 0.6), (b - a).normalized(), w * 3.0, col)
		if words:
			var mid := a.lerp(b, 0.5)
			var tcol := ORANGE.darkened(0.15) if d.has("mark") and int(d.mark) == i else INK
			match i:
				0:
					_text_col(ci, font, mid + Vector2(0, -fs * 0.5), texts[i], fs, tcol)
				2:
					_text_col(ci, font, mid + Vector2(0, fs * 1.25), texts[i], fs, tcol)
				1:
					ci.draw_string(font, mid + Vector2(fs * 1.0, fs * 0.35), texts[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tcol)
				3:
					var tw := font.get_string_size(texts[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
					ci.draw_string(font, mid + Vector2(-fs * 1.0 - tw, fs * 0.35), texts[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
						tcol)
	ci.draw_circle(corners[0], w * 1.6, GREEN)
	# a calm face in the middle
	var fr := side * 0.16
	ci.draw_circle(c, fr, Color("fde8b0"))
	ci.draw_arc(c, fr, 0, TAU, 20, INK, 2.0, true)
	for sx: float in [-0.35, 0.35]:
		ci.draw_arc(c + Vector2(sx * fr, -fr * 0.15), fr * 0.16, PI * 0.1, PI * 0.9, 6, INK, 1.5, true)
	ci.draw_arc(c + Vector2(0, fr * 0.2), fr * 0.35, PI * 0.15, PI * 0.85, 8, INK, 1.5, true)


# --- control_rings -------------------------------------------------------------------------------------------------

static func _draw_rings(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var inside: Array = d.inside
	var outside: Array = d.outside
	var titles := bool(d.get("titles", true))
	var fs := _fs(r, 0.075, 9, 18)
	var c := r.get_center() + Vector2(0, fs * 0.4 if titles else 0.0)
	var rad := minf(r.size.y * 0.46 - (fs * 0.4 if titles else 0.0), r.size.x * 0.22)
	ci.draw_rect(Rect2(r.position, r.size), Color("f3e6e1"))
	ci.draw_circle(c, rad, Color("d6ebd2"))
	ci.draw_arc(c, rad, 0, TAU, 40, GREEN.darkened(0.2), 3.0, true)
	if titles:
		_text_col(ci, font, Vector2(c.x, c.y - rad * 0.55), "I can control", fs, GREEN.darkened(0.35))
		ci.draw_string(font, r.position + Vector2(4, fs * 1.1), "I cannot control", HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			RED.darkened(0.2))
	var ifs := _fit_all(font, inside, rad * 1.7, fs)
	var y0 := c.y - (inside.size() - 1) * ifs * 0.6 + (ifs * 0.5 if titles else ifs * 0.35)
	for i in inside.size():
		_text(ci, font, Vector2(c.x, y0 + i * ifs * 1.2), str(inside[i]), ifs)
	var col_w := (r.size.x - rad * 2) * 0.5 - 8
	var ofs := _fit_all(font, outside, col_w, fs)
	for i in outside.size():
		var left := i % 2 == 0
		var row := i / 2
		var y := c.y - rad * 0.2 + row * ofs * 2.2
		var cx := (r.position.x + c.x - rad) * 0.5 if left else (c.x + rad + r.end.x) * 0.5
		_text(ci, font, Vector2(cx, y), str(outside[i]), ofs)


# --- food_thermo ---------------------------------------------------------------------------------------------------

static func _draw_food_thermo(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var labels := bool(d.get("labels", true))
	var fs := _fs(r, 0.08, 9, 20)
	var sfs := maxi(8, int(fs * 0.85))
	var bulb := minf(r.size.y * 0.13, 26.0)
	var left := r.position.x + bulb * 2.2
	var right := r.end.x - fs * 1.2
	var tube_h := bulb * 0.9
	# from the top: two rows of names, the zones' band, the tube, its ticks and numbers (centred up and down)
	var height := (fs * 2.6 if labels else 0.0) + bulb * 1.3 + bulb * 0.3 + tube_h + bulb * 0.4 + sfs * 1.8
	var top := r.position.y + maxf(0.0, (r.size.y - height) * 0.5)
	var band := Rect2(Vector2(left, top + (fs * 2.6 if labels else 0.0)), Vector2(right - left, bulb * 1.3))
	var tube_y := band.end.y + bulb * 0.3 + tube_h * 0.5
	var x_of := func(t: float) -> float: return left + (right - left) * (t - THERMO.x) / float(THERMO.y - THERMO.x)
	# the zones as coloured bands above the tube, their names above them
	for z: String in ZONES:
		var span: Array = ZONE_SPANS[z]
		var a: float = x_of.call(float(span[0]))
		var b: float = x_of.call(float(span[1]))
		var zr := Rect2(Vector2(a, band.position.y), Vector2(b - a, band.size.y))
		ci.draw_rect(zr, ZONE_COLORS[z])
		if str(d.get("mark", "")) == z:
			ci.draw_rect(zr.grow(2), ORANGE, false, 4.0)
		if labels:
			var t := "?" if str(d.get("hide", "")) == z else str(ZONE_NAMES[z])
			var y := band.position.y - fs * (1.35 if z == "freezer" else 0.35)   # the two narrow zones on two rows
			_text_col(ci, font, Vector2(zr.get_center().x, y), t, fs, ORANGE.darkened(0.2) if str(d.get("mark", "")) == z else INK)
	# the tube and its scale
	var tube := Rect2(Vector2(left - bulb * 0.4, tube_y - tube_h * 0.5), Vector2(right - left + bulb * 0.8, tube_h))
	ci.draw_rect(tube, Color.WHITE)
	var bc := Vector2(left - bulb * 0.9, tube_y)
	if d.has("value"):
		var vx: float = x_of.call(float(d.value))
		ci.draw_rect(Rect2(Vector2(bc.x, tube_y - tube_h * 0.25), Vector2(vx - bc.x, tube_h * 0.5)), RED)
		var tip := Vector2(vx, tube.end.y + 2)
		ci.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-bulb * 0.4, bulb * 0.6), tip + Vector2(bulb * 0.4,
			bulb * 0.6)]), ORANGE)
	ci.draw_rect(tube, INK, false, 2.0)
	ci.draw_circle(bc, bulb, RED)
	ci.draw_arc(bc, bulb, 0, TAU, 20, INK, 2.0, true)
	var every := 10 if (right - left) / 12.5 >= 30.0 else 20
	var ny := tube.end.y + bulb * 0.4 + sfs * 1.3
	for t in range(-20, 101, every):
		var x: float = x_of.call(float(t))
		ci.draw_line(Vector2(x, tube.end.y), Vector2(x, tube.end.y + bulb * 0.35), INK, 1.5)
		var s := ("−%d" % -t) if t < 0 else str(t)
		_text(ci, font, Vector2(x, ny), s, sfs)
	_text(ci, font, Vector2(bc.x, ny), "°C", sfs)


# --- microbe_split -------------------------------------------------------------------------------------------------

static func _draw_microbes(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var steps := int(d.steps)
	var minutes := int(d.get("minutes", 20))
	var times := bool(d.get("times", true))
	var fs := _fs(r, 0.075, 9, 18)
	var rows := steps + 1
	var rh := r.size.y / rows
	var label_w := fs * 4.2 if times else 0.0
	var room := r.size.x - label_w
	for i in rows:
		var y := r.position.y + rh * (i + 0.5)
		if times:
			ci.draw_string(font, Vector2(r.position.x, y + fs * 0.35), "%d min" % (i * minutes), HORIZONTAL_ALIGNMENT_LEFT,
				-1, fs, INK)
		var n := int(pow(2, i))
		var cell := minf(room / 32.0 * 1.0, rh * 0.8) if n > 16 else minf(room / maxf(n, 8.0), rh * 0.8)
		var w := cell * 0.8
		for k in n:
			var x := r.position.x + label_w + cell * (k + 0.5)
			var body := Rect2(Vector2(x - w * 0.5, y - w * 0.22), Vector2(w, w * 0.44))
			var style := StyleBoxFlat.new()
			style.bg_color = Color("7cc46a")
			style.set_corner_radius_all(int(w * 0.22))
			ci.draw_style_box(style, body)


# --- weather_kit ---------------------------------------------------------------------------------------------------

static func _draw_weather_kit(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var tools: Array = d.tools
	var names := bool(d.get("names", true))
	for i in tools.size():
		var t := _tile(r, tools.size(), i, names)
		_tile_mark(ci, t, d, i)
		_tool(ci, _square(t), str(tools[i]))
		if names:
			_tile_name(ci, font, r, tools.size(), i, str(TOOL_NAMES[str(tools[i])]), d)


static func _tool(ci: CanvasItem, b: Rect2, what: String) -> void:
	var c := b.get_center()
	var s := b.size.x
	var w := maxf(1.5, s * 0.03)
	var ground := c.y + s * 0.44
	if what != "barometer":   # a barometer lives indoors
		ci.draw_line(Vector2(c.x - s * 0.45, ground), Vector2(c.x + s * 0.45, ground), Color("6fa84f"), w * 2)
	match what:
		"thermometer":
			var tube := Rect2(c + Vector2(-s * 0.06, -s * 0.42), Vector2(s * 0.12, s * 0.66))
			ci.draw_rect(tube, Color.WHITE)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.025, -s * 0.12), Vector2(s * 0.05, s * 0.4)), RED)
			ci.draw_rect(tube, INK, false, w * 0.7)
			ci.draw_circle(c + Vector2(0, s * 0.3), s * 0.1, RED)
			for k in 6:
				var y := c.y - s * 0.36 + k * s * 0.1
				ci.draw_line(Vector2(c.x + s * 0.06, y), Vector2(c.x + s * 0.12, y), INK, 1.2)
		"rain_gauge":
			var cyl := Rect2(c + Vector2(-s * 0.12, -s * 0.2), Vector2(s * 0.24, s * 0.64))
			ci.draw_rect(Rect2(Vector2(cyl.position.x, cyl.end.y - s * 0.24), Vector2(cyl.size.x, s * 0.24)), Color("8cc8f0"))
			ci.draw_rect(cyl, INK, false, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.26, -s * 0.36), c + Vector2(s * 0.26, -s * 0.36),
				c + Vector2(s * 0.12, -s * 0.2), c + Vector2(-s * 0.12, -s * 0.2)]), Color("c9d1da"))
			for k in 5:
				var y := cyl.end.y - (k + 1) * s * 0.1
				ci.draw_line(Vector2(cyl.position.x, y), Vector2(cyl.position.x + s * 0.08, y), INK, 1.2)
		"wind_vane":
			var pole_top := c + Vector2(0, -s * 0.2)
			ci.draw_line(Vector2(c.x, ground), pole_top, GREY.darkened(0.3), w * 1.5)
			ci.draw_line(pole_top + Vector2(-s * 0.36, 0), pole_top + Vector2(s * 0.18, 0), INK, w * 1.5)
			ci.draw_colored_polygon(PackedVector2Array([pole_top + Vector2(-s * 0.44, 0), pole_top + Vector2(-s * 0.3, -s * 0.07),
				pole_top + Vector2(-s * 0.3, s * 0.07)]), INK)
			ci.draw_colored_polygon(PackedVector2Array([pole_top + Vector2(s * 0.12, 0), pole_top + Vector2(s * 0.3, -s * 0.13),
				pole_top + Vector2(s * 0.3, s * 0.13)]), RED)
			ci.draw_line(c + Vector2(-s * 0.2, s * 0.12), c + Vector2(s * 0.2, s * 0.12), INK, w)
			ci.draw_line(c + Vector2(0, s * 0.02), c + Vector2(0, s * 0.22), INK, w)
		"anemometer":
			var hub := c + Vector2(0, -s * 0.18)
			ci.draw_line(Vector2(c.x, ground), hub, GREY.darkened(0.3), w * 1.5)
			for k in 3:
				var a := -PI * 0.5 + TAU * k / 3.0 + 0.3
				var dir := Vector2(cos(a), sin(a) * 0.4)
				var cup := hub + dir * s * 0.36
				ci.draw_line(hub, cup, INK, w)
				ci.draw_colored_polygon(_half_disc(cup, s * 0.08), Color("5b6b86"))
			_turn_arrow(ci, hub, s * 0.46, true, BLUE, w * 1.2)
		"barometer":
			var dc := c + Vector2(0, -s * 0.04)
			var rad := s * 0.36
			ci.draw_circle(dc, rad, Color("f7f1e1"))
			ci.draw_arc(dc, rad, 0, TAU, 32, Color("8a5a36"), w * 2.5, true)
			for k in 11:
				var a := PI * 0.75 + PI * 1.5 * k / 10.0
				ci.draw_line(dc + Vector2(cos(a), sin(a)) * rad * 0.78, dc + Vector2(cos(a), sin(a)) * rad * 0.9, INK, 1.2)
			ci.draw_line(dc, dc + Vector2(cos(PI * 1.6), sin(PI * 1.6)) * rad * 0.7, RED, w * 1.2)
			ci.draw_circle(dc, w * 1.5, INK)


# --- access_fm -----------------------------------------------------------------------------------------------------

static func _draw_access_fm(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var words := bool(d.get("words", true))
	var cw := r.size.x / 4.0
	var ch := r.size.y / 2.0
	var cols: Array[Color] = [Color("f7d9c4"), Color("f3e7b8"), Color("d6ebd2"), Color("cfe3f7")]
	for i in 8:
		var cell := Rect2(r.position + Vector2(i % 4 * cw, i / 4 * ch), Vector2(cw, ch)).grow(-3)
		var style := StyleBoxFlat.new()
		style.bg_color = cols[i % 4]
		style.set_corner_radius_all(int(minf(cw, ch) * 0.1))
		if d.has("mark") and int(d.mark) == i:
			style.border_color = ORANGE
			style.set_border_width_all(4)
		ci.draw_style_box(style, cell)
		var word := str(ACCESS_FM[i])
		var big := clampi(int(ch * (0.5 if words else 0.7)), 10, 56)
		_text(ci, font, Vector2(cell.get_center().x, cell.position.y + cell.size.y * (0.52 if words else 0.72)), word[0], big)
		if words:
			var t := "?" if d.has("hide") and int(d.hide) == i else word
			var fs := _fit(font, t, cell.size.x * 0.92, clampi(int(ch * 0.2), 8, 20))
			_text(ci, font, Vector2(cell.get_center().x, cell.end.y - cell.size.y * 0.12), t, fs)


# --- talk_test -----------------------------------------------------------------------------------------------------

static func _draw_talk_test(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var words := bool(d.get("words", true))
	var fs := _fs(r, 0.085, 9, 20)
	var bar_h := r.size.y * (0.22 if words else 0.4)
	var bar_y := r.position.y + r.size.y * (0.42 if words else 0.3)
	var seg := r.size.x / 3.0
	var cols: Array[Color] = [Color("7cc46a"), Color("f2c230"), Color("e8746a")]
	for i in 3:
		var b := Rect2(Vector2(r.position.x + seg * i, bar_y), Vector2(seg, bar_h))
		ci.draw_rect(b, cols[i])
		var heart := b.get_center()
		_heart(ci, heart, bar_h * (0.22 + i * 0.1))
		if str(d.get("mark", "")) == INTENSITIES[i]:
			ci.draw_rect(b.grow(-2), ORANGE, false, 5.0)
		if words:
			_text(ci, font, Vector2(b.get_center().x, bar_y - fs * 0.5), INTENSITIES[i], fs)
			var t := str(TALK_WORDS[INTENSITIES[i]])
			_text(ci, font, Vector2(b.get_center().x, b.end.y + fs * 1.3), t, _fit(font, t, seg * 0.95, fs))
	ci.draw_rect(Rect2(Vector2(r.position.x, bar_y), Vector2(r.size.x, bar_h)), INK, false, 2.0)


static func _heart(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_circle(c + Vector2(-s * 0.5, -s * 0.2), s * 0.55, RED.darkened(0.2))
	ci.draw_circle(c + Vector2(s * 0.5, -s * 0.2), s * 0.55, RED.darkened(0.2))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 1.02, -s * 0.05), c + Vector2(s * 1.02, -s * 0.05),
		c + Vector2(0, s * 1.05)]), RED.darkened(0.2))


# --- fast_signs ----------------------------------------------------------------------------------------------------

static func _draw_fast(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var words := bool(d.get("words", true))
	for i in 4:
		var t := _tile(r, 4, i, words)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("e7eef8")
		style.set_corner_radius_all(int(t.size.x * 0.08))
		ci.draw_style_box(style, t)
		_tile_mark(ci, t, d, i)
		var lf := clampi(int(t.size.y * 0.24), 10, 40)
		_text_col(ci, font, Vector2(t.get_center().x, t.position.y + lf * 1.0), FAST_WORDS[i][0], lf, RED)
		var pic := Rect2(t.position + Vector2(0, lf * 1.15), Vector2(t.size.x, t.size.y - lf * 1.2))
		_fast_icon(ci, _square(pic), i, font)
		if words:
			_tile_name(ci, font, r, 4, i, FAST_WORDS[i], d)


static func _fast_icon(ci: CanvasItem, b: Rect2, i: int, font: Font) -> void:
	var c := b.get_center()
	var s := b.size.x
	var w := maxf(1.5, s * 0.04)
	match i:
		0:   # a face drooping on one side
			ci.draw_circle(c, s * 0.4, Color("fde3c8"))
			ci.draw_arc(c, s * 0.4, 0, TAU, 24, INK, w, true)
			ci.draw_circle(c + Vector2(-s * 0.15, -s * 0.1), s * 0.04, INK)
			ci.draw_circle(c + Vector2(s * 0.15, -s * 0.03), s * 0.04, INK)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.2, s * 0.12), c + Vector2(0, s * 0.16),
				c + Vector2(s * 0.18, s * 0.26)]), INK, w, true)
		1:   # two arms up, one drifting down
			ci.draw_circle(c + Vector2(0, -s * 0.28), s * 0.1, INK)
			ci.draw_line(c + Vector2(0, -s * 0.18), c + Vector2(0, s * 0.2), INK, w * 1.4)
			ci.draw_line(c + Vector2(0, -s * 0.08), c + Vector2(-s * 0.36, -s * 0.12), INK, w * 1.2)
			ci.draw_line(c + Vector2(0, -s * 0.08), c + Vector2(s * 0.32, s * 0.08), INK, w * 1.2)
			_arrow(ci, c + Vector2(s * 0.36, -s * 0.06), c + Vector2(s * 0.36, s * 0.2), RED, w)
			ci.draw_line(c + Vector2(0, s * 0.2), c + Vector2(-s * 0.14, s * 0.44), INK, w * 1.2)
			ci.draw_line(c + Vector2(0, s * 0.2), c + Vector2(s * 0.14, s * 0.44), INK, w * 1.2)
		2:   # a speech bubble, muddled
			var bub := Rect2(c - Vector2(s * 0.4, s * 0.3), Vector2(s * 0.8, s * 0.46))
			var style := StyleBoxFlat.new()
			style.bg_color = Color.WHITE
			style.set_corner_radius_all(int(s * 0.1))
			style.border_color = INK
			style.set_border_width_all(int(maxf(1.0, w)))
			ci.draw_style_box(style, bub)
			ci.draw_colored_polygon(PackedVector2Array([bub.position + Vector2(s * 0.14, bub.size.y - 1),
				bub.position + Vector2(s * 0.3, bub.size.y - 1), bub.position + Vector2(s * 0.08, bub.size.y + s * 0.16)]),
				Color.WHITE)
			var pts := PackedVector2Array()
			for k in 13:
				pts.append(bub.get_center() + Vector2(-s * 0.3 + k * s * 0.05, sin(k * 1.7) * s * 0.07))
			ci.draw_polyline(pts, INK, w, true)
		3:   # a phone: 999
			var ph := Rect2(c - Vector2(s * 0.2, s * 0.4), Vector2(s * 0.4, s * 0.8))
			var style := StyleBoxFlat.new()
			style.bg_color = Color("2b2f36")
			style.set_corner_radius_all(int(s * 0.06))
			ci.draw_style_box(style, ph)
			ci.draw_rect(ph.grow(-s * 0.04), Color("cfe3f7"))
			var fs := clampi(int(s * 0.18), 8, 30)
			_text(ci, font, c + Vector2(0, fs * 0.35), "999", fs)


# --- track_field ---------------------------------------------------------------------------------------------------

static func _draw_track(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	match str(d.view):
		"marks", "set":
			_draw_sprint_start(ci, font, r, d)
		"relay":
			_draw_relay(ci, font, r, d)
		"long_jump":
			_draw_long_jump(ci, font, r, d)
		"triple_jump":
			_draw_triple_jump(ci, font, r, d)


static func _draw_sprint_start(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var view := str(d.view)
	var labels := bool(d.get("labels", false))
	var fs := _fs(r, 0.08, 9, 18)
	var pose: Dictionary = SPRINT[view]
	var ground := r.end.y - (fs * 1.4 if labels else fs * 0.4)
	var unit := minf(r.size.x * 1.2, (ground - r.position.y - fs * (2.6 if labels else 1.4)) / 0.5)
	var line_x := r.get_center().x + unit * 0.2
	var at := func(k: String) -> Vector2:
		var p: Vector2 = pose[k]
		return Vector2(line_x + p.x * unit, ground - p.y * unit)
	ci.draw_rect(Rect2(Vector2(r.position.x, ground), Vector2(r.size.x, maxf(4.0, r.end.y - ground))), Color("c96a4a"))
	ci.draw_line(Vector2(line_x, ground), Vector2(line_x, ground + 8), Color.WHITE, 4.0)
	ci.draw_line(Vector2(r.position.x, ground), Vector2(r.end.x, ground), Color.WHITE, 3.0)
	for k: String in ["rf", "lf"]:   # the blocks behind the feet
		var f: Vector2 = at.call(k)
		var bw := unit * 0.07
		var fy := minf(f.y, ground)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(f.x - bw, fy), Vector2(f.x + bw * 0.6, fy - bw * 1.3),
			Vector2(f.x + bw * 0.9, fy)]), Color("5b6b86"))
	var w := maxf(2.5, unit * 0.017)
	var neck: Vector2 = at.call("neck")
	var hip: Vector2 = at.call("hip")
	var limb := func(from: Vector2, a: String, b: String, col: Color) -> void:
		ci.draw_polyline(PackedVector2Array([from, at.call(a), at.call(b)]), col, w, true)
	var far := Color(INK, 0.45)
	limb.call(neck, "le", "lh", far)
	limb.call(hip, "lk", "lf", far)
	ci.draw_line(neck, hip, INK, w * 1.3, true)
	limb.call(hip, "rk", "rf", INK)
	limb.call(neck, "re", "rh", INK)
	var head: Vector2 = at.call("head")
	ci.draw_line(neck, head, INK, w, true)
	ci.draw_circle(head, unit * 0.05, Color("fbe3c8"))
	ci.draw_arc(head, unit * 0.05, 0, TAU, 16, INK, w * 0.6, true)
	var title := "On your marks" if view == "marks" else "Set"
	ci.draw_string(font, r.position + Vector2(0, fs), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	if labels:
		var sfs := maxi(8, int(fs * 0.85))
		_text(ci, font, Vector2(line_x + unit * 0.12, ground + sfs * 1.2), "start line", sfs)
		_text(ci, font, Vector2(line_x - unit * 0.4, ground + sfs * 1.2), "blocks", sfs)
		var note := "hips above shoulders" if view == "set" else "back knee down"
		var tip: Vector2 = hip if view == "set" else at.call("lk")
		var tw := font.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs).x
		var at_text := Vector2(clampf(tip.x - tw * 0.5, r.position.x, r.end.x - tw), r.position.y + fs * 2.1)
		ci.draw_string(font, at_text, note, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs, BLUE)
		ci.draw_line(Vector2(at_text.x + tw * 0.5, at_text.y + 3), tip, Color(BLUE, 0.6), 1.5, true)


static func _draw_relay(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var labels := bool(d.get("labels", false))
	var fs := _fs(r, 0.08, 9, 18)
	var lane := Rect2(Vector2(r.position.x, r.position.y + r.size.y * 0.3), Vector2(r.size.x, r.size.y * 0.34))
	ci.draw_rect(lane, Color("c96a4a"))
	ci.draw_line(lane.position, Vector2(lane.end.x, lane.position.y), Color.WHITE, 3.0)
	ci.draw_line(Vector2(lane.position.x, lane.end.y), lane.end, Color.WHITE, 3.0)
	var m := r.size.x / 46.0   # 46 m of track across the card
	var zone_start := r.position.x + 13 * m
	var zone := Rect2(Vector2(zone_start, lane.position.y), Vector2(30 * m, lane.size.y))
	ci.draw_rect(zone, Color(1, 1, 0.6, 0.35))
	for x: float in [zone.position.x, zone.end.x]:
		ci.draw_line(Vector2(x, lane.position.y), Vector2(x, lane.end.y), Color("f2c230"), 4.0)
	var check := zone_start - 6 * m   # the outgoing runner's check mark
	ci.draw_line(Vector2(check - 5, lane.get_center().y - 5), Vector2(check + 5, lane.get_center().y + 5), Color.WHITE, 3.0)
	ci.draw_line(Vector2(check - 5, lane.get_center().y + 5), Vector2(check + 5, lane.get_center().y - 5), Color.WHITE, 3.0)
	var rad := lane.size.y * 0.2
	var incoming := Vector2(check - 4.5 * m, lane.get_center().y)
	var outgoing := Vector2(zone_start + 3 * m, lane.get_center().y)
	for p: Vector2 in [incoming, outgoing]:
		ci.draw_circle(p, rad, BLUE)
		_arrow(ci, p + Vector2(rad * 1.2, 0), p + Vector2(rad * 3.2, 0), Color.WHITE, maxf(2.0, rad * 0.25))
	ci.draw_line(incoming + Vector2(rad * 0.4, -rad * 0.9), incoming + Vector2(rad * 1.1, -rad * 1.4), Color("f2c230"), rad * 0.4)
	if labels:
		var sfs := maxi(8, int(fs * 0.9))
		_text(ci, font, Vector2(zone.get_center().x, lane.position.y - sfs * 0.5), "takeover zone: 30 m", sfs)
		_text(ci, font, Vector2(check, lane.end.y + sfs * 1.3), "check mark", sfs)
		_text(ci, font, Vector2(incoming.x, lane.position.y - sfs * 0.5), "baton", sfs)
		_text(ci, font, Vector2(outgoing.x + rad * 2, lane.end.y + sfs * 1.3), "next runner", sfs)


static func _draw_long_jump(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var labels := bool(d.get("labels", false))
	var fs := _fs(r, 0.08, 9, 18)
	var ground := r.position.y + r.size.y * 0.55
	var board_x := r.position.x + r.size.x * 0.24
	var m := (r.end.x - board_x) / PIT_M
	var pit_start := board_x + 1.0 * m
	ci.draw_rect(Rect2(Vector2(r.position.x, ground), Vector2(board_x - r.position.x, r.size.y * 0.08)), Color("c96a4a"))
	ci.draw_rect(Rect2(Vector2(board_x - m * 0.2, ground), Vector2(m * 0.2, r.size.y * 0.08)), Color.WHITE)
	ci.draw_line(Vector2(board_x, ground - 3), Vector2(board_x, ground + r.size.y * 0.08), INK, 2.0)
	ci.draw_rect(Rect2(Vector2(board_x, ground), Vector2(pit_start - board_x, r.size.y * 0.08)), Color("c96a4a"))
	ci.draw_rect(Rect2(Vector2(pit_start, ground), Vector2(r.end.x - pit_start, r.size.y * 0.12)), SAND)
	for t in range(0, 11):   # metres from the take-off line
		var x := board_x + t * m
		ci.draw_line(Vector2(x, ground + r.size.y * 0.13), Vector2(x, ground + r.size.y * 0.16), INK, 1.2)
		if t % 2 == 0:
			_text(ci, font, Vector2(x, ground + r.size.y * 0.16 + fs), "%d m" % t if t > 0 else "0", maxi(8, int(fs * 0.8)))
	var marks: Array = d.get("marks", [])
	for mk: Variant in marks:
		var x := board_x + float(mk) * m
		var dent := PackedVector2Array()
		for p: Vector2 in _half_disc(Vector2(x, ground + 2), m * 0.2):
			dent.append(Vector2(p.x, 2 * (ground + 2) - p.y))
		ci.draw_colored_polygon(dent, Color("b89a5a"))
	if bool(d.get("measure", false)) and not marks.is_empty():
		var near := jump_length(marks)
		var y := ground - r.size.y * 0.12
		var x1 := board_x + near * m
		var x := board_x
		while x < x1:
			ci.draw_line(Vector2(x, y), Vector2(minf(x + 8, x1), y), BLUE, 3.0)
			x += 13
		ci.draw_line(Vector2(board_x, y - 6), Vector2(board_x, y + 6), BLUE, 2.0)
		ci.draw_line(Vector2(x1, y - 6), Vector2(x1, ground), BLUE, 2.0)
		_text_col(ci, font, Vector2((board_x + x1) * 0.5, y - 6), _metres(near), fs, BLUE)
	if labels:
		var sfs := maxi(8, int(fs * 0.9))
		ci.draw_string(font, r.position + Vector2(0, sfs * 1.2), "run-up", HORIZONTAL_ALIGNMENT_LEFT, -1, sfs, INK)
		_text(ci, font, Vector2(board_x, r.position.y + sfs * 2.6), "take-off line", sfs)
		ci.draw_line(Vector2(board_x, r.position.y + sfs * 2.9), Vector2(board_x, ground - 4), Color(INK, 0.5), 1.2)
		_text(ci, font, Vector2(r.end.x - r.size.x * 0.12, r.position.y + sfs * 1.2), "sand pit", sfs)


static func _draw_triple_jump(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var labels := bool(d.get("labels", false))
	var phases: Array = d.get("phases", [3.5, 2.5, 3.0])
	var fs := _fs(r, 0.08, 9, 18)
	var total := float(phases[0]) + float(phases[1]) + float(phases[2])
	var board_x := r.position.x + r.size.x * 0.1
	var m := (r.end.x - board_x) / (total + 1.0)
	var y := r.position.y + r.size.y * 0.45
	var runway := Rect2(Vector2(r.position.x, y - r.size.y * 0.14), Vector2(r.size.x, r.size.y * 0.28))
	ci.draw_rect(runway, Color("c96a4a"))
	var pit_x := board_x + (float(phases[0]) + float(phases[1]) + float(phases[2]) * 0.4) * m
	ci.draw_rect(Rect2(Vector2(pit_x, runway.position.y - r.size.y * 0.05), Vector2(r.end.x - pit_x, runway.size.y + r.size.y * 0.1)),
		SAND)
	ci.draw_rect(Rect2(Vector2(board_x - m * 0.2, runway.position.y), Vector2(m * 0.2, runway.size.y)), Color.WHITE)
	var xs: Array[float] = [board_x]
	var acc := 0.0
	for p: Variant in phases:
		acc += float(p)
		xs.append(board_x + acc * m)
	var foot := func(c: Vector2, col: Color) -> void:
		ci.draw_set_transform(c, 0, Vector2(1.6, 1))
		ci.draw_circle(Vector2.ZERO, r.size.y * 0.035, col)
		ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var left := Color("2f6fdc")
	var right := Color("dc3d2d")
	foot.call(Vector2(xs[0] - m * 0.1, y - r.size.y * 0.05), left)    # take off from the left foot …
	foot.call(Vector2(xs[1], y - r.size.y * 0.05), left)             # … hop: land on the same foot
	foot.call(Vector2(xs[2], y + r.size.y * 0.05), right)            # step: land on the other foot
	foot.call(Vector2(xs[3], y - r.size.y * 0.05), SAND.darkened(0.35))   # jump: land on both feet in the pit
	foot.call(Vector2(xs[3], y + r.size.y * 0.05), SAND.darkened(0.35))
	var words: Array[String] = ["hop", "step", "jump"]
	for i in 3:
		var a := xs[i]
		var b := xs[i + 1]
		var by := runway.end.y + r.size.y * 0.1
		ci.draw_line(Vector2(a, by), Vector2(b, by), INK, 1.5)
		ci.draw_line(Vector2(a, by - 5), Vector2(a, by + 5), INK, 1.5)
		ci.draw_line(Vector2(b, by - 5), Vector2(b, by + 5), INK, 1.5)
		var t := words[i] + (" " + _metres(float(phases[i])) if labels else "")
		_text(ci, font, Vector2((a + b) * 0.5, by + fs * 1.2), t, _fit(font, t, b - a, fs))
	if labels:
		ci.draw_string(font, r.position + Vector2(0, fs), "blue: left foot, red: right foot", HORIZONTAL_ALIGNMENT_LEFT,
			r.size.x, maxi(8, int(fs * 0.85)), INK)


## A length in metres as the lessons write it: 3.2 m, 4 m.
static func _metres(v: float) -> String:
	return ("%d m" % int(v)) if v == floorf(v) else ("%s m" % str(snappedf(v, 0.01)))


# --- helpers -------------------------------------------------------------------------------------------------------

## The font size (at most `fs`) at which `text` fits `width`.
static func _fit(font: Font, text: String, width: float, fs: int) -> int:
	var size := fs
	while size > 7 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
		size -= 1
	return size


static func _fit_all(font: Font, texts: Array, width: float, fs: int) -> int:
	var size := fs
	for t: Variant in texts:
		size = mini(size, _fit(font, str(t), width, fs))
	return size


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
