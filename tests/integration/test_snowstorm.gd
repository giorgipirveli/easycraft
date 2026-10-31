extends GutTest
## M3 Task 3 (spec §14.1 "snowstorms hide everyone (visibility × 0.5 for monsters and players; the screen
## whitens)"): Frostpeak's snowstorms are the desert's storm code (SandstormDirector, SandstormRules) in
## snow: the same clock, warnings and ease; everyone outdoors half as visible to monsters; this game's view
## gets white fog at half the distance and a white screen; its own words and wind.

const FLOOR := 10

var _toasts: Array = []


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _storm() -> SandstormDirector:
	var s := SandstormDirector.new()
	s.name = "Snowstorm"
	s.snow = true
	s.toast = func(text: String) -> void: _toasts.append(text)
	add_child_autofree(s)
	s.set_process(false)
	return s


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func test_snow_has_its_own_words_and_wind() -> void:
	_toasts.clear()
	var s := _storm()
	s.start_host(12345)
	var t := 0.0
	while _toasts.size() < 3 and t < 2000.0:
		s.tick(0.5)
		t += 0.5
	assert_eq(_toasts, [SandstormRules.SNOW_WARN_TEXT, SandstormRules.SNOW_START_TEXT, SandstormRules.SNOW_END_TEXT])
	for w: String in _toasts:
		assert_string_contains(w.to_lower(), "snow")
	assert_eq(s.find_child("Wind", false, false).stream.resource_path, "res://assets/audio/sfx/snowstorm.wav")
	var sand := SandstormDirector.new()
	add_child_autofree(sand)
	assert_eq(sand.find_child("Wind", false, false).stream.resource_path, "res://assets/audio/sfx/sandstorm.wav",
		"the desert keeps its own")


func test_in_a_snowstorm_monsters_see_a_player_outdoors_half_as_well() -> void:
	var stealth := StealthDirector.new()
	add_child_autofree(stealth)
	stealth.block_at = func(p: Vector3i) -> int: return BlockIds.SNOW if p.y < FLOOR else BlockIds.AIR
	stealth.surface_height = func(_x: int, _z: int) -> int: return FLOOR
	stealth.time_of_day = func() -> float: return DayCycle.NOON
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	stealth.refresh(p)
	var clear := p.stealth_visibility()
	var s := _storm()
	s.start_host(1)
	s.force(true)
	for i in 10:
		s.follow(1.0)
	stealth.weather = s.visibility
	stealth.refresh(p)
	assert_almost_eq(p.stealth_visibility(), clear * 0.5, 0.001, "× 0.5 in a full snowstorm")


func test_the_view_whitens_and_closes_in_then_clears() -> void:
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	var p := _player(Vector3(0.5, 200, 0.5))
	var amb := Ambience.new()
	amb.world = world
	amb.player = p
	add_child_autofree(amb)
	amb._process(1.0)
	var env := world.environment()
	var clear_end := env.fog_depth_end
	amb.storm_snow = true
	amb.storm = 1.0
	for i in 5:
		amb._process(0.2)
	assert_almost_eq(env.fog_depth_end, clear_end * 0.5, 0.5, "players see half as far")
	var fog := env.fog_light_color
	assert_gt(minf(fog.r, minf(fog.g, fog.b)), 0.85, "white fog")
	var tint := amb.find_children("*", "ColorRect", true, false)[0] as ColorRect
	assert_true(tint.visible, "the screen whitens")
	assert_gt(minf(tint.color.r, minf(tint.color.g, tint.color.b)), 0.9, "white, not sandy")
	assert_gt(tint.color.a, SandstormRules.SAND_TINT.a, "whiter than a sandstorm's tint")
	amb.storm = 0.0
	for i in 5:
		amb._process(0.2)
	assert_almost_eq(env.fog_depth_end, clear_end, 0.5, "back to normal")
	assert_false(tint.visible)


func test_snow_mood_rules() -> void:
	var base := {"sun": 1.0, "ambient": 0.6, "fog_color": Color(0.7, 0.8, 1.0), "fog_begin": 90.0, "fog_end": 128.0,
		"lantern": 0.0, "tint": Color(0.1, 0.35, 0.75, 0.0)}
	var snow := SandstormRules.mood(base, 1.0, true)
	assert_almost_eq(float(snow.fog_end), 64.0, 0.01, "half the view")
	assert_true((snow.fog_color as Color).is_equal_approx(SandstormRules.SNOW_FOG))
	assert_true((snow.tint as Color).is_equal_approx(SandstormRules.SNOW_TINT))
	assert_eq(SandstormRules.mood(base, 1.0), SandstormRules.mood(base, 1.0, false), "sand by default")
