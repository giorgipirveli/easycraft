extends GutTest
## Owner #112, #113 (docs/design/life-skills.md §3, §7, §11): the Life Passport's rules. A page per skill (an Experience
## on a track); a finished run stamps it (Done it, By myself, Expert: informational, never lost); the first finished run
## of a skill pays the Experience's gold once, like a lesson; the skill comes back after 1, 3, 7, 21 and 60 days (spaced
## repeats, never required); the before-and-after checks give the grown-ups' honest numbers ("knew 1 of 5, now 5 of 5,
## in 9 minutes") and "your child can now..." lists what was done by themselves.

const DAY := 20_000
const SKILL := "fire_escape.middle"


func _outcome(stamps: int, seconds: float = 300.0) -> Dictionary:
	return {"finished": stamps != 0, "stamps": stamps, "hints": 0 if stamps & LifeData.SELF else 2, "seconds": seconds}


func test_a_page_per_skill_on_every_track() -> void:
	var pages := LifePassport.skills()
	assert_eq(pages.size(), LifeExperience.IDS.size() * LifeData.TRACKS.size())
	for page in pages:
		assert_true(LifeData.valid_skill_id(str(page.id)), str(page.id))
		assert_ne(str(page.title), "")


func test_a_first_finished_run_stamps_pays_once_and_schedules_a_repeat() -> void:
	var life := LifeData.new()
	var r := LifePassport.record_run(life, SKILL, _outcome(LifeData.DONE, 540.0), DAY)
	assert_eq(int(r.new), LifeData.DONE)
	assert_eq(int(r.gold), LifePassport.GOLD)
	assert_eq(LifePassport.GOLD, EarnRules.UNIT_GOLD, "like a lesson mastered")
	var p := life.skill(SKILL)
	assert_eq(int(p.r), 1)
	assert_eq(int(p.c), DAY)
	assert_eq(int(p.w), 540)
	assert_eq(int(p.d), DAY + 1)
	var again := LifePassport.record_run(life, SKILL, _outcome(LifeData.DONE | LifeData.SELF), DAY)
	assert_eq(int(again.gold), 0, "the gold is paid once per skill")
	assert_eq(int(again.new), LifeData.SELF)
	assert_eq(int(life.skill(SKILL).w), 540, "the first run's time stays")


func test_an_unfinished_run_changes_nothing() -> void:
	var life := LifeData.new()
	var r := LifePassport.record_run(life, SKILL, {"finished": false, "stamps": 0, "hints": 0, "seconds": 30.0}, DAY)
	assert_eq(int(r.gold), 0)
	assert_true(life.skills.is_empty())


func test_stamps_are_never_lost() -> void:
	var life := LifeData.new()
	LifePassport.record_run(life, SKILL, _outcome(LifeData.DONE | LifeData.SELF), DAY)
	LifePassport.record_run(life, SKILL, _outcome(LifeData.DONE), DAY + 1)
	assert_true(life.has_stamp(SKILL, LifeData.SELF))


func test_a_new_expert_stamp_is_the_surprise() -> void:
	var life := LifeData.new()
	assert_false(bool(LifePassport.record_run(life, SKILL, _outcome(LifeData.DONE | LifeData.SELF), DAY).expert_new))
	var r := LifePassport.record_run(life, SKILL, _outcome(LifeData.DONE | LifeData.SELF | LifeData.EXPERT), DAY)
	assert_true(bool(r.expert_new))
	assert_false(bool(LifePassport.record_run(life, SKILL, _outcome(7), DAY + 2).expert_new), "only the first time")


func test_the_expert_try_opens_after_by_myself() -> void:
	var life := LifeData.new()
	assert_false(LifePassport.expert_open(life, SKILL))
	LifePassport.record_run(life, SKILL, _outcome(LifeData.DONE), DAY)
	assert_false(LifePassport.expert_open(life, SKILL))
	LifePassport.record_run(life, SKILL, _outcome(LifeData.DONE | LifeData.SELF), DAY)
	assert_true(LifePassport.expert_open(life, SKILL))


func test_spaced_repeats_come_back_later_and_never_expire() -> void:
	var life := LifeData.new()
	LifePassport.record_run(life, SKILL, _outcome(LifeData.DONE), DAY)
	assert_false(LifePassport.repeat_due(life, SKILL, DAY))
	assert_true(LifePassport.repeat_due(life, SKILL, DAY + 1))
	LifePassport.record_run(life, SKILL, _outcome(LifeData.DONE), DAY + 1)
	assert_eq(int(life.skill(SKILL).d), DAY + 1 + LifePassport.REPEAT_DAYS[1])
	assert_true(LifePassport.repeat_due(life, SKILL, DAY + 400), "a repeat waits: nothing is lost")
	LifePassport.record_run(life, SKILL, _outcome(LifeData.DONE), DAY + 2)
	assert_eq(int(life.skill(SKILL).x), 1, "a run before the repeat's day does not move it on")


func test_a_skill_never_played_is_not_due() -> void:
	assert_false(LifePassport.repeat_due(LifeData.new(), SKILL, DAY))


func test_the_before_check_is_the_first_and_the_after_check_the_best_and_latest() -> void:
	var life := LifeData.new()
	LifePassport.record_check(life, SKILL, false, 1, 5)
	LifePassport.record_check(life, SKILL, false, 4, 5)
	var p := life.skill(SKILL)
	assert_eq(int(p.b), 1, "only the first before-check counts")
	assert_eq(int(p.q), 5)
	LifePassport.record_check(life, SKILL, true, 5, 5)
	LifePassport.record_check(life, SKILL, true, 4, 5)
	p = life.skill(SKILL)
	assert_eq(int(p.a), 5)
	assert_eq(int(p.l), 4)


func test_the_grown_ups_line_is_honest() -> void:
	var life := LifeData.new()
	assert_eq(LifePassport.summary_line(life, SKILL), "")
	LifePassport.record_check(life, SKILL, false, 1, 5)
	LifePassport.record_run(life, SKILL, _outcome(LifeData.DONE, 540.0), DAY)
	LifePassport.record_check(life, SKILL, true, 5, 5)
	assert_eq(LifePassport.summary_line(life, SKILL),
		"Fire Escape (Middle): knew 1 of 5 at the start, now 5 of 5, in 9 minutes.")


func test_your_child_can_now_lists_only_what_was_done_by_themselves() -> void:
	var life := LifeData.new()
	LifePassport.record_run(life, "fire_escape.middle", _outcome(LifeData.DONE), DAY)
	LifePassport.record_run(life, "little_lifesaver.little", _outcome(LifeData.DONE | LifeData.SELF), DAY)
	var lines := LifePassport.can_now(life, "ge")
	assert_eq(lines.size(), 1)
	assert_string_contains(lines[0], "112")
	var practised := LifePassport.practising(life, "ge")
	assert_eq(practised.size(), 1, "the fire escape is practised with the coach's help")


func test_the_week_shows_what_was_played_in_the_last_seven_days() -> void:
	var life := LifeData.new()
	LifePassport.record_run(life, "fire_escape.middle", _outcome(LifeData.DONE), DAY - 10)
	LifePassport.record_run(life, "money_stall.little", _outcome(LifeData.DONE), DAY - 2)
	var week := LifePassport.this_week(life, DAY)
	assert_eq(week, ["money_stall.little"] as Array[String])


## L1's follow-up (Life L2, owner #112): the Gold Shop's "How to earn" list names Life (EarnRules.TABLE), with the
## Passport's own number.
func test_the_gold_shops_how_to_earn_names_life() -> void:
	var rows := EarnRules.TABLE.filter(func(r: Dictionary) -> bool: return str(r.id) == "life_skill")
	assert_eq(rows.size(), 1)
	if rows.is_empty():
		return
	assert_eq(int(rows[0].gold), LifePassport.GOLD, "the first finished run of a Life skill")
	assert_eq(str(rows[0].by), "game")
	assert_string_contains(str(rows[0].when), "Life")
