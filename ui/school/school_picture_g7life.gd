class_name SchoolPictureG7Life
extends RefCounted
## Owner #70, #73 and #111, grade 7 health and PE, design and technology, and projects (research §6.7): the picture kinds
## they add, drawn from data onto a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls
## only, no new art; the font has no arrows or signs, so they are drawn). A diagram's `labels` name its parts in bands
## along its top and bottom, each with a line to its part; `mark` (a part) is orange and `hide` (a part) shows "?"; its
## parts' places are `part_at`'s, so a label exercise's pins can point at them. Kinds and fields:
## Health and PE
## - hr_zones {max (150-220 whole: a maximum heart rate, about 220 − age), trace?: [[label (6 letters), bpm (30-230)]]
##   (2-8: a pulse over a session, joined), point? (a trace point's index: drawn big and orange), mark? (a zone of
##   ZONES), hide? (a zone: its name shown "?"), names? (true: each zone's name and its share of the maximum)}: the
##   heart-rate zones as bands: warm-up 50-60%, aerobic 60-80%, anaerobic 80-90%, maximum 90-100% (zone_of, zone_bpm).
## - shot_paths {sport: SPORTS ("badminton", "tennis"), shots: [SHOTS[sport]] (1-4, each once), tags? (letters A-D at
##   the landings instead of names), mark? (a shot, orange)}: a net game from the side: a player, the net and each shot's
##   flight (badminton: clear, drop, smash, drive, net shot; tennis: lob, drop, smash, drive).
## - sleep_dial {sleep, wake ("HH:MM" on the quarter hour; 4-14 hours apart), screens? ("HH:MM": screens off, a phone on
##   the rim), hours? (true: the hours of sleep in the middle), hide? (the hours shown "?")}: a 24-hour clock, midnight at
##   the top, with the night's sleep as a dark arc from falling asleep to waking (sleep_hours).
## - photo_edit {edits: [EDITS] (1-6, each once), tags? (numbered circles on the edited photo, one for each edit in the
##   list's order), names? (the edits listed under it), before? (true: the photo before it, beside it)}: a portrait
##   before and after editing: brighter light, a warm filter, smoothed skin, bigger eyes, whiter teeth, a new background.
## - advert {product: PRODUCTS, tricks: [TRICKS] (1-6, each once), words? (true: the tricks' words on the poster),
##   labels?, mark?, hide? (a trick)}: a poster advert and the tricks it uses to sell (TRICK_NAMES).
## - influence_map {centre (14 letters), influences: [text (14)] (2-6), mark?, hide? (an influence's index)}: what
##   pulls on a choice, round it, with arrows in.
## - ref_signal {signal: SIGNALS, card? ("yellow" | "red": the card's colour), name? (the signal's name under it)}: a
##   referee's signal (football's Laws of the Game): advantage (both arms forward), a direct free kick (an arm pointing the
##   way), an indirect free kick (an arm straight up), a penalty (pointing at the spot), a card held up.
## Design and technology
## - schematic {parts: [SYMS] (2-6, clockwise round the loop from the top left; one cell or battery), active? (push
##   switches, pressure pads, reed and tilt switches closed: pressed, near the magnet, tipped), lit? (when the loop is
##   complete, lamps and LEDs glow, a buzzer sounds, a motor turns), names? (each part named), values?: [text (8)] (one
##   each, "" for none), mark?, hide? (a part's index: a "?" box)}: a circuit diagram with UK symbols; conventional
##   current flows clockwise (out of the cell's long plate); an LED points the way it lets current through ("led") or
##   against it ("led_back": it stays dark) (conducts).
## - resistor {bands: [COLOURS] (3: digit, digit, multiplier; or 4: and gold or silver), names? (each band's colour under
##   it), value? (its value in ohms under it), hide? (a band's index, grey "?")}: a resistor and its colour bands
##   (resistor_ohms).
## - micro_board {leds?: [five rows of five "0" or "1"], pressed? ("A", "B" or "AB"), sound? (notes from the speaker),
##   grid? (x 0-4 along the top and y 0-4 down the side of the LEDs), labels?, mark?, hide? (BOARD_PARTS)}: a classroom
##   microcontroller board: a 5 × 5 grid of LEDs, buttons A and B, a speaker and the pins (led_at).
## - exploded {product: "torch", labels?, mark?, hide? (TORCH_PARTS)}: a product's exploded view: its parts pulled apart
##   along a line, in the order they fit together.
## - cam_process {machine: "laser" | "printer", layers? (printer: 2-12, the layers printed so far; 6), labels?, mark?,
##   hide? (CAM_PARTS[machine])}: a laser cutter cutting and engraving a sheet, or a 3D printer building a part layer by
##   layer.
## - fabric_section {type: FABRICS, labels?, mark?, hide? (FABRIC_PARTS[type])}: a breathable waterproof fabric's
##   layers (rain stays out, water vapour gets out), retroreflection (glass beads send a headlight's light back), or a
##   smart textile's circuit sewn with conductive thread.
## Projects
## - eco_home {features?: [ECO_PARTS] (1-6; all), labels?, mark?, hide?}: a home cut open to show what saves energy and
##   water: solar panels, loft insulation, double glazing, a heat pump, a rain butt and LED lights.

const KINDS: Array[String] = ["hr_zones", "shot_paths", "sleep_dial", "photo_edit", "advert", "influence_map",
	"ref_signal", "schematic", "resistor", "micro_board", "exploded", "cam_process", "fabric_section", "eco_home"]
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
const HAIR := Color("4a3222")
const NIGHT := Color("26346b")

## The kinds a label exercise can point at, and the shape (width ÷ height) each is drawn in, so `part_at` knows where.
const RATIOS := {"advert": 2.2, "micro_board": 1.7, "exploded": 2.2, "cam_process": 2.2, "fabric_section": 2.2,
	"eco_home": 2.2}

# --- Heart-rate zones -------------------------------------------------------------------------------------------------
const ZONES: Array[String] = ["warm-up", "aerobic", "anaerobic", "maximum"]
const ZONE_FROM := {"warm-up": 0.5, "aerobic": 0.6, "anaerobic": 0.8, "maximum": 0.9}
const ZONE_TO := {"warm-up": 0.6, "aerobic": 0.8, "anaerobic": 0.9, "maximum": 1.0}
const ZONE_COLOURS := {"warm-up": Color("cfe3fb"), "aerobic": Color("bfe6b8"), "anaerobic": Color("fbd5a6"),
	"maximum": Color("f6b3ab")}
const MAX_TRACE := 8
const MAX_TRACE_LABEL := 6

# --- Shots ------------------------------------------------------------------------------------------------------------
const SPORTS: Array[String] = ["badminton", "tennis"]
const SHOTS := {"badminton": ["clear", "drop", "smash", "drive", "net"], "tennis": ["lob", "drop", "smash", "drive"]}
const SHOT_NAMES := {"clear": "clear", "drop": "drop shot", "smash": "smash", "drive": "drive", "net": "net shot",
	"lob": "lob"}
## Each shot's flight as a curve (start, pull, landing) in shares of the court's length (x, from the player's end) and
## of the picture's height above the floor (y); the net stands at x 0.5.
const PATHS := {
	"badminton": {"clear": [Vector2(0.12, 0.62), Vector2(0.5, 1.35), Vector2(0.95, 0.0)],
		"drop": [Vector2(0.12, 0.62), Vector2(0.42, 0.85), Vector2(0.6, 0.0)],
		"smash": [Vector2(0.12, 0.66), Vector2(0.4, 0.6), Vector2(0.72, 0.0)],
		"drive": [Vector2(0.12, 0.45), Vector2(0.55, 0.55), Vector2(0.92, 0.0)],
		"net": [Vector2(0.42, 0.2), Vector2(0.5, 0.55), Vector2(0.58, 0.0)]},
	"tennis": {"lob": [Vector2(0.1, 0.25), Vector2(0.5, 1.6), Vector2(0.94, 0.0)],
		"drop": [Vector2(0.1, 0.25), Vector2(0.38, 0.6), Vector2(0.62, 0.0)],
		"smash": [Vector2(0.12, 0.7), Vector2(0.4, 0.5), Vector2(0.75, 0.0)],
		"drive": [Vector2(0.1, 0.25), Vector2(0.5, 0.45), Vector2(0.9, 0.0)]}}
const NET_HEIGHT := {"badminton": 0.3, "tennis": 0.18}
const SHOT_COLOURS: Array[Color] = [Color("d9433b"), Color("1f5fbf"), Color("2e8b3e"), Color("8e44ad"), Color("c07a10")]

# --- Sleep ------------------------------------------------------------------------------------------------------------
const MIN_SLEEP := 4.0
const MAX_SLEEP := 14.0

# --- Photo edits ------------------------------------------------------------------------------------------------------
const EDITS: Array[String] = ["light", "filter", "smooth", "eyes", "teeth", "background"]
const EDIT_NAMES := {"light": "brighter light", "filter": "warm filter", "smooth": "smoothed skin", "eyes": "bigger eyes",
	"teeth": "whiter teeth", "background": "new background"}

# --- Adverts ----------------------------------------------------------------------------------------------------------
const PRODUCTS: Array[String] = ["drink", "trainers", "cereal"]
const TRICKS: Array[String] = ["star", "bandwagon", "free_gift", "health_claim", "small_print", "ad_label"]
const TRICK_NAMES := {"star": "famous person", "bandwagon": "bandwagon", "free_gift": "free gift",
	"health_claim": "health claim", "small_print": "small print", "ad_label": "#ad label"}
const TRICK_WORDS := {"star": "My favourite!", "bandwagon": "Everyone's got one!", "free_gift": "FREE gift!",
	"health_claim": "Full of vitamins!", "small_print": "*Gift while stocks last. Prices may change.", "ad_label": "#ad"}
## Where each trick sits on the poster (shares of its box).
## (The top and bottom strips stay clear, except for the small print, so a label exercise's pins never hide a trick.)
const TRICK_AT := {"star": Vector2(0.13, 0.55), "bandwagon": Vector2(0.5, 0.25), "free_gift": Vector2(0.84, 0.33),
	"health_claim": Vector2(0.82, 0.66), "small_print": Vector2(0.42, 0.92), "ad_label": Vector2(0.94, 0.77)}
## Where a label's line ends on each trick: the edge facing its pin (shares of the box's height from TRICK_AT), so no
## line crosses its words.
const TRICK_EDGE := {"star": 0.0, "bandwagon": -0.08, "free_gift": -0.15, "health_claim": 0.13, "small_print": -0.04,
	"ad_label": 0.06}
const MAX_INFLUENCES := 6
const MAX_INFLUENCE := 14

# --- Referee's signals ------------------------------------------------------------------------------------------------
const SIGNALS: Array[String] = ["advantage", "direct", "indirect", "penalty", "card"]
const SIGNAL_NAMES := {"advantage": "advantage", "direct": "direct free kick", "indirect": "indirect free kick",
	"penalty": "penalty kick", "card": "a card"}

# --- Circuits ---------------------------------------------------------------------------------------------------------
const SYMS: Array[String] = ["cell", "battery", "switch", "closed", "push", "pad", "reed", "tilt", "resistor", "led",
	"led_back", "lamp", "buzzer", "motor", "ldr"]
const SYM_NAMES := {"cell": "cell", "battery": "battery", "switch": "switch (open)", "closed": "switch (closed)",
	"push": "push switch", "pad": "pressure pad", "reed": "reed switch", "tilt": "tilt switch", "resistor": "resistor",
	"led": "LED", "led_back": "LED", "lamp": "lamp", "buzzer": "buzzer", "motor": "motor", "ldr": "LDR"}
## The switches a person, a magnet or a tilt closes (`active`).
const SENSING: Array[String] = ["push", "pad", "reed", "tilt"]
const MAX_PARTS := 6
const MAX_VALUE := 8
const WIRE := Color("2a3550")
## Resistor colours by their digit (0-9), then the tolerance bands.
const COLOURS: Array[String] = ["black", "brown", "red", "orange", "yellow", "green", "blue", "violet", "grey", "white"]
const TOLERANCES: Array[String] = ["gold", "silver"]
const BAND_COLOURS := {"black": Color("1b1b1b"), "brown": Color("7a4a24"), "red": Color("d9433b"),
	"orange": Color("f08a1c"), "yellow": Color("f7d21e"), "green": Color("3aa845"), "blue": Color("2f6fdc"),
	"violet": Color("8a3fb8"), "grey": Color("8c8c8c"), "white": Color("f7f7f7"), "gold": Color("c9a227"),
	"silver": Color("c0c4cc")}

# --- The microcontroller board ----------------------------------------------------------------------------------------
const BOARD_PARTS: Array[String] = ["LED grid", "button A", "button B", "pins", "speaker"]
const BOARD_AT := {"LED grid": Vector2(0.5, 0.42), "button A": Vector2(0.12, 0.44), "button B": Vector2(0.88, 0.44),
	"pins": Vector2(0.5, 0.9), "speaker": Vector2(0.86, 0.14)}
const BOARD := Color("23272e")

# --- Exploded views ---------------------------------------------------------------------------------------------------
const PRODUCT_VIEWS: Array[String] = ["torch"]
const TORCH_PARTS: Array[String] = ["lens", "reflector", "LED", "case", "switch", "batteries", "spring", "end cap"]
const TORCH_AT := {"lens": Vector2(0.05, 0.55), "reflector": Vector2(0.15, 0.55), "LED": Vector2(0.24, 0.55),
	"case": Vector2(0.4, 0.55), "switch": Vector2(0.4, 0.17), "batteries": Vector2(0.62, 0.55),
	"spring": Vector2(0.78, 0.55), "end cap": Vector2(0.91, 0.55)}

# --- CAM machines -----------------------------------------------------------------------------------------------------
const MACHINES: Array[String] = ["laser", "printer"]
const CAM_PARTS := {"laser": ["laser head", "beam", "sheet", "bed", "extractor"],
	"printer": ["spool", "filament", "nozzle", "layers", "bed"]}
const LASER_AT := {"laser head": Vector2(0.42, 0.2), "beam": Vector2(0.42, 0.4), "sheet": Vector2(0.62, 0.6),
	"bed": Vector2(0.24, 0.77), "extractor": Vector2(0.92, 0.42)}
const MAX_LAYERS := 12
const PLA := Color("f08a3c")

# --- Fabrics ----------------------------------------------------------------------------------------------------------
const FABRICS: Array[String] = ["breathable", "reflective", "smart"]
const FABRIC_PARTS := {"breathable": ["rain", "outer fabric", "membrane", "lining", "water vapour"],
	"reflective": ["headlight", "light beam", "reflective strip", "glass beads"],
	"smart": ["battery", "switch", "LED", "conductive thread"]}
const FABRIC_AT := {
	"breathable": {"rain": Vector2(0.25, 0.2), "outer fabric": Vector2(0.3, 0.46), "membrane": Vector2(0.3, 0.56),
		"lining": Vector2(0.3, 0.66), "water vapour": Vector2(0.83, 0.26)},
	"reflective": {"headlight": Vector2(0.21, 0.6), "light beam": Vector2(0.42, 0.5),
		"reflective strip": Vector2(0.69, 0.75), "glass beads": Vector2(0.86, 0.45)},
	"smart": {"battery": Vector2(0.2, 0.5), "switch": Vector2(0.45, 0.28), "LED": Vector2(0.76, 0.28),
		"conductive thread": Vector2(0.45, 0.74)}}

# --- The eco home -----------------------------------------------------------------------------------------------------
const ECO_PARTS: Array[String] = ["solar panels", "insulation", "double glazing", "heat pump", "rain butt", "LED light"]
const ECO_AT := {"solar panels": Vector2(0.33, 0.24), "insulation": Vector2(0.56, 0.4), "double glazing": Vector2(0.33,
	0.64), "heat pump": Vector2(0.865, 0.82), "rain butt": Vector2(0.09, 0.81), "LED light": Vector2(0.63, 0.57)}


# --- The rules the pictures draw by (the lessons teach them; tests check them) ----------------------------------------

## The zone a pulse of `bpm` is in for a maximum heart rate of `top`: "rest" below 50%, then ZONES by ZONE_FROM.
static func zone_of(top: int, bpm: float) -> String:
	var share := bpm / float(top)
	if share < 0.5:
		return "rest"
	for z: String in ZONES:
		if share < float(ZONE_TO[z]) or z == "maximum":
			return z
	return "maximum"


## A zone's edge in beats a minute: `share` of the maximum, to the nearest beat.
static func zone_bpm(top: int, share: float) -> int:
	return roundi(top * share)


## Minutes after midnight of "HH:MM" on the quarter hour; -1 when it is not a time.
static func minutes_of(t: Variant) -> int:
	if not t is String:
		return -1
	var parts := str(t).split(":")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int() or parts[1].length() != 2:
		return -1
	var h := int(parts[0])
	var m := int(parts[1])
	if h < 0 or h > 23 or not m in [0, 15, 30, 45]:
		return -1
	return h * 60 + m


## Hours from falling asleep to waking, across midnight: "22:30" to "07:00" is 8.5.
static func sleep_hours(sleep: String, wake: String) -> float:
	return float((minutes_of(wake) - minutes_of(sleep) + 1440) % 1440) / 60.0


## The hours as the dial writes them: "9 hours", "8.5 hours".
static func hours_text(h: float) -> String:
	return ("%d hours" % int(h)) if is_equal_approx(h, roundf(h)) else ("%s hours" % String.num(h, 2))


## A resistor's value in ohms: the first two bands' digits, then the third band's number of zeros.
static func resistor_ohms(bands: Array) -> int:
	return (COLOURS.find(str(bands[0])) * 10 + COLOURS.find(str(bands[1]))) * int(pow(10, COLOURS.find(str(bands[2]))))


## Whether current flows round a loop of `parts`: no open switch, no LED the wrong way round, and every push switch,
## pad, reed or tilt switch closed (`active`).
static func conducts(parts: Array, active: bool) -> bool:
	for p: Variant in parts:
		var s := str(p)
		if s == "switch" or s == "led_back" or (SENSING.has(s) and not active):
			return false
	return true


## Whether the board's LED at column x, row y (0-4 from the top left) is lit.
static func led_at(leds: Array, x: int, y: int) -> bool:
	return y >= 0 and y < leds.size() and x >= 0 and x < str(leds[y]).length() and str(leds[y])[x] == "1"


## Where the part named `label` is drawn on a picture of `size` (a SchoolPicture's whole size), for a label's line;
## (-1, -1) when the picture has no such part.
static func part_at(p: Dictionary, label: String, size: Vector2) -> Vector2:
	var none := Vector2(-1, -1)
	var kind := str(p.get("kind", ""))
	if not RATIOS.has(kind):
		return none
	var a := _diagram_box(p, _rect(size))
	var anchors := _anchors(p, a)
	return anchors.get(label, none)


## Each named part's place in the diagram box `a`.
static func _anchors(p: Dictionary, a: Rect2) -> Dictionary:
	var out := {}
	match str(p.get("kind", "")):
		"advert":
			for t: Variant in p.get("tricks", []):
				out[str(TRICK_NAMES.get(str(t), str(t)))] = _at(a, TRICK_AT[str(t)].x, TRICK_AT[str(t)].y
					+ float(TRICK_EDGE[str(t)]))
		"micro_board":
			for part: String in BOARD_PARTS:
				out[part] = _at(a, BOARD_AT[part].x, BOARD_AT[part].y)
		"exploded":
			for part: String in TORCH_PARTS:
				out[part] = _at(a, TORCH_AT[part].x, TORCH_AT[part].y)
		"cam_process":
			if str(p.get("machine", "")) == "laser":
				for part: String in CAM_PARTS.laser:
					out[part] = _at(a, LASER_AT[part].x, LASER_AT[part].y)
			else:
				var g := _printer_geo(a, int(p.get("layers", 6)))
				out = {"spool": g.spool, "filament": g.filament, "nozzle": g.nozzle, "layers": g.layers, "bed": g.bed}
		"fabric_section":
			var at: Dictionary = FABRIC_AT.get(str(p.get("type", "")), {})
			for part: String in at:
				out[part] = _at(a, at[part].x, at[part].y)
		"eco_home":
			for part: String in _features(p):
				out[part] = _at(a, ECO_AT[part].x, ECO_AT[part].y)
	return out


static func _features(p: Dictionary) -> Array:
	return p.get("features", ECO_PARTS) as Array


## A diagram's box in `r`: its label bands taken off, then its shape (RATIOS) centred.
static func _diagram_box(p: Dictionary, r: Rect2) -> Rect2:
	var fs := _fs(r)
	return _fit_box(_inner(r, fs, bool(p.get("labels", false))), float(RATIOS.get(str(p.get("kind", "")), 2.0)))


# --- Checks -------------------------------------------------------------------------------------------------------------

## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	var kind := str(p.get("kind", ""))
	match kind:
		"hr_zones":
			return _zones_problem(p)
		"shot_paths":
			var sport := str(p.get("sport", ""))
			if not SPORTS.has(sport):
				return "shot_paths: sport is one of %s" % [SPORTS]
			var why := _list_problem(p, "shots", SHOTS[sport], 4)
			if why != "":
				return "shot_paths: " + why
			if p.has("mark") and not (p.shots as Array).has(p.mark):
				return "shot_paths: mark is one of its shots"
			return _flags_problem(p, ["tags"])
		"sleep_dial":
			for key: String in ["sleep", "wake"] + (["screens"] if p.has("screens") else []):
				if minutes_of(p.get(key)) < 0:
					return "sleep_dial: %s is a time HH:MM on the quarter hour" % key
			var h := sleep_hours(str(p.sleep), str(p.wake))
			if h < MIN_SLEEP or h > MAX_SLEEP:
				return "sleep_dial: %d-%d hours of sleep" % [int(MIN_SLEEP), int(MAX_SLEEP)]
			return _flags_problem(p, ["hours", "hide"])
		"photo_edit":
			var why := _list_problem(p, "edits", EDITS, 6)
			if why != "":
				return "photo_edit: " + why
			return _flags_problem(p, ["tags", "names", "before"])
		"advert":
			if not PRODUCTS.has(str(p.get("product", ""))):
				return "advert: product is one of %s" % [PRODUCTS]
			var why := _list_problem(p, "tricks", TRICKS, 6)
			if why != "":
				return "advert: " + why
			for key: String in ["mark", "hide"]:
				if p.has(key) and not (p.tricks as Array).has(p[key]):
					return "advert: %s is one of its tricks" % key
			return _flags_problem(p, ["labels", "words"])
		"influence_map":
			if not p.get("centre") is String or str(p.centre).strip_edges() == "" or str(p.centre).length() > MAX_INFLUENCE:
				return "influence_map: a centre of 1-%d letters" % MAX_INFLUENCE
			var list: Variant = p.get("influences")
			if not list is Array or (list as Array).size() < 2 or (list as Array).size() > MAX_INFLUENCES:
				return "influence_map: 2-%d influences" % MAX_INFLUENCES
			for t: Variant in list:
				if not t is String or str(t).strip_edges() == "" or str(t).length() > MAX_INFLUENCE:
					return "influence_map: an influence is 1-%d letters" % MAX_INFLUENCE
			return _index_problem(p, (list as Array).size())
		"ref_signal":
			if not SIGNALS.has(str(p.get("signal", ""))):
				return "ref_signal: signal is one of %s" % [SIGNALS]
			if p.has("card") and (str(p.signal) != "card" or not str(p.card) in ["yellow", "red"]):
				return "ref_signal: a card is yellow or red, with the card signal"
			return _flags_problem(p, ["name"])
		"schematic":
			return _schematic_problem(p)
		"resistor":
			var bands: Variant = p.get("bands")
			if not bands is Array or not (bands as Array).size() in [3, 4]:
				return "resistor: 3 or 4 bands"
			for i in (bands as Array).size():
				var b := str(bands[i])
				if i < 3 and not COLOURS.has(b):
					return "resistor: the first three bands are digit colours"
				if i == 3 and not TOLERANCES.has(b):
					return "resistor: the fourth band is gold or silver"
			if str(bands[0]) == "black":
				return "resistor: the first band is never black"
			if p.has("hide") and (not _whole(p.hide) or int(p.hide) < 0 or int(p.hide) >= (bands as Array).size()):
				return "resistor: hide is a band's index"
			return _flags_problem(p, ["names", "value"])
		"micro_board":
			if p.has("leds"):
				var leds: Variant = p.leds
				if not leds is Array or (leds as Array).size() != 5:
					return "micro_board: leds is five rows"
				for row: Variant in leds:
					if not row is String or str(row).length() != 5:
						return "micro_board: each row is five of 0 or 1"
					for ch in str(row):
						if ch != "0" and ch != "1":
							return "micro_board: each row is five of 0 or 1"
			if p.has("pressed") and not str(p.pressed) in ["A", "B", "AB"]:
				return "micro_board: pressed is A, B or AB"
			return _parts_problem(p, BOARD_PARTS, ["sound", "grid"])
		"exploded":
			if not PRODUCT_VIEWS.has(str(p.get("product", ""))):
				return "exploded: product is one of %s" % [PRODUCT_VIEWS]
			return _parts_problem(p, TORCH_PARTS)
		"cam_process":
			var machine := str(p.get("machine", ""))
			if not MACHINES.has(machine):
				return "cam_process: machine is one of %s" % [MACHINES]
			if p.has("layers") and (machine != "printer" or not _whole(p.layers) or int(p.layers) < 2
					or int(p.layers) > MAX_LAYERS):
				return "cam_process: a printer's layers are 2-%d" % MAX_LAYERS
			return _parts_problem(p, CAM_PARTS[machine])
		"fabric_section":
			var type := str(p.get("type", ""))
			if not FABRICS.has(type):
				return "fabric_section: type is one of %s" % [FABRICS]
			return _parts_problem(p, FABRIC_PARTS[type])
		"eco_home":
			if p.has("features"):
				var why := _list_problem(p, "features", ECO_PARTS, 6)
				if why != "":
					return "eco_home: " + why
			return _parts_problem(p, _features(p))
	return "unknown picture kind '%s'" % kind


static func _zones_problem(p: Dictionary) -> String:
	if not _whole(p.get("max")) or int(p.max) < 150 or int(p.max) > 220:
		return "hr_zones: max is 150-220 whole beats a minute"
	if p.has("trace"):
		var trace: Variant = p.trace
		if not trace is Array or (trace as Array).size() < 2 or (trace as Array).size() > MAX_TRACE:
			return "hr_zones: a trace of 2-%d points" % MAX_TRACE
		for pt: Variant in trace:
			if not pt is Array or (pt as Array).size() != 2 or not pt[0] is String or str(pt[0]).length() > MAX_TRACE_LABEL \
					or not _number(pt[1]) or float(pt[1]) < 30.0 or float(pt[1]) > 230.0:
				return "hr_zones: each point is [label (%d letters), 30-230 bpm]" % MAX_TRACE_LABEL
	if p.has("point") and (not p.has("trace") or not _whole(p.point) or int(p.point) < 0
			or int(p.point) >= (p.trace as Array).size()):
		return "hr_zones: point is a trace point's index"
	for key: String in ["mark", "hide"]:
		if p.has(key) and not ZONES.has(str(p[key])):
			return "hr_zones: %s is one of %s" % [key, ZONES]
	return _flags_problem(p, ["names"])


static func _schematic_problem(p: Dictionary) -> String:
	var parts: Variant = p.get("parts")
	if not parts is Array or (parts as Array).size() < 2 or (parts as Array).size() > MAX_PARTS:
		return "schematic: 2-%d parts" % MAX_PARTS
	var power := 0
	for s: Variant in parts:
		if not SYMS.has(str(s)):
			return "schematic: a part is one of %s" % [SYMS]
		if str(s) in ["cell", "battery"]:
			power += 1
	if power != 1:
		return "schematic: one cell or battery"
	if p.has("values"):
		var values: Variant = p.values
		if not values is Array or (values as Array).size() != (parts as Array).size():
			return "schematic: a value for each part"
		for v: Variant in values:
			if not v is String or str(v).length() > MAX_VALUE:
				return "schematic: a value is up to %d letters" % MAX_VALUE
	var why := _index_problem(p, (parts as Array).size())
	if why != "":
		return why
	return _flags_problem(p, ["active", "lit", "names"])


## A list under `key` of 1-`most` known names, each once.
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


static func _index_problem(p: Dictionary, n: int) -> String:
	for key: String in ["mark", "hide"]:
		if p.has(key) and (not _whole(p[key]) or int(p[key]) < 0 or int(p[key]) >= n):
			return "%s: %s is an index" % [p.kind, key]
	return ""


static func _flags_problem(p: Dictionary, keys: Array) -> String:
	for key: String in keys:
		if p.has(key) and not p[key] is bool:
			return "%s: %s is true or false" % [p.kind, key]
	return ""


## `labels` (and `more` flags) true or false; `mark` and `hide` parts of `parts`.
static func _parts_problem(p: Dictionary, parts: Array, more: Array = []) -> String:
	for key: String in ["mark", "hide"]:
		if p.has(key) and not parts.has(str(p[key])):
			return "%s: %s is one of %s" % [p.kind, key, parts]
	return _flags_problem(p, ["labels"] + more)


static func _whole(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT and is_equal_approx(float(v), roundf(float(v)))


static func _number(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT]


# --- Drawing ------------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"hr_zones":
			_draw_zones(pic, font, r, d)
		"shot_paths":
			_draw_shots(pic, font, r, d)
		"sleep_dial":
			_draw_sleep(pic, font, r, d)
		"photo_edit":
			_draw_photos(pic, font, r, d)
		"advert":
			_draw_advert(pic, font, r, d)
		"influence_map":
			_draw_influences(pic, font, r, d)
		"ref_signal":
			_draw_signal(pic, font, r, d)
		"schematic":
			_draw_schematic(pic, font, r, d)
		"resistor":
			_draw_resistor(pic, font, r, d)
		"micro_board":
			_draw_board(pic, font, r, d)
		"exploded":
			_draw_exploded(pic, font, r, d)
		"cam_process":
			_draw_cam(pic, font, r, d)
		"fabric_section":
			_draw_fabric(pic, font, r, d)
		"eco_home":
			_draw_eco_home(pic, font, r, d)


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


static func _arrow(ci: CanvasItem, from: Vector2, to: Vector2, colour: Color, width: float) -> void:
	if from.distance_to(to) < 1.0:
		return
	var dir := (to - from).normalized()
	var head := maxf(7.0, width * 3.0)
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


static func _pts(a: Rect2, fracs: Array) -> Array:
	var out: Array = []
	for f: Vector2 in fracs:
		out.append(_at(a, f.x, f.y))
	return out


## The part of the unit box `a` from (x0, y0) to (x1, y1), as a rectangle.
static func _sub(a: Rect2, x0: float, y0: float, x1: float, y1: float) -> Rect2:
	return Rect2(_at(a, x0, y0), Vector2(a.size.x * (x1 - x0), a.size.y * (y1 - y0)))


## The widest box of aspect `ratio` (width ÷ height) centred in `r`.
static func _fit_box(r: Rect2, ratio: float) -> Rect2:
	var w := minf(r.size.x, r.size.y * ratio)
	var h := w / ratio
	return Rect2(r.get_center() - Vector2(w, h) * 0.5, Vector2(w, h))


## Text in a box, on two lines when one is too wide.
static func _text_in(ci: CanvasItem, font: Font, box: Rect2, text: String, fs: int, colour: Color = INK) -> void:
	var room := box.size.x - 8.0
	if _text_w(font, text, fs) <= room or not text.contains(" "):
		_say(ci, font, box.get_center(), text, _fit(font, text, fs, room), colour, false)
		return
	var cut := text.rfind(" ", text.length() / 2 + 2)
	if cut <= 0:
		cut = text.find(" ")
	var lines := [text.substr(0, cut), text.substr(cut + 1)]
	var f := mini(_fit(font, lines[0], fs, room), _fit(font, lines[1], fs, room))
	f = mini(f, int(box.size.y / 2.4))
	_say(ci, font, box.get_center() - Vector2(0, f * 0.6), lines[0], maxi(f, 7), colour, false)
	_say(ci, font, box.get_center() + Vector2(0, f * 0.6), lines[1], maxi(f, 7), colour, false)


## A point `t` (0-1) along the curve from p0 pulled towards p1 to p2.
static func _bez(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	return p0 * (1.0 - t) * (1.0 - t) + p1 * 2.0 * t * (1.0 - t) + p2 * t * t


## A simple stick person standing on `foot` (the ground point under them), `h` tall, with arms to `hands` (two points
## from the shoulders; empty: hanging down).
static func _person(ci: CanvasItem, foot: Vector2, h: float, hands: Array, colour: Color = INK) -> Dictionary:
	var w := clampf(h * 0.04, 2.0, 6.0)
	var hip := foot + Vector2(0, -h * 0.45)
	var neck := foot + Vector2(0, -h * 0.78)
	var head := neck + Vector2(0, -h * 0.11)
	ci.draw_line(hip, foot + Vector2(-h * 0.1, 0), colour, w, true)
	ci.draw_line(hip, foot + Vector2(h * 0.1, 0), colour, w, true)
	ci.draw_line(hip, neck, colour, w * 1.4, true)
	var shoulder := neck + Vector2(0, h * 0.04)
	var hl: Vector2 = hands[0] if hands.size() > 0 else shoulder + Vector2(-h * 0.12, h * 0.3)
	var hr: Vector2 = hands[1] if hands.size() > 1 else shoulder + Vector2(h * 0.12, h * 0.3)
	ci.draw_line(shoulder, hl, colour, w, true)
	ci.draw_line(shoulder, hr, colour, w, true)
	ci.draw_circle(head, h * 0.1, SKIN)
	ci.draw_arc(head, h * 0.1, 0.0, TAU, 20, colour, maxf(1.5, w * 0.6))
	return {"head": head, "shoulder": shoulder, "hip": hip, "left": hl, "right": hr}


# --- Heart-rate zones ---------------------------------------------------------------------------------------------------

static func _draw_zones(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var top := int(d.max)
	var trace: Array = d.get("trace", [])
	var names := bool(d.get("names", true))
	var lo := top * 0.4
	var left := r.position.x + _text_w(font, str(top), fs - 1) + 10.0
	var right := r.end.x
	if names:
		right -= minf(r.size.x * 0.36, _text_w(font, "anaerobic 80-90%", fs - 1) + 14.0)
	var y_top := r.position.y + fs * 0.7
	var y_bottom := r.end.y - (fs * 1.6 if not trace.is_empty() else fs * 0.5)
	var y_of := func(bpm: float) -> float:
		return y_bottom - (clampf(bpm, lo, top) - lo) / (top - lo) * (y_bottom - y_top)
	var y_half: float = y_of.call(top * 0.5)
	ci.draw_rect(Rect2(left, y_half, right - left, y_bottom - y_half), PALE)
	for z: String in ZONES:
		var y0: float = y_of.call(top * float(ZONE_TO[z]))
		var y1: float = y_of.call(top * float(ZONE_FROM[z]))
		var band := Rect2(left, y0, r.end.x - left, y1 - y0) if names else Rect2(left, y0, right - left, y1 - y0)
		ci.draw_rect(band, ZONE_COLOURS[z])
		if d.has("mark") and str(d.mark) == z:
			ci.draw_rect(band.grow(-1.5), ORANGE, false, 3.0)
		if names:
			var said := _label_of(d, z, "%s %d-%d%%" % [z, int(float(ZONE_FROM[z]) * 100), int(float(ZONE_TO[z]) * 100)])
			var room := r.end.x - right - 6.0
			_say_from(ci, font, Vector2(right + 4.0, (y0 + y1) * 0.5), str(said[0]),
				mini(_fit(font, str(said[0]), fs - 1, room), int((y1 - y0) * 0.8)), said[1], false, false)
	for share: float in [0.5, 0.6, 0.8, 0.9, 1.0]:
		var y: float = y_of.call(top * share)
		ci.draw_line(Vector2(left - 4.0, y), Vector2(right, y), INK, 1.0)
		_say_from(ci, font, Vector2(left - 6.0, y), str(zone_bpm(top, share)), fs - 1, INK, true, false)
	ci.draw_line(Vector2(left, y_top - 2.0), Vector2(left, y_bottom), INK, 2.0)
	ci.draw_line(Vector2(left, y_bottom), Vector2(right, y_bottom), INK, 2.0)
	if trace.is_empty():
		return
	var n := trace.size()
	var slot := (right - left) / n
	var pts := PackedVector2Array()
	for i in n:
		pts.append(Vector2(left + slot * (i + 0.5), y_of.call(float(trace[i][1]))))
	ci.draw_polyline(pts, RED, 3.0, true)
	for i in n:
		var big := d.has("point") and int(d.point) == i
		ci.draw_circle(pts[i], 6.0 if big else 3.5, ORANGE if big else RED)
		if big:
			ci.draw_arc(pts[i], 7.0, 0.0, TAU, 20, INK, 1.5)
		var label := str(trace[i][0])
		_say(ci, font, Vector2(pts[i].x, y_bottom + fs * 0.8), label, _fit(font, label, fs - 1, slot - 2.0), INK, false)


# --- Shots ------------------------------------------------------------------------------------------------------------

static func _draw_shots(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var sport := str(d.sport)
	var court := Rect2(r.position.x + 4.0, r.position.y + fs * 0.4, r.size.x - 8.0, r.size.y - fs * 1.0)
	var floor_y := court.end.y
	var to_px := func(v: Vector2) -> Vector2:
		return Vector2(court.position.x + court.size.x * v.x, floor_y - court.size.y * 0.85 * v.y)
	ci.draw_rect(Rect2(court.position.x, floor_y, court.size.x, 4.0), Color("3d8b5f") if sport == "badminton"
		else Color("3f72b5"))
	ci.draw_line(Vector2(court.position.x, floor_y), Vector2(court.end.x, floor_y), INK, 2.0)
	var net_top: Vector2 = to_px.call(Vector2(0.5, float(NET_HEIGHT[sport])))
	ci.draw_line(Vector2(net_top.x, floor_y), net_top, INK, 3.0)
	var mesh := Rect2(net_top.x - 4.0, net_top.y, 8.0, (floor_y - net_top.y) * (0.45 if sport == "badminton" else 0.95))
	ci.draw_rect(mesh, Color(1, 1, 1, 0.9))
	for k in 4:
		var my := mesh.position.y + mesh.size.y * (k + 1) / 5.0
		ci.draw_line(Vector2(mesh.position.x, my), Vector2(mesh.end.x, my), GREY, 1.0)
	ci.draw_rect(mesh, INK, false, 1.5)
	ci.draw_line(net_top + Vector2(-6, 0), net_top + Vector2(6, 0), Color.WHITE, 3.0)
	var shots: Array = d.shots
	var first_path: Array = PATHS[sport][str(shots[0])]
	var hit: Vector2 = to_px.call(first_path[0])
	var foot: Vector2 = to_px.call(Vector2(0.05, 0.0))
	var h := court.size.y * 0.6
	var grip := hit + Vector2(-h * 0.08, h * 0.16)
	var body := _person(ci, foot, h, [foot + Vector2(-h * 0.12, -h * 0.5), grip])
	ci.draw_line(grip, hit, Color("6b4a2b"), 3.0, true)
	ci.draw_arc(hit, maxf(4.0, h * 0.06), 0.0, TAU, 16, INK, 2.0)
	var tags := bool(d.get("tags", false))
	var letters := "ABCD"
	for i in shots.size():
		var shot := str(shots[i])
		var path: Array = PATHS[sport][shot]
		var colour: Color = ORANGE if d.has("mark") and str(d.mark) == shot else SHOT_COLOURS[i % SHOT_COLOURS.size()]
		var pts := PackedVector2Array()
		for k in 25:
			pts.append(to_px.call(_bez(path[0], path[1], path[2], k / 24.0)))
		for k in range(0, 24, 2):   # a dashed flight
			ci.draw_line(pts[k], pts[k + 1], colour, 3.0, true)
		_arrow(ci, pts[22], pts[24], colour, 3.0)
		ci.draw_circle(pts[0], 4.0, Color.WHITE)
		ci.draw_arc(pts[0], 4.0, 0.0, TAU, 12, colour, 2.0)
		var land := pts[24]
		var row := 0   # labels of landings close together are stacked
		for j in i:
			var other: Vector2 = to_px.call((PATHS[sport][str(shots[j])] as Array)[2])
			if absf(other.x - land.x) < (fs * 1.6 if tags else _text_w(font, str(SHOT_NAMES[shot]), fs) * 0.9 + 10.0):
				row += 1
		if tags:
			var c := land + Vector2(0, -fs * (0.9 + 1.5 * row))
			ci.draw_circle(c, fs * 0.7, Color.WHITE)
			ci.draw_arc(c, fs * 0.7, 0.0, TAU, 20, colour, 2.5)
			_say(ci, font, c, letters[i], fs, colour, false)
		else:   # the name above its landing
			var name := str(SHOT_NAMES[shot])
			var at := Vector2(land.x, land.y - fs * (1.0 + 1.25 * row))
			at.x = clampf(at.x, r.position.x + _text_w(font, name, fs) * 0.5, r.end.x - _text_w(font, name, fs) * 0.5)
			_say(ci, font, at, name, fs, colour)


# --- Sleep ------------------------------------------------------------------------------------------------------------

static func _angle(minutes: int) -> float:
	return -PI * 0.5 + TAU * minutes / 1440.0


static func _draw_sleep(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var c := r.get_center()
	var rad := minf(r.size.y * 0.5 - fs * 1.2, r.size.x * 0.5 - fs * 3.2)
	rad = maxf(rad, 20.0)
	ci.draw_circle(c, rad, Color("fffaf0"))
	var a0 := _angle(minutes_of(d.sleep))
	var span := TAU * sleep_hours(str(d.sleep), str(d.wake)) / 24.0
	ci.draw_arc(c, rad * 0.86, a0, a0 + span, 48, NIGHT, rad * 0.22, true)
	ci.draw_arc(c, rad, 0.0, TAU, 48, INK, 2.5, true)
	for hour in 24:
		var a := _angle(hour * 60)
		var dir := Vector2(cos(a), sin(a))
		var long := hour % 3 == 0
		ci.draw_line(c + dir * rad * (0.9 if long else 0.94), c + dir * rad, INK, 2.0 if long else 1.0)
		if hour % 3 == 0:
			_say(ci, font, c + dir * rad * 0.62, str(hour), maxi(fs - 2, 7), INK, false)
	for key: String in ["sleep", "wake"]:
		var a := _angle(minutes_of(d[key]))
		var dir := Vector2(cos(a), sin(a))
		ci.draw_circle(c + dir * rad * 0.86, rad * 0.09, Color("f7c531") if key == "wake" else Color("dfe6ff"))
		var t := str(d[key])
		var at := c + dir * (rad + fs * 0.4)
		_say_from(ci, font, at, t, fs - 1, INK, dir.x < 0.0)
	if d.has("screens"):   # a phone switched off, just inside the rim at its time, and a line saying when
		var a := _angle(minutes_of(d.screens))
		var dir := Vector2(cos(a), sin(a))
		var at := c + dir * rad * 0.86
		var ph := Rect2(at - Vector2(rad * 0.06, rad * 0.1), Vector2(rad * 0.12, rad * 0.2))
		_box(ci, ph, Color("cfd6e6"), INK, 3, 2)
		ci.draw_line(ph.position, ph.end, RED, 2.0)
		var words := "phone off %s" % str(d.screens)
		_say_from(ci, font, Vector2(r.position.x + 2.0, r.end.y - fs * 0.6), words, _fit(font, words, fs - 1,
			r.size.x * 0.5 - rad - 4.0 + r.size.x * 0.5 - 4.0), RED)
	if bool(d.get("hours", true)):
		var words := "?" if bool(d.get("hide", false)) else hours_text(sleep_hours(str(d.sleep), str(d.wake)))
		_say(ci, font, c, words, _fit(font, words, fs, rad * 1.1), ORANGE if bool(d.get("hide", false)) else NIGHT)


# --- Photo edits --------------------------------------------------------------------------------------------------------

static func _draw_photos(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var edits: Array = d.edits
	var before := bool(d.get("before", true))
	var names := bool(d.get("names", false))
	var n := 2 if before else 1
	var top := r.position.y + fs * 1.3
	var bottom := r.end.y - (fs * 1.5 if names else 0.0)
	var h := bottom - top
	var w := minf(h * 0.82, (r.size.x - 12.0 * n) / n)
	h = w / 0.82
	var gap := (r.size.x - w * n) / (n + 1)
	var after: Rect2
	for i in n:
		var box := Rect2(r.position.x + gap + (w + gap) * i, top, w, h)
		var is_after := i == n - 1
		_portrait(ci, box, edits if is_after else [])
		ci.draw_rect(box, INK, false, 2.0)
		_say(ci, font, Vector2(box.get_center().x, r.position.y + fs * 0.6), "after" if is_after else "before", fs,
			ORANGE if is_after else INK, false)
		if is_after:
			after = box
	if bool(d.get("tags", false)):
		for k in edits.size():
			var at := _edit_at(after, str(edits[k]))
			ci.draw_circle(at, fs * 0.6, Color.WHITE)
			ci.draw_arc(at, fs * 0.6, 0.0, TAU, 20, ORANGE, 2.5)
			_say(ci, font, at, str(k + 1), fs - 2, INK, false)
	if names:
		var parts: Array = []
		for k in edits.size():
			parts.append("%d %s" % [k + 1, EDIT_NAMES[str(edits[k])]])
		var line := "   ".join(parts)
		_say(ci, font, Vector2(r.get_center().x, r.end.y - fs * 0.6), line, _fit(font, line, fs - 1, r.size.x - 4.0))


## Where each edit shows on a photo `box` (its tag).
static func _edit_at(box: Rect2, edit: String) -> Vector2:
	match edit:
		"light":
			return _at(box, 0.15, 0.1)
		"filter":
			return _at(box, 0.85, 0.1)
		"smooth":
			return _at(box, 0.31, 0.56)
		"eyes":
			return _at(box, 0.62, 0.42)
		"teeth":
			return _at(box, 0.5, 0.67)
	return _at(box, 0.85, 0.32)


## A smiling portrait in `box`, with `edits` applied.
static func _portrait(ci: CanvasItem, box: Rect2, edits: Array) -> void:
	var lift := 0.22 if edits.has("light") else 0.0
	var tone := func(c: Color) -> Color:
		return c.lerp(Color.WHITE, lift)
	if edits.has("background"):
		ci.draw_rect(Rect2(box.position, Vector2(box.size.x, box.size.y * 0.55)), tone.call(Color("f6a96b")))
		ci.draw_rect(Rect2(_at(box, 0, 0.35), Vector2(box.size.x, box.size.y * 0.2)), tone.call(Color("f7c59f")))
		ci.draw_circle(_at(box, 0.82, 0.3), box.size.x * 0.08, tone.call(Color("ffe08a")))
		ci.draw_rect(Rect2(_at(box, 0, 0.55), Vector2(box.size.x, box.size.y * 0.45)), tone.call(Color("4f9bd9")))
	else:
		ci.draw_rect(box, tone.call(Color("c9cfd8")))
		ci.draw_rect(_sub(box, 0.68, 0.12, 0.95, 1.0), tone.call(Color("a9b1bd")))
		ci.draw_line(_at(box, 0.68, 0.12), _at(box, 0.68, 1.0), tone.call(Color("8a93a1")), 2.0)
	var head := _at(box, 0.5, 0.5)
	var hr := box.size.x * 0.24
	_poly(ci, _pts(box, [Vector2(0.14, 1.0), Vector2(0.24, 0.82), Vector2(0.76, 0.82), Vector2(0.86, 1.0)]),
		tone.call(Color("3a7be8")), INK, 1.5)
	ci.draw_rect(_sub(box, 0.44, 0.7, 0.56, 0.84), tone.call(SKIN))
	ci.draw_circle(head, hr, tone.call(SKIN))
	ci.draw_arc(head, hr, 0.0, TAU, 32, INK, 1.5)
	var hair := PackedVector2Array()
	for k in 13:
		var a := PI + PI * k / 12.0
		hair.append(head + Vector2(cos(a), sin(a) * 0.85) * hr * 1.05)
	hair.append(head + Vector2(hr * 0.9, -hr * 0.2))
	hair.append(head + Vector2(-hr * 0.9, -hr * 0.2))
	ci.draw_colored_polygon(hair, tone.call(HAIR))
	var eye := hr * (0.2 if edits.has("eyes") else 0.14)
	for side: float in [-1.0, 1.0]:
		var e := head + Vector2(side * hr * 0.4, -hr * 0.08)
		ci.draw_circle(e, eye, Color.WHITE)
		ci.draw_circle(e, eye * 0.55, Color("3b2a1a"))
		ci.draw_arc(e, eye, 0.0, TAU, 16, INK, 1.0)
	if not edits.has("smooth"):
		for s: Vector2 in [Vector2(-0.55, 0.22), Vector2(-0.42, 0.34), Vector2(0.5, 0.28)]:
			ci.draw_circle(head + s * hr, hr * 0.05, Color("c0605a"))
	else:
		for side: float in [-1.0, 1.0]:
			ci.draw_circle(head + Vector2(side * hr * 0.55, hr * 0.25), hr * 0.13, Color(1.0, 0.6, 0.6, 0.35))
	var mouth := head + Vector2(0, hr * 0.38)
	var smile := PackedVector2Array()
	for k in 9:
		var a := PI * k / 8.0
		smile.append(mouth + Vector2(cos(a) * hr * 0.38, sin(a) * hr * 0.24))
	ci.draw_colored_polygon(smile, Color.WHITE if edits.has("teeth") else Color("e9dcb0"))
	smile.append(smile[0])
	ci.draw_polyline(smile, INK, 1.5, true)
	if edits.has("filter"):
		ci.draw_rect(box, Color(1.0, 0.55, 0.15, 0.18))


# --- Adverts ----------------------------------------------------------------------------------------------------------

static func _draw_advert(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var labels := bool(d.get("labels", false))
	var a := _diagram_box(d, r)
	var words := bool(d.get("words", true))
	_box(ci, a, Color("fff3b0"), INK, 8, 2)
	_product(ci, a, str(d.product))
	var tricks: Array = d.tricks
	for t: Variant in tricks:
		var at := _at(a, TRICK_AT[str(t)].x, TRICK_AT[str(t)].y)
		var u := a.size.y
		match str(t):
			"star":
				var foot := at + Vector2(0, u * 0.3)
				var body := _person(ci, foot, u * 0.5, [foot + Vector2(-u * 0.1, -u * 0.22), foot + Vector2(u * 0.1, -u * 0.48)],
					Color("8e44ad"))
				ci.draw_circle((body.shoulder as Vector2) + Vector2(0, u * 0.07), u * 0.035, GOLD)
				if words:
					_bubble(ci, font, at + Vector2(u * 0.05, -u * 0.33), str(TRICK_WORDS.star), fs - 2)
			"bandwagon":
				var band := Rect2(at - Vector2(a.size.x * 0.24, u * 0.08), Vector2(a.size.x * 0.48, u * 0.16))
				_box(ci, band, Color("d9433b"), INK, 4, 2)
				if words:
					_say(ci, font, band.get_center(), str(TRICK_WORDS.bandwagon), _fit(font, str(TRICK_WORDS.bandwagon), fs,
						band.size.x - 8.0), Color.WHITE, false)
			"free_gift":
				var star := PackedVector2Array()
				for k in 16:
					var ang := TAU * k / 16.0
					star.append(at + Vector2(cos(ang), sin(ang)) * u * (0.17 if k % 2 == 0 else 0.12))
				ci.draw_colored_polygon(star, Color("f08a1c"))
				if words:
					_say(ci, font, at, str(TRICK_WORDS.free_gift), _fit(font, str(TRICK_WORDS.free_gift), fs - 1, u * 0.3),
						Color.WHITE, false)
			"health_claim":
				ci.draw_circle(at, u * 0.15, GREEN)
				ci.draw_arc(at, u * 0.15, 0.0, TAU, 24, INK, 2.0)
				if words:
					_text_in(ci, font, Rect2(at - Vector2(u * 0.14, u * 0.12), Vector2(u * 0.28, u * 0.24)),
						str(TRICK_WORDS.health_claim), fs - 2, Color.WHITE)
			"small_print":
				var tiny := maxi(7, int(fs * 0.5))
				_say(ci, font, at, str(TRICK_WORDS.small_print) if words else "...........................", tiny,
					Color("6b6b6b"), false)
			"ad_label":
				var tag := Rect2(at - Vector2(u * 0.09, u * 0.06), Vector2(u * 0.18, u * 0.12))
				_box(ci, tag, Color.WHITE, INK, 3, 1)
				_say(ci, font, tag.get_center(), "#ad", _fit(font, "#ad", fs - 1, tag.size.x - 4.0), INK, false)
		if d.has("mark") and str(d.mark) == str(t):
			ci.draw_arc(at, u * 0.2, 0.0, TAU, 32, ORANGE, 3.5)
	if labels:   # the labels name the tricks; mark and hide name them by their ids
		var dd := d.duplicate()
		for key: String in ["mark", "hide"]:
			if d.has(key):
				dd[key] = TRICK_NAMES[str(d[key])]
		_label_parts(ci, font, r, dd, _anchors(d, a), fs)


## A speech bubble with `text` over `c`.
static func _bubble(ci: CanvasItem, font: Font, c: Vector2, text: String, fs: int) -> void:
	var w := _text_w(font, text, fs) + 12.0
	var box := Rect2(c - Vector2(w * 0.5, fs * 0.8), Vector2(w, fs * 1.6))
	_box(ci, box, Color.WHITE, INK, 8, 1)
	_poly(ci, [box.position + Vector2(w * 0.3, box.size.y - 1.0), box.position + Vector2(w * 0.42, box.size.y - 1.0),
		box.position + Vector2(w * 0.28, box.size.y + fs * 0.5)], Color.WHITE, INK, 0.0)
	_say(ci, font, box.get_center(), text, fs, INK, false)


static func _product(ci: CanvasItem, a: Rect2, product: String) -> void:
	var c := _at(a, 0.45, 0.6)
	var u := a.size.y
	match product:
		"drink":
			var can := Rect2(c - Vector2(u * 0.12, u * 0.23), Vector2(u * 0.24, u * 0.46))
			_box(ci, can, Color("3a7be8"), INK, 10, 2)
			ci.draw_rect(Rect2(can.position + Vector2(0, can.size.y * 0.38), Vector2(can.size.x, can.size.y * 0.18)),
				Color.WHITE)
			ci.draw_rect(Rect2(can.position + Vector2(can.size.x * 0.25, -u * 0.03), Vector2(can.size.x * 0.5, u * 0.04)),
				GREY)
		"trainers":
			_poly(ci, [c + Vector2(-u * 0.34, u * 0.14), c + Vector2(-u * 0.3, -u * 0.12), c + Vector2(-u * 0.08, -u * 0.12),
				c + Vector2(u * 0.06, -u * 0.02), c + Vector2(u * 0.32, u * 0.04), c + Vector2(u * 0.36, u * 0.14)],
				Color("e0453a"), INK, 2.0)
			ci.draw_rect(Rect2(c + Vector2(-u * 0.35, u * 0.14), Vector2(u * 0.72, u * 0.06)), Color.WHITE)
			ci.draw_rect(Rect2(c + Vector2(-u * 0.35, u * 0.14), Vector2(u * 0.72, u * 0.06)), INK, false, 1.5)
		_:
			var box := Rect2(c - Vector2(u * 0.16, u * 0.24), Vector2(u * 0.32, u * 0.44))
			_box(ci, box, Color("f2c14e"), INK, 3, 2)
			ci.draw_circle(box.get_center() + Vector2(0, u * 0.06), u * 0.1, Color.WHITE)
			ci.draw_arc(box.get_center() + Vector2(0, u * 0.06), u * 0.1, 0.0, TAU, 20, INK, 1.5)
			for k in 4:
				ci.draw_circle(box.get_center() + Vector2(-u * 0.05 + k * u * 0.035, u * 0.03), u * 0.018, Color("c98b4f"))


# --- Influences -------------------------------------------------------------------------------------------------------

static func _draw_influences(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var c := r.get_center()
	var list: Array = d.influences
	var n := list.size()
	var bw := minf(r.size.x * 0.27, _text_w(font, "a long influence", fs) + 12.0)
	var bh := fs * 1.9
	var rx := r.size.x * 0.5 - bw * 0.5 - 2.0
	var ry := r.size.y * 0.5 - bh * 0.5 - 2.0
	var core := Vector2(minf(r.size.x * 0.17, _text_w(font, str(d.centre), fs) * 0.6 + 12.0), r.size.y * 0.16)
	for i in n:
		var ang := -PI * 0.5 + TAU * i / n
		var at := c + Vector2(cos(ang) * rx, sin(ang) * ry)
		var box := Rect2(at - Vector2(bw, bh) * 0.5, Vector2(bw, bh))
		var tip := c + Vector2(cos(ang) * core.x, sin(ang) * core.y)
		_arrow(ci, at - (at - c).normalized() * bh * 0.55, tip, GREY, 2.5)
		var marked := d.has("mark") and int(d.mark) == i
		var hidden := d.has("hide") and int(d.hide) == i
		_box(ci, box, SOFT if marked or hidden else Color.WHITE, ORANGE if marked or hidden else INK, 8, 2)
		_text_in(ci, font, box, "?" if hidden else str(list[i]), fs)
	ci.draw_set_transform(c, 0.0, Vector2(core.x / core.y, 1.0))
	ci.draw_circle(Vector2.ZERO, core.y, Color("ffe08a"))
	ci.draw_arc(Vector2.ZERO, core.y, 0.0, TAU, 32, INK, 2.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_say(ci, font, c, str(d.centre), _fit(font, str(d.centre), fs, core.x * 1.8), INK, false)


# --- Referee's signals ------------------------------------------------------------------------------------------------

static func _draw_signal(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var name := bool(d.get("name", false))
	var ground := r.end.y - (fs * 1.6 if name else 6.0)
	var h := (ground - r.position.y) * 0.8
	var foot := Vector2(r.get_center().x - h * 0.1, ground)
	ci.draw_line(Vector2(r.position.x + 4.0, ground), Vector2(r.end.x - 4.0, ground), Color("3d8b5f"), 3.0)
	var sh := foot + Vector2(0, -h * 0.74)
	var hands: Array
	var sig := str(d.signal)
	match sig:
		"advantage":
			hands = [sh + Vector2(h * 0.36, -h * 0.1), sh + Vector2(h * 0.38, h * 0.02)]
		"direct":
			hands = [sh + Vector2(-h * 0.1, h * 0.32), sh + Vector2(h * 0.4, 0.0)]
		"indirect":
			hands = [sh + Vector2(-h * 0.1, h * 0.32), sh + Vector2(h * 0.22, -h * 0.27)]
		"penalty":
			hands = [sh + Vector2(-h * 0.1, h * 0.32), sh + Vector2(h * 0.32, h * 0.24)]
			ci.draw_circle(Vector2(sh.x + h * 0.62, ground - 2.0), maxf(3.0, h * 0.03), Color.WHITE)
			ci.draw_arc(Vector2(sh.x + h * 0.62, ground - 2.0), maxf(3.0, h * 0.03), 0.0, TAU, 12, INK, 1.0)
		_:
			hands = [sh + Vector2(-h * 0.1, h * 0.32), sh + Vector2(h * 0.24, -h * 0.25)]
	var body := _person(ci, foot, h, hands, Color("1b1b1b"))
	ci.draw_circle((body.head as Vector2) + Vector2(h * 0.07, h * 0.06), maxf(2.0, h * 0.02), GREY)
	if sig == "card":
		var colour := RED if str(d.get("card", "yellow")) == "red" else Color("f7d21e")
		var right: Vector2 = body.right
		ci.draw_rect(Rect2(right + Vector2(-h * 0.03, -h * 0.12), Vector2(h * 0.08, h * 0.11)), colour)
		ci.draw_rect(Rect2(right + Vector2(-h * 0.03, -h * 0.12), Vector2(h * 0.08, h * 0.11)), INK, false, 1.5)
	if name:
		var words := str(SIGNAL_NAMES[sig])
		if sig == "card":
			words = "%s card" % str(d.get("card", "yellow"))
		_say(ci, font, Vector2(r.get_center().x, r.end.y - fs * 0.7), words, _fit(font, words, fs, r.size.x - 4.0))


# --- Circuits ---------------------------------------------------------------------------------------------------------

static func _draw_schematic(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var parts: Array = d.parts
	var n := parts.size()
	var texty := bool(d.get("names", false)) or d.has("values")
	var band := fs * (2.4 if bool(d.get("names", false)) and d.has("values") else 1.3) if texty else 0.0
	var k_top := ceili(n / 2.0)
	var k_bottom := n - k_top
	var s := minf(r.size.x * 0.84 / maxi(k_top, k_bottom) * 0.62, minf(fs * 4.2, (r.size.y - band * 2.0) * 0.36))
	var edge := band + s * 0.55   # the symbols and their words stay inside the card
	var loop := Rect2(r.position.x + r.size.x * 0.08, r.position.y + edge, r.size.x * 0.84, r.size.y - edge * 2.0)
	ci.draw_rect(loop, WIRE, false, 2.5)
	var live := conducts(parts, bool(d.get("active", false))) and bool(d.get("lit", false))
	for i in n:
		var top := i < k_top
		var c := Vector2(loop.position.x + loop.size.x * (i + 0.5) / k_top, loop.position.y) if top else \
			Vector2(loop.end.x - loop.size.x * (i - k_top + 0.5) / k_bottom, loop.end.y)
		var flow := 1.0 if top else -1.0
		ci.draw_rect(Rect2(c - Vector2(s * 0.55, s * 0.5), Vector2(s * 1.1, s)), PAPER)
		var sym := str(parts[i])
		if d.has("hide") and int(d.hide) == i:
			_box(ci, Rect2(c - Vector2(s * 0.45, s * 0.35), Vector2(s * 0.9, s * 0.7)), SOFT, ORANGE, 4, 2)
			_say(ci, font, c, "?", fs, ORANGE, false)
		else:
			_symbol(ci, font, c, s, flow, sym, bool(d.get("active", false)), live)
		if d.has("mark") and int(d.mark) == i:
			ci.draw_rect(Rect2(c - Vector2(s * 0.6, s * 0.55), Vector2(s * 1.2, s * 1.1)), ORANGE, false, 3.0)
		var lines: Array = []   # [words, colour]: the name, then the value, away from the loop
		if bool(d.get("names", false)) and not (d.has("hide") and int(d.hide) == i):
			lines.append([str(SYM_NAMES[sym]), INK])
		if d.has("values") and str(d.values[i]) != "":
			lines.append([str(d.values[i]), BLUE])
		var room := loop.size.x / maxi(k_top, k_bottom) - 4.0
		for k in lines.size():
			var step := (lines.size() - 1 - k) if top else k
			var off := s * 0.5 + fs * (0.7 + 1.1 * step)
			var at := c + Vector2(0, -off if top else off)
			_say(ci, font, at, str(lines[k][0]), _fit(font, str(lines[k][0]), fs - 1, room), lines[k][1])


## One circuit symbol centred on `c`, `s` across, for current flowing to the right (flow 1) or the left (flow -1).
static func _symbol(ci: CanvasItem, font: Font, c: Vector2, s: float, flow: float, sym: String, active: bool,
		live: bool) -> void:
	var w := 2.5
	var lead := func(x0: float, x1: float) -> void:
		ci.draw_line(c + Vector2(x0, 0), c + Vector2(x1, 0), WIRE, w)
	match sym:
		"cell", "battery":
			var plates: Array[float] = [0.0]
			if sym == "battery":
				plates = [-s * 0.18, s * 0.18]
			lead.call(-s * 0.55, plates[0] - s * 0.05)
			lead.call(plates[-1] + s * 0.05, s * 0.55)
			for x0: float in plates:
				var long_x := x0 + s * 0.05 * flow   # the long plate (+) on the side the current leaves
				var short_x := x0 - s * 0.05 * flow
				ci.draw_line(c + Vector2(long_x, -s * 0.34), c + Vector2(long_x, s * 0.34), INK, 3.0)
				ci.draw_line(c + Vector2(short_x, -s * 0.18), c + Vector2(short_x, s * 0.18), INK, 5.0)
			if sym == "battery":   # two cells joined: the dashes between them
				for k in 3:
					var x := -s * 0.08 + k * s * 0.08
					ci.draw_line(c + Vector2(x - s * 0.025, 0), c + Vector2(x + s * 0.025, 0), INK, 2.0)
		"switch", "closed", "push", "reed", "tilt":
			var closed := sym == "closed" or (SENSING.has(sym) and active)
			lead.call(-s * 0.55, -s * 0.3)
			lead.call(s * 0.3, s * 0.55)
			ci.draw_circle(c + Vector2(-s * 0.3, 0), 3.0, INK)
			ci.draw_circle(c + Vector2(s * 0.3, 0), 3.0, INK)
			if sym == "push":
				var y := -s * (0.04 if closed else 0.2)
				ci.draw_line(c + Vector2(-s * 0.32, y), c + Vector2(s * 0.32, y), INK, 3.0)
				ci.draw_line(c + Vector2(0, y), c + Vector2(0, y - s * 0.22), INK, 2.5)
				ci.draw_line(c + Vector2(-s * 0.1, y - s * 0.22), c + Vector2(s * 0.1, y - s * 0.22), INK, 2.5)
			else:
				var tip := c + (Vector2(s * 0.3, 0) if closed else Vector2(s * 0.26, -s * 0.24))
				ci.draw_line(c + Vector2(-s * 0.3, 0), tip, INK, 3.0)
			if sym == "reed":
				ci.draw_set_transform(c, 0.0, Vector2(1.0, 0.45))
				ci.draw_arc(Vector2.ZERO, s * 0.45, 0.0, TAU, 28, BLUE, 2.0)
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			elif sym == "tilt":
				ci.draw_arc(c, s * 0.45, 0.0, TAU, 28, BLUE, 2.0)
				ci.draw_circle(c + Vector2(s * (0.18 if active else -0.18), s * 0.22), s * 0.08, GREY)
		"pad":
			lead.call(-s * 0.55, -s * 0.4)
			lead.call(s * 0.4, s * 0.55)
			var gap := s * (0.02 if active else 0.12)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.4, -gap - s * 0.12), Vector2(s * 0.8, s * 0.12)), GREY)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.4, gap), Vector2(s * 0.8, s * 0.12)), GREY)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.4, -gap - s * 0.12), Vector2(s * 0.8, s * 0.24 + gap * 2.0)), INK, false,
				1.5)
		"resistor", "ldr":
			lead.call(-s * 0.55, -s * 0.3)
			lead.call(s * 0.3, s * 0.55)
			ci.draw_rect(Rect2(c - Vector2(s * 0.3, s * 0.12), Vector2(s * 0.6, s * 0.24)), Color.WHITE)
			ci.draw_rect(Rect2(c - Vector2(s * 0.3, s * 0.12), Vector2(s * 0.6, s * 0.24)), INK, false, 2.5)
			if sym == "ldr":
				ci.draw_arc(c, s * 0.42, 0.0, TAU, 28, INK, 2.0)
				for k in 2:
					var from := c + Vector2(-s * 0.55 + k * s * 0.2, -s * 0.62)
					_arrow(ci, from, from + Vector2(s * 0.16, s * 0.24), Color("e0a400"), 2.0)
		"led", "led_back":
			lead.call(-s * 0.55, -s * 0.22)
			lead.call(s * 0.22, s * 0.55)
			var dir := flow * (1.0 if sym == "led" else -1.0)
			var back := c + Vector2(-s * 0.2 * dir, 0)
			var front := c + Vector2(s * 0.2 * dir, 0)
			var glow := live and sym == "led"
			if glow:
				ci.draw_circle(c, s * 0.42, Color(1.0, 0.25, 0.2, 0.25))
			_poly(ci, [back + Vector2(0, -s * 0.22), back + Vector2(0, s * 0.22), front], RED if glow else Color.WHITE, INK,
				2.5)
			ci.draw_line(front + Vector2(0, -s * 0.22), front + Vector2(0, s * 0.22), INK, 3.0)
			for k in 2:
				var from := c + Vector2(s * (0.02 + k * 0.16), -s * 0.24)
				_arrow(ci, from, from + Vector2(s * 0.14, -s * 0.2), RED, 2.0)
		"lamp":
			lead.call(-s * 0.55, -s * 0.28)
			lead.call(s * 0.28, s * 0.55)
			if live:
				ci.draw_circle(c, s * 0.4, Color(1.0, 0.85, 0.2, 0.45))
			ci.draw_circle(c, s * 0.28, Color.WHITE)
			ci.draw_arc(c, s * 0.28, 0.0, TAU, 24, INK, 2.5)
			var k := s * 0.2
			ci.draw_line(c + Vector2(-k, -k), c + Vector2(k, k), INK, 2.0)
			ci.draw_line(c + Vector2(-k, k), c + Vector2(k, -k), INK, 2.0)
		"buzzer":
			lead.call(-s * 0.55, -s * 0.24)
			lead.call(s * 0.24, s * 0.55)
			ci.draw_line(c + Vector2(-s * 0.24, s * 0.1), c + Vector2(s * 0.24, s * 0.1), INK, 2.5)
			ci.draw_arc(c + Vector2(0, s * 0.1), s * 0.24, PI, TAU, 16, INK, 2.5)
			if live:
				for k in 2:
					ci.draw_arc(c + Vector2(0, s * 0.05), s * (0.36 + k * 0.1), PI * 1.25, PI * 1.75, 8, ORANGE, 2.0)
		"motor":
			lead.call(-s * 0.55, -s * 0.28)
			lead.call(s * 0.28, s * 0.55)
			ci.draw_circle(c, s * 0.28, Color.WHITE)
			ci.draw_arc(c, s * 0.28, 0.0, TAU, 24, INK, 2.5)
			_say(ci, font, c, "M", int(s * 0.32), INK, false)
			if live:
				ci.draw_arc(c, s * 0.38, -PI * 0.3, PI * 0.3, 8, ORANGE, 2.0)


static func _draw_resistor(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 11.0)
	var bands: Array = d.bands
	var below := (fs * 1.6 if bool(d.get("names", false)) else 0.0) + (fs * 1.5 if bool(d.get("value", false)) else 0.0)
	var c := Vector2(r.get_center().x, r.position.y + (r.size.y - below) * 0.5)
	var bw := minf(r.size.x * 0.56, (r.size.y - below) * 2.4)
	var bh := minf(bw * 0.36, (r.size.y - below) * 0.7)
	ci.draw_line(Vector2(r.position.x + 4.0, c.y), Vector2(r.end.x - 4.0, c.y), GREY, maxf(3.0, bh * 0.08))
	var body := Rect2(c - Vector2(bw, bh) * 0.5, Vector2(bw, bh))
	_box(ci, body, Color("e8d3a8"), INK, int(bh * 0.4), 2)
	var xs: Array[float] = [0.2, 0.33, 0.46, 0.8]
	var centres: Array[float] = []
	for i in bands.size():
		var x := body.position.x + bw * xs[i]
		centres.append(x)
		var stripe := Rect2(x - bw * 0.035, body.position.y + 1.0, bw * 0.07, bh - 2.0)
		var hidden := d.has("hide") and int(d.hide) == i
		ci.draw_rect(stripe, Color("d5d5d5") if hidden else BAND_COLOURS[str(bands[i])])
		ci.draw_rect(stripe, INK, false, 1.0)
		if hidden:
			_say(ci, font, stripe.get_center(), "?", fs, ORANGE)
	var y := body.end.y + fs * 0.9
	if bool(d.get("names", false)):
		var row: Array = []
		for i in bands.size():
			var t := "?" if d.has("hide") and int(d.hide) == i else str(bands[i])
			row.append([centres[i], _text_w(font, t, fs - 2) + 6.0, t])
		var at := _spread(row, r.position.x, r.end.x, 3.0)
		for i in bands.size():
			ci.draw_line(Vector2(centres[i], body.end.y), Vector2(at[i], y - fs * 0.45), GREY, 1.0)
			_say(ci, font, Vector2(at[i], y), str(row[i][2]), fs - 2, INK, false)
		y += fs * 1.5
	if bool(d.get("value", false)):
		var words := "%s ohms" % GenKit.fmt(resistor_ohms(bands))
		_say(ci, font, Vector2(c.x, y), words, fs, BLUE, false)


# --- The microcontroller board ----------------------------------------------------------------------------------------

static func _draw_board(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var a := _diagram_box(d, r)
	var board := _sub(a, 0.02, 0.02, 0.98, 0.8)
	_box(ci, board, BOARD, INK, int(a.size.y * 0.06), 2)
	var leds: Array = d.get("leds", ["00000", "00000", "00000", "00000", "00000"])
	var grid := _sub(a, 0.33, 0.12, 0.67, 0.72)
	var cw := grid.size.x / 5.0
	var ch := grid.size.y / 5.0
	for y in 5:
		for x in 5:
			var cell := Rect2(grid.position + Vector2(x * cw + cw * 0.3, y * ch + ch * 0.2), Vector2(cw * 0.4, ch * 0.6))
			if led_at(leds, x, y):
				ci.draw_circle(cell.get_center(), maxf(cw, ch) * 0.42, Color(1.0, 0.3, 0.2, 0.35))
				ci.draw_rect(cell, Color("ff4a3a"))
			else:
				ci.draw_rect(cell, Color("4a4f58"))
	if bool(d.get("grid", false)):
		var gfs := maxi(7, int(minf(cw, ch) * 0.42))
		for k in 5:
			_say(ci, font, Vector2(grid.position.x + (k + 0.5) * cw, grid.position.y - ch * 0.25), str(k), gfs, Color.WHITE,
				false)
			_say(ci, font, Vector2(grid.position.x - cw * 0.3, grid.position.y + (k + 0.5) * ch), str(k), gfs, Color.WHITE,
				false)
	var pressed := str(d.get("pressed", ""))
	for b: String in ["A", "B"]:
		var at := _at(a, BOARD_AT["button " + b].x, BOARD_AT["button " + b].y)
		var u := a.size.y * 0.12
		ci.draw_rect(Rect2(at - Vector2(u, u), Vector2(u, u) * 2.0), Color("c9ced6"))
		ci.draw_circle(at, u * (0.62 if pressed.contains(b) else 0.75), Color("1b1b1b"))
		if pressed.contains(b):
			ci.draw_arc(at, u * 1.25, 0.0, TAU, 24, ORANGE, 3.0)
		_say(ci, font, at + Vector2(0, u * 1.6), b, fs, Color.WHITE, false)
	var sp := _at(a, BOARD_AT.speaker.x, BOARD_AT.speaker.y)
	var sr := a.size.y * 0.06
	ci.draw_circle(sp, sr, Color("3a3f48"))
	for k in 3:
		ci.draw_arc(sp, sr * (0.35 + k * 0.25), 0.0, TAU, 16, Color("8a8f98"), 1.0)
	if bool(d.get("sound", false)):
		for k in 2:
			var nt := sp + Vector2(-sr * (2.2 + k * 1.6), sr * (0.2 - k * 0.8))
			ci.draw_circle(nt, sr * 0.35, Color("f7d21e"))
			ci.draw_line(nt + Vector2(sr * 0.32, 0), nt + Vector2(sr * 0.32, -sr * 1.1), Color("f7d21e"), 2.0)
	var strip := _sub(a, 0.04, 0.8, 0.96, 0.99)
	ci.draw_rect(strip, Color("2f343c"))
	var pads := ["0", "1", "2", "3V", "GND"]
	for k in pads.size():
		var pw := strip.size.x / 5.0
		var pad := Rect2(strip.position + Vector2(k * pw + pw * 0.14, strip.size.y * 0.1), Vector2(pw * 0.72, strip.size.y * 0.8))
		_box(ci, pad, GOLD, Color("8a6a10"), 3, 1)
		_say(ci, font, pad.get_center(), pads[k], _fit(font, pads[k], fs - 1, pad.size.x - 4.0), INK, false)
	_board_marks(ci, a, d)
	if bool(d.get("labels", false)):
		_label_parts(ci, font, r, d, _anchors(d, a), fs)


## The marked part's orange ring on a diagram.
static func _board_marks(ci: CanvasItem, a: Rect2, d: Dictionary) -> void:
	if d.has("mark"):
		var at: Vector2 = _anchors(d, a).get(str(d.mark), Vector2(-1, -1))
		if at.x >= 0.0:
			ci.draw_arc(at, a.size.y * 0.14, 0.0, TAU, 28, ORANGE, 3.5)


# --- The torch, exploded ----------------------------------------------------------------------------------------------

static func _draw_exploded(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var a := _diagram_box(d, r)
	var y := a.position.y + a.size.y * 0.55
	var dash := 8.0
	var x := a.position.x
	while x < a.end.x:
		ci.draw_line(Vector2(x, y), Vector2(minf(x + dash, a.end.x), y), GREY, 1.5)
		x += dash * 2.0
	var u := a.size.y
	var at := func(part: String) -> Vector2:
		return _at(a, TORCH_AT[part].x, TORCH_AT[part].y)
	# the lens: a clear disc seen edge-on
	var lens: Vector2 = at.call("lens")
	ci.draw_set_transform(lens, 0.0, Vector2(0.28, 1.0))
	ci.draw_circle(Vector2.ZERO, u * 0.22, Color(0.75, 0.9, 1.0, 0.9))
	ci.draw_arc(Vector2.ZERO, u * 0.22, 0.0, TAU, 24, INK, 2.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the reflector: a shiny cone, wide end towards the lens
	var rf: Vector2 = at.call("reflector")
	_poly(ci, [rf + Vector2(-u * 0.07, -u * 0.22), rf + Vector2(u * 0.07, -u * 0.07), rf + Vector2(u * 0.07, u * 0.07),
		rf + Vector2(-u * 0.07, u * 0.22)], Color("d8dde6"), INK, 2.0)
	ci.draw_line(rf + Vector2(-u * 0.05, -u * 0.15), rf + Vector2(u * 0.04, -u * 0.05), Color.WHITE, 2.0)
	# the LED: a small dome with two legs
	var led: Vector2 = at.call("LED")
	ci.draw_line(led + Vector2(u * 0.01, -u * 0.03), led + Vector2(u * 0.08, -u * 0.03), GREY, 2.0)
	ci.draw_line(led + Vector2(u * 0.01, u * 0.03), led + Vector2(u * 0.06, u * 0.03), GREY, 2.0)
	ci.draw_circle(led + Vector2(-u * 0.01, 0), u * 0.05, Color("fff4c2"))
	ci.draw_rect(Rect2(led + Vector2(-u * 0.01, -u * 0.05), Vector2(u * 0.03, u * 0.1)), Color("fff4c2"))
	ci.draw_arc(led + Vector2(-u * 0.01, 0), u * 0.05, PI * 0.5, PI * 1.5, 12, INK, 1.5)
	# the case: a tube with a grip and the switch's slot
	var cs: Vector2 = at.call("case")
	var case_box := Rect2(cs - Vector2(u * 0.28, u * 0.16), Vector2(u * 0.56, u * 0.32))
	_box(ci, case_box, Color("3a7be8"), INK, int(u * 0.06), 2)
	for k in 5:
		var gx := case_box.position.x + case_box.size.x * (0.55 + k * 0.08)
		ci.draw_line(Vector2(gx, case_box.position.y + 3.0), Vector2(gx, case_box.end.y - 3.0), Color("2a5bb0"), 2.0)
	ci.draw_rect(Rect2(cs + Vector2(-u * 0.05, -u * 0.17), Vector2(u * 0.1, u * 0.04)), Color("1b2a4a"))
	# the switch: a button pulled up out of its slot
	var sw: Vector2 = at.call("switch")
	_box(ci, Rect2(sw - Vector2(u * 0.06, u * 0.05), Vector2(u * 0.12, u * 0.1)), Color("e0453a"), INK, 4, 2)
	var dy := sw.y + u * 0.07
	while dy < cs.y - u * 0.18:
		ci.draw_line(Vector2(sw.x, dy), Vector2(sw.x, minf(dy + 5.0, cs.y - u * 0.18)), GREY, 1.5)
		dy += 10.0
	# two batteries, + towards the LED
	var bt: Vector2 = at.call("batteries")
	for k in 2:
		var cell := Rect2(bt + Vector2(-u * 0.15 + k * u * 0.16, -u * 0.1), Vector2(u * 0.14, u * 0.2))
		_box(ci, cell, Color("2e2e2e"), INK, 3, 2)
		ci.draw_rect(Rect2(cell.position + Vector2(-u * 0.025, u * 0.07), Vector2(u * 0.025, u * 0.06)), GREY)
		ci.draw_rect(Rect2(cell.position + Vector2(cell.size.x * 0.55, 0), Vector2(cell.size.x * 0.45, cell.size.y)),
			Color("c9a227"))
	# the spring: a zigzag
	var sp: Vector2 = at.call("spring")
	var zig := PackedVector2Array()
	for k in 9:
		zig.append(sp + Vector2(-u * 0.08 + k * u * 0.02, (u * 0.1 if k % 2 == 0 else -u * 0.1)))
	ci.draw_polyline(zig, Color("8a8f98"), 3.0, true)
	# the end cap
	var ec: Vector2 = at.call("end cap")
	_box(ci, Rect2(ec - Vector2(u * 0.06, u * 0.15), Vector2(u * 0.12, u * 0.3)), Color("2a5bb0"), INK, 5, 2)
	_board_marks(ci, a, d)
	if bool(d.get("labels", false)):
		_label_parts(ci, font, r, d, _anchors(d, a), fs)


# --- CAM ----------------------------------------------------------------------------------------------------------------

## A 3D printer's parts in the box `a` with `layers` printed: {spool, filament, nozzle, layers, bed, top, layer_h}.
static func _printer_geo(a: Rect2, layers: int) -> Dictionary:
	var bed_y := 0.74
	var layer_h := 0.032
	var top := bed_y - layers * layer_h
	return {"spool": _at(a, 0.12, 0.3), "filament": _at(a, 0.28, 0.13), "nozzle": _at(a, 0.52, top - 0.08),
		"layers": _at(a, 0.52, (bed_y + top) * 0.5), "bed": _at(a, 0.52, bed_y + 0.04), "top": top, "layer_h": layer_h,
		"bed_y": bed_y}


static func _draw_cam(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var a := _diagram_box(d, r)
	if str(d.machine) == "laser":
		_draw_laser(ci, font, a)
	else:
		_draw_printer(ci, a, int(d.get("layers", 6)))
	_board_marks(ci, a, d)
	if bool(d.get("labels", false)):
		_label_parts(ci, font, r, d, _anchors(d, a), fs)


static func _draw_laser(ci: CanvasItem, font: Font, a: Rect2) -> void:
	_box(ci, _sub(a, 0.02, 0.04, 0.86, 0.92), Color("e6e9ef"), INK, 8, 2)
	ci.draw_rect(_sub(a, 0.05, 0.1, 0.83, 0.13), GREY)
	# the bed: a honeycomb of small cells
	var bed := _sub(a, 0.06, 0.7, 0.82, 0.84)
	ci.draw_rect(bed, Color("b9bec8"))
	var cols := 18
	for k in cols + 1:
		var x := bed.position.x + bed.size.x * k / cols
		ci.draw_line(Vector2(x, bed.position.y), Vector2(x, bed.end.y), Color("8a8f98"), 1.0)
	ci.draw_line(Vector2(bed.position.x, bed.get_center().y), Vector2(bed.end.x, bed.get_center().y), Color("8a8f98"), 1.0)
	ci.draw_rect(bed, INK, false, 1.5)
	# the sheet, seen from above at a slant, with its red cut line and black engraving
	var sheet := [_at(a, 0.16, 0.52), _at(a, 0.8, 0.52), _at(a, 0.74, 0.69), _at(a, 0.1, 0.69)]
	_poly(ci, sheet, Color("e4c18f"), INK, 2.0)
	var star := PackedVector2Array()
	var sc := _at(a, 0.42, 0.6)
	for k in 10:
		var ang := -PI * 0.5 + TAU * k / 10.0
		var rad := a.size.y * (0.075 if k % 2 == 0 else 0.032)
		star.append(sc + Vector2(cos(ang) * rad * 1.7, sin(ang) * rad))
	star.append(star[0])
	ci.draw_polyline(star, RED, 2.5, true)
	var text_at := _at(a, 0.62, 0.6)
	var efs := clampi(int(a.size.y * 0.08), 7, 16)
	_say(ci, font, text_at, "TILLY", efs, Color("3a2a1a"), false)
	# the laser head and its beam onto the star's edge
	var head := _at(a, LASER_AT["laser head"].x, LASER_AT["laser head"].y)
	_box(ci, Rect2(head - Vector2(a.size.x * 0.04, a.size.y * 0.07), Vector2(a.size.x * 0.08, a.size.y * 0.14)),
		Color("4a5060"), INK, 4, 2)
	var hit := star[2]
	ci.draw_line(head + Vector2(0, a.size.y * 0.07), Vector2(head.x, hit.y), Color(1.0, 0.1, 0.1, 0.9), 3.0)
	ci.draw_circle(Vector2(head.x, hit.y), 3.5, Color("ffe08a"))
	# the extractor's duct and fan, pulling the fumes out
	var ex := _at(a, LASER_AT.extractor.x, LASER_AT.extractor.y)
	ci.draw_rect(_sub(a, 0.86, 0.3, 0.98, 0.54), Color("c9ced6"))
	ci.draw_rect(_sub(a, 0.86, 0.3, 0.98, 0.54), INK, false, 1.5)
	ci.draw_circle(ex, a.size.y * 0.08, Color("e6e9ef"))
	for k in 3:
		var ang := TAU * k / 3.0
		ci.draw_line(ex, ex + Vector2(cos(ang), sin(ang)) * a.size.y * 0.07, INK, 3.0)
	for k in 3:
		var f := _at(a, 0.5 + k * 0.1, 0.42 - k * 0.03)
		ci.draw_arc(f, a.size.y * 0.03, PI, TAU, 8, GREY, 1.5)


static func _draw_printer(ci: CanvasItem, a: Rect2, layers: int) -> void:
	var g := _printer_geo(a, layers)
	ci.draw_rect(_sub(a, 0.3, 0.05, 0.33, 0.9), GREY)
	ci.draw_rect(_sub(a, 0.74, 0.05, 0.77, 0.9), GREY)
	ci.draw_rect(_sub(a, 0.3, 0.04, 0.77, 0.08), GREY)
	ci.draw_rect(_sub(a, 0.26, 0.88, 0.81, 0.94), Color("6a707c"))
	# the bed
	var bed_y: float = g.bed_y
	ci.draw_rect(_sub(a, 0.36, bed_y, 0.71, bed_y + 0.06), Color("2f343c"))
	# the layers so far: a small box shape with an overhang held up by a support
	var lh: float = g.layer_h
	for k in layers:
		var y0 := bed_y - (k + 1) * lh
		var x0 := 0.44 if k < layers - 2 or layers < 4 else 0.4
		var strip := _sub(a, x0, y0 + 0.003, 0.6, y0 + lh - 0.003)
		_box(ci, strip, PLA, Color("b5581b"), 2, 1)
	if layers >= 4:
		for k in layers - 2:
			var y0 := bed_y - (k + 1) * lh
			ci.draw_rect(_sub(a, 0.405, y0 + 0.006, 0.425, y0 + lh - 0.006), Color("f7c99a"))
	# the hot nozzle over the top layer, the filament from the spool
	var nz: Vector2 = g.nozzle
	var top_y := a.position.y + a.size.y * float(g.top)
	_box(ci, Rect2(nz - Vector2(a.size.x * 0.05, a.size.y * 0.1), Vector2(a.size.x * 0.1, a.size.y * 0.1)), Color("4a5060"),
		INK, 3, 2)
	_poly(ci, [nz + Vector2(-a.size.x * 0.015, 0), nz + Vector2(a.size.x * 0.015, 0), Vector2(nz.x, top_y - 2.0)], GOLD,
		INK, 1.5)
	ci.draw_rect(_sub(a, 0.3, 0.17, 0.77, 0.2), Color("8a8f98"))
	var sp: Vector2 = g.spool
	ci.draw_circle(sp, a.size.y * 0.15, PLA)
	ci.draw_arc(sp, a.size.y * 0.15, 0.0, TAU, 28, INK, 2.0)
	ci.draw_circle(sp, a.size.y * 0.05, Color("e6e9ef"))
	var fil := PackedVector2Array()
	for k in 13:
		fil.append(_bez(sp + Vector2(0, -a.size.y * 0.15), g.filament, nz + Vector2(0, -a.size.y * 0.1), k / 12.0))
	ci.draw_polyline(fil, PLA, 3.0, true)


# --- Fabrics ----------------------------------------------------------------------------------------------------------

static func _draw_fabric(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var a := _diagram_box(d, r)
	match str(d.type):
		"breathable":
			_draw_breathable(ci, a)
		"reflective":
			_draw_reflective(ci, a)
		_:
			_draw_smart(ci, a)
	_board_marks(ci, a, d)
	if bool(d.get("labels", false)):
		_label_parts(ci, font, r, d, _anchors(d, a), fs)


static func _draw_breathable(ci: CanvasItem, a: Rect2) -> void:
	ci.draw_rect(_sub(a, 0.0, 0.0, 1.0, 0.4), Color("dcecf8"))
	ci.draw_rect(_sub(a, 0.0, 0.72, 1.0, 1.0), Color("f6dcc8"))
	ci.draw_rect(_sub(a, 0.02, 0.4, 0.98, 0.52), Color("2f6fdc"))   # outer fabric
	for k in 24:
		var x := a.position.x + a.size.x * (0.03 + k * 0.04)
		ci.draw_line(Vector2(x, a.position.y + a.size.y * 0.41), Vector2(x, a.position.y + a.size.y * 0.51), Color("1f4fa8"),
			1.0)
	ci.draw_rect(_sub(a, 0.02, 0.52, 0.98, 0.6), Color("eef1f6"))   # the membrane, with tiny pores
	for k in 30:
		ci.draw_circle(_at(a, 0.04 + k * 0.032, 0.56), maxf(1.2, a.size.y * 0.008), Color("8a93a1"))
	ci.draw_rect(_sub(a, 0.02, 0.6, 0.98, 0.72), Color("8fd0a8"))   # the lining
	for rect: Rect2 in [_sub(a, 0.02, 0.4, 0.98, 0.52), _sub(a, 0.02, 0.52, 0.98, 0.6), _sub(a, 0.02, 0.6, 0.98, 0.72)]:
		ci.draw_rect(rect, INK, false, 1.5)
	for k in 5:   # raindrops falling and bouncing off
		var c := _at(a, 0.08 + k * 0.1, 0.12 + (k % 2) * 0.1)
		_poly(ci, [c + Vector2(0, -a.size.y * 0.06), c + Vector2(a.size.y * 0.035, a.size.y * 0.01), c + Vector2(0,
			a.size.y * 0.04), c + Vector2(-a.size.y * 0.035, a.size.y * 0.01)], BLUE, INK, 1.0)
	for k in 3:
		var hit := _at(a, 0.14 + k * 0.12, 0.39)
		ci.draw_arc(hit + Vector2(0, -a.size.y * 0.02), a.size.y * 0.05, PI * 1.1, PI * 1.9, 8, BLUE, 2.0)
		_arrow(ci, hit + Vector2(a.size.y * 0.04, -a.size.y * 0.04), hit + Vector2(a.size.y * 0.1, -a.size.y * 0.13), BLUE,
			2.0)
	for k in 3:   # water vapour from the warm body rising out through the pores
		var x := 0.72 + k * 0.08
		var dots := 6
		for j in dots:
			ci.draw_circle(_at(a, x + (0.01 if j % 2 == 0 else -0.01), 0.94 - j * 0.14), maxf(1.8, a.size.y * 0.014),
				Color("b0b8c4"))
		_arrow(ci, _at(a, x, 0.32), _at(a, x, 0.16), Color("8a93a1"), 2.0)


static func _draw_reflective(ci: CanvasItem, a: Rect2) -> void:
	ci.draw_rect(a, Color("1d2440"))
	ci.draw_rect(_sub(a, 0.0, 0.84, 1.0, 1.0), Color("3a3f48"))
	# a car with its headlight
	_poly(ci, _pts(a, [Vector2(0.0, 0.82), Vector2(0.0, 0.5), Vector2(0.08, 0.42), Vector2(0.17, 0.42),
		Vector2(0.23, 0.55), Vector2(0.24, 0.82)]), Color("c0563a"), INK, 2.0)
	ci.draw_circle(_at(a, 0.07, 0.84), a.size.y * 0.06, Color("1b1b1b"))
	ci.draw_circle(_at(a, 0.21, 0.6), a.size.y * 0.035, Color("fff4c2"))
	# the beam out, and the light sent straight back
	var from := _at(a, 0.22, 0.6)
	var strip := _at(a, 0.67, 0.6)
	_poly(ci, [from, strip + Vector2(0, -a.size.y * 0.1), strip + Vector2(0, a.size.y * 0.1)], Color(1.0, 0.95, 0.6, 0.35),
		INK, 0.0)
	_arrow(ci, _at(a, 0.26, 0.52), _at(a, 0.63, 0.52), Color("ffe08a"), 2.5)
	_arrow(ci, _at(a, 0.63, 0.66), _at(a, 0.26, 0.66), Color("fff7cf"), 2.5)
	# a cyclist's vest with its silver strip
	ci.draw_rect(_sub(a, 0.64, 0.3, 0.74, 0.84), Color("d9f25a"))
	ci.draw_rect(_sub(a, 0.64, 0.68, 0.74, 0.82), Color("e8ebf0"))
	ci.draw_rect(_sub(a, 0.64, 0.3, 0.74, 0.84), INK, false, 1.5)
	# a close-up: glass beads in a row, each sending light back the way it came
	var zc := _at(a, 0.87, 0.45)
	var zr := a.size.y * 0.3
	ci.draw_circle(zc, zr, Color("2b3358"))
	ci.draw_arc(zc, zr, 0.0, TAU, 32, Color("e8ebf0"), 2.0)
	ci.draw_line(_at(a, 0.74, 0.75), zc + Vector2(-zr * 0.7, zr * 0.7), Color("e8ebf0"), 1.5)
	for k in 4:
		var b := zc + Vector2(-zr * 0.6 + k * zr * 0.4, zr * 0.3)
		ci.draw_circle(b, zr * 0.18, Color(0.85, 0.95, 1.0, 0.85))
		ci.draw_arc(b, zr * 0.18, 0.0, TAU, 16, INK, 1.0)
	ci.draw_line(zc + Vector2(-zr * 0.8, zr * 0.5), zc + Vector2(zr * 0.8, zr * 0.5), Color("e8ebf0"), 3.0)
	_arrow(ci, zc + Vector2(-zr * 0.75, -zr * 0.55), zc + Vector2(-zr * 0.25, zr * 0.1), Color("ffe08a"), 2.0)
	_arrow(ci, zc + Vector2(-zr * 0.1, zr * 0.05), zc + Vector2(-zr * 0.6, -zr * 0.6), Color("fff7cf"), 2.0)


static func _draw_smart(ci: CanvasItem, a: Rect2) -> void:
	_box(ci, _sub(a, 0.04, 0.06, 0.96, 0.94), Color("4a6fa5"), INK, 12, 2)
	for k in 12:   # the denim's stitches
		var x := a.position.x + a.size.x * (0.07 + k * 0.075)
		ci.draw_line(Vector2(x, a.position.y + a.size.y * 0.1), Vector2(x + 6.0, a.position.y + a.size.y * 0.1),
			Color("e8c070"), 1.5)
	var bat := _at(a, FABRIC_AT.smart.battery.x, FABRIC_AT.smart.battery.y)
	var sw := _at(a, FABRIC_AT.smart.switch.x, FABRIC_AT.smart.switch.y)
	var led1 := _at(a, FABRIC_AT.smart.LED.x, FABRIC_AT.smart.LED.y)
	var led2 := _at(a, 0.76, 0.74)
	var thread := Color("d5d9e0")
	for seg: Array in [[bat + Vector2(0, -a.size.y * 0.12), Vector2(bat.x, sw.y), sw], [sw, led1],
			[led1, led2], [led2, Vector2(bat.x, led2.y), bat + Vector2(0, a.size.y * 0.12)]]:
		for k in seg.size() - 1:
			var p0: Vector2 = seg[k]
			var p1: Vector2 = seg[k + 1]
			var n := maxi(1, int(p0.distance_to(p1) / 9.0))
			for j in n:
				if j % 2 == 0:
					ci.draw_line(p0.lerp(p1, float(j) / n), p0.lerp(p1, float(j + 1) / n), thread, 3.0)
	ci.draw_circle(bat, a.size.y * 0.12, Color("c0c4cc"))
	ci.draw_arc(bat, a.size.y * 0.12, 0.0, TAU, 24, INK, 2.0)
	ci.draw_circle(bat, a.size.y * 0.08, Color("8a8f98"))
	_box(ci, Rect2(sw - Vector2(a.size.y * 0.09, a.size.y * 0.06), Vector2(a.size.y * 0.18, a.size.y * 0.12)),
		Color("2e2e2e"), INK, 3, 2)
	ci.draw_rect(Rect2(sw - Vector2(a.size.y * 0.02, a.size.y * 0.04), Vector2(a.size.y * 0.08, a.size.y * 0.08)),
		Color("e6e9ef"))
	for led: Vector2 in [led1, led2]:
		ci.draw_circle(led, a.size.y * 0.1, Color(1.0, 0.9, 0.3, 0.35))
		ci.draw_circle(led, a.size.y * 0.05, Color("fff4c2"))
		ci.draw_arc(led, a.size.y * 0.05, 0.0, TAU, 16, INK, 1.5)


# --- The eco home -----------------------------------------------------------------------------------------------------

static func _draw_eco_home(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var a := _diagram_box(d, r)
	var f := _features(d)
	ci.draw_rect(_sub(a, 0.0, 0.0, 1.0, 0.9), Color("dcecf8"))
	ci.draw_rect(_sub(a, 0.0, 0.9, 1.0, 1.0), Color("9fcf7f"))
	ci.draw_rect(_sub(a, 0.2, 0.44, 0.75, 0.9), Color("f2e3c6"))   # the walls, cut open
	ci.draw_rect(_sub(a, 0.2, 0.44, 0.75, 0.9), INK, false, 2.0)
	ci.draw_line(_at(a, 0.475, 0.44), _at(a, 0.475, 0.9), Color("c9b48a"), 2.0)
	_poly(ci, _pts(a, [Vector2(0.16, 0.44), Vector2(0.47, 0.08), Vector2(0.78, 0.44)]), Color("b05a3a"), INK, 2.0)
	ci.draw_rect(_sub(a, 0.4, 0.74, 0.46, 0.9), Color("8a5a3a"))   # the door
	if f.has("insulation"):
		var band := PackedVector2Array()
		for k in 11:
			band.append(_at(a, 0.2 + k * 0.055, 0.4 + (0.012 if k % 2 == 0 else -0.012)))
		band.append(_at(a, 0.75, 0.44))
		band.append(_at(a, 0.2, 0.44))
		ci.draw_colored_polygon(band, Color("f7d96b"))
	if f.has("solar panels"):
		var c := _at(a, ECO_AT["solar panels"].x, ECO_AT["solar panels"].y)
		var along := (_at(a, 0.47, 0.08) - _at(a, 0.16, 0.44)).normalized()
		var up := Vector2(along.y, -along.x)
		var half := a.size.x * 0.07
		var pts := [c - along * half, c + along * half, c + along * half + up * a.size.y * 0.06,
			c - along * half + up * a.size.y * 0.06]
		_poly(ci, pts, Color("1f4fa8"), INK, 1.5)
		for k in range(1, 4):
			ci.draw_line((pts[0] as Vector2).lerp(pts[1], k / 4.0), (pts[3] as Vector2).lerp(pts[2], k / 4.0), Color("8fb3f0"),
				1.0)
	if f.has("double glazing"):
		var w := _sub(a, 0.27, 0.56, 0.39, 0.72)
		ci.draw_rect(w, Color("cfe9f7"))
		ci.draw_rect(w, INK, false, 2.0)
		ci.draw_line(w.position + Vector2(w.size.x * 0.46, 0), w.position + Vector2(w.size.x * 0.46, w.size.y), INK, 1.5)
		ci.draw_line(w.position + Vector2(w.size.x * 0.54, 0), w.position + Vector2(w.size.x * 0.54, w.size.y), INK, 1.5)
	if f.has("LED light"):
		var b := _at(a, ECO_AT["LED light"].x, ECO_AT["LED light"].y)
		ci.draw_line(_at(a, ECO_AT["LED light"].x, 0.44), b + Vector2(0, -a.size.y * 0.03), INK, 1.5)
		ci.draw_circle(b, a.size.y * 0.06, Color(1.0, 0.92, 0.4, 0.35))
		ci.draw_circle(b, a.size.y * 0.028, Color("fff4c2"))
		ci.draw_arc(b, a.size.y * 0.028, 0.0, TAU, 12, INK, 1.0)
	if f.has("heat pump"):
		var hp := _sub(a, 0.8, 0.74, 0.93, 0.9)
		_box(ci, hp, Color("e6e9ef"), INK, 3, 2)
		var c := hp.get_center()
		ci.draw_arc(c, hp.size.y * 0.32, 0.0, TAU, 20, INK, 1.5)
		for k in 3:
			var ang := TAU * k / 3.0
			ci.draw_line(c, c + Vector2(cos(ang), sin(ang)) * hp.size.y * 0.28, INK, 2.0)
		ci.draw_line(_at(a, 0.75, 0.82), _at(a, 0.8, 0.82), INK, 2.0)
	if f.has("rain butt"):
		ci.draw_line(_at(a, 0.17, 0.44), _at(a, 0.17, 0.7), GREY, 3.0)
		ci.draw_line(_at(a, 0.17, 0.7), _at(a, 0.11, 0.72), GREY, 3.0)
		_box(ci, _sub(a, 0.05, 0.72, 0.13, 0.9), Color("3fa34d"), INK, 4, 2)
		ci.draw_rect(_sub(a, 0.06, 0.82, 0.12, 0.89), Color("7fb6e8"))
	_board_marks(ci, a, d)
	if bool(d.get("labels", false)):
		_label_parts(ci, font, r, d, _anchors(d, a), fs)
