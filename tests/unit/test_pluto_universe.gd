extends GutTest
## Cosmos: Pluto is world 26 (world/universes/pluto.gd, spec §21b.2), a space world like the Moon, Mars, Europa, Io,
## Titan, Mercury, Venus's cloud city and Saturn's rings: its descriptor brings its terrain and secrets (SpaceShape PLUTO,
## SpaceSecretRules: the Balloon Lander), its real gravity (0.063 of Earth's: long, floaty jumps), peace, its own sky (a
## thin nitrogen air: black and starry by day with a blue haze along the horizon; the Sun a very bright star, 40 times as
## far as from Earth; Charon big in the west, never moving: the two always face each other; Nix and Hydra tiny points),
## soft chimes, calm music, no animals (lifeless), Tilly's local things, the landing words, real facts in its finds' words
## and at its sights (the Charon Lookout, the heart's plain, a floating hill, the ice mountains, the red-brown lands, the
## heart's bright side), a helper robot and the aliens' camp, a mission (a spacecraft flew past after 9 and a half years;
## landing needs a giant drag balloon in Pluto's thin air), a picture card and loading hints. It says kindly that Pluto is
## a dwarf planet and why (2006: a planet clears its path round the Sun; Pluto shares its path with many icy worlds). The
## cold is a fact, never a danger. The Star Map then says LAND for Pluto.


func after_each() -> void:
	UniverseRegistry.reset()
	LabRules.world_gravity = 1.0


func _pluto() -> Object:
	return UniverseRegistry.descriptor(SpaceRules.PLUTO)


func test_pluto_is_world_26_a_space_world_found_by_the_registry() -> void:
	assert_eq(SpaceRules.PLUTO, 26)
	assert_has(SpaceRules.WORLDS, SpaceRules.PLUTO, "the picker and the Star Map know it")
	assert_eq(SpaceRules.WORLDS.slice(0, 11), [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26] as Array[int])
	assert_true(UniverseRegistry.is_space(26))
	assert_true(UniverseRegistry.exists(26))
	assert_true(UniverseRegistry.space_available().has(26))
	assert_false(UniverseRegistry.available().has(26), "not on the ladder")
	var d := _pluto()
	assert_eq(d.get("name"), &"pluto")
	assert_eq(d.get("index"), 26)
	assert_eq(UniverseRegistry.display_name(26), "Pluto")
	assert_eq(UniverseRegistry.path_for(26), "res://world/universes/pluto.gd")
	assert_false(ShopCatalog.needs_plus(26), "free for everyone")
	assert_eq(UniverseRules.scale(26), 1, "never scaled")
	assert_eq(ModeRules.slot(ModeRules.SANDBOX, 26), "sandbox_26")


func test_the_star_map_says_land_on_pluto_and_the_space_book_marks_it() -> void:
	var s := StarMap.states(1, 1, UniverseRegistry.space_available(), 1)
	assert_eq(s[&"pluto"], StarMap.LAND, "Pluto can be landed on now")
	assert_eq(StarMap.action_words_for(&"pluto", StarMap.LAND), "LAND")
	assert_eq(StarMap.states(26, 2, UniverseRegistry.space_available(), 2)[&"pluto"], StarMap.HERE)
	assert_eq(StarMap.body_for_world(26), &"pluto")
	var no_route: Array[int] = []
	assert_eq(StarMap.states(1, 1, UniverseRegistry.space_available(), 1, no_route)[&"pluto"], StarMap.MISSION,
		"a mission first (spec §21d.5)")
	var w := WonderData.new()
	assert_true(w.land_on_world(26), "the first landing on Pluto")
	assert_eq(w.bodies, {"pluto": WonderData.SEEN | WonderData.LANDED})


func test_its_terrain_generator_and_secrets() -> void:
	var shape := UniverseRegistry.shape_for(26, 77)
	assert_true(shape is SpaceShape)
	assert_eq((shape as SpaceShape).planet, SpaceShape.PLUTO)
	var gen := UniverseRegistry.generator_for(26, 77)
	assert_true(gen is SpaceGenerator)
	assert_eq((gen as SpaceGenerator).space_shape().planet, SpaceShape.PLUTO)
	assert_eq((gen as SpaceGenerator).world_seed, 77)
	var rules: Variant = _pluto().call(&"secret_rules", 77, shape)
	assert_true(rules is SpaceSecretRules)
	assert_eq((rules as SpaceSecretRules).landmark().get("name"), "Balloon Lander")


## Pluto's real gravity: 0.62 m/s² ÷ 9.81 = 0.063: a jump floats ~27 blocks up for ~12 s; the step onto a one-block ledge
## stays gentle (LabRules.step_velocity: as high as on the Moon).
func test_real_gravity_long_floaty_jumps_and_the_landing_words() -> void:
	assert_almost_eq(UniverseRegistry.gravity(26), 0.063, 0.0001, "Pluto's real gravity, about 6 % of Earth's")
	assert_true(UniverseRegistry.peaceful(26), "no monsters come by themselves")
	var words := UniverseRegistry.landing_words(26)
	assert_string_contains(words, "Pluto")
	assert_string_contains(words, "heart")
	assert_string_contains(words, "Charon")
	LabRules.world_gravity = UniverseRegistry.gravity(26)
	var jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	var air := LabRules.air_time(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	assert_between(jump, 24.0, 30.0, "a jump floats very high (%.1f blocks)" % jump)
	assert_between(air, 10.0, 14.0, "long and floaty (%.1f s)" % air)
	var step := LabRules.step_velocity(Player.AUTO_STEP_VELOCITY, LabRules.gravity_factor(LabRules.Mode.NORMAL))
	var hop := step * step / (2.0 * Player.GRAVITY * 0.063)
	assert_between(hop, 1.05, 3.6, "a step onto a ledge clears it gently (%.2f blocks)" % hop)


## A thin nitrogen air: space's black starry sky overhead by day with a blue haze along the horizon (never the photo
## sky); the Sun about 40 times smaller than at home; Charon big and grey with its red cap, low in the west (the lookout
## looks there), never home's moon disc; Nix and Hydra tiny points.
func test_a_black_sky_a_blue_haze_a_star_like_sun_and_charon() -> void:
	var space := UniverseRegistry.space_sky(26)
	assert_between(space, 0.4, 0.75, "mostly space's black, thin air (%.2f)" % space)
	assert_false(UniverseRegistry.photo_sky(26), "never Earth's blue photo sky")
	var sky := UniverseRegistry.sky(26)
	var haze: Color = sky.sky_horizon
	assert_gt(haze.b, haze.r + 0.3, "a blue haze along the horizon (%s)" % haze)
	assert_lt((sky.sky_top as Color).get_luminance(), 0.08, "black overhead")
	assert_almost_eq(UniverseRegistry.sun_size(26), 0.025, 0.0001, "the Sun 1/40 as wide: a very bright star")
	assert_true(UniverseRegistry.sun_rises_west(26), "Pluto spins backwards, like Venus: the Sun rises in the west")
	var charon := UniverseRegistry.sky_planet(26)
	assert_true(charon.get("own_moons") == true, "Pluto's moons: home's big moon disc never shows")
	assert_gte(float(charon.size), 50.0, "Charon is big in Pluto's sky")
	var dir: Vector3 = charon.dir
	assert_lt(dir.normalized().x, -0.8, "in the west, where the lookout looks")
	assert_between(dir.normalized().y, 0.15, 0.5, "low over the horizon")
	var grey: Color = charon.color
	assert_lt(absf(grey.r - grey.b), 0.1, "Charon's grey (%s)" % grey)
	var cap: Color = charon.cap
	assert_gt(cap.r, cap.b + 0.2, "its red cap")
	assert_eq((charon.get("moons", []) as Array).size(), 2, "Nix and Hydra")
	for m: Dictionary in charon.moons:
		assert_lte(float(m.size), 2.5, "tiny points of light")


func test_its_sounds_music_and_no_animals() -> void:
	assert_eq(UniverseRegistry.ambience(26), {"day": &"chimes", "night": &"chimes"}, "soft icy chimes: air too thin for wind")
	assert_eq(UniverseRegistry.classical(26), [&"winter_largo", &"moonlight"] as Array[StringName])
	for id in UniverseRegistry.classical(26):
		assert_false(MusicPieces.PIECES[id].moods.has(MusicPieces.BOSS), "a piece a day or a night plays, not a boss's")
	assert_eq(UniverseRegistry.music(26), {}, "no loops of its own")
	assert_true(UniverseRegistry.lifeless(26), "no life we know of")
	assert_eq(UniverseRegistry.animals(26), [] as Array[StringName], "no animals")


func test_tillys_pluto_things() -> void:
	var stock := UniverseRegistry.trader_stock(26)
	for id in [BlockIds.NITROGEN_ICE, BlockIds.CELL_EDGE, BlockIds.WATER_ICE, BlockIds.PLUTO_FROST, BlockIds.THOLIN_DUST,
			BlockIds.RED_ICE, BlockIds.METHANE_SNOW, BlockIds.FROST_CRYSTAL, BlockIds.DRAG_BALLOON, BlockIds.CHARON_GLOBE,
			BlockIds.HEART_BEACON, BlockIds.FROST_BRICK, BlockIds.LANDING_PAD]:
		assert_true(stock.has(id), "%s to build with" % BlockIds.display_name(id))
	assert_false(stock.has(BlockIds.STAR_GOLD), "treasure is found, never sold")
	assert_false(stock.has(BlockIds.FAKE_WATER_ICE))
	assert_eq(ShopRules.price(BlockIds.NITROGEN_ICE, 26), stock[BlockIds.NITROGEN_ICE], "never scaled")


func test_every_find_says_a_real_pluto_fact() -> void:
	var words: Dictionary = _pluto().get("secret_words")
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.ISLAND, SecretRules.GEODE]:
		assert_true(words.has(k), str(k))
		var text: String = words[k]
		assert_true(text.begins_with("You found"), text)
		assert_gt(text.find("! "), 0, "a find, then a fact: %s" % text)
		assert_true(text.ends_with("."), text)
		assert_lt(text.length(), 110, "short enough for the banner: %s" % text)
	assert_string_contains(words[SecretRules.ISLAND], "Balloon Lander")
	assert_string_contains(words[SecretRules.ISLAND], "balloon")
	assert_string_contains(words[SecretRules.TREASURE], "11-year-old")
	assert_string_contains(words[SecretRules.TREASURE], "1930")
	assert_string_contains(words[SecretRules.ROOM], "hard as rock")
	assert_string_contains(words[SecretRules.TEMPLE], "five moons")
	assert_string_contains(words[SecretRules.GEODE], "230 °C")


func test_its_sights_teach_real_facts() -> void:
	var sights := UniverseRegistry.sights(26)
	assert_eq(sights.keys(), [&"lookout", &"heart", &"hills", &"mountains", &"dark", &"bright"])
	for id: StringName in sights:
		var e: Dictionary = sights[id]
		assert_ne(str(e.get("name", "")), "", "a name for the map: %s" % id)
		assert_true(str(e.words).begins_with("You "), e.words)
		assert_lt(str(e.words).length(), 120, e.words)
	assert_string_contains(sights[&"lookout"].words, "face each other")
	assert_string_contains(sights[&"heart"].words, "nitrogen")
	assert_string_contains(sights[&"heart"].words, "cells")
	assert_string_contains(sights[&"hills"].words, "iceberg")
	assert_string_contains(sights[&"mountains"].words, "Everest")
	assert_string_contains(sights[&"dark"].words, "tholins")
	assert_string_contains(sights[&"bright"].words, "frost")
	var map_ids: Array = []
	for s: Dictionary in SpaceShape.new(12345, SpaceShape.PLUTO).sights():
		map_ids.append(s.id)
	assert_eq(map_ids, sights.keys(), "MY MAP shows all six from the landing")


## Kindly, and why: Pluto is a dwarf planet since 2006, because it shares its path round the Sun with many icy worlds.
func test_it_says_kindly_that_pluto_is_a_dwarf_planet_and_why() -> void:
	var said_2006 := false
	var said_path := false
	for t in _texts():
		var lower := t.to_lower()
		if lower.contains("dwarf planet") and lower.contains("2006"):
			said_2006 = true
		if lower.contains("path") and (lower.contains("icy worlds") or lower.contains("icy objects")):
			said_path = true
		for unkind in ["not a real planet", "only a dwarf", "just a dwarf", "demoted", "kicked out", "not a planet anymore"]:
			assert_false(lower.contains(unkind), "kind words: %s" % t)
	assert_true(said_2006, "it says Pluto has been a dwarf planet since 2006")
	assert_true(said_path, "and why: it shares its path round the Sun with many icy worlds")


## The cold is a fact, never a danger: no word says anything hurts, freezes a child or is scary.
func test_the_cold_is_a_fact_never_a_danger() -> void:
	for t in _texts():
		for w in ["hurt", "burn", "danger", "dangerous", "scary", "careful", "die", "crash", "deadly", "freeze you",
				"too cold", "frozen solid in", "frostbite"]:
			var whole := RegEx.create_from_string("(?<![a-z])" + w + "(?![a-z])")
			assert_null(whole.search(t.to_lower()), "a friendly world (spec §3c): %s" % t)


func test_no_mission_names_or_brands_in_its_words() -> void:
	for t in _texts():
		for name in ["New Horizons", "NASA", "ESA", "JPL", "Hubble", "Voyager", "Pioneer", "NIAC", "Hop, Skip",
				"Global Aerospace", "Sputnik", "Cthulhu", "Mordor"]:
			assert_eq(t.find(name), -1, "general words, no mission names (§21b.2): %s" % t)


func _texts() -> Array[String]:
	var texts: Array[String] = [UniverseRegistry.landing_words(26)]
	for w: String in (_pluto().get("secret_words") as Dictionary).values():
		texts.append(w)
	for e: Dictionary in UniverseRegistry.sights(26).values():
		texts.append(str(e.words))
		texts.append(str(e.name))
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 26):
		texts.append(str(LoadingHints.HINTS[i].text))
	var r := CreatureWords.robot(26)
	for k in ["hello", "fact", "sample"]:
		texts.append(str(r.get(k, "")))
	for q: Dictionary in r.get("questions", []):
		texts.append(str(q.q))
		texts.append(str(q.hint))
		for c: Variant in q.choices:
			texts.append(str(c))
	var c := CreatureWords.camp(26)
	for id: StringName in [c.get("explorer", &""), c.get("trader", &"")]:
		var a := CreatureWords.alien(id)
		for k in ["pretend", "science", "asks", "hello"]:
			texts.append(str(a.get(k, "")))
	var m := MissionRules.for_world(26)
	texts.append(str(m.get("fact", "")))
	for leg: Array in m.get("legs", []):
		texts.append(str(leg[0]))
	return texts


func test_its_picture_card_and_loading_hints() -> void:
	var colors := UniverseRegistry.card_colors(26)
	assert_lt((colors.top as Color).get_luminance(), 0.2, "a dark sky on its card")
	assert_ne(UniverseArt.layout(26), UniverseArt.layout(25), "its own scene")
	var ids: Array = UniverseArt.legend(26).values()
	assert_has(ids, BlockIds.NITROGEN_ICE, "the heart's nitrogen ice on the card")
	assert_has(ids, BlockIds.DRAG_BALLOON, "the Balloon Lander's balloon")
	var own := 0
	var dwarf := false
	var jump := false
	var charon := false
	var dim := false
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 26):
		if int(LoadingHints.HINTS[i].get("universe", 0)) == 26:
			own += 1
			var text := str(LoadingHints.HINTS[i].text)
			assert_lte(text.split(" ").size(), 10, text)
			dwarf = dwarf or text.contains("dwarf planet")
			jump = jump or text.contains("jump")
			charon = charon or text.contains("Charon")
			dim = dim or text.contains("dim")
	assert_gte(own, 6, "hints of its own")
	assert_true(dwarf, "a hint says Pluto is a dwarf planet")
	assert_true(jump, "a hint says jumps go high")
	assert_true(charon, "a hint says Charon never moves")
	assert_true(dim, "a hint says real noon on Pluto is dim (the game's light stays friendly)")


func test_its_helper_robot_and_the_aliens_camp() -> void:
	assert_true(CreatureWords.has_robot(26))
	var r := CreatureWords.robot(26)
	assert_string_contains(str(r.hello), str(r.name))
	assert_string_contains(str(r.sample), "sample")
	assert_eq((r.questions as Array).size(), 3)
	assert_true(AlienRules.has_camp(26), "the aliens' travelling camp")
	var c := CreatureWords.camp(26)
	assert_eq(CreatureWords.alien(c.explorer).role, &"explorer")
	assert_eq(CreatureWords.alien(c.trader).role, &"trader")
	assert_true(MiniRules.gives_mini(AlienRules.mini_kind(c.explorer)), "a friend comes along as a mini-buddy")
	assert_true(SpaceCreatures.wanted(26, ModeRules.SANDBOX))


## The Mission to Pluto: a spacecraft flew past Pluto in 2015 after 9 and a half years (too fast to stop); a landing from
## that trip needs to brake about 14 km/s, far beyond any rocket a child builds. The game's way, a real study's: slowing in
## Pluto's thin, tall air under a giant drag balloon (the heat shield and parachute on the rocket), then a small burn down.
## Air and water for 9 and a half years.
func test_a_mission_to_pluto() -> void:
	var m := MissionRules.for_world(26)
	assert_false(m.is_empty())
	assert_eq(m.body, &"pluto")
	assert_eq(str(m.name), "Mission to Pluto")
	assert_eq(str(m.trip), "about 9 and a half years")
	assert_eq(int(m.days), 3470, "9.5 years")
	assert_true(bool(m.air), "its thin air slows the balloon: a heat shield and a parachute on the rocket")
	assert_almost_eq(MissionRules.need(m), 18.6, 0.001, "9.4 + 8.9 + 0.3")
	assert_lt(MissionRules.need(m), MissionRules.need(MissionRules.for_world(SpaceRules.MERCURY)),
		"Mercury's stays the hardest landing")
	assert_string_contains(str(m.distance), "billion km")
	assert_string_contains(str(m.fact), "flew past")
	assert_string_contains(str(m.fact), "balloon")
	assert_string_contains(str((m.legs as Array)[1][0]), "Jupiter", "a swing past Jupiter, as the real spacecraft did")
	assert_string_contains(str((m.legs as Array)[2][0]), "balloon")
	assert_eq(FlightPlan.REAL_TRIP[SpaceRules.PLUTO], "about 9 and a half years", "the flight says the board's trip")


## The mission is reachable: a rocket of 239 parts (about 8,200 gold, like the rings' and Mercury's) passes every line of
## the check for the Mission to Pluto (found by a search over the parts' numbers; the notes have it). Without the balloon
## (braking the ~14 km/s by engines: about 32 km/s in all) no rocket of up to 7 stages the pad holds passes.
func test_a_rocket_a_child_can_build_reaches_pluto() -> void:
	var m := MissionRules.for_world(26)
	var cells := {}
	var y := 0
	var stages := [[BlockIds.ROCKET_ENGINE, 48, 5], [BlockIds.SPACE_ENGINE, 34, 65], [BlockIds.SPACE_ENGINE, 12, 21],
		[BlockIds.SPACE_ENGINE, 5, 8], [BlockIds.SPACE_ENGINE, 2, 3], [BlockIds.SPACE_ENGINE, 1, 2]]
	for i in stages.size():
		var st: Array = stages[i]
		y = _layers(cells, y, _many(int(st[0]), int(st[1])))
		var rest := _many(BlockIds.FUEL_TANK, int(st[2]))
		if i == 0:
			rest.append_array(_many(BlockIds.ROCKET_FINS, 3))
		y = _layers(cells, y, rest)
		if i < stages.size() - 1:
			y = _layers(cells, y, [BlockIds.STAGE_SEPARATOR])
	var payload := _many(BlockIds.SERVICE_MODULE, 18)
	payload.append_array([BlockIds.HEAT_SHIELD, BlockIds.PARACHUTE_PACK, BlockIds.SOLAR_ARRAY])
	payload.append_array(_many(BlockIds.LANDING_LEGS, 3))
	y = _layers(cells, y, payload)
	_layers(cells, y, [BlockIds.CREW_CAPSULE])
	var r := RocketCheck.check(cells, m)
	var failing: Array = (r.lines as Array).filter(func(l: Dictionary) -> bool: return not l.ok).map(
		func(l: Dictionary) -> String: return str(l.text))
	assert_true(r.ok, "every line passes: %s" % [failing])
	assert_gte(float(r.dv), MissionRules.need(m), "enough speed (%.2f km/s)" % float(r.dv))
	assert_eq((r.cells as Dictionary).size(), 239, "a rocket of 239 parts")


## Fills layers of the pad's 9 × 9 square with `ids`, row by row from the corner, from layer y; returns the next layer.
func _layers(cells: Dictionary, y: int, ids: Array) -> int:
	var i := 0
	while i < ids.size():
		for k in RocketCheck.PAD * RocketCheck.PAD:
			if i >= ids.size():
				break
			cells[Vector3i(k % RocketCheck.PAD, y, k / RocketCheck.PAD)] = int(ids[i])
			i += 1
		y += 1
	return y


func _many(id: int, n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append(id)
	return out
