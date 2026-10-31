extends GutTest
## Owner #68 (spec §22.4, §22.5): the curriculum is data: data/school/grade<N>.json for grades 4-8 (subjects → units with
## their standards and goals) and one file per written unit. The outline is complete for every grade and subject.


func after_each() -> void:
	Curriculum.clear_cache()


## Owner #70 (2026-09-29): "start from grade 3 and finish all grades acordingly".
func test_grades_3_to_8_each_with_the_core_subjects_first() -> void:
	assert_eq(Curriculum.grades(), [3, 4, 5, 6, 7, 8] as Array[int])
	for g in Curriculum.grades():
		var ids: Array[String] = []
		for s: Dictionary in Curriculum.subjects(g):
			ids.append(str(s.id))
		assert_eq(ids.slice(0, 3), ["maths", "science", "english"] as Array[String], "grade %d" % g)


func test_a_grade_lists_known_subjects_in_tab_order_with_the_core_three() -> void:
	var grade: Dictionary = Curriculum.grade(4).duplicate(true)
	grade.subjects = (grade.subjects as Array).slice(0, 3)   # maths, science, English
	var history: Dictionary = (grade.subjects[0] as Dictionary).duplicate(true)
	history.id = "history"
	for u: Dictionary in history.units:
		u.id = str(u.id).replace(".maths.", ".history.")
		u.erase("file")
	grade.subjects.append(history)
	Curriculum.put_grade(4, grade)
	assert_eq(Curriculum.outline_problems(4), [] as Array[String], "a grade may add any school subject")
	var odd: Dictionary = grade.duplicate(true)
	odd.subjects.reverse()
	Curriculum.put_grade(4, odd)
	assert_ne(Curriculum.outline_problems(4), [] as Array[String], "subjects out of the tabs' order")
	var strange: Dictionary = grade.duplicate(true)
	strange.subjects[3].id = "cooking"
	Curriculum.put_grade(4, strange)
	assert_ne(Curriculum.outline_problems(4), [] as Array[String], "a subject the School has no tab for")
	var thin: Dictionary = grade.duplicate(true)
	thin.subjects.remove_at(1)
	Curriculum.put_grade(4, thin)
	assert_ne(Curriculum.outline_problems(4), [] as Array[String], "every grade keeps maths, science and English")


func test_the_outline_has_no_problems() -> void:
	for g in Curriculum.grades():
		assert_eq(Curriculum.outline_problems(g), [] as Array[String], "grade %d" % g)


func test_every_subject_has_units_with_goals_and_standards() -> void:
	var total := 0
	for g in Curriculum.grades():
		for s: Dictionary in Curriculum.subjects(g):
			var units := Curriculum.units(g, str(s.id))
			var least := 3 if s.id == "projects" else 9   # three projects a grade (the research §5.2)
			assert_between(units.size(), least, Curriculum.MAX_UNITS, "grade %d %s" % [g, s.id])
			total += units.size()
			for u: Dictionary in units:
				assert_gt((u.goals as Array).size(), 0, str(u.id))
				assert_gt((u.standards as Array).size(), 0, str(u.id))
	assert_gt(total, 240, "the whole programme of grades 3-8")


func test_unit_ids_are_unique_across_every_grade() -> void:
	var seen := {}
	for g in Curriculum.grades():
		for s: Dictionary in Curriculum.subjects(g):
			for u: Dictionary in Curriculum.units(g, str(s.id)):
				assert_false(seen.has(u.id), "%s twice" % u.id)
				seen[u.id] = true
				assert_true(SchoolData.valid_id(str(u.id)), str(u.id))


func test_a_unit_by_id() -> void:
	var u := Curriculum.unit("g4.maths.big_numbers")
	assert_eq(u.title, "Big numbers")
	assert_eq(int(u.grade), 4)
	assert_eq(u.subject, "maths")
	assert_eq(u.number, 1, "its place on the map")
	assert_eq(Curriculum.unit("g4.maths.nothing"), {})
	assert_eq(Curriculum.unit("rubbish"), {})


func test_a_missing_unit_file_reads_as_coming_soon() -> void:
	var grade: Dictionary = Curriculum.grade(4).duplicate(true)
	(grade.subjects[0].units[0] as Dictionary)["file"] = "g4/maths/no_such_file.json"
	Curriculum.put_grade(4, grade)
	assert_false(Curriculum.has_content("g4.maths.big_numbers"))
	assert_eq(Curriculum.content("g4.maths.big_numbers"), {})
	assert_ne(Curriculum.outline_problems(4), [] as Array[String], "the outline check names the missing file")


func test_a_broken_grade_file_is_an_empty_grade() -> void:
	Curriculum.put_grade(5, Curriculum.parse_grade("{ not json"))
	assert_eq(Curriculum.subjects(5), [] as Array[Dictionary])
	assert_eq(Curriculum.units(5, "maths"), [] as Array[Dictionary])


func test_tests_can_put_a_units_content() -> void:
	var id := "g5.maths.test_only_unit"   # never in the outline, so never written
	Curriculum.put_content(id, {"id": id, "lesson": [{"text": "a"}, {"text": "b"}], "exercises": [], "generators": []})
	assert_true(Curriculum.has_content(id))
	Curriculum.clear_cache()
	assert_false(Curriculum.has_content(id))


func test_written_units_get_their_exercise_ids() -> void:
	var c := Curriculum.parse_content("g4.maths.test", JSON.stringify({"id": "g4.maths.test",
		"lesson": [{"text": "One."}, {"text": "Two."}],
		"exercises": [{"type": "truefalse", "prompt": "p", "answer": true, "hint": "h"}]}))
	assert_eq(str(c.exercises[0].id), "g4.maths.test#0")
	assert_eq(Curriculum.parse_content("g4.maths.test", "[]"), {})
	assert_eq(Curriculum.parse_content("g4.maths.test", JSON.stringify({"id": "g4.maths.other", "lesson": []})), {},
		"a file for another unit")


## Owner #70: every school subject has its word and colour on the School's tabs, and grade 3 ids are valid.
func test_every_subject_has_its_tab_words_and_colour() -> void:
	for sid: String in Curriculum.SUBJECTS:
		assert_true(SchoolUi.SUBJECT_WORDS.has(sid), sid)
		assert_true(SchoolUi.SUBJECT_COLORS.has(sid), sid)
	# The research's subjects (docs/design/school-curriculum-research.md §5.2): eleven and Projects.
	for s: String in ["maths", "english", "science", "history", "geography", "citizenship", "computing", "art", "music",
			"health_pe", "design_tech", "projects"]:
		assert_true(Curriculum.SUBJECTS.has(s), s)
	assert_true(SchoolData.valid_id("g3.maths.place_value"), "grade 3")
	assert_true(SchoolData.valid_id("g3.health_pe.balance_games"), "a subject id with an underscore")
	assert_gte(SchoolData.MAX_UNITS, 2000, "progress for a School of every subject and grade")
