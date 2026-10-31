extends GutTest
## Owner #78 (spec §24): Earth's own worlds are numbers 41-60 (after space's 16-40), and world 41 is "Wonders of the
## World". A save keeps a world's number (UniverseRules.MAX_UNIVERSE 60), its slots are its own (sandbox_41,
## survivor_u41), it is free for everyone and never scaled, and it is a trip away like a space world: reached from the
## Star Map's Earth card, it remembers its home, and the Star Map's HOME (and the portal by the landing) go back there.


func after_each() -> void:
	UniverseRegistry.reset()


func test_earths_own_range_comes_after_space() -> void:
	assert_eq(EarthRules.FIRST, 41)
	assert_eq(EarthRules.LAST, 60)
	assert_eq(EarthRules.WONDERS, 41, "Wonders of the World")
	assert_eq(EarthRules.FIRST, SpaceRules.LAST + 1, "right after space's 16-40")
	assert_eq(UniverseRules.MAX_UNIVERSE, 60, "a save keeps an Earth world's number")
	assert_eq(UniverseRules.valid(41), 41)
	assert_eq(UniverseRules.valid(60), 60)
	assert_eq(UniverseRules.valid(61), 60)
	for u in range(41, 61):
		assert_true(EarthRules.is_earth(u), str(u))
		assert_false(SpaceRules.is_space(u), "%d is Earth's, not space's" % u)
		assert_true(SpaceRules.is_away(u), "%d: a trip goes there and comes home" % u)
	for u: int in [0, 1, 5, 15, 16, 19, 40, 61]:
		assert_false(EarthRules.is_earth(u), str(u))
	for u: int in [16, 19, 23, 40]:
		assert_true(SpaceRules.is_away(u), "space worlds are away too (%d)" % u)
	for u in range(1, 16):
		assert_false(SpaceRules.is_away(u), "the ladder's worlds are homes (%d)" % u)


func test_its_saves_have_their_own_slots_and_keep_the_number() -> void:
	assert_eq(ModeRules.slot(ModeRules.SANDBOX, 41), "sandbox_41")
	assert_eq(UniverseRules.slot(41), "survivor_u41")
	assert_eq(ModeRules.slot(ModeRules.SURVIVOR, 41), "survivor_u41")
	assert_eq(WorldMeta.from_json('{"seed": 5, "universe": 41}').universe, 41, "the number survives a save")
	assert_eq(WorldMeta.from_json('{"seed": 5, "universe": 60}').universe, 60)
	assert_eq(WorldMeta.from_json('{"seed": 5, "universe": 99}').universe, 60, "never past Earth's last")


func test_free_for_everyone_and_never_scaled() -> void:
	assert_eq(UniverseRules.scale(41), 1, "Green Meadows' gold and prices")
	assert_eq(UniverseRules.gold(10, 41), 10)
	assert_eq(UniverseRules.price(7, 60), 7)
	assert_false(ShopCatalog.needs_plus(41), "never EasyCraft Plus")
	assert_false(ShopCatalog.needs_plus(60))


func test_a_trip_there_remembers_home_and_comes_back_to_it() -> void:
	assert_eq(SpaceRules.home_for(41, 3), 3, "Frostpeak's child goes home to Frostpeak")
	assert_eq(SpaceRules.home_for(41, 0), 1, "a lost home is Green Meadows")
	assert_eq(SpaceRules.home_for(41, 19), 1, "a space world is never a home")
	var meta := WorldMeta.new_random()
	meta.universe = 41
	SpaceRules.take_off(meta, Vector3(10, 40, 20))
	assert_eq(meta.space_return, [], "an Earth world never remembers a take-off column (it lands at its landing spot)")
	assert_eq(SpaceRules.landing_spot(meta), [])
	var arrived := SpaceRules.arrival_meta(null, 41, ModeRules.SANDBOX, DifficultyRules.NORMAL, 2)
	assert_eq(arrived.universe, 41)
	assert_eq(arrived.space_home, 2)
	assert_eq(arrived.arrival_gate, 2, "the portal home by the landing spot")


func test_the_star_map_may_land_there() -> void:
	assert_eq(SpaceRules.refusal(41, 1, [41] as Array[int], 0), "", "LAND from the meadows")
	assert_eq(SpaceRules.refusal(41, 41, [41] as Array[int], 0), "here")
	assert_eq(SpaceRules.refusal(41, 1, [] as Array[int], 0), "coming_soon", "not built: coming soon")
	assert_eq(SpaceRules.refusal(41, 1, [41] as Array[int], 1), "friends", "trips work when you play alone")
	assert_eq(SpaceRules.refusal(5, 1, [5] as Array[int], 0), "coming_soon", "a ladder universe is no trip")


func test_the_registry_knows_earths_worlds() -> void:
	assert_true(UniverseRegistry.is_earth(41))
	assert_false(UniverseRegistry.is_earth(19))
	assert_false(UniverseRegistry.is_space(41))
	assert_eq(UniverseRegistry.path_for(41), "res://world/universes/wonders.gd")
	assert_eq(UniverseRegistry.path_for(42), "", "the next Earth world is not planned yet")
	assert_true(UniverseRegistry.exists(41))
	assert_eq(UniverseRegistry.display_name(41), "Wonders of the World")
	assert_eq(UniverseRegistry.earth_available(), [41] as Array[int])
	assert_true(UniverseRegistry.trip_available().has(41), "the Star Map's LAND knows it")
	assert_true(UniverseRegistry.trip_available().has(SpaceRules.MOON))
	assert_false(UniverseRegistry.available().has(41), "not on the ladder")
	assert_false(UniverseRegistry.space_available().has(41), "not a space world")
	assert_true(UniverseRegistry.autopilot_worlds().has(41), "the developer menu's WORLD reaches it")
	var colors := UniverseRegistry.card_colors(41)
	assert_true(colors.get("ground") is Color and colors.get("top") is Color)


func test_getting_there_is_the_star_maps_until_planes_are_invented() -> void:
	assert_eq(EarthRules.way_there(41), EarthRules.BY_STAR_MAP, "LAND from the Star Map's Earth card")
	assert_eq(EarthRules.way_there(41, true), EarthRules.BY_PLANE, "the hook for spec §21e's plane")
	assert_eq(EarthRules.way_there(5), &"", "not an Earth world")
