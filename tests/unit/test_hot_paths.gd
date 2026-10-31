extends GutTest
## M5 Task 3 (spec §15.3, the hot paths with everything merged): what runs every physics tick for every monster or
## animal reads as little of the world as it can and makes nothing new.


## A monster pressed against a wall looks for a door in it every tick (Monster._door_at_wall): each cell is read once.
func test_the_door_check_reads_each_cell_once() -> void:
	var reads := {}
	var block_at := func(cell: Vector3i) -> int:
		reads[cell] = int(reads.get(cell, 0)) + 1
		return BlockIds.STONE
	assert_false(DefenseRules.door_in_way(Vector3(0.5, 10.0, 0.5), Vector3(1, 0, 0), 1.6, 0.9, block_at))
	assert_gt(reads.size(), 3, "it looks at the cells ahead and to both sides")
	for cell: Vector3i in reads:
		assert_eq(reads[cell], 1, "%s read once" % cell)


func test_the_door_check_still_finds_a_door_or_a_powered_door() -> void:
	for door: int in [BlockIds.DOOR, BlockIds.POWERED_DOOR]:
		var block_at := func(cell: Vector3i) -> int: return door if cell == Vector3i(1, 10, 0) else BlockIds.AIR
		assert_true(DefenseRules.door_in_way(Vector3(0.5, 10.0, 0.5), Vector3(1, 0, 0), 1.6, 0.4, block_at),
			BlockIds.display_name(door))


func test_a_slider_still_slides_on_ice_only() -> void:
	assert_eq(AnimalRules.slide_factor(&"penguin", 0.1), AnimalRules.SLIDE_FACTOR, "a penguin belly-slides on ice")
	assert_eq(AnimalRules.slide_factor(&"penguin", 1.0), 1.0, "not on grass")
	assert_eq(AnimalRules.slide_factor(&"cow", 0.1), 1.0, "a cow never slides")
	assert_eq(AnimalRules.slide_factor(&"no_such_animal", 0.1), 1.0)
	assert_true(AnimalRules.NO_SPECIES.is_read_only(), "the shared empty default can't be changed")
