extends GutTest
## Owner #85 (Wordle's lesson; the world game plan §2b; brief 2026-09-30 item 1): the Daily Mission. One short challenge
## a day, the same for every player of a grade (seeded by the UTC date and the grade): 5 exercises from that grade's
## generators across subjects (a unit with no generator gives one of its own exercises), easy to harder. Its card says
## the date, the grade and the stars, never the answers, and carries the invite link. Nothing pushes.

const PRESSURE: Array[String] = ["hurry", "or else", "last chance", "lose", "only today", "don't miss", "must", "streak",
	"before it's gone", "miss out", "expires"]

var day := 0


func before_all() -> void:
	day = DailyMission.day_of(Time.get_unix_time_from_datetime_string("2026-09-30T09:00:00"))


func after_all() -> void:
	Curriculum.clear_cache()


func test_a_day_is_a_utc_day_with_its_date() -> void:
	var midnight := Time.get_unix_time_from_datetime_string("2026-09-30T00:00:00")
	assert_eq(DailyMission.day_of(midnight), day)
	assert_eq(DailyMission.day_of(midnight + 86399), day, "the whole UTC day")
	assert_eq(DailyMission.day_of(midnight - 1), day - 1)
	assert_eq(DailyMission.date_key(day), "2026-09-30")
	assert_eq(DailyMission.date_words(day), "30 September 2026")
	assert_eq(DailyMission.date_words(day + 1), "1 October 2026")


func test_five_exercises_across_the_grades_subjects_easy_to_harder() -> void:
	var p := DailyMission.plan(day, 4)
	assert_eq(p.size(), DailyMission.SIZE)
	var subjects := {}
	for i in p.size():
		var ex: Dictionary = p[i]
		assert_eq(ExerciseCheck.problem(ex), "", "exercise %d is a real one: %s" % [i, ex.get("id", "")])
		var unit := str(ex.get("daily_unit", ""))
		assert_true(unit.begins_with("g4."), "grade 4's own unit: %s" % unit)
		assert_false(SpendRules.is_bonus(Curriculum.unit(unit)), "never an Explorer lesson a child must buy")
		assert_eq(str(ex.get("daily_subject", "")), unit.split(".")[1])
		subjects[ex.daily_subject] = true
		if str(ex.id).begins_with("gen:"):   # a generator makes any level; a unit's own exercise keeps its own
			assert_eq(int(ex.get("level", 0)), DailyMission.LEVELS[i], "easy to harder")
	assert_eq(subjects.size(), DailyMission.SIZE, "five different subjects in a grade that has them")


func test_the_same_mission_for_every_player_of_a_grade() -> void:
	var a := _ids(DailyMission.plan(day, 5))
	Curriculum.clear_cache()   # another phone: nothing cached
	var b := _ids(DailyMission.plan(day, 5))
	assert_eq(a, b, "the same date and grade: the same mission")
	assert_eq(_prompts(DailyMission.plan(day, 5)), _prompts(DailyMission.plan(day, 5)), "the same questions, word for word")
	assert_ne(_ids(DailyMission.plan(day + 1, 5)), a, "tomorrow: a new one")
	assert_ne(_ids(DailyMission.plan(day, 4)), a, "another grade: its own")


func test_generators_first_and_a_units_own_exercises_where_it_has_none() -> void:
	var from_gen := 0
	for d in 20:
		for ex: Dictionary in DailyMission.plan(day + d, 4):
			var content := Curriculum.content(str(ex.daily_unit))
			var has_gen := false
			for g: Dictionary in content.generators:
				has_gen = has_gen or SchoolGen.exists(str(g.gen))
			if has_gen:
				assert_true(str(ex.id).begins_with("gen:"), "%s has generators: %s" % [ex.daily_unit, ex.id])
				from_gen += 1
			else:
				assert_true(str(ex.id).begins_with(str(ex.daily_unit) + "#"), "its own exercise: %s" % ex.id)
	assert_gt(from_gen, 50, "mostly generated")


func test_every_grade_has_a_full_mission_every_day_of_a_month() -> void:
	for g in SchoolData.GRADES:
		var seen := {}
		for d in 30:
			var p := DailyMission.plan(day + d, g)
			assert_eq(p.size(), DailyMission.SIZE, "grade %d day %d" % [g, d])
			for ex: Dictionary in p:
				assert_eq(ExerciseCheck.problem(ex), "", "grade %d: %s" % [g, ex.get("id", "")])
				seen[ex.daily_subject] = true
		assert_gte(seen.size(), mini(DailyMission.subjects(g).size(), DailyMission.SIZE), "grade %d: across subjects" % g)


## Grade 8 had only its three core subjects when this was written; it has more now (its humanities, 2026-10-17), so the
## test makes its own three-subject grade 8 from the real outline (Curriculum.put_grade) and puts the real one back.
func test_a_grade_with_three_subjects_still_gets_five_questions() -> void:
	var outline: Dictionary = Curriculum.grade(8).duplicate(true)
	var core: Array[String] = ["maths", "science", "english"]
	outline.subjects = (outline.subjects as Array).filter(func(s: Dictionary) -> bool: return core.has(str(s.id)))
	Curriculum.put_grade(8, outline)
	var subs := DailyMission.subjects(8)
	assert_eq(subs, ["maths", "science", "english"] as Array[String], "a grade of three subjects")
	var p := DailyMission.plan(day, 8)
	assert_eq(p.size(), DailyMission.SIZE)
	var seen := {}
	for ex: Dictionary in p:
		seen[ex.daily_subject] = true
	assert_eq(seen.size(), 3, "each of them")
	Curriculum.clear_cache()


func test_the_card_shows_the_stars_never_the_answers_and_carries_the_invite_link() -> void:
	assert_eq(DailyMission.score_words(4), "Today's Mission: 4 of 5!")
	assert_eq(DailyMission.stars_in("10111"), 4)
	assert_eq(DailyMission.stars_in(""), 0)
	var text := DailyMission.share_text(day, 4, "10111", "BLUE-OTTER-42")
	assert_string_contains(text, "30 September 2026")
	assert_string_contains(text, "grade 4")
	assert_string_contains(text, "Today's Mission: 4 of 5!")
	assert_string_contains(text, "BLUE-OTTER-42")
	assert_string_contains(text, InviteRules.link("BLUE-OTTER-42"))
	assert_string_contains(text, DailyMission.share_stars("10111"))
	for ex: Dictionary in DailyMission.plan(day, 4):
		assert_false(text.contains(str(ex.get("prompt", "")).substr(0, 20)), "no question in the card")
	var no_code := DailyMission.share_text(day, 4, "11111", "")
	assert_string_contains(no_code, InviteRules.PLAY_URL, "no code yet: the game's own link")
	assert_eq(DailyMission.link(""), InviteRules.PLAY_URL)
	assert_eq(DailyMission.link("BLUE-OTTER-42"), InviteRules.link("BLUE-OTTER-42"))


func test_the_words_are_calm() -> void:
	var lines: Array[String] = [DailyMission.intro_words(4), DailyMission.GROWN_UPS_LINE, DailyMission.REST_LINE,
		DailyMission.DONE_LINE, DailyMission.days_words(1), DailyMission.days_words(12), DailyMission.score_words(0),
		DailyMission.score_words(5), DailyMission.praise(0), DailyMission.praise(3), DailyMission.praise(5)]
	for w in lines:
		assert_ne(w, "")
		for p in PRESSURE:
			assert_false(w.to_lower().contains(p), "no pressure (%s): %s" % [p, w])
	assert_eq(DailyMission.days_words(1), "1 mission day")
	assert_eq(DailyMission.days_words(12), "12 mission days")


func _ids(p: Array[Dictionary]) -> Array:
	return p.map(func(ex: Dictionary) -> String: return str(ex.get("id", "")))


func _prompts(p: Array[Dictionary]) -> Array:
	return p.map(func(ex: Dictionary) -> String: return str(ex.get("prompt", "")))
