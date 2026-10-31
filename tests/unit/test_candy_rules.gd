extends GutTest
## M3 Task 4 (spec §14.1): the Candy Kingdom's world rules. Gumdrops are bouncy: landing on one from a fall
## bounces you back up (walking over them does not); sprinkles fall at night under the open sky; the water is
## chocolate here: under it the view is brown, not blue (the rivers swim like any water).


func test_landing_on_a_gumdrop_bounces_you_back_up() -> void:
	assert_eq(CandyRules.gumdrop_bounce(2.0), 0.0, "walking and small steps never bounce")
	assert_eq(CandyRules.gumdrop_bounce(CandyRules.BOUNCE_FROM - 0.01), 0.0)
	var jump := CandyRules.gumdrop_bounce(Player.JUMP_VELOCITY)
	assert_almost_eq(jump, Player.JUMP_VELOCITY * CandyRules.BOUNCE_KEEP, 0.001, "a jump's landing bounces most of it back")
	assert_lt(jump, Player.JUMP_VELOCITY, "each bounce is a little lower: it always settles")
	assert_eq(CandyRules.gumdrop_bounce(80.0), CandyRules.BOUNCE_MAX, "never higher than a trampoline")
	assert_true(CandyRules.is_gumdrop(BlockIds.GUMDROP))
	assert_true(CandyRules.is_gumdrop(BlockIds.RED_GUMDROP))
	assert_false(CandyRules.is_gumdrop(BlockIds.FROSTING))


## A bounce settles: bounce after bounce the height falls until it stops.
func test_bounces_settle() -> void:
	var v := 12.0
	var n := 0
	while v > 0.0 and n < 50:
		v = CandyRules.gumdrop_bounce(v)
		n += 1
	assert_lt(n, 10, "it stops bouncing by itself")


func test_sprinkles_fall_at_night_under_the_open_sky() -> void:
	assert_true(CandyRules.sprinkles_on(DayCycle.MIDNIGHT, 0.0))
	assert_false(CandyRules.sprinkles_on(DayCycle.NOON, 0.0), "not in the day")
	assert_false(CandyRules.sprinkles_on(DayCycle.MIDNIGHT, 0.8), "not in a cave")
	assert_true(CandyRules.sprinkles_on(DayCycle.MIDNIGHT, 0.2), "under a roof by the surface still sees them")


func test_under_chocolate_the_view_is_brown() -> void:
	var base := {"sun": 1.0, "ambient": 1.0, "fog_color": Color(0.7, 0.8, 1.0), "fog_begin": 40.0, "fog_end": 120.0}
	var water := AmbienceRules.mood(0.0, 1.0, base)
	var choc := CandyRules.chocolate_mood(water, 1.0)
	assert_true((choc.fog_color as Color).is_equal_approx(CandyRules.CHOCOLATE_FOG), "chocolate fog")
	assert_eq(Color(choc.tint, 1.0), Color(CandyRules.CHOCOLATE_TINT, 1.0))
	assert_almost_eq((choc.tint as Color).a, (water.tint as Color).a, 0.001, "as strong as the water's tint")
	assert_eq(choc.fog_end, water.fog_end, "as far to see as in water")
	var dry := AmbienceRules.mood(0.0, 0.0, base)
	assert_eq(CandyRules.chocolate_mood(dry, 0.0), dry, "out of it nothing changes")
