extends GutTest
## Owner #70, #73 and #111, grade 7 maths, science and English (research §6.7): the School draws their pictures from data
## (SchoolPictureG7Core, inside SchoolPicture): a factor tree, two numbers' primes in a Venn diagram, a distance-time
## graph, the speed triangle, the kinds of chart, an axis with odd steps, a picture made bigger both ways, the periodic
## table (elements 1-20, or all 18 groups), the pH scale with universal indicator's colours, the apparatus that separates
## mixtures, a chromatogram, light reflected, refracted and split by a prism, what colour a thing looks in coloured light,
## the carbon cycle, a hundred squares of air, a passage with phrases marked, a Venn diagram, and the three points of
## view. Every sample draws at the School's picture sizes; broken data is a problem the content test finds; the rules the
## pictures draw by (primes, HCF and LCM, a leg's speed, the triangle's formulas, bars on odd axes, how much bigger a
## picture looks, the periodic table's places and kinds, pH, Rf, Snell's law, the colour seen, the carbon cycle's
## processes) are checked here with this file's own facts, and every label pin's part is on its picture.

const SAMPLES: Array[Dictionary] = [
	{"kind": "factor_tree", "n": 60},
	{"kind": "factor_tree", "n": 60, "powers": true},
	{"kind": "factor_tree", "n": 84, "hide": 2},
	{"kind": "factor_tree", "n": 200, "powers": true},
	{"kind": "factor_tree", "n": 96, "hide": 5, "powers": true},
	{"kind": "factor_tree", "n": 6},
	{"kind": "prime_venn", "a": 60, "b": 84},
	{"kind": "prime_venn", "a": 60, "b": 84, "show": "both"},
	{"kind": "prime_venn", "a": 12, "b": 18, "show": "hcf", "hide": true},
	{"kind": "prime_venn", "a": 7, "b": 9, "show": "both", "names": ["buses", "trams"]},
	{"kind": "prime_venn", "a": 64, "b": 96, "show": "lcm"},
	{"kind": "distance_time", "points": [[0, 0], [30, 6], [45, 6], [60, 12]], "t_to": 60, "t_step": 10, "d_to": 12,
		"d_step": 2, "legs": true, "mark": 0},
	{"kind": "distance_time", "points": [[0, 0], [1, 60], [2, 60], [3, 0]], "t_to": 3, "t_step": 1, "d_to": 60,
		"d_step": 20, "t_unit": "h", "title": "A day out and back"},
	{"kind": "distance_time", "points": [[0, 0], [10, 50], [20, 150], [40, 200]], "t_to": 40, "t_step": 5, "d_to": 200,
		"d_step": 50, "t_unit": "s", "d_unit": "m", "legs": true},
	{"kind": "speed_triangle"},
	{"kind": "speed_triangle", "cover": "time", "formula": true},
	{"kind": "speed_triangle", "cover": "distance"},
	{"kind": "chart_kinds", "show": ["bar", "line", "pie", "scatter"]},
	{"kind": "chart_kinds", "show": ["pictogram", "pie"], "mark": "pie"},
	{"kind": "chart_kinds", "show": ["line"], "names": false},
	{"kind": "odd_scale", "values": [["Jan", 10], ["Feb", 30], ["Mar", 90]], "ticks": [0, 10, 20, 50, 100],
		"title": "Visitors (thousands)"},
	{"kind": "odd_scale", "values": [["A", 5], ["B", 40]], "ticks": [0, 5, 10, 20, 40], "fair": true},
	{"kind": "big_icons", "what": "bag", "scale": 2, "labels": ["2020: 10", "2025: 20"]},
	{"kind": "big_icons", "what": "coin", "scale": 3},
	{"kind": "big_icons", "what": "box", "scale": 2, "solid": true, "labels": ["small", "big"]},
	{"kind": "big_icons", "what": "tree", "scale": 1.5},
	{"kind": "big_icons", "what": "house", "scale": 2.5},
	{"kind": "periodic_grid", "view": "first20", "groups": true, "periods": true},
	{"kind": "periodic_grid", "view": "first20", "shade": true, "mark": ["Na", "Cl"], "groups": true},
	{"kind": "periodic_grid", "view": "first20", "hide": "O", "col": 8},
	{"kind": "periodic_grid", "view": "full", "shade": true},
	{"kind": "periodic_grid", "view": "full", "groups": true, "periods": true, "mark": ["Fe", "Au"], "row": 4},
	{"kind": "periodic_grid", "view": "full", "labels": true},
	{"kind": "periodic_grid", "view": "first20", "labels": true, "numbers": false},
	{"kind": "ph_scale"},
	{"kind": "ph_scale", "marks": [[2, "lemon juice"], [7, "pure water"], [10, "soap"], [13, "oven cleaner"]],
		"bands": true},
	{"kind": "ph_scale", "marks": [[1, "stomach acid"], [3, "vinegar"], [6.5, "milk"], [8, "baking soda"], [12, "bleach"],
		[14, "drain cleaner"]], "hide": 2, "litmus": true},
	{"kind": "ph_scale", "colours": false, "bands": true},
	{"kind": "separation", "method": "filter", "labels": true},
	{"kind": "separation", "method": "evaporate", "labels": true, "mark": "water vapour"},
	{"kind": "separation", "method": "distil", "labels": true, "hide": "condenser"},
	{"kind": "separation", "method": "chromatography", "labels": true},
	{"kind": "separation", "method": "sieve"},
	{"kind": "separation", "method": "magnet", "labels": true},
	{"kind": "separation", "method": "distil"},
	{"kind": "chromatogram", "samples": [["black", [[0.2, "yellow"], [0.5, "red"], [0.8, "blue"]]], ["red", [[0.5, "red"]]],
		["blue", [[0.8, "blue"]]], ["yellow", [[0.3, "yellow"]]]], "names": true},
	{"kind": "chromatogram", "samples": [["A", [0.35]], ["B", [0.35, 0.7]], ["mix", [0.15, 0.35, 0.6, 0.9]]], "mark": 2},
	{"kind": "chromatogram", "samples": [["ink", []]]},
	{"kind": "light_rays", "view": "specular", "labels": true},
	{"kind": "light_rays", "view": "diffuse", "labels": true},
	{"kind": "light_rays", "view": "refraction", "labels": true},
	{"kind": "light_rays", "view": "refraction", "into": "water", "angle": 60, "labels": true},
	{"kind": "light_rays", "view": "leaving", "angle": 30, "labels": true},
	{"kind": "light_rays", "view": "block", "labels": true},
	{"kind": "light_rays", "view": "along_normal", "labels": true},
	{"kind": "light_rays", "view": "prism", "labels": true},
	{"kind": "light_rays", "view": "prism", "mark": "spectrum"},
	{"kind": "seen_colour", "light": "white", "object": "red", "thing": "apple"},
	{"kind": "seen_colour", "light": "green", "object": "red", "thing": "flower", "hide": true},
	{"kind": "seen_colour", "light": "white", "object": "blue", "filter": "red", "thing": "book"},
	{"kind": "seen_colour", "light": "red", "object": "yellow", "thing": "shirt"},
	{"kind": "seen_colour", "light": "white", "object": "white", "thing": "leaf"},
	{"kind": "seen_colour", "light": "blue", "object": "black"},
	{"kind": "carbon_cycle"},
	{"kind": "carbon_cycle", "mark": "photosynthesis"},
	{"kind": "carbon_cycle", "hide": "combustion"},
	{"kind": "carbon_cycle", "labels": false, "processes": false},
	{"kind": "carbon_cycle", "hide": "fossil fuels", "mark": "decay"},
	{"kind": "air_mix"},
	{"kind": "air_mix", "hide": 1, "mark": 0},
	{"kind": "air_mix", "gases": [["nitrogen", 78], ["oxygen", 16], ["carbon dioxide", 4], ["argon and others", 2]]},
	{"kind": "marked_text", "lines": ["Mira gripped the rope with both hands.", "The bridge swayed over the gorge.",
		"She took one step, then another."], "marks": [[0, "gripped the rope"], [2, "took one step"]],
		"tags": ["evidence 1", "evidence 2"], "title": "Claim: Mira is brave"},
	{"kind": "marked_text", "lines": ["The crust crackled.", "Warm bread filled the kitchen with its smell."],
		"marks": [[0, "crackled"], [1, "smell"]]},
	{"kind": "marked_text", "lines": ["One line only."]},
	{"kind": "venn", "left_name": "frogs", "right_name": "toads", "left": ["smooth, moist skin", "long legs: hop"],
		"right": ["dry, bumpy skin", "short legs: walk"], "both": ["amphibians", "eggs in water"]},
	{"kind": "venn", "left_name": "the story", "right_name": "the history", "left": ["invented Ned", "his feelings"],
		"right": ["dates", "sources"], "both": ["1476", "Caxton's press"], "hide": "both", "title": "Compare them"},
	{"kind": "venn", "left_name": "book", "right_name": "film", "both": ["the same plot"]},
	{"kind": "pov_view", "mode": "first"},
	{"kind": "pov_view", "mode": "third_limited", "names": ["Zara", "Bram", "Tilly"]},
	{"kind": "pov_view", "mode": "omniscient", "hide": true},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(480, 280), Vector2(248, 126)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_kind_view_and_method_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureG7Core.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)
	for v: String in SchoolPictureG7Core.LIGHT_VIEWS:
		assert_true(SAMPLES.any(func(d: Dictionary) -> bool: return d.kind == "light_rays" and str(d.get("view")) == v),
			"a %s light picture" % v)
	for m: String in SchoolPictureG7Core.METHODS:
		assert_true(SAMPLES.any(func(d: Dictionary) -> bool: return d.kind == "separation" and str(d.get("method")) == m),
			"a %s picture" % m)
	for m: String in SchoolPictureG7Core.POV_MODES:
		assert_true(SAMPLES.any(func(d: Dictionary) -> bool: return d.kind == "pov_view" and str(d.get("mode")) == m),
			"a %s point of view" % m)


func test_every_sample_draws_at_every_size() -> void:
	for px in SIZES:
		for d in SAMPLES:
			var p := SchoolPicture.new(d, px)
			p.size = px
			add_child_autofree(p)
	await wait_process_frames(2)
	assert_true(true, "drawn without script errors")


func test_broken_pictures_are_problems() -> void:
	for d: Dictionary in [
			{"kind": "factor_tree", "n": 13}, {"kind": "factor_tree", "n": 1024}, {"kind": "factor_tree", "n": 2},
			{"kind": "factor_tree", "n": 60, "hide": 4}, {"kind": "factor_tree", "n": 60, "powers": "yes"},
			{"kind": "prime_venn", "a": 1, "b": 6}, {"kind": "prime_venn", "a": 6, "b": 1000},
			{"kind": "prime_venn", "a": 6, "b": 8, "show": "sum"}, {"kind": "prime_venn", "a": 6, "b": 8, "names": ["one"]},
			{"kind": "distance_time", "points": [[0, 0]], "t_to": 10, "t_step": 5, "d_to": 10, "d_step": 5},
			{"kind": "distance_time", "points": [[5, 0], [10, 5]], "t_to": 10, "t_step": 5, "d_to": 10, "d_step": 5},
			{"kind": "distance_time", "points": [[0, 0], [10, 5], [10, 6]], "t_to": 10, "t_step": 5, "d_to": 10,
				"d_step": 5},
			{"kind": "distance_time", "points": [[0, 0], [10, 15]], "t_to": 10, "t_step": 5, "d_to": 10, "d_step": 5},
			{"kind": "distance_time", "points": [[0, 0], [10, 5]], "t_to": 10, "t_step": 3, "d_to": 10, "d_step": 5},
			{"kind": "distance_time", "points": [[0, 0], [10, 5]], "t_to": 10, "t_step": 5, "d_to": 10, "d_step": 5,
				"mark": 1},
			{"kind": "distance_time", "points": [[0, 0], [10, 5]], "t_to": 10, "t_step": 5, "d_to": 10, "d_step": 5,
				"t_unit": "days"},
			{"kind": "speed_triangle", "cover": "mass"},
			{"kind": "chart_kinds", "show": ["bar", "bar"]}, {"kind": "chart_kinds", "show": ["map"]},
			{"kind": "chart_kinds", "show": ["bar"], "mark": "pie"},
			{"kind": "odd_scale", "values": [["A", 5], ["B", 50]], "ticks": [0, 10, 20]},
			{"kind": "odd_scale", "values": [["A", 5], ["B", 6]], "ticks": [0, 10, 5]},
			{"kind": "odd_scale", "values": [["A", 5]], "ticks": [0, 5, 10]},
			{"kind": "odd_scale", "values": [["a long label", 5], ["B", 6]], "ticks": [0, 5, 10]},
			{"kind": "big_icons", "what": "bag", "scale": 4}, {"kind": "big_icons", "what": "car", "scale": 2},
			{"kind": "big_icons", "what": "bag", "scale": 2, "labels": ["one"]},
			{"kind": "periodic_grid", "view": "short"}, {"kind": "periodic_grid", "view": "first20", "mark": ["Fe"]},
			{"kind": "periodic_grid", "view": "full", "hide": "La"}, {"kind": "periodic_grid", "view": "first20", "col": 9},
			{"kind": "periodic_grid", "view": "full", "row": 8}, {"kind": "periodic_grid", "view": "full", "mark": ["Xx"]},
			{"kind": "ph_scale", "marks": [[15, "too high"]]}, {"kind": "ph_scale", "marks": [[7, "a label far too long"]]},
			{"kind": "ph_scale", "marks": [[7, "water"]], "hide": 1}, {"kind": "ph_scale", "bands": 1},
			{"kind": "separation", "method": "boil"}, {"kind": "separation", "method": "filter", "mark": "condenser"},
			{"kind": "chromatogram", "samples": []}, {"kind": "chromatogram", "samples": [["A", [1.2]]]},
			{"kind": "chromatogram", "samples": [["A", [0.2, 0.3, 0.4, 0.5, 0.6]]]},
			{"kind": "chromatogram", "samples": [["a name too long", [0.2]]]},
			{"kind": "chromatogram", "samples": [["A", [0.2]]], "mark": 1},
			{"kind": "chromatogram", "samples": [["A", [[0.2, "silver"]]]]},
			{"kind": "chromatogram", "samples": [["A", [[0.2]]]]},
			{"kind": "light_rays", "view": "mirror"}, {"kind": "light_rays", "view": "refraction", "angle": 85},
			{"kind": "light_rays", "view": "leaving", "angle": 60},
			{"kind": "light_rays", "view": "refraction", "into": "oil"},
			{"kind": "light_rays", "view": "prism", "mark": "normal"},
			{"kind": "seen_colour", "light": "pink", "object": "red"}, {"kind": "seen_colour", "light": "red", "object": "grey"},
			{"kind": "seen_colour", "light": "red", "object": "red", "filter": "yellow"},
			{"kind": "carbon_cycle", "hide": "melting"}, {"kind": "carbon_cycle", "labels": "no"},
			{"kind": "air_mix", "gases": [["nitrogen", 78], ["oxygen", 21]]},
			{"kind": "air_mix", "gases": [["nitrogen", 100]]}, {"kind": "air_mix", "hide": 3},
			{"kind": "marked_text", "lines": []},
			{"kind": "marked_text", "lines": ["A short line."], "marks": [[0, "not there"]]},
			{"kind": "marked_text", "lines": ["A short line."], "marks": [[1, "short"]]},
			{"kind": "marked_text", "lines": ["A short line."], "marks": [[0, "short"]], "tags": []},
			{"kind": "marked_text", "lines": ["This line is far too long to fit on one card of the School."]},
			{"kind": "venn", "left_name": "a", "right_name": "b"},
			{"kind": "venn", "left_name": "a", "right_name": "b", "both": ["an item that is too long"]},
			{"kind": "venn", "right_name": "b", "both": ["x"]},
			{"kind": "venn", "left_name": "a", "right_name": "b", "both": ["x"], "hide": "middle"},
			{"kind": "pov_view", "mode": "second"}, {"kind": "pov_view", "mode": "first", "names": ["A", "B"]}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))


## Every whole number above 1 is a product of primes in one way: the tree splits off the smallest prime each time.
func test_prime_factors_and_powers() -> void:
	assert_eq(SchoolPictureG7Core.prime_factors(60), [2, 2, 3, 5] as Array[int])
	assert_eq(SchoolPictureG7Core.prime_factors(84), [2, 2, 3, 7] as Array[int])
	assert_eq(SchoolPictureG7Core.prime_factors(97), [97] as Array[int])
	assert_eq(SchoolPictureG7Core.power_form(60), "2² × 3 × 5")
	assert_eq(SchoolPictureG7Core.power_form(640), "2⁷ × 5")
	assert_eq(SchoolPictureG7Core.power_form(72), "2³ × 3²")
	assert_true(SchoolPictureG7Core.is_prime(2))
	assert_false(SchoolPictureG7Core.is_prime(1))
	assert_false(SchoolPictureG7Core.is_prime(91), "91 = 7 × 13")
	for n in range(4, 1000):
		var product := 1
		for p in SchoolPictureG7Core.prime_factors(n):
			assert_true(SchoolPictureG7Core.is_prime(p), "%d's factor %d is prime" % [n, p])
			product *= p
		assert_eq(product, n, "%d's primes multiply to it" % n)


## The HCF multiplies the shared primes and the LCM all of them; HCF × LCM = a × b (checked by Euclid's method here).
func test_hcf_and_lcm() -> void:
	assert_eq(SchoolPictureG7Core.hcf(60, 84), 12)
	assert_eq(SchoolPictureG7Core.lcm(60, 84), 420)
	assert_eq(SchoolPictureG7Core.hcf(12, 18), 6)
	assert_eq(SchoolPictureG7Core.lcm(12, 18), 36)
	assert_eq(SchoolPictureG7Core.hcf(7, 9), 1)
	assert_eq(str(SchoolPictureG7Core.venn_parts(60, 84)), str([[5], [2, 2, 3], [7]]))
	for a in range(2, 120, 7):
		for b in range(2, 120, 11):
			var x := a
			var y := b
			while y != 0:
				var t := x % y
				x = y
				y = t
			assert_eq(SchoolPictureG7Core.hcf(a, b), x, "HCF of %d and %d" % [a, b])
			assert_eq(SchoolPictureG7Core.lcm(a, b), a * b / x, "LCM of %d and %d" % [a, b])


func test_speed_and_the_triangle() -> void:
	var pts := [[0, 0], [30, 6], [45, 6], [60, 12]]
	assert_almost_eq(SchoolPictureG7Core.leg_speed(pts, 0), 0.2, 0.0001, "6 km in 30 minutes: 0.2 km a minute")
	assert_almost_eq(SchoolPictureG7Core.leg_speed(pts, 1), 0.0, 0.0001, "a flat leg: stopped")
	assert_almost_eq(SchoolPictureG7Core.leg_speed(pts, 2) * 60.0, 24.0, 0.0001, "6 km in 15 minutes: 24 km/h")
	assert_eq(SchoolPictureG7Core.formula_for("distance"), "distance = speed × time")
	assert_eq(SchoolPictureG7Core.formula_for("speed"), "speed = distance ÷ time")
	assert_eq(SchoolPictureG7Core.formula_for("time"), "time = distance ÷ speed")


## Evenly spaced numbers 0, 10, 20, 50, 100: 30 is drawn a third of the way from 20 to 50, at 2.33 of 4 steps; on a fair
## axis it would be 30% of the way up.
func test_bars_on_odd_and_fair_axes() -> void:
	var ticks := [0, 10, 20, 50, 100]
	assert_almost_eq(SchoolPictureG7Core.drawn_height(ticks, 30.0), (2.0 + 1.0 / 3.0) / 4.0, 0.0001)
	assert_almost_eq(SchoolPictureG7Core.drawn_height(ticks, 100.0), 1.0, 0.0001)
	assert_almost_eq(SchoolPictureG7Core.drawn_height(ticks, 10.0), 0.25, 0.0001)
	assert_almost_eq(SchoolPictureG7Core.honest_height(ticks, 30.0), 0.3, 0.0001)
	assert_true(SchoolPictureG7Core.uneven(ticks))
	assert_false(SchoolPictureG7Core.uneven([0, 5, 10, 15]))
	assert_almost_eq(SchoolPictureG7Core.looks_times(2.0), 4.0, 0.0001, "twice as tall and wide: 4 times the area")
	assert_almost_eq(SchoolPictureG7Core.looks_times(3.0), 9.0, 0.0001)
	assert_almost_eq(SchoolPictureG7Core.looks_times(2.0, true), 8.0, 0.0001, "twice each way, solid: 8 times")


## The periodic table's places by this test's own list (period, school group, metal or not).
func test_the_periodic_table() -> void:
	var facts := {"H": [1, 1, "non-metal"], "He": [1, 0, "non-metal"], "Li": [2, 1, "metal"], "C": [2, 4, "non-metal"],
		"O": [2, 6, "non-metal"], "Ne": [2, 0, "non-metal"], "Na": [3, 1, "metal"], "Mg": [3, 2, "metal"],
		"Al": [3, 3, "metal"], "Si": [3, 4, "metalloid"], "S": [3, 6, "non-metal"], "Cl": [3, 7, "non-metal"],
		"Ar": [3, 0, "non-metal"], "K": [4, 1, "metal"], "Ca": [4, 2, "metal"], "Fe": [4, -1, "metal"],
		"Cu": [4, -1, "metal"], "Br": [4, 7, "non-metal"], "Kr": [4, 0, "non-metal"], "I": [5, 7, "non-metal"],
		"Ag": [5, -1, "metal"], "Au": [6, -1, "metal"], "Hg": [6, -1, "metal"], "Pb": [6, 4, "metal"],
		"Rn": [6, 0, "non-metal"], "Og": [7, 0, "unknown"]}
	for sym: String in facts:
		var f: Array = facts[sym]
		assert_eq(SchoolPictureG7Core.place_of(sym).y, int(f[0]), "%s's period" % sym)
		assert_eq(SchoolPictureG7Core.school_group(sym), int(f[1]), "%s's group" % sym)
		assert_eq(SchoolPictureG7Core.element_kind(sym), str(f[2]), "%s is a %s" % [sym, f[2]])
	assert_eq(SchoolPictureG7Core.atomic_number("Fe"), 26)
	assert_eq(SchoolPictureG7Core.atomic_number("Au"), 79)
	assert_eq(SchoolPictureG7Core.atomic_number("U"), 92)
	assert_eq(SchoolPictureG7Core.symbol_of(8), "O")
	assert_eq(SchoolPictureG7Core.SYMBOLS.size(), 118)
	assert_eq(SchoolPictureG7Core.place_of("Hf"), Vector2i(4, 6))
	assert_eq(SchoolPictureG7Core.place_of("La"), Vector2i(0, 6), "the lanthanides sit outside the main table")
	assert_eq(SchoolPictureG7Core.family_of("Na"), "alkali metals")
	assert_eq(SchoolPictureG7Core.family_of("H"), "", "hydrogen is not an alkali metal")
	assert_eq(SchoolPictureG7Core.family_of("Cl"), "halogens")
	assert_eq(SchoolPictureG7Core.family_of("Ar"), "noble gases")
	assert_eq(SchoolPictureG7Core.family_of("Fe"), "transition metals")
	var metals := 0
	for s in SchoolPictureG7Core.SYMBOLS:
		if SchoolPictureG7Core.element_kind(s) == "metal":
			metals += 1
	assert_gt(metals, 118 * 2 / 3, "most elements are metals: more than two in three")


func test_ph_strength_and_indicator() -> void:
	var facts := {1.0: ["acid", "strongly acidic", "red"], 3.0: ["acid", "strongly acidic", "red"],
		5.0: ["acid", "weakly acidic", "orange"], 6.0: ["acid", "weakly acidic", "yellow"],
		7.0: ["neutral", "neutral", "green"], 9.0: ["alkali", "weakly alkaline", "blue"],
		11.0: ["alkali", "strongly alkaline", "purple"], 14.0: ["alkali", "strongly alkaline", "purple"]}
	for ph: float in facts:
		var f: Array = facts[ph]
		assert_eq(SchoolPictureG7Core.ph_kind(ph), str(f[0]), "pH %s" % ph)
		assert_eq(SchoolPictureG7Core.strength(ph), str(f[1]), "pH %s" % ph)
		assert_eq(SchoolPictureG7Core.indicator_colour(ph), str(f[2]), "pH %s" % ph)
	assert_eq(SchoolPictureG7Core.PH_COLOURS.size(), 15)


func test_chromatograms_and_rf() -> void:
	assert_true(SchoolPictureG7Core.is_pure(["red", [0.5]]))
	assert_false(SchoolPictureG7Core.is_pure(["black", [0.2, 0.5]]))
	assert_eq(SchoolPictureG7Core.shared(["mix", [0.2, 0.5, 0.8]], ["red", [0.5]]), [0.5])
	assert_eq(SchoolPictureG7Core.shared(["a", [0.3]], ["b", [0.6]]), [])
	assert_eq(SchoolPictureG7Core.shared(["black", [[0.2, "yellow"], [0.5, "red"]]], ["red", [[0.5, "red"]]]), [0.5])
	assert_almost_eq(SchoolPictureG7Core.rf(3.0, 6.0), 0.5, 0.0001)


## Snell's law with this test's own numbers: into glass at 30° from the normal, sin r = 0.5 ÷ 1.5, so r ≈ 19.5°; light
## that slows bends towards the normal; out of glass at 60° it cannot leave (sin 60° × 1.5 > 1).
func test_refraction() -> void:
	assert_almost_eq(SchoolPictureG7Core.refracted_angle(30.0, 1.0, 1.5), 19.47, 0.01)
	assert_almost_eq(SchoolPictureG7Core.refracted_angle(0.0, 1.0, 1.5), 0.0, 0.0001, "along the normal: no bend")
	assert_lt(SchoolPictureG7Core.refracted_angle(40.0, 1.0, 1.33), 40.0, "into water: towards the normal")
	assert_gt(SchoolPictureG7Core.refracted_angle(30.0, 1.5, 1.0), 30.0, "out into air: away from the normal")
	assert_eq(SchoolPictureG7Core.refracted_angle(60.0, 1.5, 1.0), -1.0, "it cannot leave")
	assert_true(SchoolPictureG7Core.bends_towards(1.0, 1.5))
	assert_false(SchoolPictureG7Core.bends_towards(1.5, 1.0))
	assert_eq(SchoolPictureG7Core.SPECTRUM, ["red", "orange", "yellow", "green", "blue", "indigo", "violet"] as Array[String])


## A thing reflects its own colour of light (white all three, black none, yellow red and green); a filter lets only its
## colour through.
func test_the_colour_you_see() -> void:
	var facts := [["white", "red", "", "red"], ["green", "red", "", "black"], ["red", "red", "", "red"],
		["white", "white", "", "white"], ["red", "white", "", "red"], ["white", "black", "", "black"],
		["white", "yellow", "", "yellow"], ["red", "yellow", "", "red"], ["green", "yellow", "", "green"],
		["blue", "yellow", "", "black"], ["white", "blue", "red", "black"], ["white", "white", "red", "red"],
		["white", "green", "green", "green"], ["blue", "blue", "", "blue"]]
	for f: Array in facts:
		assert_eq(SchoolPictureG7Core.seen_as(str(f[0]), str(f[1]), str(f[2])), str(f[3]), str(f))


func test_the_carbon_cycle() -> void:
	assert_true(SchoolPictureG7Core.adds_carbon_dioxide("respiration"))
	assert_true(SchoolPictureG7Core.adds_carbon_dioxide("combustion"))
	assert_true(SchoolPictureG7Core.adds_carbon_dioxide("decay"))
	assert_false(SchoolPictureG7Core.adds_carbon_dioxide("photosynthesis"))
	assert_false(SchoolPictureG7Core.adds_carbon_dioxide("feeding"))
	assert_true(SchoolPictureG7Core.process_from("air").has(["photosynthesis", "plants"]))
	assert_true(SchoolPictureG7Core.process_from("fossil fuels").has(["combustion", "air"]))
	assert_true(SchoolPictureG7Core.process_from("decomposers").has(["fossilisation", "fossil fuels"]))
	for f: Array in SchoolPictureG7Core.FLOWS:
		assert_true(SchoolPictureG7Core.PROCESSES.has(str(f[0])), "%s is a process" % f[0])
		assert_true(SchoolPictureG7Core.STORES.has(str(f[1])) and SchoolPictureG7Core.STORES.has(str(f[4])), str(f))


## A label exercise's pins end on their parts: every part of every labelled diagram is inside its picture's box.
func test_every_part_is_on_its_picture() -> void:
	var box := ExerciseCheck.LABEL_BOX
	var checks := 0
	for view: String in SchoolPictureG7Core.LIGHT_VIEWS:
		var p := {"kind": "light_rays", "view": view}
		for part: String in SchoolPictureG7Core.LIGHT_PARTS[view]:
			var at := SchoolPictureG7Core.part_at(p, part, box)
			assert_true(Rect2(Vector2.ZERO, box).has_point(at), "%s's %s at %s" % [view, part, at])
			checks += 1
	for m: String in SchoolPictureG7Core.METHODS:
		var p := {"kind": "separation", "method": m}
		for part: String in SchoolPictureG7Core.SEPARATION_PARTS[m]:
			var at := SchoolPictureG7Core.part_at(p, part, box)
			assert_true(Rect2(Vector2.ZERO, box).has_point(at), "%s's %s at %s" % [m, part, at])
			checks += 1
	for s: String in SchoolPictureG7Core.STORES:
		var at := SchoolPictureG7Core.part_at({"kind": "carbon_cycle", "labels": false}, s, box)
		assert_true(Rect2(Vector2.ZERO, box).has_point(at), "the carbon cycle's %s" % s)
		checks += 1
	for fam: String in SchoolPictureG7Core.FAMILIES:
		var at := SchoolPictureG7Core.part_at({"kind": "periodic_grid", "view": "full"}, fam, box)
		assert_true(Rect2(Vector2.ZERO, box).has_point(at), "the table's %s" % fam)
		checks += 1
	assert_eq(SchoolPictureG7Core.part_at({"kind": "carbon_cycle"}, "the Moon", box), Vector2(-1, -1))
	assert_eq(SchoolPictureG7Core.part_at({"kind": "venn", "left_name": "a", "right_name": "b", "both": ["x"]}, "a", box),
		Vector2(-1, -1), "a kind with no parts")
	assert_gt(checks, 40)
