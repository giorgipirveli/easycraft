extends GutTest
## Owner #70 and #73, grade 5 maths, science and English (G5CoreGen, "g5c"; research §6.5): percentages, angle facts,
## forces and machines, electric circuits, life cycles and seeds, the pulse and the blood's loop, quotes, sources,
## linking words, formal writing, an explanation's features, showing feelings, speech marks and summaries. Each answer is
## worked out again here from the exercise's picture and `data` with this file's own facts and rules (typed apart from
## the generator's tables), for many seeds and every level, and every exercise must be valid (ExerciseCheck, the
## picture's own check).

const SEEDS := 80
const GENS: Array[String] = ["percent_square", "percent_convert", "percent_of", "discount", "percent_order", "angle_line",
	"angle_point", "angle_cross", "triangle_angle", "quad_angle", "force_name", "friction_test", "lever_push",
	"machine_gears", "circuit_lit", "circuit_bright", "circuit_symbol", "cycle_order", "seed_travel", "young_birth",
	"pulse_rate", "body_path", "organ_match", "quote_pick", "quote_exact", "source_pick", "opinion_link", "formal_pick",
	"text_feature", "show_feeling", "speech_marks", "summary_pick"]
## Surfaces from the least friction to the most.
const FRICTION: Array[String] = ["ice", "smooth wood", "carpet", "sandpaper"]
## Words that give a situation's force away.
const FORCE_WORDS := {"friction": ["brakes", "rub", "Rubbing", "grip", "chalk", "struck", "stony"],
	"air resistance": ["parachute", "paper plane", "umbrella", "cyclist", "feather", "curved shapes"],
	"water resistance": ["swimmer", "rowing", "paddling", "fish", "ship"],
	"gravity": ["apple drops", "thrown up", "Moon keeps", "falls faster"]}
## Each animal's life cycle, from the start.
const LIFE := {"grasshopper": ["egg", "nymph", "adult grasshopper"], "dragonfly": ["egg", "nymph living in water",
	"adult dragonfly"], "chicken": ["egg", "chick", "adult hen"], "cat": ["kitten is born", "kitten drinks milk",
	"young cat", "adult cat"], "frog": ["frogspawn (eggs)", "tadpole", "froglet", "adult frog"],
	"butterfly": ["egg", "caterpillar (larva)", "chrysalis (pupa)", "butterfly"], "robin": ["egg", "hatchling",
	"fledgling", "adult robin"], "ladybird": ["egg", "larva", "pupa", "adult ladybird"], "toad": ["eggs in long strings",
	"tadpole", "toadlet", "adult toad"], "whale": ["calf is born", "calf drinks milk", "young whale", "adult whale"],
	"sunflower": ["seed", "seedling", "young plant", "flower", "new seeds"], "mosquito": ["egg", "larva", "pupa",
	"adult mosquito"]}
## How each plant's seeds travel.
const SEED_WAY := {"dandelion": "the wind", "sycamore": "the wind", "thistle": "the wind",
	"burdock": "sticking to animals' fur", "goosegrass": "sticking to animals' fur", "blackberry": "animals eating the fruit",
	"cherry": "animals eating the fruit", "coconut": "floating on water", "water lily": "floating on water",
	"pea": "pods bursting open", "gorse": "pods bursting open", "oak": "animals burying them"}
const MAMMALS_BORN_ALIVE: Array[String] = ["cow", "whale", "bat", "horse", "dolphin", "elephant", "rabbit", "kangaroo",
	"giraffe", "seal"]
const EGG_LAYERS: Array[String] = ["frog", "robin", "butterfly", "crocodile", "salmon", "tortoise", "penguin", "bee",
	"snail", "ostrich", "platypus"]
## The blood's loop, round and round, and the air's way in.
const LOOP: Array[String] = ["muscles", "veins", "right side", "lungs give", "left side", "arteries"]
const AIR: Array[String] = ["nose", "windpipe", "tubes", "air sacs"]
const JOB := {"heart": "pumps", "lungs": "oxygen from the air", "windpipe": "air to the lungs", "diaphragm": "breathe",
	"arteries": "away from the heart", "veins": "back to the heart", "capillaries": "tiny tubes", "air sacs": "into the blood",
	"red blood cells": "carry oxygen", "white blood cells": "germs", "platelets": "clot", "plasma": "food and water"}
## The sentence that proves each point.
const PROOF := {"Bram was at the beach": "sandcastle", "the clown fell into water": "paddling pool",
	"the bridge moved": "swayed", "Dot is very old": "sixty", "Oli was not upset about his cake": "smiled",
	"Juno did not want to wake the dog": "tiptoed", "it was wet outside": "dripped", "it was very cold": "frozen",
	"the letter had good news": "danced", "the buddy was unhappy": "drooped", "Zara was not sure of the way": "map round",
	"Kit knew the answer": "shot up"}
const SOURCE := {"habitat": "glossary", "owls": "index", "chapters": "contents", "Peru": "atlas", "necessary": "dictionary",
	"Roman invasion": "timeline", "rain": "bar chart", "bicycle": "diagram", "big": "thesaurus", "website": "trusted",
	"bees tell": "expert"}
const LINK := {"Plastic": "Therefore", "Our park": "Specifically", "Trees give": "Furthermore", "Many pupils": "Consequently",
	"homework": "However", "Reading every": "For instance", "Cycling costs": "In contrast", "floods": "As a result",
	"Gardens help": "In particular", "library": "Moreover"}
## Marks of informal English: short forms and chatty words.
const INFORMAL: Array[String] = ["'", "kids", "super", "loads", "reckon", "stuff", "cheers", "shout", "mad", "ok",
	"meet up", "shut"]
const FEATURE := {"Magma": "a definition", "A volcano is": "a definition", "How volcanoes form": "a subheading",
	"Picture 2": "a caption", "expert said": "a quotation", "In conclusion": "a conclusion", "lava:": "a glossary entry",
	"Mount Etna": "a fact", "Why volcanoes": "a subheading", "To sum up": "a conclusion", "pollen:": "a glossary entry",
	"beekeeper": "a quotation"}
const SHOWS := {"hands shook": "nervous", "slammed": "angry", "bounced": "excited", "tear": "sad", "froze": "scared",
	"drooped": "tired", "stood tall": "proud", "jaw dropped": "surprised", "sighed": "bored"}
const SYMBOL_NAMES := {"cell": "a cell", "battery": "a battery", "lamp": "a lamp (bulb)", "open": "an open switch",
	"closed": "a closed switch", "buzzer": "a buzzer", "motor": "a motor"}
const SUMMARY := {"Hedgehogs": "Hedgehogs eat pests", "Our school": "Printing less", "Romans": "Roman roads",
	"Bats": "not blind", "Water covers": "fresh: save", "Trees clean": "plant more"}


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make("g5c." + gen, s, level)
			assert_false(ex.is_empty(), "%s makes an exercise" % gen)
			if ex.is_empty():
				return
			assert_eq(ExerciseCheck.problem(ex), "", "%s: %s" % [gen, ex.get("prompt", "")])
			assert_ne(str(ex.get("explain", "")), "", "%s: a worked answer" % gen)
			assert_ne(str(ex.get("hint", "")), str(ex.get("explain", "")), "%s: the hint is a strategy" % gen)
			assert_true(ex.get("data") is Dictionary, "%s: its data" % gen)
			if ex.has("picture"):
				assert_eq(SchoolPicture.problem(ex.picture), "", "%s: its picture" % gen)
			if ExerciseCheck.problem(ex) == "" and ex.get("data") is Dictionary:
				check.call(ex, level)


func _number_is(ex: Dictionary, expected: float) -> void:
	assert_eq(str(ex.type), "number", str(ex.prompt))
	assert_almost_eq(NumberAnswer.value(str(ex.answer)), expected, 0.0001, str(ex.prompt))


func _answer(ex: Dictionary) -> String:
	return ExerciseCheck.answer_text(ex)


## An order exercise's items in the right order.
func _in_order(ex: Dictionary) -> Array:
	var out: Array = []
	for i: Variant in ex.answer:
		out.append(ex.items[int(i)])
	return out


## A sort's items in their right groups, by the group's name.
func _sorted(ex: Dictionary) -> Dictionary:
	var out := {}
	for g: String in ex.groups:
		out[g] = []
	for i in (ex.items as Array).size():
		(out[ex.groups[int(ex.answer[i])]] as Array).append(str(ex.items[i]))
	return out


## A fraction, a decimal or a percentage as a number of per cent: "3/5" 60, "0.35" 35, "45%" 45.
func _percent_of_text(t: String) -> float:
	if t.ends_with("%"):
		return float(t.trim_suffix("%"))
	if t.contains("/"):
		return float(t.get_slice("/", 0)) * 100.0 / float(t.get_slice("/", 1))
	return float(t) * 100.0


func test_every_generator_is_here() -> void:
	var ids := SchoolGen.ids().filter(func(g: String) -> bool: return g.begins_with("g5c."))
	assert_eq(ids.size(), GENS.size(), "every g5c generator is tested here: %s" % [ids])
	for g in GENS:
		assert_true(SchoolGen.exists("g5c." + g), g)


# --- Percentages -------------------------------------------------------------------------------------------------------

func test_the_hundred_square() -> void:
	_each("percent_square", _check_percent_square)


func _check_percent_square(ex: Dictionary, level: int) -> void:
	var n := int(ex.picture.shaded)
	assert_eq(str(ex.picture.kind), "hundred_square")
	var want := [float(n), 100.0 - n, n / 100.0][level - 1] as float
	_number_is(ex, want)
	if level == 1:
		assert_eq(n % 5, 0, "level 1: fives")


func test_fractions_decimals_and_percentages() -> void:
	_each("percent_convert", _check_percent_convert)


func _check_percent_convert(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	var value: float   # in per cent
	if d.has("num"):
		value = float(d.num) * 100.0 / float(d.den)
		assert_true(str(ex.prompt).begins_with("%d/%d" % [d.num, d.den]), str(ex.prompt))
	elif d.has("decimal"):
		value = float(d.decimal) * 100.0
		assert_true(str(ex.prompt).begins_with(str(d.decimal)), str(ex.prompt))
	else:
		value = float(d.percent)
		assert_true(str(ex.prompt).contains("%d%%" % int(d.percent)), str(ex.prompt))
	match str(d.want):
		"percent":
			_number_is(ex, value)
		"decimal":
			_number_is(ex, value / 100.0)
		"fraction":
			_number_is(ex, value / 100.0)
			var parts := str(ex.answer).split("/")
			var a := int(parts[0])
			var b := int(parts[1])
			for k in range(2, b + 1):
				assert_false(a % k == 0 and b % k == 0, "%s is in its simplest form" % ex.answer)
	if level == 3 and d.has("den"):
		assert_true(int(d.den) in [2, 4, 5, 20, 25, 50], "level 3: halves to fiftieths")


func test_a_percentage_of_an_amount() -> void:
	_each("percent_of", _check_percent_of)


func _check_percent_of(ex: Dictionary, level: int) -> void:
	var p := int(ex.data.p)
	var n := int(ex.data.n)
	assert_true(str(ex.prompt).contains("%d%%" % p) and str(ex.prompt).contains(str(n)), str(ex.prompt))
	_number_is(ex, n * p / 100.0)
	assert_true(p in [[50, 10], [25, 75, 20, 30, 40], [5, 15, 35, 45, 60, 70, 90]][level - 1], "level %d: %d%%" % [level, p])


func test_discounts_in_gold() -> void:
	_each("discount", _check_discount)


func _check_discount(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	if d.has("pa"):
		var a := int(d.price_a) * (100 - int(d.pa)) / 100.0
		var b := int(d.price_b) * (100 - int(d.pb)) / 100.0
		var want := "Shop A" if a < b else ("Shop B" if b < a else "They cost the same")
		assert_true(_answer(ex).begins_with(want), "%s: %s (A %s, B %s)" % [ex.prompt, _answer(ex), a, b])
		assert_eq(level, 3, "two offers at level 3")
		return
	var off := int(d.price) * int(d.p) / 100.0
	assert_true(str(ex.prompt).contains("%d gold" % int(d.price)), str(ex.prompt))
	_number_is(ex, off if str(d.ask) == "off" else int(d.price) - off)
	assert_eq(str(d.ask) == "off", level == 1)


func test_comparing_fractions_decimals_and_percentages() -> void:
	_each("percent_order", _check_percent_order)


# --- Angles -------------------------------------------------------------------------------------------------------------


func _check_percent_order(ex: Dictionary, level: int) -> void:
	var shown: Array = ex.data.shown
	var values: Array = ex.data.values
	for i in shown.size():
		assert_almost_eq(_percent_of_text(str(shown[i])), float(values[i]), 0.001, str(shown[i]))
	if level == 3:
		var got := _in_order(ex)
		for i in range(1, got.size()):
			assert_lt(_percent_of_text(str(got[i - 1])), _percent_of_text(str(got[i])), "smallest first: %s" % [got])
	else:
		var best := _percent_of_text(_answer(ex))
		for c: Variant in ex.choices:
			assert_true(_percent_of_text(str(c)) <= best, "%s is the largest" % _answer(ex))


## Every angle picture's angles keep their rule (a straight line 180°, a point 360°, a triangle 180°, a quadrilateral
## 360°), every angle it shows in degrees is its own, and the answer is the angle asked for.
func _check_angles(ex: Dictionary, figure: String, total: int) -> void:
	var pic: Dictionary = ex.picture
	assert_eq(str(pic.figure), figure)
	var angles: Array = pic.angles
	var sum := 0
	for a: Variant in angles:
		sum += int(a)
	assert_eq(sum, total, "%s: %s" % [figure, angles])
	var labels: Array = pic.labels
	var asked := -1
	for i in labels.size():
		var l := str(labels[i])
		if l.ends_with("°"):
			assert_eq(l, "%d°" % int(angles[i]), "a shown angle is its own")
		elif l == "?":
			asked = i
	if asked >= 0:
		_number_is(ex, float(angles[asked]))
	elif str(ex.prompt).contains("What is a,"):
		_number_is(ex, float(angles[labels.find("a")]))
		for i in labels.size():
			if str(labels[i]) == "a":
				assert_eq(int(angles[i]), int(angles[labels.find("a")]), "the angles marked a are equal")
	else:
		assert_true(str(ex.prompt).contains("angle b"), str(ex.prompt))
		_number_is(ex, float(angles[labels.find("b")]))


func test_angles_on_a_straight_line() -> void:
	_each("angle_line", _check_angle_line)


func _check_angle_line(ex: Dictionary, level: int) -> void:
	_check_angles(ex, "straight", 180)
	if level == 1:
		assert_eq(int(ex.picture.angles[0]) % 10, 0, "level 1: tens")


func test_angles_round_a_point() -> void:
	_each("angle_point", _check_angle_point)


func _check_angle_point(ex: Dictionary, level: int) -> void:
	_check_angles(ex, "point", 360)
	if level == 3:
		assert_true((ex.picture.labels as Array).has("a"), "level 3: equal angles marked a")


func test_vertically_opposite_angles() -> void:
	_each("angle_cross", _check_angle_cross)


func _check_angle_cross(ex: Dictionary, level: int) -> void:
	var angles: Array = ex.picture.angles
	assert_eq(int(angles[0]), int(angles[2]), "vertically opposite angles are equal")
	assert_eq(int(angles[1]), int(angles[3]))
	assert_eq(int(angles[0]) + int(angles[1]), 180, "neighbours on a straight line")
	_check_angles(ex, "cross", 360)
	if level == 3:
		assert_true(str(ex.prompt).contains("add up to %d°" % (2 * int(angles[0]))), str(ex.prompt))
	else:
		var labels: Array = ex.picture.labels
		var given := -1
		for i in 4:
			if str(labels[i]).ends_with("°"):
				given = i
		var asked := labels.find("?")
		assert_eq(absi(asked - given) == 2, level == 1, "level 1 asks the opposite angle, level 2 a neighbour")


func test_angles_in_a_triangle() -> void:
	_each("triangle_angle", _check_triangle_angle)


func _check_triangle_angle(ex: Dictionary, level: int) -> void:
	_check_angles(ex, "triangle", 180)
	var angles: Array = ex.picture.angles
	if level == 3:
		assert_eq(int(angles[0]), int(angles[1]), "isosceles: the base angles are equal")
		assert_eq(ex.picture.ticks, [1, 2], "the two equal sides are marked")
	for i in 3:
		if int(angles[i]) == 90:
			assert_eq(str(ex.picture.labels[i]), "", "a right angle is shown by its square")


func test_angles_in_a_quadrilateral() -> void:
	_each("quad_angle", _check_quad_angle)


# --- Forces and machines --------------------------------------------------------------------------------------------------


func _check_quad_angle(ex: Dictionary, level: int) -> void:
	_check_angles(ex, "quad", 360)
	for a: Variant in ex.picture.angles:
		assert_lt(int(a), 180, "a convex quadrilateral")
	if str(ex.prompt).contains("parallelogram"):
		var a: Array = ex.picture.angles
		assert_eq(int(a[0]), int(a[2]), "opposite angles equal")
		assert_eq(int(a[0]) + int(a[1]), 180)


func test_which_force() -> void:
	_each("force_name", _check_force_name)


func _check_force_name(ex: Dictionary, level: int) -> void:
	var found := ""
	for f: String in FORCE_WORDS:
		for w: String in FORCE_WORDS[f]:
			if str(ex.data.situation).contains(w):
				assert_true(found == "" or found == f, "one force: %s" % ex.data.situation)
				found = f
	assert_ne(found, "", "a known situation: %s" % ex.data.situation)
	assert_eq(_answer(ex), found, str(ex.prompt))
	assert_eq((ex.choices as Array).size(), 3 if level == 1 else 4)


func test_friction_tests() -> void:
	_each("friction_test", _check_friction_test)


func _check_friction_test(ex: Dictionary, level: int) -> void:
	if level == 1:
		var a: String = ex.data.surfaces[0]
		var b: String = ex.data.surfaces[1]
		var more := FRICTION.find(a) > FRICTION.find(b)
		var want := (a if more else b) if str(ex.data.ask) == "more" else (b if more else a)
		assert_eq(_answer(ex), want, str(ex.prompt))
		return
	var rows: Array = ex.picture.rows
	var dist := {}
	for row: Array in rows.slice(1):
		dist[str(row[0])] = int(str(row[1]).trim_suffix(" cm"))
	var by_friction: Array = dist.keys()
	by_friction.sort_custom(func(x: String, y: String) -> bool: return FRICTION.find(x) < FRICTION.find(y))
	for i in range(1, by_friction.size()):
		assert_gt(int(dist[by_friction[i - 1]]), int(dist[by_friction[i]]), "more friction, a shorter roll: %s" % [dist])
	match str(ex.type):
		"choice":
			assert_eq(_answer(ex), by_friction[-1], "the shortest roll: the most friction")
		"order":
			assert_eq(_in_order(ex), by_friction)
		"number":
			_number_is(ex, float(int(dist[by_friction[0]]) - int(dist[by_friction[-1]])))


func test_levers() -> void:
	_each("lever_push", _check_lever_push)


func _check_lever_push(ex: Dictionary, level: int) -> void:
	var far := -1
	for c: Dictionary in ex.choices:
		var p: Dictionary = c.picture
		assert_eq(str(p.kind), "lever")
		far = maxi(far, absi(int(p.effort) - int(p.pivot)))
	var right: Dictionary = ex.choices[int(ex.answer)].picture
	assert_eq(absi(int(right.effort) - int(right.pivot)), far, "the push farthest from the pivot needs the least effort")
	assert_eq((ex.choices as Array).size(), 2 if level == 1 else 3)


func test_gears_and_pulleys() -> void:
	_each("machine_gears", _check_machine_gears)


# --- Electric systems ---------------------------------------------------------------------------------------------------


func _check_machine_gears(ex: Dictionary, level: int) -> void:
	var pic: Dictionary = ex.picture
	if str(pic.kind) == "pulleys":
		_number_is(ex, int(ex.data.load) / 2.0)
		return
	var gears: Array = pic.gears
	if str(ex.type) == "number":
		_number_is(ex, float(gears[1]) / float(gears[0]))
		return
	var first := "clockwise" if str(pic.turn) == "cw" else "anticlockwise"
	var other := "anticlockwise" if first == "clockwise" else "clockwise"
	assert_eq(_answer(ex), first if gears.size() % 2 == 1 else other, "meshing gears turn opposite ways")


## Which loads work, by this file's own rule: in series, all or none; in parallel, a branch works when neither it nor the
## main line has an open switch. How hard: the cells over the loads on the path.
func _works(pic: Dictionary) -> Array:
	var out: Array = []
	var rows: Array = pic.branches if pic.has("branches") else [pic.series]
	var main_open := (pic.get("main", []) as Array).has("open")
	for row: Array in rows:
		var n := 0
		for x: Variant in row:
			if str(x) in ["lamp", "buzzer", "motor"]:
				n += 1
		for x: Variant in row:
			if str(x) in ["lamp", "buzzer", "motor"]:
				out.append(0.0 if main_open or row.has("open") else float(pic.get("cells", 1)) / n)
	return out


func test_which_lamps_light() -> void:
	_each("circuit_lit", _check_circuit_lit)


func _check_circuit_lit(ex: Dictionary, level: int) -> void:
	var works := _works(ex.picture)
	if str(ex.type) == "truefalse":
		assert_eq(ex.answer, float(works[int(ex.data.ask)]) > 0.0, str(ex.picture))
	else:
		_number_is(ex, float(works.filter(func(p: float) -> bool: return p > 0.0).size()))
	assert_eq(ex.picture.has("branches"), level > 1, "level 1: series; levels 2-3: parallel")
	assert_eq(ex.picture.has("main"), level == 3)


func test_brighter_or_dimmer() -> void:
	_each("circuit_bright", _check_circuit_bright)


func _check_circuit_bright(ex: Dictionary, level: int) -> void:
	if level == 3:
		var best := -1.0
		for c: Dictionary in ex.choices:
			best = maxf(best, float(_works(c.picture)[0]))
		assert_eq(float(_works(ex.choices[int(ex.answer)].picture)[0]), best, "the brightest")
		var tops := (ex.choices as Array).filter(func(c: Dictionary) -> bool: return float(_works(c.picture)[0]) == best)
		assert_eq(tops.size(), 1, "one brightest")
		return
	var p := float(_works(ex.picture)[0])
	assert_eq(_answer(ex), "brighter" if p > 1.0 else ("dimmer" if p < 1.0 else "the same"), str(ex.picture))


func test_circuit_symbols() -> void:
	_each("circuit_symbol", _check_circuit_symbol)


# --- How living things reproduce ---------------------------------------------------------------------------------------------


func _check_circuit_symbol(ex: Dictionary, level: int) -> void:
	var sym := str(ex.data.symbol)
	if level < 3:
		assert_eq(ex.picture.symbols, [sym])
		assert_false(bool(ex.picture.get("names", true)), "the name is not shown")
		assert_eq(_answer(ex), SYMBOL_NAMES[sym])
	else:
		assert_true(str(ex.prompt).contains(SYMBOL_NAMES[sym]), str(ex.prompt))
		assert_eq(ex.choices[int(ex.answer)].picture.symbols, [sym])


func test_life_cycles() -> void:
	_each("cycle_order", _check_cycle_order)


func _check_cycle_order(ex: Dictionary, level: int) -> void:
	var stages: Array = LIFE[str(ex.data.animal)]
	if level < 3:
		assert_eq(_in_order(ex), stages, str(ex.data.animal))
		assert_eq(stages.size(), 2 + level, "level %d: %d stages" % [level, 2 + level])
	else:
		var pic: Dictionary = ex.picture
		assert_eq(_answer(ex), str(pic.stages[int(pic.hide)]), "the hidden stage")
		for c: Variant in ex.choices:
			if str(c) != _answer(ex):
				for s: Variant in stages:
					assert_false(str(s).contains(str(c)), "%s is not a stage of the %s" % [c, ex.data.animal])


func test_how_seeds_travel() -> void:
	_each("seed_travel", _check_seed_travel)


func _check_seed_travel(ex: Dictionary, level: int) -> void:
	if level == 3:
		var groups := _sorted(ex)
		for g: String in groups:
			assert_eq((groups[g] as Array).size(), 2)
			for plant: String in groups[g]:
				assert_eq(SEED_WAY[plant], g, plant)
	else:
		assert_eq(_answer(ex), SEED_WAY[str(ex.data.plant)], str(ex.prompt))


func test_eggs_or_live_young() -> void:
	_each("young_birth", _check_young_birth)


# --- Breathing and the heart ----------------------------------------------------------------------------------------------


func _check_young_birth(ex: Dictionary, level: int) -> void:
	if level == 1:
		assert_true(MAMMALS_BORN_ALIVE.has(_answer(ex)), _answer(ex))
		for c: Variant in ex.choices:
			if str(c) != _answer(ex):
				assert_true(EGG_LAYERS.has(str(c)), str(c))
		return
	var groups := _sorted(ex)
	for a: String in groups["live young"]:
		assert_true(MAMMALS_BORN_ALIVE.has(a), a)
	for a: String in groups["lays eggs"]:
		assert_true(EGG_LAYERS.has(a), a)
	if (ex.items as Array).has("platypus"):
		assert_true(str(ex.explain).contains("mammal that lays eggs"))


func test_the_pulse() -> void:
	_each("pulse_rate", _check_pulse_rate)


func _check_pulse_rate(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	var per_minute := 60 / int(d.seconds)
	if d.has("after"):
		_number_is(ex, float((int(d.after) - int(d.count)) * per_minute))
		assert_eq(level, 3)
	else:
		_number_is(ex, float(int(d.count) * per_minute))
	var rate := int(d.count) * per_minute
	if str(ex.prompt).contains("heartbeats") or str(ex.prompt).contains("beats"):
		assert_between(rate, 60, 110, "a child's pulse at rest: %d" % rate)
	else:
		assert_between(rate, 12, 30, "breaths at rest: %d" % rate)


func test_the_air_and_the_blood_go_round_in_order() -> void:
	_each("body_path", _check_body_path)


func _check_body_path(ex: Dictionary, level: int) -> void:
	var steps := _in_order(ex)
	var ring: Array = AIR if level == 1 else LOOP
	var at := -1
	for s: Variant in steps:
		var here := -1
		for i in ring.size():
			if str(s).contains(str(ring[i])):
				here = i
		assert_ne(here, -1, "a known step: %s" % s)
		if at >= 0:
			assert_eq(here, (at + 1) % ring.size() if level > 1 else at + 1, "%s follows" % s)
		at = here
	if level == 3:
		assert_true(str(ex.prompt).contains(str(steps[0])), "it starts where the question says")


func test_body_parts_and_their_jobs() -> void:
	_each("organ_match", _check_organ_match)


# --- English ------------------------------------------------------------------------------------------------------------------


func _check_organ_match(ex: Dictionary, level: int) -> void:
	for i in (ex.items as Array).size():
		var part := str(ex.items[i])
		assert_true(str(ex.matches[int(ex.answer[i])]).contains(JOB[part]), "%s: %s" % [part, ex.matches[int(ex.answer[i])]])
	assert_eq((ex.items as Array).size(), 3 if level == 1 else 4)


func test_quotes_that_prove_it() -> void:
	_each("quote_pick", _check_quote_pick)


func _check_quote_pick(ex: Dictionary, level: int) -> void:
	var claim := str(ex.data.claim)
	assert_true(_answer(ex).contains(PROOF[claim]), "%s: %s" % [claim, _answer(ex)])
	for c: Variant in ex.choices:
		assert_true(str(ex.prompt).contains(str(c)), "every choice is quoted from the text: %s" % c)


func test_exact_quotes() -> void:
	_each("quote_exact", _check_quote_exact)


func _check_quote_exact(ex: Dictionary, level: int) -> void:
	var text := str(ex.prompt).get_slice("The text says: ", 1).get_slice(" Which is an exact", 0)
	assert_eq(_answer(ex), text, "the exact quote")
	for c: Variant in ex.choices:
		if str(c) != text:
			assert_ne(str(c), text)


func test_where_to_look() -> void:
	_each("source_pick", _check_source_pick)


func _check_source_pick(ex: Dictionary, level: int) -> void:
	var found := false
	for k: String in SOURCE:
		if str(ex.data.question).contains(k):
			found = true
			assert_true(_answer(ex).contains(SOURCE[k]), "%s: %s" % [ex.data.question, _answer(ex)])
	assert_true(found, str(ex.data.question))


func test_linking_words() -> void:
	_each("opinion_link", _check_opinion_link)


func _check_opinion_link(ex: Dictionary, level: int) -> void:
	var found := false
	for k: String in LINK:
		if str(ex.data.sentence).begins_with(k) or str(ex.data.sentence).contains(" " + k):
			found = true
			assert_eq(_answer(ex), LINK[k], str(ex.data.sentence))
	assert_true(found, str(ex.data.sentence))


func _informal(t: String) -> bool:
	var low := t.to_lower()
	for w in INFORMAL:
		if RegEx.create_from_string("(^|\\W)" + w + "(\\W|$)").search(low) != null or (w == "'" and low.contains("'")):
			return true
	return false


func test_formal_and_informal() -> void:
	_each("formal_pick", _check_formal_pick)


func _check_formal_pick(ex: Dictionary, level: int) -> void:
	if str(ex.type) == "sort":
		var groups := _sorted(ex)
		for t: String in groups["formal"]:
			assert_false(_informal(t), "formal: %s" % t)
		for t: String in groups["informal"]:
			assert_true(_informal(t), "informal: %s" % t)
		return
	assert_false(_informal(_answer(ex)), _answer(ex))
	for c: Variant in ex.choices:
		if str(c) != _answer(ex):
			assert_true(_informal(str(c)), str(c))


func test_an_explanations_features() -> void:
	_each("text_feature", _check_text_feature)


func _check_text_feature(ex: Dictionary, level: int) -> void:
	var found := false
	for k: String in FEATURE:
		if str(ex.data.text).begins_with(k) or str(ex.data.text).contains(k):
			found = true
			assert_eq(_answer(ex), FEATURE[k], str(ex.data.text))
	assert_true(found, str(ex.data.text))


func test_show_do_not_tell() -> void:
	_each("show_feeling", _check_show_feeling)


func _check_show_feeling(ex: Dictionary, level: int) -> void:
	var feeling := str(ex.data.feeling)
	if level < 3:
		var shown := _answer(ex)
		assert_false(shown.to_lower().contains(feeling), "it shows, not tells: %s" % shown)
		var key := ""
		for k: String in SHOWS:
			if shown.contains(k):
				key = k
		assert_eq(SHOWS.get(key, ""), feeling, shown)
	else:
		for k: String in SHOWS:
			if str(ex.prompt).contains(k):
				assert_eq(_answer(ex), SHOWS[k], str(ex.prompt))


## Speech punctuated by the rules the lesson teaches: speech marks round the words spoken; the comma, question mark or
## exclamation mark inside them; a capital letter to start the speech (a split sentence carries on in a small letter);
## a question asked ends in a question mark; only "said Mum." or "Bram said, " outside the marks.
func _speech_right(t: String) -> bool:
	var q := t.count("\"")
	if q < 2 or q % 2 != 0:
		return false
	var parts := t.split("\"")   # outside, inside, outside, inside, …, outside
	var tag := RegEx.create_from_string("^ (said|asked|shouted|cried|whispered) [A-Z][a-z]+(,|\\.) ?$")
	var lead := RegEx.create_from_string("^[A-Z][a-z]+ (said|asked|shouted|cried), $")
	for i in parts.size():
		var p := parts[i]
		if i % 2 == 1:   # spoken words
			if p == "" or not p[p.length() - 1] in [",", ".", "!", "?"]:
				return false
			var after_comma := i > 1 and parts[i - 1].ends_with(", ")
			var first := p.substr(0, 1)
			if after_comma and i > 1 and not parts[i - 1].begins_with(" said") and not parts[i - 1].begins_with(" cried"):
				after_comma = false
			if (first == first.to_upper()) == (after_comma and i > 1):
				return false
			if RegEx.create_from_string("(said|asked|shouted|cried) [A-Z]").search(p) != null:
				return false
			var next := parts[i + 1] if i + 1 < parts.size() else ""
			if next.begins_with(" asked") and not p.ends_with("?"):
				return false
		else:
			if p == "":
				continue
			if p.substr(0, 1) in [",", ".", "!", "?"]:
				return false
			if i == 0:
				if lead.search(p) == null:
					return false
			elif tag.search(p) == null:
				return false
	return true


func test_speech_marks() -> void:
	for right: String in ["\"Come here,\" said Mum.", "Bram said, \"Let's go.\"", "\"Where are you going?\" asked Zara.",
			"\"I think,\" said Mimi, \"that it will rain.\"", "\"We won!\" cried Juno. \"We really won!\""]:
		assert_true(_speech_right(right), "the rules pass %s" % right)
	_each("speech_marks", _check_speech_marks)


func _check_speech_marks(ex: Dictionary, level: int) -> void:
	assert_true(_speech_right(_answer(ex)), "right: %s" % _answer(ex))
	for c: Variant in ex.choices:
		if str(c) != _answer(ex):
			assert_false(_speech_right(str(c)), "a mistake: %s" % c)


func test_summaries() -> void:
	_each("summary_pick", _check_summary_pick)


func _check_summary_pick(ex: Dictionary, level: int) -> void:
	var talk := str(ex.data.talk)
	var found := false
	for k: String in SUMMARY:
		if talk.begins_with(k) or talk.contains(k + " "):
			found = true
			assert_true(_answer(ex).contains(SUMMARY[k]), "%s: %s" % [k, _answer(ex)])
	assert_true(found, talk)
	assert_lt(_answer(ex).length(), talk.length() / 2, "a summary is short")
