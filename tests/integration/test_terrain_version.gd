extends GutTest
## Owner feedback #45b (spec §14.18): only edited chunks are saved, the rest is generated from the seed again every
## time, so a world keeps the terrain it was made with. WorldMeta.terrain: 1 is the M1-M3 Green Meadows (every world
## saved before, forever), 2 the wild meadows (new worlds). The universe's descriptor makes the terrain of the
## world's version; a guest gets the host's version before the world; the other universes keep theirs.

var _terrain := 1


func before_each() -> void:
	_terrain = Session.world_terrain


func after_each() -> void:
	Session.world_terrain = _terrain
	UniverseRegistry.reset()


func test_a_new_world_is_wild_and_a_world_saved_before_stays_as_it_was() -> void:
	assert_eq(WorldMeta.TERRAIN_LATEST, MeadowsBiomeShape.TERRAIN)
	assert_eq(WorldMeta.new_random().terrain, 2, "a new world gets the wild meadows")
	assert_eq(WorldMeta.from_json('{"seed": 5}').terrain, 1, "a world saved before keeps the old meadows")
	assert_eq(WorldMeta.new().terrain, 1)
	var m := WorldMeta.new_random()
	assert_eq(WorldMeta.from_json(m.to_json()).terrain, 2, "saved and loaded")
	m.terrain = 1
	assert_eq(WorldMeta.from_json(m.to_json()).terrain, 1)
	for bad in ['"wild"', "0", "-3", "99", "1e30", "2.5", "true"]:
		assert_eq(WorldMeta.from_json('{"seed": 5, "terrain": %s}' % bad).terrain, 1, "nonsense reads as the old meadows: %s" % bad)


func test_green_meadows_terrain_follows_the_version() -> void:
	assert_true(UniverseRegistry.shape_for(1, 12345).get_script() == MeadowsShape, "version 1 by default")
	assert_true(UniverseRegistry.shape_for(1, 12345, 1).get_script() == MeadowsShape)
	assert_true(UniverseRegistry.shape_for(1, 12345, 2) is MeadowsBiomeShape)
	assert_true(UniverseRegistry.generator_for(1, 12345, 1).get_script() == MeadowsGenerator)
	assert_true(UniverseRegistry.generator_for(1, 12345, 2) is MeadowsBiomeGenerator)
	assert_eq((UniverseRegistry.generator_for(1, 777, 2) as MeadowsBiomeGenerator).world_seed, 777)


func test_the_other_universes_keep_their_terrain() -> void:
	assert_true(UniverseRegistry.shape_for(2, 5, 2) is DesertShape)
	assert_true(UniverseRegistry.generator_for(2, 5, 2) is DesertGenerator)
	assert_true(UniverseRegistry.shape_for(3, 5, 2) is FrostShape)
	assert_true(UniverseRegistry.shape_for(4, 5, 2) is CandyShape)


func test_a_world_is_built_with_its_terrain() -> void:
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.terrain_version = 2
	world.setup("", 42)
	add_child_autofree(world)
	assert_true(world.generator_shape() is MeadowsBiomeShape)
	assert_eq(world.surface_height(10, 20), MeadowsBiomeShape.new(42).height_at(10, 20))
	assert_eq(world.spawn_column(), MeadowsBiomeShape.new(42).spawn_column())
	var old: WorldService = load("res://world/world.tscn").instantiate()
	old.setup("", 42)
	add_child_autofree(old)
	assert_true(old.generator_shape().get_script() == MeadowsShape, "a world without a version is the old meadows")
	var arena: WorldService = load("res://world/world.tscn").instantiate()
	arena.terrain_version = 2
	arena.setup("", 42, false, 1, true)
	add_child_autofree(arena)
	assert_true(arena.generator_shape() is ArenaShape, "Monster Wave's arena stays flat")


## A LAN or online guest builds the host's world: the host's terrain version comes before world_info (reliable,
## on the same channel as the universe), and the guest's secrets are worked out on that terrain.
func test_a_guest_takes_the_hosts_terrain_and_its_secrets_follow() -> void:
	Session._rpc_own45b_terrain(2)
	assert_eq(Session.world_terrain, 2)
	Session._rpc_own45b_terrain(57)
	assert_eq(Session.world_terrain, 1, "nonsense reads as the old meadows")
	var meadows: Object = UniverseRegistry.descriptor(1)
	assert_true(meadows.has_method(&"secret_rules"), "Green Meadows gives its secrets the world's own terrain")
	var shape := MeadowsBiomeShape.new(9)
	var rules: SecretRules = meadows.call(&"secret_rules", 9, shape)
	assert_same(rules.shape, shape)
	assert_eq(rules.spawn, shape.spawn_column())
