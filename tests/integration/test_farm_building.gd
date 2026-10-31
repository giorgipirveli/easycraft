extends GutTest
## M3 Task 10: the Gold Farm's building and its looks are cheap: one shared mesh for every farm (and one per
## cap level for the gold piles), WeaponModels' one material, one static body on the world layer with a
## doorway you can walk through, 1-3 workers sharing their meshes, drawn only within SHOW_WORKERS_WITHIN,
## a tap on the barn finds it (not through a wall), and the welcome-back's coin shower uses Fx's shared
## material and one cached coin.


func _building(rate := 0, cap := 0, facing := 0) -> FarmBuilding:
	var b := FarmBuilding.new()
	add_child_autofree(b)
	b.setup(FarmRules.new_farm(Vector3i(10, 30, -5), facing, rate, cap))
	return b


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func test_every_farm_shares_one_mesh_and_one_material() -> void:
	var a := _building()
	var b := _building(2, 3, 1)
	var ma := a.get_node("Mesh") as MeshInstance3D
	var mb := b.get_node("Mesh") as MeshInstance3D
	assert_same(ma.mesh, mb.mesh)
	assert_same(ma.mesh.surface_get_material(0), WeaponModels.material())
	assert_eq(ma.mesh.get_surface_count(), 1, "one draw call for the barn and the field")
	assert_same(FarmBuilding.gold_mesh(1), FarmBuilding.gold_mesh(1), "gold piles cached per level")
	assert_ne(FarmBuilding.gold_mesh(0), FarmBuilding.gold_mesh(3))


func test_the_barn_is_solid_on_the_world_layer_with_a_doorway() -> void:
	var b := _building()
	var body := b.get_node("Walls") as StaticBody3D
	assert_eq(body.collision_layer, 1)
	assert_eq(body.collision_mask, 0)
	var door_mid := Vector3((FarmBuilding.DOOR_X.x + FarmBuilding.DOOR_X.y) * 0.5, 1.0, FarmBuilding.BARN_HI.z - 0.15)
	for box: AABB in FarmBuilding.solid_boxes():
		assert_false(box.has_point(door_mid), "the doorway is open: %s" % box)
	var walls := 0
	for box: AABB in FarmBuilding.solid_boxes():
		if box.has_point(Vector3(FarmBuilding.BARN_LO.x + 0.1, 1.0, -1.0)):
			walls += 1
	assert_eq(walls, 1, "the left wall is solid")
	for x in range(1, 5):
		for box: AABB in FarmBuilding.solid_boxes():
			assert_false(box.has_point(Vector3(x, 0.5, 0.0)), "the field is walked through")


func test_workers_follow_the_rate_level_and_share_meshes() -> void:
	var b := _building()
	assert_eq(b.workers.size(), 1)
	b.show_levels(FarmRules.new_farm(Vector3i(10, 30, -5), 0, 3, 0))
	assert_eq(b.workers.size(), 3)
	b.show_levels(FarmRules.new_farm(Vector3i(10, 30, -5), 0, 1, 0))
	assert_eq(b.workers.size(), 2)
	var other := _building(2)
	var arm_a := (b.workers[0].get_child(1) as Node3D).get_child(0) as MeshInstance3D
	var arm_b := (other.workers[1].get_child(1) as Node3D).get_child(0) as MeshInstance3D
	assert_same(arm_a.mesh, arm_b.mesh, "one arm and hoe for every worker")
	assert_same((b.workers[0].get_child(0) as MeshInstance3D).mesh, (other.workers[0].get_child(0) as MeshInstance3D).mesh)
	assert_eq((b.workers[0].get_child(0) as MeshInstance3D).visibility_range_end, FarmBuilding.SHOW_WORKERS_WITHIN)


func test_workers_rest_until_a_player_is_near() -> void:
	var b := _building(2)
	for w in b.workers:
		assert_false(w.is_processing())
	b.set_working(true)
	for w in b.workers:
		assert_true(w.is_processing())


func test_a_worker_walks_the_field_and_hoes() -> void:
	var b := _building()
	var w := b.workers[0]
	var jobs := {}
	for i in 1200:   # 60 s of steps of 0.05 s
		w.step(0.05)
		jobs[w.job] = true
		assert_lt(absf(w.position.x), FarmSite.HALF_W + 0.6, "stays on the farm")
		assert_lt(absf(w.position.z), FarmSite.HALF_D + 0.6)
	assert_true(jobs.has(FarmWorker.Job.WALK))
	assert_true(jobs.has(FarmWorker.Job.HOE))
	assert_true(jobs.has(FarmWorker.Job.DELIVER), "and carries the harvest to the barn")


func test_a_tap_on_the_barn_finds_it_from_near_but_not_through_a_wall() -> void:
	var b := _building()
	await wait_process_frames(1)
	var barn_front := b.global_transform * Vector3(-2.0, 1.5, FarmBuilding.BARN_HI.z)
	var eye := b.global_transform * Vector3(-2.0, 1.6, FarmBuilding.BARN_HI.z + 4.0)
	var dir := (barn_front - eye).normalized()
	assert_same(FarmBuilding.find(get_tree(), eye, dir, eye), b)
	var never := func(_f: Vector3, _d: Vector3, _dist: float) -> bool: return true
	assert_null(FarmBuilding.find(get_tree(), eye, dir, eye, never), "a block in the way")
	var far := b.global_transform * Vector3(-2.0, 1.6, FarmBuilding.BARN_HI.z + 20.0)
	assert_null(FarmBuilding.find(get_tree(), far, (barn_front - far).normalized(), far), "too far")
	assert_null(FarmBuilding.find(get_tree(), eye, -dir, eye), "looking away")


func test_the_coin_shower_uses_the_shared_material_and_one_coin() -> void:
	var holder := Node3D.new()
	add_child_autofree(holder)
	var a := Fx.coin_shower(holder, Vector3(0, 30, 0), 240)
	var b := Fx.coin_shower(holder, Vector3(4, 30, 0), 12)
	assert_same(a.mesh, b.mesh, "one cached coin")
	assert_same(a.mesh.surface_get_material(0), Fx.material(), "Fx's one material: nothing compiles")
	assert_gt(a.amount, b.amount, "more gold, more coins")
	assert_lte(a.amount, Fx.COIN_SHOWER_MAX)
	assert_gte(b.amount, Fx.COIN_SHOWER_MIN)
	assert_gt(a.global_position.y, 30.0, "they fall from above")
	assert_true(a.one_shot)
