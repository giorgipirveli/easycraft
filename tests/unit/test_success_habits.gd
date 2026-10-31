extends GutTest
## Owner #115 (docs/design/success-skills.md §2.6, §3; the brief: "a plant grows on each day it is kept; a missed day
## never kills it: gentle, never guilt; no streak pressure"): the habit garden's rules. One small good habit, picked
## from pictures; once a day the child says whether they did it (honestly: "not today" is thanked); the plant grows on
## every day it was kept and never shrinks; a missed day changes nothing kept; another habit starts its own plant and
## the first one stays in the garden at its size (and grows on again if the child comes back to it).

const DAY := 20_000

var d: SuccessData


func before_each() -> void:
	d = SuccessData.new()


func test_the_habits_are_small_good_things_from_pictures() -> void:
	var list := SuccessHabits.list()
	assert_gte(list.size(), 6)
	for h in list:
		assert_true(SuccessData.valid_id(h.get("id")), str(h))
		assert_ne(str(h.get("title", "")), "", str(h))
		assert_ne(str(h.get("icon", "")), "", str(h))
	assert_false(SuccessHabits.habit("water").is_empty())


func test_choosing_a_habit_starts_its_plant() -> void:
	assert_true(SuccessHabits.choose(d, "water", DAY))
	assert_eq(str(d.habit.h), "water")
	assert_eq(int(d.habit.c), DAY)
	assert_eq(SuccessHabits.days_kept(d), 0)
	assert_eq(SuccessHabits.stage(SuccessHabits.days_kept(d)), 0, "a seed")
	assert_false(SuccessHabits.choose(d, "not_a_habit", DAY))
	assert_eq(str(d.habit.h), "water")


func test_a_kept_day_grows_the_plant_once_a_day() -> void:
	SuccessHabits.choose(d, "water", DAY)
	SuccessHabits.answer(d, DAY, true)
	assert_eq(SuccessHabits.days_kept(d), 1)
	assert_true(SuccessHabits.kept_on(d, DAY))
	SuccessHabits.answer(d, DAY, true)
	assert_eq(SuccessHabits.days_kept(d), 1, "one day is one day")
	assert_eq(SuccessHabits.stage(1), 1, "a sprout")


func test_not_today_is_honest_and_can_change_today() -> void:
	SuccessHabits.choose(d, "read", DAY)
	SuccessHabits.answer(d, DAY, true)
	SuccessHabits.answer(d, DAY, false)
	assert_eq(SuccessHabits.days_kept(d), 0, "the child changed today's answer")
	assert_true(SuccessHabits.answered_on(d, DAY))
	assert_string_contains(SuccessHabits.words(d, DAY), "honest")


func test_a_missed_day_never_takes_anything_away() -> void:
	SuccessHabits.choose(d, "water", DAY)
	for i in 6:
		SuccessHabits.answer(d, DAY + i, true)
	var size := SuccessHabits.stage(SuccessHabits.days_kept(d))
	SuccessHabits.answer(d, DAY + 6, false)
	assert_eq(SuccessHabits.days_kept(d), 6)
	assert_eq(SuccessHabits.stage(SuccessHabits.days_kept(d)), size, "the plant just waits")
	SuccessHabits.answer(d, DAY + 9, true)
	assert_eq(SuccessHabits.days_kept(d), 7, "and grows again on the next kept day")


func test_the_plant_only_ever_grows() -> void:
	var last := -1
	for n in 120:
		var s := SuccessHabits.stage(n)
		assert_gte(s, last, "day %d" % n)
		last = s
	assert_eq(SuccessHabits.stage(0), 0)
	assert_eq(SuccessHabits.stage(1000), SuccessHabits.STAGES.size() - 1)
	assert_eq(SuccessHabits.flowers(10), 0)
	assert_gt(SuccessHabits.flowers(40), 0, "a plant kept for weeks flowers")
	assert_lte(SuccessHabits.flowers(10_000), SuccessHabits.MAX_FLOWERS)


func test_coming_back_after_days_away_is_welcome_never_guilt() -> void:
	SuccessHabits.choose(d, "water", DAY)
	SuccessHabits.answer(d, DAY, true)
	var back := SuccessHabits.words(d, DAY + 5)
	assert_string_contains(back, "Welcome back")
	assert_string_contains(back, "waited")
	for words: String in [back, SuccessHabits.words(d, DAY), SuccessHabits.words(SuccessData.new(), DAY)]:
		var lower := words.to_lower()
		for bad: String in ["streak", "in a row", "lost", "broke", "died", "dead", "miss you", "don't forget", "hurry",
				"last chance", "shame", "failed"]:
			assert_false(lower.contains(bad), "%s: %s" % [bad, words])


func test_no_streak_is_counted_anywhere() -> void:
	var names: Array[String] = []
	for m: Dictionary in (SuccessHabits as Script).get_script_method_list():
		names.append(str(m.name))
	for c: String in (SuccessHabits as Script).get_script_constant_map():
		names.append(c.to_lower())
	for n in names:
		for bad: String in ["streak", "in_a_row", "best_run", "run_length", "consecutive"]:
			assert_false(n.contains(bad), n)


func test_another_habit_keeps_the_first_plant_in_the_garden_and_it_grows_on_later() -> void:
	SuccessHabits.choose(d, "water", DAY)
	for i in 4:
		SuccessHabits.answer(d, DAY + i, true)
	SuccessHabits.choose(d, "read", DAY + 5)
	assert_eq(str(d.habit.h), "read")
	assert_eq(SuccessHabits.days_kept(d), 0)
	assert_eq(d.garden, [{"h": "water", "n": 4}] as Array[Dictionary])
	SuccessHabits.answer(d, DAY + 5, true)
	SuccessHabits.choose(d, "water", DAY + 8)
	assert_eq(SuccessHabits.days_kept(d), 4, "the water plant remembers its 4 days")
	assert_eq(d.garden, [{"h": "read", "n": 1}] as Array[Dictionary])
	SuccessHabits.choose(d, "water", DAY + 9)
	assert_eq(SuccessHabits.days_kept(d), 4, "choosing the same habit again changes nothing")


func test_a_week_counts_the_days_kept_in_the_last_seven() -> void:
	SuccessHabits.choose(d, "water", DAY - 20)
	for day: int in [DAY - 20, DAY - 8, DAY - 6, DAY - 3, DAY]:
		SuccessHabits.answer(d, day, true)
	assert_eq(SuccessHabits.this_week(d, DAY), 3)
	assert_eq(SuccessHabits.days_kept(d), 5)


func test_the_grown_ups_line_says_only_what_happened() -> void:
	assert_eq(SuccessHabits.grown_ups_line(d), "")
	SuccessHabits.choose(d, "water", DAY - 3)
	SuccessHabits.answer(d, DAY - 3, true)
	SuccessHabits.answer(d, DAY - 1, true)
	var line := SuccessHabits.grown_ups_line(d)
	assert_string_contains(line, SuccessHabits.habit("water").title)
	assert_string_contains(line, "2 days")
	assert_string_contains(line, SchoolClock.short_date(DAY - 3))
