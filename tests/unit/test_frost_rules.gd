extends GutTest
## M3 Task 3 (spec §14.1 "ice lakes (slippery)"): how slippery Frostpeak's ground is, as a pure rule every
## walker uses (players, animals, monsters): on ice a body speeds up and stops slowly (it slides), on blue
## ice even more; everywhere else nothing changes. The Frost Giant's stomp makes the ground icy for a few
## seconds (IcyGround): a state everyone's game keeps, never a changed block.

func after_each() -> void:
	IcyGround.clear()


func test_ice_is_slippery_and_nothing_else_is() -> void:
	assert_lt(FrostRules.grip(BlockIds.ICE), 0.3, "ice")
	assert_lt(FrostRules.grip(BlockIds.BLUE_ICE), FrostRules.grip(BlockIds.ICE), "blue ice is even more slippery")
	assert_gt(FrostRules.grip(BlockIds.BLUE_ICE), 0.0, "never no grip at all: a child can always steer a little")
	for id in [BlockIds.STONE, BlockIds.GRASS, BlockIds.SNOW, BlockIds.SNOWY_GRASS, BlockIds.PACKED_SNOW, BlockIds.SAND,
			BlockIds.AIR, BlockIds.WATER]:
		assert_eq(FrostRules.grip(id), 1.0, BlockIds.display_name(id))


func test_the_block_under_the_feet_decides() -> void:
	var ice := func(c: Vector3i) -> int: return BlockIds.ICE if c.y == 9 else BlockIds.AIR
	assert_eq(FrostRules.floor_cell(Vector3(3.5, 10.0, -2.5)), Vector3i(3, 9, -3))
	assert_almost_eq(FrostRules.grip_at(Vector3(3.5, 10.0, -2.5), ice), FrostRules.grip(BlockIds.ICE), 0.0001)
	assert_eq(FrostRules.grip_at(Vector3(3.5, 12.0, -2.5), ice), 1.0, "in the air: its own air control")


## A child who lets go on ice slides several blocks; on stone they stop at once.
func test_stopping_takes_longer_on_ice() -> void:
	var stone := FrostRules.stop_distance(6.0, 45.0, 1.0)
	var ice := FrostRules.stop_distance(6.0, 45.0, FrostRules.grip(BlockIds.ICE))
	assert_lt(stone, 0.5)
	assert_between(ice, 2.0, 5.0, "a slide a child can see, not a ride across the lake")
	assert_gt(FrostRules.stop_distance(6.0, 45.0, FrostRules.grip(BlockIds.BLUE_ICE)), ice)


## The Frost Giant's stomp: icy ground round it for a few seconds, then it is gone. Never a block.
func test_icy_ground_from_a_stomp_lasts_a_few_seconds() -> void:
	var at := Vector3(10, 20, 10)
	IcyGround.add(at, 8.0, 4.0, 100.0)
	assert_lt(IcyGround.grip_at(at + Vector3(5, 0, 0), 101.0), 0.5, "slippery inside the ring")
	assert_eq(IcyGround.grip_at(at + Vector3(9, 0, 0), 101.0), 1.0, "not outside it")
	assert_eq(IcyGround.grip_at(at + Vector3(0, 4, 0), 101.0), 1.0, "not up on a tower")
	assert_eq(IcyGround.grip_at(at, 104.5), 1.0, "melted after 4 s")
	assert_true(IcyGround.active(101.0))
	assert_false(IcyGround.active(105.0))
	var ground := func(c: Vector3i) -> int: return BlockIds.STONE if c.y < 20 else BlockIds.AIR
	IcyGround.add(at, 8.0, 4.0, 200.0)
	assert_almost_eq(FrostRules.grip_at(at, ground, 201.0), IcyGround.ICY_GRIP, 0.0001, "the icy ground counts where you stand")
