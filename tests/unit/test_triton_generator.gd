extends GutTest
## Cosmos: Triton (world 27, spec §21b.2): its voxel generator is the space worlds' SpaceGenerator with planet TRITON:
## TritonTerrain's columns (the band's frost over a crust of nitrogen ice over the icy mantle of water ice, the cap's pink
## ice, its mottled patches, the geysers' vents, rings and streaks of dark dust, the cantaloupe terrain's dimples and
## ridges, the frozen lake's floor and terraces of ice lava, the crater), the landing pad, ores in the water ice, water-ice
## boulders and nitrogen crystals, the Neptune Lookout and the secrets with the Hopper Lander, written fast and equal to
## the slow per-block reference everywhere, with no seams.

const CH := VoxelBuffer.CHANNEL_TYPE
const SEED := 12345


func _gen(seed: int = SEED) -> SpaceGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.TRITON
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


func test_it_is_the_space_generator_with_triton_rules() -> void:
	var g := _gen()
	assert_true(g is SpaceGenerator)
	assert_eq(g.space_shape().planet, SpaceShape.TRITON)
	assert_not_null(g.space_shape().triton)
	assert_true(g._secrets is SpaceSecretRules)


## Every region's chunks, block by block, against the reference (features, the lookout and secrets included).
func test_every_region_matches_the_reference_block_rule() -> void:
	var g := _gen()
	var s := g.space_shape()
	var t := s.triton
	var sp := s.spawn_column()
	var lm: Dictionary = (g._secrets as SpaceSecretRules).landmark()
	var at: Vector3i = lm.anchor
	var crystal := Vector2i.ZERO
	var boulder := Vector2i.ZERO
	var mottle := Vector2i.ZERO
	for i in 60000:   # a grid over 1800 × 1800 blocks round the world's middle
		var x := (i % 300) * 6 - 900
		var z := (i / 300) * 9 - 900
		if mottle == Vector2i.ZERO and s.triton_kind(x, z) == TritonTerrain.MOTTLE:
			mottle = Vector2i(x, z)
		if s.tree_at(x, z) and not t.on_lookout(x, z, 1):
			if s.feature_at(x, s.height_at(x, z), z) == BlockIds.NITROGEN_CRYSTAL:
				crystal = Vector2i(x, z) if crystal == Vector2i.ZERO else crystal
			elif boulder == Vector2i.ZERO:
				boulder = Vector2i(x, z)
	assert_ne(crystal, Vector2i.ZERO, "a nitrogen crystal to check")
	assert_ne(boulder, Vector2i.ZERO, "a boulder to check")
	assert_ne(mottle, Vector2i.ZERO, "a mottled patch to check")
	var geyser := t.first_geyser()
	var lake := t.lake_centre()
	var cols: Array[Vector2i] = [sp, t.lookout, crystal, boulder, mottle, geyser, t.streak_centre(geyser, 20.0),
		t.cap_point_south_of(sp), t.first_melon_toward(sp), t.melon_site_near(t.first_melon_toward(sp) + Vector2i(-60, -60)),
		lake, lake + Vector2i(TritonTerrain.LAKE_R + 4, 0), t.crater_centre(), Vector2i(at.x, at.z)]
	var checked := 0
	for c in cols:
		var h := s.ground_at(c.x, c.y)
		for y in [h - 12, h - 2, h + 6]:
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


func test_the_neptune_lookout_is_written_by_the_pad() -> void:
	var g := _gen()
	var t := g.space_shape().triton
	var top := Vector3i(t.lookout.x + 1, t.lookout_y + 3, t.lookout.y - 1)
	var buf := _generate(g, _chunk(top.x, top.y, top.z))
	var l := top - _chunk(top.x, top.y, top.z)
	assert_eq(buf.get_voxel(l.x, l.y, l.z, CH), BlockIds.TELESCOPE, "the telescope looking at Neptune")
	var globe := Vector3i(t.lookout.x - 1, t.lookout_y + 1, t.lookout.y + 1)
	var gb := _generate(g, _chunk(globe.x, globe.y, globe.z))
	var lg := globe - _chunk(globe.x, globe.y, globe.z)
	assert_eq(gb.get_voxel(lg.x, lg.y, lg.z, CH), BlockIds.NEPTUNE_GLOBE)


func test_a_geyser_its_dust_and_the_pink_cap_in_their_chunks() -> void:
	var g := _gen()
	var s := g.space_shape()
	var v := s.triton.first_geyser()
	var gv := s.ground_at(v.x, v.y)
	var buf := _generate(g, _chunk(v.x, gv - 1, v.y))
	var l := Vector3i(v.x, gv - 1, v.y) - _chunk(v.x, gv - 1, v.y)
	assert_eq(buf.get_voxel(l.x, l.y, l.z, CH), BlockIds.NITROGEN_GEYSER, "the vent")
	assert_gt(_count(buf, BlockIds.GEYSER_DUST), 10, "its ring and trail of dark dust")
	var cap := s.triton.cap_point_south_of(s.spawn_column()) + Vector2i(0, 40)
	var top := _generate(g, _chunk(cap.x, s.height_at(cap.x, cap.y) - 1, cap.y))
	assert_gt(_count(top, BlockIds.PINK_ICE) + _count(top, BlockIds.MOTTLED_ICE), 100, "the pink cap")


func test_ores_only_in_the_water_ice() -> void:
	var g := _gen()
	var ores := 0
	for origin: Vector3i in [Vector3i(0, 0, 0), Vector3i(16, 16, 0), Vector3i(-32, -32, 48), Vector3i(80, -64, -16)]:
		var buf := _generate(g, origin)
		for id in [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND]:
			ores += _count(buf, id)
		for id in [BlockIds.STONE, BlockIds.DEEPSTONE, BlockIds.GRASS, BlockIds.DIRT, BlockIds.MOON_ROCK]:
			assert_eq(_count(buf, id), 0, "no other world's ground on Triton")
	assert_gt(ores, 10, "a child can mine the water ice")


func test_neighbouring_chunks_meet_without_seams() -> void:
	var g := _gen()
	var s := g.space_shape()
	var v := s.triton.first_geyser()
	var h := s.ground_at(v.x, v.y) - 2
	var oa := _chunk(v.x, h, v.y)
	var ob := oa + Vector3i(16, 0, 0)
	var a := _generate(g, oa)
	var b := _generate(g, ob)
	for z in 16:
		for y in 16:
			assert_eq(a.get_voxel(15, y, z, CH), g.reference_block(oa.x + 15, oa.y + y, oa.z + z))
			assert_eq(b.get_voxel(0, y, z, CH), g.reference_block(ob.x, ob.y + y, ob.z + z))
