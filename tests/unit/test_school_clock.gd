extends GutTest
## Owner #68 (spec §22.2): the School's days are whole days of the device's calendar; grown-ups read them as dates.


func test_days_follow_the_calendar() -> void:
	var a := SchoolClock.day_of({"year": 2026, "month": 9, "day": 28})
	assert_eq(SchoolClock.day_of({"year": 2026, "month": 9, "day": 29}), a + 1)
	assert_eq(SchoolClock.day_of({"year": 2026, "month": 10, "day": 1}), a + 3)
	assert_eq(SchoolClock.day_of({"year": 1970, "month": 1, "day": 2}), 1)


func test_a_short_date_for_grown_ups() -> void:
	assert_eq(SchoolClock.short_date(SchoolClock.day_of({"year": 2026, "month": 9, "day": 28})), "28 Sep")
	assert_eq(SchoolClock.short_date(SchoolClock.day_of({"year": 2027, "month": 1, "day": 3})), "3 Jan")
	assert_eq(SchoolClock.short_date(0), "", "never practised")


func test_today_is_a_sensible_day() -> void:
	assert_gt(SchoolClock.today(), SchoolClock.day_of({"year": 2026, "month": 1, "day": 1}))
