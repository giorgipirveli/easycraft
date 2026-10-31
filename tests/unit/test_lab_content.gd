extends GutTest
## Spec §23 (owner #74): the Science Lab's content test. Every experiment in data/lab is listed in its index and has no
## problems (LabExperiments.problems: its title, card, units, predict, scene, try, result and why words); every School
## unit it names exists in the outline; its prediction is a School exercise form (a choice, or a sort of the scene's
## things) whose own answer is what the scene really does; every scene can be made and finished by taps; the facts are
## checked against numbers held here (densities, magnetic metals, water's melting and boiling points, light and paint
## mixing, what seeds need, a closed loop); and the words are kind, English, British-spelt and in the font's letters
## (the School's own lists).

const SchoolContent := preload("res://tests/unit/test_school_content.gd")
const FIRST: Array[String] = ["float_sink", "magnets", "melting", "colours", "plants", "circuit"]
## Densities in g/cm³ (water: 1.0): a thing floats when it is less dense than water. Wood: pine and oak, 0.4-0.75;
## ice 0.917; a fresh leaf has air spaces; a dry sponge is mostly air; granite 2.7; iron 7.87; gold 19.3; glass 2.5.
const DENSITY := {"wood": 0.6, "ice": 0.917, "leaf": 0.7, "sponge": 0.1, "stone": 2.7, "iron": 7.87, "gold": 19.3,
	"glass": 2.5}
## What a fridge magnet pulls on: iron and the steels of nails, paper clips and food tins (tinplate: steel with a thin
## coat of tin). Gold, copper, glass, wood and ordinary stone do not stick.
const MAGNETIC := {"iron": true, "clip": true, "tin": true, "wood": false, "glass": false, "gold": false,
	"copper": false, "stone": false}


func before_each() -> void:
	LabExperiments.clear_cache()


func _all() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in LabExperiments.ids():
		out.append(LabExperiments.experiment(id))
	return out


# --- The files -----------------------------------------------------------------------------------------------------

func test_the_six_first_experiments_are_there_in_order() -> void:
	assert_eq(LabExperiments.ids().slice(0, 6), FIRST)
	for id in FIRST:
		assert_false(LabExperiments.experiment(id).is_empty(), "%s loads" % id)


func test_every_file_is_listed_and_has_no_problems() -> void:
	var files: Array[String] = []
	for f in DirAccess.get_files_at(LabExperiments.DIR):
		if f.ends_with(".json") and f != LabExperiments.INDEX:
			files.append(f.get_basename())
	files.sort()
	var listed := LabExperiments.ids().duplicate()
	listed.sort()
	assert_eq(files, listed, "every experiment file is in the index, and every listed one has its file")
	for e in _all():
		assert_eq(LabExperiments.problems(e), [] as Array[String], str(e.get("id", "?")))


func test_a_broken_experiment_says_what_is_wrong() -> void:
	var e := LabExperiments.experiment("magnets").duplicate(true)
	e.units = ["g3.science.no_such_unit"]
	e.why = []
	(e.predict as Dictionary).erase("prompt")
	var problems := LabExperiments.problems(e)
	assert_true(problems.any(func(p: String) -> bool: return p.contains("no_such_unit")), str(problems))
	assert_true(problems.any(func(p: String) -> bool: return p.contains("why")), str(problems))
	assert_true(problems.any(func(p: String) -> bool: return p.contains("prompt")), str(problems))
	var s := LabExperiments.experiment("melting").duplicate(true)
	s.scene = {"kind": "volcano"}
	assert_false(LabExperiments.problems(s).is_empty(), "an unknown scene")


func test_every_unit_is_in_the_school_outline() -> void:
	for e in _all():
		assert_gt((e.units as Array).size(), 0, e.id)
		for u: Variant in e.units:
			assert_false(Curriculum.unit(str(u)).is_empty(), "%s: %s is a unit of the School" % [e.id, u])
		assert_true(LabExperiments.experiment(str(e.id)).has("units"))
	assert_has(LabExperiments.for_unit("g3.science.magnets"), "magnets")
	assert_has(LabExperiments.for_unit("g3.science.plants_needs"), "plants")
	assert_eq(LabExperiments.for_unit("g4.maths.big_numbers"), [] as Array[String])


func test_learn_more_picks_the_childs_grade_or_the_nearest_below() -> void:
	var e := LabExperiments.experiment("melting")   # grades 4, 4, 5, 7
	assert_eq(LabExperiments.learn_unit(e, 5), "g5.science.particles")
	assert_eq(LabExperiments.learn_unit(e, 4), "g4.science.states_of_matter", "the first of the grade")
	assert_eq(LabExperiments.learn_unit(e, 6), "g5.science.particles", "none in grade 6: the grade below")
	assert_eq(LabExperiments.learn_unit(e, 3), "g4.science.states_of_matter", "none so low: the first")
	assert_eq(LabExperiments.learn_unit(e, 0), "g4.science.states_of_matter", "no grade picked yet")


# --- Predictions ---------------------------------------------------------------------------------------------------

func test_every_prediction_is_a_school_exercise_whose_answer_is_what_happens() -> void:
	for e in _all():
		var p := LabExperiments.predict_of(e)
		assert_has(["choice", "sort"], str(p.get("type", "")), e.id)
		assert_true(ExerciseCheck.is_right(p, ExerciseCheck.answer_of(p)), "%s: its own answer" % e.id)
		if str(p.type) == "sort":
			var things: Array = e.scene.things
			assert_eq((p.items as Array).size(), things.size(), "%s: a card for every thing" % e.id)
			var model := LabModels.make(e.scene)
			var seen := _drop_all(model)
			assert_eq(p.answer, seen, "%s: the sort's answer is what the things really do" % e.id)
			var r: Array = (p.answer as Array).duplicate()
			r.reverse()
			assert_ne(r, p.answer, "%s: never already sorted" % e.id)


func test_a_prediction_is_never_marked_but_its_words_are_kept() -> void:
	var sink := LabExperiments.experiment("float_sink")
	var p := LabExperiments.predict_of(sink)
	var all_float: Array[int] = []
	for i in (p.items as Array).size():
		all_float.append(0)
	assert_eq(LabExperiments.predict_words(sink, all_float),
		"Floats: wood, stone, ice, iron nail, leaf, gold ring, dry sponge, glass marble.")
	assert_false(LabExperiments.matched(sink, all_float))
	assert_true(LabExperiments.matched(sink, ExerciseCheck.answer_of(p)))
	var melt := LabExperiments.experiment("melting")
	assert_eq(LabExperiments.predict_words(melt, 3), "100 °C")
	assert_false(LabExperiments.matched(melt, 3))
	assert_true(LabExperiments.matched(melt, 0))
	assert_eq(LabExperiments.predict_words(melt, null), "", "no guess yet")


# --- Scenes and facts ----------------------------------------------------------------------------------------------

func _drop_all(model: LabModel) -> Array[int]:
	if model is LabTank:
		for i in (model as LabTank).things.size():
			(model as LabTank).drop(i)
		return (model as LabTank).sorted()
	for i in (model as LabMagnet).things.size():
		(model as LabMagnet).test(i)
	return (model as LabMagnet).sorted()


func test_every_scene_can_be_made() -> void:
	for e in _all():
		assert_eq(LabModels.problem(e.scene), "", e.id)
		assert_not_null(LabModels.make(e.scene), e.id)


func test_floating_follows_density() -> void:
	for kind: String in ["float_sink"]:
		for t: Dictionary in LabExperiments.experiment(kind).scene.things:
			assert_true(DENSITY.has(t.thing), "%s: a density to check" % t.thing)
			assert_eq(bool(t.floats), float(DENSITY.get(t.thing, 1.0)) < 1.0, "%s floats only if less dense than water" % t.name)
	var m := LabModels.make(LabExperiments.experiment("float_sink").scene) as LabTank
	var got := _drop_all(m)
	var floated := 0
	for g in got:
		floated += 1 if g == 0 else 0
	assert_eq(floated, 4, "wood, ice, a leaf and a sponge float (spec §23.1)")


func test_only_iron_and_steel_stick() -> void:
	for t: Dictionary in LabExperiments.experiment("magnets").scene.things:
		assert_true(MAGNETIC.has(t.thing), "%s: known" % t.thing)
		assert_eq(bool(t.magnetic), bool(MAGNETIC.get(t.thing, false)), t.name)


func test_water_melts_at_0_and_boils_at_100_degrees() -> void:
	var s: Dictionary = LabExperiments.experiment("melting").scene
	assert_eq(int(s.melt), 0)
	assert_eq(int(s.boil), 100)
	assert_lte(int(s.low), -18, "an ice bath with salt gets as cold as a freezer (about −20 °C)")
	var p := LabExperiments.predict_of(LabExperiments.experiment("melting"))
	assert_eq(ExerciseCheck.answer_text(p), "0 °C")


func test_light_adds_and_paint_mixes_as_the_school_teaches() -> void:
	var s: Dictionary = LabExperiments.experiment("colours").scene
	# light: additive RGB, worked out here
	var rgb := {"red": Vector3(1, 0, 0), "green": Vector3(0, 1, 0), "blue": Vector3(0, 0, 1)}
	var sum := (rgb.red as Vector3) + (rgb.green as Vector3)
	assert_eq(sum, Vector3(1, 1, 0), "red + green light: yellow")
	assert_eq(LabColours.light_name(["red", "green"]), "yellow")
	assert_eq(LabColours.light_name(["red", "green", "blue"]), "white")
	assert_eq(LabColours.light_name(["red", "blue"]), "magenta")
	assert_eq(LabColours.light_name(["green", "blue"]), "cyan")
	assert_eq(LabColours.light_colour(["red", "green"]), Color(1, 1, 0))
	assert_eq(LabColours.light_colour(["red", "green", "blue"]), Color(1, 1, 1))
	# paint: the School's recipes (ColourMix)
	assert_eq(s.paint_goals, ["orange", "green", "brown"])
	assert_true(ColourMix.matches("orange", {"red": 1, "yellow": 1}))
	assert_true(ColourMix.matches("green", {"blue": 1, "yellow": 1}))
	assert_true(ColourMix.matches("brown", {"red": 1, "yellow": 1, "blue": 1}))
	var p := LabExperiments.predict_of(LabExperiments.experiment("colours"))
	assert_eq(ExerciseCheck.answer_text(p), "Yellow", "red and green light make yellow")


func test_seeds_need_water_to_sprout_and_light_to_grow_green() -> void:
	var s: Dictionary = LabExperiments.experiment("plants").scene
	assert_eq(int(s.days), 2, "two game days (spec §23.1)")
	var at := 1_000_000
	var clock := [at]
	var m := LabModels.make(s, func() -> int: return clock[0]) as LabPlants
	for i in m.pots.size():
		m.plant(i)
	clock[0] = at + int(2 * LabPlants.DAY)
	for i in m.pots.size():
		var pot: Dictionary = m.pots[i]
		if not pot.water:
			assert_eq(m.look(i), LabPlants.SEED, "%s: no water, no sprout" % pot.name)
		elif pot.light:
			assert_eq(m.look(i), LabPlants.PLANT, "%s: a green plant" % pot.name)
		else:
			assert_eq(m.look(i), LabPlants.PALE_SHOOT, "%s: a pale, thin shoot" % pot.name)
	var p := LabExperiments.predict_of(LabExperiments.experiment("plants"))
	assert_eq(ExerciseCheck.answer_text(p), "Light and water")


func test_a_bulb_lights_only_in_a_closed_loop() -> void:
	var m := LabModels.make(LabExperiments.experiment("circuit").scene) as LabCircuit
	assert_false(m.lit(), "the switch starts open")
	m.toggle_switch()
	assert_true(m.lit())
	m.toggle_wire(0)
	assert_false(m.lit(), "a gap")
	var p := LabExperiments.predict_of(LabExperiments.experiment("circuit"))
	assert_eq(ExerciseCheck.answer_text(p), "The bulb goes out")


func test_supplies_are_a_few_ordinary_blocks() -> void:
	for e in _all():
		var s := LabExperiments.supplies(e)
		assert_between(s.size(), 1, 3, e.id)
		var total := 0
		for id: int in s:
			assert_true(Inventory.ownable(id), "%s: %s is a block a bag holds" % [e.id, BlockIds.display_name(id)])
			assert_false(LootRules.TREASURE_ONLY.has(id))
			total += int(s[id])
		assert_between(total, 1, 3, "%s: a few blocks" % e.id)


func test_the_burner_and_the_battery_carry_safety_words() -> void:
	for id in ["melting", "circuit"]:
		var words := str(LabExperiments.experiment(id).get("safety", ""))
		assert_string_contains(words, "Never", id)


# --- Words ---------------------------------------------------------------------------------------------------------

func _texts() -> Array[String]:
	var out: Array[String] = []
	for e in _all():
		out.append_array(LabExperiments.words_of(e))
	return out


func test_the_words_are_kind_and_our_own() -> void:
	var found: Array[String] = []
	for t in _texts():
		var lower := t.to_lower()
		for w in SchoolContent.UNKIND + SchoolContent.OTHER_GAMES:
			if RegEx.create_from_string("\\b" + w + "\\b").search(lower):
				found.append("'%s' in: %s" % [w, t])
	assert_eq(found, [] as Array[String], "\n".join(found))


func test_british_spelling() -> void:
	var found: Array[String] = []
	for t in _texts():
		var lower := t.to_lower()
		for w in SchoolContent.US_SPELLINGS + ["aluminum", "centers", "gray", "neighbor"]:
			if RegEx.create_from_string("\\b" + w + "\\b").search(lower):
				found.append("'%s' in: %s" % [w, t])
	assert_eq(found, [] as Array[String], "\n".join(found))


func test_english_letters_and_the_fonts_symbols_only() -> void:
	var found: Array[String] = []
	for t in _texts():
		for ch in t:
			if ch.unicode_at(0) > 127 and not SchoolContent.ALLOWED.contains(ch):
				found.append("'%s' in: %s" % [ch, t])
				break
	assert_eq(found, [] as Array[String], "\n".join(found))
	assert_gt(_texts().size(), 60, "every word a child reads was looked at")
