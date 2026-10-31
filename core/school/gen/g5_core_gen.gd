class_name G5CoreGen
extends RefCounted
## Owner #70 and #73 (research §6.5): grade 5 maths, science and English generators for the research's new units:
## percentages (a hundred square, fractions, decimals and percentages, a percentage of an amount, discounts in gold,
## comparing); angles (on a straight line, round a point, vertically opposite, in triangles and quadrilaterals); forces
## (which force, friction tests, levers, gears and pulleys); electric systems (which lamps light, brighter or dimmer,
## the symbols); life cycles, how seeds travel, eggs or live young; the pulse, the air's and the blood's paths, the
## body's parts and their jobs; and in English: quotes that prove a point, exact quotes, where to look, linking words,
## formal words, an explanation's features, showing feelings, speech marks and summaries. SchoolGen "g5c.<name>",
## `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint (a
## strategy), a worked answer and `data` (its inputs, for tests/unit/test_g5_core_gen.gd, which checks every answer with
## its own facts). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")

## Things to buy in the game's shops (a discount in gold).
const GOODS: Array[String] = ["saddle", "lantern", "fishing rod", "telescope", "backpack", "pet bed", "kite", "map",
	"compass", "rowing boat", "tent", "paint set"]
## Who shops, saves and builds in the stories.
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Oli", "Juno"]
## Things to count for "a percentage of an amount": [plural, what the person does with some].
const HEAPS: Array = [["blocks", "uses %d%% of them to build a wall"], ["seeds", "plants %d%% of them"],
	["gold coins", "spends %d%% of them"], ["apples", "gives %d%% of them to the horses"],
	["bricks", "uses %d%% of them for a tower"], ["shells", "paints %d%% of them"]]

## The forces and their situations, by level ([situation, force]).
const FORCES: Array[String] = ["gravity", "friction", "air resistance", "water resistance"]
const FORCE_SITUATIONS: Array = [
	[["An apple drops from a tree to the ground.", "gravity"], ["Bike brakes rub on the wheels to stop them.", "friction"],
		["An open parachute slows a skydiver's fall.", "air resistance"],
		["A swimmer feels the water pushing back on her arms.", "water resistance"],
		["A ball thrown up in the air comes back down.", "gravity"],
		["Rubbing your hands together makes them warm.", "friction"]],
	[["A paper plane glides slowly down to the floor.", "air resistance"],
		["A rowing boat slows down when Oli stops rowing.", "water resistance"],
		["Your shoes grip the floor, so you do not slip.", "friction"],
		["A skater's blades glide far on the smooth ice, but a sledge stops quickly on the stony path.", "friction"],
		["The Moon keeps going round the Earth.", "gravity"],
		["An open umbrella is hard to run with on a windy day.", "air resistance"],
		["A dog paddling across the pond is slowed by the water.", "water resistance"]],
	[["A cyclist crouches low and wears a smooth helmet to go faster.", "air resistance"],
		["A fish's smooth, pointed shape helps it swim fast.", "water resistance"],
		["A match lights when it is struck on the rough side of its box.", "friction"],
		["A ship's front is pointed so it cuts through the sea.", "water resistance"],
		["A feather falls slowly, but on the Moon it falls as fast as a hammer.", "air resistance"],
		["Cars have smooth, curved shapes to save fuel at speed.", "air resistance"],
		["Climbers use chalk on their hands to grip the rock.", "friction"],
		["A dropped ball falls faster and faster until it hits the ground.", "gravity"]],
]
## Surfaces from the least friction to the most, for a crate sliding or a toy car rolling on them.
const SURFACES: Array[String] = ["ice", "smooth wood", "carpet", "sandpaper"]

## Circuit parts' names, for the symbols.
const SYMBOL_WORDS := {"cell": "a cell", "battery": "a battery", "lamp": "a lamp (bulb)", "open": "an open switch",
	"closed": "a closed switch", "buzzer": "a buzzer", "motor": "a motor", "wire": "a wire"}
const BRIGHTER := "brighter"
const DIMMER := "dimmer"
const SAME := "the same"

## Life cycles: [the animal or plant, its stages in order, the short labels for its picture (14 letters each)].
const CYCLES: Array = [
	["grasshopper", ["egg", "nymph", "adult grasshopper"], ["egg", "nymph", "adult"], 1, []],
	["dragonfly", ["egg", "nymph living in water", "adult dragonfly"], ["egg", "water nymph", "adult"], 1, []],
	["chicken", ["egg", "chick", "adult hen"], ["egg", "chick", "hen"], 1, []],
	["cat", ["kitten is born", "kitten drinks milk", "young cat", "adult cat"],
		["born", "drinks milk", "young cat", "adult cat"], 2, ["tadpole", "chrysalis", "hatchling"]],
	["frog", ["frogspawn (eggs)", "tadpole", "froglet", "adult frog"], ["frogspawn", "tadpole", "froglet", "adult frog"], 2,
		["caterpillar", "chrysalis", "drinks milk"]],
	["butterfly", ["egg", "caterpillar (larva)", "chrysalis (pupa)", "butterfly"],
		["egg", "caterpillar", "chrysalis", "butterfly"], 2, ["tadpole", "froglet", "drinks milk"]],
	["robin", ["egg", "hatchling", "fledgling", "adult robin"], ["egg", "hatchling", "fledgling", "adult robin"], 2,
		["tadpole", "chrysalis", "nymph"]],
	["ladybird", ["egg", "larva", "pupa", "adult ladybird"], ["egg", "larva", "pupa", "ladybird"], 2,
		["tadpole", "froglet", "fledgling"]],
	["toad", ["eggs in long strings", "tadpole", "toadlet", "adult toad"], ["egg strings", "tadpole", "toadlet",
		"adult toad"], 2, ["caterpillar", "chrysalis", "fledgling"]],
	["whale", ["calf is born", "calf drinks milk", "young whale", "adult whale"],
		["calf is born", "drinks milk", "young whale", "adult whale"], 2, ["tadpole", "chrysalis", "hatchling"]],
	["sunflower", ["seed", "seedling", "young plant", "flower", "new seeds"],
		["seed", "seedling", "young plant", "flower", "new seeds"], 3, ["tadpole", "chrysalis", "hatchling"]],
	["mosquito", ["egg", "larva", "pupa", "adult mosquito"], ["egg", "larva", "pupa", "adult"], 3,
		["tadpole", "froglet", "fledgling"]],
]
## How seeds travel: [the plant, how, a clue], and every way.
const SEED_WAYS: Array[String] = ["the wind", "sticking to animals' fur", "animals eating the fruit", "floating on water",
	"pods bursting open", "animals burying them"]
const SEED_PLANTS: Array = [
	["dandelion", "the wind", "Each seed has a fluffy parachute."],
	["sycamore", "the wind", "Each seed has a wing that spins."],
	["thistle", "the wind", "Its seeds have soft, feathery hairs."],
	["burdock", "sticking to animals' fur", "Its burrs are covered in tiny hooks."],
	["goosegrass", "sticking to animals' fur", "Its little round seeds are covered in hooks."],
	["blackberry", "animals eating the fruit", "Birds eat the juicy berries."],
	["cherry", "animals eating the fruit", "Birds eat the sweet red fruit."],
	["coconut", "floating on water", "Its big, light fruit floats across the sea."],
	["water lily", "floating on water", "Its seeds float away across the pond."],
	["pea", "pods bursting open", "Its dry pods split and flick the peas out."],
	["gorse", "pods bursting open", "Its pods pop open with a crack on hot days."],
	["oak", "animals burying them", "Squirrels and jays bury its acorns and forget some."],
]
## Animals that lay eggs and animals born alive (all mammals here; the platypus is a mammal that lays eggs).
const LAYS_EGGS: Array[String] = ["frog", "robin", "butterfly", "crocodile", "salmon", "tortoise", "penguin", "bee", "snail",
	"ostrich"]
const BORN_ALIVE: Array[String] = ["cow", "whale", "bat", "horse", "dolphin", "elephant", "rabbit", "kangaroo", "giraffe",
	"seal"]

## The air's path into the body, and the blood's loop (from the body's muscles round and back).
const AIR_PATH: Array[String] = ["nose or mouth", "windpipe", "tubes into each lung", "tiny air sacs"]
const BLOOD_LOOP: Array[String] = ["the body's muscles use oxygen", "veins carry blood back to the heart",
	"the heart's right side pumps it to the lungs", "the lungs give it fresh oxygen",
	"the heart's left side pumps it out", "arteries carry it to the body"]
## Parts of the body and their jobs, by level.
const JOBS: Array = [
	[["heart", "pumps blood round the body"], ["lungs", "take in oxygen from the air"], ["windpipe", "carries air to the lungs"],
		["diaphragm", "helps you breathe in and out"]],
	[["arteries", "carry blood away from the heart"], ["veins", "carry blood back to the heart"],
		["capillaries", "tiny tubes to every cell"], ["air sacs", "pass oxygen into the blood"]],
	[["red blood cells", "carry oxygen"], ["white blood cells", "fight germs"], ["platelets", "help a cut to clot"],
		["plasma", "carries food and water"]],
]

## Quotes that prove it: [the text's three sentences, what to prove, the sentence that proves it, level]. Level 1: the
## text says it; level 2: you infer it from a clue; level 3: the right quote and a near miss.
const QUOTES: Array = [
	[["Bram wore a yellow shirt.", "He built a sandcastle by the sea.", "He was eight years old."],
		"Bram was at the beach", 1, 1],
	[["Zara laughed until her sides ached.", "The clown fell into the paddling pool.", "Everyone clapped."],
		"the clown fell into water", 1, 1],
	[["The old bridge was made of rope.", "It swayed in the wind.", "Mimi's hat was green."], "the bridge moved", 1, 1],
	[["Oli has a pet tortoise called Dot.", "Dot is sixty years old.", "She likes lettuce."], "Dot is very old", 1, 1],
	[["Oli's cake was lopsided.", "The icing had slid off one side.", "He smiled anyway."],
		"Oli was not upset about his cake", 2, 2],
	[["Juno tiptoed past the sleeping dog.", "The kitchen was painted blue.", "The clock said nine."],
		"Juno did not want to wake the dog", 0, 2],
	[["Tilly's coat dripped on the mat.", "Her scarf was striped.", "She had been out for an hour."],
		"it was wet outside", 0, 2],
	[["Bram ate his breakfast slowly.", "The pond outside had frozen solid.", "His sister was still asleep."],
		"it was very cold", 1, 2],
	[["Mimi read the letter twice.", "Then she danced round the kitchen.", "The letter was from her gran."],
		"the letter had good news", 1, 3],
	[["The buddy's tail drooped.", "It lay by the fire.", "Its fur was brown."], "the buddy was unhappy", 0, 3],
	[["Zara turned the map round and round.", "Her new boots were red.", "The sun was setting."],
		"Zara was not sure of the way", 0, 3],
	[["Kit's hand shot up first.", "The question was about volcanoes.", "Kit sat by the window."],
		"Kit knew the answer", 0, 3],
]
## Exact quotes: [the sentence from the text, three changed copies (a word changed, a word missing, a word added), level].
const EXACT: Array = [
	["The fox slipped silently into the woods.", ["The fox slipped quietly into the woods.",
		"The fox slipped silently into woods.", "The red fox slipped silently into the woods."], 1],
	["Snow lay deep on the mountain path.", ["Snow lay thick on the mountain path.", "Snow lay deep on the path.",
		"Deep snow lay on the mountain path."], 1],
	["Bees visit hundreds of flowers every day.", ["Bees visit thousands of flowers every day.",
		"Bees visit hundreds of flowers each day.", "Bees visit hundreds of flowers."], 2],
	["The castle was built nearly 900 years ago.", ["The castle was built 900 years ago.",
		"The castle was built nearly 800 years ago.", "The castle was made nearly 900 years ago."], 2],
	["Tilly whispered, \"We must be very careful.\"", ["Tilly whispered, \"We must be careful.\"",
		"Tilly said, \"We must be very careful.\"", "Tilly whispered, \"We should be very careful.\""], 3],
	["The dragon kite rose high above the hill.", ["The dragon kite rose high over the hill.",
		"The kite rose high above the hill.", "The dragon kite rose high above the green hill."], 3],
]
## Where to look: [the question, the best place, three places that fit worse, level].
const SOURCES: Array = [
	["What does the word \"habitat\" mean in this book?", "the glossary", ["the contents page", "the title", "the cover"], 1],
	["Which page of the book is about owls?", "the index", ["the glossary", "the cover", "a map"], 1],
	["What are the book's chapters called?", "the contents page", ["the index", "the glossary", "a timeline"], 1],
	["Where is Peru?", "an atlas", ["a dictionary", "a timeline", "a recipe book"], 1],
	["How is \"necessary\" spelled?", "a dictionary", ["an atlas", "a timeline", "a bar chart"], 2],
	["In what order did the events of the Roman invasion happen?", "a timeline", ["a glossary", "a dictionary",
		"an atlas"], 2],
	["Which month had the most rain last year?", "a bar chart of the rainfall", ["a glossary", "the index",
		"an atlas"], 2],
	["What are the parts of a bicycle called?", "a labelled diagram", ["a timeline", "the contents page",
		"a thesaurus"], 2],
	["What is another word for \"big\"?", "a thesaurus", ["an atlas", "a timeline", "the index"], 3],
	["Is a fact on a website true?", "two or three other trusted sources", ["the website's own advert",
		"a comment under it", "how many pictures it has"], 3],
	["How do bees tell each other where flowers are?", "an expert's book about bees", ["a story about a talking bee",
		"a bee colouring book", "a poem about summer"], 3],
]
## Linking words for an opinion: [the sentences with ___, the right words, three that do not fit, level].
const LINKS: Array = [
	["Plastic lasts for hundreds of years. ___, we should use less of it.", "Therefore",
		["For instance", "In contrast", "Specifically"], 1],
	["Our park needs more bins. ___, it needs two by the pond.", "Specifically",
		["However", "Consequently", "In contrast"], 1],
	["Trees give us clean air. ___, they give birds a home.", "Furthermore", ["However", "In contrast", "Specifically"], 1],
	["Many pupils walk to school. ___, the road outside is busy.", "Consequently",
		["For instance", "In contrast", "Specifically"], 2],
	["Some say homework is boring. ___, it helps us remember.", "However", ["Furthermore", "Consequently",
		"Specifically"], 2],
	["Reading every day helps. ___, it grows your vocabulary.", "For instance", ["However", "In contrast",
		"Consequently"], 2],
	["Cycling costs nothing. ___, a bus ticket costs gold every day.", "In contrast",
		["Furthermore", "Therefore", "For instance"], 2],
	["The playground floods when it rains. ___, we cannot play there.", "As a result",
		["For instance", "In contrast", "Specifically"], 3],
	["Gardens help wildlife. ___, bees need flowers to feed.", "In particular",
		["However", "Consequently", "In contrast"], 3],
	["The library is quiet. ___, it has thousands of books to borrow.", "Moreover",
		["However", "Consequently", "In contrast"], 3],
]
## Formal and informal: [formal, informal] ways of saying the same thing.
const FORMAL: Array = [
	["I would like to request a meeting.", "Can we meet up?"],
	["Please do not hesitate to contact us.", "Just give us a shout."],
	["The children were extremely excited.", "The kids were super excited."],
	["We regret that the pool is closed.", "Sorry, the pool's shut."],
	["Pupils must not enter the kitchen.", "Keep out of the kitchen, OK?"],
	["I am writing to complain about the noise.", "The noise is driving me mad!"],
	["Thank you for your kind help.", "Cheers for helping!"],
	["Many people believe that it is unfair.", "Loads of people reckon it's unfair."],
	["We need to investigate further.", "We need to find out more stuff."],
	["The results will be announced tomorrow.", "We'll tell you the results tomorrow."],
	["If I were the mayor, I would build a park.", "If I was the mayor, I'd build a park."],
]
## An explanation's features: [a piece of text, what it is, level].
const FEATURES: Array[String] = ["a definition", "a quotation", "a caption", "a subheading", "a conclusion",
	"a glossary entry", "a fact"]
const FEATURE_TEXTS: Array = [
	["Magma is melted rock deep under the ground.", "a definition", 1],
	["A volcano is an opening where melted rock escapes.", "a definition", 1],
	["How volcanoes form", "a subheading", 1],
	["Picture 2: lava flowing down the side of a volcano", "a caption", 1],
	["A volcano expert said, \"Every eruption is different.\"", "a quotation", 2],
	["In conclusion, volcanoes are dangerous but also build new land.", "a conclusion", 2],
	["lava: melted rock that comes out of a volcano", "a glossary entry", 2],
	["Mount Etna is on the island of Sicily, in Italy.", "a fact", 2],
	["Why volcanoes erupt", "a subheading", 3],
	["To sum up, bees are small but they feed the world.", "a conclusion", 3],
	["pollen: a yellow powder that flowers make", "a glossary entry", 3],
	["A beekeeper told us, \"A hive can hold 50,000 bees.\"", "a quotation", 3],
]
## Showing a feeling: [the feeling, the sentence that shows it, the one that only tells it].
const FEELINGS: Array = [
	["nervous", "Tilly's hands shook as she knocked on the door.", "Tilly was nervous."],
	["angry", "Bram slammed the door and stamped upstairs.", "Bram was angry."],
	["excited", "Zara bounced on her toes, grinning.", "Zara was excited."],
	["sad", "A tear rolled down Mimi's cheek.", "Mimi was sad."],
	["scared", "Juno froze, her heart thumping.", "Juno was scared."],
	["tired", "Oli's eyes drooped, and he yawned.", "Oli was tired."],
	["proud", "Kit stood tall and showed everyone her badge.", "Kit was proud."],
	["surprised", "Tam's jaw dropped, and so did his spoon.", "Tam was surprised."],
	["bored", "Wick sighed and drew slow circles on the table.", "Wick was bored."],
]
## Speech punctuated right, and three copies with a mistake each: [right, wrongs, level].
const SPEECH: Array = [
	["\"Come here,\" said Mum.", ["Come here, said Mum.", "\"Come here\", said Mum.", "\"come here,\" said Mum."], 1],
	["Bram said, \"Let's go.\"", ["Bram said, Let's go.", "Bram said, \"let's go.\"", "Bram said \"Let's go\"."], 1],
	["\"Where are you going?\" asked Zara.", ["\"Where are you going,\" asked Zara.", "Where are you going? asked Zara.",
		"\"Where are you going\"? asked Zara."], 2],
	["\"Look out!\" shouted Oli.", ["\"Look out\"! shouted Oli.", "Look out! shouted Oli.", "\"look out!\" shouted Oli."], 2],
	["\"I think,\" said Mimi, \"that it will rain.\"", ["\"I think,\" said Mimi, \"That it will rain.\"",
		"\"I think\" said Mimi \"that it will rain.\"", "I think, said Mimi, that it will rain."], 3],
	["\"We won!\" cried Juno. \"We really won!\"", ["\"We won!\" cried Juno. We really won!",
		"\"We won\"! cried Juno. \"We really won\"!", "\"We won! cried Juno. We really won!\""], 3],
]
## Summaries of a short talk: [the talk, the best summary, three worse ones, level].
const TALKS: Array = [
	["Hedgehogs eat slugs and beetles. They sleep all winter. Leave a gap under your fence so they can visit.",
		"Hedgehogs eat pests, sleep in winter, need gaps.",
		["Hedgehogs eat beetles.", "Fences are made of wood.", "Hedgehogs are cute."], 1],
	["Our school uses too much paper. We could print on both sides and use screens. That would save trees.",
		"Printing less paper would save trees.", ["Paper is white.", "Screens are bright.",
		"Our school has a printer."], 1],
	["The Romans built long, straight roads. Soldiers could march fast on them. Some roads are still used today.",
		"Roman roads were straight, fast and still used.",
		["Soldiers marched.", "Roads are long.", "The Romans liked walking."], 2],
	["Bats are not blind. They hunt at night using echoes. One bat can eat thousands of insects in a night.",
		"Bats are not blind; they hunt insects by echo.",
		["Bats are blind.", "Bats sleep upside down.", "Insects fly at night."], 2],
	["Water covers most of Earth, but most of it is salty. Only a tiny part is fresh water we can drink, so save it.",
		"Little of Earth's water is fresh: save it.",
		["Water covers most of Earth.", "Seawater is salty.", "Drinking water is cold."], 3],
	["Trees clean the air and give animals homes. They also cool streets in summer. Our town should plant more.",
		"Trees help air, wildlife, streets: plant more.",
		["Trees are tall.", "Animals live in trees.", "Streets are hot in summer."], 3],
]


# --- Percentages -------------------------------------------------------------------------------------------------------

## A hundred square: the percentage shaded (level 1), not shaded (level 2), or the shaded part as a decimal (level 3).
static func percent_square(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := rng.randi_range(1, 19) * 5 if level == 1 else rng.randi_range(1, 99)
	var pic := {"kind": "hundred_square", "shaded": n}
	var ex: Dictionary
	match level:
		1:
			ex = K.number("What percentage of the square is shaded?", str(n),
				"Each small square is 1 of 100, so 1%. Count the full rows of 10 first, then the rest.",
				"%d of the 100 small squares are shaded: %d out of 100 is %d%%." % [n, n, n], pic)
		2:
			ex = K.number("What percentage of the square is NOT shaded?", str(100 - n),
				"The whole square is 100%. Count the shaded part, then take it away from 100%.",
				"%d%% is shaded, so 100%% − %d%% = %d%% is not shaded." % [n, n, 100 - n], pic)
		_:
			ex = K.number("Write the shaded part of the square as a decimal.", _hundredths(n),
				"Per cent means out of 100: the shaded squares are hundredths. Write them as 0.__.",
				"%d of 100 squares: %d%% = %d/100 = %s." % [n, n, n, _hundredths(n)], pic)
	ex.data = {"n": n, "ask": ["shaded", "not", "decimal"][level - 1]}
	return ex


## Fractions, decimals and percentages: tenths and hundredths (level 1), decimals both ways (level 2), halves,
## quarters, fifths, twentieths, twenty-fifths and fiftieths (level 3).
static func percent_convert(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var data := {}
	match level:
		1:
			if rng.randf() < 0.5:
				var t := rng.randi_range(1, 9)
				ex = K.number("%d/10 = ?%%" % t, str(t * 10), "Make the fraction out of 100: multiply the top and the bottom by 10.",
					"%d/10 = %d/100 = %d%%." % [t, t * 10, t * 10])
				data = {"num": t, "den": 10, "want": "percent"}
			else:
				var h := rng.randi_range(1, 99)
				ex = K.number("%d/100 = ?%%" % h, str(h), "Per cent means out of 100.",
					"%d out of 100 is %d%%." % [h, h])
				data = {"num": h, "den": 100, "want": "percent"}
		2:
			var h := rng.randi_range(1, 99)
			if h % 10 == 0 or rng.randf() < 0.2:
				h = rng.randi_range(1, 9) * (10 if rng.randf() < 0.5 else 1)
			if rng.randf() < 0.5:
				ex = K.number("%s = ?%%" % _hundredths(h), str(h),
					"Multiply the decimal by 100: the digits move two places to the left.",
					"%s = %d hundredths = %d%%." % [_hundredths(h), h, h])
				data = {"decimal": _hundredths(h), "want": "percent"}
			else:
				ex = K.number("Write %d%% as a decimal." % h, _hundredths(h),
					"Per cent means hundredths: divide by 100, so the digits move two places to the right.",
					"%d%% = %d/100 = %s." % [h, h, _hundredths(h)])
				data = {"percent": h, "want": "decimal"}
		_:
			var den: int = [2, 4, 5, 20, 25, 50][rng.randi_range(0, 5)]
			var num := rng.randi_range(1, den - 1)
			while _gcd(num, den) != 1:
				num = rng.randi_range(1, den - 1)
			var times := 100 / den
			var p := num * times
			if rng.randf() < 0.7:
				ex = K.number("%d/%d = ?%%" % [num, den], str(p),
					"Find an equal fraction out of 100: what do you multiply %d by to make 100?" % den,
					"%d × %d = 100, so %d/%d = %d/100 = %d%%." % [den, times, num, den, p, p])
				data = {"num": num, "den": den, "want": "percent"}
			else:
				ex = K.number("Write %d%% as a fraction in its simplest form." % p, "%d/%d" % [num, den],
					"Write it out of 100, then divide the top and the bottom by the same number.",
					"%d%% = %d/100 = %d/%d (dividing both by %d)." % [p, p, num, den, times])
				data = {"percent": p, "want": "fraction"}
	ex.data = data
	return ex


## A percentage of an amount: 50% and 10% (level 1); 25%, 75%, 20%, 30% and 40% (level 2); 5%, 15%, 35%, 45%, 60%, 70%
## and 90% (level 3), in stories or as sums.
static func percent_of(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var p: int
	var n: int
	match level:
		1:
			p = [50, 10][rng.randi_range(0, 1)]
			n = rng.randi_range(2, 20) * 10
		2:
			p = [25, 75, 20, 30, 40][rng.randi_range(0, 4)]
			n = rng.randi_range(2, 25) * (4 if p in [25, 75] else 10)
		_:
			p = [5, 15, 35, 45, 60, 70, 90][rng.randi_range(0, 6)]
			n = rng.randi_range(1, 20) * 20
	var part := n * p / 100
	var prompt: String
	if rng.randf() < 0.5:
		prompt = "%d%% of %d = ?" % [p, n]
	else:
		var who := NAMES[rng.randi_range(0, NAMES.size() - 1)]
		var heap: Array = HEAPS[rng.randi_range(0, HEAPS.size() - 1)]
		prompt = "%s has %d %s and %s. How many is that?" % [who, n, heap[0], str(heap[1]) % p]
	var ex := K.number(prompt, str(part), _percent_hint(p), _percent_steps(p, n))
	ex.data = {"p": p, "n": n}
	return ex


## A discount in gold: how much is taken off (level 1), the new price (level 2), or a harder discount or the cheaper of
## two offers (level 3).
static func discount(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var thing := GOODS[rng.randi_range(0, GOODS.size() - 1)]
	if level == 3 and rng.randf() < 0.4:
		return _cheaper_offer(rng, thing)
	var p: int
	var price: int
	match level:
		1:
			p = [10, 50][rng.randi_range(0, 1)]
			price = rng.randi_range(2, 15) * 10
		2:
			p = [10, 20, 25, 50][rng.randi_range(0, 3)]
			price = rng.randi_range(2, 12) * 20
		_:
			p = [5, 15, 30, 40, 75][rng.randi_range(0, 4)]
			price = rng.randi_range(2, 12) * 20
	var off := price * p / 100
	var ex: Dictionary
	if level == 1:
		ex = K.number("A %s costs %d gold. The shop takes %d%% off. How many gold coins are taken off?" % [thing, price, p],
			str(off), _percent_hint(p), _percent_steps(p, price) + " So %d gold is taken off." % off)
	else:
		ex = K.number("A %s costs %d gold. In the sale it is %d%% off. What is the sale price, in gold?" % [thing, price, p],
			str(price - off), "Find %d%% of the price, then take it away from the price." % p,
			"%d%% of %d is %d gold, and %d − %d = %d gold." % [p, price, off, price, off, price - off])
	ex.data = {"p": p, "price": price, "ask": "off" if level == 1 else "price"}
	return ex


static func _cheaper_offer(rng: RandomNumberGenerator, thing: String) -> Dictionary:
	var pa := 0
	var pb := 0
	var price_a := 0
	var price_b := 0
	for _i in 40:
		pa = [10, 20, 25, 50][rng.randi_range(0, 3)]
		pb = [10, 20, 25, 50][rng.randi_range(0, 3)]
		price_a = rng.randi_range(3, 12) * 20
		price_b = price_a + [-40, -20, 20, 40][rng.randi_range(0, 3)]
		if pa != pb and price_a - price_a * pa / 100 != price_b - price_b * pb / 100:
			break
	var cost_a := price_a - price_a * pa / 100
	var cost_b := price_b - price_b * pb / 100
	var a_text := "Shop A (%d gold)" % cost_a
	var b_text := "Shop B (%d gold)" % cost_b
	var same := "They cost the same."
	var right := a_text if cost_a < cost_b else (b_text if cost_b < cost_a else same)
	var wrongs: Array = [a_text, b_text, same]
	wrongs.erase(right)
	var ex := K.choice(rng, "Shop A sells a %s for %d gold with %d%% off. Shop B sells it for %d gold with %d%% off. Which is cheaper?" % [
		thing, price_a, pa, price_b, pb], right, wrongs,
		"Work out each sale price: find the percentage off, then take it away.",
		"A: %d − %d = %d gold. B: %d − %d = %d gold. %s" % [price_a, price_a * pa / 100, cost_a, price_b,
			price_b * pb / 100, cost_b, "A is cheaper." if cost_a < cost_b else ("B is cheaper." if cost_b < cost_a else same)])
	ex.data = {"pa": pa, "price_a": price_a, "pb": pb, "price_b": price_b}
	return ex


## Comparing fractions, decimals and percentages: the largest of three (level 1, tens of per cent apart) or four (level
## 2, fives apart); four in order, smallest first (level 3).
static func percent_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var count := 3 if level == 1 else 4
	var step := 10 if level == 1 else 5
	var values: Array = []
	while values.size() < count:
		var v := rng.randi_range(1, 99 / step) * step
		if not values.has(v):
			values.append(v)
	var shown: Array = []
	var forms: Array = []
	for i in values.size():
		var form := rng.randi_range(0, 2)
		shown.append(_as_form(int(values[i]), form))
		forms.append(form)
	var sorted := values.duplicate()
	sorted.sort()
	var ex: Dictionary
	var worked: Array = []
	for i in values.size():
		worked.append("%s = %d%%" % [shown[i], values[i]])
	if level == 3:
		var in_order: Array = []
		for v: int in sorted:
			in_order.append(shown[values.find(v)])
		ex = K.order(rng, "Put them in order, smallest first.", in_order,
			"Change them all into percentages first, then compare.", ", ".join(worked) + ".")
	else:
		var biggest: int = sorted[-1]
		var right: String = shown[values.find(biggest)]
		var wrongs: Array = []
		for s: String in shown:
			if s != right:
				wrongs.append(s)
		ex = K.choice(rng, "Which is the largest?", right, wrongs,
			"Change them all into percentages (out of 100), then compare.",
			", ".join(worked) + ". The largest is %s." % right)
	ex.data = {"values": values, "shown": shown}
	return ex


## A value in per cent, shown as a percentage (0), a decimal (1) or a fraction in its simplest form (2).
static func _as_form(p: int, form: int) -> String:
	match form:
		1:
			return _hundredths(p)
		2:
			var g := _gcd(p, 100)
			return "%d/%d" % [p / g, 100 / g]
	return "%d%%" % p


static func _percent_hint(p: int) -> String:
	match p:
		50:
			return "50% is a half: divide by 2."
		10:
			return "10% is a tenth: divide by 10."
		25:
			return "25% is a quarter: divide by 4."
		75:
			return "75% is three quarters: find a quarter, then times it by 3."
		5:
			return "Find 10% first (divide by 10). 5% is half of 10%."
		15, 35, 45:
			return "Find 10% (divide by 10) and 5% (half of that), then build the percentage from them."
	return "Find 10%% first (divide by 10), then times it by %d." % (p / 10)


## The worked steps for p% of n.
static func _percent_steps(p: int, n: int) -> String:
	var ten := n / 10
	match p:
		50:
			return "50%% is a half: %d ÷ 2 = %d." % [n, n / 2]
		10:
			return "10%% is a tenth: %d ÷ 10 = %d." % [n, ten]
		25:
			return "25%% is a quarter: %d ÷ 4 = %d." % [n, n / 4]
		75:
			return "A quarter of %d is %d, so 75%% is 3 × %d = %d." % [n, n / 4, n / 4, n * 3 / 4]
		5:
			return "10%% of %d is %d, and 5%% is half of that: %d." % [n, ten, ten / 2]
		15:
			return "10%% of %d is %d and 5%% is %d, so 15%% is %d + %d = %d." % [n, ten, ten / 2, ten, ten / 2, ten + ten / 2]
		35, 45:
			var tens := p / 10
			return "10%% of %d is %d, so %d%% is %d; 5%% is %d; %d%% is %d + %d = %d." % [n, ten, tens * 10, tens * ten,
				ten / 2, p, tens * ten, ten / 2, tens * ten + ten / 2]
	return "10%% of %d is %d, so %d%% is %d × %d = %d." % [n, ten, p, p / 10, ten, p / 10 * ten]


## A decimal of hundredths: 7 -> "0.07", 40 -> "0.4", 35 -> "0.35".
static func _hundredths(h: int) -> String:
	if h % 10 == 0:
		return "0.%d" % (h / 10)
	return "0.%02d" % h


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := b
		b = a % b
		a = t
	return a


# --- Angles --------------------------------------------------------------------------------------------------------

## Angles on a straight line add up to 180°: two angles in tens (level 1), any two (level 2), three, or two equal ones
## (level 3).
static func angle_line(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var angles: Array = []
	var labels: Array = []
	var answer: int
	var prompt := "The angles are on a straight line. What is the angle marked ?, in degrees?"
	var explain: String
	if level < 3:
		var a := rng.randi_range(2, 16) * 10 if level == 1 else rng.randi_range(21, 159)
		while a == 90:
			a = rng.randi_range(2, 16) * 10
		angles = [a, 180 - a]
		var hide := rng.randi_range(0, 1)
		labels = ["%d°" % a, "?"] if hide == 1 else ["?", "%d°" % (180 - a)]
		answer = int(angles[hide])
		explain = "Angles on a straight line add up to 180°: 180 − %d = %d°." % [int(angles[1 - hide]), answer]
	elif rng.randf() < 0.5:
		var b := rng.randi_range(4, 14) * 10 + (rng.randi_range(0, 1) * 5 if rng.randf() < 0.5 else 0)
		if (180 - b) % 2 != 0:
			b += 5
		var a := (180 - b) / 2
		angles = [a, b, a]
		labels = ["a", "%d°" % b, "a"]
		answer = a
		prompt = "The angles are on a straight line, and the two marked a are equal. What is a, in degrees?"
		explain = "180 − %d = %d, and the two equal angles share it: %d ÷ 2 = %d°." % [b, 180 - b, 180 - b, a]
	else:
		var a := rng.randi_range(25, 80)
		var b := rng.randi_range(25, 150 - a)
		angles = [a, b, 180 - a - b]
		var hide := rng.randi_range(0, 2)
		for i in 3:
			labels.append("?" if i == hide else "%d°" % int(angles[i]))
		answer = int(angles[hide])
		var known: Array = []
		for i in 3:
			if i != hide:
				known.append(int(angles[i]))
		explain = "Angles on a straight line add up to 180°: 180 − %d − %d = %d°." % [known[0], known[1], answer]
	var ex := K.number(prompt, str(answer), "Angles on a straight line add up to 180°. Take the angles you know away from 180.",
		explain, {"kind": "angle_facts", "figure": "straight", "angles": angles, "labels": labels})
	ex.data = {"figure": "straight", "angles": angles, "labels": labels}
	return ex


## Angles round a point add up to 360°: three (level 1, in tens), four (level 2), or equal angles marked a (level 3).
static func angle_point(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var angles: Array = []
	var labels: Array = []
	var prompt := "The angles are round a point. What is the angle marked ?, in degrees?"
	var answer: int
	var explain: String
	match level:
		1, 2:
			var n := 3 if level == 1 else 4
			for _i in 60:
				angles = []
				var left := 360
				for i in n - 1:
					var a := rng.randi_range(4, 15) * 10 if level == 1 else rng.randi_range(40, 150)
					angles.append(a)
					left -= a
				angles.append(left)
				if left >= 40 and left <= 200:
					break
			if int(angles[-1]) < 40 or int(angles[-1]) > 200:
				angles = [120, 100, 140] if n == 3 else [80, 95, 100, 85]
			var hide := rng.randi_range(0, n - 1)
			var known: Array = []
			for i in n:
				labels.append("?" if i == hide else "%d°" % int(angles[i]))
				if i != hide:
					known.append(str(angles[i]))
			answer = int(angles[hide])
			explain = "Angles round a point add up to 360°: 360 − %s = %d°." % [" − ".join(known), answer]
		_:
			var equal := rng.randi_range(2, 3)
			var known_n := 4 - equal if equal == 2 else 1
			var known: Array = []
			var used := 0
			for i in known_n:
				var a := rng.randi_range(5, 12) * 10
				known.append(a)
				used += a
			var rest := 360 - used
			while rest % equal != 0:
				known[0] = int(known[0]) + 10
				used += 10
				rest = 360 - used
			var a := rest / equal
			for k: int in known:
				angles.append(k)
				labels.append("%d°" % k)
			for i in equal:
				angles.append(a)
				labels.append("a")
			answer = a
			prompt = "The angles are round a point, and the angles marked a are equal. What is a, in degrees?"
			var known_text: Array = []
			for k: int in known:
				known_text.append(str(k))
			explain = "360 − %s = %d, shared by %d equal angles: %d ÷ %d = %d°." % [" − ".join(known_text), rest, equal, rest,
				equal, a]
	var ex := K.number(prompt, str(answer),
		"A full turn round a point is 360°. Take the angles you know away from 360.", explain,
		{"kind": "angle_facts", "figure": "point", "angles": angles, "labels": labels})
	ex.data = {"figure": "point", "angles": angles, "labels": labels}
	return ex


## Two straight lines cross: the angle opposite one given (level 1: equal), next to it (level 2: 180° take away), or b
## when the two a's are given together (level 3).
static func angle_cross(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(25, 155)
	while a == 90:
		a = rng.randi_range(25, 155)
	if level == 3:
		a = rng.randi_range(15, 75) * 2
		if a == 90:
			a = 100
	var angles: Array = [a, 180 - a, a, 180 - a]
	var given := rng.randi_range(0, 3)
	var labels: Array = ["", "", "", ""]
	var prompt := "Two straight lines cross. What is the angle marked ?, in degrees?"
	var answer: int
	var explain: String
	var hint: String
	match level:
		1:
			var ask := (given + 2) % 4
			labels[given] = "%d°" % int(angles[given])
			labels[ask] = "?"
			answer = int(angles[ask])
			hint = "Look at the angle across the crossing from it. Vertically opposite angles are equal."
			explain = "The ? is vertically opposite the %d° angle, and vertically opposite angles are equal: %d°." % [answer,
				answer]
		2:
			var ask := (given + 1) % 4
			labels[given] = "%d°" % int(angles[given])
			labels[ask] = "?"
			answer = int(angles[ask])
			hint = "The ? and the angle you know sit side by side on one straight line."
			explain = "They are on a straight line, so they add up to 180°: 180 − %d = %d°." % [int(angles[given]), answer]
		_:
			labels = ["a", "b", "a", ""]
			answer = int(angles[1])
			prompt = "Two straight lines cross. The two angles marked a add up to %d°. What is angle b, in degrees?" % (a * 2)
			hint = "The a's are vertically opposite, so they are equal: find one a first. Then use the straight line."
			explain = "Each a is %d ÷ 2 = %d°. a and b are on a straight line: 180 − %d = %d°." % [a * 2, a, a, answer]
	var ex := K.number(prompt, str(answer), hint, explain,
		{"kind": "angle_facts", "figure": "cross", "angles": angles, "labels": labels})
	ex.data = {"figure": "cross", "angles": angles, "labels": labels, "a_sum": a * 2 if level == 3 else 0}
	return ex


## A triangle's angles add up to 180°: two given in tens (level 1), any two or a right angle (level 2), an isosceles
## triangle's base or top angle (level 3).
static func triangle_angle(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var angles: Array
	var labels: Array = []
	var ticks: Array = []
	var prompt := "What is the angle marked ? in the triangle, in degrees?"
	var answer: int
	var explain: String
	var hint := "The angles in a triangle add up to 180°. Take the angles you know away from 180."
	if level < 3:
		var a: int
		var b: int
		if level == 1:
			a = rng.randi_range(3, 9) * 10
			b = rng.randi_range(3, mini(9, 15 - a / 10)) * 10
		elif rng.randf() < 0.4:
			a = 90
			b = rng.randi_range(20, 70)
		else:
			a = rng.randi_range(25, 110)
			b = rng.randi_range(25, 150 - a)
		angles = [a, b, 180 - a - b]
		var order := [0, 1, 2]
		K.shuffle(rng, order)
		angles = [angles[order[0]], angles[order[1]], angles[order[2]]]
		var hide := rng.randi_range(0, 2)
		if int(angles[hide]) == 90:
			hide = (hide + 1) % 3
		var known: Array = []
		for i in 3:
			if i == hide:
				labels.append("?")
			else:
				labels.append("" if int(angles[i]) == 90 else "%d°" % int(angles[i]))
				known.append(str(angles[i]))
		answer = int(angles[hide])
		if (angles as Array).has(90):
			prompt = "The triangle has a right angle (the square corner). What is the angle marked ?, in degrees?"
		explain = "180 − %s = %d°." % [" − ".join(known), answer]
	else:
		if rng.randf() < 0.5:
			var top := rng.randi_range(2, 14) * 10
			if top == 90:
				top = 100
			var base := (180 - top) / 2
			angles = [base, base, top]
			labels = ["?", "", "%d°" % top] if rng.randf() < 0.5 else ["", "?", "%d°" % top]
			answer = base
			explain = "The two base angles are equal: 180 − %d = %d, and %d ÷ 2 = %d°." % [top, 180 - top, 180 - top, base]
		else:
			var base := rng.randi_range(25, 80)
			if base == 45:
				base = 50
			angles = [base, base, 180 - 2 * base]
			labels = ["%d°" % base, "", "?"] if rng.randf() < 0.5 else ["", "%d°" % base, "?"]
			answer = 180 - 2 * base
			explain = "The two base angles are equal, both %d°: 180 − %d − %d = %d°." % [base, base, base, answer]
		ticks = [1, 2]
		prompt = "The triangle is isosceles: the two sides marked are equal, so the angles at the bottom are equal. What is ?, in degrees?"
		hint = "In an isosceles triangle the two angles at the ends of the third side are equal. The three add up to 180°."
	var pic := {"kind": "angle_facts", "figure": "triangle", "angles": angles, "labels": labels}
	if not ticks.is_empty():
		pic.ticks = ticks
	var ex := K.number(prompt, str(answer), hint, explain, pic)
	ex.data = {"figure": "triangle", "angles": angles, "labels": labels, "isosceles": not ticks.is_empty()}
	return ex


## A quadrilateral's angles add up to 360°: three given in tens (level 1), any three (level 2), a parallelogram's
## angles or two equal angles marked a (level 3).
static func quad_angle(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var angles: Array = []
	var labels: Array = []
	var prompt := "What is the angle marked ? in the quadrilateral, in degrees?"
	var hint := "The angles in a quadrilateral add up to 360°. Take the angles you know away from 360."
	var answer: int
	var explain: String
	if level < 3:
		for _i in 50:
			angles = []
			var left := 360
			for i in 3:
				var a := rng.randi_range(6, 14) * 10 if level == 1 else rng.randi_range(55, 145)
				angles.append(a)
				left -= a
			angles.append(left)
			if left >= 50 and left <= 150:
				break
		if int(angles[3]) < 50 or int(angles[3]) > 150:
			angles = [80, 100, 70, 110]
		var hide := rng.randi_range(0, 3)
		var known: Array = []
		for i in 4:
			labels.append("?" if i == hide else "%d°" % int(angles[i]))
			if i != hide:
				known.append(str(angles[i]))
		answer = int(angles[hide])
		explain = "360 − %s = %d°." % [" − ".join(known), answer]
	elif rng.randf() < 0.5:
		var a := rng.randi_range(5, 17) * 5
		if a == 90:
			a = 70
		angles = [a, 180 - a, a, 180 - a]
		var given := rng.randi_range(0, 3)
		var ask := (given + (1 if rng.randf() < 0.7 else 2)) % 4
		labels = ["", "", "", ""]
		labels[given] = "%d°" % int(angles[given])
		labels[ask] = "?"
		answer = int(angles[ask])
		prompt = "The quadrilateral is a parallelogram: its opposite angles are equal. What is the angle marked ?, in degrees?"
		hint = "Opposite angles of a parallelogram are equal, and two angles next to each other add up to 180°."
		if ask == (given + 2) % 4:
			explain = "The ? is opposite the %d° angle, and opposite angles of a parallelogram are equal: %d°." % [answer, answer]
		else:
			explain = "Next to each other, they add up to 180° (half of 360°): 180 − %d = %d°." % [int(angles[given]), answer]
	else:
		var p := rng.randi_range(8, 13) * 10
		var q := rng.randi_range(6, 12) * 10
		while (360 - p - q) % 2 != 0 or (360 - p - q) / 2 >= 170 or (360 - p - q) / 2 < 40:
			q += 10
			if q > 150:
				q = 60
				p -= 10
		var a := (360 - p - q) / 2
		angles = [a, p, a, q]
		labels = ["a", "%d°" % p, "a", "%d°" % q]
		answer = a
		prompt = "The two angles marked a are equal. What is a, in degrees?"
		explain = "360 − %d − %d = %d, shared by the two equal angles: %d ÷ 2 = %d°." % [p, q, 360 - p - q, 360 - p - q, a]
	var ex := K.number(prompt, str(answer), hint, explain,
		{"kind": "angle_facts", "figure": "quad", "angles": angles, "labels": labels})
	ex.data = {"figure": "quad", "angles": angles, "labels": labels}
	return ex


# --- Forces and machines ------------------------------------------------------------------------------------------------

## Which force is at work: everyday situations (level 1, three choices), trickier ones (level 2), shapes and grips
## (level 3), always with the four forces the unit teaches.
static func force_name(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var bank: Array = FORCE_SITUATIONS[level - 1]
	var pick: Array = bank[rng.randi_range(0, bank.size() - 1)]
	var right := str(pick[1])
	var wrongs: Array = []
	for f in FORCES:
		if f != right:
			wrongs.append(f)
	K.shuffle(rng, wrongs)
	if level == 1:
		wrongs.resize(2)
	var ex := K.choice(rng, "%s Which force is this about?" % pick[0], right, wrongs,
		"Gravity pulls things down. Friction acts where surfaces rub. Air and water resistance push against moving things.",
		"%s: %s." % [_cap(right), _force_why(right)])
	ex.data = {"situation": pick[0]}
	return ex


static func _force_why(force: String) -> String:
	match force:
		"gravity":
			return "the pull of the Earth (or another big mass) on everything"
		"friction":
			return "two surfaces rubbing against each other slow the movement or grip"
		"air resistance":
			return "the air pushes against things moving through it"
	return "the water pushes against things moving through it"


## Friction tests: which of two surfaces has more friction (level 1); a table of how far a toy car rolled, and which
## surface had the most friction (level 2); the surfaces in order, or how much farther (level 3).
static func friction_test(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 1:
		var i := rng.randi_range(0, SURFACES.size() - 2)
		var j := rng.randi_range(i + 1, SURFACES.size() - 1)
		var more_friction := rng.randf() < 0.5
		var right := SURFACES[j] if more_friction else SURFACES[i]
		var ex := K.choice(rng, "A crate slides across %s and across %s. Where is there %s friction?" % [
			SURFACES[i], SURFACES[j], "more" if more_friction else "less"], right, [SURFACES[j] if not more_friction else SURFACES[i]],
			"Rough surfaces grip and rub more; smooth, slippery ones rub less.",
			"%s is %s than %s, so there is %s friction on %s." % [_cap(right), "rougher" if more_friction else "smoother",
				SURFACES[i] if more_friction else SURFACES[j], "more" if more_friction else "less", right])
		ex.data = {"surfaces": [SURFACES[i], SURFACES[j]], "ask": "more" if more_friction else "less"}
		return ex
	var n := 3 if level == 2 else 4
	var idx: Array = range(SURFACES.size())
	K.shuffle(rng, idx)
	idx = idx.slice(0, n)
	idx.sort()
	var dist := {}
	var d := rng.randi_range(16, 20) * 10
	for k in idx:   # from the least friction: the car rolls farthest on the smoothest surface
		dist[SURFACES[k]] = d
		d -= rng.randi_range(2, 4) * 10
	var shown := idx.duplicate()
	K.shuffle(rng, shown)
	var rows: Array = [["Surface", "Distance"]]
	for k: int in shown:
		rows.append([SURFACES[k], "%d cm" % int(dist[SURFACES[k]])])
	var pic := {"kind": "table", "rows": rows}
	var ex: Dictionary
	var hint := "Friction slows the car. The more friction, the shorter the distance it rolls."
	if level == 2:
		var most: String = SURFACES[idx[-1]]
		var others: Array = []
		for k: int in idx:
			if SURFACES[k] != most:
				others.append(SURFACES[k])
		ex = K.choice(rng, "Bram rolled a toy car down the same ramp onto each surface. Which surface had the most friction?",
			most, others, hint, "The car stopped soonest on %s (%d cm): the most friction slowed it most." % [most,
				int(dist[most])], pic)
	elif rng.randf() < 0.5:
		var in_order: Array = []
		for k: int in idx:
			in_order.append(SURFACES[k])
		ex = K.order(rng, "Bram rolled a toy car down the same ramp onto each surface. Put the surfaces in order, from the least friction to the most.", in_order, hint,
			"The farther the car rolled, the less friction: %s." % ", then ".join(in_order), pic)
	else:
		var a: String = SURFACES[idx[0]]
		var b: String = SURFACES[idx[-1]]
		ex = K.number("Bram rolled a toy car down the same ramp onto each surface. How much farther did it roll on %s than on %s, in cm?" % [a, b],
			str(int(dist[a]) - int(dist[b])), "Find both distances in the table, then take the smaller from the bigger.",
			"%d − %d = %d cm farther on %s." % [int(dist[a]), int(dist[b]), int(dist[a]) - int(dist[b]), a], pic)
	ex.data = {"distances": dist}
	return ex


## Levers: which of two (level 1) or three (levels 2-3) levers lifts the same load with the smallest push; the load sits
## at the same place, the push farther from or nearer to the pivot.
static func lever_push(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := 2 if level == 1 else 3
	var pivot := rng.randi_range(2, 4)
	var load := pivot - rng.randi_range(1, 2)
	var spots: Array = []
	var gaps: Array = [[3, 6], [2, 4, 6], [3, 4, 5]][level - 1]
	for g: int in gaps:
		if pivot + g <= 10:
			spots.append(pivot + g)
	while spots.size() < n:
		spots.append(10 - spots.size())
	spots = spots.slice(0, n)
	var far: int = spots.max()
	var choices: Array = []
	for s: int in spots:
		choices.append({"picture": {"kind": "lever", "pivot": pivot, "load": load, "effort": s}})
	var right: Dictionary = choices[spots.find(far)]
	var wrongs: Array = []
	for c: Dictionary in choices:
		if c != right:
			wrongs.append(c)
	var ex := K.choice(rng, "Which lever lifts the same load with the smallest push (effort)?", right, wrongs,
		"The farther from the pivot you push, the less effort you need.",
		"The push farthest from the pivot, %d steps away, needs the least effort: a long lever arm." % (far - pivot))
	ex.data = {"pivot": pivot, "load": load, "efforts": spots}
	return ex


## Gears and pulleys: which way the second gear turns (level 1); how many turns a small gear makes for one turn of a big
## one (level 2); the last of three gears' turn, or the effort with a moving pulley (level 3).
static func machine_gears(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var a: int = [8, 10, 12][rng.randi_range(0, 2)]
			var b := a * rng.randi_range(2, 3)
			var turn: String = ["cw", "acw"][rng.randi_range(0, 1)]
			var right := "anticlockwise" if turn == "cw" else "clockwise"
			ex = K.choice(rng, "The first gear turns %s. Which way does the second gear turn?" % (
				"clockwise" if turn == "cw" else "anticlockwise"), right, ["clockwise" if turn == "cw" else "anticlockwise"],
				"Meshing gears push each other's teeth. Do they turn the same way or opposite ways?",
				"Meshing gears turn opposite ways, so the second gear turns %s." % right,
				{"kind": "gears", "gears": [a, b], "turn": turn})
			ex.data = {"gears": [a, b], "turn": turn}
		2:
			var small: int = [8, 10][rng.randi_range(0, 1)]
			var times := rng.randi_range(2, 4)
			var big := small * times
			ex = K.number("A gear with %d teeth drives a gear with %d teeth. How many times does the small gear turn while the big gear turns once?" % [
				small, big], str(times), "Each turn of the small gear moves %d teeth past. How many lots of %d make %d?" % [
				small, small, big], "%d ÷ %d = %d: the small gear turns %d times, so the big gear turns slower but with more force." % [
				big, small, times, times], {"kind": "gears", "gears": [small, big], "turn": "cw", "marks": true})
			ex.data = {"gears": [small, big]}
		_:
			if rng.randf() < 0.5:
				var gears: Array = []
				for _i in 3:
					gears.append(rng.randi_range(2, 6) * 5)
				var turn: String = ["cw", "acw"][rng.randi_range(0, 1)]
				var right := "clockwise" if turn == "cw" else "anticlockwise"
				ex = K.choice(rng, "Three gears mesh in a row. The first turns %s. Which way does the third gear turn?" % right,
					right, ["anticlockwise" if turn == "cw" else "clockwise"],
					"Each gear turns the opposite way to the one before it. Follow them one at a time.",
					"The second turns the opposite way, and the third the opposite way again: %s, like the first." % right,
					{"kind": "gears", "gears": gears, "turn": turn})
				ex.data = {"gears": gears, "turn": turn}
			else:
				var load := rng.randi_range(3, 12) * 20
				ex = K.number("A moving pulley halves the effort needed. About how many newtons of effort lift a %d N crate with it?" % load,
					str(load / 2), "The rope holds the moving pulley on both sides, so each side takes half of the load.",
					"%d ÷ 2 = %d N: half the effort, but you pull twice as much rope." % [load, load / 2],
					{"kind": "pulleys", "lift": 2, "labels": true})
				ex.data = {"load": load}
	return ex


# --- Electric systems ----------------------------------------------------------------------------------------------------

## How many lamps light: a series circuit with a switch (level 1); two parallel branches, each maybe with its switch
## (level 2); a main switch too, or three branches, or true or false about one lettered lamp (level 3).
static func circuit_lit(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pic := {"kind": "circuit_symbols"}
	match level:
		1:
			var lamps := rng.randi_range(1, 3)
			var series: Array = []
			for i in lamps:
				series.append("lamp")
			series.insert(rng.randi_range(0, series.size()), ["open", "closed"][rng.randi_range(0, 1)])
			pic.series = series
		2:
			var branches: Array = []
			for b in 2:
				var row: Array = ["lamp"]
				if rng.randf() < 0.6:
					row.insert(rng.randi_range(0, 1), ["open", "closed"][rng.randi_range(0, 1)])
				branches.append(row)
			pic.branches = branches
		_:
			var branches: Array = []
			for b in rng.randi_range(2, 3):
				var row: Array = ["lamp"]
				if rng.randf() < 0.6:
					row.insert(rng.randi_range(0, 1), ["open", "closed"][rng.randi_range(0, 1)])
				branches.append(row)
			pic.branches = branches
			pic.main = [["open", "closed", "closed"][rng.randi_range(0, 2)]]
	var powers := _power(pic)
	var lit := 0
	for p: float in powers:
		if p > 0.0:
			lit += 1
	var ex: Dictionary
	var hint := "Follow each path from the cell and back. A lamp lights only if its path has no open switch."
	var why := _circuit_why(pic)
	if level == 3 and rng.randf() < 0.4:
		pic.tags = true
		var i := rng.randi_range(0, powers.size() - 1)
		var letter := "ABCDEFGH"[i]
		ex = K.truefalse("Lamp %s lights." % letter, float(powers[i]) > 0.0, hint,
			"%s %s." % [why, "So lamp %s lights" % letter if float(powers[i]) > 0.0 else "So lamp %s stays off" % letter], pic)
		ex.data = {"ask": i}
	else:
		ex = K.number("How many lamps light in this circuit?", str(lit), hint, "%s %s." % [why,
			"1 lamp lights" if lit == 1 else "%d lamps light" % lit], pic)
		ex.data = {"ask": -1}
	return ex


## How hard each lamp, buzzer or motor works (the picture's rule, SchoolPictureG5Core.power): 0 on a path an open
## switch breaks, otherwise the cells shared by the loads on its path.
static func _power(pic: Dictionary) -> Array:
	var rows: Array = pic.branches if pic.has("branches") else [pic.series]
	var main_closed := not (pic.get("main", []) as Array).has("open")
	var out: Array = []
	for row: Array in rows:
		var loads := row.filter(func(x: Variant) -> bool: return str(x) in ["lamp", "buzzer", "motor"]).size()
		for x: Variant in row:
			if str(x) in ["lamp", "buzzer", "motor"]:
				out.append(float(pic.get("cells", 1)) / loads if main_closed and not row.has("open") else 0.0)
	return out


## Why a circuit's lamps light or not, in words.
static func _circuit_why(pic: Dictionary) -> String:
	if pic.has("series"):
		if (pic.series as Array).has("open"):
			return "The switch is open, so the only loop is broken."
		return "The switch is closed, so the loop is complete."
	if (pic.get("main", []) as Array).has("open"):
		return "The main switch is open, so no path is complete."
	var open := 0
	for row: Array in pic.branches:
		if row.has("open"):
			open += 1
	if open == 0:
		return "Every branch is a complete path from the cell and back."
	return "A branch with an open switch is broken, but the other branches still make complete paths."


## Brighter, dimmer or the same as one lamp on one cell: lamps and cells in series (level 1), parallel branches too
## (level 2), or which of three circuits has the brightest lamp (level 3).
static func circuit_bright(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 3:
		var options: Array = [{"series": ["lamp"], "cells": 2}, {"series": ["lamp", "lamp"]}, {"series": ["lamp"]},
			{"series": ["lamp", "lamp", "lamp"], "cells": 2}, {"branches": [["lamp"], ["lamp"]]},
			{"series": ["lamp"], "cells": 3}, {"series": ["lamp", "lamp"], "cells": 3}]
		var picks: Array = []
		var best := -1.0
		for _i in 40:
			var idx: Array = range(options.size())
			K.shuffle(rng, idx)
			picks = [options[idx[0]], options[idx[1]], options[idx[2]]]
			var vals: Array = []
			for p: Dictionary in picks:
				var pd := p.duplicate(true)
				pd.kind = "circuit_symbols"
				vals.append(float(_power(pd)[0]))
			var top: float = vals.max()
			if vals.count(top) == 1:
				best = top
				break
		var choices: Array = []
		var right: Dictionary = {}
		for p: Dictionary in picks:
			var pd := p.duplicate(true)
			pd.kind = "circuit_symbols"
			var c := {"picture": pd}
			choices.append(c)
			if float(_power(pd)[0]) == best:
				right = c
		var wrongs: Array = []
		for c: Dictionary in choices:
			if c != right:
				wrongs.append(c)
		var ex := K.choice(rng, "In which circuit does a lamp glow brightest?", right, wrongs,
			"More cells push harder: brighter. More lamps in one loop share the push: dimmer. Parallel lamps each get the full push.",
			"The brightest lamp has the most cells for each lamp on its path: %s." % _bright_words(right.picture))
		ex.data = {"circuits": picks}
		return ex
	var options: Array = [[1, 2, false], [2, 1, false], [3, 1, false], [1, 3, false]] if level == 1 else \
		[[1, 2, true], [1, 3, true], [2, 2, false], [3, 3, false], [2, 1, false], [1, 2, false], [2, 3, false],
		[3, 2, false]]
	var o: Array = options[rng.randi_range(0, options.size() - 1)]
	var cells: int = o[0]
	var lamps: int = o[1]
	var pic := {"kind": "circuit_symbols", "cells": cells}
	if bool(o[2]):
		var branches: Array = []
		for i in lamps:
			branches.append(["lamp"])
		pic.branches = branches
	else:
		var series: Array = []
		for i in lamps:
			series.append("lamp")
		pic.series = series
	var p := float(_power(pic)[0])
	var right := BRIGHTER if p > 1.0 else (DIMMER if p < 1.0 else SAME)
	var ex := K.choice(rng, "Compared with one lamp on one cell, are the lamps in this circuit brighter, dimmer or the same?",
		right, [BRIGHTER, DIMMER, SAME], "Count the cells and the lamps on each lamp's path. More cells: brighter; more lamps sharing one path: dimmer.",
		"%s, so each lamp glows %s." % [_cap(_bright_words(pic)), {BRIGHTER: "more brightly", DIMMER: "more dimly",
			SAME: "just as brightly"}[right]], pic)
	ex.data = {"cells": cells, "lamps": lamps, "parallel": bool(o[2])}
	return ex


static func _bright_words(pic: Dictionary) -> String:
	var cells := int(pic.get("cells", 1))
	var cell_words := "%d cell%s" % [cells, "" if cells == 1 else "s"]
	if pic.has("branches"):
		return "%s, and each lamp on its own branch" % cell_words
	var lamps := (pic.series as Array).size()
	return "%s for %d lamp%s in one loop" % [cell_words, lamps, "" if lamps == 1 else "s"]


## The circuit symbols: what a symbol stands for (level 1: cell, lamp and switches; level 2: all of them), or which
## symbol is a given part (level 3, the symbols as pictures).
static func circuit_symbol(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var bank: Array = ["cell", "lamp", "open", "closed"] if level == 1 else ["cell", "battery", "lamp", "open", "closed",
		"buzzer", "motor"]
	var idx: Array = range(bank.size())
	K.shuffle(rng, idx)
	var sym: String = bank[idx[0]]
	var ex: Dictionary
	if level < 3:
		var wrongs: Array = []
		for k in range(1, 4):
			wrongs.append(SYMBOL_WORDS[bank[idx[k]]])
		ex = K.choice(rng, "What does this circuit symbol stand for?", SYMBOL_WORDS[sym], wrongs,
			"Think of the real part: a lamp's filament makes a cross, a switch has a gap, a cell has a long and a short line.",
			"This is the symbol for %s." % SYMBOL_WORDS[sym], {"kind": "circuit_symbols", "symbols": [sym], "names": false})
	else:
		var choices: Array = []
		for k in 3:
			choices.append({"picture": {"kind": "circuit_symbols", "symbols": [bank[idx[k]]], "names": false}})
		ex = K.choice(rng, "Which symbol is %s?" % SYMBOL_WORDS[sym], choices[0], choices.slice(1),
			"Picture the real part, then find the symbol that looks like its shape or job.",
			"%s is drawn like this: %s." % [_cap(str(SYMBOL_WORDS[sym])), _symbol_looks(sym)])
	ex.data = {"symbol": sym}
	return ex


static func _symbol_looks(sym: String) -> String:
	match sym:
		"cell":
			return "a long line and a short, thick line"
		"battery":
			return "two cells joined together"
		"lamp":
			return "a circle with a cross inside"
		"open":
			return "a line lifted away, leaving a gap"
		"closed":
			return "a line joining the two contacts"
		"buzzer":
			return "a dome shape on two legs"
	return "a circle with M inside"


# --- How living things reproduce ------------------------------------------------------------------------------------------

## Life cycles: three stages in order (level 1), four (level 2), or the stage missing from a drawn cycle (level 3).
static func cycle_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = []
	for c: Array in CYCLES:
		if (level < 3 and int(c[3]) == level) or (level == 3 and (c[1] as Array).size() >= 4):
			pool.append(c)
	var c: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var ex: Dictionary
	if level < 3:
		ex = K.order(rng, "Put the %s's life cycle in order, starting at the beginning." % c[0], c[1],
			"What does it start as? What does each stage grow or change into next?",
			"The %s's life cycle: %s, and then it starts again." % [c[0], ", then ".join(c[1] as Array)])
	else:
		var labels: Array = c[2]
		var hide := rng.randi_range(0, labels.size() - 1)
		var right := str(labels[hide])
		var wrongs: Array = c[4]
		ex = K.choice(rng, "Which stage is missing from the %s's life cycle?" % c[0], right, wrongs,
			"Go round the cycle from the egg or the seed. What comes between the stages either side of the gap?",
			"The %s's cycle is %s: the missing stage is %s." % [c[0], ", ".join(labels), right],
			{"kind": "life_cycle", "stages": labels, "title": str(c[0]), "hide": hide})
	ex.data = {"animal": c[0]}
	return ex


## How seeds travel: from the plant's name (level 1), from a clue about the seed (level 2), or sorting plants by two
## ways (level 3).
static func seed_travel(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 3:
		var ways: Array = SEED_WAYS.slice(0, 5)   # the ways with two plants or more
		K.shuffle(rng, ways)
		ways = ways.slice(0, 2)
		var both: Array = []
		for w in 2:
			var of_way: Array = SEED_PLANTS.filter(func(p: Array) -> bool: return p[1] == ways[w])
			K.shuffle(rng, of_way)
			for p: Array in of_way.slice(0, 2):
				both.append([str(p[0]), w])
		K.shuffle(rng, both)
		var items: Array = []
		var answer: Array = []
		for b: Array in both:
			items.append(b[0])
			answer.append(b[1])
		var ex := {"type": "sort", "prompt": "Sort the plants by how their seeds travel.", "groups": ways, "items": items,
			"answer": answer, "hint": "Think about each seed's shape: wings and fluff for wind, hooks for fur, juicy fruit for eating.",
			"explain": "; ".join(items.map(func(it: String) -> String: return "%s: %s" % [it, _seed_way(it)])) + "."}
		ex.data = {"items": items}
		return ex
	var p: Array = SEED_PLANTS[rng.randi_range(0, SEED_PLANTS.size() - 1)]
	var wrongs: Array = []
	for w in SEED_WAYS:
		if w != p[1]:
			wrongs.append(w)
	K.shuffle(rng, wrongs)
	wrongs.resize(2 if level == 1 else 3)
	var prompt := "How do %s seeds travel away from the plant?" % p[0] if level == 1 else \
		"%s How do these seeds travel?" % p[2]
	var ex := K.choice(rng, prompt, str(p[1]), wrongs,
		"Seeds travel away so new plants have room and light. Look at the seed's shape: what could carry it?",
		"%s: %s. %s" % [_cap(str(p[0])), p[1], p[2]])
	ex.data = {"plant": p[0]}
	return ex


static func _seed_way(plant: String) -> String:
	for p: Array in SEED_PLANTS:
		if p[0] == plant:
			return str(p[1])
	return ""


## Eggs or live young: which animal gives birth to live young (level 1), sort four (level 2), sort six with a surprise
## mammal that lays eggs (level 3).
static func young_birth(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var eggs := LAYS_EGGS.duplicate()
	var alive := BORN_ALIVE.duplicate()
	K.shuffle(rng, eggs)
	K.shuffle(rng, alive)
	if level == 1:
		var ex := K.choice(rng, "Which of these animals gives birth to live young?", alive[0], [eggs[0], eggs[1]],
			"Mammals (with fur or hair, feeding their young on milk) are born alive; birds, insects, fish and frogs hatch from eggs.",
			"The %s is a mammal: its young are born alive and drink milk. The %s and the %s hatch from eggs." % [alive[0],
				eggs[0], eggs[1]])
		ex.data = {"right": alive[0]}
		return ex
	var n_alive := 2 if level == 2 else rng.randi_range(2, 3)
	var n_eggs := (4 if level == 2 else 6) - n_alive
	var items: Array = []
	for i in n_alive:
		items.append([alive[i], 1])
	for i in n_eggs:
		items.append([eggs[i], 0])
	if level == 3 and rng.randf() < 0.6:
		items[-1] = ["platypus", 0]
	K.shuffle(rng, items)
	var names: Array = []
	var answer: Array = []
	for it: Array in items:
		names.append(it[0])
		answer.append(it[1])
	var ex := {"type": "sort", "prompt": "Sort the animals: do they lay eggs, or give birth to live young?",
		"groups": ["lays eggs", "live young"], "items": names, "answer": answer,
		"hint": "Is it a mammal? Most mammals give birth to live young. Birds, insects, fish, frogs and reptiles lay eggs.",
		"explain": "Live young: %s. Eggs: %s.%s" % [", ".join(_group(names, answer, 1)), ", ".join(_group(names, answer, 0)),
			" The platypus is a mammal that lays eggs!" if names.has("platypus") else ""]}
	ex.data = {"items": names}
	return ex


static func _group(names: Array, answer: Array, g: int) -> Array:
	var out: Array = []
	for i in names.size():
		if int(answer[i]) == g:
			out.append(names[i])
	return out


# --- Breathing and the heart ------------------------------------------------------------------------------------------------

## The pulse (and breaths) in a minute: counted for 15 seconds (level 1), for 10 or 30 seconds, or breaths (level 2),
## and how much faster after exercise (level 3).
static func pulse_rate(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var ex: Dictionary
	match level:
		1:
			var beats := rng.randi_range(17, 25)
			ex = K.number("%s counts %d heartbeats in 15 seconds. How many beats is that in a minute?" % [who, beats],
				str(beats * 4), "A minute is 60 seconds. How many lots of 15 seconds make a minute?",
				"15 seconds × 4 = 1 minute, so %d × 4 = %d beats a minute." % [beats, beats * 4])
			ex.data = {"count": beats, "seconds": 15}
		2:
			var kind := rng.randi_range(0, 2)
			if kind == 0:
				var beats := rng.randi_range(12, 16)
				ex = K.number("%s counts %d heartbeats in 10 seconds. How many beats is that in a minute?" % [who, beats],
					str(beats * 6), "How many lots of 10 seconds make 60 seconds?",
					"10 seconds × 6 = 1 minute, so %d × 6 = %d beats a minute." % [beats, beats * 6])
				ex.data = {"count": beats, "seconds": 10}
			elif kind == 1:
				var beats := rng.randi_range(35, 48)
				ex = K.number("%s counts %d heartbeats in 30 seconds. How many beats is that in a minute?" % [who, beats],
					str(beats * 2), "How many lots of 30 seconds make 60 seconds?",
					"30 seconds × 2 = 1 minute, so %d × 2 = %d beats a minute." % [beats, beats * 2])
				ex.data = {"count": beats, "seconds": 30}
			else:
				var breaths := rng.randi_range(4, 6)
				ex = K.number("Sitting still, %s counts %d breaths in 15 seconds. How many breaths is that in a minute?" % [
					who, breaths], str(breaths * 4), "A minute is 60 seconds: four lots of 15 seconds.",
					"%d × 4 = %d breaths a minute." % [breaths, breaths * 4])
				ex.data = {"count": breaths, "seconds": 15}
		_:
			var rest := rng.randi_range(17, 23)
			var after := rng.randi_range(28, 38)
			var what: String = ["skipping", "running", "dancing", "swimming"][rng.randi_range(0, 3)]
			ex = K.number("%s counts %d beats in 15 seconds at rest, and %d beats in 15 seconds after %s. How many more beats a minute is that after %s?" % [
				who, rest, after, what, what], str((after - rest) * 4),
				"Find how many more beats there were in 15 seconds, then times by 4 for a whole minute.",
				"%d − %d = %d more beats in 15 seconds, and %d × 4 = %d more a minute: the muscles need more oxygen." % [
					after, rest, after - rest, after - rest, (after - rest) * 4])
			ex.data = {"count": rest, "after": after, "seconds": 15}
	return ex


## Paths through the body: the air's path in (level 1), the blood's path through the heart and lungs (level 2), or
## five steps of the blood's loop from any place (level 3).
static func body_path(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var steps: Array
	var prompt: String
	var hint: String
	match level:
		1:
			var n := rng.randi_range(3, 4)
			steps = AIR_PATH.slice(0, n) if n == 4 or rng.randf() < 0.5 else AIR_PATH.slice(1, 4)
			prompt = "Put the air's path in order as you breathe in."
			hint = "Air goes in through your face, down a tube in your neck, and into your chest."
		2:
			steps = BLOOD_LOOP.slice(1, 5)
			prompt = "Put the blood's path in order, starting as it comes back from the body."
			hint = "The heart pumps blood to the lungs to pick up oxygen before it goes round the body again."
		_:
			var start := rng.randi_range(0, BLOOD_LOOP.size() - 1)
			steps = []
			for i in 5:
				steps.append(BLOOD_LOOP[(start + i) % BLOOD_LOOP.size()])
			prompt = "Put five steps of the blood's loop in order, starting with: %s." % steps[0]
			hint = "The blood goes round and round: body, heart, lungs, heart, body. Follow it from the first step."
	var ex := K.order(rng, prompt, steps, hint, "In order: %s." % "; ".join(steps))
	ex.data = {"steps": steps}
	return ex


## Match body parts to their jobs: the heart, lungs, windpipe and diaphragm (level 1), blood vessels and air sacs (level
## 2), the blood's parts (level 3).
static func organ_match(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pairs: Array = (JOBS[level - 1] as Array).duplicate()
	K.shuffle(rng, pairs)
	if level == 1:
		pairs = pairs.slice(0, 3)
	var items: Array = []
	var jobs: Array = []
	for p: Array in pairs:
		items.append(p[0])
		jobs.append(p[1])
	var order: Array = range(jobs.size())
	for _i in 8:
		K.shuffle(rng, order)
		var same := false
		for i in order.size():
			if int(order[i]) == i:
				same = true
		if not same:
			break
	if order == range(order.size()):
		order.reverse()
	var matches: Array = []
	for i: int in order:
		matches.append(jobs[i])
	var answer: Array = []
	for j in jobs:
		answer.append(matches.find(j))
	var worked: Array = []
	for p: Array in pairs:
		worked.append("%s: %s" % [_cap(str(p[0])), p[1]])
	var ex := {"type": "match", "prompt": "Match each part of the body to its job.", "items": items, "matches": matches,
		"answer": answer, "hint": "Start with the part you are surest of, then match the rest.",
		"explain": ". ".join(worked) + "."}
	ex.data = {"items": items}
	return ex


# --- English --------------------------------------------------------------------------------------------------------------

## Quote to prove it: which sentence of a short text proves a point it says (level 1), a point you infer (level 2), or a
## point with a near miss among the choices (level 3).
static func quote_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = QUOTES.filter(func(q: Array) -> bool: return int(q[3]) == level)
	var q: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var sentences: Array = q[0]
	var right := str(sentences[int(q[2])])
	var wrongs: Array = []
	for s: Variant in sentences:
		if str(s) != right:
			wrongs.append(str(s))
	var ex := K.choice(rng, "Read: %s Which quote best proves that %s?" % [" ".join(sentences), q[1]], right, wrongs,
		"Test each quote: if you read only that sentence, would it show the point?",
		"\"%s\" shows that %s; the other sentences do not." % [right, q[1]])
	ex.data = {"claim": q[1]}
	return ex


## An exact quote: which copy is word for word the same as the text (a word changed, missing or added).
static func quote_exact(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = EXACT.filter(func(e: Array) -> bool: return int(e[2]) == level)
	var e: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var ex := K.choice(rng, "The text says: %s Which is an exact quote of it?" % e[0], str(e[0]), e[1],
		"Check every word, one at a time, against the text: nothing changed, left out or added.",
		"Only \"%s\" copies every word exactly. The others change, leave out or add a word." % e[0])
	ex.data = {"text": e[0]}
	return ex


## Where to look to answer a question quickly: parts of a book (level 1), other sources (level 2), trusted sources and
## word books (level 3).
static func source_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = SOURCES.filter(func(s: Array) -> bool: return int(s[3]) == level)
	var s: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var wrongs: Array = (s[2] as Array).duplicate()
	if level == 1:
		K.shuffle(rng, wrongs)
		wrongs.resize(2)
	var ex := K.choice(rng, "%s Where would you look first?" % s[0], str(s[1]), wrongs,
		"Think about what each source is for: meanings, pages, places, dates, numbers or trusted facts.",
		"%s is the quickest, most useful place for this." % _cap(str(s[1])))
	ex.data = {"question": s[0]}
	return ex


## Linking words for an opinion piece: choose the words for the gap (therefore, specifically, consequently, in contrast…).
static func opinion_link(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = LINKS.filter(func(l: Array) -> bool: return int(l[3]) == level)
	var l: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var ex := K.choice(rng, "Choose the linking words: %s" % l[0], str(l[1]), l[2],
		"Read the two sentences. Does the second give a result, an example, one more reason, or the other side?",
		"%s fits: %s" % [l[1], _link_job(str(l[1]))])
	ex.data = {"sentence": l[0]}
	return ex


static func _link_job(word: String) -> String:
	match word:
		"Therefore", "Consequently", "As a result":
			return "the second sentence is a result of the first."
		"Specifically", "In particular":
			return "the second sentence gives the exact detail."
		"For instance":
			return "the second sentence gives an example."
		"Furthermore", "Moreover":
			return "the second sentence adds one more reason."
	return "the second sentence shows the other side, a contrast."


## Formal or informal: the more formal of two (level 1), the one for a letter to a museum (level 2), or sort four
## sentences (level 3).
static func formal_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pairs: Array = FORMAL.duplicate()
	K.shuffle(rng, pairs)
	if level < 3:
		var p: Array = pairs[0]
		var prompt := "Which sentence is more formal?" if level == 1 else \
			"Which sentence would you write in a letter to a museum?"
		var wrongs: Array = [p[1]]
		if level == 2:
			wrongs.append((pairs[1] as Array)[1])
		var ex := K.choice(rng, prompt, str(p[0]), wrongs,
			"Formal writing uses full words (no short forms like don't), polite phrases and no slang.",
			"\"%s\" is formal: full words, polite and no slang." % p[0])
		ex.data = {"formal": p[0]}
		return ex
	var items: Array = []
	var answer: Array = []
	for i in 2:
		items.append((pairs[i] as Array)[0])
		answer.append(0)
		items.append((pairs[i + 2] as Array)[1])
		answer.append(1)
	var both: Array = []
	for i in items.size():
		both.append([items[i], answer[i]])
	K.shuffle(rng, both)
	items = []
	answer = []
	for b: Array in both:
		items.append(b[0])
		answer.append(b[1])
	var ex := {"type": "sort", "prompt": "Sort the sentences: formal or informal?", "groups": ["formal", "informal"],
		"items": items, "answer": answer,
		"hint": "Look for short forms (it's, I'd), slang (kids, loads) and chatty words: those are informal.",
		"explain": "Formal: %s Informal: %s" % [" ".join(_group(items, answer, 0)), " ".join(_group(items, answer, 1))]}
	ex.data = {"items": items}
	return ex


## An explanation's features: what a piece of text is (a definition, a caption, a quotation, a subheading…).
static func text_feature(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = FEATURE_TEXTS.filter(func(f: Array) -> bool: return int(f[2]) == level)
	var f: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var wrongs: Array = []
	for w in FEATURES:
		if w != f[1]:
			wrongs.append(w)
	K.shuffle(rng, wrongs)
	wrongs.resize(2 if level == 1 else 3)
	var ex := K.choice(rng, "What is this part of an explanation text? %s" % f[0], str(f[1]), wrongs,
		"Does it explain a word, name a section, describe a picture, repeat someone's words, sum up, or state a fact?",
		"It is %s: %s" % [f[1], _feature_job(str(f[1]))])
	ex.data = {"text": f[0]}
	return ex


static func _feature_job(feature: String) -> String:
	match feature:
		"a definition":
			return "it explains what a word means."
		"a quotation":
			return "it gives someone's exact words in speech marks, and says who said them."
		"a caption":
			return "it tells you what a picture shows."
		"a subheading":
			return "it names the section below it, so readers can find what they need."
		"a conclusion":
			return "it sums up the main ideas at the end."
		"a glossary entry":
			return "a special word and its meaning, listed at the back."
	return "a true piece of information that can be checked."


## Show, don't tell: the sentence that shows a feeling without naming it (levels 1-2), or the feeling a sentence shows
## (level 3).
static func show_feeling(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = FEELINGS.duplicate()
	K.shuffle(rng, pool)
	var f: Array = pool[0]
	var ex: Dictionary
	if level < 3:
		var name := str(f[2]).split(" ")[0]
		var wrongs: Array = [f[2], (pool[1] as Array)[1]]
		if level == 2:
			wrongs.append((pool[2] as Array)[1])
		ex = K.choice(rng, "Which sentence SHOWS that %s is %s, without saying the word?" % [name, f[0]], str(f[1]), wrongs,
			"Look for what the character does and how their body reacts, not a sentence that names the feeling.",
			"\"%s\" shows it through actions. \"%s\" only tells it." % [f[1], f[2]])
	else:
		var wrongs: Array = [(pool[1] as Array)[0], (pool[2] as Array)[0], (pool[3] as Array)[0]]
		ex = K.choice(rng, "What feeling does this sentence show? %s" % f[1], str(f[0]), wrongs,
			"Picture the character doing this. When do people act like that?",
			"The actions show the character is %s." % f[0])
	ex.data = {"feeling": f[0]}
	return ex


## Speech marks: the sentence punctuated right: a comma or a question or exclamation mark inside the speech marks, a
## capital letter to start the speech, and a split sentence carrying on in small letters.
static func speech_marks(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = SPEECH.filter(func(s: Array) -> bool: return int(s[2]) == level)
	var s: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var wrongs: Array = (s[1] as Array).duplicate()
	if level == 1:
		K.shuffle(rng, wrongs)
		wrongs.resize(2)
	var ex := K.choice(rng, "Which is punctuated correctly?", str(s[0]), wrongs,
		"Check: speech marks round the spoken words, the comma, ? or ! inside them, and a capital letter to start the speech.",
		"%s has speech marks round the words spoken, its punctuation inside them, and capital letters in the right places." % s[0])
	ex.data = {"right": s[0]}
	return ex


## Summarise what a speaker said: the best short summary of a talk (the main points, not a detail or something new).
static func summary_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = TALKS.filter(func(t: Array) -> bool: return int(t[3]) == level)
	var t: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var ex := K.choice(rng, "A speaker said: %s Which is the best summary?" % t[0], str(t[1]), t[2],
		"A good summary gives all the main points in a few words: not just one detail, and nothing the speaker did not say.",
		"\"%s\" covers every main point briefly." % t[1])
	ex.data = {"talk": t[0]}
	return ex


# --- Helpers ----------------------------------------------------------------------------------------------------------------

static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1) if s != "" else s
