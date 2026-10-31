extends GutTest
## Owner #68 (spec §22.1-22.3): the School's pages. The first visit asks the grade; the map shows the grade's units per
## subject with their stars; a unit has its goals, PLAY and THE BOOK (owner #122, G0: never LESSON then PRACTICE; the
## new flow's own tests: test_play_screen.gd); the Book is cards; a round is 6 exercises (the old panel's round, kept
## for these tests of its rules) and its end shows the score, the stars and, the first time a unit is mastered, its
## gold (once). Leaving a round early
## records nothing. Grown-ups choose and fix the grade behind the parent gate and see every unit's progress. Every page
## fits the School's frame. The screen works on its own profile, save hook, day and seed (tests never touch the real
## profile).

const UNIT := "g4.maths.big_numbers"
const DAY := 20_000
const CONTENT := {"id": UNIT, "lesson": [
		{"text": "A digit's place tells what it is worth.", "picture": {"kind": "blocks", "hundreds": 3, "tens": 4, "ones": 7}},
		{"text": "Each place is worth ten times the place to its right."},
		{"text": "We read big numbers in groups of three."}],
	"exercises": [
		{"type": "truefalse", "prompt": "In 347, the 4 is worth 40.", "answer": true, "hint": "Tens place.", "level": 1},
		{"type": "number", "prompt": "300 + 40 + 7 = ?", "answer": "347", "hint": "Put the parts together.", "level": 2},
		{"type": "choice", "prompt": "Which is 3,000 + 20 + 5?", "choices": ["3,025", "3,205", "325"], "answer": 0,
			"hint": "No hundreds.", "level": 3},
		{"type": "order", "prompt": "Smallest first.", "items": ["4,210", "4,021", "4,201"], "answer": [1, 2, 0],
			"hint": "Look at the hundreds.", "level": 2},
		{"type": "build", "prompt": "Build 2 rows of 3.", "board": {"cols": 6, "rows": 3, "block": 9, "given": []},
			"goal": {"kind": "array", "rows": 2, "cols": 3}, "hint": "A row of 3 first.", "level": 1}],
	"generators": [{"gen": "g4m.digit_value", "level": 1}, {"gen": "g4m.digit_value", "level": 3}]}

var profile: ProfileData
var saves := 0
var screen: SchoolScreen


func before_each() -> void:
	ParentGate.reset_tries()
	Curriculum.clear_cache()
	Curriculum.put_content(UNIT, CONTENT)
	profile = ProfileData.new()
	saves = 0


func after_each() -> void:
	Curriculum.clear_cache()


func after_all() -> void:
	Audio.stop_all()


func _open(grade: int = 4) -> SchoolScreen:
	profile.school.grade = grade
	screen = SchoolScreen.new()
	screen.profile = profile
	screen.save_profile = func() -> void: saves += 1
	screen.today = func() -> int: return DAY
	screen.next_seed = func() -> int: return 7
	add_child_autofree(screen)
	await wait_process_frames(2)
	return screen


func _button(text: String) -> Button:
	for b in screen.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b
	return null


func _labels() -> Array[String]:
	var out: Array[String] = []
	for l in screen.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out.append((l as Label).text)
	return out


## Answers the round's current exercise right (or wrong once and then right: first time false).
func _answer(right_first: bool) -> void:
	var p := screen.exercise_panel
	var ex := p.ex
	var w := p.answer_widget
	if not right_first:
		_respond(w, ex, false)
		p.check()
	_respond(w, ex, true)
	p.check()
	p.next_button.pressed.emit()
	await wait_process_frames(1)


func _respond(w: Control, ex: Dictionary, right: bool) -> void:
	var a: Variant = ExerciseCheck.answer_of(ex)
	match str(ex.type):
		"choice":
			var n := (ex.choices as Array).size()
			(w as ChoiceAnswer).choose(int(a) if right else (int(a) + 1) % n)
		"truefalse":
			(w as ChoiceAnswer).choose((0 if a else 1) if right else (1 if a else 0))
		"number":
			var pad := w as NumberAnswerPad
			while pad.typed != "":
				pad.press(NumberPad.DELETE)
			for ch in (str(a) if right else str(a) + "1"):
				pad.press(ch)
		"order":
			var o := w as OrderAnswer
			o.clear()
			var seq: Array = a if right else [a[1], a[0]] + (a as Array).slice(2)
			for i: int in seq:
				o.tap(i)
		"build":
			var b := w as BuildBoard
			b.clear()
			var cells: Array = a if right else [Vector2i(5, 2)]
			for c: Vector2i in cells:
				b.paint(c, true)


# --- First visit and grades ---

func test_the_first_visit_asks_the_grade() -> void:
	await _open(0)
	assert_eq(screen.page, SchoolScreen.WELCOME)
	assert_has(_labels(), SchoolScreen.HELLO_WORDS, "owner #122: DISCOVER's hello")
	for g in range(4, 9):
		assert_not_null(_button("GRADE %d" % g), "grade %d" % g)
	_button("GRADE 4").pressed.emit()
	await wait_process_frames(1)
	assert_eq(profile.school.grade, 4)
	assert_eq(saves, 1)
	assert_eq(screen.page, SchoolScreen.MAP)


func test_a_grade_a_grown_up_fixed_cannot_be_changed_by_the_child() -> void:
	profile.school.grade_locked = true
	await _open(5)
	screen.show_grades()
	await wait_process_frames(1)
	assert_true(_button("GRADE 4").disabled)
	assert_true(_labels().any(func(t: String) -> bool: return t.contains("A grown-up chose grade 5")))


# --- The map ---

func test_the_map_shows_every_unit_of_the_subject() -> void:
	await _open()
	assert_eq(screen.page, SchoolScreen.MAP)
	assert_eq(screen.stops.size(), Curriculum.units(4, "maths").size())
	_button("SCIENCE").pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.subject, "science")
	assert_eq(screen.stops.size(), Curriculum.units(4, "science").size())


func test_a_stop_shows_its_stars_and_a_review_leaf_when_one_is_due() -> void:
	var p: Dictionary = MasteryRules.after_round(profile.school.progress(UNIT), 6, 6, DAY - 1).progress
	profile.school.set_progress(UNIT, p)
	await _open()
	var stop: UnitStop = screen.stops[0]
	assert_eq(stop.unit_id, UNIT)
	assert_eq(stop.stars, 2)
	assert_true(stop.review, "mastered yesterday: a review would help today")
	assert_true(stop.written)


# --- A unit ---

func test_a_unit_shows_its_goals_play_and_the_book() -> void:
	await _open()
	screen.show_unit(UNIT)
	await wait_process_frames(1)
	var labels := _labels()
	for goal: String in Curriculum.unit(UNIT).goals:
		assert_true(labels.any(func(t: String) -> bool: return t.contains(goal)), goal)
	assert_true(labels.any(func(t: String) -> bool: return t.contains("4.NBT.1")), "its standards, for grown-ups")
	assert_not_null(_button(SchoolScreen.PLAY_WORDS), "owner #122: PLAY first")
	assert_not_null(_button(SchoolScreen.BOOK_WORDS), "the Book, as a small choice")
	assert_null(_button("LESSON"))
	assert_null(_button("PRACTICE"))


func test_a_unit_not_written_yet_says_coming_soon() -> void:
	var unwritten := _unwritten()   # the School is written grade by grade (owner #68)
	if unwritten.is_empty():
		pass_test("every unit is written")
		return
	await _open(int(unwritten[0]))
	screen.show_unit(str(unwritten[1]))
	await wait_process_frames(1)
	assert_has(_labels(), SchoolWords.COMING_SOON)
	assert_null(_button(SchoolScreen.PLAY_WORDS))
	assert_null(_button(SchoolScreen.BOOK_WORDS))


## [grade, unit id] of the first unit with no content yet, or [] when every unit is written.
func _unwritten() -> Array:
	for g in Curriculum.grades():
		for subject: Dictionary in Curriculum.subjects(g):
			for u: Dictionary in Curriculum.units(g, str(subject.id)):
				if not Curriculum.has_content(str(u.id)):
					return [g, str(u.id)]
	return []


func test_practice_says_review_when_one_is_due() -> void:
	profile.school.set_progress(UNIT, MasteryRules.after_round(profile.school.progress(UNIT), 6, 6, DAY - 3).progress)
	await _open()
	screen.show_unit(UNIT)
	await wait_process_frames(1)
	assert_not_null(_button(SchoolScreen.REVIEW_WORDS), "owner #122: come back: the same game, new challenges")


# --- The lesson ---

## Owner #122: the lesson's cards are the Book (on request); its end plays (it never goes to the old round).
func test_the_book_card_by_card_then_play() -> void:
	await _open()
	screen.show_lesson(UNIT)
	await wait_process_frames(1)
	assert_eq(screen.page, SchoolScreen.LESSON)
	assert_has(_labels(), "A digit's place tells what it is worth.")
	_button("NEXT").pressed.emit()
	_button("NEXT").pressed.emit()
	await wait_process_frames(1)
	assert_has(_labels(), "We read big numbers in groups of three.")
	assert_true(bool(profile.school.progress(UNIT).l), "read to the end")
	assert_eq(MasteryRules.stars(profile.school.progress(UNIT)), 0, "no star for reading")
	_button(SchoolScreen.BOOK_PLAY_WORDS).pressed.emit()
	await wait_process_frames(2)
	assert_eq(screen.page, SchoolScreen.PLAY)
	screen.play_host.close()


# --- A round ---

func test_a_round_of_six_then_its_end_with_the_gold_once() -> void:
	var gold := profile.survivor_gold
	await _open()
	screen.show_round(UNIT)
	await wait_process_frames(1)
	assert_eq(screen.round.size(), MasteryRules.ROUND_SIZE)
	for i in 6:
		await _answer(i != 3)   # 5 of 6 right the first time
	assert_eq(screen.page, SchoolScreen.ROUND_END)
	assert_has(_labels(), "5 of 6 right the first time!")
	assert_eq(MasteryRules.stars(profile.school.progress(UNIT)), 2, "mastered")
	assert_eq(profile.survivor_gold, gold + MasteryRules.UNIT_GOLD + 5 * EarnRules.ANSWER_GOLD, "the unit, and 5 answers (#79)")
	assert_gt(saves, 0)
	_button("PRACTISE AGAIN").pressed.emit()
	await wait_process_frames(1)
	for i in 6:
		await _answer(true)
	assert_eq(profile.survivor_gold, gold + MasteryRules.UNIT_GOLD + 11 * EarnRules.ANSWER_GOLD,
		"the unit's gold is paid once (answers right the first time pay each round: EarnRules, owner #79)")


func test_a_weaker_round_gives_the_first_star_and_no_gold() -> void:
	var gold := profile.survivor_gold
	await _open()
	screen.show_round(UNIT)
	await wait_process_frames(1)
	for i in 6:
		await _answer(i % 2 == 0)
	assert_eq(MasteryRules.stars(profile.school.progress(UNIT)), 1)
	assert_eq(profile.survivor_gold, gold + 3 * EarnRules.ANSWER_GOLD, "no unit gold; the 3 first-try answers pay (#79)")
	assert_has(_labels(), "3 of 6 right the first time.")


func test_leaving_a_round_early_records_nothing() -> void:
	await _open()
	screen.show_round(UNIT)
	await wait_process_frames(1)
	await _answer(true)
	_button("STOP").pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.page, SchoolScreen.UNIT)
	assert_eq(profile.school.progress(UNIT), SchoolData.new().progress(UNIT))


# --- Grown-ups ---

func test_grown_ups_are_behind_the_parent_gate() -> void:
	await _open()
	_button("GROWN-UPS").pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.page, SchoolScreen.GATE)
	var gate: GrownUpGate = screen.find_children("*", "GrownUpGate", true, false)[0]
	gate.passed.emit()
	await wait_process_frames(1)
	assert_eq(screen.page, SchoolScreen.GROWN_UPS)
	var page: SchoolGrownUpsPage = screen.find_children("*", "SchoolGrownUpsPage", true, false)[0]
	page.set_grade(6)
	page.set_locked(true)
	assert_eq(profile.school.grade, 6)
	assert_true(profile.school.grade_locked)
	assert_gt(saves, 1)


func test_the_grown_ups_page_lists_every_unit_with_its_progress() -> void:
	profile.school.set_progress(UNIT, MasteryRules.after_round(profile.school.progress(UNIT), 5, 6, DAY).progress)
	await _open()
	screen.show_grown_ups_page()
	await wait_process_frames(1)
	var page: SchoolGrownUpsPage = screen.find_children("*", "SchoolGrownUpsPage", true, false)[0]
	assert_eq(page.rows.size(), Curriculum.units(4, "maths").size())
	var labels := _labels()
	assert_true(labels.any(func(t: String) -> bool: return t.contains("1 round") and t.contains("83%")), str(labels))
	assert_true(labels.any(func(t: String) -> bool: return t.contains("Common Core")), "what the lessons follow")


## The grade 6 agent's list (research §5.4: hard history with respect, listed for grown-ups): a unit whose outline has
## `hard` words is marked on the grown-ups' page, and the page says what those units name ("told with respect, never
## shown"). A subject with none says nothing more.
func test_the_grown_ups_page_names_the_hard_history() -> void:
	await _open()
	screen.show_grown_ups_page()
	await wait_process_frames(1)
	var page: SchoolGrownUpsPage = screen.find_children("*", "SchoolGrownUpsPage", true, false)[0]
	page.set_grade(6)
	page.show_subject("history")
	await wait_process_frames(1)
	assert_not_null(page.hard_note, "a note for grown-ups")
	assert_true(page.hard_note.visible)
	assert_string_contains(page.hard_note.text, "the Spanish conquest")
	assert_string_contains(page.hard_note.text, "never shown")
	page.show_subject("maths")
	await wait_process_frames(1)
	assert_false(page.hard_note.visible, "maths has none")
	for u: Dictionary in Curriculum.units(6, "history"):
		var h: Variant = u.get("hard")
		assert_true(h == null or (h is String and str(h).length() <= 60), "%s: a short note" % u.id)


# --- Fit and read-aloud ---

func test_every_page_fits_the_frame_and_has_a_speaker() -> void:
	await _open()
	var pages := {
		"welcome": func() -> void: screen.show_welcome(),
		"grades": func() -> void: screen.show_grades(),
		"map maths": func() -> void: screen.show_map("maths"),
		"map english": func() -> void: screen.show_map("english"),
		"unit": func() -> void: screen.show_unit(UNIT),
		"coming soon": func() -> void: screen.show_unit("g4.science.waves"),
		"lesson": func() -> void: screen.show_lesson(UNIT),
		"round": func() -> void: screen.show_round(UNIT),
		"gate": func() -> void: screen.show_grown_ups(),
		"grown-ups": func() -> void: screen.show_grown_ups_page(),
	}
	for name: String in pages:
		(pages[name] as Callable).call()
		await wait_process_frames(2)
		var size := screen.get_combined_minimum_size()
		assert_lte(size.x, SchoolUi.FRAME.x, "%s is %s" % [name, size])
		assert_lte(size.y, SchoolUi.FRAME.y, "%s is %s" % [name, size])
		if name != "gate":
			assert_gt(screen.find_children("ReadAloud", "", true, false).size(), 0, "%s has a speaker" % name)
	screen.show_round(UNIT)
	await wait_process_frames(1)
	for i in 6:
		await _answer(true)
	var end := screen.get_combined_minimum_size()
	assert_lte(end.y, SchoolUi.FRAME.y, "the round's end is %s" % end)


func test_every_units_stop_fits_its_card_in_every_grade() -> void:
	for g in Curriculum.grades():
		for s: Dictionary in Curriculum.subjects(g):
			for u: Dictionary in Curriculum.units(g, str(s.id)):
				var stop := UnitStop.new(Curriculum.unit(str(u.id)), {}, DAY, UiKit.BLUE)
				add_child_autofree(stop)
				var body: Control = stop.get_child(0)
				var need := body.get_combined_minimum_size().y + stop.body_top() + 6.0
				assert_lte(need, UnitStop.SIZE.y, "%s \"%s\" needs %d px" % [u.id, u.title, need])


## Owner #70 (2026-09-29): every school subject. A grade with all of them shows a tab for each, and its map still fits.
func test_a_grade_with_every_subject_shows_a_tab_for_each_and_fits() -> void:
	var g: Dictionary = Curriculum.grade(4).duplicate(true)
	var maths: Dictionary = g.subjects[0]
	var subjects: Array = []
	for sid: String in Curriculum.SUBJECTS:
		var found: Array = (g.subjects as Array).filter(func(s: Dictionary) -> bool: return s.id == sid)
		if not found.is_empty():
			subjects.append(found[0])
			continue
		var copy: Dictionary = maths.duplicate(true)
		copy.id = sid
		copy.title = sid.capitalize()
		for u: Dictionary in copy.units:
			u.id = "g4.%s.%s" % [sid, str(u.id).get_slice(".", 2)]
			u.erase("file")
		subjects.append(copy)
	g.subjects = subjects
	Curriculum.put_grade(4, g)
	for s: Dictionary in subjects:   # a tab shows once its subject has a written unit
		var first := str(s.units[0].id)
		if not Curriculum.has_content(first):
			Curriculum.put_content(first, {"id": first, "lesson": [{"text": "a"}, {"text": "b"}], "exercises": [],
				"generators": []})
	await _open()
	for sid: String in Curriculum.SUBJECTS:
		screen.show_map(sid)
		await wait_process_frames(2)
		for tab: String in Curriculum.SUBJECTS:
			assert_not_null(screen.find_child("Tab_" + tab, true, false), "%s's map has the %s tab" % [sid, tab])
		var size := screen.get_combined_minimum_size()
		assert_lte(size.x, SchoolUi.FRAME.x, "%s's map is %s" % [sid, size])
		assert_lte(size.y, SchoolUi.FRAME.y, "%s's map is %s" % [sid, size])
	for u: Dictionary in Curriculum.units(4, "maths"):   # every unit mastered: the gold line fits too
		var p := profile.school.progress(str(u.id))
		for day in [DAY - 9, DAY - 5, DAY]:
			p = MasteryRules.after_round(p, 6, 6, day).progress
		profile.school.set_progress(str(u.id), p)
	screen.show_map("maths")
	await wait_process_frames(2)
	assert_true(screen.find_children("*", "Label", true, false).any(
		func(l: Label) -> bool: return l.visible and l.text.contains("mastered")), "the gold words show")
	var done := screen.get_combined_minimum_size()
	assert_lte(done.y, SchoolUi.FRAME.y, "the mastered map is %s" % done)
	Curriculum.clear_cache()


## A subject's tab shows once it has a written unit (maths, science and English always): a child never opens an
## empty subject. The grown-ups' page lists every subject of the outline.
func test_a_subject_s_tab_shows_once_it_has_a_written_unit() -> void:
	var g: Dictionary = Curriculum.grade(4).duplicate(true)
	g.subjects = (g.subjects as Array).slice(0, 3)   # maths, science, English
	var history: Dictionary = (g.subjects[0] as Dictionary).duplicate(true)
	history.id = "history"
	for u: Dictionary in history.units:
		u.id = str(u.id).replace(".maths.", ".history.")
		u.erase("file")
	g.subjects.append(history)
	Curriculum.put_grade(4, g)
	await _open()
	screen.show_map("maths")
	await wait_process_frames(2)
	assert_null(screen.find_child("Tab_history", true, false), "nothing written yet: no tab")
	for sid: String in ["maths", "science", "english"]:
		assert_not_null(screen.find_child("Tab_" + sid, true, false), sid)
	var first := str(history.units[0].id)
	Curriculum.put_content(first, {"id": first, "lesson": [{"text": "a"}, {"text": "b"}], "exercises": [], "generators": []})
	screen.show_map("maths")
	await wait_process_frames(2)
	assert_not_null(screen.find_child("Tab_history", true, false), "a written unit: the tab shows")
	Curriculum.clear_cache()


## A grade shows only the subjects its outline has.
func test_the_map_shows_only_the_grade_s_subjects() -> void:
	await _open()
	screen.show_map("maths")
	await wait_process_frames(2)
	var shown := 0
	for s: Dictionary in Curriculum.subjects(4):
		var sid := str(s.id)
		if Curriculum.CORE.has(sid) or Curriculum.has_written(4, sid):
			assert_not_null(screen.find_child("Tab_" + sid, true, false), sid)
			shown += 1
	assert_not_null(screen.find_child("Tab_life", true, false), "owner #112: Life, the 13th tab, on every grade")
	assert_eq(screen.find_children("Tab_*", "", true, false).size(), shown + 1)
