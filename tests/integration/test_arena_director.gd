extends GutTest
## Monster Wave on the host (owner feedback #44, spec §12.20), with a real WaveDirector and MonsterDirector on stubs
## and a stand-in boss: a run starts by itself (wave 1 after 8 s), each next wave 8 s after the last is cleared,
## wave 10 is the raid boss, Totem taps start nothing; the run ends when every player is down at once and pays
## gold for the time and the waves; a small kill bonus with the combo (no coins); each player's best is kept;
## beating the boss offers NEXT UNIVERSE or STAY.

const FLOOR := 10
const TOTEM := Vector3(0.5, FLOOR, 0.5)

var _mode_before: StringName
var _gold_before := 0
var _now := 100.0
var _md: MonsterDirector
var _waves: WaveDirector
var _boss: FakeBoss
var _me: Player
var _results: Array = []
var _paid: Array = []
var _travels: Array[int] = []


class FakeBoss:
	extends Node

	signal fight_started(tired: bool)
	signal fight_ended(won: bool, percent: int)

	var started: Array = []
	var ended := 0
	var _on := false

	func start(pos: Vector3, _kind: StringName = &"") -> String:
		started.append(pos)
		_on = true
		fight_started.emit(false)
		return ""

	func fighting() -> bool:
		return _on

	func end_fight() -> void:
		ended += 1
		_on = false

	func finish(won: bool) -> void:
		_on = false
		fight_ended.emit(won, 0 if won else 40)


func before_each() -> void:
	_mode_before = Game.mode
	_gold_before = Profile.data.survivor_gold
	Game.mode = ModeRules.WAVE
	Profile.data.survivor_gold = 0
	_now = 100.0
	_results.clear()
	_paid.clear()
	_travels.clear()
	Session.hunt_paid.connect(_on_paid)
	_md = MonsterDirector.new()
	_md.name = "Monsters"
	_md.block_at = _flat
	_md.player_positions = func() -> Array[Vector3]:
		var out: Array[Vector3] = []
		for p: Player in get_tree().get_nodes_in_group(&"players"):
			out.append(p.global_position)
		return out
	add_child_autofree(_md)
	_waves = WaveDirector.new()
	_waves.name = "Waves"
	_waves.monsters = _md
	_waves.stand_spot = func(x: int, z: int) -> Vector3: return Vector3(x + 0.5, FLOOR, z + 0.5)
	_waves.is_ready = func(_p: Vector3) -> bool: return true
	_waves.rng.seed = 20260924
	add_child_autofree(_waves)
	_waves.set_process(false)
	_waves.place_totem(TOTEM, 0.0)
	_boss = FakeBoss.new()
	add_child_autofree(_boss)
	_me = _player(Vector3(0.5, FLOOR, 6.5))


func after_each() -> void:
	Session.hunt_paid.disconnect(_on_paid)
	Game.mode = _mode_before
	Profile.data.survivor_gold = _gold_before
	Session.survivor_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_paid(gold: int, combo: int) -> void:
	_paid.append([gold, combo])


func _flat(p: Vector3i) -> int:
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _player(feet: Vector3, peer: int = 1) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _arena(u: int = 1) -> ArenaDirector:
	var a := ArenaDirector.new()
	a.name = "Arena"
	a.waves = _waves
	a.boss = _boss
	a.monsters = _md
	a.universe = u
	a.totem_pos = TOTEM
	a.now = func() -> float: return _now
	a.name_of = func(peer: int) -> String: return "P%d" % peer
	a.travel = func(to: int) -> String:
		_travels.append(to)
		return ""
	a.next_open = func(to: int) -> bool: return to <= 3
	a.result_shown.connect(func(r: Dictionary) -> void: _results.append(r))
	add_child_autofree(a)
	a.set_process(false)   # the test drives the clock
	a.start()
	return a


## Moves the run's clock (and the waves' with it) by `seconds`.
func _run(a: ArenaDirector, seconds: float) -> void:
	var step := WaveDirector.TICK
	for i in roundi(seconds / step):
		_now += step
		a.advance(step)
		_waves.advance(step)


func _defeat_wave() -> void:
	for i in 12:
		for m in _waves.wave_monsters():
			m.take_hit(100000, _me.global_position, Vector3.ZERO)
		if _waves.wave_monsters().is_empty():
			return


## Clears the running wave once all its monsters are there.
func _clear_wave(a: ArenaDirector) -> void:
	_run(a, WaveRules.COUNTDOWN + 0.2)
	_run(a, 4.0)
	_defeat_wave()
	_run(a, 0.4)


func test_a_run_starts_by_itself_and_wave_one_comes_after_eight_seconds() -> void:
	var a := _arena()
	assert_eq(a.phase, ArenaDirector.Phase.READY)
	_run(a, ArenaRules.FIRST_DELAY - 0.4)
	assert_eq(_waves.phase, WaveDirector.Phase.IDLE, "not yet")
	_run(a, 0.6)
	assert_eq(a.phase, ArenaDirector.Phase.WAVE)
	assert_eq(_waves.wave, 1)
	assert_ne(_waves.phase, WaveDirector.Phase.IDLE)


func test_each_next_wave_comes_after_a_breather() -> void:
	var a := _arena()
	_run(a, ArenaRules.FIRST_DELAY + 0.2)
	_clear_wave(a)
	assert_eq(a.cleared, 1)
	assert_eq(a.phase, ArenaDirector.Phase.BREATHER)
	_run(a, ArenaRules.BREATHER - 0.6)
	assert_eq(_waves.phase, WaveDirector.Phase.IDLE, "a breather")
	_run(a, 0.8)
	assert_eq(_waves.wave, 2, "wave 2 by itself")


func test_the_waves_pay_nothing_themselves_in_the_arena() -> void:
	var a := _arena()
	_run(a, ArenaRules.FIRST_DELAY + 0.2)
	var before := Profile.data.survivor_gold
	_clear_wave(a)
	var kill_bonus := 0
	for p: Array in _paid:
		kill_bonus += int(p[0])
	assert_eq(Profile.data.survivor_gold - before, kill_bonus, "only the kill bonus, no wave reward")


func test_totem_taps_start_nothing_here() -> void:
	_arena()
	assert_eq(_waves.request_start(_me.peer_id, 1), &"auto")
	assert_eq(_waves.request_boss(_me.peer_id), &"auto")


func test_wave_ten_is_the_raid_boss() -> void:
	var a := _arena()
	a.cleared = ArenaRules.FINAL_WAVE - 1
	a.phase = ArenaDirector.Phase.BREATHER
	a.wait_left = 0.1
	_run(a, 0.4)
	assert_eq(a.phase, ArenaDirector.Phase.BOSS)
	assert_eq(_boss.started, [TOTEM])
	assert_eq(_waves.phase, WaveDirector.Phase.BOSS, "the Totem glows and starts no wave meanwhile")


func test_a_knock_out_ends_a_solo_run_and_pays_for_the_time_and_the_waves() -> void:
	var a := _arena()
	_run(a, ArenaRules.FIRST_DELAY + 0.2)
	_clear_wave(a)
	_run(a, 3.0)
	var seconds := a.run_time
	var kills := Profile.data.survivor_gold
	_me.knocked_out = true
	Session.knockout_received.emit(_me.peer_id, true)
	assert_eq(a.phase, ArenaDirector.Phase.OVER)
	var gold := ArenaRules.run_gold(seconds, 1, 1)
	assert_eq(Profile.data.survivor_gold - kills, gold, "the time and one wave")
	assert_eq(_results.size(), 1)
	var r: Dictionary = _results[0]
	assert_eq(int(r.cleared), 1)
	assert_eq(int(r.gold), gold)
	assert_almost_eq(float(r.seconds), seconds, 0.01)
	assert_false(r.won)
	assert_true(r.new_best, "the first run is a best")
	assert_eq(_md.monsters().filter(func(m: Monster) -> bool: return not m.is_queued_for_deletion()).size(), 0,
		"the monsters go home")
	assert_eq(a.bests["P1"].best_wave, 1)


func test_with_a_friend_the_run_ends_only_when_everyone_is_down() -> void:
	var friend := _player(Vector3(3.5, FLOOR, 6.5), 5)
	var a := _arena()
	_run(a, ArenaRules.FIRST_DELAY + 1.0)
	_me.knocked_out = true
	Session.knockout_received.emit(_me.peer_id, true)
	assert_ne(a.phase, ArenaDirector.Phase.OVER, "a friend is still up")
	_me.knocked_out = false
	Session.knockout_respawned.emit(_me.peer_id, true)
	friend.knocked_out = true
	Session.knockout_received.emit(5, true)
	assert_ne(a.phase, ArenaDirector.Phase.OVER, "the first one is back up")
	_me.knocked_out = true
	Session.knockout_received.emit(_me.peer_id, true)
	assert_eq(a.phase, ArenaDirector.Phase.OVER, "both down at once")


func test_every_defeat_pays_a_small_bonus_with_the_combo_and_no_coins() -> void:
	var a := _arena(2)
	_run(a, ArenaRules.FIRST_DELAY + WaveRules.COUNTDOWN + 4.0)
	var list := _waves.wave_monsters()
	assert_gte(list.size(), 3)
	for i in 3:
		_now += 1.0
		list[i].take_hit(100000, _me.global_position, Vector3.ZERO)
	assert_eq(_paid, [[2, 1], [4, 2], [6, 3]], "1, 2, 3 gold × 2 in universe 2")
	assert_eq(_md.coins().size(), 0, "no coins in the arena")
	_now += 6.0
	list[3].take_hit(100000, _me.global_position, Vector3.ZERO)
	assert_eq(_paid.back(), [2, 1], "a new combo after 5 s")
	assert_eq(Profile.data.survivor_gold, 14)


func test_play_again_starts_a_new_run() -> void:
	var a := _arena()
	_run(a, ArenaRules.FIRST_DELAY + 1.0)
	_me.knocked_out = true
	Session.knockout_received.emit(_me.peer_id, true)
	_me.knocked_out = false
	a.request_again()
	assert_eq(a.phase, ArenaDirector.Phase.READY)
	assert_eq(a.cleared, 0)
	assert_almost_eq(a.run_time, 0.0, 0.001)


func test_a_best_is_kept_and_a_shorter_run_is_no_new_best() -> void:
	var a := _arena()
	a.bests["P1"] = {"best_time": 500.0, "best_wave": 6}
	_run(a, ArenaRules.FIRST_DELAY + 2.0)
	_me.knocked_out = true
	Session.knockout_received.emit(_me.peer_id, true)
	assert_false(_results.back().new_best)
	assert_eq(a.bests["P1"], {"best_time": 500.0, "best_wave": 6})


func test_beating_the_raid_boss_offers_the_next_universe_or_stay() -> void:
	var a := _arena(1)
	a.cleared = ArenaRules.FINAL_WAVE - 1
	a.phase = ArenaDirector.Phase.BREATHER
	a.wait_left = 0.1
	_run(a, 0.4)
	_run(a, 30.0)
	_boss.finish(true)
	assert_eq(a.phase, ArenaDirector.Phase.OVER)
	var r: Dictionary = _results.back()
	assert_true(r.won)
	assert_eq(int(r.cleared), ArenaRules.FINAL_WAVE)
	assert_eq(int(r.next), 2, "universe 2 is there: NEXT UNIVERSE is offered")
	assert_eq(int(r.gold), ArenaRules.run_gold(float(r.seconds), ArenaRules.FINAL_WAVE, 1))
	a.request_next()
	assert_eq(_travels, [2] as Array[int])


func test_the_next_universe_is_not_offered_when_it_is_not_built() -> void:
	var a := _arena(3)
	a.cleared = ArenaRules.FINAL_WAVE - 1
	a.phase = ArenaDirector.Phase.BREATHER
	a.wait_left = 0.1
	_run(a, 0.4)
	_boss.finish(true)
	assert_eq(int(_results.back().next), 0, "universe 4 is coming soon: STAY only")
	a.request_next()
	assert_eq(_travels, [] as Array[int])


func test_losing_to_the_raid_boss_ends_the_run() -> void:
	var a := _arena()
	a.cleared = ArenaRules.FINAL_WAVE - 1
	a.phase = ArenaDirector.Phase.BREATHER
	a.wait_left = 0.1
	_run(a, 0.4)
	_boss.finish(false)
	assert_eq(a.phase, ArenaDirector.Phase.OVER)
	assert_false(_results.back().won)
	assert_eq(int(_results.back().cleared), ArenaRules.FINAL_WAVE - 1)


func test_a_knock_out_during_the_boss_puts_it_to_sleep() -> void:
	var a := _arena()
	a.cleared = ArenaRules.FINAL_WAVE - 1
	a.phase = ArenaDirector.Phase.BREATHER
	a.wait_left = 0.1
	_run(a, 0.4)
	_me.knocked_out = true
	Session.knockout_received.emit(_me.peer_id, true)
	assert_eq(_boss.ended, 1)
	assert_eq(a.phase, ArenaDirector.Phase.OVER)
