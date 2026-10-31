extends GutTest
## Cosmos: Venus's cloud city (world 24, spec §21b.2): its voxel generator is the space worlds' SpaceGenerator with planet
## VENUS: the clouds in every column (deep clouds under their yellow tops), the platforms' float hulls and decks and the
## bridges' keels and planks over them, the landing pad, the lamp posts, flowers and little trees, the city's built
## parts (the cloud scope, the dock's mast, the garden's pond, the homes, the west lookout) and the secrets with the
## Research Blimp, written fast and equal to the slow per-block reference everywhere, with no seams and no ores (no rock
## in the clouds).

const CH := VoxelBuffer.CHANNEL_TYPE
const SEED := 12345


func _gen(seed: int = SEED) -> SpaceGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.VENUS
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


func test_it_is_the_space_generator_with_venus_rules() -> void:
	var g := _gen()
	assert_true(g is SpaceGenerator)
	assert_eq(g.space_shape().planet, SpaceShape.VENUS)
	assert_not_null(g.space_shape().venus)
	assert_true(g._secrets is SpaceSecretRules)


## Every part of the city's chunks, block by block, against the reference (features, built parts and secrets included).
func test_every_part_matches_the_reference_block_rule() -> void:
	for seed: int in [SEED, 77]:
		var g := _gen(seed)
		var s := g.space_shape()
		var v := s.venus
		var sp := s.spawn_column()
		var lm: Dictionary = (g._secrets as SpaceSecretRules).landmark()
		var at: Vector3i = lm.anchor
		var tree := Vector2i.ZERO
		var lamp := Vector2i.ZERO
		for z in range(sp.y - 120, sp.y + 120):
			for x in range(sp.x - 120, sp.x + 120, 2):
				var f := v.feature_at(x, z)
				if tree == Vector2i.ZERO and f == VenusTerrain.TREE:
					tree = Vector2i(x, z)
				if lamp == Vector2i.ZERO and f == VenusTerrain.LAMP and v.kind_at(x, z) == VenusTerrain.BRIDGE:
					lamp = Vector2i(x, z)
			if tree != Vector2i.ZERO and lamp != Vector2i.ZERO:
				break
		assert_ne(tree, Vector2i.ZERO, "a little tree to check")
		assert_ne(lamp, Vector2i.ZERO, "a bridge's lamp to check")
		var isle := Vector2i.ZERO
		for cx in range(3, 8):
			var i := v.isle(Vector2i(cx, 2))
			if not i.is_empty():
				isle = Vector2i(i[1], i[2])
				break
		var cols: Array[Vector2i] = [sp, sp - v.north() * VenusTerrain.SCOPE_OUT, v.centre(VenusTerrain.DOCK),
			v.centre(VenusTerrain.DOCK) + v.north() * 8, v.centre(VenusTerrain.GARDEN_DECK),
			v.centre(VenusTerrain.HOMES) + Vector2i(5, 5), v.centre(VenusTerrain.LOOKOUT) + Vector2i(-8, 0), tree, lamp,
			isle, Vector2i(at.x, at.z), Vector2i(at.x + 10, at.z)]
		var checked := 0
		for c in cols:
			for y in [VenusTerrain.DECK_Y - 20, VenusTerrain.DECK_Y - 2, VenusTerrain.DECK_Y + 6, v.cloud_top(c.x, c.y) - 1]:
				checked += _same(g, _chunk(c.x, y, c.y))
		for origin: Vector3i in [_chunk(sp.x, -40, sp.y), _chunk(sp.x, MeadowsShape.WORLD_BOTTOM, sp.y),
				Vector3i(64, 160, 64), Vector3i(-400, 48, 512), Vector3i(-400, 32, 512)]:
			checked += _same(g, origin)
		assert_eq(checked, (cols.size() * 4 + 5) * 4096, "every block checked (seed %d)" % seed)


func test_the_landing_pad_the_deck_and_the_clouds_are_in_their_chunks() -> void:
	var g := _gen()
	var s := g.space_shape()
	var sp := s.spawn_column()
	var y := VenusTerrain.DECK_Y - 1
	var origin := _chunk(sp.x, y, sp.y)
	var l := Vector3i(sp.x, y, sp.y) - origin
	var buf := _generate(g, origin)
	assert_eq(buf.get_voxel(l.x, l.y, l.z, CH), BlockIds.LANDING_PAD)
	assert_gt(_count(buf, BlockIds.CLOUD_DECK), 150, "the landing deck")
	assert_gt(_count(buf, BlockIds.FLOAT_HULL), 150, "over its float hull")
	var ct := s.venus.cloud_top(sp.x, sp.y) - 1
	var clouds := _generate(g, _chunk(sp.x, ct, sp.y))
	assert_gt(_count(clouds, BlockIds.VENUS_CLOUD) + _count(clouds, BlockIds.DEEP_CLOUD), 1000, "the clouds far below")
	assert_gt(_count(_generate(g, _chunk(sp.x, 8, sp.y)), BlockIds.DEEP_CLOUD), 4000, "deep clouds under them")
	var open := sp - s.venus.north() * 32   # beyond the landing deck, on the open side
	assert_eq(_count(_generate(g, _chunk(open.x, 50, open.y)), BlockIds.AIR), 4096,
		"open air between the clouds and the city")


func test_the_built_parts_are_in_their_chunks() -> void:
	var g := _gen()
	var v := g.space_shape().venus
	var y := VenusTerrain.DECK_Y
	var dock := v.centre(VenusTerrain.DOCK)
	var mast := dock + v.north() * VenusTerrain.MAST_OUT + Vector2i(VenusTerrain.MAST_SIDE, 0)
	var top := Vector3i(mast.x, y + VenusTerrain.MAST_H, mast.y)
	var o := _chunk(top.x, top.y, top.z)
	assert_eq(_generate(g, o).get_voxel(top.x - o.x, top.y - o.y, top.z - o.z, CH), BlockIds.CLOUD_LAMP, "the mast's lamp")
	var gd := v.centre(VenusTerrain.GARDEN_DECK)
	var pond := Vector3i(gd.x + 1, y - 1, gd.y)
	var po := _chunk(pond.x, pond.y, pond.z)
	assert_eq(_generate(g, po).get_voxel(pond.x - po.x, pond.y - po.y, pond.z - po.z, CH), BlockIds.WATER, "the pond")
	var hm := v.centre(VenusTerrain.HOMES) + Vector2i(5, 5)
	var ho := _chunk(hm.x, y + 1, hm.y)
	assert_gt(_count(_generate(g, ho), BlockIds.HOME_PANEL), 20, "a home's walls")


func test_no_ores_and_no_other_worlds_ground() -> void:
	var g := _gen()
	var sp := g.space_shape().spawn_column()
	for origin: Vector3i in [Vector3i(0, 0, 0), Vector3i(16, 16, 0), Vector3i(-32, -32, 48), Vector3i(80, -64, -16),
			_chunk(sp.x, VenusTerrain.DECK_Y - 1, sp.y), _chunk(sp.x, 32, sp.y)]:
		var buf := _generate(g, origin)
		for id in [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND, BlockIds.STONE, BlockIds.DEEPSTONE,
				BlockIds.GRASS, BlockIds.DIRT, BlockIds.MOON_ROCK, BlockIds.MERCURY_ROCK]:
			assert_eq(_count(buf, id), 0, "no rock in Venus's clouds and no other world's ground (%s)" % origin)


func test_neighbouring_chunks_meet_without_seams() -> void:
	var g := _gen()
	var v := g.space_shape().venus
	var dock := v.centre(VenusTerrain.DOCK)
	var oa := _chunk(dock.x, VenusTerrain.DECK_Y - 4, dock.y)
	var ob := oa + Vector3i(16, 0, 0)
	var a := _generate(g, oa)
	var b := _generate(g, ob)
	for z in 16:
		for y in 16:
			assert_eq(a.get_voxel(15, y, z, CH), g.reference_block(oa.x + 15, oa.y + y, oa.z + z))
			assert_eq(b.get_voxel(0, y, z, CH), g.reference_block(ob.x, ob.y + y, ob.z + z))
