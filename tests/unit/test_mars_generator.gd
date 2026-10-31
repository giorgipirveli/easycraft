extends GutTest
## Cosmos: Mars (world 19, spec §21b.2): its voxel generator is the space worlds' SpaceGenerator with planet MARS:
## MarsTerrain's columns (the plains' dust, regolith and layered basalt, the volcano's bare lava rock, the canyon's
## terraces, the river beds, the ice caps' layers), the landing pad, ores in the basalt, boulders and gypsum crystals,
## and the secrets with the rover, written fast and equal to the slow per-block reference everywhere, with no seams.

const CH := VoxelBuffer.CHANNEL_TYPE
const SEED := 12345


func _gen(seed: int = SEED) -> SpaceGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.MARS
	g.world_seed = seed
	return g


func _generate(gen: SpaceGenerator, origin: Vector3i) -> VoxelBuffer:
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	gen._generate_block(buf, origin, 0)
	return buf


func _chunk(x: int, y: int, z: int) -> Vector3i:
	return Vector3i(floori(x / 16.0), floori(y / 16.0), floori(z / 16.0)) * 16


func _count(buf: VoxelBuffer, id: int) -> int:
	var n := 0
	for z in 16:
		for x in 16:
			for y in 16:
				if buf.get_voxel(x, y, z, CH) == id:
					n += 1
	return n


func test_it_is_the_space_generator_with_mars_rules() -> void:
	var g := _gen()
	assert_true(g is SpaceGenerator)
	assert_eq(g.space_shape().planet, SpaceShape.MARS)
	assert_not_null(g.space_shape().mars)
	assert_true(g._secrets is SpaceSecretRules)


## Every region's chunks, block by block, against the reference (features and secrets included).
func test_every_region_matches_the_reference_block_rule() -> void:
	var g := _gen()
	var s := g.space_shape()
	var sp := s.spawn_column()
	var vc := s.mars.volcano_centre()
	var cx := sp.x + 40
	var cz := roundi(s.mars.canyon_z(cx))
	var north := s.mars.north_edge()
	var lm: Dictionary = (g._secrets as SpaceSecretRules).landmark()
	var at: Vector3i = lm.anchor
	var river := Vector2i.ZERO
	for i in 3000:
		var x := (i * 13) % 1000 - 500
		var z := (i * 7) % 600 - 400
		if s.mars_kind(x, z) == MarsTerrain.VALLEY and s.tree_at(x, z):
			river = Vector2i(x, z)
			break
	var cols: Array[Vector2i] = [sp, vc, vc + Vector2i(60, 20), vc + Vector2i(MarsTerrain.VOLCANO_RADIUS - 2, 0),
		Vector2i(cx, cz), Vector2i(cx, cz - 30), Vector2i(0, north - 70), Vector2i(40, north + 20),
		Vector2i(-30, s.mars.south_edge() + 60), river, Vector2i(at.x, at.z)]
	var checked := 0
	for c in cols:
		var h := s.height_at(c.x, c.y)
		for y in [h - 10, h - 2, h + 6]:
			var origin := _chunk(c.x, y, c.y)
			var buf := _generate(g, origin)
			for z in 16:
				for x in 16:
					for yy in 16:
						var w := origin + Vector3i(x, yy, z)
						var got := buf.get_voxel(x, yy, z, CH)
						var want := g.reference_block(w.x, w.y, w.z)
						if got != want:
							assert_eq(got, want, "at %s (column %s)" % [w, c])
							return
						checked += 1
	for origin: Vector3i in [_chunk(sp.x, -40, sp.y), _chunk(sp.x, MeadowsShape.WORLD_BOTTOM, sp.y), Vector3i(64, 160, 64)]:
		var buf := _generate(g, origin)
		for z in 16:
			for x in 16:
				for yy in 16:
					var w := origin + Vector3i(x, yy, z)
					assert_eq(buf.get_voxel(x, yy, z, CH), g.reference_block(w.x, w.y, w.z), "at %s" % w)
					checked += 1
	assert_eq(checked, (cols.size() * 3 + 3) * 4096, "every block checked")


func test_the_landing_pad_is_in_the_chunk_under_the_spawn() -> void:
	var g := _gen()
	var sp := g.space_shape().spawn_column()
	var h := g.space_shape().height_at(sp.x, sp.y)
	var origin := _chunk(sp.x, h - 1, sp.y)
	var l := Vector3i(sp.x, h - 1, sp.y) - origin
	assert_eq(_generate(g, origin).get_voxel(l.x, l.y, l.z, CH), BlockIds.LANDING_PAD)


func test_ores_only_in_basalt_and_no_green_meadows_ground() -> void:
	var g := _gen()
	var ores := 0
	for origin: Vector3i in [Vector3i(0, 0, 0), Vector3i(16, 16, 0), Vector3i(-32, -32, 48), Vector3i(80, -64, -16),
			Vector3i(-48, 16, 32)]:
		var buf := _generate(g, origin)
		for z in 16:
			for x in 16:
				for y in 16:
					var id := buf.get_voxel(x, y, z, CH)
					if id in [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND]:
						ores += 1
					assert_false(id in [BlockIds.STONE, BlockIds.DEEPSTONE, BlockIds.GRASS, BlockIds.DIRT, BlockIds.WATER,
						BlockIds.MOON_ROCK, BlockIds.MOON_DUST], "no other world's ground on Mars")
	assert_gt(ores, 10, "a child can mine on Mars")


func test_neighbouring_chunks_meet_without_seams() -> void:
	var g := _gen()
	var s := g.space_shape()
	var x0 := 96
	var z0 := roundi(s.mars.canyon_z(x0)) - 24   # across a canyon wall
	var h := s.height_at(x0, z0)
	var oa := _chunk(x0, h, z0)
	var ob := oa + Vector3i(16, 0, 0)
	var oc := oa + Vector3i(0, 0, 16)
	var a := _generate(g, oa)
	var b := _generate(g, ob)
	var c := _generate(g, oc)
	for i in 16:
		for y in 16:
			assert_eq(a.get_voxel(15, y, i, CH), g.reference_block(oa.x + 15, oa.y + y, oa.z + i))
			assert_eq(b.get_voxel(0, y, i, CH), g.reference_block(ob.x, ob.y + y, ob.z + i))
			assert_eq(c.get_voxel(i, y, 0, CH), g.reference_block(oc.x + i, oc.y + y, oc.z))


func test_the_volcano_and_the_poles_are_in_their_chunks() -> void:
	var g := _gen()
	var s := g.space_shape()
	var vc := s.mars.volcano_centre()
	var flank := vc + Vector2i(80, 0)
	var fh := s.height_at(flank.x, flank.y)
	assert_gt(_count(_generate(g, _chunk(flank.x, fh - 8, flank.y)), BlockIds.BASALT), 1000, "a volcano of basalt")
	var pole := Vector2i(16, s.mars.north_edge() - 90)
	var ph := s.height_at(pole.x, pole.y)
	var ice := _generate(g, _chunk(pole.x, ph - 4, pole.y))
	assert_gt(_count(ice, BlockIds.POLAR_ICE), 400, "the north cap's water ice")
	var south := Vector2i(16, s.mars.south_edge() + 90)
	var top := _chunk(south.x, s.height_at(south.x, south.y) - 1, south.y)
	var dry := _count(_generate(g, top), BlockIds.DRY_ICE) + _count(_generate(g, top - Vector3i(0, 16, 0)), BlockIds.DRY_ICE)
	assert_gt(dry, 120, "the south cap's dry ice on top")
