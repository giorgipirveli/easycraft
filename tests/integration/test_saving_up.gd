extends GutTest
## M3 Task 21b (research R3): SAVE UP — at Tilly's shop and in the avatar editor a child who hasn't enough gold for
## something can put it on the saving list; the bar under the HUD's gold and the book's SAVING tab show the gold
## filling up. Buying it later takes it off. SAVE UP never spends gold.

var _p: ProfileData
var _gold_before := 0
var _mode_before: StringName
var _wonder_before: WonderData
var _owned_before: Array[String] = []


func before_each() -> void:
	_gold_before = Profile.data.survivor_gold
	_mode_before = Game.mode
	_wonder_before = Profile.data.wonder
	_owned_before = Profile.data.cosmetics.duplicate()
	Profile.data.cosmetics = [] as Array[String]   # another test may have given the shared profile a crown
	Game.mode = ModeRules.SURVIVOR
	Profile.data.wonder = WonderData.new()
	Profile.data.survivor_gold = 10
	_p = Profile.data


func after_each() -> void:
	Profile.data.survivor_gold = _gold_before
	Profile.data.wonder = _wonder_before
	Profile.data.cosmetics = _owned_before
	Game.mode = _mode_before
	Session.survivor_reset()


func _shop() -> ShopPanel:
	var shop := ShopPanel.new()
	add_child_autofree(shop)
	shop.open(null)
	shop._reach_timer.stop()
	return shop


func test_save_up_shows_when_the_gold_is_not_there_yet() -> void:
	var shop := _shop()
	shop.select(ItemIds.SWORD_CRYSTAL)
	assert_true(shop.buy_button.disabled, "10 gold is not enough")
	assert_true(shop.save_button.visible)
	assert_eq(shop.save_button.text, SavingRules.SAVE_WORD)
	shop.select(ItemIds.DUMMY)
	assert_false(shop.buy_button.disabled, "a 5-gold dummy is affordable")
	assert_false(shop.save_button.visible, "nothing to save up for")


func test_save_up_puts_it_on_the_list_and_spends_nothing() -> void:
	var shop := _shop()
	watch_signals(shop)
	shop.select(ItemIds.SWORD_CRYSTAL)
	shop.save_button.pressed.emit()
	assert_true(SavingRules.has(_p.wonder, SavingRules.SHOP, str(ItemIds.SWORD_CRYSTAL)))
	assert_eq(shop.save_button.text, SavingRules.SAVING_WORD)
	assert_eq(shop.message_text(), SavingRules.ON_WORDS)
	assert_eq(_p.survivor_gold, 10, "no gold spent")
	assert_signal_emitted(shop, "saving_changed")
	shop.save_button.pressed.emit()
	assert_false(SavingRules.has(_p.wonder, SavingRules.SHOP, str(ItemIds.SWORD_CRYSTAL)), "off again")


func test_buying_it_takes_it_off_the_list() -> void:
	var shop := _shop()
	SavingRules.toggle(_p.wonder, SavingRules.SHOP, str(ItemIds.DUMMY))
	shop.select(ItemIds.DUMMY)
	shop._on_trade_done(true, "You got a Practice Dummy!", ItemIds.DUMMY, 1, -5)
	assert_false(SavingRules.has(_p.wonder, SavingRules.SHOP, str(ItemIds.DUMMY)), "it came true")


func test_the_hud_bar_under_the_gold_follows_the_first_thing() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.add_secret_controls(null)
	hud.setup_books()
	assert_false(hud.saving_bar.visible, "nothing on the list: no bar")
	SavingRules.toggle(_p.wonder, SavingRules.LOOK, "hat.crown")
	hud.refresh_saving()
	assert_true(hud.saving_bar.visible)
	assert_eq(hud.saving_bar.words(), "10 / %d" % AvatarCatalog.price("hat.crown"))
	assert_true(hud.gold_counter.get_rect().encloses(Rect2(hud.gold_counter.position + hud.saving_bar.position,
		hud.saving_bar.size)), "inside the gold's own spot")
	Game.mode = ModeRules.SANDBOX
	hud.refresh_saving()
	assert_false(hud.saving_bar.visible, "Sandbox gold is endless: no bar")


func test_the_avatar_editor_shows_save_up_in_buys_place() -> void:
	var p := ProfileData.new()
	p.survivor_gold = 10
	var editor := AvatarEditor.new()
	editor.profile = p
	editor.save_profile = func() -> void: pass
	add_child_autofree(editor)
	editor.pick(AvatarCatalog.HAT, &"crown")
	assert_false(editor.buy_button.visible, "BUY makes way")
	assert_true(editor.save_button.visible)
	editor.save_button.pressed.emit()
	assert_true(SavingRules.has(p.wonder, SavingRules.LOOK, "hat.crown"))
	assert_eq(editor.save_button.text, SavingRules.SAVING_WORD)
	assert_eq(p.survivor_gold, 10)
	p.survivor_gold = 5000
	editor.refresh()
	assert_true(editor.buy_button.visible, "enough gold: BUY again")
	assert_false(editor.save_button.visible)
	editor.pick(AvatarCatalog.WINGS, &"phoenix")
	assert_false(editor.save_button.visible, "a pack item keeps owner #35's WISH")
