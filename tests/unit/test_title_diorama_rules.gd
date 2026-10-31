extends GutTest
## M5 Task 2 (spec §15.2): the living title diorama's 12 s loop, as plain numbers: the brand's buddy asleep on its
## island, the wand's star sparkles, it wakes (eyes pop open), hops and waves, the dog hops and wags, then it dozes
## off again; the island turns slowly. Floats only: the diorama reads them every frame without making anything.

const R := preload("res://core/rules/title_diorama_rules.gd")


func test_the_loop_is_twelve_seconds_and_seamless() -> void:
	assert_eq(R.LOOP, 12.0)
	for f: Callable in [R.eyes, R.buddy_lift, R.dog_lift, R.wave, R.sway]:
		assert_almost_eq(f.call(0.0), f.call(R.LOOP - 0.0001), 0.02, "no jump at the seam")
		assert_almost_eq(f.call(1.3), f.call(1.3 + R.LOOP), 0.0001, "it repeats")


func test_asleep_then_the_star_sparkles_then_awake_then_asleep_again() -> void:
	assert_lt(R.eyes(1.0), 0.2, "asleep: eyes shut")
	assert_lt(R.eyes(R.SPARKLE - 0.05), 0.2, "still asleep when the star sparkles")
	assert_almost_eq(R.eyes(7.0), 1.0, 0.001, "awake: eyes wide")
	assert_lt(R.eyes(R.LOOP - 0.3), 0.2, "dozes off again")
	assert_true(R.sparkles(R.SPARKLE - 0.1, R.SPARKLE + 0.1))
	assert_false(R.sparkles(0.0, R.SPARKLE - 0.1))
	assert_false(R.sparkles(R.SPARKLE + 0.1, R.LOOP))
	assert_true(R.sparkles(R.LOOP + R.SPARKLE - 0.05, R.LOOP + R.SPARKLE + 0.05), "every loop")


func test_it_hops_and_waves_once_awake_and_the_dog_joins_in() -> void:
	var hop := 0.0
	var dog := 0.0
	var wave := 0.0
	for i in 400:
		var t := R.LOOP * i / 400.0
		if t < R.SPARKLE:
			assert_almost_eq(R.buddy_lift(t), 0.0, 0.05, "no hopping in its sleep")
			assert_almost_eq(R.wave(t), 0.0, 0.001, "no waving in its sleep")
		hop = maxf(hop, R.buddy_lift(t))
		dog = maxf(dog, R.dog_lift(t))
		wave = maxf(wave, absf(R.wave(t)))
	assert_gt(hop, 0.3, "a hop of joy")
	assert_gt(dog, 0.2, "the dog hops too")
	assert_gt(wave, 0.5, "it waves")
	assert_gte(R.buddy_lift(1.0), 0.0, "never sinks into the island")


func test_it_breathes_in_its_sleep_and_the_dog_wags() -> void:
	var lo := INF
	var hi := -INF
	for i in 40:
		var b := R.breath(1.0 + i * 0.05)
		lo = minf(lo, b)
		hi = maxf(hi, b)
	assert_gt(hi - lo, 0.02, "a slow breath")
	assert_lt(hi - lo, 0.12)
	assert_ne(R.wag(6.0), R.wag(6.1), "the tail moves")
	assert_gt(absf(R.wag(6.05)) + absf(R.wag(6.15)), 0.1)


func test_the_island_turns_slowly_both_ways() -> void:
	var lo := INF
	var hi := -INF
	for i in 120:
		var s := R.sway(R.LOOP * i / 120.0)
		lo = minf(lo, s)
		hi = maxf(hi, s)
	assert_lt(lo, -0.1)
	assert_gt(hi, 0.1)
	assert_lt(maxf(-lo, hi), 0.45, "slow and gentle")
