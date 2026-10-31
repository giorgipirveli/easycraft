extends GutTest
## Owner feedback #39 (spec §14.2a): the Dragon Realm's terrain rules (DragonShape, a MeadowsShape every world
## system can use): floating islands over a starry void. An island mask from noise, each island a flat-ish top
## (heights around 40-90, varied from island to island) over a tapered underside, void between them; a big home
## island round the world spawn, always; no bedrock, no water, nothing below the islands. Giant glowing mushrooms
## and crystal spires are the realm's trees; clouds drift under and between the islands. A void column's height
## makes every spawner say "no ground here".

const SEED := 12345
const SPAN := 768                # columns -SPAN/2 .. SPAN/2 are sampled
const STEP := 6

var shape: DragonShape


func before_all() -> void:
	shape = DragonShape.new(SEED)


## The sampled columns (a grid over the SPAN square).
func _sample() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for z in range(-SPAN / 2, SPAN / 2, STEP):
		for x in range(-SPAN / 2, SPAN / 2, STEP):
			out.append(Vector2i(x, z))
	return out


func test_it_is_a_meadows_shape_with_the_seed() -> void:
	assert_true(shape is MeadowsShape, "every system types the shape MeadowsShape")
	assert_eq(shape.seed, SEED)
	assert_false(shape.is_river(10, 10), "no rivers in the sky")


func test_islands_float_over_the_void() -> void:
	var counts := {"island": 0, "void": 0}
	for p in _sample():
		counts["island" if shape.is_island(p.x, p.y) else "void"] += 1
	var total := float(counts.island + counts.void)
	assert_between(counts.island / total, 0.15, 0.5, "islands: %d of %d" % [counts.island, total])
	assert_gt(counts.void / total, 0.4, "and gaps of void between them")


func test_island_tops_are_high_flat_ish_and_varied() -> void:
	var tops: Array[int] = []
	for p in _sample():
		var c := shape.column(p.x, p.y)
		if c.x <= c.y:
			continue
		tops.append(c.x)
		assert_between(c.x, 36, 92, "the top at %s" % p)
		assert_gt(c.x, MeadowsShape.SEA_LEVEL + 1, "every island is dry land to the systems that ask")
		assert_eq(shape.height_at(p.x, p.y), c.x)
		assert_gte(c.y, DragonShape.MIN_BOTTOM, "the underside at %s" % p)
		assert_gte(c.x - c.y, DragonShape.EDGE_THICK, "never thinner than its edge")
	var lo := 999
	var hi := -999
	for t in tops:
		lo = mini(lo, t)
		hi = maxi(hi, t)
	assert_gt(hi - lo, 20, "islands float at different heights (%d..%d)" % [lo, hi])


## Near its edge an island is thin; deep inside it hangs down far: a tapered underside.
func test_undersides_taper_to_the_edge() -> void:
	var s := shape.spawn_column()
	var middle := shape.column(s.x, s.y)
	assert_gt(middle.x - middle.y, 20, "the home island is deep in its middle")
	var tapered := 0
	for a in 8:
		var dir := Vector2(cos(TAU * a / 8.0), sin(TAU * a / 8.0))
		var last := Vector3i.ZERO
		for r in range(0, 200):
			var p := Vector2i(roundi(s.x + dir.x * r), roundi(s.y + dir.y * r))
			var c := shape.column(p.x, p.y)
			if c.x <= c.y:
				break
			last = c
		if last != Vector3i.ZERO and last.x - last.y <= DragonShape.EDGE_THICK + 3:
			tapered += 1
	assert_gte(tapered, 6, "the edge of the home island is thin on most sides")


func test_a_void_column_is_no_ground_for_any_spawner() -> void:
	var found := 0
	for p in _sample():
		if shape.is_island(p.x, p.y) or found > 40:
			continue
		found += 1
		var h := shape.height_at(p.x, p.y)
		assert_eq(h, DragonShape.VOID_HEIGHT)
		assert_lte(h, MeadowsShape.SEA_LEVEL + 1, "land spawners (animals, Tilly, the circle, secrets) see no dry land")
		assert_lt(MeadowsShape.SEA_LEVEL - h, 2, "and fish see no water deep enough to swim in")
		assert_true(AnimalRules._spot(shape, &"sheep", p.x, p.y) == Vector3.INF, "no sheep over the void")
		assert_true(AnimalRules._spot(shape, &"fish", p.x, p.y) == Vector3.INF, "no fish in the void")
		assert_false(shape.tree_at(p.x, p.y))
	assert_gt(found, 40)


func test_nothing_below_the_islands_no_bedrock_no_water() -> void:
	for p: Vector2i in [shape.spawn_column(), Vector2i(200, -150), Vector2i(-300, 90), Vector2i(77, 301)]:
		var c := shape.column(p.x, p.y)
		var cloud := shape.cloud_at(p.x, p.y)
		for y in range(-64, 192):
			var id := shape.block_in_column(y, c, cloud)
			assert_ne(id, BlockIds.BEDROCK)
			assert_ne(id, BlockIds.WATER)
			if y < DragonShape.MIN_BOTTOM:
				assert_eq(id, BlockIds.AIR, "the void under %s at %d" % [p, y])


func test_an_islands_layers() -> void:
	var s := shape.spawn_column()
	var c := shape.column(s.x, s.y)
	var none := Vector2i.ZERO
	assert_eq(shape.block_in_column(c.x, c, none), BlockIds.AIR)
	assert_eq(shape.block_in_column(c.x - 1, c, none), BlockIds.SKY_GRASS)
	assert_eq(shape.block_in_column(c.x - 2, c, none), BlockIds.FLOATSTONE)
	assert_eq(shape.block_in_column(c.x - 4, c, none), BlockIds.FLOATSTONE)
	assert_eq(shape.block_in_column(c.y, c, none), BlockIds.DEEP_FLOATSTONE, "the underside is deep floatstone")
	assert_eq(shape.block_in_column(c.y - 1, c, none), BlockIds.AIR)
	assert_between(c.z, c.y, c.x - 1 - DragonShape.SOIL, "deep rock only under the soil")


## A big home island round the world spawn, always: safe and wide, flat round the spawn, above the sea level.
func test_the_home_island_at_the_spawn() -> void:
	for world_seed in [SEED, 1, 777, 424242, 99]:
		var sh := DragonShape.new(world_seed)
		var s := sh.spawn_column()
		assert_eq(sh.spawn_column(), s, "the same every time")
		assert_lte(Vector2(s - sh.home).length(), 24.0, "near the home island's middle")
		assert_lte(Vector2(sh.home).length(), DragonShape.HOME_OFFSET * 1.5, "the home island is near the origin")
		var lo := 999
		var hi := -999
		for dz in range(-40, 41, 4):
			for dx in range(-40, 41, 4):
				if dx * dx + dz * dz > 40 * 40:
					continue
				var c := sh.column(s.x + dx, s.y + dz)
				assert_gt(c.x, c.y, "island all round the spawn: %d,%d (seed %d)" % [dx, dz, world_seed])
				if absi(dx) <= 6 and absi(dz) <= 6:
					lo = mini(lo, c.x)
					hi = maxi(hi, c.x)
		assert_lte(hi - lo, DragonShape.SPAWN_FLAT, "flat round the spawn (seed %d)" % world_seed)
		assert_gt(lo, MeadowsShape.SEA_LEVEL + 10)
		for dz in range(-3, 4):
			for dx in range(-3, 4):
				assert_eq(sh.plant_at(s.x + dx, s.y + dz), DragonShape.NO_PLANT, "no mushroom or spire on the spawn")


## The M2/M3 places round the spawn (Tilly's stall, the Totem, the stone circle, the Theater) find dry ground on
## the home island, never over the void.
func test_the_spawns_neighbours_stand_on_the_home_island() -> void:
	var s := shape.spawn_column()
	var stall: Vector3 = TraderRules.stall_for_world(SEED, shape, s).pos
	assert_true(shape.is_island(floori(stall.x), floori(stall.z)), "Tilly's stall")
	var totem: Vector3 = WaveRules.totem_for_world(SEED, shape, s, stall).pos
	assert_true(shape.is_island(floori(totem.x), floori(totem.z)), "the Totem")
	var circle := HubRules.circle_for_world(SEED, shape, s)
	var c: Vector3 = circle.pos
	assert_true(shape.is_island(floori(c.x), floori(c.z)), "the stone circle")
	var site := TheaterSite.pick_for(shape)
	assert_false(site.is_empty(), "the Theater finds a site")


func test_animals_spawn_only_on_islands() -> void:
	var n := 0
	for cz in range(-8, 8):
		for cx in range(-8, 8):
			for a: Dictionary in AnimalRules.spawns_for_cell(shape, Vector2i(cx, cz)):
				var p: Vector3 = a.pos
				assert_true(shape.is_island(floori(p.x), floori(p.z)), "%s at %s" % [a.species, p])
				assert_ne(a.species, &"fish", "no water in the sky")
				n += 1
	assert_gt(n, 0, "some animals live on the islands")


func test_clouds_drift_in_the_air_under_and_between_islands() -> void:
	var clouds := 0
	var under := 0
	for p in _sample():
		var cl := shape.cloud_at(p.x, p.y)
		if cl.x >= cl.y:
			continue
		clouds += 1
		assert_between(cl.x, DragonShape.MIN_BOTTOM + 1, 70, "cloud base")
		assert_lte(cl.y - cl.x, DragonShape.CLOUD_MAX)
		var c := shape.column(p.x, p.y)
		for y in range(cl.x, cl.y):
			var id := shape.block_in_column(y, c, cl)
			assert_true(id == BlockIds.CLOUD or (y >= c.y and y < c.x), "a cloud never inside an island")
		if c.x > c.y and cl.y <= c.y:
			under += 1
	assert_gt(clouds, 20, "clouds drift here and there")
	assert_gt(under, 0, "some drift under islands")
	assert_false(BlockIds.is_solid(BlockIds.CLOUD), "you pass through them")


func test_mushrooms_and_spires_grow_on_islands() -> void:
	var found := {}
	for q in _sample():
		for dz in 3:
			for dx in 3:
				var x := q.x + dx
				var z := q.y + dz
				var p := shape.plant_at(x, z)
				if p == DragonShape.NO_PLANT:
					continue
				found[p] = int(found.get(p, 0)) + 1
				assert_true(shape.is_island(x, z), "a plant stands on an island")
				assert_true(shape.tree_at(x, z))
				var tall := shape.plant_height(x, z)
				if p == DragonShape.SPIRE:
					assert_between(tall, 5, 14)
				else:
					assert_between(tall, 4, 8)
	assert_gt(int(found.get(DragonShape.SPIRE, 0)), 3, "crystal spires")
	assert_gt(int(found.get(DragonShape.MUSHROOM, 0)), 3, "giant mushrooms")


## Ores lie in the island rock by depth under the island's top (coal just under the moss, diamonds deep in the big
## islands), so a Survivor child can gather them; they only ever replace floatstone.
func test_ores_lie_in_the_island_rock_by_depth() -> void:
	var s := shape.spawn_column()
	var kinds := {}
	for cz in range(-4, 4):
		for cy in range(1, 11):
			for cx in range(-4, 4):
				for vein: Dictionary in shape.veins_in_cell(Vector3i(floori(s.x / 8.0) + cx, cy, floori(s.y / 8.0) + cz)):
					var ore: int = vein.ore
					kinds[ore] = true
					var band: Vector2i = DragonShape.ORE_DEPTH[ore]
					assert_between(int(vein.depth), band.x, band.y, BlockIds.display_name(ore))
					assert_between((vein.blocks as Array).size(), 1, DragonShape.MAX_VEIN)
	for ore in [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD]:
		assert_true(kinds.has(ore), BlockIds.display_name(ore))
	assert_true(kinds.has(BlockIds.DIAMOND) or kinds.has(BlockIds.CRYSTAL), "something precious deep in the home island")
	assert_eq(shape.ore_in(BlockIds.SKY_GRASS, BlockIds.COAL), BlockIds.SKY_GRASS, "the moss stays moss")
	assert_eq(shape.ore_in(BlockIds.FLOATSTONE, BlockIds.COAL), BlockIds.COAL)
	assert_eq(shape.ore_in(BlockIds.DEEP_FLOATSTONE, BlockIds.GOLD), BlockIds.GOLD)
	assert_eq(shape.ore_in(BlockIds.AIR, BlockIds.GOLD), BlockIds.AIR, "never in the air")
