extends GutTest
## Owner #37 (spec §14.23): the TradeDirector (node "Trading" on every game). MORE → SHOP shows Tilly's way and
## distance and opens her shop when the child gets there; the first-time tip comes once; market day brings Nico's
## cart from sunrise to sunset (the host counts the days and tells every game); the universe's helper keeps a stand;
## a tap on another player's name tag opens their card (never a bot's); the ask card and the trade window follow the
## host. Survivor only.

const SCREENS: Array[Vector2i] = [Vector2i(2400, 1080), Vector2i(1334, 750)]

var me: Player
var hud: Hud
var layer: Control
var d: TradeDirector
var tilly: Trader
var pointed: Array = []
var stops: Array = []
var asked: Array = []
var sent: Array = []
var sent_to: Array = []
var clock := [DayCycle.NOON]
var _hints_before: Array[String] = []
var _mode_before: StringName
var _window_size: Vector2i


class AirWorld:
	extends WorldService

	func get_block(_pos: Vector3i) -> int:
		return BlockIds.AIR


func before_all() -> void:
	_window_size = get_window().size


func after_all() -> void:
	get_window().size = _window_size
	Audio.stop_all()


func before_each() -> void:
	_hints_before = Profile.data.hints_seen.duplicate()
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	pointed.clear()
	stops.clear()
	asked.clear()
	sent.clear()
	sent_to.clear()
	clock[0] = DayCycle.NOON
	me = _player(multiplayer.get_unique_id(), Vector3(0.5, 20, 0.5))
	hud = Hud.new()
	add_child_autofree(hud)
	hud.setup(me, "Kid", true, false)
	hud.add_secret_controls(null)   # the banners
	layer = Control.new()
	add_child_autofree(layer)
	tilly = Trader.new()
	tilly.setup({"pos": Vector3(0.5, 20, -40.5), "yaw": 0.0, "hint": false})
	add_child_autofree(tilly)
	d = _director(ModeRules.SURVIVOR, 1)


func after_each() -> void:
	Profile.data.hints_seen = _hints_before
	Game.mode = _mode_before
	Session.chat_names.erase(77)


func _player(peer: int, at: Vector3) -> Player:
	var w := AirWorld.new()
	autofree(w)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	p.world = w
	add_child_autofree(p)
	p.viewer.free()
	p.set_physics_process(false)
	p.global_position = at
	p._spawned = true
	p.visible = true
	return p


func _director(mode: StringName, universe: int) -> TradeDirector:
	var t := TradeDirector.new()
	t.mode = mode
	t.universe = universe
	t.world_seed = 42
	t.auto_tick = false
	t.time_of_day = func() -> float: return clock[0]
	t.point_at = func(what: String, pos: Vector3) -> void: pointed.append([what, pos])
	t.stop_arrow = func() -> void: stops.append(true)
	t.tilly = func() -> Node3D: return tilly if is_instance_valid(tilly) else null
	t.is_host = func() -> bool: return true
	t.ask = func(peer: int) -> void: asked.append(peer)
	t.send_market = func(on: bool, pos: Vector3, yaw: float) -> void: sent.append([on, pos, yaw])
	t.send_market_to = func(peer: int, on: bool, pos: Vector3, yaw: float) -> void: sent_to.append([peer, on, pos, yaw])
	add_child_autofree(t)
	t.setup_local(me, hud, layer, me.get_node("BlockInteractor") as BlockInteractor)
	return t


# --- MORE → SHOP ---

func test_shop_is_in_more_in_survivor_only() -> void:
	assert_not_null(d.more_button)
	assert_has(hud.more.buttons(), d.more_button)
	assert_eq(d.more_button.text, "SHOP")
	assert_true(HudIcons.knows(d.more_button.symbol))
	var sandbox_hud := Hud.new()
	add_child_autofree(sandbox_hud)
	sandbox_hud.setup(me, "Kid", true, false)
	var s := TradeDirector.new()
	s.mode = ModeRules.SANDBOX
	s.auto_tick = false
	add_child_autofree(s)
	s.setup_local(me, sandbox_hud, layer, null)
	assert_null(s.more_button, "no shop in the Sandbox")
	assert_false(s.tap_name_tag(Vector2(10, 10)), "no trading in the Sandbox")


func test_the_shop_card_shows_tilly_with_the_distance_and_the_way() -> void:
	me.rig.yaw = 0.0   # looking along -Z, at Tilly
	d.more_button.pressed.emit()
	assert_true(d.shop_menu.is_open())
	assert_eq(d.shop_menu.rows.size(), 1)
	var r: Dictionary = d.shop_menu.rows[0]
	assert_eq(r.shop.what, "Tilly")
	assert_eq((r.distance as Label).text, "41 m")
	assert_almost_eq((r.arrow as ShopMenu.WayArrow).angle, 0.0, 0.05, "straight ahead")
	assert_eq((r.button as Button).text, ShopMenu.WAY_WORDS)
	(r.button as Button).pressed.emit()
	assert_false(d.shop_menu.is_open())
	assert_eq(pointed, [["Tilly", tilly.global_position]], "the find arrow points at her")
	assert_eq(d.guiding(), tilly)


func test_arriving_opens_her_shop_and_the_arrow_stops() -> void:
	d.guide_to("Tilly", tilly)
	d.guide_tick()
	assert_false(hud.shop.visible, "not there yet")
	me.global_position = tilly.global_position + Vector3(0, 0, 3)
	d.guide_tick()
	assert_true(hud.shop.visible, "there: her shop opens by itself")
	assert_eq(stops.size(), 1)
	assert_null(d.guiding())


func test_close_by_the_card_opens_the_shop() -> void:
	me.global_position = tilly.global_position + Vector3(0, 0, 3)
	d.shop_menu.open_menu()
	var b: Button = d.shop_menu.rows[0].button
	assert_eq(b.text, ShopMenu.OPEN_WORDS)
	b.pressed.emit()
	assert_true(hud.shop.visible)
	assert_true(pointed.is_empty())


func test_a_nearer_villager_who_trades_is_the_way() -> void:
	var v := Villager.new()
	v.setup({"pos": Vector3(0.5, 20, 20.5), "yaw": 0.0, "look": 1, "name": "Rosa", "trades": true})
	add_child_autofree(v)
	d.shop_menu.open_menu()
	assert_eq(d.shop_menu.rows[0].shop.what, "Rosa")
	assert_eq(d.shop_menu.rows[0].shop.trader, v)


func test_the_first_time_tip_comes_once() -> void:
	Profile.data.hints_seen.erase(ShopGuide.TIP)
	d.maybe_tip()
	assert_has(Profile.data.hints_seen, ShopGuide.TIP)
	assert_true(hud.picture_hint.visible)
	assert_eq(d.guiding(), tilly, "the arrow points at Tilly")
	me.global_position = tilly.global_position + Vector3(0, 0, 3)
	d.guide_tick()
	assert_false(hud.shop.visible, "the tip only shows the way")
	pointed.clear()
	d.maybe_tip()
	assert_true(pointed.is_empty(), "once per profile")


# --- Market day ---

func _tick_at(t: float) -> void:
	clock[0] = t
	d.tick()


func _next_day(at: float = DayCycle.NOON) -> void:
	_tick_at(0.95)
	_tick_at(DayCycle.SUNRISE + 0.01)
	_tick_at(at)


func test_market_day_brings_nicos_cart_from_sunrise_to_sunset() -> void:
	var spot := Vector3(6.5, 20, -40.5)
	d._set_cart_spot({"pos": spot, "yaw": 0.3})
	d.market = {"day": 1}
	_tick_at(DayCycle.NOON)
	assert_null(d.cart, "day 1: no market")
	_next_day(DayCycle.SUNRISE + 0.02)
	assert_eq(d.market_save(), {"day": 2})
	assert_not_null(d.cart, "day 2: Nico came at sunrise")
	assert_true(d.cart.is_in_group(&"market_traders"))
	assert_eq(d.cart.global_position, spot)
	assert_eq(sent, [[true, spot, 0.3]], "every game is told")
	assert_eq(hud.banner.showing(), MarketRules.ARRIVED)
	_tick_at(DayCycle.NOON)
	assert_not_null(d.cart)
	_tick_at(DayCycle.SUNSET + 0.01)
	assert_null(d.cart, "gone at sunset")
	assert_eq(sent.back()[0], false)
	for i in 6:
		_next_day()
	assert_eq(int(d.market.day), 8)
	assert_null(d.cart)
	_next_day()
	assert_not_null(d.cart, "day 9: market day again, a week later")


func test_the_shop_card_shows_nico_on_market_day() -> void:
	d.set_market(true, Vector3(6.5, 20, -40.5), 0.0)
	d.shop_menu.open_menu()
	assert_eq(d.shop_menu.rows.size(), 2)
	assert_eq(d.shop_menu.rows[1].shop.what, MarketRules.SHOP_TITLE)


func test_a_guest_builds_the_cart_it_is_told_about() -> void:
	var g := _director(ModeRules.SURVIVOR, 1)
	g.is_host = func() -> bool: return false
	g._rpc_market(true, Vector3(3, 20, 3), 0.0)
	assert_not_null(g.cart)
	g.tick()
	assert_not_null(g.cart, "a guest never decides the market itself")
	g._rpc_market(false, Vector3.INF, 0.0)
	assert_null(g.cart)


func test_a_guest_who_arrives_hears_the_market() -> void:
	d.set_market(true, Vector3(6.5, 20, -40.5), 0.0)
	d.on_client_ready(77)
	assert_eq(sent_to, [[77, true, Vector3(6.5, 20, -40.5), 0.0]])


# --- The helper's stand ---

func test_the_universe_helper_keeps_a_stand_beside_them() -> void:
	var z := _director(ModeRules.SURVIVOR, 2)
	var shape := UniverseRegistry.shape_for(2, 42)
	z.setup_world(shape)
	var spot := QuestRules.giver_for_world(42, shape, shape.spawn_column())
	var zara := Node3D.new()
	add_child_autofree(zara)
	zara.global_position = spot.pos
	z.giver = func(id: StringName) -> Node3D: return zara if id == &"zara" else null
	z.tick()
	for i in 600:
		if z.stand != null:
			break
		await get_tree().process_frame
	assert_not_null(z.stand, "Zara's stand (a worker thread finds its spot)")
	assert_true(z.stand.is_in_group(&"traders"))
	assert_eq(z.stand.universe, 2)
	var off := Vector2(z.stand.global_position.x - zara.global_position.x, z.stand.global_position.z - zara.global_position.z)
	assert_between(off.length(), 1.5, 3.8, "beside her")
	var m := _director(ModeRules.SURVIVOR, 1)
	m.setup_world(UniverseRegistry.shape_for(1, 42))
	m.giver = func(_id: StringName) -> Node3D: return zara
	m.tick()
	await get_tree().process_frame
	assert_null(m.stand, "Green Meadows' stand is Tilly's stall")


# --- Players ---

func _bob(at: Vector3) -> Player:
	Session.chat_names[77] = "Bob"
	var bob := _player(77, at)
	var tag := bob.get_node_or_null("NameTag") as Label3D   # every other player wears one
	if tag == null:
		tag = NameTag.new()
		(tag as NameTag).player = bob
		bob.add_child(tag)
	tag.text = "Bob"   # its words come twice a second
	return bob


func test_a_tap_on_a_name_tag_opens_that_players_card() -> void:
	var bob := _bob(Vector3(0.5, 20, -4.5))
	var tag := bob.get_node("NameTag") as Label3D
	var eye := me.eye_position()
	var hit := d.name_tag_hit(eye, (tag.global_position - eye).normalized(), eye)
	assert_eq(hit, bob)
	assert_null(d.name_tag_hit(eye, Vector3.FORWARD.rotated(Vector3.UP, 1.0), eye), "a tap elsewhere")
	bob.global_position = Vector3(0.5, 20, -30.5)
	assert_null(d.name_tag_hit(eye, (tag.global_position - eye).normalized(), eye), "too far to tap")
	d.player_card.open_for(77, "Bob")
	assert_true(d.player_card.is_open())
	d.player_card.trade_button.pressed.emit()
	assert_eq(asked, [77], "TRADE asks Bob")


func test_the_shop_card_lists_players_to_trade_with_never_bots() -> void:
	_bob(Vector3(10, 20, 10))
	var bot := Node3D.new()
	bot.add_to_group(&"bot_friends")
	bot.add_to_group(&"bots")
	add_child_autofree(bot)
	assert_eq(d.other_players(), [{"peer": 77, "name": "Bob"}])
	d.shop_menu.open_menu()
	assert_true(d.shop_menu.trade_buttons.has(77))
	assert_eq(d.shop_menu.trade_buttons.size(), 1)
	(d.shop_menu.trade_buttons[77] as Button).pressed.emit()
	assert_eq(asked, [77])


func test_the_ask_card_and_the_trade_window_follow_the_host() -> void:
	var answers: Array = []
	d.ask_card.answer = func(peer: int, yes: bool) -> void: answers.append([peer, yes])
	Session.player_trade_asked.emit(77, "Bob")
	assert_true(d.ask_card.is_open())
	assert_has(d.ask_card.texts(), "Bob would like to trade.")
	d.ask_card.yes_button.pressed.emit()
	assert_eq(answers, [[77, true]])
	var state := {"id": 1, "other": 77, "name": "Bob", "mine": {"items": [], "gold": 0},
		"theirs": {"items": [[BlockIds.DIAMOND, 1]], "gold": 0}, "my_ready": false, "their_ready": false}
	Session.player_trade_changed.emit(state)
	assert_true(d.trade_window.is_open())
	Session.player_trade_note.emit("Bob has no room for that many Stone.")
	assert_eq(d.trade_window.message.text, "Bob has no room for that many Stone.")
	Session.player_trade_ended.emit(true, TradeRules.message("done"))
	assert_false(d.trade_window.is_open())
	assert_eq(hud._toast_label.text, TradeRules.message("done"))


func test_no_thanks_and_a_tap_outside_both_say_no() -> void:
	var answers: Array = []
	d.ask_card.answer = func(peer: int, yes: bool) -> void: answers.append([peer, yes])
	Session.player_trade_asked.emit(77, "Bob")
	d.ask_card.no_button.pressed.emit()
	Session.player_trade_asked.emit(77, "Bob")
	d.ask_card.close()   # a finger outside the card
	assert_eq(answers, [[77, false], [77, false]])
	Session.player_trade_asked.emit(77, "Bob")
	Session.player_trade_ask_gone.emit(77)
	assert_false(d.ask_card.is_open())
	assert_eq(answers.size(), 2, "an ask taken back needs no answer")


func test_back_stops_a_trade() -> void:
	var cancels: Array = []
	d.trade_window.send_cancel = func() -> void: cancels.append(true)
	Session.player_trade_changed.emit({"id": 1, "other": 77, "name": "Bob", "mine": {"items": [], "gold": 0},
		"theirs": {"items": [], "gold": 0}, "my_ready": false, "their_ready": false})
	assert_true(d.close_pages())
	assert_eq(cancels, [true])
	assert_false(d.close_pages(), "nothing left to close")


# --- The MORE panel with every entry ---

func test_the_more_panel_with_every_entry_fits_both_screens() -> void:
	for screen in SCREENS:
		get_window().size = screen
		var h := Hud.new()
		add_child_autofree(h)
		h.setup(me, "Kid", true, true)
		for extra: Array in [["QUESTS", &"quests"], ["MAP", &"map"], ["SHARE", &"gift"]]:
			var b := TouchButton.new()
			b.text = extra[0]
			b.symbol = extra[1]
			h.more.add(b, true)
		var t := TradeDirector.new()
		t.mode = ModeRules.SURVIVOR
		t.auto_tick = false
		add_child_autofree(t)
		t.setup_local(me, h, layer, null)
		h.more.open()
		await wait_process_frames(2)
		UiMotion.settle(h.more)   # owner #94: measured at rest, not mid-pop
		var view := Rect2(Vector2.ZERO, h.get_viewport_rect().size)
		var box := h.more.box.get_global_rect()
		assert_true(view.encloses(box), "%s: the panel is on the screen (%s)" % [screen, box])
		var inside := h.more.buttons()
		assert_has(inside, t.more_button)
		for b in inside:
			var r := b.get_global_rect()
			assert_gte(minf(r.size.x, r.size.y), HudLayout.BUTTON_MIN, "%s: %s is big" % [screen, b.text])
			assert_true(box.encloses(r), "%s: %s is in the box" % [screen, b.text])
			for other in inside:
				if other != b:
					assert_false(r.intersects(other.get_global_rect()), "%s: %s overlaps %s" % [screen, b.text, other.text])
		h.more.close()


# --- M3 Task 15: the tutorial's Tilly step reuses the tip ---

func test_the_tutorial_holds_the_first_time_tip() -> void:
	Profile.data.hints_seen.erase(ShopGuide.TIP)
	d.hold_tip = func() -> bool: return true   # Pip's offer or lessons are on
	d.maybe_tip()
	assert_false(Profile.data.hints_seen.has(ShopGuide.TIP), "still to come")
	assert_false(hud.picture_hint.visible)
	assert_null(d.guiding())
	d.hold_tip = func() -> bool: return false   # skipped or stopped: the tip comes as before
	d.maybe_tip()
	assert_has(Profile.data.hints_seen, ShopGuide.TIP)
	assert_eq(d.guiding(), tilly)


func test_the_tutorials_tilly_step_shows_the_same_tip_even_when_seen() -> void:
	if not Profile.data.hints_seen.has(ShopGuide.TIP):
		Profile.data.hints_seen.append(ShopGuide.TIP)
	assert_true(d.show_tip(), "Tilly is there")
	assert_true(hud.picture_hint.visible, "the same picture tip")
	assert_eq(hud.picture_hint.label.text, ShopGuide.TIP_TEXT)
	assert_eq(d.guiding(), tilly, "and the SHOP arrow at her")
	assert_eq(Profile.data.hints_seen.count(ShopGuide.TIP), 1)


## Spec §17.3 "Safety in the world": the card opens in every world with other players, not only Survivor; TRADE is
## Survivor's.
func test_the_card_opens_in_the_sandbox_too_without_trade() -> void:
	var sd := _director(ModeRules.SANDBOX, 1)
	assert_not_null(sd.player_card, "a card in every world")
	Session.chat_names[77] = "Bob"
	sd.open_card(77)
	assert_true(sd.player_card.is_open())
	assert_false(sd.player_card.can_trade, "no trading in the Sandbox")
	assert_null(sd.player_card.find_child("TradeButton", true, false))
