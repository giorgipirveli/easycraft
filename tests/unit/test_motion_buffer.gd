extends GutTest
## Smoothing remote bodies between syncs (M4 Wave 2 A2, spec §17.0): players sync 20 times a second
## and creatures 10, so they moved in visible steps. A MotionBuffer keeps the last few synced places
## with the time they arrived and shows the body where it was `delay` seconds ago, in between two of
## them; it never guesses ahead, jumps on a teleport, and waits out a rest.

const INTERVAL := 0.05
const DELAY := 0.1


func _buffer() -> MotionBuffer:
	return MotionBuffer.new(INTERVAL, DELAY)


func test_an_empty_buffer_has_nothing_to_show() -> void:
	var b := _buffer()
	assert_true(b.is_empty())
	b.push(1.0, Vector3.ONE, 0.0)
	assert_false(b.is_empty())
	b.clear()
	assert_true(b.is_empty())


func test_it_shows_the_body_delay_seconds_ago_between_two_syncs() -> void:
	var b := _buffer()
	b.push(1.00, Vector3(0, 0, 0), 0.0)
	b.push(1.05, Vector3(1, 0, 0), 0.0)
	b.push(1.10, Vector3(2, 0, 0), 0.0)
	b.sample(1.125)   # shows 1.025: half way from the first to the second
	assert_almost_eq(b.position, Vector3(0.5, 0, 0), Vector3.ONE * 0.001)
	b.sample(1.19)    # 1.09: 80 % from the second to the third
	assert_almost_eq(b.position, Vector3(1.8, 0, 0), Vector3.ONE * 0.001)


func test_it_never_guesses_ahead_of_the_newest_or_behind_the_oldest() -> void:
	var b := _buffer()
	b.push(1.00, Vector3(0, 0, 0), 0.0)
	b.push(1.05, Vector3(1, 2, 3), 0.0)
	b.sample(5.0)
	assert_eq(b.position, Vector3(1, 2, 3), "held at the newest (a late packet is waited for)")
	b.sample(0.5)
	assert_eq(b.position, Vector3.ZERO, "the oldest")


func test_a_single_sync_is_shown_at_once() -> void:
	var b := _buffer()
	b.push(2.0, Vector3(4, 5, 6), 1.0)
	b.sample(2.0)
	assert_eq(b.position, Vector3(4, 5, 6))
	assert_eq(b.yaw, 1.0)


func test_the_turn_takes_the_short_way_round() -> void:
	var b := _buffer()
	b.push(1.00, Vector3.ZERO, deg_to_rad(170.0))
	b.push(1.05, Vector3.ZERO, deg_to_rad(-170.0))
	b.sample(1.125)
	assert_almost_eq(absf(b.yaw), PI, 0.001, "through 180 degrees, not through 0")


func test_a_teleport_jumps_instead_of_sliding() -> void:
	var b := _buffer()
	b.push(1.00, Vector3.ZERO, 0.0)
	b.push(1.05, Vector3(1, 0, 0), 0.0)
	b.push(1.10, Vector3(100, 0, 0), 0.0)   # a respawn, a portal, a rejoin
	b.sample(1.12)
	assert_eq(b.position, Vector3(100, 0, 0))


func test_after_a_rest_it_starts_moving_from_where_it_rested() -> void:
	# A resting creature sends nothing (only changes sync); its first move after the rest must not
	# be smeared over the whole rest.
	var b := _buffer()
	b.push(1.00, Vector3.ZERO, 0.0)
	b.push(5.00, Vector3(1, 0, 0), 0.0)   # 4 s later
	b.sample(5.0 + DELAY - INTERVAL * 0.5)   # half an interval into the move
	assert_almost_eq(b.position, Vector3(0.5, 0, 0), Vector3.ONE * 0.001)
	b.sample(5.0 + DELAY - INTERVAL * 1.5)
	assert_eq(b.position, Vector3.ZERO, "still resting just before")


func test_it_keeps_only_the_newest_syncs_in_a_fixed_ring() -> void:
	var b := _buffer()
	for i in 100:
		b.push(1.0 + i * INTERVAL, Vector3(i, 0, 0), 0.0)
	assert_eq(b.count(), MotionBuffer.SIZE)
	b.sample(1.0 + 99 * INTERVAL + DELAY)
	assert_eq(b.position, Vector3(99, 0, 0))
	b.sample(1.0 + 97.5 * INTERVAL + DELAY)
	assert_almost_eq(b.position, Vector3(97.5, 0, 0), Vector3.ONE * 0.001)


func test_times_out_of_order_or_bad_values_do_not_break_it() -> void:
	var b := _buffer()
	b.push(1.0, Vector3.ZERO, 0.0)
	b.push(1.0, Vector3(1, 0, 0), 0.0)   # two in one frame
	b.push(0.9, Vector3(2, 0, 0), 0.0)   # a clock that went back
	b.push(1.2, Vector3(NAN, 0, 0), 0.0)
	b.push(1.2, Vector3(3, 0, 0), INF)
	assert_eq(b.count(), 3, "the bad values are ignored")
	b.sample(10.0)
	assert_eq(b.position, Vector3(2, 0, 0))
	assert_true(b.position.is_finite())
