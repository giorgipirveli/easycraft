extends GutTest
## M3 Task 3: Frostpeak's voxel generator (FrostGenerator, a MeadowsGenerator): FrostShape's columns, pines
## and igloos and FrostSecretRules' secrets written fast, equal to the slow per-block reference, and without
## seams between chunks (every rule is a function of world coordinates).

const CH := VoxelBuffer.CHANNEL_TYPE
const SEED := 12345

var _gen: FrostGenerator


func before_all() -> void:
	_gen = FrostGenerator.new()
	_gen.world_seed = SEED


func _generate(origin: Vector3i, gen: FrostGenerator = _gen) -> VoxelBuffer:
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	gen._generate_block(buf, origin, 0)
	return buf


func _pine_near(x: int, z: int) -> bool:
	var shape := _gen.frost_shape()
	for dz in range(-FrostGenerator.PLANT_REACH, FrostGenerator.PLANT_REACH + 1):
		for dx in range(-FrostGenerator.PLANT_REACH, FrostGenerator.PLANT_REACH + 1):
			if shape.pine_at(x + dx, z + dz):
				return true
	return false


func _find(want: Callable) -> Vector2i:
	for z in range(-384, 384, 4):
		for x in range(-384, 384, 4):
			if want.call(x, z):
				return Vector2i(x, z)
	return Vector2i.ZERO


func test_it_is_a_meadows_generator_with_frost_rules() -> void:
	assert_true(_gen is MeadowsGenerator)
	assert_true(_gen.frost_shape() is FrostShape)
	assert_eq(_gen.frost_shape().seed, SEED)
	assert_true(_gen._secrets is FrostSecretRules)
	var fresh := FrostGenerator.new()
	assert_true(fresh.frost_shape() is FrostShape, "a new one has frost rules before a seed is set")


## Surface, peak, lake and underground chunks: the fast path (runs, carving, ores, igloos) equals the reference.
func test_chunks_match_the_reference_block_rule() -> void:
	var shape := _gen.frost_shape()
	var origins: Array[Vector3i] = [Vector3i(0, -48, 0), Vector3i(32, -16, -48), Vector3i(-64, -64, 16), Vector3i(16, 16, 16),
		Vector3i(-32, 32, 64)]
	var spots: Array[Vector2i] = [
		_find(func(x: int, z: int) -> bool: return shape.terrain_at(x, z) == FrostShape.PEAK and shape.height_at(x, z) > 60),
		_find(func(x: int, z: int) -> bool: return shape.terrain_at(x, z) == FrostShape.LAKE and shape.height_at(x, z) < 21),
		_find(func(x: int, z: int) -> bool: return shape.column(x, z).z != FrostShape.NO_ORE),
	]
	for spot in spots:
		var h := shape.height_at(spot.x, spot.y)
		origins.append(Vector3i(floori(spot.x / 16.0) * 16, floori((h - 4) / 16.0) * 16, floori(spot.y / 16.0) * 16))
	var ig := _igloo()
	var c: Vector3i = ig.center
	origins.append(Vector3i(floori(c.x / 16.0) * 16, floori(c.y / 16.0) * 16, floori(c.z / 16.0) * 16))
	var checked := 0
	for origin in origins:
		var buf := _generate(origin)
		for z in 16:
			for x in 16:
				if _pine_near(origin.x + x, origin.z + z):
					continue
				for y in 16:
					var w := origin + Vector3i(x, y, z)
					var want := _gen.reference_block(w.x, w.y, w.z)
					if buf.get_voxel(x, y, z, CH) != want:
						assert_eq(buf.get_voxel(x, y, z, CH), want, "block at %s" % w)
						return
					checked += 1
	assert_gt(checked, 18000, "most of 9 chunks (columns near pines are left out)")


func _igloo() -> Dictionary:
	var shape := _gen.frost_shape()
	for cz in range(-4, 4):
		for cx in range(-4, 4):
			var ig := shape.igloo_in_cell(Vector2i(cx, cz))
			if not ig.is_empty():
				return ig
	return {}


## Chunks that overlap by half agree everywhere, pines, igloos and caves included.
func test_neighbouring_chunks_meet_without_seams() -> void:
	var ig := _igloo()
	assert_false(ig.is_empty(), "an igloo to cut through")
	var c: Vector3i = ig.center
	var base := Vector3i(c.x - 8, floori(c.y / 16.0) * 16, c.z - 8)
	var a := _generate(base)
	var b := _generate(base + Vector3i(8, 0, 0))
	var d := _generate(base + Vector3i(0, 0, 8))
	var up := _generate(base + Vector3i(0, 8, 0))
	for y in 16:
		for z in 16:
			for x in range(8, 16):
				assert_eq(a.get_voxel(x, y, z, CH), b.get_voxel(x - 8, y, z, CH))
				assert_eq(a.get_voxel(z, y, x, CH), d.get_voxel(z, y, x - 8, CH))
	for y in range(8, 16):
		for z in 16:
			for x in 16:
				assert_eq(a.get_voxel(x, y, z, CH), up.get_voxel(x, y - 8, z, CH))


## Every block an igloo puts somewhere is in the generated chunks, whichever chunk it falls in.
func test_igloos_are_generated_whole() -> void:
	var shape := _gen.frost_shape()
	var done := 0
	for cz in range(-3, 3):
		for cx in range(-3, 3):
			var ig := shape.igloo_in_cell(Vector2i(cx, cz))
			if ig.is_empty():
				continue
			done += 1
			var lo: Vector3i = ig.lo
			var hi: Vector3i = ig.hi
			for z in range(lo.z, hi.z):
				for y in range(lo.y, hi.y):
					for x in range(lo.x, hi.x):
						var p := Vector3i(x, y, z)
						var want := FrostShape.igloo_block(p, ig)
						if want < 0 or _gen._secrets.block_at(p) >= 0:
							continue
						var origin := Vector3i(floori(x / 16.0), floori(y / 16.0), floori(z / 16.0)) * 16
						var got := _generate(origin).get_voxel(x - origin.x, y - origin.y, z - origin.z, CH)
						if got != want:
							assert_eq(got, want, "igloo block at %s" % p)
							return
	assert_gt(done, 1, "igloos checked")


func test_pines_grow_where_the_shape_says() -> void:
	var shape := _gen.frost_shape()
	var found := 0
	for z in range(-200, 200, 3):
		for x in range(-200, 200, 3):
			if found >= 6 or not shape.pine_at(x, z):
				continue
			var ground := shape.height_at(x, z)
			var tall := shape.pine_height(x, z)
			var origin := Vector3i(floori(x / 16.0) * 16, floori(ground / 16.0) * 16, floori(z / 16.0) * 16)
			var buf := _generate(origin)
			var l := Vector3i(x, ground, z) - origin
			assert_eq(buf.get_voxel(l.x, l.y, l.z, CH), BlockIds.PINE_LOG, "a trunk at %d,%d,%d" % [x, ground, z])
			var top := Vector3i(x, ground + tall + 1, z)
			var o2 := Vector3i(floori(top.x / 16.0), floori(top.y / 16.0), floori(top.z / 16.0)) * 16
			assert_eq(_generate(o2).get_voxel(top.x - o2.x, top.y - o2.y, top.z - o2.z, CH), BlockIds.PINE_NEEDLES, "its tip")
			found += 1
	assert_eq(found, 6, "six pines checked")


## The generator's quick first look for pines (inlined) finds exactly the pines FrostShape grows: in a
## forest chunk, a trunk stands on every pine_at column and nowhere else.
func test_every_pine_and_only_pines_in_a_forest_chunk() -> void:
	var shape := _gen.frost_shape()
	var spot := _find(func(x: int, z: int) -> bool: return shape.pine_at(x, z) and shape.forest_at(x, z))
	var h := shape.height_at(spot.x, spot.y)
	var trunks := 0
	for dy in [0, 16]:
		var origin := Vector3i(floori(spot.x / 16.0) * 16, floori(h / 16.0) * 16 - dy, floori(spot.y / 16.0) * 16)
		var buf := _generate(origin)
		for z in 16:
			for x in 16:
				var pine := shape.pine_at(origin.x + x, origin.z + z)
				var ground := shape.height_at(origin.x + x, origin.z + z)
				for y in 16:
					var logged := buf.get_voxel(x, y, z, CH) == BlockIds.PINE_LOG
					if logged:
						assert_true(pine, "a trunk only where a pine grows (%s)" % (origin + Vector3i(x, y, z)))
						trunks += 1
					elif pine and origin.y + y == ground:
						assert_true(logged, "a pine's first log at %s" % (origin + Vector3i(x, y, z)))
	assert_gt(trunks, 3, "a forest")


func test_deep_bedrock_and_sky() -> void:
	assert_eq(_generate(Vector3i(0, -32, 0)).get_voxel(3, 3, 3, CH), BlockIds.DEEPSTONE)
	var floor_buf := _generate(Vector3i(0, -64, 0))
	assert_eq(floor_buf.get_voxel(2, 0, 2, CH), BlockIds.BEDROCK)
	var sky := _generate(Vector3i(0, 256, 0))
	for x in 16:
		assert_eq(sky.get_voxel(x, 8, x, CH), BlockIds.AIR)


## Every block a secret puts somewhere is in the generated chunks, whichever chunk it falls in (one of each
## kind: a room under an igloo spans several chunks).
func test_secret_structures_are_generated_without_seams() -> void:
	var rules: FrostSecretRules = _gen._secrets
	var done := {}
	var crossed := 0
	for az in range(-5, 5):
		for ax in range(-5, 5):
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
