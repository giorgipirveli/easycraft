extends GutTest
## Owner feedback #39 (spec §14.2a): universe crystals (items 480-489) and the universe portal cores (page 10).
## A crystal is earned by reaching its universe (every opened universe gives its crystal once), Tilly sells
## copies of the crystals up to the universe she stands in at a fixed price, the Sandbox palette has the ones
## the child reached; placing a crystal puts its universe's portal core, breaking the core gives it back.


func test_one_crystal_per_universe_in_the_allocated_ids() -> void:
	assert_eq(CrystalRules.crystal_of(1), 480, "Green Meadows' crystal is 480")
	assert_eq(CrystalRules.crystal_of(5), 484, "the Dragon Realm's is 484")
	for u in range(1, 6):
		var id := CrystalRules.crystal_of(u)
		assert_between(id, 480, 489)
		assert_eq(CrystalRules.universe_of(id), u)
		assert_true(CrystalRules.is_crystal(id))
		assert_true(ItemIds.is_item(id), "an item a bag holds")
		assert_ne(ItemIds.display_name(id), "", "it has a name")
		assert_true(ItemIds.display_name(id).ends_with("Crystal"))
	assert_eq(CrystalRules.crystal_of(0), -1, "no crystal for a universe that isn't one")
	assert_eq(CrystalRules.crystal_of(99), -1)
	assert_eq(CrystalRules.universe_of(BlockIds.STONE), 0)
	assert_eq(CrystalRules.universe_of(ItemIds.SWORD), 0)
	assert_true(CrystalRules.is_crystal(485), "universe 6, the Glow Caves: the Glow Crystal")
	assert_false(CrystalRules.is_crystal(486), "486-489 are kept for universes 7-10, not made yet")


func test_every_crystal_places_its_universes_core_and_the_core_gives_it_back() -> void:
	var cores := [212, 213, 214, 215, 222, 223]   # universe 6's on page 10 too
	for u in range(1, 7):
		var core: int = cores[u - 1]
		assert_eq(CrystalRules.core_of(u), core, "universe %d's core" % u)
		assert_eq(CrystalRules.core_for_item(CrystalRules.crystal_of(u)), core)
		assert_eq(CrystalRules.universe_of_core(core), u)
		assert_true(CrystalRules.is_universe_core(core))
		assert_true(BlockIds.is_valid(core), "a block the host accepts")
		assert_false(ItemIds.is_item(core), "never an item id")
		assert_eq(BlockLibrary.page_of(core), PortalPage.PAGE, "on page 10")
		assert_eq(GatherRules.drop(core, GatherRules.NONE), CrystalRules.crystal_of(u), "breaking it gives the crystal")
		assert_eq(GatherRules.cost(core), CrystalRules.crystal_of(u), "placing it uses the crystal")
	assert_false(CrystalRules.is_universe_core(BlockIds.PORTAL_CORE), "the linking core is not a universe's")
	assert_eq(CrystalRules.core_for_item(ItemIds.SWORD), -1)


func test_a_profile_is_owed_the_crystal_of_every_universe_it_reached_once() -> void:
	assert_eq(CrystalRules.owed(1, 0, []), [1] as Array[int], "a new child has Green Meadows' crystal to come")
	assert_eq(CrystalRules.owed(3, 0, []), [1, 2, 3] as Array[int])
	assert_eq(CrystalRules.owed(3, 1, []), [2, 3] as Array[int], "only the ones not given yet")
	assert_eq(CrystalRules.owed(3, 3, []), [] as Array[int], "given already: nothing more")
	assert_eq(CrystalRules.owed(5, 5, [5]), [5] as Array[int], "a gift (the Sky Dragon's Dragon Crystal) on top")
	assert_eq(CrystalRules.owed(20, 0, []), [1, 2, 3, 4, 5, 6] as Array[int], "only universes that have a crystal")
	assert_eq(CrystalRules.given_after(3, 1), 3, "the highest given is remembered")
	assert_eq(CrystalRules.given_after(2, 4), 4, "never lowered")


func test_gifts_are_capped_and_cleaned() -> void:
	var gifts: Array[int] = CrystalRules.clean_gifts([5, "x", 99, 2, -1, 5.0])
	assert_eq(gifts, [5, 2, 5] as Array[int], "only universes that have a crystal")
	var many := []
	for i in 50:
		many.append(5)
	assert_eq(CrystalRules.clean_gifts(many).size(), CrystalRules.MAX_GIFTS)
	assert_eq(CrystalRules.clean_gifts(null), [] as Array[int])


func test_earned_is_reached() -> void:
	assert_true(CrystalRules.earned(1, 1), "Green Meadows is always reached")
	assert_true(CrystalRules.earned(3, 4))
	assert_false(CrystalRules.earned(4, 3), "not reached yet")


func test_tilly_sells_copies_of_the_crystals_up_to_her_universe_at_a_fixed_price() -> void:
	assert_eq(CrystalRules.for_sale_in(1), [480] as Array[int])
	assert_eq(CrystalRules.for_sale_in(3), [480, 481, 482] as Array[int])
	assert_eq(ShopRules.price(CrystalRules.crystal_of(1), 1), CrystalRules.PRICE, "a fixed price in Green Meadows")
	assert_eq(ShopRules.price(CrystalRules.crystal_of(2), 3), CrystalRules.PRICE * 4, "× 2^(u-1) like every price")
	assert_eq(ShopRules.price(CrystalRules.crystal_of(4), 3), 0, "not sold before its universe is here")
	assert_true(ShopRules.catalog(ShopRules.HOME, 2).has(CrystalRules.crystal_of(2)))
	assert_false(ShopRules.catalog(ShopRules.HOME, 2).has(CrystalRules.crystal_of(3)))
	assert_eq(ShopRules.sell_price(CrystalRules.crystal_of(1), 1), 0, "Tilly never buys them back")


func test_the_sandbox_palette_has_the_crystals_of_the_universes_reached() -> void:
	assert_eq(CrystalRules.sandbox_crystals(1), [480] as Array[int])
	assert_eq(CrystalRules.sandbox_crystals(3), [480, 481, 482] as Array[int])
	assert_eq(CrystalRules.sandbox_crystals(40), [480, 481, 482, 483, 484, 485] as Array[int])


func test_every_crystal_has_its_universes_swirl_colours_and_an_icon() -> void:
	var seen := {}
	for u in range(1, 6):
		var c := CrystalRules.swirl_colors(u)
		assert_eq(c.size(), 3, "deep, bright and rim")
		assert_false(seen.has(c[1]), "each universe its own colour")
		seen[c[1]] = true
		assert_not_null(BlockIcons.icon(CrystalRules.crystal_of(u)), "an icon drawn in code")
	assert_eq(CrystalRules.swirl_colors(0).size(), 3, "a plain link swirls in the old purple")
