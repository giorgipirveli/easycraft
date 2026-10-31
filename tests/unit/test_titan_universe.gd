extends GutTest
## Cosmos: Titan is world 22 (world/universes/titan.gd, spec §21b.2), Saturn's biggest moon and the only moon with thick
## air, a space world like the Moon, Mars, Europa and Io: its descriptor brings its terrain and secrets (SpaceShape TITAN,
## SpaceSecretRules: the Landing Probe), real gravity (0.14: jumps about 7 times as high), peace, its own sky (an orange
## haze by day, never space's black and never Earth's photo sky) with Saturn and its rings hanging in it, its lakes' and
## sea's liquid shown as methane, a soft wind, calm music, no animals (lifeless), Tilly's local things, the landing words,
## real facts in its finds' words and at its sights (the methane sea, a methane lake, the dunes, the icy mountains), a
## picture card and loading hints (one says a child leaps out of a methane lake). The Star Map then says LAND for Titan,
## and landing marks it in the Space Book.


func after_each() -> void:
	UniverseRegistry.reset()
	LabRules.world_gravity = 1.0


func _titan() -> Object:
	return UniverseRegistry.descriptor(SpaceRules.TITAN)


func test_titan_is_world_22_a_space_world_found_by_the_registry() -> void:
	assert_eq(SpaceRules.TITAN, 22)
	assert_has(SpaceRules.WORLDS, SpaceRules.TITAN, "the picker and the Star Map know it")
	assert_eq(SpaceRules.WORLDS.slice(0, 7), [16, 17, 18, 19, 20, 21, 22] as Array[int])
	assert_true(UniverseRegistry.is_space(22))
	assert_true(UniverseRegistry.exists(22))
	assert_true(UniverseRegistry.space_available().has(22))
	assert_false(UniverseRegistry.available().has(22), "not on the ladder")
	var d := _titan()
	assert_eq(d.get("name"), &"titan")
	assert_eq(d.get("index"), 22)
	assert_eq(UniverseRegistry.display_name(22), "Titan")
	assert_eq(UniverseRegistry.path_for(22), "res://world/universes/titan.gd")
	assert_false(ShopCatalog.needs_plus(22), "free for everyone")
	assert_eq(UniverseRules.scale(22), 1, "never scaled")
	assert_eq(ModeRules.slot(ModeRules.SANDBOX, 22), "sandbox_22")


func test_the_star_map_says_land_on_titan_and_the_space_book_marks_it() -> void:
	var s := StarMap.states(1, 1, UniverseRegistry.space_available(), 1)
	assert_eq(s[&"titan"], StarMap.LAND, "Titan can be landed on now")
	assert_eq(StarMap.states(22, 2, UniverseRegistry.space_available(), 2)[&"titan"], StarMap.HERE)
	assert_eq(StarMap.body_for_world(22), &"titan")
	var w := WonderData.new()
	assert_true(w.land_on_world(22), "the first landing on Titan")
	assert_eq(w.bodies, {"titan": WonderData.SEEN | WonderData.LANDED})


func test_its_terrain_generator_and_secrets() -> void:
	var shape := UniverseRegistry.shape_for(22, 77)
	assert_true(shape is SpaceShape)
	assert_eq((shape as SpaceShape).planet, SpaceShape.TITAN)
	var gen := UniverseRegistry.generator_for(22, 77)
	assert_true(gen is SpaceGenerator)
	assert_eq((gen as SpaceGenerator).space_shape().planet, SpaceShape.TITAN)
	assert_eq((gen as SpaceGenerator).world_seed, 77)
	var rules: Variant = _titan().call(&"secret_rules", 77, shape)
	assert_true(rules is SpaceSecretRules)
	assert_eq((rules as SpaceSecretRules).landmark().get("name"), "Landing Probe")


func test_real_gravity_peace_and_the_landing_words() -> void:
	assert_almost_eq(UniverseRegistry.gravity(22), 0.14, 0.001, "Titan's real gravity: 14% of Earth's")
	assert_true(UniverseRegistry.peaceful(22), "no monsters come by themselves")
	assert_eq(UniverseRegistry.landing_words(22), "You landed on Titan! Look up at Saturn through the orange haze!")
	var jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	LabRules.world_gravity = UniverseRegistry.gravity(22)
	var titan_jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	assert_gt(titan_jump, jump * 7.0, "about 7 times as high (%.1f vs %.1f blocks)" % [titan_jump, jump])
	assert_gt(titan_jump, float(TitanTerrain.MAX_STEP) + 0.5, "every step Titan's terrain makes is one jump")
	var hop := LabRules.step_velocity(Player.AUTO_STEP_VELOCITY, LabRules.gravity_factor(LabRules.Mode.NORMAL))
	assert_lt(hop, Player.AUTO_STEP_VELOCITY, "the step hop stays gentle (the Moon's height), as on Europa")


func test_an_orange_haze_by_day_with_saturn_and_its_rings() -> void:
	assert_eq(UniverseRegistry.space_sky(22), 0.0, "thick air: never space's black sky")
	assert_false(UniverseRegistry.photo_sky(22), "never Earth's blue photo sky")
	var sky := UniverseRegistry.sky(22)
	for key in ["sky_top", "sky_horizon", "ground_bottom", "ground_horizon", "fog"]:
		assert_true(sky.get(key) is Color, key)
		var c: Color = sky[key]
		assert_gt(c.r, c.b + 0.2, "%s is orange (%s)" % [key, c])
		assert_gt(c.get_luminance(), 0.35, "%s: a bright, friendly haze (%s)" % [key, c])
	var saturn := UniverseRegistry.sky_planet(22)
	assert_true(saturn.get("ring") == true, "Saturn's rings")
	assert_true(saturn.get("bands") == true, "and its pale cloud bands")
	assert_gte(float(saturn.size), 70.0, "big in Titan's sky")
	assert_true(saturn.get("own_moons") == true, "no moon disc of home at night")
	assert_true((saturn.get("moons", []) as Array).is_empty(), "the haze hides Saturn's other moons")


func test_its_lakes_are_liquid_methane() -> void:
	assert_eq(_titan().get("liquid"), TitanRules.METHANE)
	assert_true(TitanRules.floaty(_titan().get("liquid")), "a swimmer leaps out of it")


func test_its_sounds_music_and_no_animals() -> void:
	assert_eq(UniverseRegistry.ambience(22), {"day": &"wind", "night": &"wind"}, "a soft wind in the thick air")
	assert_eq(UniverseRegistry.classical(22), [&"morning_mood", &"air"] as Array[StringName])
	for id in UniverseRegistry.classical(22):
		assert_false(MusicPieces.PIECES[id].moods.has(MusicPieces.BOSS), "a piece a day or a night plays, not a boss's")
	assert_eq(UniverseRegistry.music(22), {}, "no loops of its own")
	assert_true(UniverseRegistry.lifeless(22), "no life we know of")
	assert_eq(UniverseRegistry.animals(22), [] as Array[StringName], "no animals")


func test_tillys_titan_things() -> void:
	var stock := UniverseRegistry.trader_stock(22)
	for id in [BlockIds.TITAN_SOIL, BlockIds.ICE_PEBBLES, BlockIds.DUNE_SAND, BlockIds.WET_SHORE, BlockIds.ICY_ROCK,
			BlockIds.SHORE_CRYSTAL, BlockIds.TITAN_BRICK, BlockIds.PROBE_SHELL, BlockIds.PARACHUTE, BlockIds.PROBE_LAMP,
			BlockIds.LANDING_PAD]:
		assert_true(stock.has(id), "%s to build with" % BlockIds.display_name(id))
	assert_false(stock.has(BlockIds.STAR_GOLD), "treasure is found, never sold")
	assert_false(stock.has(BlockIds.FAKE_ICY_ROCK))
	assert_eq(ShopRules.price(BlockIds.TITAN_SOIL, 22), stock[BlockIds.TITAN_SOIL], "never scaled")


func test_every_find_says_a_real_titan_fact() -> void:
	var words: Dictionary = _titan().get("secret_words")
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.ISLAND, SecretRules.GEODE]:
		assert_true(words.has(k), str(k))
		var text: String = words[k]
		assert_true(text.begins_with("You found"), text)
		assert_gt(text.find("! "), 0, "a find, then a fact: %s" % text)
		assert_true(text.ends_with("."), text)
		assert_lt(text.length(), 110, "short enough for the banner: %s" % text)
	assert_string_contains(words[SecretRules.ISLAND], "Landing Probe")
	assert_string_contains(words[SecretRules.ISLAND], "2005")
	assert_string_contains(words[SecretRules.TREASURE], "Mercury")
	assert_string_contains(words[SecretRules.ROOM], "water ice")
	assert_string_contains(words[SecretRules.TEMPLE], "16 Earth days")
	assert_string_contains(words[SecretRules.GEODE], "bathtub")


func test_its_sights_teach_real_facts() -> void:
	var sights := UniverseRegistry.sights(22)
	for id: StringName in [&"sea", &"lake", &"dunes", &"mountain"]:
		assert_true(sights.has(id), str(id))
		var e: Dictionary = sights[id]
		assert_ne(str(e.get("name", "")), "", "a name for the map: %s" % id)
		assert_true(str(e.words).begins_with("You found") or str(e.words).begins_with("You reached")
			or str(e.words).begins_with("You climbed"), e.words)
		assert_lt(str(e.words).length(), 120, e.words)
	assert_string_contains(sights[&"sea"].words, "north pole")
	assert_string_contains(sights[&"lake"].words, "rain")
	assert_string_contains(sights[&"dunes"].words, "haze")
	assert_string_contains(sights[&"mountain"].words, "3.3 km")


func test_no_mission_names_or_brands_in_its_words() -> void:
	var texts: Array[String] = [UniverseRegistry.landing_words(22)]
	for w: String in (_titan().get("secret_words") as Dictionary).values():
		texts.append(w)
	for e: Dictionary in UniverseRegistry.sights(22).values():
		texts.append(str(e.words))
		texts.append(str(e.name))
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 22):
		texts.append(str(LoadingHints.HINTS[i].text))
	for t in texts:
		for name in ["Huygens", "Cassini", "Dragonfly", "Voyager", "Pioneer", "Hubble", "NASA", "ESA", "JPL"]:
			assert_eq(t.find(name), -1, "general words, no mission names (§21b.2): %s" % t)


func test_its_picture_card_and_loading_hints() -> void:
	var colors := UniverseRegistry.card_colors(22)
	assert_gt((colors.top as Color).r, (colors.top as Color).b + 0.2, "an orange haze on its card")
	assert_ne(UniverseArt.layout(22), UniverseArt.layout(21), "its own scene")
	var ids: Array = UniverseArt.legend(22).values()
	assert_has(ids, BlockIds.TITAN_SOIL)
	assert_has(ids, BlockIds.PROBE_SHELL, "the Landing Probe on the card")
	assert_has(ids, BlockIds.PARACHUTE, "and its parachute")
	var own := 0
	var leap := false
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 22):
		if int(LoadingHints.HINTS[i].get("universe", 0)) == 22:
			own += 1
			var text := str(LoadingHints.HINTS[i].text)
			assert_lte(text.split(" ").size(), 10, text)
			if text.contains("JUMP") and text.contains("leap"):
				leap = true
	assert_gte(own, 3, "hints of its own")
	assert_true(leap, "a hint says a child leaps out of a methane lake")
