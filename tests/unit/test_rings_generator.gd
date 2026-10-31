extends GutTest
## Cosmos: Saturn's rings (world 25, spec §21b.2): its voxel generator is the space worlds' SpaceGenerator with planet
## RINGS: open space everywhere (no bedrock, no deep rock: nothing under the rings), each column's span of ice (a frosty
## top on the clean ice, the C ring's dusty ice, rock lumps, Pan's ice and ridge dust), the landing pad, the built parts
## (the Ring Station, the Saturn scope, the Saturn model, the beacons) and the secrets with the Ring Explorer, written
## fast and equal to the slow per-block reference everywhere, with no seams and no ores.

const CH := VoxelBuffer.CHANNEL_TYPE
const SEED := 12345


func _gen(seed: int = SEED) -> SpaceGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.RINGS
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


func test_it_is_the_space_generator_with_the_rings_rules() -> void:
	var g := _gen()
	assert_true(g is SpaceGenerator)
	assert_eq(g.space_shape().planet, SpaceShape.RINGS)
	assert_not_null(g.space_shape().rings)
	assert_true(g._secrets is SpaceSecretRules)


## Every part of the rings' chunks, block by block, against the reference (built parts and secrets included).
func test_every_part_matches_the_reference_block_rule() -> void:
	for seed: int in [SEED, 77]:
		var g := _gen(seed)
		var s := g.space_shape()
		var r := s.rings
		var sp := s.spawn_column()
		var lm: Dictionary = (g._secrets as SpaceSecretRules).landmark()
		var at: Vector3i = lm.anchor
		var sx := -1 if r.flip else 1
		var dusty := Vector2i.ZERO
		var rock := Vector2i.ZERO
		for z in range(sp.y - 280, sp.y + 80, 2):
			for x in range(sp.x - 200, sp.x + 200, 2):
				var k := r.kind_at(x, z)
				if dusty == Vector2i.ZERO and k == RingsTerrain.DUSTY_FLAT:
					dusty = Vector2i(x, z)
				if rock == Vector2i.ZERO and k == RingsTerrain.ROCK_LUMP:
					rock = Vector2i(x, z)
			if dusty != Vector2i.ZERO and rock != Vector2i.ZERO:
				break
		assert_ne(dusty, Vector2i.ZERO, "a dusty C ring chunk to check")
		assert_ne(rock, Vector2i.ZERO, "a rock lump to check")
		var cols: Array[Vector2i] = [sp, sp + Vector2i(0, -RingsTerrain.SCOPE_OUT),
			sp + Vector2i(RingsTerrain.STATION.x * sx, RingsTerrain.STATION.y),
			sp + Vector2i(RingsTerrain.MODEL.x * sx, RingsTerrain.MODEL.y), r.centre(RingsTerrain.CAMP),
			r.centre(RingsTerrain.EDGE) + Vector2i(0, 8), r.centre(&"pan"), r.centre(&"pan") + Vector2i(12, 3),
			r.centre(RingsTerrain.F_SPOT) + Vector2i(20, 0), r.centre(RingsTerrain.C_SPOT), dusty, rock,
			Vector2i(at.x, at.z), Vector2i(at.x + 10, at.z)]
		var checked := 0
		for c in cols:
			for y in [44, 56, 66, 72]:
				checked += _same(g, _chunk(c.x, y, c.y))
		for origin: Vector3i in [_chunk(sp.x, -40, sp.y), _chunk(sp.x, MeadowsShape.WORLD_BOTTOM, sp.y),
				Vector3i(64, 160, 64), Vector3i(-400, 48, 512), Vector3i(-400, 64, 512)]:
			checked += _same(g, origin)
		assert_eq(checked, (cols.size() * 4 + 5) * 4096, "every block checked (seed %d)" % seed)


func test_the_landing_pad_the_chunk_and_open_space_are_in_their_chunks() -> void:
	var g := _gen()
	var s := g.space_shape()
	var sp := s.spawn_column()
	var y := RingsTerrain.TOP_BASE - 1
	var origin := _chunk(sp.x, y, sp.y)
	var l := Vector3i(sp.x, y, sp.y) - origin
	var buf := _generate(g, origin)
	assert_eq(buf.get_voxel(l.x, l.y, l.z, CH), BlockIds.LANDING_PAD)
	assert_gt(_count(buf, BlockIds.RING_FROST), 150, "the landing chunk's frosty top")
	assert_gt(_count(_generate(g, _chunk(sp.x, 52, sp.y)), BlockIds.RING_ICE), 1000, "its ice")
	assert_eq(_count(_generate(g, _chunk(sp.x, 8, sp.y)), BlockIds.AIR), 4096, "open space far under it")
	assert_eq(_count(_generate(g, _chunk(sp.x, MeadowsShape.WORLD_BOTTOM, sp.y)), BlockIds.AIR), 4096,
		"no bedrock: nothing under the rings")
	var north := sp + Vector2i(0, RingsTerrain.C_IN - 60)
	assert_eq(_count(_generate(g, _chunk(north.x, 64, north.y)), BlockIds.AIR), 4096, "space between the rings and Saturn")


func test_the_built_parts_are_in_their_chunks() -> void:
	var g := _gen()
	var r := g.space_shape().rings
	var sp := r.spawn()
	var y := RingsTerrain.TOP_BASE
	var scope := Vector3i(sp.x, y + 1, sp.y - RingsTerrain.SCOPE_OUT)
	var o := _chunk(scope.x, scope.y, scope.z)
	assert_eq(_generate(g, o).get_voxel(scope.x - o.x, scope.y - o.y, scope.z - o.z, CH), BlockIds.TELESCOPE, "the scope")
	var sx := -1 if r.flip else 1
	var st := sp + Vector2i(RingsTerrain.STATION.x * sx, RingsTerrain.STATION.y)
	assert_gt(_count(_generate(g, _chunk(st.x, y, st.y)), BlockIds.STATION_PANEL), 20, "the station's walls")
	var p := r.centre(&"pan")
	var beacon := Vector3i(p.x, RingsTerrain.PAN_Y + RingsTerrain.PAN_HALF + 1, p.y)
	var po := _chunk(beacon.x, beacon.y, beacon.z)
	assert_eq(_generate(g, po).get_voxel(beacon.x - po.x, beacon.y - po.y, beacon.z - po.z, CH), BlockIds.RING_BEACON,
		"Pan's beacon")


func test_no_ores_and_no_other_worlds_ground() -> void:
	var g := _gen()
	var sp := g.space_shape().spawn_column()
	for origin: Vector3i in [Vector3i(0, 0, 0), Vector3i(16, 48, 0), Vector3i(-32, 48, 48), Vector3i(80, -64, -16),
			_chunk(sp.x, RingsTerrain.TOP_BASE - 1, sp.y), _chunk(sp.x, 48, sp.y)]:
		var buf := _generate(g, origin)
		for id in [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND, BlockIds.STONE, BlockIds.DEEPSTONE,
				BlockIds.GRASS, BlockIds.DIRT, BlockIds.MOON_ROCK, BlockIds.BEDROCK, BlockIds.DEEP_CLOUD]:
			assert_eq(_count(buf, id), 0, "no ore, no bedrock and no other world's ground (%s)" % origin)


func test_neighbouring_chunks_meet_without_seams() -> void:
	var g := _gen()
	var sp := g.space_shape().spawn_column()
	var oa := _chunk(sp.x + 40, 56, sp.y - 40)
	var ob := oa + Vector3i(16, 0, 0)
	var a := _generate(g, oa)
	var b := _generate(g, ob)
	for z in 16:
		for y in 16:
			assert_eq(a.get_voxel(15, y, z, CH), g.reference_block(oa.x + 15, oa.y + y, oa.z + z))
			assert_eq(b.get_voxel(0, y, z, CH), g.reference_block(ob.x, ob.y + y, ob.z + z))
