extends GutTest
## M2 Task 17 (research: pets help find secrets; spec §12.16 and the plan): a pet dog near an unopened
## buried treasure now and then runs a few blocks towards it, never far from its owner, and paws the
## ground right over it. It points the way; it never digs the block itself.

const OWNER := Vector3(0, 10, 0)


func test_a_far_treasure_is_not_sniffed() -> void:
	var chest := Vector3(TreasureSniff.RANGE + 5.0, 5, 0)
	assert_false(TreasureSniff.target(Vector3(1, 10, 0), chest, OWNER).is_finite())
	assert_false(TreasureSniff.target(Vector3(1, 10, 0), Vector3.INF, OWNER).is_finite(), "no treasure")


func test_the_dog_leads_a_few_blocks_towards_the_treasure() -> void:
	var dog := Vector3(1, 10, 0)
	var chest := Vector3(20, 5, 0)
	var t := TreasureSniff.target(dog, chest, OWNER)
	assert_true(t.is_finite())
	assert_almost_eq(Vector2(t.x - dog.x, t.z - dog.z).length(), TreasureSniff.STEP, 0.01, "a few blocks at a time")
	assert_gt(t.x, dog.x, "towards the treasure")


func test_it_never_leads_far_from_its_owner() -> void:
	var dog := Vector3(TreasureSniff.LEAD - 1.0, 10, 0)
	var t := TreasureSniff.target(dog, Vector3(22, 5, 0), OWNER)
	assert_lte(Vector2(t.x - OWNER.x, t.z - OWNER.z).length(), TreasureSniff.LEAD + 0.01)


func test_over_the_treasure_it_digs_right_there() -> void:
	var chest := Vector3(6, 5, 0)
	var dog := Vector3(6.3, 10, 0.2)
	assert_true(TreasureSniff.digs(dog, chest))
	var t := TreasureSniff.target(dog, chest, OWNER)
	assert_almost_eq(t.x, chest.x, 0.01)
	assert_almost_eq(t.z, chest.z, 0.01)
	assert_false(TreasureSniff.digs(Vector3(9, 10, 0), chest))
