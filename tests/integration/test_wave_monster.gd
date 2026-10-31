extends GutTest
## M2 Task 9: a Totem wave monster is an ordinary monster (Task 4) that belongs to a wave and heads for
## the Totem while it has nobody to chase; once there it wanders around it and chases whoever it sees.

const FLOOR := 10
const DT := 1.0 / 60.0

var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR


func after_each() -> void:
	Game.mode = _mode_before


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _flat(p: Vector3i) -> int:
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _ground() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120, 1, 120)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	ground.global_position = Vector3(0, FLOOR - 0.5, 0)


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = "1"
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _goblin(pos: Vector3, goal: Vector3, wave: int = 2) -> Monster:
	var m := Monster.new()
	m.setup({"kind": MonsterRules.GOBLIN, "level": 1, "id": "w_test", "pos": pos, "yaw": 0.0, "wild": false,
		"universe": 1, "wave": wave, "goal": goal})
	m.block_at = _flat
	add_child_autofree(m)
	return m


func test_setup_keeps_the_wave_and_the_goal() -> void:
	var m := _goblin(Vector3(0.5, FLOOR, 20.5), Vector3(0.5, FLOOR, 0.5), 4)
	assert_eq(m.wave, 4)
	assert_eq(m.goal, Vector3(0.5, FLOOR, 0.5))
	var plain := Monster.new()
	plain.setup({"kind": MonsterRules.SLIME, "level": 1, "id": "p", "pos": Vector3.ZERO, "yaw": 0.0, "wild": true, "universe": 1})
	assert_eq(plain.wave, 0, "night monsters belong to no wave")
	assert_false(plain.goal.is_finite())
	plain.free()


func test_a_wave_monster_with_nobody_in_sight_walks_to_the_totem() -> void:
	_ground()
	var goal := Vector3(0.5, FLOOR, 0.5)
	# Two monsters with the same wandering luck (same id) on opposite sides: both come to the Totem.
	var north := _goblin(Vector3(0.5, FLOOR, 22.5), goal)
	north.rotation.y = PI   # facing away from the Totem
	var south := _goblin(Vector3(0.5, FLOOR, -22.5), goal)
	_player(Vector3(20.5, FLOOR, 0.5))   # near enough to wake them, never within their sight
	await get_tree().physics_frame
	for m: Monster in [north, south]:
		var start := m.global_position.distance_to(goal)
		for i in 180:
			m._physics_process(DT)
		assert_null(m.target(), "it saw nobody")
		assert_lt(m.global_position.distance_to(goal), start - 2.5, "it came towards the Totem")


func test_near_the_totem_it_wanders_like_any_monster() -> void:
	_ground()
	var goal := Vector3(0.5, FLOOR, 0.5)
	var m := _goblin(Vector3(1.5, FLOOR, 1.5), goal)
	_player(Vector3(30.5, FLOOR, 1.5))
	await get_tree().physics_frame
	for i in 240:
		m._physics_process(DT)
	assert_lt(Vector2(m.global_position.x - goal.x, m.global_position.z - goal.z).length(), Monster.GOAL_NEAR + 4.0,
		"it stays around the Totem")
