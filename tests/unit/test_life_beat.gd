extends GutTest
## Owner #112 (docs/design/life-skills.md §5 #1): hands-only CPR's beat. The authorities (ERC 2021, IFRC 2020): push
## 100 to 120 times a minute. The rate is read from the last few pushes; in VR a push is the hands going down a few
## centimetres from where they rest and coming back up (the chest comes back up).


func test_the_rate_from_push_times() -> void:
	assert_eq(LifeBeat.rate([]), 0.0)
	assert_eq(LifeBeat.rate([1.0]), 0.0, "one push has no rate yet")
	assert_almost_eq(LifeBeat.rate([0.0, 0.5, 1.0, 1.5]), 120.0, 0.1)
	assert_almost_eq(LifeBeat.rate([0.0, 0.6, 1.2]), 100.0, 0.1)


func test_the_rate_reads_only_the_last_pushes() -> void:
	var times: Array = [0.0, 2.0, 4.0]   # slow at first
	for i in 6:
		times.append(4.0 + (i + 1) * 0.55)
	assert_almost_eq(LifeBeat.rate(times), 109.1, 0.5)


func test_the_good_window_is_100_to_120() -> void:
	assert_false(LifeBeat.good(95.0))
	assert_true(LifeBeat.good(100.0))
	assert_true(LifeBeat.good(110.0))
	assert_true(LifeBeat.good(120.0))
	assert_false(LifeBeat.good(130.0))


func test_the_beat_the_coach_plays() -> void:
	assert_almost_eq(LifeBeat.BEAT_SECONDS, 60.0 / 110.0, 0.001, "110 a minute, the middle of the window")


func test_a_push_is_down_then_up() -> void:
	var p := LifeBeat.Pusher.new()
	assert_false(p.feed(1.00))
	assert_false(p.feed(0.98))
	assert_false(p.feed(0.95), "down 5 cm")
	assert_false(p.feed(0.955))
	assert_true(p.feed(0.98), "back up: one push")
	assert_false(p.feed(1.0))


func test_a_small_wobble_is_no_push() -> void:
	var p := LifeBeat.Pusher.new()
	var pushes := 0
	for y: float in [1.0, 0.99, 1.0, 0.985, 1.0, 0.99, 1.0]:
		if p.feed(y):
			pushes += 1
	assert_eq(pushes, 0)


func test_many_pushes_in_a_row() -> void:
	var p := LifeBeat.Pusher.new()
	var pushes := 0
	for i in 5:
		for y: float in [1.0, 0.97, 0.94, 0.97, 1.0]:
			if p.feed(y):
				pushes += 1
	assert_eq(pushes, 5)


func test_the_rest_height_follows_hands_that_settle_lower() -> void:
	var p := LifeBeat.Pusher.new()
	p.feed(1.0)   # placed higher at first...
	for i in 200:
		p.feed(0.97)   # ...then resting 3 cm lower
	var pushes := 0
	for y: float in [0.96, 0.95, 0.96, 0.97]:   # a 2 cm wobble from where they rest now: no push
		if p.feed(y):
			pushes += 1
	assert_eq(pushes, 0)
	for y: float in [0.95, 0.93, 0.96, 0.97]:   # a real push from there
		if p.feed(y):
			pushes += 1
	assert_eq(pushes, 1)
