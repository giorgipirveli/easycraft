extends GutTest
## M2 Task 7: Tilly's shop panel (a centred overlay): BUY and SELL tabs, the Buy tab's sections,
## picture cards with a coin and a short price, a have/need bar under prices the player can't afford
## yet, icon-first buttons with a small word under each, and trades that go through the host.

const SCREEN := Vector2(1280, 720)

var _gold_before := 0
var _mode_before: StringName
var _player: Player
var _tilly: Trader
var _panel: ShopPanel


func before_each() -> void:
	_gold_before = Profile.data.survivor_gold
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 30
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	_player = load("res://entities/player/player.tscn").instantiate()
	_player.name = str(multiplayer.get_unique_id())
	_player.world = world
	add_child_autofree(_player)
	_player.viewer.free()
	_player.set_physics_process(false)
	_tilly = Trader.new()
	_tilly.setup({"pos": Vector3(0.5, 30, 0.5), "yaw": 0.0, "hint": false})
	add_child_autofree(_tilly)
	_player.global_position = Vector3(0.5, 30, -2.0)
	Session.set_inventory(_player.peer_id, Inventory.new())
	_panel = ShopPanel.new()
	add_child_autofree(_panel)
	_panel.player = _player


func after_each() -> void:
	Profile.data.survivor_gold = _gold_before
	Game.mode = _mode_before
	Session.survivor_reset()


func _inv() -> Inventory:
	return Session.inventory_of(_player.peer_id)


func _ids(cards: Array[ShopCard]) -> Array[int]:
	var ids: Array[int] = []
	for c in cards:
		ids.append(c.id)
	return ids


func test_it_opens_on_the_buy_tab_with_tools_and_the_players_gold() -> void:
	watch_signals(_panel)
	_panel.open(_tilly)
	assert_true(_panel.visible)
	assert_signal_emitted(_panel, "opened")
	assert_eq(_panel.tab, ShopPanel.BUY)
	assert_eq(_panel.section, ShopRules.TOOLS)
	assert_eq(_ids(_panel.cards()), ShopRules.catalog(ShopRules.TOOLS))
	assert_eq(_panel.gold_text(), "30")


func test_the_panel_is_centred_and_fits_the_screen() -> void:
	var box := _panel.panel_rect(SCREEN)
	assert_true(Rect2(Vector2.ZERO, SCREEN).encloses(box))
	assert_almost_eq(box.get_center().x, SCREEN.x * 0.5, 1.0)
	assert_almost_eq(box.get_center().y, SCREEN.y * 0.5, 1.0)


func test_prices_are_short_numbers_with_a_coin() -> void:
	_panel.open(_tilly)
	_panel.show_section(ShopRules.HOME)
	assert_eq(_panel.card_for(BlockIds.BED).price_text(), "20")
	_panel.show_section(ShopRules.BLOCKS)
	var planks := _panel.card_for(BlockIds.PLANKS)
	assert_eq(planks.price_text(), "1")
	assert_eq(planks.badge_text(), "×4", "four blocks for the price")


## M2 Task 8: doors come in pairs (a doorway); the card says so, and so does the footer.
func test_a_door_card_shows_a_pair() -> void:
	_panel.open(_tilly)
	_panel.show_section(ShopRules.HOME)
	var door := _panel.card_for(BlockIds.DOOR)
	assert_eq(door.price_text(), "10")
	assert_eq(door.badge_text(), "×2")
	assert_eq(_panel.card_for(BlockIds.LANTERN).badge_text(), "")
	assert_eq(_panel.card_for(BlockIds.SPIKE_TRAP).price_text(), "15")


func test_prices_you_cannot_afford_yet_show_a_have_need_bar() -> void:
	Profile.data.survivor_gold = 3
	_panel.open(_tilly)
	_panel.show_section(ShopRules.HOME)
	var bed := _panel.card_for(BlockIds.BED)
	assert_true(bed.need_visible())
	assert_eq(bed.need_text(), "3 / 20")
	assert_almost_eq(bed.need_ratio(), 0.15, 0.001)
	assert_false(_panel.card_for(BlockIds.BUSH).need_visible(), "3 gold buys a bush")
	Session.gold_changed.emit(25)
	assert_false(_panel.card_for(BlockIds.BED).need_visible(), "updates when the gold changes")


func test_buying_goes_through_the_host() -> void:
	_panel.open(_tilly)
	_panel.show_section(ShopRules.HOME)
	_panel.select(BlockIds.LANTERN)
	assert_false(_panel.buy_button.disabled)
	_panel.buy_button.pressed.emit()
	assert_eq(Profile.data.survivor_gold, 25)
	assert_eq(_inv().count(BlockIds.LANTERN), 1)
	assert_eq(_panel.message_text(), "You got a Lantern!")
	assert_eq(_panel.gold_text(), "25")


func test_a_tool_you_have_is_marked_and_not_sold_again() -> void:
	_inv().add(ItemIds.SWORD, 1)
	_panel.open(_tilly)
	var sword := _panel.card_for(ItemIds.SWORD)
	assert_true(sword.owned)
	_panel.select(ItemIds.SWORD)
	assert_true(_panel.buy_button.disabled)
	assert_eq(_panel.message_text(), ShopRules.message("have_it"))


func test_without_enough_gold_the_buy_button_waits() -> void:
	Profile.data.survivor_gold = 3
	_panel.open(_tilly)
	_panel.show_section(ShopRules.HOME)
	_panel.select(BlockIds.BED)
	assert_true(_panel.buy_button.disabled)
	assert_eq(_panel.message_text(), ShopRules.message("gold"))


func test_the_sell_tab_lists_what_tilly_buys_and_sells_it() -> void:
	_inv().add(BlockIds.COAL, 7)
	_inv().add(BlockIds.DIAMOND, 2)
	_inv().add(BlockIds.DIRT, 50)
	_panel.open(_tilly)
	_panel.show_tab(ShopPanel.SELL)
	assert_eq(_ids(_panel.cards()), [BlockIds.COAL, BlockIds.DIAMOND] as Array[int])
	assert_eq(_panel.card_for(BlockIds.COAL).badge_text(), "×7")
	assert_eq(_panel.card_for(BlockIds.DIAMOND).price_text(), "20")
	_panel.select(BlockIds.DIAMOND)
	_panel.sell_all_button.pressed.emit()
	assert_eq(Profile.data.survivor_gold, 70)
	assert_eq(_panel.message_text(), "Sold! +40 gold")
	assert_eq(_ids(_panel.cards()), [BlockIds.COAL] as Array[int], "the diamonds are gone")
	_panel.select(BlockIds.COAL)
	_panel.sell_one_button.pressed.emit()
	assert_eq(_inv().count(BlockIds.COAL), 6)


func test_buttons_are_icon_first_with_a_small_word_under() -> void:
	for b: Button in [_panel.buy_tab, _panel.sell_tab, _panel.buy_button, _panel.sell_one_button, _panel.sell_all_button]:
		assert_not_null(b.icon, b.text)
		assert_ne(b.text, "")
		assert_lte(b.text.length(), 8, "a small word: %s" % b.text)
		assert_eq(b.vertical_icon_alignment, VERTICAL_ALIGNMENT_TOP, "icon above the word: %s" % b.text)
	for section: StringName in ShopRules.SECTIONS:
		var b: Button = _panel.section_buttons[section]
		assert_not_null(b.icon, String(section))
		assert_eq(b.vertical_icon_alignment, VERTICAL_ALIGNMENT_TOP)


func test_every_card_has_a_picture() -> void:
	_inv().add(BlockIds.COAL, 1)
	_panel.open(_tilly)
	for section: StringName in ShopRules.SECTIONS:
		_panel.show_section(section)
		for c in _panel.cards():
			assert_not_null(c.icon_texture(), "id %d" % c.id)


func test_closing() -> void:
	_panel.open(_tilly)
	watch_signals(_panel)
	_panel.close_button.pressed.emit()
	assert_false(_panel.visible)
	assert_signal_emitted(_panel, "closed")


func test_the_hud_opens_the_shop_when_tilly_is_tapped() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(_player, "Kid", false, false)
	assert_lt(hud.shop.get_index(), hud.palette.get_index(), "the block palette overlay stays on top")
	assert_gt(hud.shop.get_index(), hud.hotbar.get_index(), "over the game's controls")
	assert_false(hud.shop.visible)
	hud.palette.open()
	_player.get_node("BlockInteractor").trader_tapped.emit(_tilly)
	assert_true(hud.shop.visible)
	assert_false(hud.palette.visible, "one overlay at a time")
	assert_has(hud.look_area.blockers, hud.shop, "touches on the shop never build behind it")


func test_walking_away_closes_the_shop() -> void:
	_panel.open(_tilly)
	_panel.check_reach()
	assert_true(_panel.visible, "still near")
	_player.global_position = Vector3(0.5, 30, -20)
	_panel.check_reach()
	assert_false(_panel.visible)
