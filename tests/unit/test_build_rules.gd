extends GutTest
## Build to Survive's clock (spec §12.18): a new world starts in the morning and the first night comes
## 3:00 later; days run 4× (sunrise to sunset in 3:30), nights 2× (sunset to sunrise in 3:00). The HUD's
## night clock says "Night in 1:20" by day and "Morning in 0:45" at night. Game time only.


## Plays `seconds` of Build to Survive time from t, in small steps like SkyCycle does each frame.
func _play(t: float, seconds: float, step: float = 0.05) -> float:
	var left := seconds
	while left > 0.0:
		var dt := minf(step, left)
		t = DayCycle.advance(t, dt * BuildRules.speed(t))
		left -= dt
	return t


func test_the_first_night_comes_three_minutes_after_the_start() -> void:
	assert_almost_eq(BuildRules.seconds_to_night(BuildRules.START_TIME), 180.0, 0.01)
	assert_false(DayCycle.is_night(_play(BuildRules.START_TIME, 179.0)), "still day at 2:59")
	assert_true(DayCycle.is_night(_play(BuildRules.START_TIME, 181.0)), "night at 3:01")


func test_a_day_lasts_three_and_a_half_minutes_and_a_night_three() -> void:
	assert_almost_eq(BuildRules.seconds_until(DayCycle.SUNRISE, DayCycle.SUNSET), 210.0, 0.01)
	assert_almost_eq(BuildRules.seconds_until(DayCycle.SUNSET, DayCycle.SUNRISE), 180.0, 0.01)
	assert_almost_eq(BuildRules.seconds_to_morning(DayCycle.SUNSET), 180.0, 0.01)
	assert_almost_eq(BuildRules.seconds_to_morning(DayCycle.MIDNIGHT), 90.0, 0.01, "half the night left at midnight")
	assert_true(DayCycle.is_night(_play(DayCycle.SUNSET, 179.0)))
	assert_false(DayCycle.is_night(_play(DayCycle.SUNSET, 181.0)), "morning after 3:00")


func test_the_speeds() -> void:
	assert_eq(BuildRules.speed(DayCycle.NOON), BuildRules.DAY_SPEED)
	assert_eq(BuildRules.speed(DayCycle.SUNRISE), BuildRules.DAY_SPEED, "the sun is up")
	assert_eq(BuildRules.speed(DayCycle.SUNSET), BuildRules.NIGHT_SPEED, "the sun is down")
	assert_eq(BuildRules.speed(DayCycle.MIDNIGHT), BuildRules.NIGHT_SPEED)
	assert_eq(BuildRules.DAY_SPEED, 4.0)
	assert_eq(BuildRules.NIGHT_SPEED, 2.0)


func test_seconds_until_goes_forward_round_the_clock() -> void:
	assert_almost_eq(BuildRules.seconds_until(0.5, 0.5), 0.0, 0.0001)
	assert_almost_eq(BuildRules.seconds_until(DayCycle.SUNSET, DayCycle.SUNSET), 0.0, 0.0001)
	assert_almost_eq(BuildRules.seconds_until(0.86, 0.85), 390.0 - 0.01 * DayCycle.LENGTH / 2.0, 0.01, "a whole cycle less a bit of night")
	assert_almost_eq(BuildRules.seconds_until(0.5, 0.6), 0.1 * DayCycle.LENGTH / 4.0, 0.001)


func test_the_night_clock_words() -> void:
	assert_eq(BuildRules.clock_line(BuildRules.START_TIME), "Night in 3:00")
	var t := _play(BuildRules.START_TIME, 100.0)
	assert_eq(BuildRules.clock_line(t), "Night in 1:20")
	assert_true(BuildRules.clock_is_night(DayCycle.MIDNIGHT))
	assert_false(BuildRules.clock_is_night(DayCycle.NOON))
	assert_eq(BuildRules.clock_line(DayCycle.MIDNIGHT), "Morning in 1:30")
	assert_eq(BuildRules.clock_line(DayCycle.SUNSET - 0.00001), "Night in 0:01", "never 0:00 by day")


func test_minutes_and_seconds() -> void:
	assert_eq(BuildRules.mm_ss(0.0), "0:00")
	assert_eq(BuildRules.mm_ss(59.2), "1:00", "rounded up")
	assert_eq(BuildRules.mm_ss(80.0), "1:20")
	assert_eq(BuildRules.mm_ss(605.0), "10:05")
	assert_eq(BuildRules.mm_ss(-3.0), "0:00")


func test_the_score_lines_are_short_and_kind() -> void:
	assert_eq(BuildRules.score_line(3, 5), "Nights 3 · Best 5")
	assert_eq(BuildRules.morning_line(3, false), "You made it through night 3!")
	assert_eq(BuildRules.morning_line(4, true), "You made it through night 4! A new best!")
