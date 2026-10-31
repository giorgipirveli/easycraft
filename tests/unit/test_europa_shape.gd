extends GutTest
## Cosmos: Europa (world 20, spec §21b.2): its terrain as pure rules (SpaceShape with planet EUROPA; the regions in
## EuropaTerrain). A smooth white crust of ice (one of the smoothest surfaces in the solar system) over blue deep ice in
## layers and the rocky seafloor under y 0; long reddish cracks (lineae) with a trough and a stained ridge on each side;
## the ice cliffs (a plateau with two cliffs and a terrace); water plumes (geyser vents in mounds of salt); the ocean under
## the ice: a deep round well through the crust, a ramp winding down its wall to dark water at the bottom, the water
## reaching on under the ice, glowing rings of ice on the walls. Ice blades (penitentes) and salt crystals. Every step a
## child meets is one a Europa jump climbs.

const SEED := 12345


func _europa(seed: int = SEED) -> SpaceShape:
	return SpaceShape.new(seed, SpaceShape.EUROPA)


func test_europa_is_a_space_planet_with_its_terrain() -> void:
	assert_has(SpaceShape.PLANETS, SpaceShape.EUROPA)
	var s := _europa()
	assert_eq(s.planet, SpaceShape.EUROPA)
	assert_not_null(s.europa, "Europa's regions")
	assert_null(SpaceShape.new(SEED, SpaceShape.MARS).europa, "Mars has none")
	assert_null(s.mars)
	assert_lt(EuropaTerrain.MAX_STEP, 13, "a jump at 0.13 gravity reaches ~13 blocks")


func test_heights_stay_between_the_floor_and_the_sky_outside_the_well() -> void:
	var s := _europa()
	var mc := s.europa.mesa_centre()
	var points: Array[Vector2i] = [mc, mc + Vector2i(20, 0)]
	for i in 900:
		points.append(Vector2i((i * 37) % 2400 - 1200, (i * 91) % 2400 - 1200))
	for p in points:
		if s.europa.in_well(p.x, p.y):
			continue
		var h := s.height_at(p.x, p.y)
		assert_gte(h, SpaceShape.MIN_GROUND, "(%d, %d): never under the floor" % [p.x, p.y])
		assert_lt(h, SpaceGenerator.SKY_TOP - 40, "(%d, %d): far under the sky's limit" % [p.x, p.y])
		assert_false(s.is_river(p.x, p.y), "no rivers on Europa's ice")


func test_the_crust_is_white_ice_over_layered_deep_ice_over_seafloor_rock() -> void:
	var s := _europa()
	var checked := 0
	for i in 400:
		var x := (i * 53) % 900 - 450
		var z := (i * 29) % 900 - 450
		if s.europa_kind(x, z) != EuropaTerrain.PLAINS or s.pad_at(x, z) or s.tree_at(x, z):
			continue
		checked += 1
		var h := s.height_at(x, z)
		assert_eq(s.block_at(x, h - 1, z), BlockIds.EUROPA_ICE, "white ice on top (%d, %d)" % [x, z])
		assert_eq(s.block_at(x, h - 2, z), BlockIds.EUROPA_ICE)
		assert_has([BlockIds.DEEP_ICE, BlockIds.EUROPA_ICE], s.block_at(x, h - 8, z), "deep ice under it")
		assert_eq(s.block_at(x, -5, z), BlockIds.EUROPA_ROCK, "the rocky seafloor under the ice")
		assert_eq(s.block_at(x, MeadowsShape.WORLD_BOTTOM, z), BlockIds.BEDROCK)
		assert_eq(s.block_at(x, h, z), BlockIds.AIR)
	assert_gt(checked, 150, "mostly smooth white plains")
	var deep := 0
	var bands := 0
	for y in range(1, 40):
		var id := s.block_at(300, y, 300) if s.europa_kind(300, 300) != EuropaTerrain.WELL else BlockIds.AIR
		if id == BlockIds.DEEP_ICE:
			deep += 1
		elif id == BlockIds.EUROPA_ICE:
			bands += 1
	assert_gt(deep, bands, "mostly blue deep ice ...")
	assert_gt(bands, 3, "... in layers with white bands")


func test_the_crust_is_smooth() -> void:
	var s := _europa()
	var flat := 0
	var n := 0
	for i in 3000:
		var x := (i * 17) % 1200 - 600
		var z := (i * 11) % 1200 - 600
		if s.europa_kind(x, z) != EuropaTerrain.PLAINS or s.europa_kind(x + 1, z) != EuropaTerrain.PLAINS:
			continue
		n += 1
		var d := absi(s.height_at(x, z) - s.height_at(x + 1, z))
		assert_lte(d, 1, "the plains rise and fall one block at a time")
		if d == 0:
			flat += 1
	assert_gt(n, 1000)
	assert_gt(float(flat) / n, 0.93, "one of the smoothest surfaces in the solar system")


func test_every_step_is_one_europa_jump() -> void:
	var s := _europa()
	for i in 6000:
		var x := (i * 13) % 1400 - 700
		var z := (i * 7) % 1400 - 700
		if s.europa.in_well(x, z) or s.europa.in_well(x + 1, z) or s.europa.in_well(x, z + 1):
			continue
		assert_lte(absi(s.height_at(x, z) - s.height_at(x + 1, z)), EuropaTerrain.MAX_STEP, "(%d, %d)" % [x, z])
		assert_lte(absi(s.height_at(x, z) - s.height_at(x, z + 1)), EuropaTerrain.MAX_STEP, "(%d, %d)" % [x, z])


# --- The lineae: long reddish cracks ---

func test_long_reddish_cracks_with_a_ridge_on_each_side() -> void:
	var s := _europa()
	var troughs := 0
	var ridges := 0
	for i in 5000:
		var x := (i * 19) % 1000 - 500
		var z := (i * 23) % 1000 - 500
		var kind := s.europa_kind(x, z)
		var h := s.height_at(x, z)
		if kind == EuropaTerrain.LINEA and not s.pad_at(x, z):
			troughs += 1
			assert_eq(s.block_at(x, h - 1, z), BlockIds.LINEA_ICE, "reddish ice in the crack (%d, %d)" % [x, z])
		elif kind == EuropaTerrain.RIDGE:
			ridges += 1
			assert_eq(s.block_at(x, h - 1, z), BlockIds.BAND_ICE, "stained ice on its ridges")
	assert_gt(troughs, 40, "cracks cross the ice")
	assert_gt(ridges, troughs, "a ridge on each side")


func test_a_crack_is_long() -> void:
	var s := _europa()
	var start := Vector2i(999999, 0)
	for i in 5000:
		var x := (i * 19) % 1000 - 500
		var z := (i * 23) % 1000 - 500
		if s.europa_kind(x, z) == EuropaTerrain.LINEA:
			start = Vector2i(x, z)
			break
	assert_ne(start.x, 999999, "a crack to follow")
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	var lo := start
	var hi := start
	while not queue.is_empty() and seen.size() < 3000:
		var p: Vector2i = queue.pop_front()
		lo = lo.min(p)
		hi = hi.max(p)
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q := p + d
			if not seen.has(q) and s.europa_kind(q.x, q.y) == EuropaTerrain.LINEA:
				seen[q] = true
				queue.append(q)
	assert_gt(Vector2(hi - lo).length(), 120.0, "a long line across the ice (%s .. %s)" % [lo, hi])


func test_the_ridges_stand_above_the_crack() -> void:
	var s := _europa()
	var higher := 0
	var n := 0
	for i in 5000:
		var x := (i * 19) % 1000 - 500
		var z := (i * 23) % 1000 - 500
		if s.europa_kind(x, z) != EuropaTerrain.RIDGE:
			continue
		n += 1
		if s.height_at(x, z) > s.europa.plains_height(x, z):
			higher += 1
	assert_gt(n, 40)
	assert_gt(float(higher) / n, 0.5, "double ridges: raised on both sides of the crack")


# --- The ice cliffs ---

func test_the_ice_cliffs_rise_in_two_cliffs_to_a_plateau() -> void:
	var s := _europa()
	var mc := s.europa.mesa_centre()
	var sp := s.spawn_column()
	var d := Vector2(mc - sp).length()
	assert_between(d, 120.0, 330.0, "a walk from the pad (%.0f)" % d)
	assert_eq(s.europa_kind(mc.x, mc.y), EuropaTerrain.CLIFF_TOP)
	var top := s.height_at(mc.x, mc.y)
	assert_eq(top - s.europa.plains_height(mc.x, mc.y), EuropaTerrain.CLIFF * 2, "two cliffs up")
	for a in 12:
		var dir := Vector2(cos(TAU * a / 12.0), sin(TAU * a / 12.0))
		var last := s.height_at(mc.x, mc.y)
		var cliffs := 0
		for r in range(1, 110):
			var p := mc + Vector2i(roundi(dir.x * r), roundi(dir.y * r))
			var h := s.height_at(p.x, p.y)
			if last - h >= EuropaTerrain.CLIFF - 1:
				cliffs += 1
			assert_lte(absi(h - last), EuropaTerrain.MAX_STEP, "a jump climbs every cliff (direction %d, r %d)" % [a, r])
			last = h
		assert_eq(cliffs, 2, "two cliffs and a terrace between them (direction %d)" % a)


func test_the_cliffs_faces_show_layers_of_blue_and_white_ice() -> void:
	var s := _europa()
	var mc := s.europa.mesa_centre()
	var kinds := {}
	for y in range(s.europa.plains_height(mc.x, mc.y), s.height_at(mc.x, mc.y) - 2):
		kinds[s.block_at(mc.x, y, mc.y)] = true
	assert_true(kinds.has(BlockIds.DEEP_ICE) and kinds.has(BlockIds.EUROPA_ICE), "layered ice (%s)" % [kinds.keys()])


# --- The ocean under the ice ---

func test_a_deep_well_opens_through_the_ice_down_to_the_ocean() -> void:
	var s := _europa()
	var wc := s.europa.well_centre()
	var sp := s.spawn_column()
	assert_gt(Vector2(wc - sp).length(), 110.0, "a walk from the pad")
	assert_lt(Vector2(wc - sp).length(), 330.0)
	var top := s.europa.well_top()
	assert_gt(top - EuropaTerrain.OCEAN_TOP, 36, "deep: through the thick ice")
	for y in range(EuropaTerrain.OCEAN_TOP, top + 4):
		assert_eq(s.block_at(wc.x, y, wc.y), BlockIds.AIR, "open to the sky: bright all the way down (y %d)" % y)
	for y in range(EuropaTerrain.SEAFLOOR, EuropaTerrain.OCEAN_TOP):
		assert_eq(s.block_at(wc.x, y, wc.y), BlockIds.WATER, "the ocean at the bottom (y %d)" % y)
	assert_eq(s.block_at(wc.x, EuropaTerrain.SEAFLOOR - 1, wc.y), BlockIds.EUROPA_ROCK, "the rocky seafloor under it")
	assert_eq(s.height_at(wc.x, wc.y), EuropaTerrain.SEAFLOOR, "the ground there is the seafloor")
	assert_eq(s.europa_kind(wc.x, wc.y), EuropaTerrain.WELL)
	for r: int in [16, 20]:
		assert_eq(s.height_at(wc.x + r, wc.y), top, "a flat rim round it")
		assert_eq(s.height_at(wc.x, wc.y - r), top)


func test_the_water_reaches_on_under_the_ice() -> void:
	var s := _europa()
	var wc := s.europa.well_centre()
	var r := EuropaTerrain.WELL_R + 2
	for p: Vector2i in [Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r)]:
		var c := wc + p
		assert_eq(s.block_at(c.x, EuropaTerrain.OCEAN_TOP - 1, c.y), BlockIds.WATER, "water under the ice at %s" % p)
		assert_true(BlockIds.is_solid(s.block_at(c.x, EuropaTerrain.OCEAN_TOP, c.y)), "the ice over it at %s" % p)


func test_a_ramp_winds_down_the_wall_to_the_water() -> void:
	var s := _europa()
	var wc := s.europa.well_centre()
	var top := s.europa.well_top()
	var a0 := s.europa.ramp_start()
	var last := -1
	var first := -1
	var ups := 0
	var r := (EuropaTerrain.RAMP_IN + EuropaTerrain.WELL_R) / 2.0 + 0.5
	for k in range(8, 712):   # clear of the seam where the ramp's top meets the shelf
		var a := a0 + TAU * (k + 0.5) / 720.0
		var c := wc + Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))
		var h := s.height_at(c.x, c.y)
		if first < 0:
			first = h
		elif h != last:
			assert_lte(absi(h - last), 2, "a gentle ramp (step %d: %d -> %d)" % [k, last, h])
			if h > last:
				ups += 1
		assert_eq(s.block_at(c.x, h, c.y), BlockIds.AIR, "open above the ramp")
		last = h
	assert_lt(ups, 6, "down all the way round (a column's corner aside)")
	assert_gte(first, top - 2, "it starts at the rim")
	assert_eq(last, EuropaTerrain.OCEAN_TOP + 1, "and ends on a shelf just over the water")
	var c2 := wc + Vector2i(roundi(cos(a0 - 0.2) * r), roundi(sin(a0 - 0.2) * r))
	assert_eq(s.block_at(c2.x, EuropaTerrain.OCEAN_TOP - 1, c2.y), BlockIds.WATER, "the ocean under the shelf")


func test_glowing_rings_light_the_well() -> void:
	var s := _europa()
	var wc := s.europa.well_centre()
	var glow := 0
	for y in range(EuropaTerrain.OCEAN_TOP, s.europa.well_top()):
		for p: Vector2i in [Vector2i(EuropaTerrain.WELL_R + 1, 0), Vector2i(0, -EuropaTerrain.WELL_R - 1)]:
			if s.block_at(wc.x + p.x, y, wc.y + p.y) == BlockIds.GLOW_ICE:
				glow += 1
	assert_gt(glow, 8, "rings of glowing ice on the wall, never dark and scary")


# --- Water plumes ---

func test_geyser_vents_sit_in_mounds_of_salt() -> void:
	var s := _europa()
	var vents := s.europa.vents_near(0, 0, 700)
	assert_gt(vents.size(), 8, "water plumes across the ice")
	for v: Vector2i in vents:
		assert_eq(s.europa_kind(v.x, v.y), EuropaTerrain.VENT)
		var base := s.height_at(v.x, v.y)
		assert_eq(s.block_at(v.x, base - 1, v.y), BlockIds.GEYSER_VENT, "the vent at the bottom of its hole")
		var rim := v + Vector2i(2, 0)
		assert_eq(s.europa_kind(rim.x, rim.y), EuropaTerrain.MOUND)
		assert_gt(s.height_at(rim.x, rim.y), base, "a mound round the hole")
		assert_eq(s.block_at(rim.x, s.height_at(rim.x, rim.y) - 1, rim.y), BlockIds.SALT, "crusted with salt")
		assert_false(s.europa.in_well(v.x, v.y))
		assert_gt(Vector2(v - s.spawn_column()).length(), 60.0, "never on the landing pad")
	var sp := s.spawn_column()
	var near := s.europa.nearest_vent(sp)
	assert_true(vents.has(near), "the nearest to the pad goes on MY MAP")
	assert_lt(Vector2(near - sp).length(), 320.0)


# --- Ice blades and salt crystals ---

func test_ice_blades_on_the_plains_and_salt_crystals_in_the_cracks() -> void:
	var s := _europa()
	var blades := 0
	var salt := 0
	for z in range(-300, 300):
		for x in range(-300, 300, 3):
			if not s.tree_at(x, z):
				continue
			var base := s.height_at(x, z)
			var id := s.feature_at(x, base, z)
			assert_has([BlockIds.EUROPA_ICE, BlockIds.SALT], id, "(%d, %d)" % [x, z])
			assert_eq(s.feature_at(x, base - 1, z), -1, "never in the ground")
			if id == BlockIds.SALT:
				salt += 1
				assert_has([EuropaTerrain.LINEA, EuropaTerrain.RIDGE], s.europa_kind(x, z), "salt where the cracks are")
				assert_between(s.tree_height(x, z), 1, 2)
			else:
				blades += 1
				assert_has([EuropaTerrain.PLAINS, EuropaTerrain.CLIFF_TOP], s.europa_kind(x, z))
				assert_between(s.tree_height(x, z), 2, 4)
	assert_gt(blades, 30, "fields of ice blades (penitentes)")
	assert_gt(salt, 10, "salt crystals in the cracks")


# --- The landing pad and the sights ---

func test_the_spawn_is_calm_plains_near_the_middle() -> void:
	var s := _europa()
	var sp := s.spawn_column()
	assert_lt(Vector2(sp).length(), 400.0)
	assert_eq(s.europa_kind(sp.x, sp.y), EuropaTerrain.PLAINS)
	assert_eq(s.sight_at(sp.x, sp.y), &"")
	assert_gt(Vector2(sp - s.europa.well_centre()).length(), 110.0)


func test_sights_are_where_the_shape_says() -> void:
	var s := _europa()
	var wc := s.europa.well_centre()
	assert_eq(s.sight_at(wc.x, wc.y), &"ocean", "the water at the bottom of the well")
	assert_eq(s.sight_at(wc.x + EuropaTerrain.WELL_R + 2, wc.y), &"", "not on the ice round it")
	var mc := s.europa.mesa_centre()
	assert_eq(s.sight_at(mc.x, mc.y), &"cliffs", "on top of the cliffs")
	var v := s.europa.nearest_vent(s.spawn_column())
	assert_eq(s.sight_at(v.x, v.y), &"plume")
	assert_eq(s.sight_at(v.x + 2, v.y), &"plume", "on its mound too")
	var crack := Vector2i(999999, 0)
	for i in 5000:
		var x := (i * 19) % 1000 - 500
		var z := (i * 23) % 1000 - 500
		if s.europa_kind(x, z) == EuropaTerrain.LINEA:
			crack = Vector2i(x, z)
			break
	assert_eq(s.sight_at(crack.x, crack.y), &"linea")
	var ids: Array = []
	for sight: Dictionary in s.sights():
		ids.append(sight.id)
		var at: Vector3 = sight.pos
		assert_eq(s.sight_at(floori(at.x), floori(at.z)), sight.id, "its map spot is on it: %s" % sight.id)
		assert_eq(int(at.y), s.height_at(floori(at.x), floori(at.z)))
	assert_eq(ids, [&"ocean", &"cliffs", &"plume"], "the big ones on the map")


func test_another_seed_is_another_europa() -> void:
	var a := _europa()
	var b := _europa(777)
	assert_eq(a.europa.well_centre(), _europa().europa.well_centre(), "the same seed, the same Europa")
	assert_ne(a.europa.well_centre(), b.europa.well_centre())
	assert_ne(a.europa.mesa_centre(), b.europa.mesa_centre())
	var differ := 0
	for i in 40:
		if a.europa_kind(i * 31, i * 17) != b.europa_kind(i * 31, i * 17) or a.height_at(i * 31, i * 17) != b.height_at(i * 31, i * 17):
			differ += 1
	assert_gt(differ, 5)
