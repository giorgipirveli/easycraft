extends GutTest
## Owner #70, #73 and #111, grade 8 history, geography and citizenship (research §6.8): the School draws their pictures
## from data (SchoolPictureG8Hum, inside SchoolPicture): a beam steam engine with Watt's separate condenser, the
## greenhouse effect (and a thicker blanket of gases), a scatter graph (income and life, risk and return), a population
## pyramid, the tourism area life cycle, the ocean's zones from the sunlit surface to the trenches, map projections
## (the globe, Mercator, equal-area, a compromise and an azimuthal map, with same-sized circles to show the stretch), a
## parliament's seats in a half-circle, a till receipt, and reasons weighed on a balance. Every sample draws at the
## School's picture sizes; broken data is a problem the content test finds; the rules the pictures draw by (Mercator's
## stretch, a majority, the ocean's zones, the cycle's stages, a receipt's total, the balance's tilt) are checked here.

const SAMPLES: Array[Dictionary] = [
	{"kind": "steam_engine", "labels": true},
	{"kind": "steam_engine", "labels": true, "mark": "condenser", "hide": "beam"},
	{"kind": "steam_engine"},
	{"kind": "greenhouse", "labels": true},
	{"kind": "greenhouse", "labels": true, "more": true, "mark": "greenhouse gases"},
	{"kind": "greenhouse", "hide": "heat kept in", "labels": true},
	{"kind": "greenhouse", "more": true},
	{"kind": "scatter_plot", "points": [[2, 58, "A"], [8, 66, "B"], [15, 72, "C"], [30, 78, "D"], [45, 82, "E"]],
		"x_name": "income (thousand gold)", "y_name": "life (years)", "x_to": 50, "x_step": 10, "y_from": 50, "y_to": 90,
		"y_step": 10, "line": true, "mark": 2},
	{"kind": "scatter_plot", "points": [[1, 1, "savings"], [2, 3, "bonds"], [4, 6, "shares"], [5, 8, "one company"]],
		"x_name": "risk", "y_name": "return (% a year)", "x_to": 5, "x_step": 1, "y_to": 10, "y_step": 2},
	{"kind": "scatter_plot", "points": [[10, 20], [20, 25], [30, 45], [40, 50], [50, 70], [60, 72], [70, 80], [80, 95],
		[90, 90], [5, 8], [65, 60], [35, 30]], "x_name": "x", "y_name": "y", "x_to": 100, "x_step": 20, "y_to": 100,
		"y_step": 25, "line": true},
	{"kind": "pop_pyramid", "bands": [["0-14", 21, 20], ["15-29", 14, 14], ["30-44", 9, 9], ["45-59", 5, 5],
		["60-74", 1.5, 1.5], ["75+", 0, 0]], "top": 25, "step": 5, "title": "Stage 2: many children"},
	{"kind": "pop_pyramid", "bands": [["0-14", 7, 7], ["15-29", 8, 8], ["30-44", 9, 9], ["45-59", 9, 9],
		["60-74", 8, 8], ["75+", 5, 7]], "top": 10, "step": 2, "mark": 5, "left_name": "males",
		"right_name": "females"},
	{"kind": "pop_pyramid", "bands": [["0-9", 10, 10], ["10-19", 9, 9], ["20+", 26, 36]], "top": 40, "step": 10},
	{"kind": "tourism_cycle", "labels": true},
	{"kind": "tourism_cycle", "labels": true, "mark": "development", "hide": "stagnation", "paths": true},
	{"kind": "tourism_cycle", "paths": true},
	{"kind": "ocean_zones", "labels": true, "depths": true, "life": true},
	{"kind": "ocean_zones", "labels": true, "mark": "twilight zone", "hide": "abyss"},
	{"kind": "ocean_zones", "life": true},
	{"kind": "projection", "view": "globe", "circles": true},
	{"kind": "projection", "view": "mercator", "circles": true, "mark": 60},
	{"kind": "projection", "view": "equal_area", "circles": true},
	{"kind": "projection", "view": "compromise", "circles": true},
	{"kind": "projection", "view": "azimuthal", "circles": true, "mark": 30},
	{"kind": "projection", "view": "mercator"},
	{"kind": "parliament_seats", "groups": [["Group A", 330], ["Group B", 200], ["Group C", 70], ["Others", 50]],
		"majority": true, "title": "650 seats"},
	{"kind": "parliament_seats", "groups": [["Red", 40], ["Blue", 35], ["Green", 25]], "mark": 0},
	{"kind": "parliament_seats", "groups": [["Yes", 1], ["No", 1]]},
	{"kind": "receipt", "shop": "Village Store", "lines": [["headphones", 30], ["case", 4.5], ["cable", 2.25]],
		"date": "3 May", "total": true, "paid": "card", "note": "Keep this for returns"},
	{"kind": "receipt", "shop": "Market", "lines": [["bread", 2]], "mark": 0},
	{"kind": "receipt", "shop": "The Big Village Shop", "lines": [["a", 1], ["b", 2], ["c", 3], ["d", 4],
		["e", 5], ["f", 6]], "total": true, "hide_total": true},
	{"kind": "balance_scale", "left": ["finds lost children fast", "no passes to lose"], "right":
		["faces are private data", "it can make mistakes", "who keeps the pictures?"], "left_name": "for",
		"right_name": "against", "title": "Face cameras at school?"},
	{"kind": "balance_scale", "left": ["equal pay"], "right": [], "left_name": "fair", "right_name": "unfair",
		"tilt": "level"},
	{"kind": "balance_scale", "left": ["a", "b", "c", "d"], "right": ["e"], "left_name": "yes", "right_name": "no",
		"weights": [[1, 1, 1, 1], [5]]},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(480, 280), Vector2(248, 126)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_kind_and_view_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureG8Hum.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)
	for v: String in SchoolPictureG8Hum.PROJECTIONS:
		assert_true(SAMPLES.any(func(d: Dictionary) -> bool: return d.kind == "projection" and str(d.get("view")) == v),
			"a %s projection" % v)


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
			{"kind": "steam_engine", "mark": "wheel"}, {"kind": "steam_engine", "labels": 1},
			{"kind": "greenhouse", "hide": "Moon"}, {"kind": "greenhouse", "more": "yes"},
			{"kind": "scatter_plot", "points": [[1, 1]], "x_name": "x", "y_name": "y", "x_to": 5, "x_step": 1, "y_to": 5,
				"y_step": 1},
			{"kind": "scatter_plot", "points": [[1, 1], [9, 2]], "x_name": "x", "y_name": "y", "x_to": 5, "x_step": 1,
				"y_to": 5, "y_step": 1},
			{"kind": "scatter_plot", "points": [[1, 1], [2, 2]], "x_name": "x", "y_name": "y", "x_to": 5, "x_step": 2,
				"y_to": 5, "y_step": 1},
			{"kind": "scatter_plot", "points": [[1, 1], [2, 2]], "x_name": "a name much too long for the axis",
				"y_name": "y", "x_to": 5, "x_step": 1, "y_to": 5, "y_step": 1},
			{"kind": "scatter_plot", "points": [[1, 1, "a label too long"], [2, 2]], "x_name": "x", "y_name": "y",
				"x_to": 5, "x_step": 1, "y_to": 5, "y_step": 1},
			{"kind": "scatter_plot", "points": [[1, 1], [2, 2]], "x_name": "x", "y_name": "y", "x_to": 5, "x_step": 1,
				"y_to": 5, "y_step": 1, "mark": 2},
			{"kind": "pop_pyramid", "bands": [["0-14", 5, 5], ["15+", 5, 5]], "top": 10, "step": 5},
			{"kind": "pop_pyramid", "bands": [["0-14", 12, 5], ["15-29", 5, 5], ["30+", 5, 5]], "top": 10, "step": 5},
			{"kind": "pop_pyramid", "bands": [["0-14", 5, 5], ["15-29", -1, 5], ["30+", 5, 5]], "top": 10, "step": 5},
			{"kind": "pop_pyramid", "bands": [["0-14", 5, 5], ["15-29", 5, 5], ["30+", 5, 5]], "top": 10, "step": 3},
			{"kind": "tourism_cycle", "mark": "boom"}, {"kind": "tourism_cycle", "paths": 2},
			{"kind": "ocean_zones", "hide": "the deep"}, {"kind": "ocean_zones", "life": "fish"},
			{"kind": "projection", "view": "flat"}, {"kind": "projection", "view": "mercator", "mark": 85},
			{"kind": "projection", "view": "mercator", "mark": 45.5}, {"kind": "projection"},
			{"kind": "parliament_seats", "groups": [["A", 0]]},
			{"kind": "parliament_seats", "groups": [["A", 500], ["B", 300]]},
			{"kind": "parliament_seats", "groups": [["A name too long", 3], ["B", 3]]},
			{"kind": "parliament_seats", "groups": [["A", 2], ["B", 3]], "mark": 2},
			{"kind": "receipt", "shop": "Shop", "lines": []},
			{"kind": "receipt", "shop": "Shop", "lines": [["a very long item name", 3]]},
			{"kind": "receipt", "shop": "Shop", "lines": [["bread", -2]]},
			{"kind": "receipt", "lines": [["bread", 2]]},
			{"kind": "receipt", "shop": "Shop", "lines": [["a", 1], ["b", 1], ["c", 1], ["d", 1], ["e", 1], ["f", 1],
				["g", 1]]},
			{"kind": "balance_scale", "left": ["a"], "right": ["b"], "left_name": "for"},
			{"kind": "balance_scale", "left": ["a", "b", "c", "d", "e"], "right": [], "left_name": "for",
				"right_name": "against"},
			{"kind": "balance_scale", "left": ["a reason much too long for its little box"], "right": [],
				"left_name": "for", "right_name": "against"},
			{"kind": "balance_scale", "left": ["a"], "right": ["b"], "left_name": "for", "right_name": "against",
				"tilt": "up"},
			{"kind": "balance_scale", "left": ["a"], "right": ["b"], "left_name": "for", "right_name": "against",
				"weights": [[1, 2], [1]]}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))


## Mercator stretches every length by 1 ÷ cos(latitude): twice at 60°, so an area there looks 4 times its true size.
func test_mercator_stretch() -> void:
	assert_almost_eq(SchoolPictureG8Hum.stretch(0.0), 1.0, 0.0001)
	assert_almost_eq(SchoolPictureG8Hum.stretch(60.0), 2.0, 0.0001)
	assert_almost_eq(SchoolPictureG8Hum.stretch(75.5225), 4.0, 0.001)
	assert_almost_eq(SchoolPictureG8Hum.mercator_y(0.0), 0.0, 0.0001)
	assert_gt(SchoolPictureG8Hum.mercator_y(80.0) - SchoolPictureG8Hum.mercator_y(70.0),
		SchoolPictureG8Hum.mercator_y(20.0) - SchoolPictureG8Hum.mercator_y(10.0), "the lines spread out towards the poles")


## A majority is more than half of the seats.
func test_a_majority() -> void:
	assert_eq(SchoolPictureG8Hum.majority(650), 326)
	assert_eq(SchoolPictureG8Hum.majority(100), 51)
	assert_eq(SchoolPictureG8Hum.majority(99), 50)


## The ocean's zones by depth: sunlight to 200 m, twilight to 1,000 m, midnight to 4,000 m, the abyss to 6,000 m, then
## the trenches.
func test_the_oceans_zones() -> void:
	assert_eq(SchoolPictureG8Hum.zone_at(50), "sunlight zone")
	assert_eq(SchoolPictureG8Hum.zone_at(500), "twilight zone")
	assert_eq(SchoolPictureG8Hum.zone_at(2500), "midnight zone")
	assert_eq(SchoolPictureG8Hum.zone_at(5000), "abyss")
	assert_eq(SchoolPictureG8Hum.zone_at(10900), "trenches")


## Butler's tourism area life cycle, in order.
func test_the_tourism_cycle() -> void:
	assert_eq(SchoolPictureG8Hum.stage_after("exploration"), "involvement")
	assert_eq(SchoolPictureG8Hum.stage_after("consolidation"), "stagnation")
	assert_eq(SchoolPictureG8Hum.stage_after("stagnation"), "")


func test_a_receipts_total() -> void:
	assert_almost_eq(SchoolPictureG8Hum.receipt_total([["headphones", 30], ["case", 4.5], ["cable", 2.25]]), 36.75, 0.0001)


## The balance tips towards the heavier side: each reason weighs 1 unless `weights` says otherwise.
func test_the_balance_tilts() -> void:
	assert_eq(SchoolPictureG8Hum.tilt({"left": ["a", "b"], "right": ["c"]}), "left")
	assert_eq(SchoolPictureG8Hum.tilt({"left": ["a"], "right": ["c"]}), "level")
	assert_eq(SchoolPictureG8Hum.tilt({"left": ["a", "b"], "right": ["c"], "weights": [[1, 1], [3]]}), "right")
	assert_eq(SchoolPictureG8Hum.tilt({"left": ["a", "b"], "right": ["c"], "tilt": "level"}), "level")
