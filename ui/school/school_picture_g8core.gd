class_name SchoolPictureG8Core
extends RefCounted
## Owner #70, #73 and #111, grade 8 maths, science and English: the research's last 14 units (research §6.8): the
## picture kinds they add, drawn from data onto a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI
## draw calls only, no new art; the font has no arrows, so they are drawn). Diagrams name their parts with grade 7's
## labels (SchoolPictureG7Life's bands along the top and bottom, each with a line to its part); `mark` (a part) is orange
## and `hide` (a part) shows "?"; `pins` (true) leaves the bands free for a label exercise's pins; a part's place is
## `part_at`'s, so the pins can point at them. Kinds and fields:
## Maths
## - parabola {a? (1), b? (0), c? (0) (whole: a from −3 to 3, not 0; b −12 to 12; c −30 to 30), from? (−5), to? (5)
##   (whole x, 2-12 apart), points?: [x] (0-5 whole x in range: dots on the curve), roots? (true: its crossings of the
##   x-axis marked and numbered), vertex? (true: the lowest or highest point marked), axis? (true: the line of symmetry
##   dashed), equation? (true, the default: "y = x² − 4" written)}: the graph of y = ax² + bx + c, a U (or an upside-down
##   U), on a grid whose y-range fits the curve (parabola_y, roots, vertex, equation).
## - trig_triangle {angle (10-80 whole degrees: the marked angle, which sets the shape), at? ("left", the default: the
##   marked angle at the bottom left; "top": at the top), sides?: {hyp?, opp?, adj? (8 letters: "10 cm", "?")}, names?
##   (true: the words hypotenuse, opposite and adjacent by the sides), angle_label? (6 letters, "x" by default: "35°",
##   "?"), scene? ("ladder": a ladder against a wall; "ramp": a wedge on the ground), mark? (a side: "hyp", "opp",
##   "adj"), labels?, pins?, hide? (TRIG_PARTS)}: a right-angled triangle, the right angle at the bottom right, its
##   sides named from the marked angle (part_at: hypotenuse, opposite, adjacent, right angle, angle x).
## Science
## - fluid_pressure {view: FLUID_VIEWS ("faces": the same brick on its end and lying flat on sand, its dent deeper under
##   the small face; "spouts": a raised tank with three holes, water spurting furthest from the deepest; "dam": a dam
##   thicker at its base, the water's push growing with depth; "float": a floating block (or, floats false, a sinking
##   stone) with its weight and upthrust as arrows), floats? (float: true), words? (true: what it shows, in a line),
##   labels?, pins?, mark?, hide? (FLUID_PARTS[view])}.
## - energy_meter {readings: [[label (12 letters), digits (4-6 digits as text)]] (1-2: a week's start and end), unit?
##   ("kWh"), mark? (a reading's index, orange)}: an electricity meter's display for each reading (meter_used).
## - energy_profile {type: "exo" | "endo", reactants?, products? (16 letters: their names), values?: [reactants,
##   products] (kJ, 0-10,000; exo: the products lower, endo: higher), hump? (true: the activation energy hump), names?
##   (true: "energy given out" or "taken in", and "activation energy", by their arrows), hide? ("change": its words or
##   number "?"), labels?, pins?, mark? (PROFILE_PARTS)}: an energy level diagram (part_at: reactants, products, energy
##   change, activation energy).
## - meter_circuit {layout: "series" | "parallel", volts (the cell's voltage, more than 0, at most 24), parts: [[type
##   (PARTS: lamp, resistor, motor), ohms? (more than 0)]] (series 1-3, parallel 2-3 branches), meters?: [[ "A" | "V",
##   where, reading? (a number, or "?")]] (0-4; an ammeter's where is "main" or (parallel) a branch's index as text; a
##   voltmeter's is "cell" or a part's index), names? (true: each part's name and resistance)}: a circuit diagram with
##   UK symbols, ammeters in the wires and voltmeters across their parts; with every part's resistance a meter's number
##   must be its reading (reading: the series current is the voltage ÷ the total resistance and the parts share the
##   voltage; parallel branches each have the full voltage and their currents add up).
## - plant_transport {show? ("both", the default; "xylem"; "phloem"), flows? (true: the arrows), labels?, pins?, mark?,
##   hide? (PLANT_PARTS)}: a plant's transport: water up the xylem from the root hairs to the leaves and out of the
##   stomata, sugars along the phloem both ways (part_at).
## - heart_chambers {flow? (true: blood's way as arrows, blue low in oxygen, red rich in it), sides? (true: "person's
##   right" and "person's left" under it), parts? (the HEART_PARTS the labels or pins name: all by default), labels?,
##   pins?, mark?, hide? (one of the parts)}: the heart from the front: the
##   person's right side on the picture's left; four chambers, the valves, the vena cava, the pulmonary artery and vein
##   and the aorta (part_at).
## - air_sac {arrows? (true: oxygen into the blood, carbon dioxide out), labels?, pins?, mark?, hide? (SAC_PARTS)}: an
##   alveolus at the end of an airway, a capillary round it with red blood cells (part_at).
## - gene_transfer {step? (1-4: that panel in orange), words? (true: a caption under each panel), labels?, pins?, mark?,
##   hide? (GENE_PARTS)}: genetic engineering in four panels: the human insulin gene cut out, put into a bacterium's
##   plasmid, the bacteria multiplying, and the insulin they make (part_at).
## English
## - slide_design {title (26 letters), bullets?: [text (30)] (0-5), chart?: [[label (8), value (0 or more)]] (2-5 bars),
##   number? (8 letters: one big number, "60%"), image? (IMAGES: a simple picture), busy? (true: the same slide crammed:
##   small text in clashing colours), notes? (60 letters: the speaker's notes under it), mark? (SLIDE_PARTS)}: a
##   presentation slide on a screen.
## - story_order {events: [text (22 letters)] (3-5, in the order they happened), told: [index] (the order the story
##   tells them: each index once), flash? (an event's index: drawn orange), names? (true: the rows' names)}: the order a
##   story is told above the order it happened, a line joining each event's two cards: a flashback's lines cross
##   (flashback).

const L := preload("res://ui/school/school_picture_g7life.gd")
const KINDS: Array[String] = ["parabola", "trig_triangle", "fluid_pressure", "energy_meter", "energy_profile",
	"meter_circuit", "plant_transport", "heart_chambers", "air_sac", "gene_transfer", "slide_design", "story_order"]
const INK := Color("1f2a4a")    # SchoolUi.INK
const PAPER := Color("fdf6e3")  # SchoolUi.PAPER
const ORANGE := Color("f08a1c")
const SOFT := Color("fce2b8")
const RED := Color("d9433b")
const BLUE := Color("3a7be8")
const GREEN := Color("3fa34d")
const GREY := Color("9aa1ad")
const PALE := Color("eef1f6")
const WATER := Color("7fb6e8")
const SAND := Color("e6cf98")
const WOOD := Color("c98b4f")
const LEAF := Color("5fae4f")
const SKY := Color("dcecf8")

## The shape (width ÷ height) of each labelled diagram's box.
const RATIOS := {"trig_triangle": 2.0, "fluid_pressure": 2.0, "energy_profile": 2.0, "plant_transport": 2.0,
	"heart_chambers": 2.0, "air_sac": 2.0, "gene_transfer": 3.0}

const MAX_A := 3
const MAX_B := 12
const MAX_C := 30
const MAX_SPAN := 12
const MAX_POINTS := 5

const TRIG_SIDES: Array[String] = ["hyp", "opp", "adj"]
const TRIG_NAMES := {"hyp": "hypotenuse", "opp": "opposite", "adj": "adjacent"}
const TRIG_PARTS: Array[String] = ["hypotenuse", "opposite", "adjacent", "right angle", "angle x"]
const AT: Array[String] = ["left", "top"]
const SCENES: Array[String] = ["ladder", "ramp"]
const MAX_SIDE := 8
const MAX_ANGLE_LABEL := 6

const FLUID_VIEWS: Array[String] = ["faces", "spouts", "dam", "float"]
const FLUID_PARTS := {"faces": ["small area", "large area", "sand"], "spouts": ["top hole", "middle hole",
	"bottom hole", "water"], "dam": ["dam wall", "reservoir", "thick base"], "float": ["weight", "upthrust",
	"water line"]}
const FLUID_WORDS := {"faces": "the same force on a smaller area: more pressure",
	"spouts": "deeper water: more pressure, a faster jet", "dam": "the deeper the water, the bigger its push",
	"float": "it floats: upthrust balances its weight"}
const SINK_WORDS := "it sinks: its weight is more than the upthrust"
## Each part's place in its view's box (fractions of its width and height).
const FLUID_AT := {
	"faces": {"small area": Vector2(0.25, 0.74), "large area": Vector2(0.7, 0.665), "sand": Vector2(0.48, 0.86)},
	"spouts": {"top hole": Vector2(0.3, 0.24), "middle hole": Vector2(0.3, 0.36), "bottom hole": Vector2(0.3, 0.48),
		"water": Vector2(0.2, 0.3)},
	"dam": {"dam wall": Vector2(0.56, 0.3), "reservoir": Vector2(0.25, 0.55), "thick base": Vector2(0.62, 0.86)},
	"float": {"weight": Vector2(0.5, 0.7), "upthrust": Vector2(0.5, 0.18), "water line": Vector2(0.85, 0.45)},
}

const MAX_READING_LABEL := 12

const PROFILE_TYPES: Array[String] = ["exo", "endo"]
const PROFILE_PARTS: Array[String] = ["reactants", "products", "energy change", "activation energy"]
const MAX_SPECIES := 16
const MAX_KJ := 10000.0

const LAYOUTS: Array[String] = ["series", "parallel"]
const PARTS: Array[String] = ["lamp", "resistor", "motor"]
const MAX_VOLTS := 24.0
const MAX_METERS := 4

const SHOWS: Array[String] = ["both", "xylem", "phloem"]
const PLANT_PARTS: Array[String] = ["xylem", "phloem", "root hairs", "stomata", "leaf"]
const PLANT_AT := {"xylem": Vector2(0.46, 0.5), "phloem": Vector2(0.54, 0.68), "root hairs": Vector2(0.35, 0.9),
	"stomata": Vector2(0.72, 0.39), "leaf": Vector2(0.28, 0.27)}

const HEART_PARTS: Array[String] = ["right atrium", "left atrium", "right ventricle", "left ventricle", "aorta",
	"vena cava", "pulmonary artery", "pulmonary vein"]
const HEART_AT := {"right atrium": Vector2(0.41, 0.38), "left atrium": Vector2(0.59, 0.38),
	"right ventricle": Vector2(0.43, 0.66), "left ventricle": Vector2(0.57, 0.68), "aorta": Vector2(0.55, 0.1),
	"vena cava": Vector2(0.22, 0.24), "pulmonary artery": Vector2(0.441, 0.13), "pulmonary vein": Vector2(0.76, 0.346)}

const SAC_PARTS: Array[String] = ["air sac", "capillary", "oxygen", "carbon dioxide", "airway"]
const SAC_AT := {"air sac": Vector2(0.5, 0.32), "capillary": Vector2(0.691, 0.716), "oxygen": Vector2(0.43, 0.63),
	"carbon dioxide": Vector2(0.58, 0.63), "airway": Vector2(0.5, 0.07)}

const GENE_PARTS: Array[String] = ["human gene", "plasmid", "bacterium", "insulin"]
const GENE_AT := {"human gene": Vector2(0.135, 0.45), "plasmid": Vector2(0.375, 0.28), "bacterium": Vector2(0.62, 0.62),
	"insulin": Vector2(0.88, 0.5)}
const GENE_WORDS: Array[String] = ["cut out the gene", "put it in a plasmid", "bacteria multiply", "they make insulin"]

const IMAGES: Array[String] = ["none", "map", "plant", "sun", "chart_icon"]
const SLIDE_PARTS: Array[String] = ["title", "bullets", "chart", "number", "image"]
const MAX_SLIDE_TITLE := 26
const MAX_BULLET := 30
const MAX_BULLETS := 5
const MAX_BAR_LABEL := 8
const MAX_NUMBER := 8
const MAX_NOTES := 60

const MAX_EVENT := 22


# --- Rules (the content test works them out again) -------------------------------------------------------------------

static func _abc(d: Dictionary) -> Vector3:
	return Vector3(float(d.get("a", 1)), float(d.get("b", 0)), float(d.get("c", 0)))


## y = ax² + bx + c at x.
static func parabola_y(d: Dictionary, x: float) -> float:
	var k := _abc(d)
	return k.x * x * x + k.y * x + k.z


## Where the curve crosses the x-axis, smallest first ([] when it never does).
static func roots(d: Dictionary) -> Array[float]:
	var k := _abc(d)
	var disc := k.y * k.y - 4.0 * k.x * k.z
	var out: Array[float] = []
	if disc < -0.000001:
		return out
	var s := sqrt(maxf(disc, 0.0))
	var r1 := (-k.y - s) / (2.0 * k.x)
	var r2 := (-k.y + s) / (2.0 * k.x)
	out.append(minf(r1, r2))
	if s > 0.000001:
		out.append(maxf(r1, r2))
	return out


## The lowest point of a U (the highest of an upside-down U).
static func vertex(d: Dictionary) -> Vector2:
	var k := _abc(d)
	var x := -k.y / (2.0 * k.x)
	return Vector2(x, parabola_y(d, x))


## "y = x² − 4x + 3", as the lessons write it.
static func equation(d: Dictionary) -> String:
	var k := _abc(d)
	var out := "y = "
	var a := int(k.x)
	out += ("x²" if a == 1 else ("−x²" if a == -1 else ("−" if a < 0 else "") + str(absi(a)) + "x²"))
	var b := int(k.y)
	if b != 0:
		out += (" + " if b > 0 else " − ") + ("" if absi(b) == 1 else str(absi(b))) + "x"
	var c := int(k.z)
	if c != 0:
		out += (" + " if c > 0 else " − ") + str(absi(c))
	return out


## The units a meter counted: the second reading less the first.
static func meter_used(d: Dictionary) -> int:
	var r: Array = d.get("readings", [])
	if r.size() < 2:
		return 0
	return str(r[1][1]).to_int() - str(r[0][1]).to_int()


## Meter `i`'s reading worked out from the cell's voltage and the parts' resistances (NAN when a part has none).
static func reading(d: Dictionary, i: int) -> float:
	var meters: Array = d.get("meters", [])
	if i < 0 or i >= meters.size():
		return NAN
	var ohms: Array[float] = []
	for p: Variant in d.get("parts", []):
		if (p as Array).size() < 2:
			return NAN
		ohms.append(float(p[1]))
	var volts := float(d.volts)
	var m: Array = meters[i]
	var kind := str(m[0])
	var where := str(m[1])
	if str(d.layout) == "series":
		var total := 0.0
		for o in ohms:
			total += o
		var amps := volts / total
		if kind == "A":
			return amps
		return volts if where == "cell" else amps * ohms[where.to_int()]
	if kind == "V":
		return volts
	if where == "main":
		var amps := 0.0
		for o in ohms:
			amps += volts / o
		return amps
	return volts / ohms[where.to_int()]


## The story is told out of time order (a flashback, or a flash forward).
static func flashback(d: Dictionary) -> bool:
	var told: Array = d.get("told", [])
	for k in range(1, told.size()):
		if int(told[k]) < int(told[k - 1]):
			return true
	return false


## Where the part named `label` is drawn on a picture of `size` (a SchoolPicture's whole size), for a label's line;
## (-1, -1) when the picture has no such part.
static func part_at(p: Dictionary, label: String, size: Vector2) -> Vector2:
	var none := Vector2(-1, -1)
	if not RATIOS.has(str(p.get("kind", ""))):
		return none
	var a := _diagram_box(p, L._rect(size))
	return _anchors(p, a).get(label, none)


## A diagram's box in `r`: its label bands (or its pins' bands) taken off, then its shape (RATIOS) centred.
static func _diagram_box(p: Dictionary, r: Rect2) -> Rect2:
	var fs := L._fs(r)
	var ratio := float(RATIOS.get(str(p.get("kind", "")), 2.0))
	var bands := bool(p.get("labels", false)) or bool(p.get("pins", false))
	return L._fit_box(L._inner(r, fs, bands), ratio)


## Each named part's place in the diagram box `a`.
static func _anchors(p: Dictionary, a: Rect2) -> Dictionary:
	var out := {}
	match str(p.get("kind", "")):
		"trig_triangle":
			var t := _trig_geo(p, a)
			var mids: Dictionary = t.mids
			for side: String in TRIG_SIDES:
				out[TRIG_NAMES[side]] = mids[side]
			var b: Vector2 = t.B
			out["right angle"] = b + Vector2(-1, -1) * float(t.s) * 0.5
			out["angle x"] = t.mark_at
		"fluid_pressure":
			var at: Dictionary = FLUID_AT.get(str(p.get("view", "")), {})
			for part: String in at:
				out[part] = L._at(a, at[part].x, at[part].y)
			if str(p.get("view", "")) == "float" and not bool(p.get("floats", true)):   # a sinking stone's arrows
				out["weight"] = L._at(a, 0.5, 0.85)
				out["upthrust"] = L._at(a, 0.5, 0.56)
		"energy_profile":
			var g := _profile_geo(p, a)
			out["reactants"] = Vector2(L._at(a, 0.2, 0).x, g.yr)
			out["products"] = Vector2(L._at(a, 0.8, 0).x, g.yp)
			out["energy change"] = Vector2(L._at(a, 0.95, 0).x, (g.yr + g.yp) * 0.5)
			out["activation energy"] = Vector2(L._at(a, 0.33, 0).x, (g.yr + g.peak) * 0.5)
		"plant_transport":
			for part: String in PLANT_PARTS:
				if part == "xylem" and str(p.get("show", "both")) == "phloem":
					continue
				if part == "phloem" and str(p.get("show", "both")) == "xylem":
					continue
				out[part] = L._at(a, PLANT_AT[part].x, PLANT_AT[part].y)
		"heart_chambers":
			for part: String in HEART_PARTS:
				if (p.get("parts", HEART_PARTS) as Array).has(part):
					out[part] = L._at(a, HEART_AT[part].x, HEART_AT[part].y)
		"air_sac":
			for part: String in SAC_PARTS:
				out[part] = L._at(a, SAC_AT[part].x, SAC_AT[part].y)
		"gene_transfer":
			for part: String in GENE_PARTS:
				out[part] = L._at(a, GENE_AT[part].x, GENE_AT[part].y)
	return out


# --- Checks -------------------------------------------------------------------------------------------------------------

## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	var kind := str(p.get("kind", ""))
	match kind:
		"parabola":
			return _parabola_problem(p)
		"trig_triangle":
			return _trig_problem(p)
		"fluid_pressure":
			if not FLUID_VIEWS.has(str(p.get("view", ""))):
				return "fluid_pressure: view is one of %s" % [FLUID_VIEWS]
			if p.has("floats") and (not p.floats is bool or str(p.view) != "float"):
				return "fluid_pressure: floats is true or false, in the float view"
			return L._parts_problem(p, FLUID_PARTS[str(p.view)], ["pins", "words"])
		"energy_meter":
			return _meter_problem(p)
		"energy_profile":
			return _profile_problem(p)
		"meter_circuit":
			return _circuit_problem(p)
		"plant_transport":
			if p.has("show") and not SHOWS.has(str(p.show)):
				return "plant_transport: show is one of %s" % [SHOWS]
			var parts: Array = PLANT_PARTS.duplicate()
			if str(p.get("show", "both")) == "xylem":
				parts.erase("phloem")
			elif str(p.get("show", "both")) == "phloem":
				parts.erase("xylem")
			return L._parts_problem(p, parts, ["pins", "flows"])
		"heart_chambers":
			if p.has("parts"):
				var why := L._list_problem(p, "parts", HEART_PARTS, HEART_PARTS.size())
				if why != "":
					return "heart_chambers: " + why
			return L._parts_problem(p, p.get("parts", HEART_PARTS), ["pins", "flow", "sides"])
		"air_sac":
			return L._parts_problem(p, SAC_PARTS, ["pins", "arrows"])
		"gene_transfer":
			if p.has("step") and (not L._whole(p.step) or int(p.step) < 1 or int(p.step) > 4):
				return "gene_transfer: step is 1-4"
			return L._parts_problem(p, GENE_PARTS, ["pins", "words"])
		"slide_design":
			return _slide_problem(p)
		"story_order":
			return _story_problem(p)
	return "unknown picture kind '%s'" % kind


static func _short(v: Variant, most: int) -> bool:
	return v is String and str(v).strip_edges() != "" and str(v).length() <= most


static func _parabola_problem(p: Dictionary) -> String:
	for key: String in ["a", "b", "c", "from", "to"]:
		if p.has(key) and not L._whole(p[key]):
			return "parabola: %s is a whole number" % key
	var k := _abc(p)
	if is_zero_approx(k.x) or absf(k.x) > MAX_A or absf(k.y) > MAX_B or absf(k.z) > MAX_C:
		return "parabola: a is −%d to %d and not 0, b −%d to %d, c −%d to %d" % [MAX_A, MAX_A, MAX_B, MAX_B, MAX_C,
			MAX_C]
	var lo := int(p.get("from", -5))
	var hi := int(p.get("to", 5))
	if hi - lo < 2 or hi - lo > MAX_SPAN:
		return "parabola: from and to are 2-%d apart" % MAX_SPAN
	var pts: Variant = p.get("points", [])
	if not pts is Array or (pts as Array).size() > MAX_POINTS:
		return "parabola: points is 0-%d whole x" % MAX_POINTS
	for x: Variant in pts:
		if not L._whole(x) or int(x) < lo or int(x) > hi:
			return "parabola: a point's x is whole, from %d to %d" % [lo, hi]
	return L._flags_problem(p, ["roots", "vertex", "axis", "equation"])


static func _trig_problem(p: Dictionary) -> String:
	if not L._whole(p.get("angle")) or int(p.angle) < 10 or int(p.angle) > 80:
		return "trig_triangle: angle is 10-80 whole degrees"
	if p.has("at") and not AT.has(str(p.at)):
		return "trig_triangle: at is one of %s" % [AT]
	if p.has("scene") and not SCENES.has(str(p.scene)):
		return "trig_triangle: scene is one of %s" % [SCENES]
	if p.has("sides"):
		if not p.sides is Dictionary:
			return "trig_triangle: sides is {hyp?, opp?, adj?}"
		for key: Variant in p.sides:
			if not TRIG_SIDES.has(str(key)) or not _short(p.sides[key], MAX_SIDE):
				return "trig_triangle: sides are hyp, opp, adj, each 1-%d letters" % MAX_SIDE
	if p.has("angle_label") and not _short(p.angle_label, MAX_ANGLE_LABEL):
		return "trig_triangle: angle_label is 1-%d letters" % MAX_ANGLE_LABEL
	if p.has("mark") and not (TRIG_SIDES.has(str(p.mark)) or TRIG_PARTS.has(str(p.mark))):
		return "trig_triangle: mark is a side (%s) or a part" % [TRIG_SIDES]
	if p.has("hide") and not TRIG_PARTS.has(str(p.hide)):
		return "trig_triangle: hide is one of %s" % [TRIG_PARTS]
	return L._flags_problem(p, ["names", "labels", "pins"])


static func _meter_problem(p: Dictionary) -> String:
	var r: Variant = p.get("readings")
	if not r is Array or (r as Array).is_empty() or (r as Array).size() > 2:
		return "energy_meter: readings is 1-2 [label, digits]"
	for x: Variant in r:
		if not x is Array or (x as Array).size() != 2 or not _short(x[0], MAX_READING_LABEL):
			return "energy_meter: a reading is [label (1-%d letters), digits]" % MAX_READING_LABEL
		var digits := str(x[1])
		if not x[1] is String or digits.length() < 4 or digits.length() > 6 or not digits.is_valid_int() \
				or digits.contains("-") or digits.contains("+"):
			return "energy_meter: digits are 4-6 digits as text"
	if (r as Array).size() == 2 and (str(r[1][1]).length() != str(r[0][1]).length() or meter_used(p) < 0):
		return "energy_meter: the second reading has as many digits, and is not less"
	if p.has("unit") and not _short(p.unit, 6):
		return "energy_meter: unit is 1-6 letters"
	return L._index_problem(p, (r as Array).size())


static func _profile_problem(p: Dictionary) -> String:
	if not PROFILE_TYPES.has(str(p.get("type", ""))):
		return "energy_profile: type is one of %s" % [PROFILE_TYPES]
	for key: String in ["reactants", "products"]:
		if p.has(key) and not _short(p[key], MAX_SPECIES):
			return "energy_profile: %s is 1-%d letters" % [key, MAX_SPECIES]
	if p.has("values"):
		var v: Variant = p.values
		if not v is Array or (v as Array).size() != 2 or not L._number(v[0]) or not L._number(v[1]) \
				or float(v[0]) < 0.0 or float(v[1]) < 0.0 or float(v[0]) > MAX_KJ or float(v[1]) > MAX_KJ:
			return "energy_profile: values is [reactants, products], 0-%d kJ" % int(MAX_KJ)
		if (str(p.type) == "exo") != (float(v[1]) < float(v[0])) or is_equal_approx(float(v[0]), float(v[1])):
			return "energy_profile: exo has the products lower, endo higher"
	if p.has("hide") and str(p.hide) != "change" and not PROFILE_PARTS.has(str(p.hide)):
		return "energy_profile: hide is \"change\" or a part"
	if p.has("mark") and not PROFILE_PARTS.has(str(p.mark)):
		return "energy_profile: mark is one of %s" % [PROFILE_PARTS]
	return L._flags_problem(p, ["hump", "names", "labels", "pins"])


static func _circuit_problem(p: Dictionary) -> String:
	if not LAYOUTS.has(str(p.get("layout", ""))):
		return "meter_circuit: layout is one of %s" % [LAYOUTS]
	if not L._number(p.get("volts")) or float(p.volts) <= 0.0 or float(p.volts) > MAX_VOLTS:
		return "meter_circuit: volts is more than 0, at most %d" % int(MAX_VOLTS)
	var parts: Variant = p.get("parts")
	var most := 3
	var least := 1 if str(p.layout) == "series" else 2
	if not parts is Array or (parts as Array).size() < least or (parts as Array).size() > most:
		return "meter_circuit: %s has %d-%d parts" % [p.layout, least, most]
	for part: Variant in parts:
		if not part is Array or (part as Array).is_empty() or (part as Array).size() > 2 or not PARTS.has(str(part[0])):
			return "meter_circuit: a part is [%s, ohms?]" % [PARTS]
		if (part as Array).size() == 2 and (not L._number(part[1]) or float(part[1]) <= 0.0):
			return "meter_circuit: a part's ohms are more than 0"
	var meters: Variant = p.get("meters", [])
	if not meters is Array or (meters as Array).size() > MAX_METERS:
		return "meter_circuit: meters is 0-%d" % MAX_METERS
	var n := (parts as Array).size()
	var seen := {}
	for i in (meters as Array).size():
		var m: Variant = meters[i]
		if not m is Array or (m as Array).size() < 2 or (m as Array).size() > 3 or not str(m[0]) in ["A", "V"]:
			return "meter_circuit: a meter is [\"A\" | \"V\", where, reading?]"
		var where := str(m[1])
		var places: Array[String] = []
		places.append("cell" if str(m[0]) == "V" else "main")
		if str(m[0]) == "V" or str(p.layout) == "parallel":
			for k in n:
				places.append(str(k))
		if not places.has(where):
			return "meter_circuit: %s's place is one of %s" % [m[0], places]
		if seen.has(str(m[0]) + where):
			return "meter_circuit: two meters in one place"
		seen[str(m[0]) + where] = true
		if (m as Array).size() == 3:
			if not (str(m[2]) == "?" or L._number(m[2])):
				return "meter_circuit: a reading is a number or \"?\""
			var want := reading(p, i)
			if L._number(m[2]) and not is_nan(want) and absf(float(m[2]) - want) > 0.011:
				return "meter_circuit: meter %d reads %s, not %s" % [i, want, m[2]]
	return L._flags_problem(p, ["names"])


static func _slide_problem(p: Dictionary) -> String:
	if not _short(p.get("title"), MAX_SLIDE_TITLE):
		return "slide_design: title is 1-%d letters" % MAX_SLIDE_TITLE
	var b: Variant = p.get("bullets", [])
	if not b is Array or (b as Array).size() > MAX_BULLETS:
		return "slide_design: bullets is 0-%d" % MAX_BULLETS
	for t: Variant in b:
		if not _short(t, MAX_BULLET):
			return "slide_design: a bullet is 1-%d letters" % MAX_BULLET
	if p.has("chart"):
		var c: Variant = p.chart
		if not c is Array or (c as Array).size() < 2 or (c as Array).size() > 5:
			return "slide_design: chart is 2-5 bars"
		for bar: Variant in c:
			if not bar is Array or (bar as Array).size() != 2 or not _short(bar[0], MAX_BAR_LABEL) \
					or not L._number(bar[1]) or float(bar[1]) < 0.0:
				return "slide_design: a bar is [label (1-%d letters), value]" % MAX_BAR_LABEL
	if p.has("number") and not _short(p.number, MAX_NUMBER):
		return "slide_design: number is 1-%d letters" % MAX_NUMBER
	if p.has("image") and not IMAGES.has(str(p.image)):
		return "slide_design: image is one of %s" % [IMAGES]
	if p.has("notes") and not _short(p.notes, MAX_NOTES):
		return "slide_design: notes are 1-%d letters" % MAX_NOTES
	if p.has("mark") and not SLIDE_PARTS.has(str(p.mark)):
		return "slide_design: mark is one of %s" % [SLIDE_PARTS]
	return L._flags_problem(p, ["busy"])


static func _story_problem(p: Dictionary) -> String:
	var e: Variant = p.get("events")
	if not e is Array or (e as Array).size() < 3 or (e as Array).size() > 5:
		return "story_order: events is 3-5"
	for t: Variant in e:
		if not _short(t, MAX_EVENT):
			return "story_order: an event is 1-%d letters" % MAX_EVENT
	var told: Variant = p.get("told")
	var n := (e as Array).size()
	if not told is Array or (told as Array).size() != n:
		return "story_order: told lists every event once"
	var seen := {}
	for i: Variant in told:
		if not L._whole(i) or int(i) < 0 or int(i) >= n or seen.has(int(i)):
			return "story_order: told lists every event once"
		seen[int(i)] = true
	if p.has("flash") and (not L._whole(p.flash) or int(p.flash) < 0 or int(p.flash) >= n):
		return "story_order: flash is an event's index"
	return L._flags_problem(p, ["names"])


# --- Drawing ------------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"parabola":
			_draw_parabola(pic, font, r, d)
		"trig_triangle":
			_draw_trig(pic, font, r, d)
		"fluid_pressure":
			_draw_fluid(pic, font, r, d)
		"energy_meter":
			_draw_meter(pic, font, r, d)
		"energy_profile":
			_draw_profile(pic, font, r, d)
		"meter_circuit":
			_draw_circuit(pic, font, r, d)
		"plant_transport":
			_draw_plant(pic, font, r, d)
		"heart_chambers":
			_draw_heart(pic, font, r, d)
		"air_sac":
			_draw_sac(pic, font, r, d)
		"gene_transfer":
			_draw_gene(pic, font, r, d)
		"slide_design":
			_draw_slide(pic, font, r, d)
		"story_order":
			_draw_story(pic, font, r, d)


## A number as the lessons write it: −4, 2.5, 1,200.
static func _num(v: float) -> String:
	var neg := v < -0.0000001
	var t := ""
	if is_equal_approx(v, roundf(v)):
		t = GenKit.fmt(absi(roundi(v)))
	else:
		t = ("%.2f" % absf(v)).rstrip("0").rstrip(".")
	return ("−" if neg else "") + t


static func _dashed(ci: CanvasItem, from: Vector2, to: Vector2, colour: Color, width: float, dash: float = 7.0) -> void:
	var length := from.distance_to(to)
	if length < 1.0:
		return
	var dir := (to - from) / length
	var t := 0.0
	while t < length:
		ci.draw_line(from + dir * t, from + dir * minf(t + dash, length), colour, width, true)
		t += dash * 2.0


## Mark (an orange ring) on an unlabelled diagram's part, or every part's label in the bands.
static func _finish_diagram(ci: CanvasItem, font: Font, r: Rect2, a: Rect2, d: Dictionary) -> void:
	if d.has("mark") and not bool(d.get("labels", false)):
		var at: Vector2 = _anchors(d, a).get(str(d.mark), Vector2(-1, -1))
		if at.x >= 0.0:
			ci.draw_arc(at, a.size.y * 0.09, 0.0, TAU, 28, ORANGE, 3.5)
	if bool(d.get("labels", false)):
		L._label_parts(ci, font, r, d, _anchors(d, a), L._fs(r, 12.0))


## A word or two on a diagram (not when its parts are labelled or pinned: then the bands name them).
static func _plain(d: Dictionary) -> bool:
	return not bool(d.get("labels", false)) and not bool(d.get("pins", false))


static func _double_arrow(ci: CanvasItem, from: Vector2, to: Vector2, colour: Color, width: float) -> void:
	var mid := from.lerp(to, 0.5)
	L._arrow(ci, mid, from, colour, width)
	L._arrow(ci, mid, to, colour, width)


# --- A parabola -------------------------------------------------------------------------------------------------------

static func _gx(plot: Rect2, lo: float, hi: float, x: float) -> float:
	return plot.position.x + (x - lo) / (hi - lo) * plot.size.x


static func _gy(plot: Rect2, y0: float, y1: float, y: float) -> float:
	return plot.end.y - (y - y0) / (y1 - y0) * plot.size.y


static func _draw_parabola(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := L._fs(r)
	var lo := float(d.get("from", -5))
	var hi := float(d.get("to", 5))
	var y0 := 0.0
	var y1 := 0.0
	for k in 121:
		var y := parabola_y(d, lerpf(lo, hi, k / 120.0))
		y0 = minf(y0, y)
		y1 = maxf(y1, y)
	var step := 1.0
	for s: float in [1.0, 2.0, 5.0, 10.0, 20.0]:
		step = s
		if (y1 - y0) / s <= 10.0:
			break
	y0 = floorf(y0 / step) * step
	y1 = ceilf(y1 / step) * step
	if is_equal_approx(y0, y1):
		y1 += step
	var nf := maxi(fs - 3, 8)
	var left := L._text_w(font, "−30", nf) + 8.0
	var plot := Rect2(r.position + Vector2(left, fs * 0.5), r.size - Vector2(left + fs * 0.5, fs * 1.3))
	ci.draw_rect(plot, Color.WHITE)
	for xi in range(int(lo), int(hi) + 1):
		var gx := _gx(plot, lo, hi, float(xi))
		ci.draw_line(Vector2(gx, plot.position.y), Vector2(gx, plot.end.y), PALE.darkened(0.08), 1.0)
	var yv := y0
	while yv <= y1 + 0.001:
		var gy := _gy(plot, y0, y1, yv)
		ci.draw_line(Vector2(plot.position.x, gy), Vector2(plot.end.x, gy), PALE.darkened(0.08), 1.0)
		L._say_from(ci, font, Vector2(plot.position.x - 4.0, gy), _num(yv), nf, INK, true, false)
		yv += step
	var ax := _gy(plot, y0, y1, 0.0)
	ci.draw_line(Vector2(plot.position.x, ax), Vector2(plot.end.x, ax), INK, 2.0)
	if lo <= 0.0 and hi >= 0.0:
		var zx := _gx(plot, lo, hi, 0.0)
		ci.draw_line(Vector2(zx, plot.position.y), Vector2(zx, plot.end.y), INK, 2.0)
	var xstep := 1 if hi - lo <= 10.0 else 2
	for xi in range(int(lo), int(hi) + 1):
		if xi == 0 or (xi - int(lo)) % xstep != 0:
			continue
		var ty := clampf(ax + nf * 0.85, plot.position.y + nf * 0.6, plot.end.y + nf * 0.7)
		L._say(ci, font, Vector2(_gx(plot, lo, hi, float(xi)), ty), _num(float(xi)), nf, INK)
	if bool(d.get("axis", false)):
		var vx := _gx(plot, lo, hi, vertex(d).x)
		_dashed(ci, Vector2(vx, plot.position.y), Vector2(vx, plot.end.y), ORANGE, 2.0)
	var seg := PackedVector2Array()
	for k in 161:
		var x := lerpf(lo, hi, k / 160.0)
		var y := parabola_y(d, x)
		if y < y0 - 0.0001 or y > y1 + 0.0001:
			if seg.size() > 1:
				ci.draw_polyline(seg, BLUE, 3.0, true)
			seg = PackedVector2Array()
			continue
		seg.append(Vector2(_gx(plot, lo, hi, x), _gy(plot, y0, y1, y)))
	if seg.size() > 1:
		ci.draw_polyline(seg, BLUE, 3.0, true)
	var dot_r := maxf(4.0, fs * 0.32)
	for x: Variant in d.get("points", []):
		var y := parabola_y(d, float(x))
		if y >= y0 and y <= y1:
			var at := Vector2(_gx(plot, lo, hi, float(x)), _gy(plot, y0, y1, y))
			ci.draw_circle(at, dot_r, ORANGE)
			L._say_from(ci, font, at + Vector2(dot_r + 3.0, -nf * 0.7), "(%s, %s)" % [_num(float(x)), _num(y)], nf)
	if bool(d.get("roots", false)):
		for x in roots(d):
			if x >= lo and x <= hi:
				var at := Vector2(_gx(plot, lo, hi, x), ax)
				ci.draw_circle(at, dot_r, RED)
				ci.draw_arc(at, dot_r + 3.0, 0.0, TAU, 20, RED, 2.0)
	if bool(d.get("vertex", false)):
		var v := vertex(d)
		if v.y >= y0 and v.y <= y1 and v.x >= lo and v.x <= hi:
			var at := Vector2(_gx(plot, lo, hi, v.x), _gy(plot, y0, y1, v.y))
			ci.draw_circle(at, dot_r, GREEN)
			L._say_from(ci, font, at + Vector2(dot_r + 4.0, -nf * 0.8 if _abc(d).x > 0 else nf * 0.8),
				"(%s, %s)" % [_num(v.x), _num(v.y)], nf, GREEN.darkened(0.35))
	if bool(d.get("equation", true)):
		var t := equation(d)
		var w := L._text_w(font, t, fs) + 12.0
		var box := Rect2(plot.position + Vector2(4, 4), Vector2(w, fs * 1.5))
		if _abc(d).x < 0:
			box.position.y = plot.end.y - box.size.y - 4.0
		L._box(ci, box, SOFT, ORANGE, 5, 1)
		L._say(ci, font, box.get_center(), t, fs, INK, false)
	ci.draw_rect(plot, INK, false, 1.5)


# --- A right-angled triangle --------------------------------------------------------------------------------------------

## The triangle in the diagram box: its corners (A bottom left, B the right angle, C top right), the marked corner and
## where its angle's name goes, and each side's middle by its name from the marked angle.
static func _trig_geo(p: Dictionary, a: Rect2) -> Dictionary:
	var region := L._sub(a, 0.16, 0.1, 0.8, 0.84)
	var top := str(p.get("at", "left")) == "top"
	var base_deg := float(p.angle) if not top else 90.0 - float(p.angle)
	var t := tan(deg_to_rad(base_deg))
	var base := minf(region.size.x, region.size.y / t)
	var height := base * t
	var left := region.position.x + (region.size.x - base) * 0.5
	var bottom := region.position.y + (region.size.y + height) * 0.5
	var A := Vector2(left, bottom)
	var B := Vector2(left + base, bottom)
	var C := Vector2(left + base, bottom - height)
	var M := C if top else A
	var d1 := (B - M).normalized()
	var d2 := (A - C).normalized() if top else (C - A).normalized()
	var bis := (d1 + d2).normalized()
	var s := clampf(minf(base, height) * 0.14, 7.0, 16.0)
	var mids := {"hyp": (A + C) * 0.5}
	mids["opp"] = (A + B) * 0.5 if top else (B + C) * 0.5
	mids["adj"] = (B + C) * 0.5 if top else (A + B) * 0.5
	var ends := {"hyp": [A, C]}
	ends["opp"] = [A, B] if top else [B, C]
	ends["adj"] = [B, C] if top else [A, B]
	var arc_r := clampf(minf(base, height) * 0.28, 12.0, 30.0)
	return {"A": A, "B": B, "C": C, "M": M, "d1": d1, "d2": d2, "s": s, "arc": arc_r,
		"mark_at": M + bis * (arc_r + 9.0), "mids": mids, "ends": ends, "centre": (A + B + C) / 3.0}


static func _draw_trig(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var a := _diagram_box(d, r)
	var g := _trig_geo(d, a)
	var fs := L._fs(r)
	var A: Vector2 = g.A
	var B: Vector2 = g.B
	var C: Vector2 = g.C
	var scene := str(d.get("scene", ""))
	if scene != "":
		ci.draw_line(Vector2(a.position.x, B.y), Vector2(a.end.x, B.y), Color("8a6a3a"), 3.0)
	if scene == "ladder":
		var wall := Rect2(Vector2(B.x, a.position.y + a.size.y * 0.02), Vector2(a.size.x * 0.05, B.y - a.position.y
			- a.size.y * 0.02))
		ci.draw_rect(wall, Color("c9735a"))
		var yy := wall.position.y
		while yy < wall.end.y:
			ci.draw_line(Vector2(wall.position.x, yy), Vector2(wall.end.x, yy), Color("f3d9c9"), 1.0)
			yy += 9.0
	if scene == "ramp":
		L._poly(ci, [A, B, C], WOOD.lightened(0.35), INK, 0.0)
	elif scene == "":
		L._poly(ci, [A, B, C], PALE, INK, 0.0)
	var mark := str(d.get("mark", ""))
	var mids: Dictionary = g.mids
	var ends: Dictionary = g.ends
	for side: String in TRIG_SIDES:
		var e: Array = ends[side]
		ci.draw_line(e[0], e[1], ORANGE if mark == side else INK, 5.0 if mark == side else 2.5, true)
	if scene == "ladder":
		var along := (C - A).normalized()
		var off := Vector2(-along.y, along.x) * 4.0
		var rail := Color("8a5a2a")
		ci.draw_line(A + off, C + off, rail, 3.0, true)
		ci.draw_line(A - off, C - off, rail, 3.0, true)
		var n := int(A.distance_to(C) / 14.0)
		for k in range(1, n):
			var q := A.lerp(C, float(k) / n)
			ci.draw_line(q + off * 1.6, q - off * 1.6, rail, 2.0, true)
	var s: float = g.s
	ci.draw_polyline(PackedVector2Array([B + Vector2(-s, 0), B + Vector2(-s, -s), B + Vector2(0, -s)]), INK, 2.0)
	var M: Vector2 = g.M
	var d1: Vector2 = g.d1
	var d2: Vector2 = g.d2
	var a1 := d1.angle()
	var a2 := d2.angle()
	if absf(a2 - a1) > PI:
		a2 += TAU if a2 < a1 else -TAU
	ci.draw_arc(M, float(g.arc), minf(a1, a2), maxf(a1, a2), 18, ORANGE, 2.5, true)
	if _plain(d):
		var label := str(d.get("angle_label", "x"))
		if str(d.get("hide", "")) == "angle x":
			label = "?"
		if scene != "":
			var lw := L._text_w(font, label, fs)
			var mat: Vector2 = g.mark_at
			L._box(ci, Rect2(mat - Vector2(lw * 0.5 + 4.0, fs * 0.75), Vector2(lw + 8.0, fs * 1.5)), Color.WHITE, GREY, 4, 1)
		L._say(ci, font, g.mark_at, label, fs, ORANGE.darkened(0.25) if label == "?" else INK)
		var sides: Dictionary = d.get("sides", {})
		var centre: Vector2 = g.centre
		for side: String in TRIG_SIDES:
			var words := ""
			if sides.has(side):
				words = str(sides[side])
			if bool(d.get("names", false)):
				words = str(TRIG_NAMES[side]) if words == "" else "%s %s" % [TRIG_NAMES[side], words]
			if words == "":
				continue
			var m: Vector2 = mids[side]
			var out := (m - centre).normalized()
			var f := L._fit(font, words, fs, a.size.x * 0.5)
			var w := L._text_w(font, words, f)
			var at := m + out * (f * 0.85 + absf(out.x) * w * 0.5)
			var colour := ORANGE.darkened(0.25) if mark == side or words.ends_with("?") else INK
			if scene != "":   # over a wall, a ladder or the ground: on a card of its own
				L._box(ci, Rect2(at - Vector2(w * 0.5 + 4.0, f * 0.75), Vector2(w + 8.0, f * 1.5)), Color.WHITE, GREY, 4, 1)
			L._say(ci, font, at, words, f, colour)
	_finish_diagram(ci, font, r, a, d)


# --- Pressure in solids, liquids and gases -----------------------------------------------------------------------------

static func _draw_fluid(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var a := _diagram_box(d, r)
	var fs := L._fs(r)
	var view := str(d.view)
	var words: String = FLUID_WORDS[view]
	match view:
		"faces":
			ci.draw_rect(L._sub(a, 0.0, 0.62, 1.0, 1.0), SAND)
			L._poly(ci, L._pts(a, [Vector2(0.16, 0.62), Vector2(0.2, 0.745), Vector2(0.3, 0.745), Vector2(0.34, 0.62)]),
				SAND.darkened(0.18), INK, 0.0)
			L._poly(ci, L._pts(a, [Vector2(0.52, 0.62), Vector2(0.55, 0.668), Vector2(0.85, 0.668), Vector2(0.88, 0.62)]),
				SAND.darkened(0.18), INK, 0.0)
			ci.draw_line(L._at(a, 0.0, 0.62), L._at(a, 0.16, 0.62), INK, 1.5)
			ci.draw_line(L._at(a, 0.34, 0.62), L._at(a, 0.52, 0.62), INK, 1.5)
			ci.draw_line(L._at(a, 0.88, 0.62), L._at(a, 1.0, 0.62), INK, 1.5)
			var brick := Color("b5533c")
			L._box(ci, L._sub(a, 0.2, 0.2, 0.3, 0.745), brick, INK, 3, 2)
			L._box(ci, L._sub(a, 0.55, 0.5, 0.85, 0.668), brick, INK, 3, 2)
			L._arrow(ci, L._at(a, 0.25, 0.02), L._at(a, 0.25, 0.18), INK, 3.0)
			L._arrow(ci, L._at(a, 0.7, 0.3), L._at(a, 0.7, 0.48), INK, 3.0)
			if _plain(d):
				L._say_from(ci, font, L._at(a, 0.28, 0.08), "a force", fs - 2)
				L._say_from(ci, font, L._at(a, 0.73, 0.38), "the same force", fs - 2)
		"spouts":
			ci.draw_line(L._at(a, 0.0, 0.97), L._at(a, 1.0, 0.97), Color("8a6a3a"), 3.0)
			ci.draw_rect(L._sub(a, 0.08, 0.53, 0.1, 0.97), WOOD)
			ci.draw_rect(L._sub(a, 0.26, 0.53, 0.28, 0.97), WOOD)
			ci.draw_rect(L._sub(a, 0.05, 0.52, 0.31, 0.55), WOOD.darkened(0.2))
			ci.draw_rect(L._sub(a, 0.06, 0.1, 0.3, 0.52), WATER)
			ci.draw_rect(L._sub(a, 0.06, 0.04, 0.3, 0.52), INK, false, 2.5)
			for k in 3:
				var hy := 0.24 + 0.12 * k
				var depth := hy - 0.1
				var drop := 0.97 - hy
				var pts := PackedVector2Array()
				for i in 25:
					var yy := drop * i / 24.0
					pts.append(L._at(a, 0.3, hy) + Vector2(2.0 * sqrt(depth * yy) * a.size.y, yy * a.size.y))
				ci.draw_polyline(pts, BLUE, 3.0, true)
				ci.draw_circle(L._at(a, 0.3, hy), 3.0, INK)
		"dam":
			L._poly(ci, L._pts(a, [Vector2(0.0, 0.2), Vector2(0.5, 0.2), Vector2(0.5, 0.92), Vector2(0.0, 0.92)]), WATER,
				INK, 0.0)
			ci.draw_line(L._at(a, 0.0, 0.2), L._at(a, 0.5, 0.2), BLUE, 2.0)
			L._poly(ci, L._pts(a, [Vector2(0.5, 0.12), Vector2(0.57, 0.12), Vector2(0.78, 0.92), Vector2(0.5, 0.92)]),
				Color("c5c9cf"), INK, 2.0)
			ci.draw_rect(L._sub(a, 0.0, 0.92, 1.0, 1.0), Color("b98a5a"))
			ci.draw_line(L._at(a, 0.82, 0.9), L._at(a, 1.0, 0.9), BLUE, 3.0)
			for y: float in [0.32, 0.47, 0.62, 0.77, 0.88]:
				var length := (y - 0.2) * 0.42
				L._arrow(ci, L._at(a, 0.49 - length, y), L._at(a, 0.49, y), INK, 2.5)
		"float":
			ci.draw_rect(L._sub(a, 0.05, 0.45, 0.95, 0.86), WATER)
			ci.draw_polyline(PackedVector2Array(L._pts(a, [Vector2(0.05, 0.2), Vector2(0.05, 0.86), Vector2(0.95, 0.86),
				Vector2(0.95, 0.2)])), INK, 2.5)
			ci.draw_line(L._at(a, 0.05, 0.45), L._at(a, 0.95, 0.45), BLUE, 2.0)
			if bool(d.get("floats", true)):
				L._box(ci, L._sub(a, 0.39, 0.3, 0.61, 0.6), WOOD, INK, 3, 2)
				ci.draw_rect(L._sub(a, 0.39, 0.45, 0.61, 0.6), Color(WATER, 0.45))
				L._arrow(ci, L._at(a, 0.5, 0.45), L._at(a, 0.5, 0.08), BLUE.darkened(0.2), 4.0)
				L._arrow(ci, L._at(a, 0.5, 0.45), L._at(a, 0.5, 0.82), INK, 4.0)
				if _plain(d):
					L._say_from(ci, font, L._at(a, 0.53, 0.14), "upthrust", fs - 1, BLUE.darkened(0.3))
					L._say_from(ci, font, L._at(a, 0.53, 0.76), "weight", fs - 1)
			else:
				words = SINK_WORDS
				L._poly(ci, L._pts(a, [Vector2(0.42, 0.62), Vector2(0.5, 0.57), Vector2(0.59, 0.6), Vector2(0.6, 0.7),
					Vector2(0.52, 0.75), Vector2(0.41, 0.72)]), GREY, INK, 2.0)
				L._arrow(ci, L._at(a, 0.5, 0.66), L._at(a, 0.5, 0.5), BLUE.darkened(0.2), 4.0)
				L._arrow(ci, L._at(a, 0.5, 0.66), L._at(a, 0.5, 0.98), INK, 4.0)
				if _plain(d):
					L._say_from(ci, font, L._at(a, 0.62, 0.52), "upthrust", fs - 1, BLUE.darkened(0.3))
					L._say_from(ci, font, L._at(a, 0.53, 0.92), "weight", fs - 1)
	if _plain(d) and bool(d.get("words", true)):
		var at := L._at(a, 0.5, 0.95)
		match view:
			"spouts":
				at = L._at(a, 0.66, 0.08)
			"dam":
				at = L._at(a, 0.8, 0.07)
			"float":
				at = L._at(a, 0.5, 0.95 if bool(d.get("floats", true)) else 0.08)
		var room := a.size.x * (0.62 if view == "spouts" else (0.4 if view == "dam" else 0.95))
		if view == "dam":
			L._text_in(ci, font, Rect2(at - Vector2(room * 0.5, fs * 0.3), Vector2(room, fs * 2.6)), words, fs - 2)
		else:
			L._say(ci, font, at, words, L._fit(font, words, fs - 1, room))
	_finish_diagram(ci, font, r, a, d)


# --- An electricity meter ---------------------------------------------------------------------------------------------

static func _draw_meter(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var readings: Array = d.readings
	var n := readings.size()
	var fs := L._fs(r)
	var gap := r.size.x * 0.06
	var w := (r.size.x - gap * (n - 1)) / n
	var unit := str(d.get("unit", "kWh"))
	for i in n:
		var cell := Rect2(r.position + Vector2(i * (w + gap), 0), Vector2(w, r.size.y))
		var marked := d.has("mark") and int(d.mark) == i
		var body := Rect2(cell.position + Vector2(0, fs * 1.6), Vector2(cell.size.x, cell.size.y - fs * 1.6))
		L._box(ci, body, Color("e7e9ee"), ORANGE if marked else INK, 10, 3 if marked else 2)
		L._say(ci, font, cell.position + Vector2(cell.size.x * 0.5, fs * 0.7), str(readings[i][0]), fs,
			ORANGE.darkened(0.2) if marked else INK)
		var digits := str(readings[i][1])
		var k := digits.length()
		var uw := L._text_w(font, unit, fs) + 10.0
		var dw := minf((body.size.x - uw - 24.0) / k, body.size.y * 0.4)
		var dh := dw * 1.45
		var start := body.position + Vector2((body.size.x - uw - dw * k) * 0.5, body.size.y * 0.4 - dh * 0.5)
		ci.draw_rect(Rect2(start - Vector2(4, 4), Vector2(dw * k + 8, dh + 8)), INK)
		for j in k:
			var box := Rect2(start + Vector2(j * dw + 1.5, 0), Vector2(dw - 3.0, dh))
			ci.draw_rect(box, Color("2b2f3a"))
			L._say(ci, font, box.get_center(), digits[j], int(dh * 0.62), Color.WHITE, false)
		L._say_from(ci, font, start + Vector2(dw * k + 10.0, dh * 0.5), unit, fs)
		var dial := body.position + Vector2(body.size.x * 0.5, body.size.y * 0.82)
		ci.draw_circle(dial, minf(body.size.y * 0.08, 9.0), RED)


# --- An energy level diagram ------------------------------------------------------------------------------------------

static func _profile_geo(p: Dictionary, a: Rect2) -> Dictionary:
	var exo := str(p.type) == "exo"
	var yr := a.position.y + a.size.y * (0.4 if exo else 0.74)
	var yp := a.position.y + a.size.y * (0.74 if exo else 0.4)
	var peak := a.position.y + a.size.y * 0.13 if bool(p.get("hump", true)) else minf(yr, yp)
	return {"yr": yr, "yp": yp, "peak": peak}


static func _draw_profile(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var a := _diagram_box(d, r)
	var fs := L._fs(r)
	var g := _profile_geo(d, a)
	var yr: float = g.yr
	var yp: float = g.yp
	var peak: float = g.peak
	var exo := str(d.type) == "exo"
	var hump := bool(d.get("hump", true))
	L._arrow(ci, L._at(a, 0.06, 0.92), L._at(a, 0.06, 0.02), INK, 2.0)
	ci.draw_line(L._at(a, 0.06, 0.92), L._at(a, 1.0, 0.92), INK, 2.0)
	L._say_from(ci, font, L._at(a, 0.08, 0.04), "energy", fs - 2)
	var along := "progress of the reaction"
	L._say(ci, font, L._at(a, 0.55, 0.975), along, L._fit(font, along, fs - 3, a.size.x * 0.6))
	var pts := PackedVector2Array()
	for k in 61:
		var f := lerpf(0.1, 0.9, k / 60.0)
		var y := yr
		if not hump:
			y = yr if f <= 0.4 else (yp if f >= 0.6 else lerpf(yr, yp, (f - 0.4) / 0.2))
		elif f > 0.3 and f <= 0.47:
			y = yr + (peak - yr) * (1.0 - cos(PI * (f - 0.3) / 0.17)) * 0.5
		elif f > 0.47 and f <= 0.66:
			y = peak + (yp - peak) * (1.0 - cos(PI * (f - 0.47) / 0.19)) * 0.5
		elif f > 0.66:
			y = yp
		pts.append(Vector2(a.position.x + a.size.x * f, y))
	ci.draw_polyline(pts, BLUE, 3.0, true)
	var x30 := a.position.x + a.size.x * 0.3
	var x90 := a.position.x + a.size.x * 0.9
	var x95 := a.position.x + a.size.x * 0.95
	var x97 := a.position.x + a.size.x * 0.97
	_dashed(ci, Vector2(x30, yr), Vector2(x97, yr), GREY, 1.5, 5.0)
	ci.draw_line(Vector2(x90, yp), Vector2(x97, yp), BLUE, 2.0)
	_double_arrow(ci, Vector2(x95, yr), Vector2(x95, yp), ORANGE, 2.5)
	if hump:
		var x33 := a.position.x + a.size.x * 0.33
		L._arrow(ci, Vector2(x33, yr), Vector2(x33, peak + 2.0), GREEN, 2.5)
	if not _plain(d):
		_finish_diagram(ci, font, r, a, d)
		return
	var vals: Array = d.get("values", [])
	var hidden := str(d.get("hide", "")) == "change"
	var rn := str(d.get("reactants", "reactants"))
	var pn := str(d.get("products", "products"))
	if vals.size() == 2:
		rn += ": %s kJ" % _num(float(vals[0]))
		pn += ": %s kJ" % _num(float(vals[1]))
	L._say(ci, font, Vector2(a.position.x + a.size.x * 0.2, yr + fs * 0.9), rn, L._fit(font, rn, fs - 1, a.size.x * 0.3),
		INK, false)
	L._say(ci, font, Vector2(a.position.x + a.size.x * 0.78, yp + fs * 0.9), pn, L._fit(font, pn, fs - 1, a.size.x * 0.28),
		INK, false)
	if bool(d.get("names", true)) or vals.size() == 2 or hidden:
		var said := "energy given out" if exo else "energy taken in"
		var amount := ""
		if vals.size() == 2:
			amount = "%s kJ" % _num(absf(float(vals[0]) - float(vals[1])))
		if hidden:
			said = "?"
			amount = ""
		var f := L._fit(font, said, fs - 2, a.size.x * 0.27)
		var cy := (yr + yp) * 0.5
		var tx := a.position.x + a.size.x * 0.93
		var colour := ORANGE.darkened(0.3)
		if amount == "":
			L._say_from(ci, font, Vector2(tx, cy), said, f, colour, true, false)
		else:
			L._say_from(ci, font, Vector2(tx, cy - f * 0.6), said, f, colour, true, false)
			L._say_from(ci, font, Vector2(tx, cy + f * 0.6), amount, f, colour, true, false)
	if bool(d.get("names", true)) and hump:
		var fa := L._fit(font, "activation", fs - 2, a.size.x * 0.21)
		var ay := (yr + peak) * 0.5
		var ax := a.position.x + a.size.x * 0.31
		L._say_from(ci, font, Vector2(ax, ay - fa * 0.6), "activation", fa, GREEN.darkened(0.35), true, false)
		L._say_from(ci, font, Vector2(ax, ay + fa * 0.6), "energy", fa, GREEN.darkened(0.35), true, false)
	_finish_diagram(ci, font, r, a, d)


# --- A circuit with meters --------------------------------------------------------------------------------------------

## A meter: a circle with its letter, and its reading beside it (right of it, or left when `left`), `beside` further
## out (past a voltmeter's wires).
static func _meter(ci: CanvasItem, font: Font, c: Vector2, rad: float, m: Array, fs: int, left: bool = false,
		beside: float = 0.0) -> void:
	ci.draw_circle(c, rad, Color.WHITE)
	ci.draw_arc(c, rad, 0.0, TAU, 24, INK, 2.5)
	L._say(ci, font, c, str(m[0]), maxi(int(rad * 1.1), 8), INK, false)
	if m.size() > 2:
		var t := "?" if str(m[2]) == "?" else "%s %s" % [_num(float(m[2])), m[0]]
		var colour := ORANGE.darkened(0.2) if t == "?" else INK
		if left:
			L._say_from(ci, font, c - Vector2(rad + 4.0 + beside, 0), t, fs, colour, true)
		else:
			L._say_from(ci, font, c + Vector2(rad + 4.0 + beside, 0), t, fs, colour)


static func _gap_less(p: Array, q: Array) -> bool:
	return float(p[0]) < float(q[0])


## A horizontal wire from x0 to x1 at y, broken where a symbol sits ([centre x, half width], …).
static func _wire(ci: CanvasItem, x0: float, x1: float, y: float, gaps: Array) -> void:
	var cuts: Array = gaps.duplicate()
	cuts.sort_custom(_gap_less)
	var x := x0
	for g: Array in cuts:
		var gx := float(g[0])
		var half := float(g[1])
		if gx - half > x:
			ci.draw_line(Vector2(x, y), Vector2(gx - half, y), L.WIRE, 2.5)
		x = maxf(x, gx + half)
	if x1 > x:
		ci.draw_line(Vector2(x, y), Vector2(x1, y), L.WIRE, 2.5)


## A voltmeter at `c` joined across the stretch of wire from x - half to x + half at y.
static func _across(ci: CanvasItem, x: float, half: float, y: float, c: Vector2, rad: float) -> void:
	ci.draw_polyline(PackedVector2Array([Vector2(x - half, y), Vector2(x - half, c.y), c - Vector2(rad, 0)]), L.WIRE, 2.0)
	ci.draw_polyline(PackedVector2Array([Vector2(x + half, y), Vector2(x + half, c.y), c + Vector2(rad, 0)]), L.WIRE, 2.0)


static func _part_words(part: Array) -> String:
	return "%s, %s ohms" % [part[0], _num(float(part[1]))] if part.size() > 1 else str(part[0])


static func _draw_circuit(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := L._fs(r)
	var parts: Array = d.parts
	var meters: Array = d.get("meters", [])
	var n := parts.size()
	var volts := "%s V" % _num(float(d.volts))
	if str(d.layout) == "series":
		var loop := L._sub(r, 0.1, 0.34, 0.9, 0.74)
		var s := minf(loop.size.x / (n + 1) * 0.75, r.size.y * 0.24)
		var rad := s * 0.24
		var gaps: Array = []
		var xs: Array[float] = []
		for k in n:
			xs.append(loop.position.x + loop.size.x * (k + 1) / (n + 1))
			gaps.append([xs[k], s * 0.55])
		_wire(ci, loop.position.x, loop.end.x, loop.position.y, gaps)
		var cx := loop.get_center().x
		_wire(ci, loop.position.x, loop.end.x, loop.end.y, [[cx, s * 0.55]])
		ci.draw_line(loop.position, Vector2(loop.position.x, loop.end.y), L.WIRE, 2.5)
		ci.draw_line(Vector2(loop.end.x, loop.position.y), loop.end, L.WIRE, 2.5)
		for k in n:
			L._symbol(ci, font, Vector2(xs[k], loop.position.y), s, 1.0, str(parts[k][0]), false, true)
			if bool(d.get("names", false)):
				var room := loop.size.x / (n + 1) * 0.95
				var said: Array = [str(parts[k][0])]
				if (parts[k] as Array).size() > 1:
					said.append("%s ohms" % _num(float(parts[k][1])))
				for j in said.size():
					var t := str(said[j])
					L._say(ci, font, Vector2(xs[k], loop.position.y + s * 0.4 + fs * (0.5 + j * 1.05)), t, L._fit(font, t,
						fs - 2, room), INK, false)
		L._symbol(ci, font, Vector2(cx, loop.end.y), s, 1.0, "cell", false, true)
		L._say_from(ci, font, Vector2(cx - s * 0.6, loop.end.y - fs * 0.75), volts, fs - 1, INK, true)
		for m: Array in meters:
			var where := str(m[1])
			if str(m[0]) == "A":
				_meter(ci, font, Vector2(loop.position.x, loop.get_center().y), rad, m, fs - 1)
			elif where == "cell":
				var c := Vector2(cx, loop.end.y + r.size.y * 0.17)
				_across(ci, cx, s * 0.75, loop.end.y, c, rad)
				_meter(ci, font, c, rad, m, fs - 1, false, s * 0.75 - rad)
			else:
				var px: float = xs[where.to_int()]
				var c := Vector2(px, loop.position.y - r.size.y * 0.19)
				_across(ci, px, s * 0.7, loop.position.y, c, rad)
				_meter(ci, font, c, rad, m, fs - 1, false, s * 0.7 - rad)
		return
	# Parallel: branches between two rails, the cell on the bottom wire.
	var x0 := r.position.x + r.size.x * 0.17
	var x1 := r.end.x - r.size.x * 0.06
	var yb := r.end.y - r.size.y * 0.16
	var top := r.position.y + r.size.y * 0.06
	var band := (yb - top - r.size.y * 0.14) / n
	var s := minf(band * 0.95, (x1 - x0) * 0.22)
	var rad := clampf(band * 0.2, 7.0, maxf(7.0, s * 0.26))
	var has_v := {}
	for m: Array in meters:
		if str(m[0]) == "V" and str(m[1]) != "cell":
			has_v[str(m[1]).to_int()] = true
	var px := (x0 + x1) * 0.5 + (x1 - x0) * 0.1
	var ax := x0 + (x1 - x0) * 0.2
	var ys: Array[float] = []
	for k in n:
		ys.append(top + band * k + (band * 0.3 if has_v.has(k) else band * 0.5))
	for k in n:
		var gaps: Array = [[px, s * 0.55]]
		for m: Array in meters:
			if str(m[0]) == "A" and str(m[1]) == str(k):
				gaps.append([ax, rad])
		_wire(ci, x0, x1, ys[k], gaps)
		L._symbol(ci, font, Vector2(px, ys[k]), s, 1.0, str(parts[k][0]), false, true)
		if bool(d.get("names", false)):
			var t := _part_words(parts[k])
			L._say_from(ci, font, Vector2(px + s * 0.6, ys[k] - fs * 0.75), t, L._fit(font, t, fs - 3, x1 - px - s * 0.6))
		for m: Array in meters:
			if str(m[0]) == "A" and str(m[1]) == str(k):   # its reading above it, off the wire
				_meter(ci, font, Vector2(ax, ys[k]), rad, [m[0], m[1]], fs - 2)
				if m.size() > 2:
					var t := "?" if str(m[2]) == "?" else "%s A" % _num(float(m[2]))
					L._say_from(ci, font, Vector2(ax + rad * 0.6, ys[k] - rad - fs * 0.45), t, fs - 2,
						ORANGE.darkened(0.2) if t == "?" else INK)
			elif str(m[0]) == "V" and str(m[1]) == str(k):
				var c := Vector2(px, ys[k] + band * 0.44)
				_across(ci, px, s * 0.7, ys[k], c, rad)
				_meter(ci, font, c, rad, m, fs - 2, false, s * 0.7 - rad)
	var cx := (x0 + x1) * 0.5
	ci.draw_line(Vector2(x0, ys[0]), Vector2(x0, yb), L.WIRE, 2.5)
	ci.draw_line(Vector2(x1, ys[0]), Vector2(x1, yb), L.WIRE, 2.5)
	var cs := minf(s, r.size.y * 0.22)
	_wire(ci, x0, x1, yb, [[cx, cs * 0.55]])
	L._symbol(ci, font, Vector2(cx, yb), cs, 1.0, "cell", false, true)
	var cell_v := false
	for m: Array in meters:
		cell_v = cell_v or (str(m[0]) == "V" and str(m[1]) == "cell")
	if cell_v:   # a voltmeter across the cell below it: the cell's voltage above it
		L._say(ci, font, Vector2(cx, yb - cs * 0.45 - fs * 0.4), volts, fs - 1)
	else:
		L._say(ci, font, Vector2(cx, yb + cs * 0.45 + fs * 0.45), volts, fs - 1)
	var my := (ys[n - 1] + yb) * 0.5
	for m: Array in meters:
		if str(m[0]) == "A" and str(m[1]) == "main":
			_meter(ci, font, Vector2(x0, my), rad, m, fs - 2, true)
		elif str(m[0]) == "V" and str(m[1]) == "cell":
			var c := Vector2(cx, minf(yb + cs * 0.55, r.end.y - rad - 1.0))
			_across(ci, cx, cs * 0.75, yb, c, rad)
			_meter(ci, font, c, rad, m, fs - 2, false, cs * 0.75 - rad)


# --- Transport in a plant ---------------------------------------------------------------------------------------------

static func _draw_plant(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var a := _diagram_box(d, r)
	var fs := L._fs(r)
	var show := str(d.get("show", "both"))
	var flows := bool(d.get("flows", true))
	ci.draw_rect(L._sub(a, 0.0, 0.0, 1.0, 0.76), SKY)
	ci.draw_rect(L._sub(a, 0.0, 0.76, 1.0, 1.0), Color("b98a5a"))
	for end: Vector2 in [Vector2(0.3, 0.95), Vector2(0.42, 0.98), Vector2(0.58, 0.98), Vector2(0.7, 0.94)]:
		ci.draw_line(L._at(a, 0.5, 0.76), L._at(a, end.x, end.y), Color("e8d9b0"), 3.0, true)
	for k in 9:
		var q := L._at(a, 0.5, 0.76).lerp(L._at(a, 0.3, 0.95), 0.45 + k * 0.06)
		ci.draw_line(q, q + Vector2(-5, -5), Color("f4ecd3"), 1.5)
		ci.draw_line(q, q + Vector2(5, -6), Color("f4ecd3"), 1.5)
	L._poly(ci, L._pts(a, [Vector2(0.5, 0.36), Vector2(0.38, 0.22), Vector2(0.2, 0.2), Vector2(0.1, 0.27),
		Vector2(0.22, 0.33), Vector2(0.38, 0.35)]), LEAF, INK, 1.5)
	L._poly(ci, L._pts(a, [Vector2(0.5, 0.43), Vector2(0.62, 0.3), Vector2(0.8, 0.28), Vector2(0.9, 0.34),
		Vector2(0.78, 0.4), Vector2(0.62, 0.42)]), LEAF, INK, 1.5)
	ci.draw_rect(L._sub(a, 0.42, 0.14, 0.58, 0.77), Color("7fc46a"))
	ci.draw_rect(L._sub(a, 0.42, 0.14, 0.58, 0.77), INK, false, 1.5)
	ci.draw_circle(L._at(a, 0.5, 0.11), a.size.y * 0.05, Color("f2a0c0"))
	if show != "phloem":
		ci.draw_rect(L._sub(a, 0.44, 0.16, 0.48, 0.8), Color("bcd8f5"))
		ci.draw_line(L._at(a, 0.46, 0.37), L._at(a, 0.2, 0.26), BLUE, 1.5)
		ci.draw_line(L._at(a, 0.46, 0.42), L._at(a, 0.82, 0.33), BLUE, 1.5)
	if show != "xylem":
		ci.draw_rect(L._sub(a, 0.52, 0.14, 0.56, 0.78), Color("f6cf9c"))
	for k in 3:
		ci.draw_circle(L._at(a, 0.66 + k * 0.06, 0.4 - k * 0.012), 2.5, INK)
	if flows:
		if show != "phloem":
			for y: float in [0.68, 0.5, 0.3]:
				L._arrow(ci, L._at(a, 0.46, y + 0.06), L._at(a, 0.46, y - 0.03), BLUE, 2.0)
			for k in 3:
				var q := L._at(a, 0.67 + k * 0.06, 0.41)
				L._arrow(ci, q, q + Vector2(6, 12), BLUE.lightened(0.2), 1.5)
			for q: Vector2 in [Vector2(0.26, 0.86), Vector2(0.36, 0.95)]:
				ci.draw_circle(L._at(a, q.x, q.y), 3.0, BLUE)
		if show != "xylem":
			L._arrow(ci, L._at(a, 0.54, 0.3), L._at(a, 0.54, 0.17), ORANGE, 2.0)
			L._arrow(ci, L._at(a, 0.54, 0.55), L._at(a, 0.54, 0.72), ORANGE, 2.0)
	if _plain(d) and flows:
		var f := maxi(fs - 3, 8)
		if show != "phloem":
			L._say_from(ci, font, L._at(a, 0.03, 0.62), "water and minerals: up", f, BLUE.darkened(0.3))
		if show != "xylem":
			L._say_from(ci, font, L._at(a, 0.6, 0.62), "sugars: up and down", f, ORANGE.darkened(0.3))
	_finish_diagram(ci, font, r, a, d)


# --- The heart --------------------------------------------------------------------------------------------------------

static func _tube(ci: CanvasItem, a: Rect2, pts: Array, colour: Color, w: float) -> void:
	var p := PackedVector2Array(L._pts(a, pts))
	ci.draw_polyline(p, INK, w + 3.0, true)
	ci.draw_polyline(p, colour, w, true)


static func _draw_heart(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var a := _diagram_box(d, r)
	var fs := L._fs(r)
	var w := a.size.y * 0.07
	var blue := Color("6d9be8")
	var red := Color("e0605a")
	_tube(ci, a, [Vector2(0.1, 0.24), Vector2(0.3, 0.24), Vector2(0.39, 0.34)], blue, w)
	_tube(ci, a, [Vector2(0.45, 0.42), Vector2(0.44, 0.08), Vector2(0.2, 0.06)], blue, w)
	_tube(ci, a, [Vector2(0.9, 0.33), Vector2(0.64, 0.36)], red, w)
	_tube(ci, a, [Vector2(0.55, 0.45), Vector2(0.55, 0.06), Vector2(0.7, 0.04), Vector2(0.78, 0.16)], red, w)
	var right_side := L._pts(a, [Vector2(0.5, 0.27), Vector2(0.36, 0.28), Vector2(0.31, 0.45), Vector2(0.33, 0.68),
		Vector2(0.42, 0.84), Vector2(0.5, 0.93)])
	var left_side := L._pts(a, [Vector2(0.5, 0.27), Vector2(0.64, 0.28), Vector2(0.69, 0.45), Vector2(0.67, 0.68),
		Vector2(0.58, 0.84), Vector2(0.5, 0.93)])
	var back: Array = right_side.duplicate()
	back.reverse()
	L._poly(ci, left_side + back, Color("f3c3bd"), INK, 0.0)
	L._poly(ci, L._pts(a, [Vector2(0.5, 0.29), Vector2(0.37, 0.3), Vector2(0.33, 0.45), Vector2(0.35, 0.67),
		Vector2(0.43, 0.82), Vector2(0.5, 0.88)]), Color("b9d0f5"), INK, 0.0)
	L._poly(ci, L._pts(a, [Vector2(0.52, 0.29), Vector2(0.62, 0.3), Vector2(0.66, 0.45), Vector2(0.63, 0.66),
		Vector2(0.56, 0.8), Vector2(0.52, 0.84)]), Color("f5bcb6"), INK, 0.0)
	var outline := PackedVector2Array(left_side + back)
	outline.append(outline[0])
	ci.draw_polyline(outline, INK, 2.5, true)
	ci.draw_line(L._at(a, 0.5, 0.27), L._at(a, 0.5, 0.92), Color("b04a44"), 5.0)
	ci.draw_line(L._at(a, 0.33, 0.5), L._at(a, 0.67, 0.5), INK, 2.0)
	for vx: float in [0.41, 0.59]:
		L._poly(ci, L._pts(a, [Vector2(vx - 0.03, 0.5), Vector2(vx + 0.03, 0.5), Vector2(vx, 0.56)]), Color.WHITE, INK,
			1.5)
	if bool(d.get("flow", true)):
		var dark_blue := BLUE.darkened(0.3)
		var dark_red := RED.darkened(0.2)
		L._arrow(ci, L._at(a, 0.14, 0.24), L._at(a, 0.24, 0.24), dark_blue, 2.5)
		L._arrow(ci, L._at(a, 0.41, 0.4), L._at(a, 0.41, 0.48), dark_blue, 2.5)
		L._arrow(ci, L._at(a, 0.4, 0.66), L._at(a, 0.44, 0.54), dark_blue, 2.0)
		L._arrow(ci, L._at(a, 0.38, 0.07), L._at(a, 0.27, 0.065), dark_blue, 2.5)
		L._arrow(ci, L._at(a, 0.88, 0.333), L._at(a, 0.8, 0.342), dark_red, 2.5)
		L._arrow(ci, L._at(a, 0.59, 0.4), L._at(a, 0.59, 0.48), dark_red, 2.5)
		L._arrow(ci, L._at(a, 0.6, 0.66), L._at(a, 0.56, 0.54), dark_red, 2.0)
		L._arrow(ci, L._at(a, 0.7, 0.04), L._at(a, 0.76, 0.13), dark_red, 2.5)
	if _plain(d):
		var f := maxi(fs - 3, 8)
		L._say_from(ci, font, L._at(a, 0.09, 0.16), "from the body", f)
		L._say_from(ci, font, L._at(a, 0.19, 0.06), "to the lungs", f, INK, true)
		L._say_from(ci, font, L._at(a, 0.9, 0.25), "from the lungs", f, INK, true)
		L._say_from(ci, font, L._at(a, 0.8, 0.12), "to the body", f)
	if bool(d.get("sides", true)):
		var f := maxi(fs - 4, 8)
		L._say(ci, font, L._at(a, 0.22, 0.9), "person's right", f, GREY.darkened(0.35))
		L._say(ci, font, L._at(a, 0.78, 0.9), "person's left", f, GREY.darkened(0.35))
	_finish_diagram(ci, font, r, a, d)


# --- An air sac -------------------------------------------------------------------------------------------------------

## A point `t` (0-1) along the capillary that runs under the air sac, from the left to the right.
static func _capillary_at(a: Rect2, t: float) -> Vector2:
	var ang := PI * (1.0 - t)
	return L._at(a, 0.5 + 0.3 * cos(ang), 0.45 + 0.345 * sin(PI * t))


static func _draw_sac(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var a := _diagram_box(d, r)
	var fs := L._fs(r)
	var c := L._at(a, 0.5, 0.45)
	var rad := a.size.y * 0.3
	ci.draw_rect(L._sub(a, 0.465, 0.0, 0.535, 0.2), Color("fbecec"))
	ci.draw_line(L._at(a, 0.465, 0.0), L._at(a, 0.465, 0.19), INK, 2.0)
	ci.draw_line(L._at(a, 0.535, 0.0), L._at(a, 0.535, 0.19), INK, 2.0)
	var width := a.size.y * 0.12
	for k in 24:
		var p0 := _capillary_at(a, k / 24.0)
		var p1 := _capillary_at(a, (k + 1) / 24.0)
		ci.draw_line(p0, p1, INK, width + 3.0, true)
	for k in 24:
		var p0 := _capillary_at(a, k / 24.0)
		var p1 := _capillary_at(a, (k + 1) / 24.0)
		ci.draw_line(p0, p1, Color("5f8fe0").lerp(Color("d9433b"), k / 23.0), width, true)
	for t: float in [0.12, 0.3, 0.55, 0.8, 0.92]:
		ci.draw_circle(_capillary_at(a, t), a.size.y * 0.035, Color("b8322c"))
	ci.draw_circle(c, rad, Color("fbecec"))
	ci.draw_arc(c, rad, 0.0, TAU, 40, INK, 2.5)
	ci.draw_rect(L._sub(a, 0.467, 0.12, 0.533, 0.2), Color("fbecec"))
	if bool(d.get("arrows", true)):
		L._arrow(ci, L._at(a, 0.43, 0.5), L._at(a, 0.43, 0.78), ORANGE, 3.0)
		L._arrow(ci, L._at(a, 0.58, 0.78), L._at(a, 0.58, 0.5), GREY.darkened(0.2), 3.0)
		if _plain(d):
			var f := maxi(fs - 2, 8)
			L._say_from(ci, font, L._at(a, 0.41, 0.6), "oxygen", f, ORANGE.darkened(0.3), true)
			L._say_from(ci, font, L._at(a, 0.6, 0.6), "carbon dioxide", f, GREY.darkened(0.4))
	if _plain(d):
		var f := maxi(fs - 3, 8)
		L._say_from(ci, font, L._at(a, 0.56, 0.07), "air in and out", f, INK, false, false)
		L._say_from(ci, font, L._at(a, 0.02, 0.38), "from the heart", f, BLUE.darkened(0.3))
		L._say_from(ci, font, L._at(a, 0.98, 0.38), "back to the heart", f, RED.darkened(0.2), true)
	_finish_diagram(ci, font, r, a, d)


# --- Genetic engineering ----------------------------------------------------------------------------------------------

static func _capsule(ci: CanvasItem, rect: Rect2, fill: Color, line: Color, w: int) -> void:
	L._box(ci, rect, fill, line, int(minf(rect.size.x, rect.size.y) * 0.5), w)


static func _draw_gene(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var a := _diagram_box(d, r)
	var fs := L._fs(r)
	var h := a.size.y
	var step := int(d.get("step", 0))
	var words := bool(d.get("words", true)) and _plain(d)
	for k in 4:
		var panel := L._sub(a, k * 0.25 + 0.01, 0.02, k * 0.25 + 0.24, 0.84)
		L._box(ci, panel, Color.WHITE, ORANGE if step == k + 1 else GREY, 8, 3 if step == k + 1 else 1)
		if words:
			L._say(ci, font, L._at(a, k * 0.25 + 0.125, 0.93), GENE_WORDS[k], L._fit(font, GENE_WORDS[k], fs - 2,
				a.size.x * 0.24))
		if k < 3:
			L._arrow(ci, L._at(a, k * 0.25 + 0.232, 0.45), L._at(a, k * 0.25 + 0.268, 0.45), INK, 2.5)
	var cell := L._at(a, 0.125, 0.45)
	ci.draw_circle(cell, h * 0.34, Color("f9e3d0"))
	ci.draw_arc(cell, h * 0.34, 0.0, TAU, 32, INK, 2.0)
	ci.draw_circle(cell, h * 0.22, Color("ecd0f0"))
	var dna := PackedVector2Array()
	var dna2 := PackedVector2Array()
	for k in 21:
		var x := cell.x - h * 0.3 + h * 0.6 * k / 20.0
		dna.append(Vector2(x, cell.y + sin(k * 0.9) * h * 0.04))
		dna2.append(Vector2(x, cell.y - sin(k * 0.9) * h * 0.04))
	ci.draw_polyline(dna, Color("7a3fa0"), 2.0, true)
	ci.draw_polyline(dna2, Color("7a3fa0"), 2.0, true)
	ci.draw_rect(Rect2(L._at(a, 0.115, 0.4), Vector2(a.size.x * 0.04, h * 0.1)), ORANGE)
	for x: float in [0.113, 0.157]:
		ci.draw_line(L._at(a, x - 0.006, 0.36), L._at(a, x + 0.006, 0.54), RED, 2.0)
	_capsule(ci, L._sub(a, 0.29, 0.14, 0.46, 0.76), Color("dff0d6"), GREEN.darkened(0.2), 2)
	var pc := L._at(a, 0.375, 0.45)
	ci.draw_arc(pc, h * 0.17, -PI * 0.25, PI * 1.25, 28, GREEN, 4.0)
	ci.draw_arc(pc, h * 0.17, PI * 1.25, PI * 1.75, 10, ORANGE, 5.0)
	ci.draw_rect(L._sub(a, 0.52, 0.2, 0.73, 0.78), Color("e4f0fa"))
	ci.draw_rect(L._sub(a, 0.52, 0.2, 0.73, 0.78), INK, false, 2.0)
	for q: Vector2 in [Vector2(0.56, 0.3), Vector2(0.64, 0.34), Vector2(0.58, 0.45), Vector2(0.67, 0.5),
			Vector2(0.62, 0.62), Vector2(0.55, 0.68), Vector2(0.69, 0.68)]:
		_capsule(ci, Rect2(L._at(a, q.x - 0.025, q.y - 0.04), Vector2(a.size.x * 0.05, h * 0.08)), Color("bfe3ad"),
			GREEN.darkened(0.3), 1)
		ci.draw_circle(L._at(a, q.x, q.y), h * 0.015, ORANGE)
	ci.draw_rect(L._sub(a, 0.845, 0.28, 0.915, 0.74), Color("f4f7fb"))
	ci.draw_rect(L._sub(a, 0.845, 0.28, 0.915, 0.74), INK, false, 2.0)
	ci.draw_rect(L._sub(a, 0.855, 0.2, 0.905, 0.28), GREY)
	for q: Vector2 in [Vector2(0.865, 0.42), Vector2(0.88, 0.5), Vector2(0.87, 0.6), Vector2(0.895, 0.66),
			Vector2(0.89, 0.36)]:
		var hc := L._at(a, q.x, q.y)
		var hx := PackedVector2Array()
		for i in 6:
			hx.append(hc + Vector2(cos(i * TAU / 6.0), sin(i * TAU / 6.0)) * h * 0.03)
		ci.draw_colored_polygon(hx, ORANGE)
	_finish_diagram(ci, font, r, a, d)


# --- A slide ----------------------------------------------------------------------------------------------------------

static func _image(ci: CanvasItem, box: Rect2, image: String) -> void:
	var at := _map_land(box)
	match image:
		"map":
			ci.draw_rect(box, Color("bfe0f5"))
			L._poly(ci, [at[0], at[1], at[2], at[3], at[4]], Color("9fcf7f"), INK, 1.5)
			ci.draw_circle(box.get_center(), 4.0, RED)
		"plant":
			ci.draw_rect(box, SKY)
			ci.draw_line(box.position + box.size * Vector2(0.5, 0.95), box.position + box.size * Vector2(0.5, 0.35), GREEN,
				4.0)
			ci.draw_circle(box.position + box.size * Vector2(0.38, 0.45), box.size.y * 0.12, LEAF)
			ci.draw_circle(box.position + box.size * Vector2(0.62, 0.35), box.size.y * 0.12, LEAF)
		"sun":
			ci.draw_rect(box, SKY)
			var c := box.get_center()
			ci.draw_circle(c, box.size.y * 0.22, Color("ffd23f"))
			for i in 8:
				var dir := Vector2(cos(i * TAU / 8.0), sin(i * TAU / 8.0))
				ci.draw_line(c + dir * box.size.y * 0.28, c + dir * box.size.y * 0.4, Color("f0a020"), 3.0)
		"chart_icon":
			ci.draw_rect(box, Color.WHITE)
			for i in 3:
				var hh := box.size.y * (0.3 + 0.2 * i)
				ci.draw_rect(Rect2(box.position + Vector2(box.size.x * (0.18 + 0.25 * i), box.size.y * 0.9 - hh),
					Vector2(box.size.x * 0.16, hh)), BLUE)
	if image != "none":
		ci.draw_rect(box, INK, false, 1.5)


## A map's land, as five points of `box`.
static func _map_land(box: Rect2) -> Array:
	var out: Array = []
	for f: Vector2 in [Vector2(0.2, 0.25), Vector2(0.55, 0.15), Vector2(0.8, 0.45), Vector2(0.6, 0.85), Vector2(0.25, 0.7)]:
		out.append(box.position + box.size * f)
	return out


static func _draw_slide(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var notes := str(d.get("notes", ""))
	var fs := L._fs(r)
	var room := Rect2(r.position, r.size - Vector2(0, fs * 1.9 if notes != "" else 0.0))
	var sw := minf(room.size.x, room.size.y * 16.0 / 9.0)
	var slide := Rect2(room.get_center() - Vector2(sw, sw * 9.0 / 16.0) * 0.5, Vector2(sw, sw * 9.0 / 16.0))
	ci.draw_rect(slide.grow(5.0), Color("3a3f4b"))
	var busy := bool(d.get("busy", false))
	var mark := str(d.get("mark", ""))
	var sh := slide.size.y
	var bullets: Array = d.get("bullets", [])
	if busy:
		ci.draw_rect(slide, Color("4b1fa8"))
		for k in 7:
			ci.draw_line(slide.position + Vector2(0, sh * k / 7.0), slide.position + Vector2(slide.size.x, sh * (k + 1)
				/ 7.0), Color("6a3fd0"), 3.0)
		var tf := L._fit(font, str(d.title), int(sh * 0.08), slide.size.x * 0.9)
		L._say(ci, font, slide.position + Vector2(slide.size.x * 0.5, sh * 0.09), str(d.title), tf, Color("ffe600"), false)
		var lines: Array = []
		for k in 3:
			for b: Variant in bullets:
				lines.append(str(b))
		var f := maxi(int(sh * 0.045), 7)
		for k in mini(lines.size(), 14):
			var col := Color("ff4d4d") if k % 2 == 0 else Color("48ff7a")
			var t := "• " + str(lines[k]) + " " + str(lines[(k + 1) % lines.size()])
			ci.draw_string(font, slide.position + Vector2(slide.size.x * 0.04, sh * 0.2 + k * f * 1.15 + f), t,
				HORIZONTAL_ALIGNMENT_LEFT, slide.size.x * 0.92, f, col)
		var star := slide.position + Vector2(slide.size.x * 0.88, sh * 0.82)
		var pts := PackedVector2Array()
		for i in 10:
			var rr := sh * (0.1 if i % 2 == 0 else 0.045)
			pts.append(star + Vector2(cos(i * TAU / 10.0 - PI * 0.5), sin(i * TAU / 10.0 - PI * 0.5)) * rr)
		ci.draw_colored_polygon(pts, Color("ffe600"))
	else:
		ci.draw_rect(slide, Color.WHITE)
		var tf := L._fit(font, str(d.title), int(sh * 0.11), slide.size.x * 0.9)
		L._say_from(ci, font, slide.position + Vector2(slide.size.x * 0.05, sh * 0.12), str(d.title), tf, INK, false, false)
		ci.draw_line(slide.position + Vector2(slide.size.x * 0.05, sh * 0.21), slide.position + Vector2(slide.size.x
			* 0.95, sh * 0.21), ORANGE, 3.0)
		if mark == "title":
			ci.draw_rect(Rect2(slide.position + Vector2(slide.size.x * 0.03, sh * 0.03), Vector2(slide.size.x * 0.94,
				sh * 0.17)), ORANGE, false, 3.0)
		var side := d.has("chart") or str(d.get("image", "none")) != "none" or d.has("number")
		var text_w := slide.size.x * (0.48 if side else 0.9)
		var bf := int(sh * 0.075)
		for k in bullets.size():
			var t := "• " + str(bullets[k])
			L._say_from(ci, font, slide.position + Vector2(slide.size.x * 0.05, sh * (0.33 + k * 0.13)), t, L._fit(font,
				t, bf, text_w), INK, false, false)
		if mark == "bullets" and not bullets.is_empty():
			ci.draw_rect(Rect2(slide.position + Vector2(slide.size.x * 0.03, sh * 0.25), Vector2(text_w + slide.size.x
				* 0.04, sh * (0.13 * bullets.size() + 0.04))), ORANGE, false, 3.0)
		var right := Rect2(slide.position + Vector2(slide.size.x * 0.56, sh * 0.27), Vector2(slide.size.x * 0.39, sh * 0.66))
		if d.has("number"):
			var nf := L._fit(font, str(d.number), int(sh * 0.3), right.size.x)
			L._say(ci, font, right.get_center(), str(d.number), nf, ORANGE.darkened(0.15), false)
			if mark == "number":
				ci.draw_rect(right, ORANGE, false, 3.0)
		elif d.has("chart"):
			var bars: Array = d.chart
			var top := 1.0
			for b: Variant in bars:
				top = maxf(top, float(b[1]))
			var bw := right.size.x / bars.size()
			var base := right.end.y - fs * 1.1
			ci.draw_line(Vector2(right.position.x, base), Vector2(right.end.x, base), INK, 2.0)
			for k in bars.size():
				var hh := (base - right.position.y - fs * 0.6) * float(bars[k][1]) / top
				ci.draw_rect(Rect2(Vector2(right.position.x + k * bw + bw * 0.18, base - hh), Vector2(bw * 0.64, hh)), BLUE)
				var bl := str(bars[k][0])
				L._say(ci, font, Vector2(right.position.x + (k + 0.5) * bw, base + fs * 0.6), bl, L._fit(font, bl, fs - 3,
					bw))
			if mark == "chart":
				ci.draw_rect(right, ORANGE, false, 3.0)
		elif str(d.get("image", "none")) != "none":
			var box := L._fit_box(right, 1.4)
			_image(ci, box, str(d.image))
			if mark == "image":
				ci.draw_rect(box.grow(3.0), ORANGE, false, 3.0)
	if notes != "":
		var nb := Rect2(Vector2(r.position.x, r.end.y - fs * 1.6), Vector2(r.size.x, fs * 1.6))
		L._box(ci, nb, PALE, GREY, 5, 1)
		var t := "Speaker notes: " + notes
		L._say(ci, font, nb.get_center(), t, L._fit(font, t, fs - 2, nb.size.x - 10.0), INK, false)


# --- Story order and time order ---------------------------------------------------------------------------------------

static func _draw_story(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var events: Array = d.events
	var told: Array = d.told
	var n := events.size()
	var fs := L._fs(r)
	var names := bool(d.get("names", true))
	var left := r.size.x * 0.17 if names else 0.0
	var row := Rect2(r.position + Vector2(left, 0), Vector2(r.size.x - left, r.size.y))
	var gap := row.size.x * 0.025
	var cw := (row.size.x - gap * (n - 1)) / n
	var ch := r.size.y * 0.32
	var flash := int(d.get("flash", -1))
	var top_y := r.position.y + r.size.y * 0.03
	var bot_y := r.end.y - ch - r.size.y * 0.03
	if names:
		var f := L._fit(font, "it happened", fs - 2, left - 6.0)
		L._text_in(ci, font, Rect2(Vector2(r.position.x, top_y), Vector2(left - 6.0, ch)), "as told", f)
		L._text_in(ci, font, Rect2(Vector2(r.position.x, bot_y), Vector2(left - 6.0, ch)), "as it happened", f)
	for k in n:
		var e := int(told[k])
		var from := Vector2(row.position.x + k * (cw + gap) + cw * 0.5, top_y + ch)
		var to := Vector2(row.position.x + e * (cw + gap) + cw * 0.5, bot_y)
		ci.draw_line(from, to, ORANGE if e == flash else GREY, 3.0 if e == flash else 2.0, true)
	for k in n:
		var e := int(told[k])
		for pair: Array in [[Rect2(row.position.x + k * (cw + gap), top_y, cw, ch), k + 1],
				[Rect2(row.position.x + e * (cw + gap), bot_y, cw, ch), e + 1]]:
			var box: Rect2 = pair[0]
			L._box(ci, box, SOFT if e == flash else Color.WHITE, ORANGE if e == flash else INK, 6, 2 if e == flash else 1)
			L._text_in(ci, font, box.grow_individual(-2, -fs * 0.45, -2, 0), str(events[e]), fs - 2)
			L._say(ci, font, box.position + Vector2(fs * 0.55, fs * 0.55), str(pair[1]), maxi(fs - 5, 8),
				GREY.darkened(0.35), false)
