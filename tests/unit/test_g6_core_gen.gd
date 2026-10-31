extends GutTest
## Owner #70 and #73, grade 6 maths, science and English: the research's last units (G6CoreGen, "g6k"; research §6.6):
## the problem-solving toolkit, skeleton and muscles, nutrition and digestion, classifying life, light, energy changes,
## engineering design, reading closely, arguments, information texts, narratives, sources and discussions. Each answer is
## worked out again here from the exercise's picture and `data` with this file's own facts, arithmetic and rules (typed
## apart from the generator's tables), for many seeds and every level, and every exercise must be valid (ExerciseCheck,
## the picture's own check).

const SEEDS := 80
const GENS: Array[String] = ["work_back", "bar_problem", "systematic_list", "guess_check", "find_pattern",
	"strategy_pick", "bone_job", "muscle_work", "joint_type", "nutrient_find", "food_test_read", "enzyme_job",
	"vertebrate_group", "invertebrate_group", "key_walk", "kingdom_pick", "taxon_order", "shadow_size", "mirror_angle",
	"light_kind", "energy_convert", "energy_waste", "save_energy", "criteria_sort", "design_pick", "decision_matrix",
	"trial_mean", "stated_or_inferred", "best_evidence", "story_or_fact", "argument_part", "argument_link",
	"formal_style", "precise_word", "info_feature", "hook_pick", "pace_pick", "vivid_verb", "paraphrase_pick",
	"source_trust", "cite_order", "build_on", "chart_choice"]

## Problems and the strategy that fits them, by a phrase in each.
const STRATEGY := {"3 times as many shells": "draw a model", "spent half his gold": "work backwards",
	"one hat and one scarf": "make a systematic list", "10 heads and 28 legs": "guess and check",
	"2, 5, 8 and 11": "look for a pattern", "gave away 12": "work backwards", "multiply to make 96": "guess and check",
	"3-digit numbers": "make a systematic list", "4 times as long": "draw a model", "first 30 odd": "look for a pattern",
	"2/5 of his gold": "draw a model", "is doubled, then 7": "work backwards", "2-gold and 5-gold coins": "make a systematic list",
	"12 tickets cost 44": "guess and check", "1 × 1, 2 × 2": "look for a pattern"}
const PROTECT := {"brain": "skull", "heart and lungs": "ribs", "spinal cord": "spine"}
const BONE_NAME := {"skull": "skull", "ribs": "ribs", "spine": "spine", "pelvis": "pelvis", "humerus": "humerus",
	"radius_ulna": "radius and ulna", "femur": "femur", "tibia_fibula": "tibia and fibula"}
## True or false facts, by a phrase in each.
const FACTS := {"206 bones": true, "marrow": true, "femur, in your thigh": true, "not alive": false,
	"new baby": true, "smallest bone": true, "Calcium from milk": true, "only holds you up": false,
	"only pull": true, "Tendons join muscles": true, "Ligaments join muscles": false, "quadriceps contract": true,
	"triceps contracts too": false, "Cartilage is a smooth": true, "longer and fatter": false}
## The muscle that contracts for each move (its partner relaxes).
const PULLS := {"bend your arm": "biceps", "straighten your arm": "triceps", "bend your leg": "hamstrings",
	"straighten your leg": "quadriceps"}
const PARTNER := {"biceps": "triceps", "triceps": "biceps", "hamstrings": "quadriceps", "quadriceps": "hamstrings"}
const JOINT_AT := {"elbow": "hinge joint", "knee": "hinge joint", "fingers": "hinge joint",
	"shoulder": "ball and socket joint", "hip": "ball and socket joint", "neck": "pivot joint", "skull": "fixed joint"}
const JOINT_DRAWN := {"hinge": "hinge joint", "ball_socket": "ball and socket joint", "pivot": "pivot joint",
	"fixed": "fixed joint"}
const MOVES_BY := {"elbow": "moves one way", "knee": "moves one way", "finger": "moves one way",
	"shoulder": "moves every way", "hip": "moves every way", "skull": "does not move"}
## Nutrients by food, job and lack.
const RICH_IN := {"bread, rice": "carbohydrates", "fish, eggs": "proteins", "butter": "fats", "oranges": "vitamin C",
	"milk": "calcium", "wholegrain": "fibre", "potatoes": "carbohydrates", "lentils": "proteins"}
const JOB_OF := {"most of its energy": "carbohydrates", "grow and repair": "proteins", "keeps you warm": "fats",
	"through your gut": "fibre", "bones and teeth": "calcium", "red blood cells": "iron", "gums and skin": "vitamin C",
	"in sunlight": "vitamin D", "every cell": "water"}
const LACK := {"scurvy": "vitamin C", "rickets": "vitamin D", "anaemia": "iron", "constipation": "fibre"}
const FOOD_GROUP := {"bread": "carbohydrates", "rice": "carbohydrates", "pasta": "carbohydrates",
	"potatoes": "carbohydrates", "fish": "proteins", "eggs": "proteins", "chicken": "proteins", "lentils": "proteins",
	"butter": "fats", "olive oil": "fats", "lard": "fats"}
## Which reagent finds which nutrient.
const REAGENT := {"starch": "iodine", "sugar": "Benedict", "protein": "biuret", "fat": "paper"}
const ENZYME := {"starch": "amylase", "protein": "protease", "fat": "lipase"}
const MAKES := {"starch": "sugars", "protein": "amino acids", "fat": "fatty acids and glycerol"}
const GUT := {"saliva": "the mouth", "strong acid": "the stomach", "into the blood": "the small intestine",
	"taken back out": "the large intestine", "makes bile": "the liver", "squeezes food": "the gullet"}
## Vertebrate groups.
const GROUP_OF := {"fish": "fish", "frog": "amphibian", "lizard": "reptile", "turtle": "reptile", "parrot": "bird",
	"owl": "bird", "penguin": "bird", "duck": "bird", "chicken": "bird", "dog": "mammal", "cat": "mammal",
	"cow": "mammal", "horse": "mammal", "seal": "mammal", "rabbit": "mammal", "fox": "mammal", "hedgehog": "mammal",
	"camel": "mammal", "polar_bear": "mammal", "deer": "mammal", "a whale": "mammal", "a bat": "mammal",
	"a penguin": "bird", "a shark": "fish", "a salamander": "amphibian", "a crocodile": "reptile", "a dolphin": "mammal",
	"a newt": "amphibian", "a snake": "reptile", "a seahorse": "fish", "an ostrich": "bird", "a platypus": "mammal"}
const GROUP_CLUE := {"gills, has fins": "fish", "moist skin": "amphibian", "dry, scaly": "reptile", "feathers": "bird",
	"milk": "mammal"}
const INVERT := {"an ant": "insects", "a ladybird": "insects", "a butterfly": "insects", "a bee": "insects",
	"a spider": "arachnids", "a scorpion": "arachnids", "a crab": "crustaceans", "a woodlouse": "crustaceans",
	"a lobster": "crustaceans", "a snail": "molluscs", "an octopus": "molluscs", "a slug": "molluscs",
	"an earthworm": "annelid worms", "a leech": "annelid worms", "a centipede": "myriapods", "a millipede": "myriapods"}
const INVERT_CLUE := {"six legs": "insects", "eight legs": "arachnids", "hard outer shell": "crustaceans",
	"soft body that": "molluscs", "in rings": "annelid worms", "lots of legs": "myriapods"}
## What each living thing in the keys has.
const HAS := {"robin": ["feathers", "wings", "legs"], "fox": ["fur", "legs"], "trout": ["fins"], "frog": ["legs"],
	"lizard": ["dry scales", "legs"], "snail": ["a shell"], "centipede": ["legs"], "earthworm": [],
	"daisy": ["flowers"], "pine tree": ["cones"], "fern": ["fronds"], "moss": [], "butterfly": ["wings", "legs"],
	"spider": ["8 legs", "legs"], "slug": []}
const KINGDOM := {"an eagle": "animals", "a snail": "animals", "an oak tree": "plants", "grass": "plants",
	"a mushroom": "fungi", "mould on old bread": "fungi", "the bacteria that turn milk": "bacteria",
	"an amoeba": "protists", "moss": "plants", "yeast": "fungi", "a sponge": "animals", "coral": "animals",
	"a toadstool": "fungi", "a fern": "plants"}
const KINGDOM_CLUE := {"eats other living things": "animals", "from sunlight": "plants", "spores": "fungi",
	"with a nucleus": "protists", "no nucleus": "bacteria"}
const LEVELS: Array[String] = ["kingdom", "phylum", "class", "order", "family", "genus", "species"]
const WOLF: Array[String] = ["animals", "chordates", "mammals", "carnivores", "dog family", "Canis", "Canis lupus"]
const SOURCES := {"the Sun": true, "a candle flame": true, "a lamp that is switched on": true, "a campfire": true,
	"a lit torch": true, "the Moon": false, "a mirror": false, "a white page": false, "a bicycle reflector": false,
	"a cat's eye": false, "a shiny spoon": false}
const SEE_THROUGH := {"clear glass": "transparent", "clean water": "transparent", "cling film": "transparent",
	"tracing paper": "translucent", "frosted glass": "translucent", "tissue paper": "translucent", "wood": "opaque",
	"cardboard": "opaque", "a brick": "opaque", "a metal tray": "opaque"}
## Energy in and out.
const DEVICE := {"an electric kettle": ["electrical", "heat"], "a loudspeaker": ["electrical", "sound"],
	"an electric fan": ["electrical", "kinetic"], "a lamp": ["electrical", "light"], "a solar panel": ["light", "electrical"],
	"a wind turbine": ["kinetic", "electrical"], "a microphone": ["sound", "electrical"], "a battery": ["chemical", "electrical"],
	"a wind-up toy": ["elastic", "kinetic"], "a campfire": ["chemical", "heat"]}
const CHAIN := {"through a dam": ["gravitational", "kinetic", "electrical"], "a torch": ["chemical", "electrical", "light"],
	"toy car": ["chemical", "electrical", "kinetic"], "bike lamp": ["chemical", "kinetic", "electrical", "light"],
	"ball dropped": ["gravitational", "kinetic", "heat"], "phone charged": ["light", "electrical", "chemical"],
	"turbine lighting": ["kinetic", "electrical", "light"], "a bow": ["chemical", "elastic", "kinetic"]}
const SAVES := {"lamp wastes": "an LED lamp", "one cup": "boil just one cupful", "leave a room": "switch the light off",
	"pan of soup": "a pan with a lid on", "loses less heat": "one with thick loft insulation",
	"dry clothes": "hang them on a line", "overnight": "turning the TV off at the switch",
	"keeps its heat": "curtains closed", "friend's house": "walking or cycling"}
## Words that mark a limit on a design.
const LIMIT_WORDS: Array[String] = ["at most", "or less", "only", "fit inside", "no more than", "safe"]
const INFERRED := {"It had been raining": "inferred", "boots were caked": "stated", "opens at seven.": "stated",
	"is popular": "inferred", "read the letter twice.": "stated", "good news": "inferred", "about 200 times": "stated",
	"not been used": "inferred", "very long distances": "inferred", "not sure which way": "inferred",
	"checked the map again.": "stated", "felt nervous": "inferred"}
const PROOF := {"nobody had looked after": "Brambles", "freezing": "Icicles", "Tam was nervous": "hands shook",
	"very busy": "thousand flowers", "soft and wet": "wellies", "loves reading": "every book", "very old": "rings",
	"did not want the sprouts": "slid the sprouts", "Dot was tired": "yawned"}
const CHARACTERS: Array[String] = ["Kit", "Mimi", "Zara", "Oli", "Old Owl"]
const PART_OF := {"should have a garden": "claim", "should have a free library": "claim", "teach us how food grows": "reason",
	"chance to read": "reason", "40 kg": "evidence", "12,000 books": "evidence", "Some people say": "counterclaim",
	"Some argue": "counterclaim", "However, a garden club": "rebuttal", "However, not every home": "rebuttal"}
const LINK := {"homework is boring": "However", "Cycling is good": "Furthermore", "Trees help wildlife": "For example",
	"Litter harms": "Therefore", "all these reasons": "In conclusion", "we need a garden": "Firstly",
	"Buses can be slow": "On the other hand", "free to join": "As a result"}
const INFORMAL: Array[String] = ["'", "!", "totally", "yeah", "loads", "innit", "gimme", "joke", "well good", "honestly",
	"rocks", "stuff", "ok", "super", "c'mon", "plus", "obviously"]
const PRECISE := {"BIG BANG": "erupts", "GOES UP": "evaporates", "HARD CASE": "chrysalis", "PUSHES": "pumps",
	"FOOD-MAKING": "photosynthesis", "TURNED INTO WATER": "melted", "SOUND-FINDING": "echolocation",
	"WEARS AWAY": "erodes", "PLANT-EATERS": "herbivores"}
const FEATURE := {"one section": "a subheading", "special words at the end": "a glossary", "what a picture": "a caption",
	"the pages they are on": "an index", "opens the text": "an introduction", "sums up": "a conclusion",
	"labelled drawing": "a diagram", "meaning of a word in the text": "a definition", "short points": "bullet points"}
const FLAT_STARTS: Array[String] = ["This is", "This story", "Once there", "There was", "One day", "I am going",
	"My story", "Zara was", "Zara lived", "Bram lived", "The river was", "Juno went", "Juno had", "Lighthouses",
	"The lighthouse"]
const VIVID := {"mouse WENT": "scurried", "SAID Oli": "yelled", "horse ATE": "gobbled", "CAME DOWN": "hammered",
	"LOOKED at": "stared", "kite WENT": "soared", "MADE A NOISE": "creaked", "MOVED quietly": "crept",
	"heart BEAT": "pounded"}
const TRUSTED := {"sharks": "marine scientist", "castle was built": "museum", "today's weather": "weather service",
	"bones are in a hand": "encyclopedia", "different heights": "third trusted", "sweet company": "sell"}
const BUILDS := {"plant flowers": "bees like", "bike rack": "shelter", "books about space": "which topics",
	"lights off": "Mimi's point", "Walking to school": "less traffic", "quiet room": "how many pupils"}


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make("g6k." + gen, s, level)
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


func _num(ex: Dictionary) -> float:
	return NumberAnswer.value(str(ex.answer))


func _answer(ex: Dictionary) -> String:
	return ExerciseCheck.answer_text(ex)


func _in_order(ex: Dictionary) -> Array:
	var out: Array = []
	for i: Variant in ex.answer:
		out.append(ex.items[int(i)])
	return out


## A sort's items and the group each is put in, by the group's name.
func _groups(ex: Dictionary) -> Dictionary:
	var out := {}
	for i in (ex.items as Array).size():
		out[str(ex.items[i])] = str(ex.groups[int(ex.answer[i])])
	return out


## The value of `key` whose phrase is in `text` (a phrase must be found).
func _by_phrase(table: Dictionary, text: String) -> Variant:
	for k: String in table:
		if text.contains(k):
			return table[k]
	fail_test("no phrase of the table in: %s" % text)
	return null


func test_every_generator_is_here() -> void:
	var ids := SchoolGen.ids().filter(func(g: String) -> bool: return g.begins_with("g6k."))
	assert_eq(ids.size(), GENS.size(), "every g6k generator is tested here: %s" % [ids])
	for g in GENS:
		assert_true(SchoolGen.exists("g6k." + g), g)


# --- The problem-solving toolkit -------------------------------------------------------------------------------------

## A step done or undone by this test's own arithmetic.
func _step(x: float, op: String, back: bool) -> float:
	var sign := op.substr(0, 1)
	var n := float(op.substr(2))
	if back:
		sign = {"+": "−", "−": "+", "×": "÷", "÷": "×"}[sign]
	match sign:
		"+":
			return x + n
		"−":
			return x - n
		"×":
			return x * n
	return x / n


func test_working_backwards() -> void:
	_each("work_back", _check_work_back)


func _check_work_back(ex: Dictionary, _level: int) -> void:
	var ops: Array = ex.data.ops
	var x := float(ex.data.end)
	for i in range(ops.size() - 1, -1, -1):
		x = _step(x, str(ops[i]), true)
	assert_almost_eq(_num(ex), x, 0.0001, str(ex.prompt))
	var y := _num(ex)
	for o: Variant in ops:
		y = _step(y, str(o), false)
		assert_eq(y, floorf(y), "whole numbers all the way: %s" % ex.prompt)
		assert_gt(y, 0.0, "above zero all the way")
	assert_almost_eq(y, float(ex.data.end), 0.0001, "the machine takes the start to the end")
	assert_eq(ex.picture.ops, ops, "the machine drawn is the one worked")


func test_bar_models() -> void:
	_each("bar_problem", _check_bar_problem)


func _check_bar_problem(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.kind):
		"sum_difference":
			var less := (int(d.total) - int(d.difference)) / 2.0
			assert_almost_eq(_num(ex), less + int(d.difference) if str(d.ask) == "more" else less, 0.0001, str(ex.prompt))
		"times_as_many":
			var u := float(d.total) / (int(d.times) + 1)
			var want: Variant = {"first": u * int(d.times), "second": u, "difference": u * (int(d.times) - 1)}[str(d.ask)]
			assert_almost_eq(_num(ex), float(want), 0.0001, str(ex.prompt))
		"fraction_of_rest":
			var start := _num(ex)
			var left := start - start / int(d.first)
			left -= left / int(d.second)
			assert_almost_eq(left, float(d.left), 0.0001, "what is left: %s" % ex.prompt)
			assert_true(str(ex.prompt).contains("1/%d" % int(d.first)) and str(ex.prompt).contains("1/%d" % int(d.second)))


func test_systematic_lists() -> void:
	_each("systematic_list", _check_systematic_list)


func _check_systematic_list(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var count := 0
	match str(d.kind):
		"pairs":
			for _i in int(d.a):
				for _j in int(d.b):
					count += 1
		"handshakes":
			for i in int(d.n):
				for j in range(i + 1, int(d.n)):
					count += 1
			assert_eq(int(ex.picture.n), int(d.n))
		"coins":
			for big in range(0, int(d.total) + 1):
				for small in range(0, int(d.total) + 1):
					if big * int(d.big) + small * int(d.small) == int(d.total):
						count += 1
	assert_eq(_num(ex), float(count), str(ex.prompt))


func test_guess_and_check() -> void:
	_each("guess_check", _check_guess_check)


func _check_guess_check(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var found: Array = []
	for many in range(0, int(d.count) + 1):
		if int(d.low) * (int(d.count) - many) + int(d.high) * many == int(d.total):
			found.append(many)
	assert_eq(found.size(), 1, "one answer fits: %s" % ex.prompt)
	assert_eq(_num(ex), float(found[0]), str(ex.prompt))


func test_patterns() -> void:
	_each("find_pattern", _check_find_pattern)


func _check_find_pattern(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	if d.has("sum_to"):
		var total := 0
		for k in range(1, int(d.sum_to) + 1):
			total += k
		assert_eq(_num(ex), float(total), str(ex.prompt))
	elif d.has("target"):
		var term := 1
		var v := int(d.first)
		while v < int(d.target):
			v += int(d.step)
			term += 1
		assert_eq(v, int(d.target), "the target is in the pattern")
		assert_eq(_num(ex), float(term), str(ex.prompt))
	else:
		var v := int(d.first)
		for _k in int(d.n) - 1:
			v += int(d.step)
		assert_eq(_num(ex), float(v), str(ex.prompt))
		var h: Array = ex.picture.heights
		for i in h.size():
			assert_eq(int(h[i]), int(d.first) + i * int(d.step), "the towers drawn follow the pattern")


func test_choosing_a_strategy() -> void:
	_each("strategy_pick", _check_strategy_pick)


func _check_strategy_pick(ex: Dictionary, _level: int) -> void:
	assert_eq(_answer(ex), _by_phrase(STRATEGY, str(ex.data.problem)), str(ex.prompt))


# --- Skeleton and muscles --------------------------------------------------------------------------------------------

func test_bones() -> void:
	_each("bone_job", _check_bone_job)


func _check_bone_job(ex: Dictionary, level: int) -> void:
	if level == 1:
		assert_eq(_answer(ex), _by_phrase(PROTECT, str(ex.data.protects)), str(ex.prompt))
	elif level == 2:
		assert_eq(_answer(ex), BONE_NAME[str(ex.picture.mark)], "the marked bone")
	else:
		assert_eq(ex.answer, _by_phrase(FACTS, str(ex.prompt)), str(ex.prompt))


func test_muscles_work_in_pairs() -> void:
	_each("muscle_work", _check_muscle_work)


func _check_muscle_work(ex: Dictionary, level: int) -> void:
	if level == 3:
		assert_eq(ex.answer, _by_phrase(FACTS, str(ex.prompt)), str(ex.prompt))
		return
	var pulls: String = _by_phrase(PULLS, str(ex.data.move))
	assert_eq(_answer(ex), pulls if bool(ex.data.contract) else PARTNER[pulls], str(ex.prompt))
	if ex.has("picture"):
		assert_eq(str(ex.picture.move) == "bend", pulls == "biceps", "the arm drawn bends or straightens")


func test_joints() -> void:
	_each("joint_type", _check_joint_type)


func _check_joint_type(ex: Dictionary, level: int) -> void:
	match level:
		1:
			assert_eq(_answer(ex), _by_phrase(JOINT_AT, str(ex.data.place)), str(ex.prompt))
		2:
			assert_eq(_answer(ex), JOINT_DRAWN[str(ex.picture.type)], "the joint drawn")
			assert_false(bool(ex.picture.get("name", true)), "the picture does not name it")
		_:
			var g := _groups(ex)
			for item: String in g:
				assert_eq(g[item], MOVES_BY[item], item)


# --- Nutrition and digestion -----------------------------------------------------------------------------------------

func test_nutrients() -> void:
	_each("nutrient_find", _check_nutrient_find)


func _check_nutrient_find(ex: Dictionary, level: int) -> void:
	match level:
		1:
			assert_eq(_answer(ex), _by_phrase(RICH_IN, str(ex.data.foods)), str(ex.prompt))
		2:
			assert_eq(_answer(ex), _by_phrase(JOB_OF, str(ex.data.job)), str(ex.prompt))
		_:
			if str(ex.type) == "sort":
				var g := _groups(ex)
				for item: String in g:
					assert_eq(g[item], FOOD_GROUP[item], item)
			else:
				assert_eq(_answer(ex), _by_phrase(LACK, str(ex.data.illness)), str(ex.prompt))


func test_food_tests() -> void:
	_each("food_test_read", _check_food_test_read)


func _check_food_test_read(ex: Dictionary, level: int) -> void:
	var tubes: Array = ex.picture.tubes
	assert_eq(tubes.size(), [1, 3, 4][level - 1])
	match level:
		1:
			var t := str(tubes[0][0])
			assert_eq(_answer(ex), t, "the nutrient its test finds")
			assert_true(str(ex.prompt).contains(REAGENT[t]), "the prompt names the right test: %s" % ex.prompt)
		2:
			var positive: Array = tubes.filter(func(tb: Array) -> bool: return bool(tb[1]))
			assert_eq(positive.size(), 1, "one food has it")
			assert_eq(_answer(ex), "food %s" % positive[0][2])
			assert_true(str(ex.prompt).contains(str(tubes[0][0])), "the prompt asks for the nutrient tested")
		_:
			var has: Array = []
			for tb: Array in tubes:
				if bool(tb[1]):
					has.append(str(tb[0]))
			assert_false(has.is_empty(), "at least one nutrient")
			for t: String in REAGENT:
				assert_eq(_answer(ex).contains(t), has.has(t), "%s in %s" % [t, _answer(ex)])


func test_enzymes() -> void:
	_each("enzyme_job", _check_enzyme_job)


func _check_enzyme_job(ex: Dictionary, level: int) -> void:
	match level:
		1:
			assert_eq(_answer(ex), ENZYME[str(ex.data.food)])
			assert_eq(str(ex.picture.hide), "enzyme", "the picture does not name it")
		2:
			assert_eq(_answer(ex), MAKES[str(ex.data.food)])
			assert_eq(str(ex.picture.hide), "products")
		_:
			assert_eq(_answer(ex), _by_phrase(GUT, str(ex.data.question)), str(ex.prompt))


# --- Classifying life ------------------------------------------------------------------------------------------------

func test_vertebrate_groups() -> void:
	_each("vertebrate_group", _check_vertebrate_group)


func _check_vertebrate_group(ex: Dictionary, level: int) -> void:
	match level:
		1:
			assert_eq(_answer(ex), GROUP_OF[str(ex.data.animal)], str(ex.data.animal))
			assert_eq(str(ex.picture.animal), str(ex.data.animal), "the animal drawn")
		2:
			assert_eq(_answer(ex), _by_phrase(GROUP_CLUE, str(ex.data.features)), str(ex.prompt))
		_:
			assert_eq(_answer(ex), GROUP_OF[str(ex.data.animal)], str(ex.data.animal))


func test_invertebrate_groups() -> void:
	_each("invertebrate_group", _check_invertebrate_group)


func _check_invertebrate_group(ex: Dictionary, level: int) -> void:
	match level:
		1:
			assert_eq(_answer(ex), INVERT[str(ex.data.animal)])
		2:
			assert_eq(_answer(ex), _by_phrase(INVERT_CLUE, str(ex.data.features)), str(ex.prompt))
		_:
			for c: Variant in ex.choices:
				assert_eq(INVERT[str(c)] == "insects", str(c) != _answer(ex), "only the answer is not an insect: %s" % c)


## A key walked with this test's own table of what each living thing has.
func test_keys() -> void:
	_each("key_walk", _check_key_walk)


func _check_key_walk(ex: Dictionary, level: int) -> void:
	var qs: Array = ex.data.questions
	var ends: Array = ex.data.ends
	assert_eq(qs.size(), level + 1, "questions by level")
	var feature := func(q: String) -> String: return q.replace("Does it have ", "").replace("Does it make ", "").trim_suffix("?")
	for e_i in ends.size():   # every living thing in the key is named by its own features
		var has: Array = HAS[str(ends[e_i])]
		var at := qs.size()
		for q_i in qs.size():
			if has.has(feature.call(str(qs[q_i]))):
				at = q_i
				break
		assert_eq(at, e_i, "%s is reached by its features" % ends[e_i])
	var answer := _answer(ex)
	var mine: Array = HAS[answer]
	for q_i in qs.size():
		var f: String = feature.call(str(qs[q_i]))
		var said := str(ex.data.said)
		if mine.has(f):
			assert_true(said.contains("it has " + f) or said.contains("it makes " + f), "%s: the clue %s" % [answer, f])
			break
		var bare := f.trim_prefix("a ")
		assert_true(said.contains("no " + bare) or said.contains("not have " + bare) or said.contains("makes no " + bare),
			"%s: not %s" % [answer, f])


func test_kingdoms() -> void:
	_each("kingdom_pick", _check_kingdom_pick)


func _check_kingdom_pick(ex: Dictionary, level: int) -> void:
	if level == 2:
		assert_eq(_answer(ex), _by_phrase(KINGDOM_CLUE, str(ex.data.features)), str(ex.prompt))
	else:
		assert_eq(_answer(ex), _by_phrase(KINGDOM, str(ex.data.living)), str(ex.prompt))


func test_the_levels_of_classification() -> void:
	_each("taxon_order", _check_taxon_order)


func _check_taxon_order(ex: Dictionary, level: int) -> void:
	var order := _in_order(ex)
	assert_eq(order.size(), [4, 5, 6][level - 1])
	var list: Array[String] = LEVELS if level < 3 else WOLF
	var last := -1
	for item: Variant in order:
		var at := list.find(str(item))
		assert_gt(at, last, "biggest to smallest: %s" % [order])
		last = at


# --- Light -----------------------------------------------------------------------------------------------------------

func test_shadows() -> void:
	_each("shadow_size", _check_shadow_size)


func _check_shadow_size(ex: Dictionary, level: int) -> void:
	if level == 1:
		var m := str(ex.data.move)
		var bigger := (m.contains("card closer to the lamp") or m.contains("screen farther") or m.contains("lamp closer"))
		assert_eq(_answer(ex), "It gets bigger." if bigger else "It gets smaller.", m)
		return
	var d: Dictionary = ex.data
	var shadow := float(d.size) * float(d.far) / float(d.near)   # similar triangles: the rays are straight
	var want: Variant = {"shadow": shadow, "size": float(d.size), "near": float(d.near)}[str(d.ask)]
	assert_almost_eq(_num(ex), float(want), 0.0001, str(ex.prompt))
	assert_eq(str(ex.picture.hide), str(d.ask), "the picture hides what is asked")
	assert_eq(float(ex.picture.near), float(d.near))
	assert_eq(float(ex.picture.far), float(d.far))


func test_reflection() -> void:
	_each("mirror_angle", _check_mirror_angle)


func _check_mirror_angle(ex: Dictionary, _level: int) -> void:
	var i := int(ex.data.i)
	var want: Variant = {"r": i, "i": i, "mr": 90 - i, "both": 2 * i}[str(ex.data.ask)]
	assert_eq(_num(ex), float(want), str(ex.prompt))
	assert_eq(int(ex.picture.i), i, "the ray drawn")


func test_light() -> void:
	_each("light_kind", _check_light_kind)


func _check_light_kind(ex: Dictionary, level: int) -> void:
	match level:
		1:
			assert_eq(ex.answer, _by_phrase(SOURCES, str(ex.data.thing)), str(ex.prompt))
		2:
			var g := _groups(ex)
			for item: String in g:
				assert_eq(g[item], SEE_THROUGH[item], item)
		_:
			var order := _in_order(ex)
			var marks := ["gives out", "travels", "reflects", "enters", "brain"]
			for k in marks.size():
				assert_true(str(order[k]).contains(marks[k]), "step %d: %s" % [k + 1, order[k]])


# --- Energy ----------------------------------------------------------------------------------------------------------

func test_energy_changes() -> void:
	_each("energy_convert", _check_energy_convert)


func _check_energy_convert(ex: Dictionary, level: int) -> void:
	if level < 3:
		var io: Array = DEVICE[str(ex.data.device)]
		assert_eq(_answer(ex), "%s energy" % (io[1] if str(ex.data.ask) == "out" else io[0]), str(ex.prompt))
	else:
		var steps: Array = _by_phrase(CHAIN, str(ex.data.chain))
		var hide := int(ex.data.hide)
		assert_between(hide, 1, steps.size() - 2, "a middle step is asked")
		assert_eq(_answer(ex), "%s energy" % steps[hide], str(ex.prompt))
		assert_eq(ex.picture.steps, steps, "the chain drawn")


func test_energy_flows() -> void:
	_each("energy_waste", _check_energy_waste)


func _check_energy_waste(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	var wasted := 0
	for w: Array in d.wasted:
		wasted += int(w[1])
	assert_eq(int(d.useful) + wasted, int(d.total), "energy is never made or destroyed")
	var want: Variant = [wasted, int(d.useful), int(d.useful) * 100 / int(d.total)][level - 1]
	assert_eq(_num(ex), float(want), str(ex.prompt))
	if level == 3:
		assert_eq(int(d.useful) * 100 % int(d.total), 0, "a whole percentage")


func test_saving_energy() -> void:
	_each("save_energy", _check_save_energy)


func _check_save_energy(ex: Dictionary, _level: int) -> void:
	assert_eq(_answer(ex), _by_phrase(SAVES, str(ex.data.question)), str(ex.prompt))


# --- Engineering design ----------------------------------------------------------------------------------------------

func _is_limit(statement: String) -> bool:
	for w in LIMIT_WORDS:
		if statement.to_lower().contains(w):
			return true
	return false


func test_criteria_and_constraints() -> void:
	_each("criteria_sort", _check_criteria_sort)


func _check_criteria_sort(ex: Dictionary, level: int) -> void:
	if level == 1:
		assert_eq(_answer(ex), "a constraint" if _is_limit(str(ex.data.statement)) else "a criterion", str(ex.prompt))
		return
	var g := _groups(ex)
	for item: String in g:
		assert_eq(g[item], "constraint" if _is_limit(item) else "criterion", item)


func test_choosing_a_design() -> void:
	_each("design_pick", _check_design_pick)


func _check_design_pick(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	var ok: Array = []
	for row: Array in d.rows:
		var meets := int(row[1]) >= int(d.need)
		if level >= 2:
			meets = meets and int(row[2]) <= int(d.budget)
		if level == 3:
			meets = meets and int(row[3]) <= 3
		if meets:
			ok.append("design %s" % row[0])
	assert_eq(ok.size(), 1, "one design meets the brief: %s" % ex.prompt)
	assert_eq(_answer(ex), ok[0], str(ex.prompt))


func test_decision_matrices() -> void:
	_each("decision_matrix", _check_decision_matrix)


func _check_decision_matrix(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	var totals: Array = []
	for s: Array in d.scores:
		var t := 0
		for c in 3:
			t += int(s[c]) * int(d.weights[c])
		totals.append(t)
	if level < 3:
		assert_eq(_num(ex), float(totals[int(d.design)]), str(ex.prompt))
	else:
		var best := 0
		for i in 3:
			if int(totals[i]) > int(totals[best]):
				best = i
		assert_eq(totals.count(totals[best]), 1, "one best design")
		assert_eq(_answer(ex), "design %s" % ["A", "B", "C"][best])


func test_repeated_trials() -> void:
	_each("trial_mean", _check_trial_mean)


func _check_trial_mean(ex: Dictionary, level: int) -> void:
	var trials: Array = ex.data.trials
	if level == 1:
		var sum := 0
		for t: Variant in trials:
			sum += int(t)
		assert_eq(_num(ex), sum / 3.0, str(ex.prompt))
		return
	var sorted := trials.duplicate()
	sorted.sort()
	var median := (float(sorted[(sorted.size() - 1) / 2]) + float(sorted[sorted.size() / 2])) / 2.0
	var odd := 0
	for i in trials.size():
		if absf(float(trials[i]) - median) > absf(float(trials[odd]) - median):
			odd = i
	for i in trials.size():
		if i != odd:
			assert_lt(absf(float(trials[i]) - median), 7.0, "the good results are close together")
	assert_gt(absf(float(trials[odd]) - median), 7.5, "the odd one is far from the rest")
	assert_eq(odd, int(ex.data.odd), "the odd one found")
	if level == 2:
		assert_eq(_answer(ex), "trial %d" % (odd + 1))
	else:
		var sum := 0
		for i in trials.size():
			if i != odd:
				sum += int(trials[i])
		assert_eq(_num(ex), sum / 3.0, str(ex.prompt))


# --- English ---------------------------------------------------------------------------------------------------------

func test_stated_or_inferred() -> void:
	_each("stated_or_inferred", _check_stated_or_inferred)


func _check_stated_or_inferred(ex: Dictionary, _level: int) -> void:
	var kind: String = _by_phrase(INFERRED, str(ex.data.statement))
	assert_eq(_answer(ex), "stated in the text" if kind == "stated" else "inferred from clues", str(ex.prompt))
	if kind == "stated":
		var text := str(ex.prompt).get_slice(" Is this", 0)
		assert_true(text.contains(str(ex.data.statement).trim_suffix(".").get_slice(" ", 1)), "a stated fact's words are in the text")


func test_the_best_evidence() -> void:
	_each("best_evidence", _check_best_evidence)


func _check_best_evidence(ex: Dictionary, _level: int) -> void:
	assert_true(_answer(ex).contains(_by_phrase(PROOF, str(ex.data.inference))), str(ex.prompt))
	for c: Variant in ex.choices:
		assert_true(str(ex.prompt).contains(str(c)), "every choice is quoted from the text: %s" % c)


func _is_story(sentence: String) -> bool:
	if sentence.contains("\""):
		return true
	for n in CHARACTERS:
		if sentence.contains(n):
			return true
	return false


func test_stories_and_information_texts() -> void:
	_each("story_or_fact", _check_story_or_fact)


func _check_story_or_fact(ex: Dictionary, level: int) -> void:
	if level == 1:
		assert_eq(_answer(ex), "a story" if _is_story(str(ex.data.sentence)) else "an information text", str(ex.prompt))
		return
	var g := _groups(ex)
	for item: String in g:
		assert_eq(g[item], "story" if _is_story(item) else "information", item)


func test_an_arguments_parts() -> void:
	_each("argument_part", _check_argument_part)


func _check_argument_part(ex: Dictionary, level: int) -> void:
	assert_eq(_answer(ex), "the %s" % _by_phrase(PART_OF, str(ex.data.sentence)), str(ex.prompt))
	assert_eq((ex.choices as Array).size(), level + 2, "choices by level")


func test_argument_linking_words() -> void:
	_each("argument_link", _check_argument_link)


func _check_argument_link(ex: Dictionary, _level: int) -> void:
	assert_eq(_answer(ex), _by_phrase(LINK, str(ex.data.sentence)), str(ex.prompt))


func _informal(t: String) -> bool:
	var low := t.to_lower()
	for w in INFORMAL:
		if w in ["'", "!"]:
			if low.contains(w):
				return true
		elif RegEx.create_from_string("\\b" + w + "\\b").search(low) != null:
			return true
	return false


func test_formal_writing() -> void:
	_each("formal_style", _check_formal_style)


func _check_formal_style(ex: Dictionary, level: int) -> void:
	if level < 3:
		for c: Variant in ex.choices:
			assert_eq(_informal(str(c)), str(c) != _answer(ex), "only the answer is formal: %s" % c)
		return
	var g := _groups(ex)
	for item: String in g:
		assert_eq(g[item], "informal" if _informal(item) else "formal", item)


func test_precise_words() -> void:
	_each("precise_word", _check_precise_word)


func _check_precise_word(ex: Dictionary, _level: int) -> void:
	assert_eq(_answer(ex), _by_phrase(PRECISE, str(ex.data.sentence)), str(ex.prompt))


func test_an_information_texts_features() -> void:
	_each("info_feature", _check_info_feature)


func _check_info_feature(ex: Dictionary, level: int) -> void:
	assert_eq(_answer(ex), _by_phrase(FEATURE, str(ex.data.job)), str(ex.prompt))
	assert_eq((ex.choices as Array).size(), level + 2, "choices by level")


func test_hooks() -> void:
	_each("hook_pick", _check_hook_pick)


func _check_hook_pick(ex: Dictionary, _level: int) -> void:
	for c: Variant in ex.choices:
		var flat := false
		for f in FLAT_STARTS:
			flat = flat or str(c).begins_with(f)
		assert_eq(flat, str(c) != _answer(ex), "only the hook is not a flat start: %s" % c)


func _sentences(t: String) -> int:
	return t.count(".") + t.count("!") + t.count("?")


func test_pace() -> void:
	_each("pace_pick", _check_pace_pick)


func _check_pace_pick(ex: Dictionary, _level: int) -> void:
	var slow := bool(ex.data.slow)
	for c: Variant in ex.choices:
		if str(c) == _answer(ex):
			continue
		if slow:   # the calm version: fewest, longest sentences
			assert_lt(_sentences(_answer(ex)), _sentences(str(c)), "%s is calmer than %s" % [_answer(ex), c])
		else:   # the tense version: the most, shortest sentences
			assert_gt(_sentences(_answer(ex)), _sentences(str(c)), "%s is tenser than %s" % [_answer(ex), c])


func test_vivid_verbs() -> void:
	_each("vivid_verb", _check_vivid_verb)


func _check_vivid_verb(ex: Dictionary, _level: int) -> void:
	assert_eq(_answer(ex), _by_phrase(VIVID, str(ex.data.sentence)), str(ex.prompt))


func test_paraphrases() -> void:
	_each("paraphrase_pick", _check_paraphrase_pick)


func _check_paraphrase_pick(ex: Dictionary, _level: int) -> void:
	var source := str(ex.data.source)
	assert_ne(_answer(ex), source, "a paraphrase is not a copy")
	var copied := false
	for c: Variant in ex.choices:
		copied = copied or str(c) == source
		assert_false(str(c) == _answer(ex) and (str(c).to_lower().contains("i think") or str(c).contains("best")
			or str(c).contains("cutest") or str(c).contains("scar")), "the paraphrase adds no opinion")
	assert_true(copied, "a copied choice to spot")
	var words := 0
	for w in source.to_lower().trim_suffix(".").split(" "):
		if w.length() > 4 and _answer(ex).to_lower().contains(w.substr(0, 4)):
			words += 1
	assert_gte(words, 2, "the paraphrase keeps the meaning (its key words): %s" % _answer(ex))


func test_trustworthy_sources() -> void:
	_each("source_trust", _check_source_trust)


func _check_source_trust(ex: Dictionary, _level: int) -> void:
	assert_true(_answer(ex).contains(_by_phrase(TRUSTED, str(ex.data.question))), str(ex.prompt))


## A to Z by surname, compared letter by letter with this test's own rule.
func _before(a: String, b: String) -> bool:
	for i in mini(a.length(), b.length()):
		if a.unicode_at(i) != b.unicode_at(i):
			return a.unicode_at(i) < b.unicode_at(i)
	return a.length() < b.length()


func test_source_lists_in_order() -> void:
	_each("cite_order", _check_cite_order)


func _check_cite_order(ex: Dictionary, level: int) -> void:
	var order := _in_order(ex)
	assert_eq(order.size(), level + 2)
	for i in order.size() - 1:
		assert_true(_before(str(order[i]).get_slice(",", 0), str(order[i + 1]).get_slice(",", 0)),
			"%s before %s" % [order[i], order[i + 1]])


func test_building_on_ideas() -> void:
	_each("build_on", _check_build_on)


func _check_build_on(ex: Dictionary, _level: int) -> void:
	assert_true(_answer(ex).contains(_by_phrase(BUILDS, str(ex.data.said))), str(ex.prompt))


func test_the_right_chart() -> void:
	_each("chart_choice", _check_chart_choice)


func _check_chart_choice(ex: Dictionary, _level: int) -> void:
	var data := str(ex.data.data)
	var want := "a bar chart"
	if data.contains("changed") or data.contains("each week") or data.contains("each month"):
		want = "a line graph"
	elif data.contains("fraction") or data.contains("share") or data.contains("split"):
		want = "a pie chart"
	assert_eq(_answer(ex), want, data)
