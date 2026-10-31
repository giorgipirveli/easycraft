extends GutTest
## Owner #79, #86 (spec §25.3): the flight's looks. They never load a world's descriptor on the flight's first frame (the
## Moon's took 360 ms): the skies over worlds with air and Mercury's big Sun are copied into FlightLooks, and must stay
## equal to the worlds' own; the Star Map's colours come from its tables. Every world has a sphere; the big maps come
## from a worker thread and are there when a sphere shows. Every mesh the flight makes faces outward (Godot draws
## clockwise triangles as front faces).


func test_the_copied_skies_and_suns_are_the_worlds_own() -> void:
	for u: int in FlightLooks.SKY:
		if not UniverseRegistry.exists(u):
			continue
		var sky := UniverseRegistry.sky(u)
		assert_eq(FlightLooks.SKY[u][0], sky.get("sky_top"), "world %d's sky" % u)
		assert_eq(FlightLooks.SKY[u][1], sky.get("sky_horizon"), "world %d's horizon" % u)
	for u: int in SpaceRules.WORLDS:
		assert_eq(float(FlightLooks.look(u).sun_size), UniverseRegistry.sun_size(u), "world %d's Sun" % u)
	for u: int in SpaceRules.WORLDS:
		if FlightPlan.has_air(u):
			assert_true(FlightLooks.SKY.has(u), "world %d has air: its sky is copied" % u)


func test_the_star_map_s_bodies_without_a_descriptor() -> void:
	for u: int in SpaceRules.WORLDS:
		assert_eq(FlightLooks.star_body(u), StarMap.body(StarMap.body_for_world(u)), "world %d" % u)
	assert_eq(FlightLooks.star_body(1), {}, "a universe is no Star Map body to land on")


func test_every_world_has_a_sphere_whose_map_arrives() -> void:
	for u: int in SpaceRules.WORLDS + [99]:
		var m := FlightLooks.planet_material(u)
		FlightLooks.need(m)
		assert_not_null(m.get_shader_parameter(&"surface"), "world %d's map" % u)
	var earth := FlightLooks.earth_material()
	FlightLooks.need(earth)
	assert_not_null(earth.get_shader_parameter(&"surface"))
	assert_true(FlightLooks.poll(), "nothing left loading")


func _inside_out(mesh: Mesh) -> int:
	var wrong := 0
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var idx: Variant = arrays[Mesh.ARRAY_INDEX]
		var order: Array = Array(idx as PackedInt32Array) if idx != null and (idx as PackedInt32Array).size() > 0 \
			else range(v.size())
		for i in range(0, order.size(), 3):
			var a := v[order[i]]
			var face := (v[order[i + 1]] - a).cross(v[order[i + 2]] - a)
			if face.length() > 0.000001 and face.dot(n[order[i]]) > 0.0:
				wrong += 1
	return wrong


func test_every_mesh_the_flight_makes_faces_outward() -> void:
	var body := RocketBody.new()
	add_child_autofree(body)
	body.setup(RocketStages.test_rocket(SpaceRules.MARS, 2), 1)
	body.finish_setup()
	var set := FlightSet.new()
	add_child_autofree(set)
	set.setup(SpaceRules.MOON, 1)
	var moments := FlightMoments.new()
	add_child_autofree(moments)
	moments.setup(1)
	var checked := 0
	for root: Node in [body, set, moments]:
		for m: Node in root.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			if mi.mesh is ArrayMesh and mi.name not in ["Stars", "Streaks"]:   # both sides drawn (the night sky's)
				assert_eq(_inside_out(mi.mesh), 0, "%s faces outward" % root.get_path_to(mi))
				checked += 1
	assert_eq(_inside_out(moments.rocks.multimesh.mesh), 0, "the asteroids face outward")
	assert_gt(checked, 5)
