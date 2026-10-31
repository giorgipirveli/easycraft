extends GutTest
## Cosmos: Europa is world 20 (world/universes/europa.gd, spec §21b.2), Jupiter's icy moon, a space world like the Moon
## and Mars: its descriptor brings its terrain and secrets (SpaceShape EUROPA, SpaceSecretRules: the Ice Lander), real
## gravity (0.13: jumps more than 7 times as high), peace, a black starry sky (almost no air) with giant banded Jupiter
## hanging in it and two of its other moons (Io and Ganymede), soft icy chimes, calm icy music, no animals (lifeless: no
## life we know of), Tilly's local things, the landing words, real facts in its finds' words and at its sights (the
## ocean under the ice, the ice cliffs, a water plume, a reddish crack), a picture card and loading hints. The Star Map
## then says LAND for Europa, and landing marks it in the Space Book.


func after_each() -> void:
	UniverseRegistry.reset()
	LabRules.world_gravity = 1.0


func _europa() -> Object:
	return UniverseRegistry.descriptor(SpaceRules.EUROPA)


func test_europa_is_world_20_a_space_world_found_by_the_registry() -> void:
	assert_eq(SpaceRules.EUROPA, 20)
	assert_has(SpaceRules.WORLDS, SpaceRules.EUROPA, "the picker and the Star Map know it")
	assert_eq(SpaceRules.WORLDS.slice(0, 5), [16, 17, 18, 19, 20] as Array[int])
	assert_true(UniverseRegistry.is_space(20))
	assert_true(UniverseRegistry.exists(20))
	assert_true(UniverseRegistry.space_available().has(20))
	assert_false(UniverseRegistry.available().has(20), "not on the ladder")
	var d := _europa()
	assert_eq(d.get("name"), &"europa")
	assert_eq(d.get("index"), 20)
	assert_eq(UniverseRegistry.display_name(20), "Europa")
	assert_eq(UniverseRegistry.path_for(20), "res://world/universes/europa.gd")
	assert_false(ShopCatalog.needs_plus(20), "free for everyone")
	assert_eq(UniverseRules.scale(20), 1, "never scaled")
	assert_eq(ModeRules.slot(ModeRules.SANDBOX, 20), "sandbox_20")


func test_the_star_map_says_land_on_europa_and_the_space_book_marks_it() -> void:
	var s := StarMap.states(1, 1, UniverseRegistry.space_available(), 1)
	assert_eq(s[&"europa"], StarMap.LAND, "Europa can be landed on now")
	assert_eq(StarMap.states(20, 2, UniverseRegistry.space_available(), 2)[&"europa"], StarMap.HERE)
	assert_eq(StarMap.body_for_world(20), &"europa")
	var w := WonderData.new()
	assert_true(w.land_on_world(20), "the first landing on Europa")
	assert_eq(w.bodies, {"europa": WonderData.SEEN | WonderData.LANDED})


func test_its_terrain_generator_and_secrets() -> void:
	var shape := UniverseRegistry.shape_for(20, 77)
	assert_true(shape is SpaceShape)
	assert_eq((shape as SpaceShape).planet, SpaceShape.EUROPA)
	var gen := UniverseRegistry.generator_for(20, 77)
	assert_true(gen is SpaceGenerator)
	assert_eq((gen as SpaceGenerator).space_shape().planet, SpaceShape.EUROPA)
	assert_eq((gen as SpaceGenerator).world_seed, 77)
	var rules: Variant = _europa().call(&"secret_rules", 77, shape)
	assert_true(rules is SpaceSecretRules)
	assert_eq((rules as SpaceSecretRules).landmark().get("name"), "Ice Lander")


func test_real_gravity_peace_and_the_landing_words() -> void:
	assert_almost_eq(UniverseRegistry.gravity(20), 0.13, 0.001, "Europa's real gravity: 13% of Earth's")
	assert_true(UniverseRegistry.peaceful(20), "no monsters come by themselves")
	assert_eq(UniverseRegistry.landing_words(20), "You landed on Europa! Jump high and look up at Jupiter!")
	var jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	LabRules.world_gravity = UniverseRegistry.gravity(20)
	var europa_jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	assert_gt(europa_jump, jump * 7.0, "more than 7 times as high (%.1f vs %.1f blocks)" % [europa_jump, jump])
	assert_gt(europa_jump, float(EuropaTerrain.MAX_STEP) + 0.5, "every step Europa's terrain makes is one jump")


func test_a_black_starry_sky_with_giant_banded_jupiter_and_two_of_its_moons() -> void:
	assert_eq(UniverseRegistry.space_sky(20), 1.0, "almost no air: space's black sky with stars, like the Moon's")
	assert_false(UniverseRegistry.photo_sky(20), "never Earth's blue photo sky")
	var sky := UniverseRegistry.sky(20)
	for key in ["sky_top", "sky_horizon", "ground_bottom", "ground_horizon", "fog"]:
		assert_true(sky.get(key) is Color, key)
	var jupiter := UniverseRegistry.sky_planet(20)
	assert_true(jupiter.color is Color, "Jupiter in the sky")
	assert_true(jupiter.get("bands") == true, "its cloud bands")
	assert_true(jupiter.get("spot") == true, "and its Great Red Spot")
	assert_gt(float(jupiter.size), float(UniverseRegistry.sky_planet(16).size), "bigger than Earth over the Moon: huge")
	assert_true(jupiter.get("own_moons") == true, "no moon disc of home at night")
	var moons: Array = jupiter.get("moons", [])
	assert_eq(moons.size(), 2, "Io and Ganymede")
	for m: Dictionary in moons:
		assert_lt(float(m.size), float(jupiter.size) * 0.25, "small beside Jupiter")
		assert_true(m.dir is Vector3)
	var io: Color = moons[0].color
	assert_gt(io.r, io.b + 0.3, "Io is sulphur-yellow (%s)" % io)


func test_its_sounds_music_and_no_animals() -> void:
	assert_eq(UniverseRegistry.ambience(20), {"day": &"chimes", "night": &"chimes"}, "icy chimes: no air, no wind")
	assert_eq(UniverseRegistry.classical(20), [&"snow_dancing", &"gymnopedie"] as Array[StringName], "calm icy pieces")
	assert_eq(UniverseRegistry.music(20), {}, "no loops of its own")
	assert_true(UniverseRegistry.lifeless(20), "no life we know of")
	assert_eq(UniverseRegistry.animals(20), [] as Array[StringName], "no animals")


func test_tillys_europa_things() -> void:
	var stock := UniverseRegistry.trader_stock(20)
	for id in [BlockIds.EUROPA_ICE, BlockIds.LINEA_ICE, BlockIds.DEEP_ICE, BlockIds.GLOW_ICE, BlockIds.SALT,
			BlockIds.ICE_BRICK, BlockIds.PROBE_PANEL, BlockIds.LANDING_PAD]:
		assert_true(stock.has(id), "%s to build with" % BlockIds.display_name(id))
	assert_false(stock.has(BlockIds.STAR_GOLD), "treasure is found, never sold")
	assert_false(stock.has(BlockIds.FAKE_DEEP_ICE))
	assert_eq(ShopRules.price(BlockIds.EUROPA_ICE, 20), stock[BlockIds.EUROPA_ICE], "never scaled")


func test_every_find_says_a_real_europa_fact() -> void:
	var words: Dictionary = _europa().get("secret_words")
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.ISLAND, SecretRules.GEODE]:
		assert_true(words.has(k), str(k))
		var text: String = words[k]
		assert_true(text.begins_with("You found"), text)
		assert_gt(text.find("! "), 0, "a find, then a fact: %s" % text)
		assert_true(text.ends_with("."), text)
		assert_lt(text.length(), 110, "short enough for the banner: %s" % text)
	assert_string_contains(words[SecretRules.ISLAND], "Ice Lander")
	assert_string_contains(words[SecretRules.ISLAND], "melt through the ice")
	assert_string_contains(words[SecretRules.TREASURE], "Moon")
	assert_string_contains(words[SecretRules.ROOM], "−160 °C")
	assert_string_contains(words[SecretRules.TEMPLE], "3.5 Earth days")
	assert_string_contains(words[SecretRules.GEODE], "table salt")


func test_its_sights_teach_real_facts() -> void:
	var sights := UniverseRegistry.sights(20)
	for id: StringName in [&"ocean", &"cliffs", &"plume", &"linea"]:
		assert_true(sights.has(id), str(id))
		var e: Dictionary = sights[id]
		assert_ne(str(e.get("name", "")), "", "a name for the map: %s" % id)
		assert_true(str(e.words).begins_with("You found") or str(e.words).begins_with("You reached")
			or str(e.words).begins_with("You climbed"), e.words)
		assert_lt(str(e.words).length(), 120, e.words)
	assert_string_contains(sights[&"ocean"].words, "twice as much water as all of Earth's oceans")
	assert_string_contains(sights[&"cliffs"].words, "15 to 25 km thick")
	assert_string_contains(sights[&"plume"].words, "100 km")
	assert_string_contains(sights[&"linea"].words, "salts and sulphur")


func test_no_mission_names_or_brands_in_its_words() -> void:
	var texts: Array[String] = [UniverseRegistry.landing_words(20)]
	for w: String in (_europa().get("secret_words") as Dictionary).values():
		texts.append(w)
	for e: Dictionary in UniverseRegistry.sights(20).values():
		texts.append(str(e.words))
		texts.append(str(e.name))
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 20):
		texts.append(str(LoadingHints.HINTS[i].text))
	for t in texts:
		for name in ["Hubble", "Galileo", "Clipper", "JUICE", "Juno", "Voyager", "NASA", "ESA", "JPL"]:
			assert_eq(t.find(name), -1, "general words, no mission names (§21b.2): %s" % t)


func test_its_picture_card_and_loading_hints() -> void:
	var colors := UniverseRegistry.card_colors(20)
	assert_lt((colors.top as Color).get_luminance(), 0.2, "space's dark sky on its card")
	assert_ne(UniverseArt.layout(20), UniverseArt.layout(1), "its own scene")
	var ids: Array = UniverseArt.legend(20).values()
	assert_has(ids, BlockIds.EUROPA_ICE)
	assert_has(ids, BlockIds.LINEA_ICE, "a reddish crack on the card")
	assert_has(ids, BlockIds.PROBE_PANEL, "the Ice Lander on the card")
	var own := 0
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 20):
		if int(LoadingHints.HINTS[i].get("universe", 0)) == 20:
			own += 1
			assert_lte(str(LoadingHints.HINTS[i].text).split(" ").size(), 10, LoadingHints.HINTS[i].text)
	assert_gte(own, 3, "hints of its own")
