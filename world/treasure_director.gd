class_name TreasureDirector
extends Node
## The treasure pack in a world (owner feedback #42, spec §12.16b). The SecretDirector adds one on every peer
## as its child "Treasures" (so its RPCs line up) and calls it from its own checks; it reuses the director's
## spawner, things, state and world access. Host:
## - brings the pack's own things near players (a haunted house's ghosts, a well's tap box, the pictures
##   over a vault's levers; chests and notes are the director's);
## - the vault's levers (M3 Task 7's smart blocks, flipped by taps): looked at 10 times a second next to an
##   unsolved vault; the right order opens the golden door and unlocks the legendary chest, a wrong lever
##   flips them all back ("Clunk!"). Levers already on when someone came near don't count;
## - the ghosts' riddles (Session.secret_answer_requested, names "ghost_…"): the right answer opens the
##   house's chest, once;
## - wishes (Session.secret_wish_requested): within reach, once per in-game day for each player, the day's
##   fixed gift, never gold;
## - the days (dawns, saved) and the rainbow: on the first morning and then about one in two, or after rain
##   (rain_ended) by day, a rainbow and its pot of gold near a player for RAINBOW_STAY; walking up to the pot
##   pays each player once per rainbow.
## Every peer: the coin's plop, the ghosts' giggles and sparkles (RPCs).

const LEVER_TELL := 24.0          # players this close to a vault hear its levers
const RAINBOW_TELL := 96.0        # players this close are told a rainbow came
const RAINBOW_WORDS := "Look! A rainbow! Find where it ends."

var secrets: SecretDirector
var _vaults_near: Array = []
var _lever_seen := {}             # vault id -> Array[bool]: its levers' on/off at the last look
var _lever_progress := {}         # vault id -> Array[int]: the levers flipped in the right order so far
var _tapper := {}                 # lever cell -> the peer who last tapped it (feedback goes to them)
## Cosmos (spec §21b.2): rainbows come only where it rains (not in the space worlds: the Moon, Mars, …).
var rainbows := true
var _last_phase := -1
var _rainbow_due := false
var _rainbow_n := 0               # the rainbow showing now (0: none)
var _rainbow_pot := Vector3i.ZERO
var _rainbow_left := 0.0


func _ready() -> void:
	Session.secret_answer_requested.connect(_on_answer_requested)
	Session.secret_wish_requested.connect(_on_wish_requested)
	Session.smart_tap_requested.connect(_on_smart_tap)


## The pack's own things of secret `s` near a player (the director checked the cap and the terrain).
func spawn_things(s: Dictionary) -> void:
	match s.kind:
		TreasurePlaces.HAUNTED:
			var ghosts: Array = s.ghosts
			for i in ghosts.size():
				var gname := "ghost_%s_%d" % [s.id, i]
				if secrets.thing(gname) == null:
					_spawn({"kind": "ghost", "id": gname, "secret": s.id, "pos": ghosts[i], "riddle": s.riddle, "index": i,
						"yaw": float(s.yaw)})
		TreasurePlaces.WELL:
			if secrets.thing("well_" + s.id) == null:
				_spawn({"kind": "well", "id": "well_" + s.id, "secret": s.id, "pos": Vector3(s.well) + Vector3(0.5, 0, 0.5)})
		TreasurePlaces.VAULT:
			if secrets.thing("levers_" + s.id) == null:
				_spawn({"kind": "levermarks", "id": "levers_" + s.id, "secret": s.id, "pos": Vector3(s.levers[0]),
					"levers": s.levers, "symbols": s.symbols, "side": s.side})


## The things only the pack spawns (the director's spawn function asks here first).
static func make_thing(kind: String) -> SecretThing:
	match kind:
		"ghost":
			return FriendlyGhost.new()
		"well":
			return WishingWell.new()
		"levermarks":
			return LeverMarks.new()
		"rainbow":
			return RainbowArch.new()
		"pot":
			return PotOfGold.new()
	return null


## A player's key for once-a-day and once-per-rainbow: their name (so a guest who comes back is the same
## player), or their peer id.
func player_key(peer: int) -> String:
	var n: Variant = Session.chat_names.get(peer)
	return str(n) if n != null and str(n) != "" else "peer%d" % peer


func _spawn(data: Dictionary) -> void:
	secrets._spawner.spawn(data)


# --- Host: the checks ------------------------------------------------------------------------------

## Every host tick (SecretDirector.host_tick): the days and the rainbow, the pots, the vaults near players.
func host_tick(delta: float, players: Array[Player]) -> void:
	_update_days(players)
	var vaults: Array = []
	for p in players:
		for s: Dictionary in secrets.rules.secrets_near(p.global_position, SecretDirector.SPAWN_RADIUS):
			if s.kind == TreasurePlaces.VAULT and not secrets.state.solved.has(s.id) and not vaults.has(s):
				vaults.append(s)
		_check_pot(p)
	_vaults_near = vaults
	if _rainbow_n != 0:
		_rainbow_left -= delta
		if _rainbow_left <= 0.0:
			_rainbow_fades()


## Ten times a second (SecretDirector.plate_tick): the levers of the vaults near players.
func lever_tick() -> void:
	for s: Dictionary in _vaults_near:
		if secrets.state.solved.has(s.id):
			continue
		var levers: Array = s.levers
		var seen: Array = _lever_seen.get(s.id, [])
		var now := _levers_now(levers)
		if seen.is_empty():
			_lever_seen[s.id] = now       # the first look: whatever is on already doesn't count
			continue
		for i in levers.size():
			if now[i] and not seen[i]:
				_pull(s, i)
				if secrets.state.solved.has(s.id):
					break
				now = _levers_now(levers)   # a wrong lever flipped them back
		_lever_seen[s.id] = _levers_now(levers)


func _levers_now(levers: Array) -> Array:
	var out: Array = []
	for cell: Vector3i in levers:
		out.append(int(secrets.block_at.call(cell)) == BlockIds.LEVER_ON)
	return out


## Lever i of vault s was flipped on.
func _pull(s: Dictionary, i: int) -> void:
	var progress: Array[int] = _lever_progress.get(s.id, [] as Array[int])
	var r := SurpriseRules.press_plate(progress, i, s.order)
	_lever_progress[s.id] = r.progress
	var cell: Vector3i = s.levers[i]
	var peer := int(_tapper.get(cell, -1))
	match r.result:
		&"ok":
			_say(s, peer, tr("Click! %d of 3") % (r.progress as Array).size())
		&"wrong":
			var on := TreasureRules.levers_on(r.progress, (s.levers as Array).size())
			for k in on.size():
				secrets.set_block.call(s.levers[k], BlockIds.LEVER_ON if on[k] else BlockIds.LEVER)
			_say(s, peer, "Clunk! The levers flip back. Look at the note!")
			secrets._rpc_plate.rpc(Vector3(cell) + Vector3(0.5, 0.5, 0.5), false)
		&"solved":
			_open_vault(s, peer)


func _open_vault(s: Dictionary, peer: int) -> void:
	secrets.state.solved[s.id] = true
	for v: Vector3i in s.vault:
		secrets.set_block.call(v, BlockIds.AIR)
	var chest := secrets.thing("chest_" + s.id) as TreasureChest
	if chest:
		chest.locked = false
	var at := Vector3(s.vault[0]) + Vector3(0.5, 1.0, 0.5)
	secrets._rpc_poof.rpc(at, SecretDirector.SPARKLE)
	var finder := peer if Session._player_for_peer(peer) != null else _nearest_peer(at)
	for p in secrets._players():
		if p.peer_id == finder or p.global_position.distance_to(at) <= LEVER_TELL:
			secrets._tell(p.peer_id, &"_rpc_banner", ["The vault is open!", TreasureRules.VAULT_PICTURE])
	if finder >= 0 and not secrets.state.found.has(s.id):
		secrets._mark_found(s, finder)


## A line for the player who flipped the lever, else for everyone near the vault's hall.
func _say(s: Dictionary, peer: int, text: String) -> void:
	if Session._player_for_peer(peer) != null:
		Session.send_feedback(peer, text)
		return
	var hall := Vector3((s.levers as Array)[1])
	for p in secrets._players():
		if p.global_position.distance_to(hall) <= LEVER_TELL:
			Session.send_feedback(p.peer_id, text)


func _nearest_peer(at: Vector3) -> int:
	var best := -1
	var best_d := INF
	for p in secrets._players():
		var d := p.global_position.distance_to(at)
		if d < best_d:
			best_d = d
			best = p.peer_id
	return best


## Host (Session.smart_tap_requested, already checked): who flipped which lever, for the vaults' words.
func _on_smart_tap(peer: int, cell: Vector3i) -> void:
	_tapper[cell] = peer


# --- Host: the ghosts' riddles ---------------------------------------------------------------------

func _on_answer_requested(peer: int, visitor_name: String, choice: int) -> void:
	if not visitor_name.begins_with("ghost_") or not multiplayer.is_server() or secrets == null:
		return
	var ghost := secrets.thing(visitor_name) as FriendlyGhost
	var requester := Session._player_for_peer(peer)
	if ghost == null or requester == null:
		return
	if requester.global_position.distance_to(ghost.global_position) > SurpriseRules.WANDERER_REACH + PlacementRules.REACH_TOLERANCE:
		Session.send_feedback(peer, "Come closer to answer!")
		return
	var s := secrets.rules.find(ghost.secret_id)
	if s.is_empty():
		return
	if secrets.state.solved.has(s.id):
		Session.send_feedback(peer, "Hee hee! The chest is open already!")
		return
	if not TreasureRules.is_right_ghost_answer(ghost.riddle, choice):
		Session.send_feedback(peer, TreasureRules.GHOST_WRONG)
		_rpc_giggle.rpc(ghost.global_position + Vector3(0, 1, 0))
		return
	secrets.state.solved[s.id] = true
	var chest := secrets.thing("chest_" + s.id) as TreasureChest
	if chest:
		chest.locked = false
	Session.send_feedback(peer, TreasureRules.GHOST_RIGHT)
	_rpc_giggle.rpc(ghost.global_position + Vector3(0, 1, 0))
	secrets._rpc_poof.rpc(ghost.global_position + Vector3(0, 1, 0), Color("dff3ff"))
	if not secrets.state.found.has(s.id):
		secrets._mark_found(s, peer)


# --- Host: the wishing well ------------------------------------------------------------------------

func _on_wish_requested(peer: int, well_name: String) -> void:
	if not multiplayer.is_server() or secrets == null:
		return
	var well := secrets.thing(well_name) as WishingWell
	var requester := Session._player_for_peer(peer)
	if well == null or requester == null:
		return
	if not PlacementRules.in_reach(requester.eye_position(), well.cell(), PlacementRules.REACH + PlacementRules.REACH_TOLERANCE):
		Session.send_feedback(peer, "Too far away!")
		return
	var more := secrets.state.more
	var who := player_key(peer)
	var at := Vector3(well.cell()) + Vector3(0.5, 0.3, 0.5)
	_rpc_coin.rpc(at)
	if not TreasureRules.may_wish(more.wishes, who, more.dawns):
		Session.send_feedback(peer, TreasureRules.WISH_DONE)
		return
	TreasureRules.wish(more.wishes, who, more.dawns)
	var gift := TreasureRules.wish_gift(more.dawns)
	gift["title"] = TreasureRules.WISH_TEXT + " "
	gift["picture"] = TreasureRules.WELL_PICTURE
	secrets._give(peer, gift)
	Session.send_feedback(peer, TreasureRules.WISH_TEXT)
	var s := secrets.rules.find(well.secret_id)
	if not s.is_empty() and not secrets.state.found.has(s.id):
		secrets._mark_found(s, peer)


# --- Host: days and the rainbow --------------------------------------------------------------------

## A new day starts at dawn (or at sunrise when a sleeper skipped the dawn): the well's day turns and the
## morning may bring a rainbow, which shows once the day has begun.
func _update_days(players: Array[Player]) -> void:
	if not secrets.time_of_day.is_valid():
		return
	var phase := int(DayCycle.phase(float(secrets.time_of_day.call())))
	if _last_phase != -1 and phase != _last_phase:
		if phase == DayCycle.Phase.DAWN or (phase == DayCycle.Phase.DAY and _last_phase == DayCycle.Phase.NIGHT):
			secrets.state.more.dawns += 1
			_rainbow_due = _rainbow_due or TreasureRules.rainbow_at_dawn(secrets.world_seed, secrets.state.more.dawns)
	_last_phase = phase
	if _rainbow_due and phase == DayCycle.Phase.DAY and show_rainbow(players):
		_rainbow_due = false


## Weather hook: rain just stopped. A rainbow now if it is day (else at the next morning).
func rain_ended() -> void:
	var t: float = secrets.time_of_day.call() if secrets.time_of_day.is_valid() else DayCycle.NOON
	if not TreasureRules.rainbow_may_show(t) or not show_rainbow(secrets._players()):
		_rainbow_due = true


## /secret rainbow (a Sandbox cheat): a rainbow now, near the first player.
func rainbow_now() -> String:
	if not rainbows:
		return "No rainbow here: it never rains in this world."
	if _rainbow_n != 0:
		return "Look up! A rainbow is out already."
	return RAINBOW_WORDS if show_rainbow(secrets._players()) else "No rainbow here: try on dry land."


## A rainbow and its pot of gold near the first player. False when one shows already or there is no dry
## ground for its end.
func show_rainbow(players: Array[Player]) -> bool:
	if not rainbows or _rainbow_n != 0 or players.is_empty():
		return false
	var more := secrets.state.more
	var n := more.rainbows + 1
	var near := players[0].global_position
	var spot := TreasureRules.rainbow_spot(secrets.world_seed, n, near, secrets.ground_at)
	if spot.is_empty():
		return false
	more.rainbows = n
	_rainbow_n = n
	_rainbow_pot = spot.pot
	_rainbow_left = TreasureRules.RAINBOW_STAY
	var foot := Vector3(_rainbow_pot) + Vector3(0.5, 0, 0.5)
	_spawn({"kind": "rainbow", "id": "rainbow_%d" % n, "pos": foot, "yaw": float(spot.yaw)})
	_spawn({"kind": "pot", "id": "pot_%d" % n, "pos": foot, "n": n})
	_rpc_rainbow.rpc(foot)
	for p in players:
		if p.global_position.distance_to(foot) <= RAINBOW_TELL:
			Session.send_feedback(p.peer_id, RAINBOW_WORDS)
	secrets._bot_notice(foot, TreasureRules.notice_text(TreasurePlaces.RAINBOW))
	return true


func _check_pot(p: Player) -> void:
	if _rainbow_n == 0 or not TreasureRules.at_pot(p.global_position, _rainbow_pot):
		return
	if not secrets.state.more.take_pot(_rainbow_n, player_key(p.peer_id)):
		return
	var at := Vector3(_rainbow_pot) + Vector3(0.5, 0.8, 0.5)
	secrets._tell(p.peer_id, &"_rpc_found", [String(TreasurePlaces.RAINBOW), at])
	var loot := TreasureRules.pot_reward(Game.universe, secrets._survivor())
	loot["title"] = "A pot of gold! "
	loot["picture"] = TreasureRules.RAINBOW_PICTURE
	secrets._give(p.peer_id, loot)
	secrets._rpc_poof.rpc(at, SecretDirector.SPARKLE)


func _rainbow_fades() -> void:
	for thing_name in ["rainbow_%d" % _rainbow_n, "pot_%d" % _rainbow_n]:
		var t := secrets.thing(thing_name)
		if t:
			secrets._rpc_poof.rpc(t.global_position + Vector3(0, 0.5, 0), Color("fff3a8"))
			t.queue_free()
	_rainbow_n = 0


# --- Every peer: effects ---------------------------------------------------------------------------

@rpc("authority", "call_local", "unreliable")
func _rpc_coin(at: Vector3) -> void:
	Audio.play(&"coin_toss", at)
	Fx.burst(get_tree().root, at, Color("ffd23f"), 14, 2.5, 0.08, 0.7, 3.0)
	Fx.burst(get_tree().root, at + Vector3(0, -0.6, 0), Color("8fd3ff"), 12, 2.0, 0.08, 0.6, 5.0)


@rpc("authority", "call_local", "unreliable")
func _rpc_giggle(at: Vector3) -> void:
	Audio.play(&"giggle", at)
	Fx.burst(get_tree().root, at, Color("eaf2ff"), 10, 1.5, 0.08, 0.8, -0.5)


@rpc("authority", "call_local", "reliable")
func _rpc_rainbow(at: Vector3) -> void:
	Audio.play(&"rainbow")
	Fx.burst(get_tree().root, at + Vector3(0, 0.8, 0), Color("fff3a8"), 24, 3.0, 0.1, 1.2, 1.0)
