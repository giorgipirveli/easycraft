extends GutTest
## M3 Task 21a (simple controls, research A6/O8): offered once at first launch, a switch in SETTINGS. Simple:
## auto-jump (up 1-block steps, as everyone has since M1b, and also over a 1-block gap), the camera turns to
## follow behind the child, and only the buttons that apply now show (ATTACK with a weapon or a monster near,
## CROUCH with a monster near). Classic keeps everything as it was.

const STEP := 1.0 / 60.0

var _solid := {}


func _is_solid(cell: Vector3i) -> bool:
	return _solid.has(cell)


## Flat ground at y = -1 (the feet stand at y = 0) from x = -5 to 10 along z = 0, except the given gaps.
func _ground(gaps: Array = [], deep := 3) -> void:
	_solid.clear()
	for x in range(-5, 11):
		if gaps.has(x):
			continue
		for z in range(-2, 3):
			for y in range(-deep, 0):
				_solid[Vector3i(x, y, z)] = true


func _jumps(simple: bool, feet := Vector3(0.5, 0.0, 0.5), dir := Vector3(1, 0, 0)) -> bool:
	return SimpleControls.auto_jump(simple, feet, dir, PlacementRules.PLAYER_RADIUS, 2, _is_solid)


func test_both_hop_up_a_one_block_step() -> void:
	_ground()
	_solid[Vector3i(1, 0, 0)] = true   # a step ahead, room above it
	assert_true(_jumps(true))
	assert_true(_jumps(false), "Classic keeps M1b's auto-step")


func test_simple_hops_over_a_one_block_gap() -> void:
	_ground([1])
	assert_true(_jumps(true), "a hole one block wide: Simple hops over it")
	assert_false(_jumps(false), "Classic walks on (the child jumps)")


func test_no_hop_on_flat_ground_or_standing_still() -> void:
	_ground()
	assert_false(_jumps(true))
	_ground([1])
	assert_false(_jumps(true, Vector3(0.5, 0, 0.5), Vector3.ZERO), "only while walking")
	assert_false(_jumps(true, Vector3(0.5, 0, 0.5), Vector3(0.1, 0, 0)), "a tiny push is not walking")


func test_no_hop_over_a_wide_gap_or_into_a_shallow_dip() -> void:
	_ground([1, 2])
	assert_false(_jumps(true), "two blocks wide: too far to land on the other side")
	_ground([1], 3)
	_solid[Vector3i(1, -2, 0)] = true   # the hole is one block deep: the child walks in and hops out
	assert_false(_jumps(true), "a one-deep dip is walked through")


func test_no_hop_under_a_low_ceiling() -> void:
	_ground([1])
	_solid[Vector3i(1, 2, 0)] = true   # a block over the gap at head height + 1
	assert_false(_jumps(true), "no room over the gap")


func test_no_hop_to_a_blocked_landing() -> void:
	_ground([1])
	_solid[Vector3i(2, 0, 0)] = true   # a wall on the other side
	_solid[Vector3i(2, 1, 0)] = true
	assert_false(_jumps(true))


func test_the_camera_follows_when_walking_sideways() -> void:
	var yaw: float = SimpleControls.follow_yaw(0.0, Vector2(1, 0), STEP, 10.0)
	assert_lt(yaw, 0.0, "stick right: the view turns right (like dragging right)")
	assert_gt(SimpleControls.follow_yaw(0.0, Vector2(-1, 0), STEP, 10.0), 0.0)
	var slow: float = SimpleControls.follow_yaw(0.0, Vector2(0.3, -0.9), STEP, 10.0)
	assert_between(slow, yaw, 0.0, "a small sideways part turns it slowly")


func test_the_camera_holds_still_when_it_should() -> void:
	assert_eq(SimpleControls.follow_yaw(1.0, Vector2(0, -1), STEP, 10.0), 1.0, "straight ahead: nothing to follow")
	assert_eq(SimpleControls.follow_yaw(1.0, Vector2.ZERO, STEP, 10.0), 1.0, "standing still")
	assert_eq(SimpleControls.follow_yaw(1.0, Vector2(1, 0), STEP, 0.2), 1.0, "the child just turned the camera")
	assert_eq(SimpleControls.follow_yaw(1.0, Vector2(0.7, 0.7), STEP, 10.0), 1.0, "walking back towards the camera")


func test_classic_shows_every_button() -> void:
	assert_true(SimpleControls.show_attack(false, false, false, false))
	assert_true(SimpleControls.show_crouch(false, false, false))


func test_simple_shows_attack_only_when_it_applies() -> void:
	assert_false(SimpleControls.show_attack(true, false, false, false), "empty hands, no monster")
	assert_true(SimpleControls.show_attack(true, true, false, false), "a weapon in the hand")
	assert_true(SimpleControls.show_attack(true, false, true, false), "a monster near")
	assert_true(SimpleControls.show_attack(true, false, false, true), "never hidden under a finger")


func test_simple_shows_crouch_only_when_it_applies() -> void:
	assert_false(SimpleControls.show_crouch(true, false, false))
	assert_true(SimpleControls.show_crouch(true, true, false), "a monster near: sneak")
	assert_true(SimpleControls.show_crouch(true, false, true), "crouching: the button stands you up")


func test_simple_controls_are_off_until_the_child_chooses() -> void:
	var p := ProfileData.new()
	assert_false(p.settings.simple_controls)
	assert_false(p.settings.simple_asked)
	p.settings.simple_controls = true
	p.settings.simple_asked = true
	var q := ProfileData.from_json(p.to_json())
	assert_true(q.settings.simple_controls)
	assert_true(q.settings.simple_asked)
