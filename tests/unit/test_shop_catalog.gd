extends GutTest
## Owner feedback #35 (spec §18): what EasyCraft sells, in one table (ShopCatalog). Parents pay for
## clear value: one-time unlocks at fixed prices, the exact items listed, nothing random, nothing
## consumable, nothing earnable sold, nothing needed to play. Plus's universes come from the ladder.

const PRESSURE: Array[String] = ["hurry", "only today", "limited", "last chance", "sale", "ends", "left",
	"don't miss", "buy now", "ask your", "tell your", "mom", "dad", "streak", "expires", "random", "mystery"]


func test_every_product_is_a_one_time_unlock_at_a_fixed_whole_price() -> void:
	assert_gt(ShopCatalog.ids().size(), 2, "Plus and packs")
	for id in ShopCatalog.ids():
		var p := ShopCatalog.product(id)
		assert_eq(p.kind, ShopCatalog.ONE_TIME, "%s is a one-time unlock" % id)
		assert_typeof(p.price_cents, TYPE_INT, "%s: a fixed price in cents" % id)
		assert_gt(int(p.price_cents), 0, "%s has a price" % id)
		assert_lte(int(p.price_cents), 999, "%s: under ten dollars" % id)
		assert_ne(ShopCatalog.reference_price(id), "", "%s: the price in words" % id)
		assert_string_contains(ShopCatalog.reference_price(id), "US$")


func test_there_is_no_random_consumable_currency_or_timed_kind() -> void:
	assert_eq(ShopCatalog.KINDS, [ShopCatalog.ONE_TIME] as Array[StringName], "one kind only")
	for id in ShopCatalog.ids():
		var p := ShopCatalog.product(id)
		for key: String in p:
			for bad: String in ["random", "chance", "odds", "gold", "coins", "gems", "until", "ends", "discount",
					"sale", "timer", "expires", "limited", "stock", "consumable"]:
				assert_false(key.to_lower().contains(bad), "%s has no '%s' field (%s)" % [id, bad, key])


func test_the_plus_universes_are_every_ladder_universe_after_the_free_ones() -> void:
	assert_eq(ShopCatalog.FREE_UNIVERSES, [&"meadows", &"desert"] as Array[StringName], "Survivor's first universes are free")
	assert_false(ShopCatalog.needs_plus(1), "Green Meadows is free")
	assert_false(ShopCatalog.needs_plus(2), "the Sandstorm Desert is free")
	for u in range(3, UniverseRegistry.size() + 1):
		assert_true(ShopCatalog.needs_plus(u), "universe %d comes with Plus" % u)
	var expected: Array[int] = []
	for u in range(3, UniverseRegistry.size() + 1):
		expected.append(u)
	assert_eq(ShopCatalog.plus_universes(), expected)
	assert_true(ShopCatalog.needs_plus_name(&"dragon"), "a universe added to the ladder later is Plus by the one rule")
	assert_false(ShopCatalog.needs_plus_name(&"desert"))
	assert_false(ShopCatalog.needs_plus(0), "not a universe")
	assert_false(ShopCatalog.needs_plus(-2))


func test_the_free_forever_list_keeps_the_game_complete() -> void:
	for key: StringName in [&"sandbox", &"first_universes", &"bots", &"lan", &"online_friends", &"earned_items"]:
		assert_has(ShopCatalog.FREE_FOREVER, key, "%s stays free" % key)
		assert_ne(ShopCatalog.free_words(key), "", key)
	var first := ShopCatalog.free_words(&"first_universes")
	assert_string_contains(first, "Green Meadows")
	assert_string_contains(first, "Sandstorm Desert")


func test_plus_lists_its_universes_by_name_and_its_set() -> void:
	var lines := "\n".join(ShopCatalog.contents(ShopCatalog.PLUS))
	for u in ShopCatalog.plus_universes():
		assert_string_contains(lines, UniverseRegistry.display_name(u))
	for item in ShopCatalog.items_of(ShopCatalog.PLUS):
		assert_string_contains(lines, AvatarCatalog.display_name(item))
	assert_gte(ShopCatalog.items_of(ShopCatalog.PLUS).size(), 3, "an outfit and a few looks")
	assert_true(ShopCatalog.items_of(ShopCatalog.PLUS).any(func(i: String) -> bool: return i.begins_with("outfit.")),
		"Plus has an outfit")


func test_later_extras_are_never_listed_before_they_work() -> void:
	for key: String in ShopCatalog.PLUS_LATER:
		assert_false(bool(ShopCatalog.PLUS_LATER[key].ready), "%s waits for the owner's server" % key)
		var lines := "\n".join(ShopCatalog.contents(ShopCatalog.PLUS))
		assert_false(lines.contains(str(ShopCatalog.PLUS_LATER[key].name)), "%s is not sold yet" % key)


func test_every_ready_pack_lists_its_exact_items_and_slots_are_not_for_sale() -> void:
	for id in ShopCatalog.for_sale():
		assert_true(bool(ShopCatalog.product(id).ready))
		var items := ShopCatalog.items_of(id)
		assert_gte(items.size(), 3, "%s shows what is inside" % id)
		assert_eq(ShopCatalog.contents(id).size() >= items.size(), true, "%s: every item named" % id)
	for slot: String in [ShopCatalog.PACK_STORYBOOK, ShopCatalog.PACK_GLIDERS]:
		assert_true(ShopCatalog.is_product(slot), "%s has a slot in the table" % slot)
		assert_false(slot in ShopCatalog.for_sale(), "%s is not sold until it exists" % slot)
	assert_has(ShopCatalog.for_sale(), ShopCatalog.PLUS)
	assert_has(ShopCatalog.for_sale(), ShopCatalog.PACK_SKY)
	assert_has(ShopCatalog.for_sale(), ShopCatalog.PACK_OCEAN)


func test_pack_items_exist_only_in_packs_and_never_for_gold() -> void:
	var in_packs := 0
	for id: String in AvatarCatalog.ITEMS:
		var item: Dictionary = AvatarCatalog.ITEMS[id]
		if item.kind == AvatarCatalog.PACK:
			in_packs += 1
			assert_true(ShopCatalog.is_product(str(item.get("pack", ""))), "%s names its pack" % id)
			assert_eq(AvatarCatalog.price(id), 0, "%s has no gold price" % id)
			assert_eq(ShopCatalog.pack_of(id), str(item.pack))
		else:
			assert_false(item.has("pack"), "%s: only pack items name a pack" % id)
			assert_eq(ShopCatalog.pack_of(id), "")
	assert_gte(in_packs, 10)
	var p := ProfileData.new()
	p.survivor_gold = 999_999
	var wings := "wings.phoenix"
	assert_eq(AvatarUnlocks.check_buy(wings, p.cosmetics, p.survivor_gold), AvatarUnlocks.NOT_FOR_SALE, "gold never buys it")
	assert_eq(AvatarUnlocks.buy(p, wings), AvatarUnlocks.NOT_FOR_SALE)
	assert_eq(p.survivor_gold, 999_999)


func test_pack_item_reasons_name_the_pack_without_a_price() -> void:
	for id: String in AvatarCatalog.ITEMS:
		if AvatarCatalog.ITEMS[id].kind != AvatarCatalog.PACK:
			continue
		var reason := AvatarUnlocks.lock_reason(id)
		assert_ne(reason, "", id)
		assert_false(reason.contains("$") or reason.contains("gold") or reason.to_lower().contains("buy"), "%s: %s" % [id, reason])
		assert_string_contains(reason, ShopCatalog.product_name(ShopCatalog.pack_of(id)))


func test_every_new_trail_has_a_look() -> void:
	for n: StringName in AvatarCatalog.items_in(AvatarCatalog.TRAIL):
		if n != &"none":
			assert_true(AvatarTrail.STYLES.has(n), "trail %s has colours" % n)


func test_the_play_store_stays_off_until_the_owner_sets_product_ids() -> void:
	for id in ShopCatalog.ids():
		assert_true(ShopCatalog.PLAY_IDS.has(id), "%s has a Play id slot" % id)
	assert_false(ShopCatalog.play_ready(ShopCatalog.PLAY_IDS), "no ids yet: off")
	var ids := {}
	for id in ShopCatalog.for_sale():
		ids[id] = "easycraft_" + id
	assert_true(ShopCatalog.play_ready(ids), "every product on sale has an id")
	assert_eq(ShopCatalog.from_play_id("easycraft_plus", ids), ShopCatalog.PLUS)
	assert_eq(ShopCatalog.from_play_id("something_else", ids), "")
	ids.erase(ShopCatalog.PACK_SKY)
	assert_false(ShopCatalog.play_ready(ids), "a missing id keeps the store off")


func test_the_words_a_grown_up_reads_have_no_pressure() -> void:
	var texts: Array[String] = []
	for id in ShopCatalog.ids():
		texts.append(ShopCatalog.product_name(id))
		texts.append(str(ShopCatalog.product(id).get("about", "")))
		texts.append_array(ShopCatalog.contents(id))
	for key: StringName in ShopCatalog.FREE_FOREVER:
		texts.append(ShopCatalog.free_words(key))
	for t in texts:
		for bad in PRESSURE:
			assert_false(RegEx.create_from_string("\\b" + bad + "\\b").search(t.to_lower()) != null, "'%s' in \"%s\"" % [bad, t])


## Owner 48 (spec §14.6a): a child's gender look is never for sale. Every boy and girl part is free for
## everyone: in no product, never for gold, never on the wish list, and no product names one.
func test_no_girl_or_boy_part_is_ever_sold() -> void:
	assert_gt(AvatarCatalog.GIRL_PARTS.size(), 10)
	var sold: Array[String] = []
	for product in ShopCatalog.ids():
		sold.append_array(ShopCatalog.items_of(product))
		for line in ShopCatalog.contents(product):
			for id in AvatarCatalog.GIRL_PARTS:
				assert_ne(line, AvatarCatalog.display_name(id), "%s lists %s" % [product, id])
	for id in AvatarCatalog.GIRL_PARTS:
		assert_false(id in sold, "%s is in no product" % id)
		assert_eq(AvatarCatalog.ITEMS[id].kind, AvatarCatalog.FREE, "%s is free" % id)
		assert_false(AvatarCatalog.ITEMS[id].has("pack"), id)
		assert_eq(ShopCatalog.pack_of(id), "", id)
		assert_eq(AvatarCatalog.price(id), 0, "%s has no gold price" % id)
		assert_false(WishList.can_wish(id), "%s never goes on a wish list" % id)
	for id: StringName in AvatarCatalog.PRESETS:
		for field: String in AvatarCatalog.PRESETS[id].look:
			var item := AvatarCatalog.item_id(AvatarLook.FIELDS[field], StringName(AvatarCatalog.PRESETS[id].look[field]))
			assert_true(AvatarCatalog.is_free(item), "the %s look is free parts only: %s" % [id, item])
