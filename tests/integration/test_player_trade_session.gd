extends GutTest
## Owner #37 (spec §14.23): trading between players, decided by the host (Session section "Trading"). Nothing
## opens without YES; both put things in; every change makes both not ready; both READY swaps at once, all or
## nothing, checked against the real bags and purses; X or leaving stops it and nothing moved; a guest's requests are
## checked like the host's own; online, under-13 players trade only with their friends; bots are not players.

const GUEST := 77

var _gold_before := 0
var _mode_before: StringName
var _universe_before := 1
var host: Player
var guest: Player
var to_guest: Array = []        # [kind, args] the host sent the guest's game
var asked: Array = []           # this game (the host's player): [peer, name]
var states: Array = []
var ended: Array = []
var notes: Array = []
var lines: Array = []


func before_each() -> void:
	_gold_before = Profile.data.survivor_gold
	_mode_before = Game.mode
	_universe_before = Game.universe
	Game.mode = ModeRules.SURVIVOR
	Game.universe = 1
	Profile.data.survivor_gold = 100
	for a: Array in [to_guest, asked, states, ended, notes, lines]:
		a.clear()
	host = _player(multiplayer.get_unique_id(), Vector3(0.5, 20, 0.5))
	guest = _player(GUEST, Vector3(3.5, 20, 0.5))
	Session.set_inventory(host.peer_id, Inventory.new())
	Session.set_inventory(GUEST, Inventory.new())
	Session._wallets[GUEST] = Wallet.new(40)
	Session._host_chat_join(host.peer_id, "Ann", "13_plus")
	Session._host_chat_join(GUEST, "Bob", "13_plus")
	Session.trade_tap = func(peer: int, kind: StringName, args: Array) -> void:
		if peer == GUEST:
			to_guest.append([kind, args])
	Session.trade_now_ms = func() -> int: return 100_000
	Session.player_trade_asked.connect(_on_asked)
	Session.player_trade_changed.connect(_on_state)
	Session.player_trade_ended.connect(_on_ended)
	Session.player_trade_note.connect(_on_note)
	Session.chat_received.connect(_on_line)


func after_each() -> void:
	Session.player_trade_asked.disconnect(_on_asked)
	Session.player_trade_changed.disconnect(_on_state)
	Session.player_trade_ended.disconnect(_on_ended)
	Session.player_trade_note.disconnect(_on_note)
	Session.chat_received.disconnect(_on_line)
	Session.trade_reset_hooks()
	Session.survivor_reset()
	Session.chat_reset()
	Profile.data.survivor_gold = _gold_before
	Game.mode = _mode_before
	Game.universe = _universe_before


func _player(peer: int, at: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.viewer.free()
	p.set_physics_process(false)
	p.global_position = at
	return p


func _on_asked(peer: int, from_name: String) -> void:
	asked.append([peer, from_name])


func _on_state(state: Dictionary) -> void:
	states.append(state)


func _on_ended(done: bool, text: String) -> void:
	ended.append([done, text])


func _on_note(text: String) -> void:
	notes.append(text)


func _on_line(_from: String, text: String, _kind: StringName) -> void:
	lines.append(text)


func _me() -> int:
	return host.peer_id


func _guest_got(kind: StringName) -> Array:
	var out: Array = []
	for e: Array in to_guest:
		if e[0] == kind:
			out.append(e[1])
	return out


## The host's child asks the guest, and the guest says YES.
func _open() -> void:
	Session.player_trade_ask(GUEST)
	Session.host_trade_answer(GUEST, _me(), true)


func _bags() -> Array:
	var a := Session.inventory_of(_me())
	var b := Session.inventory_of(GUEST)
	return [a.to_save(), b.to_save(), Session.gold_of(_me()), Session.gold_of(GUEST)]


# --- Asking ---

func test_nothing_opens_until_the_other_says_yes() -> void:
	Session.player_trade_ask(GUEST)
	assert_eq(_guest_got(&"asked"), [[_me(), "Ann"]], "Bob is asked, with Ann's name")
	assert_true(Session.trade_table.trade_of(_me()).is_empty(), "no trade yet")
	assert_eq(notes, [TradeRules.message("asked", "Bob")])
	Session.host_trade_answer(GUEST, _me(), false)
	assert_true(Session.trade_table.trade_of(_me()).is_empty())
	assert_has(notes, TradeRules.message("said_no", "Bob"))


func test_yes_opens_the_same_trade_on_both_games() -> void:
	_open()
	assert_false(Session.trade_table.trade_of(_me()).is_empty())
	assert_eq(states.size(), 1)
	assert_eq(states[0].name, "Bob")
	assert_eq(states[0].other, GUEST)
	var g: Array = _guest_got(&"state")
	assert_eq(g.size(), 1)
	assert_eq(g[0][0].name, "Ann")


func test_a_guest_asks_and_the_host_answers() -> void:
	Session.host_trade_ask(GUEST, _me())
	assert_eq(asked, [[GUEST, "Bob"]])
	Session.player_trade_answer(GUEST, true)
	assert_false(Session.trade_table.trade_of(GUEST).is_empty())


func test_only_the_one_asked_can_say_yes() -> void:
	Session.player_trade_ask(GUEST)
	Session.host_trade_answer(_me(), GUEST, true)   # the asker can't answer its own ask
	assert_true(Session.trade_table.trade_of(_me()).is_empty())
	Session.host_trade_answer(4242, _me(), true)
	assert_true(Session.trade_table.trade_of(_me()).is_empty())


# --- The swap ---

func test_both_ready_swaps_at_once_and_both_get_a_chat_line() -> void:
	Session.inventory_of(_me()).add(BlockIds.STONE, 20)
	Session.inventory_of(GUEST).add(ItemIds.SWORD_IRON, 1)
	_open()
	Session.player_trade_offer([[BlockIds.STONE, 10]], 5)
	Session.host_trade_offer(GUEST, [[ItemIds.SWORD_IRON, 1]], 0)
	Session.player_trade_ready(true)
	assert_eq(Session.inventory_of(_me()).count(BlockIds.STONE), 20, "nothing moves until both are ready")
	Session.host_trade_ready(GUEST, true)
	for e in get_errors():   # Bob's new gold goes to his game by RPC, and in a test there is no network peer 77
		e.handled = true
	assert_eq(Session.inventory_of(_me()).count(BlockIds.STONE), 10)
	assert_eq(Session.inventory_of(_me()).count(ItemIds.SWORD_IRON), 1)
	assert_eq(Session.inventory_of(GUEST).count(BlockIds.STONE), 10)
	assert_eq(Session.inventory_of(GUEST).count(ItemIds.SWORD_IRON), 0)
	assert_eq(Profile.data.survivor_gold, 95)
	assert_eq(Session.gold_of(GUEST), 45)
	assert_eq(ended, [[true, TradeRules.message("done")]])
	assert_eq(_guest_got(&"ended"), [[true, TradeRules.message("done")]])
	var sword := ItemIds.display_name(ItemIds.SWORD_IRON)
	assert_has(lines, "You traded with Bob: you gave 10 Stone and 5 gold; you got 1 %s." % sword)
	assert_eq(_guest_got(&"line"), [["You traded with Ann: you gave 1 %s; you got 10 Stone and 5 gold." % sword]])
	assert_true(Session.trade_table.trade_of(_me()).is_empty(), "the trade is over")
	Session.host_trade_ready(GUEST, true)
	assert_eq(Session.inventory_of(GUEST).count(BlockIds.STONE), 10, "a second READY swaps nothing")


func test_every_change_makes_both_not_ready() -> void:
	Session.inventory_of(_me()).add(BlockIds.STONE, 20)
	Session.inventory_of(GUEST).add(BlockIds.DIRT, 5)
	_open()
	Session.player_trade_offer([[BlockIds.STONE, 10]], 0)
	Session.player_trade_ready(true)
	Session.host_trade_offer(GUEST, [[BlockIds.DIRT, 1]], 0)
	assert_false(states.back().my_ready, "Bob's change made Ann not ready")
	Session.host_trade_ready(GUEST, true)
	assert_eq(Session.inventory_of(_me()).count(BlockIds.STONE), 20, "no swap: Ann has not seen Bob's new offer")


func test_x_stops_the_trade_and_nothing_changed() -> void:
	Session.inventory_of(_me()).add(BlockIds.STONE, 20)
	_open()
	Session.player_trade_offer([[BlockIds.STONE, 10]], 30)
	var before := _bags()
	Session.player_trade_cancel()
	assert_eq(_bags(), before, "everything is where it was")
	assert_eq(ended, [[false, TradeRules.message("stopped")]])
	assert_eq(_guest_got(&"ended"), [[false, TradeRules.message("stopped")]])
	assert_true(Session.trade_table.trade_of(GUEST).is_empty())


func test_one_leaves_and_the_trade_stops() -> void:
	Session.inventory_of(_me()).add(BlockIds.STONE, 20)
	_open()
	Session.player_trade_offer([[BlockIds.STONE, 10]], 0)
	var before := _bags()
	Session.peer_left.emit(GUEST)
	assert_eq(ended, [[false, TradeRules.message("left", "Bob")]])
	assert_eq(_bags(), before)
	assert_true(Session.trade_table.trade_of(_me()).is_empty())


func test_an_ask_goes_away_when_the_asker_leaves() -> void:
	var gone: Array = []
	var f := func(p: int) -> void: gone.append(p)
	Session.player_trade_ask_gone.connect(f)
	Session.host_trade_ask(GUEST, _me())
	Session.peer_left.emit(GUEST)
	Session.player_trade_ask_gone.disconnect(f)
	assert_eq(gone, [GUEST])


func test_a_full_bag_stops_the_swap_and_says_why() -> void:
	Session.inventory_of(_me()).add(BlockIds.STONE, 20)
	Session.inventory_of(GUEST).add(BlockIds.STONE, 995)
	_open()
	Session.player_trade_offer([[BlockIds.STONE, 10]], 0)
	var before := _bags()
	Session.player_trade_ready(true)
	Session.host_trade_ready(GUEST, true)
	assert_eq(_bags(), before, "nothing moved")
	assert_has(notes, TradeRules.message("no_room", "Bob", BlockIds.STONE))
	assert_has(_guest_got(&"note"), [TradeRules.message("no_room_you", "", BlockIds.STONE)])
	assert_false(Session.trade_table.trade_of(_me()).is_empty(), "the trade stays open to change")
	assert_false(states.back().my_ready)


func test_you_can_only_offer_what_you_own() -> void:
	Session.inventory_of(_me()).add(BlockIds.STONE, 10)
	Session.inventory_of(_me()).add(ItemIds.CRYSTAL_MEADOWS, 1)
	_open()
	Session.player_trade_offer([[BlockIds.STONE, 50], [ItemIds.CRYSTAL_MEADOWS, 1], [BlockIds.DIAMOND, 3]], 500)
	var mine: Dictionary = states.back().mine
	assert_eq(mine.items, [[BlockIds.STONE, 10]], "clamped to the bag; a crystal never trades")
	assert_eq(mine.gold, 100, "at most the gold Ann has")


func test_things_used_up_meanwhile_shrink_the_offer() -> void:
	Session.inventory_of(_me()).add(BlockIds.STONE, 10)
	_open()
	Session.player_trade_offer([[BlockIds.STONE, 10]], 0)
	Session.player_trade_ready(true)
	Session.inventory_of(_me()).take(BlockIds.STONE, 6)   # placed as blocks
	Session.player_trade_tick()
	assert_eq(states.back().mine.items, [[BlockIds.STONE, 4]])
	assert_false(states.back().my_ready)
	assert_has(notes, TradeRules.message("changed"))


func test_a_last_moment_check_makes_copies_impossible() -> void:
	Session.inventory_of(_me()).add(BlockIds.DIAMOND, 5)
	Session.inventory_of(GUEST).add(BlockIds.STONE, 5)
	_open()
	Session.player_trade_offer([[BlockIds.DIAMOND, 5]], 0)
	Session.host_trade_offer(GUEST, [[BlockIds.STONE, 5]], 0)
	Session.player_trade_ready(true)
	Session.inventory_of(_me()).take(BlockIds.DIAMOND, 5)   # gone before the recheck came round
	Session.host_trade_ready(GUEST, true)
	assert_eq(Session.inventory_of(GUEST).count(BlockIds.DIAMOND), 0, "no diamond appears from nowhere")
	assert_eq(Session.inventory_of(GUEST).count(BlockIds.STONE), 5)
	assert_has(notes, TradeRules.message("not_owned_you"))


# --- The host's checks ---

func test_a_guests_offer_is_checked_against_its_own_bag_and_gold() -> void:
	Session.inventory_of(GUEST).add(BlockIds.DIRT, 3)
	_open()
	Session.host_trade_offer(GUEST, [[BlockIds.DIRT, 30], [ItemIds.FARM, 1]], 9999)
	var theirs: Dictionary = states.back().theirs
	assert_eq(theirs.items, [[BlockIds.DIRT, 3]])
	assert_eq(theirs.gold, 40, "Bob's own purse")


func test_a_guest_without_a_body_can_not_trade() -> void:
	Session.host_trade_ask(4242, _me())
	assert_true(asked.is_empty())
	Session.player_trade_ask(4242)
	assert_eq(notes.back(), TradeRules.message("gone", "That player"))


func test_bots_can_not_be_traded_with() -> void:
	var bot := Node3D.new()
	bot.name = "Pip"
	bot.add_to_group(&"bot_friends")
	add_child_autofree(bot)
	Session.player_trade_ask(bot.get_instance_id())
	assert_true(Session.trade_table.trade_of(_me()).is_empty())
	assert_eq(Session.trade_table.asker_of(bot.get_instance_id()), 0, "a bot is not a player: nothing to ask")


func test_trading_is_for_survivor_worlds() -> void:
	Game.mode = ModeRules.SANDBOX
	Session.player_trade_ask(GUEST)
	assert_eq(notes, [TradeRules.message("survivor_only")])
	assert_true(_guest_got(&"asked").is_empty())
	Game.mode = ModeRules.WAVE
	Session.player_trade_ask(GUEST)
	assert_true(_guest_got(&"asked").is_empty(), "no trading in the Monster Wave arena either")


func test_asking_again_waits_a_moment() -> void:
	Session.player_trade_ask(GUEST)
	Session.host_trade_answer(GUEST, _me(), false)
	Session.player_trade_ask(GUEST)
	assert_eq(notes.back(), TradeRules.message("too_soon"))


func test_online_under_13_players_trade_only_with_their_friends() -> void:
	Session._chat_bands[GUEST] = AgeBand.UNDER_13
	Session.trade_online = func() -> bool: return true
	Session.trade_user_of = func(peer: int) -> String: return "u%d" % peer
	Session.player_trade_ask(GUEST)
	assert_eq(notes.back(), TradeRules.message("friends_only", "Bob"))
	assert_true(_guest_got(&"asked").is_empty())
	Session.host_trade_friends(GUEST, ["u%d" % _me()])   # Ann is on Bob's friends list
	Session.trade_now_ms = func() -> int: return 200_000
	Session.player_trade_ask(GUEST)
	assert_eq(_guest_got(&"asked").size(), 1)
	Session.trade_online = func() -> bool: return false
	Session.host_trade_friends(GUEST, [])
	Session.host_trade_answer(GUEST, _me(), true)
	assert_false(Session.trade_table.trade_of(_me()).is_empty(), "LAN: together at home")


func test_friend_lists_are_cleaned() -> void:
	Session.host_trade_friends(GUEST, ["a", 5, "b", "x".repeat(500)])
	assert_eq(Session._pt_friends[GUEST], ["a", "b"] as Array[String])


# --- Nico's market (the host's check for Tilly's trades) ---

func test_the_markets_things_are_sold_only_while_nico_is_there() -> void:
	var tilly := Node3D.new()
	tilly.add_to_group(&"traders")
	add_child_autofree(tilly)
	tilly.global_position = host.global_position + Vector3(0, 0, -3)
	var id := BlockIds.ROOF_TILES
	var r := Session.host_trade(_me(), true, id, 1)
	assert_false(r.ok, "Tilly doesn't sell the village blocks")
	var cart := Node3D.new()
	cart.add_to_group(&"traders")
	cart.add_to_group(&"market_traders")
	add_child_autofree(cart)
	cart.global_position = host.global_position + Vector3(2, 0, -3)
	Game.universe = 2
	r = Session.host_trade(_me(), true, id, 1)
	assert_true(r.ok)
	assert_eq(r.gold, MarketRules.price(id, 2))
	assert_eq(Profile.data.survivor_gold, 100 - MarketRules.price(id, 2))
	assert_eq(Session.inventory_of(_me()).count(id), MarketRules.amount(id))
