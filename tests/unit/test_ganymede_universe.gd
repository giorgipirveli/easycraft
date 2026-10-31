extends GutTest
## Cosmos: Ganymede is world 28 (world/universes/ganymede.gd, spec §21b.2), a space world like the Moon, Mars, Europa, Io,
## Titan, Mercury, Venus's cloud city, Saturn's rings, Pluto and Triton: its descriptor brings its terrain and secrets
## (SpaceShape GANYMEDE, SpaceSecretRules: the Solar Wing Lander), its real gravity (0.146 of Earth's: long, floaty jumps),
## peace, space's black starry sky (almost no air) with Jupiter big and banded in the east, never moving (Ganymede always
## shows it the same face), Io and Europa as bright dots, the Sun small (5 times as far as from Earth), soft chimes, calm
## music, no animals (lifeless), Tilly's local things, the landing words, real facts in its finds' words and at its sights
## (the Jupiter Lookout, the grooved terrain, the dark terrain, a bright ray crater, the polar frost, the Aurora Watch, the
## ocean drill), a helper robot and the aliens' camp, a mission (a real spacecraft on its way swings past the Moon, Venus
## and Earth to save fuel: Jupiter in 2031, Ganymede's orbit in 2034), a picture card and loading hints. It says that
## Ganymede is the biggest moon of all (bigger than Mercury), the only one with its own magnetic field (so it has
## auroras), with a salty ocean deep under its ice. The cold is a fact, never a danger. The Star Map then says LAND (or
## MISSION) for Ganymede.


func after_each() -> void:
	UniverseRegistry.reset()
	LabRules.world_gravity = 1.0


func _ganymede() -> Object:
	return UniverseRegistry.descriptor(SpaceRules.GANYMEDE)


func test_ganymede_is_world_28_a_space_world_found_by_the_registry() -> void:
	assert_eq(SpaceRules.GANYMEDE, 28)
	assert_has(SpaceRules.WORLDS, SpaceRules.GANYMEDE, "the picker and the Star Map know it")
	assert_eq(SpaceRules.WORLDS.slice(0, 13), [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28] as Array[int])
	assert_true(UniverseRegistry.is_space(28))
	assert_true(UniverseRegistry.exists(28))
	assert_true(UniverseRegistry.space_available().has(28))
	assert_false(UniverseRegistry.available().has(28), "not on the ladder")
	var d := _ganymede()
	assert_eq(d.get("name"), &"ganymede")
	assert_eq(d.get("index"), 28)
	assert_eq(UniverseRegistry.display_name(28), "Ganymede")
	assert_eq(UniverseRegistry.path_for(28), "res://world/universes/ganymede.gd")
	assert_false(ShopCatalog.needs_plus(28), "free for everyone")
	assert_eq(UniverseRules.scale(28), 1, "never scaled")
	assert_eq(ModeRules.slot(ModeRules.SANDBOX, 28), "sandbox_28")


func test_the_star_map_says_land_on_ganymede_and_the_space_book_marks_it() -> void:
	var s := StarMap.states(1, 1, UniverseRegistry.space_available(), 1)
	assert_eq(s[&"ganymede"], StarMap.LAND, "Ganymede can be landed on now")
	assert_eq(StarMap.action_words_for(&"ganymede", StarMap.LAND), "LAND")
	assert_eq(s[&"jupiter"], StarMap.NO_GROUND, "Jupiter itself has no ground: land on its moons")
	assert_eq(StarMap.states(28, 2, UniverseRegistry.space_available(), 2)[&"ganymede"], StarMap.HERE)
	assert_eq(StarMap.body_for_world(28), &"ganymede")
	var no_route: Array[int] = []
	assert_eq(StarMap.states(1, 1, UniverseRegistry.space_available(), 1, no_route)[&"ganymede"], StarMap.MISSION,
		"a mission first (spec §21d.5)")
	var w := WonderData.new()
	assert_true(w.land_on_world(28), "the first landing on Ganymede")
	assert_eq(w.bodies, {"ganymede": WonderData.SEEN | WonderData.LANDED})


func test_its_terrain_generator_and_secrets() -> void:
	var shape := UniverseRegistry.shape_for(28, 77)
	assert_true(shape is SpaceShape)
	assert_eq((shape as SpaceShape).planet, SpaceShape.GANYMEDE)
	var gen := UniverseRegistry.generator_for(28, 77)
	assert_true(gen is SpaceGenerator)
	assert_eq((gen as SpaceGenerator).space_shape().planet, SpaceShape.GANYMEDE)
	assert_eq((gen as SpaceGenerator).world_seed, 77)
	var rules: Variant = _ganymede().call(&"secret_rules", 77, shape)
	assert_true(rules is SpaceSecretRules)
	assert_eq((rules as SpaceSecretRules).landmark().get("name"), "Solar Wing Lander")


## Ganymede's real gravity: 1.428 m/s² ÷ 9.81 = 0.146: a jump floats ~11 blocks up for ~5 s; the step onto a one-block
## ledge stays gentle (LabRules.step_velocity: as high as on the Moon).
func test_real_gravity_floaty_jumps_and_the_landing_words() -> void:
	assert_almost_eq(UniverseRegistry.gravity(28), 0.146, 0.0001, "Ganymede's real gravity, about 15 % of Earth's")
	assert_true(UniverseRegistry.peaceful(28), "no monsters come by themselves")
	var words := UniverseRegistry.landing_words(28)
	assert_string_contains(words, "Ganymede")
	assert_string_contains(words, "Jupiter")
	LabRules.world_gravity = UniverseRegistry.gravity(28)
	var jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	var air := LabRules.air_time(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	assert_between(jump, 9.5, 13.5, "a jump floats high (%.1f blocks)" % jump)
	assert_between(air, 4.0, 7.0, "long and floaty (%.1f s)" % air)
	var step := LabRules.step_velocity(Player.AUTO_STEP_VELOCITY, LabRules.gravity_factor(LabRules.Mode.NORMAL))
	var hop := step * step / (2.0 * Player.GRAVITY * 0.146)
	assert_between(hop, 1.05, 3.6, "a step onto a ledge clears it gently (%.2f blocks)" % hop)


## Almost no air: space's black starry sky all day (never the photo sky); the Sun about 5 times smaller than at home;
## Jupiter big and banded with its Great Red Spot in the east, up in the sky, never home's moon disc; Io and Europa as
## bright dots.
func test_a_black_sky_a_small_sun_and_jupiter_big_and_banded() -> void:
	assert_eq(UniverseRegistry.space_sky(28), 1.0, "space's black: almost no air")
	assert_false(UniverseRegistry.photo_sky(28), "never Earth's blue photo sky")
	var sky := UniverseRegistry.sky(28)
	assert_lt((sky.sky_top as Color).get_luminance(), 0.06, "black overhead")
	assert_almost_eq(UniverseRegistry.sun_size(28), 0.19, 0.005, "the Sun about 1/5.2 as wide")
	assert_false(UniverseRegistry.sun_rises_west(28), "the Sun rises in the east")
	var jupiter := UniverseRegistry.sky_planet(28)
	assert_true(jupiter.get("own_moons") == true, "Jupiter's moons: home's big moon disc never shows")
	assert_gte(float(jupiter.size), 70.0, "Jupiter is big in Ganymede's sky")
	assert_lt(float(jupiter.size), 104.0, "smaller than from Europa, which is nearer to it")
	assert_true(jupiter.get("bands") == true, "its cloud bands")
	assert_true(jupiter.get("spot") == true, "its Great Red Spot")
	assert_false(jupiter.has("spot_color"), "red, as from Europa and Io")
	var dir: Vector3 = (jupiter.dir as Vector3).normalized()
	assert_gt(dir.x, 0.6, "in the east: where the lookout looks")
	assert_between(dir.y, 0.25, 0.6, "up in the sky, over the day views")
	var moons: Array = jupiter.get("moons", [])
	assert_eq(moons.size(), 2, "Io and Europa")
	for m: Dictionary in moons:
		assert_lte(float(m.size), 7.0, "bright dots")
	assert_gt((moons[0].color as Color).r, (moons[0].color as Color).b + 0.3, "Io sulphur-yellow")
	assert_gt((moons[1].color as Color).get_luminance(), 0.75, "Europa icy white")


func test_its_sounds_music_and_no_animals() -> void:
	assert_eq(UniverseRegistry.ambience(28), {"day": &"chimes", "night": &"chimes"}, "soft icy chimes: no air for wind")
	assert_eq(UniverseRegistry.classical(28), [&"nachtmusik", &"air"] as Array[StringName])
	for id in UniverseRegistry.classical(28):
		assert_false(MusicPieces.PIECES[id].moods.has(MusicPieces.BOSS), "a piece a day or a night plays, not a boss's")
	assert_eq(UniverseRegistry.music(28), {}, "no loops of its own")
	assert_true(UniverseRegistry.lifeless(28), "no life we know of")
	assert_eq(UniverseRegistry.animals(28), [] as Array[StringName], "no animals")


func test_tillys_ganymede_things() -> void:
	var stock := UniverseRegistry.trader_stock(28)
	for id in [BlockIds.GROOVED_ICE, BlockIds.TROUGH_ICE, BlockIds.DARK_ICE, BlockIds.OLD_ICE, BlockIds.RAY_ICE,
			BlockIds.POLAR_FROST, BlockIds.WATER_ICE, BlockIds.AURORA_CRYSTAL, BlockIds.JUPITER_GLOBE, BlockIds.AURORA_LAMP,
			BlockIds.MAGNETOMETER, BlockIds.GROOVE_BRICK, BlockIds.TELESCOPE, BlockIds.LANDING_PAD]:
		assert_true(stock.has(id), "%s to build with" % BlockIds.display_name(id))
	assert_false(stock.has(BlockIds.STAR_GOLD), "treasure is found, never sold")
	assert_false(stock.has(BlockIds.FAKE_GROOVED_ICE))
	assert_eq(ShopRules.price(BlockIds.GROOVED_ICE, 28), stock[BlockIds.GROOVED_ICE], "never scaled")


func test_every_find_says_a_real_ganymede_fact() -> void:
	var words: Dictionary = _ganymede().get("secret_words")
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.ISLAND, SecretRules.GEODE]:
		assert_true(words.has(k), str(k))
		var text: String = words[k]
		assert_true(text.begins_with("You found"), text)
		assert_gt(text.find("! "), 0, "a find, then a fact: %s" % text)
		assert_true(text.ends_with("."), text)
		assert_lt(text.length(), 110, "short enough for the banner: %s" % text)
	assert_string_contains(words[SecretRules.ISLAND], "Solar Wing Lander")
	assert_string_contains(words[SecretRules.ISLAND], "25 times")
	assert_string_contains(words[SecretRules.TREASURE], "1610")
	assert_string_contains(words[SecretRules.ROOM], "Mercury")
	assert_string_contains(words[SecretRules.TEMPLE], "Io")
	assert_string_contains(words[SecretRules.GEODE], "°C")


func test_its_sights_teach_real_facts() -> void:
	var sights := UniverseRegistry.sights(28)
	assert_eq(sights.keys(), [&"lookout", &"grooves", &"dark", &"crater", &"frost", &"aurora", &"ocean"])
	for id: StringName in sights:
		var e: Dictionary = sights[id]
		assert_ne(str(e.get("name", "")), "", "a name for the map: %s" % id)
		assert_true(str(e.words).begins_with("You "), e.words)
		assert_lt(str(e.words).length(), 120, e.words)
	assert_string_contains(sights[&"lookout"].words, "same face")
	assert_string_contains(sights[&"grooves"].words, "ridges")
	assert_string_contains(sights[&"dark"].words, "billion years")
	assert_string_contains(sights[&"crater"].words, "fresh ice")
	assert_string_contains(sights[&"frost"].words, "magnetic field")
	assert_string_contains(sights[&"aurora"].words, "aurora")
	assert_string_contains(sights[&"ocean"].words, "ocean")
	assert_string_contains(sights[&"ocean"].words, "150 km")
	var map_ids: Array = []
	for s: Dictionary in SpaceShape.new(12345, SpaceShape.GANYMEDE).sights():
		map_ids.append(s.id)
	assert_eq(map_ids, sights.keys(), "MY MAP shows all seven from the landing")


## The biggest moon of all (bigger than Mercury), the only moon with its own magnetic field (so it has auroras), a salty
## ocean deep under its ice; said by the robot, the sights and the hints.
func test_it_says_the_biggest_moon_its_magnetic_field_and_its_ocean() -> void:
	var biggest := false
	var mercury := false
	var magnet := false
	var aurora := false
	var ocean := false
	for t in _texts():
		var lower := t.to_lower()
		biggest = biggest or lower.contains("biggest moon")
		mercury = mercury or (lower.contains("bigger") and lower.contains("mercury"))
		magnet = magnet or (lower.contains("only moon") and lower.contains("magnetic field"))
		aurora = aurora or lower.contains("aurora")
		ocean = ocean or (lower.contains("ocean") and lower.contains("salty"))
	assert_true(biggest, "the biggest moon in the solar system")
	assert_true(mercury, "bigger than the planet Mercury")
	assert_true(magnet, "the only moon with its own magnetic field")
	assert_true(aurora, "its auroras")
	assert_true(ocean, "a salty ocean deep under its ice")


## The cold is a fact, never a danger: no word says anything hurts, freezes a child or is scary.
func test_the_cold_is_never_a_danger() -> void:
	for t in _texts():
		for w in ["hurt", "burn", "danger", "dangerous", "scary", "careful", "die", "crash into", "deadly", "freeze you",
				"too cold", "frostbite", "explode", "blast", "radiation"]:
			var whole := RegEx.create_from_string("(?<![a-z])" + w + "(?![a-z])")
			assert_null(whole.search(t.to_lower()), "a friendly world (spec §3c): %s" % t)


## General words, no mission or map names (spec §21b.2): a spacecraft, a space telescope, scientists. The astronomer
## Galileo Galilei, who found it in 1610, is a person (always with his whole name).
func test_no_mission_names_or_brands_in_its_words() -> void:
	for t in _texts():
		for name in ["Voyager", "NASA", "ESA", "JPL", "Hubble", "Juno", "JUICE", "Juice", "Pioneer", "Clipper", "Keck",
				"Regio", "Sulcus", "Uruk", "Osiris", "Tros", "Memphis", "Nicholson", "Marius", "Laplace"]:
			assert_eq(t.find(name), -1, "general words, no mission or map names (§21b.2): %s" % t)
		var galileo := RegEx.create_from_string("Galileo(?! Galilei)")
		assert_null(galileo.search(t), "Galileo only as the astronomer's whole name: %s" % t)


func _texts() -> Array[String]:
	var texts: Array[String] = [UniverseRegistry.landing_words(28)]
	for w: String in (_ganymede().get("secret_words") as Dictionary).values():
		texts.append(w)
	for e: Dictionary in UniverseRegistry.sights(28).values():
		texts.append(str(e.words))
		texts.append(str(e.name))
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 28):
		texts.append(str(LoadingHints.HINTS[i].text))
	var r := CreatureWords.robot(28)
	for k in ["hello", "fact", "sample"]:
		texts.append(str(r.get(k, "")))
	for q: Dictionary in r.get("questions", []):
		texts.append(str(q.q))
		texts.append(str(q.hint))
		for c: Variant in q.choices:
			texts.append(str(c))
	var c := CreatureWords.camp(28)
	for id: StringName in [c.get("explorer", &""), c.get("trader", &"")]:
		var a := CreatureWords.alien(id)
		for k in ["pretend", "science", "asks", "hello"]:
			texts.append(str(a.get(k, "")))
	var m := MissionRules.for_world(28)
	texts.append(str(m.get("fact", "")))
	for leg: Array in m.get("legs", []):
		texts.append(str(leg[0]))
	return texts


func test_its_picture_card_and_loading_hints() -> void:
	var colors := UniverseRegistry.card_colors(28)
	assert_lt((colors.top as Color).get_luminance(), 0.2, "a dark sky on its card")
	assert_ne(UniverseArt.layout(28), UniverseArt.layout(27), "its own scene")
	var ids: Array = UniverseArt.legend(28).values()
	assert_has(ids, BlockIds.GROOVED_ICE, "the bright grooved ice on the card")
	assert_has(ids, BlockIds.DARK_ICE, "the old dark terrain")
	assert_has(ids, BlockIds.SOLAR_PANEL, "the Solar Wing Lander's wings")
	var own := 0
	var magnet := false
	var jump := false
	var jupiter := false
	var aurora := false
	var minutes := false
	var moons := false
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 28):
		if int(LoadingHints.HINTS[i].get("universe", 0)) == 28:
			own += 1
			var text := str(LoadingHints.HINTS[i].text)
			assert_lte(text.split(" ").size(), 10, text)
			magnet = magnet or text.contains("magnetic field")
			jump = jump or text.contains("jump")
			jupiter = jupiter or text.contains("never moves")
			aurora = aurora or text.contains("aurora")
			minutes = minutes or text.contains("43 minutes")
			moons = moons or (text.contains("Io") and text.contains("Europa"))
	assert_gte(own, 8, "hints of its own")
	assert_true(magnet, "a hint says it has its own magnetic field")
	assert_true(jump, "a hint says jumps go high")
	assert_true(jupiter, "a hint says Jupiter never moves")
	assert_true(aurora, "a hint says to look for the auroras")
	assert_true(minutes, "a hint says sunlight takes about 43 minutes")
	assert_true(moons, "a hint says Io and Europa swing past Jupiter")


func test_its_helper_robot_and_the_aliens_camp() -> void:
	assert_true(CreatureWords.has_robot(28))
	var r := CreatureWords.robot(28)
	assert_eq(str(r.name), "Compass")
	assert_string_contains(str(r.hello), str(r.name))
	assert_string_contains(str(r.sample), "sample")
	assert_eq((r.questions as Array).size(), 3)
	assert_true(AlienRules.has_camp(28), "the aliens' travelling camp")
	var c := CreatureWords.camp(28)
	assert_eq(CreatureWords.alien(c.explorer).role, &"explorer")
	assert_eq(CreatureWords.alien(c.trader).role, &"trader")
	assert_true(MiniRules.gives_mini(AlienRules.mini_kind(c.explorer)), "a friend comes along as a mini-buddy")
	assert_true(SpaceCreatures.wanted(28, ModeRules.SANDBOX))


## The Mission to Ganymede, the way a real spacecraft goes now: launched in 2023, it swings past the Moon and Earth,
## Venus and Earth again to save fuel (the launch gave it only ~2.5 km/s past Earth's pull: 3.5 km/s from a low orbit,
## our arithmetic), reaches Jupiter in 2031 (~0.95 km/s to slow into orbit round it), flies past its moons again and again
## to slow down and circles Ganymede from December 2034 (its whole budget ~2.7 km/s); then down onto the ice on the
## engines (~1.9 from a 500 km orbit). Almost 12 years: air and water for that long. No air: no heat shield, no parachute.
func test_a_mission_to_ganymede() -> void:
	var m := MissionRules.for_world(28)
	assert_false(m.is_empty())
	assert_eq(m.body, &"ganymede")
	assert_eq(str(m.name), "Mission to Ganymede")
	assert_eq(str(m.trip), "almost 12 years")
	assert_eq(int(m.days), 4260, "11 years and 8 months")
	assert_false(bool(m.air), "no air")
	assert_false(bool(m.get("skim", false)))
	assert_almost_eq(MissionRules.need(m), 17.5, 0.001, "9.4 + 3.5 + 2.1 + 2.5")
	assert_lt(MissionRules.need(m), MissionRules.need(MissionRules.for_world(SpaceRules.EUROPA)),
		"less speed than the straight trip to Europa: the swings save fuel ...")
	assert_gt(int(m.days), int(MissionRules.for_world(SpaceRules.EUROPA).days), "... but take years longer")
	assert_string_contains(str(m.distance), "million km")
	assert_string_contains(str(m.fact), "2034")
	var legs: Array = m.legs
	assert_eq(legs.size(), 4)
	assert_string_contains(str(legs[1][0]), "Venus", "swinging past Venus")
	assert_string_contains(str(legs[2][0]), "moons", "flybys of Jupiter's moons")
	assert_string_contains(str(legs[3][0]), "Ganymede")
	assert_eq(FlightPlan.REAL_TRIP[SpaceRules.GANYMEDE], "almost 12 years", "the flight says the board's trip")
	var words := MissionRules.needs_words(m)
	assert_false(words.any(func(w: String) -> bool: return w.contains("heat shield")), "no heat shield: %s" % [words])


## The mission is reachable: a rocket of 209 parts (about 7,100 gold, 6 stages; Triton's needs 266) passes every line of
## the check for the Mission to Ganymede (found by a search over the parts' numbers with the check's rules; the notes
## have it).
func test_a_rocket_a_child_can_build_reaches_ganymede() -> void:
	var r := RocketCheck.check(_rocket(), MissionRules.for_world(28))
	assert_true(r.ok, "every line passes: %s" % [(r.lines as Array).filter(func(l: Dictionary) -> bool:
		return not l.ok).map(func(l: Dictionary) -> String: return str(l.text))])
	assert_gte(float(r.dv), MissionRules.need(MissionRules.for_world(28)), "enough speed (%.2f km/s)" % float(r.dv))
	assert_eq((r.cells as Dictionary).size(), ROCKET_PARTS, "a rocket of %d parts" % ROCKET_PARTS)
	assert_lt(RocketParts.cost(RocketParts.count(r.cells)),
		RocketParts.cost(RocketParts.count(RocketCheck.check(_triton_rocket(), MissionRules.for_world(27)).cells)),
		"cheaper than Triton's: less speed, no heat shield")


const ROCKET_PARTS := 209
## [engine, engines, tanks] per stage, bottom first (the search's design; stage 1 also has 3 fins).
const STAGES := [[BlockIds.ROCKET_ENGINE, 41, 5], [BlockIds.SPACE_ENGINE, 29, 62], [BlockIds.SPACE_ENGINE, 8, 12],
	[BlockIds.SPACE_ENGINE, 4, 6], [BlockIds.SPACE_ENGINE, 2, 2], [BlockIds.SPACE_ENGINE, 1, 2]]


func _rocket() -> Dictionary:
	return _build(STAGES, 22, false)


func _triton_rocket() -> Dictionary:
	return _build([[BlockIds.ROCKET_ENGINE, 54, 1], [BlockIds.SPACE_ENGINE, 40, 82], [BlockIds.SPACE_ENGINE, 12, 24],
		[BlockIds.SPACE_ENGINE, 4, 6], [BlockIds.SPACE_ENGINE, 2, 3], [BlockIds.SPACE_ENGINE, 1, 1]], 22, true)


func _build(stages: Array, modules: int, shield: bool) -> Dictionary:
	var cells := {}
	var y := 0
	for i in stages.size():
		var st: Array = stages[i]
		y = _layers(cells, y, _many(int(st[0]), int(st[1])))
		var rest := _many(BlockIds.FUEL_TANK, int(st[2]))
		if i == 0:
			rest.append_array(_many(BlockIds.ROCKET_FINS, 3))
		y = _layers(cells, y, rest)
		if i < stages.size() - 1:
			y = _layers(cells, y, [BlockIds.STAGE_SEPARATOR])
	var payload := _many(BlockIds.SERVICE_MODULE, modules)
	if shield:
		payload.append(BlockIds.HEAT_SHIELD)
	payload.append(BlockIds.SOLAR_ARRAY)
	payload.append_array(_many(BlockIds.LANDING_LEGS, 3))
	y = _layers(cells, y, payload)
	_layers(cells, y, [BlockIds.CREW_CAPSULE])
	return cells


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
