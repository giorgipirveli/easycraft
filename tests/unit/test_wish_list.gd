extends GutTest
## Owner feedback #35 (spec §18.5): a child's wish list reaches the grown-up area. The child marks
## things a grown-up could give (pack items, Plus); the grown-up sees each with what it is and its price;
## the child's own words never carry a price, a buy word or a nudge to ask.

const PRESSURE: Array[String] = ["hurry", "only today", "limited", "last chance", "sale", "don't miss",
	"buy", "ask your", "tell your", "mom", "dad", "parent", "streak", "price", "pay", "money"]


func test_the_round_trip_from_the_editor_to_the_grown_up_area() -> void:
	var p := ProfileData.new()
	assert_true(WishList.toggle(p, "wings.phoenix"), "on the list")
	assert_true(WishList.has(p, "wings.phoenix"))
	WishList.toggle(p, "outfit.frost_ranger")
	var loaded := ProfileData.from_json(p.to_json())
	var rows := WishList.for_grown_up(loaded)
	assert_eq(rows.size(), 2)
	assert_eq(rows[0].id, "wings.phoenix")
	assert_eq(rows[0].product, ShopCatalog.PACK_SKY, "the pack that has it")
	assert_eq(rows[0].name, "Phoenix Wings")
	assert_eq(rows[1].product, ShopCatalog.PLUS, "a Plus item comes with Plus")
	assert_false(WishList.toggle(loaded, "wings.phoenix"), "off the list")
	assert_false(WishList.has(loaded, "wings.phoenix"))


func test_only_things_a_grown_up_can_give_go_on_the_list() -> void:
	var p := ProfileData.new()
	assert_true(WishList.can_wish("wings.phoenix"))
	assert_true(WishList.can_wish(ShopCatalog.PLUS), "Plus itself")
	assert_false(WishList.can_wish("hat.crown"), "gold items are the child's own goal, never sold")
	assert_false(WishList.can_wish("hat.cap"), "free")
	assert_false(WishList.can_wish("outfit.cosmic"), "earned")
	assert_false(WishList.can_wish(ShopCatalog.PACK_STORYBOOK), "not for sale yet")
	assert_false(WishList.can_wish("nope"))
	assert_false(WishList.add(p, "hat.crown"))
	assert_eq(p.wishes, [] as Array[String])


func test_a_wish_that_is_owned_leaves_the_list() -> void:
	var p := ProfileData.new()
	WishList.add(p, "wings.phoenix")
	WishList.add(p, "cape.wave")
	Entitlements.grant(p, ShopCatalog.PACK_SKY)
	WishList.tidy(p)
	assert_eq(p.wishes, ["cape.wave"] as Array[String], "the gift arrived")
	assert_false(WishList.can_wish("wings.phoenix", p), "owned things can't be wished")


func test_the_list_has_a_cap_and_no_repeats() -> void:
	var p := ProfileData.new()
	var wishable: Array[String] = []
	for id: String in AvatarCatalog.ITEMS:
		if WishList.can_wish(id):
			wishable.append(id)
	for id in wishable:
		WishList.add(p, id)
		WishList.add(p, id)
	assert_eq(p.wishes.size(), mini(wishable.size(), WishList.MAX))
	assert_lte(p.wishes.size(), WishList.MAX)


func test_the_grown_up_sees_the_price_the_child_never_does() -> void:
	var p := ProfileData.new()
	WishList.add(p, "wings.phoenix")
	var row: Dictionary = WishList.for_grown_up(p)[0]
	assert_eq(row.price, ShopCatalog.reference_price(ShopCatalog.PACK_SKY))
	assert_eq(WishList.for_grown_up(p, {ShopCatalog.PACK_SKY: "2,49 €"})[0].price, "2,49 €", "the store's own price wins")
	for line in [ShopWords.wished(true), ShopWords.wished(false), ShopWords.WISH, ShopWords.WISHED, ShopWords.WISH_FULL,
			ShopWords.PLUS_CARD, ShopWords.PLUS_ONCE, ShopWords.PLUS_AGAIN, AvatarUnlocks.lock_reason("wings.phoenix")]:
		for bad in PRESSURE:
			if bad == "ask your" and line == ShopWords.PLUS_ONCE:
				continue   # the one calm line, said once (spec §18.3)
			assert_null(RegEx.create_from_string("\\b" + bad + "\\b").search(line.to_lower()), "'%s' in \"%s\"" % [bad, line])
		assert_false(line.contains("$") or line.contains("€") or line.contains("£"), "no currency in \"%s\"" % line)


func test_the_plus_line_is_said_once_then_stays_calm() -> void:
	var p := ProfileData.new()
	assert_eq(ShopWords.plus_line(p), ShopWords.PLUS_ONCE, "the first time")
	assert_has(p.hints_seen, ShopWords.HINT_PLUS)
	assert_eq(ShopWords.plus_line(p), ShopWords.PLUS_AGAIN, "never again")
	assert_eq(ShopWords.plus_line(ProfileData.from_json(p.to_json())), ShopWords.PLUS_AGAIN, "not after a reload either")
	assert_false(ShopWords.PLUS_AGAIN.to_lower().contains("grown-up"), "no asking in the calm line")
	assert_string_contains(ShopWords.PLUS_ONCE, "With EasyCraft Plus")
