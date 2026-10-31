extends GutTest
## The island of a showcase visit (M4 Wave 3, agent I): flat grass, a ring of sand, a calm sea; the
## friend's showcase in the middle with the layer they stood on lying on the island's grass; at and
## under that layer the showcase's air keeps the island's ground (no holes); a broken build leaves the
## island empty.


func _area() -> String:
	var cells := PackedInt32Array()
	var size := Vector3i(ShowcaseArea.SIDE, ShowcaseArea.HEIGHT, ShowcaseArea.SIDE)
	cells.resize(size.x * size.y * size.z)
	cells.fill(BlockIds.AIR)
	var put := func(p: Vector3i, id: int) -> void: cells[p.x + size.x * (p.z + size.z * p.y)] = id
	for x in size.x:
		for z in size.z:
			put.call(Vector3i(x, ShowcaseArea.GROUND_LAYER, z), BlockIds.SAND if x < 16 else BlockIds.AIR)
	put.call(Vector3i(3, ShowcaseArea.GROUND_LAYER + 1, 3), BlockIds.BRICK)
	put.call(Vector3i(3, ShowcaseArea.GROUND_LAYER - 2, 3), BlockIds.COAL)
	return BuildCodec.encode_cells(size, cells)


func test_the_friends_ground_lies_on_the_islands_grass() -> void:
	var g := VisitGenerator.new()
	g.setup(_area())
	assert_eq(g.origin, Vector3i(-16, VisitGenerator.GROUND_TOP - ShowcaseArea.GROUND_LAYER, -16))
	var o := g.origin
	assert_eq(g.block_at(o + Vector3i(3, ShowcaseArea.GROUND_LAYER, 3)), BlockIds.SAND, "the friend's ground")
	assert_eq(o.y + ShowcaseArea.GROUND_LAYER, VisitGenerator.GROUND_TOP)
	assert_eq(g.block_at(o + Vector3i(3, ShowcaseArea.GROUND_LAYER + 1, 3)), BlockIds.BRICK, "the build on it")
	assert_eq(g.block_at(o + Vector3i(3, ShowcaseArea.GROUND_LAYER - 2, 3)), BlockIds.COAL, "what was under it")
	assert_eq(g.block_at(o + Vector3i(20, ShowcaseArea.GROUND_LAYER, 20)), BlockIds.GRASS, "air there: the island's grass")
	assert_eq(g.block_at(o + Vector3i(20, ShowcaseArea.GROUND_LAYER - 1, 20)), BlockIds.DIRT, "and its dirt under it")
	assert_eq(g.block_at(o + Vector3i(20, ShowcaseArea.GROUND_LAYER + 1, 20)), BlockIds.AIR, "above: the showcase's air")


func test_the_island_and_the_sea() -> void:
	var g := VisitGenerator.new()
	g.setup("junk")
	assert_eq(g.size, Vector3i.ZERO, "a broken build: an empty island")
	var top := VisitGenerator.GROUND_TOP
	assert_eq(g.block_at(Vector3i(0, top, 0)), BlockIds.GRASS)
	assert_eq(g.block_at(Vector3i(0, top + 1, 0)), BlockIds.AIR)
	assert_eq(g.block_at(Vector3i(VisitGenerator.ISLAND + 2, top, 0)), BlockIds.SAND, "the beach")
	assert_eq(g.block_at(Vector3i(0, top, VisitGenerator.ISLAND + VisitGenerator.BEACH + 3)), BlockIds.WATER, "the sea")
	assert_eq(g.block_at(Vector3i(0, top - VisitGenerator.DEPTH - 1, 0)), BlockIds.STONE)
	assert_eq(VisitShape.new().height_at(123, -45), top)
	assert_eq(VisitShape.new().spawn_column().y, VisitGenerator.ISLAND - 14, "the visitor starts on the grass, south")


func test_it_writes_a_chunk_the_way_block_at_says() -> void:
	var g := VisitGenerator.new()
	g.setup(_area())
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	var at := Vector3i(-16, VisitGenerator.GROUND_TOP - 8, -16)
	g._generate_block(buf, at, 0)
	for p: Vector3i in [Vector3i(3, 8, 3), Vector3i(3, 9, 3), Vector3i(3, 6, 3), Vector3i(10, 8, 10), Vector3i(10, 12, 10)]:
		assert_eq(buf.get_voxel(p.x, p.y, p.z, VoxelBuffer.CHANNEL_TYPE), g.block_at(at + p), str(p))
