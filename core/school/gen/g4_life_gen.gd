class_name G4LifeGen
extends RefCounted
## Owner #68 (the grade 4 agent): grade 4 life science generators: SchoolGen "g4l.<name>",
## `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint, a
## worked answer and `data`. Units: "Plant and animal parts" (4-LS1-1), "Senses and the brain" (4-LS1-2). Every part's
## wrong jobs are written for that part, so none of them is secretly right.

const K := preload("res://core/school/gen/gen_kit.gd")

## {q, say (the worked answer), right, wrongs (3 jobs this part does not do), level, animal (its portrait) or ""}.
const PARTS: Array[Dictionary] = [
	{"q": "What do a plant's roots do?", "level": 1, "animal": "",
		"right": "take in water from the soil",
		"wrongs": ["make seeds", "catch sunlight to make food", "bring bees to the plant"],
		"say": "A plant's roots take in water from the soil and hold the plant in the ground."},
	{"q": "What do a plant's leaves do?", "level": 1, "animal": "",
		"right": "use sunlight to make food",
		"wrongs": ["take in water from the soil", "make seeds", "hold the plant in the ground"],
		"say": "A plant's leaves use sunlight to make food for the plant."},
	{"q": "What does a turtle's shell do?", "level": 1, "animal": "turtle",
		"right": "protects its soft body",
		"wrongs": ["helps it fly", "helps it see", "helps it smell"],
		"say": "A turtle's hard shell protects its soft body. It can even hide inside."},
	{"q": "What do a fish's gills do?", "level": 1, "animal": "fish",
		"right": "take in oxygen from the water",
		"wrongs": ["help it see in the dark", "keep it warm", "help it hear"],
		"say": "A fish's gills take in oxygen from the water, so it can breathe."},
	{"q": "What do a parrot's wings do?", "level": 1, "animal": "parrot",
		"right": "let it fly",
		"wrongs": ["help it breathe", "help it smell", "help it taste"],
		"say": "A parrot's wings let it fly."},
	{"q": "What does the heart do?", "level": 1, "animal": "",
		"right": "pumps blood around the body",
		"wrongs": ["breaks down food", "takes in air", "helps you smell"],
		"say": "The heart pumps blood all around the body."},
	{"q": "What do a duck's webbed feet do?", "level": 2, "animal": "duck",
		"right": "help it swim",
		"wrongs": ["help it hear", "help it see", "help it smell"],
		"say": "A duck's webbed feet push against the water like paddles: they help it swim."},
	{"q": "What does a polar bear's thick fur do?", "level": 2, "animal": "polar_bear",
		"right": "keeps it warm",
		"wrongs": ["helps it breathe", "helps it hear", "helps it taste"],
		"say": "A polar bear's thick fur keeps it warm in the snow and ice."},
	{"q": "What does a hedgehog's coat of spines do?", "level": 2, "animal": "hedgehog",
		"right": "protects it from hungry animals",
		"wrongs": ["helps it swim", "helps it see", "helps it breathe"],
		"say": "A hedgehog's spines protect it: few hungry animals want a prickly meal."},
	{"q": "What do a rose's thorns do?", "level": 2, "animal": "",
		"right": "keep hungry animals away",
		"wrongs": ["take in water", "make seeds", "catch sunlight"],
		"say": "A rose's thorns keep hungry animals from eating it."},
	{"q": "What does a plant's stem do?", "level": 2, "animal": "",
		"right": "holds it up and carries water",
		"wrongs": ["makes seeds", "brings bees to the plant", "catches insects"],
		"say": "A plant's stem holds it up and carries water from the roots to the leaves."},
	{"q": "What do the lungs do?", "level": 2, "animal": "",
		"right": "take in air",
		"wrongs": ["pump blood", "break down food", "help you think"],
		"say": "The lungs take in air when you breathe."},
	{"q": "What does the stomach do?", "level": 2, "animal": "",
		"right": "breaks down food",
		"wrongs": ["pumps blood", "takes in air", "helps you see"],
		"say": "The stomach breaks down the food you eat."},
	{"q": "What does a camel's hump store?", "level": 3, "animal": "camel",
		"right": "fat, for energy when food is scarce",
		"wrongs": ["water, for drinking later", "air, for breathing", "sand, to weigh it down"],
		"say": "A camel's hump stores fat, which gives it energy when food is hard to find. It is not full of water!"},
	{"q": "What do a flower's bright petals do?", "level": 3, "animal": "",
		"right": "bring bees and birds to the flower",
		"wrongs": ["take in water", "hold the plant up", "make food from soil"],
		"say": "Bright petals bring bees and birds, which carry pollen from flower to flower so seeds can form."},
	{"q": "What does a cactus's thick stem do?", "level": 3, "animal": "",
		"right": "stores water for dry days",
		"wrongs": ["makes seeds", "helps it move about", "brings bees to it"],
		"say": "A cactus's thick stem stores water, so it can live through long dry spells."},
	{"q": "What does the brain do?", "level": 3, "animal": "",
		"right": "controls the body and thinks",
		"wrongs": ["pumps blood", "breaks down food", "takes in air"],
		"say": "The brain controls the body: it thinks, remembers and tells the muscles what to do."},
	{"q": "What does your skin do?", "level": 3, "animal": "",
		"right": "protects the inside of your body",
		"wrongs": ["pumps blood", "breaks down food", "helps you think"],
		"say": "Your skin covers and protects the inside of your body."},
	{"q": "What does a squirrel's bushy tail help it do?", "level": 3, "animal": "squirrel",
		"right": "balance as it climbs and leaps",
		"wrongs": ["breathe under water", "see in the dark", "taste its food"],
		"say": "A squirrel's bushy tail helps it balance as it climbs and leaps."},
	{"q": "What do a rabbit's big ears help it do?", "level": 3, "animal": "rabbit",
		"right": "hear danger from far away",
		"wrongs": ["smell its food", "dig its tunnels", "taste the grass"],
		"say": "A rabbit's big ears help it hear danger coming from far away."},
	{"q": "What do an owl's sharp talons do?", "level": 3, "animal": "owl",
		"right": "grip the food it catches",
		"wrongs": ["help it hear", "keep it warm", "help it swim"],
		"say": "An owl's sharp talons grip the food it catches."},
]
## An animal's parts, inside its body and outside.
const INSIDE: Array[String] = ["the heart", "the lungs", "the stomach", "the brain", "the bones", "the muscles"]
const OUTSIDE: Array[String] = ["the fur", "the feathers", "the claws", "the scales", "the shell", "the whiskers",
	"the skin"]
const SENSES: Array[String] = ["sight", "hearing", "smell", "taste", "touch"]
## [what happens, the sense it uses, level].
const SITUATIONS: Array = [
	["A fox hears a mouse under the snow.", "hearing", 1],
	["An eagle spots a rabbit from high in the sky.", "sight", 1],
	["A dog sniffs out a buried bone.", "smell", 1],
	["Zara tastes that the lemon is sour.", "taste", 1],
	["Bram feels that the snow is cold.", "touch", 1],
	["A cat watches a bird on the fence.", "sight", 1],
	["A spider feels its web shake.", "touch", 2],
	["A shark smells a fish from far away.", "smell", 2],
	["A deer's ears catch the snap of a twig.", "hearing", 2],
	["A bee finds the bright petals of a flower.", "sight", 2],
	["Mimi notices that the soup is salty.", "taste", 2],
	["A mole feels its way along a dark tunnel.", "touch", 2],
	["A bat listens for the echoes of its calls.", "hearing", 3],
	["A snake picks up smells with its flicking tongue.", "smell", 3],
	["A cat's whiskers brush the sides of a narrow gap.", "touch", 3],
	["An owl finds a mouse rustling under the leaves.", "hearing", 3],
	["A hawk sees a mouse move in a field far below.", "sight", 3],
	["A butterfly tastes a flower with its feet.", "taste", 3],
]
## [who, the sense's body part, "picks up"/"pick up", what it picks up, what they do].
const REACTIONS: Array = [
	["the fox", "ears", "pick up", "a mouse's squeak", "pounces on the snow"],
	["the deer", "ears", "pick up", "a twig snapping", "runs into the trees"],
	["the cat", "eyes", "pick up", "a bird on the fence", "crouches down low"],
	["the dog", "nose", "picks up", "the smell of dinner", "runs to the kitchen"],
	["Tilly", "skin", "picks up", "a cold wind", "puts on her coat"],
	["the rabbit", "eyes", "pick up", "a hawk's shadow", "freezes"],
	["Bram", "tongue", "picks up", "a very sour taste", "pulls a funny face"],
	["the owl", "ears", "pick up", "a rustle in the grass", "swoops down"],
]


# --- Plant and animal parts (4-LS1-1) -----------------------------------------------------------------------------

## "What do a duck's webbed feet do?" (the part's job among three it does not do)
static func part_job(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = []
	for row: Dictionary in PARTS:
		if int(row.level) <= level:
			pool.append(row)
			if int(row.level) == level:
				pool.append(row)
	var row: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	var picture := {"kind": "icon", "animal": row.animal} if str(row.animal) != "" else {}
	var ex := K.choice(rng, str(row.q), str(row.right), row.wrongs,
		"Think about how this part helps the living thing survive, grow or stay safe.", str(row.say), picture)
	ex.data = {"q": row.q}
	return ex


## "The heart is an inside part of an animal's body." (true or false; level 2: which is inside; 3: which is outside)
static func inside_outside(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ins: Array = []
	ins.append_array(INSIDE)
	var outs: Array = []
	outs.append_array(OUTSIDE)
	K.shuffle(rng, ins)
	K.shuffle(rng, outs)
	var ex: Dictionary
	if level == 1:
		var part: String = ins[0] if rng.randf() < 0.5 else outs[0]
		var ask_inside := rng.randf() < 0.5
		var is_inside := INSIDE.has(part)
		ex = K.truefalse("%s %s an %s part of an animal's body." % [_cap(part), _is(part), "inside" if ask_inside else
			"outside"], is_inside == ask_inside, "Can you see it from the outside, or is it hidden inside the body?",
			"%s %s %s the body." % [_cap(part), _is(part), "inside" if is_inside else "on the outside of"])
		ex.data = {"part": part}
	elif level == 2:
		ex = K.choice(rng, "Which is an inside part of an animal's body?", ins[0], outs.slice(0, 3),
			"Which one is hidden inside, under the skin?",
			"%s %s inside the body; the others are on the outside." % [_cap(ins[0]), _is(ins[0])])
	else:
		ex = K.choice(rng, "Which is an outside part of an animal's body?", outs[0], ins.slice(0, 3),
			"Which one could you see without looking inside the body?",
			"%s %s on the outside; the others are inside the body." % [_cap(outs[0]), _is(outs[0])])
	if not ex.has("data"):
		ex.data = {}
	return ex


# --- Senses and the brain (4-LS1-2) -------------------------------------------------------------------------------

## "Which sense is this? A fox hears a mouse under the snow." (sight, hearing, smell, taste or touch)
static func which_sense(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = []
	for row: Array in SITUATIONS:
		if int(row[2]) <= level:
			pool.append(row)
			if int(row[2]) == level:
				pool.append(row)
	var row: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var sense: String = row[1]
	var ex := K.choice(rng, "Which sense is being used?  %s" % row[0], sense,
		SENSES.filter(func(s: String) -> bool: return s != sense),
		"Which body part takes in the information: eyes, ears, nose, tongue or skin?",
		"This is %s." % sense)
	ex.data = {"sense": sense}
	return ex


## "Put what happens in order": the sense picks something up, a message goes to the brain, (the brain decides,) the
## body acts.
static func sense_steps(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = REACTIONS[rng.randi_range(0, REACTIONS.size() - 1)]
	var who := _cap(str(row[0]))
	var steps: Array = ["%s's %s %s %s." % [who, row[1], row[2], row[3]], "A message travels to the brain."]
	if level > 1:
		steps.append("The brain decides what to do.")
	steps.append("%s %s." % [who, row[4]])
	var ex := K.order(rng, "Put what happens in order, from the sense to the action.", steps,
		"Information goes in through a sense, the brain works out what to do, then the body acts.",
		" ".join(steps))
	ex.data = {"who": row[0]}
	return ex


## "is" or "are": "the lungs are", "the heart is".
static func _is(part: String) -> String:
	return "are" if part.ends_with("s") else "is"


static func _cap(s: String) -> String:
	return s.left(1).to_upper() + s.substr(1)
