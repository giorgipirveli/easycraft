extends GutTest
## M3 Task 8 (Build-and-Wear): a built wearable is baked into one small cached mesh in its blocks' own page
## materials (both styles: the shared block materials restyle themselves), worn by both avatar styles through
## AvatarModel's anchors (a hat on the head, a backpack and wings on the back; wings flap), saved in the profile
## and sent to other players with the look (Player.look_code). The editor's HAT, CAPE and WINGS tiles take it off.


func _code(blocks: Dictionary) -> String:
	return WearRules.from_blocks(blocks)


func _make(kind: GDScript) -> AvatarModel:
	var a: AvatarModel = kind.new()
	add_child_autofree(a)
	return a


func _meshes_of(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for n in node.find_children("*", "MeshInstance3D", true, false):
		out.append(n as MeshInstance3D)
	return out


func test_a_wearable_is_one_mesh_in_the_blocks_own_materials() -> void:
	var code := _code({Vector3i(0, 0, 0): BlockIds.BRICK, Vector3i(1, 0, 0): BlockIds.PAINTED_PINK,
		Vector3i(0, 1, 0): BlockIds.BRICK})
	var mesh := WearMesh.mesh_for(WearRules.HAT, code, false)
	assert_eq(mesh.get_surface_count(), 2, "one surface per material: brick (page 0), paint (page 12)")
	var lib := WorldService.library()
	var mats := [mesh.surface_get_material(0), mesh.surface_get_material(1)]
	assert_has(mats, (lib.models[BlockIds.BRICK] as VoxelBlockyModel).get_material_override(0))
	assert_has(mats, BlockLibrary.page_material(PaintPage.PAGE, &"opaque"), "the paint page's shared material")
	var faces := 0
	for s in mesh.get_surface_count():
		faces += (mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 6
	assert_eq(faces, 14, "3 cubes = 18 faces, less the 4 where they touch")
	assert_same(WearMesh.mesh_for(WearRules.HAT, code, false), mesh, "cached: every avatar shares it")


func test_faces_point_out() -> void:
	var mesh := WearMesh.cube(BlockIds.STONE)
	var arrays := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	assert_eq(idx.size(), 36, "a whole cube")
	var box := BoxMesh.new().get_mesh_arrays()
	var bv: PackedVector3Array = box[Mesh.ARRAY_VERTEX]
	var bi: PackedInt32Array = box[Mesh.ARRAY_INDEX]
	var box_turn := (bv[bi[1]] - bv[bi[0]]).cross(bv[bi[2]] - bv[bi[0]]).dot(box[Mesh.ARRAY_NORMAL][bi[0]])
	for k in range(0, idx.size(), 3):
		var turn := (v[idx[k + 1]] - v[idx[k]]).cross(v[idx[k + 2]] - v[idx[k]]).dot(n[idx[k]])
		assert_eq(signf(turn), signf(box_turn), "the same winding as Godot's own BoxMesh")
		var mid := (v[idx[k]] + v[idx[k + 1]] + v[idx[k + 2]]) / 3.0 - Vector3(0.5, 0.5, 0.5)
		assert_gt(mid.dot(n[idx[k]]), 0.0, "the normal points out of the cube")


func test_the_blocky_body_wears_a_built_hat_backpack_and_wings() -> void:
	var a := _make(BlockyAvatar)
	var look := AvatarLook.new()
	look.hat = &"crown"
	look.cape = &"hero"
	var code := _code({Vector3i(0, 0, 0): BlockIds.RED, Vector3i(0, 1, 0): BlockIds.YELLOW})
	for slot: StringName in WearRules.SLOTS:
		look.wear(slot, code)
	a.apply_look(look)
	var hat := a.find_child("built_hat", true, false) as Node3D
	assert_not_null(hat)
	assert_true(a.head_anchor().is_ancestor_of(hat), "on the head")
	assert_null(a.find_child("hat_crown", true, false), "the built hat takes the crown's place")
	assert_null(a.find_child("cape_hero", true, false), "the backpack takes the cape's place")
	var back := a.find_child("built_back", true, false) as Node3D
	assert_true(a.back_anchor().is_ancestor_of(back), "on the back")
	var wings := a.find_child("built_wings", true, false) as Node3D
	assert_not_null(wings.get_node_or_null("R"))
	assert_not_null(wings.get_node_or_null("L"))
	var before := (wings.get_node("R") as Node3D).rotation.y
	a.animate(0.0, false, 0.1)
	a.animate(0.0, false, 0.1)
	assert_ne((wings.get_node("R") as Node3D).rotation.y, before, "built wings flap")
	for mi in _meshes_of(hat):
		assert_eq(mi.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	# the hat sits on the head's top
	var aabb := (_meshes_of(hat)[0].mesh as ArrayMesh).get_aabb()
	assert_almost_eq(aabb.position.y, WearMesh.HEAD_TOP, 0.001)
	assert_almost_eq(aabb.size.y, 2 * WearMesh.HAT_SCALE, 0.001)


func test_the_realistic_person_wears_it_too() -> void:
	var a := _make(RealisticAvatar)
	var look := AvatarLook.new()
	look.wear(WearRules.HAT, _code({Vector3i.ZERO: BlockIds.GOLD}))
	a.apply_look(look)
	var hat := a.find_child("built_hat", true, false)
	assert_not_null(hat)
	assert_true(a.head_anchor().is_ancestor_of(hat))


func test_taking_it_off_frees_it() -> void:
	var a := _make(BlockyAvatar)
	var look := AvatarLook.new()
	look.wear(WearRules.HAT, _code({Vector3i.ZERO: BlockIds.GOLD}))
	a.apply_look(look)
	look.take_off(WearRules.HAT)
	a.apply_look(look)
	assert_null(a.find_child("built_hat", true, false))


## The avatar editor: picking a hat, cape or wings from the catalogue takes the built one in that place off.
func test_the_editors_tiles_take_a_built_wearable_off() -> void:
	var profile := ProfileData.new()
	var code := _code({Vector3i.ZERO: BlockIds.GOLD})
	for slot: StringName in WearRules.SLOTS:
		profile.avatar.wear(slot, code)
	var editor := AvatarEditor.new()
	editor.profile = profile
	editor.save_profile = func() -> void: pass
	add_child_autofree(editor)
	editor.pick(AvatarCatalog.HAT, &"cap")
	assert_false(editor.look.builds.has(WearRules.HAT))
	assert_true(editor.look.builds.has(WearRules.BACK), "only that place")
	editor.pick(AvatarCatalog.CAPE, &"hero")
	editor.pick(AvatarCatalog.WINGS, &"butterfly")
	assert_eq(editor.look.builds, {})
	editor.done()
	assert_eq(profile.avatar.builds, {})


## Sent with the look (Player.look_code, synced on spawn and on change): another player's game wears it; a
## wearable too big in a code from the network is dropped on its own (the rest of the look stays).
func test_other_players_see_it_and_a_bad_one_is_dropped() -> void:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = "4081"
	add_child_autofree(p)
	var look := AvatarLook.new()
	look.shirt = &"pink"
	look.wear(WearRules.WINGS, _code({Vector3i.ZERO: BlockIds.PAINTED_SKY, Vector3i(1, 0, 0): BlockIds.PAINTED_SKY}))
	p.look_code = look.to_code()
	assert_not_null(p.avatar.find_child("built_wings", true, false))
	var d := look.to_dict()
	var big := {}
	for x in 6:
		big[Vector3i(x, 0, 0)] = BlockIds.RED
	d["builds"] = {"hat": BuildCodec.encode(big)}
	p.look_code = JSON.stringify(d)
	assert_null(p.avatar.find_child("built_hat", true, false), "6 wide: not worn")
	assert_eq(p.avatar.look().shirt, &"pink")


func test_the_profile_keeps_it() -> void:
	var profile := ProfileData.new()
	var code := _code({Vector3i.ZERO: BlockIds.PAINTED_BLUE, Vector3i(1, 0, 0): BlockIds.GLASS})
	profile.avatar.wear(WearRules.BACK, code)
	var back := ProfileData.from_json(profile.to_json())
	assert_eq(back.avatar.builds, {WearRules.BACK: code})
