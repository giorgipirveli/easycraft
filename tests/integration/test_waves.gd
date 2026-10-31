extends GutTest
## M2 Task 9 (spec §12.8, §12.15, research G6): the host's WaveDirector with stubs (like the
## MonsterDirector tests), real monsters and a real Totem. A tap starts wave N after a 5 s countdown;
## 3 + 2N monsters come from the edge of the 25-block circle, a few at a time, heading for the Totem;
## the wave is won when all are defeated, and ends after 3 minutes or when every player was knocked
## out; players not knocked out get 10 × N gold; a win raises N; a wave not won offers itself again
## or one easier; the boss is offered after wave 5; Sandbox waves are gentle and pay nothing.

const FLOOR := 10
const TOTEM := Vector3(0.5, FLOOR, 0.5)
const ME := 1

var _mode_before: StringName
var _md: MonsterDirector
var _peers: Array[int] = []
var _eyes := {}
var _paid: Array = []
var _told: Array = []
var _allowed := true


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_peers = [ME]
	_eyes = {ME: TOTEM + Vector3(0, 1.6, -3)}
	_paid = []
	_told = []
	_allowed = true
	_md = MonsterDirector.new()
	_md.name = "Monsters"
	_md.block_at = _flat
	add_child_autofree(_md)


func after_each() -> void:
	Game.mode = _mode_before


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _flat(p: Vector3i) -> int:
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _waves(gentle: bool = false) -> WaveDirector:
	var w := WaveDirector.new()
	w.name = "Waves"
	w.monsters = _md
	w.player_peers = func() -> Array[int]: return _peers
	w.stand_spot = func(x: int, z: int) -> Vector3: return Vector3(x + 0.5, FLOOR, z + 0.5)
	w.is_ready = func(_p: Vector3) -> bool: return true
	w.eye_of = func(peer: int) -> Vector3: return _eyes.get(peer, Vector3.INF)
	w.pay = func(peer: int, gold: int) -> void: _paid.append([peer, gold])
	w.tell = func(peer: int, text: String) -> void: _told.append([peer, text])
	w.monsters_allowed = func() -> bool: return _allowed
	w.gentle = gentle
	w.rng.seed = 20260924
	add_child_autofree(w)
	w.set_process(false)   # the test drives the clocks
	w.place_totem(TOTEM, 0.0)
	return w


func _run(w: WaveDirector, seconds: float) -> void:
	for i in roundi(seconds / WaveDirector.TICK):
		w.advance(WaveDirector.TICK)


## Starts wave n (a tap from ME) and lets the countdown run out and every monster appear.
func _running(w: WaveDirector, n: int) -> void:
	w.next_wave = maxi(w.next_wave, n)
	assert_eq(w.request_start(ME, n), &"", "wave %d starts" % n)
	_run(w, WaveRules.COUNTDOWN + 0.01)
	_run(w, 3.0)


func _defeat_all(w: WaveDirector) -> void:
	for i in 10:   # split slimes bring small ones
		for m in w.wave_monsters():
			m.take_hit(1000, m.global_position, Vector3.ZERO)
		if w.wave_monsters().is_empty():
			return


# --- Starting a wave ---

func test_a_tap_starts_a_5_second_countdown_then_the_wave() -> void:
	var w := _waves()
	var states: Array = []
	w.state_changed.connect(func(s: Dictionary) -> void: states.append(s))
	assert_eq(w.request_start(ME, 1), &"")
	assert_eq(w.phase, WaveDirector.Phase.COUNTDOWN)
	assert_eq(int(w.state().count), 5)
	assert_true(w.totem().glowing(), "the Totem glows from the countdown on")
	_run(w, 4.0)
	assert_eq(w.phase, WaveDirector.Phase.COUNTDOWN)
	assert_eq(w.wave_monsters().size(), 0, "nothing comes during the countdown")
	_run(w, 1.2)
	assert_eq(w.phase, WaveDirector.Phase.RUNNING)
	var counts: Array[int] = []
	for s: Dictionary in states:
		if int(s.phase) == WaveDirector.Phase.COUNTDOWN:
			counts.append(int(s.count))
	assert_eq(counts, [5, 4, 3, 2, 1] as Array[int], "everyone hears 5… 4… 3… 2… 1…")


func test_wave_monsters_come_a_few_at_a_time_from_the_edge_of_the_circle() -> void:
	var w := _waves()
	w.next_wave = 3
	assert_eq(w.request_start(ME, 3), &"")
	_run(w, WaveRules.COUNTDOWN + 0.01)
	assert_lte(w.wave_monsters().size(), WaveDirector.MAX_SPAWNS_PER_TICK, "a few at a time (the animals' lesson)")
	_run(w, 3.0)
	var list := w.wave_monsters()
	assert_eq(list.size(), WaveRules.size(3, false))
	var roster := WaveRules.roster(3, false)
	var want := {}
	for r: Dictionary in roster:
		var key := "%s%d" % [r.kind, r.level]
		want[key] = int(want.get(key, 0)) + 1
	var got := {}
	for m in list:
		var d := Vector2(m.global_position.x - TOTEM.x, m.global_position.z - TOTEM.z).length()
		assert_almost_eq(d, WaveRules.RING, 1.5, "from the edge of the 25-block circle")
		assert_false(m.wild, "the sun never takes wave monsters away")
		assert_eq(m.wave, 3)
		assert_eq(m.goal, TOTEM, "they head for the Totem")
		var key := "%s%d" % [m.kind, m.level]
		got[key] = int(got.get(key, 0)) + 1
	assert_eq(got, want, "the wave's own monsters and levels")
	assert_eq(int(w.state().left), list.size())


func test_the_hud_line_counts_monsters_left() -> void:
	var w := _waves()
	_running(w, 2)
	assert_eq(int(w.state().left), 7)
	w.wave_monsters()[0].take_hit(1000, TOTEM, Vector3.ZERO)
	assert_eq(int(w.state().left), 6)


func test_only_the_totems_wave_may_start_and_only_near_it() -> void:
	var w := _waves()
	w.next_wave = 3
	assert_eq(w.request_start(ME, 2), &"not_offered", "no easier wave before one was tried")
	assert_eq(w.request_start(ME, 4), &"not_offered", "never above N")
	assert_eq(w.phase, WaveDirector.Phase.IDLE)
	_eyes[ME] = TOTEM + Vector3(0, 1.6, -12)
	assert_eq(w.request_start(ME, 3), &"too_far")
	assert_true(_told.has([ME, WaveRules.refusal_message(&"too_far")]), "the child hears why")
	_eyes[ME] = TOTEM + Vector3(0, 1.6, -3)
	assert_eq(w.request_start(ME, 3), &"")
	assert_eq(w.request_start(ME, 3), &"busy", "one wave at a time")


func test_a_guest_without_a_body_cannot_start_a_wave() -> void:
	var w := _waves()
	assert_eq(w.request_start(42, 1), &"too_far")
	assert_eq(w.phase, WaveDirector.Phase.IDLE)


func test_waves_can_start_by_day_or_by_night() -> void:
	# Nothing about the clock is asked: the Totem works whenever the child is ready.
	var w := _waves()
	assert_eq(w.request_start(ME, 1), &"")


func test_night_monsters_stop_while_a_wave_runs() -> void:
	var w := _waves()
	var night := w.night_allowed(func() -> bool: return true)
	assert_true(night.call())
	w.request_start(ME, 1)
	assert_false(night.call(), "wild ones puff away and none come during a wave")
	w.stop()
	assert_true(night.call())


# --- How a wave ends ---

func test_a_won_wave_pays_players_still_standing_and_raises_n() -> void:
	_peers = [ME, 7]
	var w := _waves()
	var ends: Array = []
	var nexts: Array = []
	w.wave_ended.connect(func(n: int, r: StringName) -> void: ends.append([n, r]))
	w.next_changed.connect(func(n: int) -> void: nexts.append(n))
	_running(w, 2)
	_defeat_all(w)
	_run(w, 0.4)
	assert_eq(ends, [[2, WaveRules.WON]])
	assert_eq(_paid, [[ME, 20], [7, 20]], "10 × N gold each")
	assert_eq(w.next_wave, 3, "a win raises N")
	assert_eq(nexts, [3], "the sandbox saves it")
	assert_eq(w.phase, WaveDirector.Phase.IDLE)
	assert_false(w.totem().glowing())
	assert_true(_told.has([ME, WaveRules.won_message(2, 20)]))


## M3 Task 9 (the avatar editor's celebrations): a won wave makes everyone dance, once; a lost one never.
func test_a_won_wave_starts_the_victory_celebration_once() -> void:
	_peers = [ME]
	var w := _waves()
	var parties := [0]
	w.celebrate = func() -> void: parties[0] += 1
	_running(w, 1)
	_defeat_all(w)
	_run(w, 0.4)
	assert_eq(parties[0], 1)
	_running(w, 2)
	Session.knockout_received.emit(ME, true)
	_run(w, 0.4)
	assert_eq(parties[0], 1, "no party for a wave not won")


func test_a_player_knocked_out_during_the_wave_is_not_paid() -> void:
	_peers = [ME, 7]
	var w := _waves()
	Session.knockout_received.emit(7, true)   # before the wave: doesn't count
	_running(w, 1)
	Session.knockout_received.emit(7, true)
	_defeat_all(w)
	_run(w, 0.4)
	assert_eq(_paid, [[ME, 10]])
	assert_true(_told.has([7, WaveRules.no_gold_message(1)]), "told kindly why")
	assert_eq(w.next_wave, 2, "the team still won")


func test_a_knock_out_during_the_countdown_does_not_count() -> void:
	var w := _waves()
	w.request_start(ME, 1)
	Session.knockout_received.emit(ME, true)
	_run(w, WaveRules.COUNTDOWN + 3.0)
	assert_eq(w.phase, WaveDirector.Phase.RUNNING)
	_defeat_all(w)
	_run(w, 0.4)
	assert_eq(_paid, [[ME, 10]])


func test_the_wave_ends_when_every_player_was_knocked_out() -> void:
	_peers = [ME, 7]
	var w := _waves()
	var ends: Array = []
	w.wave_ended.connect(func(n: int, r: StringName) -> void: ends.append([n, r]))
	_running(w, 2)
	Session.knockout_received.emit(ME, true)
	_run(w, 0.4)
	assert_eq(w.phase, WaveDirector.Phase.RUNNING, "someone is still standing")
	Session.knockout_received.emit(7, true)
	_run(w, 0.4)
	assert_eq(ends, [[2, WaveRules.KNOCKED_OUT]])
	assert_eq(w.wave_monsters().size(), 0, "the monsters go home")
	assert_eq(_paid, [])
	assert_eq(w.next_wave, 2, "N stays")
	assert_eq(w.lost, 2)


func test_the_wave_ends_after_3_minutes() -> void:
	var w := _waves()
	var ends: Array = []
	w.wave_ended.connect(func(n: int, r: StringName) -> void: ends.append([n, r]))
	_running(w, 4)
	w.wave_monsters()[0].take_hit(1000, TOTEM, Vector3.ZERO)
	_run(w, WaveRules.TIME_LIMIT - 4.0)
	assert_eq(w.phase, WaveDirector.Phase.RUNNING)
	_run(w, 2.0)
	assert_eq(ends, [[4, WaveRules.TIME_UP]])
	assert_eq(w.wave_monsters().size(), 0, "the rest puff away (no coins)")
	assert_eq(_paid, [])
	assert_eq(w.next_wave, 4, "N rises on a win only")
	assert_true(_told.has([ME, WaveRules.lost_message(WaveRules.TIME_UP)]))


func test_wave_monsters_never_leave_for_being_far_from_players() -> void:
	var w := _waves()
	_running(w, 1)
	_md.player_positions = func() -> Array[Vector3]: return [Vector3(500, FLOOR, 500)] as Array[Vector3]
	_md.time_of_day = func() -> float: return DayCycle.NOON
	_md.enabled = func() -> bool: return true
	_md.tick()
	assert_eq(w.wave_monsters().size(), 5, "running away never wins a wave")


func test_a_split_wave_slime_brings_its_small_ones_into_the_wave() -> void:
	var w := _waves()
	_running(w, 5)   # levels 3 and 4: slimes split
	var before := int(w.state().left)
	var big: Monster = null
	for m in w.wave_monsters():
		if MonsterRules.splits(m.kind, m.level):
			big = m
			break
	assert_not_null(big)
	big.take_hit(1000, TOTEM, Vector3.ZERO)
	assert_eq(int(w.state().left), before + 1, "one gone, two small ones came")
	for m in w.wave_monsters():
		assert_eq(m.wave, 5)
		assert_eq(m.goal, TOTEM)


func test_a_wave_monster_stuck_far_from_the_totem_is_called_closer() -> void:
	# A slime stuck behind a river would make the wave impossible to win: the Totem calls it closer.
	var w := _waves()
	_running(w, 1)
	_run(w, WaveDirector.STUCK_TIME - 4.0)
	for m in w.wave_monsters():
		var d := Vector2(m.global_position.x - TOTEM.x, m.global_position.z - TOTEM.z).length()
		assert_gt(d, 20.0, "not yet: they may still be on their way")
	_run(w, 6.0)
	for m in w.wave_monsters():
		var d := Vector2(m.global_position.x - TOTEM.x, m.global_position.z - TOTEM.z).length()
		assert_between(d, 6.0, WaveDirector.CALL_RADIUS + 1.5, "called to the Totem")


func test_a_wave_monster_chasing_someone_is_never_called() -> void:
	var w := _waves()
	_running(w, 1)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = "1"
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	var m := w.wave_monsters()[0]
	p.global_position = m.global_position + Vector3(1, 0, 0)
	await get_tree().physics_frame   # monsters look players up once per physics frame
	var at := m.global_position
	m.take_hit(0, p.global_position, Vector3.ZERO)   # it turns on the player
	assert_not_null(m.target())
	_run(w, WaveDirector.STUCK_TIME + 2.0)
	assert_eq(m.global_position, at, "busy with a player: left alone")


# --- Try again, try an easier wave, the boss ---

func test_a_wave_not_won_offers_itself_again_or_one_easier() -> void:
	var w := _waves()
	_running(w, 4)
	_run(w, WaveRules.TIME_LIMIT)
	assert_eq(w.lost, 4)
	var s := w.state()
	assert_eq(int(s.lost), 4, "the Totem offers wave 4 again")
	assert_eq(w.request_start(ME, 2), &"not_offered")
	assert_eq(w.request_start(ME, 3), &"", "try an easier wave")
	_run(w, WaveRules.COUNTDOWN + 3.0)
	assert_eq(w.wave_monsters().size(), WaveRules.size(3, false), "a normal wave 3")
	_defeat_all(w)
	_run(w, 0.4)
	assert_eq(_paid, [[ME, 30]], "the easier wave pays the normal gold")
	assert_eq(w.next_wave, 4, "winning an easier wave keeps N")
	assert_eq(w.lost, 0, "a win clears the offer")


func test_try_again_replays_the_same_wave() -> void:
	var w := _waves()
	_running(w, 2)
	_run(w, WaveRules.TIME_LIMIT)
	assert_eq(w.request_start(ME, 2), &"")
	_run(w, WaveRules.COUNTDOWN + 3.0)
	assert_eq(w.wave_monsters().size(), WaveRules.size(2, false))


func test_the_boss_is_offered_after_wave_5_is_won() -> void:
	var w := _waves()
	var offers: Array = []
	var asks: Array = []
	w.boss_offered.connect(func(at: Vector3) -> void: offers.append(at))
	w.boss_requested.connect(func(peer: int, at: Vector3) -> void: asks.append([peer, at]))
	assert_false(w.boss_available())
	assert_eq(w.request_boss(ME), &"no_boss")
	_running(w, 4)
	_defeat_all(w)
	_run(w, 0.4)
	assert_eq(offers, [], "not after wave 4")
	_running(w, 5)
	_defeat_all(w)
	_run(w, 0.4)
	assert_eq(offers, [TOTEM])
	assert_true(w.boss_available())
	assert_true(bool(w.state().boss), "everyone's Totem shows the boss")
	_eyes[ME] = TOTEM + Vector3(0, 1.6, -12)
	assert_eq(w.request_boss(ME), &"too_far")
	_eyes[ME] = TOTEM + Vector3(0, 1.6, -3)
	assert_eq(w.request_boss(ME), &"")
	assert_eq(asks, [[ME, TOTEM]], "Task 10 hears it and brings the Stone Golem")


func test_while_the_boss_fights_no_wave_starts_and_the_totem_glows() -> void:
	var w := _waves()
	w.next_wave = 6
	w.set_boss_running(true)
	assert_eq(w.phase, WaveDirector.Phase.BOSS)
	assert_true(w.totem().glowing())
	assert_eq(w.request_start(ME, 6), &"boss")
	assert_eq(w.request_boss(ME), &"boss")
	w.set_boss_running(false)
	assert_eq(w.phase, WaveDirector.Phase.IDLE)
	assert_false(w.totem().glowing())


func test_asking_for_the_boss_with_nobody_to_bring_it_says_so() -> void:
	var w := _waves()
	w.next_wave = 6
	assert_eq(w.request_boss(ME), &"asleep")
	assert_true(_told.has([ME, WaveRules.refusal_message(&"asleep")]))


# --- Sandbox ---

func test_sandbox_waves_are_gentle_and_pay_nothing() -> void:
	Game.mode = ModeRules.SANDBOX
	var w := _waves(true)
	_running(w, 9)
	var list := w.wave_monsters()
	assert_eq(list.size(), 8, "8 at most")
	for m in list:
		assert_lte(m.level, 2)
	_defeat_all(w)
	_run(w, 0.4)
	assert_eq(_paid, [], "Sandbox gold is ∞")
	assert_true(_told.has([ME, WaveRules.won_message(9, 0)]))
	assert_eq(w.next_wave, 10)


func test_sandbox_with_monsters_off_has_no_waves_and_off_ends_one() -> void:
	Game.mode = ModeRules.SANDBOX
	var w := _waves(true)
	_running(w, 1)
	_allowed = false
	w.stop()
	assert_eq(w.phase, WaveDirector.Phase.IDLE)
	assert_eq(w.wave_monsters().size(), 0)
	assert_eq(w.next_wave, 1)
	assert_eq(w.lost, 0, "switched off: nobody lost anything")
	assert_eq(w.request_start(ME, 1), &"off")


# --- Everyone sees it (LAN) ---

func test_the_state_reaches_every_game_and_their_totem() -> void:
	var w := _waves()
	var s := w.state()
	assert_eq(int(s.phase), WaveDirector.Phase.IDLE)
	assert_eq(int(s.next), 1)
	# A guest's director: it only mirrors what the host sends.
	var guest := WaveDirector.new()
	guest.name = "GuestWaves"
	add_child_autofree(guest)
	guest.set_process(false)
	var t := Totem.new()
	t.setup({"pos": TOTEM + Vector3(40, 0, 0), "yaw": 0.0})
	add_child_autofree(t)
	guest.watch_totem(t)
	var seen: Array = []
	guest.state_changed.connect(func(st: Dictionary) -> void: seen.append(st))
	w.request_start(ME, 1)
	guest.apply_state(w.state())
	assert_eq(seen.size(), 1)
	assert_true(t.glowing(), "the guest's Totem glows too")
	assert_eq(t.label_text(), "5")
	_run(w, WaveRules.COUNTDOWN + 3.0)
	guest.apply_state(w.state())
	assert_eq(int(guest.current.left), 5)
	assert_eq(t.label_text(), "5 left")
