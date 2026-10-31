extends GutTest
## Monster Wave's arena (spec §12.20): a flat world of the universe's ground with low cover here and there (2-block
## pillars and short walls on a grid, none within 12 blocks of the middle), the Totem in the middle and the players
## starting 6 blocks from it. The generator writes exactly what the shape says, chunk by chunk.


func test_the_ground_is_flat_everywhere() -> void:
	var s := ArenaShape.new(123, 1)
	for p: Vector2i in [Vector2i(0, 0), Vector2i(500, -70), Vector2i(-3000, 4000)]:
		assert_eq(s.height_at(p.x, p.y), ArenaShape.FLOOR)
		assert_false(s.is_river(p.x, p.y))
		assert_false(s.tree_at(p.x, p.y))
	assert_eq(s.spawn_column(), Vector2i(0, ArenaShape.START_Z))
	assert_eq(ArenaShape.START_Z, 6)
	assert_eq(ArenaShape.totem_cell(), Vector2i(0, 0))


func test_each_universe_has_its_own_ground() -> void:
	var meadows := ArenaShape.new(1, 1)
	assert_eq(meadows.block_at(Vector3i(3, ArenaShape.FLOOR - 1, 3)), BlockIds.GRASS)
	assert_eq(meadows.block_at(Vector3i(3, ArenaShape.FLOOR - 2, 3)), BlockIds.DIRT)
	var desert := ArenaShape.new(1, 2)
	assert_eq(desert.block_at(Vector3i(3, ArenaShape.FLOOR - 1, 3)), BlockIds.SAND)
	var frost := ArenaShape.new(1, 3)
	assert_eq(frost.block_at(Vector3i(3, ArenaShape.FLOOR - 1, 3)), BlockIds.SNOW)
	var later := ArenaShape.new(1, 9)
	assert_eq(later.block_at(Vector3i(3, ArenaShape.FLOOR - 1, 3)), BlockIds.GRASS, "a universe without its own: grass")
	for s: ArenaShape in [meadows, desert, frost]:
		assert_eq(s.block_at(Vector3i(3, ArenaShape.FLOOR - ArenaShape.DEPTH, 3)), BlockIds.BEDROCK)
		assert_eq(s.block_at(Vector3i(3, ArenaShape.FLOOR + 5, 3)), BlockIds.AIR)
		for id in s.palette.values():
			assert_true(BlockIds.is_valid(id), "a real block: %d" % id)


func test_there_is_cover_but_never_near_the_middle() -> void:
	var s := ArenaShape.new(77, 1)
	var cover := 0
	for x in range(-80, 81):
		for z in range(-80, 81):
			var c := s.cover_at(x, z)
			if c == BlockIds.AIR:
				continue
			cover += 1
			assert_gt(Vector2(x, z).length(), float(ArenaShape.CLEAR), "no cover near the middle: %d, %d" % [x, z])
			assert_true(BlockIds.is_solid(c))
			assert_eq(s.block_at(Vector3i(x, ArenaShape.FLOOR, z)), c)
			assert_eq(s.block_at(Vector3i(x, ArenaShape.FLOOR + ArenaShape.COVER_HIGH - 1, z)), c)
			assert_eq(s.block_at(Vector3i(x, ArenaShape.FLOOR + ArenaShape.COVER_HIGH, z)), BlockIds.AIR, "low: jump-over height")
	assert_between(cover, 150, 1200, "here and there, not a maze (%d columns in a 161-block square)" % cover)


func test_the_same_seed_is_the_same_arena() -> void:
	var a := ArenaShape.new(5, 1)
	var b := ArenaShape.new(5, 1)
	var c := ArenaShape.new(6, 1)
	var differs := false
	for x in range(-60, 60, 3):
		for z in range(-60, 60, 3):
			assert_eq(a.cover_at(x, z), b.cover_at(x, z))
			differs = differs or a.cover_at(x, z) != c.cover_at(x, z)
	assert_true(differs, "another seed, another arena")


func test_the_generator_writes_what_the_shape_says() -> void:
	var gen := ArenaGenerator.new()
	gen.universe = 2
	gen.world_seed = 77
	var shape := ArenaShape.new(77, 2)
	for origin: Vector3i in [Vector3i(16, 16, 16), Vector3i(-32, 32, 16), Vector3i(0, 0, 0), Vector3i(16, 48, 0),
			Vector3i(0, -64, 0)]:
		var buf := VoxelBuffer.new()
		buf.create(16, 16, 16)
		gen._generate_block(buf, origin, 0)
		for x in 16:
			for z in 16:
				for y in 16:
					var p := origin + Vector3i(x, y, z)
					var want := shape.block_at(p)
					var got := buf.get_voxel(x, y, z, VoxelBuffer.CHANNEL_TYPE)
					if got != want:
						fail_test("chunk %s at %s: %d, not %d" % [origin, p, got, want])
						return
	pass_test("every block as the shape says")
