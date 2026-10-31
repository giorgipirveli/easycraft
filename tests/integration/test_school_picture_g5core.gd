extends GutTest
## Grade 5 maths, science and English: the picture kinds they add (SchoolPictureG5Core, drawn inside SchoolPicture): a
## hundred square, angle facts (on a straight line, round a point, where two lines cross, in triangles and quadrilaterals), circuit
## symbols and circuit diagrams in series and in parallel, forces as arrows, life cycles, a flower cut in half, the chest
## breathing in and out, and the blood's double loop. Every kind draws from its data at the School's picture sizes; the
## rules the pictures draw by are the ones the lessons teach; broken data is a problem the content test finds.

const SAMPLES: Array[Dictionary] = [
	{"kind": "angle_facts", "figure": "straight", "angles": [130, 50]},
	{"kind": "angle_facts", "figure": "straight", "angles": [40, 90, 50], "labels": ["40°", "", "?"]},
	{"kind": "angle_facts", "figure": "straight", "angles": [30, 45, 60, 45], "labels": ["a", "a", "60°", "45°"]},
	{"kind": "angle_facts", "figure": "point", "angles": [100, 120, 140]},
	{"kind": "angle_facts", "figure": "point", "angles": [90, 75, 105, 45, 45], "labels": ["", "75°", "?", "b", "b"]},
	{"kind": "angle_facts", "figure": "point", "angles": [200, 160]},
	{"kind": "angle_facts", "figure": "cross", "angles": [40, 140, 40, 140]},
	{"kind": "angle_facts", "figure": "cross", "angles": [65, 115, 65, 115], "labels": ["65°", "", "?", ""]},
	{"kind": "angle_facts", "figure": "cross", "angles": [70.0, 110.0, 70.0, 110.0]},   # numbers as JSON loads them
	{"kind": "angle_facts", "figure": "triangle", "angles": [60, 70, 50]},
	{"kind": "angle_facts", "figure": "triangle", "angles": [90, 35, 55], "labels": ["", "35°", "?"]},
	{"kind": "angle_facts", "figure": "triangle", "angles": [70, 70, 40], "labels": ["?", "?", "40°"], "ticks": [1, 2]},
	{"kind": "angle_facts", "figure": "triangle", "angles": [25, 25, 130], "ticks": [1, 2]},
	{"kind": "angle_facts", "figure": "quad", "angles": [80, 100, 70, 110]},
	{"kind": "angle_facts", "figure": "quad", "angles": [90, 90, 90, 90], "ticks": [0, 1, 2, 3]},
	{"kind": "angle_facts", "figure": "quad", "angles": [60, 120, 60, 120], "labels": ["60°", "?", "", ""]},
	{"kind": "angle_facts", "figure": "quad", "angles": [110, 70, 95, 85], "labels": ["110°", "70°", "95°", "?"]},
	{"kind": "hundred_square", "shaded": 35},
	{"kind": "hundred_square", "shaded": 0, "label": "percent"},
	{"kind": "hundred_square", "shaded": 100, "label": "fraction"},
	{"kind": "hundred_square", "shaded": 7.0, "label": "decimal"},
	{"kind": "hundred_square", "shaded": 50, "label": "none"},
	{"kind": "circuit_symbols", "symbols": ["cell", "battery", "lamp", "open", "closed", "buzzer"]},
	{"kind": "circuit_symbols", "symbols": ["motor", "wire"]},
	{"kind": "circuit_symbols", "symbols": ["lamp"], "names": false},
	{"kind": "circuit_symbols", "series": ["lamp"]},
	{"kind": "circuit_symbols", "series": ["closed", "lamp", "lamp"], "lit": true, "tags": true},
	{"kind": "circuit_symbols", "series": ["open", "buzzer", "motor", "lamp"], "cells": 3, "lit": true},
	{"kind": "circuit_symbols", "series": ["lamp"], "cells": 2, "lit": true},
	{"kind": "circuit_symbols", "branches": [["lamp"], ["lamp"]], "lit": true},
	{"kind": "circuit_symbols", "branches": [["open", "lamp"], ["lamp"], ["buzzer"]], "main": ["closed"], "tags": true,
		"lit": true},
	{"kind": "circuit_symbols", "branches": [["lamp", "lamp"], ["closed", "motor"]], "main": ["open", "closed"],
		"cells": 2},
	{"kind": "force_arrows", "thing": "block", "arrows": [["right", 2, "push"], ["left", 1, "friction"]], "ground": "carpet",
		"moving": "right"},
	{"kind": "force_arrows", "thing": "car", "arrows": [["left", 3, "friction"]], "ground": "sand"},
	{"kind": "force_arrows", "thing": "block", "arrows": [["down", 2, "gravity"], ["up", 2, "the floor"]], "ground": "ice"},
	{"kind": "force_arrows", "thing": "car", "arrows": [["right", 1]], "ground": "grass", "moving": "right"},
	{"kind": "force_arrows", "thing": "block", "arrows": [["right", 3, "push"]], "ground": "wood"},
	{"kind": "force_arrows", "thing": "parachute", "arrows": [["up", 3, "air resistance"], ["down", 3, "gravity"]],
		"moving": "down"},
	{"kind": "force_arrows", "thing": "skydiver", "arrows": [["up", 1, "air resistance"], ["down", 3, "gravity"]]},
	{"kind": "force_arrows", "thing": "boat", "arrows": [["right", 2, "engine"], ["left", 2, "water resistance"]],
		"moving": "right"},
	{"kind": "force_arrows", "thing": "ball", "arrows": [["down", 2, "gravity"], ["up", 1, ""], ["left", 1], ["right", 1]]},
	{"kind": "life_cycle", "stages": ["egg", "chick", "adult"], "title": "chicken"},
	{"kind": "life_cycle", "stages": ["egg", "tadpole", "froglet", "adult frog"], "title": "frog", "hide": 2},
	{"kind": "life_cycle", "stages": ["egg", "caterpillar", "chrysalis", "butterfly"], "mark": 1},
	{"kind": "life_cycle", "stages": ["seed", "seedling", "adult plant", "flower", "pollination", "fruit"]},
	{"kind": "life_cycle", "stages": ["egg", "nymph", "adult", "?", "moult"]},
	{"kind": "flower_parts"},
	{"kind": "flower_parts", "labels": "parts"},
	{"kind": "flower_parts", "labels": "parts", "hide": "stigma", "mark": "stigma"},
	{"kind": "flower_parts", "labels": "groups", "mark": "carpel"},
	{"kind": "flower_parts", "mark": "stamen", "bee": true},
	{"kind": "lungs"},
	{"kind": "lungs", "breath": "in", "labels": true},
	{"kind": "lungs", "breath": "out", "mark": "diaphragm"},
	{"kind": "lungs", "mark": "heart", "labels": true},
	{"kind": "blood_loop"},
	{"kind": "blood_loop", "labels": true},
	{"kind": "blood_loop", "labels": true, "hide": "veins", "mark": "veins"},
	{"kind": "blood_loop", "mark": "lungs", "arrows": false},
	{"kind": "blood_loop", "hide": "heart"},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(480, 280), Vector2(248, 126)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_kind_figure_thing_and_mode_has_a_sample() -> void:
	var seen := {}
	for d in SAMPLES:
		seen[str(d.kind)] = true
		for k: String in ["figure", "thing", "ground", "labels", "breath", "label"]:
			if d.has(k) and d[k] is String:
				seen["%s:%s" % [k, d[k]]] = true
		if d.has("branches"):
			seen["branches"] = true
		if d.has("series"):
			seen["series"] = true
		for s: Variant in d.get("symbols", []):
			seen["symbol:%s" % s] = true
	for k: String in SchoolPictureG5Core.KINDS:
		assert_true(seen.has(k), "a sample of %s" % k)
	for f: String in SchoolPictureG5Core.FIGURES:
		assert_true(seen.has("figure:" + f), "a sample of the %s" % f)
	for t: String in SchoolPictureG5Core.THINGS:
		assert_true(seen.has("thing:" + t), "a sample of the %s" % t)
	for g: String in SchoolPictureG5Core.GROUNDS:
		assert_true(seen.has("ground:" + g), "a sample on %s" % g)
	for s: String in SchoolPictureG5Core.SYMBOLS:
		assert_true(seen.has("symbol:" + s), "a sample of the %s symbol" % s)
	for l: String in SchoolPictureG5Core.SQUARE_LABELS:
		assert_true(seen.has("label:" + l), "a hundred square labelled %s" % l)
	for m: String in ["series", "branches", "labels:parts", "labels:groups", "breath:in", "breath:out"]:
		assert_true(seen.has(m), "a sample of %s" % m)


func test_every_sample_draws_at_every_size() -> void:
	for px in SIZES:
		for d in SAMPLES:
			var p := SchoolPicture.new(d, px)
			p.size = px
			add_child_autofree(p)
	await wait_process_frames(2)
	assert_true(true, "drawn without script errors")


## Vertically opposite angles are equal and neighbours make 180°; a triangle and a quadrilateral are drawn with the
## angles they are given (their corners' angles measured again).
func test_the_angle_pictures_follow_the_angle_facts() -> void:
	assert_eq(SchoolPictureG5Core.cross_angles(40), [40, 140, 40, 140])
	assert_eq(SchoolPictureG5Core.cross_angles(90), [90, 90, 90, 90])
	for angles: Array in [[60, 70, 50], [90, 35, 55], [25, 25, 130], [100, 40, 40], [30, 120, 30]]:
		_assert_corners(SchoolPictureG5Core.triangle_points(angles), angles)
	for angles: Array in [[80, 100, 70, 110], [90, 90, 90, 90], [60, 120, 60, 120], [110, 70, 95, 85], [120, 60, 60, 120],
			[45, 135, 100, 80], [150, 30, 150, 30], [170, 5, 170, 15]]:
		_assert_corners(SchoolPictureG5Core.quad_points(angles), angles)


func _assert_corners(pts: Array[Vector2], angles: Array) -> void:
	var n := pts.size()
	assert_eq(n, angles.size())
	var turn := 0.0
	for i in n:
		var here := pts[i]
		var u := pts[(i + 1) % n] - here
		var v := pts[(i - 1 + n) % n] - here
		assert_almost_eq(rad_to_deg(absf(u.angle_to(v))), float(angles[i]), 0.01, "corner %d of %s" % [i, angles])
		turn += u.angle_to(v)
	# every corner turns the same way: a convex shape, drawn anticlockwise on the screen (y down)
	assert_almost_eq(absf(turn), deg_to_rad(float(SchoolPictureG5Core.SUMS["triangle" if n == 3 else "quad"])), 0.001,
		"the corners are all inside angles: %s" % [angles])
	assert_almost_eq(pts[0].y, pts[1].y, 0.0001, "the first side lies flat along the bottom")
	for i in range(2, n):
		assert_lt(pts[i].y, pts[0].y, "the other corners are above the bottom side")


## A lamp in series shares its cells with every lamp on its path; in parallel each branch is its own path, so its lamp
## is as bright as a lamp alone; an open switch breaks its path; a main switch breaks them all; more cells, brighter.
func test_the_circuit_pictures_follow_the_rules_the_lesson_teaches() -> void:
	var c := func(d: Dictionary) -> Array: return SchoolPictureG5Core.power(d)
	assert_eq(c.call({"series": ["lamp"]}), [1.0])
	assert_eq(c.call({"series": ["lamp", "lamp"]}), [0.5, 0.5], "two lamps in series share one cell: dimmer")
	assert_eq(c.call({"series": ["lamp"], "cells": 2}), [2.0], "two cells: brighter")
	assert_eq(c.call({"series": ["lamp", "lamp"], "cells": 2}), [1.0, 1.0])
	assert_eq(c.call({"series": ["open", "lamp", "buzzer"]}), [0.0, 0.0], "an open switch breaks the only path")
	assert_eq(c.call({"series": ["closed", "lamp", "buzzer"]}), [0.5, 0.5])
	assert_eq(c.call({"branches": [["lamp"], ["lamp"]]}), [1.0, 1.0], "in parallel each lamp is as bright as one alone")
	assert_eq(c.call({"branches": [["open", "lamp"], ["lamp"]]}), [0.0, 1.0], "a branch's switch works that branch only")
	assert_eq(c.call({"branches": [["lamp"], ["lamp"]], "main": ["open"]}), [0.0, 0.0], "the main switch works them all")
	assert_eq(c.call({"branches": [["lamp", "lamp"], ["motor"]], "cells": 2}), [1.0, 1.0, 2.0])
	assert_eq(SchoolPictureG5Core.loads({"branches": [["open", "lamp"], ["buzzer", "closed"], ["motor"]]}),
		["lamp", "buzzer", "motor"])


## Only the marked part turns orange: once, with no mark, the blood's unnamed lung vessels matched the empty mark.
func test_only_the_marked_part_is_orange() -> void:
	var blue := SchoolPictureG5Core.POOR
	assert_eq(SchoolPictureG5Core.part_colour("", "", blue), blue, "no mark: the unnamed vessels keep their colour")
	assert_eq(SchoolPictureG5Core.part_colour("veins", "", blue), blue)
	assert_eq(SchoolPictureG5Core.part_colour("veins", "arteries", blue), blue)
	assert_eq(SchoolPictureG5Core.part_colour("veins", "veins", blue), SchoolPictureG5Core.ORANGE)


func test_broken_pictures_are_problems() -> void:
	for d: Dictionary in [
			{"kind": "angle_facts"}, {"kind": "angle_facts", "figure": "circle", "angles": [360]},
			{"kind": "angle_facts", "figure": "straight", "angles": [100, 90]},
			{"kind": "angle_facts", "figure": "straight", "angles": [180]},
			{"kind": "angle_facts", "figure": "straight", "angles": [30, 30, 30, 30, 60]},
			{"kind": "angle_facts", "figure": "point", "angles": [180, 170]},
			{"kind": "angle_facts", "figure": "cross", "angles": [40, 140, 50, 130]},
			{"kind": "angle_facts", "figure": "triangle", "angles": [60, 60, 70]},
			{"kind": "angle_facts", "figure": "triangle", "angles": [90, 90, 0]},
			{"kind": "angle_facts", "figure": "triangle", "angles": [60.5, 59.5, 60]},
			{"kind": "angle_facts", "figure": "quad", "angles": [200, 60, 50, 50]},
			{"kind": "angle_facts", "figure": "quad", "angles": [90, 90, 90, 90], "labels": ["a", "b"]},
			{"kind": "angle_facts", "figure": "quad", "angles": [90, 90, 90, 90], "labels": ["a", "b", "c", "123456"]},
			{"kind": "angle_facts", "figure": "straight", "angles": [90, 90], "ticks": [0]},
			{"kind": "angle_facts", "figure": "triangle", "angles": [60, 60, 60], "ticks": [3]},
			{"kind": "angle_facts", "figure": "triangle", "angles": [60, 60, 60], "ticks": [1, 1]},
			{"kind": "hundred_square"}, {"kind": "hundred_square", "shaded": 101},
			{"kind": "hundred_square", "shaded": -1}, {"kind": "hundred_square", "shaded": 2.5},
			{"kind": "hundred_square", "shaded": 5, "label": "words"},
			{"kind": "circuit_symbols"}, {"kind": "circuit_symbols", "symbols": []},
			{"kind": "circuit_symbols", "symbols": ["resistor"]},
			{"kind": "circuit_symbols", "symbols": ["lamp"], "series": ["lamp"]},
			{"kind": "circuit_symbols", "series": ["lamp"], "branches": [["lamp"], ["lamp"]]},
			{"kind": "circuit_symbols", "series": []}, {"kind": "circuit_symbols", "series": ["open"]},
			{"kind": "circuit_symbols", "series": ["lamp", "lamp", "lamp", "lamp", "lamp"]},
			{"kind": "circuit_symbols", "series": ["lamp"], "cells": 4},
			{"kind": "circuit_symbols", "series": ["lamp"], "main": ["open"]},
			{"kind": "circuit_symbols", "branches": [["lamp"]]},
			{"kind": "circuit_symbols", "branches": [["lamp"], ["closed"]]},
			{"kind": "circuit_symbols", "branches": [["lamp"], ["lamp", "lamp", "lamp"]]},
			{"kind": "circuit_symbols", "branches": [["lamp"], ["lamp"]], "main": ["lamp"]},
			{"kind": "circuit_symbols", "branches": [["lamp"], ["lamp"]], "lit": "yes"},
			{"kind": "force_arrows", "thing": "rocket", "arrows": [["up", 1]]},
			{"kind": "force_arrows", "thing": "block", "arrows": []},
			{"kind": "force_arrows", "thing": "block", "arrows": [["up", 1], ["up", 2]]},
			{"kind": "force_arrows", "thing": "block", "arrows": [["north", 1]]},
			{"kind": "force_arrows", "thing": "block", "arrows": [["up", 4]]},
			{"kind": "force_arrows", "thing": "block", "arrows": [["up", 1, "a label much too long"]]},
			{"kind": "force_arrows", "thing": "boat", "arrows": [["up", 1]], "ground": "ice"},
			{"kind": "force_arrows", "thing": "block", "arrows": [["up", 1]], "ground": "mud"},
			{"kind": "force_arrows", "thing": "block", "arrows": [["up", 1]], "moving": "back"},
			{"kind": "life_cycle"}, {"kind": "life_cycle", "stages": ["egg", "adult"]},
			{"kind": "life_cycle", "stages": ["a", "b", "c", "d", "e", "f", "g"]},
			{"kind": "life_cycle", "stages": ["egg", "a very long stage name", "adult"]},
			{"kind": "life_cycle", "stages": ["egg", "larva", "adult"], "hide": 3},
			{"kind": "life_cycle", "stages": ["egg", "larva", "adult"], "title": "a title far too long"},
			{"kind": "flower_parts", "labels": "all"}, {"kind": "flower_parts", "mark": "root"},
			{"kind": "flower_parts", "hide": "stigma"}, {"kind": "flower_parts", "labels": "groups", "hide": "stigma"},
			{"kind": "flower_parts", "bee": 1},
			{"kind": "lungs", "breath": "hold"}, {"kind": "lungs", "mark": "stomach"}, {"kind": "lungs", "labels": "yes"},
			{"kind": "blood_loop", "mark": "brain"}, {"kind": "blood_loop", "hide": "veins"},
			{"kind": "blood_loop", "arrows": "no"}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))
