extends GutTest
## Owner #98, bug 2: a friend's ROCKET PART present said it waits at the Launch Site but reached only the Sandbox's
## rockets (MissionData), never a Survivor bag. Now it goes where the Gold Shop's parts go (RocketParts.grant): the
## Sandbox's rockets and the backpack for the next Survivor world, and its words say so.


func test_a_rocket_part_present_reaches_the_sandbox_and_the_next_survivor_bag() -> void:
	var p := ProfileData.new()
	var words := FriendPresents.open(p, "rocket_part")
	var part := FriendPresents.ROCKET_PART_BLOCK
	assert_eq(int(p.missions.parts.get(part, 0)), 1, "for the Sandbox's rockets")
	assert_eq(int(p.backpack.get(part, 0)), 1, "and in the backpack")
	assert_string_contains(words, "Survivor", "the words say where it waits")
	var bag := Inventory.new()
	SpendRules.unpack_backpack(p, bag)
	assert_eq(bag.count(part), 1, "the next Survivor world's bag has it")


## Owner #98, bug 1: a part bought on the Gold Shop's ROCKET PARTS shelf was gold spent and a part a Survivor world never
## saw. Now it also waits in the backpack, and the shop says where it went.
func test_a_part_bought_in_the_gold_shop_reaches_the_next_survivor_bag() -> void:
	SpendRules.clear_extra()
	RocketParts.register_shelf()
	var p := ProfileData.new()
	var tank := BlockIds.FUEL_TANK
	p.survivor_gold = RocketParts.price(tank) * 2
	assert_eq(SpendRules.buy(p, "part:%d" % tank), SpendRules.OK)
	assert_eq(SpendRules.buy(p, "part:%d" % tank), SpendRules.OK)
	assert_eq(int(p.missions.parts.get(tank, 0)), 2, "the Sandbox's rockets")
	assert_eq(int(p.backpack.get(tank, 0)), 2, "the backpack")
	var bag := Inventory.new()
	SpendRules.unpack_backpack(p, bag)
	assert_eq(bag.count(tank), 2, "a Survivor world's bag gets both")
	SpendRules.clear_extra()
