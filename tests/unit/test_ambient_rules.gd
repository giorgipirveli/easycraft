extends GutTest
## Owner #94 (the animations brief §2): the world's ambient life follows its rules: fireflies over the meadow at night
## only, birds high by day only, each bird round its own circle flying forwards and flapping then gliding, leaves and
## petals from the blocks that have them, a blinking light's rhythm and a flag's wave.


func test_fireflies_at_night_over_the_meadow_only() -> void:
	assert_true(LifeRules.fireflies_on(0.95, 0.0, BlockIds.GRASS), "a meadow at night")
	assert_true(LifeRules.fireflies_on(0.0, 0.0, BlockIds.BUSH), "by the bushes")
	assert_false(LifeRules.fireflies_on(DayCycle.NOON, 0.0, BlockIds.GRASS), "not by day")
	assert_false(LifeRules.fireflies_on(0.95, 0.8, BlockIds.GRASS), "not in a cave")
	assert_false(LifeRules.fireflies_on(0.95, 0.0, BlockIds.SAND), "not over the beach")


func test_birds_by_day_under_the_open_sky() -> void:
	assert_true(LifeRules.birds_on(DayCycle.NOON, 0.0))
	assert_false(LifeRules.birds_on(0.95, 0.0), "they roost at night")
	assert_false(LifeRules.birds_on(DayCycle.NOON, 0.9), "not seen from a cave")


func test_each_bird_flies_forwards_round_its_own_circle() -> void:
	for i in LifeRules.BIRDS:
		for step in 20:
			var t := step * 0.37
			var at := LifeRules.bird_at(i, t)
			var flat := Vector2(at.x, at.z).length()
			assert_between(flat, LifeRules.FLOCK_RADIUS.x - 0.01, LifeRules.FLOCK_RADIUS.y + 0.01, "round the middle")
			assert_between(at.y, -4.0, 4.0, "about the flock's height")
			var ahead := LifeRules.bird_at(i, t + 0.02) - at
			var forward := Basis(Vector3.UP, LifeRules.bird_heading(i, t)) * Vector3.FORWARD
			assert_gt(forward.dot(ahead.normalized()), 0.9, "bird %d faces where it flies" % i)
			assert_between(LifeRules.bird_flap(i, t), -0.6, 0.8)
	assert_ne(LifeRules.bird_at(0, 1.0), LifeRules.bird_at(1, 1.0), "not in one spot")


func test_leaves_and_petals_come_from_trees_bushes_and_flowers() -> void:
	for b: int in [BlockIds.LEAVES, BlockIds.BIRCH_LEAVES, BlockIds.PALM_LEAVES, BlockIds.BUSH, BlockIds.FLOWERS]:
		assert_true(LifeRules.flutters(b), "block %d" % b)
	for b: int in [BlockIds.STONE, BlockIds.DIRT, BlockIds.LOG, BlockIds.GLASS]:
		assert_false(LifeRules.flutters(b), "block %d" % b)


func test_a_blinking_light_is_on_a_share_of_every_period() -> void:
	var on := 0
	for i in 120:
		if Blinker.lit_at(i * Blinker.PERIOD / 120.0):
			on += 1
	assert_almost_eq(on / 120.0, Blinker.ON_SHARE, 0.02)
	assert_true(Blinker.lit_at(0.0), "on at once")


func test_a_flag_s_wave_runs_along_it() -> void:
	var t := 0.8
	assert_ne(WavingFlag.turn_of(0, t), WavingFlag.turn_of(3, t), "the strips turn at different moments")
	for i in WavingFlag.STRIPS:
		for k in 10:
			assert_lt(absf(WavingFlag.turn_of(i, k * 0.3)), WavingFlag.SWING + 0.001, "gently")
