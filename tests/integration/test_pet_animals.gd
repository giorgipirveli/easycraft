extends GutTest
## The new pets' bodies (M3 Task 11): the fox, the parrot and Pip the robot are box-built like every animal
## (shared meshes, at most two draw calls, a small body), wear a collar when they are pets, and Pip shines in
## the realistic style with one shared material (the animals' shader, no new one). What guests see travels as
## synced properties (collar, heart) and RPCs (bark, point, dig). The fox sniffs out treasure faster.

const KINDS: Array[StringName] = [&"fox", &"parrot", &"pip"]

var _style := ""


func before_each() -> void:
	_style = BlockLibrary.style


func after_each() -> void:
	BlockLibrary.style = _style


func _animal(species: StringName, owner := 0) -> Animal:
	var a := Animal.new()
	a.setup({"species": species, "id": "t_%s" % species, "pos": Vector3(0, 40, 0), "owner": owner,
		"name": "Kiwi" if owner else ""})
	add_child_autofree(a)
	return a


func test_the_new_kinds_are_small_shared_box_models() -> void:
	for sp in KINDS:
		var a := _animal(sp)
		var b := _animal(sp)
		var meshes := a.find_children("*", "MeshInstance3D", true, false)
		assert_lte(meshes.size(), 2, "%s: the body and its moving part" % sp)
		assert_same((meshes[0] as MeshInstance3D).mesh, (b.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh,
			"%s shares one mesh" % sp)
		var box := (a.find_children("*", "CollisionShape3D", false, false)[0] as CollisionShape3D).shape as BoxShape3D
		assert_lte(maxf(box.size.x, box.size.z), 1.0, "%s footprint stays small" % sp)
		assert_not_null(a.find_child("Part", true, false), "%s wags or bobs something" % sp)


func test_a_pet_of_every_new_kind_wears_a_collar() -> void:
	for sp in KINDS:
		var pet := _animal(sp, 3)
		assert_not_null(pet.find_child("Collar", true, false), "%s wears a collar" % sp)
		assert_eq(pet.find_children("*", "Label3D", true, false).size(), 1, "%s has a name tag" % sp)


func test_pip_shines_in_the_realistic_style_with_one_shared_material() -> void:
	var pip := _animal(&"pip", 3)
	BlockLibrary.style = "realistic"
	pip._process(0.016)
	var body := pip.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	assert_same(body.material_override, Animal.pip_material())
	var shiny := Animal.pip_material()
	assert_true(shiny.vertex_color_use_as_albedo, "the animals' vertex colours (same shader, other numbers)")
	assert_gt(shiny.metallic, 0.5)
	var other := _animal(&"pip", 4)
	other._process(0.016)
	assert_same((other.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).material_override, shiny,
		"every Pip shares it")
	BlockLibrary.style = "blocky"
	pip._process(0.016)
	assert_null(body.material_override, "blocky Pip wears the animals' own material")


func test_guests_get_the_collar_and_the_heart_as_synced_properties() -> void:
	var pet := _animal(&"dog", 3)
	var sync := pet.get_node("Sync") as MultiplayerSynchronizer
	var cfg := sync.replication_config
	for prop in [".:collar", ".:happiness", ".:pet_name"]:
		assert_true(cfg.has_property(NodePath(prop)), prop)
		assert_eq(cfg.property_get_replication_mode(NodePath(prop)), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
			"%s only when it changes" % prop)


func test_a_pets_save_has_its_collar_and_heart() -> void:
	var pet := _animal(&"parrot", 3)
	pet.collar = 6
	pet.happiness = 0.9
	var saved := pet.to_save()
	assert_eq(saved.collar, 6)
	assert_eq(saved.happiness, 0.9)
	var back := Animal.new()
	back.setup({"species": &"parrot", "id": "p", "pos": Vector3.ZERO, "owner": 3, "name": "Kiwi",
		"collar": saved.collar, "happiness": saved.happiness})
	add_child_autofree(back)
	assert_eq(back.collar, 6)
	assert_eq(back.happiness, 0.9)


func _players(pos: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = "3"
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = pos
	return p


## Seconds of decisions until a pet starts a treasure trip towards a chest 10 blocks away.
func _first_trip(species: StringName) -> float:
	var pet := _animal(species, 3)
	pet.global_position = Vector3(0, 40, 0)
	pet.treasure_near = func(_from: Vector3) -> Vector3: return Vector3(10, 39, 0)
	var t := 0.0
	while not pet.sniffing and t < 60.0:
		pet._sniff_treasure()
		t += Animal.AI_INTERVAL
	return t


func test_the_fox_sets_off_for_buried_treasure_sooner_and_faster_than_the_dog() -> void:
	_players(Vector3(1, 40, 0))
	await get_tree().physics_frame
	var dog := _first_trip(&"dog")
	var fox := _first_trip(&"fox")
	assert_lt(fox, dog, "the fox is faster to sniff (%.1f s against %.1f s)" % [fox, dog])
	var trotting := _animal(&"fox", 3)
	trotting.global_position = Vector3(0, 40, 0)
	trotting.treasure_near = func(_from: Vector3) -> Vector3: return Vector3(10, 39, 0)
	for i in 1000:   # bounded: a pet that never sets off fails here instead of hanging the whole suite
		if trotting.sniffing:
			break
		trotting._sniff_treasure()
	assert_true(trotting.sniffing, "the fox sets off")
	assert_eq(trotting._pace, PetRules.sniff_pace(&"fox"), "and trots there at its own pace")
	assert_gte(_first_trip(&"cat"), 60.0, "a cat never sniffs")


func test_a_wild_fox_never_sniffs_for_anyone() -> void:
	_players(Vector3(1, 40, 0))
	await get_tree().physics_frame
	var wild := _animal(&"fox")
	wild.treasure_near = func(_from: Vector3) -> Vector3: return Vector3(10, 39, 0)
	for i in 400:
		wild._sniff_treasure()
	assert_false(wild.sniffing)
