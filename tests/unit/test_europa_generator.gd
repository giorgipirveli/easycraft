extends GutTest
## Cosmos: Europa (world 20, spec §21b.2): its voxel generator is the space worlds' SpaceGenerator with planet EUROPA:
## EuropaTerrain's columns (the white crust over layered deep ice, the seafloor rock under y 0, the reddish cracks and
## their stained ridges, the ice cliffs, the salt mounds and their geyser vents), the ocean well cut through the ice
## (its ramp, the water at the bottom and under the ice, the glowing rings), the landing pad, ores in the seafloor rock,
## ice blades and salt crystals, and the secrets with the Ice Lander, written fast and equal to the slow per-block
## reference everywhere, with no seams.

const CH := VoxelBuffer.CHANNEL_TYPE
const SEED := 12345


func _gen(seed: int = SEED) -> SpaceGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.EUROPA
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


func test_it_is_the_space_generator_with_europa_rules() -> void:
	var g := _gen()
	assert_true(g is SpaceGenerator)
	assert_eq(g.space_shape().planet, SpaceShape.EUROPA)
	assert_not_null(g.space_shape().europa)
	assert_true(g._secrets is SpaceSecretRules)


## Every region's chunks, block by block, against the reference (features and secrets included).
func test_every_region_matches_the_reference_block_rule() -> void:
	var g := _gen()
	var s := g.space_shape()
	var e := s.europa
	var sp := s.spawn_column()
	var mc := e.mesa_centre()
	var wc := e.well_centre()
	var vent := e.nearest_vent(sp)
	var lm: Dictionary = (g._secrets as SpaceSecretRules).landmark()
	var at: Vector3i = lm.anchor
	var crack := Vector2i.ZERO
	for i in 5000:
		var x := (i * 19) % 1000 - 500
		var z := (i * 23) % 1000 - 500
		if s.europa_kind(x, z) == EuropaTerrain.LINEA and s.tree_at(x, z):
			crack = Vector2i(x, z)
			break
	var blades := Vector2i.ZERO
	for i in 20000:
		var x := (i * 7) % 600 - 300
		var z := (i * 13) % 600 - 300
		if s.europa_kind(x, z) == EuropaTerrain.PLAINS and s.tree_at(x, z):
			blades = Vector2i(x, z)
			break
	var cols: Array[Vector2i] = [sp, mc, mc + Vector2i(roundi(EuropaTerrain.MESA_RADIUS), 0), vent, crack, blades,
		Vector2i(at.x, at.z)]
	var checked := 0
	for c in cols:
		var h := s.height_at(c.x, c.y)
		for y in [h - 10, h - 2, h + 6]:
			checked += _same(g, _chunk(c.x, y, c.y))
	var well := 0
	for dx: int in [-16, 0, 16]:   # the whole well: its walls, ramp, water and the rock under it
		for dz: int in [-16, 0, 16]:
			for y in range(EuropaTerrain.SEAFLOOR - 16, e.well_top() + 16, 16):
				well += _same(g, _chunk(wc.x + dx, y, wc.y + dz))
	for origin: Vector3i in [_chunk(sp.x, -40, sp.y), _chunk(sp.x, MeadowsShape.WORLD_BOTTOM, sp.y), Vector3i(64, 160, 64)]:
		checked += _same(g, origin)
	assert_eq(checked, (cols.size() * 3 + 3) * 4096, "every block checked")
	assert_gt(well, 27 * 4096, "every block of the well checked")


func test_the_landing_pad_is_in_the_chunk_under_the_spawn() -> void:
	var g := _gen()
	var sp := g.space_shape().spawn_column()
	var h := g.space_shape().height_at(sp.x, sp.y)
	var origin := _chunk(sp.x, h - 1, sp.y)
	var l := Vector3i(sp.x, h - 1, sp.y) - origin
	assert_eq(_generate(g, origin).get_voxel(l.x, l.y, l.z, CH), BlockIds.LANDING_PAD)


func test_the_ocean_is_in_the_wells_chunks_even_under_y_0() -> void:
	var g := _gen()
	var wc := g.space_shape().europa.well_centre()
	var low := _chunk(wc.x, EuropaTerrain.SEAFLOOR, wc.y)
	assert_lt(low.y + 16, 1, "a chunk wholly under y 0")
	var l := Vector3i(wc.x, EuropaTerrain.SEAFLOOR, wc.y) - low
	assert_eq(_generate(g, low).get_voxel(l.x, l.y, l.z, CH), BlockIds.WATER, "the ocean's deepest water")
	var up := _chunk(wc.x, EuropaTerrain.OCEAN_TOP - 1, wc.y)
	var l2 := Vector3i(wc.x, EuropaTerrain.OCEAN_TOP - 1, wc.y) - up
	var buf := _generate(g, up)
	assert_eq(buf.get_voxel(l2.x, l2.y, l2.z, CH), BlockIds.WATER, "its surface")
	assert_gt(_count(buf, BlockIds.WATER), 100)


func test_ores_only_in_the_seafloor_rock_and_no_other_worlds_ground() -> void:
	var g := _gen()
	var ores := 0
	for origin: Vector3i in [Vector3i(0, 0, 0), Vector3i(16, 16, 0), Vector3i(-32, -32, 48), Vector3i(80, -64, -16),
			Vector3i(-48, -16, 32), Vector3i(48, -48, 48)]:
		var buf := _generate(g, origin)
		for z in 16:
			for x in 16:
				for y in 16:
					var id := buf.get_voxel(x, y, z, CH)
					if id in [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND]:
						ores += 1
						assert_lt(origin.y + y, 0, "ores in the rock under the ice, never in the ice")
					assert_false(id in [BlockIds.STONE, BlockIds.DEEPSTONE, BlockIds.GRASS, BlockIds.DIRT,
						BlockIds.MOON_ROCK, BlockIds.MOON_DUST, BlockIds.BASALT, BlockIds.MARS_DUST, BlockIds.ICE],
						"no other world's ground on Europa")
	assert_gt(ores, 10, "a child can mine on Europa")


func test_neighbouring_chunks_meet_without_seams() -> void:
	var g := _gen()
	var s := g.space_shape()
	var mc := s.europa.mesa_centre()
	var x0 := mc.x + roundi(EuropaTerrain.MESA_RADIUS) - 8   # across the ice cliffs
	var z0 := mc.y
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


func test_the_crust_is_ice_in_its_chunks() -> void:
	var g := _gen()
	var s := g.space_shape()
	var sp := s.spawn_column()
	var p := sp + Vector2i(40, 3)
	var h := s.height_at(p.x, p.y)
	var buf := _generate(g, _chunk(p.x, h - 20, p.y))
	assert_gt(_count(buf, BlockIds.DEEP_ICE) + _count(buf, BlockIds.EUROPA_ICE), 3000, "a crust of ice")
	assert_gt(_count(_generate(g, _chunk(p.x, -20, p.y)), BlockIds.EUROPA_ROCK), 3000, "rock under it")
