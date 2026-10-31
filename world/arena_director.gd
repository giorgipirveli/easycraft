class_name ArenaDirector
extends Node
## Monster Wave in its arena (owner feedback #44, spec §12.20). The sandbox adds one on every peer, named "Arena",
## so its RPCs line up across the network.
## Host (start()): a run begins by itself (READY: "Get ready!", then wave 1 after ArenaRules.FIRST_DELAY); each
## next wave comes BREATHER seconds after the last was cleared (won, or its 3 minutes ran out) through the
## WaveDirector (taps on the Totem start nothing here; waves pay nothing themselves; knock-outs never end a
## wave); wave FINAL_WAVE is the raid boss through the BossDirector. The run ends when every player is knocked out
## at once (solo: the first knock-out), or when the raid boss is beaten or wins: the monsters go home, every player
## in the arena gets ArenaRules.run_gold for the time and the waves (once, through Session.gold_add), their best is
## kept (bests: the arena world's WorldMeta.arena, by name) and they hear their result (a panel: PLAY AGAIN /
## LEAVE, or after the boss NEXT UNIVERSE / STAY). Every defeat pays its defeater the small kill bonus with the
## combo (MonsterDirector.defeat_payer; no coins).
## Every peer: the run's state (state_changed), this player's result (result_shown) and best (best_changed); the
## HUD's clock and the result panel follow them (setup_local).
## World access is injected, so tests drive the host side with stubs. Nothing here changes a block.

signal state_changed(state: Dictionary)
signal result_shown(result: Dictionary)
signal best_changed(best: Dictionary)

enum Phase { IDLE, READY, WAVE, BREATHER, BOSS, OVER }

const SYNC_EVERY := 1.0
const CLEARED_WORDS := "Wave %d cleared! Next wave coming."

# Host side, injected by the sandbox (tests use stand-ins).
var waves: WaveDirector
var boss: Node                       # BossDirector: start(pos), fighting(), end_fight(), fight_ended(won, percent)
var monsters: MonsterDirector
var universe := 1
var totem_pos := Vector3.INF
var now: Callable = func() -> float: return Time.get_ticks_msec() / 1000.0
var name_of: Callable                # (peer_id) -> String: whose best
## {player name: ArenaRules record}: the arena world's WorldMeta.arena (the same dictionary).
var bests: Dictionary = {}
var travel: Callable                 # (u) -> String: the sandbox travels to universe u's arena (solo)
var next_open: Callable = func(u: int) -> bool: return UniverseRegistry.available().has(u)
var solo: Callable = func() -> bool: return multiplayer.get_peers().is_empty()

var phase: Phase = Phase.IDLE
var run_time := 0.0
var cleared := 0
var wait_left := 0.0
var running := false                 # host

var _down := {}                      # host: peer -> true, knocked out and not up yet
var _combos := {}                    # host: peer -> ArenaRules.Combo
var _sync_t := 0.0
var _next_offer := 0                 # host: the universe NEXT UNIVERSE leads to (0: none)


# --- Host -------------------------------------------------------------------------------------------------

## Host: the arena's hooks, then the first run.
func start() -> void:
	running = true
	waves.taps_start = false
	waves.rewards = false
	waves.knockouts_end_waves = false
	waves.tell = func(_peer: int, _text: String) -> void: pass   # the arena says its own words
	waves.wave_ended.connect(_on_wave_ended)
	boss.connect(&"fight_ended", _on_boss_ended)
	monsters.defeat_payer = _pay_defeat
	Session.knockout_received.connect(_on_knockout)
	Session.knockout_respawned.connect(_on_up)
	Session.revive_done.connect(func(peer_id: int, _by: int) -> void: _on_up(peer_id, false))
	Session.client_ready.connect(_on_client_ready)
	start_run()


## Host: a new run from wave 1.
func start_run() -> void:
	phase = Phase.READY
	run_time = 0.0
	cleared = 0
	wait_left = ArenaRules.FIRST_DELAY
	_down.clear()
	_combos.clear()
	_next_offer = 0
	for p in _players():
		_tell(p.peer_id, ArenaRules.READY_WORDS)
	_sync()


func _process(delta: float) -> void:
	if running:
		advance(delta)
	_local_process(delta)


## Host: the run's clock (tests drive it directly).
func advance(delta: float) -> void:
	match phase:
		Phase.READY, Phase.BREATHER:
			run_time += delta
			wait_left -= delta
			if wait_left <= 0.0:
				_next()
		Phase.WAVE, Phase.BOSS:
			run_time += delta
	_sync_t -= delta
	if _sync_t <= 0.0:
		_sync_t = SYNC_EVERY
		_sync()


## The next wave, or the raid boss.
func _next() -> void:
	var n := cleared + 1
	if ArenaRules.is_boss_wave(n):
		phase = Phase.BOSS
		waves.set_boss_running(true)
		boss.call(&"start", totem_pos)
		for p in _players():
			_tell(p.peer_id, ArenaRules.BOSS_WORDS)
	else:
		phase = Phase.WAVE
		waves.start(n)
	_sync()


func _on_wave_ended(n: int, result: StringName) -> void:
	if phase != Phase.WAVE:
		return
	if result == WaveRules.WON or result == WaveRules.TIME_UP:
		cleared = n
		phase = Phase.BREATHER
		wait_left = ArenaRules.BREATHER
		for p in _players():
			_tell(p.peer_id, tr(CLEARED_WORDS) % n)
		_sync()
	elif result == WaveRules.KNOCKED_OUT:
		end_run(false)


func _on_boss_ended(won: bool, _percent: int) -> void:
	if phase != Phase.BOSS:
		return
	waves.set_boss_running(false)
	if won:
		cleared = ArenaRules.FINAL_WAVE
	end_run(won)


func _on_knockout(peer_id: int, _at_home: bool) -> void:
	if not running or phase == Phase.OVER or phase == Phase.IDLE:
		return
	_down[peer_id] = true
	if _combos.has(peer_id):
		(_combos[peer_id] as ArenaRules.Combo).reset()
	if _all_down():
		end_run(false)


func _on_up(peer_id: int, _at_home: bool) -> void:
	_down.erase(peer_id)


func _all_down() -> bool:
	var players := _players()
	if players.is_empty():
		return false
	for p in players:
		if not _down.has(p.peer_id):
			return false
	return true


## Host: the run is over: the monsters go home, everyone is paid for the time and the waves, bests, results.
func end_run(won: bool) -> void:
	if phase == Phase.OVER:
		return
	var was_boss := phase == Phase.BOSS
	phase = Phase.OVER
	if waves.phase == WaveDirector.Phase.COUNTDOWN or waves.phase == WaveDirector.Phase.RUNNING:
		waves.stop()
	if was_boss:
		if not won and bool(boss.call(&"fighting")):
			boss.call(&"end_fight")
		waves.set_boss_running(false)
	monsters.puff_all()
	var gold := ArenaRules.run_gold(run_time, cleared, universe)
	var next := UniverseRules.next_universe(universe)
	_next_offer = next if won and bool(next_open.call(next)) else 0
	for p in _players():
		if gold > 0:
			Session.gold_add(p.peer_id, gold, "arena")
		var best := best_of(p.peer_id)
		var new_best := ArenaRules.better(best, run_time, cleared)
		_send_result(p.peer_id, {"seconds": run_time, "cleared": cleared, "gold": gold, "won": won,
			"new_best": new_best, "next": _next_offer, "best": best.duplicate()})
	_sync()


## A player's best in this arena (made the first time).
func best_of(peer_id: int) -> Dictionary:
	var key := _key(peer_id)
	if not bests.has(key):
		bests[key] = ArenaRules.new_record()
	return bests[key]


## MonsterDirector.defeat_payer: the one who defeated it gets the kill bonus at once, × the combo (no coins).
func _pay_defeat(m: Monster) -> bool:
	var peer := _defeater(m.last_hit_from)
	if not _combos.has(peer):
		_combos[peer] = ArenaRules.Combo.new()
	var count := (_combos[peer] as ArenaRules.Combo).defeat(float(now.call()))
	var gold := ArenaRules.kill_gold(count, universe)
	Session.gold_add(peer, gold, "arena")
	Session.send_hunt_paid(peer, gold, count)
	return true


## The player nearest to where the last hit came from (this game's player when nobody is known).
func _defeater(from: Vector3) -> int:
	var best := INF
	var peer := multiplayer.get_unique_id()
	for p in _players():
		var d := p.global_position.distance_to(from) if from.is_finite() else 0.0
		if d < best:
			best = d
			peer = p.peer_id
	return peer


# --- Choices: PLAY AGAIN / STAY and NEXT UNIVERSE ------------------------------------------------------------

## A new run here (PLAY AGAIN, STAY). The host decides.
func request_again() -> void:
	if Session.is_host():
		if phase == Phase.OVER:
			start_run()
	else:
		_rpc_again.rpc_id(1)


## NEXT UNIVERSE after the raid boss (solo): the host travels to the next universe's arena.
func request_next() -> void:
	if not Session.is_host() or phase != Phase.OVER or _next_offer <= 0 or not bool(solo.call()):
		return
	if travel.is_valid():
		travel.call(_next_offer)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_again() -> void:
	if Session.is_host() and phase == Phase.OVER:
		start_run()


# --- Everyone: the state, results and bests -----------------------------------------------------------------

## What every game shows: the phase, the time survived, the waves cleared.
func state() -> Dictionary:
	return {"phase": phase, "time": run_time, "cleared": cleared}


## The wave shown on the clock: the one coming or on (the raid boss at the end).
func shown_wave() -> int:
	return mini(cleared + 1, ArenaRules.FINAL_WAVE) if phase != Phase.OVER else maxi(cleared, 1)


func _sync() -> void:
	var s := state()
	state_changed.emit(s)
	if not multiplayer.get_peers().is_empty():
		_rpc_state.rpc(s)


@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_state(s: Dictionary) -> void:
	apply_state(s)


## A guest: the host's state (the time runs on here between syncs while a run is on).
func apply_state(s: Dictionary) -> void:
	phase = clampi(int(s.get("phase", 0)), 0, Phase.OVER) as Phase
	run_time = maxf(float(s.get("time", 0.0)), 0.0)
	cleared = clampi(int(s.get("cleared", 0)), 0, ArenaRules.FINAL_WAVE)
	state_changed.emit(state())


func _send_result(peer_id: int, r: Dictionary) -> void:
	if peer_id == multiplayer.get_unique_id():
		result_shown.emit(r)
		best_changed.emit(r.best)
	elif multiplayer.get_peers().has(peer_id):
		_rpc_result.rpc_id(peer_id, r)


@rpc("authority", "call_remote", "reliable")
func _rpc_result(r: Dictionary) -> void:
	var clean := {"seconds": maxf(float(r.get("seconds", 0.0)), 0.0), "cleared": clampi(int(r.get("cleared", 0)), 0,
		ArenaRules.FINAL_WAVE), "gold": maxi(int(r.get("gold", 0)), 0), "won": bool(r.get("won", false)),
		"new_best": bool(r.get("new_best", false)), "next": 0, "best": ArenaRules.clean(r.get("best"))}
	result_shown.emit(clean)
	best_changed.emit(clean.best)


func _on_client_ready(peer_id: int) -> void:
	if multiplayer.get_peers().has(peer_id):
		_rpc_best.rpc_id(peer_id, best_of(peer_id))
		_rpc_state.rpc_id(peer_id, state())


@rpc("authority", "call_remote", "reliable")
func _rpc_best(b: Dictionary) -> void:
	best_changed.emit(ArenaRules.clean(b))


# --- Shared ------------------------------------------------------------------------------------------------

func _players() -> Array[Player]:
	var out: Array[Player] = []
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if p and not p.is_queued_for_deletion() and p.is_spawned():
			out.append(p)
	return out


func _key(peer_id: int) -> String:
	var n := str(name_of.call(peer_id)) if name_of.is_valid() else ""
	return n if n != "" else "#%d" % peer_id


func _tell(peer_id: int, text: String) -> void:
	if peer_id == multiplayer.get_unique_id() or multiplayer.get_peers().has(peer_id):
		Session.send_feedback(peer_id, text)

# --- Every peer: the HUD's clock and the result panel --------------------------------------------------------

var clock: GameClock
var _my_best := ArenaRules.new_record()
var _local_t := 0.0


## This game's HUD: the clock shows the run; results and bests follow.
func setup_local(c: GameClock) -> void:
	clock = c
	clock.visible = true
	best_changed.connect(func(b: Dictionary) -> void: _my_best = b.duplicate())
	Session.hunt_paid.connect(func(gold: int, combo: int) -> void:
		if is_instance_valid(clock):
			clock.show_paid(gold, combo))
	if running:
		_my_best = best_of(multiplayer.get_unique_id()).duplicate()
	update_clock()


func _local_process(delta: float) -> void:
	if clock == null:
		return
	if not running and (phase == Phase.READY or phase == Phase.WAVE or phase == Phase.BREATHER or phase == Phase.BOSS):
		run_time += delta   # a guest's clock runs on between the host's syncs
	_local_t += delta
	if _local_t >= 0.25:
		_local_t = 0.0
		update_clock()


func update_clock() -> void:
	if is_instance_valid(clock):
		clock.show_arena(run_time, shown_wave(), _my_best)
