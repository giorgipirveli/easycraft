extends GutTest
## Prospecting quests on the Moon and Mars (spec §26.5, owner #80): one per resource, 7 steps each like Earth's (the
## map, the walk, the sign, a problem and a clue, a quiz, MARK IT), and the lesson of living off the land: ice becomes
## water, air and rocket fuel for the trip; dust becomes bricks for the domes. The problems' answers worked by hand, the
## recipes' numbers the quizzes use, honest lines (helium-3 power is a dream not built yet; Mars's perchlorate is washed
## out of soil), and no real mission's, agency's or person's name (spec §21b.2).

const CAMP := Vector3(10, 50, 20)
const SPACE_KINDS: Array[StringName] = [DepositKinds.MOON_ICE, DepositKinds.ILMENITE, DepositKinds.HELIUM_3,
	DepositKinds.KREEP, DepositKinds.MOON_METEORITE, DepositKinds.MARS_ICE, DepositKinds.HEMATITE, DepositKinds.DARK_SAND,
	DepositKinds.MARS_SALT, DepositKinds.MARS_METEORITE]

var _moon: DepositRules
var _mars: DepositRules


func before_all() -> void:
	var moon := SpaceShape.new(12345, SpaceShape.MOON)
	_moon = DepositRules.for_world(12345, moon, SpaceSecretRules.new(12345, moon))
	var mars := SpaceShape.new(12345, SpaceShape.MARS)
	_mars = DepositRules.for_world(12345, mars, SpaceSecretRules.new(12345, mars))


func _deposit(kind: StringName) -> Dictionary:
	return (_mars if DepositKinds.universe_of(kind) == SpaceRules.MARS else _moon).nearest(kind, CAMP, [], 3)


func _steps(kind: StringName, roll := 0) -> Array[Dictionary]:
	return ProspectQuests.steps(kind, _deposit(kind), CAMP, roll)


func _first(steps: Array[Dictionary], type: StringName) -> Dictionary:
	for s: Dictionary in steps:
		if s.type == type:
			return s
	return {}


func _all_exercises(steps: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s: Dictionary in steps:
		out.append_array(ProspectQuests.exercises(s))
	return out


func test_every_space_kind_has_its_quest_of_seven_steps() -> void:
	assert_eq(SpaceQuests.QUESTS.keys().size(), SPACE_KINDS.size())
	for kind in SPACE_KINDS:
		assert_false(SpaceQuests.QUESTS.get(kind, {}).is_empty(), str(kind))
		assert_eq(ProspectQuests.quest(kind), SpaceQuests.QUESTS[kind], "%s is told like Earth's" % kind)
		var steps := _steps(kind)
		assert_eq(steps.size(), 7, "%s: 7 steps" % kind)
		assert_true(_first(steps, ProspectQuests.CLUE).size() > 0, "%s has a clue" % kind)


## The problems' answers, worked by hand.
func test_the_problems_answers_worked_by_hand() -> void:
	var want := {DepositKinds.MOON_ICE: "350", DepositKinds.ILMENITE: "200", DepositKinds.HELIUM_3: "1000",
		DepositKinds.KREEP: "24", DepositKinds.MOON_METEORITE: "1200", DepositKinds.MARS_ICE: "120",
		DepositKinds.HEMATITE: "4", DepositKinds.DARK_SAND: "15", DepositKinds.MARS_SALT: "24",
		DepositKinds.MARS_METEORITE: "5"}
	for kind: StringName in want:
		var p := _first(_steps(kind), ProspectQuests.PROBLEM)
		assert_true(ExerciseCheck.is_right(p.exercise, want[kind]), "%s: %s (%s)" % [kind, want[kind], p.exercise.prompt])
	assert_eq(120 + 230, 350, "from 230 below zero up to 120: 350 degrees")
	assert_eq(500 * 4 / 10, 200, "40% of 500 kg")
	assert_eq(50 * 20, 1000, "50 tonnes × 20 mg")
	assert_eq(3 * 8, 24, "8 times 3 clicks")
	assert_eq(60 * 20, 1200, "20 km a second for a minute")
	assert_eq(3 * 4 * 10, 120, "3 litres × 4 astronauts × 10 days")
	assert_eq(48 / 12, 4, "48 mm shared by 12 blueberries")
	assert_eq(20 / 4 * 3, 15, "3 of every 4 grains of 20")
	assert_eq(6 * 4, 24, "4 oxygen atoms for each of 6 chlorine atoms")
	assert_eq(50 / 10, 5, "10% of 50 kg")


## The quizzes' numbers are the game's recipes (what a child makes in Survivor is what the quiz says).
func test_the_quiz_numbers_are_the_recipes() -> void:
	var met := Recipes.find(&"meteorite_iron")
	var moon_met := _all_exercises(_steps(DepositKinds.MOON_METEORITE)).filter(func(e: Dictionary) -> bool:
		return e.type == "number" and str(e.prompt).contains("Solar Oven"))
	assert_eq(moon_met.size(), 1)
	assert_true(ExerciseCheck.is_right(moon_met[0], str(5 * int(met.count))), "5 meteorites × %d Iron" % met.count)
	var mars_met := _all_exercises(_steps(DepositKinds.MARS_METEORITE)).filter(func(e: Dictionary) -> bool:
		return e.type == "number" and str(e.prompt).contains("Solar Oven"))
	assert_true(ExerciseCheck.is_right(mars_met[0], str(4 * int(met.count))))
	var sieve := Recipes.find(&"sieve_blueberries")
	var smelt := Recipes.find(&"hematite_iron")
	var hem := _all_exercises(_steps(DepositKinds.HEMATITE)).filter(func(e: Dictionary) -> bool:
		return e.type == "number" and str(e.prompt).contains("Blueberry Soil"))
	assert_true(ExerciseCheck.is_right(hem[0], str(int(sieve.needs[BlockIds.BLUEBERRY_SOIL]) * int(smelt.needs[BlockIds.HEMATITE]))),
		"blueberry soil for one iron")
	var sand := Recipes.find(&"sand_iron")
	var dark := _all_exercises(_steps(DepositKinds.DARK_SAND)).filter(func(e: Dictionary) -> bool:
		return e.type == "number" and str(e.prompt).contains("Dark Sand"))
	assert_true(ExerciseCheck.is_right(dark[0], str(5 * int(sand.needs[BlockIds.DARK_SAND]))))
	var water := _all_exercises(_steps(DepositKinds.MOON_ICE)).filter(func(e: Dictionary) -> bool:
		return e.type == "number" and str(e.prompt).contains("9 kg"))
	assert_true(ExerciseCheck.is_right(water[0], "8"), "9 kg of water: 1 kg of hydrogen, 8 of oxygen")


## Living off the land (the brief's lesson): both ice quests put the chain in order (dig, melt, split, use) and say
## water, air and rocket fuel.
func test_the_ice_quests_teach_living_off_the_land() -> void:
	for kind: StringName in [DepositKinds.MOON_ICE, DepositKinds.MARS_ICE]:
		var steps := _steps(kind)
		var orders := _all_exercises(steps).filter(func(e: Dictionary) -> bool: return e.type == "order")
		assert_eq(orders.size(), 1, "%s: put the chain in order" % kind)
		var o: Dictionary = orders[0]
		var in_order: Array = (o.answer as Array).map(func(i: int) -> String: return str(o.items[i]).to_lower())
		assert_true(in_order[0].contains("dig"), "%s: dig first (%s)" % [kind, in_order])
		assert_true(in_order[1].contains("melt"), "%s: then melt (%s)" % [kind, in_order])
		assert_true(in_order[2].contains("split"), "%s: then split (%s)" % [kind, in_order])
		var text := str(steps).to_lower()
		for word in ["water", "oxygen", "rocket fuel", "hydrogen"]:
			assert_string_contains(text, word, "%s says %s" % [kind, word])


## The crater quests start on the rim (the map's X) and go down into the crater to the sign.
func test_the_crater_quests_go_from_the_rim_down_in() -> void:
	for kind: StringName in [DepositKinds.MOON_ICE, DepositKinds.MOON_METEORITE, DepositKinds.MARS_ICE,
			DepositKinds.DARK_SAND]:
		var d := _deposit(kind)
		var steps := _steps(kind)
		var reach := _first(steps, ProspectQuests.REACH)
		var sign := _first(steps, ProspectQuests.SIGN)
		assert_eq(int(reach.spot), 0, "%s: walk to the rim" % kind)
		assert_eq(int(sign.spot), 1, "%s: find the sign in the crater" % kind)
		assert_eq(ProspectQuests.target(sign, d), Vector3(d.signs[1][0] as Vector3i) + Vector3(0.5, 0.5, 0.5))


## Honest, friendly words: helium-3 power is a dream (not built yet), perchlorate is washed out of soil (no scary
## words), and no real mission's, agency's or person's name.
func test_honest_and_friendly() -> void:
	var he := str(_steps(DepositKinds.HELIUM_3)).to_lower()
	assert_true(he.contains("none works yet") or he.contains("dream"), "fusion is a dream")
	var salt := str(_steps(DepositKinds.MARS_SALT)).to_lower()
	assert_string_contains(salt, "wash")
	for kind in SPACE_KINDS:
		var text := str(SpaceQuests.QUESTS[kind]) + str(_steps(kind)) + str(DepositKinds.data(kind))
		for bad: String in ["poison", "toxic", "explode", "danger", "deadly", "hurry", "apollo", "lcross", "phoenix",
				"opportunity", "curiosity", "perseverance", "spirit rover", "artemis", "nasa", "esa ", "lunar prospector",
				"moxie", "armstrong", "musk", "spacex"]:
			assert_false(text.to_lower().contains(bad), "%s says '%s'" % [kind, bad])


func test_a_match_and_a_sort_are_good_school_exercises() -> void:
	var kreep := _all_exercises(_steps(DepositKinds.KREEP)).filter(func(e: Dictionary) -> bool: return e.type == "match")
	assert_eq(kreep.size(), 1, "KREEP's letters matched to what they stand for")
	assert_eq(ExerciseCheck.problem(kreep[0]), "")
	var m: Dictionary = kreep[0]
	for i in (m.items as Array).size():
		var left := str(m.items[i])
		var right := str(m.matches[int(m.answer[i])])
		match left:
			"K":
				assert_eq(right, "Potassium")
			"REE":
				assert_eq(right, "Rare earth elements")
			"P":
				assert_eq(right, "Phosphorus")
	for roll in [0, 1, 2, 3]:
		for kind in SPACE_KINDS:
			for ex in _all_exercises(_steps(kind, roll)):
				assert_eq(ExerciseCheck.problem(ex), "", "%s %s" % [kind, ex.get("prompt", "")])
