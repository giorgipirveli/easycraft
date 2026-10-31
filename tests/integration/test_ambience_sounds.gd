extends GutTest
## The ambience loops in a world (the audio pass, owner feedback #27): two players cross-fade between the
## loop AmbienceSoundRules picks for the place and time; a silent loop stops (nothing decodes); caves also
## tell Music (the cave mood). Driven by hand (tick) with made-up surroundings.

var amb: AmbienceSounds


func before_each() -> void:
	amb = AmbienceSounds.new()
	add_child_autofree(amb)
	amb.set_process(false)


func after_each() -> void:
	Music.set_underground(false)


func _ctx(extra: Dictionary = {}) -> Dictionary:
	var c := {"time": DayCycle.NOON, "underground": 0.0, "underwater": 0.0, "storm": 0.0, "height": 5.0, "sea": 0.0,
		"own": {}}
	c.merge(extra, true)
	return c


func _playing() -> Array[StringName]:
	var out: Array[StringName] = []
	for i in AmbienceSounds.PLAYERS:
		if amb.player(i).playing:
			out.append(amb.loop_on(i))
	return out


func test_birds_fade_in_by_day() -> void:
	amb.tick(0.0, _ctx())
	assert_eq(amb.chosen, &"birds")
	assert_eq(_playing(), [&"birds"] as Array[StringName])
	var p := amb.player(amb.index_of(&"birds"))
	assert_eq(p.bus, Audio.BUS, "ambience is a sound effect (the SOUND EFFECTS volume)")
	assert_lt(p.volume_db, -40.0, "starts silent")
	amb.tick(AmbienceSounds.FADE, _ctx())
	assert_almost_eq(p.volume_db, AmbienceSoundRules.volume_db(&"birds"), 0.01, "fully in")


func test_nightfall_crossfades_birds_into_crickets_and_stops_the_birds() -> void:
	amb.tick(AmbienceSounds.FADE, _ctx())
	amb.tick(AmbienceSounds.FADE / 2.0, _ctx({"time": DayCycle.MIDNIGHT}))
	assert_eq(amb.chosen, &"crickets")
	var both := _playing()
	assert_true(both.has(&"birds") and both.has(&"crickets"), "both during the fade: %s" % [both])
	amb.tick(AmbienceSounds.FADE, _ctx({"time": DayCycle.MIDNIGHT}))
	assert_eq(_playing(), [&"crickets"] as Array[StringName], "the silent birds stopped")


func test_never_more_than_two_loops_even_when_the_place_changes_fast() -> void:
	for extra: Dictionary in [{}, {"underground": 1.0}, {"sea": 1.0}, {"height": 99.0}, {"time": DayCycle.MIDNIGHT}, {}]:
		amb.tick(0.3, _ctx(extra))
		assert_lte(_playing().size(), AmbienceSounds.PLAYERS)
	assert_eq(amb.get_child_count(), AmbienceSounds.PLAYERS, "no player is ever added")


func test_under_water_everything_fades_away() -> void:
	amb.tick(AmbienceSounds.FADE, _ctx())
	amb.tick(AmbienceSounds.FADE + 0.1, _ctx({"underwater": 1.0}))
	assert_eq(amb.chosen, &"")
	assert_eq(_playing(), [] as Array[StringName])


func test_caves_drip_and_tell_the_music() -> void:
	amb.tick(0.1, _ctx({"underground": 0.9}))
	assert_eq(amb.chosen, &"drips")
	assert_true(amb.in_cave())
	amb.tick(0.1, _ctx({"underground": 0.45}))
	assert_true(amb.in_cave(), "a little hysteresis: no flicker at the cave mouth")
	amb.tick(0.1, _ctx({"underground": 0.1}))
	assert_false(amb.in_cave())


func test_leaving_the_world_stops_the_loops_and_the_cave_mood() -> void:
	amb.tick(AmbienceSounds.FADE, _ctx({"underground": 1.0}))
	var p := amb.player(0)
	remove_child(amb)
	assert_false(amb.in_cave())
	assert_false(p.playing)
	add_child(amb)
