class_name SchoolPictureG8Life
extends RefCounted
## Owner #70, #73 and #111, grade 8 health and PE, design and technology, and projects (research §6.8): the picture kinds
## they add, drawn from data onto a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls
## only, no new art; the font has no arrows or signs, so they are drawn). Diagrams name their parts with grade 7's labels
## (SchoolPictureG7Life's bands along the top and bottom, each with a line to its part); `mark` (a part) is orange and
## `hide` (a part) shows "?"; `pins` (true) leaves room for a label exercise's pins (the bands, on a wide diagram; on a
## narrow one, ratio SIDE_PINS_RATIO or less, columns PIN_SIDE wide at its sides); a part's place is `part_at`'s, so the
## pins can point at them. Kinds and fields:
## Health and PE
## - fitness_profile {parts: [[name (12 letters), score]] (3-6), top (3-10 whole: the best score, the outer ring),
##   after?: [score] (one for each part: a retest, drawn orange and dashed), mark? (a part's index), title? (24)}: a
##   fitness profile as a spider chart, each part's score out along its own spoke (weakest).
## - feeling_curve {view: FEEL_VIEWS ("pressure": how well you do against pressure, too little, the best zone and too
##   much; "stay": anxiety over time, rising, peaking and falling if you stay, and the escape that brings it back next
##   time), words? (true: the zones' or the parts' names), point? (pressure: 0-1 along, a dot on the curve), labels?,
##   mark?, hide? (FEEL_PARTS[view])} (pressure_zone).
## - chance_wheel {slices: [[label (10), count (1-20), gold? (won, 0 or more)]] (2-6; 2-24 slices in all), cost? (gold
##   a spin), pointer? (a group's index: the wheel turned so the pointer is on one of its slices), mark?, hide? (a group's
##   index: its name "?")}: a prize wheel, each group's slices spread round it, and a key with each group's count
##   (chance, expected_win).
## - cpr_aed {view: CPR_VIEWS ("hands": a rescuer's straight arms and stacked hands on the centre of a lying person's
##   chest, from the side, and the 5 to 6 cm push; "pads": where a defibrillator's two pads go on the bare chest;
##   "machine": a defibrillator and its parts), labels?, pins?, mark?, hide? (CPR_PARTS[view])}.
## Design and technology
## - making_plan {tasks: [[name (16 letters), start (whole, from 0), length (whole, 1 or more)]] (2-7), columns (4-16:
##   every task inside), unit? (8 letters: "lesson"), today? (a column, 1-columns: shaded), mark?, hide? (a task's index:
##   its bar dashed with "?")}: a Gantt chart: each task's bar across the lessons it takes (plan_end).
## - smart_material {material: SMART, words? (true: what happens, under each panel), labels?, pins?, mark?, hide?
##   (SMART_PARTS[material])}: a smart material before and after its trigger (a shape-memory wire warmed back to shape, a
##   thermochromic spoon in hot food, photochromic lenses in sunlight, a piezoelectric crystal squeezed into a spark, a
##   hydrogel swelling with water), or a composite's layers of fibres in a matrix.
## - gear_train {stages: [[driver, driven]] (1-3; teeth 8-60 whole; each stage's driven gear shares a shaft with the
##   next stage's driver), rpm? (the input's speed, 1-10,000), out? (8 letters under the last gear: "50 rpm", "?"), turn?
##   ("cw" | "acw": the first gear's arrow), arrows? (true: every gear's arrow, by train_turns), values? (true: each gear's
##   teeth), hide? (a gear's index: its teeth "?"), labels? (driver, driven and shared shafts named)} (train_ratio).
## - block_tackle {ropes (1-6: the ropes holding the load), load? (newtons, more than 0), effort? (newtons, or "?"),
##   count? (true: each holding rope numbered), labels? (true: the blocks, the load and the effort named)}: a block and
##   tackle lifting a crate (tackle_effort).
## - tall_structure {type: STRUCTURES ("damper": a skyscraper in the wind with a tuned mass damper; "isolation": a
##   building on rubber bearings over shaking ground; "suspension": a suspension bridge; "cable_stayed": a cable-stayed
##   bridge), labels?, pins?, mark?, hide? (STRUCTURE_PARTS[type])}.
## - circular_loop {side? ("both": the default, "technical" or "biological"), words? (true: the key of the loops),
##   labels?, pins?, mark?, hide? (LOOP_PARTS)}: the circular economy's loops: materials, make, use in the middle;
##   technical loops on the right (maintain, reuse, refurbish, recycle: the smaller the loop, the more it saves),
##   biological ones on the left (compost, biogas), and the leak to landfill.

const L := preload("res://ui/school/school_picture_g7life.gd")
const KINDS: Array[String] = ["fitness_profile", "feeling_curve", "chance_wheel", "cpr_aed", "making_plan",
	"smart_material", "gear_train", "block_tackle", "tall_structure", "circular_loop"]
const INK := Color("1f2a4a")    # SchoolUi.INK
const PAPER := Color("fdf6e3")  # SchoolUi.PAPER
const ORANGE := Color("f08a1c")
const SOFT := Color("fce2b8")
const RED := Color("d9433b")
const BLUE := Color("3a7be8")
const GREEN := Color("3fa34d")
const GREY := Color("9aa1ad")
const PALE := Color("eef1f6")
const GOLD := Color("e0b23a")
const SKIN := Color("e0ac7e")
const STEEL := Color("aab3bf")
const SKY := Color("dcecf8")
const WATER := Color("7fb6e8")
const GROUND := Color("b98a5a")

const MAX_PART_NAME := 12
const MAX_TITLE := 24

const FEEL_VIEWS: Array[String] = ["pressure", "stay"]
const FEEL_PARTS := {"pressure": ["too little", "best zone", "too much"], "stay": ["it rises", "the peak", "it falls",
	"escape"]}

const MAX_GROUP_NAME := 10
const MAX_SLICES := 24
const WHEEL_COLOURS: Array[Color] = [Color("f0b43c"), Color("3a7be8"), Color("3fa34d"), Color("d9433b"),
	Color("8e44ad"), Color("9aa1ad")]

const CPR_VIEWS: Array[String] = ["hands", "pads", "machine"]
const CPR_PARTS := {"hands": ["hands", "straight arms", "chest", "5 to 6 cm"], "pads": ["upper pad", "side pad",
	"collarbone", "armpit", "AED"], "machine": ["handle", "on button", "shock button", "speaker", "pads"]}
## Each part's place in its view's box (fractions of its width and height; the box has the view's ratio, RATIOS).
const CPR_AT := {
	"hands": {"hands": Vector2(0.33, 0.705), "straight arms": Vector2(0.333, 0.42), "chest": Vector2(0.47, 0.8),
		"5 to 6 cm": Vector2(0.235, 0.8)},
	"pads": {"upper pad": Vector2(0.39, 0.37), "side pad": Vector2(0.65, 0.63), "collarbone": Vector2(0.4, 0.235),
		"armpit": Vector2(0.73, 0.33), "AED": Vector2(0.9, 0.8)},
	"machine": {"handle": Vector2(0.5, 0.06), "on button": Vector2(0.26, 0.48), "shock button": Vector2(0.44, 0.72),
		"speaker": Vector2(0.74, 0.3), "pads": Vector2(0.75, 0.7)},
}

const MAX_TASKS := 7
const MAX_TASK := 16
const MAX_COLUMNS := 16
const MAX_UNIT := 8

const SMART: Array[String] = ["shape_memory", "thermochromic", "photochromic", "piezoelectric", "hydrogel", "composite"]
const SMART_PARTS := {"shape_memory": ["bent wire", "warm it", "set shape"], "thermochromic": ["cool colour", "heat",
	"hot colour"], "photochromic": ["clear lenses", "UV light", "dark lenses"], "piezoelectric": ["crystal", "squeeze",
	"spark"], "hydrogel": ["dry crystals", "add water", "swollen gel"], "composite": ["fibres", "matrix", "layers"]}
## What happens, under each panel (before, the trigger, after).
const SMART_WORDS := {"shape_memory": ["bent, cold", "warm it", "back to its shape"], "thermochromic": ["cool: blue",
	"hot food", "hot: pink"], "photochromic": ["indoors: clear", "sunlight", "outdoors: dark"], "piezoelectric":
	["a crystal", "squeeze", "a spark"], "hydrogel": ["dry crystals", "water", "a swollen gel"], "composite":
	["fibres", "in a matrix", "layer on layer"]}
const SMART_AT := {"before": Vector2(0.21, 0.5), "trigger": Vector2(0.5, 0.5), "after": Vector2(0.79, 0.5)}
const COMPOSITE_AT := {"fibres": Vector2(0.38, 0.33), "matrix": Vector2(0.6, 0.72), "layers": Vector2(0.77, 0.45)}

const MIN_TEETH := 8
const MAX_TEETH := 60
const MAX_STAGES := 3
const MAX_OUT := 8
const TURNS: Array[String] = ["cw", "acw"]

const MAX_ROPES := 6

const STRUCTURES: Array[String] = ["damper", "isolation", "suspension", "cable_stayed"]
const STRUCTURE_PARTS := {"damper": ["tuned mass damper", "stiff core", "cross-bracing", "piles", "wind"],
	"isolation": ["rubber bearings", "steel frame", "foundation", "ground shaking"], "suspension": ["tower",
	"main cable", "hangers", "deck", "anchorage"], "cable_stayed": ["tower", "stay cables", "deck", "pier"]}
const STRUCTURE_AT := {
	"damper": {"tuned mass damper": Vector2(0.5, 0.2), "stiff core": Vector2(0.5, 0.56), "cross-bracing":
		Vector2(0.42, 0.66), "piles": Vector2(0.44, 0.92), "wind": Vector2(0.17, 0.4)},
	"isolation": {"rubber bearings": Vector2(0.38, 0.69), "steel frame": Vector2(0.62, 0.42), "foundation":
		Vector2(0.7, 0.755), "ground shaking": Vector2(0.5, 0.9)},
	"suspension": {"tower": Vector2(0.3, 0.32), "main cable": Vector2(0.4, 0.45), "hangers": Vector2(0.62, 0.58),
		"deck": Vector2(0.86, 0.62), "anchorage": Vector2(0.03, 0.69)},
	"cable_stayed": {"tower": Vector2(0.5, 0.3), "stay cables": Vector2(0.3, 0.4), "deck": Vector2(0.86, 0.62),
		"pier": Vector2(0.5, 0.8)},
}

const SIDES: Array[String] = ["both", "technical", "biological"]
const TECH_LOOPS: Array[String] = ["maintain", "reuse", "refurbish", "recycle"]
const BIO_LOOPS: Array[String] = ["biogas", "compost"]
const STAGES: Array[String] = ["materials", "make", "use", "landfill"]
const LOOP_PARTS: Array[String] = ["maintain", "reuse", "refurbish", "recycle", "biogas", "compost", "materials", "make",
	"use", "landfill"]
## Each stage's height in the box, and each loop's end (the stage it goes back to) and width.
const STAGE_Y := {"materials": 0.12, "make": 0.37, "use": 0.62, "landfill": 0.9}
const LOOP_FROM := {"maintain": 0.66, "reuse": 0.7, "refurbish": 0.72, "recycle": 0.74, "biogas": 0.7,
	"compost": 0.74}
const LOOP_END := {"maintain": 0.56, "reuse": 0.495, "refurbish": 0.37, "recycle": 0.12, "biogas": 0.37,
	"compost": 0.12}
const LOOP_RX := {"maintain": 0.05, "reuse": 0.11, "refurbish": 0.17, "recycle": 0.23, "biogas": 0.12,
	"compost": 0.22}

## A label exercise's pins sit in columns this wide at the sides of a diagram this narrow (or narrower).
const SIDE_PINS_RATIO := 2.0
const PIN_SIDE := 62.0
## The shape (width ÷ height) each labelled diagram is drawn in, so its parts' places can be worked out.
const RATIOS := {"cpr_aed.hands": 2.2, "cpr_aed.pads": 1.5, "cpr_aed.machine": 1.8, "smart_material": 2.4,
	"tall_structure.damper": 1.3, "tall_structure.isolation": 1.7, "tall_structure.suspension": 2.6,
	"tall_structure.cable_stayed": 2.4, "circular_loop": 2.0}


# --- The rules the pictures draw by (the lessons teach them; tests check them) --------------------------------------

## A gear train's ratio: each stage's driven teeth ÷ its driver's, multiplied (8 means the output turns 8 times
## slower, with 8 times the turning force, less friction).
static func train_ratio(stages: Array) -> float:
	var r := 1.0
	for s: Variant in stages:
		r *= float(s[1]) / float(s[0])
	return r


## Which way each gear turns, the first turning `turn`: a meshing gear turns the other way, a gear on the same shaft
## the same way.
static func train_turns(stages: Array, turn: String) -> Array[String]:
	var out: Array[String] = []
	var now := turn
	for s: Variant in stages:
		out.append(now)
		now = "acw" if now == "cw" else "cw"
		out.append(now)
	return out


## The effort a block and tackle needs for a load with `ropes` ropes holding it, without friction.
static func tackle_effort(load: float, ropes: int) -> float:
	return load / maxi(ropes, 1)


## The share of a prize wheel's slices in group `i`.
static func chance(slices: Array, i: int) -> float:
	var total := 0
	for s: Variant in slices:
		total += int(s[1])
	return float(slices[i][1]) / maxi(total, 1)


## The gold a spin wins on average: each prize × its share of the slices, added up.
static func expected_win(slices: Array) -> float:
	var total := 0
	var won := 0.0
	for s: Variant in slices:
		total += int(s[1])
		won += int(s[1]) * (float(s[2]) if (s as Array).size() > 2 else 0.0)
	return won / maxi(total, 1)


## A plan's last lesson: the latest end of its tasks (a task from 0 for 2 ends after lesson 2).
static func plan_end(tasks: Array) -> int:
	var out := 0
	for t: Variant in tasks:
		out = maxi(out, int(t[1]) + int(t[2]))
	return out


## The part of a fitness profile with the lowest score (the first, when two tie).
static func weakest(parts: Array) -> String:
	var best := 0
	for i in parts.size():
		if float(parts[i][1]) < float(parts[best][1]):
			best = i
	return str(parts[best][0])


## The zone of the pressure curve at `x` (0-1 along): too little, the best zone, too much.
static func pressure_zone(x: float) -> String:
	return "too little" if x < 0.35 else ("best zone" if x <= 0.68 else "too much")


## Where the part named `label` is drawn on a picture of `size` (a SchoolPicture's whole size), for a label's line;
## (-1, -1) when the picture has no such part.
static func part_at(p: Dictionary, label: String, size: Vector2) -> Vector2:
	var none := Vector2(-1, -1)
	if not RATIOS.has(_ratio_key(p)):
		return none
	var a := _diagram_box(p, L._rect(size))
	return _anchors(p, a).get(label, none)


static func _ratio_key(p: Dictionary) -> String:
	var kind := str(p.get("kind", ""))
	match kind:
		"cpr_aed":
			return "cpr_aed.%s" % p.get("view", "")
		"tall_structure":
			return "tall_structure.%s" % p.get("type", "")
	return kind


## A diagram's box in `r`: its label bands (or its pins' bands) taken off, then its shape (RATIOS) centred.
static func _diagram_box(p: Dictionary, r: Rect2) -> Rect2:
	var fs := L._fs(r)
	var ratio := float(RATIOS.get(_ratio_key(p), 2.0))
	if bool(p.get("pins", false)) and not bool(p.get("labels", false)) and ratio <= SIDE_PINS_RATIO:
		return L._fit_box(Rect2(r.position + Vector2(PIN_SIDE, 0), r.size - Vector2(2.0 * PIN_SIDE, 0)), ratio)
	var bands := bool(p.get("labels", false)) or bool(p.get("pins", false))
	return L._fit_box(L._inner(r, fs, bands), ratio)


## Each named part's place in the diagram box `a`.
static func _anchors(p: Dictionary, a: Rect2) -> Dictionary:
	var out := {}
	match str(p.get("kind", "")):
		"cpr_aed":
			var at: Dictionary = CPR_AT.get(str(p.get("view", "")), {})
			for part: String in at:
				out[part] = L._at(a, at[part].x, at[part].y)
		"smart_material":
			var m := str(p.get("material", ""))
			var parts: Array = SMART_PARTS.get(m, [])
			var art := _smart_art(p, a)
			if m == "composite":
				for part: String in parts:
					out[part] = L._at(art, COMPOSITE_AT[part].x, COMPOSITE_AT[part].y)
			elif parts.size() == 3:
				for k in 3:
					var at: Vector2 = SMART_AT[["before", "trigger", "after"][k]]
					out[parts[k]] = L._at(art, at.x, at.y)
		"tall_structure":
			var at: Dictionary = STRUCTURE_AT.get(str(p.get("type", "")), {})
			for part: String in at:
				out[part] = L._at(a, at[part].x, at[part].y)
		"circular_loop":
			for part: String in _loop_parts(p):
				out[part] = _loop_at(a, part)
	return out


## The parts a circular_loop draws (its side's loops, and the stages).
static func _loop_parts(p: Dictionary) -> Array[String]:
	var side := str(p.get("side", "both"))
	var out: Array[String] = []
	if side != "biological":
		out.append_array(TECH_LOOPS)
	if side != "technical":
		out.append_array(BIO_LOOPS)
	out.append_array(STAGES)
	return out


## A loop's tag (its far side) or a stage's box centre.
static func _loop_at(a: Rect2, part: String) -> Vector2:
	if STAGE_Y.has(part):
		return L._at(a, 0.5, float(STAGE_Y[part]))
	var right := TECH_LOOPS.has(part)
	var rx := float(LOOP_RX[part])
	var mid := (float(LOOP_FROM[part]) + float(LOOP_END[part])) * 0.5
	return L._at(a, 0.58 + rx if right else 0.42 - rx, mid)


# --- Checks -------------------------------------------------------------------------------------------------------------

## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	var kind := str(p.get("kind", ""))
	match kind:
		"fitness_profile":
			return _profile_problem(p)
		"feeling_curve":
			if not FEEL_VIEWS.has(str(p.get("view", ""))):
				return "feeling_curve: view is one of %s" % [FEEL_VIEWS]
			if p.has("point") and (not L._number(p.point) or float(p.point) < 0.0 or float(p.point) > 1.0
					or str(p.view) != "pressure"):
				return "feeling_curve: point is 0-1 along the pressure curve"
			var why := L._parts_problem(p, FEEL_PARTS[str(p.view)], ["words"])
			return why
		"chance_wheel":
			return _wheel_problem(p)
		"cpr_aed":
			if not CPR_VIEWS.has(str(p.get("view", ""))):
				return "cpr_aed: view is one of %s" % [CPR_VIEWS]
			return L._parts_problem(p, CPR_PARTS[str(p.view)], ["pins"])
		"making_plan":
			return _plan_problem(p)
		"smart_material":
			if not SMART.has(str(p.get("material", ""))):
				return "smart_material: material is one of %s" % [SMART]
			return L._parts_problem(p, SMART_PARTS[str(p.material)], ["pins", "words"])
		"gear_train":
			return _train_problem(p)
		"block_tackle":
			if not L._whole(p.get("ropes")) or int(p.ropes) < 1 or int(p.ropes) > MAX_ROPES:
				return "block_tackle: ropes is 1-%d" % MAX_ROPES
			if p.has("load") and (not L._number(p.load) or float(p.load) <= 0.0):
				return "block_tackle: load is newtons, more than 0"
			if p.has("effort") and not (str(p.effort) == "?" or (L._number(p.effort) and float(p.effort) > 0.0)):
				return "block_tackle: effort is newtons, more than 0, or \"?\""
			return L._flags_problem(p, ["count", "labels"])
		"tall_structure":
			if not STRUCTURES.has(str(p.get("type", ""))):
				return "tall_structure: type is one of %s" % [STRUCTURES]
			return L._parts_problem(p, STRUCTURE_PARTS[str(p.type)], ["pins"])
		"circular_loop":
			if p.has("side") and not SIDES.has(str(p.side)):
				return "circular_loop: side is one of %s" % [SIDES]
			return L._parts_problem(p, _loop_parts(p), ["pins", "words"])
	return "unknown picture kind '%s'" % kind


static func _short(v: Variant, most: int) -> bool:
	return v is String and str(v).strip_edges() != "" and str(v).length() <= most


static func _profile_problem(p: Dictionary) -> String:
	if not L._whole(p.get("top")) or int(p.top) < 3 or int(p.top) > 10:
		return "fitness_profile: top is 3-10"
	var parts: Variant = p.get("parts")
	if not parts is Array or (parts as Array).size() < 3 or (parts as Array).size() > 6:
		return "fitness_profile: 3-6 parts"
	for pt: Variant in parts:
		if not pt is Array or (pt as Array).size() != 2 or not _short(pt[0], MAX_PART_NAME) or not L._number(pt[1]) \
				or float(pt[1]) < 0.0 or float(pt[1]) > float(p.top):
			return "fitness_profile: a part is [name (1-%d letters), score 0-top]" % MAX_PART_NAME
	if p.has("after"):
		var after: Variant = p.after
		if not after is Array or (after as Array).size() != (parts as Array).size():
			return "fitness_profile: after has a score for each part"
		for v: Variant in after:
			if not L._number(v) or float(v) < 0.0 or float(v) > float(p.top):
				return "fitness_profile: every retest score is 0-top"
	if p.has("title") and not _short(p.title, MAX_TITLE):
		return "fitness_profile: a title of 1-%d letters" % MAX_TITLE
	if p.has("mark") and (not L._whole(p.mark) or int(p.mark) < 0 or int(p.mark) >= (parts as Array).size()):
		return "fitness_profile: mark is a part's index"
	return ""


static func _wheel_problem(p: Dictionary) -> String:
	var slices: Variant = p.get("slices")
	if not slices is Array or (slices as Array).size() < 2 or (slices as Array).size() > WHEEL_COLOURS.size():
		return "chance_wheel: 2-%d groups of slices" % WHEEL_COLOURS.size()
	var total := 0
	for s: Variant in slices:
		if not s is Array or (s as Array).size() < 2 or (s as Array).size() > 3 or not _short(s[0], MAX_GROUP_NAME) \
				or not L._whole(s[1]) or int(s[1]) < 1 or int(s[1]) > 20:
			return "chance_wheel: a group is [name (1-%d letters), count (1-20), gold?]" % MAX_GROUP_NAME
		if (s as Array).size() == 3 and (not L._number(s[2]) or float(s[2]) < 0.0):
			return "chance_wheel: a prize is 0 gold or more"
		total += int(s[1])
	if total < 2 or total > MAX_SLICES:
		return "chance_wheel: 2-%d slices in all" % MAX_SLICES
	if p.has("cost") and (not L._number(p.cost) or float(p.cost) < 0.0):
		return "chance_wheel: cost is 0 gold or more"
	for key: String in ["pointer", "mark", "hide"]:
		if p.has(key) and (not L._whole(p[key]) or int(p[key]) < 0 or int(p[key]) >= (slices as Array).size()):
			return "chance_wheel: %s is a group's index" % key
	return ""


static func _plan_problem(p: Dictionary) -> String:
	if not L._whole(p.get("columns")) or int(p.columns) < 4 or int(p.columns) > MAX_COLUMNS:
		return "making_plan: columns is 4-%d" % MAX_COLUMNS
	var tasks: Variant = p.get("tasks")
	if not tasks is Array or (tasks as Array).size() < 2 or (tasks as Array).size() > MAX_TASKS:
		return "making_plan: 2-%d tasks" % MAX_TASKS
	for t: Variant in tasks:
		if not t is Array or (t as Array).size() != 3 or not _short(t[0], MAX_TASK) or not L._whole(t[1]) \
				or not L._whole(t[2]) or int(t[1]) < 0 or int(t[2]) < 1 or int(t[1]) + int(t[2]) > int(p.columns):
			return "making_plan: a task is [name (1-%d letters), start, length], inside the columns" % MAX_TASK
	if p.has("unit") and not _short(p.unit, MAX_UNIT):
		return "making_plan: unit is 1-%d letters" % MAX_UNIT
	if p.has("today") and (not L._whole(p.today) or int(p.today) < 1 or int(p.today) > int(p.columns)):
		return "making_plan: today is a column, 1-columns"
	for key: String in ["mark", "hide"]:
		if p.has(key) and (not L._whole(p[key]) or int(p[key]) < 0 or int(p[key]) >= (tasks as Array).size()):
			return "making_plan: %s is a task's index" % key
	return ""


static func _train_problem(p: Dictionary) -> String:
	var stages: Variant = p.get("stages")
	if not stages is Array or (stages as Array).is_empty() or (stages as Array).size() > MAX_STAGES:
		return "gear_train: 1-%d stages" % MAX_STAGES
	for s: Variant in stages:
		if not s is Array or (s as Array).size() != 2:
			return "gear_train: a stage is [driver, driven]"
		for t: Variant in s:
			if not L._whole(t) or int(t) < MIN_TEETH or int(t) > MAX_TEETH:
				return "gear_train: every gear has %d-%d teeth" % [MIN_TEETH, MAX_TEETH]
	if p.has("rpm") and (not L._number(p.rpm) or float(p.rpm) < 1.0 or float(p.rpm) > 10000.0):
		return "gear_train: rpm is 1-10,000"
	if p.has("out") and not _short(p.out, MAX_OUT):
		return "gear_train: out is 1-%d letters" % MAX_OUT
	if p.has("turn") and not TURNS.has(str(p.turn)):
		return "gear_train: turn is cw or acw"
	if p.has("hide") and (not L._whole(p.hide) or int(p.hide) < 0 or int(p.hide) >= (stages as Array).size() * 2):
		return "gear_train: hide is a gear's index"
	return L._flags_problem(p, ["arrows", "values", "labels"])


# --- Drawing ----------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"fitness_profile":
			_draw_profile(pic, font, r, d)
		"feeling_curve":
			_draw_feeling(pic, font, r, d)
		"chance_wheel":
			_draw_wheel(pic, font, r, d)
		"cpr_aed":
			_draw_cpr(pic, font, r, d)
		"making_plan":
			_draw_plan(pic, font, r, d)
		"smart_material":
			_draw_smart(pic, font, r, d)
		"gear_train":
			_draw_train(pic, font, r, d)
		"block_tackle":
			_draw_tackle(pic, font, r, d)
		"tall_structure":
			_draw_structure(pic, font, r, d)
		"circular_loop":
			_draw_loops(pic, font, r, d)


## A number as the lessons write it: 1,200, 4.5, 2.25.
static func _num(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return GenKit.fmt(roundi(v))
	var s := "%.2f" % v
	return s.rstrip("0").rstrip(".")


static func _dashed(ci: CanvasItem, from: Vector2, to: Vector2, colour: Color, width: float, dash: float = 7.0) -> void:
	var length := from.distance_to(to)
	if length < 1.0:
		return
	var dir := (to - from) / length
	var t := 0.0
	while t < length:
		ci.draw_line(from + dir * t, from + dir * minf(t + dash, length), colour, width, true)
		t += dash * 2.0


## A turning arrow round `c`: clockwise or anticlockwise, over the top.
static func _turn_arrow(ci: CanvasItem, c: Vector2, radius: float, turn: String, colour: Color) -> void:
	var a0 := -PI * 0.85
	var a1 := -PI * 0.15
	ci.draw_arc(c, radius, a0, a1, 18, colour, 2.5, true)
	var end_a := a1 if turn == "cw" else a0
	var tip := c + Vector2(cos(end_a), sin(end_a)) * radius
	var along := Vector2(-sin(end_a), cos(end_a)) * (1.0 if turn == "cw" else -1.0)
	var side := Vector2(cos(end_a), sin(end_a))
	var h := maxf(6.0, radius * 0.35)
	ci.draw_colored_polygon(PackedVector2Array([tip + along * h, tip - side * h * 0.5, tip + side * h * 0.5]), colour)


## Mark (an orange ring) on an unlabelled diagram's part.
static func _ring_mark(ci: CanvasItem, a: Rect2, d: Dictionary) -> void:
	if d.has("mark") and not bool(d.get("labels", false)):
		var at: Vector2 = _anchors(d, a).get(str(d.mark), Vector2(-1, -1))
		if at.x >= 0.0:
			ci.draw_arc(at, a.size.y * 0.1, 0.0, TAU, 28, ORANGE, 3.5)


static func _finish_diagram(ci: CanvasItem, font: Font, r: Rect2, a: Rect2, d: Dictionary) -> void:
	_ring_mark(ci, a, d)
	if bool(d.get("labels", false)):
		L._label_parts(ci, font, r, d, _anchors(d, a), L._fs(r, 12.0))


# --- A fitness profile ------------------------------------------------------------------------------------------------

static func _draw_profile(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := L._fs(r, 13.0)
	var parts: Array = d.parts
	var n := parts.size()
	var top := int(d.top)
	var title_h := 0.0
	var key_w := r.size.x * 0.24 if d.has("after") else 0.0
	var area := Rect2(r.position + Vector2(0, title_h), r.size - Vector2(key_w, title_h))
	var c := area.get_center()
	var radius := minf(area.size.y * 0.5 - fs * 1.3, area.size.x * 0.5 - fs * 4.0)
	radius = maxf(radius, 12.0)
	if d.has("title"):
		L._say_from(ci, font, Vector2(r.position.x + 2.0, r.position.y + fs * 0.7), str(d.title),
			L._fit(font, str(d.title), fs, r.size.x * 0.3), INK, false, false)
	var dirs: Array[Vector2] = []
	for i in n:
		var ang := -PI * 0.5 + TAU * i / n
		dirs.append(Vector2(cos(ang), sin(ang)))
	for ring in range(1, top + 1):
		var pts := PackedVector2Array()
		for i in n:
			pts.append(c + dirs[i] * radius * ring / top)
		pts.append(pts[0])
		ci.draw_polyline(pts, GREY if ring < top else INK, 1.0 if ring < top else 1.5, true)
	for i in n:
		ci.draw_line(c, c + dirs[i] * radius, GREY, 1.0, true)
	var sfs := maxi(8, fs - 4)
	var every := 1 if top <= 5 else 2
	for ring in range(every, top, every):
		L._say(ci, font, c + dirs[0] * radius * ring / top + Vector2(sfs * 0.6, -sfs * 0.3), str(ring), sfs, GREY)
	var shape := PackedVector2Array()
	for i in n:
		shape.append(c + dirs[i] * radius * float(parts[i][1]) / top)
	ci.draw_colored_polygon(shape, Color(BLUE, 0.28))
	var closed := shape.duplicate()
	closed.append(shape[0])
	ci.draw_polyline(closed, BLUE, 2.5, true)
	for v in shape:
		ci.draw_circle(v, 3.5, BLUE)
	if d.has("after"):
		var after := PackedVector2Array()
		for i in n:
			after.append(c + dirs[i] * radius * float(d.after[i]) / top)
		for i in n:
			_dashed(ci, after[i], after[(i + 1) % n], ORANGE, 2.5, 6.0)
			ci.draw_circle(after[i], 3.5, ORANGE)
		var kx := r.end.x - key_w + 6.0
		var ky := r.position.y + r.size.y * 0.4
		ci.draw_line(Vector2(kx, ky), Vector2(kx + 22, ky), BLUE, 3.0)
		L._say_from(ci, font, Vector2(kx + 28, ky), "first test", L._fit(font, "first test", sfs + 1, key_w - 34), INK)
		_dashed(ci, Vector2(kx, ky + fs * 1.6), Vector2(kx + 22, ky + fs * 1.6), ORANGE, 3.0, 5.0)
		L._say_from(ci, font, Vector2(kx + 28, ky + fs * 1.6), "retest", sfs + 1, INK)
	for i in n:
		var at := c + dirs[i] * (radius + fs * 0.9)
		var name := str(parts[i][0])
		var colour := ORANGE if d.has("mark") and int(d.mark) == i else INK
		var w := L._text_w(font, name, fs)
		var shift := Vector2(0, 0)
		if dirs[i].x > 0.3:
			shift.x = w * 0.5 - fs * 0.3
		elif dirs[i].x < -0.3:
			shift.x = -w * 0.5 + fs * 0.3
		L._say(ci, font, at + shift, name, fs, colour)


# --- Feelings curves --------------------------------------------------------------------------------------------------

static func _feel_anchor(view: String, part: String) -> Vector2:
	if view == "pressure":
		return {"too little": Vector2(0.24, 0.62), "best zone": Vector2(0.52, 0.2), "too much": Vector2(0.82, 0.62)}[part]
	return {"it rises": Vector2(0.22, 0.48), "the peak": Vector2(0.4, 0.2), "it falls": Vector2(0.85, 0.6),
		"escape": Vector2(0.31, 0.7)}[part]


## The pressure curve's height (0 at the top of the box, 1 at the bottom) at x along it.
static func _pressure_y(x: float) -> float:
	return 0.86 - 0.62 * exp(-pow((x - 0.52) / 0.19, 2.0))


static func _stay_y(x: float) -> float:
	if x < 0.4:
		return 0.8 - 0.55 * pow(x / 0.4, 0.8)
	return 0.25 + 0.55 * (1.0 - exp(-(x - 0.4) * 4.0))


static func _draw_feeling(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := L._fs(r, 13.0)
	var view := str(d.view)
	var labels := bool(d.get("labels", false))
	var a := L._inner(r, fs, labels)
	a = Rect2(a.position + Vector2(fs * 1.4, 0), a.size - Vector2(fs * 1.4, fs * 1.3))
	var origin := L._at(a, 0.0, 0.94)
	if view == "pressure":
		var zones := [[0.0, 0.35, Color(GREY, 0.18)], [0.35, 0.68, Color(GREEN, 0.2)], [0.68, 1.0, Color(RED, 0.15)]]
		for z: Array in zones:
			ci.draw_rect(L._sub(a, float(z[0]), 0.05, float(z[1]), 0.94), z[2])
	L._arrow(ci, origin, L._at(a, 1.0, 0.94), INK, 2.0)
	L._arrow(ci, origin, L._at(a, 0.0, 0.03), INK, 2.0)
	var sfs := maxi(8, fs - 2)
	var x_name := "pressure" if view == "pressure" else "time"
	var y_name := "how well you do" if view == "pressure" else "anxiety"
	L._say(ci, font, L._at(a, 0.5, 0.94) + Vector2(0, fs * 0.85), x_name, sfs, INK, false)
	var yw := L._text_w(font, y_name, sfs)
	ci.draw_set_transform(L._at(a, 0.0, 0.5) + Vector2(-fs * 0.7, yw * 0.5), -PI * 0.5)
	ci.draw_string(font, Vector2(0, sfs * 0.35), y_name, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs, INK)
	ci.draw_set_transform(Vector2.ZERO, 0.0)
	var curve := PackedVector2Array()
	for k in 41:
		var x := k / 40.0
		curve.append(L._at(a, 0.02 + x * 0.96, _pressure_y(x) if view == "pressure" else _stay_y(x)))
	ci.draw_polyline(curve, BLUE, 3.0, true)
	if view == "stay":
		var esc := PackedVector2Array()
		for k in 13:
			var x := k / 40.0
			esc.append(L._at(a, 0.02 + x * 0.96, _stay_y(x)))
		for k in esc.size() - 1:
			_dashed(ci, esc[k], esc[k + 1], RED, 2.5, 4.0)
		var drop_top := esc[esc.size() - 1]
		_dashed(ci, drop_top, Vector2(drop_top.x, L._at(a, 0, 0.86).y), RED, 2.5, 4.0)
		var kx := L._at(a, 0.5, 0.06)
		ci.draw_line(kx, kx + Vector2(22, 0), BLUE, 3.0)
		L._say_from(ci, font, kx + Vector2(28, 0), "if you stay", sfs, INK)
		_dashed(ci, kx + Vector2(0, fs * 1.3), kx + Vector2(22, fs * 1.3), RED, 3.0, 4.0)
		L._say_from(ci, font, kx + Vector2(28, fs * 1.3), "if you escape", sfs, INK)
	if d.has("point") and view == "pressure":
		var x := float(d.point)
		ci.draw_circle(L._at(a, 0.02 + x * 0.96, _pressure_y(x)), maxf(5.0, fs * 0.4), ORANGE)
		ci.draw_arc(L._at(a, 0.02 + x * 0.96, _pressure_y(x)), maxf(5.0, fs * 0.4), 0.0, TAU, 16, INK, 1.5)
	var anchors := {}
	for part: String in FEEL_PARTS[view]:
		var f := _feel_anchor(view, part)
		anchors[part] = L._at(a, f.x, f.y)
	if labels:
		L._label_parts(ci, font, r, d, anchors, L._fs(r, 12.0))
	elif bool(d.get("words", true)):
		for part: String in anchors:
			var said: Array = L._label_of(d, part, part)
			L._say(ci, font, anchors[part], str(said[0]), sfs, said[1])


# --- A prize wheel ----------------------------------------------------------------------------------------------------

## Each slice's group, the groups spread round the wheel as evenly as their counts allow.
static func _slice_groups(slices: Array) -> Array[int]:
	var total := 0
	for s: Variant in slices:
		total += int(s[1])
	var out: Array[int] = []
	var placed: Array[float] = []
	for s: Variant in slices:
		placed.append(0.0)
	for k in total:
		var best := -1
		var best_need := -INF
		for i in slices.size():
			var need := float(slices[i][1]) * (k + 1) / total - placed[i]
			if need > best_need + 0.000001:
				best_need = need
				best = i
		out.append(best)
		placed[best] += 1.0
	return out


static func _draw_wheel(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := L._fs(r, 13.0)
	var slices: Array = d.slices
	var groups := _slice_groups(slices)
	var total := groups.size()
	var key_w := r.size.x * 0.46
	var wheel := Rect2(r.position, Vector2(r.size.x - key_w, r.size.y))
	var radius := minf(wheel.size.x, wheel.size.y - fs * 1.6) * 0.46
	var c := Vector2(wheel.get_center().x, r.position.y + fs * 1.1 + radius + 2.0)
	var step := TAU / total
	var turn := 0.0
	if d.has("pointer"):
		var first := groups.find(int(d.pointer))
		turn = -(first + 0.5) * step
	for k in total:
		var a0 := -PI * 0.5 + turn + k * step
		var pts := PackedVector2Array([c])
		for j in 9:
			var ang := a0 + step * j / 8.0
			pts.append(c + Vector2(cos(ang), sin(ang)) * radius)
		ci.draw_colored_polygon(pts, WHEEL_COLOURS[groups[k]])
		ci.draw_line(c, c + Vector2(cos(a0), sin(a0)) * radius, Color.WHITE, 1.5, true)
	ci.draw_arc(c, radius, 0.0, TAU, 48, INK, 2.5, true)
	ci.draw_circle(c, maxf(4.0, radius * 0.08), INK)
	var tip := c + Vector2(0, -radius + radius * 0.12)
	var pw := maxf(7.0, radius * 0.12)
	ci.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-pw, -pw * 1.9), tip + Vector2(pw, -pw * 1.9)]), INK)
	if d.has("cost"):
		var line := "%s gold a spin" % _num(float(d.cost))
		L._say(ci, font, Vector2(c.x, r.end.y - fs * 0.6), line, L._fit(font, line, fs, wheel.size.x), INK, false)
	var sfs := maxi(9, fs - 1)
	var row_h := minf(fs * 1.7, r.size.y / (slices.size() + 0.5))
	var ky := r.position.y + (r.size.y - row_h * slices.size()) * 0.5 + row_h * 0.5
	var kx := r.end.x - key_w + 8.0
	for i in slices.size():
		var y := ky + i * row_h
		var sw := minf(row_h * 0.7, 18.0)
		L._box(ci, Rect2(kx, y - sw * 0.5, sw, sw), WHEEL_COLOURS[i], INK, 3, 1)
		var name := "?" if d.has("hide") and int(d.hide) == i else str(slices[i][0])
		var line := "%s: %d of %d" % [name, int(slices[i][1]), total]
		var colour := ORANGE if d.has("mark") and int(d.mark) == i else INK
		L._say_from(ci, font, Vector2(kx + sw + 6.0, y), line, L._fit(font, line, sfs, key_w - sw - 16.0), colour)
		if d.has("mark") and int(d.mark) == i:
			ci.draw_rect(Rect2(kx - 4.0, y - row_h * 0.5 + 1.0, key_w - 6.0, row_h - 2.0), ORANGE, false, 2.0)


# --- CPR and the defibrillator ----------------------------------------------------------------------------------------

static func _draw_cpr(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var a := _diagram_box(d, r)
	match str(d.view):
		"hands":
			_cpr_hands(ci, a)
		"pads":
			_cpr_pads(ci, a)
		"machine":
			_cpr_machine(ci, a)
	_finish_diagram(ci, font, r, a, d)


static func _cpr_hands(ci: CanvasItem, a: Rect2) -> void:
	var h := a.size.y
	ci.draw_rect(L._sub(a, 0.0, 0.95, 1.0, 1.0), Color("c9b48a"))
	ci.draw_line(L._at(a, 0.0, 0.95), L._at(a, 1.0, 0.95), INK, 2.0)
	# The rescuer, kneeling beside the person (drawn first: behind).
	var knee := L._at(a, 0.48, 0.94)
	var foot := L._at(a, 0.64, 0.94)
	var hip := L._at(a, 0.5, 0.6)
	var shoulder := L._at(a, 0.333, 0.3)
	var hands := L._at(a, 0.33, 0.705)
	var w := clampf(h * 0.035, 2.5, 7.0)
	var colour := Color("4a5f8a")
	ci.draw_line(foot, knee, colour, w * 1.3, true)
	ci.draw_line(knee, hip, colour, w * 1.4, true)
	ci.draw_line(hip, shoulder, colour, w * 2.0, true)
	ci.draw_line(shoulder, hands, colour, w * 1.1, true)
	ci.draw_line(shoulder + Vector2(w * 0.9, 0), hands + Vector2(w * 0.5, 0), colour, w * 1.1, true)
	var head := L._at(a, 0.262, 0.22)
	ci.draw_line(shoulder, head, colour, w * 1.2, true)
	ci.draw_circle(head, h * 0.075, SKIN)
	ci.draw_arc(head, h * 0.075, 0.0, TAU, 20, INK, 1.5)
	# The person lying on their back, head on the left.
	var pc := L._at(a, 0.12, 0.83)
	ci.draw_circle(pc, h * 0.07, SKIN)
	ci.draw_arc(pc, h * 0.07, 0.0, TAU, 20, INK, 1.5)
	L._box(ci, L._sub(a, 0.17, 0.74, 0.62, 0.92), Color("7fb6e8"), INK, int(h * 0.05), 2)
	L._box(ci, L._sub(a, 0.6, 0.8, 0.95, 0.91), Color("5f7aa8"), INK, int(h * 0.03), 2)
	# The hands, one on top of the other, on the centre of the chest.
	L._box(ci, Rect2(hands + Vector2(-h * 0.07, -h * 0.03), Vector2(h * 0.14, h * 0.05)), SKIN, INK, 4, 1)
	L._box(ci, Rect2(hands + Vector2(-h * 0.06, -h * 0.065), Vector2(h * 0.12, h * 0.045)), SKIN.darkened(0.08), INK, 4, 1)
	# The push: 5 to 6 cm down, and back up.
	var px := L._at(a, 0.235, 0.7)
	var py := L._at(a, 0.235, 0.9)
	L._arrow(ci, px.lerp(py, 0.5), py, ORANGE, 3.0)
	L._arrow(ci, px.lerp(py, 0.5), px, ORANGE, 3.0)


static func _cpr_pads(ci: CanvasItem, a: Rect2) -> void:
	var body := L._pts(a, [Vector2(0.44, 0.1), Vector2(0.56, 0.1), Vector2(0.58, 0.19), Vector2(0.78, 0.23),
		Vector2(0.84, 0.32), Vector2(0.76, 0.34), Vector2(0.72, 0.98), Vector2(0.28, 0.98), Vector2(0.24, 0.34),
		Vector2(0.16, 0.32), Vector2(0.22, 0.23), Vector2(0.42, 0.19)])
	L._poly(ci, body, SKIN, INK, 2.0)
	ci.draw_circle(L._at(a, 0.5, 0.05), a.size.y * 0.06, SKIN)
	ci.draw_arc(L._at(a, 0.5, 0.05), a.size.y * 0.06, 0.0, TAU, 20, INK, 1.5)
	# The collarbones.
	ci.draw_line(L._at(a, 0.47, 0.215), L._at(a, 0.3, 0.255), INK.lightened(0.3), 2.0, true)
	ci.draw_line(L._at(a, 0.53, 0.215), L._at(a, 0.7, 0.255), INK.lightened(0.3), 2.0, true)
	# The pads: below the person's right collarbone (on our left), and on their left side below the armpit.
	var upper := L._sub(a, 0.33, 0.29, 0.45, 0.45)
	var side := L._sub(a, 0.6, 0.53, 0.7, 0.73)
	for pad: Rect2 in [upper, side]:
		L._box(ci, pad, Color.WHITE, INK, 5, 2)
		var hc := pad.get_center()
		ci.draw_circle(hc + Vector2(-pad.size.x * 0.12, -pad.size.y * 0.06), pad.size.x * 0.13, RED)
		ci.draw_circle(hc + Vector2(pad.size.x * 0.12, -pad.size.y * 0.06), pad.size.x * 0.13, RED)
		ci.draw_colored_polygon(PackedVector2Array([hc + Vector2(-pad.size.x * 0.25, 0), hc + Vector2(pad.size.x * 0.25,
			0), hc + Vector2(0, pad.size.y * 0.22)]), RED)
	# The wires to the defibrillator.
	var aed := L._sub(a, 0.84, 0.7, 0.97, 0.92)
	var w1 := PackedVector2Array()
	var w2 := PackedVector2Array()
	for k in 13:
		var t := k / 12.0
		w1.append(L._bez(upper.end - Vector2(upper.size.x * 0.2, 0), L._at(a, 0.45, 0.9), aed.position + Vector2(0,
			aed.size.y * 0.7), t))
		w2.append(L._bez(side.end - Vector2(0, side.size.y * 0.3), L._at(a, 0.8, 0.62), aed.position + Vector2(0,
			aed.size.y * 0.3), t))
	ci.draw_polyline(w1, INK, 1.5, true)
	ci.draw_polyline(w2, INK, 1.5, true)
	L._box(ci, aed, GREEN, INK, 5, 2)
	ci.draw_circle(aed.get_center(), aed.size.y * 0.2, Color.WHITE)


static func _cpr_machine(ci: CanvasItem, a: Rect2) -> void:
	L._box(ci, L._sub(a, 0.4, 0.02, 0.6, 0.12), GREEN.darkened(0.3), INK, 8, 2)
	L._box(ci, L._sub(a, 0.44, 0.04, 0.56, 0.1), PAPER, INK, 4, 1)
	L._box(ci, L._sub(a, 0.08, 0.1, 0.92, 0.94), GREEN, INK, 14, 3)
	L._box(ci, L._sub(a, 0.13, 0.17, 0.87, 0.88), Color("f6f7f2"), INK, 10, 2)
	# The heart and lightning sign.
	var hs := L._at(a, 0.5, 0.32)
	var s := a.size.y * 0.07
	ci.draw_circle(hs + Vector2(-s * 0.55, -s * 0.2), s * 0.6, RED)
	ci.draw_circle(hs + Vector2(s * 0.55, -s * 0.2), s * 0.6, RED)
	ci.draw_colored_polygon(PackedVector2Array([hs + Vector2(-s * 1.12, 0), hs + Vector2(s * 1.12, 0), hs + Vector2(0,
		s * 1.3)]), RED)
	_bolt(ci, hs + Vector2(0, s * 0.1), s * 0.8, Color.WHITE)
	# The on button and the shock button.
	var on := L._at(a, 0.26, 0.48)
	ci.draw_circle(on, a.size.y * 0.09, GREEN.lightened(0.2))
	ci.draw_arc(on, a.size.y * 0.09, 0.0, TAU, 24, INK, 2.0)
	ci.draw_arc(on, a.size.y * 0.045, -PI * 0.3, PI * 1.3, 16, INK, 2.5)
	ci.draw_line(on + Vector2(0, -a.size.y * 0.06), on + Vector2(0, -a.size.y * 0.015), INK, 2.5)
	var shock := L._at(a, 0.44, 0.72)
	ci.draw_circle(shock, a.size.y * 0.1, ORANGE)
	ci.draw_arc(shock, a.size.y * 0.1, 0.0, TAU, 24, INK, 2.0)
	_bolt(ci, shock, a.size.y * 0.07, Color.WHITE)
	# The speaker's grille.
	var sp := L._at(a, 0.74, 0.3)
	for k in 4:
		var y := sp.y + (k - 1.5) * a.size.y * 0.04
		ci.draw_line(Vector2(sp.x - a.size.x * 0.07, y), Vector2(sp.x + a.size.x * 0.07, y), INK, 2.0)
	# The pads in their pouch, plugged in.
	var pouch := L._sub(a, 0.65, 0.55, 0.85, 0.83)
	L._box(ci, pouch, Color("dfe3ea"), INK, 6, 2)
	L._box(ci, Rect2(pouch.position + pouch.size * Vector2(0.15, 0.2), pouch.size * Vector2(0.32, 0.5)), Color.WHITE, INK,
		3, 1)
	L._box(ci, Rect2(pouch.position + pouch.size * Vector2(0.55, 0.3), pouch.size * Vector2(0.32, 0.5)), Color.WHITE, INK,
		3, 1)
	ci.draw_line(L._at(a, 0.75, 0.83), L._at(a, 0.75, 0.9), INK, 3.0)


static func _bolt(ci: CanvasItem, c: Vector2, s: float, colour: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.15, -s), c + Vector2(-s * 0.45, s * 0.1),
		c + Vector2(-s * 0.02, s * 0.1), c + Vector2(-s * 0.2, s), c + Vector2(s * 0.45, -s * 0.15), c + Vector2(s * 0.02,
		-s * 0.15)]), colour)


# --- A making plan (a Gantt chart) ------------------------------------------------------------------------------------

static func _draw_plan(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var tasks: Array = d.tasks
	var cols := int(d.columns)
	var fs := L._fs(r, 12.0)
	var name_w := minf(r.size.x * 0.34, fs * 9.5)
	var head_h := fs * 1.6
	var row_h := minf((r.size.y - head_h) / tasks.size(), fs * 2.4)
	var grid := Rect2(r.position + Vector2(name_w, head_h), Vector2(r.size.x - name_w, row_h * tasks.size()))
	var cw := grid.size.x / cols
	var sfs := maxi(8, fs - 2)
	var unit := str(d.get("unit", "lesson"))
	L._say_from(ci, font, Vector2(r.position.x + 2.0, r.position.y + head_h * 0.5), unit + "s:",
		L._fit(font, unit + "s:", sfs, name_w - 6.0), INK)
	if d.has("today"):
		var t := int(d.today) - 1
		ci.draw_rect(Rect2(grid.position + Vector2(t * cw, -head_h), Vector2(cw, grid.size.y + head_h)), Color(GOLD, 0.25))
	for k in cols:
		L._say(ci, font, Vector2(grid.position.x + (k + 0.5) * cw, r.position.y + head_h * 0.5), str(k + 1),
			L._fit(font, str(k + 1), sfs, cw - 2.0), INK, false)
	for k in cols + 1:
		var x := grid.position.x + k * cw
		ci.draw_line(Vector2(x, grid.position.y), Vector2(x, grid.end.y), Color("c9d2e0"), 1.0)
	for i in tasks.size() + 1:
		var y := grid.position.y + i * row_h
		ci.draw_line(Vector2(r.position.x, y), Vector2(grid.end.x, y), Color("c9d2e0"), 1.0)
	for i in tasks.size():
		var t: Array = tasks[i]
		var y := grid.position.y + i * row_h
		var marked := d.has("mark") and int(d.mark) == i
		var hidden := d.has("hide") and int(d.hide) == i
		L._say_from(ci, font, Vector2(r.position.x + 2.0, y + row_h * 0.5), str(t[0]),
			L._fit(font, str(t[0]), fs, name_w - 6.0), ORANGE if marked else INK)
		var bar := Rect2(grid.position.x + int(t[1]) * cw + 2.0, y + row_h * 0.2, int(t[2]) * cw - 4.0, row_h * 0.6)
		if hidden:
			for e: Array in [[bar.position, bar.position + Vector2(bar.size.x, 0)], [bar.position + Vector2(0,
					bar.size.y), bar.end], [bar.position, bar.position + Vector2(0, bar.size.y)], [bar.position
					+ Vector2(bar.size.x, 0), bar.end]]:
				_dashed(ci, e[0], e[1], INK, 1.5, 5.0)
			L._say(ci, font, bar.get_center(), "?", fs, INK)
		else:
			L._box(ci, bar, ORANGE if marked else BLUE, INK, 4, 1)


# --- Smart materials --------------------------------------------------------------------------------------------------

static func _draw_smart(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var a := _diagram_box(d, r)
	var m := str(d.material)
	var fs := L._fs(r, 12.0)
	var words := _smart_words(d)
	var art := _smart_art(d, a)
	if m == "composite":
		_composite(ci, art)
	else:
		var before := L._sub(art, 0.03, 0.08, 0.39, 0.92)
		var after := L._sub(art, 0.61, 0.08, 0.97, 0.92)
		for panel: Rect2 in [before, after]:
			L._box(ci, panel, Color.WHITE, GREY, 8, 1)
		L._arrow(ci, L._at(art, 0.42, 0.5), L._at(art, 0.58, 0.5), ORANGE, 4.0)
		match m:
			"shape_memory":
				_wire(ci, before, true)
				_wire(ci, after, false)
				_flame(ci, L._at(art, 0.5, 0.72), art.size.y * 0.1)
			"thermochromic":
				_spoon(ci, before, Color("5b8fd9"), false)
				_spoon(ci, after, Color("e8748a"), true)
				_flame(ci, L._at(art, 0.5, 0.72), art.size.y * 0.1)
			"photochromic":
				_glasses(ci, before, Color(0.85, 0.93, 1.0, 0.5))
				_glasses(ci, after, Color(0.2, 0.25, 0.35, 0.85))
				_sun(ci, L._at(art, 0.5, 0.25), art.size.y * 0.09)
			"piezoelectric":
				_crystal(ci, before, false)
				_crystal(ci, after, true)
				L._arrow(ci, L._at(art, 0.5, 0.12), L._at(art, 0.5, 0.32), INK, 3.0)
				L._arrow(ci, L._at(art, 0.5, 0.88), L._at(art, 0.5, 0.68), INK, 3.0)
			"hydrogel":
				_gel(ci, before, false)
				_gel(ci, after, true)
				_drop(ci, L._at(art, 0.5, 0.72), art.size.y * 0.08)
	if words:
		var said: Array = SMART_WORDS[m]
		var xs := [0.21, 0.5, 0.79]
		for k in 3:
			var part := str(SMART_PARTS[m][k])
			var lab: Array = L._label_of(d, part, str(said[k]))
			var room := a.size.x * (0.36 if k != 1 else 0.24)
			L._say(ci, font, L._at(a, xs[k], 0.9), str(lab[0]), L._fit(font, str(lab[0]), fs, room), lab[1], false)
	_ring_mark(ci, a, d)
	if bool(d.get("labels", false)):
		L._label_parts(ci, font, r, d, _anchors(d, a), fs)


## Whether a smart_material shows what happens under its panels (not when it is labelled or has pins).
static func _smart_words(d: Dictionary) -> bool:
	return bool(d.get("words", true)) and not bool(d.get("labels", false)) and not bool(d.get("pins", false))


## The part of the box the panels are drawn in (the words take its bottom fifth).
static func _smart_art(d: Dictionary, a: Rect2) -> Rect2:
	return Rect2(a.position, Vector2(a.size.x, a.size.y * (0.8 if _smart_words(d) else 1.0)))


static func _wire(ci: CanvasItem, panel: Rect2, bent: bool) -> void:
	var pts := PackedVector2Array()
	if bent:
		for k in 9:
			var t := k / 8.0
			pts.append(L._at(panel, 0.2 + t * 0.6, 0.5 + (0.25 if k % 2 == 0 else -0.2) * (0.6 + 0.4 * sin(t * 3.0))))
	else:
		pts.append(L._at(panel, 0.15, 0.5))
		pts.append(L._at(panel, 0.85, 0.5))
	ci.draw_polyline(pts, STEEL.darkened(0.3), maxf(3.0, panel.size.y * 0.05), true)


static func _flame(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.55, s * 0.2), c + Vector2(0, s * 0.6),
		c + Vector2(-s * 0.55, s * 0.2)]), ORANGE)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.4), c + Vector2(s * 0.25, s * 0.25), c + Vector2(0,
		s * 0.5), c + Vector2(-s * 0.25, s * 0.25)]), GOLD)


static func _spoon(ci: CanvasItem, panel: Rect2, colour: Color, hot: bool) -> void:
	var bowl := L._at(panel, 0.32, 0.5)
	var rad := panel.size.y * 0.16
	ci.draw_circle(bowl, rad, colour)
	ci.draw_arc(bowl, rad, 0.0, TAU, 24, INK, 1.5)
	ci.draw_line(bowl + Vector2(rad, 0), L._at(panel, 0.88, 0.5), colour, panel.size.y * 0.08, true)
	if hot:
		for k in 3:
			var x := bowl.x - rad * 0.6 + k * rad * 0.6
			var p := PackedVector2Array()
			for j in 6:
				p.append(Vector2(x + sin(j * 1.3) * 3.0, bowl.y - rad * 1.2 - j * panel.size.y * 0.04))
			ci.draw_polyline(p, GREY, 1.5, true)


static func _glasses(ci: CanvasItem, panel: Rect2, tint: Color) -> void:
	var l := L._at(panel, 0.3, 0.5)
	var rr := L._at(panel, 0.7, 0.5)
	var rad := panel.size.x * 0.17
	for c: Vector2 in [l, rr]:
		ci.draw_circle(c, rad, tint)
		ci.draw_arc(c, rad, 0.0, TAU, 24, INK, 2.5)
	ci.draw_line(l + Vector2(rad, 0), rr - Vector2(rad, 0), INK, 2.5)


static func _sun(ci: CanvasItem, c: Vector2, s: float) -> void:
	for k in 8:
		var ang := TAU * k / 8.0
		ci.draw_line(c + Vector2(cos(ang), sin(ang)) * s * 1.2, c + Vector2(cos(ang), sin(ang)) * s * 1.7, GOLD, 2.5)
	ci.draw_circle(c, s, GOLD)


static func _crystal(ci: CanvasItem, panel: Rect2, squeezed: bool) -> void:
	var top := 0.32 if not squeezed else 0.38
	var bot := 0.78 if not squeezed else 0.72
	L._poly(ci, L._pts(panel, [Vector2(0.35, top), Vector2(0.65, top), Vector2(0.72, (top + bot) * 0.5),
		Vector2(0.65, bot), Vector2(0.35, bot), Vector2(0.28, (top + bot) * 0.5)]), Color("cfe3f2"), INK, 2.0)
	if squeezed:
		_bolt(ci, L._at(panel, 0.84, 0.3), panel.size.y * 0.14, GOLD)
		for side in [-1.0, 1.0]:
			L._arrow(ci, L._at(panel, 0.5, 0.5 - side * 0.4), L._at(panel, 0.5, 0.5 - side * 0.17), INK, 2.5)


static func _gel(ci: CanvasItem, panel: Rect2, swollen: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	var n := 9
	for k in n:
		var c := L._at(panel, 0.22 + rng.randf() * 0.56, 0.3 + rng.randf() * 0.5)
		var rad := panel.size.y * (0.12 if swollen else 0.035)
		ci.draw_circle(c, rad, Color(0.55, 0.8, 0.95, 0.7 if swollen else 1.0))
		ci.draw_arc(c, rad, 0.0, TAU, 16, Color("3f86d0"), 1.2)


static func _drop(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 1.3), c + Vector2(s * 0.7, 0), c + Vector2(0, s * 0.8),
		c + Vector2(-s * 0.7, 0)]), WATER)
	ci.draw_circle(c + Vector2(0, s * 0.05), s * 0.7, WATER)


## A composite's block: layers of fibres (each layer's fibres another way) set in a resin matrix, cut open.
static func _composite(ci: CanvasItem, a: Rect2) -> void:
	var front := L._sub(a, 0.2, 0.38, 0.72, 0.9)
	var depth := Vector2(a.size.x * 0.12, -a.size.y * 0.26)
	L._poly(ci, [front.position, front.position + depth, front.position + Vector2(front.size.x, 0) + depth,
		front.position + Vector2(front.size.x, 0)], Color("e9d8a6"), INK, 2.0)
	L._poly(ci, [front.position + Vector2(front.size.x, 0), front.position + Vector2(front.size.x, 0) + depth,
		front.end + depth, front.end], Color("d8c48c"), INK, 2.0)
	ci.draw_rect(front, Color("f2e3b5"))
	var layers := 4
	for k in layers:
		var y0 := front.position.y + front.size.y * k / layers
		ci.draw_line(Vector2(front.position.x, y0), Vector2(front.end.x, y0), Color("c9b06a"), 1.0)
		var yc := y0 + front.size.y / layers * 0.5
		if k % 2 == 0:
			ci.draw_line(Vector2(front.position.x + 3.0, yc), Vector2(front.end.x - 3.0, yc), INK, 3.0)
			ci.draw_line(Vector2(front.position.x + 3.0, yc - 5.0), Vector2(front.end.x - 3.0, yc - 5.0), INK, 2.0)
		else:
			for j in 12:
				ci.draw_circle(Vector2(front.position.x + front.size.x * (j + 0.5) / 12.0, yc), 2.6, INK)
	for j in 8:
		var t := (j + 0.5) / 8.0
		var p0 := front.position + Vector2(front.size.x * t, 0)
		ci.draw_line(p0 + depth * 0.15, p0 + depth * 0.85, INK, 2.5)
	ci.draw_rect(front, INK, false, 2.0)


# --- A gear train -------------------------------------------------------------------------------------------------------

static func _gear(ci: CanvasItem, c: Vector2, radius: float, teeth: int, fill: Color) -> void:
	var depth := clampf(radius * 0.14, 2.0, 9.0)
	var ro := radius
	var ri := radius - depth
	var pts := PackedVector2Array()
	var step := TAU / teeth
	for k in teeth:
		var a0 := k * step
		pts.append(c + Vector2(cos(a0), sin(a0)) * ri)
		pts.append(c + Vector2(cos(a0 + step * 0.15), sin(a0 + step * 0.15)) * ro)
		pts.append(c + Vector2(cos(a0 + step * 0.45), sin(a0 + step * 0.45)) * ro)
		pts.append(c + Vector2(cos(a0 + step * 0.6), sin(a0 + step * 0.6)) * ri)
	ci.draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, INK, 1.5, true)
	ci.draw_circle(c, maxf(2.5, radius * 0.1), INK)


static func _draw_train(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var stages: Array = d.stages
	var fs := L._fs(r, 13.0)
	var teeth: Array[int] = []
	for s: Variant in stages:
		teeth.append(int(s[0]))
		teeth.append(int(s[1]))
	# Centres in teeth-units: gear 0 at 0; a meshing gear one radius sum on; a shaft's second gear at the same place.
	var xs: Array[float] = [0.0]
	for i in range(1, teeth.size()):
		if i % 2 == 1:
			xs.append(xs[i - 1] + teeth[i - 1] + teeth[i])
		else:
			xs.append(xs[i - 1])
	var left := -float(teeth[0])
	var right := 0.0
	var tall := 0.0
	for i in teeth.size():
		right = maxf(right, xs[i] + teeth[i])
		tall = maxf(tall, 2.0 * teeth[i])
	var below := fs * (2.6 if bool(d.get("labels", false)) else 1.5)
	var room := Rect2(r.position + Vector2(4, fs * 0.6), r.size - Vector2(8, below + fs * 0.6))
	var scale := minf(room.size.x / (right - left), room.size.y / tall)
	var cy := room.position.y + room.size.y * 0.5
	var x0 := room.get_center().x - (left + right) * 0.5 * scale
	var turns := train_turns(stages, str(d.get("turn", "cw")))
	var fills: Array[Color] = [Color("f0c96a"), Color("9cc3f0"), Color("a8d8a0"), Color("f2a6a0"), Color("d7b8ea"),
		Color("f5d29a")]
	# Shared shafts: the bigger gear behind, the smaller in front.
	var order: Array = range(teeth.size())
	order.sort_custom(func(i: int, j: int) -> bool:
		if is_equal_approx(xs[i], xs[j]):
			return teeth[i] > teeth[j]
		return i < j)
	for i: int in order:
		_gear(ci, Vector2(x0 + xs[i] * scale, cy), teeth[i] * scale, teeth[i], fills[i])
	var sfs := maxi(8, fs - 2)
	for i in teeth.size():
		var c := Vector2(x0 + xs[i] * scale, cy)
		var rad := teeth[i] * scale
		if bool(d.get("values", true)):
			var shared := (i % 2 == 1 and i + 1 < teeth.size()) or (i % 2 == 0 and i > 0)
			var t := "?" if d.has("hide") and int(d.hide) == i else str(teeth[i])
			var at := c + Vector2(0, -rad * 0.55)
			if shared:
				var front := teeth[i] < teeth[i + 1 if i % 2 == 1 else i - 1]
				at = c + Vector2(0, rad * 0.5) if front else c + Vector2(0, -rad + fs * 0.9)
			L._say(ci, font, at, t, L._fit(font, t, sfs, maxf(rad * 1.2, 14.0)), INK)
		if i == 0 or bool(d.get("arrows", false)):
			var front := not ((i % 2 == 1 and i + 1 < teeth.size() and teeth[i] > teeth[i + 1]) or (i % 2 == 0 and i > 0
				and teeth[i] > teeth[i - 1]))
			if front or i == 0:
				_turn_arrow(ci, c, maxf(rad * 0.38, 7.0), turns[i], RED)
	var base := r.end.y - below + fs * 0.2
	if d.has("rpm"):
		var t := "%s rpm" % _num(float(d.rpm))
		L._say(ci, font, Vector2(x0, base + fs * 0.5), t, sfs, INK, false)
	if d.has("out"):
		L._say(ci, font, Vector2(x0 + xs[-1] * scale, base + fs * 0.5), str(d.out), sfs, ORANGE, false)
	if bool(d.get("labels", false)):
		var ly := base + fs * 1.6
		L._say(ci, font, Vector2(x0, ly), "driver", sfs, INK, false)
		L._say(ci, font, Vector2(x0 + xs[-1] * scale, ly), "driven", sfs, INK, false)
		for k in range(1, stages.size()):
			L._say(ci, font, Vector2(x0 + xs[2 * k] * scale, ly), "same shaft", sfs, INK, false)


# --- A block and tackle -------------------------------------------------------------------------------------------------

static func _draw_tackle(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := L._fs(r, 13.0)
	var a := L._fit_box(r, 1.25)
	var n := int(d.ropes)
	var sfs := maxi(8, fs - 2)
	ci.draw_rect(L._sub(a, 0.08, 0.0, 0.72, 0.05), Color("8a6a4a"))
	ci.draw_rect(L._sub(a, 0.08, 0.0, 0.72, 0.05), INK, false, 1.5)
	var x0 := 0.26
	var x1 := 0.54
	var fixed_y := 0.17
	var moving_y := 0.55
	var xs: Array[float] = []
	for k in n:
		xs.append(x0 + (x1 - x0) * (k / float(maxi(n - 1, 1)) if n > 1 else 0.5))
	var pulley_r := a.size.y * 0.05
	# The fixed block (hanging from the beam) and the moving block (on the crate).
	ci.draw_line(L._at(a, 0.4, 0.05), L._at(a, 0.4, fixed_y - 0.05), INK, 2.5)
	L._box(ci, L._sub(a, x0 - 0.05, fixed_y - 0.06, x1 + 0.12, fixed_y + 0.06), Color("dfe3ea"), INK, 5, 2)
	if n > 1:
		L._box(ci, L._sub(a, x0 - 0.05, moving_y - 0.05, x1 + 0.05, moving_y + 0.05), Color("dfe3ea"), INK, 5, 2)
	var rope := Color("8a5a2a")
	var rw := maxf(2.0, a.size.y * 0.012)
	var top_y := L._at(a, 0, fixed_y + 0.05).y
	var low_y := L._at(a, 0, moving_y - 0.04).y if n > 1 else L._at(a, 0, 0.62).y
	for k in n:
		var x := L._at(a, xs[k], 0).x
		ci.draw_line(Vector2(x, top_y), Vector2(x, low_y), rope, rw, true)
		if bool(d.get("count", false)):
			L._say(ci, font, Vector2(x + sfs * 0.6, (top_y + low_y) * 0.5), str(k + 1), sfs, BLUE)
	for k in n:
		ci.draw_circle(L._at(a, xs[k], fixed_y), pulley_r, GREY)
		ci.draw_arc(L._at(a, xs[k], fixed_y), pulley_r, 0.0, TAU, 16, INK, 1.5)
	# The rope's free end: over the last fixed pulley and down to the hand.
	var free_x := x1 + 0.08
	ci.draw_circle(L._at(a, free_x, fixed_y), pulley_r, GREY)
	ci.draw_arc(L._at(a, free_x, fixed_y), pulley_r, 0.0, TAU, 16, INK, 1.5)
	var pull_top := L._at(a, free_x + 0.04, fixed_y)
	var hand := L._at(a, free_x + 0.04, 0.78)
	ci.draw_line(pull_top, hand, rope, rw, true)
	ci.draw_circle(hand, a.size.y * 0.035, SKIN)
	L._arrow(ci, hand + Vector2(a.size.x * 0.05, -a.size.y * 0.1), hand + Vector2(a.size.x * 0.05, a.size.y * 0.1), RED,
		3.0)
	var effort := ""
	if d.has("effort"):
		effort = "?" if str(d.effort) == "?" else "%s N" % _num(float(d.effort))
	if bool(d.get("labels", false)):
		effort = "effort" + (" " + effort if effort != "" else "")
	if effort != "":
		L._say_from(ci, font, hand + Vector2(a.size.x * 0.09, 0), effort, sfs, RED)
	# The crate.
	var hook := L._at(a, (x0 + x1) * 0.5, 0.62)
	if n > 1:
		ci.draw_line(L._at(a, (x0 + x1) * 0.5, moving_y + 0.05), hook, INK, 2.5)
	else:
		ci.draw_line(L._at(a, xs[0], 0.6), hook, INK, 2.5)
	var crate := L._sub(a, (x0 + x1) * 0.5 - 0.15, 0.64, (x0 + x1) * 0.5 + 0.15, 0.94)
	L._box(ci, crate, Color("c98b4f"), INK, 3, 2)
	ci.draw_line(crate.position, crate.end, Color("8a5a2a"), 1.5)
	ci.draw_line(crate.position + Vector2(crate.size.x, 0), crate.position + Vector2(0, crate.size.y), Color("8a5a2a"), 1.5)
	var load_text := ""
	if d.has("load"):
		load_text = "%s N" % _num(float(d.load))
	if bool(d.get("labels", false)):
		load_text = "load" + (" " + load_text if load_text != "" else "")
	if load_text != "":
		L._box(ci, Rect2(crate.get_center() - Vector2(L._text_w(font, load_text, sfs) * 0.5 + 4.0, sfs * 0.75),
			Vector2(L._text_w(font, load_text, sfs) + 8.0, sfs * 1.5)), Color.WHITE, INK, 4, 1)
		L._say(ci, font, crate.get_center(), load_text, sfs, INK, false)
	if bool(d.get("labels", false)):
		L._say_from(ci, font, L._at(a, x1 + 0.15, fixed_y - 0.02), "fixed block", sfs, INK)
		if n > 1:
			L._say_from(ci, font, L._at(a, x0 - 0.07, moving_y), "moving block", sfs, INK, true)


# --- Big structures -----------------------------------------------------------------------------------------------------

static func _draw_structure(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var a := _diagram_box(d, r)
	match str(d.type):
		"damper":
			_tower(ci, a)
		"isolation":
			_isolated(ci, a)
		"suspension":
			_suspension(ci, a)
		"cable_stayed":
			_cable_stayed(ci, a)
	_finish_diagram(ci, font, r, a, d)


static func _tower(ci: CanvasItem, a: Rect2) -> void:
	ci.draw_rect(L._sub(a, 0.0, 0.0, 1.0, 0.82), SKY)
	ci.draw_rect(L._sub(a, 0.0, 0.82, 1.0, 1.0), GROUND)
	var body := L._sub(a, 0.36, 0.06, 0.64, 0.82)
	ci.draw_rect(body, Color("c9d6e6"))
	for row in 14:
		for col in 4:
			ci.draw_rect(Rect2(body.position + Vector2(body.size.x * (0.08 + col * 0.235), body.size.y * (0.04 + row
				* 0.068)), Vector2(body.size.x * 0.14, body.size.y * 0.04)), Color("8fb3d9"))
	ci.draw_rect(L._sub(a, 0.47, 0.06, 0.53, 0.82), Color(INK, 0.35))
	for k in 3:
		var y0 := 0.58 + k * 0.08
		for side in [[0.36, 0.45], [0.55, 0.64]]:
			ci.draw_line(L._at(a, side[0], y0), L._at(a, side[1], y0 + 0.08), INK, 1.8)
			ci.draw_line(L._at(a, side[1], y0), L._at(a, side[0], y0 + 0.08), INK, 1.8)
	ci.draw_rect(body, INK, false, 2.0)
	ci.draw_line(L._at(a, 0.46, 0.08), L._at(a, 0.49, 0.18), INK, 1.5)
	ci.draw_line(L._at(a, 0.54, 0.08), L._at(a, 0.51, 0.18), INK, 1.5)
	ci.draw_circle(L._at(a, 0.5, 0.2), a.size.y * 0.04, GOLD)
	ci.draw_arc(L._at(a, 0.5, 0.2), a.size.y * 0.04, 0.0, TAU, 20, INK, 1.5)
	for k in 4:
		var x := 0.4 + k * 0.067
		ci.draw_line(L._at(a, x, 0.82), L._at(a, x, 0.97), INK.lightened(0.2), 3.0)
	for y in [0.24, 0.4, 0.56]:
		L._arrow(ci, L._at(a, 0.05, y), L._at(a, 0.3, y), BLUE, 3.0)


static func _isolated(ci: CanvasItem, a: Rect2) -> void:
	ci.draw_rect(L._sub(a, 0.0, 0.0, 1.0, 0.78), SKY)
	ci.draw_rect(L._sub(a, 0.0, 0.78, 1.0, 1.0), GROUND)
	ci.draw_rect(L._sub(a, 0.2, 0.73, 0.8, 0.78), Color("9aa1ab"))
	ci.draw_rect(L._sub(a, 0.2, 0.73, 0.8, 0.78), INK, false, 1.5)
	for k in 4:
		var x := 0.27 + k * 0.155
		L._box(ci, L._sub(a, x - 0.04, 0.665, x + 0.04, 0.725), Color("2b2b2b"), INK, 4, 1)
	var b := L._sub(a, 0.24, 0.2, 0.76, 0.665)
	ci.draw_rect(b, Color("f2e3c6"))
	for k in 4:
		var y := b.position.y + b.size.y * (k + 1) / 4.0
		ci.draw_line(Vector2(b.position.x, y), Vector2(b.end.x, y), INK, 1.5)
	for k in 5:
		var x := b.position.x + b.size.x * k / 4.0
		ci.draw_line(Vector2(x, b.position.y), Vector2(x, b.end.y), Color("6f7d8f"), 3.0)
	for k in 4:
		for j in 6:
			ci.draw_rect(Rect2(b.position + Vector2(b.size.x * (0.04 + j * 0.16), b.size.y * (0.06 + k * 0.25)),
				Vector2(b.size.x * 0.09, b.size.y * 0.12)), Color("8fb3d9"))
	ci.draw_rect(b, INK, false, 2.0)
	L._arrow(ci, L._at(a, 0.42, 0.9), L._at(a, 0.2, 0.9), RED, 3.0)
	L._arrow(ci, L._at(a, 0.58, 0.9), L._at(a, 0.8, 0.9), RED, 3.0)
	ci.draw_line(L._at(a, 0.42, 0.9), L._at(a, 0.58, 0.9), RED, 3.0)


static func _water_and_deck(ci: CanvasItem, a: Rect2) -> void:
	ci.draw_rect(L._sub(a, 0.0, 0.0, 1.0, 0.85), SKY)
	ci.draw_rect(L._sub(a, 0.0, 0.85, 1.0, 1.0), WATER)
	ci.draw_rect(L._sub(a, 0.0, 0.6, 1.0, 0.645), Color("6f7d8f"))
	ci.draw_rect(L._sub(a, 0.0, 0.6, 1.0, 0.645), INK, false, 1.5)


static func _suspension(ci: CanvasItem, a: Rect2) -> void:
	_water_and_deck(ci, a)
	for x in [0.3, 0.7]:
		ci.draw_rect(L._sub(a, x - 0.012, 0.13, x + 0.012, 0.9), Color("b8bfca"))
		ci.draw_rect(L._sub(a, x - 0.012, 0.13, x + 0.012, 0.9), INK, false, 1.5)
	var cable := PackedVector2Array()
	cable.append(L._at(a, 0.04, 0.62))
	for k in 21:
		var x := 0.3 + 0.4 * k / 20.0
		cable.append(L._at(a, x, 0.55 - 0.4 * pow((x - 0.5) / 0.2, 2.0)))
	cable.append(L._at(a, 0.96, 0.62))
	var cable_pts := PackedVector2Array([L._at(a, 0.04, 0.66), L._at(a, 0.3, 0.15)])
	cable_pts.append_array(cable.slice(1, cable.size() - 1))
	cable_pts.append(L._at(a, 0.96, 0.66))
	for k in 19:
		var x := 0.32 + 0.36 * k / 18.0
		ci.draw_line(L._at(a, x, 0.55 - 0.4 * pow((x - 0.5) / 0.2, 2.0)), L._at(a, x, 0.6), INK, 1.0)
	for k in 6:
		var x := 0.06 + k * 0.04
		var yc := 0.66 - (0.66 - 0.15) * (x - 0.04) / 0.26
		ci.draw_line(L._at(a, x, yc), L._at(a, x, 0.6), INK, 1.0)
		var xr := 1.0 - x
		ci.draw_line(L._at(a, xr, yc), L._at(a, xr, 0.6), INK, 1.0)
	ci.draw_polyline(cable_pts, Color("c0392b"), maxf(2.0, a.size.y * 0.015), true)
	for x in [0.0, 0.94]:
		ci.draw_rect(L._sub(a, x, 0.62, x + 0.06, 0.76), Color("9aa1ab"))
		ci.draw_rect(L._sub(a, x, 0.62, x + 0.06, 0.76), INK, false, 1.5)


static func _cable_stayed(ci: CanvasItem, a: Rect2) -> void:
	_water_and_deck(ci, a)
	ci.draw_rect(L._sub(a, 0.488, 0.06, 0.512, 0.6), Color("b8bfca"))
	ci.draw_rect(L._sub(a, 0.488, 0.06, 0.512, 0.6), INK, false, 1.5)
	ci.draw_rect(L._sub(a, 0.47, 0.645, 0.53, 0.92), Color("9aa1ab"))
	ci.draw_rect(L._sub(a, 0.47, 0.645, 0.53, 0.92), INK, false, 1.5)
	for k in 6:
		var y := 0.1 + k * 0.035
		var reach := 0.42 - k * 0.06
		ci.draw_line(L._at(a, 0.5, y), L._at(a, 0.5 - reach, 0.6), Color("c0392b"), 1.6, true)
		ci.draw_line(L._at(a, 0.5, y), L._at(a, 0.5 + reach, 0.6), Color("c0392b"), 1.6, true)


# --- The circular economy's loops ---------------------------------------------------------------------------------------

static func _draw_loops(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var a := _diagram_box(d, r)
	var fs := L._fs(r, 13.0)
	var sfs := maxi(8, fs - 2)
	var parts := _loop_parts(d)
	var show_words := bool(d.get("words", true)) and not bool(d.get("labels", false)) and not bool(d.get("pins", false))
	var bw := a.size.x * 0.14
	var bh := a.size.y * 0.13
	var number := 0
	var key_fs := sfs
	var n_key := 0
	for part: String in TECH_LOOPS + BIO_LOOPS:
		if parts.has(part):
			n_key += 1
			key_fs = mini(key_fs, L._fit(font, "%d %s" % [n_key, part], sfs, a.size.x * 0.15))
	for part: String in TECH_LOOPS + BIO_LOOPS:
		if not parts.has(part):
			continue
		number += 1
		var right := TECH_LOOPS.has(part)
		var marked := d.has("mark") and str(d.mark) == part
		var colour := ORANGE if marked else (BLUE if right else GREEN)
		var rx := float(LOOP_RX[part])
		var y0 := float(LOOP_FROM[part])
		var y1 := float(LOOP_END[part])
		var mid := (y0 + y1) * 0.5
		var ry := (y0 - y1) * 0.5
		var pts := PackedVector2Array()
		for k in 25:
			var t := PI * 0.5 - PI * k / 24.0
			var x := 0.58 + rx * cos(t) if right else 0.42 - rx * cos(t)
			pts.append(L._at(a, x, mid + ry * sin(t)))
		ci.draw_polyline(pts, colour, 3.0 if marked else 2.5, true)
		L._arrow(ci, pts[pts.size() - 3], pts[pts.size() - 1], colour, 2.5)
		var tag := _loop_at(a, part)
		var tr := maxf(5.0, sfs * 0.62)
		ci.draw_circle(tag, tr, Color.WHITE)
		ci.draw_arc(tag, tr, 0.0, TAU, 18, colour, 2.0)
		if show_words:
			L._say(ci, font, tag, str(number), maxi(7, sfs - 1), colour, false)
			var said: Array = L._label_of(d, part, part)
			var line := "%d %s" % [number, str(said[0])]
			var k := TECH_LOOPS.find(part) if right else BIO_LOOPS.find(part)
			var ky := L._at(a, 0, 0.24 + k * 0.17).y
			var room := a.size.x * 0.15
			var lfs := mini(key_fs, L._fit(font, line, sfs, room))
			if right:
				L._say_from(ci, font, Vector2(a.end.x - room, ky), line, lfs, said[1])
			else:
				L._say_from(ci, font, Vector2(a.position.x + room, ky), line, lfs, said[1], true)
	for k in 3:
		var stage := STAGES[k]
		var c := L._at(a, 0.5, float(STAGE_Y[stage]))
		var marked := d.has("mark") and str(d.mark) == stage
		L._box(ci, Rect2(c - Vector2(bw, bh) * 0.5, Vector2(bw, bh)), SOFT if marked else Color.WHITE, ORANGE if marked
			else INK, 5, 2)
		var said: Array = L._label_of(d, stage, stage)
		L._say(ci, font, c, str(said[0]), L._fit(font, str(said[0]), sfs, bw - 6.0), INK, false)
		if k < 2:
			L._arrow(ci, c + Vector2(0, bh * 0.5), L._at(a, 0.5, float(STAGE_Y[STAGES[k + 1]])) - Vector2(0, bh * 0.5),
				INK, 2.0)
	var use := L._at(a, 0.5, float(STAGE_Y["use"]))
	var land := L._at(a, 0.5, float(STAGE_Y["landfill"]))
	_dashed(ci, use + Vector2(0, bh * 0.5), land - Vector2(0, bh * 0.4), GREY, 2.0, 5.0)
	var lw := bw * 1.1
	var marked_l := d.has("mark") and str(d.mark) == "landfill"
	L._box(ci, Rect2(land - Vector2(lw, bh * 0.8) * 0.5, Vector2(lw, bh * 0.8)), Color("e3e5ea"), ORANGE if marked_l
		else GREY, 5, 2)
	var said_l: Array = L._label_of(d, "landfill", "landfill")
	L._say(ci, font, land, str(said_l[0]), L._fit(font, str(said_l[0]), sfs, lw - 6.0), INK, false)
	if show_words:
		var side := str(d.get("side", "both"))
		if side != "biological":
			L._say(ci, font, L._at(a, 0.88, 0.08), "technical", sfs, BLUE, false)
		if side != "technical":
			L._say(ci, font, L._at(a, 0.12, 0.08), "biological", sfs, GREEN, false)
	if bool(d.get("labels", false)):
		L._label_parts(ci, font, r, d, _anchors(d, a), L._fs(r, 12.0))
