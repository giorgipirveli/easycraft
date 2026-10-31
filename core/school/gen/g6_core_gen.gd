class_name G6CoreGen
extends RefCounted
## Owner #70 and #73 (research §6.6): grade 6 maths, science and English generators for the research's last units: the
## problem-solving toolkit (working backwards through a function machine, bar models, systematic lists, guess and check,
## growing patterns, choosing a strategy); skeleton and muscles (bones and their jobs, muscle pairs, joints); nutrition
## and digestion (nutrients, food tests, enzymes); classifying life (vertebrate and invertebrate groups, keys, kingdoms,
## the levels); light (shadows by the rays' straight lines, reflected angles, sources, materials and seeing); energy
## changes (forms, waste and efficiency, saving energy); engineering design (criteria and constraints, choosing from test
## results, decision matrices, repeated trials); and in English: stated or inferred, the best evidence, stories and
## information texts, an argument's parts and links, formal writing, precise words, an information text's features,
## hooks, pace and vivid verbs, paraphrases, trustworthy sources, a source list in order, building on a speaker's idea,
## and the right chart. SchoolGen "g6k.<name>", `static func <name>(rng: RandomNumberGenerator, level: int) ->
## Dictionary`, seeded, level 1-3, each with a hint (a strategy), a worked answer and `data` (its inputs, for
## tests/unit/test_g6_core_gen.gd, which checks every answer with its own facts and arithmetic). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")

const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Oli", "Juno", "Kit", "Dot"]

# --- The problem-solving toolkit ---------------------------------------------------------------------------------------

## Stories for working backwards: [what happened (%d the number), the step it is].
const BACK_STEPS: Array = [["spent half of it", "÷ 2"], ["earned %d gold", "+ %d"], ["spent %d gold", "− %d"],
	["doubled it", "× 2"], ["found %d more", "+ %d"], ["gave %d to a friend", "− %d"]]
## Things to share in bar-model problems: [plural, singular].
const THINGS: Array = [["shells", "shell"], ["stamps", "stamp"], ["cards", "card"], ["marbles", "marble"],
	["stickers", "sticker"], ["seeds", "seed"]]
const BUYS: Array[String] = ["a lantern", "a saddle", "a map", "a kite", "a tent", "a compass"]
## Pairs to choose from in a systematic list: [first plural, second plural, what the choice makes].
const COMBOS: Array = [["hats", "scarves", "outfits of one hat and one scarf"],
	["kinds of bread", "fillings", "sandwiches of one bread and one filling"],
	["buddies", "colours of saddle", "ways to pick a buddy and a saddle colour"],
	["starters", "main courses", "meals of one starter and one main course"]]
## Problems and the strategy that suits them best, with a clue word the test knows them by.
const STRATEGIES: Array[String] = ["draw a model", "work backwards", "make a systematic list", "guess and check",
	"look for a pattern"]
const STRATEGY_PROBLEMS: Array = [
	["Zara has 3 times as many shells as Bram. Together they have 48. How many has Zara?", "draw a model", 1],
	["Oli spent half his gold, then earned 10 more. He has 30. How much did he start with?", "work backwards", 1],
	["How many ways can you pick one hat and one scarf from 3 hats and 4 scarves?", "make a systematic list", 1],
	["A farm has hens and cows: 10 heads and 28 legs. How many cows are there?", "guess and check", 1],
	["Towers have 2, 5, 8 and 11 blocks. How many blocks will the 20th tower have?", "look for a pattern", 1],
	["Mimi had some stickers. She gave away 12 and then half of the rest. She has 9 left. How many had she?",
		"work backwards", 2],
	["Two numbers add up to 20 and multiply to make 96. What are they?", "guess and check", 2],
	["How many different 3-digit numbers can you make with the cards 2, 5 and 7?", "make a systematic list", 2],
	["A rope is cut into two pieces. One is 4 times as long as the other, and the rope is 60 m. How long is each?",
		"draw a model", 2],
	["What is the sum 1 + 3 + 5 + 7 + … of the first 30 odd numbers?", "look for a pattern", 2],
	["Kit had 2/5 of his gold left after buying a tent. The tent cost 36 gold. How much had he at first?",
		"draw a model", 3],
	["A number is doubled, then 7 is taken away, and the answer is 31. What was the number?", "work backwards", 3],
	["In how many ways can you pay exactly 20 gold with 2-gold and 5-gold coins?", "make a systematic list", 3],
	["Tickets cost 3 gold for children and 5 gold for grown-ups. 12 tickets cost 44 gold. How many were for children?",
		"guess and check", 3],
	["Squares of tiles grow 1 × 1, 2 × 2, 3 × 3 … How many tiles does the 12th square need?", "look for a pattern", 3],
]

# --- Skeleton and muscles --------------------------------------------------------------------------------------------

## What each bone protects (level 1): [the part protected, the bone].
const PROTECTS: Array = [["your brain", "skull"], ["your heart and lungs", "ribs"], ["your spinal cord", "spine"]]
const BONE_WORDS := {"skull": "skull", "ribs": "ribs", "spine": "spine", "pelvis": "pelvis", "humerus": "humerus",
	"radius_ulna": "radius and ulna", "femur": "femur", "tibia_fibula": "tibia and fibula"}
## Facts about bones (level 3): [statement, true or false, the worked answer].
const BONE_FACTS: Array = [
	["An adult's skeleton has 206 bones.", true, "True: an adult has 206 bones."],
	["New blood cells are made in the marrow inside some bones.", true,
		"True: red and white blood cells are made in the bone marrow."],
	["The femur, in your thigh, is the longest bone in your body.", true, "True: the femur is the longest bone."],
	["Bones are not alive.", false, "False: bones are living tissue: they grow, and they mend when they break."],
	["A new baby has more separate bones than an adult.", true,
		"True: a baby has around 300 bones, and some of them join together as the baby grows."],
	["The smallest bone in your body is in your ear.", true, "True: the stirrup bone in your middle ear is the smallest."],
	["Calcium from milk and green leaves helps keep bones strong.", true, "True: bones need calcium, and vitamin D helps you take it in."],
	["Your skeleton only holds you up; it does nothing else.", false,
		"False: it supports you, protects your organs, lets you move and makes blood cells."],
]
## Muscle pairs: [the move, the muscle that contracts, the muscle that relaxes, the limb].
const MOVES: Array = [["bend your arm at the elbow", "biceps", "triceps", "arm"],
	["straighten your arm", "triceps", "biceps", "arm"],
	["bend your leg at the knee", "hamstrings", "quadriceps", "leg"],
	["straighten your leg", "quadriceps", "hamstrings", "leg"]]
const MUSCLE_FACTS: Array = [
	["Muscles can only pull; they cannot push.", true, "True: a muscle pulls by contracting (getting shorter)."],
	["Tendons join muscles to bones.", true, "True: tendons are tough cords that join muscles to bones."],
	["Ligaments join muscles to bones.", false, "False: ligaments join bone to bone at a joint; tendons join muscle to bone."],
	["Your quadriceps contract to straighten your leg.", true, "True: the quadriceps at the front of the thigh straighten the knee."],
	["When your biceps contracts, your triceps contracts too.", false,
		"False: they work as a pair: when one contracts, the other relaxes."],
	["Cartilage is a smooth layer on the ends of bones in a joint.", true,
		"True: smooth cartilage cushions the bones so they move easily."],
	["A muscle gets longer and fatter when it contracts.", false, "False: a contracting muscle gets shorter and fatter."],
]
## Joints: [the place, its kind].
const JOINT_PLACES: Array = [["your elbow", "hinge joint"], ["your knee", "hinge joint"],
	["the joints in your fingers", "hinge joint"], ["your shoulder", "ball and socket joint"],
	["your hip", "ball and socket joint"], ["the top of your neck", "pivot joint"],
	["the joins between the plates of your skull", "fixed joint"]]
const JOINT_KINDS: Array[String] = ["hinge joint", "ball and socket joint", "pivot joint", "fixed joint"]
const JOINT_TYPE := {"hinge joint": "hinge", "ball and socket joint": "ball_socket", "pivot joint": "pivot",
	"fixed joint": "fixed"}
const JOINT_MOVES := {"elbow": "moves one way", "knee": "moves one way", "finger": "moves one way",
	"shoulder": "moves every way", "hip": "moves every way", "skull": "does not move"}

# --- Nutrition and digestion -----------------------------------------------------------------------------------------

## Foods and the nutrient they are rich in (level 1): [foods, nutrient, wrong choices].
const FOOD_NUTRIENTS: Array = [
	["bread, rice and pasta", "carbohydrates", ["fats", "vitamin C", "water"]],
	["fish, eggs and chicken", "proteins", ["carbohydrates", "fibre", "vitamin C"]],
	["butter and olive oil", "fats", ["proteins", "fibre", "vitamin C"]],
	["oranges, kiwis and peppers", "vitamin C", ["fats", "proteins", "calcium"]],
	["milk, yoghurt and cheese", "calcium", ["vitamin C", "fibre", "carbohydrates"]],
	["wholegrain bread, beans and vegetables", "fibre", ["fats", "vitamin D", "salt"]],
	["potatoes and oats", "carbohydrates", ["fats", "calcium", "vitamin D"]],
	["lentils, beans and tofu", "proteins", ["fats", "vitamin D", "salt"]],
]
## Nutrients by their job (level 2) and by the illness their lack causes (level 3): [clue, nutrient, wrongs].
const NUTRIENT_JOBS: Array = [
	["gives your body most of its energy", "carbohydrates", ["fibre", "calcium", "vitamin C"]],
	["helps your body grow and repair itself", "proteins", ["fats", "fibre", "water"]],
	["stores energy and keeps you warm", "fats", ["fibre", "vitamin C", "calcium"]],
	["keeps food moving through your gut", "fibre", ["fats", "iron", "vitamin D"]],
	["builds strong bones and teeth", "calcium", ["vitamin C", "fibre", "fats"]],
	["helps make red blood cells, which carry oxygen", "iron", ["calcium", "fibre", "fats"]],
	["keeps your gums and skin healthy and helps cuts heal", "vitamin C", ["iron", "fats", "fibre"]],
	["helps you take in calcium; your skin makes it in sunlight", "vitamin D", ["iron", "fibre", "vitamin C"]],
	["makes up most of your body, and every cell needs it", "water", ["fats", "fibre", "iron"]],
]
const DEFICIENCIES: Array = [
	["scurvy (bleeding gums, slow healing)", "vitamin C", ["iron", "calcium", "fibre"]],
	["rickets (soft, bent bones in children)", "vitamin D", ["vitamin C", "iron", "fibre"]],
	["anaemia (tired and pale: too few red blood cells)", "iron", ["vitamin C", "calcium", "fibre"]],
	["constipation (food moving too slowly through the gut)", "fibre", ["iron", "vitamin D", "calcium"]],
]
## Foods to sort (level 3): [food, "carbohydrates" | "proteins" | "fats"].
const SORT_FOODS: Array = [["bread", "carbohydrates"], ["rice", "carbohydrates"], ["pasta", "carbohydrates"],
	["potatoes", "carbohydrates"], ["fish", "proteins"], ["eggs", "proteins"], ["chicken", "proteins"],
	["lentils", "proteins"], ["butter", "fats"], ["olive oil", "fats"], ["lard", "fats"]]
const TESTS: Array[String] = ["starch", "sugar", "protein", "fat"]
const TEST_WORDS := {"starch": "iodine", "sugar": "Benedict's solution (heated)", "protein": "biuret", "fat": "paper"}
const TEST_HOW := {"starch": "tested with iodine", "sugar": "heated with Benedict's solution",
	"protein": "tested with biuret", "fat": "rubbed on paper"}
## Where digestion happens (level 3): [question, the right place, wrongs].
const GUT_PLACES: Array = [
	["Where does amylase in your saliva start breaking starch down?", "the mouth", ["the stomach", "the large intestine",
		"the gullet"]],
	["Where do protease and strong acid start breaking protein down?", "the stomach", ["the mouth", "the large intestine",
		"the gullet"]],
	["Where do the small pieces of digested food pass into the blood?", "the small intestine", ["the stomach", "the mouth",
		"the gullet"]],
	["Where is water taken back out of what is left?", "the large intestine", ["the mouth", "the stomach", "the gullet"]],
	["Which organ makes bile, which breaks fat into tiny drops?", "the liver", ["the heart", "the lungs", "the mouth"]],
	["Which tube squeezes food down from the mouth to the stomach?", "the gullet", ["the small intestine", "the windpipe",
		"the large intestine"]],
]

# --- Classifying life ------------------------------------------------------------------------------------------------

const GROUPS: Array[String] = ["fish", "amphibian", "reptile", "bird", "mammal"]
## The game's animals and their groups (level 1).
const ANIMAL_GROUPS := {"fish": "fish", "frog": "amphibian", "lizard": "reptile", "turtle": "reptile",
	"parrot": "bird", "owl": "bird", "penguin": "bird", "duck": "bird", "chicken": "bird", "dog": "mammal",
	"cat": "mammal", "cow": "mammal", "horse": "mammal", "seal": "mammal", "rabbit": "mammal", "fox": "mammal",
	"hedgehog": "mammal", "camel": "mammal", "polar_bear": "mammal", "deer": "mammal"}
## The groups by their features (level 2).
const GROUP_FEATURES: Array = [
	["It breathes with gills, has fins and scales, and lives in water all its life.", "fish"],
	["It has moist skin; its young live in water and breathe with gills, and the adults have lungs.", "amphibian"],
	["It has dry, scaly skin and lays eggs with leathery shells on land.", "reptile"],
	["It has feathers and a beak, and lays eggs with hard shells.", "bird"],
	["It has fur or hair and feeds its young on milk.", "mammal"],
]
## Animals people often sort wrongly (level 3): [animal, group, why].
const TRICKY: Array = [
	["a whale", "mammal", "It breathes air with lungs and feeds its young on milk."],
	["a bat", "mammal", "It has fur and feeds its young on milk; flying does not make it a bird."],
	["a penguin", "bird", "It has feathers and lays eggs with hard shells, though it cannot fly."],
	["a shark", "fish", "It breathes with gills and has fins."],
	["a salamander", "amphibian", "It has moist skin and its young grow up in water."],
	["a crocodile", "reptile", "It has dry, scaly skin and lays eggs on land."],
	["a dolphin", "mammal", "It breathes air with lungs and feeds its young on milk."],
	["a newt", "amphibian", "It has moist skin and lays its eggs in water."],
	["a snake", "reptile", "It has dry scales and no legs, but it is still a reptile."],
	["a seahorse", "fish", "It breathes with gills and has fins."],
	["an ostrich", "bird", "It has feathers and lays eggs, though it cannot fly."],
	["a platypus", "mammal", "It lays eggs, but it has fur and feeds its young on milk."],
]
const INVERT_GROUPS: Array[String] = ["insects", "arachnids", "crustaceans", "molluscs", "annelid worms", "myriapods"]
const INVERT_ANIMALS: Array = [["an ant", "insects"], ["a ladybird", "insects"], ["a butterfly", "insects"],
	["a bee", "insects"], ["a spider", "arachnids"], ["a scorpion", "arachnids"], ["a crab", "crustaceans"],
	["a woodlouse", "crustaceans"], ["a lobster", "crustaceans"], ["a snail", "molluscs"], ["an octopus", "molluscs"],
	["a slug", "molluscs"], ["an earthworm", "annelid worms"], ["a leech", "annelid worms"], ["a centipede", "myriapods"],
	["a millipede", "myriapods"]]
const INVERT_FEATURES: Array = [
	["six legs, three body parts and often wings", "insects"], ["eight legs and two body parts", "arachnids"],
	["a hard outer shell and many jointed legs; most live in water", "crustaceans"],
	["a soft body that often has a shell", "molluscs"], ["a soft body in rings, with no legs", "annelid worms"],
	["a long body in many segments, with lots of legs", "myriapods"]]
## Chain keys: questions [question, yes words, no words] and their ends (the last end: every answer no).
const KEYS: Array = [
	[[["Does it have feathers?", "it has feathers", "it has no feathers"],
		["Does it have fur?", "it has fur", "it has no fur"]], ["robin", "fox", "trout"]],
	[[["Does it have a shell?", "it has a shell", "it has no shell"],
		["Does it have legs?", "it has legs", "it has no legs"]], ["snail", "centipede", "earthworm"]],
	[[["Does it have flowers?", "it has flowers", "it has no flowers"],
		["Does it make cones?", "it makes cones", "it makes no cones"]], ["daisy", "pine tree", "fern"]],
	[[["Does it have feathers?", "it has feathers", "it has no feathers"],
		["Does it have fur?", "it has fur", "it has no fur"],
		["Does it have fins?", "it has fins", "it has no fins"]], ["robin", "fox", "trout", "frog"]],
	[[["Does it have wings?", "it has wings", "it has no wings"],
		["Does it have 8 legs?", "it has 8 legs", "it does not have 8 legs"],
		["Does it have a shell?", "it has a shell", "it has no shell"]], ["butterfly", "spider", "snail", "slug"]],
	[[["Does it have flowers?", "it has flowers", "it has no flowers"],
		["Does it make cones?", "it makes cones", "it makes no cones"],
		["Does it have fronds?", "it has fronds", "it has no fronds"]], ["daisy", "pine tree", "fern", "moss"]],
	[[["Does it have feathers?", "it has feathers", "it has no feathers"],
		["Does it have fur?", "it has fur", "it has no fur"],
		["Does it have fins?", "it has fins", "it has no fins"],
		["Does it have dry scales?", "it has dry scales", "it has no dry scales"]],
		["robin", "fox", "trout", "lizard", "frog"]],
	[[["Does it have wings?", "it has wings", "it has no wings"],
		["Does it have 8 legs?", "it has 8 legs", "it does not have 8 legs"],
		["Does it have a shell?", "it has a shell", "it has no shell"],
		["Does it have legs?", "it has legs", "it has no legs"]], ["butterfly", "spider", "snail", "centipede", "slug"]],
]
const KINGDOM_NAMES: Array[String] = ["animals", "plants", "fungi", "protists", "bacteria"]
const KINGDOM_OF: Array = [["an eagle", "animals", 1], ["a snail", "animals", 1], ["an oak tree", "plants", 1],
	["grass", "plants", 1], ["a mushroom", "fungi", 1], ["mould on old bread", "fungi", 1],
	["the bacteria that turn milk into yoghurt", "bacteria", 1], ["an amoeba", "protists", 1],
	["moss", "plants", 3], ["yeast, which makes bread rise", "fungi", 3], ["a sponge on the sea bed", "animals", 3],
	["coral", "animals", 3], ["a toadstool", "fungi", 3], ["a fern", "plants", 3]]
const KINGDOM_FEATURES: Array = [
	["It has many cells and cannot make its own food, so it eats other living things.", "animals"],
	["It makes its own food from sunlight, water and air.", "plants"],
	["It cannot make its own food; it feeds on dead things and grows from spores.", "fungi"],
	["It is a single cell with a nucleus, like an amoeba.", "protists"],
	["It is a single cell with no nucleus.", "bacteria"]]
const LEVEL_NAMES: Array[String] = ["kingdom", "phylum", "class", "order", "family", "genus", "species"]
const WOLF: Array[String] = ["animals", "chordates", "mammals", "carnivores", "dog family", "Canis", "Canis lupus"]

# --- Light -----------------------------------------------------------------------------------------------------------

## Shadows (level 1): [what changes, bigger or smaller].
const SHADOW_MOVES: Array = [["moves the card closer to the lamp", "It gets bigger."],
	["moves the card closer to the screen", "It gets smaller."],
	["moves the lamp farther from the card", "It gets smaller."],
	["moves the screen farther from the card", "It gets bigger."],
	["moves the lamp closer to the card", "It gets bigger."]]
const SOURCES: Array = [["the Sun", true], ["a candle flame", true], ["a lamp that is switched on", true],
	["a campfire", true], ["a lit torch", true], ["the Moon", false], ["a mirror", false], ["a white page", false],
	["a bicycle reflector", false], ["a cat's eye shining in torchlight", false], ["a shiny spoon", false]]
const MATERIALS: Array = [["clear glass", "transparent"], ["clean water", "transparent"], ["cling film", "transparent"],
	["tracing paper", "translucent"], ["frosted glass", "translucent"], ["tissue paper", "translucent"],
	["wood", "opaque"], ["cardboard", "opaque"], ["a brick", "opaque"], ["a metal tray", "opaque"]]
const SEEING: Array = [
	["You see a book by a lamp.", ["The lamp gives out light", "Light travels to the book in straight lines",
		"Light reflects off the book", "The reflected light enters your eye", "Your eye sends a message to your brain"]],
	["You see a tree on a sunny day.", ["The Sun gives out light", "Sunlight travels to the tree",
		"Light reflects off the tree", "The reflected light enters your eye", "Your eye sends a message to your brain"]],
	["You see the Moon at night.", ["The Sun gives out light", "Sunlight travels to the Moon",
		"Light reflects off the Moon", "The reflected light enters your eye", "Your eye sends a message to your brain"]],
]

# --- Energy changes --------------------------------------------------------------------------------------------------

## Devices: [device, what goes in, the useful energy out].
const DEVICES: Array = [["an electric kettle", "electrical", "heat"], ["a loudspeaker", "electrical", "sound"],
	["an electric fan", "electrical", "kinetic"], ["a lamp", "electrical", "light"],
	["a solar panel", "light", "electrical"], ["a wind turbine", "kinetic", "electrical"],
	["a microphone", "sound", "electrical"], ["a battery", "chemical", "electrical"],
	["a wind-up toy", "elastic", "kinetic"], ["a campfire", "chemical", "heat"]]
## Chains of three or more steps (level 3): [what it is, the steps].
const CHAINS: Array = [["water falling through a dam to make electricity", ["gravitational", "kinetic", "electrical"]],
	["a torch", ["chemical", "electrical", "light"]], ["a toy car with a battery", ["chemical", "electrical", "kinetic"]],
	["a bike lamp powered by pedalling", ["chemical", "kinetic", "electrical", "light"]],
	["a ball dropped from a height", ["gravitational", "kinetic", "heat"]],
	["a phone charged by a solar panel", ["light", "electrical", "chemical"]],
	["a wind turbine lighting a lamp", ["kinetic", "electrical", "light"]],
	["a bow shooting an arrow", ["chemical", "elastic", "kinetic"]]]
## Machines for energy flows: [device, useful energy, the useful share range in %, what is wasted].
const WASTERS: Array = [["a filament bulb", "light", [5, 10], ["heat"]],
	["an electric kettle", "hot water", [80, 90], ["warm air", "sound"]],
	["an electric motor", "movement", [60, 80], ["heat", "sound"]], ["a car engine", "movement", [20, 30], ["heat", "sound"]]]
const SAVERS: Array = [
	["Which lamp wastes less energy?", "an LED lamp", ["an old filament bulb"], 1],
	["Which way to boil water for one cup wastes less?", "boil just one cupful", ["fill the whole kettle"], 1],
	["Which way wastes less energy when you leave a room?", "switch the light off", ["leave the light on"], 1],
	["Which pan of soup heats up with less wasted heat?", "a pan with a lid on", ["a pan with no lid"], 2],
	["Which home loses less heat in winter?", "one with thick loft insulation", ["one with no loft insulation",
		"one with the windows open"], 2],
	["Which way to dry clothes uses no electricity?", "hang them on a line", ["use a tumble dryer"], 2],
	["Which wastes less energy overnight?", "turning the TV off at the switch", ["leaving the TV on standby"], 3],
	["Which room keeps its heat better at night?", "curtains closed", ["curtains open"], 3],
	["Which way of getting to a friend's house nearby uses no fuel?", "walking or cycling", ["a car ride"], 3],
]

# --- Engineering design ----------------------------------------------------------------------------------------------

## Statements about a design: [statement, "criterion" | "constraint"].
const DESIGN_STATEMENTS: Array = [
	["The egg must not crack when it lands.", "criterion"], ["Use at most 10 straws.", "constraint"],
	["It must hold at least 20 coins.", "criterion"], ["It must cost no more than 5 gold.", "constraint"],
	["The boat must float for 5 minutes.", "criterion"], ["Build it in 30 minutes or less.", "constraint"],
	["The filter must make the water clear.", "criterion"], ["It must fit inside a shoebox.", "constraint"],
	["The tower must stand up in a breeze.", "criterion"], ["Use only paper and tape.", "constraint"],
	["The bridge must reach across a 30 cm gap.", "criterion"], ["It must be safe: no sharp edges.", "constraint"],
]
const DESIGN_TASKS: Array = [["bridge", "coins held", "hold at least %d coins"], ["tower", "height cm",
	"be at least %d cm tall"], ["boat", "minutes", "float for at least %d minutes"]]

# --- English -------------------------------------------------------------------------------------------------------

## Stated or inferred: [text, statement, "stated" | "inferred", level].
const INFER: Array = [
	["Kit's boots were caked in mud and his coat dripped onto the floor.", "Kit's boots were caked in mud.", "stated", 1],
	["Kit's boots were caked in mud and his coat dripped onto the floor.", "It had been raining outside.", "inferred", 1],
	["The bakery opens at seven. By five past, the queue reached the corner.", "The bakery opens at seven.", "stated", 1],
	["The bakery opens at seven. By five past, the queue reached the corner.", "The bakery is popular.", "inferred", 1],
	["Mimi read the letter twice, then hugged it and danced round the kitchen.", "Mimi read the letter twice.", "stated", 2],
	["Mimi read the letter twice, then hugged it and danced round the kitchen.", "The letter had good news.", "inferred", 2],
	["Honeybees beat their wings about 200 times a second, which makes their buzz.",
		"Bees beat their wings about 200 times a second.", "stated", 2],
	["The old lighthouse's lamp was dark, and ivy grew over its door.", "The lighthouse has not been used for a long time.",
		"inferred", 2],
	["Arctic terns fly from the Arctic to the Antarctic and back each year.", "Arctic terns travel very long distances.",
		"inferred", 3],
	["Oli checked the map again, frowned, and turned the paper the other way up.", "Oli was not sure which way to go.",
		"inferred", 3],
	["Oli checked the map again, frowned, and turned the paper the other way up.", "Oli checked the map again.", "stated", 3],
	["Zara's hands shook as she stepped onto the stage and looked at the crowd.", "Zara felt nervous.", "inferred", 3],
]
## The best evidence: [sentences, the inference, the index of the sentence that proves it, level].
const EVIDENCE: Array = [
	[["A robin sang on the wall.", "Brambles covered the path.", "The sky was blue."],
		"nobody had looked after the garden for a long time", 1, 1],
	[["Dot read a book by the window.", "Icicles hung from the roof.", "She liked the colour red."],
		"it was freezing outside", 1, 1],
	[["The crowd went silent.", "Tam's hands shook on the violin.", "The hall had red seats."],
		"Tam was nervous", 1, 1],
	[["Bees visit about a thousand flowers a day.", "Some flowers are purple.", "Honey is sweet."],
		"bees are very busy", 0, 2],
	[["The river was brown and fast.", "Kit's wellies sank into deep mud.", "A duck sat on the bank."],
		"the ground by the river was soft and wet", 1, 2],
	[["Juno had read every book in the library twice.", "The library had a green door.", "It opened at nine."],
		"Juno loves reading", 0, 2],
	[["The tree's rings showed 120 years of growth.", "Its leaves were bright green.", "Birds nested in it."],
		"the tree is very old", 0, 3],
	[["Oli smiled and slid the sprouts away.", "The table was set for six.", "It was Sunday."],
		"Oli did not want the sprouts", 0, 3],
	[["The clock struck ten.", "Dot yawned and rubbed her eyes.", "The fire crackled."], "Dot was tired", 1, 3],
]
## Story or information text: [sentence, "story" | "information", topic].
const TEXT_KINDS: Array = [
	["\"Quick, the lava is coming!\" shouted Kit.", "story"], ["A volcano is an opening in the Earth's crust.", "information"],
	["Mimi crept towards the hive, heart thumping.", "story"], ["A hive can hold tens of thousands of bees.", "information"],
	["The Moon glowed like a coin as Zara wished.", "story"], ["The Moon reflects light from the Sun.", "information"],
	["Owls hunt mostly at night.", "information"], ["\"Follow me,\" said Old Owl with a blink.", "story"],
	["Rivers flow from their source to the sea.", "information"], ["The river whispered secrets to Oli all night.", "story"],
]
## An argument's parts (topic: a school garden): [sentence, part].
const ARG_PARTS: Array = [
	["Our school should have a garden.", "claim"], ["Every town should have a free library.", "claim"],
	["A garden would teach us how food grows.", "reason"], ["A library gives everyone the chance to read.", "reason"],
	["Pupils in one garden club grew 40 kg of vegetables in a year.", "evidence"],
	["The town's library lent 12,000 books last year.", "evidence"],
	["Some people say a garden would take too much time.", "counterclaim"],
	["Some argue that everyone can read online now.", "counterclaim"],
	["However, a garden club could share the work.", "rebuttal"],
	["However, not every home has a computer.", "rebuttal"],
]
const ARG_NAMES: Array[String] = ["claim", "reason", "evidence", "counterclaim", "rebuttal"]
## Linking words for an argument: [sentence with ___, right, wrongs].
const ARG_LINKS: Array = [
	["Some say homework is boring. ___, it helps us remember what we learn.", "However", ["For example", "Firstly",
		"Therefore"]],
	["Cycling is good exercise. ___, it causes no pollution.", "Furthermore", ["However", "For example", "In conclusion"]],
	["Trees help wildlife. ___, one oak tree can be home to hundreds of kinds of insects.", "For example", ["However",
		"In conclusion", "Although"]],
	["Litter harms animals and costs money to clear. ___, we need more bins.", "Therefore", ["For example", "However",
		"Firstly"]],
	["___, for all these reasons, our town needs a skate park.", "In conclusion", ["For example", "However", "Firstly"]],
	["I believe we need a garden. ___, it would teach us about science.", "Firstly", ["However", "Although",
		"On the other hand"]],
	["Buses can be slow. ___, they carry many people at once, which saves fuel.", "On the other hand", ["For example",
		"Firstly", "In conclusion"]],
	["Libraries are free to join. ___, anyone can borrow books.", "As a result", ["However", "For example",
		"Although"]],
]
## Formal and informal sentences, in sets: [formal, informal, informal, informal].
const FORMAL_SETS: Array = [
	["I believe the park needs more bins.", "The park's totally rubbish, yeah?", "Loads of bins, please!",
		"Bins. We need 'em."],
	["Pupils would benefit from a longer lunch.", "Lunch is way too short, innit?", "Gimme more lunch!",
		"Lunch break is a joke."],
	["Evidence shows that walking is healthy.", "Walking's well good for you.", "Honestly, just walk, it's fine.",
		"Walking rocks!"],
	["Everyone should recycle their plastic.", "Recycle your stuff, OK?", "Recycling is super cool!", "C'mon, recycle!"],
	["Furthermore, a garden would attract bees.", "Plus bees and stuff would come.", "And bees! Loads of bees!",
		"Bees love it, obviously."],
]
## Precise words: [sentence, the precise word, wrongs, level].
const PRECISE: Array = [
	["When a volcano DOES A BIG BANG, hot lava pours out.", "erupts", ["goes", "happens", "gets"], 1],
	["The Sun heats the puddle and the water GOES UP into the air.", "evaporates", ["goes away", "moves", "leaves"], 1],
	["A caterpillar makes a HARD CASE and changes inside it.", "chrysalis", ["house", "bag", "box"], 1],
	["The heart PUSHES blood round the body.", "pumps", ["moves", "gets", "does"], 2],
	["Plants make their own food using sunlight. This is called FOOD-MAKING.", "photosynthesis", ["digestion",
		"evaporation", "erosion"], 2],
	["The ice TURNED INTO WATER in the warm room.", "melted", ["went", "changed about", "got"], 2],
	["Bats find food by sending out sounds and hearing the echoes: SOUND-FINDING.", "echolocation", ["hearing", "noise",
		"shouting"], 3],
	["The river WEARS AWAY its banks, bit by bit.", "erodes", ["breaks", "does", "gets"], 3],
	["Animals that eat only plants are called PLANT-EATERS.", "herbivores", ["carnivores", "predators", "omnivores"], 3],
]
const FEATURES: Array = [
	["tells the reader what one section is about", "a subheading"], ["explains special words at the end", "a glossary"],
	["says what a picture or diagram shows", "a caption"], ["lists topics and the pages they are on", "an index"],
	["opens the text and says what it will explain", "an introduction"], ["sums up the main ideas at the end", "a conclusion"],
	["shows how something works in a labelled drawing", "a diagram"], ["tells you the meaning of a word in the text",
		"a definition"], ["shows a list of short points, each on its own line", "bullet points"]]
const FEATURE_NAMES: Array[String] = ["a subheading", "a glossary", "a caption", "an index", "an introduction",
	"a conclusion", "a diagram", "a definition", "bullet points"]
## Openings: [the best hook, three flat openings, level].
const HOOKS: Array = [
	["\"Don't open that door!\" Bram shouted. Too late.", ["This is a story about a door.",
		"Once there was a boy called Bram.", "Bram lived in a house with doors."], 1],
	["Nobody knew why the river had turned purple.", ["There was a river in the town.",
		"This story is about a river.", "The river was near the town."], 1],
	["Zara had exactly one minute to find the key.", ["Zara was a girl who liked keys.",
		"One day Zara looked for things.", "Zara lived near the sea."], 2],
	["What if your shadow walked away without you?", ["I am going to tell you a story.",
		"My story is about a shadow.", "There was a shadow once."], 2],
	["The map was wrong. The path ended at a cliff.", ["Juno went for a walk with a map.",
		"Juno had a map. It was a nice day.", "This is Juno's story."], 3],
	["For fifty years the door stayed shut. Until now.", ["There was a lighthouse by the sea.",
		"Lighthouses help ships at sea.", "The lighthouse was tall and white."], 3],
]
## Pace: [question, right, wrongs, level].
const PACE: Array = [
	["Which version builds the most tension?", "The ice cracked. Tam froze. Another crack.",
		["The ice was cracking a little, so Tam stopped.", "Tam walked slowly over the ice, which cracked."], 1],
	["Which version builds the most tension?", "Footsteps. Closer. The handle turned.",
		["Someone walked up and turned the handle.", "Mimi heard steps coming towards her door."], 2],
	["Which version slows the moment down, to make it feel calm?", "The boat drifted as the sun sank, slow and gold.",
		["Boat. Lake. Sunset. Done.", "The boat stopped. Sun down."], 2],
	["Which version keeps the reader on edge?", "Nothing moved. Then the lights went out.",
		["The lights went out and Kit went to bed.", "Kit read until the lights went out, then slept."], 3],
]
## Vivid verbs: [sentence with a plain verb in capitals, the vivid verb, wrongs, level].
const VIVID: Array = [
	["The mouse WENT across the kitchen floor.", "scurried", ["was", "did", "got"], 1],
	["\"Watch out!\" SAID Oli, as the rock fell.", "yelled", ["told", "did", "talked"], 1],
	["The hungry horse ATE the apple.", "gobbled", ["had", "got", "did"], 1],
	["The rain CAME DOWN on the tin roof.", "hammered", ["went", "was", "got"], 2],
	["Mimi LOOKED at the strange footprints.", "stared", ["saw", "got", "went"], 2],
	["The kite WENT up into the clouds.", "soared", ["got", "was", "did"], 2],
	["The old door MADE A NOISE as it opened.", "creaked", ["did", "went", "got"], 3],
	["The fox MOVED quietly towards the hens.", "crept", ["got", "went", "did"], 3],
	["Juno's heart BEAT as she opened the box.", "pounded", ["went", "did", "got"], 3],
]
## Paraphrases: [original, good paraphrase, wrongs, level].
const PARAPHRASES: Array = [
	["Hedgehogs sleep all winter and wake in spring.", "After a winter asleep, hedgehogs wake in spring.",
		["Hedgehogs sleep all winter and wake in spring.", "Hedgehogs stay awake all winter long.",
		"Hedgehogs are the cutest animals ever."], 1],
	["Bees move pollen, helping plants make seeds.", "By moving pollen, bees help plants form seeds.",
		["Bees move pollen, helping plants make seeds.", "Plants move pollen to help bees make seeds.",
		"I think bees are the best insects."], 2],
	["Roman roads let armies march quickly.", "Soldiers could travel fast on Roman roads.",
		["Roman roads let armies march quickly.", "The Romans built roads for cars.",
		"Roman roads were the best roads ever."], 2],
	["Octopuses have three hearts and blue blood.", "Each octopus pumps blue blood with three hearts.",
		["Octopuses have three hearts and blue blood.", "Octopuses have one heart and red blood.",
		"Octopuses are strange and scary."], 3],
	["Thunder is the sound of air heated by lightning.", "When lightning heats the air, we hear thunder.",
		["Thunder is the sound of air heated by lightning.", "Thunder makes lightning heat the air.",
		"Thunderstorms are the scariest weather."], 3],
]
## Trustworthy sources: [question, the best source, wrongs, level].
const TRUST: Array = [
	["You want facts about sharks for a report.", "a book by a marine scientist", ["a comment under a video",
		"an advert for a shark film", "a friend's guess"], 1],
	["You want to know when a castle was built.", "the castle's museum website", ["a story set in a castle",
		"a post by someone you don't know", "a cartoon about knights"], 1],
	["You want today's weather for your town.", "the national weather service", ["last year's calendar",
		"a book about clouds", "a poem about rain"], 2],
	["You want to know how many bones are in a hand.", "a science encyclopedia", ["a funny video",
		"an advert for gloves", "a guess in a chat"], 2],
	["Two websites give different heights for a mountain. What should you do?",
		"check a third trusted source", ["pick the bigger number", "use the first one you found",
		"make up your own number"], 3],
	["A website about healthy food is written by a sweet company. What should you ask?",
		"is it trying to sell something?", ["are the pictures nice?", "is the website colourful?",
		"is it long?"], 3],
]
const AUTHORS: Array[String] = ["Patel", "Okafor", "Nguyen", "Smith", "Garcia", "Ahmed", "Brown", "Kowalski", "Evans",
	"Oduya", "Silva", "Novak", "Park", "Haddad", "Morris", "Morgan", "Moreau", "Mills", "Singh", "Sato"]
const TITLES: Array[String] = ["Owls at Night", "The Water Cycle", "Life in a Hive", "Volcanoes", "Rivers of the World",
	"The Human Skeleton", "Light and Shadow", "Forces for Beginners", "Castles", "Bees and Flowers", "The Moon",
	"Rainforests"]
## Building on others' ideas: [what they said, the reply that builds on it, wrongs, level].
const BUILD_ON: Array = [
	["Tilly: \"We could plant flowers by the school gate.\"", "Yes, and we could pick ones that bees like.",
		["I had toast for breakfast.", "We should do something else.", "What about football?"], 1],
	["Bram: \"A bike rack would help more pupils cycle.\"", "Good point, and a shelter would keep bikes dry.",
		["No.", "I like my scooter.", "Can we talk about lunch?"], 1],
	["Zara: \"Our library needs more books about space.\"", "And we could ask which topics pupils want.",
		["Space is not my thing.", "Let's go outside.", "Books are heavy."], 2],
	["Oli: \"We should turn the lights off when we leave.\"", "That links to Mimi's point about saving money.",
		["Lights are bright.", "Maybe.", "I'm hungry."], 2],
	["Juno: \"Walking to school is healthy.\"", "Building on that: it also means less traffic.",
		["I think we should talk about films.", "Cars are faster anyway.", "What's on TV tonight?"], 3],
	["Kit: \"A quiet room at lunch would help people read.\"", "Could we ask how many pupils would use it?",
		["Let's talk about sport instead.", "What time is lunch?", "I want chips."], 3],
]
## Charts: [the data, the chart that shows it best].
const CHARTS: Array = [["how the temperature changed through one day", "a line graph"],
	["how many pupils chose each fruit", "a bar chart"],
	["what fraction of the class walks, cycles or comes by bus", "a pie chart"],
	["how tall a sunflower grew each week", "a line graph"],
	["how many books each class read", "a bar chart"],
	["what share of a day you spend sleeping, at school and at home", "a pie chart"],
	["the number of visitors to a park each month of the year", "a line graph"],
	["the heights of the tallest mountains on each continent", "a bar chart"],
	["how a pocket of gold was split between saving and spending", "a pie chart"]]
const CHART_NAMES: Array[String] = ["a line graph", "a bar chart", "a pie chart"]


# --- Helpers ---------------------------------------------------------------------------------------------------------

static func _pick(rng: RandomNumberGenerator, a: Array) -> Variant:
	return a[rng.randi_range(0, a.size() - 1)]


static func _name(rng: RandomNumberGenerator) -> String:
	return NAMES[rng.randi_range(0, NAMES.size() - 1)]


static func _two_names(rng: RandomNumberGenerator) -> Array[String]:
	var a := _name(rng)
	var b := _name(rng)
	while b == a:
		b = _name(rng)
	return [a, b]


static func _cap(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1)


## `n` entries of `pool` at `level` (or every level when none is at it), shuffled.
static func _at_level(pool: Array, level: int, col: int) -> Array:
	var out := pool.filter(func(e: Array) -> bool: return int(e[col]) == level)
	return out if not out.is_empty() else pool.duplicate()


## A sort exercise: `pairs` [item, group] shuffled; every group used.
static func _sort(rng: RandomNumberGenerator, prompt: String, groups: Array, pairs: Array, hint: String,
		explain: String = "") -> Dictionary:
	var ps := pairs.duplicate()
	K.shuffle(rng, ps)
	var items: Array = []
	var answer: Array = []
	var by_group := {}
	for pr: Array in ps:
		items.append(pr[0])
		answer.append(groups.find(pr[1]))
		if not by_group.has(pr[1]):
			by_group[pr[1]] = []
		(by_group[pr[1]] as Array).append(str(pr[0]))
	var parts: Array[String] = []
	for g: Variant in groups:
		if by_group.has(g):
			parts.append("%s: %s" % [_cap(str(g)), ", ".join(PackedStringArray(by_group[g]))])
	return {"type": "sort", "prompt": prompt, "groups": groups, "items": items, "answer": answer, "hint": hint,
		"explain": explain if explain != "" else ". ".join(parts) + "."}


## `count` pairs from `pool` [item, group] with every group of `groups` at least once (as far as the pool allows).
static func _spread(rng: RandomNumberGenerator, pool: Array, groups: Array, count: int) -> Array:
	var ps := pool.duplicate()
	K.shuffle(rng, ps)
	var out: Array = []
	for g: Variant in groups:
		for pr: Array in ps:
			if pr[1] == g and not out.has(pr):
				out.append(pr)
				break
	for pr: Array in ps:
		if out.size() >= count:
			break
		if not out.has(pr):
			out.append(pr)
	return out.slice(0, count)


## "contracts" for one muscle, "contract" for the hamstrings (a group).
static func _verb(muscle: String, verb: String) -> String:
	return verb if muscle == "hamstrings" else verb + ("es" if verb.ends_with("x") else "s")


## "a lizard", "an owl".
static func _a(word: String) -> String:
	return ("an " if "aeiou".contains(word.substr(0, 1)) else "a ") + word


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := b
		b = a % b
		a = t
	return a


# --- The problem-solving toolkit -------------------------------------------------------------------------------------

## Work backwards: a function machine's start from its end (levels 1-2, with the machine drawn) or a story of gold
## spent and earned (level 3).
static func work_back(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var start: int
	var ops: Array[String] = []
	var v: int
	if level == 1:
		start = rng.randi_range(3, 30)
		v = start
		for i in 2:
			var a := rng.randi_range(2, 15)
			if rng.randf() < 0.5 or v - a < 1:
				ops.append("+ %d" % a)
				v += a
			else:
				ops.append("− %d" % a)
				v -= a
	elif level == 2:
		start = rng.randi_range(2, 20)
		v = start
		var kinds := ["×", "+", "÷"]
		K.shuffle(rng, kinds)
		for kind: String in kinds:
			match kind:
				"×":
					var m := rng.randi_range(2, 5)
					ops.append("× %d" % m)
					v *= m
				"+":
					var a := rng.randi_range(1, 20)
					ops.append("+ %d" % a)
					v += a
				"÷":
					var divs: Array[int] = []
					for dv in range(2, 7):
						if v % dv == 0:
							divs.append(dv)
					if divs.is_empty():
						var a := rng.randi_range(1, mini(v - 1, 12)) if v > 2 else 0
						if a > 0:
							ops.append("− %d" % a)
							v -= a
						else:
							ops.append("× 2")
							v *= 2
					else:
						var dv: int = divs[rng.randi_range(0, divs.size() - 1)]
						ops.append("÷ %d" % dv)
						v /= dv
	else:
		var who := _name(rng)
		start = rng.randi_range(8, 30) * 2
		v = start
		var story: Array[String] = []
		var steps := BACK_STEPS.duplicate()
		K.shuffle(rng, steps)
		var used := 0
		for st: Array in steps:
			if used == 3:
				break
			var words: String = st[0]
			var op: String = st[1]
			var n := rng.randi_range(3, 15)
			if op == "÷ 2":
				if v % 2 != 0 or used > 0 and v < 8:
					continue
				v /= 2
			elif op == "× 2":
				if v > 60:
					continue
				v *= 2
			elif op.begins_with("−"):
				if v - n < 2:
					continue
				v -= n
				op = op % n
				words = words % n
			else:
				v += n
				op = op % n
				words = words % n
			ops.append(op)
			story.append(words)
			used += 1
		while used < 3:
			var n := rng.randi_range(3, 15)
			ops.append("+ %d" % n)
			story.append("found %d more" % n)
			v += n
			used += 1
		var prompt := "%s had some gold. %s %s, then %s, then %s. Now %s has %d gold. How much did %s have at the start?" % [
			who, who, story[0], story[1], story[2], who, v, who]
		var ex := K.number(prompt, str(start), "Work backwards from the end: undo each step, the last step first.",
			_undo_words(ops, v, start), {"kind": "op_chain", "start": "?", "ops": ops, "end": str(v), "back": true})
		ex.data = {"ops": ops, "end": v, "start": start}
		return ex
	var ex := K.number("What number went into the machine?", str(start),
		"Work backwards from the end: undo each step, the last step first. + and − undo each other; so do × and ÷.",
		_undo_words(ops, v, start), {"kind": "op_chain", "start": "?", "ops": ops, "end": str(v)})
	ex.data = {"ops": ops, "end": v, "start": start}
	return ex


## "Undo − 3: 21 + 3 = 24. …" for `ops` from `end` back to `start`.
static func _undo_words(ops: Array[String], end: int, start: int) -> String:
	var parts: Array[String] = []
	var v := float(end)
	for i in range(ops.size() - 1, -1, -1):
		var back := SchoolPictureG6Core.inverse_op(ops[i])
		var nv := SchoolPictureG6Core.run(v, [back])
		parts.append("undo %s: %d %s = %d" % [ops[i], int(v), back, int(nv)])
		v = nv
	return "%s. The start was %d." % [_cap("; ".join(parts)), start]


## Bar models (Singapore): a total and a difference (level 1), "times as many" (level 2), a fraction and then a
## fraction of the rest (level 3).
static func bar_problem(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names := _two_names(rng)
	var thing: Array = _pick(rng, THINGS)
	var plural: String = thing[0]
	var ex: Dictionary
	match level:
		1:
			var b := rng.randi_range(5, 40)
			var diff := rng.randi_range(2, 20)
			var a := b + diff
			var total := a + b
			var ask_more := rng.randf() < 0.5
			var who := names[0] if ask_more else names[1]
			ex = K.number("%s and %s have %d %s together. %s has %d more than %s. How many %s has %s?" % [names[0],
				names[1], total, plural, names[0], diff, names[1], plural, who], str(a if ask_more else b),
				"Draw a model: two bars, one longer by %d. Take the extra away and the two bars are equal." % diff,
				"%d − %d = %d, and %d ÷ 2 = %d. %s has %d, and %s has %d + %d = %d." % [total, diff, total - diff,
					total - diff, b, names[1], b, names[0], b, diff, a],
				{"kind": "bar_model", "bars": [{"name": names[0], "parts": [{"text": "?", "size": b}, {"text": str(diff),
					"size": diff}]}, {"name": names[1], "parts": [{"text": "?", "size": b}]}]})
			ex.data = {"kind": "sum_difference", "total": total, "difference": diff, "ask": "more" if ask_more else "less"}
		2:
			var u := rng.randi_range(3, 25)
			var m := rng.randi_range(2, 5)
			var total := (m + 1) * u
			var ask := rng.randi_range(0, 2)
			var answer: int = [m * u, u, (m - 1) * u][ask]
			var question: String = ["How many has %s?" % names[0], "How many has %s?" % names[1],
				"How many more has %s than %s?" % [names[0], names[1]]][ask]
			var parts: Array = []
			for i in m:
				parts.append({"text": "", "size": 1})
			ex = K.number("%s has %d times as many %s as %s. Together they have %d. %s" % [names[0], m, plural, names[1],
				total, question], str(answer),
				"Draw a model: %s's bar is %d equal units and %s's is 1 unit. Find what 1 unit is worth." % [names[0], m,
					names[1]],
				"%d + 1 = %d units make %d, so 1 unit is %d ÷ %d = %d. %s" % [m, m + 1, total, total, m + 1, u,
					["%s has %d × %d = %d." % [names[0], m, u, m * u], "%s has 1 unit: %d." % [names[1], u],
					"The difference is %d − 1 = %d units: %d × %d = %d." % [m, m - 1, m - 1, u, (m - 1) * u]][ask]],
				{"kind": "bar_model", "bars": [{"name": names[0], "parts": parts}, {"name": names[1], "parts": [{"text": "",
					"size": 1}]}]})
			ex.data = {"kind": "times_as_many", "times": m, "total": total, "ask": ["first", "second", "difference"][ask]}
		_:
			var a := rng.randi_range(2, 5)
			var b := rng.randi_range(2, 4)
			var k := rng.randi_range(2, 8)
			var units := a * b
			var start := units * k
			var left := (a - 1) * (b - 1) * k
			var buys := BUYS.duplicate()
			K.shuffle(rng, buys)
			var who := names[0]
			ex = K.number("%s spent 1/%d of some gold on %s, then 1/%d of what was left on %s. %d gold was left. How much gold was there at first?" % [
				who, a, buys[0], b, buys[1], left], str(start),
				"Draw a bar for all the gold, cut into %d × %d = %d equal units. Follow what each thing takes, then find 1 unit." % [
					a, b, units],
				"The first thing took %d units, leaving %d; the second took 1/%d of %d = %d units, leaving %d units. %d units = %d gold, so 1 unit = %d and %d units = %d gold." % [
					b, units - b, b, units - b, a - 1, (a - 1) * (b - 1), (a - 1) * (b - 1), left, k, units, start],
				{"kind": "bar_model", "bars": [{"name": who, "parts": [{"text": "1st", "size": b}, {"text": "2nd",
					"size": a - 1}, {"text": str(left), "size": (a - 1) * (b - 1)}], "total": "?"}]})
			ex.data = {"kind": "fraction_of_rest", "first": a, "second": b, "left": left}
	return ex


## Make a systematic list: choices of one of each (level 1), handshakes (level 2), ways to pay with two kinds of coin
## (level 3).
static func systematic_list(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _name(rng)
	var ex: Dictionary
	match level:
		1:
			var c: Array = _pick(rng, COMBOS)
			var a := rng.randi_range(2, 5)
			var b := rng.randi_range(2, 6)
			ex = K.number("%s has %d %s and %d %s. How many different %s can %s make?" % [who, a, c[0], b, c[1], c[2], who],
				str(a * b), "Make a list: take the first of the %s with each of the %s, then the next one, and so on." % [
					c[0], c[1]],
				"Each of the %d %s goes with each of the %d %s: %d × %d = %d." % [a, c[0], b, c[1], a, b, a * b])
			ex.data = {"kind": "pairs", "a": a, "b": b}
		2:
			var n := rng.randi_range(4, 8)
			var sum_words: Array[String] = []
			for k in range(n - 1, 0, -1):
				sum_words.append(str(k))
			var teams := rng.randf() < 0.5
			var prompt := ("%d teams play in a league. Each team plays each other team once. How many games are there?" % n) \
				if teams else ("%d friends meet, and each shakes hands with each other friend once. How many handshakes?" % n)
			ex = K.number(prompt, str(n * (n - 1) / 2),
				"Make a list: the first one meets all the others, the next meets only the ones not met yet, and so on.",
				"The first meets %d others, the next %d new ones, and so on down to 1: %s = %d." % [n - 1, n - 2,
					" + ".join(PackedStringArray(sum_words)), n * (n - 1) / 2],
				{"kind": "handshakes", "n": n})
			ex.data = {"kind": "handshakes", "n": n}
		_:
			var coins: Array = _pick(rng, [[2, 5], [3, 5], [2, 7]])
			var small: int = coins[0]
			var big: int = coins[1]
			var total := 0
			var ways: Array[String] = []
			for _t in 30:
				total = rng.randi_range(12, 40)
				ways = []
				for f in range(0, total / big + 1):
					if (total - big * f) % small == 0:
						ways.append("%d × %d and %d × %d" % [f, big, (total - big * f) / small, small])
				if ways.size() >= 2 and ways.size() <= 4:
					break
			ex = K.number("In how many ways can %s pay exactly %d gold with %d-gold and %d-gold coins? (None of one kind is fine.)" % [
				who, total, small, big], str(ways.size()),
				"Make a systematic list: try 0 %d-gold coins, then 1, then 2 … and see if %d-gold coins can pay the rest." % [
					big, small],
				"%s: %d ways." % [_cap("; ".join(ways)), ways.size()])
			ex.data = {"kind": "coins", "total": total, "small": small, "big": big}
	return ex


## Guess and check: hens and cows by their heads and legs (level 1), spiders and beetles (level 2), coins of two values
## (level 3).
static func guess_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var kinds: Array = [["hens", 2, "cows", 4, "heads", "legs"], ["beetles", 6, "spiders", 8, "animals", "legs"],
		["2-gold coins", 2, "5-gold coins", 5, "coins", "gold"]]
	var k: Array = kinds[level - 1]
	var count := rng.randi_range(6, 14) if level < 3 else rng.randi_range(8, 16)
	var many := rng.randi_range(1, count - 1)
	var total := int(k[1]) * (count - many) + int(k[3]) * many
	var low_total := int(k[1]) * count
	var guess := count / 2
	var guess_total := int(k[1]) * (count - guess) + int(k[3]) * guess
	var prompt: String
	if level == 3:
		prompt = "%s has %d coins, all 2-gold and 5-gold coins. Together they are worth %d gold. How many 5-gold coins?" % [
			_name(rng), count, total]
	else:
		prompt = "A field has %s and %s: %d %s and %d %s in all. How many %s are there?" % [k[0], k[2], count, k[4], total,
			k[5], k[2]]
	var ex := K.number(prompt, str(many),
		"Guess and check: guess how many %s, work out the %s, then change your guess up or down." % [k[2], k[5]],
		"If all %d were %s: %d %s. %d − %d = %d more, and each of the %s adds %d: %d ÷ %d = %d %s." % [count, k[0],
			low_total, k[5], total, low_total, total - low_total, k[2], int(k[3]) - int(k[1]), total - low_total,
			int(k[3]) - int(k[1]), many, k[2]],
		{"kind": "table", "rows": [[str(k[2]), str(k[0]), str(k[5])], [str(guess), str(count - guess), str(guess_total)],
			["?", "?", str(total)]]})
	ex.data = {"count": count, "total": total, "low": int(k[1]), "high": int(k[3])}
	return ex


## Look for a pattern: the next tower (level 1), the 10th or 20th (level 2), which term is a number, or 1 + 2 + … + n
## (level 3).
static func find_pattern(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var a := rng.randi_range(1, 3)
			var d := rng.randi_range(1, 3)
			var heights := [a, a + d, a + 2 * d, a + 3 * d]
			ex = K.number("The towers grow by the same number of blocks each time. How many blocks will the 5th tower have?",
				str(a + 4 * d), "Look for a pattern: how many blocks are added each time?",
				"Each tower has %d more than the one before: %d + %d = %d." % [d, a + 3 * d, d, a + 4 * d],
				{"kind": "towers", "heights": heights, "missing": true})
			ex.data = {"first": a, "step": d, "n": 5}
		2:
			var a := rng.randi_range(1, 4)
			var d := rng.randi_range(2, 4)
			var n: int = [10, 12, 15, 20][rng.randi_range(0, 3)]
			ex = K.number("The towers grow by the same number of blocks each time. How many blocks will the %dth tower have?" % n,
				str(a + (n - 1) * d), "Look for a pattern: the 1st tower, then the same number added each time. How many times is it added to reach the %dth?" % n,
				"Start with %d and add %d, %d times: %d + %d × %d = %d." % [a, d, n - 1, a, n - 1, d, a + (n - 1) * d],
				{"kind": "towers", "heights": [a, a + d, a + 2 * d]})
			ex.data = {"first": a, "step": d, "n": n}
		_:
			if rng.randf() < 0.5:
				var a := rng.randi_range(2, 9)
				var d := rng.randi_range(3, 7)
				var n := rng.randi_range(8, 20)
				var target := a + (n - 1) * d
				ex = K.number("In the pattern %d, %d, %d, %d, … which term is %d? (%d is the 1st term.)" % [a, a + d, a + 2 * d,
					a + 3 * d, target, a], str(n), "Look for a pattern: how many steps of %d take you from %d to %d?" % [d, a,
						target],
					"%d − %d = %d, and %d ÷ %d = %d steps, so it is term %d + 1 = %d." % [target, a, target - a, target - a, d,
						n - 1, n - 1, n])
				ex.data = {"first": a, "step": d, "target": target}
			else:
				var n: int = [10, 20, 30, 40, 50, 100][rng.randi_range(0, 5)]
				ex = K.number("What is 1 + 2 + 3 + … + %d?" % n, str(n * (n + 1) / 2),
					"Look for a pattern: pair the first and last numbers, then the second and second last…",
					"Each pair makes %d + 1 = %d, and there are %d ÷ 2 = %d pairs: %d × %d = %d." % [n, n + 1, n, n / 2, n + 1,
						n / 2, n * (n + 1) / 2])
				ex.data = {"sum_to": n}
	return ex


## Choose a strategy for a problem (Singapore's heuristics): the clearest problems (level 1) to subtler ones (level 3).
static func strategy_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var p: Array = _pick(rng, _at_level(STRATEGY_PROBLEMS, level, 2))
	var wrongs: Array = STRATEGIES.filter(func(s: String) -> bool: return s != str(p[1]))
	K.shuffle(rng, wrongs)
	var ex := K.choice(rng, "Which strategy suits this problem best? %s" % p[0], str(p[1]), wrongs.slice(0, 3),
		"Ask: is there an end to undo, a whole and parts to draw, a list of cases, a rule that repeats, or a guess to test?",
		"%s: %s." % [_cap(str(p[1])), _why_strategy(str(p[1]))])
	ex.data = {"problem": p[0]}
	return ex


static func _why_strategy(s: String) -> String:
	match s:
		"draw a model":
			return "bars show the whole, the parts and how many times one is bigger"
		"work backwards":
			return "you know the end, so undo each step from the last"
		"make a systematic list":
			return "list every case in order so none is missed or counted twice"
		"guess and check":
			return "two facts must both fit, so guess, check and improve the guess"
	return "the numbers follow a rule, so find the rule and use it"


# --- Skeleton and muscles --------------------------------------------------------------------------------------------

## Bones: which bone protects a part (level 1), which bone is marked on the skeleton (level 2), true or false facts
## (level 3).
static func bone_job(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var p: Array = _pick(rng, PROTECTS)
			var wrongs: Array = ["skull", "ribs", "spine", "femur", "pelvis"].filter(func(b: String) -> bool: return b != str(p[1]))
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "Which bone or bones protect %s?" % p[0], str(p[1]), wrongs.slice(0, 3),
				"Think of the soft part and the hard case round it.",
				"The %s protect%s %s." % [p[1], "" if str(p[1]) == "ribs" else "s", p[0]])
			ex.data = {"protects": p[0]}
		2:
			var bones: Array = BONE_WORDS.keys()
			var b: String = bones[rng.randi_range(0, bones.size() - 1)]
			var wrongs: Array = []
			for o: Variant in bones:
				if str(o) != b:
					wrongs.append(str(BONE_WORDS[o]))
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "Which bone is shown in orange?", str(BONE_WORDS[b]), wrongs.slice(0, 3),
				"Is it in the head, the chest, the middle, an arm or a leg? Upper or lower?",
				"The orange bone is the %s." % BONE_WORDS[b], {"kind": "skeleton", "mark": b})
			ex.data = {"bone": b}
		_:
			var f: Array = _pick(rng, BONE_FACTS)
			ex = K.truefalse(str(f[0]), bool(f[1]), "Think about what bones do and what they are made of.", str(f[2]))
			ex.data = {"fact": f[0]}
	return ex


## Muscles work in pairs: which contracts (level 1, the arm drawn), which relaxes (level 2), true or false (level 3).
static func muscle_work(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var f: Array = _pick(rng, MUSCLE_FACTS)
		ex = K.truefalse(str(f[0]), bool(f[1]), "Muscles pull by getting shorter; tendons and ligaments hold things together.",
			str(f[2]))
		ex.data = {"fact": f[0]}
		return ex
	var pool: Array = MOVES.filter(func(m: Array) -> bool: return str(m[3]) == "arm") if level == 1 else MOVES
	var m: Array = _pick(rng, pool)
	var muscles := ["biceps", "triceps"] if str(m[3]) == "arm" else ["hamstrings", "quadriceps"]
	var contract := level == 1 or rng.randf() < 0.5
	var right := str(m[1]) if contract else str(m[2])
	var others: Array = ["biceps", "triceps", "hamstrings", "quadriceps"].filter(func(x: String) -> bool: return x != right)
	var pic := {"kind": "muscle_pair", "move": "bend" if str(m[0]).begins_with("bend") else "straighten"} \
		if str(m[3]) == "arm" else {}
	ex = K.choice(rng, "To %s, which muscle %s?" % [m[0], "contracts" if contract else "relaxes"], right,
		others.slice(0, 3), "Muscles pull, never push. The muscle that pulls the bone the way it moves contracts.",
		"%s %s and %s %s: they work as a pair." % [_cap(str(m[1])), _verb(str(m[1]), "contract"), m[2],
			_verb(str(m[2]), "relax")], pic)
	ex.data = {"move": m[0], "contract": contract, "pair": muscles}
	return ex


## Joints: which kind is at a place (level 1), which kind is drawn (level 2), sort places by how they move (level 3).
static func joint_type(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var j: Array = _pick(rng, JOINT_PLACES)
			ex = K.choice(rng, "What kind of joint is at %s?" % j[0], str(j[1]),
				JOINT_KINDS.filter(func(x: String) -> bool: return x != str(j[1])),
				"Does it move like a door, turn every way, twist round, or not move at all?",
				"%s: a %s." % [_cap(str(j[0])), j[1]])
			ex.data = {"place": j[0]}
		2:
			var kind: String = _pick(rng, JOINT_KINDS)
			ex = K.choice(rng, "What kind of joint is this?", kind, JOINT_KINDS.filter(func(x: String) -> bool: return x != kind),
				"Look at how the bones meet and at the red arrow: one way, every way, round, or none?",
				"It is a %s." % kind, {"kind": "joint", "type": JOINT_TYPE[kind], "name": false})
			ex.data = {"kind": kind}
		_:
			var pool: Array = []
			for place: String in JOINT_MOVES:
				pool.append([place, JOINT_MOVES[place]])
			var groups := ["moves one way", "moves every way", "does not move"]
			ex = _sort(rng, "Sort the joints by how they move.", groups, _spread(rng, pool, groups, 5),
				"A hinge moves one way, like a door; a ball and socket turns every way; a fixed joint does not move.")
			ex.data = {"items": ex.items}
	return ex


# --- Nutrition and digestion -----------------------------------------------------------------------------------------

## Nutrients: foods (level 1), jobs (level 2), what a lack causes, or sorting foods (level 3).
static func nutrient_find(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var f: Array = _pick(rng, FOOD_NUTRIENTS)
			ex = K.choice(rng, "Which nutrient are %s rich in?" % f[0], str(f[1]), f[2],
				"Think of the job these foods do: energy, growth, a store of energy, bones or healthy gums?",
				"%s are rich in %s." % [_cap(str(f[0])), f[1]])
			ex.data = {"foods": f[0]}
		2:
			var j: Array = _pick(rng, NUTRIENT_JOBS)
			ex = K.choice(rng, "Which nutrient %s?" % j[0], str(j[1]), j[2],
				"Match the job to the nutrient: energy, growth, warmth, gut, bones, blood, gums, sunlight or every cell.",
				"%s %s." % [_cap(str(j[1])), j[0]])
			ex.data = {"job": j[0]}
		_:
			if rng.randf() < 0.5:
				var dfc: Array = _pick(rng, DEFICIENCIES)
				ex = K.choice(rng, "A lack of which nutrient causes %s?" % dfc[0], str(dfc[1]), dfc[2],
					"Think of what the missing nutrient does: gums, bones, red blood cells or the gut.",
					"%s: too little %s." % [_cap(str(dfc[0]).get_slice(" (", 0)), dfc[1]])
				ex.data = {"illness": dfc[0]}
			else:
				var groups := ["carbohydrates", "proteins", "fats"]
				ex = _sort(rng, "Sort the foods by the nutrient they are richest in.", groups, _spread(rng, SORT_FOODS, groups, 6),
					"Energy foods (grains and potatoes), growth foods (meat, fish, eggs, beans) or fats (oils, butter)?")
				ex.data = {"items": ex.items}
	return ex


## Food tests: one tube (level 1), which of three foods has the nutrient (level 2), what one food contains from four
## tests (level 3).
static func food_test_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var t: String = _pick(rng, TESTS)
			ex = K.choice(rng, "A food was tested with %s. Which nutrient does the result show?" % TEST_WORDS[t], t,
				TESTS.filter(func(x: String) -> bool: return x != t),
				"Each test looks for one nutrient: iodine for starch, Benedict's for sugar, biuret for protein, paper for fat.",
				"%s, so the food contains %s." % [_result_words(t), t],
				{"kind": "food_test", "tubes": [[t, true, "food"]]})
			ex.data = {"tubes": [[t, true]]}
		2:
			var t: String = _pick(rng, TESTS)
			var right := rng.randi_range(0, 2)
			var tubes: Array = []
			for i in 3:
				tubes.append([t, i == right, ["A", "B", "C"][i]])
			ex = K.choice(rng, "Three foods, A, B and C, were %s. Which one contains %s?" % [TEST_HOW[t], t],
				"food %s" % ["A", "B", "C"][right],
				["food %s" % ["A", "B", "C"][(right + 1) % 3], "food %s" % ["A", "B", "C"][(right + 2) % 3]],
				"Only one result changed colour (or, for paper, left a see-through spot). Which one?",
				"Food %s: its test shows %s; the others show %s." % [["A", "B", "C"][right],
					SchoolPictureG6Core.colour_word(t, true), SchoolPictureG6Core.colour_word(t, false)],
				{"kind": "food_test", "tubes": tubes})
			ex.data = {"tubes": tubes}
		_:
			var has: Array = []
			var tubes: Array = []
			for t: String in TESTS:
				var pos := rng.randf() < 0.5
				tubes.append([t, pos])
			var any := false
			for tb: Array in tubes:
				any = any or bool(tb[1])
			if not any:
				tubes[rng.randi_range(0, 3)][1] = true
			for tb: Array in tubes:
				if bool(tb[1]):
					has.append(str(tb[0]))
			var right := _and_list(has)
			var wrongs: Array = []
			var tries := 0
			while wrongs.size() < 3 and tries < 50:
				tries += 1
				var other: Array = []
				for t: String in TESTS:
					if rng.randf() < 0.5:
						other.append(t)
				if other.is_empty():
					continue
				var w := _and_list(other)
				if w != right and not wrongs.has(w):
					wrongs.append(w)
			ex = K.choice(rng, "One food was tested four ways. Which nutrients does it contain?", right, wrongs,
				"Check each result: blue-black, brick red, purple and a see-through spot each mean a nutrient is there.",
				"It contains %s: those tests changed; the others stayed %s." % [right, "the same"],
				{"kind": "food_test", "tubes": tubes})
			ex.data = {"tubes": tubes}
	return ex


static func _result_words(t: String) -> String:
	match t:
		"starch":
			return "Iodine turned from orange-brown to blue-black"
		"sugar":
			return "Heated Benedict's solution turned from blue to brick red"
		"protein":
			return "Biuret turned from blue to purple"
	return "The paper shows a see-through spot"


static func _and_list(words: Array) -> String:
	if words.size() == 1:
		return str(words[0])
	var head := PackedStringArray(words.slice(0, words.size() - 1).map(func(w: Variant) -> String: return str(w)))
	return "%s and %s" % [", ".join(head), words[-1]]


## Enzymes: which enzyme (level 1), what it makes (level 2), where each part of digestion happens (level 3).
static func enzyme_job(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var food: String = _pick(rng, SchoolPictureG6Core.FOODS)
	var ex: Dictionary
	match level:
		1:
			var right := str(SchoolPictureG6Core.ENZYMES[food])
			ex = K.choice(rng, "Which enzyme breaks %s down?" % food, right, ["amylase", "protease", "lipase", "bile"].filter(
				func(x: String) -> bool: return x != right),
				"Enzymes are named after the food they break: prote- for protein, lip- for fat, amyl- for starch.",
				"%s breaks %s into %s." % [_cap(right), food, SchoolPictureG6Core.PRODUCTS[food]],
				{"kind": "enzyme_cut", "food": food, "hide": "enzyme"})
			ex.data = {"food": food}
		2:
			var right := str(SchoolPictureG6Core.PRODUCTS[food])
			var wrongs: Array = ["sugars", "amino acids", "fatty acids and glycerol", "fibre"].filter(
				func(x: String) -> bool: return x != right)
			ex = K.choice(rng, "What does %s break %s into?" % [SchoolPictureG6Core.ENZYMES[food], food], right, wrongs,
				"Big food molecules are chains or bundles of small ones. Which small ones make up this food?",
				"%s breaks %s into %s, small enough to pass into the blood." % [
					_cap(str(SchoolPictureG6Core.ENZYMES[food])), food, right],
				{"kind": "enzyme_cut", "food": food, "hide": "products"})
			ex.data = {"food": food}
		_:
			var g: Array = _pick(rng, GUT_PLACES)
			ex = K.choice(rng, str(g[0]), str(g[1]), g[2],
				"Follow food from the mouth: chewing and saliva, the stomach's acid, the small intestine, then the large one.",
				"%s." % _cap(str(g[1])), {"kind": "digestion", "labels": true})
			ex.data = {"question": g[0]}
	return ex


# --- Classifying life ------------------------------------------------------------------------------------------------

## The five groups of vertebrates: an animal drawn (level 1), by features (level 2), animals people sort wrongly
## (level 3).
static func vertebrate_group(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var animals: Array = ANIMAL_GROUPS.keys()
			var a: String = animals[rng.randi_range(0, animals.size() - 1)]
			var right := str(ANIMAL_GROUPS[a])
			var wrongs: Array = GROUPS.filter(func(g: String) -> bool: return g != right)
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "Which group of vertebrates is this animal in?", right, wrongs.slice(0, 3),
				"Look at its skin: scales and fins, moist skin, dry scales, feathers, or fur?",
				"%s is %s." % [_cap(_a(a.replace("_", " "))), _a(right)], {"kind": "icon", "animal": a})
			ex.data = {"animal": a}
		2:
			var f: Array = _pick(rng, GROUP_FEATURES)
			ex = K.choice(rng, "%s Which group is it in?" % f[0], str(f[1]), GROUPS.filter(
				func(g: String) -> bool: return g != str(f[1])).slice(0, 3),
				"Gills and fins, moist skin, dry scales, feathers, or fur and milk?",
				"Those are the features of %s." % _a(str(f[1])))
			ex.data = {"features": f[0]}
		_:
			var t: Array = _pick(rng, TRICKY)
			var wrongs: Array = GROUPS.filter(func(g: String) -> bool: return g != str(t[1]))
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "Which group of vertebrates is %s in?" % t[0], str(t[1]), wrongs.slice(0, 3),
				"Do not go by where it lives or how it moves: check how it breathes, its skin and how it feeds its young.",
				"%s is %s. %s" % [_cap(str(t[0])), _a(str(t[1])), t[2]])
			ex.data = {"animal": t[0]}
	return ex


## Invertebrates: an animal's group (level 1), a group by its features (level 2), the one that is not an insect (level 3).
static func invertebrate_group(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var a: Array = _pick(rng, INVERT_ANIMALS)
			var wrongs: Array = INVERT_GROUPS.filter(func(g: String) -> bool: return g != str(a[1]))
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "Which group of invertebrates is %s in?" % a[0], str(a[1]), wrongs.slice(0, 3),
				"Count its legs and look at its body: six legs, eight legs, a hard shell, a soft body, rings, or many legs?",
				"%s is in the %s." % [_cap(str(a[0])), a[1]])
			ex.data = {"animal": a[0]}
		2:
			var f: Array = _pick(rng, INVERT_FEATURES)
			var wrongs: Array = INVERT_GROUPS.filter(func(g: String) -> bool: return g != str(f[1]))
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "An invertebrate has %s. Which group is it in?" % f[0], str(f[1]), wrongs.slice(0, 3),
				"Insects have six legs, arachnids eight; crustaceans wear a hard shell; molluscs are soft; worms have rings.",
				"Animals with %s are %s." % [f[0], f[1]])
			ex.data = {"features": f[0]}
		_:
			var insects: Array = INVERT_ANIMALS.filter(func(a: Array) -> bool: return str(a[1]) == "insects")
			var others: Array = INVERT_ANIMALS.filter(func(a: Array) -> bool: return str(a[1]) in ["arachnids",
				"crustaceans", "myriapods"])
			K.shuffle(rng, insects)
			var odd: Array = _pick(rng, others)
			var wrongs: Array = []
			for a: Array in insects.slice(0, 3):
				wrongs.append(str(a[0]))
			ex = K.choice(rng, "Which of these is NOT an insect?", str(odd[0]), wrongs,
				"Count the legs: every insect has six legs and three body parts.",
				"%s is in the %s, not an insect; the others have six legs." % [_cap(str(odd[0])), odd[1]])
			ex.data = {"odd": odd[0]}
	return ex


## A key of yes-or-no questions: 2 questions (level 1), 3 (level 2), 4 (level 3); a living thing described, named by
## walking the key.
static func key_walk(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = KEYS.filter(func(k: Array) -> bool: return (k[0] as Array).size() == level + 1)
	var key: Array = _pick(rng, pool)
	var qs: Array = key[0]
	var ends: Array = key[1]
	var t := rng.randi_range(0, ends.size() - 1)
	var words: Array[String] = []
	var answers: Array = []
	for i in qs.size():
		if i < t:
			words.append(str(qs[i][2]))
			answers.append(false)
		elif i == t:
			words.append(str(qs[i][1]))
			answers.append(true)
	var said := ", ".join(PackedStringArray(words.slice(0, words.size() - 1))) + (" and " if words.size() > 1 else "") \
		+ words[-1]
	var questions: Array = []
	for q: Array in qs:
		questions.append(str(q[0]))
	var wrongs: Array = ends.filter(func(e: Variant) -> bool: return str(e) != str(ends[t]))
	K.shuffle(rng, wrongs)
	var ex := K.choice(rng, "Use the key: %s. What is it?" % said, str(ends[t]), wrongs.slice(0, 3),
		"Start at question 1. Answer each question for this living thing: yes names it, no takes you down to the next.",
		"%s: the key names the %s." % [_cap(said), ends[t]], {"kind": "key_tree", "questions": questions, "ends": ends})
	ex.data = {"questions": questions, "ends": ends, "answers": answers, "said": said}
	return ex


## Kingdoms: a living thing's kingdom (level 1), by its features (level 2), the ones people sort wrongly (level 3).
static func kingdom_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 2:
		var f: Array = _pick(rng, KINGDOM_FEATURES)
		var wrongs: Array = KINGDOM_NAMES.filter(func(k: String) -> bool: return k != str(f[1]))
		K.shuffle(rng, wrongs)
		ex = K.choice(rng, "%s Which kingdom is it in?" % f[0], str(f[1]), wrongs.slice(0, 3),
			"Does it make its own food? Is it one cell or many? Does its cell have a nucleus?",
			"That describes the %s kingdom." % f[1], {"kind": "kingdoms", "show": KINGDOM_NAMES, "names": true})
		ex.data = {"features": f[0]}
		return ex
	var pool: Array = KINGDOM_OF.filter(func(k: Array) -> bool: return int(k[2]) == level)
	var k: Array = _pick(rng, pool)
	var wrongs: Array = KINGDOM_NAMES.filter(func(x: String) -> bool: return x != str(k[1]))
	K.shuffle(rng, wrongs)
	ex = K.choice(rng, "Which kingdom is %s in?" % k[0], str(k[1]), wrongs.slice(0, 3),
		"Plants make their own food; fungi feed on dead things; animals eat; protists and bacteria are single cells.",
		"%s is in the %s kingdom." % [_cap(str(k[0])), k[1]])
	ex.data = {"living": k[0]}
	return ex


## The levels of classification in order: 4 (level 1), 5 (level 2), 6 of the wolf's names (level 3).
static func taxon_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var count: int = [4, 5, 6][level - 1]
	var idx: Array = range(7)
	K.shuffle(rng, idx)
	idx = idx.slice(0, count)
	idx.sort()
	var ex: Dictionary
	if level < 3:
		var steps: Array = []
		for i: int in idx:
			steps.append(LEVEL_NAMES[i])
		ex = K.order(rng, "Put the levels in order, from the biggest group to the smallest.", steps,
			"Remember: Kind People Can Often Find Good Snacks (kingdom, phylum, class, order, family, genus, species).",
			"From biggest to smallest: %s." % ", ".join(PackedStringArray(steps)))
		ex.data = {"levels": steps}
	else:
		var steps: Array = []
		for i: int in idx:
			steps.append(WOLF[i])
		ex = K.order(rng, "Put the wolf's groups in order, from the biggest to the smallest.", steps,
			"The biggest group holds the most living things: all animals. The smallest is the wolf itself, Canis lupus.",
			"From biggest to smallest: %s." % ", ".join(PackedStringArray(steps)))
		ex.data = {"levels": steps}
	return ex


# --- Light -----------------------------------------------------------------------------------------------------------

## Shadows: bigger or smaller (level 1), the shadow's height (level 2), the card's height or its distance (level 3).
static func shadow_size(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var who := _name(rng)
	if level == 1:
		var m: Array = _pick(rng, SHADOW_MOVES)
		ex = K.choice(rng, "%s makes a shadow of a card on a screen with a lamp. Then %s %s. What happens to the shadow?" % [
			who, who, m[0]], str(m[1]), ["It gets bigger.", "It gets smaller.", "It stays the same size."].filter(
				func(x: String) -> bool: return x != str(m[1])),
			"Light travels in straight lines. Imagine the two rays past the card's edges spreading out to the screen.",
			"%s The closer the card is to the lamp (and the farther the screen), the more the rays spread: a bigger shadow." % m[1],
			{"kind": "shadow_rays", "near": 20, "far": 60, "size": 5, "numbers": false, "hide": "none"})
		ex.data = {"move": m[0]}
		return ex
	var near := rng.randi_range(2, 10) * 5
	var k := rng.randi_range(2, 5)
	var far := near * k
	var size := rng.randi_range(2, 10)
	var shadow := size * k
	var hint := "The rays spread in straight lines: the screen is %s as far from the lamp as the card, so the shadow is that many times taller." % \
		"how many times"
	if level == 2:
		ex = K.number("The card is %d cm tall and %d cm from the lamp. The screen is %d cm from the lamp. How tall is the shadow, in cm?" % [
			size, near, far], str(shadow), hint,
			"The screen is %d ÷ %d = %d times as far as the card, so the shadow is %d × %d = %d cm tall." % [far, near, k, size,
				k, shadow],
			{"kind": "shadow_rays", "near": near, "far": far, "size": size, "hide": "shadow"})
		ex.data = {"near": near, "far": far, "size": size, "ask": "shadow"}
	elif rng.randf() < 0.5:
		ex = K.number("The shadow is %d cm tall. The card is %d cm from the lamp and the screen is %d cm from it. How tall is the card, in cm?" % [
			shadow, near, far], str(size), hint,
			"The screen is %d ÷ %d = %d times as far, so the shadow is %d times the card: %d ÷ %d = %d cm." % [far, near, k, k,
				shadow, k, size],
			{"kind": "shadow_rays", "near": near, "far": far, "size": size, "hide": "size"})
		ex.data = {"near": near, "far": far, "size": size, "ask": "size"}
	else:
		ex = K.number("A %d cm card makes a %d cm shadow on a screen %d cm from the lamp. How far is the card from the lamp, in cm?" % [
			size, shadow, far], str(near), "The shadow is how many times taller than the card? The screen is that many times as far away as the card.",
			"The shadow is %d ÷ %d = %d times the card, so the card is %d ÷ %d = %d cm from the lamp." % [shadow, size, k,
				far, k, near],
			{"kind": "shadow_rays", "near": near, "far": far, "size": size, "hide": "near"})
		ex.data = {"near": near, "far": far, "size": size, "ask": "near"}
	return ex


## Reflection: the angle of reflection from the angle of incidence (level 1), from the angle to the mirror (level 2),
## the angle between the rays (level 3).
static func mirror_angle(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var i := rng.randi_range(3, 15) * 5
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A ray of light hits a flat mirror. The angle of incidence is %d°. What is the angle of reflection?" % i,
				str(i), "Both angles are measured from the normal, the dashed line at right angles to the mirror.",
				"The angle of reflection equals the angle of incidence: %d°." % i,
				{"kind": "reflection", "i": i, "marks": ["i", "r"], "unknown": "r"})
			ex.data = {"i": i, "ask": "r"}
		2:
			var m := 90 - i
			if rng.randf() < 0.5:
				ex = K.number("The ray meets the mirror at %d°, measured from the mirror. What is the angle of reflection, measured from the normal?" % m,
					str(i), "The normal is at 90° to the mirror. The angle from the normal and the angle from the mirror make 90°.",
					"The angle of incidence is 90° − %d° = %d°, and the angle of reflection equals it: %d°." % [m, i, i],
					{"kind": "reflection", "i": i, "marks": ["mi", "r"], "unknown": "r"})
				ex.data = {"i": i, "ask": "r"}
			else:
				ex = K.number("The ray comes in at %d° to the mirror. At what angle to the mirror does it leave?" % m, str(m),
					"The ray leaves the mirror the same way it came in, like a ball bouncing off a wall.",
					"It leaves at the same angle to the mirror: %d° (and at %d° to the normal on both sides)." % [m, i],
					{"kind": "reflection", "i": i, "marks": ["mi", "mr"], "unknown": "mr"})
				ex.data = {"i": i, "ask": "mr"}
		_:
			if rng.randf() < 0.5:
				ex = K.number("The angle of incidence is %d°. What is the angle between the ray going in and the ray coming out?" % i,
					str(2 * i), "The angle of reflection equals the angle of incidence, and both sit either side of the normal.",
					"%d° + %d° = %d°." % [i, i, 2 * i], {"kind": "reflection", "i": i, "marks": ["i", "both"], "unknown": "both"})
				ex.data = {"i": i, "ask": "both"}
			else:
				ex = K.number("The ray going in and the ray coming out make an angle of %d°. What is the angle of incidence?" % (2 * i),
					str(i), "The normal cuts the angle between the rays exactly in half.",
					"%d° ÷ 2 = %d°: the angle of incidence and the angle of reflection are equal." % [2 * i, i],
					{"kind": "reflection", "i": i, "marks": ["i", "both"], "unknown": "i"})
				ex.data = {"i": i, "ask": "i"}
	return ex


## Light: a light source or not (level 1), transparent, translucent or opaque (level 2), how we see, in order (level 3).
static func light_kind(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var s: Array = _pick(rng, SOURCES)
			ex = K.truefalse("%s is a light source." % _cap(str(s[0])), bool(s[1]),
				"A light source makes its own light. Things that only bounce light back are not sources.",
				("True: %s gives out its own light." if bool(s[1]) else "False: %s makes no light; it only reflects light.") % s[0])
			ex.data = {"thing": s[0]}
		2:
			var groups := ["transparent", "translucent", "opaque"]
			ex = _sort(rng, "Sort them: how much light do they let through?", groups, _spread(rng, MATERIALS, groups, 6),
				"Transparent: you see clearly through it. Translucent: some light, blurry. Opaque: no light, a shadow.")
			ex.data = {"items": ex.items}
		_:
			var s: Array = _pick(rng, SEEING)
			var steps: Array = s[1]
			ex = K.order(rng, "%s Put what happens in order." % s[0], steps,
				"Follow the light: where does it start, what does it bounce off, and where does it end?",
				"%s." % ". ".join(PackedStringArray(steps)))
			ex.data = {"steps": steps}
	return ex


# --- Energy changes --------------------------------------------------------------------------------------------------

## Energy changes: a device's useful energy (level 1), what goes in (level 2), the missing step of a chain (level 3).
static func energy_convert(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level < 3:
		var dv: Array = _pick(rng, DEVICES)
		var ask_out := level == 1
		var right := str(dv[2]) if ask_out else str(dv[1])
		var wrongs: Array = SchoolPictureG6Core.FORMS.filter(func(f: String) -> bool: return f != right and f != (
			str(dv[1]) if ask_out else str(dv[2])))
		K.shuffle(rng, wrongs)
		ex = K.choice(rng, ("What useful energy does %s give out?" % dv[0]) if ask_out else \
			("%s changes which energy into %s energy?" % [_cap(str(dv[0])), dv[2]]), "%s energy" % right,
			wrongs.slice(0, 3).map(func(w: Variant) -> String: return "%s energy" % w),
			"Think what it is for (its useful output) and what it needs to work (its input).",
			"%s changes %s energy into %s energy." % [_cap(str(dv[0])), dv[1], dv[2]],
			{"kind": "energy_chain", "steps": [dv[1], dv[2]], "hide": 1 if ask_out else 0})
		ex.data = {"device": dv[0], "ask": "out" if ask_out else "in"}
		return ex
	var c: Array = _pick(rng, CHAINS)
	var steps: Array = c[1]
	var hide := rng.randi_range(1, steps.size() - 2)
	var right := str(steps[hide])
	var wrongs: Array = SchoolPictureG6Core.FORMS.filter(func(f: String) -> bool: return f != right)
	K.shuffle(rng, wrongs)
	ex = K.choice(rng, "Energy changes in %s. Which form is missing?" % c[0], "%s energy" % right,
		wrongs.slice(0, 3).map(func(w: Variant) -> String: return "%s energy" % w),
		"Follow the energy step by step: what does each part store or do?",
		"The chain is %s." % " to ".join(PackedStringArray(steps.map(func(s: Variant) -> String: return str(s)))),
		{"kind": "energy_chain", "steps": steps, "hide": hide})
	ex.data = {"chain": c[0], "hide": hide}
	return ex


## Energy flows (Sankey diagrams): the wasted energy (level 1), the useful energy (level 2), the efficiency (level 3).
static func energy_waste(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w: Array = _pick(rng, WASTERS)
	var total: int = [100, 200, 400, 500, 1000][rng.randi_range(0, 4)]
	var span: Array = w[2]
	var pct := rng.randi_range(int(span[0]), int(span[1]))
	if level == 3:
		pct = int(roundf(pct / 5.0)) * 5
		pct = clampi(pct, 5, 95)
	var useful := total * pct / 100
	var wasted_names: Array = w[3]
	var wasted: Array = []
	if level == 1 or wasted_names.size() == 1:
		wasted = [[str(wasted_names[0]), total - useful]]
	else:
		var first := (total - useful) * rng.randi_range(5, 8) / 10
		wasted = [[str(wasted_names[0]), first], [str(wasted_names[1]), total - useful - first]]
	var pic := {"kind": "sankey", "total": total, "useful": [[str(w[1]), useful]], "wasted": wasted, "name": str(w[0])}
	var ex: Dictionary
	match level:
		1:
			pic.hide = 2
			ex = K.number("%s takes in %d J of energy and gives out %d J of useful energy (%s). How much is wasted, in J?" % [
				_cap(str(w[0])), total, useful, w[1]], str(total - useful),
				"Energy is never made or destroyed: the useful and the wasted energy add up to what went in.",
				"%d − %d = %d J wasted." % [total, useful, total - useful], pic)
		2:
			pic.hide = 1
			var wasted_sum := 0
			for part: Array in wasted:
				wasted_sum += int(part[1])
			ex = K.number("%s takes in %d J. The diagram shows the energy wasted. How much useful energy (%s) does it give out, in J?" % [
				_cap(str(w[0])), total, w[1]], str(useful),
				"Add up the wasted energy, then take it from the energy that went in.",
				"Wasted: %d J. %d − %d = %d J of useful energy." % [wasted_sum, total, wasted_sum, useful], pic)
		_:
			ex = K.number("%s takes in %d J and gives out %d J of useful energy (%s). What is its efficiency, in %%?" % [
				_cap(str(w[0])), total, useful, w[1]], str(pct),
				"Efficiency = useful energy out ÷ total energy in × 100.",
				"%d ÷ %d × 100 = %d%%." % [useful, total, pct], pic)
	ex.data = {"total": total, "useful": useful, "wasted": wasted}
	return ex


## Saving energy: which choice wastes less (levels 1-3).
static func save_energy(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var s: Array = _pick(rng, _at_level(SAVERS, level, 3))
	var ex := K.choice(rng, str(s[0]), str(s[1]), s[2],
		"Which one needs less energy for the same job, or keeps heat in where it is wanted?",
		"%s: it does the job with less energy wasted." % _cap(str(s[1])))
	ex.data = {"question": s[0]}
	return ex


# --- Engineering design ----------------------------------------------------------------------------------------------

## Criteria (what a design must do) and constraints (its limits): one statement (level 1), sort 4 (level 2) or 6
## (level 3).
static func criteria_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var s: Array = _pick(rng, DESIGN_STATEMENTS)
		ex = K.choice(rng, "\"%s\" Is this a criterion or a constraint?" % s[0], "a %s" % s[1], ["a %s" % (
			"constraint" if str(s[1]) == "criterion" else "criterion")],
			"A criterion says what the design must do to work. A constraint is a limit: cost, time, materials, size or safety.",
			"It is a %s: %s" % [s[1], "it says what the design must do." if str(s[1]) == "criterion" else "it limits how you build it."])
		ex.data = {"statement": s[0]}
		return ex
	var groups := ["criterion", "constraint"]
	ex = _sort(rng, "Sort them: criteria (what it must do) or constraints (limits)?", groups,
		_spread(rng, DESIGN_STATEMENTS, groups, 4 if level == 2 else 6),
		"Ask: does it say what success looks like, or does it limit the money, time, materials, size or safety?")
	ex.data = {"items": ex.items}
	return ex


## Which design meets the brief, from a table of test results: one criterion (level 1), a criterion and a cost limit
## (level 2), two criteria and a cost limit (level 3).
static func design_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var task: Array = _pick(rng, DESIGN_TASKS)
	var need := rng.randi_range(4, 9) * 5
	var budget := rng.randi_range(4, 9)
	var letters := ["A", "B", "C", "D"]
	var rows: Array = []
	for _t in 60:
		rows = []
		for i in 4:
			rows.append([letters[i], rng.randi_range(need / 5 - 3, need / 5 + 3) * 5, rng.randi_range(budget - 3, budget + 3),
				rng.randi_range(1, 5)])
		var ok := 0
		for row: Array in rows:
			if _meets(row, level, need, budget):
				ok += 1
		if ok == 1:
			break
	var met := rows.filter(func(row: Array) -> bool: return _meets(row, level, need, budget))
	if met.size() != 1:   # never in practice: make design A the only one that meets the brief
		rows[0] = ["A", need + 5, budget - 1, 2]
		for i in range(1, 4):
			rows[i] = [letters[i], need - 5 * i, budget - 1, 2]
	var header: Array = ["design", str(task[1]), "cost"]
	if level == 3:
		header.append("mass kg")
	var table_rows: Array = [header]
	var right := ""
	for row: Array in rows:
		var r: Array = [str(row[0]), str(row[1]), str(row[2])]
		if level == 3:
			r.append(str(row[3]))
		table_rows.append(r)
		if _meets(row, level, need, budget):
			right = "design %s" % row[0]
	var brief := str(task[2]) % need
	if level >= 2:
		brief += (", cost at most %d gold" if level == 3 else " and cost at most %d gold") % budget
	if level == 3:
		brief += " and have a mass of at most 3 kg"
	var wrongs: Array = []
	for row: Array in rows:
		if "design %s" % row[0] != right:
			wrongs.append("design %s" % row[0])
	var ex := K.choice(rng, "Four %s designs were tested (cost in gold). The %s must %s. Which design meets the brief?" % [
		task[0], task[0], brief], right, wrongs,
		"Check each design against every part of the brief, one at a time; cross out any that fail one.",
		"Only %s meets every part: it can %s." % [right, brief], {"kind": "table", "rows": table_rows})
	ex.data = {"rows": rows, "need": need, "budget": budget}
	return ex


static func _meets(row: Array, level: int, need: int, budget: int) -> bool:
	if int(row[1]) < need:
		return false
	if level >= 2 and int(row[2]) > budget:
		return false
	if level == 3 and int(row[3]) > 3:
		return false
	return true


## A decision matrix: one design's total (level 1), its weighted total (level 2), the best design by weighted total
## (level 3).
static func decision_matrix(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var criteria := ["strong", "cheap", "light"]
	var weights := [3, 2, 1]
	K.shuffle(rng, weights)
	var designs := ["A", "B", "C"]
	var scores: Array = []
	var totals: Array = []
	var best := -1
	for _t in 40:
		scores = []
		totals = []
		for i in 3:
			var s: Array = []
			var t := 0
			for c in 3:
				var v := rng.randi_range(1, 5)
				s.append(v)
				t += v * (int(weights[c]) if level > 1 else 1)
			scores.append(s)
			totals.append(t)
		var top := -1
		var count := 0
		for i in 3:
			if int(totals[i]) > top:
				top = int(totals[i])
				best = i
				count = 1
			elif int(totals[i]) == top:
				count += 1
		if count == 1:
			break
	var header: Array = ["design"]
	for c in 3:
		header.append(criteria[c] if level == 1 else "%s ×%d" % [criteria[c], weights[c]])
	var rows: Array = [header]
	for i in 3:
		rows.append([designs[i], str(scores[i][0]), str(scores[i][1]), str(scores[i][2])])
	var pic := {"kind": "table", "rows": rows}
	var ex: Dictionary
	var d := rng.randi_range(0, 2)
	var s: Array = scores[d]
	match level:
		1:
			ex = K.number("Each design was scored 1-5 for each criterion. What is design %s's total score?" % designs[d],
				str(totals[d]), "Add the design's scores along its row.",
				"%d + %d + %d = %d." % [s[0], s[1], s[2], totals[d]], pic)
		2:
			ex = K.number("Scores are multiplied by each criterion's weight (×3 matters most). What is design %s's weighted total?" % designs[d],
				str(totals[d]), "Multiply each score by the weight at the top of its column, then add.",
				"%d × %d + %d × %d + %d × %d = %d." % [s[0], weights[0], s[1], weights[1], s[2], weights[2], totals[d]], pic)
		_:
			var parts: Array[String] = []
			for i in 3:
				parts.append("%s: %d" % [designs[i], totals[i]])
			ex = K.choice(rng, "Scores are multiplied by each criterion's weight. Which design has the best weighted total?",
				"design %s" % designs[best], designs.filter(func(x: String) -> bool: return x != designs[best]).map(
					func(x: Variant) -> String: return "design %s" % x),
				"Work out each design's weighted total: each score × its weight, added up. The biggest wins.",
				"Weighted totals: %s. Design %s is best." % [", ".join(PackedStringArray(parts)), designs[best]], pic)
	ex.data = {"scores": scores, "weights": weights if level > 1 else [1, 1, 1], "design": d}
	return ex


## Repeated trials: the mean of three (level 1), the odd result (level 2), the mean without the odd result (level 3).
static func trial_mean(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var what: Array = _pick(rng, [["how far a toy car rolled", "cm"], ["how long a paper helicopter took to fall",
		"tenths of a second"], ["how many coins a bridge held", "coins"]])
	var ex: Dictionary
	if level == 1:
		var base := rng.randi_range(20, 60)
		var a := base + rng.randi_range(-3, 3)
		var b := base + rng.randi_range(-3, 3)
		var c := 3 * base - a - b
		ex = K.number("A team measured %s three times: %d, %d and %d %s. What is the mean?" % [what[0], a, b, c, what[1]],
			str(base), "Add the three results, then share the total equally: divide by 3.",
			"%d + %d + %d = %d, and %d ÷ 3 = %d %s." % [a, b, c, a + b + c, a + b + c, base, what[1]],
			{"kind": "table", "rows": [["trial", "1", "2", "3"], [str(what[1]).get_slice(" ", 0), str(a), str(b), str(c)]]})
		ex.data = {"trials": [a, b, c]}
		return ex
	var base := rng.randi_range(20, 60)
	var trials: Array = []
	var n := 3 if level == 2 else 4
	var sum_good := 0
	for i in n - 1:
		var v := base + rng.randi_range(-2, 2)
		trials.append(v)
		sum_good += v
	if level == 3:   # the good three share equally
		var fix := (3 - sum_good % 3) % 3
		trials[0] = int(trials[0]) + fix
		sum_good += fix
	var odd := base + (rng.randi_range(12, 20) if rng.randf() < 0.5 else -rng.randi_range(12, 18))
	var at := rng.randi_range(0, n - 1)
	trials.insert(at, odd)
	var head: Array = ["trial"]
	var row: Array = [str(what[1]).get_slice(" ", 0)]
	for i in n:
		head.append(str(i + 1))
		row.append(str(trials[i]))
	var pic := {"kind": "table", "rows": [head, row]}
	if level == 2:
		var wrongs: Array = []
		for i in n:
			if i != at:
				wrongs.append("trial %d" % (i + 1))
		ex = K.choice(rng, "A team measured %s: %s %s. Which result is odd (an anomaly) and should be tested again?" % [what[0],
			", ".join(PackedStringArray(trials.map(func(t: Variant) -> String: return str(t)))), what[1]],
			"trial %d" % (at + 1), wrongs, "Most results are close together. Look for the one far from the rest.",
			"Trial %d (%d) is far from the others, so something went wrong: test it again." % [at + 1, odd], pic)
	else:
		ex = K.number("A team measured %s four times. One result is odd. What is the mean of the other three?" % what[0],
			str(sum_good / 3), "Leave out the result far from the rest, then add the others and divide by 3.",
			"Leave out %d. The others add up to %d, and %d ÷ 3 = %d %s." % [odd, sum_good, sum_good, sum_good / 3, what[1]], pic)
	ex.data = {"trials": trials, "odd": at}
	return ex


# --- English: read closely -------------------------------------------------------------------------------------------

## Stated or inferred (levels 1-3).
static func stated_or_inferred(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var s: Array = _pick(rng, _at_level(INFER, level, 3))
	var right := "stated in the text" if str(s[2]) == "stated" else "inferred from clues"
	var ex := K.choice(rng, "Read: %s Is this stated or inferred? \"%s\"" % [s[0], s[1]], right,
		["inferred from clues" if str(s[2]) == "stated" else "stated in the text"],
		"Stated: the text says it in its own words. Inferred: you work it out from clues and what you know.",
		("Stated: the text says it straight out." if str(s[2]) == "stated" else
			"Inferred: the text never says it, but the clues show it."))
	ex.data = {"statement": s[1], "kind": s[2]}
	return ex


## The quote that best proves an inference (levels 1-3).
static func best_evidence(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var e: Array = _pick(rng, _at_level(EVIDENCE, level, 3))
	var sentences: Array = e[0]
	var right := str(sentences[int(e[2])])
	var wrongs: Array = sentences.filter(func(x: Variant) -> bool: return str(x) != right)
	var ex := K.choice(rng, "Read: %s Which quote best shows that %s?" % [" ".join(PackedStringArray(sentences)), e[1]],
		right, wrongs, "Read each quote on its own: would it prove the point to someone who had not read the text?",
		"\"%s\" is the evidence that %s; the other sentences do not show it." % [right, e[1]])
	ex.data = {"inference": e[1]}
	return ex


## A story or an information text: one sentence (level 1), sort 4 (level 2) or 6 (level 3).
static func story_or_fact(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var t: Array = _pick(rng, TEXT_KINDS)
		var right := "a story" if str(t[1]) == "story" else "an information text"
		ex = K.choice(rng, "Which kind of text is this sentence from? %s" % t[0], right,
			["an information text" if right == "a story" else "a story"],
			"Stories have characters, feelings and made-up events; information texts give facts in the present tense.",
			"It is from %s." % right)
		ex.data = {"sentence": t[0]}
		return ex
	var groups := ["story", "information"]
	ex = _sort(rng, "Sort the sentences: from a story or from an information text?", groups,
		_spread(rng, TEXT_KINDS, groups, 4 if level == 2 else 6),
		"Look for characters, dialogue and feelings (story) or facts, numbers and general words (information).",
		"From a story: the sentences with characters, speech or feelings. From an information text: the ones that give facts about the world.")
	ex.data = {"items": ex.items}
	return ex


# --- English: write an argument --------------------------------------------------------------------------------------

## An argument's parts: claim, reason or evidence (level 1), and a counterclaim (level 2), and a rebuttal (level 3).
static func argument_part(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = ARG_NAMES.slice(0, level + 2)
	var pool: Array = ARG_PARTS.filter(func(p: Array) -> bool: return names.has(str(p[1])))
	var p: Array = _pick(rng, pool)
	var ex := K.choice(rng, "Which part of an argument is this? \"%s\"" % p[0], "the %s" % p[1],
		names.filter(func(n: Variant) -> bool: return str(n) != str(p[1])).map(func(n: Variant) -> String: return "the %s" % n),
		"Claim: what you argue. Reason: why. Evidence: facts that prove it. Counterclaim: the other side. Rebuttal: your answer to it.",
		"It is the %s: %s" % [p[1], _arg_job(str(p[1]))])
	ex.data = {"sentence": p[0]}
	return ex


static func _arg_job(part: String) -> String:
	match part:
		"claim":
			return "the writer's main point."
		"reason":
			return "it says why the claim is right."
		"evidence":
			return "a fact or number that backs up a reason."
		"counterclaim":
			return "it gives the other side's view."
	return "it answers the other side."


## Linking words for an argument (levels 1-3: the pool, by level).
static func argument_link(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = ARG_LINKS.slice(0, 3) if level == 1 else (ARG_LINKS.slice(0, 6) if level == 2 else ARG_LINKS)
	var l: Array = _pick(rng, pool)
	var ex := K.choice(rng, "Choose the linking words: %s" % l[0], str(l[1]), l[2],
		"Does the second part add, give an example, show the other side, give a result, or sum up?",
		"%s fits: %s" % [l[1], _link_job(str(l[1]))])
	ex.data = {"sentence": l[0]}
	return ex


static func _link_job(w: String) -> String:
	match w:
		"However", "On the other hand":
			return "it turns to the other side."
		"Furthermore":
			return "it adds one more reason."
		"For example":
			return "it gives an example."
		"Therefore", "As a result":
			return "it gives a result."
		"In conclusion":
			return "it sums up at the end."
	return "it puts the first reason first."


## Formal writing: the formal sentence of four (levels 1-2), or sort four sentences (level 3).
static func formal_style(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var sets := FORMAL_SETS.duplicate()
	K.shuffle(rng, sets)
	var ex: Dictionary
	if level < 3:
		var s: Array = sets[0]
		var wrongs: Array = s.slice(1, 2 + level)
		ex = K.choice(rng, "An argument for the head teacher should be formal. Which sentence is formal?", str(s[0]), wrongs,
			"Formal writing uses full words, no slang, no short forms like it's, and no exclamations.",
			"\"%s\" is formal: full, polite words and no slang." % s[0])
		ex.data = {"formal": [s[0]]}
		return ex
	var pairs: Array = [[str(sets[0][0]), "formal"], [str(sets[1][0]), "formal"], [str(sets[0][1]), "informal"],
		[str(sets[1][2]), "informal"]]
	ex = _sort(rng, "Sort the sentences: formal or informal?", ["formal", "informal"], pairs,
		"Look for slang, short forms and exclamation marks: they make writing informal.")
	ex.data = {"formal": [sets[0][0], sets[1][0]]}
	return ex


# --- English: write to inform ----------------------------------------------------------------------------------------

## The precise word for a vague one (levels 1-3).
static func precise_word(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var p: Array = _pick(rng, _at_level(PRECISE, level, 3))
	var ex := K.choice(rng, "Make it precise: which word could replace the words in capitals? %s" % p[0], str(p[1]), p[2],
		"An information text uses the exact scientific word, not an everyday one.",
		"\"%s\" is the precise word here." % p[1])
	ex.data = {"sentence": p[0]}
	return ex


## An information text's features by their jobs (levels 1-3: fewer or more choices).
static func info_feature(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var f: Array = _pick(rng, FEATURES)
	var wrongs: Array = FEATURE_NAMES.filter(func(n: String) -> bool: return n != str(f[1]))
	K.shuffle(rng, wrongs)
	var ex := K.choice(rng, "Which feature of an information text %s?" % f[0], str(f[1]), wrongs.slice(0, level + 1),
		"Picture a page: the title, subheadings, pictures and their words, the lists, the start, the end and the back.",
		"%s %s." % [_cap(str(f[1])), f[0]])
	ex.data = {"job": f[0]}
	return ex


# --- English: write a narrative --------------------------------------------------------------------------------------

## The opening that hooks the reader (levels 1-3).
static func hook_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var h: Array = _pick(rng, _at_level(HOOKS, level, 2))
	var ex := K.choice(rng, "Which opening hooks the reader best?", str(h[0]), h[1],
		"A hook makes the reader ask a question: action, speech, a mystery or a surprise, not a plain introduction.",
		"\"%s\" makes you want to know what happens next." % h[0])
	ex.data = {"hook": h[0]}
	return ex


## Pace: the version that builds tension or slows a moment (levels 1-3).
static func pace_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var p: Array = _pick(rng, _at_level(PACE, level, 3))
	var slow := str(p[0]).contains("slows")
	var ex := K.choice(rng, str(p[0]), str(p[1]), p[2],
		"Short, sharp sentences speed a story up and build tension; long, flowing ones slow it down.",
		("Long, flowing sentences full of detail slow the moment down." if slow else
			"Short, sharp sentences make the reader hold their breath."))
	ex.data = {"question": p[0], "slow": slow}
	return ex


## A vivid verb for a plain one (levels 1-3).
static func vivid_verb(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var v: Array = _pick(rng, _at_level(VIVID, level, 3))
	var ex := K.choice(rng, "Choose a vivid verb for the word in capitals: %s" % v[0], str(v[1]), v[2],
		"Pick the verb that shows exactly how it happened, so the reader can picture it.",
		"\"%s\" shows exactly how it happened." % v[1])
	ex.data = {"sentence": v[0]}
	return ex


# --- English: research and sources -----------------------------------------------------------------------------------

## A paraphrase in your own words (levels 1-3).
static func paraphrase_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var p: Array = _pick(rng, _at_level(PARAPHRASES, level, 3))
	var ex := K.choice(rng, "The source says: \"%s\" Which is the best paraphrase in your own words?" % p[0], str(p[1]), p[2],
		"A paraphrase keeps the meaning but changes the words; it does not copy, change the facts or add an opinion.",
		"\"%s\" keeps the meaning in new words. Copying is not paraphrasing, and the others change the facts or add an opinion." % p[1])
	ex.data = {"source": p[0]}
	return ex


## The most trustworthy source (levels 1-3).
static func source_trust(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var t: Array = _pick(rng, _at_level(TRUST, level, 3))
	var ex := K.choice(rng, "%s Which is best?" % t[0], str(t[1]), t[2],
		"Ask: who wrote it, are they an expert, is it up to date, and are they trying to sell something?",
		"%s: it is the most reliable." % _cap(str(t[1])))
	ex.data = {"question": t[0]}
	return ex


## A list of sources in alphabetical order of the authors' surnames: 3 (level 1), 4 (level 2), 5 with close names
## (level 3).
static func cite_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var count: int = [3, 4, 5][level - 1]
	var pool: Array = AUTHORS.duplicate()
	if level == 3:
		pool = ["Morris", "Morgan", "Moreau", "Mills", "Patel", "Park", "Nguyen", "Novak", "Silva", "Singh", "Sato"]
	K.shuffle(rng, pool)
	var names: Array = pool.slice(0, count)
	var titles := TITLES.duplicate()
	K.shuffle(rng, titles)
	var entries := {}
	for i in count:
		entries[names[i]] = "%s, %s. (%d) %s" % [names[i], "ABCDEFGHJKLMNPRST"[rng.randi_range(0, 16)],
			rng.randi_range(2008, 2025), titles[i]]
	var sorted_names := names.duplicate()
	sorted_names.sort()
	var in_order: Array = []
	for n: Variant in sorted_names:
		in_order.append(entries[n])
	var ex := K.order(rng, "Put the sources in the order of a source list: by the author's surname, A to Z.", in_order,
		"Compare the first letters of the surnames; when they match, compare the second letters, and so on.",
		"A to Z by surname: %s." % ", ".join(PackedStringArray(sorted_names.map(func(n: Variant) -> String: return str(n)))))
	ex.data = {"surnames": names}
	return ex


# --- English: discuss and present ------------------------------------------------------------------------------------

## The reply that builds on a speaker's idea (levels 1-3).
static func build_on(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b: Array = _pick(rng, _at_level(BUILD_ON, level, 3))
	var ex := K.choice(rng, "In a class discussion: %s Which reply builds on the idea?" % b[0], str(b[1]), b[2],
		"Building on an idea means listening, then adding to it, linking it or asking a useful question about it.",
		"\"%s\" takes the idea further, kindly and on topic." % b[1])
	ex.data = {"said": b[0]}
	return ex


## The chart that shows data best: a line graph, a bar chart or a pie chart (levels 1-3: more choices).
static func chart_choice(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var c: Array = _pick(rng, CHARTS)
	var wrongs: Array = CHART_NAMES.filter(func(n: String) -> bool: return n != str(c[1]))
	if level > 1:
		wrongs.append("a table of words")
	var ex := K.choice(rng, "Your talk shows %s. Which chart shows it best?" % c[0], str(c[1]), wrongs,
		"Change over time: a line graph. Comparing separate groups: a bar chart. Parts of one whole: a pie chart.",
		"%s: %s." % [_cap(str(c[1])), _chart_why(str(c[1]))])
	ex.data = {"data": c[0]}
	return ex


static func _chart_why(chart: String) -> String:
	match chart:
		"a line graph":
			return "it shows how something changes over time"
		"a bar chart":
			return "it compares separate groups side by side"
	return "it shows the parts of one whole"
