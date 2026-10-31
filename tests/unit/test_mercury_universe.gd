extends GutTest
## Cosmos: Mercury is world 23 (world/universes/mercury.gd, spec §21b.2), the smallest planet and the closest to the Sun,
## a space world like the Moon, Mars, Europa, Io and Titan: its descriptor brings its terrain and secrets (SpaceShape
## MERCURY, SpaceSecretRules: the Sunshade Lander), real gravity (0.38: jumps more than twice as high), peace, space's
## black sky by day (almost no air) with the Sun three times as big as at home (`sun_size`), Venus and Earth (with our
## Moon) as tiny points in it and no moon of its own, soft chimes, calm music, no animals (lifeless), Tilly's local
## things, the landing words, real facts in its finds' words and at its sights (the thermometer, a long cliff, a big
## crater, the ice crater), a picture card and loading hints. Its heat is a fact, never a danger. The Star Map then says
## LAND for Mercury, and landing marks it in the Space Book.


func after_each() -> void:
	UniverseRegistry.reset()
	LabRules.world_gravity = 1.0


func _mercury() -> Object:
	return UniverseRegistry.descriptor(SpaceRules.MERCURY)


func test_mercury_is_world_23_a_space_world_found_by_the_registry() -> void:
	assert_eq(SpaceRules.MERCURY, 23)
	assert_has(SpaceRules.WORLDS, SpaceRules.MERCURY, "the picker and the Star Map know it")
	assert_eq(SpaceRules.WORLDS.slice(0, 8), [16, 17, 18, 19, 20, 21, 22, 23] as Array[int])
	assert_true(UniverseRegistry.is_space(23))
	assert_true(UniverseRegistry.exists(23))
	assert_true(UniverseRegistry.space_available().has(23))
	assert_false(UniverseRegistry.available().has(23), "not on the ladder")
	var d := _mercury()
	assert_eq(d.get("name"), &"mercury")
	assert_eq(d.get("index"), 23)
	assert_eq(UniverseRegistry.display_name(23), "Mercury")
	assert_eq(UniverseRegistry.path_for(23), "res://world/universes/mercury.gd")
	assert_false(ShopCatalog.needs_plus(23), "free for everyone")
	assert_eq(UniverseRules.scale(23), 1, "never scaled")
	assert_eq(ModeRules.slot(ModeRules.SANDBOX, 23), "sandbox_23")


func test_the_star_map_says_land_on_mercury_and_the_space_book_marks_it() -> void:
	var s := StarMap.states(1, 1, UniverseRegistry.space_available(), 1)
	assert_eq(s[&"mercury"], StarMap.LAND, "Mercury can be landed on now")
	assert_eq(StarMap.states(23, 2, UniverseRegistry.space_available(), 2)[&"mercury"], StarMap.HERE)
	assert_eq(StarMap.body_for_world(23), &"mercury")
	var w := WonderData.new()
	assert_true(w.land_on_world(23), "the first landing on Mercury")
	assert_eq(w.bodies, {"mercury": WonderData.SEEN | WonderData.LANDED})


func test_its_terrain_generator_and_secrets() -> void:
	var shape := UniverseRegistry.shape_for(23, 77)
	assert_true(shape is SpaceShape)
	assert_eq((shape as SpaceShape).planet, SpaceShape.MERCURY)
	var gen := UniverseRegistry.generator_for(23, 77)
	assert_true(gen is SpaceGenerator)
	assert_eq((gen as SpaceGenerator).space_shape().planet, SpaceShape.MERCURY)
	assert_eq((gen as SpaceGenerator).world_seed, 77)
	var rules: Variant = _mercury().call(&"secret_rules", 77, shape)
	assert_true(rules is SpaceSecretRules)
	assert_eq((rules as SpaceSecretRules).landmark().get("name"), "Sunshade Lander")


func test_real_gravity_peace_and_the_landing_words() -> void:
	assert_almost_eq(UniverseRegistry.gravity(23), 0.38, 0.001, "Mercury's real gravity: 38% of Earth's")
	assert_true(UniverseRegistry.peaceful(23), "no monsters come by themselves")
	assert_eq(UniverseRegistry.landing_words(23), "You landed on Mercury! The Sun looks three times as big here!")
	var jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	LabRules.world_gravity = UniverseRegistry.gravity(23)
	var mercury_jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	assert_gt(mercury_jump, jump * 2.5, "more than twice as high (%.1f vs %.1f blocks)" % [mercury_jump, jump])
	assert_gt(mercury_jump, float(MercuryTerrain.MAX_STEP) + 0.3, "every step Mercury's terrain makes is one jump")


func test_a_black_sky_by_day_and_a_sun_three_times_as_big() -> void:
	assert_eq(UniverseRegistry.space_sky(23), 1.0, "almost no air: space's black sky by day")
	assert_false(UniverseRegistry.photo_sky(23), "never Earth's blue photo sky")
	assert_almost_eq(UniverseRegistry.sun_size(23), 3.0, 0.01, "the Sun three times as big as at home")
	assert_eq(UniverseRegistry.sun_size(1), 1.0, "home's Sun")
	assert_eq(UniverseRegistry.sun_size(SpaceRules.TITAN), 1.0, "a world without the field")
	var sky := UniverseRegistry.sky_planet(23)
	assert_true(sky.get("own_moons") == true, "Mercury has no moon: the big moon disc of home never shows")
	assert_lte(float(sky.size), 8.0, "Venus: a tiny bright point, not a big planet")
	var moons: Array = sky.get("moons", [])
	assert_eq(moons.size(), 2, "Earth and our Moon, two tiny points")
	assert_gt((moons[0].color as Color).b, (moons[0].color as Color).r, "Earth is blue")
	assert_lt(float(moons[1].size), float(moons[0].size), "our Moon smaller than Earth")


func test_its_sounds_music_and_no_animals() -> void:
	assert_eq(UniverseRegistry.ambience(23), {"day": &"chimes", "night": &"chimes"}, "no air: no wind, soft chimes")
	assert_eq(UniverseRegistry.classical(23), [&"ode_to_joy", &"gymnopedie"] as Array[StringName])
	for id in UniverseRegistry.classical(23):
		assert_false(MusicPieces.PIECES[id].moods.has(MusicPieces.BOSS), "a piece a day or a night plays, not a boss's")
	assert_eq(UniverseRegistry.music(23), {}, "no loops of its own")
	assert_true(UniverseRegistry.lifeless(23), "no life we know of")
	assert_eq(UniverseRegistry.animals(23), [] as Array[StringName], "no animals")


func test_tillys_mercury_things() -> void:
	var stock := UniverseRegistry.trader_stock(23)
	for id in [BlockIds.MERCURY_DUST, BlockIds.MERCURY_ROCK, BlockIds.DARK_DUST, BlockIds.RAY_DUST, BlockIds.SHADOW_ICE,
			BlockIds.ICE_CRYSTAL, BlockIds.SUNSHADE, BlockIds.HEAT_BLANKET, BlockIds.MIRROR_PANEL, BlockIds.EXPLORER_LAMP,
			BlockIds.THERMOMETER, BlockIds.THERMO_BULB, BlockIds.EXPLORER_BRICK, BlockIds.LANDING_PAD]:
		assert_true(stock.has(id), "%s to build with" % BlockIds.display_name(id))
	assert_false(stock.has(BlockIds.STAR_GOLD), "treasure is found, never sold")
	assert_false(stock.has(BlockIds.FAKE_MERCURY_ROCK))
	assert_eq(ShopRules.price(BlockIds.MERCURY_DUST, 23), stock[BlockIds.MERCURY_DUST], "never scaled")


func test_every_find_says_a_real_mercury_fact() -> void:
	var words: Dictionary = _mercury().get("secret_words")
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.ISLAND, SecretRules.GEODE]:
		assert_true(words.has(k), str(k))
		var text: String = words[k]
		assert_true(text.begins_with("You found"), text)
		assert_gt(text.find("! "), 0, "a find, then a fact: %s" % text)
		assert_true(text.ends_with("."), text)
		assert_lt(text.length(), 110, "short enough for the banner: %s" % text)
	assert_string_contains(words[SecretRules.ISLAND], "Sunshade Lander")
	assert_string_contains(words[SecretRules.ISLAND], "sunshades")
	assert_string_contains(words[SecretRules.TREASURE], "88 Earth days")
	assert_string_contains(words[SecretRules.ROOM], "85 %")
	assert_string_contains(words[SecretRules.TEMPLE], "no air")
	assert_string_contains(words[SecretRules.GEODE], "Comets")


func test_its_sights_teach_real_facts() -> void:
	var sights := UniverseRegistry.sights(23)
	for id: StringName in [&"thermometer", &"scarp", &"crater", &"ice"]:
		assert_true(sights.has(id), str(id))
		var e: Dictionary = sights[id]
		assert_ne(str(e.get("name", "")), "", "a name for the map: %s" % id)
		assert_true(str(e.words).begins_with("You found"), e.words)
		assert_lt(str(e.words).length(), 120, e.words)
	assert_string_contains(sights[&"thermometer"].words, "430 °C")
	assert_string_contains(sights[&"thermometer"].words, "−180 °C")
	assert_string_contains(sights[&"scarp"].words, "shrank")
	assert_string_contains(sights[&"crater"].words, "artists")
	assert_string_contains(sights[&"ice"].words, "never")
	assert_string_contains(sights[&"ice"].words, "poles")


## Mercury's heat is a fact, never a danger: no word says it hurts, burns or is too hot for a child.
func test_the_heat_is_a_fact_never_a_danger() -> void:
	var texts := _texts()
	for t in texts:
		for w in ["hurt", "burn", "danger", "dangerous", "scary", "careful", "too hot", "die", "melt you"]:
			assert_eq(t.to_lower().find(w), -1, "a friendly world (spec §3c): %s" % t)


func test_no_mission_names_or_brands_in_its_words() -> void:
	for t in _texts():
		for name in ["MESSENGER", "Messenger", "Mariner", "BepiColombo", "Bepi", "NASA", "ESA", "JAXA", "JPL", "Hubble"]:
			assert_eq(t.find(name), -1, "general words, no mission names (§21b.2): %s" % t)


func _texts() -> Array[String]:
	var texts: Array[String] = [UniverseRegistry.landing_words(23)]
	for w: String in (_mercury().get("secret_words") as Dictionary).values():
		texts.append(w)
	for e: Dictionary in UniverseRegistry.sights(23).values():
		texts.append(str(e.words))
		texts.append(str(e.name))
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 23):
		texts.append(str(LoadingHints.HINTS[i].text))
	return texts


func test_its_picture_card_and_loading_hints() -> void:
	var colors := UniverseRegistry.card_colors(23)
	assert_lt((colors.top as Color).get_luminance(), 0.1, "a black sky on its card")
	assert_ne(UniverseArt.layout(23), UniverseArt.layout(22), "its own scene")
	var ids: Array = UniverseArt.legend(23).values()
	assert_has(ids, BlockIds.MERCURY_DUST)
	assert_has(ids, BlockIds.SUNSHADE, "the Sunshade Lander on the card")
	assert_has(ids, BlockIds.THERMO_BULB, "and the thermometer")
	var own := 0
	var sun := false
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 23):
		if int(LoadingHints.HINTS[i].get("universe", 0)) == 23:
			own += 1
			var text := str(LoadingHints.HINTS[i].text)
			assert_lte(text.split(" ").size(), 10, text)
			if text.contains("Sun") and text.contains("three times"):
				sun = true
	assert_gte(own, 3, "hints of its own")
	assert_true(sun, "a hint says the Sun looks three times as big")
