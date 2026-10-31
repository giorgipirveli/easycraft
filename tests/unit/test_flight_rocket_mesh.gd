extends GutTest
## Owner #79 (spec §25.3): the rocket the child built rises from the pad — a mesh made from its blocks with the blocks'
## own atlas look (both styles: BlockLibrary's shared materials, so set_style restyles it), one surface (one draw call)
## per material, only the faces that show. A block id no page draws yet (the missions' parts, ids 560-575, before their
## page is merged) is drawn in a stand-in look and never breaks the build.


func _faces(mesh: ArrayMesh) -> int:
	var n := 0
	for s in mesh.get_surface_count():
		n += (mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 6
	return n


func test_one_block_is_six_faces_in_its_page_s_material() -> void:
	var mesh := RocketMesh.build({Vector3i(0, 0, 0): BlockIds.STONE})
	assert_eq(mesh.get_surface_count(), 1)
	assert_eq(_faces(mesh), 6)
	assert_eq(mesh.surface_get_material(0), BlockLibrary.page_material(0, &"opaque"), "the blocks' own shared material")


func test_faces_between_two_blocks_are_not_drawn() -> void:
	var mesh := RocketMesh.build({Vector3i(0, 0, 0): BlockIds.STONE, Vector3i(0, 1, 0): BlockIds.BRICK})
	assert_eq(mesh.get_surface_count(), 1, "one material, one draw call")
	assert_eq(_faces(mesh), 10)


func test_a_see_through_block_shows_the_face_behind_it() -> void:
	var mesh := RocketMesh.build({Vector3i(0, 0, 0): BlockIds.STONE, Vector3i(1, 0, 0): BlockIds.GLASS,
		Vector3i(2, 0, 0): BlockIds.GLASS})
	assert_eq(mesh.get_surface_count(), 2, "opaque and cut-out")
	assert_eq(_faces(mesh), 6 + 4 + 5, "the stone's face behind the glass shows; glass to glass and glass on stone do not")


func test_one_surface_per_material_across_pages() -> void:
	var cells := {Vector3i(0, 0, 0): BlockIds.STONE, Vector3i(0, 1, 0): BlockIds.MOON_ROCK,
		Vector3i(0, 2, 0): BlockIds.PORTHOLE, Vector3i(0, 3, 0): BlockIds.BASE_PANEL, Vector3i(0, 4, 0): BlockIds.LIGHT}
	var mesh := RocketMesh.build(cells)
	var mats := {}
	for s in mesh.get_surface_count():
		mats[mesh.surface_get_material(s)] = true
	assert_eq(mesh.get_surface_count(), mats.size(), "never two surfaces with one material")
	assert_eq(mesh.get_surface_count(), 4, "page 0 opaque and glow, the Moon's page opaque and glow")
	assert_has(mats.keys(), BlockLibrary.page_material(BlockLibrary.page_of(BlockIds.PORTHOLE), &"glow"))


## A block no page draws (an id past every page) is drawn in a stand-in look; the missions' parts (page 32, merged
## 2026-09-30) are drawn from their page.
func test_an_unknown_part_is_drawn_in_a_stand_in_look() -> void:
	var cells := {}
	for i in 16:
		cells[Vector3i(0, i, 0)] = 900 + i   # ids no page holds
	cells[Vector3i(1, 0, 0)] = 1000   # beyond every page
	var mesh := RocketMesh.build(cells)
	assert_gt(mesh.get_surface_count(), 0)
	assert_eq(_faces(mesh), 16 * 4 + 2 - 1 + 5, "every block drawn (stand-ins are solid: their shared face goes)")
	assert_true(RocketMesh.stand_in(903), "no page draws it")
	assert_false(RocketMesh.stand_in(BlockIds.STONE))
	assert_false(RocketMesh.stand_in(RocketStages.PART_IDS_FIRST + 3), "page 32 draws the rocket parts now")
	assert_ne(RocketMesh.look(900).tint, RocketMesh.look(902).tint, "stand-ins told apart by colour")


func test_the_mesh_sits_round_the_rocket_s_axis() -> void:
	var cells := {Vector3i(4, 2, 4): BlockIds.STONE}
	var mesh := RocketMesh.build(cells, RocketStages.pivot(cells))
	var aabb := mesh.get_aabb()
	assert_almost_eq(aabb.position, Vector3(-0.5, 0.0, -0.5), Vector3.ONE * 0.001, "the axis at the middle of its foot")
	assert_almost_eq(aabb.size, Vector3.ONE, Vector3.ONE * 0.001)


func test_no_blocks_no_surfaces() -> void:
	assert_eq(RocketMesh.build({}).get_surface_count(), 0)


func test_the_test_rocket_is_a_handful_of_draw_calls() -> void:
	var r := RocketStages.test_rocket(SpaceRules.MOON, 3)
	for i in RocketStages.stage_count(r):
		var mesh := RocketMesh.build(RocketStages.stage_cells(r, i))
		assert_lte(mesh.get_surface_count(), 5, "stage %d" % i)
		assert_lte(_faces(mesh), 400)


## Godot draws clockwise triangles as front faces: seen from outside (along the normal) every triangle winds clockwise.
func test_every_face_looks_outward() -> void:
	var mesh := RocketMesh.build(RocketStages.test_rocket(SpaceRules.MOON).cells)
	var bad := 0
	var seen := 0
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for t in range(0, idx.size(), 3):
			var a := v[idx[t]]
			var cross := (v[idx[t + 1]] - a).cross(v[idx[t + 2]] - a)
			seen += 1
			if cross.dot(n[idx[t]]) >= 0.0:
				bad += 1
	assert_gt(seen, 100)
	assert_eq(bad, 0, "triangles winding the wrong way")
