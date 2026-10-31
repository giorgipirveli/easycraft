extends GutTest
## M3 Task 10: where a Gold Farm stands (FarmSite). The child taps the ground like a stamp: the farm's
## front row is the tapped cell, it reaches away from the child, its barn door faces them. It needs flat,
## open ground (one-block dips are filled); "inside" is anywhere over its footprint.

const FLOOR := 30


## A flat world: ground up to FLOOR - 1, air above; `extra` overrides cells.
func _world(extra: Dictionary = {}) -> Callable:
	return func(p: Vector3i) -> int:
		if extra.has(p):
			return extra[p]
		return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func test_the_farm_reaches_away_from_the_child_and_faces_them() -> void:
	var anchor := Vector3i(10, FLOOR, 5)
	for forward: Vector3i in [Vector3i(0, 0, -1), Vector3i(1, 0, 0), Vector3i(0, 0, 1), Vector3i(-1, 0, 0)]:
		var facing := FarmSite.facing_for_forward(forward)
		var door := FarmSite.door_dir(facing)
		assert_eq(Vector3i(door.x, 0, door.y), -forward, "the door looks back at the child")
		var c := FarmSite.center_for(anchor, facing)
		assert_eq(c - anchor, forward * FarmSite.HALF_D, "the tapped cell is the middle of the front row")
		assert_eq(c.y, FLOOR)


func test_the_footprint_is_9_by_7_turned_with_the_farm() -> void:
	var c := Vector3i(0, FLOOR, 0)
	assert_eq(FarmSite.cells(c, 0).size(), 63)
	var xs := {}
	var zs := {}
	for p: Vector2i in FarmSite.cells(c, 0):
		xs[p.x] = true
		zs[p.y] = true
	assert_eq(xs.size(), 9)
	assert_eq(zs.size(), 7)
	xs.clear()
	zs.clear()
	for p: Vector2i in FarmSite.cells(c, 1):
		xs[p.x] = true
		zs[p.y] = true
	assert_eq(xs.size(), 7, "turned a quarter: 7 along x")
	assert_eq(zs.size(), 9)


func test_local_and_world_turn_back_and_forth() -> void:
	var c := Vector3i(4, FLOOR, -9)
	for facing in 4:
		for local: Vector2i in [Vector2i(3, -2), Vector2i(-4, 3), Vector2i(0, 0)]:
			var w := FarmSite.to_world_cell(c, facing, local)
			var back := FarmSite.to_local(c, facing, Vector3(w.x + 0.5, FLOOR, w.y + 0.5))
			assert_almost_eq(Vector2(back.x, back.z), Vector2(local), Vector2(0.001, 0.001), "facing %d" % facing)
	var door := FarmSite.door_dir(1)
	var front := FarmSite.to_world_cell(c, 1, Vector2i(0, FarmSite.HALF_D))
	assert_eq(front, Vector2i(c.x, c.z) + door * FarmSite.HALF_D, "local +Z is the door's side")


func test_flat_open_ground_takes_a_farm() -> void:
	var c := FarmSite.center_for(Vector3i(0, FLOOR, 0), 0)
	for facing in 4:
		assert_eq(FarmSite.refusal(c, facing, _world()), "", "facing %d" % facing)


func test_a_one_block_dip_is_filled_but_a_hole_is_not() -> void:
	var c := Vector3i(0, FLOOR, 0)
	var dip := {Vector3i(2, FLOOR - 1, 1): BlockIds.AIR}
	assert_eq(FarmSite.refusal(c, 0, _world(dip)), "", "one block lower: the plinth fills it")
	var hole := {Vector3i(2, FLOOR - 1, 1): BlockIds.AIR, Vector3i(2, FLOOR - 2, 1): BlockIds.AIR}
	assert_eq(FarmSite.refusal(c, 0, _world(hole)), "farm_ground")
	var pond := {Vector3i(-3, FLOOR - 1, 0): BlockIds.WATER}
	assert_eq(FarmSite.refusal(c, 0, _world(pond)), "farm_ground", "never on water")


func test_a_bump_or_a_tree_in_the_way_says_no() -> void:
	var c := Vector3i(0, FLOOR, 0)
	assert_eq(FarmSite.refusal(c, 0, _world({Vector3i(3, FLOOR, 2): BlockIds.STONE})), "farm_room", "a bump")
	var barn := FarmSite.to_world_cell(c, 0, Vector2i(-2, -1))
	assert_eq(FarmSite.refusal(c, 0, _world({Vector3i(barn.x, FLOOR + 5, barn.y): BlockIds.LEAVES})), "farm_room",
		"leaves where the barn's roof goes")
	var field := FarmSite.to_world_cell(c, 0, Vector2i(3, 0))
	assert_eq(FarmSite.refusal(c, 0, _world({Vector3i(field.x, FLOOR + 4, field.y): BlockIds.LEAVES})), "",
		"a branch high over the field is fine")
	assert_eq(FarmSite.refusal(c, 0, _world({Vector3i(field.x, FLOOR, field.y): BlockIds.BUSH})), "",
		"a bush is walked through")


func test_just_outside_the_footprint_does_not_matter() -> void:
	var c := Vector3i(0, FLOOR, 0)
	var w := FarmSite.to_world_cell(c, 0, Vector2i(FarmSite.HALF_W + 1, 0))
	assert_eq(FarmSite.refusal(c, 0, _world({Vector3i(w.x, FLOOR, w.y): BlockIds.STONE})), "")


func test_inside_is_anywhere_over_the_footprint() -> void:
	var farm := FarmRules.new_farm(Vector3i(20, FLOOR, 7), 1)
	var mid := Vector3(20.5, FLOOR, 7.5)
	assert_true(FarmSite.is_inside(farm, mid))
	assert_true(FarmSite.is_inside(farm, mid + Vector3(0, 3, 0)), "up in the barn's loft")
	var corner := FarmSite.to_world_cell(farm.pos, 1, Vector2i(FarmSite.HALF_W, -FarmSite.HALF_D))
	assert_true(FarmSite.is_inside(farm, Vector3(corner.x + 0.9, FLOOR, corner.y + 0.1)), "the field's far corner")
	var out := FarmSite.to_world_cell(farm.pos, 1, Vector2i(FarmSite.HALF_W + 1, 0))
	assert_false(FarmSite.is_inside(farm, Vector3(out.x + 0.5, FLOOR, out.y + 0.5)), "one step past the field")
	assert_false(FarmSite.is_inside(farm, mid + Vector3(0, 12, 0)), "flying high over it")
	assert_false(FarmSite.is_inside(farm, mid + Vector3(0, -4, 0)), "in a cave under it")
	assert_false(FarmSite.is_inside({}, mid))
	assert_false(FarmSite.is_inside(farm, Vector3.INF))


func test_the_barn_and_the_field() -> void:
	assert_true(FarmSite.is_barn(Vector2i(-2, -1)))
	assert_false(FarmSite.is_barn(Vector2i(3, 0)), "the field")
	assert_false(FarmSite.is_barn(Vector2i(-2, FarmSite.HALF_D)), "the yard in front of the door")
