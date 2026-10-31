extends GutTest
## M5 Task 2 (spec §15.2): Frostpeak's and the Candy Kingdom's own ambience and classical pieces. Frostpeak: a cold
## wind by day, a quiet snowy pine forest at night, Vivaldi's Winter and Debussy's The Snow Is Dancing; the Candy
## Kingdom: wind chimes by day, the chocolate river's brook at night, the Nutcracker's Waltz of the Flowers and Chopin's
## Minute Waltz. A universe's own piece plays only there (MusicPieces "own": a favourite), never in the menu or
## elsewhere.


func test_frostpeak_and_the_candy_kingdom_have_their_own_ambience() -> void:
	assert_eq(UniverseRegistry.ambience(3), {"day": &"snow_wind", "night": &"snow_night"})
	assert_eq(UniverseRegistry.ambience(4), {"day": &"chimes", "night": &"brook"})
	for id: StringName in [&"snow_wind", &"snow_night", &"chimes", &"brook"]:
		assert_true(AmbienceSoundRules.LOOPS.has(id), String(id))
		var stream := load(AmbienceSoundRules.path(id)) as AudioStreamOggVorbis
		assert_not_null(stream, String(id))
		if stream:
			assert_true(stream.loop, "%s loops" % id)
			assert_lte(FileAccess.get_file_as_bytes(AmbienceSoundRules.path(id)).size(), 400 * 1024, "%s is small" % id)


func test_frostpeak_and_the_candy_kingdom_have_their_own_pieces() -> void:
	var frost := UniverseRegistry.classical(3)
	assert_eq(frost, [&"winter_largo", &"snow_dancing"] as Array[StringName])
	var candy := UniverseRegistry.classical(4)
	assert_true(candy.has(&"minute_waltz"))
	for id: StringName in [&"winter_largo", &"snow_dancing", &"minute_waltz"]:
		assert_true(MusicPieces.is_own(id), "%s is a universe's own" % id)
		var stream := load(MusicPieces.path(id)) as AudioStreamOggVorbis
		assert_not_null(stream, String(id))
		if stream:
			assert_false(stream.loop, "a piece plays once")
			assert_almost_eq(stream.get_length(), MusicPieces.length(id), 1.0, String(id))
	assert_false(MusicPieces.is_own(&"waltz_flowers"), "the Waltz of the Flowers plays everywhere, as before")


func _picks(favourites: Array[StringName], mood: StringName, n: int) -> Dictionary:
	var plan := MusicPlan.new(7)
	plan.set_style(MusicPlan.CLASSICAL)
	plan.favourites = favourites
	var seen := {}
	plan.update(mood, 0.0)
	for i in n:
		if MusicPieces.has(plan.cue):
			seen[plan.cue] = true
		plan.skip()
	return seen


func test_a_universes_own_piece_plays_only_there() -> void:
	var elsewhere := _picks([], MusicPlan.DAY, 200)
	for id: StringName in elsewhere:
		assert_false(MusicPieces.is_own(id), "%s never plays outside its universe" % id)
	var menu := _picks([], MusicPlan.MENU, 100)
	for id: StringName in menu:
		assert_false(MusicPieces.is_own(id), "nor in the menu: %s" % id)
	var frost := _picks([&"winter_largo", &"snow_dancing"], MusicPlan.DAY, 60)
	assert_true(frost.has(&"winter_largo") and frost.has(&"snow_dancing"), "Frostpeak plays its own")
	assert_false(frost.has(&"minute_waltz"), "and never the kingdom's")
