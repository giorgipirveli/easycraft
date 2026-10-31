extends Node
## Owns the multiplayer session. Every world edit goes through request_set_block: the host
## validates it (reach, block id, player bodies) and applies it; a client sends it to the host.
## Solo play uses the default OfflineMultiplayerPeer, where the local game is the host.
##
## Join handshake (client scene is loaded before connecting, so replicated nodes have a home):
##   client connects -> hello -> host replies world_info(seed, spawn) -> client builds its world
##   -> client_ready -> host spawns the client's player (replicated to everyone).

signal edit_rejected(pos: Vector3i, id: int)
signal world_info_received(world_seed: int, spawn: Vector3)
signal client_ready(peer_id: int)
signal peer_left(peer_id: int)
signal disconnected
## Host only: the sandbox handles Magic Wand requests (capture + spawn, or sleep).
signal spark_requested(peer_id: int, block_pos: Vector3i)
signal sleep_requested(peer_id: int, buddy_name: String)
## Host only: a player petted an animal (the sandbox tames it, or makes a pet sit or stand).
signal pet_requested(peer_id: int, animal_name: String)
## Local: a short message for this player's HUD.
signal magic_feedback(text: String)
## Local: one undo step for this player's edits, decided by the host (see _send_undo_step).
signal undo_step_received(step: Array)

const DEFAULT_PORT := 24565
const MAX_CLIENTS := 3

var world: WorldService
## Set by the host's sandbox so joining clients can generate the same terrain.
var host_seed := 0
var host_spawn := Vector3.ZERO
var host_mode: StringName = ModeRules.SANDBOX   # sent to guests with the seed (M2)


func _ready() -> void:
	multiplayer.connected_to_server.connect(func() -> void: _rpc_hello.rpc_id(1))
	multiplayer.server_disconnected.connect(func() -> void: disconnected.emit())
	multiplayer.connection_failed.connect(func() -> void: disconnected.emit())
	multiplayer.peer_disconnected.connect(_a_peer_disconnected)   # M4 A: an online guest may come back
	_a_ready()
	_f_ready()   # M4 F: play time
	_shop_ready()   # Owner 35: the shop restores purchases at start
	_costumes_ready()   # Owner 36: costumes earned while playing
	_pt_ready()   # owner #37: trades stop when a player leaves


func register_world(w: WorldService) -> void:
	world = w
	_a_world_registered()


func is_host() -> bool:
	return multiplayer.multiplayer_peer == null or multiplayer.is_server()


## Home Wi-Fi play. M7: a browser can't open ENet connections (spec §20.3): ERR_UNAVAILABLE there, and it stays solo.
func host_lan(port: int = DEFAULT_PORT) -> Error:
	if not PlatformRules.lan_available(PlatformRules.current()):
		return ERR_UNAVAILABLE
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err == OK:
		multiplayer.multiplayer_peer = peer
		_lan_removed.clear()   # M5 Task 6 review: a new LAN game turns nobody away
	return err


func join_lan(address: String, port: int = DEFAULT_PORT) -> Error:
	if not PlatformRules.lan_available(PlatformRules.current()):
		return ERR_UNAVAILABLE
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err == OK:
		multiplayer.multiplayer_peer = peer
	return err


## Back to solo play.
func close() -> void:
	online_reset()   # M4 spike: leaves a Nakama match first (section at the end)
	crew_reset()   # spec §21d.6: no crew move or follow outlives the session
	if not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	world = null
	survivor_reset()


func send_client_ready() -> void:
	_rpc_client_ready.rpc_id(1)


## Returns false if the host rejected the edit (clients return true once sent). The undo step
## arrives from the host (undo_step_received). is_undo: this edit undoes an earlier one.
func request_set_block(pos: Vector3i, id: int, is_undo: bool = false) -> bool:
	if world == null:
		return false
	if is_host():
		return _host_apply(multiplayer.get_unique_id(), pos, id, is_undo)
	_rpc_request_set_block.rpc_id(1, pos, id, is_undo)
	return true


## Several edits at once (mirror pairs, stamps, undo of those): changes = [[Vector3i, id], ...].
## The host applies every valid change and skips the rest. Returns false only if nothing applied.
func request_set_blocks(changes: Array, is_undo: bool = false) -> bool:
	if world == null or changes.is_empty():
		return false
	if is_host():
		return _host_apply_batch(multiplayer.get_unique_id(), changes, is_undo) > 0
	_rpc_request_set_blocks.rpc_id(1, changes, is_undo)
	return true


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_set_blocks(changes: Array, is_undo: bool) -> void:
	if is_host():
		_host_apply_batch(multiplayer.get_remote_sender_id(), changes, is_undo)


func _host_apply_batch(peer_id: int, changes: Array, is_undo: bool = false) -> int:
	var requester := _player_for_peer(peer_id)
	if requester == null:
		return 0
	if not Game.allows(ModeRules.BUILDING):
		send_feedback(peer_id, ArenaRules.NO_BUILDING_WORDS)   # Monster Wave (spec §12.20)
		return 0
	var eye := requester.eye_position()
	var bodies := _player_bodies()
	var applied := 0
	var step: Array = []
	var clean := EditBatch.sanitize(changes)
	var ledger := _batch_ledger(peer_id, clean, is_undo, eye, bodies)   # M2 Task 3: null in Sandbox
	for change: Array in clean:
		var pos: Vector3i = change[0]
		var id: int = change[1]
		var old := world.get_block(pos)
		if PlacementRules.validate_edit(pos, id, old, eye, bodies, PlacementRules.BATCH_REACH) \
				and (ledger == null or ledger.pays(old, id)):
			world.set_block(pos, id)
			applied += 1
			if ledger:
				ledger.changed(old, world.get_block(pos))
		var entry := _undo_entry(pos, id, old, is_undo)
		if not entry.is_empty():
			step.append(entry)
	progress_placed(peer_id, step, is_undo)   # M3 Task 12: blocks placed count for the builder
	_send_undo_step(peer_id, step)
	if ledger and ledger.message != "":
		send_feedback(peer_id, ledger.message)
	return applied


## Host: what the requester can undo after asking for `id` at pos, which held `old`, as
## [pos, id to put back, id there now]: an edit that really changed the cell, or, for an undo,
## a cell it could not restore yet (someone stands there), kept for later. [] for nothing.
func _undo_entry(pos: Vector3i, id: int, old: int, is_undo: bool) -> Array:
	var now := world.get_block(pos)
	if is_undo:
		return [pos, id, now] if now != id else []
	return [pos, old, id] if now == id and old != id else []


## Host -> the player who asked: one undo step. A LAN client can't know which of its edits the host
## refused or skipped, so undo steps come from here, never from the request.
func _send_undo_step(peer_id: int, step: Array) -> void:
	if step.is_empty():
		return
	if peer_id == multiplayer.get_unique_id():
		undo_step_received.emit(step)
	else:
		_rpc_undo_step.rpc_id(peer_id, step)


@rpc("authority", "call_remote", "reliable")
func _rpc_undo_step(step: Array) -> void:
	undo_step_received.emit(step)


## Magic Wand on a build: the host checks reach, then the sandbox captures it.
func request_spark(block_pos: Vector3i) -> void:
	if is_host():
		_host_spark(multiplayer.get_unique_id(), block_pos)
	else:
		_rpc_spark.rpc_id(1, block_pos)


## Magic Wand on a buddy: it turns back into blocks (owner only, within reach).
func request_sleep(buddy_name: String) -> void:
	if is_host():
		sleep_requested.emit(multiplayer.get_unique_id(), buddy_name)
	else:
		_rpc_sleep.rpc_id(1, buddy_name)


## Host -> the player who asked.
func send_feedback(peer_id: int, text: String) -> void:
	if peer_id == multiplayer.get_unique_id():
		magic_feedback.emit(text)
	else:
		_rpc_feedback.rpc_id(peer_id, text)


func _host_spark(peer_id: int, block_pos: Vector3i) -> void:
	var requester := _player_for_peer(peer_id)
	if requester and PlacementRules.in_reach(requester.eye_position(), block_pos, PlacementRules.REACH + PlacementRules.REACH_TOLERANCE):
		spark_requested.emit(peer_id, block_pos)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_spark(block_pos: Vector3i) -> void:
	if is_host():
		_host_spark(multiplayer.get_remote_sender_id(), block_pos)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_sleep(buddy_name: String) -> void:
	if is_host():
		sleep_requested.emit(multiplayer.get_remote_sender_id(), buddy_name)


@rpc("authority", "call_remote", "reliable")
func _rpc_feedback(text: String) -> void:
	magic_feedback.emit(text)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_hello() -> void:
	if is_host() and not _lan_refused.has(multiplayer.get_remote_sender_id()):   # M5 Task 6 review: a removed player
		if crew_hold_hello(multiplayer.get_remote_sender_id()):
			return   # spec §21d.6: the host's world is moving with its crew; the answer comes from the new world
		_answer_hello(multiplayer.get_remote_sender_id())


## Host: a guest's hello answered: its universe, game and terrain, then the world's seed and spawn.
func _answer_hello(peer_id: int) -> void:
	_a_before_world_info(peer_id)   # M4 A: a guest back at its player
	_m3_send_universe(peer_id)   # M3 Task 5: before world_info
	_sgc_send_game(peer_id)   # Survivor games: before world_info too
	_own45b_send_terrain(peer_id)   # owner #45b: the terrain version, before world_info
	_rpc_world_info.rpc_id(peer_id, host_seed, host_spawn, String(host_mode))


@rpc("authority", "call_remote", "reliable")
func _rpc_world_info(world_seed: int, spawn: Vector3, world_mode: String) -> void:
	Game.mode = ModeRules.valid(StringName(world_mode))   # a guest plays by the host's rules
	world_info_received.emit(world_seed, spawn)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_client_ready() -> void:
	if is_host() and not _lan_refused.has(multiplayer.get_remote_sender_id()):   # M5 Task 6 review: a removed player
		client_ready.emit(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_set_block(pos: Vector3i, id: int, is_undo: bool) -> void:
	if is_host():
		_host_apply(multiplayer.get_remote_sender_id(), pos, id, is_undo)


func _host_apply(peer_id: int, pos: Vector3i, id: int, is_undo: bool = false) -> bool:
	var requester := _player_for_peer(peer_id)
	if requester == null:
		edit_rejected.emit(pos, id)
		return false
	var old := world.get_block(pos)
	var reason := PlacementRules.refusal(pos, id, old, requester.eye_position(), _player_bodies())
	if not Game.allows(ModeRules.BUILDING):
		reason = ArenaRules.NO_BUILDING_WORDS   # Monster Wave (spec §12.20): the arena stays as it is
	var ledger := gather_ledger(peer_id, is_undo)   # M2 Task 3: Survivor pays for every edit
	if reason == "" and ledger and not ledger.pays(old, id):
		reason = ledger.message
	if reason == "":
		world.set_block(pos, id)
		if ledger:
			ledger.changed(old, world.get_block(pos))
	else:
		edit_rejected.emit(pos, id)
		send_feedback(peer_id, reason)   # never fail silently: tell the player why
	var entry := _undo_entry(pos, id, old, is_undo)
	progress_placed(peer_id, [entry], is_undo)   # M3 Task 12
	_send_undo_step(peer_id, [entry] if not entry.is_empty() else [])
	return reason == ""


func _player_for_peer(peer_id: int) -> Player:
	for p: Player in get_tree().get_nodes_in_group(&"players"):
		if p.peer_id == peer_id:
			return p
	return null


func _player_bodies() -> Array[AABB]:
	var bodies: Array[AABB] = []
	for p: Player in get_tree().get_nodes_in_group(&"players"):
		if p.is_spawned():
			bodies.append(PlacementRules.player_aabb(p.global_position, p.size_scale()))
	return bodies


## Petting an animal: three quick pets tame a dog or cat; a pet's owner makes it sit or stand.
func request_pet(animal_name: String) -> void:
	if is_host():
		pet_requested.emit(multiplayer.get_unique_id(), animal_name)
	else:
		_rpc_pet.rpc_id(1, animal_name)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pet(animal_name: String) -> void:
	if is_host():
		pet_requested.emit(multiplayer.get_remote_sender_id(), animal_name)

# --- Chat and commands (M1b Task 12) ------------------------------------------------------------
# Each player registers a name and age band with the host once (chat_join). The host checks every
# message against the SENDER's registered band, never against anything the message claims, so a
# client that skips the chat bar and sends raw RPCs still can't send free text as under_13; and
# the first registration wins, so a client can't switch its band later. Trust trade-off: on LAN the
# band is self-declared by the joining device (it is only stored there, spec §4.1), so a modified
# client could lie once at join; M4 moves the band to the server account (Nakama).
# Messages are rate-limited per player, and under_13 players only receive quick-chat phrases.

## A line for this player's chat history. kind: &"chat" (a player's message), &"system", &"error".
signal chat_received(from: String, text: String, kind: StringName)
## Host only: a checked world-changing command (ChatCommands.host_check) for the sandbox.
signal command_requested(peer_id: int, command: Dictionary)

## Survivor (M2) turns commands off except /help. Set on the host.
var commands_enabled := true
## Everyone: peer id -> player name (the host sends updates). For chat lines and /tp name.
var chat_names := {}
var _chat_bands := {}   # host: peer id -> registered age band
var _chat_limiter := ChatRules.RateLimiter.new()


## Registers this player's name and age band for chat. Call once the local player exists.
func chat_join(username: String, band: StringName) -> void:
	if is_host():
		_host_chat_join(multiplayer.get_unique_id(), username, String(band))
	else:
		_rpc_chat_join.rpc_id(1, username, String(band))


## A message from this player to everyone (quick-chat phrase or free text; the host checks it).
func request_chat(text: String) -> void:
	if is_host():
		_host_chat(multiplayer.get_unique_id(), text)
	else:
		_rpc_chat.rpc_id(1, text)


## A world-changing command (ChatCommands.runs_on_host) for the host to check and run.
func request_command(text: String) -> void:
	if is_host():
		_host_command(multiplayer.get_unique_id(), text)
	else:
		_rpc_command.rpc_id(1, text)


## Host -> one player: a line in their chat history (command replies and refusals).
func send_chat_line(peer_id: int, text: String, kind: StringName = &"system", from: String = "") -> void:
	if peer_id == multiplayer.get_unique_id():
		chat_received.emit(from, text, kind)
	else:
		_rpc_chat_line.rpc_id(peer_id, from, text, String(kind))


## Host -> everyone: a system line, like "Bob made it night."
func broadcast_chat_line(text: String) -> void:
	for id in _chat_peers():
		send_chat_line(id, text)


## Forgets every registration and rate count (leaving a game, tests).
func chat_reset() -> void:
	chat_names.clear()
	_chat_bands.clear()
	_chat_limiter.clear()
	_chat_levels.clear()   # M4 Task 10 review B
	_b_waiting.clear()


func _chat_peers() -> Array[int]:
	var ids: Array[int] = [multiplayer.get_unique_id()]
	for id in multiplayer.get_peers():
		ids.append(id)
	return ids


func _host_chat_join(peer_id: int, username: String, band: String) -> void:
	var own := peer_id == multiplayer.get_unique_id()
	if _chat_bands.has(peer_id) and not own:
		return   # the first registration wins
	for id: int in chat_names.keys():   # forget peers of an earlier session
		if not _chat_peers().has(id):
			_chat_forget(id)
	if not own and not peer_left.is_connected(_on_chat_peer_left):
		peer_left.connect(_on_chat_peer_left)
	if not own and _f_online_host():
		_b_join_from_server(peer_id)   # M4 Task 10 review B: online, the server's word, never the guest's
		return
	var b := StringName(band)
	_chat_bands[peer_id] = ChatRules.effective_band(b)
	var player_name := username.strip_edges() if UsernameRules.validate(username) == "" else "Player"
	_chat_named(peer_id, player_name, own)


## Host: names a registered player (unique among the players), tells everyone, and welcomes a guest.
func _chat_named(peer_id: int, player_name: String, own: bool) -> void:
	chat_names[peer_id] = _unique_chat_name(player_name, peer_id)
	_send_chat_names()
	if not own:
		broadcast_chat_line(tr("%s joined the game.") % chat_names[peer_id])


func _unique_chat_name(player_name: String, peer_id: int) -> String:
	var result := player_name
	var n := 2
	while true:
		var taken := false
		for id: int in chat_names:
			if id != peer_id and str(chat_names[id]).to_lower() == result.to_lower():
				taken = true
		if not taken:
			return result
		result = "%s%d" % [player_name, n]
		n += 1
	return result


func _send_chat_names() -> void:
	for id in multiplayer.get_peers():
		_rpc_chat_names.rpc_id(id, chat_names)


func _on_chat_peer_left(peer_id: int) -> void:
	if not is_host():
		return
	if not chat_names.has(peer_id):
		_chat_forget(peer_id)   # M4 Task 10 review B: a name still on its way from the server goes with them
		return
	var player_name: String = chat_names[peer_id]
	_chat_forget(peer_id)
	_send_chat_names()
	broadcast_chat_line(tr("%s left the game.") % player_name)


func _chat_forget(peer_id: int) -> void:
	chat_names.erase(peer_id)
	_chat_bands.erase(peer_id)
	_chat_limiter.forget(peer_id)
	_chat_levels.erase(peer_id)   # M4 Task 10 review B
	_b_waiting.erase(peer_id)


func _host_chat(peer_id: int, text: String) -> void:
	if not _chat_limiter.allow(peer_id, Time.get_ticks_msec() / 1000.0):
		send_chat_line(peer_id, ChatRules.message("too_fast"), &"error")
		return
	# M4 Task 10 review B: online the server-checked team room carries the words; the host's relay carries quick
	# phrases only, whatever anyone's band, and nothing from a player whose grown-up switched chat off.
	var online := _f_online_host()
	if online and str(_chat_levels.get(peer_id, "")) == OnlineRules.CHAT_OFF:
		send_chat_line(peer_id, OnlineChatRules.message("chat_off"), &"error")
		return
	var band: StringName = AgeBand.effective(AgeBand.UNDER_13 if online else _chat_bands.get(peer_id, AgeBand.unknown()))
	var result := ChatRules.check(text.substr(0, ChatRules.MAX_RAW_LENGTH), band)
	if result.has("error"):
		var code: String = "chat_resting" if online and result.error == "quick_chat_only" else result.error
		send_chat_line(peer_id, OnlineChatRules.message(code) if online else ChatRules.message(code), &"error")
		return
	var from: String = chat_names.get(peer_id, "Player")
	for id in chat_recipients(peer_id, result.text, _chat_peers()):
		send_chat_line(id, result.text, &"chat", from)


## Host: who of `peers` receives a checked message from `sender`: the sender, and everyone whose
## registered band may read it (a peer who never registered counts as under 13). M4 Task 10 review B: online,
## never a player whose grown-up switched chat off (the server's chat level).
func chat_recipients(sender: int, text: String, peers: Array[int]) -> Array[int]:
	var out: Array[int] = []
	for id in peers:
		if id != sender and str(_chat_levels.get(id, "")) == OnlineRules.CHAT_OFF:
			continue
		if id == sender or ChatRules.can_receive(text, AgeBand.effective(_chat_bands.get(id, AgeBand.unknown()))):
			out.append(id)
	return out


func _host_command(peer_id: int, text: String) -> void:
	if not _chat_limiter.allow(peer_id, Time.get_ticks_msec() / 1000.0):
		send_chat_line(peer_id, ChatRules.message("too_fast"), &"error")
		return
	var cmd := ChatCommands.host_check(text.substr(0, ChatRules.MAX_RAW_LENGTH), commands_enabled, Game.mode)
	if cmd.has("error"):
		send_chat_line(peer_id, cmd.error, &"error")
		return
	command_requested.emit(peer_id, cmd)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_chat_join(username: String, band: String) -> void:
	if is_host():
		_host_chat_join(multiplayer.get_remote_sender_id(), username, band)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_chat(text: String) -> void:
	if is_host():
		_host_chat(multiplayer.get_remote_sender_id(), text)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_command(text: String) -> void:
	if is_host():
		_host_command(multiplayer.get_remote_sender_id(), text)


@rpc("authority", "call_remote", "reliable")
func _rpc_chat_line(from: String, text: String, kind: String) -> void:
	chat_received.emit(from, text, StringName(kind))


@rpc("authority", "call_remote", "reliable")
func _rpc_chat_names(names: Dictionary) -> void:
	chat_names = names

# --- M4 Task 10 review B (module 0.2.11): online, the host's word on its players is the server's ----------------
# chat_join's name and band are the guest's own word: on LAN they are trusted (the joining device, spec §12.11);
# online a modified guest could show another player's name (chat lines, name tags, trades) or claim 13+. An online
# host asks the server who is in its match (match_players, MatchRoster) and registers each guest with the account's
# username, band and chat level; until the answer the guest counts as under 13 and has no name, and when the server
# can't say, the guest is "Player" and under 13. The relay chat carries quick phrases only online (_host_chat).

var _chat_levels := {}   # host, online: peer id -> the server's chat level (off: no relay chat to or from them)
var _b_roster: MatchRoster
var _b_waiting := {}     # host, online: peer id -> the lookup on its way (a number: the newest wins)
var _b_asks := 0


## The host's view of its online match's players from the server (made on first use with this device's service).
func online_roster() -> MatchRoster:
	if _b_roster == null:
		_b_roster = MatchRoster.new()
		_b_roster.service = online_service()
		_b_roster.user_of = _f_user_of
		_b_roster.match_id = online_hosted_match
	return _b_roster


## Tests: this roster (a fake server) and whether this game acts as an online host; null forgets.
func use_online_roster(r: MatchRoster, online_host: bool) -> void:
	_b_roster = r
	_f_test_online_host = online_host


func _b_join_from_server(peer_id: int) -> void:
	_chat_bands[peer_id] = AgeBand.unknown()   # until the server answers (the first registration still wins)
	_b_asks += 1
	var ask := _b_asks
	_b_waiting[peer_id] = ask
	var p: Dictionary = await online_roster().lookup(peer_id)
	if int(_b_waiting.get(peer_id, 0)) != ask:
		return   # left meanwhile (or the game ended)
	_b_waiting.erase(peer_id)
	if p.is_empty():
		_chat_named(peer_id, "Player", false)
		return
	_chat_bands[peer_id] = ChatRules.effective_band(p.age_band)
	_chat_levels[peer_id] = str(p.chat_level)
	_chat_named(peer_id, str(p.username) if str(p.username) != "" else "Player", false)

# --- Time of day, beds and sleeping (M1b Task 10) ---------------------------------------------
# The host owns the clock (SkyCycle) and decides who sleeps (SleepDirector); it tells everyone.

## Everyone but the host: the host's clock.
signal time_received(time_of_day: float)
## Host only: a player asks to lie down in the bed at bed_pos, or to get up.
signal bed_sleep_requested(peer_id: int, bed_pos: Vector3i)
signal bed_wake_requested(peer_id: int)
## Everyone, from the host: who sleeps where; this player's home; "go home".
signal sleep_state_received(peer_id: int, asleep: bool, bed_pos: Vector3i)
signal home_received(has_home: bool, bed_pos: Vector3i)
signal go_home_received


## Host -> every client.
func broadcast_time(time_of_day: float) -> void:
	if is_host() and not multiplayer.get_peers().is_empty():
		_rpc_time.rpc(time_of_day)


## Host -> one client (a player who just joined).
func send_time(peer_id: int, time_of_day: float) -> void:
	if is_host() and multiplayer.get_peers().has(peer_id):
		_rpc_time.rpc_id(peer_id, time_of_day)


@rpc("authority", "call_remote", "reliable")
func _rpc_time(time_of_day: float) -> void:
	time_received.emit(time_of_day)


func request_bed_sleep(bed_pos: Vector3i) -> void:
	if is_host():
		bed_sleep_requested.emit(multiplayer.get_unique_id(), bed_pos)
	else:
		_rpc_bed_sleep.rpc_id(1, bed_pos)


func request_bed_wake() -> void:
	if is_host():
		bed_wake_requested.emit(multiplayer.get_unique_id())
	else:
		_rpc_bed_wake.rpc_id(1)


## Host -> everyone, itself included.
func broadcast_sleep_state(peer_id: int, asleep: bool, bed_pos: Vector3i) -> void:
	sleep_state_received.emit(peer_id, asleep, bed_pos)
	if not multiplayer.get_peers().is_empty():
		_rpc_sleep_state.rpc(peer_id, asleep, bed_pos)


## Host -> one player (who just joined).
func send_sleep_state(to_peer: int, peer_id: int, asleep: bool, bed_pos: Vector3i) -> void:
	if to_peer == multiplayer.get_unique_id():
		sleep_state_received.emit(peer_id, asleep, bed_pos)
	elif multiplayer.get_peers().has(to_peer):
		_rpc_sleep_state.rpc_id(to_peer, peer_id, asleep, bed_pos)


## Host -> the player whose home it is.
func send_home(peer_id: int, has_home: bool, bed_pos: Vector3i) -> void:
	if peer_id == multiplayer.get_unique_id():
		home_received.emit(has_home, bed_pos)
	elif multiplayer.get_peers().has(peer_id):
		_rpc_home.rpc_id(peer_id, has_home, bed_pos)


## Host -> a player: back to your bed, or to the world spawn without one.
func send_go_home(peer_id: int) -> void:
	if peer_id == multiplayer.get_unique_id():
		go_home_received.emit()
	elif multiplayer.get_peers().has(peer_id):
		_rpc_go_home.rpc_id(peer_id)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_bed_sleep(bed_pos: Vector3i) -> void:
	if is_host():
		bed_sleep_requested.emit(multiplayer.get_remote_sender_id(), bed_pos)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_bed_wake() -> void:
	if is_host():
		bed_wake_requested.emit(multiplayer.get_remote_sender_id())


@rpc("authority", "call_remote", "reliable")
func _rpc_sleep_state(peer_id: int, asleep: bool, bed_pos: Vector3i) -> void:
	sleep_state_received.emit(peer_id, asleep, bed_pos)


@rpc("authority", "call_remote", "reliable")
func _rpc_home(has_home: bool, bed_pos: Vector3i) -> void:
	home_received.emit(has_home, bed_pos)


@rpc("authority", "call_remote", "reliable")
func _rpc_go_home() -> void:
	go_home_received.emit()

# --- Weapons and practice targets (M1b Task 11) ---
# The host checks every attack here (a real weapon, a sane aim, the weapon's cooldown per player);
# the sandbox's CombatDirector then resolves it with the host's own positions (reach per hit).
# Tool powers need nothing new: they are block batches (request_set_blocks).

## Host only: a validated attack, and target requests, for the CombatDirector.
signal attack_requested(peer_id: int, weapon_id: int, dir: Vector3, power: float)
signal target_requested(peer_id: int, item_id: int, cell: Vector3i, yaw: float)
signal target_removal_requested(peer_id: int, target_name: String)
## Local: a hit pushed this player (each player simulates its own body).
signal knocked_back(impulse: Vector3)

const MAX_KNOCKBACK := 30.0

var _last_attack := {}   # peer id -> msec of its last accepted attack


## Attacks with a weapon in direction `dir` (power: the bow's draw, 0..1).
func request_attack(weapon_id: int, dir: Vector3, power: float = 1.0) -> void:
	if is_host():
		_host_attack(multiplayer.get_unique_id(), weapon_id, dir, power)
	else:
		_rpc_attack.rpc_id(1, weapon_id, dir, power)


## Host check of one attack at time now_ms; records it when accepted.
func accept_attack(peer_id: int, weapon_id: int, dir: Vector3, power: float, now_ms: int) -> bool:
	if not WeaponRules.is_weapon(weapon_id) or not dir.is_finite() or dir.length() < 0.001 or is_nan(power):
		return false
	if not owns_weapon(peer_id, weapon_id):   # M2 Task 6: Survivor attacks only with what you own
		return false
	if not WeaponRules.cooldown_ok(int(_last_attack.get(peer_id, -1)), now_ms, weapon_id):
		return false
	_last_attack[peer_id] = now_ms
	return true


func _host_attack(peer_id: int, weapon_id: int, dir: Vector3, power: float) -> void:
	if accept_attack(peer_id, weapon_id, dir, power, Time.get_ticks_msec()):
		attack_requested.emit(peer_id, weapon_id, dir.normalized(), clampf(power, 0.0, 1.0))


@rpc("any_peer", "call_remote", "reliable")
func _rpc_attack(weapon_id: int, dir: Vector3, power: float) -> void:
	if is_host():
		_host_attack(multiplayer.get_remote_sender_id(), weapon_id, dir, power)


## Places a practice dummy or bullseye (item) standing in `cell`, turned to `yaw`.
func request_place_target(item_id: int, cell: Vector3i, yaw: float) -> void:
	if is_host():
		target_requested.emit(multiplayer.get_unique_id(), item_id, cell, yaw)
	else:
		_rpc_place_target.rpc_id(1, item_id, cell, yaw)


func request_remove_target(target_name: String) -> void:
	if is_host():
		target_removal_requested.emit(multiplayer.get_unique_id(), target_name)
	else:
		_rpc_remove_target.rpc_id(1, target_name)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_place_target(item_id: int, cell: Vector3i, yaw: float) -> void:
	if is_host():
		target_requested.emit(multiplayer.get_remote_sender_id(), item_id, cell, yaw)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_remove_target(target_name: String) -> void:
	if is_host():
		target_removal_requested.emit(multiplayer.get_remote_sender_id(), target_name)


## Host -> a player: a push from a hit. Players are never hurt.
func send_knockback(peer_id: int, impulse: Vector3) -> void:
	if peer_id == multiplayer.get_unique_id():
		knocked_back.emit(impulse.limit_length(MAX_KNOCKBACK))
	else:
		_rpc_knockback.rpc_id(peer_id, impulse)


@rpc("authority", "call_remote", "reliable")
func _rpc_knockback(impulse: Vector3) -> void:
	if impulse.is_finite():
		knocked_back.emit(impulse.limit_length(MAX_KNOCKBACK))


# --- M2 Task 1: Survivor gold, inventories and health (the host decides every change) -----------
# Gold: each player's Survivor gold is their own profile's. The host keeps a wallet per player for
# the session (its own is the profile; a LAN guest's starts from what the guest reports when it joins,
# trusted on LAN until M4's server wallet, spec §12.11) and sends every change to that player, whose
# game writes it into its profile. Changes stay in memory; the world's save writes the profile.
# Inventories (§12.2) belong to the world and live on the host; health (§12.3) is decided on the host
# and broadcast.

## This game's Survivor gold changed (the HUD shows it).
signal gold_changed(balance: int)
## A player's hearts changed (host -> everyone): hp after, where the hit came from.
signal player_hurt(peer_id: int, hp: int, from: Vector3)

var _wallets := {}       # host: peer id -> Wallet (never the local player's: that is the profile)
var _inventories := {}   # host: peer id -> Inventory


## Host: gives a player gold (monsters, waves, the boss, selling). Survivor only; Sandbox gold is ∞.
func gold_add(peer_id: int, amount: int, _reason: String = "") -> void:
	if not is_host() or amount <= 0 or Game.allows(ModeRules.INFINITE_GOLD):
		return
	var w := _wallet(peer_id)
	var before := w.balance
	w.add(amount)
	_f_host_gold(peer_id, w.balance - before)   # M4 F: online, the server's ledger
	_store_gold(peer_id, w.balance)


## Host: takes gold from a player when they have enough (buying, flying). Sandbox pays for anything.
func gold_spend(peer_id: int, amount: int) -> bool:
	if not is_host() or amount < 0:
		return false
	if Game.allows(ModeRules.INFINITE_GOLD):
		return true
	var w := _wallet(peer_id)
	if not w.spend(amount):
		return false
	_f_host_gold(peer_id, -amount)   # M4 F
	_store_gold(peer_id, w.balance)
	return true


func gold_of(peer_id: int) -> int:
	return _wallet(peer_id).balance


func _wallet(peer_id: int) -> Wallet:
	if peer_id == multiplayer.get_unique_id():
		return Wallet.new(Profile.data.survivor_gold)
	if not _wallets.has(peer_id):
		_wallets[peer_id] = Wallet.new(0)
	return _wallets[peer_id]


func _store_gold(peer_id: int, balance: int) -> void:
	if peer_id == multiplayer.get_unique_id():
		_f_gold_moved(Profile.data.survivor_gold, balance)   # M4 F: the server's wallet ledger
		Profile.data.survivor_gold = balance
		gold_changed.emit(balance)
	else:
		var old := (_wallets[peer_id] as Wallet).balance if _wallets.has(peer_id) else 0
		_wallets[peer_id] = Wallet.new(balance)
		if _f_online_host():   # M4 F: online, the guest's game follows the change (the server keeps the balance)
			_rpc_gold_moved.rpc_id(peer_id, balance, balance - old, online_wallets().seq_of(peer_id))
		else:
			_rpc_gold.rpc_id(peer_id, balance)


## A LAN guest tells the host its Survivor gold once it has joined (trusted LAN, spec §12.11).
func gold_hello() -> void:
	if not is_host():
		_rpc_gold_hello.rpc_id(1, Profile.data.survivor_gold)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_gold_hello(balance: int) -> void:
	var id := multiplayer.get_remote_sender_id()
	if is_host() and not _wallets.has(id) and not _f_seed_guest(id, balance):   # M4 F: online, the server's word
		_wallets[id] = Wallet.new(balance)


@rpc("authority", "call_remote", "reliable")
func _rpc_gold(balance: int) -> void:
	_f_gold_moved(Profile.data.survivor_gold, Wallet.new(balance).balance)   # M4 F
	Profile.data.survivor_gold = Wallet.new(balance).balance
	gold_changed.emit(Profile.data.survivor_gold)


## Host: a player's counted blocks and items (Survivor). The sandbox gives the local player's from the
## world save; a guest gets the one saved under their name, or a starter kit.
func set_inventory(peer_id: int, inv: Inventory) -> void:
	_watch_inventory(peer_id, inv)   # M2 Task 3: that player's HUD hears every change
	_inventories[peer_id] = inv
	# Owner #83: what the Gold Shop put in the backpack comes into this game's own next Survivor world (once).
	if peer_id == multiplayer.get_unique_id() and Game.mode == ModeRules.SURVIVOR and not Profile.data.backpack.is_empty():
		SpendRules.unpack_backpack(Profile.data, inv)
		Profile.save()


func inventory_of(peer_id: int) -> Inventory:
	if not _inventories.has(peer_id):
		set_inventory(peer_id, Inventory.new())
	return _inventories[peer_id]


## Host: this world's Survivor difficulty (DifficultyRules; the sandbox sets it from the world).
var difficulty: StringName = DifficultyRules.NORMAL


## Host: hurts a player (monsters, traps, the boss). Knock-outs are handled by Task 2 on
## player_hurt with hp == 0.
func hurt_player(peer_id: int, amount: int, from: Vector3) -> void:
	if not is_host() or amount <= 0 or not Game.allows(ModeRules.DAMAGE):
		return
	var p := _player_for_peer(peer_id)
	if p == null:
		return
	amount = DifficultyRules.damage(amount, difficulty)   # M2 Task 17: Cozy half, Brave half again
	amount = shielded_amount(peer_id, amount, from)   # M2 Task 6: a shield takes its share
	if amount <= 0:
		return
	var before := p.health.hp
	p.health.damage(amount)
	if p.health.hp == before:
		return   # knocked out already, or protected: nothing to tell (M2 Task 2)
	_rpc_health.rpc(peer_id, p.health.hp, from)
	player_hurt.emit(peer_id, p.health.hp, from)


## Host -> everyone: a player's hearts after a hit or a heal.
func broadcast_health(peer_id: int, hp: int) -> void:
	if is_host():
		_rpc_health.rpc(peer_id, hp, Vector3.INF)


@rpc("authority", "call_remote", "reliable")
func _rpc_health(peer_id: int, hp: int, from: Vector3) -> void:
	var p := _player_for_peer(peer_id)
	if p:
		p.health.hp = clampi(hp, 0, Health.MAX_HP)
	player_hurt.emit(peer_id, clampi(hp, 0, Health.MAX_HP), from)


## Forgets every guest's wallet and inventory (leaving a game, tests).
func survivor_reset() -> void:
	_wallets.clear()
	_inventories.clear()
	_inventory_dirty.clear()           # M2 Task 3
	my_inventory = Inventory.new()
	_shield_carry.clear()              # M2 Task 6
	difficulty = DifficultyRules.NORMAL   # M2 Task 17
	_pt_reset()   # owner #37: no ask or trade outlives its world

# --- M2 Task 3: gathering and counted blocks (Survivor, §12.2) -----------------------------------
# In Survivor the host pays for every edit from the requester's inventory (GatherLedger): breaking
# gives the block's drop (ores need the right pickaxe), placing takes one, and an undo is the exact
# reverse of its edit. A batch of placements (a stamp, mirror copies) is paid for whole or not at
# all; cells a batch can't pay for are skipped like any other refused cell. Sandbox never counts.
# Every change of a player's inventory, whoever makes it (edits, the pickup bag, the trader), reaches
# that player as one snapshot per frame: the HUD reads my_inventory and listens to inventory_changed.

## This game's own blocks and items changed (the hotbar and the palette show them).
signal inventory_changed

## This game's player's blocks and items: on the host its own inventory object, on a LAN guest the
## last snapshot the host sent.
var my_inventory := Inventory.new()

var _inventory_watch := {}   # host: peer id -> the Callable connected to that player's `changed`
var _inventory_dirty := {}   # host: peers whose snapshot goes out at the end of this frame


## Host: pays for one edit request of peer_id in Survivor; null when blocks are not counted.
func gather_ledger(peer_id: int, is_undo: bool) -> GatherLedger:
	if Game.allows(ModeRules.UNLIMITED_BLOCKS):
		return null
	return GatherLedger.new(inventory_of(peer_id), is_undo)


## Host: the ledger for a batch. Its placements are reserved at once over the cells the host's checks
## let through (an undo batch is paid cell by cell: what it can't pay for yet waits for later).
func _batch_ledger(peer_id: int, clean: Array, is_undo: bool, eye: Vector3, bodies: Array[AABB]) -> GatherLedger:
	var ledger := gather_ledger(peer_id, is_undo)
	if ledger == null or is_undo:
		return ledger
	var cells: Array = []
	for change: Array in clean:
		var old := world.get_block(change[0])
		if PlacementRules.validate_edit(change[0], change[1], old, eye, bodies, PlacementRules.BATCH_REACH):
			cells.append([old, change[1]])
	ledger.reserve(cells)
	return ledger


## Host -> a player: their blocks and items now (the host's own player reads the object itself).
func send_inventory(peer_id: int) -> void:
	var inv: Inventory = _inventories.get(peer_id)
	if inv == null:
		return
	if peer_id == multiplayer.get_unique_id():
		my_inventory = inv
		inventory_changed.emit()
	elif multiplayer.get_peers().has(peer_id):
		_rpc_inventory.rpc_id(peer_id, inv.to_save())


func _watch_inventory(peer_id: int, inv: Inventory) -> void:
	if not _inventory_watch.has(peer_id):
		_inventory_watch[peer_id] = _on_inventory_changed.bind(peer_id)
	var cb: Callable = _inventory_watch[peer_id]
	var current: Inventory = _inventories.get(peer_id)
	if current and current != inv and current.changed.is_connected(cb):
		current.changed.disconnect(cb)
	if not inv.changed.is_connected(cb):
		inv.changed.connect(cb)
	_on_inventory_changed(peer_id)


## Many changes in one frame (a 1600-block stamp) send one snapshot.
func _on_inventory_changed(peer_id: int) -> void:
	if _inventory_dirty.is_empty():
		_send_inventories.call_deferred()
	_inventory_dirty[peer_id] = true


func _send_inventories() -> void:
	var peers := _inventory_dirty.keys()
	_inventory_dirty.clear()
	for peer_id: int in peers:
		send_inventory(peer_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_inventory(items: Array) -> void:
	my_inventory = Inventory.from_save(items)
	inventory_changed.emit()


# --- M2 Task 2: knock-outs, getting up and pickup bags --------------------------------------------
# The host decides every knock-out (hp 0 on its own Health) and every bag (KnockoutDirector): it drops
# a Survivor player's carried blocks into a bag, tells everyone, revives the player after a short fade
# and tells them to get up. The player's own game moves its body (Survivor: to the bed or the world
# spawn; Sandbox: on the spot) and says when it has arrived, which ends the protection the host holds
# meanwhile. Taking a bag is a request the host checks (reach, whose bag) like every edit.

## Everyone: a player was knocked out (their avatar lies down; their own screen fades).
## at_home: Survivor, where they get up at home (Sandbox: on the spot).
signal knockout_received(peer_id: int, at_home: bool)
## Everyone: the host revived a player; that player's game moves their body.
signal knockout_respawned(peer_id: int, at_home: bool)
## Host only: a revived player is back on their feet; a player asks to take a bag.
signal knockout_arrived(peer_id: int)
signal bag_take_requested(peer_id: int, bag_name: String)
## Host only: a knock-out or a bag changed this player's inventory (for the hotbar counts).
signal bag_inventory_changed(peer_id: int)


## Host -> everyone, itself included.
func broadcast_knockout(peer_id: int, at_home: bool) -> void:
	if not is_host():
		return
	knockout_received.emit(peer_id, at_home)
	if not multiplayer.get_peers().is_empty():
		_rpc_knockout.rpc(peer_id, at_home)


## Host -> everyone, itself included.
func broadcast_knockout_respawn(peer_id: int, at_home: bool) -> void:
	if not is_host():
		return
	knockout_respawned.emit(peer_id, at_home)
	if not multiplayer.get_peers().is_empty():
		_rpc_knockout_respawn.rpc(peer_id, at_home)


## This player's game: back on my feet after getting up.
func send_knockout_arrived() -> void:
	if is_host():
		knockout_arrived.emit(multiplayer.get_unique_id())
	else:
		_rpc_knockout_arrived.rpc_id(1)


## Takes the pickup bag with this node name (the host checks reach and whose it is).
func request_take_bag(bag_name: String) -> void:
	if is_host():
		bag_take_requested.emit(multiplayer.get_unique_id(), bag_name)
	else:
		_rpc_take_bag.rpc_id(1, bag_name)


@rpc("authority", "call_remote", "reliable")
func _rpc_knockout(peer_id: int, at_home: bool) -> void:
	knockout_received.emit(peer_id, at_home)


@rpc("authority", "call_remote", "reliable")
func _rpc_knockout_respawn(peer_id: int, at_home: bool) -> void:
	knockout_respawned.emit(peer_id, at_home)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_knockout_arrived() -> void:
	if is_host():
		knockout_arrived.emit(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func _rpc_take_bag(bag_name: String) -> void:
	if is_host():
		bag_take_requested.emit(multiplayer.get_remote_sender_id(), bag_name.substr(0, 64))


# --- M2 Task 7: Tilly the trader, trades and the cost of flying (the host decides) ---------------
# A player taps Tilly and the shop opens; it asks the host for the player's counted things
# (request_shop). Every trade is checked on the host: a Survivor world, the player within
# TraderRules.HOST_REACH of a trader (group "traders"), then ShopRules (gold, room, a tool already
# owned, for sale / sellable). The host moves the gold (gold_spend / gold_add, which tell the player)
# and the inventory, and answers with the result and the player's things (trade_done,
# trade_inventory_received). Flying: each physics step the host charges every Survivor player in FLY
# mode (their synced physics_mode) through a FlyCost meter; one who can't pay lands gently. Owner #78: the fuel follows
# the machine the child invented (their synced flight_craft, InventionRules.fuel_factor): a balloon flies free, a jet
# burns twice the plane's.

## This player's counted things, from the host: [[id, count], ...] (the shop's Sell tab).
signal trade_inventory_received(items: Array)
## The host's answer to one of this player's trades: what it said, what moved and the gold paid/got.
signal trade_done(ok: bool, text: String, id: int, count: int, gold: int)

const FLY_LAND_RESEND_MS := 2000

var _fly_meters := {}    # host: peer id -> FlyCost
var _fly_landing := {}   # host: peer id -> msec it was told to land


## Opening the shop: the host sends this player's things.
func request_shop() -> void:
	if is_host():
		_send_trade_inventory(multiplayer.get_unique_id())
	else:
		_rpc_shop.rpc_id(1)


## Buys one purchase of id, or sells `count` of it.
func request_trade(buying: bool, id: int, count: int = 1) -> void:
	if is_host():
		host_trade(multiplayer.get_unique_id(), buying, id, count)
	else:
		_rpc_trade.rpc_id(1, buying, id, count)


## Host: checks and applies one trade and tells the player. Returns ShopRules' result.
func host_trade(peer_id: int, buying: bool, id: int, count: int) -> Dictionary:
	var result := {"ok": false, "error": "", "gold": 0, "id": id, "count": 0}
	if not TraderRules.wants_trader(Game.mode) or Game.allows(ModeRules.INFINITE_GOLD):
		result.error = "survivor_only"
	elif not _near_trader(peer_id):
		result.error = "too_far"
	elif buying and farm_buy_refusal(peer_id, id) != "":   # M3 Task 10: one farm per world, the owner's
		result.error = farm_buy_refusal(peer_id, id)
	elif buying and _pt_market_sells(peer_id, id):   # owner #37: Nico's things on market day
		result = _pt_market_buy(peer_id, id)
	else:
		var inv := inventory_of(peer_id)
		var wallet := Wallet.new(gold_of(peer_id))   # a copy: the real gold moves below
		if buying:
			result = ShopRules.buy(id, wallet, inv, Game.universe, Game.survivor_game)   # M3 Task 5: × 2^(u−1); §12.18
			if result.ok and not gold_spend(peer_id, result.gold):
				inv.take(id, result.count)
				result = {"ok": false, "error": "gold", "gold": 0, "id": id, "count": 0}
		else:
			result = ShopRules.sell(id, clampi(count, 0, Inventory.MAX_COUNT), wallet, inv, Game.universe)
			if result.ok:
				gold_add(peer_id, result.gold, "sell")
	var text := ShopRules.done_message(buying, id, result.count, result.gold) if result.ok else ShopRules.message(result.error)
	_send_trade_done(peer_id, result.ok, text, id, result.count, result.gold)
	if result.ok:
		_send_trade_inventory(peer_id)
	return result


func _near_trader(peer_id: int) -> bool:
	var p := _player_for_peer(peer_id)
	if p == null:
		return false
	for t in get_tree().get_nodes_in_group(&"traders"):
		if t is Node3D and TraderRules.in_reach(p.eye_position(), (t as Node3D).global_position, TraderRules.HOST_REACH):
			return true
	return false


func _send_trade_done(peer_id: int, ok: bool, text: String, id: int, count: int, gold: int) -> void:
	if peer_id == multiplayer.get_unique_id():
		trade_done.emit(ok, text, id, count, gold)
	elif multiplayer.get_peers().has(peer_id):
		_rpc_trade_done.rpc_id(peer_id, ok, text, id, count, gold)


func _send_trade_inventory(peer_id: int) -> void:
	var items := inventory_of(peer_id).to_save()
	if peer_id == multiplayer.get_unique_id():
		trade_inventory_received.emit(items)
	elif multiplayer.get_peers().has(peer_id):
		_rpc_trade_inventory.rpc_id(peer_id, items)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_shop() -> void:
	if is_host():
		_send_trade_inventory(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func _rpc_trade(buying: bool, id: int, count: int) -> void:
	if is_host():
		host_trade(multiplayer.get_remote_sender_id(), buying, id, count)


@rpc("authority", "call_remote", "reliable")
func _rpc_trade_done(ok: bool, text: String, id: int, count: int, gold: int) -> void:
	trade_done.emit(ok, text, id, count, gold)


@rpc("authority", "call_remote", "reliable")
func _rpc_trade_inventory(items: Array) -> void:
	trade_inventory_received.emit(Inventory.from_save(items).to_save())


func _physics_process(delta: float) -> void:
	if world == null:
		if not _fly_meters.is_empty():
			fly_reset()
		return
	var peer := multiplayer.multiplayer_peer
	if peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return   # M3 Task 19: a guest whose host left (its goodbye shows); is_host() logged an error every frame
	if is_host():
		fly_tick(delta)
		_tool_tick()   # M3 Task 8: a big tool edit, a slice a frame
		_pt_tick()   # owner #37: open trades' offers held to the bags


## Host: charges every Survivor player who is flying (Sandbox flies free) and lands those who can't pay.
func fly_tick(delta: float) -> void:
	if not is_host() or Game.allows(ModeRules.FREE_FLY):
		return
	var now := Time.get_ticks_msec()
	for p: Player in get_tree().get_nodes_in_group(&"players"):
		if not is_instance_valid(p) or p.is_queued_for_deletion():
			continue
		var peer := p.peer_id
		if not p.is_spawned() or p.physics_mode != PhysicsMode.Mode.FLY:
			_fly_landing.erase(peer)
			continue
		if now - int(_fly_landing.get(peer, -FLY_LAND_RESEND_MS)) < FLY_LAND_RESEND_MS:
			continue   # told to land; a guest's mode takes a moment to arrive
		var fuel := InventionRules.fuel_factor(p.flight_craft)   # owner #78: the balloon is free, the jet burns twice
		if fuel <= 0:
			_fly_meters.erase(peer)
			continue
		if not _fly_meters.has(peer):
			_fly_meters[peer] = FlyCost.new()
		var pay := func(amount: int) -> bool:   # M3 Task 5: the universe's price
			return gold_spend(peer, UniverseRules.price(amount, Game.universe) * fuel)
		if not (_fly_meters[peer] as FlyCost).tick(delta, true, pay):
			_fly_landing[peer] = now
			_send_fly_land(peer)


## Forgets every flight clock (leaving a world, tests).
func fly_reset() -> void:
	_fly_meters.clear()
	_fly_landing.clear()


## Host -> a flyer who is out of gold: land gently.
func _send_fly_land(peer_id: int) -> void:
	if peer_id == multiplayer.get_unique_id():
		_land_local_player()
	elif multiplayer.get_peers().has(peer_id):
		_rpc_fly_land.rpc_id(peer_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_fly_land() -> void:
	_land_local_player()


func _land_local_player() -> void:
	var p := _player_for_peer(multiplayer.get_unique_id())
	if p:
		p.land_gently()
	magic_feedback.emit(FlyCost.LANDED_MESSAGE)

# --- M2 Task 6: potions, spear throws and shields -----------------------------------------------
# Potions: a tap on a potion's hotbar slot asks the host (request_drink). The host refuses a potion
# that is still working and, in Survivor, takes one from the player's inventory; then every game
# starts it on that player (Player.drink). Spear throws are checked like attacks (a spear, a sane
# aim, the shared cooldown) and flown by the CombatDirector. Shields (passive, ruling 5):
# hurt_player first asks shielded_amount(), which takes the best owned shield's share off a blow from
# the front (Survivor: the inventory; Sandbox: the shield carried in the hotbar, Player.carried_shield).

## Everyone: a player drank a potion (the HUD shows its timer).
signal potion_started(peer_id: int, potion_id: int)
## Host only: a checked spear throw for the CombatDirector.
signal spear_throw_requested(peer_id: int, weapon_id: int, dir: Vector3)
## Everyone: a player's shield took `share` of a blow.
signal shield_blocked(peer_id: int, share: float)

var _shield_carry := {}   # host: peer id -> the part of a hit point a shield left over (WeaponRules.shielded_damage)


## Drinks a potion from the hotbar (the host decides).
func request_drink(potion_id: int) -> void:
	if is_host():
		_host_drink(multiplayer.get_unique_id(), potion_id)
	else:
		_rpc_drink.rpc_id(1, potion_id)


## Host: returns true when the player drank it (and everyone was told).
func _host_drink(peer_id: int, potion_id: int) -> bool:
	var p := _player_for_peer(peer_id)
	if p == null:
		return false
	var unlimited := Game.allows(ModeRules.UNLIMITED_BLOCKS)
	var inv := inventory_of(peer_id)
	var why := PotionRules.refusal(potion_id, p.potions, unlimited, inv.count(potion_id))
	if why != "":
		if why != "?":
			send_feedback(peer_id, why)
		return false
	if not unlimited and not inv.take(potion_id, 1):
		return false
	if p.drink(potion_id):
		potion_started.emit(peer_id, potion_id)
	if not multiplayer.get_peers().is_empty():
		_rpc_potion.rpc(peer_id, potion_id, PotionRules.seconds(potion_id))
	if not client_ready.is_connected(_send_working_potions):
		client_ready.connect(_send_working_potions)   # players who join later hear about them
	return true


## Host: every potion working on a player now, as [peer id, potion id, seconds left].
func working_potions() -> Array:
	var out: Array = []
	for p: Player in get_tree().get_nodes_in_group(&"players"):
		for id in p.potions.active_ids():
			out.append([p.peer_id, id, p.potions.time_left(id)])
	return out


func _send_working_potions(to_peer: int) -> void:
	if not multiplayer.get_peers().has(to_peer):
		return
	for e: Array in working_potions():
		_rpc_potion.rpc_id(to_peer, e[0], e[1], e[2])


@rpc("any_peer", "call_remote", "reliable")
func _rpc_drink(potion_id: int) -> void:
	if is_host():
		_host_drink(multiplayer.get_remote_sender_id(), potion_id)


## Host -> guests: a player's potion and its seconds left (the host's word wins over the guest's timer).
@rpc("authority", "call_remote", "reliable")
func _rpc_potion(peer_id: int, potion_id: int, seconds: float) -> void:
	var p := _player_for_peer(peer_id)
	if p and p.sync_potion(potion_id, seconds):
		potion_started.emit(peer_id, potion_id)


## Throws the spear `weapon_id` along `dir`.
func request_spear_throw(weapon_id: int, dir: Vector3) -> void:
	if is_host():
		_host_spear_throw(multiplayer.get_unique_id(), weapon_id, dir)
	else:
		_rpc_spear_throw.rpc_id(1, weapon_id, dir)


func _host_spear_throw(peer_id: int, weapon_id: int, dir: Vector3) -> void:
	if WeaponRules.base_of(weapon_id) != ItemIds.SPEAR:
		return
	if accept_attack(peer_id, weapon_id, dir, 1.0, Time.get_ticks_msec()):
		spear_throw_requested.emit(peer_id, weapon_id, dir.normalized())


@rpc("any_peer", "call_remote", "reliable")
func _rpc_spear_throw(weapon_id: int, dir: Vector3) -> void:
	if is_host():
		_host_spear_throw(multiplayer.get_remote_sender_id(), weapon_id, dir)


## Host: may this player attack with `weapon_id`? Survivor: only with one in the inventory (tiers
## make a stranger weapon much stronger); Sandbox has everything. Everybody has fists (owner feedback #29).
func owns_weapon(peer_id: int, weapon_id: int) -> bool:
	return weapon_id == WeaponRules.FISTS or Game.allows(ModeRules.UNLIMITED_BLOCKS) or inventory_of(peer_id).has(weapon_id)


## Host: the best shield a player owns (0 for none): Survivor counts the inventory, Sandbox the
## shield the player carries in the hotbar.
func best_shield_of(peer_id: int) -> int:
	if Game.allows(ModeRules.UNLIMITED_BLOCKS):
		var p := _player_for_peer(peer_id)
		return p.carried_shield if p and WeaponRules.is_shield(p.carried_shield) else 0
	return WeaponRules.best_shield(inventory_of(peer_id).ids())


## Host: what is left of a blow of `amount` from `from` after the player's shield (a blow from the
## front, within WeaponRules.SHIELD_ARC of where the player faces). Everyone sees a block.
func shielded_amount(peer_id: int, amount: int, from: Vector3) -> int:
	var p := _player_for_peer(peer_id)
	if p == null or amount <= 0 or not from.is_finite():
		return amount
	var yaw := p.avatar.rotation.y if p.avatar else 0.0
	var facing := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var share := WeaponRules.shield_block(best_shield_of(peer_id), p.global_position - from, facing)
	if share <= 0.0:
		return amount
	var r := WeaponRules.shielded_damage(amount, share, float(_shield_carry.get(peer_id, 0.0)))
	_shield_carry[peer_id] = r.carry
	_shield_fx(peer_id, share)
	if not multiplayer.get_peers().is_empty():
		_rpc_shield_fx.rpc(peer_id, share)
	return int(r.damage)


func _shield_fx(peer_id: int, share: float) -> void:
	var p := _player_for_peer(peer_id)
	if p == null:
		return
	var yaw := p.avatar.rotation.y if p.avatar else 0.0
	var front := p.global_position + Vector3(-sin(yaw), 0.0, -cos(yaw)) * 0.5 * p.size_scale() + Vector3(0, 1.0 * p.size_scale(), 0)
	Fx.burst(get_tree().root, front, Color("fff4d6"), 8, 3.0, 0.08, 0.3, 4.0)
	Audio.play(&"thud", front, -2.0)
	shield_blocked.emit(peer_id, share)


@rpc("authority", "call_remote", "unreliable")
func _rpc_shield_fx(peer_id: int, share: float) -> void:
	if is_finite(share):
		_shield_fx(peer_id, clampf(share, 0.0, 1.0))

# --- M2 Task 15: bot friends ------------------------------------------------------------------
# Bot friends are host-simulated companions, not network players (ruling 13). A builder's blocks
# go through the host's own checks (valid ids, reach from the bot, never bedrock, never inside a
# player or a friend) and only ever fill empty cells, so a friend never replaces, breaks or takes a
# player's blocks; nobody gets an undo step for them. Their chat lines are fixed, friendly phrases
# (BotRules) that go to everyone, marked as a bot ("Pip (bot)"); they hear only their own child's
# words (owner 38's section at the end).

## Host: a bot friend's small build, [[Vector3i, id], ...] from its eye; returns the blocks placed.
func bot_set_blocks(changes: Array, bot_eye: Vector3) -> int:
	if world == null or not is_host() or not bot_eye.is_finite() or not Game.allows(ModeRules.BUILDING):
		return 0   # (Monster Wave's arena: nothing is built, spec §12.20)
	var bodies := _player_bodies()
	for n in get_tree().get_nodes_in_group(&"bot_friends"):
		bodies.append(PlacementRules.player_aabb((n as Node3D).global_position))
	var placed := 0
	for change: Array in EditBatch.sanitize(changes, BotRules.MAX_BUILD_BLOCKS):
		var pos: Vector3i = change[0]
		var id: int = change[1]
		var old := world.get_block(pos)
		if id == BlockIds.AIR or old != BlockIds.AIR or not PlacementRules.validate_edit(pos, id, old, bot_eye, bodies):
			continue
		world.set_block(pos, id)
		if world.get_block(pos) == id:
			placed += 1
	return placed


## Host -> everyone: a bot friend's line in the chat.
func bot_say(bot_name: String, text: String) -> void:
	if not is_host():
		return
	for id in _chat_peers():
		send_chat_line(id, text, &"bot", BotRules.chat_name(bot_name))


# --- M2 Task 16: secrets and treasures -----------------------------------------------------------
# A player asks; the host's SecretDirector (node "Secrets" on every peer) decides — reach, a chest opens
# once per world, a temple's chest stays locked until its plates are solved, the Wanderer rewards the first
# right answer once — and tells everyone what happened through its own RPCs. Golden animals are caught
# through request_pet (the sandbox hands a golden animal to the director).

## Host only: a player asks to open a chest, knocks on a fake wall, or answers the Wanderer's riddle.
signal secret_chest_requested(peer_id: int, chest_name: String)
signal secret_knock_requested(peer_id: int, pos: Vector3i)
signal secret_answer_requested(peer_id: int, visitor_name: String, choice: int)


func request_open_chest(chest_name: String) -> void:
	if is_host():
		secret_chest_requested.emit(multiplayer.get_unique_id(), chest_name)
	else:
		_rpc_secret_chest.rpc_id(1, chest_name)


func request_knock(pos: Vector3i) -> void:
	if is_host():
		secret_knock_requested.emit(multiplayer.get_unique_id(), pos)
	else:
		_rpc_secret_knock.rpc_id(1, pos)


func request_wanderer_answer(visitor_name: String, choice: int) -> void:
	if is_host():
		secret_answer_requested.emit(multiplayer.get_unique_id(), visitor_name, choice)
	else:
		_rpc_secret_answer.rpc_id(1, visitor_name, choice)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_secret_chest(chest_name: String) -> void:
	if is_host():
		secret_chest_requested.emit(multiplayer.get_remote_sender_id(), chest_name)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_secret_knock(pos: Vector3i) -> void:
	if is_host():
		secret_knock_requested.emit(multiplayer.get_remote_sender_id(), pos)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_secret_answer(visitor_name: String, choice: int) -> void:
	if is_host():
		secret_answer_requested.emit(multiplayer.get_remote_sender_id(), visitor_name, choice)


# --- M3 Task 9: emotes, celebrations and avatar items -------------------------------------------
# Emotes: a player's own game plays one at once and asks the host, which checks it (a known emote,
# not faster than EMOTE_COOLDOWN_MS) and sends it to every other game. Looks travel with the player
# (Player.look_code, synced), so nothing here. Celebrations: the host tells every game to celebrate.
# Avatar items bought in a Survivor world are paid with the host's gold rule (gold_spend); outside a
# world (or in a Sandbox world) the editor changes the profile itself (AvatarUnlocks.buy).

## Every game: a player did an emote (bots and buddies can copy it: "the buddy that learns your dance").
signal emote_played(peer_id: int, emote_name: StringName)
## Every game: everyone celebrated a won wave or boss.
signal celebrated
## Local: the host's answer to request_cosmetic_buy (AvatarUnlocks.OK / NOT_ENOUGH / NOT_FOR_SALE...).
signal cosmetic_result(item: String, status: StringName)

const EMOTE_COOLDOWN_MS := 400

var _last_emote := {}   # host: peer id -> msec of its last accepted emote


func request_emote(emote_name: StringName) -> void:
	if is_host():
		_host_emote(multiplayer.get_unique_id(), emote_name)
	else:
		_rpc_request_emote.rpc_id(1, String(emote_name))


## Host: whether a player's emote is played for everyone (known, and not spammed).
func accept_emote(peer_id: int, emote_name: StringName, now_ms: int) -> bool:
	if not EmotePoses.has(emote_name):
		return false
	if _last_emote.has(peer_id) and now_ms - int(_last_emote[peer_id]) < EMOTE_COOLDOWN_MS:
		return false
	_last_emote[peer_id] = now_ms
	return true


func _host_emote(peer_id: int, emote_name: StringName) -> void:
	if not accept_emote(peer_id, emote_name, Time.get_ticks_msec()):
		return
	if peer_id != multiplayer.get_unique_id():
		_show_emote(peer_id, emote_name)   # the host's own body already plays it
	emote_played.emit(peer_id, emote_name)
	for id in multiplayer.get_peers():
		if id != peer_id:
			_rpc_emote.rpc_id(id, peer_id, String(emote_name))


func _show_emote(peer_id: int, emote_name: StringName) -> void:
	var p := _player_for_peer(peer_id)
	if p:
		p.show_emote(emote_name)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_emote(emote_name: String) -> void:
	if is_host():
		_host_emote(multiplayer.get_remote_sender_id(), StringName(emote_name))


@rpc("authority", "call_remote", "reliable")
func _rpc_emote(peer_id: int, emote_name: String) -> void:
	var e := StringName(emote_name)
	if EmotePoses.has(e):
		_show_emote(peer_id, e)
		emote_played.emit(peer_id, e)


## Host: a wave or boss was won (M2 Tasks 9-10 call this): every game shows every player's victory
## dance and confetti (Player.celebrate).
func celebrate_all() -> void:
	if not is_host():
		return
	_celebrate_here()
	_rpc_celebrate.rpc()


@rpc("authority", "call_remote", "reliable")
func _rpc_celebrate() -> void:
	_celebrate_here()


func _celebrate_here() -> void:
	for p: Player in get_tree().get_nodes_in_group(&"players"):
		p.celebrate()
	celebrated.emit()


## Buys an avatar item with Survivor gold in a Survivor world: the host decides (gold_spend), and the
## answer comes back as cosmetic_result; an OK also gives the item to this game's profile.
func request_cosmetic_buy(item: String) -> void:
	if is_host():
		_host_cosmetic_buy(multiplayer.get_unique_id(), item)
	else:
		_rpc_buy_cosmetic.rpc_id(1, item)


## Host: takes the item's fixed price from the player's Survivor gold (never Sandbox gold, never an
## earned item) and answers them.
func _host_cosmetic_buy(peer_id: int, item: String) -> StringName:
	var status := AvatarUnlocks.OK
	var price := AvatarCatalog.price(item)
	var local := peer_id == multiplayer.get_unique_id()
	if not AvatarCatalog.is_item(item):
		status = AvatarUnlocks.UNKNOWN
	elif local and AvatarUnlocks.is_owned(item, Profile.data.cosmetics):
		status = AvatarUnlocks.OWNED
	elif price <= 0 or Game.allows(ModeRules.INFINITE_GOLD):
		status = AvatarUnlocks.NOT_FOR_SALE   # earned items, and Sandbox gold never buys account-wide items
	elif not gold_spend(peer_id, price):
		status = AvatarUnlocks.NOT_ENOUGH
	if local:
		_receive_cosmetic(item, status)
	else:
		_rpc_cosmetic_result.rpc_id(peer_id, item, String(status))
	return status


@rpc("any_peer", "call_remote", "reliable")
func _rpc_buy_cosmetic(item: String) -> void:
	if is_host():
		_host_cosmetic_buy(multiplayer.get_remote_sender_id(), item)


@rpc("authority", "call_remote", "reliable")
func _rpc_cosmetic_result(item: String, status: String) -> void:
	_receive_cosmetic(item, StringName(status))


## The item joins this game's profile in memory, like gold (the editor's DONE and the world's save
## write the profile).
func _receive_cosmetic(item: String, status: StringName) -> void:
	if status == AvatarUnlocks.OK:
		AvatarUnlocks.grant(Profile.data, item)
	cosmetic_result.emit(item, status)


# --- M4 early: Nakama online peer (spike) -------------------------------------------------------
# Online play is the same game over a Nakama relayed match (spec §2, §7.3). NakamaLink
# (net/nakama_link.gd) signs in with this install's DeviceId and wraps the match in a RelayBridge
# (a NakamaMultiplayerBridge), which is a MultiplayerPeer, so the hello -> world_info -> client_ready
# handshake, every RPC in this file, the spawners and the voxel sync run over the relay unchanged:
# the host is peer 1 and still validates every action, Nakama only relays. Developer args only, no
# menu yet (scenes/main.gd): --online-host prints the match id, --online-join=<match id>,
# --online-server=<address> (OnlineConfig). Results and risks: docs/devlog/parts/m4-online-spike.md.

## Host: the relayed match exists; guests join it with this id.
signal online_match_ready(match_id: String)
## Signing in, the match or the connection failed (also printed as "ONLINE error <reason>").
signal online_failed(reason: String)

const NAKAMA_LINK_SCRIPT := "res://net/nakama_link.gd"

## OnlineConfig.from_args, set before the world scene loads; {} for solo and LAN.
var online_config := {}
## Where this install's DeviceId is kept (tests use their own folder).
var online_device_id_path := DeviceId.PATH
## The NakamaLink while online. Untyped and loaded by path on purpose: naming its class here would
## load the Nakama client with Session, in every solo and LAN game.
var _link = null


func wants_online() -> bool:
	return online_config.has("role")


func is_online() -> bool:
	return _link != null


## The NakamaLink while online (its relay traffic `stats`), else null.
func online_link() -> Node:
	return _link


## Owner #105 (the second review's HIGH): a world's own sign-in makes a new account only when this device has none yet
## (no device id file). Once it had one, it signs in with create=false: a device unlinked by a LOG IN elsewhere (or a
## DELETE) hears "no account" instead of quietly getting a fresh empty one and re-claiming the freed name.
func _online_new_ok() -> bool:
	return not (FileAccess.file_exists(online_device_id_path) or FileAccess.file_exists(online_device_id_path + ".bak"))


## Host: keeps playing solo while it signs in and creates the match, then switches to the relay,
## as host_lan switches to ENet. A failure leaves it solo.
func host_online() -> void:
	var link = _online_start()
	var new_ok := _online_new_ok()   # before load_or_create makes the file
	var err: String = await link.sign_in(online_config.server, DeviceId.load_or_create(online_device_id_path), new_ok)
	if err == "" and link == _link:
		err = await link.create_match()
	if link != _link:
		return   # closed meanwhile
	if err != "":
		_online_fail(err)
		return
	multiplayer.multiplayer_peer = link.peer()
	print("ONLINE host match_id=%s" % link.match_id())
	online_match_ready.emit(link.match_id())


## Guest: a waiting peer while it signs in (never mistaken for the host), then the relay's peer.
## The handshake starts when the host gives this game its peer id (connected_to_server). A failure
## ends in `disconnected`, like a LAN join that fails.
func join_online(match_id: String) -> void:
	var link = _online_start()
	multiplayer.multiplayer_peer = link.waiting_peer()
	var new_ok := _online_new_ok()   # before load_or_create makes the file
	var err: String = await link.sign_in(online_config.server, DeviceId.load_or_create(online_device_id_path), new_ok)
	if err == "" and link == _link:
		multiplayer.multiplayer_peer = link.peer()
		err = await link.join_match(match_id)
	if link != _link:
		return
	if err != "":
		_online_fail(err)
		disconnected.emit()
		return
	print("ONLINE joined match_id=%s as peer %d" % [match_id, multiplayer.get_unique_id()])


## Leaves online play and forgets its settings (Session.close, back to the menu).
func online_reset() -> void:
	_online_close()
	online_config = {}


func _online_start():   # -> NakamaLink (untyped, see _link)
	_online_close()
	_link = (load(NAKAMA_LINK_SCRIPT) as GDScript).new()
	_link.name = "NakamaLink"
	add_child(_link)
	_link.closed.connect(_on_online_closed)
	_link.version_verdict.connect(_on_version_verdict)   # owner #123: the online version check
	_link.own_version = _test_net_version()
	if not multiplayer.peer_disconnected.is_connected(_on_online_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_online_peer_disconnected)
	return _link


## Back to solo. The relay's peer is swapped out before the link closes (Godot 4.7 can't close() a
## NakamaMultiplayerPeer, it has no _close), and a host lets go of the guests it had.
func _online_close() -> void:
	if _link == null:
		return
	_f_flush_wallet_reports()   # a host closing its world: what it still holds for its players goes now
	var link = _link
	_link = null
	link.closed.disconnect(_on_online_closed)
	var guests: Array[int] = []
	if multiplayer.multiplayer_peer is MultiplayerPeerExtension:   # the relay's or the waiting peer
		if multiplayer.is_server():
			guests.assign(multiplayer.get_peers())
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	for id in guests:
		peer_left.emit(id)
	link.leave()


## Owner #123 (NetVersionCheck.action): a guest in a world of another version goes back to the menu with words saying
## which game is behind; the host hears a friend couldn't join; an older game that never answered: a gentle warning.
func _on_version_verdict(verdict: StringName, session_id: String) -> void:
	print("ONLINE version %s %s" % [verdict, session_id])
	var act := NetVersionCheck.action(verdict, multiplayer.is_server())
	if act.is_empty():
		return
	if act.leave:
		_online_fail(str(act.reason))
		disconnected.emit()
	else:
		_a_notice(act.notice)


## A developer's test of the check: `--net-version=<hex>` plays as a build with that fingerprint (debug builds only).
func _test_net_version() -> Dictionary:
	if OS.is_debug_build():
		for a: String in OS.get_cmdline_user_args():
			if a.begins_with("--net-version="):
				var own := NetVersionCheck.own_info()
				own.net = a.trim_prefix("--net-version=")
				own.date = "2000-01-01T00:00:00+00:00" if own.net.begins_with("0") else "2099-01-01T00:00:00+00:00"
				return own
	return {}


func _online_fail(reason: String) -> void:
	print("ONLINE error %s" % reason)
	online_failed.emit(reason)
	_online_close()


## The server went away or the network dropped: a guest tries to get back in (M4 A: _a_link_lost),
## a host plays on solo.
func _on_online_closed() -> void:
	var guest := not multiplayer.is_server()
	if guest and _a_can_rejoin():
		_a_link_lost()
		return
	_online_fail("the connection to the server closed")
	if guest:
		disconnected.emit()


## The bridge tells a guest that the host left as "peer 1 disconnected", never as
## server_disconnected (the socket stays open), so the guest's game ends here.
func _on_online_peer_disconnected(id: int) -> void:
	if id == 1 and _link != null and not multiplayer.is_server():
		print("ONLINE the host left")
		_a_notice(NetWords.HOST_LEFT)
		_online_close()
		disconnected.emit()

# --- M2 Task 9: waves -------------------------------------------------------------------------------
# A tap on the Monster Totem's START (TRY AGAIN, EASIER) or its boss button asks the host. The host's
# WaveDirector (node "Waves" in the sandbox) checks it (the Totem's wave, reach, one wave at a time),
# runs the wave and sends every game the wave state itself.

## Host only: a player asked the Totem for wave `wave`, or for the boss.
signal wave_start_requested(peer_id: int, wave: int)
signal wave_boss_requested(peer_id: int)


func wave_request_start(wave: int) -> void:
	if is_host():
		wave_start_requested.emit(multiplayer.get_unique_id(), wave)
	else:
		_rpc_wave_start.rpc_id(1, wave)


func wave_request_boss() -> void:
	if is_host():
		wave_boss_requested.emit(multiplayer.get_unique_id())
	else:
		_rpc_wave_boss.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_wave_start(wave: int) -> void:
	if is_host():
		wave_start_requested.emit(multiplayer.get_remote_sender_id(), clampi(wave, 0, WaveRules.MAX_WAVE))


@rpc("any_peer", "call_remote", "reliable")
func _rpc_wave_boss() -> void:
	if is_host():
		wave_boss_requested.emit(multiplayer.get_remote_sender_id())

# --- M2 Task 5: stealth ---------------------------------------------------------------------------
# Hiding in a barrel or closet is an action like every other: the player's game asks the host
# (stealth_request_hide / stealth_request_unhide), the host's StealthDirector checks it (reach, the
# block, nobody else inside, not knocked out or asleep) and tells every game (stealth_broadcast_hidden),
# which puts that body inside, or out again (Player.set_hidden). Crouching is synced with the body
# (Player.crouching); what monsters see and hear is decided on the host (Monster, StealthDirector).

## Host only: a player asks to hide in the barrel or closet at `cell`.
signal stealth_hide_requested(peer_id: int, cell: Vector3i)
## Host only: a hidden player asks to come out.
signal stealth_unhide_requested(peer_id: int)
## Everyone: a player went into a hiding spot at `cell` (hidden), or came out of it.
signal stealth_hidden_changed(peer_id: int, hidden: bool, cell: Vector3i)


func stealth_request_hide(cell: Vector3i) -> void:
	if is_host():
		stealth_hide_requested.emit(multiplayer.get_unique_id(), cell)
	else:
		_rpc_stealth_hide.rpc_id(1, cell)


func stealth_request_unhide() -> void:
	if is_host():
		stealth_unhide_requested.emit(multiplayer.get_unique_id())
	else:
		_rpc_stealth_unhide.rpc_id(1)


## Host -> every game (this one too): a player is in a hiding spot now, or out of it.
func stealth_broadcast_hidden(peer_id: int, hidden: bool, cell: Vector3i) -> void:
	if not is_host():
		return
	stealth_hidden_changed.emit(peer_id, hidden, cell)
	if not multiplayer.get_peers().is_empty():
		_rpc_stealth_hidden.rpc(peer_id, hidden, cell)


## Host -> a guest who just joined: who is hiding where.
func stealth_send_hidden(to_peer: int, peer_id: int, cell: Vector3i) -> void:
	if is_host() and multiplayer.get_peers().has(to_peer):
		_rpc_stealth_hidden.rpc_id(to_peer, peer_id, true, cell)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_stealth_hide(cell: Vector3i) -> void:
	if is_host():
		stealth_hide_requested.emit(multiplayer.get_remote_sender_id(), cell)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_stealth_unhide() -> void:
	if is_host():
		stealth_unhide_requested.emit(multiplayer.get_remote_sender_id())


@rpc("authority", "call_remote", "reliable")
func _rpc_stealth_hidden(peer_id: int, hidden: bool, cell: Vector3i) -> void:
	stealth_hidden_changed.emit(peer_id, hidden, cell)

# --- M2 Task 10: the boss -----------------------------------------------------------------------
# The host runs the Stone Golem (BossDirector, world/boss_director.gd) and pays its gold through
# gold_add. Beating it in Survivor opens the next universe in every player's own profile: the host
# decides, each game raises its own profile (never lowers it), like gold.

## This game's profile opened a new universe (the Golem's portal).
signal boss_universe_unlocked(universe: int)


## Host: every player's game raises its profile's universe_unlocked to at least `universe`.
func boss_unlock(universe: int) -> void:
	if not is_host():
		return
	_rpc_boss_unlock.rpc(universe)
	boss_apply_unlock(universe)


## Raises this profile's highest universe (true when it went up). The host's profile is saved with
## its world (sandbox save_world); a guest's world never saves, so a guest saves at once.
func boss_apply_unlock(universe: int) -> bool:
	var earned := _boss_earn_avatar_item()
	var before := Profile.data.universe_unlocked
	Profile.data.universe_unlocked = maxi(before, clampi(universe, 1, 99))
	if Profile.data.universe_unlocked == before:
		return earned
	boss_universe_unlocked.emit(Profile.data.universe_unlocked)
	return true


func _boss_earn_avatar_item() -> bool:
	return boss_apply_earn(AvatarCatalog.EARN_GOLEM)   # the Rock Helmet (M3 Task 9) and King Arthur (Owner 36), said


@rpc("authority", "call_remote", "reliable")
func _rpc_boss_unlock(universe: int) -> void:
	if boss_apply_unlock(universe):
		Profile.save()

# --- M2 Task 8: defenses (doors) -------------------------------------------------------------------
# A tap on a door asks the host to open or close it (BlockInteractor). The host decides from its own
# world: the whole stack of doors (DefenseRules.toggle_changes), within the requester's reach, and it
# never closes a door on a player, a bot friend or a monster standing in the doorway (opening one
# traps nobody). Then it changes the cells like any edit: Survivor's ledger (a toggle gives the door
# back and uses it again, so it costs nothing) and one undo step for the requester. Every game hears it.

const DOOR_MONSTER_MESSAGE := "A monster is in the doorway!"
const _DOORWAY_SLACK := 0.05      # a monster only touching the doorway is not in it

## Everyone: a doorway opened or closed (`at` is its middle).
signal door_toggled(at: Vector3, open: bool)


## Asks the host to open or close the doorway with the door at pos. False when this game is the host
## and refused; a LAN guest returns true once the request is sent (the host's answer is the world).
func request_door(pos: Vector3i) -> bool:
	if world == null:
		return false
	if is_host():
		return host_door(multiplayer.get_unique_id(), pos)
	_rpc_door.rpc_id(1, pos)
	return true


## Host: opens or closes the doorway at pos for peer_id, all of it or nothing (with a message why).
func host_door(peer_id: int, pos: Vector3i) -> bool:
	var requester := _player_for_peer(peer_id)
	if requester == null or world == null:
		return false
	var changes := DefenseRules.toggle_changes(pos, world.get_block)
	if changes.is_empty():
		return false
	var opening: bool = changes[0][1] == BlockIds.DOOR_OPEN
	var eye := requester.eye_position()
	var bodies: Array[AABB] = []      # an opening door traps nobody (a player leaning on it may open it)
	if not opening:
		bodies = _doorway_bodies()
	for c: Array in changes:
		var reason := PlacementRules.refusal(c[0], c[1], world.get_block(c[0]), eye, bodies)
		if reason == "" and not opening and _monster_in(c[0]):
			reason = DOOR_MONSTER_MESSAGE
		if reason != "":
			edit_rejected.emit(pos, c[1])
			send_feedback(peer_id, reason)
			return false
	var ledger := gather_ledger(peer_id, false)
	var step: Array = []
	for c: Array in changes:
		var old := world.get_block(c[0])
		if ledger and not ledger.pays(old, c[1]):
			continue
		world.set_block(c[0], c[1])
		if ledger:
			ledger.changed(old, world.get_block(c[0]))
		var entry := _undo_entry(c[0], c[1], old, false)
		if not entry.is_empty():
			step.append(entry)
	_send_undo_step(peer_id, step)
	var bottom: Vector3i = changes[0][0]
	_rpc_door_toggled.rpc(Vector3(bottom) + Vector3(0.5, changes.size() * 0.5, 0.5), opening)
	return true


## Players and bot friends that are up: a closing door must not shut on them.
func _doorway_bodies() -> Array[AABB]:
	var bodies := _player_bodies()
	for n in get_tree().get_nodes_in_group(&"bots"):
		var b := n as Node3D
		if b and not b.is_queued_for_deletion():
			bodies.append(PlacementRules.player_aabb(b.global_position))
	return bodies


## Is a monster standing in the cell? (Its size() box, else a player's.)
func _monster_in(cell: Vector3i) -> bool:
	var box := AABB(Vector3(cell), Vector3.ONE)
	for n in get_tree().get_nodes_in_group(&"monsters"):
		var m := n as Node3D
		if m == null or m.is_queued_for_deletion():
			continue
		var s: Vector3 = m.call(&"size") if m.has_method(&"size") else Vector3(0.6, PlacementRules.PLAYER_HEIGHT, 0.6)
		var body := AABB(m.global_position - Vector3(s.x * 0.5, 0.0, s.z * 0.5), s).grow(-_DOORWAY_SLACK)
		if body.intersects(box):
			return true
	return false


@rpc("any_peer", "call_remote", "reliable")
func _rpc_door(pos: Vector3i) -> void:
	if is_host():
		host_door(multiplayer.get_remote_sender_id(), pos)


@rpc("authority", "call_local", "unreliable")
func _rpc_door_toggled(at: Vector3, open: bool) -> void:
	door_toggled.emit(at, open)
	Audio.play(&"door_open" if open else &"door_close", at)

# --- M4 C: online play -------------------------------------------------------------------------
# PLAY ONLINE (spec §17.1-17.3, ui/online/): this device's OnlineService (the account, friends,
# invites and consent; net/online_service.gd) lives here so it outlasts scene changes, with the
# invite toast over every scene. The match itself is the spike's host_online / join_online above:
# prepare_online_host / prepare_online_join set online_config, then the world scene hosts or joins
# as for LAN (OnlineFlow). The service keeps its own connection; solo and LAN games never make one.

const NAKAMA_BACKEND_SCRIPT := "res://net/nakama_online_backend.gd"

var _online_service: OnlineService
var _reconnect: ReconnectWatch   # owner #95: signs in again once the internet is back
var _invite_toast: InviteToast


## This device's OnlineService, made on first use with the Nakama backend (not signed in yet).
func online_service() -> OnlineService:
	if _online_service == null:
		var s := OnlineService.new()
		s.backend = (load(NAKAMA_BACKEND_SCRIPT) as GDScript).new()   # by path: see NAKAMA_LINK_SCRIPT
		s.server = online_server()
		use_online_service(s)
	return _online_service


## The service if one was made (null in solo and LAN-only play).
func online_service_or_null() -> OnlineService:
	return _online_service


## Tests: this service (with a fake backend) instead of the Nakama one; null forgets it.
func use_online_service(s: OnlineService) -> void:
	if _online_service and _online_service != s and is_instance_valid(_online_service):
		_online_service.queue_free()
	_online_service = s
	invite_toast().service = s
	if s == null:
		return
	s.name = "OnlineService"
	s.process_mode = Node.PROCESS_MODE_ALWAYS   # friends and invites work in the pause menu
	if not s.removed_from_world.is_connected(_on_removed_from_world):
		s.removed_from_world.connect(_on_removed_from_world)   # spec §17.3
	if s.get_parent() == null:
		add_child(s)


## The invite toast over every scene (made once, kept for the whole run: the HUD's look area keeps
## a reference to it).
func invite_toast() -> InviteToast:
	if _invite_toast == null:
		var layer := CanvasLayer.new()
		layer.name = "OnlineToastLayer"
		layer.layer = 90   # over every menu and HUD
		UiLayers.route(layer, self)   # owner #101: in VR on the panel
		_invite_toast = InviteToast.new()
		_invite_toast.join_pressed.connect(func(invite: Dictionary) -> void: OnlineFlow.join(invite.match_id))
		layer.add_child(_invite_toast)
	return _invite_toast


## The toast's controls, for the HUD's look area (a tap on JOIN must not build).
func online_toast_blockers() -> Array[Control]:
	return invite_toast().blockers()


## Signs in by itself once this device has been through PLAY ONLINE, so friends' invites arrive in
## the menu and in solo games. Never headless (tests, tools).
## Owner #67: the menu opens after a world too, so what changed there goes up now (not 5-30 s later, when the
## child may have closed the game); a device that was offline signs in again here and syncs (the profile is the
## queue: ProfileSync merges and uploads at every sign-in).
func online_autostart() -> void:
	if _online_service and _online_service.profile_sync:
		_online_service.profile_sync.flush()
	if DisplayServer.get_name() == "headless":
		return
	# Owner #79: a child who used or typed a friend's code signs in too (the code, the first unit learned, friends' news).
	if OnlinePrefs.load_from().safe_card_seen <= 0 and Profile.data.invite.is_empty():
		return
	online_service().sign_in()
	_start_reconnect_watch()


## Owner #95: once the internet is back the game signs in again by itself (before, only the main menu tried, once), so
## what was played offline goes up (sign_in sends the backup, gold, codes, invite and learning events), and says so
## (back_online). Made with the first autostart; wanted as long as the service still counts this device as online
## before (its prefs, in memory: forget_online clears them); a friend's world rejoining by itself is left alone.
func _start_reconnect_watch() -> void:
	if _reconnect != null or _online_service == null:
		return
	_reconnect = ReconnectWatch.new()
	_reconnect.name = "ReconnectWatch"
	_reconnect.service = _online_service
	_reconnect.wanted = func() -> bool:
		return _online_service != null and (_online_service.prefs.safe_card_seen > 0 or not Profile.data.invite.is_empty())
	_reconnect.busy = a_rejoining
	_reconnect.online_hint = WebGlue.browser_online
	_reconnect.back_online.connect(func() -> void: back_online.emit())
	add_child(_reconnect)


## The server for online play: --online-server=<address> (developer), else OnlineConfig.default_server()
## (Agent D: this PC's server in developer builds, 10.0.2.2 from the emulator; the release server,
## or {error} until it exists, in release builds). Called through the script so this also runs on
## a base without it (then this PC's server).
func online_server() -> Dictionary:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--online-server="):
			var s := OnlineConfig.parse_server(a.trim_prefix("--online-server="))
			if not s.has("error"):
				return s
	return OnlineConfig.default_server()   # this PC's server in developer builds; RELEASE_SERVER in release (M4 D)


## The next world scene hosts its world as a relayed match (PLAY ONLINE -> HOST MY WORLD).
func prepare_online_host() -> void:
	online_config = {"role": OnlineConfig.HOST, "match_id": "", "server": online_server()}


## The next world scene joins this match (an invite's JOIN). False when it is not a match id.
func prepare_online_join(match_id: String) -> bool:
	var id := OnlineConfig.normalize_match_id(match_id)
	if id == "":
		return false
	online_config = {"role": OnlineConfig.JOIN, "match_id": id, "server": online_server()}
	return true


## The relayed match this game hosts (friends are invited into it), or "".
func online_hosted_match() -> String:
	if _link == null or not multiplayer.is_server() or not (multiplayer.multiplayer_peer is MultiplayerPeerExtension):
		return ""
	return _link.match_id()


## Players in this game (the host and its guests).
func online_players() -> int:
	return multiplayer.get_peers().size() + 1


## The HUD's online dot: in an online match, or signed in for friends.
func online_dot_on() -> bool:
	return is_online() or (_online_service != null and _online_service.status == OnlineService.ONLINE)

# --- M4 A: world sync -------------------------------------------------------------------------------
# Guests generate the terrain from the seed; the host sends them only its edits (WorldSync, a node of
# every WorldService: a chunk's edit list when the chunk comes into a guest's view, then each change,
# paced per guest). LAN and online alike. Notes: docs/devlog/parts/m4-a.md.

## Host -> one guest: a packet of world edits (EditCodec).
func a_send_world_edits(peer_id: int, packet: PackedByteArray) -> void:
	_rpc_world_edits.rpc_id(peer_id, packet)


## Guest -> host: how far this game sees (the host streams that far around its player).
func a_send_view_distance(distance: int) -> void:
	_rpc_view_distance.rpc_id(1, distance)


## Bytes still queued on the way to the relay (0 on LAN and solo): world data waits while it is big.
func a_link_backlog() -> int:
	return int(_link.backlog()) if _link != null else 0


@rpc("authority", "call_remote", "reliable")
func _rpc_world_edits(packet: PackedByteArray) -> void:
	if is_instance_valid(world) and world.sync != null:
		world.sync.receive(packet)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_view_distance(distance: int) -> void:
	if is_host() and is_instance_valid(world) and world.sync != null:
		world.sync.set_view_of(multiplayer.get_remote_sender_id(), distance)


# World sync's robustness over the relay (spec §17.0): a guest whose link drops rejoins the same match
# within RejoinRules.WINDOW ("The internet went away. Trying again…"; RelayBridge gives it back its
# peer id) while the host keeps its player; after the window it goes back to the menu with kind words.
# Every network problem reaches the player as a NetWords code in net_notice (NetOverlay shows it).

## Local: a network problem or news for this player: a NetWords code and its words.
signal net_notice(code: StringName, words: String)
## Host: an online guest's link dropped; its player stays for RejoinRules.WINDOW seconds (then
## peer_left), or it comes back (peer_back) with the same peer id.
signal peer_away(peer_id: int)
signal peer_back(peer_id: int)

const ALIVE_SECONDS := 2.0
## At most this long for the old scene's voxel work to drain before a rejoin reloads the scene.
const RELOAD_DRAIN_SECONDS := 1.5

## Guest: where its kept player stands, sent by the host when it rejoins (INF: a new player).
var rejoin_spot := Vector3.INF
var _away := RejoinRules.Away.new()
var _rejoin := RejoinRules.new()
var _rejoined := false
var _last_notice: StringName = &""
var _heard_count := -1
var _alive_at := 0.0
var _a_reloading := false
var _smoother := RemoteSmoother.new()
## Tests: what reloads the guest scene (default Game.join_lan_game) and what a rejoin try does.
var a_reload_scene: Callable
var a_rejoin_try: Callable


func _a_ready() -> void:
	multiplayer.peer_connected.connect(_a_peer_connected)
	get_tree().node_added.connect(_a_pace_sync)
	online_failed.connect(_a_on_failed)
	var clock := Timer.new()
	clock.name = "RejoinClock"
	clock.wait_time = 0.25
	clock.process_mode = Node.PROCESS_MODE_ALWAYS
	clock.timeout.connect(func() -> void: _a_tick(Time.get_ticks_msec() / 1000.0))
	add_child(clock)
	clock.start()
	_smoother.name = "RemoteSmoother"   # M4 A2: remote bodies move smoothly between syncs
	_smoother.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_smoother)


## Every MultiplayerSynchronizer syncs at SyncPace's rate, not every frame (players faster); in a
## networked game everything but players syncs only what changed. (Both games must agree on a
## synchronizer's modes: a guest is networked before anything is spawned in it, and a host converts
## what it already has when its first guest arrives, before the first sync to it.)
func _a_pace_sync(node: Node) -> void:
	if node is MultiplayerSynchronizer:
		_a_pace(node as MultiplayerSynchronizer, _a_networked())
		_smoother.track(node as MultiplayerSynchronizer)


## Follows every synchronized body; shows remote ones smoothly between syncs (M4 Wave 2 A2).
func a_smoother() -> RemoteSmoother:
	return _smoother


func _a_pace(sync: MultiplayerSynchronizer, networked: bool) -> void:
	var interval := SyncPace.interval_for(sync.get_parent())
	sync.replication_interval = interval
	sync.delta_interval = interval
	if networked and SyncPace.only_on_change(sync.get_parent()):
		SyncPace.to_on_change(sync.replication_config)


func _a_networked() -> bool:
	var peer := multiplayer.multiplayer_peer
	return peer != null and not (peer is OfflineMultiplayerPeer)


func _a_pace_all() -> void:
	for sync in get_tree().root.find_children("*", "MultiplayerSynchronizer", true, false):
		_a_pace(sync as MultiplayerSynchronizer, true)


## Guest: trying to get back into the match (its scene waits for Session instead of joining itself).
func a_rejoining() -> bool:
	return _rejoin.state == RejoinRules.REJOINING


func a_rejoin_seconds_left() -> float:
	return _rejoin.seconds_left(Time.get_ticks_msec() / 1000.0)


## The last network notice (a NetWords code), for the words on the way back to the menu.
func a_last_notice() -> StringName:
	return _last_notice


func a_clear_notice() -> void:
	_last_notice = &""


## Words for a failure: a host that lost the server plays on; a guest not in a world yet can't reach it.
func _a_on_failed(reason: String) -> void:
	var code := NetWords.code_for(reason)
	if code == NetWords.LINK_LOST:
		code = NetWords.SERVER_GONE if multiplayer.is_server() else NetWords.NO_SERVER
	_a_notice(code)


func _a_notice(code: StringName) -> void:
	_last_notice = code
	net_notice.emit(code, NetWords.text(code))


## Host: an online guest's link dropped: its player stays in the world for the window.
func _a_peer_disconnected(id: int) -> void:
	_f_flush_wallet_reports()   # the gold-double bug's leftover: its last batch now, not in 5 s
	if is_instance_valid(world) and world.sync != null:
		world.sync.guest_gone(id)
	if _removed_peers.erase(id) or _lan_refused.erase(id):   # spec §17.3: the host removed them, so their player goes now
		peer_left.emit(id)
		return
	if is_online() and multiplayer.is_server() and id != 1 and _player_for_peer(id) != null:
		_away.went(id, Time.get_ticks_msec() / 1000.0)
		print("ONLINE guest %d away: its player stays for %d s" % [id, int(RejoinRules.WINDOW)])
		peer_away.emit(id)
		return
	peer_left.emit(id)


func _a_peer_connected(id: int) -> void:
	if multiplayer.is_server() and _lan_turn_away(id):
		return   # M5 Task 6 review: the host removed this player from its LAN game
	if multiplayer.is_server():
		_a_pace_all()
	if _away.back(id):
		print("ONLINE guest %d is back" % id)
		peer_back.emit(id)


## Host: a guest that comes back to its kept player is told where it stands.
func _a_before_world_info(peer_id: int) -> void:
	var p := _player_for_peer(peer_id)
	if p != null and p.is_spawned():
		_rpc_rejoin_spot.rpc_id(peer_id, p.global_position)


@rpc("authority", "call_remote", "reliable")
func _rpc_rejoin_spot(pos: Vector3) -> void:
	rejoin_spot = pos if pos.is_finite() else Vector3.INF


## Guest: where its kept player stands (INF: a new player), once.
func a_take_rejoin_spot() -> Vector3:
	var spot := rejoin_spot
	rejoin_spot = Vector3.INF
	return spot


## Host -> guests: "still here" (a guest that hears nothing for RejoinRules.SILENCE s rejoins).
@rpc("authority", "call_remote", "reliable")
func _rpc_alive() -> void:
	pass


func _a_world_registered() -> void:
	if is_instance_valid(world) and not is_host() and _rejoined:
		_rejoined = false
		_a_notice(NetWords.BACK)


func _a_can_rejoin() -> bool:
	return online_config.get("role", &"") == OnlineConfig.JOIN and (is_instance_valid(world) or a_rejoining())


## Guest: the link dropped. A fresh guest scene waits while Session joins the same match again.
func _a_link_lost() -> void:
	if a_rejoining():
		_a_drop_link()   # a try's link that closed: the try fails, the next one starts afresh
		return
	print("ONLINE link lost: trying to get back in for %d s" % int(RejoinRules.WINDOW))
	_rejoin.lost(Time.get_ticks_msec() / 1000.0)
	_a_drop_link()
	world = null
	rejoin_spot = Vector3.INF
	_a_notice(NetWords.LINK_LOST)
	_a_reload_scene(get_tree().current_scene)


## A fresh guest scene, once the old one's world has stopped streaming (M4 Wave 2 A2): freeing a world
## with thousands of queued voxel tasks froze the game for 6-13 s on the desktop ("Trying again…"
## stood still). Its viewers go first, the queue drains (about 150 ms), then the scene reloads. No try
## to join starts meanwhile (the new scene must be there to hear world_info).
func _a_reload_scene(scene: Node) -> void:
	_a_reloading = true
	if scene != null:
		WorldService.stop_viewers(scene)
		await WorldService.drain(get_tree(), RELOAD_DRAIN_SECONDS)
	_a_reloading = false
	if not a_rejoining():
		return
	if a_reload_scene.is_valid():
		a_reload_scene.call_deferred()
	else:
		Game.join_lan_game.call_deferred("")


func a_reloading() -> bool:
	return _a_reloading


## The dead link goes without a word to the scene; a "connecting" peer keeps this game from ever
## taking itself for the host meanwhile.
func _a_drop_link() -> void:
	var link = _link
	_link = null
	multiplayer.multiplayer_peer = (load(NAKAMA_LINK_SCRIPT) as GDScript).waiting_peer()
	if link != null:
		link.closed.disconnect(_on_online_closed)
		link.leave()


## The rejoin clock's last tick (its ticks are 0.25 s apart; a longer gap is this game frozen).
var _a_last_tick := 0.0


func _a_tick(now: float) -> void:
	var last := _a_last_tick
	_a_last_tick = now
	_a_tick_at(now, last)


func _a_tick_at(now: float, last: float) -> void:
	if not _away.peers().is_empty() and not (is_online() and multiplayer.is_server()):
		for id: int in _away.peers():   # the host went offline: nobody can come back
			_away.back(id)
			peer_left.emit(id)
	for id in _away.expired(now):
		print("ONLINE guest %d did not come back" % id)
		peer_left.emit(id)
	if is_online() and multiplayer.is_server() and now >= _alive_at:
		_alive_at = now + ALIVE_SECONDS
		if not multiplayer.get_peers().is_empty():
			_rpc_alive.rpc()
	if online_config.get("role", &"") != OnlineConfig.JOIN:
		return
	if _rejoin.state == RejoinRules.PLAYING:
		_rejoin.frame(now, now - last if last > 0.0 else 0.0)   # #92: our own freeze is not the host's silence
		_a_listen(now)
		return
	if _rejoin.tick(now) == RejoinRules.GAVE_UP:
		_a_give_up()
	else:
		_a_try_if_due(now)


func _a_try_if_due(now: float) -> void:
	if _a_reloading or not _rejoin.should_try(now):
		return
	if a_rejoin_try.is_valid():
		a_rejoin_try.call()
	else:
		_a_try(now)


## Guest: anything from the relay counts as the host still being there.
func _a_listen(now: float) -> void:
	if _link == null or not is_instance_valid(world):
		_heard_count = -1
		return
	var count := int(_link.stats.received)
	if count != _heard_count or _heard_count < 0:
		_heard_count = count
		_rejoin.heard(now)
	elif _rejoin.silent_too_long(now):
		print("ONLINE nothing from the host for %d s" % int(RejoinRules.SILENCE))
		_a_link_lost()


func _a_try(now: float) -> void:
	_rejoin.trying(now)
	print("ONLINE rejoin try %d" % _rejoin.tries)
	await join_online(str(online_config.match_id))
	if not a_rejoining():
		return
	var peer := multiplayer.multiplayer_peer
	if _link != null and peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED \
			and not multiplayer.is_server():
		_rejoin.joined()
		_rejoined = true
		_heard_count = -1
		print("ONLINE rejoined as peer %d" % multiplayer.get_unique_id())
		return
	_rejoin.failed(Time.get_ticks_msec() / 1000.0)
	multiplayer.multiplayer_peer = (load(NAKAMA_LINK_SCRIPT) as GDScript).waiting_peer()
	_a_notice(NetWords.LINK_LOST)


func _a_give_up() -> void:
	print("ONLINE gave up rejoining")
	_rejoin = RejoinRules.new()
	_online_close()
	if multiplayer.multiplayer_peer is MultiplayerPeerExtension:   # the "connecting" peer of the tries
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()   # (it can't close(): M4 A2)
	_a_notice(NetWords.GAVE_UP)
	disconnected.emit()

# --- M2 Task 18: minds --------------------------------------------------------------------------
# Creature minds run on the host (core/mind/). A player feeding an animal (a tap holding grass or
# leaves: AnimalSpecies.is_treat) asks the host, which checks the reach (Animal.mind_treat) and tells
# the animal's mind who was kind to it. The thoughts over creatures' heads travel as synced properties.

## Host only: a player gave the animal called `animal_name` a treat.
signal mind_treat_requested(peer_id: int, animal_name: String)


func mind_request_treat(animal_name: String) -> void:
	if is_host():
		mind_treat_requested.emit(multiplayer.get_unique_id(), animal_name)
	else:
		_rpc_mind_treat.rpc_id(1, animal_name)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_mind_treat(animal_name: String) -> void:
	if is_host():
		mind_treat_requested.emit(multiplayer.get_remote_sender_id(), animal_name)

# --- M4 E: online chat and co-op ------------------------------------------------------------------
# The team room of an online match is named after its relayed match (the server lets only the
# match's players in: server/modules/src/server/chat.ts); the sandbox gives the HUD's chat panel
# this id (ChatPanel.use_team_chat).

## The relayed match this game plays in (as its host or a guest), or "" (solo, LAN, not joined yet).
func online_match_id() -> String:
	if _link == null or not (multiplayer.multiplayer_peer is MultiplayerPeerExtension):
		return ""
	return str(_link.match_id())


## Everyone (M4 E): a teammate helped a knocked-out player up (KnockoutDirector; §17.5). The host's
## waves count that player as standing again.
signal revive_done(peer_id: int, by_peer: int)

# --- M4 F: Survivor gold online (the server's wallet ledger) and play time -----------------------------
# Online, the server keeps each player's Survivor gold (spec §17.1, §17.6; the lead's review): the host
# starts a guest's wallet from the server, never from the guest's own word (_f_seed_guest), reports
# every change of every player to the server's ledger (_f_host_gold -> OnlineWallets), and a guest's
# game adds each change to its own phone's gold (_rpc_gold_moved) so the child's gold never goes
# backwards (§6). LAN keeps the M2 way above (the guest's word, trusted: §12.11). PlayClock counts
# the time the game is open for the grown-up area (§17.2).

## This game's own Survivor gold changed in an online world (the host reports it to the server, so
## OnlineService moves this device's wallet marker too: WalletSync).
signal own_gold_moved_online(delta: int)
## The gold-double bug's leftover (module 0.2.19): the host of the online world `match_id` told this guest's game a
## gold move with its count `seq` (the host reports that count to the server with its batch): after the world, the
## OnlineService waits for the server to have heard it before it trusts the wallet.
signal hosted_gold_seq(match_id: String, seq: int)

var _play_clock: PlayClock
var _f_wallets: OnlineWallets
var _f_test_online_host := false


func _f_ready() -> void:
	if DisplayServer.get_name() != "headless":   # tests and tools never count play time
		play_clock()


## This device's play-time counter (made on first use).
func play_clock() -> PlayClock:
	if _play_clock == null:
		_play_clock = PlayClock.new()
		_play_clock.name = "PlayClock"
		add_child(_play_clock)
	return _play_clock


## Today's minutes of play on this device (the grown-up area; read from the file when not counting).
func play_minutes_today() -> int:
	return _play_clock.minutes_today() if _play_clock else PlayTime.load_from().minutes_on(PlayTime.today())


## The host's view of online players' gold (made on first use with this device's OnlineService).
func online_wallets() -> OnlineWallets:
	if _f_wallets == null:
		_f_wallets = OnlineWallets.new()
		_f_wallets.service = online_service()
		_f_wallets.user_of = _f_user_of
		_f_wallets.match_id = online_hosted_match
	return _f_wallets


## Tests: these wallets (a fake server) and whether this game acts as an online host; null forgets.
func use_online_wallets(w: OnlineWallets, online_host: bool) -> void:
	_f_wallets = w
	_f_test_online_host = online_host


func _f_online_host() -> bool:
	return _f_test_online_host or (is_online() and is_host())


## Another player's Nakama user id in this online game ("" when unknown): what REPORT and BLOCK on their card need.
func online_user_of(peer_id: int) -> String:
	return _f_user_of(peer_id)


## A guest's Nakama user id, from the relay ("" when unknown).
func _f_user_of(peer_id: int) -> String:
	if _link == null or _link.bridge == null:
		return ""
	var presence = _link.bridge.get_user_presence_for_peer(peer_id)
	return str(presence.user_id) if presence != null else ""


## Host: a player's gold changed; online, it goes to the server's ledger.
func _f_host_gold(peer_id: int, delta: int) -> void:
	if delta != 0 and _f_online_host():
		online_wallets().moved(peer_id, delta)


## Host: online, a joining guest's wallet starts from the server, not from `claimed` (its own word).
## False on LAN (the caller trusts the guest, §12.11).
func _f_seed_guest(id: int, claimed: int) -> bool:
	if not _f_online_host():
		return false
	_wallets[id] = Wallet.new(0)   # until the server answers (changes meanwhile are kept)
	_f_seed_from_server(id, claimed)
	return true


func _f_seed_from_server(id: int, claimed: int) -> void:
	var gold: int = await online_wallets().starting_gold(id)
	if not _wallets.has(id):
		return   # left meanwhile
	var since := (_wallets[id] as Wallet).balance
	# No answer from the server (not signed in, the network): the guest's word, as on LAN.
	_wallets[id] = Wallet.new((gold if gold >= 0 else claimed) + since)


## Tests: forget a peer's wallet.
func _f_forget_wallet(id: int) -> void:
	_wallets.erase(id)


func _f_gold_moved(before: int, after: int) -> void:
	if after != before and (is_online() or _f_test_online_host):
		own_gold_moved_online.emit(after - before)


## Guest, online: the host changed this player's gold by `delta` (its view, `balance`, is the server's).
## The phone adds the change to its own gold, which never goes below 0. `seq` (module 0.2.19): the host's count of
## this player's gold moves so far (0 from an older host).
@rpc("authority", "call_remote", "reliable")
func _rpc_gold_moved(_balance: int, delta: int, seq: int = 0) -> void:
	var before := Profile.data.survivor_gold
	Profile.data.survivor_gold = Wallet.new(before + delta).balance
	gold_changed.emit(Profile.data.survivor_gold)
	if Profile.data.survivor_gold != before:
		own_gold_moved_online.emit(Profile.data.survivor_gold - before)
	if seq > 0:
		hosted_gold_seq.emit(online_match_id(), seq)


## The gold-double bug's leftover (module 0.2.19): an online host sends what it still holds for its players at once
## when one leaves, and when it closes its world (else up to 5 s later): the server takes that batch late (it carries
## its count), and the guest's game waits for it before it trusts its wallet.
func _f_flush_wallet_reports() -> void:
	if _f_online_host() and _f_wallets != null and _f_wallets.service != null:
		_f_wallets.service.send_wallet_report()

# --- M3 Task 5: the universe ladder ---------------------------------------------------------------------
# A LAN or online guest builds the host's world from its seed; it needs the host's universe too (the
# terrain, music, sky and scaling come from it). The host sends it just before world_info: both are
# reliable RPCs on the same channel, so they arrive in that order.

func _m3_send_universe(peer_id: int) -> void:
	_rpc_m3_universe.rpc_id(peer_id, Game.universe)


@rpc("authority", "call_remote", "reliable")
func _rpc_m3_universe(u: int) -> void:
	Game.universe = UniverseRules.valid(u)

# --- Survivor games and crafting (owner feedback #33, #34; spec §12.18, §12.19) ----------------------------
# Crafting: a player asks for a recipe (request_craft); the host checks it (host_craft: a Survivor world, a
# known recipe, the stations near the requester's body as the host sees it — one bulk copy of the blocks
# around it —, then CraftRules: the ingredients, the fuel, one tool of each, room), takes and gives, and
# answers that player (craft_done); the inventory follows by the usual snapshot. Survivor games: the host
# sends a guest the world's game (Game.survivor_game) with its universe, before world_info; Monster Hunter's
# gold pops up on the hunter's screen (hunt_paid); every player hears their own score (game_score_received).

## The host's answer to one of this player's crafts: what it said and what was made.
signal craft_done(ok: bool, text: String, id: int, count: int)
## Monster Hunter: this player was paid for a defeat (the gold, the combo's count).
signal hunt_paid(gold: int, combo: int)
## This player's score in this world's game (GameScores record).
signal game_score_received(score: Dictionary)

const _HAND_ONLY := {Recipes.HAND: true, Recipes.TABLE: false, Recipes.FURNACE: false, Recipes.REFINERY: false}


## Crafts one recipe of the book (the host checks it).
func request_craft(recipe_id: StringName) -> void:
	if is_host():
		host_craft(multiplayer.get_unique_id(), recipe_id)
	else:
		_rpc_craft.rpc_id(1, String(recipe_id).substr(0, 40))


## Host: checks and makes one recipe for a player and tells them. Returns CraftRules.craft's result.
func host_craft(peer_id: int, recipe_id: StringName) -> Dictionary:
	var recipe := Recipes.find(recipe_id)
	var result := {"ok": false, "error": "unknown", "id": int(recipe.get("makes", 0)), "count": 0, "fuel": BlockIds.AIR}
	var p := _player_for_peer(peer_id)
	if not is_host() or p == null:
		return result
	var inv := inventory_of(peer_id)
	if Game.allows(ModeRules.UNLIMITED_BLOCKS):
		result.error = "survivor_only"
	elif not recipe.is_empty():
		var near := _HAND_ONLY if recipe.at == Recipes.HAND else craft_stations_near(p.eye_position(), CraftRules.HOST_REACH)
		result = CraftRules.craft(recipe, inv, near)
	var text := CraftRules.done_message(recipe) if result.ok else CraftRules.message(result.error, recipe, inv)
	_send_craft_done(peer_id, result.ok, text, int(result.id), int(result.count))
	if result.ok:
		progress_tell(peer_id, StringName("%s/%s" % [LevelRules.CRAFTED, recipe.id]))   # owner #45a: what was made
	return result


## Where a player whose eyes are at `eye` can craft (CraftRules.stations), from one bulk copy of the blocks
## around them (the host with CraftRules.HOST_REACH; this game's recipe book with CraftRules.REACH).
func craft_stations_near(eye: Vector3, reach: float) -> Dictionary:
	if world == null:
		return _HAND_ONLY.duplicate()
	var box := CraftRules.search_box(eye)
	var buf := world.copy_box(box[0], box[1])
	var tables := MonsterDirector.find_blocks(buf, box[0], [BlockIds.CRAFTING_TABLE] as Array[int])
	var furnaces := MonsterDirector.find_blocks(buf, box[0], [BlockIds.FURNACE] as Array[int])
	var refineries := MonsterDirector.find_blocks(buf, box[0], [BlockIds.REFINERY] as Array[int])   # spec §26
	var machines := {}   # spec §26.5: the Ice Melter, the Oxygen Maker, the Solar Oven
	for m: StringName in Recipes.MACHINES:
		machines[m] = MonsterDirector.find_blocks(buf, box[0], [Recipes.station_block(m)] as Array[int])
	return CraftRules.stations(eye, tables, furnaces, reach, refineries, machines)


func _send_craft_done(peer_id: int, ok: bool, text: String, id: int, count: int) -> void:
	if peer_id == multiplayer.get_unique_id():
		craft_done.emit(ok, text, id, count)
	elif multiplayer.get_peers().has(peer_id):
		_rpc_craft_done.rpc_id(peer_id, ok, text, id, count)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_craft(recipe_id: String) -> void:
	if is_host():
		host_craft(multiplayer.get_remote_sender_id(), StringName(recipe_id.substr(0, 40)))


@rpc("authority", "call_remote", "reliable")
func _rpc_craft_done(ok: bool, text: String, id: int, count: int) -> void:
	craft_done.emit(ok, text.substr(0, 200), id, count)


## Host -> a guest: this world's game, before world_info (the same channel keeps the order).
func _sgc_send_game(peer_id: int) -> void:
	_rpc_sgc_game.rpc_id(peer_id, String(Game.survivor_game))


@rpc("authority", "call_remote", "reliable")
func _rpc_sgc_game(game: String) -> void:
	Game.survivor_game = SurvivorGames.valid(StringName(game))


## Host -> a player: paid for a defeat in Monster Hunter.
func send_hunt_paid(peer_id: int, gold: int, combo: int) -> void:
	if peer_id == multiplayer.get_unique_id():
		hunt_paid.emit(gold, combo)
	elif multiplayer.get_peers().has(peer_id):
		_rpc_hunt_paid.rpc_id(peer_id, gold, combo)


@rpc("authority", "call_remote", "reliable")
func _rpc_hunt_paid(gold: int, combo: int) -> void:
	hunt_paid.emit(maxi(gold, 0), clampi(combo, 0, 999))


## Host -> a player: their score in this world's game.
func send_game_score(peer_id: int, score: Dictionary) -> void:
	if peer_id == multiplayer.get_unique_id():
		game_score_received.emit(score.duplicate())
	elif multiplayer.get_peers().has(peer_id):
		_rpc_game_score.rpc_id(peer_id, score)


@rpc("authority", "call_remote", "reliable")
func _rpc_game_score(score: Dictionary) -> void:
	game_score_received.emit(GameScores.clean(score))


# --- M3 Task 12: progress events, board gold and pets' presents ---------------------------------------
# Each player's own game counts its own progress (the Progress autoload, the profile's ProgressData).
# Events the host decides reach the player they belong to through progress_tell (the host's own game
# counts at once; a guest's gets one reliable RPC and checks the kind): blocks a player placed, a
# monster beaten near players, a won wave or boss, a buddy woken, a pet tamed. Survivor gold for a board
# goal, and a Survivor present's gift, go through the host's gold and inventory paths: the player's game
# asks, the host checks the goal or gift is a known one with a fixed reward and that this player was
# not paid one a moment ago (trusted LAN, like gold_hello; M4's server can take it over).

## Players this close to a beaten monster count it (the team that fought it).
const PROGRESS_NEAR := 24.0

var _t12_goal_paid := {}      # host: peer id -> msec of its last paid goal
var _t12_present_given := {}  # host: peer id -> msec of its last present


## Host: `peer_id`'s game counts `amount` of `kind` (this game's own player: here and now).
func progress_tell(peer_id: int, kind: StringName, amount: int = 1) -> void:
	if not is_host() or not LevelRules.is_kind(kind) or amount <= 0:
		return
	if peer_id == multiplayer.get_unique_id():
		Progress.event(kind, amount)
	elif multiplayer.get_peers().has(peer_id):
		_rpc_progress.rpc_id(peer_id, String(kind), mini(amount, LevelRules.MAX_AMOUNT))


## Host: every spawned player within `radius` of `pos` counts `kind` (a monster beaten near them).
func progress_near(pos: Vector3, kind: StringName, radius: float = PROGRESS_NEAR) -> void:
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if is_instance_valid(p) and p.is_spawned() and p.global_position.distance_to(pos) <= radius:
			progress_tell(p.peer_id, kind)


## Host: every player in the game counts `kind` (a wave or a boss the team won).
func progress_everyone(kind: StringName) -> void:
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if is_instance_valid(p) and not p.is_queued_for_deletion():
			progress_tell(p.peer_id, kind)


## Host: the blocks a player placed with an edit (its undo step: [pos, id before, id now]); an undo
## never counts. Called from _host_apply and _host_apply_batch.
func progress_placed(peer_id: int, step: Array, is_undo: bool) -> void:
	if not is_undo:
		var n := progress_placed_count(step)
		if n > 0:
			progress_tell(peer_id, LevelRules.BLOCK, n)


## New blocks in an undo step: a cell that was air or water and holds a block now.
static func progress_placed_count(step: Array) -> int:
	var n := 0
	for e: Variant in step:
		if e is Array and (e as Array).size() == 3 and e[1] is int and e[2] is int \
				and int(e[1]) in [BlockIds.AIR, BlockIds.WATER] and int(e[2]) not in [BlockIds.AIR, BlockIds.WATER]:
			n += 1
	return n


@rpc("authority", "call_remote", "reliable")
func _rpc_progress(kind: String, amount: int) -> void:
	var k := StringName(kind)
	if LevelRules.is_kind(k) and amount > 0:
		Progress.event(k, mini(amount, LevelRules.MAX_AMOUNT))


## This game's player finished a board goal in Survivor: the host pays its fixed gold.
func progress_goal_gold(goal_id: StringName) -> void:
	if is_host():
		progress_host_goal_gold(multiplayer.get_unique_id(), goal_id)
	else:
		_rpc_goal_gold.rpc_id(1, String(goal_id))


## Host: pays `peer_id` the fixed gold of goal `goal_id` (Survivor only; never twice within
## BoardRules.CLAIM_GAP_MS). True when paid.
func progress_host_goal_gold(peer_id: int, goal_id: StringName) -> bool:
	var gold := BoardRules.gold_for(goal_id)
	var now := Time.get_ticks_msec()
	if not is_host() or gold <= 0 or Game.allows(ModeRules.INFINITE_GOLD) \
			or not BoardRules.host_allows(int(_t12_goal_paid.get(peer_id, -1)), now):
		return false
	_t12_goal_paid[peer_id] = now
	gold_add(peer_id, gold, "goal")
	return true


@rpc("any_peer", "call_remote", "reliable")
func _rpc_goal_gold(goal_id: String) -> void:
	if is_host():
		progress_host_goal_gold(multiplayer.get_remote_sender_id(), StringName(goal_id))


## This game's player opened a Survivor present with gift `gift_id`: the host gives it.
func progress_present(gift_id: StringName) -> void:
	if is_host():
		progress_host_present(multiplayer.get_unique_id(), gift_id)
	else:
		_rpc_present.rpc_id(1, String(gift_id))


## Host: gives `peer_id` Survivor gift `gift_id` (gold or blocks; never twice within
## PresentRules.CLAIM_GAP_MS). True when given.
func progress_host_present(peer_id: int, gift_id: StringName) -> bool:
	var g := PresentRules.gift(gift_id, true)
	var now := Time.get_ticks_msec()
	if not is_host() or g.is_empty() or Game.allows(ModeRules.INFINITE_GOLD) \
			or not PresentRules.host_allows(int(_t12_present_given.get(peer_id, -1)), now):
		return false
	_t12_present_given[peer_id] = now
	if int(g.gold) > 0:
		gold_add(peer_id, int(g.gold), "present")
	if int(g.item) > 0:
		inventory_of(peer_id).add(int(g.item), int(g.count))
	return true


@rpc("any_peer", "call_remote", "reliable")
func _rpc_present(gift_id: String) -> void:
	if is_host():
		progress_host_present(multiplayer.get_remote_sender_id(), StringName(gift_id))


## Forgets the host's claim times (a new session, tests).
func progress_reset() -> void:
	_t12_goal_paid.clear()
	_t12_present_given.clear()

# --- M3 Task 7: smart blocks and Game Blocks ------------------------------------------------------------
# A tap on a button, lever or light switch, and a runner's feet on a Game Block or a teleport pad (reported
# by the player's own game), are requests. The host checks them (the block is there in its world, the body it
# knows is within reach, at most 5 toggles and 20 touches a second per player) and hands them to its
# SmartDirector (power, teleport pads) and CourseDirector (courses) through the signals below. Power changes
# the host's world like an edit (guests get it like every edit) but is nobody's undo step and counts nothing
# in Survivor: power_set_blocks only flips a block between its off and on states, and never closes a powered
# doorway on someone. A runner's clock and results go back to that runner's game (course_state_received); a
# course's goals panel asks the host (course_info_*, course_goals_*).

const SMART_TOUCHES_PER_SECOND := 20
const SMART_TOUCH_REACH := 3.5     # feet (as the host knows them) to the block's middle: a step of latency
const _SMART_SLACK := 0.05         # a body only touching a doorway is not in it

## Host: a checked tap on a switch at `cell` (SmartDirector.tap).
signal smart_tap_requested(peer_id: int, cell: Vector3i)
## Host: a checked touch of a Game Block or a teleport pad (`left`: the feet just left that START).
signal smart_touch_requested(peer_id: int, id: int, cell: Vector3i, left: bool)
## Host: a player asks about the course of the START or FINISH at `cell` (its goals panel).
signal course_info_requested(peer_id: int, cell: Vector3i)
## Host: a player sets the goals of the course of the START or FINISH at `cell`.
signal course_goals_requested(peer_id: int, cell: Vector3i, goals: Array)
## Local: this player's run changed (the race clock), from the host.
signal course_state_received(state: Dictionary)
## Local: a course's goals and best time (the goals panel), from the host.
signal course_info_received(info: Dictionary)

## The host's clock for the rate caps (tests set their own).
var smart_now_ms: Callable = Time.get_ticks_msec
var _smart_taps := {}      # host: peer id -> PowerRules.TapLimiter
var _smart_touches := {}   # host: peer id -> PowerRules.TapLimiter (SMART_TOUCHES_PER_SECOND)


func smart_reset() -> void:
	_smart_taps.clear()
	_smart_touches.clear()
	smart_now_ms = Time.get_ticks_msec


## A tap on a switch. False when this game is the host and refused it; a guest returns true once sent.
func request_smart_tap(cell: Vector3i) -> bool:
	if world == null:
		return false
	if is_host():
		return host_smart_tap(multiplayer.get_unique_id(), cell)
	_rpc_smart_tap.rpc_id(1, cell)
	return true


## Host: a switch at `cell` within the player's reach, at most MAX_TOGGLES_PER_SECOND a second.
func host_smart_tap(peer_id: int, cell: Vector3i) -> bool:
	var p := _player_for_peer(peer_id)
	if p == null or world == null or not PowerRules.is_switch(world.get_block(cell)):
		return false
	if not PlacementRules.in_reach(p.eye_position(), cell, PlacementRules.REACH + PlacementRules.REACH_TOLERANCE):
		send_feedback(peer_id, PlacementRules.TOO_FAR_MESSAGE)
		return false
	if not _smart_limit(_smart_taps, peer_id, PowerRules.MAX_TOGGLES_PER_SECOND):
		return false   # a finger drumming on a lever: the extra taps do nothing
	smart_tap_requested.emit(peer_id, cell)
	return true


## This player's feet touched a Game Block or a teleport pad (`left`: they just stepped off that START).
func request_smart_touch(id: int, cell: Vector3i, left: bool = false) -> bool:
	if world == null:
		return false
	if is_host():
		return host_smart_touch(multiplayer.get_unique_id(), id, cell, left)
	_rpc_smart_touch.rpc_id(1, id, cell, left)
	return true


## Host: the block is really there and the body it knows is on or next to it.
func host_smart_touch(peer_id: int, id: int, cell: Vector3i, left: bool) -> bool:
	var p := _player_for_peer(peer_id)
	if p == null or world == null or not (CourseRules.is_floor_block(id) or id == BlockIds.COIN):
		return false
	if world.get_block(cell) != id:
		return false
	var reach := SMART_TOUCH_REACH * maxf(p.size_scale(), 1.0)
	if p.global_position.distance_to(Vector3(cell) + Vector3(0.5, 0.5, 0.5)) > reach:
		return false
	if not _smart_limit(_smart_touches, peer_id, SMART_TOUCHES_PER_SECOND):
		return false
	smart_touch_requested.emit(peer_id, id, cell, left)
	return true


## Host: power's own changes, [[cell, id], ...]. Only a block's off and on states (a lever on, a lamp lit, a
## doorway open) ever change, so nothing is made or lost; a doorway that would close on a player, a bot
## friend or a monster stays open. Returns those cells (the SmartDirector tries again later).
func power_set_blocks(changes: Array) -> Array[Vector3i]:
	var waiting: Array[Vector3i] = []
	if world == null or not is_host():
		return waiting
	var clean: Array = []
	var blocked := false
	var bodies := _doorway_bodies()
	for c: Variant in changes:
		if not c is Array or (c as Array).size() != 2 or not c[0] is Vector3i or typeof(c[1]) != TYPE_INT:
			continue
		var old := world.get_block(c[0])
		if old == c[1] or PowerRules.item_of(old) != PowerRules.item_of(c[1]):
			continue
		clean.append(c)
		if c[1] == BlockIds.POWERED_DOOR and (_smart_body_in(c[0], bodies) or _monster_in(c[0])):
			blocked = true
	for c: Array in clean:
		if blocked and c[1] == BlockIds.POWERED_DOOR:
			waiting.append(c[0])
		else:
			world.set_block(c[0], c[1])
	return waiting


func _smart_body_in(cell: Vector3i, bodies: Array[AABB]) -> bool:
	var box := AABB(Vector3(cell), Vector3.ONE).grow(-_SMART_SLACK)
	for b in bodies:
		if b.intersects(box):
			return true
	return false


func _smart_limit(limits: Dictionary, peer_id: int, per_second: int) -> bool:
	if not limits.has(peer_id):
		limits[peer_id] = PowerRules.TapLimiter.new(per_second)
	return (limits[peer_id] as PowerRules.TapLimiter).allow(int(smart_now_ms.call()))


## A tap on START or FINISH (not racing): the course's goals and best time, from the host.
func request_course_info(cell: Vector3i) -> void:
	if world == null:
		return
	if is_host():
		host_course_info(multiplayer.get_unique_id(), cell)
	else:
		_rpc_course_info_request.rpc_id(1, cell)


func host_course_info(peer_id: int, cell: Vector3i) -> bool:
	if not _course_block_in_reach(peer_id, cell):
		return false
	course_info_requested.emit(peer_id, cell)
	return true


## The goals panel's gold, silver and bronze times (ms) for the course of the START or FINISH at `cell`.
func request_course_goals(cell: Vector3i, goals: Array) -> void:
	if world == null:
		return
	if is_host():
		host_course_goals(multiplayer.get_unique_id(), cell, goals)
	else:
		_rpc_course_goals.rpc_id(1, cell, goals)


func host_course_goals(peer_id: int, cell: Vector3i, goals: Array) -> bool:
	if not _course_block_in_reach(peer_id, cell) or CourseRules.clean_goals(goals).is_empty():
		return false
	course_goals_requested.emit(peer_id, cell, CourseRules.clean_goals(goals))
	return true


func _course_block_in_reach(peer_id: int, cell: Vector3i) -> bool:
	var p := _player_for_peer(peer_id)
	if p == null or world == null or not world.get_block(cell) in [BlockIds.START, BlockIds.FINISH]:
		return false
	if not PlacementRules.in_reach(p.eye_position(), cell, PlacementRules.REACH + PlacementRules.REACH_TOLERANCE):
		send_feedback(peer_id, PlacementRules.TOO_FAR_MESSAGE)
		return false
	return true


## Host -> a runner: their run's state (CourseDirector.state_of).
func send_course_state(peer_id: int, state: Dictionary) -> void:
	if peer_id == multiplayer.get_unique_id():
		course_state_received.emit(state)
	else:
		_rpc_course_state.rpc_id(peer_id, state)


## Host -> a player: a course's goals and best time (CourseDirector.info_of).
func send_course_info(peer_id: int, info: Dictionary) -> void:
	if peer_id == multiplayer.get_unique_id():
		course_info_received.emit(info)
	else:
		_rpc_course_info.rpc_id(peer_id, info)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_smart_tap(cell: Vector3i) -> void:
	if is_host():
		host_smart_tap(multiplayer.get_remote_sender_id(), cell)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_smart_touch(id: int, cell: Vector3i, left: bool) -> void:
	if is_host():
		host_smart_touch(multiplayer.get_remote_sender_id(), id, cell, left)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_course_info_request(cell: Vector3i) -> void:
	if is_host():
		host_course_info(multiplayer.get_remote_sender_id(), cell)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_course_goals(cell: Vector3i, goals: Array) -> void:
	if is_host():
		host_course_goals(multiplayer.get_remote_sender_id(), cell, goals)


@rpc("authority", "call_remote", "reliable")
func _rpc_course_state(state: Dictionary) -> void:
	course_state_received.emit(state)


@rpc("authority", "call_remote", "reliable")
func _rpc_course_info(info: Dictionary) -> void:
	course_info_received.emit(info)

# --- M4 H: co-op games -------------------------------------------------------------------------------
# Hide-and-seek, Storm Run and the team photo after a boss (spec §17.5) run in the host's world, LAN and
# online alike. A player's game asks; the host's GamesDirector (world/games/, node "Games" in the sandbox)
# checks every request — a start (no round, wave or boss on; hide-and-seek needs two), a find (a seeker who
# sees an unfound hider within 3 blocks, never through a wall), a look into a hiding spot (a seeker in
# reach, someone inside), a star (close enough), the photo (the 20 s offer after a boss) — and tells every
# game through its own RPCs. Bot friends play through the host's director; they are never players.

## Host only: a player asks for a round of `kind` (GameRules.KINDS); `seeker`: a participant's key, or "".
signal games_start_requested(peer_id: int, kind: StringName, seeker: String)
## Host only: a player asks to end the round early (the host's GAMES page).
signal games_stop_requested(peer_id: int)
## Host only: a seeker saw the hider with key `hider` (their own game checked the view).
signal games_find_requested(peer_id: int, hider: String)
## Host only: a seeker looks into the barrel, closet or bush at `cell`.
signal games_spot_requested(peer_id: int, cell: Vector3i)
## Host only: a player touched Storm Run's star `star_id`.
signal games_star_requested(peer_id: int, star_id: int)
## Host only: a player tapped TEAM PHOTO.
signal games_photo_requested(peer_id: int)


func games_request_start(kind: StringName, seeker: String = "") -> void:
	if is_host():
		games_start_requested.emit(multiplayer.get_unique_id(), kind, seeker)
	else:
		_rpc_games_start.rpc_id(1, String(kind), seeker)


func games_request_stop() -> void:
	if is_host():
		games_stop_requested.emit(multiplayer.get_unique_id())
	else:
		_rpc_games_stop.rpc_id(1)


func games_request_find(hider: String) -> void:
	if is_host():
		games_find_requested.emit(multiplayer.get_unique_id(), hider)
	else:
		_rpc_games_find.rpc_id(1, hider)


func games_request_spot(cell: Vector3i) -> void:
	if is_host():
		games_spot_requested.emit(multiplayer.get_unique_id(), cell)
	else:
		_rpc_games_spot.rpc_id(1, cell)


func games_request_star(star_id: int) -> void:
	if is_host():
		games_star_requested.emit(multiplayer.get_unique_id(), star_id)
	else:
		_rpc_games_star.rpc_id(1, star_id)


func games_request_photo() -> void:
	if is_host():
		games_photo_requested.emit(multiplayer.get_unique_id())
	else:
		_rpc_games_photo.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_games_start(kind: String, seeker: String) -> void:
	if is_host() and kind.length() <= 32 and seeker.length() <= 40:
		games_start_requested.emit(multiplayer.get_remote_sender_id(), StringName(kind), seeker)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_games_stop() -> void:
	if is_host():
		games_stop_requested.emit(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func _rpc_games_find(hider: String) -> void:
	if is_host() and hider.length() <= 40:
		games_find_requested.emit(multiplayer.get_remote_sender_id(), hider)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_games_spot(cell: Vector3i) -> void:
	if is_host():
		games_spot_requested.emit(multiplayer.get_remote_sender_id(), cell)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_games_star(star_id: int) -> void:
	if is_host():
		games_star_requested.emit(multiplayer.get_remote_sender_id(), star_id)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_games_photo() -> void:
	if is_host():
		games_photo_requested.emit(multiplayer.get_remote_sender_id())

# --- Owner 38: bot chat -------------------------------------------------------------------------------
# The child's words to their own bot friends (spec §12.14a): the chat bar's text and the quick-chat wheel's
# phrases go to the host, which checks them like chat — the rate limit, and the filter: personal information
# and bad words never reach a bot, so bots never react to them — and gives them to the bot director
# (BotDirector.hear), where only the speaker's own friends listen. Nothing is stored or sent anywhere else.

var _bot_talk_limiter := ChatRules.RateLimiter.new()


## This game's player says `text` to their own bot friends (the host decides who hears).
func request_bot_talk(text: String) -> void:
	if is_host():
		_host_bot_talk(multiplayer.get_unique_id(), text)
	else:
		_rpc_bot_talk.rpc_id(1, text.substr(0, ChatRules.MAX_RAW_LENGTH))


## Does this game's player have bot friends of their own? (Friends follow the player who added them:
## the host's, BotFriend.leader_peer; a guest has none.)
func has_own_bots() -> bool:
	var me := multiplayer.get_unique_id()
	for n in get_tree().get_nodes_in_group(&"bot_friends"):
		if n is BotFriend and (n as BotFriend).leader_peer == me and not n.is_queued_for_deletion():
			return true
	return false


## Host: `text` from player `peer_id` to their bot friends. True when the director heard it.
func _host_bot_talk(peer_id: int, text: String) -> bool:
	if not is_host() or not _bot_talk_limiter.allow(peer_id, Time.get_ticks_msec() / 1000.0):
		return false
	var t := ChatRules.clean(text.substr(0, ChatRules.MAX_RAW_LENGTH))
	if t == "" or ChatRules.filter_code(t) != "":
		return false
	for n in get_tree().get_nodes_in_group(&"bot_director"):
		if n.has_method(&"hear"):
			n.call(&"hear", peer_id, t)
			return true
	return false


## Forgets the rate counts (leaving a game, tests).
func bot_talk_reset() -> void:
	_bot_talk_limiter.clear()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_bot_talk(text: String) -> void:
	if is_host():
		_host_bot_talk(multiplayer.get_remote_sender_id(), text)

# --- M4 I: gifts and visits -------------------------------------------------------------------------
# M4 Wave 3, agent I (spec §17.5): a friend's showcase is visited in a small read-only world of its own
# (world/visit/visit.tscn, VisitWorld), even while the friend is away. The showcase comes from
# OnlineService.showcase_of; the visit world never registers with Session, so no edit reaches it.

const VISIT_SCENE := "res://world/visit/visit.tscn"

## The showcase being visited (GiftRules.showcase), for the visit scene when it starts.
var visit_showcase: Dictionary = {}


## Goes to a friend's showcase (from PLAY ONLINE's friends page: VISIT). Solo: nothing of a match.
func start_visit(showcase: Dictionary) -> void:
	if showcase.is_empty():
		return
	visit_showcase = showcase
	close()
	get_tree().paused = false
	get_tree().change_scene_to_file(VISIT_SCENE)


## Back to the menu from a visit.
func leave_visit() -> void:
	visit_showcase = {}
	Game.quit_to_menu()

# --- M3 Task 4: a boss's avatar item ---------------------------------------------------------------------------
# Beating the Cake Monster (the Candy Kingdom's boss) in Survivor earns every player the cosmic outfit, like the
# next universe: the host decides, each game adds it to its own profile (AvatarUnlocks.earn, never twice) and
# says so; a guest saves at once (the host's profile is saved with its world).

const EARNED_MESSAGE := "You got a new look: %s! Try it on in the avatar editor."


## Host: every player's game earns `event`'s avatar items (AvatarCatalog.EARN_*).
func boss_earn(event: StringName) -> void:
	if not is_host():
		return
	_rpc_boss_earn.rpc(String(event))
	boss_apply_earn(event)


## Adds `event`'s items to this game's profile and says so (true when something was new).
func boss_apply_earn(event: StringName) -> bool:
	if not AvatarCatalog.EARN_REASONS.has(event):
		return false
	var got := AvatarUnlocks.earn(Profile.data, event)
	for id: String in got:
		magic_feedback.emit(tr(EARNED_MESSAGE) % str(AvatarCatalog.ITEMS[id].name))
	return not got.is_empty()


@rpc("authority", "call_remote", "reliable")
func _rpc_boss_earn(event: String) -> void:
	if boss_apply_earn(StringName(event)):
		Profile.save()

# --- M3 Task 14b: blasters ---------------------------------------------------------------------------
# A blaster shot asks the host (request_blast). The host checks it (a blaster, a sane aim; in Survivor the
# blaster owned and one ammo taken from the inventory, "Out of Foam Darts!" once when there is none; its
# rate and reload with a little slack, one BlasterRules.Magazine per player and blaster) and emits
# blast_requested; the sandbox's BlasterDirector flies it for everyone from the host's own copy of the
# shooter's eyes. Sandbox blasters never use ammo.

## Host only: a checked blaster shot for the BlasterDirector.
signal blast_requested(peer_id: int, blaster_id: int, dir: Vector3)

const BLAST_TELL_GAP_MS := 2500   # "Out of ...!" at most this often per player

var _magazines := {}              # host: peer id -> {blaster id: BlasterRules.Magazine}
var _blast_told := {}             # host: peer id -> msec of its last "out of ammo"


## Fires the blaster `blaster_id` along `dir` (the host decides).
# --- Owner #124: a VR player's shot leaves the weapon in the hand, not the eye ---
## A hand is never farther than this from the eye (× the player's size): a farther origin is not believed.
const SHOT_ORIGIN_REACH := 1.6
var _shot_origins := {}   # host: peer id -> where that player's next shot starts


## Sent just before a shot (request_blast, request_attack) on the same reliable channel, so it arrives first.
func request_shot_origin(origin: Vector3) -> void:
	if not origin.is_finite():
		return
	if is_host():
		_host_shot_origin(multiplayer.get_unique_id(), origin)
	else:
		_rpc_shot_origin.rpc_id(1, origin)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_shot_origin(origin: Vector3) -> void:
	if is_host():
		_host_shot_origin(multiplayer.get_remote_sender_id(), origin)


func _host_shot_origin(peer_id: int, origin: Vector3) -> void:
	_shot_origins[peer_id] = origin


## Host: where `p`'s shot starts (taken once): the origin it sent when that is near its eye, else its eye.
func shot_origin(p: Player) -> Vector3:
	var eye := p.eye_position()
	var o: Variant = _shot_origins.get(p.peer_id)
	_shot_origins.erase(p.peer_id)
	if o is Vector3 and (o as Vector3).is_finite() \
			and (o as Vector3).distance_to(eye) <= SHOT_ORIGIN_REACH * maxf(p.size_scale(), 0.1):
		return o
	return eye


func request_blast(blaster_id: int, dir: Vector3) -> void:
	if is_host():
		_host_blast(multiplayer.get_unique_id(), blaster_id, dir)
	else:
		_rpc_blast.rpc_id(1, blaster_id, dir)


## Host check of one shot at time now_ms; takes its ammo (Survivor) and counts it when accepted.
func accept_blast(peer_id: int, blaster_id: int, dir: Vector3, now_ms: int) -> bool:
	if not BlasterRules.is_blaster(blaster_id) or not BlasterRules.aim_ok(dir):
		return false
	var p := _player_for_peer(peer_id)
	if p == null or not p.is_spawned():
		return false
	var unlimited := Game.allows(ModeRules.UNLIMITED_BLOCKS)
	var inv := inventory_of(peer_id)
	if not unlimited and not inv.has(blaster_id):
		return false                              # Survivor: only a blaster you own
	var ammo := BlasterRules.ammo_of(blaster_id)
	var why := BlasterRules.ammo_refusal(blaster_id, unlimited, inv.count(ammo))
	if why != "":
		if now_ms - int(_blast_told.get(peer_id, -BLAST_TELL_GAP_MS)) >= BLAST_TELL_GAP_MS:
			_blast_told[peer_id] = now_ms
			send_feedback(peer_id, why)
		return false
	var mags: Dictionary = _magazines.get(peer_id, {})
	_magazines[peer_id] = mags
	if not mags.has(blaster_id):
		mags[blaster_id] = BlasterRules.Magazine.new(blaster_id, BlasterRules.HOST_SLACK)
	var mag: BlasterRules.Magazine = mags[blaster_id]
	if not mag.can_fire(now_ms):
		return false                              # its rate and reload (a modified client can't spray)
	if not unlimited and not inv.take(ammo, 1):
		return false
	return mag.fire(now_ms)


## Host (and tests): forgets every player's magazines and "out of ammo" timers.
func blaster_reset() -> void:
	_magazines.clear()
	_blast_told.clear()


func _host_blast(peer_id: int, blaster_id: int, dir: Vector3) -> void:
	if accept_blast(peer_id, blaster_id, dir, Time.get_ticks_msec()):
		blast_requested.emit(peer_id, blaster_id, dir.normalized())


@rpc("any_peer", "call_remote", "reliable")
func _rpc_blast(blaster_id: int, dir: Vector3) -> void:
	if is_host():
		_host_blast(multiplayer.get_remote_sender_id(), blaster_id, dir)

# --- Owner 42: more secrets -----------------------------------------------------------------------------
# The treasure pack (spec §12.16b). A tap on a wishing well asks the host; the host's TreasureDirector (node
# "Secrets/Treasures" on every peer) decides — within reach, once per in-game day for each player — and gives
# the day's fixed gift. The ghosts' riddles go through request_wanderer_answer (a ghost's name starts with
# "ghost_"); the vault's levers are Task 7's smart-block taps; pots of gold are reached by walking.

## Host only: a player tossed a coin into the wishing well `well_name` (a SecretThing's name).
signal secret_wish_requested(peer_id: int, well_name: String)


func request_wish(well_name: String) -> void:
	if is_host():
		secret_wish_requested.emit(multiplayer.get_unique_id(), well_name)
	else:
		_rpc_secret_wish.rpc_id(1, well_name)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_secret_wish(well_name: String) -> void:
	if is_host():
		secret_wish_requested.emit(multiplayer.get_remote_sender_id(), well_name)

# --- Owner 40: commands ---
# /freeze stops the day clock for everyone: the host decides and tells every game (a guest who joins
# hears it with the host's command switch, so a LAN guest only runs what the host allows). Each game's
# ChatCommandRunner follows clock_frozen_changed with its sky.

## Everyone: the day clock stopped (true) or runs again (false).
signal clock_frozen_changed(frozen: bool)

var clock_frozen := false


## Host: stops or starts the day clock for everyone (/freeze).
func set_clock_frozen(frozen: bool) -> void:
	if not is_host():
		return
	clock_frozen = frozen
	clock_frozen_changed.emit(frozen)
	for id in multiplayer.get_peers():
		_rpc_command_state.rpc_id(id, frozen, commands_enabled)


## Host: a guest who just joined hears the clock and whether commands are on.
func send_command_state(peer_id: int) -> void:
	if is_host() and multiplayer.get_peers().has(peer_id):
		_rpc_command_state.rpc_id(peer_id, clock_frozen, commands_enabled)


## The game is over (or a test ends): the clock runs again.
func command_state_reset() -> void:
	clock_frozen = false


@rpc("authority", "call_remote", "reliable")
func _rpc_command_state(frozen: bool, enabled: bool) -> void:
	commands_enabled = enabled
	if frozen != clock_frozen:
		clock_frozen = frozen
		clock_frozen_changed.emit(frozen)

# --- M3 Task 14a: gadgets (the grappling hook, the orbs, quick builds, ziplines) ------------------------------
# Every use is a request the host checks with its own positions and clock: the player is there, owns the gadget
# (Sandbox: always; Survivor: in the bag, and an orb thrown is used up), the gadget's own pace (the hook and the
# orbs once a second, a build every 0.6 s, a zipline every 0.5 s), and the gadget's rule: a hook only onto a
# block within 24 blocks that a grid ray from the eyes reaches first (never through walls, never a player or a
# monster), a build only into empty cells through the batch path (one undo step, paid whole from the bag in
# Survivor: "Need 12 Planks!"), a ride only on a linked post within reach. The player's own game moves its body
# (the glider needs no request: it only slows a fall); the host tells it "go" (hook, ride) and everyone sees it
# (GadgetDirector, ZiplineDirector).

## Host: a checked orb throw (the GadgetDirector flies it in every game and bursts it).
signal gadget_orb_thrown(peer_id: int, item: int, from: Vector3, velocity: Vector3)
## Host: a checked hook (the GadgetDirector shows the rope in every game).
signal gadget_hooked(peer_id: int, point: Vector3)
## Host: a quick build went up (the GadgetDirector's puff at its middle).
signal gadget_built(peer_id: int, item: int, center: Vector3)
## Host: a player asks to ride the line of the post at `post` (checked: the post, near it, the pace); the
## ZiplineDirector answers with send_zip_start, or with kind words.
signal gadget_zip_requested(peer_id: int, post: Vector3i)

const GADGET_GRAB_MESSAGE := "Walk up to the post to ride its line!"

## The host's clock for the gadgets' pace (tests set their own).
var gadget_now_ms: Callable = Time.get_ticks_msec
var _gadget_last := {}   # host: "<peer>:<use>" -> msec of its last use


func gadget_reset() -> void:
	_gadget_last.clear()
	gadget_now_ms = Time.get_ticks_msec


## Host: may peer_id use `item`? Sandbox: always; Survivor: one is in its bag.
func gadget_owns(peer_id: int, item: int) -> bool:
	return Game.allows(ModeRules.UNLIMITED_BLOCKS) or inventory_of(peer_id).count(item) > 0


func _gadget_pace(peer_id: int, use: StringName, seconds: float) -> bool:
	var key := "%d:%s" % [peer_id, use]
	var now: int = gadget_now_ms.call()
	if _gadget_last.has(key) and now - int(_gadget_last[key]) < int(seconds * 1000.0):
		return false
	_gadget_last[key] = now
	return true


func _gadget_player(peer_id: int) -> Player:
	var p := _player_for_peer(peer_id)
	return p if p and p.is_spawned() and world else null


func _gadget_solid(cell: Vector3i) -> bool:
	return BlockIds.is_solid(world.get_block(cell))


## The grappling hook thrown at block `cell`. A guest returns true once sent.
func request_hook(cell: Vector3i) -> bool:
	if world == null:
		return false
	if is_host():
		return host_hook(multiplayer.get_unique_id(), cell)
	_rpc_gadget_hook.rpc_id(1, cell)
	return true


func host_hook(peer_id: int, cell: Vector3i) -> bool:
	var p := _gadget_player(peer_id)
	if p == null or not gadget_owns(peer_id, ItemIds.GRAPPLE):
		return false
	var r := GadgetRules.hook_check(p.eye_position(), cell, _gadget_solid)
	if not r.ok:
		send_feedback(peer_id, GadgetRules.hook_message(r.error))
		return false
	if not _gadget_pace(peer_id, &"hook", GadgetRules.HOOK_COOLDOWN):
		return false
	send_hook_start(peer_id, r.point)
	gadget_hooked.emit(peer_id, r.point)
	return true


## An orb thrown the way `dir` points (from the thrower's eyes).
func request_orb(item: int, dir: Vector3) -> bool:
	if world == null:
		return false
	if is_host():
		return host_orb(multiplayer.get_unique_id(), item, dir)
	_rpc_gadget_orb.rpc_id(1, item, dir)
	return true


func host_orb(peer_id: int, item: int, dir: Vector3) -> bool:
	var p := _gadget_player(peer_id)
	if p == null or not GadgetRules.is_orb(item) or not dir.is_finite() or dir.length() < 0.01:
		return false
	if not gadget_owns(peer_id, item):
		send_feedback(peer_id, tr("You have no %s left!") % Lang.t(ItemIds.display_name(item)))
		return false
	if not _gadget_pace(peer_id, &"orb", GadgetRules.ORB_COOLDOWN):
		return false
	if not Game.allows(ModeRules.UNLIMITED_BLOCKS):
		inventory_of(peer_id).take(item, 1)   # Survivor: an orb thrown is used up
	var d := dir.normalized()
	gadget_orb_thrown.emit(peer_id, item, p.eye_position() + d * 0.6, GadgetRules.orb_velocity(d))
	return true


## A quick build put in front of the player, who looks along `yaw`.
func request_instant_build(item: int, yaw: float) -> bool:
	if world == null:
		return false
	if is_host():
		return host_instant_build(multiplayer.get_unique_id(), item, yaw)
	_rpc_gadget_build.rpc_id(1, item, yaw)
	return true


func host_instant_build(peer_id: int, item: int, yaw: float) -> bool:
	var p := _gadget_player(peer_id)
	if p == null or not GadgetRules.is_build(item) or not is_finite(yaw) or not gadget_owns(peer_id, item):
		return false
	if not _gadget_pace(peer_id, &"build", GadgetRules.BUILD_COOLDOWN):
		return false
	var a := GadgetRules.build_anchor(p.global_position, yaw, item)
	var free := GadgetRules.empty_cells(GadgetRules.build_cells(item, a.anchor, a.forward), world.get_block)
	if free.is_empty():
		send_feedback(peer_id, GadgetRules.NOTHING_TO_BUILD)
		return false
	var material := BlockIds.PLANKS
	if not Game.allows(ModeRules.UNLIMITED_BLOCKS):
		var inv := inventory_of(peer_id)
		material = GadgetRules.build_material(inv.count(BlockIds.PLANKS), inv.count(BlockIds.STONE), free.size())
		if material == 0:
			send_feedback(peer_id, GadgetRules.short_message(free.size()))
			return false
	if _host_apply_batch(peer_id, GadgetRules.with_material(free, material)) == 0:
		return false
	var center := Vector3.ZERO
	for c: Array in free:
		center += Vector3(c[0])
	gadget_built.emit(peer_id, item, center / free.size() + Vector3(0.5, 0.5, 0.5))
	return true


## A tap on a zipline post: ride its line.
func request_zipline(post: Vector3i) -> bool:
	if world == null:
		return false
	if is_host():
		return host_zipline(multiplayer.get_unique_id(), post)
	_rpc_gadget_zip.rpc_id(1, post)
	return true


func host_zipline(peer_id: int, post: Vector3i) -> bool:
	var p := _gadget_player(peer_id)
	if p == null or world.get_block(post) != BlockIds.ZIPLINE_POST or p.gadget_move == GadgetRules.Move.ZIP:
		return false
	if not GadgetRules.can_grab(p.global_position, post):
		send_feedback(peer_id, GADGET_GRAB_MESSAGE)
		return false
	if not _gadget_pace(peer_id, &"zip", GadgetRules.ZIP_COOLDOWN):
		return false
	gadget_zip_requested.emit(peer_id, post)
	return true


## Host -> a player: its hook holds at `point` (its own game pulls it there).
func send_hook_start(peer_id: int, point: Vector3) -> void:
	if peer_id == multiplayer.get_unique_id():
		_gadget_start_hook(point)
	elif multiplayer.get_peers().has(peer_id):
		_rpc_gadget_hook_start.rpc_id(peer_id, point)


## Host -> a player: ride the line from `from` to `to` (attach points).
func send_zip_start(peer_id: int, from: Vector3, to: Vector3) -> void:
	if peer_id == multiplayer.get_unique_id():
		_gadget_start_zip(from, to)
	elif multiplayer.get_peers().has(peer_id):
		_rpc_gadget_zip_start.rpc_id(peer_id, from, to)


func _gadget_start_hook(point: Vector3) -> void:
	var me := _player_for_peer(multiplayer.get_unique_id())
	if me and point.is_finite():
		me.start_hook(point)


func _gadget_start_zip(from: Vector3, to: Vector3) -> void:
	var me := _player_for_peer(multiplayer.get_unique_id())
	if me and from.is_finite() and to.is_finite() and from.distance_to(to) <= GadgetRules.ZIP_MAX_LENGTH + 1.0:
		me.start_zip(from, to)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_gadget_hook(cell: Vector3i) -> void:
	if is_host():
		host_hook(multiplayer.get_remote_sender_id(), cell)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_gadget_orb(item: int, dir: Vector3) -> void:
	if is_host():
		host_orb(multiplayer.get_remote_sender_id(), item, dir)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_gadget_build(item: int, yaw: float) -> void:
	if is_host():
		host_instant_build(multiplayer.get_remote_sender_id(), item, yaw)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_gadget_zip(post: Vector3i) -> void:
	if is_host():
		host_zipline(multiplayer.get_remote_sender_id(), post)


@rpc("authority", "call_remote", "reliable")
func _rpc_gadget_hook_start(point: Vector3) -> void:
	_gadget_start_hook(point)


@rpc("authority", "call_remote", "reliable")
func _rpc_gadget_zip_start(from: Vector3, to: Vector3) -> void:
	_gadget_start_zip(from, to)

# --- M3 Task 11: pets with perks --------------------------------------------------------------------
# A child's taps on pets go to the host, which decides (PetDirector, node "Pets" in the sandbox): a treat (a
# tap holding one of ItemIds.TREATS; Survivor pays one from the bag), a pat (the heart), a name (from the list,
# or for 13+ a typed name through the username filter: the host reads the SENDER's registered chat band, never
# what the request claims), a collar colour, and Pip coming along from the child's profile. What changes
# travels as the pets' synced properties; the bark, the pointing and the dig puff are RPCs on the animal. The
# parrot's words never travel (PetEcho).

const PET_NAME_RAW := 64          # longer requests are cut before the checks

## Host only: `peer_id` asks for something about the animal called `animal_name`.
signal pet_treat_requested(peer_id: int, animal_name: String, item: int)
signal pet_pat_requested(peer_id: int, animal_name: String)
signal pet_name_requested(peer_id: int, animal_name: String, pet_name: String)
signal pet_collar_requested(peer_id: int, animal_name: String, collar: int)
## Host only: `peer_id` brings their Pip (PetRules.clean_pip of their profile's record).
signal pip_requested(peer_id: int, record: Dictionary)


func pet_request_treat(animal_name: String, item: int) -> void:
	if is_host():
		pet_treat_requested.emit(multiplayer.get_unique_id(), animal_name, item)
	else:
		_rpc_pet_treat.rpc_id(1, animal_name, item)


func pet_request_pat(animal_name: String) -> void:
	if is_host():
		pet_pat_requested.emit(multiplayer.get_unique_id(), animal_name)
	else:
		_rpc_pet_pat.rpc_id(1, animal_name)


func pet_request_name(animal_name: String, pet_name: String) -> void:
	if is_host():
		pet_name_requested.emit(multiplayer.get_unique_id(), animal_name, pet_name.substr(0, PET_NAME_RAW))
	else:
		_rpc_pet_name.rpc_id(1, animal_name, pet_name.substr(0, PET_NAME_RAW))


func pet_request_collar(animal_name: String, collar: int) -> void:
	if is_host():
		pet_collar_requested.emit(multiplayer.get_unique_id(), animal_name, collar)
	else:
		_rpc_pet_collar.rpc_id(1, animal_name, collar)


func pet_request_pip(record: Dictionary) -> void:
	var clean := PetRules.clean_pip(record)
	if clean.is_empty():
		return
	if is_host():
		pip_requested.emit(multiplayer.get_unique_id(), clean)
	else:
		_rpc_pet_pip.rpc_id(1, clean)


## Host: the age band `peer_id` registered for chat (under 13 when they never did).
func pet_band_of(peer_id: int) -> StringName:
	return ChatRules.effective_band(_chat_bands.get(peer_id, AgeBand.unknown()))


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pet_treat(animal_name: String, item: int) -> void:
	if is_host():
		pet_treat_requested.emit(multiplayer.get_remote_sender_id(), animal_name, item)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pet_pat(animal_name: String) -> void:
	if is_host():
		pet_pat_requested.emit(multiplayer.get_remote_sender_id(), animal_name)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pet_name(animal_name: String, pet_name: String) -> void:
	if is_host():
		pet_name_requested.emit(multiplayer.get_remote_sender_id(), animal_name, pet_name.substr(0, PET_NAME_RAW))


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pet_collar(animal_name: String, collar: int) -> void:
	if is_host():
		pet_collar_requested.emit(multiplayer.get_remote_sender_id(), animal_name, collar)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pet_pip(record: Dictionary) -> void:
	if is_host():
		pip_requested.emit(multiplayer.get_remote_sender_id(), PetRules.clean_pip(record))

# --- M3 Task 20a: rideable buddies -------------------------------------------------------------------------
# A buddy built with a SADDLE can be ridden (RideRules). The host decides every ride (RideDirector): getting on
# (RIDE), the rider's stick, which comes to the host like a player's input (unreliable, at most 20 times a
# second), and getting off (RIDE again, JUMP off a walker, a car or a boat, a Survivor flight's landing). The host
# moves the buddy; its synchronizer carries it to every game, where RemoteSmoother shows it smoothly, and every
# game puts the rider on the saddle. Getting off, the host tells the rider's own game where to stand.

## Host: player `peer_id` asks to ride the buddy named `buddy_name`.
signal ride_requested(peer_id: int, buddy_name: String)
## Host: player `peer_id` asks to get off.
signal ride_off_requested(peer_id: int)
## Host: player `peer_id`'s stick for the buddy it rides (not checked yet: RideDirector does).
signal ride_input_received(peer_id: int, buddy_name: String, wish: Vector3)
## This game's player: the host says where to stand after getting off.
signal ride_off_received(spot: Vector3)

const RIDE_NAME_MAX := 32


## RIDE near a saddled buddy: this game's player asks the host to get on.
func request_ride(buddy_name: String) -> void:
	if is_host():
		ride_requested.emit(multiplayer.get_unique_id(), buddy_name)
	else:
		_rpc_ride.rpc_id(1, buddy_name.substr(0, RIDE_NAME_MAX))


## RIDE again (or JUMP off): this game's player asks the host to get off.
func request_ride_off() -> void:
	if is_host():
		ride_off_requested.emit(multiplayer.get_unique_id())
	else:
		_rpc_ride_off_request.rpc_id(1)


## The rider's stick (x/z the way to go in the world, y up or down) for the buddy it rides.
func ride_input(buddy_name: String, wish: Vector3) -> void:
	if is_host():
		ride_input_received.emit(multiplayer.get_unique_id(), buddy_name, wish)
	else:
		_rpc_ride_input.rpc_id(1, buddy_name.substr(0, RIDE_NAME_MAX), wish)


## Host -> the rider who got off: stand here.
func send_ride_off(peer_id: int, spot: Vector3) -> void:
	if peer_id == multiplayer.get_unique_id():
		ride_off_received.emit(spot)
	elif multiplayer.get_peers().has(peer_id):
		_rpc_ride_off.rpc_id(peer_id, spot)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_ride(buddy_name: String) -> void:
	if is_host():
		ride_requested.emit(multiplayer.get_remote_sender_id(), buddy_name.substr(0, RIDE_NAME_MAX))


@rpc("any_peer", "call_remote", "reliable")
func _rpc_ride_off_request() -> void:
	if is_host():
		ride_off_requested.emit(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_ride_input(buddy_name: String, wish: Vector3) -> void:
	if is_host():
		ride_input_received.emit(multiplayer.get_remote_sender_id(), buddy_name.substr(0, RIDE_NAME_MAX), wish)


@rpc("authority", "call_remote", "reliable")
func _rpc_ride_off(spot: Vector3) -> void:
	ride_off_received.emit(spot)

# --- M3 Task 10: the Gold Farm ------------------------------------------------------------------------------
# A world's farm is its owner's (the host's player): only they buy one from Tilly (one per world), place it
# (the FARM item, like a stamp) and upgrade it. Placing and upgrading are requests the host checks and hands
# to its FarmDirector through the signals below. The welcome-back pays through gold_add; gold the server's
# farm_collect already put into its wallet (signed in) comes in through farm_pay_collected, which never
# reports it to the server again.

## Host: a player asks to place their farm: the middle of its front row at `anchor`, the door on `facing`.
signal farm_place_requested(peer_id: int, anchor: Vector3i, facing: int)
## Host: a player asks for an upgrade (FarmRules.RATE or FarmRules.CAP).
signal farm_upgrade_requested(peer_id: int, kind: StringName)
## Host: a player asks to pick the farm up and put it somewhere else.
signal farm_move_requested(peer_id: int)

## Host: () -> bool, the world has its farm (the FarmDirector sets it).
var farm_built := Callable()


func request_farm_place(anchor: Vector3i, facing: int) -> void:
	if is_host():
		farm_place_requested.emit(multiplayer.get_unique_id(), anchor, posmod(facing, 4))
	else:
		_rpc_farm_place.rpc_id(1, anchor, posmod(facing, 4))


func request_farm_upgrade(kind: StringName) -> void:
	if is_host():
		farm_upgrade_requested.emit(multiplayer.get_unique_id(), kind)
	else:
		_rpc_farm_upgrade.rpc_id(1, String(kind))


func request_farm_move() -> void:
	if is_host():
		farm_move_requested.emit(multiplayer.get_unique_id())
	else:
		_rpc_farm_move.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_farm_move() -> void:
	if is_host():
		farm_move_requested.emit(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func _rpc_farm_place(anchor: Vector3i, facing: int) -> void:
	if is_host():
		farm_place_requested.emit(multiplayer.get_remote_sender_id(), anchor, posmod(facing, 4))


@rpc("any_peer", "call_remote", "reliable")
func _rpc_farm_upgrade(kind: String) -> void:
	if is_host() and (kind == String(FarmRules.RATE) or kind == String(FarmRules.CAP)):
		farm_upgrade_requested.emit(multiplayer.get_remote_sender_id(), StringName(kind))


## Host: why `peer_id` can't buy `id` because of the farm rules ("" = they can): Tilly sells a farm only to
## the world's owner, and only while the world has none.
func farm_buy_refusal(peer_id: int, id: int) -> String:
	if id != ItemIds.FARM:
		return ""
	return FarmRules.buy_refusal(peer_id == multiplayer.get_unique_id(), farm_built.is_valid() and bool(farm_built.call()))


## Host, its own player: farm gold the server's farm_collect already paid into the server's wallet. The phone's
## gold goes up like gold_add's, but it is not reported to the server again, and the device's wallet marker
## moves with it (online through own_gold_moved_online, else here), so the wallet sync never sends it twice.
func farm_pay_collected(amount: int) -> void:
	if not is_host() or amount <= 0 or Game.allows(ModeRules.INFINITE_GOLD):
		return
	var me := multiplayer.get_unique_id()
	var w := _wallet(me)
	var before := w.balance
	w.add(amount)
	_store_gold(me, w.balance)
	if not (is_online() or _f_test_online_host) and _online_service:
		_online_service.farm_paid_on_phone(w.balance - before)

# --- Owner 35: shop ------------------------------------------------------------------------------------
# The honest, parent-facing shop (owner feedback #35, spec §18): one ShopService for the game (made on
# first use), over the store this build has (ShopService.billing_for_this_build: Google Play once the owner
# turns it on, the pretend store in debug builds, none otherwise). At start it quietly restores what the
# store account owns (a reinstall, a payment that finished while the game was closed). Purchases happen
# only in the grown-up area's SHOP page (ShopPage), behind the parent gate; the child's side asks only
# whether a universe is open (shop_travel_refusal).

var _shop: ShopService


func _shop_ready() -> void:
	if DisplayServer.get_name() != "headless":   # tests and tools never touch a store
		(func() -> void: shop().restore_at_start()).call_deferred()


func shop() -> ShopService:
	if _shop == null:
		var s := ShopService.new()
		s.billing = ShopService.billing_for_this_build()
		s.profile = Profile.data   # the Profile autoload's object (a backup restore copies into it)
		use_shop(s)
	return _shop


## Tests: this service (with a fake store) instead of the build's; null forgets it.
func use_shop(s: ShopService) -> void:
	_shop = s
	if s == null:
		return
	if s.profile == null:
		s.profile = Profile.data
	if not s.save_profile.is_valid():
		s.save_profile = func() -> void:
			Profile.save()
			Profile.avatar_changed.emit()   # new items to wear
	s.start()


## Why this game's child can't travel to Survivor universe u ("" = they can): the line about EasyCraft
## Plus, said with a grown-up in it once per profile (ShopWords.plus_line; saved), calm after that.
func shop_travel_refusal(u: int) -> String:
	if Entitlements.travel_refusal(u, Profile.data.purchases, shop().store_open()) == "":
		return ""
	var once := ShopWords.plus_once_due(Profile.data)
	var line := ShopWords.plus_line(Profile.data)
	if once and DisplayServer.get_name() != "headless":
		Profile.save()
	return line

# --- M3 Task 8: building tools (paint, line, fill, copy/paste) ----------------------------------------------
# Every tool edit is a request the host checks with its own world and positions (request_build_tool): PAINT
# (Sandbox and Survivor: a tap and its mirror copy; only a plain block becomes a painted one, PaintRules; free in
# Survivor, where a precious block is never painted; no ledger either way), LINE, FILL and PASTE (Sandbox only;
# at most PowerTools.LINE_MAX or FILL_MAX blocks, refused whole beyond; only ever into empty cells, air or water,
# never inside a body; within PowerTools.REACH of the requester's eyes). Each request is one undo step, sent back
# like the ordinary ones (tool_undo_step_received) and undone through here too (UNDO): the host keeps each
# player's last TOOL_LOG_STEPS tool steps and undoes a cell only when its log says this player's tool made it and
# it still holds what the tool put there. So paint's undo is free in Survivor and a guest can never "undo" a
# block into something that was never there. Tool edits are not counted as blocks placed (M3 Task 12's XP).

## Local: one undo step of this player's tool edits, decided by the host ([pos, id to put back, id now], like
## undo_step_received); BlockInteractor undoes it with request_build_tool(TOOL_UNDO, ...).
signal tool_undo_step_received(step: Array)

const TOOL_PAINT := &"paint"
const TOOL_LINE := &"line"
const TOOL_FILL := &"fill"
const TOOL_PASTE := &"paste"
const TOOL_UNDO := &"undo"
const TOOL_KINDS: Array[StringName] = [TOOL_PAINT, TOOL_LINE, TOOL_FILL, TOOL_PASTE, TOOL_UNDO]
## The most cells of one request: a paint tap and its mirror copy; a line; a fill or a paste (16³).
const TOOL_CAPS := {TOOL_PAINT: 2, TOOL_LINE: PowerTools.LINE_MAX, TOOL_FILL: PowerTools.FILL_MAX,
	TOOL_PASTE: PowerTools.FILL_MAX, TOOL_UNDO: PowerTools.FILL_MAX}
const TOOL_LOG_STEPS := 20   # BlockInteractor.UNDO_DEPTH
## Tool edits are written TOOL_CHUNK cells at a time (one read, one copy and one paste of their box), a physics frame
## writing chunks until TOOL_FRAME_MS have gone (at least one chunk): every changed cell is announced to about ten
## listeners (block_changed), which cost 13-20 µs a cell on this PC when the world is settled and up to 0.9 ms while
## it streams (docs/devlog/parts/m3-task-8.md), so a big edit takes as many frames as the device needs and no frame
## pays for all of it. An edit of at most TOOL_AT_ONCE cells (paint, a line, small pastes) is written at once.
const TOOL_CHUNK := 16
const TOOL_FRAME_MS := 8.0
const TOOL_AT_ONCE := 64
## A tool edit's cell waits for "air or water" (a paint and an undo wait for exactly what the cell held).
const TOOL_EMPTY := -1
const TOOLS_SANDBOX_ONLY := "The building tools work in Sandbox!"
## Unfinished tool edits (an undo too) a player may have waiting at once (the M3 review: the queue had no cap).
const TOOL_JOBS_PER_PLAYER := 2
const TOOLS_STILL_BUILDING := "Still building! Wait a moment."

var _tool_log := {}          # host: peer id -> [PackedInt32Array of [x, y, z, before, after] per cell], oldest first
var _tool_log_world: Object = null
var _tool_jobs: Array = []   # host: {peer, todo [[pos, id, what it must hold]], at, done [[pos, old, new]], undo, pending}
## The most milliseconds one frame spent writing tool edits (the smoke run's measurement).
var tool_slowest_slice_ms := 0.0
## TOOL_FRAME_MS (tests set 0: one chunk a frame).
var tool_frame_ms := TOOL_FRAME_MS


## A tool edit ([[pos, id], ...]; UNDO: [[pos, id to put back], ...]). A guest returns true once sent.
func request_build_tool(kind: StringName, changes: Array) -> bool:
	if world == null or changes.is_empty() or not TOOL_KINDS.has(kind):
		return false
	if is_host():
		return host_build_tool(multiplayer.get_unique_id(), kind, changes) > 0
	_rpc_build_tool.rpc_id(1, String(kind), changes)
	return true


## Host: checks one tool request of peer_id and applies it (a big one a slice a frame: _tool_tick); how many cells
## it changes.
func host_build_tool(peer_id: int, kind: StringName, changes: Array) -> int:
	if world == null or not TOOL_KINDS.has(kind):
		return 0
	if _tool_log_world != world:   # another world: old logs and unfinished edits mean nothing here
		_tool_log.clear()
		_tool_jobs.clear()
		_tool_log_world = world
	var p := _player_for_peer(peer_id)
	if p == null or not p.is_spawned():
		return 0
	if not Game.allows(ModeRules.BUILDING):
		send_feedback(peer_id, ArenaRules.NO_BUILDING_WORDS)
		return 0
	if _tool_jobs.filter(func(j: Dictionary) -> bool: return j.peer == peer_id).size() >= TOOL_JOBS_PER_PLAYER:
		send_feedback(peer_id, TOOLS_STILL_BUILDING)
		return 0
	var cap: int = TOOL_CAPS[kind]
	if changes.size() > cap:
		send_feedback(peer_id, PowerTools.message(PowerTools.TOO_LONG if kind == TOOL_LINE else PowerTools.TOO_BIG))
		return 0
	var clean := EditBatch.sanitize(changes, cap)
	if kind == TOOL_UNDO:
		return _tool_undo(peer_id, clean)
	var sandbox := Game.allows(ModeRules.UNLIMITED_BLOCKS)
	if kind != TOOL_PAINT and not sandbox:
		send_feedback(peer_id, TOOLS_SANDBOX_ONLY)
		return 0
	var job := {"peer": peer_id, "todo": [], "at": 0, "done": [], "undo": false, "pending": [],
		"eye": p.eye_position(), "bodies": _player_bodies()}
	if kind == TOOL_PAINT:   # at most 2 cells: checked here, with a reason for the child
		var olds := world.blocks_at(clean.map(func(c: Array) -> Vector3i: return c[0]))
		var why := ""
		for i in clean.size():
			var code := PaintRules.refusal(olds[i], clean[i][1], not sandbox)
			if code == "" and not PlacementRules.in_reach(job.eye, clean[i][0], PlacementRules.BATCH_REACH):
				code = PlacementRules.TOO_FAR_MESSAGE
			if code != "":
				why = (PaintRules.message(code, olds[i]) if code != PlacementRules.TOO_FAR_MESSAGE else code) if why == "" else why
				continue
			(job.todo as Array).append([clean[i][0], clean[i][1], olds[i]])
		if (job.todo as Array).is_empty():
			if why != "":
				send_feedback(peer_id, why)
			return 0
	else:   # LINE, FILL, PASTE: each cell is checked when its chunk is written (_tool_write), not all in one frame
		for c: Array in clean:
			if c[1] != BlockIds.AIR:
				(job.todo as Array).append([c[0], c[1], TOOL_EMPTY])
	_tool_jobs.append(job)
	if (job.todo as Array).size() <= TOOL_AT_ONCE and _tool_jobs.size() == 1:
		_tool_tick(true)   # a small edit (paint, a line) happens at once
		return (job.done as Array).size()
	return (job.todo as Array).size()


## Host, every physics frame: the next chunks of the oldest unfinished tool edit (for TOOL_FRAME_MS, at least one);
## a finished one becomes one undo step for its player (an undo: the cells it couldn't restore, kept for later).
## `whole`: all of it now (a small edit).
func _tool_tick(whole: bool = false) -> void:
	if _tool_jobs.is_empty() or world == null:
		return
	if _tool_log_world != world:   # another world since: its edits mean nothing here
		_tool_jobs.clear()
		_tool_log.clear()
		_tool_log_world = world
		return
	var job: Dictionary = _tool_jobs[0]
	var todo: Array = job.todo
	var t0 := Time.get_ticks_usec()
	while job.at < todo.size():
		_tool_write(job, todo.slice(job.at, job.at + TOOL_CHUNK))
		job.at = mini(job.at + TOOL_CHUNK, todo.size())
		if not whole and (Time.get_ticks_usec() - t0) / 1000.0 >= tool_frame_ms:
			break
	tool_slowest_slice_ms = maxf(tool_slowest_slice_ms, (Time.get_ticks_usec() - t0) / 1000.0)
	if job.at < todo.size():
		return
	_tool_jobs.pop_front()
	if job.undo:
		var restored := {}
		for e: Array in job.done:
			restored[e[0]] = true
		var pending: Array = job.pending
		for c: Array in todo:
			if not restored.has(c[0]) and world.get_block(c[0]) == c[2]:
				pending.append([c[0], c[1], c[2]])   # not written (not loaded yet): later; a cell changed since is left
		_tool_remember(job.peer, pending)
		_send_tool_undo_step(job.peer, pending)
	else:
		if (job.done as Array).is_empty():
			send_feedback(job.peer, PowerTools.message(PowerTools.NOTHING))   # every cell was taken, or too far
		_tool_remember(job.peer, job.done)
		_send_tool_undo_step(job.peer, job.done)


## One chunk of a job, checked now (one read of its box): a LINE, FILL or PASTE cell only into air or water, never
## inside a body, within PowerTools.REACH of the eyes at the request (PlacementRules.validate_edit); a paint or an undo
## cell only if it still holds what it held at the request (a cell someone changed since stays as it is). Then
## written and announced.
func _tool_write(job: Dictionary, chunk: Array) -> void:
	var nows := world.blocks_at(chunk.map(func(c: Array) -> Vector3i: return c[0]))
	var still: Array = []
	for i in chunk.size():
		var c: Array = chunk[i]
		if c[2] == TOOL_EMPTY:
			if not PowerTools.is_empty(nows[i]) \
					or not PlacementRules.validate_edit(c[0], c[1], nows[i], job.eye, job.bodies, PowerTools.REACH):
				continue
		elif c[2] != nows[i]:
			continue
		still.append([c[0], c[1]])
	(job.done as Array).append_array(world.set_blocks(still))


## True while a tool edit is still being written (tests wait for it).
func tool_busy() -> bool:
	return not _tool_jobs.is_empty()


## Host: undoes cells of peer_id's tool steps ([[pos, id to put back]]): only a cell its log says this player's
## tool changed from that id, and that still holds what the tool put there; each log entry is used once. A cell it
## can't restore yet (a body stands where a block comes back) goes back to the player as a new undo step (and a new
## log entry), so it can be undone later.
func _tool_undo(peer_id: int, clean: Array) -> int:
	var log: Array = _tool_log.get(peer_id, [])
	var cells: Array = clean.map(func(c: Array) -> Vector3i: return c[0])
	var nows := world.blocks_at(cells)
	var back_of := {}   # pos -> the id to put back
	var now_of := {}    # pos -> what it holds now
	for i in clean.size():
		back_of[cells[i]] = clean[i][1]
		now_of[cells[i]] = nows[i]
	var found := _tool_find(log, back_of, now_of)
	var bodies := _player_bodies()
	var restore: Array = []
	var pending: Array = []
	for pos: Vector3i in found:
		var cells_of_step: PackedInt32Array = log[found[pos][0]]
		cells_of_step[found[pos][1] + 4] = -1   # used: nothing holds "-1", the entry never matches again
		log[found[pos][0]] = cells_of_step
		var back: int = back_of[pos]
		if BlockIds.is_solid(back) and not PlacementRules.can_place(pos, bodies, back):
			pending.append([pos, back, now_of[pos]])
		else:
			restore.append([pos, back, now_of[pos]])
	if restore.is_empty():
		_tool_remember(peer_id, pending)
		_send_tool_undo_step(peer_id, pending)
		return 0
	_tool_jobs.append({"peer": peer_id, "todo": restore, "at": 0, "done": [], "undo": true, "pending": pending})
	if restore.size() <= TOOL_AT_ONCE and _tool_jobs.size() == 1:
		_tool_tick(true)
	return restore.size()


## pos -> [step index, cell offset] of the newest log entry that turned each cell from back_of[pos] into what it
## holds now (now_of[pos]); cells with none are left out. Steps are read newest first, each once, and only until
## every cell is found: an undo of the last step reads that step alone (4,096 cells: one pass, never one per cell).
func _tool_find(log: Array, back_of: Dictionary, now_of: Dictionary) -> Dictionary:
	var found := {}
	for s in range(log.size() - 1, -1, -1):
		if found.size() == back_of.size():
			break
		var cells: PackedInt32Array = log[s]
		for i in range(0, cells.size(), 5):
			var pos := Vector3i(cells[i], cells[i + 1], cells[i + 2])
			if back_of.has(pos) and not found.has(pos) and cells[i + 3] == back_of[pos] and cells[i + 4] == now_of[pos]:
				found[pos] = [s, i]
	return found


func _tool_remember(peer_id: int, step: Array) -> void:
	if step.is_empty():
		return
	var cells := PackedInt32Array()
	for e: Array in step:
		var pos: Vector3i = e[0]
		cells.append_array(PackedInt32Array([pos.x, pos.y, pos.z, e[1], e[2]]))
	var log: Array = _tool_log.get(peer_id, [])
	log.append(cells)
	while log.size() > TOOL_LOG_STEPS:
		log.pop_front()
	_tool_log[peer_id] = log


## Host -> the player who asked: one undo step of tool edits (or the cells an undo couldn't restore yet).
func _send_tool_undo_step(peer_id: int, step: Array) -> void:
	if step.is_empty():
		return
	if peer_id == multiplayer.get_unique_id():
		tool_undo_step_received.emit(step)
	elif multiplayer.get_peers().has(peer_id):
		_rpc_tool_undo_step.rpc_id(peer_id, step)


## Tests: forget every player's tool steps.
func tool_reset() -> void:
	_tool_log.clear()
	_tool_jobs.clear()
	_tool_log_world = null


@rpc("any_peer", "call_remote", "reliable")
func _rpc_build_tool(kind: String, changes: Array) -> void:
	if is_host() and TOOL_KINDS.has(StringName(kind)):
		host_build_tool(multiplayer.get_remote_sender_id(), StringName(kind), changes)


@rpc("authority", "call_remote", "reliable")
func _rpc_tool_undo_step(step: Array) -> void:
	tool_undo_step_received.emit(step)

# --- Owner 39: dragon eggs and the Sky Dragon's baby dragon ----------------------------------------------------
# A tap on a dragon egg asks the host (request_hatch -> egg_hatch_requested: the sandbox's DragonNests decides). A
# child's baby dragon comes along from their profile like Pip (pet_request_baby_dragon -> baby_dragon_requested: the
# PetDirector). Beating the Sky Dragon gives every player's own profile a baby dragon (once) and a Dragon Crystal
# (boss_give_dragon -> dragon_gift_apply on every game).

## Host only: `peer_id` tapped the dragon egg `egg_name` (a SecretThing's name).
signal egg_hatch_requested(peer_id: int, egg_name: String)
## Host only: `peer_id` brings their baby dragon (PetRules.clean_pip of their profile's record).
signal baby_dragon_requested(peer_id: int, record: Dictionary)

const DRAGON_GIFT_WORDS := "You got a baby dragon and a Dragon Crystal! It comes into every world with you."
const DRAGON_CRYSTAL_WORDS := "You got a Dragon Crystal!"


func request_hatch(egg_name: String) -> void:
	if is_host():
		egg_hatch_requested.emit(multiplayer.get_unique_id(), egg_name)
	else:
		_rpc_request_hatch.rpc_id(1, egg_name.substr(0, 128))


func pet_request_baby_dragon(record: Dictionary) -> void:
	var clean := PetRules.clean_pip(record)
	if clean.is_empty():
		return
	if is_host():
		baby_dragon_requested.emit(multiplayer.get_unique_id(), clean)
	else:
		_rpc_pet_baby_dragon.rpc_id(1, clean)


## Host: every player's game gets the Sky Dragon's gifts in its own profile.
func boss_give_dragon() -> void:
	if not is_host():
		return
	_rpc_dragon_gift.rpc()
	magic_feedback.emit(dragon_gift_apply(Profile.data))
	if DisplayServer.get_name() != "headless":
		Profile.save()


## A baby dragon (once, PetRules.give_baby_dragon) and a Dragon Crystal (handed into the bag in the child's own
## Survivor world, CrystalRules.owed) for `profile`; what to say.
static func dragon_gift_apply(profile: ProfileData) -> String:
	var dragon := PetRules.give_baby_dragon(profile)
	if profile.crystal_gifts.size() < CrystalRules.MAX_GIFTS:
		profile.crystal_gifts.append(5)
	return DRAGON_GIFT_WORDS if dragon else DRAGON_CRYSTAL_WORDS


@rpc("authority", "call_remote", "reliable")
func _rpc_dragon_gift() -> void:
	magic_feedback.emit(dragon_gift_apply(Profile.data))
	Profile.save()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_hatch(egg_name: String) -> void:
	if is_host():
		egg_hatch_requested.emit(multiplayer.get_remote_sender_id(), egg_name)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pet_baby_dragon(record: Dictionary) -> void:
	if is_host():
		baby_dragon_requested.emit(multiplayer.get_remote_sender_id(), PetRules.clean_pip(record))


# --- Owner 45b: a bigger world ----------------------------------------------------------------------------
# A guest builds the host's world from its seed: it needs the world's terrain version too (WorldMeta.terrain; the
# wild meadows or the old ones). The host sends it before world_info, like the universe.

## The terrain version of the world being played (the host sets it from its WorldMeta; a guest gets the host's).
var world_terrain := 1


func _own45b_send_terrain(peer_id: int) -> void:
	_rpc_own45b_terrain.rpc_id(peer_id, world_terrain)


@rpc("authority", "call_remote", "reliable")
func _rpc_own45b_terrain(t: int) -> void:
	world_terrain = t if t >= 1 and t <= WorldMeta.TERRAIN_LATEST else 1


# --- Owner feedback #41: more animals ------------------------------------------------------------------------
# A child's taps on their tamed horse or camel holding a SADDLE, and their donkey's chest (put the held stack in,
# take a slot back), go to the host, which decides (PetDirector section "owner #41"). What changes travels as the
# animal's synced `saddled` and `chest`.

## Host only: `peer_id` asks to saddle the animal called `animal_name`.
signal pet_saddle_requested(peer_id: int, animal_name: String)
## Host only: `peer_id` asks to put their held `item` in the donkey's chest, or to take slot `slot` out.
signal pet_chest_put_requested(peer_id: int, animal_name: String, item: int)
signal pet_chest_take_requested(peer_id: int, animal_name: String, slot: int)


func pet_request_saddle(animal_name: String) -> void:
	if is_host():
		pet_saddle_requested.emit(multiplayer.get_unique_id(), animal_name)
	else:
		_rpc_pet_saddle.rpc_id(1, animal_name)


func pet_request_chest_put(animal_name: String, item: int) -> void:
	if is_host():
		pet_chest_put_requested.emit(multiplayer.get_unique_id(), animal_name, item)
	else:
		_rpc_pet_chest_put.rpc_id(1, animal_name, item)


func pet_request_chest_take(animal_name: String, slot: int) -> void:
	if is_host():
		pet_chest_take_requested.emit(multiplayer.get_unique_id(), animal_name, slot)
	else:
		_rpc_pet_chest_take.rpc_id(1, animal_name, slot)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pet_saddle(animal_name: String) -> void:
	if is_host():
		pet_saddle_requested.emit(multiplayer.get_remote_sender_id(), animal_name)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pet_chest_put(animal_name: String, item: int) -> void:
	if is_host():
		pet_chest_put_requested.emit(multiplayer.get_remote_sender_id(), animal_name, item)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pet_chest_take(animal_name: String, slot: int) -> void:
	if is_host():
		pet_chest_take_requested.emit(multiplayer.get_remote_sender_id(), animal_name, slot)

# --- M3 Task 21b: books and memories ------------------------------------------------------------------------
# The world owner's showcase — its badges (on every trophy shelf) and its Hub Tree's state — goes from the host to
# each guest when it joins and whenever it changes (a new badge, a boss, a page, a universe): one small reliable
# RPC, cleaned on the guest (BooksDirector.clean_showcase). Everything else about the books stays on each child's
# own game (the profile; the Memory Book on the device).

## A guest's game: the host's showcase {badges, tree} arrived.
signal books_showcase_received(data: Dictionary)

const BOOKS_MAX_BADGES := 64


## Host: the showcase to every guest.
func books_share_showcase(data: Dictionary) -> void:
	if is_host() and multiplayer.multiplayer_peer != null and not multiplayer.get_peers().is_empty():
		_rpc_books_showcase.rpc(_books_payload(data))


## Host: the showcase to one guest (it just joined).
func books_send_showcase(peer_id: int, data: Dictionary) -> void:
	if is_host() and multiplayer.get_peers().has(peer_id):
		_rpc_books_showcase.rpc_id(peer_id, _books_payload(data))


static func _books_payload(data: Dictionary) -> Dictionary:
	var badges: Array = (data.get("badges", []) as Array).slice(0, BOOKS_MAX_BADGES)
	return {"badges": badges, "tree": data.get("tree", {})}


@rpc("authority", "call_remote", "reliable")
func _rpc_books_showcase(data: Dictionary) -> void:
	books_showcase_received.emit(BooksDirector.clean_showcase(data))

# --- Owner #36: costumes ---------------------------------------------------------------------------------------
# While a world is played, whatever this game's player does may finish a costume's way (a story, a level, a title, a
# find: CostumeRules.sync reads the profile). The costume is given, with a message, within COSTUME_CHECK_S of it (a
# check costs ~0.1 ms here, ~0.4 ms on a phone: not every block placed), only for the profile's own progress (never a
# test's). A boss's costume comes with its win (boss_earn), the rest when the avatar editor opens. The host's profile is
# saved with its world; a guest saves at once.

const COSTUME_MESSAGE := "New costume: %s! Try it on in the avatar editor."
const COSTUME_CHECK_S := 0.5

var _costume_check_queued := false


func _costumes_ready() -> void:
	Progress.changed.connect(_queue_costume_check)


func _queue_costume_check() -> void:
	if _costume_check_queued or not is_inside_tree():
		return
	_costume_check_queued = true
	get_tree().create_timer(COSTUME_CHECK_S).timeout.connect(_costume_check)


func _costume_check() -> void:
	_costume_check_queued = false
	if not Progress.is_counting() or Progress.data() != Profile.data.progress:
		return
	var got := CostumeRules.sync(Profile.data)
	for id in got:
		var words := COSTUME_MESSAGE if AvatarCatalog.slot_of(id) == AvatarCatalog.COSTUME else EARNED_MESSAGE
		magic_feedback.emit(tr(words) % tr(AvatarCatalog.display_name(id)))   # M3 Task 21a: in the game's language
	if not got.is_empty() and not is_host():
		Profile.save()


# --- M3 Task 20b: buddy magic ---------------------------------------------------------------------------------
# A wand tap on a calm monster asks the host to befriend it (request_befriend -> befriend_requested: the sandbox's
# BuddyMagicDirector decides, BefriendRules). A child's bosses' mini-buddies come along from their profile like Pip
# (request_mini -> mini_requested), and the tricks Pip or the baby dragon learned come back to the host
# (request_pet_tricks -> pet_tricks_requested). The host tells ONE player's own game what its profile keeps
# (buddy_magic_tell -> buddy_magic_told: a buddy it woke for the album and the secret shapes, a mini earned, a trick
# a profile pet learned). Emotes reach the director through emote_played (M3 Task 9).

## Host only: `peer_id` tapped the monster `monster_name` with the Magic Wand.
signal befriend_requested(peer_id: int, monster_name: String)
## Host only: `peer_id` brings their mini-buddy of `boss_kind` (their profile's record and its tricks).
signal mini_requested(peer_id: int, boss_kind: StringName, record: Dictionary, tricks: Array)
## Host only: `peer_id` sends back the tricks their profile pet `animal_name` learned before.
signal pet_tricks_requested(peer_id: int, animal_name: String, tricks: Array)
## This game: the host told it something for its own profile (BuddyMagicDirector.WOKEN, MINI, TRICK).
signal buddy_magic_told(kind: StringName, info: Dictionary)

const T20B_NAME_MAX := 64         # longer names are cut before the checks
const T20B_TRICKS_MAX := 16


func request_befriend(monster_name: String) -> void:
	if is_host():
		befriend_requested.emit(multiplayer.get_unique_id(), monster_name.substr(0, T20B_NAME_MAX))
	else:
		_rpc_t20b_befriend.rpc_id(1, monster_name.substr(0, T20B_NAME_MAX))


func request_mini(boss_kind: StringName, record: Dictionary, tricks: Array) -> void:
	if not MiniRules.gives_mini(boss_kind):
		return
	var clean := PetRules.clean_pip(record)
	var list := TrickRules.clean(tricks)
	if is_host():
		mini_requested.emit(multiplayer.get_unique_id(), boss_kind, clean, list)
	else:
		_rpc_t20b_mini.rpc_id(1, String(boss_kind), clean, list)


func request_pet_tricks(animal_name: String, tricks: Array) -> void:
	var list := TrickRules.clean(tricks)
	if is_host():
		pet_tricks_requested.emit(multiplayer.get_unique_id(), animal_name.substr(0, T20B_NAME_MAX), list)
	else:
		_rpc_t20b_pet_tricks.rpc_id(1, animal_name.substr(0, T20B_NAME_MAX), list)


## Host: tells `peer_id`'s own game something for its profile (this game's own player: here and now).
func buddy_magic_tell(peer_id: int, kind: StringName, info: Dictionary) -> void:
	if not is_host():
		return
	if peer_id == multiplayer.get_unique_id():
		buddy_magic_told.emit(kind, info)
	elif multiplayer.get_peers().has(peer_id):
		_rpc_t20b_told.rpc_id(peer_id, String(kind), info)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_t20b_befriend(monster_name: String) -> void:
	if is_host():
		befriend_requested.emit(multiplayer.get_remote_sender_id(), monster_name.substr(0, T20B_NAME_MAX))


@rpc("any_peer", "call_remote", "reliable")
func _rpc_t20b_mini(boss_kind: String, record: Dictionary, tricks: Array) -> void:
	if is_host() and MiniRules.gives_mini(StringName(boss_kind)):
		mini_requested.emit(multiplayer.get_remote_sender_id(), StringName(boss_kind), PetRules.clean_pip(record),
			TrickRules.clean(tricks.slice(0, T20B_TRICKS_MAX)))


@rpc("any_peer", "call_remote", "reliable")
func _rpc_t20b_pet_tricks(animal_name: String, tricks: Array) -> void:
	if is_host():
		pet_tricks_requested.emit(multiplayer.get_remote_sender_id(), animal_name.substr(0, T20B_NAME_MAX),
			TrickRules.clean(tricks.slice(0, T20B_TRICKS_MAX)))


@rpc("authority", "call_remote", "reliable")
func _rpc_t20b_told(kind: String, info: Dictionary) -> void:
	if kind in [String(BuddyMagicDirector.WOKEN), String(BuddyMagicDirector.MINI), String(BuddyMagicDirector.TRICK)]:
		buddy_magic_told.emit(StringName(kind), info)


# --- M3 Task 21c: the Tiny world and waking more things ---------------------------------------------------------------
# The Magic Wand on an opened treasure chest wakes it as a chest mimic: the host's TinyDirector (node "Secrets/Tiny" on
# every peer) checks the reach, that the chest is open and hasn't given its present yet, and wakes it (it hops after the
# child, giggles and gives a small present; never harmful). Mouse villages need no request: walking in finds them.

## Host only: a player tapped the opened chest `chest_name` (a SecretThing's name) with the wand.
signal tiny_wake_chest_requested(peer_id: int, chest_name: String)


func request_wake_chest(chest_name: String) -> void:
	if is_host():
		tiny_wake_chest_requested.emit(multiplayer.get_unique_id(), chest_name)
	else:
		_rpc_tiny_wake_chest.rpc_id(1, chest_name)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_tiny_wake_chest(chest_name: String) -> void:
	if is_host():
		tiny_wake_chest_requested.emit(multiplayer.get_remote_sender_id(), chest_name.left(96))


# --- Trading --------------------------------------------------------------------------------------------------
# Owner #37 (spec §14.23): trading between players, LAN and online, and Nico's market-day things. The host decides
# everything: a player asks another (never a bot: bots are not players) and nothing opens without that player's
# YES; both put things in (each offer is cleaned by TradeRules and held to what its owner still has, looked at
# again every PT_RECHECK_MS); every change makes both not ready; when both are READY the host swaps at once, all or
# nothing (TradeRules.swap_check against the real bags and purses, then the gold through gold_spend / gold_add, which
# the online server's ledger hears, then the things). Nothing leaves a bag before the swap, so X, a player leaving
# (or dropping their link) or the world ending stops a trade with nothing lost or copied. Online, under-13 players
# trade only with players on their own friends list (each game tells the host its friends' user ids); the bands
# are the chat's registered ones. Both traders get a chat line. Survivor worlds only.

## This game: another player asks to trade (their peer id and name): YES / NO THANKS answer it.
signal player_trade_asked(peer_id: int, from_name: String)
## This game: an ask to this player went away (its asker took it back or left).
signal player_trade_ask_gone(peer_id: int)
## This game: its open trade as the host sees it (TradeTable.state_for), after every change.
signal player_trade_changed(state: Dictionary)
## This game: its trade ended (done: swapped), with the words to show.
signal player_trade_ended(done: bool, text: String)
## This game: a short line from the host about trading ("Waiting for an answer...", a refusal).
signal player_trade_note(text: String)

const PT_RECHECK_MS := 250
const PT_FRIENDS_MAX := 1000
const PT_UNKNOWN := "That player"

## Host: the asks and open trades.
var trade_table := TradeTable.new()
## Tests: (peer, kind, args) for every trade message the host sends another game.
var trade_tap: Callable
## (peer) -> String: a player's online user id ("" unknown). Tests set their own.
var trade_user_of: Callable = _f_user_of
## () -> bool: this world is played online (the under-13 friends rule). Tests set their own.
var trade_online: Callable = is_online
var trade_now_ms: Callable = Time.get_ticks_msec
var _pt_friends := {}      # host: peer -> Array[String] of the user ids on that player's friends list
var _pt_checked_ms := 0


func _pt_ready() -> void:
	peer_left.connect(_pt_on_peer_left)
	peer_away.connect(_pt_on_peer_left)   # M4 A: a guest whose link dropped stops trading too


## Forgets every ask, trade and friend list (leaving a game, tests).
func _pt_reset() -> void:
	trade_table.clear()
	_pt_friends.clear()


## Tests: the default hooks again, and nothing open.
func trade_reset_hooks() -> void:
	trade_tap = Callable()
	trade_user_of = _f_user_of
	trade_online = is_online
	trade_now_ms = Time.get_ticks_msec
	_pt_reset()


# This game's requests (the host decides) -----------------------------------------------------------------------

func player_trade_ask(target: int) -> void:
	if is_host():
		host_trade_ask(multiplayer.get_unique_id(), target)
	else:
		_rpc_pt_ask.rpc_id(1, target)


func player_trade_answer(asker: int, yes: bool) -> void:
	if is_host():
		host_trade_answer(multiplayer.get_unique_id(), asker, yes)
	else:
		_rpc_pt_answer.rpc_id(1, asker, yes)


## Takes back this player's ask.
func player_trade_unask() -> void:
	if is_host():
		host_trade_unask(multiplayer.get_unique_id())
	else:
		_rpc_pt_unask.rpc_id(1)


## This player's side of their trade: [[id, count], ...] and gold.
func player_trade_offer(items: Array, gold: int) -> void:
	if is_host():
		host_trade_offer(multiplayer.get_unique_id(), items, gold)
	else:
		_rpc_pt_offer.rpc_id(1, items, gold)


func player_trade_ready(on: bool) -> void:
	if is_host():
		host_trade_ready(multiplayer.get_unique_id(), on)
	else:
		_rpc_pt_ready.rpc_id(1, on)


func player_trade_cancel() -> void:
	if is_host():
		host_trade_cancel(multiplayer.get_unique_id())
	else:
		_rpc_pt_cancel.rpc_id(1)


## This player's friends' online user ids (for the under-13 rule).
func player_trade_friends(ids: Array) -> void:
	if is_host():
		host_trade_friends(multiplayer.get_unique_id(), ids)
	else:
		_rpc_pt_friends.rpc_id(1, ids)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pt_ask(target: int) -> void:
	if is_host():
		host_trade_ask(multiplayer.get_remote_sender_id(), target)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pt_answer(asker: int, yes: bool) -> void:
	if is_host():
		host_trade_answer(multiplayer.get_remote_sender_id(), asker, yes)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pt_unask() -> void:
	if is_host():
		host_trade_unask(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pt_offer(items: Array, gold: int) -> void:
	if is_host():
		host_trade_offer(multiplayer.get_remote_sender_id(), items.slice(0, TradeRules.MAX_KINDS * 4), gold)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pt_ready(on: bool) -> void:
	if is_host():
		host_trade_ready(multiplayer.get_remote_sender_id(), on)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pt_cancel() -> void:
	if is_host():
		host_trade_cancel(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pt_friends(ids: Array) -> void:
	if is_host():
		host_trade_friends(multiplayer.get_remote_sender_id(), ids.slice(0, PT_FRIENDS_MAX))


# The host ---------------------------------------------------------------------------------------------------

## Why `peer` may not trade with `target` now ("" = they may): TradeRules.MESSAGES keys.
func _pt_refusal(peer: int, target: int) -> String:
	if not TraderRules.wants_trader(Game.mode) or Game.allows(ModeRules.INFINITE_GOLD):
		return "survivor_only"
	if peer == target:
		return "self"
	if _player_for_peer(peer) == null or _player_for_peer(target) == null:
		return "gone"
	return TradeRules.age_refusal(AgeBand.effective(_chat_bands.get(peer, AgeBand.unknown())), AgeBand.effective(_chat_bands.get(target, AgeBand.unknown())),
		_pt_lists(peer, target), _pt_lists(target, peer), bool(trade_online.call()))


## `b` is on `a`'s friends list (as `a`'s game said).
func _pt_lists(a: int, b: int) -> bool:
	var uid := str(trade_user_of.call(b))
	return uid != "" and (_pt_friends.get(a, []) as Array).has(uid)


func _pt_name(peer: int) -> String:
	return str(chat_names.get(peer, tr(PT_UNKNOWN)))


func host_trade_ask(peer: int, target: int) -> void:
	var why := _pt_refusal(peer, target)
	if why == "":
		var r := trade_table.ask(peer, target, int(trade_now_ms.call()))
		why = r.error
		if why == "":
			if int(r.dropped) != 0:
				_pt_send(int(r.dropped), &"ask_gone", [peer])
			_pt_send(target, &"asked", [peer, _pt_name(peer)])
			_pt_send(peer, &"note", [TradeRules.message("asked", _pt_name(target))])
			return
	_pt_send(peer, &"note", [TradeRules.message(why, _pt_name(target))])


func host_trade_answer(peer: int, asker: int, yes: bool) -> void:
	if asker == 0 or trade_table.asker_of(peer) != asker:
		return   # nobody asked, or an answer that came too late
	if not yes:
		trade_table.answer(peer, asker, false)
		_pt_send(asker, &"note", [TradeRules.message("said_no", _pt_name(peer))])
		return
	var why := _pt_refusal(asker, peer)
	if why != "":
		trade_table.answer(peer, asker, false)
		_pt_send(asker, &"note", [TradeRules.message(why, _pt_name(peer))])
		_pt_send(peer, &"note", [TradeRules.message(why, _pt_name(asker))])
		return
	var dropped := trade_table.unask(peer)   # the child saying YES had asked someone else: that ask goes
	if dropped != 0:
		_pt_send(dropped, &"ask_gone", [peer])
	var t := trade_table.answer(peer, asker, true)
	if t.is_empty():
		_pt_send(peer, &"note", [TradeRules.message("busy", _pt_name(asker))])
		return
	_pt_send_state(t)


func host_trade_unask(peer: int) -> void:
	var target := trade_table.unask(peer)
	if target != 0:
		_pt_send(target, &"ask_gone", [peer])


func host_trade_offer(peer: int, items: Array, gold: int) -> void:
	var t := trade_table.trade_of(peer)
	if t.is_empty():
		return
	var offer := TradeRules.clean_offer(items, gold, Game.universe)
	trade_table.set_offer(peer, TradeRules.covered(offer, inventory_of(peer), gold_of(peer)))
	_pt_send_state(t)


func host_trade_ready(peer: int, on: bool) -> void:
	var t := trade_table.set_ready(peer, on)
	if t.is_empty():
		return
	if trade_table.both_ready(t):
		_pt_swap(t)
	else:
		_pt_send_state(t)


func host_trade_cancel(peer: int) -> void:
	var t := trade_table.trade_of(peer)
	if t.is_empty():
		host_trade_unask(peer)
		return
	trade_table.close(t)
	for p: int in [int(t.a), int(t.b)]:
		_pt_send(p, &"ended", [false, TradeRules.message("stopped")])


func host_trade_friends(peer: int, ids: Array) -> void:
	var clean: Array[String] = []
	for v: Variant in ids:
		if v is String and (v as String).length() <= 128 and clean.size() < PT_FRIENDS_MAX:
			clean.append(v)
	_pt_friends[peer] = clean


## Both are ready: the swap, all or nothing, against the real bags and purses.
func _pt_swap(t: Dictionary) -> void:
	var a := int(t.a)
	var b := int(t.b)
	var oa: Dictionary = t.offers[a]
	var ob: Dictionary = t.offers[b]
	var ia := inventory_of(a)
	var ib := inventory_of(b)
	var why := TradeRules.swap_check(ia, gold_of(a), oa, ib, gold_of(b), ob)
	if why.error == "" and (_player_for_peer(a) == null or _player_for_peer(b) == null):
		why = {"error": "gone", "side": 0 if _player_for_peer(a) == null else 1, "id": -1}
	if why.error == "" and int(oa.gold) > 0 and not gold_spend(a, int(oa.gold)):
		why = {"error": "not_owned", "side": 0, "id": -1}
	if why.error == "" and int(ob.gold) > 0 and not gold_spend(b, int(ob.gold)):
		gold_add(a, int(oa.gold), "trade")   # a's gold back: nothing moves
		why = {"error": "not_owned", "side": 1, "id": -1}
	if why.error != "":
		trade_table.unready(t)
		var about := a if int(why.side) == 0 else b
		for p: int in [a, b]:
			_pt_send(p, &"note", [_pt_why(why, about, p)])
		_pt_send_state(t)
		return
	TradeRules.move_items(ia, oa.items, ib, ob.items)
	gold_add(b, int(oa.gold), "trade")
	gold_add(a, int(ob.gold), "trade")
	trade_table.close(t)
	for side: Array in [[a, b, oa, ob], [b, a, ob, oa]]:
		_pt_send(int(side[0]), &"ended", [true, TradeRules.message("done")])
		_pt_line(int(side[0]), TradeRules.log_line(_pt_name(int(side[1])), side[2], side[3]))


## Host -> a trader: the trade's line in their chat history (only to a game that is there).
func _pt_line(peer: int, text: String) -> void:
	if trade_tap.is_valid() and peer != multiplayer.get_unique_id():
		trade_tap.call(peer, &"line", [text])
	if peer == multiplayer.get_unique_id() or multiplayer.get_peers().has(peer):
		send_chat_line(peer, text)


## The words for a refused swap, to `p`: about themselves ("Your bag has no room ...") or the other one.
func _pt_why(why: Dictionary, about: int, p: int) -> String:
	var key := str(why.error)
	if about == p and key in ["not_owned", "no_room"]:
		return TradeRules.message(key + "_you", "", int(why.id))
	return TradeRules.message(key, _pt_name(about), int(why.id))


## Host, from _physics_process: every PT_RECHECK_MS the open offers are held to what their owners still have (a
## block placed, a knock-out's bag): a changed offer makes both not ready.
func _pt_tick() -> void:
	var now := int(trade_now_ms.call())
	if trade_table.trades.is_empty() or now - _pt_checked_ms < PT_RECHECK_MS:
		return
	_pt_checked_ms = now
	player_trade_tick()


## Host: one look at the open offers (tests call it directly).
func player_trade_tick() -> void:
	for id: int in trade_table.trades.keys():
		var t: Dictionary = trade_table.trades[id]
		var changed := false
		for p: int in [int(t.a), int(t.b)]:
			var c := TradeRules.covered(t.offers[p], inventory_of(p), gold_of(p))
			if not TradeRules.same(c, t.offers[p]):
				t.offers[p] = c
				changed = true
				_pt_send(p, &"note", [TradeRules.message("changed")])
		if changed:
			trade_table.unready(t)
			_pt_send_state(t)


func _pt_on_peer_left(peer: int) -> void:
	if not is_host():
		return
	var gone := trade_table.forget(peer)
	_pt_friends.erase(peer)
	var trade: Dictionary = gone.trade
	if not trade.is_empty():
		_pt_send(TradeTable.other(trade, peer), &"ended", [false, TradeRules.message("left", _pt_name(peer))])
	if int(gone.asked) != 0:
		_pt_send(int(gone.asked), &"ask_gone", [peer])
	if int(gone.asker) != 0:
		_pt_send(int(gone.asker), &"note", [TradeRules.message("gone", _pt_name(peer))])


func _pt_send_state(t: Dictionary) -> void:
	for p: int in [int(t.a), int(t.b)]:
		_pt_send(p, &"state", [trade_table.state_for(t, p, _pt_name(TradeTable.other(t, p)))])


## Host -> one game (itself included).
func _pt_send(peer: int, kind: StringName, args: Array) -> void:
	if peer == multiplayer.get_unique_id():
		_pt_receive(kind, args)
		return
	if trade_tap.is_valid():
		trade_tap.call(peer, kind, args)
	if multiplayer.get_peers().has(peer):
		_rpc_pt_to.rpc_id(peer, String(kind), args)


@rpc("authority", "call_remote", "reliable")
func _rpc_pt_to(kind: String, args: Array) -> void:
	_pt_receive(StringName(kind), args)


func _pt_receive(kind: StringName, args: Array) -> void:
	match kind:
		&"asked":
			player_trade_asked.emit(int(args[0]), str(args[1]))
		&"ask_gone":
			player_trade_ask_gone.emit(int(args[0]))
		&"state":
			player_trade_changed.emit(args[0] as Dictionary if args[0] is Dictionary else {})
		&"ended":
			player_trade_ended.emit(bool(args[0]), str(args[1]))
		&"note":
			player_trade_note.emit(str(args[0]))


# Nico's market (Tilly's trades, M2 Task 7's host_trade) ----------------------------------------------------------

## Host: Nico's cart stands near `peer` (the cart is a trader in the group "market_traders" only while the market
## is open) and sells `id`.
func _pt_market_sells(peer: int, id: int) -> bool:
	if not MarketRules.sells(id):
		return false
	var p := _player_for_peer(peer)
	if p == null:
		return false
	for n in get_tree().get_nodes_in_group(&"market_traders"):
		if n is Node3D and TraderRules.in_reach(p.eye_position(), (n as Node3D).global_position, TraderRules.HOST_REACH):
			return true
	return false


## Host: one of Nico's things for `peer` (MarketRules: the gold through gold_spend, the blocks into their bag).
func _pt_market_buy(peer: int, id: int) -> Dictionary:
	var inv := inventory_of(peer)
	var result := MarketRules.buy(id, Wallet.new(gold_of(peer)), inv, Game.universe)
	if result.ok and not gold_spend(peer, int(result.gold)):
		inv.take(id, int(result.count))
		result = {"ok": false, "error": "gold", "gold": 0, "id": id, "count": 0}
	return result

# --- Safety in the world (spec §17.3, the M4 Task 10 review's finding A) ----------------------------------------------
# The host takes a player out of its world from their name tag's card (REMOVE). The guest's game is told first (an
# RPC), so it goes to the menu with kind words and never tries to rejoin; online the server then takes them out of the
# relayed match and off the invite list (remove_guest; its notification 107 also reaches the guest's game), on LAN the
# host drops their connection. Nothing of the guest's is taken.

var _removed_peers := {}   # host: peers it removed (their leave is final: no waiting for a rejoin)


## Host: takes `peer_id` out of this world. "" or plain words ("?": no such guest here, or not the host).
func host_remove_guest(peer_id: int) -> String:
	if not is_host() or peer_id == multiplayer.get_unique_id() or not multiplayer.get_peers().has(peer_id):
		return "?"
	_removed_peers[peer_id] = true
	if not is_online():
		_lan_remember_removed(peer_id)   # M5 Task 6 review: they can't come straight back
	_rpc_removed.rpc_id(peer_id)
	if is_online():
		var user := _f_user_of(peer_id)
		var match_id := online_hosted_match()
		if user == "" or match_id == "" or online_service_or_null() == null:
			return NetWords.text(NetWords.UNKNOWN)
		var err: String = await online_service_or_null().remove_guest(user, match_id)
		if err != "":
			return err
		print("ONLINE the host removed guest %d" % peer_id)
		return ""
	await get_tree().create_timer(0.3).timeout   # LAN: the RPC goes first, then the connection
	var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if enet != null and multiplayer.get_peers().has(peer_id):
		enet.disconnect_peer(peer_id)
	print("LAN the host removed guest %d" % peer_id)
	return ""


## Guest: the host removed this player (only the host may call it).
@rpc("authority", "call_remote", "reliable")
func _rpc_removed() -> void:
	if not multiplayer.is_server():
		_leave_removed()


## The server's notification 107: only for the match this game is in as a guest.
func _on_removed_from_world(match_id: String) -> void:
	if _link == null or multiplayer.is_server() or _link.match_id() != match_id:
		return
	_leave_removed()


# M5 Task 6 review: online the server strikes a removed player off the invite list; on LAN nothing stopped them from
# joining again at once, so REMOVE meant nothing there. The LAN host remembers where a removed player's game connected
# from (its address on the Wi-Fi) and, for as long as it hosts, turns a new connection from there away the same way
# (the kind words, then the connection drops); nothing it sends (hello, ready) is heard meanwhile.

var _lan_removed := {}   # LAN host: addresses of players it removed (cleared by the next host_lan)
var _lan_refused := {}   # LAN host: peers being turned away


## The address `peer_id`'s game connected from ("" when not a LAN peer).
func _lan_address(peer_id: int) -> String:
	var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if enet == null or not multiplayer.is_server():
		return ""
	var link := enet.get_peer(peer_id)
	return link.get_remote_address() if link != null else ""


func _lan_remember_removed(peer_id: int) -> void:
	var address := _lan_address(peer_id)
	if address != "":
		_lan_removed[address] = true


## A new connection from a removed player's address: the kind words, then the connection goes. True when turned away.
func _lan_turn_away(peer_id: int) -> bool:
	if _lan_removed.is_empty() or not _lan_removed.has(_lan_address(peer_id)):
		return false
	_lan_refused[peer_id] = true
	_rpc_removed.rpc_id(peer_id)
	get_tree().create_timer(0.3).timeout.connect(func() -> void:
		var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
		if enet != null and multiplayer.get_peers().has(peer_id):
			enet.disconnect_peer(peer_id))
	print("LAN the host turned away a removed player (peer %d)" % peer_id)
	return true


## Back to the menu with the host's words; never a rejoin.
func _leave_removed() -> void:
	print("ONLINE removed by the host")
	_rejoin = RejoinRules.new()
	_a_notice(NetWords.REMOVED)
	if _link != null:
		_online_close()
	elif multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()   # no closed connection left behind
	disconnected.emit()


# --- Crew flights (spec §21d.6 phase 2; owner #78, #79) ---------------------------------------------------------------
# Friends in a shared world fly the rocket together (CrewFlights, node "Crew" in the sandbox, has the flow; CrewCall and
# CrewFlightRules the rules). Here: the crew's messages, and the host's world moving with its crew. LAUNCH with friends
# here calls them (crew_call -> their card; crew_answer back); the crew boards (crew_board: the rocket, the seats) and
# flies the pilot's flight (crew_state, a few times a second); the others are left behind with kind words (crew_leave).
# Landed (or HOME), the host's world moves: crew_move tells every guest, then the host changes worlds WITHOUT closing
# the session (the match or the LAN server goes on) and holds every hello until its new world stands (crew_world_ready).
# Each guest leaves the link (crew_follow_leave), loads a fresh guest scene and joins the same match (or LAN host)
# again: the ordinary join, into the host's new world (its universe, seed and spawn). A crew member arriving there is
# welcomed (crew_welcome): its own profile flies the mission and keeps the crew badge.

signal crew_called(pilot: String, destination: int, seconds: float)
signal crew_answered(peer_id: int, take: bool)
signal crew_boarded(rocket: Dictionary, seat: int, crew: Array)
signal crew_left_behind(words: String)
signal crew_cancelled(words: String)
signal crew_noted(words: String)
signal crew_state_received(state: Dictionary)
signal crew_waved(peer_id: int)
signal crew_moved(universe: int, home: bool, flew: bool)
signal crew_welcomed(universe: int, mates: Array)
## Owner #95: signed in again by itself after an offline spell: what was played offline is on the account now.
signal back_online
## Host: a guest that followed stands in the new world; it was `token` (its peer id) in the crew.
signal crew_arrival(peer_id: int, token: int)

var _crew_moving := false          # host: its world is moving with the crew (hellos wait)
var _crew_held: Array[int] = []    # host: guests whose hello waits for the new world
var _crew_follow_until := 0.0      # guest: following the host into its new world until then (seconds; 0: not)


## Host -> a guest: the call's card ("Anna is launching to the Moon! Take your seat.").
func crew_call(peer_id: int, pilot: String, destination: int, seconds: float) -> void:
	_rpc_crew_call.rpc_id(peer_id, pilot, destination, seconds)


## Guest -> host: TAKE MY SEAT (true) or STAY HERE.
func crew_answer(take: bool) -> void:
	if not is_host():
		_rpc_crew_answer.rpc_id(1, take)


## Host -> a crew member: the rocket (RocketCheck.description with its "origin"), its seat, the crew
## ([{peer, name, look, seat}], the pilot first).
func crew_board(peer_id: int, rocket: Dictionary, seat: int, crew: Array) -> void:
	_rpc_crew_board.rpc_id(peer_id, rocket, seat, crew)


## Host -> a friend who does not fly: the world flies away (the words say why).
func crew_leave(peer_id: int, words: String) -> void:
	_rpc_crew_leave.rpc_id(peer_id, words)


## Host -> a friend: the launch waits (the call is over).
func crew_cancel(peer_id: int, words: String) -> void:
	_rpc_crew_cancel.rpc_id(peer_id, words)


## Host -> a friend: words on its card while the call waits (the pilot is choosing).
func crew_note(peer_id: int, words: String) -> void:
	_rpc_crew_note.rpc_id(peer_id, words)


## Host -> a crew member: the pilot's flight now (RocketFlight.crew_state).
func crew_state(peer_id: int, state: Dictionary) -> void:
	_rpc_crew_state.rpc_id(peer_id, state)


## A crew member waves from their seat: the host tells everyone (itself too).
func crew_wave() -> void:
	if is_host():
		_crew_waved_all(multiplayer.get_unique_id())
	else:
		_rpc_crew_wave.rpc_id(1)


## Host: its world moves to `universe` (a landing, or HOME) and every guest follows (flew: the peers who flew in the
## crew). Hellos wait until crew_world_ready.
func crew_move(universe: int, home: bool, flew: Array[int]) -> void:
	if not is_host():
		return
	_crew_moving = true
	_crew_held.clear()
	_pt_reset()   # no ask or trade outlives its world
	for id in multiplayer.get_peers():
		_rpc_crew_move.rpc_id(id, universe, home, flew.has(id))
	print("CREW move to %d (%s) with %d guests at %d ms" % [universe, "home" if home else "landing",
		multiplayer.get_peers().size(), Time.get_ticks_msec()])


## Host: waits (at most `max_seconds`) until every guest has let go of the world it leaves (crew_follow_leave), so
## no guest's last word is meant for a node of the old world.
func crew_guests_gone(max_seconds: float) -> void:
	var from := Time.get_ticks_msec()
	var until := from + int(max_seconds * 1000.0)
	while not multiplayer.get_peers().is_empty() and Time.get_ticks_msec() < until and is_inside_tree():
		await get_tree().process_frame
	print("CREW guests let go in %d ms (%d still here)" % [Time.get_ticks_msec() - from, multiplayer.get_peers().size()])


## Host: the world is moving with its crew (its next world keeps hosting the same match or LAN game).
func crew_moving() -> bool:
	return _crew_moving


## Host: a guest's hello while the world moves waits for the new world (true: held).
func crew_hold_hello(peer_id: int) -> bool:
	if not _crew_moving:
		return false
	if not _crew_held.has(peer_id):
		_crew_held.append(peer_id)
	return true


## Host: the new world stands (its seed and the host's spawn are set): the held hellos are answered.
func crew_world_ready() -> void:
	if not _crew_moving:
		return
	_crew_moving = false
	var held := _crew_held.duplicate()
	_crew_held.clear()
	for id in held:
		if multiplayer.get_peers().has(id):
			_answer_hello(id)
	print("CREW world ready: %d hellos answered at %d ms" % [held.size(), Time.get_ticks_msec()])


## Host -> a crew member in the destination world: its mission counts (mates: the other crew members' names).
func crew_welcome(peer_id: int, universe: int, mates: Array) -> void:
	_rpc_crew_welcome.rpc_id(peer_id, universe, mates)


## Guest -> host: it followed the host's world and stands in it; `token`: its peer id in the crew (LAN gives new ids).
func crew_arrived(token: int) -> void:
	if not is_host():
		_rpc_crew_arrived.rpc_id(1, token)


## Guest: leaves the link without a word to the scene (the match or the LAN host goes on); the next guest scene joins it
## again (online_config and Game.join_address are kept). For CrewFlightRules.FOLLOW_SECONDS it is "following".
func crew_follow_leave() -> void:
	_crew_follow_until = Time.get_ticks_msec() / 1000.0 + CrewFlightRules.FOLLOW_SECONDS
	world = null
	if _link != null:
		_a_drop_link()   # (a waiting peer: never taken for the host meanwhile)
	elif multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	print("CREW following the host into its new world at %d ms" % Time.get_ticks_msec())


## Guest: following the host into its new world (and how long it may still take).
func crew_following() -> bool:
	return _crew_follow_until > 0.0


func crew_follow_seconds_left() -> float:
	return maxf(_crew_follow_until - Time.get_ticks_msec() / 1000.0, 0.0) if crew_following() else 0.0


## Guest: it stands in the host's new world (or gave up): no longer following.
func crew_follow_done() -> void:
	_crew_follow_until = 0.0


## Forgets every crew move and follow (the session closed, tests).
func crew_reset() -> void:
	_crew_moving = false
	_crew_held.clear()
	_crew_follow_until = 0.0


@rpc("authority", "call_remote", "reliable")
func _rpc_crew_call(pilot: String, destination: int, seconds: float) -> void:
	crew_called.emit(pilot, destination, seconds)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_crew_answer(take: bool) -> void:
	if is_host():
		crew_answered.emit(multiplayer.get_remote_sender_id(), take)


@rpc("authority", "call_remote", "reliable")
func _rpc_crew_board(rocket: Dictionary, seat: int, crew: Array) -> void:
	crew_boarded.emit(rocket, seat, crew)


@rpc("authority", "call_remote", "reliable")
func _rpc_crew_leave(words: String) -> void:
	crew_left_behind.emit(words)


@rpc("authority", "call_remote", "reliable")
func _rpc_crew_cancel(words: String) -> void:
	crew_cancelled.emit(words)


@rpc("authority", "call_remote", "reliable")
func _rpc_crew_note(words: String) -> void:
	crew_noted.emit(words)


@rpc("authority", "call_remote", "reliable")
func _rpc_crew_state(state: Dictionary) -> void:
	crew_state_received.emit(state)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_crew_wave() -> void:
	if is_host():
		_crew_waved_all(multiplayer.get_remote_sender_id())


func _crew_waved_all(peer_id: int) -> void:
	crew_waved.emit(peer_id)
	for id in multiplayer.get_peers():
		_rpc_crew_waved.rpc_id(id, peer_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_crew_waved(peer_id: int) -> void:
	crew_waved.emit(peer_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_crew_move(universe: int, home: bool, flew: bool) -> void:
	crew_moved.emit(universe, home, flew)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_crew_arrived(token: int) -> void:
	if is_host():
		crew_arrival.emit(multiplayer.get_remote_sender_id(), token)


@rpc("authority", "call_remote", "reliable")
func _rpc_crew_welcome(universe: int, mates: Array) -> void:
	crew_welcomed.emit(universe, mates)
