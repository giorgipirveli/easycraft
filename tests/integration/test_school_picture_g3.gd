extends GutTest
## Owner #70, grade 3 maths: the picture kinds grade 3 adds (SchoolPictureG3, drawn inside SchoolPicture): pictograms and
## scaled bar graphs (3.MD.3), measuring jugs, a kitchen scale's dial and a ruler (3.MD.2, 3.MD.4), shapes cut into
## parts (3.NF.1, 3.G.2), shapes of unit squares and shapes with their sides' lengths (3.MD.5-8), line plots in halves
## and quarters (3.MD.4), bar models (3.OA.8), a digital clock (3.MD.1, 24-hour time), the times-table grid (3.OA.7,
## 3.OA.9) and a fraction wall without words (3.NF.3). Every kind draws from its data at the School's picture sizes;
## broken data is a problem the content test finds.

const SAMPLES: Array[Dictionary] = [
	{"kind": "pictogram", "rows": [["Cats", 6], ["Dogs", 9], ["Owls", 4]], "each": 2, "unit": "votes"},
	{"kind": "pictogram", "rows": [["Mon", 20], ["Tue", 35]], "each": 5, "block": 28},
	{"kind": "bar_graph", "bars": [["red", 14], ["blue", 8], ["green", 11], ["gold", 5]], "step": 2, "top": 16,
		"name": "Blocks"},
	{"kind": "bar_graph", "bars": [["A", 50]], "step": 10, "top": 60},
	{"kind": "jug", "top": 5, "fill": 3, "step": 1, "unit": "L"},
	{"kind": "jug", "jugs": [{"top": 1000, "fill": 750, "label": "A"}, {"top": 1000, "fill": 250, "label": "B"}],
		"step": 200, "unit": "mL", "minor": 1},
	{"kind": "dial_scale", "top": 1000, "step": 100, "value": 450, "unit": "g", "minor": 1, "block": 28},
	{"kind": "dial_scale", "top": 10, "step": 1, "value": 7, "unit": "kg"},
	{"kind": "ruler", "to": 10, "length": "7"},
	{"kind": "ruler", "to": 12, "length": "6.5", "from": "2", "mm": true},
	{"kind": "cut_shape", "shape": "circle", "parts": 4, "shade": 3},
	{"kind": "cut_shape", "shape": "circle", "parts": 3, "unequal": true},
	{"kind": "cut_shape", "shape": "square", "parts": 4, "way": "diagonals", "shade": 1},
	{"kind": "cut_shape", "shape": "rectangle", "parts": 6, "way": "grid", "shade": 2},
	{"kind": "cut_shape", "shape": "rectangle", "parts": 5, "shade": 2},
	{"kind": "cut_shape", "shape": "hexagon", "parts": 6, "shade": 1},
	{"kind": "cut_shape", "shape": "triangle", "parts": 4, "shade": 1},
	{"kind": "unit_squares", "rows": ["###..", "###..", "#####"]},
	{"kind": "unit_squares", "rows": ["aaa..", "aaa..", "bbbbb"], "grid": false, "labels": true, "unit": "m"},
	{"kind": "unit_squares", "rows": ["####", "####"], "labels": true, "per": 2, "unit": "cm"},
	{"kind": "side_lengths", "what": "triangle_acute", "labels": ["5 cm", "4 cm", "5 cm"]},
	{"kind": "side_lengths", "points": [[0, 0], [6, 0], [6, 2], [3, 2], [3, 4], [0, 4]],
		"labels": ["6 m", "2 m", "3 m", "2 m", "3 m", "?"]},
	{"kind": "fraction_plot", "from": 1, "to": 4, "parts": 2, "counts": {"1½": 2, "2": 3, "3½": 1}, "unit": "cm"},
	{"kind": "fraction_plot", "from": 0, "to": 2, "parts": 4, "counts": {"¼": 1, "¾": 2, "1": 1, "1¾": 3}},
	{"kind": "bar_model", "bars": [{"name": "Tilly", "parts": [{"text": "45", "size": 45}, {"text": "?", "size": 30}],
		"total": "75"}]},
	{"kind": "bar_model", "bars": [{"name": "Bram", "parts": [{"text": "60", "size": 60}]},
		{"name": "Zara", "parts": [{"text": "35", "size": 35}]}], "diff": "?"},
	{"kind": "bar_model", "bars": [{"parts": [{"text": "8", "size": 1}, {"text": "8", "size": 1}, {"text": "8", "size": 1},
		{"text": "8", "size": 1}], "total": "?"}]},
	{"kind": "digital_clock", "h": 15, "m": 7},
	{"kind": "digital_clock", "h": 9, "m": 45, "twelve": true},
	{"kind": "times_grid", "rows": 12, "cols": 12},
	{"kind": "times_grid", "rows": 4, "cols": 5, "r0": 6, "c0": 3, "hide": [[7, 5]], "shade_row": 8},
	{"kind": "times_grid", "rows": 5, "cols": 5, "op": "+", "shade_col": 2},
	{"kind": "fraction_wall", "rows": [{"den": 2, "shade": 1}, {"den": 4, "shade": 2}, {"den": 8, "shade": 4}]},
	{"kind": "fraction_wall", "rows": [{"den": 3, "shade": 2}], "labels": true},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(248, 126)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_grade_3_kind_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureG3.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)
	assert_eq(kinds.size(), SchoolPictureG3.KINDS.size())


func test_no_kind_is_another_grades() -> void:
	for k: String in SchoolPictureG3.KINDS:
		assert_false(SchoolPicture.KINDS.has(k) or SchoolPictureG5.KINDS.has(k) or SchoolPicture.SCIENCE_KINDS.has(k), k)


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
			{"kind": "pictogram", "rows": [], "each": 2}, {"kind": "pictogram", "rows": [["A", 3]], "each": 2, "block": 99999},
			{"kind": "pictogram", "rows": [["A", 5]], "each": 4}, {"kind": "pictogram", "rows": [["A", 30]], "each": 2},
			{"kind": "pictogram", "rows": [["A", 4]], "each": 0},
			{"kind": "bar_graph", "bars": [["A", 5]], "step": 2, "top": 7}, {"kind": "bar_graph", "bars": [["A", 50]], "step": 2,
				"top": 40}, {"kind": "bar_graph", "bars": [["A", 5]], "step": 1, "top": 11},
			{"kind": "jug", "top": 5, "fill": 6, "step": 1, "unit": "L"}, {"kind": "jug", "top": 5, "fill": 2, "step": 1,
				"unit": "cups"}, {"kind": "jug", "jugs": [], "step": 1, "unit": "L"},
			{"kind": "jug", "top": 25, "fill": 2, "step": 1, "unit": "L"},
			{"kind": "dial_scale", "top": 1000, "step": 50, "value": 450, "unit": "g"},
			{"kind": "dial_scale", "top": 10, "step": 1, "value": 11, "unit": "kg"},
			{"kind": "dial_scale", "top": 10, "step": 1, "value": 1, "unit": "L"},
			{"kind": "ruler", "to": 10, "length": "11"}, {"kind": "ruler", "to": 20, "length": "3"},
			{"kind": "ruler", "to": 10, "length": "abc"},
			{"kind": "cut_shape", "shape": "star", "parts": 4}, {"kind": "cut_shape", "shape": "hexagon", "parts": 4},
			{"kind": "cut_shape", "shape": "square", "parts": 5, "way": "grid"},
			{"kind": "cut_shape", "shape": "rectangle", "parts": 4, "way": "diagonals"},
			{"kind": "cut_shape", "shape": "circle", "parts": 4, "shade": 5},
			{"kind": "cut_shape", "shape": "triangle", "parts": 3, "unequal": true},
			{"kind": "unit_squares", "rows": []}, {"kind": "unit_squares", "rows": ["##", "###"]},
			{"kind": "unit_squares", "rows": ["..", ".."]}, {"kind": "unit_squares", "rows": ["#x"]},
			{"kind": "side_lengths", "what": "circle", "labels": []}, {"kind": "side_lengths", "what": "square",
				"labels": ["1", "2"]}, {"kind": "side_lengths", "points": [[0, 0], [20, 0], [0, 3]], "labels": ["a", "b", "c"]},
			{"kind": "fraction_plot", "from": 0, "to": 5, "parts": 4, "counts": {}},
			{"kind": "fraction_plot", "from": 0, "to": 2, "parts": 2, "counts": {"¼": 1}},
			{"kind": "fraction_plot", "from": 1, "to": 2, "parts": 2, "counts": {"3": 1}},
			{"kind": "bar_model", "bars": []}, {"kind": "bar_model", "bars": [{"parts": [{"text": "a", "size": 0}]}]},
			{"kind": "bar_model", "bars": [{"parts": [{"text": "a", "size": 2}]}], "diff": "?"},
			{"kind": "digital_clock", "h": 24, "m": 0}, {"kind": "digital_clock", "h": 3, "m": 60},
			{"kind": "times_grid", "rows": 0, "cols": 3}, {"kind": "times_grid", "rows": 5, "cols": 5, "r0": 10},
			{"kind": "times_grid", "rows": 3, "cols": 3, "hide": [[9, 9]]},
			{"kind": "times_grid", "rows": 3, "cols": 3, "op": "−"},
			{"kind": "fraction_wall", "rows": []}, {"kind": "fraction_wall", "rows": [{"den": 13, "shade": 1}]},
			{"kind": "fraction_wall", "rows": [{"den": 4, "shade": 5}]}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))


func test_a_plot_key_is_a_number_of_quarters() -> void:
	assert_eq(SchoolPictureG3.quarters_of("2½"), 10)
	assert_eq(SchoolPictureG3.quarters_of("¾"), 3)
	assert_eq(SchoolPictureG3.quarters_of("3"), 12)
	assert_eq(SchoolPictureG3.quarters_of("0"), 0)
	assert_eq(SchoolPictureG3.quarters_of("x"), -1)
	assert_eq(SchoolPictureG3.quarters_of(""), -1)
	for q in 20:
		assert_eq(SchoolPictureG3.quarters_of(SchoolPictureG3.quarter_text(q)), q, str(q))


func test_the_sides_of_an_l_shape() -> void:
	var sides := SchoolPictureG3.square_sides(["###..", "###..", "#####"])
	var lengths: Array[int] = []
	var perimeter := 0
	for s: Dictionary in sides:
		lengths.append(int(s.len))
		perimeter += int(s.len)
	lengths.sort()
	var expected: Array[int] = [1, 2, 2, 3, 3, 5]
	assert_eq(lengths, expected, "six sides")
	assert_eq(perimeter, 16, "the L-shape's perimeter")


func test_a_cut_shapes_parts_are_equal_unless_it_is_cut_unequally() -> void:
	var box := Rect2(0, 0, 300, 300)
	for d: Dictionary in [{"shape": "circle", "parts": 5}, {"shape": "square", "parts": 4, "way": "diagonals"},
			{"shape": "rectangle", "parts": 6, "way": "grid"}, {"shape": "hexagon", "parts": 3},
			{"shape": "hexagon", "parts": 2}, {"shape": "triangle", "parts": 3}, {"shape": "triangle", "parts": 4},
			{"shape": "square", "parts": 3}]:
		var areas := _areas(SchoolPictureG3.cut_parts(d, box))
		assert_eq(areas.size(), int(d.parts), str(d))
		for a in areas:
			assert_almost_eq(a, areas[0], areas[0] * 0.03, "equal parts: %s" % d)
	var uneven := _areas(SchoolPictureG3.cut_parts({"shape": "circle", "parts": 3, "unequal": true}, box))
	assert_gt(absf(uneven[0] - uneven[1]), uneven[0] * 0.2, "an unequal cut has parts of different sizes")


func _areas(polys: Array[PackedVector2Array]) -> Array[float]:
	var out: Array[float] = []
	for poly in polys:
		var a := 0.0
		for i in poly.size():
			a += poly[i].cross(poly[(i + 1) % poly.size()])
		out.append(absf(a) * 0.5)
	return out
