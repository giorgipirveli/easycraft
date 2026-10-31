extends GutTest
## Owner feedback #35 (spec §18): the grown-up area's SHOP page, behind the parent gate. EasyCraft Plus
## and the packs with their exact items and prices, a confirm page with the price before the store's
## sheet, the child's wish list with GIVE AS A GIFT, RESTORE, what stays free forever, the test store
## said plainly, and a closed shop when there is no store. Every view fits the menu's panel.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const PANEL_CONTENT := Vector2(1280 - 56, 720 - 130 - 56)

var DIR := "user://test_shop_grown_up_%d/" % OS.get_process_id()
var store: FakeBilling
var shop: ShopService
var profile: ProfileData
var _saves := 0


func before_each() -> void:
	ParentGate.reset_tries()   # M4 Task 10 review E: the gates share one lock for the app run
	DirAccess.make_dir_recursive_absolute(DIR)
	_saves = 0
	store = FakeBilling.new()
	profile = ProfileData.new()
	shop = _shop(store)


func after_each() -> void:
	Session.use_shop(null)
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func _shop(billing: Billing) -> ShopService:
	var s := ShopService.new()
	s.billing = billing
	s.profile = profile
	s.save_profile = func() -> void: _saves += 1
	s.start()
	return s


## The area on its SHOP page inside a themed panel, as the menus show it.
func _area(with_shop: ShopService = shop) -> GrownUpsPanel:
	var holder := Control.new()
	holder.theme = UiKit.theme()
	holder.size = Vector2(1280, 720)
	add_child_autofree(holder)
	var panel := PanelContainer.new()
	holder.add_child(panel)
	var area := GrownUpsPanel.new()
	area.service = OnlineService.new()
	autofree(area.service)
	area.shop = with_shop
	area.page = GrownUpsPanel.PAGE_SHOP
	panel.add_child(area)
	await wait_process_frames(3)
	return area


func _page(area: GrownUpsPanel) -> ShopPage:
	var pages := area.find_children("*", "ShopPage", true, false)
	return pages[0] as ShopPage if pages.size() == 1 else null


func _buttons(root: Node) -> Array[Button]:
	var out: Array[Button] = []
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree() and not (b as Node).is_queued_for_deletion():
			out.append(b)
	return out


func _button(root: Node, prefix: String) -> Button:
	for b in _buttons(root):
		if b.text.begins_with(prefix):
			return b
	return null


func _press(root: Node, prefix: String) -> void:
	var b := _button(root, prefix)
	assert_not_null(b, "a %s button" % prefix)
	if b:
		b.pressed.emit()
	await wait_process_frames(3)


func _words(root: Node) -> String:
	var out := ""
	for l in root.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree() and not (l as Node).is_queued_for_deletion():
			out += (l as Label).text + "\n"
	for b in _buttons(root):
		out += b.text + "\n"
	return out


func _check_fits(area: Control, what: String) -> void:
	await wait_process_frames(2)
	var size := area.get_combined_minimum_size()
	assert_lte(size.y, PANEL_CONTENT.y, "%s fits the height (%d)" % [what, size.y])
	assert_lte(size.x, PANEL_CONTENT.x, "%s fits the width (%d)" % [what, size.x])
	for b in _buttons(area):
		if b is AvatarTile:
			continue
		assert_gte(b.size.x, OnlineUi.MIN_WIDTH, "%s: %s is wide enough" % [what, b.text])
		assert_gte(b.size.y, OnlineUi.MIN_HEIGHT, "%s: %s is tall enough" % [what, b.text])


# --- The gate ---

func _player_service(server: RefCounted) -> OnlineService:
	server.make_account("dev-k", "Kit", AgeBand.UNDER_13, OnlineRules.CONSENT_VERIFIED, true)
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = "dev-k"
	s.profile = ProfileData.new()
	s.profile.username = "Kit"
	s.profile.age_band = AgeBand.UNDER_13
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + "dev-k.json"
	s.prefs.safe_card_seen = 1_800_000_000
	add_child_autofree(s)
	assert_eq(await s.sign_in(), "")
	return s


func test_the_shop_is_only_reached_through_the_parent_gate() -> void:
	Session.use_shop(shop)
	var service := await _player_service(FakeServer.new())
	var box := PanelContainer.new()
	box.theme = UiKit.theme()
	var settings := SettingsPanel.new()
	settings.make_service = func() -> OnlineService: return service
	settings.play_minutes = func() -> int: return 3
	box.add_child(settings)
	add_child_autofree(box)
	await wait_process_frames(3)
	assert_eq(settings.find_children("*", "ShopPage", true, false).size(), 0)
	await _press(settings, "GROWN-UPS")
	var g := settings.find_children("*", "GrownUpGate", true, false)[0] as GrownUpGate
	assert_eq(settings.find_children("*", "ShopPage", true, false).size(), 0, "the gate first")
	assert_false(shop.in_grown_up_area())
	for key in str(int(g.question.answer) + 1):
		g.press(key)
	g.press("OK")
	await wait_process_frames(2)
	assert_eq(settings.find_children("*", "GrownUpsPanel", true, false).size(), 0, "a wrong answer stays at the gate")
	for key in str(g.question.answer):
		g.press(key)
	g.press("OK")
	await wait_process_frames(3)
	await _press(settings, "SHOP")
	var pages := settings.find_children("*", "ShopPage", true, false)
	assert_eq(pages.size(), 1, "the shop page, behind the gate")
	assert_true(shop.in_grown_up_area())
	await _press(settings, "DONE")
	await wait_process_frames(2)
	assert_false(shop.in_grown_up_area(), "closed with the area")
	assert_eq(shop.buy(ShopCatalog.PLUS), ShopService.NEEDS_GATE)


# --- Plus ---

func test_plus_shows_its_universes_items_and_price_then_a_confirm_page() -> void:
	var area := await _area()
	var page := _page(area)
	assert_not_null(page)
	assert_eq(page.view, ShopPage.VIEW_PLUS, "Plus first")
	var words := _words(area)
	assert_string_contains(words, "EasyCraft Plus")
	assert_string_contains(words, ShopCatalog.reference_price(ShopCatalog.PLUS))
	for u in ShopCatalog.plus_universes():
		assert_string_contains(words, UniverseRegistry.display_name(u))
	for item in ShopCatalog.items_of(ShopCatalog.PLUS):
		assert_string_contains(words, AvatarCatalog.display_name(item))
	await _check_fits(area, "Plus")
	await _press(area, "BUY")
	assert_eq(page.view, ShopPage.VIEW_CONFIRM)
	assert_eq(store.calls, [] as Array[String], "nothing bought before the confirm page")
	words = _words(area)
	assert_string_contains(words, "You are buying")
	assert_string_contains(words, ShopCatalog.reference_price(ShopCatalog.PLUS))
	assert_string_contains(words, "once")
	for item in ShopCatalog.items_of(ShopCatalog.PLUS):
		assert_string_contains(words, AvatarCatalog.display_name(item), "the exact items before paying")
	await _check_fits(area, "the confirm page")
	await _press(area, "PAY " + ShopCatalog.reference_price(ShopCatalog.PLUS))
	await wait_process_frames(3)
	assert_eq(store.calls, ["buy:plus"] as Array[String])
	assert_true(shop.owns(ShopCatalog.PLUS))
	assert_true(Entitlements.universe_open(3, profile.purchases))
	assert_string_contains(page.note.text, "Thank you")
	assert_eq(page.view, ShopPage.VIEW_PLUS)
	assert_null(_button(area, "BUY"), "owned: nothing more to buy")
	assert_string_contains(_words(area), ShopWords.OWNED_WORD)


func test_back_on_the_confirm_page_buys_nothing() -> void:
	var area := await _area()
	await _press(area, "BUY")
	await _press(area, "BACK")
	assert_eq(_page(area).view, ShopPage.VIEW_PLUS)
	assert_eq(store.calls, [] as Array[String])


func test_a_cancelled_or_failed_payment_says_nothing_was_charged() -> void:
	for outcome: StringName in [Billing.CANCELLED, Billing.FAILED]:
		store.outcome = outcome
		var area := await _area()
		await _press(area, "BUY")
		await _press(area, "PAY")
		await wait_process_frames(3)
		assert_string_contains(_page(area).note.text, "othing was charged", str(outcome))
		assert_false(shop.owns(ShopCatalog.PLUS))
		assert_not_null(_button(area, "BUY"), "can try again")


func test_a_pending_payment_says_it_opens_when_paid() -> void:
	store.outcome = Billing.PENDING
	var area := await _area()
	await _press(area, "BUY")
	await _press(area, "PAY")
	await wait_process_frames(3)
	assert_string_contains(_page(area).note.text, "waiting")
	assert_false(shop.owns(ShopCatalog.PLUS))


# --- Packs ---

func test_packs_show_every_item_and_price_and_no_slots() -> void:
	var area := await _area()
	await _press(area, "PACKS")
	var page := _page(area)
	assert_eq(page.view, ShopPage.VIEW_PACKS)
	var words := _words(area)
	for id in ShopCatalog.for_sale():
		if id == ShopCatalog.PLUS:
			continue
		assert_string_contains(words, ShopCatalog.product_name(id))
		assert_string_contains(words, ShopCatalog.reference_price(id))
		for item in ShopCatalog.items_of(id):
			assert_string_contains(words, AvatarCatalog.display_name(item))
	assert_false(words.contains("Storybook Pack"), "a slot is not shown")
	assert_false(words.contains("Glider Looks"))
	await _check_fits(area, "packs")
	var buy := _button(area, "BUY")
	buy.pressed.emit()
	await wait_process_frames(3)
	assert_eq(page.view, ShopPage.VIEW_CONFIRM)
	await _press(area, "PAY")
	await wait_process_frames(3)
	assert_true(shop.owns(ShopCatalog.PACK_SKY))
	assert_true(AvatarUnlocks.is_owned("wings.phoenix", profile.cosmetics))


func test_the_stores_own_price_is_shown_when_it_has_one() -> void:
	store.prices = {ShopCatalog.PLUS: "13,99 ₾"}
	var s := _shop(store)
	await wait_process_frames(2)
	var area := await _area(s)
	assert_string_contains(_words(area), "13,99 ₾")
	await _press(area, "BUY")
	assert_not_null(_button(area, "PAY 13,99 ₾"))


# --- The wish list ---

func test_the_childs_wishes_reach_the_grown_up_who_can_give_them() -> void:
	WishList.add(profile, "wings.phoenix")
	WishList.add(profile, "cape.aurora")
	var area := await _area()
	assert_not_null(_button(area, "WISH LIST (2)"), "the count on the button")
	await _press(area, "WISH LIST")
	var page := _page(area)
	assert_eq(page.view, ShopPage.VIEW_WISHES)
	var words := _words(area)
	assert_string_contains(words, "Phoenix Wings")
	assert_string_contains(words, "Sky Pack")
	assert_string_contains(words, ShopCatalog.reference_price(ShopCatalog.PACK_SKY))
	assert_string_contains(words, "Aurora Cape")
	assert_string_contains(words, "EasyCraft Plus")
	await _check_fits(area, "the wish list")
	await _press(area, "GIVE AS A GIFT")
	assert_eq(page.view, ShopPage.VIEW_CONFIRM)
	assert_string_contains(_words(area), "Sky Pack", "the first wish's pack")
	await _press(area, "PAY")
	await wait_process_frames(3)
	assert_true(shop.owns(ShopCatalog.PACK_SKY))
	assert_eq(profile.wishes, ["cape.aurora"] as Array[String], "the gift left the list")


func test_an_empty_wish_list_says_so() -> void:
	var area := await _area()
	await _press(area, "WISH LIST")
	assert_string_contains(_words(area), "No wishes")


# --- Restore, free forever, the store's state ---

func test_restore_brings_back_what_the_store_account_owns() -> void:
	store.history.append(ShopCatalog.PACK_OCEAN)
	var area := await _area()
	await _press(area, "RESTORE")
	await wait_process_frames(3)
	assert_true(shop.owns(ShopCatalog.PACK_OCEAN))
	assert_string_contains(_page(area).note.text, "Ocean Pack")


func test_always_free_lists_what_never_costs_anything() -> void:
	var area := await _area()
	await _press(area, "ALWAYS FREE")
	var words := _words(area)
	for key: StringName in ShopCatalog.FREE_FOREVER:
		assert_string_contains(words, ShopCatalog.free_words(key))
	assert_string_contains(words, "No ads")
	await _check_fits(area, "always free")


func test_the_test_store_says_nothing_is_charged() -> void:
	var area := await _area()
	assert_string_contains(_words(area), ShopWords.TEST_STORE)


func test_without_a_store_the_shop_is_closed_and_nothing_can_be_bought() -> void:
	var closed := _shop(Billing.new())
	var area := await _area(closed)
	var words := _words(area)
	assert_string_contains(words, ShopWords.STORE_OFF)
	assert_string_contains(words, "EasyCraft Plus", "still says what it would be")
	assert_null(_button(area, "BUY"), "no buy button without a store")
	await _press(area, "PACKS")
	assert_null(_button(area, "BUY"))


func test_the_area_still_fits_with_the_shop_tab() -> void:
	var area := await _area()
	for p: StringName in [GrownUpsPanel.PAGE_TIME, GrownUpsPanel.PAGE_SHOP]:
		area.show_page(p)
		await _check_fits(area, str(p))
	assert_not_null(_button(area, "SHOP"))
