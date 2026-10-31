extends GutTest
## Prospecting (spec §26.2): the surveys' maths a quest asks a child to do, worked out by hand here.
## - The echo survey (oil): sound goes down to the dome and back up, so depth = speed × time ÷ 2.
## - The metal detector (gold, iron, copper): half the distance, twice the beeps (1 a second at 40 m).
## - The map: which way (8 compass points, north is -z as on MY MAP), how far (rounded as a map is read), which square.


func test_the_echo_survey() -> void:
	assert_eq(SurveyRules.ECHO_SPEED, 2000, "sound in the rock over the dome: 2,000 m a second (sandstone and shale: 2,000-4,000)")
	assert_almost_eq(SurveyRules.echo_seconds(1000), 1.0, 0.0001, "down 1,000 m and back up: 2,000 m, one second")
	assert_almost_eq(SurveyRules.echo_seconds(1500), 1.5, 0.0001)
	assert_almost_eq(SurveyRules.echo_seconds(3000), 3.0, 0.0001)
	assert_eq(SurveyRules.depth_from_echo(2.0), 2000)
	assert_eq(SurveyRules.depth_from_echo(2.5), 2500)
	for depth in DepositRules.OIL_DEPTHS:
		assert_eq(SurveyRules.depth_from_echo(SurveyRules.echo_seconds(depth)), depth, "there and back again: %d m" % depth)


func test_the_detector_beeps_faster_as_you_come_closer() -> void:
	assert_almost_eq(SurveyRules.beeps(40.0), 1.0, 0.001, "1 beep a second at 40 m")
	assert_almost_eq(SurveyRules.beeps(20.0), 2.0, 0.001, "half the distance: twice the beeps")
	assert_almost_eq(SurveyRules.beeps(10.0), 4.0, 0.001)
	assert_almost_eq(SurveyRules.beeps(5.0), 8.0, 0.001)
	assert_eq(SurveyRules.beeps(SurveyRules.DETECTOR_RANGE + 1.0), 0.0, "too far: silent")
	assert_eq(SurveyRules.beeps(0.0), SurveyRules.MAX_BEEPS, "right on it: as fast as it goes")
	assert_eq(SurveyRules.beeps(-3.0), SurveyRules.MAX_BEEPS)
	assert_eq(SurveyRules.beeps(INF), 0.0)


func test_compass_points_and_words() -> void:
	var from := Vector3(0, 0, 0)
	assert_eq(SurveyRules.point(from, Vector3(0, 0, -100)), "N", "north is -z (MY MAP's up)")
	assert_eq(SurveyRules.point(from, Vector3(100, 0, 0)), "E")
	assert_eq(SurveyRules.point(from, Vector3(0, 0, 100)), "S")
	assert_eq(SurveyRules.point(from, Vector3(-100, 0, 0)), "W")
	assert_eq(SurveyRules.point(from, Vector3(100, 0, -100)), "NE")
	assert_eq(SurveyRules.point(from, Vector3(-100, 0, 100)), "SW")
	assert_eq(SurveyRules.point(from, Vector3(30, 0, -100)), "N", "within 22.5° of north")
	assert_eq(SurveyRules.point_words("NE"), "north-east")
	assert_eq(SurveyRules.point_words("W"), "west")
	assert_eq(SurveyRules.POINTS.size(), 8)


func test_distances_are_read_like_a_map() -> void:
	assert_eq(SurveyRules.map_distance(Vector3.ZERO, Vector3(0, 0, 340)), 300, "to the nearest 100 m")
	assert_eq(SurveyRules.map_distance(Vector3.ZERO, Vector3(360, 5, 0)), 400)
	assert_eq(SurveyRules.map_distance(Vector3.ZERO, Vector3(30, 0, 0)), 100, "never less than one square")


func test_squares_on_the_map() -> void:
	# A map of 8 × 8 squares of 100 m; its north-west corner at (-400, -400): A1 is the top-left square.
	var corner := Vector2(-400, -400)
	assert_eq(SurveyRules.square(Vector3(-350, 0, -350), corner), "A1")
	assert_eq(SurveyRules.square(Vector3(-250, 0, -350), corner), "B1", "letters go east")
	assert_eq(SurveyRules.square(Vector3(-350, 0, -250), corner), "A2", "numbers go south")
	assert_eq(SurveyRules.square(Vector3(50, 0, 150), corner), "E6")
	assert_eq(SurveyRules.square(Vector3(399, 0, 399), corner), "H8")
	assert_eq(SurveyRules.square(Vector3(-450, 0, 0), corner), "", "off the map")


## A map round the camp and the target: 8 squares a side, both inside, the camp near the middle when it can be.
func test_a_map_fits_the_camp_and_the_target() -> void:
	for target: Vector3 in [Vector3(300, 30, -200), Vector3(-450, 30, 120), Vector3(90, 30, 90), Vector3(0, 30, -700)]:
		var camp := Vector3(10, 30, 20)
		var m := SurveyRules.map_frame(camp, target)
		var corner: Vector2 = m.corner
		var sq := int(m.square)
		assert_ne(SurveyRules.square(camp, corner, sq), "", "the camp is on the map (%s)" % target)
		assert_ne(SurveyRules.square(target, corner, sq), "", "the target is on the map (%s)" % target)
		assert_eq(int(m.squares), SurveyRules.MAP_SQUARES)
		assert_eq(int(m.size), SurveyRules.MAP_SQUARES * sq)
		assert_eq(fmod(corner.x, float(sq)), 0.0, "grid lines on round numbers")
		assert_eq(sq, 100 if Vector2(target.x - camp.x, target.z - camp.z).length() < 500.0 else 200,
			"the smallest scale that fits (%s)" % target)


## Wrong choices for a question: different from the answer and from each other, the answer among them once.
func test_choices_have_the_answer_once() -> void:
	var c := SurveyRules.point_choices("NE", 7)
	assert_eq(c.choices.size(), 4)
	assert_eq(c.choices[c.answer], "north-east")
	var seen := {}
	for t: String in c.choices:
		assert_false(seen.has(t), "no choice twice: %s" % t)
		seen[t] = true
	var d := SurveyRules.number_choices(300, 100, 3)
	assert_eq(d.choices[d.answer], "300 m")
	assert_eq(d.choices.size(), 4)
	var s := SurveyRules.square_choices("C4", 11)
	assert_eq(s.choices[s.answer], "C4")
	assert_eq(s.choices.size(), 4)
	assert_eq(SurveyRules.point_choices("NE", 7), c, "the same roll gives the same choices")
