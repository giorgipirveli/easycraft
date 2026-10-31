extends GutTest
## Owner #68, grade 5 maths: the picture kinds grade 5 adds (SchoolPictureG5, drawn inside SchoolPicture): a coordinate
## grid (5.G.1-2), boxes of unit cubes (5.MD.3-5), the quadrilaterals' family tree (5.G.3-4), a place value chart to
## thousandths with its "× 10" steps (5.NBT.1-3), an area model (5.NBT.5-6), a square cut both ways for fractions and
## decimals times each other (5.NF.4, 5.NBT.7) and sums written in columns (5.NBT.5, 5.NBT.7). Every kind draws from its
## data at the School's picture sizes; broken data is a problem the content test finds.

const SAMPLES: Array[Dictionary] = [
	{"kind": "grid", "x_max": 10, "y_max": 8},
	{"kind": "grid", "x_max": 6, "y_max": 18, "y_step": 3, "points": [{"x": 0, "y": 0}, {"x": 1, "y": 3}, {"x": 2, "y": 6,
		"label": "C"}], "join": true, "x_name": "x", "y_name": "y"},
	{"kind": "cubes", "boxes": [{"l": 4, "w": 3, "h": 2}]},
	{"kind": "cubes", "boxes": [{"l": 3, "w": 2, "h": 4}, {"l": 2, "w": 2, "h": 2}], "labels": true, "unit": "cm"},
	{"kind": "cubes", "boxes": [{"l": 5, "w": 4, "h": 3, "fill": 1}], "labels": true},
	{"kind": "cubes", "boxes": [{"l": 8, "w": 6, "h": 5}], "grid": false, "labels": true, "unit": "m", "unknown": "h"},
	{"kind": "family"},
	{"kind": "family", "hide": "rhombus", "mark": "square"},
	{"kind": "places", "numbers": ["2.358"]},
	{"kind": "places", "numbers": ["34", "340", "3,400"], "times_ten": true, "highlight": "tens"},
	{"kind": "places", "numbers": ["0.45", "0.405"]},
	{"kind": "area_model", "cols": ["300", "40", "2"], "rows": ["20", "5"], "cells": [["6,000", "800", "40"],
		["1,500", "200", "10"]]},
	{"kind": "area_model", "cols": ["30", "?"], "rows": ["24"], "cells": [["720", "48"]]},
	{"kind": "fraction_area", "cols": 4, "rows": 3, "shade_cols": 3, "shade_rows": 2},
	{"kind": "fraction_area", "cols": 10, "rows": 10, "shade_cols": 6, "shade_rows": 3, "w": "0.6", "h": "0.3"},
	{"kind": "column", "rows": ["342", "× 25", "1,710", "6,840", "8,550"], "lines": [1, 3]},
	{"kind": "column", "rows": ["3.45", "+ 2.3", "5.75"], "lines": [1]},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(248, 126)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_grade_5_kind_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureG5.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)
	assert_eq(kinds.size(), SchoolPictureG5.KINDS.size())


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
			{"kind": "grid", "x_max": 0, "y_max": 5},
			{"kind": "cubes"}, {"kind": "cubes", "boxes": []}, {"kind": "cubes", "boxes": [{"l": 0, "w": 2, "h": 2}]},
			{"kind": "cubes", "boxes": [{"l": 11, "w": 2, "h": 2}]}, {"kind": "cubes", "boxes": [{"l": 2, "w": 2, "h": 2,
				"fill": 3}]}, {"kind": "cubes", "boxes": [{"l": 8, "w": 2, "h": 2}, {"l": 8, "w": 2, "h": 2}]},
			{"kind": "cubes", "boxes": [{"l": 2, "w": 2, "h": 2}], "unknown": "v"},
			{"kind": "cubes", "boxes": [{"l": 2, "w": 2, "h": 2}, {"l": 2, "w": 2, "h": 2}, {"l": 2, "w": 2, "h": 2}]},
			{"kind": "family", "hide": "circle"}, {"kind": "family", "mark": "blob"}, {"kind": "family", "tree": "animals"},
			{"kind": "places"}, {"kind": "places", "numbers": []}, {"kind": "places", "numbers": ["3.4567"]},
			{"kind": "places", "numbers": ["12345678"]}, {"kind": "places", "numbers": ["-3"]},
			{"kind": "places", "numbers": ["2.5"], "highlight": "millions"},
			{"kind": "places", "numbers": ["1", "2", "3", "4"]},
			{"kind": "area_model", "cols": [], "rows": ["2"]}, {"kind": "area_model", "cols": ["1", "2", "3", "4", "5"],
				"rows": ["2"]}, {"kind": "area_model", "cols": ["3"], "rows": ["2"], "cells": [["6", "7"]]},
			{"kind": "fraction_area", "cols": 4, "rows": 3, "shade_cols": 5, "shade_rows": 2},
			{"kind": "fraction_area", "cols": 0, "rows": 3, "shade_cols": 0, "shade_rows": 2},
			{"kind": "column", "rows": ["342"]}, {"kind": "column", "rows": ["342", "× 2a"]},
			{"kind": "column", "rows": ["342", "25"], "lines": [7]}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))


func test_the_grid_maps_numbers_to_the_screen_and_back() -> void:
	var g := {"x_max": 10, "y_max": 20, "y_step": 2}
	var r := Rect2(14, 14, 552, 222)
	var frame := SchoolPictureG5.grid_frame(r, g)
	var origin := SchoolPictureG5.grid_at(frame, Vector2i(0, 0))
	var far := SchoolPictureG5.grid_at(frame, Vector2i(10, 20))
	assert_true(r.has_point(origin) and r.has_point(far), "the grid is inside its card")
	assert_lt(far.y, origin.y, "y goes up")
	assert_gt(far.x, origin.x, "x goes right")
	assert_eq(SchoolPictureG5.grid_value(frame, SchoolPictureG5.grid_at(frame, Vector2i(3, 14))), Vector2i(3, 14))
	assert_eq(SchoolPictureG5.grid_value(frame, SchoolPictureG5.grid_at(frame, Vector2i(3, 14)) + Vector2(4, -3)),
		Vector2i(3, 14), "a finger a little off still finds the point")


func test_the_place_chart_has_the_places_its_numbers_need() -> void:
	assert_eq(SchoolPictureG5.places_of(["2.358"]), ["ones", "tenths", "hundredths", "thousandths"])
	assert_eq(SchoolPictureG5.places_of(["34", "3,400"]), ["thousands", "hundreds", "tens", "ones"])
	assert_eq(SchoolPictureG5.places_of(["0.45", "12.4"]), ["tens", "ones", "tenths", "hundredths"])
