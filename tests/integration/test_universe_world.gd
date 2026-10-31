extends GutTest
## M3 Task 5 (spec §14.1): a Survivor world belongs to a universe. Its save slot is the universe's
## (Game.slot), its terrain comes from the universe's descriptor (WorldService), its music and daytime
## sky too; a LAN guest takes the host's universe; the world remembers which universe it is.

const FAKE := preload("res://tests/fakes/fake_universe.gd")
var DIR := "user://test_universe_world_%d/" % OS.get_process_id()

var _mode: StringName
var _universe := 1


func before_each() -> void:
	_mode = Game.mode
	_universe = Game.universe


func after_each() -> void:
	Game.mode = _mode
	Game.universe = _universe
	UniverseRegistry.reset()
	Music.use_tracks({})
	Music.reset()


func after_all() -> void:
	var abs_dir := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		for f in DirAccess.get_files_at(abs_dir):
			DirAccess.remove_absolute(abs_dir.path_join(f))
		DirAccess.remove_absolute(abs_dir)


func test_the_save_slot_follows_the_universe() -> void:
	Game.mode = ModeRules.SURVIVOR
	Game.universe = 1
	assert_eq(Game.slot(), "survivor_1", "M2's Survivor world is universe 1's")
	Game.universe = 3
	assert_eq(Game.slot(), "survivor_u3")
	Game.mode = ModeRules.SANDBOX
	assert_eq(Game.slot(), "sandbox_3", "owner 39: a Sandbox world per universe")
	Game.universe = 1
	assert_eq(Game.slot(), "sandbox_1", "M1's Sandbox world is universe 1's")


func test_a_world_of_another_universe_has_that_universes_ground() -> void:
	UniverseRegistry.use(2, FAKE.new())
	DirAccess.make_dir_recursive_absolute(DIR)
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup(DIR, 77, false, 2)
	add_child_autofree(world)
	assert_eq(world.universe, 2)
	assert_eq(world.surface_height(10, 20), FAKE.HEIGHT, "the descriptor's shape")
	assert_eq(world.spawn_column(), Vector2i(3, 5))
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.position = Vector3(0, FAKE.HEIGHT, 0)
	world.add_child(viewer)
	var below := Vector3i(1, FAKE.HEIGHT - 1, 1)
	await wait_until(func() -> bool: return world.is_editable(below), 10.0, "terrain loads")
	assert_eq(world.get_block(below), BlockIds.STONE, "the descriptor's generator made the ground")
	assert_eq(world.get_block(below + Vector3i(0, 2, 0)), BlockIds.AIR)


func test_a_world_without_a_universe_is_green_meadows() -> void:
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	assert_eq(world.universe, 1)
	assert_eq(world.surface_height(10, 20), MeadowsShape.new(42).height_at(10, 20))


func test_a_universe_brings_its_music_and_meadows_puts_it_back() -> void:
	var night: AudioStream = Music.player(MusicRules.NIGHT).stream
	var day: AudioStream = Music.player(MusicRules.DAY).stream
	Music.use_tracks({"day": "res://assets/music/night.ogg"})
	assert_eq(Music.player(MusicRules.DAY).stream.resource_path, night.resource_path, "the universe's day loop")
	assert_eq(Music.player(MusicRules.NIGHT).stream, night, "a track it doesn't name stays")
	Music.use_tracks({})
	assert_eq(Music.player(MusicRules.DAY).stream, day, "Green Meadows' day loop again")


func test_a_broken_music_path_keeps_the_default_track() -> void:
	var day: AudioStream = Music.player(MusicRules.DAY).stream
	Music.use_tracks({"day": "res://no/such/track.ogg", "disco": "res://assets/music/boss.ogg"})
	assert_eq(Music.player(MusicRules.DAY).stream, day)


func test_the_daytime_sky_takes_the_universes_colours() -> void:
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	var sky := SkyCycle.new()
	sky.world = world
	sky.palette = {"sky_top": Color(1.0, 0.6, 0.3), "sky_horizon": Color(0.9, 0.8, 0.6)}
	add_child_autofree(sky)
	sky.set_time(DayCycle.NOON)
	var blocky := world.environment().sky.sky_material as ProceduralSkyMaterial
	assert_true(blocky.sky_top_color.is_equal_approx(Color(1.0, 0.6, 0.3)), "noon: the universe's sky")
	assert_true(blocky.sky_horizon_color.is_equal_approx(Color(0.9, 0.8, 0.6)), "and its horizon")
	# the visuals brief (docs/devlog/parts/visuals.md): the haze is the horizon's colour (DayCycle.sky_meets_fog)
	assert_true((world.ambience_base.fog_color as Color).is_equal_approx(Color(0.9, 0.8, 0.6)), "and its haze")
	assert_true(blocky.ground_bottom_color.is_equal_approx(Color(0.9, 0.8, 0.6)), "the sky under the horizon too")
	sky.set_time(DayCycle.MIDNIGHT)
	assert_true(blocky.sky_top_color.is_equal_approx(DayCycle.look(DayCycle.MIDNIGHT).sky_top), "the night stays the night's")


func test_a_lan_guest_takes_the_hosts_universe() -> void:
	Game.universe = 1
	Session._rpc_m3_universe(3)
	assert_eq(Game.universe, 3)
	Session._rpc_m3_universe(-4)
	assert_eq(Game.universe, 1, "nonsense reads as Green Meadows")


func test_the_world_remembers_its_universe() -> void:
	var m := WorldMeta.new_random()
	assert_eq(m.universe, 1, "worlds saved before M3 are Green Meadows")
	m.universe = 3
	assert_eq(WorldMeta.from_json(m.to_json()).universe, 3)
	assert_eq(WorldMeta.from_json('{"seed": 5, "universe": "desert"}').universe, 1)
	assert_eq(WorldMeta.from_json('{"seed": 5, "universe": 1e30}').universe, UniverseRules.MAX_UNIVERSE)
	assert_eq(WorldMeta.from_json('{"seed": 5, "universe": -2}').universe, 1)


func test_the_developer_arg_picks_a_universe() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	assert_eq(main.call(&"_universe_arg", ["--survivor", "--new-world", "--universe=2"]), 2)
	assert_eq(main.call(&"_universe_arg", ["--survivor"]), 1, "Green Meadows without it")
	assert_eq(main.call(&"_universe_arg", ["--universe=banana"]), 1)
