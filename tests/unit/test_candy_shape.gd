extends GutTest
## M3 Task 4 (spec §14.1): the Candy Kingdom's terrain rules (CandyShape, a MeadowsShape every world system
## can use): rolling frosting plains, chocolate rivers (the sea level's water, chocolate in this universe),
## round gumdrop hills (green or red), tiered cake mountains with layers of sponge, jam and cream, candy-cane
## forests, lollipop trees and cotton candy. Every rule is a function of (x, z) and the seed.

const SEED := 12345
const SPAN := 768                 # the region the feature tests scan (every 8th column)
const STEP := 8
const NOWHERE := Vector2i(999999, 999999)


func _shape(s: int = SEED) -> CandyShape:
	return CandyShape.new(s)


func _scan(f: Callable, step: int = STEP) -> void:
	for z in range(-SPAN / 2, SPAN / 2, step):
		for x in range(-SPAN / 2, SPAN / 2, step):
			f.call(x, z)


func _find(shape: CandyShape, kind: int, where: Callable = func(_x: int, _z: int) -> bool: return true) -> Vector2i:
	for z in range(-SPAN / 2, SPAN / 2, 4):
		for x in range(-SPAN / 2, SPAN / 2, 4):
			if shape.terrain_at(x, z) == kind and where.call(x, z):
				return Vector2i(x, z)
	return NOWHERE


func test_it_is_a_meadows_shape_for_every_world_system() -> void:
	var shape: MeadowsShape = _shape()
	assert_true(shape is CandyShape)
	assert_eq(shape.seed, SEED)
	var r := _find(_shape(), CandyShape.RIVER)
	assert_ne(r, NOWHERE, "a chocolate river nearby")
	assert_true(shape.is_river(r.x, r.y), "is_river: secrets and spawns keep off it")


func test_the_same_seed_makes_the_same_kingdom() -> void:
	var a := _shape()
	var b := _shape()
	var c := _shape(SEED + 1)
	var differs := 0
	for i in 200:
		var x := i * 37 - 3000
		var z := i * 53 - 4000
		assert_eq(a.column(x, z), b.column(x, z))
		assert_eq(a.plant_at(x, z), b.plant_at(x, z))
		if a.height_at(x, z) != c.height_at(x, z):
			differs += 1
	assert_gt(differs, 100, "another seed, another kingdom")


func test_plains_rivers_hills_and_mountains_are_all_there() -> void:
	var shape := _shape()
	var seen := {}
	for k in [CandyShape.PLAINS, CandyShape.RIVER, CandyShape.BANK, CandyShape.GREEN_HILL, CandyShape.RED_HILL,
			CandyShape.CAKE_MOUNTAIN]:
		seen[k] = 0
	var top := [0]
	_scan(func(x: int, z: int) -> void:
		seen[shape.terrain_at(x, z)] += 1
		top[0] = maxi(top[0], shape.height_at(x, z)))
	assert_gt(seen[CandyShape.RIVER], 20, "chocolate rivers")
	assert_gt(seen[CandyShape.BANK], 10, "chocolate banks")
	assert_gt(seen[CandyShape.GREEN_HILL] + seen[CandyShape.RED_HILL], 30, "gumdrop hills")
	assert_gt(seen[CandyShape.GREEN_HILL], 0, "green ones")
	assert_gt(seen[CandyShape.RED_HILL], 0, "red ones")
	assert_gt(seen[CandyShape.CAKE_MOUNTAIN], 40, "cake mountains")
	assert_gt(seen[CandyShape.PLAINS], seen[CandyShape.CAKE_MOUNTAIN] * 3, "mostly frosting plains")
	assert_lt(top[0], CandyShape.TOP, "every ground is under TOP: the generator skips the sky above it")
	assert_gt(top[0], CandyShape.TOP - 10, "... and TOP is not far above the highest cake")


## Water (chocolate here) only in the rivers: plains, hills and mountains stay above the sea level, so no
## lake appears by accident (everything below SEA_LEVEL over the ground is filled with it).
func test_only_rivers_go_below_the_water_line() -> void:
	var shape := _shape()
	_scan(func(x: int, z: int) -> void:
		if shape.terrain_at(x, z) != CandyShape.RIVER:
			assert_gt(shape.height_at(x, z), MeadowsShape.SEA_LEVEL, "dry at %d,%d" % [x, z])
		else:
			assert_lt(shape.height_at(x, z), MeadowsShape.SEA_LEVEL, "a river holds chocolate at %d,%d" % [x, z]))


## A chocolate river is deep enough to swim in (M2 Task 14's water: chest deep is swimming), with a
## chocolate bed and chocolate banks.
func test_chocolate_rivers_are_swimmable_with_chocolate_beds_and_banks() -> void:
	var shape := _shape()
	var deepest := [0]
	_scan(func(x: int, z: int) -> void:
		if shape.terrain_at(x, z) == CandyShape.RIVER:
			deepest[0] = maxi(deepest[0], MeadowsShape.SEA_LEVEL - shape.height_at(x, z)), 2)
	assert_gte(deepest[0], 3, "deep enough to swim (%d blocks)" % deepest[0])
	var r := _find(shape, CandyShape.RIVER)
	var rc := shape.column(r.x, r.y)
	assert_eq(shape.block_in_column(rc.x - 1, rc), BlockIds.CHOCOLATE, "a chocolate bed")
	assert_eq(shape.block_in_column(rc.x, rc), BlockIds.WATER, "the river (chocolate in this universe)")
	var b := _find(shape, CandyShape.BANK)
	var bc := shape.column(b.x, b.y)
	assert_eq(shape.block_in_column(bc.x - 1, bc), BlockIds.CHOCOLATE, "a chocolate bank")
	assert_eq(shape.block_in_column(bc.x, bc), BlockIds.AIR, "banks are dry")


## A gumdrop hill is a round dome of one colour of gumdrop, rising well above the plains round it.
func test_gumdrop_hills_are_round_domes_of_one_colour() -> void:
	var shape := _shape()
	var tallest := [0]
	_scan(func(x: int, z: int) -> void:
		var col := shape.column(x, z)
		if col.y == CandyShape.GREEN_HILL or col.y == CandyShape.RED_HILL:
			tallest[0] = maxi(tallest[0], col.x - col.z)
			var jelly := BlockIds.GUMDROP if col.y == CandyShape.GREEN_HILL else BlockIds.RED_GUMDROP
			assert_eq(shape.block_in_column(col.x - 1, col), jelly, "%d,%d" % [x, z]), 2)
	assert_gte(tallest[0], 6, "hills rise")
	var h := _find(shape, CandyShape.GREEN_HILL)
	if h == NOWHERE:
		h = _find(shape, CandyShape.RED_HILL)
	var c := shape.hill_near(h.x, h.y)
	assert_gt(c.z, 0, "the hill's centre and radius")
	var peak := shape.height_at(c.x, c.y)
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var prev := peak
		for i in range(1, c.z + 2):
			var here := shape.height_at(c.x + d.x * i, c.y + d.y * i)
			assert_lte(here, prev + 1, "a dome only goes down from its middle")
			prev = here


## A cake mountain is tiered like a wedding cake: each tier is TIER_H high; its sides show sponge, jam and
## cream; a lower tier's top is cream, the top tier's is sprinkles.
func test_cake_mountains_are_tiered_layer_cakes() -> void:
	var shape := _shape()
	var rises := {}
	_scan(func(x: int, z: int) -> void:
		var col := shape.column(x, z)
		if col.y == CandyShape.CAKE_MOUNTAIN:
			var rise := col.x - col.z
			assert_eq(rise % CandyShape.TIER_H, 0, "whole tiers at %d,%d (rise %d)" % [x, z, rise])
			rises[rise / CandyShape.TIER_H] = true, 2)
	assert_true(rises.has(1) and rises.has(2) and rises.has(CandyShape.TIERS), "every tier is there: %s" % [rises.keys()])
	var top := _find(shape, CandyShape.CAKE_MOUNTAIN, func(x: int, z: int) -> bool:
		var col := shape.column(x, z)
		return col.x - col.z == CandyShape.TIERS * CandyShape.TIER_H)
	var tc := shape.column(top.x, top.y)
	assert_eq(shape.block_in_column(tc.x - 1, tc), BlockIds.SPRINKLES, "sprinkles on the top tier")
	var layers := {}
	for y in range(tc.z, tc.x - 1):
		layers[shape.block_in_column(y, tc)] = true
	for id in [BlockIds.CAKE, BlockIds.JAM, BlockIds.CREAM]:
		assert_true(layers.has(id), "a layer of %s" % BlockIds.display_name(id))
	var low := _find(shape, CandyShape.CAKE_MOUNTAIN, func(x: int, z: int) -> bool:
		var col := shape.column(x, z)
		return col.x - col.z == CandyShape.TIER_H)
	var lc := shape.column(low.x, low.y)
	assert_eq(shape.block_in_column(lc.x - 1, lc), BlockIds.CREAM, "cream icing on a lower tier")


func test_plains_layers() -> void:
	var shape := _shape()
	var p := _find(shape, CandyShape.PLAINS)
	var col := shape.column(p.x, p.y)
	var h := col.x
	assert_eq(shape.block_in_column(h - 1, col), BlockIds.FROSTING, "frosting on top")
	assert_eq(shape.block_in_column(h - 2, col), BlockIds.CAKE, "cake under it")
	assert_eq(shape.block_in_column(h - CandyShape.CAKE_DEPTH - 2, col), BlockIds.CHOCOLATE, "a chocolate layer deeper down")
	assert_eq(shape.block_in_column(h, col), BlockIds.AIR)
	assert_eq(shape.block_in_column(-5, col), BlockIds.DEEPSTONE)
	assert_eq(shape.block_in_column(MeadowsShape.WORLD_BOTTOM, col), BlockIds.BEDROCK)
	assert_eq(shape.column_block(h - 1, h), BlockIds.FROSTING, "MeadowsShape's own signature: plains layers")


## The generator fills stone up to stone_top and writes the layers above it itself (checked against
## block_in_column in test_candy_generator); stone_top must be exactly where the stone ends.
func test_stone_top_is_where_the_stone_ends() -> void:
	var shape := _shape()
	var n := [0]
	_scan(func(x: int, z: int) -> void:
		var col := shape.column(x, z)
		var top := shape.stone_top(col)
		assert_eq(shape.block_in_column(top - 1, col), BlockIds.STONE, "%d,%d" % [x, z])
		assert_ne(shape.block_in_column(top, col), BlockIds.STONE, "%d,%d" % [x, z])
		for y in range(top, col.x):
			assert_ne(shape.block_in_column(y, col), BlockIds.STONE, "no stone above it at %d,%d,%d" % [x, y, z])
		n[0] += 1)
	assert_gt(n[0], 1000)


func test_candy_canes_and_lollipops_grow_in_forests_on_the_plains() -> void:
	var shape := _shape()
	var count := {CandyShape.CANE: 0, CandyShape.LOLLIPOP_TREE: 0, CandyShape.COTTON: 0}
	var in_forest := [0, 0]           # trees in forests, trees outside
	for z in range(-SPAN / 2, SPAN / 2, 2):
		for x in range(-SPAN / 2, SPAN / 2, 2):
			var p := shape.plant_at(x, z)
			if p == CandyShape.NO_PLANT:
				continue
			count[p] += 1
			assert_true(shape.tree_at(x, z), "a plant counts as a tree (secrets stay off it)")
			assert_eq(shape.terrain_at(x, z), CandyShape.PLAINS, "plants grow on the plains")
			if p != CandyShape.COTTON:
				in_forest[0 if shape.forest_at(x, z) else 1] += 1
	for p: int in count:
		assert_gt(count[p], 5, "plant %d grows somewhere" % p)
	assert_gt(in_forest[0], in_forest[1], "candy-cane forests: most trees stand in them")
	for i in 50:
		var h := shape.plant_height(i * 7, i * 13)
		assert_between(h, 1, CandyShape.PLANT_TOP)
	assert_lte(CandyShape.PLANT_REACH, 2, "a plant reaches at most 2 blocks sideways")


## A new kingdom world starts on open, gentle frosting: not on a hill, a cake or a river bank.
func test_the_spawn_is_on_open_flat_frosting() -> void:
	for s in [SEED, 7, 99, 424242]:
		var shape := _shape(s)
		var c := shape.spawn_column()
		assert_eq(shape.terrain_at(c.x, c.y), CandyShape.PLAINS, "seed %d" % s)
		var lo := 999
		var hi := -999
		for dz in [-6, 0, 6]:
			for dx in [-6, 0, 6]:
				lo = mini(lo, shape.height_at(c.x + dx, c.y + dz))
				hi = maxi(hi, shape.height_at(c.x + dx, c.y + dz))
		assert_lte(hi - lo, CandyShape.SPAWN_FLAT, "flat around the spawn (seed %d)" % s)
		assert_gt(lo, MeadowsShape.SEA_LEVEL + 1, "dry (seed %d)" % s)
		assert_eq(shape.spawn_column(), c, "the same every time")


## The generator's fast path (a chunk's hills and cakes looked up once) gives exactly column()'s answer.
func test_the_chunk_fast_path_equals_column() -> void:
	var shape := _shape()
	var checked := 0
	for i in 40:
		var x0 := (i * 37 - 700) * 16
		var z0 := (i * 23 - 460) * 16
		var features := shape.features_in(x0, z0, x0 + 16, z0 + 16)
		for k in 64:
			var x := x0 + (k * 5) % 16
			var z := z0 + (k * 11) % 16
			assert_eq(shape.column_among(x, z, features), shape.column(x, z), "%d,%d" % [x, z])
			checked += 1
	var cake := _find(shape, CandyShape.CAKE_MOUNTAIN)
	var hill := _find(shape, CandyShape.GREEN_HILL)
	for spot: Vector2i in [cake, hill]:
		var x0 := floori(spot.x / 16.0) * 16
		var z0 := floori(spot.y / 16.0) * 16
		var features := shape.features_in(x0, z0, x0 + 16, z0 + 16)
		for z in range(z0, z0 + 16):
			for x in range(x0, x0 + 16):
				assert_eq(shape.column_among(x, z, features), shape.column(x, z), "%d,%d" % [x, z])
	assert_gt(checked, 2000)
