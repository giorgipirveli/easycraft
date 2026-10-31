extends GutTest
## Cosmos: Titan's methane (spec §21b.2: "lakes of liquid methane (swim: very floaty)"). Its lakes and sea are the game's
## WATER (they swim, flow and splash like water; never harmful: no water hurts in the game), shown as liquid methane in
## Titan's world (BlockLibrary.set_liquid: an amber, glassy liquid; under it the view turns amber, TitanRules.methane_mood).
## Very floaty (TitanRules): a swimmer at the surface who presses JUMP leaps out like a dolphin (a share of a jump's
## speed; in Titan's low gravity that is several blocks up and seconds in the air), then splashes back and may leap again
## after a short while in it. Anywhere else water stays water.


func after_each() -> void:
	BlockLibrary.set_liquid(&"")
	LabRules.world_gravity = 1.0


func test_only_methane_is_floaty() -> void:
	assert_true(TitanRules.floaty(TitanRules.METHANE))
	assert_true(TitanRules.floaty(&"methane"))
	for other: Variant in [&"", &"chocolate", null, "water", 5]:
		assert_false(TitanRules.floaty(other), str(other))


func test_jump_at_the_surface_leaps_out() -> void:
	var surface := SwimRules.FLOAT_DEPTH   # floating: the surface this far over the feet
	assert_true(TitanRules.leaps(true, true, surface, 1.0, 0.0), "JUMP at the surface of methane: a leap")
	assert_false(TitanRules.leaps(false, true, surface, 1.0, 0.0), "water: no leap (JUMP swims up as always)")
	assert_false(TitanRules.leaps(true, false, surface, 1.0, 0.0), "no JUMP, no leap")
	assert_false(TitanRules.leaps(true, true, 4.0, 1.0, 0.0), "deep under: JUMP swims up first")
	assert_false(TitanRules.leaps(true, true, surface, 1.0, 0.3), "not again straight away")
	assert_true(TitanRules.leaps(true, true, surface * 2.0, 2.0, 0.0), "a Giant floats deeper: its surface too")


func test_a_leap_is_very_floaty_in_titans_gravity() -> void:
	var v := TitanRules.leap_speed(Player.JUMP_VELOCITY)
	assert_lt(v, Player.JUMP_VELOCITY, "a share of a jump")
	var g := Player.GRAVITY * 0.14
	var up := v * v / (2.0 * g)
	assert_gt(up, 4.0, "out of the methane and well over it (%.1f blocks)" % up)
	assert_lt(up, Player.JUMP_VELOCITY * Player.JUMP_VELOCITY / (2.0 * g), "lower than a jump from the ground")
	var air := 2.0 * v / g
	assert_gt(air, 3.0, "seconds of float (%.1f s)" % air)
	assert_gt(TitanRules.LEAP_COOLDOWN, 0.0)
	assert_gt(TitanRules.LEAP_COAST, 0.0, "the liquid lets the leap go")
	var home := v * v / (2.0 * Player.GRAVITY)
	assert_lt(home, 1.5, "at home's gravity it would be a little hop (%.1f)" % home)


func test_the_view_under_methane_is_amber() -> void:
	var m := {"sun": 1.0, "ambient": 1.0, "fog_color": Color(0.2, 0.4, 0.7), "fog_begin": 10.0, "fog_end": 40.0,
		"lantern": 0.0, "tint": Color(0.1, 0.3, 0.6, 0.3)}
	assert_eq(TitanRules.methane_mood(m, 0.0), m, "out of it nothing changes")
	var under := TitanRules.methane_mood(m, 1.0)
	var fog: Color = under.fog_color
	var tint: Color = under.tint
	assert_gt(fog.r, fog.b, "amber fog (%s)" % fog)
	assert_gt(tint.r, tint.b, "an amber screen (%s)" % tint)
	assert_almost_eq(tint.a, 0.3, 0.001, "as strong as the water's own")


func test_the_water_looks_like_methane_in_titans_world_only() -> void:
	BlockLibrary.set_liquid(TitanRules.METHANE)
	assert_eq(BlockLibrary.liquid_methane(), 1.0)
	assert_eq(BlockLibrary.liquid_chocolate(), 0.0, "never chocolate")
	BlockLibrary.set_liquid(&"chocolate")
	assert_eq(BlockLibrary.liquid_methane(), 0.0)
	assert_eq(BlockLibrary.liquid_chocolate(), 1.0)
	BlockLibrary.set_liquid(&"")
	assert_eq(BlockLibrary.liquid_methane(), 0.0, "the next world's water is water again")
	assert_eq(BlockLibrary.liquid_chocolate(), 0.0)


func test_methane_is_never_harmful() -> void:
	assert_false(BlockIds.is_solid(BlockIds.WATER), "a swimmer's liquid")
	assert_false(PadRules.is_pad(BlockIds.WATER), "no throw, no bounce")
