extends GutTest
## Tier weapons in the world (M2 Task 6): spear, mace and shield models, tier looks (a cached
## material per tier and 1-5 countable bands, never colour alone), the held item and its animations.

const NEW_KINDS := [ItemIds.SPEAR, ItemIds.MACE, ItemIds.SHIELD_WOOD]
const ALL_KINDS := [ItemIds.SWORD, ItemIds.BOW, ItemIds.PICKAXE, ItemIds.AXE, ItemIds.SPEAR, ItemIds.MACE, ItemIds.SHIELD_WOOD]


## Triangles that wind counter-clockwise seen from outside (along their vertex normal).
func _inside_out(arrays: Array) -> int:
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var wrong := 0
	for i in range(0, v.size(), 3):
		var face := (v[i + 1] - v[i]).cross(v[i + 2] - v[i])
		if face.length() > 0.000001 and face.dot(n[i]) > 0.0:
			wrong += 1
	return wrong


func _mark_boxes(m: ArrayMesh) -> int:
	var colors: PackedColorArray = m.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var n := 0
	for c in colors:
		if c.is_equal_approx(WeaponModels.TIER_MARK):
			n += 1
	return n / 36     # a box is 6 faces of 2 triangles


# --- Models ---

func test_spear_mace_and_shield_are_one_cheap_mesh_each() -> void:
	for kind: int in NEW_KINDS:
		var m := WeaponModels.mesh_for(kind) as ArrayMesh
		assert_not_null(m, ItemIds.display_name(kind))
		if m == null:
			continue
		assert_eq(m.get_surface_count(), 1, "one draw call: %s" % ItemIds.display_name(kind))
		assert_ne(m.surface_get_format(0) & Mesh.ARRAY_FORMAT_COLOR, 0, "vertex coloured")
		assert_eq(_inside_out(m.surface_get_arrays(0)), 0, "faces outwards: %s" % ItemIds.display_name(kind))
	var spear := WeaponModels.mesh_for(ItemIds.SPEAR).get_aabb()
	assert_between(spear.size.z, 1.4, 1.9, "a long spear")
	assert_lt(spear.position.z, -1.2, "its tip far ahead of the hand")
	assert_lt(maxf(spear.size.x, spear.size.y), 0.3, "thin")
	var mace := WeaponModels.mesh_for(ItemIds.MACE).get_aabb()
	assert_lt(mace.size.length(), 1.2, "hand-sized")
	var shield := WeaponModels.mesh_for(ItemIds.SHIELD_WOOD).get_aabb()
	assert_between(shield.size.x, 0.5, 0.8, "a round shield")
	assert_lt(shield.size.z, 0.2, "flat, facing forward")


func test_every_tier_item_is_a_cached_mesh_with_tier_plus_one_bands() -> void:
	for kind: int in ALL_KINDS:
		var ids: Array = WeaponRules.TIERS[kind]
		for t in 5:
			var m := WeaponModels.mesh_for(ids[t]) as ArrayMesh
			assert_not_null(m, ItemIds.display_name(ids[t]))
			assert_same(WeaponModels.mesh_for(ids[t]), m, "built once")
			assert_eq(m.get_surface_count(), 1)
			assert_eq(_mark_boxes(m), t + 1, "bands count the tier: %s" % ItemIds.display_name(ids[t]))
			assert_eq(_inside_out(m.surface_get_arrays(0)), 0, ItemIds.display_name(ids[t]))
	assert_null(WeaponModels.mesh_for(ItemIds.POTION_SPEED), "potions are not held")


func test_one_cached_material_per_tier() -> void:
	var base := WeaponModels.material()
	assert_same(WeaponModels.tier_material(WeaponRules.TIER_WOOD), base, "wood keeps the M1b material")
	var seen := {}
	for t in range(1, 5):
		var mat := WeaponModels.tier_material(t) as StandardMaterial3D
		assert_same(WeaponModels.tier_material(t), mat, "cached")
		assert_false(seen.has(mat), "one per tier")
		seen[mat] = true
		assert_eq(mat.albedo_color, ItemRarity.model_tint(t))
		assert_true(mat.vertex_color_use_as_albedo, "same shader as the M1b models (no new compile)")
		assert_eq(mat.transparency, base.transparency)
		assert_eq(mat.shading_mode, base.shading_mode)


# --- The held item ---

func test_a_held_tier_weapon_uses_its_mesh_and_tier_material() -> void:
	var held := HeldItem.new()
	add_child_autofree(held)
	held.show_item(ItemIds.MACE_CRYSTAL)
	var mi := held.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	assert_true(held.visible)
	assert_same(mi.mesh, WeaponModels.mesh_for(ItemIds.MACE_CRYSTAL))
	assert_same(mi.material_override, WeaponModels.tier_material(WeaponRules.TIER_CRYSTAL))
	held.show_item(ItemIds.SWORD)
	assert_null(mi.material_override, "the wood tier needs no override")
	held.show_item(ItemIds.SHIELD_IRON)
	assert_true(held.visible, "a shield is held")
	assert_same(mi.material_override, WeaponModels.tier_material(WeaponRules.TIER_IRON))
	held.show_item(ItemIds.POTION_JUMP)
	assert_false(held.visible, "a potion is not")


func test_tier_weapons_swing_like_their_kind() -> void:
	assert_eq(HeldItem.swing_name(ItemIds.SWORD_COSMIC, 0), &"slash")
	assert_eq(HeldItem.swing_name(ItemIds.SWORD_IRON, 2), &"spin")
	assert_eq(HeldItem.swing_name(ItemIds.AXE_STONE, 0), &"chop")
	assert_eq(HeldItem.swing_name(ItemIds.SPEAR_IRON, 0), &"thrust")
	assert_eq(HeldItem.swing_name(ItemIds.SPEAR, WeaponRules.THROW), &"throw")
	assert_eq(HeldItem.swing_name(ItemIds.MACE, 0), &"smash")
	assert_eq(HeldItem.swing_name(ItemIds.SHIELD_WOOD, 0), &"")


## Steps the animation by hand (no real-time waits: the shared PC can be slow).
func test_a_thrust_pushes_the_spear_forward_and_back() -> void:
	var held := HeldItem.new()
	add_child_autofree(held)
	held.show_item(ItemIds.SPEAR)
	held.play_attack(ItemIds.SPEAR, 0, true)
	var farthest := 0.0
	for i in 12:
		held._swing.custom_step(0.02)
		held._process(0.0)
		farthest = minf(farthest, held.position.z)
	assert_lt(farthest, -0.3, "the spear shoots forward (-Z)")
	for i in 20:
		held._swing.custom_step(0.02)
	held._process(0.0)
	assert_almost_eq(held.position.z, 0.0, 0.01, "and comes back")


func test_the_blocky_arm_swings_the_mace_overhead() -> void:
	var avatar := BlockyAvatar.new()
	add_child_autofree(avatar)
	avatar.play_attack(ItemIds.MACE_COSMIC)
	var highest := 0.0
	for i in 12:
		avatar._attack.custom_step(0.05)
		avatar.animate(0.0, true, 0.05)
		highest = maxf(highest, avatar._right_arm.rotation.x)
	assert_gt(highest, 2.0, "up over the head like the hammer")
