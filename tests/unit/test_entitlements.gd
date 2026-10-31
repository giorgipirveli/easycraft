extends GutTest
## Owner feedback #35 (spec §18): what a purchase opens (Entitlements) and how it is kept in the profile.
## Locked content opens after a purchase and stays open (a save and a load, a backup merge); old
## profiles load; the free content never needs anything.


func _reload(p: ProfileData) -> ProfileData:
	return ProfileData.from_json(p.to_json())


func test_the_free_universes_are_open_without_anything() -> void:
	assert_true(Entitlements.universe_open(1, []))
	assert_true(Entitlements.universe_open(2, []))
	for u in ShopCatalog.plus_universes():
		assert_false(Entitlements.universe_open(u, []), "universe %d waits for Plus" % u)
		assert_true(Entitlements.universe_open(u, [ShopCatalog.PLUS]), "universe %d opens with Plus" % u)
		assert_false(Entitlements.universe_open(u, [ShopCatalog.PACK_SKY]), "a pack is not Plus")


func test_granting_plus_records_it_once_and_gives_its_set() -> void:
	var p := ProfileData.new()
	var got := Entitlements.grant(p, ShopCatalog.PLUS)
	assert_eq(p.purchases, [ShopCatalog.PLUS] as Array[String])
	assert_eq(got, ShopCatalog.items_of(ShopCatalog.PLUS), "the new items, for a 'New!' line")
	for item in ShopCatalog.items_of(ShopCatalog.PLUS):
		assert_true(AvatarUnlocks.is_owned(item, p.cosmetics), item)
	assert_eq(Entitlements.grant(p, ShopCatalog.PLUS), [] as Array[String], "twice changes nothing")
	assert_eq(p.purchases.size(), 1)
	assert_true(Entitlements.owns(p.purchases, ShopCatalog.PLUS))


func test_a_pack_gives_exactly_its_items() -> void:
	var p := ProfileData.new()
	Entitlements.grant(p, ShopCatalog.PACK_SKY)
	var owned: Array[String] = []
	for id: String in AvatarCatalog.ITEMS:
		if AvatarCatalog.ITEMS[id].kind == AvatarCatalog.PACK and AvatarUnlocks.is_owned(id, p.cosmetics):
			owned.append(id)
	assert_eq(owned, ShopCatalog.items_of(ShopCatalog.PACK_SKY))
	assert_false(Entitlements.universe_open(3, p.purchases))


func test_unknown_or_unready_products_are_never_granted() -> void:
	var p := ProfileData.new()
	assert_eq(Entitlements.grant(p, "gold_1000"), [] as Array[String])
	assert_eq(Entitlements.grant(p, ""), [] as Array[String])
	assert_eq(p.purchases, [] as Array[String])


func test_locked_content_opens_after_a_purchase_and_stays_open_through_a_save() -> void:
	var p := ProfileData.new()
	assert_false(Entitlements.universe_open(3, p.purchases))
	Entitlements.grant(p, ShopCatalog.PLUS)
	var loaded := _reload(_reload(p))
	assert_true(Entitlements.universe_open(3, loaded.purchases), "open after a save and a load")
	assert_true(AvatarUnlocks.is_owned("cape.aurora", loaded.cosmetics))
	loaded.avatar.cape = &"aurora"
	assert_eq(_reload(loaded).avatar.cape, &"aurora", "worn and kept")


func test_old_profiles_load_with_nothing_bought_and_no_wishes() -> void:
	var old := '{"version": 1, "username": "Kit", "age_band": "under_13", "survivor_gold": 300, "universe_unlocked": 3, "cosmetics": ["hat.crown"]}'
	var p := ProfileData.from_json(old)
	assert_eq(p.purchases, [] as Array[String])
	assert_eq(p.wishes, [] as Array[String])
	assert_eq(p.survivor_gold, 300)
	assert_eq(p.universe_unlocked, 3, "the universe opened by the boss stays unlocked")
	assert_false(Entitlements.universe_open(3, p.purchases))
	assert_true(Entitlements.universe_open(2, p.purchases))


func test_broken_purchase_and_wish_data_falls_back_safely() -> void:
	var p := ProfileData.from_json('{"purchases": "plus", "wishes": 7}')
	assert_eq(p.purchases, [] as Array[String])
	assert_eq(p.wishes, [] as Array[String])
	p = ProfileData.from_json(JSON.stringify({"purchases": ["plus", "plus", 5, null, "PLUS", "x".repeat(80), "pack_sky"],
		"wishes": ["wings.phoenix", "wings.phoenix", "hat.crown", "hat.cap", "nope", 3]}))
	assert_eq(p.purchases, ["plus", "pack_sky"] as Array[String], "known product ids, once each")
	assert_eq(p.wishes, ["wings.phoenix"] as Array[String], "only things a grown-up can give, once each")


func test_the_backup_merge_never_loses_a_purchase() -> void:
	var phone := ProfileData.new()
	phone.username = "Kit"
	phone.updated_at = 2000
	Entitlements.grant(phone, ShopCatalog.PACK_SKY)
	var backup := ProfileData.new()
	backup.username = "Kit"
	backup.updated_at = 1000
	Entitlements.grant(backup, ShopCatalog.PLUS)
	var merged: ProfileData = ProfileBackup.merge(phone, ProfileBackup.to_backup(backup)).profile
	assert_true(Entitlements.owns(merged.purchases, ShopCatalog.PLUS), "the older copy's purchase stays")
	assert_true(Entitlements.owns(merged.purchases, ShopCatalog.PACK_SKY))
	assert_true(AvatarUnlocks.is_owned("cape.aurora", merged.cosmetics))


func test_a_profile_with_a_purchase_is_not_new() -> void:
	var p := ProfileData.new()
	assert_true(ProfileBackup.is_new(p))
	Entitlements.grant(p, ShopCatalog.PACK_OCEAN)
	p.cosmetics.clear()
	assert_false(ProfileBackup.is_new(p), "a bought pack is progress: a backup never overwrites it blindly")


func test_the_travel_refusal_for_a_plus_universe() -> void:
	assert_eq(Entitlements.travel_refusal(3, []), Entitlements.NEEDS_PLUS)
	assert_eq(Entitlements.travel_refusal(3, [ShopCatalog.PLUS]), "")
	assert_eq(Entitlements.travel_refusal(2, []), "")
	assert_eq(Entitlements.travel_refusal(1, []), "")


## Owner 35 merge (lead): a build without a store can't sell Plus, so nothing is locked behind it (a release
## build before Play Billing is set up keeps Frostpeak and the Candy Kingdom open, as they were).
func test_every_universe_is_open_while_this_build_has_no_store() -> void:
	assert_true(Entitlements.universe_open(3, [], false), "no store: nothing locked")
	assert_eq(Entitlements.travel_refusal(4, [], false), "")
	assert_false(Entitlements.universe_open(3, [], true), "with a store: Plus")
