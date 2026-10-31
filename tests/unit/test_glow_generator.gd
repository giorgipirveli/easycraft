extends GutTest
## Universe 6, the Glow Caves: the voxel generator (GlowGenerator, a MeadowsGenerator) writes GlowShape's caves fast:
## rock under the floor, the floor's moss, flowstone or lake stone, air or a lake's water up to the ceiling, the
## glow-worm ceiling, rock and the roof's meadow; the plants (glowshrooms, dripstone, columns, selenite beams); its
## secrets. Equal to the slow per-block reference, and without seams between chunks.

const CH := VoxelBuffer.CHANNEL_TYPE
const SEED := 20261017

var _gen: GlowGenerator


func before_all() -> void:
	_gen = GlowGenerator.new()
	_gen.world_seed = SEED


func _generate(origin: Vector3i, gen: GlowGenerator = _gen) -> VoxelBuffer:
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	gen._generate_block(buf, origin, 0)
	return buf


func _chunk_at(spot: Vector2i, y: int) -> Vector3i:
	return Vector3i(floori(spot.x / 16.0) * 16, floori(y / 16.0) * 16, floori(spot.y / 16.0) * 16)


func _plant_near(x: int, z: int) -> bool:
	var shape := _gen.glow_shape()
	for dz in range(-GlowShape.BEAM_REACH, GlowShape.BEAM_REACH + 1):
		for dx in range(-GlowShape.BEAM_REACH, GlowShape.BEAM_REACH + 1):
			var p := shape.plant_at(x + dx, z + dz)
			if p == GlowShape.BEAM or (p != GlowShape.NO_PLANT and absi(dx) <= GlowShape.PLANT_REACH
					and absi(dz) <= GlowShape.PLANT_REACH):
				return true
	return shape.hang_at(x, z) > 0


func _find(want: Callable) -> Vector2i:
	var shape := _gen.glow_shape()
	for z in range(-400, 400, 5):
		for x in range(-400, 400, 5):
			if want.call(shape, x, z):
				return Vector2i(x, z)
	return Vector2i.ZERO


func test_it_is_a_meadows_generator_with_the_caves_rules() -> void:
	assert_true(_gen is MeadowsGenerator)
	assert_true(_gen.glow_shape() is GlowShape)
	assert_eq(_gen.glow_shape().seed, SEED)
	assert_true(_gen._secrets is GlowSecretRules)
	assert_true(GlowGenerator.new().glow_shape() is GlowShape, "the caves' rules before a seed is set")


## The floor, a hall's air, its ceiling, the rock over it, the roof's meadow, a lake, a wall, a shaft: the fast path
## equals the reference.
func test_chunks_match_the_reference_block_rule() -> void:
	var shape := _gen.glow_shape()
	var sp := shape.spawn_column()
	var col := shape.column(sp.x, sp.y)
	var origins: Array[Vector3i] = [_chunk_at(sp, col.x - 2), _chunk_at(sp, col.y), _chunk_at(sp, col.z - 2),
		_chunk_at(sp, col.x - 30), _chunk_at(sp, -10)]
	var lake := _find(func(sh: GlowShape, x: int, z: int) -> bool:
		var c := sh.column(x, z)
		return c.x < c.y and c.x < GlowShape.LAKE_LEVEL - 3 and not sh.in_shaft(x, z))
	origins.append(_chunk_at(lake, GlowShape.LAKE_LEVEL - 2))
	var wall := _find(func(sh: GlowShape, x: int, z: int) -> bool:
		var c := sh.column(x, z)
		return c.x == c.y and Vector2(x - sp.x, z - sp.y).length() > 60)
	origins.append(_chunk_at(wall, shape.column(wall.x, wall.y).x))
	var shaft := shape.home_shaft()
	origins.append(_chunk_at(shaft + Vector2i(GlowShape.SHAFT_R - 1, 0), shape.column(shaft.x, shaft.y).z - 12))
	origins.append(_chunk_at(shaft, shape.column(shaft.x, shaft.y).x - 4))
	var checked := 0
	for origin in origins:
		var buf := _generate(origin)
		for z in 16:
			for x in 16:
				if _plant_near(origin.x + x, origin.z + z):
					continue
				for y in 16:
					var w := origin + Vector3i(x, y, z)
					var want := _gen.reference_block(w.x, w.y, w.z)
					if buf.get_voxel(x, y, z, CH) != want:
						assert_eq(buf.get_voxel(x, y, z, CH), want, "block at %s" % w)
						return
					checked += 1
	assert_gt(checked, 10000, "most of nine chunks (columns near plants are left out)")


## The layers of a hall's column by the reference: rock under the floor, its top block, air up to the ceiling, the
## ceiling's block, rock, dirt and the roof's grass; a lake's water up to LAKE_LEVEL.
func test_a_column_has_the_caves_layers() -> void:
	var shape := _gen.glow_shape()
	var sp := shape.spawn_column()
	var c := shape.column(sp.x, sp.y)
	assert_eq(_gen.reference_block(sp.x, c.x - 1, sp.y), shape.floor_block(sp.x, sp.y, c))
	assert_eq(_gen.reference_block(sp.x, c.x - 2, sp.y), BlockIds.CAVE_STONE)
	assert_eq(_gen.reference_block(sp.x, c.x, sp.y), BlockIds.AIR)
	assert_eq(_gen.reference_block(sp.x, c.y - 1, sp.y), BlockIds.AIR)
	assert_eq(_gen.reference_block(sp.x, c.y, sp.y), shape.ceiling_block(sp.x, sp.y))
	assert_eq(_gen.reference_block(sp.x, c.z - 1, sp.y), BlockIds.GRASS, "the meadow on the roof")
	assert_eq(_gen.reference_block(sp.x, c.z - 2, sp.y), BlockIds.DIRT)
	assert_eq(_gen.reference_block(sp.x, c.z, sp.y), BlockIds.AIR)
	assert_eq(_gen.reference_block(sp.x, GlowShape.BED_BOTTOM, sp.y), BlockIds.BEDROCK, "the caves' floor of bedrock")
	assert_eq(_gen.reference_block(sp.x, GlowShape.BED_BOTTOM - 1, sp.y), BlockIds.AIR, "nothing under it")
	var lake := _find(func(sh: GlowShape, x: int, z: int) -> bool:
		var cc := sh.column(x, z)
		return cc.x < cc.y and cc.x < GlowShape.LAKE_LEVEL - 2 and not sh.in_shaft(x, z))
	var lc := shape.column(lake.x, lake.y)
	assert_eq(_gen.reference_block(lake.x, lc.x, lake.y), BlockIds.WATER)
	assert_eq(_gen.reference_block(lake.x, GlowShape.LAKE_LEVEL - 1, lake.y), BlockIds.WATER)
	assert_eq(_gen.reference_block(lake.x, GlowShape.LAKE_LEVEL, lake.y), BlockIds.AIR)
	assert_eq(_gen.reference_block(lake.x, lc.x - 1, lake.y), BlockIds.LAKE_STONE)


## Chunks that overlap by half agree everywhere: plants, beams and secrets included.
func test_neighbouring_chunks_meet_without_seams() -> void:
	var shape := _gen.glow_shape()
	var giant := _find(func(sh: GlowShape, x: int, z: int) -> bool: return sh.plant_at(x, z) == GlowShape.BLUE_GIANT)
	var beam := _find(func(sh: GlowShape, x: int, z: int) -> bool: return sh.plant_at(x, z) == GlowShape.BEAM)
	for spot: Vector2i in [giant, beam, shape.spawn_column()]:
		var h := shape.height_at(spot.x, spot.y)
		var base := Vector3i(spot.x - 8, floori(h / 16.0) * 16, spot.y - 8)
		var a := _generate(base)
		var b := _generate(base + Vector3i(8, 0, 0))
		var c := _generate(base + Vector3i(0, 8, 0))
		var d := _generate(base + Vector3i(0, 0, 8))
		for z in 8:
			for y in 16:
				for x in 8:
					assert_eq(b.get_voxel(x, y, z, CH), a.get_voxel(x + 8, y, z, CH), "x seam at %s" % (base + Vector3i(x + 8, y, z)))
					if b.get_voxel(x, y, z, CH) != a.get_voxel(x + 8, y, z, CH):
						return
		for z in 16:
			for y in 8:
				for x in 16:
					if c.get_voxel(x, y, z, CH) != a.get_voxel(x, y + 8, z, CH):
						assert_eq(c.get_voxel(x, y, z, CH), a.get_voxel(x, y + 8, z, CH), "y seam")
						return
		for z in 8:
			for y in 16:
				for x in 16:
					if d.get_voxel(x, y, z, CH) != a.get_voxel(x, y, z + 8, CH):
						assert_eq(d.get_voxel(x, y, z, CH), a.get_voxel(x, y, z + 8, CH), "z seam")
						return


## The plants as built: a giant glowshroom's pale stem under its glowing cap, a stalactite hanging from the ceiling,
## a selenite beam's crystal.
func test_the_plants_are_written() -> void:
	var shape := _gen.glow_shape()
	var giant := _find(func(sh: GlowShape, x: int, z: int) -> bool: return sh.plant_at(x, z) == GlowShape.BLUE_GIANT)
	var h := shape.height_at(giant.x, giant.y)
	var tall := shape.plant_height(giant.x, giant.y)
	var buf := _generate(_chunk_at(giant, h))
	var origin := _chunk_at(giant, h)
	var stem_y := h - origin.y
	if stem_y >= 0 and stem_y < 16:
		assert_eq(buf.get_voxel(giant.x - origin.x, stem_y, giant.y - origin.z, CH), BlockIds.SHROOM_STEM)
	var cap := _generate(_chunk_at(giant, h + tall))
	var co := _chunk_at(giant, h + tall)
	assert_eq(cap.get_voxel(giant.x - co.x, h + tall - co.y, giant.y - co.z, CH), BlockIds.BLUE_SHROOM, "its cap")
	var tite := _find(func(sh: GlowShape, x: int, z: int) -> bool: return sh.hang_at(x, z) > 0)
	var tc := shape.column(tite.x, tite.y)
	var tip_y := tc.y - shape.hang_at(tite.x, tite.y)
	var to := _chunk_at(tite, tip_y)
	assert_eq(_generate(to).get_voxel(tite.x - to.x, tip_y - to.y, tite.y - to.z, CH), BlockIds.STALACTITE, "its tip")
	var beam := _find(func(sh: GlowShape, x: int, z: int) -> bool: return sh.plant_at(x, z) == GlowShape.BEAM)
	var cells := shape.beam_cells(beam.x, beam.y)
	assert_false(cells.is_empty())
	var first: Vector3i = cells[0]
	var bo := Vector3i(floori(first.x / 16.0), floori(first.y / 16.0), floori(first.z / 16.0)) * 16
	assert_eq(_generate(bo).get_voxel(first.x - bo.x, first.y - bo.y, first.z - bo.z, CH), BlockIds.SELENITE)


## Ores lie in the stone under the floor (the meadows' veins): a child who digs finds coal and iron.
func test_ores_lie_under_the_floor() -> void:
	var shape := _gen.glow_shape()
	var sp := shape.spawn_column()
	var ores := {}
	for cz in range(-2, 2):
		for cx in range(-2, 2):
			for cy in range(-2, 2):
				var origin := Vector3i(floori(sp.x / 16.0) + cx, cy, floori(sp.y / 16.0) + cz) * 16
				var buf := _generate(origin)
				for z in 16:
					for y in 16:
						for x in 16:
							var id := buf.get_voxel(x, y, z, CH)
							if [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND].has(id):
								ores[id] = true
	assert_true(ores.has(BlockIds.COAL), "coal: %s" % [ores.keys()])
	assert_true(ores.has(BlockIds.IRON), "iron")


## A chunk far over the roof is empty at once (no secret goes that high), and so is one under the caves' bedrock
## (the rock under the floor ends at BED_BOTTOM: a chunk there costs nothing, like the Dragon Realm's void).
func test_over_the_roof_and_under_the_bedrock_is_nothing() -> void:
	for origin: Vector3i in [Vector3i(0, 112, 0), Vector3i(0, GlowShape.BED_BOTTOM - 16, 0), Vector3i(-32, -64, 48)]:
		var buf := _generate(origin)
		for p: Vector3i in [Vector3i(0, 0, 0), Vector3i(15, 15, 15), Vector3i(7, 7, 7)]:
			assert_eq(buf.get_voxel(p.x, p.y, p.z, CH), BlockIds.AIR, "at %s" % (origin + p))
	var deep := _generate(Vector3i(0, GlowShape.BED_BOTTOM, 0))
	assert_eq(deep.get_voxel(3, 0, 3, CH), BlockIds.BEDROCK)
	assert_true(deep.get_voxel(3, 8, 3, CH) in [BlockIds.DEEPSTONE, BlockIds.GOLD, BlockIds.IRON], "deep stone (or an ore)")


## The roof's flowers stand on its grass in the chunk (and in the reference: the chunks' test checks the roof too).
func test_flowers_grow_on_the_roof() -> void:
	var shape := _gen.glow_shape()
	var spot := _find(func(sh: GlowShape, x: int, z: int) -> bool: return sh.flower_on_roof(x, z))
	var roof := shape.roof_at(spot.x, spot.y)
	var o := _chunk_at(spot, roof)
	assert_eq(_generate(o).get_voxel(spot.x - o.x, roof - o.y, spot.y - o.z, CH), BlockIds.FLOWERS, "a flower")
	assert_eq(_gen.reference_block(spot.x, roof, spot.y), BlockIds.FLOWERS)
	assert_eq(_gen.reference_block(spot.x, roof - 1, spot.y), BlockIds.GRASS, "on the grass")
	assert_eq(_gen.reference_block(spot.x, roof + 1, spot.y), BlockIds.AIR)
