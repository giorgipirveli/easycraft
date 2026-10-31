extends GutTest
## Owner #70, #73 and #111 ("we want to have full school programs and sylabusse content in the game"; research §6.7),
## the grade 7 life agent: every HEALTH AND PE, DESIGN AND TECHNOLOGY and PROJECTS unit of grade 7's outline (England's
## KS3 PE, RSHE and D&T, SHAPE America, NHES, CASEL, Finland's crafts and home economics, the IB, Cambridge Global
## Perspectives) is written, one step up from grade 6: a lesson of 4 to 8 cards that opens with a memory question from an
## earlier grade and ends with something to try in the world and what comes next (research §5.3 rules 1, 7 and 8), at
## least 12 hand-written exercises at levels 1, 2 and 3 of two kinds or more, each with a strategy hint and a worked
## answer, and rounds that fill, vary and never show a hand-written exercise twice. Health is taught kindly (no weight
## talk, nothing about puberty or reproduction: research §5.4 rule 4); drugs are taught only in their own unit,
## factually: what they are, the risks, the law and getting help, with no street drug named and nothing that shows use
## (rule 5). Owner #112 and #117 (learn by doing): a unit whose topic is a Life Experience ends by sending the child to
## it by name in the LIFE tab, and D&T's structures, materials and tools to Real Builder and the Tool Book. The rules the
## pictures teach (heart-rate zones, hours of sleep, a resistor's bands, a circuit that is complete) are worked out again
## here. (Every exercise's validity, answers, pictures, sounds and words are the shared content test's,
## test_school_content.gd; the quality bar is test_school_quality.gd's.)

const GRADE := 7
const UNITS := {"health_pe": 11, "design_tech": 9, "projects": 3}   # research §6.7
const MIN_EXERCISES := 12
const MIN_CARDS := 4
const MIN_DISTINCT := 12
## Grade 7 generators these units use: their own ("g7w", G7LifeGen).
const OWN_GEN := "g7w."
## Words a health lesson for 12-year-olds never uses (research §5.4 rule 4; no weight talk, no shaming about food). (A
## recipe may still "weigh" its flour; a load has a "mass".)
const NOT_IN_HEALTH: Array[String] = ["weight", "weights", "overweight", "underweight", "skinny", "fat people", "calorie",
	"calories", "junk", "naughty", "bad food", "bad foods", "diet", "diets", "dieting", "puberty", "reproduction", "sex"]
## Drugs, alcohol, tobacco and gambling (research §5.4 rule 5): only in the unit that teaches them factually. (Caffeine
## is named in sleep and in adverts for energy drinks, as grade 5's sleep unit names it.)
const SUBSTANCES: Array[String] = ["drug", "drugs", "alcohol", "alcoholic", "beer", "wine", "drunk", "cigarette",
	"cigarettes", "e-cigarette", "tobacco", "smoking", "smoker", "vape", "vapes", "vaping", "nicotine", "gambling",
	"gamble", "betting", "solvent", "solvents"]
const SUBSTANCES_UNIT := "g7.health_pe.drugs_and_the_law"
## Never named anywhere (ruling: the law's classes are taught by harm, without street names).
const STREET_DRUGS: Array[String] = ["cannabis", "cocaine", "heroin", "ecstasy", "mdma", "lsd", "ketamine", "crack",
	"weed", "skunk", "spice", "meth"]
## Words that would show or invite use (rule 5: "nothing shows use").
const SHOWS_USE: Array[String] = ["how to smoke", "take a puff", "have a sip", "try a sip", "try a vape", "try it once",
	"just once", "one won't hurt", "how to take", "how much to take", "safe dose", "get high"]
## Pictures with people in them, never in the drugs unit.
const FIGURES: Array[String] = ["pose", "lying", "track_field", "fast_signs", "pitch", "ref_signal", "photo_edit",
	"advert"]
const CURRENCIES: Array[String] = ["dollar", "dollars", "euro", "euros", "pound", "pounds", "pence", "penny", "pennies",
	"yen", "rupee", "rupees", "yuan", "lari"]
const PERSONAL := "(what is|what's|tell us|type|enter|write) your (real |full |home |school )?(name|address|phone|number|password|school|birthday|age|email)"
## The facts each lesson must say (research §6.7 goals; the sources are in docs/devlog/parts/school-g7-dt-hpe-projects.md).
const MUST := {
	"g7.health_pe.invasion_advanced": ["overlap", "switch", "third-man", "press", "zonal", "man-to-man", "transition",
		"goal-side"],
	"g7.health_pe.racket_sports": ["grip", "split step", "clear", "drop", "smash", "21", "even", "deuce"],
	"g7.health_pe.fitness_plan": ["220", "aerobic", "anaerobic", "60 minutes", "3 days", "rest day", "talk test"],
	"g7.health_pe.dance_styles": ["street", "breaking", "popping", "locking", "folk", "contemporary", "canon",
		"8 counts"],
	"g7.health_pe.lead_and_officiate": ["referee", "captain", "coach", "advantage", "indirect", "round robin",
		"knockout", "feedback"],
	"g7.health_pe.teen_sleep": ["8 to 10 hours", "body clock", "melatonin", "caffeine", "an hour", "same time", "dark"],
	"g7.health_pe.health_influences": ["family", "friends", "media", "advert", "influencer", "#ad", "small print",
		"most young people"],
	"g7.health_pe.self_image": ["self-image", "edited", "filter", "highlights", "kind", "trusted adult", "strengths"],
	"g7.health_pe.drugs_and_the_law": ["drug", "medicine", "illegal", "class a", "against the law", "frank",
		"0300 123 6600", "999", "say no"],
	"g7.health_pe.resolve_conflict": ["calm", "i feel", "listen", "win-win", "compromise", "mediator", "online"],
	"g7.health_pe.where_to_get_help": ["trusted adult", "999", "112", "111", "0800 1111", "116 111", "ceop",
		"confidential"],
	"g7.design_tech.product_analysis": ["exploded", "injection moulding", "abs", "acrylic", "access fm",
		"mass production", "batch", "one-off"],
	"g7.design_tech.cad_cam": ["cad", "cam", "laser cutter", "3d printer", "layer", "kerf", "additive", "subtractive"],
	"g7.design_tech.electronic_circuits": ["resistor", "led", "ohms", "colour code", "long leg", "breadboard", "solder",
		"alarm"],
	"g7.design_tech.microcontrollers": ["microcontroller", "input", "output", "button a", "5 × 5", "pause", "1,000",
		"forever"],
	"g7.design_tech.smart_textiles": ["technical textile", "waterproof", "breathable", "membrane", "reflective",
		"fluorescent", "smart", "conductive thread"],
	"g7.design_tech.world_cooking": ["staple", "rice", "wheat", "maize", "spices", "halal", "kosher", "vegetarian",
		"14 allergens"],
	"g7.design_tech.less_food_waste": ["plan", "shopping list", "use by", "best before", "first in, first out",
		"leftovers", "freeze", "methane"],
	"g7.design_tech.product_life_cycle": ["raw materials", "manufacture", "transport", "end of life", "repair",
		"recycle", "6 rs", "circular"],
	"g7.design_tech.prototype_improve": ["prototype", "iteration", "test", "fair", "mean", "user", "improve",
		"wright"],
	"g7.projects.voyage": ["latitude", "longitude", "knots", "nautical mile", "60", "supplies", "log"],
	"g7.projects.eco_district": ["insulation", "solar", "rain", "footprint", "kwh", "trees", "cycl"],
	"g7.projects.mini_business": ["market research", "fixed costs", "variable costs", "markup", "break-even",
		"profit", "logo"],
}
## The pictures each unit needs, over its lesson, its exercises and its generators' ([kind, how many], …).
const DRAWS := {
	"g7.health_pe.invasion_advanced": [["pitch", 4]],
	"g7.health_pe.racket_sports": [["shot_paths", 3], ["net_court", 1]],
	"g7.health_pe.fitness_plan": [["hr_zones", 3]],
	"g7.health_pe.dance_styles": [["pose", 1], ["table", 1]],
	"g7.health_pe.lead_and_officiate": [["ref_signal", 4]],
	"g7.health_pe.teen_sleep": [["sleep_dial", 3]],
	"g7.health_pe.health_influences": [["advert", 3], ["influence_map", 1]],
	"g7.health_pe.self_image": [["photo_edit", 3]],
	"g7.health_pe.drugs_and_the_law": [["table", 1]],
	"g7.health_pe.resolve_conflict": [["step_chain", 2]],
	"g7.health_pe.where_to_get_help": [["hand", 1], ["table", 1]],
	"g7.design_tech.product_analysis": [["exploded", 3]],
	"g7.design_tech.cad_cam": [["cam_process", 3]],
	"g7.design_tech.electronic_circuits": [["schematic", 3], ["resistor", 3]],
	"g7.design_tech.microcontrollers": [["micro_board", 3], ["text_code", 2]],
	"g7.design_tech.smart_textiles": [["fabric_section", 3]],
	"g7.design_tech.world_cooking": [["voyage_map", 1], ["table", 1]],
	"g7.design_tech.less_food_waste": [["food_thermo", 1], ["pie_chart", 1]],
	"g7.design_tech.product_life_cycle": [["life_cycle", 2]],
	"g7.design_tech.prototype_improve": [["step_chain", 1], ["table", 1]],
	"g7.projects.voyage": [["voyage_map", 2], ["pole_star", 1]],
	"g7.projects.eco_district": [["eco_home", 2]],
	"g7.projects.mini_business": [["break_even", 1], ["sheet", 1]],
}
## Units whose label exercises must exist (label the diagram), with how many.
const LABELS := {"g7.health_pe.health_influences": 1, "g7.design_tech.product_analysis": 1,
	"g7.design_tech.cad_cam": 1, "g7.design_tech.microcontrollers": 1, "g7.design_tech.smart_textiles": 1,
	"g7.projects.eco_district": 1}
## Owner #112 and #117 (learn by doing): the units whose topic is a Life Experience end by naming it (its title in
## data/life/experiences/ or data/tools/real_builder.json, or the Tool Book) in the LIFE tab.
const LIFE_LINKS := {
	"g7.health_pe.teen_sleep": ["Calm Corner"],
	"g7.health_pe.health_influences": ["Calm Corner"],
	"g7.health_pe.self_image": ["Calm Corner"],
	"g7.health_pe.drugs_and_the_law": ["Calm Corner"],
	"g7.health_pe.resolve_conflict": ["Calm Corner"],
	"g7.health_pe.where_to_get_help": ["Little Lifesaver", "Calm Corner"],
	"g7.design_tech.product_analysis": ["Tool Book"],
	"g7.design_tech.cad_cam": ["Real Builder"],
	"g7.design_tech.electronic_circuits": ["Fire Escape", "Tool Book"],
	"g7.design_tech.microcontrollers": ["Safe Streets"],
	"g7.design_tech.smart_textiles": ["Safe Streets"],
	"g7.design_tech.world_cooking": ["The Kitchen"],
	"g7.design_tech.less_food_waste": ["The Kitchen"],
	"g7.design_tech.product_life_cycle": ["Tool Book"],
	"g7.design_tech.prototype_improve": ["Real Builder"],
	"g7.projects.voyage": ["Tool Book"],
	"g7.projects.eco_district": ["Real Builder"],
	"g7.projects.mini_business": ["My Money Stall"],
}
## The Tool Book's tools a unit's last card names (their ids in data/tools/tools.json, by their names there).
const TOOL_LINKS := {
	"g7.design_tech.product_analysis": ["screwdriver"],
	"g7.design_tech.electronic_circuits": ["smoke_alarm"],
	"g7.design_tech.product_life_cycle": ["screwdriver", "allen_key"],
	"g7.projects.voyage": ["compass"],
}
const DANCE_UNIT := "g7.health_pe.dance_styles"


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
		assert_eq(Curriculum.units(GRADE, subject).size(), int(UNITS[subject]), "grade 7 %s" % subject)


func test_grade_7_health_dt_projects_are_written_for_every_unit() -> void:
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
	gut.p("grade 7 health and PE, D&T and projects: %d cards, %d hand-written exercises" % [cards, exercises])


## The outline keeps its standards and goals, and every unit names its own grade 7 file.
func test_the_files_are_their_own() -> void:
	for u in _units():
		var parts := str(u.id).split(".")
		assert_eq(str(u.get("file", "")), "g7/%s/%s.json" % [parts[1], parts[2]], "%s's file" % u.id)
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
		assert_true(first.contains("grade 3") or first.contains("grade 4") or first.contains("grade 5")
			or first.contains("grade 6"), "%s: the first card names the grade it builds on" % id)
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


## The units use grade 7's own health, D&T and projects generators ("g7w"), each of which exists, and every "g7w"
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
			assert_true(used.has(gen), "%s is used by a grade 7 health, D&T or project unit" % gen)
	assert_gt(own, 25, "grade 7's health, D&T and projects generators exist")


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


## Research §5.4 rule 5: drugs, alcohol, tobacco, vaping, solvents and gambling only in the unit that teaches them
## factually (what they are, the risks, the law and getting help), no street drug named anywhere, nothing that shows
## or invites use, and no people drawn there; and that unit teaches the law and where to get help.
func test_drugs_are_taught_only_factually_in_their_own_unit() -> void:
	var found: Array[String] = []
	for u in _units():
		if not Curriculum.has_content(str(u.id)):
			continue
		for t in _all_texts(str(u.id)):
			var w := _found(t, SUBSTANCES)
			if w != "" and str(u.id) != SUBSTANCES_UNIT:
				found.append("%s: '%s' in: %s" % [u.id, w, t])
			var street := _found(t, STREET_DRUGS)
			if street != "":
				found.append("%s: '%s' in: %s" % [u.id, street, t])
			var use := _found(t, SHOWS_USE)
			if use != "":
				found.append("%s: '%s' in: %s" % [u.id, use, t])
	assert_eq(found, [] as Array[String], "\n".join(found))
	if not Curriculum.has_content(SUBSTANCES_UNIT):
		fail_test("%s is not written" % SUBSTANCES_UNIT)
		return
	var lesson := _lesson(SUBSTANCES_UNIT)
	for w: String in ["misuse of drugs act", "against the law", "say no", "trusted adult", "frank", "childline"]:
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


## Label the diagram: every label's line ends on its own part of the picture (SchoolPictureG7Life.part_at, at the
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
			assert_true(SchoolPictureG7Life.KINDS.has(str(ex.picture.kind)), "%s: a grade 7 life picture" % ex.id)
			for i in (ex.labels as Array).size():
				var spot: Array = ex.spots[int(ex.answer[i])]
				assert_eq(spot.size(), 4, "%s: a line from the pin to the part" % ex.id)
				if spot.size() != 4:
					continue
				var part := SchoolPictureG7Life.part_at(ex.picture, str(ex.labels[i]), ExerciseCheck.LABEL_BOX)
				assert_ne(part, Vector2(-1, -1), "%s: the picture has a %s" % [ex.id, ex.labels[i]])
				var tip := Vector2(float(spot[2]), float(spot[3])) * ExerciseCheck.LABEL_BOX
				assert_lt(tip.distance_to(part), 14.0, "%s: the line to %s ends on it" % [ex.id, ex.labels[i]])
				checked += 1
		assert_gte(n, int(LABELS[id]), "%s: label exercises" % id)
	assert_gte(checked, 18, "labels were checked")


## Owner #112 and #117: the School and Life work together. A unit whose topic is a Life Experience ends by naming it,
## in the LIFE tab; each name is a real Experience's title (or the Tool Book), and each tool named is in the Tool Book.
func test_the_life_experiences_are_named_where_the_topic_is_one() -> void:
	var titles: Array[String] = ["Tool Book"]
	for id: String in LifeExperience.IDS:
		var d := LifeExperience.data(id)   # each Experience's own file (Life's, Real Builder's, Success's)
		assert_false(d.is_empty(), "%s's data" % id)
		titles.append(str(d.get("title", "")))
	var tools := {}
	for t: Variant in ToolBook.data().get("tools", []):
		tools[str(t.id)] = str(t.name)
	for id: String in LIFE_LINKS:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var last := str((Curriculum.content(id).lesson as Array)[-1].text)
		assert_true(last.contains("LIFE"), "%s: the last card sends the child to the LIFE tab" % id)
		for name: String in LIFE_LINKS[id]:
			assert_true(titles.has(name), "%s: '%s' is a Life Experience" % [id, name])
			assert_true(last.contains(name), "%s: the last card names %s" % [id, name])
		for tool: String in TOOL_LINKS.get(id, []):
			assert_true(tools.has(tool), "%s: %s is in the Tool Book" % [id, tool])
			assert_true(last.to_lower().contains(str(tools.get(tool, "?")).to_lower()), "%s names the %s" % [id,
				tools.get(tool, tool)])


## Dance is heard: the counts and steps can be listened to (and copied), and every project has a build on the block
## board.
func test_the_dance_is_heard_and_projects_are_built() -> void:
	if Curriculum.has_content(DANCE_UNIT):
		var sounds := 0
		var c := Curriculum.content(DANCE_UNIT)
		for item: Dictionary in (c.lesson as Array) + (c.exercises as Array):
			if item.get("sound") is Dictionary:
				sounds += 1
		assert_gte(sounds, 3, "%s: counts and steps to listen to" % DANCE_UNIT)
	else:
		fail_test("%s is not written" % DANCE_UNIT)
	for u in Curriculum.units(GRADE, "projects"):
		if not Curriculum.has_content(str(u.id)):
			fail_test("%s is not written" % u.id)
			continue
		var builds := 0
		for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
			builds += 1 if str(ex.type) == "build" else 0
		assert_gte(builds, 1, "%s: a build on the block board" % u.id)


# --- The rules the pictures teach, worked out again (this test's own) ------------------------------------------------

## A resistor's value from its bands: two digits, then that many zeros (gold and silver are the tolerance).
func _ohms(bands: Array) -> int:
	var digits := ["black", "brown", "red", "orange", "yellow", "green", "blue", "violet", "grey", "white"]
	return (digits.find(str(bands[0])) * 10 + digits.find(str(bands[1]))) * int(pow(10, digits.find(str(bands[2]))))


## The heart-rate zone of `bpm` for a maximum of `top`: warm-up 50-60%, aerobic 60-80%, anaerobic 80-90%, maximum
## 90-100%, rest below.
func _zone(top: int, bpm: float) -> String:
	var share := bpm / top
	return "rest" if share < 0.5 else ("warm-up" if share < 0.6 else ("aerobic" if share < 0.8 else ("anaerobic" if share
		< 0.9 else "maximum")))


## Hours from falling asleep to waking ("22:30" to "07:00" is 8.5).
func _hours(from: String, to: String) -> float:
	var a := int(from.split(":")[0]) * 60 + int(from.split(":")[1])
	var b := int(to.split(":")[0]) * 60 + int(to.split(":")[1])
	return float((b - a + 1440) % 1440) / 60.0


## Every number the units ask about a resistor's bands, a heart-rate zone and the hours of sleep on a dial (hand-written
## and generated) has the answer this test works out, and the pictures' own rules agree.
func test_the_pictures_rules_are_right() -> void:
	var checked := 0
	for id: String in ["g7.design_tech.electronic_circuits", "g7.health_pe.fitness_plan", "g7.health_pe.teen_sleep"]:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		for ex in _exercises(id, 20):
			var pic: Variant = ex.get("picture")
			if not pic is Dictionary:
				continue
			var kind := str(pic.get("kind", ""))
			var prompt := str(ex.prompt).to_lower()
			if kind == "resistor" and str(ex.type) == "number" and not pic.has("hide"):
				assert_eq(NumberAnswer.value(str(ex.answer)), float(_ohms(pic.bands)), "%s: %s" % [ex.id, ex.prompt])
				assert_eq(SchoolPictureG7Life.resistor_ohms(pic.bands), _ohms(pic.bands), "%s: the picture's rule" % ex.id)
				checked += 1
			elif kind == "hr_zones" and str(ex.type) == "choice" and prompt.contains("zone") and pic.has("point"):
				var right := ExerciseCheck.item_text(ex.choices[int(ex.answer)]).to_lower()
				var point: Array = pic.trace[int(pic.point)]
				var want := _zone(int(pic.max), float(point[1]))
				assert_true(right.begins_with(want), "%s: %s (%s)" % [ex.id, ex.prompt, want])
				assert_eq(SchoolPictureG7Life.zone_of(int(pic.max), float(point[1])), want, "%s: the picture's rule" % ex.id)
				checked += 1
			elif kind == "sleep_dial" and str(ex.type) == "number" and prompt.contains("how many hours"):
				assert_almost_eq(NumberAnswer.value(str(ex.answer)), _hours(str(pic.sleep), str(pic.wake)), 0.001,
					"%s: %s" % [ex.id, ex.prompt])
				assert_almost_eq(SchoolPictureG7Life.sleep_hours(str(pic.sleep), str(pic.wake)), _hours(str(pic.sleep),
					str(pic.wake)), 0.001, "%s: the picture's rule" % ex.id)
				checked += 1
	assert_gte(checked, 20, "the pictures' rules were checked")
	assert_eq(_ohms(["brown", "black", "red", "gold"]), 1000)
	assert_eq(_zone(208, 150), "aerobic")
	assert_almost_eq(_hours("22:30", "07:00"), 8.5, 0.001)
