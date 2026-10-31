extends GutTest
## Owner #78 (spec §24): world 41, Wonders of the World (world/universes/wonders.gd): Earth's own first world, found by
## the registry, free and peaceful, with Earth's gravity, sky and animals; its terrain (WondersShape, WondersGenerator)
## and secrets (WondersSecretRules); the wonders as its sights (their names and real facts); Tilly's local things (what
## the wonders were built of); its landing words, loading hints and picture; the Star Map lands there from Earth's card.


func after_each() -> void:
	UniverseRegistry.reset()


func _d() -> Object:
	return UniverseRegistry.descriptor(EarthRules.WONDERS)


func test_world_41_is_earths_wonders() -> void:
	var d := _d()
	assert_not_null(d)
	assert_eq(d.get("name"), &"wonders")
	assert_eq(d.get("index"), 41)
	assert_eq(UniverseRegistry.display_name(41), "Wonders of the World")
	assert_eq(UniverseRegistry.path_for(41), "res://world/universes/wonders.gd")


func test_earths_gravity_sky_and_animals_and_peace() -> void:
	assert_eq(UniverseRegistry.gravity(41), 1.0, "Earth's gravity")
	assert_true(UniverseRegistry.peaceful(41), "no monster comes by itself")
	assert_false(UniverseRegistry.lifeless(41), "Earth's animals")
	assert_eq(UniverseRegistry.animals(41), AnimalRules.MEADOWS_KINDS as Array[StringName])
	assert_true(UniverseRegistry.photo_sky(41), "Earth's blue sky with clouds")
	assert_eq(UniverseRegistry.space_sky(41), 0.0)
	assert_eq(UniverseRegistry.sky_planet(41), {}, "no planet hangs in Earth's sky")
	assert_eq(UniverseRegistry.sun_size(41), 1.0)
	assert_eq(UniverseRegistry.landing_words(41), "Welcome to the Wonders of the World! Follow the red arrow: the Seven "
		+ "Ancient Wonders are here, the New Seven along the Wonders Road, nature's seven along the Nature Trail.")


func test_its_terrain_generator_and_secrets() -> void:
	assert_true(UniverseRegistry.shape_for(41, 5) is WondersShape)
	assert_true(UniverseRegistry.shape_for(41, 5, 2) is WondersShape, "a new world's terrain version too")
	var gen := UniverseRegistry.generator_for(41, 5)
	assert_true(gen is WondersGenerator)
	assert_eq((gen as WondersGenerator).world_seed, 5)
	var rules: Variant = _d().call(&"secret_rules", 5, UniverseRegistry.shape_for(41, 5))
	assert_true(rules is WondersSecretRules)
	assert_null(DepositRules.for_world(5, UniverseRegistry.shape_for(41, 5)), "no prospecting deposits on the tour")


func test_the_wonders_are_its_sights_with_their_real_facts() -> void:
	var sights := UniverseRegistry.sights(41)
	assert_eq(sights.size(), 21, "three tours: the ancient seven, the New Seven and nature's seven")
	for id in WonderFacts.ORDER:
		assert_true(sights.has(id), str(id))
		assert_eq(sights[id].name, WonderFacts.display_name(id))
		assert_true(str(sights[id].words).begins_with("You reached "), str(sights[id].words))   # (Petra: no "the")


func test_tilly_sells_what_the_wonders_were_built_of() -> void:
	var stock := UniverseRegistry.trader_stock(41)
	for id: int in [BlockIds.LIMESTONE, BlockIds.MARBLE, BlockIds.MARBLE_COLUMN, BlockIds.BRONZE, BlockIds.GLAZED_BRICK]:
		assert_true(stock.has(id), BlockIds.display_name(id))
	for id: int in stock:
		assert_false(SecretRules.is_fake_wall(id), "never a hidden door")


func test_the_star_map_lands_at_the_wonders_from_earths_card() -> void:
	var s := StarMap.states(1, 1, UniverseRegistry.trip_available(), 1)
	assert_eq(s[&"earth"], StarMap.LAND)
	assert_eq(StarMap.action_words_for(&"earth", s[&"earth"]), "Wonders of the World: LAND")
	assert_eq(StarMap.body_for_world(41), &"earth")
	assert_false(MissionRules.needs_mission(41, []), "no rocket needed to come down to Earth")
	var w := WonderData.new()
	assert_false(w.land_on_world(41), "Earth is no Space Book landing")


func test_loading_hints_and_its_picture() -> void:
	var fit := LoadingHints.fitting(ModeRules.SANDBOX, 41)
	var own := fit.filter(func(i: int) -> bool: return LoadingHints.HINTS[i].get("universe", 0) == 41)
	assert_gte(own.size(), 4, "its own hints")
	assert_eq(UniverseArt.layout(41).size(), UniverseArt.ROWS)
	for row: String in UniverseArt.layout(41):
		assert_eq(row.length(), UniverseArt.COLUMNS)
	var legend := UniverseArt.legend(41)
	assert_eq(legend.get("L"), BlockIds.LIMESTONE, "the pyramid in its picture")


func test_every_block_named_in_its_descriptor_exists() -> void:
	for id: int in UniverseRegistry.trader_stock(41):
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
