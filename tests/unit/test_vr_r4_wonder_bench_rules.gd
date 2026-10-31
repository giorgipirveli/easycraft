extends GutTest
## Owner #110, VR round 4 (VR-WONDER, idea 4; docs/devlog/parts/vr-r4-wonder.md): LabBenchRules, the Lab bench by hand.
## The bench at hand height (a handle lifts or lowers it), the shelf, the two baskets (the prediction's sort), the tank
## (a cube let go over it is dropped in), where a cube floats or rests, and the magnet's pull (magnetic things are
## caught from further away; the rest only when touched).


func test_the_bench_starts_at_hand_height_in_front_and_the_handle_keeps_it_within_reach() -> void:
	var head := Transform3D(Basis(), Vector3(0.0, 1.5, 0.0))
	var t := LabBenchRules.place_before(head)
	assert_almost_eq(t.origin.y, 1.5 - LabBenchRules.START_DROP, 0.001, "the eyes minus 0.45 m")
	assert_almost_eq(-t.origin.z, LabBenchRules.START_AHEAD, 0.001, "ahead of the child")
	assert_almost_eq(t.basis.z.dot(Vector3.BACK), 1.0, 0.001, "its +z towards the child")
	var turned := Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.0, 1.2, 0.0))
	var t2 := LabBenchRules.place_before(turned.looking_at(Vector3(-5, 1.2, 0)))
	assert_almost_eq(t2.origin.x, -LabBenchRules.START_AHEAD, 0.001, "in front wherever the child looks")
	assert_almost_eq(t2.basis.y.dot(Vector3.UP), 1.0, 0.001, "always level")
	assert_almost_eq(LabBenchRules.lifted(1.5, 1.4), 1.5 - LabBenchRules.LIFT.x, 0.001, "never above the chest")
	assert_almost_eq(LabBenchRules.lifted(1.5, 0.2), 1.5 - LabBenchRules.LIFT.y, 0.001, "never down at the floor")
	assert_almost_eq(LabBenchRules.lifted(1.5, 0.95), 0.95, 0.001)


func test_the_shelf_holds_every_thing_in_a_row_on_the_bench() -> void:
	var spots: Array[Vector3] = []
	for i in 8:
		spots.append(LabBenchRules.shelf_spot(i, 8))
	for i in 8:
		assert_almost_eq(spots[i].y, LabBenchRules.CUBE * 0.5, 0.001, "on the top")
		assert_lte(absf(spots[i].x), LabBenchRules.TOP.x * 0.5, "on the bench")
		if i > 0:
			assert_gt(spots[i].x - spots[i - 1].x, LabBenchRules.CUBE, "apart, left to right")
	assert_eq(LabBenchRules.basket_at(spots[0]), -1, "the shelf is no basket")
	assert_false(LabBenchRules.in_tank(spots[7]), "nor the tank")


func test_a_cube_let_go_over_a_basket_is_sorted_into_it() -> void:
	for g in 2:
		var c: Vector3 = LabBenchRules.BASKETS[g]
		assert_eq(LabBenchRules.basket_at(c + Vector3(0.0, 0.05, 0.0)), g, "in basket %d" % g)
		assert_eq(LabBenchRules.basket_at(c + Vector3(0.0, 0.18, 0.0)), g, "dropped from a little above")
		assert_eq(LabBenchRules.basket_at(c + Vector3(0.0, 0.5, 0.0)), -1, "too high above it")
	assert_eq(LabBenchRules.basket_at(Vector3(0.0, 0.05, -0.3)), -1)
	var a: Vector3 = LabBenchRules.BASKETS[0]
	var b: Vector3 = LabBenchRules.BASKETS[1]
	assert_gt(b.x - a.x, LabBenchRules.BASKET_SIZE.x, "the two baskets do not overlap")


func test_eight_cubes_fit_in_one_basket() -> void:
	for g in 2:
		var seen: Array[Vector3] = []
		for k in 8:
			var s := LabBenchRules.basket_slot(g, k)
			assert_eq(LabBenchRules.basket_at(s), g, "slot %d inside its basket" % k)
			for o: Vector3 in seen:
				assert_gt(o.distance_to(s), LabBenchRules.CUBE * 0.95, "slots never overlap")
			seen.append(s)


func test_a_cube_let_go_over_the_tank_goes_in() -> void:
	var t := LabBenchRules.TANK_AT
	assert_true(LabBenchRules.in_tank(t + Vector3(0.0, LabBenchRules.TANK_SIZE.y + 0.05, 0.0)), "from above the rim")
	assert_true(LabBenchRules.in_tank(t + Vector3(0.05, 0.1, 0.02)), "in the water")
	assert_false(LabBenchRules.in_tank(t + Vector3(0.0, 0.6, 0.0)), "far above")
	assert_false(LabBenchRules.in_tank(t + Vector3(0.4, 0.1, 0.0)), "beside it")
	for g in 2:
		assert_false(LabBenchRules.in_tank(LabBenchRules.BASKETS[g]), "no basket is in the tank")


func test_a_floater_rests_at_the_surface_and_a_sinker_on_the_bottom() -> void:
	var surface := LabBenchRules.TANK_SIZE.y * LabBenchRules.WATER
	for k in 4:
		var f := LabBenchRules.tank_spot(true, k, 4)
		var s := LabBenchRules.tank_spot(false, k, 4)
		assert_almost_eq(f.y, surface - LabBenchRules.CUBE * LabBenchRules.FLOAT_DEPTH, 0.001, "bobbing at the top")
		assert_almost_eq(s.y, LabBenchRules.CUBE * 0.5 + LabBenchRules.GLASS, 0.001, "on the bottom")
		assert_true(LabBenchRules.in_tank(f) and LabBenchRules.in_tank(s), "inside the tank")
	assert_gt(LabBenchRules.tank_spot(true, 1, 4).x - LabBenchRules.tank_spot(true, 0, 4).x, LabBenchRules.CUBE,
		"side by side")


func test_the_magnet_pulls_a_magnetic_thing_from_further_away() -> void:
	assert_true(LabBenchRules.magnet_catches(0.08, true), "iron jumps across 8 cm")
	assert_false(LabBenchRules.magnet_catches(0.08, false), "wood does not")
	assert_true(LabBenchRules.magnet_catches(0.02, false), "touching it: tried, and it does not stick")
	assert_false(LabBenchRules.magnet_catches(LabBenchRules.PULL_REACH + 0.01, true), "too far for any pull")


func test_the_baskets_words_come_from_the_experiments_groups() -> void:
	assert_eq(LabBenchRules.basket_words(["Floats", "Sinks"]), ["FLOATS", "SINKS"])
	assert_eq(LabBenchRules.basket_words(["Sticks", "Does not stick"]), ["STICKS", "DOES NOT STICK"])
	assert_true(LabBenchRules.by_hand({"kind": "tank"}))
	assert_true(LabBenchRules.by_hand({"kind": "magnet"}))
	assert_false(LabBenchRules.by_hand({"kind": "heat"}), "the other experiments stay on the panel for now")


## Every wonder teaches: the bench's units (its experiments' own, and working like a scientist) are real, written units.
func test_the_bench_links_to_written_school_units() -> void:
	Curriculum.clear_cache()
	LabExperiments.clear_cache()
	var ids: Array[String] = LabBenchRules.units_of(LabExperiments.experiment("float_sink"))
	assert_has(ids, "g3.science.materials", "the experiment's own units")
	assert_has(ids, "g3.science.fair_tests", "predict, try, why: working like a scientist")
	assert_has(LabBenchRules.units_of(LabExperiments.experiment("magnets")), "g3.science.magnets")
	for e: String in ["float_sink", "magnets"]:
		for id: String in LabBenchRules.units_of(LabExperiments.experiment(e)):
			assert_false(Curriculum.unit(id).is_empty(), "%s is a School unit" % id)
			assert_true(Curriculum.has_content(id), "%s has its lessons written" % id)
