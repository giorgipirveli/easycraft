extends GutTest
## Jump pads and speed pads (M3 Task 6, spec §14.3): which pad a body stands on, the launch, the
## speed burst, and the cooldown that keeps two pads from bouncing a body back and forth endlessly fast.

const DT := 1.0 / 60.0

var pads: PadRules


func before_each() -> void:
	pads = PadRules.new()


## A one-pad world: `id` at `cell`, stone below y = 10, air elsewhere.
func _world(id: int, cell: Vector3i) -> Callable:
	return func(p: Vector3i) -> int:
		if p == cell:
			return id
		return BlockIds.STONE if p.y < 10 else BlockIds.AIR


func test_pads_are_blocks_with_their_own_ids() -> void:
	assert_eq(BlockIds.JUMP_PAD, 36)
	assert_eq(BlockIds.SPEED_PAD, 37)
	assert_true(PadRules.is_pad(BlockIds.JUMP_PAD))
	assert_true(PadRules.is_pad(BlockIds.SPEED_PAD))
	assert_false(PadRules.is_pad(BlockIds.STONE))
	assert_false(PadRules.is_pad(BlockIds.AIR))


func test_the_pad_under_the_feet() -> void:
	var get_block := _world(BlockIds.JUMP_PAD, Vector3i(3, 10, 3))
	assert_eq(PadRules.pad_under(Vector3(3.5, 11.0, 3.5), 0.3, get_block), BlockIds.JUMP_PAD, "standing on it")
	assert_eq(PadRules.pad_under(Vector3(3.5, 11.001, 3.5), 0.0, get_block), BlockIds.JUMP_PAD, "a point body too")
	assert_eq(PadRules.pad_under(Vector3(5.5, 11.0, 3.5), 0.3, get_block), 0, "next to it")
	assert_eq(PadRules.pad_under(Vector3(3.5, 13.0, 3.5), 0.3, get_block), 0, "high above it")


func test_a_foot_on_the_edge_of_a_pad_counts() -> void:
	var get_block := _world(BlockIds.SPEED_PAD, Vector3i(3, 10, 3))
	assert_eq(PadRules.pad_under(Vector3(4.15, 11.0, 3.5), 0.3, get_block), BlockIds.SPEED_PAD,
		"the body's centre is off the pad, its side is on it")
	assert_eq(PadRules.pad_under(Vector3(4.15, 11.0, 3.5), 0.0, get_block), 0, "a point body is not")


func test_a_jump_pad_throws_a_body_up_strongly() -> void:
	assert_eq(pads.touch(BlockIds.JUMP_PAD, Vector3(2, 0, 0), Vector3.FORWARD), BlockIds.JUMP_PAD)
	var v := pads.apply(Vector3(2, 0, 0), BlockIds.JUMP_PAD)
	assert_eq(v.y, PadRules.LAUNCH_SPEED)
	assert_eq(v.x, 2.0, "it keeps its run")
	var height := PadRules.LAUNCH_SPEED * PadRules.LAUNCH_SPEED / (2.0 * Player.GRAVITY)
	assert_gt(height, 4.0, "higher than a triple jump's first hop")
	assert_gt(height, 3.0 * LabRules.jump_height(LabRules.Mode.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY))


func test_launches_never_add_up() -> void:
	var v := PadRules.launch_velocity(PadRules.launch_velocity(Vector3.ZERO))
	assert_eq(v.y, PadRules.LAUNCH_SPEED)
	assert_eq(PadRules.launch_velocity(Vector3(0, 30, 0)).y, 30.0, "never slows a faster body")


func test_a_pad_waits_a_moment_before_it_fires_again() -> void:
	assert_eq(pads.touch(BlockIds.JUMP_PAD, Vector3.ZERO, Vector3.FORWARD), BlockIds.JUMP_PAD)
	assert_eq(pads.touch(BlockIds.JUMP_PAD, Vector3.ZERO, Vector3.FORWARD), 0, "cooling down")
	assert_eq(pads.touch(BlockIds.SPEED_PAD, Vector3.ZERO, Vector3.FORWARD), 0, "any pad")
	pads.tick(PadRules.COOLDOWN + 0.01)
	assert_eq(pads.touch(BlockIds.JUMP_PAD, Vector3.ZERO, Vector3.FORWARD), BlockIds.JUMP_PAD, "ready again")


func test_two_pads_can_not_bounce_a_body_endlessly_fast() -> void:
	# A body touching a pad every physics frame for 3 s (say, between two pads under a low ceiling).
	var fired := 0
	for i in 180:
		pads.tick(DT)
		var pad := BlockIds.JUMP_PAD if i % 2 == 0 else BlockIds.SPEED_PAD
		if pads.touch(pad, Vector3(1, 0, 0), Vector3.FORWARD) != 0:
			fired += 1
	assert_lte(fired, ceili(3.0 / PadRules.COOLDOWN) + 1)
	assert_gt(fired, 1, "but pads keep working")


func test_nothing_but_a_pad_fires() -> void:
	assert_eq(pads.touch(BlockIds.STONE, Vector3.ZERO, Vector3.FORWARD), 0)
	assert_eq(pads.touch(0, Vector3.ZERO, Vector3.FORWARD), 0)
	assert_eq(pads.cooldown_left, 0.0, "and it does not start a cooldown")


func test_a_speed_pad_bursts_the_way_the_body_travels_for_one_and_a_half_seconds() -> void:
	var run := Vector3(0, 0, -3)   # walking north onto the pad
	assert_eq(pads.touch(BlockIds.SPEED_PAD, run, Vector3.RIGHT), BlockIds.SPEED_PAD)
	var v := pads.apply(run, BlockIds.SPEED_PAD)
	assert_almost_eq(-v.z, PadRules.BOOST_SPEED, 0.0001, "a burst of speed")
	assert_almost_eq(v.x, 0.0, 0.0001, "along the way it was going, not the way it looked")
	var t := 0.0
	while t < PadRules.BOOST_TIME - PadRules.BOOST_FADE - 0.05:
		pads.tick(DT)
		t += DT
	assert_almost_eq(-pads.apply(run, 0).z, PadRules.BOOST_SPEED, 0.0001, "full speed for a second")
	while t < PadRules.BOOST_TIME - 0.1:
		pads.tick(DT)
		t += DT
	var fading := -pads.apply(run, 0).z
	assert_lt(fading, PadRules.BOOST_SPEED, "easing back")
	pads.tick(0.2)
	assert_eq(pads.apply(run, 0), run, "over after %.1f s" % PadRules.BOOST_TIME)


func test_a_body_standing_still_bursts_the_way_it_faces() -> void:
	pads.touch(BlockIds.SPEED_PAD, Vector3.ZERO, Vector3.RIGHT)
	var v := pads.apply(Vector3.ZERO, BlockIds.SPEED_PAD)
	assert_almost_eq(v, Vector3(PadRules.BOOST_SPEED, 0, 0), Vector3.ONE * 0.0001)


func test_the_burst_is_level_whatever_the_body_does_up_or_down() -> void:
	pads.touch(BlockIds.SPEED_PAD, Vector3(3, -5, 0), Vector3.FORWARD)
	var v := pads.apply(Vector3(3, -5, 0), BlockIds.SPEED_PAD)
	assert_almost_eq(v.x, PadRules.BOOST_SPEED, 0.0001)
	assert_eq(v.y, -5.0, "falling or jumping goes on as before")


func test_a_boosted_body_can_still_steer_sideways() -> void:
	pads.touch(BlockIds.SPEED_PAD, Vector3(0, 0, -3), Vector3.FORWARD)
	var v := pads.apply(Vector3(2, 0, -3), 0)
	assert_eq(v.x, 2.0)
	assert_almost_eq(-v.z, PadRules.BOOST_SPEED, 0.0001)


func test_boosts_never_add_up() -> void:
	var v := Vector3(0, 0, -3)
	pads.touch(BlockIds.SPEED_PAD, v, Vector3.FORWARD)
	v = pads.apply(v, BlockIds.SPEED_PAD)
	pads.tick(PadRules.COOLDOWN + 0.01)
	pads.touch(BlockIds.SPEED_PAD, v, Vector3.FORWARD)
	v = pads.apply(v, BlockIds.SPEED_PAD)
	assert_almost_eq(v.length(), PadRules.BOOST_SPEED, 0.0001, "a chain of speed pads holds the speed, never more")
	assert_almost_eq(pads.boost_left, PadRules.BOOST_TIME, 0.0001, "the burst starts over")


func test_the_burst_never_slows_a_faster_body() -> void:
	pads.touch(BlockIds.SPEED_PAD, Vector3(20, 0, 0), Vector3.FORWARD)
	assert_eq(pads.apply(Vector3(20, 0, 0), BlockIds.SPEED_PAD), Vector3(20, 0, 0))


func test_reset_forgets_the_burst_and_the_cooldown() -> void:
	pads.touch(BlockIds.SPEED_PAD, Vector3(3, 0, 0), Vector3.FORWARD)
	pads.reset()
	assert_eq(pads.boost_left, 0.0)
	assert_eq(pads.cooldown_left, 0.0)
	assert_eq(pads.apply(Vector3(3, 0, 0), 0), Vector3(3, 0, 0))
