extends GutTest
## M5 Task 2 (spec §15.2): the living title diorama behind the menu's wordmark. A floating grass island in front of
## the menu's camera, the brand's buddy on it asleep, the star sparkles, it wakes, hops and waves, the dog wags; shared
## meshes and materials the game already has (no new shader), nothing made per frame; hidden with Reduce motion,
## and the camera then holds still.

var _reduce := false


func before_each() -> void:
	_reduce = bool(Profile.data.settings.get("reduce_motion", false))
	Profile.data.settings.reduce_motion = false


func after_each() -> void:
	Profile.data.settings.reduce_motion = _reduce


func _diorama() -> TitleDiorama:
	var d := TitleDiorama.new()
	add_child_autofree(d)
	d.set_process(false)
	return d


func _meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for m in n.find_children("*", "MeshInstance3D", true, false):
		out.append(m)
	return out


func test_an_island_with_the_buddy_its_eyes_its_star_and_the_dog() -> void:
	var d := _diorama()
	for part: Node3D in [d.island, d.buddy, d.eyes, d.arm, d.star, d.dog, d.tail]:
		assert_not_null(part)
		assert_true(part.is_inside_tree())
	assert_same(d.dog.mesh, BlockyAnimal.mesh_for(&"dog"), "the game's own dog")
	assert_same(d.tail.mesh, BlockyAnimal.part_mesh_for(&"dog"), "and its tail")
	assert_false(d.light.shadow_enabled, "its small light casts no shadows")
	assert_lt(d.light.position.length() + d.light.omni_range, 14.0, "and reaches nothing but the island")


func test_its_meshes_are_shared_and_it_makes_no_material() -> void:
	var a := _meshes(_diorama())
	var b := _meshes(_diorama())
	assert_eq(a.size(), b.size())
	assert_lte(a.size(), 10, "a handful of draws")
	var known := [BlockyAnimal.mesh_for(&"dog").surface_get_material(0)]
	for page_kind: StringName in [&"opaque", &"cutout"]:
		known.append(BlockLibrary.page_material(0, page_kind))
	for i in a.size():
		assert_same(a[i].mesh, b[i].mesh, "%s: one mesh for every diorama" % a[i].name)
		assert_null(a[i].material_override, "%s: no material of its own" % a[i].name)
		for s in a[i].mesh.get_surface_count():
			var m := a[i].mesh.surface_get_material(s)
			assert_true(known.has(m), "%s: a material the game already compiled (%s)" % [a[i].name, m])
		assert_eq(a[i].cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "no shadow pass for it")


func test_it_sleeps_the_star_sparkles_it_wakes_hops_and_waves() -> void:
	var d := _diorama()
	d.step(1.0)
	assert_lt(d.eyes.scale.y, 0.2, "asleep")
	assert_false(d.sparkle.emitting)
	d.step(TitleDioramaRules.SPARKLE - 1.0 + 0.02)
	assert_true(d.sparkle.emitting, "the wand's star sparkles")
	var top := 0.0
	var arm := 0.0
	for i in 60:
		d.step(0.05)
		top = maxf(top, d.buddy.position.y)
		arm = maxf(arm, absf(d.arm.rotation.z))
	assert_almost_eq(d.eyes.scale.y, 1.0, 0.01, "awake")
	assert_gt(top, d.rest_y + 0.3, "it hops")
	d.step(7.0 - d.time())
	assert_gt(absf(d.arm.rotation.z), 1.0, "it waves")


func test_a_minute_of_it_makes_nothing_new() -> void:
	var d := _diorama()
	d.step(0.1)
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	var t0 := Time.get_ticks_usec()
	for i in 3600:
		d.step(1.0 / 60.0)
	gut.p("TITLE_DIORAMA step: %.1f us a frame (desktop)" % ((Time.get_ticks_usec() - t0) / 3600.0))
	# (A piece of music loading on its thread may add an object meanwhile: fewer than one a loop is nothing made.)
	assert_lt(Performance.get_monitor(Performance.OBJECT_COUNT) - before, 5.0, "no object made in a minute (five loops)")


func test_the_menu_shows_it_in_front_of_its_camera_beside_the_wordmark() -> void:
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_frames(3)
	var cam := menu.get("_cam") as Camera3D
	var d := cam.find_children("*", "TitleDiorama", false, false)
	assert_eq(d.size(), 1, "on the menu's camera")
	if d.size() != 1:
		return
	var at := cam.to_local((d[0] as Node3D).global_position)
	assert_lt(at.z, -3.0, "in front of the camera")
	assert_gt(at.y / -at.z, 0.15, "above the middle: in the wordmark's band, above the buttons")
	assert_lt(at.x, 0.0, "left of the wordmark (the visuals brief: under it, it hid behind the panels)")
	assert_true((d[0] as Node3D).visible)


func test_with_reduce_motion_it_is_hidden_and_the_camera_holds_still() -> void:
	Profile.data.settings.reduce_motion = true
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_frames(3)
	var cam := menu.get("_cam") as Camera3D
	var d := cam.find_children("*", "TitleDiorama", false, false)
	assert_false(d.is_empty() or (d[0] as Node3D).visible, "hidden")
	var t := cam.global_transform
	await wait_frames(10)
	assert_eq(cam.global_transform, t, "the camera holds still")
