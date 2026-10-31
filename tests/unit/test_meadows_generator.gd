extends GutTest

const CH := VoxelBuffer.CHANNEL_TYPE


func _generate(gen: MeadowsGenerator, origin: Vector3i) -> VoxelBuffer:
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	gen._generate_block(buf, origin, 0)
	return buf


func test_columns_match_shape_where_no_tree_is_near() -> void:
	var gen := MeadowsGenerator.new()
	gen.world_seed = 99
	var shape := MeadowsShape.new(99)
	var h := shape.height_at(8, 8)
	var origin := Vector3i(0, (h / 16) * 16, 0)
	var buf := _generate(gen, origin)
	var checked := 0
	for x in 16:
		for z in 16:
			if _tree_near(shape, x, z):
				continue
			for y in 16:   # layers, caves, ores and crystals (the full per-block rule)
				assert_eq(buf.get_voxel(x, y, z, CH), gen.reference_block(x, origin.y + y, z))
			checked += 1
	assert_gt(checked, 0)


func test_high_sky_block_is_empty() -> void:
	var gen := MeadowsGenerator.new()
	var buf := _generate(gen, Vector3i(0, 256, 0))
	for x in 16:
		assert_eq(buf.get_voxel(x, 8, x, CH), BlockIds.AIR)


func test_deep_block_is_deepstone() -> void:
	var gen := MeadowsGenerator.new()
	var buf := _generate(gen, Vector3i(0, -32, 0))
	assert_eq(buf.get_voxel(3, 3, 3, CH), BlockIds.DEEPSTONE)


func test_world_floor_is_bedrock() -> void:
	var gen := MeadowsGenerator.new()
	gen.world_seed = 5
	var shape := MeadowsShape.new(5)
	var buf := _generate(gen, Vector3i(0, -64, 0))
	for x in 16:
		for z in 16:
			var top := shape.bedrock_top(x, z)
			for y in range(0, top + 65):
				assert_eq(buf.get_voxel(x, y, z, CH), BlockIds.BEDROCK, "bedrock at %d,%d,%d" % [x, y - 64, z])
			assert_ne(buf.get_voxel(x, top + 65, z, CH), BlockIds.BEDROCK)


func test_trees_are_generated_somewhere() -> void:
	var gen := MeadowsGenerator.new()
	gen.world_seed = 12345
	var shape := MeadowsShape.new(12345)
	for tx in 64:
		for tz in 64:
			if shape.tree_at(tx, tz):
				var base := shape.height_at(tx, tz)
				var origin := Vector3i(floori(tx / 16.0) * 16, floori(base / 16.0) * 16, floori(tz / 16.0) * 16)
				var buf := _generate(gen, origin)
				assert_eq(buf.get_voxel(tx - origin.x, base - origin.y, tz - origin.z, CH), BlockIds.LOG, "trunk above ground")
				return
	fail_test("no tree found to check")


func _tree_near(shape: MeadowsShape, x: int, z: int) -> bool:
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			if shape.tree_at(x + dx, z + dz):
				return true
	return false


# --- Caves (M1b Task 4) ---

func _count_carved(buf: VoxelBuffer) -> int:
	var n := 0
	for y in 16:
		for z in 16:
			for x in 16:
				var id := buf.get_voxel(x, y, z, CH)
				if id == BlockIds.AIR or id == BlockIds.WATER:
					n += 1
	return n


func test_caves_wind_through_the_underground() -> void:
	var gen := MeadowsGenerator.new()
	gen.world_seed = 12345
	var carved := 0
	var total := 0
	for cx in range(-3, 3):
		for cz in range(-3, 3):
			for cy in [-3, -2, -1]:
				carved += _count_carved(_generate(gen, Vector3i(cx, cy, cz) * 16))
				total += 4096
	var share := carved / float(total)
	assert_between(share, 0.02, 0.25, "share of the underground that is cave: %.3f" % share)


## The fast path (coarse 4³ cells, skip test, interpolation) must equal the slow per-block reference.
func test_chunks_match_the_reference_block_rule() -> void:
	var gen := MeadowsGenerator.new()
	gen.world_seed = 12345
	var shape := MeadowsShape.new(12345)
	for origin: Vector3i in [Vector3i(0, -48, 0), Vector3i(32, -16, -48), Vector3i(-64, -64, 16), Vector3i(16, 16, 16), Vector3i(0, 48, 0), Vector3i(-32, 32, 64)]:
		var buf := _generate(gen, origin)
		for z in 16:
			for x in 16:
				if _tree_near(shape, origin.x + x, origin.z + z):
					continue
				for y in 16:
					var w := origin + Vector3i(x, y, z)
					assert_eq(buf.get_voxel(x, y, z, CH), gen.reference_block(w.x, w.y, w.z), "block at %s" % w)
					if buf.get_voxel(x, y, z, CH) != gen.reference_block(w.x, w.y, w.z):
						return


func test_carving_is_seamless_between_neighbouring_chunks() -> void:
	var gen := MeadowsGenerator.new()
	gen.world_seed = 12345
	var a := _generate(gen, Vector3i(0, -32, 0))
	var b := _generate(gen, Vector3i(8, -32, 0))     # overlaps a's x 8..15
	var c := _generate(gen, Vector3i(0, -24, 0))     # overlaps a's y 8..15
	for y in 16:
		for z in 16:
			for x in range(8, 16):
				assert_eq(a.get_voxel(x, y, z, CH), b.get_voxel(x - 8, y, z, CH))
	for y in range(8, 16):
		for z in 16:
			for x in 16:
				assert_eq(a.get_voxel(x, y, z, CH), c.get_voxel(x, y - 8, z, CH))


# --- Ores and crystals (M1b Task 5) ---

func test_underground_has_ores_and_crystals_only_where_they_belong() -> void:
	var gen := MeadowsGenerator.new()
	gen.world_seed = 12345
	var found := {}
	for cx in range(-3, 3):
		for cz in range(-3, 3):
			for cy in [-4, -3, -2, -1, 0]:
				var origin := Vector3i(cx, cy, cz) * 16
				var buf := _generate(gen, origin)
				for y in 16:
					for z in 16:
						for x in 16:
							var id := buf.get_voxel(x, y, z, CH)
							if id in [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND, BlockIds.CRYSTAL]:
								found[id] = found.get(id, 0) + 1
							if id == BlockIds.CRYSTAL:
								var w := origin + Vector3i(x, y, z)
								assert_lt(w.y, OreRules.CRYSTAL_MAX_Y)
								var up := gen.reference_block(w.x, w.y + 1, w.z)
								var down := gen.reference_block(w.x, w.y - 1, w.z)
								assert_true(up == BlockIds.AIR or down == BlockIds.AIR, "crystal at %s touches a cave" % w)
	for id in [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.CRYSTAL]:
		assert_gt(found.get(id, 0), 0, "%s found" % BlockIds.display_name(id))


# --- Secrets and treasures (M2 Task 16) ---

## Every block a secret puts somewhere is in the generated chunks, whichever chunk it falls in: structures
## that cross chunk borders are written piece by piece, without seams (one of each kind).
func test_secret_structures_are_generated_without_seams() -> void:
	var gen := MeadowsGenerator.new()
	gen.world_seed = 12345
	var rules := SecretRules.new(12345)
	var done := {}
	var crossed := 0
	for az in range(-3, 3):
		for ax in range(-3, 3):
			for s: Dictionary in rules.secrets_in_area(Vector2i(ax, az)):
				if not done.has(s.kind):
					done[s.kind] = true
					crossed += _check_secret(gen, rules, s)
	assert_eq(done.keys().filter(func(k: StringName) -> bool: return SecretRules.PLACED.has(k)).size(),
		SecretRules.PLACED.size(), "one of each M2 kind checked (owner 42: the treasure pack's too)")
	assert_gt(crossed, 2, "several of them cross chunk borders")


## Generates every chunk the secret touches and compares its cells with SecretRules.block_at; returns
## 1 when the secret spans more than one chunk.
func _check_secret(gen: MeadowsGenerator, rules: SecretRules, s: Dictionary) -> int:
	var lo: Vector3i = s.lo
	var hi: Vector3i = s.hi
	var c0 := Vector3i(floori(lo.x / 16.0), floori(lo.y / 16.0), floori(lo.z / 16.0))
	var c1 := Vector3i(floori((hi.x - 1) / 16.0), floori((hi.y - 1) / 16.0), floori((hi.z - 1) / 16.0))
	var checked := 0
	for cz in range(c0.z, c1.z + 1):
		for cy in range(c0.y, c1.y + 1):
			for cx in range(c0.x, c1.x + 1):
				var origin := Vector3i(cx, cy, cz) * 16
				var buf := _generate(gen, origin)
				var a := lo.max(origin)
				var b := hi.min(origin + Vector3i(16, 16, 16))
				for z in range(a.z, b.z):
					for y in range(a.y, b.y):
						for x in range(a.x, b.x):
							var want := rules.block_at(Vector3i(x, y, z))
							if want >= 0:
								assert_eq(buf.get_voxel(x - origin.x, y - origin.y, z - origin.z, CH), want,
									"%s at %s" % [s.id, Vector3i(x, y, z)])
								checked += 1
	assert_gt(checked, 0, s.id)
	return 1 if c0 != c1 else 0


func test_the_reference_block_includes_the_secrets() -> void:
	var gen := MeadowsGenerator.new()
	gen.world_seed = 12345
	var rules := SecretRules.new(12345)
	for az in range(-3, 3):
		for ax in range(-3, 3):
			for s: Dictionary in rules.secrets_in_area(Vector2i(ax, az)):
				if s.kind == SecretRules.ROOM:
					var cell: Vector3i = s.fake_wall[0]
					assert_eq(gen.reference_block(cell.x, cell.y, cell.z), BlockIds.FAKE_WALL)
					return
	fail_test("no hidden room found")
