extends GutTest
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.5, §3.5b, §3.10): the weather is the music the child plays
## along to. A voyage's script from its data: what the weather is at any moment, the desert's dawn that warms over 8 s,
## the window that lasts 30 % longer after two missed turns (ruling 25), the extra turns the bud asks for (up to six in
## all), and which way a plant that knows the rule sets its doors (the ghost's and the rule's direction).


func test_the_sunflower_s_script_plays_in_order() -> void:
	var w := LeafWeather.for_voyage("5.1")
	assert_almost_eq(w.total(), 164.0, 0.001, "14 + 4 x (20 + 15) + 10")
	var a := w.at(0.0)
	assert_eq(str(a.id), "trap")
	assert_eq(str(a.kind), "blaze")
	assert_almost_eq(float(a.heat), 1.0, 0.0001)
	assert_almost_eq(float(a.light), 1.0, 0.0001)
	assert_almost_eq(float(a.left), 14.0, 0.0001)
	var b := w.at(14.0)
	assert_eq(str(b.id), "cloud1", "a new segment starts on its first moment")
	assert_almost_eq(float(b.since), 0.0, 0.0001)
	assert_true(bool(b.voiced), "the first cloud is voiced")
	assert_almost_eq(float(b.heat), 0.25, 0.0001)
	assert_almost_eq(float(b.light), 0.7, 0.0001)
	var c := w.at(13.99)
	assert_eq(str(c.id), "trap")
	assert_almost_eq(float(c.since), 13.99, 0.0001)
	var e := w.at(160.0)
	assert_eq(str(e.id), "evening")
	assert_false(w.ended(163.9))
	assert_true(w.ended(164.0))
	assert_eq(str(w.at(500.0).id), "evening", "after the end the last weather holds")


func test_the_rule_opens_the_doors_in_the_cloud_and_shuts_them_in_the_blaze() -> void:
	var w := LeafWeather.for_voyage("5.1")
	assert_false(bool(w.at(1.0).open), "the blaze: shut")
	assert_true(bool(w.at(15.0).open), "the cloud: open")
	assert_false(bool(w.at(160.0).open), "the evening: shut")
	var d := LeafWeather.for_voyage("5.T1")
	assert_false(bool(d.at(5.0).open), "the desert's day: shut")
	assert_true(bool(d.at(35.0).open), "the desert's night: open")
	assert_true(bool(d.at(35.0).night))
	assert_false(bool(d.at(5.0).night))


func test_the_desert_s_dawn_warms_over_eight_seconds() -> void:
	var d := LeafWeather.for_voyage("5.T1")
	assert_almost_eq(d.total(), 150.0, 0.001, "day, night, day, night, day: 30 s each")
	var dawn := d.at(60.0)
	assert_eq(str(dawn.id), "day2")
	assert_almost_eq(float(dawn.heat), 0.2, 0.0001, "the cool of the morning")
	assert_almost_eq(float(dawn.light), 0.3, 0.0001)
	var mid := d.at(64.0)
	assert_almost_eq(float(mid.heat), 0.75, 0.0001, "0.2 + (1.3 - 0.2) x 4/8")
	assert_almost_eq(float(mid.light), 0.65, 0.0001, "0.3 + 0.7 x 4/8")
	var noon := d.at(70.0)
	assert_almost_eq(float(noon.heat), 1.3, 0.0001)
	assert_almost_eq(float(noon.light), 1.0, 0.0001)
	var night := d.at(40.0)
	assert_almost_eq(float(night.heat), 0.05, 0.0001)
	assert_almost_eq(float(night.light), 0.0, 0.0001)


func test_a_window_lengthened_after_two_misses_lasts_longer_and_pushes_the_rest_on() -> void:
	var w := LeafWeather.for_voyage("5.1")
	var cloud3 := w.index_of("cloud3")
	var start := w.start_of(cloud3)
	assert_almost_eq(start, 84.0, 0.001, "14 + 35 + 35")
	w.lengthen(cloud3, 0.3)
	assert_almost_eq(float(w.segments[cloud3].seconds), 26.0, 0.001, "20 s, 30 % longer")
	assert_true(bool(w.segments[cloud3].longer), "the record's note says so")
	assert_almost_eq(w.start_of(cloud3 + 1), 110.0, 0.001, "the next blaze starts 6 s later")
	assert_almost_eq(w.total(), 170.0, 0.001)


func test_the_bud_asks_for_more_turns_up_to_six_in_all() -> void:
	var w := LeafWeather.for_voyage("5.1")
	assert_eq(w.turn_count(), 4, "the script's four clouds")
	assert_true(w.add_turn())
	assert_eq(w.turn_count(), 5)
	var last := w.segments.size() - 1
	assert_eq(str(w.segments[last].kind), "evening", "the evening still ends the day")
	assert_eq(str(w.segments[last - 2].id), "cloud5")
	assert_eq(str(w.segments[last - 1].id), "blaze5")
	assert_almost_eq(float(w.segments[last - 2].seconds), 20.0, 0.001)
	assert_almost_eq(float(w.segments[last - 1].seconds), 15.0, 0.001)
	assert_true(w.add_turn())
	assert_false(w.add_turn(), "six turns in all, never more")
	assert_eq(w.turn_count(), 6)
	assert_false(LeafWeather.for_voyage("5.T1").add_turn(), "the desert's days and nights are fixed")


func test_an_unknown_voyage_has_no_weather() -> void:
	var w := LeafWeather.for_voyage("9.9")
	assert_eq(w.total(), 0.0)
	assert_true(w.ended(0.0))
	assert_eq(str(w.at(0.0).get("kind", "")), "", "no weather at all")
