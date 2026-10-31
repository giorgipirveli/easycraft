extends GutTest
## The host's WaveDirector scales a wave with the team (M4 Wave 2, Agent E; spec §12.8, §17.5):
## players and bot friends when the wave begins (WaveRules.size with the team), the state tells every
## game the team (the Totem panel's count), and a team that changes during a wave keeps its wave.

const FLOOR := 10
const TOTEM := Vector3(0.5, FLOOR, 0.5)
const ME := 1

var _mode_before: StringName
var _md: MonsterDirector
var _team := 1


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_team = 1
	_md = MonsterDirector.new()
	_md.name = "Monsters"
	_md.block_at = func(p: Vector3i) -> int: return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR
	add_child_autofree(_md)


func after_each() -> void:
	Game.mode = _mode_before


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _waves(gentle: bool = false) -> WaveDirector:
	var w := WaveDirector.new()
	w.name = "Waves"
	w.monsters = _md
	w.player_peers = func() -> Array[int]: return [ME] as Array[int]
	w.stand_spot = func(x: int, z: int) -> Vector3: return Vector3(x + 0.5, FLOOR, z + 0.5)
	w.is_ready = func(_p: Vector3) -> bool: return true
	w.eye_of = func(_peer: int) -> Vector3: return TOTEM + Vector3(0, 1.6, -3)
	w.pay = func(_peer: int, _gold: int) -> void: pass
	w.tell = func(_peer: int, _text: String) -> void: pass
	w.team_size = func() -> int: return _team
	w.gentle = gentle
	w.rng.seed = 20260924
	add_child_autofree(w)
	w.set_process(false)
	w.place_totem(TOTEM, 0.0)
	return w


func _run(w: WaveDirector, seconds: float) -> void:
	for i in roundi(seconds / WaveDirector.TICK):
		w.advance(WaveDirector.TICK)


func test_two_players_bring_half_again_as_many_monsters() -> void:
	_team = 2
	var w := _waves()
	assert_eq(int(w.state().team), 2, "every game hears the team (the Totem panel's count)")
	assert_eq(w.request_start(ME, 1), &"")
	_run(w, WaveRules.COUNTDOWN + 0.01)
	_run(w, 4.0)
	assert_eq(w.wave_monsters().size(), 8, "5 x 1.5")
	assert_eq(int(w.state().total), 8)


func test_the_team_is_counted_when_the_wave_begins() -> void:
	var w := _waves()
	assert_eq(w.request_start(ME, 1), &"")
	_team = 3   # a friend and a bot friend arrive during the countdown
	_run(w, WaveRules.COUNTDOWN + 0.01)
	_team = 1   # and leave during the wave
	_run(w, 4.0)
	assert_eq(w.wave_monsters().size(), 10, "5 x 2: the team when it began")
	assert_eq(int(w.state().total), 10)


func test_gentle_waves_stay_gentle_with_a_team() -> void:
	_team = 4
	var w := _waves(true)
	w.next_wave = 3
	assert_eq(w.request_start(ME, 3), &"")
	_run(w, WaveRules.COUNTDOWN + 0.01)
	_run(w, 5.0)
	assert_eq(w.wave_monsters().size(), WaveRules.GENTLE_MAX_SIZE)


func test_by_default_the_team_is_the_players_and_bot_friends_here() -> void:
	var w := WaveDirector.new()
	add_child_autofree(w)
	assert_eq(int(w.team_size.call()), maxi(BotFriend.team_size(get_tree()), 1))
	assert_eq(WaveDirector.team_of(0, 0), 1, "never less than one")


func test_the_totem_panel_counts_the_team() -> void:
	var panel := TotemPanel.new()
	add_child_autofree(panel)
	panel.open(null, {"phase": WaveDirector.Phase.IDLE, "next": 1, "lost": 0, "gentle": false, "boss": false, "team": 3})
	assert_eq(panel.monster_count(), WaveRules.size(1, false, 3))
	panel.open(null, {"phase": WaveDirector.Phase.IDLE, "next": 1, "lost": 0, "gentle": false, "boss": false})
	assert_eq(panel.monster_count(), WaveRules.size(1, false), "an older host's state: one player")
