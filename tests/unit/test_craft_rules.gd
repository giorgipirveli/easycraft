extends GutTest
## Crafting's rules (spec §12.19): a craft is all or nothing and takes and gives exactly; by hand anywhere,
## the rest next to a Crafting Table or a Furnace (within 4 blocks of the eyes); furnace recipes burn one
## fuel (coal, else a log; never the recipe's own result); tools are one of each; counts cap at 999.

const ALL_STATIONS := {Recipes.HAND: true, Recipes.TABLE: true, Recipes.FURNACE: true}
const HAND_ONLY := {Recipes.HAND: true, Recipes.TABLE: false, Recipes.FURNACE: false}


func _inv(items: Dictionary) -> Inventory:
	var inv := Inventory.new()
	for id: int in items:
		inv.add(id, items[id])
	return inv


func test_planks_by_hand_take_one_log_and_give_four() -> void:
	var inv := _inv({BlockIds.LOG: 3})
	var r := CraftRules.craft(Recipes.find(&"planks"), inv, HAND_ONLY)
	assert_true(r.ok)
	assert_eq([r.id, r.count], [BlockIds.PLANKS, 4])
	assert_eq(inv.count(BlockIds.LOG), 2)
	assert_eq(inv.count(BlockIds.PLANKS), 4)


func test_a_sword_at_the_table_takes_exactly_its_ingredients() -> void:
	var inv := _inv({BlockIds.PLANKS: 5, ItemIds.STICK: 3, BlockIds.DIRT: 7})
	var r := CraftRules.craft(Recipes.find(&"sword"), inv, ALL_STATIONS)
	assert_true(r.ok)
	assert_eq(inv.count(BlockIds.PLANKS), 3)
	assert_eq(inv.count(ItemIds.STICK), 2)
	assert_eq(inv.count(BlockIds.DIRT), 7, "nothing else is touched")
	assert_eq(inv.count(ItemIds.SWORD), 1)


func test_missing_ingredients_change_nothing_and_say_what_is_missing() -> void:
	var inv := _inv({BlockIds.STONE: 1, ItemIds.STICK: 1})
	var before := inv.to_save()
	var recipe := Recipes.find(&"pickaxe_stone")
	var r := CraftRules.craft(recipe, inv, ALL_STATIONS)
	assert_false(r.ok)
	assert_eq(r.error, "missing")
	assert_eq(inv.to_save(), before, "all or nothing")
	assert_eq(CraftRules.missing(recipe, inv), {BlockIds.STONE: 2, ItemIds.STICK: 1})
	assert_eq(CraftRules.message("missing", recipe, inv), "You need 2 more Stone!")
	assert_eq(CraftRules.message("missing", Recipes.find(&"sword"), _inv({BlockIds.PLANKS: 2})), "You need 1 more Stick!")


func test_the_table_and_the_furnace_must_be_near() -> void:
	var inv := _inv({BlockIds.PLANKS: 9, ItemIds.STICK: 9, BlockIds.SAND: 4, BlockIds.COAL: 2, BlockIds.STONE: 8})
	var r := CraftRules.craft(Recipes.find(&"sword"), inv, HAND_ONLY)
	assert_eq(r.error, "table")
	assert_eq(CraftRules.message("table", Recipes.find(&"sword"), inv), "Stand next to a Workbench!")
	r = CraftRules.craft(Recipes.find(&"glass"), inv, {Recipes.HAND: true, Recipes.TABLE: true, Recipes.FURNACE: false})
	assert_eq(r.error, "furnace", "a table is no furnace")
	assert_eq(CraftRules.message("furnace", Recipes.find(&"glass"), inv), "Stand next to a Clay Oven!")
	assert_eq(inv.count(BlockIds.SAND), 4)
	assert_true(CraftRules.craft(Recipes.find(&"crafting_table"), inv, HAND_ONLY).ok, "the table itself is made by hand")


func test_the_furnace_burns_coal_first_then_a_log() -> void:
	var inv := _inv({BlockIds.SAND: 8, BlockIds.COAL: 1, BlockIds.LOG: 5})
	var r := CraftRules.craft(Recipes.find(&"glass"), inv, ALL_STATIONS)
	assert_true(r.ok)
	assert_eq(r.fuel, BlockIds.COAL)
	assert_eq(inv.count(BlockIds.COAL), 0)
	assert_eq(inv.count(BlockIds.GLASS), 4)
	r = CraftRules.craft(Recipes.find(&"glass"), inv, ALL_STATIONS)
	assert_true(r.ok)
	assert_eq(r.fuel, BlockIds.LOG)
	assert_eq(inv.count(BlockIds.LOG), 4)
	assert_eq(inv.count(BlockIds.SAND), 0)


func test_no_fuel_no_fire() -> void:
	var inv := _inv({BlockIds.SAND: 4})
	var r := CraftRules.craft(Recipes.find(&"glass"), inv, ALL_STATIONS)
	assert_eq(r.error, "fuel")
	assert_eq(inv.count(BlockIds.SAND), 4)
	assert_eq(CraftRules.message("fuel", Recipes.find(&"glass"), inv), "You need coal or a log to burn!")


## Charcoal is made from logs: its fire is a log, never the coal it makes (and never the logs it needs).
func test_charcoal_burns_a_log_beyond_its_own() -> void:
	var recipe := Recipes.find(&"charcoal")
	var need := int((recipe.needs as Dictionary)[BlockIds.LOG])
	var inv := _inv({BlockIds.LOG: need, BlockIds.COAL: 3})
	assert_eq(CraftRules.refusal(recipe, inv, ALL_STATIONS), "fuel", "coal never burns to make coal")
	inv.add(BlockIds.LOG, 1)
	var r := CraftRules.craft(recipe, inv, ALL_STATIONS)
	assert_true(r.ok)
	assert_eq(r.fuel, BlockIds.LOG)
	assert_eq(inv.count(BlockIds.LOG), 0)
	assert_eq(inv.count(BlockIds.COAL), 4)


func test_a_log_needed_as_an_ingredient_is_not_burnt_too() -> void:
	assert_eq(CraftRules.fuel_for(Recipes.find(&"glass"), _inv({BlockIds.LOG: 1})), BlockIds.LOG)
	assert_eq(CraftRules.fuel_for(Recipes.find(&"sword"), _inv({})), BlockIds.AIR, "the table needs no fire")
	assert_eq(CraftRules.fuel_for(Recipes.find(&"glass"), _inv({})), -1)


func test_one_of_each_tool_like_tillys() -> void:
	var inv := _inv({BlockIds.IRON: 9, ItemIds.STICK: 9, ItemIds.SWORD_IRON: 1})
	var r := CraftRules.craft(Recipes.find(&"sword_iron"), inv, ALL_STATIONS)
	assert_eq(r.error, "have_it")
	assert_eq(inv.count(BlockIds.IRON), 9)
	assert_eq(CraftRules.message("have_it", Recipes.find(&"sword_iron"), inv), "You already have one!")
	assert_true(CraftRules.craft(Recipes.find(&"pickaxe_iron"), inv, ALL_STATIONS).ok, "another tool is fine")


func test_a_full_stack_refuses() -> void:
	var inv := _inv({BlockIds.LOG: 1, BlockIds.PLANKS: 997})
	assert_eq(CraftRules.refusal(Recipes.find(&"planks"), inv, HAND_ONLY), "full")
	assert_eq(inv.count(BlockIds.LOG), 1)
	assert_eq(CraftRules.message("full", Recipes.find(&"planks"), inv), "Your bag is full of those!")


func test_an_unknown_recipe_is_refused() -> void:
	assert_eq(CraftRules.refusal({}, _inv({}), ALL_STATIONS), "unknown")
	assert_false(CraftRules.craft({}, _inv({}), ALL_STATIONS).ok)


func test_the_words_when_it_works() -> void:
	assert_eq(CraftRules.done_message(Recipes.find(&"planks")), "You made 4 Planks!")
	assert_eq(CraftRules.done_message(Recipes.find(&"sword_stone")), "You made a Stone Sword!")
	assert_eq(CraftRules.done_message(Recipes.find(&"lantern")), "You made a Lantern!")
	assert_eq(CraftRules.done_message(Recipes.find(&"doors")), "You made 2 Doors!")
	assert_eq(CraftRules.have_need(3, 2), "3/2")


## "Next to" = the block within 4 of the eyes (its nearest point), the host a little more for lag.
func test_a_station_within_four_blocks_of_the_eyes() -> void:
	var eye := Vector3(0.5, 1.6, 0.5)
	assert_true(CraftRules.in_reach(eye, Vector3i(3, 1, 0), CraftRules.REACH))
	assert_true(CraftRules.in_reach(eye, Vector3i(4, 1, 0), CraftRules.REACH), "3.5 to its near face")
	assert_false(CraftRules.in_reach(eye, Vector3i(5, 1, 0), CraftRules.REACH))
	assert_true(CraftRules.in_reach(eye, Vector3i(5, 1, 0), CraftRules.HOST_REACH))
	assert_gt(CraftRules.HOST_REACH, CraftRules.REACH)
	var st := CraftRules.stations(eye, [Vector3i(2, 0, 2)] as Array[Vector3i], [Vector3i(9, 0, 0)] as Array[Vector3i], CraftRules.REACH)
	assert_eq(st, {Recipes.HAND: true, Recipes.TABLE: true, Recipes.FURNACE: false, Recipes.REFINERY: false,
		Recipes.MELTER: false, Recipes.OXYGEN_MAKER: false, Recipes.SOLAR_OVEN: false})   # spec §26.5: the machines


func test_the_box_to_search_covers_the_host_reach() -> void:
	var eye := Vector3(10.2, 20.6, -3.4)
	var box := CraftRules.search_box(eye)
	var origin: Vector3i = box[0]
	var size: Vector3i = box[1]
	var r := ceili(CraftRules.HOST_REACH)
	assert_eq(origin, Vector3i(eye.floor()) - Vector3i(r, r, r))
	assert_eq(size, Vector3i(2 * r + 1, 2 * r + 1, 2 * r + 1))


## The picture book: what you can make now first (in the table's order), then the rest.
func test_the_book_shows_what_can_be_made_first() -> void:
	var inv := _inv({BlockIds.LOG: 1, BlockIds.PLANKS: 2})
	var book := CraftRules.book(inv, HAND_ONLY)
	assert_eq(book.size(), Recipes.LIST.size())
	assert_eq(book[0].id, &"planks")
	assert_eq(book[1].id, &"sticks")
	assert_true(CraftRules.can_make(book[1], inv, HAND_ONLY))
	assert_false(CraftRules.can_make(book[2], inv, HAND_ONLY))
	var order: Array[StringName] = []
	for r: Dictionary in book.slice(2):
		order.append(r.id)
	var rest: Array[StringName] = []
	for r: Dictionary in Recipes.LIST:
		if not [&"planks", &"sticks"].has(r.id):
			rest.append(r.id)
	assert_eq(order, rest, "the others keep the table's order")
