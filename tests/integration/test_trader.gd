extends GutTest
## M2 Task 7: Tilly and her stall. Cheap (shared meshes and one shared material), solid enough to
## bump into, found by a tap within reach, with a one-time hint arrow over the stall.


func _tilly(pos: Vector3 = Vector3(0.5, 30, 0.5), yaw: float = 0.0, hint: bool = false) -> Trader:
	var t := Trader.new()
	t.setup({"pos": pos, "yaw": yaw, "hint": hint})
	add_child_autofree(t)
	return t


func test_tilly_stands_where_the_host_put_her() -> void:
	var t := _tilly(Vector3(12.5, 31, -4.5), 1.2)
	assert_eq(t.name, "Tilly")
	assert_eq(t.global_position, Vector3(12.5, 31, -4.5))
	assert_almost_eq(t.rotation.y, 1.2, 0.0001)
	assert_true(t.is_in_group(&"traders"))


func test_she_and_her_stall_are_cheap() -> void:
	var a := _tilly()
	var b := _tilly(Vector3(40.5, 30, 0.5))
	var meshes_a := a.find_children("*", "MeshInstance3D", true, false)
	var meshes_b := b.find_children("*", "MeshInstance3D", true, false)
	assert_lte(meshes_a.size(), 4, "a handful of draw calls")
	for i in meshes_a.size():
		var m := (meshes_a[i] as MeshInstance3D).mesh
		assert_same(m, (meshes_b[i] as MeshInstance3D).mesh, "meshes are built once and shared")
		assert_eq(m.get_surface_count(), 1)
		assert_same(m.surface_get_material(0), WeaponModels.material(), "one shared material")


func test_players_and_animals_bump_into_the_stall() -> void:
	var t := _tilly()
	var bodies := t.find_children("*", "StaticBody3D", true, false)
	assert_eq(bodies.size(), 1)
	var body := bodies[0] as StaticBody3D
	assert_eq(body.collision_layer, Player.WORLD_COLLISION_MASK, "on the world layer")
	assert_eq(body.collision_mask, 0)
	assert_gt(body.find_children("*", "CollisionShape3D", true, false).size(), 0)


func test_the_stall_is_about_three_blocks_wide_with_an_awning_above_her() -> void:
	var t := _tilly()
	var box := AABB()
	for mi: MeshInstance3D in t.find_children("*", "MeshInstance3D", true, false):
		if not t.hint_node().is_ancestor_of(mi):
			box = box.merge(t.global_transform.affine_inverse() * mi.global_transform * mi.get_aabb())
	assert_between(box.size.x, 2.5, 3.2, "fits the 3 x 3 level spot")
	assert_between(box.size.y, 2.6, 3.8, "an awning above head height")


func test_the_hint_arrow_shows_until_the_first_visit() -> void:
	var t := _tilly(Vector3(0.5, 30, 0.5), 0.0, true)
	assert_true(t.hint_visible())
	assert_gt(t.hint_node().position.y, 3.0, "floats over the stall")
	t.show_hint(false)
	assert_false(t.hint_visible())
	assert_false(_tilly().hint_visible(), "no hint once visited")


func test_a_tap_ray_within_reach_finds_her() -> void:
	var t := _tilly(Vector3(0.5, 30, 0.5))
	var eye := Vector3(0.5, 31.6, -2.5)
	var at_her := (t.global_position + Vector3(0, 1.1, 0) - eye).normalized()
	assert_same(Trader.find(get_tree(), eye, at_her, eye), t)
	assert_null(Trader.find(get_tree(), eye, Vector3.LEFT, eye), "looking away")
	var far_eye := Vector3(0.5, 31.6, -20)
	assert_null(Trader.find(get_tree(), far_eye, (t.global_position + Vector3(0, 1.1, 0) - far_eye).normalized(), far_eye), "too far to tap")
	var wall := func(_from: Vector3, _dir: Vector3, _dist: float) -> bool: return true
	assert_null(Trader.find(get_tree(), eye, at_her, eye, wall), "not through a wall")
