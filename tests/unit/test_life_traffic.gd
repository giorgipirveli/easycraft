extends GutTest
## Owner #112 (docs/design/life-skills.md §5 #4, Safe Streets; the evidence [L3]: real gaps between real-sized cars at
## real speeds): the practice street's scripted traffic (LifeTraffic, not the world's cars). Cars drive on the region's
## side at town speeds (30-40 km/h), in bunches with a real safe gap every cycle; a car in the crossing or reaching it
## within the time it takes to walk across makes it unsafe. A child who steps out when it isn't safe makes the coming
## cars stop gently before the crossing (never a crash); a button crossing turns the cars' light red and shows the green
## man; cars never drive into each other.


func _run(t: LifeTraffic, seconds: float, dt: float = 0.05) -> void:
	var n := int(seconds / dt)
	for i in n:
		t.step(dt)


func test_cars_drive_at_real_town_speeds_on_the_regions_side() -> void:
	var right := LifeTraffic.new(3, "right")
	_run(right, 30.0)
	assert_gt(right.cars.size(), 0)
	for c: Dictionary in right.cars:
		assert_between(float(c.top), 8.0, 11.2, "30-40 km/h")
		if int(c.lane) == LifeTraffic.NEAR:
			assert_eq(int(c.dir), 1, "cars drive on the right: the near lane comes from the child's left (-x)")
	var left := LifeTraffic.new(3, "left")
	_run(left, 30.0)
	for c: Dictionary in left.cars:
		if int(c.lane) == LifeTraffic.NEAR:
			assert_eq(int(c.dir), -1, "cars drive on the left: the near lane comes from the child's right")


func test_there_is_a_real_safe_gap_every_cycle_and_busy_moments_between() -> void:
	var t := LifeTraffic.new(7, "right")
	var safe_runs := 0
	var unsafe_seen := false
	var was_safe := false
	var longest_wait := 0.0
	var waiting := 0.0
	var window := 0.0
	var shortest_window := INF
	for i in int(LifeTraffic.CYCLE * 4.0 / 0.05):
		t.step(0.05)
		var s := t.safe_gap()
		if s and not was_safe:
			safe_runs += 1
		unsafe_seen = unsafe_seen or not s
		waiting = 0.0 if s else waiting + 0.05
		longest_wait = maxf(longest_wait, waiting)
		if s:
			window += 0.05
		elif was_safe and i > 40:
			shortest_window = minf(shortest_window, window)
			window = 0.0
		was_safe = s
	assert_gte(safe_runs, 3, "a safe gap comes every cycle")
	assert_true(unsafe_seen, "and there are busy moments to wait through")
	assert_lt(longest_wait, LifeTraffic.CYCLE, "a child never waits more than a cycle")
	assert_gte(shortest_window, 3.0, "each safe gap lasts long enough to see it and go")


func test_safe_means_no_car_in_the_crossing_or_reaching_it_while_you_walk_across() -> void:
	var t := LifeTraffic.new(11, "right")
	for i in int(LifeTraffic.CYCLE * 3.0 / 0.05):
		t.step(0.05)
		if not t.safe_gap():
			continue
		for c: Dictionary in t.cars:
			var ahead := -float(c.x) * int(c.dir)   # metres before the crossing (negative: past it)
			assert_false(absf(float(c.x)) < LifeTraffic.ZONE, "nothing in the crossing when it is safe")
			if ahead > LifeTraffic.ZONE and float(c.v) > 0.5:
				assert_gte((ahead - LifeTraffic.ZONE) / float(c.v), LifeTraffic.CROSS_SECONDS - 0.05,
					"time to walk across before it comes")


func test_stepping_out_when_unsafe_makes_the_coming_cars_stop_gently_then_go_on() -> void:
	var t := LifeTraffic.new(5, "right")
	while t.safe_gap():
		t.step(0.05)
	_run(t, 0.5)
	var coming := t.coming()
	assert_gt(coming.size(), 0, "a car is coming")
	t.stop_for_child()
	var stopped := false
	var closest := INF
	for i in int(8.0 / 0.05):
		t.step(0.05)
		for c: Dictionary in t.cars:
			if int(c.id) == int(coming[0].id) and not stopped:
				closest = minf(closest, -float(c.x) * int(c.dir))
				stopped = float(c.v) < 0.05
	assert_true(stopped, "the car stops")
	assert_gte(closest, LifeTraffic.ZONE - 0.01, "before the crossing: never into it while it stops")
	_run(t, 6.0)
	var still := false
	for c: Dictionary in t.cars:
		still = still or (int(c.id) == int(coming[0].id) and float(c.v) < 0.05)
	assert_false(still, "and then it drives on")


func test_cars_never_drive_into_each_other() -> void:
	var t := LifeTraffic.new(2, "left")
	for i in int(60.0 / 0.05):
		t.step(0.05)
		if i % 200 == 0:
			t.stop_for_child()
		for a: Dictionary in t.cars:
			for b: Dictionary in t.cars:
				if a == b or int(a.lane) != int(b.lane):
					continue
				var gap := absf(float(a.x) - float(b.x)) - (float(a.length) + float(b.length)) * 0.5
				assert_gt(gap, 0.5, "a following car keeps its distance")


func test_the_button_crossing_turns_the_cars_red_and_shows_the_green_man() -> void:
	var t := LifeTraffic.new(4, "right")
	_run(t, 5.0)
	assert_false(t.green_man())
	assert_false(t.safe_green(), "never on the red man")
	t.press_button()
	assert_true(t.waiting_for_green())
	_run(t, LifeTraffic.BUTTON_WAIT + LifeTraffic.AMBER + 3.0)
	assert_true(t.green_man(), "the green man")
	assert_eq(t.lights, "stop")
	var moving_before := false
	for c: Dictionary in t.cars:
		var ahead := -float(c.x) * int(c.dir)
		if ahead > 0.0 and ahead < LifeTraffic.STOP_X + 20.0 and float(c.v) > 0.3:
			moving_before = true
	assert_false(moving_before, "every car before the crossing has stopped")
	assert_true(t.safe_green())
	_run(t, LifeTraffic.GREEN_MAN)
	assert_false(t.green_man(), "and back to the cars")


func test_the_same_seed_makes_the_same_traffic() -> void:
	var a := LifeTraffic.new(9, "right")
	var b := LifeTraffic.new(9, "right")
	_run(a, 20.0)
	_run(b, 20.0)
	assert_eq(a.cars.size(), b.cars.size())
	for i in a.cars.size():
		assert_almost_eq(float(a.cars[i].x), float(b.cars[i].x), 0.001)


## A car past its stop line (it went on at amber, or it stopped for a child there) still has to cross: the green man is
## not safe until it has gone, even while it stands.
func test_the_green_man_waits_for_a_car_past_its_line() -> void:
	var t := LifeTraffic.new(4, "right")
	t.press_button()
	_run(t, LifeTraffic.BUTTON_WAIT + LifeTraffic.AMBER + 2.0)
	assert_true(t.green_man())
	t.cars.append({"id": 999, "lane": LifeTraffic.NEAR, "dir": 1, "x": -5.0, "v": 0.0, "top": 8.33, "kind": &"pickup",
		"colour": 0, "length": 4.2, "hold": 2.0, "stop_at": -5.0, "why": "child"})
	assert_false(t.safe_green(), "a car stands between its line and the crossing")
