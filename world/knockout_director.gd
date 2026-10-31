class_name KnockoutDirector
extends Node
## Knock-outs and pickup bags in a world (M2 Task 2, spec §12.3, §12.15). The sandbox adds one on
## every peer, always named "Knockout", so its spawner and RPCs line up across the network.
## Host: when a player's hearts reach 0 on the host's own Health (Session.player_hurt), a Survivor
## player's carried blocks drop into a bag where they fell (KnockoutRules), and everyone sees them
## knocked out. After KnockoutRules.KO_TIME the host revives them (full hearts) and tells them to get
## up. Nothing hurts them until their game says they have arrived (at most ARRIVAL_TIMEOUT), then for
## Health.PROTECTION more. It spawns, hands out, saves and restores the bags.
## Every peer: knocked-out avatars lie down with a burst of stars; this game's player gets the fade and
## the message, and moves its own body when told to get up (Survivor: home; Sandbox: on the spot).
## M4 E (§17.5): with a teammate near, a knocked-out player waits a little for help (GET UP goes at
## once); a teammate holding HELP UP near them for 3 s helps them up on the spot (ReviveRules).

const ARRIVAL_TIMEOUT := 15.0      # a far bed loads within Player.SPAWN_TIMEOUT
const SURVIVOR_MESSAGE := "You were knocked out!"
const SANDBOX_MESSAGE := "Oops! Back on your feet!"

var player: Player                 # this game's player (null on a dedicated host)
var hud: Hud
## Host: the world's Survivor difficulty (KnockoutRules.COZY drops no bag); the lead's world setting.
var difficulty: StringName = KnockoutRules.NORMAL
## name_of(peer_id) -> String: the player's name, which owns their bags (the sandbox's).
var name_of: Callable = _chat_name
## block_at(pos: Vector3i) -> int: the host's world (tests replace it).
var block_at: Callable = _world_block

var _bags := Node3D.new()
var _bag_spawner := MultiplayerSpawner.new()
var _next_id := 1
var _down := {}                    # host: peer id -> seconds until they get up
var _arriving := {}                # host: peer id -> seconds left to say they have arrived
var _tips := 0                     # this game's knock-outs so far (the tips take turns)


func _ready() -> void:
	_bags.name = "Bags"
	add_child(_bags)
	_bag_spawner.name = "BagSpawner"
	add_child(_bag_spawner)
	_bag_spawner.spawn_path = _bag_spawner.get_path_to(_bags)
	_bag_spawner.spawn_function = _make_bag
	# A LAN guest's sandbox makes this before it joins, so every handler checks is_host() itself.
	Session.player_hurt.connect(_on_player_hurt)
	Session.knockout_received.connect(_on_knockout)
	Session.knockout_respawned.connect(_on_respawned)
	Session.knockout_arrived.connect(_on_arrived)
	Session.bag_take_requested.connect(_on_take_requested)
	Session.peer_left.connect(_on_peer_left)


## This game's player and HUD (the hearts row and the fade).
func setup_local(p: Player, h: Hud) -> void:
	player = p
	hud = h
	if hud:
		hud.add_health_controls()
		hud.add_revive_controls()   # M4 E: HELP UP and GET UP
		hud.help_button.pressed.connect(_on_help_pressed)
		hud.help_button.released.connect(_on_help_released)
		hud.get_up_button.pressed.connect(ask_get_up)


func _process(delta: float) -> void:
	if Session.is_host() and not (_down.is_empty() and _arriving.is_empty()):
		advance(delta)
	_local_help_tick(delta)   # M4 E


## Host: the knock-out and arrival clocks (tests drive it directly).
func advance(delta: float) -> void:
	_advance_helps(delta)   # M4 E: teammates helping someone up
	for id: int in _down.keys():
		if _held.has(id):
			continue   # a friend is helping them up: they wait for it
		_down[id] -= delta
		if _down[id] <= 0.0:
			_get_up(id)
	for id: int in _arriving.keys():
		_arriving[id] -= delta
		var p := Session._player_for_peer(id)
		if p == null or _arriving[id] <= 0.0:
			_arriving.erase(id)
		else:
			p.health.protect(Health.PROTECTION)


func _world_block(pos: Vector3i) -> int:
	return Session.world.get_block(pos) if Session.world else BlockIds.AIR


func _is_solid(cell: Vector3i) -> bool:
	return BlockIds.is_solid(block_at.call(cell))


func _chat_name(peer_id: int) -> String:
	return str(Session.chat_names.get(peer_id, ""))

# --- Host: knock-outs ---------------------------------------------------------------------------

func _on_player_hurt(peer_id: int, hp: int, _from: Vector3) -> void:
	if hp > 0 or not Session.is_host() or _down.has(peer_id):
		return
	var p := Session._player_for_peer(peer_id)
	if p and p.health.is_knocked_out():   # only the host's own Health decides
		knock_out(p)


## Host: p's hearts are at 0.
func knock_out(p: Player) -> void:
	if p.sleeping:
		Session.bed_wake_requested.emit(p.peer_id)   # out of bed first (SleepDirector)
	if KnockoutRules.drops_bag(Game.mode, difficulty):
		var items := KnockoutRules.take_blocks(Session.inventory_of(p.peer_id))
		if not items.is_empty():
			drop_bag(str(name_of.call(p.peer_id)), p.global_position, items)
			Session.bag_inventory_changed.emit(p.peer_id)
	_down[p.peer_id] = _down_time(p)   # M4 E: longer with a teammate near who can help
	_arriving.erase(p.peer_id)
	Session.broadcast_knockout(p.peer_id, KnockoutRules.respawns_at_home(Game.mode))
	if _down[p.peer_id] > KnockoutRules.KO_TIME:
		_rpc_wait.rpc(p.peer_id, true)


func _get_up(peer_id: int) -> void:
	_down.erase(peer_id)
	_end_help(peer_id)   # M4 E
	var p := Session._player_for_peer(peer_id)
	if p == null:
		return
	p.health.revive()
	Session.broadcast_health(peer_id, p.health.hp)
	Session.player_hurt.emit(peer_id, p.health.hp, Vector3.INF)
	_arriving[peer_id] = ARRIVAL_TIMEOUT
	Session.broadcast_knockout_respawn(peer_id, KnockoutRules.respawns_at_home(Game.mode))


## Host: the player's game says they are back on their feet. This only ever ends the protection the
## host was holding (a guest cannot make itself safe for longer by sending it).
func _on_arrived(peer_id: int) -> void:
	if not Session.is_host() or not _arriving.has(peer_id):
		return
	_arriving.erase(peer_id)
	var p := Session._player_for_peer(peer_id)
	if p:
		p.health.protect(Health.PROTECTION)


func _on_peer_left(peer_id: int) -> void:
	_down.erase(peer_id)
	_arriving.erase(peer_id)
	_end_help(peer_id)   # M4 E: as the one helped
	for friend: int in _held.keys():   # and as the helper
		if helper_of(friend) == peer_id:
			_stop_help(friend)

# --- Every peer: what a knock-out looks like --------------------------------------------------

## at_home: Survivor (they get up at home) rather than Sandbox (on the spot).
func _on_knockout(peer_id: int, at_home: bool) -> void:
	var p := Session._player_for_peer(peer_id)
	if p == null:
		return
	p.set_knocked_out(true)
	Fx.burst(get_tree().root, p.global_position + Vector3(0, 1.2 * p.size_scale(), 0), Color("ffd23f"), 14, 2.5, 0.1, 0.9, 1.5)
	Audio.play(&"thud", p.global_position)
	if hud == null:
		return
	if p == player:
		var tip := KnockoutRules.tip(_tips, at_home, player.has_home)
		_tips += 1
		hud.knockout_overlay.knock_out(SURVIVOR_MESSAGE if at_home else SANDBOX_MESSAGE, tip)
	else:
		var who := str(Session.chat_names.get(peer_id, "A friend"))
		hud.toast(tr("%s was knocked out!") % who)


func _on_respawned(peer_id: int, at_home: bool) -> void:
	var p := Session._player_for_peer(peer_id)
	if p == null:
		return
	p.set_knocked_out(false)
	if p != player:
		return
	if at_home:
		player.go_home()   # the bed, or the world spawn without one
		if not player.spawned.is_connected(_on_back_on_feet):
			player.spawned.connect(_on_back_on_feet, CONNECT_ONE_SHOT)
	else:
		player.pop_up()
		_on_back_on_feet()


func _on_back_on_feet() -> void:
	if hud:
		hud.knockout_overlay.get_up()
	Session.send_knockout_arrived()

# --- Pickup bags ------------------------------------------------------------------------------

func bags() -> Array[PickupBag]:
	var list: Array[PickupBag] = []
	for n in _bags.get_children():
		if n is PickupBag and not n.is_queued_for_deletion():
			list.append(n)
	return list


## Host: puts `items` down for bag_owner where someone fell (feet): on the ground below, in the
## owner's bag right there, or their oldest when they have too many (KnockoutRules.merge_index).
## Returns the bag that holds them.
func drop_bag(bag_owner: String, feet: Vector3, items: Array) -> PickupBag:
	var spot := KnockoutRules.bag_spot(feet, _is_solid)
	if not spot.is_finite():
		spot = Session.host_spawn if Session.host_spawn.is_finite() else Vector3.ZERO
	var existing := bags()
	var list := []
	for b in existing:
		list.append({"owner": b.owner_name, "pos": b.global_position, "age": b.age()})
	var i := KnockoutRules.merge_index(list, bag_owner, spot)
	if i >= 0:
		var old := existing[i]
		items = KnockoutRules.merge_items(old.items, items)
		old.items = []
		old.queue_free()
	return spawn_bag(bag_owner, spot, items, 0.0)


## Host: a bag for everyone (its node name is unique in this game).
func spawn_bag(bag_owner: String, pos: Vector3, items: Array, age: float) -> PickupBag:
	var data := {"id": "Bag%d" % _next_id, "pos": pos, "owner": bag_owner, "items": items, "age": age}
	_next_id += 1
	return _bag_spawner.spawn(data) as PickupBag


func _make_bag(data: Variant) -> Node:
	var bag := PickupBag.new()
	bag.setup(data)
	return bag


## Host: a player asks for a bag they tapped: within reach, and theirs (or free for anyone by now).
## Every block that fits goes into their inventory; the rest stays in the bag.
func _on_take_requested(peer_id: int, bag_name: String) -> void:
	if not Session.is_host():
		return
	var bag := _bags.get_node_or_null(NodePath(bag_name)) as PickupBag
	var p := Session._player_for_peer(peer_id)
	if bag == null or p == null or bag.is_queued_for_deletion() or bag.items.is_empty():
		return
	if _down.has(peer_id) or p.health.is_knocked_out():
		return   # not during the fade: a tap on your own bag would undo the knock-out (LAN run)
	if not KnockoutRules.in_reach(p.eye_position(), bag.center()):
		Session.send_feedback(peer_id, "Get closer to the bag first!")
		return
	var taker := str(name_of.call(peer_id))
	var refusal := KnockoutRules.refusal(bag.owner_name, taker, bag.age())
	if refusal != "":
		Session.send_feedback(peer_id, refusal)
		return
	var left := KnockoutRules.put_back(bag.items, Session.inventory_of(peer_id))
	if left != bag.items:
		Session.bag_inventory_changed.emit(peer_id)
	bag.items = left
	if not left.is_empty():
		Session.send_feedback(peer_id, "Your pockets are full! The rest stays in the bag.")
		return
	_rpc_bag_taken.rpc(bag.center())
	bag.queue_free()
	if bag.owner_name == taker:
		Session.send_feedback(peer_id, "You got your blocks back!")
	else:
		Session.send_feedback(peer_id, tr("You took %s's bag!") % bag.owner_name if bag.owner_name != "" else "You took the bag!")


@rpc("authority", "call_local", "unreliable")
func _rpc_bag_taken(at: Vector3) -> void:
	Fx.burst(get_tree().root, at, Color("ffd23f"), 18, 4.0, 0.1, 0.7, 6.0)
	Audio.play(&"ding", at)


## The bags for WorldMeta.bags.
func to_save() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for b in bags():
		if not b.items.is_empty():
			list.append(b.to_save())
	return list


## Host: brings back the saved bags (WorldMeta.bags, already checked).
func restore(saved: Array[Dictionary]) -> void:
	for e in saved:
		spawn_bag(str(e.owner), Vector3(e.pos[0], e.pos[1], e.pos[2]), e.items, float(e.age))


# --- M4 E: helping a knocked-out teammate up (§17.5) --------------------------------------------
# The host decides (ReviveRules with its own positions): who waits for help, whether a help can
# start and go on, and when it is done. Every game hears who waits (_rpc_wait), who is helping whom
# (_rpc_help, a ring fills from then on) and the cheer (_rpc_revived). This game's player gets HELP
# UP near a teammate who waits (hold it, or H on a keyboard) and GET UP while it waits itself (G).

## Every peer: a teammate helped a knocked-out player up.
signal revived(friend_peer: int, helper_peer: int)

const HELP_KEY := KEY_H
const GET_UP_KEY := KEY_G
const LOCAL_SCAN := 0.2            # this game looks for someone to help five times a second

## Host: the players in this world (tests replace it).
var players_here: Callable = _players_in_world
## Every peer: players waiting for a teammate's help (peer id -> true).
var waiting := {}
## Every peer: helps going on (friend's peer id -> {"by": helper's peer id, "since": msec}).
var helping := {}
## Every peer: the bodies that cheered after a help (tests read it).
var cheered: Array[int] = []

var _held := {}                    # host: friend's peer id -> seconds held so far
var _help_target := 0              # this game: the teammate HELP UP is for
var _asking := 0                   # this game: the teammate it holds HELP UP for now
var _scan := 0.0


func _players_in_world() -> Array[Player]:
	var out: Array[Player] = []
	for n in get_tree().get_nodes_in_group(&"players"):
		if n is Player and is_instance_valid(n):
			out.append(n)
	return out


## Host: how long `p` stays down: longer when a teammate who is up could come and help.
func _down_time(p: Player) -> float:
	var near := 0
	for other: Player in players_here.call():
		if other == p or other.health.is_knocked_out() or _down.has(other.peer_id):
			continue
		if ReviveRules.calls_for_help(p.global_position, other.global_position):
			near += 1
	return ReviveRules.down_time(near)


func is_waiting(peer_id: int) -> bool:
	return waiting.has(peer_id)


## The teammate helping `friend` up now (0 = nobody).
func helper_of(friend: int) -> int:
	return int((helping.get(friend, {}) as Dictionary).get("by", 0))


## Host: `helper` holds HELP UP for `friend` (holding) or lets go.
func request_revive(helper: int, friend: int, holding: bool) -> void:
	if not Session.is_host():
		return
	if not holding:
		if _held.has(friend) and helper_of(friend) == helper:
			_stop_help(friend)
		return
	if _held.has(friend):
		return   # someone is already helping
	var why := _help_refusal(helper, friend)
	if why != &"":
		var words := ReviveRules.refusal_message(why)
		if words != "":
			Session.send_feedback(helper, words)
		return
	_held[friend] = 0.0
	_rpc_help.rpc(friend, helper, true)


## Host: a waiting player chose GET UP: up now, the usual way.
func request_get_up(peer_id: int) -> void:
	if Session.is_host() and _down.has(peer_id) and not _held.has(peer_id):
		_down[peer_id] = 0.0


func _help_refusal(helper: int, friend: int) -> StringName:
	var hp := Session._player_for_peer(helper)
	var fp := Session._player_for_peer(friend)
	if hp == null or fp == null:
		return ReviveRules.NOT_DOWN
	return ReviveRules.refusal(helper, friend, _down.has(friend) and fp.health.is_knocked_out(),
		fp.health.is_protected() or _arriving.has(friend), _down.has(helper) or hp.health.is_knocked_out(),
		ReviveRules.in_reach(hp.global_position, fp.global_position, hp.size_scale()))


func _advance_helps(delta: float) -> void:
	for friend: int in _held.keys():
		var helper := helper_of(friend)
		if _help_refusal(helper, friend) != &"":
			_stop_help(friend)
			continue
		_held[friend] = float(_held[friend]) + delta
		if ReviveRules.done(_held[friend]):
			_help_up(friend, helper)


func _stop_help(friend: int) -> void:
	_held.erase(friend)
	_rpc_help.rpc(friend, 0, false)


## Host: up on the spot with full hearts (the knock-out's protection follows, as for getting up).
func _help_up(friend: int, helper: int) -> void:
	_held.erase(friend)
	_down.erase(friend)
	var p := Session._player_for_peer(friend)
	if p == null:
		return
	p.health.revive()
	Session.broadcast_health(friend, p.health.hp)
	Session.player_hurt.emit(friend, p.health.hp, Vector3.INF)
	_arriving[friend] = ARRIVAL_TIMEOUT
	Session.broadcast_knockout_respawn(friend, false)   # on the spot, Sandbox and Survivor alike
	_rpc_revived.rpc(friend, helper)


## Host: `peer_id` is no longer waiting or being helped.
func _end_help(peer_id: int) -> void:
	if _held.has(peer_id):
		_stop_help(peer_id)
	if waiting.has(peer_id):
		_rpc_wait.rpc(peer_id, false)


@rpc("authority", "call_local", "reliable")
func _rpc_wait(peer_id: int, on: bool) -> void:
	if on:
		waiting[peer_id] = true
	else:
		waiting.erase(peer_id)


@rpc("authority", "call_local", "reliable")
func _rpc_help(friend: int, helper: int, on: bool) -> void:
	if on:
		helping[friend] = {"by": helper, "since": Time.get_ticks_msec()}
	else:
		helping.erase(friend)


@rpc("authority", "call_local", "reliable")
func _rpc_revived(friend: int, helper: int) -> void:
	waiting.erase(friend)
	helping.erase(friend)
	for id in [friend, helper]:
		Session._show_emote(id, &"cheer")   # both get a small cheer
		cheered.append(id)
	var p := Session._player_for_peer(friend)
	if p:
		Fx.burst(get_tree().root, p.global_position + Vector3(0, 1.2 * p.size_scale(), 0), Color("7ee081"), 16, 3.0, 0.1, 0.8, 2.0)
		Audio.play(&"ding", p.global_position)
	if hud and is_instance_valid(hud) and is_instance_valid(player):
		var me := player.peer_id
		if me == friend:
			hud.toast(ReviveRules.helped_you(_display_name(helper)))
		elif me == helper:
			hud.toast(ReviveRules.you_helped(_display_name(friend)))
		else:
			hud.toast(ReviveRules.someone_helped(_display_name(helper), _display_name(friend)))
	revived.emit(friend, helper)
	Session.revive_done.emit(friend, helper)


func _display_name(peer_id: int) -> String:
	return str(Session.chat_names.get(peer_id, "A friend"))


# --- This game's player: HELP UP and GET UP ---

## Asks the host: this game's player holds HELP UP for `friend` (holding), or lets go.
func ask_revive(friend: int, holding: bool) -> void:
	if friend == 0:
		return
	_asking = friend if holding else 0
	if Session.is_host():
		request_revive(multiplayer.get_unique_id(), friend, holding)
	else:
		_rpc_ask_revive.rpc_id(1, friend, holding)


func ask_get_up() -> void:
	if Session.is_host():
		request_get_up(multiplayer.get_unique_id())
	else:
		_rpc_ask_get_up.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_ask_revive(friend: int, holding: bool) -> void:
	if Session.is_host():
		request_revive(multiplayer.get_remote_sender_id(), friend, holding)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_ask_get_up() -> void:
	if Session.is_host():
		request_get_up(multiplayer.get_remote_sender_id())


## The waiting teammate nearest this game's player within reach (0 = none); never while down.
func help_target() -> int:
	if not is_instance_valid(player) or player.knocked_out:
		return 0
	var best := 0
	var best_d := INF
	for id: int in waiting:
		var p := Session._player_for_peer(id)
		if p == null or p == player:
			continue
		var d := player.global_position.distance_to(p.global_position)
		if d < best_d and ReviveRules.in_reach(player.global_position, p.global_position, player.size_scale()):
			best = id
			best_d = d
	return best


## How full the ring of the help for `friend` is (0 when nobody is helping).
func help_progress(friend: int) -> float:
	if not helping.has(friend):
		return 0.0
	return ReviveRules.progress((Time.get_ticks_msec() - int(helping[friend].since)) / 1000.0)


func _local_help_tick(delta: float) -> void:
	if hud == null or not is_instance_valid(hud) or not is_instance_valid(player):
		return
	_scan -= delta
	if _scan <= 0.0:
		_scan = LOCAL_SCAN
		var target := help_target()
		if target != _help_target and _asking != 0:
			ask_revive(_asking, false)   # walked away from them: let go
		_help_target = target
	var me := player.peer_id
	hud.show_help(_help_target != 0, help_progress(_help_target) if helper_of(_help_target) == me else 0.0)
	var helper := helper_of(me)
	var down_waiting := player.knocked_out and waiting.has(me)
	var words := ""
	if down_waiting:
		words = ReviveRules.helping_you(_display_name(helper)) if helper != 0 else ReviveRules.WAITING
	hud.show_get_up(down_waiting, helper == 0, words, help_progress(me))


func _on_help_pressed() -> void:
	ask_revive(_help_target, true)


func _on_help_released() -> void:
	if _asking != 0:
		ask_revive(_asking, false)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or key.echo or not is_instance_valid(player):
		return
	if key.physical_keycode == HELP_KEY:
		if key.pressed and _help_target != 0:
			_on_help_pressed()
		elif not key.pressed:
			_on_help_released()
	elif key.physical_keycode == GET_UP_KEY and key.pressed and player.knocked_out and waiting.has(player.peer_id):
		ask_get_up()
