class_name G3ScienceGen
extends RefCounted
## Owner #70 (the grade 3 science and English agent): grade 3 science generators: SchoolGen "g3s.<name>",
## `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint, a
## worked answer and `data` (its inputs; tests/unit/test_g3_science_gen.gd works every answer out again from it).
## Units (docs/design/school-curriculum-research.md §6.3): living things, keys, life cycles, plants, traits, fossils,
## habitats, food, materials, forces, magnets, light, weather and climate, hazards, fair tests, design.

const K := preload("res://core/school/gen/gen_kit.gd")

const LIVING := "living"
const ONCE := "once living"
const NEVER := "never living"
## [thing, kind, level, why].
const THINGS: Array = [
	["a rabbit", LIVING, 1, "it feeds, grows and has young"], ["an oak tree", LIVING, 1, "it grows and makes acorns"],
	["a sunflower", LIVING, 1, "it grows and makes seeds"], ["a goldfish", LIVING, 1, "it feeds, grows and breathes"],
	["a rock", NEVER, 1, "it never fed or grew"], ["a metal spoon", NEVER, 1, "metal was never alive"],
	["a glass marble", NEVER, 1, "glass was never alive"], ["a plastic cup", NEVER, 1, "plastic was never alive"],
	["a mushroom", LIVING, 2, "it is a fungus: it feeds and grows"], ["an earthworm", LIVING, 2, "it feeds and grows"],
	["moss on a wall", LIVING, 2, "it is a small plant that grows"], ["a wooden spoon", ONCE, 2, "wood came from a tree"],
	["a fallen dry leaf", ONCE, 2, "it grew on a living tree"], ["a feather", ONCE, 2, "it grew on a living bird"],
	["a paper bag", ONCE, 2, "paper is made from trees"], ["a cotton sock", ONCE, 2, "cotton grew on a plant"],
	["a puddle of water", NEVER, 2, "water was never alive"], ["a cloud", NEVER, 2, "a cloud is only water drops"],
	["a seed in a packet", LIVING, 3, "it is resting; with water it grows"],
	["mould on old bread", LIVING, 3, "it is a fungus that feeds and grows"],
	["a leather belt", ONCE, 3, "leather is an animal's skin"], ["a bone", ONCE, 3, "it was part of a living animal"],
	["a shell on the beach", ONCE, 3, "a sea animal once lived in it"], ["a woolly jumper", ONCE, 3,
		"wool grew on a sheep"],
	["a fire", NEVER, 3, "it grows but does not feed or reproduce"], ["a robot", NEVER, 3,
		"it moves but cannot grow or reproduce"],
	["the Sun", NEVER, 3, "it shines but is not alive"], ["a snowman", NEVER, 3, "snow was never alive"],
]

## Linear keys: each step [question, feature, name when yes]; `last` is the name when every answer is no.
const KEYS: Array = [
	{"steps": [["Feathers?", "feathers", "parrot"], ["Fur?", "fur", "rabbit"], ["Fins?", "fins", "fish"]], "last": "frog"},
	{"steps": [["8 legs?", "eight legs", "spider"], ["Wings?", "wings", "bee"], ["A shell?", "a shell", "snail"]],
		"last": "worm"},
	{"steps": [["Flowers?", "flowers", "rose"], ["Fronds?", "fronds", "fern"]], "last": "moss"},
]

## Life cycles, from the start.
const CYCLES := {
	"frog": ["egg", "tadpole", "froglet", "adult frog"],
	"butterfly": ["egg", "caterpillar", "chrysalis", "butterfly"],
	"chicken": ["egg", "chick", "young hen", "adult hen"],
	"bean plant": ["seed", "seedling", "plant with flowers", "pod with seeds"],
	"ladybird": ["egg", "larva", "pupa", "adult ladybird"],
}
const EASY_CYCLES: Array[String] = ["frog", "chicken", "bean plant"]
const CYCLE_PICTURES := {"frog": {"kind": "icon", "animal": "frog"}, "chicken": {"kind": "icon", "animal": "chicken"},
	"bean plant": {"kind": "icon", "block": 260}}

## [what the part does, the part, level].
const PLANT_JOBS: Array = [
	["takes in water from the soil", "the roots", 1], ["makes food from sunlight", "the leaves", 1],
	["makes the seeds", "the flower", 1], ["holds the leaves up to the light", "the stem", 2],
	["carries water from the roots to the leaves", "the stem", 2], ["grows into a new plant", "the seed", 2],
	["holds the plant in the ground", "the roots", 3], ["brings insects with bright petals", "the flower", 3],
	["keeps the seeds safe inside it", "the fruit", 3],
]
const PLANT_PARTS: Array[String] = ["the roots", "the stem", "the leaves", "the flower", "the seed", "the fruit"]

const INHERITED := "inherited from the parents"
const SURROUNDINGS := "changed by the surroundings"
const LEARNED := "learned"
## [trait, kind, level].
const TRAITS: Array = [
	["a cat's eye colour", INHERITED, 1], ["a dog's fur colour", INHERITED, 1], ["reading a book", LEARNED, 1],
	["riding a bike", LEARNED, 1], ["a plant drooping with no water", SURROUNDINGS, 1],
	["a sunburnt nose", SURROUNDINGS, 1],
	["a zebra's stripes", INHERITED, 2], ["a parrot saying hello", LEARNED, 2], ["a dog sitting when asked", LEARNED, 2],
	["a flamingo's pink feathers", SURROUNDINGS, 2], ["a pale plant grown in the dark", SURROUNDINGS, 2],
	["a scar on a knee", SURROUNDINGS, 2],
	["a bird's beak shape", INHERITED, 3], ["a spider's eight legs", INHERITED, 3],
	["a sheepdog rounding up sheep", LEARNED, 3], ["speaking English", LEARNED, 3],
	["blue hydrangeas in some soils", SURROUNDINGS, 3], ["a tree bent over by strong winds", SURROUNDINGS, 3],
]

## What varies in a group of one kind: {kind, many, from, heading, lo, hi, unit, most, least, over (how many are over a
## size), big, small (for the difference)}.
const VARIATION: Array[Dictionary] = [
	{"kind": "Rabbit", "many": "rabbits", "from": "from one family", "heading": "Ear (cm)", "lo": 7, "hi": 12, "unit": "cm",
		"most": "has the longest ears", "least": "has the shortest ears", "over": "have ears longer than",
		"big": "the longest ears", "small": "the shortest"},
	{"kind": "Sunflower", "many": "sunflowers", "from": "from one seed packet", "heading": "Height (cm)", "lo": 140, "hi": 200, "unit": "cm",
		"most": "is the tallest", "least": "is the shortest", "over": "are taller than",
		"big": "the tallest sunflower", "small": "the shortest"},
	{"kind": "Fish", "many": "fish", "from": "of one kind", "heading": "Length (cm)", "lo": 10, "hi": 25, "unit": "cm",
		"most": "is the longest", "least": "is the shortest", "over": "are longer than",
		"big": "the longest fish", "small": "the shortest"},
	{"kind": "Puppy", "many": "puppies", "from": "from one litter", "heading": "Mass (kg)", "lo": 2, "hi": 9, "unit": "kg",
		"most": "is the heaviest", "least": "is the lightest", "over": "are heavier than",
		"big": "the heaviest puppy", "small": "the lightest"},
]

## Fossils and the place they tell of.
const FOSSIL_PLACE := {"fish": "under the sea", "shell": "under the sea", "leaf": "land with plants"}
const CLIFF: Array[int] = [17, 3, 64, 4, 2]

## Habitats: what survives well there, and what cannot survive there at all.
const HABITATS := {
	"a hot desert": {"well": ["a camel", "a cactus", "a fennec fox", "a scorpion"],
		"not": ["a shark", "an octopus", "a water lily", "a jellyfish", "a polar bear"]},
	"the icy polar lands": {"well": ["a polar bear", "a penguin", "an arctic fox", "a seal"],
		"not": ["a cactus", "a sloth", "a toucan", "an orchid", "a jaguar"]},
	"the sea": {"well": ["a shark", "an octopus", "a jellyfish", "a whale"],
		"not": ["a camel", "a cactus", "a sloth", "a toucan", "a fennec fox"]},
	"a pond": {"well": ["a frog", "a water lily", "a tadpole", "a duck"],
		"not": ["a camel", "a cactus", "an octopus", "a shark", "a scorpion"]},
	"a rainforest": {"well": ["a sloth", "a toucan", "a jaguar", "an orchid"],
		"not": ["a shark", "an octopus", "a jellyfish", "a polar bear", "a penguin"]},
}

const STARCHY := "starchy food: energy"
const PROTEIN := "protein: growing and repair"
const FRUIT_VEG := "fruit and vegetables: vitamins"
const DAIRY := "dairy: strong bones and teeth"
## [food, group, level].
const FOODS: Array = [
	["bread", STARCHY, 1], ["pasta", STARCHY, 1], ["eggs", PROTEIN, 1], ["apples", FRUIT_VEG, 1], ["milk", DAIRY, 1],
	["carrots", FRUIT_VEG, 1],
	["rice", STARCHY, 2], ["potatoes", STARCHY, 2], ["fish", PROTEIN, 2], ["beans", PROTEIN, 2], ["cheese", DAIRY, 2],
	["bananas", FRUIT_VEG, 2],
	["porridge oats", STARCHY, 3], ["lentils", PROTEIN, 3], ["chicken", PROTEIN, 3], ["yoghurt", DAIRY, 3],
	["broccoli", FRUIT_VEG, 3], ["oranges", FRUIT_VEG, 3],
]

## {job, material, wrongs (materials no good for it), property, not (properties it does not have), level}.
const JOBS: Array[Dictionary] = [
	{"job": "a window", "material": "glass", "wrongs": ["wood", "brick", "cotton"], "level": 1,
		"property": "it is transparent", "not": ["it is bendy", "it soaks up water"]},
	{"job": "a raincoat", "material": "waterproof plastic", "wrongs": ["paper", "cotton wool", "glass"], "level": 1,
		"property": "it is waterproof", "not": ["it soaks up water", "it is magnetic"]},
	{"job": "a towel", "material": "cotton", "wrongs": ["plastic", "glass", "metal"], "level": 1,
		"property": "it soaks up water", "not": ["it is waterproof", "it is transparent"]},
	{"job": "a car tyre", "material": "rubber", "wrongs": ["glass", "paper", "wood"], "level": 1,
		"property": "it is bendy and grips", "not": ["it is transparent", "it soaks up water"]},
	{"job": "a saucepan", "material": "metal", "wrongs": ["paper", "plastic", "wool"], "level": 2,
		"property": "it is strong and lets heat through", "not": ["it soaks up water", "it is bendy"]},
	{"job": "a pair of wellies", "material": "rubber", "wrongs": ["cotton", "paper", "glass"], "level": 2,
		"property": "it is waterproof and bendy", "not": ["it soaks up water", "it is transparent"]},
	{"job": "a spoon to stir a hot pan", "material": "wood", "wrongs": ["paper", "ice", "chocolate"], "level": 2,
		"property": "heat passes through it slowly", "not": ["it is transparent", "it soaks up water"]},
	{"job": "a bridge over a river", "material": "steel", "wrongs": ["paper", "cotton", "chocolate"], "level": 3,
		"property": "it is very strong", "not": ["it soaks up water", "it is soft"]},
	{"job": "curtains that keep out light", "material": "thick fabric", "wrongs": ["clear glass", "clear plastic",
		"thin paper"], "level": 3, "property": "it is opaque", "not": ["it is transparent", "it is magnetic"]},
	{"job": "a fish tank", "material": "glass", "wrongs": ["wood", "cotton", "paper"], "level": 3,
		"property": "it is transparent and waterproof", "not": ["it soaks up water", "it is bendy"]},
]

## Surfaces, the least friction first: a toy car rolls furthest on the first.
const SURFACES: Array[String] = ["ice", "wood", "carpet", "grass", "sand"]

## Magnetic things and things a magnet does not pull (level 3: metals that are not magnetic).
const MAGNETIC: Array[String] = ["an iron nail", "a steel paper clip", "a steel pin", "iron filings", "an iron pan",
	"an iron bar"]
const NOT_MAGNETIC: Array[String] = ["a wooden spoon", "a plastic ruler", "a glass marble", "a rubber band",
	"a paper cup", "a cotton sock"]
const NOT_MAGNETIC_METALS: Array[String] = ["an aluminium can", "a copper wire", "a gold ring", "a silver spoon",
	"aluminium foil"]

## Shadows: a 10 cm toy between a torch and a wall 100 cm away: shadow height = 10 × 100 ÷ distance.
const SHADOW_DISTANCES: Array[int] = [10, 20, 25, 50]
const WALL := 100
const TOY := 10

const DAYS: Array[String] = ["Mon", "Tue", "Wed", "Thu", "Fri"]
const DAY_NAMES := {"Mon": "Monday", "Tue": "Tuesday", "Wed": "Wednesday", "Thu": "Thursday", "Fri": "Friday"}

## Climates: [name, summer °C range, winter °C range, rain a year (tens of mm) range, descriptions].
const CLIMATES: Array = [
	["a hot desert", [34, 42], [14, 22], [1, 20], ["It is hot and very dry nearly all year.",
		"Days are baking hot, and rain hardly ever falls."]],
	["a tropical rainforest", [25, 28], [24, 27], [200, 350], ["It is hot and wet all year, with rain most days.",
		"It is warm every month, and heavy rain falls almost every day."]],
	["a polar climate", [-5, 2], [-40, -20], [2, 20], ["It is freezing cold all year, with ice everywhere.",
		"Winters are long and dark, and even summer is below freezing."]],
	["a mild climate", [16, 22], [2, 8], [60, 100], ["Summers are warm, winters are cool, and it rains in every "
		+ "season.", "It is never very hot or very cold, and rain falls all year."]],
]

## Weather hazards: designs that help, and designs that do not help with that hazard.
const HAZARDS := {
	"a flood": {"level": 1, "help": ["a flood wall", "houses on stilts", "sandbags"],
		"no": ["a lightning rod", "a snow plough", "a sun hat"]},
	"a thunderstorm": {"level": 1, "help": ["a lightning rod"], "no": ["sandbags", "a snow plough", "a reservoir"]},
	"a drought": {"level": 2, "help": ["a reservoir", "a rainwater tank"],
		"no": ["a lightning rod", "a flood wall", "a snow plough", "storm shutters"]},
	"a heatwave": {"level": 2, "help": ["shady trees", "drinking water fountains"],
		"no": ["a snow plough", "a lightning rod", "sandbags"]},
	"a blizzard": {"level": 2, "help": ["a snow plough", "grit on the roads"],
		"no": ["a lightning rod", "sandbags", "a sun hat"]},
	"a hurricane": {"level": 3, "help": ["storm shutters", "a storm shelter", "roof straps"],
		"no": ["a reservoir", "a sun hat", "a snow plough"]},
}

const LENGTH := "length"
const MASS := "mass"
const HEAT := "temperature"
const TIME := "time"
const LIQUID := "liquid"
const TOOLS := {LENGTH: "a ruler", MASS: "scales", HEAT: "a thermometer", TIME: "a stopwatch", LIQUID: "a measuring jug"}
const KIND_WORDS := {LENGTH: "a length", MASS: "a mass", HEAT: "a temperature", TIME: "a time",
	LIQUID: "an amount of liquid"}
const UNITS := {LENGTH: "centimetres (cm)", MASS: "grams (g)", HEAT: "degrees Celsius (°C)", TIME: "seconds",
	LIQUID: "millilitres (mL)"}
## [what to measure, kind, level].
const MEASURES: Array = [
	["how long a pencil is", LENGTH, 1], ["how heavy an apple is", MASS, 1], ["how hot the bath water is", HEAT, 1],
	["how long a race takes", TIME, 1], ["how much water is in a cup", LIQUID, 1],
	["how long a worm is", LENGTH, 2], ["how heavy a bag of flour is", MASS, 2], ["how cold a freezer is", HEAT, 2],
	["how long an egg takes to boil", TIME, 2], ["how much juice is in a jug", LIQUID, 2],
	["how wide a book is", LENGTH, 3], ["how heavy a hamster is", MASS, 3], ["how warm the classroom is", HEAT, 3],
	["how long a candle burns", TIME, 3], ["how much milk is in a bottle", LIQUID, 3],
]


# --- Living and non-living (SG P3, UK Y4) ------------------------------------------------------------------------

## "Is it living, once living, or never living?  a wooden spoon"
static func living_or_not(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick(rng, THINGS, level, 2)
	var thing: String = row[0]
	var kind: String = row[1]
	var ex := K.choice(rng, "Is it living, once living, or never living?  %s" % _cap(thing), kind,
		[LIVING, ONCE, NEVER].filter(func(k: String) -> bool: return k != kind),
		"Does it feed, grow and reproduce now? If not, did it come from something that was alive?",
		"%s is %s: %s." % [_cap(thing), kind, row[3]])
	ex.data = {"thing": thing, "kind": kind}
	return ex


# --- Sorting with keys (UK Y4, SG P3) ----------------------------------------------------------------------------

## "Use the key. It has no feathers and no fur, but it has fins. What is it?" (the key as a table)
static func key_walk(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var k := rng.randi_range(0, KEYS.size() - 1)
	var key: Dictionary = KEYS[k]
	var steps: Array = key.steps
	var names: Array = []
	for s: Array in steps:
		names.append(s[2])
	names.append(key.last)
	# level 1: named at the first or second question; 2: a later one; 3: the last name (every answer no)
	var at: int
	if level == 1:
		at = rng.randi_range(0, mini(1, steps.size() - 1))
	elif level == 2:
		at = rng.randi_range(1, steps.size() - 1)
	else:
		at = steps.size()
	var answer: String = names[at]
	var features: Array = []
	var parts: Array[String] = []
	for i in mini(at, steps.size()):
		parts.append("no %s" % steps[i][1])
	var told: String
	if at < steps.size():
		features.append(steps[at][1])
		told = "It has %s, but it has %s." % [_list(parts), steps[at][1]] if not parts.is_empty() \
			else "It has %s." % steps[at][1]
	else:
		told = "It has %s." % _list(parts)
	var rows: Array = [["Question", "Yes", "No"]]
	for i in steps.size():
		var no: String = "go to %d" % (i + 2) if i < steps.size() - 1 else str(key.last)
		rows.append(["%d %s" % [i + 1, steps[i][0]], steps[i][2], no])
	var ex := K.choice(rng, "Use the key. %s What is it?" % told, answer,
		names.filter(func(n: String) -> bool: return n != answer),
		"Start at question 1. Answer yes or no, and follow the key until it names the living thing.",
		"Following the key question by question, the answers lead to the %s." % answer,
		{"kind": "table", "rows": rows})
	ex.data = {"key": k, "features": features}
	return ex


# --- Life cycles (3-LS1-1) ---------------------------------------------------------------------------------------

## "Put a frog's life cycle in order, from the start." (level 1: the first three stages of an easy cycle)
static func life_cycle_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var animal := _cycle(rng, level)
	var stages: Array = (CYCLES[animal] as Array).slice(0, 3 if level == 1 else 4)
	var ex := K.order(rng, "Put a %s's life cycle in order, from the start." % animal, stages,
		"What does the life cycle start as? What does that grow into?", "%s." % _cap(", ".join(stages)),
		CYCLE_PICTURES.get(animal, {}))
	ex.data = {"animal": animal, "stages": stages}
	return ex


## "In a butterfly's life cycle, what comes after the caterpillar?" (level 3: what comes before)
static func life_cycle_next(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var animal := _cycle(rng, level)
	var stages: Array = CYCLES[animal]
	var before := level == 3
	var i := rng.randi_range(1, stages.size() - 1) if before else rng.randi_range(0, stages.size() - 2)
	var right: String = stages[i - 1] if before else stages[i + 1]
	var given: String = stages[i]
	var ex := K.choice(rng, "In a %s's life cycle, what comes %s the %s?" % [animal, "before" if before else "after",
		given], right, stages.filter(func(s: String) -> bool: return s != right and s != given),
		"Say the whole life cycle in order, from the start.", "%s: %s." % [_cap(animal), ", ".join(stages)])
	ex.data = {"animal": animal, "stage": given, "before": before}
	return ex


# --- Plants (UK Y3) ----------------------------------------------------------------------------------------------

## "Which part of a plant takes in water from the soil?"
static func plant_part(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick(rng, PLANT_JOBS, level, 1)
	var part: String = row[1]
	var wrongs: Array = PLANT_PARTS.filter(func(p: String) -> bool: return p != part)
	K.shuffle(rng, wrongs)
	var ex := K.choice(rng, "Which part of a plant %s?" % row[0], part, wrongs.slice(0, 3),
		"Picture a plant from the roots up. Where does this job happen?", "%s %s." % [_cap(part), _verb(part, row[0])],
		{"kind": "icon", "block": 260})
	ex.data = {"job": row[0], "part": part}
	return ex


# --- Traits (3-LS3-1, 3-LS3-2) -----------------------------------------------------------------------------------

## "Where does this trait come from?  a zebra's stripes" (inherited, changed by the surroundings, or learned)
static func trait_kind(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick(rng, TRAITS, level, 1)
	var kind: String = row[1]
	var ex := K.choice(rng, "Where does this trait come from?  %s" % _cap(str(row[0])), kind,
		[INHERITED, SURROUNDINGS, LEARNED].filter(func(k: String) -> bool: return k != kind),
		"Was it born with it, did the world around it change it, or did it have to practise?",
		"%s: %s." % [_cap(str(row[0])), kind])
	ex.data = {"trait": row[0], "kind": kind}
	return ex


## A table of four of one kind (A-D): which is biggest (1), smallest or how many are over a size (2), the difference
## between the biggest and the smallest (3).
static func variation_table(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var kind: Dictionary = VARIATION[rng.randi_range(0, VARIATION.size() - 1)]
	var values: Array = []
	while values.size() < 4:
		var v := rng.randi_range(int(kind.lo), int(kind.hi))
		if not values.has(v):
			values.append(v)
	var names: Array = ["A", "B", "C", "D"]
	var rows: Array = [[kind.kind, kind.heading]]
	for i in 4:
		rows.append([names[i], str(values[i])])
	var picture := {"kind": "table", "rows": rows}
	var most: int = values.max()
	var least: int = values.min()
	var unit := str(kind.unit)
	var ex: Dictionary
	var ask: String
	var line := 0
	if level == 1 or (level == 2 and rng.randf() < 0.3):
		ask = "most"
		var right: String = names[values.find(most)]
		ex = K.choice(rng, "Four %s %s. Which one %s?" % [kind.many, kind.from, kind.most], right,
			names.filter(func(n: String) -> bool: return n != right), "Find the biggest number in the table.",
			"%s is %d %s, the biggest number." % [right, most, unit], picture)
	elif level == 2 and rng.randf() < 0.5:
		ask = "least"
		var right: String = names[values.find(least)]
		ex = K.choice(rng, "Four %s %s. Which one %s?" % [kind.many, kind.from, kind.least], right,
			names.filter(func(n: String) -> bool: return n != right), "Find the smallest number in the table.",
			"%s is %d %s, the smallest number." % [right, least, unit], picture)
	elif level == 2:
		ask = "over"
		var sorted := values.duplicate()
		sorted.sort()
		line = sorted[rng.randi_range(0, 2)]
		var over := values.filter(func(v: int) -> bool: return v > line).size()
		ex = K.number("How many of the %s %s %d %s?" % [kind.many, kind.over, line, unit], over,
			"Check each number: is it bigger than %d?" % line, "%d of them are more than %d %s." % [over, line, unit],
			picture)
	else:
		ask = "range"
		ex = K.number("What is the difference between %s and %s? (%s)" % [kind.big, kind.small, unit], most - least,
			"Find the biggest and the smallest numbers, then take away.",
			"%d − %d = %d %s. Living things of one kind vary!" % [most, least, most - least, unit], picture)
	ex.data = {"values": values, "ask": ask, "line": line}
	return ex


# --- Fossils (3-LS4-1) --------------------------------------------------------------------------------------------

## Level 1: one fossil: what was the place like? 2: which of two fossils is older? 3: two layers: what changed?
static func fossil_clue(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var kinds: Array = FOSSIL_PLACE.keys()
	var ex: Dictionary
	if level == 1:
		var kind: String = kinds[rng.randi_range(0, kinds.size() - 1)]
		var layer := rng.randi_range(1, 3)
		var place: String = FOSSIL_PLACE[kind]
		ex = K.choice(rng, "This rock layer has %s fossils. What was the place like when the layer formed?" % kind,
			place, ["under the sea", "land with plants", "under thick ice"].filter(func(p: String) -> bool:
				return p != place), "Where does a %s live or grow?" % kind,
			"A %s fossil shows the place was %s." % [kind, place], {"kind": "layers", "blocks": CLIFF,
				"fossils": {str(layer): kind}})
		ex.data = {"fossils": {str(layer): kind}, "ask": "place"}
		return ex
	var sea: Array = ["fish", "shell"]
	var low := rng.randi_range(0, 2)
	var high := rng.randi_range(low + 1, 4)
	if level == 2:
		var a: String = kinds[rng.randi_range(0, kinds.size() - 1)]
		var b: String = kinds.filter(func(k: String) -> bool: return k != a)[rng.randi_range(0, 1)]
		ex = K.choice(rng, "Which fossil is older?", "the %s" % a, ["the %s" % b],
			"Rock layers pile up, so deeper layers are usually older.",
			"The %s is in a lower layer, so it is older than the %s." % [a, b], {"kind": "layers", "blocks": CLIFF,
				"fossils": {str(low): a, str(high): b}, "labels": true})
		ex.data = {"fossils": {str(low): a, str(high): b}, "ask": "older"}
		return ex
	var sea_first := rng.randf() < 0.5
	var sea_kind: String = sea[rng.randi_range(0, 1)]
	var lower: String = sea_kind if sea_first else "leaf"
	var upper: String = "leaf" if sea_first else sea_kind
	var right := "The sea became land" if sea_first else "The land became sea"
	ex = K.choice(rng, "The lower layer has %s fossils, and a higher layer has %s fossils. What changed?" % [lower,
		upper], right, ["The sea became land", "The land became sea", "Nothing changed"].filter(
			func(c: String) -> bool: return c != right),
		"Which layer is older? What lived there, and what lived there later?",
		"The older, lower layer shows %s; the newer one shows %s. %s." % [FOSSIL_PLACE[lower], FOSSIL_PLACE[upper],
			right], {"kind": "layers", "blocks": CLIFF, "fossils": {str(low): lower, str(high): upper}})
	ex.data = {"fossils": {str(low): lower, str(high): upper}, "ask": "change"}
	return ex


# --- Habitats (3-LS4-3) ------------------------------------------------------------------------------------------

## "Which one survives well in a hot desert?" (level 3: true or false for one living thing)
static func habitat_fit(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var places: Array = HABITATS.keys()
	var place: String = places[rng.randi_range(0, places.size() - 1)]
	var well: Array = HABITATS[place].well
	var nots: Array = (HABITATS[place].not as Array).duplicate()
	K.shuffle(rng, nots)
	var right: String = well[rng.randi_range(0, well.size() - 1)]
	var ex: Dictionary
	if level < 3:
		ex = K.choice(rng, "Which one survives well in %s?" % place, right, nots.slice(0, level + 1),
			"Think about what each one needs: water or dry land, heat or cold.",
			"%s survives well in %s. The others could not live there." % [_cap(right), place])
		ex.data = {"place": place, "thing": right, "fits": true}
		return ex
	var fits := rng.randf() < 0.5
	var thing: String = right if fits else str(nots[0])
	ex = K.truefalse("%s can survive well in %s." % [_cap(thing), place], fits,
		"What does it need to live? Does %s give it that?" % place,
		"%s %s in %s." % [_cap(thing), "survives well" if fits else "cannot survive", place])
	ex.data = {"place": place, "thing": thing, "fits": fits}
	return ex


# --- Food (UK Y3 animals including humans) -----------------------------------------------------------------------

## "Which food group are eggs in, and what do they do for you?"
static func food_group(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick(rng, FOODS, level, 1)
	var group: String = row[1]
	var ex := K.choice(rng, "Which food group is this in, and what does it do for you?  %s" % _cap(str(row[0])), group,
		[STARCHY, PROTEIN, FRUIT_VEG, DAIRY].filter(func(g: String) -> bool: return g != group),
		"Is it starchy, is it meat, fish, eggs or beans, is it a fruit or vegetable, or is it made from milk?",
		"%s: %s." % [_cap(str(row[0])), group])
	ex.data = {"food": row[0], "group": group}
	return ex


# --- Materials (SG P3) -------------------------------------------------------------------------------------------

## "Which material is best for a window?" (level 3: which property makes it good)
static func material_job(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = []
	for row: Dictionary in JOBS:
		if int(row.level) <= level:
			pool.append(row)
			if int(row.level) == level:
				pool.append(row)
	var row: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	var ex: Dictionary
	if level < 3 or rng.randf() < 0.5:
		ex = K.choice(rng, "Which material is best for %s?" % row.job, str(row.material), row.wrongs,
			"What must %s do? Which material has that property?" % row.job,
			"%s is best for %s, because %s." % [_cap(str(row.material)), row.job, row.property])
		ex.data = {"job": row.job, "ask": "material", "answer": row.material}
	else:
		ex = K.choice(rng, "Why is %s good for %s?" % [row.material, row.job], str(row.property), row.not,
			"Think about what %s must do." % row.job, "%s is good for %s because %s." % [_cap(str(row.material)),
			row.job, row.property])
		ex.data = {"job": row.job, "ask": "property", "answer": row.property}
	return ex


# --- Forces (3-PS2-1, 3-PS2-2, UK Y3) ----------------------------------------------------------------------------

## "Tug of war: 4 friends pull left and 3 friends of the same strength pull right. What happens?"
static func tug_of_war(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var top := 4 if level == 1 else 8
	var left := rng.randi_range(1, top)
	var right := rng.randi_range(1, top)
	if rng.randf() < 0.3:
		right = left
	var joined := 0
	var side := ""
	var prompt: String
	if level == 3:
		left = rng.randi_range(2, 6)
		right = left
		joined = rng.randi_range(0, 2)
		side = "left" if rng.randf() < 0.5 else "right"
		prompt = "Tug of war: %d friends pull left and %d pull right, all just as strong. %s" % [left, right,
			"Nobody else joins. What happens?" if joined == 0 else "%s the %s. What happens?" % [
				"1 more friend joins" if joined == 1 else "%d more friends join" % joined, side]]
	else:
		prompt = "Tug of war: %s left and %s right, all just as strong. What happens?" % [_pull(left), _pull(right)]
	var l := left + (joined if side == "left" else 0)
	var r := right + (joined if side == "right" else 0)
	var result := "The rope stays still" if l == r else ("The rope moves left" if l > r else "The rope moves right")
	var ex := K.choice(rng, prompt, result, ["The rope moves left", "The rope moves right", "The rope stays still"
		].filter(func(c: String) -> bool: return c != result),
		"Count the friends on each side. Are the forces balanced or unbalanced?",
		"%d against %d: %s. %s." % [l, r, "balanced forces" if l == r else "unbalanced forces", result])
	ex.data = {"left": l, "right": r}
	return ex


## A toy car rolled on different surfaces: which has the most or the least friction (1-2), or how much further (3).
static func surface_test(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var idx: Array = range(SURFACES.size())
	K.shuffle(rng, idx)
	var chosen: Array = idx.slice(0, 3 if level == 1 else 4)
	chosen.sort()   # the least friction first
	var names: Array = []
	var dist: Array = []
	var d := rng.randi_range(24, 32) * 5
	for i: int in chosen:
		names.append(SURFACES[i])
		dist.append(d)
		d -= rng.randi_range(3, 6) * 5   # at least 120 − 3 × 30 = 30 cm: every distance different
	var rows: Array = [["Surface", "Rolled"]]
	var shown: Array = range(names.size())
	K.shuffle(rng, shown)
	for i: int in shown:
		rows.append([names[i], "%d cm" % dist[i]])
	var picture := {"kind": "table", "rows": rows}
	var ex: Dictionary
	if level < 3:
		var most := rng.randf() < 0.5
		var right: String = names[names.size() - 1] if most else names[0]
		ex = K.choice(rng, "A toy car rolled on each surface. Which surface has the %s friction?" % ("most" if most
			else "least"), right, names.filter(func(n: String) -> bool: return n != right),
			"More friction slows the car sooner, so it rolls a shorter way.",
			"The car rolled %s on %s, so it has the %s friction." % ["least far" if most else "furthest", right,
			"most" if most else "least"], picture)
		ex.data = {"surfaces": names, "cm": dist, "ask": "most" if most else "least"}
		return ex
	var a := rng.randi_range(0, names.size() - 2)
	var b := rng.randi_range(a + 1, names.size() - 1)
	ex = K.number("How much further did the car roll on %s than on %s? (cm)" % [names[a], names[b]],
		int(dist[a]) - int(dist[b]), "Find both distances in the table, then take away.",
		"%d − %d = %d cm. %s has less friction than %s." % [dist[a], dist[b], int(dist[a]) - int(dist[b]),
		_cap(str(names[a])), names[b]], picture)
	ex.data = {"surfaces": names, "cm": dist, "ask": "further", "a": a, "b": b}
	return ex


## "A swing is at the back at 0, 2 and 4 seconds. When will it next be at the back?" (level 3: swings in a time)
static func motion_next(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var period := rng.randi_range(2, 3 if level == 1 else 5)
	var ex: Dictionary
	if level == 3:
		var swings := rng.randi_range(2, 6)
		var total := period * swings
		ex = K.number(("A pendulum takes %d seconds to swing there and back. How many times does it swing there and "
			+ "back in %d seconds?") % [period, total], swings, "How many %ds make %d?" % [period, total],
			"%d ÷ %d = %d swings there and back." % [total, period, swings])
		ex.data = {"period": period, "total": total, "ask": "swings"}
		return ex
	var start := 0 if level == 1 else rng.randi_range(1, 4)
	var what: Array = [["swing", "at the back", "at the back"], ["pendulum", "on the left", "on the left"],
		["seesaw", "down on Zara's side", "Zara down"]]
	var pick: Array = what[rng.randi_range(0, what.size() - 1)]
	var times: Array = [start, start + period, start + 2 * period]
	var next := start + 3 * period
	var rows: Array = [["Time", "Where"]]
	for t: int in times:
		rows.append(["%d s" % t, pick[2]])
	rows.append(["?", pick[2]])
	ex = K.number("A %s is %s at %d, %d and %d seconds. When will it next be there? (seconds)" % [pick[0], pick[1],
		times[0], times[1], times[2]], next, "How many seconds between each time?",
		"It comes back every %d seconds: %d + %d = %d seconds." % [period, times[2], period, next],
		{"kind": "table", "rows": rows})
	ex.data = {"start": start, "period": period, "ask": "next"}
	return ex


# --- Magnets (3-PS2-3, 3-PS2-4) ----------------------------------------------------------------------------------

## "Magnet A's N pole faces magnet B's S pole. What happens?" (level 3: B is turned round first)
static func magnet_poles(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := "N" if rng.randf() < 0.5 else "S"
	var b := "N" if rng.randf() < 0.5 else "S"
	var turned := level == 3
	var facing := ("S" if b == "N" else "N") if turned else b
	var pull := a != facing
	var right := "They pull together" if pull else "They push apart"
	var prompt: String
	if level == 1:
		prompt = "A %s pole faces a %s pole. What happens?" % [_pole(a), _pole(b)]
	elif level == 2:
		prompt = "Magnet A's %s pole is next to magnet B's %s pole. What happens?" % [_pole(a), _pole(b)]
	else:
		prompt = "Magnet A's %s pole faces magnet B's %s pole. Bram turns magnet B round. What happens now?" % [
			_pole(a), _pole(b)]
	var ex := K.choice(rng, prompt, right, ["They pull together", "They push apart", "Nothing happens"].filter(
		func(c: String) -> bool: return c != right), "Unlike poles attract; like poles repel.",
		"%s faces %s: %s, so %s." % [a, facing, "unlike poles" if pull else "like poles", right.to_lower()])
	ex.data = {"a": a, "b": b, "turned": turned}
	return ex


## "Which one would a magnet pull?" (level 2: true or false; level 3: which metal thing)
static func magnetic_or_not(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var yes: Array = MAGNETIC.duplicate()
	var no: Array = NOT_MAGNETIC_METALS.duplicate() if level == 3 else NOT_MAGNETIC.duplicate()
	K.shuffle(rng, yes)
	K.shuffle(rng, no)
	var ex: Dictionary
	if level == 2:
		var pulled := rng.randf() < 0.5
		var thing: String = yes[0] if pulled else no[0]
		ex = K.truefalse("A magnet would pull %s." % thing, pulled, "Is it made of iron or steel?",
			"%s %s." % [_cap(thing), "is magnetic: it has iron in it" if pulled else "is not magnetic"])
		ex.data = {"things": [thing], "magnetic": [pulled]}
		return ex
	ex = K.choice(rng, "Which %s would a magnet pull?" % ("metal thing" if level == 3 else "one"), yes[0],
		no.slice(0, 3), "Magnets pull things made of iron or steel. %s" % ("Not every metal is magnetic!" if level == 3
			else ""), "%s is magnetic. %s" % [_cap(str(yes[0])), "Aluminium, copper, gold and silver are not."
			if level == 3 else "The others are not."])
	ex.hint = str(ex.hint).strip_edges()
	ex.data = {"things": [yes[0]] + no.slice(0, 3), "magnetic": [true, false, false, false]}
	return ex


# --- Light and shadows (UK Y3) ------------------------------------------------------------------------------------

## A toy between a torch and a wall: is the shadow bigger or smaller (1), where is it biggest (2), order (3).
static func shadow_size(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ds: Array = SHADOW_DISTANCES.duplicate()
	K.shuffle(rng, ds)
	var ex: Dictionary
	if level == 1:
		var from: int = ds[0]
		var to: int = ds[1]
		var right := "bigger" if to < from else "smaller"
		ex = K.choice(rng, "Zara's toy is %d cm from a torch. She moves it to %d cm from the torch. What happens to "
			% [from, to] + "its shadow?", "It gets %s" % right, ["It gets bigger", "It gets smaller",
			"It stays the same"].filter(func(c: String) -> bool: return c != "It gets %s" % right),
			"Is the toy moving closer to the torch, or further away?",
			"The toy moves %s the torch, so its shadow gets %s." % ["closer to" if to < from else "further from",
			right])
		ex.data = {"distances": [from, to], "ask": "change"}
		return ex
	var chosen: Array = ds.slice(0, 3)
	if level == 2:
		var near: int = chosen.min()
		var rows: Array = [["Toy from torch", "Shadow"]]
		for d: int in chosen:
			rows.append(["%d cm" % d, "%d cm" % _shadow(d)])
		ex = K.choice(rng, "Where does the toy make the biggest shadow?", "%d cm from the torch" % near,
			chosen.filter(func(d: int) -> bool: return d != near).map(func(d: int) -> String:
				return "%d cm from the torch" % d), "Closer to the torch, the toy blocks more light.",
			"At %d cm, the closest, the shadow is %d cm tall: the biggest." % [near, _shadow(near)],
			{"kind": "table", "rows": rows})
		ex.data = {"distances": chosen, "ask": "biggest"}
		return ex
	var sorted := chosen.duplicate()
	sorted.sort()
	ex = K.order(rng, "Put the toy's places in order, from the biggest shadow to the smallest.", sorted.map(
		func(d: int) -> String: return "%d cm from the torch" % d), "The closer to the torch, the bigger the shadow.",
		"Closest first: %s." % ", ".join(sorted.map(func(d: int) -> String: return "%d cm" % d)))
	ex.data = {"distances": chosen, "ask": "order"}
	return ex


# --- Weather and climate (3-ESS2-1, 3-ESS2-2) ---------------------------------------------------------------------

## A week's weather table: the warmest or coldest day (1), the rain in all or the dry days (2), the difference
## between the warmest and the coldest (3).
static func weather_table(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := 4 if level < 3 else 5
	var temps: Array = []
	while temps.size() < n:
		var t := rng.randi_range(4, 28)
		if not temps.has(t):
			temps.append(t)
	var rain: Array = []
	for i in n:
		rain.append(0 if rng.randf() < 0.35 else rng.randi_range(1, 15))
	var days: Array = DAYS.slice(0, n)
	var rows: Array = [["Day", "Temp", "Rain"]]
	for i in n:
		rows.append([days[i], "%d °C" % temps[i], "%d mm" % rain[i]])
	var picture := {"kind": "table", "rows": rows}
	var ex: Dictionary
	var ask: String
	var hot: int = temps.max()
	var cold: int = temps.min()
	if level == 1:
		var warm := rng.randf() < 0.5
		var t: int = hot if warm else cold
		var day: String = DAY_NAMES[days[temps.find(t)]]
		ask = "warmest" if warm else "coldest"
		ex = K.choice(rng, "Which day was the %s?" % ask, day, days.filter(func(d: String) -> bool:
			return DAY_NAMES[d] != day).map(func(d: String) -> String: return DAY_NAMES[d]),
			"Find the %s temperature in the table." % ("biggest" if warm else "smallest"),
			"%s was %d °C, the %s." % [day, t, ask], picture)
	elif level == 2 and rng.randf() < 0.5:
		ask = "rain"
		var total := 0
		for r: int in rain:
			total += r
		ex = K.number("How much rain fell in all these days together? (mm)", total, "Add up the rain column.",
			"%s = %d mm." % [" + ".join(rain.map(func(r: int) -> String: return str(r))), total], picture)
	elif level == 2:
		ask = "dry"
		var dry := rain.filter(func(r: int) -> bool: return r == 0).size()
		ex = K.number("How many days had no rain at all?", dry, "Count the days with 0 mm of rain.",
			"%d of the days had 0 mm of rain." % dry, picture)
	else:
		ask = "difference"
		ex = K.number("What is the difference between the warmest and the coldest day? (°C)", hot - cold,
			"Find the biggest and the smallest temperatures, then take away.",
			"%d °C − %d °C = %d °C." % [hot, cold, hot - cold], picture)
	ex.data = {"days": days, "temps": temps, "rain": rain, "ask": ask}
	return ex


## "Which climate is it?" from a description (1) or a table of a place's usual weather (2: three choices, 3: four).
static func climate_clue(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var c: Array = CLIMATES[rng.randi_range(0, CLIMATES.size() - 1)]
	var name: String = c[0]
	var others: Array = CLIMATES.map(func(x: Array) -> String: return x[0]).filter(func(x: String) -> bool:
		return x != name)
	K.shuffle(rng, others)
	var ex: Dictionary
	if level == 1:
		var lines: Array = c[4]
		ex = K.choice(rng, "%s Which climate is it?" % lines[rng.randi_range(0, lines.size() - 1)], name,
			others.slice(0, 2), "Is it hot or cold? Wet or dry?", "That is %s." % name)
		ex.data = {"climate": name}
		return ex
	var summer := rng.randi_range(int(c[1][0]), int(c[1][1]))
	var winter := rng.randi_range(int(c[2][0]), int(c[2][1]))
	var rain := rng.randi_range(int(c[3][0]), int(c[3][1])) * 10
	var rows: Array = [["Place", "Usual weather"], ["Summer", _temp(summer)], ["Winter", _temp(winter)],
		["Rain a year", "%s mm" % K.fmt(rain)]]
	ex = K.choice(rng, "This is a place's usual weather. Which climate does it have?", name,
		others.slice(0, 2 if level == 2 else 3),
		"Look at the temperatures first, then the rain. Deserts get less than 250 mm of rain a year.",
		"%s summers, %s winters and %s mm of rain a year: %s." % [_temp(summer), _temp(winter), K.fmt(rain), name],
		{"kind": "table", "rows": rows})
	ex.data = {"climate": name, "summer": summer, "winter": winter, "rain": rain}
	return ex


# --- Weather hazards (3-ESS3-1) -----------------------------------------------------------------------------------

## "Which design helps people in a drought?"
static func hazard_design(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = []
	for h: String in HAZARDS:
		if int(HAZARDS[h].level) <= level:
			pool.append(h)
			if int(HAZARDS[h].level) == level:
				pool.append(h)
	var hazard: String = pool[rng.randi_range(0, pool.size() - 1)]
	var help: Array = HAZARDS[hazard].help
	var no: Array = (HAZARDS[hazard].no as Array).duplicate()
	K.shuffle(rng, no)
	var right: String = help[rng.randi_range(0, help.size() - 1)]
	var ex := K.choice(rng, "Which design helps people in %s?" % hazard, right, no.slice(0, 2 if level == 1 else 3),
		"What harm does %s do? Which design stops that harm?" % hazard,
		"%s reduces the harm of %s." % [_cap(right), hazard])
	ex.data = {"hazard": hazard, "design": right}
	return ex


# --- Working like a scientist (UK lower KS2) ----------------------------------------------------------------------

## "What would you use to measure how heavy an apple is?" (level 3: which unit)
static func tool_unit(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick(rng, MEASURES, level, 1)
	var kind: String = row[1]
	var others: Array = TOOLS.keys().filter(func(k: String) -> bool: return k != kind)
	K.shuffle(rng, others)
	var ex: Dictionary
	if level < 3:
		ex = K.choice(rng, "What would you use to measure %s?" % row[0], str(TOOLS[kind]),
			others.slice(0, 3).map(func(k: String) -> String: return str(TOOLS[k])),
			"Is it a length, a mass, a temperature, a time or an amount of liquid?",
			"Measuring %s means measuring %s, so use %s." % [row[0], KIND_WORDS[kind], TOOLS[kind]])
		ex.data = {"what": row[0], "kind": kind, "ask": "tool"}
	else:
		ex = K.choice(rng, "Which unit would you use to measure %s?" % row[0], str(UNITS[kind]),
			others.slice(0, 3).map(func(k: String) -> String: return str(UNITS[k])),
			"Is it a length, a mass, a temperature, a time or an amount of liquid?",
			"Measuring %s means measuring %s, in %s." % [row[0], KIND_WORDS[kind], UNITS[kind]])
		ex.data = {"what": row[0], "kind": kind, "ask": "unit"}
	return ex


# --- Design and test (3-5-ETS1) -----------------------------------------------------------------------------------

## Three bridges, how many coins each held and their cost: the strongest (1), the cheapest that holds enough (2), the
## one that meets both rules (3).
static func design_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = ["A", "B", "C"]
	var need := rng.randi_range(2, 4) * 5
	var limit := rng.randi_range(5, 9)
	# one bridge meets both rules; one holds too few; one costs too much
	var good := [need + rng.randi_range(0, 8), rng.randi_range(2, limit)]
	var weak := [rng.randi_range(maxi(1, need - 8), need - 1), rng.randi_range(1, limit)]
	var dear := [need + rng.randi_range(4, 14), limit + rng.randi_range(1, 5)]
	if dear[0] == good[0]:
		dear[0] += 1
	var designs: Array = [good, weak, dear]
	K.shuffle(rng, designs)
	var rows: Array = [["Bridge", "Coins held", "Cost"]]
	for i in 3:
		rows.append([names[i], str(designs[i][0]), "%d gold" % designs[i][1]])
	var picture := {"kind": "table", "rows": rows}
	var ex: Dictionary
	var ask: String
	if level == 1:
		ask = "most"
		var best := 0
		for i in 3:
			if int(designs[i][0]) > int(designs[best][0]):
				best = i
		ex = K.choice(rng, "Three paper bridges were tested with coins. Which bridge held the most coins?", names[best],
			names.filter(func(n: String) -> bool: return n != names[best]), "Find the biggest number of coins.",
			"Bridge %s held %d coins, the most." % [names[best], designs[best][0]], picture)
	elif level == 2:
		ask = "cheapest_enough"
		var pick := -1
		for i in 3:
			if int(designs[i][0]) >= need and (pick < 0 or int(designs[i][1]) < int(designs[pick][1])):
				pick = i
		ex = K.choice(rng, "A bridge must hold at least %d coins. Of the bridges that do, which costs least?" % need,
			names[pick], names.filter(func(n: String) -> bool: return n != names[pick]),
			"First cross out the bridges that hold fewer than %d coins." % need,
			"Bridge %s holds %d coins and costs %d gold, the least of the ones strong enough." % [names[pick],
			designs[pick][0], designs[pick][1]], picture)
	else:
		ask = "both"
		var pick := designs.find(good)
		ex = K.choice(rng, "A bridge must hold at least %d coins and cost at most %d gold. Which bridge does both?"
			% [need, limit], names[pick], names.filter(func(n: String) -> bool: return n != names[pick]),
			"Check both rules for every bridge: enough coins? Not too costly?",
			"Bridge %s holds %d coins and costs %d gold, so it meets both rules." % [names[pick], good[0], good[1]],
			picture)
	ex.data = {"designs": designs, "need": need, "limit": limit, "ask": ask}
	return ex


# --- Helpers ------------------------------------------------------------------------------------------------------

## A row of this level or an easier one (this level's rows twice as often); `at` is the row's level index.
static func _pick(rng: RandomNumberGenerator, rows: Array, level: int, at: int) -> Array:
	var pool: Array = []
	for row: Array in rows:
		if int(row[at]) <= level:
			pool.append(row)
			if int(row[at]) == level:
				pool.append(row)
	return pool[rng.randi_range(0, pool.size() - 1)]


static func _cap(s: String) -> String:
	return s.left(1).to_upper() + s.substr(1)


static func _pole(p: String) -> String:
	return "north" if p == "N" else "south"


## "the roots take in water", "the stem holds": the job's verb as the part's subject.
static func _verb(part: String, job: String) -> String:
	if part.ends_with("s") and job.split(" ")[0].ends_with("s"):
		var words := job.split(" ")
		words[0] = words[0].left(-1)
		return " ".join(words)
	return job


static func _temp(t: int) -> String:
	return "%s%d °C" % ["−" if t < 0 else "", absi(t)]


## "no feathers, no fur and no fins"
static func _list(parts: Array[String]) -> String:
	if parts.size() < 2:
		return "".join(parts)
	return "%s and %s" % [", ".join(parts.slice(0, parts.size() - 1)), parts[parts.size() - 1]]


## "1 friend pulls", "3 friends pull"
static func _pull(n: int) -> String:
	return "1 friend pulls" if n == 1 else "%d friends pull" % n


## A life cycle for the level: level 1 the easy ones.
static func _cycle(rng: RandomNumberGenerator, level: int) -> String:
	var names: Array = []
	if level == 1:
		names.append_array(EASY_CYCLES)
	else:
		names.append_array(CYCLES.keys())
	return names[rng.randi_range(0, names.size() - 1)]


## The shadow's height (cm) of the toy at `d` cm from the torch.
static func _shadow(d: int) -> int:
	return roundi(float(TOY * WALL) / d)
