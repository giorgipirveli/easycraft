class_name WaveDirector
extends Node
## Monster Totem waves in a world (M2 Task 9, spec §12.8, §12.15; research G6). The sandbox adds one
## on every peer, always named "Waves", so its Totem spawner and RPCs line up across the network.
## Host: it places the Totem (TotemSpawner), checks every tap on it (Session.wave_start_requested:
## the Totem's wave or, after a wave not won, that wave or one easier; the player near it; one wave at
## a time; Sandbox MONSTERS: ON), counts down 5 s, brings the wave's monsters through the
## MonsterDirector a few at a time from the edge of the 25-block circle (not wild, tagged with the wave,
## heading for the Totem), counts them, ends the wave (WaveRules.outcome) and pays 10 x N gold to every
## player not knocked out during it (Session.knockout_received). A win raises N (next_changed: the
## sandbox saves it); a wave not won sends its monsters home and offers itself again or one easier.
## Once wave 5 is won it offers the boss: boss_offered, boss_requested and set_boss_running are the
## hooks Task 10 (the Stone Golem) uses. Every change goes to everyone as one small state (state()),
## which each game's HUD wave line, Totem panel and Totem glow follow (state_changed).
## World access is injected, so tests drive the host side with stubs. Nothing here edits blocks.

## Every peer: the wave state changed (WaveDirector.state()).
signal state_changed(state: Dictionary)
## Host: a wave ended (WaveRules.WON, TIME_UP, KNOCKED_OUT, or STOPPED).
signal wave_ended(wave: int, result: StringName)
## Host: the Totem's N changed (the sandbox saves it in WorldMeta.wave_next).
signal next_changed(next: int)
## Host (Task 10): a wave from BOSS_AFTER on was won; the Totem offers the Stone Golem.
signal boss_offered(totem_pos: Vector3)
## Host (Task 10): a player near the Totem asked for the boss (checked: offered, nothing running).
signal boss_requested(peer_id: int, totem_pos: Vector3)

enum Phase { IDLE, COUNTDOWN, RUNNING, BOSS }

const TICK := 0.2                 # host: counting, spawning and ending, five times a second
const MAX_SPAWNS_PER_TICK := 2    # monsters built per tick (the animals' lesson: many in one frame cost)
const MAX_TRIES_PER_TICK := 12    # spawn columns looked at per tick
const STOPPED := &"stopped"       # MONSTERS: OFF (Sandbox) ended the wave: nobody won or lost
## A wave monster that chases nobody and got no closer to the Totem for STUCK_TIME (behind a river, up
## a cliff, resting far from everyone) is called to CALL_RADIUS from it, so every wave can be won.
const STUCK_TIME := 15.0
const CALL_RADIUS := 9.0
const NEAR_TOTEM := 12.0          # monsters this close are never called
const FX_SPAWN := 0
const FX_START := 1
const FX_WIN := 2
const SPAWN_COLOR := Color(0.72, 0.42, 1.0)

# Host side, injected by the sandbox (tests use stubs).
var monsters: MonsterDirector
var player_peers: Callable = _spawned_peers   # () -> Array[int]: players in the world (never bots)
var stand_spot: Callable                      # (x: int, z: int) -> Vector3 feet on the surface, or INF
var is_ready: Callable                        # (pos: Vector3) -> bool: terrain loaded there
var eye_of: Callable = _eye_of                # (peer) -> Vector3: a player's eye, INF if none or down
var pay: Callable = _pay                      # (peer, gold) -> void
var tell: Callable = _tell                    # (peer, text) -> void: a toast for that player
var celebrate: Callable = _celebrate          # () -> void: everyone dances after a win (M3 Task 9)
var monsters_allowed: Callable = _always      # () -> bool: Sandbox MONSTERS: ON / OFF
var team_size: Callable = _team_here          # () -> int: players and bot friends (M4 E: waves grow with the team)
## M4 H: () -> bool: a co-op game's round is on (hide-and-seek, Storm Run); the Totem starts nothing meanwhile.
var game_on: Callable = func() -> bool: return false
var gentle := false                           # Sandbox waves (§12.15)
## Monster Wave (owner feedback #44, spec §12.20; the ArenaDirector sets both false): a tap on the Totem starts
## nothing (the waves come by themselves), and a won wave pays nothing itself (the run pays at its end).
var taps_start := true
var rewards := true
## Monster Wave: knock-outs never end a wave (the run ends when everyone is down at once: the ArenaDirector).
var knockouts_end_waves := true
var universe := 1
## The universe's wave monsters (M3 Task 2: the desert's mummies and scorpions) and its boss's name.
var kinds: Array[StringName] = MonsterRules.MEADOWS_KINDS
var boss_name := "Stone Golem"
var rng := RandomNumberGenerator.new()

# Host: the wave. Guests mirror the host's `current` state.
var phase: Phase = Phase.IDLE
var next_wave := WaveRules.FIRST_WAVE         # the wave the Totem offers (saved per world)
var wave := 0                                 # the wave counting down or running
var lost := 0                                 # the last wave not won since the last win (0 = none)
## Every peer: the last state heard (the host's own included).
var current: Dictionary = {}

var _countdown := 0.0
var _elapsed := 0.0
var _pending: Array[Dictionary] = []          # monsters still to appear: {kind, level, index, cursor}
var _count := 0
var _start_angle := 0.0
var _knocked: Array[int] = []
var _team := 1                    # the team when the running wave began (M4 E)
var _progress := {}               # wave monster name -> [closest to the Totem so far, seconds without getting closer]
var _run := 0
var _t := 0.0
var _last_sent := {}
var _totem_pos := Vector3.INF
var _watched: Totem
var _totems := Node3D.new()
var _totem_spawner := MultiplayerSpawner.new()


func _init() -> void:
	rng.randomize()


func _ready() -> void:
	_totems.name = "Totems"
	add_child(_totems)
	_totem_spawner.name = "TotemSpawner"
	add_child(_totem_spawner)
	_totem_spawner.spawn_path = _totem_spawner.get_path_to(_totems)
	_totem_spawner.spawn_function = _make_totem
	# A LAN guest's sandbox makes this before it joins, so every handler checks is_host() itself.
	Session.wave_start_requested.connect(_on_start_requested)
	Session.wave_boss_requested.connect(_on_boss_requested)
	Session.knockout_received.connect(_on_knockout)
	Session.revive_done.connect(_on_revived)   # M4 E: a helped player is standing again
	Session.client_ready.connect(_on_client_ready)


func _process(delta: float) -> void:
	if (phase == Phase.COUNTDOWN or phase == Phase.RUNNING) and Session.is_host():
		advance(delta)


# --- The Totem --------------------------------------------------------------------------------------

## Host: the world's Totem, for everyone.
func place_totem(pos: Vector3, yaw: float) -> Totem:
	_totem_pos = pos
	var t := _totem_spawner.spawn({"pos": pos, "yaw": yaw}) as Totem
	_sync()
	return t


func _make_totem(data: Variant) -> Node:
	var t := Totem.new()
	t.setup(data)
	watch_totem(t)
	print("TOTEM at %s" % t.position)   # host and guests (the spawner replicates it)
	return t


## This game's Totem follows the wave state (glow and the line over it).
func watch_totem(t: Totem) -> void:
	_watched = t
	if not current.is_empty():
		t.show_state(current)


func totem() -> Totem:
	return _watched if is_instance_valid(_watched) else null


func totem_position() -> Vector3:
	return _totem_pos


# --- Host: starting and stopping ----------------------------------------------------------------------

## Host: a player's tap on START (TRY AGAIN, EASIER). Returns why not (&"" = the countdown began); the
## player hears why (WaveRules.REFUSALS).
func request_start(peer_id: int, n: int) -> StringName:
	var why := _start_refusal(peer_id, n)
	if why != &"":
		var text := WaveRules.refusal_message(why, boss_name)
		if text != "":
			tell.call(peer_id, text)
		return why
	start(n)
	return &""


func _start_refusal(peer_id: int, n: int) -> StringName:
	if not taps_start:
		return &"auto"
	if phase == Phase.BOSS:
		return &"boss"
	if phase != Phase.IDLE:
		return &"busy"
	if game_on.call():
		return &"game"   # M4 H
	if not monsters_allowed.call():
		return &"off"
	if not WaveRules.may_start(n, next_wave, lost):
		return &"not_offered"
	if not WaveRules.in_reach(eye_of.call(peer_id), _totem_pos, WaveRules.HOST_REACH):
		return &"too_far"
	return &""


## Host: wave n counts down, then comes (no checks: tests and tools).
func start(n: int) -> void:
	wave = WaveRules.valid_wave(n)
	phase = Phase.COUNTDOWN
	_countdown = float(WaveRules.COUNTDOWN)
	_t = 0.0
	_sync()


## Host: ends a wave without a result (Sandbox MONSTERS: OFF): its monsters go home, N and the offer stay.
func stop() -> void:
	if phase != Phase.COUNTDOWN and phase != Phase.RUNNING:
		return
	var played := wave
	_send_home()
	_finish()
	wave_ended.emit(played, STOPPED)


func busy() -> bool:
	return phase != Phase.IDLE


## The night spawns' switch (MonsterDirector.enabled) with the waves in: no night monsters while a
## wave or the boss is on (the wild ones puff away), so the budget of 20 holds.
func night_allowed(enabled: Callable) -> Callable:
	return func() -> bool: return enabled.call() and not busy()


# --- Host: the boss hook (Task 10) --------------------------------------------------------------------

func boss_available() -> bool:
	return WaveRules.boss_ready(next_wave)


## Host: a player's tap on the Totem's boss button. Returns why not (&"" = boss_requested was emitted).
func request_boss(peer_id: int) -> StringName:
	var why := &""
	if not taps_start:
		why = &"auto"
	elif phase == Phase.BOSS:
		why = &"boss"
	elif phase != Phase.IDLE:
		why = &"busy"
	elif game_on.call():
		why = &"game"   # M4 H
	elif not boss_available():
		why = &"no_boss"
	elif not WaveRules.in_reach(eye_of.call(peer_id), _totem_pos, WaveRules.HOST_REACH):
		why = &"too_far"
	elif boss_requested.get_connections().is_empty():
		why = &"asleep"   # nothing brings the boss yet
	if why != &"":
		tell.call(peer_id, WaveRules.refusal_message(why, boss_name))
		return why
	boss_requested.emit(peer_id, _totem_pos)
	return &""


## Host (Task 10): the boss fight began or ended. Meanwhile the Totem glows and starts no wave.
func set_boss_running(on: bool) -> void:
	if on and phase == Phase.IDLE:
		phase = Phase.BOSS
	elif not on and phase == Phase.BOSS:
		phase = Phase.IDLE
	_sync()


# --- Host: the clock ------------------------------------------------------------------------------------

## Host: the countdown and the wave clock (tests drive it directly).
func advance(delta: float) -> void:
	if phase == Phase.COUNTDOWN:
		_countdown -= delta
		if _countdown <= 0.001:
			_begin()
	elif phase == Phase.RUNNING:
		_elapsed += delta
	_t += delta
	if _t >= TICK - 0.0001:
		_t = 0.0
		tick()


## Host, every TICK: new monsters, the count, the end.
func tick() -> void:
	if phase == Phase.RUNNING:
		_spawn_some()
		_call_stuck()
		var knocked: Array[int] = _knocked if knockouts_end_waves else ([] as Array[int])   # Monster Wave: the arena's
		var result := WaveRules.outcome(_alive(), _pending.size(), _elapsed, _players(), knocked)
		if result != WaveRules.GOING:
			_end(result)
			return
	_sync()


func _begin() -> void:
	phase = Phase.RUNNING
	_elapsed = 0.0
	_knocked.clear()
	_run += 1
	_team = maxi(int(team_size.call()), 1)
	var roster := ArcherRules.wave_roster(WaveRules.roster(wave, gentle, _team, kinds), wave)   # M3 Task 14b: archers from wave 4
	_count = roster.size()
	_start_angle = rng.randf() * TAU
	_pending.clear()
	for i in roster.size():
		_pending.append({"kind": roster[i].kind, "level": roster[i].level, "index": i, "cursor": 0})
	_rpc_fx.rpc(_totem_pos + Vector3(0, Totem.CRYSTAL_Y, 0), FX_START)


## Up to MAX_SPAWNS_PER_TICK monsters, each at its own place on the edge of the circle, or the next
## column that has ground (water and tree tops don't); it waits while the terrain there is not loaded.
func _spawn_some() -> void:
	var made := 0
	var tries := MAX_TRIES_PER_TICK
	while made < MAX_SPAWNS_PER_TICK and not _pending.is_empty() and tries > 0:
		var entry: Dictionary = _pending[0]
		var cols := WaveRules.spawn_columns(_totem_pos, int(entry.index), _count, _start_angle)
		var pos := Vector3.INF
		while tries > 0 and int(entry.cursor) < cols.size():
			tries -= 1
			var c: Vector2 = cols[int(entry.cursor)]
			if not is_ready.call(Vector3(c.x, _totem_pos.y, c.y)):
				return                      # its ground is still loading: next tick
			pos = stand_spot.call(floori(c.x), floori(c.y))
			if pos.is_finite():
				break
			entry.cursor = int(entry.cursor) + 1
		if not pos.is_finite():
			if int(entry.cursor) < cols.size():
				return                      # out of tries this tick
			pos = _totem_pos + Vector3(0, 0, -3).rotated(Vector3.UP, TAU * int(entry.index) / maxi(_count, 1))
		_pending.pop_front()
		_spawn(entry, pos)
		made += 1


func _spawn(entry: Dictionary, pos: Vector3) -> void:
	var to := _totem_pos - pos
	monsters.spawn_monster({"kind": entry.kind, "level": entry.level, "id": "w%d_%d" % [_run, int(entry.index)],
		"pos": pos, "yaw": atan2(-to.x, -to.z), "wild": false, "universe": universe, "wave": wave, "goal": _totem_pos})
	_rpc_fx.rpc(pos + Vector3(0, 0.6, 0), FX_SPAWN)


## The wave's monsters still up (small slimes of a split wave slime included).
func wave_monsters() -> Array[Monster]:
	var out: Array[Monster] = []
	if monsters == null:
		return out
	for m in monsters.monsters():
		if m.wave > 0:
			out.append(m)
	return out


func _alive() -> int:
	return wave_monsters().size()


## Wave monsters that got stuck on their way are called closer (a puff where they were and where they
## come back), the way bot friends catch up with the player.
func _call_stuck() -> void:
	var seen := {}
	for m in wave_monsters():
		var key := String(m.name)
		seen[key] = true
		var d := Vector2(m.global_position.x - _totem_pos.x, m.global_position.z - _totem_pos.z).length()
		var p: Array = _progress.get(key, [d, 0.0])
		if d < float(p[0]) - 1.0:
			p = [d, 0.0]
		elif d <= NEAR_TOTEM or m.target() != null:
			p[1] = 0.0
		else:
			p[1] = float(p[1]) + TICK
		if float(p[1]) >= STUCK_TIME and _call_closer(m):
			p = [CALL_RADIUS, 0.0]
		_progress[key] = p
	for key: String in _progress.keys():
		if not seen.has(key):
			_progress.erase(key)


func _call_closer(m: Monster) -> bool:
	var a := atan2(m.global_position.z - _totem_pos.z, m.global_position.x - _totem_pos.x)
	for r: float in [CALL_RADIUS, CALL_RADIUS - 1.0, CALL_RADIUS + 1.0, CALL_RADIUS - 2.0]:
		for nudge: float in [0.0, 0.3, -0.3, 0.6, -0.6]:
			var c := Vector2(_totem_pos.x + cos(a + nudge) * r, _totem_pos.z + sin(a + nudge) * r)
			if not is_ready.call(Vector3(c.x, _totem_pos.y, c.y)):
				continue
			var pos: Vector3 = stand_spot.call(floori(c.x), floori(c.y))
			if pos.is_finite():
				_rpc_fx.rpc(m.hit_center(), FX_SPAWN)
				m.global_position = pos
				m.velocity = Vector3.ZERO
				_rpc_fx.rpc(pos + Vector3(0, 0.6, 0), FX_SPAWN)
				return true
	return false


func _players() -> Array[int]:
	var out: Array[int] = []
	out.assign(player_peers.call())
	return out


func _end(result: StringName) -> void:
	var played := wave
	var won := WaveRules.is_win(result)
	var players := _players()
	if won:
		var gold := UniverseRules.gold(WaveRules.reward(played, Game.allows(ModeRules.INFINITE_GOLD)), universe) \
			if rewards else 0   # × 2^(u−1) (M3 Task 5); Monster Wave pays at the run's end
		var paid := WaveRules.paid(players, _knocked)
		for p in players:
			if paid.has(p):
				if gold > 0:
					pay.call(p, gold)
				tell.call(p, WaveRules.won_message(played, gold))
			else:
				tell.call(p, WaveRules.no_gold_message(played) if gold > 0 else WaveRules.won_message(played, 0))
		lost = 0
		celebrate.call()
		_set_next(WaveRules.next_wave(next_wave, played, true))
		_rpc_fx.rpc(_totem_pos + Vector3(0, Totem.CRYSTAL_Y, 0), FX_WIN)
	else:
		_send_home()
		lost = played
		for p in players:
			tell.call(p, WaveRules.lost_message(result))
	_finish()
	wave_ended.emit(played, result)
	if WaveRules.offers_boss(played, won):
		boss_offered.emit(_totem_pos)


## The wave's monsters puff away (no coins).
func _send_home() -> void:
	for m in wave_monsters():
		monsters.puff(m)


func _finish() -> void:
	_pending.clear()
	_knocked.clear()
	_progress.clear()
	phase = Phase.IDLE
	wave = 0
	_countdown = 0.0
	_elapsed = 0.0
	_sync()


func _set_next(n: int) -> void:
	if n != next_wave:
		next_wave = n
		next_changed.emit(n)


func _on_knockout(peer_id: int, _at_home: bool) -> void:
	if Session.is_host() and phase == Phase.RUNNING and not _knocked.has(peer_id):
		_knocked.append(peer_id)


func _on_start_requested(peer_id: int, n: int) -> void:
	if Session.is_host():
		request_start(peer_id, n)


func _on_boss_requested(peer_id: int) -> void:
	if Session.is_host():
		request_boss(peer_id)


# --- Everyone: the state ------------------------------------------------------------------------------

## What every game shows: phase, the Totem's next wave, the wave on, monsters left (still to come
## included), the countdown's whole seconds, the time left, the wave not won (0 = none), whether the
## boss is offered, and whether waves are gentle (Sandbox).
func state() -> Dictionary:
	var running := phase == Phase.RUNNING
	return {"phase": phase, "next": next_wave, "wave": wave,
		"left": _alive() + _pending.size() if running else 0,
		"total": WaveRules.size(wave, gentle, _team) if running else 0,
		"team": _team if running else maxi(int(team_size.call()), 1),
		"count": ceili(maxf(_countdown, 0.0)) if phase == Phase.COUNTDOWN else 0,
		"time_left": maxf(WaveRules.TIME_LIMIT - _elapsed, 0.0) if running else 0.0,
		"lost": lost, "boss": boss_available(), "gentle": gentle}


## Host: sends the state to everyone when something they see changed (not the clock alone).
func _sync() -> void:
	var s := state()
	var key := s.duplicate()
	key.erase("time_left")
	if key == _last_sent:
		return
	_last_sent = key
	_rpc_state.rpc(s)


func _on_client_ready(peer_id: int) -> void:
	if Session.is_host() and not current.is_empty():
		_rpc_state.rpc_id(peer_id, state())
		_sync()   # M4 E: everyone's Totem panel counts the new team


@rpc("authority", "call_local", "reliable")
func _rpc_state(s: Dictionary) -> void:
	apply_state(s)


## Every peer: the host's wave state arrives (the host's own too).
func apply_state(s: Dictionary) -> void:
	current = s
	if is_instance_valid(_watched):
		_watched.show_state(s)
	state_changed.emit(s)


## Everyone: a monster appears (a purple puff), the wave starts (a horn at the Totem), a win (confetti).
@rpc("authority", "call_local", "unreliable")
func _rpc_fx(pos: Vector3, kind: int) -> void:
	var root := get_tree().root
	match kind:
		FX_SPAWN:
			Fx.burst(root, pos, SPAWN_COLOR, 12, 3.0, 0.14, 0.7, 2.0)
			Audio.play(&"poof", pos, -6.0)
		FX_START:
			Fx.burst(root, pos, SPAWN_COLOR, 16, 4.0, 0.12, 0.8, 4.0)
			Audio.play(&"horn", pos)   # the audio pass
		FX_WIN:
			for c in MonsterDirector.CONFETTI:
				Fx.burst(root, pos, c, 10, 6.0, 0.12, 1.1, 8.0)
			Audio.play(&"ding", pos)
			Audio.play(&"coin", pos, -4.0)


# --- Defaults (the sandbox's world through Session) ------------------------------------------------------

func _spawned_peers() -> Array[int]:
	var out: Array[int] = []
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if is_instance_valid(p) and not p.is_queued_for_deletion() and p.is_spawned():
			out.append(p.peer_id)
	return out


func _eye_of(peer_id: int) -> Vector3:
	var p := Session._player_for_peer(peer_id)
	return p.eye_position() if p and p.is_spawned() and not p.knocked_out else Vector3.INF


func _pay(peer_id: int, gold: int) -> void:
	Session.gold_add(peer_id, gold, "wave")


func _celebrate() -> void:
	Session.celebrate_all()


func _tell(peer_id: int, text: String) -> void:
	if peer_id == multiplayer.get_unique_id() or multiplayer.get_peers().has(peer_id):
		Session.send_feedback(peer_id, text)


func _always() -> bool:
	return true


# --- M4 E: waves grow with the team (§12.8, §17.5) ---

## Players and bot friends in this world (like the Stone Golem's health), at least one.
func _team_here() -> int:
	return maxi(BotFriend.team_size(get_tree()), 1) if is_inside_tree() else 1


## Host: a teammate helped this player up during the wave: they count as standing (paid for a win).
func _on_revived(peer_id: int, _by_peer: int) -> void:
	if Session.is_host():
		_knocked.erase(peer_id)


static func team_of(players: int, bots: int) -> int:
	return maxi(BotRules.team_size(players, bots), 1)
