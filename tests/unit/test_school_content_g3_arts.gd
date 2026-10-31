extends GutTest
## Owner #70 and #73 ("start from grade 3 and finish all grades accordingly"; research §6.3): grade 3's computing, art
## and design and music are written for every unit of the outline. Each unit teaches with a lesson of 4 or more cards
## that opens with a memory question and ends with something to try in the world (research §5.3 rules 1 and 8), has at
## least 12 hand-written exercises at levels 1, 2 and 3 of at least two kinds, each with a hint (a strategy) and a worked
## answer, and rounds that vary and never show a hand-written exercise twice. The music units that teach listening let
## the child listen (a tune or claps, SchoolSound) in at least 6 exercises each. The facts the lessons state about paint
## are checked against paint. (Every exercise's validity, answers, pictures and words are the shared content test's,
## test_school_content.gd.)

const GRADE := 3
const SUBJECTS: Array[String] = ["computing", "art", "music"]
const UNITS := {"computing": 11, "art": 9, "music": 9}   # research §6.3
const MIN_EXERCISES := 12
const MIN_CARDS := 4
## Music units that teach listening, and the sounds they must use: "rhythm" (claps), "notes" (a tune) or "any".
## instrument_families is taught in words: the School's sound is one plucked tone and claps, not an orchestra.
const LISTENING := {"g3.music.pulse_rhythm": "rhythm", "g3.music.high_low": "notes",
	"g3.music.loud_quiet_fast_slow": "any", "g3.music.rhythm_notation": "rhythm", "g3.music.sing_well": "notes",
	"g3.music.compose_loops": "any", "g3.music.world_music": "any", "g3.music.music_stories": "notes"}
const MIN_SOUNDS := 6
## Paint: two primaries make a secondary (either order).
const MIXES := {"red+yellow": "orange", "yellow+blue": "green", "blue+red": "purple"}


func _units() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for subject in SUBJECTS:
		out.append_array(Curriculum.units(GRADE, subject))
	return out


func _texts(id: String) -> Array[String]:
	var out: Array[String] = []
	var c := Curriculum.content(id)
	for card: Dictionary in c.lesson:
		out.append(str(card.text))
	for ex: Dictionary in c.exercises:
		out.append_array([str(ex.prompt), str(ex.hint), str(ex.get("explain", ""))])
		for it: Variant in ex.get("choices", []) + ex.get("items", []) + ex.get("matches", []):
			out.append(ExerciseCheck.item_text(it))
	return out


func test_the_outline_has_every_unit_of_the_research() -> void:
	for subject in SUBJECTS:
		assert_eq(Curriculum.units(GRADE, subject).size(), int(UNITS[subject]), "grade 3 %s" % subject)


func test_grade_3_computing_art_music_are_written_for_every_unit() -> void:
	var exercises := 0
	for u in _units():
		var id := str(u.id)
		assert_true(Curriculum.has_content(id), "%s is written" % id)
		if not Curriculum.has_content(id):
			continue
		assert_eq(Curriculum.content_problems(id), [] as Array[String], id)
		var c := Curriculum.content(id)
		assert_between((c.lesson as Array).size(), MIN_CARDS, Curriculum.MAX_CARDS, "%s: a lesson of 4 to 8 cards" % id)
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
					distinct[str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("sound", "")) + str(ex.get("board", ""))] = true
					if not str(ex.id).begins_with("gen:"):
						assert_false(ids.has(ex.id), "%s: %s twice in a round" % [id, ex.id])
						ids[ex.id] = true
		assert_gte(distinct.size(), 12, "%s: varied practice" % id)
	gut.p("%d hand-written exercises in grade 3 computing, art and music" % exercises)


func test_every_exercise_has_a_strategy_hint_and_a_worked_answer() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for ex: Dictionary in Curriculum.content(id).exercises:
			assert_ne(str(ex.get("hint", "")).strip_edges(), "", "%s: a hint" % ex.id)
			assert_ne(str(ex.get("explain", "")).strip_edges(), "", "%s: a worked answer" % ex.id)
			assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: the hint is a strategy, not the answer" % ex.id)


## Research §5.3: "Start with memory" (a quick question from earlier) and "Do it in the world" (a challenge to try).
func test_every_lesson_starts_with_a_memory_question_and_ends_in_the_world() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		var cards: Array = Curriculum.content(id).lesson
		assert_true(str(cards[0].text).contains("?"), "%s: the first card asks a memory question" % id)
		assert_true(str(cards[-1].text).to_lower().contains("world"), "%s: the last card is something to try in the world" % id)


## The brief: "Which pattern did you hear?", "How many claps?", "Which note is higher?", "Does the tune go up or down?"
func test_the_music_units_let_you_listen() -> void:
	for id: String in LISTENING:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var sounds := 0
		for ex: Dictionary in Curriculum.content(id).exercises:
			if ex.get("sound") is Dictionary and (LISTENING[id] == "any" or str(ex.sound.kind) == LISTENING[id]):
				sounds += 1
		assert_gte(sounds, MIN_SOUNDS, "%s: %d exercises to listen to" % [id, sounds])


## The generators these units use are their own ("g3a"), each exists, and every one of them is used here.
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for g: Dictionary in Curriculum.content(id).generators:
			assert_true(str(g.gen).begins_with("g3a."), "%s uses %s" % [id, g.gen])
			assert_true(SchoolGen.exists(str(g.gen)), "%s: %s exists" % [id, g.gen])
			used[str(g.gen)] = true
	for gen in SchoolGen.ids():
		if gen.begins_with("g3a."):
			assert_true(used.has(gen), "%s is used by a grade 3 computing, art or music unit" % gen)


## Every "red and yellow make orange" (or "red + yellow = orange") the art and design lessons state is how paint mixes.
func test_the_colour_mixing_facts_are_right() -> void:
	var rule := RegEx.create_from_string("\\b(red|yellow|blue) (?:and|\\+) (red|yellow|blue) (?:make|makes|=|mix to make) (\\w+)")
	var checked := 0
	for u in Curriculum.units(GRADE, "art"):
		if not Curriculum.has_content(str(u.id)):
			continue
		for t in _texts(str(u.id)):
			for m in rule.search_all(t.to_lower()):
				var key := m.get_string(1) + "+" + m.get_string(2)
				var back := m.get_string(2) + "+" + m.get_string(1)
				var made := str(MIXES.get(key, MIXES.get(back, "")))
				assert_eq(m.get_string(3), made, "%s: %s" % [u.id, t])
				checked += 1
	assert_gte(checked, 6, "the mixing facts were found")


## Research §5.4 rule 6: online safety every grade, and never ask a child for personal details.
func test_the_lessons_never_ask_for_personal_details() -> void:
	var ask := RegEx.create_from_string("(what is|what's|tell us|type|enter|write) your (real |full |home |school )?(name|address|phone|number|password|school|birthday|age|email)")
	for u in _units():
		if not Curriculum.has_content(str(u.id)):
			continue
		for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
			assert_null(ask.search(str(ex.prompt).to_lower()), "%s asks: %s" % [ex.id, ex.prompt])


## The music lessons name Saint-Saëns (The Carnival of the Animals, public domain): the School's font draws "ë".
func test_the_font_draws_saint_saens_name() -> void:
	assert_true(ThemeDB.fallback_font.has_char("ë".unicode_at(0)), "the School's font has ë")
	var named := false
	if Curriculum.has_content("g3.music.music_stories"):
		for t in _texts("g3.music.music_stories"):
			named = named or t.contains("Saint-Saëns")
	assert_true(named, "the music stories unit names Saint-Saëns")


## "FORWARD 2, TURN RIGHT, FORWARD" as RobotCheck's commands ([] when the text is not a program).
func _program(text: String) -> Array:
	var out: Array = []
	for part in text.split(", "):
		var w := part.strip_edges()
		if w == "TURN LEFT" or w == "TURN RIGHT":
			out.append("L" if w == "TURN LEFT" else "R")
		elif w == "FORWARD":
			out.append("F")
		elif w.begins_with("FORWARD ") and w.substr(8).is_valid_int() and int(w.substr(8)) >= 2:
			for i in int(w.substr(8)):
				out.append("F")
		else:
			return []
	return out


## The robot's facts are run, not trusted: every "code the robot" worked answer ("One program that works: …") reaches
## the flag, and in every choice of programs on a board only the right one does (RobotCheck).
func test_the_robot_programs_do_what_the_lessons_say() -> void:
	var checked := 0
	for u in Curriculum.units(GRADE, "computing"):
		if not Curriculum.has_content(str(u.id)):
			continue
		for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
			if str(ex.type) == "robot":
				var said := str(ex.explain).get_slice(": ", 1).trim_suffix(".")
				assert_true(RobotCheck.reaches(ex.board, _program(said)), "%s: %s" % [ex.id, ex.explain])
				checked += 1
			elif str(ex.type) == "choice" and ex.get("picture", {}).get("kind", "") == "robot" and ex.picture.has("goal"):
				var b: Dictionary = ex.picture
				for i in (ex.choices as Array).size():
					var p := _program(str(ex.choices[i]))
					if p.is_empty():
						continue
					assert_eq(RobotCheck.reaches(b, p), i == int(ex.answer), "%s: %s" % [ex.id, ex.choices[i]])
					checked += 1
	assert_gte(checked, 20, "the robot programs were run")


## "Copy the rhythm": at most 8 boxes, starting with a clap you can hear, and the worked answer names the boxes.
func test_the_rhythms_to_copy_start_with_a_clap() -> void:
	var n := 0
	for u in Curriculum.units(GRADE, "music"):
		if not Curriculum.has_content(str(u.id)):
			continue
		for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
			if str(ex.type) != "rhythm":
				continue
			n += 1
			var p := str(ex.sound.pattern)
			assert_true(p.begins_with("x") and p.length() <= 8, "%s: %s" % [ex.id, p])
			assert_true(str(ex.explain).contains("box"), "%s: the worked answer names the boxes" % ex.id)
	assert_gte(n, 9, "pulse and rhythm, reading rhythms and loops copy rhythms")


## "Mix the colour": every worked answer names exactly the paints of the target's recipe (ColourMix.RECIPES), so what
## the child reads is what the bowl checks.
func test_the_mixing_answers_name_the_recipes_paints() -> void:
	var n := 0
	for u in Curriculum.units(GRADE, "art"):
		if not Curriculum.has_content(str(u.id)):
			continue
		for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
			if str(ex.type) != "mix":
				continue
			n += 1
			var recipe: Dictionary = ColourMix.RECIPES[str(ex.target)]
			var said := str(ex.explain).get_slice(":", str(ex.explain).count(":")).to_lower()
			for paint: String in ColourMix.PAINTS:
				var named := RegEx.create_from_string("\\b%s\\b" % paint).search(said) != null
				assert_eq(named, recipe.has(paint), "%s: %s in %s" % [ex.id, paint, ex.explain])
	assert_gte(n, 8, "colour mixing, patterns and cave art mix paint")
