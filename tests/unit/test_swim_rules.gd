extends GutTest
## Real water (M2 Task 14, owner feedback #17): in water deep enough the player swims. It floats with
## the head above the surface, swims where it looks, JUMP swims up and DOWN dives, it never stands on
## the bottom, and it climbs out over a 1-block bank.
##
## The pool used here, along x (every z is the same):
##   x < 0     land, stone up to row 12 (its top is level with the water surface at 13)
##   0 ... 3   a shallow shelf: stone up to row 11, water in row 12 (1 deep)
##   4 ... 19  deep water: stone up to row 9, water in rows 10-12 (3 deep, the surface at 13)
##   x >= 20   a bank: stone up to row 13 (its top is 1 block above the surface)

const DT := 1.0 / 60.0
const SURFACE := 13.0
const FLOOR := 10.0


static func _pool(p: Vector3i) -> int:
	if p.y <= 9:
		return BlockIds.STONE
	if p.x < 0:
		return BlockIds.STONE if p.y <= 12 else BlockIds.AIR
	if p.x < 4:
		if p.y <= 11:
			return BlockIds.STONE
		return BlockIds.WATER if p.y <= 12 else BlockIds.AIR
	if p.x < 20:
		return BlockIds.WATER if p.y <= 12 else BlockIds.AIR
	return BlockIds.STONE if p.y <= 13 else BlockIds.AIR


## Water from row -50 to row 12: deeper than any fall.
static func _sea(p: Vector3i) -> int:
	if p.y < -50:
		return BlockIds.STONE
	return BlockIds.WATER if p.y <= 12 else BlockIds.AIR


static func _solid_in(blocks: Callable) -> Callable:
	return func(p: Vector3i) -> bool: return BlockIds.is_solid(blocks.call(p))


## Moves a body's feet with the swim rules for `seconds` (no input unless given), stopping on the
## floor like the physics would. Returns [feet_y, velocity_y, lowest feet_y, highest feet_y].
static func _simulate(blocks: Callable, feet_y: float, vy: float, seconds: float, up := false,
		down := false, floor_y := -1000.0) -> Array:
	var low := feet_y
	var high := feet_y
	var feet := Vector3(10.5, feet_y, 0.5)
	for i in int(seconds / DT):
		var surface := SwimRules.surface_y(feet, blocks)
		vy = SwimRules.vertical_velocity(vy, SwimRules.vertical_target(surface - feet.y, 1.0, 1.0, up, down, 0.0), DT)
		feet.y += vy * DT
		if feet.y < floor_y:
			feet.y = floor_y
			vy = maxf(vy, 0.0)
		low = minf(low, feet.y)
		high = maxf(high, feet.y)
	return [feet.y, vy, low, high]


# --- Where the body is: dry, wading, swimming or diving ---------------------------------------

func test_on_land_the_body_is_dry() -> void:
	assert_eq(SwimRules.water_state(Vector3(-3.5, 13.0, 0.5), 1.0, _pool), SwimRules.State.DRY)


func test_knee_deep_water_is_wading_not_swimming() -> void:
	assert_eq(SwimRules.water_state(Vector3(2.5, 12.0, 0.5), 1.0, _pool), SwimRules.State.WADING,
		"1-deep water only reaches the knees: walk (slowly) through it")


func test_water_up_to_the_chest_is_swimming_even_on_the_bottom() -> void:
	assert_eq(SwimRules.water_state(Vector3(10.5, FLOOR, 0.5), 1.0, _pool), SwimRules.State.DIVING,
		"standing on the bottom of 3-deep water: the head is under")
	assert_eq(SwimRules.water_state(Vector3(10.5, SURFACE - SwimRules.FLOAT_DEPTH, 0.5), 1.0, _pool),
		SwimRules.State.SWIMMING, "floating: swimming with the head out")


func test_the_head_under_water_is_diving() -> void:
	assert_eq(SwimRules.water_state(Vector3(10.5, 10.6, 0.5), 1.0, _pool), SwimRules.State.DIVING)


func test_a_giant_wades_where_a_normal_player_swims_and_a_tiny_one_swims_in_a_puddle() -> void:
	assert_eq(SwimRules.water_state(Vector3(10.5, FLOOR, 0.5), 3.0, _pool), SwimRules.State.WADING,
		"3-deep water reaches a giant's knees")
	var tiny_float := SURFACE - SwimRules.FLOAT_DEPTH * 0.25
	assert_eq(SwimRules.water_state(Vector3(2.5, tiny_float, 0.5), 0.25, _pool), SwimRules.State.SWIMMING,
		"1-deep water is a lake for a tiny player")


func test_the_surface_is_found_from_the_feet() -> void:
	assert_eq(SwimRules.surface_y(Vector3(10.5, 10.2, 0.5), _pool), SURFACE)
	assert_eq(SwimRules.surface_y(Vector3(10.5, 12.9, 0.5), _pool), SURFACE, "feet just in the water")
	assert_eq(SwimRules.surface_y(Vector3(2.5, 12.0, 0.5), _pool), SURFACE, "shallow water")
	assert_gt(SwimRules.surface_y(Vector3(10.5, -40.0, 0.5), _sea), -40.0 + SwimRules.SURFACE_SCAN - 1,
		"deep down the surface is far above (the scan stops early)")


# --- Floating, diving and swimming up -----------------------------------------------------------

func test_an_idle_swimmer_floats_up_from_the_bottom_with_the_head_above_the_surface() -> void:
	var r := _simulate(_pool, FLOOR, 0.0, 8.0, false, false, FLOOR)
	var feet: float = r[0]
	assert_almost_eq(SURFACE - feet, SwimRules.FLOAT_DEPTH, 0.05, "floats at the float line")
	assert_gt(feet + SwimRules.EYES, SURFACE + 0.2, "the eyes are above the water")
	assert_gt(feet, FLOOR + 0.5, "never rests on the bottom")
	assert_almost_eq(float(r[1]), 0.0, 0.05, "and stays there")
	assert_eq(SwimRules.water_state(Vector3(10.5, feet, 0.5), 1.0, _pool), SwimRules.State.SWIMMING)


func test_floating_up_never_pops_the_chest_out_of_the_water() -> void:
	var r := _simulate(_sea, -20.0, 0.0, 20.0)
	assert_gt(SURFACE - float(r[3]), SwimRules.CHEST + 0.05, "the highest the feet came: still swimming")


func test_a_jump_into_deep_water_sinks_a_little_and_floats_back_up() -> void:
	var r := _simulate(_sea, SURFACE, -12.0, 8.0)
	assert_lt(SURFACE - float(r[2]), 3.0, "a 3 m jump stops within 3 blocks")
	assert_almost_eq(SURFACE - float(r[0]), SwimRules.FLOAT_DEPTH, 0.05, "and floats back to the surface")
	var fall := _simulate(_sea, SURFACE, -22.0, 8.0)
	assert_lt(SURFACE - float(fall[2]), 5.0, "even a 10 m fall stops within 5 blocks")


func test_jump_swims_up_faster_than_floating_but_never_out_of_the_water() -> void:
	var idle := _simulate(_sea, 5.0, 0.0, 1.5)
	var swim := _simulate(_sea, 5.0, 0.0, 1.5, true)
	assert_gt(float(swim[0]), float(idle[0]) + 1.0, "JUMP swims up")
	var held := _simulate(_sea, 5.0, 0.0, 10.0, true)
	assert_gt(SURFACE - float(held[3]), SwimRules.CHEST, "held at the surface, the chest stays in the water")
	assert_lt(SURFACE - float(held[0]), SwimRules.FLOAT_DEPTH, "a little higher than floating")


func test_down_dives() -> void:
	var start := SURFACE - SwimRules.FLOAT_DEPTH
	var r := _simulate(_sea, start, 0.0, 1.0, false, true)
	assert_lt(float(r[0]), start - 2.0, "DOWN dives")
	assert_almost_eq(float(r[1]), -SwimRules.DIVE_SPEED, 0.01)


func test_vertical_speeds_grow_with_the_body() -> void:
	assert_gt(SwimRules.vertical_target(1.0, 3.0, 1.7, false, true, 0.0), -SwimRules.DIVE_SPEED * 1.8)
	assert_lt(SwimRules.vertical_target(1.0, 3.0, 1.7, false, true, 0.0), -SwimRules.DIVE_SPEED * 1.6)
	assert_almost_eq(SwimRules.vertical_target(SwimRules.FLOAT_DEPTH * 3.0, 3.0, 1.7, false, false, 0.0), 0.0, 0.001,
		"a giant floats at its own float line")


# --- Swimming where you look ------------------------------------------------------------------

func test_pushing_forward_swims_level_with_the_resting_third_person_camera() -> void:
	var v := SwimRules.swim_velocity(Vector2(0, -1), 0.0, -0.35, 4.0)
	assert_almost_eq(v.y, 0.0, 0.001, "the camera looks down at the player: still level")
	assert_almost_eq(v.z, -4.0, 0.001, "forward is -Z")
	assert_almost_eq(v.x, 0.0, 0.001)


func test_looking_down_and_pushing_forward_dives_and_looking_up_rises() -> void:
	var down := SwimRules.swim_velocity(Vector2(0, -1), 0.0, CameraRig.PITCH_MIN, 4.0)
	assert_lt(down.y, -3.5, "straight down the look")
	assert_almost_eq(down.length(), 4.0, 0.001, "at swim speed")
	var half := SwimRules.swim_velocity(Vector2(0, -1), 0.0, -0.9, 4.0)
	assert_between(half.y, down.y, -0.5, "a gentler look dives gently")
	var up := SwimRules.swim_velocity(Vector2(0, -1), 0.0, CameraRig.PITCH_MAX, 4.0)
	assert_gt(up.y, 3.5)


func test_sideways_and_standing_still_never_dive() -> void:
	assert_almost_eq(SwimRules.swim_velocity(Vector2(1, 0), 0.0, CameraRig.PITCH_MIN, 4.0).y, 0.0, 0.001)
	assert_eq(SwimRules.swim_velocity(Vector2.ZERO, 0.0, CameraRig.PITCH_MIN, 4.0), Vector3.ZERO)


func test_swimming_follows_the_camera_yaw() -> void:
	var v := SwimRules.swim_velocity(Vector2(0, -1), -PI / 2.0, 0.0, 4.0)
	assert_almost_eq(v.x, 4.0, 0.001, "yaw -90 degrees: forward is +X")


func test_looking_up_at_the_surface_stays_at_the_surface() -> void:
	assert_lte(SwimRules.vertical_target(SwimRules.FLOAT_DEPTH, 1.0, 1.0, false, false, 3.0), 0.01)
	assert_almost_eq(SwimRules.vertical_target(6.0, 1.0, 1.0, false, false, 3.0), 3.0, 0.001, "deep: swims up the look")
	assert_almost_eq(SwimRules.vertical_target(SwimRules.FLOAT_DEPTH, 1.0, 1.0, false, false, -2.5), -2.5, 0.001,
		"looking down dives from the surface")


# --- Climbing out -----------------------------------------------------------------------------

func _at_surface(x: float) -> Vector3:
	return Vector3(x, SURFACE - SwimRules.FLOAT_DEPTH, 0.5)


func test_pushing_against_a_one_block_bank_climbs_out() -> void:
	var top := SwimRules.climb_target(_at_surface(19.5), Vector3.RIGHT, 0.3, 2, SURFACE, 1.0, _solid_in(_pool))
	assert_eq(top, 14.0, "onto the bank, 1 block above the water")


func test_a_shelf_under_the_surface_and_a_bank_level_with_the_water_are_climbed_too() -> void:
	var shelf := SwimRules.climb_target(_at_surface(4.5), Vector3.LEFT, 0.3, 2, SURFACE, 1.0, _solid_in(_pool))
	assert_eq(shelf, 12.0, "onto the shallow shelf (then wading)")
	var level := func(p: Vector3i) -> int: return BlockIds.STONE if p.x == 3 and p.y == 12 else _pool(p)
	var beach := SwimRules.climb_target(_at_surface(4.5), Vector3.LEFT, 0.3, 2, SURFACE, 1.0, _solid_in(level))
	assert_eq(beach, 13.0, "onto a beach level with the water")


func test_a_two_block_wall_is_not_climbed() -> void:
	var wall := func(p: Vector3i) -> int: return BlockIds.STONE if p.x == 20 and p.y == 14 else _pool(p)
	assert_true(is_nan(SwimRules.climb_target(_at_surface(19.5), Vector3.RIGHT, 0.3, 2, SURFACE, 1.0, _solid_in(wall))))


func test_no_climb_without_pushing_or_deep_under_or_without_head_room() -> void:
	var solid := _solid_in(_pool)
	assert_true(is_nan(SwimRules.climb_target(_at_surface(19.5), Vector3.ZERO, 0.3, 2, SURFACE, 1.0, solid)), "not pushing")
	assert_true(is_nan(SwimRules.climb_target(_at_surface(19.5), Vector3.LEFT, 0.3, 2, SURFACE, 1.0, solid)), "pushing away")
	assert_true(is_nan(SwimRules.climb_target(Vector3(19.5, 10.2, 0.5), Vector3.RIGHT, 0.3, 2, SURFACE, 1.0, solid)),
		"deep under the surface: swim up first")
	var roof := func(p: Vector3i) -> int: return BlockIds.STONE if p == Vector3i(19, 15, 0) else _pool(p)
	assert_true(is_nan(SwimRules.climb_target(_at_surface(19.5), Vector3.RIGHT, 0.3, 2, SURFACE, 1.0, _solid_in(roof))),
		"no room to rise")


# --- Owner feedback #30: "i cannt get from water without filying" ------------------------------------

func test_up_and_a_push_climb_a_two_block_wall_but_never_a_three_block_one() -> void:
	var two := func(p: Vector3i) -> int: return BlockIds.STONE if p.x == 20 and p.y == 14 else _pool(p)
	var three := func(p: Vector3i) -> int: return BlockIds.STONE if p.x == 20 and p.y in [14, 15] else _pool(p)
	var lifted := Vector3(19.5, SURFACE - SwimRules.LIFT_DEPTH, 0.5)
	assert_eq(SwimRules.climb_target(lifted, Vector3.RIGHT, 0.3, 2, SURFACE, 1.0, _solid_in(two), true), 15.0,
		"UP and a push: over a wall 2 blocks above the water")
	assert_true(is_nan(SwimRules.climb_target(lifted, Vector3.RIGHT, 0.3, 2, SURFACE, 1.0, _solid_in(three), true)),
		"never a 3-block wall")
	assert_true(is_nan(SwimRules.climb_target(lifted, Vector3.RIGHT, 0.3, 2, SURFACE, 1.0, _solid_in(two))),
		"without UP a 2-block wall stays a wall")


## The owner's river: 2 deep at the bank, a child who looks down while swimming at the bank sinks to the
## bottom (the look dives), where the feet are 2 blocks under the surface.
func test_a_bank_is_felt_from_the_bottom_of_a_river_but_the_climb_starts_near_the_surface() -> void:
	var river := func(p: Vector3i) -> int: return BlockIds.STONE if p.y <= 10 and p.x < 20 else _pool(p)
	var bottom := Vector3(19.7, SURFACE - 2.0, 0.5)
	assert_true(is_nan(SwimRules.climb_target(bottom, Vector3.RIGHT, 0.3, 2, SURFACE, 1.0, _solid_in(river))),
		"on the bottom the climb does not start")
	assert_eq(SwimRules.climb_target(bottom, Vector3.RIGHT, 0.3, 2, SURFACE, 1.0, _solid_in(river), false,
		SwimRules.BANK_DEPTH), 14.0, "but the bank is felt, so the swimmer floats up to it")


func test_climb_out_follows_the_push_or_with_up_alone_the_view_or_any_side() -> void:
	var solid := _solid_in(_pool)
	var near := _at_surface(19.5)
	var push := SwimRules.climb_out(near, Vector3.RIGHT, false, false, Vector3.FORWARD, 0.3, 2, SURFACE, 1.0, solid)
	assert_eq(push, {"top": 14.0, "dir": Vector3.RIGHT}, "pushing at the bank")
	var up_view := SwimRules.climb_out(near, Vector3.ZERO, true, false, Vector3.RIGHT, 0.3, 2, SURFACE, 1.0, solid)
	assert_eq(up_view, {"top": 14.0, "dir": Vector3.RIGHT}, "UP alone, looking at the bank")
	var up_side := SwimRules.climb_out(near, Vector3.ZERO, true, false, Vector3.FORWARD, 0.3, 2, SURFACE, 1.0, solid)
	assert_eq(up_side, {"top": 14.0, "dir": Vector3.RIGHT}, "UP alone, the bank beside the body")
	assert_eq(SwimRules.climb_out(near, Vector3.ZERO, false, false, Vector3.RIGHT, 0.3, 2, SURFACE, 1.0, solid), {},
		"neither pushing nor UP: stays in the water")
	assert_eq(SwimRules.climb_out(_at_surface(12.5), Vector3.ZERO, true, false, Vector3.RIGHT, 0.3, 2, SURFACE, 1.0, solid), {},
		"UP in open water only swims up")
	assert_eq(SwimRules.climb_out(near, Vector3.RIGHT, false, true, Vector3.RIGHT, 0.3, 2, SURFACE, 1.0, solid), {},
		"DOWN held dives, never climbs")


# --- Splash, pose and tilt --------------------------------------------------------------------

func test_the_splash_grows_with_the_entry_speed() -> void:
	var walk := SwimRules.splash_strength(Vector3(6.0, 0.0, 0.0))
	var jump := SwimRules.splash_strength(Vector3(2.0, -9.0, 0.0))
	var dive := SwimRules.splash_strength(Vector3(0.0, -20.0, 0.0))
	assert_gt(walk, SwimRules.SPLASH_MIN, "running in splashes a little")
	assert_gt(jump, walk)
	assert_gt(dive, jump)
	assert_lte(dive, 1.0)
	assert_eq(SwimRules.splash_strength(Vector3(0.0, -60.0, 0.0)), 1.0, "capped")
	assert_lt(SwimRules.splash_strength(Vector3(1.0, 0.0, 0.0)), SwimRules.SPLASH_MIN, "wading in slowly: no splash")


func test_the_swim_pose_is_only_for_swimming_on_foot() -> void:
	assert_true(SwimRules.swim_pose(PhysicsMode.Mode.NORMAL, SwimRules.State.SWIMMING, false))
	assert_true(SwimRules.swim_pose(PhysicsMode.Mode.NORMAL, SwimRules.State.DIVING, false))
	assert_false(SwimRules.swim_pose(PhysicsMode.Mode.NORMAL, SwimRules.State.WADING, false))
	assert_false(SwimRules.swim_pose(PhysicsMode.Mode.NORMAL, SwimRules.State.DRY, false))
	assert_false(SwimRules.swim_pose(PhysicsMode.Mode.FLY, SwimRules.State.SWIMMING, false), "flying through water")
	assert_false(SwimRules.swim_pose(PhysicsMode.Mode.NORMAL, SwimRules.State.SWIMMING, true), "asleep")


func test_the_body_tips_with_the_swim_direction() -> void:
	assert_lt(SwimRules.body_tilt(0.0, 0.0), 0.3, "treading water: upright")
	assert_almost_eq(SwimRules.body_tilt(3.0, 0.0), PI / 2.0, 0.01, "swimming along: flat")
	assert_gt(SwimRules.body_tilt(0.0, -3.0), 2.8, "diving down: head first")
	assert_lt(SwimRules.body_tilt(0.0, 2.0), 0.3, "floating up: upright")
	assert_between(SwimRules.body_tilt(2.0, -2.0), PI / 2.0 + 0.5, PI - 0.5, "diving at an angle")
