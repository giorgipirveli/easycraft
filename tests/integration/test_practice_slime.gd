extends GutTest
## M3 Task 15 (spec §14.9): the tutorial's practice slime — a real slime that sees and chases (so hiding in a bush
## is the real lesson) but can't hurt anyone and can't be hurt (no coins, no defeat), and has no creature mind (the
## world's slimes learn nothing from it). Solo: this game is the host.

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


func _slime(pos: Vector3, practice: bool) -> Monster:
	var m := Monster.new()
	m.setup({"kind": MonsterRules.SLIME, "level": 2, "id": "practice_test_%s" % practice, "pos": pos, "yaw": 0.0,
		"wild": false, "universe": 1, "practice": practice})
	m.block_at = _flat
	add_child_autofree(m)
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


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = "1"
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


func test_it_is_a_practice_slime_only_when_asked() -> void:
	assert_true(_slime(Vector3(0, 40, 0), true).practice)
	assert_false(_slime(Vector3(4, 40, 0), false).practice)


func test_it_sees_and_comes_but_never_hurts() -> void:
	_ground()
	var s := _slime(Vector3(0.5, FLOOR, 0.5), true)
	var p := _player(Vector3(0.5, FLOOR, -0.4))
	await get_tree().physics_frame
	var saw := false
	for i in 240:
		_steps(s, 1)
		saw = saw or s.alert == StealthRules.MARK_BANG
	assert_true(saw, "it sees the child: '!' (so hiding is the lesson)")
	assert_eq(p.health.hp, Health.MAX_HP, "a practice slime can't hurt")


func test_a_real_slime_still_hurts() -> void:
	_ground()
	var s := _slime(Vector3(0.5, FLOOR, 0.5), false)
	var p := _player(Vector3(0.5, FLOOR, -0.4))
	await get_tree().physics_frame
	_steps(s, 240)
	assert_lt(p.health.hp, Health.MAX_HP, "the guard above is the practice one")


func test_a_hit_bounces_it_but_never_defeats_it() -> void:
	var s := _slime(Vector3(0, 40, 0), true)
	var defeated := []
	s.defeated.connect(func(m: Monster) -> void: defeated.append(m))
	for i in 10:
		s.take_hit(99, Vector3(0, 40, 2), Vector3(0, 0, -3))
	assert_eq(s.hp, s.max_hp, "no coins, no confetti: it's practice")
	assert_true(defeated.is_empty())
	assert_gt(absf(s.velocity.z), 0.0, "a push, like any hit")


func test_it_has_no_creature_mind() -> void:
	var s := _slime(Vector3(0, 40, 0), true)
	s._mind_ready()
	assert_null(s.mind, "the world's slimes learn nothing from a practice one")
