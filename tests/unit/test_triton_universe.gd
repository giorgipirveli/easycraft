extends GutTest
## Cosmos: Triton is world 27 (world/universes/triton.gd, spec §21b.2), a space world like the Moon, Mars, Europa, Io,
## Titan, Mercury, Venus's cloud city, Saturn's rings and Pluto: its descriptor brings its terrain and secrets (SpaceShape
## TRITON, SpaceSecretRules: the Hopper Lander), its real gravity (0.079 of Earth's: long, floaty jumps), peace, its own sky
## (a very thin nitrogen air: black and starry by day with a faint haze low down; the Sun a bright star, 30 times as far
## as from Earth; Neptune huge, deep blue with its dark spot, in the north-east, never moving: Triton always shows it the
## same face), soft chimes, calm music, no animals (lifeless), Tilly's local things, the landing words, real facts in its
## finds' words and at its sights (the Neptune Lookout, a geyser, a dark streak, the pink polar cap, the cantaloupe
## terrain, a frozen lake of ice lava, one of its few craters), a helper robot and the aliens' camp, a mission (a
## spacecraft flew past after 12 years; the game's rocket stays by skimming Triton's thin air behind a blow-up heat
## shield, as a real study planned), a picture card and loading hints. It says that Triton goes round Neptune backwards
## (the only big moon that does: probably caught from the Kuiper Belt, Pluto's cousin). The cold is a fact, never a
## danger; the geysers are safe and fun. The Star Map then says LAND (or MISSION) for Triton.


func after_each() -> void:
	UniverseRegistry.reset()
	LabRules.world_gravity = 1.0


func _triton() -> Object:
	return UniverseRegistry.descriptor(SpaceRules.TRITON)


func test_triton_is_world_27_a_space_world_found_by_the_registry() -> void:
	assert_eq(SpaceRules.TRITON, 27)
	assert_has(SpaceRules.WORLDS, SpaceRules.TRITON, "the picker and the Star Map know it")
	assert_eq(SpaceRules.WORLDS.slice(0, 12), [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27] as Array[int])
	assert_true(UniverseRegistry.is_space(27))
	assert_true(UniverseRegistry.exists(27))
	assert_true(UniverseRegistry.space_available().has(27))
	assert_false(UniverseRegistry.available().has(27), "not on the ladder")
	var d := _triton()
	assert_eq(d.get("name"), &"triton")
	assert_eq(d.get("index"), 27)
	assert_eq(UniverseRegistry.display_name(27), "Triton")
	assert_eq(UniverseRegistry.path_for(27), "res://world/universes/triton.gd")
	assert_false(ShopCatalog.needs_plus(27), "free for everyone")
	assert_eq(UniverseRules.scale(27), 1, "never scaled")
	assert_eq(ModeRules.slot(ModeRules.SANDBOX, 27), "sandbox_27")


func test_the_star_map_says_land_on_triton_and_the_space_book_marks_it() -> void:
	var s := StarMap.states(1, 1, UniverseRegistry.space_available(), 1)
	assert_eq(s[&"triton"], StarMap.LAND, "Triton can be landed on now")
	assert_eq(StarMap.action_words_for(&"triton", StarMap.LAND), "LAND")
	assert_eq(s[&"neptune"], StarMap.NO_GROUND, "Neptune itself has no ground: land on its moon")
	assert_eq(StarMap.states(27, 2, UniverseRegistry.space_available(), 2)[&"triton"], StarMap.HERE)
	assert_eq(StarMap.body_for_world(27), &"triton")
	var no_route: Array[int] = []
	assert_eq(StarMap.states(1, 1, UniverseRegistry.space_available(), 1, no_route)[&"triton"], StarMap.MISSION,
		"a mission first (spec §21d.5)")
	var w := WonderData.new()
	assert_true(w.land_on_world(27), "the first landing on Triton")
	assert_eq(w.bodies, {"triton": WonderData.SEEN | WonderData.LANDED})


func test_its_terrain_generator_and_secrets() -> void:
	var shape := UniverseRegistry.shape_for(27, 77)
	assert_true(shape is SpaceShape)
	assert_eq((shape as SpaceShape).planet, SpaceShape.TRITON)
	var gen := UniverseRegistry.generator_for(27, 77)
	assert_true(gen is SpaceGenerator)
	assert_eq((gen as SpaceGenerator).space_shape().planet, SpaceShape.TRITON)
	assert_eq((gen as SpaceGenerator).world_seed, 77)
	var rules: Variant = _triton().call(&"secret_rules", 77, shape)
	assert_true(rules is SpaceSecretRules)
	assert_eq((rules as SpaceSecretRules).landmark().get("name"), "Hopper Lander")


## Triton's real gravity: 0.779 m/s² ÷ 9.81 = 0.079: a jump floats ~21 blocks up for ~10 s; the step onto a one-block
## ledge stays gentle (LabRules.step_velocity: as high as on the Moon).
func test_real_gravity_long_floaty_jumps_and_the_landing_words() -> void:
	assert_almost_eq(UniverseRegistry.gravity(27), 0.079, 0.0001, "Triton's real gravity, about 8 % of Earth's")
	assert_true(UniverseRegistry.peaceful(27), "no monsters come by themselves")
	var words := UniverseRegistry.landing_words(27)
	assert_string_contains(words, "Triton")
	assert_string_contains(words, "Neptune")
	assert_string_contains(words, "geyser")
	LabRules.world_gravity = UniverseRegistry.gravity(27)
	var jump := LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	var air := LabRules.air_time(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	assert_between(jump, 18.0, 24.0, "a jump floats very high (%.1f blocks)" % jump)
	assert_between(air, 8.0, 11.0, "long and floaty (%.1f s)" % air)
	var step := LabRules.step_velocity(Player.AUTO_STEP_VELOCITY, LabRules.gravity_factor(LabRules.Mode.NORMAL))
	var hop := step * step / (2.0 * Player.GRAVITY * 0.079)
	assert_between(hop, 1.05, 3.6, "a step onto a ledge clears it gently (%.2f blocks)" % hop)


## A very thin nitrogen air: space's black starry sky by day with a faint haze low down (never the photo sky); the Sun
## about 30 times smaller than at home; Neptune huge and deep blue with its bands and its dark spot, in the north-east
## (the lookout looks there), never home's moon disc; two small moons as points.
func test_a_black_sky_a_star_like_sun_and_neptune_huge_and_blue() -> void:
	var space := UniverseRegistry.space_sky(27)
	assert_between(space, 0.7, 0.95, "mostly space's black, very thin air (%.2f)" % space)
	assert_false(UniverseRegistry.photo_sky(27), "never Earth's blue photo sky")
	var sky := UniverseRegistry.sky(27)
	assert_lt((sky.sky_top as Color).get_luminance(), 0.06, "black overhead")
	var haze: Color = sky.sky_horizon
	assert_gte(haze.b, haze.r, "a faint cold haze low down (%s)" % haze)
	assert_almost_eq(UniverseRegistry.sun_size(27), 0.033, 0.001, "the Sun 1/30 as wide: a very bright star")
	assert_false(UniverseRegistry.sun_rises_west(27), "(the game keeps its usual day: ruling)")
	var neptune := UniverseRegistry.sky_planet(27)
	assert_true(neptune.get("own_moons") == true, "Neptune's moons: home's big moon disc never shows")
	assert_gte(float(neptune.size), 90.0, "Neptune is huge in Triton's sky")
	var blue: Color = neptune.color
	assert_gt(blue.b, blue.r + 0.3, "deep blue (%s)" % blue)
	assert_true(neptune.get("bands") == true, "faint cloud bands")
	assert_true(neptune.get("spot") == true, "its dark spot")
	var spot: Color = neptune.spot_color
	assert_lt(spot.get_luminance(), 0.3, "a dark spot, not Jupiter's red one (%s)" % spot)
	var dir: Vector3 = (neptune.dir as Vector3).normalized()
	assert_gt(dir.x, 0.4, "in the east ...")
	assert_lt(dir.z, -0.4, "... and the north: where the lookout looks")
	assert_between(dir.y, 0.15, 0.4, "low over the horizon, in the day views there")
	assert_eq((neptune.get("moons", []) as Array).size(), 2, "two of Neptune's small moons")
	for m: Dictionary in neptune.moons:
		assert_lte(float(m.size), 2.5, "tiny points of light")


func test_its_sounds_music_and_no_animals() -> void:
	assert_eq(UniverseRegistry.ambience(27), {"day": &"chimes", "night": &"chimes"}, "soft icy chimes: air too thin for wind")
	assert_eq(UniverseRegistry.classical(27), [&"snow_dancing", &"moonlight"] as Array[StringName])
	for id in UniverseRegistry.classical(27):
		assert_false(MusicPieces.PIECES[id].moods.has(MusicPieces.BOSS), "a piece a day or a night plays, not a boss's")
	assert_eq(UniverseRegistry.music(27), {}, "no loops of its own")
	assert_true(UniverseRegistry.lifeless(27), "no life we know of")
	assert_eq(UniverseRegistry.animals(27), [] as Array[StringName], "no animals")


func test_tillys_triton_things() -> void:
	var stock := UniverseRegistry.trader_stock(27)
	for id in [BlockIds.TRITON_FROST, BlockIds.PINK_ICE, BlockIds.MOTTLED_ICE, BlockIds.GEYSER_DUST, BlockIds.CANTALOUPE_ICE,
			BlockIds.RIDGE_ICE, BlockIds.ICE_LAVA, BlockIds.NITROGEN_CRYSTAL, BlockIds.NITROGEN_TANK, BlockIds.NEPTUNE_GLOBE,
			BlockIds.BLUE_BEACON, BlockIds.CAP_BRICK, BlockIds.LANDING_PAD]:
		assert_true(stock.has(id), "%s to build with" % BlockIds.display_name(id))
	assert_false(stock.has(BlockIds.STAR_GOLD), "treasure is found, never sold")
	assert_false(stock.has(BlockIds.FAKE_PINK_ICE))
	assert_false(stock.has(BlockIds.NITROGEN_GEYSER), "Triton's geysers stay on Triton")
	assert_eq(ShopRules.price(BlockIds.PINK_ICE, 27), stock[BlockIds.PINK_ICE], "never scaled")


func test_every_find_says_a_real_triton_fact() -> void:
	var words: Dictionary = _triton().get("secret_words")
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.ISLAND, SecretRules.GEODE]:
		assert_true(words.has(k), str(k))
		var text: String = words[k]
		assert_true(text.begins_with("You found"), text)
		assert_gt(text.find("! "), 0, "a find, then a fact: %s" % text)
		assert_true(text.ends_with("."), text)
		assert_lt(text.length(), 110, "short enough for the banner: %s" % text)
	assert_string_contains(words[SecretRules.ISLAND], "Hopper Lander")
	assert_string_contains(words[SecretRules.ISLAND], "rocket fuel")
	assert_string_contains(words[SecretRules.TREASURE], "1846")
	assert_string_contains(words[SecretRules.TREASURE], "17 days")
	assert_string_contains(words[SecretRules.ROOM], "70 %")
	assert_string_contains(words[SecretRules.TEMPLE], "Pluto")
	assert_string_contains(words[SecretRules.GEODE], "235 °C")


func test_its_sights_teach_real_facts() -> void:
	var sights := UniverseRegistry.sights(27)
	assert_eq(sights.keys(), [&"lookout", &"geyser", &"trail", &"cap", &"melon", &"lake", &"crater"])
	for id: StringName in sights:
		var e: Dictionary = sights[id]
		assert_ne(str(e.get("name", "")), "", "a name for the map: %s" % id)
		assert_true(str(e.words).begins_with("You "), e.words)
		assert_lt(str(e.words).length(), 120, e.words)
	assert_string_contains(sights[&"lookout"].words, "same face")
	assert_string_contains(sights[&"geyser"].words, "8 km")
	assert_string_contains(sights[&"geyser"].words, "nitrogen")
	assert_string_contains(sights[&"trail"].words, "wind")
	assert_string_contains(sights[&"cap"].words, "pink")
	assert_string_contains(sights[&"melon"].words, "melon")
	assert_string_contains(sights[&"lake"].words, "lava")
	assert_string_contains(sights[&"crater"].words, "young")
	var map_ids: Array = []
	for s: Dictionary in SpaceShape.new(12345, SpaceShape.TRITON).sights():
		map_ids.append(s.id)
	assert_eq(map_ids, sights.keys(), "MY MAP shows all seven from the landing")


## Triton goes round Neptune backwards: the only big moon that does; scientists think Neptune caught it from the Kuiper
## Belt (where Pluto is); said by the robot and the hints.
func test_it_says_triton_goes_round_backwards_and_was_probably_caught() -> void:
	var backwards := false
	var caught := false
	var cousin := false
	for t in _texts():
		var lower := t.to_lower()
		backwards = backwards or (lower.contains("backwards") and lower.contains("neptune"))
		caught = caught or lower.contains("kuiper belt")
		cousin = cousin or lower.contains("pluto")
	assert_true(backwards, "it goes round Neptune backwards")
	assert_true(caught, "probably caught from the Kuiper Belt")
	assert_true(cousin, "Pluto's icy cousin")


## The cold is a fact, never a danger; the geysers are a ride: no word says anything hurts, freezes a child or is scary.
func test_the_cold_and_the_geysers_are_never_a_danger() -> void:
	for t in _texts():
		for w in ["hurt", "burn", "danger", "dangerous", "scary", "careful", "die", "crash", "deadly", "freeze you",
				"too cold", "frozen solid in", "frostbite", "explode", "blast"]:
			var whole := RegEx.create_from_string("(?<![a-z])" + w + "(?![a-z])")
			assert_null(whole.search(t.to_lower()), "a friendly world (spec §3c): %s" % t)


func test_no_mission_names_or_brands_in_its_words() -> void:
	for t in _texts():
		for name in ["Voyager", "NASA", "ESA", "JPL", "Hubble", "NIAC", "Trident", "Neptune Odyssey", "LOFTID",
				"Triton Hopper", "Uhlanga", "Bubembe", "Ruach", "Tuonela", "Hili", "Mahilani", "Mazomba", "Leviathan"]:
			assert_eq(t.find(name), -1, "general words, no mission or map names (§21b.2): %s" % t)


func _texts() -> Array[String]:
	var texts: Array[String] = [UniverseRegistry.landing_words(27)]
	for w: String in (_triton().get("secret_words") as Dictionary).values():
		texts.append(w)
	for e: Dictionary in UniverseRegistry.sights(27).values():
		texts.append(str(e.words))
		texts.append(str(e.name))
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 27):
		texts.append(str(LoadingHints.HINTS[i].text))
	var r := CreatureWords.robot(27)
	for k in ["hello", "fact", "sample"]:
		texts.append(str(r.get(k, "")))
	for q: Dictionary in r.get("questions", []):
		texts.append(str(q.q))
		texts.append(str(q.hint))
		for c: Variant in q.choices:
			texts.append(str(c))
	var c := CreatureWords.camp(27)
	for id: StringName in [c.get("explorer", &""), c.get("trader", &"")]:
		var a := CreatureWords.alien(id)
		for k in ["pretend", "science", "asks", "hello"]:
			texts.append(str(a.get(k, "")))
	var m := MissionRules.for_world(27)
	texts.append(str(m.get("fact", "")))
	for leg: Array in m.get("legs", []):
		texts.append(str(leg[0]))
	return texts


func test_its_picture_card_and_loading_hints() -> void:
	var colors := UniverseRegistry.card_colors(27)
	assert_lt((colors.top as Color).get_luminance(), 0.2, "a dark sky on its card")
	assert_ne(UniverseArt.layout(27), UniverseArt.layout(26), "its own scene")
	var ids: Array = UniverseArt.legend(27).values()
	assert_has(ids, BlockIds.PINK_ICE, "the pink cap on the card")
	assert_has(ids, BlockIds.NITROGEN_TANK, "the Hopper Lander's tank")
	assert_has(ids, BlockIds.NITROGEN_GEYSER, "a geyser")
	var own := 0
	var backwards := false
	var jump := false
	var neptune := false
	var geyser := false
	var hours := false
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 27):
		if int(LoadingHints.HINTS[i].get("universe", 0)) == 27:
			own += 1
			var text := str(LoadingHints.HINTS[i].text)
			assert_lte(text.split(" ").size(), 10, text)
			backwards = backwards or text.contains("backwards")
			jump = jump or text.contains("jump")
			neptune = neptune or text.contains("never moves")
			geyser = geyser or text.contains("geyser")
			hours = hours or text.contains("4 hours")
	assert_gte(own, 8, "hints of its own")
	assert_true(backwards, "a hint says Triton goes round backwards")
	assert_true(jump, "a hint says jumps go high")
	assert_true(neptune, "a hint says Neptune never moves")
	assert_true(geyser, "a hint says the geysers are a ride")
	assert_true(hours, "a hint says sunlight takes about 4 hours")


func test_its_helper_robot_and_the_aliens_camp() -> void:
	assert_true(CreatureWords.has_robot(27))
	var r := CreatureWords.robot(27)
	assert_eq(str(r.name), "Spout")
	assert_string_contains(str(r.hello), str(r.name))
	assert_string_contains(str(r.sample), "sample")
	assert_eq((r.questions as Array).size(), 3)
	assert_true(AlienRules.has_camp(27), "the aliens' travelling camp")
	var c := CreatureWords.camp(27)
	assert_eq(CreatureWords.alien(c.explorer).role, &"explorer")
	assert_eq(CreatureWords.alien(c.trader).role, &"trader")
	assert_true(MiniRules.gives_mini(AlienRules.mini_kind(c.explorer)), "a friend comes along as a mini-buddy")
	assert_true(SpaceCreatures.wanted(27, ModeRules.SANDBOX))


## The Mission to Triton: a spacecraft flew past Triton in 1989 after 12 years (with swing-bys past Jupiter, Saturn and
## Uranus) and did not stop. The game's rocket swings past Jupiter to Neptune in about 12 years (7.4 km/s from low orbit,
## our arithmetic) and arrives about 10 km every second too fast; braking that by engines and matching Triton would take
## ~7.5 more (none of the pad's rockets does it). The way a real study planned: skim Triton's thin air behind a blow-up
## heat shield to stay at Neptune, a few small burns, then down onto the ice with the engines (its air is far too thin for
## a parachute). Air and water for 12 years.
func test_a_mission_to_triton() -> void:
	var m := MissionRules.for_world(27)
	assert_false(m.is_empty())
	assert_eq(m.body, &"triton")
	assert_eq(str(m.name), "Mission to Triton")
	assert_eq(str(m.trip), "about 12 years")
	assert_eq(int(m.days), 4380, "12 years")
	assert_false(bool(m.air), "its air is too thin for a parachute")
	assert_true(bool(m.skim), "a heat shield to skim its thin air")
	assert_almost_eq(MissionRules.need(m), 18.5, 0.001, "9.4 + 7.4 + 0.3 + 1.4")
	assert_lt(MissionRules.need(m), MissionRules.need(MissionRules.for_world(SpaceRules.MERCURY)),
		"Mercury's stays the hardest landing")
	assert_string_contains(str(m.distance), "billion km")
	assert_string_contains(str(m.fact), "flew past")
	assert_string_contains(str(m.fact), "heat shield")
	var legs: Array = m.legs
	assert_eq(legs.size(), 4)
	assert_string_contains(str(legs[1][0]), "Jupiter", "a swing past Jupiter")
	assert_string_contains(str(legs[2][0]), "thin air")
	assert_string_contains(str(legs[3][0]), "engines")
	assert_eq(FlightPlan.REAL_TRIP[SpaceRules.TRITON], "about 12 years", "the flight says the board's trip")
	var words := MissionRules.needs_words(m)
	assert_true(words.any(func(w: String) -> bool: return w.contains("heat shield") and not w.contains("parachute")),
		"the board asks for a heat shield, no parachute: %s" % [words])


## The check asks for the heat shield (to skim its thin air) and never a parachute.
func test_the_check_wants_a_heat_shield_and_no_parachute() -> void:
	var m := MissionRules.for_world(27)
	var r := RocketCheck.check(_rocket(false), m)
	var keys: Array = (r.lines as Array).map(func(l: Dictionary) -> StringName: return l.key)
	assert_has(keys, &"heat_shield")
	assert_does_not_have(keys, &"parachute", "no parachute line: Triton's air is far too thin")
	var shield: Dictionary = (r.lines as Array).filter(func(l: Dictionary) -> bool: return l.key == &"heat_shield")[0]
	assert_false(shield.ok, "no heat shield yet: %s" % shield.text)
	assert_string_contains(str(shield.text), "skim")
	var with := RocketCheck.check(_rocket(true), m)
	var ok: Dictionary = (with.lines as Array).filter(func(l: Dictionary) -> bool: return l.key == &"heat_shield")[0]
	assert_true(ok.ok, ok.text)
	assert_true(with.ok, "every line passes: %s" % [(with.lines as Array).filter(func(l: Dictionary) -> bool:
		return not l.ok).map(func(l: Dictionary) -> String: return str(l.text))])


## The mission is reachable: a rocket of 266 parts (about 4,300 gold since owner #98 halved the prices; it carries 22
## service modules from before one module kept an astronaut for the whole trip) passes every line of the check for the
## Mission to Triton (found by a search over the parts' numbers; the notes have it). Without the skim (braking ~7.5 km/s
## more by engines: about 25.7 km/s in all) no rocket of up to 7 stages the pad holds passes. Mission Control's own
## plan (RocketPlan) is far smaller: test_rocket_plan.gd.
func test_a_rocket_a_child_can_build_reaches_triton() -> void:
	var r := RocketCheck.check(_rocket(true), MissionRules.for_world(27))
	assert_true(r.ok, "every line passes")
	assert_gte(float(r.dv), MissionRules.need(MissionRules.for_world(27)), "enough speed (%.2f km/s)" % float(r.dv))
	assert_eq((r.cells as Dictionary).size(), 266, "a rocket of 266 parts")
	assert_between(RocketParts.cost(RocketParts.count(r.cells)), 4000, 4600, "about 4,300 gold")
	assert_lt(RocketPlan.gold(MissionRules.for_world(27), 1), RocketParts.cost(RocketParts.count(r.cells)),
		"owner #98: Mission Control's plan is cheaper")


func _rocket(shield: bool) -> Dictionary:
	var cells := {}
	var y := 0
	var stages := [[BlockIds.ROCKET_ENGINE, 54, 1], [BlockIds.SPACE_ENGINE, 40, 82], [BlockIds.SPACE_ENGINE, 12, 24],
		[BlockIds.SPACE_ENGINE, 4, 6], [BlockIds.SPACE_ENGINE, 2, 3], [BlockIds.SPACE_ENGINE, 1, 1]]
	for i in stages.size():
		var st: Array = stages[i]
		y = _layers(cells, y, _many(int(st[0]), int(st[1])))
		var rest := _many(BlockIds.FUEL_TANK, int(st[2]))
		if i == 0:
			rest.append_array(_many(BlockIds.ROCKET_FINS, 3))
		y = _layers(cells, y, rest)
		if i < stages.size() - 1:
			y = _layers(cells, y, [BlockIds.STAGE_SEPARATOR])
	var payload := _many(BlockIds.SERVICE_MODULE, 22)
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
