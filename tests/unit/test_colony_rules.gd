extends GutTest
## Colonies under domes (owner #77, spec §21c): ColonyRules, the colonies' pure rules. The Moon and Mars have one; each
## part says a real fact the first time a child walks in (the descriptors' sights: the Great Dome is the big one on MY MAP
## and the explorer's checklist, the other parts are small ones); no real person's, company's or mission's name
## (§21b.2); Tilly sells the colony's blocks there; the Gold Shop's DECORATIONS shelf sells dome decorations into the
## backpack; the Great Dome's animals are the game's own.

const BRANDS: Array[String] = ["NASA", "ESA", "JPL", "SpaceX", "Starship", "Falcon", "Apollo", "Artemis", "MOXIE",
	"Perseverance", "Opportunity", "Curiosity", "Veggie", "Musk", "Elon", "Blue Origin", "Gateway", "InSight", "Mars One"]


func after_each() -> void:
	UniverseRegistry.reset()
	SpendRules.clear_extra()


func test_the_moon_and_mars_have_a_colony() -> void:
	assert_true(ColonyRules.has_colony(SpaceShape.MOON))
	assert_true(ColonyRules.has_colony(SpaceShape.MARS))
	for p: StringName in [SpaceShape.BOING, SpaceShape.RAINBOW, SpaceShape.EUROPA, SpaceShape.IO, SpaceShape.TITAN,
			SpaceShape.MERCURY]:
		assert_false(ColonyRules.has_colony(p), "no colony on %s yet (§21c.5: more worlds later)" % p)


func test_every_part_has_a_name_and_a_real_fact_on_both_worlds() -> void:
	assert_eq(ColonyRules.PARTS.size(), 12)
	assert_eq(ColonyRules.PARTS[0], ColonyRules.DOME, "the Great Dome first: the colony's big sight")
	for planet: StringName in ColonyRules.PLANETS:
		var sights := ColonyRules.sights(planet)
		assert_eq(sights.size(), ColonyRules.PARTS.size(), str(planet))
		for id: StringName in ColonyRules.PARTS:
			assert_true(sights.has(id), "%s: %s" % [planet, id])
			var e: Dictionary = sights[id]
			assert_ne(str(e.name), "", "%s: a name" % id)
			var words := str(e.words)
			assert_true(words.begins_with("You found"), words)
			assert_gt(words.find("! "), 0, "a find, then a fact: %s" % words)
			assert_true(words.ends_with("."), words)
			assert_lt(words.length(), 125, "short enough for the toast: %s" % words)
	assert_eq(ColonyRules.sights(SpaceShape.MARS)[ColonyRules.DOME].name, "Mars Colony")
	assert_eq(ColonyRules.sights(SpaceShape.MOON)[ColonyRules.DOME].name, "Moon Colony")
	assert_true(ColonyRules.sights(SpaceShape.EUROPA).is_empty())


## The real idea (spec §21c.1), each fact checked against the agencies' own pages (the notes list the sources).
func test_the_facts_are_the_real_ones() -> void:
	var mars := ColonyRules.sights(SpaceShape.MARS)
	var moon := ColonyRules.sights(SpaceShape.MOON)
	assert_string_contains(mars[ColonyRules.DOME].words, "too thin to breathe")
	assert_string_contains(moon[ColonyRules.DOME].words, "no air")
	assert_string_contains(mars[ColonyRules.OXYGEN].words, "Mars's air")
	assert_string_contains(mars[ColonyRules.OXYGEN].words, "10 hours")
	assert_string_contains(moon[ColonyRules.OXYGEN].words, "splits water")
	assert_string_contains(mars[ColonyRules.WATER].words, "under the dust")
	assert_string_contains(moon[ColonyRules.WATER].words, "south pole")
	assert_string_contains(mars[ColonyRules.CONTROL].words, "3 to 22 minutes")
	assert_string_contains(moon[ColonyRules.CONTROL].words, "1.3 seconds")
	assert_string_contains(moon[ColonyRules.GARDEN].words, "red and blue light")
	assert_string_contains(moon[ColonyRules.HOMES].words, "Moon dust")
	assert_string_contains(mars[ColonyRules.HOMES].words, "Sun's harmful rays")
	assert_string_contains(mars[ColonyRules.SOLAR].words, "less than half")
	assert_string_contains(moon[ColonyRules.SOLAR].words, "almost all the time")
	assert_string_contains(mars[ColonyRules.ROCKET].words, "7 months")
	assert_string_contains(moon[ColonyRules.ROCKET].words, "15-storey")
	assert_string_contains(moon[ColonyRules.GARAGE].words, "1971")
	assert_string_contains(mars[ColonyRules.GARAGE].words, "45 kilometres")
	assert_string_contains(moon[ColonyRules.LAB].words, "382 kilograms")
	assert_string_contains(mars[ColonyRules.MINE].words, "rocket fuel")
	assert_string_contains(moon[ColonyRules.MINE].words, "south pole")
	assert_string_contains(mars[ColonyRules.AIRLOCK].words, "two doors")


func test_no_real_names_and_never_scary() -> void:
	for planet: StringName in ColonyRules.PLANETS:
		for e: Dictionary in ColonyRules.sights(planet).values():
			for text: String in [str(e.name), str(e.words)]:
				for name in BRANDS:
					assert_eq(text.find(name), -1, "general words, no real names (§21b.2): %s" % text)
				for w in ["die", "dead", "danger", "scary", "hurt", "burn", "deadly", "kill"]:
					assert_false(RegEx.create_from_string("\\b%s\\b" % w).search(text.to_lower()) != null,
						"friendly (§3c): %s" % text)


func test_the_parts() -> void:
	assert_true(ColonyRules.is_part(ColonyRules.DOME))
	assert_true(ColonyRules.is_part(ColonyRules.MINE))
	assert_false(ColonyRules.is_part(&"volcano"))
	assert_false(ColonyRules.is_small_part(ColonyRules.DOME), "the Great Dome is the big sight")
	assert_true(ColonyRules.is_small_part(ColonyRules.LAB))
	assert_false(ColonyRules.is_small_part(&"river"))


## Build your own (spec §21c.2): every colony block in Tilly's stock on the Moon and Mars, at a price in gold.
func test_tilly_sells_the_colonys_blocks_on_both_worlds() -> void:
	for u: int in [SpaceRules.MOON, SpaceRules.MARS]:
		var stock := UniverseRegistry.trader_stock(u)
		for id: int in ColonyBlocks.TILES:
			assert_true(stock.has(id), "%s on world %d" % [BlockIds.display_name(id), u])
			assert_gt(int(stock[id]), 0)
		assert_has(ShopRules.catalog(ShopRules.BLOCKS, u), BlockIds.DOME_GLASS, "Tilly's BLOCKS on world %d" % u)
		assert_eq(ShopRules.price(BlockIds.GROW_LAMP, u), stock[BlockIds.GROW_LAMP], "never scaled in space")
	assert_false(UniverseRegistry.trader_stock(SpaceRules.EUROPA).has(BlockIds.DOME_GLASS), "only where a colony stands")


## The Gold Shop's DECORATIONS shelf (SpendRules.register): dome decorations, bought again and again, into the backpack
## for the next Survivor world.
func test_dome_decorations_on_the_gold_shops_shelf() -> void:
	ColonyRules.register_shelf()
	var profile := ProfileData.new()
	var items := SpendRules.items(SpendRules.DECOR, profile)
	assert_gte(items.size(), 8, "a shelf of decorations")
	for it: Dictionary in items:
		assert_true(str(it.id).begins_with("decor:"), str(it.id))
		assert_gt(int(it.price), 0)
		assert_ne(str(it.name), "")
	profile.survivor_gold = 1000
	var first: Dictionary = items[0]
	assert_eq(SpendRules.buy(profile, first.id), SpendRules.OK)
	assert_eq(profile.survivor_gold, 1000 - int(first.price))
	var packed := 0
	for k: int in profile.backpack:
		packed += int(profile.backpack[k])
		assert_true(Inventory.ownable(k), "a bag holds %s" % BlockIds.display_name(k))
	assert_gt(packed, 0, "the blocks wait in the backpack")
	assert_eq(SpendRules.buy(profile, first.id), SpendRules.OK, "bought again and again (never 'yours' once)")
	assert_false(profile.bought.has(first.id))
	ColonyRules.register_shelf()
	assert_eq(SpendRules.items(SpendRules.DECOR, profile).size(), items.size(), "registering twice adds nothing")


func test_the_great_domes_animals_are_the_games_own() -> void:
	var n := 0
	for e: Dictionary in ColonyRules.HERD:
		assert_true(AnimalRules.SPECIES.has(e.species), str(e.species))
		n += int(e.count)
	assert_between(n, 6, 12, "a few, within the budget")
	assert_true(ColonyRules.HERD.any(func(e: Dictionary) -> bool: return e.species == &"fish"), "fish in the pond")
	assert_true(ColonyRules.HERD.any(func(e: Dictionary) -> bool: return e.species == &"rabbit"), "bunnies")
	assert_true(ColonyRules.HERD.any(func(e: Dictionary) -> bool: return e.species == &"chicken"), "chickens")
