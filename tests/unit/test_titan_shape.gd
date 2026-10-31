extends GutTest
## Cosmos: Titan (world 22, spec §21b.2): its terrain as pure rules (SpaceShape with planet TITAN; the regions in
## TitanTerrain). Plains of orange-brown soil with patches of ice pebbles over icy rock (water ice as hard as stone); the
## methane sea to the north (Titan's biggest seas lie near its north pole), small methane lakes (more of them to the
## north), each filled to one level (LIQUID_TOP: the game's WATER, shown as liquid methane) with a beach level with it
## and a gentle coast, so a child walks out of every one; long east-west dunes of dark grains to the south; a range of
## icy mountains to the east or west. Ice boulders on the plains, shore crystals on the beaches. Every step a child meets
## is one a Titan jump climbs (and the step hop climbs one block).

const SEED := 12345
const SEEDS: Array[int] = [12345, 77, 777, 42]


func _titan(seed: int = SEED) -> SpaceShape:
	return SpaceShape.new(seed, SpaceShape.TITAN)


func _jump() -> float:
	return Player.JUMP_VELOCITY * Player.JUMP_VELOCITY / (2.0 * Player.GRAVITY * 0.14)


func test_titan_is_a_space_planet_with_its_terrain() -> void:
	assert_has(SpaceShape.PLANETS, SpaceShape.TITAN)
	var s := _titan()
	assert_eq(s.planet, SpaceShape.TITAN)
	assert_not_null(s.titan, "Titan's regions")
	assert_null(s.io)
	assert_null(s.europa)
	assert_null(s.mars)
	assert_null(SpaceShape.new(SEED, SpaceShape.IO).titan, "Io has none")
	assert_lt(float(TitanTerrain.MAX_STEP), _jump() - 0.5, "a jump at 0.14 gravity reaches ~12 blocks")


func test_heights_stay_between_the_floor_and_the_sky() -> void:
	var s := _titan()
	var t := s.titan
	var points: Array[Vector2i] = [t.sea_centre(), t.peak_centre()]
	for i in 900:
		points.append(Vector2i((i * 37) % 2400 - 1200, (i * 91) % 2400 - 1200))
	for p in points:
		var h := s.height_at(p.x, p.y)
		assert_gt(h, MeadowsShape.SEA_LEVEL + 2, "(%d, %d): over the old sea level" % [p.x, p.y])
		assert_lt(h, SpaceGenerator.SKY_TOP - 40, "(%d, %d): far under the sky's limit" % [p.x, p.y])
		assert_gte(s.ground_at(p.x, p.y), SpaceShape.MIN_GROUND, "a floor under every lake")


func test_soil_and_ice_pebbles_over_icy_rock() -> void:
	var s := _titan()
	var kinds := {}
	var checked := 0
	for i in 4000:
		var x := (i * 17) % 1400 - 700
		var z := (i * 11) % 1400 - 700
		var k := s.titan_kind(x, z)
		kinds[k] = int(kinds.get(k, 0)) + 1
		if not TitanTerrain.is_plains(k) or s.pad_at(x, z) or s.tree_at(x, z):
			continue
		checked += 1
		var h := s.height_at(x, z)
		assert_eq(s.block_at(x, h - 1, z), BlockIds.TITAN_SOIL if k == TitanTerrain.PLAINS else BlockIds.ICE_PEBBLES,
			"(%d, %d)" % [x, z])
		assert_eq(s.block_at(x, h - 2, z), BlockIds.TITAN_SOIL, "soil under the top")
		assert_eq(s.block_at(x, h - 8, z), BlockIds.ICY_ROCK, "icy rock under the soil")
		assert_eq(s.block_at(x, -5, z), BlockIds.ICY_ROCK, "icy rock deep down")
		assert_eq(s.block_at(x, MeadowsShape.WORLD_BOTTOM, z), BlockIds.BEDROCK)
		assert_eq(s.block_at(x, h, z), BlockIds.AIR)
	assert_gt(checked, 800, "mostly plains")
	assert_gt(float(kinds.get(TitanTerrain.PEBBLES, 0)) / 4000.0, 0.05, "patches of ice pebbles")
	assert_gt(float(kinds.get(TitanTerrain.PLAINS, 0)), float(kinds.get(TitanTerrain.PEBBLES, 0)), "mostly soil")


func test_every_step_is_one_titan_jump_and_the_shores_are_gentle() -> void:
	for seed in SEEDS:
		var s := _titan(seed)
		var t := s.titan
		var pts: Array[Vector2i] = []
		for i in 3000:
			pts.append(Vector2i((i * 13) % 1400 - 700, (i * 7) % 1400 - 700))
		for c: Vector2i in [t.peak_centre(), t.sea_beach_toward(s.spawn_column()),
				Vector2i(s.spawn_column().x, t.dune_edge() + 60)]:
			for dz in range(-60, 61, 4):
				for dx in range(-60, 61):
					pts.append(c + Vector2i(dx, dz))
		for p in pts:
			for n: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
				var a := s.ground_at(p.x, p.y)
				var b := s.ground_at(p.x + n.x, p.y + n.y)
				assert_lte(absi(a - b), TitanTerrain.MAX_STEP, "seed %d (%d, %d)" % [seed, p.x, p.y])
				if s.is_river(p.x, p.y) or s.is_river(p.x + n.x, p.y + n.y) \
						or TitanTerrain.is_shore(s.titan_kind(p.x, p.y)):
					assert_lte(absi(a - b), 1, "seed %d (%d, %d): a lake's bed and shore step one block" % [seed, p.x, p.y])


# --- The methane sea and lakes ---

func test_the_methane_sea_lies_north_of_the_pad_a_walk_away() -> void:
	for seed in SEEDS:
		var s := _titan(seed)
		var t := s.titan
		var sp := s.spawn_column()
		var sc := t.sea_centre()
		assert_lt(sc.y, sp.y - 150, "seed %d: the sea is to the north (-z), like Titan's biggest seas" % seed)
		var beach := t.sea_beach_toward(sp)
		assert_eq(s.titan_kind(beach.x, beach.y), TitanTerrain.SEA_SHORE, "seed %d: its beach" % seed)
		var d := Vector2(beach - sp).length()
		assert_between(d, 90.0, 330.0, "seed %d: a walk from the pad (%.0f)" % [seed, d])
		assert_eq(s.titan_kind(sc.x, sc.y), TitanTerrain.SEA)
		assert_eq(s.ground_at(sc.x, sc.y), TitanTerrain.LIQUID_TOP - TitanTerrain.SEA_DEPTH, "deep in its middle")


func test_the_sea_is_liquid_methane_up_to_one_level_over_a_wet_bed() -> void:
	var s := _titan()
	var sc := s.titan.sea_centre()
	var g := s.ground_at(sc.x, sc.y)
	assert_eq(s.height_at(sc.x, sc.y), TitanTerrain.LIQUID_TOP, "the methane's top")
	assert_true(s.is_river(sc.x, sc.y), "liquid at the top: never dry land for a spawner")
	for y in range(g, TitanTerrain.LIQUID_TOP):
		assert_eq(s.block_at(sc.x, y, sc.y), BlockIds.WATER, "liquid at y %d (shown as methane)" % y)
	assert_eq(s.block_at(sc.x, TitanTerrain.LIQUID_TOP, sc.y), BlockIds.AIR)
	assert_eq(s.block_at(sc.x, g - 1, sc.y), BlockIds.WET_SHORE, "a wet bed")
	assert_eq(s.block_at(sc.x, g - 8, sc.y), BlockIds.ICY_ROCK)
	var beach := s.titan.sea_beach_toward(s.spawn_column())
	assert_eq(s.ground_at(beach.x, beach.y), TitanTerrain.LIQUID_TOP, "a beach level with the methane's top")
	assert_false(s.is_river(beach.x, beach.y), "the beach is dry")
	assert_eq(s.block_at(beach.x, TitanTerrain.LIQUID_TOP - 1, beach.y), BlockIds.WET_SHORE)


## Walking out of the sea or any lake: from the middle out, the bed rises one block at a time to a waterline one deep
## (wading), then the beach, then a coast of one-block steps up to the plains.
func test_a_child_walks_out_of_the_sea_and_every_lake() -> void:
	var s := _titan()
	var t := s.titan
	var basins: Array[Vector3i] = [Vector3i(t.sea_centre().x, t.sea_centre().y, int(TitanTerrain.SEA_R))]
	for cz in range(-6, 6):
		for cx in range(-6, 6):
			var l := t.lake_in_cell(Vector2i(cx, cz))
			if l.z > 0:
				basins.append(l)
	assert_gt(basins.size(), 6, "the sea and some lakes")
	for b: Vector3i in basins:
		for a in 16:
			var dir := Vector2.from_angle(TAU * a / 16.0)
			var last := -1
			var left_water := false
			for r in range(0, b.z + 40):
				var p := Vector2i(b.x + roundi(dir.x * r), b.y + roundi(dir.y * r))
				var g := s.ground_at(p.x, p.y)
				if last >= 0:
					assert_lte(g - last, 1, "out from %s: one block at a time (%s)" % [b, p])
				if not s.is_river(p.x, p.y):
					if not left_water and last >= 0:
						assert_eq(last, TitanTerrain.LIQUID_TOP - 1, "the waterline is one deep (wading) at %s" % p)
					left_water = true
				last = g
			assert_true(left_water, "every way out of %s reaches dry land" % b)


func test_small_lakes_more_in_the_north_filled_with_methane() -> void:
	var s := _titan()
	var t := s.titan
	var north := 0
	var south := 0
	for cz in range(-10, 10):
		for cx in range(-10, 10):
			var l := t.lake_in_cell(Vector2i(cx, cz))
			if l.z <= 0:
				continue
			assert_between(l.z, TitanTerrain.LAKE_R.x, TitanTerrain.LAKE_R.y)
			if l.y < 0:
				north += 1
			else:
				south += 1
			assert_eq(s.titan_kind(l.x, l.y), TitanTerrain.LAKE)
			assert_eq(s.height_at(l.x, l.y), TitanTerrain.LIQUID_TOP)
			assert_eq(s.block_at(l.x, TitanTerrain.LIQUID_TOP - 1, l.y), BlockIds.WATER, "methane in it")
			assert_eq(s.ground_at(l.x, l.y), TitanTerrain.LIQUID_TOP - TitanTerrain.LAKE_DEPTH, "its depth")
			assert_lt(l.y, t.dune_edge() - 20, "never among the dunes")
	assert_gt(north, south, "more lakes to the north (%d vs %d)" % [north, south])
	assert_gt(north + south, 20, "lakes all over")


func test_shore_crystals_ring_the_beaches_never_in_the_liquid() -> void:
	var s := _titan()
	var crystals := 0
	var boulders := 0
	for i in 60000:
		var x := (i * 29) % 1600 - 800
		var z := (i * 47) % 1600 - 800
		if not s.tree_at(x, z):
			continue
		assert_false(s.is_river(x, z), "(%d, %d): nothing grows in the methane" % [x, z])
		var h := s.height_at(x, z)
		var id := s.feature_at(x, h, z)
		if id == BlockIds.SHORE_CRYSTAL:
			crystals += 1
			assert_true(TitanTerrain.is_shore(s.titan_kind(x, z)), "on a beach (%d, %d)" % [x, z])
			assert_eq(h, TitanTerrain.LIQUID_TOP, "right by the waterline")
		elif id == BlockIds.ICY_ROCK:
			boulders += 1
			assert_true(TitanTerrain.is_plains(s.titan_kind(x, z)), "ice boulders on the plains")
	assert_gt(crystals, 5, "shore crystals round the lakes")
	assert_gt(boulders, 20, "ice boulders on the plains")


# --- The dunes ---

func test_long_dunes_of_dark_grains_run_east_west_south_of_the_pad() -> void:
	for seed in SEEDS:
		var s := _titan(seed)
		var t := s.titan
		var sp := s.spawn_column()
		assert_gt(t.dune_edge(), sp.y + 60, "seed %d: the dunes start south of the pad (+z)" % seed)
		var dz := t.first_dune_south_of(sp)
		assert_ne(dz, TitanTerrain.NONE, "seed %d: a dune a walk south" % seed)
		assert_between(float(dz.y - sp.y), 60.0, 330.0, "seed %d: a walk away" % seed)
	var s := _titan()
	var t := s.titan
	var dunes := 0
	var tallest := 0
	var along := 0
	var across := 0
	for i in 3000:
		var x := (i * 23) % 800 - 400
		var z := t.dune_edge() + 80 + (i * 7) % 300
		var k := s.titan_kind(x, z)
		if k != TitanTerrain.DUNE:
			continue
		dunes += 1
		var h := s.height_at(x, z)
		assert_eq(s.block_at(x, h - 1, z), BlockIds.DUNE_SAND, "dark grains on top")
		assert_eq(s.block_at(x, h - 3, z), BlockIds.DUNE_SAND, "grains inside")
		tallest = maxi(tallest, h - t.plains_height(x, z))
		if s.titan_kind(x + 4, z) == TitanTerrain.DUNE:
			along += 1
		if s.titan_kind(x, z + 14) == TitanTerrain.DUNE:
			across += 1
	assert_gt(dunes, 600, "a sea of dunes")
	assert_between(tallest, 5, 10, "dunes a few blocks high")
	assert_gt(along, across + dunes / 5, "long ridges east-west (%d along, %d across)" % [along, across])


# --- The icy mountains ---

func test_icy_mountains_to_the_east_or_west_a_walk_away() -> void:
	for seed in SEEDS:
		var s := _titan(seed)
		var t := s.titan
		var sp := s.spawn_column()
		var pk := t.peak_centre()
		var d := Vector2(pk - sp).length()
		assert_between(d, 150.0, 330.0, "seed %d: a walk from the pad (%.0f)" % [seed, d])
		assert_gt(absi(pk.x - sp.x), absi(pk.y - sp.y), "seed %d: to the east or west" % seed)
		assert_eq(s.titan_kind(pk.x, pk.y), TitanTerrain.PEAK)
		var rise := s.height_at(pk.x, pk.y) - t.plains_height(pk.x, pk.y)
		assert_between(rise, TitanTerrain.PEAK_H - 2, TitanTerrain.PEAK_H + 1, "seed %d: its top" % seed)
		assert_eq(s.block_at(pk.x, s.height_at(pk.x, pk.y) - 1, pk.y), BlockIds.ICE_PEBBLES, "pale ice on top")
		var slope := pk + Vector2i(roundi(TitanTerrain.HALF_W - 8), 0)
		if s.titan_kind(slope.x, slope.y) == TitanTerrain.MOUNTAIN:
			assert_eq(s.block_at(slope.x, s.height_at(slope.x, slope.y) - 1, slope.y), BlockIds.ICY_ROCK, "icy rock")


# --- The landing pad and the sights ---

func test_the_pad_is_on_calm_plains_away_from_everything() -> void:
	for seed in SEEDS:
		var s := _titan(seed)
		var t := s.titan
		var sp := s.spawn_column()
		assert_true(TitanTerrain.is_plains(s.titan_kind(sp.x, sp.y)), "seed %d" % seed)
		assert_false(t.lake_near(sp.x, sp.y, 60.0), "seed %d: no lake near the pad" % seed)
		assert_false(t.near_mountain(float(sp.x), float(sp.y), 60.0), "seed %d" % seed)
		for a in 32:
			for r in range(0, 64, 4):
				var p := sp + Vector2i(roundi(cos(TAU * a / 32.0) * r), roundi(sin(TAU * a / 32.0) * r))
				assert_false(s.is_river(p.x, p.y), "seed %d: no methane within 64 of the pad (%s)" % [seed, p])
				assert_ne(s.titan_kind(p.x, p.y), TitanTerrain.DUNE, "seed %d: no dune by the pad" % seed)


func test_the_sights_where_a_child_learns_a_fact() -> void:
	var s := _titan()
	var t := s.titan
	var sc := t.sea_centre()
	assert_eq(s.sight_at(sc.x, sc.y), &"sea", "swimming in the sea")
	var beach := t.sea_beach_toward(s.spawn_column())
	assert_eq(s.sight_at(beach.x, beach.y), &"sea", "on its beach")
	var lake := Vector3i.ZERO
	for cz in range(-6, 6):
		for cx in range(-6, 6):
			if lake.z == 0:
				lake = t.lake_in_cell(Vector2i(cx, cz))
	assert_eq(s.sight_at(lake.x, lake.y), &"lake")
	assert_eq(s.sight_at(lake.x + lake.z + 1, lake.y), &"lake", "its beach")
	var dune := t.first_dune_south_of(s.spawn_column())
	assert_eq(s.sight_at(dune.x, dune.y), &"dunes")
	assert_eq(s.sight_at(t.peak_centre().x, t.peak_centre().y), &"mountain")
	var sp := s.spawn_column()
	assert_eq(s.sight_at(sp.x, sp.y), &"", "nothing at the pad")
	var ids: Array = s.sights().map(func(e: Dictionary) -> StringName: return e.id)
	assert_eq(ids, [&"sea", &"dunes", &"mountain"], "MY MAP shows the sea, the dunes and the mountains from the landing")
	for e: Dictionary in s.sights():
		var p: Vector3 = e.pos
		assert_eq(s.sight_at(floori(p.x), floori(p.z)), e.id, "%s's mark is on it" % e.id)


func test_the_same_seed_is_the_same_titan() -> void:
	var a := _titan()
	var b := _titan()
	assert_eq(a.spawn_column(), b.spawn_column())
	assert_eq(a.titan.sea_centre(), b.titan.sea_centre())
	for i in 50:
		assert_eq(a.height_at(i * 13, -i * 7), b.height_at(i * 13, -i * 7))
	var other := _titan(777)
	assert_ne(other.titan.sea_centre(), a.titan.sea_centre(), "another seed, another Titan")
