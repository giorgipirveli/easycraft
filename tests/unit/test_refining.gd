extends GutTest
## Mining and refining (spec §26.3-26.4): what a deposit gives is worked in real steps, each with a real fact: gravel
## panned for gold, ores smelted in the Clay Oven (it burns coal or wood), salt cleaned and dried, crude oil split at a
## Refinery into kerosene (the rocket's fuel hook) and plastic. Refined things sell at Tilly's for more than their raw
## ingredients would (refining pays) and never more than a loop could mint (Tilly never sells them).


func test_every_refining_step_is_a_recipe_with_a_fact() -> void:
	for id: StringName in RefiningRules.STEPS:
		var r := Recipes.find(id)
		assert_false(r.is_empty(), "%s is in the recipe book" % id)
		assert_eq(r.at, RefiningRules.STEPS[id], "%s is made at %s" % [id, RefiningRules.STEPS[id]])
		assert_ne(RefiningRules.fact(id), "", "%s tells a fact" % id)
		assert_lte(RefiningRules.fact(id).length(), 140, "%s's fact fits a toast" % id)
	assert_eq(RefiningRules.fact(&"planks"), "", "only refining tells facts")
	assert_eq(Recipes.problems(Recipes.LIST), [] as Array[String])
	assert_false(Recipes.has_loop(Recipes.LIST))


func test_the_real_steps() -> void:
	assert_eq(Recipes.find(&"pan_gold").needs, {BlockIds.GOLD_GRAVEL: 4})
	assert_eq(Recipes.find(&"pan_gold").makes, BlockIds.GOLD, "panned gravel gives gold")
	assert_eq(Recipes.find(&"smelt_gold").makes, BlockIds.GOLD)
	assert_eq(Recipes.find(&"smelt_iron").makes, BlockIds.IRON, "banded iron smelts to the game's iron")
	assert_eq(int(Recipes.find(&"smelt_iron").count), 2, "rich ore: 2 iron (the quest's problem)")
	assert_eq(Recipes.find(&"smelt_copper").makes, BlockIds.COPPER)
	assert_eq(Recipes.find(&"smelt_malachite").makes, BlockIds.COPPER)
	assert_eq(Recipes.find(&"table_salt").makes, BlockIds.TABLE_SALT)
	assert_eq(Recipes.find(&"crust_salt").makes, BlockIds.TABLE_SALT)
	assert_eq(Recipes.find(&"kerosene").needs, {BlockIds.CRUDE_OIL: 1})
	assert_eq(Recipes.find(&"kerosene").makes, BlockIds.KEROSENE)
	assert_eq(Recipes.find(&"plastic").makes, BlockIds.PLASTIC)
	assert_eq(Recipes.find(&"refinery").makes, BlockIds.REFINERY, "a Refinery is built at a Workbench")
	assert_eq(RefiningRules.ROCKET_FUEL, BlockIds.KEROSENE, "the rocket's fuel hook")
	assert_eq(Recipes.station_block(Recipes.REFINERY), BlockIds.REFINERY)
	assert_has(Recipes.STATIONS, Recipes.REFINERY)


## Survivor: smelting burns a fuel (coal or wood, like a real furnace); the Refinery works only next to one.
func test_refining_in_a_bag() -> void:
	var inv := Inventory.new()
	inv.add(BlockIds.BANDED_IRON, 3)
	var near := CraftRules.stations(Vector3.ZERO, [] as Array[Vector3i], [Vector3i(1, 0, 0)] as Array[Vector3i], CraftRules.REACH)
	assert_eq(CraftRules.refusal(Recipes.find(&"smelt_iron"), inv, near), "fuel", "no coal to burn")
	inv.add(BlockIds.COAL, 1)
	var r := CraftRules.craft(Recipes.find(&"smelt_iron"), inv, near)
	assert_true(r.ok)
	assert_eq(inv.count(BlockIds.IRON), 2)
	assert_eq(inv.count(BlockIds.COAL), 0, "the coal burned")
	inv.add(BlockIds.CRUDE_OIL, 3)
	assert_eq(CraftRules.refusal(Recipes.find(&"kerosene"), inv, near), "refinery")
	assert_eq(CraftRules.message("refinery", Recipes.find(&"kerosene"), inv), "Stand next to a Refinery!")
	var at_refinery := CraftRules.stations(Vector3.ZERO, [] as Array[Vector3i], [] as Array[Vector3i], CraftRules.REACH,
		[Vector3i(0, 0, 2)] as Array[Vector3i])
	assert_true(at_refinery[Recipes.REFINERY])
	assert_true(CraftRules.craft(Recipes.find(&"kerosene"), inv, at_refinery).ok, "no fuel needed at the Refinery")
	assert_eq(inv.count(BlockIds.KEROSENE), 1)
	inv.add(BlockIds.GOLD_GRAVEL, 4)
	assert_true(CraftRules.craft(Recipes.find(&"pan_gold"), inv, at_refinery).ok, "panning is by hand")
	assert_eq(inv.count(BlockIds.GOLD), 1)
	var said := CraftRules.done_message(Recipes.find(&"pan_gold"))
	assert_string_contains(said, "You made 1 Gold!", "stuff is counted, never \"a Gold\"")
	assert_string_contains(said, "heavy gold stays", "the step's real fact")


func test_refined_things_sell_fairly_and_refining_pays() -> void:
	for id: int in RefiningRules.SELL:
		assert_eq(ShopRules.sell_price(id), RefiningRules.SELL[id], "%s: one price" % BlockIds.display_name(id))
		if id == BlockIds.KEROSENE:   # owner #98: the rocket's fuel without another universe, dearer than it sells back
			assert_gt(ShopRules.price(id, 1), ShopRules.sell_price(id, 1), "no gold loop")
			continue
		assert_false(ShopRules.for_sale(id), "Tilly never sells %s (no gold loop)" % BlockIds.display_name(id))
	for id: int in ProspectPage.FOUND:
		if id != BlockIds.COAL:
			assert_eq(ShopRules.sell_price(id), 0, "%s is refined before it sells" % BlockIds.display_name(id))
	for id: StringName in RefiningRules.STEPS:
		var r := Recipes.find(id)
		if RefiningRules.sell_price(int(r.makes)) > 0 or ShopRules.sell_price(int(r.makes)) > 0:
			assert_gte(RefiningRules.value_added(r), 0, "%s never loses gold" % id)
	assert_gt(RefiningRules.sell_price(BlockIds.KEROSENE), RefiningRules.sell_price(BlockIds.CRUDE_OIL),
		"kerosene sells for more than crude oil")
	assert_gt(RefiningRules.sell_price(BlockIds.KEROSENE), RefiningRules.sell_price(BlockIds.PLASTIC) * 3 / 2,
		"a crude drum is worth most as kerosene (the rocket's fuel)")
	assert_gt(ShopRules.price(BlockIds.REFINERY), 0, "Tilly sells a Refinery")


## A rich deposit is worth a few hundred gold in Survivor: about a day of learning, never more than the School pays in a
## few days (spec §25.1: learning is how gold is earned).
func test_a_deposit_is_worth_about_a_day_of_learning() -> void:
	var shape := MeadowsBiomeShape.new(12345)
	var rules := DepositRules.for_world(12345, shape, SecretRules.new(12345, shape))
	for kind in [DepositKinds.GOLD, DepositKinds.IRON, DepositKinds.COAL]:
		var d := rules.nearest(kind, Vector3.ZERO)
		var cells := DepositRules.cells_of(d)
		var worth := 0.0
		for p: Vector3i in cells:
			worth += _gold_per_block(int(cells[p]))
		assert_between(worth, 40.0, 1400.0, "%s is worth %d gold refined and sold" % [d.id, worth])
	var desert := DepositRules.for_world(12345, DesertShape.new(12345))
	for kind in [DepositKinds.COPPER, DepositKinds.SALT]:
		var d := desert.nearest(kind, Vector3.ZERO)
		var cells := DepositRules.cells_of(d)
		var worth := 0.0
		for p: Vector3i in cells:
			worth += _gold_per_block(int(cells[p]))
		assert_between(worth, 40.0, 1400.0, "%s is worth %d gold refined and sold" % [d.id, worth])
	var oil := DepositRules.OIL_DRUMS * RefiningRules.sell_price(BlockIds.KEROSENE)
	assert_between(oil, 40, 1400, "an oil well's drums as kerosene")


## Gold a found block is worth once refined and sold (the recipe's result per ingredient).
func _gold_per_block(id: int) -> float:
	for r: Dictionary in Recipes.LIST:
		if RefiningRules.is_refining(r.id) and (r.needs as Dictionary).has(id) and (r.needs as Dictionary).size() == 1:
			return float(ShopRules.sell_price(int(r.makes)) * int(r.count)) / int(r.needs[id])
	return float(ShopRules.sell_price(id))
