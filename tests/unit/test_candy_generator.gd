extends GutTest
## M3 Task 4: the Candy Kingdom's voxel generator (CandyGenerator, a MeadowsGenerator): CandyShape's
## columns, plants and CandySecretRules' secrets written fast, equal to the slow per-block reference, and
## without seams between chunks (every rule is a function of world coordinates).

const CH := VoxelBuffer.CHANNEL_TYPE
const SEED := 12345

var _gen: CandyGenerator


func before_all() -> void:
	_gen = CandyGenerator.new()
	_gen.world_seed = SEED


func _generate(origin: Vector3i, gen: CandyGenerator = _gen) -> VoxelBuffer:
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	gen._generate_block(buf, origin, 0)
	return buf


func _plant_near(x: int, z: int) -> bool:
	var shape := _gen.candy_shape()
	for dz in range(-CandyShape.PLANT_REACH, CandyShape.PLANT_REACH + 1):
		for dx in range(-CandyShape.PLANT_REACH, CandyShape.PLANT_REACH + 1):
			if shape.plant_at(x + dx, z + dz) != CandyShape.NO_PLANT:
				return true
	return false


func _find(kind: int, where: Callable = func(_c: Vector3i) -> bool: return true) -> Vector2i:
	var shape := _gen.candy_shape()
	for z in range(-384, 384, 4):
		for x in range(-384, 384, 4):
			var col := shape.column(x, z)
			if col.y == kind and where.call(col):
				return Vector2i(x, z)
	return Vector2i.ZERO


func _chunk_at(spot: Vector2i, y: int) -> Vector3i:
	return Vector3i(floori(spot.x / 16.0) * 16, floori(y / 16.0) * 16, floori(spot.y / 16.0) * 16)


func test_it_is_a_meadows_generator_with_candy_rules() -> void:
	assert_true(_gen is MeadowsGenerator)
	assert_true(_gen.candy_shape() is CandyShape)
	assert_eq(_gen.candy_shape().seed, SEED)
	assert_true(_gen._secrets is CandySecretRules)
	var fresh := CandyGenerator.new()
	assert_true(fresh.candy_shape() is CandyShape, "a new one has candy rules before a seed is set")


## Plains, river, hill and cake chunks at their surface, and underground ones: the fast path (runs, carving,
## ores) equals the reference.
func test_chunks_match_the_reference_block_rule() -> void:
	var shape := _gen.candy_shape()
	var origins: Array[Vector3i] = [Vector3i(0, -48, 0), Vector3i(32, -16, -48), Vector3i(-64, -64, 16), Vector3i(16, 16, 16),
		Vector3i(-32, 32, 64)]
	for kind in [CandyShape.RIVER, CandyShape.BANK, CandyShape.GREEN_HILL, CandyShape.RED_HILL, CandyShape.CAKE_MOUNTAIN]:
		var spot := _find(kind)
		var col := shape.column(spot.x, spot.y)
		origins.append(_chunk_at(spot, col.x - 4))
		if kind == CandyShape.CAKE_MOUNTAIN:
			origins.append(_chunk_at(spot, col.z + 2))   # the layers in a cake's side
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
	assert_gt(checked, 25000, "most of 11 chunks (columns near plants are left out)")


## Chunks that overlap by half agree everywhere, plants and caves included.
func test_neighbouring_chunks_meet_without_seams() -> void:
	var shape := _gen.candy_shape()
	for spot in [_forest_tree(), _find(CandyShape.CAKE_MOUNTAIN)]:
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


func _forest_tree() -> Vector2i:
	var shape := _gen.candy_shape()
	for z in range(-200, 200):
		for x in range(-200, 200):
			if shape.plant_at(x, z) == CandyShape.LOLLIPOP_TREE:
				return Vector2i(x, z)
	return Vector2i.ZERO


func test_plants_grow_where_the_shape_says() -> void:
	var shape := _gen.candy_shape()
	var found := {}
	var want := {CandyShape.CANE: BlockIds.CANDY_CANE, CandyShape.LOLLIPOP_TREE: BlockIds.CANDY_CANE,
		CandyShape.COTTON: BlockIds.COTTON_CANDY}
	for z in range(-200, 200):
		for x in range(-200, 200):
			var p := shape.plant_at(x, z)
			if p == CandyShape.NO_PLANT or found.has(p):
				continue
			var ground := shape.height_at(x, z)
			var origin := _chunk_at(Vector2i(x, z), ground)
			var buf := _generate(origin)
			var l := Vector3i(x, ground, z) - origin
			assert_eq(buf.get_voxel(l.x, l.y, l.z, CH), want[p], "plant %d at %d,%d,%d" % [p, x, ground, z])
			found[p] = true
			if p == CandyShape.LOLLIPOP_TREE:
				var top := Vector3i(x, ground + shape.plant_height(x, z) + 1, z)
				var lolly := 0
				for c in CandyGenerator.lollipop_cells(top, shape.plant_dir(x, z)):
					var cell := c as Vector3i
					var o := Vector3i(floori(cell.x / 16.0), floori(cell.y / 16.0), floori(cell.z / 16.0)) * 16
					if _generate(o).get_voxel(cell.x - o.x, cell.y - o.y, cell.z - o.z, CH) == BlockIds.LOLLIPOP:
						lolly += 1
				assert_gt(lolly, 12, "a round lollipop on its stick")
	assert_eq(found.size(), 3, "a candy cane, a lollipop tree and cotton candy")


## The axe fells a generated lollipop tree whole (its stick and its top), like a Meadows tree.
func test_the_axe_fells_a_lollipop_tree() -> void:
	var shape := _gen.candy_shape()
	var t := _forest_tree()
	var ground := shape.height_at(t.x, t.y)
	var cache := {}
	var block_at := func(p: Vector3i) -> int:
		var o := Vector3i(floori(p.x / 16.0), floori(p.y / 16.0), floori(p.z / 16.0)) * 16
		if not cache.has(o):
			cache[o] = _generate(o)
		return (cache[o] as VoxelBuffer).get_voxel(p.x - o.x, p.y - o.y, p.z - o.z, CH)
	var edits := ToolPowers.fell_tree(Vector3i(t.x, ground + 1, t.y), block_at)
	var sticks := 0
	var tops := 0
	for e: Array in edits:
		match block_at.call(e[0]):
			BlockIds.CANDY_CANE:
				sticks += 1
			BlockIds.LOLLIPOP:
				tops += 1
	assert_eq(sticks, shape.plant_height(t.x, t.y) + 2, "the whole stick")
	assert_gt(tops, 12, "and its lollipop")


func test_deep_bedrock_and_sky() -> void:
	assert_eq(_generate(Vector3i(0, -32, 0)).get_voxel(3, 3, 3, CH), BlockIds.DEEPSTONE)
	var floor_buf := _generate(Vector3i(0, -64, 0))
	assert_eq(floor_buf.get_voxel(2, 0, 2, CH), BlockIds.BEDROCK)
	var sky := _generate(Vector3i(0, 256, 0))
	for x in 16:
		assert_eq(sky.get_voxel(x, 8, x, CH), BlockIds.AIR)


## Every block a secret puts somewhere is in the generated chunks, whichever chunk it falls in.
func test_secret_structures_are_generated_without_seams() -> void:
	var rules: CandySecretRules = _gen._secrets
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
