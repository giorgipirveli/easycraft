extends GutTest
## In-situ resource use on the Moon and Mars (spec §26.5, owner #80): living off the land. Ice melts into water at an
## Ice Melter; an Oxygen Maker splits water into hydrogen fuel (the rocket's) and oxygen (to breathe), and pulls oxygen
## out of ilmenite; a Solar Oven (mirrors, sunlight: no fuel) bakes planet dust into bricks for the domes, and gets
## titanium from ilmenite, helium-3 from the seas' dust, rare earths from KREEP rock, iron from meteorites, hematite and
## dark sand, and oxygen from Mars's perchlorate salt; blueberries are sieved by hand. Hydrogen fuel, made far from
## Earth, sells: its gold buys the next rocket's tanks (the rocket's parts stay bought with gold, the missions' rule).
## Each step says a real fact; the fuel and the metals sell fairly at Tilly's, for less than her own water and ice would
## cost to make them (no loop through her colony stock); water, air and bricks help (never sold).


func test_the_stations() -> void:
	assert_has(Recipes.STATIONS, Recipes.MELTER)
	assert_has(Recipes.STATIONS, Recipes.OXYGEN_MAKER)
	assert_has(Recipes.STATIONS, Recipes.SOLAR_OVEN)
	assert_eq(Recipes.station_block(Recipes.MELTER), BlockIds.ICE_MELTER, "the colony's Ice Melter")
	assert_eq(Recipes.station_block(Recipes.OXYGEN_MAKER), BlockIds.OXYGEN_MAKER, "the colony's Oxygen Maker")
	assert_eq(Recipes.station_block(Recipes.SOLAR_OVEN), BlockIds.SOLAR_OVEN)
	assert_gt(ShopRules.price(BlockIds.SOLAR_OVEN), 0, "Tilly sells a Solar Oven")
	assert_gt(ShopRules.price(BlockIds.SOLAR_OVEN, SpaceRules.MOON), 0, "on the Moon too")
	assert_gt(ShopRules.price(BlockIds.ICE_MELTER, SpaceRules.MOON), 0, "Tilly sells the colony's Ice Melter on the Moon")
	assert_gt(ShopRules.price(BlockIds.OXYGEN_MAKER, SpaceRules.MARS), 0, "and its Oxygen Maker on Mars")
	assert_eq(Recipes.find(&"solar_oven").at, Recipes.TABLE, "a Solar Oven is built at a Workbench")


## Ice → water → hydrogen fuel (it pays: gold for the rocket's tanks) and oxygen (air).
func test_ice_becomes_water_air_and_rocket_fuel() -> void:
	for id: StringName in [&"melt_moon_ice", &"melt_mars_ice", &"melt_polar_ice"]:
		var r := Recipes.find(id)
		assert_eq(r.at, Recipes.MELTER, str(id))
		assert_eq(r.makes, BlockIds.WATER_TANK, "%s gives water" % id)
	assert_eq(Recipes.find(&"melt_moon_ice").needs, {BlockIds.ICY_REGOLITH: 2})
	assert_eq(Recipes.find(&"melt_mars_ice").needs, {BlockIds.GROUND_ICE: 2})
	var fuel := Recipes.find(&"split_fuel")
	assert_eq([fuel.at, fuel.needs, fuel.makes], [Recipes.OXYGEN_MAKER, {BlockIds.WATER_TANK: 2}, BlockIds.HYDROGEN_FUEL])
	var air := Recipes.find(&"split_oxygen")
	assert_eq([air.at, air.needs, air.makes], [Recipes.OXYGEN_MAKER, {BlockIds.WATER_TANK: 1}, BlockIds.OXYGEN_TANK])
	assert_true(Recipes.for_result(BlockIds.FUEL_TANK).is_empty(), "a rocket's Fuel Tank stays bought with gold (missions)")
	assert_gt(RefiningRules.sell_price(BlockIds.HYDROGEN_FUEL), 0, "the fuel pays: gold for the next rocket's tanks")
	assert_eq(RefiningRules.SPACE_FUEL, BlockIds.HYDROGEN_FUEL, "the space fuel hook")
	assert_eq(RefiningRules.ROCKET_FUEL, BlockIds.KEROSENE, "Earth's stays kerosene")
	assert_eq(Recipes.find(&"rock_oxygen").needs, {BlockIds.ILMENITE: 2}, "oxygen from Moon rock")
	assert_eq(Recipes.find(&"salt_oxygen").makes, BlockIds.OXYGEN_TANK, "oxygen from Mars's salt")


## Regolith → bricks for the domes: the colony's own Printed Regolith (ColonyRules' blocks), baked in a Solar Oven.
func test_dust_becomes_bricks_for_the_domes() -> void:
	for id: StringName in [&"moon_bricks", &"mars_bricks"]:
		var r := Recipes.find(id)
		assert_eq(r.at, Recipes.SOLAR_OVEN, str(id))
		assert_eq(r.makes, BlockIds.PRINTED_REGOLITH)
		assert_true(ColonyRules.STOCK.has(int(r.makes)), "a colony block: build your own dome")
	assert_eq(Recipes.find(&"moon_bricks").needs, {BlockIds.MOON_DUST: 4})
	assert_eq(Recipes.find(&"mars_bricks").needs, {BlockIds.MARS_REGOLITH: 4})
	assert_true(RefiningRules.helps(BlockIds.PRINTED_REGOLITH).contains("dome"))


func test_the_metals_and_the_rare_things() -> void:
	var pairs := {&"titanium": [BlockIds.ILMENITE, BlockIds.TITANIUM], &"helium3": [BlockIds.MARE_DUST, BlockIds.HELIUM_3],
		&"rare_earths": [BlockIds.KREEP_ROCK, BlockIds.RARE_EARTHS], &"meteorite_iron": [BlockIds.IRON_METEORITE, BlockIds.IRON],
		&"hematite_iron": [BlockIds.HEMATITE, BlockIds.IRON], &"sand_iron": [BlockIds.DARK_SAND, BlockIds.IRON]}
	for id: StringName in pairs:
		var r := Recipes.find(id)
		assert_eq(r.at, Recipes.SOLAR_OVEN, str(id))
		assert_true((r.needs as Dictionary).has(pairs[id][0]), str(id))
		assert_eq(r.makes, pairs[id][1], str(id))
	assert_gte(int(Recipes.find(&"helium3").needs[BlockIds.MARE_DUST]), 10, "tonnes of dust for a little helium-3")
	var sieve := Recipes.find(&"sieve_blueberries")
	assert_eq([sieve.at, sieve.needs, sieve.makes], [Recipes.HAND, {BlockIds.BLUEBERRY_SOIL: 3}, BlockIds.HEMATITE])


## Survivor: each machine works only next to it; the Solar Oven burns nothing (sunlight).
func test_in_a_bag_at_the_machines() -> void:
	var inv := Inventory.new()
	inv.add(BlockIds.ICY_REGOLITH, 4)
	var none := CraftRules.stations(Vector3.ZERO, [] as Array[Vector3i], [] as Array[Vector3i], CraftRules.REACH)
	assert_eq(CraftRules.refusal(Recipes.find(&"melt_moon_ice"), inv, none), "melter")
	assert_eq(CraftRules.message("melter", Recipes.find(&"melt_moon_ice"), inv), "Stand next to an Ice Melter!")
	assert_eq(CraftRules.message("oxygen_maker", Recipes.find(&"split_fuel"), inv), "Stand next to an Oxygen Maker!")
	assert_eq(CraftRules.message("solar_oven", Recipes.find(&"titanium"), inv), "Stand next to a Solar Oven!")
	var here := CraftRules.stations(Vector3.ZERO, [Vector3i(1, 0, 0)] as Array[Vector3i], [] as Array[Vector3i],
		CraftRules.REACH, [] as Array[Vector3i], {Recipes.MELTER: [Vector3i(0, 0, 2)], Recipes.OXYGEN_MAKER: [Vector3i(2, 0, 0)],
			Recipes.SOLAR_OVEN: [Vector3i(0, 1, 1)]})
	assert_true(here[Recipes.MELTER] and here[Recipes.OXYGEN_MAKER] and here[Recipes.SOLAR_OVEN])
	assert_true(CraftRules.craft(Recipes.find(&"melt_moon_ice"), inv, here).ok)
	assert_true(CraftRules.craft(Recipes.find(&"melt_moon_ice"), inv, here).ok)
	assert_eq(inv.count(BlockIds.WATER_TANK), 2)
	var r := CraftRules.craft(Recipes.find(&"split_fuel"), inv, here)
	assert_true(r.ok)
	assert_eq(r.fuel, BlockIds.AIR, "the machines burn nothing")
	assert_eq(inv.count(BlockIds.HYDROGEN_FUEL), 1)
	inv.add(BlockIds.ILMENITE, 2)
	assert_true(CraftRules.craft(Recipes.find(&"titanium"), inv, here).ok, "no fuel: sunlight")
	var said := CraftRules.done_message(Recipes.find(&"titanium"))
	assert_string_contains(said, "You made 1 Titanium!", "stuff is counted")
	assert_string_contains(said, "strong and light", "the step's real fact")
	assert_string_contains(CraftRules.done_message(Recipes.find(&"split_fuel")), "You made 1 Hydrogen Fuel!")


func test_what_pays_and_what_helps() -> void:
	for id: int in [BlockIds.HYDROGEN_FUEL, BlockIds.TITANIUM, BlockIds.RARE_EARTHS, BlockIds.HELIUM_3]:
		assert_gt(RefiningRules.sell_price(id), 0, "%s sells at Tilly's" % BlockIds.display_name(id))
		assert_eq(ShopRules.sell_price(id), RefiningRules.SELL[id], "one price")
		for u: int in [1, SpaceRules.MOON, SpaceRules.MARS]:
			assert_false(ShopRules.for_sale(id, u), "Tilly never sells %s in %d (no gold loop)" % [BlockIds.display_name(id), u])
	for id: int in [BlockIds.WATER_TANK, BlockIds.OXYGEN_TANK, BlockIds.PRINTED_REGOLITH]:
		for u: int in [1, SpaceRules.MOON, SpaceRules.MARS]:
			assert_eq(ShopRules.sell_price(id, u), 0, "%s helps: never sold to Tilly" % BlockIds.display_name(id))
		assert_ne(RefiningRules.helps(id), "", "%s says how it helps" % BlockIds.display_name(id))
	for id: int in ProspectSpacePage.FOUND:
		assert_eq(ShopRules.sell_price(id), 0, "%s is refined before it sells" % BlockIds.display_name(id))
	assert_gt(RefiningRules.sell_price(BlockIds.RARE_EARTHS), RefiningRules.sell_price(BlockIds.TITANIUM),
		"rare earths are the rarest")
	# No loop: fuel made from Tilly's own water tanks (or Mars's polar ice she sells) costs more than it sells for.
	for u: int in [SpaceRules.MOON, SpaceRules.MARS]:
		var water := ShopRules.price(BlockIds.WATER_TANK, u)
		if ShopRules.for_sale(BlockIds.POLAR_ICE, u):
			water = mini(water, ShopRules.price(BlockIds.POLAR_ICE, u) * int(Recipes.find(&"melt_polar_ice").needs[BlockIds.POLAR_ICE]))
		var fuel_cost := water * int(Recipes.find(&"split_fuel").needs[BlockIds.WATER_TANK])
		assert_gt(fuel_cost, ShopRules.sell_price(BlockIds.HYDROGEN_FUEL, u), "%d: bought water never pays as fuel" % u)


## How a find is worked, on the find's card: the ice's whole chain to the rocket's tank.
func test_the_find_card_tells_the_whole_chain() -> void:
	var lines := "\n".join(RefiningRules.lines_for(DepositKinds.MOON_ICE))
	for want: String in ["Icy Regolith", "Ice Melter", "Water Tank", "Hydrogen Fuel", "Oxygen Tank", "next rocket's tanks"]:
		assert_string_contains(lines, want)
	lines = "\n".join(RefiningRules.lines_for(DepositKinds.MARS_ICE))
	assert_string_contains(lines, "Ground Ice")
	assert_string_contains(lines, "Hydrogen Fuel")
	lines = "\n".join(RefiningRules.lines_for(DepositKinds.ILMENITE))
	assert_string_contains(lines, "Titanium")
	assert_string_contains(lines, "gold each at Tilly's")
	assert_string_contains(lines, "Oxygen Tank")
	var earth := "\n".join(RefiningRules.lines_for(DepositKinds.IRON))
	assert_false(earth.contains("Hydrogen"), "Earth's iron card stays as it was")


## A deposit refined and sold is worth about a day of learning, like Earth's.
func test_a_deposit_is_worth_about_a_day_of_learning() -> void:
	for planet: StringName in [SpaceShape.MOON, SpaceShape.MARS]:
		var shape := SpaceShape.new(12345, planet)
		var rules := DepositRules.for_world(12345, shape, SpaceSecretRules.new(12345, shape))
		for kind in rules.kinds:
			var d := rules.nearest(kind, Vector3(rules.spawn.x, 0, rules.spawn.y), [], 3)
			var cells := DepositRules.cells_of(d)
			var worth := 0.0
			for p: Vector3i in cells:
				worth += _gold_per_block(int(cells[p]))
			assert_lte(worth, 1400.0, "%s is worth %d gold refined and sold" % [d.id, worth])
			if kind in [DepositKinds.MOON_ICE, DepositKinds.ILMENITE, DepositKinds.HELIUM_3, DepositKinds.KREEP,
					DepositKinds.MARS_ICE, DepositKinds.HEMATITE, DepositKinds.DARK_SAND]:
				assert_gte(worth, 100.0, "%s pays (%d gold)" % [d.id, worth])


## Gold a found block is worth once refined and sold (the best chain of single-ingredient recipes: ice → water → fuel).
func _gold_per_block(id: int, depth: int = 0) -> float:
	var best := float(ShopRules.sell_price(id))
	if depth > 3:
		return best
	for r: Dictionary in Recipes.LIST:
		if RefiningRules.is_refining(r.id) and (r.needs as Dictionary).has(id) and (r.needs as Dictionary).size() == 1:
			var made := int(r.makes)
			best = maxf(best, _gold_per_block(made, depth + 1) * int(r.count) / float(int(r.needs[id])))
	return best
