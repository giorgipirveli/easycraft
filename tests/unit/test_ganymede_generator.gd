extends GutTest
## Cosmos: Ganymede (world 28, spec §21b.2): its voxel generator is the space worlds' SpaceGenerator with planet GANYMEDE:
## GanymedeTerrain's columns (the smooth plain's and the grooves' bright ice over the icy crust of water ice, the groove
## floors' blue-grey ice, the dark terrain's dark ice over old ice, its furrows and old craters, the ray crater's fresh ice
## and its rays, the poles' frost), the landing pad, ores in the water ice, boulders and aurora crystals, the built parts
## (the Jupiter Lookout, the Aurora Watch, the ocean drill and its shaft) and the secrets with the Solar Wing Lander,
## written fast and equal to the slow per-block reference everywhere, with no seams.

const CH := VoxelBuffer.CHANNEL_TYPE
const SEED := 12345


func _gen(seed: int = SEED) -> SpaceGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.GANYMEDE
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


func _same(g: SpaceGenerator, origin: Vector3i) -> int:
	var buf := _generate(g, origin)
	for z in 16:
		for x in 16:
			for y in 16:
				var w := origin + Vector3i(x, y, z)
				var got := buf.get_voxel(x, y, z, CH)
				var want := g.reference_block(w.x, w.y, w.z)
				if got != want:
					assert_eq(got, want, "at %s" % w)
					return -1
	return 4096


func test_it_is_the_space_generator_with_ganymede_rules() -> void:
	var g := _gen()
	assert_true(g is SpaceGenerator)
	assert_eq(g.space_shape().planet, SpaceShape.GANYMEDE)
	assert_not_null(g.space_shape().ganymede)
	assert_true(g._secrets is SpaceSecretRules)


## Every region's chunks, block by block, against the reference (features, the built parts and secrets included).
func test_every_region_matches_the_reference_block_rule() -> void:
	var g := _gen()
	var s := g.space_shape()
	var gy := s.ganymede
	var sp := s.spawn_column()
	var lm: Dictionary = (g._secrets as SpaceSecretRules).landmark()
	var at: Vector3i = lm.anchor
	var crystal := Vector2i.ZERO
	var boulder := Vector2i.ZERO
	var furrow := Vector2i.ZERO
	var old := Vector2i.ZERO
	for i in 60000:   # a grid over 1800 × 1800 blocks round the world's middle
		var x := (i % 300) * 6 - 900
		var z := (i / 300) * 9 - 900
		var k := s.ganymede_kind(x, z)
		if furrow == Vector2i.ZERO and k == GanymedeTerrain.FURROW:
			furrow = Vector2i(x, z)
		if old == Vector2i.ZERO and k == GanymedeTerrain.OLD_CRATER:
			old = Vector2i(x, z)
		if s.tree_at(x, z) and not gy.on_part(x, z, 1):
			if s.feature_at(x, s.height_at(x, z), z) == BlockIds.AURORA_CRYSTAL:
				crystal = Vector2i(x, z) if crystal == Vector2i.ZERO else crystal
			elif boulder == Vector2i.ZERO:
				boulder = Vector2i(x, z)
	assert_ne(crystal, Vector2i.ZERO, "an aurora crystal to check")
	assert_ne(boulder, Vector2i.ZERO, "a boulder to check")
	assert_ne(furrow, Vector2i.ZERO, "a furrow to check")
	assert_ne(old, Vector2i.ZERO, "an old crater to check")
	var c := gy.crater_centre()
	var cols: Array[Vector2i] = [sp, gy.lookout, gy.watch, gy.drill, crystal, boulder, furrow, old, c,
		c + Vector2i(gy.crater_radius() + 20, 3), gy.first_groove_toward(sp), gy.first_dark_west_of(sp),
		gy.frost_point_north_of(sp), Vector2i(at.x, at.z)]
	var checked := 0
	for p in cols:
		var h := s.ground_at(p.x, p.y)
		for y in [h - 12, h - 2, h + 6]:
			checked += _same(g, _chunk(p.x, y, p.y))
	for origin: Vector3i in [_chunk(sp.x, -40, sp.y), _chunk(sp.x, MeadowsShape.WORLD_BOTTOM, sp.y), Vector3i(64, 160, 64)]:
		checked += _same(g, origin)
	assert_eq(checked, (cols.size() * 3 + 3) * 4096, "every block checked")


func test_the_landing_pad_is_in_the_chunk_under_the_spawn() -> void:
	var g := _gen()
	var sp := g.space_shape().spawn_column()
	var h := g.space_shape().height_at(sp.x, sp.y)
	var origin := _chunk(sp.x, h - 1, sp.y)
	var l := Vector3i(sp.x, h - 1, sp.y) - origin
	assert_eq(_generate(g, origin).get_voxel(l.x, l.y, l.z, CH), BlockIds.LANDING_PAD)


func test_the_built_parts_are_written() -> void:
	var g := _gen()
	var gy := g.space_shape().ganymede
	for e: Array in [[Vector3i(gy.lookout.x + 1, gy.lookout_y + 3, gy.lookout.y), BlockIds.TELESCOPE],
			[Vector3i(gy.lookout.x - 1, gy.lookout_y + 1, gy.lookout.y + 1), BlockIds.JUPITER_GLOBE],
			[Vector3i(gy.watch.x + 5, gy.watch_y + 5, gy.watch.y), BlockIds.MAGNETOMETER],
			[Vector3i(gy.drill.x, gy.drill_y - 3, gy.drill.y), BlockIds.AIR],
			[Vector3i(gy.drill.x, gy.drill_y - GanymedeTerrain.SHAFT_DEPTH - 1, gy.drill.y), BlockIds.GLOW_ICE]]:
		var p: Vector3i = e[0]
		var buf := _generate(g, _chunk(p.x, p.y, p.z))
		var l := p - _chunk(p.x, p.y, p.z)
		assert_eq(buf.get_voxel(l.x, l.y, l.z, CH), e[1], "at %s" % p)


func test_the_grooves_the_dark_terrain_and_the_frost_in_their_chunks() -> void:
	var g := _gen()
	var s := g.space_shape()
	var gy := s.ganymede
	var gr := gy.first_groove_toward(s.spawn_column()) + Vector2i(0, 30)
	var top := _generate(g, _chunk(gr.x, s.height_at(gr.x, gr.y) - 1, gr.y))
	assert_gt(_count(top, BlockIds.GROOVED_ICE), 40, "ridges of pale ice")
	assert_gt(_count(top, BlockIds.TROUGH_ICE), 20, "and the grooves' floors")
	var d := gy.first_dark_west_of(s.spawn_column()) + Vector2i(-60, 0)
	var dark := _generate(g, _chunk(d.x, s.height_at(d.x, d.y) - 1, d.y))
	assert_gt(_count(dark, BlockIds.DARK_ICE) + _count(dark, BlockIds.OLD_ICE), 150, "the old dark terrain")
	var f := gy.frost_point_north_of(s.spawn_column()) + Vector2i(0, -40)
	var frost := _generate(g, _chunk(f.x, s.height_at(f.x, f.y) - 1, f.y))
	assert_gt(_count(frost, BlockIds.POLAR_FROST), 100, "the poles' frost")


func test_ores_only_in_the_water_ice() -> void:
	var g := _gen()
	var ores := 0
	for origin: Vector3i in [Vector3i(0, 0, 0), Vector3i(16, 16, 0), Vector3i(-32, -32, 48), Vector3i(80, -64, -16)]:
		var buf := _generate(g, origin)
		for id in [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND]:
			ores += _count(buf, id)
		for id in [BlockIds.STONE, BlockIds.DEEPSTONE, BlockIds.GRASS, BlockIds.DIRT, BlockIds.MOON_ROCK]:
			assert_eq(_count(buf, id), 0, "no other world's ground on Ganymede")
	assert_gt(ores, 10, "a child can mine the water ice")


func test_neighbouring_chunks_meet_without_seams() -> void:
	var g := _gen()
	var s := g.space_shape()
	var c := s.ganymede.crater_centre()
	var h := s.ground_at(c.x, c.y) - 2
	var oa := _chunk(c.x, h, c.y)
	var ob := oa + Vector3i(16, 0, 0)
	var a := _generate(g, oa)
	var b := _generate(g, ob)
	for z in 16:
		for y in 16:
			assert_eq(a.get_voxel(15, y, z, CH), g.reference_block(oa.x + 15, oa.y + y, oa.z + z))
			assert_eq(b.get_voxel(0, y, z, CH), g.reference_block(ob.x, ob.y + y, ob.z + z))
