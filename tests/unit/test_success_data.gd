extends GutTest
## Owner #115 (docs/design/success-skills.md §2 systems 3, 6, 7; §4): Success S2's part of the profile, inside Life's
## (ProfileData.life.success): the Goal Board's goal and plan, the habit garden (the habit, the days it was kept, the
## plants of earlier habits), the Connections Book's people (met, warmth, help, promises, introductions, a mentor's tip)
## and the Success Stories read. Everything is picked from pictures (nothing typed), parsed field by field (a bad field
## falls back on its own), limited in size and merged without losing a kept day, a person or a story.

const DAY := 20_000


func test_a_new_profile_has_no_success_progress() -> void:
	var d := SuccessData.new()
	assert_true(d.is_empty())
	assert_true(d.goal.is_empty())
	assert_true(d.habit.is_empty())
	assert_eq(d.garden.size(), 0)
	assert_true(d.people.is_empty())
	assert_true(d.stories.is_empty())


func test_it_round_trips_through_json() -> void:
	var d := SuccessData.new()
	d.goal = {"d": "moon", "g": "moon_gold", "s": ["learn", "save", "build"], "t": 5, "w": "after_lesson",
		"a": "save_10", "o": "friends", "r": "after_step", "c": DAY, "x": 0, "b": 2, "n": 470}
	d.goals_reached = 2
	d.habit = {"h": "water", "c": DAY - 10, "k": [DAY - 9, DAY - 3, DAY], "n": 3, "l": DAY, "y": true}
	d.garden = [{"h": "read", "n": 12}]
	d.set_person("amara", {"m": DAY - 5, "w": 3, "h": 2, "p": 1, "i": 1, "t": true})
	d.mark_story("braille", DAY - 1, true)
	var e := SuccessData.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())))
	assert_false(e.is_empty())
	assert_eq(str(e.goal.d), "moon")
	assert_eq(e.goal.s, ["learn", "save", "build"])
	assert_eq(int(e.goal.t), 5)
	assert_eq(int(e.goal.n), 470)
	assert_eq(e.goals_reached, 2)
	assert_eq(str(e.habit.h), "water")
	assert_eq(e.habit.k, [DAY - 9, DAY - 3, DAY])
	assert_eq(int(e.habit.n), 3)
	assert_true(bool(e.habit.y))
	assert_eq(e.garden, [{"h": "read", "n": 12}] as Array[Dictionary])
	var p := e.person("amara")
	assert_eq(int(p.w), 3)
	assert_eq(int(p.h), 2)
	assert_true(bool(p.t))
	assert_true(e.story_read("braille"))
	assert_true(bool(e.story("braille").a))


func test_bad_fields_fall_back_on_their_own() -> void:
	var e := SuccessData.from_dict({"goal": {"d": "NOT OK", "s": "x"}, "reached": -3,
		"habit": {"h": "water", "k": ["a", DAY, -5, DAY], "n": -2},
		"garden": [{"h": "Bad Id", "n": 3}, "nope", {"h": "read", "n": 999_999}],
		"people": {"amara": {"w": 99, "h": -1}, "BAD ID": {"w": 1}, "tomas": "warm"},
		"stories": {"braille": {"r": DAY, "a": "yes"}, "x y": {"r": 1}}})
	assert_true(e.goal.is_empty(), "a goal without a good dream is no goal")
	assert_eq(e.goals_reached, 0)
	assert_eq(e.habit.k, [DAY], "only whole days, each once")
	assert_eq(int(e.habit.n), 1, "at least the days in the list")
	assert_eq(e.garden.size(), 1)
	assert_eq(int(e.garden[0].n), SuccessData.MAX_COUNT)
	assert_eq(int(e.person("amara").w), SuccessData.MAX_WARMTH, "warmth at most 5")
	assert_eq(int(e.person("amara").h), 0)
	assert_false(e.people.has("BAD ID"))
	assert_false(e.people.has("tomas"))
	assert_true(e.story_read("braille"))
	assert_false(bool(e.story("braille").a), "only true is true")
	assert_false(e.stories.has("x y"))


func test_a_broken_field_is_an_empty_one() -> void:
	assert_true(SuccessData.from_dict("lots").is_empty())
	assert_true(SuccessData.from_dict({"goal": 4, "habit": [], "people": 1}).is_empty())


func test_the_kept_days_are_limited_to_the_newest() -> void:
	var days: Array = []
	for i in SuccessData.MAX_DAYS + 50:
		days.append(DAY - 1000 + i)
	var e := SuccessData.from_dict({"habit": {"h": "water", "c": DAY - 1000, "k": days, "n": days.size()}})
	assert_eq((e.habit.k as Array).size(), SuccessData.MAX_DAYS)
	assert_eq(int((e.habit.k as Array).back()), DAY - 1000 + SuccessData.MAX_DAYS + 49, "the newest stay")
	assert_eq(int(e.habit.n), days.size(), "the plant's size keeps every kept day")


func test_the_merge_never_loses_a_kept_day_a_person_or_a_story() -> void:
	var a := SuccessData.new()
	a.habit = {"h": "water", "c": DAY - 10, "k": [DAY - 9, DAY - 8], "n": 2, "l": DAY - 8, "y": true}
	a.set_person("amara", {"m": DAY - 9, "w": 2, "h": 1})
	a.mark_story("braille", DAY - 4, false)
	var b := SuccessData.new()
	b.habit = {"h": "water", "c": DAY - 10, "k": [DAY - 8, DAY - 2], "n": 2, "l": DAY - 2, "y": true}
	b.set_person("amara", {"m": DAY - 3, "w": 4, "p": 1})
	b.set_person("lina", {"m": DAY - 2, "w": 1})
	b.mark_story("braille", DAY - 6, true)
	b.mark_story("nightingale", DAY - 1, false)
	b.goals_reached = 1
	a.merge_from(b)
	assert_eq(a.habit.k, [DAY - 9, DAY - 8, DAY - 2])
	assert_eq(int(a.habit.n), 3)
	assert_eq(int(a.habit.l), DAY - 2)
	var amara := a.person("amara")
	assert_eq(int(amara.m), DAY - 9, "the first meeting")
	assert_eq(int(amara.w), 4)
	assert_eq(int(amara.h), 1)
	assert_eq(int(amara.p), 1)
	assert_true(a.people.has("lina"))
	assert_eq(int(a.story("braille").r), DAY - 6, "the first read")
	assert_true(bool(a.story("braille").a))
	assert_true(a.story_read("nightingale"))
	assert_eq(a.goals_reached, 1)


func test_merging_another_habit_keeps_its_plant_in_the_garden() -> void:
	var a := SuccessData.new()
	a.habit = {"h": "read", "c": DAY - 2, "k": [DAY - 1], "n": 1, "l": DAY - 1, "y": true}
	var older := SuccessData.new()
	older.habit = {"h": "water", "c": DAY - 30, "k": [DAY - 29, DAY - 28], "n": 2, "l": DAY - 28, "y": true}
	a.merge_from(older)
	assert_eq(str(a.habit.h), "read", "the newer habit stays the one growing")
	assert_eq(a.garden, [{"h": "water", "n": 2}] as Array[Dictionary], "the other plant is kept in the garden")


func test_the_newer_goal_wins_a_merge() -> void:
	var a := SuccessData.new()
	a.goal = {"d": "moon", "g": "moon_gold", "c": DAY - 20}
	var b := SuccessData.new()
	b.goal = {"d": "learn", "g": "master_3", "c": DAY - 2}
	a.merge_from(b)
	assert_eq(str(a.goal.d), "learn")
	var c := SuccessData.new()
	c.goal = {"d": "build", "g": "house", "c": DAY - 40}
	a.merge_from(c)
	assert_eq(str(a.goal.d), "learn", "an older goal doesn't come back")


func test_lists_are_limited() -> void:
	var d := SuccessData.new()
	for i in SuccessData.MAX_PEOPLE + 5:
		d.set_person("p%d" % i, {"m": DAY, "w": 1})
	assert_eq(d.people.size(), SuccessData.MAX_PEOPLE)
	for i in SuccessData.MAX_STORIES + 5:
		d.mark_story("s%d" % i, DAY, false)
	assert_eq(d.stories.size(), SuccessData.MAX_STORIES)
	var garden: Array = []
	for i in SuccessData.MAX_GARDEN + 4:
		garden.append({"h": "h%d" % i, "n": 1})
	assert_eq(SuccessData.from_dict({"garden": garden}).garden.size(), SuccessData.MAX_GARDEN)


func test_life_carries_success_in_the_profile_and_its_backup() -> void:
	var p := ProfileData.new()
	p.life.success.goal = {"d": "moon", "g": "moon_gold", "c": DAY}
	p.life.success.set_person("amara", {"m": DAY, "w": 1})
	var q := ProfileData.from_json(p.to_json())
	assert_eq(str(q.life.success.goal.d), "moon")
	assert_true(q.life.success.people.has("amara"))
	var older := ProfileData.new()
	older.life.success.set_person("tomas", {"m": DAY - 3, "w": 2})
	q.life.merge_from(older.life)
	assert_true(q.life.success.people.has("tomas"), "Life's merge merges Success too")
	assert_false(q.life.is_empty())
