extends GutTest
## Prospecting quests (spec §26.2, owner #80: "quests which include solving problems, quizes, maps, advantures,
## findings"): one per resource, 5-7 steps each, mixing a map to read (built from this world: the camp and the X), a
## clue from real geology, a problem (the echo survey's depth, the detector's pattern, percents, ratios), a short quiz
## of what the quest taught (School exercises: ExerciseCheck), walks to the place (the compass points) and a find (the
## sign itself, walked up to); the last step marks the deposit on MY MAP. The numbers come from the world, the answers
## are worked out by hand here. Every kind: Earth's six and the Moon's and Mars's ten (spec §26.5; their own answers:
## test_prospect_space_quests.gd).

const CAMP := Vector3(10, 40, 20)

var _meadows: DepositRules
var _desert: DepositRules
var _moon: DepositRules
var _mars: DepositRules


func before_all() -> void:
	var m := MeadowsBiomeShape.new(12345)
	_meadows = DepositRules.for_world(12345, m, SecretRules.new(12345, m))
	var d := DesertShape.new(12345)
	_desert = DepositRules.for_world(12345, d, DesertSecretRules.new(12345, d))
	var moon := SpaceShape.new(12345, SpaceShape.MOON)
	_moon = DepositRules.for_world(12345, moon, SpaceSecretRules.new(12345, moon))
	var mars := SpaceShape.new(12345, SpaceShape.MARS)
	_mars = DepositRules.for_world(12345, mars, SpaceSecretRules.new(12345, mars))


func _deposit(kind: StringName) -> Dictionary:
	var rules: DepositRules = {1: _meadows, 2: _desert, SpaceRules.MOON: _moon, SpaceRules.MARS: _mars}[DepositKinds.universe_of(kind)]
	return rules.nearest(kind, CAMP, [], 3)


func test_there_is_a_quest_for_every_kind() -> void:
	assert_eq(ProspectQuests.QUESTS.keys().size() + SpaceQuests.QUESTS.keys().size(), DepositKinds.ALL.size())
	for kind in DepositKinds.ALL:
		var q := ProspectQuests.quest(kind)
		assert_false(q.is_empty(), str(kind))
		assert_ne(str(q.get("title", "")), "")
		assert_ne(str(q.get("story", "")), "")
		assert_lte(str(q.story).length(), 180, "%s's story fits the card" % kind)


func test_each_quest_mixes_every_kind_of_step() -> void:
	for kind in DepositKinds.ALL:
		var steps := ProspectQuests.steps(kind, _deposit(kind), CAMP, 5)
		assert_between(steps.size(), 5, 7, "%s: 5-7 steps" % kind)
		var types := {}
		for s: Dictionary in steps:
			types[s.type] = true
			assert_has(ProspectQuests.TYPES, s.type)
			assert_ne(str(s.get("words", "")), "", "%s: every step says what to do" % kind)
			assert_lte(str(s.words).length(), 64, "%s: '%s' fits the HUD's line" % [kind, s.words])
		assert_true(types.has(ProspectQuests.MAP), "%s reads a map" % kind)
		assert_true(types.has(ProspectQuests.REACH), "%s has an adventure to reach it" % kind)
		assert_true(types.has(ProspectQuests.SIGN), "%s finds the sign" % kind)
		assert_true(types.has(ProspectQuests.QUIZ), "%s has a quiz" % kind)
		assert_true(types.has(ProspectQuests.PROBLEM) or types.has(ProspectQuests.CLUE), "%s solves a problem" % kind)
		assert_true(types.has(ProspectQuests.PROBLEM), "%s: some maths" % kind)
		assert_eq(steps[steps.size() - 1].type, ProspectQuests.MARK, "%s ends by marking MY MAP" % kind)
		assert_eq(steps[0].type, ProspectQuests.MAP, "%s starts with the map at the camp" % kind)


func test_every_exercise_is_a_good_school_exercise() -> void:
	for kind in DepositKinds.ALL:
		for roll in [0, 1, 2, 3]:
			for s: Dictionary in ProspectQuests.steps(kind, _deposit(kind), CAMP, roll):
				for ex: Dictionary in ProspectQuests.exercises(s):
					assert_eq(ExerciseCheck.problem(ex), "", "%s %s: %s" % [kind, s.type, ex.get("prompt", "")])
					assert_true(ex.has("explain"), "%s: every exercise explains its answer" % kind)
				if s.type == ProspectQuests.QUIZ:
					assert_between(ProspectQuests.exercises(s).size(), 2, 3, "%s: a short quiz" % kind)
				elif s.type in [ProspectQuests.MAP, ProspectQuests.CLUE, ProspectQuests.PROBLEM]:
					assert_eq(ProspectQuests.exercises(s).size(), 1)
				else:
					assert_eq(ProspectQuests.exercises(s).size(), 0, "%s: walking steps have no exercise" % kind)


## The map's question is about this world: the X is where the quest's first place really is.
func test_the_map_question_is_about_this_world() -> void:
	for kind in DepositKinds.ALL:
		var d := _deposit(kind)
		var map: Dictionary = ProspectQuests.steps(kind, d, CAMP, 1)[0]
		var target: Vector3 = map.map.target
		var spot: Vector3i = d.spots[0]
		assert_eq(target, Vector3(spot) + Vector3(0.5, 0, 0.5), "%s: the X is the first place" % kind)
		assert_eq(map.map.camp, CAMP)
		var frame: Dictionary = map.map.frame
		var ex: Dictionary = map.exercise
		var right: String = ex.choices[ex.answer]
		match str(map.ask):
			"direction":
				assert_eq(right, SurveyRules.point_words(SurveyRules.point(CAMP, target)), "%s: which way" % kind)
			"distance":
				assert_eq(right, "%d m" % SurveyRules.map_distance(CAMP, target, int(frame.square)), "%s: how far" % kind)
			"square":
				assert_eq(right, SurveyRules.square(target, frame.corner, int(frame.square)), "%s: which square" % kind)
			_:
				fail_test("%s asks %s" % [kind, map.ask])
		assert_true(ExerciseCheck.is_right(ex, ex.answer))


func test_the_problems_answers_worked_by_hand() -> void:
	var gold := ProspectQuests.steps(DepositKinds.GOLD, _deposit(DepositKinds.GOLD), CAMP, 0)
	var p := _first(gold, ProspectQuests.PROBLEM)
	assert_true(ExerciseCheck.is_right(p.exercise, "16"), "2, 4, 8 … 16 flakes")
	assert_false(ExerciseCheck.is_right(p.exercise, "10"))
	var oil_deposit := _deposit(DepositKinds.OIL)
	var oil := ProspectQuests.steps(DepositKinds.OIL, oil_deposit, CAMP, 0)
	p = _first(oil, ProspectQuests.PROBLEM)
	var depth := int(oil_deposit.depth_m)
	assert_true(ExerciseCheck.is_right(p.exercise, str(depth)), "the dome is %d m down" % depth)
	assert_true(str(p.exercise.prompt).contains(str(SurveyRules.echo_seconds(depth)).trim_suffix(".0")),
		"the echo's time is in the question: %s" % p.exercise.prompt)
	var copper := ProspectQuests.steps(DepositKinds.COPPER, _deposit(DepositKinds.COPPER), CAMP, 0)
	assert_true(ExerciseCheck.is_right(_first(copper, ProspectQuests.PROBLEM).exercise, "5"), "1% of 500 kg")
	var iron := ProspectQuests.steps(DepositKinds.IRON, _deposit(DepositKinds.IRON), CAMP, 0)
	var beeps: Dictionary = _first(iron, ProspectQuests.PROBLEM).exercise
	assert_true(ExerciseCheck.is_right(beeps, "8"), "the detector: half the distance, twice the beeps")
	assert_eq(roundi(SurveyRules.beeps(5.0)), 8, "the game's detector beeps like the problem says")
	var smelt: Dictionary = ProspectQuests.exercises(_first(iron, ProspectQuests.QUIZ))[1]
	assert_true(ExerciseCheck.is_right(smelt, "12"), "6 × 2 Iron (the Clay Oven's recipe)")
	assert_eq(int(Recipes.find(&"smelt_iron").count), 2)
	var coal := ProspectQuests.steps(DepositKinds.COAL, _deposit(DepositKinds.COAL), CAMP, 0)
	assert_true(ExerciseCheck.is_right(_first(coal, ProspectQuests.PROBLEM).exercise, "30"), "3 m × 10")
	for roll in [0, 1, 2]:
		var salt := ProspectQuests.steps(DepositKinds.SALT, _deposit(DepositKinds.SALT), CAMP, roll)
		var ex: Dictionary = _first(salt, ProspectQuests.PROBLEM).exercise
		var litres := int(ProspectQuests.SALT_PANS[roll % ProspectQuests.SALT_PANS.size()])
		assert_true(ExerciseCheck.is_right(ex, str(35 * litres)), "35 g × %d litres" % litres)


## Walking steps: the compass points to the step's place; arriving is being there (sideways and up or down).
func test_walking_steps_arrive_where_the_deposit_is() -> void:
	var d := _deposit(DepositKinds.GOLD)
	var steps := ProspectQuests.steps(DepositKinds.GOLD, d, CAMP, 0)
	var reach := _first(steps, ProspectQuests.REACH)
	var spot: Vector3i = d.spots[int(reach.spot)]
	assert_eq(ProspectQuests.target(reach, d), Vector3(spot) + Vector3(0.5, 0.5, 0.5))
	assert_true(ProspectQuests.arrived(reach, d, Vector3(spot) + Vector3(8, 1, 3)), "near is enough to reach it")
	assert_false(ProspectQuests.arrived(reach, d, Vector3(spot) + Vector3(40, 0, 0)))
	assert_false(ProspectQuests.arrived(reach, d, Vector3(spot) + Vector3(0, 60, 0)), "flying high over it is not there")
	var sign := _first(steps, ProspectQuests.SIGN)
	var cell: Vector3i = d.signs[int(sign.spot)][0]
	assert_true(ProspectQuests.arrived(sign, d, Vector3(cell) + Vector3(0.5, 1.0, 2.5)), "walking up to the sign finds it")
	assert_false(ProspectQuests.arrived(sign, d, Vector3(cell) + Vector3(12, 1, 0)), "the sign is found up close")
	assert_ne(str(sign.get("fact", "")), "", "finding a sign teaches a fact")
	var mark: Dictionary = steps[steps.size() - 1]
	assert_false(ProspectQuests.arrived(mark, d, Vector3(cell)), "marking is done on the card")


func test_the_oil_quest_leads_to_the_domes_top() -> void:
	var d := _deposit(DepositKinds.OIL)
	var steps := ProspectQuests.steps(DepositKinds.OIL, d, CAMP, 0)
	var reaches := steps.filter(func(s: Dictionary) -> bool: return s.type == ProspectQuests.REACH)
	assert_eq(reaches.size(), 2, "the seep, then the dome's top")
	assert_eq(int(reaches[1].spot), 1)
	assert_eq(ProspectQuests.target(reaches[1], d), Vector3(d.anchor) + Vector3(0.5, 0.5, 0.5), "the well's place")


## Fair fun (spec §6): no timers, nothing lost, never scary: no time pressure words, no danger words.
func test_no_timers_and_nothing_scary() -> void:
	for kind in DepositKinds.ALL:
		var text := str(ProspectQuests.quest(kind))
		for s: Dictionary in ProspectQuests.steps(kind, _deposit(kind), CAMP, 0):
			text += str(s)
		for bad: String in ["hurry", "quick!", "seconds left", "explode", "explosion", "danger", "die", "poison", "leak"]:
			assert_false(text.to_lower().contains(bad), "%s says '%s'" % [kind, bad])


func test_the_oil_quest_tells_the_honest_line() -> void:
	var text := str(ProspectQuests.steps(DepositKinds.OIL, _deposit(DepositKinds.OIL), CAMP, 0))
	assert_true(text.contains("warms the planet") or text.contains("warm the planet"), "burning oil warms the planet")
	assert_true(text.contains("cleaner"), "rockets and cars are learning cleaner fuels")


func _first(steps: Array[Dictionary], type: StringName) -> Dictionary:
	for s: Dictionary in steps:
		if s.type == type:
			return s
	return {}
