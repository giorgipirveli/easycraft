extends GutTest
## Cosmos: Triton (world 27, spec §21b.2): its terrain as pure rules (SpaceShape with planet TRITON; the regions in
## TritonTerrain), from what Voyager 2 saw in 1989. The landing pad on the bright band of fresh nitrogen frost; the south
## polar cap to the south (pink nitrogen ice with darker mottled patches, a little higher) with its geysers: dark vents in
## rings of dark dust, each with a dark streak the thin wind drew north-east across the pink ice; the cantaloupe terrain to
## the north-west (dimples with ridges between them, like a melon's rind); a walled plain to the north-east (a frozen lake
## of ice lava, flat, sunk under the frost, with terraced walls up to a rim); one of Triton's few craters to the east (its
## ground is young); the Neptune Lookout a few steps north-east of the pad, towards Neptune. Every step is one a Triton jump
## climbs (and the frost, the cap and the cantaloupe terrain step a block at most: a walk).

const SEED := 12345
const SEEDS: Array[int] = [12345, 77, 777, 42]


func _triton(seed: int = SEED) -> SpaceShape:
	return SpaceShape.new(seed, SpaceShape.TRITON)


func _jump() -> float:
	return Player.JUMP_VELOCITY * Player.JUMP_VELOCITY / (2.0 * Player.GRAVITY * 0.079)


func test_triton_is_a_space_planet_with_its_terrain() -> void:
	assert_has(SpaceShape.PLANETS, SpaceShape.TRITON)
	var s := _triton()
	assert_eq(s.planet, SpaceShape.TRITON)
	assert_not_null(s.triton, "Triton's regions")
	assert_null(s.pluto)
	assert_null(s.europa)
	assert_null(SpaceShape.new(SEED, SpaceShape.PLUTO).triton, "Pluto has none")
	assert_lt(float(TritonTerrain.MAX_STEP), _jump() - 10.0, "a jump at 0.079 gravity reaches ~21 blocks")
	assert_true(s.has_vents(), "geysers")


func test_heights_stay_between_the_floor_and_the_sky() -> void:
	var s := _triton()
	var t := s.triton
	var points: Array[Vector2i] = [t.lake_centre(), t.crater_centre(), t.first_geyser()]
	for i in 900:
		points.append(Vector2i((i * 37) % 2400 - 1200, (i * 91) % 2400 - 1200))
	for q in points:
		var h := s.height_at(q.x, q.y)
		assert_gt(h, MeadowsShape.SEA_LEVEL + 2, "(%d, %d): over the old sea level" % [q.x, q.y])
		assert_lt(h, SpaceGenerator.SKY_TOP - 60, "(%d, %d): far under the sky's limit" % [q.x, q.y])
		assert_false(s.is_river(q.x, q.y), "no liquid on Triton: every column is dry land")


## The pad on the bright band's fresh frost: the cap a walk south, the cantaloupe terrain a walk north-west, the frozen
## lake a walk north-east, the crater a walk east.
func test_the_pad_is_on_the_frost_between_the_cap_and_the_cantaloupe_terrain() -> void:
	for seed in SEEDS:
		var s := _triton(seed)
		var t := s.triton
		var sp := s.spawn_column()
		assert_eq(s.triton_kind(sp.x, sp.y), TritonTerrain.FROST, "seed %d" % seed)
		assert_between(t.cap_edge(float(sp.x)) - sp.y, 45.0, 130.0, "seed %d: the pink cap a walk south" % seed)
		assert_between(t.melon_edge_distance(sp.x, sp.y), 45.0, 160.0, "seed %d: the cantaloupe terrain a walk away" % seed)
		var lake := t.lake_centre()
		assert_between(Vector2(lake - sp).length(), 110.0, 230.0, "seed %d: the frozen lake a walk away" % seed)
		assert_gt(lake.x, sp.x, "seed %d: to the east" % seed)
		assert_lt(lake.y, sp.y, "seed %d: and the north" % seed)
		var crater := t.crater_centre()
		assert_between(Vector2(crater - sp).length(), 90.0, 180.0, "seed %d: the crater a walk away" % seed)
		assert_gt(crater.x, sp.x + 80, "seed %d: to the east" % seed)


func test_the_frost_band_is_bright_nitrogen_frost_over_nitrogen_and_water_ice() -> void:
	var s := _triton()
	var sp := s.spawn_column()
	var frost := 0
	for i in 2000:
		var x := sp.x + (i * 17) % 120 - 60
		var z := sp.y + (i * 29) % 90 - 45
		if s.triton_kind(x, z) != TritonTerrain.FROST or s.pad_at(x, z) or s.triton.on_lookout(x, z, 1):
			continue
		frost += 1
		var h := s.height_at(x, z)
		assert_eq(s.block_at(x, h - 1, z), BlockIds.TRITON_FROST, "(%d, %d): fresh frost on top" % [x, z])
		assert_eq(s.block_at(x, h - 3, z), BlockIds.NITROGEN_ICE, "a crust of frozen nitrogen under it")
		assert_eq(s.block_at(x, h - 8, z), BlockIds.WATER_ICE, "an icy mantle under that")
		assert_eq(s.block_at(x, -5, z), BlockIds.WATER_ICE, "water ice deep down")
		assert_eq(s.block_at(x, MeadowsShape.WORLD_BOTTOM, z), BlockIds.BEDROCK)
	assert_gt(frost, 1200, "a wide band of frost round the pad")


func test_the_south_polar_cap_is_pink_with_darker_patches() -> void:
	var s := _triton()
	var t := s.triton
	var counts := {}
	for i in 8000:
		var x := (i * 17) % 800 - 400
		var z := 160 + (i * 31) % 500
		var k := s.triton_kind(x, z)
		counts[k] = int(counts.get(k, 0)) + 1
		assert_true(TritonTerrain.is_cap(k), "(%d, %d): the cap covers the south (%d)" % [x, z, k])
		var h := s.height_at(x, z)
		match k:
			TritonTerrain.CAP:
				assert_eq(s.block_at(x, h - 1, z), BlockIds.PINK_ICE, "pink nitrogen ice")
				assert_eq(s.block_at(x, h - 2, z), BlockIds.PINK_ICE)
				assert_eq(s.block_at(x, h - 4, z), BlockIds.NITROGEN_ICE, "nitrogen ice under it")
			TritonTerrain.MOTTLE:
				assert_eq(s.block_at(x, h - 1, z), BlockIds.MOTTLED_ICE, "darker mottled patches")
			TritonTerrain.STREAK:
				assert_eq(s.block_at(x, h - 1, z), BlockIds.GEYSER_DUST, "a dark streak of geyser dust")
				assert_eq(s.block_at(x, h - 2, z), BlockIds.PINK_ICE, "on the pink ice")
	assert_gt(int(counts.get(TritonTerrain.CAP, 0)), 4000, "mostly pink ice")
	assert_gt(int(counts.get(TritonTerrain.MOTTLE, 0)), 300, "darker patches")
	assert_gt(int(counts.get(TritonTerrain.STREAK, 0)), 100, "dark streaks")
	for x in range(-120, 300, 25):   # (the cantaloupe terrain meets the cap far to the west)
		var edge := t.cap_edge(float(x))
		assert_eq(s.triton_kind(x, ceili(edge) + 3) != TritonTerrain.FROST, true, "(%d): south of the edge is the cap" % x)
		assert_eq(s.triton_kind(x, floori(edge) - 3), TritonTerrain.FROST, "(%d): north of it the frost" % x)


## Geysers: at most one per VENT_CELL cell, deep in the cap, a dark vent in a ring of dark dust, flush with the ice (a
## child walks onto it), each with a dark streak running north-east (downwind), narrowing as it goes.
func test_geysers_on_the_cap_with_streaks_running_north_east() -> void:
	for seed in SEEDS:
		var s := _triton(seed)
		var t := s.triton
		var vents := t.vents_near(0, 300, 420.0)
		assert_gt(vents.size(), 6, "seed %d: many geysers on the cap (%d)" % [seed, vents.size()])
		var first := t.first_geyser()
		assert_has(vents, first, "seed %d: the first geyser is one of them" % seed)
		var sp := s.spawn_column()
		assert_between(Vector2(first - sp).length(), 80.0, 160.0, "seed %d: a walk south of the pad" % seed)
		assert_gt(first.y, sp.y, "seed %d: south" % seed)
		for v in vents:
			assert_gte(float(v.y) - t.cap_edge(float(v.x)), float(TritonTerrain.VENT_IN) - 0.5, "seed %d: deep in the cap" % seed)
			assert_eq(s.triton_kind(v.x, v.y), TritonTerrain.VENT, "seed %d: (%d, %d) is a vent" % [seed, v.x, v.y])
			var g := s.ground_at(v.x, v.y)
			assert_eq(s.block_at(v.x, g - 1, v.y), BlockIds.NITROGEN_GEYSER, "the vent block on top")
			for d: Vector2i in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
				assert_eq(s.triton_kind(v.x + d.x, v.y + d.y), TritonTerrain.SPOT, "a ring of dark dust round it")
				assert_eq(s.ground_at(v.x + d.x, v.y + d.y), g, "flush: the ring and the vent at one height")
				assert_eq(s.block_at(v.x + d.x, g - 1, v.y + d.y), BlockIds.GEYSER_DUST)
		var along := 0
		var down := 0
		for i in 60:   # the first geyser's streak runs north-east of it (east +x, north -z)
			var a := float(i + 5)
			var p := t.streak_centre(first, a)
			if a <= t.streak_length(first) * 0.6:
				if s.triton_kind(p.x, p.y) == TritonTerrain.STREAK:
					along += 1
			var back := first - (p - first)
			if i < 20 and s.triton_kind(back.x, back.y) == TritonTerrain.STREAK:
				down += 1
		assert_gt(along, 15, "seed %d: a streak north-east of the first geyser (%d)" % [seed, along])
		assert_eq(down, 0, "seed %d: none upwind" % seed)
		var dir := Vector2(t.streak_centre(first, 30.0) - first).normalized()
		assert_gt(dir.x, 0.3, "seed %d: east" % seed)
		assert_lt(dir.y, -0.3, "seed %d: and north (%s)" % [seed, dir])


func test_the_streaks_narrow_downwind() -> void:
	var s := _triton()
	var t := s.triton
	var v := t.first_geyser()
	var len := t.streak_length(v)
	var near := 0
	var far := 0
	for a: float in [6.0, 8.0, 10.0]:
		near += _width(s, t, v, a)
	for a: float in [len * 0.55, len * 0.58, len * 0.61]:
		far += _width(s, t, v, a)
	assert_gt(near, far, "wide near the vent (%d), thin far downwind (%d)" % [near, far])


## Across the streak at `a` blocks downwind: how many columns are streak.
func _width(s: SpaceShape, t: TritonTerrain, v: Vector2i, a: float) -> int:
	var c := t.streak_centre(v, a)
	var n := 0
	for k in range(-8, 9):
		var p := Vector2(c) + Vector2(0.7071, 0.7071) * k
		if s.triton_kind(roundi(p.x), roundi(p.y)) == TritonTerrain.STREAK:
			n += 1
	return n


func test_the_cantaloupe_terrain_is_dimples_with_ridges() -> void:
	var s := _triton()
	var t := s.triton
	var start := t.first_melon_toward(s.spawn_column())
	assert_ne(start, TritonTerrain.NONE)
	var dimples := 0
	var ridges := 0
	var tops := {}
	var cells := {}
	for i in 6000:
		var x := start.x - 30 - (i * 13) % 200
		var z := start.y - 30 - (i * 7) % 200
		var k := s.triton_kind(x, z)
		if not TritonTerrain.is_melon(k):
			continue
		var h := s.height_at(x, z)
		tops[h] = true
		if k == TritonTerrain.DIMPLE:
			dimples += 1
			assert_eq(s.block_at(x, h - 1, z), BlockIds.CANTALOUPE_ICE)
		else:
			ridges += 1
			assert_eq(s.block_at(x, h - 1, z), BlockIds.RIDGE_ICE, "paler ridge ice")
		assert_eq(s.block_at(x, h - 2, z), BlockIds.CANTALOUPE_ICE)
		cells[Vector2i(floori(x / float(TritonTerrain.MELON_CELL)), floori(z / float(TritonTerrain.MELON_CELL)))] = true
	assert_gt(dimples, 3000, "mostly dimples")
	assert_between(float(ridges) / (dimples + ridges), 0.08, 0.4, "ridges between them")
	assert_gte(tops.size(), 3, "dimples sink below their ridges")
	assert_gt(cells.size(), 30, "many dimples")
	for corner: Vector2i in [Vector2i(-80, -80), Vector2i(-120, -40), Vector2i(-40, -140)]:
		var site := t.melon_site_near(start + corner)
		var mid := s.height_at(site.x, site.y)
		var hi := mid
		for n: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			for d in range(0, 23):   # from a dimple's middle out to its ridges the ground rises
				hi = maxi(hi, s.height_at(site.x + n.x * d, site.y + n.y * d))
		assert_gte(hi - mid, 2, "a dimple: its middle lower than its ridges (%d .. %d)" % [mid, hi])
		assert_eq(s.triton_kind(site.x, site.y), TritonTerrain.DIMPLE)


func test_the_frozen_lake_is_flat_ice_lava_with_terraced_walls() -> void:
	for seed in SEEDS:
		var s := _triton(seed)
		var t := s.triton
		var c := t.lake_centre()
		assert_eq(s.triton_kind(c.x, c.y), TritonTerrain.LAKE, "seed %d" % seed)
		for d in range(0, TritonTerrain.LAKE_R - TritonTerrain.LAKE_WOBBLE - 1, 3):
			assert_eq(s.height_at(c.x + d, c.y), TritonTerrain.LAKE_Y, "seed %d: a flat floor (%d)" % [seed, d])
			assert_eq(s.triton_kind(c.x - d, c.y), TritonTerrain.LAKE)
		assert_eq(s.block_at(c.x, TritonTerrain.LAKE_Y - 1, c.y), BlockIds.ICE_LAVA, "frozen ice lava")
		assert_eq(s.block_at(c.x, TritonTerrain.LAKE_Y - 4, c.y), BlockIds.ICE_LAVA, "layers of it")
		var rim := TritonTerrain.LAKE_R + TritonTerrain.LAKE_WOBBLE + TritonTerrain.STEPS * TritonTerrain.STEP_W + 1
		var walls := 0
		var last := TritonTerrain.LAKE_Y
		for d in range(TritonTerrain.LAKE_R - TritonTerrain.LAKE_WOBBLE, rim):
			var h := s.height_at(c.x, c.y - d)
			assert_gte(h, last, "seed %d: the walls step up to the rim" % seed)
			last = h
			if s.triton_kind(c.x, c.y - d) == TritonTerrain.TERRACE:
				walls += 1
				assert_eq(s.block_at(c.x, h - 1, c.y - d), BlockIds.ICE_LAVA)
		assert_gte(walls, TritonTerrain.STEPS, "seed %d: terraces" % seed)
		assert_gte(last, TritonTerrain.LAKE_Y + TritonTerrain.STEPS - 1, "seed %d: up to the rim" % seed)


func test_one_of_tritons_few_craters() -> void:
	var s := _triton()
	var t := s.triton
	var c := t.crater_centre()
	assert_eq(s.triton_kind(c.x, c.y), TritonTerrain.CRATER)
	var floor_h := s.height_at(c.x, c.y)
	var rim_h := s.height_at(c.x + t.crater_radius(), c.y)
	assert_gte(rim_h - floor_h, 3, "a bowl (%d .. %d)" % [floor_h, rim_h])
	assert_eq(s.block_at(c.x, floor_h - 1, c.y), BlockIds.NITROGEN_ICE, "dug through the frost into nitrogen ice")
	var craters := 0
	for i in 20000:
		var x := (i % 200) * 8 - 800
		var z := (i / 200) * 8 - 800
		if s.triton_kind(x, z) == TritonTerrain.CRATER:
			craters += 1
	assert_lt(craters, 60, "very few craters: Triton's ground is young (%d columns)" % craters)


func test_every_step_is_one_triton_jump_and_a_walk_on_the_plains() -> void:
	for seed in SEEDS:
		var s := _triton(seed)
		var t := s.triton
		var pts: Array[Vector2i] = []
		for i in 3000:
			pts.append(Vector2i((i * 13) % 1400 - 700, (i * 7) % 1400 - 700))
		for c: Vector2i in [t.lake_centre(), t.crater_centre(), t.first_geyser(), s.spawn_column(),
				t.first_melon_toward(s.spawn_column()), Vector2i(t.first_geyser().x, roundi(t.cap_edge(t.first_geyser().x)))]:
			for dz in range(-70, 71, 4):
				for dx in range(-70, 71):
					pts.append(c + Vector2i(dx, dz))
		for q in pts:
			for n: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
				var a := s.ground_at(q.x, q.y)
				var b := s.ground_at(q.x + n.x, q.y + n.y)
				assert_lte(absi(a - b), TritonTerrain.MAX_STEP, "seed %d (%d, %d)" % [seed, q.x, q.y])
				var ka := s.triton_kind(q.x, q.y)
				var kb := s.triton_kind(q.x + n.x, q.y + n.y)
				if _walk(ka) and _walk(kb):
					assert_lte(absi(a - b), 1, "seed %d (%d, %d): a walk (%d, %d)" % [seed, q.x, q.y, ka, kb])


func _walk(k: int) -> bool:
	return k == TritonTerrain.FROST or TritonTerrain.is_cap(k) or TritonTerrain.is_melon(k) or k == TritonTerrain.LAKE \
		or k == TritonTerrain.TERRACE


func test_the_neptune_lookout_stands_north_east_of_the_pad() -> void:
	for seed in SEEDS:
		var s := _triton(seed)
		var t := s.triton
		var sp := s.spawn_column()
		var lk := t.lookout
		assert_ne(lk, TritonTerrain.NONE)
		assert_gt(lk.x, sp.x + 5, "seed %d: east of the pad ..." % seed)
		assert_lt(lk.y, sp.y - 5, "seed %d: ... and north: towards Neptune" % seed)
		assert_between(Vector2(lk - sp).length(), 11.0, 15.0, "seed %d: a few steps from it" % seed)
		assert_true(s.tree_at(lk.x, lk.y), "its ground is kept: nothing else stands there")
		var y := t.lookout_y
		assert_eq(t.built_at(Vector3i(lk.x, y - 1, lk.y)), BlockIds.CAP_BRICK, "a round floor of cap bricks")
		assert_eq(t.built_at(Vector3i(lk.x, y, lk.y)), BlockIds.TRUSS, "a stand")
		assert_eq(t.built_at(Vector3i(lk.x, y + 2, lk.y)), BlockIds.TELESCOPE, "its telescope")
		assert_eq(t.built_at(Vector3i(lk.x + 1, y + 3, lk.y - 1)), BlockIds.TELESCOPE, "looking north-east and up at Neptune")
		assert_eq(t.built_at(Vector3i(lk.x - 1, y + 1, lk.y + 1)), BlockIds.NEPTUNE_GLOBE, "a globe of Neptune")
		assert_eq(t.built_at(Vector3i(lk.x + 1, y, lk.y + 1)), BlockIds.BLUE_BEACON, "a blue beacon")
		assert_eq(t.built_at(Vector3i(lk.x + 6, y, lk.y)), -1)
		for dz in range(-2, 3):
			for dx in range(-2, 3):
				if dx * dx + dz * dz <= 5:
					assert_lte(y - s.height_at(lk.x + dx, lk.y + dz), 2, "a step or two up onto its floor")


func test_boulders_on_the_frost_and_nitrogen_crystals_on_the_cap() -> void:
	var s := _triton()
	var boulders := 0
	var crystals := 0
	for i in 80000:   # a grid over 1800 × 1800 blocks
		var x := (i % 400) * 4 - 600
		var z := (i / 400) * 9 - 900
		if not s.tree_at(x, z) or s.triton.on_lookout(x, z):
			continue
		var id := s.feature_at(x, s.height_at(x, z), z)
		var k := s.triton_kind(x, z)
		if id == BlockIds.WATER_ICE:
			boulders += 1
			assert_true(k == TritonTerrain.FROST or TritonTerrain.is_melon(k), "boulders on the frost and the dimples")
		elif id == BlockIds.NITROGEN_CRYSTAL:
			crystals += 1
			assert_true(k == TritonTerrain.CAP or k == TritonTerrain.MOTTLE, "crystals on the cap's ice")
		assert_false(k == TritonTerrain.VENT or k == TritonTerrain.SPOT or k == TritonTerrain.LAKE,
			"nothing stands on a vent or the lake's smooth ice")
	assert_gt(boulders, 20, "boulders of water ice")
	assert_gt(crystals, 20, "glowing nitrogen crystals")


func test_the_sights_where_a_child_learns_a_fact() -> void:
	var s := _triton()
	var t := s.triton
	var sp := s.spawn_column()
	assert_eq(s.sight_at(t.lookout.x, t.lookout.y), &"lookout", "the Neptune Lookout by the pad")
	var g := t.first_geyser()
	assert_eq(s.sight_at(g.x, g.y), &"geyser")
	assert_eq(s.sight_at(g.x + 2, g.y), &"geyser", "its ring of dust too")
	var st := t.streak_centre(g, 16.0)
	assert_eq(s.sight_at(st.x, st.y), &"trail")
	var cap := t.cap_point_south_of(sp)
	assert_eq(s.sight_at(cap.x, cap.y), &"cap")
	var melon := t.first_melon_toward(sp)
	assert_eq(s.sight_at(melon.x, melon.y), &"melon")
	assert_eq(s.sight_at(t.lake_centre().x, t.lake_centre().y), &"lake")
	assert_eq(s.sight_at(t.crater_centre().x, t.crater_centre().y), &"crater")
	assert_eq(s.sight_at(sp.x, sp.y), &"", "nothing at the pad")
	var ids: Array = s.sights().map(func(e: Dictionary) -> StringName: return e.id)
	assert_eq(ids, [&"lookout", &"geyser", &"trail", &"cap", &"melon", &"lake", &"crater"], "MY MAP shows all seven")
	for e: Dictionary in s.sights():
		var at: Vector3 = e.pos
		assert_eq(s.sight_at(floori(at.x), floori(at.z)), e.id, "%s's mark is on it" % e.id)


func test_the_same_seed_is_the_same_triton() -> void:
	var a := _triton()
	var b := _triton()
	assert_eq(a.spawn_column(), b.spawn_column())
	assert_eq(a.triton.first_geyser(), b.triton.first_geyser())
	assert_eq(a.triton.lake_centre(), b.triton.lake_centre())
	for i in 50:
		assert_eq(a.height_at(i * 13, -i * 7), b.height_at(i * 13, -i * 7))
		assert_eq(a.height_at(i * 11, 150 + i * 5), b.height_at(i * 11, 150 + i * 5))
	var other := _triton(777)
	assert_ne(other.triton.lake_centre(), a.triton.lake_centre(), "another seed, another Triton")


## The generator's path (columns) is exactly the reference (column), over a block.
func test_the_fast_columns_are_the_reference() -> void:
	var s := _triton()
	var t := s.triton
	for c: Vector2i in [t.lake_centre() + Vector2i(TritonTerrain.LAKE_R, 0), t.first_geyser(), t.crater_centre(),
			t.first_melon_toward(s.spawn_column()), s.spawn_column(), t.streak_centre(t.first_geyser(), 20.0)]:
		var x0 := c.x - 8
		var z0 := c.y - 8
		var cols := s.triton_columns(x0, z0, 16, 16)
		var g: PackedInt32Array = cols[0]
		var k: PackedByteArray = cols[1]
		for z in 16:
			for x in 16:
				assert_eq(g[x + z * 16], s.ground_at(x0 + x, z0 + z), "(%d, %d)" % [x0 + x, z0 + z])
				assert_eq(k[x + z * 16], s.triton_kind(x0 + x, z0 + z))
