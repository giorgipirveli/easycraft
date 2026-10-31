extends GutTest
## Cosmos: Mars is world 19 (world/universes/mars.gd, spec §21b.2), a space world like the Moon: its descriptor brings
## its terrain and secrets (SpaceShape MARS, SpaceSecretRules: the rover), real gravity (0.38: jumps more than twice
## as high), peace, a butterscotch sky with a blue sunset glow and its two small moons (Phobos and Deimos), a soft
## dusty wind, calm classical music, no animals (Mars has no life we know of), Tilly's local things, the landing
## words, real facts in its finds' words and at its sights (the volcano, the canyon, the ice caps, the dry rivers), a
## picture card and loading hints. The Star Map then says LAND for Mars, and landing marks it in the Space Book.


func after_each() -> void:
	UniverseRegistry.reset()
	LabRules.world_gravity = 1.0


func _mars() -> Object:
	return UniverseRegistry.descriptor(SpaceRules.MARS)


func test_mars_is_world_19_a_space_world_found_by_the_registry() -> void:
	assert_eq(SpaceRules.MARS, 19)
	assert_has(SpaceRules.WORLDS, SpaceRules.MARS, "the picker and the Star Map know it")
	assert_eq(SpaceRules.WORLDS.slice(0, 4), [16, 17, 18, 19] as Array[int])
	assert_true(UniverseRegistry.is_space(19))
	assert_true(UniverseRegistry.exists(19))
	assert_true(UniverseRegistry.space_available().has(19))
	assert_false(UniverseRegistry.available().has(19), "not on the ladder")
	var d := _mars()
	assert_eq(d.get("name"), &"mars")
	assert_eq(d.get("index"), 19)
	assert_eq(UniverseRegistry.display_name(19), "Mars")
	assert_eq(UniverseRegistry.path_for(19), "res://world/universes/mars.gd")
	assert_false(ShopCatalog.needs_plus(19), "free for everyone")
	assert_eq(UniverseRules.scale(19), 1, "never scaled")
	assert_eq(ModeRules.slot(ModeRules.SANDBOX, 19), "sandbox_19")


func test_the_star_map_says_land_on_mars_and_the_space_book_marks_it() -> void:
	var s := StarMap.states(1, 1, UniverseRegistry.space_available(), 1)
	assert_eq(s[&"mars"], StarMap.LAND, "Mars can be landed on now")
	assert_eq(StarMap.states(19, 2, UniverseRegistry.space_available(), 2)[&"mars"], StarMap.HERE)
	assert_eq(StarMap.body_for_world(19), &"mars")
	var w := WonderData.new()
	assert_true(w.land_on_world(19), "the first landing on Mars")
	assert_eq(w.bodies, {"mars": WonderData.SEEN | WonderData.LANDED})


func test_its_terrain_generator_and_secrets() -> void:
	var shape := UniverseRegistry.shape_for(19, 77)
	assert_true(shape is SpaceShape)
	assert_eq((shape as SpaceShape).planet, SpaceShape.MARS)
	var gen := UniverseRegistry.generator_for(19, 77)
	assert_true(gen is SpaceGenerator)
	assert_eq((gen as SpaceGenerator).space_shape().planet, SpaceShape.MARS)
	assert_eq((gen as SpaceGenerator).world_seed, 77)
	var rules: Variant = _mars().call(&"secret_rules", 77, shape)
	assert_true(rules is SpaceSecretRules)
	assert_eq((rules as SpaceSecretRules).landmark().get("name"), "Mars Rover")


func test_real_gravity_peace_and_the_landing_words() -> void:
	assert_almost_eq(UniverseRegistry.gravity(19), 0.38, 0.001, "Mars's real gravity: 38% of Earth's")
	assert_true(UniverseRegistry.peaceful(19), "no monsters come by themselves")
	assert_eq(UniverseRegistry.landing_words(19), "You landed on Mars! Jump: you are lighter here!")
	var jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	LabRules.world_gravity = UniverseRegistry.gravity(19)
	var mars_jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	assert_gt(mars_jump, jump * 2.5, "more than twice as high (%.1f vs %.1f blocks)" % [mars_jump, jump])
	assert_gt(mars_jump, 4.2, "every step Mars's terrain makes (4 at most) is one jump")


func test_a_butterscotch_sky_with_a_blue_sunset_and_two_small_moons() -> void:
	assert_eq(UniverseRegistry.space_sky(19), 0.0, "an air sky of its own by day, not space's black")
	var sky := UniverseRegistry.sky(19)
	for key in ["sky_top", "sky_horizon", "ground_bottom", "ground_horizon", "fog"]:
		assert_true(sky.get(key) is Color, key)
	var top: Color = sky.sky_top
	assert_true(top.r > top.g and top.g > top.b, "butterscotch-pink, not blue (%s)" % top)
	var fog: Color = sky.fog
	assert_true(fog.r > fog.b, "a dusty haze")
	var ground: Color = sky.ground_bottom
	assert_gt(ground.get_luminance(), fog.get_luminance() * 0.8,
		"the sky under the horizon is the haze's, not a dark band over the far plains (%s)" % ground)
	var sunset: Color = sky.sunset
	assert_gt(sunset.b, sunset.r + 0.2, "Mars's sunsets glow blue (%s)" % sunset)
	var phobos := UniverseRegistry.sky_planet(19)
	assert_true(phobos.color is Color, "Phobos in the sky")
	assert_true(phobos.get("own_moons") == true, "Mars's own moons: no big moon disc at night")
	assert_lt(float(phobos.size), 40.0, "a small moon")
	var moons: Array = phobos.get("moons", [])
	assert_eq(moons.size(), 1, "and Deimos")
	assert_lt(float(moons[0].size), float(phobos.size), "Deimos is the smaller one")
	assert_true(moons[0].dir is Vector3)


func test_its_sounds_music_and_no_animals() -> void:
	assert_eq(UniverseRegistry.ambience(19), {"day": &"wind", "night": &"wind"}, "a soft dusty wind")
	assert_false(UniverseRegistry.classical(19).is_empty(), "calm pieces already in the game")
	assert_eq(UniverseRegistry.music(19), {}, "no loops of its own")
	assert_true(UniverseRegistry.lifeless(19), "Mars has no life we know of")
	assert_eq(UniverseRegistry.animals(19), [] as Array[StringName], "no animals")
	assert_false(UniverseRegistry.lifeless(16), "the Moon keeps its bunnies")
	assert_false(UniverseRegistry.lifeless(1))
	assert_false(UniverseRegistry.animals(1).is_empty())


func test_tillys_mars_things() -> void:
	var stock := UniverseRegistry.trader_stock(19)
	for id in [BlockIds.MARS_DUST, BlockIds.BASALT, BlockIds.POLAR_ICE, BlockIds.DRY_ICE, BlockIds.ROVER_PANEL,
			BlockIds.ROVER_WHEEL, BlockIds.SOLAR_PANEL, BlockIds.LANDING_PAD]:
		assert_true(stock.has(id), "%s to build with" % BlockIds.display_name(id))
	assert_false(stock.has(BlockIds.STAR_GOLD), "treasure is found, never sold")
	assert_false(stock.has(BlockIds.FAKE_BASALT))
	assert_eq(ShopRules.price(BlockIds.MARS_DUST, 19), stock[BlockIds.MARS_DUST], "never scaled")


func test_every_find_says_a_real_mars_fact() -> void:
	var words: Dictionary = _mars().get("secret_words")
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.ISLAND, SecretRules.GEODE]:
		assert_true(words.has(k), str(k))
		var text: String = words[k]
		assert_true(text.begins_with("You found"), text)
		assert_gt(text.find("! "), 0, "a find, then a fact: %s" % text)
		assert_true(text.ends_with("."), text)
		assert_lt(text.length(), 110, "short enough for the banner: %s" % text)
	assert_string_contains(words[SecretRules.ISLAND], "Mars Rover")
	assert_string_contains(words[SecretRules.ISLAND], "six wheels")
	assert_string_contains(words[SecretRules.TREASURE], "rust")
	assert_string_contains(words[SecretRules.GEODE], "gypsum")


func test_its_sights_teach_real_facts() -> void:
	var sights := UniverseRegistry.sights(19)
	for id: StringName in [&"volcano", &"canyon", &"north_cap", &"south_cap", &"river"]:
		assert_true(sights.has(id), str(id))
		var e: Dictionary = sights[id]
		assert_ne(str(e.get("name", "")), "", "a name for the map: %s" % id)
		assert_true(str(e.words).begins_with("You found") or str(e.words).begins_with("You reached"), e.words)
		assert_lt(str(e.words).length(), 120, e.words)
	assert_string_contains(sights[&"volcano"].words, "Olympus Mons")
	assert_string_contains(sights[&"canyon"].words, "Valles Marineris")
	assert_string_contains(sights[&"north_cap"].words, "frozen water and frozen carbon dioxide")
	assert_string_contains(sights[&"south_cap"].words, "dry ice")
	assert_string_contains(sights[&"river"].words, "water")
	assert_eq(UniverseRegistry.sights(16).keys(), ColonyRules.sights(SpaceShape.MOON).keys(),
		"the Moon has only its colony's (spec §21c)")
	for id: StringName in ColonyRules.PARTS:
		assert_true(sights.has(id), "Mars's colony: %s" % id)


func test_its_picture_card_and_loading_hints() -> void:
	var colors := UniverseRegistry.card_colors(19)
	assert_true((colors.top as Color).r > (colors.top as Color).b, "a butterscotch sky on its card")
	assert_ne(UniverseArt.layout(19), UniverseArt.layout(1), "its own scene")
	var ids: Array = UniverseArt.legend(19).values()
	assert_has(ids, BlockIds.MARS_DUST)
	assert_has(ids, BlockIds.ROVER_WHEEL, "the rover on the card")
	var own := 0
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 19):
		if int(LoadingHints.HINTS[i].get("universe", 0)) == 19:
			own += 1
	assert_gte(own, 2, "hints of its own")
