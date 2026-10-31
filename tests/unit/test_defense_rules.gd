extends GutTest
## M2 Task 8 (spec §12.6): doors, spike traps and lanterns as pure rules. A door is one block; a tap
## opens or closes the whole stack of doors it belongs to (a doorway is two doors). Monsters never
## step up onto or hop over a closed door. A spike trap hurts a monster standing on it or in it 2 a
## second. Monsters of level 2 or less keep 6 blocks from a lantern; stronger ones don't care.

const FLOOR := 10


## A small world: ground below FLOOR, and the cells in `cells`.
static func _world(cells: Dictionary) -> Callable:
	return func(p: Vector3i) -> int:
		if cells.has(p):
			return cells[p]
		return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


# --- Doors ------------------------------------------------------------------------------------------

func test_a_door_toggles_between_closed_and_open() -> void:
	assert_eq(DefenseRules.toggled(BlockIds.DOOR), BlockIds.DOOR_OPEN)
	assert_eq(DefenseRules.toggled(BlockIds.DOOR_OPEN), BlockIds.DOOR)
	assert_eq(DefenseRules.toggled(BlockIds.STONE), BlockIds.STONE, "only doors toggle")
	assert_true(DefenseRules.is_door(BlockIds.DOOR))
	assert_true(DefenseRules.is_door(BlockIds.DOOR_OPEN))
	assert_false(DefenseRules.is_door(BlockIds.PLANKS))


func test_a_tap_toggles_the_whole_stack_of_doors() -> void:
	var at := Vector3i(3, FLOOR, 4)
	var block_at := _world({at: BlockIds.DOOR, at + Vector3i.UP: BlockIds.DOOR, at + Vector3i(0, 2, 0): BlockIds.PLANKS})
	assert_eq(DefenseRules.door_stack(at + Vector3i.UP, block_at), [at, at + Vector3i.UP] as Array[Vector3i],
		"from the bottom up, whichever half was tapped")
	assert_eq(DefenseRules.toggle_changes(at, block_at), [[at, BlockIds.DOOR_OPEN], [at + Vector3i.UP, BlockIds.DOOR_OPEN]])


func test_a_half_open_stack_follows_the_tapped_door() -> void:
	var at := Vector3i(0, FLOOR, 0)
	var block_at := _world({at: BlockIds.DOOR_OPEN, at + Vector3i.UP: BlockIds.DOOR})
	assert_eq(DefenseRules.toggle_changes(at + Vector3i.UP, block_at), [[at, BlockIds.DOOR_OPEN], [at + Vector3i.UP, BlockIds.DOOR_OPEN]])
	assert_eq(DefenseRules.toggle_changes(at, block_at), [[at, BlockIds.DOOR], [at + Vector3i.UP, BlockIds.DOOR]])


func test_a_stack_is_at_most_three_doors_and_always_holds_the_tapped_one() -> void:
	var cells := {}
	for y in 6:
		cells[Vector3i(0, FLOOR + y, 0)] = BlockIds.DOOR
	var block_at := _world(cells)
	for y in 6:
		var tapped := Vector3i(0, FLOOR + y, 0)
		var stack := DefenseRules.door_stack(tapped, block_at)
		assert_lte(stack.size(), DefenseRules.MAX_DOOR_STACK)
		assert_has(stack, tapped)


func test_something_that_is_not_a_door_has_no_stack() -> void:
	var block_at := _world({})
	assert_eq(DefenseRules.door_stack(Vector3i(0, FLOOR, 0), block_at), [] as Array[Vector3i])
	assert_eq(DefenseRules.toggle_changes(Vector3i(0, FLOOR - 1, 0), block_at), [])


## Monsters never step up onto a closed door or hop over it (an open door is a way in).
func test_a_closed_door_in_the_way_is_seen_and_an_open_one_is_not() -> void:
	var door := Vector3i(2, FLOOR, 0)
	var feet := Vector3(0.5, FLOOR, 0.5)
	assert_true(DefenseRules.door_in_way(feet, Vector3.RIGHT, 2.0, 0.3, _world({door: BlockIds.DOOR})))
	assert_false(DefenseRules.door_in_way(feet, Vector3.RIGHT, 2.0, 0.3, _world({door: BlockIds.DOOR_OPEN})), "open")
	assert_false(DefenseRules.door_in_way(feet, Vector3.LEFT, 2.0, 0.3, _world({door: BlockIds.DOOR})), "behind it")
	assert_false(DefenseRules.door_in_way(feet, Vector3.RIGHT, 1.0, 0.3, _world({door: BlockIds.DOOR})), "out of reach")
	assert_false(DefenseRules.door_in_way(feet, Vector3.ZERO, 2.0, 0.3, _world({door: BlockIds.DOOR})), "not moving")


func test_a_door_brushed_by_the_side_of_the_body_counts() -> void:
	var door := Vector3i(1, FLOOR, 1)
	var feet := Vector3(0.5, FLOOR, 0.75)
	var block_at := _world({door: BlockIds.DOOR})
	assert_true(DefenseRules.door_in_way(feet, Vector3.RIGHT, 1.0, 0.35, block_at), "the right side touches it")
	assert_false(DefenseRules.door_in_way(feet, Vector3.RIGHT, 1.0, 0.1, block_at), "a thin body passes")


## Universe 6's crowd (2026-10-18): a big monster pressed against the wall beside a doorway looks along the wall a
## block and more to each side (Monster._door_at_wall); every cell between its sides counts, not only the middle and the
## two edges (the door right next to it was skipped, and it hopped up beside it).
func test_a_door_between_the_middle_and_the_side_counts() -> void:
	var cells := {Vector3i(5, FLOOR, 0): BlockIds.DOOR}
	for z in [-2, -1, 1, 2]:
		cells[Vector3i(5, FLOOR, z)] = BlockIds.PLANKS
	var feet := Vector3(4.48, FLOOR, -0.18)
	assert_true(DefenseRules.door_in_way(feet, Vector3.RIGHT, 1.05, 1.45, _world(cells)), "the door beside it in the wall")


## ... and one that came down with a sliver of its body on a door's top still sees the door under its feet (it stepped
## up from there over the wall).
func test_a_door_under_the_edge_of_the_feet_counts() -> void:
	var door := Vector3i(5, FLOOR, 0)
	var feet := Vector3(4.56, FLOOR + 1, -0.02)
	assert_true(DefenseRules.door_in_way(feet, Vector3(0.46, 0.0, -0.89), 1.05, 0.45, _world({door: BlockIds.DOOR})),
		"the door it stands on the edge of")
	assert_false(DefenseRules.door_in_way(feet, Vector3(0.46, 0.0, -0.89), 1.05, 0.45, _world({})), "no door: free to step")


func test_a_door_one_block_up_is_part_of_a_wall_not_a_step() -> void:
	var feet := Vector3(0.5, FLOOR, 0.5)
	assert_false(DefenseRules.door_in_way(feet, Vector3.RIGHT, 2.0, 0.3, _world({Vector3i(1, FLOOR + 1, 0): BlockIds.DOOR})))


# --- Spike traps --------------------------------------------------------------------------------------

func test_a_trap_under_the_feet_or_around_them_is_found() -> void:
	var trap := Vector3i(4, FLOOR - 1, 4)
	var block_at := _world({trap: BlockIds.SPIKE_TRAP})
	assert_eq(DefenseRules.trap_under(Vector3(4.5, FLOOR, 4.5), block_at), trap, "standing on it")
	assert_eq(DefenseRules.trap_under(Vector3(4.5, FLOOR - 0.001, 4.5), block_at), trap, "a hair low")
	assert_eq(DefenseRules.trap_under(Vector3(4.5, FLOOR - 0.6, 4.5), block_at), trap, "in it")
	assert_eq(DefenseRules.trap_under(Vector3(5.5, FLOOR, 4.5), block_at), DefenseRules.NO_TRAP, "next to it")
	assert_eq(DefenseRules.trap_under(Vector3(4.5, FLOOR + 1.5, 4.5), block_at), DefenseRules.NO_TRAP, "above it")


func test_a_trap_hurts_2_a_second_from_the_first_step() -> void:
	assert_eq(DefenseRules.TRAP_DAMAGE, 2)
	var cooldown := 0.0
	var hits := 0
	for i in 100:                      # 10 s at 10 checks a second
		var r := DefenseRules.trap_tick(cooldown, true, 0.1)
		cooldown = r.cooldown
		hits += 1 if r.hit else 0
		if i == 0:
			assert_true(r.hit, "at once")
	assert_eq(hits * DefenseRules.TRAP_DAMAGE, 20, "2 per second")


func test_hopping_off_and_on_never_hurts_faster() -> void:
	var cooldown := 0.0
	var hits := 0
	for i in 100:
		var r := DefenseRules.trap_tick(cooldown, i % 2 == 0, 0.1)
		cooldown = r.cooldown
		hits += 1 if r.hit else 0
	assert_eq(hits, 10)
	var off := DefenseRules.trap_tick(0.0, false, 0.1)
	assert_false(off.hit, "nothing off the trap")


# --- Lanterns ----------------------------------------------------------------------------------------

func test_only_monsters_of_level_2_or_less_fear_lanterns() -> void:
	assert_true(DefenseRules.fears_lanterns(1))
	assert_true(DefenseRules.fears_lanterns(2))
	for level in [3, 4, 5]:
		assert_false(DefenseRules.fears_lanterns(level), str(level))
	assert_eq(DefenseRules.LANTERN_KEEP_AWAY, 6.0)


func test_a_weak_monster_stops_before_it_comes_within_6_blocks() -> void:
	var lantern: Array[Vector3i] = [Vector3i(10, FLOOR, 0)]
	var at := Vector3(3.6, FLOOR, 0.5)      # 6.9 from the lantern's middle
	assert_eq(DefenseRules.lantern_dir(at, Vector3.RIGHT, 1, lantern, 1.0), Vector3.ZERO, "one more step is too close")
	assert_eq(DefenseRules.lantern_dir(at, Vector3.LEFT, 1, lantern, 1.0), Vector3.LEFT, "going away is fine")
	assert_eq(DefenseRules.lantern_dir(at + Vector3.LEFT * 3.0, Vector3.RIGHT, 2, lantern, 1.0), Vector3.RIGHT, "far enough")


func test_a_weak_monster_already_close_goes_away() -> void:
	var lantern: Array[Vector3i] = [Vector3i(0, FLOOR, 0), Vector3i(40, FLOOR, 0)]
	var dir := DefenseRules.lantern_dir(Vector3(3.5, FLOOR, 0.5), Vector3.LEFT, 2, lantern, 1.0)
	assert_almost_eq(dir.x, 1.0, 0.001, "straight away from the lantern")
	assert_almost_eq(dir.y, 0.0, 0.001)
	var still := DefenseRules.lantern_dir(Vector3(0.5, FLOOR, 3.5), Vector3.ZERO, 1, lantern, 1.0)
	assert_almost_eq(still.z, 1.0, 0.001, "even one that was standing still")


func test_strong_monsters_ignore_lanterns() -> void:
	var lantern: Array[Vector3i] = [Vector3i(0, FLOOR, 0)]
	assert_eq(DefenseRules.lantern_dir(Vector3(2.5, FLOOR, 0.5), Vector3.LEFT, 3, lantern, 1.0), Vector3.LEFT)
	assert_eq(DefenseRules.lantern_dir(Vector3(2.5, FLOOR, 0.5), Vector3.ZERO, 5, lantern, 1.0), Vector3.ZERO)


func test_the_nearest_lanterns_come_first() -> void:
	var cells: Array[Vector3i] = [Vector3i(10, 0, 0), Vector3i(1, 0, 0), Vector3i(-5, 0, 0), Vector3i(0, 30, 0)]
	assert_eq(DefenseRules.nearest(Vector3.ZERO, cells, 2), [Vector3i(1, 0, 0), Vector3i(-5, 0, 0)] as Array[Vector3i])
	assert_eq(DefenseRules.nearest(Vector3.ZERO, cells, 9).size(), 4)
	assert_eq(DefenseRules.nearest(Vector3.ZERO, [] as Array[Vector3i], 2), [] as Array[Vector3i])
