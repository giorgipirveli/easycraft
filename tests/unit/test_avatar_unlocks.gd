extends GutTest
## M3 Task 9 (spec §5.9, §6, §13.6, §14.6): avatar items are account-wide. A basic set is free;
## others have FIXED gold prices (Survivor gold) or are earned (achievements, bosses, secrets, codes).
## No random boxes, nothing only for payers, and what is earned is the best (the legendary cosmic
## outfit can't be bought). AvatarUnlocks is the one rule for price and ownership.


func _profile(gold: int = 0) -> ProfileData:
	var p := ProfileData.new()
	p.survivor_gold = gold
	return p


func test_there_is_a_free_basic_set_in_every_slot() -> void:
	for slot: StringName in [AvatarCatalog.FACE, AvatarCatalog.HAIR, AvatarCatalog.HAT, AvatarCatalog.CAPE,
			AvatarCatalog.TRAIL, AvatarCatalog.EMOTE]:
		var free := AvatarCatalog.items_in(slot).filter(func(n: StringName) -> bool:
			return n != &"none" and AvatarCatalog.is_free(AvatarCatalog.item_id(slot, n)))
		assert_gt(free.size(), 0, "free %s items" % slot)


func test_colours_and_hair_are_always_free() -> void:
	for n: StringName in AvatarCatalog.items_in(AvatarCatalog.HAIR):
		assert_true(AvatarCatalog.is_free(AvatarCatalog.item_id(AvatarCatalog.HAIR, n)), "hair %s" % n)
	var p := _profile()
	for c: StringName in AvatarCatalog.CLOTH:
		var look := AvatarLook.new()
		look.shirt = c
		look.pants = c
		assert_true(AvatarUnlocks.wearable(look, p.cosmetics).equals(look), "colour %s needs nothing" % c)


func test_the_free_base_set_has_at_least_four_emotes_and_two_dances() -> void:
	var emotes := 0
	var dances := 0
	for n: StringName in AvatarCatalog.items_in(AvatarCatalog.EMOTE):
		if not AvatarCatalog.is_free(AvatarCatalog.item_id(AvatarCatalog.EMOTE, n)):
			continue
		if AvatarCatalog.is_dance(n):
			dances += 1
		else:
			emotes += 1
	assert_gte(emotes, 4, "free emotes")
	assert_gte(dances, 2, "free dances")


func test_the_wheel_has_the_spec_emotes() -> void:
	for n: StringName in [&"wave", &"cheer", &"laugh", &"thumbs_up", &"sit", &"dance_hop", &"dance_robot", &"dance_star"]:
		assert_true(AvatarCatalog.has_item(AvatarCatalog.EMOTE, n), n)
	var dances := AvatarCatalog.items_in(AvatarCatalog.EMOTE).filter(func(n: StringName) -> bool: return AvatarCatalog.is_dance(n))
	assert_gte(dances.size(), 3, "three dances (and the victory dance)")


func test_every_item_is_free_priced_or_earned_never_random() -> void:
	for id: String in AvatarCatalog.ITEMS:
		var item: Dictionary = AvatarCatalog.ITEMS[id]
		assert_has(AvatarCatalog.UNLOCK_KINDS, item.kind, "%s has a known unlock kind" % id)
		if item.kind == AvatarCatalog.GOLD:
			assert_gt(int(item.price), 0, "%s has a fixed price" % id)
		else:
			assert_eq(int(item.get("price", 0)), 0, "%s can't be bought" % id)
		if item.kind in [AvatarCatalog.ACHIEVEMENT, AvatarCatalog.BOSS, AvatarCatalog.SECRET]:
			assert_true(AvatarCatalog.EARN_REASONS.has(item.get("earn", &"")), "%s says how it is earned" % id)
	for kind: StringName in AvatarCatalog.UNLOCK_KINDS:
		assert_false(String(kind).contains("random") or String(kind).contains("box"), "no random unlocks")


func test_the_cosmic_outfit_is_earned_by_beating_the_cake_monster() -> void:
	var id := AvatarCatalog.item_id(AvatarCatalog.OUTFIT, &"cosmic")
	var p := _profile(999_999)
	assert_eq(AvatarUnlocks.check_buy(id, p.cosmetics, p.survivor_gold), AvatarUnlocks.NOT_FOR_SALE, "gold can't buy it")
	assert_eq(AvatarUnlocks.buy(p, id), AvatarUnlocks.NOT_FOR_SALE)
	assert_eq(p.survivor_gold, 999_999, "no gold taken")
	assert_false(AvatarUnlocks.is_owned(id, p.cosmetics))
	assert_string_contains(AvatarUnlocks.lock_reason(id), "Cake Monster")
	assert_eq(AvatarCatalog.rarity(id), AvatarCatalog.LEGENDARY)
	var got := AvatarUnlocks.earn(p, AvatarCatalog.EARN_CAKE_MONSTER)
	assert_has(got, id)
	assert_true(AvatarUnlocks.is_owned(id, p.cosmetics))
	assert_eq(AvatarUnlocks.earn(p, AvatarCatalog.EARN_CAKE_MONSTER), [] as Array[String], "earned once")


func test_nothing_bought_outranks_the_legendary_earned_outfit() -> void:
	for id: String in AvatarCatalog.ITEMS:
		if AvatarCatalog.ITEMS[id].kind == AvatarCatalog.GOLD:
			assert_ne(AvatarCatalog.rarity(id), AvatarCatalog.LEGENDARY, "%s is not legendary" % id)


func test_buying_with_enough_gold_takes_the_fixed_price_once() -> void:
	var id := AvatarCatalog.item_id(AvatarCatalog.HAT, &"crown")
	var price := AvatarCatalog.price(id)
	var p := _profile(price + 7)
	assert_eq(AvatarUnlocks.check_buy(id, p.cosmetics, p.survivor_gold), AvatarUnlocks.OK)
	assert_eq(AvatarUnlocks.buy(p, id), AvatarUnlocks.OK)
	assert_eq(p.survivor_gold, 7)
	assert_true(AvatarUnlocks.is_owned(id, p.cosmetics))
	assert_eq(AvatarUnlocks.buy(p, id), AvatarUnlocks.OWNED, "never charged twice")
	assert_eq(p.survivor_gold, 7)


func test_not_enough_gold_changes_nothing_and_says_how_much_more() -> void:
	var id := AvatarCatalog.item_id(AvatarCatalog.WINGS, &"dragon")
	var price := AvatarCatalog.price(id)
	var p := _profile(price - 40)
	assert_eq(AvatarUnlocks.buy(p, id), AvatarUnlocks.NOT_ENOUGH)
	assert_eq(p.survivor_gold, price - 40)
	assert_false(AvatarUnlocks.is_owned(id, p.cosmetics))
	assert_eq(AvatarUnlocks.message(AvatarUnlocks.NOT_ENOUGH, id, p.survivor_gold), "You need 40 more gold.")


func test_free_items_need_no_buying() -> void:
	var id := AvatarCatalog.item_id(AvatarCatalog.HAT, &"cap")
	var p := _profile(10)
	assert_true(AvatarUnlocks.is_owned(id, p.cosmetics), "free = owned")
	assert_eq(AvatarUnlocks.buy(p, id), AvatarUnlocks.OWNED)
	assert_eq(p.survivor_gold, 10)


func test_unknown_items_are_refused() -> void:
	var p := _profile(1000)
	assert_eq(AvatarUnlocks.buy(p, "hat.golden_toilet"), AvatarUnlocks.UNKNOWN)
	assert_eq(AvatarUnlocks.buy(p, ""), AvatarUnlocks.UNKNOWN)
	assert_eq(p.survivor_gold, 1000)
	assert_false(AvatarUnlocks.grant(p, "wings.jetpack"))
	assert_eq(p.cosmetics, [] as Array[String])


func test_earned_items_are_locked_with_a_reason_until_earned() -> void:
	var cases := {
		AvatarCatalog.item_id(AvatarCatalog.HAT, &"pip_cap"): AvatarCatalog.EARN_TUTORIAL,
		AvatarCatalog.item_id(AvatarCatalog.EMOTE, &"victory"): AvatarCatalog.EARN_FIRST_VICTORY,
		AvatarCatalog.item_id(AvatarCatalog.HAT, &"golem_helm"): AvatarCatalog.EARN_GOLEM,
		AvatarCatalog.item_id(AvatarCatalog.WINGS, &"fairy"): AvatarCatalog.EARN_SECRET_PAGE,
	}
	for id: String in cases:
		var p := _profile(999_999)
		assert_false(AvatarUnlocks.is_owned(id, p.cosmetics), "%s starts locked" % id)
		assert_eq(AvatarUnlocks.buy(p, id), AvatarUnlocks.NOT_FOR_SALE)
		assert_ne(AvatarUnlocks.lock_reason(id), "", "%s says why" % id)
		assert_has(AvatarUnlocks.earn(p, cases[id]), id)
		assert_true(AvatarUnlocks.is_owned(id, p.cosmetics))


func test_lock_reasons_are_friendly() -> void:
	for id: String in AvatarCatalog.ITEMS:
		var reason := AvatarUnlocks.lock_reason(id).to_lower()
		for bad: String in ["hurry", "last chance", "only today", "miss", "don't go", "buy now"]:
			assert_false(reason.contains(bad), "%s: no pressure words" % id)
	assert_eq(AvatarUnlocks.lock_reason(AvatarCatalog.item_id(AvatarCatalog.HAT, &"crown")), "%d gold" % AvatarCatalog.price(AvatarCatalog.item_id(AvatarCatalog.HAT, &"crown")))
	assert_eq(AvatarUnlocks.lock_reason(AvatarCatalog.item_id(AvatarCatalog.HAT, &"cap")), "", "free: nothing to say")


func test_a_code_item_is_locked_until_a_code_gives_it() -> void:
	var id := AvatarCatalog.item_id(AvatarCatalog.TRAIL, &"confetti")
	assert_eq(AvatarCatalog.ITEMS[id].kind, AvatarCatalog.CODE)
	var p := _profile(999_999)
	assert_eq(AvatarUnlocks.buy(p, id), AvatarUnlocks.NOT_FOR_SALE)
	assert_string_contains(AvatarUnlocks.lock_reason(id), "code")
	assert_true(CodeRules.give(p, {"kind": CodeRules.KIND_COSMETIC, "item": id}), "the code rule gives cosmetics")
	assert_true(AvatarUnlocks.is_owned(id, p.cosmetics))
	assert_false(CodeRules.give(p, {"kind": CodeRules.KIND_COSMETIC, "item": "trail.lava"}), "unknown items are not given")
	assert_false(CodeRules.give(p, {"kind": CodeRules.KIND_COSMETIC}), "no item")


func test_a_cosmetic_code_says_what_it_gave() -> void:
	var id := AvatarCatalog.item_id(AvatarCatalog.TRAIL, &"confetti")
	var msg := CodeRules.message({"status": CodeRules.ACCEPTED, "reward": {"kind": CodeRules.KIND_COSMETIC, "item": id}})
	assert_eq(msg, "Code accepted! New: %s" % AvatarCatalog.display_name(id))


func test_a_cosmetic_code_redeems_once() -> void:
	var p := _profile()
	var tries := CodeTries.new()
	var id := AvatarCatalog.item_id(AvatarCatalog.WINGS, &"bat")
	var rewards := {CodeRules.hash_code("test-wings"): {"kind": CodeRules.KIND_COSMETIC, "item": id}}
	var first := CodeRules.redeem(p, "test-wings", tries, 0, rewards)
	assert_eq(first.status, CodeRules.ACCEPTED)
	assert_true(AvatarUnlocks.is_owned(id, p.cosmetics))
	assert_eq(CodeRules.redeem(p, "test-wings", tries, 0, rewards).status, CodeRules.ALREADY_USED)


func test_wearable_takes_off_what_is_not_owned() -> void:
	var p := _profile()
	var look := AvatarLook.new()
	look.hat = &"crown"          # gold
	look.wings = &"fairy"        # secret
	look.outfit = &"cosmic"      # boss
	look.face = &"cool"          # gold
	look.cape = &"hero"          # free
	look.emotes[2] = &"dance_star"
	var worn := AvatarUnlocks.wearable(look, p.cosmetics)
	assert_eq(worn.hat, &"none")
	assert_eq(worn.wings, &"none")
	assert_eq(worn.outfit, &"none")
	assert_eq(worn.face, &"smile")
	assert_eq(worn.cape, &"hero", "free items stay")
	assert_true(AvatarUnlocks.is_owned(AvatarCatalog.item_id(AvatarCatalog.EMOTE, worn.emotes[2]), p.cosmetics), "the wheel keeps only owned emotes")
	assert_eq(look.hat, &"crown", "the original is not changed")
	AvatarUnlocks.grant(p, AvatarCatalog.item_id(AvatarCatalog.HAT, &"crown"))
	assert_eq(AvatarUnlocks.wearable(look, p.cosmetics).hat, &"crown", "owned now")


func test_sanitize_owned_keeps_only_known_unique_non_free_items() -> void:
	var owned := AvatarUnlocks.sanitize_owned(["hat.crown", "hat.crown", "hat.cap", "hat.nope", 5, null, "HAT.CROWN", "wings.bat"])
	assert_eq(owned, ["hat.crown", "wings.bat"] as Array[String])
	assert_eq(AvatarUnlocks.sanitize_owned("hat.crown"), [] as Array[String])
	assert_eq(AvatarUnlocks.sanitize_owned(null), [] as Array[String])


func test_prices_are_whole_numbers_a_child_can_read() -> void:
	for id: String in AvatarCatalog.ITEMS:
		var price := AvatarCatalog.price(id)
		assert_eq(price % 10, 0, "%s: %d is a round price" % [id, price])
		assert_lte(price, 1000, "%s: reachable with earned gold" % id)


func test_every_item_has_a_short_name() -> void:
	for id: String in AvatarCatalog.ITEMS:
		var n := AvatarCatalog.display_name(id)
		assert_ne(n, "", id)
		# owner #36: a costume is named for its hero ("Sherlock Holmes"); test_costume_editor checks it fits its tile
		assert_lte(n.length(), 15 if id.begins_with("costume.") else 14, "%s fits under an icon" % id)
