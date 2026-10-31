extends GutTest
## The day/night cycle (M1b Task 10): 20 minutes (12 day, 2 dusk, 4 night, 2 dawn), the sun and the
## moon, a light curve that never goes pitch black, and when a sleeper wakes up.


func _minutes_in(phase: int) -> float:
	var steps := 2400
	var n := 0
	for i in steps:
		if DayCycle.phase((i + 0.5) / steps) == phase:
			n += 1
	return 20.0 * n / steps


func _brightness(look: Dictionary) -> float:
	var ambient: Color = look.ambient_color
	var light: Color = look.light_color
	var sun_height := maxf((look.light_dir as Vector3).y, 0.0)
	return look.ambient * ambient.get_luminance() + look.light_energy * light.get_luminance() * sun_height


func test_a_day_lasts_twenty_minutes() -> void:
	assert_eq(DayCycle.LENGTH, 1200.0)
	assert_almost_eq(DayCycle.advance(0.3, 1200.0), 0.3, 0.0001, "a whole cycle comes back round")
	assert_almost_eq(DayCycle.advance(0.9, 240.0), 0.1, 0.0001, "the clock wraps past midnight")
	assert_almost_eq(DayCycle.wrap_time(-0.25), 0.75, 0.0001)
	assert_almost_eq(DayCycle.wrap_time(1.25), 0.25, 0.0001)


func test_phases_last_12_2_4_and_2_minutes() -> void:
	assert_almost_eq(_minutes_in(DayCycle.Phase.DAY), 12.0, 0.05)
	assert_almost_eq(_minutes_in(DayCycle.Phase.DUSK), 2.0, 0.05)
	assert_almost_eq(_minutes_in(DayCycle.Phase.NIGHT), 4.0, 0.05)
	assert_almost_eq(_minutes_in(DayCycle.Phase.DAWN), 2.0, 0.05)


func test_named_times_fall_in_their_phases() -> void:
	assert_eq(DayCycle.phase(DayCycle.NOON), DayCycle.Phase.DAY)
	assert_eq(DayCycle.phase(DayCycle.SUNSET), DayCycle.Phase.DUSK)
	assert_eq(DayCycle.phase(DayCycle.MIDNIGHT), DayCycle.Phase.NIGHT)
	assert_eq(DayCycle.phase(DayCycle.SUNRISE), DayCycle.Phase.DAWN)
	assert_eq(DayCycle.phase(DayCycle.START), DayCycle.Phase.DAY, "a new world starts in the morning")
	assert_lt(DayCycle.START, DayCycle.NOON)


func test_phases_come_in_order() -> void:
	var order: Array[int] = []
	for i in 1200:
		var p := DayCycle.phase(DayCycle.wrap_time(DayCycle.NOON + i / 1200.0))
		if order.is_empty() or order[-1] != p:
			order.append(p)
	assert_eq(order, [DayCycle.Phase.DAY, DayCycle.Phase.DUSK, DayCycle.Phase.NIGHT, DayCycle.Phase.DAWN, DayCycle.Phase.DAY])


func test_the_sun_rises_in_the_east_is_highest_at_noon_and_sets_in_the_west() -> void:
	var rise := DayCycle.sun_direction(DayCycle.SUNRISE)
	var set := DayCycle.sun_direction(DayCycle.SUNSET)
	assert_almost_eq(rise.y, 0.0, 0.001, "on the horizon at sunrise")
	assert_almost_eq(set.y, 0.0, 0.001, "on the horizon at sunset")
	assert_gt(rise.x, 0.9, "rises in the east (+X)")
	assert_lt(set.x, -0.9, "sets in the west (-X)")
	var noon := DayCycle.sun_direction(DayCycle.NOON)
	assert_gt(noon.y, 0.8, "high in the sky at noon")
	for i in 240:
		assert_true(DayCycle.sun_direction(i / 240.0).y <= noon.y + 0.00001, "never higher than at noon")
	assert_lt(DayCycle.sun_direction(DayCycle.MIDNIGHT).y, -0.8, "far below the ground at midnight")


func test_the_sun_moves_smoothly_without_jumps() -> void:
	var prev := DayCycle.sun_direction(0.0)
	for i in range(1, 2401):
		var d := DayCycle.sun_direction(i / 2400.0)
		assert_true(prev.angle_to(d) < deg_to_rad(1.0), "step %d" % i)
		prev = d


func test_the_moon_is_opposite_the_sun() -> void:
	for t in [0.0, 0.15, 0.3, 0.5, 0.85, 0.95]:
		assert_almost_eq((DayCycle.moon_direction(t) + DayCycle.sun_direction(t)).length(), 0.0, 0.0001)
	assert_gt(DayCycle.moon_direction(DayCycle.MIDNIGHT).y, 0.8, "high at midnight")


func test_it_is_night_while_the_sun_is_down() -> void:
	assert_true(DayCycle.is_night(DayCycle.MIDNIGHT))
	assert_true(DayCycle.is_night(DayCycle.SUNSET + 0.01))
	assert_true(DayCycle.is_night(DayCycle.SUNRISE - 0.01))
	assert_false(DayCycle.is_night(DayCycle.NOON))
	assert_false(DayCycle.is_night(DayCycle.SUNRISE + 0.01))
	assert_false(DayCycle.is_night(DayCycle.SUNSET - 0.01))


func test_wake_time_is_the_next_sunrise_at_night_and_the_next_sunset_by_day() -> void:
	assert_eq(DayCycle.wake_time(DayCycle.MIDNIGHT), DayCycle.SUNRISE)
	assert_eq(DayCycle.wake_time(0.95), DayCycle.SUNRISE)
	assert_eq(DayCycle.wake_time(DayCycle.SUNRISE - 0.01), DayCycle.SUNRISE, "just before sunrise")
	assert_eq(DayCycle.wake_time(DayCycle.NOON), DayCycle.SUNSET)
	assert_eq(DayCycle.wake_time(DayCycle.SUNRISE + 0.01), DayCycle.SUNSET, "after sunrise it is day")
	assert_eq(DayCycle.wake_time(DayCycle.DUSK_START + 0.01), DayCycle.SUNRISE, "getting dark: sleep until morning")


func test_nights_are_moonlit_and_never_pitch_black() -> void:
	var day := _brightness(DayCycle.look(DayCycle.NOON))
	for i in 480:
		var look := DayCycle.look(i / 480.0)
		assert_gte(look.ambient, DayCycle.NIGHT_AMBIENT, "ambient at t=%.3f" % (i / 480.0))
		assert_gt(_brightness(look), 0.2 * day, "never pitch black at t=%.3f" % (i / 480.0))
	var midnight := DayCycle.look(DayCycle.MIDNIGHT)
	assert_true(midnight.moon_up, "the moon lights the night")
	assert_gt(midnight.light_energy, 0.25, "moonlight")
	assert_gt((midnight.light_dir as Vector3).y, 0.8, "the moon is high at midnight")
	assert_lt(_brightness(midnight), 0.6 * day, "but it is clearly night")


func test_night_is_darker_and_bluer_than_day_with_stars_and_a_moon() -> void:
	var day := DayCycle.look(DayCycle.NOON)
	var night := DayCycle.look(DayCycle.MIDNIGHT)
	assert_false(day.moon_up)
	assert_lt(night.light_energy, day.light_energy)
	assert_lt(night.ambient, day.ambient)
	assert_lt((night.sky_top as Color).v, (day.sky_top as Color).v)
	assert_gt((night.fog_color as Color).b, (night.fog_color as Color).r, "night fog is blue")
	assert_gt((night.light_color as Color).b, (night.light_color as Color).r, "moonlight is blue")
	assert_eq(day.stars, 0.0)
	assert_eq(day.moon, 0.0)
	assert_gt(night.stars, 0.9)
	assert_gt(night.moon, 0.9)
	assert_lt(night.sky_energy, 0.3, "the realistic sky is dimmed at night")
	assert_eq(day.sky_energy, 1.0)


func test_sunset_glows_orange() -> void:
	var dusk := DayCycle.look(DayCycle.SUNSET)
	assert_gt((dusk.sky_horizon as Color).r, (dusk.sky_horizon as Color).b)
	assert_gt((dusk.fog_color as Color).r, (dusk.fog_color as Color).b)


func test_the_look_changes_smoothly() -> void:
	var prev := DayCycle.look(0.0)
	for i in range(1, 1201):
		var look := DayCycle.look(i / 1200.0)
		assert_lt(absf(look.ambient - prev.ambient), 0.05, "ambient step %d" % i)
		assert_lt(absf(look.sky_energy - prev.sky_energy), 0.05, "sky step %d" % i)
		assert_lt(absf(look.stars - prev.stars), 0.05, "stars step %d" % i)
		prev = look


func test_noon_matches_the_world_scene() -> void:
	var world: Node = load("res://world/world.tscn").instantiate()
	var env := (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	var sky := env.sky.sky_material as ProceduralSkyMaterial
	var sun := world.get_node("Sun") as DirectionalLight3D
	var noon := DayCycle.look(DayCycle.NOON)
	assert_true((noon.sky_top as Color).is_equal_approx(sky.sky_top_color), "sky top")
	assert_true((noon.sky_horizon as Color).is_equal_approx(sky.sky_horizon_color), "sky horizon")
	assert_true((noon.ground_bottom as Color).is_equal_approx(sky.ground_bottom_color), "ground bottom")
	assert_true((noon.ground_horizon as Color).is_equal_approx(sky.ground_horizon_color), "ground horizon")
	assert_true((noon.fog_color as Color).is_equal_approx(env.fog_light_color), "fog")
	assert_true((noon.ambient_color as Color).is_equal_approx(env.ambient_light_color), "ambient colour")
	assert_true((noon.light_color as Color).is_equal_approx(sun.light_color), "sunlight")
	assert_almost_eq(noon.sun_glow, sky.sun_angle_max, 0.001)
	assert_almost_eq(noon.light_energy, 1.0, 0.0001)
	assert_almost_eq(noon.ambient, 1.0, 0.0001)
	world.free()
