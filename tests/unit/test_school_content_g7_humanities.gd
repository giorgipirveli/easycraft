extends GutTest
## Owner #70 and #73 ("start from grade 3 and finish all grades accordingly"; research §6.7): grade 7's history (the
## early modern world, about 1450-1750: the printing press, the Renaissance, voyages of exploration, encounters in the
## Americas, the Ottoman Empire, Mughal India, Ming China and Edo Japan, the Scientific Revolution, monarchs and
## parliaments, spices, trade and companies), geography (tectonic plates and people, rocks and soils, glaciers, coasts,
## the world's ecosystems, water supply, the Middle East, Russia, a fieldwork enquiry, managing natural hazards) and
## citizenship (how laws are made, constitutions and rights, active citizens, charities, media and bias, global citizens,
## careers, a small business, cards and credit, saving and investing, ethical dilemmas) are written for every unit of
## the outline. Each unit teaches with a lesson of 3 or more cards that opens with a memory question naming the earlier
## grade it builds on, ends with something to try in the world and names what comes next (research §5.3 rules 1, 7 and
## 8), has at least 12 hand-written exercises at levels 1, 2 and 3 of at least two kinds, each with a hint (a strategy)
## and a worked answer, and rounds that vary and never show a hand-written exercise twice. A number whose answer is a
## year says so. Hard history (research §5.4 rule 3: the effects of colonisation above all, ruling 9) is marked in the
## outline for the grown-ups' page, told with respect and never shown. (Every exercise's validity, answers, pictures and
## words are the shared content test's, test_school_content.gd; the generators' answers are test_g7_hum_gen.gd's.)

const GRADE := 7
const SUBJECTS: Array[String] = ["history", "geography", "citizenship"]
const UNITS := {"history": 10, "geography": 10, "citizenship": 11}   # research §6.7
const MIN_EXERCISES := 12
## Every generator a grade 7 humanities unit uses is its own source's ("g7h").
const SOURCE := "g7h."
## Money in the School is the game's gold (research §5.5 ruling 6): no real currency's name or sign.
const CURRENCIES: Array[String] = ["dollar", "dollars", "euro", "euros", "pound", "pounds", "pence", "yen", "rupee",
	"rupees", "yuan", "guilder", "guilders", "ducat", "ducats"]
## Research §5.4 rule 3: hard history through causes, everyday life, change and remembrance; no gore, no weapon detail,
## no suffering shown.
const GRUESOME: Array[String] = ["blood", "bloody", "gore", "corpse", "corpses", "torture", "tortured", "behead",
	"beheaded", "massacre", "massacred", "slaughter", "slaughtered", "sacrifice", "sacrificed", "sacrifices", "pus",
	"rotting", "execution", "executed", "burned alive", "hanged", "mutilated", "slain"]
## Research §5.4 rule 2: how systems work, in general terms; no parties.
const PARTIES: Array[String] = ["labour party", "conservative party", "democrats", "republicans", "tory", "tories",
	"liberal democrats", "whigs"]
## Research §5.4 rule 2: no disputed borders, places or names (the Middle East and Russia units above all): only seas,
## rivers, deserts, mountains and widely recognised capitals and cities.
const DISPUTED: Array[String] = ["jerusalem", "crimea", "kashmir", "taiwan", "tibet", "persian gulf", "arabian gulf",
	"palestine", "palestinian", "israel", "israeli", "gaza", "west bank", "golan", "kurdistan", "western sahara", "kuril",
	"south china sea", "falklands", "malvinas", "ukraine", "chechnya", "abkhazia", "ossetia", "donbas"]
## "What year …?", "In which year …?": the answer is a year.
const ASKS_A_YEAR := "(?i)\\b(what|which) year\\b"
## The units a grown-up may want to sit with (research §5.4 rule 3, ruling 9): each marked in the outline with what it
## names ("hard", at most 60 letters), so the grown-ups' page lists it.
const HARD: Array[String] = ["g7.history.voyages", "g7.history.encounters_americas", "g7.history.ottoman_empire",
	"g7.history.crowns_parliaments", "g7.history.trade_companies"]
const MAX_HARD := 60
## The pictures each unit's lesson draws: the grade's new kinds (SchoolPictureG7Hum) and earlier ones.
const DRAWS := {
	"g7.history.printing_press": ["hand_press"],
	"g7.history.renaissance": ["event_timeline"],
	"g7.history.voyages": ["voyage_map", "pole_star"],
	"g7.history.encounters_americas": ["columbian_exchange"],
	"g7.history.ottoman_empire": ["dome_profile", "voyage_map"],
	"g7.history.mughal_india": ["dome_profile", "charbagh"],
	"g7.history.ming_edo": ["event_timeline"],
	"g7.history.scientific_revolution": ["sky_model", "step_chain"],
	"g7.history.crowns_parliaments": ["family_tree"],
	"g7.history.trade_companies": ["voyage_map"],
	"g7.geography.plates_and_people": ["plate_section"],
	"g7.geography.rocks_soils_geo": ["rock_cycle", "soil_profile"],
	"g7.geography.glaciers": ["glacial_valley"],
	"g7.geography.coasts": ["coast_view"],
	"g7.geography.world_ecosystems": ["nutrient_cycle", "climograph"],
	"g7.geography.water_supply": ["step_chain"],
	"g7.geography.middle_east": ["voyage_map"],
	"g7.geography.russia": ["voyage_map"],
	"g7.geography.fieldwork_enquiry": ["step_chain"],
	"g7.geography.hazard_management": ["plate_section"],
	"g7.citizenship.how_laws_are_made": ["step_chain"],
	"g7.citizenship.media_bias": ["cut_axis_bars"],
	"g7.citizenship.small_business": ["break_even"],
	"g7.citizenship.saving_investing": ["savings_growth"],
}


func _units() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for subject in SUBJECTS:
		out.append_array(Curriculum.units(GRADE, subject))
	return out


func _texts(id: String) -> Array[String]:
	var out: Array[String] = []
	var c := Curriculum.content(id)
	for card: Dictionary in c.lesson:
		out.append(str(card.get("text", "")))
	for ex: Dictionary in c.exercises:
		out.append_array([str(ex.prompt), str(ex.hint), str(ex.get("explain", ""))])
		for x: Variant in ex.get("choices", []) + ex.get("items", []) + ex.get("matches", []) + ex.get("groups", []) \
				+ ex.get("labels", []):
			out.append(ExerciseCheck.item_text(x))
	return out


## Every text of the grade's units and of its generators (12 seeds a level).
func _all_texts() -> Array[String]:
	var out: Array[String] = []
	for u in _units():
		if Curriculum.has_content(str(u.id)):
			out.append_array(_texts(str(u.id)))
	for gen in SchoolGen.ids():
		if gen.begins_with(SOURCE):
			for level in [1, 2, 3]:
				for s in 12:
					var ex := SchoolGen.make(gen, s, level)
					out.append_array([str(ex.get("prompt", "")), str(ex.get("hint", "")), str(ex.get("explain", ""))])
					for x: Variant in ex.get("choices", []) + ex.get("items", []) + ex.get("matches", []) \
							+ ex.get("groups", []):
						out.append(ExerciseCheck.item_text(x))
	return out


func _has_word(text: String, word: String) -> bool:
	return RegEx.create_from_string("\\b" + word + "\\b").search(text.to_lower()) != null


func test_the_outline_has_every_unit_of_the_research() -> void:
	for subject in SUBJECTS:
		assert_eq(Curriculum.units(GRADE, subject).size(), int(UNITS[subject]), "grade 7 %s" % subject)


func test_grade_7_history_geography_citizenship_are_written_for_every_unit() -> void:
	var exercises := 0
	for u in _units():
		var id := str(u.id)
		assert_true(Curriculum.has_content(id), "%s is written" % id)
		if not Curriculum.has_content(id):
			continue
		assert_eq(Curriculum.content_problems(id), [] as Array[String], id)
		var c := Curriculum.content(id)
		assert_between((c.lesson as Array).size(), 3, Curriculum.MAX_CARDS, "%s: a lesson of 3 or more cards" % id)
		assert_gte((c.exercises as Array).size(), MIN_EXERCISES, "%s: at least %d hand-written exercises" % [id, MIN_EXERCISES])
		exercises += (c.exercises as Array).size()
		var levels := {}
		var types := {}
		for ex: Dictionary in c.exercises:
			levels[int(ex.level)] = true
			types[str(ex.type)] = true
		assert_eq(levels.keys().size(), 3, "%s: hand-written exercises at levels 1, 2 and 3" % id)
		assert_gte(types.size(), 2, "%s: at least two kinds of hand-written exercise" % id)
		var distinct := {}
		for stars in [0, 1, 2]:
			for s in 20:
				var round := RoundPlan.plan(c, s * 7 + stars, stars)
				assert_eq(round.size(), MasteryRules.ROUND_SIZE, "%s fills a round" % id)
				var ids := {}
				for ex in round:
					distinct[str(ex.prompt) + str(ex.get("picture", ""))] = true
					if not str(ex.id).begins_with("gen:"):
						assert_false(ids.has(ex.id), "%s: %s twice in a round" % [id, ex.id])
						ids[ex.id] = true
		assert_gte(distinct.size(), 12, "%s: varied practice" % id)
	gut.p("%d hand-written exercises in grade 7 history, geography and citizenship" % exercises)


func test_every_exercise_has_a_strategy_hint_and_a_worked_answer() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for ex: Dictionary in Curriculum.content(id).exercises:
			assert_ne(str(ex.get("hint", "")).strip_edges(), "", "%s: a hint" % ex.id)
			assert_ne(str(ex.get("explain", "")).strip_edges(), "", "%s: a worked answer" % ex.id)
			assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: the hint is a strategy, not the answer" % ex.id)


## Research §5.3: "Start with memory" (a quick question from earlier), "Spiral" (name what it builds on and what comes
## next) and "Do it in the world" (a challenge to try). Grade 7 builds on grades 3 to 6, and its first card names the
## grade it recalls.
func test_every_lesson_starts_with_memory_of_an_earlier_grade_and_ends_in_the_world_with_what_comes_next() -> void:
	var earlier := RegEx.create_from_string("grade [3456]\\b")
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		var cards: Array = Curriculum.content(id).lesson
		var first := str(cards[0].text)
		assert_true(first.begins_with("Quick memory:") and first.contains("?"),
			"%s: the first card asks a memory question" % id)
		assert_true(earlier.search(first) != null, "%s: the first card names the grade it builds on" % id)
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


## The generators these units use are grade 7 humanities' own ("g7h"), each exists, and each is used.
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for g: Dictionary in Curriculum.content(id).generators:
			assert_true(str(g.gen).begins_with(SOURCE), "%s uses %s" % [id, g.gen])
			assert_true(SchoolGen.exists(str(g.gen)), "%s: %s exists" % [id, g.gen])
			used[str(g.gen)] = true
	assert_gt(used.size(), 20, "grade 7 humanities practise with generators too")
	for gen in SchoolGen.ids():
		if gen.begins_with(SOURCE):
			assert_true(used.has(gen), "%s is used by a grade 7 humanities unit" % gen)


## The lessons draw the grade's pictures: a hand press and its type, voyages on the world's grid, the Pole Star, the
## Columbian exchange, Ottoman and Mughal domes, a Mughal garden, models of the heavens, a royal family tree; plate
## boundaries, the rock cycle, a soil's layers, a glaciated valley, the coast, nutrient stores, chains of steps; a chart
## with a cut axis, a business's break-even point, savings growing.
func test_the_lessons_draw_their_pictures() -> void:
	for id: String in DRAWS:
		if not Curriculum.has_content(id):
			assert_true(false, "%s is written" % id)
			continue
		var kinds := {}
		for card: Dictionary in Curriculum.content(id).lesson:
			kinds[str(card.get("picture", {}).get("kind", ""))] = true
		for kind: String in DRAWS[id]:
			assert_true(kinds.has(kind), "%s's lesson draws a %s picture" % [id, kind])


## Every new kind of the grade's picture file is drawn by a lesson.
func test_every_new_picture_kind_is_used() -> void:
	var drawn := {}
	for id: String in DRAWS:
		for kind: String in DRAWS[id]:
			drawn[kind] = true
	var path := "res://ui/school/school_picture_g7hum.gd"
	assert_true(ResourceLoader.exists(path), "the grade's picture file")
	if not ResourceLoader.exists(path):
		return
	for kind: String in (load(path) as Script).get_script_constant_map()["KINDS"]:
		assert_true(drawn.has(kind), "a lesson draws %s" % kind)


## A number exercise whose answer is a year shows it as one (1492, not 1,492), hand-written or generated; and "year"
## is only for years.
func test_a_year_is_shown_as_a_year() -> void:
	var asks := RegEx.create_from_string(ASKS_A_YEAR)
	var checked := 0
	var exercises: Array[Dictionary] = []
	for u in _units():
		if Curriculum.has_content(str(u.id)):
			exercises.append_array(Curriculum.content(str(u.id)).exercises)
	for gen in SchoolGen.ids():
		if gen.begins_with(SOURCE):
			for level in [1, 2, 3]:
				for s in 40:
					exercises.append(SchoolGen.make(gen, s, level))
	for ex in exercises:
		if str(ex.get("type", "")) != "number":
			continue
		if asks.search(str(ex.prompt)) != null:
			checked += 1
			assert_true(ex.get("year", false) == true, "a year: %s" % ex.prompt)
		if ex.get("year", false) == true:
			var y := int(str(ex.answer))
			assert_between(y, 1, 2100, "a year's answer: %s" % ex.prompt)
	assert_gt(checked, 3, "the units ask for years")


## Money is the game's gold everywhere (research §5.5 ruling 6), in the lessons and the generators.
func test_money_is_the_games_gold() -> void:
	for t in _all_texts():
		assert_false(t.contains("$"), t)
		for w in CURRENCIES:
			assert_false(_has_word(t, w), "'%s' in %s" % [w, t])


## Research §5.4 rules 2 and 3: no gruesome words in hard history, no political parties, no disputed places.
func test_hard_history_with_respect_no_parties_no_disputed_places() -> void:
	for t in _all_texts():
		for w in GRUESOME + PARTIES + DISPUTED:
			assert_false(_has_word(t, w), "'%s' in %s" % [w, t])


## Research §5.4 rule 3 and §5.5 ruling 9: the hard-history units (the encounters in the Americas above all) are
## marked for the grown-ups' page with what they name, and no other grade 7 humanities unit is.
func test_hard_history_is_listed_for_grown_ups() -> void:
	for u in _units():
		var id := str(u.id)
		var hard: Variant = u.get("hard")
		if HARD.has(id):
			assert_true(hard is String and str(hard).strip_edges() != "", "%s names its hard history" % id)
			assert_lte(str(hard).length(), MAX_HARD, "%s: a short line" % id)
		else:
			assert_null(hard, "%s is not marked hard" % id)
	assert_true(HARD.has("g7.history.encounters_americas"), "research ruling 9")
