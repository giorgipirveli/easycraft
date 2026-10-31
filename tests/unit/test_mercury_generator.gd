extends GutTest
## Cosmos: Mercury (world 23, spec §21b.2): its voxel generator is the space worlds' SpaceGenerator with planet MERCURY:
## MercuryTerrain's columns (grey dust over grey rock, darker patches, bright rays, the big craters' rocky terraced walls
## and floors, the long cliffs' rocky faces, the ice on the polar craters' floors), the landing pad, ores in the rock,
## rock boulders, ice crystals and the explorers' thermometer, and the secrets with the Sunshade Lander, written fast and
## equal to the slow per-block reference everywhere, with no seams.

const CH := VoxelBuffer.CHANNEL_TYPE
const SEED := 12345


func _gen(seed: int = SEED) -> SpaceGenerator:
	var g := SpaceGenerator.new()
	g.planet = SpaceShape.MERCURY
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


func test_it_is_the_space_generator_with_mercury_rules() -> void:
	var g := _gen()
	assert_true(g is SpaceGenerator)
	assert_eq(g.space_shape().planet, SpaceShape.MERCURY)
	assert_not_null(g.space_shape().mercury)
	assert_true(g._secrets is SpaceSecretRules)


## Every region's chunks, block by block, against the reference (features and secrets included).
func test_every_region_matches_the_reference_block_rule() -> void:
	var g := _gen()
	var s := g.space_shape()
	var m := s.mercury
	var sp := s.spawn_column()
	var lm: Dictionary = (g._secrets as SpaceSecretRules).landmark()
	var at: Vector3i = lm.anchor
	var ray := Vector2i.ZERO
	var dark := Vector2i.ZERO
	var boulder := Vector2i.ZERO
	for i in 40000:
		var x := (i * 29) % 1600 - 800
		var z := (i * 47) % 1600 - 800
		var k := s.mercury_kind(x, z)
		if ray == Vector2i.ZERO and k == MercuryTerrain.RAY:
			ray = Vector2i(x, z)
		if dark == Vector2i.ZERO and k == MercuryTerrain.DARK:
			dark = Vector2i(x, z)
		if boulder == Vector2i.ZERO and s.tree_at(x, z) and s.feature_at(x, s.height_at(x, z), z) == BlockIds.MERCURY_ROCK:
			boulder = Vector2i(x, z)
		if ray != Vector2i.ZERO and dark != Vector2i.ZERO and boulder != Vector2i.ZERO:
			break
	assert_ne(ray, Vector2i.ZERO, "a ray to check")
	assert_ne(boulder, Vector2i.ZERO, "a boulder to check")
	var face := m.great_face_toward(sp)
	var crater := m.nearest_crater(sp)
	var ic := m.ice_centre()
	var t := s.thermometer_column()
	var cols: Array[Vector2i] = [sp, t, ray, dark, boulder, face, face + Vector2i(9, 9), crater, crater + Vector2i(18, 5),
		ic, ic + Vector2i(10, -4), Vector2i(at.x, at.z)]
	var checked := 0
	for c in cols:
		var h := s.ground_at(c.x, c.y)
		for y in [h - 10, h - 2, h + 6]:
			checked += _same(g, _chunk(c.x, y, c.y))
	for origin: Vector3i in [_chunk(sp.x, -40, sp.y), _chunk(sp.x, MeadowsShape.WORLD_BOTTOM, sp.y), Vector3i(64, 160, 64)]:
		checked += _same(g, origin)
	assert_eq(checked, (cols.size() * 3 + 3) * 4096, "every block checked")


func test_the_landing_pad_and_the_thermometer_are_in_their_chunks() -> void:
	var g := _gen()
	var s := g.space_shape()
	var sp := s.spawn_column()
	var h := s.height_at(sp.x, sp.y)
	var origin := _chunk(sp.x, h - 1, sp.y)
	var l := Vector3i(sp.x, h - 1, sp.y) - origin
	assert_eq(_generate(g, origin).get_voxel(l.x, l.y, l.z, CH), BlockIds.LANDING_PAD)
	var t := s.thermometer_column()
	var bulb := Vector3i(t.x, s.height_at(t.x, t.y) + 1, t.y)
	var o := _chunk(bulb.x, bulb.y, bulb.z)
	var b := bulb - o
	assert_eq(_generate(g, o).get_voxel(b.x, b.y, b.z, CH), BlockIds.THERMO_BULB, "the thermometer's red bulb")


func test_the_cliffs_face_and_the_ice_are_in_their_chunks() -> void:
	var g := _gen()
	var s := g.space_shape()
	var face := s.mercury.great_face_toward(s.spawn_column())
	var top := s.height_at(face.x, face.y) - 1
	var buf := _generate(g, _chunk(face.x, top, face.y))
	var l := Vector3i(face.x, top, face.y) - _chunk(face.x, top, face.y)
	assert_eq(buf.get_voxel(l.x, l.y, l.z, CH), BlockIds.MERCURY_ROCK, "rock on the cliff's face")
	var ic := s.mercury.ice_centre()
	var ih := s.height_at(ic.x, ic.y) - 1
	var ice := _generate(g, _chunk(ic.x, ih, ic.y))
	assert_gt(_count(ice, BlockIds.SHADOW_ICE), 200, "the ice crater's floor")
	assert_eq(_count(ice, BlockIds.WATER), 0, "ice, never water")


func test_ores_only_in_the_rock_and_no_other_worlds_ground() -> void:
	var g := _gen()
	var ores := 0
	for origin: Vector3i in [Vector3i(0, 0, 0), Vector3i(16, 16, 0), Vector3i(-32, -32, 48), Vector3i(80, -64, -16)]:
		var buf := _generate(g, origin)
		for id in [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND]:
			ores += _count(buf, id)
		for id in [BlockIds.STONE, BlockIds.DEEPSTONE, BlockIds.GRASS, BlockIds.DIRT, BlockIds.MOON_ROCK, BlockIds.WATER]:
			assert_eq(_count(buf, id), 0, "no other world's ground on Mercury")
	assert_gt(ores, 10, "a child can mine Mercury's rock")


func test_neighbouring_chunks_meet_without_seams() -> void:
	var g := _gen()
	var s := g.space_shape()
	var face := s.mercury.great_face_toward(s.spawn_column())
	var h := s.height_at(face.x, face.y) - 4
	var oa := _chunk(face.x, h, face.y)
	var ob := oa + Vector3i(16, 0, 0)
	var a := _generate(g, oa)
	var b := _generate(g, ob)
	for z in 16:
		for y in 16:
			assert_eq(a.get_voxel(15, y, z, CH), g.reference_block(oa.x + 15, oa.y + y, oa.z + z))
			assert_eq(b.get_voxel(0, y, z, CH), g.reference_block(ob.x, ob.y + y, ob.z + z))
