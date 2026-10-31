extends GutTest
## Owner #85 (brief 2026-09-30 item 1): the Daily Mission's part of the profile (DailyData). Each day's answers (a star
## for each right the first time), kept when the child stops half-way; mission days that never go down (a missed day is
## a rest day, never a loss: the fair-fun rules reject streak loss); the day's gold paid once (EarnRules' daily line);
## a backup's merge never loses a day.

const DAY := 20_726   # 2026-09-30


func test_answers_make_the_days_stars_and_a_finished_day_counts_once() -> void:
	var d := DailyData.new()
	assert_eq(d.stars_of(DAY), "")
	assert_false(d.is_done(DAY))
	for right: bool in [true, false, true, true]:
		d.answer(DAY, 4, right)
	assert_eq(d.stars_of(DAY), "1011")
	assert_false(d.is_done(DAY))
	assert_eq(d.total, 0, "not finished yet")
	d.answer(DAY, 4, true)
	assert_eq(d.stars_of(DAY), "10111")
	assert_true(d.is_done(DAY))
	assert_eq(d.total, 1)
	assert_eq(d.grade_of(DAY), 4)
	d.answer(DAY, 4, true)
	assert_eq(d.stars_of(DAY), "10111", "a finished day takes no more answers")
	assert_eq(d.total, 1)


func test_mission_days_never_go_down_and_the_week_shows_rest_days() -> void:
	var d := DailyData.new()
	for day: int in [DAY - 6, DAY - 5, DAY - 2, DAY]:
		for i in DailyMission.SIZE:
			d.answer(day, 5, true)
	assert_eq(d.total, 4)
	assert_eq(d.week(DAY), [1, 1, 0, 0, 1, 0, 1] as Array[int], "the last 7 days, oldest first: a mission day or a rest day")
	# Many days later, old results are tidied away but the count stays.
	for k in DailyData.KEEP + 20:
		for i in DailyMission.SIZE:
			d.answer(DAY + 10 + k, 5, false)
	assert_eq(d.total, 4 + DailyData.KEEP + 20)
	assert_lte(d.days.size(), DailyData.KEEP)
	assert_eq(d.week(DAY + 10 + DailyData.KEEP + 30), [0, 0, 0, 0, 0, 0, 0] as Array[int], "a long rest: calm, no loss")
	assert_eq(d.total, 4 + DailyData.KEEP + 20)


func test_the_days_gold_is_paid_once_by_earn_rules() -> void:
	var p := ProfileData.new()
	p.survivor_gold = 25
	assert_eq(EarnRules.daily_gold(p, DAY), 0, "nothing before the mission is done")
	for right: bool in [true, true, false, true, true]:
		p.daily.answer(DAY, 4, right)
	assert_eq(EarnRules.daily_gold(p, DAY), 4 * EarnRules.DAILY_STAR_GOLD)
	assert_eq(p.survivor_gold, 25 + 4 * EarnRules.DAILY_STAR_GOLD)
	assert_eq(EarnRules.daily_gold(p, DAY), 0, "once a day")
	for i in DailyMission.SIZE:
		p.daily.answer(DAY - 1, 4, true)
	assert_eq(EarnRules.daily_gold(p, DAY - 1), 0, "a clock turned back pays nothing again")
	var row: Dictionary = EarnRules.TABLE.filter(func(r: Dictionary) -> bool: return r.id == "daily")[0]
	assert_eq(int(row.gold), EarnRules.DAILY_STAR_GOLD)
	assert_eq(str(row.by), "game")


func test_it_survives_a_save_and_bad_data() -> void:
	var p := ProfileData.new()
	for right: bool in [true, false, true]:
		p.daily.answer(DAY, 3, right)
	for i in DailyMission.SIZE:
		p.daily.answer(DAY - 1, 3, true)
	var back := ProfileData.from_json(p.to_json())
	assert_eq(back.daily.stars_of(DAY), "101")
	assert_eq(back.daily.stars_of(DAY - 1), "11111")
	assert_eq(back.daily.total, 1)
	assert_eq(back.daily.grade_of(DAY), 3)
	for bad: Variant in ["x", [1], {"days": "no"}, {"days": {"abc": {"s": "11"}}}, {"days": {"20726": {"s": "1x1"}}},
			{"days": {"20726": {"s": "111111111"}}}, {"total": -4}, {"paid": "x"}]:
		var d := DailyData.from_dict(bad)
		assert_true(d.total >= 0, str(bad))
		for k: int in d.days:
			var s := d.stars_of(k)
			assert_true(s.length() <= DailyMission.SIZE and s.replace("1", "").replace("0", "") == "", str(bad))


func test_a_backup_merge_keeps_every_day_and_the_count() -> void:
	var a := DailyData.new()
	var b := DailyData.new()
	for right: bool in [true, true]:
		a.answer(DAY, 4, right)
	for right: bool in [true, false, true, true, true]:
		b.answer(DAY, 4, right)
	for i in DailyMission.SIZE:
		b.answer(DAY - 3, 4, true)
	a.paid = DAY
	a.merge_from(b)
	assert_eq(a.stars_of(DAY), "10111", "the further one")
	assert_eq(a.stars_of(DAY - 3), "11111")
	assert_eq(a.total, 2)
	assert_eq(a.paid, DAY, "paid stays paid")
	var p := ProfileData.new()
	p.daily = a
	var merged: ProfileData = ProfileBackup.merge(ProfileData.new(), ProfileBackup.to_backup(p)).profile
	assert_eq(merged.daily.total, 2, "through the profile backup")
