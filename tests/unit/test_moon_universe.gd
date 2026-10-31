extends GutTest
## Owner feedback #55 (spec §21.2): the Moon is world 16 (world/universes/moon.gd): its descriptor brings its terrain
## (SpaceShape, SpaceGenerator), secrets (SpaceSecretRules, the Moon Base), low gravity (0.35: big floaty jumps), peace
## (no night monsters), a black starry sky with the home planet in it, its music and ambience, its moon bunnies, Tilly's
## local things, the landing words, a picture card and loading hints — the universe interface, no parallel system.


func after_each() -> void:
	UniverseRegistry.reset()


func _moon() -> Object:
	return UniverseRegistry.descriptor(SpaceRules.MOON)


func test_the_moon_descriptor_is_found_by_the_registry() -> void:
	assert_true(UniverseRegistry.exists(16))
	assert_eq(UniverseRegistry.space_available().has(16), true)
	var d := _moon()
	assert_eq(d.get("name"), &"moon")
	assert_eq(d.get("index"), 16)
	assert_eq(UniverseRegistry.display_name(16), "The Moon")
	assert_false(UniverseRegistry.available().has(16), "not on the ladder")


func test_its_terrain_generator_and_secrets() -> void:
	var shape := UniverseRegistry.shape_for(16, 77)
	assert_true(shape is SpaceShape)
	assert_eq((shape as SpaceShape).planet, SpaceShape.MOON)
	var gen := UniverseRegistry.generator_for(16, 77)
	assert_true(gen is SpaceGenerator)
	assert_eq((gen as SpaceGenerator).space_shape().planet, SpaceShape.MOON)
	assert_eq((gen as SpaceGenerator).world_seed, 77)
	var rules: Variant = _moon().call(&"secret_rules", 77, shape)
	assert_true(rules is SpaceSecretRules)
	assert_eq((rules as SpaceSecretRules).landmark().get("name"), "Moon Base")
	var words: Dictionary = _moon().get("secret_words")
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.ISLAND, SecretRules.GEODE]:
		assert_true(words.has(k), str(k))
	assert_string_contains(words[SecretRules.ISLAND], "Moon Base")


func test_low_gravity_peace_and_a_space_sky() -> void:
	assert_almost_eq(UniverseRegistry.gravity(16), 0.35, 0.001, "big floaty jumps")
	assert_true(UniverseRegistry.peaceful(16), "no monsters come by themselves")
	assert_eq(UniverseRegistry.space_sky(16), 1.0, "a black starry sky by day")
	var planet := UniverseRegistry.sky_planet(16)
	assert_true(planet.color is Color, "the home planet hangs in the sky")
	var jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	LabRules.world_gravity = UniverseRegistry.gravity(16)
	var moon_jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	LabRules.world_gravity = 1.0
	assert_gt(moon_jump, jump * 2.5, "almost three times as high (%.1f vs %.1f blocks)" % [moon_jump, jump])
	assert_ne(UniverseRegistry.landing_words(16), "")
	assert_string_contains(UniverseRegistry.landing_words(16), "Moon")


func test_its_sounds_music_and_shop() -> void:
	assert_false(UniverseRegistry.classical(16).is_empty(), "its own pieces first")
	assert_true(UniverseRegistry.classical(16).has(&"moonlight"))
	assert_false(UniverseRegistry.ambience(16).is_empty())
	var stock := UniverseRegistry.trader_stock(16)
	assert_true(stock.has(BlockIds.MOON_DUST))
	assert_true(stock.has(BlockIds.LANDING_PAD), "build your own landing pad")
	assert_false(stock.has(BlockIds.STAR_GOLD), "treasure is found, never sold")
	assert_false(stock.has(BlockIds.FAKE_MOON_ROCK))
	assert_eq(ShopRules.price(BlockIds.MOON_DUST, 16), stock[BlockIds.MOON_DUST], "never scaled (ruling 3)")


func test_moon_bunnies_live_on_the_moon() -> void:
	assert_eq(UniverseRegistry.animals(16), [&"moon_bunny"] as Array[StringName])
	var d: Dictionary = AnimalRules.SPECIES[&"moon_bunny"]
	assert_eq(d.habitat, &"land")
	assert_gt(AnimalRules.walk_hop(&"moon_bunny"), AnimalRules.walk_hop(&"rabbit"), "floaty hops")
	assert_true(AnimalFood.eats(&"moon_bunny", BlockIds.MOON_CHEESE), "they love cheese")
	assert_true(AnimalFood.eats(&"moon_bunny", BlockIds.MOON_CRYSTAL))
	assert_has(ChatCommands.ANIMALS, "moon_bunny", "/summon moon_bunny")
	var shape := SpaceShape.new(12345, SpaceShape.MOON)
	var seen := 0
	for cz in range(-8, 8):
		for cx in range(-8, 8):
			for a: Dictionary in AnimalRules.spawns_for_cell(shape, Vector2i(cx, cz), UniverseRegistry.animals(16)):
				assert_eq(a.species, &"moon_bunny")
				seen += 1
	assert_gt(seen, 10, "herds of moon bunnies")
	assert_true(AnimalRules.spawns_for_cell(shape, Vector2i(3, 3), [&"moon_bunny"]).all(func(a: Dictionary) -> bool:
		return a.species == &"moon_bunny"))


func test_its_picture_card_and_loading_hints() -> void:
	var colors := UniverseRegistry.card_colors(16)
	assert_lt((colors.top as Color).get_luminance(), 0.15, "a black sky on its card")
	assert_ne(UniverseArt.layout(16), UniverseArt.layout(1), "its own scene")
	var ids: Array = UniverseArt.legend(16).values()
	assert_has(ids, BlockIds.MOON_DUST)
	assert_has(ids, BlockIds.BASE_PANEL, "the Moon Base on the card")
	assert_false(LoadingHints.fitting(ModeRules.SANDBOX, 16).is_empty())
	var own := 0
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 16):
		if int(LoadingHints.HINTS[i].get("universe", 0)) == 16:
			own += 1
	assert_gt(own, 0, "a hint of its own")
