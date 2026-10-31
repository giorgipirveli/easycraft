extends GutTest
## M3 Task 5 (spec §14.1): travelling to another universe's world through a portal or the portal hub.
## The child's bag and hotbar come along (tools keep their tiers: a cosmic sword stays a cosmic sword),
## nothing is ever copied or lost, and the child arrives by the new world's spawn. A universe's world is
## made the first time someone travels there, with the same difficulty as the world they came from.

const KEY := "Mia"


func _bag(entries: Array) -> Array:
	return Inventory.from_save(entries).to_save()


func _total(a: Array, b: Array, id: int) -> int:
	return Inventory.from_save(a).count(id) + Inventory.from_save(b).count(id)


func test_the_bag_and_hotbar_come_along_and_nothing_stays_behind() -> void:
	var from := WorldMeta.new_random()
	from.inventories[KEY] = _bag([[BlockIds.STONE, 3]])   # an old save of the bag; the live one wins
	var to := UniverseRules.arrival_meta(null, 2, DifficultyRules.BRAVE)
	var bag := _bag([[ItemIds.SWORD_COSMIC, 1], [BlockIds.PLANKS, 40]])
	var hotbar: Array[int] = [ItemIds.SWORD_COSMIC, BlockIds.PLANKS, BlockIds.STONE, BlockIds.DIRT, BlockIds.LOG,
		BlockIds.SAND, BlockIds.GLASS, BlockIds.BRICK, ItemIds.PICKAXE]
	UniverseRules.carry(from, to, KEY, bag, hotbar, 1)
	var arrived := Inventory.from_save(to.inventories[KEY])
	assert_eq(arrived.count(ItemIds.SWORD_COSMIC), 1, "the cosmic sword stays a cosmic sword")
	assert_eq(arrived.count(BlockIds.PLANKS), 40)
	assert_eq(from.inventories[KEY], [], "nothing is left behind to be used twice")
	assert_eq(to.hotbar, hotbar)
	assert_eq(to.selected_slot, 1)


func test_a_world_visited_before_adds_the_bag_to_what_waits_there() -> void:
	var from := WorldMeta.new_random()
	var to := WorldMeta.new_random()
	to.universe = 2
	to.inventories[KEY] = _bag([[BlockIds.PLANKS, 5], [BlockIds.SAND, 9]])
	var bag := _bag([[BlockIds.PLANKS, 40]])
	UniverseRules.carry(from, to, KEY, bag, WorldMeta.new().hotbar, 0)
	var arrived := Inventory.from_save(to.inventories[KEY])
	assert_eq(arrived.count(BlockIds.PLANKS), 45)
	assert_eq(arrived.count(BlockIds.SAND), 9)


func test_what_does_not_fit_stays_behind_never_lost() -> void:
	var from := WorldMeta.new_random()
	var to := WorldMeta.new_random()
	to.inventories[KEY] = _bag([[BlockIds.DIRT, 900]])
	var bag := _bag([[BlockIds.DIRT, 300], [BlockIds.LOG, 2]])
	UniverseRules.carry(from, to, KEY, bag, WorldMeta.new().hotbar, 0)
	assert_eq(Inventory.from_save(to.inventories[KEY]).count(BlockIds.DIRT), Inventory.MAX_COUNT)
	assert_eq(Inventory.from_save(from.inventories[KEY]).count(BlockIds.DIRT), 201, "waits in the old world")
	assert_eq(_total(from.inventories[KEY], to.inventories[KEY], BlockIds.DIRT), 1200, "not one lost")
	assert_eq(Inventory.from_save(from.inventories[KEY]).count(BlockIds.LOG), 0)


func test_other_players_bags_are_left_alone() -> void:
	var from := WorldMeta.new_random()
	from.inventories["Leo"] = _bag([[BlockIds.BRICK, 7]])
	var to := WorldMeta.new_random()
	to.inventories["Leo"] = _bag([[BlockIds.GLASS, 2]])
	UniverseRules.carry(from, to, KEY, _bag([[BlockIds.PLANKS, 1]]), WorldMeta.new().hotbar, 0)
	assert_eq(from.inventories["Leo"], _bag([[BlockIds.BRICK, 7]]))
	assert_eq(to.inventories["Leo"], _bag([[BlockIds.GLASS, 2]]))


func test_the_child_arrives_by_the_spawn_of_the_new_world() -> void:
	var to := WorldMeta.new_random()
	to.player_pos = Vector3(500, 60, -300)   # where they left it last time
	var arrived := UniverseRules.arrival_meta(to, 2, DifficultyRules.NORMAL)
	assert_same(arrived, to)
	assert_false(arrived.has_player_pos(), "by the spawn and its stone circle")


func test_a_new_universe_world_gives_the_starter_kit_on_top_of_the_bag() -> void:
	var from := WorldMeta.new_random()
	var to := UniverseRules.arrival_meta(null, 2, DifficultyRules.NORMAL, KEY)
	UniverseRules.carry(from, to, KEY, _bag([[BlockIds.PLANKS, 40]]), WorldMeta.new().hotbar, 0)
	var arrived := Inventory.from_save(to.inventories[KEY])
	var kit := Inventory.starter_kit()
	assert_eq(arrived.count(BlockIds.PLANKS), 40 + kit.count(BlockIds.PLANKS), "M2 §12.1: every new Survivor world")
	assert_eq(arrived.count(ItemIds.SWORD), kit.count(ItemIds.SWORD))
	var old := WorldMeta.new_random()
	old.inventories[KEY] = _bag([[BlockIds.SAND, 3]])
	assert_eq(UniverseRules.arrival_meta(old, 2, DifficultyRules.NORMAL, KEY).inventories[KEY], _bag([[BlockIds.SAND, 3]]),
		"a world visited before gives nothing more")


func test_a_new_universe_world_takes_the_difficulty_it_came_from() -> void:
	var m := UniverseRules.arrival_meta(null, 3, DifficultyRules.COZY)
	assert_eq(m.mode, ModeRules.SURVIVOR)
	assert_eq(m.universe, 3)
	assert_eq(m.difficulty, DifficultyRules.COZY)
	assert_false(m.has_player_pos())
	var old := WorldMeta.new_random()
	old.difficulty = DifficultyRules.BRAVE
	assert_eq(UniverseRules.arrival_meta(old, 3, DifficultyRules.COZY).difficulty, DifficultyRules.BRAVE,
		"a world keeps the difficulty it was made with")
