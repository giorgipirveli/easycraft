class_name G4CoreGen
extends RefCounted
## Owner #70 and #73 (research §6.4): grade 4 science and English generators for the research's new units: will this
## circuit work (a switch, a gap, something across it), conductors and insulators; reading a thermometer (below 0 at
## level 3), how much warmer or colder, which way heat flows (from the warmer thing, even between two icy things);
## solid, liquid or gas at a temperature (water, then metals by their melting points), which change of state an everyday
## event is; the loudest, quietest, highest or lowest sound's wave; the food's path through the digestive system; and in
## English: phrases from myths (a Herculean task), first-hand and second-hand accounts, and linking words for an
## opinion. SchoolGen "g4c.<name>", `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded,
## level 1-3, each with a hint (a strategy), a worked answer and `data` (its inputs, for tests/unit/test_g4_core_gen.gd,
## which checks every answer with its own facts). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")

## Things to sort, and to lay across a circuit's gap ([what, its short name for the picture]).
const CONDUCTORS: Array = [["a copper wire", "copper wire"], ["a steel spoon", "steel spoon"], ["an iron nail", "iron nail"],
	["aluminium foil", "foil"], ["a gold ring", "gold ring"], ["a brass key", "brass key"],
	["a steel paper clip", "paper clip"], ["a metal coin", "metal coin"]]
const INSULATORS: Array = [["a plastic ruler", "plastic ruler"], ["a rubber band", "rubber band"],
	["a wooden spoon", "wooden spoon"], ["a glass marble", "glass marble"], ["a paper straw", "paper straw"],
	["a cotton sock", "cotton sock"], ["a woolly glove", "woolly glove"], ["a cork", "cork"], ["a china plate", "china plate"],
	["a plastic cup", "plastic cup"]]
## A circuit's parts and what they do when the loop is complete: [part, the statement for one, for two].
const DOES := {"bulb": ["the bulb lights up", "both bulbs light up"], "buzzer": ["the buzzer buzzes", ""],
	"motor": ["the motor spins", ""]}
## Thermometer scales: [from, to, step, small marks between the numbers], by level.
const SCALES: Array = [
	[[0, 50, 10, 0], [0, 100, 10, 0], [0, 40, 5, 0]],
	[[0, 50, 10, 4], [0, 100, 10, 1], [20, 45, 5, 4]],
	[[-20, 20, 10, 4], [-10, 15, 5, 4], [-30, 30, 10, 1]],
]
## Warmer and colder stories: [the start, the end, the question], levels 1-2 (above 0) and 3 (across 0).
const WARMER: Array = [
	["At 9:00 the thermometer in the garden showed {a} °C.", "At 13:00 it showed {b} °C.", "How many degrees warmer was it at 13:00?"],
	["The water in the paddling pool was {a} °C in the morning.", "By the afternoon it was {b} °C.",
		"How many degrees warmer was the water?"],
	["Mimi's greenhouse was {a} °C at dawn.", "At noon it was {b} °C.", "How many degrees warmer was it at noon?"],
]
const COLDER: Array = [
	["A mug of cocoa was {a} °C.", "Twenty minutes later it was {b} °C.", "How many degrees colder was the cocoa?"],
	["At 15:00 the thermometer showed {a} °C.", "At 21:00 it showed {b} °C.", "How many degrees colder was it at 21:00?"],
	["A bowl of soup was {a} °C.", "After lunch it had cooled to {b} °C.", "How many degrees colder was the soup?"],
]
## Which way heat flows: [a thing, its short name for the choices, °C] pairs (level 1), and icy pairs (level 3).
const HEAT_PAIRS: Array = [
	[["a metal spoon", "the spoon", 20], ["hot soup", "the soup", 80]],
	[["an ice cube", "the ice cube", -5], ["a glass of juice", "the juice", 15]],
	[["your hand", "your hand", 30], ["a snowball", "the snowball", 0]],
	[["a baking tray from the oven", "the tray", 180], ["a wooden board", "the board", 20]],
	[["a cold can of juice", "the can", 5], ["Tilly's warm hand", "Tilly's hand", 32]],
	[["a hot water bottle", "the bottle", 50], ["a cold bed", "the bed", 12]],
]
const ICY_PAIRS: Array = [
	[["a block of ice", "the ice", -5], ["the freezer shelf", "the shelf", -18]],
	[["a snowball", "the snowball", -2], ["an icy path", "the path", -9]],
	[["an ice lolly", "the lolly", -12], ["a frozen pea", "the pea", -18]],
	[["an icicle", "the icicle", -3], ["the frozen roof", "the roof", -10]],
]
## Melting points in °C (water also boils at 100 °C).
const MELTING := {"gold": 1064, "iron": 1538, "aluminium": 660, "tin": 232}
## Everyday events and their change of state, by level (level 3 also draws from level 2).
const CHANGE_EVENTS: Array = [
	[["An ice lolly drips on a hot day.", "melting"], ["Water in a tray turns to ice in the freezer.", "freezing"],
		["Snow turns to water in the spring sunshine.", "melting"], ["A pond turns to ice on a frosty night.", "freezing"],
		["Butter goes runny in a hot pan.", "melting"], ["Juice in a mould turns into an ice lolly.", "freezing"]],
	[["A puddle dries up in the sun.", "evaporating"], ["Drops of water form on a cold window.", "condensing"],
		["Wet washing dries on a line.", "evaporating"], ["A mirror mists up after a hot bath.", "condensing"],
		["A cold can of juice gets wet on the outside.", "condensing"], ["Sweat dries on your skin.", "evaporating"]],
	[["Water bubbles in a pan at 100 °C and turns to steam.", "boiling"],
		["Dew forms on the grass on a cool morning.", "condensing"], ["Hot, runny iron cools into a solid bar.", "freezing"],
		["Chocolate goes runny in a warm hand.", "melting"], ["A kettle's water bubbles hard and steam pours out.", "boiling"],
		["Seawater in a shallow pool dries up, leaving salt.", "evaporating"],
		["A glass of iced water gets wet on the outside.", "condensing"]],
]
const CHANGE_WORDS := {"melting": "a solid turns into a liquid", "freezing": "a liquid turns into a solid",
	"evaporating": "a liquid turns into a gas", "condensing": "a gas turns back into a liquid",
	"boiling": "a liquid turns into a gas all through it, with bubbles"}
## The food's path, mouth first.
const PATH: Array[String] = ["mouth", "gullet", "stomach", "small intestine", "large intestine", "rectum"]
## Phrases from Greek myths: [the phrase, its key words, what it means, where it comes from, two sentences using it].
const PHRASES: Array = [
	["a Herculean task", "Herculean task", "a very hard job", "Hercules had to do twelve almost impossible labours.",
		["Clearing the snow from the whole village was a Herculean task.",
		"Carrying every block up the tower by hand was a Herculean task."]],
	["an Achilles' heel", "Achilles' heel", "a weak spot", "Achilles could only be hurt on his heel.",
		["Tilly is a great swimmer, but diving is her Achilles' heel.",
		"The castle was strong, but its old back gate was its Achilles' heel."]],
	["Pandora's box", "Pandora's box", "the start of many troubles",
		"Pandora opened a box she was told to keep shut, and troubles flew out.",
		["Letting all the puppies in at once opened Pandora's box.",
		"Changing the rules halfway through the game opened Pandora's box."]],
	["the Midas touch", "Midas touch", "success at everything", "Everything King Midas touched turned to gold.",
		["Every seed Zara plants grows well: she has the Midas touch.",
		"The new bakery has the Midas touch: everything it bakes sells out."]],
	["an odyssey", "odyssey", "a long, adventurous journey", "Odysseus took ten years to sail home.",
		["Their walk all the way round the island was an odyssey.", "Getting home through the snowstorm was a real odyssey."]],
]
## Sentences from first-hand accounts (the writer was there) and second-hand ones (from what others found out).
const FIRST_HAND: Array[String] = ["I felt the ground shake under my feet.", "We heard the thunder crash right above us.",
	"My hands were shaking as I opened the letter.", "I saw the river rise over the path.",
	"We cheered as the rocket lifted off.", "The smoke made my eyes sting.", "I could smell bread baking in our street.",
	"Our boat rocked as the big wave passed.", "The snow came up to my knees."]
const SECOND_HAND: Array[String] = ["Historians say the city grew very fast.", "The report says 20 homes were flooded.",
	"Records show the bridge opened in 1894.", "People who were there said the crowd cheered.",
	"The book explains why the volcano erupted.", "Scientists found the storm lasted six hours.",
	"According to the museum, the ship sank in 1628.", "Old newspapers said the winter was harsh.",
	"A news report says the fire began at noon."]
## Linking words: [the sentence with ___, what it needs, the right words, three words that do not fit, level].
const LINKS: Array = [
	["Dogs are loyal. ___, a dog will wait by the door for you.", "an example", "For example",
		["In conclusion", "However", "Because"], 1],
	["I love winter ___ I can build snowmen.", "a reason", "because", ["however", "for example", "in conclusion"], 1],
	["The last sentence: \"___, a school garden would help everyone.\"", "an ending", "In conclusion",
		["For example", "Once upon a time", "Because"], 1],
	["Museums show real objects. ___, we could see an ancient mummy case.", "an example", "For example",
		["In conclusion", "However", "Because"], 1],
	["Reading is fun. ___, it teaches us new words.", "another reason", "In addition",
		["For example", "However", "Because"], 2],
	["Cycling keeps us fit. ___, it does not make the air dirty.", "another reason", "Also",
		["For example", "In conclusion", "Because"], 2],
	["Walking to school is good for us. ___, it is good for the planet.", "another reason", "In addition",
		["For example", "In order to", "Because"], 2],
	["Our town needs a library ___ children can borrow books for free.", "a purpose", "so that",
		["for example", "in conclusion", "however"], 2],
	["We need a crossing ___ keep children safe on the road.", "a purpose", "in order to",
		["for example", "in addition", "however"], 3],
	["Many animals live in hedges. ___, hedgehogs and wrens shelter there.", "an example", "For instance",
		["In conclusion", "However", "In order to"], 3],
	["Some people say pets are hard work. ___, the fun they bring is worth it.", "a different side", "However",
		["For example", "In addition", "In order to"], 3],
	["The ending: \"___, every class should have a pet fish.\"", "an ending", "To sum up",
		["For example", "Once upon a time", "In order to"], 3],
]


# --- Circuits ----------------------------------------------------------------------------------------------------------

## Will this circuit work? True or false, from its picture: a switch open or closed (level 1); a gap too, and bulbs,
## buzzers or motors (level 2); something laid across the gap, a conductor or an insulator (level 3).
static func circuit_lights(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var kind: String = "bulb" if level == 1 else ["bulb", "bulb", "buzzer", "motor"][rng.randi_range(0, 3)]
	var two: bool = kind == "bulb" and level > 1 and rng.randf() < 0.3
	var parts: Array = [kind, kind] if two else [kind]
	var pic := {"kind": "lab_circuit", "parts": parts, "glow": "?"}
	var sw: String = ["open", "closed", ""][rng.randi_range(0, 2)]
	if level == 3:
		sw = ["closed", "", "", "open"][rng.randi_range(0, 3)]
	if sw != "":
		pic.switch = sw
	var gap := level == 3 or (level == 2 and rng.randf() < 0.5)
	var bridge: Array = []
	var conducts := false
	if gap:
		pic.gap = true
	if level == 3:
		conducts = rng.randf() < 0.5
		var bank: Array = CONDUCTORS if conducts else INSULATORS
		bridge = bank[rng.randi_range(0, bank.size() - 1)]
		pic.bridge = bridge[1]
	var works: bool = sw != "open" and (not gap or conducts)
	var does := str(DOES[kind][1 if two else 0])
	var why: String
	if sw == "open":
		why = "The switch is open, so the loop is broken%s: no electricity flows." % (
			", even with %s in the gap" % bridge[0] if conducts else "")
	elif gap and bridge.is_empty():
		why = "There is a gap in the wire, so the loop is broken: no electricity flows."
	elif gap and not conducts:
		why = "%s is an insulator: it does not let electricity through, so the gap stays open." % _cap(bridge[0])
	elif gap:
		why = "%s is a metal, a conductor: it closes the gap, so the loop is complete and %s." % [_cap(bridge[0]), does]
	else:
		why = "The loop is complete%s, so electricity flows all the way round and %s." % [
			" and the switch is closed" if sw == "closed" else "", does]
	var hint := "Follow the wire all the way round from the battery. Is there a gap anywhere?"
	if level == 3:
		hint += " Is the thing in the gap a metal?"
	var ex := K.truefalse("In this circuit, %s." % does, works, hint, why, pic)
	ex.data = {"parts": parts, "switch": sw, "gap": gap, "bridge": str(bridge[0]) if not bridge.is_empty() else "",
		"conducts": conducts}
	return ex


## Sort things into conductors and insulators of electricity: 4, 5 or 6 of them.
static func conductor_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := level + 3
	var metal := rng.randi_range(2, n - 2)
	var yes := _pick(rng, CONDUCTORS, metal)
	var no := _pick(rng, INSULATORS, n - metal)
	var items: Array = []
	for x: Array in yes:
		items.append([x[0], 0])
	for x: Array in no:
		items.append([x[0], 1])
	K.shuffle(rng, items)
	var names: Array = []
	var answer: Array = []
	for x: Array in items:
		names.append(x[0])
		answer.append(x[1])
	var yes_names: Array[String] = []
	var no_names: Array[String] = []
	for x: Array in yes:
		yes_names.append(str(x[0]))
	for x: Array in no:
		no_names.append(str(x[0]))
	var ex := {"type": "sort", "prompt": "Sort them: which let electricity through (conductors), and which do not (insulators)?",
		"groups": ["conductor", "insulator"], "items": names, "answer": answer,
		"hint": "What is each thing made of? Test it in your head in a circuit's gap: would the bulb light?",
		"explain": "Conductors (metals): %s. Insulators: %s." % [", ".join(yes_names), ", ".join(no_names)]}
	ex.data = {"items": names}
	return ex


# --- Heat and temperature ----------------------------------------------------------------------------------------------

## Read a thermometer in °C: numbers only (level 1); small marks worth 1, 2 or 5 degrees (level 2); below zero too
## (level 3).
static func thermo_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var scales: Array = SCALES[level - 1]
	var sc: Array = scales[rng.randi_range(0, scales.size() - 1)]
	var from: int = sc[0]
	var to: int = sc[1]
	var step: int = sc[2]
	var minor: int = sc[3]
	var mark := step / (minor + 1)
	var marks := (to - from) / mark
	var value := from + mark * rng.randi_range(0 if level > 1 else 1, marks - (0 if level > 1 else 1))
	if level == 3 and rng.randf() < 0.6 and value >= 0:   # most level 3 readings are below zero
		value = from + mark * rng.randi_range(1, (0 - from) / mark - 1)
	var pic := {"kind": "thermometer", "from": from, "to": to, "step": step, "value": value}
	if minor > 0:
		pic.minor = minor
	var hint := "Find the top of the red liquid, then read the scale beside it."
	if minor > 0:
		hint = "Each small mark is %d degree%s. Find the number just below the top of the red liquid and count up the marks." % [
			mark, "" if mark == 1 else "s"]
	if level == 3:
		hint += " Below 0 the numbers go down: −2 is colder than −1."
	var ex := K.number("What temperature does the thermometer show, in °C?%s" % (
		" (Below 0, type the minus sign.)" if level == 3 else ""), str(value), hint,
		"The red liquid stops at %s °C." % SchoolPictureG4Core.degrees(value), pic)
	ex.data = {"from": from, "to": to, "step": step, "minor": minor, "value": value}
	return ex


## How many degrees warmer or colder: above zero (levels 1-2; level 1 in 5s and warmer only), across zero (level 3).
static func temp_change(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var warmer := level == 1 or rng.randf() < 0.5
	var a: int
	var b: int
	if level == 1:
		a = rng.randi_range(1, 4) * 5
		b = a + rng.randi_range(1, 4) * 5
	elif level == 2 and warmer:
		a = rng.randi_range(8, 19)
		b = a + rng.randi_range(3, 14)
	elif level == 2:
		a = rng.randi_range(55, 90)
		b = a - rng.randi_range(12, 38)
	else:
		var low := -rng.randi_range(2, 12)
		var high := rng.randi_range(2, 14)
		a = low if warmer else high
		b = high if warmer else low
	var story: Array
	if level == 3:
		story = ["At 6:00 the thermometer showed {a} °C.", "At 14:00 it showed {b} °C.",
			"How many degrees warmer was it at 14:00?"] if warmer else ["At 16:00 the thermometer showed {a} °C.",
			"By midnight it showed {b} °C.", "How many degrees colder was it at midnight?"]
	else:
		var bank: Array = WARMER if warmer else COLDER
		story = bank[rng.randi_range(0, bank.size() - 1)]
	var words := {"a": SchoolPictureG4Core.degrees(a), "b": SchoolPictureG4Core.degrees(b)}
	var prompt := "%s %s %s" % [str(story[0]).format(words), str(story[1]).format(words), story[2]]
	var diff := absi(b - a)
	var explain: String
	var hint := "Count on from the lower temperature to the higher one."
	if level == 3:
		var below := -mini(a, b)
		var above := maxi(a, b)
		hint = "Count from the temperature below 0 up to 0, then on from 0 to the other one."
		explain = "From −%d °C up to 0 °C is %d degrees, and from 0 °C to %d °C is %d more: %d + %d = %d degrees." % [below,
			below, above, above, below, above, diff]
	else:
		explain = "%d − %d = %d degrees." % [maxi(a, b), mini(a, b), diff]
	var ex := K.number(prompt, diff, hint, explain)
	ex.data = {"a": a, "b": b}
	return ex


## Which way does heat flow between two things? Named things at their temperatures (level 1), two blocks, sometimes at
## the same temperature (level 2), two icy things both below zero (level 3: the less cold one gives heat).
static func heat_flow(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a: Array
	var b: Array
	if level == 2:
		var ta := rng.randi_range(5, 60)
		var tb := ta if rng.randf() < 0.2 else rng.randi_range(5, 60)
		if tb == ta and rng.randf() < 0.5:
			tb = ta + rng.randi_range(3, 20)
		a = ["block A", "block A", ta]
		b = ["block B", "block B", tb]
	else:
		var pairs: Array = HEAT_PAIRS if level == 1 else ICY_PAIRS
		var pair: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
		a = pair[0]
		b = pair[1]
		if rng.randf() < 0.5:
			var s := a
			a = b
			b = s
	var prompt := "%s at %s °C touches %s at %s °C. Which way does heat flow?" % [_cap(a[0]),
		SchoolPictureG4Core.degrees(int(a[2])), b[0], SchoolPictureG4Core.degrees(int(b[2]))]
	var ab := "from %s into %s" % [a[1], b[1]]
	var ba := "from %s into %s" % [b[1], a[1]]
	var none := "Heat does not flow between them."
	var right := ab if int(a[2]) > int(b[2]) else ba if int(b[2]) > int(a[2]) else none
	var explain := none.trim_suffix(".") + ": they are at the same temperature."
	if right != none:
		var hot: Array = a if int(a[2]) > int(b[2]) else b
		var cold: Array = b if hot == a else a
		explain = "Heat flows from the warmer thing to the colder one: %s is %s °C and %s is %s °C, so heat flows %s." % [
			hot[1], SchoolPictureG4Core.degrees(int(hot[2])), cold[1], SchoolPictureG4Core.degrees(int(cold[2])), right]
	var hint := "Which of the two is warmer? Heat always flows from warmer to colder."
	if level == 3:
		hint += " Below zero, −5 °C is warmer than −18 °C."
	var ex := K.choice(rng, prompt, right, [ab, ba, none], hint, explain)
	ex.data = {"a": [a[1], int(a[2])], "b": [b[1], int(b[2])]}
	return ex


# --- Solids, liquids and gases -----------------------------------------------------------------------------------------

## Solid, liquid or gas? Water far from 0 °C and 100 °C (level 1), just either side of them (level 2), metals by their
## melting points (level 3).
static func state_at(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var thing := "water"
	var t: int
	var melt := 0
	if level == 1:
		t = [rng.randi_range(-18, -4), rng.randi_range(8, 90), rng.randi_range(106, 120)][rng.randi_range(0, 2)]
	elif level == 2:
		t = [rng.randi_range(-3, -1), rng.randi_range(1, 4), rng.randi_range(96, 99), rng.randi_range(101, 104)][rng.randi_range(0, 3)]
	else:
		var names: Array = MELTING.keys()
		thing = names[rng.randi_range(0, names.size() - 1)]
		melt = MELTING[thing]
		var off := rng.randi_range(30, 300)
		t = melt - off if rng.randf() < 0.5 else melt + off
		t = maxi(20, t)
		if t == melt:
			t = melt + 50
	var state: String
	if thing == "water":
		state = "solid" if t < 0 else "gas" if t > 100 else "liquid"
	else:
		state = "solid" if t < melt else "liquid"
	var prompt: String
	var hint: String
	var explain: String
	if thing == "water":
		prompt = "What state is water in at %s °C?" % SchoolPictureG4Core.degrees(t)
		hint = "Ice melts at 0 °C and water boils at 100 °C. Is %s °C below 0, between them or above 100?" % \
			SchoolPictureG4Core.degrees(t)
		explain = "%s °C is %s, so it is %s." % [SchoolPictureG4Core.degrees(t), "below 0 °C" if t < 0 else
			"above 100 °C" if t > 100 else "between 0 °C and 100 °C", "a solid: ice" if state == "solid" else
			"a gas: steam (water vapour)" if state == "gas" else "a liquid: water"]
	else:
		prompt = "%s melts at %s °C. What state is %s in at %s °C?" % [thing.capitalize(), K.fmt(melt), thing, K.fmt(t)]
		hint = "Is %s °C below the melting point or above it?" % K.fmt(t)
		explain = "%s °C is %s %s's melting point, %s °C, so it is a %s." % [K.fmt(t), "below" if t < melt else "above",
			thing, K.fmt(melt), state]
	var ex := K.choice(rng, prompt, state, ["solid", "liquid", "gas"], hint, explain)
	ex.data = {"thing": thing, "t": t}
	return ex


## Which change of state is this everyday event? Melting or freezing (level 1, 2 choices); evaporating and condensing too
## (level 2, 4 choices); boiling too, and trickier events (level 3, 5 choices).
static func state_change(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var bank: Array = (CHANGE_EVENTS[level - 1] as Array).duplicate()
	if level == 3:
		bank.append_array(CHANGE_EVENTS[1])
	var event: Array = bank[rng.randi_range(0, bank.size() - 1)]
	var right := str(event[1])
	var all: Array = [["melting", "freezing"], ["melting", "freezing", "evaporating", "condensing"],
		["melting", "freezing", "evaporating", "condensing", "boiling"]][level - 1]
	if level == 1 and right not in all:
		right = all[0]
	var ex := K.choice(rng, "Which change of state is this? %s" % event[0], right, all.filter(func(w: String) -> bool:
		return w != right), "Say what it was at the start (solid, liquid or gas) and what it is at the end.",
		"It is %s: %s.%s" % [right, CHANGE_WORDS[right], " Even at 1,538 °C, a liquid turning solid is freezing!" if
			str(event[0]).contains("iron") else ""])
	ex.data = {"scene": event[0]}
	return ex


# --- Sound -------------------------------------------------------------------------------------------------------------

## Which sound is loudest or quietest (level 1: the waves' heights differ), highest or lowest (level 2: how close
## together the waves are), or any of them among three sounds (level 3)?
static func sound_wave(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := 3 if level == 3 else 2
	var asks: Array = [["loudest", "quietest"], ["highest", "lowest"], ["loudest", "quietest", "highest", "lowest"]][level - 1]
	var ask: String = asks[rng.randi_range(0, asks.size() - 1)]
	var by_amp := ask in ["loudest", "quietest"]
	var amps := _distinct(rng, n, 1, 4)
	var counts := _distinct(rng, n, 1, 6)
	if level < 3:   # only the property asked about changes
		var same_amp := rng.randi_range(2, 3)
		var same_count := rng.randi_range(2, 4)
		for i in n:
			if by_amp:
				counts[i] = same_count
			else:
				amps[i] = same_amp
	var waves: Array = []
	for i in n:
		waves.append({"amp": amps[i], "count": counts[i]})
	var values: Array = amps if by_amp else counts
	var want_big := ask in ["loudest", "highest"]
	var best: int = values.find(values.max() if want_big else values.min())
	var names: Array[String] = ["sound A", "sound B", "sound C"]
	var prompt := "The waves show %d sounds. Which is the %s sound?" % [n, ask] if by_amp else \
		"The waves show %d sounds. Which sound has the %s pitch?" % [n, ask]
	var hint := "A louder sound has taller waves (a bigger amplitude)." if by_amp else \
		"A higher sound vibrates faster, so its waves are closer together."
	var explain := "%s has the %s waves, so it is the %s." % [_cap(names[best]), "tallest" if ask == "loudest" else "smallest",
		ask]
	if not by_amp:
		explain = "%s's waves are %s, so it has the %s pitch." % [_cap(names[best]), "the closest together" if ask == "highest"
			else "the furthest apart", ask]
	var ex := K.choice(rng, prompt, names[best], names.slice(0, n).filter(func(x: String) -> bool: return x != names[best]),
		hint, explain, {"kind": "wave", "waves": waves, "names": true})
	ex.data = {"waves": waves, "ask": ask}
	return ex


# --- Digestion ---------------------------------------------------------------------------------------------------------

## Put the parts of the digestive system in the order food passes through them: 3, 4 or 5 of them in a row.
static func gut_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := level + 2
	var last_start := (5 if level < 3 else PATH.size()) - n
	var start := rng.randi_range(0, last_start)
	var parts: Array = PATH.slice(start, start + n)
	var pic := {"kind": "digestion", "labels": true} if level == 1 else {}
	var ex := K.order(rng, "Put these parts in the order food passes through them.", parts,
		"Food goes in at the mouth and moves down: the stomach comes before the intestines, the small one before the large, and the rectum is at the end.",
		"Food goes: %s." % ", then ".join(PackedStringArray(parts)), pic)
	ex.data = {"parts": parts}
	return ex


# --- English -----------------------------------------------------------------------------------------------------------

## Phrases from Greek myths: what one means (level 1), match four to their meanings (level 2), what one means in a
## sentence (level 3).
static func myth_phrase(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var order: Array = range(PHRASES.size())
	K.shuffle(rng, order)
	if level == 2:
		var picked: Array = order.slice(0, 4)
		var items: Array = []
		var meanings: Array = []
		for i: int in picked:
			items.append(PHRASES[i][0])
			meanings.append(PHRASES[i][2])
		var shown: Array = range(4)
		while shown == range(4):   # never all side by side
			K.shuffle(rng, shown)
		var matches: Array = []
		for k: int in shown:
			matches.append(meanings[k])
		var answer: Array = []
		for k in 4:
			answer.append(shown.find(k))
		var lines: Array[String] = []
		for i: int in picked:
			lines.append("%s: %s" % [PHRASES[i][0], PHRASES[i][2]])
		var ex := {"type": "match", "prompt": "Match each phrase from a Greek myth to what it means today.", "items": items,
			"matches": matches, "answer": answer, "hint": "Think of each story: what happened to its hero?",
			"explain": _cap("%s." % "; ".join(lines))}
		ex.data = {"phrases": picked}
		return ex
	var p: Array = PHRASES[order[0]]
	var wrongs: Array = []
	for k in range(1, 4 if level == 3 else 3):
		wrongs.append(PHRASES[order[k]][2])
	var prompt := "What does \"%s\" mean?" % p[0]
	if level == 3:
		var sentences: Array = p[4]
		prompt = "\"%s\" What does \"%s\" mean here?" % [sentences[rng.randi_range(0, 1)], p[1]]
	var ex := K.choice(rng, prompt, p[2], wrongs, "Remember the myth: what happened in the story?",
		"It means %s. %s" % [p[2], p[3]])
	ex.data = {"key": p[1]}
	return ex


## Sort sentences: from a first-hand account (the writer was there) or a second-hand one: 4, 5 or 6 of them.
static func account_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := level + 3
	var first := rng.randi_range(2, n - 2)
	var items: Array = []
	for s: String in _pick(rng, FIRST_HAND, first):
		items.append([s, 0])
	for s: String in _pick(rng, SECOND_HAND, n - first):
		items.append([s, 1])
	K.shuffle(rng, items)
	var names: Array = []
	var answer: Array = []
	for x: Array in items:
		names.append(x[0])
		answer.append(x[1])
	var ex := {"type": "sort", "prompt": "Sort the sentences: from a first-hand account (the writer was there) or a second-hand account?",
		"groups": ["first-hand", "second-hand"], "items": names, "answer": answer,
		"hint": "Look for I, we, my and our, and for what someone saw, heard or felt. Who found it out, and how?",
		"explain": _account_words(items)}
	ex.data = {"items": names}
	return ex


## Choose the linking words that fit an opinion's sentence: 3 choices (level 1), 4 (levels 2 and 3, finer ones).
static func link_word(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var bank: Array = LINKS.filter(func(l: Array) -> bool: return int(l[4]) == level)
	var l: Array = bank[rng.randi_range(0, bank.size() - 1)]
	var wrongs: Array = (l[3] as Array).duplicate()
	K.shuffle(rng, wrongs)
	var ex := K.choice(rng, "Choose the linking words for the gap: %s" % l[0], l[2], wrongs.slice(0, 2 if level == 1 else 3),
		"What does the gap need: another reason, an example, a purpose, a reason why, the other side, or an ending?",
		"It needs %s: %s" % [l[1], _filled(str(l[0]), str(l[2]))])
	ex.data = {"needs": l[1]}
	return ex


## The worked answer of an account sort: each group's sentences when they fit, or the rule.
static func _account_words(items: Array) -> String:
	var first: Array[String] = []
	var second: Array[String] = []
	for x: Array in items:
		(first if int(x[1]) == 0 else second).append(str(x[0]).trim_suffix("."))
	var words := "First-hand (the writer was there): %s. Second-hand: %s." % ["; ".join(first), "; ".join(second)]
	if words.length() <= 260:
		return words
	return "First-hand accounts say what the writer saw, heard and felt (I, we, my, our). Second-hand accounts tell what others found out (historians say, records show, the report says)."


# --- Helpers -----------------------------------------------------------------------------------------------------------

static func _pick(rng: RandomNumberGenerator, from: Array, n: int) -> Array:
	var copy := from.duplicate()
	K.shuffle(rng, copy)
	return copy.slice(0, n)


## `n` different whole numbers from lo to hi.
static func _distinct(rng: RandomNumberGenerator, n: int, lo: int, hi: int) -> Array:
	var all: Array = range(lo, hi + 1)
	K.shuffle(rng, all)
	return all.slice(0, n)


## A linking sentence with its gap filled (without "The ending:" and its quotation marks).
static func _filled(sentence: String, words: String) -> String:
	var s := sentence
	if s.contains(": \""):
		s = s.substr(s.find(": \"") + 3).trim_suffix("\"")
	return s.replace("___", words)


static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)
