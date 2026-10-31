extends GutTest
## Owner #70 and #73 ("start from grade 3 and finish all grades accordingly"; research §6.6): grade 6's history (the
## medieval world: after Rome, Anglo-Saxons and Vikings, Baghdad, castles, Magna Carta, Tang and Song China, African
## kingdoms, medieval Japan, the Aztecs and Incas, the Black Death), geography (population, migration, cities, jobs,
## detailed maps, climate graphs, rivers, Africa, Asia, maps with layers) and citizenship (how a country is run,
## elections, police and courts, human rights, identity, disagreeing well, income and taxes, compound interest, risk,
## scams, sustainable choices) are written for every unit of the outline. Each unit teaches with a lesson of 3 or more
## cards that opens with a memory question naming the earlier grade it builds on, ends with something to try in the
## world and names what comes next (research §5.3 rules 1, 7 and 8), has at least 12 hand-written exercises at levels
## 1, 2 and 3 of at least two kinds, each with a hint (a strategy) and a worked answer, and rounds that vary and never
## show a hand-written exercise twice. A number whose answer is a year says so ("year": true: 1066, not 1,066).
## (Every exercise's validity, answers, pictures and words are the shared content test's, test_school_content.gd; the
## generators' answers are test_g6_humanities_gen.gd's.)

const GRADE := 6
const SUBJECTS: Array[String] = ["history", "geography", "citizenship"]
const UNITS := {"history": 10, "geography": 10, "citizenship": 11}   # research §6.6
const MIN_EXERCISES := 12
## Every generator a grade 6 humanities unit uses is its own source's ("g6h").
const SOURCE := "g6h."
## Money in the School is the game's gold (research §5.5 ruling 6): no real currency's name or sign ("per cent" is
## a percentage, not money).
const CURRENCIES: Array[String] = ["dollar", "dollars", "euro", "euros", "pound", "pounds", "pence", "yen", "rupee",
	"rupees", "yuan"]
## Research §5.4 rule 3: hard history through causes, everyday life, change and remembrance; no gore, no weapon detail,
## no suffering shown (the Black Death "with no gruesome detail", the outline says).
const GRUESOME: Array[String] = ["blood", "bloody", "gore", "corpse", "corpses", "torture", "tortured", "behead",
	"beheaded", "massacre", "slaughter", "slaughtered", "sacrifice", "sacrificed", "sacrifices", "buboes", "pus",
	"rotting", "execution", "executed"]
## Research §5.4 rule 2: how systems work, in general terms; no parties.
const PARTIES: Array[String] = ["labour party", "conservative party", "democrats", "republicans", "tory", "tories",
	"liberal democrats"]
## "What year …?", "In which year …?": the answer is a year.
const ASKS_A_YEAR := "(?i)\\b(what|which) year\\b"
## The pictures each unit's lesson draws (kind -> the units): the grade's new kinds (SchoolPictureG6Hum) and the world's
## grid of grade 5.
const DRAWS := {
	"g6.history.castles_feudal": ["feudal_pyramid", "castle_type"],
	"g6.history.aztec_inca": ["quipu"],
	"g6.history.after_rome": ["event_timeline"],
	"g6.geography.population": ["dot_density"],
	"g6.geography.cities": ["city_zones"],
	"g6.geography.detailed_maps": ["os_map"],
	"g6.geography.climate_graphs": ["climograph"],
	"g6.geography.river_processes": ["river_course"],
	"g6.geography.maps_with_layers": ["layer_map"],
	"g6.geography.africa": ["latlong"],
	"g6.geography.asia": ["latlong"],
	"g6.citizenship.compound_interest": ["savings_growth"],
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
		for x: Variant in ex.get("choices", []) + ex.get("items", []) + ex.get("matches", []) + ex.get("groups", []):
			out.append(ExerciseCheck.item_text(x))
	return out


func _has_word(text: String, word: String) -> bool:
	return RegEx.create_from_string("\\b" + word + "\\b").search(text.to_lower()) != null


func test_the_outline_has_every_unit_of_the_research() -> void:
	for subject in SUBJECTS:
		assert_eq(Curriculum.units(GRADE, subject).size(), int(UNITS[subject]), "grade 6 %s" % subject)


func test_grade_6_history_geography_citizenship_are_written_for_every_unit() -> void:
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
	gut.p("%d hand-written exercises in grade 6 history, geography and citizenship" % exercises)


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
## next) and "Do it in the world" (a challenge to try). Grade 6 builds on grades 3, 4 and 5, and its first card names
## the grade it recalls.
func test_every_lesson_starts_with_memory_of_an_earlier_grade_and_ends_in_the_world_with_what_comes_next() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		var cards: Array = Curriculum.content(id).lesson
		var first := str(cards[0].text)
		assert_true(first.begins_with("Quick memory:") and first.contains("?"),
			"%s: the first card asks a memory question" % id)
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


## The generators these units use are grade 6 humanities' own ("g6h"), and each unit's generators exist.
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
	assert_gt(used.size(), 0, "grade 6 humanities practise with generators too")
	for gen in SchoolGen.ids():
		if gen.begins_with(SOURCE):
			assert_true(used.has(gen), "%s is used by a grade 6 humanities unit" % gen)


## The lessons draw the grade's pictures: a quipu's knots, a castle and the feudal pyramid, a timeline; dots for
## people, a city's zones, a detailed map with contours and grid lines, a climate graph, a river's course, a layered
## map, the world's grid for Africa and Asia; savings growing year by year.
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


## A number exercise whose answer is a year shows it as one (1066, not 1,066), hand-written or generated; and "year"
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


## Money is the game's gold everywhere (research §5.5 ruling 6).
func test_money_is_the_games_gold() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for t in _texts(id):
			assert_false(t.contains("$"), "%s: %s" % [id, t])
			for w in CURRENCIES:
				assert_false(_has_word(t, w), "%s: '%s' in %s" % [id, w, t])


## Research §5.4 rules 2 and 3: no gruesome words in hard history, and no political parties.
func test_hard_history_with_respect_and_no_parties() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for t in _texts(id):
			for w in GRUESOME + PARTIES:
				assert_false(_has_word(t, w), "%s: '%s' in %s" % [id, w, t])
