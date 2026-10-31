extends GutTest
## Owner #78 (spec §21e): a "try it" moment for each invention, a small challenge that shows its science: fly the kite
## with your back to the wind; heat the balloon to rise; glide farther from higher; fly the plane 12 seconds (the first
## flight's time); fly the jet far; launch a bottle rocket. The tracker is fed what the child's body does.

const DT := 0.1

var t: InventionTry


func before_each() -> void:
	t = InventionTry.new()


func _s(pos: Vector3, craft: int, flying: bool, extra := {}) -> Dictionary:
	var s := {"pos": pos, "craft": craft, "flying": flying, "gliding": false, "on_floor": not flying,
		"facing": Vector3(1, 0, 0), "wind": Vector3(1, 0, 0)}
	s.merge(extra, true)
	return s


func test_the_kite_flies_with_your_back_to_the_wind() -> void:
	t.start(InventionLine.KITE)
	assert_true(t.active())
	for i in 30:
		t.feed(_s(Vector3.ZERO, FlightCrafts.Craft.KITE, false, {"facing": Vector3(-1, 0, 0)}), DT)
	assert_eq(t.progress, 0.0, "facing into the wind the kite falls")
	assert_string_contains(t.hint(), "back to the wind")
	for i in 49:
		t.feed(_s(Vector3.ZERO, FlightCrafts.Craft.KITE, false), DT)
	assert_false(t.done)
	t.feed(_s(Vector3.ZERO, FlightCrafts.Craft.KITE, false), DT * 1.5)
	assert_true(t.done, "5 seconds")
	assert_eq(t.progress, 1.0)


func test_the_balloon_rises_15_blocks() -> void:
	t.start(InventionLine.BALLOON)
	t.feed(_s(Vector3(0, 30, 0), FlightCrafts.Craft.NONE, false), DT)
	assert_string_contains(t.hint(), "balloon")
	t.feed(_s(Vector3(0, 30, 0), FlightCrafts.Craft.BALLOON, true), DT)
	t.feed(_s(Vector3(0, 38, 0), FlightCrafts.Craft.BALLOON, true), DT)
	assert_almost_eq(t.progress, 8.0 / 15.0, 0.01)
	t.feed(_s(Vector3(0, 45.5, 0), FlightCrafts.Craft.BALLOON, true), DT)
	assert_true(t.done)


func test_a_glide_counts_in_one_go() -> void:
	t.start(InventionLine.GLIDER)
	var g := {"gliding": true}
	t.feed(_s(Vector3(0, 50, 0), FlightCrafts.Craft.NONE, false, g), DT)
	t.feed(_s(Vector3(15, 45, 0), FlightCrafts.Craft.NONE, false, g), DT)
	assert_almost_eq(t.progress, 15.0 / 25.0, 0.01)
	t.feed(_s(Vector3(15, 40, 0), FlightCrafts.Craft.NONE, false), DT)
	assert_eq(t.progress, 0.0, "landed: the next glide starts again")
	t.feed(_s(Vector3(0, 60, 0), FlightCrafts.Craft.NONE, false, g), DT)
	t.feed(_s(Vector3(0, 50, 26), FlightCrafts.Craft.NONE, false, g), DT)
	assert_true(t.done)


func test_the_plane_flies_12_seconds_like_the_first_flight() -> void:
	t.start(InventionLine.PLANE)
	for i in 60:
		t.feed(_s(Vector3(0, 40, -i), FlightCrafts.Craft.PLANE, true), DT)
	assert_almost_eq(t.progress, 0.5, 0.01)
	t.feed(_s(Vector3(0, 30, 0), FlightCrafts.Craft.PLANE, true, {"on_floor": true}), DT)
	assert_eq(t.progress, 0.0, "a landing starts the clock again")
	for i in 121:
		t.feed(_s(Vector3(0, 40, -i), FlightCrafts.Craft.PLANE, true), DT)
	assert_true(t.done)


func test_the_jet_flies_far_in_one_flight() -> void:
	t.start(InventionLine.JET)
	t.feed(_s(Vector3(0, 60, 0), FlightCrafts.Craft.JET, true), DT)
	t.feed(_s(Vector3(150, 60, 0), FlightCrafts.Craft.JET, true), DT)
	assert_almost_eq(t.progress, 0.5, 0.01)
	t.feed(_s(Vector3(150, 60, 0), FlightCrafts.Craft.PLANE, true), DT)
	assert_eq(t.progress, 0.0, "in the jet")
	t.feed(_s(Vector3(150, 60, 0), FlightCrafts.Craft.JET, true), DT)
	t.feed(_s(Vector3(150, 60, 301), FlightCrafts.Craft.JET, true), DT)
	assert_true(t.done)


func test_a_bottle_rocket_flies_higher_with_more_air() -> void:
	assert_eq(InventionTry.bottle_height(0), 0.0, "no air, no push")
	assert_lt(InventionTry.bottle_height(3), InventionTry.bottle_height(6))
	assert_eq(InventionTry.bottle_height(99), InventionTry.bottle_height(InventionTry.BOTTLE_MAX_PUMPS),
		"only as much air as is safe")
	t.start(InventionLine.ROCKET)
	assert_lt(t.launch_bottle(3), InventionTry.BOTTLE_GOAL)
	assert_false(t.done)
	assert_gte(t.launch_bottle(6), InventionTry.BOTTLE_GOAL)
	assert_true(t.done)


func test_each_goal_has_words() -> void:
	for id in InventionLine.ORDER:
		t.start(id)
		assert_true(t.goal().length() > 5, "%s says what to do" % id)
	t.stop()
	assert_false(t.active())
