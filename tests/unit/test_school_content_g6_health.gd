extends GutTest
## Owner #70 and #73 ("start from grade 3 and finish all grades accordingly"; research §6.6), the grade 6 life agent:
## every HEALTH AND PE, DESIGN AND TECHNOLOGY and PROJECTS unit of grade 6's outline (England's PE, RSHE and D&T, SHAPE
## America, NHES, CASEL, Finland's crafts and home economics, Finland's modules, the IB, Cambridge Global Perspectives)
## is written, building on grades 3, 4 and 5: a lesson of 4 to 8 cards that opens with a memory question from an
## earlier grade and ends with something to try in the world and what comes next (research §5.3 rules 1, 7 and 8), at
## least 12 hand-written exercises at levels 1, 2 and 3 of two kinds or more, each with a strategy hint and a worked
## answer, and rounds that fill, vary and never show a hand-written exercise twice. Health is taught kindly (no weight
## talk, no good or bad bodies or foods, nothing about puberty or reproduction: research §5.4 rule 4); smoking, vaping
## and alcohol are taught only in their own unit, factually: the body, the law and saying no, nothing that shows use
## (rule 5). The facts a child's safety depends on are in the lessons (checked against the NHS, the British Red Cross,
## the Resuscitation Council UK, Food - a fact of life and UK law: docs/devlog/parts/m8-grade6-health.md), and the rules
## the pictures teach (lever classes, linkages, a truss's triangles, the food danger zone) are worked out again here.
## (Every exercise's validity, answers, pictures, sounds and words are the shared content test's, test_school_content.gd.)

const GRADE := 6
const UNITS := {"health_pe": 11, "design_tech": 9, "projects": 3}   # research §6.6
const MIN_EXERCISES := 12
const MIN_CARDS := 4
const MIN_DISTINCT := 12
## Grade 6 generators these units use: their own ("g6w", G6HealthGen).
const OWN_GEN := "g6w."
## Words a health lesson for 11-year-olds never uses (research §5.4 rule 4; no weight talk, no shaming about food). (A
## recipe may still "weigh" its flour; a lever lifts a "load".)
const NOT_IN_HEALTH: Array[String] = ["weight", "weights", "overweight", "underweight", "skinny", "fat people", "calorie",
	"calories", "junk", "naughty", "bad food", "bad foods", "diet", "diets", "dieting", "puberty", "reproduction", "sex"]
## Harmful substances and gambling (research §5.4 rule 5): only in the unit that teaches them factually.
const SUBSTANCES: Array[String] = ["drug", "drugs", "alcohol", "alcoholic", "beer", "wine", "drunk", "cigarette",
	"cigarettes", "e-cigarette", "e-cigarettes", "tobacco", "smoking", "smoker", "smokers", "vape", "vapes", "vaping",
	"nicotine", "gambling", "gamble", "betting"]
const SUBSTANCES_UNIT := "g6.health_pe.smoking_vaping_alcohol"
## Words that would show or invite use (rule 5: "nothing shows use").
const SHOWS_USE: Array[String] = ["how to smoke", "light a cigarette", "take a puff", "have a sip", "try a sip",
	"try a vape", "try vaping", "try smoking", "cool to smoke", "cool to vape", "just one", "one won't hurt"]
## Pictures with people in them, never in the substances unit.
const FIGURES: Array[String] = ["pose", "lying", "track_field", "fast_signs", "pitch"]
const CURRENCIES: Array[String] = ["dollar", "dollars", "euro", "euros", "pound", "pounds", "pence", "penny", "pennies",
	"yen", "rupee", "rupees", "yuan"]
const PERSONAL := "(what is|what's|tell us|type|enter|write) your (real |full |home |school )?(name|address|phone|number|password|school|birthday|age|email)"
## The facts each lesson must say (research §6.6 goals; the sources are in the notes).
const MUST := {
	"g6.health_pe.training_principles": ["frequency", "intensity", "time", "type", "overload", "warm up", "cool down",
		"60 minutes", "pulse", "talk test"],
	"g6.health_pe.team_tactics": ["formation", "width", "support", "attack", "defend", "fair play"],
	"g6.health_pe.athletics_technique": ["on your marks", "set", "baton", "zone", "30 m", "take-off", "nearest mark",
		"hop"],
	"g6.health_pe.analyse_improve": ["preparation", "execution", "recovery", "what went well", "even better if"],
	"g6.health_pe.food_as_fuel": ["energy", "carbohydrate", "protein", "fibre", "calcium", "iron", "water", "breakfast",
		"5 a day"],
	"g6.health_pe.mental_health": ["mental health", "connect", "be active", "keep learning", "give", "take notice",
		"trusted adult", "0800 1111"],
	"g6.health_pe.stress_coping": ["stress", "box breathing", "plan", "talk", "trusted adult"],
	"g6.health_pe.respectful_relationships": ["respect", "trust", "personal space", "ask", "bullying", "trusted adult"],
	"g6.health_pe.smoking_vaping_alcohol": ["tar", "carbon monoxide", "nicotine", "addictive", "alcohol", "vaping",
		"against the law", "under 18", "say no", "trusted adult"],
	"g6.health_pe.serious_emergencies": ["999", "112", "breathing", "bleeding", "burn", "20 minutes", "fast", "cpr",
		"trained", "defibrillator"],
	"g6.health_pe.outdoor_challenge": ["route", "map", "compass", "weather", "tell someone", "whistle",
		"countryside code"],
	"g6.design_tech.user_centred_design": ["user", "interview", "open question", "specification", "measurable"],
	"g6.design_tech.ideas_from_nature": ["biomimicry", "burr", "hook-and-loop", "kingfisher", "train"],
	"g6.design_tech.structures_forces": ["compression", "tension", "triangle", "strut", "tie"],
	"g6.design_tech.mechanisms": ["class 1", "class 2", "class 3", "pivot", "linkage", "gear ratio"],
	"g6.design_tech.sensors_switches": ["sensor", "input", "process", "output", "light", "temperature", "threshold"],
	"g6.design_tech.food_science": ["bacteria", "5 °c", "63 °c", "75 °c", "use by", "best before", "fridge"],
	"g6.design_tech.cook_on_a_budget": ["budget", "per portion", "balanced", "gold", "wash"],
	"g6.design_tech.material_families": ["hardwood", "softwood", "ferrous", "non-ferrous", "thermoplastic", "thermoset",
		"composite"],
	"g6.design_tech.design_movements": ["arts and crafts", "bauhaus", "form follows function", "william morris", "1919"],
	"g6.projects.market_town": ["charter", "guild", "ratio", "fair"],
	"g6.projects.weather_station": ["rain gauge", "wind vane", "anemometer", "spreadsheet", "=average", "chart"],
	"g6.projects.design_for_a_need": ["interview", "specification", "prototype", "test", "present"],
}
## The pictures each unit needs, over its lesson, its exercises and its generators' ([kind, how many], …).
const DRAWS := {
	"g6.health_pe.training_principles": [["talk_test", 2]],
	"g6.health_pe.team_tactics": [["pitch", 3]],
	"g6.health_pe.athletics_technique": [["track_field", 4]],
	"g6.health_pe.analyse_improve": [["table", 2]],
	"g6.health_pe.food_as_fuel": [["plate", 2]],
	"g6.health_pe.mental_health": [["hand", 1]],
	"g6.health_pe.stress_coping": [["breath_box", 2], ["control_rings", 1]],
	"g6.health_pe.smoking_vaping_alcohol": [["lungs", 1]],
	"g6.health_pe.serious_emergencies": [["fast_signs", 2]],
	"g6.health_pe.outdoor_challenge": [["os_map", 2]],
	"g6.design_tech.user_centred_design": [["access_fm", 2]],
	"g6.design_tech.ideas_from_nature": [["biomimicry", 4]],
	"g6.design_tech.structures_forces": [["truss", 3], ["struct_force", 3]],
	"g6.design_tech.mechanisms": [["lever_class", 4], ["linkage", 3], ["gears", 2]],
	"g6.design_tech.sensors_switches": [["sensor_system", 3], ["threshold_graph", 2]],
	"g6.design_tech.food_science": [["food_thermo", 3], ["microbe_split", 2]],
	"g6.design_tech.cook_on_a_budget": [["table", 3]],
	"g6.design_tech.material_families": [["material_swatch", 4]],
	"g6.design_tech.design_movements": [["design_style", 4]],
	"g6.projects.market_town": [["table", 2]],
	"g6.projects.weather_station": [["weather_kit", 3], ["sheet", 2]],
	"g6.projects.design_for_a_need": [["table", 2]],
}
## Units whose label exercises must exist (label the diagram), with how many.
const LABELS := {"g6.design_tech.mechanisms": 1, "g6.design_tech.sensors_switches": 1, "g6.projects.weather_station": 1}
## The CPR beat heard in "Serious emergencies": 100 to 120 pushes a minute (the Resuscitation Council UK).
const CPR_UNIT := "g6.health_pe.serious_emergencies"


func _units() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for subject: String in UNITS:
		out.append_array(Curriculum.units(GRADE, subject))
	return out


func _texts(c: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for card: Dictionary in c.lesson:
		out.append(str(card.get("text", "")))
	for ex: Dictionary in c.exercises:
		out.append_array(_ex_texts(ex))
	return out


func _ex_texts(ex: Dictionary) -> Array[String]:
	var out: Array[String] = [str(ex.get("prompt", "")), str(ex.get("hint", "")), str(ex.get("explain", ""))]
	for t: Variant in ex.get("choices", []) + ex.get("items", []) + ex.get("matches", []) + ex.get("groups", []) \
			+ ex.get("labels", []):
		out.append(ExerciseCheck.item_text(t))
	return out


## A unit's texts with its generators' at every level.
func _all_texts(id: String, seeds: int = 12) -> Array[String]:
	var c := Curriculum.content(id)
	var texts := _texts(c)
	for g: Dictionary in c.generators:
		for s in seeds:
			texts.append_array(_ex_texts(SchoolGen.make(str(g.gen), s, int(g.level))))
	return texts


func _lesson(id: String) -> String:
	var out := ""
	for card: Dictionary in Curriculum.content(id).lesson:
		out += str(card.text) + " "
	return out.to_lower()


## A unit's exercises: hand-written, and its generators' for `seeds` seeds.
func _exercises(id: String, seeds: int = 0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var c := Curriculum.content(id)
	for ex: Dictionary in c.exercises:
		out.append(ex)
	for g: Dictionary in c.generators:
		for s in seeds:
			out.append(SchoolGen.make(str(g.gen), s, int(g.level)))
	return out


## Every picture of a unit (on its cards, its exercises and their choices), with its generators' for `seeds` seeds.
func _pictures(id: String, seeds: int = 0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for card: Dictionary in Curriculum.content(id).lesson:
		if card.get("picture") is Dictionary:
			out.append(card.picture)
	for ex in _exercises(id, seeds):
		if ex.get("picture") is Dictionary:
			out.append(ex.picture)
		for ch: Variant in ex.get("choices", []):
			if ch is Dictionary and ch.get("picture") is Dictionary:
				out.append(ch.picture)
	return out


func _found(t: String, words: Array[String]) -> String:
	for w in words:
		if RegEx.create_from_string("\\b" + w + "\\b").search(t.to_lower()):
			return w
	return ""


func test_the_outline_has_every_unit_of_the_research() -> void:
	for subject: String in UNITS:
		assert_eq(Curriculum.units(GRADE, subject).size(), int(UNITS[subject]), "grade 6 %s" % subject)


func test_grade_6_health_dt_projects_are_written_for_every_unit() -> void:
	var exercises := 0
	var cards := 0
	for u in _units():
		var id := str(u.id)
		assert_true(Curriculum.has_content(id), "%s is written" % id)
		if not Curriculum.has_content(id):
			continue
		assert_eq(Curriculum.content_problems(id), [] as Array[String], id)
		var c := Curriculum.content(id)
		assert_between((c.lesson as Array).size(), MIN_CARDS, Curriculum.MAX_CARDS, "%s: a lesson of 4 to 8 cards" % id)
		assert_gte((c.exercises as Array).size(), MIN_EXERCISES, "%s: at least %d hand-written exercises" % [id,
			MIN_EXERCISES])
		exercises += (c.exercises as Array).size()
		cards += (c.lesson as Array).size()
		var levels := {}
		var types := {}
		for ex: Dictionary in c.exercises:
			levels[int(ex.level)] = true
			types[str(ex.type)] = true
		assert_eq(levels.keys().size(), 3, "%s: hand-written exercises at levels 1, 2 and 3" % id)
		assert_gte(types.size(), 2, "%s: at least two kinds of exercise" % id)
		var distinct := {}
		for stars in [0, 1, 2]:
			for s in 20:
				var round := RoundPlan.plan(c, s * 7 + stars, stars)
				assert_eq(round.size(), MasteryRules.ROUND_SIZE, "%s fills a round" % id)
				var ids := {}
				for ex in round:
					distinct[str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("sound", "")) + str(ex.get("board", ""))] = true
					if not str(ex.id).begins_with("gen:"):
						assert_false(ids.has(ex.id), "%s: %s twice in a round" % [id, ex.id])
						ids[ex.id] = true
		assert_gte(distinct.size(), MIN_DISTINCT, "%s: varied practice" % id)
	gut.p("grade 6 health and PE, D&T and projects: %d cards, %d hand-written exercises" % [cards, exercises])


## The outline keeps its standards and goals, and every unit names its own grade 6 file.
func test_the_files_are_their_own() -> void:
	for u in _units():
		var parts := str(u.id).split(".")
		assert_eq(str(u.get("file", "")), "g6/%s/%s.json" % [parts[1], parts[2]], "%s's file" % u.id)
		assert_gt((u.get("standards", []) as Array).size(), 0, "%s: its standards" % u.id)
		assert_gt((u.get("goals", []) as Array).size(), 0, "%s: its goals" % u.id)


## Research §5.3: every exercise has a strategy hint (not the answer itself) and a worked answer.
func test_every_exercise_has_a_strategy_hint_and_a_worked_answer() -> void:
	for u in _units():
		if not Curriculum.has_content(str(u.id)):
			continue
		for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
			assert_ne(str(ex.get("hint", "")).strip_edges(), "", "%s: a hint" % ex.id)
			assert_ne(str(ex.get("explain", "")).strip_edges(), "", "%s: a worked answer" % ex.id)
			assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: the hint is a strategy, not the answer" % ex.id)


## Research §5.3 rules 1, 7 and 8: a memory question from an earlier grade first; something to try in the world and
## what comes next last.
func test_every_lesson_starts_with_memory_of_an_earlier_grade_and_ends_in_the_world_with_what_comes_next() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		var cards: Array = Curriculum.content(id).lesson
		var first := str(cards[0].text)
		assert_true(first.begins_with("Quick memory:") and first.contains("?"), "%s: the first card asks a memory question" % id)
		assert_true(first.contains("grade 3") or first.contains("grade 4") or first.contains("grade 5"),
			"%s: the first card names the grade it builds on" % id)
		var last := str(cards[-1].text)
		assert_true(last.begins_with("Try it in the world:"), "%s: the last card is something to try in the world" % id)
		assert_true(last.contains("Next"), "%s: the last card says what comes next" % id)


## A hand-written exercise's prompt appears once in a unit (a round never shows the same question twice by another id).
func test_no_unit_asks_the_same_question_twice() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		var seen := {}
		for ex: Dictionary in Curriculum.content(id).exercises:
			var key := str(ex.prompt) + str(ex.get("picture", ""))
			assert_false(seen.has(key), "%s asks twice: %s" % [id, ex.prompt])
			seen[key] = true


## The units use grade 6's own health, D&T and projects generators ("g6w"), each of which exists, and every "g6w"
## generator is used by one of them.
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for u in _units():
		if not Curriculum.has_content(str(u.id)):
			continue
		for g: Dictionary in Curriculum.content(str(u.id)).generators:
			var gen := str(g.gen)
			assert_true(gen.begins_with(OWN_GEN), "%s uses %s" % [u.id, gen])
			assert_true(SchoolGen.exists(gen), "%s: %s exists" % [u.id, gen])
			used[gen] = true
	var own := 0
	for gen in SchoolGen.ids():
		if gen.begins_with(OWN_GEN):
			own += 1
			assert_true(used.has(gen), "%s is used by a grade 6 health, D&T or project unit" % gen)
	assert_gt(own, 20, "grade 6's health, D&T and projects generators exist")


## The facts a child's safety and health depend on, and each unit's goals, are in the lessons.
func test_the_lessons_teach_their_facts() -> void:
	for id: String in MUST:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var lesson := _lesson(id)
		for fact: String in MUST[id]:
			assert_true(lesson.contains(fact.to_lower()), "%s's lesson says '%s'" % [id, fact])


## Research §5.4 rule 4 and the brief: never shaming about bodies or food, no weight talk, nothing about puberty or
## reproduction, in any card, exercise or generated exercise.
func test_health_is_taught_kindly() -> void:
	var found: Array[String] = []
	for u in _units():
		if not Curriculum.has_content(str(u.id)):
			continue
		for t in _all_texts(str(u.id)):
			var w := _found(t, NOT_IN_HEALTH)
			if w != "":
				found.append("%s: '%s' in: %s" % [u.id, w, t])
	assert_eq(found, [] as Array[String], "\n".join(found))


## Research §5.4 rule 5: tobacco, vaping and alcohol only in the unit that teaches them factually (the body, the law
## and saying no), with nothing that shows or invites use and no people drawn; and that unit teaches all of them.
func test_harmful_substances_are_taught_only_factually_in_their_own_unit() -> void:
	var found: Array[String] = []
	for u in _units():
		if not Curriculum.has_content(str(u.id)):
			continue
		for t in _all_texts(str(u.id)):
			var w := _found(t, SUBSTANCES)
			if w != "" and str(u.id) != SUBSTANCES_UNIT:
				found.append("%s: '%s' in: %s" % [u.id, w, t])
			var use := _found(t, SHOWS_USE)
			if use != "":
				found.append("%s: '%s' in: %s" % [u.id, use, t])
	assert_eq(found, [] as Array[String], "\n".join(found))
	if not Curriculum.has_content(SUBSTANCES_UNIT):
		fail_test("%s is not written" % SUBSTANCES_UNIT)
		return
	var lesson := _lesson(SUBSTANCES_UNIT)
	for w: String in ["tobacco", "vaping", "alcohol", "against the law", "under 18", "say no", "trusted adult"]:
		assert_true(lesson.contains(w), "%s's lesson says '%s'" % [SUBSTANCES_UNIT, w])
	for p in _pictures(SUBSTANCES_UNIT, 6):
		assert_false(str(p.get("kind", "")) in FIGURES, "%s: no people drawn" % SUBSTANCES_UNIT)


## Money is the game's gold (research §5.5 ruling 6), and no lesson asks a child for personal details (rule 6).
func test_money_is_gold_and_nothing_personal_is_asked() -> void:
	var ask := RegEx.create_from_string(PERSONAL)
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for t in _all_texts(id, 6):
			assert_false(t.contains("$") or t.contains("£"), "%s: %s" % [id, t])
			var w := _found(t, CURRENCIES)
			assert_eq(w, "", "%s: '%s' in %s" % [id, w, t])
			assert_null(ask.search(t.to_lower()), "%s asks: %s" % [id, t])


## The units that need a picture to be taught have theirs.
func test_the_units_are_drawn() -> void:
	for id: String in DRAWS:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var counts := {}
		for p in _pictures(id, 6):
			counts[str(p.get("kind", ""))] = int(counts.get(str(p.get("kind", "")), 0)) + 1
		for need: Array in DRAWS[id]:
			assert_gte(int(counts.get(str(need[0]), 0)), int(need[1]), "%s: %s pictures" % [id, need[0]])


## Label the diagram: every label's line ends on its own part of the picture (SchoolPictureG6Health.part_at, at the
## label box's size), so the pins can be trusted; and the units that label have their label exercises.
func test_every_label_points_at_its_part() -> void:
	var checked := 0
	for id: String in LABELS:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var n := 0
		for ex in _exercises(id):
			if str(ex.type) != "label":
				continue
			n += 1
			assert_true(SchoolPictureG6Health.KINDS.has(str(ex.picture.kind)), "%s: a grade 6 life picture" % ex.id)
			for i in (ex.labels as Array).size():
				var spot: Array = ex.spots[int(ex.answer[i])]
				assert_eq(spot.size(), 4, "%s: a line from the pin to the part" % ex.id)
				if spot.size() != 4:
					continue
				var part := SchoolPictureG6Health.part_at(ex.picture, str(ex.labels[i]), ExerciseCheck.LABEL_BOX)
				assert_ne(part, Vector2(-1, -1), "%s: the picture has a %s" % [ex.id, ex.labels[i]])
				var tip := Vector2(float(spot[2]), float(spot[3])) * ExerciseCheck.LABEL_BOX
				assert_lt(tip.distance_to(part), 14.0, "%s: the line to %s ends on it" % [ex.id, ex.labels[i]])
				checked += 1
		assert_gte(n, int(LABELS[id]), "%s: label exercises" % id)
	assert_gte(checked, 9, "labels were checked")


## The CPR beat can be heard (a steady clap at 100 to 120 a minute), every project has a build on the block board.
func test_the_cpr_beat_is_heard_and_projects_are_built() -> void:
	if Curriculum.has_content(CPR_UNIT):
		var beats := 0
		var c := Curriculum.content(CPR_UNIT)
		for item: Dictionary in (c.lesson as Array) + (c.exercises as Array):
			var s: Variant = item.get("sound")
			if s is Dictionary and str(s.get("kind", "")) == "rhythm":
				# each letter is half a beat: claps a minute = claps ÷ the pattern's beats × beats a minute
				var per_minute := float(s.get("tempo", 100)) * str(s.pattern).count("x") / (str(s.pattern).length() * 0.5)
				assert_between(per_minute, 100.0, 120.0, "%s: the beat is 100-120 a minute (%s)" % [CPR_UNIT, s])
				beats += 1
		assert_gte(beats, 2, "%s: the CPR beat to listen to" % CPR_UNIT)
	else:
		fail_test("%s is not written" % CPR_UNIT)
	for u in Curriculum.units(GRADE, "projects"):
		if not Curriculum.has_content(str(u.id)):
			fail_test("%s is not written" % u.id)
			continue
		var builds := 0
		for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
			builds += 1 if str(ex.type) == "build" else 0
		assert_gte(builds, 1, "%s: a build on the block board" % u.id)


# --- The rules the pictures teach, worked out again (this test's own) ------------------------------------------------

## A lever's class: what is in the middle (class 1 the pivot, class 2 the load, class 3 the effort).
func _lever_class(pivot: int, load: int, effort: int) -> int:
	var mid := [pivot, load, effort]
	mid.sort()
	return 1 if mid[1] == pivot else (2 if mid[1] == load else 3)


func _opposite(way: String) -> String:
	return {"left": "right", "right": "left", "up": "down", "down": "up"}.get(way, "")


## Every choice about a lever's class, a linkage's output, a temperature's zone and a truss's triangles and bars that
## the units ask (hand-written and generated) has the answer this test works out.
func test_the_pictures_rules_are_right() -> void:
	var checked := 0
	var ids: Array[String] = ["g6.design_tech.mechanisms", "g6.design_tech.structures_forces",
		"g6.design_tech.food_science"]
	for id in ids:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		for ex in _exercises(id, 20):
			var pic: Variant = ex.get("picture")
			if not pic is Dictionary:
				continue
			var kind := str(pic.get("kind", ""))
			var right := ""
			if str(ex.type) == "choice":
				right = ExerciseCheck.item_text(ex.choices[int(ex.answer)]).to_lower()
			if kind == "lever_class" and right.begins_with("class "):
				assert_eq(right.substr(0, 7), "class %d" % _lever_class(int(pic.pivot), int(pic.load), int(pic.effort)),
					"%s: %s" % [ex.id, ex.prompt])
				checked += 1
			elif kind == "linkage" and right in ["left", "right", "up", "down"]:
				var move := str(pic.get("move", "right"))
				var want := ""
				match str(pic.type):
					"reverse":
						want = _opposite(move)
					"parallel":
						want = move
					"bell_crank":
						want = "down" if move == "right" else "up"
				assert_eq(right, want, "%s: %s" % [ex.id, ex.prompt])
				checked += 1
			elif kind == "food_thermo" and pic.has("value") and str(ex.type) == "choice" \
					and str(ex.prompt).to_lower().contains("zone"):
				var t := int(pic.value)
				var zone := "freezer" if t <= -18 else ("fridge" if t >= 0 and t <= 5 else ("danger zone" if t > 5 and t < 63
					else ("hot" if t >= 63 else "")))
				assert_true(zone != "" and right.contains(zone), "%s: %d °C is %s, not %s" % [ex.id, t, zone, right])
				checked += 1
			elif kind == "truss" and str(ex.type) == "number":
				var p := int(pic.panels)
				var prompt := str(ex.prompt).to_lower()
				if prompt.contains("how many triangles"):
					assert_eq(NumberAnswer.value(str(ex.answer)), float(2 * p - 1), "%s: %s" % [ex.id, ex.prompt])
					checked += 1
				elif prompt.contains("how many bars"):
					assert_eq(NumberAnswer.value(str(ex.answer)), float(4 * p - 1), "%s: %s" % [ex.id, ex.prompt])
					checked += 1
	assert_gte(checked, 20, "the pictures' rules were checked")
