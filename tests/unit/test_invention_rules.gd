extends GutTest
## Owner #78 (spec §21e): the gates. In Survivor, flight is invented step by step in history's order, each at a
## Workbench from real materials, for a little gold or free once its School unit is mastered; each opens what it can do
## (the kite a lift on a windy hill, the balloon slow flying, the glider the glide, the plane fast flying, the jet the
## fastest) and the rocket opens the Launch Site's missions. Where flying is free (the Sandbox) everything stays open.

var inv: Inventory
var data: InventionData


func before_each() -> void:
	inv = Inventory.new()
	data = InventionData.new()


func _stock(id: StringName) -> void:
	for n: Array in InventionLine.entry(id).needs:
		inv.add(int(InventionLine.MATERIALS[n[0]].ids[0]), int(n[1]))


func test_the_next_is_the_first_not_invented() -> void:
	assert_eq(InventionRules.next(data), InventionLine.KITE)
	data.add(InventionLine.KITE)
	assert_eq(InventionRules.next(data), InventionLine.BALLOON)
	for id in InventionLine.ORDER:
		data.add(id)
	assert_eq(InventionRules.next(data), &"", "all invented")


func test_one_opens_the_next() -> void:
	assert_true(InventionRules.may_make(InventionLine.KITE, data))
	assert_false(InventionRules.may_make(InventionLine.BALLOON, data))
	_stock(InventionLine.BALLOON)
	assert_eq(InventionRules.refusal(InventionLine.BALLOON, data, inv, true, 1000, false), "earlier")
	assert_string_contains(InventionRules.message("earlier", InventionLine.BALLOON, inv), "The Kite")
	data.add(InventionLine.KITE)
	assert_eq(InventionRules.refusal(InventionLine.BALLOON, data, inv, true, 1000, false), "")
	assert_eq(InventionRules.refusal(InventionLine.KITE, data, inv, true, 1000, false), "known")
	assert_eq(InventionRules.refusal(&"hoverboard", data, inv, true, 1000, false), "unknown")


func test_it_is_made_at_a_workbench_from_real_materials() -> void:
	assert_eq(InventionRules.refusal(InventionLine.KITE, data, inv, false, 1000, false), "workbench")
	assert_eq(InventionRules.message("workbench", InventionLine.KITE, inv), "Stand next to a Workbench to make it!")
	assert_eq(InventionRules.refusal(InventionLine.KITE, data, inv, true, 1000, false), "missing")
	assert_eq(InventionRules.message("missing", InventionLine.KITE, inv), "You need 4 more Sticks!")
	inv.add(ItemIds.STICK, 4)
	inv.add(BlockIds.RED, 1)
	inv.add(BlockIds.SAIL, 1)
	assert_eq(InventionRules.have(&"cloth", inv), 2, "wool and sail cloth are both cloth")
	assert_eq(InventionRules.message("missing", InventionLine.KITE, inv), "You need 1 more Cloth!")
	inv.add(BlockIds.BLUE, 5)
	assert_eq(InventionRules.refusal(InventionLine.KITE, data, inv, true, 1000, false), "")


func test_it_costs_a_little_gold_or_is_free_once_its_unit_is_mastered() -> void:
	_stock(InventionLine.KITE)
	assert_eq(InventionRules.price(InventionLine.KITE, false), 10)
	assert_eq(InventionRules.price(InventionLine.KITE, true), 0, "learning it in the School makes it free")
	assert_eq(InventionRules.refusal(InventionLine.KITE, data, inv, true, 9, false), "gold")
	assert_eq(InventionRules.message("gold", InventionLine.KITE, inv), "You need 10 gold to make it!")
	assert_eq(InventionRules.refusal(InventionLine.KITE, data, inv, true, 0, true), "", "mastered: free")
	assert_string_contains(InventionRules.price_words(InventionLine.KITE, false), "10 gold")
	assert_string_contains(InventionRules.price_words(InventionLine.KITE, false), "Pushes, pulls and friction")
	assert_eq(InventionRules.price_words(InventionLine.KITE, true), "Free: you mastered Pushes, pulls and friction!")


func test_making_it_takes_exactly_what_it_needs() -> void:
	inv.add(ItemIds.STICK, 6)
	inv.add(BlockIds.SAIL, 1)
	inv.add(BlockIds.RED, 5)
	assert_true(InventionRules.take(InventionLine.KITE, inv))
	assert_eq(inv.count(ItemIds.STICK), 2)
	assert_eq(inv.count(BlockIds.SAIL), 0, "sail cloth first")
	assert_eq(inv.count(BlockIds.RED), 3)
	var poor := Inventory.new()
	poor.add(ItemIds.STICK, 1)
	assert_false(InventionRules.take(InventionLine.KITE, poor), "all or nothing")
	assert_eq(poor.count(ItemIds.STICK), 1)


func test_survivor_flies_only_what_it_invented() -> void:
	var earth := InventionRules.EARTH
	assert_eq(InventionRules.fly_refusal(true, data, FlightCrafts.Craft.NONE, earth), "", "the Sandbox flies free")
	assert_string_contains(InventionRules.fly_refusal(false, data, FlightCrafts.Craft.NONE, earth), "Invent")
	assert_eq(InventionRules.take_off_craft(false, data, FlightCrafts.Craft.NONE), FlightCrafts.Craft.NONE)
	data.add(InventionLine.KITE)
	assert_eq(InventionRules.take_off_craft(false, data, FlightCrafts.Craft.NONE), FlightCrafts.Craft.KITE)
	data.add(InventionLine.BALLOON)
	data.add(InventionLine.GLIDER)
	data.add(InventionLine.PLANE)
	assert_eq(InventionRules.take_off_craft(false, data, FlightCrafts.Craft.NONE), FlightCrafts.Craft.PLANE, "the newest")
	assert_eq(InventionRules.take_off_craft(false, data, FlightCrafts.Craft.BALLOON), FlightCrafts.Craft.BALLOON, "picked")
	assert_eq(InventionRules.take_off_craft(false, data, FlightCrafts.Craft.JET), FlightCrafts.Craft.PLANE,
		"a machine not invented is never flown")
	assert_eq(InventionRules.fly_refusal(false, data, FlightCrafts.Craft.PLANE, earth), "")
	assert_eq(InventionRules.take_off_craft(true, InventionData.new(), FlightCrafts.Craft.NONE), FlightCrafts.Craft.NONE,
		"the Sandbox's classic flying")
	assert_eq(InventionRules.take_off_craft(true, InventionData.new(), FlightCrafts.Craft.JET), FlightCrafts.Craft.JET,
		"the Sandbox tries anything")


func test_the_plane_and_the_jet_burn_fuel_the_balloon_does_not() -> void:
	assert_eq(InventionRules.fuel_factor(FlightCrafts.Craft.BALLOON), 0)
	assert_eq(InventionRules.fuel_factor(FlightCrafts.Craft.KITE), 0)
	assert_eq(InventionRules.fuel_factor(FlightCrafts.Craft.PLANE), 1)
	assert_eq(InventionRules.fuel_factor(FlightCrafts.Craft.JET), 2)
	assert_eq(InventionRules.fuel_factor(FlightCrafts.Craft.NONE), 1, "the classic flight costs what it cost")
	assert_true(InventionRules.can_pay_take_off(false, FlightCrafts.Craft.BALLOON, 0, 1))
	assert_false(InventionRules.can_pay_take_off(false, FlightCrafts.Craft.JET, 1, 1))
	assert_true(InventionRules.can_pay_take_off(false, FlightCrafts.Craft.JET, 2, 1))
	assert_true(InventionRules.can_pay_take_off(true, FlightCrafts.Craft.JET, 0, 1), "free flying")
	assert_string_contains(InventionRules.fuel_words(FlightCrafts.Craft.JET, 1), "20 gold a minute")


func test_the_rocket_opens_the_missions_in_survivor_only() -> void:
	assert_true(InventionRules.missions_open(true, data), "the Sandbox")
	assert_false(InventionRules.missions_open(false, data))
	assert_string_contains(InventionRules.MISSIONS_WORDS, "Invent the rocket")
	for id in InventionLine.ORDER:
		data.add(id)
	assert_true(InventionRules.missions_open(false, data))


func test_no_air_no_wings() -> void:
	assert_eq(InventionRules.air(1), InventionRules.EARTH)
	assert_eq(InventionRules.air(SpaceRules.MOON), InventionRules.NO_AIR)
	assert_eq(InventionRules.air(SpaceRules.MARS), InventionRules.THIN_AIR)
	assert_eq(InventionRules.air(SpaceRules.TITAN), InventionRules.THICK_AIR)
	assert_eq(InventionRules.air(SpaceRules.BOING), InventionRules.EARTH, "our own planets have air")
	for id in InventionLine.ORDER:
		data.add(id)
	assert_string_contains(InventionRules.fly_refusal(false, data, FlightCrafts.Craft.BALLOON, InventionRules.NO_AIR),
		"no air")
	assert_ne(InventionRules.fly_refusal(false, data, FlightCrafts.Craft.PLANE, InventionRules.THIN_AIR), "")
	assert_eq(InventionRules.fly_refusal(false, data, FlightCrafts.Craft.PLANE, InventionRules.THICK_AIR), "")
	assert_eq(InventionRules.fly_refusal(true, data, FlightCrafts.Craft.NONE, InventionRules.NO_AIR), "",
		"the Sandbox's own flying is magic")
	assert_ne(InventionRules.fly_refusal(true, data, FlightCrafts.Craft.KITE, InventionRules.NO_AIR), "",
		"a kite never flies without air")


func test_the_try_it_pays_once() -> void:
	assert_eq(InventionRules.try_gold(InventionLine.KITE, data), EarnRules.INVENT_TRY_GOLD)
	data.mark_tried(InventionLine.KITE)
	assert_eq(InventionRules.try_gold(InventionLine.KITE, data), 0)
	assert_true(EarnRules.TABLE.any(func(r: Dictionary) -> bool: return r.id == "invent_try"), "on the How to earn list")
