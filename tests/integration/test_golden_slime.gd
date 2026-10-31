extends GutTest
## Spec §12.16 #4: a golden slime runs away (slower than a walking child), never hurts anyone and
## shines in the one shared golden material (golden animals', M2 Task 16).

const FLOOR := 10
const DT := 1.0 / 60.0


func _flat(p: Vector3i) -> int:
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _ground() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	ground.global_position = Vector3(0, FLOOR - 0.5, 0)


func _golden(pos: Vector3) -> Monster:
	var m := Monster.new()
	m.setup({"kind": MonsterRules.SLIME, "level": 2, "id": "g%d" % randi(), "pos": pos, "wild": true,
		"universe": 1, "golden": true})
	m.block_at = _flat
	add_child_autofree(m)
	return m


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func test_it_runs_away_and_never_hurts() -> void:
	_ground()
	var g := _golden(Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, 3.5))
	await get_tree().physics_frame
	var start := g.global_position.distance_to(p.global_position)
	for i in 240:
		g._physics_process(DT)
	assert_gt(g.global_position.distance_to(p.global_position), start + 1.0, "away from the child")
	assert_eq(p.health.hp, Health.MAX_HP, "never hurts")
	assert_lt(g._move_speed(), Player.WALK_SPEED, "a walking child can catch it")


func test_it_wears_the_shared_golden_material() -> void:
	var g := _golden(Vector3(0.5, FLOOR, 0.5))
	var body := g._body.get_child(0) as MeshInstance3D   # the slime's own mesh (not its ?/! mark or health bar)
	assert_eq(body.mesh, MonsterModels.mesh_for(MonsterRules.SLIME, 2))
	assert_same(body.material_override, Animal.golden_material())
