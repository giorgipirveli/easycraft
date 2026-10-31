extends GutTest
## Owner feedback #55 (spec §21.2): the space worlds' voxel generator (SpaceGenerator, a MeadowsGenerator for any
## planet): SpaceShape's ground, the landing pad, ores in the planet's rock, its features (the Moon's crystals) and
## SpaceSecretRules' secrets written fast, equal to the slow per-block reference, without seams between chunks.

const CH := VoxelBuffer.CHANNEL_TYPE
const SEED := 12345


func _gen(planet: StringName) -> SpaceGenerator:
	var g := SpaceGenerator.new()
	g.planet = planet
	g.world_seed = SEED
	return g


func _generate(gen: SpaceGenerator, origin: Vector3i) -> VoxelBuffer:
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	gen._generate_block(buf, origin, 0)
	return buf


func _chunk(x: int, y: int, z: int) -> Vector3i:
	return Vector3i(floori(x / 16.0), floori(y / 16.0), floori(z / 16.0)) * 16


func test_it_is_a_meadows_generator_with_the_planets_rules() -> void:
	for planet: StringName in SpaceShape.PLANETS:
		var g := _gen(planet)
		assert_true(g is MeadowsGenerator)
		assert_true(g.space_shape() is SpaceShape)
		assert_eq(g.space_shape().planet, planet)
		assert_eq(g.space_shape().seed, SEED)
		assert_true(g._secrets is SpaceSecretRules)


func test_chunks_match_the_reference_block_rule() -> void:
	for planet: StringName in SpaceShape.PLANETS:
		var g := _gen(planet)
		var shape := g.space_shape()
		var sp := shape.spawn_column()
		var h := shape.height_at(sp.x, sp.y)
		var lm: Dictionary = (g._secrets as SpaceSecretRules).landmark()
		var at: Vector3i = lm.anchor
		var origins: Array[Vector3i] = [_chunk(sp.x, h - 2, sp.y), _chunk(sp.x, h - 20, sp.y), _chunk(sp.x, -40, sp.y),
			_chunk(sp.x, MeadowsShape.WORLD_BOTTOM, sp.y), _chunk(at.x, at.y, at.z), _chunk(at.x, at.y + 12, at.z),
			Vector3i(160, 32, -96), Vector3i(-208, 48, 144), Vector3i(64, 160, 64)]
		var checked := 0
		for origin in origins:
			var buf := _generate(g, origin)
			for z in 16:
				for x in 16:
					for y in 16:
						var w := origin + Vector3i(x, y, z)
						var got := buf.get_voxel(x, y, z, CH)
						var want := g.reference_block(w.x, w.y, w.z)
						if got != want:
							assert_eq(got, want, "%s at %s" % [planet, w])
							return
						checked += 1
		assert_eq(checked, origins.size() * 4096, "%s: every block checked" % planet)


func test_the_landing_pad_is_in_the_chunk_under_the_spawn() -> void:
	for planet: StringName in SpaceShape.PLANETS:
		var g := _gen(planet)
		var sp := g.space_shape().spawn_column()
		var h := g.space_shape().height_at(sp.x, sp.y)
		var origin := _chunk(sp.x, h - 1, sp.y)
		var buf := _generate(g, origin)
		var l := Vector3i(sp.x, h - 1, sp.y) - origin
		assert_eq(buf.get_voxel(l.x, l.y, l.z, CH), BlockIds.LANDING_PAD, planet)


func test_ores_only_replace_the_planets_rock() -> void:
	var g := _gen(SpaceShape.MOON)
	var ores := 0
	for origin: Vector3i in [Vector3i(0, 0, 0), Vector3i(16, 16, 0), Vector3i(-32, -32, 48), Vector3i(80, -64, -16)]:
		var buf := _generate(g, origin)
		for z in 16:
			for x in 16:
				for y in 16:
					var id := buf.get_voxel(x, y, z, CH)
					if id in [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND]:
						ores += 1
					assert_false(id in [BlockIds.STONE, BlockIds.DEEPSTONE, BlockIds.GRASS, BlockIds.DIRT, BlockIds.WATER],
						"no Green Meadows ground on the Moon")
	assert_gt(ores, 10, "a child can mine on the Moon")


func test_the_moon_has_crystals_in_its_chunks() -> void:
	var g := _gen(SpaceShape.MOON)
	var shape := g.space_shape()
	var crystals := 0
	for cz in range(-4, 4):
		for cx in range(-4, 4):
			var h := shape.height_at(cx * 16 + 8, cz * 16 + 8)
			var buf := _generate(g, _chunk(cx * 16, h, cz * 16))
			crystals += _count(buf, BlockIds.MOON_CRYSTAL)
	assert_gt(crystals, 5)


func _count(buf: VoxelBuffer, id: int) -> int:
	var n := 0
	for z in 16:
		for x in 16:
			for y in 16:
				if buf.get_voxel(x, y, z, CH) == id:
					n += 1
	return n


func test_neighbouring_chunks_meet_without_seams() -> void:
	var g := _gen(SpaceShape.MOON)
	var shape := g.space_shape()
	var h := shape.height_at(100, 100)
	var a := _generate(g, _chunk(96, h, 96))
	var b := _generate(g, _chunk(112, h, 96))
	var oa := _chunk(96, h, 96)
	var ob := _chunk(112, h, 96)
	for z in 16:
		for y in 16:
			assert_eq(a.get_voxel(15, y, z, CH), g.reference_block(oa.x + 15, oa.y + y, oa.z + z))
			assert_eq(b.get_voxel(0, y, z, CH), g.reference_block(ob.x, ob.y + y, ob.z + z))
