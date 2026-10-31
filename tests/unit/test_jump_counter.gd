extends GutTest

var jc: JumpCounter


func before_each() -> void:
	jc = JumpCounter.new()


func test_three_jumps_then_no_fourth() -> void:
	jc.tick(0.016, true)
	jc.press_jump()
	assert_true(jc.tick(0.016, true), "ground jump")
	jc.press_jump()
	assert_true(jc.tick(0.016, false), "air jump 1")
	jc.press_jump()
	assert_true(jc.tick(0.016, false), "air jump 2")
	jc.press_jump()
	assert_false(jc.tick(0.016, false), "no 4th jump")


func test_landing_resets() -> void:
	jc.tick(0.016, true)
	for i in 3:
		jc.press_jump()
		jc.tick(0.016, i == 0)
	jc.tick(0.016, true)
	jc.press_jump()
	assert_true(jc.tick(0.016, true))


func test_no_jump_without_press() -> void:
	assert_false(jc.tick(0.016, true))
	assert_false(jc.tick(0.016, false))


func test_coyote_time_allows_ground_jump_after_leaving_edge() -> void:
	jc.tick(0.016, true)
	jc.tick(0.05, false)
	jc.press_jump()
	assert_true(jc.tick(0.016, false))
	assert_eq(jc.jumps_used, 1, "coyote jump counts as the ground jump")


func test_after_coyote_window_first_press_is_an_air_jump() -> void:
	jc.tick(0.016, true)
	jc.tick(0.3, false)
	jc.press_jump()
	assert_true(jc.tick(0.016, false))
	assert_eq(jc.jumps_used, 2, "walking off an edge spends the ground jump")


func test_buffered_press_fires_on_landing() -> void:
	jc.tick(0.016, true)
	jc.press_jump()
	jc.tick(0.016, true)
	jc.press_jump()
	jc.tick(0.016, false)
	jc.press_jump()
	jc.tick(0.016, false)
	jc.press_jump()
	assert_false(jc.tick(0.05, false), "no jumps left, press is buffered")
	assert_true(jc.tick(0.016, true), "buffered press fires on landing")


func test_stale_buffer_expires() -> void:
	jc.tick(0.016, true)
	jc.press_jump()
	jc.tick(0.016, true)
	jc.press_jump()
	jc.tick(0.016, false)
	jc.press_jump()
	jc.tick(0.016, false)
	jc.press_jump()
	jc.tick(0.2, false)
	assert_false(jc.tick(0.016, true), "press older than 0.1 s is dropped")


func test_double_jump_mode_allows_exactly_two() -> void:
	var c := JumpCounter.new()
	c.max_jumps = 2
	c.tick(0.016, true)
	c.press_jump()
	assert_true(c.tick(0.016, true), "ground jump")
	c.press_jump()
	assert_true(c.tick(0.016, false), "air jump")
	c.press_jump()
	assert_false(c.tick(0.016, false), "no third jump in double mode")
