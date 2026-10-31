extends GutTest
## Inside a Leaf's B1 (finding 3, 2026-10-18): BlockyAnimal wound each box face counter-clockwise seen from outside, and
## Godot culls that winding (its front faces are clockwise), so every animal, the golems and the hub tree's stones drew
## their inside walls: the right outline, the light on the wrong side. Each mesh built from BlockyAnimal._box now winds
## its faces as Godot's own BoxMesh does.


## +1 when a triangle's corners turn the way its normal says (right-handed), -1 when the other way.
static func _turns(a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> int:
	return 1 if (b - a).cross(c - a).dot(n) > 0.0 else -1


## Every triangle's turn in `arrays` (a Mesh's surface arrays, indexed or not).
static func _all_turns(arrays: Array) -> Array[int]:
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if idx.is_empty():
		for i in v.size():
			idx.append(i)
	var out: Array[int] = []
	for t in range(0, idx.size(), 3):
		out.append(_turns(v[idx[t]], v[idx[t + 1]], v[idx[t + 2]], n[idx[t]]))
	return out


func _godot_turn() -> int:
	var turns := _all_turns(BoxMesh.new().get_mesh_arrays())
	assert_eq(turns.count(turns[0]), turns.size(), "Godot's own box winds every face one way")
	return turns[0]


func test_every_animal_winds_its_faces_as_godots_box() -> void:
	var front := _godot_turn()
	for species: StringName in AnimalRules.SPECIES:
		var turns := _all_turns(BlockyAnimal.mesh_for(species).surface_get_arrays(0))
		assert_eq(turns.count(front), turns.size(), "%s: every face turned outwards" % species)


func test_the_golems_wind_their_faces_as_godots_box() -> void:
	var front := _godot_turn()
	for mesh: ArrayMesh in [GolemModels.body_mesh(), GolemModels.arm_mesh(), GolemModels.eyes_mesh()]:
		var turns := _all_turns(mesh.surface_get_arrays(0))
		assert_eq(turns.count(front), turns.size(), "a golem's mesh: every face turned outwards")


## Balance Altar's B1 (docs/devlog/parts/game-altar-b.md): every mesh its places build (AltarKit's Mesher: the temple,
## the altars, gems, balloons, crystals, the Glimmers, Hoot) winds its faces as Godot's own BoxMesh does, so no part of
## the temple is lit from inside. The rooms' default dressing (Decor) is the rooms' look's, not the altar's.
func test_the_balance_altar_s_meshes_wind_their_faces_as_godots_box() -> void:
	var front := _godot_turn()
	var places: Array[Node3D] = [TempleHall.new(), SkyRoom.new(), TempleArrival.new()]
	var checked := 0
	for place in places:
		add_child_autofree(place)
		if place is TempleHall:
			(place as TempleHall).raise_great(1.0)
			(place as TempleHall).show_hoot(true)
			(place as TempleHall).set_door_open(true)
		for g: Node in place.find_children("*", "GeometryInstance3D", true, false):
			if place.get_node_or_null("Decor") != null and place.get_node("Decor").is_ancestor_of(g):
				continue
			var mesh: Mesh = null
			if g is MeshInstance3D:
				mesh = (g as MeshInstance3D).mesh
			elif g is MultiMeshInstance3D:
				mesh = (g as MultiMeshInstance3D).multimesh.mesh
			if not mesh is ArrayMesh:
				continue
			for s in mesh.get_surface_count():
				var turns := _all_turns(mesh.surface_get_arrays(s))
				assert_eq(turns.count(front), turns.size(), "%s %s: every face turned outwards" % [place.name, g.name])
				checked += 1
	for kind: String in AltarHalls.GLIMMERS:
		for pose: String in [GlimmerModel.ASLEEP, GlimmerModel.AWAKE]:
			var turns := _all_turns(GlimmerModel.mesh(kind, pose).surface_get_arrays(0))
			assert_eq(turns.count(front), turns.size(), "the %s Glimmer %s" % [kind, pose])
	assert_gt(checked, 20, "the temple's meshes were found")


func test_hoot_winds_his_faces_as_godots_box() -> void:
	var front := _godot_turn()
	for part: StringName in [HootModel.BODY, HootModel.WING_LEFT, HootModel.WING_RIGHT]:
		var turns := _all_turns(HootModel.mesh(part).surface_get_arrays(0))
		assert_eq(turns.count(front), turns.size(), "Hoot's %s: every face turned outwards" % part)


func test_the_academy_and_the_crystals_stones_wind_their_faces_as_godots_box() -> void:
	var front := _godot_turn()
	var b := AcademyBuildings.new()
	b.setup({"pos": Vector3i(0, 70, -40), "facing": 0}, func(_x: int, _z: int) -> int: return 70)
	var meshes: Array[Mesh] = []
	for m: Node in b.find_children("*", "MeshInstance3D", true, false):
		meshes.append((m as MeshInstance3D).mesh)
	var c := DiscoveryCrystal.new()
	meshes.append(c.stones.mesh)
	for mesh in meshes:
		var turns := _all_turns(mesh.surface_get_arrays(0))
		assert_eq(turns.count(front), turns.size(), "%s: every face turned outwards" % mesh)
	b.free()
	c.free()
