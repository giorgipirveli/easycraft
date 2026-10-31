extends GutTest
## Owner feedback #36 (spec §14.6b): every costume dresses BOTH graphics styles. The blocky body wears box parts;
## the realistic person wears the same hats, capes and back pieces on its bones and its own rounded "_real" clothes
## and faces (a nose, a beard), recoloured by the one skin shader. Parts are shared meshes like every other part.

## Task 9's torso pieces that only the blocky body wears (the realistic person shows those outfits' patterns in its
## skin shader instead). Every part the costume pack added is worn by both bodies.
const TASK9_TORSO_PIECES: Array[String] = ["extra_knight_emblem", "extra_space_badge", "extra_robot_panel",
	"extra_ninja_belt", "extra_pirate_stripes", "extra_candy_stripes", "extra_cosmic_stars"]


func _make(kind: GDScript) -> AvatarModel:
	var a: AvatarModel = kind.new()
	add_child_autofree(a)
	return a


func _skin(a: RealisticAvatar) -> ShaderMaterial:
	return a.body_mesh().get_surface_override_material(0) as ShaderMaterial


## The AvatarParts ids a resolved look puts on the blocky body.
func _blocky_parts(r: Dictionary) -> Array[String]:
	var out: Array[String] = ["face_%s" % r.face]
	if r.hair != &"none" and not r.hides_hair:
		out.append("hair_%s" % r.hair)
	for key: String in ["hat", "cape", "wings"]:
		if r[key] != &"none":
			out.append("%s_%s" % [key, r[key]])
	for e: StringName in r.extras:
		out.append("extra_%s" % e)
	return out


func test_every_costume_dresses_both_bodies() -> void:
	var blocky := _make(BlockyAvatar)
	var person := _make(RealisticAvatar) as RealisticAvatar
	for id: StringName in CostumeRules.ORDER:
		var look := CostumeRules.wear(id)
		blocky.apply_look(look)
		person.apply_look(look)
		var r := look.resolve()
		for part in _blocky_parts(r):
			assert_true(AvatarParts.has_part(part), "%s: %s has a box recipe" % [id, part])
			assert_not_null(blocky.find_child(part, true, false), "blocky %s wears %s" % [id, part])
			if part.begins_with("hair_") or part.begins_with("face_") and not AvatarParts.has_part(part + "_real"):
				continue   # the realistic hair and face are painted (Task 9, owner 48): only their add-ons are parts
			if AvatarParts.blocky_only(part) and not AvatarParts.has_part(part + "_real"):
				assert_has(TASK9_TORSO_PIECES, part, "%s: %s needs a realistic recipe" % [id, part])
				continue
			var real := person.find_child(part + "_real", true, false)
			if real == null:
				real = person.find_child(part, true, false)
			assert_not_null(real, "realistic %s wears %s" % [id, part])
			if real:
				assert_true(person.skeleton().is_ancestor_of(real), "%s: %s moves with the bones" % [id, part])


func test_every_costume_only_part_is_worn_by_both_bodies() -> void:
	var blocky := _make(BlockyAvatar)
	var person := _make(RealisticAvatar) as RealisticAvatar
	for item: String in AvatarCatalog.ITEMS:
		if AvatarCatalog.ITEMS[item].kind != AvatarCatalog.IN_COSTUME:
			continue
		var slot := AvatarCatalog.slot_of(item)
		var look := AvatarLook.new()
		look.set(String(slot), AvatarCatalog.name_of(item))
		blocky.apply_look(look)
		person.apply_look(look)
		var r := look.resolve()
		# only what the costume part puts on: the default look's own parts (owner #43's rosy face since 2026-09-25, a
		# shader-only blush on the realistic face) are the body's, not the costume's
		var base_parts := _blocky_parts(AvatarLook.new().resolve())
		var parts := _blocky_parts(r).filter(func(p: String) -> bool: return not base_parts.has(p))
		if slot == AvatarCatalog.TRAIL:
			assert_not_null(blocky.trail(), "blocky %s" % item)
			assert_not_null(person.trail(), "realistic %s" % item)
			assert_eq(person.trail().style, AvatarCatalog.name_of(item))
			continue
		assert_gt(parts.size(), 0, "%s puts something on" % item)
		for part: String in parts:
			assert_not_null(blocky.find_child(part, true, false), "blocky %s: %s" % [item, part])
			var real := person.find_child(part + "_real", true, false)
			if real == null and not AvatarParts.blocky_only(part):
				real = person.find_child(part, true, false)
			assert_not_null(real, "realistic %s: %s" % [item, part])


func test_dorothy_wears_silver_shoes_in_both_styles() -> void:
	var look := CostumeRules.wear(&"dorothy")
	var silver: Color = look.resolve().shoes
	var blocky := _make(BlockyAvatar)
	blocky.apply_look(look)
	var shoe := blocky.find_child("LeftShoe", true, false) as MeshInstance3D
	assert_true(shoe.visible)
	assert_eq((shoe.material_override as StandardMaterial3D).albedo_color, Color(silver, 1.0))
	var person := _make(RealisticAvatar) as RealisticAvatar
	person.apply_look(look)
	assert_eq(_skin(person).get_shader_parameter("shoe_color"), silver, "the realistic shoes are recoloured silver")


func test_the_realistic_face_wears_pinocchios_nose_and_merlins_beard() -> void:
	var person := _make(RealisticAvatar) as RealisticAvatar
	person.apply_look(CostumeRules.wear(&"pinocchio"))
	var nose := person.find_child("face_long_nose_real", true, false)
	assert_not_null(nose, "the nose")
	if nose:
		assert_true(person.face_anchor().is_ancestor_of(nose), "on the face")
	person.apply_look(CostumeRules.wear(&"merlin"))
	assert_null(person.find_child("face_long_nose_real", true, false), "a new costume takes the old face off")
	var beard := person.find_child("face_beard_real", true, false)
	assert_not_null(beard, "the beard")
	if beard:
		assert_true(person.face_anchor().is_ancestor_of(beard), "on the face")


func test_the_tin_woodman_is_tin_all_over() -> void:
	var look := CostumeRules.wear(&"tin_woodman")
	var r := look.resolve()
	assert_eq(r.pattern, AvatarCatalog.PATTERN_METAL, "metal on the realistic person")
	assert_eq(r.sleeves, r.shirt, "tin arms, not bare ones")
	var blocky := _make(BlockyAvatar)
	blocky.apply_look(look)
	assert_not_null(blocky.find_child("extra_tin_heart", true, false), "the heart the Wizard gave him")
	assert_null(blocky.find_child("hair_%s" % look.hair, true, false), "the funnel hat hides the hair")


func test_wearing_every_costume_again_makes_no_new_materials() -> void:
	var blocky := _make(BlockyAvatar)
	var person := _make(RealisticAvatar) as RealisticAvatar
	for id: StringName in CostumeRules.ORDER:
		blocky.apply_look(CostumeRules.wear(id))
		person.apply_look(CostumeRules.wear(id))
	var parts := AvatarParts.material_count()
	var skins := AvatarSkin.material_count()
	var meshes := AvatarParts.mesh_count()
	for id: StringName in CostumeRules.ORDER:
		blocky.apply_look(CostumeRules.wear(id))
		person.apply_look(CostumeRules.wear(id))
	assert_eq(AvatarParts.material_count(), parts, "the body's colours are shared")
	assert_eq(AvatarSkin.material_count(), skins, "one realistic skin material per look, kept")
	assert_eq(AvatarParts.mesh_count(), meshes, "each part's merged mesh is made once")
