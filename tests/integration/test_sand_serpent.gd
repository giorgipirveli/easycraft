extends GutTest
## M3 Task 2 (spec §14.1): the Sand Serpent as an entity. It fits the BossDirector like the Golem (it is a
## StoneGolem to it: health bar, honest help, win and loss), draws with shared meshes, can be hit only
## while it is out of the sand, swims under the sand towards a child, shakes the sand where it will burst
## (a child who steps away is safe), sweeps its tail (a jump clears it; then it is dizzy: double damage),
## spits a ball of sand, plays the boss music, and never changes a block. Solo: this game is the host.

const FLOOR := 10
const DT := 1.0 / 60.0
const P := SerpentRules.Phase

var _mode_before: StringName
var _hurts: Array = []
var _n := 0


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_hurts.clear()
	Session.player_hurt.connect(_on_hurt)


func after_each() -> void:
	Session.player_hurt.disconnect(_on_hurt)
	Game.mode = _mode_before
	Session.survivor_reset()
	Music.reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_hurt(peer: int, hp: int, from: Vector3) -> void:
	_hurts.append([peer, hp, from])


func _flat(p: Vector3i) -> int:
	return BlockIds.SAND if p.y < FLOOR else BlockIds.AIR


func _serpent(pos: Vector3 = Vector3(0.5, FLOOR, 0.5), max_hp: int = 360, tired: bool = false) -> SandSerpent:
	_n += 1
	var s := SandSerpent.new()
	s.setup({"id": "s%d" % _n, "pos": pos, "yaw": 0.0, "max_hp": max_hp, "tired": tired})
	s.block_at = _flat
	add_child_autofree(s)
	s.set_physics_process(false)
	return s


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _steps(s: SandSerpent, n: int) -> void:
	for i in n:
		if is_instance_valid(s):
			s._physics_process(DT)


func _steps_until(s: SandSerpent, done: Callable, limit: int = 900) -> int:
	for i in limit:
		if done.call():
			return i
		_steps(s, 1)
	return limit


func test_it_is_a_boss_the_director_knows_with_shared_meshes() -> void:
	var a := _serpent()
	var b := _serpent(Vector3(10.5, FLOOR, 0.5))
	assert_true(a is StoneGolem, "the BossDirector's fights, bar and help work unchanged")
	assert_true(a.is_in_group(&"monsters"), "weapons and bot friends find it")
	assert_eq(a.collision_mask, 1)
	var shapes := a.find_children("*", "CollisionShape3D", false, false)
	assert_eq(shapes.size(), 1)
	var box := (shapes[0] as CollisionShape3D).shape as BoxShape3D
	assert_lte(maxf(box.size.x, box.size.z), Buddy.MAX_FOOTPRINT, "a small footprint")
	var meshes_a := a.find_children("*", "MeshInstance3D", true, false).map(func(m: MeshInstance3D) -> Mesh: return m.mesh)
	var meshes_b := b.find_children("*", "MeshInstance3D", true, false).map(func(m: MeshInstance3D) -> Mesh: return m.mesh)
	assert_eq(meshes_a, meshes_b, "every serpent shares the same meshes")
	assert_same(SerpentModels.head_mesh().surface_get_material(0), BlockyAnimal.mesh_for(&"pig").surface_get_material(0),
		"the animals' material: no new shader")
	assert_eq(a.boss_kind(), BossRules.SERPENT)


func test_it_can_be_hit_only_out_of_the_sand() -> void:
	var s := _serpent()
	assert_eq(s.phase, P.RISE)
	s.take_hit(50, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(s.hp, 360, "rising: not yet")
	s.start_phase(P.DIVE)
	s.take_hit(50, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(s.hp, 360, "under the sand")
	assert_eq(s.collision_layer, 0, "weapon taps pass over the sand")
	s.start_phase(P.UP)
	assert_eq(s.collision_layer, Monster.LAYER, "up: a target")
	s.take_hit(50, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(s.hp, 310)
	s.start_phase(P.DIZZY)
	assert_true(s.is_dazed(), "the boss bar's x2 chip")
	s.take_hit(10, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(s.hp, 290, "dizzy: double")
	var defeats: Array = []
	s.defeated.connect(func(x: StoneGolem) -> void: defeats.append(x))
	s.take_hit(1000, Vector3(0, FLOOR, 3), Vector3.ZERO)
	s.take_hit(1000, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(defeats.size(), 1)
	assert_true(s.is_down())


func test_the_schedule_runs_in_order_with_its_signals() -> void:
	var s := _serpent()
	_player(Vector3(0.5, FLOOR, 12.5))
	await get_tree().physics_frame
	var seen: Array = [s.phase]
	for i in int(30.0 / DT):
		_steps(s, 1)
		if s.phase != seen[-1]:
			seen.append(s.phase)
	assert_eq(seen.slice(0, 12), [P.RISE, P.UP, P.SWEEP_WARN, P.DIZZY, P.DIVE, P.WARN, P.BURST, P.UP, P.SPIT_WARN,
		P.DIVE, P.WARN, P.BURST])


func test_under_the_sand_it_swims_to_the_child_and_bursts_where_they_stood() -> void:
	var s := _serpent()
	var p := _player(Vector3(8.5, FLOOR, 0.5))
	await get_tree().physics_frame
	s.start_phase(P.DIVE)
	_steps_until(s, func() -> bool: return s.phase == P.WARN)
	assert_lt(Vector2(s.global_position.x - 8.5, s.global_position.z - 0.5).length(), 1.0, "right under the child")
	var spot := s.burst_spot()
	assert_almost_eq(spot.x, 8.5, 1.0)
	_steps_until(s, func() -> bool: return s.phase == P.UP)
	assert_eq(_hurts.size(), 1, "a child who stayed on the shaking sand is hit")
	assert_eq(p.health.hp, Health.MAX_HP - SerpentRules.damage(SerpentRules.BURST))


func test_a_child_who_steps_off_the_shaking_sand_is_safe() -> void:
	var s := _serpent()
	var p := _player(Vector3(8.5, FLOOR, 0.5))
	await get_tree().physics_frame
	s.start_phase(P.DIVE)
	_steps_until(s, func() -> bool: return s.phase == P.WARN)
	p.global_position += Vector3(0, 0, 4.0)
	_steps_until(s, func() -> bool: return s.phase == P.UP)
	assert_eq(_hurts.size(), 0, "stepped away")


func test_the_tail_sweep_hurts_the_ground_around_it_and_then_it_is_dizzy() -> void:
	var s := _serpent()
	var p := _player(Vector3(0.5, FLOOR, 3.5))
	await get_tree().physics_frame
	s.start_phase(P.SWEEP_WARN)
	var frames := _steps_until(s, func() -> bool: return not _hurts.is_empty(), 200)
	assert_almost_eq(frames * DT, SerpentRules.SWEEP_WINDUP, 3 * DT, "it lands as the wind-up ends")
	assert_eq(p.health.hp, Health.MAX_HP - SerpentRules.damage(SerpentRules.SWEEP))
	assert_eq(s.phase, P.DIZZY)


func test_a_jump_clears_the_sweep() -> void:
	var s := _serpent()
	var p := _player(Vector3(0.5, FLOOR + 1.6, 3.5))   # in the air, over the tail
	await get_tree().physics_frame
	s.start_phase(P.SWEEP_WARN)
	_steps(s, int(SerpentRules.SWEEP_WINDUP / DT) + 5)
	assert_eq(_hurts.size(), 0)
	assert_eq(p.health.hp, Health.MAX_HP)


func test_the_sand_ball_hits_a_child_who_stays_and_misses_one_who_steps_aside() -> void:
	var s := _serpent()
	var p := _player(Vector3(0.5, FLOOR, 8.5))
	await get_tree().physics_frame
	s.start_phase(P.SPIT_WARN)
	_steps_until(s, func() -> bool: return s.rocks_in_flight() > 0, 200)
	assert_eq(s.rocks_in_flight(), 1)
	_steps_until(s, func() -> bool: return s.rocks_in_flight() == 0, 200)
	assert_eq(p.health.hp, Health.MAX_HP - SerpentRules.damage(SerpentRules.SPIT))
	s.start_phase(P.SPIT_WARN)
	_steps_until(s, func() -> bool: return s.rocks_in_flight() > 0, 200)
	p.global_position += Vector3(3.0, 0, 0)
	_steps_until(s, func() -> bool: return s.rocks_in_flight() == 0, 200)
	assert_eq(p.health.hp, Health.MAX_HP - SerpentRules.damage(SerpentRules.SPIT), "the second one missed")


func test_the_boss_music_plays_while_it_is_here() -> void:
	Music.reset()
	var s := _serpent()
	Music.tick(0.1)
	assert_eq(Music.current(), MusicRules.BOSS)
	s.free()
	Music.tick(0.1)
	assert_ne(Music.current(), MusicRules.BOSS)


class WatchedWorld:
	extends WorldService
	var edits := 0

	func get_block(pos: Vector3i) -> int:
		return BlockIds.SAND if pos.y < 10 or (pos.z == -4 and pos.y < 13) else BlockIds.AIR

	func set_block(_pos: Vector3i, _id: int) -> void:
		edits += 1

	func is_editable(_pos: Vector3i) -> bool:
		return true


func test_it_never_changes_blocks() -> void:
	var w := WatchedWorld.new()
	autofree(w)
	var before := Session.world
	Session.register_world(w)
	var s := _serpent()
	s.block_at = w.get_block
	var p := _player(Vector3(0.5, FLOOR, -6.5))
	await get_tree().physics_frame
	_steps(s, int(30.0 / DT))
	s.take_hit(1000, p.global_position, Vector3.ZERO)
	Session.register_world(before)
	assert_eq(w.edits, 0, "the Sand Serpent never edits a block")
	for path in ["res://entities/monsters/sand_serpent.gd", "res://entities/monsters/serpent_models.gd",
			"res://core/rules/serpent_rules.gd"]:
		var src := FileAccess.get_file_as_string(path)
		for call in ["set_block", "request_set_block", "set_voxel(", "do_box", "do_sphere"]:
			assert_false(src.contains(call), "%s never calls %s" % [path.get_file(), call])
