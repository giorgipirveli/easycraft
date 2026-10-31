extends GutTest
## M3 Task 9: a look (AvatarLook) is worn by both avatar styles. The blocky body colours its boxes and
## adds box parts (hair, hat, face, cape, wings, outfit pieces); the realistic person recolours its
## Kenney skin with a shader (skin, hair, shirt, pants, shoes) and wears the same box parts on its
## bones. Materials are shared: one per colour (box parts) and one per look (realistic skin), made
## once and reused, never per frame or per avatar (DEVELOPMENT.md §8: per-event materials cost
## 100+ ms frames on the emulator).


func _make(kind: GDScript) -> AvatarModel:
	var a: AvatarModel = kind.new()
	add_child_autofree(a)
	return a


func _look() -> AvatarLook:
	var look := AvatarLook.new()
	look.shirt = &"red"
	look.pants = &"green"
	look.skin = &"tan"
	look.hair = &"spiky"
	look.hair_color = &"blond"
	look.hat = &"crown"
	look.cape = &"hero"
	look.wings = &"bat"
	look.trail = &"sparkles"
	look.face = &"smile"   # owner 43: the default face is "rosy" now
	return look


func _mesh_color(a: Node, node_name: String) -> Color:
	var mi := a.find_child(node_name, true, false) as MeshInstance3D
	assert_not_null(mi, node_name)
	if mi == null:
		return Color()
	return (mi.material_override as StandardMaterial3D).albedo_color


func _realistic_material(a: RealisticAvatar) -> ShaderMaterial:
	return a.body_mesh().get_surface_override_material(0) as ShaderMaterial


func test_the_blocky_body_wears_the_colours() -> void:
	var a := _make(BlockyAvatar)
	a.apply_look(_look())
	assert_eq(_mesh_color(a, "Torso"), AvatarCatalog.CLOTH[&"red"])
	assert_eq(_mesh_color(a, "LeftLeg"), AvatarCatalog.CLOTH[&"green"])
	assert_eq(_mesh_color(a, "Head"), AvatarCatalog.SKIN_TONES[&"tan"])
	assert_eq(_mesh_color(a, "RightArm"), AvatarCatalog.SKIN_TONES[&"tan"])
	assert_eq(_mesh_color(a, "RightSleeve"), AvatarCatalog.CLOTH[&"red"], "short sleeves in the shirt colour")


func test_the_blocky_body_wears_the_parts() -> void:
	var a := _make(BlockyAvatar)
	a.apply_look(_look())
	for part: String in ["hair_spiky", "hat_crown", "cape_hero", "wings_bat", "face_smile"]:
		assert_not_null(a.find_child(part, true, false), part)
	assert_true(a.head_anchor().is_ancestor_of(a.find_child("hat_crown", true, false)), "the hat is on the head")
	assert_true(a.back_anchor().is_ancestor_of(a.find_child("cape_hero", true, false)), "the cape hangs on the back")
	assert_not_null(a.trail(), "a running trail")


func test_a_new_look_replaces_the_old_parts() -> void:
	var a := _make(BlockyAvatar)
	a.apply_look(_look())
	var plain := AvatarLook.new()
	a.apply_look(plain)
	await wait_process_frames(1)
	for part: String in ["hair_spiky", "hat_crown", "cape_hero", "wings_bat"]:
		assert_null(a.find_child(part, true, false), "%s is gone" % part)
	assert_null(a.trail(), "no trail")
	assert_eq(_mesh_color(a, "Torso"), BlockyAvatar.TORSO, "back to the default look")
	assert_true(a.look().equals(plain))


func test_box_part_materials_are_one_per_colour_and_shared() -> void:
	var a := _make(BlockyAvatar)
	var b := _make(BlockyAvatar)
	a.apply_look(_look())
	b.apply_look(_look())
	var ta := (a.find_child("Torso", true, false) as MeshInstance3D).material_override
	var tb := (b.find_child("Torso", true, false) as MeshInstance3D).material_override
	assert_same(ta, tb, "two avatars with a red shirt share one material")
	assert_same(ta, AvatarParts.material(AvatarCatalog.CLOTH[&"red"]), "the cached one")
	assert_same(AvatarParts.material(Color(0.1, 0.2, 0.3)), AvatarParts.material(Color(0.1, 0.2, 0.3)))
	assert_ne(AvatarParts.material(Color.RED), AvatarParts.material(Color.BLUE))
	var before := AvatarParts.material_count()
	for i in 5:
		a.apply_look(_look())
		a.animate(3.0, true, 0.016)
	assert_eq(AvatarParts.material_count(), before, "re-dressing makes no new materials")


## Draw calls matter on phones: each part is one merged mesh (one draw call, two when some boxes
## glow), shared by every avatar wearing it in the same colours, with the two shared part materials.
func test_each_part_is_one_shared_mesh_drawn_with_shared_materials() -> void:
	var a := _make(BlockyAvatar)
	var b := _make(RealisticAvatar)
	a.apply_look(_look())
	b.apply_look(_look())
	var crown_a := a.find_child("hat_crown", true, false)
	var crown_b := b.find_child("hat_crown", true, false)
	var meshes_a := crown_a.find_children("*", "MeshInstance3D", true, false)
	assert_eq(meshes_a.size(), 1, "one draw call for the whole crown")
	var mesh := (meshes_a[0] as MeshInstance3D).mesh
	assert_same((crown_b.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh, mesh,
		"both styles share the crown's mesh")
	for i in mesh.get_surface_count():
		assert_true(mesh.surface_get_material(i) in [AvatarParts.part_material(), AvatarParts.part_glow_material()],
			"a shared part material")
	var wings := a.find_child("wings_bat", true, false)
	assert_eq(wings.find_children("*", "MeshInstance3D", true, false).size(), 2, "a mesh per wing: they flap")
	var before := AvatarParts.mesh_count()
	var c := _make(BlockyAvatar)
	c.apply_look(_look())
	assert_eq(AvatarParts.mesh_count(), before, "a third avatar in the same look makes no new meshes")


func test_an_outfit_puts_on_its_helmet_and_pieces_and_hides_the_hair() -> void:
	var look := _look()
	look.outfit = &"knight"
	var a := _make(BlockyAvatar)
	a.apply_look(look)
	assert_not_null(a.find_child("hat_knight_helm", true, false), "helmet")
	assert_not_null(a.find_child("extra_knight_emblem", true, false), "emblem")
	assert_null(a.find_child("hat_crown", true, false), "the helmet replaces the hat")
	assert_null(a.find_child("hair_spiky", true, false), "the helmet hides the hair")
	assert_not_null(a.find_child("cape_hero", true, false), "the child's own cape stays")
	assert_eq(_mesh_color(a, "Torso"), AvatarCatalog.OUTFITS[&"knight"].shirt)


func test_every_part_and_outfit_builds_in_both_styles() -> void:
	var avatars: Array[AvatarModel] = [_make(BlockyAvatar), _make(RealisticAvatar)]
	for a in avatars:
		for slot: StringName in [AvatarCatalog.FACE, AvatarCatalog.HAIR, AvatarCatalog.HAT, AvatarCatalog.CAPE,
				AvatarCatalog.WINGS, AvatarCatalog.TRAIL, AvatarCatalog.OUTFIT]:
			for n: StringName in AvatarCatalog.items_in(slot):
				var look := AvatarLook.new()
				look.set(String(slot), n)
				a.apply_look(look)
				a.animate(3.0, true, 0.016)
		assert_true(true, "%s wore everything" % a.get_script().get_global_name())


func test_every_catalog_part_has_a_box_recipe() -> void:
	for slot: StringName in [AvatarCatalog.HAT, AvatarCatalog.CAPE, AvatarCatalog.WINGS, AvatarCatalog.HAIR, AvatarCatalog.FACE]:
		for n: StringName in AvatarCatalog.items_in(slot):
			if n != &"none":
				assert_true(AvatarParts.has_part("%s_%s" % [slot, n]), "%s %s" % [slot, n])
	for o: StringName in AvatarCatalog.OUTFITS:
		var outfit: Dictionary = AvatarCatalog.OUTFITS[o]
		assert_true(AvatarParts.has_part("hat_%s" % outfit.hat), "%s helmet" % o)
		for e: StringName in outfit.extras:
			assert_true(AvatarParts.has_part("extra_%s" % e), "%s %s" % [o, e])


func test_the_realistic_person_is_recoloured_by_one_shared_material_per_look() -> void:
	var a := _make(RealisticAvatar) as RealisticAvatar
	var b := _make(RealisticAvatar) as RealisticAvatar
	a.apply_look(_look())
	b.apply_look(_look())
	var mat := _realistic_material(a)
	assert_not_null(mat, "a recolour shader material")
	assert_same(_realistic_material(b), mat, "the same look shares one material")
	assert_eq(mat.get_shader_parameter("shirt_color"), AvatarCatalog.CLOTH[&"red"])
	assert_eq(mat.get_shader_parameter("pants_color"), AvatarCatalog.CLOTH[&"green"])
	assert_eq(mat.get_shader_parameter("hair_color"), AvatarCatalog.HAIR_COLORS[&"blond"])
	var other := _look()
	other.shirt = &"purple"
	b.apply_look(other)
	assert_ne(_realistic_material(b), mat, "another look, another material")
	var count := AvatarSkin.material_count()
	for i in 5:
		a.apply_look(_look())
		b.apply_look(other)
	assert_eq(AvatarSkin.material_count(), count, "wearing a look again reuses its material")


func test_the_realistic_classic_skin_keeps_the_texture_tone() -> void:
	var a := _make(RealisticAvatar) as RealisticAvatar
	a.apply_look(AvatarLook.classic())   # owner 43: the classic skin id (the new default is peach)
	assert_eq(_realistic_material(a).get_shader_parameter("skin_tint"), Vector3.ONE)
	var tan := AvatarLook.new()
	tan.skin = &"deep"
	a.apply_look(tan)
	var tint: Vector3 = _realistic_material(a).get_shader_parameter("skin_tint")
	assert_lt(tint.x, 1.0, "darker skin")


func test_long_hair_picks_the_long_haired_realistic_skin() -> void:
	var a := _make(RealisticAvatar) as RealisticAvatar
	var look := AvatarLook.new()
	look.hair = &"long"
	a.apply_look(look)
	assert_eq((_realistic_material(a).get_shader_parameter("albedo_tex") as Texture2D).resource_path, RealisticAvatar.SKINS[1])
	look.hair = &"short"
	a.apply_look(look)
	assert_eq((_realistic_material(a).get_shader_parameter("albedo_tex") as Texture2D).resource_path, RealisticAvatar.SKINS[0])


func test_the_realistic_person_wears_parts_on_its_bones() -> void:
	var a := _make(RealisticAvatar) as RealisticAvatar
	a.apply_look(_look())
	var hat := a.find_child("hat_crown", true, false) as Node3D
	var cape := a.find_child("cape_hero", true, false) as Node3D
	assert_not_null(hat)
	assert_not_null(cape)
	assert_true(a.skeleton().is_ancestor_of(hat), "the hat follows the head bone")
	assert_true(a.skeleton().is_ancestor_of(cape), "the cape follows the chest")
	assert_null(a.find_child("hair_spiky", true, false), "the realistic hair is its texture's")
	await wait_process_frames(2)
	var mi := hat.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var crown := a.global_transform.affine_inverse() * mi.global_transform * mi.get_aabb()
	assert_between(crown.get_center().y, 1.6, 2.0, "on top of the head")
	assert_between(crown.get_center().x, -0.1, 0.1, "centred")
	assert_almost_eq(hat.global_basis.get_scale().x, AvatarModel.REALISTIC_HEAD_SCALE, 0.05, "head-sized, not bone-scaled")


func test_an_outfit_pattern_reaches_the_realistic_shader() -> void:
	var a := _make(RealisticAvatar) as RealisticAvatar
	var look := AvatarLook.new()
	look.outfit = &"pirate"
	a.apply_look(look)
	var mat := _realistic_material(a)
	assert_eq(mat.get_shader_parameter("pattern"), AvatarCatalog.PATTERN_STRIPES)
	assert_eq(mat.get_shader_parameter("shirt_color"), AvatarCatalog.OUTFITS[&"pirate"].shirt)
	assert_gt((mat.get_shader_parameter("shoe_color") as Color).a, 0.5, "outfit shoes")
	assert_not_null(a.find_child("hat_pirate_hat", true, false))


func test_the_player_keeps_its_look_when_the_style_changes() -> void:
	var player: Player = load("res://entities/player/player.tscn").instantiate()
	player.name = "7"
	add_child_autofree(player)
	player.look_code = _look().to_code()
	assert_not_null(player.avatar.find_child("hat_crown", true, false), "blocky")
	player.set_avatar_style("realistic")
	assert_not_null(player.avatar.find_child("hat_crown", true, false), "realistic")
	assert_eq(_realistic_material(player.avatar as RealisticAvatar).get_shader_parameter("shirt_color"), AvatarCatalog.CLOTH[&"red"])
	player.set_avatar_style("blocky")
	assert_eq(_mesh_color(player.avatar, "Torso"), AvatarCatalog.CLOTH[&"red"])
