extends GutTest
## Owner #134 (docs/design/future-lessons.md §3.5, invisible assessment): a game never asks a quiz; it tells what the
## child showed (SkillShown events), and the School's record follows from it exactly as from a round: stars, the unit's
## gold once, reviews, the grown-ups' page (MasteryRules' progress). Only what was solved with no help counts; a few
## events can't master a unit (they count as a review of one mastered already); the answers' gold is the School's.

const UNIT := "g4.maths.add_fractions"
const OTHER := "g4.maths.big_numbers"
const DAY := 20000

var saves := 0


func before_each() -> void:
	saves = 0


func _profile() -> ProfileData:
	return ProfileData.new()


func _save() -> Callable:
	return func() -> void: saves += 1


func _six(shown: SkillShown, unit: String, solved: int) -> void:
	for i in MasteryRules.ROUND_SIZE:
		shown.add(unit, SkillShown.SOLVED if i < solved else SkillShown.HELPED)


func test_six_events_are_a_round_as_mastery_rules_counts_one() -> void:
	var p := _profile()
	var shown := SkillShown.begin()
	_six(shown, UNIT, 5)
	assert_eq(shown.right_first(UNIT), 5)
	assert_eq(shown.total(UNIT), 6)
	var gold_before := p.survivor_gold
	var results := shown.record(p, DAY, _save())
	var r: Dictionary = results[UNIT]
	assert_true(bool(r.recorded))
	assert_true(bool(r.mastered_now))
	assert_eq(MasteryRules.stars(p.school.progress(UNIT)), MasteryRules.MASTERED)
	assert_eq(p.survivor_gold - gold_before, MasteryRules.UNIT_GOLD, "the unit's gold, once")
	assert_eq(int(p.school.progress(UNIT).d), DAY + MasteryRules.REVIEW_DAYS[0], "its first review is planned")
	assert_eq(saves, 1, "saved once")
	shown = SkillShown.begin()
	_six(shown, UNIT, 6)
	var again: Dictionary = shown.record(p, DAY, _save())[UNIT]
	assert_false(bool(again.pay), "never twice")


func test_help_and_shown_answers_do_not_count() -> void:
	var shown := SkillShown.begin()
	assert_true(shown.add(UNIT, SkillShown.HELPED))
	assert_true(shown.add(UNIT, SkillShown.SHOWN))
	assert_true(shown.add(UNIT, SkillShown.SOLVED))
	assert_eq(shown.right_first(UNIT), 1)
	assert_eq(shown.total(UNIT), 3)


func test_a_new_setting_counts_and_is_kept_as_transfer() -> void:
	var p := _profile()
	var shown := SkillShown.begin()
	for i in 4:
		shown.add(UNIT, SkillShown.SOLVED)
	shown.add(UNIT, SkillShown.NEW_SETTING, "the bakery at night")
	shown.add(UNIT, SkillShown.NEW_SETTING)
	assert_eq(shown.right_first(UNIT), 6)
	var r: Dictionary = shown.record(p, DAY, _save())[UNIT]
	assert_eq(int(r.transfer), 2)
	assert_true(bool(r.mastered_now))


func test_an_unknown_kind_is_refused() -> void:
	var shown := SkillShown.begin()
	assert_false(shown.add(UNIT, "guessed"))
	assert_false(shown.add("", SkillShown.SOLVED), "every event names its unit")
	assert_eq(shown.total(UNIT), 0)


func test_a_few_events_never_master_a_new_unit() -> void:
	var p := _profile()
	var shown := SkillShown.begin()
	for i in 3:
		shown.add(UNIT, SkillShown.SOLVED)
	var r: Dictionary = shown.record(p, DAY, _save())[UNIT]
	assert_false(bool(r.recorded), "three right is a good minute, not a mastered unit")
	assert_eq(MasteryRules.stars(p.school.progress(UNIT)), 0)
	assert_eq(saves, 0, "nothing changed: nothing to save")


func test_a_few_events_count_as_a_review_of_a_mastered_unit() -> void:
	var p := _profile()
	var first := SkillShown.begin()
	_six(first, UNIT, 6)
	first.record(p, DAY, _save())
	var due := DAY + MasteryRules.REVIEW_DAYS[0]
	var shown := SkillShown.begin()
	for i in 3:
		shown.add(UNIT, SkillShown.SOLVED)
	var r: Dictionary = shown.record(p, due, _save())[UNIT]
	assert_true(bool(r.recorded), "a crystal's minute is a review")
	assert_eq(int(p.school.progress(UNIT).x), 1, "the next review step")


func test_each_unit_of_a_session_is_recorded_on_its_own() -> void:
	var p := _profile()
	var shown := SkillShown.begin()
	_six(shown, UNIT, 6)
	_six(shown, OTHER, 1)
	assert_eq(shown.units(), [UNIT, OTHER] as Array[String])
	var results := shown.record(p, DAY, _save())
	assert_true(bool(results[UNIT].mastered_now))
	assert_false(bool(results[OTHER].mastered_now))
	assert_eq(MasteryRules.stars(p.school.progress(OTHER)), 1, "a round finished: the first star")
	assert_eq(saves, 1, "one save for the session")


func test_the_answers_gold_is_the_school_s_within_its_day_cap() -> void:
	var p := _profile()
	var paid := 0
	for i in 40:
		paid += SkillShown.pay_first_try(p, DAY)
	assert_eq(paid, EarnRules.ANSWER_DAY_CAP)
