extends GutTest
## Cosmos: Titan (world 22, spec §21b.2): its voxel generator is the space worlds' SpaceGenerator with planet TITAN:
## TitanTerrain's columns (soil and ice pebbles over icy rock, the dunes' dark grains, the methane sea and lakes: the
## game's WATER over a wet bed up to TitanTerrain.LIQUID_TOP, the icy mountains), the landing pad, ores in the icy rock,
## ice boulders and shore crystals, and the secrets with the Landing Probe, written fast and equal to the slow per-block
## reference everywhere, with no seams.

const CH := VoxelBuffer.CHANNEL_TYPE
const SEED := 12345


func _gen(seed: int = SEED) -> SpaceGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.TITAN
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


func test_it_is_the_space_generator_with_titan_rules() -> void:
	var g := _gen()
	assert_true(g is SpaceGenerator)
	assert_eq(g.space_shape().planet, SpaceShape.TITAN)
	assert_not_null(g.space_shape().titan)
	assert_true(g._secrets is SpaceSecretRules)


## Every region's chunks, block by block, against the reference (features, liquid and secrets included).
func test_every_region_matches_the_reference_block_rule() -> void:
	var g := _gen()
	var s := g.space_shape()
	var t := s.titan
	var sp := s.spawn_column()
	var lm: Dictionary = (g._secrets as SpaceSecretRules).landmark()
	var at: Vector3i = lm.anchor
	var lake := Vector2i.ZERO
	var crystal := Vector2i.ZERO
	var boulder := Vector2i.ZERO
	for i in 40000:
		var x := (i * 29) % 1600 - 800
		var z := (i * 47) % 1600 - 800
		if lake == Vector2i.ZERO and s.titan_kind(x, z) == TitanTerrain.LAKE:
			lake = Vector2i(x, z)
		if s.tree_at(x, z):
			if s.feature_at(x, s.height_at(x, z), z) == BlockIds.SHORE_CRYSTAL:
				crystal = Vector2i(x, z) if crystal == Vector2i.ZERO else crystal
			elif boulder == Vector2i.ZERO:
				boulder = Vector2i(x, z)
	assert_ne(lake, Vector2i.ZERO, "a lake to check")
	assert_ne(crystal, Vector2i.ZERO, "a shore crystal to check")
	var beach := t.sea_beach_toward(sp)
	var dune := t.first_dune_south_of(sp)
	var pk := t.peak_centre()
	var cols: Array[Vector2i] = [sp, lake, crystal, boulder, beach, beach + Vector2i(0, -20), dune, dune + Vector2i(9, 9),
		Vector2i(at.x, at.z), pk, pk + Vector2i(20, 0), t.sea_centre()]
	var checked := 0
	for c in cols:
		var h := s.ground_at(c.x, c.y)
		for y in [h - 10, h - 2, h + 6]:
			checked += _same(g, _chunk(c.x, y, c.y))
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


func test_the_sea_is_liquid_in_its_chunks() -> void:
	var g := _gen()
	var sc := g.space_shape().titan.sea_centre()
	var top := TitanTerrain.LIQUID_TOP
	var buf := _generate(g, _chunk(sc.x, top - 1, sc.y))
	var l := Vector3i(sc.x, top - 1, sc.y) - _chunk(sc.x, top - 1, sc.y)
	assert_eq(buf.get_voxel(l.x, l.y, l.z, CH), BlockIds.WATER, "liquid methane at the top")
	assert_gt(_count(buf, BlockIds.WATER), 1000, "a sea of it")
	var above := _generate(g, _chunk(sc.x, top + 16, sc.y))
	assert_eq(_count(above, BlockIds.WATER), 0, "nothing over its top")


func test_ores_only_in_the_icy_rock_and_dunes_in_their_chunks() -> void:
	var g := _gen()
	var s := g.space_shape()
	var ores := 0
	for origin: Vector3i in [Vector3i(0, 0, 0), Vector3i(16, 16, 0), Vector3i(-32, -32, 48), Vector3i(80, -64, -16)]:
		var buf := _generate(g, origin)
		for id in [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND]:
			ores += _count(buf, id)
		for id in [BlockIds.STONE, BlockIds.DEEPSTONE, BlockIds.GRASS, BlockIds.DIRT]:
			assert_eq(_count(buf, id), 0, "no Green Meadows ground on Titan")
	assert_gt(ores, 10, "a child can mine the icy rock")
	var dune := s.titan.first_dune_south_of(s.spawn_column())
	var top := _generate(g, _chunk(dune.x, s.height_at(dune.x, dune.y) - 1, dune.y))
	assert_gt(_count(top, BlockIds.DUNE_SAND), 100, "dark dune grains")


func test_neighbouring_chunks_meet_without_seams() -> void:
	var g := _gen()
	var s := g.space_shape()
	var beach := s.titan.sea_beach_toward(s.spawn_column())
	var h := TitanTerrain.LIQUID_TOP - 2
	var oa := _chunk(beach.x, h, beach.y)
	var ob := oa + Vector3i(16, 0, 0)
	var a := _generate(g, oa)
	var b := _generate(g, ob)
	for z in 16:
		for y in 16:
			assert_eq(a.get_voxel(15, y, z, CH), g.reference_block(oa.x + 15, oa.y + y, oa.z + z))
			assert_eq(b.get_voxel(0, y, z, CH), g.reference_block(ob.x, ob.y + y, ob.z + z))
