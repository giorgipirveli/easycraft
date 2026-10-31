class_name TradeDirector
extends Node
## The shop and trading in a played world (owner #37, spec §14.23), the sandbox's node "Trading" on every game (its
## RPCs line up). Survivor only (Sandbox gold is ∞, the Monster Wave arenas have no shop):
## - MORE → SHOP (ShopMenu): Tilly (or a nearer villager who trades) with the distance and the way, Nico's cart on
##   market day, the other players with TRADE; SHOW ME points the HUD's find arrow and the shop opens by itself on
##   arrival (a look four times a second while guiding, never otherwise). The first-time picture tip, once per profile.
## - Market day (host): the world's days are counted at every sunrise of the host's clock (WorldMeta.market); on
##   market day Nico's MarketCart stands beside Tilly's stall from sunrise to sunset; every game is told (an RPC on
##   change and to a guest who arrives) and builds its own cart; a banner says so once when it comes.
## - A stand beside the universe's helper (StandRules; every game places it from the helper's spot, nothing sent).
## - Trading between players: a tap on another player's name tag opens their card (PlayerCard: TRADE); the ask card
##   (TradeAskCard), the trade window (TradeWindow) and the notes follow Session's section "Trading" (the host
##   decides everything). This game tells the host its online friends (the under-13 rule).
## Decisions once a second; the cart's and the stand's spots are worked out on worker threads.

signal market_changed(open: bool)

const TICK := 1.0
const GUIDE_EVERY := 0.25

# --- Injected by the sandbox (tests use stand-ins) ---
var mode: StringName = ModeRules.SANDBOX
var universe := 1
var world_seed := 0
var player: Player
var hud: Hud
## () -> float: the sky's time of day (the host counts the days with it).
var time_of_day: Callable = func() -> float: return DayCycle.START
## (what, pos) -> void: the HUD's find arrow points there; () -> void: it stops.
var point_at: Callable = func(_what: String, _pos: Vector3) -> void: pass
var stop_arrow: Callable = func() -> void: pass
## () -> Node3D: Tilly's stall (null when there is none).
var tilly: Callable = func() -> Node3D: return null
## (giver id) -> Node3D: the quest giver standing in this world (QuestDirector.givers), or null.
var giver: Callable = func(_id: StringName) -> Node3D: return null
var is_host: Callable = func() -> bool: return Session.is_host()
## (peer) -> void: ask a player to trade.
var ask: Callable = func(peer: int) -> void: Session.player_trade_ask(peer)
## Host -> the other games: the market's state (on, cart pos, yaw); a guest who arrives (peer, on, pos, yaw).
var send_market: Callable = _send_market
var send_market_to: Callable = _send_market_to
var auto_tick := true

## Host: the world's day count ({"day": n}, saved in WorldMeta.market).
var market := {"day": 1}
var market_open := false
var cart: MarketCart
var stand: TraderStand
var shop_menu: ShopMenu
var player_card: PlayerCard
var ask_card: TradeAskCard
var trade_window: TradeWindow
var more_button: TouchButton

var _shape: MeadowsShape
var _last_time := -1.0            # host: the clock at the last look
var _cart_spot := {}              # host: {pos, yaw} beside Tilly's stall
var _cart_pos := Vector3.INF      # every game: where the cart stands now
var _cart_yaw := 0.0
var _stand_asked := false
var _guide: Node3D                # the trader the arrow leads to
var _guide_opens := false
var _t := 0.0
var _g := 0.0
var _tasks: Array[int] = []


func enabled() -> bool:
	return TraderRules.wants_trader(mode)


func _exit_tree() -> void:
	for id in _tasks:
		WorkerThreadPool.wait_for_task_completion(id)
	_tasks.clear()
	for pair: Array in _session_links():
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])


func _process(delta: float) -> void:
	if not auto_tick:
		return
	_t += delta
	if _t >= TICK:
		_t = 0.0
		tick()
	if _guide != null:
		_g += delta
		if _g >= GUIDE_EVERY:
			_g = 0.0
			guide_tick()


## Every game: the world's terrain rules (the stand's and the cart's ground) and its spawn.
func setup_world(shape: MeadowsShape) -> void:
	_shape = shape


## Host (or solo): the saved day count and Tilly's stall; the cart's spot is worked out on a worker thread.
func setup_host(saved: Dictionary, stall_pos: Vector3, stall_yaw: float, spawn: Vector2i) -> void:
	market = MarketRules.clean(saved)
	if not enabled() or _shape == null or not stall_pos.is_finite():
		return
	var shape := _shape
	var s := world_seed
	var u := universe
	_tasks.append(WorkerThreadPool.add_task(func() -> void:
		var marks: Array = []
		for m: Vector3 in QuestRules.landmarks(s, shape, spawn):
			if m.distance_to(stall_pos) > 1.0:
				marks.append(m)
		if StandRules.giver_in(u) != &"":
			marks.append(QuestRules.giver_for_world(s, shape, spawn).pos)
		var spot := MarketRules.cart_spot(stall_pos, stall_yaw, shape.height_at, _ground_ok_for(s, shape), shape.tree_at, marks)
		_set_cart_spot.call_deferred(spot)))


func _set_cart_spot(spot: Dictionary) -> void:
	_cart_spot = spot


## What the world saves (WorldMeta.market).
func market_save() -> Dictionary:
	return MarketRules.clean(market)


## The ground a stand or a cart may stand on (dry land, no river, no cave mouth), like the quest helpers'.
static func _ground_ok_for(s: int, shape: MeadowsShape) -> Callable:
	var caves := CaveShape.new(s)
	return func(x: int, z: int) -> bool:
		return shape.height_at(x, z) > MeadowsShape.SEA_LEVEL + 1 and not shape.is_river(x, z) and not caves.entrance_open(x, z)


# --- Every second ----------------------------------------------------------------------------------------------

## One look (TICK seconds of play have passed; tests call it directly).
func tick() -> void:
	_prune_tasks()
	if not enabled():
		return
	if is_host.call():
		_host_market(float(time_of_day.call()))
	_place_stand()


func _prune_tasks() -> void:
	var left: Array[int] = []
	for id in _tasks:
		if WorkerThreadPool.is_task_completed(id):
			WorkerThreadPool.wait_for_task_completion(id)
		else:
			left.append(id)
	_tasks = left


## Host: the day count and the cart.
func _host_market(t: float) -> void:
	if _last_time >= 0.0:
		market.day = mini(int(market.day) + MarketRules.sunrises(_last_time, t), MarketRules.MAX_DAY)
	_last_time = t
	var want := MarketRules.is_open(int(market.day), t) and not _cart_spot.is_empty()
	if want != market_open:
		var pos: Vector3 = _cart_spot.get("pos", Vector3.INF)
		var yaw := float(_cart_spot.get("yaw", 0.0))
		set_market(want, pos, yaw)
		send_market.call(want, pos, yaw)


## Every game: the cart comes or goes (the host decides; a guest hears it).
func set_market(on: bool, pos: Vector3, yaw: float) -> void:
	var was := market_open
	market_open = on and pos.is_finite()
	_cart_pos = pos
	_cart_yaw = yaw
	if market_open and cart == null:
		cart = MarketCart.new()
		cart.setup({"pos": pos, "yaw": yaw})
		add_child(cart)
	elif not market_open and cart != null:
		if _guide == cart:
			_stop_guide()
		cart.queue_free()
		cart = null
	if market_open and not was and is_instance_valid(hud):
		hud.show_banner(MarketRules.ARRIVED)
	if market_open != was:
		market_changed.emit(market_open)


func _send_market(on: bool, pos: Vector3, yaw: float) -> void:
	for peer in multiplayer.get_peers():
		_rpc_market.rpc_id(peer, on, pos, yaw)


func _send_market_to(peer: int, on: bool, pos: Vector3, yaw: float) -> void:
	if multiplayer.get_peers().has(peer):
		_rpc_market.rpc_id(peer, on, pos, yaw)


## Host: a guest who arrives hears whether Nico is here.
func on_client_ready(peer: int) -> void:
	send_market_to.call(peer, market_open, _cart_pos, _cart_yaw)


@rpc("authority", "call_remote", "reliable")
func _rpc_market(on: bool, pos: Vector3, yaw: float) -> void:
	set_market(on, pos if pos.is_finite() else Vector3.INF, yaw)


# --- The helper's stand (every game, from the helper's spot) ------------------------------------------------------

func _place_stand() -> void:
	if stand != null or _stand_asked or _shape == null or not StandRules.has_stand(universe):
		return
	var g: Node3D = giver.call(StandRules.giver_in(universe))
	if g == null or not g.is_inside_tree():
		return
	_stand_asked = true
	var at := g.global_position
	var yaw := g.rotation.y
	var shape := _shape
	var s := world_seed
	_tasks.append(WorkerThreadPool.add_task(func() -> void:
		var spot := StandRules.stand_spot(at, yaw, shape.height_at, _ground_ok_for(s, shape), shape.tree_at)
		_add_stand.call_deferred(spot)))


func _add_stand(spot: Dictionary) -> void:
	if not is_inside_tree() or stand != null:
		return
	stand = TraderStand.new()
	stand.setup({"pos": spot.pos, "yaw": float(spot.yaw), "universe": universe})
	add_child(stand)


# --- Finding Tilly (this game) -------------------------------------------------------------------------------------

## The full shops this game knows: Tilly's stall and the villagers who trade (near this game's player).
func full_shops() -> Array:
	var out: Array = []
	var t: Node3D = tilly.call()
	if t != null and is_instance_valid(t) and t.is_inside_tree():
		out.append({"pos": t.global_position, "what": "Tilly", "trader": t})
	if is_inside_tree():
		for v in get_tree().get_nodes_in_group(&"villagers"):
			if v is Trader and (v as Node).is_in_group(&"traders") and not (v as Node).is_queued_for_deletion():
				out.append({"pos": (v as Node3D).global_position, "what": _villager_name(v), "trader": v})
	return out


static func _villager_name(v: Node) -> String:
	for c in v.get_children():
		if c is Label3D and (c as Label3D).text != "":
			return (c as Label3D).text
	return Lang.t("A villager")


## Nico's cart as a shop ({} when it is not market day).
func market_shop() -> Dictionary:
	if cart == null or not is_instance_valid(cart):
		return {}
	return {"pos": cart.global_position, "what": MarketRules.SHOP_TITLE, "trader": cart}


## The other players in this world ({peer, name}): players with a body, never bot friends.
func other_players() -> Array:
	var out: Array = []
	if not is_inside_tree():
		return out
	for p in get_tree().get_nodes_in_group(&"players"):
		var pl := p as Player
		if pl == null or pl.is_queued_for_deletion() or pl == player or pl.peer_id == multiplayer.get_unique_id():
			continue
		out.append({"peer": pl.peer_id, "name": str(Session.chat_names.get(pl.peer_id, "Player"))})
	return out


## The arrow leads to `trader`; `opens`: its shop opens by itself on arrival.
func guide_to(what: String, trader: Node3D, opens: bool = true) -> void:
	if trader == null or not is_instance_valid(trader):
		return
	_guide = trader
	_guide_opens = opens
	_g = 0.0
	point_at.call(what, trader.global_position)
	if is_instance_valid(hud):
		hud.toast(tr(ShopGuide.FOLLOW) % what, 3.0)


## A look while guiding: once the child is there, the shop opens (and the arrow stops).
func guide_tick() -> void:
	if _guide == null:
		return
	if not is_instance_valid(_guide) or not _guide.is_inside_tree():
		_stop_guide()
		return
	if not is_instance_valid(player) or not ShopGuide.there(player.eye_position(), _guide.global_position):
		return
	var t := _guide
	var opens := _guide_opens
	_stop_guide()
	if opens and t is Trader:
		open_shop(t as Trader)


func _stop_guide() -> void:
	_guide = null
	stop_arrow.call()


func guiding() -> Node3D:
	return _guide


func open_shop(trader: Trader) -> void:
	if is_instance_valid(hud) and trader != null and is_instance_valid(trader):
		hud.open_shop(trader)


## The first time a child plays a Survivor world (once per profile): a picture tip, and the arrow at Tilly. M3 Task 15:
## held while the tutorial is offered or playing (`hold_tip`); its Tilly step shows it (show_tip).
func maybe_tip() -> void:
	if hold_tip.call() or not ShopGuide.wants_tip(Profile.data.hints_seen, mode):
		return
	show_tip()


## The picture tip and the arrow at Tilly (marked seen); false when there is no Tilly to point at.
func show_tip() -> bool:
	if not Profile.data.hints_seen.has(ShopGuide.TIP):
		Profile.data.hints_seen.append(ShopGuide.TIP)
	if is_instance_valid(hud):
		hud.picture_hint.show_hint(CoinIcon.texture(), CoinIcon.GOLD, ShopGuide.TIP_TEXT, ShopGuide.TIP_SECONDS)
	var t: Node3D = tilly.call()
	if t == null:
		return false
	guide_to("Tilly", t, false)
	return true


## M3 Task 15: () -> bool, true while the tutorial with Pip is offered or playing (the sandbox sets it).
var hold_tip: Callable = func() -> bool: return false


# --- Trading between players (this game) -------------------------------------------------------------------------

## Another player whose name tag a tap ray (from, unit dir) hits, within TradeRules.TAP_REACH of `eye` and not behind
## a block (blocked(from, dir, distance) -> bool); never this game's own player, never a bot friend.
func name_tag_hit(from: Vector3, dir: Vector3, eye: Vector3, blocked: Callable = Callable()) -> Player:
	var best: Player = null
	var best_t := INF
	for p in get_tree().get_nodes_in_group(&"players"):
		var pl := p as Player
		if pl == null or pl == player or pl.peer_id == multiplayer.get_unique_id() or not pl.visible:
			continue
		var tag := pl.get_node_or_null("NameTag") as Label3D
		if tag == null or not tag.visible or tag.text == "":
			continue
		var center := tag.global_position
		if eye.distance_to(center) > TradeRules.TAP_REACH:
			continue
		var t := (center - from).dot(dir)
		if t <= 0.0 or (from + dir * t).distance_to(center) > TradeRules.TAG_RADIUS or t >= best_t:
			continue
		if blocked.is_valid() and blocked.call(from, dir, t):
			continue
		best = pl
		best_t = t
	return best


## The BlockInteractor's hook: a tap on a name tag opens that player's card (every world with other players, spec
## §17.3 "Safety in the world"; TRADE on it only where trading is).
func tap_name_tag(screen_pos: Vector2) -> bool:
	if not is_instance_valid(player) or player_card == null:
		return false
	var cam := player.camera()
	if cam == null:
		return false
	var blocked := func(from: Vector3, dir: Vector3, dist: float) -> bool: return player.world.raycast(from, dir, dist) != null
	var ray := player.aim_ray(screen_pos)   # owner #101: the camera's ray through the point, or the VR hand's
	var p := name_tag_hit(ray[0], ray[1], player.eye_position(), blocked)
	if p == null:
		return false
	open_card(p.peer_id)
	return true


## Another player's card, with what this game may offer: TRADE where trading is; online REPORT and BLOCK; the host's
## REMOVE (spec §17.3).
func open_card(peer_id: int) -> void:
	player_card.can_trade = enabled()
	player_card.online = Session.is_online() and Session.online_service_or_null() != null
	player_card.host = Session.is_host() and multiplayer.get_peers().has(peer_id)
	player_card.open_for(peer_id, str(Session.chat_names.get(peer_id, "Player")))


## This game's online friends go to the host (the under-13 rule); nothing on LAN or solo.
func report_friends() -> void:
	var s := Session.online_service_or_null()
	if s == null or not Session.is_online():
		return
	var ids: Array = []
	for f: Dictionary in s.friends:
		if f.get("state") == OnlineRules.FRIEND:
			ids.append(str(f.get("id", "")))
	Session.player_trade_friends(ids)


func _on_trade_changed(state: Dictionary) -> void:
	if trade_window == null:
		return
	for page: QuestOverlay in [shop_menu, player_card]:
		if page:
			page.close()
	if is_instance_valid(hud):
		hud.more.close()
		hud.shop.close()
	if state.is_empty():
		trade_window.close_window()
	else:
		trade_window.show_state(state)


func _on_trade_ended(done: bool, text: String) -> void:
	if trade_window:
		trade_window.close_window()
	if is_instance_valid(hud):
		hud.toast(text, 3.0)
	Audio.play(&"ding" if done else &"thud")


func _on_trade_note(text: String) -> void:
	if trade_window and trade_window.is_open():
		trade_window.say(text)
	elif is_instance_valid(hud):
		hud.toast(text, 3.0)


func _on_asked(peer: int, from_name: String) -> void:
	if ask_card:
		ask_card.ask(peer, from_name)


func _on_ask_gone(peer: int) -> void:
	if ask_card:
		ask_card.ask_gone(peer)


func _session_links() -> Array:
	return [[Session.player_trade_changed, _on_trade_changed], [Session.player_trade_ended, _on_trade_ended],
		[Session.player_trade_note, _on_trade_note], [Session.player_trade_asked, _on_asked],
		[Session.player_trade_ask_gone, _on_ask_gone]]


# --- This game's screens ----------------------------------------------------------------------------------------------

## SHOP in MORE, the SHOP card, a player's card, the ask card and the trade window over `h` (in `layer`); the name
## tag taps through `interactor`. Survivor only.
func setup_local(p: Player, h: Hud, layer: Node, interactor: BlockInteractor) -> void:
	player = p
	hud = h
	_setup_card(layer, interactor)   # every world (spec §17.3 "Safety in the world")
	if not enabled():
		return
	shop_menu = ShopMenu.new()
	shop_menu.name = "ShopMenu"
	shop_menu.shops = full_shops
	shop_menu.market = market_shop
	shop_menu.players = other_players
	shop_menu.eye = func() -> Vector3:
		return player.eye_position() if is_instance_valid(player) and player.is_spawned() else Vector3.INF
	shop_menu.yaw = func() -> float: return player.rig.yaw if is_instance_valid(player) else 0.0
	shop_menu.on_way = func(what: String, trader: Variant) -> void:
		if trader is Node3D:
			guide_to(what, trader)
	shop_menu.on_open = func(trader: Variant) -> void:
		if trader is Trader:
			open_shop(trader)
	shop_menu.on_trade = func(peer: int) -> void: ask.call(peer)
	ask_card = TradeAskCard.new()
	ask_card.name = "TradeAskCard"
	trade_window = TradeWindow.new()
	trade_window.name = "TradeWindow"
	for c: Control in [shop_menu, ask_card, trade_window]:
		layer.add_child(c)
		if h:
			h.look_area.blockers.append(c)
	if h:
		more_button = ShopMenu.more_button()
		h.more.add(more_button, true)
		more_button.pressed.connect(shop_menu.open_menu)
	for pair: Array in _session_links():
		(pair[0] as Signal).connect(pair[1])
	if p:
		p.spawned.connect(maybe_tip, CONNECT_ONE_SHOT)
	var s := Session.online_service_or_null()
	if s:
		s.friends_changed.connect(report_friends)
	report_friends()


## The player card in every world: a tap on a name tag opens it (spec §17.3). Online REPORT and BLOCK go to this
## device's account (the other player's Nakama id from the relay); the host's REMOVE goes through Session.
func _setup_card(layer: Node, interactor: BlockInteractor) -> void:
	player_card = PlayerCard.new()
	player_card.name = "PlayerCard"
	player_card.on_trade = func(peer: int) -> void: ask.call(peer)
	player_card.on_report = func(peer: int, reason: String) -> String:
		var s := Session.online_service_or_null()
		var id := Session.online_user_of(peer)
		if s == null or id == "":
			return NetWords.text(NetWords.UNKNOWN)
		return await s.report(id, reason)
	player_card.on_block = func(peer: int) -> String:
		var s := Session.online_service_or_null()
		var id := Session.online_user_of(peer)
		if s == null or id == "":
			return NetWords.text(NetWords.UNKNOWN)
		return await s.block(id)
	player_card.on_remove = func(peer: int) -> String: return await Session.host_remove_guest(peer)
	layer.add_child(player_card)
	if hud:
		hud.look_area.blockers.append(player_card)
	if interactor:
		interactor.name_tag_tap = tap_name_tag


## The pages close (Android Back, the pause menu): the trade stops with X's words. True when one was open.
func close_pages() -> bool:
	var was := false
	for page: QuestOverlay in [shop_menu, player_card, ask_card]:
		if page and page.is_open():
			page.close()
			was = true
	if trade_window and trade_window.is_open():
		trade_window.cancel()
		was = true
	return was


## The overlays, for the sandbox to put under the pause menu.
func pages() -> Array[Control]:
	var out: Array[Control] = []
	for c: Control in [shop_menu, player_card, ask_card, trade_window]:
		if c:
			out.append(c)
	return out
