extends GutTest
## M3 Task 2 (spec §14.1 "sandstorms that lower visibility"; the brief: visibility × 0.5 for monsters and
## players, the screen tinted): the Sandstorm Desert's weather as pure rules. Calm spells and storms take
## turns (a warning first, so a child can find shelter); in a full storm everyone outdoors is half as
## visible to monsters, the fog comes in to half the view distance and the screen turns sandy; under a roof
## deep in the rock (a cave, a pyramid) the storm doesn't reach.

func test_calm_and_storm_take_turns_the_same_way_every_time() -> void:
	for n in 20:
		var spell := SandstormRules.spell(12345, n)
		assert_between(spell.x, SandstormRules.CALM_MIN, SandstormRules.CALM_MAX, "calm %d" % n)
		assert_between(spell.y, SandstormRules.STORM_MIN, SandstormRules.STORM_MAX, "storm %d" % n)
		assert_eq(SandstormRules.spell(12345, n), spell, "from the seed")
	assert_ne(SandstormRules.spell(12345, 0), SandstormRules.spell(12346, 0))
	assert_gt(SandstormRules.CALM_MIN, SandstormRules.STORM_MAX, "mostly calm: storms are an event")
	assert_gte(SandstormRules.WARNING, 8.0, "time to find shelter")


func test_a_full_storm_halves_how_visible_everyone_is() -> void:
	assert_eq(SandstormRules.visibility(0.0), 1.0)
	assert_eq(SandstormRules.visibility(1.0), 0.5)
	assert_almost_eq(SandstormRules.visibility(0.5), 0.75, 0.001)
	assert_eq(SandstormRules.visibility(1.0, 1.0), 1.0, "deep underground: no storm")
	assert_almost_eq(SandstormRules.visibility(1.0, 0.5), 0.75, 0.001)


func test_the_view_closes_in_to_half_and_turns_sandy() -> void:
	var base := {"sun": 1.0, "ambient": 0.6, "fog_color": Color(0.7, 0.8, 1.0), "fog_begin": 90.0, "fog_end": 128.0,
		"lantern": 0.0, "tint": Color(0.1, 0.35, 0.75, 0.0)}
	var calm := SandstormRules.mood(base, 0.0)
	assert_eq(calm, base, "no storm: the view is untouched")
	var storm := SandstormRules.mood(base, 1.0)
	assert_almost_eq(float(storm.fog_end), 64.0, 0.01, "half the view")
	assert_lt(float(storm.fog_begin), float(base.fog_begin) * 0.5)
	assert_true((storm.fog_color as Color).is_equal_approx(SandstormRules.SAND_FOG), "sandy fog")
	assert_gt((storm.tint as Color).a, 0.1, "the screen is tinted")
	assert_almost_eq((storm.tint as Color).r, SandstormRules.SAND_TINT.r, 0.001)
	assert_lt(float(storm.sun), float(base.sun), "the sun is dimmer")
	var under_water := base.duplicate()
	under_water.tint = Color(0.1, 0.35, 0.75, 0.28)
	assert_eq(SandstormRules.mood(under_water, 1.0).tint, under_water.tint, "under water the water's own view wins")


func test_the_storm_eases_in_and_out() -> void:
	assert_almost_eq(SandstormRules.approach(0.0, true, 1.0), SandstormRules.RATE, 0.001)
	assert_eq(SandstormRules.approach(0.95, true, 1.0), 1.0)
	assert_eq(SandstormRules.approach(0.05, false, 1.0), 0.0)
	assert_gte(1.0 / SandstormRules.RATE, 3.0, "it takes a few seconds to blow up")


func test_words() -> void:
	for w in [SandstormRules.WARN_TEXT, SandstormRules.START_TEXT, SandstormRules.END_TEXT]:
		assert_ne(w, "")
		assert_lt(w.length(), 60, "short: %s" % w)
