extends GutTest
## Owner #79, #83 (spec §25.1, §25.5): the School pays a few gold for each answer right the first time ("+5 gold: right
## the first time!"), up to a daily cap, and says the round's total at its end; STOP keeps that gold; the first unit a
## child ever masters is noted for the friend who invited them (InviteData). An Explorer lesson (a unit marked "bonus")
## opens for good with gold; the grade's own units stay open and free.

const UNIT := "g4.maths.big_numbers"
const BONUS := "g4.maths.rockets_explorer"
const DAY := 20_000
const CONTENT := {"id": UNIT, "lesson": [{"text": "A digit's place tells what it is worth."}, {"text": "Ten times."}],
	"exercises": [
		{"type": "truefalse", "prompt": "In 347, the 4 is worth 40.", "answer": true, "hint": "Tens place.", "level": 1},
		{"type": "truefalse", "prompt": "In 347, the 3 is worth 30.", "answer": false, "hint": "Hundreds.", "level": 1},
		{"type": "truefalse", "prompt": "In 520, the 2 is worth 20.", "answer": true, "hint": "Tens place.", "level": 2},
		{"type": "truefalse", "prompt": "In 905, the 0 is worth 0.", "answer": true, "hint": "No tens.", "level": 2},
		{"type": "truefalse", "prompt": "In 614, the 6 is worth 60.", "answer": false, "hint": "Hundreds.", "level": 3},
		{"type": "truefalse", "prompt": "In 71, the 7 is worth 70.", "answer": true, "hint": "Tens place.", "level": 3}],
	"generators": []}

var profile: ProfileData
var saves := 0
var screen: SchoolScreen


func before_each() -> void:
	ParentGate.reset_tries()
	Curriculum.clear_cache()
	Curriculum.put_grade(4, {"grade": 4, "ages": "9-10", "subjects": [
		{"id": "maths", "title": "Maths", "units": [
			{"id": UNIT, "title": "Big numbers", "standards": ["4.NBT.1"], "goals": ["Read big numbers"], "file": "x"},
			{"id": BONUS, "title": "How rockets work", "standards": ["Explorer"], "goals": ["Why a rocket flies"],
				"file": "y", "bonus": true, "price": 150}]},
		{"id": "science", "title": "Science", "units": []}, {"id": "english", "title": "English", "units": []}]})
	Curriculum.put_content(UNIT, CONTENT)
	Curriculum.put_content(BONUS, CONTENT.merged({"id": BONUS}, true))
	profile = ProfileData.new()
	profile.school.grade = 4
	saves = 0


func after_each() -> void:
	Curriculum.clear_cache()


func after_all() -> void:
	Audio.stop_all()


func _open() -> void:
	screen = SchoolScreen.new()
	screen.profile = profile
	screen.save_profile = func() -> void: saves += 1
	screen.today = func() -> int: return DAY
	screen.next_seed = func() -> int: return 7
	add_child_autofree(screen)
	await wait_process_frames(2)


func _labels() -> Array[String]:
	var out: Array[String] = []
	for l in screen.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out.append((l as Label).text)
	return out


func _button(text: String) -> Button:
	for b in screen.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b
	return null


## Answers the current true-or-false exercise: right at once, or wrong once first. Leaves NEXT to the caller.
func _check(right_first: bool) -> void:
	var p := screen.exercise_panel
	var a: bool = ExerciseCheck.answer_of(p.ex)
	if not right_first:
		(p.answer_widget as ChoiceAnswer).choose(1 if a else 0)
		p.check()
	(p.answer_widget as ChoiceAnswer).choose(0 if a else 1)
	p.check()


func _next() -> void:
	screen.exercise_panel.next_button.pressed.emit()
	await wait_process_frames(1)


func test_an_answer_right_the_first_time_says_its_gold_at_once() -> void:
	await _open()
	var gold := profile.survivor_gold
	screen.show_round(UNIT)
	await wait_process_frames(1)
	_check(true)
	assert_true(screen.exercise_panel.gold_line.visible)
	assert_eq(screen.exercise_panel.gold_line.text, "+5 gold: right the first time!")
	assert_eq(profile.survivor_gold, gold + EarnRules.ANSWER_GOLD)
	await _next()
	_check(false)
	assert_false(screen.exercise_panel.gold_line.visible, "a second try earns stars' help, not gold")
	assert_eq(profile.survivor_gold, gold + EarnRules.ANSWER_GOLD)


func test_the_round_end_says_the_answers_gold_and_the_unit_pays_its_100_once() -> void:
	await _open()
	var gold := profile.survivor_gold
	screen.show_round(UNIT)
	await wait_process_frames(1)
	for i in 6:
		_check(true)
		await _next()
	assert_eq(screen.page, SchoolScreen.ROUND_END)
	assert_has(_labels(), "+30 gold for answers right the first time!")
	assert_eq(profile.survivor_gold, gold + 30 + EarnRules.UNIT_GOLD)
	assert_eq(profile.earn_today, {"d": DAY, "g": 30})


func test_the_day_s_cap_keeps_learning_free_of_grind() -> void:
	profile.earn_today = {"d": DAY, "g": EarnRules.ANSWER_DAY_CAP - EarnRules.ANSWER_GOLD}
	await _open()
	var gold := profile.survivor_gold
	screen.show_round(UNIT)
	await wait_process_frames(1)
	for i in 6:
		_check(true)
		await _next()
	assert_eq(profile.survivor_gold, gold + EarnRules.ANSWER_GOLD + EarnRules.UNIT_GOLD, "one more answer's gold, then none")
	assert_has(_labels(), "+5 gold for answers right the first time!")
	assert_has(_labels(), EarnRules.DAY_FULL_WORDS)


func test_stop_keeps_the_gold_earned_and_records_no_stars() -> void:
	await _open()
	screen.show_round(UNIT)
	await wait_process_frames(1)
	_check(true)
	await _next()
	var before := saves
	_button("STOP").pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.page, SchoolScreen.UNIT)
	assert_gt(saves, before, "the gold is saved")
	assert_eq(MasteryRules.stars(profile.school.progress(UNIT)), 0)


func test_the_first_unit_mastered_is_noted_for_the_friend_who_invited() -> void:
	await _open()
	screen.show_round(UNIT)
	await wait_process_frames(1)
	for i in 6:
		_check(true)
		await _next()
	assert_eq(profile.invite.learned_day, DAY)
	assert_eq(profile.invite.events_to_send(), [{"event": "learned"}] as Array[Dictionary], "sent at the next sign-in")


## A unit's way in: PLAY where it plays without reading, else the School's PRACTICE (owner #134).
func _way_in() -> Button:
	var play := _button(SchoolScreen.PLAY_WORDS)
	return play if play != null else _button("PRACTICE")


func test_an_explorer_lesson_opens_with_gold_and_the_grade_s_own_unit_stays_free() -> void:
	profile.survivor_gold = 100
	await _open()
	screen.show_unit(UNIT)
	await wait_process_frames(1)
	assert_not_null(_way_in(), "a grade's own unit: open and free (owner #122: PLAY; #134: PRACTICE with no game yet)")
	screen.show_unit(BONUS)
	await wait_process_frames(1)
	assert_null(_way_in())
	var open := _button("OPEN FOR 150 GOLD")
	assert_not_null(open)
	assert_true(open.disabled, "100 gold is not enough")
	screen.show_round(BONUS)
	await wait_process_frames(1)
	assert_eq(screen.page, SchoolScreen.UNIT, "no round before it is open")
	screen.show_play(BONUS)
	await wait_process_frames(1)
	assert_eq(screen.page, SchoolScreen.UNIT, "no play before it is open")
	profile.survivor_gold = 400
	screen.show_unit(BONUS)
	await wait_process_frames(1)
	_button("OPEN FOR 150 GOLD").pressed.emit()
	await wait_process_frames(1)
	assert_eq(profile.survivor_gold, 250)
	assert_true(profile.bought.has("lesson:" + BONUS))
	assert_not_null(_way_in(), "open for good")
	assert_gt(saves, 0)
