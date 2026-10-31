extends GutTest
## Cosmos: Ganymede (world 28, spec §21b.2): its terrain as pure rules (SpaceShape with planet GANYMEDE; the regions in
## GanymedeTerrain), from what spacecraft saw (1979-2021). The landing pad on a smooth plain of bright ice; round it the
## bright grooved terrain (lanes of long parallel ridges and grooves, each lane its own way, flat seams between them); the
## old dark terrain to the west (a little higher, dark ice crossed by long curved furrows and pocked with old craters); a
## young bright ray crater to the east (a bowl with a pit in its middle, a low rim, long rays of fresh ice across the
## ground); frost at the poles, far to the north and the south. Built by the pad: the Jupiter Lookout (east, towards
## Jupiter); a walk away: the ocean drill (south-west) and the Aurora Watch on the northern frost. Every step is one a
## Ganymede jump climbs, and the smooth plain is a walk.

const SEED := 12345
const SEEDS: Array[int] = [12345, 77, 777, 42]


func _ganymede(seed: int = SEED) -> SpaceShape:
	return SpaceShape.new(seed, SpaceShape.GANYMEDE)


func _jump() -> float:
	return Player.JUMP_VELOCITY * Player.JUMP_VELOCITY / (2.0 * Player.GRAVITY * 0.146)


func test_ganymede_is_a_space_planet_with_its_terrain() -> void:
	assert_has(SpaceShape.PLANETS, SpaceShape.GANYMEDE)
	var s := _ganymede()
	assert_eq(s.planet, SpaceShape.GANYMEDE)
	assert_not_null(s.ganymede, "Ganymede's regions")
	assert_null(s.triton)
	assert_null(s.europa)
	assert_null(SpaceShape.new(SEED, SpaceShape.TRITON).ganymede, "Triton has none")
	assert_lt(float(GanymedeTerrain.MAX_STEP), _jump() - 6.0, "a jump at 0.146 gravity reaches ~11 blocks")
	assert_false(s.has_vents(), "no geysers on Ganymede")


func test_heights_stay_between_the_floor_and_the_sky() -> void:
	var s := _ganymede()
	var g := s.ganymede
	var points: Array[Vector2i] = [g.crater_centre(), g.drill, g.watch, g.lookout]
	for i in 900:
		points.append(Vector2i((i * 37) % 2400 - 1200, (i * 91) % 2400 - 1200))
	for q in points:
		var h := s.height_at(q.x, q.y)
		assert_gt(h, MeadowsShape.SEA_LEVEL + 2, "(%d, %d): over the old sea level" % [q.x, q.y])
		assert_lt(h, SpaceGenerator.SKY_TOP - 60, "(%d, %d): far under the sky's limit" % [q.x, q.y])
		assert_false(s.is_river(q.x, q.y), "no liquid on Ganymede's ground: every column is dry land")


## The pad on the smooth bright plain: the grooves round it, the dark terrain a walk west, the ray crater a walk east, the
## frost far north and far south.
func test_the_pad_is_on_a_smooth_plain_among_the_grooves() -> void:
	for seed in SEEDS:
		var s := _ganymede(seed)
		var g := s.ganymede
		var sp := s.spawn_column()
		assert_eq(s.ganymede_kind(sp.x, sp.y), GanymedeTerrain.SMOOTH, "seed %d" % seed)
		assert_between(float(sp.x) - g.dark_edge(float(sp.y)), 60.0, 160.0, "seed %d: the dark terrain a walk west" % seed)
		var crater := g.crater_centre()
		assert_between(Vector2(crater - sp).length(), 100.0, 180.0, "seed %d: the ray crater a walk away" % seed)
		assert_gt(crater.x, sp.x + 80, "seed %d: to the east" % seed)
		assert_between(float(sp.y) - g.north_edge(float(sp.x)), 170.0, 280.0, "seed %d: the north frost far north" % seed)
		assert_between(g.south_edge(float(sp.x)) - float(sp.y), 200.0, 330.0, "seed %d: the south frost far south" % seed)
		var grooves := 0
		for a in 16:
			var p := sp + Vector2i(roundi(cos(a * TAU / 16.0) * 110.0), roundi(sin(a * TAU / 16.0) * 110.0))
			if GanymedeTerrain.is_grooved(s.ganymede_kind(p.x, p.y)):
				grooves += 1
		assert_gte(grooves, 6, "seed %d: grooved terrain all round the plain (%d of 16)" % [seed, grooves])


func test_the_smooth_plain_and_the_grooves_are_bright_ice_over_the_icy_crust() -> void:
	var s := _ganymede()
	var sp := s.spawn_column()
	var plain := 0
	var ridges := 0
	var troughs := 0
	for i in 4000:
		var x := sp.x + (i * 17) % 300 - 150
		var z := sp.y + (i * 29) % 300 - 150
		var k := s.ganymede_kind(x, z)
		if s.pad_at(x, z) or s.ganymede.on_part(x, z, 1) or s.tree_at(x, z):
			continue
		var h := s.height_at(x, z)
		match k:
			GanymedeTerrain.SMOOTH:
				plain += 1
				assert_eq(s.block_at(x, h - 1, z), BlockIds.GROOVED_ICE, "(%d, %d): pale bright ice on the plain" % [x, z])
			GanymedeTerrain.RIDGE:
				ridges += 1
				assert_eq(s.block_at(x, h - 1, z), BlockIds.GROOVED_ICE, "a ridge's pale ice")
			GanymedeTerrain.GROOVE:
				troughs += 1
				assert_eq(s.block_at(x, h - 1, z), BlockIds.TROUGH_ICE, "a groove's blue-grey floor")
			_:
				continue
		assert_eq(s.block_at(x, h - 3, z), BlockIds.GROOVED_ICE, "the bright ice goes a few blocks down")
		assert_eq(s.block_at(x, h - 8, z), BlockIds.WATER_ICE, "the icy crust under it")
		assert_eq(s.block_at(x, -5, z), BlockIds.WATER_ICE, "water ice deep down")
		assert_eq(s.block_at(x, MeadowsShape.WORLD_BOTTOM, z), BlockIds.BEDROCK)
	assert_gt(plain, 500, "a smooth plain round the pad")
	assert_gt(ridges, 300, "ridges")
	assert_gt(troughs, 300, "and grooves between them")


## The grooves: long and parallel inside a lane (heights repeat every few blocks across them and hardly change along
## them), each lane its own way.
func test_grooves_run_long_and_parallel() -> void:
	for seed in SEEDS:
		var s := _ganymede(seed)
		var g := s.ganymede
		var sp := s.spawn_column()
		var found := 0
		var dirs := {}
		for a in 24:
			var p := sp + Vector2i(roundi(cos(a * TAU / 24.0) * 140.0), roundi(sin(a * TAU / 24.0) * 140.0))
			var lane := g.lane_at(p.x, p.y)
			if lane.is_empty() or float(lane.strength) < 0.99:
				continue
			var along: Vector2 = lane.along
			var across := Vector2(-along.y, along.x)
			var same := 0
			for t in range(-12, 13, 2):   # along a groove: the same height
				var q := Vector2(p) + along * t
				var r := Vector2(p)
				if absi(s.height_at(roundi(q.x), roundi(q.y)) - s.height_at(roundi(r.x), roundi(r.y))) <= 1:
					same += 1
			var lo := 999
			var hi := -999
			for t in range(0, 14):   # across them: up and down
				var q := Vector2(p) + across * t
				var h := s.height_at(roundi(q.x), roundi(q.y))
				lo = mini(lo, h)
				hi = maxi(hi, h)
			if same >= 11 and hi - lo >= 2:
				found += 1
				dirs[roundi(rad_to_deg(along.angle())) / 20] = true
		assert_gte(found, 4, "seed %d: lanes of long parallel ridges and grooves (%d)" % [seed, found])
		assert_gte(dirs.size(), 2, "seed %d: the lanes run different ways" % seed)


func test_the_dark_terrain_is_old_dark_ice_with_furrows_and_old_craters() -> void:
	var s := _ganymede()
	var g := s.ganymede
	var counts := {}
	var dark_h := 0.0
	var n := 0
	for i in 8000:
		var z := (i * 31) % 360 - 180
		var x := roundi(g.dark_edge(float(z))) - 30 - (i * 17) % 500
		var k := s.ganymede_kind(x, z)
		counts[k] = int(counts.get(k, 0)) + 1
		assert_true(GanymedeTerrain.is_dark(k) or k == GanymedeTerrain.FROST, "(%d, %d): west of its edge (%d)" % [x, z, k])
		var h := s.height_at(x, z)
		if s.tree_at(x, z):
			continue
		match k:
			GanymedeTerrain.DARK:
				assert_eq(s.block_at(x, h - 1, z), BlockIds.DARK_ICE, "dark ice on top")
				assert_eq(s.block_at(x, h - 2, z), BlockIds.OLD_ICE, "old, dusty ice under it")
				dark_h += h
				n += 1
			GanymedeTerrain.FURROW, GanymedeTerrain.OLD_CRATER:
				assert_eq(s.block_at(x, h - 1, z), BlockIds.OLD_ICE, "a furrow's or an old crater's floor")
		assert_eq(s.block_at(x, h - 7, z), BlockIds.WATER_ICE, "the icy crust under it")
	assert_gt(int(counts.get(GanymedeTerrain.DARK, 0)), 4000, "mostly dark ice")
	assert_gt(int(counts.get(GanymedeTerrain.FURROW, 0)), 300, "long furrows")
	assert_gt(int(counts.get(GanymedeTerrain.OLD_CRATER, 0)), 300, "old craters everywhere")
	assert_gt(dark_h / n, GanymedeTerrain.BASE + 1.0, "the old terrain stands a little higher (%.1f)" % (dark_h / n))


## The furrows: long curved troughs, arcs round one far-off middle (the scar of an old giant impact).
func test_the_furrows_are_arcs_round_one_middle() -> void:
	var s := _ganymede()
	var g := s.ganymede
	var f := g.furrow_centre()
	var arcs := 0
	var z0 := 0
	for k in 3:
		var r := g.furrow_radius(k + 8)
		var on := 0
		var tried := 0
		for a in range(-10, 11):
			var ang := deg_to_rad(float(a))
			var p := Vector2(f) + Vector2(cos(ang), sin(ang)) * r
			if float(roundi(p.x)) > g.dark_edge(p.y) - GanymedeTerrain.DARK_BLEND - 4.0:
				continue
			tried += 1
			if s.ganymede_kind(roundi(p.x), roundi(p.y)) == GanymedeTerrain.FURROW:
				on += 1
		if tried > 5 and on >= tried * 0.6:
			arcs += 1
	assert_gte(arcs, 2, "furrows follow arcs round one middle")
	assert_lt(f.x, -400, "far to the west")


## A young bright ray crater: a bowl of fresh ice with a pit in its middle and a low rim; long rays of fresh ice running
## out across the ground in every direction, narrowing and breaking up far out.
func test_the_bright_ray_crater_has_a_pit_and_long_rays() -> void:
	for seed in SEEDS:
		var s := _ganymede(seed)
		var g := s.ganymede
		var c := g.crater_centre()
		var r := g.crater_radius()
		assert_between(r, GanymedeTerrain.CRATER_R.x, GanymedeTerrain.CRATER_R.y, "seed %d" % seed)
		assert_eq(s.ganymede_kind(c.x, c.y), GanymedeTerrain.PIT, "seed %d: a pit in its middle" % seed)
		var pit := s.height_at(c.x, c.y)
		var floor_h := s.height_at(c.x + roundi(r * 0.5), c.y)
		var rim := s.height_at(c.x + r, c.y)
		assert_gt(floor_h, pit, "seed %d: the pit is sunk in the floor (%d .. %d)" % [seed, pit, floor_h])
		assert_gte(rim - floor_h, 3, "seed %d: a bowl (%d .. %d)" % [seed, floor_h, rim])
		assert_eq(s.block_at(c.x, pit - 1, c.y), BlockIds.RAY_ICE, "fresh ice in the pit")
		assert_eq(s.block_at(c.x + roundi(r * 0.5), floor_h - 1, c.y), BlockIds.RAY_ICE, "fresh ice in the bowl")
		var rays := 0
		var dirs := {}
		for a in 72:
			var ang := a * TAU / 72.0
			var hits := 0
			for d in range(r + 8, r + 40, 4):
				var p := c + Vector2i(roundi(cos(ang) * d), roundi(sin(ang) * d))
				if s.ganymede_kind(p.x, p.y) == GanymedeTerrain.RAY:
					hits += 1
			if hits >= 5:
				rays += 1
				dirs[a / 6] = true
		assert_gte(rays, 8, "seed %d: long bright rays (%d)" % [seed, rays])
		assert_gte(dirs.size(), 5, "seed %d: in many directions" % seed)
		var far := 0
		for a in 360:
			var ang := deg_to_rad(float(a))
			var p := c + Vector2i(roundi(cos(ang) * (r + 140)), roundi(sin(ang) * (r + 140)))
			if s.ganymede_kind(p.x, p.y) == GanymedeTerrain.RAY:
				far += 1
		assert_eq(far, 0, "seed %d: the rays end out on the plains" % seed)


func test_rays_are_fresh_ice_laid_on_the_ground() -> void:
	var s := _ganymede()
	var g := s.ganymede
	var c := g.crater_centre()
	var seen := 0
	for a in 180:
		for d in [30, 45, 60]:
			var p := c + Vector2i(roundi(cos(a * TAU / 180.0) * d), roundi(sin(a * TAU / 180.0) * d))
			if s.ganymede_kind(p.x, p.y) != GanymedeTerrain.RAY or s.tree_at(p.x, p.y):
				continue
			seen += 1
			var h := s.height_at(p.x, p.y)
			assert_eq(s.block_at(p.x, h - 1, p.y), BlockIds.RAY_ICE, "fresh ice on top")
			assert_eq(h, g.ground_without_rays(p.x, p.y), "a ray is laid on the ground: it never changes its height")
	assert_gt(seen, 40)


## Frost at the poles: far north and far south everything wears white frost with a violet tint (the ground under it
## goes on: grooves, dark terrain); its edge is patchy.
func test_frost_at_the_poles() -> void:
	var s := _ganymede()
	var g := s.ganymede
	for x in range(-300, 300, 9):
		var n := g.north_edge(float(x))
		for d in [12, 40, 120]:
			assert_eq(s.ganymede_kind(x, floori(n) - d), GanymedeTerrain.FROST, "(%d): north of the edge, frost" % x)
			var h := s.height_at(x, floori(n) - d)
			if not s.tree_at(x, floori(n) - d) and not g.on_part(x, floori(n) - d, 1):
				assert_eq(s.block_at(x, h - 1, floori(n) - d), BlockIds.POLAR_FROST)
		assert_ne(s.ganymede_kind(x, ceili(n) + 12), GanymedeTerrain.FROST, "(%d): south of it, none" % x)
		var so := g.south_edge(float(x))
		assert_eq(s.ganymede_kind(x, ceili(so) + 12), GanymedeTerrain.FROST, "(%d): the south pole's frost" % x)
		assert_ne(s.ganymede_kind(x, floori(so) - 12), GanymedeTerrain.FROST)


func test_every_step_is_one_ganymede_jump_and_the_plain_a_walk() -> void:
	for seed in SEEDS:
		var s := _ganymede(seed)
		var g := s.ganymede
		var pts: Array[Vector2i] = []
		for i in 3000:
			pts.append(Vector2i((i * 13) % 1400 - 700, (i * 7) % 1400 - 700))
		for c: Vector2i in [g.crater_centre(), s.spawn_column(), Vector2i(roundi(g.dark_edge(0.0)), 0), g.drill,
				g.watch, Vector2i(0, roundi(g.north_edge(0.0))), g.furrow_point_near(s.spawn_column())]:
			for dz in range(-70, 71, 4):
				for dx in range(-70, 71):
					pts.append(c + Vector2i(dx, dz))
		for q in pts:
			for n: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
				if g.on_part(q.x, q.y, 1) or g.on_part(q.x + n.x, q.y + n.y, 1):
					continue
				var a := s.ground_at(q.x, q.y)
				var b := s.ground_at(q.x + n.x, q.y + n.y)
				assert_lte(absi(a - b), GanymedeTerrain.MAX_STEP, "seed %d (%d, %d)" % [seed, q.x, q.y])
				var ka := s.ganymede_kind(q.x, q.y)
				var kb := s.ganymede_kind(q.x + n.x, q.y + n.y)
				if ka == GanymedeTerrain.SMOOTH and kb == GanymedeTerrain.SMOOTH:
					assert_lte(absi(a - b), 1, "seed %d (%d, %d): the plain is a walk" % [seed, q.x, q.y])


func test_the_jupiter_lookout_stands_east_of_the_pad() -> void:
	for seed in SEEDS:
		var s := _ganymede(seed)
		var g := s.ganymede
		var sp := s.spawn_column()
		var lk := g.lookout
		assert_ne(lk, GanymedeTerrain.NONE)
		assert_gt(lk.x, sp.x + 8, "seed %d: east of the pad: towards Jupiter" % seed)
		assert_between(Vector2(lk - sp).length(), 10.0, 14.0, "seed %d: a few steps from it" % seed)
		assert_true(s.tree_at(lk.x, lk.y), "its ground is kept: nothing else stands there")
		var y := g.lookout_y
		assert_eq(g.built_at(Vector3i(lk.x, y - 1, lk.y)), BlockIds.GROOVE_BRICK, "a round floor of groove bricks")
		assert_eq(g.built_at(Vector3i(lk.x, y, lk.y)), BlockIds.TRUSS, "a stand")
		assert_eq(g.built_at(Vector3i(lk.x, y + 2, lk.y)), BlockIds.TELESCOPE, "its telescope")
		assert_eq(g.built_at(Vector3i(lk.x + 1, y + 3, lk.y)), BlockIds.TELESCOPE, "looking east and up at Jupiter")
		assert_eq(g.built_at(Vector3i(lk.x - 1, y + 1, lk.y + 1)), BlockIds.JUPITER_GLOBE, "a globe of Jupiter")
		assert_eq(g.built_at(Vector3i(lk.x + 1, y, lk.y + 1)), BlockIds.AURORA_LAMP, "an aurora lamp")
		for dz in range(-2, 3):
			for dx in range(-2, 3):
				if dx * dx + dz * dz <= 5:
					assert_lte(y - s.height_at(lk.x + dx, lk.y + dz), 2, "a step or two up onto its floor")


## The Aurora Watch on the northern frost, straight north of the pad: a floor of groove bricks, a mast with a lamp, a
## long boom with the magnetometer at its tip (they sit far out on booms, away from a station's own magnetism).
func test_the_aurora_watch_stands_on_the_northern_frost() -> void:
	for seed in SEEDS:
		var s := _ganymede(seed)
		var g := s.ganymede
		var sp := s.spawn_column()
		var w := g.watch
		assert_eq(s.ganymede_kind(w.x, w.y), GanymedeTerrain.FROST, "seed %d: on the frost" % seed)
		assert_lt(float(w.y), g.north_edge(float(w.x)) - 6.0, "seed %d: inside its edge" % seed)
		assert_lt(absi(w.x - sp.x), 30, "seed %d: straight north of the pad" % seed)
		assert_true(s.tree_at(w.x, w.y), "its ground is kept")
		var y := g.watch_y
		assert_eq(g.built_at(Vector3i(w.x, y - 1, w.y)), BlockIds.GROOVE_BRICK, "a floor")
		var mast := 0
		var sensor := 0
		var lamp := 0
		for dy in range(0, 10):
			for dz in range(-6, 7):
				for dx in range(-6, 7):
					match g.built_at(Vector3i(w.x + dx, y + dy, w.y + dz)):
						BlockIds.TRUSS:
							mast += 1
						BlockIds.MAGNETOMETER:
							sensor += 1
							assert_gte(Vector2(dx, dz).length(), 3.0, "the sensor far out on its boom")
						BlockIds.AURORA_LAMP:
							lamp += 1
		assert_gte(mast, 7, "a mast and a boom")
		assert_eq(sensor, 1, "the magnetometer")
		assert_gte(lamp, 1, "an aurora lamp")
		for dz in range(-2, 3):
			for dx in range(-2, 3):
				if dx * dx + dz * dz <= 5:
					assert_lte(y - s.height_at(w.x + dx, w.y + dz), 2, "a step or two up onto its floor")


## The ocean drill a walk south-west: a floor of bricks round a shaft lined with deep blue ice, the drill's light glowing
## at its bottom; a tower of trusses over it with lamps. A child who drops in jumps out (a Ganymede jump ~11 blocks).
func test_the_ocean_drill_has_a_shaft_a_child_can_jump_out_of() -> void:
	for seed in SEEDS:
		var s := _ganymede(seed)
		var g := s.ganymede
		var sp := s.spawn_column()
		var d := g.drill
		var off := d - sp
		assert_between(Vector2(off).length(), 70.0, 110.0, "seed %d: a walk from the pad" % seed)
		assert_lt(off.x, 0, "seed %d: to the west ..." % seed)
		assert_gt(off.y, 0, "seed %d: ... and the south" % seed)
		assert_true(s.tree_at(d.x, d.y), "its ground is kept")
		var y := g.drill_y
		assert_eq(g.built_at(Vector3i(d.x + 2, y - 1, d.y)), BlockIds.GROOVE_BRICK, "a brick floor round the shaft")
		for dy in range(1, GanymedeTerrain.SHAFT_DEPTH + 1):
			assert_eq(g.built_at(Vector3i(d.x, y - dy, d.y)), BlockIds.AIR, "the shaft goes down (%d)" % dy)
			assert_eq(g.built_at(Vector3i(d.x + 2, y - dy - 1, d.y)), BlockIds.DEEP_ICE, "lined with deep blue ice")
		assert_eq(g.built_at(Vector3i(d.x, y - GanymedeTerrain.SHAFT_DEPTH - 1, d.y)), BlockIds.GLOW_ICE,
			"the drill's light glows at its bottom")
		assert_lt(float(GanymedeTerrain.SHAFT_DEPTH), _jump() - 0.5, "a child jumps out of it")
		var legs := 0
		for c: Vector2i in [Vector2i(-2, -2), Vector2i(2, -2), Vector2i(-2, 2), Vector2i(2, 2)]:
			if g.built_at(Vector3i(d.x + c.x, y + 3, d.y + c.y)) == BlockIds.TRUSS:
				legs += 1
		assert_eq(legs, 4, "a tower on four legs")


func test_boulders_on_the_ground_and_aurora_crystals_on_the_frost() -> void:
	var s := _ganymede()
	var boulders := 0
	var crystals := 0
	for i in 80000:   # a grid over 1800 × 1800 blocks
		var x := (i % 400) * 4 - 600
		var z := (i / 400) * 9 - 900
		if not s.tree_at(x, z) or s.ganymede.on_part(x, z, 1):
			continue
		var id := s.feature_at(x, s.height_at(x, z), z)
		var k := s.ganymede_kind(x, z)
		if id == BlockIds.AURORA_CRYSTAL:
			crystals += 1
			assert_true(k == GanymedeTerrain.FROST or k == GanymedeTerrain.PIT, "crystals on the frost and in the pit")
		elif id == BlockIds.WATER_ICE or id == BlockIds.OLD_ICE:
			boulders += 1
			assert_true(GanymedeTerrain.is_grooved(k) or GanymedeTerrain.is_dark(k) or k == GanymedeTerrain.SMOOTH,
				"boulders on the plains")
		assert_false(k == GanymedeTerrain.RAY or k == GanymedeTerrain.CRATER, "nothing stands on the fresh ice")
	assert_gt(boulders, 20, "boulders")
	assert_gt(crystals, 30, "glowing aurora crystals on the frost")


func test_the_sights_where_a_child_learns_a_fact() -> void:
	var s := _ganymede()
	var g := s.ganymede
	var sp := s.spawn_column()
	assert_eq(s.sight_at(g.lookout.x, g.lookout.y), &"lookout", "the Jupiter Lookout by the pad")
	assert_eq(s.sight_at(g.watch.x, g.watch.y), &"aurora", "the Aurora Watch")
	assert_eq(s.sight_at(g.drill.x, g.drill.y), &"ocean", "the ocean drill")
	assert_eq(s.sight_at(g.crater_centre().x, g.crater_centre().y), &"crater")
	var groove := g.first_groove_toward(sp)
	assert_eq(s.sight_at(groove.x, groove.y), &"grooves")
	var dark := g.first_dark_west_of(sp)
	assert_eq(s.sight_at(dark.x, dark.y), &"dark")
	var frost := g.frost_point_north_of(sp)
	assert_eq(s.sight_at(frost.x, frost.y), &"frost")
	assert_eq(s.sight_at(sp.x, sp.y), &"", "nothing at the pad")
	var ids: Array = s.sights().map(func(e: Dictionary) -> StringName: return e.id)
	assert_eq(ids, [&"lookout", &"grooves", &"dark", &"crater", &"frost", &"aurora", &"ocean"], "MY MAP shows all seven")
	for e: Dictionary in s.sights():
		var at: Vector3 = e.pos
		assert_eq(s.sight_at(floori(at.x), floori(at.z)), e.id, "%s's mark is on it" % e.id)


func test_the_same_seed_is_the_same_ganymede() -> void:
	var a := _ganymede()
	var b := _ganymede()
	assert_eq(a.spawn_column(), b.spawn_column())
	assert_eq(a.ganymede.crater_centre(), b.ganymede.crater_centre())
	assert_eq(a.ganymede.drill, b.ganymede.drill)
	for i in 50:
		assert_eq(a.height_at(i * 13, -i * 7), b.height_at(i * 13, -i * 7))
		assert_eq(a.height_at(-i * 11, 150 + i * 5), b.height_at(-i * 11, 150 + i * 5))
	var other := _ganymede(777)
	assert_ne(other.ganymede.crater_centre(), a.ganymede.crater_centre(), "another seed, another Ganymede")


## The generator's path (columns) is exactly the reference (column), over a block.
func test_the_fast_columns_are_the_reference() -> void:
	var s := _ganymede()
	var g := s.ganymede
	for c: Vector2i in [g.crater_centre(), g.crater_centre() + Vector2i(40, 10), s.spawn_column(), g.drill, g.watch,
			Vector2i(roundi(g.dark_edge(0.0)), 0), g.furrow_point_near(s.spawn_column()), g.first_groove_toward(s.spawn_column())]:
		var x0 := c.x - 8
		var z0 := c.y - 8
		var cols := s.ganymede_columns(x0, z0, 16, 16)
		var gr: PackedInt32Array = cols[0]
		var k: PackedByteArray = cols[1]
		for z in 16:
			for x in 16:
				assert_eq(gr[x + z * 16], s.ground_at(x0 + x, z0 + z), "(%d, %d)" % [x0 + x, z0 + z])
				assert_eq(k[x + z * 16], s.ganymede_kind(x0 + x, z0 + z))
