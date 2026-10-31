extends GutTest
## Owner #37 (spec §14.23): the shop panel at a helper's stand and at Nico's market cart shows that trader's own
## things under its own name (no sections to wander in); Nico's cards carry the market's fixed prices and BUY goes
## through the host's market check. Tilly's shop stays as it was.

var _gold_before := 0
var _mode_before: StringName
var _universe_before := 1
var _player: Player
var _panel: ShopPanel


func before_each() -> void:
	_gold_before = Profile.data.survivor_gold
	_mode_before = Game.mode
	_universe_before = Game.universe
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 30
	_player = load("res://entities/player/player.tscn").instantiate()
	_player.name = str(multiplayer.get_unique_id())
	add_child_autofree(_player)
	_player.viewer.free()
	_player.set_physics_process(false)
	_player.global_position = Vector3(0.5, 30, -2.0)
	Session.set_inventory(_player.peer_id, Inventory.new())
	_panel = ShopPanel.new()
	add_child_autofree(_panel)
	_panel.player = _player


func after_each() -> void:
	Profile.data.survivor_gold = _gold_before
	Game.mode = _mode_before
	Game.universe = _universe_before
	Session.survivor_reset()


func _ids() -> Array[int]:
	var ids: Array[int] = []
	for c in _panel.cards():
		ids.append(c.id)
	return ids


func _tilly() -> Trader:
	var t := Trader.new()
	t.setup({"pos": Vector3(0.5, 30, 0.5), "yaw": 0.0, "hint": false})
	add_child_autofree(t)
	return t


func test_tillys_shop_is_as_it_was() -> void:
	_panel.open(_tilly())
	assert_eq(_panel.title_text(), "Tilly's Shop")
	assert_true(_panel.section_buttons[ShopRules.TOOLS].is_visible_in_tree())
	assert_eq(_ids(), ShopRules.catalog(ShopRules.TOOLS))


func test_a_stand_shows_its_universes_things_under_its_name() -> void:
	Game.universe = 2
	var s := TraderStand.new()
	s.setup({"pos": Vector3(0.5, 30, 0.5), "yaw": 0.0, "universe": 2})
	add_child_autofree(s)
	_panel.open(s)
	assert_eq(_panel.title_text(), "Zara's stand")
	assert_false(_panel.section_buttons[ShopRules.TOOLS].is_visible_in_tree(), "no sections at a stand")
	assert_eq(_ids(), StandRules.stock(2))
	var first := _panel.cards()[0]
	_panel.select(first.id)
	assert_eq(_panel._sel_price.text, GoldFormat.short(ShopRules.price(first.id, 2)))


func test_nicos_cart_shows_the_market_with_its_fixed_prices() -> void:
	var cart := MarketCart.new()
	cart.setup({"pos": Vector3(0.5, 30, 0.5), "yaw": 0.0})
	add_child_autofree(cart)
	_panel.open(cart)
	assert_eq(_panel.title_text(), MarketRules.SHOP_TITLE)
	assert_eq(_ids(), MarketRules.stock())
	var id := BlockIds.ROOF_TILES
	_panel.select(id)
	assert_eq(_panel._sel_price.text, GoldFormat.short(MarketRules.price(id)))
	assert_false(_panel.buy_button.disabled, "30 gold buys it")
	_panel.buy_button.pressed.emit()
	assert_eq(Session.inventory_of(_player.peer_id).count(id), MarketRules.amount(id), "bought through the host")
	assert_eq(Profile.data.survivor_gold, 30 - MarketRules.price(id))


func test_the_market_card_waits_for_gold() -> void:
	Profile.data.survivor_gold = 0
	var cart := MarketCart.new()
	cart.setup({"pos": Vector3(0.5, 30, 0.5), "yaw": 0.0})
	add_child_autofree(cart)
	_panel.open(cart)
	_panel.select(BlockIds.HAY)
	assert_true(_panel.buy_button.disabled)
	assert_eq(_panel.message_text(), ShopRules.message("gold"))


func test_back_at_tilly_the_shop_is_hers_again() -> void:
	var cart := MarketCart.new()
	cart.setup({"pos": Vector3(0.5, 30, 0.5), "yaw": 0.0})
	add_child_autofree(cart)
	_panel.open(cart)
	_panel.close()
	_panel.open(_tilly())
	assert_eq(_panel.title_text(), "Tilly's Shop")
	assert_eq(_ids(), ShopRules.catalog(_panel.section))
