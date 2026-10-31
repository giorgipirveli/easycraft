extends GutTest
## Owner #70 and #73, grade 7 history, geography and citizenship (research §6.7): the School draws their pictures from
## data (SchoolPictureG7Hum, inside SchoolPicture): a hand press and its mirrored type, voyages on the world's grid, a
## sailor measuring the Pole Star, the Columbian exchange, an Ottoman mosque's and a Mughal tomb's domes, a Mughal
## garden, the heavens with the Earth or the Sun in the middle and Jupiter's moons night by night, a royal family tree;
## plate boundaries, the rock cycle, a soil's layers, glaciated valleys, the coast (a headland, longshore drift, bays),
## an ecosystem's nutrient stores, a chain of steps; a business's break-even chart and a chart with a cut axis. Every
## sample draws at the School's picture sizes; broken data is a problem the content test finds; the rules the pictures
## draw by (mirrored type, the heavens' order, the rock cycle's turn, break-even, a cut axis's bars) are checked here.

const TUDORS := {"kind": "family_tree", "people": [
	{"name": "Henry VII", "years": "1485-1509", "row": 0, "col": 2},
	{"name": "Henry VIII", "years": "1509-1547", "row": 1, "col": 1},
	{"name": "Margaret", "row": 1, "col": 4},
	{"name": "Mary I", "years": "1553-1558", "row": 2, "col": 0},
	{"name": "Elizabeth I", "years": "1558-1603", "row": 2, "col": 1},
	{"name": "Edward VI", "years": "1547-1553", "row": 2, "col": 2},
	{"name": "James V", "row": 2, "col": 4},
	{"name": "Mary, Queen of Scots", "row": 3, "col": 4},
	{"name": "James I", "years": "1603-1625", "row": 4, "col": 4}],
	"links": [[0, 1], [0, 2], [1, 3], [1, 4], [1, 5], [2, 6], [6, 7], [7, 8]], "mark": 4}

const SAMPLES: Array[Dictionary] = [
	{"kind": "hand_press", "view": "press", "labels": true},
	{"kind": "hand_press", "view": "press", "labels": true, "mark": "platen", "hide": "screw"},
	{"kind": "hand_press", "view": "press"},
	{"kind": "hand_press", "view": "type", "word": "Books"},
	{"kind": "hand_press", "view": "type", "word": "bdpq", "print": false},
	{"kind": "hand_press", "view": "type", "word": "NEWS", "hide_print": true},
	{"kind": "voyage_map", "routes": [{"name": "Columbus 1492", "points": [[37, -7], [28, -16], [24, -74]]},
		{"name": "Zheng He", "points": [[32, 119], [13, 109], [2, 102], [11, 76], [27, 56], [-3, 40]]}],
		"places": [{"lat": 37, "long": -7, "label": "Palos"}, {"lat": 32, "long": 119, "label": "Nanjing"}]},
	{"kind": "voyage_map", "routes": [{"name": "Magellan", "points": [[37, -6], [-23, -43], [-53, -70], [13, 145],
		[10, 124], [-35, 20], [37, -6]]}], "lat_step": 30, "long_step": 60},
	{"kind": "voyage_map", "routes": [{"name": "Manila galleon", "points": [[15, 121], [17, -100]]}],
		"places": [{"lat": 15, "long": 121, "label": "Manila"}, {"lat": 17, "long": -100, "label": "Acapulco"}]},
	{"kind": "voyage_map", "places": [{"lat": -4, "long": 130, "label": "Banda"}]},
	{"kind": "voyage_map", "window": {"lat": [10, 45], "long": [25, 65]}, "lat_step": 10, "long_step": 15,
		"places": [{"lat": 30, "long": 31, "label": "Cairo"}, {"lat": 40, "long": 33, "label": "Ankara"},
		{"lat": 33, "long": 44, "label": "Baghdad"}, {"lat": 36, "long": 51, "label": "Tehran"},
		{"lat": 25, "long": 47, "label": "Riyadh"}, {"lat": 24, "long": 58, "label": "Muscat"}]},
	{"kind": "voyage_map", "window": {"lat": [40, 75], "long": [20, 180]}, "lat_step": 10, "long_step": 20,
		"routes": [{"name": "Trans-Siberian", "points": [[56, 38], [57, 61], [55, 83], [52, 104], [43, 132]]}],
		"places": [{"lat": 56, "long": 38, "label": "Moscow"}, {"lat": 43, "long": 132, "label": "Vladivostok"}]},
	{"kind": "pole_star", "angle": 52, "labels": true},
	{"kind": "pole_star", "angle": 12, "hide": true},
	{"kind": "pole_star", "angle": 85},
	{"kind": "columbian_exchange", "to_old": ["maize", "potatoes", "tomatoes", "cacao", "turkeys"],
		"to_new": ["wheat", "horses", "cattle", "sugar cane", "coffee", "smallpox"]},
	{"kind": "columbian_exchange", "to_old": ["potatoes"], "to_new": ["horses"], "hide": "horses"},
	{"kind": "dome_profile", "style": "ottoman", "labels": true},
	{"kind": "dome_profile", "style": "ottoman", "labels": true, "mark": "half-dome"},
	{"kind": "dome_profile", "style": "mughal", "labels": true, "hide": "chhatri"},
	{"kind": "dome_profile", "style": "mughal"},
	{"kind": "charbagh", "labels": true},
	{"kind": "charbagh", "labels": true, "mark": "pool", "hide": "tomb"},
	{"kind": "charbagh"},
	{"kind": "sky_model", "model": "earth", "labels": true},
	{"kind": "sky_model", "model": "sun", "labels": true, "mark": "Earth"},
	{"kind": "sky_model", "model": "sun", "hide": "Sun"},
	{"kind": "sky_model", "model": "jupiter", "nights": [[-3, 2, 5], [-6, -1, 3], [4], [-7, -2, 1, 6]]},
	{"kind": "sky_model", "model": "jupiter", "nights": [[]]},
	TUDORS,
	{"kind": "family_tree", "people": [{"name": "Babur", "years": "1526-1530", "row": 0, "col": 0},
		{"name": "Humayun", "row": 1, "col": 0}], "links": [[0, 1]], "hide": 1},
	{"kind": "family_tree", "people": [{"name": "William III", "row": 0, "col": 0}, {"name": "Mary II", "row": 0,
		"col": 1}, {"name": "Anne", "row": 1, "col": 3}], "couples": [[0, 1]], "links": []},
	{"kind": "plate_section", "type": "divergent", "labels": true},
	{"kind": "plate_section", "type": "subduction", "labels": true, "mark": "trench"},
	{"kind": "plate_section", "type": "collision", "labels": true, "hide": "fold mountains"},
	{"kind": "plate_section", "type": "transform", "labels": true},
	{"kind": "plate_section", "type": "subduction"},
	{"kind": "rock_cycle"},
	{"kind": "rock_cycle", "mark": "sedimentary rock", "hide": "melting"},
	{"kind": "rock_cycle", "labels": false, "hide": "igneous rock"},
	{"kind": "soil_profile", "labels": true},
	{"kind": "soil_profile", "labels": true, "mark": "topsoil", "hide": "bedrock"},
	{"kind": "soil_profile"},
	{"kind": "glacial_valley", "view": "compare", "labels": true},
	{"kind": "glacial_valley", "view": "landforms", "labels": true},
	{"kind": "glacial_valley", "view": "landforms", "labels": true, "mark": "arete", "hide": "tarn"},
	{"kind": "glacial_valley", "view": "corrie", "labels": true},
	{"kind": "glacial_valley", "view": "corrie", "labels": true, "hide": "plucking"},
	{"kind": "coast_view", "view": "headland", "labels": true},
	{"kind": "coast_view", "view": "headland", "labels": true, "hide": "arch"},
	{"kind": "coast_view", "view": "drift", "labels": true},
	{"kind": "coast_view", "view": "drift", "labels": true, "mark": "backwash"},
	{"kind": "coast_view", "view": "bays", "labels": true},
	{"kind": "coast_view", "view": "bays"},
	{"kind": "nutrient_cycle", "stores": [5, 1, 1], "flows": [5, 5, 5], "name": "Tropical rainforest", "labels": true},
	{"kind": "nutrient_cycle", "stores": [3, 5, 2], "flows": [2, 1, 1], "name": "Taiga", "labels": true},
	{"kind": "nutrient_cycle", "stores": [1, 1, 5]},
	{"kind": "step_chain", "steps": ["rain", "reservoir", "treatment works", "pipes", "homes", "sewage works",
		"river"], "mark": 2},
	{"kind": "step_chain", "steps": ["question", "hypothesis", "experiment", "results", "conclusion"], "loop": true,
		"hide": 1, "title": "The scientific method"},
	{"kind": "step_chain", "steps": ["first reading", "second reading"]},
	{"kind": "break_even", "fixed": 60, "cost": 2, "price": 5, "max": 40, "point": true},
	{"kind": "break_even", "fixed": 1000, "cost": 0, "price": 25, "max": 100},
	{"kind": "break_even", "fixed": 90, "cost": 1.5, "price": 4.5, "max": 40, "point": true, "hide": true},
	{"kind": "cut_axis_bars", "bars": [["Oak", 52], ["River", 54]], "from": 50, "to": 55, "step": 1, "full": true},
	{"kind": "cut_axis_bars", "bars": [["2024", 480], ["2025", 500], ["2026", 510]], "from": 470, "to": 520, "step": 10,
		"title": "Visitors a day"},
	{"kind": "cut_axis_bars", "bars": [["A", 3], ["B", 9], ["C", 1], ["D", 6]], "from": 0, "to": 10, "step": 2},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(480, 280), Vector2(248, 126)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_kind_and_view_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureG7Hum.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)
	var has := func(kind: String, key: String, value: String) -> bool:
		return SAMPLES.any(func(d: Dictionary) -> bool: return d.kind == kind and str(d.get(key, "")) == value)
	for v: String in SchoolPictureG7Hum.PRESS_VIEWS:
		assert_true(has.call("hand_press", "view", v), "a %s press" % v)
	for s: String in SchoolPictureG7Hum.DOME_STYLES:
		assert_true(has.call("dome_profile", "style", s), "an %s dome" % s)
	for m: String in SchoolPictureG7Hum.SKY_MODELS:
		assert_true(has.call("sky_model", "model", m), "a %s sky" % m)
	for t: String in SchoolPictureG7Hum.PLATE_TYPES:
		assert_true(has.call("plate_section", "type", t), "a %s boundary" % t)
	for v: String in SchoolPictureG7Hum.GLACIER_VIEWS:
		assert_true(has.call("glacial_valley", "view", v), "a %s glacier" % v)
	for v: String in SchoolPictureG7Hum.COAST_VIEWS:
		assert_true(has.call("coast_view", "view", v), "a %s coast" % v)


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
			{"kind": "hand_press"}, {"kind": "hand_press", "view": "side"},
			{"kind": "hand_press", "view": "press", "mark": "wheel"}, {"kind": "hand_press", "view": "press", "labels": 1},
			{"kind": "hand_press", "view": "type"}, {"kind": "hand_press", "view": "type", "word": "far too long"},
			{"kind": "hand_press", "view": "type", "word": "a b"}, {"kind": "hand_press", "view": "type", "word": "12"},
			{"kind": "voyage_map", "routes": [{"name": "x", "points": [[37, -7]]}]},
			{"kind": "voyage_map", "routes": [{"name": "x", "points": [[95, 0], [0, 0]]}]},
			{"kind": "voyage_map", "routes": [{"name": "x", "points": [[0, 190], [0, 0]]}]},
			{"kind": "voyage_map", "routes": [{"points": [[0, 10], [0, 0]]}]},
			{"kind": "voyage_map", "routes": [{"name": "a", "points": [[0, 1], [0, 0]]}, {"name": "b", "points": [[0, 1],
				[0, 0]]}, {"name": "c", "points": [[0, 1], [0, 0]]}, {"name": "d", "points": [[0, 1], [0, 0]]},
				{"name": "e", "points": [[0, 1], [0, 0]]}]},
			{"kind": "voyage_map", "places": [{"lat": 0, "long": 0, "label": "a name far too long"}]},
			{"kind": "voyage_map", "lat_step": 7},
			{"kind": "voyage_map", "window": {"lat": [10, 45]}},
			{"kind": "voyage_map", "window": {"lat": [45, 10], "long": [25, 65]}},
			{"kind": "voyage_map", "window": {"lat": [10, 15], "long": [25, 65]}},
			{"kind": "voyage_map", "window": {"lat": [10, 45], "long": [25, 65]}, "places": [{"lat": 5, "long": 30,
				"label": "Outside"}]},
			{"kind": "voyage_map", "window": {"lat": [10, 45], "long": [25, 65]}, "routes": [{"name": "x",
				"points": [[20, 30], [20, 70]]}]},
			{"kind": "pole_star"}, {"kind": "pole_star", "angle": 95}, {"kind": "pole_star", "angle": 2},
			{"kind": "pole_star", "angle": 45.5}, {"kind": "pole_star", "angle": 45, "hide": "yes"},
			{"kind": "columbian_exchange", "to_old": [], "to_new": ["horses"]},
			{"kind": "columbian_exchange", "to_old": ["a", "b", "c", "d", "e", "f", "g"], "to_new": ["horses"]},
			{"kind": "columbian_exchange", "to_old": ["potatoes"], "to_new": ["horses"], "hide": "cats"},
			{"kind": "columbian_exchange", "to_old": ["a word much too long for it"], "to_new": ["horses"]},
			{"kind": "dome_profile", "style": "gothic"}, {"kind": "dome_profile", "style": "mughal", "mark": "half-dome"},
			{"kind": "charbagh", "hide": "fountain"}, {"kind": "charbagh", "labels": "yes"},
			{"kind": "sky_model", "model": "mars"}, {"kind": "sky_model", "model": "sun", "mark": "Pluto"},
			{"kind": "sky_model", "model": "jupiter"}, {"kind": "sky_model", "model": "jupiter", "nights": [[0]]},
			{"kind": "sky_model", "model": "jupiter", "nights": [[1, 2, 3, 4, 5]]},
			{"kind": "sky_model", "model": "jupiter", "nights": [[9]]},
			{"kind": "sky_model", "model": "jupiter", "nights": [[1], [2], [3], [4], [5]]},
			{"kind": "family_tree", "people": [{"name": "A", "row": 0, "col": 0}], "links": []},
			{"kind": "family_tree", "people": [{"name": "A", "row": 0, "col": 0}, {"name": "B", "row": 5, "col": 0}],
				"links": []},
			{"kind": "family_tree", "people": [{"name": "A", "row": 0, "col": 0}, {"name": "B", "row": 1, "col": 0}],
				"links": [[0, 2]]},
			{"kind": "family_tree", "people": [{"name": "A", "row": 0, "col": 0}, {"name": "B", "row": 0, "col": 0}],
				"links": []},
			{"kind": "family_tree", "people": [{"name": "A name that is too long", "row": 0, "col": 0}, {"name": "B",
				"row": 1, "col": 0}], "links": []},
			{"kind": "family_tree", "people": [{"name": "A", "row": 0, "col": 0}, {"name": "B", "row": 1, "col": 0}],
				"links": [[1, 0]]},
			{"kind": "plate_section", "type": "hotspot"}, {"kind": "plate_section", "type": "transform", "mark": "volcano"},
			{"kind": "rock_cycle", "mark": "granite"}, {"kind": "rock_cycle", "labels": 0},
			{"kind": "soil_profile", "hide": "clay"},
			{"kind": "glacial_valley", "view": "cave"}, {"kind": "glacial_valley", "view": "compare", "mark": "tarn"},
			{"kind": "coast_view", "view": "cliff"}, {"kind": "coast_view", "view": "bays", "mark": "stack"},
			{"kind": "nutrient_cycle", "stores": [1, 2]}, {"kind": "nutrient_cycle", "stores": [0, 2, 3]},
			{"kind": "nutrient_cycle", "stores": [1, 2, 6]}, {"kind": "nutrient_cycle", "stores": [1, 2, 3],
				"flows": [1, 2]},
			{"kind": "step_chain", "steps": ["one"]}, {"kind": "step_chain", "steps": ["1", "2", "3", "4", "5", "6", "7",
				"8"]}, {"kind": "step_chain", "steps": ["a", "b"], "mark": 2},
			{"kind": "step_chain", "steps": ["a step name much too long to fit", "b"]},
			{"kind": "break_even", "fixed": 60, "cost": 5, "price": 5, "max": 40},
			{"kind": "break_even", "fixed": 600, "cost": 2, "price": 5, "max": 40},
			{"kind": "break_even", "fixed": 0, "cost": 2, "price": 5, "max": 40},
			{"kind": "break_even", "fixed": 60, "cost": 2, "price": 5, "max": 1},
			{"kind": "cut_axis_bars", "bars": [["A", 52]], "from": 50, "to": 55, "step": 1},
			{"kind": "cut_axis_bars", "bars": [["A", 52], ["B", 54]], "from": 53, "to": 55, "step": 1},
			{"kind": "cut_axis_bars", "bars": [["A", 52], ["B", 54]], "from": 50, "to": 53, "step": 1},
			{"kind": "cut_axis_bars", "bars": [["A", 52], ["B", 54]], "from": 50, "to": 55, "step": 2},
			{"kind": "cut_axis_bars", "bars": [["A", 52], ["B", 54]], "from": 0, "to": 55, "step": 1},
			{"kind": "cut_axis_bars", "bars": [["A", 52], ["B", 54]], "from": -5, "to": 55, "step": 5}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))


## Type is set as a mirror of the page: its letters run right to left, each one flipped.
func test_type_is_a_mirror() -> void:
	assert_eq(SchoolPictureG7Hum.type_order("CAT"), "TAC")
	assert_eq(SchoolPictureG7Hum.type_order("Books"), "skooB")
	assert_eq(SchoolPictureG7Hum.type_order("a"), "a")


## The heavens from the middle outwards: Ptolemy's (the Earth in the middle) and Copernicus's (the Sun in the middle).
func test_the_heavens_order() -> void:
	assert_eq(SchoolPictureG7Hum.bodies("earth"), ["Earth", "Moon", "Mercury", "Venus", "Sun", "Mars", "Jupiter",
		"Saturn"] as Array[String])
	assert_eq(SchoolPictureG7Hum.bodies("sun"), ["Sun", "Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn"]
		as Array[String])


## The rock cycle turns: magma cools into igneous rock, which is weathered and eroded into sediment, pressed and
## cemented into sedimentary rock, changed by heat and pressure into metamorphic rock, which melts into magma.
func test_the_rock_cycle_turns() -> void:
	assert_eq(SchoolPictureG7Hum.rock_next("magma"), "igneous rock")
	assert_eq(SchoolPictureG7Hum.rock_next("metamorphic rock"), "magma")
	assert_eq(SchoolPictureG7Hum.process_after("igneous rock"), "weathering and erosion")
	assert_eq(SchoolPictureG7Hum.process_after("sedimentary rock"), "heat and pressure")


## Break-even: the fixed costs shared over each item's profit (price − cost): 60 ÷ (5 − 2) = 20 items.
func test_break_even() -> void:
	assert_almost_eq(SchoolPictureG7Hum.break_even_items(60, 2, 5), 20.0, 0.0001)
	assert_almost_eq(SchoolPictureG7Hum.break_even_items(90, 1.5, 4.5), 30.0, 0.0001)
	assert_almost_eq(SchoolPictureG7Hum.break_even_items(1000, 0, 25), 40.0, 0.0001)


## A cut axis: each bar's height is its value above the axis's start, so 54 against 52 on an axis from 50 looks twice
## as tall.
func test_a_cut_axis_bars() -> void:
	assert_almost_eq(SchoolPictureG7Hum.bar_ratio(52, 54, 50), 2.0, 0.0001)
	assert_almost_eq(SchoolPictureG7Hum.bar_ratio(52, 54, 0), 54.0 / 52.0, 0.0001)
