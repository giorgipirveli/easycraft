extends GutTest
## Owner #70 and #73, grade 4 science and English (G4CoreGen, "g4c"; research §6.4): will this circuit work, conductors
## and insulators, reading thermometers (below 0 too), how much warmer or colder, which way heat flows, solid, liquid or
## gas at a temperature, which change of state, the loudest or highest sound's wave, the digestive system's order, words
## from myths, first-hand and second-hand accounts, and linking words for an opinion. Each answer is worked out again
## here from the exercise's `data` with this file's own facts (typed apart from the generator's tables), for many seeds
## and every level, and every exercise must be valid (ExerciseCheck, the picture's and the sound's own checks).

const SEEDS := 80
## Metals let electricity through; the rest here do not.
const METALS: Array[String] = ["copper", "steel", "iron", "foil", "gold", "brass", "paper clip", "metal coin"]
const NOT_METALS: Array[String] = ["plastic", "rubber", "wooden", "glass", "paper straw", "cotton", "woolly", "cork", "china"]
## Melting points in °C (and water's boiling point): the lessons' facts.
const MELTS := {"water": 0, "gold": 1064, "iron": 1538, "aluminium": 660, "tin": 232}
const WATER_BOILS := 100
## The food's path, mouth first.
const PATH: Array[String] = ["mouth", "gullet", "stomach", "small intestine", "large intestine", "rectum"]
## Which change of state each event is.
const CHANGES := {
	"An ice lolly drips on a hot day.": "melting", "Water in a tray turns to ice in the freezer.": "freezing",
	"Snow turns to water in the spring sunshine.": "melting", "A pond turns to ice on a frosty night.": "freezing",
	"Butter goes runny in a hot pan.": "melting", "Juice in a mould turns into an ice lolly.": "freezing",
	"A puddle dries up in the sun.": "evaporating", "Drops of water form on a cold window.": "condensing",
	"Wet washing dries on a line.": "evaporating", "A mirror mists up after a hot bath.": "condensing",
	"A cold can of juice gets wet on the outside.": "condensing", "Sweat dries on your skin.": "evaporating",
	"Water bubbles in a pan at 100 °C and turns to steam.": "boiling",
	"Dew forms on the grass on a cool morning.": "condensing", "Hot, runny iron cools into a solid bar.": "freezing",
	"Chocolate goes runny in a warm hand.": "melting", "A kettle's water bubbles hard and steam pours out.": "boiling",
	"Seawater in a shallow pool dries up, leaving salt.": "evaporating",
	"A glass of iced water gets wet on the outside.": "condensing",
}
## Phrases from myths and what they mean today.
const PHRASES := {"Herculean task": "a very hard job", "Achilles' heel": "a weak spot",
	"Pandora's box": "the start of many troubles", "Midas touch": "success at everything",
	"odyssey": "a long, adventurous journey"}
## Words that show a writer was there (first-hand) or found out from others (second-hand).
const FIRST_HAND: Array[String] = ["I ", "We ", "My ", "my ", "Our ", "our ", " me", " us"]
const SECOND_HAND: Array[String] = ["say", "said", "says", "show", "explains", "found", "According", "report", "Old "]


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make(gen, s, level)
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


func _choice_is(ex: Dictionary, expected: String) -> void:
	assert_eq(str(ex.type), "choice", str(ex.prompt))
	assert_eq(ExerciseCheck.answer_text(ex), expected, str(ex.prompt))


func _conducts(thing: String) -> bool:
	for m in METALS:
		if thing.contains(m):
			return true
	for m in NOT_METALS:
		if thing.contains(m):
			return false
	fail_test("unknown material %s" % thing)
	return false


## A sort's items in their right groups, by the group's name.
func _sorted(ex: Dictionary) -> Dictionary:
	var out := {}
	for g: String in ex.groups:
		out[g] = []
	for i in (ex.items as Array).size():
		(out[ex.groups[int(ex.answer[i])]] as Array).append(str(ex.items[i]))
	return out


# --- Circuits ----------------------------------------------------------------------------------------------------------

func test_will_the_circuit_work() -> void:
	_each("g4c.circuit_lights", _check_circuit)


func _check_circuit(ex: Dictionary, level: int) -> void:
	assert_eq(str(ex.type), "truefalse")
	var pic: Dictionary = ex.picture
	assert_eq(str(pic.kind), "lab_circuit")
	assert_eq(str(pic.get("glow", "")), "?", "the picture does not give the answer away")
	var works := str(pic.get("switch", "")) != "open" and bool(pic.get("cell", true))
	if bool(pic.get("gap", false)):
		works = works and pic.has("bridge") and _conducts(str(pic.bridge))
	assert_eq(ex.answer, works, "%s %s" % [ex.prompt, pic])
	if level == 1:
		assert_false(bool(pic.get("gap", false)), "level 1: only the switch")
	if level == 3:
		assert_true(pic.has("bridge"), "level 3: something across the gap")


func test_conductors_and_insulators() -> void:
	_each("g4c.conductor_sort", _check_conductors)


func _check_conductors(ex: Dictionary, level: int) -> void:
	assert_eq(str(ex.type), "sort")
	assert_eq(ex.groups, ["conductor", "insulator"])
	for i in (ex.items as Array).size():
		assert_eq(int(ex.answer[i]), 0 if _conducts(str(ex.items[i])) else 1, str(ex.items[i]))
	assert_eq((ex.items as Array).size(), level + 3, "level %d sorts %d things" % [level, level + 3])


# --- Heat --------------------------------------------------------------------------------------------------------------

func test_reading_a_thermometer() -> void:
	_each("g4c.thermo_read", _check_thermometer)


func _check_thermometer(ex: Dictionary, level: int) -> void:
	var pic: Dictionary = ex.picture
	assert_eq(str(pic.kind), "thermometer")
	var v := float(pic.value)
	_number_is(ex, v)
	var mark := float(pic.step) / (int(pic.get("minor", 0)) + 1)
	assert_almost_eq(fmod(v - float(pic.from), mark), 0.0, 0.0001, "the value is on a mark")
	if level == 1:
		assert_eq(int(pic.get("minor", 0)), 0, "level 1: numbers only")
	if level == 3:
		assert_lt(float(pic.from), 0.0, "level 3: below zero on the scale")
	else:
		assert_gte(v, 0.0, "levels 1-2: 0 and above")


func test_how_much_warmer_or_colder() -> void:
	_each("g4c.temp_change", _check_temp_change)


func _check_temp_change(ex: Dictionary, level: int) -> void:
	var a := int(ex.data.a)
	var b := int(ex.data.b)
	assert_ne(a, b)
	_number_is(ex, absi(b - a))
	var p := str(ex.prompt)
	assert_true(p.contains(SchoolPictureG4Core.degrees(a) + " °C") and p.contains(SchoolPictureG4Core.degrees(b) + " °C"),
		"the prompt gives both temperatures: %s" % p)
	if b > a:
		assert_true(p.contains("warmer") or p.contains("warm up") or p.contains("rise"), p)
	else:
		assert_true(p.contains("colder") or p.contains("cool") or p.contains("fall"), p)
	assert_false(p.contains("-"), "minus signs, not hyphens: %s" % p)
	if level == 3:
		assert_true(a < 0 or b < 0, "level 3 goes below zero")
		assert_true(a > 0 or b > 0, "and above it")
	else:
		assert_true(a >= 0 and b >= 0, "levels 1-2 stay above zero")


func test_which_way_heat_flows() -> void:
	_each("g4c.heat_flow", _check_heat_flow)


func _check_heat_flow(ex: Dictionary, level: int) -> void:
	var a: Array = ex.data.a   # [name, °C]
	var b: Array = ex.data.b
	var right := "Heat does not flow between them."
	if int(a[1]) > int(b[1]):
		right = "from %s into %s" % [a[0], b[0]]
	elif int(b[1]) > int(a[1]):
		right = "from %s into %s" % [b[0], a[0]]
	_choice_is(ex, right)
	assert_true(str(ex.prompt).contains(SchoolPictureG4Core.degrees(int(a[1])) + " °C")
		and str(ex.prompt).contains(SchoolPictureG4Core.degrees(int(b[1])) + " °C"), "the prompt gives both temperatures")
	if level == 3:
		assert_true(int(a[1]) < 0 and int(b[1]) < 0, "level 3: both below zero (the warmer ice still gives heat)")


# --- States of matter --------------------------------------------------------------------------------------------------

func test_solid_liquid_or_gas() -> void:
	_each("g4c.state_at", _check_state_at)


func _check_state_at(ex: Dictionary, level: int) -> void:
	var thing := str(ex.data.thing)
	var t := int(ex.data.t)
	assert_true(MELTS.has(thing), thing)
	var melt: int = MELTS[thing]
	assert_ne(t, melt, "never at the melting point itself")
	var state := "solid" if t < melt else "liquid"
	if thing == "water" and t > WATER_BOILS:
		state = "gas"
	assert_ne(t, WATER_BOILS if thing == "water" else -9999, "never at the boiling point itself")
	_choice_is(ex, state)
	assert_true(str(ex.prompt).contains(SchoolPictureG4Core.degrees(t) + " °C"), "the prompt gives the temperature")
	if thing != "water":
		assert_true(str(ex.prompt).contains(GenKit.fmt(melt) + " °C"), "a metal's melting point is given")
	assert_eq(thing == "water", level < 3, "levels 1-2: water; level 3: metals")


func test_which_change_of_state() -> void:
	_each("g4c.state_change", _check_state_change)


func _check_state_change(ex: Dictionary, level: int) -> void:
	var scene := str(ex.data.scene)
	assert_true(CHANGES.has(scene), scene)
	assert_true(str(ex.prompt).contains(scene))
	_choice_is(ex, str(CHANGES.get(scene, "")))
	assert_eq((ex.choices as Array).size(), [2, 4, 5][level - 1], "level %d's choices" % level)


# --- Sound -------------------------------------------------------------------------------------------------------------

func test_which_sound_is_louder_or_higher() -> void:
	_each("g4c.sound_wave", _check_sound_wave)


func _check_sound_wave(ex: Dictionary, level: int) -> void:
	var waves: Array = ex.picture.waves
	var ask := str(ex.data.ask)
	var key := "amp" if ask in ["loudest", "quietest"] else "count"
	var want_big := ask in ["loudest", "highest"]
	var best := 0
	for i in waves.size():
		if (int(waves[i][key]) > int(waves[best][key])) == want_big and int(waves[i][key]) != int(waves[best][key]):
			best = i
	for i in waves.size():
		if i != best:
			assert_ne(int(waves[i][key]), int(waves[best][key]), "one wave is the %s" % ask)
	_choice_is(ex, "sound %s" % ["A", "B", "C"][best])
	assert_true(str(ex.prompt).contains(ask), "the prompt asks for the %s" % ask)
	assert_eq(waves.size(), 3 if level == 3 else 2)
	if level == 1:
		assert_true(ask in ["loudest", "quietest"], "level 1: loud and quiet")
	elif level == 2:
		assert_true(ask in ["highest", "lowest"], "level 2: high and low")


# --- Digestion ---------------------------------------------------------------------------------------------------------

func test_the_food_path() -> void:
	_each("g4c.gut_order", _check_gut)


func _check_gut(ex: Dictionary, level: int) -> void:
	assert_eq(str(ex.type), "order")
	var ordered: Array[String] = []
	for i: Variant in ex.answer:
		ordered.append(str(ex.items[int(i)]))
	var start := PATH.find(ordered[0])
	assert_gte(start, 0, ordered[0])
	for k in ordered.size():
		assert_eq(ordered[k], PATH[start + k], "the food's path: %s" % [ordered])
	assert_eq(ordered.size(), [3, 4, 5][level - 1])


# --- English -----------------------------------------------------------------------------------------------------------

func test_words_from_myths() -> void:
	_each("g4c.myth_phrase", _check_myths)


func _check_myths(ex: Dictionary, level: int) -> void:
	if level == 2:
		assert_eq(str(ex.type), "match")
		for i in (ex.items as Array).size():
			var phrase := str(ex.items[i])
			var meaning := str(ex.matches[int(ex.answer[i])])
			var found := false
			for k: String in PHRASES:
				if phrase.contains(k):
					found = true
					assert_eq(meaning, PHRASES[k], phrase)
			assert_true(found, phrase)
		return
	var key := str(ex.data.key)
	assert_true(PHRASES.has(key), key)
	assert_true(str(ex.prompt).contains(key), "the prompt says the phrase")
	_choice_is(ex, str(PHRASES.get(key, "")))
	if level == 3:
		assert_true(str(ex.prompt).count("\"") >= 4, "level 3: the phrase in a sentence")


func test_first_and_second_hand_accounts() -> void:
	_each("g4c.account_sort", _check_accounts)


func _check_accounts(ex: Dictionary, level: int) -> void:
	assert_eq(str(ex.type), "sort")
	assert_eq(ex.groups, ["first-hand", "second-hand"])
	var groups := _sorted(ex)
	for s: String in groups["first-hand"]:
		assert_true(FIRST_HAND.any(func(w: String) -> bool: return (" " + s + " ").contains(w)), "first-hand: %s" % s)
		assert_false(SECOND_HAND.any(func(w: String) -> bool: return s.contains(w)), "first-hand: %s" % s)
	for s: String in groups["second-hand"]:
		assert_true(SECOND_HAND.any(func(w: String) -> bool: return s.contains(w)), "second-hand: %s" % s)
		assert_false(FIRST_HAND.any(func(w: String) -> bool: return (" " + s + " ").contains(w)), "second-hand: %s" % s)
	assert_eq((ex.items as Array).size(), level + 3)


func test_linking_words() -> void:
	_each("g4c.link_word", _check_links)


## Each sentence's linking words: what it needs and what it must never be offered as right.
const LINKS := {
	"another reason": ["In addition", "Also"], "an example": ["For example", "For instance"],
	"a purpose": ["in order to", "so that"], "a reason": ["because"], "an ending": ["In conclusion", "To sum up"],
	"a different side": ["However"],
}


func _check_links(ex: Dictionary, level: int) -> void:
	assert_eq(str(ex.type), "choice")
	var needs := str(ex.data.needs)
	assert_true(LINKS.has(needs), needs)
	var right := ExerciseCheck.answer_text(ex)
	assert_true((LINKS[needs] as Array).has(right), "%s needs %s, not %s" % [ex.prompt, needs, right])
	for i in (ex.choices as Array).size():
		if i != int(ex.answer):
			assert_false((LINKS[needs] as Array).has(str(ex.choices[i])), "%s: only one right choice" % ex.prompt)
	assert_true(str(ex.prompt).contains("___"), "a gap to fill")
	assert_eq((ex.choices as Array).size(), 3 if level == 1 else 4)
