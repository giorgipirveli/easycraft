extends GutTest
## The rooms' look brief (2026-10-17, docs/devlog/parts/rooms-look.md): the practice rooms' shared look kit. Decoration
## is drawn as few meshes as can be: every piece of one material merged into one mesh (the lit pieces in their colours,
## the floors and walls in the game's own block pictures, the glowing ones), each piece remembered as a box for the
## rooms' keep-clear rules; a room's static scenery (its LifeRoomKit boxes, cylinders and spheres) merges into one mesh
## after it is built, while everything a room moves, hides, glows or names stays itself. The room brings its own warm
## sun (the world's below is put away while it shows, given back after) and a soft sky; every material is one the game
## already warms up (the web's shader warm-up).


func _census() -> Dictionary:
	var keys := {}
	for d: Dictionary in ShaderWarmup.census_draws():
		if d.has("material"):
			keys[ShaderWarmup.key(d.material)] = true
	return keys


func _bare_room() -> LifeRoom:
	var r := LifeRoom.new("little")
	add_child_autofree(r)
	return r


func test_many_pieces_of_one_material_draw_as_one_mesh() -> void:
	var holder := Node3D.new()
	add_child_autofree(holder)
	var d := LifeRoomDecor.new()
	for i in 20:
		d.box("Shelf%d" % i, Vector3(0.5, 0.05, 0.25), Vector3(i * 0.6, 1.0, 0), Color("a8642a"))
		d.cylinder("Pot%d" % i, 0.1, 0.2, Vector3(i * 0.6, 0.1, 1), Color("d9774a"))
	for i in 5:
		d.tiled("Floor%d" % i, LifeRoomDecor.PLANKS, Vector3(2, 0.05, 2), Vector3(i * 2, -0.025, 3))
	d.glow_box("Window", Vector3(1, 1, 0.02), Vector3(0, 1.5, -2), Color("bfe3ff"))
	var made := d.commit(holder)
	var meshes := made.find_children("*", "MeshInstance3D", true, false)
	assert_eq(meshes.size(), 3, "one mesh each: the lit pieces, the block pictures, the glowing ones")
	assert_eq(d.pieces.size(), 46, "every piece is remembered")
	for m: Node in meshes:
		assert_eq((m as MeshInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, str(m.name))


func test_every_material_of_the_kit_is_one_the_game_already_warms() -> void:
	var census := _census()
	var holder := Node3D.new()
	add_child_autofree(holder)
	var d := LifeRoomDecor.new()
	d.box("A", Vector3.ONE, Vector3.ZERO, Color.RED)
	d.tiled("B", LifeRoomDecor.BRICK, Vector3.ONE, Vector3(2, 0, 0))
	d.glow_box("C", Vector3.ONE, Vector3(4, 0, 0), Color.WHITE)
	d.sky(Color("6fb2ec"), Color("d8ecfa"), Color("8cc56a"))
	d.glass("D", Vector3(1, 1, 0.02), Vector3(6, 0, 0))
	var made := d.commit(holder)
	for m: Node in made.find_children("*", "MeshInstance3D", true, false):
		var desc := ShaderWarmup.describe((m as MeshInstance3D).material_override)
		assert_true(census.has(ShaderWarmup.key(desc)), "%s: %s" % [m.name, desc])


func test_a_piece_is_remembered_as_its_box_in_the_rooms_space() -> void:
	var d := LifeRoomDecor.new()
	d.box("Turned", Vector3(2, 1, 0.5), Vector3(1, 0.5, -3), Color.WHITE, PI / 2)
	var p: Dictionary = d.pieces[0]
	var b: AABB = p.box
	assert_eq(str(p.name), "Turned")
	assert_eq(str(p.kind), LifeRoomDecor.DECOR)
	assert_almost_eq(b.size.x, 0.5, 0.01, "turned a quarter: its depth across")
	assert_almost_eq(b.size.z, 2.0, 0.01)
	assert_almost_eq(b.get_center().distance_to(Vector3(1, 0.5, -3)), 0.0, 0.01)


func test_a_tiled_face_shows_its_block_picture_once_a_metre() -> void:
	var holder := Node3D.new()
	add_child_autofree(holder)
	var d := LifeRoomDecor.new()
	d.tiled("Floor", LifeRoomDecor.PLANKS, Vector3(3, 0.05, 2), Vector3.ZERO)
	var mesh := (d.commit(holder).find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	var arrays := mesh.surface_get_arrays(0)
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var tile := LifeRoomDecor.PLANKS
	for uv in uvs:
		assert_true(uv.x >= tile.x / 8.0 - 0.0001 and uv.x <= (tile.x + 1) / 8.0 + 0.0001, "inside the planks' tile: %s" % uv)
		assert_true(uv.y >= tile.y / 8.0 - 0.0001 and uv.y <= (tile.y + 1) / 8.0 + 0.0001, "inside the planks' tile: %s" % uv)
	var top := 0
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for n in normals:
		if n.y > 0.9:
			top += 1
	assert_eq(top, 3 * 2 * 4, "the 3 x 2 m top is six pictures (four corners each)")
	assert_eq(arrays[Mesh.ARRAY_TANGENT].size(), uvs.size() * 4, "tangents for the realistic pictures' normal maps")


func test_faces_point_outwards() -> void:
	var holder := Node3D.new()
	add_child_autofree(holder)
	var d := LifeRoomDecor.new()
	d.box("Box", Vector3(1, 2, 3), Vector3(5, 1, 0), Color.WHITE)
	var arrays := (d.commit(holder).find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i in range(0, idx.size(), 3):
		var a := v[idx[i]]
		var b := v[idx[i + 1]]
		var c := v[idx[i + 2]]
		var centre := (a + b + c) / 3.0
		# Godot's front faces wind clockwise seen from the front: (b - a) x (c - a) points into the box
		var n := (b - a).cross(c - a)
		assert_lt(n.dot(centre - Vector3(5, 1, 0)), 0.0, "triangle %d winds as a front face seen from outside" % (i / 3))


func test_a_cones_faces_point_outwards_and_none_is_flat() -> void:
	var holder := Node3D.new()
	add_child_autofree(holder)
	var d := LifeRoomDecor.new()
	d.cylinder("Roof", 1.0, 2.0, Vector3(0, 1, 0), Color.WHITE, 0.0, 8)   # a point at the top (a turret's roof)
	d.cylinder("Corbel", 0.0, 1.0, Vector3(5, 0.5, 0), Color.WHITE, 0.8, 8)   # a point at the foot
	var arrays := (d.commit(holder).find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i in range(0, idx.size(), 3):
		var n := (v[idx[i + 1]] - v[idx[i]]).cross(v[idx[i + 2]] - v[idx[i]])
		assert_gt(n.length(), 0.0001, "triangle %d has an area (no flat sliver)" % (i / 3))
		assert_lt(n.dot(normals[idx[i]]), 0.0, "triangle %d winds as a front face seen from outside" % (i / 3))


func test_the_sky_is_a_dome_round_the_room_seen_from_inside() -> void:
	var holder := Node3D.new()
	add_child_autofree(holder)
	var d := LifeRoomDecor.new()
	d.sky(Color("6fb2ec"), Color("d8ecfa"), Color("8cc56a"))
	var sky := d.commit(holder).get_node("Sky") as MeshInstance3D
	assert_not_null(sky, "the sky has a mesh of its own (a night can tint it)")
	var aabb := sky.get_aabb()
	assert_gt(aabb.size.x, 60.0, "round the whole room")
	assert_lt(aabb.size.x * 0.5, 80.0, "inside the room camera's far plane (80 m)")
	var arrays := sky.mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var n := (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]])
	assert_gt(n.dot((v[idx[0]] + v[idx[1]] + v[idx[2]]) / 3.0), 0.0, "its front faces look in")
	var colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var top := colours[0]
	var low := colours[0]
	var top_y := -INF
	var low_y := INF
	for i in v.size():
		if v[i].y > top_y:
			top_y = v[i].y
			top = colours[i]
		if v[i].y >= 0.0 and v[i].y < low_y:
			low_y = v[i].y
			low = colours[i]
	assert_gt(low.get_luminance(), top.get_luminance(), "light at the horizon, deeper blue above")


func test_a_rooms_scenery_merges_into_one_mesh_and_what_it_uses_stays() -> void:
	var r := LifeRoomProbe.new()
	add_child_autofree(r)
	var sc := r.scenery()
	assert_true(r.is_ancestor_of(sc))
	assert_eq(sc.find_children("Table*", "", true, false).size(), 0,
		"the twenty static boxes and their legs merged")
	assert_not_null(r.get_node_or_null("Scenery/Decor_Lit"), "into one lit mesh")
	assert_true(is_instance_valid(r.door) and r.door.is_inside_tree(), "a node the room keeps stays itself")
	assert_true(is_instance_valid(r.target_node("cup")) and r.target_node("cup").is_inside_tree(), "a target stays")
	assert_not_null(r.get_node_or_null("Scenery/LampPole"), "a target's parent stays (its child would go with it)")
	assert_not_null(r.get_node_or_null("Scenery/Boxes"), "a hidden thing stays (it shows later)")
	var buddy := r.get_node_or_null("Scenery/Buddy")
	assert_true(buddy is LifeBuddy and buddy.find_children("*", "MeshInstance3D", true, false).size() > 5,
		"a buddy (its own script) stays whole")
	assert_not_null(r.get_node_or_null("Scenery/Glass"), "a see-through thing stays")
	var baked := r.look_pieces.filter(func(p: Dictionary) -> bool: return str(p.kind) == LifeRoomDecor.BAKED)
	assert_eq(baked.size(), 40, "each merged box is remembered")
	var first: AABB = (baked.filter(func(p: Dictionary) -> bool: return str(p.name) == "Table0")[0] as Dictionary).box
	assert_almost_eq(first.get_center().distance_to(Vector3(0, 0.75, -2)), 0.0, 0.01, "where it stood")


func test_the_merged_scenery_keeps_each_things_place_and_colour() -> void:
	var r := LifeRoomProbe.new()
	add_child_autofree(r)
	var lit := r.get_node("Scenery/Decor_Lit") as MeshInstance3D
	var arrays := lit.mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var c: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var found := false
	for i in v.size():
		if v[i].distance_to(Vector3(0.6, 1.5, -1.6)) < 0.001:   # Table0's top corner (1.2 x 1.5 x 0.8 at (0, 0.75, -2))
			found = true
			assert_almost_eq(c[i].r, LifeRoomProbe.WOOD.r, 0.01)
			assert_almost_eq(c[i].g, LifeRoomProbe.WOOD.g, 0.01)
	assert_true(found, "its corner where it was")


func test_the_rooms_own_sun_puts_the_worlds_away_while_it_shows() -> void:
	var world_sun := DirectionalLight3D.new()
	add_child_autofree(world_sun)
	var r := _bare_room()
	var suns := r.find_children("*", "DirectionalLight3D", true, false)
	assert_eq(suns.size(), 1, "one warm key light of its own")
	var sun := suns[0] as DirectionalLight3D
	assert_false(sun.shadow_enabled, "no new shadows")
	assert_false(world_sun.visible, "the world's sun is away while the room shows")
	r.get_parent().remove_child(r)
	assert_true(world_sun.visible, "and back after")
	r.free()


func test_a_world_sun_hidden_before_stays_hidden() -> void:
	var world_sun := DirectionalLight3D.new()
	world_sun.visible = false
	add_child_autofree(world_sun)
	var r := _bare_room()
	r.get_parent().remove_child(r)
	assert_false(world_sun.visible, "the room gives back only what it put away")
	r.free()


func test_a_room_draws_with_the_worlds_tone() -> void:
	var r := _bare_room()
	assert_eq(r.env.tonemap_mode, Environment.TONE_MAPPER_ACES, "the worlds' ACES (the visuals brief)")
	assert_lt(r.env.tonemap_exposure, 1.0, "a little under 1, as the worlds")
	assert_not_null(r.get_node_or_null("Decor/Sky"), "a soft sky round every room, its own if it made none")


func _shown_meshes(n: Node) -> int:
	return n.find_children("*", "MeshInstance3D", true, false).filter(func(m: Node) -> bool:
		return (m as MeshInstance3D).is_visible_in_tree()).size()


func test_a_buddy_draws_in_few_meshes_and_still_moves() -> void:
	Profile.data.settings.reduce_motion = true
	var b := SuccessCast.person("tomas", Vector3.ZERO)
	add_child_autofree(b)
	var before := _shown_meshes(b)
	LifeRoomPeople.merge_person(b)
	assert_lte(_shown_meshes(b), 6, "a head, a body and four limbs (was %d boxes)" % before)
	assert_not_null(b.head.get_node_or_null(LifeRoomPeople.HEAD_LOOK), "the head in one mesh under the head: it nods")
	assert_not_null(b.arm_near.get_node_or_null(LifeRoomPeople.PART_LOOK), "an arm and its paw under the arm: it swings")
	b.pose("sit")
	assert_almost_eq(b.leg_near.rotation.x, -PI / 2, 0.01, "poses still move the parts")
	b.show_ouch("cut")
	assert_eq(b.ouch.size(), 1, "the soft ouch spot still shows")
	Profile.data.settings.reduce_motion = false


func test_a_buddy_who_keeps_still_is_two_meshes() -> void:
	var b := SuccessCast.person("omar", Vector3.ZERO)   # his wheelchair too
	add_child_autofree(b)
	LifeRoomPeople.merge_person(b, true)
	assert_eq(_shown_meshes(b), 2, "the head and the whole body")
	assert_not_null(b.get_node_or_null("Name"), "the name tag stays")


func test_a_merged_buddys_face_still_changes() -> void:
	var b := LifeBuddy.new()
	add_child_autofree(b)
	LifeRoomPeople.merge_person(b, true)
	var head := b.head.get_node(LifeRoomPeople.HEAD_LOOK) as MeshInstance3D
	var smile_verts: int = (head.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	LifeRoomPeople.feel(b, "happy")
	assert_eq(b.feeling, "happy")
	head = b.head.get_node(LifeRoomPeople.HEAD_LOOK) as MeshInstance3D
	assert_gt((head.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), smile_verts,
		"the feeling's mouth, its corners and the brows instead of the first smile")
	assert_eq(_shown_meshes(b.head), 1, "still one mesh for the head")
	LifeRoomPeople.feel(b, "cross")
	assert_eq(_shown_meshes(b.head), 1)


func test_a_dog_draws_in_few_meshes() -> void:
	var dog := LifeDog.new()
	add_child_autofree(dog)
	var before := _shown_meshes(dog)
	LifeRoomPeople.merge_dog(dog)
	assert_lte(_shown_meshes(dog), before - 2, "its head's skull, muzzle and nose in one (was %d)" % before)
	dog.set_mood("warning")
	assert_true(dog.lips.is_visible_in_tree(), "the warning signs stay the dog's own: the room shows them")
	dog.set_mood("sleep")
	var shut := 0
	for m: Node in dog.head.find_children("*", "MeshInstance3D", true, false):
		if (m as MeshInstance3D).is_visible_in_tree() and (m as Node3D).scale.y < 0.5:
			shut += 1
	assert_gt(shut, 0, "a sleeping dog's eyes still close")


func test_a_dog_whose_mood_never_changes_again_is_one_mesh() -> void:
	var dog := LifeDog.new()
	add_child_autofree(dog)
	dog.set_mood("warning")
	LifeRoomPeople.merge_dog(dog, true)
	assert_eq(_shown_meshes(dog), 1, "its body, head, ears, tail, legs, eyes and warning signs in one mesh")


func test_a_street_car_with_its_wheels_draws_as_one_mesh() -> void:
	var r := LifeRooms.make("street", "little", LifeExperience.vars("safe_streets", "little", 1, "ge")) as StreetRoom
	add_child_autofree(r)
	for i in 40:   # the traffic brings its cars along
		if not r.cars.is_empty():
			break
		r.traffic.step(0.5)
		r._sync_cars()
	assert_false(r.cars.is_empty(), "a car came")
	for id: int in r.cars:
		var car := r.cars[id].node as Node3D
		assert_eq(car.find_children("*", "MeshInstance3D", true, false).size(), 1, "%s: its body and wheels in one" % car.name)


func test_a_held_things_inner_parts_still_merge() -> void:
	var r := LifeRoomShelf.new("little")
	add_child_autofree(r)
	var sign := r.bottles.bleach.get_node("Sign") as Node3D
	LifeRoomPeople.merge_parts(r, sign)
	assert_not_null(sign.get_node_or_null(LifeRoomPeople.PART_LOOK),
		"the room holding the bottle (in a dictionary) never stops its sign's own boxes merging")


func test_a_thing_that_never_comes_apart_draws_as_one_mesh() -> void:
	var r := LifeRoomShelf.new("little")
	add_child_autofree(r)
	var bottle := r.bottles.bleach as Node3D
	LifeRoomPeople.merge_whole(bottle)
	assert_eq(_shown_meshes(bottle), 1, "the body, the cap and the sign's two boxes in one mesh")
	assert_true(r.target_node("sign").is_inside_tree(), "the sign (a target) keeps its place to be tapped")
	bottle.position.x = 1.0
	assert_almost_eq((bottle.get_node(LifeRoomPeople.PART_LOOK) as Node3D).global_position.x, 1.0, 0.001,
		"and moves with the bottle")


func test_the_phone_held_up_draws_only_near_it() -> void:
	var r := LifeRoomShelf.new("little")
	add_child_autofree(r)
	var parts := r.get_node("HeldPhone").find_children("*", "GeometryInstance3D", true, false)
	assert_gt(parts.size(), 10)
	for g: Node in parts:
		assert_between((g as GeometryInstance3D).visibility_range_end, 1.0, 5.0,
			"%s: a speck from the other places, not a draw" % g.name)


func test_a_rooms_words_draw_only_as_near_as_they_are_read() -> void:
	var r := LifeRoomShelf.new("little")
	add_child_autofree(r)
	var sign := r.get_node("ShelfSign") as Label3D
	assert_between(sign.visibility_range_end, 20.0, 30.0, "a place's words are never read from further (a speck, not a draw)")
	var key := r.get_node("HeldPhone").find_children("Label", "Label3D", true, false)[0] as Label3D
	assert_between(key.visibility_range_end, 1.0, 5.0, "the phone's keys keep their nearer reach")


## A room holding bottles with their signs in a dictionary, and a phone to hold up.
class LifeRoomShelf extends LifeRoom:
	var bottles := {}

	func build() -> void:
		var b := Node3D.new()
		b.name = "Bottle_bleach"
		add_child(b)
		LifeRoomKit.box(b, "Body", Vector3(0.1, 0.26, 0.08), Vector3(0, 0.13, 0), Color.WHITE)
		LifeRoomKit.box(b, "Cap", Vector3(0.05, 0.05, 0.05), Vector3(0, 0.28, 0), Color.BLUE)
		var sign := Node3D.new()
		sign.name = "Sign"
		sign.position = Vector3(0, 0.14, 0.05)
		b.add_child(sign)
		LifeRoomKit.box(sign, "Edge", Vector3(0.075, 0.075, 0.004), Vector3.ZERO, Color.RED).rotation.z = PI / 4
		LifeRoomKit.box(sign, "Inside", Vector3(0.058, 0.058, 0.004), Vector3(0, 0, 0.002), Color.WHITE).rotation.z = PI / 4
		add_target("sign", sign, 0.12)
		bottles.bleach = b
		make_held_phone(Transform3D(Basis(), Vector3(0, 1.2, -0.45)))
		LifeRoomKit.sign(self, "ShelfSign", "BE CAREFUL", Vector3(0, 1.6, -1.0), 0.003, Color.BLACK)


## A room with a bit of everything for the scenery's merge.
class LifeRoomProbe extends LifeRoom:
	const WOOD := Color("a8642a")
	var door: MeshInstance3D

	func build() -> void:
		var sc := scenery()
		for i in 20:
			var t := LifeRoomKit.box(sc, "Table%d" % i, Vector3(1.2, 1.5, 0.8), Vector3(i * 1.5, 0.75, -2), WOOD)
			LifeRoomKit.box(t, "TableLeg%d" % i, Vector3(0.1, 0.4, 0.1), Vector3(0, -0.9, 0), WOOD)
		door = LifeRoomKit.box(sc, "Door", Vector3(1, 2, 0.1), Vector3(0, 1, 3), Color.BROWN)
		var cup := LifeRoomKit.cylinder(sc, "Cup", 0.05, 0.1, Vector3(0, 1.55, -2), Color.WHITE)
		add_target("cup", cup, 0.1)
		var pole := LifeRoomKit.cylinder(sc, "LampPole", 0.03, 1.0, Vector3(3, 0.5, 0), Color.GRAY)
		add_target("lamp", LifeRoomKit.box(pole, "Shade", Vector3(0.3, 0.2, 0.3), Vector3(0, 0.6, 0), Color.YELLOW), 0.2)
		LifeRoomKit.box(sc, "Boxes", Vector3(0.5, 0.5, 0.5), Vector3(2, 0.25, 2), Color.TAN).visible = false
		sc.add_child(LifeBuddy.new())
		LifeRoomKit.box(sc, "Glass", Vector3(1, 1, 0.02), Vector3(0, 1, 4), Color(0.8, 0.9, 1.0, 0.3))
