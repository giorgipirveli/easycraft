extends GutTest
## Cosmos: Io (world 21, spec §21b.2): its terrain as pure rules (SpaceShape with planet IO; the regions in IoTerrain).
## Plains of yellow sulphur with orange patches and white frost (frozen sulphur dioxide) over Io's rock (layers of black
## lava in it); volcanoes: low cones of black lava rock with a vent in their crater, ringed with red sulphur; small lava
## lakes (black crust with glowing cracks); the big lava lake: a crust you can walk on, a narrow moat of bright hot lava
## round it inside a rim of black lava rock (a fence), causeways across the moat; a big mountain, a tilted block of
## crust with a gentle side and a steep side. Sulphur crystals and lava boulders. Every step a child meets is one an Io
## jump climbs, and hot lava is only ever a narrow band a bounce leaves.

const SEED := 12345


func _io(seed: int = SEED) -> SpaceShape:
	return SpaceShape.new(seed, SpaceShape.IO)


func _jump() -> float:
	return Player.JUMP_VELOCITY * Player.JUMP_VELOCITY / (2.0 * Player.GRAVITY * 0.18)


func test_io_is_a_space_planet_with_its_terrain() -> void:
	assert_has(SpaceShape.PLANETS, SpaceShape.IO)
	var s := _io()
	assert_eq(s.planet, SpaceShape.IO)
	assert_not_null(s.io, "Io's regions")
	assert_null(s.europa)
	assert_null(s.mars)
	assert_null(SpaceShape.new(SEED, SpaceShape.EUROPA).io, "Europa has none")
	assert_lt(float(IoTerrain.MAX_STEP), _jump() - 0.5, "a jump at 0.18 gravity reaches ~9 blocks")


func test_heights_stay_between_the_floor_and_the_sky() -> void:
	var s := _io()
	var points: Array[Vector2i] = [s.io.lake_centre(), s.io.peak_centre(), s.io.mountain_centre()]
	for i in 900:
		points.append(Vector2i((i * 37) % 2400 - 1200, (i * 91) % 2400 - 1200))
	for p in points:
		var h := s.height_at(p.x, p.y)
		assert_gt(h, MeadowsShape.SEA_LEVEL + 2, "(%d, %d): dry" % [p.x, p.y])
		assert_lt(h, SpaceGenerator.SKY_TOP - 40, "(%d, %d): far under the sky's limit" % [p.x, p.y])
		assert_false(s.is_river(p.x, p.y), "no rivers on Io: it has no water to speak of")


func test_sulphur_plains_over_layered_rock() -> void:
	var s := _io()
	var checked := 0
	for i in 400:
		var x := (i * 53) % 900 - 450
		var z := (i * 29) % 900 - 450
		if s.io_kind(x, z) != IoTerrain.PLAINS or s.pad_at(x, z) or s.tree_at(x, z):
			continue
		checked += 1
		var h := s.height_at(x, z)
		assert_eq(s.block_at(x, h - 1, z), BlockIds.SULPHUR, "yellow sulphur on top (%d, %d)" % [x, z])
		assert_eq(s.block_at(x, h - 2, z), BlockIds.SULPHUR, "a blanket of sulphur")
		assert_has([BlockIds.IO_ROCK, BlockIds.BLACK_LAVA], s.block_at(x, h - 8, z), "rock under it")
		assert_eq(s.block_at(x, -5, z), BlockIds.IO_ROCK, "Io's rock deep down")
		assert_eq(s.block_at(x, MeadowsShape.WORLD_BOTTOM, z), BlockIds.BEDROCK)
		assert_eq(s.block_at(x, h, z), BlockIds.AIR)
	assert_gt(checked, 120, "mostly yellow plains")
	var rock := 0
	var lava := 0
	for y in range(1, 40):
		var id := s.block_at(300, y, 300)
		if id == BlockIds.IO_ROCK:
			rock += 1
		elif id == BlockIds.BLACK_LAVA:
			lava += 1
	assert_gt(rock, lava, "mostly Io's rock ...")
	assert_gt(lava, 3, "... with layers of old black lava in it")


func test_orange_patches_and_white_frost_on_the_plains() -> void:
	var s := _io()
	var kinds := {}
	var n := 0
	for i in 4000:
		var x := (i * 17) % 1400 - 700
		var z := (i * 11) % 1400 - 700
		var k := s.io_kind(x, z)
		kinds[k] = int(kinds.get(k, 0)) + 1
		n += 1
		var h := s.height_at(x, z)
		if s.pad_at(x, z):
			continue
		if k == IoTerrain.ORANGE:
			assert_eq(s.block_at(x, h - 1, z), BlockIds.ORANGE_SULPHUR)
		elif k == IoTerrain.FROST:
			assert_eq(s.block_at(x, h - 1, z), BlockIds.SULPHUR_FROST)
			assert_eq(s.block_at(x, h - 2, z), BlockIds.SULPHUR, "a coat of frost over sulphur")
	assert_gt(float(kinds.get(IoTerrain.PLAINS, 0)) / n, 0.45, "mostly yellow")
	assert_gt(float(kinds.get(IoTerrain.ORANGE, 0)) / n, 0.06, "orange patches")
	assert_gt(float(kinds.get(IoTerrain.FROST, 0)) / n, 0.04, "white frost")


func test_every_step_is_one_io_jump() -> void:
	var s := _io()
	var pts: Array[Vector2i] = []
	for i in 6000:
		pts.append(Vector2i((i * 13) % 1400 - 700, (i * 7) % 1400 - 700))
	for c: Vector2i in [s.io.lake_centre(), s.io.mountain_centre()]:
		for dz in range(-70, 71, 3):
			for dx in range(-70, 71):
				pts.append(c + Vector2i(dx, dz))
	for p in pts:
		assert_lte(absi(s.height_at(p.x, p.y) - s.height_at(p.x + 1, p.y)), IoTerrain.MAX_STEP, "(%d, %d)" % [p.x, p.y])
		assert_lte(absi(s.height_at(p.x, p.y) - s.height_at(p.x, p.y + 1)), IoTerrain.MAX_STEP, "(%d, %d)" % [p.x, p.y])


# --- The big lava lake ---

func test_the_lava_lake_is_a_crust_to_walk_on_with_hot_lava_under_it() -> void:
	var s := _io()
	var lc := s.io.lake_centre()
	var sp := s.spawn_column()
	var d := Vector2(lc - sp).length()
	assert_between(d, 110.0, 330.0, "a walk from the pad (%.0f)" % d)
	var top := s.io.lake_top()
	assert_eq(s.io_kind(lc.x, lc.y), IoTerrain.LAKE)
	var g := s.height_at(lc.x, lc.y)
	assert_eq(g, top - IoTerrain.LAKE_DOWN, "the crust lies in a hollow")
	assert_eq(s.block_at(lc.x, g - 1, lc.y), BlockIds.LAVA_CRUST, "black crust with glowing cracks")
	assert_eq(s.block_at(lc.x, g - 2, lc.y), BlockIds.HOT_LAVA, "hot lava under the crust")
	assert_true(BlockIds.is_solid(BlockIds.LAVA_CRUST), "safe to walk on")
	for r in range(0, IoTerrain.LAKE_R - IoTerrain.MOAT_W, 3):
		for a in 8:
			var p := lc + Vector2i(roundi(cos(TAU * a / 8.0) * r), roundi(sin(TAU * a / 8.0) * r))
			if s.io_kind(p.x, p.y) == IoTerrain.LAKE:
				assert_eq(s.height_at(p.x, p.y), g, "a flat crust")


func test_a_narrow_moat_of_hot_lava_fenced_by_a_rim() -> void:
	var s := _io()
	var lc := s.io.lake_centre()
	var top := s.io.lake_top()
	var moat := 0
	for a in 360:
		var dir := Vector2.from_angle(TAU * a / 360.0)
		var p := lc + Vector2i(roundi(dir.x * (IoTerrain.LAKE_R - 1)), roundi(dir.y * (IoTerrain.LAKE_R - 1)))
		var k := s.io_kind(p.x, p.y)
		if k != IoTerrain.MOAT:
			continue
		moat += 1
		var g := s.height_at(p.x, p.y)
		assert_eq(s.block_at(p.x, g - 1, p.y), BlockIds.HOT_LAVA, "bright hot lava")
		assert_eq(g, top - IoTerrain.LAKE_DOWN - 1, "a step under the crust")
		var rim := lc + Vector2i(roundi(dir.x * (IoTerrain.LAKE_R + 1)), roundi(dir.y * (IoTerrain.LAKE_R + 1)))
		assert_eq(s.height_at(rim.x, rim.y) - g, IoTerrain.MOAT_DEPTH, "the rim stands over it")
		assert_eq(s.block_at(rim.x, s.height_at(rim.x, rim.y) - 1, rim.y), BlockIds.BLACK_LAVA, "a rim of black lava rock")
	assert_gt(moat, 250, "the moat goes nearly all the way round")
	for z in range(lc.y - 40, lc.y + 41):
		for x in range(lc.x - 40, lc.x + 41):
			if s.io_kind(x, z) != IoTerrain.MOAT:
				continue
			var near := false
			for dz in range(-IoTerrain.MOAT_W, IoTerrain.MOAT_W + 1):
				for dx in range(-IoTerrain.MOAT_W, IoTerrain.MOAT_W + 1):
					if s.io_kind(x + dx, z + dz) != IoTerrain.MOAT:
						near = true
			assert_true(near, "never more than %d blocks of hot lava to cross (%d, %d)" % [IoTerrain.MOAT_W, x, z])


func test_causeways_cross_the_moat_from_the_rim_down_to_the_crust() -> void:
	var s := _io()
	var lc := s.io.lake_centre()
	var crust := s.io.lake_top() - IoTerrain.LAKE_DOWN
	var ways := 0
	for k in IoTerrain.CAUSEWAYS:
		var dir := Vector2.from_angle(s.io.causeway_angle(k))
		var last := -1
		var ok := true
		for r in range(IoTerrain.LAKE_R + IoTerrain.RIM_W + 2, IoTerrain.LAKE_R - IoTerrain.MOAT_W - 3, -1):
			var p := lc + Vector2i(roundi(dir.x * r), roundi(dir.y * r))
			var h := s.height_at(p.x, p.y)
			if s.block_at(p.x, h - 1, p.y) == BlockIds.HOT_LAVA:
				ok = false
			if last >= 0 and absi(h - last) > 2:
				ok = false
			last = h
		assert_true(ok, "causeway %d: small steps down, no hot lava" % k)
		assert_eq(last, crust, "causeway %d ends on the crust" % k)
		if ok:
			ways += 1
	assert_eq(ways, IoTerrain.CAUSEWAYS)
	var cells := 0
	for z in range(lc.y - 32, lc.y + 33):   # step by step (a child walks cell to cell): one block at a time
		for x in range(lc.x - 32, lc.x + 33):
			if s.io_kind(x, z) != IoTerrain.SHORE or Vector2(x - lc.x, z - lc.y).length() >= IoTerrain.LAKE_R:
				continue
			cells += 1
			for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				if s.io_kind(x + d.x, z + d.y) in [IoTerrain.SHORE, IoTerrain.LAKE]:
					assert_lte(absi(s.height_at(x, z) - s.height_at(x + d.x, z + d.y)), 1, "(%d, %d)" % [x, z])
	assert_gt(cells, 4 * IoTerrain.MOAT_W * 3, "causeway cells across the moat")


func test_hot_lava_is_only_in_the_lakes_moat() -> void:
	var s := _io()
	var lc := s.io.lake_centre()
	var pts: Array[Vector2i] = []
	for i in 20000:
		pts.append(Vector2i((i * 29) % 1600 - 800, (i * 47) % 1600 - 800))
	for z in range(lc.y - 60, lc.y + 61, 2):
		for x in range(lc.x - 60, lc.x + 61):
			pts.append(Vector2i(x, z))
	var hot := 0
	for p in pts:
		var h := s.height_at(p.x, p.y)
		if s.block_at(p.x, h - 1, p.y) == BlockIds.HOT_LAVA:
			hot += 1
			assert_eq(s.io_kind(p.x, p.y), IoTerrain.MOAT, "(%d, %d)" % [p.x, p.y])
	assert_gt(hot, 100, "the moat is there")


# --- Small lava lakes, volcanoes, the mountain ---

func test_small_lava_lakes_with_black_shores() -> void:
	var s := _io()
	var found := 0
	for i in 20000:
		var x := (i * 29) % 1600 - 800
		var z := (i * 47) % 1600 - 800
		if s.io_kind(x, z) != IoTerrain.PATERA:
			continue
		found += 1
		var h := s.height_at(x, z)
		assert_eq(s.block_at(x, h - 1, z), BlockIds.LAVA_CRUST, "a black crust that glows")
		assert_lt(h, s.io.plains_height(x, z), "in a hollow")
	assert_gt(found, 30, "little lava lakes here and there")


func test_volcanoes_are_cones_with_a_vent_ringed_by_red_sulphur() -> void:
	var s := _io()
	var vents := s.io.vents_near(0, 0, 700)
	assert_gt(vents.size(), 6, "volcanoes across Io")
	var sp := s.spawn_column()
	for v: Vector2i in vents:
		assert_eq(s.io_kind(v.x, v.y), IoTerrain.VENT)
		var base := s.height_at(v.x, v.y)
		assert_eq(s.block_at(v.x, base - 1, v.y), BlockIds.VOLCANO_VENT, "the vent at the bottom of its crater")
		var rim := v + Vector2i(2, 0)
		assert_eq(s.io_kind(rim.x, rim.y), IoTerrain.CONE)
		assert_gt(s.height_at(rim.x, rim.y), base, "a crater round the vent")
		assert_eq(s.block_at(rim.x, s.height_at(rim.x, rim.y) - 1, rim.y), BlockIds.BLACK_LAVA, "a cone of black lava")
		var ring := v + Vector2i(roundi((IoTerrain.RING_IN + IoTerrain.RING_OUT) / 2.0), 0)
		assert_eq(s.io_kind(ring.x, ring.y), IoTerrain.RED_RING)
		assert_eq(s.block_at(ring.x, s.height_at(ring.x, ring.y) - 1, ring.y), BlockIds.RED_SULPHUR, "a ring of red sulphur")
		assert_gt(Vector2(v - sp).length(), 60.0, "never on the landing pad")
	var near := s.io.nearest_vent(sp)
	assert_true(vents.has(near), "the nearest to the pad goes on MY MAP")
	assert_lt(Vector2(near - sp).length(), 330.0)


func test_the_mountain_has_a_gentle_side_a_steep_side_and_a_frosty_top() -> void:
	var s := _io()
	var mc := s.io.mountain_centre()
	var pk := s.io.peak_centre()
	var sp := s.spawn_column()
	assert_between(Vector2(mc - sp).length(), 120.0, 360.0, "a walk from the pad")
	assert_eq(s.io_kind(pk.x, pk.y), IoTerrain.PEAK)
	var top := s.height_at(pk.x, pk.y)
	assert_gte(top - s.io.plains_height(pk.x, pk.y), IoTerrain.PEAK_H - 1, "a big mountain")
	assert_eq(s.block_at(pk.x, top - 1, pk.y), BlockIds.SULPHUR_FROST, "white frost on its top")
	var up := s.io.mountain_up()   # from the gentle side to the steep side
	var biggest_gentle := 0
	var biggest_steep := 0
	var last := s.height_at(pk.x, pk.y)
	for r in range(1, 80):   # down the gentle side
		var p := pk - Vector2i(roundi(up.x * r), roundi(up.y * r))
		var h := s.height_at(p.x, p.y)
		biggest_gentle = maxi(biggest_gentle, absi(h - last))
		last = h
	last = s.height_at(pk.x, pk.y)
	for r in range(1, 60):   # down the steep side
		var p := pk + Vector2i(roundi(up.x * r), roundi(up.y * r))
		var h := s.height_at(p.x, p.y)
		biggest_steep = maxi(biggest_steep, absi(h - last))
		last = h
	assert_lte(biggest_gentle, 2, "a gentle side to walk up")
	assert_gte(biggest_steep, 3, "a steep side to jump up")
	var kinds := {}
	var face := pk + Vector2i(roundi(up.x * 12), roundi(up.y * 12))
	for y in range(s.io.plains_height(face.x, face.y), s.height_at(face.x, face.y) - 1):
		kinds[s.block_at(face.x, y, face.y)] = true
	assert_true(kinds.has(BlockIds.IO_ROCK) and kinds.has(BlockIds.BLACK_LAVA), "layers in its rock (%s)" % [kinds.keys()])


# --- Features, the landing pad and the sights ---

func test_sulphur_crystals_and_lava_boulders_on_the_plains() -> void:
	var s := _io()
	var crystals := 0
	var boulders := 0
	for z in range(-300, 300):
		for x in range(-300, 300, 3):
			if not s.tree_at(x, z):
				continue
			var base := s.height_at(x, z)
			var id := s.feature_at(x, base, z)
			assert_has([BlockIds.SULPHUR_CRYSTAL, BlockIds.BLACK_LAVA], id, "(%d, %d)" % [x, z])
			assert_eq(s.feature_at(x, base - 1, z), -1, "never in the ground")
			assert_has([IoTerrain.PLAINS, IoTerrain.ORANGE, IoTerrain.FROST, IoTerrain.RED_RING], s.io_kind(x, z))
			if id == BlockIds.SULPHUR_CRYSTAL:
				crystals += 1
				assert_between(s.tree_height(x, z), 1, 3)
			else:
				boulders += 1
				assert_between(s.tree_height(x, z), 1, 2)
	assert_gt(crystals, 30, "sulphur crystals")
	assert_gt(boulders, 10, "lava boulders")


func test_the_spawn_is_calm_plains_near_the_middle() -> void:
	var s := _io()
	var sp := s.spawn_column()
	assert_lt(Vector2(sp).length(), 400.0)
	assert_has([IoTerrain.PLAINS, IoTerrain.ORANGE, IoTerrain.FROST], s.io_kind(sp.x, sp.y))
	assert_eq(s.sight_at(sp.x, sp.y), &"")
	assert_gt(Vector2(sp - s.io.lake_centre()).length(), 110.0)
	assert_true(s.io.vents_near(sp.x, sp.y, 60.0).is_empty(), "no volcano by the pad")
	assert_false(s.io.patera_near(sp.x, sp.y, 60.0), "no lava lake by the pad or the Volcano Lander")


func test_sights_are_where_the_shape_says() -> void:
	var s := _io()
	var lc := s.io.lake_centre()
	assert_eq(s.sight_at(lc.x, lc.y), &"lake", "on the lava lake's crust")
	var rim := lc + Vector2i(IoTerrain.LAKE_R + 1, 0)
	assert_eq(s.sight_at(rim.x, rim.y), &"lake", "on its rim too: the fact before the moat")
	var pk := s.io.peak_centre()
	assert_eq(s.sight_at(pk.x, pk.y), &"mountain")
	var v := s.io.nearest_vent(s.spawn_column())
	assert_eq(s.sight_at(v.x, v.y), &"plume")
	assert_eq(s.sight_at(v.x + 3, v.y), &"plume", "on its cone too")
	var ring := v + Vector2i(roundi((IoTerrain.RING_IN + IoTerrain.RING_OUT) / 2.0), 0)
	assert_eq(s.sight_at(ring.x, ring.y), &"ring")
	var ids: Array = []
	for sight: Dictionary in s.sights():
		ids.append(sight.id)
		var at: Vector3 = sight.pos
		assert_eq(s.sight_at(floori(at.x), floori(at.z)), sight.id, "its map spot is on it: %s" % sight.id)
		assert_eq(int(at.y), s.height_at(floori(at.x), floori(at.z)))
	assert_eq(ids, [&"lake", &"mountain", &"plume"], "the big ones on the map")


func test_another_seed_is_another_io() -> void:
	var a := _io()
	var b := _io(777)
	assert_eq(a.io.lake_centre(), _io().io.lake_centre(), "the same seed, the same Io")
	assert_ne(a.io.lake_centre(), b.io.lake_centre())
	assert_ne(a.io.mountain_centre(), b.io.mountain_centre())
	var differ := 0
	for i in 40:
		if a.io_kind(i * 31, i * 17) != b.io_kind(i * 31, i * 17) or a.height_at(i * 31, i * 17) != b.height_at(i * 31, i * 17):
			differ += 1
	assert_gt(differ, 5)
