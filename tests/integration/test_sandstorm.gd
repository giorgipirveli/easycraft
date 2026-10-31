extends GutTest
## M3 Task 2 (spec §14.1): sandstorms in a desert world. The host's clock warns, blows and ends storms
## (every game hears it); the storm eases in; in a full storm a player outdoors is half as visible to
## monsters (the StealthDirector's light), but not deep in a cave; this game's view gets sandy fog at half
## the distance and a sandy tint (Ambience), and goes back to normal after.

const FLOOR := 10

var _toasts: Array = []


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _storm() -> SandstormDirector:
	var s := SandstormDirector.new()
	s.name = "Sandstorm"
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


func test_the_host_warns_then_a_storm_blows_then_it_ends() -> void:
	_toasts.clear()
	var s := _storm()
	s.start_host(12345)
	var seen: Array = []
	s.storm_changed.connect(func(on: bool, warning: bool) -> void: seen.append([on, warning]))
	var t := 0.0
	while seen.size() < 3 and t < 2000.0:
		s.tick(0.5)
		t += 0.5
	assert_eq(seen, [[false, true], [true, false], [false, false]], "warning, storm, calm")
	assert_eq(_toasts, [SandstormRules.WARN_TEXT, SandstormRules.START_TEXT, SandstormRules.END_TEXT])
	assert_gte(t, SandstormRules.FIRST_CALM, "a visit starts calm")


func test_the_storm_eases_in_and_the_wind_blows() -> void:
	var s := _storm()
	s.start_host(7)
	var views: Array = []
	s.apply_view = func(x: float) -> void: views.append(x)
	s.force(true)
	s.follow(1.0)
	assert_almost_eq(s.strength, SandstormRules.RATE, 0.001, "blowing up")
	for i in 10:
		s.follow(1.0)
	assert_eq(s.strength, 1.0)
	assert_eq(views[-1], 1.0, "the view follows it")
	assert_almost_eq(s.visibility(), 0.5, 0.001, "half as visible outdoors")
	assert_almost_eq(s.visibility(1.0), 1.0, 0.001, "deep in a cave: no storm")
	s.force(false)
	for i in 10:
		s.follow(1.0)
	assert_eq(s.strength, 0.0)
	assert_eq(views[-1], 0.0)


func test_in_a_storm_monsters_see_a_player_outdoors_half_as_well() -> void:
	var stealth := StealthDirector.new()
	add_child_autofree(stealth)
	stealth.block_at = func(p: Vector3i) -> int: return BlockIds.SAND if p.y < FLOOR else BlockIds.AIR
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
	assert_almost_eq(p.stealth_visibility(), clear * 0.5, 0.001, "× 0.5 in a full storm")
	var cave := StealthDirector.new()
	add_child_autofree(cave)
	cave.block_at = func(c: Vector3i) -> int: return BlockIds.STONE if c.y < FLOOR + 20 and c.y > FLOOR + 2 else BlockIds.AIR
	cave.surface_height = func(_x: int, _z: int) -> int: return FLOOR + 20
	cave.time_of_day = func() -> float: return DayCycle.NOON
	cave.weather = s.visibility
	cave.refresh(p)
	var deep := p.stealth_light
	cave.weather = Callable()
	cave.refresh(p)
	assert_almost_eq(deep, p.stealth_light, 0.001, "deep under the rock the storm doesn't reach")


func test_the_view_turns_sandy_and_closes_in_then_clears() -> void:
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
	amb.storm = 1.0
	for i in 5:
		amb._process(0.2)
	assert_almost_eq(env.fog_depth_end, clear_end * 0.5, 0.5, "half the view distance")
	var tint := amb.find_children("*", "ColorRect", true, false)[0] as ColorRect
	assert_true(tint.visible, "the screen is tinted")
	assert_almost_eq(tint.color.r, SandstormRules.SAND_TINT.r, 0.01)
	amb.storm = 0.0
	for i in 5:
		amb._process(0.2)
	assert_almost_eq(env.fog_depth_end, clear_end, 0.5, "back to normal")
	assert_false(tint.visible)
