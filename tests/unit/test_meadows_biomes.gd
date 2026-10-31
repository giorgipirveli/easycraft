extends GutTest
## Owner feedback #45b (spec §14.18): the wild meadows (terrain version 2). Biomes blended into the old noise
## (birch and dark forests, flower fields, swamps, beaches, a sea with islands, tall mountains with snowy tops),
## rivers that run to the sea, cave regions (glowing mushroom caves, underground lakes), all from the seed alone.

const SEED := 12345

var s: MeadowsBiomeShape
var _survey := {}          # biome -> count over a wide grid (seed 12345)
var _samples := 0


func before_all() -> void:
	s = MeadowsBiomeShape.new(SEED)
	for x in range(-2400, 2400, 48):
		for z in range(-2400, 2400, 48):
			var b := s.column(x, z).y
			_survey[b] = int(_survey.get(b, 0)) + 1
			_samples += 1
	gut.p("biomes over %d columns: %s" % [_samples, _named(_survey)])


func _named(counts: Dictionary) -> String:
	var parts: Array[String] = []
	for b: int in counts:
		parts.append("%s %.1f%%" % [MeadowsBiomeShape.BIOME_NAMES[b], 100.0 * counts[b] / _samples])
	return ", ".join(parts)


func _share(biome: int) -> float:
	return int(_survey.get(biome, 0)) / float(_samples)


# --- Biome picks ---

func test_the_biome_picks_are_the_same_for_the_same_seed() -> void:
	var again := MeadowsBiomeShape.new(SEED)
	for i in 300:
		var x := i * 37 - 5000
		var z := i * 53 + 400
		assert_eq(again.column(x, z), s.column(x, z), "column %d %d" % [x, z])
		assert_eq(again.tree_kind(x, z), s.tree_kind(x, z))
	assert_eq(MeadowsBiomeShape.TERRAIN, 2)


func test_different_seeds_make_different_worlds() -> void:
	var other := MeadowsBiomeShape.new(SEED + 1)
	var differs := 0
	for i in 200:
		if other.column(i * 61, i * 29).y != s.column(i * 61, i * 29).y:
			differs += 1
	assert_gt(differs, 40)


func test_every_biome_is_somewhere_near_the_spawn() -> void:
	for b in [MeadowsBiomeShape.MEADOW, MeadowsBiomeShape.FLOWERS, MeadowsBiomeShape.BIRCH, MeadowsBiomeShape.DARK,
			MeadowsBiomeShape.SWAMP, MeadowsBiomeShape.BEACH, MeadowsBiomeShape.MOUNTAIN, MeadowsBiomeShape.SEA,
			MeadowsBiomeShape.RIVER, MeadowsBiomeShape.ISLAND]:
		assert_gt(_share(b), 0.0, "%s within 2.4 km" % MeadowsBiomeShape.BIOME_NAMES[b])
	for b in [MeadowsBiomeShape.MEADOW, MeadowsBiomeShape.FLOWERS, MeadowsBiomeShape.BIRCH, MeadowsBiomeShape.DARK,
			MeadowsBiomeShape.SWAMP, MeadowsBiomeShape.MOUNTAIN]:
		assert_between(_share(b), 0.025, 0.45, "%s is a real part of the land" % MeadowsBiomeShape.BIOME_NAMES[b])


func test_heights_stay_in_range() -> void:
	for x in range(-3000, 3000, 97):
		for z in range(-3000, 3000, 89):
			assert_between(s.height_at(x, z), MeadowsShape.MIN_HEIGHT, MeadowsShape.MAX_HEIGHT)


## The same continents, hills and mountains as the old Green Meadows: land stays land and the sea stays sea
## (apart from rivers, swamp pools and islands).
func test_the_biomes_are_blended_into_the_old_noise() -> void:
	var old := MeadowsShape.new(SEED)
	var same := 0
	var n := 0
	for x in range(-3000, 3000, 71):
		for z in range(-3000, 3000, 67):
			n += 1
			if (old.height_at(x, z) >= MeadowsShape.SEA_LEVEL) == (s.height_at(x, z) >= MeadowsShape.SEA_LEVEL):
				same += 1
	assert_gt(same / float(n), 0.85, "land and sea where they were: %.3f" % (same / float(n)))


# --- Rivers run to the sea ---

## Every river is one of two families of long winding lines (roughly north-south and east-west): each line is
## x + warp (or z + warp), and the warp never turns faster than the line runs, so a river never closes into a
## loop: it crosses the whole world and meets the other rivers and the sea.
func test_the_rivers_never_close_into_loops() -> void:
	for x in range(-3000, 3000, 37):
		for z in range(-3000, 3000, 131):
			assert_gt(s.river_line_a(x + 1, z) - s.river_line_a(x, z), 0.2, "family A runs on at %d %d" % [x, z])
			assert_gt(s.river_line_b(x, z + 1) - s.river_line_b(x, z), 0.2, "family B runs on at %d %d" % [x, z])


func test_rivers_reach_the_sea() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var tried := 0
	var reached := 0
	var steps: Array[int] = []
	while tried < 10:
		var x := rng.randi_range(-2000, 2000)
		var z := rng.randi_range(-2000, 2000)
		if not s.is_river(x, z):
			continue
		tried += 1
		var r := _steps_to_sea(Vector2i(x, z), 4, 120000)
		if r >= 0:
			reached += 1
			steps.append(r)
	gut.p("rivers reach the open sea after %s steps of 4 blocks" % str(steps))
	assert_eq(reached, tried, "every river sampled reaches the sea")


## Water columns (on a 4-block grid) from `start` to the open sea: steps, or -1 within `limit` cells.
func _steps_to_sea(start: Vector2i, step: int, limit: int) -> int:
	var seen := {start: 0}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size() and seen.size() < limit:
		var p: Vector2i = queue[head]
		head += 1
		if s.is_open_sea(p.x, p.y):
			return int(seen[p])
		for d: Vector2i in [Vector2i(step, 0), Vector2i(-step, 0), Vector2i(0, step), Vector2i(0, -step)]:
			var q := p + d
			if not seen.has(q) and s.height_at(q.x, q.y) < MeadowsShape.SEA_LEVEL:
				seen[q] = int(seen[p]) + 1
				queue.append(q)
	return -1


func test_rivers_are_under_water_and_widen_at_the_coast() -> void:
	var inland := []
	var coast := []
	for x in range(-2400, 2400, 7):
		for z in range(-2400, 2400, 211):
			if not s.is_river(x, z):
				continue
			assert_lt(s.height_at(x, z), MeadowsShape.SEA_LEVEL, "a river is water at %d %d" % [x, z])
			var w := s.river_half_width(x, z)
			if s.coast_share(x, z) < 0.3:
				coast.append(w)
			else:
				inland.append(w)
	assert_gt(inland.size(), 5)
	assert_gt(coast.size(), 0, "some rivers were sampled near the coast")
	if coast.size() > 0 and inland.size() > 0:
		assert_gt(coast.max(), inland.min() + 2.0, "an estuary is wider than a river inland")


# --- The sea, islands, beaches ---

func test_islands_stand_in_the_sea_with_sand_round_them() -> void:
	var found := 0
	for x in range(-2400, 2400, 16):
		for z in range(-2400, 2400, 16):
			var c := s.column(x, z)
			if c.y != MeadowsBiomeShape.ISLAND:
				continue
			found += 1
			assert_gt(c.x, MeadowsShape.SEA_LEVEL + 2, "dry land")
			assert_lt(s.coast_share(x, z), 1.0, "out at sea")
	assert_gt(found, 3, "islands near the spawn")


func test_beaches_are_sand_by_the_water() -> void:
	var beaches := 0
	for x in range(-2400, 2400, 13):
		for z in range(-2400, 2400, 59):
			var c := s.column(x, z)
			if c.y != MeadowsBiomeShape.BEACH:
				continue
			beaches += 1
			assert_between(c.x, MeadowsShape.SEA_LEVEL, MeadowsShape.SEA_LEVEL + MeadowsBiomeShape.BEACH_TOP, "a beach at %d %d" % [x, z])
			assert_eq(s.block_in_column(c.x - 1, c, s.bedrock_top(x, z)), BlockIds.SAND)
	assert_gt(beaches, 20)


func test_the_sea_bed_is_sand_and_the_water_reaches_the_sea_level() -> void:
	for x in range(-2400, 2400, 173):
		for z in range(-2400, 2400, 181):
			var c := s.column(x, z)
			if c.y != MeadowsBiomeShape.SEA:
				continue
			assert_lt(c.x, MeadowsShape.SEA_LEVEL)
			assert_eq(s.block_in_column(MeadowsShape.SEA_LEVEL - 1, c, -64), BlockIds.WATER)
			assert_eq(s.block_in_column(MeadowsShape.SEA_LEVEL, c, -64), BlockIds.AIR)
			assert_true(s.block_in_column(c.x - 1, c, -64) in [BlockIds.SAND, BlockIds.MUD])


# --- Mountains, forests, swamps, flower fields ---

func test_tall_mountains_have_rock_faces_and_snowy_tops() -> void:
	var snowy := 0
	var tallest := 0
	for x in range(-3000, 3000, 23):
		for z in range(-3000, 3000, 97):
			var c := s.column(x, z)
			tallest = maxi(tallest, c.x)
			var top := s.block_in_column(c.x - 1, c, -64)
			if c.x >= MeadowsBiomeShape.SNOW_LINE + 4:
				assert_eq(top, BlockIds.SNOW, "snow on top at %d %d (h %d)" % [x, z, c.x])
				snowy += 1
			elif c.x < MeadowsBiomeShape.SNOW_LINE - 4:
				assert_ne(top, BlockIds.SNOW)
	assert_gt(snowy, 10, "snowy tops near the spawn")
	assert_gt(tallest, 100, "tall mountains: %d" % tallest)


func test_swamps_are_mud_with_pools_and_lily_pads() -> void:
	var mud := 0
	var pools := 0
	var pads := 0
	for x in range(-2400, 2400, 5):
		for z in range(-2400, 2400, 97):
			var c := s.column(x, z)
			if c.y != MeadowsBiomeShape.SWAMP:
				continue
			if c.x >= MeadowsShape.SEA_LEVEL:
				assert_eq(s.block_in_column(c.x - 1, c, -64), BlockIds.MUD, "a swamp's ground is mud")
				mud += 1
			else:
				pools += 1
				if c.z & MeadowsBiomeShape.F_LILY:
					pads += 1
					assert_eq(s.block_in_column(MeadowsShape.SEA_LEVEL, c, -64), BlockIds.LILY_PAD, "a pad on the water")
					assert_eq(s.block_in_column(MeadowsShape.SEA_LEVEL - 1, c, -64), BlockIds.WATER)
	assert_gt(mud, 10)
	assert_gt(pools, 5, "shallow pools in the swamps")
	assert_gt(pads, 0, "lily pads on them")


func test_flowers_grow_on_grass_in_flower_fields_and_meadows() -> void:
	var in_fields := 0
	var fields := 0
	for x in range(-2400, 2400, 3):
		for z in range(-2400, 2400, 127):
			var c := s.column(x, z)
			if c.z & MeadowsBiomeShape.F_FLOWER:
				assert_true(c.y in [MeadowsBiomeShape.FLOWERS, MeadowsBiomeShape.MEADOW], MeadowsBiomeShape.BIOME_NAMES[c.y])
				assert_eq(s.block_in_column(c.x, c, -64), BlockIds.FLOWERS, "the flower stands on the ground")
				assert_eq(s.block_in_column(c.x - 1, c, -64), BlockIds.GRASS)
			if c.y == MeadowsBiomeShape.FLOWERS:
				fields += 1
				if c.z & MeadowsBiomeShape.F_FLOWER:
					in_fields += 1
	assert_gt(fields, 20)
	assert_gt(in_fields / float(maxi(fields, 1)), 0.12, "flower fields are full of flowers")


func test_forests_have_their_own_trees() -> void:
	var kinds := {}
	var counts := {}
	for x in range(-2400, 2400, 1):
		for z in range(-2400, 2400, 173):
			var c := s.column(x, z)
			counts[c.y] = int(counts.get(c.y, 0)) + 1
			var t := s.tree_kind(x, z)
			if t == MeadowsBiomeShape.NO_TREE:
				continue
			assert_gt(c.x, MeadowsShape.SEA_LEVEL + 1, "no tree in the water or on a beach")
			assert_eq(c.z & MeadowsBiomeShape.F_RIVER, 0)
			var key := "%d/%d" % [c.y, t]
			kinds[key] = int(kinds.get(key, 0)) + 1
	var birch := int(kinds.get("%d/%d" % [MeadowsBiomeShape.BIRCH, MeadowsBiomeShape.BIRCH_TREE], 0)) / float(maxi(int(counts.get(MeadowsBiomeShape.BIRCH, 0)), 1))
	var dark := int(kinds.get("%d/%d" % [MeadowsBiomeShape.DARK, MeadowsBiomeShape.DARK_TREE], 0)) / float(maxi(int(counts.get(MeadowsBiomeShape.DARK, 0)), 1))
	var oak := int(kinds.get("%d/%d" % [MeadowsBiomeShape.MEADOW, MeadowsBiomeShape.OAK], 0)) / float(maxi(int(counts.get(MeadowsBiomeShape.MEADOW, 0)), 1))
	gut.p("trees per column: birch forest %.3f, dark forest %.3f, meadow %.3f" % [birch, dark, oak])
	assert_gt(birch, oak * 2.0, "birch forests are thick with birches")
	assert_gt(dark, oak * 2.0, "dark forests are thick with dark oaks")
	assert_gt(oak, 0.0)
	assert_eq(int(kinds.get("%d/%d" % [MeadowsBiomeShape.BIRCH, MeadowsBiomeShape.DARK_TREE], 0)), 0)
	assert_true(s.tree_at(0, 0) == (s.tree_kind(0, 0) != MeadowsBiomeShape.NO_TREE))


# --- The spawn and the shape's other uses ---

func test_the_spawn_is_on_friendly_dry_land() -> void:
	for seed in [SEED, 1, 42, 777, 2024]:
		var shape := MeadowsBiomeShape.new(seed)
		var sp := shape.spawn_column()
		var c := shape.column(sp.x, sp.y)
		assert_gt(c.x, MeadowsShape.SEA_LEVEL + 2, "seed %d" % seed)
		assert_lt(c.x, MeadowsBiomeShape.ROCK_LINE, "not on a mountain top (seed %d)" % seed)
		assert_true(c.y in MeadowsBiomeShape.SPAWN_BIOMES, "seed %d: %s" % [seed, MeadowsBiomeShape.BIOME_NAMES[c.y]])


## Everything that asks a MeadowsShape (the secrets, the treasure pack, animals, Tilly's stall) gets the same
## answers from each of its questions.
func test_the_shape_answers_agree() -> void:
	for i in 200:
		var x := i * 41 - 4000
		var z := 3000 - i * 31
		var c := s.column(x, z)
		assert_eq(s.height_at(x, z), c.x)
		assert_eq(s.is_river(x, z), (c.z & MeadowsBiomeShape.F_RIVER) != 0)
		assert_eq(s._column(x, z), Vector2i(c.x, 1 if s.is_river(x, z) else 0))


## A chunk column's heights and biomes are worked out once for its whole stack of chunks (the generator's
## cost), and they are exactly the columns'.
func test_a_chunk_columns_look_up_equals_the_columns() -> void:
	for origin: Vector2i in [Vector2i(0, 0), Vector2i(-48, 32), Vector2i(1024, -2048)]:
		var cols: Array = s.chunk_columns(origin.x, origin.y)
		var heights: PackedInt32Array = cols[0]
		var info: PackedInt32Array = cols[1]
		var top := -1
		var low := 1000
		for z in 16:
			for x in 16:
				var c := s.column(origin.x + x, origin.y + z)
				assert_eq(heights[x + z * 16], c.x)
				assert_eq(MeadowsBiomeShape.unpack(heights[x + z * 16], info[x + z * 16]), c)
				top = maxi(top, c.x)
				low = mini(low, c.x)
		assert_eq(int(cols[2]), top)
		assert_eq(int(cols[3]), low)
		assert_same(s.chunk_columns(origin.x, origin.y), cols, "cached")


# --- Deeper caves ---

func test_mushroom_caves_and_underground_lakes_have_their_own_regions() -> void:
	var kinds := {}
	for rx in range(-12, 12):
		for rz in range(-12, 12):
			var k := s.cave_region(rx * MeadowsBiomeShape.CAVE_REGION + 5, rz * MeadowsBiomeShape.CAVE_REGION + 9)
			kinds[k] = int(kinds.get(k, 0)) + 1
			assert_eq(k, s.cave_region(rx * MeadowsBiomeShape.CAVE_REGION + 100, rz * MeadowsBiomeShape.CAVE_REGION + 1),
				"one kind per region")
	assert_gt(int(kinds.get(MeadowsBiomeShape.MUSHROOM_CAVES, 0)), 20)
	assert_gt(int(kinds.get(MeadowsBiomeShape.LAKE_CAVES, 0)), 20)
	assert_gt(int(kinds.get(MeadowsBiomeShape.PLAIN_CAVES, 0)), 200)
