extends GutTest
## Owner feedback #43 (spec §3c): EasyCraft's own default avatar, not the yellow-and-blue box person of another
## block game. New players and JUST ME wear peach skin, curly brown hair, rosy cheeks, an orange tee and teal
## trousers; every blocky body has a rounder head (its edges cut round, a little bigger) and every body in both
## styles wears the buddy badge on its chest (hidden under a full outfit). Every look saved before keeps its colours and parts,
## including profiles saved before avatars existed (they show the classic look, as they do today).


func _make(kind: GDScript) -> AvatarModel:
	var a: AvatarModel = kind.new()
	add_child_autofree(a)
	return a


func _box_color(a: Node, node_name: String) -> Color:
	var mi := a.find_child(node_name, true, false) as MeshInstance3D
	assert_not_null(mi, node_name)
	return (mi.material_override as StandardMaterial3D).albedo_color if mi else Color()


func _parts(look: AvatarLook) -> Dictionary:
	var d := look.to_dict()
	d.erase("emotes")
	d.erase("base")
	return d


func _classic_saved() -> Dictionary:
	## A look exactly as M3 Task 9 saved the old default (before owner #48's clothes).
	return {"skin": "classic", "face": "smile", "hair": "none", "hair_color": "brown", "hat": "none", "shirt": "blue",
		"pants": "jeans", "cape": "none", "wings": "none", "trail": "none", "outfit": "none",
		"emotes": ["wave", "cheer", "laugh", "thumbs_up", "clap", "sit", "dance_hop", "dance_robot"]}

# --- The look -------------------------------------------------------------------------------------------------

func test_a_new_player_wears_easycrafts_own_default() -> void:
	for look: AvatarLook in [ProfileData.new().avatar, AvatarLook.new()]:
		assert_eq(look.skin, &"peach")
		assert_eq(look.hair, &"curly")
		assert_eq(look.hair_color, &"brown")
		assert_eq(look.face, &"rosy", "a smile with rosy cheeks")
		assert_eq(look.shirt, &"orange")
		assert_eq(look.pants, &"teal")
		assert_eq(look.outfit, &"none")
	var r := AvatarLook.new().resolve()
	assert_ne(r.skin, AvatarCatalog.SKIN_TONES[&"classic"], "not the old yellow")
	assert_ne(r.shirt, AvatarCatalog.CLOTH[&"blue"], "not the old blue tee")
	assert_true(AvatarUnlocks.wearable(AvatarLook.new(), []).equals(AvatarLook.new()), "all free")


func test_just_me_starts_the_new_default_and_keeps_the_childs_skin() -> void:
	assert_eq(_parts(AvatarLook.start(AvatarCatalog.NEUTRAL)), _parts(AvatarLook.new()))
	var mine := AvatarLook.classic()
	mine.skin = &"brown"
	var just_me := AvatarLook.start(AvatarCatalog.NEUTRAL, mine)
	assert_eq(just_me.shirt, &"orange")
	assert_eq(just_me.skin, &"brown", "the child's own skin tone stays")


func test_the_classic_look_is_the_old_default() -> void:
	var classic := AvatarLook.classic()
	assert_eq(_parts(classic), _parts(AvatarLook.from_dict(_classic_saved())))
	assert_eq(classic.skin, &"classic")
	assert_eq(classic.shirt, &"blue")
	assert_eq(classic.pants, &"jeans")
	assert_eq(classic.hair, &"none")
	assert_eq(classic.face, &"smile")

# --- Profiles saved before keep their look ----------------------------------------------------------------------

func test_a_profile_with_the_old_default_keeps_it() -> void:
	var p := ProfileData.from_json(JSON.stringify({"username": "Leo", "age_band": "under_13", "avatar": _classic_saved()}))
	assert_eq(_parts(p.avatar), _parts(AvatarLook.classic()))


func test_a_profile_saved_before_avatars_existed_shows_the_classic_look() -> void:
	var p := ProfileData.from_json(JSON.stringify({"username": "Mia", "age_band": "under_13", "survivor_gold": 40}))
	assert_eq(_parts(p.avatar), _parts(AvatarLook.classic()), "as it looks today")
	assert_eq(p.avatar.base, AvatarCatalog.NEUTRAL)


func test_a_saved_look_missing_a_field_fills_it_from_the_classic_look() -> void:
	var saved := _classic_saved()
	saved.erase("shirt")
	saved["pants"] = "no_such_colour"
	saved["hat"] = "crown"   # an item the profile does not own: taken off, as before
	var p := ProfileData.from_json(JSON.stringify({"username": "Ana", "avatar": saved}))
	assert_eq(p.avatar.shirt, &"blue", "a missing field is the classic one, not the new default")
	assert_eq(p.avatar.pants, &"jeans")
	assert_eq(p.avatar.hat, &"none")


func test_a_saved_custom_look_is_kept_exactly() -> void:
	var look := AvatarLook.new()
	look.skin = &"tan"
	look.hair = &"ponytail"
	look.shirt = &"pink"
	look.pants = &"lilac"
	look.clothes = &"skirt"
	var p := ProfileData.new()
	p.avatar = look
	var back := ProfileData.from_json(p.to_json())
	assert_eq(_parts(back.avatar), _parts(look))

# --- Both bodies ------------------------------------------------------------------------------------------------

func test_the_blocky_body_wears_the_new_default() -> void:
	var a := _make(BlockyAvatar)
	a.apply_look(AvatarLook.new())
	await wait_process_frames(1)
	assert_eq(_box_color(a, "Head"), AvatarCatalog.SKIN_TONES[&"peach"])
	assert_eq(_box_color(a, "Torso"), AvatarCatalog.CLOTH[&"orange"])
	assert_eq(_box_color(a, "LeftLeg"), AvatarCatalog.CLOTH[&"teal"])
	assert_not_null(a.find_child("hair_curly", true, false), "curly hair")
	assert_eq(BlockyAvatar.SKIN, AvatarCatalog.SKIN_TONES[&"peach"], "the body's own first colours are the default's")
	assert_eq(BlockyAvatar.TORSO, AvatarCatalog.CLOTH[&"orange"])
	assert_eq(BlockyAvatar.LEGS, AvatarCatalog.CLOTH[&"teal"])


func test_an_old_player_keeps_the_classic_colours() -> void:
	var a := _make(BlockyAvatar)
	a.apply_look(AvatarLook.classic())
	await wait_process_frames(1)
	assert_eq(_box_color(a, "Head"), Color("f5cd30"), "the old yellow")
	assert_eq(_box_color(a, "Torso"), Color("0d69ac"))
	assert_null(a.find_child("hair_curly", true, false))


func test_the_realistic_person_wears_the_new_default() -> void:
	var a := _make(RealisticAvatar) as RealisticAvatar
	a.apply_look(AvatarLook.new())
	await wait_process_frames(1)
	var mat := a.body_mesh().get_surface_override_material(0) as ShaderMaterial
	assert_eq(mat.get_shader_parameter("shirt_color"), AvatarCatalog.CLOTH[&"orange"])
	assert_eq(mat.get_shader_parameter("pants_color"), AvatarCatalog.CLOTH[&"teal"])
	assert_ne(mat.get_shader_parameter("skin_tint"), Vector3.ONE, "peach, not the texture's own tone")


func test_the_blocky_head_is_rounder_and_a_little_bigger() -> void:
	var a := _make(BlockyAvatar)
	await wait_process_frames(1)
	var head := a.head_anchor()
	assert_almost_eq(head.scale.x, BlockyAvatar.HEAD_SCALE, 0.001)
	assert_gt(BlockyAvatar.HEAD_SCALE, 1.0, "a little bigger")
	var boxes: Array[Vector3] = []
	for n: String in ["Head", "HeadTall", "HeadDeep"]:
		var mi := a.find_child(n, true, false) as MeshInstance3D
		assert_not_null(mi, n)
		if mi:
			assert_true(head.is_ancestor_of(mi), "%s is on the head" % n)
			boxes.append((mi.mesh as BoxMesh).size)
			assert_eq(_box_color(a, n), _box_color(a, "Head"), "%s wears the skin" % n)
	# Three crossing boxes: the head's outer size is still a 0.5 cube (hats and hair fit), its edges are cut round.
	for axis in 3:
		var longest := 0.0
		var shortest := 1.0
		for s: Vector3 in boxes:
			longest = maxf(longest, s[axis])
			shortest = minf(shortest, s[axis])
		assert_almost_eq(longest, 0.5, 0.001)
		assert_lt(shortest, 0.46, "the edges are cut round")
	# Still 1.8 tall: the head's top at 1.8.
	var top := head.position.y + BlockyAvatar.PIVOT_Y + 0.25 * head.scale.y
	assert_almost_eq(top, 1.8, 0.011)


func test_every_body_wears_the_buddy_badge_on_its_chest() -> void:
	for kind: GDScript in [BlockyAvatar, RealisticAvatar]:
		var a := _make(kind)
		a.apply_look(AvatarLook.classic())
		await wait_process_frames(1)
		var badge := a.find_child(BuddyBadge.NODE_NAME, true, false) as Node3D
		assert_not_null(badge, "%s wears the badge (old looks too: it is the body's)" % kind.get_global_name())
		if badge:
			assert_true(a.body_anchor().is_ancestor_of(badge), "on the chest")
			var knight := AvatarLook.classic()
			knight.outfit = &"knight"
			a.apply_look(knight)
			assert_null(a.find_child(BuddyBadge.NODE_NAME, true, false), "hidden under a full outfit")
			a.apply_look(AvatarLook.new())
			assert_not_null(a.find_child(BuddyBadge.NODE_NAME, true, false), "back without it")


func test_the_badge_is_one_shared_mesh_with_the_parts_material() -> void:
	var a := BuddyBadge.mesh()
	assert_same(a, BuddyBadge.mesh(), "made once")
	assert_same(a.surface_get_material(0), AvatarParts.part_material(), "no new shader to compile")
	var colors := PackedColorArray()
	for s in a.get_surface_count():
		colors.append_array(a.surface_get_arrays(s)[Mesh.ARRAY_COLOR])
	var orange := false
	for c: Color in colors:
		if c.is_equal_approx(BuddyBadge.BUDDY):
			orange = true
	assert_true(orange, "the orange buddy")
