extends GutTest
## Owner #70 and #73, grade 6 history, geography and citizenship (research §6.6): the School draws their pictures from
## data (SchoolPictureG6Hum, inside SchoolPicture): a timeline of events and eras, an Inca quipu's knots, the feudal
## pyramid, the Normans' castles, dots of people on squares of land, a city's zones, a detailed map with contours and
## grid lines, a climate graph, a river (its long profile, from above, a meander, a waterfall), a map in layers, and
## savings growing with compound interest. Every sample draws at the School's picture sizes; broken data is a problem
## the content test finds; the rules the pictures draw by (a quipu's knots, grid references, compound interest) are
## checked here.

const SAMPLES: Array[Dictionary] = [
	{"kind": "event_timeline", "from": 400, "to": 1600, "step": 200, "events": [[476, "Rome's west ends"],
		[1066, "Battle of Hastings"], [1215, "Magna Carta"], [1348, "The Black Death"], [1453, "Constantinople falls"]],
		"eras": [[410, 1066, "Anglo-Saxon England"], [1066, 1485, "Middle Ages"]], "mark": 1},
	{"kind": "event_timeline", "from": -800, "to": 800, "step": 200, "events": [[-776, "First Olympics"],
		[43, "Romans invade"], [793, "Lindisfarne"]], "hide": 2},
	{"kind": "event_timeline", "from": 1000, "to": 1100, "step": 10, "events": [[1066, "Hastings"]]},
	{"kind": "quipu", "cords": [3042, 105, 11, 7], "names": ["maize", "llamas", "houses", "wells"], "labels": true,
		"places": true},
	{"kind": "quipu", "cords": [0]},
	{"kind": "quipu", "cords": [9999, 1111, 2020, 808, 76], "places": true},
	{"kind": "feudal_pyramid"},
	{"kind": "feudal_pyramid", "arrows": true, "mark": "knights"},
	{"kind": "feudal_pyramid", "hide": "barons"},
	{"kind": "castle_type", "type": "motte_bailey", "labels": true},
	{"kind": "castle_type", "type": "stone_keep", "labels": true},
	{"kind": "castle_type", "type": "concentric", "labels": true},
	{"kind": "castle_type", "type": "stone_keep"},
	{"kind": "dot_density", "areas": [{"name": "Hilltown", "people": 12, "km2": 4}, {"name": "Riverside", "people": 60,
		"km2": 3}]},
	{"kind": "dot_density", "areas": [{"name": "A", "people": 0, "km2": 1}, {"name": "B", "people": 80, "km2": 9},
		{"name": "C", "people": 7, "km2": 5}], "each": 100},
	{"kind": "city_zones"},
	{"kind": "city_zones", "mark": "suburbs"},
	{"kind": "city_zones", "hide": "cbd", "labels": true},
	{"kind": "city_zones", "labels": false},
	{"kind": "os_map", "e0": 32, "n0": 60, "cols": 5, "rows": 4, "hills": [{"e": 344, "n": 624, "heights": [50, 100,
		150, 200], "top": 212, "size": 12, "steep": "e"}], "river": [[320, 604], [330, 610], [337, 603], [352, 612],
		[370, 606]], "symbols": [{"what": "worship", "e": 325, "n": 618}, {"what": "school", "e": 356, "n": 632},
		{"what": "farm", "e": 362, "n": 618}, {"what": "car_park", "e": 331, "n": 635}, {"what": "campsite", "e": 348,
		"n": 606}, {"what": "viewpoint", "e": 344, "n": 624}, {"what": "castle", "e": 364, "n": 636}, {"what": "bridge",
		"e": 337, "n": 603}], "points": [{"e": 324, "n": 617, "label": "A"}, {"e": 351, "n": 629, "label": "B"}],
		"km": true},
	{"kind": "os_map", "e0": 0, "n0": 97, "cols": 2, "rows": 2},
	{"kind": "os_map", "e0": 93, "n0": 94, "cols": 6, "rows": 5, "hills": [{"e": 950, "n": 960, "heights": [10]},
		{"e": 975, "n": 975, "heights": [100, 150], "steep": "w", "size": 3}]},
	{"kind": "climograph", "name": "London", "temp": [5, 5, 7, 9, 13, 16, 18, 18, 15, 12, 8, 6], "rain": [55, 40, 42,
		44, 49, 45, 45, 50, 49, 69, 59, 55], "t_top": 30, "t_step": 5, "r_top": 300, "r_step": 50, "mark": 6},
	{"kind": "climograph", "temp": [-10, -8, -2, 6, 13, 17, 19, 17, 11, 5, -2, -7], "rain": [40, 35, 35, 40, 55, 80,
		90, 80, 65, 60, 50, 45], "t_from": -20, "t_top": 30, "t_step": 10, "r_top": 250, "r_step": 50},
	{"kind": "climograph", "name": "Mumbai", "temp": [24, 25, 27, 29, 30, 29, 28, 27, 28, 29, 28, 26], "rain": [0, 0,
		0, 0, 20, 500, 600, 450, 300, 60, 10, 0], "t_top": 40, "t_step": 5, "r_top": 800, "r_step": 100},
	{"kind": "river_course", "view": "long", "labels": true},
	{"kind": "river_course", "view": "long", "labels": true, "mark": "waterfall", "hide": "floodplain"},
	{"kind": "river_course", "view": "plan", "labels": true},
	{"kind": "river_course", "view": "plan"},
	{"kind": "river_course", "view": "meander", "labels": true, "hide": "deposition"},
	{"kind": "river_course", "view": "waterfall", "labels": true, "mark": "plunge pool"},
	{"kind": "layer_map", "w": 8, "h": 5, "layers": [
		{"name": "river", "what": "water", "cells": ["...##...", "...##...", "..##....", ".##.....", "##......"]},
		{"name": "flood zone", "what": "flood", "cells": ["..####..", "..####..", ".####...", "####....", "###....."]},
		{"name": "houses", "what": "houses", "cells": [".#....#.", "......##", "....#...", "#....#..", "..#....#"]},
		{"name": "schools", "what": "schools", "cells": ["........", "#.......", "........", "......#.", "........"]}]},
	{"kind": "layer_map", "w": 6, "h": 4, "view": "stack", "layers": [
		{"name": "roads", "what": "road", "cells": ["######", "..#...", "..#...", "..#..."]},
		{"name": "parks", "what": "trees", "cells": ["......", "##....", "##..##", "....##"]},
		{"name": "shops", "what": "shops", "cells": ["......", "...#..", ".....#", "......"]},
		{"name": "bus stops", "what": "bus_stops", "cells": [".#..#.", "......", "......", "...#.."]}]},
	{"kind": "savings_growth", "start": 1000, "rate": 10, "years": 3, "values": true},
	{"kind": "savings_growth", "start": 500, "rate": 5, "years": 6, "simple": true, "values": true},
	{"kind": "savings_growth", "start": 1, "rate": 50, "years": 1},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(480, 280), Vector2(248, 126)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_kind_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureG6Hum.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)
	for view: String in SchoolPictureG6Hum.VIEWS:
		assert_true(SAMPLES.any(func(d: Dictionary) -> bool: return str(d.get("view", "")) == view), "a %s river" % view)
	for type: String in SchoolPictureG6Hum.CASTLES:
		assert_true(SAMPLES.any(func(d: Dictionary) -> bool: return str(d.get("type", "")) == type), "a %s castle" % type)


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
			{"kind": "event_timeline", "from": 1000, "to": 900, "step": 10, "events": [[950, "x"]]},
			{"kind": "event_timeline", "from": 1000, "to": 1100, "step": 30, "events": [[1050, "x"]]},
			{"kind": "event_timeline", "from": 1000, "to": 1100, "step": 5, "events": [[1050, "x"]]},
			{"kind": "event_timeline", "from": 1000, "to": 1100, "step": 10, "events": []},
			{"kind": "event_timeline", "from": 1000, "to": 1100, "step": 10, "events": [[1200, "x"]]},
			{"kind": "event_timeline", "from": -100, "to": 100, "step": 50, "events": [[0, "year 0"]]},
			{"kind": "event_timeline", "from": 1000, "to": 1100, "step": 10, "events": [[1050, "a label far too long here"]]},
			{"kind": "event_timeline", "from": 1000, "to": 1100, "step": 10, "events": [[1050, "x"]], "mark": 1},
			{"kind": "event_timeline", "from": 1000, "to": 1100, "step": 10, "events": [[1050, "x"]],
				"eras": [[1000, 1200, "too far"]]},
			{"kind": "event_timeline", "from": 0, "to": 5000, "step": 500, "events": [[1050, "x"]]},
			{"kind": "quipu", "cords": []}, {"kind": "quipu", "cords": [10000]}, {"kind": "quipu", "cords": [1.5]},
			{"kind": "quipu", "cords": [1, 2, 3, 4, 5, 6]}, {"kind": "quipu", "cords": [1, 2], "names": ["one"]},
			{"kind": "quipu", "cords": [1], "labels": "yes"},
			{"kind": "feudal_pyramid", "mark": "queen"}, {"kind": "feudal_pyramid", "arrows": 1},
			{"kind": "castle_type"}, {"kind": "castle_type", "type": "palace"},
			{"kind": "dot_density", "areas": []}, {"kind": "dot_density", "areas": [{"name": "A", "people": 81, "km2": 1}]},
			{"kind": "dot_density", "areas": [{"name": "A", "people": 5, "km2": 10}]},
			{"kind": "dot_density", "areas": [{"people": 5, "km2": 1}]},
			{"kind": "dot_density", "areas": [{"name": "A", "people": 5, "km2": 1}], "each": 0},
			{"kind": "city_zones", "mark": "harbour"}, {"kind": "city_zones", "labels": "no"},
			{"kind": "os_map", "e0": 32, "n0": 60, "cols": 7, "rows": 4},
			{"kind": "os_map", "e0": 32, "n0": 60, "cols": 5, "rows": 1},
			{"kind": "os_map", "e0": 95, "n0": 60, "cols": 5, "rows": 4},
			{"kind": "os_map", "e0": 32, "n0": 60, "cols": 5, "rows": 4, "points": [{"e": 380, "n": 617, "label": "A"}]},
			{"kind": "os_map", "e0": 32, "n0": 60, "cols": 5, "rows": 4, "points": [{"e": 324, "n": 617, "label": "ABCD"}]},
			{"kind": "os_map", "e0": 32, "n0": 60, "cols": 5, "rows": 4, "hills": [{"e": 340, "n": 620, "heights": [100, 50]}]},
			{"kind": "os_map", "e0": 32, "n0": 60, "cols": 5, "rows": 4, "hills": [{"e": 340, "n": 620, "heights": [50],
				"top": 40}]},
			{"kind": "os_map", "e0": 32, "n0": 60, "cols": 5, "rows": 4, "hills": [{"e": 340, "n": 620, "heights": [50],
				"steep": "up"}]},
			{"kind": "os_map", "e0": 32, "n0": 60, "cols": 5, "rows": 4, "river": [[330, 610]]},
			{"kind": "os_map", "e0": 32, "n0": 60, "cols": 5, "rows": 4, "symbols": [{"what": "pub", "e": 330, "n": 610}]},
			{"kind": "climograph", "temp": [1, 2, 3], "rain": [1, 2, 3], "t_top": 30, "t_step": 5, "r_top": 300, "r_step": 50},
			{"kind": "climograph", "temp": [5, 5, 7, 9, 13, 16, 18, 18, 15, 12, 8, 6], "rain": [55, 40, 42, 44, 49, 45, 45,
				50, 49, 69, 59, 55], "t_top": 30, "t_step": 5, "r_top": 300, "r_step": 100},
			{"kind": "climograph", "temp": [5, 5, 7, 9, 13, 16, 18, 18, 15, 12, 8, 36], "rain": [55, 40, 42, 44, 49, 45, 45,
				50, 49, 69, 59, 55], "t_top": 30, "t_step": 5, "r_top": 300, "r_step": 50},
			{"kind": "climograph", "temp": [5, 5, 7, 9, 13, 16, 18, 18, 15, 12, 8, 6], "rain": [55, 40, 42, 44, 49, 45, 45,
				50, 49, 69, 59, 355], "t_top": 30, "t_step": 5, "r_top": 300, "r_step": 50},
			{"kind": "climograph", "temp": [5, 5, 7, 9, 13, 16, 18, 18, 15, 12, 8, 6], "rain": [55, 40, 42, 44, 49, 45, 45,
				50, 49, 69, 59, 55], "t_top": 30, "t_step": 5, "r_top": 300, "r_step": 50, "mark": 12},
			{"kind": "river_course", "view": "sideways"}, {"kind": "river_course", "view": "plan", "mark": "waterfall"},
			{"kind": "river_course", "view": "long", "labels": "yes"},
			{"kind": "layer_map", "w": 2, "h": 4, "layers": [{"name": "a", "what": "water", "cells": ["..", "..", "..", ".."]}]},
			{"kind": "layer_map", "w": 3, "h": 2, "layers": []},
			{"kind": "layer_map", "w": 3, "h": 2, "layers": [{"name": "a", "what": "lava", "cells": ["...", "..."]}]},
			{"kind": "layer_map", "w": 3, "h": 2, "layers": [{"name": "a", "what": "water", "cells": ["...", ".."]}]},
			{"kind": "layer_map", "w": 3, "h": 2, "layers": [{"name": "a", "what": "water", "cells": ["...", "..x"]}]},
			{"kind": "layer_map", "w": 3, "h": 2, "layers": [{"name": "a", "what": "water", "cells": ["..."]}]},
			{"kind": "layer_map", "w": 3, "h": 2, "view": "3d", "layers": [{"name": "a", "what": "water", "cells": ["...",
				"..."]}]},
			{"kind": "savings_growth", "start": 0, "rate": 5, "years": 2},
			{"kind": "savings_growth", "start": 100, "rate": 60, "years": 2},
			{"kind": "savings_growth", "start": 100, "rate": 5, "years": 7},
			{"kind": "savings_growth", "start": 100, "rate": 5, "years": 2, "simple": "yes"}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))


## A quipu's knots (Ascher's reading of Inca cords): a place's digit as that many single knots, except the ones place:
## a figure-of-eight knot for 1, a long knot of 2-9 turns; no knot for 0.
func test_a_quipus_knots() -> void:
	assert_eq(SchoolPictureG6Hum.quipu_digits(3042), [3, 0, 4, 2] as Array[int])
	assert_eq(SchoolPictureG6Hum.quipu_digits(7), [0, 0, 0, 7] as Array[int])
	assert_eq(SchoolPictureG6Hum.quipu_digits(9999), [9, 9, 9, 9] as Array[int])
	assert_eq(SchoolPictureG6Hum.knot_kind(0, true), "none")
	assert_eq(SchoolPictureG6Hum.knot_kind(0, false), "none")
	assert_eq(SchoolPictureG6Hum.knot_kind(1, true), "eight")
	assert_eq(SchoolPictureG6Hum.knot_kind(4, true), "long")
	assert_eq(SchoolPictureG6Hum.knot_kind(1, false), "single")
	assert_eq(SchoolPictureG6Hum.knot_kind(9, false), "single")


## Grid references: the easting first, then the northing ("along the corridor, then up the stairs"); a four-figure
## reference names the square by the lines at its bottom-left.
func test_grid_references() -> void:
	assert_eq(SchoolPictureG6Hum.six_figure(324, 617), "324617")
	assert_eq(SchoolPictureG6Hum.six_figure(40, 95), "040095")
	assert_eq(SchoolPictureG6Hum.four_figure(324, 617), "3261")
	assert_eq(SchoolPictureG6Hum.four_figure(330, 609), "3360")


## Compound interest adds each year's interest to the savings, so it earns interest too; simple interest does not.
func test_savings_grow() -> void:
	assert_almost_eq(SchoolPictureG6Hum.compound(1000, 10, 3), 1331.0, 0.001)
	assert_almost_eq(SchoolPictureG6Hum.compound(400, 5, 2), 441.0, 0.001)
	assert_almost_eq(SchoolPictureG6Hum.compound(500, 5, 0), 500.0, 0.001)
	assert_almost_eq(SchoolPictureG6Hum.simple(1000, 10, 3), 1300.0, 0.001)
	assert_gt(SchoolPictureG6Hum.compound(500, 5, 6), SchoolPictureG6Hum.simple(500, 5, 6))


func test_years_on_a_timeline() -> void:
	assert_eq(SchoolPictureG6Hum.year_text(-776), "776 BC")
	assert_eq(SchoolPictureG6Hum.year_text(43, true), "AD 43")
	assert_eq(SchoolPictureG6Hum.year_text(1066), "1066")
