extends GutTest
## Cosmos: Venus's cloud city is world 24 (world/universes/venus.gd, spec §21b.2), a space world like the Moon, Mars,
## Europa, Io, Titan and Mercury: its descriptor brings its terrain and secrets (SpaceShape VENUS, SpaceSecretRules: the
## Research Blimp), real gravity (0.9: almost home's), peace, a hazy golden sky of its own (thick air: never space's
## black, never Earth's photo sky) where the Sun is a little bigger than at home and rises in the west (Venus spins
## backwards), Earth and our Moon as tiny points and no moon of its own, a warm breeze that lifts a child who falls back
## up to the city (its void line far over the clouds), a gentle wind, calm music, no animals (lifeless), Tilly's local
## things, the landing words, real facts in its finds' words and at its sights (the cloud scope, the airship dock, the
## sky garden, the cloud homes, the west lookout), a helper robot and the aliens' camp, a mission, a picture card and
## loading hints. The acid clouds and the heat far below are facts, never a danger. The Star Map then says LAND for Venus.


func after_each() -> void:
	UniverseRegistry.reset()
	LabRules.world_gravity = 1.0


func _venus() -> Object:
	return UniverseRegistry.descriptor(SpaceRules.VENUS)


func test_venus_is_world_24_a_space_world_found_by_the_registry() -> void:
	assert_eq(SpaceRules.VENUS, 24)
	assert_has(SpaceRules.WORLDS, SpaceRules.VENUS, "the picker and the Star Map know it")
	assert_eq(SpaceRules.WORLDS.slice(0, 9), [16, 17, 18, 19, 20, 21, 22, 23, 24] as Array[int])
	assert_true(UniverseRegistry.is_space(24))
	assert_true(UniverseRegistry.exists(24))
	assert_true(UniverseRegistry.space_available().has(24))
	assert_false(UniverseRegistry.available().has(24), "not on the ladder")
	var d := _venus()
	assert_eq(d.get("name"), &"venus")
	assert_eq(d.get("index"), 24)
	assert_eq(UniverseRegistry.display_name(24), "Venus")
	assert_eq(UniverseRegistry.path_for(24), "res://world/universes/venus.gd")
	assert_false(ShopCatalog.needs_plus(24), "free for everyone")
	assert_eq(UniverseRules.scale(24), 1, "never scaled")
	assert_eq(ModeRules.slot(ModeRules.SANDBOX, 24), "sandbox_24")


func test_the_star_map_says_land_on_venus_and_the_space_book_marks_it() -> void:
	var s := StarMap.states(1, 1, UniverseRegistry.space_available(), 1)
	assert_eq(s[&"venus"], StarMap.LAND, "Venus can be landed on now")
	assert_eq(StarMap.states(24, 2, UniverseRegistry.space_available(), 2)[&"venus"], StarMap.HERE)
	assert_eq(StarMap.body_for_world(24), &"venus")
	var no_route: Array[int] = []
	assert_eq(StarMap.states(1, 1, UniverseRegistry.space_available(), 1, no_route)[&"venus"], StarMap.MISSION,
		"a mission first (spec §21d.5)")
	var w := WonderData.new()
	assert_true(w.land_on_world(24), "the first landing on Venus")
	assert_eq(w.bodies, {"venus": WonderData.SEEN | WonderData.LANDED})


func test_its_terrain_generator_and_secrets() -> void:
	var shape := UniverseRegistry.shape_for(24, 77)
	assert_true(shape is SpaceShape)
	assert_eq((shape as SpaceShape).planet, SpaceShape.VENUS)
	var gen := UniverseRegistry.generator_for(24, 77)
	assert_true(gen is SpaceGenerator)
	assert_eq((gen as SpaceGenerator).space_shape().planet, SpaceShape.VENUS)
	assert_eq((gen as SpaceGenerator).world_seed, 77)
	var rules: Variant = _venus().call(&"secret_rules", 77, shape)
	assert_true(rules is SpaceSecretRules)
	assert_eq((rules as SpaceSecretRules).landmark().get("name"), "Research Blimp")


func test_real_gravity_peace_and_the_landing_words() -> void:
	assert_almost_eq(UniverseRegistry.gravity(24), 0.9, 0.001, "Venus's real gravity: 90% of Earth's")
	assert_true(UniverseRegistry.peaceful(24), "no monsters come by themselves")
	assert_string_contains(UniverseRegistry.landing_words(24), "cloud city")
	var jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	LabRules.world_gravity = UniverseRegistry.gravity(24)
	var venus_jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	assert_gt(venus_jump, jump, "a little higher than at home (%.2f vs %.2f blocks)" % [venus_jump, jump])
	assert_lt(venus_jump, jump * 1.2, "almost home's")
	assert_gt(venus_jump, 1.3, "every step in the city is a block at most: one jump")


## The warm breeze: a child who falls off a deck or a bridge is lifted back to the city far over the clouds.
func test_a_warm_breeze_lifts_a_faller_back_to_the_city() -> void:
	var d := _venus()
	assert_true(DragonRules.world_has_void(d, false), "the city floats over the clouds")
	assert_eq(DragonRules.rescue_y(d), VenusTerrain.LIFT_Y, "its line far over the clouds")
	assert_string_contains(DragonRules.carried_back_words(d), "breeze")
	assert_ne(DragonRules.carried_back_words(d), DragonRules.CARRIED_BACK, "not the Dragon Realm's wind")


## Thick air: a hazy golden sky of its own (never space's black, never the photo sky), the Sun a little bigger than at
## home (Venus is closer to it) and rising in the west (Venus spins backwards), Earth and our Moon as tiny points, no
## moon disc of its own.
func test_a_golden_sky_where_the_sun_rises_in_the_west() -> void:
	assert_eq(UniverseRegistry.space_sky(24), 0.0, "thick air: its own sky")
	assert_false(UniverseRegistry.photo_sky(24), "never Earth's blue photo sky")
	assert_almost_eq(UniverseRegistry.sun_size(24), 1.4, 0.01, "the Sun a little bigger than at home")
	assert_true(UniverseRegistry.sun_rises_west(24), "Venus spins backwards")
	assert_false(UniverseRegistry.sun_rises_west(SpaceRules.MERCURY), "a world without the field")
	assert_false(UniverseRegistry.sun_rises_west(1))
	var sky := UniverseRegistry.sky(24)
	var top: Color = sky.sky_top
	assert_gt(top.r, top.b + 0.3, "a golden, hazy sky (%s)" % top)
	assert_eq(top, FlightLooks.SKY[SpaceRules.VENUS][0], "the flight's picture of its sky is the world's")
	assert_eq(sky.sky_horizon, FlightLooks.SKY[SpaceRules.VENUS][1])
	var planet := UniverseRegistry.sky_planet(24)
	assert_true(planet.get("own_moons") == true, "Venus has no moon: home's big moon disc never shows")
	assert_lte(float(planet.size), 6.0, "Earth, a tiny bright point")
	assert_gt((planet.color as Color).b, (planet.color as Color).r, "Earth is blue")
	assert_eq((planet.get("moons", []) as Array).size(), 1, "and our Moon beside it")


func test_its_sounds_music_and_no_animals() -> void:
	assert_eq(UniverseRegistry.ambience(24), {"day": &"wind", "night": &"chimes"}, "a gentle wind in its air")
	assert_eq(UniverseRegistry.classical(24), [&"fur_elise", &"air"] as Array[StringName])
	for id in UniverseRegistry.classical(24):
		assert_false(MusicPieces.PIECES[id].moods.has(MusicPieces.BOSS), "a piece a day or a night plays, not a boss's")
	assert_eq(UniverseRegistry.music(24), {}, "no loops of its own")
	assert_true(UniverseRegistry.lifeless(24), "no life we know of")
	assert_eq(UniverseRegistry.animals(24), [] as Array[StringName], "no animals")


func test_tillys_cloud_city_things() -> void:
	var stock := UniverseRegistry.trader_stock(24)
	for id in [BlockIds.CLOUD_DECK, BlockIds.FLOAT_HULL, BlockIds.SKY_TURF, BlockIds.SKY_BRIDGE, BlockIds.CLOUD_LAMP,
			BlockIds.SKY_FRAME, BlockIds.HOME_PANEL, BlockIds.BLIMP_SKIN, BlockIds.BLIMP_STRIPE, BlockIds.GONDOLA,
			BlockIds.SOLAR_FILM, BlockIds.CLOUD_CRYSTAL, BlockIds.TELESCOPE, BlockIds.VENUS_CLOUD, BlockIds.LANDING_PAD]:
		assert_true(stock.has(id), "%s to build with" % BlockIds.display_name(id))
	assert_false(stock.has(BlockIds.STAR_GOLD), "treasure is found, never sold")
	assert_false(stock.has(BlockIds.FAKE_FLOAT_HULL))
	assert_eq(ShopRules.price(BlockIds.CLOUD_DECK, 24), stock[BlockIds.CLOUD_DECK], "never scaled")


func test_every_find_says_a_real_venus_fact() -> void:
	var words: Dictionary = _venus().get("secret_words")
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.ISLAND, SecretRules.GEODE]:
		assert_true(words.has(k), str(k))
		var text: String = words[k]
		assert_true(text.begins_with("You found"), text)
		assert_gt(text.find("! "), 0, "a find, then a fact: %s" % text)
		assert_true(text.ends_with("."), text)
		assert_lt(text.length(), 110, "short enough for the banner: %s" % text)
	assert_string_contains(words[SecretRules.ISLAND], "Research Blimp")
	assert_string_contains(words[SecretRules.ISLAND], "balloons")
	assert_string_contains(words[SecretRules.TREASURE], "twin")
	assert_string_contains(words[SecretRules.ROOM], "465 °C")
	assert_string_contains(words[SecretRules.TEMPLE], "hottest planet")
	assert_string_contains(words[SecretRules.GEODE], "4 Earth days")


func test_its_sights_teach_real_facts() -> void:
	var sights := UniverseRegistry.sights(24)
	assert_eq(sights.keys(), [&"scope", &"dock", &"garden", &"homes", &"lookout"])
	for id: StringName in sights:
		var e: Dictionary = sights[id]
		assert_ne(str(e.get("name", "")), "", "a name for the map: %s" % id)
		assert_true(str(e.words).begins_with("You found"), e.words)
		assert_lt(str(e.words).length(), 120, e.words)
	assert_string_contains(sights[&"scope"].words, "sulfuric acid")
	assert_string_contains(sights[&"dock"].words, "air we breathe")
	assert_string_contains(sights[&"garden"].words, "50 km")
	assert_string_contains(sights[&"homes"].words, "243")
	assert_string_contains(sights[&"homes"].words, "225")
	assert_string_contains(sights[&"lookout"].words, "west")


## The acid clouds and the heat far below are facts, never a danger: no word says anything hurts, burns or is scary.
func test_the_clouds_and_the_heat_are_facts_never_a_danger() -> void:
	for t in _texts():
		for w in ["hurt", "burn", "danger", "dangerous", "scary", "careful", "too hot", "die", "melt you", "fall to",
				"crash", "poison", "deadly"]:
			assert_eq(t.to_lower().find(w), -1, "a friendly world (spec §3c): %s" % t)


func test_no_mission_names_or_brands_in_its_words() -> void:
	for t in _texts():
		for name in ["HAVOC", "Vega", "VEGA", "Venera", "Magellan", "Pioneer", "Mariner", "Akatsuki", "Venus Express",
				"DAVINCI", "VERITAS", "EnVision", "NASA", "ESA", "JAXA", "JPL", "Parker"]:
			assert_eq(t.find(name), -1, "general words, no mission names (§21b.2): %s" % t)


func _texts() -> Array[String]:
	var texts: Array[String] = [UniverseRegistry.landing_words(24), DragonRules.carried_back_words(_venus())]
	for w: String in (_venus().get("secret_words") as Dictionary).values():
		texts.append(w)
	for e: Dictionary in UniverseRegistry.sights(24).values():
		texts.append(str(e.words))
		texts.append(str(e.name))
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 24):
		texts.append(str(LoadingHints.HINTS[i].text))
	var r := CreatureWords.robot(24)
	for k in ["hello", "fact", "sample"]:
		texts.append(str(r.get(k, "")))
	for q: Dictionary in r.get("questions", []):
		texts.append(str(q.q))
		texts.append(str(q.hint))
	var m := MissionRules.for_world(24)
	texts.append(str(m.get("fact", "")))
	return texts


func test_its_picture_card_and_loading_hints() -> void:
	var colors := UniverseRegistry.card_colors(24)
	assert_gt((colors.top as Color).r, 0.8, "a golden sky on its card")
	assert_ne(UniverseArt.layout(24), UniverseArt.layout(23), "its own scene")
	var ids: Array = UniverseArt.legend(24).values()
	assert_has(ids, BlockIds.BLIMP_SKIN, "the Research Blimp on the card")
	assert_has(ids, BlockIds.CLOUD_DECK, "over a deck")
	var own := 0
	var west := false
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 24):
		if int(LoadingHints.HINTS[i].get("universe", 0)) == 24:
			own += 1
			var text := str(LoadingHints.HINTS[i].text)
			assert_lte(text.split(" ").size(), 10, text)
			if text.contains("west"):
				west = true
	assert_gte(own, 4, "hints of its own")
	assert_true(west, "a hint says the Sun rises in the west")


func test_its_helper_robot_and_the_aliens_camp() -> void:
	assert_true(CreatureWords.has_robot(24))
	var r := CreatureWords.robot(24)
	assert_string_contains(str(r.hello), str(r.name))
	assert_string_contains(str(r.sample), "sample")
	assert_eq((r.questions as Array).size(), 3)
	assert_true(AlienRules.has_camp(24), "the aliens' travelling camp")
	var c := CreatureWords.camp(24)
	assert_eq(CreatureWords.alien(c.explorer).role, &"explorer")
	assert_eq(CreatureWords.alien(c.trader).role, &"trader")
	assert_true(MiniRules.gives_mini(AlienRules.mini_kind(c.explorer)), "a friend comes along as a mini-buddy")
	assert_true(SpaceCreatures.wanted(24, ModeRules.SANDBOX))


func test_a_mission_to_venus() -> void:
	var m := MissionRules.for_world(24)
	assert_false(m.is_empty())
	assert_eq(m.body, &"venus")
	assert_eq(str(m.trip), "about 5 months")
	assert_between(int(m.days), 140, 160, "about 5 months of air and water")
	assert_true(bool(m.air), "thick air: a heat shield and a parachute")
	assert_almost_eq(MissionRules.need(m), 13.4, 0.001, "9.4 + 3.5 + 0.5")
	assert_string_contains(str(m.distance), "38")
	assert_eq(FlightPlan.REAL_TRIP[SpaceRules.VENUS], "about 5 months", "the flight says the board's trip")
