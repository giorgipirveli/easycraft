extends GutTest
## Owner #68 (spec §22.5): the School's content test. Every written unit is valid (its lesson cards, its exercises, the
## generators it names); every hand-written exercise's own answer passes its own checker and the other answers do not;
## every generator makes valid, right-by-their-own-answer exercises at every level for many seeds; every picture can be
## drawn; grade 4's maths is written for every unit of its outline, with its first science and English units; and the
## words are kind (no guilt, pressure or shaming words, no other game's names), English, and British-spelt (§22.6).

const SEEDS := 120
## Written in the lessons' own words or not at all (spec §6, research §7; test_no_guilt_words.gd's list and more).
const UNKIND: Array[String] = ["miss you", "don't go", "lonely", "last chance", "hurry", "only today", "you failed",
	"failure", "loser", "for babies", "noob", "streak", "wrong!", "stupid", "dumb", "idiot", "lazy", "you lose"]
const OTHER_GAMES: Array[String] = ["minecraft", "roblox", "creeper", "enderman", "nether", "redstone", "steve", "robux",
	"fortnite", "pokemon", "mario"]
## US spellings the game writes the British way (spec §22.6 ruling 3).
const US_SPELLINGS: Array[String] = ["color", "colors", "colored", "center", "centers", "meter", "meters", "centimeter",
	"centimeters", "kilometer", "kilometers", "liter", "liters", "milliliter", "milliliters", "favorite", "gray",
	"neighbor", "neighbors", "math", "behavior", "flavor", "honor", "organize", "realize", "trapezoid"]
## Letters beyond ASCII the lessons may use (all in the game's font).
## Grade 5 writes powers of ten: 10⁴ (5.NBT.2); ë: Saint-Saëns; grade 4 arts: ç (Jean-François Champollion), è (Frère
## Jacques), é (Boléro), ü (Albrecht Dürer).
const ALLOWED := "×÷−°²³½¼¾•’“”—…√≤≥π·⁰¹⁴⁵⁶⁷⁸⁹ëçèéü"


func _written() -> Array[String]:
	var out: Array[String] = []
	for g in Curriculum.grades():
		for s: Dictionary in Curriculum.subjects(g):
			for u: Dictionary in Curriculum.units(g, str(s.id)):
				if Curriculum.has_content(str(u.id)):
					out.append(str(u.id))
	return out


func _texts_of(ex: Dictionary) -> Array[String]:
	var out: Array[String] = [str(ex.get("prompt", "")), str(ex.get("hint", "")), str(ex.get("explain", ""))]
	for c: Variant in ex.get("choices", []) + ex.get("items", []) + ex.get("matches", []) + ex.get("groups", []):
		out.append(ExerciseCheck.item_text(c))
	return out


func _all_texts() -> Array[String]:
	var out: Array[String] = []
	for id in _written():
		var c := Curriculum.content(id)
		for card: Dictionary in c.lesson:
			out.append(str(card.get("text", "")))
		for ex: Dictionary in c.exercises:
			out.append_array(_texts_of(ex))
	for gen in SchoolGen.ids():
		for level in [1, 2, 3]:
			for s in 12:
				out.append_array(_texts_of(SchoolGen.make(gen, s, level)))
	return out


func _pictures_of(ex: Dictionary) -> Array:
	var out: Array = []
	if ex.has("picture"):
		out.append(ex.picture)
	for c: Variant in ex.get("choices", []):
		if c is Dictionary and c.has("picture"):
			out.append(c.picture)
	return out


## The responses that must not be right: every other choice, the other truth, the order reversed.
func _wrong_responses(ex: Dictionary) -> Array:
	var out: Array = []
	match str(ex.type):
		"choice":
			for i in (ex.choices as Array).size():
				if i != int(ex.answer):
					out.append(i)
		"truefalse":
			out.append(not ex.answer)
		"order":
			var r: Array[int] = []
			for i: Variant in ex.answer:
				r.push_front(int(i))
			out.append(r)
		"point":   # grade 5: the pair the other way round, and every crossing next to the answer
			var a: Vector2i = ExerciseCheck.answer_of(ex)
			var s := GridCheck.step(ex.grid)
			for p: Vector2i in [Vector2i(a.y, a.x), a + Vector2i(s.x, 0), a - Vector2i(s.x, 0), a + Vector2i(0, s.y),
					a - Vector2i(0, s.y)]:
				if p != a and GridCheck.on_grid(ex.grid, p):
					out.append(p)
	return out


func _check_exercise(ex: Dictionary, where: String) -> void:
	assert_eq(ExerciseCheck.problem(ex), "", where)
	if ExerciseCheck.problem(ex) != "":
		return
	assert_true(ExerciseCheck.is_right(ex, ExerciseCheck.answer_of(ex)), "%s: its own answer is right" % where)
	for w: Variant in _wrong_responses(ex):
		assert_false(ExerciseCheck.is_right(ex, w), "%s: %s is not right" % [where, w])
	for p: Variant in _pictures_of(ex):
		assert_eq(SchoolPicture.problem(p), "", "%s: its picture %s" % [where, p])


# --- Written units --------------------------------------------------------------------------------------------------

func test_every_written_unit_has_no_problems() -> void:
	for id in _written():
		assert_eq(Curriculum.content_problems(id), [] as Array[String], id)


func test_every_hand_written_exercise_is_right_by_its_own_answer_only() -> void:
	var n := 0
	for id in _written():
		for ex: Dictionary in Curriculum.content(id).exercises:
			_check_exercise(ex, str(ex.id))
			n += 1
	gut.p("%d hand-written exercises" % n)


func test_every_lesson_card_fits_and_its_picture_can_be_drawn() -> void:
	for id in _written():
		for card: Dictionary in Curriculum.content(id).lesson:
			assert_lte(str(card.text).length(), 260, "%s: a card of %d letters" % [id, str(card.text).length()])
			if card.has("picture"):
				assert_eq(SchoolPicture.problem(card.picture), "", "%s: %s" % [id, card.picture])
			if card.has("sound"):   # a tune or claps (SchoolSound)
				assert_eq(SchoolSound.problem(card.sound), "", "%s: %s" % [id, card.sound])


# --- Generators -------------------------------------------------------------------------------------------------------

func test_every_generator_makes_valid_exercises_at_every_level() -> void:
	for gen in SchoolGen.ids():
		for level in [1, 2, 3]:
			for s in SEEDS:
				var ex := SchoolGen.make(gen, s, level)
				_check_exercise(ex, "%s level %d seed %d" % [gen, level, s])
				if ExerciseCheck.problem(ex) != "":
					break


func test_generators_vary_with_the_seed() -> void:
	for gen in SchoolGen.ids():
		var seen := {}
		for s in 40:
			var ex := SchoolGen.make(gen, s, 2)
			seen[str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("answer", "")) + str(ex.get("board", ""))
				+ str(ex.get("choices", "")) + str(ex.get("sound", ""))] = true   # a rhythm to copy is its sound
		assert_gte(seen.size(), 4, "%s makes different exercises" % gen)


func test_every_generator_is_used_by_a_written_unit() -> void:
	var used := {}
	for id in _written():
		for g: Dictionary in Curriculum.content(id).generators:
			used[str(g.gen)] = true
	for gen in SchoolGen.ids():
		assert_true(used.has(gen), "%s is used" % gen)


# --- What is written ------------------------------------------------------------------------------------------------

func test_grade_4_maths_is_written_for_every_unit() -> void:
	for u: Dictionary in Curriculum.units(4, "maths"):
		var id := str(u.id)
		if not u.has("file"):
			continue   # the research's new units (owner #73) are written next
		assert_true(Curriculum.has_content(id), "%s is written" % id)
		if not Curriculum.has_content(id):
			continue
		var c := Curriculum.content(id)
		assert_between((c.lesson as Array).size(), 3, Curriculum.MAX_CARDS, "%s: a lesson of 3 or more cards" % id)
		var types := {}
		var distinct := {}
		for stars in [0, 1, 2]:
			for s in 20:
				var round := RoundPlan.plan(c, s * 7 + stars, stars)
				assert_eq(round.size(), MasteryRules.ROUND_SIZE, "%s fills a round" % id)
				for ex in round:
					types[str(ex.type)] = true
					distinct[str(ex.prompt) + str(ex.get("picture", ""))] = true
		assert_gte(types.size(), 2, "%s: at least two kinds of exercise" % id)
		assert_gte(distinct.size(), 25, "%s: varied practice" % id)
		assert_gte((c.exercises as Array).size(), 6, "%s: hand-written exercises too" % id)


## Owner #68, grade 4 agent: every science and English unit of grade 4 is written, with a lesson, enough hand-written
## practice for a round that never repeats one, and every level from easy to hard.
func test_grade_4_science_and_english_are_written_for_every_unit() -> void:
	for subject: String in ["science", "english"]:
		for u: Dictionary in Curriculum.units(4, subject):
			var id := str(u.id)
			if not u.has("file"):
				continue   # the research's new units (owner #73) are written next
			assert_true(Curriculum.has_content(id), "%s is written" % id)
			if not Curriculum.has_content(id):
				continue
			var c := Curriculum.content(id)
			assert_between((c.lesson as Array).size(), 3, Curriculum.MAX_CARDS, "%s: a lesson of 3 or more cards" % id)
			assert_gte((c.exercises as Array).size(), 10, "%s: at least 10 hand-written exercises" % id)
			var levels := {}
			for ex: Dictionary in c.exercises:
				levels[int(ex.level)] = true
			for g: Dictionary in c.generators:
				levels[int(g.level)] = true
			assert_eq(levels.keys().size(), 3, "%s: exercises at levels 1, 2 and 3" % id)
			var types := {}
			var distinct := {}
			for stars in [0, 1, 2]:
				for s in 20:
					var round := RoundPlan.plan(c, s * 7 + stars, stars)
					assert_eq(round.size(), MasteryRules.ROUND_SIZE, "%s fills a round" % id)
					var ids := {}
					for ex in round:
						types[str(ex.type)] = true
						distinct[str(ex.prompt) + str(ex.get("picture", ""))] = true
						if not str(ex.id).begins_with("gen:"):
							assert_false(ids.has(ex.id), "%s: %s twice in a round" % [id, ex.id])
							ids[ex.id] = true
			assert_gte(types.size(), 2, "%s: at least two kinds of exercise" % id)
			assert_gte(distinct.size(), 12, "%s: varied practice" % id)


## Owner #68 ("at the end we should have full school 4-5-6-7-8 grade programs"): every science and English unit written
## for grades 5 to 8 meets grade 4's bar: a lesson of 3 or more cards, at least 10 hand-written exercises at levels 1, 2
## and 3, two kinds of exercise, and rounds that vary.
func test_every_later_science_and_english_unit_meets_the_bar() -> void:
	var checked := 0
	for g in [5, 6, 7, 8]:
		for subject: String in ["science", "english"]:
			for u: Dictionary in Curriculum.units(g, subject):
				var id := str(u.id)
				if not Curriculum.has_content(id):
					continue
				checked += 1
				var c := Curriculum.content(id)
				assert_between((c.lesson as Array).size(), 3, Curriculum.MAX_CARDS, "%s: a lesson of 3 or more cards" % id)
				assert_gte((c.exercises as Array).size(), 10, "%s: at least 10 hand-written exercises" % id)
				var levels := {}
				var types := {}
				for ex: Dictionary in c.exercises:
					levels[int(ex.level)] = true
					types[str(ex.type)] = true
				assert_eq(levels.keys().size(), 3, "%s: exercises at levels 1, 2 and 3" % id)
				assert_gte(types.size(), 2, "%s: at least two kinds of exercise" % id)
				var distinct := {}
				for stars in [0, 1, 2]:
					for s in 12:
						for ex in RoundPlan.plan(c, s * 7 + stars, stars):
							distinct[str(ex.prompt)] = true
				assert_gte(distinct.size(), 12, "%s: varied practice" % id)
	assert_gte(checked, 25, "grade 5's science and English at least")


## Owner #68: every maths unit written for grades 6 to 8 meets grade 5's bar (test_school_content_g5.gd): a lesson of 3
## or more cards, at least 8 hand-written exercises, something at every level, two kinds of exercise, and rounds that
## vary (the generators give endless practice).
func test_every_later_maths_unit_meets_the_bar() -> void:
	for g in [6, 7, 8]:
		for u: Dictionary in Curriculum.units(g, "maths"):
			var id := str(u.id)
			if not Curriculum.has_content(id):
				continue
			var c := Curriculum.content(id)
			assert_between((c.lesson as Array).size(), 3, Curriculum.MAX_CARDS, "%s: a lesson of 3 or more cards" % id)
			assert_gte((c.exercises as Array).size(), 8, "%s: 8 or more hand-written exercises" % id)
			var levels := {}
			for ex: Dictionary in c.exercises:
				levels[int(ex.level)] = true
			for gen: Dictionary in c.generators:
				levels[int(gen.level)] = true
			assert_eq(levels.keys().size(), 3, "%s: something at every level" % id)
			var types := {}
			var distinct := {}
			for stars in [0, 1, 2]:
				for s in 20:
					for ex in RoundPlan.plan(c, s * 7 + stars, stars):
						types[str(ex.type)] = true
						distinct[str(ex.prompt) + str(ex.get("picture", ""))] = true
			assert_gte(types.size(), 2, "%s: at least two kinds of exercise" % id)
			assert_gte(distinct.size(), 25, "%s: varied practice" % id)


## Owner #68 (2026-09-28): grades 4 to 8, maths, science and English: all 201 units of the first outline are written.
## Owner #70/#73 (2026-09-29): the research's programme adds units and subjects, written next. So: every unit that names
## its file is written, and no grade's subject ever has fewer written units than on 2026-09-28 (201 in all).
const WRITTEN_2026_09_28 := {4: {"maths": 17, "science": 12, "english": 13}, 5: {"maths": 16, "science": 13, "english": 12},
	6: {"maths": 17, "science": 11, "english": 12}, 7: {"maths": 15, "science": 12, "english": 12},
	8: {"maths": 16, "science": 11, "english": 12}}


func test_the_school_keeps_every_written_unit() -> void:
	var total := 0
	for g: int in WRITTEN_2026_09_28:
		for subject: String in WRITTEN_2026_09_28[g]:
			var written := 0
			for u: Dictionary in Curriculum.units(g, subject):
				if u.has("file"):
					assert_true(Curriculum.has_content(str(u.id)), "%s is written" % u.id)
				if Curriculum.has_content(str(u.id)):
					written += 1
			assert_gte(written, int(WRITTEN_2026_09_28[g][subject]), "grade %d %s" % [g, subject])
			total += written
	assert_gte(total, 201, "the first outline's 201 units")
	for g in Curriculum.grades():   # any grade, any subject: a unit that names its file is written
		for s: Dictionary in Curriculum.subjects(g):
			for u: Dictionary in Curriculum.units(g, str(s.id)):
				if u.has("file"):
					assert_true(Curriculum.has_content(str(u.id)), "%s is written" % u.id)


func test_grade_4_science_and_english_have_their_first_units() -> void:
	for id: String in ["g4.science.rock_layers", "g4.english.story_characters", "g4.english.sound_alike"]:
		assert_true(Curriculum.has_content(id), id)
		if Curriculum.has_content(id):
			assert_gte((Curriculum.content(id).exercises as Array).size(), 10, "%s: enough practice" % id)


# --- Words -------------------------------------------------------------------------------------------------------

## Owner #70 (2026-09-29, the lead's review): a lesson once said 346 + 278 = 724. Every plain sum a lesson card, a
## prompt, a hint or a worked answer states ("a + b = c", "−", "×", "÷") is right, except where the text means it to be
## checked: a false TRUE/FALSE claim, someone's claim ("Bram says …", a question), a remainder (a long division's step: "55 ÷ 23 = 2 (46), 9 left"), a
## percentage or a count of tens.
func test_the_sums_in_the_lessons_are_right() -> void:
	var num := "(?<![\\d/.,])(\\d{1,3}(?:,\\d{3})+|\\d+(?:\\.\\d+)?)(?![\\d/])"
	var sum := RegEx.create_from_string(num + "\\s*([+−×÷-])\\s*" + num + "\\s*=\\s*" + num)
	var checked := 0
	var wrong: Array[String] = []
	for id in _written():
		var c := Curriculum.content(id)
		var texts: Array[String] = []
		for card: Dictionary in c.lesson:
			texts.append(str(card.get("text", "")))
		for ex: Dictionary in c.exercises:
			if not (str(ex.type) == "truefalse" and ex.answer == false):
				texts.append(str(ex.get("prompt", "")))
			texts.append(str(ex.get("hint", "")))
			texts.append(str(ex.get("explain", "")))
		for t in texts:
			for m in sum.search_all(t):
				var before := t.substr(0, m.get_start()).strip_edges()
				var after := t.substr(m.get_end(), 24).strip_edges()
				var sentence := t.substr(maxi(t.rfind(".", m.get_start()), 0), m.get_end() - maxi(t.rfind(".", m.get_start()), 0) + 40)
				if before.ends_with("+") or before.ends_with("−") or before.ends_with("×") or before.ends_with("÷") \
						or before.ends_with("(") or after.begins_with("+") or after.begins_with("−") \
						or after.begins_with("×") or after.begins_with("÷") or after.begins_with("remainder") \
						or after.begins_with("r ") or after.begins_with("%") or after.begins_with("tens") \
						or (op_of(m) == "÷" and after.contains("left")) \
						or after.begins_with("hundreds") or after.begins_with("1/") or after.begins_with("2/") \
						or after.begins_with("3/") or sentence.contains("says") or sentence.contains("?"):
					continue
				var a_ := float(m.get_string(1).replace(",", ""))
				var b_ := float(m.get_string(3).replace(",", ""))
				var c_ := float(m.get_string(4).replace(",", ""))
				var op := m.get_string(2)
				var r := a_ + b_ if op == "+" else a_ - b_ if op in ["−", "-"] else a_ * b_ if op == "×" \
					else (a_ / b_ if b_ != 0.0 else INF)
				checked += 1
				if absf(r - c_) > 0.0001:
					wrong.append("%s: %s" % [id, m.get_string()])
	assert_eq(wrong, [] as Array[String], "every sum a lesson states is right")
	assert_gt(checked, 200, "the lessons' sums were found")


## A sum's operator (test_the_sums_in_the_lessons_are_right).
func op_of(m: RegExMatch) -> String:
	return m.get_string(2)


func test_the_words_are_kind_and_our_own() -> void:
	var found: Array[String] = []
	for t in _all_texts():
		var lower := t.to_lower()
		for w in UNKIND + OTHER_GAMES:
			if RegEx.create_from_string("\\b" + w + "\\b").search(lower):
				found.append("'%s' in: %s" % [w, t])
	assert_eq(found, [] as Array[String], "\n".join(found))


func test_british_spelling() -> void:
	var found: Array[String] = []
	for t in _all_texts():
		var lower := t.to_lower()
		for w in US_SPELLINGS:
			if RegEx.create_from_string("\\b" + w + "\\b").search(lower):
				found.append("'%s' in: %s" % [w, t])
	assert_eq(found, [] as Array[String], "\n".join(found))


func test_english_letters_and_the_fonts_symbols_only() -> void:
	var found: Array[String] = []
	for t in _all_texts():
		for ch in t:
			if ch.unicode_at(0) > 127 and not ALLOWED.contains(ch):
				found.append("'%s' in: %s" % [ch, t])
				break
	assert_eq(found, [] as Array[String], "\n".join(found))
