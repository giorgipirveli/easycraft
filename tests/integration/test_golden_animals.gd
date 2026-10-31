extends GutTest
## M2 Task 16 (spec §12.16): golden animals — a rare golden variant of a wild animal (one shared golden
## material), never tamed, running from anyone who comes close, but slower than a walking child.


func _animal(golden: bool, species: StringName = &"pig") -> Animal:
	var a := Animal.new()
	a.setup({"species": species, "id": "a1_2_0", "pos": Vector3(0.5, 40, 0.5), "yaw": 0.0, "owner": 0, "name": "",
		"sitting": false, "golden": golden})
	add_child_autofree(a)
	return a


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func test_a_golden_animal_shines_in_one_shared_material() -> void:
	var a := _animal(true)
	var b := _animal(true, &"rabbit")
	assert_true(a.golden)
	for mi: MeshInstance3D in a.find_children("*", "MeshInstance3D", true, false) + b.find_children("*", "MeshInstance3D", true, false):
		assert_same(mi.material_override, Animal.golden_material())
	var plain := _animal(false)
	for mi: MeshInstance3D in plain.find_children("*", "MeshInstance3D", true, false):
		assert_null(mi.material_override, "an ordinary animal keeps its colours")


func test_a_golden_animal_is_never_tamed() -> void:
	var a := _animal(true, &"dog")
	for t in 5:
		a.pet_tap(7, t * 0.2, 0)
	assert_false(a.is_pet())


func test_a_golden_animal_runs_from_anyone_close() -> void:
	var a := _animal(true)
	var p := _player(Vector3(3.5, 40, 0.5))
	assert_true(a._check_golden_flee())
	assert_almost_eq(a._dir.x, -1.0, 0.01, "away from the player, who is only walking")
	assert_gt(a._flee, 0.0)
	var calm := _animal(false)
	assert_false(calm._check_golden_flee(), "an ordinary animal only runs from a rush")
	p.global_position = Vector3(30, 40, 0)
	await wait_physics_frames(1)      # animals look players up once per physics frame
	a._flee = 0.0
	assert_false(a._check_golden_flee(), "nobody close: calm")
