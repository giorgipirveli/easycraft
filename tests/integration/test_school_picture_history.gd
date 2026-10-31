extends GutTest
## Owner #70 and #73, grade 4 history ("How ancient people counted", research §6.4): the School draws the first
## civilisations' numbers from data (SchoolPictureHistory, inside SchoolPicture): Egyptian hieroglyph numbers (strokes,
## heel bones, coils of rope and lotus flowers, each drawn as many times as needed) and Babylonian cuneiform (upright
## wedges for ones and corner wedges for tens, in places of sixties). Grade 5 (research §6.5) adds Maya numbers (dots,
## bars and a shell for zero, in places of twenties, the biggest on top) and the world's grid of latitude and longitude
## (the Equator, the Prime Meridian, the Tropics and polar circles, places, night, hours from Greenwich, climate bands).
## Every sample draws at the School's picture sizes; broken data is a problem the content test finds.

const SAMPLES: Array[Dictionary] = [
	{"kind": "numerals", "system": "egypt", "value": 1111, "labels": true},
	{"kind": "numerals", "system": "egypt", "value": 342},
	{"kind": "numerals", "system": "egypt", "value": 9999},
	{"kind": "numerals", "system": "egypt", "value": 305, "labels": true},
	{"kind": "numerals", "system": "egypt", "value": 1},
	{"kind": "numerals", "system": "babylon", "value": 23},
	{"kind": "numerals", "system": "babylon", "value": 125, "labels": true},
	{"kind": "numerals", "system": "babylon", "value": 3599},
	{"kind": "numerals", "system": "babylon", "value": 59, "labels": true},
	{"kind": "numerals", "system": "maya", "value": 0},
	{"kind": "numerals", "system": "maya", "value": 19},
	{"kind": "numerals", "system": "maya", "value": 20, "labels": true},
	{"kind": "numerals", "system": "maya", "value": 425, "labels": true},
	{"kind": "numerals", "system": "maya", "value": 7999},
	{"kind": "latlong"},
	{"kind": "latlong", "lines": ["tropics", "polar"], "points": [{"lat": 51.5, "long": 0, "label": "London"},
		{"lat": -33, "long": 151, "label": "S"}, {"lat": 0, "long": -78.5, "label": "Quito"}]},
	{"kind": "latlong", "lat_step": 15, "long_step": 15, "hours": true, "night": 180},
	{"kind": "latlong", "lines": ["tropics", "polar"], "bands": true, "lat_step": 30, "long_step": 60},
	{"kind": "latlong", "lat_step": 10, "long_step": 20, "points": [{"lat": -90, "long": -180, "label": "A"},
		{"lat": 90, "long": 180, "label": "B"}], "night": -45},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(248, 126)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_history_kind_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureHistory.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)


func test_no_kind_is_another_grades() -> void:
	for k: String in SchoolPictureHistory.KINDS:
		assert_false(SchoolPicture.KINDS.has(k) or SchoolPictureG5.KINDS.has(k) or SchoolPictureG3.KINDS.has(k)
			or SchoolPicture.SCIENCE_KINDS.has(k), k)


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
			{"kind": "numerals", "system": "roman", "value": 12}, {"kind": "numerals", "system": "egypt", "value": 0},
			{"kind": "numerals", "system": "egypt", "value": 10000}, {"kind": "numerals", "system": "egypt"},
			{"kind": "numerals", "system": "babylon", "value": 120},   # an empty ones place: the Babylonians left a gap
			{"kind": "numerals", "system": "babylon", "value": 3600}, {"kind": "numerals", "system": "babylon", "value": -5},
			{"kind": "numerals", "system": "egypt", "value": "12"},
			{"kind": "numerals", "system": "maya", "value": 8000}, {"kind": "numerals", "system": "maya", "value": -1},
			{"kind": "numerals", "system": "maya", "value": 2.5},
			{"kind": "latlong", "lat_step": 7}, {"kind": "latlong", "long_step": 0}, {"kind": "latlong", "lines": ["rivers"]},
			{"kind": "latlong", "lines": "tropics"}, {"kind": "latlong", "points": [{"lat": 95, "long": 0, "label": "A"}]},
			{"kind": "latlong", "points": [{"lat": 10, "long": -200, "label": "A"}]},
			{"kind": "latlong", "points": [{"lat": 10, "long": 20}]},
			{"kind": "latlong", "points": [{"lat": 10, "long": 20, "label": "a much too long name"}]},
			{"kind": "latlong", "points": "London"}, {"kind": "latlong", "night": 270},
			{"kind": "latlong", "hours": true, "long_step": 45}, {"kind": "latlong", "bands": "yes"}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))


## The signs an Egyptian number needs: one of a sign for each of its digit's worth (the thousands' digit lotus flowers,
## and so on), biggest first; a Babylonian number's places are sixties and ones, each a count of tens and ones.
func test_the_signs_of_a_number() -> void:
	assert_eq(SchoolPictureHistory.egypt_groups(3042), [[1000, 3], [10, 4], [1, 2]])
	assert_eq(SchoolPictureHistory.egypt_groups(1111), [[1000, 1], [100, 1], [10, 1], [1, 1]])
	assert_eq(SchoolPictureHistory.babylon_places(125), [[0, 2], [0, 5]])
	assert_eq(SchoolPictureHistory.babylon_places(23), [[2, 3]])
	assert_eq(SchoolPictureHistory.babylon_places(3599), [[5, 9], [5, 9]])
	assert_eq(SchoolPictureHistory.babylon_places(754), [[1, 2], [3, 4]])


## A Maya number's places, the biggest first (400s, 20s, ones): each a digit 0-19, written as bars of 5 under dots of 1,
## and a shell for 0.
func test_the_places_and_marks_of_a_maya_number() -> void:
	assert_eq(SchoolPictureHistory.maya_places(0), [0])
	assert_eq(SchoolPictureHistory.maya_places(19), [19])
	assert_eq(SchoolPictureHistory.maya_places(20), [1, 0])
	assert_eq(SchoolPictureHistory.maya_places(425), [1, 1, 5])
	assert_eq(SchoolPictureHistory.maya_places(360), [18, 0])
	assert_eq(SchoolPictureHistory.maya_places(7999), [19, 19, 19])
	assert_eq(SchoolPictureHistory.maya_places(800), [2, 0, 0])
	assert_eq(SchoolPictureHistory.maya_marks(0), [0, 0], "a shell: no bars, no dots")
	assert_eq(SchoolPictureHistory.maya_marks(19), [3, 4], "3 bars and 4 dots")
	assert_eq(SchoolPictureHistory.maya_marks(5), [1, 0])
	assert_eq(SchoolPictureHistory.maya_marks(7), [1, 2])
	assert_eq(SchoolPictureHistory.maya_marks(4), [0, 4])


## Latitude and longitude as the lessons write them: 30°N, 0°, 45°S; 60°E, 0°, 120°W; hours from Greenwich: 15° is 1 hour.
func test_the_grids_words() -> void:
	assert_eq(SchoolPictureHistory.lat_text(30), "30°N")
	assert_eq(SchoolPictureHistory.lat_text(0), "0°")
	assert_eq(SchoolPictureHistory.lat_text(-45), "45°S")
	assert_eq(SchoolPictureHistory.long_text(60), "60°E")
	assert_eq(SchoolPictureHistory.long_text(-120), "120°W")
	assert_eq(SchoolPictureHistory.long_text(180), "180°")
	assert_eq(SchoolPictureHistory.hour_text(-75), "−5")
	assert_eq(SchoolPictureHistory.hour_text(0), "0")
	assert_eq(SchoolPictureHistory.hour_text(135), "+9")
