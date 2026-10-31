extends GutTest
## Owner #68 (spec §22.2, rulings 7-8): stars per unit, never lost: ★ a round finished, ★★ 5 of 6 right the first time
## (mastered: the reward, once), ★★★ mastered again on a later day (remembered). Reviews are suggested after 1, 3, 7, 21
## and 60 days; nothing is lost when one waits.

const M := preload("res://core/school/mastery_rules.gd")
const DAY := 20_000


func _fresh() -> Dictionary:
	return SchoolData.new().progress("g4.maths.big_numbers")


func test_a_finished_round_gives_the_first_star() -> void:
	var r := M.after_round(_fresh(), 2, 6, DAY)
	assert_eq(M.stars(r.progress), 1)
	assert_eq(r.stars_before, 0)
	assert_false(r.pay)
	assert_eq(int(r.progress.r), 1, "one round")
	assert_eq(int(r.progress.a), 6)
	assert_eq(int(r.progress.f), 2)
	assert_eq(int(r.progress.b), 33, "the best round, in percent")
	assert_eq(int(r.progress.t), DAY, "the day last practised")


func test_five_of_six_right_first_time_masters_it_and_pays_once() -> void:
	var r := M.after_round(_fresh(), 5, 6, DAY)
	assert_eq(M.stars(r.progress), 2)
	assert_true(r.mastered_now)
	assert_true(r.pay, "the reward the first time")
	var again := M.after_round(r.progress, 6, 6, DAY)
	assert_false(again.pay, "never twice")
	assert_false(again.mastered_now)
	assert_eq(M.stars(again.progress), 2, "the same day is not 'remembered'")


func test_four_of_six_is_not_mastered_yet() -> void:
	var r := M.after_round(_fresh(), 4, 6, DAY)
	assert_eq(M.stars(r.progress), 1)
	assert_false(r.pay)


func test_mastered_again_on_a_later_day_is_remembered() -> void:
	var p: Dictionary = M.after_round(_fresh(), 5, 6, DAY).progress
	var later := M.after_round(p, 5, 6, DAY + 1)
	assert_eq(M.stars(later.progress), 3)
	assert_true(later.remembered_now)
	assert_false(later.pay, "a star, never more gold")


func test_stars_never_drop() -> void:
	var p: Dictionary = M.after_round(_fresh(), 6, 6, DAY).progress
	p = M.after_round(p, 6, 6, DAY + 1).progress
	var poor := M.after_round(p, 0, 6, DAY + 5)
	assert_eq(M.stars(poor.progress), 3)


func test_reviews_step_through_1_3_7_21_60_days() -> void:
	var p: Dictionary = M.after_round(_fresh(), 6, 6, DAY).progress
	assert_eq(int(p.d), DAY + 1)
	assert_false(M.review_due(p, DAY))
	assert_true(M.review_due(p, DAY + 1))
	var day := DAY + 1
	for step: int in [3, 7, 21, 60, 60]:
		p = M.after_round(p, 6, 6, day).progress
		assert_eq(int(p.d), day + step, "next review after %d days" % step)
		day += step


func test_practising_before_a_review_is_due_does_not_move_the_step() -> void:
	var p: Dictionary = M.after_round(_fresh(), 6, 6, DAY).progress
	p = M.after_round(p, 6, 6, DAY + 1).progress   # the 1-day review: next in 3
	var early := M.after_round(p, 6, 6, DAY + 2)
	assert_eq(int(early.progress.d), int(p.d), "still due on the same day")


func test_a_review_that_goes_less_well_comes_back_sooner_without_losing_anything() -> void:
	var p: Dictionary = M.after_round(_fresh(), 6, 6, DAY).progress
	p = M.after_round(p, 6, 6, DAY + 1).progress
	p = M.after_round(p, 6, 6, DAY + 4).progress   # now a week away
	var tough := M.after_round(p, 2, 6, DAY + 11)
	assert_eq(int(tough.progress.d), DAY + 12, "tomorrow")
	assert_eq(M.stars(tough.progress), 3)
	assert_true(bool(tough.progress.p), "paid stays paid")


func test_nothing_is_due_before_mastering() -> void:
	var p: Dictionary = M.after_round(_fresh(), 1, 6, DAY).progress
	assert_false(M.review_due(p, DAY + 100))


func test_a_day_going_backwards_changes_nothing_earned() -> void:
	var p: Dictionary = M.after_round(_fresh(), 6, 6, DAY).progress
	var back := M.after_round(p, 6, 6, DAY - 30)
	assert_eq(M.stars(back.progress), 2, "not 'remembered' on an earlier day")
	assert_eq(int(back.progress.d), int(p.d), "the review day stays")
	assert_eq(int(back.progress.t), DAY, "the last day never goes back")
	assert_false(back.pay)


func test_an_empty_round_records_nothing() -> void:
	var p := _fresh()
	var r := M.after_round(p, 0, 0, DAY)
	assert_eq(r.progress, p)
	assert_false(r.pay)


func test_the_lesson_read() -> void:
	var p := M.lesson_read(_fresh())
	assert_true(bool(p.l))
	assert_eq(M.stars(p), 0, "reading earns no star (no reward for opening lessons)")


func test_the_unit_reward_is_fixed_gold() -> void:
	assert_eq(M.UNIT_GOLD, 100)


func test_a_subject_is_mastered_when_every_written_unit_is() -> void:
	var s := SchoolData.new()
	var ids: Array[String] = ["g4.maths.big_numbers", "g4.maths.divide"]
	assert_false(M.all_mastered(s, ids))
	s.set_progress(ids[0], M.after_round(s.progress(ids[0]), 6, 6, DAY).progress)
	assert_false(M.all_mastered(s, ids))
	s.set_progress(ids[1], M.after_round(s.progress(ids[1]), 5, 6, DAY).progress)
	assert_true(M.all_mastered(s, ids))
	assert_false(M.all_mastered(s, [] as Array[String]), "nothing written yet: no certificate")
