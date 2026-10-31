extends GutTest
## Ambience by place and time (the audio pass, owner feedback #27; spec §15.2 "ambient loops per biome"):
## birds by day, crickets at night, drips in caves, waves by the sea, wind up on the peaks (and in the
## desert by day); quiet under water and in a sandstorm (it has its own wind). A universe can name its own.


func _ctx(extra: Dictionary = {}) -> Dictionary:
	var c := {"time": DayCycle.NOON, "underground": 0.0, "underwater": 0.0, "storm": 0.0, "height": 10.0, "sea": 0.0,
		"own": {}}
	c.merge(extra, true)
	return c


func test_birds_by_day_and_crickets_at_night() -> void:
	assert_eq(AmbienceSoundRules.choose(_ctx()), &"birds")
	assert_eq(AmbienceSoundRules.choose(_ctx({"time": DayCycle.MIDNIGHT})), &"crickets")
	assert_eq(AmbienceSoundRules.choose(_ctx({"time": DayCycle.SUNSET + 0.01})), &"crickets")
	assert_eq(AmbienceSoundRules.choose(_ctx({"time": DayCycle.SUNRISE + 0.01})), &"birds")


func test_drips_in_caves_by_day_and_night() -> void:
	assert_eq(AmbienceSoundRules.choose(_ctx({"underground": 1.0})), &"drips")
	assert_eq(AmbienceSoundRules.choose(_ctx({"underground": 0.8, "time": DayCycle.MIDNIGHT})), &"drips")
	assert_eq(AmbienceSoundRules.choose(_ctx({"underground": 0.2})), &"birds", "just inside the cave mouth")


func test_waves_by_the_sea() -> void:
	assert_eq(AmbienceSoundRules.choose(_ctx({"sea": 0.6})), &"waves")
	assert_eq(AmbienceSoundRules.choose(_ctx({"sea": 0.6, "time": DayCycle.MIDNIGHT})), &"waves")
	assert_eq(AmbienceSoundRules.choose(_ctx({"sea": 0.1})), &"birds", "a pond is not the sea")


func test_wind_up_on_the_peaks_and_flying_high() -> void:
	assert_eq(AmbienceSoundRules.choose(_ctx({"height": AmbienceSoundRules.PEAK_HEIGHT + 1.0})), &"wind")
	assert_eq(AmbienceSoundRules.choose(_ctx({"height": AmbienceSoundRules.PEAK_HEIGHT + 1.0, "sea": 1.0})), &"wind")


func test_quiet_under_water_and_in_a_sandstorm() -> void:
	assert_eq(AmbienceSoundRules.choose(_ctx({"underwater": 1.0})), &"")
	assert_eq(AmbienceSoundRules.choose(_ctx({"storm": 0.8})), &"", "the sandstorm has its own wind")


func test_a_universe_names_its_own_ambience() -> void:
	var desert := {"day": "wind", "night": "crickets"}
	assert_eq(AmbienceSoundRules.choose(_ctx({"own": desert})), &"wind")
	assert_eq(AmbienceSoundRules.choose(_ctx({"own": desert, "time": DayCycle.MIDNIGHT})), &"crickets")
	assert_eq(AmbienceSoundRules.choose(_ctx({"own": {"day": "nonsense"}})), &"birds", "unknown loops are ignored")
	assert_eq(AmbienceSoundRules.choose(_ctx({"own": desert, "underground": 1.0})), &"drips", "caves are caves")


func test_every_loop_exists_and_loops() -> void:
	for id: StringName in AmbienceSoundRules.LOOPS:
		var stream := load(AmbienceSoundRules.path(id)) as AudioStreamOggVorbis
		assert_not_null(stream, String(id))
		if stream:
			assert_true(stream.loop, "%s loops" % id)
			assert_gt(stream.get_length(), 20.0, String(id))


func test_the_desert_names_its_ambience() -> void:
	var own := UniverseRegistry.ambience(2)
	assert_eq(StringName(str(own.get("day", ""))), &"wind")
