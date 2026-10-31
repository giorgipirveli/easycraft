extends GutTest
## Owner feedback #55 (spec §21): the space worlds plug into the universe machinery. UniverseRegistry knows them by
## number (16-18) next to the ladder, from their own descriptor files; they are free (never Plus), never scaled, have
## their own save slots, and bring their own gravity (LabRules.world_gravity: the world's times the lab's).

const FAKE := preload("res://tests/fakes/fake_universe.gd")


func after_each() -> void:
	UniverseRegistry.reset()
	LabRules.world_gravity = 1.0


func test_the_ladder_stays_the_ladder() -> void:
	assert_eq(UniverseRegistry.size(), 6, "space worlds are not on the ladder (six with the Glow Caves)")
	assert_false(UniverseRegistry.available().has(16))
	assert_eq(UniverseRegistry.ladder_name(16), &"", "no ladder name")


func test_the_space_worlds_have_names_files_and_card_colours_before_their_files_exist() -> void:
	var names := {16: &"moon", 17: &"boing", 18: &"rainbow"}
	var shown := {16: "The Moon", 17: "Planet Boing", 18: "Rainbow Planet"}
	for u: int in names:
		assert_true(UniverseRegistry.is_space(u))
		assert_eq(UniverseRegistry.space_name(u), names[u])
		assert_eq(UniverseRegistry.path_for(u), "res://world/universes/%s.gd" % names[u])
		UniverseRegistry.use(u, null)   # pretend the file is missing
		assert_eq(UniverseRegistry.display_name(u), shown[u], "the table names it")
		var c := UniverseRegistry.card_colors(u)
		assert_true(c.top is Color and c.bottom is Color and c.ground is Color)
	assert_false(UniverseRegistry.is_space(5))
	assert_eq(UniverseRegistry.space_name(5), &"")


func test_space_available_lists_the_space_worlds_whose_files_exist() -> void:
	UniverseRegistry.use(16, FAKE.new())
	UniverseRegistry.use(17, null)
	UniverseRegistry.use(18, null)
	UniverseRegistry.use(19, null)
	UniverseRegistry.use(20, null)
	UniverseRegistry.use(21, null)
	UniverseRegistry.use(22, null)
	UniverseRegistry.use(23, null)
	UniverseRegistry.use(24, null)
	UniverseRegistry.use(25, null)
	UniverseRegistry.use(26, null)
	UniverseRegistry.use(27, null)
	UniverseRegistry.use(28, null)
	assert_eq(UniverseRegistry.space_available(), [16] as Array[int])
	assert_true(UniverseRegistry.exists(16))
	assert_eq(UniverseRegistry.display_name(16), "Test Land", "a descriptor's own name wins")


func test_a_space_descriptor_brings_gravity_peace_and_its_sky() -> void:
	var d := FAKE.new()
	UniverseRegistry.use(16, SpaceStub.new())
	assert_almost_eq(UniverseRegistry.gravity(16), 0.35, 0.001)
	assert_true(UniverseRegistry.peaceful(16))
	assert_eq(UniverseRegistry.space_sky(16), 1.0)
	assert_eq((UniverseRegistry.sky_planet(16).color as Color), Color("3f8fe0"))
	UniverseRegistry.use(2, d)
	assert_eq(UniverseRegistry.gravity(2), 1.0, "a universe without the field: normal gravity")
	assert_false(UniverseRegistry.peaceful(2))
	assert_eq(UniverseRegistry.space_sky(2), 0.0)
	assert_true(UniverseRegistry.sky_planet(2).is_empty())
	assert_eq(UniverseRegistry.gravity(1), 1.0, "Green Meadows")


func test_broken_gravity_reads_safely() -> void:
	var stub := SpaceStub.new()
	stub.gravity = -3.0
	UniverseRegistry.use(17, stub)
	assert_eq(UniverseRegistry.gravity(17), UniverseRegistry.MIN_GRAVITY, "never upside down or zero")
	stub.gravity = NAN
	assert_eq(UniverseRegistry.gravity(17), 1.0)
	stub.gravity = 40.0
	assert_eq(UniverseRegistry.gravity(17), UniverseRegistry.MAX_GRAVITY)


func test_space_worlds_are_free_and_never_scaled() -> void:
	for u in SpaceRules.WORLDS:
		assert_false(ShopCatalog.needs_plus(u), "ruling 3: %d is free" % u)
		assert_eq(UniverseRules.scale(u), 1, "ruling 3: %d is never scaled" % u)
		assert_eq(UniverseRules.gold(10, u), 10)
		assert_eq(FlyCost.charge(u), FlyCost.GOLD_PER_CHARGE, "flying costs what it costs at home")
	assert_true(ShopCatalog.needs_plus(3), "the ladder keeps its rule")
	assert_eq(UniverseRules.scale(3), 4)
	assert_false(ShopCatalog.plus_universes().has(16))


func test_space_worlds_have_their_own_saves() -> void:
	assert_eq(ModeRules.slot(ModeRules.SANDBOX, 16), "sandbox_16")
	assert_eq(ModeRules.slot(ModeRules.SURVIVOR, 16), "survivor_u16")
	assert_eq(ModeRules.slot(ModeRules.SURVIVOR, 18), "survivor_u18")


func test_the_world_gravity_multiplies_the_lab() -> void:
	assert_eq(LabRules.gravity_factor(LabRules.Mode.NORMAL), 1.0)
	LabRules.world_gravity = 0.35
	assert_almost_eq(LabRules.gravity_factor(LabRules.Mode.NORMAL), 0.35, 0.0001, "the Moon")
	assert_almost_eq(LabRules.gravity_factor(LabRules.Mode.SLOW), 0.35, 0.0001)
	assert_almost_eq(LabRules.gravity_factor(LabRules.Mode.MOON), 0.35 * LabRules.MOON_GRAVITY, 0.0001, "the lab's Moon on the Moon")
	assert_eq(LabRules.gravity_factor(LabRules.Mode.ZERO_G), 0.0, "zero is zero")
	assert_eq(LabRules.gravity_factor(LabRules.Mode.FLY), 0.0)


## M7 (the browser's freezes): the space worlds' files load in the background (the climb asks for it), and the picker
## then takes them from there; nothing is asked twice.
func test_warming_loads_the_space_worlds_files_in_the_background() -> void:
	UniverseRegistry.reset()
	var asked := UniverseRegistry.warm_space()
	assert_eq(asked, [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 41] as Array[int],
		"owner #78: the Star Map's Earth card lands at world 41 (cosmos: Venus's cloud city is 24, Saturn's rings 25)")
	for u in asked:
		assert_ne(ResourceLoader.load_threaded_get_status(UniverseRegistry.path_for(u)),
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, "asked for in the background")
	assert_eq(UniverseRegistry.display_name(16), "The Moon", "the descriptor from the background load")
	assert_eq(UniverseRegistry.display_name(17), "Planet Boing")
	assert_eq(UniverseRegistry.warm_space(), [] as Array[int], "asked once: 18-21 are on their way, 16 and 17 are here")
	assert_eq(UniverseRegistry.display_name(18), "Rainbow Planet")
	assert_eq(UniverseRegistry.display_name(19), "Mars")
	assert_eq(UniverseRegistry.display_name(20), "Europa")
	assert_eq(UniverseRegistry.warm_space(), [] as Array[int], "nothing left to ask for")


func test_warming_skips_a_world_a_test_stands_in_for() -> void:
	UniverseRegistry.use(16, null)
	assert_false(UniverseRegistry.warm_space().has(16))


## A stand-in space descriptor (the fields the registry reads).
class SpaceStub extends RefCounted:
	var name := &"moon"
	var display_name := "Stub Moon"
	var index := 16
	var gravity := 0.35
	var peaceful := true
	var space_sky := 1.0
	var sky_planet := {"color": Color("3f8fe0"), "ring": false, "size": 60.0}

	func generator_shape(world_seed: int) -> MeadowsShape:
		return MeadowsShape.new(world_seed)
