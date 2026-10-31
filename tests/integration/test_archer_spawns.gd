extends GutTest
## M3 Task 14b: where goblin archers come from. At night some goblins of level 2 and up carry a bow (never a
## level 1 one); Totem waves bring archers from wave 4 on; /summon archer calls one (Sandbox).

const FLOOR := 10
const TOTEM := Vector3(0.5, FLOOR, 0.5)
const ME := 1

var _mode_before: StringName
var _players: Array[Vector3] = []


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_players = [Vector3(0.5, FLOOR, 0.5)]


func after_each() -> void:
	Game.mode = _mode_before


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _flat(p: Vector3i) -> int:
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _monsters(spawn: Vector3) -> MonsterDirector:
	var d := MonsterDirector.new()
	d.name = "Monsters"
	d.player_positions = func() -> Array[Vector3]: return _players
	d.is_ready = func(_p: Vector3) -> bool: return true
	d.stand_spot = func(x: int, z: int) -> Vector3: return Vector3(x + 0.5, FLOOR, z + 0.5)
	d.lights_near = func(_p: Vector3) -> Array[Vector3i]: return [] as Array[Vector3i]
	d.home_beds = func() -> Array[Vector3i]: return [] as Array[Vector3i]
	d.time_of_day = func() -> float: return DayCycle.MIDNIGHT
	d.enabled = func() -> bool: return true
	d.block_at = _flat
	d.world_spawn = spawn
	d.rng.seed = 20260924
	add_child_autofree(d)
	d.set_process(false)
	return d


## Night after night (monsters sent home between ticks), what kinds and levels come.
func _night_kinds(d: MonsterDirector, ticks: int) -> Array:
	var seen: Array = []
	for i in ticks:
		d.tick()
		for m in d.monsters():
			seen.append([m.kind, m.level])
			m.free()
	return seen


func test_night_goblins_of_level_2_and_up_sometimes_carry_bows() -> void:
	var d := _monsters(Vector3(400.5, 0, 0.5))    # far from the world spawn: levels 2-4
	var seen := _night_kinds(d, 40)
	var archers := seen.filter(func(e: Array) -> bool: return e[0] == MonsterRules.ARCHER)
	var goblins := seen.filter(func(e: Array) -> bool: return e[0] == MonsterRules.GOBLIN)
	assert_gt(archers.size(), 0, "archers at night")
	assert_gt(goblins.size(), 0, "and plain goblins")
	for e: Array in archers:
		assert_gte(int(e[1]), ArcherRules.NIGHT_MIN_LEVEL)


func test_level_1_goblins_never_carry_a_bow() -> void:
	var d := _monsters(Vector3(0.5, 0, 0.5))      # at the world spawn: levels 1-2
	for e: Array in _night_kinds(d, 40):
		if e[0] == MonsterRules.ARCHER:
			assert_gte(int(e[1]), 2)


func test_waves_bring_archers_from_wave_4() -> void:
	var md := _monsters(Vector3.ZERO)
	for n in [3, 4]:
		var w := WaveDirector.new()
		w.name = "Waves%d" % n
		w.monsters = md
		w.player_peers = func() -> Array[int]: return [ME] as Array[int]
		w.stand_spot = func(x: int, z: int) -> Vector3: return Vector3(x + 0.5, FLOOR, z + 0.5)
		w.is_ready = func(_p: Vector3) -> bool: return true
		w.eye_of = func(_peer: int) -> Vector3: return TOTEM + Vector3(0, 1.6, -3)
		w.pay = func(_peer: int, _gold: int) -> void: pass
		w.tell = func(_peer: int, _text: String) -> void: pass
		w.rng.seed = 20260924
		add_child_autofree(w)
		w.set_process(false)
		w.place_totem(TOTEM, 0.0)
		w.next_wave = n
		assert_eq(w.request_start(ME, n), &"")
		for i in roundi((WaveRules.COUNTDOWN + 4.0) / WaveDirector.TICK):
			w.advance(WaveDirector.TICK)
		var archers := w.wave_monsters().filter(func(m: Monster) -> bool: return m.kind == MonsterRules.ARCHER).size()
		if n < ArcherRules.WAVE_FROM:
			assert_eq(archers, 0, "wave %d: no archers yet" % n)
		else:
			assert_gt(archers, 0, "wave %d: archers" % n)
		w.stop()
		for m in md.monsters():
			m.free()


func test_summon_archer_calls_one() -> void:
	var d := _monsters(Vector3.ZERO)
	assert_eq(d.summon(MonsterRules.ARCHER, 2, Vector3(0.5, FLOOR, 0.5)), "")
	assert_eq(d.monsters().size(), 1)
	assert_eq(d.monsters()[0].kind, MonsterRules.ARCHER)
	assert_eq(ChatCommands.host_check("/summon archer 2", true, ModeRules.SANDBOX).get("monster"), MonsterRules.ARCHER)
