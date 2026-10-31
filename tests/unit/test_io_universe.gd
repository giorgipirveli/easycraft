extends GutTest
## Cosmos: Io is world 21 (world/universes/io.gd, spec §21b.2), Jupiter's volcanic moon, a space world like the Moon,
## Mars and Europa: its descriptor brings its terrain and secrets (SpaceShape IO, SpaceSecretRules: the Volcano Lander),
## real gravity (0.18: jumps more than 5 times as high), peace, a black starry sky (almost no air) with giant banded
## Jupiter hanging in it and two of its other moons (Europa and Ganymede), soft chimes, lively music, no animals
## (lifeless), Tilly's local things, the landing words, real facts in its finds' words and at its sights (the lava lake,
## the mountain, a volcano's plume, a red ring), a picture card and loading hints (one says what hot lava does). The
## Star Map then says LAND for Io, and landing marks it in the Space Book.


func after_each() -> void:
	UniverseRegistry.reset()
	LabRules.world_gravity = 1.0


func _io() -> Object:
	return UniverseRegistry.descriptor(SpaceRules.IO)


func test_io_is_world_21_a_space_world_found_by_the_registry() -> void:
	assert_eq(SpaceRules.IO, 21)
	assert_has(SpaceRules.WORLDS, SpaceRules.IO, "the picker and the Star Map know it")
	assert_eq(SpaceRules.WORLDS.slice(0, 6), [16, 17, 18, 19, 20, 21] as Array[int])
	assert_true(UniverseRegistry.is_space(21))
	assert_true(UniverseRegistry.exists(21))
	assert_true(UniverseRegistry.space_available().has(21))
	assert_false(UniverseRegistry.available().has(21), "not on the ladder")
	var d := _io()
	assert_eq(d.get("name"), &"io")
	assert_eq(d.get("index"), 21)
	assert_eq(UniverseRegistry.display_name(21), "Io")
	assert_eq(UniverseRegistry.path_for(21), "res://world/universes/io.gd")
	assert_false(ShopCatalog.needs_plus(21), "free for everyone")
	assert_eq(UniverseRules.scale(21), 1, "never scaled")
	assert_eq(ModeRules.slot(ModeRules.SANDBOX, 21), "sandbox_21")


func test_the_star_map_says_land_on_io_and_the_space_book_marks_it() -> void:
	var s := StarMap.states(1, 1, UniverseRegistry.space_available(), 1)
	assert_eq(s[&"io"], StarMap.LAND, "Io can be landed on now")
	assert_eq(StarMap.states(21, 2, UniverseRegistry.space_available(), 2)[&"io"], StarMap.HERE)
	assert_eq(StarMap.body_for_world(21), &"io")
	var w := WonderData.new()
	assert_true(w.land_on_world(21), "the first landing on Io")
	assert_eq(w.bodies, {"io": WonderData.SEEN | WonderData.LANDED})


func test_its_terrain_generator_and_secrets() -> void:
	var shape := UniverseRegistry.shape_for(21, 77)
	assert_true(shape is SpaceShape)
	assert_eq((shape as SpaceShape).planet, SpaceShape.IO)
	var gen := UniverseRegistry.generator_for(21, 77)
	assert_true(gen is SpaceGenerator)
	assert_eq((gen as SpaceGenerator).space_shape().planet, SpaceShape.IO)
	assert_eq((gen as SpaceGenerator).world_seed, 77)
	var rules: Variant = _io().call(&"secret_rules", 77, shape)
	assert_true(rules is SpaceSecretRules)
	assert_eq((rules as SpaceSecretRules).landmark().get("name"), "Volcano Lander")


func test_real_gravity_peace_and_the_landing_words() -> void:
	assert_almost_eq(UniverseRegistry.gravity(21), 0.18, 0.001, "Io's real gravity: 18% of Earth's")
	assert_true(UniverseRegistry.peaceful(21), "no monsters come by themselves")
	assert_eq(UniverseRegistry.landing_words(21), "You landed on Io! Watch the volcanoes and look up at Jupiter!")
	var jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	LabRules.world_gravity = UniverseRegistry.gravity(21)
	var io_jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	assert_gt(io_jump, jump * 5.0, "more than 5 times as high (%.1f vs %.1f blocks)" % [io_jump, jump])
	assert_gt(io_jump, float(IoTerrain.MAX_STEP) + 0.5, "every step Io's terrain makes is one jump")


func test_a_black_starry_sky_with_giant_jupiter_and_two_of_its_moons() -> void:
	assert_eq(UniverseRegistry.space_sky(21), 1.0, "almost no air: space's black sky with stars")
	assert_false(UniverseRegistry.photo_sky(21), "never Earth's blue photo sky")
	var sky := UniverseRegistry.sky(21)
	for key in ["sky_top", "sky_horizon", "ground_bottom", "ground_horizon", "fog"]:
		assert_true(sky.get(key) is Color, key)
	var jupiter := UniverseRegistry.sky_planet(21)
	assert_true(jupiter.get("bands") == true, "Jupiter's cloud bands")
	assert_true(jupiter.get("spot") == true, "and its Great Red Spot")
	assert_gt(float(jupiter.size), float(UniverseRegistry.sky_planet(20).size), "bigger than over Europa: Io is closer")
	assert_true(jupiter.get("own_moons") == true, "no moon disc of home at night")
	var moons: Array = jupiter.get("moons", [])
	assert_eq(moons.size(), 2, "Europa and Ganymede")
	for m: Dictionary in moons:
		assert_lt(float(m.size), float(jupiter.size) * 0.2, "small beside Jupiter")
		assert_true(m.dir is Vector3)
	var europa: Color = moons[0].color
	assert_gt(europa.get_luminance(), 0.75, "Europa is icy white (%s)" % europa)


func test_its_sounds_music_and_no_animals() -> void:
	assert_eq(UniverseRegistry.ambience(21), {"day": &"chimes", "night": &"chimes"}, "soft chimes: no air, no wind")
	assert_eq(UniverseRegistry.classical(21), [&"figaro", &"moonlight"] as Array[StringName])
	for id in UniverseRegistry.classical(21):
		assert_false(MusicPieces.PIECES[id].moods.has(MusicPieces.BOSS), "a piece a day or a night plays, not a boss's")
	assert_eq(UniverseRegistry.music(21), {}, "no loops of its own")
	assert_true(UniverseRegistry.lifeless(21), "no life we know of")
	assert_eq(UniverseRegistry.animals(21), [] as Array[StringName], "no animals")


func test_tillys_io_things() -> void:
	var stock := UniverseRegistry.trader_stock(21)
	for id in [BlockIds.SULPHUR, BlockIds.ORANGE_SULPHUR, BlockIds.SULPHUR_FROST, BlockIds.RED_SULPHUR,
			BlockIds.BLACK_LAVA, BlockIds.LAVA_CRUST, BlockIds.SULPHUR_CRYSTAL, BlockIds.HEAT_TILE, BlockIds.LANDING_PAD]:
		assert_true(stock.has(id), "%s to build with" % BlockIds.display_name(id))
	assert_false(stock.has(BlockIds.STAR_GOLD), "treasure is found, never sold")
	assert_false(stock.has(BlockIds.FAKE_IO_ROCK))
	assert_eq(ShopRules.price(BlockIds.SULPHUR, 21), stock[BlockIds.SULPHUR], "never scaled")


func test_every_find_says_a_real_io_fact() -> void:
	var words: Dictionary = _io().get("secret_words")
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.ISLAND, SecretRules.GEODE]:
		assert_true(words.has(k), str(k))
		var text: String = words[k]
		assert_true(text.begins_with("You found"), text)
		assert_gt(text.find("! "), 0, "a find, then a fact: %s" % text)
		assert_true(text.ends_with("."), text)
		assert_lt(text.length(), 110, "short enough for the banner: %s" % text)
	assert_string_contains(words[SecretRules.ISLAND], "Volcano Lander")
	assert_string_contains(words[SecretRules.ISLAND], "1979")
	assert_string_contains(words[SecretRules.TREASURE], "Moon")
	assert_string_contains(words[SecretRules.ROOM], "Jupiter's pull")
	assert_string_contains(words[SecretRules.TEMPLE], "42 hours")
	assert_string_contains(words[SecretRules.GEODE], "sulphur")


func test_its_sights_teach_real_facts() -> void:
	var sights := UniverseRegistry.sights(21)
	for id: StringName in [&"lake", &"mountain", &"plume", &"ring"]:
		assert_true(sights.has(id), str(id))
		var e: Dictionary = sights[id]
		assert_ne(str(e.get("name", "")), "", "a name for the map: %s" % id)
		assert_true(str(e.words).begins_with("You found") or str(e.words).begins_with("You reached")
			or str(e.words).begins_with("You climbed"), e.words)
		assert_lt(str(e.words).length(), 120, e.words)
	assert_string_contains(sights[&"lake"].words, "200 km")
	assert_string_contains(sights[&"mountain"].words, "Mount Everest")
	assert_string_contains(sights[&"plume"].words, "400")
	assert_string_contains(sights[&"ring"].words, "1,000 km")


func test_no_mission_names_or_brands_in_its_words() -> void:
	var texts: Array[String] = [UniverseRegistry.landing_words(21)]
	for w: String in (_io().get("secret_words") as Dictionary).values():
		texts.append(w)
	for e: Dictionary in UniverseRegistry.sights(21).values():
		texts.append(str(e.words))
		texts.append(str(e.name))
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 21):
		texts.append(str(LoadingHints.HINTS[i].text))
	for t in texts:
		for name in ["Galileo", "Juno", "Voyager", "Pioneer", "Hubble", "NASA", "ESA", "JPL", "New Horizons"]:
			assert_eq(t.find(name), -1, "general words, no mission names (§21b.2): %s" % t)


func test_its_picture_card_and_loading_hints() -> void:
	var colors := UniverseRegistry.card_colors(21)
	assert_lt((colors.top as Color).get_luminance(), 0.2, "space's dark sky on its card")
	assert_ne(UniverseArt.layout(21), UniverseArt.layout(20), "its own scene")
	var ids: Array = UniverseArt.legend(21).values()
	assert_has(ids, BlockIds.SULPHUR)
	assert_has(ids, BlockIds.HOT_LAVA, "glowing lava on the card")
	assert_has(ids, BlockIds.HEAT_TILE, "the Volcano Lander on the card")
	var own := 0
	var lava_hint := false
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 21):
		if int(LoadingHints.HINTS[i].get("universe", 0)) == 21:
			own += 1
			var text := str(LoadingHints.HINTS[i].text)
			assert_lte(text.split(" ").size(), 10, text)
			if text.contains("lava") and text.contains("bounces"):
				lava_hint = true
	assert_gte(own, 3, "hints of its own")
	assert_true(lava_hint, "a hint says what hot lava does before a child meets it")
