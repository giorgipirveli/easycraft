extends GutTest
## Cosmos: Saturn's rings are world 25 (world/universes/rings.gd, spec §21b.2), a space world like the Moon, Mars,
## Europa, Io, Titan, Mercury and Venus's cloud city: its descriptor brings its terrain and secrets (SpaceShape RINGS,
## SpaceSecretRules: the Ring Explorer), the game's very low gravity (0.05: long, slow jumps from chunk to chunk; the
## words say a real chunk's pull is far weaker still), peace, space's black starry sky with Saturn huge over the northern
## horizon (bands, its rings edge-on) and the Sun small and far, Titan and other moons, the space suit's little jets that
## carry a faller back to the ice (its void line under every chunk), soft chimes, calm music, no animals (lifeless),
## Tilly's local things, the landing words, real facts in its finds' words and at its sights (the Saturn scope, the Ring
## Station, the Cassini Division, the C ring, the F ring, Pan), a helper robot and the aliens' camp, a mission, a picture
## card and loading hints. Falling is never a danger and Saturn is never reached. The Star Map then says LAND for Saturn.


func after_each() -> void:
	UniverseRegistry.reset()
	LabRules.world_gravity = 1.0


func _rings() -> Object:
	return UniverseRegistry.descriptor(SpaceRules.RINGS)


func test_the_rings_are_world_25_a_space_world_found_by_the_registry() -> void:
	assert_eq(SpaceRules.RINGS, 25)
	assert_has(SpaceRules.WORLDS, SpaceRules.RINGS, "the picker and the Star Map know it")
	assert_eq(SpaceRules.WORLDS.slice(0, 10), [16, 17, 18, 19, 20, 21, 22, 23, 24, 25] as Array[int])
	assert_true(UniverseRegistry.is_space(25))
	assert_true(UniverseRegistry.exists(25))
	assert_true(UniverseRegistry.space_available().has(25))
	assert_false(UniverseRegistry.available().has(25), "not on the ladder")
	var d := _rings()
	assert_eq(d.get("name"), &"rings")
	assert_eq(d.get("index"), 25)
	assert_eq(UniverseRegistry.display_name(25), "Saturn's Rings")
	assert_eq(UniverseRegistry.path_for(25), "res://world/universes/rings.gd")
	assert_false(ShopCatalog.needs_plus(25), "free for everyone")
	assert_eq(UniverseRules.scale(25), 1, "never scaled")
	assert_eq(ModeRules.slot(ModeRules.SANDBOX, 25), "sandbox_25")


func test_the_star_map_says_land_on_saturn_and_the_space_book_marks_it() -> void:
	var s := StarMap.states(1, 1, UniverseRegistry.space_available(), 1)
	assert_eq(s[&"saturn"], StarMap.LAND, "Saturn's rings can be landed on now")
	assert_eq(StarMap.action_words_for(&"saturn", StarMap.LAND), "Saturn's rings: LAND", "the card says where")
	assert_eq(StarMap.states(25, 2, UniverseRegistry.space_available(), 2)[&"saturn"], StarMap.HERE)
	assert_eq(StarMap.body_for_world(25), &"saturn")
	var no_route: Array[int] = []
	assert_eq(StarMap.states(1, 1, UniverseRegistry.space_available(), 1, no_route)[&"saturn"], StarMap.MISSION,
		"a mission first (spec §21d.5)")
	assert_eq(StarMap.states(1, 1, UniverseRegistry.space_available(), 1)[&"titan"], StarMap.LAND, "Titan stays Titan")
	var w := WonderData.new()
	assert_true(w.land_on_world(25), "the first landing in Saturn's rings")
	assert_eq(w.bodies, {"saturn": WonderData.SEEN | WonderData.LANDED})


func test_its_terrain_generator_and_secrets() -> void:
	var shape := UniverseRegistry.shape_for(25, 77)
	assert_true(shape is SpaceShape)
	assert_eq((shape as SpaceShape).planet, SpaceShape.RINGS)
	var gen := UniverseRegistry.generator_for(25, 77)
	assert_true(gen is SpaceGenerator)
	assert_eq((gen as SpaceGenerator).space_shape().planet, SpaceShape.RINGS)
	assert_eq((gen as SpaceGenerator).world_seed, 77)
	var rules: Variant = _rings().call(&"secret_rules", 77, shape)
	assert_true(rules is SpaceSecretRules)
	assert_eq((rules as SpaceSecretRules).landmark().get("name"), "Ring Explorer")


## The spec's gravity (0.05 of Earth's): a jump floats very high and long, so a child hops from chunk to chunk; the
## step onto a one-block ledge stays gentle (LabRules.step_velocity: as high as on the Moon).
func test_very_low_gravity_long_slow_jumps_and_the_landing_words() -> void:
	assert_almost_eq(UniverseRegistry.gravity(25), 0.05, 0.0001, "the spec's 0.05, never clamped")
	assert_true(UniverseRegistry.peaceful(25), "no monsters come by themselves")
	assert_string_contains(UniverseRegistry.landing_words(25), "rings")
	LabRules.world_gravity = UniverseRegistry.gravity(25)
	var jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	var air := LabRules.air_time(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	assert_gt(jump, 30.0, "a jump floats very high (%.1f blocks)" % jump)
	assert_between(air, 10.0, 20.0, "long and slow (%.1f s)" % air)
	assert_gt(air * Player.WALK_SPEED, 60.0, "far enough to cross the Cassini Division (%.0f blocks)" % (air * Player.WALK_SPEED))
	var step := LabRules.step_velocity(Player.AUTO_STEP_VELOCITY, LabRules.gravity_factor(LabRules.Mode.NORMAL))
	var hop := step * step / (2.0 * Player.GRAVITY * 0.05)
	assert_between(hop, 1.05, 3.6, "a step onto a ledge clears it gently (%.2f blocks)" % hop)


## Between the chunks: the space suit's little jets carry a faller back to the ice, far above Saturn.
func test_the_suits_jets_carry_a_faller_back_to_the_ice() -> void:
	var d := _rings()
	assert_true(DragonRules.world_has_void(d, false), "the chunks float over open space")
	assert_eq(DragonRules.rescue_y(d), RingsTerrain.LIFT_Y, "its line under every chunk")
	assert_string_contains(DragonRules.carried_back_words(d), "jets")
	assert_ne(DragonRules.carried_back_words(d), DragonRules.CARRIED_BACK, "not the Dragon Realm's wind")


## No air: space's black sky with stars by day (never the photo sky), the Sun about ten times smaller than at home,
## Saturn huge over the northern horizon with its bands and its rings edge-on, Titan and other moons, no moon disc of
## home's.
func test_saturn_huge_in_a_black_sky_the_sun_small_and_far() -> void:
	assert_eq(UniverseRegistry.space_sky(25), 1.0, "space's black sky")
	assert_false(UniverseRegistry.photo_sky(25), "never Earth's blue photo sky")
	assert_almost_eq(UniverseRegistry.sun_size(25), 0.1, 0.001, "the Sun about ten times smaller than at home")
	var planet := UniverseRegistry.sky_planet(25)
	assert_true(planet.get("own_moons") == true, "Saturn's moons: home's big moon disc never shows")
	assert_true(planet.get("bands") == true, "Saturn's cloud bands")
	assert_true(planet.get("ring_edge") == true, "its rings seen edge-on: we stand in them")
	assert_gte(float(planet.size), 300.0, "Saturn is huge from its rings")
	var dir: Vector3 = planet.dir
	assert_lt(dir.z, -0.9, "over the northern horizon (towards Saturn, -z)")
	assert_between(dir.y, -0.1, 0.1, "centred on the horizon: half above the rings, half below")
	var color: Color = planet.color
	assert_gt(color.r, color.b + 0.15, "pale gold")
	assert_gte((planet.get("moons", []) as Array).size(), 3, "Titan and other moons")
	var titan: Dictionary = planet.moons[0]
	assert_gt((titan.color as Color).r, (titan.color as Color).b + 0.3, "Titan is orange")


func test_its_sounds_music_and_no_animals() -> void:
	assert_eq(UniverseRegistry.ambience(25), {"day": &"chimes", "night": &"chimes"}, "soft icy chimes")
	assert_eq(UniverseRegistry.classical(25), [&"waltz_flowers", &"moonlight"] as Array[StringName])
	for id in UniverseRegistry.classical(25):
		assert_false(MusicPieces.PIECES[id].moods.has(MusicPieces.BOSS), "a piece a day or a night plays, not a boss's")
	assert_eq(UniverseRegistry.music(25), {}, "no loops of its own")
	assert_true(UniverseRegistry.lifeless(25), "no life we know of")
	assert_eq(UniverseRegistry.animals(25), [] as Array[StringName], "no animals")


func test_tillys_ring_things() -> void:
	var stock := UniverseRegistry.trader_stock(25)
	for id in [BlockIds.RING_ICE, BlockIds.RING_FROST, BlockIds.DUSTY_ICE, BlockIds.RING_ROCK, BlockIds.MOONLET_ICE,
			BlockIds.RIDGE_DUST, BlockIds.RING_CRYSTAL, BlockIds.STATION_PANEL, BlockIds.STATION_WINDOW,
			BlockIds.STATION_LAMP, BlockIds.RADIO_DISH, BlockIds.POWER_PACK, BlockIds.TRUSS, BlockIds.RING_BEACON,
			BlockIds.SATURN_BAND, BlockIds.LANDING_PAD]:
		assert_true(stock.has(id), "%s to build with" % BlockIds.display_name(id))
	assert_false(stock.has(BlockIds.STAR_GOLD), "treasure is found, never sold")
	assert_false(stock.has(BlockIds.FAKE_RING_ICE))
	assert_eq(ShopRules.price(BlockIds.RING_ICE, 25), stock[BlockIds.RING_ICE], "never scaled")


func test_every_find_says_a_real_rings_fact() -> void:
	var words: Dictionary = _rings().get("secret_words")
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.ISLAND, SecretRules.GEODE]:
		assert_true(words.has(k), str(k))
		var text: String = words[k]
		assert_true(text.begins_with("You found"), text)
		assert_gt(text.find("! "), 0, "a find, then a fact: %s" % text)
		assert_true(text.ends_with("."), text)
		assert_lt(text.length(), 110, "short enough for the banner: %s" % text)
	assert_string_contains(words[SecretRules.ISLAND], "Ring Explorer")
	assert_string_contains(words[SecretRules.ISLAND], "22 times")
	assert_string_contains(words[SecretRules.TREASURE], "ice and rock")
	assert_string_contains(words[SecretRules.ROOM], "10 metres thick")
	assert_string_contains(words[SecretRules.TEMPLE], "270 moons")
	assert_string_contains(words[SecretRules.GEODE], "rain down")


func test_its_sights_teach_real_facts() -> void:
	var sights := UniverseRegistry.sights(25)
	assert_eq(sights.keys(), [&"scope", &"station", &"cassini", &"c_ring", &"f_ring", &"pan"])
	for id: StringName in sights:
		var e: Dictionary = sights[id]
		assert_ne(str(e.get("name", "")), "", "a name for the map: %s" % id)
		assert_true(str(e.words).begins_with("You found"), e.words)
		assert_lt(str(e.words).length(), 120, e.words)
	assert_string_contains(sights[&"scope"].words, "760 Earths")
	assert_string_contains(sights[&"station"].words, "80 minutes")
	assert_string_contains(sights[&"cassini"].words, "Cassini Division")
	assert_string_contains(sights[&"cassini"].words, "4,700 km")
	assert_string_contains(sights[&"cassini"].words, "1675")
	assert_string_contains(sights[&"c_ring"].words, "dustier")
	assert_string_contains(sights[&"f_ring"].words, "Prometheus and Pandora")
	assert_string_contains(sights[&"pan"].words, "walnut")
	assert_string_contains(sights[&"pan"].words, "Encke Gap")
	var map_ids: Array = []
	for s: Dictionary in SpaceShape.new(12345, SpaceShape.RINGS).sights():
		map_ids.append(s.id)
	assert_eq(map_ids, sights.keys(), "MY MAP shows all six from the landing")


## Falling is never a danger: no word says anything hurts, burns, crashes or is scary, nor that a child falls into
## Saturn.
func test_falling_is_never_a_danger() -> void:
	for t in _texts():
		for w in ["hurt", "burn", "danger", "dangerous", "scary", "careful", "die", "crash", "deadly", "fall into",
				"lost in space", "smash"]:
			assert_eq(t.to_lower().find(w), -1, "a friendly world (spec §3c): %s" % t)


func test_no_mission_names_or_brands_in_its_words() -> void:
	for t in _texts():
		for name in ["Cassini-Huygens", "Cassini spacecraft", "Cassini mission", "Voyager", "Pioneer", "Huygens",
				"Grand Finale", "Dragonfly", "NASA", "ESA", "JPL", "Saturn Ring Observer"]:
			assert_eq(t.find(name), -1, "general words, no mission names (§21b.2): %s" % t)


func _texts() -> Array[String]:
	var texts: Array[String] = [UniverseRegistry.landing_words(25), DragonRules.carried_back_words(_rings())]
	for w: String in (_rings().get("secret_words") as Dictionary).values():
		texts.append(w)
	for e: Dictionary in UniverseRegistry.sights(25).values():
		texts.append(str(e.words))
		texts.append(str(e.name))
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 25):
		texts.append(str(LoadingHints.HINTS[i].text))
	var r := CreatureWords.robot(25)
	for k in ["hello", "fact", "sample"]:
		texts.append(str(r.get(k, "")))
	for q: Dictionary in r.get("questions", []):
		texts.append(str(q.q))
		texts.append(str(q.hint))
	var c := CreatureWords.camp(25)
	for id: StringName in [c.get("explorer", &""), c.get("trader", &"")]:
		var a := CreatureWords.alien(id)
		for k in ["pretend", "science", "asks", "hello"]:
			texts.append(str(a.get(k, "")))
	var m := MissionRules.for_world(25)
	texts.append(str(m.get("fact", "")))
	return texts


func test_its_picture_card_and_loading_hints() -> void:
	var colors := UniverseRegistry.card_colors(25)
	assert_lt((colors.top as Color).get_luminance(), 0.2, "space's dark sky on its card")
	assert_ne(UniverseArt.layout(25), UniverseArt.layout(24), "its own scene")
	var ids: Array = UniverseArt.legend(25).values()
	assert_has(ids, BlockIds.RING_ICE, "ring ice on the card")
	assert_has(ids, BlockIds.RING_FROST, "frosty chunk tops")
	var own := 0
	var jets := false
	var float_hint := false
	var honest := false
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 25):
		if int(LoadingHints.HINTS[i].get("universe", 0)) == 25:
			own += 1
			var text := str(LoadingHints.HINTS[i].text)
			assert_lte(text.split(" ").size(), 10, text)
			jets = jets or text.contains("jets")
			float_hint = float_hint or text.contains("float")
			honest = honest or text.contains("real ring chunk")
	assert_gte(own, 4, "hints of its own")
	assert_true(jets, "a hint says the suit's jets bring a faller back")
	assert_true(float_hint, "a hint says jumps float")
	assert_true(honest, "a hint says a real chunk's pull is far weaker than the game's (the Moon's card's honesty)")


func test_its_helper_robot_and_the_aliens_camp() -> void:
	assert_true(CreatureWords.has_robot(25))
	var r := CreatureWords.robot(25)
	assert_string_contains(str(r.hello), str(r.name))
	assert_string_contains(str(r.sample), "sample")
	assert_eq((r.questions as Array).size(), 3)
	assert_true(AlienRules.has_camp(25), "the aliens' travelling camp")
	var c := CreatureWords.camp(25)
	assert_eq(CreatureWords.alien(c.explorer).role, &"explorer")
	assert_eq(CreatureWords.alien(c.trader).role, &"trader")
	assert_true(MiniRules.gives_mini(AlienRules.mini_kind(c.explorer)), "a friend comes along as a mini-buddy")
	assert_true(SpaceCreatures.wanted(25, ModeRules.SANDBOX))


## The Mission to Saturn's rings: the trip to Saturn (as Titan's), the capture burn into orbit round Saturn, dips through
## Saturn's thin upper air to slow (free, as spacecraft did at Mars and Venus), then keeping up with the ring chunks
## (about 20 km every second). Air and water for about 6 years; no air in the rings.
func test_a_mission_to_the_rings() -> void:
	var m := MissionRules.for_world(25)
	assert_false(m.is_empty())
	assert_eq(m.body, &"saturn")
	assert_eq(str(m.name), "Mission to Saturn's rings")
	assert_eq(str(m.trip), "about 6 years")
	assert_eq(int(m.days), 2200, "as Titan's: the same trip to Saturn")
	assert_false(bool(m.air), "no air in the rings: no heat shield or parachute")
	assert_almost_eq(MissionRules.need(m), 20.0, 0.001, "9.4 + 7.3 + 0.6 + 2.7")
	assert_lt(MissionRules.need(m), MissionRules.need(MissionRules.for_world(SpaceRules.MERCURY)),
		"Mercury's stays the hardest landing")
	assert_gt(MissionRules.need(m), MissionRules.need(MissionRules.for_world(SpaceRules.TITAN)),
		"harder than Titan's: no air to brake, and the chunks race round Saturn")
	assert_string_contains(str(m.distance), "billion km")
	assert_string_contains(str(m.fact), "20 km every second")
	assert_eq(FlightPlan.REAL_TRIP[SpaceRules.RINGS], "about 7 years", "real spacecraft took about 7 years")
