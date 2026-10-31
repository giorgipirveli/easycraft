extends GutTest
## Owner feedback #48 (spec §14.6a): girl looks are built in BOTH graphics styles. The blocky body wears
## box hair, faces, hats and clothes; the realistic person wears its own rounded shapes (hair balls and
## tails, real skirts) on its bones, and its face gets cartoon eyelashes and rosy cheeks from the skin
## shader. Everything shares meshes and materials like every other part (DEVELOPMENT.md §8).

const GIRL_HAIR: Array[StringName] = [&"long", &"bangs", &"ponytail", &"pigtails", &"braid", &"bun", &"buns", &"bob",
	&"curly"]


func _make(kind: GDScript) -> AvatarModel:
	var a: AvatarModel = kind.new()
	add_child_autofree(a)
	return a


func _look(fields: Dictionary) -> AvatarLook:
	return AvatarLook.from_dict(fields)


func _skin(a: RealisticAvatar) -> ShaderMaterial:
	return a.body_mesh().get_surface_override_material(0) as ShaderMaterial


func _box_color(a: Node, node_name: String) -> Color:
	var mi := a.find_child(node_name, true, false) as MeshInstance3D
	return (mi.material_override as StandardMaterial3D).albedo_color


## The part's merged mesh bounds in the avatar's own space (after the bones have posed).
func _bounds(a: AvatarModel, part: Node) -> AABB:
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in part.find_children("*", "MeshInstance3D", true, false):
		var b := a.global_transform.affine_inverse() * mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func test_girl_hair_is_built_in_both_styles() -> void:
	var blocky := _make(BlockyAvatar)
	var person := _make(RealisticAvatar) as RealisticAvatar
	for hair in GIRL_HAIR:
		var look := _look({"hair": hair, "hair_color": "purple"})
		blocky.apply_look(look)
		person.apply_look(look)
		assert_not_null(blocky.find_child("hair_%s" % hair, true, false), "blocky %s" % hair)
		var real := person.find_child("hair_%s_real" % hair, true, false)
		assert_not_null(real, "realistic %s" % hair)
		if real:
			assert_true(person.head_anchor().is_ancestor_of(real), "%s follows the head" % hair)
		assert_eq((_skin(person).get_shader_parameter("albedo_tex") as Texture2D).resource_path, RealisticAvatar.SKINS[1],
			"%s wears the long-haired, smooth-faced skin" % hair)


func test_a_realistic_ponytail_hangs_behind_the_head() -> void:
	var person := _make(RealisticAvatar) as RealisticAvatar
	person.apply_look(_look({"hair": "ponytail"}))
	await wait_process_frames(2)
	var tail := _bounds(person, person.find_child("hair_ponytail_real", true, false))
	assert_gt(tail.get_center().z, 0.12, "behind the head (+Z is the back)")
	assert_between(tail.get_center().y, 1.15, 1.75, "at the back of the head, down to the neck")
	assert_lt(absf(tail.get_center().x), 0.08, "in the middle")


func test_the_new_hats_are_worn_in_both_styles() -> void:
	for kind: GDScript in [BlockyAvatar, RealisticAvatar]:
		var a := _make(kind)
		for hat: StringName in [&"clips", &"flower_crown", &"bow"]:
			a.apply_look(_look({"hat": hat, "hair": "bangs"}))
			var node := a.find_child("hat_%s" % hat, true, false)
			if node == null:
				node = a.find_child("hat_%s_real" % hat, true, false)
			assert_not_null(node, "%s wears %s" % [kind.get_global_name(), hat])


func test_sweet_faces_have_lashes_and_rosy_cheeks_in_both_styles() -> void:
	var blocky := _make(BlockyAvatar)
	blocky.apply_look(_look({"face": "sweet"}))
	assert_not_null(blocky.find_child("face_sweet", true, false))
	var person := _make(RealisticAvatar) as RealisticAvatar
	person.apply_look(_look({"face": "sweet", "hair": "short"}))
	assert_eq(float(_skin(person).get_shader_parameter("lashes")), 1.0, "eyelashes in the skin shader")
	assert_eq(float(_skin(person).get_shader_parameter("blush")), 1.0, "rosy cheeks")
	assert_eq((_skin(person).get_shader_parameter("albedo_tex") as Texture2D).resource_path, RealisticAvatar.SKINS[1],
		"a face with lashes is the smooth-faced skin, even with short hair")
	person.apply_look(_look({"face": "rosy", "hair": "short"}))
	assert_eq(float(_skin(person).get_shader_parameter("lashes")), 0.0)
	assert_eq(float(_skin(person).get_shader_parameter("blush")), 1.0)
	assert_eq((_skin(person).get_shader_parameter("albedo_tex") as Texture2D).resource_path, RealisticAvatar.SKINS[0])
	person.apply_look(AvatarLook.classic())   # owner 43: the classic smile (the new default has rosy cheeks)
	assert_eq(float(_skin(person).get_shader_parameter("blush")), 0.0, "the classic face as before")


func test_every_clothes_cut_dresses_both_bodies() -> void:
	var blocky := _make(BlockyAvatar)
	var person := _make(RealisticAvatar) as RealisticAvatar
	for cut: StringName in AvatarCatalog.CUTS:
		var look := _look({"clothes": cut, "shirt": "lilac", "pants": "mint"})
		blocky.apply_look(look)
		person.apply_look(look)
		for e: StringName in AvatarCatalog.CUTS[cut].extras:
			var id := "extra_%s" % e
			assert_true(AvatarParts.has_part(id), "%s has a box recipe" % id)
			assert_not_null(blocky.find_child(id, true, false), "blocky %s: %s" % [cut, id])
			var real := person.find_child(id + "_real", true, false)
			if real == null:
				real = person.find_child(id, true, false)
			assert_not_null(real, "realistic %s: %s" % [cut, id])
			if real:
				assert_true(person.skeleton().is_ancestor_of(real), "%s moves with the bones" % id)


func test_a_realistic_skirt_hangs_from_the_hips() -> void:
	var person := _make(RealisticAvatar) as RealisticAvatar
	person.apply_look(_look({"clothes": "skirt", "pants": "rose"}))
	await wait_process_frames(2)
	var skirt := person.find_child("extra_skirt_real", true, false)
	assert_not_null(skirt)
	var box := _bounds(person, skirt)
	assert_between(box.end.y, 0.7, 0.95, "the waistband at the waist")
	assert_between(box.position.y, 0.3, 0.6, "down to the knees")
	assert_gt(box.size.x, 0.34, "wider than the hips")
	assert_eq(_skin(person).get_shader_parameter("pants_color"), AvatarCatalog.TIGHTS, "tights under it")


func test_the_blocky_body_wears_sleeves_puffs_boots_and_tights() -> void:
	var a := _make(BlockyAvatar)
	var sleeve := a.find_child("LeftSleeve", true, false) as MeshInstance3D
	var shoe := a.find_child("LeftShoe", true, false) as MeshInstance3D
	var short_y := sleeve.scale.y
	a.apply_look(_look({"clothes": "hoodie", "shirt": "mint"}))
	assert_gt(sleeve.scale.y, short_y * 2.0, "long sleeves")
	assert_eq(_box_color(a, "LeftSleeve"), AvatarCatalog.CLOTH[&"mint"])
	a.apply_look(_look({"clothes": "jacket", "shirt": "teal"}))
	assert_eq(_box_color(a, "Torso"), AvatarCatalog.JACKET, "the jacket")
	assert_eq(_box_color(a, "LeftSleeve"), AvatarCatalog.JACKET)
	assert_true(shoe.visible)
	assert_gt(shoe.scale.y, 1.5, "boots")
	a.apply_look(_look({"clothes": "dress"}))
	assert_gt(sleeve.scale.x, 1.1, "puffed sleeves")
	assert_eq(shoe.scale.y, 1.0)
	a.apply_look(_look({"clothes": "skirt", "pants": "rose"}))
	assert_eq(_box_color(a, "LeftLeg"), AvatarCatalog.TIGHTS)
	a.apply_look(AvatarLook.new())
	assert_eq(sleeve.scale, Vector3.ONE, "back to the classic short sleeves")
	assert_false(shoe.visible)


func test_the_girl_presets_dress_both_styles() -> void:
	for kind: GDScript in [BlockyAvatar, RealisticAvatar]:
		var a := _make(kind)
		var real := kind == RealisticAvatar
		a.apply_look(AvatarLook.preset(&"princess"))
		assert_not_null(a.find_child("hat_flower_crown", true, false), "the flower crown")
		assert_not_null(a.find_child("extra_gown_skirt_real" if real else "extra_gown_skirt", true, false), "the gown")
		assert_not_null(a.find_child("hair_bangs_real" if real else "hair_bangs", true, false), "long hair")
		a.apply_look(AvatarLook.preset(&"adventurer"))
		assert_not_null(a.find_child("hair_ponytail_real" if real else "hair_ponytail", true, false), "the ponytail")
		assert_not_null(a.find_child("extra_jacket_front_real" if real else "extra_jacket_front", true, false), "the jacket")


func test_girl_looks_share_meshes_and_materials() -> void:
	var a := _make(RealisticAvatar) as RealisticAvatar
	var b := _make(RealisticAvatar) as RealisticAvatar
	a.apply_look(AvatarLook.preset(&"princess"))
	b.apply_look(AvatarLook.preset(&"princess"))
	assert_same(_skin(a), _skin(b), "one skin material per look")
	var meshes := AvatarParts.mesh_count()
	var materials := AvatarParts.material_count()
	var skins := AvatarSkin.material_count()
	for kind: GDScript in [BlockyAvatar, RealisticAvatar]:
		var c := _make(kind)
		for i in 3:
			c.apply_look(AvatarLook.preset(&"princess"))
			c.animate(3.0, true, 0.016)
	var blocky := _make(BlockyAvatar)
	blocky.apply_look(AvatarLook.preset(&"princess"))
	var meshes_after_blocky := AvatarParts.mesh_count()
	var d := _make(BlockyAvatar)
	d.apply_look(AvatarLook.preset(&"princess"))
	assert_eq(AvatarParts.mesh_count(), meshes_after_blocky, "another princess makes no new meshes")
	assert_gte(meshes_after_blocky, meshes)
	assert_eq(AvatarSkin.material_count(), skins, "no new skin material for the same look")
	assert_lte(AvatarParts.material_count(), materials + 4, "a few body colours at most")
	for mi: MeshInstance3D in a.find_children("*", "MeshInstance3D", true, false):
		if mi == a.body_mesh():
			continue
		for s in mi.mesh.get_surface_count():
			assert_true(mi.mesh.surface_get_material(s) in [AvatarParts.part_material(), AvatarParts.part_glow_material()],
				"%s uses a shared part material" % mi.get_parent().name)


func test_bot_friends_wear_their_girl_and_boy_looks() -> void:
	var girl := BotBlockyAvatar.new()
	girl.bot_look = 1
	add_child_autofree(girl)
	assert_not_null(girl.find_child("hair_ponytail", true, false), "a girl friend's ponytail")
	assert_not_null(girl.find_child("extra_skirt", true, false), "and skirt")
	assert_eq(_box_color(girl, "Torso"), BotRules.LOOKS[1].torso, "in the bot's own shirt colour")
	assert_not_null(girl.find_child("Antenna", true, false), "still a bot")
	var boy := BotBlockyAvatar.new()
	boy.bot_look = 0
	add_child_autofree(boy)
	assert_not_null(boy.find_child("hair_spiky", true, false))
	assert_null(boy.find_child("extra_skirt", true, false))
	var person := BotRealisticAvatar.new()
	person.bot_look = 3
	add_child_autofree(person)
	assert_not_null(person.find_child("hair_pigtails_real", true, false), "pigtails in the realistic style too")
	var skin := person.body_mesh().get_surface_override_material(0) as StandardMaterial3D
	assert_not_null(skin, "the bot keeps its dyed skin")
	if skin:
		assert_eq(skin.albedo_texture.resource_path, BotRealisticAvatar.skin_path(3))


func test_a_remote_player_wears_the_girl_look_in_either_style() -> void:
	var player: Player = load("res://entities/player/player.tscn").instantiate()
	player.name = "9"
	add_child_autofree(player)
	player.look_code = AvatarLook.preset(&"princess").to_code()
	assert_not_null(player.avatar.find_child("extra_gown_skirt", true, false), "blocky gown")
	player.set_avatar_style("realistic")
	assert_not_null(player.avatar.find_child("extra_gown_skirt_real", true, false), "realistic gown")
	assert_not_null(player.avatar.find_child("hat_flower_crown", true, false))
