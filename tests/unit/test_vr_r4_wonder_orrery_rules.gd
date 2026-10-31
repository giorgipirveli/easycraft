extends GutTest
## Owner #110, VR round 4 (VR-WONDER, idea 1; docs/devlog/parts/vr-r4-wonder.md): OrreryRules, the Star Map as a moving
## orrery within reach. The real sizes (and that the Star Map's own facts agree with them), where each body is on the
## orrery today, its size there, in the hand and in TRUE SIZE, the TRUE SIZE row, the landing ring and the comparison words.


func test_the_real_sizes_give_eleven_earths_for_jupiter_and_109_for_the_sun() -> void:
	assert_eq(roundi(OrreryRules.ratio(&"jupiter", &"earth")), 11, "Jupiter is eleven Earths across")
	assert_eq(roundi(OrreryRules.ratio(&"sun", &"earth")), 109, "the Sun is 109 Earths across")
	assert_almost_eq(OrreryRules.ratio(&"earth", &"earth"), 1.0, 0.0001)
	assert_lt(OrreryRules.ratio(&"moon", &"earth"), 0.3, "the Moon is about a quarter of Earth")


func test_every_body_of_the_star_maps_solar_system_has_a_real_size() -> void:
	for b: Dictionary in StarMap.SOLAR:
		assert_true(OrreryRules.DIAMETER_KM.has(b.id), "%s has its diameter" % b.id)
		assert_gt(float(OrreryRules.DIAMETER_KM.get(b.id, 0.0)), 1000.0)


## The cards' facts and the sizes must tell the same story (a child compares them in the hands).
func test_the_star_maps_facts_agree_with_the_sizes() -> void:
	var sun := OrreryRules.ratio(&"sun", &"earth")
	assert_almost_eq(pow(sun, 3.0) / 1.0e6, 1.3, 0.05, "about 1.3 million Earths fit inside the Sun")
	assert_gt(pow(OrreryRules.ratio(&"jupiter", &"earth"), 3.0), 1300.0, "over 1,300 Earths fit inside Jupiter")
	assert_gt(OrreryRules.ratio(&"ganymede", &"mercury"), 1.0, "Ganymede is bigger than Mercury")
	assert_lt(OrreryRules.ratio(&"pluto", &"moon"), 1.0, "Pluto is smaller than our Moon")
	for id: StringName in OrreryRules.DIAMETER_KM:
		if id != &"jupiter" and id != &"sun":
			assert_lt(OrreryRules.ratio(id, &"jupiter"), 1.0, "Jupiter is the biggest planet: %s" % id)
	assert_lt(OrreryRules.ratio(&"mercury", &"mars"), 1.0, "Mercury is the smallest planet")


func test_a_planet_sits_on_its_orbit_where_the_star_map_puts_it_today() -> void:
	var days := 9500.0
	for id: StringName in [&"mercury", &"earth", &"jupiter", &"pluto"]:
		var p := OrreryRules.place(id, days, 0.0, false)
		assert_almost_eq(Vector2(p.x, p.z).length(), float(OrreryRules.ORBIT[id]), 0.0001, "%s on its orbit" % id)
		assert_almost_eq(p.y, 0.0, 0.0001, "the orbits lie flat")
		var a := StarMap.longitude(id, days)
		assert_almost_eq(p.x, cos(a) * float(OrreryRules.ORBIT[id]), 0.0001)
		assert_almost_eq(p.z, -sin(a) * float(OrreryRules.ORBIT[id]), 0.0001, "counter-clockwise seen from above")
	assert_eq(OrreryRules.place(&"sun", days, 0.0, false), Vector3.ZERO, "the Sun in the middle")


func test_the_orbits_go_out_in_order_and_stay_within_reach() -> void:
	var last := OrreryRules.SUN_RADIUS
	for id: StringName in [&"mercury", &"venus", &"earth", &"mars", &"jupiter", &"saturn", &"uranus", &"neptune", &"pluto"]:
		assert_gt(float(OrreryRules.ORBIT[id]), last, "%s further out" % id)
		last = float(OrreryRules.ORBIT[id])
	assert_lte(last, OrreryRules.REACH, "the outermost orbit is within the orrery's reach")


func test_a_moon_goes_round_its_planet_clear_of_it() -> void:
	var earth := OrreryRules.place(&"earth", 100.0, 3.0, false)
	var moon := OrreryRules.place(&"moon", 100.0, 3.0, false)
	var gap := earth.distance_to(moon)
	assert_almost_eq(gap, OrreryRules.radius(&"earth", false) + OrreryRules.MOON_GAP, 0.0001, "the Moon's ring")
	var later := OrreryRules.place(&"moon", 100.0, 10.0, false)
	assert_ne(moon, later, "it goes round")
	var j := OrreryRules.place(&"jupiter", 100.0, 3.0, false)
	var io := OrreryRules.place(&"io", 100.0, 3.0, false)
	var europa := OrreryRules.place(&"europa", 100.0, 3.0, false)
	assert_gt(io.distance_to(europa), 0.01, "a planet's moons are spread round it")
	assert_almost_eq(io.distance_to(j), europa.distance_to(j), 0.0001)


func test_sizes_on_the_orrery_follow_the_star_map_bigger_means_bigger() -> void:
	assert_eq(OrreryRules.radius(&"sun", false), OrreryRules.SUN_RADIUS)
	assert_gt(OrreryRules.radius(&"jupiter", false), OrreryRules.radius(&"earth", false))
	assert_gt(OrreryRules.radius(&"earth", false), OrreryRules.radius(&"mars", false))
	assert_almost_eq(OrreryRules.radius(&"earth", false), 16.0 * OrreryRules.MAP_SIZE, 0.0001, "the map's size")
	assert_lt(OrreryRules.radius(&"mercury", false) + OrreryRules.SUN_RADIUS, float(OrreryRules.ORBIT[&"mercury"]),
		"Mercury clears the Sun")


func test_in_the_hand_and_in_true_size_every_body_is_its_real_size_against_earth() -> void:
	for id: StringName in [&"jupiter", &"moon", &"pluto", &"saturn"]:
		assert_almost_eq(OrreryRules.hand_radius(id) / OrreryRules.hand_radius(&"earth"), OrreryRules.ratio(id, &"earth"),
			0.0001, "%s in the hand" % id)
		assert_almost_eq(OrreryRules.radius(id, true) / OrreryRules.radius(&"earth", true), OrreryRules.ratio(id, &"earth"),
			0.0001, "%s in TRUE SIZE" % id)
	assert_almost_eq(OrreryRules.hand_radius(&"earth"), OrreryRules.HAND_EARTH_RADIUS, 0.0001)
	assert_almost_eq(OrreryRules.radius(&"sun", true) / OrreryRules.radius(&"earth", true), OrreryRules.ratio(&"sun", &"earth"),
		0.0001, "the Sun too, 109 Earths across")


func test_true_size_puts_the_planets_in_a_row_in_order_before_the_sun() -> void:
	var xs: Array[float] = []
	for id: StringName in OrreryRules.ROW:
		var p := OrreryRules.place(id, 0.0, 0.0, true)
		assert_almost_eq(p.z, OrreryRules.ROW_Z, 0.0001, "%s in the row" % id)
		xs.append(p.x)
	for i in range(1, xs.size()):
		var a: StringName = OrreryRules.ROW[i - 1]
		var b: StringName = OrreryRules.ROW[i]
		assert_gt(xs[i] - xs[i - 1], OrreryRules.half_width(a, true) + OrreryRules.half_width(b, true), "%s and %s apart" % [a, b])
	assert_almost_eq(xs[0] + xs[-1], 0.0, 0.01, "the row is centred")
	assert_lte(absf(xs[-1]) + OrreryRules.half_width(OrreryRules.ROW[-1], true), OrreryRules.REACH + 0.05, "within reach")
	var sun := OrreryRules.place(&"sun", 0.0, 0.0, true)
	assert_lt(sun.z + OrreryRules.radius(&"sun", true), OrreryRules.ROW_Z, "the Sun stands behind the row")


func test_saturns_ring_is_counted_in_its_width() -> void:
	assert_almost_eq(OrreryRules.half_width(&"saturn", true), OrreryRules.radius(&"saturn", true) * OrreryRules.RING_OUTER,
		0.0001)
	assert_almost_eq(OrreryRules.half_width(&"earth", true), OrreryRules.radius(&"earth", true), 0.0001)


func test_a_planet_let_go_in_the_landing_ring_lands() -> void:
	var ring := OrreryRules.ring_at(VrRules.RIGHT)
	assert_gt(ring.x, OrreryRules.REACH, "beside the orrery, on the pointing hand's side")
	assert_lt(OrreryRules.ring_at(VrRules.LEFT).x, -OrreryRules.REACH, "a left-handed child's ring is on the left")
	assert_true(OrreryRules.in_ring(ring, ring))
	assert_true(OrreryRules.in_ring(ring + Vector3(0.0, 0.05, 0.08), ring), "near the middle")
	assert_false(OrreryRules.in_ring(ring + Vector3(0.0, 0.0, 0.3), ring), "30 cm off: not in it")


func test_the_comparison_words_say_how_many_times_as_wide() -> void:
	assert_eq(OrreryRules.compare_words(&"jupiter", &"earth"), "Jupiter is 11 times as wide as Earth!")
	assert_eq(OrreryRules.compare_words(&"earth", &"jupiter"), "Jupiter is 11 times as wide as Earth!", "the bigger first")
	assert_eq(OrreryRules.compare_words(&"earth", &"mars"), "Earth is 1.9 times as wide as Mars!")
	assert_eq(OrreryRules.compare_words(&"earth", &"venus"), "Earth and Venus are about the same size!")
	assert_eq(OrreryRules.compare_words(&"moon", &"earth"), "Earth is 3.7 times as wide as the Moon!")
	assert_eq(OrreryRules.compare_words(&"earth", &"earth"), "")
	assert_lte(OrreryRules.compare_words(&"ganymede", &"pluto").length(), OrreryRules.MAX_WORDS)


func test_the_orrery_year_matches_the_flat_map() -> void:
	assert_eq(OrreryRules.EARTH_YEAR_SECONDS, SpacePanel.EARTH_YEAR_SECONDS, "the same speed as the 2D Star Map")
	assert_almost_eq(OrreryRules.days_per_second(), StarMap.year_days(&"earth") / SpacePanel.EARTH_YEAR_SECONDS, 0.0001)


func test_the_sun_is_never_taken() -> void:
	assert_false(OrreryRules.takeable(&"sun"), "109 Earths across: it stays in the middle")
	assert_true(OrreryRules.takeable(&"jupiter"))
	assert_true(OrreryRules.takeable(&"moon"))


## Every wonder teaches: the School's units the orrery links to are real, written units.
func test_the_orrery_links_to_written_school_units() -> void:
	Curriculum.clear_cache()
	assert_gt(OrreryRules.UNITS.size(), 3)
	for id: String in OrreryRules.UNITS:
		assert_false(Curriculum.unit(id).is_empty(), "%s is a School unit" % id)
		assert_true(Curriculum.has_content(id), "%s has its lessons written" % id)
