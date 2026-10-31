extends GutTest
## Owner feedback #35 (spec §18.1, §18.3, §18.5): what a child sees of the shop. In the avatar editor a
## pack item has no price and no buy button, only WISH (a heart) that puts it on the wish list; a
## universe that comes with Plus shows a calm "EasyCraft Plus" card, and the one line that mentions a
## grown-up is said once. No child screen can buy or show a real-money price: only the grown-up
## area's shop page does (checked over the code, too).

const FAKE := preload("res://tests/fakes/fake_universe.gd")
## Code a child's screens run: none of it may buy or show a real-money price.
const CHILD_DIRS: Array[String] = ["res://ui/avatar", "res://ui/universe", "res://ui/menus", "res://ui/hud",
	"res://ui/progress", "res://ui/photo", "res://world", "res://scenes", "res://entities"]

var editor: AvatarEditor
var profile: ProfileData
var _saves := 0
var _unlocked := 1
var _hints: Array[String] = []
var _purchases: Array[String] = []


func before_each() -> void:
	_saves = 0
	_unlocked = Profile.data.universe_unlocked
	_hints = Profile.data.hints_seen.duplicate()
	_purchases = Profile.data.purchases.duplicate()
	Profile.data.purchases.clear()
	profile = ProfileData.new()
	profile.survivor_gold = 5000


func after_each() -> void:
	Profile.data.universe_unlocked = _unlocked
	Profile.data.hints_seen = _hints
	Profile.data.purchases = _purchases
	UniverseRegistry.reset()


func _editor() -> AvatarEditor:
	editor = AvatarEditor.new()
	editor.profile = profile
	editor.save_profile = func() -> void: _saves += 1
	editor.preview_style = "blocky"
	add_child_autofree(editor)
	await wait_process_frames(2)
	return editor


func _visible_texts(root: Node) -> Array[String]:
	var out: Array[String] = []
	for n in root.find_children("*", "", true, false):
		if n is Label and (n as Label).is_visible_in_tree():
			out.append((n as Label).text)
		elif n is Button and (n as Button).is_visible_in_tree():
			out.append((n as Button).text)
	return out


func _no_money_words(texts: Array[String], what: String) -> void:
	for t in texts:
		for bad: String in ["$", "€", "£", "US$", "BUY FOR", "PAY", "price"]:
			assert_false(t.contains(bad), "%s: '%s' in \"%s\"" % [what, bad, t])


# --- The avatar editor ---

func test_a_pack_item_has_no_price_and_no_buy_button_only_wish() -> void:
	await _editor()
	editor.select_tab(AvatarCatalog.WINGS)
	editor.pick(AvatarCatalog.WINGS, &"phoenix")
	await wait_process_frames(2)
	assert_false(editor.buy_button.visible, "no buy button for what a grown-up buys")
	assert_true(editor.wish_button.visible, "WISH instead")
	var tile: AvatarTile
	for t in editor.tiles():
		if t.item == &"phoenix":
			tile = t
	assert_true(tile.locked)
	assert_eq(tile.price, 0, "no coin tag")
	assert_string_contains(editor.message.text, "Sky Pack", "where it comes from")
	_no_money_words(_visible_texts(editor), "the editor")


func test_wish_puts_it_on_the_list_and_takes_it_off_again() -> void:
	await _editor()
	editor.select_tab(AvatarCatalog.WINGS)
	editor.pick(AvatarCatalog.WINGS, &"phoenix")
	editor.wish_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(profile.wishes, ["wings.phoenix"] as Array[String])
	assert_gt(_saves, 0, "saved")
	assert_eq(editor.message.text, ShopWords.wished(true))
	assert_eq(editor.wish_button.text, ShopWords.WISHED)
	var tile: AvatarTile
	for t in editor.tiles():
		if t.item == &"phoenix":
			tile = t
	assert_true(tile.wished, "a heart on the tile")
	editor.wish_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(profile.wishes, [] as Array[String])
	assert_false(tile.wished)


func test_gold_and_earned_items_have_no_wish_button() -> void:
	await _editor()
	editor.select_tab(AvatarCatalog.HAT)
	editor.pick(AvatarCatalog.HAT, &"crown")
	await wait_process_frames(1)
	assert_true(editor.buy_button.visible, "gold items keep BUY with gold")
	assert_false(editor.wish_button.visible, "the child's own goal, not a gift")
	editor.pick(AvatarCatalog.HAT, &"golem_helm")
	await wait_process_frames(1)
	assert_false(editor.wish_button.visible)
	editor.pick(AvatarCatalog.HAT, &"cap")
	await wait_process_frames(1)
	assert_false(editor.wish_button.visible, "free")
	for id in AvatarCatalog.GIRL_PARTS:   # Owner 48: boy and girl looks are nobody's gift or purchase
		editor.pick(AvatarCatalog.slot_of(id), AvatarCatalog.name_of(id))
		assert_false(editor.wish_button.visible, "%s: no WISH" % id)
		assert_false(editor.buy_button.visible, "%s: no BUY" % id)


func test_a_bought_pack_item_is_worn_and_saved_like_any_other() -> void:
	Entitlements.grant(profile, ShopCatalog.PACK_SKY)
	await _editor()
	editor.select_tab(AvatarCatalog.WINGS)
	editor.pick(AvatarCatalog.WINGS, &"phoenix")
	await wait_process_frames(1)
	assert_false(editor.wish_button.visible, "owned: nothing to wish")
	editor.done()
	assert_eq(profile.avatar.wings, &"phoenix", "worn")


# --- Universe cards ---

func _open_all() -> void:
	for u in range(2, UniverseRegistry.size() + 1):
		UniverseRegistry.use(u, FAKE.new())


func test_a_universe_that_comes_with_plus_shows_a_calm_card() -> void:
	_open_all()
	var card := UniverseCard.new(3, true, false)
	add_child_autofree(card)
	assert_true(card.plus_locked)
	assert_eq(card.word(), ShopWords.PLUS_CARD)
	assert_true(card.disabled, "nothing to press, nothing to nag about")
	var free := UniverseCard.new(2, true, false)
	add_child_autofree(free)
	assert_false(free.plus_locked)
	assert_eq(free.word(), "GO!")
	Profile.data.purchases.append(ShopCatalog.PLUS)
	var bought := UniverseCard.new(3, true, false)
	add_child_autofree(bought)
	assert_false(bought.plus_locked, "open after the purchase")
	assert_eq(bought.word(), "GO!")


func test_the_hub_says_the_grown_up_line_once_then_never_again() -> void:
	_open_all()
	Profile.data.hints_seen.erase(ShopWords.HINT_PLUS)
	var panel := HubPanel.new()
	add_child_autofree(panel)
	await wait_process_frames(1)
	var entries: Array[Dictionary] = [{"universe": 1, "open": true}, {"universe": 2, "open": true}, {"universe": 3, "open": true}]
	panel.open(entries, 1)
	assert_eq(panel.hint(), ShopWords.PLUS_ONCE)
	panel.close()
	panel.open(entries, 1)
	assert_eq(panel.hint(), "", "said once, never repeated")
	var free_only: Array[Dictionary] = [{"universe": 1, "open": true}, {"universe": 2, "open": true}]
	Profile.data.hints_seen.erase(ShopWords.HINT_PLUS)
	panel.open(free_only, 1)
	assert_eq(panel.hint(), "", "nothing about Plus when no card needs it")


func test_the_menu_hub_says_the_line_once() -> void:
	_open_all()
	Profile.data.hints_seen.erase(ShopWords.HINT_PLUS)
	Profile.data.universe_unlocked = 3
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_process_frames(3)
	menu.call("_show_main")
	await wait_process_frames(2)
	menu.call("_on_survivor")
	await wait_process_frames(2)
	var texts := _visible_texts(menu)
	assert_has(texts, ShopWords.PLUS_ONCE)
	assert_has(texts, ShopWords.PLUS_CARD, "the Frostpeak card")
	_no_money_words(texts, "the SURVIVOR hub")
	menu.call("_show_main")
	await wait_process_frames(2)
	menu.call("_on_survivor")
	await wait_process_frames(2)
	assert_does_not_have(_visible_texts(menu), ShopWords.PLUS_ONCE, "once only")


func test_travelling_to_a_plus_universe_is_refused_calmly() -> void:
	Profile.data.hints_seen.erase(ShopWords.HINT_PLUS)
	assert_eq(Session.shop_travel_refusal(3), ShopWords.PLUS_ONCE, "the first time")
	assert_eq(Session.shop_travel_refusal(3), ShopWords.PLUS_AGAIN, "then calm")
	assert_eq(Session.shop_travel_refusal(2), "", "the free universes always")
	Profile.data.purchases.append(ShopCatalog.PLUS)
	assert_eq(Session.shop_travel_refusal(3), "", "open with Plus")


# --- Over the code ---

func _files(dir: String, out: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_files(dir.path_join(d), out)


func test_only_the_grown_up_area_can_buy_or_show_a_price() -> void:
	var files: Array[String] = []
	for d in CHILD_DIRS:
		_files(d, files)
	assert_gt(files.size(), 50)
	var found: Array[String] = []
	for path in files:
		var text := FileAccess.get_file_as_string(path)
		for bad: String in ["ShopPage.new(", "reference_price(", "price_words(", "shop().buy(", "billing.buy(", "US$"]:
			if text.contains(bad):
				found.append("%s: %s" % [path, bad])
	assert_eq(found, [] as Array[String], "\n".join(found))
	var area := FileAccess.get_file_as_string("res://ui/online/grown_ups_panel.gd")
	assert_string_contains(area, "ShopPage.new(", "the grown-up area makes the shop page")
	var gate_users: Array[String] = []
	var all: Array[String] = []
	_files("res://ui", all)
	for path in all:
		if FileAccess.get_file_as_string(path).contains("GrownUpsPanel.new("):
			gate_users.append(path)
	for path in gate_users:
		var text := FileAccess.get_file_as_string(path)
		assert_string_contains(text, "GrownUpGate.new(", "%s opens the area only behind the parent gate" % path)
		assert_string_contains(text, "passed.connect(", path)


func test_a_build_without_a_store_locks_nothing() -> void:
	var s := ShopService.new()
	s.billing = Billing.new()   # what a release build has before Play Billing is turned on
	Session.use_shop(s)
	assert_false(Session.shop().store_open())
	assert_eq(Session.shop_travel_refusal(3), "", "Frostpeak stays open: nothing could be bought")
	Session.use_shop(null)
