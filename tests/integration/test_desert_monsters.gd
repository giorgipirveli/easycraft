extends GutTest
## M3 Task 2 (spec §14.1): the Sandstorm Desert's monsters in the world. The mummy (a slow tank) raises
## its arms before its heavy grab, is hard to push, and at level 3+ unwraps into a crawling top and walking
## legs (through the MonsterDirector); the scorpion (a spitter) keeps its distance, raises its glowing tail
## and spits a glob that leads a running child a little and hits only where it lands, so a sidestep
## dodges it. The night spawns and waves of a desert world bring them. They never change blocks (the M2
## tests that loop over MonsterRules.KINDS cover doors, lanterns and edits for them too).

const FLOOR := 10
const DT := 1.0 / 60.0

var _mode_before: StringName
var _n := 0
var _players: Array[Vector3] = []


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_players = [Vector3(0.5, FLOOR, 0.5)]


func after_each() -> void:
	Game.mode = _mode_before
	Session.survivor_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _flat(p: Vector3i) -> int:
	return BlockIds.SAND if p.y < FLOOR else BlockIds.AIR


func _monster(kind: StringName, level: int, pos: Vector3, yaw: float = 0.0, half: int = 0) -> Monster:
	_n += 1
	var m := Monster.new()
	m.setup({"kind": kind, "level": level, "id": "dm%d" % _n, "pos": pos, "yaw": yaw, "wild": true, "universe": 2,
		"half": half})
	m.block_at = _flat
	add_child_autofree(m)
	m.set_physics_process(false)
	return m


func _ground() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	ground.global_position = Vector3(0, FLOOR - 0.5, 0)


func _player(feet: Vector3, peer: int = 1) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _steps(m: Monster, n: int) -> void:
	for i in n:
		if is_instance_valid(m):
			m._physics_process(DT)


func _steps_until(m: Monster, done: Callable, limit: int = 120) -> void:
	for i in limit:
		if done.call():
			return
		_steps(m, 1)


# --- The mummy -------------------------------------------------------------------------------------

func test_a_mummy_raises_its_arms_for_longer_than_a_goblin_then_grabs() -> void:
	_ground()
	var m := _monster(MonsterRules.MUMMY, 1, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -0.9))
	await get_tree().physics_frame
	_steps_until(m, func() -> bool: return m.state == Monster.State.WINDUP)
	assert_eq(m.state, Monster.State.WINDUP)
	assert_true(m.winding, "everyone sees the arms go up")
	_steps(m, int(MonsterRules.GOBLIN_WINDUP / DT) + 2)
	assert_eq(p.health.hp, Health.MAX_HP, "still winding up after a goblin's time")
	_steps(m, int((MonsterRules.MUMMY_WINDUP - MonsterRules.GOBLIN_WINDUP) / DT) + 4)
	assert_eq(p.health.hp, Health.MAX_HP - MonsterRules.hit(MonsterRules.MUMMY, 1, 2), "the grab lands")


func test_stepping_back_dodges_the_mummys_grab() -> void:
	_ground()
	var m := _monster(MonsterRules.MUMMY, 2, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -0.9))
	await get_tree().physics_frame
	_steps_until(m, func() -> bool: return m.state == Monster.State.WINDUP)
	p.global_position = Vector3(0.5, FLOOR, -5.5)
	_steps(m, int(MonsterRules.MUMMY_WINDUP / DT) + 4)
	assert_eq(p.health.hp, Health.MAX_HP, "missed")


func test_a_mummy_is_slow_and_hard_to_push() -> void:
	var m := _monster(MonsterRules.MUMMY, 3, Vector3(0.5, 40, 0.5))
	m.take_hit(1, Vector3(0.5, 40, 2.5), Vector3(0, 3, -6))
	assert_almost_eq(m.velocity, Vector3(0, 3, -6) * MonsterRules.MUMMY_PUSH, Vector3.ONE * 0.01)
	assert_eq(m.hp, MonsterRules.hp(MonsterRules.MUMMY, 3, 2) - 1, "universe 2's health")


func test_a_big_mummy_unwraps_into_a_top_and_legs() -> void:
	var d := MonsterDirector.new()
	d.name = "Monsters"
	d.player_positions = func() -> Array[Vector3]: return _players
	d.block_at = _flat
	d.universe = 2
	add_child_autofree(d)
	var big := d.spawn_monster({"kind": MonsterRules.MUMMY, "level": 4, "id": "big", "pos": Vector3(0.5, FLOOR, 0.5),
		"yaw": 0.0, "wild": true, "universe": 2})
	big.take_hit(1000, Vector3(0.5, FLOOR, 2.5), Vector3.ZERO)
	await get_tree().process_frame
	var halves: Array[int] = []
	for m in d.monsters():
		assert_eq(m.kind, MonsterRules.MUMMY)
		assert_eq(m.level, 1)
		assert_eq(m.max_hp, MonsterRules.hp(MonsterRules.MUMMY, 1, 2, m.half))
		halves.append(m.half)
	halves.sort()
	assert_eq(halves, [MonsterRules.HALF_TOP, MonsterRules.HALF_LEGS], "a crawling top and walking legs")
	var top: Monster = d.monsters().filter(func(m: Monster) -> bool: return m.half == MonsterRules.HALF_TOP)[0]
	top.take_hit(1000, Vector3.ZERO, Vector3.ZERO)
	await get_tree().process_frame
	assert_eq(d.monsters().size(), 1, "a half never unwraps again")


func test_the_halves_look_different_from_a_whole_mummy() -> void:
	var whole := MonsterModels.mesh_for(MonsterRules.MUMMY, 1)
	var top := MonsterModels.mesh_for(MonsterRules.MUMMY, 1, MonsterRules.HALF_TOP)
	var legs := MonsterModels.mesh_for(MonsterRules.MUMMY, 1, MonsterRules.HALF_LEGS)
	assert_ne(top, whole)
	assert_ne(legs, whole)
	assert_lt(top.get_aabb().size.y, whole.get_aabb().size.y * 0.7)
	assert_lt(legs.get_aabb().size.y, whole.get_aabb().size.y * 0.7)
	assert_null(MonsterModels.arm_mesh_for(MonsterRules.MUMMY, 1, MonsterRules.HALF_LEGS), "legs have no arms")
	assert_not_null(MonsterModels.arm_mesh_for(MonsterRules.MUMMY, 1, MonsterRules.HALF_TOP), "the top still grabs")
	var m := _monster(MonsterRules.MUMMY, 1, Vector3(0.5, 40, 0.5), 0.0, MonsterRules.HALF_LEGS)
	assert_lt(m.size().y, MonsterRules.size_of(MonsterRules.MUMMY, 1).y * 0.7)


# --- The scorpion ------------------------------------------------------------------------------------

func test_a_scorpion_keeps_its_distance() -> void:
	_ground()
	var s := _monster(MonsterRules.SCORPION, 1, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -12.5))
	await get_tree().physics_frame
	var closest := [INF]
	for i in 300:
		_steps(s, 1)
		closest[0] = minf(closest[0], Vector2(s.global_position.x - p.global_position.x, s.global_position.z - p.global_position.z).length())
	assert_lt(s.global_position.z, -1.0, "it comes closer ...")
	assert_gt(closest[0], MonsterRules.SPIT_TOO_CLOSE - 0.5, "... but never right up to the child (%.1f)" % closest[0])


func test_a_scorpion_backs_off_from_a_child_who_comes_close() -> void:
	_ground()
	var s := _monster(MonsterRules.SCORPION, 2, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -1.5))
	await get_tree().physics_frame
	for i in 240:                   # it may spit first (signalled), then it steps back while its tail rests
		_steps(s, 1)
	assert_gt(Vector2(s.global_position.x - p.global_position.x, s.global_position.z - p.global_position.z).length(),
		MonsterRules.SPIT_TOO_CLOSE - 0.3, "it stepped back from 2 blocks")


func _winds_up_and_spits(s: Monster) -> void:
	_steps_until(s, func() -> bool: return s.state == Monster.State.WINDUP, 180)
	assert_eq(s.state, Monster.State.WINDUP)
	assert_true(s.winding, "everyone sees the tail go up")
	_steps_until(s, func() -> bool: return s.globs_in_flight() > 0, int(MonsterRules.SCORPION_WINDUP / DT) + 4)
	assert_eq(s.globs_in_flight(), 1, "then the glob flies")


func test_a_scorpion_signals_then_spits_and_a_child_who_stands_still_is_hit() -> void:
	_ground()
	var s := _monster(MonsterRules.SCORPION, 1, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -6.5))
	await get_tree().physics_frame
	_winds_up_and_spits(s)
	assert_eq(p.health.hp, Health.MAX_HP, "nothing yet: it is flying")
	_steps_until(s, func() -> bool: return s.globs_in_flight() == 0, 120)
	assert_eq(p.health.hp, Health.MAX_HP - MonsterRules.hit(MonsterRules.SCORPION, 1, 2), "the glob lands on them")


func test_a_sidestep_during_the_flight_dodges_the_glob() -> void:
	_ground()
	var s := _monster(MonsterRules.SCORPION, 1, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -6.5))
	await get_tree().physics_frame
	_winds_up_and_spits(s)
	p.global_position += Vector3(2.5, 0, 0)
	_steps_until(s, func() -> bool: return s.globs_in_flight() == 0, 120)
	assert_eq(p.health.hp, Health.MAX_HP, "dodged")


func test_the_spit_leads_a_running_child() -> void:
	_ground()
	var s := _monster(MonsterRules.SCORPION, 1, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -7.5))
	p.velocity = Vector3(3.0, 0.0, 0.0)
	await get_tree().physics_frame
	_winds_up_and_spits(s)
	var landing: Vector3 = s.glob_landing(0)
	assert_gt(landing.x, p.global_position.x + 1.0, "aimed where the runner is going")
	assert_lte(landing.x - p.global_position.x, MonsterRules.MAX_LEAD + 0.01)


func test_the_tail_glows_while_it_winds_up() -> void:
	var s := _monster(MonsterRules.SCORPION, 3, Vector3(0.5, 40, 0.5))
	var tail := s.find_child("Arm", true, false) as Node3D
	assert_not_null(tail, "the tail turns on its own pivot")
	var mesh := (tail.get_child(0) as MeshInstance3D)
	var calm := mesh.mesh
	s.winding = true
	s._process(DT)
	assert_ne(mesh.mesh, calm, "a glowing tail while it winds up")
	assert_same(mesh.mesh, MonsterModels.arm_mesh_for(MonsterRules.SCORPION, 3, 0, true), "a shared mesh")
	s.winding = false
	s._process(DT)
	assert_same(mesh.mesh, calm)


# --- The desert's nights and waves ---------------------------------------------------------------------

func test_a_desert_night_brings_mummies_and_scorpions() -> void:
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
	d.kinds = MonsterRules.DESERT_KINDS
	d.universe = 2
	d.rng.seed = 7
	add_child_autofree(d)
	var seen := {}
	for i in 8:
		d.tick()
	for m in d.monsters():
		seen[m.kind] = true
		assert_eq(m.universe, 2)
	assert_eq(seen.keys().size(), 2, "%s" % [seen.keys()])
	assert_true(seen.has(MonsterRules.MUMMY) and seen.has(MonsterRules.SCORPION))


func test_a_desert_totem_wave_brings_mummies_and_scorpions() -> void:
	var roster := WaveRules.roster(3, false, 1, MonsterRules.DESERT_KINDS)
	var kinds := {}
	for m: Dictionary in roster:
		kinds[m.kind] = true
	assert_eq(kinds.keys().size(), 2)
	assert_true(kinds.has(MonsterRules.MUMMY) and kinds.has(MonsterRules.SCORPION))
	assert_eq(WaveRules.roster(3, false), WaveRules.roster(3, false, 1, MonsterRules.MEADOWS_KINDS), "Green Meadows' waves unchanged")
	assert_eq(WaveRules.BOSS_AFTER, 5, "five waves before the boss")
