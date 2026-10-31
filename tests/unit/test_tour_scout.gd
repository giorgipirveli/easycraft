extends GutTest
## TourScout (tools/tour_scout.gd): where the acceptance tour finds a peak, water, a beach and a
## cave near the spawn, from the generator's rules alone. Checked against MeadowsShape and
## MeadowsGenerator.reference_block (the exact per-block rule).

const SEED := 12345

var scout: TourScout
var shape: MeadowsShape
var spawn: Vector2i


func before_all() -> void:
	scout = TourScout.new(SEED)
	shape = MeadowsShape.new(SEED)
	spawn = shape.spawn_column()


# --- Peak ---

func test_peak_is_the_highest_column_in_a_small_area() -> void:
	var best := -1
	for dz in range(-24, 25):
		for dx in range(-24, 25):
			if dx * dx + dz * dz <= 24 * 24:
				best = maxi(best, shape.height_at(spawn.x + dx, spawn.y + dz))
	var p := scout.peak(spawn, 24, 1)
	assert_eq(p.y, best)
	assert_eq(shape.height_at(p.x, p.z), p.y, "y is the ground height of that column")


func test_peak_stays_within_the_radius() -> void:
	var p := scout.peak(spawn, 300, 4)
	assert_lte(Vector2(p.x - spawn.x, p.z - spawn.y).length(), 300.0)
	assert_eq(shape.height_at(p.x, p.z), p.y)


func test_peak_is_at_least_as_high_as_every_coarse_sample() -> void:
	var p := scout.peak(spawn, 96, 8)
	for dz in range(-96, 97, 8):
		for dx in range(-96, 97, 8):
			if dx * dx + dz * dz <= 96 * 96:
				assert_gte(p.y, shape.height_at(spawn.x + dx, spawn.y + dz))


# --- Water ---

func test_water_is_deep_enough() -> void:
	var c := scout.water(spawn, 400, 3)
	assert_ne(c, TourScout.NO_COLUMN, "water within 400 blocks of the spawn")
	assert_lte(shape.height_at(c.x, c.y), MeadowsShape.SEA_LEVEL - 3)


func test_water_can_ask_for_a_river() -> void:
	var c := scout.water(spawn, 600, 1, TourScout.RIVER)
	assert_ne(c, TourScout.NO_COLUMN, "a river within 600 blocks")
	assert_true(shape.is_river(c.x, c.y))


func test_water_nothing_in_a_tiny_dry_area() -> void:
	assert_eq(scout.water(spawn, 0, 1), TourScout.NO_COLUMN, "the spawn column itself is dry land")


# --- Shore ---

func test_shore_is_a_beach_block_next_to_water() -> void:
	var s := scout.shore(spawn, 400)
	assert_false(s.is_empty(), "a shore within 400 blocks")
	if s.is_empty():
		return
	var land: Vector2i = s.land
	var water: Vector2i = s.water
	assert_eq(absi(land.x - water.x) + absi(land.y - water.y), 1, "4-neighbours (water flows sideways)")
	var y := MeadowsShape.SEA_LEVEL - 1
	assert_true(BlockIds.is_solid(scout.generator.reference_block(land.x, y, land.y)), "a solid block at the waterline")
	assert_eq(scout.generator.reference_block(water.x, y, water.y), BlockIds.WATER, "water beside it")


func test_shore_none_without_water() -> void:
	assert_true(scout.shore(spawn, 0).is_empty())


# --- Flat ground ---

func test_flat_is_level_dry_ground_without_trees() -> void:
	var c := scout.flat(spawn, 64, 2)
	assert_ne(c, TourScout.NO_COLUMN, "flat ground within 64 blocks of the spawn")
	if c == TourScout.NO_COLUMN:
		return
	var h := shape.height_at(c.x, c.y)
	assert_gt(h, MeadowsShape.SEA_LEVEL + 1, "dry land")
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			assert_eq(shape.height_at(c.x + dx, c.y + dz), h, "level at %d,%d" % [dx, dz])
			assert_false(shape.is_river(c.x + dx, c.y + dz))
	var reach := 2 + MeadowsGenerator.TREE_REACH   # no leaves hang over it either
	for dz in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			assert_false(shape.tree_at(c.x + dx, c.y + dz), "no tree at %d,%d" % [dx, dz])


func test_flat_several_seeds() -> void:
	for s in [1, 42, 777]:
		var other := TourScout.new(s)
		var home := MeadowsShape.new(s).spawn_column()
		assert_ne(other.flat(home, 64), TourScout.NO_COLUMN, "seed %d" % s)


func test_flat_nothing_in_the_sea() -> void:
	var sea := scout.water(spawn, 400, 6, TourScout.SEA)
	if sea == TourScout.NO_COLUMN:
		pass_test("no deep sea near this spawn")
		return
	assert_eq(scout.flat(sea, 0, 2), TourScout.NO_COLUMN, "deep water is not dry ground")


# --- Cave ---

func test_cave_is_dry_air_with_room_and_a_ceiling() -> void:
	var c := scout.cave(spawn, 128, -38, -22)
	assert_ne(c, TourScout.NOT_FOUND, "a deep dry cave within 128 blocks")
	if c == TourScout.NOT_FOUND:
		return
	assert_between(c.y, -38, -22)
	assert_eq(scout.generator.reference_block(c.x, c.y, c.z), BlockIds.AIR, "feet")
	assert_eq(scout.generator.reference_block(c.x, c.y + 1, c.z), BlockIds.AIR, "head")
	var ceiling := false
	for dy in range(2, 33):
		if BlockIds.is_solid(scout.generator.reference_block(c.x, c.y + dy, c.z)):
			ceiling = true
			break
	assert_true(ceiling, "a solid ceiling (the cave gets dark)")


func test_cave_not_found_where_caves_cannot_be() -> void:
	assert_eq(scout.cave(spawn, 16, -63, -62), TourScout.NOT_FOUND, "no caves in the bedrock layer")
