extends GutTest
## Cosmos: Io (world 21, spec §21b.2): its voxel generator is the space worlds' SpaceGenerator with planet IO: IoTerrain's
## columns (sulphur plains over Io's rock with black lava layers, the volcanoes' cones, vents and red rings, the small
## lava lakes, the big lava lake's crust, hot lava, rim and causeways, the mountain), the landing pad, ores in Io's rock,
## sulphur crystals and lava boulders, and the secrets with the Volcano Lander, written fast and equal to the slow
## per-block reference everywhere, with no seams.

const CH := VoxelBuffer.CHANNEL_TYPE
const SEED := 12345


func _gen(seed: int = SEED) -> SpaceGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.IO
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


func test_it_is_the_space_generator_with_io_rules() -> void:
	var g := _gen()
	assert_true(g is SpaceGenerator)
	assert_eq(g.space_shape().planet, SpaceShape.IO)
	assert_not_null(g.space_shape().io)
	assert_true(g._secrets is SpaceSecretRules)


## Every region's chunks, block by block, against the reference (features and secrets included).
func test_every_region_matches_the_reference_block_rule() -> void:
	var g := _gen()
	var s := g.space_shape()
	var io := s.io
	var sp := s.spawn_column()
	var lc := io.lake_centre()
	var vent := io.nearest_vent(sp)
	var lm: Dictionary = (g._secrets as SpaceSecretRules).landmark()
	var at: Vector3i = lm.anchor
	var patera := Vector2i.ZERO
	var crystal := Vector2i.ZERO
	for i in 20000:
		var x := (i * 29) % 1600 - 800
		var z := (i * 47) % 1600 - 800
		if patera == Vector2i.ZERO and s.io_kind(x, z) == IoTerrain.PATERA:
			patera = Vector2i(x, z)
		if crystal == Vector2i.ZERO and s.tree_at(x, z):
			crystal = Vector2i(x, z)
	var cols: Array[Vector2i] = [sp, vent, vent + Vector2i(14, 0), patera, crystal, Vector2i(at.x, at.z),
		io.peak_centre(), io.peak_centre() + Vector2i(roundi(io.mountain_up().x * 20), roundi(io.mountain_up().y * 20))]
	var checked := 0
	for c in cols:
		var h := s.height_at(c.x, c.y)
		for y in [h - 10, h - 2, h + 6]:
			checked += _same(g, _chunk(c.x, y, c.y))
	var lake := 0
	for dx: int in [-32, -16, 0, 16, 32]:   # the whole lava lake: its crust, moat, rim and causeways
		for dz: int in [-32, -16, 0, 16, 32]:
			for y in range(io.lake_top() - 24, io.lake_top() + 8, 16):
				lake += _same(g, _chunk(lc.x + dx, y, lc.y + dz))
	for origin: Vector3i in [_chunk(sp.x, -40, sp.y), _chunk(sp.x, MeadowsShape.WORLD_BOTTOM, sp.y), Vector3i(64, 160, 64)]:
		checked += _same(g, origin)
	assert_eq(checked, (cols.size() * 3 + 3) * 4096, "every block checked")
	assert_eq(lake, 50 * 4096, "every block of the lava lake checked")


func test_the_landing_pad_is_in_the_chunk_under_the_spawn() -> void:
	var g := _gen()
	var sp := g.space_shape().spawn_column()
	var h := g.space_shape().height_at(sp.x, sp.y)
	var origin := _chunk(sp.x, h - 1, sp.y)
	var l := Vector3i(sp.x, h - 1, sp.y) - origin
	assert_eq(_generate(g, origin).get_voxel(l.x, l.y, l.z, CH), BlockIds.LANDING_PAD)


func test_the_lava_lake_glows_in_its_chunks() -> void:
	var g := _gen()
	var io := g.space_shape().io
	var lc := io.lake_centre()
	var crust := io.lake_top() - IoTerrain.LAKE_DOWN
	var buf := _generate(g, _chunk(lc.x, crust - 1, lc.y))
	var l := Vector3i(lc.x, crust - 1, lc.y) - _chunk(lc.x, crust - 1, lc.y)
	assert_eq(buf.get_voxel(l.x, l.y, l.z, CH), BlockIds.LAVA_CRUST, "the crust")
	var moat := 0
	for dx: int in [-32, -16, 0, 16]:
		for dz: int in [-32, -16, 0, 16]:
			moat += _count(_generate(g, _chunk(lc.x + dx, crust - 2, lc.y + dz)), BlockIds.HOT_LAVA)
	assert_gt(moat, 200, "hot lava in the moat and under the crust")


func test_ores_only_in_ios_rock_and_no_other_worlds_ground() -> void:
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
					assert_false(id in [BlockIds.STONE, BlockIds.DEEPSTONE, BlockIds.GRASS, BlockIds.DIRT, BlockIds.WATER,
						BlockIds.MOON_ROCK, BlockIds.MOON_DUST, BlockIds.BASALT, BlockIds.MARS_DUST, BlockIds.EUROPA_ICE,
						BlockIds.DEEP_ICE], "no other world's ground on Io")
	assert_gt(ores, 10, "a child can mine on Io")


func test_neighbouring_chunks_meet_without_seams() -> void:
	var g := _gen()
	var s := g.space_shape()
	var lc := s.io.lake_centre()
	var x0 := lc.x + IoTerrain.LAKE_R - 8   # across the lava lake's moat and rim
	var z0 := lc.y
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


func test_the_ground_is_sulphur_over_rock_in_its_chunks() -> void:
	var g := _gen()
	var s := g.space_shape()
	var sp := s.spawn_column()
	var p := sp + Vector2i(40, 3)
	var h := s.height_at(p.x, p.y)
	var buf := _generate(g, _chunk(p.x, h - 20, p.y))
	assert_gt(_count(buf, BlockIds.IO_ROCK) + _count(buf, BlockIds.BLACK_LAVA), 3000, "Io's rock")
	var top := _generate(g, _chunk(p.x, h - 1, p.y))
	assert_gt(_count(top, BlockIds.SULPHUR) + _count(top, BlockIds.ORANGE_SULPHUR) + _count(top, BlockIds.SULPHUR_FROST), 100,
		"a blanket of sulphur")
