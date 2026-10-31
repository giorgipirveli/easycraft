extends GutTest
## M3 Task 2 (spec §14.1): the Sandstorm Desert's terrain rules (DesertShape, a MeadowsShape every world
## system can use): a sandy floor with long dunes, striped mesas with terraced cliffs, oases (a pond, grassy
## banks, palms), cacti and dry bushes; no rivers and no sea. Every rule is a function of (x, z) and the seed.

const SEED := 12345
const SPAN := 640                 # the region the feature tests scan (every 8th column)
const STEP := 8


func _shape(s: int = SEED) -> DesertShape:
	return DesertShape.new(s)


func test_it_is_a_meadows_shape_for_every_world_system() -> void:
	var shape: MeadowsShape = _shape()
	assert_true(shape is DesertShape)
	assert_eq(shape.seed, SEED)
	assert_false(shape.is_river(10, 20), "no rivers in the desert")


func test_the_same_seed_makes_the_same_desert() -> void:
	var a := _shape()
	var b := _shape()
	var c := _shape(SEED + 1)
	var differs := 0
	for i in 200:
		var x := i * 37 - 3000
		var z := i * 53 - 4000
		assert_eq(a.height_at(x, z), b.height_at(x, z))
		assert_eq(a.terrain_at(x, z), b.terrain_at(x, z))
		assert_eq(a.plant_at(x, z), b.plant_at(x, z))
		if a.height_at(x, z) != c.height_at(x, z):
			differs += 1
	assert_gt(differs, 100, "another seed, another desert")


func _scan(f: Callable) -> void:
	for z in range(-SPAN / 2, SPAN / 2, STEP):
		for x in range(-SPAN / 2, SPAN / 2, STEP):
			f.call(x, z)


func test_dunes_mesas_and_oases_are_all_there() -> void:
	var shape := _shape()
	var seen := {DesertShape.DESERT: 0, DesertShape.OASIS: 0, DesertShape.MESA: 0}
	var water := [0]
	var lo := [999]
	var hi := [-999]
	_scan(func(x: int, z: int) -> void:
		var k := shape.terrain_at(x, z)
		seen[k] += 1
		var h := shape.height_at(x, z)
		if k == DesertShape.OASIS and h < MeadowsShape.SEA_LEVEL:
			water[0] += 1
		if k == DesertShape.DESERT:
			lo[0] = mini(lo[0], h)
			hi[0] = maxi(hi[0], h))
	assert_gt(seen[DesertShape.MESA], 40, "mesas")
	assert_gt(seen[DesertShape.OASIS], 10, "oases")
	assert_gt(water[0], 3, "oasis ponds hold water")
	assert_gt(seen[DesertShape.DESERT], seen[DesertShape.MESA] * 3, "mostly open desert")
	assert_gte(hi[0] - lo[0], 8, "dunes rise and fall (%d..%d)" % [lo[0], hi[0]])
	var top := [0]
	_scan(func(x: int, z: int) -> void: top[0] = maxi(top[0], shape.height_at(x, z)))
	assert_lt(top[0], DesertShape.TOP, "every ground is under TOP: the generator skips the sky above it")
	assert_gt(top[0], DesertShape.TOP - 6, "... and TOP is not far above the highest mesa")
	assert_lt(DesertShape.OASIS_MIN_R, DesertShape.OASIS_MAX_R)


## Water only in oasis ponds: the open desert and the mesas stay above the sea level, so no lake appears
## by accident (MeadowsShape.column_block fills everything below SEA_LEVEL with water).
func test_only_oases_go_below_the_water_line() -> void:
	var shape := _shape()
	_scan(func(x: int, z: int) -> void:
		if shape.terrain_at(x, z) != DesertShape.OASIS:
			assert_gt(shape.height_at(x, z), MeadowsShape.SEA_LEVEL + 1, "dry at %d,%d" % [x, z]))


func _find(shape: DesertShape, kind: int) -> Vector2i:
	for z in range(-SPAN / 2, SPAN / 2, 4):
		for x in range(-SPAN / 2, SPAN / 2, 4):
			if shape.terrain_at(x, z) == kind:
				return Vector2i(x, z)
	return Vector2i(999999, 999999)


## A mesa rises well above the desert floor under it, in terraces (ledges a child can see), never one
## sheer wall from the floor to the top.
func test_mesas_are_tall_and_terraced() -> void:
	var shape := _shape()
	var tallest := [0]                # (a lambda copies plain locals: DEVELOPMENT.md §8)
	var steps := {}
	_scan(func(x: int, z: int) -> void:
		if shape.terrain_at(x, z) == DesertShape.MESA:
			var rise := shape.height_at(x, z) - shape.floor_at(x, z)
			tallest[0] = maxi(tallest[0], rise)
			steps[rise / 4] = true)
	assert_gte(tallest[0], DesertShape.MESA_RISE - 4, "a mesa top is high above the floor")
	assert_gte(steps.size(), 3, "rises of several heights: terraces")
	# along a line into a mesa, no single step is the whole mesa
	var m := _find(shape, DesertShape.MESA)
	assert_ne(m, Vector2i(999999, 999999))
	var worst := 0
	for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var prev := shape.height_at(m.x, m.y)
		for i in range(1, 40):
			var h := shape.height_at(m.x + dir.x * i, m.y + dir.y * i)
			worst = maxi(worst, absi(h - prev))
			prev = h
	assert_lt(worst, DesertShape.MESA_RISE, "cliffs come in steps (worst %d)" % worst)


func test_column_layers_desert_mesa_and_oasis() -> void:
	var shape := _shape()
	var d := _find(shape, DesertShape.DESERT)
	var col := shape.column(d.x, d.y)
	var h := col.x
	assert_eq(shape.block_in_column(h - 1, col), BlockIds.SAND, "sand on top")
	assert_eq(shape.block_in_column(h, col), BlockIds.AIR)
	assert_eq(shape.block_in_column(col.z - DesertShape.SANDSTONE_DEPTH + 1, col), BlockIds.SANDSTONE, "sandstone under the sand")
	assert_eq(shape.block_in_column(-5, col), BlockIds.DEEPSTONE)
	assert_eq(shape.block_in_column(MeadowsShape.WORLD_BOTTOM, col), BlockIds.BEDROCK)
	var m := _find(shape, DesertShape.MESA)
	var mc := shape.column(m.x, m.y)
	assert_eq(shape.block_in_column(mc.x - 1, mc), BlockIds.RED_SAND, "red sand on a mesa")
	var bands := {}
	for y in range(mc.z, mc.x - 1):
		bands[shape.block_in_column(y, mc)] = true
	assert_true(bands.has(BlockIds.RED_SANDSTONE), "red sandstone stripes")
	var found := [Vector2i(999999, 999999), Vector2i(999999, 999999)]   # a pond, a bank
	_scan(func(x: int, z: int) -> void:
		if shape.terrain_at(x, z) == DesertShape.OASIS:
			if shape.height_at(x, z) < MeadowsShape.SEA_LEVEL:
				found[0] = Vector2i(x, z)
			elif shape.height_at(x, z) > MeadowsShape.SEA_LEVEL:
				found[1] = Vector2i(x, z))
	var o: Vector2i = found[0]
	var bank: Vector2i = found[1]
	var oc := shape.column(o.x, o.y)
	assert_eq(shape.block_in_column(oc.x, oc), BlockIds.WATER, "a pond")
	assert_eq(shape.block_in_column(oc.x - 1, oc), BlockIds.SAND, "on sand")
	var bc := shape.column(bank.x, bank.y)
	assert_eq(shape.block_in_column(bc.x - 1, bc), BlockIds.GRASS, "grassy banks")


## The generator fills stone up to stone_top and writes the layers above it itself (checked against
## block_in_column in test_desert_generator); stone_top must be exactly where the stone ends.
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


func test_cacti_and_bushes_grow_in_the_open_desert_and_palms_by_the_water() -> void:
	var shape := _shape()
	var count := {DesertShape.CACTUS: 0, DesertShape.PALM: 0, DesertShape.BUSH: 0}
	for z in range(-SPAN / 2, SPAN / 2, 2):
		for x in range(-SPAN / 2, SPAN / 2, 2):
			var p := shape.plant_at(x, z)
			if p == DesertShape.NO_PLANT:
				continue
			count[p] += 1
			var k := shape.terrain_at(x, z)
			assert_true(shape.tree_at(x, z), "a plant counts as a tree (secrets stay off it)")
			if p == DesertShape.PALM:
				assert_eq(k, DesertShape.OASIS, "palms at oases")
				assert_gt(shape.height_at(x, z), MeadowsShape.SEA_LEVEL, "never in the pond")
			else:
				assert_eq(k, DesertShape.DESERT, "cacti and bushes in the open desert")
	for p: int in count:
		assert_gt(count[p], 3, "plant %d grows somewhere" % p)
	assert_between(shape.plant_height(3, 4), 1, 7)


## A new desert world starts on open, gentle sand: not on a mesa, not in an oasis, not on a dune's steep side.
func test_the_spawn_is_on_open_flat_sand() -> void:
	for s in [SEED, 7, 99, 424242]:
		var shape := _shape(s)
		var c := shape.spawn_column()
		assert_eq(shape.terrain_at(c.x, c.y), DesertShape.DESERT, "seed %d" % s)
		var lo := 999
		var hi := -999
		for dz in [-6, 0, 6]:
			for dx in [-6, 0, 6]:
				lo = mini(lo, shape.height_at(c.x + dx, c.y + dz))
				hi = maxi(hi, shape.height_at(c.x + dx, c.y + dz))
		assert_lte(hi - lo, DesertShape.SPAWN_FLAT, "flat around the spawn (seed %d)" % s)
		assert_eq(shape.spawn_column(), c, "the same every time")
