extends GutTest
## M3 Task 3 (spec §14.1): Frostpeak's terrain rules (FrostShape, a MeadowsShape every world system can
## use): snowy valleys, snow-capped stone peaks, frozen lakes (ice over water, level with their banks), pine
## forests, igloos (small snow-brick domes on flat snowy ground), frozen ore in the peaks' stone. No rivers
## and no sea. Every rule is a function of (x, z) and the seed, so chunks meet without seams.

const SEED := 12345
const SPAN := 768                 # the region the feature tests scan (every 8th column)
const STEP := 8
const NONE := Vector2i(999999, 999999)


func _shape(s: int = SEED) -> FrostShape:
	return FrostShape.new(s)


func _scan(f: Callable, span: int = SPAN, step: int = STEP) -> void:
	for z in range(-span / 2, span / 2, step):
		for x in range(-span / 2, span / 2, step):
			f.call(x, z)


func _find(shape: FrostShape, want: Callable) -> Vector2i:
	for z in range(-SPAN / 2, SPAN / 2, 4):
		for x in range(-SPAN / 2, SPAN / 2, 4):
			if want.call(x, z):
				return Vector2i(x, z)
	return NONE


func test_it_is_a_meadows_shape_for_every_world_system() -> void:
	var shape: MeadowsShape = _shape()
	assert_true(shape is FrostShape)
	assert_eq(shape.seed, SEED)
	assert_false(shape.is_river(10, 20), "no rivers in Frostpeak")


func test_the_same_seed_makes_the_same_frostpeak() -> void:
	var a := _shape()
	var b := _shape()
	var c := _shape(SEED + 1)
	var differs := 0
	for i in 200:
		var x := i * 37 - 3000
		var z := i * 53 - 4000
		assert_eq(a.height_at(x, z), b.height_at(x, z))
		assert_eq(a.terrain_at(x, z), b.terrain_at(x, z))
		assert_eq(a.pine_at(x, z), b.pine_at(x, z))
		if a.height_at(x, z) != c.height_at(x, z):
			differs += 1
	assert_gt(differs, 100, "another seed, another Frostpeak")


func test_valleys_peaks_and_lakes_are_all_there() -> void:
	var shape := _shape()
	var seen := {FrostShape.VALLEY: 0, FrostShape.LAKE: 0, FrostShape.PEAK: 0}
	var top := [0]
	var frozen := [0]
	_scan(func(x: int, z: int) -> void:
		var k := shape.terrain_at(x, z)
		seen[k] += 1
		var h := shape.height_at(x, z)
		top[0] = maxi(top[0], h)
		if k == FrostShape.LAKE and h < MeadowsShape.SEA_LEVEL:
			frozen[0] += 1)
	assert_gt(seen[FrostShape.PEAK], 60, "snowy peaks")
	assert_gt(seen[FrostShape.LAKE], 10, "lakes")
	assert_gt(frozen[0], 5, "frozen lakes hold water under their ice")
	assert_gt(seen[FrostShape.VALLEY], seen[FrostShape.PEAK], "mostly valleys to walk in")
	assert_gt(top[0], FrostShape.SNOW_LINE + 20, "peaks rise far above the snow line (%d)" % top[0])
	assert_lt(top[0], FrostShape.TOP, "every ground is under TOP: the generator skips the sky above it")


## Water only under lake ice: valleys and peaks stay above the sea level, so no open water appears by
## accident (MeadowsShape fills everything below SEA_LEVEL with water).
func test_only_lakes_go_below_the_water_line() -> void:
	var shape := _shape()
	_scan(func(x: int, z: int) -> void:
		if shape.terrain_at(x, z) != FrostShape.LAKE:
			assert_gt(shape.height_at(x, z), MeadowsShape.SEA_LEVEL + 1, "dry at %d,%d" % [x, z]))


## A frozen lake is ice on top (a flat, slippery floor at the banks' level) with water under it; a child
## walks from the bank straight onto the ice.
func test_lakes_are_ice_over_water_level_with_their_banks() -> void:
	var shape := _shape()
	var deep := _find(shape, func(x: int, z: int) -> bool:
		return shape.terrain_at(x, z) == FrostShape.LAKE and shape.height_at(x, z) < MeadowsShape.SEA_LEVEL - 2)
	assert_ne(deep, NONE, "a deep lake")
	var col := shape.column(deep.x, deep.y)
	assert_eq(shape.block_in_column(MeadowsShape.SEA_LEVEL - 1, col), BlockIds.ICE, "ice on top")
	assert_eq(shape.block_in_column(MeadowsShape.SEA_LEVEL - 2, col), BlockIds.WATER, "water under it")
	assert_eq(shape.block_in_column(MeadowsShape.SEA_LEVEL, col), BlockIds.AIR, "the ice is the surface")
	assert_true(BlockIds.is_solid(shape.block_in_column(col.x - 1, col)), "a lake bed")
	# every lake column's surface is the ice at the same height
	var n := [0]
	_scan(func(x: int, z: int) -> void:
		var c := shape.column(x, z)
		if c.y == FrostShape.LAKE and c.x < MeadowsShape.SEA_LEVEL:
			assert_eq(shape.surface_at(x, z), MeadowsShape.SEA_LEVEL, "flat ice at %d,%d" % [x, z])
			n[0] += 1, SPAN, 4)
	assert_gt(n[0], 20)
	# the bank next to the ice is at most one step up
	var worst := 0
	for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var prev := shape.surface_at(deep.x, deep.y)
		for i in range(1, 40):
			var s := shape.surface_at(deep.x + dir.x * i, deep.y + dir.y * i)
			if shape.terrain_at(deep.x + dir.x * (i - 1), deep.y + dir.y * (i - 1)) == FrostShape.LAKE:
				worst = maxi(worst, absi(s - prev))
			prev = s
	assert_lte(worst, 1, "no cliff round a lake")


func test_column_layers_valley_and_peak() -> void:
	var shape := _shape()
	var v := _find(shape, func(x: int, z: int) -> bool: return shape.terrain_at(x, z) == FrostShape.VALLEY)
	var col := shape.column(v.x, v.y)
	var h := col.x
	assert_eq(shape.block_in_column(h - 1, col), BlockIds.SNOWY_GRASS, "snowy grass in the valleys")
	assert_eq(shape.block_in_column(h - 2, col), BlockIds.DIRT)
	assert_eq(shape.block_in_column(h, col), BlockIds.AIR)
	assert_eq(shape.block_in_column(h - 6, col), BlockIds.STONE)
	assert_eq(shape.block_in_column(-5, col), BlockIds.DEEPSTONE)
	assert_eq(shape.block_in_column(MeadowsShape.WORLD_BOTTOM, col), BlockIds.BEDROCK)
	var p := _find(shape, func(x: int, z: int) -> bool:
		return shape.terrain_at(x, z) == FrostShape.PEAK and shape.height_at(x, z) > FrostShape.SNOW_LINE + 6)
	var pc := shape.column(p.x, p.y)
	assert_eq(shape.block_in_column(pc.x - 1, pc), BlockIds.SNOW, "snow caps the peaks")
	var below := shape.block_in_column(pc.x - 2, pc)
	assert_true(below == BlockIds.STONE or below == BlockIds.FROZEN_ORE, "rock under the snow (cliffs show stone)")


## The generator fills stone up to stone_top and writes the layers above it itself (checked against
## block_in_column in test_frost_generator); stone_top must be exactly where the plain stone ends.
func test_stone_top_is_where_the_stone_ends() -> void:
	var shape := _shape()
	var n := [0]
	_scan(func(x: int, z: int) -> void:
		var col := shape.column(x, z)
		var top := shape.stone_top(col)
		var below := shape.block_in_column(top - 1, col)
		assert_true(below == BlockIds.STONE or below == BlockIds.FROZEN_ORE, "%d,%d" % [x, z])
		for y in range(top, col.x):
			assert_ne(shape.block_in_column(y, col), BlockIds.STONE, "no plain stone above it at %d,%d,%d" % [x, y, z])
		n[0] += 1)
	assert_gt(n[0], 1000)


func test_frozen_ore_glitters_in_the_peaks() -> void:
	var shape := _shape()
	var ores := [0]
	_scan(func(x: int, z: int) -> void:
		var col := shape.column(x, z)
		for y in range(col.x - 6, col.x):
			if shape.block_in_column(y, col) == BlockIds.FROZEN_ORE:
				assert_eq(col.y, FrostShape.PEAK, "frozen ore only in the peaks")
				assert_lt(y, col.x - 1, "under the snow")
				ores[0] += 1, SPAN, 2)
	assert_gt(ores[0], 20)


func test_pines_grow_in_forests_never_on_lakes_or_the_high_peaks() -> void:
	var shape := _shape()
	var forest := [0]
	var open := [0]
	var total := [0]
	_scan(func(x: int, z: int) -> void:
		if not shape.pine_at(x, z):
			return
		total[0] += 1
		assert_true(shape.tree_at(x, z), "a pine is a tree (secrets and spawns keep off it)")
		var col := shape.column(x, z)
		assert_ne(col.y, FrostShape.LAKE, "no pine on a lake or its bank at %d,%d" % [x, z])
		assert_lt(col.x, FrostShape.TREE_LINE, "no pine above the tree line")
		assert_between(shape.pine_height(x, z), 5, 8)
		if shape.forest_at(x, z):
			forest[0] += 1
		else:
			open[0] += 1, SPAN, 2)
	assert_gt(total[0], 200, "pine forests")
	assert_gt(forest[0], open[0] * 3, "pines grow together in forests")


func test_igloos_stand_on_flat_snowy_ground() -> void:
	var shape := _shape()
	var igloos := _igloos(shape)
	assert_gt(igloos.size(), 3, "igloos around")
	for ig: Dictionary in igloos:
		var c: Vector3i = ig.center
		assert_eq(shape.terrain_at(c.x, c.z), FrostShape.VALLEY, "on the snowy valley floor")
		for off: Vector2i in [Vector2i(-4, 0), Vector2i(4, 0), Vector2i(0, -4), Vector2i(0, 4), Vector2i.ZERO]:
			assert_lte(absi(shape.height_at(c.x + off.x, c.z + off.y) - c.y), FrostShape.IGLOO_FLAT, "flat round it")
			assert_true(shape.tree_at(c.x + off.x, c.z + off.y), "secrets, spawns and pines keep off it")
			assert_false(shape.pine_at(c.x + off.x, c.z + off.y), "no pine grows in an igloo")
		assert_eq(shape.igloo_block(c + Vector3i(0, 1, 0), ig), BlockIds.AIR, "room inside")
		assert_eq(shape.igloo_block(c + Vector3i.DOWN, ig), BlockIds.PACKED_SNOW, "a packed snow floor")
		assert_eq(shape.igloo_block(c + Vector3i(0, 3, 0), ig), BlockIds.SNOW_BRICK, "a dome of snow bricks")
		assert_eq(shape.igloo_block(c + Vector3i(0, 4, 0), ig), -1, "nothing on top of it")
		var door := c + (ig.dir as Vector3i) * FrostShape.IGLOO_R
		assert_eq(shape.igloo_block(door, ig), BlockIds.AIR, "a doorway")
		assert_eq(shape.igloo_block(door + Vector3i.UP, ig), BlockIds.AIR)
		var lit := false
		for b: Array in ig.boxes:
			lit = lit or b[2] == BlockIds.ICE_LANTERN
		assert_true(lit, "an ice lantern lights it")
		assert_eq(shape.igloo_near(c.x, c.z), ig, "found by its spot")


func test_every_igloo_stays_in_its_cell_and_is_the_same_every_time() -> void:
	var shape := _shape()
	var again := _shape()
	for ig: Dictionary in _igloos(shape):
		var cell: Vector2i = ig.cell
		var lo: Vector3i = ig.lo
		var hi: Vector3i = ig.hi
		var a0 := cell * FrostShape.IGLOO_CELL
		assert_true(lo.x >= a0.x and lo.z >= a0.y and hi.x <= a0.x + FrostShape.IGLOO_CELL and hi.z <= a0.y + FrostShape.IGLOO_CELL,
			"igloo %s stays in its cell" % cell)
		assert_eq(again.igloo_in_cell(cell).get("boxes"), ig.boxes)


func _igloos(shape: FrostShape) -> Array:
	var out: Array = []
	for cz in range(-6, 6):
		for cx in range(-6, 6):
			var ig := shape.igloo_in_cell(Vector2i(cx, cz))
			if not ig.is_empty():
				out.append(ig)
	return out


## A new Frostpeak world starts in an open snowy valley: not on a peak, not on a lake, not in an igloo.
func test_the_spawn_is_in_an_open_flat_valley() -> void:
	for s in [SEED, 7, 99, 424242]:
		var shape := _shape(s)
		var c := shape.spawn_column()
		assert_eq(shape.terrain_at(c.x, c.y), FrostShape.VALLEY, "seed %d" % s)
		assert_false(shape.tree_at(c.x, c.y), "seed %d: not in a pine or an igloo" % s)
		var lo := 999
		var hi := -999
		for dz in [-6, 0, 6]:
			for dx in [-6, 0, 6]:
				lo = mini(lo, shape.height_at(c.x + dx, c.y + dz))
				hi = maxi(hi, shape.height_at(c.x + dx, c.y + dz))
		assert_lte(hi - lo, FrostShape.SPAWN_FLAT, "flat around the spawn (seed %d)" % s)
		assert_eq(shape.spawn_column(), c, "the same every time")
