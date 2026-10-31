extends GutTest
## M3 Task 2: the Sandstorm Desert's voxel generator (DesertGenerator, a MeadowsGenerator): DesertShape's
## columns, plants and DesertSecretRules' secrets written fast, equal to the slow per-block reference, and
## without seams between chunks (every rule is a function of world coordinates).

const CH := VoxelBuffer.CHANNEL_TYPE
const SEED := 12345

var _gen: DesertGenerator


func before_all() -> void:
	_gen = DesertGenerator.new()
	_gen.world_seed = SEED


func _generate(origin: Vector3i, gen: DesertGenerator = _gen) -> VoxelBuffer:
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	gen._generate_block(buf, origin, 0)
	return buf


func _plant_near(x: int, z: int) -> bool:
	var shape := _gen.desert_shape()
	for dz in range(-DesertGenerator.PLANT_REACH, DesertGenerator.PLANT_REACH + 1):
		for dx in range(-DesertGenerator.PLANT_REACH, DesertGenerator.PLANT_REACH + 1):
			if shape.plant_at(x + dx, z + dz) != DesertShape.NO_PLANT:
				return true
	return false


func test_it_is_a_meadows_generator_with_desert_rules() -> void:
	assert_true(_gen is MeadowsGenerator)
	assert_true(_gen.desert_shape() is DesertShape)
	assert_eq(_gen.desert_shape().seed, SEED)
	assert_true(_gen._secrets is DesertSecretRules)
	var fresh := DesertGenerator.new()
	assert_true(fresh.desert_shape() is DesertShape, "a new one has desert rules before a seed is set")


## Surface, mesa, oasis and underground chunks: the fast path (runs, carving, ores) equals the reference.
func test_chunks_match_the_reference_block_rule() -> void:
	var shape := _gen.desert_shape()
	var origins: Array[Vector3i] = [Vector3i(0, -48, 0), Vector3i(32, -16, -48), Vector3i(-64, -64, 16), Vector3i(16, 16, 16),
		Vector3i(-32, 32, 64)]
	for kind in [DesertShape.MESA, DesertShape.OASIS]:   # a chunk of each kind at its surface
		var spot := _find(kind)
		var h := shape.height_at(spot.x, spot.y)
		origins.append(Vector3i(floori(spot.x / 16.0) * 16, floori((h - 4) / 16.0) * 16, floori(spot.y / 16.0) * 16))
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
	assert_gt(checked, 15000, "most of 7 chunks (columns near plants are left out)")


func _find(kind: int) -> Vector2i:
	var shape := _gen.desert_shape()
	for z in range(-320, 320, 4):
		for x in range(-320, 320, 4):
			if shape.terrain_at(x, z) == kind and (kind != DesertShape.OASIS or shape.height_at(x, z) < MeadowsShape.SEA_LEVEL):
				return Vector2i(x, z)
	return Vector2i.ZERO


## Chunks that overlap by half agree everywhere, plants and caves included.
func test_neighbouring_chunks_meet_without_seams() -> void:
	var spot := _find(DesertShape.OASIS)       # palms: fronds reach into the next chunk
	var h := _gen.desert_shape().height_at(spot.x, spot.y)
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


func test_plants_grow_where_the_shape_says() -> void:
	var shape := _gen.desert_shape()
	var found := {}
	for z in range(-160, 160):
		for x in range(-160, 160):
			var p := shape.plant_at(x, z)
			if p == DesertShape.NO_PLANT or found.has(p):
				continue
			var ground := shape.height_at(x, z)
			var origin := Vector3i(floori(x / 16.0) * 16, floori(ground / 16.0) * 16, floori(z / 16.0) * 16)
			var buf := _generate(origin)
			var l := Vector3i(x, ground, z) - origin
			var want := {DesertShape.CACTUS: BlockIds.CACTUS, DesertShape.PALM: BlockIds.PALM_LOG, DesertShape.BUSH: BlockIds.DEAD_BUSH}
			assert_eq(buf.get_voxel(l.x, l.y, l.z, CH), want[p], "plant %d at %d,%d,%d" % [p, x, ground, z])
			found[p] = true
	assert_eq(found.size(), 3, "a cactus, a palm and a bush")


func test_deep_bedrock_and_sky() -> void:
	assert_eq(_generate(Vector3i(0, -32, 0)).get_voxel(3, 3, 3, CH), BlockIds.DEEPSTONE)
	var floor_buf := _generate(Vector3i(0, -64, 0))
	assert_eq(floor_buf.get_voxel(2, 0, 2, CH), BlockIds.BEDROCK)
	var sky := _generate(Vector3i(0, 256, 0))
	for x in 16:
		assert_eq(sky.get_voxel(x, 8, x, CH), BlockIds.AIR)


## Every block a secret puts somewhere is in the generated chunks, whichever chunk it falls in (one of each
## kind: a pyramid spans several chunks).
func test_secret_structures_are_generated_without_seams() -> void:
	var rules: DesertSecretRules = _gen._secrets
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
		SecretRules.PLACED.size(), "one of each M2 kind checked (owner 42: the treasure pack's too)")
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
