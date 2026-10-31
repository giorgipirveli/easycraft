extends GutTest
## Owner feedback #39: the Dragon Realm's voxel generator (DragonGenerator, a MeadowsGenerator): DragonShape's islands,
## clouds, ores and plants and DragonSecretRules' secrets written fast, equal to the slow per-block reference, and
## without seams between chunks (every rule is a function of world coordinates); the void below the islands is air.

const CH := VoxelBuffer.CHANNEL_TYPE
const SEED := 12345

var _gen: DragonGenerator


func before_all() -> void:
	_gen = DragonGenerator.new()
	_gen.world_seed = SEED


func _generate(origin: Vector3i, gen: DragonGenerator = _gen) -> VoxelBuffer:
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	gen._generate_block(buf, origin, 0)
	return buf


func _plant_near(x: int, z: int) -> bool:
	var shape := _gen.dragon_shape()
	for dz in range(-DragonShape.PLANT_REACH, DragonShape.PLANT_REACH + 1):
		for dx in range(-DragonShape.PLANT_REACH, DragonShape.PLANT_REACH + 1):
			if shape.plant_at(x + dx, z + dz) != DragonShape.NO_PLANT:
				return true
	return false


func _chunk_at(spot: Vector2i, y: int) -> Vector3i:
	return Vector3i(floori(spot.x / 16.0) * 16, floori(y / 16.0) * 16, floori(spot.y / 16.0) * 16)


## A column of the kind wanted: an island's rim, a deep island, a cloud.
func _find(want: Callable) -> Vector2i:
	var shape := _gen.dragon_shape()
	for z in range(-400, 400, 5):
		for x in range(-400, 400, 5):
			if want.call(shape, x, z):
				return Vector2i(x, z)
	return Vector2i.ZERO


func test_it_is_a_meadows_generator_with_dragon_rules() -> void:
	assert_true(_gen is MeadowsGenerator)
	assert_true(_gen.dragon_shape() is DragonShape)
	assert_eq(_gen.dragon_shape().seed, SEED)
	assert_true(_gen._secrets is DragonSecretRules)
	var fresh := DragonGenerator.new()
	assert_true(fresh.dragon_shape() is DragonShape, "a new one has the realm's rules before a seed is set")


## Island tops, undersides, rims, clouds and deep rock with ores: the fast path equals the reference.
func test_chunks_match_the_reference_block_rule() -> void:
	var shape := _gen.dragon_shape()
	var s := shape.spawn_column()
	var col := shape.column(s.x, s.y)
	var origins: Array[Vector3i] = [_chunk_at(s, col.x - 2), _chunk_at(s, col.y + 2), _chunk_at(s, col.z),
		_chunk_at(s, col.x - 20), Vector3i(-64, 16, 80), Vector3i(96, 48, -32)]
	var rim := _find(func(sh: DragonShape, x: int, z: int) -> bool:
		var c := sh.column(x, z)
		return c.x > c.y and c.x - c.y <= DragonShape.EDGE_THICK + 1 and Vector2(x - s.x, z - s.y).length() > 90)
	var rc := shape.column(rim.x, rim.y)
	origins.append(_chunk_at(rim, rc.x - 2))
	var cloud := _find(func(sh: DragonShape, x: int, z: int) -> bool:
		var cl := sh.cloud_at(x, z)
		return cl.x < cl.y and Vector2(x - s.x, z - s.y).length() > 90)
	origins.append(_chunk_at(cloud, shape.cloud_at(cloud.x, cloud.y).x))
	var checked := 0
	for origin in origins:
		var buf := _generate(origin)
		for z in 16:
			for x in 16:
				if _plant_near(origin.x + x, origin.z + z):
					continue
				for y in 16:
					var w := origin + Vector3i(x, y, z)
					var want := _gen.reference_block(w.x, w.y, w.z)
					if buf.get_voxel(x, y, z, CH) != want:
						assert_eq(buf.get_voxel(x, y, z, CH), want, "block at %s" % w)
						return
					checked += 1
	assert_gt(checked, 20000, "most of 8 chunks (columns near plants are left out)")


## Some of the checked blocks were ores: the reference and the fast path agree on them too.
func test_ores_are_in_the_generated_rock() -> void:
	var shape := _gen.dragon_shape()
	var s := shape.spawn_column()
	var col := shape.column(s.x, s.y)
	var ores := {}
	for cz in range(-2, 2):
		for cx in range(-2, 2):
			for cy in range(floori(col.y / 16.0), floori(col.x / 16.0) + 1):
				var origin := Vector3i(floori(s.x / 16.0) + cx, cy, floori(s.y / 16.0) + cz) * 16
				var buf := _generate(origin)
				for z in 16:
					for y in 16:
						for x in 16:
							var id := buf.get_voxel(x, y, z, CH)
							if [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.CRYSTAL, BlockIds.DIAMOND].has(id):
								ores[id] = true
	assert_true(ores.has(BlockIds.COAL), "coal in the home island: %s" % [ores.keys()])
	assert_true(ores.has(BlockIds.IRON), "iron too")


## Chunks that overlap by half agree everywhere, plants, clouds and secrets included.
func test_neighbouring_chunks_meet_without_seams() -> void:
	var shape := _gen.dragon_shape()
	var spots: Array[Vector2i] = [_mushroom(), shape.spawn_column()]
	for spot in spots:
		var h := shape.height_at(spot.x, spot.y)
		var base := Vector3i(spot.x - 8, floori(h / 16.0) * 16, spot.y - 8)
		var a := _generate(base)
		var b := _generate(base + Vector3i(8, 0, 0))
		var c := _generate(base + Vector3i(0, 8, 0))
		var d := _generate(base + Vector3i(0, 0, 8))
		for y in 16:
			for z in 16:
				for x in range(8, 16):
					assert_eq(a.get_voxel(x, y, z, CH), b.get_voxel(x - 8, y, z, CH))
					assert_eq(a.get_voxel(z, y, x, CH), d.get_voxel(z, y, x - 8, CH))
		for y in range(8, 16):
			for z in 16:
				for x in 16:
					assert_eq(a.get_voxel(x, y, z, CH), c.get_voxel(x, y - 8, z, CH))


func _mushroom() -> Vector2i:
	var shape := _gen.dragon_shape()
	for z in range(-300, 300):
		for x in range(-300, 300):
			if shape.plant_at(x, z) == DragonShape.MUSHROOM:
				return Vector2i(x, z)
	return Vector2i.ZERO


func _spire() -> Vector2i:
	var shape := _gen.dragon_shape()
	for z in range(-300, 300):
		for x in range(-300, 300):
			if shape.plant_at(x, z) == DragonShape.SPIRE:
				return Vector2i(x, z)
	return Vector2i.ZERO


func _block(p: Vector3i, cache: Dictionary) -> int:
	var o := Vector3i(floori(p.x / 16.0), floori(p.y / 16.0), floori(p.z / 16.0)) * 16
	if not cache.has(o):
		cache[o] = _generate(o)
	return (cache[o] as VoxelBuffer).get_voxel(p.x - o.x, p.y - o.y, p.z - o.z, CH)


func test_mushrooms_and_spires_grow_where_the_shape_says() -> void:
	var shape := _gen.dragon_shape()
	var cache := {}
	var m := _mushroom()
	var ground := shape.height_at(m.x, m.y)
	var tall := shape.plant_height(m.x, m.y)
	assert_eq(_block(Vector3i(m.x, ground, m.y), cache), BlockIds.MUSHROOM_STEM, "a stalk on the island")
	assert_eq(_block(Vector3i(m.x, ground + tall - 1, m.y), cache), BlockIds.MUSHROOM_STEM)
	var caps := 0
	for c in DragonGenerator.cap_cells(Vector3i(m.x, ground + tall, m.y)):
		if _block(c, cache) == BlockIds.GLOW_CAP:
			caps += 1
	assert_gt(caps, 40, "a round glowing cap")
	var sp := _spire()
	var sg := shape.height_at(sp.x, sp.y)
	for y in range(sg, sg + shape.plant_height(sp.x, sp.y)):
		assert_eq(_block(Vector3i(sp.x, y, sp.y), cache), BlockIds.CRYSTAL_SPIRE, "the spire at %d" % y)


## The axe fells a giant mushroom whole (its stalk and its cap), like a Meadows tree.
func test_the_axe_fells_a_giant_mushroom() -> void:
	var shape := _gen.dragon_shape()
	var m := _mushroom()
	var ground := shape.height_at(m.x, m.y)
	var cache := {}
	var edits := ToolPowers.fell_tree(Vector3i(m.x, ground + 1, m.y), func(p: Vector3i) -> int: return _block(p, cache))
	var stalk := 0
	var caps := 0
	for e: Array in edits:
		match _block(e[0], cache):
			BlockIds.MUSHROOM_STEM:
				stalk += 1
			BlockIds.GLOW_CAP:
				caps += 1
	assert_eq(stalk, shape.plant_height(m.x, m.y), "the whole stalk")
	assert_gt(caps, 40, "and its cap")


func test_the_void_below_is_air_and_there_is_no_bedrock() -> void:
	for origin: Vector3i in [Vector3i(0, -64, 0), Vector3i(0, -32, 0), Vector3i(48, -16, -16), Vector3i(0, 0, 0)]:
		var buf := _generate(origin)
		for y in 16:
			for x in 16:
				assert_eq(buf.get_voxel(x, y, x, CH), BlockIds.AIR, "the void at %s" % (origin + Vector3i(x, y, x)))
	var sky := _generate(Vector3i(0, 256, 0))
	for x in 16:
		assert_eq(sky.get_voxel(x, 8, x, CH), BlockIds.AIR)


## Every block a secret puts somewhere is in the generated chunks, whichever chunk it falls in.
func test_secret_structures_are_generated_without_seams() -> void:
	var rules: DragonSecretRules = _gen._secrets
	var done := {}
	var crossed := 0
	for az in range(-4, 4):
		for ax in range(-4, 4):
			for s: Dictionary in rules.secrets_in_area(Vector2i(ax, az)):
				if done.has(s.kind):
					continue
				done[s.kind] = true
				crossed += _check_secret(rules, s)
	assert_eq(done.keys().filter(func(k: StringName) -> bool: return SecretRules.PLACED.has(k)).size(),
		SecretRules.PLACED.size(), "one of each M2 kind checked: %s" % [done.keys()])
	assert_gt(crossed, 2, "several of them cross chunk borders")


func _check_secret(rules: SecretRules, s: Dictionary) -> int:
	var lo: Vector3i = s.lo
	var hi: Vector3i = s.hi
	var c0 := Vector3i(floori(lo.x / 16.0), floori(lo.y / 16.0), floori(lo.z / 16.0))
	var c1 := Vector3i(floori((hi.x - 1) / 16.0), floori((hi.y - 1) / 16.0), floori((hi.z - 1) / 16.0))
	var checked := 0
	for cz in range(c0.z, c1.z + 1):
		for cy in range(c0.y, c1.y + 1):
			for cx in range(c0.x, c1.x + 1):
				var origin := Vector3i(cx, cy, cz) * 16
				var buf := _generate(origin)
				var a := lo.max(origin)
				var b := hi.min(origin + Vector3i(16, 16, 16))
				for z in range(a.z, b.z):
					for y in range(a.y, b.y):
						for x in range(a.x, b.x):
							var want := rules.block_at(Vector3i(x, y, z))
							if want >= 0 and buf.get_voxel(x - origin.x, y - origin.y, z - origin.z, CH) != want:
								assert_eq(buf.get_voxel(x - origin.x, y - origin.y, z - origin.z, CH), want, "%s at %s" % [s.id, Vector3i(x, y, z)])
								return 0
							if want >= 0:
								checked += 1
	assert_gt(checked, 0, s.id)
	return 1 if c0 != c1 else 0
