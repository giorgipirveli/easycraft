extends GutTest
## Owner feedback #35 (spec §18.1, §18.6): the purchase flow over the Billing adapter with the fake
## store — buy, cancel, fail, pending, restore after a reinstall, the receipt hook — and the parent
## gate in front of every purchase: the service refuses to start one outside the grown-up area.

var saves := 0


func _service(store: FakeBilling = null, p: ProfileData = null) -> ShopService:
	var s := ShopService.new()
	s.billing = store if store else FakeBilling.new()
	s.profile = p if p else ProfileData.new()
	s.save_profile = func() -> void: saves += 1
	s.start()
	return s


func before_each() -> void:
	saves = 0


func _buy(s: ShopService, product: String) -> Array:
	var got: Array = []
	s.purchase_finished.connect(func(prod: String, status: StringName) -> void: got.append([prod, status]), CONNECT_ONE_SHOT)
	var started := s.buy(product)
	if started == ShopService.STARTED:
		await wait_process_frames(3)
	return [started, got]


func test_nothing_is_bought_outside_the_grown_up_area() -> void:
	var store := FakeBilling.new()
	var s := _service(store)
	var r: Array = await _buy(s, ShopCatalog.PLUS)
	assert_eq(r[0], ShopService.NEEDS_GATE)
	assert_false(store.calls.has("buy:plus"), "the store was never asked")
	assert_eq(s.profile.purchases, [] as Array[String])
	s.enter_grown_up_area()
	s.leave_grown_up_area()
	assert_eq(s.buy(ShopCatalog.PLUS), ShopService.NEEDS_GATE, "closed again when the grown-up area closes")


func test_a_purchase_opens_the_content_saves_and_acknowledges() -> void:
	var store := FakeBilling.new()
	var s := _service(store)
	s.enter_grown_up_area()
	var r: Array = await _buy(s, ShopCatalog.PLUS)
	assert_eq(r[0], ShopService.STARTED)
	assert_eq(r[1], [[ShopCatalog.PLUS, Billing.PAID]])
	assert_true(s.owns(ShopCatalog.PLUS))
	assert_true(s.universe_open(3))
	assert_true(AvatarUnlocks.is_owned("outfit.frost_ranger", s.profile.cosmetics))
	assert_gt(saves, 0, "recorded in the profile")
	assert_eq(store.acknowledged.size(), 1, "the store is told (Play refunds what isn't acknowledged)")
	assert_eq(s.buy(ShopCatalog.PLUS), ShopService.OWNED, "never charged twice")


func test_a_cancelled_or_failed_purchase_changes_nothing() -> void:
	for outcome: StringName in [Billing.CANCELLED, Billing.FAILED]:
		var store := FakeBilling.new()
		store.outcome = outcome
		var s := _service(store)
		s.enter_grown_up_area()
		var r: Array = await _buy(s, ShopCatalog.PACK_SKY)
		assert_eq(r[1], [[ShopCatalog.PACK_SKY, outcome]])
		assert_eq(s.profile.purchases, [] as Array[String], "%s: nothing bought" % outcome)
		assert_false(AvatarUnlocks.is_owned("wings.phoenix", s.profile.cosmetics))
		assert_eq(store.acknowledged.size(), 0)
		assert_false(s.busy(), "ready for another try")


func test_a_pending_payment_opens_only_when_it_completes() -> void:
	var store := FakeBilling.new()
	store.outcome = Billing.PENDING
	var s := _service(store)
	s.enter_grown_up_area()
	var r: Array = await _buy(s, ShopCatalog.PACK_OCEAN)
	assert_eq(r[1], [[ShopCatalog.PACK_OCEAN, Billing.PENDING]])
	assert_false(s.owns(ShopCatalog.PACK_OCEAN), "not while the payment waits")
	s.leave_grown_up_area()
	store.complete_pending(ShopCatalog.PACK_OCEAN)
	await wait_process_frames(3)
	assert_true(s.owns(ShopCatalog.PACK_OCEAN), "opens when paid, even with the grown-up area closed")
	assert_true(AvatarUnlocks.is_owned("outfit.diver", s.profile.cosmetics))


func test_purchases_are_restored_after_a_reinstall() -> void:
	var store := FakeBilling.new()
	var first := _service(store)
	first.enter_grown_up_area()
	await _buy(first, ShopCatalog.PLUS)
	await _buy(first, ShopCatalog.PACK_SKY)
	var fresh := _service(store, ProfileData.new())   # a new phone, the same store account
	assert_false(fresh.owns(ShopCatalog.PLUS))
	var done: Array = []
	fresh.restore_done.connect(func(ok: bool, added: Array) -> void: done.append([ok, added]))
	fresh.restore()
	await wait_process_frames(3)
	assert_eq(done.size(), 1)
	assert_true(done[0][0])
	assert_true(fresh.owns(ShopCatalog.PLUS))
	assert_true(fresh.owns(ShopCatalog.PACK_SKY))
	assert_true(fresh.universe_open(4))
	assert_true(AvatarUnlocks.is_owned("wings.phoenix", fresh.profile.cosmetics))
	assert_false(fresh.busy())


func test_a_failed_restore_never_takes_anything_away() -> void:
	var store := FakeBilling.new()
	var p := ProfileData.new()
	Entitlements.grant(p, ShopCatalog.PLUS)
	store.restore_fails = true
	var s := _service(store, p)
	var done: Array = []
	s.restore_done.connect(func(ok: bool, _added: Array) -> void: done.append(ok))
	s.restore()
	await wait_process_frames(3)
	assert_eq(done, [false])
	assert_true(s.owns(ShopCatalog.PLUS), "what was bought stays")


func test_a_restore_that_lists_less_keeps_what_the_profile_has() -> void:
	var store := FakeBilling.new()
	var p := ProfileData.new()
	Entitlements.grant(p, ShopCatalog.PACK_SKY)
	var s := _service(store, p)
	s.restore()
	await wait_process_frames(3)
	assert_true(s.owns(ShopCatalog.PACK_SKY), "restoring only adds (ruling: refunds are the server hook's job)")


func test_the_starting_restore_opens_what_the_store_remembers() -> void:
	var store := FakeBilling.new()
	store.history.append(ShopCatalog.PACK_OCEAN)
	var s := _service(store)
	s.restore_at_start()
	await wait_process_frames(3)
	assert_true(s.owns(ShopCatalog.PACK_OCEAN))


func test_things_that_are_not_for_sale_are_refused() -> void:
	var store := FakeBilling.new()
	var s := _service(store)
	s.enter_grown_up_area()
	assert_eq(s.buy(ShopCatalog.PACK_STORYBOOK), ShopService.NOT_FOR_SALE, "a slot is not a product yet")
	assert_eq(s.buy("gold_1000"), ShopService.NOT_FOR_SALE)
	assert_eq(store.calls, [] as Array[String])


func test_without_a_store_nothing_can_be_bought() -> void:
	var s := ShopService.new()
	s.billing = Billing.new()
	s.profile = ProfileData.new()
	s.start()
	s.enter_grown_up_area()
	assert_false(s.store_open())
	assert_eq(s.buy(ShopCatalog.PLUS), ShopService.NO_STORE)


func test_one_purchase_at_a_time() -> void:
	var store := FakeBilling.new()
	store.outcome = Billing.PENDING
	var s := _service(store)
	s.enter_grown_up_area()
	assert_eq(s.buy(ShopCatalog.PACK_SKY), ShopService.STARTED)
	assert_eq(s.buy(ShopCatalog.PACK_OCEAN), ShopService.BUSY, "the store's sheet is still open")
	await wait_process_frames(3)
	assert_eq(s.buy(ShopCatalog.PACK_OCEAN), ShopService.STARTED)


func test_the_receipt_hook_can_refuse_a_purchase() -> void:
	var store := FakeBilling.new()
	var s := _service(store)
	var seen: Array = []
	s.verify_receipt = func(purchase: Dictionary) -> bool:
		seen.append(purchase.product)
		return false
	s.enter_grown_up_area()
	var r: Array = await _buy(s, ShopCatalog.PACK_SKY)
	assert_eq(seen, [ShopCatalog.PACK_SKY], "the server hook saw the receipt")
	assert_eq(r[1], [[ShopCatalog.PACK_SKY, Billing.FAILED]])
	assert_false(s.owns(ShopCatalog.PACK_SKY))
	assert_eq(store.acknowledged.size(), 0, "not acknowledged: Play refunds it")


func test_prices_come_from_the_store_when_it_has_them() -> void:
	var store := FakeBilling.new()
	store.prices = {ShopCatalog.PLUS: "13,99 GEL"}
	var s := _service(store)
	await wait_process_frames(3)
	assert_eq(s.price_words(ShopCatalog.PLUS), "13,99 GEL")
	assert_eq(s.price_words(ShopCatalog.PACK_SKY), ShopCatalog.reference_price(ShopCatalog.PACK_SKY))


func test_the_fake_store_says_it_is_a_test_and_remembers_across_launches() -> void:
	var path := "user://test_fake_store_%d.json" % OS.get_process_id()
	var a := FakeBilling.new(path)
	assert_true(a.is_test())
	a.buy(ShopCatalog.PACK_SKY)
	await wait_process_frames(2)
	var b := FakeBilling.new(path)
	assert_has(b.history, ShopCatalog.PACK_SKY, "a pretend purchase history, like the store account's")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path + ".bak")


func test_an_answer_about_something_that_is_not_ours_is_ignored() -> void:
	var store := FakeBilling.new()
	var s := _service(store)
	var got: Array = []
	s.purchase_finished.connect(func(prod: String, status: StringName) -> void: got.append([prod, status]))
	store.purchase_updated.emit({"product": "", "status": Billing.OWNED_ALREADY, "token": "", "acknowledged": false})
	store.purchase_updated.emit({"product": "gold_1000", "status": Billing.PAID, "token": "x", "acknowledged": false})
	await wait_process_frames(2)
	assert_eq(got, [], "nothing to say to the grown-up")
	assert_eq(s.profile.purchases, [] as Array[String])
	assert_eq(store.calls, [] as Array[String], "no restore asked for a stray answer")
