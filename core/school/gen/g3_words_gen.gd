class_name G3WordsGen
extends RefCounted
## Owner #70 (the grade 3 science and English agent): grade 3 English generators: SchoolGen "g3e.<name>",
## `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint, a
## worked answer and `data` (tests/unit/test_g3_words_gen.gd works every answer out again with its own spelling
## rules). Every word is spelled the same in British and American English (spec §22.6 ruling 3); the sentences are
## our own.

const K := preload("res://core/school/gen/gen_kit.gd")

## [one, many, level, wrongs (the likeliest mistakes first)]: 1 add -s or -es; 2 -y to -ies, a vowel and y, -f or -fe
## to -ves; 3 irregular.
const NOUNS: Array = [
	["cat", "cats", 1, ["cat's", "cates", "caties"]], ["tree", "trees", 1, ["tree's", "treees", "treeses"]],
	["fox", "foxes", 1, ["foxs", "fox's", "foxies"]], ["bus", "buses", 1, ["buss", "bus's", "busies"]],
	["box", "boxes", 1, ["boxs", "box's", "boxies"]], ["dish", "dishes", 1, ["dishs", "dish's", "dishies"]],
	["bench", "benches", 1, ["benchs", "bench's", "benchies"]], ["glass", "glasses", 1, ["glasss", "glass's",
		"glassies"]], ["brush", "brushes", 1, ["brushs", "brush's", "brushies"]],
	["lunch", "lunches", 1, ["lunchs", "lunch's", "lunchies"]], ["frog", "frogs", 1, ["frog's", "froges", "froggs"]],
	["kite", "kites", 1, ["kite's", "kitees", "kitess"]],
	["baby", "babies", 2, ["babys", "baby's", "babyes"]], ["city", "cities", 2, ["citys", "city's", "cityes"]],
	["pony", "ponies", 2, ["ponys", "pony's", "ponyes"]], ["story", "stories", 2, ["storys", "story's", "storyes"]],
	["day", "days", 2, ["daies", "day's", "dayes"]], ["toy", "toys", 2, ["toies", "toy's", "toyes"]],
	["key", "keys", 2, ["kies", "key's", "keyes"]], ["leaf", "leaves", 2, ["leafs", "leaf's", "leafes"]],
	["wolf", "wolves", 2, ["wolfs", "wolf's", "wolfes"]], ["knife", "knives", 2, ["knifes", "knife's", "knifs"]],
	["loaf", "loaves", 2, ["loafs", "loaf's", "loafes"]], ["shelf", "shelves", 2, ["shelfs", "shelf's", "shelfes"]],
	["mouse", "mice", 3, ["mouses", "mices", "mouse's"]], ["child", "children", 3, ["childs", "childrens", "childes"]],
	["man", "men", 3, ["mans", "mens", "man's"]], ["woman", "women", 3, ["womans", "womens", "woman's"]],
	["foot", "feet", 3, ["foots", "feets", "footes"]], ["tooth", "teeth", 3, ["tooths", "teeths", "toothes"]],
	["goose", "geese", 3, ["gooses", "geeses", "goose's"]], ["ox", "oxen", 3, ["oxes", "oxs", "oxens"]],
	["sheep", "sheep", 3, ["sheeps", "sheepes", "sheep's"]], ["deer", "deer", 3, ["deers", "deeres", "deer's"]],
]

## [sentence with ___, the pronoun, wrongs, level]: 1 subject pronouns; 2 object pronouns; 3 we, us and owning words.
const PRONOUNS: Array = [
	["Zara found a shell. ___ kept it.", "She", ["He", "It", "Them"], 1],
	["Bram lost his hat. ___ looked everywhere.", "He", ["She", "It", "Us"], 1],
	["The dogs were hungry. ___ ate their dinner.", "They", ["It", "He", "Him"], 1],
	["The kite flew high. ___ was red and gold.", "It", ["They", "She", "Them"], 1],
	["Pip and Nell ran home. ___ were wet from the rain.", "They", ["He", "It", "Them"], 1],
	["Mimi baked a cake. ___ shared it with friends.", "She", ["He", "They", "Her"], 1],
	["The dogs barked, so Nell fed ___.", "them", ["they", "it", "him"], 2],
	["Zara waved to Bram, and Bram waved back to ___.", "her", ["she", "him", "they"], 2],
	["Pip dropped the ball, so Nell threw ___ back.", "it", ["them", "him", "she"], 2],
	["Bram needed help, so Tilly helped ___.", "him", ["he", "her", "it"], 2],
	["The ducks swam over, and we gave ___ some seeds.", "them", ["they", "it", "us"], 2],
	["Mimi smiled when her friends thanked ___.", "her", ["she", "them", "him"], 2],
	["Tilly and I baked bread. ___ shared it.", "We", ["They", "She", "Us"], 3],
	["Our teacher gave ___ a map.", "us", ["we", "our", "they"], 3],
	["Nell and Pip fed ___ goats.", "their", ["there", "they", "them"], 3],
	["Bram painted ___ boat blue.", "his", ["him", "he", "hers"], 3],
	["We planted ___ own garden.", "our", ["us", "we", "ours"], 3],
	["The bird built ___ nest in the tree.", "its", ["it", "it's", "their"], 3],
]

## [base, past, level, wrongs]: 1 add -ed; 2 regular with a spelling change; 3 irregular.
const VERBS: Array = [
	["jump", "jumped", 1, ["jumpt", "jumps"]], ["walk", "walked", 1, ["walkt", "walks"]],
	["play", "played", 1, ["plaied", "plays"]], ["help", "helped", 1, ["helpt", "helps"]],
	["look", "looked", 1, ["lookt", "looks"]], ["open", "opened", 1, ["openned", "opens"]],
	["climb", "climbed", 1, ["climbt", "climbs"]], ["kick", "kicked", 1, ["kickt", "kicks"]],
	["pull", "pulled", 1, ["pullt", "pulls"]], ["paint", "painted", 1, ["paintted", "paints"]],
	["hop", "hopped", 2, ["hoped", "hopt"]], ["stop", "stopped", 2, ["stoped", "stops"]],
	["clap", "clapped", 2, ["claped", "claps"]], ["bake", "baked", 2, ["bakeed", "bakked"]],
	["smile", "smiled", 2, ["smileed", "smilled"]], ["dance", "danced", 2, ["danceed", "dancd"]],
	["cry", "cried", 2, ["cryed", "cries"]], ["carry", "carried", 2, ["carryed", "carries"]],
	["try", "tried", 2, ["tryed", "tries"]], ["hug", "hugged", 2, ["huged", "hugs"]],
	["run", "ran", 3, ["runned", "runs"]], ["swim", "swam", 3, ["swimmed", "swims"]],
	["take", "took", 3, ["taked", "tooked"]], ["go", "went", 3, ["goed", "wented"]], ["see", "saw", 3, ["seen", "seeed"]],
	["eat", "ate", 3, ["eated", "eatted"]], ["write", "wrote", 3, ["writed", "writted"]],
	["think", "thought", 3, ["thinked", "thunk"]], ["catch", "caught", 3, ["catched", "caughted"]],
	["find", "found", 3, ["finded", "findded"]], ["sing", "sang", 3, ["sung", "singged"]],
	["fly", "flew", 3, ["flied", "flyed"]], ["bring", "brought", 3, ["bringed", "brang"]],
	["sit", "sat", 3, ["sitted", "setted"]], ["make", "made", 3, ["maked", "maded"]],
	["tell", "told", 3, ["telled", "tolded"]],
]

## Subjects: [words, one (true) or more than one, level]. "I" and "you" take the plain verb, like more than one.
const SUBJECTS: Array = [
	["He", true, 1], ["She", true, 1], ["They", false, 1], ["It", true, 1], ["We", false, 1],
	["The dog", true, 2], ["The dogs", false, 2], ["Zara", true, 2], ["Zara and Bram", false, 2], ["My friends", false, 2],
	["The bird", true, 2], ["I", false, 3], ["You", false, 3], ["The children", false, 3], ["My sister", true, 3],
]
## [verb, what follows]: plain verbs (level 1-2); level 3 adds verbs that take -es.
const DOINGS: Array = [["play", "in the park"], ["sing", "every morning"], ["run", "to school"], ["jump", "over puddles"],
	["swim", "in the lake"], ["read", "at bedtime"]]
const ES_DOINGS: Array = [["go", "to the beach"], ["wash", "the dishes"], ["catch", "the ball"], ["fly", "a kite"]]

## [base, -er, -est, level, a noun it fits]: 1 add -er or -est; 2 a spelling change; 3 more and most, irregular.
const ADJECTIVES: Array = [
	["tall", "taller", "tallest", 1, "tower"], ["fast", "faster", "fastest", 1, "horse"],
	["small", "smaller", "smallest", 1, "shell"], ["long", "longer", "longest", 1, "river"],
	["cold", "colder", "coldest", 1, "day"], ["kind", "kinder", "kindest", 1, "giant"],
	["big", "bigger", "biggest", 2, "box"], ["hot", "hotter", "hottest", 2, "day"], ["thin", "thinner", "thinnest", 2,
		"book"], ["happy", "happier", "happiest", 2, "puppy"], ["heavy", "heavier", "heaviest", 2, "bag"],
	["funny", "funnier", "funniest", 2, "joke"], ["nice", "nicer", "nicest", 2, "cake"], ["brave", "braver",
		"bravest", 2, "knight"], ["wide", "wider", "widest", 2, "road"],
	["beautiful", "more beautiful", "most beautiful", 3, "rainbow"], ["dangerous", "more dangerous", "most dangerous",
		3, "storm"], ["careful", "more careful", "most careful", 3, "builder"], ["good", "better", "best", 3, "idea"],
	["bad", "worse", "worst", 3, "storm"], ["exciting", "more exciting", "most exciting", 3, "story"],
]

## [sentence with ___, the joining word, wrongs, level].
const JOINS: Array = [
	["I like apples ___ pears.", "and", ["but", "because"], 1],
	["It was raining, ___ we took an umbrella.", "so", ["because", "if"], 1],
	["You can have juice ___ milk.", "or", ["because", "so"], 1],
	["The sun was shining, ___ it was very cold.", "but", ["so", "because"], 1],
	["I wanted to swim, ___ the pool was closed.", "but", ["so", "because"], 1],
	["The ice was thin, ___ we did not skate on it.", "so", ["or", "because"], 1],
	["We stayed inside ___ it was stormy.", "because", ["so", "but"], 2],
	["___ the bell rings, we line up.", "When", ["But", "Or"], 2],
	["___ it snows, we will build a snowman.", "If", ["But", "So"], 2],
	["The dog barked ___ it heard a knock.", "because", ["but", "or"], 2],
	["Put on your coat ___ you go out.", "before", ["but", "or"], 2],
	["Bram read a book ___ he waited for the bus.", "while", ["but", "so"], 3],
	["___ the box was heavy, Nell lifted it.", "Although", ["Because", "Unless"], 3],
	["You will get wet ___ you take a coat.", "unless", ["because", "and"], 3],
	["We can play outside ___ we finish lunch.", "after", ["but", "or"], 3],
	["Mimi stayed up ___ the stars came out.", "until", ["but", "or"], 3],
]

## Owners: [who, one owner (true) or more than one, a thing, level]: 1 one owner; 2 more than one, ending in s;
## 3 more than one, not ending in s (and one owner mixed in).
const OWNERS: Array = [
	["dog", true, "bone", 1], ["cat", true, "bowl", 1], ["bird", true, "nest", 1], ["teacher", true, "desk", 1],
	["girl", true, "bike", 1], ["farmer", true, "tractor", 1],
	["dogs", false, "bones", 2], ["girls", false, "bikes", 2], ["birds", false, "nests", 2], ["boys", false, "coats", 2],
	["horses", false, "saddles", 2], ["friends", false, "kites", 2],
	["children", false, "toys", 3], ["men", false, "boots", 3], ["women", false, "hats", 3], ["people", false, "homes", 3],
	["mice", false, "holes", 3], ["geese", false, "eggs", 3],
]

## Speech: [speaker, verb, words, end mark].
const SPEECH: Array = [
	["Zara", "said", "Let's build a boat", "."], ["Pip", "asked", "Can I help", "?"], ["Nell", "shouted", "Look out",
		"!"], ["Bram", "whispered", "The baby is asleep", "."], ["Mimi", "called", "Dinner is ready", "."],
	["Tilly", "asked", "Where is my map", "?"], ["Pip", "cried", "I found it", "!"], ["Nell", "said",
		"It is snowing", "."],
]

## [base, suffix, level, wrongs]: 1 just add; 2 drop the e or double the last letter; 3 y to i (or keep y before -ing).
const SUFFIXES: Array = [
	["jump", "ing", 1, ["jumpping", "jumpeing"]], ["play", "ed", 1, ["plaied", "playd"]],
	["help", "ful", 1, ["helpfull", "helpfel"]], ["kind", "ness", 1, ["kindnes", "kinness"]],
	["quick", "ly", 1, ["quickley", "quikly"]], ["sleep", "ing", 1, ["sleepping", "sleping"]],
	["hope", "ful", 1, ["hopful", "hopefull"]], ["care", "less", 1, ["carless", "careles"]],
	["make", "ing", 2, ["makeing", "makking"]], ["smile", "ed", 2, ["smileed", "smilled"]],
	["ride", "ing", 2, ["rideing", "ridng"]], ["hop", "ing", 2, ["hoping", "hopeing"]],
	["run", "ing", 2, ["runing", "runeing"]], ["swim", "ing", 2, ["swiming", "swimeing"]],
	["stop", "ed", 2, ["stoped", "stopt"]], ["clap", "ed", 2, ["claped", "clapt"]],
	["sit", "ing", 2, ["siting", "siteing"]], ["bake", "ed", 2, ["bakeed", "bakked"]],
	["hope", "ing", 2, ["hopeing", "hopping"]],
	["happy", "ness", 3, ["happyness", "happiess"]], ["cry", "ed", 3, ["cryed", "cryd"]],
	["carry", "ed", 3, ["carryed", "carred"]], ["easy", "ly", 3, ["easyly", "easly"]],
	["happy", "ly", 3, ["happyly", "happly"]], ["try", "ed", 3, ["tryed", "tryd"]],
	["cry", "ing", 3, ["criing", "cring"]], ["busy", "ly", 3, ["busyly", "busly"]],
	["fly", "ing", 3, ["fliing", "flyying"]],
]

## Words for alphabetical order: level 1 by the first letter; 2 some share a first letter; 3 the third letter decides.
const ALPHA_1: Array[String] = ["ant", "bee", "cat", "dog", "egg", "fox", "goat", "hat", "jam", "kite", "lamp", "moon",
	"nest", "owl", "pig", "rain", "sun", "tree", "van", "wolf", "zoo"]
const ALPHA_2: Array = [["bat", "bee", "bird", "bus", "boat"], ["cat", "chair", "cloud", "crab", "cup"],
	["sand", "seal", "ship", "snow", "sun"], ["tent", "tiger", "toad", "tree", "tulip"]]
const ALPHA_3: Array = [["stamp", "stick", "stone", "storm", "step"], ["bread", "brick", "brown", "brush", "brave"],
	["cream", "crab", "crisp", "crow", "crust"], ["plan", "plum", "plot", "plate", "plus"]]

## [word, what it means, wrongs, level].
const WORD_PARTS: Array = [
	["unkind", "not kind", ["very kind", "kind again"], 1], ["unhappy", "not happy", ["very happy", "happy again"], 1],
	["replay", "play again", ["not play", "play before"], 1], ["reread", "read again", ["not read", "read before"], 1],
	["helpful", "full of help", ["without help", "help again"], 1],
	["careless", "without care", ["full of care", "care again"], 1],
	["dislike", "not like", ["like again", "like before"], 2], ["preview", "view before", ["view again",
		"not view"], 2], ["fearless", "without fear", ["full of fear", "fear again"], 2],
	["hopeful", "full of hope", ["without hope", "hope again"], 2], ["washable", "can be washed",
		["cannot be washed", "washed again"], 2], ["teacher", "a person who teaches", ["teaching again",
		"not teaching"], 2], ["quickly", "in a quick way", ["not quick", "quick again"], 2],
	["unhelpful", "not helpful", ["full of help", "helping again"], 3], ["unbreakable", "cannot be broken",
		["can be broken", "broken again"], 3], ["reusable", "can be used again", ["cannot be used", "used before"], 3],
	["unkindly", "in an unkind way", ["in a kind way", "kind again"], 3], ["hopeless", "without hope",
		["full of hope", "hoping again"], 3], ["disagree", "not agree", ["agree again", "agree before"], 3],
	["preheat", "heat before", ["heat again", "not heat"], 3],
]

## Words split into syllables: level 1 one or two; 2 three; 3 four or five.
const SYLLABLES: Array = [
	["cat", 1], ["tree", 1], ["frog", 1], ["rab-bit", 1], ["gar-den", 1], ["pen-cil", 1], ["ap-ple", 1],
	["win-dow", 1], ["mon-key", 1],
	["but-ter-fly", 2], ["el-e-phant", 2], ["to-ma-to", 2], ["ba-na-na", 2], ["di-no-saur", 2], ["um-brel-la", 2],
	["com-pu-ter", 2], ["kan-ga-roo", 2], ["hol-i-day", 2],
	["cat-er-pil-lar", 3], ["wa-ter-mel-on", 3], ["hel-i-cop-ter", 3], ["al-li-ga-tor", 3], ["cal-cu-la-tor", 3],
	["hip-po-pot-a-mus", 3], ["tel-e-vi-sion", 3], ["av-o-ca-do", 3], ["cel-e-bra-tion", 3],
]

## [sentence, fact (true) or opinion, level].
const FACTS: Array = [
	["A spider has eight legs.", true, 1], ["The Sun is a star.", true, 1], ["A week has seven days.", true, 1],
	["Frogs lay eggs.", true, 1], ["Spiders are scary.", false, 1], ["Winter is the best season.", false, 1],
	["Pizza is the tastiest food.", false, 1], ["Rainy days are the worst.", false, 1],
	["Water freezes at 0 °C.", true, 2], ["Penguins cannot fly.", true, 2], ["Snow is frozen water.", true, 2],
	["Cats are nicer than dogs.", false, 2], ["Blue is the prettiest colour.", false, 2],
	["Football is boring.", false, 2],
	["A giraffe is the tallest animal.", true, 3], ["A cheetah can run faster than a horse.", true, 3],
	["A triangle has three sides.", true, 3], ["Giraffes are the most amazing animals.", false, 3],
	["Maths is the most fun subject.", false, 3], ["Owls are the loveliest birds.", false, 3],
]


# --- Nouns and pronouns (L.3.1b, L.3.1a) ---------------------------------------------------------------------------

## "What is the plural of \"fox\"?"
static func plural(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick(rng, NOUNS, level, 2)
	var one: String = row[0]
	var many: String = row[1]
	var wrongs: Array = row[3]
	var ex := K.choice(rng, "What is the plural of \"%s\"?  One %s, two ___." % [one, one], many,
		wrongs.slice(0, 2 if level < 3 else 3), _plural_hint(one, many),
		"One %s, two %s." % [one, many])
	ex.data = {"one": one}
	return ex


## "Zara found a shell. ___ kept it." (the pronoun that stands for the noun)
static func pronoun(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick(rng, PRONOUNS, level, 3)
	var sentence: String = row[0]
	var right: String = row[1]
	var ex := K.choice(rng, "Which pronoun fits?  %s" % sentence, right, row[2],
		"Who or what does the missing word stand for? One or more than one? Before or after the verb?",
		sentence.replace("___", right))
	ex.data = {"sentence": sentence, "pronoun": right}
	return ex


# --- Verbs (L.3.1d, L.3.1e, L.3.1f) --------------------------------------------------------------------------------

## "Today I swim. Yesterday I ___." (the past tense)
static func past_tense(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick(rng, VERBS, level, 2)
	var base: String = row[0]
	var past: String = row[1]
	var ex := K.choice(rng, "Choose the past tense.  Today I %s. Yesterday I ___." % base, past, row[3],
		_past_hint(base, past), "Today I %s; yesterday I %s." % [base, past])
	ex.data = {"base": base}
	return ex


## "The dog ___ in the park." (the verb agrees with its subject; level 3: am, is, are and -es verbs)
static func verb_agree(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var subj: Array = _pick(rng, SUBJECTS, level, 2)
	var who: String = subj[0]
	var one: bool = subj[1] and who != "I" and who != "You"
	var ex: Dictionary
	if level == 3 and rng.randf() < 0.4:
		var be := "am" if who == "I" else ("is" if one else "are")
		ex = K.choice(rng, "Which word fits?  %s ___ ready for the trip." % who, be, ["am", "is", "are"].filter(
			func(w: String) -> bool: return w != be), "Use am with I, is with one, are with you and more than one.",
			"%s %s ready for the trip." % [who, be])
		ex.data = {"subject": who, "one": one, "verb": "be"}
		return ex
	var pool: Array = DOINGS.duplicate()
	if level == 3:
		pool.append_array(ES_DOINGS)
	var doing: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var verb: String = doing[0]
	var right := _s_form(verb) if one else verb
	var wrong := verb if one else _s_form(verb)
	ex = K.choice(rng, "Which word fits?  %s ___ %s." % [who, doing[1]], right, [wrong],
		"Is the subject one, or more than one? One takes -s or -es; more than one, I and you do not.",
		"%s %s %s." % [who, right, doing[1]])
	ex.data = {"subject": who, "one": one, "verb": verb}
	return ex


# --- Describing words (L.3.1g) -------------------------------------------------------------------------------------

## "This tower is ___ than that one. (tall)" or "This tower is the ___ of all. (tall)"
static func compare(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick(rng, ADJECTIVES, level, 3)
	var base: String = row[0]
	var two := rng.randf() < 0.5
	var right: String = row[1] if two else row[2]
	var other: String = row[2] if two else row[1]
	var made: String
	if right.begins_with("more ") or right.begins_with("most "):
		made = base + ("er" if two else "est")
	elif base in ["good", "bad"]:
		made = base + ("er" if two else "est")
	else:
		made = ("more " if two else "most ") + base
	var prompt := "This %s is ___ than that one. (%s)" % [row[4], base] if two \
		else "This %s is the ___ of them all. (%s)" % [row[4], base]
	var ex := K.choice(rng, prompt, right, [other, made],
		"Two things: -er or more. Three or more: -est or most. Long words use more and most.",
		prompt.left(prompt.find(" (")).replace("___", right))
	ex.data = {"base": base, "two": two}
	return ex


# --- Joining sentences (L.3.1h, L.3.1i) ----------------------------------------------------------------------------

## "Choose the joining word: It was raining, ___ we took an umbrella."
static func conjunction(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick(rng, JOINS, level, 3)
	var sentence: String = row[0]
	var right: String = row[1]
	var ex := K.choice(rng, "Choose the joining word:  %s" % sentence, right, row[2],
		"And adds, but shows a difference, so gives a result, because gives a reason, and when, if, while, before, "
		+ "after and until tell when or what must happen first.", sentence.replace("___", right))
	ex.data = {"sentence": sentence, "word": right}
	return ex


# --- Punctuation (L.3.2c, L.3.2d) ----------------------------------------------------------------------------------

## "The bone belongs to one dog. Which is right?" (the apostrophe for owning)
static func possessive(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick(rng, OWNERS, level, 3)
	var who: String = row[0]
	var one: bool = row[1]
	var thing: String = row[2]
	var right := "the %s %s" % [_owner(who, one), thing]
	var wrongs: Array
	if one:   # "the dogs bone", "the dogs' bone"
		wrongs = ["the %ss %s" % [who, thing], "the %ss' %s" % [who, thing]]
	elif who.ends_with("s"):   # "the girls bikes", "the girl's bikes"
		wrongs = ["the %s %s" % [who, thing], "the %s's %s" % [who.left(-1), thing]]
	else:   # "the childrens toys", "the childrens' toys"
		wrongs = ["the %ss %s" % [who, thing], "the %ss' %s" % [who, thing]]
	var ex := K.choice(rng, "The %s %s to %s. Which is right?" % [thing, "belongs" if not thing.ends_with("s") else
		"belong", ("one %s" % who) if one else "the %s (more than one)" % who], right, wrongs,
		"One owner: add 's. More than one owner ending in s: add ' after the s. A plural without s: add 's.",
		"%s: %s." % [_cap(right), "one owner, so add 's" if one else ("the owners end in s, so the apostrophe "
			+ "goes after the s" if who.ends_with("s") else "%s has no s, so add 's" % who)])
	ex.data = {"who": who, "one": one, "thing": thing}
	return ex


## "Which is punctuated correctly?" (speech marks: level 1-2 the speaker first, level 3 the speech first)
static func speech_marks(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = SPEECH[rng.randi_range(0, SPEECH.size() - 1)]
	var who: String = row[0]
	var verb: String = row[1]
	var words: String = row[2]
	var mark: String = row[3]
	var first := level == 3
	var right := _speech(who, verb, words, mark, first)
	var wrongs: Array = []
	if first:
		var inner := "," if mark == "." else mark
		wrongs.append("%s%s %s %s." % [words, inner, verb, who])                    # no speech marks
		if mark == ".":
			wrongs.append("\"%s.\" %s %s." % [words, verb, who])                    # a full stop, not a comma
		else:
			wrongs.append("\"%s\"%s %s %s." % [words, mark, verb, who])             # the mark outside
		wrongs.append("\"%s%s %s %s.\"" % [words, inner, verb, who])                # marks round the wrong words
	else:
		wrongs.append("%s %s, %s%s" % [who, verb, words, mark])                     # no speech marks
		wrongs.append("%s %s, \"%s%s" % [who, verb, words, mark])                   # no closing mark
		wrongs.append("\"%s %s,\" %s%s" % [who, verb, words, mark])                 # marks round the wrong words
	K.shuffle(rng, wrongs)
	var ex := K.choice(rng, "%s %s something. Which is punctuated correctly?" % [who, "asks" if mark == "?" else
		"says"], right, wrongs.slice(0, 2 if level == 1 else 3),
		"Speech marks go round the spoken words only, and the spoken words' punctuation goes inside them.", right)
	ex.data = {"who": who, "verb": verb, "words": words, "mark": mark, "first": first}
	return ex


# --- Spelling (L.3.2e, L.3.2f, L.3.2g) -----------------------------------------------------------------------------

## "Add -ing to \"run\"." (the spelling rules for endings)
static func add_suffix(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick(rng, SUFFIXES, level, 2)
	var base: String = row[0]
	var suffix: String = row[1]
	var right := _add(base, suffix)
	var ex := K.choice(rng, "Add \"-%s\" to \"%s\". Which spelling is right?" % [suffix, base], right, row[3],
		"Does the word end in e? In one vowel and one consonant? In a consonant and y?",
		"%s + %s = %s%s" % [base, suffix, right, _rule(base, suffix)])
	ex.data = {"base": base, "suffix": suffix}
	return ex


## "Put these words in alphabetical order." (level 1: first letters; 2: the second letter; 3: the third)
static func alpha_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var words: Array = []
	if level == 1:
		words.append_array(ALPHA_1)
		K.shuffle(rng, words)
		words = words.slice(0, 4)
	else:
		var sets: Array = ALPHA_2 if level == 2 else ALPHA_3
		words.append_array(sets[rng.randi_range(0, sets.size() - 1)])
		K.shuffle(rng, words)
		words = words.slice(0, 4)
	var sorted := words.duplicate()
	sorted.sort()
	var ex := K.order(rng, "Put these words in alphabetical order, like a dictionary.", sorted,
		"Look at the first letter. If two are the same, look at the next letter.", "%s." % ", ".join(sorted))
	ex.data = {"words": words}
	return ex


# --- Word building (L.3.4b, RF.3.3) --------------------------------------------------------------------------------

## "What does \"unkind\" mean?"
static func word_part(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick(rng, WORD_PARTS, level, 3)
	var ex := K.choice(rng, "What does \"%s\" mean?" % row[0], str(row[1]), row[2],
		"Find the root word, then the prefix (un-, re-, dis-, pre-) or suffix (-ful, -less, -ly, -able, -er).",
		"\"%s\" means %s." % [row[0], row[1]])
	ex.data = {"word": row[0], "meaning": row[1]}
	return ex


## "How many syllables are in \"caterpillar\"? Clap it!"
static func syllables(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick(rng, SYLLABLES, level, 1)
	var split: String = row[0]
	var word := split.replace("-", "")
	var n := split.split("-").size()
	var ex := K.number("How many syllables are in \"%s\"? Clap it!" % word, n,
		"Say the word slowly and clap each beat. Every beat has a vowel sound.", "%s: %d syllable%s." % [split, n,
		"" if n == 1 else "s"])
	ex.data = {"split": split}
	return ex


# --- Writing (W.3.1, W.3.2) ----------------------------------------------------------------------------------------

## "Fact or opinion?  Spiders are scary." (level 3: which one is a fact, or which one is an opinion)
static func fact_opinion(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level < 3:
		var row: Array = _pick(rng, FACTS, level, 2)
		var right := "a fact" if row[1] else "an opinion"
		var ex := K.choice(rng, "Fact or opinion?  \"%s\"" % row[0], right, ["an opinion" if row[1] else "a fact"],
			"Can it be checked and proved true? Or is it what someone thinks or feels?",
			"\"%s\" is %s." % [row[0], "a fact: it can be checked" if row[1] else "an opinion: someone thinks it"])
		ex.data = {"sentences": [row[0]], "facts": [row[1]]}
		return ex
	var facts: Array = FACTS.filter(func(r: Array) -> bool: return r[1])
	var opinions: Array = FACTS.filter(func(r: Array) -> bool: return not r[1])
	K.shuffle(rng, facts)
	K.shuffle(rng, opinions)
	var want_fact := rng.randf() < 0.5
	var right: String = (facts[0] if want_fact else opinions[0])[0]
	var wrongs: Array = (opinions if want_fact else facts).slice(0, 2).map(func(r: Array) -> String: return r[0])
	var ex := K.choice(rng, "Which one is %s?" % ("a fact" if want_fact else "an opinion"), right, wrongs,
		"A fact can be checked. An opinion is what someone thinks, often with words like best, nicer or scary.",
		"\"%s\" is %s." % [right, "a fact" if want_fact else "an opinion"])
	ex.data = {"sentences": [right] + wrongs, "facts": [want_fact, not want_fact, not want_fact]}
	return ex


# --- Helpers -------------------------------------------------------------------------------------------------------

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


static func _vowel(c: String) -> bool:
	return "aeiou".contains(c)


static func _plural_hint(one: String, many: String) -> String:
	if many == one:
		return "Some words stay the same for more than one."
	if not many.begins_with(one.left(-1)) or many.length() < one.length():
		return "This one is irregular: it changes in its own way."
	if many.ends_with("ves"):
		return "Some words ending in f or fe change to -ves."
	if many.ends_with("ies"):
		return "A consonant and then y: change the y to -ies."
	if many.ends_with("es"):
		return "Words ending in s, x, ch or sh add -es."
	return "Most words just add -s."


static func _past_hint(base: String, past: String) -> String:
	if not past.ends_with("ed"):
		return "This verb is irregular: it changes in its own way."
	if past.ends_with("ied"):
		return "A consonant and then y: change the y to i and add -ed."
	if base.ends_with("e"):
		return "It ends in e: just add -d."
	if past.length() == base.length() + 3:
		return "One short vowel and one last consonant: double the last letter, then add -ed."
	return "Just add -ed."


## The -s form of a verb: "plays", "goes", "washes", "flies".
static func _s_form(verb: String) -> String:
	if verb.ends_with("sh") or verb.ends_with("ch") or verb.ends_with("s") or verb.ends_with("x") or verb.ends_with("o"):
		return verb + "es"
	if verb.ends_with("y") and not _vowel(verb[verb.length() - 2]):
		return verb.left(-1) + "ies"
	return verb + "s"


## "dog" -> "dog's", "girls" -> "girls'", "children" -> "children's"
static func _owner(who: String, one: bool) -> String:
	return who + "'" if not one and who.ends_with("s") else who + "'s"


## Speech punctuated: `Zara said, "Let's go."` or (first) `"Let's go," said Zara.`
static func _speech(who: String, verb: String, words: String, mark: String, first: bool) -> String:
	if first:
		return "\"%s%s\" %s %s." % [words, "," if mark == "." else mark, verb, who]
	return "%s %s, \"%s%s\"" % [who, verb, words, mark]


## The base with the suffix, by the spelling rules.
static func _add(base: String, suffix: String) -> String:
	var starts_vowel := _vowel(suffix[0])
	var last := base[base.length() - 1]
	if last == "y" and not _vowel(base[base.length() - 2]) and suffix != "ing":
		return base.left(-1) + "i" + suffix
	if starts_vowel and last == "e":
		return base.left(-1) + suffix
	if starts_vowel and _short(base):
		return base + last + suffix
	return base + suffix


## One vowel, then one last consonant (not w, x or y): "hop", "swim".
static func _short(base: String) -> bool:
	var vowels := 0
	for c in base:
		if _vowel(c):
			vowels += 1
	var n := base.length()
	return vowels == 1 and n >= 3 and not _vowel(base[n - 1]) and _vowel(base[n - 2]) and not _vowel(base[n - 3]) \
		and not "wxy".contains(base[n - 1])


static func _rule(base: String, suffix: String) -> String:
	var right := _add(base, suffix)
	if right == base + suffix:
		return " (just add it)."
	if right.contains("i" + suffix) and base.ends_with("y"):
		return " (change the y to i)."
	if base.ends_with("e"):
		return " (drop the e)."
	return " (double the last letter)."
