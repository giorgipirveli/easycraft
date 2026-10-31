class_name SchoolPictureG7Core
extends RefCounted
## Owner #70, #73 and #111, grade 7 maths, science and English: the research's last units (research §6.7): the picture
## kinds they add, drawn from data onto a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw
## calls only, no new art; the font has no arrows, so they are drawn). Diagrams that can be labelled are drawn in a box of
## a fixed shape (RATIOS), so `part_at` can say where each part is for a label exercise's pins. Kinds and fields:
## - factor_tree {n (4-999, not prime, 2-6 prime factors), hide? (a prime's index, smallest first: "?"), powers? (true:
##   "60 = 2² × 3 × 5" under the tree)}: a factor tree that splits off the smallest prime each time (prime_factors,
##   power_form).
## - prime_venn {a, b (2-999, 1-6 prime factors each), show? ("hcf", "lcm", "both": the products under the circles),
##   hide? (true: the products end "= ?"), names? ([two texts, 8 letters]: the circles' names; the numbers without)}:
##   two numbers' prime factors in a Venn diagram: the shared ones in the middle (venn_parts, hcf, lcm).
## - distance_time {points: [[time, distance]] (2-7; the first time 0, times rising, distances 0 or more), t_to, t_step,
##   d_to, d_step (2-12 steps along, 2-10 up; every point inside), t_unit? ("min", "h", "s"), d_unit? ("km", "m"),
##   legs? (true: each leg lettered A, B, C …), mark? (a leg's index, orange), title? (28 letters)}: a distance-time
##   graph: a steeper leg is faster, a flat one stopped (leg_speed).
## - speed_triangle {cover? ("distance", "speed", "time": shaded, as a finger covers it), formula? (true: the covered
##   one's formula beside the triangle)}: the formula triangle (formula_for).
## - chart_kinds {show: [CHARTS] (1-4, each once), names? (false hides the names), mark? (one of them)}: small charts side
##   by side: a bar chart, a line graph, a pie chart, a scatter graph, a pictogram.
## - odd_scale {values: [[label (10 letters), value]] (2-5), ticks: [numbers] (3-7, rising, the first 0 or more; every
##   value between the first and the last), fair? (true: the same bars beside it on an even axis), title? (24)}: a bar
##   chart whose axis numbers are evenly spaced although their steps are not (drawn_height, honest_height, uneven).
## - big_icons {what: ICONS, scale (1.2-3: the second as many times as tall and as wide), solid? (true: as deep too),
##   labels? ([two texts, 14 letters])}: the same picture drawn small and big: it looks scale² (scale³ solid) times as
##   big (looks_times).
## - periodic_grid {view: "first20" (elements 1-20 in groups 1-7 and 0) | "full" (the 18 groups, periods 1-7; the
##   lanthanides and actinides left out), numbers? (atomic numbers; first20 only), groups? (group numbers on top),
##   periods? (period numbers at the side), shade? (metals, non-metals and metalloids coloured, with a key), mark?
##   ([symbols] 1-6, orange), hide? (a symbol: "?"), col? (a group, shaded: 1-8 in first20 where 8 is group 0; 1-18 in
##   full), row? (a period, shaded), labels? (the families named in bands: FAMILIES in the view)}: the periodic table
##   (symbol_of, atomic_number, place_of, school_group, element_kind, family_of).
## - ph_scale {marks?: [[pH (0-14), label (14 letters)]] (0-6), hide? (a mark's index: its label "?"), colours? (false:
##   a plain bar; the default draws universal indicator's colours), bands? (acid, neutral, alkali named under it),
##   litmus? (litmus's red and blue under it)}: the pH scale (ph_kind, strength, indicator_colour).
## - separation {method: METHODS, labels?, mark?, hide? (SEPARATION_PARTS[method])}: the apparatus: filtering,
##   evaporating, distilling, paper chromatography, a sieve and a magnet (part_at).
## - chromatogram {samples: [[name (8 letters), [spots]]] (1-5; 0-4 spots each: a height 0.08-0.95 of the way from the
##   start line to the solvent front, or [height, DYES colour]), names? (the start line and the solvent front named),
##   mark? (a sample's index)}: paper chromatography's result; a dye without its own colour is drawn the same colour at
##   the same height in every sample (is_pure, shared, rf).
## - light_rays {view: LIGHT_VIEWS, into? ("glass", "water"), angle? (10-70 whole degrees from the normal), labels?,
##   mark?, hide? (LIGHT_PARTS[view])}: reflection from smooth and rough surfaces, refraction into and out of glass or
##   water (Snell's law: bends_towards, refracted_angle), through a block, along the normal, and a prism's spectrum
##   (part_at).
## - seen_colour {light: LIGHTS, object: OBJECTS, filter? (red, green or blue, between the object and the eye), thing?
##   (THINGS), hide? (true: the colour seen is "?")}: light from a lamp on a coloured thing, what it reflects and what
##   the eye sees (seen_as).
## - carbon_cycle {labels? (false: the stores' names left out, for labelling), processes? (false: the arrows' names left
##   out), mark?, hide? (a store or a process: "?")}: carbon's stores and the processes between them (process_from,
##   adds_carbon_dioxide) (part_at).
## - air_mix {gases?: [[name (22 letters), parts]] (2-5, 100 parts in all; dry air by default), mark?, hide? (an index:
##   its share "?")}: a hundred squares, each 1% of the air.
## - marked_text {lines: [text (52 letters)] (1-6), marks?: [[line, phrase]] (0-6; each phrase in its line), tags?:
##   [text (12 letters)] (one a mark), title? (28)}: a passage with phrases highlighted (evidence, senses, signal words).
## - venn {left_name, right_name (16 letters), left, right, both: [text (22 letters)] (0-4 each; one at least), hide?
##   ("left", "right", "both": "?"), title? (28)}: two things compared in a Venn diagram.
## - pov_view {mode: POV_MODES, names? ([three names, 8 letters]), hide? (true: the mode's name "?")}: three characters and
##   whose thoughts the narrator can see: the first person, the third person limited, the third person omniscient.

const KINDS: Array[String] = ["factor_tree", "prime_venn", "distance_time", "speed_triangle", "chart_kinds",
	"odd_scale", "big_icons", "periodic_grid", "ph_scale", "separation", "chromatogram", "light_rays", "seen_colour",
	"carbon_cycle", "air_mix", "marked_text", "venn", "pov_view"]
const INK := Color("1f2a4a")    # SchoolUi.INK
const PAPER := Color("fdf6e3")  # SchoolUi.PAPER
const ORANGE := Color("f08a1c")
const SOFT := Color("fce2b8")
const RED := Color("d9433b")
const BLUE := Color("3a7be8")
const GREEN := Color("3fa34d")
const YELLOW := Color("f0c419")
const GREY := Color("9aa1ad")
const PALE := Color("eef1f6")
const GLASS := Color(0.62, 0.82, 0.95, 0.45)
const WATER := Color(0.45, 0.68, 0.92, 0.55)
const METAL := Color("b8c0cc")
const FLAME := Color("f39c32")

## The kinds a label exercise can point at, and the shape (width ÷ height) each is drawn in, so `part_at` knows where.
const RATIOS := {"separation": 2.0, "light_rays": 2.0, "carbon_cycle": 2.0, "periodic_grid": 2.4}

const SUPERSCRIPT := {2: "²", 3: "³", 4: "⁴", 5: "⁵", 6: "⁶", 7: "⁷", 8: "⁸", 9: "⁹"}
const MAX_FACTORS := 6
const SHOWS: Array[String] = ["hcf", "lcm", "both"]
const T_UNITS: Array[String] = ["min", "h", "s"]
const D_UNITS: Array[String] = ["km", "m"]
const LEG_LETTERS := "ABCDEF"
const QUANTITIES: Array[String] = ["distance", "speed", "time"]
const CHARTS: Array[String] = ["bar", "line", "pie", "scatter", "pictogram"]
const CHART_NAMES := {"bar": "bar chart", "line": "line graph", "pie": "pie chart", "scatter": "scatter graph",
	"pictogram": "pictogram"}
const ICONS: Array[String] = ["bag", "coin", "tree", "house", "box"]

## The elements in order of atomic number (1-118).
const SYMBOLS: Array[String] = ["H", "He", "Li", "Be", "B", "C", "N", "O", "F", "Ne", "Na", "Mg", "Al", "Si", "P", "S",
	"Cl", "Ar", "K", "Ca", "Sc", "Ti", "V", "Cr", "Mn", "Fe", "Co", "Ni", "Cu", "Zn", "Ga", "Ge", "As", "Se", "Br", "Kr",
	"Rb", "Sr", "Y", "Zr", "Nb", "Mo", "Tc", "Ru", "Rh", "Pd", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I", "Xe", "Cs", "Ba",
	"La", "Ce", "Pr", "Nd", "Pm", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", "Lu", "Hf", "Ta", "W", "Re", "Os",
	"Ir", "Pt", "Au", "Hg", "Tl", "Pb", "Bi", "Po", "At", "Rn", "Fr", "Ra", "Ac", "Th", "Pa", "U", "Np", "Pu", "Am", "Cm",
	"Bk", "Cf", "Es", "Fm", "Md", "No", "Lr", "Rf", "Db", "Sg", "Bh", "Hs", "Mt", "Ds", "Rg", "Cn", "Nh", "Fl", "Mc", "Lv",
	"Ts", "Og"]
## The non-metals and the metalloids (the elements along the staircase) by atomic number; 109-118 are made only a few
## atoms at a time, so their properties are not known ("unknown"); every other element is a metal.
const NON_METALS: Array[int] = [1, 2, 6, 7, 8, 9, 10, 15, 16, 17, 18, 34, 35, 36, 53, 54, 86]
const METALLOIDS: Array[int] = [5, 14, 32, 33, 51, 52, 85]
const UNKNOWN_FROM := 109
const ELEMENT_KINDS: Array[String] = ["metal", "non-metal", "metalloid", "unknown"]
const KIND_COLOURS := {"metal": Color("cfe0f7"), "non-metal": Color("fbeab0"), "metalloid": Color("cdebc4"),
	"unknown": Color("e2e4e8")}
const VIEWS: Array[String] = ["first20", "full"]
## The families a periodic_grid can name (labels), with the group (1-18) each stands in.
const FAMILIES := {"alkali metals": 1, "transition metals": 8, "halogens": 17, "noble gases": 18}

## Universal indicator's colours, pH 0 to 14, and each pH's colour name (a common school chart; charts differ a little).
const PH_COLOURS: Array[Color] = [Color("d32f2f"), Color("e23d2f"), Color("ea552e"), Color("ef6c2c"), Color("f39a2b"),
	Color("f6b52e"), Color("e9d64a"), Color("6abf4b"), Color("3fae7a"), Color("2f9ec4"), Color("3a7be8"), Color("4d5fd0"),
	Color("5f4bbf"), Color("6b3daa"), Color("5a2d8c")]
const MAX_PH_MARKS := 6

const METHODS: Array[String] = ["filter", "evaporate", "distil", "chromatography", "sieve", "magnet"]
const SEPARATION_PARTS := {
	"filter": ["funnel", "filter paper", "residue", "filtrate", "beaker"],
	"evaporate": ["evaporating basin", "solution", "water vapour", "heat"],
	"distil": ["flask", "thermometer", "condenser", "cold water", "distillate", "heat"],
	"chromatography": ["paper", "start line", "spots", "solvent", "solvent front"],
	"sieve": ["sieve", "big pieces", "small pieces"],
	"magnet": ["magnet", "iron filings", "sand"],
}
const SEP_AT := {
	"filter": {"funnel": Vector2(0.38, 0.28), "filter paper": Vector2(0.58, 0.22), "residue": Vector2(0.5, 0.36),
		"filtrate": Vector2(0.5, 0.9), "beaker": Vector2(0.675, 0.72)},
	"evaporate": {"evaporating basin": Vector2(0.68, 0.5), "solution": Vector2(0.5, 0.48),
		"water vapour": Vector2(0.5, 0.12), "heat": Vector2(0.5, 0.83)},
	"distil": {"flask": Vector2(0.15, 0.55), "thermometer": Vector2(0.15, 0.1), "condenser": Vector2(0.48, 0.4),
		"cold water": Vector2(0.7, 0.72), "distillate": Vector2(0.86, 0.86), "heat": Vector2(0.15, 0.93)},
	"chromatography": {"paper": Vector2(0.44, 0.4), "start line": Vector2(0.5, 0.72), "spots": Vector2(0.5, 0.5),
		"solvent": Vector2(0.5, 0.86), "solvent front": Vector2(0.5, 0.22)},
	"sieve": {"sieve": Vector2(0.3, 0.42), "big pieces": Vector2(0.5, 0.34), "small pieces": Vector2(0.5, 0.82)},
	"magnet": {"magnet": Vector2(0.5, 0.18), "iron filings": Vector2(0.5, 0.42), "sand": Vector2(0.62, 0.82)},
}

const MAX_SAMPLES := 5
const MAX_SPOTS := 4
const MAX_SAMPLE_NAME := 8
const DYES := {"red": Color("d9433b"), "orange": Color("f08a1c"), "yellow": Color("e8c22a"), "green": Color("3fa34d"),
	"blue": Color("3a7be8"), "purple": Color("6b3daa"), "pink": Color("e05aa0"), "brown": Color("8a5a2b"),
	"black": Color("333333")}
const DYE_COLOURS: Array[Color] = [Color("d9433b"), Color("f08a1c"), Color("e0b23a"), Color("3fa34d"), Color("2f9ec4"),
	Color("3a7be8"), Color("6b3daa"), Color("c2448f"), Color("8a5a2b"), Color("4a4a4a")]

const LIGHT_VIEWS: Array[String] = ["specular", "diffuse", "refraction", "leaving", "block", "along_normal", "prism"]
const LIGHT_PARTS := {
	"specular": ["mirror", "incoming rays", "reflected rays"],
	"diffuse": ["rough surface", "incoming rays", "scattered rays"],
	"refraction": ["incident ray", "normal", "refracted ray", "air", "glass"],
	"leaving": ["incident ray", "normal", "refracted ray", "air", "glass"],
	"block": ["incident ray", "glass block", "emergent ray"],
	"along_normal": ["incident ray", "normal", "glass"],
	"prism": ["white light", "prism", "spectrum", "red", "violet"],
}
const N_GLASS := 1.5
const N_WATER := 1.33
const SPECTRUM: Array[String] = ["red", "orange", "yellow", "green", "blue", "indigo", "violet"]
const SPECTRUM_COLOURS: Array[Color] = [Color("e0302e"), Color("f38b1c"), Color("f2d21b"), Color("3fae3f"),
	Color("2f7fe0"), Color("3f3fa8"), Color("8a3fc0")]

const LIGHTS: Array[String] = ["white", "red", "green", "blue"]
const OBJECTS: Array[String] = ["white", "black", "red", "green", "blue", "yellow"]
const FILTERS: Array[String] = ["red", "green", "blue"]
const THINGS: Array[String] = ["ball", "shirt", "apple", "leaf", "book", "flower"]
## What each light holds, what each thing reflects and what each filter lets through: red, green and blue light.
const PRIMARIES := {"white": ["red", "green", "blue"], "black": [], "red": ["red"], "green": ["green"],
	"blue": ["blue"], "yellow": ["red", "green"]}
const SEEN_COLOURS := {"white": Color("ffffff"), "black": Color("222222"), "red": Color("e0302e"),
	"green": Color("3fae3f"), "blue": Color("2f6fe0"), "yellow": Color("f2d21b")}

const STORES: Array[String] = ["air", "plants", "animals", "decomposers", "fossil fuels"]
const STORE_NAMES := {"air": "carbon dioxide in the air", "plants": "plants", "animals": "animals",
	"decomposers": "decomposers", "fossil fuels": "fossil fuels"}
## Each store's box in the diagram [centre x, centre y, width, height], fractions of its 2 : 1 box.
const STORE_BOX := {"air": [0.5, 0.1, 0.42, 0.15], "plants": [0.2, 0.52, 0.17, 0.13], "animals": [0.74, 0.52, 0.17, 0.13],
	"decomposers": [0.74, 0.86, 0.22, 0.13], "fossil fuels": [0.25, 0.86, 0.22, 0.13]}
## The processes as [name, from, to, the arrow's points, where its name goes].
const FLOWS: Array = [
	["photosynthesis", "plants", [Vector2(0.33, 0.18), Vector2(0.18, 0.45)], Vector2(0.17, 0.3), "air"],
	["respiration", "air", [Vector2(0.25, 0.45), Vector2(0.4, 0.18)], Vector2(0.4, 0.31), "plants"],
	["respiration", "air", [Vector2(0.72, 0.45), Vector2(0.6, 0.18)], Vector2(0.77, 0.31), "animals"],
	["feeding", "animals", [Vector2(0.29, 0.52), Vector2(0.65, 0.52)], Vector2(0.47, 0.47), "plants"],
	["death and waste", "decomposers", [Vector2(0.74, 0.59), Vector2(0.74, 0.79)], Vector2(0.88, 0.69), "animals"],
	["death and waste", "decomposers", [Vector2(0.24, 0.59), Vector2(0.62, 0.8)], Vector2(0.45, 0.62), "plants"],
	["decay", "air", [Vector2(0.86, 0.8), Vector2(0.97, 0.8), Vector2(0.97, 0.1), Vector2(0.72, 0.1)], Vector2(0.93, 0.31),
		"decomposers"],
	["fossilisation", "fossil fuels", [Vector2(0.62, 0.9), Vector2(0.37, 0.9)], Vector2(0.495, 0.96), "decomposers"],
	["combustion", "air", [Vector2(0.14, 0.82), Vector2(0.03, 0.82), Vector2(0.03, 0.1), Vector2(0.28, 0.1)],
		Vector2(0.09, 0.69), "fossil fuels"],
]
const PROCESSES: Array[String] = ["photosynthesis", "respiration", "feeding", "death and waste", "decay",
	"fossilisation", "combustion"]
const STORE_COLOURS: Array[Color] = [Color("dbe9fb"), Color("d8f0d0"), Color("fbe6c8"), Color("e9dccb"), Color("d9d4cc")]

## Dry air (by volume, rounded): nitrogen 78%, oxygen 21%, argon and the other gases 1% (carbon dioxide about 0.04%).
const DRY_AIR: Array = [["nitrogen", 78], ["oxygen", 21], ["argon and other gases", 1]]
const GAS_COLOURS: Array[Color] = [Color("8fb8e8"), Color("f08a1c"), Color("3fa34d"), Color("c2448f"), Color("e0b23a")]

const MAX_LINES := 6
const MAX_LINE := 52
const MAX_MARKS := 6
const MAX_TAG := 12
const MAX_TITLE := 28
const MAX_SIDE_NAME := 16
const MAX_VENN_ITEM := 22
const MAX_VENN_ITEMS := 4
const POV_MODES: Array[String] = ["first", "third_limited", "omniscient"]
const POV_NAMES := {"first": "first person", "third_limited": "third person limited",
	"omniscient": "third person omniscient"}


# --- The rules the pictures draw by (the lessons teach them; tests check them) --------------------------------------

## The prime factors of n (2 or more), smallest first: 60 gives [2, 2, 3, 5].
static func prime_factors(n: int) -> Array[int]:
	var out: Array[int] = []
	var d := 2
	while n > 1 and d * d <= n:
		while n % d == 0:
			out.append(d)
			n /= d
		d += 1
	if n > 1:
		out.append(n)
	return out


static func is_prime(n: int) -> bool:
	return n >= 2 and prime_factors(n).size() == 1


## n as a product of primes with powers: 60 gives "2² × 3 × 5".
static func power_form(n: int) -> String:
	var parts: Array[String] = []
	var ps := prime_factors(n)
	var i := 0
	while i < ps.size():
		var e := 1
		while i + e < ps.size() and ps[i + e] == ps[i]:
			e += 1
		parts.append(str(ps[i]) + (str(SUPERSCRIPT.get(e, "^%d" % e)) if e > 1 else ""))
		i += e
	return " × ".join(PackedStringArray(parts))


## The prime factors of a only, of both, and of b only (a Venn diagram's three parts).
static func venn_parts(a: int, b: int) -> Array:
	var left := prime_factors(a)
	var right := prime_factors(b)
	var both: Array[int] = []
	for p in left.duplicate():
		if right.has(p):
			both.append(p)
			left.erase(p)
			right.erase(p)
	return [left, both, right]


## The highest common factor: the shared primes multiplied (1 when they share none).
static func hcf(a: int, b: int) -> int:
	var out := 1
	for p: int in venn_parts(a, b)[1]:
		out *= p
	return out


## The lowest common multiple: every prime in the diagram multiplied.
static func lcm(a: int, b: int) -> int:
	return a * b / hcf(a, b)


## A leg's speed: the distance it covers ÷ the time it takes (in the graph's units: km a minute, m a second …).
static func leg_speed(points: Array, leg: int) -> float:
	var a: Array = points[leg]
	var b: Array = points[leg + 1]
	return (float(b[1]) - float(a[1])) / (float(b[0]) - float(a[0]))


## The formula for a quantity, as the triangle gives it when you cover it.
static func formula_for(quantity: String) -> String:
	match quantity:
		"distance":
			return "distance = speed × time"
		"speed":
			return "speed = distance ÷ time"
	return "time = distance ÷ speed"


## How high a value's bar is drawn on an axis whose numbers `ticks` are evenly spaced (a fraction of the axis): between
## two numbers it goes as far as the value goes between them.
static func drawn_height(ticks: Array, value: float) -> float:
	var n := ticks.size() - 1
	for i in n:
		var lo := float(ticks[i])
		var hi := float(ticks[i + 1])
		if value <= hi or i == n - 1:
			return (float(i) + clampf((value - lo) / (hi - lo), 0.0, 1.0)) / n
	return 1.0


## How high it would be on a fair axis from the first number to the last.
static func honest_height(ticks: Array, value: float) -> float:
	return (value - float(ticks[0])) / (float(ticks[-1]) - float(ticks[0]))


## Whether an axis's steps differ.
static func uneven(ticks: Array) -> bool:
	for i in range(1, ticks.size() - 1):
		if not is_equal_approx(float(ticks[i + 1]) - float(ticks[i]), float(ticks[1]) - float(ticks[0])):
			return true
	return false


## How many times as big a picture looks when it is drawn `scale` times as tall and as wide (and as deep, solid).
static func looks_times(scale: float, solid: bool = false) -> float:
	return pow(scale, 3.0 if solid else 2.0)


static func symbol_of(z: int) -> String:
	return SYMBOLS[z - 1] if z >= 1 and z <= SYMBOLS.size() else ""


## An element's atomic number by its symbol (0 for none).
static func atomic_number(symbol: String) -> int:
	return SYMBOLS.find(symbol) + 1


## Where an element sits in the 18-group table: Vector2i(group 1-18, period 1-7); the lanthanides (57-71) and actinides
## (89-103) are in group 3's gap (group 0 here: they are left out of the main table).
static func place_of(symbol: String) -> Vector2i:
	var z := atomic_number(symbol)
	if z <= 0:
		return Vector2i(-1, -1)
	if z == 1:
		return Vector2i(1, 1)
	if z == 2:
		return Vector2i(18, 1)
	var starts: Array[int] = [3, 11, 19, 37, 55, 87, 119]
	for k in 6:
		if z < starts[k + 1]:
			var period := k + 2
			var i := z - starts[k]
			if period <= 3:
				return Vector2i(i + 1 if i < 2 else i + 11, period)
			if period <= 5:
				return Vector2i(i + 1, period)
			if i < 2:
				return Vector2i(i + 1, period)
			if i < 17:
				return Vector2i(0, period)
			return Vector2i(i - 13, period)
	return Vector2i(-1, -1)


## The group number schools use for the main groups (1-7, and 0 for the noble gases); -1 for the transition metals in
## the middle and for the lanthanides and actinides.
static func school_group(symbol: String) -> int:
	var g := place_of(symbol).x
	if g == 1 or g == 2:
		return g
	if g >= 13 and g <= 17:
		return g - 10
	if g == 18:
		return 0
	return -1


static func element_kind(symbol: String) -> String:
	var z := atomic_number(symbol)
	if z >= UNKNOWN_FROM:
		return "unknown"
	if NON_METALS.has(z):
		return "non-metal"
	if METALLOIDS.has(z):
		return "metalloid"
	return "metal"


## The family an element belongs to, by its place ("" for others; hydrogen sits over group 1 but is not an alkali metal).
static func family_of(symbol: String) -> String:
	var p := place_of(symbol)
	if symbol == "H":
		return ""
	if p.x == 1:
		return "alkali metals"
	if p.x >= 3 and p.x <= 12:
		return "transition metals"
	if p.x == 17:
		return "halogens"
	if p.x == 18:
		return "noble gases"
	return ""


static func ph_kind(ph: float) -> String:
	if is_equal_approx(ph, 7.0):
		return "neutral"
	return "acid" if ph < 7.0 else "alkali"


## How acidic or alkaline a pH is, as the scale's colours group it: 0-3 strongly acidic, 4-6 weakly acidic, 7 neutral,
## 8-10 weakly alkaline, 11-14 strongly alkaline. (A "strong acid" in chemistry is about how an acid splits up in water,
## a later topic, so the School says "strongly acidic" for a low pH.)
static func strength(ph: float) -> String:
	if ph < 3.5:
		return "strongly acidic"
	if ph < 6.5:
		return "weakly acidic"
	if ph <= 7.5:
		return "neutral"
	if ph < 10.5:
		return "weakly alkaline"
	return "strongly alkaline"


## Universal indicator's colour at a pH (whole numbers): red 0-3, orange 4-5, yellow 6, green 7, blue 8-10, purple
## 11-14.
static func indicator_colour(ph: float) -> String:
	var p := roundi(ph)
	if p <= 3:
		return "red"
	if p <= 5:
		return "orange"
	if p == 6:
		return "yellow"
	if p == 7:
		return "green"
	if p <= 10:
		return "blue"
	return "purple"


static func is_pure(sample: Array) -> bool:
	return (sample[1] as Array).size() == 1


## A spot's height (a spot is a height, or [height, colour]).
static func spot_height(spot: Variant) -> float:
	return float(spot[0]) if spot is Array else float(spot)


## The dyes two samples share (the heights they both have).
static func shared(a: Array, b: Array) -> Array:
	var out: Array = []
	for h: Variant in a[1]:
		for k: Variant in b[1]:
			if absf(spot_height(h) - spot_height(k)) < 0.015:
				out.append(spot_height(h))
				break
	return out


## The Rf value: how far a dye travelled ÷ how far the solvent travelled.
static func rf(dye_distance: float, solvent_distance: float) -> float:
	return dye_distance / solvent_distance


## Snell's law: the angle (degrees from the normal) a ray makes after it crosses from a material with index n1 into one
## with n2 (air 1, water 1.33, glass 1.5); -1 when it cannot leave (total internal reflection).
static func refracted_angle(angle: float, n1: float, n2: float) -> float:
	var s := n1 * sin(deg_to_rad(angle)) / n2
	if s > 1.0:
		return -1.0
	return rad_to_deg(asin(s))


## Light that slows down (into a denser material) bends towards the normal; light that speeds up bends away.
static func bends_towards(n1: float, n2: float) -> bool:
	return n2 > n1


## The colour a thing looks: the light that falls on it, that it reflects and that the filter lets through.
static func seen_as(light: String, object: String, filter: String = "") -> String:
	var left: Array = []
	for c: String in PRIMARIES.get(light, []):
		if (PRIMARIES.get(object, []) as Array).has(c) and (filter == "" or c == filter):
			left.append(c)
	match left.size():
		0:
			return "black"
		1:
			return str(left[0])
		3:
			return "white"
	if left.has("red") and left.has("green"):
		return "yellow"
	if left.has("green") and left.has("blue"):
		return "cyan"
	return "magenta"


## The processes that carry carbon out of a store (each [name, into]).
static func process_from(store: String) -> Array:
	var out: Array = []
	for f: Array in FLOWS:
		if str(f[4]) == store:
			out.append([str(f[0]), str(f[1])])
	return out


## Whether a process puts carbon dioxide into the air.
static func adds_carbon_dioxide(process: String) -> bool:
	for f: Array in FLOWS:
		if str(f[0]) == process:
			return str(f[1]) == "air"
	return false


## Where the part named `label` is drawn on a picture of `size` (a SchoolPicture's whole size), for a label's line;
## (-1, -1) when the picture has no such part.
static func part_at(p: Dictionary, label: String, size: Vector2) -> Vector2:
	var none := Vector2(-1, -1)
	var kind := str(p.get("kind", ""))
	if not RATIOS.has(kind) or problem(p) != "":
		return none
	var a := _diagram_box(p, _rect(size))
	return _anchors(p, a).get(label, none)


## Each named part's place in the diagram box `a`.
static func _anchors(p: Dictionary, a: Rect2) -> Dictionary:
	var out := {}
	match str(p.kind):
		"separation":
			var at: Dictionary = SEP_AT[str(p.method)]
			for part: String in at:
				out[part] = _at(a, at[part].x, at[part].y)
		"light_rays":
			out = _light_geo(p, a).parts
		"carbon_cycle":
			for s: String in STORES:
				var b: Array = STORE_BOX[s]
				out[s] = _at(a, float(b[0]), float(b[1]))
		"periodic_grid":
			var g := _grid_geo(p, a)
			for fam: String in FAMILIES:
				if g.families.has(fam):
					out[fam] = g.families[fam]
	return out


## A diagram's box in `r`: its label bands taken off, then its shape (RATIOS) centred.
static func _diagram_box(p: Dictionary, r: Rect2) -> Rect2:
	var fs := _fs(r)
	return _fit_box(_inner(r, fs, bool(p.get("labels", false)) and str(p.kind) != "carbon_cycle"),
		float(RATIOS.get(str(p.get("kind", "")), 2.0)))


# --- Checks -------------------------------------------------------------------------------------------------------------

## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	var kind := str(p.get("kind", ""))
	var why := ""
	match kind:
		"factor_tree":
			why = _tree_problem(p)
		"prime_venn":
			why = _venn_numbers_problem(p)
		"distance_time":
			why = _dt_problem(p)
		"speed_triangle":
			if p.has("cover") and not QUANTITIES.has(str(p.cover)):
				why = "cover is one of %s" % [QUANTITIES]
			else:
				why = _flags(p, ["formula"])
		"chart_kinds":
			why = _list_problem(p, "show", CHARTS, 4)
			if why == "" and p.has("mark") and not (p.show as Array).has(p.mark):
				why = "mark is one of its charts"
			if why == "":
				why = _flags(p, ["names"])
		"odd_scale":
			why = _odd_problem(p)
		"big_icons":
			if not ICONS.has(str(p.get("what", ""))):
				why = "what is one of %s" % [ICONS]
			elif not _number(p.get("scale")) or float(p.scale) < 1.2 or float(p.scale) > 3.0:
				why = "scale is 1.2-3"
			elif p.has("labels") and not _texts_ok(p.labels, 2, 2, 14):
				why = "labels are two texts of 14 letters"
			else:
				why = _flags(p, ["solid"])
		"periodic_grid":
			why = _grid_problem(p)
		"ph_scale":
			why = _ph_problem(p)
		"separation":
			var method := str(p.get("method", ""))
			if not METHODS.has(method):
				why = "method is one of %s" % [METHODS]
			else:
				why = _parts_problem(p, SEPARATION_PARTS[method])
		"chromatogram":
			why = _chroma_problem(p)
		"light_rays":
			why = _light_problem(p)
		"seen_colour":
			if not LIGHTS.has(str(p.get("light", ""))):
				why = "light is one of %s" % [LIGHTS]
			elif not OBJECTS.has(str(p.get("object", ""))):
				why = "object is one of %s" % [OBJECTS]
			elif p.has("filter") and not FILTERS.has(str(p.filter)):
				why = "filter is one of %s" % [FILTERS]
			elif p.has("thing") and not THINGS.has(str(p.thing)):
				why = "thing is one of %s" % [THINGS]
			else:
				why = _flags(p, ["hide"])
		"carbon_cycle":
			for key: String in ["mark", "hide"]:
				if p.has(key) and not (STORES.has(str(p[key])) or PROCESSES.has(str(p[key]))):
					why = "%s is a store or a process" % key
			if why == "":
				why = _flags(p, ["labels", "processes"])
		"air_mix":
			why = _air_problem(p)
		"marked_text":
			why = _marked_problem(p)
		"venn":
			why = _venn_problem(p)
		"pov_view":
			if not POV_MODES.has(str(p.get("mode", ""))):
				why = "mode is one of %s" % [POV_MODES]
			elif p.has("names") and not _texts_ok(p.names, 3, 3, 8):
				why = "names are three texts of 8 letters"
			else:
				why = _flags(p, ["hide"])
		_:
			return "unknown picture kind '%s'" % kind
	return "" if why == "" else "%s: %s" % [kind, why]


static func _tree_problem(p: Dictionary) -> String:
	if not _whole(p.get("n")) or int(p.n) < 4 or int(p.n) > 999:
		return "n is a whole number 4-999"
	var k := prime_factors(int(p.n)).size()
	if k < 2 or k > MAX_FACTORS:
		return "n has 2-%d prime factors (not a prime)" % MAX_FACTORS
	if p.has("hide") and (not _whole(p.hide) or int(p.hide) < 0 or int(p.hide) >= k):
		return "hide is a prime's index"
	return _flags(p, ["powers"])


static func _venn_numbers_problem(p: Dictionary) -> String:
	for key: String in ["a", "b"]:
		if not _whole(p.get(key)) or int(p[key]) < 2 or int(p[key]) > 999:
			return "%s is a whole number 2-999" % key
		if prime_factors(int(p[key])).size() > MAX_FACTORS:
			return "%s has at most %d prime factors" % [key, MAX_FACTORS]
	if p.has("show") and not SHOWS.has(str(p.show)):
		return "show is one of %s" % [SHOWS]
	if p.has("names") and not _texts_ok(p.names, 2, 2, 8):
		return "names are two texts of 8 letters"
	return _flags(p, ["hide"])


static func _dt_problem(p: Dictionary) -> String:
	var pts: Variant = p.get("points")
	if not pts is Array or (pts as Array).size() < 2 or (pts as Array).size() > 7:
		return "points are 2-7 [time, distance]"
	var last_t := -1.0
	var top_d := 0.0
	for pt: Variant in pts:
		if not pt is Array or (pt as Array).size() != 2 or not _number(pt[0]) or not _number(pt[1]):
			return "a point is [time, distance]"
		if float(pt[0]) <= last_t or float(pt[1]) < 0.0:
			return "times rise from 0 and distances are 0 or more"
		last_t = float(pt[0])
		top_d = maxf(top_d, float(pt[1]))
	if not is_zero_approx(float(pts[0][0])):
		return "the first time is 0"
	var why := _scale_problem(p, "t_to", "t_step", last_t, 12)
	if why == "":
		why = _scale_problem(p, "d_to", "d_step", top_d, 10)
	if why != "":
		return why
	if p.has("t_unit") and not T_UNITS.has(str(p.t_unit)):
		return "t_unit is one of %s" % [T_UNITS]
	if p.has("d_unit") and not D_UNITS.has(str(p.d_unit)):
		return "d_unit is one of %s" % [D_UNITS]
	if p.has("mark") and (not _whole(p.mark) or int(p.mark) < 0 or int(p.mark) >= (pts as Array).size() - 1):
		return "mark is a leg's index"
	if p.has("title") and str(p.title).length() > MAX_TITLE:
		return "title has at most %d letters" % MAX_TITLE
	return _flags(p, ["legs"])


static func _scale_problem(p: Dictionary, to: String, step: String, most: float, steps: int) -> String:
	if not _number(p.get(to)) or not _number(p.get(step)) or float(p[step]) <= 0.0:
		return "%s and %s are numbers" % [to, step]
	var n := float(p[to]) / float(p[step])
	if not is_equal_approx(n, roundf(n)) or roundi(n) < 2 or roundi(n) > steps:
		return "%s is 2-%d whole steps of %s" % [to, steps, step]
	if most > float(p[to]) + 0.0001:
		return "every point is inside %s" % to
	return ""


static func _odd_problem(p: Dictionary) -> String:
	var ticks: Variant = p.get("ticks")
	if not ticks is Array or (ticks as Array).size() < 3 or (ticks as Array).size() > 7:
		return "ticks are 3-7 numbers"
	var last := -1.0
	for t: Variant in ticks:
		if not _number(t) or float(t) <= last:
			return "ticks rise from 0 or more"
		last = float(t)
	var values: Variant = p.get("values")
	if not values is Array or (values as Array).size() < 2 or (values as Array).size() > 5:
		return "values are 2-5 [label, value]"
	for v: Variant in values:
		if not v is Array or (v as Array).size() != 2 or str(v[0]).length() > 10 or str(v[0]) == "" or not _number(v[1]):
			return "a value is [label of 10 letters, number]"
		if float(v[1]) < float(ticks[0]) or float(v[1]) > float(ticks[-1]):
			return "every value is between the first tick and the last"
	if p.has("title") and str(p.title).length() > 24:
		return "title has at most 24 letters"
	return _flags(p, ["fair"])


static func _grid_problem(p: Dictionary) -> String:
	var view := str(p.get("view", ""))
	if not VIEWS.has(view):
		return "view is one of %s" % [VIEWS]
	var why := _flags(p, ["numbers", "groups", "periods", "shade", "labels"])
	if why != "":
		return why
	if p.has("mark"):
		if not p.mark is Array or (p.mark as Array).is_empty() or (p.mark as Array).size() > 6:
			return "mark is 1-6 symbols"
		for s: Variant in p.mark:
			if not _in_view(view, str(s)):
				return "%s is not in the %s view" % [s, view]
	if p.has("hide") and not _in_view(view, str(p.hide)):
		return "hide is a symbol in the view"
	var cols := 8 if view == "first20" else 18
	if p.has("col") and (not _whole(p.col) or int(p.col) < 1 or int(p.col) > cols):
		return "col is a group 1-%d" % cols
	var rows := 4 if view == "first20" else 7
	if p.has("row") and (not _whole(p.row) or int(p.row) < 1 or int(p.row) > rows):
		return "row is a period 1-%d" % rows
	return ""


static func _in_view(view: String, symbol: String) -> bool:
	var z := atomic_number(symbol)
	if z <= 0:
		return false
	if view == "first20":
		return z <= 20
	return place_of(symbol).x >= 1


static func _ph_problem(p: Dictionary) -> String:
	if p.has("marks"):
		if not p.marks is Array or (p.marks as Array).size() > MAX_PH_MARKS:
			return "marks are 0-%d [pH, label]" % MAX_PH_MARKS
		for m: Variant in p.marks:
			if not m is Array or (m as Array).size() != 2 or not _number(m[0]) or float(m[0]) < 0.0 or float(m[0]) > 14.0:
				return "a mark is [pH 0-14, label]"
			if str(m[1]).length() > 14:
				return "a mark's label has at most 14 letters"
	if p.has("hide") and (not _whole(p.hide) or int(p.hide) < 0 or int(p.hide) >= (p.get("marks", []) as Array).size()):
		return "hide is a mark's index"
	return _flags(p, ["colours", "bands", "litmus"])


static func _chroma_problem(p: Dictionary) -> String:
	var samples: Variant = p.get("samples")
	if not samples is Array or (samples as Array).is_empty() or (samples as Array).size() > MAX_SAMPLES:
		return "samples are 1-%d [name, heights]" % MAX_SAMPLES
	for s: Variant in samples:
		if not s is Array or (s as Array).size() != 2 or not s[1] is Array:
			return "a sample is [name, [heights]]"
		if str(s[0]) == "" or str(s[0]).length() > MAX_SAMPLE_NAME:
			return "a sample's name has 1-%d letters" % MAX_SAMPLE_NAME
		if (s[1] as Array).size() > MAX_SPOTS:
			return "a sample has 0-%d spots" % MAX_SPOTS
		for h: Variant in s[1]:
			if h is Array and ((h as Array).size() != 2 or not DYES.has(str(h[1]))):
				return "a spot is a height or [height, one of %s]" % [DYES.keys()]
			if not _number(h[0] if h is Array else h) or spot_height(h) < 0.08 or spot_height(h) > 0.95:
				return "a spot's height is 0.08-0.95"
	if p.has("mark") and (not _whole(p.mark) or int(p.mark) < 0 or int(p.mark) >= (samples as Array).size()):
		return "mark is a sample's index"
	return _flags(p, ["names"])


static func _light_problem(p: Dictionary) -> String:
	var view := str(p.get("view", ""))
	if not LIGHT_VIEWS.has(view):
		return "view is one of %s" % [LIGHT_VIEWS]
	if p.has("into") and not ["glass", "water"].has(str(p.into)):
		return "into is glass or water"
	if p.has("angle") and (not _whole(p.angle) or int(p.angle) < 10 or int(p.angle) > 70):
		return "angle is 10-70 whole degrees"
	if view == "leaving" and refracted_angle(_angle(p), _index(p), 1.0) < 0.0:
		return "the ray cannot leave at that angle"
	var parts: Array = (LIGHT_PARTS[view] as Array).duplicate()
	if p.get("into", "glass") == "water":
		parts = parts.map(func(x: Variant) -> String: return "water" if str(x) == "glass" else str(x))
	return _parts_problem(p, parts)


static func _index(p: Dictionary) -> float:
	return N_WATER if str(p.get("into", "glass")) == "water" else N_GLASS


## The ray's angle from the normal: its own, or 30° leaving the glass and 40° otherwise.
static func _angle(p: Dictionary) -> float:
	return float(p.get("angle", 30 if str(p.get("view", "")) == "leaving" else 40))


static func _air_problem(p: Dictionary) -> String:
	var gases: Variant = p.get("gases", DRY_AIR)
	if not gases is Array or (gases as Array).size() < 2 or (gases as Array).size() > 5:
		return "gases are 2-5 [name, parts]"
	var total := 0
	for g: Variant in gases:
		if not g is Array or (g as Array).size() != 2 or not _whole(g[1]) or int(g[1]) < 1:
			return "a gas is [name, whole parts]"
		if str(g[0]) == "" or str(g[0]).length() > 22:
			return "a gas's name has 1-22 letters"
		total += int(g[1])
	if total != 100:
		return "the parts make 100"
	for key: String in ["mark", "hide"]:
		if p.has(key) and (not _whole(p[key]) or int(p[key]) < 0 or int(p[key]) >= (gases as Array).size()):
			return "%s is a gas's index" % key
	return ""


static func _marked_problem(p: Dictionary) -> String:
	var lines: Variant = p.get("lines")
	if not lines is Array or (lines as Array).is_empty() or (lines as Array).size() > MAX_LINES:
		return "lines are 1-%d texts" % MAX_LINES
	for t: Variant in lines:
		if str(t) == "" or str(t).length() > MAX_LINE:
			return "a line has 1-%d letters" % MAX_LINE
	var marks: Variant = p.get("marks", [])
	if not marks is Array or (marks as Array).size() > MAX_MARKS:
		return "marks are 0-%d [line, phrase]" % MAX_MARKS
	for m: Variant in marks:
		if not m is Array or (m as Array).size() != 2 or not _whole(m[0]) or int(m[0]) < 0 \
				or int(m[0]) >= (lines as Array).size():
			return "a mark is [line, phrase]"
		if str(m[1]) == "" or not str(lines[int(m[0])]).contains(str(m[1])):
			return "a mark's phrase is in its line: %s" % m[1]
	if p.has("tags"):
		if not p.tags is Array or (p.tags as Array).size() != (marks as Array).size():
			return "tags are one a mark"
		for t: Variant in p.tags:
			if str(t).length() > MAX_TAG:
				return "a tag has at most %d letters" % MAX_TAG
	if p.has("title") and str(p.title).length() > MAX_TITLE:
		return "title has at most %d letters" % MAX_TITLE
	return ""


static func _venn_problem(p: Dictionary) -> String:
	for key: String in ["left_name", "right_name"]:
		if str(p.get(key, "")) == "" or str(p[key]).length() > MAX_SIDE_NAME:
			return "%s has 1-%d letters" % [key, MAX_SIDE_NAME]
	var n := 0
	for key: String in ["left", "right", "both"]:
		var items: Variant = p.get(key, [])
		if not items is Array or (items as Array).size() > MAX_VENN_ITEMS:
			return "%s is 0-%d texts" % [key, MAX_VENN_ITEMS]
		for t: Variant in items:
			if str(t) == "" or str(t).length() > MAX_VENN_ITEM:
				return "an item has 1-%d letters" % MAX_VENN_ITEM
		n += (items as Array).size()
	if n == 0:
		return "one item at least"
	if p.has("hide") and not ["left", "right", "both"].has(str(p.hide)):
		return "hide is left, right or both"
	if p.has("title") and str(p.title).length() > MAX_TITLE:
		return "title has at most %d letters" % MAX_TITLE
	return ""


static func _list_problem(p: Dictionary, key: String, known: Array, most: int) -> String:
	var list: Variant = p.get(key)
	if not list is Array or (list as Array).is_empty() or (list as Array).size() > most:
		return "%s is 1-%d of %s" % [key, most, known]
	var seen := {}
	for v: Variant in list:
		if not known.has(str(v)) or seen.has(str(v)):
			return "%s is 1-%d of %s, each once" % [key, most, known]
		seen[str(v)] = true
	return ""


static func _parts_problem(p: Dictionary, parts: Array) -> String:
	for key: String in ["mark", "hide"]:
		if p.has(key) and not parts.has(str(p[key])):
			return "%s is one of %s" % [key, parts]
	return _flags(p, ["labels"])


static func _flags(p: Dictionary, keys: Array) -> String:
	for key: String in keys:
		if p.has(key) and not p[key] is bool:
			return "%s is true or false" % key
	return ""


static func _texts_ok(v: Variant, least: int, most: int, letters: int) -> bool:
	if not v is Array or (v as Array).size() < least or (v as Array).size() > most:
		return false
	for t: Variant in v:
		if str(t).length() > letters:
			return false
	return true


static func _whole(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT and is_equal_approx(float(v), roundf(float(v)))


static func _number(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT]


# --- Drawing ------------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"factor_tree":
			_draw_tree(pic, font, r, d)
		"prime_venn":
			_draw_prime_venn(pic, font, r, d)
		"distance_time":
			_draw_dt(pic, font, r, d)
		"speed_triangle":
			_draw_triangle(pic, font, r, d)
		"chart_kinds":
			_draw_charts(pic, font, r, d)
		"odd_scale":
			_draw_odd(pic, font, r, d)
		"big_icons":
			_draw_icons(pic, font, r, d)
		"periodic_grid":
			_draw_grid(pic, font, r, d)
		"ph_scale":
			_draw_ph(pic, font, r, d)
		"separation":
			_draw_separation(pic, font, r, d)
		"chromatogram":
			_draw_chroma(pic, font, r, d)
		"light_rays":
			_draw_light(pic, font, r, d)
		"seen_colour":
			_draw_seen(pic, font, r, d)
		"carbon_cycle":
			_draw_carbon(pic, font, r, d)
		"air_mix":
			_draw_air(pic, font, r, d)
		"marked_text":
			_draw_marked(pic, font, r, d)
		"venn":
			_draw_venn(pic, font, r, d)
		"pov_view":
			_draw_pov(pic, font, r, d)


# --- Factor trees and Venn diagrams of primes ---------------------------------------------------------------------------

static func _draw_tree(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var n := int(d.n)
	var ps := prime_factors(n)
	var k := ps.size()
	var fs := _fs(r, 10.0)
	var foot := fs * 1.9 if bool(d.get("powers", false)) else 0.0
	var area := Rect2(r.position, r.size - Vector2(0, foot))
	var rh := area.size.y / k
	fs = mini(fs, int(rh * 0.5))
	var dx := minf(area.size.x / (k + 1.5) * 0.9, fs * 2.6)
	var hide := int(d.get("hide", -1))
	var x := area.get_center().x - dx * 0.275 * (k - 1)
	var y := area.position.y + rh * 0.5
	var left := n
	_say(ci, font, Vector2(x, y), str(n), fs + 2)
	for i in range(1, k):
		var y2 := y + rh
		var leaf := Vector2(x - dx * 0.55, y2)
		var rest := Vector2(x + dx * 0.55, y2)
		left /= ps[i - 1]
		ci.draw_line(Vector2(x, y + fs * 0.6), leaf - Vector2(0, fs * 0.8), INK, 2.0, true)
		ci.draw_line(Vector2(x, y + fs * 0.6), rest - Vector2(0, fs * 0.8), INK, 2.0, true)
		_prime_ring(ci, font, leaf, "?" if hide == i - 1 else str(ps[i - 1]), fs, hide == i - 1)
		if i == k - 1:
			_prime_ring(ci, font, rest, "?" if hide == k - 1 else str(left), fs, hide == k - 1)
		else:
			_say(ci, font, rest, str(left), fs)
		x = rest.x
		y = y2
	if foot > 0.0:
		var line := "%d = %s" % [n, power_form(n)]
		if hide >= 0:
			var shown: Array[String] = []
			for i in k:
				shown.append("?" if i == hide else str(ps[i]))
			line = "%d = %s" % [n, " × ".join(PackedStringArray(shown))]
		_say(ci, font, Vector2(r.get_center().x, r.end.y - foot * 0.5), line, _fit(font, line, fs + 2, r.size.x - 8.0))


static func _prime_ring(ci: CanvasItem, font: Font, c: Vector2, text: String, fs: int, hidden: bool) -> void:
	var rad := maxf(fs * 0.95, _text_w(font, text, fs) * 0.5 + 6.0)
	ci.draw_circle(c, rad, SOFT if hidden else Color.WHITE)
	ci.draw_arc(c, rad, 0.0, TAU, 32, ORANGE, 2.5, true)
	_say(ci, font, c, text, fs, ORANGE if hidden else INK, false)


static func _draw_prime_venn(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var a := int(d.a)
	var b := int(d.b)
	var parts := venn_parts(a, b)
	var fs := _fs(r, 11.0)
	var show := str(d.get("show", ""))
	var lines: Array[String] = []
	var tail := "?" if bool(d.get("hide", false)) else ""
	if show == "hcf" or show == "both":
		var shared_p: Array = parts[1]
		var said := " × ".join(PackedStringArray(shared_p.map(func(x: Variant) -> String: return str(x)))) \
			if not shared_p.is_empty() else "1"
		if shared_p.is_empty():
			lines.append("HCF = %s" % (tail if tail != "" else "1"))
		else:
			lines.append("HCF = %s = %s" % [said, tail if tail != "" else str(hcf(a, b))])
	if show == "lcm" or show == "both":
		var all: Array = (parts[0] as Array) + (parts[1] as Array) + (parts[2] as Array)
		all.sort()
		lines.append("LCM = %s = %s" % [" × ".join(PackedStringArray(all.map(func(x: Variant) -> String: return str(x)))),
			tail if tail != "" else str(lcm(a, b))])
	var foot := lines.size() * (fs * 1.5)
	var names: Array = d.get("names", [str(a), str(b)])
	var head := fs * 1.6
	var area := Rect2(r.position + Vector2(0, head), r.size - Vector2(0, head + foot + 4.0))
	var rad := minf(area.size.y * 0.5, area.size.x * 0.27)
	var c := area.get_center()
	var cl := c - Vector2(rad * 0.62, 0)
	var cr := c + Vector2(rad * 0.62, 0)
	ci.draw_circle(cl, rad, Color(0.23, 0.48, 0.91, 0.16))
	ci.draw_circle(cr, rad, Color(0.94, 0.54, 0.11, 0.18))
	ci.draw_arc(cl, rad, 0.0, TAU, 64, BLUE, 2.5, true)
	ci.draw_arc(cr, rad, 0.0, TAU, 64, ORANGE, 2.5, true)
	_say(ci, font, Vector2(cl.x - rad * 0.3, r.position.y + head * 0.5), str(names[0]), fs + 1, BLUE)
	_say(ci, font, Vector2(cr.x + rad * 0.3, r.position.y + head * 0.5), str(names[1]), fs + 1, ORANGE)
	_prime_column(ci, font, Vector2(cl.x - rad * 0.5, c.y), parts[0], fs, rad)
	_prime_column(ci, font, c, parts[1], fs, rad)
	_prime_column(ci, font, Vector2(cr.x + rad * 0.5, c.y), parts[2], fs, rad)
	for i in lines.size():
		var t := lines[i]
		_say(ci, font, Vector2(r.get_center().x, r.end.y - foot + fs * 0.75 + i * fs * 1.5), t,
			_fit(font, t, fs, r.size.x - 6.0))


## Primes stacked in a region (two columns when there are more than three).
static func _prime_column(ci: CanvasItem, font: Font, c: Vector2, primes: Array, fs: int, rad: float) -> void:
	var n := primes.size()
	if n == 0:
		return
	var cols := 1 if n <= 3 else 2
	var rows := ceili(n / float(cols))
	var step := minf(fs * 1.35, rad * 1.5 / rows)
	for i in n:
		var col := i % cols if cols == 2 else 0
		var row := i / cols
		var at := c + Vector2((col - 0.5) * fs * 1.5 if cols == 2 else 0.0, (row - (rows - 1) * 0.5) * step)
		_say(ci, font, at, str(primes[i]), fs, INK)


# --- Speed: distance-time graphs and the formula triangle ---------------------------------------------------------------

static func _draw_dt(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 15.0)
	var pts: Array = d.points
	var t_unit := str(d.get("t_unit", "min"))
	var d_unit := str(d.get("d_unit", "km"))
	var top := fs * 1.4 if d.has("title") else 4.0
	var g := Rect2(r.position + Vector2(fs * 3.4, top + fs * 0.4), r.size - Vector2(fs * 3.4 + 10.0, top + fs * 3.2))
	if d.has("title"):
		_say(ci, font, Vector2(r.get_center().x, r.position.y + fs * 0.7), str(d.title), fs + 1)
	var t_to := float(d.t_to)
	var d_to := float(d.d_to)
	var nt := roundi(t_to / float(d.t_step))
	var nd := roundi(d_to / float(d.d_step))
	for i in nt + 1:
		var x := g.position.x + g.size.x * i / nt
		ci.draw_line(Vector2(x, g.position.y), Vector2(x, g.end.y), Color(0.75, 0.8, 0.88), 1.0)
		_say(ci, font, Vector2(x, g.end.y + fs * 0.7), _num(float(d.t_step) * i), fs - 2, INK, false)
	for j in nd + 1:
		var y := g.end.y - g.size.y * j / nd
		ci.draw_line(Vector2(g.position.x, y), Vector2(g.end.x, y), Color(0.75, 0.8, 0.88), 1.0)
		_say_from(ci, font, Vector2(g.position.x - 5.0, y), _num(float(d.d_step) * j), fs - 2, INK, true, false)
	ci.draw_line(g.position, Vector2(g.position.x, g.end.y), INK, 2.0)
	ci.draw_line(Vector2(g.position.x, g.end.y), g.end, INK, 2.0)
	var t_name: String = {"min": "time (minutes)", "h": "time (hours)", "s": "time (seconds)"}[t_unit]
	_say(ci, font, Vector2(g.get_center().x, r.end.y - fs * 0.6), t_name, fs - 1)
	var d_name := "distance (%s)" % d_unit
	ci.draw_set_transform(Vector2(r.position.x + fs * 0.7, g.get_center().y), -PI / 2.0, Vector2.ONE)
	_say(ci, font, Vector2.ZERO, d_name, _fit(font, d_name, fs - 1, g.size.y), INK, false)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var at := func(pt: Array) -> Vector2:
		return Vector2(g.position.x + g.size.x * float(pt[0]) / t_to, g.end.y - g.size.y * float(pt[1]) / d_to)
	var mark := int(d.get("mark", -1))
	for i in pts.size() - 1:
		var a: Vector2 = at.call(pts[i])
		var b: Vector2 = at.call(pts[i + 1])
		ci.draw_line(a, b, ORANGE if i == mark else BLUE, 5.0 if i == mark else 3.0, true)
		if bool(d.get("legs", false)) and i < LEG_LETTERS.length():
			var mid := (a + b) * 0.5
			var nrm := Vector2(-(b - a).y, (b - a).x).normalized()
			if nrm.y > 0.0:
				nrm = -nrm
			_say(ci, font, mid + nrm * fs * 0.9, LEG_LETTERS[i], fs, ORANGE if i == mark else INK)
	for pt: Array in pts:
		ci.draw_circle(at.call(pt), 4.0, INK)


static func _num(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(roundi(v))
	return str(snappedf(v, 0.01))


static func _draw_triangle(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 9.0)
	var cover := str(d.get("cover", ""))
	var formula := bool(d.get("formula", false)) and cover != ""
	var tri := Rect2(r.position, Vector2(r.size.x * (0.5 if formula else 1.0), r.size.y))
	var h := minf(tri.size.y - 8.0, tri.size.x * 0.8)
	var w := h * 1.15
	var c := tri.get_center()
	var apex := Vector2(c.x, c.y - h * 0.5)
	var bl := Vector2(c.x - w * 0.5, c.y + h * 0.5)
	var br := Vector2(c.x + w * 0.5, c.y + h * 0.5)
	var mid_y := c.y + h * 0.02
	var ml := apex.lerp(bl, (mid_y - apex.y) / (bl.y - apex.y))
	var mr := apex.lerp(br, (mid_y - apex.y) / (br.y - apex.y))
	var regions := {"distance": [apex, mr, ml], "speed": [ml, Vector2(c.x, mid_y), Vector2(c.x, bl.y), bl],
		"time": [Vector2(c.x, mid_y), mr, br, Vector2(c.x, br.y)]}
	for q: String in regions:
		_poly(ci, regions[q], SOFT if q == cover else Color.WHITE, INK, 0.0)
	_poly(ci, [apex, br, bl], Color(0, 0, 0, 0), INK, 3.0)
	ci.draw_line(ml, mr, INK, 3.0, true)
	ci.draw_line(Vector2(c.x, mid_y), Vector2(c.x, bl.y), INK, 3.0, true)
	var tfs := fs
	_say(ci, font, Vector2(c.x, (apex.y + mid_y) * 0.5 + h * 0.12), "distance", _fit(font, "distance", tfs, (mr.x - ml.x) * 0.8),
		ORANGE if cover == "distance" else INK)
	_say(ci, font, Vector2((bl.x + c.x) * 0.5 + w * 0.06, (mid_y + bl.y) * 0.5), "speed",
		_fit(font, "speed", tfs, w * 0.3), ORANGE if cover == "speed" else INK)
	_say(ci, font, Vector2((br.x + c.x) * 0.5 - w * 0.06, (mid_y + bl.y) * 0.5), "time",
		_fit(font, "time", tfs, w * 0.3), ORANGE if cover == "time" else INK)
	if formula:
		var t := formula_for(cover)
		var room := Rect2(Vector2(tri.end.x, r.position.y), Vector2(r.size.x - tri.size.x, r.size.y))
		_box(ci, Rect2(room.position + Vector2(4, room.size.y * 0.32), Vector2(room.size.x - 8, room.size.y * 0.36)), SOFT,
			ORANGE, 8, 2)
		_text_in(ci, font, Rect2(room.position + Vector2(4, room.size.y * 0.32), Vector2(room.size.x - 8, room.size.y * 0.36)),
			t, fs - 1)


# --- Charts that tell the truth, and charts that mislead ----------------------------------------------------------------

static func _draw_charts(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var show: Array = d.show
	var n := show.size()
	var fs := _fs(r, 12.0)
	var names := bool(d.get("names", true))
	var foot := fs * 1.6 if names else 0.0
	var w := r.size.x / n
	for i in n:
		var kind := str(show[i])
		var cell := Rect2(r.position + Vector2(w * i + 5.0, 2.0), Vector2(w - 10.0, r.size.y - foot - 4.0))
		var marked := d.has("mark") and str(d.mark) == kind
		_box(ci, cell, SOFT if marked else Color.WHITE, ORANGE if marked else INK, 6, 3 if marked else 1)
		_mini_chart(ci, cell.grow(-cell.size.y * 0.12), kind)
		if names:
			var t := str(CHART_NAMES[kind])
			_say(ci, font, Vector2(cell.get_center().x, r.end.y - foot * 0.5), t, _fit(font, t, fs, w - 6.0),
				ORANGE if marked else INK)


static func _mini_chart(ci: CanvasItem, b: Rect2, kind: String) -> void:
	var base := Vector2(b.position.x, b.end.y)
	match kind:
		"bar", "line", "scatter", "pictogram":
			ci.draw_line(b.position, base, INK, 2.0)
			ci.draw_line(base, b.end, INK, 2.0)
	match kind:
		"bar":
			var hs: Array[float] = [0.55, 0.85, 0.4, 0.7]
			for i in 4:
				var bw := b.size.x / 5.5
				var x := b.position.x + bw * (0.5 + i * 1.25)
				ci.draw_rect(Rect2(x, b.end.y - b.size.y * hs[i], bw, b.size.y * hs[i]), [BLUE, ORANGE, GREEN, RED][i])
		"line":
			var ys: Array[float] = [0.15, 0.3, 0.28, 0.55, 0.62, 0.85]
			var prev := Vector2.ZERO
			for i in ys.size():
				var p := Vector2(b.position.x + b.size.x * (0.08 + 0.84 * i / (ys.size() - 1.0)), b.end.y - b.size.y * ys[i])
				if i > 0:
					ci.draw_line(prev, p, BLUE, 3.0, true)
				ci.draw_circle(p, 3.5, INK)
				prev = p
		"pie":
			var c := b.get_center()
			var rad := minf(b.size.x, b.size.y) * 0.5
			var shares: Array[float] = [0.5, 0.3, 0.2]
			var start := -PI / 2.0
			for i in 3:
				var sweep := TAU * shares[i]
				var pts := PackedVector2Array([c])
				for s in 17:
					pts.append(c + Vector2.from_angle(start + sweep * s / 16.0) * rad)
				ci.draw_colored_polygon(pts, [BLUE, ORANGE, GREEN][i])
				start += sweep
			ci.draw_arc(c, rad, 0.0, TAU, 48, INK, 2.0, true)
		"scatter":
			var dots: Array[Vector2] = [Vector2(0.1, 0.2), Vector2(0.2, 0.3), Vector2(0.3, 0.25), Vector2(0.4, 0.45),
				Vector2(0.5, 0.5), Vector2(0.6, 0.48), Vector2(0.7, 0.68), Vector2(0.8, 0.7), Vector2(0.9, 0.86)]
			for v in dots:
				ci.draw_circle(Vector2(b.position.x + b.size.x * v.x, b.end.y - b.size.y * v.y), 3.5, BLUE)
		"pictogram":
			var counts: Array[int] = [4, 2, 3]
			for row in 3:
				for k in counts[row]:
					var cs := minf(b.size.y / 4.0, b.size.x / 6.0)
					var at := Vector2(b.position.x + cs * (0.9 + k * 1.2), b.position.y + b.size.y * (0.2 + 0.3 * row))
					ci.draw_circle(at, cs * 0.45, [ORANGE, GREEN, BLUE][row])


static func _draw_odd(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 14.0)
	var fair := bool(d.get("fair", false))
	var top := fs * 1.5 if d.has("title") else 4.0
	if d.has("title"):
		_say(ci, font, Vector2(r.get_center().x, r.position.y + fs * 0.7), str(d.title), fs)
	var body := Rect2(r.position + Vector2(0, top), r.size - Vector2(0, top))
	var ticks: Array = d.ticks
	var even: Array = []
	if fair:
		var steps := ticks.size() - 1
		for i in steps + 1:
			even.append(float(ticks[0]) + (float(ticks[-1]) - float(ticks[0])) * i / steps)
		_bars_on(ci, font, Rect2(body.position, Vector2(body.size.x * 0.5 - 6.0, body.size.y)), d.values, ticks, fs, true,
			"as drawn")
		_bars_on(ci, font, Rect2(body.position + Vector2(body.size.x * 0.5 + 6.0, 0), Vector2(body.size.x * 0.5 - 6.0,
			body.size.y)), d.values, even, fs, false, "a fair axis")
	else:
		_bars_on(ci, font, body, d.values, ticks, fs, true, "")


static func _bars_on(ci: CanvasItem, font: Font, r: Rect2, values: Array, ticks: Array, fs: int, odd: bool,
		caption: String) -> void:
	var cap := fs * 1.7 if caption != "" else 0.0
	var tick_w := 0.0
	for t: Variant in ticks:
		tick_w = maxf(tick_w, _text_w(font, _num(float(t)), fs - 2))
	var g := Rect2(r.position + Vector2(tick_w + 10.0, fs * 0.5), r.size - Vector2(tick_w + 14.0, fs * 2.0 + cap))
	var n := ticks.size() - 1
	for i in n + 1:
		var y := g.end.y - g.size.y * i / n
		ci.draw_line(Vector2(g.position.x, y), Vector2(g.end.x, y), Color(0.78, 0.82, 0.9), 1.0)
		_say_from(ci, font, Vector2(g.position.x - 4.0, y), _num(float(ticks[i])), fs - 2, ORANGE if odd and uneven(ticks)
			else INK, true, false)
	ci.draw_line(g.position, Vector2(g.position.x, g.end.y), INK, 2.0)
	ci.draw_line(Vector2(g.position.x, g.end.y), g.end, INK, 2.0)
	var k := values.size()
	var slot := g.size.x / k
	for i in k:
		var v: Array = values[i]
		var hgt := drawn_height(ticks, float(v[1])) * g.size.y
		var x := g.position.x + slot * i + slot * 0.2
		ci.draw_rect(Rect2(x, g.end.y - hgt, slot * 0.6, hgt), [BLUE, ORANGE, GREEN, RED, Color("8e44ad")][i % 5])
		var lab := str(v[0])
		_say(ci, font, Vector2(x + slot * 0.3, g.end.y + fs * 0.7), lab, _fit(font, lab, fs - 2, slot - 2.0), INK, false)
	if caption != "":
		_say(ci, font, Vector2(r.get_center().x, r.end.y - cap * 0.5), caption, fs - 1, GREY)


static func _draw_icons(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var k := float(d.scale)
	var solid := bool(d.get("solid", false))
	var labels: Array = d.get("labels", [])
	var foot := fs * 1.6 if not labels.is_empty() else 4.0
	var room := Rect2(r.position, r.size - Vector2(0, foot))
	var small := minf(room.size.y / k * 0.92, room.size.x / (1.0 + k) * 0.7)
	var gap := (room.size.x - small * (1.0 + k)) / 3.0
	var base_y := room.end.y
	var x1 := room.position.x + gap
	var x2 := x1 + small + gap
	_icon(ci, Rect2(x1, base_y - small, small, small), str(d.what), solid)
	_icon(ci, Rect2(x2, base_y - small * k, small * k, small * k), str(d.what), solid)
	for i in mini(labels.size(), 2):
		var cx := x1 + small * 0.5 if i == 0 else x2 + small * k * 0.5
		_say(ci, font, Vector2(cx, r.end.y - foot * 0.5), str(labels[i]), _fit(font, str(labels[i]), fs, gap + small * k))


static func _icon(ci: CanvasItem, b: Rect2, what: String, solid: bool) -> void:
	if solid:
		var dep := b.size.x * 0.28
		var front := Rect2(b.position + Vector2(0, dep), b.size - Vector2(dep, dep))
		_poly(ci, [front.position, front.position + Vector2(dep, -dep), Vector2(front.end.x + dep, front.position.y - dep),
			Vector2(front.end.x, front.position.y)], Color("f6c56a"), INK, 2.0)
		_poly(ci, [Vector2(front.end.x, front.position.y), Vector2(front.end.x + dep, front.position.y - dep),
			Vector2(front.end.x + dep, front.end.y - dep), front.end], Color("d99a3c"), INK, 2.0)
		_box(ci, front, Color("f2b552"), INK, 0, 2)
		return
	match what:
		"bag":
			_poly(ci, [b.position + Vector2(b.size.x * 0.1, b.size.y * 0.3), b.position + Vector2(b.size.x * 0.9, b.size.y * 0.3),
				b.end, Vector2(b.position.x, b.end.y)], Color("d9a441"), INK, 2.0)
			ci.draw_arc(b.position + Vector2(b.size.x * 0.5, b.size.y * 0.3), b.size.x * 0.22, PI, TAU, 16, INK, 3.0, true)
			_poly(ci, [b.position + b.size * Vector2(0.38, 0.55), b.position + b.size * Vector2(0.62, 0.55),
				b.position + b.size * Vector2(0.62, 0.8), b.position + b.size * Vector2(0.38, 0.8)], Color("f6d77a"), INK, 1.0)
		"coin":
			ci.draw_circle(b.get_center(), b.size.x * 0.48, Color("f0c419"))
			ci.draw_arc(b.get_center(), b.size.x * 0.48, 0.0, TAU, 40, INK, 2.0, true)
			ci.draw_arc(b.get_center(), b.size.x * 0.34, 0.0, TAU, 40, Color("c99a12"), 2.0, true)
		"tree":
			ci.draw_rect(Rect2(b.position + b.size * Vector2(0.42, 0.6), b.size * Vector2(0.16, 0.4)), Color("8a5a2b"))
			ci.draw_circle(b.position + b.size * Vector2(0.5, 0.38), b.size.x * 0.36, GREEN)
		"house":
			_poly(ci, [b.position + b.size * Vector2(0.1, 0.45), b.position + b.size * Vector2(0.9, 0.45),
				b.position + b.size * Vector2(0.9, 1.0), b.position + b.size * Vector2(0.1, 1.0)], Color("f2d7b0"), INK, 2.0)
			_poly(ci, [b.position + b.size * Vector2(0.0, 0.48), b.position + b.size * Vector2(0.5, 0.05),
				b.position + b.size * Vector2(1.0, 0.48)], RED, INK, 2.0)
		"box":
			_box(ci, b, Color("f2b552"), INK, 2, 2)


# --- The periodic table -------------------------------------------------------------------------------------------------

## A periodic_grid's layout: its cell size, where each element is, the families' anchors.
static func _grid_geo(d: Dictionary, a: Rect2) -> Dictionary:
	var first := str(d.view) == "first20"
	var cols := 8 if first else 18
	var rows := 4 if first else 7
	var head := 0.0
	var side := 0.0
	var foot := 0.0
	var cs := minf(a.size.x / (cols + 0.6), a.size.y / (rows + 0.6))
	if bool(d.get("groups", false)):
		head = cs * 0.55
	if bool(d.get("periods", false)):
		side = cs * 0.6
	if bool(d.get("shade", false)):
		foot = cs * 0.6
	cs = minf((a.size.x - side) / cols, (a.size.y - head - foot) / rows)
	var w := cs * cols + side
	var h := cs * rows + head + foot
	var origin := a.get_center() - Vector2(w, h) * 0.5 + Vector2(side, head)
	var cells := {}
	var last := 20 if first else SYMBOLS.size()
	for z in range(1, last + 1):
		var sym := SYMBOLS[z - 1]
		var pl := place_of(sym)
		if pl.x < 1:
			continue
		var col := pl.x
		if first:
			col = 8 if pl.x == 18 else (pl.x if pl.x <= 2 else pl.x - 10)
		cells[sym] = Rect2(origin + Vector2((col - 1) * cs, (pl.y - 1) * cs), Vector2(cs, cs))
	var fams := {}
	for fam: String in FAMILIES:
		var g := int(FAMILIES[fam])
		if first and fam == "transition metals":
			continue
		var col := g
		if first:
			col = 8 if g == 18 else (g if g <= 2 else g - 10)
		var row := 3.0 if fam != "transition metals" else 5.0
		if first:
			row = 2.5 if fam == "alkali metals" else 3.0
		fams[fam] = origin + Vector2((col - 0.5) * cs, (row - 0.5) * cs)
	return {"cs": cs, "origin": origin, "cols": cols, "rows": rows, "cells": cells, "families": fams, "first": first,
		"foot": foot}


static func _draw_grid(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r)
	var labels := bool(d.get("labels", false))
	var a := _diagram_box(d, r)
	var g := _grid_geo(d, a)
	var cs: float = g.cs
	var origin: Vector2 = g.origin
	var first: bool = g.first
	var marks: Array = d.get("mark", [])
	var shade := bool(d.get("shade", false))
	var col := int(d.get("col", 0))
	var row := int(d.get("row", 0))
	var sfs := clampi(int(cs * (0.36 if first else 0.42)), 7, 22)
	var nfs := clampi(int(cs * 0.22), 6, 12)
	for sym: String in g.cells:
		var cell: Rect2 = g.cells[sym]
		var pl := place_of(sym)
		var in_col := col > 0 and (first and _first_col(pl.x) == col or not first and pl.x == col)
		var in_row := row > 0 and pl.y == row
		var fill := Color.WHITE
		if shade:
			fill = KIND_COLOURS[element_kind(sym)]
		if in_col or in_row:
			fill = SOFT
		var marked := marks.has(sym)
		_box(ci, cell.grow(-1.0), fill, ORANGE if marked else INK, 2, 3 if marked else 1)
		var hidden := str(d.get("hide", "")) == sym
		var said := "?" if hidden else sym
		if first and bool(d.get("numbers", true)):
			_say(ci, font, cell.position + Vector2(cs * 0.5, cs * 0.24), str(atomic_number(sym)), nfs, GREY, false)
			_say(ci, font, cell.position + Vector2(cs * 0.5, cs * 0.62), said, sfs, ORANGE if marked or hidden else INK, false)
		else:
			_say(ci, font, cell.get_center(), said, _fit(font, said, sfs, cs - 2.0), ORANGE if marked or hidden else INK, false)
	if not first:
		for pr: int in [6, 7]:
			var gap := Rect2(origin + Vector2(2 * cs, (pr - 1) * cs), Vector2(cs, cs))
			_box(ci, gap.grow(-1.0), PALE, GREY, 2, 1)
			_say(ci, font, gap.get_center(), "*", sfs, GREY, false)
		_staircase(ci, origin, cs)
	if bool(d.get("groups", false)):
		var n: int = g.cols
		for i in n:
			var t := str(i + 1)
			if first:
				t = "0" if i == 7 else str(i + 1)
			_say(ci, font, origin + Vector2((i + 0.5) * cs, -cs * 0.3), t, clampi(int(cs * 0.3), 7, 16),
				ORANGE if col == i + 1 else INK, false)
	if bool(d.get("periods", false)):
		for j in int(g.rows):
			_say(ci, font, origin + Vector2(-cs * 0.32, (j + 0.5) * cs), str(j + 1), clampi(int(cs * 0.3), 7, 16),
				ORANGE if row == j + 1 else INK, false)
	if shade:
		var y := origin.y + cs * int(g.rows) + float(g.foot) * 0.55
		var kinds: Array[String] = ["metal", "non-metal", "metalloid"]
		var kfs := clampi(int(cs * 0.3), 8, 15)
		var x := origin.x
		for kd in kinds:
			ci.draw_rect(Rect2(x, y - kfs * 0.45, kfs * 1.1, kfs * 0.9), KIND_COLOURS[kd])
			ci.draw_rect(Rect2(x, y - kfs * 0.45, kfs * 1.1, kfs * 0.9), INK, false, 1.0)
			var word := kd + "s"
			_say_from(ci, font, Vector2(x + kfs * 1.4, y), word, kfs, INK, false, false)
			x += kfs * 1.8 + _text_w(font, word, kfs) + kfs
	if labels:
		_label_parts(ci, font, r, d, g.families, fs)


static func _first_col(group18: int) -> int:
	if group18 == 18:
		return 8
	return group18 if group18 <= 2 else group18 - 10


## The staircase between the metals and the non-metals: down the left of B, Si, As, Te and At.
static func _staircase(ci: CanvasItem, origin: Vector2, cs: float) -> void:
	var pts := PackedVector2Array()
	for k in 5:
		var x := origin.x + (12 + k) * cs
		pts.append(Vector2(x, origin.y + (1 + k) * cs))
		pts.append(Vector2(x, origin.y + (2 + k) * cs))
	ci.draw_polyline(pts, RED, 3.0, true)


# --- Acids and alkalis --------------------------------------------------------------------------------------------------

static func _draw_ph(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var marks: Array = d.get("marks", [])
	var colours := bool(d.get("colours", true))
	var bands := bool(d.get("bands", false))
	var litmus := bool(d.get("litmus", false))
	var above := fs * 3.4 if not marks.is_empty() else fs * 0.5
	var below := fs * 1.4 + (fs * 1.5 if bands else 0.0) + (fs * 1.5 if litmus else 0.0)
	var bar_h := clampf(r.size.y - above - below - 6.0, fs * 1.2, fs * 3.6)
	var oy := maxf(0.0, (r.size.y - above - below - bar_h) * 0.5)
	var bar := Rect2(r.position.x + 6.0, r.position.y + oy + above, r.size.x - 12.0, bar_h)
	var cw := bar.size.x / 15.0
	for i in 15:
		var cell := Rect2(bar.position.x + cw * i, bar.position.y, cw, bar.size.y)
		ci.draw_rect(cell, PH_COLOURS[i] if colours else Color.WHITE)
		ci.draw_rect(cell, INK, false, 1.0)
		_say(ci, font, Vector2(cell.get_center().x, bar.end.y + fs * 0.7), str(i), fs - 2, INK, false)
	var y := bar.end.y + fs * 1.4
	if bands:
		y += fs * 0.75
		var nfs := _fit(font, "neutral", fs - 2, cw * 2.2)
		var half := _text_w(font, "neutral", nfs) * 0.5 + 4.0
		_band_text(ci, font, Vector2(bar.position.x, y), Vector2(bar.position.x + cw * 7.5 - half, y), "acid", fs - 1, RED)
		_say(ci, font, Vector2(bar.position.x + cw * 7.5, y), "neutral", nfs, GREEN)
		_band_text(ci, font, Vector2(bar.position.x + cw * 7.5 + half, y), Vector2(bar.end.x, y), "alkali", fs - 1, BLUE)
		y += fs * 0.75
	if litmus:
		y += fs * 0.75
		var sw := Vector2(cw * 1.6, fs * 0.9)
		ci.draw_rect(Rect2(Vector2(bar.position.x + cw * 2.0, y - sw.y * 0.5), sw), Color("e0453a"))
		_say_from(ci, font, Vector2(bar.position.x + cw * 3.8, y), "litmus red", fs - 2, INK, false, false)
		ci.draw_rect(Rect2(Vector2(bar.position.x + cw * 9.5, y - sw.y * 0.5), sw), Color("3a6fd8"))
		_say_from(ci, font, Vector2(bar.position.x + cw * 11.3, y), "litmus blue", fs - 2, INK, false, false)
	var hide := int(d.get("hide", -1))
	var order: Array = range(marks.size())
	order.sort_custom(func(i: int, j: int) -> bool: return float(marks[i][0]) < float(marks[j][0]))
	for k in order.size():
		var i: int = order[k]
		var m: Array = marks[i]
		var x := bar.position.x + cw * (float(m[0]) + 0.5)
		var high := k % 2 == 1
		var ly := r.position.y + oy + (fs * 0.8 if high else fs * 2.0)
		ci.draw_line(Vector2(x, ly + fs * 0.6), Vector2(x, bar.position.y - 2.0), INK, 2.0, true)
		_poly(ci, [Vector2(x, bar.position.y - 1.0), Vector2(x - 5.0, bar.position.y - 9.0), Vector2(x + 5.0,
			bar.position.y - 9.0)], INK, INK, 0.0)
		var t := "?" if i == hide else str(m[1])
		var tw := _text_w(font, t, fs - 1) + 8.0
		var cx := clampf(x, r.position.x + tw * 0.5, r.end.x - tw * 0.5)
		_box(ci, Rect2(cx - tw * 0.5, ly - fs * 0.6, tw, fs * 1.2), SOFT if i == hide else Color.WHITE,
			ORANGE if i == hide else INK, 4, 1)
		_say(ci, font, Vector2(cx, ly), t, fs - 1, ORANGE if i == hide else INK, false)


## A band's word between two points, with arrows out to both ends (stronger towards the ends).
static func _band_text(ci: CanvasItem, font: Font, from: Vector2, to: Vector2, text: String, fs: int, colour: Color) -> void:
	var c := (from + to) * 0.5
	var tw := _text_w(font, text, fs) * 0.5 + 6.0
	_arrow(ci, Vector2(c.x - tw, c.y), Vector2(from.x + 2.0, c.y), colour, 2.0)
	_arrow(ci, Vector2(c.x + tw, c.y), Vector2(to.x - 2.0, c.y), colour, 2.0)
	_say(ci, font, c, text, fs, colour, false)


# --- Separating mixtures ------------------------------------------------------------------------------------------------

static func _draw_separation(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r)
	var labels := bool(d.get("labels", false))
	var a := _diagram_box(d, r)
	match str(d.method):
		"filter":
			_draw_filter(ci, a)
		"evaporate":
			_draw_evaporate(ci, a)
		"distil":
			_draw_distil(ci, a)
		"chromatography":
			_draw_paper(ci, a)
		"sieve":
			_draw_sieve(ci, a)
		"magnet":
			_draw_magnet(ci, a)
	if labels:
		_label_parts(ci, font, r, d, _anchors(d, a), fs)
	elif d.has("mark") or d.has("hide"):
		var anchors := _anchors(d, a)
		for key: String in ["mark", "hide"]:
			if d.has(key):
				var at: Vector2 = anchors[str(d[key])]
				ci.draw_arc(at, fs * 0.9, 0.0, TAU, 24, ORANGE, 3.0, true)
				if key == "hide":
					_say(ci, font, at, "?", fs, ORANGE)


static func _beaker(ci: CanvasItem, a: Rect2, c: Vector2, w: float, h: float, fill: float, colour: Color) -> Rect2:
	var b := Rect2(c.x - w * 0.5, c.y - h * 0.5, w, h)
	if fill > 0.0:
		ci.draw_rect(Rect2(b.position.x, b.end.y - h * fill, w, h * fill), colour)
	ci.draw_polyline(PackedVector2Array([b.position, Vector2(b.position.x, b.end.y), b.end, Vector2(b.end.x, b.position.y)]),
		INK, 2.5, true)
	return b


static func _draw_filter(ci: CanvasItem, a: Rect2) -> void:
	var top := _at(a, 0.5, 0.12)
	var cone_w := a.size.y * 0.8
	var tip := _at(a, 0.5, 0.52)
	ci.draw_colored_polygon(PackedVector2Array([top - Vector2(cone_w * 0.5, 0), top + Vector2(cone_w * 0.5, 0), tip]),
		Color("f6f1e4"))
	var sand := _at(a, 0.5, 0.36)
	for i in 14:
		var off := Vector2((i % 7 - 3) * a.size.y * 0.035, (i / 7) * a.size.y * 0.04)
		ci.draw_circle(sand + off, a.size.y * 0.018, Color("c9a35a"))
	ci.draw_polyline(PackedVector2Array([top - Vector2(cone_w * 0.5, 0), tip, top + Vector2(cone_w * 0.5, 0)]), INK, 2.5,
		true)
	ci.draw_polyline(PackedVector2Array([top - Vector2(cone_w * 0.42, 0), tip - Vector2(0, a.size.y * 0.04),
		top + Vector2(cone_w * 0.42, 0)]), GREY, 1.5, true)
	ci.draw_line(tip, tip + Vector2(0, a.size.y * 0.14), INK, 3.0)
	for k in 2:
		ci.draw_circle(tip + Vector2(0, a.size.y * (0.2 + k * 0.06)), 2.5, BLUE)
	_beaker(ci, a, _at(a, 0.5, 0.8), a.size.y * 0.7, a.size.y * 0.32, 0.4, WATER)


static func _draw_evaporate(ci: CanvasItem, a: Rect2) -> void:
	var c := _at(a, 0.5, 0.42)
	var w := a.size.y * 0.9
	var pts := PackedVector2Array()
	for i in 17:
		var t := PI * i / 16.0
		pts.append(c + Vector2(-cos(t) * w * 0.5, sin(t) * w * 0.15))
	var liquid := PackedVector2Array()
	for i in 17:
		var t := PI * i / 16.0
		liquid.append(c + Vector2(-cos(t) * w * 0.42, sin(t) * w * 0.12 + w * 0.015))
	ci.draw_colored_polygon(liquid, WATER)
	ci.draw_polyline(pts, INK, 3.0, true)
	for i in 5:
		ci.draw_circle(c + Vector2((i - 2) * w * 0.12, -w * 0.02), 3.0, Color.WHITE)
	var ring_y := _at(a, 0.5, 0.58).y
	ci.draw_line(Vector2(c.x - w * 0.55, ring_y), Vector2(c.x + w * 0.55, ring_y), GREY, 4.0)
	ci.draw_line(Vector2(c.x - w * 0.45, ring_y), Vector2(c.x - w * 0.55, a.end.y - 4.0), INK, 3.0)
	ci.draw_line(Vector2(c.x + w * 0.45, ring_y), Vector2(c.x + w * 0.55, a.end.y - 4.0), INK, 3.0)
	_flame(ci, _at(a, 0.5, 0.8), a.size.y * 0.16)
	for k in 3:
		var x := c.x + (k - 1) * w * 0.22
		var steam := PackedVector2Array()
		for s in 9:
			steam.append(Vector2(x + sin(s * 0.9) * 5.0, c.y - w * 0.12 - s * a.size.y * 0.035))
		ci.draw_polyline(steam, GREY, 2.0, true)


static func _flame(ci: CanvasItem, base: Vector2, h: float) -> void:
	ci.draw_rect(Rect2(base.x - h * 0.18, base.y + h * 0.2, h * 0.36, h * 0.5), METAL)
	_poly(ci, [base + Vector2(-h * 0.22, h * 0.2), base + Vector2(0, -h * 0.75), base + Vector2(h * 0.22, h * 0.2)], FLAME,
		Color("c0601a"), 1.5)
	_poly(ci, [base + Vector2(-h * 0.1, h * 0.18), base + Vector2(0, -h * 0.3), base + Vector2(h * 0.1, h * 0.18)], BLUE,
		BLUE, 0.0)


static func _draw_distil(ci: CanvasItem, a: Rect2) -> void:
	var fc := _at(a, 0.15, 0.6)
	var fr := a.size.y * 0.17
	var liquid := PackedVector2Array()
	for i in 21:
		var t := lerpf(0.15 * PI, 0.85 * PI, i / 20.0)
		liquid.append(fc + Vector2(cos(t), sin(t)) * (fr - 2.0))
	ci.draw_colored_polygon(liquid, WATER)
	ci.draw_arc(fc, fr, -PI * 0.38, PI * 1.38, 40, INK, 3.0, true)
	var neck_top := _at(a, 0.15, 0.24)
	ci.draw_line(fc + Vector2(-fr * 0.35, -fr * 0.94), Vector2(neck_top.x - fr * 0.35, neck_top.y), INK, 3.0)
	ci.draw_line(fc + Vector2(fr * 0.35, -fr * 0.94), Vector2(neck_top.x + fr * 0.35, neck_top.y), INK, 3.0)
	ci.draw_line(_at(a, 0.15, 0.04), _at(a, 0.15, 0.36), Color("c0392b"), 3.0)
	ci.draw_rect(Rect2(_at(a, 0.15, 0.04) - Vector2(4, 0), Vector2(8, a.size.y * 0.06)), Color.WHITE)
	ci.draw_rect(Rect2(_at(a, 0.15, 0.04) - Vector2(4, 0), Vector2(8, a.size.y * 0.06)), INK, false, 1.5)
	var c0 := _at(a, 0.18, 0.3)
	var c1 := _at(a, 0.8, 0.62)
	var dir := (c1 - c0).normalized()
	var nrm := Vector2(-dir.y, dir.x)
	var jw := a.size.y * 0.075
	var j0 := c0.lerp(c1, 0.22)
	var j1 := c0.lerp(c1, 0.85)
	ci.draw_colored_polygon(PackedVector2Array([j0 + nrm * jw, j1 + nrm * jw, j1 - nrm * jw, j0 - nrm * jw]),
		Color(0.6, 0.8, 0.98, 0.6))
	ci.draw_polyline(PackedVector2Array([j0 + nrm * jw, j1 + nrm * jw, j1 - nrm * jw, j0 - nrm * jw, j0 + nrm * jw]), INK,
		2.0, true)
	ci.draw_line(c0, c1, INK, 3.0, true)
	var inlet := Vector2((j1 + nrm * jw).x, (j1 + nrm * jw).y)
	ci.draw_line(inlet, Vector2(inlet.x, _at(a, 0.0, 0.76).y), INK, 3.0)
	_arrow(ci, Vector2(inlet.x, _at(a, 0.0, 0.84).y), Vector2(inlet.x, _at(a, 0.0, 0.765).y), BLUE, 2.5)
	var outlet := j0 - nrm * jw
	ci.draw_line(outlet, Vector2(outlet.x, _at(a, 0.0, 0.2).y), INK, 3.0)
	_arrow(ci, Vector2(outlet.x, _at(a, 0.0, 0.2).y), Vector2(outlet.x, _at(a, 0.0, 0.12).y), BLUE, 2.5)
	_flame(ci, _at(a, 0.15, 0.86), a.size.y * 0.1)
	_beaker(ci, a, _at(a, 0.86, 0.82), a.size.y * 0.24, a.size.y * 0.26, 0.35, WATER)
	ci.draw_circle(c1 + Vector2(0, a.size.y * 0.06), 2.5, BLUE)


static func _draw_paper(ci: CanvasItem, a: Rect2) -> void:
	var beaker := _beaker(ci, a, _at(a, 0.5, 0.78), a.size.y * 0.5, a.size.y * 0.36, 0.3, WATER)
	ci.draw_line(_at(a, 0.3, 0.06), _at(a, 0.7, 0.06), INK, 3.0)
	var paper := Rect2(_at(a, 0.42, 0.06), Vector2(a.size.x * 0.16, beaker.end.y - _at(a, 0.42, 0.06).y - 4.0))
	ci.draw_rect(paper, Color(1, 1, 1, 0.92))
	ci.draw_rect(paper, INK, false, 1.5)
	var start_y := _at(a, 0.5, 0.72).y
	ci.draw_line(Vector2(paper.position.x + 3.0, start_y), Vector2(paper.end.x - 3.0, start_y), GREY, 2.0)
	var front_y := _at(a, 0.5, 0.22).y
	var x := paper.position.x
	while x < paper.end.x - 4.0:
		ci.draw_line(Vector2(x + 2.0, front_y), Vector2(minf(x + 7.0, paper.end.x - 2.0), front_y), BLUE, 2.0)
		x += 10.0
	ci.draw_circle(Vector2(paper.get_center().x, _at(a, 0.5, 0.5).y), 4.5, RED)
	ci.draw_circle(Vector2(paper.get_center().x, _at(a, 0.5, 0.36).y), 4.5, BLUE)
	ci.draw_circle(Vector2(paper.get_center().x, _at(a, 0.5, 0.6).y), 4.5, YELLOW)


static func _draw_sieve(ci: CanvasItem, a: Rect2) -> void:
	var c := _at(a, 0.5, 0.42)
	var w := a.size.y * 0.8
	ci.draw_line(c - Vector2(w * 0.5, 0), c + Vector2(w * 0.5, 0), INK, 3.0)
	for i in 13:
		var x := c.x - w * 0.5 + w * i / 12.0
		ci.draw_line(Vector2(x, c.y - 4.0), Vector2(x, c.y + 4.0), GREY, 1.5)
	ci.draw_arc(c, w * 0.5, 0.0, PI, 24, INK, 3.0, true)
	for i in 5:
		ci.draw_circle(c + Vector2((i - 2) * w * 0.15, -a.size.y * 0.07), a.size.y * 0.05, Color("9a8f80"))
	for i in 8:
		ci.draw_circle(c + Vector2((i - 3.5) * w * 0.07, a.size.y * (0.2 + (i % 3) * 0.05)), 2.5, Color("c9a35a"))
	_beaker(ci, a, _at(a, 0.5, 0.85), w * 0.9, a.size.y * 0.2, 0.0, WATER)
	for i in 10:
		ci.draw_circle(_at(a, 0.5, 0.9) + Vector2((i - 4.5) * w * 0.07, 0), 2.5, Color("c9a35a"))


static func _draw_magnet(ci: CanvasItem, a: Rect2) -> void:
	var c := _at(a, 0.5, 0.2)
	var w := a.size.y * 0.5
	ci.draw_rect(Rect2(c.x - w * 0.5, c.y - a.size.y * 0.1, w * 0.5, a.size.y * 0.2), RED)
	ci.draw_rect(Rect2(c.x, c.y - a.size.y * 0.1, w * 0.5, a.size.y * 0.2), BLUE)
	ci.draw_rect(Rect2(c.x - w * 0.5, c.y - a.size.y * 0.1, w, a.size.y * 0.2), INK, false, 2.0)
	for i in 16:
		var x := c.x + (i - 7.5) * w * 0.06
		var y := c.y + a.size.y * (0.14 + (i % 4) * 0.05)
		ci.draw_line(Vector2(x, y), Vector2(x + 2.0, y + 6.0), INK, 2.0)
	var dish := Rect2(_at(a, 0.3, 0.74), Vector2(a.size.x * 0.4, a.size.y * 0.16))
	ci.draw_rect(dish, Color("f1dfb0"))
	ci.draw_rect(dish, INK, false, 2.0)
	for i in 30:
		ci.draw_circle(dish.position + Vector2(8.0 + (i * 37 % 100) / 100.0 * (dish.size.x - 16.0),
			5.0 + (i * 53 % 100) / 100.0 * (dish.size.y - 10.0)), 1.6, Color("b08a3e"))


# --- Chromatography -----------------------------------------------------------------------------------------------------

static func _draw_chroma(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var samples: Array = d.samples
	var names := bool(d.get("names", false))
	var side := fs * 6.5 if names else 0.0
	var paper := Rect2(r.position + Vector2(side + 4.0, 2.0), Vector2(r.size.x - side - 8.0, r.size.y - 4.0))
	ci.draw_rect(paper, Color.WHITE)
	ci.draw_rect(paper, INK, false, 2.0)
	var start_y := paper.end.y - fs * 2.2
	var front_y := paper.position.y + fs * 0.9
	ci.draw_line(Vector2(paper.position.x + 4.0, start_y), Vector2(paper.end.x - 4.0, start_y), GREY, 2.0)
	var x := paper.position.x + 4.0
	while x < paper.end.x - 6.0:
		ci.draw_line(Vector2(x, front_y), Vector2(minf(x + 8.0, paper.end.x - 4.0), front_y), BLUE, 2.0)
		x += 13.0
	if names:
		_say_from(ci, font, Vector2(r.position.x + 2.0, front_y), "solvent front", fs - 3, BLUE, false, false)
		_say_from(ci, font, Vector2(r.position.x + 2.0, start_y), "start line", fs - 3, GREY, false, false)
	var n := samples.size()
	var slot := paper.size.x / n
	var mark := int(d.get("mark", -1))
	for i in n:
		var s: Array = samples[i]
		var cx := paper.position.x + slot * (i + 0.5)
		if i == mark:
			ci.draw_rect(Rect2(cx - slot * 0.42, front_y - fs * 0.3, slot * 0.84, start_y - front_y + fs * 1.9), SOFT)
		ci.draw_circle(Vector2(cx, start_y), 2.5, GREY)
		for h: Variant in s[1]:
			var y := lerpf(start_y, front_y, spot_height(h))
			var col := DYE_COLOURS[clampi(int(spot_height(h) * 10.0), 0, 9)]
			if h is Array:
				col = DYES[str(h[1])]
			ci.draw_circle(Vector2(cx, y), minf(fs * 0.55, slot * 0.22), col)
		_say(ci, font, Vector2(cx, paper.end.y - fs * 0.85), str(s[0]), _fit(font, str(s[0]), fs - 1, slot - 4.0),
			ORANGE if i == mark else INK, false)


# --- Light: reflection, refraction, the spectrum, colour ----------------------------------------------------------------

## A light_rays view's geometry in box `a`: the rays to draw ([points, colour, width]), the surfaces, and each part's
## place (`parts`, for its labels).
static func _light_geo(d: Dictionary, a: Rect2) -> Dictionary:
	var view := str(d.view)
	var rays: Array = []
	var parts := {}
	var shapes: Array = []
	var normals: Array = []
	var material := "water" if str(d.get("into", "glass")) == "water" else "glass"
	var n := _index(d)
	var angle := _angle(d)
	var y0 := _at(a, 0.5, 0.5).y
	match view:
		"specular", "diffuse":
			var sy := _at(a, 0.5, 0.72).y
			shapes.append(["surface", Rect2(_at(a, 0.08, 0.72), Vector2(a.size.x * 0.84, a.size.y * 0.08))])
			for k in 3:
				var hit := _at(a, 0.4 + k * 0.08, 0.72)
				var from := hit + Vector2(-a.size.y * 0.55, -a.size.y * 0.55)
				rays.append([[from, hit], YELLOW.darkened(0.2), 3.0])
				var out_dir := Vector2(1, -1).normalized()
				if view == "diffuse":
					out_dir = Vector2.from_angle(-PI * (0.2 + 0.3 * k)).normalized()
				rays.append([[hit, hit + out_dir * a.size.y * 0.62], YELLOW.darkened(0.2), 3.0])
			if view == "specular":
				parts = {"mirror": Vector2(_at(a, 0.8, 0.0).x, sy + a.size.y * 0.04), "incoming rays": _at(a, 0.3, 0.45),
					"reflected rays": _at(a, 0.62, 0.42)}
			else:
				parts = {"rough surface": Vector2(_at(a, 0.8, 0.0).x, sy + a.size.y * 0.04), "incoming rays": _at(a, 0.3,
					0.45), "scattered rays": _at(a, 0.58, 0.36)}
		"refraction", "leaving", "along_normal":
			shapes.append([material, Rect2(Vector2(a.position.x, y0), Vector2(a.size.x, a.end.y - y0))])
			var hit := Vector2(a.get_center().x, y0)
			var len_in := a.size.y * 0.5
			normals.append([Vector2(hit.x, a.position.y + 4.0), Vector2(hit.x, a.end.y - 4.0)])
			if view == "along_normal":
				rays.append([[Vector2(hit.x, a.position.y + 6.0), Vector2(hit.x, a.end.y - 6.0)], RED, 3.0])
				parts = {"incident ray": Vector2(hit.x, _at(a, 0.5, 0.25).y), "normal": Vector2(hit.x, _at(a, 0.5, 0.06).y),
					material: _at(a, 0.8, 0.78)}
			else:
				var n1 := 1.0 if view == "refraction" else n
				var n2 := n if view == "refraction" else 1.0
				var out_angle := refracted_angle(angle, n1, n2)
				var from := hit + Vector2(-sin(deg_to_rad(angle)), -cos(deg_to_rad(angle))) * len_in
				if view == "leaving":
					from = hit + Vector2(-sin(deg_to_rad(angle)), cos(deg_to_rad(angle))) * len_in
				var to := hit + Vector2(sin(deg_to_rad(out_angle)), cos(deg_to_rad(out_angle))) * len_in
				if view == "leaving":
					to = hit + Vector2(sin(deg_to_rad(out_angle)), -cos(deg_to_rad(out_angle))) * len_in
				rays.append([[from, hit], RED, 3.0])
				rays.append([[hit, to], RED, 3.0])
				parts = {"incident ray": from.lerp(hit, 0.45), "normal": Vector2(hit.x, _at(a, 0.5, 0.06).y if view
					== "refraction" else _at(a, 0.5, 0.94).y), "refracted ray": hit.lerp(to, 0.6),
					"air": _at(a, 0.82, 0.22) if view == "refraction" else _at(a, 0.82, 0.25), material: _at(a, 0.82, 0.78)}
		"block":
			var block := Rect2(_at(a, 0.32, 0.3), Vector2(a.size.x * 0.36, a.size.y * 0.42))
			shapes.append(["glass", block])
			var i_ang := deg_to_rad(angle)
			var hit := Vector2(block.position.x + block.size.x * 0.22, block.position.y)
			var from := hit + Vector2(-sin(i_ang), -cos(i_ang)) * a.size.y * 0.3
			var r_ang := deg_to_rad(refracted_angle(angle, 1.0, N_GLASS))
			var exit := hit + Vector2(tan(r_ang) * block.size.y, block.size.y)
			var out := exit + Vector2(sin(i_ang), cos(i_ang)) * a.size.y * 0.3
			rays.append([[from, hit, exit, out], RED, 3.0])
			normals.append([hit - Vector2(0, a.size.y * 0.12), hit + Vector2(0, a.size.y * 0.12)])
			normals.append([exit - Vector2(0, a.size.y * 0.12), exit + Vector2(0, a.size.y * 0.12)])
			parts = {"incident ray": from.lerp(hit, 0.5), "glass block": block.position + block.size * Vector2(0.75, 0.5),
				"emergent ray": exit.lerp(out, 0.6)}
		"prism":
			var apex := _at(a, 0.42, 0.08)
			var left := _at(a, 0.22, 0.88)
			var right := _at(a, 0.62, 0.88)
			shapes.append(["prism", [apex, right, left]])
			var hit := left.lerp(apex, 0.45)
			var from := hit + Vector2(-a.size.x * 0.22, a.size.y * 0.02)
			var out_hit := right.lerp(apex, 0.48)
			rays.append([[from, hit], Color.WHITE, 6.0])
			rays.append([[from, hit], GREY, 1.5])
			var inside := PackedVector2Array([hit, out_hit + Vector2(0, -a.size.y * 0.04), out_hit + Vector2(0, a.size.y * 0.06)])
			shapes.append(["inside", inside])
			var spread_from := out_hit
			for k in 7:
				var end := _at(a, 0.97, 0.42 + k * 0.075)
				rays.append([[spread_from + Vector2(0, (k - 3) * 2.0), end], SPECTRUM_COLOURS[k], 4.0])
			parts = {"white light": from.lerp(hit, 0.5), "prism": _at(a, 0.42, 0.62), "spectrum": _at(a, 0.86, 0.62),
				"red": _at(a, 0.94, 0.43), "violet": _at(a, 0.94, 0.86)}
	return {"rays": rays, "parts": parts, "shapes": shapes, "normals": normals, "material": material}


static func _draw_light(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r)
	var labels := bool(d.get("labels", false))
	var a := _diagram_box(d, r)
	var g := _light_geo(d, a)
	for s: Array in g.shapes:
		match str(s[0]):
			"surface":
				var b: Rect2 = s[1]
				if str(d.view) == "specular":
					ci.draw_rect(b, Color("cfd8e6"))
					ci.draw_line(b.position, Vector2(b.end.x, b.position.y), Color("6d7a8f"), 4.0)
				else:
					var pts := PackedVector2Array()
					var amp := minf(6.0, b.size.y * 0.6)
					for i in 25:
						pts.append(Vector2(b.position.x + b.size.x * i / 24.0, b.position.y - (amp if i % 2 == 1 else 0.0)))
					pts.append(b.end)
					pts.append(Vector2(b.position.x, b.end.y))
					ci.draw_colored_polygon(pts, Color("c9b79a"))
			"glass", "water":
				var b: Rect2 = s[1]
				ci.draw_rect(b, GLASS if str(s[0]) == "glass" else WATER)
				ci.draw_rect(b, Color("5b8fb9"), false, 2.0)
			"prism":
				_poly(ci, s[1], GLASS, Color("5b8fb9"), 2.5)
			"inside":
				ci.draw_colored_polygon(s[1], Color(1, 1, 1, 0.55))
	for nm: Array in g.normals:
		_dashed(ci, nm[0], nm[1], INK, 1.5)
	for ray: Array in g.rays:
		var pts: Array = ray[0]
		var col: Color = ray[1]
		for i in pts.size() - 1:
			var last := i == pts.size() - 2
			if last and col != Color.WHITE:
				_arrow(ci, pts[i], pts[i + 1], col, float(ray[2]))
			else:
				ci.draw_line(pts[i], pts[i + 1], col, float(ray[2]), true)
	if labels:
		_label_parts(ci, font, r, d, g.parts, fs)
	elif d.has("mark") or d.has("hide"):
		for key: String in ["mark", "hide"]:
			if d.has(key) and (g.parts as Dictionary).has(str(d[key])):
				var at: Vector2 = g.parts[str(d[key])]
				ci.draw_arc(at, fs * 0.8, 0.0, TAU, 24, ORANGE, 3.0, true)


static func _dashed(ci: CanvasItem, from: Vector2, to: Vector2, colour: Color, width: float) -> void:
	var length := from.distance_to(to)
	var dir := (to - from) / maxf(length, 0.001)
	var t := 0.0
	while t < length:
		ci.draw_line(from + dir * t, from + dir * minf(t + 7.0, length), colour, width)
		t += 12.0


static func _draw_seen(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var light := str(d.light)
	var object := str(d.object)
	var filter := str(d.get("filter", ""))
	var seen := seen_as(light, object, filter)
	var hide := bool(d.get("hide", false))
	var foot := fs * 1.6
	var b := Rect2(r.position, r.size - Vector2(0, foot))
	var lamp := Vector2(b.position.x + b.size.x * 0.1, b.position.y + b.size.y * 0.3)
	var thing := Vector2(b.get_center().x, b.position.y + b.size.y * 0.7)
	var eye := Vector2(b.end.x - b.size.x * 0.1, b.position.y + b.size.y * 0.3)
	var rad := minf(b.size.y * 0.18, b.size.x * 0.08)
	var beams: Array = PRIMARIES[light]
	for k in beams.size():
		var off := Vector2(0, (k - (beams.size() - 1) * 0.5) * 6.0)
		var hit := thing + Vector2(-rad * 0.7, -rad * 0.5) + off
		var col: Color = SEEN_COLOURS[str(beams[k])]
		_arrow(ci, lamp + off + Vector2(rad * 0.8, 0), hit, col, 3.0)
		var back := (PRIMARIES[object] as Array).has(beams[k])
		if back:
			var to := eye + off + Vector2(-rad * 0.9, 0)
			var through := filter == "" or str(beams[k]) == filter
			if filter != "":
				var fx := lerpf(thing.x, eye.x, 0.55)
				var at_f := hit.lerp(to, (fx - hit.x) / (to.x - hit.x))
				if through:
					_arrow(ci, hit + Vector2(rad * 1.4, 0), to, col, 3.0)
				else:
					ci.draw_line(hit + Vector2(rad * 1.4, 0), at_f, col, 3.0, true)
			else:
				_arrow(ci, hit + Vector2(rad * 1.4, 0), to, col, 3.0)
	if filter != "":
		var fx := lerpf(thing.x, eye.x, 0.55)
		ci.draw_rect(Rect2(fx - 5.0, b.position.y + b.size.y * 0.08, 10.0, b.size.y * 0.6), Color(SEEN_COLOURS[filter], 0.55))
		ci.draw_rect(Rect2(fx - 5.0, b.position.y + b.size.y * 0.08, 10.0, b.size.y * 0.6), INK, false, 1.5)
	var glow: Color = SEEN_COLOURS["white" if light == "white" else light]
	ci.draw_circle(lamp, rad * 0.75, glow.lightened(0.2))
	ci.draw_arc(lamp, rad * 0.75, 0.0, TAU, 32, INK, 2.0, true)
	ci.draw_rect(Rect2(lamp.x - rad * 0.3, lamp.y + rad * 0.7, rad * 0.6, rad * 0.4), GREY)
	var shown := Color("b9bec8")
	if not hide:
		shown = SEEN_COLOURS.get(seen, Color.BLACK)
	_thing(ci, thing, rad, str(d.get("thing", "ball")), shown)
	if hide:
		_say(ci, font, thing, "?", fs + 4, Color.WHITE)
	ci.draw_arc(eye, rad * 0.75, PI * 0.15, PI * 0.85, 20, INK, 2.5, true)
	ci.draw_arc(eye, rad * 0.75, -PI * 0.85, -PI * 0.15, 20, INK, 2.5, true)
	ci.draw_circle(eye, rad * 0.3, INK)
	var said := "%s light" % light
	_say(ci, font, Vector2(lamp.x + rad * 0.4, r.end.y - foot * 0.5), said, _fit(font, said, fs, b.size.x * 0.3))
	var obj := "a %s %s" % [object, str(d.get("thing", "ball"))]
	_say(ci, font, Vector2(thing.x, r.end.y - foot * 0.5), obj, _fit(font, obj, fs, b.size.x * 0.34))
	var you := "you see: %s" % ("?" if hide else seen)
	_say(ci, font, Vector2(eye.x - rad * 0.4, r.end.y - foot * 0.5), you, _fit(font, you, fs, b.size.x * 0.3),
		ORANGE if hide else INK)


static func _thing(ci: CanvasItem, c: Vector2, rad: float, thing: String, col: Color) -> void:
	match thing:
		"shirt":
			_poly(ci, [c + Vector2(-rad * 0.6, -rad), c + Vector2(rad * 0.6, -rad), c + Vector2(rad * 1.2, -rad * 0.4),
				c + Vector2(rad * 0.8, -rad * 0.1), c + Vector2(rad * 0.6, -rad * 0.3), c + Vector2(rad * 0.6, rad),
				c + Vector2(-rad * 0.6, rad), c + Vector2(-rad * 0.6, -rad * 0.3), c + Vector2(-rad * 0.8, -rad * 0.1),
				c + Vector2(-rad * 1.2, -rad * 0.4)], col, INK, 2.0)
		"book":
			_box(ci, Rect2(c - Vector2(rad * 0.9, rad * 0.75), Vector2(rad * 1.8, rad * 1.5)), col, INK, 3, 2)
			ci.draw_line(c + Vector2(-rad * 0.6, -rad * 0.75), c + Vector2(-rad * 0.6, rad * 0.75), INK, 1.5)
		"leaf":
			_poly(ci, [c + Vector2(-rad, rad * 0.3), c + Vector2(-rad * 0.3, -rad * 0.6), c + Vector2(rad, -rad * 0.4),
				c + Vector2(rad * 0.4, rad * 0.5)], col, INK, 2.0)
			ci.draw_line(c + Vector2(-rad, rad * 0.3), c + Vector2(rad, -rad * 0.4), INK, 1.5)
		"flower":
			for k in 6:
				ci.draw_circle(c + Vector2.from_angle(TAU * k / 6.0) * rad * 0.55, rad * 0.42, col)
			ci.draw_circle(c, rad * 0.3, Color("f0c419"))
			ci.draw_arc(c, rad * 0.3, 0.0, TAU, 16, INK, 1.5, true)
		"apple":
			ci.draw_circle(c, rad, col)
			ci.draw_arc(c, rad, 0.0, TAU, 32, INK, 2.0, true)
			ci.draw_line(c - Vector2(0, rad), c - Vector2(-rad * 0.15, rad * 1.35), Color("6b4a2a"), 3.0)
		_:
			ci.draw_circle(c, rad, col)
			ci.draw_arc(c, rad, 0.0, TAU, 32, INK, 2.0, true)


# --- The carbon cycle and the air ---------------------------------------------------------------------------------------

static func _draw_carbon(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 15.0)
	var a := _diagram_box(d, r)
	var names := bool(d.get("labels", true))
	var processes := bool(d.get("processes", true))
	var mark := str(d.get("mark", ""))
	var hide := str(d.get("hide", ""))
	for f: Array in FLOWS:
		var pts: Array = f[2]
		var marked := mark == str(f[0])
		var col := ORANGE if marked else (Color("c0392b") if str(f[1]) == "air" else GREEN.darkened(0.15))
		for i in pts.size() - 1:
			var p0 := _at(a, (pts[i] as Vector2).x, (pts[i] as Vector2).y)
			var p1 := _at(a, (pts[i + 1] as Vector2).x, (pts[i + 1] as Vector2).y)
			if i == pts.size() - 2:
				_arrow(ci, p0, p1, col, 3.5 if marked else 2.5)
			else:
				ci.draw_line(p0, p1, col, 3.5 if marked else 2.5, true)
	for s: String in STORES:
		var b: Array = STORE_BOX[s]
		var box := Rect2(_at(a, float(b[0]) - float(b[2]) * 0.5, float(b[1]) - float(b[3]) * 0.5),
			Vector2(a.size.x * float(b[2]), a.size.y * float(b[3])))
		var marked := mark == s
		var hidden := hide == s
		var fill: Color = STORE_COLOURS[STORES.find(s)]
		if marked or hidden:
			fill = SOFT
		_box(ci, box, fill, ORANGE if marked or hidden else INK, 8, 3 if marked else 2)
		if hidden:
			_say(ci, font, box.get_center(), "?", fs + 2, ORANGE, false)
		elif names:
			_text_in(ci, font, box, str(STORE_NAMES[s]), fs)
	if processes:
		var done := {}
		for f: Array in FLOWS:
			var at: Vector2 = f[3]
			var key := "%s@%.2f" % [f[0], at.y]
			if done.has(key):
				continue
			done[key] = true
			var said := "?" if hide == str(f[0]) else str(f[0])
			var marked := mark == str(f[0]) or hide == str(f[0])
			var pfs := fs + 4 if said == "?" else _fit(font, said, fs - 2, a.size.x * 0.22)
			_say(ci, font, _at(a, at.x, at.y), said, pfs, ORANGE if marked else INK)


static func _draw_air(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var gases: Array = d.get("gases", DRY_AIR)
	var side := minf(r.size.y - 6.0, r.size.x * 0.5)
	var grid := Rect2(r.position + Vector2(4.0, (r.size.y - side) * 0.5), Vector2(side, side))
	var cell := side / 10.0
	var k := 0
	var mark := int(d.get("mark", -1))
	var hide := int(d.get("hide", -1))
	for gi in gases.size():
		var g: Array = gases[gi]
		for _n in int(g[1]):
			var at := grid.position + Vector2((k % 10) * cell, (k / 10) * cell)
			ci.draw_rect(Rect2(at + Vector2(1, 1), Vector2(cell - 2.0, cell - 2.0)), GAS_COLOURS[gi % GAS_COLOURS.size()]
				if gi != hide else Color("d0d4dc"))
			k += 1
	ci.draw_rect(grid, INK, false, 2.0)
	var key := Rect2(Vector2(grid.end.x + 14.0, r.position.y), Vector2(r.end.x - grid.end.x - 16.0, r.size.y))
	var step := minf(fs * 2.0, key.size.y / gases.size())
	var y0 := key.get_center().y - step * (gases.size() - 1) * 0.5
	for gi in gases.size():
		var g: Array = gases[gi]
		var y := y0 + gi * step
		var sw := Rect2(key.position.x, y - fs * 0.5, fs * 1.2, fs)
		ci.draw_rect(sw, GAS_COLOURS[gi % GAS_COLOURS.size()] if gi != hide else Color("d0d4dc"))
		ci.draw_rect(sw, INK, false, 1.0)
		var t := "%s: %s" % [str(g[0]), "?" if gi == hide else "%d%%" % int(g[1])]
		var colour := ORANGE if gi == mark or gi == hide else INK
		_say_from(ci, font, Vector2(sw.end.x + 8.0, y), t, _fit(font, t, fs, key.size.x - fs * 1.6), colour, false, false)


# --- English: a marked passage, a Venn diagram, points of view ----------------------------------------------------------

static func _draw_marked(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var lines: Array = d.lines
	var marks: Array = d.get("marks", [])
	var tags: Array = d.get("tags", [])
	var gap := 1.9 if not tags.is_empty() else 1.45
	var fs := clampi(int(r.size.y / (lines.size() * gap + (2.2 if d.has("title") else 0.8) + (0.9 if not tags.is_empty()
		else 0.0))), 9, 24)
	var title_h := fs * 1.6 if d.has("title") else 0.0
	var longest := 0.0
	for t: Variant in lines:
		longest = maxf(longest, _text_w(font, str(t), fs))
	while fs > 9 and (longest > r.size.x - 24.0 or lines.size() * fs * gap + title_h > r.size.y - 8.0):
		fs -= 1
		longest = 0.0
		for t: Variant in lines:
			longest = maxf(longest, _text_w(font, str(t), fs))
		title_h = fs * 1.6 if d.has("title") else 0.0
	var card := Rect2(r.position + Vector2(4, 2), r.size - Vector2(8, 4))
	_box(ci, card, Color.WHITE, INK, 6, 1)
	if d.has("title"):
		_say(ci, font, Vector2(card.get_center().x, card.position.y + title_h * 0.55), str(d.title), fs, INK, false)
	var x0 := card.position.x + maxf(10.0, (card.size.x - longest) * 0.5)
	var block := lines.size() * fs * gap + (fs * 0.6 if not tags.is_empty() else 0.0)
	var y := card.position.y + title_h + maxf(2.0, (card.size.y - title_h - block) * 0.5) + fs * gap * 0.5
	for li in lines.size():
		var text := str(lines[li])
		for mi in marks.size():
			var m: Array = marks[mi]
			if int(m[0]) != li:
				continue
			var at := text.find(str(m[1]))
			var x := x0 + _text_w(font, text.substr(0, at), fs)
			var w := _text_w(font, str(m[1]), fs)
			ci.draw_rect(Rect2(x - 2.0, y - fs * 0.62, w + 4.0, fs * 1.24), SOFT)
			ci.draw_line(Vector2(x, y + fs * 0.62), Vector2(x + w, y + fs * 0.62), ORANGE, 2.5)
			if mi < tags.size() and str(tags[mi]) != "":
				_say(ci, font, Vector2(x + w * 0.5, y + fs * 1.15), str(tags[mi]), maxi(fs - 4, 8), ORANGE, false)
		_say_from(ci, font, Vector2(x0, y), text, fs, INK, false, false)
		y += fs * gap


static func _draw_venn(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var head := fs * 1.5
	var title_h := fs * 1.5 if d.has("title") else 0.0
	if d.has("title"):
		_say(ci, font, Vector2(r.get_center().x, r.position.y + title_h * 0.5), str(d.title), fs)
	var area := Rect2(r.position + Vector2(0, title_h + head), r.size - Vector2(0, title_h + head + 2.0))
	var ry := area.size.y * 0.5
	var rx := minf(area.size.x * 0.33, ry * 1.6)
	var c := area.get_center()
	var cl := c - Vector2(rx * 0.52, 0)
	var cr := c + Vector2(rx * 0.52, 0)
	for side in 2:
		var cc := cl if side == 0 else cr
		var pts := PackedVector2Array()
		for i in 49:
			pts.append(cc + Vector2(cos(TAU * i / 48.0) * rx, sin(TAU * i / 48.0) * ry))
		ci.draw_colored_polygon(pts, Color(0.23, 0.48, 0.91, 0.14) if side == 0 else Color(0.94, 0.54, 0.11, 0.16))
		ci.draw_polyline(pts, BLUE if side == 0 else ORANGE, 2.5, true)
	_say(ci, font, Vector2(cl.x - rx * 0.35, r.position.y + title_h + head * 0.5), str(d.left_name), fs, BLUE)
	_say(ci, font, Vector2(cr.x + rx * 0.35, r.position.y + title_h + head * 0.5), str(d.right_name), fs, ORANGE)
	var hide := str(d.get("hide", ""))
	_venn_items(ci, font, Vector2(cl.x - rx * 0.5, c.y), d.get("left", []), fs, rx * 0.9, hide == "left")
	_venn_items(ci, font, c, d.get("both", []), fs, rx * 0.86, hide == "both")
	_venn_items(ci, font, Vector2(cr.x + rx * 0.5, c.y), d.get("right", []), fs, rx * 0.9, hide == "right")


static func _venn_items(ci: CanvasItem, font: Font, c: Vector2, items: Array, fs: int, room: float, hidden: bool) -> void:
	if hidden:
		_say(ci, font, c, "?", fs + 6, ORANGE)
		return
	var n := items.size()
	var ifs := fs - 1
	for t: Variant in items:
		ifs = mini(ifs, _fit(font, str(t), fs - 1, room))
	for i in n:
		_say(ci, font, c + Vector2(0, (i - (n - 1) * 0.5) * ifs * 1.45), str(items[i]), ifs, INK)


static func _draw_pov(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var mode := str(d.mode)
	var names: Array = d.get("names", ["Ana", "Tom", "Mo"])
	var foot := fs * 1.7
	var b := Rect2(r.position, r.size - Vector2(0, foot))
	var eye_h := b.size.y * 0.24 if mode != "first" else 0.0
	var fig_h := (b.size.y - eye_h) * 0.66
	var seen: Array[int] = [0]
	if mode == "omniscient":
		seen = [0, 1, 2]
	var narrator := Vector2(b.get_center().x, b.position.y + eye_h * 0.45)
	if mode != "first":
		ci.draw_arc(narrator, eye_h * 0.42, PI * 0.15, PI * 0.85, 16, INK, 2.5, true)
		ci.draw_arc(narrator, eye_h * 0.42, -PI * 0.85, -PI * 0.15, 16, INK, 2.5, true)
		ci.draw_circle(narrator, eye_h * 0.16, INK)
		_say_from(ci, font, narrator + Vector2(eye_h * 0.6, 0), "narrator", fs - 1, GREY, false, false)
	for i in 3:
		var x := b.position.x + b.size.x * (0.2 + 0.3 * i)
		var feet := b.end.y - 4.0
		var head := Vector2(x, feet - fig_h * 0.82)
		var hr := fig_h * 0.13
		var col := ORANGE if i == 0 else INK
		ci.draw_circle(head, hr, Color.WHITE)
		ci.draw_arc(head, hr, 0.0, TAU, 20, col, 2.5, true)
		ci.draw_line(head + Vector2(0, hr), Vector2(x, feet - fig_h * 0.3), col, 2.5)
		ci.draw_line(Vector2(x, feet - fig_h * 0.3), Vector2(x - hr, feet), col, 2.5)
		ci.draw_line(Vector2(x, feet - fig_h * 0.3), Vector2(x + hr, feet), col, 2.5)
		ci.draw_line(Vector2(x - hr * 1.2, feet - fig_h * 0.55), Vector2(x + hr * 1.2, feet - fig_h * 0.55), col, 2.5)
		_say(ci, font, Vector2(x + hr * 2.6, feet - fig_h * 0.15), str(names[i]), fs - 1, col)
		var bubble := Vector2(x + hr * 1.6, head.y - fig_h * 0.42)
		var open := seen.has(i)
		var bw := fig_h * 0.62
		var bh := fig_h * 0.34
		_box(ci, Rect2(bubble - Vector2(bw, bh) * 0.5, Vector2(bw, bh)), Color.WHITE if open else PALE,
			ORANGE if open else GREY, int(bh * 0.5), 2)
		ci.draw_circle(head + Vector2(hr * 1.0, -hr * 1.3), 3.0, GREY)
		_say(ci, font, bubble, "..." if open else "?", fs, ORANGE if open else GREY, false)
		if mode != "first" and open:
			_dashed(ci, narrator + Vector2(0, eye_h * 0.3), bubble - Vector2(0, bh * 0.5), ORANGE, 1.5)
		if mode == "first" and i == 0:
			_say(ci, font, Vector2(x - hr * 2.4, head.y), "I", fs + 2, ORANGE)
	var said := "?" if bool(d.get("hide", false)) else str(POV_NAMES[mode])
	_say(ci, font, Vector2(r.get_center().x, r.end.y - foot * 0.5), said, fs, ORANGE if said == "?" else INK)


# --- Shared helpers -----------------------------------------------------------------------------------------------------

## The drawing area of a SchoolPicture of `size` (its MARGIN all round).
static func _rect(size: Vector2) -> Rect2:
	return Rect2(Vector2(SchoolPicture.MARGIN, SchoolPicture.MARGIN), size - Vector2(2, 2) * SchoolPicture.MARGIN)


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


## The largest size up to `fs` at which `text` fits in `room` pixels (at least 7).
static func _fit(font: Font, text: String, fs: int, room: float) -> int:
	var f := fs
	while f > 7 and _text_w(font, text, f) > room:
		f -= 1
	return f


## Text in a box, on two lines when one is too wide.
static func _text_in(ci: CanvasItem, font: Font, box: Rect2, text: String, fs: int, colour: Color = INK) -> void:
	var room := box.size.x - 8.0
	if _text_w(font, text, fs) <= room or not text.contains(" "):
		_say(ci, font, box.get_center(), text, _fit(font, text, fs, room), colour, false)
		return
	var cut := text.rfind(" ", text.length() / 2 + 2)
	if cut < 0:
		cut = text.find(" ")
	var a := text.substr(0, cut)
	var b := text.substr(cut + 1)
	var f := mini(_fit(font, a, fs, room), _fit(font, b, fs, room))
	f = mini(f, int(box.size.y / 2.6))
	_say(ci, font, box.get_center() - Vector2(0, f * 0.62), a, f, colour, false)
	_say(ci, font, box.get_center() + Vector2(0, f * 0.62), b, f, colour, false)


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
	if fill.a > 0.0:
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


## Part labels in bands along the top and bottom of `r` (a part goes to the band nearer its anchor), spread so they
## never overlap, each with a line to its anchor; orange when marked, "?" when hidden.
static func _label_parts(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary, anchors: Dictionary, fs: int) -> void:
	for on_top: bool in [true, false]:
		var row: Array = []
		for part: String in anchors:
			var at: Vector2 = anchors[part]
			if (at.y < r.get_center().y) == on_top:
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


static func _fit_box(r: Rect2, ratio: float) -> Rect2:
	var w := minf(r.size.x, r.size.y * ratio)
	var h := w / ratio
	return Rect2(r.get_center() - Vector2(w, h) * 0.5, Vector2(w, h))
