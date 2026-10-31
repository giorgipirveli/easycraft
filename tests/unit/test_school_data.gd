extends GutTest
## Owner #68 (spec §22.2): the School's part of the profile (ProfileData.school): the grade, a grown-up's lock and each
## unit's progress. Parsed field by field (a broken field falls back on its own), kept by merges (nothing earned lost).

const DAY := 20_000


func _data_with(id: String, right: int, day: int) -> SchoolData:
	var s := SchoolData.new()
	s.set_progress(id, MasteryRules.after_round(s.progress(id), right, 6, day).progress)
	return s


func test_a_new_school_is_empty() -> void:
	var s := SchoolData.new()
	assert_true(s.is_empty())
	assert_eq(s.grade, 0, "no grade picked yet")
	assert_false(s.grade_locked)
	assert_eq(MasteryRules.stars(s.progress("g4.maths.big_numbers")), 0)


func test_round_trip() -> void:
	var s := _data_with("g4.maths.big_numbers", 5, DAY)
	s.grade = 4
	s.grade_locked = true
	var back := SchoolData.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq(back.grade, 4)
	assert_true(back.grade_locked)
	assert_eq(back.progress("g4.maths.big_numbers"), s.progress("g4.maths.big_numbers"))
	assert_false(back.is_empty())


func test_from_dict_keeps_only_clean_units() -> void:
	var raw := {"grade": 5, "locked": "yes", "units": {
		"g4.maths.big_numbers": {"s": 2, "r": 3, "a": 18, "f": 15, "b": 83, "x": 1, "d": DAY + 3, "t": DAY, "m": DAY - 1,
			"p": true, "l": true},
		"g9.maths.x": {"s": 3},
		"G4.MATHS.BIG": {"s": 1},
		"g4.maths.stars": {"s": 7, "b": 250, "r": -4, "a": "many", "p": 1},
		"g4.science.rock_layers": "broken",
		"g13.maths.x": {"s": 1},
		"g0.maths.x": {"s": 1},
	}}
	var s := SchoolData.from_dict(raw)
	assert_eq(s.grade, 5)
	assert_false(s.grade_locked, "only a real true locks it")
	assert_eq(MasteryRules.stars(s.progress("g4.maths.big_numbers")), 2)
	assert_true(bool(s.progress("g4.maths.big_numbers").p))
	assert_false(s.units.has("g13.maths.x") or s.units.has("g0.maths.x"), "school grades are 1 to 12")
	assert_false(s.units.has("G4.MATHS.BIG"), "ids are lower case")
	var clamped := s.progress("g4.maths.stars")
	assert_eq(int(clamped.s), 3, "stars at most 3")
	assert_eq(int(clamped.b), 100, "best at most 100 %")
	assert_eq(int(clamped.r), 0)
	assert_eq(int(clamped.a), 0)
	assert_false(bool(clamped.p), "paid only when true")
	assert_false(s.units.has("g4.science.rock_layers"))


func test_a_future_field_is_ignored() -> void:
	var s := SchoolData.from_dict({"grade": 4, "units": {}, "sparkles": [1, 2]})
	assert_eq(s.grade, 4)
	assert_eq(SchoolData.from_dict("nonsense").grade, 0)
	assert_eq(SchoolData.from_dict({"grade": 11}).grade, 0, "grades 4-8 only")
	assert_eq(SchoolData.from_dict({"grade": 6.5}).grade, 0)


func test_merge_keeps_the_best_of_both() -> void:
	var mine := _data_with("g4.maths.big_numbers", 2, DAY)
	var theirs := _data_with("g4.maths.big_numbers", 6, DAY + 2)
	theirs.set_progress("g4.maths.divide", MasteryRules.lesson_read(theirs.progress("g4.maths.divide")))
	theirs.grade = 4
	theirs.grade_locked = true
	mine.merge_from(theirs)
	var p := mine.progress("g4.maths.big_numbers")
	assert_eq(MasteryRules.stars(p), 2, "their mastery")
	assert_true(bool(p.p), "their paid reward stays paid")
	assert_eq(int(p.r), 1)
	assert_eq(int(p.t), DAY + 2)
	assert_true(bool(mine.progress("g4.maths.divide").l), "their lesson")
	assert_eq(mine.grade, 4, "a grade when this copy had none")
	assert_true(mine.grade_locked, "a grown-up's lock is kept")


func test_merge_never_takes_a_grade_this_copy_chose() -> void:
	var mine := SchoolData.new()
	mine.grade = 6
	var theirs := SchoolData.new()
	theirs.grade = 4
	mine.merge_from(theirs)
	assert_eq(mine.grade, 6)


func test_the_profile_keeps_the_school() -> void:
	var p := ProfileData.new()
	p.school = _data_with("g4.maths.patterns", 5, DAY)
	p.school.grade = 4
	var back := ProfileData.from_json(p.to_json())
	assert_eq(back.school.grade, 4)
	assert_eq(MasteryRules.stars(back.school.progress("g4.maths.patterns")), 2)
	assert_true(ProfileData.from_json("{}").school.is_empty(), "an old profile has an empty school")


func test_a_small_profile_even_with_every_unit_practised() -> void:
	var s := SchoolData.new()
	for g in range(4, 9):
		for i in 40:
			s.set_progress("g%d.maths.unit_%d" % [g, i], MasteryRules.after_round(s.progress("g4.maths.x"), 5, 6, DAY).progress)
	assert_lt(JSON.stringify(s.to_dict()).length(), 24_000, "the backup stays well under its 60 KiB")
