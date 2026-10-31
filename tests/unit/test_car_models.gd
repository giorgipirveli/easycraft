extends GutTest
## Owner #109: every car is drawn from boxes in the game's blocky style (our own models): ONE merged, vertex-coloured
## mesh per kind and colour with WeaponModels' one shared material, built once and cached (no mesh or material is ever
## made per car), its wheels one mesh per kind (spun by their nodes), the sky taxi's rotor one mesh. Each look fits its
## kind's size, stands on its feet (nothing under the ground) and faces -Z.


func test_each_kind_and_colour_has_one_cached_mesh_with_the_shared_material() -> void:
	for kind in CarKinds.ORDER:
		for c in CarKinds.COLOURS:
			var m := CarModels.body(kind, c)
			assert_not_null(m, "%s %d" % [kind, c])
			assert_gt(m.get_surface_count(), 0)
			assert_eq(m.surface_get_material(0), WeaponModels.material(), "%s: the one shared material" % kind)
			assert_same(CarModels.body(kind, c), m, "%s: built once" % kind)
		assert_ne(CarModels.body(kind, 0), CarModels.body(kind, 1), "%s: each colour its own mesh" % kind)
	assert_same(CarModels.body(CarKinds.BUS, 42), CarModels.body(CarKinds.BUS, 0), "an unknown colour is the first")


func test_each_look_fits_its_size_stands_on_its_feet_and_faces_forward() -> void:
	for kind in CarKinds.ORDER:
		var box := CarModels.body(kind, 0).get_aabb()
		var s := CarKinds.size(kind)
		assert_gte(box.position.y, -0.01, "%s: nothing under the ground" % kind)
		assert_lte(box.end.y, s.y + 0.15, "%s: as high as its size" % kind)
		assert_lte(box.size.x, s.x + 0.15, "%s: as wide" % kind)
		assert_lte(box.size.z, s.z + 0.15, "%s: as long" % kind)
		assert_gt(box.size.z, s.z * 0.8, "%s: about its length" % kind)
		assert_almost_eq(box.get_center().x, 0.0, 0.05, "%s: centred" % kind)
		var lights := CarModels.headlights(kind)
		assert_gt(lights.size(), 0, "%s has headlights" % kind)
		for p: Vector3 in lights:
			assert_lt(p.z, 0.0, "%s: its lights at the front (-Z)" % kind)


func test_wheels_rotors_and_the_cache_never_grows_per_car() -> void:
	for kind in CarKinds.ORDER:
		if CarKinds.hovers(kind):
			assert_null(CarModels.wheel(kind), "a hover car has no wheels")
			continue
		var w := CarModels.wheel(kind)
		assert_not_null(w, kind)
		assert_same(CarModels.wheel(kind), w)
		var r := w.get_aabb().size
		assert_almost_eq(maxf(r.x, r.y), CarKinds.wheel_radius(kind) * 2.0, 0.05, "%s: its wheel's size" % kind)
	assert_not_null(CarModels.rotor())
	assert_same(CarModels.rotor(), CarModels.rotor())
	var before := CarModels.cached_count()
	for i in 20:
		for kind in CarKinds.ORDER:
			CarModels.body(kind, i % CarKinds.COLOURS)
			CarModels.wheel(kind)
	assert_eq(CarModels.cached_count(), before, "nothing new is made for more cars")
	assert_lte(before, CarKinds.ORDER.size() * (CarKinds.COLOURS + 1) + 1)


func test_the_garage_s_picture_comes_from_the_same_parts() -> void:
	for kind in CarKinds.ORDER:
		var parts := CarModels.parts(kind, 2)
		assert_gt(parts.size(), 4, "%s is built from boxes" % kind)
		var has_colour := false
		for p: Variant in parts:
			has_colour = has_colour or (p is Array and p[2] == CarKinds.colour_of(kind, 2))
		assert_true(has_colour, "%s wears its colour" % kind)
