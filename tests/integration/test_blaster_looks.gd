extends GutTest
## M3 Task 14b: how the blasters look. Held models are toy-like (bright colours, an orange tip), one cached
## mesh each with the shared weapon material (no new shader), rarity + 1 bands; shots are cached meshes too;
## icons are drawn in code with the rarity rim and pips; the paint mark shines through fog.


func _colors(mesh: Mesh) -> Array:
	var arrays := mesh.surface_get_arrays(0)
	return Array(arrays[Mesh.ARRAY_COLOR])


func test_every_blaster_is_held_with_one_cached_toy_mesh() -> void:
	for id in ItemIds.BLASTERS:
		assert_true(WeaponRules.is_holdable(id), ItemIds.display_name(id))
		assert_false(WeaponRules.is_weapon(id), "not a melee/bow weapon: blasters have their own path")
		var mesh := WeaponModels.mesh_for(id)
		assert_not_null(mesh)
		assert_same(mesh, WeaponModels.mesh_for(id), "built once")
		assert_eq(mesh.get_surface_count(), 1)
		assert_same(mesh.surface_get_material(0), WeaponModels.material(), "the shared material: nothing to compile")
		var colors := _colors(mesh)
		assert_true(colors.has(BlasterModels.ORANGE), "%s has the orange tip" % ItemIds.display_name(id))
		var band_vertices := colors.count(BlasterModels.BAND)
		assert_eq(band_vertices, (BlasterRules.rarity(id) + 1) * 36, "%s: rarity + 1 bands" % ItemIds.display_name(id))
		var aabb := mesh.get_aabb()
		assert_lt(aabb.position.z, -0.3, "points forward (-Z)")
		assert_lt(aabb.size.length(), 1.2, "hand-sized")


func test_the_hand_holds_a_blaster_and_it_kicks() -> void:
	var held := HeldItem.new()
	add_child_autofree(held)
	held.show_item(ItemIds.FOAM_BLASTER)
	assert_true(held.visible)
	assert_eq(HeldItem.swing_name(ItemIds.FOAM_BLASTER, 0), &"blast")
	held.play_attack(ItemIds.FOAM_BLASTER, 0)
	assert_true(held._swing != null and held._swing.is_valid(), "a kick animation")
	held._swing.custom_step(0.04)
	assert_gt(held._pitch, 0.1, "the muzzle kicks up")
	held.play_attack(ItemIds.FOAM_BLASTER, 0, true)   # an avatar with arms: they don't kick, the hand does it all
	held._swing.custom_step(0.04)
	assert_gt(held._pitch, 0.25, "the whole kick, not an arm's share")


func test_shots_are_cached_meshes() -> void:
	for look in [BlasterModels.DART, BlasterModels.SNOWBALL, BlasterModels.PAINT_BLOB, BlasterModels.BUBBLE,
			BlasterModels.ROCKET, BlasterModels.GOBLIN_ARROW]:
		var m := BlasterModels.shot_mesh(look)
		assert_not_null(m, String(look))
		assert_same(m, BlasterModels.shot_mesh(look))
	assert_same(BlasterModels.shot_mesh(BlasterModels.BUBBLE).surface_get_material(0), Player.ghost_material(),
		"the bubble shares the invisibility look")
	assert_same(BlasterModels.shot_mesh(BlasterModels.DART).surface_get_material(0), WeaponModels.material())
	var arrow := BlasterModels.shot_mesh(BlasterModels.GOBLIN_ARROW).get_aabb()
	var player_arrow := WeaponModels.arrow().get_aabb()
	assert_gt(arrow.size.x, player_arrow.size.x, "the goblin's arrows are big and easy to see")
	for b in ItemIds.BLASTERS:
		assert_ne(BlasterModels.shot_look(b), &"")


func test_the_paint_mark_shines_through_fog() -> void:
	var mat := BlasterModels.mark_material()
	assert_same(mat, BlasterModels.mark_material(), "one material")
	assert_true(mat.disable_fog)
	assert_eq(mat.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED)
	assert_same(BlasterModels.paint_mark_mesh().surface_get_material(0), mat)
	assert_same(BlasterModels.bubble_mesh().surface_get_material(0), Player.ghost_material())


func test_icons_have_the_rarity_rim_and_pips() -> void:
	for id in ItemIds.BLASTERS + ItemIds.AMMO:
		var rows: Array = BlasterIcons.PICTURES[id]
		assert_eq(rows.size(), 16)
		for y in rows.size():
			assert_eq((rows[y] as String).length(), 16, "%s row %d" % [ItemIds.display_name(id), y])
			if y < 3:
				assert_eq(rows[y], "................", "rows 0-2 stay empty for the pips")
		var img := BlasterIcons.image(id)
		assert_eq(img.get_size(), Vector2i(32, 32))
		var rarity := BlasterRules.rarity(id)
		var rim := 0
		for y in 32:
			for x in 32:
				if img.get_pixel(x, y).is_equal_approx(ItemRarity.color(rarity)):
					rim += 1
		assert_gt(rim, 20, "%s: a rim in its rarity colour" % ItemIds.display_name(id))
		for i in 5:
			var c := img.get_pixelv(BlockIcons.pip_center(i))
			assert_eq(c.is_equal_approx(BlockIcons.PIP_COLOR), i <= rarity, "%s pip %d" % [ItemIds.display_name(id), i])
		assert_not_null(BlockIcons.icon(id), "the HUD finds it")
