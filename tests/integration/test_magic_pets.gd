extends GutTest
## Buddy magic's pets (M3 Task 20b, spec §14.21): a befriended monster (BefriendRules.SPECIES) looks like its
## monster kind (its variant) without its weapon, shrunk to pet size; a boss's mini-buddy (MiniRules.SPECIES) is a
## tiny version of its boss. One shared mesh per kind, one small box, and they learn tricks like every pet; a
## friend's kind and tricks are saved with the world's pets.


func after_all() -> void:
	Audio.stop_all()


func _pet(species: StringName, variant: StringName, id := "p1", owner := 1) -> Animal:
	var a := Animal.new()
	a.setup({"species": species, "id": id, "pos": Vector3(1, 40, 2), "yaw": 0.0, "owner": owner, "name": "Jelly",
		"sitting": false, "variant": variant})
	add_child_autofree(a)
	a.set_physics_process(false)
	return a


func test_every_monster_kind_becomes_a_friend_with_its_own_shared_look() -> void:
	for kind: StringName in MonsterRules.KINDS:
		var a := _pet(BefriendRules.SPECIES, kind, "f_%s" % kind)
		var meshes := a.find_children("*", "MeshInstance3D", true, false)
		var body := meshes[0] as MeshInstance3D
		assert_same(body.mesh, MagicPetModels.mesh_for(BefriendRules.SPECIES, kind), "%s: shared" % kind)
		assert_same(body.mesh.surface_get_material(0), BlockyAnimal.mesh_for(&"pig").surface_get_material(0),
			"%s: the animals' material (no new shader)" % kind)
		var aabb := body.mesh.get_aabb()
		assert_lte(aabb.size.y, MagicPetModels.HEIGHT + MagicPetModels.HOVER + 0.01, "%s: pet sized" % kind)
		assert_lte(maxf(aabb.size.x, aabb.size.z), MagicPetModels.WIDTH + 0.01, str(kind))
		var box := ((a.find_children("*", "CollisionShape3D", false, false)[0] as CollisionShape3D).shape as BoxShape3D)
		assert_lte(maxf(box.size.x, box.size.z), 0.9, "a small body")


func test_a_friend_carries_no_club_or_bow() -> void:
	for kind: StringName in [MonsterRules.GOBLIN, MonsterRules.ARCHER]:
		var body := MonsterModels.boxes(kind, 1).filter(func(b: Array) -> bool: return b[3] != MonsterModels.ARM and b[3] != MonsterModels.BALL).size()
		assert_eq(MagicPetModels.friend_boxes(kind).size(), body + 1 + 2, "%s: its body, one arm, two pink cheeks" % kind)


func test_every_boss_has_a_tiny_look() -> void:
	var seen := {}
	for boss: StringName in MiniRules.MINIS:
		var a := _pet(MiniRules.SPECIES, boss, MiniRules.animal_id(boss, 1))
		var mesh := (a.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
		assert_same(mesh, MagicPetModels.mesh_for(MiniRules.SPECIES, boss), str(boss))
		assert_false(seen.has(mesh), "%s looks like its own boss" % boss)
		seen[mesh] = true
		assert_lte(mesh.get_aabb().size.y, 1.0, "%s is tiny" % boss)


func test_a_collar_fits_its_kind() -> void:
	var a := _pet(BefriendRules.SPECIES, MonsterRules.YETI)
	var band := MagicPetModels.collar_for(BefriendRules.SPECIES, MonsterRules.YETI)
	var collar := a.find_child("Collar", true, false) as MeshInstance3D
	assert_not_null(collar)
	assert_almost_eq(collar.position, band[0], Vector3.ONE * 0.001)


func test_a_friend_is_saved_with_its_kind_and_tricks() -> void:
	var a := _pet(BefriendRules.SPECIES, MonsterRules.GOBLIN)
	for i in TrickRules.TEACH_NEED:
		a.learn(&"wave")
	var saved := a.to_save()
	assert_eq(saved.variant, "goblin")
	var m := WorldMeta.new_random()
	m.pets = [saved]
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.pets.size(), 1)
	assert_eq(back.pets[0].variant, "goblin", "it comes back a goblin")
	assert_eq(back.pets[0].tricks, ["wave"])
	var again := _pet(BefriendRules.SPECIES, StringName(back.pets[0].variant), "p2")
	again.load_tricks(back.pets[0])
	assert_eq(again.learn(&"wave"), TrickRules.KNOWN, "never forgotten")


func test_a_saved_nonsense_kind_is_dropped() -> void:
	var m := WorldMeta.new_random()
	m.pets = [{"species": "monster_friend", "name": "Jelly", "pos": [0, 1, 0], "id": "x", "variant": "golem", "tricks": ["nope"]}]
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.pets[0].get("variant", ""), "golem", "a boss kind is a mini's variant: kept")
	m.pets[0].variant = "dragon_king"
	back = WorldMeta.from_json(m.to_json())
	assert_false(back.pets[0].has("variant"))
	assert_false(back.pets[0].has("tricks"))


func test_every_trick_move_plays_on_a_pet() -> void:
	var a := _pet(&"dog", &"")
	for move: StringName in TrickRules.MOVES:
		a.do_trick(move)
		assert_true(a._anim != null and a._anim.is_valid(), str(move))
