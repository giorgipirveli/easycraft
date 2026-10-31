extends GutTest
## Owner #70 and #73 ("start from grade 3 and finish all grades accordingly"; research §6.4): grade 4's computing, art
## and design and music are written for every unit of the outline, building on grade 3's. Each unit teaches with a
## lesson of 4 or more cards that opens with a memory question and ends with something to try in the world (research
## §5.3 rules 1 and 8), has at least 12 hand-written exercises at levels 1, 2 and 3 of at least two kinds, each with a
## hint (a strategy) and a worked answer, and rounds that vary and never show a hand-written exercise twice. The music
## units that teach listening let the child listen (a tune or claps, SchoolSound) in at least 6 exercises each. The facts
## the lessons state are checked where a test can work them out: paint mixes, complementary pairs and warm and cool
## colours by the colour wheel, a stave's notes by their letters, a rhythm's beats by its notes, the robot's programs by
## RobotCheck. (Every exercise's validity, answers, pictures and words are the shared content test's,
## test_school_content.gd.)

const GRADE := 4
const SUBJECTS: Array[String] = ["computing", "art", "music"]
const UNITS := {"computing": 11, "art": 9, "music": 9}   # research §6.4
const MIN_EXERCISES := 12
const MIN_CARDS := 4
## Music units that teach listening, and the sounds they must use: "rhythm" (claps), "notes" (a tune) or "any".
## the_orchestra and music_long_ago are taught in words: the School's sound is one plucked tone and claps.
const LISTENING := {"g4.music.note_values": "any", "g4.music.beats_in_a_bar": "notes", "g4.music.the_stave": "notes",
	"g4.music.compose_melody": "notes", "g4.music.ostinato_layers": "any", "g4.music.rounds": "notes",
	"g4.music.music_for_pictures": "notes"}
const MIN_SOUNDS := 6
## Paint: two primaries make a secondary (either order).
const MIXES := {"red+yellow": "orange", "yellow+blue": "green", "blue+red": "purple"}
## The painters' colour wheel, round from yellow: each colour's complementary colour is the one opposite (6 on).
const WHEEL: Array[String] = ["yellow", "yellow-orange", "orange", "red-orange", "red", "red-purple", "purple",
	"blue-purple", "blue", "blue-green", "green", "yellow-green"]
## Warm and cool as the lessons sort them (the colours on the wheel's border, yellow-green and red-purple, are never sorted).
const WARM: Array[String] = ["red", "orange", "yellow", "red-orange", "yellow-orange"]
const COOL: Array[String] = ["blue", "green", "purple", "blue-green", "blue-purple"]
const NOTE_BEATS := {"semibreve": 4, "dotted minim": 3, "minim": 2, "crotchet": 1, "quavers": 1, "rest": 1}


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


func _exercises(subject: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u in Curriculum.units(GRADE, subject):
		if Curriculum.has_content(str(u.id)):
			for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
				out.append(ex)
	return out


func test_the_outline_has_every_unit_of_the_research() -> void:
	for subject in SUBJECTS:
		assert_eq(Curriculum.units(GRADE, subject).size(), int(UNITS[subject]), "grade 4 %s" % subject)


func test_grade_4_computing_art_music_are_written_for_every_unit() -> void:
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
	gut.p("%d hand-written exercises in grade 4 computing, art and music" % exercises)


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


## The generators these units use are their own ("g4a"), each exists, and every one of them is used here.
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for g: Dictionary in Curriculum.content(id).generators:
			assert_true(str(g.gen).begins_with("g4a."), "%s uses %s" % [id, g.gen])
			assert_true(SchoolGen.exists(str(g.gen)), "%s: %s exists" % [id, g.gen])
			used[str(g.gen)] = true
	assert_gt(used.size(), 0, "the units practise with generators")
	for gen in SchoolGen.ids():
		if gen.begins_with("g4a."):
			assert_true(used.has(gen), "%s is used by a grade 4 computing, art or music unit" % gen)


## Every "red and yellow make orange" the art lessons state is how paint mixes; every "red and green are complementary"
## and "the opposite of blue is orange" is the colour wheel's.
func test_the_colour_facts_are_right() -> void:
	var rule := RegEx.create_from_string("\\b(red|yellow|blue) (?:and|\\+) (red|yellow|blue) (?:make|makes|=|mix to make) (\\w+)")
	var pair := RegEx.create_from_string("\\b([a-z]+(?:-[a-z]+)?) and ([a-z]+(?:-[a-z]+)?) are complementary")
	var opp := RegEx.create_from_string("\\bopposite (?:of |to )?([a-z]+(?:-[a-z]+)?) (?:is|on the wheel is) ([a-z]+(?:-[a-z]+)?)")
	var mixes := 0
	var pairs := 0
	for u in Curriculum.units(GRADE, "art"):
		if not Curriculum.has_content(str(u.id)):
			continue
		for t in _texts(str(u.id)):
			var low := t.to_lower()
			for m in rule.search_all(low):
				var made := str(MIXES.get(m.get_string(1) + "+" + m.get_string(2), MIXES.get(m.get_string(2) + "+" + m.get_string(1), "")))
				assert_eq(m.get_string(3), made, "%s: %s" % [u.id, t])
				mixes += 1
			for m in pair.search_all(low) + opp.search_all(low):
				if WHEEL.has(m.get_string(1)) and WHEEL.has(m.get_string(2)):
					assert_eq(m.get_string(2), _opposite(m.get_string(1)), "%s: %s" % [u.id, t])
					pairs += 1
	assert_gte(mixes, 3, "the mixing facts were found")
	assert_gte(pairs, 4, "the complementary facts were found")


func _opposite(colour: String) -> String:
	return WHEEL[(WHEEL.find(colour) + 6) % WHEEL.size()]


## Every "warm or cool?" sort puts the warm colours (red, orange, yellow and their mixes) and the cool ones (blue,
## green, purple and theirs) in their groups; a choice of "the complementary colour" is the wheel's opposite.
func test_warm_cool_and_complementary_exercises_follow_the_wheel() -> void:
	var sorted_colours := 0
	for ex in _exercises("art"):
		if str(ex.type) == "sort":
			var groups: Array = ex.groups
			var warm := -1
			var cool := -1
			for i in groups.size():
				if str(groups[i]).to_lower().begins_with("warm"):
					warm = i
				elif str(groups[i]).to_lower().begins_with("cool"):
					cool = i
			if warm < 0 or cool < 0:
				continue
			for i in (ex.items as Array).size():
				var c := str(ex.items[i]).to_lower()
				if WARM.has(c):
					assert_eq(int(ex.answer[i]), warm, "%s: %s is warm" % [ex.id, c])
					sorted_colours += 1
				elif COOL.has(c):
					assert_eq(int(ex.answer[i]), cool, "%s: %s is cool" % [ex.id, c])
					sorted_colours += 1
	assert_gte(sorted_colours, 8, "warm and cool colours were sorted")


## A choice read from a stave ("Which note is this?", "Which word do the notes spell?"): the right choice is the notes'
## letters, and no other choice is.
func test_the_stave_notes_are_read_right() -> void:
	var read := 0
	for ex in _exercises("music"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "choice" or not pic is Dictionary or str(pic.get("kind", "")) != "stave":
			continue
		var letters := ""
		for n: String in pic.notes:
			letters += n.left(1)
		for i in (ex.choices as Array).size():
			var c := ExerciseCheck.item_text(ex.choices[i]).replace(" ", "")
			if not RegEx.create_from_string("^[A-G]+$").search(c):
				continue
			assert_eq(c == letters, i == int(ex.answer), "%s: %s on the stave, choice %s" % [ex.id, letters, c])
			read += 1
	assert_gte(read, 20, "stave notes were read")


## "How many beats…?" about written notes: the answer is the notes' beats (semibreve 4, dotted minim 3, minim 2,
## crotchet 1, two quavers 1, a crotchet rest 1).
func test_the_beats_are_counted_right() -> void:
	var counted := 0
	for ex in _exercises("music"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "number" or not pic is Dictionary or str(pic.get("kind", "")) != "notation" \
				or not str(ex.prompt).to_lower().contains("how many beats"):
			continue
		var beats := 0
		for b: String in pic.beats:
			beats += int(NOTE_BEATS[b])
		assert_eq(NumberAnswer.value(str(ex.answer)), float(beats), "%s: %s" % [ex.id, ex.prompt])
		counted += 1
	assert_gte(counted, 4, "beats were counted")


## The lessons name Albrecht Dürer, Jean-François Champollion, Frère Jacques and Ravel's Boléro in their own spelling:
## the School's font draws ü, ç, è and é (test_school_content.gd's ALLOWED lets them in).
func test_the_font_draws_the_names_letters() -> void:
	for ch in ["ü", "ç", "è", "é"]:
		assert_true(ThemeDB.fallback_font.has_char(ch.unicode_at(0)), "the School's font has %s" % ch)
	var names := {"Dürer": "g4.art.printmaking", "Jean-François Champollion": "g4.art.ancient_art",
		"Frère Jacques": "g4.music.rounds", "Boléro": "g4.music.ostinato_layers"}
	for name: String in names:
		var found := false
		if Curriculum.has_content(names[name]):
			for t in _texts(names[name]):
				found = found or t.contains(name)
		assert_true(found, "%s names %s" % [names[name], name])


## Research §5.4 rule 6: online safety every grade, and never ask a child for personal details.
func test_the_lessons_never_ask_for_personal_details() -> void:
	var ask := RegEx.create_from_string("(what is|what's|tell us|type|enter|write) your (real |full |home |school )?(name|address|phone|number|password|school|birthday|age|email)")
	for u in _units():
		if not Curriculum.has_content(str(u.id)):
			continue
		for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
			assert_null(ask.search(str(ex.prompt).to_lower()), "%s asks: %s" % [ex.id, ex.prompt])


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
## the flag within its `max`, and in every choice of programs on a board only the right one does (RobotCheck).
func test_the_robot_programs_do_what_the_lessons_say() -> void:
	var checked := 0
	for ex in _exercises("computing"):
		if str(ex.type) == "robot":
			var said := _program(str(ex.explain).get_slice(": ", 1).trim_suffix("."))
			assert_true(RobotCheck.reaches(ex.board, said), "%s: %s" % [ex.id, ex.explain])
			if ex.has("max"):
				assert_lte(said.size(), int(ex.max), "%s: the worked answer fits max" % ex.id)
			checked += 1
		elif str(ex.type) == "choice" and ex.get("picture", {}).get("kind", "") == "robot" and ex.picture.has("goal"):
			var b: Dictionary = ex.picture
			for i in (ex.choices as Array).size():
				var p := _program(str(ex.choices[i]))
				if p.is_empty():
					continue
				assert_eq(RobotCheck.reaches(b, p), i == int(ex.answer), "%s: %s" % [ex.id, ex.choices[i]])
				checked += 1
	assert_gte(checked, 8, "the robot programs were run")


## "Copy the rhythm": at most 8 boxes, starting with a clap you can hear, and the worked answer names the boxes.
func test_the_rhythms_to_copy_start_with_a_clap() -> void:
	var n := 0
	for ex in _exercises("music"):
		if str(ex.type) != "rhythm":
			continue
		n += 1
		var p := str(ex.sound.pattern)
		assert_true(p.begins_with("x") and p.length() <= 8, "%s: %s" % [ex.id, p])
		assert_true(str(ex.explain).contains("box"), "%s: the worked answer names the boxes" % ex.id)
	assert_gte(n, 4, "note values and ostinatos copy rhythms")


## "Mix the colour": every worked answer names exactly the paints of the target's recipe (ColourMix.RECIPES), and a
## recipe of unequal drops (a tertiary colour, a light or dark grey) says its drops ("2 red and 1 yellow").
func test_the_mixing_answers_name_the_recipes_paints() -> void:
	var n := 0
	for ex in _exercises("art"):
		if str(ex.type) != "mix":
			continue
		n += 1
		var recipe: Dictionary = ColourMix.RECIPES[str(ex.target)]
		var said := str(ex.explain).get_slice(":", str(ex.explain).count(":")).to_lower()
		for paint: String in ColourMix.PAINTS:
			var named := RegEx.create_from_string("\\b%s\\b" % paint).search(said) != null
			assert_eq(named, recipe.has(paint), "%s: %s in %s" % [ex.id, paint, ex.explain])
		var even := true
		for paint: String in recipe:
			even = even and int(recipe[paint]) == 1
		if not even:
			assert_string_contains(str(ex.explain), ColourMix.words(recipe), "%s: the drops" % ex.id)
	assert_gte(n, 8, "the colour wheel and light and shade mix paint")
