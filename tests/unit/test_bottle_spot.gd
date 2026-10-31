extends GutTest
## Where a friend's bottle arrives (M4 Wave 3, agent I; research D5): floating on water near where the
## child starts playing, else on the beach, else on the ground in front; bottles spread out.


func _world(blocks: Dictionary) -> Callable:
	return func(p: Vector3i) -> int:
		return blocks.get(p, BlockIds.AIR)


func test_the_nearest_water_surface_comes_first() -> void:
	var blocks := {}
	var water: Array[Vector3i] = []
	for x in range(10, 14):
		blocks[Vector3i(x, 20, 0)] = BlockIds.WATER
		blocks[Vector3i(x, 19, 0)] = BlockIds.WATER   # deep water: only the top floats a bottle
		water.append(Vector3i(x, 20, 0))
		water.append(Vector3i(x, 19, 0))
	var sand: Array[Vector3i] = [Vector3i(2, 20, 0)]
	blocks[Vector3i(2, 20, 0)] = BlockIds.SAND
	var spots := BottleSpot.find(Vector3i(0, 21, 0), 1, water, sand, _world(blocks))
	assert_eq(spots.size(), 1)
	assert_eq(spots[0].kind, BottleSpot.WATER)
	assert_eq(spots[0].cell, Vector3i(10, 20, 0), "the nearest surface cell, not the one under it")
	assert_almost_eq((spots[0].pos as Vector3).y, 20.0 + BottleSpot.FLOAT_Y, 0.001)


func test_no_water_the_beach_and_no_beach_the_ground_in_front() -> void:
	var blocks := {Vector3i(5, 20, 5): BlockIds.SAND, Vector3i(5, 21, 5): BlockIds.PLANKS, Vector3i(6, 20, 5): BlockIds.SAND}
	var sand: Array[Vector3i] = [Vector3i(5, 20, 5), Vector3i(6, 20, 5)]
	var spots := BottleSpot.find(Vector3i(0, 21, 0), 1, [] as Array[Vector3i], sand, _world(blocks))
	assert_eq(spots[0].kind, BottleSpot.BEACH)
	assert_eq(spots[0].cell, Vector3i(6, 20, 5), "sand with something on it is no beach")
	var none := BottleSpot.find(Vector3i(0, 21, 0), 2, [] as Array[Vector3i], [] as Array[Vector3i], _world({}))
	assert_eq(none.size(), 2)
	assert_eq(none[0].kind, BottleSpot.GROUND)
	assert_ne(none[0].pos, none[1].pos, "two bottles never on one spot")


func test_several_bottles_spread_out_on_the_water() -> void:
	var blocks := {}
	var water: Array[Vector3i] = []
	for x in range(0, 12):
		for z in range(0, 12):
			blocks[Vector3i(x, 20, z)] = BlockIds.WATER
			water.append(Vector3i(x, 20, z))
	var spots := BottleSpot.find(Vector3i(0, 21, 0), 3, water, [] as Array[Vector3i], _world(blocks))
	assert_eq(spots.size(), 3)
	for i in 3:
		for j in range(i + 1, 3):
			assert_gte((spots[i].cell as Vector3i - spots[j].cell as Vector3i).length(), BottleSpot.SPREAD, "apart")
