extends GutTest
## Beds (M1b Task 10): when a player may lie down, finding the bed next to the player, skipping the
## night only when every player sleeps, and home (the last bed slept in, or the world spawn).

const BED := Vector3i(10, 40, 5)
const SPAWN := Vector2i(3, -7)


func _check(overrides: Dictionary = {}) -> String:
	var a := {"bed_id": BlockIds.BED, "feet": Vector3(11.5, 40.0, 5.5), "on_floor": true, "in_water": false,
		"above": BlockIds.AIR, "mode": PhysicsMode.Mode.NORMAL, "taken": false}
	a.merge(overrides, true)
	return BedRules.check(a.bed_id, BED, a.feet, a.on_floor, a.in_water, a.above, a.mode, a.taken)


func test_can_sleep_standing_next_to_a_bed() -> void:
	assert_eq(_check(), "")
	assert_eq(_check({"feet": Vector3(10.5, 40.5625, 5.5)}), "", "or standing on it")


func test_needs_a_bed() -> void:
	assert_eq(_check({"bed_id": BlockIds.PLANKS}), "no_bed")
	assert_eq(_check({"bed_id": BlockIds.AIR}), "no_bed")


func test_the_bed_must_be_within_reach() -> void:
	assert_eq(_check({"feet": Vector3(10.5 + BedRules.REACH + 1.0, 40.0, 5.5)}), "too_far")
	var just_beyond := Vector3(10.5 + BedRules.REACH + 0.3, 40.0, 5.5)
	assert_eq(_check({"feet": just_beyond}), "too_far")
	assert_eq(BedRules.check(BlockIds.BED, BED, just_beyond, true, false, BlockIds.AIR, PhysicsMode.Mode.NORMAL, false,
		BedRules.REACH + BedRules.REACH_TOLERANCE), "", "the host allows a little network slack")


func test_not_while_flying_jumping_or_swimming() -> void:
	assert_eq(_check({"mode": PhysicsMode.Mode.FLY}), "flying")
	assert_eq(_check({"mode": PhysicsMode.Mode.GHOST}), "flying")
	assert_eq(_check({"on_floor": false}), "not_on_floor")
	assert_eq(_check({"in_water": true}), "in_water")


func test_needs_room_above_the_bed() -> void:
	assert_eq(_check({"above": BlockIds.STONE}), "no_room")
	assert_eq(_check({"above": BlockIds.WATER}), "no_room")


func test_one_sleeper_per_bed() -> void:
	assert_eq(_check({"taken": true}), "taken")


func test_every_refusal_has_a_friendly_message() -> void:
	for code in ["no_bed", "too_far", "flying", "not_on_floor", "in_water", "no_room", "taken"]:
		assert_ne(BedRules.message(code), "", code)


func test_finds_the_nearest_bed_within_reach() -> void:
	var beds := {Vector3i(2, 10, 0): true, Vector3i(-1, 9, 1): true, Vector3i(9, 10, 0): true}
	var get_block := func(p: Vector3i) -> int: return BlockIds.BED if beds.has(p) else BlockIds.AIR
	assert_eq(BedRules.find_bed(Vector3(0.5, 10.0, 0.5), get_block), Vector3i(-1, 9, 1), "the nearest one")
	assert_eq(BedRules.find_bed(Vector3(7.5, 10.0, 0.5), get_block), Vector3i(9, 10, 0))
	assert_eq(BedRules.find_bed(Vector3(20.5, 10.0, 0.5), get_block), BedRules.NO_BED, "none in reach")


func test_lies_on_top_of_the_bed() -> void:
	assert_eq(BedRules.lie_position(BED), Vector3(10.5, 40.0 + BedRules.TOP, 5.5))
	assert_between(BedRules.TOP, 0.5, 0.7, "a half-height block with a mattress")


func test_time_skips_only_when_every_player_sleeps() -> void:
	assert_true(BedRules.all_asleep([1], {1: BED}), "solo")
	assert_false(BedRules.all_asleep([1, 2], {1: BED}), "one sleeper never skips the night for everyone")
	assert_true(BedRules.all_asleep([1, 2], {1: BED, 2: Vector3i(0, 40, 0)}))
	assert_false(BedRules.all_asleep([1], {}))
	assert_false(BedRules.all_asleep([], {}), "nobody here")
	assert_eq(BedRules.asleep_count([1, 2, 3], {1: BED, 3: BED}), 2)


func test_players_who_left_never_block_the_skip() -> void:
	assert_true(BedRules.all_asleep([1], {1: BED, 7: Vector3i(0, 40, 0)}), "a sleeper who left does not matter")
	assert_false(BedRules.all_asleep([1], {7: BED}), "and does not count as asleep either")
	assert_eq(BedRules.asleep_count([1], {1: BED, 7: BED}), 1)


func test_breaking_a_bed_clears_every_home_on_it() -> void:
	var homes := {1: BED, 2: BED, 3: Vector3i(0, 40, 0)}
	var lost := BedRules.lost_homes(homes, BED, BlockIds.AIR)
	lost.sort()
	assert_eq(lost, [1, 2])
	assert_eq(BedRules.lost_homes(homes, BED, BlockIds.BED), [], "still a bed")
	assert_eq(BedRules.lost_homes(homes, Vector3i(5, 5, 5), BlockIds.AIR), [], "not anybody's bed")


func test_home_is_the_bed_or_the_world_spawn_when_it_is_gone() -> void:
	var open_air := func(_p: Vector3i) -> int: return BlockIds.AIR
	var home := BedRules.home_target(true, BED, BlockIds.BED, SPAWN, open_air)
	assert_eq(home, BedRules.home_position(BED))
	assert_gt(home.y, BED.y + BedRules.TOP, "above the mattress")
	var gone := BedRules.home_target(true, BED, BlockIds.AIR, SPAWN, open_air)
	assert_eq(Vector2(gone.x, gone.z), Vector2(3.5, -6.5), "the world spawn column")
	assert_true(is_nan(gone.y), "on the surface there")
	assert_true(is_nan(BedRules.home_target(false, BED, BlockIds.BED, SPAWN, open_air).y), "no home yet: the world spawn")
	assert_eq(BedRules.home_target(true, BED, BedRules.UNLOADED, SPAWN, open_air), BedRules.home_position(BED),
		"a bed far away is checked on arrival")


## Review M5: a bed under a one-block-high ceiling (sleeping only needs one free cell) stood the
## sleeper up with the head in the ceiling. They step off the bed instead.
func test_waking_under_a_low_ceiling_steps_off_the_bed() -> void:
	var blocks := {}
	var at := func(p: Vector3i) -> int: return blocks.get(p, BlockIds.STONE if p.y < BED.y else BlockIds.AIR)
	blocks[BED] = BlockIds.BED
	assert_eq(BedRules.wake_position(BED, at), BedRules.lie_position(BED), "room to stand: up on the bed")
	blocks[BED + Vector3i(0, 2, 0)] = BlockIds.PLANKS                     # a low ceiling
	var off := BedRules.wake_position(BED, at)
	assert_eq(off.y, float(BED.y), "standing on the floor")
	assert_eq(Vector3i(off.floor()).distance_squared_to(BED), 1, "right beside the bed")
	for side: Vector3i in [Vector3i.FORWARD, Vector3i.BACK, Vector3i.LEFT, Vector3i.RIGHT]:
		blocks[BED + side + Vector3i.UP] = BlockIds.BRICK                  # walls all around
	assert_eq(BedRules.wake_position(BED, at), BedRules.lie_position(BED), "nowhere else: stay on the bed")


## The SLEEP button's scan reads one box (WorldService.box_reader): it must hold every cell
## find_bed looks at.
func test_the_scan_box_holds_every_cell_find_bed_reads() -> void:
	var feet := Vector3(10.3, 40.0, -5.8)
	var box: Array = BedRules.scan_box(feet)
	var origin: Vector3i = box[0]
	var size: Vector3i = box[1]
	var outside := []
	var at := func(p: Vector3i) -> int:
		var l := p - origin
		if l.x < 0 or l.y < 0 or l.z < 0 or l.x >= size.x or l.y >= size.y or l.z >= size.z:
			outside.append(p)
		return BlockIds.AIR
	BedRules.find_bed(feet, at)
	assert_eq(outside, [], "no cell outside the box")
	assert_lte(size.x * size.y * size.z, 7 * 4 * 7, "and the box is no bigger than the scan")


## Found by the acceptance tour (seed 777): a bed under an oak, leaves 2 blocks above it. Going home
## spawned at bed + 1 and the unstuck check lifted the player onto the canopy. Home is beside the bed
## then, like waking up.
func test_going_home_under_a_low_ceiling_lands_beside_the_bed() -> void:
	var blocks := {BED: BlockIds.BED, BED + Vector3i(0, 2, 0): BlockIds.LEAVES}
	var at := func(p: Vector3i) -> int: return blocks.get(p, BlockIds.STONE if p.y < BED.y else BlockIds.AIR)
	var home := BedRules.home_target(true, BED, BlockIds.BED, SPAWN, at)
	assert_eq(home.y, float(BED.y), "standing on the floor")
	assert_eq(Vector3i(home.floor()).distance_squared_to(BED), 1, "right beside the bed, not on the canopy")
