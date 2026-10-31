extends GutTest
## Cosmos: Mars (world 19, spec §21b.2): its terrain as pure rules (SpaceShape with planet MARS; the regions in
## MarsTerrain). Wide dusty plains of red dust over rusty regolith and basalt (with pale layers in the rock), craters
## with raised rims, dry river valleys with pale beds, a giant shield volcano (wide gentle slopes, a caldera on top,
## far taller than anything round it and still under the sky's limit), a long canyon running east and west (a flat
## floor far below the plains, terraced walls a child can climb), and the polar ice caps: water ice with dusty layers
## in the north, dry ice on top in the south. No water, no caves. Every step a child meets is one a Mars jump climbs.

const SEED := 12345
const MARS_JUMP := 4.0            # a jump at 0.38 gravity reaches ~4.4 blocks: every step must be this or less


func _mars(seed: int = SEED) -> SpaceShape:
	return SpaceShape.new(seed, SpaceShape.MARS)


func test_mars_is_a_space_planet_with_its_regions() -> void:
	assert_has(SpaceShape.PLANETS, SpaceShape.MARS)
	var s := _mars()
	assert_eq(s.planet, SpaceShape.MARS)
	assert_not_null(s.mars, "Mars's regions")
	assert_null(SpaceShape.new(SEED, SpaceShape.MOON).mars, "the Moon has none")


func test_heights_stay_between_the_floor_and_the_sky() -> void:
	var s := _mars()
	var vc := s.mars.volcano_centre()
	var points: Array[Vector2i] = [vc, vc + Vector2i(20, 0), vc + Vector2i(0, -60)]
	for i in 900:
		points.append(Vector2i((i * 37) % 2400 - 1200, (i * 91) % 2400 - 1200))
	for p in points:
		var h := s.height_at(p.x, p.y)
		assert_gte(h, SpaceShape.MIN_GROUND, "(%d, %d): never under the floor" % [p.x, p.y])
		assert_lt(h, SpaceGenerator.SKY_TOP - 4, "(%d, %d): under the sky's limit, room to fly over" % [p.x, p.y])
		assert_false(s.is_river(p.x, p.y), "no water on Mars")


func test_plains_are_red_dust_over_regolith_over_basalt() -> void:
	var s := _mars()
	var checked := 0
	for i in 400:
		var x := (i * 53) % 900 - 450
		var z := (i * 29) % 500 - 250
		if s.mars_kind(x, z) != MarsTerrain.PLAINS or s.pad_at(x, z):
			continue
		checked += 1
		var h := s.height_at(x, z)
		assert_eq(s.block_at(x, h - 1, z), BlockIds.MARS_DUST, "red dust on top (%d, %d)" % [x, z])
		for d in [2, 3, 4]:
			assert_eq(s.block_at(x, h - d, z), BlockIds.MARS_REGOLITH, "rusty regolith under it")
		assert_has([BlockIds.BASALT, BlockIds.MARS_SEDIMENT], s.block_at(x, h - 6, z), "rock under the regolith")
		assert_eq(s.block_at(x, -5, z), BlockIds.DEEP_BASALT)
		assert_eq(s.block_at(x, MeadowsShape.WORLD_BOTTOM, z), BlockIds.BEDROCK)
		assert_eq(s.block_at(x, h, z), BlockIds.AIR)
	assert_gt(checked, 150, "mostly wide dusty plains")


func test_the_rock_is_basalt_with_pale_layers() -> void:
	var s := _mars()
	var sp := s.spawn_column()
	var layers := 0
	var basalt := 0
	for y in range(1, 30):
		var id := s.block_at(sp.x + 40, y, sp.y + 3)
		if id == BlockIds.MARS_SEDIMENT:
			layers += 1
		elif id == BlockIds.BASALT:
			basalt += 1
	assert_gt(basalt, layers, "mostly dark basalt")
	assert_gt(layers, 4, "with pale layers (the canyon's walls show them)")


func test_the_spawn_is_calm_plains_near_the_middle() -> void:
	var s := _mars()
	var sp := s.spawn_column()
	assert_lt(Vector2(sp).length(), 400.0)
	assert_eq(s.mars_kind(sp.x, sp.y), MarsTerrain.PLAINS)
	assert_eq(s.sight_at(sp.x, sp.y), &"", "no sight right on the pad")
	assert_gt(Vector2(sp - s.mars.volcano_centre()).length(), MarsTerrain.VOLCANO_RADIUS + 40.0, "the volcano is a walk away")


# --- The giant shield volcano ---

func test_a_giant_shield_volcano_rises_far_above_the_plains() -> void:
	var s := _mars()
	var vc := s.mars.volcano_centre()
	var sp := s.spawn_column()
	var d := Vector2(vc - sp).length()
	assert_between(d, 240.0, 420.0, "a long walk from the pad (%.0f), in sight on the map" % d)
	var plains := s.height_at(sp.x, sp.y)
	var rim := 0
	for a in 16:
		var p := vc + Vector2i(roundi(cos(TAU * a / 16.0) * (MarsTerrain.CALDERA_RADIUS + 2)), roundi(sin(TAU * a / 16.0) * (MarsTerrain.CALDERA_RADIUS + 2)))
		rim = maxi(rim, s.height_at(p.x, p.y))
	assert_gt(rim - plains, 60, "far taller than anything round it (rim %d, plains %d)" % [rim, plains])
	assert_lt(rim, SpaceGenerator.SKY_TOP - 6, "within the world's height limit")
	var floor_h := s.height_at(vc.x, vc.y)
	assert_gt(rim - floor_h, 8, "a caldera sunk into its top")
	assert_eq(s.mars_kind(vc.x, vc.y), MarsTerrain.CALDERA)
	var outside := vc + Vector2i(MarsTerrain.VOLCANO_RADIUS + 12, 0)
	assert_lt(s.height_at(outside.x, outside.y), plains + 16, "its foot is on the plains")


func test_the_volcanos_slopes_are_gentle_and_climbable() -> void:
	var s := _mars()
	var vc := s.mars.volcano_centre()
	for a in 8:
		var dir := Vector2(cos(TAU * a / 8.0), sin(TAU * a / 8.0))
		var last := s.height_at(vc.x + roundi(dir.x * (MarsTerrain.VOLCANO_RADIUS + 6)), vc.y + roundi(dir.y * (MarsTerrain.VOLCANO_RADIUS + 6)))
		var rises := 0
		for r in range(MarsTerrain.VOLCANO_RADIUS + 5, 0, -1):
			var h := s.height_at(vc.x + roundi(dir.x * r), vc.y + roundi(dir.y * r))
			assert_lte(absi(h - last), MARS_JUMP, "a jump climbs every step (direction %d, radius %d)" % [a, r])
			if h > last:
				rises += 1
			last = h
		assert_gt(rises, 40, "a long gentle climb")
	var flank := vc + Vector2i(MarsTerrain.VOLCANO_RADIUS / 2, 0)
	assert_eq(s.mars_kind(flank.x, flank.y), MarsTerrain.VOLCANO)
	var top := s.height_at(flank.x, flank.y)
	assert_has([BlockIds.MARS_DUST, BlockIds.BASALT], s.block_at(flank.x, top - 1, flank.y))
	assert_eq(s.block_at(flank.x, top - 3, flank.y), BlockIds.BASALT, "a volcano of dark lava rock")
	assert_eq(s.block_at(vc.x, s.height_at(vc.x, vc.y) - 1, vc.y), BlockIds.BASALT, "the caldera's bare floor")


# --- The canyon ---

func test_a_long_canyon_runs_east_and_west() -> void:
	var s := _mars()
	var span := s.mars.canyon_span()
	assert_gt(span.y - span.x, 1600, "long (%s)" % span)
	var sp := s.spawn_column()
	assert_between(s.mars.canyon_z(sp.x) - sp.y, 60.0, 260.0, "south of the pad, a walk away")
	var found := 0
	var n := 0
	for x in range(span.x + 200, span.y - 200, 60):
		n += 1
		var cz := roundi(s.mars.canyon_z(x))
		var floor_h := s.height_at(x, cz)
		var north := s.height_at(x, cz - 70)
		var south := s.height_at(x, cz + 70)
		if floor_h <= MarsTerrain.CANYON_FLOOR + 2 and north - floor_h >= 16 and south - floor_h >= 16:
			found += 1
		assert_eq(s.mars_kind(x, cz), MarsTerrain.CANYON, "x %d" % x)
	assert_eq(found, n, "a deep floor all along (%d of %d)" % [found, n])


func test_the_canyons_walls_are_terraces_a_child_climbs() -> void:
	var s := _mars()
	for x in range(-600, 600, 97):
		var cz := roundi(s.mars.canyon_z(x))
		var last := s.height_at(x, cz)
		assert_eq(s.block_at(x, last - 1, cz), BlockIds.MARS_DUST, "dust on the canyon's floor")
		for dz in range(1, 60):
			var h := s.height_at(x, cz - dz)
			assert_lte(absi(h - last), MARS_JUMP, "up the north wall at x %d, dz %d" % [x, dz])
			last = h
		for dx in range(1, 12):
			var h2 := s.height_at(x + dx, cz - 20)
			assert_lte(absi(h2 - s.height_at(x + dx - 1, cz - 20)), MARS_JUMP, "along the wall at x %d" % (x + dx))
	var walls := 0
	var cz0 := roundi(s.mars.canyon_z(0))
	for y in range(MarsTerrain.CANYON_FLOOR, 50):
		if s.block_at(0, y, cz0 - 70) == BlockIds.MARS_SEDIMENT:
			walls += 1
	assert_gt(walls, 3, "the walls show pale layers")


# --- Dry river valleys ---

func test_dry_river_valleys_have_pale_beds_below_the_plains() -> void:
	var s := _mars()
	var beds := 0
	for i in 3000:
		var x := (i * 13) % 1000 - 500
		var z := (i * 7) % 600 - 400
		if s.mars_kind(x, z) != MarsTerrain.VALLEY or s.pad_at(x, z):
			continue
		beds += 1
		var h := s.height_at(x, z)
		assert_eq(s.block_at(x, h - 1, z), BlockIds.MARS_SEDIMENT, "a pale dry river bed")
		assert_eq(s.block_at(x, h - 2, z), BlockIds.MARS_SEDIMENT)
	assert_gt(beds, 40, "dry river valleys cross the plains")


func test_valley_sides_and_crater_rims_are_gentle() -> void:
	var s := _mars()
	var steep := 0
	var n := 0
	for i in 4000:
		var x := (i * 17) % 1200 - 600
		var z := (i * 11) % 500 - 300
		if s.mars_kind(x, z) == MarsTerrain.VOLCANO:
			continue
		n += 1
		if absi(s.height_at(x, z) - s.height_at(x + 1, z)) > MARS_JUMP:
			steep += 1
	assert_lt(float(steep) / n, 0.005, "almost never a step a jump can't climb")


func test_mars_has_craters_with_raised_rims() -> void:
	var s := _mars()
	var found := 0
	var bowls := 0
	for cz in range(-5, 5):
		for cx in range(-8, 8):
			var c := s.crater_in_cell(Vector2i(cx, cz))
			if c.is_empty():
				continue
			var at: Vector2i = c.center
			var r: float = c.radius
			if s.mars_kind(at.x, at.y) != MarsTerrain.PLAINS or Vector2(at - s.spawn_column()).length() < SpaceShape.BLEND_RADIUS + r * 1.4:
				continue
			found += 1
			assert_lt(s.crater_depth(at.x, at.y), -1.5, "a bowl (%s)" % at)
			if s.height_at(at.x, at.y) < s.height_at(at.x + roundi(r * 1.12), at.y):
				bowls += 1
	assert_gt(found, 8, "craters on the plains")
	assert_gt(float(bowls) / found, 0.75, "lower in the middle than at the rim")


# --- The polar ice caps ---

func test_the_north_pole_is_water_ice_with_dusty_layers() -> void:
	var s := _mars()
	var sp := s.spawn_column()
	var edge := s.mars.north_edge()
	assert_between(sp.y - edge, 400, 800, "far north of the pad: a trip (%d)" % (sp.y - edge))
	var ice := 0
	var layered := 0
	for x in range(-400, 400, 40):
		var z := edge - 80
		assert_eq(s.mars_kind(x, z), MarsTerrain.NORTH_CAP, "(%d, %d)" % [x, z])
		var h := s.height_at(x, z)
		if s.block_at(x, h - 1, z) == BlockIds.POLAR_ICE:
			ice += 1
		var kinds := {}
		for y in range(MarsTerrain.ICE_FLOOR, h - 1):
			kinds[s.block_at(x, y, z)] = true
		if kinds.has(BlockIds.POLAR_ICE) and kinds.has(BlockIds.MARS_DUST):
			layered += 1
		assert_gt(h, s.height_at(x, edge + 120) - 8, "a raised cap of ice")
	assert_eq(ice, 20, "white water ice on top")
	assert_gt(layered, 15, "layers of ice and dust inside")


func test_the_south_pole_is_topped_with_dry_ice() -> void:
	var s := _mars()
	var edge := s.mars.south_edge()
	assert_gt(edge - s.spawn_column().y, 500)
	for x in range(-400, 400, 40):
		var z := edge + 80
		assert_eq(s.mars_kind(x, z), MarsTerrain.SOUTH_CAP)
		var h := s.height_at(x, z)
		assert_eq(s.block_at(x, h - 1, z), BlockIds.DRY_ICE, "frozen carbon dioxide on top")
		assert_eq(s.block_at(x, h - 2, z), BlockIds.POLAR_ICE, "water ice under it")


func test_the_ice_caps_edges_can_be_walked_up() -> void:
	var s := _mars()
	for x in range(-300, 300, 50):
		var z0 := s.mars.north_edge() + 90
		var last := s.height_at(x, z0)
		for dz in range(1, 180):
			var h := s.height_at(x, z0 - dz)
			assert_lte(absi(h - last), MARS_JUMP, "onto the north cap at x %d" % x)
			last = h


func test_frost_patches_near_the_caps() -> void:
	var s := _mars()
	var frost := 0
	for i in 600:
		var x := (i * 19) % 1200 - 600
		var z := s.mars.north_edge() + 5 + (i * 7) % 50
		if s.mars_kind(x, z) == MarsTerrain.FROST_N:
			frost += 1
			assert_eq(s.block_at(x, s.height_at(x, z) - 1, z), BlockIds.POLAR_ICE)
	assert_gt(frost, 30, "white frost on the dust near the cap")


# --- Boulders and crystals ---

func test_boulders_on_the_plains_and_gypsum_crystals_in_the_river_beds() -> void:
	var s := _mars()
	var boulders := 0
	var crystals := 0
	for z in range(-300, 300):
		for x in range(-300, 300, 3):
			if not s.tree_at(x, z):
				continue
			var base := s.height_at(x, z)
			var id := s.feature_at(x, base, z)
			assert_has([BlockIds.BASALT, BlockIds.GYPSUM], id, "(%d, %d)" % [x, z])
			assert_between(s.tree_height(x, z), 1, 3)
			if id == BlockIds.GYPSUM:
				crystals += 1
				assert_has([MarsTerrain.VALLEY, MarsTerrain.CANYON], s.mars_kind(x, z), "crystals grow where water was")
			else:
				boulders += 1
			assert_eq(s.feature_at(x, base - 1, z), -1, "never in the ground")
	assert_gt(boulders, 30, "boulders of basalt")
	assert_gt(crystals, 10, "gypsum crystals in the dry river beds")


# --- Sights: the places a child learns about ---

func test_sights_are_where_the_shape_says() -> void:
	var s := _mars()
	var vc := s.mars.volcano_centre()
	assert_eq(s.sight_at(vc.x, vc.y), &"volcano", "the summit")
	var cz := roundi(s.mars.canyon_z(0))
	assert_eq(s.sight_at(0, cz), &"canyon")
	assert_eq(s.sight_at(0, s.mars.north_edge() - 60), &"north_cap")
	assert_eq(s.sight_at(0, s.mars.south_edge() + 60), &"south_cap")
	var flank := vc + Vector2i(MarsTerrain.VOLCANO_RADIUS - 30, 0)
	assert_eq(s.sight_at(flank.x, flank.y), &"", "the summit, not the foot")
	var river := Vector2i(999999, 0)
	for i in 3000:
		var x := (i * 13) % 1000 - 500
		var z := (i * 7) % 600 - 400
		if s.mars_kind(x, z) == MarsTerrain.VALLEY:
			river = Vector2i(x, z)
			break
	assert_eq(s.sight_at(river.x, river.y), &"river")
	var ids: Array = []
	for sight: Dictionary in s.sights():
		ids.append(sight.id)
		var at: Vector3 = sight.pos
		assert_eq(s.sight_at(floori(at.x), floori(at.z)), sight.id, "its map spot is on it: %s" % sight.id)
		assert_eq(int(at.y), s.height_at(floori(at.x), floori(at.z)))
	assert_eq(ids, [&"volcano", &"canyon", &"north_cap", &"south_cap", ColonyRules.DOME],
		"the big ones on the map (spec §21c: and the colony)")
	var moon := SpaceShape.new(SEED, SpaceShape.MOON)
	assert_eq(moon.sights().map(func(e: Dictionary) -> StringName: return e.id), [ColonyRules.DOME],
		"the Moon's only big sight is its colony")
	assert_eq(moon.sight_at(moon.spawn_column().x, moon.spawn_column().y), &"", "none on the landing pad")


func test_another_seed_is_another_mars() -> void:
	var a := _mars()
	var b := _mars(777)
	assert_eq(a.mars.volcano_centre(), _mars().mars.volcano_centre(), "the same seed, the same Mars")
	assert_ne(a.mars.volcano_centre(), b.mars.volcano_centre())
	var differ := 0
	for i in 20:
		if a.height_at(i * 31, i * 17) != b.height_at(i * 31, i * 17):
			differ += 1
	assert_gt(differ, 5)
