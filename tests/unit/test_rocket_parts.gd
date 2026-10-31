extends GutTest
## Missions (spec §21d.2, §25.3): the rocket parts in one table. Each part has real-ish numbers (tonnes full and empty,
## an engine's push in tonnes-force and its efficiency, specific impulse, in seconds; what it gives the crew) and a
## price in gold (bought at the Launch Site in every mode). Sources in docs/devlog/parts/missions.md.

const PARTS: Array[int] = [BlockIds.ROCKET_ENGINE, BlockIds.SPACE_ENGINE, BlockIds.FUEL_TANK, BlockIds.NOSE_CONE,
	BlockIds.CREW_CAPSULE, BlockIds.SERVICE_MODULE, BlockIds.HEAT_SHIELD, BlockIds.LANDING_LEGS, BlockIds.ROCKET_FINS,
	BlockIds.STAGE_SEPARATOR, BlockIds.SOLAR_ARRAY, BlockIds.PARACHUTE_PACK]


func test_twelve_parts_on_page_32_and_the_pad_is_not_a_part() -> void:
	assert_eq(RocketParts.ORDER, PARTS, "the shop's order: engines and fuel, then the crew's parts")
	for id in PARTS:
		assert_true(RocketParts.is_part(id), BlockIds.display_name(id))
		assert_between(id, 560, 575, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), 32)
	for id in [BlockIds.PAD_CONCRETE, BlockIds.PAD_STRIPE, BlockIds.STONE, BlockIds.AIR, BlockIds.LANDER_LEG, 999]:
		assert_false(RocketParts.is_part(id), str(id))


func test_the_numbers_of_each_part() -> void:
	assert_eq(RocketParts.mass_full(BlockIds.ROCKET_ENGINE), 4.0)
	assert_eq(RocketParts.push(BlockIds.ROCKET_ENGINE), 250.0, "tonnes-force: it could hold up 250 tonnes")
	assert_eq(RocketParts.isp(BlockIds.ROCKET_ENGINE), 300.0, "seconds: a kerosene engine")
	assert_eq(RocketParts.push(BlockIds.SPACE_ENGINE), 150.0)
	assert_eq(RocketParts.isp(BlockIds.SPACE_ENGINE), 450.0, "hydrogen: the most efficient fuel")
	assert_true(RocketParts.space_only(BlockIds.SPACE_ENGINE), "its big nozzle is made for space")
	assert_false(RocketParts.space_only(BlockIds.ROCKET_ENGINE))
	assert_eq(RocketParts.mass_full(BlockIds.FUEL_TANK), 100.0, "full")
	assert_eq(RocketParts.mass_empty(BlockIds.FUEL_TANK), 6.0, "empty: most of a rocket is fuel")
	assert_eq(RocketParts.fuel(BlockIds.FUEL_TANK), 94.0)
	assert_eq(RocketParts.fuel(BlockIds.ROCKET_ENGINE), 0.0, "an engine holds no fuel")
	assert_eq(RocketParts.seats(BlockIds.CREW_CAPSULE), 1)
	assert_eq(RocketParts.keeps(BlockIds.SERVICE_MODULE), 1, "owner #98: air, water and food for one astronaut, the whole trip")
	assert_eq(RocketParts.keeps(BlockIds.FUEL_TANK), 0)
	for id in PARTS:
		assert_gt(RocketParts.mass_full(id), 0.0, BlockIds.display_name(id))
		assert_gte(RocketParts.mass_full(id), RocketParts.mass_empty(id), BlockIds.display_name(id))
		assert_eq(RocketParts.is_engine(id), RocketParts.push(id) > 0.0, BlockIds.display_name(id))
		assert_ne(RocketParts.words(id), "", "%s says what it does" % BlockIds.display_name(id))
		assert_lte(RocketParts.words(id).length(), 150, "one or two lines on a card")


func test_every_part_costs_gold_and_a_rocket_costs_its_parts() -> void:
	for id in PARTS:
		assert_gt(RocketParts.price(id), 0, "%s costs gold in every mode" % BlockIds.display_name(id))
		assert_eq(RocketParts.PRICES[id], RocketParts.price(id))
	assert_eq(RocketParts.PRICES.size(), PARTS.size(), "one price table")
	assert_eq(RocketParts.price(BlockIds.STONE), 0, "not a part: not sold here")
	assert_gt(RocketParts.price(BlockIds.CREW_CAPSULE), RocketParts.price(BlockIds.FUEL_TANK), "a capsule is dearer than a tank")
	assert_gt(RocketParts.price(BlockIds.ROCKET_ENGINE), RocketParts.price(BlockIds.FUEL_TANK), "engines are the dear part")
	assert_eq(RocketParts.cost({BlockIds.ROCKET_ENGINE: 2, BlockIds.FUEL_TANK: 3}), 2 * 25 + 3 * 5)
	assert_eq(RocketParts.cost({BlockIds.STONE: 5}), 0)


## Owner #98: every price halved, in multiples of 5 and at least 5 (tuned with Mission Control's plans: test_rocket_plan).
func test_the_prices_were_halved() -> void:
	var before := {BlockIds.ROCKET_ENGINE: 50, BlockIds.SPACE_ENGINE: 60, BlockIds.FUEL_TANK: 15, BlockIds.NOSE_CONE: 10,
		BlockIds.CREW_CAPSULE: 80, BlockIds.SERVICE_MODULE: 40, BlockIds.HEAT_SHIELD: 40, BlockIds.LANDING_LEGS: 15,
		BlockIds.ROCKET_FINS: 5, BlockIds.STAGE_SEPARATOR: 10, BlockIds.SOLAR_ARRAY: 20, BlockIds.PARACHUTE_PACK: 30}
	for id in PARTS:
		var p := RocketParts.price(id)
		assert_eq(p % 5, 0, BlockIds.display_name(id))
		assert_gte(p, 5, BlockIds.display_name(id))
		assert_lte(absi(p * 2 - int(before[id])), 5, "%s: about half of %d" % [BlockIds.display_name(id), before[id]])


## Owner #98: lists a young reader (and the speaker) follows: plurals, in the shop's order, "and" before the last.
func test_parts_in_words_with_plurals() -> void:
	assert_eq(RocketParts.amount_words(BlockIds.ROCKET_ENGINE, 1), "1 rocket engine")
	assert_eq(RocketParts.amount_words(BlockIds.ROCKET_ENGINE, 8), "8 rocket engines")
	assert_eq(RocketParts.amount_words(BlockIds.LANDING_LEGS, 3), "3 landing legs")
	assert_eq(RocketParts.amount_words(BlockIds.ROCKET_FINS, 1), "1 fin")
	assert_eq(RocketParts.list_words({BlockIds.FUEL_TANK: 10, BlockIds.ROCKET_ENGINE: 8}), "8 rocket engines and 10 fuel tanks")
	assert_eq(RocketParts.list_words({BlockIds.ROCKET_FINS: 3, BlockIds.FUEL_TANK: 10, BlockIds.ROCKET_ENGINE: 8}),
		"8 rocket engines, 10 fuel tanks and 3 fins")
	assert_eq(RocketParts.list_words({BlockIds.NOSE_CONE: 1}), "1 nose cone")
	assert_eq(RocketParts.list_words({}), "")
	assert_eq(RocketParts.total({BlockIds.FUEL_TANK: 10, BlockIds.ROCKET_ENGINE: 8, BlockIds.STONE: 4}), 18)
	for id in PARTS:
		assert_true(RocketParts.NAMES.has(id), BlockIds.display_name(id))


## Owner #98 (bug 1): a part bought outside a world (the Gold Shop, a friend's present) counts for the Sandbox's rockets
## and waits in the backpack for the next Survivor world's bag.
func test_a_part_given_outside_a_world_reaches_both() -> void:
	var p := ProfileData.new()
	RocketParts.grant(p, BlockIds.FUEL_TANK, 2)
	assert_eq(int(p.missions.parts.get(BlockIds.FUEL_TANK, 0)), 2, "for the Sandbox's rockets")
	assert_eq(int(p.backpack.get(BlockIds.FUEL_TANK, 0)), 2, "and in the backpack for Survivor")
	var inv := Inventory.new()
	SpendRules.unpack_backpack(p, inv)
	assert_eq(inv.count(BlockIds.FUEL_TANK), 2, "the next Survivor world's bag gets them")
	RocketParts.grant(p, BlockIds.STONE, 1)
	assert_false(p.backpack.has(BlockIds.STONE), "only rocket parts")


## Survivor may also make the simple parts at a Workbench or a Clay Oven from real materials (a ruling: the machines,
## the tanks, the capsule, the service module, the solar array and the parachute are bought); every part says what real
## ones are made of.
func test_what_parts_are_made_of_and_what_survivor_crafts() -> void:
	for id in PARTS:
		assert_string_starts_with(RocketParts.made_of(id), "Real ones: ", BlockIds.display_name(id))
	var crafted := {}
	for r: Dictionary in Recipes.LIST:
		if RocketParts.is_part(int(r.makes)):
			crafted[int(r.makes)] = r
	assert_eq(crafted.keys().size(), 5)
	for id in [BlockIds.NOSE_CONE, BlockIds.ROCKET_FINS, BlockIds.LANDING_LEGS, BlockIds.STAGE_SEPARATOR]:
		assert_true(crafted.has(id), BlockIds.display_name(id))
		assert_eq(crafted[id].at, Recipes.TABLE, "%s: at a Workbench" % BlockIds.display_name(id))
		assert_true((crafted[id].needs as Dictionary).has(BlockIds.IRON), "%s is metal" % BlockIds.display_name(id))
	assert_eq(crafted[BlockIds.HEAT_SHIELD].at, Recipes.FURNACE, "ceramic, baked in the Clay Oven")
	assert_true((crafted[BlockIds.HEAT_SHIELD].needs as Dictionary).has(BlockIds.SAND))
	for id in [BlockIds.ROCKET_ENGINE, BlockIds.SPACE_ENGINE, BlockIds.FUEL_TANK, BlockIds.CREW_CAPSULE,
			BlockIds.SERVICE_MODULE, BlockIds.SOLAR_ARRAY, BlockIds.PARACHUTE_PACK]:
		assert_false(crafted.has(id), "%s is bought with gold" % BlockIds.display_name(id))
	assert_eq(Recipes.problems(Recipes.LIST), [] as Array[String])
	assert_string_contains(RocketParts.craft_words(BlockIds.NOSE_CONE), "Workbench")
	assert_string_contains(RocketParts.craft_words(BlockIds.NOSE_CONE), "Iron")
	assert_eq(RocketParts.craft_words(BlockIds.ROCKET_ENGINE), "")


func test_what_is_missing_from_the_parts_you_own() -> void:
	var on_pad := {BlockIds.ROCKET_ENGINE: 4, BlockIds.FUEL_TANK: 2, BlockIds.CREW_CAPSULE: 1}
	var owned := {BlockIds.ROCKET_ENGINE: 1, BlockIds.FUEL_TANK: 5}
	assert_eq(RocketParts.missing(on_pad, owned), {BlockIds.ROCKET_ENGINE: 3, BlockIds.CREW_CAPSULE: 1})
	assert_eq(RocketParts.missing(on_pad, on_pad), {})
