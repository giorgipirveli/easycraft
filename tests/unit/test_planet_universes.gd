extends GutTest
## Owner feedback #55 (spec §21.2): Planet Boing (world 17) and Rainbow Planet (world 18) are universe descriptors like
## the Moon's: their terrain, secrets and landmark, gravity (Boing 0.6, Rainbow 0.8), peace, a sky of their own with a
## planet in it, music and ambience, their animals (Boing: frogs and goats; Rainbow: candy birds and horses), Tilly's
## local things, landing words, a picture card and loading hints.

const WORLDS := {17: {"name": &"boing", "shown": "Planet Boing", "planet": SpaceShape.BOING, "gravity": 0.6,
		"landmark": "Boing Tower", "animals": [&"frog", &"goat"], "ground": BlockIds.BOING_MOSS},
	18: {"name": &"rainbow", "shown": "Rainbow Planet", "planet": SpaceShape.RAINBOW, "gravity": 0.8,
		"landmark": "Rainbow Arch", "animals": [&"candy_bird", &"horse"], "ground": BlockIds.PRISM_GRASS}}


func after_each() -> void:
	UniverseRegistry.reset()


func test_every_space_world_exists() -> void:
	assert_eq(UniverseRegistry.space_available(), [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28] as Array[int])
	for u: int in WORLDS:
		var d := UniverseRegistry.descriptor(u)
		assert_not_null(d, str(u))
		assert_eq(d.get("name"), WORLDS[u].name)
		assert_eq(d.get("index"), u)
		assert_eq(UniverseRegistry.display_name(u), WORLDS[u].shown)


func test_their_terrain_generators_and_landmarks() -> void:
	for u: int in WORLDS:
		var shape := UniverseRegistry.shape_for(u, 77)
		assert_true(shape is SpaceShape)
		assert_eq((shape as SpaceShape).planet, WORLDS[u].planet)
		var gen := UniverseRegistry.generator_for(u, 77)
		assert_true(gen is SpaceGenerator)
		assert_eq((gen as SpaceGenerator).space_shape().planet, WORLDS[u].planet)
		var rules: Variant = UniverseRegistry.descriptor(u).call(&"secret_rules", 77, shape)
		assert_true(rules is SpaceSecretRules)
		assert_eq((rules as SpaceSecretRules).landmark().get("name"), WORLDS[u].landmark)
		var words: Dictionary = UniverseRegistry.descriptor(u).get("secret_words")
		assert_string_contains(words[SecretRules.ISLAND], WORLDS[u].landmark)


func test_gravity_peace_sky_and_words() -> void:
	for u: int in WORLDS:
		assert_almost_eq(UniverseRegistry.gravity(u), float(WORLDS[u].gravity), 0.001)
		assert_true(UniverseRegistry.peaceful(u))
		assert_eq(UniverseRegistry.space_sky(u), 0.0, "a sky of its own colours by day")
		assert_false(UniverseRegistry.sky(u).is_empty())
		assert_true(UniverseRegistry.sky_planet(u).color is Color, "a planet in its sky")
		assert_string_contains(UniverseRegistry.landing_words(u), WORLDS[u].shown)
	assert_true(UniverseRegistry.sky_planet(17).get("ring") == true, "a ringed planet over Boing")


func test_their_sounds_music_and_shop() -> void:
	for u: int in WORLDS:
		assert_false(UniverseRegistry.classical(u).is_empty())
		assert_false(UniverseRegistry.ambience(u).is_empty())
		var stock := UniverseRegistry.trader_stock(u)
		assert_true(stock.has(WORLDS[u].ground), "its ground to build with")
		assert_false(stock.has(BlockIds.STAR_GOLD))


func test_their_animals_live_there() -> void:
	for u: int in WORLDS:
		var kinds := UniverseRegistry.animals(u)
		assert_eq(kinds, WORLDS[u].animals as Array[StringName])
		var shape := SpaceShape.new(12345, WORLDS[u].planet)
		var seen := {}
		for cz in range(-10, 10):
			for cx in range(-10, 10):
				for a: Dictionary in AnimalRules.spawns_for_cell(shape, Vector2i(cx, cz), kinds):
					seen[a.species] = int(seen.get(a.species, 0)) + 1
		for sp: StringName in kinds:
			assert_gt(int(seen.get(sp, 0)), 0, "%s lives on %s" % [sp, WORLDS[u].shown])


func test_their_picture_cards_and_hints() -> void:
	for u: int in WORLDS:
		assert_ne(UniverseArt.layout(u), UniverseArt.layout(1), "its own scene")
		assert_has(UniverseArt.legend(u).values(), WORLDS[u].ground)
		var own := 0
		for i in LoadingHints.fitting(ModeRules.SANDBOX, u):
			if int(LoadingHints.HINTS[i].get("universe", 0)) == u:
				own += 1
		assert_gt(own, 0, "%s has a hint of its own" % WORLDS[u].shown)
