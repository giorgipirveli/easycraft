class_name G7CoreGen
extends RefCounted
## Owner #70, #73 and #111 (research §6.7): grade 7's last maths, science and English units' generators. Maths: primes,
## factor trees, the HCF and the LCM, rounding to decimal places and significant figures, estimates; speed, distance and
## time, km/h and m/s, distance-time graphs, average speed; cut axes, the right chart, pictures made bigger. Science: the
## periodic table's places, metals and non-metals, symbols; separating mixtures, chromatograms, the words of solutions;
## pH, indicators, salts; the colour a thing looks, refraction, the spectrum; the air's gases, the carbon cycle,
## combustion. English: the strongest evidence, quotes and paraphrases, history or fiction, details out of their time,
## ethos, pathos and logos, a speaker's tricks, rebuttals, faulty reasoning, signal words, precise words, points of view,
## the senses. SchoolGen "g7k.<name>", `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`,
## seeded, level 1-3, each with a hint (a strategy), a worked answer and `data` (its inputs, for
## tests/unit/test_g7_core_gen.gd). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const P := preload("res://ui/school/school_picture_g7core.gd")
const PEOPLE: Array[String] = ["Zara", "Bram", "Tilly", "Mimi", "Leo", "Ana"]

# --- Maths tables ---------------------------------------------------------------------------------------------------

const SMALL_PRIMES: Array[int] = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]
const PRIMES_TO_100: Array[int] = [53, 59, 61, 67, 71, 73, 79, 83, 89, 97]
## Odd numbers that look prime and are not.
const LOOK_PRIME: Array[int] = [21, 27, 33, 39, 49, 51, 57, 63, 69, 77, 81, 87, 91, 93]
const TREE_NUMBERS: Array[int] = [12, 18, 20, 24, 28, 30, 36, 40, 42, 44, 45, 48, 50, 54, 56, 60, 63, 66, 70, 72, 75,
	78, 80, 84, 88, 90, 96, 98, 100]
const BIG_TREES: Array[int] = [120, 126, 132, 140, 150, 168, 180, 196, 200, 210, 225, 240, 252, 270, 280, 300, 315,
	336, 360, 378, 392, 420, 450, 480, 500]
## Pairs that share primes (each under 200).
const VENN_PAIRS: Array = [[12, 18], [24, 36], [20, 30], [18, 30], [28, 42], [36, 60], [40, 60], [45, 75], [48, 72],
	[60, 84], [54, 90], [42, 70], [56, 84], [72, 120], [66, 110], [30, 105], [84, 126], [90, 150], [96, 144], [100, 140]]
const LCM_STORIES: Array = [
	["Two buses leave the square together: one every %d minutes and one every %d minutes. After how many minutes do they next leave together?", "minutes"],
	["Two lighthouse lamps flash together: one every %d seconds and one every %d seconds. After how many seconds do they next flash together?", "seconds"],
	["Zara visits the library every %d days and Bram every %d days. They met there today. In how many days will they next meet there?", "days"],
]
const HCF_STORIES: Array = [
	["%d apples and %d carrots go into identical gift chests, with nothing left over. What is the most chests you can fill?", "chests"],
	["A floor %d blocks by %d blocks is covered with equal square tiles, none cut. What is the side of the biggest tile, in blocks?", "blocks"],
	["Ribbons %d cm and %d cm long are cut into equal pieces, as long as possible, with none left over. How long is each piece, in cm?", "cm"],
]
## Numbers that round to 1 significant figure nicely, by size: their units (the rounding's step).
const ESTIMATE_BASES: Array[int] = [20, 30, 40, 50, 60, 70, 80, 90, 200, 300, 400, 500, 600, 800]

## Speeds (km/h) for whole-number journeys, and m/s that convert neatly.
const SPEEDS: Array[int] = [4, 5, 6, 8, 10, 12, 15, 20, 30, 40, 45, 50, 60, 70, 80, 90, 120]
const MPS: Array[int] = [5, 10, 15, 20, 25, 30, 35, 40]

const CHART_DATA := {"the temperature every hour of one day": "line graph",
	"a sunflower's height each week for ten weeks": "line graph",
	"a village's population every ten years": "line graph",
	"how many pupils like each kind of fruit": "bar chart", "how many goals each team scored": "bar chart",
	"the number of cars of each colour in a car park": "bar chart", "how one day's 24 hours are spent": "pie chart",
	"the share of a garden used for each crop": "pie chart",
	"how a class gets to school: walk, bike or bus": "pie chart",
	"the height and the arm span of 20 people": "scatter graph",
	"hours of sunshine and ice creams sold on 30 days": "scatter graph"}
const CHART_NAMES: Array[String] = ["line graph", "bar chart", "pie chart", "scatter graph"]
const SCALE_THINGS: Array[String] = ["bag", "coin", "tree", "house"]

# --- Science tables -------------------------------------------------------------------------------------------------

const NAMES := {"H": "hydrogen", "He": "helium", "Li": "lithium", "Be": "beryllium", "B": "boron", "C": "carbon",
	"N": "nitrogen", "O": "oxygen", "F": "fluorine", "Ne": "neon", "Na": "sodium", "Mg": "magnesium", "Al": "aluminium",
	"Si": "silicon", "P": "phosphorus", "S": "sulfur", "Cl": "chlorine", "Ar": "argon", "K": "potassium", "Ca": "calcium",
	"Fe": "iron", "Cu": "copper", "Zn": "zinc", "Ag": "silver", "Sn": "tin", "I": "iodine", "Au": "gold", "Hg": "mercury",
	"Pb": "lead", "Br": "bromine"}
const EASY_SYMBOLS: Array[String] = ["H", "He", "C", "N", "O", "Ne", "Mg", "Al", "S", "Cl", "Ar", "Ca", "Zn", "Li"]
## Symbols that come from Latin names (Na: natrium, K: kalium, Fe: ferrum, Cu: cuprum, Ag: argentum, Sn: stannum, Au:
## aurum, Hg: hydrargyrum, Pb: plumbum).
const LATIN_SYMBOLS: Array[String] = ["Na", "K", "Fe", "Cu", "Ag", "Sn", "Au", "Hg", "Pb"]
const METAL_NAMES: Array[String] = ["iron", "copper", "gold", "silver", "sodium", "magnesium", "aluminium", "zinc",
	"calcium", "potassium", "lead", "tin", "mercury", "lithium"]
const NON_METAL_NAMES: Array[String] = ["oxygen", "nitrogen", "carbon", "sulfur", "chlorine", "neon", "helium",
	"hydrogen", "iodine", "bromine", "phosphorus", "argon", "fluorine"]
const KS3_GROUPS: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "0"]

const MIXTURES := {"sand from water": "filtering", "chalk from water": "filtering", "mud from water": "filtering",
	"tea leaves from tea": "filtering", "salt from salty water": "evaporating", "sugar from sugar water": "evaporating",
	"blue crystals from their solution": "evaporating", "pure water from sea water": "distilling",
	"pure water from inky water": "distilling", "the dyes in a felt-tip ink": "chromatography",
	"the colours in a food colouring": "chromatography", "iron filings from sand": "a magnet",
	"pebbles from sand": "a sieve"}
const MAIN_METHODS: Array[String] = ["filtering", "evaporating", "distilling", "chromatography"]
const OTHER_METHODS: Array[String] = ["a magnet", "a sieve"]
const MIXTURE_WORDS := {"solute": "the substance that dissolves", "solvent": "the liquid it dissolves in",
	"solution": "a solute dissolved in a solvent", "soluble": "able to dissolve", "insoluble": "not able to dissolve",
	"residue": "the solid a filter keeps back", "filtrate": "the liquid that passes a filter",
	"distillate": "pure liquid made by distilling"}
## Inks for chromatograms: [name, [[height, colour]]].
const DYES: Array = [["red", 0.5], ["blue", 0.8], ["yellow", 0.3], ["green", 0.65], ["pink", 0.4], ["purple", 0.2]]

## Everyday substances and their pH (typical values).
const PH := {"stomach acid": 1, "lemon juice": 2, "vinegar": 3, "tomato juice": 4, "black coffee": 5,
	"pure water": 7, "salty water": 7, "sugar water": 7, "baking soda": 8, "soap": 10,
	"household ammonia": 11, "bleach": 12, "oven cleaner": 13, "drain cleaner": 14}
const PH_LABEL := {"household ammonia": "ammonia"}
const STRENGTHS: Array[String] = ["strongly acidic", "weakly acidic", "neutral", "weakly alkaline", "strongly alkaline"]
const ACIDS := {"hydrochloric acid": "chloride", "sulfuric acid": "sulfate", "nitric acid": "nitrate"}
const ALKALIS := {"sodium hydroxide": "sodium", "potassium hydroxide": "potassium", "calcium hydroxide": "calcium",
	"lithium hydroxide": "lithium"}

const COLOUR_THINGS := {"red": ["apple", "rose", "shirt", "ball"], "green": ["leaf", "frog", "shirt", "ball"],
	"blue": ["book", "shirt", "ball", "cup"], "white": ["page", "shirt", "ball", "sock"],
	"black": ["cat", "shirt", "ball", "hat"], "yellow": ["banana", "shirt", "ball", "lemon"]}
const PICTURE_THING := {"apple": "apple", "rose": "flower", "shirt": "shirt", "ball": "ball", "leaf": "leaf",
	"frog": "ball", "book": "book", "cup": "ball", "page": "book", "sock": "shirt", "cat": "ball", "hat": "ball",
	"banana": "ball", "lemon": "ball"}
const SEEN_CHOICES: Array[String] = ["red", "green", "blue", "black", "white", "yellow"]
## [from, into, the index of the second (1 air), which way it bends].
const CROSSINGS: Array = [["air", "glass", 1.5, "towards the normal"], ["air", "water", 1.33, "towards the normal"],
	["glass", "air", 1.0, "away from the normal"], ["water", "air", 1.0, "away from the normal"]]
const BENDS: Array[String] = ["towards the normal", "away from the normal", "it does not bend"]

const GASES := {"nitrogen": 78, "oxygen": 21, "argon": 1}
const PROCESS_CO2 := {"photosynthesis": false, "respiration": true, "burning coal": true, "a forest growing": false,
	"decomposers breaking down dead leaves": true, "burning petrol in a car": true, "burning wood": true,
	"a volcano erupting": true, "seaweed growing in the sea": false, "plankton making food from sunlight": false}
const SORT_CO2: Array[String] = ["adds carbon dioxide", "takes it from the air"]
const FUELS := {"methane (natural gas)": "carbon dioxide and water", "propane": "carbon dioxide and water",
	"candle wax": "carbon dioxide and water", "coal (carbon)": "carbon dioxide", "hydrogen": "only water"}

# --- English tables -------------------------------------------------------------------------------------------------

## [claim, [quotes], the strongest's index, level].
const EVIDENCE: Array = [
	["Sam is nervous.", ["His hands shook as he knocked.", "The door was painted blue.", "It was a Tuesday morning."], 0, 1],
	["The village is poor.", ["Most roofs were patched with old sacks.", "A river ran past the mill.",
		"The church bell rang at noon."], 0, 1],
	["Leo is generous.", ["Leo gave his last coin to the old woman.", "Leo has a red coat.",
		"Leo walked to the market."], 0, 1],
	["The house is empty.", ["Weeds grew through the cracked doorstep.", "The house has two floors.",
		"It stands near a road."], 0, 1],
	["Mira is brave.", ["Knees shaking, she stepped onto the bridge.", "She smiled at her friend.",
		"She wore strong boots."], 0, 2],
	["Tom feels left out.", ["Tom ate alone, wishing someone would join him.", "Tom liked apples.",
		"Tom sat near the window."], 0, 2],
	["The king is greedy.", ["He kept the harvest; his people went hungry.", "He wore a golden crown.",
		"He lived in a tall castle."], 0, 2],
	["Ana loves the sea.", ["\"I'm happiest when the waves roar,\" said Ana.", "Ana lives in a town.",
		"The sea is salty."], 0, 2],
	["Jun changes during the story.", ["Jun hid at first, but spoke up at the end.",
		"Jun has a brother.", "Jun lives by a lake."], 0, 3],
	["The storm frightens the crew.", ["The sailors gripped the ropes, and nobody spoke.", "Storms are made of clouds.",
		"The ship had three masts."], 0, 3],
	["The town trusts the doctor.", ["When anyone fell ill, they sent for Dr Lane.",
		"Dr Lane had a black bag.", "The town had a doctor."], 0, 3],
	["Kit is clever.", ["Kit mended the radio with a hairpin and a spoon.", "Kit was the youngest.",
		"Kit liked radios."], 0, 3],
]
const QUOTES: Array[String] = ["She writes, \"The wind howled like a wolf.\"", "\"I will not give up,\" Ana said.",
	"The text says the cave was \"darker than night\".", "Sam says, \"We leave at dawn.\"",
	"The poem calls the sea \"a grey, restless giant\"."]
const PARAPHRASES: Array[String] = ["She says the wind was very loud.", "Ana says she will keep trying.",
	"The text explains that the cave was very dark.", "Sam says they will set off early.",
	"The poem says the sea is huge and never still."]
## [a quote, its best paraphrase, two that change its meaning].
const PARAPHRASE_PICKS: Array = [
	["\"The rain hammered on the roof all night.\"", "It rained heavily all night.", ["It rained a little at dawn.",
		"Someone hammered the roof."]],
	["\"Nobody in the village had ever seen the sea.\"", "No villager had seen the sea.", ["The village was by the sea.",
		"Some villagers had seen the sea."]],
	["\"Leo's smile vanished when he saw the empty box.\"", "Leo stopped smiling when the box was empty.",
		["Leo smiled at the empty box.", "Leo's box vanished."]],
	["\"The old bridge creaked under every step.\"", "The old bridge made noises as people crossed.",
		["The bridge was new and silent.", "The bridge broke at the first step."]],
]

const HISTORY_SENTENCES: Array[String] = ["Caxton set up a press in Westminster in 1476.",
	"Caxton printed Chaucer's Canterbury Tales.", "By 1500, presses had printed millions of books.",
	"In 1610 Galileo saw four moons round Jupiter.", "Work on the Taj Mahal began in 1632.",
	"Caxton's own prologues are a source today."]
const FICTION_SENTENCES: Array[String] = ["Ned's fingers were black with ink.",
	"\"Faster, boy!\" Master Caxton snapped.", "Ned dreamed of printing his own story.",
	"Lucia held the lamp while Galileo gazed up.", "The stone cutter's hands ached, but he smiled.",
	"Ned hid the spoiled page under his shirt."]
## [setting, [details that belong], [details from a later time], level].
const ERAS: Array = [
	["London in 1476", ["a candle", "a horse and cart", "a wooden printing press", "a quill pen"], ["a bicycle",
		"an electric light", "a train ticket", "a telephone"], 1],
	["Padua in Italy, 1610", ["a telescope", "a quill pen", "candles", "a horse"], ["an aeroplane", "a light bulb",
		"a camera", "a radio"], 1],
	["Edo Japan in 1700", ["a kimono", "a wooden print block", "rice paper", "a paper lantern"], ["a steam train",
		"a camera", "a car", "electric street lights"], 2],
	["Mughal India in 1632", ["elephants", "white marble", "a garden with water channels", "silk"], ["a motor car",
		"an electric fan", "a telephone", "a plastic bottle"], 2],
	["England in 1476", ["bread", "woollen cloth", "a printed book", "a church bell"], ["potatoes for dinner",
		"a cup of tea", "a telescope", "a tomato salad"], 3],
	["Europe in 1450", ["a hand-copied book", "a castle", "a wooden ship", "a market"], ["a printed newspaper",
		"chocolate to drink", "a pocket telescope", "a potato field"], 3],
]

const APPEALS := {"As a doctor for twenty years, I have seen how sleep helps healing.": "ethos",
	"I have run this library for ten years, so I know what readers want.": "ethos",
	"Our team of scientists tested every sample twice.": "ethos",
	"Imagine a puppy shivering in the cold with nowhere to go.": "pathos",
	"Think how proud you will feel when the new park opens.": "pathos",
	"Every lost pet leaves a family heartbroken.": "pathos",
	"The new path would cut the walk to school from 20 minutes to 8.": "logos",
	"The repair costs 300 gold; a new roof costs 3,000 gold.": "logos",
	"Three surveys found that most pupils wanted a longer lunch.": "logos"}
const APPEAL_NAMES: Array[String] = ["ethos", "pathos", "logos"]
const APPEAL_JOBS := {"ethos": "trust in the speaker", "pathos": "the listeners' feelings", "logos": "reasons and facts"}
const TRICKS := {"This disastrous, dangerous plan must be stopped.": "loaded words",
	"Everyone in the whole world agrees with me.": "exaggeration",
	"Don't listen to Sam: he can't even tie his laces.": "attacking the person",
	"My cousin ate carrots and never caught a cold, so carrots stop colds.": "one story as proof",
	"This terrible, shameful idea will ruin our lovely town.": "loaded words",
	"Nobody, not one single person, likes the new timetable.": "exaggeration",
	"Why trust Mo's plan? He was late to school last week.": "attacking the person",
	"My gran walked every day and lived to 100, so walking makes everyone live to 100.": "one story as proof"}
const TRICK_NAMES: Array[String] = ["loaded words", "exaggeration", "attacking the person", "one story as proof"]
const FAIR_POINTS: Array[String] = ["200 pupils were asked; 70% want a later start.",
	"The report shows two cracks in the bridge.", "The library lends 400 books a week now."]

## [the other side's view, the best rebuttal, two weak answers].
const REBUTTALS: Array = [
	["Some say a school garden takes too much time.", "But a garden club could share the work.",
		["That is a silly thing to say.", "Gardens are green and pretty."]],
	["Some argue that a new bridge costs too much.", "Yet the long road round costs more each year.",
		["Bridges are big.", "People who say that are wrong."]],
	["Some think a later start would make pupils idle.", "But pupils who sleep enough often learn better.",
		["Idle is an unkind word.", "Mornings are dark in winter."]],
	["Some say the village does not need a library.", "But many families have no books to borrow.",
		["Libraries are quiet.", "I like libraries, so they are needed."]],
	["Some argue that trees in the square would drop too many leaves.",
		"Yet fallen leaves can become compost.", ["Leaves are brown.", "Trees are tall."]],
]
const FLAWS := {"Everyone is buying these trainers, so they must be the best.": "following the crowd",
	"I met two rude tourists, so all tourists are rude.": "too few examples",
	"Either we ban phones completely or pupils will never learn.": "a false choice",
	"Her plan is silly because she is only twelve.": "attacking the person",
	"Lots of people believe it, so it must be true.": "following the crowd",
	"One apple in the box was bad, so the whole farm is bad.": "too few examples",
	"We either build the bridge today or the village dies.": "a false choice",
	"His idea is wrong: he cannot even spell.": "attacking the person"}
const FLAW_NAMES: Array[String] = ["following the crowd", "too few examples", "a false choice", "attacking the person"]
const SOUND_REASONS: Array[String] = ["The bridge is closed for repairs, so the bus must take the long road.",
	"The plants in the dark cupboard died, so these plants need light.",
	"The shop shuts at five, so we must get there before five."]

## [a sentence with a gap, the signal word, its kind, two wrong ones].
const SIGNALS: Array = [
	["Frogs have smooth skin, ___ toads have dry, bumpy skin.", "whereas", "compare", ["because", "therefore"]],
	["Both frogs and toads lay eggs in water. ___, both are amphibians.", "Similarly", "compare", ["As a result", "Because"]],
	["The desert is dry. The rainforest, ___, gets rain almost every day.", "however", "compare", ["so", "because"]],
	["___ a bat, a bird has feathers.", "Unlike", "compare", ["Because of", "Therefore"]],
	["Heavy rain fell for days; ___, the river burst its banks.", "as a result", "cause", ["similarly", "unlike"]],
	["The ice melted ___ the sun warmed it.", "because", "cause", ["whereas", "likewise"]],
	["The forest was cut down, ___ the soil washed away.", "so", "cause", ["whereas", "similarly"]],
	["Plants need light. ___, a plant in a dark cupboard grows pale and weak.", "Therefore", "cause",
		["Similarly", "Unlike"]],
]
const COMPARE_WORDS: Array[String] = ["whereas", "similarly", "however", "unlike", "likewise", "in contrast"]
const CAUSE_WORDS: Array[String] = ["because", "as a result", "therefore", "so", "consequently", "this leads to"]
## [vague, precise, a wrong precise one].
const PRECISE: Array = [
	["a lot of rain", "50 mm of rain in a day", "some rain at some point"],
	["animals that live in water and on land", "amphibians", "creatures"],
	["got bigger", "expanded", "changed"],
	["a long time ago", "in 1476", "once upon a time"],
	["a big wave", "a 3-metre wave", "a nice wave"],
	["really cold", "−20 °C", "chilly-ish"],
	["went down", "fell by 20%", "did a thing"],
	["the thing that pumps blood", "the heart", "an organ thing"],
	["lots of people", "4,000 people", "loads of folk"],
]

const POV_SENTENCES := {"I pushed the door open and my heart thumped.": "first person",
	"We ran to the harbour before the storm broke.": "first person",
	"I knew at once that the map was wrong.": "first person",
	"Zara stared at the map; she was sure they were lost.": "third person limited",
	"Bram climbed the ladder, wondering if anyone had seen him.": "third person limited",
	"Tilly smiled, though she was secretly terrified of the dark.": "third person limited",
	"Zara thought they were lost, while Bram knew the way and Tilly worried about rain.": "third person omniscient",
	"Every villager hoped for rain, but none of them knew the river was already rising.": "third person omniscient",
	"Leo felt proud; across the room, his sister felt forgotten.": "third person omniscient"}
const POV_NAMES: Array[String] = ["first person", "third person limited", "third person omniscient"]
const POV_MODE := {"first person": "first", "third person limited": "third_limited",
	"third person omniscient": "omniscient"}
const SENSES := {"the sky glowed orange": "sight", "the floorboards creaked": "sound",
	"the sharp smell of smoke": "smell", "the salty sea on her lips": "taste",
	"rough bark scratched his palms": "touch", "a bell clanged in the tower": "sound",
	"the sweet scent of baking bread": "smell", "sour lemon made her wince": "taste",
	"icy water stung his fingers": "touch", "a red kite circled overhead": "sight"}
const SENSE_NAMES: Array[String] = ["sight", "sound", "smell", "taste", "touch"]


# --- Maths: primes, the HCF and the LCM, rounding, estimates --------------------------------------------------------

## Which number is prime (level 1: under 50; level 2: under 100, with odd numbers that look prime); sort them (level 3).
static func prime_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 3:
		var items: Array = []
		var primes: Array = (SMALL_PRIMES + PRIMES_TO_100).duplicate()
		var look: Array = LOOK_PRIME.duplicate()
		K.shuffle(rng, primes)
		K.shuffle(rng, look)
		items = [primes[0], primes[1], primes[2], look[0], look[1], look[2]]
		var shown: Array = items.map(func(n: Variant) -> String: return str(n))
		K.shuffle(rng, shown)
		var primes_said: Array[String] = []
		var others_said: Array[String] = []
		var answer: Array = []
		for t: Variant in shown:
			if P.is_prime(int(t)):
				primes_said.append(str(t))
				answer.append(0)
			else:
				others_said.append(_factor_text(int(t)))
				answer.append(1)
		var ex := _sort_ex("Sort the numbers: prime or not prime?", ["prime", "not prime"], shown, answer,
			"Try dividing by 2, 3, 5 and 7: a number under 100 with none of them as a factor is prime.",
			"Prime: %s. Not prime: %s." % [", ".join(primes_said), ", ".join(others_said)])
		ex.data = {"items": shown}
		return ex
	var right: int = _pick(rng, SMALL_PRIMES if level == 1 else PRIMES_TO_100)
	var wrongs: Array = []
	var pool: Array = [4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 22, 25, 26, 35] if level == 1 else LOOK_PRIME
	pool = pool.duplicate()
	K.shuffle(rng, pool)
	wrongs = pool.slice(0, 3)
	var ex := K.choice(rng, "Which number is prime?", str(right), wrongs.map(func(n: Variant) -> String: return str(n)),
		"A prime has exactly two factors, 1 and itself: try dividing each number by 2, 3, 5 and 7.",
		"%d is prime: only 1 and %d divide it. %s." % [right, right, ", ".join(PackedStringArray(wrongs.map(
			func(n: Variant) -> String: return _factor_text(int(n)))))])
	ex.data = {"right": right, "wrongs": wrongs}
	return ex


## A factor tree's hidden prime (level 1), a number as a product of primes (level 2), a product of primes worked out
## (level 3).
static func factorise(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var n: int = _pick(rng, TREE_NUMBERS)
		var ps := P.prime_factors(n)
		var hide := rng.randi_range(0, ps.size() - 1)
		ex = K.number("This factor tree splits %d into primes. What is the missing prime?" % n, ps[hide],
			"Multiply the primes you can see, then divide %d by that." % n,
			"%d = %s, so the missing prime is %d." % [n, " × ".join(PackedStringArray(ps.map(func(x: int) -> String:
				return str(x)))), ps[hide]], {"kind": "factor_tree", "n": n, "hide": hide})
		ex.data = {"n": n, "hide": hide}
		return ex
	if level == 2:
		var n: int = _pick(rng, TREE_NUMBERS + BIG_TREES.slice(0, 10))
		var right := P.power_form(n)
		var wrongs := _wrong_forms(rng, n)
		ex = K.choice(rng, "Which is %d written as a product of primes?" % n, right, wrongs,
			"Split %d with a factor tree, then check every number is prime and they multiply back to %d." % [n, n],
			"%d = %s: every factor is prime, and they multiply to %d." % [n, right, n],
			{"kind": "factor_tree", "n": n})
		ex.data = {"n": n}
		return ex
	var m: int = _pick(rng, BIG_TREES)
	var form := P.power_form(m)
	ex = K.number("What number is %s?" % form, m, "Work out each power first, then multiply them together.",
		"%s = %s = %d." % [form, " × ".join(PackedStringArray(P.prime_factors(m).map(func(x: int) -> String:
			return str(x)))), m])
	ex.data = {"n": m}
	return ex


## "21 = 3 × 7".
static func _factor_text(n: int) -> String:
	return "%d = %s" % [n, _times(Array(P.prime_factors(n)))]


## Wrong products of primes for n: a non-prime factor in it, one prime too many, one too few.
static func _wrong_forms(rng: RandomNumberGenerator, n: int) -> Array:
	var ps := P.prime_factors(n)
	var out: Array = []
	if ps.size() >= 2:
		var merged: Array = [ps[0] * ps[1]] + ps.slice(2)
		out.append(" × ".join(PackedStringArray(merged.map(func(x: Variant) -> String: return str(x)))))
	out.append(P.power_form(n * 2) if n * 2 < 100000 else "2 × " + P.power_form(n))
	var fewer: Array = ps.slice(1)
	out.append(" × ".join(PackedStringArray(fewer.map(func(x: Variant) -> String: return str(x)))) if fewer.size() > 1
		else str(n) + " × 1")
	var right := P.power_form(n)
	var keep: Array = []
	for w: Variant in out:
		if str(w) != right and not keep.has(w):
			keep.append(w)
	K.shuffle(rng, keep)
	return keep


## The HCF (level 1) or the LCM (level 2) from a Venn diagram of primes; a story that needs one of them (level 3).
static func hcf_lcm(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level <= 2:
		var pair: Array = _pick(rng, VENN_PAIRS)
		var a := int(pair[0])
		var b := int(pair[1])
		var parts := P.venn_parts(a, b)
		var shared: Array = parts[1]
		var all: Array = (parts[0] as Array) + shared + (parts[2] as Array)
		all.sort()
		if level == 1:
			ex = K.number("The Venn diagram shows the primes of %d and %d. What is their HCF?" % [a, b], P.hcf(a, b),
				"The HCF multiplies only the primes in the middle, the ones both numbers share.",
				"HCF = %s = %d." % [_times(shared), P.hcf(a, b)], {"kind": "prime_venn", "a": a, "b": b})
		else:
			ex = K.number("The Venn diagram shows the primes of %d and %d. What is their LCM?" % [a, b], P.lcm(a, b),
				"The LCM multiplies every prime in the diagram once: both sides and the middle.",
				"LCM = %s = %d." % [_times(all), P.lcm(a, b)], {"kind": "prime_venn", "a": a, "b": b})
		ex.data = {"a": a, "b": b, "ask": "hcf" if level == 1 else "lcm"}
		return ex
	var want_lcm := rng.randi() % 2 == 0
	if want_lcm:
		var pairs: Array = [[6, 8], [6, 9], [8, 12], [9, 12], [10, 15], [12, 18], [12, 15], [15, 20], [8, 10], [6, 10]]
		var pr: Array = _pick(rng, pairs)
		var story: Array = _pick(rng, LCM_STORIES)
		var l := P.lcm(int(pr[0]), int(pr[1]))
		ex = K.number(str(story[0]) % [pr[0], pr[1]], l,
			"List the multiples of each number, or use their primes: you want the first number in both lists (the LCM).",
			"The LCM of %d and %d is %d: %d %s." % [pr[0], pr[1], l, l, story[1]])
		ex.data = {"a": pr[0], "b": pr[1], "ask": "lcm"}
		return ex
	var hpairs: Array = [[24, 36], [18, 30], [20, 32], [36, 48], [28, 42], [30, 45], [40, 56], [48, 60], [27, 45]]
	var hp: Array = _pick(rng, hpairs)
	var hstory: Array = _pick(rng, HCF_STORIES)
	var h := P.hcf(int(hp[0]), int(hp[1]))
	ex = K.number(str(hstory[0]) % [hp[0], hp[1]], h,
		"Find the biggest number that divides both exactly: the HCF.",
		"The HCF of %d and %d is %d: %d %s." % [hp[0], hp[1], h, h, hstory[1]])
	ex.data = {"a": hp[0], "b": hp[1], "ask": "hcf"}
	return ex


static func _times(nums: Array) -> String:
	if nums.is_empty():
		return "1"
	return " × ".join(PackedStringArray(nums.map(func(x: Variant) -> String: return str(x))))


## Round to 1 decimal place (level 1), 2 (level 2) or 3 (level 3), sometimes carrying into the next place.
static func round_dp(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var places := level
	var extra := rng.randi_range(1, 2)
	var digits := places + extra
	var m := rng.randi_range(int(pow(10, digits)), int(pow(10, digits + 1)) - 1)
	if rng.randi() % 4 == 0:
		m = (m / int(pow(10, extra + 1))) * int(pow(10, extra + 1)) + int(pow(10, extra + 1)) - rng.randi_range(1, 4)
	var x := _dec(m, digits)
	var q := _round_half_up(m, extra)
	var answer := _dec(q, places)
	var ex := K.number("Round %s to %d decimal place%s." % [x, places, "" if places == 1 else "s"], answer,
		"Count %d place%s after the point, then look at the next digit: 5 or more rounds up." % [places,
			"" if places == 1 else "s"],
		"The digit after the %s decimal place is %s, so %s rounds %s to %s." % [["first", "second", "third"][places - 1],
			x.substr(x.find(".") + places + 1, 1), x, "up" if int(x.substr(x.find(".") + places + 1, 1)) >= 5 else "down",
			answer])
	ex.data = {"m": m, "digits": digits, "places": places}
	return ex


## Round to significant figures: whole numbers to 1 (level 1); to 2, whole or decimal (level 2); small decimals to 2
## or 3 (level 3).
static func round_sf(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var m: int
	var e: int
	var sf: int
	match level:
		1:
			m = rng.randi_range(1100, 98999)
			e = 0
			sf = 1
		2:
			if rng.randi() % 2 == 0:
				m = rng.randi_range(10100, 99899)
				e = 0
			else:
				m = rng.randi_range(1001, 9989)
				e = -3
			sf = 2
		_:
			m = rng.randi_range(1001, 9989)
			e = -rng.randi_range(5, 6)
			sf = rng.randi_range(2, 3)
	var d := str(m).length()
	var q := _round_half_up(m, d - sf)
	var shift := e + d - sf
	var answer := _scaled(q, shift)
	var x := _scaled(m, e)
	var ex := K.number("Round %s to %d significant figure%s." % [_shown(x), sf, "" if sf == 1 else "s"], answer,
		"Count from the first digit that is not 0. Look at the digit after the last one you keep: 5 or more rounds up.",
		"To %d significant figure%s, %s rounds %s to %s: the next digit is %s. Zeros keep its size." % [sf,
			"" if sf == 1 else "s", _shown(x), "up" if int(str(m)[sf]) >= 5 else "down", _shown(answer), str(m)[sf]])
	ex.data = {"m": m, "e": e, "sf": sf}
	return ex


## A whole number with thousands commas, or a decimal as it is.
static func _shown(t: String) -> String:
	if t.contains("."):
		return t
	return K.fmt(int(t))


## m ÷ 10^k rounded half up to a whole number.
static func _round_half_up(m: int, k: int) -> int:
	if k <= 0:
		return m
	var p := int(pow(10, k))
	return (m + p / 2) / p


## m × 10^e as text (a whole number, or a decimal with -e places).
static func _scaled(m: int, e: int) -> String:
	if e >= 0:
		return str(m * int(pow(10, e)))
	return _dec(m, -e)


## m ÷ 10^k as a decimal with exactly k places.
static func _dec(m: int, k: int) -> String:
	if k <= 0:
		return str(m)
	var s := str(m)
	while s.length() <= k:
		s = "0" + s
	return s.substr(0, s.length() - k) + "." + s.substr(s.length() - k)


## Estimate by rounding to 1 significant figure: a product (level 1), a quotient (level 2), a calculator's answer
## checked (level 3).
static func estimate_calc(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var ra: int = _pick(rng, [20, 30, 40, 50, 60, 70, 80, 90])
		var rb: int = _pick(rng, [20, 30, 40, 50, 6, 7, 8, 9])
		var a := _near_tenths(rng, ra)
		var b := _near_tenths(rng, rb)
		var est := ra * rb
		ex = K.choice(rng, "Estimate %s × %s by rounding each number to 1 significant figure." % [_dec(a, 1), _dec(b, 1)],
			K.fmt(est), [K.fmt(est * 10), K.fmt(est / 10), K.fmt(est * 2)],
			"Round each number to its first digit with zeros after it, then multiply the easy numbers.",
			"%s is about %d and %s is about %d, so the answer is about %d × %d = %s." % [_dec(a, 1), ra, _dec(b, 1), rb,
				ra, rb, K.fmt(est)])
		ex.data = {"a": a, "b": b, "op": "×", "estimate": est}
		return ex
	if level == 2:
		var rb2: int = _pick(rng, [20, 30, 40, 50, 60, 70, 80, 90])
		var q: int = _pick(rng, [2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30])
		var ra2 := rb2 * q
		while str(ra2).trim_suffix("0").trim_suffix("0").trim_suffix("0").length() > 1:
			q = _pick(rng, [2, 3, 4, 5, 10, 20, 30])
			ra2 = rb2 * q
		var a2 := _near_tenths(rng, ra2)
		var b2 := _near_tenths(rng, rb2)
		ex = K.number("Estimate %s ÷ %s by rounding each number to 1 significant figure." % [_dec(a2, 1), _dec(b2, 1)], q,
			"Round both numbers to 1 significant figure first, then do the easy division.",
			"%s is about %s and %s is about %d, so the answer is about %s ÷ %d = %d." % [_dec(a2, 1), K.fmt(ra2),
				_dec(b2, 1), rb2, K.fmt(ra2), rb2, q])
		ex.data = {"a": a2, "b": b2, "op": "÷", "estimate": q}
		return ex
	var ra3: int = _pick(rng, [20, 30, 40, 50, 60, 70, 80, 90])
	var rb3: int = _pick(rng, [3, 4, 5, 6, 7, 8, 9, 20, 30, 40])
	var a3 := _near_tenths(rng, ra3)
	var b3 := _near_tenths(rng, rb3)
	var exact := a3 * b3
	var slip: int = _pick(rng, [1, 10, -10])
	var shown := _dec(exact * 10 if slip == 10 else (exact / 10 if slip == -10 else exact), 2)
	var est := ra3 * rb3
	var right := "Yes: it is close to %s" % K.fmt(est) if slip == 1 else "No: it should be about %s" % K.fmt(est)
	var wrongs: Array = ["No: it should be about %s" % K.fmt(est * 10), "Yes: it is close to %s" % K.fmt(est / 10)]
	if slip != 1:
		wrongs = ["Yes: it is close to %s" % K.fmt(est), "No: it should be about %s" % K.fmt(est * 10 if slip == -10
			else est / 10)]
	ex = K.choice(rng, "A calculator says %s × %s = %s. Is that about right?" % [_dec(a3, 1), _dec(b3, 1), shown], right,
		wrongs, "Round each number to 1 significant figure and multiply: is the calculator's answer near that?",
		"%d × %d = %s, and the true answer is %s, so %s." % [ra3, rb3, K.fmt(est), _dec(exact, 2),
			"the calculator is right" if slip == 1 else "a decimal point slipped"])
	ex.data = {"a": a3, "b": b3, "shown": shown, "estimate": est}
	return ex


## A number in tenths that rounds to `r` at 1 significant figure (r's first digit and zeros), not r itself.
static func _near_tenths(rng: RandomNumberGenerator, r: int) -> int:
	var unit := int(pow(10, str(r).length() - 1))
	for _i in 40:
		var t := r * 10 + rng.randi_range(-unit * 4, unit * 4)
		if t != r * 10 and t > 0 and _first_sf(t) == r * 10:
			return t
	return r * 10 + 1


## A number in tenths rounded to 1 significant figure (in tenths).
static func _first_sf(t: int) -> int:
	var d := str(t).length()
	var p := int(pow(10, d - 1))
	return ((t + p / 2) / p) * p


# --- Maths: speed, distance and time ---------------------------------------------------------------------------------

## Speed, distance or time: speed in whole hours (level 1); distance or time with minutes (level 2); speed from minutes
## (level 3).
static func speed_calc(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var who: String = _pick(rng, PEOPLE)
	if level == 1:
		var s: int = _pick(rng, SPEEDS)
		var t := rng.randi_range(2, 5)
		ex = K.number("%s travels %d km in %d hours. What is the average speed in km/h?" % [who, s * t, t], s,
			"Speed = distance ÷ time: cover speed on the triangle.", "%d ÷ %d = %d km/h." % [s * t, t, s],
			{"kind": "speed_triangle", "cover": "speed"})
		ex.data = {"ask": "speed", "d": s * t, "t_min": t * 60}
		return ex
	if level == 2:
		var opts: Array = []
		for s2: int in [12, 20, 24, 30, 36, 40, 48, 60, 80, 90]:
			for tm: int in [15, 20, 30, 40, 45, 90]:
				if s2 * tm % 60 == 0:
					opts.append([s2, tm])
		var o: Array = _pick(rng, opts)
		var dist := int(o[0]) * int(o[1]) / 60
		if rng.randi() % 2 == 0:
			ex = K.number("%s rides at %d km/h for %d minutes. How far does %s go, in km?" % [who, o[0], o[1], who], dist,
				"Turn the minutes into hours first (÷ 60), then distance = speed × time.",
				"%d minutes = %s hours; %d × %s = %d km." % [o[1], _hours(int(o[1])), o[0], _hours(int(o[1])), dist],
				{"kind": "speed_triangle", "cover": "distance"})
			ex.data = {"ask": "distance", "s": o[0], "t_min": o[1]}
		else:
			ex = K.number("%s travels %d km at %d km/h. How many minutes does it take?" % [who, dist, o[0]], o[1],
				"Time = distance ÷ speed gives hours; then × 60 for minutes.",
				"%d ÷ %d = %s hours = %d minutes." % [dist, o[0], _hours(int(o[1])), o[1]],
				{"kind": "speed_triangle", "cover": "time"})
			ex.data = {"ask": "time", "d": dist, "s": o[0]}
		return ex
	var opts3: Array = []
	for d3: int in [3, 4, 5, 6, 8, 9, 10, 12, 15]:
		for tm3: int in [12, 15, 18, 20, 24, 36, 40, 45]:
			if d3 * 60 % tm3 == 0 and d3 * 60 / tm3 <= 40 and d3 * 60 / tm3 >= 6:
				opts3.append([d3, tm3])
	var o3: Array = _pick(rng, opts3)
	var s3 := int(o3[0]) * 60 / int(o3[1])
	ex = K.number("%s runs %d km in %d minutes. What is the average speed in km/h?" % [who, o3[0], o3[1]], s3,
		"Find how far in 1 minute, then multiply by 60 for an hour.",
		"%d km in %d minutes: %d ÷ %d × 60 = %d km/h." % [o3[0], o3[1], o3[0], o3[1], s3])
	ex.data = {"ask": "speed", "d": o3[0], "t_min": o3[1]}
	return ex


## Minutes as hours: 30 -> "0.5", 45 -> "0.75", 20 -> "1/3".
static func _hours(minutes: int) -> String:
	if minutes % 15 == 0:
		var q := minutes / 15
		return _dec(q * 25, 2).trim_suffix("0").trim_suffix(".0") if q % 4 != 0 else str(q / 4)
	var g := 60
	var n := minutes
	var a := n
	var b := g
	while b != 0:
		var t := a % b
		a = b
		b = t
	return "%d/%d" % [n / a, g / a]


## m/s to km/h (level 1), km/h to m/s (level 2), which is faster (level 3).
static func speed_convert(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var v: int = _pick(rng, MPS)
		var kmh := v * 36 / 10
		ex = K.number("Change %d m/s to km/h." % v, kmh, "From m/s to km/h, multiply by 3.6.",
			"%d × 3.6 = %d km/h." % [v, kmh])
		ex.data = {"mps": v}
		return ex
	if level == 2:
		var v2: int = _pick(rng, MPS)
		var kmh2 := v2 * 36 / 10
		ex = K.number("Change %d km/h to m/s." % kmh2, v2, "From km/h to m/s, divide by 3.6.",
			"%d ÷ 3.6 = %d m/s." % [kmh2, v2])
		ex.data = {"kmh": kmh2}
		return ex
	var v3: int = _pick(rng, MPS)
	var k3: int = v3 * 36 / 10 + int(_pick(rng, [-9, -6, -4, 4, 6, 9]))
	var faster_mps := v3 * 36 / 10 > k3
	var right := "%d m/s" % v3 if faster_mps else "%d km/h" % k3
	ex = K.choice(rng, "Which is faster: %d m/s or %d km/h?" % [v3, k3], right, ["%d km/h" % k3 if faster_mps else
		"%d m/s" % v3, "They are the same."], "Change the m/s to km/h (× 3.6), then compare the same units.",
		"%d m/s = %d km/h, which is %s than %d km/h." % [v3, v3 * 36 / 10, "faster" if faster_mps else "slower", k3])
	ex.data = {"mps": v3, "kmh": k3}
	return ex


## A distance-time graph: a stop or a distance read (level 1), a leg's speed (level 2), the whole trip's average speed
## or the faster leg (level 3).
static func dt_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var trip := _trip(rng, level == 3)
	var pts: Array = trip.points
	var pic := {"kind": "distance_time", "points": pts, "t_to": trip.t_to, "t_step": trip.t_step, "d_to": trip.d_to,
		"d_step": trip.d_step, "legs": true}
	var who: String = _pick(rng, PEOPLE)
	var ex: Dictionary
	if level == 1:
		if rng.randi() % 2 == 0:
			var stop := int(pts[2][0]) - int(pts[1][0])
			ex = K.number("The graph shows %s's bike ride. For how many minutes did %s stop?" % [who, who], stop,
				"A stop is a flat part of the graph: read the times at both ends of it.",
				"Leg B is flat from %d to %d minutes: %d − %d = %d minutes." % [pts[1][0], pts[2][0], pts[2][0], pts[1][0],
					stop], pic)
			ex.data = {"ask": "stop", "points": pts}
		else:
			ex = K.number("The graph shows %s's bike ride. How far had %s gone after %d minutes, in km?" % [who, who,
				pts[1][0]], pts[1][1], "Go up from the time to the line, then across to the distance axis.",
				"After %d minutes the line is at %d km." % [pts[1][0], pts[1][1]], pic)
			ex.data = {"ask": "distance", "points": pts, "t": pts[1][0]}
		return ex
	if level == 2:
		var leg := 0 if rng.randi() % 2 == 0 else 2
		pic.mark = leg
		var dd := int(pts[leg + 1][1]) - int(pts[leg][1])
		var dt := int(pts[leg + 1][0]) - int(pts[leg][0])
		var s := dd * 60 / dt
		ex = K.number("The graph shows %s's bike ride. What was the speed on leg %s, in km/h?" % [who,
			P.LEG_LETTERS[leg]], s, "Read the distance and the time for that leg, then speed = distance ÷ time in hours.",
			"Leg %s: %d km in %d minutes = %d km/h (%d ÷ %d × 60)." % [P.LEG_LETTERS[leg], dd, dt, s, dd, dt], pic)
		ex.data = {"ask": "leg", "leg": leg, "points": pts}
		return ex
	var total_d := int(pts[3][1])
	var total_t := int(pts[3][0])
	if total_d * 60 % total_t == 0:
		var avg := total_d * 60 / total_t
		ex = K.number("The graph shows %s's whole bike ride, stop included. What was the average speed, in km/h?" % who,
			avg, "Average speed = the total distance ÷ the total time, stops included.",
			"%d km in %d minutes: %d ÷ %d × 60 = %d km/h." % [total_d, total_t, total_d, total_t, avg], pic)
		ex.data = {"ask": "average", "points": pts}
		return ex
	var sa := (int(pts[1][1]) - int(pts[0][1])) * 60 / (int(pts[1][0]) - int(pts[0][0]))
	var sc := (int(pts[3][1]) - int(pts[2][1])) * 60 / (int(pts[3][0]) - int(pts[2][0]))
	var right := "leg A" if sa > sc else ("leg C" if sc > sa else "both the same")
	ex = K.choice(rng, "The graph shows %s's bike ride. On which leg did %s ride faster?" % [who, who], right,
		["leg A", "leg C", "both the same", "leg B"].filter(func(x: Variant) -> bool: return str(x) != right),
		"The steeper leg is faster: work out each speed to be sure.",
		"Leg A: %d km/h; leg C: %d km/h; leg B is a stop." % [sa, sc], pic)
	ex.data = {"ask": "faster", "points": pts}
	return ex


## A ride of three legs: moving, a stop, moving (times in minutes, distances in whole km).
static func _trip(rng: RandomNumberGenerator, average: bool) -> Dictionary:
	for _try in 80:
		var t1: int = _pick(rng, [20, 30, 40])
		var t2: int = _pick(rng, [10, 20])
		var t3: int = _pick(rng, [10, 20, 30])
		var s1: int = _pick(rng, [12, 18, 24, 30])
		var s3: int = _pick(rng, [12, 18, 24, 30, 36])
		if s1 * t1 % 60 != 0 or s3 * t3 % 60 != 0 or s1 == s3:
			continue
		var d1 := s1 * t1 / 60
		var d3 := s3 * t3 / 60
		var total := t1 + t2 + t3
		if average and (d1 + d3) * 60 % total != 0:
			continue
		var top := d1 + d3
		for step: int in [2, 4, 5, 10]:
			var d_to := ceili(top / float(step)) * step
			if d_to / step >= 2 and d_to / step <= 8:
				return {"points": [[0, 0], [t1, d1], [t1 + t2, d1], [total, top]], "t_to": ceili(total / 10.0) * 10,
					"t_step": 10, "d_to": d_to, "d_step": step}
	return {"points": [[0, 0], [30, 6], [40, 6], [60, 12]], "t_to": 60, "t_step": 10, "d_to": 12, "d_step": 2}


## Average speed: two legs in whole hours (level 1), with a stop (level 2), the same distance at two speeds (level 3).
static func average_speed(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var who: String = _pick(rng, PEOPLE)
	if level <= 2:
		for _try in 200:
			var h1 := rng.randi_range(1, 3)
			var h2 := rng.randi_range(1, 3)
			var s1: int = _pick(rng, [30, 40, 50, 60, 70, 80])
			var s2: int = _pick(rng, [30, 40, 50, 60, 70, 80])
			var d := s1 * h1 + s2 * h2
			var stop := 30 if level == 2 else 0
			var t_half := (h1 + h2) * 2 + (1 if stop == 30 else 0)
			if d * 2 % t_half != 0 or s1 == s2:
				continue
			var avg := d * 2 / t_half
			var prompt := "%s drives %d km in %d hour%s, %sthen %d km in %d hour%s. What is the average speed for the whole trip, in km/h?" % [
				who, s1 * h1, h1, "" if h1 == 1 else "s", "stops for 30 minutes, " if stop == 30 else "", s2 * h2, h2,
				"" if h2 == 1 else "s"]
			ex = K.number(prompt, avg, "Add all the distances and all the times (stops too), then divide.",
				"%d km ÷ %s hours = %d km/h." % [d, _dec(t_half * 5, 1).trim_suffix(".0"), avg])
			ex.data = {"d": d, "t_half_hours": t_half}
			return ex
	var opts: Array = [[60, 30, 60], [120, 40, 60], [60, 20, 30], [90, 30, 90], [120, 30, 60], [180, 60, 90],
		[60, 12, 20], [240, 40, 60]]
	var o: Array = _pick(rng, opts)
	var dist := int(o[0])
	var ta := dist / int(o[1])
	var tb := dist / int(o[2])
	var avg3 := 2 * dist / (ta + tb)
	ex = K.number("%s rides %d km out at %d km/h and %d km back at %d km/h. What is the average speed for the whole trip, in km/h?" % [
		who, dist, o[1], dist, o[2]], avg3,
		"It is not halfway between the speeds: find each time, then total distance ÷ total time.",
		"Out: %d h; back: %d h. %d km ÷ %d h = %d km/h." % [ta, tb, 2 * dist, ta + tb, avg3])
	ex.data = {"d": dist, "s1": o[1], "s2": o[2]}
	return ex


# --- Maths: graphs that mislead --------------------------------------------------------------------------------------

## A bar chart whose axis does not start at 0: how many times as tall B looks (level 1), how much bigger it really is
## in percent (level 2), how many times as tall it would be on a fair axis (level 3).
static func cut_axis_look(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var c := _cut_chart(rng, level)
	var a := int(c.a)
	var b := int(c.b)
	var f := int(c.from)
	var pic := {"kind": "cut_axis_bars", "bars": [[str(c.la), a], [str(c.lb), b]], "from": f, "to": int(c.to),
		"step": int(c.step), "title": str(c.title)}
	var ex: Dictionary
	if level == 1:
		var looks := (b - f) / (a - f)
		ex = K.number("The axis starts at %d. How many times as tall as bar %s does bar %s look?" % [f, c.la, c.lb], looks,
			"Measure each bar from the bottom of the axis, %d, not from 0." % f,
			"From %d: %s is %d − %d = %d tall and %s is %d − %d = %d tall, so %s looks %d times as tall." % [f, c.la, a, f,
				a - f, c.lb, b, f, b - f, c.lb, looks], pic)
		ex.data = {"a": a, "b": b, "from": f, "ask": "looks"}
		return ex
	if level == 2:
		var pc := (b - a) * 100 / a
		ex = K.number("Bar %s is %d and bar %s is %d. By what percent is %s really bigger than %s?" % [c.la, a, c.lb, b,
			c.lb, c.la], pc, "Find the difference, then divide by the first value and multiply by 100.",
			"%d − %d = %d; %d ÷ %d × 100 = %d%%." % [b, a, b - a, b - a, a, pc], pic)
		ex.data = {"a": a, "b": b, "from": f, "ask": "percent"}
		return ex
	var ratio := _dec(b * 100 / a, 2)
	ex = K.number("On a fair axis from 0, how many times as tall as bar %s would bar %s be? Give a decimal." % [c.la, c.lb],
		ratio, "On a fair axis the bars are as tall as their values: divide one value by the other.",
		"%d ÷ %d = %s, though on this axis it looks %d times as tall." % [b, a, ratio, (b - f) / (a - f)], pic)
	ex.data = {"a": a, "b": b, "from": f, "ask": "fair"}
	return ex


static func _cut_chart(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var titles: Array = [["Mon", "Tue", "Ice creams sold"], ["2020", "2025", "Visitors"], ["Our shop", "Next door",
		"Loaves sold"], ["Team A", "Team B", "Points"]]
	for _try in 200:
		var u: int = _pick(rng, [1, 2, 5, 10, 20, 50])
		var f: int = _pick(rng, [20, 40, 50, 80, 100, 200, 400])
		var k2: int = _pick(rng, [2, 3, 4])
		var a := f + u
		var b := f + u * k2
		if level >= 2 and (b - a) * 100 % a != 0:
			continue
		if level == 3 and b * 100 % a != 0:
			continue
		var t: Array = _pick(rng, titles)
		return {"a": a, "b": b, "from": f, "to": b + u, "step": u, "la": t[0], "lb": t[1], "title": t[2]}
	return {"a": 50, "b": 60, "from": 40, "to": 70, "step": 10, "la": "A", "lb": "B", "title": "Sales"}


## The chart that fits a set of data: 3 choices (level 1), 4 (level 2); sort six into line, bar and pie (level 3).
static func best_chart(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var groups := ["line graph", "bar chart", "pie chart"]
		var pool: Array = CHART_DATA.keys().filter(func(k: Variant) -> bool: return groups.has(str(CHART_DATA[k])))
		var items := _spread_pick(rng, pool, CHART_DATA, groups, 5)
		var said := _sort_explain(groups, items, func(it: Variant) -> String: return str(CHART_DATA[it]))
		if said.length() > 255:
			said = "Line graphs for change over time (temperature, height, population); bar charts to compare groups; pie charts for the parts of one whole."
		ex = _sort_ex("Sort the data: which chart shows each best?", groups, items,
			items.map(func(it: Variant) -> int: return groups.find(str(CHART_DATA[it]))),
			"Change over time: a line graph. Comparing groups: a bar chart. Parts of one whole: a pie chart.", said)
		ex.data = {"items": items}
		return ex
	var keys: Array = CHART_DATA.keys()
	var item: String = _pick(rng, keys)
	var right := str(CHART_DATA[item])
	var wrongs: Array = CHART_NAMES.filter(func(n: Variant) -> bool: return str(n) != right)
	K.shuffle(rng, wrongs)
	if level == 1:
		wrongs = wrongs.slice(0, 2)
	ex = K.choice(rng, "Which chart would show %s best?" % item, right, wrongs,
		"Ask: change over time, groups compared, parts of one whole, or two measures linked?",
		"A %s: %s." % [right, _chart_job(right)])
	ex.data = {"item": item}
	return ex


static func _chart_job(chart: String) -> String:
	match chart:
		"line graph":
			return "it shows how something changes over time"
		"bar chart":
			return "it compares separate groups"
		"pie chart":
			return "it shows the parts of one whole"
	return "it shows whether two measures are linked"


## A picture drawn k times as tall and as wide: how many times as big it looks (levels 1-2); solid, k times deep too
## (level 3).
static func picture_scale(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var k: float = [2.0, 3.0][rng.randi() % 2] if level == 1 else ([1.5, 2.5, 3.0, 2.0][rng.randi() % 4] if level == 2
		else [2.0, 3.0][rng.randi() % 2])
	var solid := level == 3
	var looks := P.looks_times(k, solid)
	var k_said := _num(k)
	var what: String = "box" if solid else _pick(rng, SCALE_THINGS)
	var ex := K.number("The second %s is drawn %s times as tall and %s times as wide%s. How many times as big does it look?" % [
		what, k_said, k_said, " and deep" if solid else ""], _num(looks),
		"It grows in every direction: multiply the stretches together, not just the height.",
		"%s × %s%s = %s, so it looks %s times as big." % [k_said, k_said, (" × " + k_said) if solid else "", _num(looks),
			_num(looks)], {"kind": "big_icons", "what": what, "scale": k, "solid": solid})
	ex.data = {"k": k, "solid": solid}
	return ex


static func _num(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(roundi(v))
	return str(snappedf(v, 0.01))


# --- Science: the periodic table --------------------------------------------------------------------------------------

## Where an element is: its group (level 1) or period (level 2) on the table of elements 1-20; the element at a group
## and a period (level 3).
static func element_place(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var z := rng.randi_range(1, 20)
	var sym := P.symbol_of(z)
	var group := P.school_group(sym)
	var period := P.place_of(sym).y
	var ex: Dictionary
	if level == 1:
		ex = K.number("Which group is the element in orange in? (Group 0 is the noble gases' column.)", group,
			"Read the number at the top of its column.",
			"%s (%s) is in group %d, the column headed %d." % [_cap(str(NAMES[sym])), sym, group, group],
			{"kind": "periodic_grid", "view": "first20", "groups": true, "mark": [sym]})
		ex.data = {"symbol": sym, "ask": "group"}
		return ex
	if level == 2:
		ex = K.number("Which period is the element in orange in?", period,
			"Periods are rows: count down from the top row, period 1.",
			"%s (%s) is in row %d: period %d." % [_cap(str(NAMES[sym])), sym, period, period],
			{"kind": "periodic_grid", "view": "first20", "periods": true, "mark": [sym]})
		ex.data = {"symbol": sym, "ask": "period"}
		return ex
	while P.school_group(sym) < 0 or sym == "H":
		z = rng.randi_range(2, 20)
		sym = P.symbol_of(z)
	group = P.school_group(sym)
	period = P.place_of(sym).y
	var wrongs: Array = []
	for other in range(1, 21):
		var s := P.symbol_of(other)
		if s != sym and (P.school_group(s) == group or P.place_of(s).y == period) and wrongs.size() < 3:
			wrongs.append(str(NAMES[s]))
	ex = K.choice(rng, "Which element is in group %d and period %d?" % [group, period], str(NAMES[sym]), wrongs,
		"Go down the group's column to the period's row, and read the element there.",
		"Group %d, period %d is %s (%s)." % [group, period, NAMES[sym], sym])
	ex.data = {"symbol": sym, "ask": "which"}
	return ex


## Metal or non-metal: one element (level 1), sort four (level 2) or six (level 3).
static func metal_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var groups := ["metal", "non-metal"]
	if level == 1:
		var is_metal := rng.randi() % 2 == 0
		var name: String = _pick(rng, METAL_NAMES if is_metal else NON_METAL_NAMES)
		var ex := K.choice(rng, "Is %s a metal or a non-metal?" % name, "a metal" if is_metal else "a non-metal",
			["a non-metal" if is_metal else "a metal"],
			"Metals sit on the left and in the middle of the table; non-metals are on the right.",
			"%s is %s." % [_cap(name), "a metal" if is_metal else "a non-metal"])
		ex.data = {"name": name}
		return ex
	var n := 4 if level == 2 else 6
	var metals: Array = METAL_NAMES.duplicate()
	var non: Array = NON_METAL_NAMES.duplicate()
	K.shuffle(rng, metals)
	K.shuffle(rng, non)
	var items: Array = metals.slice(0, n / 2) + non.slice(0, n - n / 2)
	K.shuffle(rng, items)
	var kinds := {}
	for it: Variant in items:
		kinds[it] = "metal" if METAL_NAMES.has(str(it)) else "non-metal"
	var ex2 := _sort_ex("Sort the elements: metal or non-metal?", groups, items,
		items.map(func(it: Variant) -> int: return groups.find(str(kinds[it]))),
		"Picture each one: is it shiny and does it conduct (metal), or is it a gas or a dull, brittle solid?",
		_sort_explain(groups, items, func(it: Variant) -> String: return str(kinds[it])))
	ex2.data = {"items": items}
	return ex2


## An element's symbol (level 1), three names matched to their symbols (level 2), four with Latin symbols (level 3).
static func element_symbol(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 1:
		var sym: String = _pick(rng, EASY_SYMBOLS)
		var pool: Array = (EASY_SYMBOLS + LATIN_SYMBOLS).duplicate()
		K.shuffle(rng, pool)
		var first := sym.substr(0, 1)
		pool.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a).begins_with(first) and not str(b).begins_with(first))
		var wrongs: Array = []
		for s: Variant in pool:
			if str(s) != sym and wrongs.size() < 3:
				wrongs.append(str(s))
		var ex := K.choice(rng, "What is the symbol for %s?" % NAMES[sym], sym, wrongs,
			"A symbol is one or two letters, the first a capital, often the start of the name.",
			"%s is %s." % [_cap(str(NAMES[sym])), sym])
		ex.data = {"symbol": sym}
		return ex
	var pool: Array = (EASY_SYMBOLS if level == 2 else LATIN_SYMBOLS).duplicate()
	K.shuffle(rng, pool)
	var syms: Array = pool.slice(0, 3 if level == 2 else 4)
	if level == 2:
		syms[2] = _pick(rng, LATIN_SYMBOLS)
	var pairs: Array = syms.map(func(s: Variant) -> Array: return [str(NAMES[s]), str(s)])
	var ex2 := _match_ex(rng, "Match each element to its symbol.", pairs,
		"Some symbols come from old Latin names: Fe from ferrum, Au from aurum, Na from natrium.",
		_cap("; ".join(PackedStringArray(pairs.map(func(p: Variant) -> String: return "%s: %s" % [p[0], p[1]])))) + ".")
	ex2.data = {"symbols": syms}
	return ex2


# --- Science: mixtures and separating -------------------------------------------------------------------------------

## The way to separate a mixture: 3 choices (level 1), 4 (level 2); sort five mixtures by three methods (level 3).
static func separate_method(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var methods: Array = MAIN_METHODS.duplicate()
		K.shuffle(rng, methods)
		methods = methods.slice(0, 3)
		var pool: Array = MIXTURES.keys().filter(func(k: Variant) -> bool: return methods.has(str(MIXTURES[k])))
		var items := _spread_pick(rng, pool, MIXTURES, methods, 5)
		ex = _sort_ex("Sort the jobs by the way you would separate them.", methods, items,
			items.map(func(it: Variant) -> int: return methods.find(str(MIXTURES[it]))),
			"Insoluble solid: filter. Dissolved solid back: evaporate. Pure liquid: distil. Dyes: chromatography.",
			_sort_explain(methods, items, func(it: Variant) -> String: return str(MIXTURES[it])))
		ex.data = {"items": items, "groups": methods}
		return ex
	var item: String = _pick(rng, MIXTURES.keys())
	var right := str(MIXTURES[item])
	var wrongs: Array = (MAIN_METHODS + OTHER_METHODS).filter(func(m: Variant) -> bool: return str(m) != right)
	K.shuffle(rng, wrongs)
	wrongs = wrongs.slice(0, 2 if level == 1 else 3)
	ex = K.choice(rng, "Which is the best way to separate %s?" % item, right, wrongs,
		"Ask: is the solid dissolved or not, do you want the liquid back, or are you splitting colours?",
		"%s: %s." % [_cap(right), _method_job(right)])
	ex.data = {"item": item}
	return ex


static func _method_job(method: String) -> String:
	match method:
		"filtering":
			return "the filter paper traps the solid that has not dissolved"
		"evaporating":
			return "the water leaves as vapour and the dissolved solid stays"
		"distilling":
			return "the steam is cooled back into pure water"
		"chromatography":
			return "each dye travels up the paper at its own speed"
		"a magnet":
			return "it pulls out the iron and leaves the rest"
	return "the small pieces fall through its holes and the big ones stay"


## A chromatogram: how many dyes in an ink (level 1), which ink is pure (level 2), which dyes are in a mixture
## (level 3).
static func chroma_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var dyes: Array = DYES.duplicate()
	K.shuffle(rng, dyes)
	var ex: Dictionary
	if level == 1:
		var n := rng.randi_range(2, 4)
		var mix: Array = dyes.slice(0, n).map(func(d: Variant) -> Array: return [float(d[1]), str(d[0])])
		var other: Array = [[float(dyes[n][1]), str(dyes[n][0])]]
		var samples: Array = [["ink X", mix], ["ink Y", other]]
		if rng.randi() % 2 == 0:
			samples.reverse()
		ex = K.number("How many dyes are in ink X?", n, "Count the separate spots in ink X's column: each is one dye.",
			"Ink X makes %d spots, so it holds %d dyes." % [n, n], {"kind": "chromatogram", "samples": samples})
		ex.data = {"samples": samples, "ask": "count"}
		return ex
	if level == 2:
		var names: Array = ["A", "B", "C"]
		var pure := rng.randi_range(0, 2)
		var samples2: Array = []
		var k := 0
		for i in 3:
			if i == pure:
				samples2.append([str(names[i]), [[float(dyes[k][1]), str(dyes[k][0])]]])
				k += 1
			else:
				samples2.append([str(names[i]), [[float(dyes[k][1]), str(dyes[k][0])], [float(dyes[k + 1][1]),
					str(dyes[k + 1][0])]]])
				k += 2
		var not_pure: Array = []
		for nm: Variant in names:
			if str(nm) != str(names[pure]):
				not_pure.append("ink %s" % nm)
		ex = K.choice(rng, "Which ink is a pure substance?", "ink %s" % names[pure], not_pure,
			"A pure substance makes just one spot; a mixture makes more.",
			"Ink %s makes one spot, so it is pure; the others split into two dyes." % names[pure],
			{"kind": "chromatogram", "samples": samples2})
		ex.data = {"samples": samples2, "ask": "pure"}
		return ex
	var three: Array = dyes.slice(0, 3)
	var inmix: Array = [three[0], three[1]]
	var samples3: Array = [["mix", inmix.map(func(d: Variant) -> Array: return [float(d[1]), str(d[0])])]]
	for d: Array in three:
		samples3.append([str(d[0]), [[float(d[1]), str(d[0])]]])
	var right := "%s and %s" % [three[0][0], three[1][0]]
	ex = K.choice(rng, "Which dyes are in the mix?", right, ["%s and %s" % [three[0][0], three[2][0]],
		"%s and %s" % [three[1][0], three[2][0]], "all three"],
		"Look across: a dye in the mix makes a spot at the same height as that dye alone.",
		"The mix's spots are level with %s and %s, not %s." % [three[0][0], three[1][0], three[2][0]],
		{"kind": "chromatogram", "samples": samples3})
	ex.data = {"samples": samples3, "ask": "which"}
	return ex


## The words of mixtures: a meaning's word (level 1), match three (level 2) or four (level 3).
static func mixture_words(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var words: Array = MIXTURE_WORDS.keys()
	K.shuffle(rng, words)
	if level == 1:
		var w := str(words[0])
		var ex := K.choice(rng, "Which word means \"%s\"?" % MIXTURE_WORDS[w], w, words.slice(1, 4),
			"Think of salty water: the salt, the water, and the two together; and what a filter keeps or lets through.",
			"%s: %s." % [_cap(w), MIXTURE_WORDS[w]])
		ex.data = {"word": w}
		return ex
	var pick: Array = words.slice(0, 3 if level == 2 else 4)
	var pairs: Array = pick.map(func(w: Variant) -> Array: return [str(w), str(MIXTURE_WORDS[w])])
	var ex2 := _match_ex(rng, "Match each word to its meaning.", pairs,
		"Solute and solvent make a solution; a residue stays in the filter and the filtrate passes through.",
		_cap("; ".join(PackedStringArray(pairs.map(func(p: Variant) -> String: return "%s: %s" % [p[0], p[1]])))) + ".")
	ex2.data = {"words": pick}
	return ex2


# --- Science: acids and alkalis -------------------------------------------------------------------------------------

## A pH: acid, neutral or alkali (level 1); how strongly (level 2); order four substances by pH (level 3).
static func ph_kind(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var pool: Array = PH.keys()
		var chosen: Array = []
		var used := {}
		K.shuffle(rng, pool)
		for s: Variant in pool:
			if not used.has(int(PH[s])) and chosen.size() < 4:
				used[int(PH[s])] = true
				chosen.append(str(s))
		chosen.sort_custom(func(a: Variant, b: Variant) -> bool: return int(PH[a]) < int(PH[b]))
		ex = K.order(rng, "Order from the most acidic to the most alkaline.", chosen,
			"Most acidic has the lowest pH; most alkaline the highest. Recall each one's pH first.",
			_cap(", ".join(PackedStringArray(chosen.map(func(s: Variant) -> String: return "%s (pH %d)" % [s, PH[s]])))) + ".")
		ex.data = {"items": chosen}
		return ex
	var sub: String = _pick(rng, PH.keys())
	var ph := int(PH[sub])
	if level == 1:
		var right: String = {"acid": "acidic", "neutral": "neutral", "alkali": "alkaline"}[P.ph_kind(ph)]
		ex = K.choice(rng, "%s has a pH of %d. Is it acidic, neutral or alkaline?" % [_cap(sub), ph], right,
			["acidic", "neutral", "alkaline"].filter(func(x: Variant) -> bool: return str(x) != right),
			"Below 7 is acidic, 7 is neutral, above 7 is alkaline.", "pH %d is %s." % [ph, right],
			{"kind": "ph_scale", "marks": [[ph, _short(sub)]]})
		ex.data = {"substance": sub, "ph": ph}
		return ex
	var right2 := P.strength(ph)
	var wrongs: Array = STRENGTHS.filter(func(x: Variant) -> bool: return str(x) != right2)
	K.shuffle(rng, wrongs)
	ex = K.choice(rng, "%s has a pH of %d. How would you describe it?" % [_cap(sub), ph], right2, wrongs.slice(0, 3),
		"The further from 7, the stronger: 0-3 and 11-14 strongly, 4-6 and 8-10 weakly.",
		"pH %d is %s." % [ph, right2], {"kind": "ph_scale", "marks": [[ph, _short(sub)]], "bands": true})
	ex.data = {"substance": sub, "ph": ph}
	return ex


static func _short(s: String) -> String:
	return str(PH_LABEL.get(s, s))


## Indicators: universal indicator's colour at a pH (level 1), litmus (level 2), the colour after neutralising
## (level 3).
static func indicator_colour(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var ph: int = _pick(rng, [1, 2, 7, 9, 12, 13, 14])
		var right := P.indicator_colour(ph)
		var wrongs: Array = ["red", "green", "blue", "purple"].filter(func(c: Variant) -> bool: return str(c) != right)
		ex = K.choice(rng, "What colour does universal indicator turn at pH %d?" % ph, right, wrongs,
			"Find the pH on the scale: is it at the acid end, in the middle, or at the alkali end?",
			"At pH %d universal indicator turns %s." % [ph, right], {"kind": "ph_scale", "marks": [[ph, "pH %d" % ph]],
				"colours": false})
		ex.data = {"ph": ph}
		return ex
	if level == 2:
		var sub: String = _pick(rng, PH.keys().filter(func(s: Variant) -> bool: return int(PH[s]) != 7))
		var acid := int(PH[sub]) < 7
		var paper: String = _pick(rng, ["red", "blue"])
		var turns := "red" if acid else "blue"
		var right := "it turns red" if paper == "blue" and acid else ("it turns blue" if paper == "red" and not acid
			else "it stays %s" % paper)
		var outcomes: Array = []
		for o: String in ["it turns red", "it turns blue", "it stays %s" % paper]:
			if o != right and o != "it turns %s" % paper:
				outcomes.append(o)
		ex = K.choice(rng, "You dip %s litmus paper into %s. What happens?" % [paper, sub], right, outcomes,
			"Litmus is red in acids and blue in alkalis: does the paper already have that colour?",
			"%s is %s, so litmus ends up %s: %s." % [_cap(sub), "acidic" if acid else "alkaline", turns, right])
		ex.data = {"substance": sub, "paper": paper}
		return ex
	var start: int = _pick(rng, [1, 2, 12, 13])
	var adding := "an alkali" if start < 7 else "an acid"
	ex = K.choice(rng, "Universal indicator in a solution of pH %d is %s. You add %s drop by drop until it is neutralised. What colour is it then?" % [
		start, P.indicator_colour(start), adding], "green", ["red", "purple", "blue"],
		"Neutralised means the pH has reached 7.",
		"Neutral is pH 7, and universal indicator is green at 7.")
	ex.data = {"start": start}
	return ex


## Neutralisation: what an acid and an alkali make (level 1), the salt's name (level 2), the acid and alkali for a salt
## (level 3).
static func salt_name(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var acid: String = _pick(rng, ACIDS.keys())
	var alkali: String = _pick(rng, ALKALIS.keys())
	var salt := "%s %s" % [ALKALIS[alkali], ACIDS[acid]]
	var ex: Dictionary
	if level == 1:
		ex = K.choice(rng, "%s + %s make a salt and what else?" % [_cap(acid), alkali], "water",
			["oxygen", "more acid", "carbon dioxide"],
			"Neutralisation always makes the same two kinds of thing: a salt and one everyday liquid.",
			"Acid + alkali make a salt + water: %s + water." % salt)
		ex.data = {"acid": acid, "alkali": alkali, "ask": "water"}
		return ex
	if level == 2:
		var wrongs: Array = []
		for a: String in ACIDS:
			for b: String in ALKALIS:
				var s := "%s %s" % [ALKALIS[b], ACIDS[a]]
				if s != salt and (a == acid or b == alkali) and wrongs.size() < 3:
					wrongs.append(s)
		ex = K.choice(rng, "%s + %s make which salt?" % [_cap(acid), alkali], salt, wrongs,
			"The metal comes from the alkali; hydrochloric acid gives a chloride, sulfuric a sulfate, nitric a nitrate.",
			"%s gives %s and %s gives %s: %s." % [_cap(alkali), ALKALIS[alkali], acid, ACIDS[acid], salt])
		ex.data = {"acid": acid, "alkali": alkali, "ask": "salt"}
		return ex
	var right := "%s + %s" % [acid, alkali]
	var wrongs3: Array = []
	for a: String in ACIDS:
		for b: String in ALKALIS:
			var pair := "%s + %s" % [a, b]
			if pair != right and (a == acid or b == alkali) and wrongs3.size() < 3:
				wrongs3.append(pair)
	ex = K.choice(rng, "Which acid and alkali make %s and water?" % salt, right, wrongs3,
		"Work backwards: the first word is the alkali's metal; chloride, sulfate or nitrate names the acid.",
		"%s comes from %s and %s." % [_cap(salt), alkali, acid])
	ex.data = {"acid": acid, "alkali": alkali, "ask": "pair"}
	return ex


# --- Science: light and colour --------------------------------------------------------------------------------------

## The colour a thing looks: in white light (level 1), in coloured light (level 2), through a filter (level 3).
static func colour_seen(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var object: String = _pick(rng, ["red", "green", "blue", "white", "black", "yellow"] if level >= 2 else
		["red", "green", "blue", "white", "black"])
	var light := "white" if level != 2 else str(_pick(rng, ["red", "green", "blue"]))
	var filter := "" if level != 3 else str(_pick(rng, ["red", "green", "blue"]))
	var seen := P.seen_as(light, object, filter)
	var thing: String = _pick(rng, COLOUR_THINGS[object])
	var wrongs: Array = SEEN_CHOICES.filter(func(c: Variant) -> bool: return str(c) != seen)
	K.shuffle(rng, wrongs)
	var prompt := "A %s %s is lit by %s light%s. What colour does it look?" % [object, thing, light,
		", seen through a %s filter" % filter if filter != "" else ""]
	var why: String = {"white": "It reflects every colour of light", "black": "It reflects no light",
		"yellow": "It reflects red and green light"}.get(object, "It reflects only %s light" % object)
	var pic := {"kind": "seen_colour", "light": light, "object": object, "thing": PICTURE_THING.get(thing, "ball"),
		"hide": true}
	if filter != "":
		pic.filter = filter
	var ex := K.choice(rng, prompt, seen, wrongs.slice(0, 3),
		"Ask what light reaches it, which of that it reflects, and what the filter lets through.",
		"%s; the light holds %s%s. So it looks %s." % [why, _light_holds(light), (" and the filter passes only " + filter)
			if filter != "" else "", seen], pic)
	ex.data = {"light": light, "object": object, "filter": filter}
	return ex


static func _light_holds(light: String) -> String:
	return "red, green and blue" if light == "white" else "only %s" % light


## Which way light bends: air into glass or water (level 1), out of them (level 2), along the normal or which bends
## more (level 3).
static func refraction_bend(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level <= 2:
		var c: Array = CROSSINGS[rng.randi_range(0, 1) + (0 if level == 1 else 2)]
		var right := str(c[3])
		var into := "glass" if "glass" in [str(c[0]), str(c[1])] else "water"
		ex = K.choice(rng, "A ray of light passes from %s into %s at an angle. Which way does it bend?" % [c[0], c[1]],
			right, BENDS.filter(func(b: Variant) -> bool: return str(b) != right),
			"Does the light slow down or speed up as it crosses? Slowing turns it towards the dashed line.",
			"It %s, so it bends %s." % ["slows down" if right == "towards the normal" else "speeds up", right],
			{"kind": "light_rays", "view": "refraction" if level == 1 else "leaving", "into": into, "angle": 30})
		ex.data = {"from": c[0], "to": c[1]}
		return ex
	if rng.randi() % 2 == 0:
		ex = K.choice(rng, "A ray goes into a glass block along the normal, at 90° to the surface. What happens?",
			"it does not bend", ["towards the normal", "away from the normal"],
			"Bending needs the ray to meet the surface at a slant: does this one?",
			"Along the normal it slows down but does not change direction: it does not bend.",
			{"kind": "light_rays", "view": "along_normal"})
		ex.data = {"ask": "normal"}
		return ex
	var angle: int = _pick(rng, [30, 40, 50, 60])
	ex = K.choice(rng, "Two rays enter glass and water at %d° from the normal. Which bends more?" % angle,
		"the ray into glass", ["the ray into water", "they bend the same"],
		"The bigger the change of speed, the bigger the bend: which one slows light more?",
		"Glass slows light more (to about 200,000 km/s) than water (about 225,000 km/s), so the glass ray bends more: %d° and %d° from the normal." % [
			roundi(P.refracted_angle(angle, 1.0, P.N_GLASS)), roundi(P.refracted_angle(angle, 1.0, P.N_WATER))])
	ex.data = {"ask": "more", "angle": angle}
	return ex


## The spectrum: the next colour (level 1), four in order (level 2), which bends most or least (level 3).
static func spectrum_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var spec: Array = Array(P.SPECTRUM)
	var ex: Dictionary
	if level == 1:
		var i := rng.randi_range(0, 5)
		var right := str(spec[i + 1])
		var wrongs: Array = spec.filter(func(c: Variant) -> bool: return str(c) != right and str(c) != str(spec[i]))
		K.shuffle(rng, wrongs)
		ex = K.choice(rng, "In the spectrum, which colour comes straight after %s?" % spec[i], right, wrongs.slice(0, 3),
			"Say the spectrum in order: red, orange, yellow, green, blue, indigo, violet.",
			"%s, then %s." % [_cap(str(spec[i])), right], {"kind": "light_rays", "view": "prism"})
		ex.data = {"after": spec[i]}
		return ex
	if level == 2:
		var idx: Array = range(7)
		K.shuffle(rng, idx)
		idx = idx.slice(0, 4)
		idx.sort()
		var cols: Array = idx.map(func(i: Variant) -> String: return str(spec[i]))
		ex = K.order(rng, "Put these colours in the spectrum's order, starting nearest red.", cols,
			"The spectrum runs red, orange, yellow, green, blue, indigo, violet.", _cap(", ".join(PackedStringArray(cols))) + ".")
		ex.data = {"items": cols}
		return ex
	var idx3: Array = range(7)
	K.shuffle(rng, idx3)
	idx3 = idx3.slice(0, 3)
	var most := rng.randi() % 2 == 0
	var best := int(idx3.max()) if most else int(idx3.min())
	ex = K.choice(rng, "A prism splits white light. Which of these colours bends %s?" % ("most" if most else "least"),
		str(spec[best]), idx3.filter(func(i: Variant) -> bool: return int(i) != best).map(func(i: Variant) -> String:
			return str(spec[i])), "Red bends least and violet most; the others are in spectrum order between them.",
		"Of these, %s comes nearest the %s end of the spectrum, so it bends %s." % [str(spec[best]), "violet" if most
			else "red", "most" if most else "least"])
	ex.data = {"colours": idx3.map(func(i: Variant) -> String: return str(spec[i])), "most": most}
	return ex


# --- Science: the air and the carbon cycle --------------------------------------------------------------------------

## The air's gases: a gas's share (level 1), litres of oxygen in some air (level 2), litres of nitrogen or the carbon
## dioxide's share (level 3).
static func air_share(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var gas: String = _pick(rng, GASES.keys())
		ex = K.number("About what percent of dry air is %s?" % gas, GASES[gas],
			"Picture a hundred squares of air: count the squares of that colour.",
			"Dry air is about 78%% nitrogen, 21%% oxygen and 1%% argon: %s is about %d%%." % [gas, GASES[gas]],
			{"kind": "air_mix", "hide": ["nitrogen", "oxygen", "argon"].find(gas)})
		ex.data = {"gas": gas}
		return ex
	var litres: int = _pick(rng, [100, 200, 300, 500, 1000, 2000, 5000])
	if level == 2:
		ex = K.number("About how many litres of oxygen are in %s litres of air?" % K.fmt(litres), litres * 21 / 100,
			"Oxygen is 21% of air: find 1% first, then multiply by 21.",
			"1%% of %s is %s; × 21 = %s litres." % [K.fmt(litres), K.fmt(litres / 100), K.fmt(litres * 21 / 100)])
		ex.data = {"litres": litres, "gas": "oxygen"}
		return ex
	if rng.randi() % 2 == 0:
		ex = K.number("About how many litres of nitrogen are in %s litres of air?" % K.fmt(litres), litres * 78 / 100,
			"Nitrogen is 78% of air: find 1% first, then multiply by 78.",
			"1%% of %s is %s; × 78 = %s litres." % [K.fmt(litres), K.fmt(litres / 100), K.fmt(litres * 78 / 100)])
		ex.data = {"litres": litres, "gas": "nitrogen"}
		return ex
	var ppm: int = _pick(rng, [280, 320, 350, 400, 420])
	ex = K.number("Air held %d parts per million of carbon dioxide. What percent is that? (A million parts is 100%%.)" % ppm,
		_dec(ppm, 4), "1% is 10,000 parts per million: divide by 10,000.",
		"%d ÷ 10,000 = %s%%." % [ppm, _dec(ppm, 4)])
	ex.data = {"ppm": ppm}
	return ex


## The carbon cycle: does a process add carbon dioxide to the air (level 1), sort four (level 2), name a hidden
## process (level 3).
static func carbon_process(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var p: String = _pick(rng, PROCESS_CO2.keys())
		var right := "it adds carbon dioxide" if PROCESS_CO2[p] else "it takes carbon dioxide out"
		ex = K.choice(rng, "Think about %s. Does it add carbon dioxide to the air, or take it out?" % p, right,
			["it takes carbon dioxide out" if PROCESS_CO2[p] else "it adds carbon dioxide"],
			"Burning, breathing out and rotting give carbon dioxide out; green plants growing take it in.",
			"%s: %s." % [_cap(p), right])
		ex.data = {"process": p}
		return ex
	if level == 2:
		var table := {}
		for k: Variant in PROCESS_CO2:
			table[k] = SORT_CO2[0] if PROCESS_CO2[k] else SORT_CO2[1]
		var items := _spread_pick(rng, PROCESS_CO2.keys(), table, SORT_CO2, 4)
		ex = _sort_ex("Sort the processes for carbon dioxide in the air.", SORT_CO2, items,
			items.map(func(it: Variant) -> int: return 0 if PROCESS_CO2[it] else 1),
			"Which ones burn, breathe or rot (adding it), and which are green things making food (taking it)?",
			_sort_explain(SORT_CO2, items, func(it: Variant) -> String: return str(table[it])))
		ex.data = {"items": items}
		return ex
	var hidden: String = _pick(rng, ["photosynthesis", "combustion", "decay", "fossilisation", "feeding"])
	var wrongs: Array = P.PROCESSES.filter(func(x: Variant) -> bool: return str(x) != hidden)
	K.shuffle(rng, wrongs)
	ex = K.choice(rng, "Which process is hidden by the question mark?", hidden, wrongs.slice(0, 3),
		"Look where the arrow starts and ends: which process moves carbon from that store to that one?",
		"%s carries carbon %s." % [_cap(hidden), _flow_said(hidden)],
		{"kind": "carbon_cycle", "hide": hidden})
	ex.data = {"hidden": hidden}
	return ex


static func _flow_said(process: String) -> String:
	for f: Array in P.FLOWS:
		if str(f[0]) == process:
			return "from %s to %s" % [STORE_SAID[str(f[4])], STORE_SAID[str(f[1])]]
	return ""


const STORE_SAID := {"air": "the air", "plants": "plants", "animals": "animals", "decomposers": "dead matter",
	"fossil fuels": "fossil fuels"}


## Combustion: the gas that burning makes (level 1), a fuel's products (level 2), too little oxygen or a fuel with no
## carbon (level 3).
static func burn_products(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		ex = K.choice(rng, "Wood burns in plenty of air. Which gas does burning add to the air?", "carbon dioxide",
			["oxygen", "nitrogen", "argon"], "Burning joins the fuel's carbon with oxygen from the air.",
			"Carbon + oxygen make carbon dioxide, which goes into the air.")
		ex.data = {"ask": "gas"}
		return ex
	if level == 2:
		var fuel: String = _pick(rng, FUELS.keys().filter(func(f: Variant) -> bool: return str(f) != "hydrogen"))
		var right := str(FUELS[fuel])
		ex = K.choice(rng, "%s burns completely in oxygen. What does it make?" % _cap(fuel), right,
			FUELS.values().filter(func(v: Variant) -> bool: return str(v) != right).duplicate() + ["oxygen and nitrogen"],
			"Fuels with carbon make carbon dioxide; fuels with hydrogen make water too.",
			"%s + oxygen make %s." % [_cap(fuel), right])
		ex.data = {"fuel": fuel}
		return ex
	if rng.randi() % 2 == 0:
		ex = K.choice(rng, "A gas fire burns with too little oxygen. Which poisonous gas can it make?",
			"carbon monoxide", ["carbon dioxide", "oxygen", "water vapour"],
			"With too little oxygen, each carbon gets only one oxygen atom.",
			"Burning with too little oxygen makes carbon monoxide, a poisonous gas you cannot see or smell.")
		ex.data = {"ask": "monoxide"}
		return ex
	ex = K.choice(rng, "Which fuel makes no carbon dioxide at all when it burns?", "hydrogen",
		["methane (natural gas)", "coal (carbon)", "candle wax"],
		"Carbon dioxide needs carbon: which fuel has no carbon in it?", "Hydrogen + oxygen make only water.")
	ex.data = {"ask": "no carbon"}
	return ex


# --- English: strong evidence ---------------------------------------------------------------------------------------

## The strongest evidence for a claim (levels 1-3: clearer to subtler).
static func evidence_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = EVIDENCE.filter(func(e: Array) -> bool: return int(e[3]) == level)
	var e: Array = _pick(rng, pool)
	var quotes: Array = e[1]
	var right := str(quotes[int(e[2])])
	var ex := K.choice(rng, "Claim: %s Which line from the story proves it best?" % e[0], right,
		quotes.filter(func(q: Variant) -> bool: return str(q) != right),
		"Read each line on its own: would it convince someone who had not read the story?",
		"\"%s\" shows it; the other lines are true but say nothing about the claim." % right.trim_suffix(".")
			.replace("\"", "'"))
	ex.data = {"claim": e[0]}
	return ex


## A quote or a paraphrase: one (level 1), sort four (level 2); the best paraphrase of a quote (level 3).
static func quote_or_paraphrase(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var p: Array = _pick(rng, PARAPHRASE_PICKS)
		ex = K.choice(rng, "Which is the best paraphrase of %s?" % p[0], str(p[1]), p[2],
			"A paraphrase keeps the meaning but uses your own words.",
			"\"%s\" keeps the meaning in new words; the others change what happened." % str(p[1]).trim_suffix("."))
		ex.data = {"quote": p[0]}
		return ex
	if level == 1:
		var quote := rng.randi() % 2 == 0
		var s: String = _pick(rng, QUOTES if quote else PARAPHRASES)
		ex = K.choice(rng, "Is this a quote or a paraphrase? %s" % s, "a quote" if quote else "a paraphrase",
			["a paraphrase" if quote else "a quote"],
			"A quote copies the exact words inside quotation marks; a paraphrase says it in your own words.",
			"It is %s: %s." % ["a quote" if quote else "a paraphrase", "the exact words are in quotation marks" if quote
				else "the ideas are in new words, with no quotation marks"])
		ex.data = {"sentence": s}
		return ex
	var qs: Array = QUOTES.duplicate()
	var ps: Array = PARAPHRASES.duplicate()
	K.shuffle(rng, qs)
	K.shuffle(rng, ps)
	var items: Array = qs.slice(0, 2) + ps.slice(0, 2)
	K.shuffle(rng, items)
	var groups := ["quote", "paraphrase"]
	ex = _sort_ex("Sort them: a quote or a paraphrase?", groups, items,
		items.map(func(it: Variant) -> int: return 0 if QUOTES.has(str(it)) else 1),
		"Look for quotation marks round the author's or speaker's exact words.",
		"Quotes copy the exact words in quotation marks; paraphrases put the same ideas in new words.")
	ex.data = {"items": items}
	return ex


# --- English: fiction and history -----------------------------------------------------------------------------------

## History text or historical fiction: one sentence (level 1), sort four (level 2) or six (level 3).
static func fact_or_fiction(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var hist := rng.randi() % 2 == 0
		var s: String = _pick(rng, HISTORY_SENTENCES if hist else FICTION_SENTENCES)
		ex = K.choice(rng, "Is this from a history text or from historical fiction? %s" % s,
			"a history text" if hist else "historical fiction", ["historical fiction" if hist else "a history text"],
			"History texts give dates, real events and sources; fiction adds invented people, feelings and speech.",
			"It is from %s: %s." % ["a history text" if hist else "historical fiction",
				"it states a fact that sources can check" if hist else "it shows invented feelings or speech"])
		ex.data = {"sentence": s}
		return ex
	var n := 4 if level == 2 else 6
	var h: Array = HISTORY_SENTENCES.duplicate()
	var f: Array = FICTION_SENTENCES.duplicate()
	K.shuffle(rng, h)
	K.shuffle(rng, f)
	var items: Array = h.slice(0, n / 2) + f.slice(0, n / 2)
	K.shuffle(rng, items)
	var groups := ["history text", "historical fiction"]
	ex = _sort_ex("Sort the sentences: history text or historical fiction?", groups, items,
		items.map(func(it: Variant) -> int: return 0 if HISTORY_SENTENCES.has(str(it)) else 1),
		"Could a source prove it (history), or does it show a made-up person's thoughts and words (fiction)?",
		"History: the facts with dates and sources. Fiction: the invented feelings, thoughts and speech.")
	ex.data = {"items": items}
	return ex


## A detail that does not belong in a story set in the past (levels 1-3: clearer to subtler).
static func out_of_time(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = ERAS.filter(func(e: Array) -> bool: return int(e[3]) == level)
	var e: Array = _pick(rng, pool)
	var belongs: Array = (e[1] as Array).duplicate()
	K.shuffle(rng, belongs)
	var wrong: String = _pick(rng, e[2])
	var ex := K.choice(rng, "A story is set in %s. Which detail does not belong there?" % e[0], wrong, belongs.slice(0, 3),
		"Ask of each detail: had it been invented, or had it reached that place, by then?",
		"%s came later, so it does not belong in %s." % [_cap(wrong), e[0]])
	ex.data = {"setting": e[0], "detail": wrong}
	return ex


# --- English: speeches and media ------------------------------------------------------------------------------------

## Ethos, pathos or logos: one line (level 1), match three (level 2), sort six (level 3).
static func appeal_kind(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var lines: Array = APPEALS.keys()
	K.shuffle(rng, lines)
	var ex: Dictionary
	if level == 1:
		var s := str(lines[0])
		var right := str(APPEALS[s])
		ex = K.choice(rng, "Which way of persuading is this? \"%s\"" % s, right,
			APPEAL_NAMES.filter(func(a: Variant) -> bool: return str(a) != right),
			"Ethos builds trust in the speaker, pathos stirs feelings, logos gives reasons and facts.",
			"It is %s: it appeals to %s." % [right, APPEAL_JOBS[right]])
		ex.data = {"line": s}
		return ex
	if level == 2:
		var pairs: Array = []
		for a: String in APPEAL_NAMES:
			var one: Array = lines.filter(func(l: Variant) -> bool: return str(APPEALS[l]) == a)
			pairs.append([a, _short_line(str(one[0]))])
		ex = _match_ex(rng, "Match each way of persuading to a line that uses it.", pairs,
			"Ethos: who is speaking. Pathos: how it makes you feel. Logos: numbers and reasons.",
			_cap("; ".join(PackedStringArray(pairs.map(func(p: Variant) -> String: return "%s: %s" % [p[0], p[1]])))))
		ex.data = {"pairs": pairs}
		return ex
	var items: Array = []
	for a: String in APPEAL_NAMES:
		var two: Array = lines.filter(func(l: Variant) -> bool: return str(APPEALS[l]) == a).slice(0, 2)
		items.append_array(two.map(func(l: Variant) -> String: return _short_line(str(l))))
	K.shuffle(rng, items)
	ex = _sort_ex("Sort the lines: ethos, pathos or logos?", APPEAL_NAMES, items,
		items.map(func(it: Variant) -> int: return APPEAL_NAMES.find(_appeal_of(str(it)))),
		"Ask: does it make me trust the speaker, feel something, or think about facts?",
		"Ethos lines say who knows best; pathos lines make you feel; logos lines give numbers and reasons.")
	ex.data = {"items": items}
	return ex


## A line short enough for a sort or match item (48 or 32 letters): its first clause.
static func _short_line(s: String) -> String:
	return SHORT_APPEALS.get(s, s)


const SHORT_APPEALS := {
	"As a doctor for twenty years, I have seen how sleep helps healing.": "As a doctor for twenty years...",
	"I have run this library for ten years, so I know what readers want.": "I have run libraries for years.",
	"Our team of scientists tested every sample twice.": "Our scientists tested it all.",
	"Imagine a puppy shivering in the cold with nowhere to go.": "Imagine a puppy shivering...",
	"Think how proud you will feel when the new park opens.": "Think how proud you will feel...",
	"Every lost pet leaves a family heartbroken.": "Every lost pet breaks a heart.",
	"The new path would cut the walk to school from 20 minutes to 8.": "The path cuts 20 minutes to 8.",
	"The repair costs 300 gold; a new roof costs 3,000 gold.": "Repair: 300 gold; roof: 3,000.",
	"Three surveys found that most pupils wanted a longer lunch.": "Three surveys found most agree."}


static func _appeal_of(short: String) -> String:
	for s: String in APPEALS:
		if _short_line(s) == short:
			return str(APPEALS[s])
	return ""


## A speaker's trick: spot it among fair points (level 1), name it (level 2), match four (level 3).
static func speech_trick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var lines: Array = TRICKS.keys()
	K.shuffle(rng, lines)
	var ex: Dictionary
	if level == 1:
		var trick := str(lines[0])
		var fair: Array = FAIR_POINTS.duplicate()
		K.shuffle(rng, fair)
		ex = K.choice(rng, "Which line uses a trick instead of evidence?", _short_trick(trick), fair.slice(0, 2),
			"Fair points give checkable facts; tricks push feelings, exaggerate or attack people.",
			"\"%s\" uses %s; the others give evidence you could check." % [trick.trim_suffix("."), TRICKS[trick]])
		ex.data = {"line": trick}
		return ex
	if level == 2:
		var s := str(lines[0])
		var right := str(TRICKS[s])
		ex = K.choice(rng, "Which trick does this use? \"%s\"" % s, right,
			TRICK_NAMES.filter(func(t: Variant) -> bool: return str(t) != right),
			"Strong words, everyone or no one, a jab at a person, or one story stretched to all?",
			"It is %s." % right)
		ex.data = {"line": s}
		return ex
	var pairs: Array = []
	for t: String in TRICK_NAMES:
		var one: Array = lines.filter(func(l: Variant) -> bool: return str(TRICKS[l]) == t)
		pairs.append([t, _short_trick(str(one[0]))])
	ex = _match_ex(rng, "Match each trick to an example.", pairs,
		"Look for strong words, all or nothing, a jab at a person, and one story used as proof.",
		_cap("; ".join(PackedStringArray(pairs.map(func(p: Variant) -> String: return "%s: %s" % [p[0], p[1]])))))
	ex.data = {"pairs": pairs}
	return ex


static func _short_trick(s: String) -> String:
	return SHORT_TRICKS.get(s, s)


const SHORT_TRICKS := {"This disastrous, dangerous plan must be stopped.": "This disastrous plan...",
	"Everyone in the whole world agrees with me.": "Everyone in the world agrees.",
	"Don't listen to Sam: he can't even tie his laces.": "Sam can't even tie his laces.",
	"My cousin ate carrots and never caught a cold, so carrots stop colds.": "My cousin ate carrots, so...",
	"This terrible, shameful idea will ruin our lovely town.": "This terrible, shameful idea...",
	"Nobody, not one single person, likes the new timetable.": "Nobody at all likes it.",
	"Why trust Mo's plan? He was late to school last week.": "Mo was late last week.",
	"My gran walked every day and lived to 100, so walking makes everyone live to 100.": "My gran walked, so..."}


# --- English: arguments with counterclaims --------------------------------------------------------------------------

## The best rebuttal to the other side's view (levels 1-3: the weak answers get closer).
static func rebuttal_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var r: Array = _pick(rng, REBUTTALS)
	var wrongs: Array = (r[2] as Array).duplicate()
	if level >= 2:
		wrongs.append("I agree, so my argument is wrong.")
	if level == 3:
		wrongs = [wrongs[0], "Some say that, and some do not.", "I agree, so my argument is wrong."]
	var ex := K.choice(rng, "Counterclaim: \"%s\" Which rebuttal answers it best?" % r[0], str(r[1]), wrongs,
		"A rebuttal answers the point itself with a reason, politely, and keeps your claim standing.",
		"\"%s\" gives a reason that answers the worry; the others are insults, off the point or give up." % str(r[1])
			.trim_suffix("."))
	ex.data = {"counter": r[0]}
	return ex


## Faulty reasoning: logical or not (level 1), name the flaw (level 2), match three (level 3).
static func reasoning_flaw(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var lines: Array = FLAWS.keys()
	K.shuffle(rng, lines)
	var ex: Dictionary
	if level == 1:
		var sound := rng.randi() % 2 == 0
		var s: String = _pick(rng, SOUND_REASONS) if sound else str(lines[0])
		ex = K.choice(rng, "Is this reasoning logical? \"%s\"" % s, "yes: the reason leads to the claim" if sound
			else "no: the reason does not prove it", ["no: the reason does not prove it" if sound
			else "yes: the reason leads to the claim"],
			"Ask: if the first part is true, must the second part be true?",
			"%s" % ("Yes: if the first part is true, the second follows." if sound else
				"No: it is %s, so the claim does not follow." % FLAWS[s]))
		ex.data = {"line": s}
		return ex
	if level == 2:
		var s2 := str(lines[0])
		var right := str(FLAWS[s2])
		ex = K.choice(rng, "What is wrong with this reasoning? \"%s\"" % s2, right,
			FLAW_NAMES.filter(func(f: Variant) -> bool: return str(f) != right),
			"Is it what everyone does, a tiny sample, only two options, or a jab at a person?",
			"It is %s." % right)
		ex.data = {"line": s2}
		return ex
	var names: Array = FLAW_NAMES.duplicate()
	K.shuffle(rng, names)
	var pairs: Array = []
	for f: Variant in names.slice(0, 3):
		var one: Array = lines.filter(func(l: Variant) -> bool: return str(FLAWS[l]) == str(f))
		pairs.append([str(f), _short_flaw(str(one[0]))])
	ex = _match_ex(rng, "Match each flaw to an example.", pairs,
		"Look for everyone, a tiny sample, only two options or a jab at a person.",
		_cap("; ".join(PackedStringArray(pairs.map(func(p: Variant) -> String: return "%s: %s" % [p[0], p[1]])))))
	ex.data = {"pairs": pairs}
	return ex


static func _short_flaw(s: String) -> String:
	return SHORT_FLAWS.get(s, s)


const SHORT_FLAWS := {"Everyone is buying these trainers, so they must be the best.": "Everyone buys them...",
	"I met two rude tourists, so all tourists are rude.": "Two were rude, so all are.",
	"Either we ban phones completely or pupils will never learn.": "Ban them all or never learn.",
	"Her plan is silly because she is only twelve.": "She is only twelve.",
	"Lots of people believe it, so it must be true.": "Lots believe it, so it's true.",
	"One apple in the box was bad, so the whole farm is bad.": "One bad apple: a bad farm.",
	"We either build the bridge today or the village dies.": "The bridge today, or nothing.",
	"His idea is wrong: he cannot even spell.": "He cannot even spell."}


# --- English: explain like an expert --------------------------------------------------------------------------------

## The signal word for a gap (level 1: 3 choices; level 2: 4), sort six signal words (level 3).
static func signal_word(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var c: Array = COMPARE_WORDS.duplicate()
		var e: Array = CAUSE_WORDS.duplicate()
		K.shuffle(rng, c)
		K.shuffle(rng, e)
		var items: Array = c.slice(0, 3) + e.slice(0, 3)
		K.shuffle(rng, items)
		var groups := ["compare and contrast", "cause and effect"]
		ex = _sort_ex("Sort the signal words.", groups, items,
			items.map(func(it: Variant) -> int: return 0 if COMPARE_WORDS.has(str(it)) else 1),
			"Does the word show things alike or different, or one thing making another happen?",
			"Compare and contrast: %s. Cause and effect: %s." % [_listed(items, COMPARE_WORDS), _listed(items,
				CAUSE_WORDS)])
		ex.data = {"items": items}
		return ex
	var s: Array = _pick(rng, SIGNALS)
	var wrongs: Array = (s[3] as Array).duplicate()
	if level == 2:
		var extra: String = _pick(rng, (COMPARE_WORDS if str(s[2]) == "cause" else CAUSE_WORDS))
		if not wrongs.has(extra) and extra.to_lower() != str(s[1]).to_lower():
			wrongs.append(extra)
	ex = K.choice(rng, "Choose the signal word: %s" % s[0], str(s[1]), wrongs,
		"Does the second part show a difference, a likeness, a cause or a result?",
		"\"%s\" fits: it shows %s." % [s[1], "a comparison or a contrast" if str(s[2]) == "compare"
			else "a cause or its effect"])
	ex.data = {"sentence": s[0]}
	return ex


## The precise words for vague ones: 2 choices (level 1), 3 (level 2); sort six (level 3).
static func precise_term(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var rows: Array = PRECISE.duplicate()
		K.shuffle(rng, rows)
		var items: Array = []
		for r: Array in rows.slice(0, 3):
			items.append(str(r[0]))
			items.append(str(r[1]))
		K.shuffle(rng, items)
		var groups := ["precise", "vague"]
		ex = _sort_ex("Sort the words: precise or vague?", groups, items,
			items.map(func(it: Variant) -> int: return 0 if _is_precise(str(it)) else 1),
			"Precise words give a number, a date or the subject's own term; vague ones could mean many things.",
			"Precise: %s. Vague: %s." % [_listed(items, PRECISE.map(func(r: Variant) -> String: return str(r[1]))),
				_listed(items, PRECISE.map(func(r: Variant) -> String: return str(r[0])))])
		ex.data = {"items": items}
		return ex
	var r: Array = _pick(rng, PRECISE)
	var wrongs: Array = [str(r[0])] if level == 1 else [str(r[0]), str(r[2])]
	ex = K.choice(rng, "An expert would write which, instead of \"%s\"?" % r[0], str(r[1]), wrongs,
		"Choose the words that give an exact amount, a date or the subject's own name for it.",
		"\"%s\" is exact; \"%s\" could mean many things." % [r[1], r[0]])
	ex.data = {"vague": r[0]}
	return ex


## The items that are in `keep`, joined with commas.
static func _listed(items: Array, keep: Array) -> String:
	var out: Array[String] = []
	for it: Variant in items:
		if keep.has(str(it)):
			out.append(str(it))
	return ", ".join(out)


static func _is_precise(t: String) -> bool:
	for r: Array in PRECISE:
		if str(r[1]) == t:
			return true
	return false


# --- English: point of view in stories ------------------------------------------------------------------------------

## The point of view of a sentence: 3 choices (level 1), with the picture (level 2); sort six (level 3).
static func pov_name(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var items: Array = []
		for name: String in POV_NAMES:
			var two: Array = POV_SENTENCES.keys().filter(func(s: Variant) -> bool: return str(POV_SENTENCES[s]) == name)
			K.shuffle(rng, two)
			items.append_array(two.slice(0, 2).map(func(s: Variant) -> String: return _short_pov(str(s))))
		K.shuffle(rng, items)
		var groups := ["first person", "third limited", "third omniscient"]
		ex = _sort_ex("Sort the lines by their point of view.", groups, items,
			items.map(func(it: Variant) -> int: return POV_NAMES.find(_pov_of(str(it)))),
			"I or we: first person. One character's thoughts: limited. Everyone's thoughts: omniscient.",
			"First person uses I or we; third limited shows one character's mind; omniscient shows several minds.")
		ex.data = {"items": items}
		return ex
	var s: String = _pick(rng, POV_SENTENCES.keys())
	var right := str(POV_SENTENCES[s])
	ex = K.choice(rng, "Which point of view is this? \"%s\"" % s, right,
		POV_NAMES.filter(func(n: Variant) -> bool: return str(n) != right),
		"Look for I or we, then count whose thoughts the narrator tells us.",
		"It is %s: %s." % [right, {"first person": "the narrator says I or we",
			"third person limited": "we hear one character's thoughts",
			"third person omniscient": "we hear more than one character's thoughts"}[right]],
		{"kind": "pov_view", "mode": POV_MODE[right], "hide": true} if level == 2 else {})
	ex.data = {"line": s}
	return ex


const SHORT_POV := {"I pushed the door open and my heart thumped.": "I pushed the door; my heart thumped.",
	"We ran to the harbour before the storm broke.": "We ran to the harbour.",
	"I knew at once that the map was wrong.": "I knew the map was wrong.",
	"Zara stared at the map; she was sure they were lost.": "Zara was sure they were lost.",
	"Bram climbed the ladder, wondering if anyone had seen him.": "Bram climbed, wondering who saw.",
	"Tilly smiled, though she was secretly terrified of the dark.": "Tilly smiled, secretly afraid.",
	"Zara thought they were lost, while Bram knew the way and Tilly worried about rain.":
		"Zara feared, Bram knew, Tilly worried.",
	"Every villager hoped for rain, but none of them knew the river was already rising.":
		"All hoped; none knew the river rose.",
	"Leo felt proud; across the room, his sister felt forgotten.": "Leo felt proud; his sister, forgotten."}


static func _short_pov(s: String) -> String:
	return SHORT_POV.get(s, s)


static func _pov_of(short: String) -> String:
	for s: String in POV_SENTENCES:
		if _short_pov(s) == short:
			return str(POV_SENTENCES[s])
	return ""


## The sense a detail uses: 3 choices (level 1), match four (level 2) or five (level 3).
static func sense_detail(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var details: Array = SENSES.keys()
	K.shuffle(rng, details)
	var ex: Dictionary
	if level == 1:
		var d := str(details[0])
		var right := str(SENSES[d])
		var wrongs: Array = SENSE_NAMES.filter(func(s: Variant) -> bool: return str(s) != right)
		K.shuffle(rng, wrongs)
		ex = K.choice(rng, "Which sense does this detail use? \"%s\"" % d, right, wrongs.slice(0, 2),
			"Ask which part of you would notice it: eyes, ears, nose, tongue or skin.",
			"\"%s\" is %s." % [d, right])
		ex.data = {"detail": d}
		return ex
	var pairs: Array = []
	var used := {}
	for d: Variant in details:
		var sense := str(SENSES[d])
		if not used.has(sense) and pairs.size() < (4 if level == 2 else 5):
			used[sense] = true
			pairs.append([sense, str(d)])
	ex = _match_ex(rng, "Match each sense to a detail that uses it.", pairs,
		"Eyes see, ears hear, the nose smells, the tongue tastes and the skin feels.",
		_cap("; ".join(PackedStringArray(pairs.map(func(p: Variant) -> String: return "%s: %s" % [p[0], p[1]])))) + ".")
	ex.data = {"pairs": pairs}
	return ex


# --- Helpers ----------------------------------------------------------------------------------------------------------

## The text with a capital first letter (String.capitalize would title-case every word and turn hyphens into spaces).
static func _cap(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1)


static func _pick(rng: RandomNumberGenerator, list: Variant) -> Variant:
	var a: Array = list
	return a[rng.randi_range(0, a.size() - 1)]


## `n` items from `pool`, using at least two groups when `table` and `groups` are given (an item's group is
## table[item]).
static func _spread_pick(rng: RandomNumberGenerator, pool: Array, table: Dictionary, groups: Array, n: int) -> Array:
	var items: Array = []
	for _try in 50:
		var p := pool.duplicate()
		K.shuffle(rng, p)
		items = p.slice(0, mini(n, p.size()))
		if table.is_empty() or groups.is_empty():
			return items
		var used := {}
		for it: Variant in items:
			used[str(table[it])] = true
		if used.size() >= mini(2, groups.size()) and (n < 5 or used.size() >= mini(3, groups.size())):
			return items
	return items


static func _sort_ex(prompt: String, groups: Array, items: Array, answer: Array, hint: String, explain: String) -> Dictionary:
	return {"type": "sort", "prompt": prompt, "groups": groups.duplicate(), "items": items.duplicate(),
		"answer": answer.duplicate(), "hint": hint, "explain": explain}


static func _sort_explain(groups: Array, items: Array, group_of: Callable) -> String:
	var parts: Array[String] = []
	for g: Variant in groups:
		var of_g: Array = items.filter(func(it: Variant) -> bool: return str(group_of.call(it)) == str(g))
		if not of_g.is_empty():
			parts.append("%s: %s" % [_cap(str(g)), ", ".join(PackedStringArray(of_g.map(func(x: Variant) -> String:
				return str(x))))])
	return ". ".join(PackedStringArray(parts)) + "."


## A match exercise from [left, right] pairs: the right side shown in another order.
static func _match_ex(rng: RandomNumberGenerator, prompt: String, pairs: Array, hint: String, explain: String) -> Dictionary:
	var n := pairs.size()
	var order: Array = range(n)
	for _i in 8:
		K.shuffle(rng, order)
		if order != range(n):
			break
	if order == range(n):
		order.reverse()
	var matches: Array = order.map(func(i: Variant) -> String: return str(pairs[i][1]))
	var answer: Array = []
	for i in n:
		answer.append(order.find(i))
	return {"type": "match", "prompt": prompt, "items": pairs.map(func(p: Variant) -> String: return str(p[0])),
		"matches": matches, "answer": answer, "hint": hint, "explain": explain}
