extends GutTest
## The learning places' look (2026-10-18, docs/devlog/parts/academy-look.md): the Discovery Academy as a landmark worth
## walking to, drawn in three meshes of warmed materials (the world's own block pictures, the lit pieces, the glowing
## ones): a tower crowned with turrets and an observatory dome over the trees, Professor Hoot perched on top, twelve
## picture-doors standing open with a lantern lit over each, a paved courtyard that follows the ground, lanterns round it
## at night, and the places kept for the games that come (the bakery's plot, the Word Tower's scaffolding, the Voyage
## Garden's bed, the temple's island above) marked with pictures, never words; nothing in a door's way. Hoot is one shared
## model (his body and two wings) that beats its wings in flight and folds them when he lands; the crystal has a halo
## that breathes, a ring of stones, and sparkles when touched.

const SITE := {"pos": Vector3i(0, 70, -40), "facing": 0}
const GROUND := 70
## The Academy's drawn triangles at most (W1's was 2.7K; the Quest's frame holds 750K, a phone's world view 300K-1M).
const TRIANGLES := 16000


func _census() -> Dictionary:
	var keys := {}
	for d: Dictionary in ShaderWarmup.census_draws():
		if d.has("material"):
			keys[ShaderWarmup.key(d.material)] = true
	return keys


func _flat(_x: int, _z: int) -> int:
	return GROUND


## A gently bumpy meadow: a block up or down here and there.
func _bumpy(x: int, z: int) -> int:
	return GROUND + (1 if (x * 7 + z * 13) % 5 == 0 else 0) - (1 if (x * 3 + z * 5) % 11 == 0 else 0)


func _academy(site: Dictionary = SITE, ground: Callable = _flat) -> AcademyBuildings:
	var b := AcademyBuildings.new()
	add_child_autofree(b)
	b.setup(site, ground)
	return b


func _pieces(b: AcademyBuildings, prefix: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Dictionary in b.look_pieces:
		if str(p.name).begins_with(prefix):
			out.append(p)
	return out


func _triangles(mesh: Mesh) -> int:
	var n := 0
	for i in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(i)
		n += ((arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() if arrays[Mesh.ARRAY_INDEX] != null
			else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return n


func _top(pieces: Array[Dictionary]) -> float:
	var hi := -INF
	for p: Dictionary in pieces:
		hi = maxf(hi, (p.box as AABB).abs().end.y)
	return hi


# --- Drawn little, in warmed materials -----------------------------------------------------------------------------

func test_the_academy_is_three_meshes_of_warmed_materials() -> void:
	var census := _census()
	var b := _academy()
	var meshes := b.find_children("*", "MeshInstance3D", true, false)
	var drawn := meshes.filter(func(m: Node) -> bool:
		return (m as MeshInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
	assert_eq(drawn.size(), 3, "the block pictures, the lit pieces, the glowing ones: one mesh each, Hoot in the lit")
	var triangles := 0
	for m: Node in drawn:
		assert_eq((m as MeshInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "%s casts no shadow" % m.name)
		triangles += _triangles((m as MeshInstance3D).mesh)
	assert_lte(triangles, TRIANGLES, "few triangles: %d" % triangles)
	gut.p("ACADEMY_TRIANGLES %d drawn, %d its shadow" % [triangles, _triangles((b.get_node("Shadow") as MeshInstance3D).mesh)])
	var shadow := b.get_node("Shadow") as MeshInstance3D
	assert_eq(shadow.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY, "a plain proxy casts its shadow")
	assert_lte(_triangles(shadow.mesh), 1500, "a cheap one")
	for m: Node in meshes:
		var desc := ShaderWarmup.describe((m as MeshInstance3D).material_override)
		assert_true(census.has(ShaderWarmup.key(desc)), "%s: %s" % [m.name, desc])
	assert_eq(b.find_children("*", "Label3D", true, false).size(), 0, "no words (owner #133)")
	assert_eq(b.find_children("*", "Light3D", true, false).size(), 0, "it glows with no light")


func test_its_faces_turn_outwards() -> void:
	var b := _academy()
	for m: Node in b.find_children("*", "MeshInstance3D", true, false):
		var mesh := (m as MeshInstance3D).mesh
		for s in mesh.get_surface_count():
			var arrays := mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var outward := 0
			for t in range(0, idx.size(), 3):
				if (v[idx[t + 1]] - v[idx[t]]).cross(v[idx[t + 2]] - v[idx[t]]).dot(n[idx[t]]) < 0.0:
					outward += 1   # Godot's front faces: clockwise seen from the front
			assert_eq(outward, idx.size() / 3, "%s: every face turned outwards" % m.name)


# --- A landmark ------------------------------------------------------------------------------------------------------

func test_the_tower_rises_over_the_trees_crowned_with_turrets_and_a_dome() -> void:
	var b := _academy()
	assert_eq(_pieces(b, "TurretRoof").size(), 4, "four turrets with pointed roofs")
	assert_gte(_top(_pieces(b, "TurretRoof")), AcademyBuildings.TOWER_TOP + 3.0, "their tips over the roof")
	assert_gte(_top(b.look_pieces), AcademyBuildings.TOWER_TOP + AcademyBuildings.PEDESTAL + 1.5,
		"Hoot on his perch the highest of all")
	assert_false(_pieces(b, "Dome").is_empty(), "an observatory dome")
	assert_false(_pieces(b, "Telescope").is_empty(), "its telescope to the sky")
	assert_gte(_pieces(b, "Window").size(), 16, "warm windows all round")


func test_its_walls_are_the_worlds_own_block_pictures() -> void:
	var b := _academy()
	var tiled: Array = b.look_pieces.filter(func(p: Dictionary) -> bool: return str(p.name).begins_with("Wall"))
	assert_gte(tiled.size(), 3, "the tower's walls")
	assert_not_null(b.get_node_or_null("Decor_Tiles"), "drawn with the blocks' own page (the world's style)")
	assert_eq((b.get_node("Decor_Tiles") as MeshInstance3D).material_override, LifeRoomDecor.tiles_material())


func test_hoot_perches_on_top_as_part_of_the_lit_mesh() -> void:
	var b := _academy()
	var hoot := _pieces(b, "Hoot")
	assert_false(hoot.is_empty())
	var low := INF
	for p: Dictionary in hoot:
		low = minf(low, (p.box as AABB).abs().position.y)
	assert_almost_eq(low, AcademyBuildings.TOWER_TOP + AcademyBuildings.PEDESTAL, 0.15, "his feet on the perch")
	assert_not_null(b.hoot, "where he perches")
	assert_almost_eq(b.hoot.position.y, AcademyBuildings.TOWER_TOP + AcademyBuildings.PEDESTAL, 0.01)


# --- The doors ------------------------------------------------------------------------------------------------------

func test_every_door_is_a_picture_door_standing_open_with_its_lantern_lit() -> void:
	var b := _academy()
	for door: String in AcademyPlaza.DOORS:
		assert_false(_pieces(b, door + "_Picture").is_empty(), "%s: its picture on its sign" % door)
		var lantern := _pieces(b, door + "_Lantern")
		assert_false(lantern.is_empty(), "%s: a lantern lit over it (open)" % door)
		assert_eq(_pieces(b, door + "_Leaf").size(), 2, "%s: its two leaves standing open" % door)
		assert_false(_pieces(b, door + "_Threshold").is_empty(), "%s: warm light at its threshold" % door)


func test_nothing_stands_in_a_doors_way() -> void:
	var b := _academy()
	for door: String in AcademyPlaza.DOORS:
		var s: Dictionary = AcademyPlaza.SPOTS[door]
		var spot: Vector2 = s.door
		var a := deg_to_rad(float(s.angle))
		var gate := Vector2(cos(a), sin(a)) * AcademyPlaza.RING
		for p: Dictionary in b.look_pieces:
			var name := str(p.name)
			if name.begins_with(door + "_") or name.begins_with("Paving") or name.begins_with("WalkUp"):
				continue   # its own gate, the ground underfoot
			var box := (p.box as AABB).abs()
			if box.position.y > 2.2 or box.end.y < 0.15:
				continue   # over a child's head or flat on the ground
			var flat := Rect2(Vector2(box.position.x, box.position.z), Vector2(box.size.x, box.size.z))
			for k in 6:   # from the walk-up spot to the gate, and the spot itself
				var at := spot.lerp(gate, k / 5.0)
				assert_false(flat.grow(0.4).has_point(at), "%s stands in %s's way (at %s)" % [name, door, at])


# --- The courtyard --------------------------------------------------------------------------------------------------

func test_the_paving_follows_the_ground() -> void:
	var b := _academy(SITE, _bumpy)
	var paving := _pieces(b, "Paving")
	var ring := 0
	var front := 0
	var beyond := {}
	for p: Dictionary in paving:
		var c := (p.box as AABB).abs().get_center()
		var flat := Vector2(c.x, c.z)
		if flat.length() >= AcademyBuildings.PAVED_IN - 0.01 and flat.length() <= AcademyBuildings.PAVED_OUT + 0.01:
			ring += 1
		if absf(c.x) <= 1.01 and c.z > AcademyBuildings.PAVED_OUT:
			front += 1
		for door: String in AcademyPlaza.DOORS:
			var d := (AcademyPlaza.SPOTS[door].door as Vector2).normalized()
			if flat.dot(d) > AcademyPlaza.RING + 1.0 and absf(flat.dot(Vector2(-d.y, d.x))) <= 0.8:
				beyond[door] = true
	assert_gte(ring, 30, "a paved ring round the tower")
	assert_gte(front, 2, "the front path towards the spawn")
	assert_eq(beyond.size(), AcademyPlaza.DOORS.size(), "a paved way up to every door")
	for p: Dictionary in paving:
		var box := (p.box as AABB).abs()
		var c := box.get_center()
		var w := AcademyPlaza.to_world(SITE, Vector2i(roundi(c.x), roundi(c.z)))
		var ground := float(_bumpy(w.x, w.y) - GROUND)
		assert_almost_eq(box.position.y, ground, 0.03, "%s laid on its own ground" % p.name)


func test_lanterns_light_the_courtyard_at_night() -> void:
	var b := _academy()
	assert_gte(_pieces(b, "Lamp").size(), 12, "lanterns round it (glowing: no light)")


# --- The places kept for the games that come -----------------------------------------------------------------------

func test_the_coming_games_places_are_marked_with_pictures() -> void:
	var b := _academy()
	for place: String in ["Bakery", "WordTower", "Garden", "Temple"]:
		assert_false(_pieces(b, place).is_empty(), "%s: its place kept" % place)
		assert_false(_pieces(b, place + "_Picture").is_empty(), "%s: a picture of what comes (never words)" % place)
	assert_gte(_top(_pieces(b, "Temple")), AcademyBuildings.TOWER_TOP + AcademyBuildings.PEDESTAL + 4.0,
		"the temple's island floats above the Academy")
	for p: Dictionary in _pieces(b, "Bakery") + _pieces(b, "Garden"):
		var box := (p.box as AABB).abs()
		var r := Vector2(box.get_center().x, box.get_center().z).length()
		assert_between(r, AcademyBuildings.TOWER_HALF_M + 0.5, AcademyPlaza.RING - 0.9, "%s: in the courtyard" % p.name)


func test_the_island_stands_alone() -> void:
	var b := _academy(AcademyPlaza.island(Vector2i(3, 4), 70))
	assert_true(b.island)
	for place: String in ["Bakery", "WordTower", "Garden", "Temple", "Lamp", "Paving", "maths_"]:
		assert_true(_pieces(b, place).is_empty(), "no %s on the island" % place)
	assert_eq(b.find_children("*", "MeshInstance3D", true, false).size(), 4, "three drawn and its shadow")


# --- Hoot ------------------------------------------------------------------------------------------------------------

func test_hoot_is_one_model_his_body_and_two_wings() -> void:
	var flyer := HootFlyer.new()
	add_child_autofree(flyer)
	var meshes := flyer.find_children("*", "MeshInstance3D", true, false)
	assert_eq(meshes.size(), 3, "his body (with his face and cap) and each wing")
	for m: Node in meshes:
		assert_eq((m as MeshInstance3D).material_override, LifeRoomDecor.lit_material(), "the warmed lit material")


func test_he_beats_his_wings_in_flight_and_folds_them_when_he_lands() -> void:
	var holder := Node3D.new()
	add_child_autofree(holder)
	var flyer := HootFlyer.new()
	holder.add_child(flyer)
	flyer.fly_in(Vector3(0, 70, -4), Vector3(0, 70, 0))
	var angles: Array[float] = []
	for i in 12:
		await wait_process_frames(2)
		angles.append(flyer.wing_angle())
	assert_gt(angles.max() - angles.min(), 0.5, "his wings beat while he flies")
	await wait_seconds(HootFlyer.IN_SECONDS + 0.6)
	assert_true(flyer.landed, "landed")
	assert_almost_eq(flyer.wing_angle(), 0.0, 0.05, "wings folded")


# --- The crystal -----------------------------------------------------------------------------------------------------

func test_the_crystal_draws_in_few_warmed_meshes() -> void:
	var census := _census()
	var c := DiscoveryCrystal.new()
	add_child_autofree(c)
	var meshes := c.find_children("*", "MeshInstance3D", true, false)
	assert_lte(meshes.size(), 3, "the crystals, their halo, the stones at their foot")
	for m: Node in meshes:
		var desc := ShaderWarmup.describe((m as MeshInstance3D).material_override)
		assert_true(census.has(ShaderWarmup.key(desc)), "%s: %s" % [m.name, desc])


func test_the_crystals_halo_breathes() -> void:
	var c := DiscoveryCrystal.new()
	add_child_autofree(c)
	var sizes: Array[float] = []
	for i in 30:
		await wait_process_frames(3)
		sizes.append(c.halo.scale.x)
	assert_gt(sizes.max() - sizes.min(), 0.04, "a slow glow in and out")


func test_the_halo_never_covers_the_numbers_or_the_gems() -> void:
	var c := DiscoveryCrystal.new()
	add_child_autofree(c)
	var box := c.halo.mesh.get_aabb()
	var widest := (1.0 + DiscoveryCrystal.BREATH) * maxf(box.size.x, box.size.z) * 0.5
	var highest := DiscoveryCrystal.LIFT + (1.0 + DiscoveryCrystal.BREATH) * box.end.y
	assert_lt(widest, DiscoveryCrystal.GEM_GAP - DiscoveryCrystal.GEM_SIZE, "its gems float beyond the halo")
	assert_lt(highest, c.count.position.y + DiscoveryCrystal.LIFT - 0.15, "the number it holds shows over the halo")


func test_a_touch_makes_it_sparkle() -> void:
	var holder := Node3D.new()
	add_child_autofree(holder)
	var c := DiscoveryCrystal.new()
	holder.add_child(c)
	var before: int = c.sparkles
	c.show_challenge({"kind": "make", "labels": ["1", "10"], "gems": [1, 10], "shown": "11"}, Vector3(0, 0, 3), "0")
	assert_eq(c.sparkles, before + 1, "the first touch sparkles")
