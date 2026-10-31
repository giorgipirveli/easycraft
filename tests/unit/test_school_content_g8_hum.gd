extends GutTest
## Owner #70, #73 and #111 ("full school programs and syllabus content"; research §6.8): grade 8's history (the modern
## world, 1745 to today: the Industrial Revolution, ideas of liberty and the revolutions, slavery and abolition, empires
## and independence, votes for all, the two world wars, the Holocaust, building peace and rights, the space race and the
## digital age), geography (climate change, development, a connected world, energy, food, cities of the future, tourism,
## oceans, map projections, a GIS investigation) and citizenship (democracies compared, young people's voice, young
## people and the law, fairness and equality, paying for public services, a grown-up's budget, credit and debt,
## investing and risk, consumer rights, a Global Goal in action, big questions about technology) are written for every
## unit of the outline. Each unit teaches with a lesson of 4-8 cards that opens with a memory question naming the earlier
## grade it builds on, ends with something to try in the world and names what comes next (research §5.3 rules 1, 7 and
## 8), has at least 12 hand-written exercises at levels 1, 2 and 3 of at least two kinds, each with a hint (a strategy)
## and a worked answer, rounds that vary and never show a hand-written exercise twice, and meets the School's quality bar
## (test_school_quality.gd's `bar`: its scope is grades 3-7, so grade 8's humanities are held to it here). Hard history
## (research §5.4 rule 3, ruling 9: the slave trade and the Holocaust above all) is marked in the outline for the
## grown-ups' page, told truthfully and calmly and never shown. Where a unit's topic is already a Life or Success
## Experience (owner #112, #115, #117: learn by doing), its last card points to that Experience by name.
## (Every exercise's validity, answers, pictures and words are the shared content test's, test_school_content.gd; the
## generators' answers are test_g8_hum_gen.gd's; the pictures' samples test_school_picture_g8hum.gd's.)

const GRADE := 8
const SUBJECTS: Array[String] = ["history", "geography", "citizenship"]
const UNITS := {"history": 10, "geography": 10, "citizenship": 11}   # research §6.8
const MIN_EXERCISES := 12
## Every generator a grade 8 humanities unit uses is its own source's ("g8h").
const SOURCE := "g8h."
## Money in the School is the game's gold (research §5.5 ruling 6): no real currency's name or sign.
const CURRENCIES: Array[String] = ["dollar", "dollars", "euro", "euros", "pound", "pounds", "pence", "penny", "yen",
	"rupee", "rupees", "yuan", "shilling", "shillings", "franc", "francs", "peso", "pesos", "guilder", "guilders"]
## Research §5.4 rule 3: hard history through causes, everyday life, change, remembrance and peace; no gore, no weapon
## detail, no suffering shown. "Murdered" is the true word for the Holocaust (MURDER_UNIT) and only there.
const GRUESOME: Array[String] = ["blood", "bloody", "gore", "corpse", "corpses", "torture", "tortured", "behead",
	"beheaded", "massacre", "massacred", "slaughter", "slaughtered", "sacrifice", "sacrificed", "pus", "rotting",
	"execution", "executed", "burned alive", "hanged", "mutilated", "slain", "killed", "killing", "gas chamber",
	"gas chambers", "shot dead", "bayonet", "bayonets", "machine gun", "machine guns", "bullet", "bullets", "grenade",
	"grenades", "rifle", "rifles", "whipped", "whipping", "lynched", "lynching", "starved to death"]
const MURDER: Array[String] = ["murder", "murdered", "murders"]
const MURDER_UNIT := "g8.history.holocaust_remembrance"
## Research §5.4 rule 2: how systems work, in general terms; no parties (today's, or movements that are parties now).
const PARTIES: Array[String] = ["labour party", "conservative party", "democrats", "republicans", "tory", "tories",
	"liberal democrats", "whigs", "green party", "snp", "ukip", "reform uk", "bjp", "anc", "african national congress",
	"indian national congress", "congress party", "muslim league"]
## Research §5.4 rule 2: no disputed borders, places or names.
const DISPUTED: Array[String] = ["jerusalem", "crimea", "kashmir", "taiwan", "tibet", "persian gulf", "arabian gulf",
	"palestine", "palestinian", "israel", "israeli", "gaza", "west bank", "golan", "kurdistan", "western sahara", "kuril",
	"south china sea", "falklands", "malvinas", "ukraine", "chechnya", "abkhazia", "ossetia", "donbas", "kosovo",
	"northern cyprus", "somaliland", "transnistria", "karabakh"]
## Research §5.4 rule 7: people of the past only (no living people), no brands.
const LIVING_OR_BRANDS: Array[String] = ["aldrin", "berners-lee", "musk", "bezos", "zuckerberg", "thunberg", "malala",
	"attenborough", "obama", "trump", "biden", "putin", "modi", "intel", "google", "microsoft", "facebook", "instagram",
	"tiktok", "youtube", "iphone", "twitter", "whatsapp", "netflix", "chatgpt", "openai", "tesla", "spacex",
	"coca-cola", "nike", "airbnb", "uber", "fairtrade", "samsung"]
## "What year …?", "In which year …?": the answer is a year.
const ASKS_A_YEAR := "(?i)\\b(what|which) year\\b"
## The units a grown-up may want to sit with (research §5.4 rule 3, ruling 9): each marked in the outline with what it
## names ("hard", at most 60 letters, no semicolons: the grown-ups' page joins them with "; "), so the page lists it.
const HARD: Array[String] = ["g8.history.ideas_of_liberty", "g8.history.slavery_abolition",
	"g8.history.empires_independence", "g8.history.first_world_war", "g8.history.second_world_war",
	"g8.history.holocaust_remembrance", "g8.history.building_peace"]
const MAX_HARD := 60
## The pictures each unit's lesson draws: the grade's new kinds (SchoolPictureG8Hum) and earlier ones.
const DRAWS := {
	"g8.history.industrial_revolution": ["steam_engine", "event_timeline"],
	"g8.history.ideas_of_liberty": ["event_timeline", "voyage_map"],
	"g8.history.slavery_abolition": ["voyage_map", "event_timeline"],
	"g8.history.empires_independence": ["event_timeline", "voyage_map"],
	"g8.history.votes_for_all": ["event_timeline", "line_graph"],
	"g8.history.first_world_war": ["event_timeline", "voyage_map"],
	"g8.history.second_world_war": ["event_timeline", "voyage_map"],
	"g8.history.holocaust_remembrance": ["event_timeline", "step_chain"],
	"g8.history.building_peace": ["event_timeline", "table"],
	"g8.history.space_digital_age": ["event_timeline", "line_graph"],
	"g8.geography.climate_change": ["greenhouse", "line_graph"],
	"g8.geography.development": ["scatter_plot", "pop_pyramid"],
	"g8.geography.connected_world": ["voyage_map", "step_chain"],
	"g8.geography.energy_for_the_world": ["pie_chart", "energy_chain"],
	"g8.geography.feeding_the_world": ["bar_graph", "voyage_map"],
	"g8.geography.future_cities": ["dot_density", "layer_map"],
	"g8.geography.tourism": ["tourism_cycle", "line_graph"],
	"g8.geography.oceans": ["ocean_zones", "voyage_map"],
	"g8.geography.map_projections": ["projection"],
	"g8.geography.gis_investigation": ["layer_map", "step_chain"],
	"g8.citizenship.democracies_compared": ["parliament_seats", "table"],
	"g8.citizenship.your_voice": ["step_chain", "bar_graph"],
	"g8.citizenship.young_people_law": ["number_line", "table"],
	"g8.citizenship.fairness_for_all": ["balance_scale", "step_chain"],
	"g8.citizenship.public_services": ["pie_chart", "step_chain"],
	"g8.citizenship.life_budget": ["pie_chart", "sheet"],
	"g8.citizenship.credit_debt": ["line_graph", "table"],
	"g8.citizenship.investing_risk": ["scatter_plot", "savings_growth"],
	"g8.citizenship.consumer_rights": ["receipt", "step_chain"],
	"g8.citizenship.global_goals_action": ["step_chain", "bar_graph"],
	"g8.citizenship.technology_ethics": ["balance_scale", "argument_map"],
}
## Owner #112, #115, #117 (learn by doing): a unit whose topic is already a Life or Success Experience keeps its lesson
## and exercises and points its last card ("Try it in the world") to that Experience by name.
const EXPERIENCES := {
	"g8.history.first_world_war": "Success Stories",
	"g8.history.second_world_war": "Success Stories",
	"g8.history.building_peace": "Success Stories",
	"g8.history.space_digital_age": "Success Stories",
	"g8.geography.climate_change": "Earth and Weather",
	"g8.geography.development": "Success Stories",
	"g8.geography.feeding_the_world": "Success Stories",
	"g8.geography.future_cities": "Success Stories",
	"g8.citizenship.your_voice": "Talk & Deal",
	"g8.citizenship.fairness_for_all": "Connections Book",
	"g8.citizenship.life_budget": "My Money Stall",
	"g8.citizenship.credit_debt": "My Money Stall",
	"g8.citizenship.investing_risk": "My Money Stall",
	"g8.citizenship.consumer_rights": "Talk & Deal",
	"g8.citizenship.global_goals_action": "Goal Board",
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


func _gen_texts() -> Array[String]:
	var out: Array[String] = []
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


## Every text of the grade's units and of its generators (12 seeds a level).
func _all_texts() -> Array[String]:
	var out: Array[String] = []
	for u in _units():
		if Curriculum.has_content(str(u.id)):
			out.append_array(_texts(str(u.id)))
	out.append_array(_gen_texts())
	return out


func _has_word(text: String, word: String) -> bool:
	return RegEx.create_from_string("\\b" + word + "\\b").search(text.to_lower()) != null


func test_the_outline_has_every_unit_of_the_research() -> void:
	for subject in SUBJECTS:
		assert_eq(Curriculum.units(GRADE, subject).size(), int(UNITS[subject]), "grade 8 %s" % subject)


func test_grade_8_history_geography_citizenship_are_written_for_every_unit() -> void:
	var exercises := 0
	for u in _units():
		var id := str(u.id)
		assert_true(Curriculum.has_content(id), "%s is written" % id)
		if not Curriculum.has_content(id):
			continue
		assert_eq(Curriculum.content_problems(id), [] as Array[String], id)
		var c := Curriculum.content(id)
		assert_between((c.lesson as Array).size(), 4, Curriculum.MAX_CARDS, "%s: a lesson of 4-8 cards" % id)
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
	gut.p("%d hand-written exercises in grade 8 history, geography and citizenship" % exercises)


## The School's quality bar (owner #94; test_school_quality.gd, whose scope is grades 3-7): memory first, the world or
## what comes next last, 4-8 cards, pictures (two in geography), three kinds of exercise, at most 70% choice and
## true-or-false, three a level or a generator, real hints and worked answers, no hint that gives the answer away.
func test_every_unit_meets_the_schools_quality_bar() -> void:
	var quality: Node = load("res://tests/unit/test_school_quality.gd").new()
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		assert_eq(quality.call("bar", id, id.split(".")[1]), [] as Array[String], "%s meets the bar" % id)
	quality.free()


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
## next) and "Do it in the world" (a challenge to try). Grade 8 builds on grades 3 to 7, and its first card names the
## grade it recalls.
func test_every_lesson_starts_with_memory_of_an_earlier_grade_and_ends_in_the_world_with_what_comes_next() -> void:
	var earlier := RegEx.create_from_string("grade [34567]\\b")
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


## Owner #112, #115, #117: learn by doing. A unit whose topic is a Life or Success Experience points to it by name.
func test_units_point_to_their_life_and_success_experiences() -> void:
	for id: String in EXPERIENCES:
		if not Curriculum.has_content(id):
			assert_true(false, "%s is written" % id)
			continue
		var last := str((Curriculum.content(id).lesson as Array)[-1].text)
		assert_true(last.contains(str(EXPERIENCES[id])), "%s's last card points to %s" % [id, EXPERIENCES[id]])


## Each name is an Experience's own title (data/life/experiences/*.json, data/success/experiences/*.json), so the child
## finds it in the LIFE tab (Earth and Weather is Life L3a's, merged before these units).


func test_the_experiences_named_are_real() -> void:
	var titles: Array[String] = []
	for dir: String in ["res://data/life/experiences/", "res://data/success/experiences/"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".json"):
				var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir + f))
				if d is Dictionary:
					titles.append(str(d.get("title", "")))
	assert_gt(titles.size(), 6, "the Experiences' data")
	for id: String in EXPERIENCES:
		var name := str(EXPERIENCES[id])
		var found := titles.any(func(t: String) -> bool: return t.contains(name))
		assert_true(found, "%s names %s, an Experience's title" % [id, name])


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


## The generators these units use are grade 8 humanities' own ("g8h"), each exists, and each is used.
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		var gens: Array = Curriculum.content(id).generators
		assert_false(gens.is_empty(), "%s practises with a generator too" % id)
		for g: Dictionary in gens:
			assert_true(str(g.gen).begins_with(SOURCE), "%s uses %s" % [id, g.gen])
			assert_true(SchoolGen.exists(str(g.gen)), "%s: %s exists" % [id, g.gen])
			used[str(g.gen)] = true
	assert_gt(used.size(), 30, "grade 8 humanities practise with generators")
	for gen in SchoolGen.ids():
		if gen.begins_with(SOURCE):
			assert_true(used.has(gen), "%s is used by a grade 8 humanities unit" % gen)


## The lessons draw the grade's pictures: a steam engine, timelines and maps of the modern world, the greenhouse effect,
## development's scatter and population pyramids, the tourism cycle, the ocean's zones, map projections, layered GIS
## maps; a parliament's seats, a till receipt, reasons weighed on a balance, risk against return.
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
	var path := "res://ui/school/school_picture_g8hum.gd"
	assert_true(ResourceLoader.exists(path), "the grade's picture file")
	if not ResourceLoader.exists(path):
		return
	for kind: String in (load(path) as Script).get_script_constant_map()["KINDS"]:
		assert_true(drawn.has(kind), "a lesson draws %s" % kind)


## A number exercise whose answer is a year shows it as one (1807, not 1,807), hand-written or generated; and "year"
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
			assert_between(y, 1, 2700, "a year's answer: %s" % ex.prompt)   # litter in the sea lasts to about 2625
	assert_gt(checked, 3, "the units ask for years")


## Money is the game's gold everywhere (research §5.5 ruling 6), in the lessons and the generators.
func test_money_is_the_games_gold() -> void:
	for t in _all_texts():
		assert_false(t.contains("$") or t.contains("£") or t.contains("€"), t)
		for w in CURRENCIES:
			assert_false(_has_word(t, w), "'%s' in %s" % [w, t])


## Research §5.4 rules 2, 3 and 7: no gruesome words or weapon detail in hard history, no political parties, no
## disputed places, no living people or brands.
func test_hard_history_with_respect_no_parties_no_disputed_places_no_living_people() -> void:
	for t in _all_texts():
		for w in GRUESOME + PARTIES + DISPUTED + LIVING_OR_BRANDS:
			assert_false(_has_word(t, w), "'%s' in %s" % [w, t])


## The Holocaust is named truthfully (the Nazis murdered six million Jews, and others), and only that unit uses the word.
func test_murder_is_named_only_for_the_holocaust() -> void:
	var said := false
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for t in _texts(id):
			for w in MURDER:
				if _has_word(t, w):
					assert_eq(id, MURDER_UNIT, "'%s' only in the Holocaust unit: %s" % [w, t])
					said = said or id == MURDER_UNIT
	for t in _gen_texts():
		for w in MURDER:
			assert_false(_has_word(t, w), "'%s' in a generator: %s" % [w, t])
	assert_true(said, "the Holocaust unit says what happened")


## Research §5.4 rule 3 and §5.5 ruling 9: the hard-history units (the slave trade and the Holocaust above all) are
## marked for the grown-ups' page with what they name, and no other grade 8 humanities unit is.
func test_hard_history_is_listed_for_grown_ups() -> void:
	for u in _units():
		var id := str(u.id)
		var hard: Variant = u.get("hard")
		if HARD.has(id):
			assert_true(hard is String and str(hard).strip_edges() != "", "%s names its hard history" % id)
			assert_lte(str(hard).length(), MAX_HARD, "%s: a short line" % id)
			assert_false(str(hard).contains(";"), "%s: no semicolons (the page joins them with '; ')" % id)
		else:
			assert_null(hard, "%s is not marked hard" % id)
	assert_true(HARD.has("g8.history.slavery_abolition") and HARD.has("g8.history.holocaust_remembrance"),
		"research ruling 9")
