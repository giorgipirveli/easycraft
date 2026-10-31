extends GutTest
## Owner #72, #74 (spec §21b.1): the Star Map. Our solar system in its real order with its moons, every body with three
## real facts; the game's own planets and every universe far away; each body says what a tap can do from where the
## child is: LAND on a built world, HOME, "You are here", a universe's portal, or honestly "Coming soon".

const OPEN_WORLDS: Array[int] = [16, 17, 18]


func after_each() -> void:
	UniverseRegistry.reset()


func _ids(kind: String) -> Array[StringName]:
	var out: Array[StringName] = []
	for b: Dictionary in StarMap.bodies():
		if str(b.kind) == kind:
			out.append(b.id)
	return out


func test_the_planets_are_in_their_real_order_out_from_the_sun() -> void:
	var order: Array[StringName] = []
	for b: Dictionary in StarMap.bodies():
		if ["star", "planet", "dwarf"].has(str(b.kind)):
			order.append(b.id)
	assert_eq(order, [&"sun", &"mercury", &"venus", &"earth", &"mars", &"jupiter", &"saturn", &"uranus", &"neptune",
		&"pluto"] as Array[StringName])


func test_moons_go_round_their_planets() -> void:
	var parents := {}
	for b: Dictionary in StarMap.bodies():
		if str(b.kind) == "moon":
			parents[b.id] = b.parent
	assert_eq(parents, {&"moon": &"earth", &"io": &"jupiter", &"europa": &"jupiter", &"ganymede": &"jupiter",
		&"callisto": &"jupiter", &"titan": &"saturn", &"triton": &"neptune"})


func test_jupiter_is_the_biggest_and_the_sun_bigger_still() -> void:
	var r := {}
	for b: Dictionary in StarMap.bodies():
		r[b.id] = float(b.size)
	for id: StringName in [&"mercury", &"venus", &"earth", &"mars", &"saturn", &"uranus", &"neptune", &"pluto"]:
		assert_gt(r[&"jupiter"], r[id], "Jupiter is bigger than %s" % id)
	assert_gt(r[&"sun"], r[&"jupiter"])
	assert_gt(r[&"earth"], r[&"mars"], "Mars is about half as wide as Earth")
	assert_gt(r[&"mars"], r[&"mercury"])
	assert_gt(r[&"ganymede"], r[&"mercury"] * 0.9, "Ganymede is a little bigger than Mercury")


func test_every_body_has_three_facts_that_fit_its_card() -> void:
	var seen := {}
	for b: Dictionary in StarMap.bodies():
		assert_false(seen.has(b.id), "%s twice" % b.id)
		seen[b.id] = true
		assert_eq((b.facts as Array).size(), 3, str(b.id))
		for f: String in b.facts:
			assert_between(f.length(), 12, StarMap.MAX_FACT, "%s: %s" % [b.id, f])
		assert_ne(str(b.name), "", str(b.id))


func test_the_worlds_to_land_on_have_their_numbers() -> void:
	var worlds := {}
	for b: Dictionary in StarMap.bodies():
		if int(b.world) > 0:
			worlds[b.id] = int(b.world)
	assert_eq(worlds.get(&"moon"), SpaceRules.MOON)
	assert_eq(worlds.get(&"boing"), SpaceRules.BOING)
	assert_eq(worlds.get(&"rainbow"), SpaceRules.RAINBOW)
	assert_eq(worlds.get(&"mars"), SpaceRules.MARS)
	assert_eq(worlds.get(&"earth"), EarthRules.WONDERS, "owner #78: Earth lands at the Wonders of the World")
	assert_eq(worlds.get(&"ganymede"), SpaceRules.GANYMEDE, "cosmos: Ganymede is world 28")
	for id: StringName in [&"sun", &"jupiter", &"uranus", &"callisto"]:
		assert_false(worlds.has(id), "%s: nothing to land on in the game (yet)" % id)
	var numbers := {}
	for id: StringName in worlds:
		var u: int = worlds[id]
		assert_false(numbers.has(u), "world %d twice" % u)
		numbers[u] = true
		if not _ids("universe").has(id):
			assert_true(SpaceRules.is_space(u) or EarthRules.is_earth(u), "%s: a space or an Earth world (%d)" % [id, u])


func test_every_built_universe_is_a_planet_far_away_and_the_next_ones_are_coming() -> void:
	var universes: Array[int] = []
	for b: Dictionary in StarMap.bodies():
		if str(b.kind) == "universe":
			universes.append(int(b.world))
			assert_eq(b.name, UniverseRegistry.display_name(int(b.world)) if int(b.world) <= UniverseRegistry.size()
				else b.name)
	for u in range(1, UniverseRegistry.size() + 1):
		assert_has(universes, u, "universe %d" % u)
	assert_true(universes.any(func(u: int) -> bool: return u > UniverseRegistry.size()), "one still to come")


func test_from_the_meadows() -> void:
	var s := StarMap.states(1, 1, OPEN_WORLDS, 2)
	assert_eq(s[&"moon"], StarMap.LAND)
	assert_eq(s[&"boing"], StarMap.LAND)
	assert_eq(s[&"mars"], StarMap.COMING_SOON, "Mars is next to build")
	assert_eq(s[&"jupiter"], StarMap.NO_GROUND)
	assert_eq(s[&"sun"], StarMap.NO_GROUND)
	assert_eq(s[&"earth"], StarMap.COMING_SOON, "owner #78: its wonders' world is not in this list of built worlds")
	assert_eq(StarMap.states(1, 1, [16, 41] as Array[int], 2)[&"earth"], StarMap.LAND, "built: LAND at the wonders")
	assert_eq(s[&"green_meadows"], StarMap.HERE)
	assert_eq(s[&"sandstorm_desert"], StarMap.PORTAL, "opened: through its portal")
	assert_eq(s[&"frostpeak"], StarMap.LOCKED)
	assert_eq(s[&"universe_6"], StarMap.LOCKED, "the Glow Caves are built: beat the Sky Dragon to open them")
	assert_eq(s[&"universe_7"], StarMap.COMING_SOON)


func test_from_the_moon_home_is_where_the_trip_started() -> void:
	var s := StarMap.states(16, 3, OPEN_WORLDS, 3)
	assert_eq(s[&"moon"], StarMap.HERE)
	assert_eq(s[&"frostpeak"], StarMap.HOME)
	assert_eq(s[&"green_meadows"], StarMap.PORTAL)
	assert_eq(s[&"boing"], StarMap.LAND)


func test_a_built_real_planet_can_be_landed_on() -> void:
	var open := OPEN_WORLDS.duplicate()
	open.append(SpaceRules.MARS)
	assert_eq(StarMap.states(1, 1, open, 1)[&"mars"], StarMap.LAND)


func test_what_each_state_says() -> void:
	for state: StringName in [StarMap.LAND, StarMap.HOME, StarMap.HERE, StarMap.PORTAL, StarMap.LOCKED,
			StarMap.COMING_SOON, StarMap.NO_GROUND, StarMap.LOOK]:
		assert_ne(StarMap.action_words(state), "", str(state))
	assert_eq(StarMap.action_words(StarMap.LAND), "LAND")
	assert_eq(StarMap.action_words(StarMap.HOME), "HOME")
	assert_eq(StarMap.action_words_for(&"earth", StarMap.LAND), "Wonders of the World: LAND", "owner #78")
	assert_eq(StarMap.action_words_for(&"moon", StarMap.LAND), "LAND")
	assert_eq(StarMap.action_words_for(&"earth", StarMap.HERE), StarMap.action_words(StarMap.HERE))


## Owner #78 (spec §24): from the wonders' world, Earth is where the child is and HOME is where the trip started.
func test_from_the_wonders_home_is_where_the_trip_started() -> void:
	var s := StarMap.states(EarthRules.WONDERS, 3, [16, 41] as Array[int], 3)
	assert_eq(s[&"earth"], StarMap.HERE)
	assert_eq(s[&"frostpeak"], StarMap.HOME)
	assert_eq(s[&"moon"], StarMap.LAND)


## Owner #91: "we need animation, movements, cyrcle as it is in reality". Each planet's orbit: its real year (days) and
## where it was on 1 January 2000 at noon (its mean longitude); from them, where it is on any day (a circle: the mean
## longitude, good to a few degrees for the planets).
func test_the_planets_go_round_the_sun_in_their_real_years() -> void:
	assert_almost_eq(StarMap.year_days(&"earth"), 365.256, 0.01)
	assert_almost_eq(StarMap.year_days(&"mercury"), 87.97, 0.05, "Mercury: 88 days")
	assert_almost_eq(StarMap.year_days(&"neptune") / 365.25, 164.8, 0.2, "Neptune: about 165 years")
	var order: Array[StringName] = [&"mercury", &"venus", &"earth", &"mars", &"jupiter", &"saturn", &"uranus",
		&"neptune", &"pluto"]
	for i in order.size() - 1:
		assert_lt(StarMap.year_days(order[i]), StarMap.year_days(order[i + 1]), "%s is faster than %s" % order.slice(i, i + 2))
	assert_almost_eq(rad_to_deg(StarMap.longitude(&"earth", 0.0)), 100.46, 0.01, "Earth at the start of 2000")
	var a := StarMap.longitude(&"mercury", 0.0)
	var b := StarMap.longitude(&"mercury", StarMap.year_days(&"mercury"))
	assert_almost_eq(angle_difference(a, b), 0.0, 0.0001, "one year later, back where it was")
	assert_almost_eq(angle_difference(StarMap.longitude(&"mars", 0.0), StarMap.longitude(&"mars", StarMap.year_days(&"mars") / 4.0)),
		PI / 2.0, 0.0001, "a quarter of a year: a quarter of the way round")
	assert_eq(StarMap.year_days(&"moon"), 0.0, "a moon goes round its planet, not the Sun")
	assert_gt(StarMap.days_since_2000(1790697951.0), 9400.0, "2026 is over 9,400 days after 2000")
