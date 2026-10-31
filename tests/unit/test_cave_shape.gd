extends GutTest
## Caves: spaghetti tunnels (|a| and |b| both small), deep caverns (c high), a solid crust under
## the ground and under water, rare surface entrances, a bedrock floor, flooded deep caves.

const TUNNEL := Vector3(0.01, -0.02, -1.0)
const SOLID := Vector3(0.5, 0.5, -1.0)
const CAVERN := Vector3(0.5, 0.5, 0.95)
const SURFACE := 60

var cave: CaveShape


func before_each() -> void:
	cave = CaveShape.new(7)


func test_tunnel_carves_where_both_noises_are_near_zero() -> void:
	assert_eq(cave.decide(TUNNEL, 10, SURFACE, false), BlockIds.AIR)


func test_one_small_noise_is_not_a_tunnel() -> void:
	assert_eq(cave.decide(Vector3(0.01, 0.5, -1.0), 10, SURFACE, false), -1)
	assert_eq(cave.decide(SOLID, 10, SURFACE, false), -1)


func test_caverns_open_only_deep_down() -> void:
	assert_eq(cave.decide(CAVERN, -30, SURFACE, false), BlockIds.AIR)
	assert_eq(cave.decide(CAVERN, 20, SURFACE, false), -1, "no giant caverns near the surface")


func test_ground_keeps_a_crust_unless_an_entrance_is_open() -> void:
	var y := SURFACE - 2
	assert_eq(cave.decide(TUNNEL, y, SURFACE, false), -1, "crust")
	assert_eq(cave.decide(TUNNEL, y, SURFACE, false, true), BlockIds.AIR, "entrance")
	assert_eq(cave.decide(TUNNEL, SURFACE, SURFACE, false, true), -1, "nothing to carve above the ground")


func test_no_caves_within_six_blocks_below_water() -> void:
	var floor_y := MeadowsShape.SEA_LEVEL - 4
	for depth in range(1, CaveShape.WATER_CRUST + 1):
		assert_eq(cave.decide(TUNNEL, floor_y - depth, floor_y, true, true), -1, "depth %d" % depth)
	assert_eq(cave.decide(TUNNEL, floor_y - CaveShape.WATER_CRUST - 3, floor_y, true), BlockIds.AIR)


func test_bedrock_zone_is_never_carved() -> void:
	for y in range(MeadowsShape.WORLD_BOTTOM, MeadowsShape.WORLD_BOTTOM + 4):
		assert_eq(cave.decide(TUNNEL, y, SURFACE, false), -1)
		assert_eq(cave.decide(CAVERN, y, SURFACE, false), -1)


func test_deep_caves_are_flooded() -> void:
	assert_eq(cave.decide(TUNNEL, CaveShape.FLOOD_Y - 1, SURFACE, false), BlockIds.WATER)
	assert_eq(cave.decide(TUNNEL, CaveShape.FLOOD_Y, SURFACE, false), BlockIds.AIR)


func test_sample_is_deterministic_and_seeded() -> void:
	var other := CaveShape.new(8)
	var same := CaveShape.new(7)
	var differs := false
	for i in 20:
		var p := Vector3i(i * 13, -i * 3, i * 7)
		assert_eq(cave.sample(p.x, p.y, p.z), same.sample(p.x, p.y, p.z))
		if cave.sample(p.x, p.y, p.z) != other.sample(p.x, p.y, p.z):
			differs = true
	assert_true(differs)


func test_entrances_are_rare() -> void:
	var open := 0
	for x in range(-2000, 2000, 25):
		for z in range(-2000, 2000, 25):
			if cave.entrance_open(x, z):
				open += 1
	var share := open / float(160 * 160)
	assert_between(share, 0.01, 0.12, "share of columns with an entrance: %.3f" % share)


## The coarse-cell skip test must be exact: whenever it says "no cave here", no point inside the
## cell may carve (interpolated values stay within the corner range).
func test_skip_test_never_hides_a_cave() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var skipped := 0
	for i in 600:
		# Corners like real noise over 4 blocks: a random level plus a small spread.
		var level := Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.4, 0.4), rng.randf_range(0.2, 0.9))
		var corners := PackedVector3Array()
		for k in 8:
			corners.append(level + Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(-0.1, 0.1), rng.randf_range(-0.1, 0.1)))
		var y := rng.randi_range(-60, 40)
		if not CaveShape.cell_may_carve(corners, cave.cavern_threshold(y), cave.cavern_threshold(y + 3)):
			skipped += 1
			for s in 64:
				var f := Vector3(rng.randf(), rng.randf(), rng.randf())
				var v := CaveShape.interpolate(corners, f.x, f.y, f.z)
				assert_eq(cave.decide(v, y + int(f.y * 4.0), SURFACE, false), -1, "cell %d hid a cave" % i)
	assert_gt(skipped, 100, "the test must exercise skipped cells")
