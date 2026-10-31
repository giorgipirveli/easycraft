extends GutTest
## M3 Task 14b (spec §13.7, build-fight practice): goblin archers in a world. An archer that sees a child 10-20
## blocks away draws its bow for a whole second (everyone sees it: `winding`, the glowing arrow) and then
## shoots a slow arrow that hurts a child who stands still; an arrow never goes through a wall (a child who
## ducks behind one is safe); it hides behind a block and steps out to shoot; it backs off from a child who
## comes close; it never changes a block. Solo play: this game is the host.

const FLOOR := 10
const DT := 1.0 / 30.0

var _mode_before: StringName
var _cells := {}
var _n := 0
var _d: BlasterDirector


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_cells = {}
	_d = BlasterDirector.new()
	_d.name = "Blasters"
	_d.block_at = _block
	add_child_autofree(_d)
	_d.set_physics_process(false)


func after_each() -> void:
	Game.mode = _mode_before
	Session.survivor_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _block(p: Vector3i) -> int:
	if _cells.has(p):
		return _cells[p]
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _archer(pos: Vector3, level: int = 2, yaw: float = 0.0) -> Monster:
	_n += 1
	var m := Monster.new()
	m.setup({"kind": MonsterRules.ARCHER, "level": level, "id": "ga%d" % _n, "pos": pos, "yaw": yaw, "wild": true})
	m.block_at = _block
	m.shoot_arrow = _d.monster_arrow
	add_child_autofree(m)
	m.set_physics_process(false)
	return m


## The ground, and a box for every solid cell in _cells (the terrain's collision).
func _ground() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(90, 1, 90)
	shape.shape = box
	shape.position = Vector3(0, FLOOR - 0.5, 0)
	body.add_child(shape)
	for p: Vector3i in _cells:
		if BlockIds.is_solid(_cells[p]):
			var s := CollisionShape3D.new()
			var b := BoxShape3D.new()
			b.size = Vector3.ONE
			s.shape = b
			s.position = Vector3(p) + Vector3(0.5, 0.5, 0.5)
			body.add_child(s)
	add_child_autofree(body)


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
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
		_d._physics_process(DT)


func _steps_until(m: Monster, done: Callable, limit: int = 300) -> bool:
	for i in limit:
		if done.call():
			return true
		_steps(m, 1)
	return done.call()


func _wall(x0: int, x1: int, z: int, height: int = 3) -> void:
	for x in range(x0, x1 + 1):
		for y in range(FLOOR, FLOOR + height):
			_cells[Vector3i(x, y, z)] = BlockIds.STONE


func test_an_archer_draws_its_bow_for_a_second_then_its_arrow_hits_a_child_standing_still() -> void:
	_ground()
	var m := _archer(Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -13.5))
	await get_tree().physics_frame
	assert_true(_steps_until(m, func() -> bool: return m.winding, 240), "it aims")
	assert_eq(_d.active_shots(), 0, "no arrow yet: the signal comes first")
	_steps(m, int(0.9 / DT))
	assert_eq(_d.active_shots(), 0, "still drawing after 0.9 s")
	assert_true(_steps_until(m, func() -> bool: return _d.active_shots() > 0, 10), "then the arrow flies")
	assert_eq(p.health.hp, Health.MAX_HP, "it takes a moment to arrive")
	_steps_until(m, func() -> bool: return _d.active_shots() == 0, 150)
	assert_lt(p.health.hp, Health.MAX_HP, "a child who stands still is hit")


func test_a_child_who_ducks_behind_a_wall_is_never_hit() -> void:
	_ground()
	var m := _archer(Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -13.5))
	await get_tree().physics_frame
	assert_true(_steps_until(m, func() -> bool: return _d.active_shots() > 0, 300), "it shoots")
	_wall(-2, 2, -11, 4)                  # built in time: a wall between the arrow and the child
	_steps_until(m, func() -> bool: return _d.active_shots() == 0, 150)
	_steps(m, int(6.0 / DT))              # and whatever it tries next
	assert_eq(p.health.hp, Health.MAX_HP, "no arrow ever goes through the wall")


func test_an_archer_hides_behind_a_block_and_steps_out_to_shoot() -> void:
	_wall(2, 2, -2, 2)                    # one pillar next to it, between it and the child
	_ground()
	var m := _archer(Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(2.5, FLOOR, -14.5))
	await get_tree().physics_frame
	var chest := p.global_position + Vector3(0, 1.0, 0)
	var covered_at := []
	var aimed_from := []
	for i in int(20.0 / DT):
		_steps(m, 1)
		var eye := m.global_position + Vector3(0, ArcherRules.EYE, 0)
		var clear := MonsterRules.clear_line(eye, chest, _is_solid)
		if not clear and m.velocity.length() < 0.1:
			covered_at.append(m.global_position)
		if m.winding:
			aimed_from.append(clear)
	assert_gt(covered_at.size(), 10, "it waited behind the pillar")
	assert_gt(aimed_from.size(), 0, "it aimed")
	assert_false(aimed_from.has(false), "always from a spot with a clear shot (it stepped out)")


func _is_solid(c: Vector3i) -> bool:
	return BlockIds.is_solid(_block(c))


func test_an_archer_backs_off_from_a_child_who_comes_close() -> void:
	_ground()
	var m := _archer(Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -4.5))
	await get_tree().physics_frame
	var start := m.global_position.distance_to(p.global_position)
	_steps(m, int(3.0 / DT))
	assert_gt(m.global_position.distance_to(p.global_position), start + 1.5, "it keeps its distance")
	assert_eq(_d.active_shots(), 0, "no shot from so close")


func test_an_archer_never_changes_a_block() -> void:
	_wall(2, 2, -2, 2)
	_ground()
	var m := _archer(Vector3(0.5, FLOOR, 0.5))
	_player(Vector3(2.5, FLOOR, -14.5))
	await get_tree().physics_frame
	var before := _cells.duplicate()
	_steps(m, int(10.0 / DT))
	assert_eq(_cells, before)
	for path in ["res://core/rules/archer_rules.gd", "res://world/blaster_director.gd", "res://entities/projectiles/shot_pool.gd",
			"res://core/rules/blaster_rules.gd", "res://entities/player/blaster_user.gd"]:
		var src := FileAccess.get_file_as_string(path)
		for call in ["set_block", "request_set_block", "set_blocks", "put_block"]:
			assert_false(src.contains(call), "%s never calls %s" % [path.get_file(), call])


func test_the_archer_looks_like_a_goblin_with_a_bow_and_a_glowing_arrow_while_it_aims() -> void:
	var rest := MonsterModels.arm_mesh_for(MonsterRules.ARCHER, 2)
	var aiming := MonsterModels.arm_mesh_for(MonsterRules.ARCHER, 2, 0, true)
	assert_ne(rest, aiming)
	var rest_colors: Array = Array(rest.surface_get_arrays(0)[Mesh.ARRAY_COLOR])
	var aim_colors: Array = Array(aiming.surface_get_arrays(0)[Mesh.ARRAY_COLOR])
	assert_false(rest_colors.has(MonsterModels.ARROW_GLOW))
	assert_true(aim_colors.has(MonsterModels.ARROW_GLOW), "the glowing tip: the signal")
	assert_true(MonsterModels.colors_of(MonsterRules.ARCHER, 2).has(MonsterModels.HOOD), "its green hood")
	assert_eq(MonsterModels.windup_angle(MonsterRules.ARCHER), MonsterModels.ARCHER_AIM)
