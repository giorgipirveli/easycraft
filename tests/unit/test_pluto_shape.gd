extends GutTest
## Cosmos: Pluto (world 26, spec §21b.2): its terrain as pure rules (SpaceShape with planet PLUTO; the regions in
## PlutoTerrain), from what New Horizons saw in 2015. The heart (Tombaugh Regio) a walk east of the landing pad: its west
## half a flat plain of pale nitrogen ice (Sputnik Planitia) cut into slowly churning cells with darker edges, floating
## hills of water ice on the cells' edges in its western part (lighter than nitrogen ice: icebergs), its east half the
## bright side of methane snow; the ice mountains (jumbled blocks of water ice, snowy on top) along the plain's
## south-west shore; the red-brown lands (tholins) to the west with methane frost on their hilltops and crater rims; the
## peach-tan uplands everywhere else; the Charon Lookout a few steps west of the pad. Every step is one a Pluto jump
## climbs; the plain, its rim and the uplands step a block at most.

const SEED := 12345
const SEEDS: Array[int] = [12345, 77, 777, 42]


func _pluto(seed: int = SEED) -> SpaceShape:
	return SpaceShape.new(seed, SpaceShape.PLUTO)


func _jump() -> float:
	return Player.JUMP_VELOCITY * Player.JUMP_VELOCITY / (2.0 * Player.GRAVITY * 0.063)


func test_pluto_is_a_space_planet_with_its_terrain() -> void:
	assert_has(SpaceShape.PLANETS, SpaceShape.PLUTO)
	var s := _pluto()
	assert_eq(s.planet, SpaceShape.PLUTO)
	assert_not_null(s.pluto, "Pluto's regions")
	assert_null(s.titan)
	assert_null(s.rings)
	assert_null(s.mercury)
	assert_null(SpaceShape.new(SEED, SpaceShape.TITAN).pluto, "Titan has none")
	assert_lt(float(PlutoTerrain.MAX_STEP), _jump() - 4.0, "a jump at 0.063 gravity reaches ~27 blocks")


func test_heights_stay_between_the_floor_and_the_sky() -> void:
	var s := _pluto()
	var p := s.pluto
	var points: Array[Vector2i] = [p.peak_centre(), p.heart_west(), p.bright_centre()]
	for i in 900:
		points.append(Vector2i((i * 37) % 2400 - 1200, (i * 91) % 2400 - 1200))
	for q in points:
		var h := s.height_at(q.x, q.y)
		assert_gt(h, MeadowsShape.SEA_LEVEL + 2, "(%d, %d): over the old sea level" % [q.x, q.y])
		assert_lt(h, SpaceGenerator.SKY_TOP - 40, "(%d, %d): far under the sky's limit" % [q.x, q.y])
		assert_false(s.is_river(q.x, q.y), "no liquid on Pluto: every column is dry land")


## The heart: its west half the plain, its east half the bright side, its point to the south, a walk east of the pad.
func test_the_heart_lies_east_of_the_pad_its_west_half_the_plain() -> void:
	for seed in SEEDS:
		var s := _pluto(seed)
		var p := s.pluto
		var sp := s.spawn_column()
		for q: Vector2 in [Vector2(-0.3, 0.75), Vector2(-0.25, 0.95), Vector2(-0.1, 0.3), Vector2(-0.4, 0.55)]:
			var w := p.heart_to_world(q)
			var k := s.pluto_kind(roundi(w.x), roundi(w.y))
			assert_true(PlutoTerrain.is_plain(k) or k == PlutoTerrain.HILL or k == PlutoTerrain.MOUNTAIN
				or k == PlutoTerrain.PEAK, "seed %d: the heart's west half %s is the plain (%d)" % [seed, q, k])
		for q: Vector2 in [Vector2(0.3, 0.75), Vector2(0.25, 0.95), Vector2(0.2, 0.5)]:
			var w := p.heart_to_world(q)
			assert_eq(s.pluto_kind(roundi(w.x), roundi(w.y)), PlutoTerrain.BRIGHT,
				"seed %d: the heart's east half %s is its bright side" % [seed, q])
		for q: Vector2 in [Vector2(-0.75, 0.75), Vector2(0.75, 0.75), Vector2(0.0, -0.15), Vector2(0.0, 1.3)]:
			var w := p.heart_to_world(q)
			var k := s.pluto_kind(roundi(w.x), roundi(w.y))
			assert_false(PlutoTerrain.is_plain(k) or k == PlutoTerrain.BRIGHT, "seed %d: %s is outside the heart" % [seed, q])
		var west := p.heart_west()
		assert_between(float(west.x - sp.x), 60.0, 140.0, "seed %d: its west shore a walk east of the pad" % seed)
		var point := p.heart_to_world(Vector2.ZERO)
		var top := p.heart_to_world(Vector2(-0.25, 1.1))
		assert_gt(point.y, top.y + 300.0, "seed %d: the heart's point to the south (+z), its lobes to the north" % seed)


func test_the_plain_is_flat_nitrogen_ice_in_cells() -> void:
	var s := _pluto()
	var p := s.pluto
	var plain := 0
	var edges := 0
	var sites := {}
	var c := p.heart_to_world(Vector2(-0.3, 0.7))
	for i in 4000:
		var x := roundi(c.x) + (i * 17) % 160 - 80
		var z := roundi(c.y) + (i * 29) % 240 - 120
		var k := s.pluto_kind(x, z)
		if not PlutoTerrain.is_plain(k):
			continue
		plain += 1
		assert_eq(s.height_at(x, z), PlutoTerrain.PLAIN_Y, "(%d, %d): the plain is flat" % [x, z])
		var h := s.height_at(x, z)
		assert_eq(s.block_at(x, h - 1, z), BlockIds.CELL_EDGE if k == PlutoTerrain.EDGE else BlockIds.NITROGEN_ICE)
		assert_eq(s.block_at(x, h - 5, z), BlockIds.NITROGEN_ICE, "nitrogen ice fills the basin")
		assert_eq(s.block_at(x, h - PlutoTerrain.N2_DEPTH - 3, z), BlockIds.WATER_ICE, "water ice under it")
		assert_eq(s.block_at(x, -5, z), BlockIds.WATER_ICE, "water ice deep down")
		assert_eq(s.block_at(x, MeadowsShape.WORLD_BOTTOM, z), BlockIds.BEDROCK)
		if k == PlutoTerrain.EDGE:
			edges += 1
		sites[Vector2i(floori(x / float(PlutoTerrain.CELL)), floori(z / float(PlutoTerrain.CELL)))] = true
	assert_gt(plain, 2000, "a wide plain")
	var share := float(edges) / plain
	assert_between(share, 0.04, 0.25, "thin darker edges between the cells (%.2f)" % share)
	assert_gt(sites.size(), 12, "many cells")


func test_floating_hills_of_water_ice_sit_on_the_cells_edges_in_the_west() -> void:
	for seed in SEEDS:
		var s := _pluto(seed)
		var p := s.pluto
		var hills := p.hills()
		assert_gte(hills.size(), 4, "seed %d: floating hills on the plain" % seed)
		var on_edge := 0
		for hl: Vector4 in hills:
			var x := int(hl.x)
			var z := int(hl.y)
			assert_eq(s.pluto_kind(x, z), PlutoTerrain.HILL, "seed %d: (%d, %d)" % [seed, x, z])
			var inside := -p.plain_sd(hl.x, hl.y)
			assert_between(inside, PlutoTerrain.HILL_SHORE, PlutoTerrain.HILL_BAND, "seed %d: in the plain's west part" % seed)
			if p._cell_kind(hl.x, hl.y) == PlutoTerrain.EDGE:
				on_edge += 1
			var g := s.ground_at(x, z)
			assert_between(g - PlutoTerrain.PLAIN_Y, 2, PlutoTerrain.HILL_H.y, "a small hill")
			assert_eq(s.block_at(x, g - 1, z), BlockIds.WATER_ICE, "water ice on top")
			assert_eq(s.block_at(x, PlutoTerrain.PLAIN_Y - 1, z), BlockIds.WATER_ICE, "an iceberg: its ice goes down into the plain")
			var r := int(hl.z) + 1
			var kr := s.pluto_kind(x + r, z)
			if PlutoTerrain.is_plain(kr):
				assert_eq(s.block_at(x + r, PlutoTerrain.PLAIN_Y - 1, z), PlutoTerrain.top_block(kr), "the plain round it")
				assert_eq(s.block_at(x + r, PlutoTerrain.PLAIN_Y - 3, z), BlockIds.NITROGEN_ICE, "nitrogen ice round it")
		assert_gt(on_edge, hills.size() * 0.7, "seed %d: pushed to the cells' edges (%d of %d)" % [seed, on_edge, hills.size()])


func test_the_ice_mountains_line_the_plains_south_west_shore() -> void:
	for seed in SEEDS:
		var s := _pluto(seed)
		var p := s.pluto
		var sp := s.spawn_column()
		var pk := p.peak_centre()
		var d := Vector2(pk - sp).length()
		assert_between(d, 150.0, 330.0, "seed %d: a walk from the pad (%.0f)" % [seed, d])
		assert_gt(pk.x, sp.x, "seed %d: to the east" % seed)
		assert_gt(pk.y, sp.y, "seed %d: and to the south, by the heart's point" % seed)
		assert_eq(s.pluto_kind(pk.x, pk.y), PlutoTerrain.PEAK)
		var rise := s.height_at(pk.x, pk.y) - roundi(p.uplands_height(pk.x, pk.y))
		assert_gte(rise, PlutoTerrain.PEAK_H - 8, "seed %d: its top rises high (%d)" % [seed, rise])
		assert_eq(s.block_at(pk.x, s.height_at(pk.x, pk.y) - 1, pk.y), BlockIds.METHANE_SNOW, "snowy on top")
		assert_eq(s.block_at(pk.x, s.height_at(pk.x, pk.y) - 6, pk.y), BlockIds.WATER_ICE, "water ice inside")
	var s := _pluto()
	var p := s.pluto
	var tops := {}
	var blocks := 0
	var by_plain := 0
	var flat := 0
	var pk := p.peak_centre()
	for i in 6000:
		var x := pk.x + (i * 13) % 200 - 100
		var z := pk.y + (i * 7) % 200 - 100
		var k := s.pluto_kind(x, z)
		if k != PlutoTerrain.MOUNTAIN and k != PlutoTerrain.PEAK:
			continue
		blocks += 1
		var h := s.height_at(x, z)
		tops[h] = true
		if k == PlutoTerrain.MOUNTAIN:
			assert_eq(s.block_at(x, h - 1, z), BlockIds.WATER_ICE, "water ice blocks")
		if s.pluto_kind(x + 1, z) == k and s.height_at(x + 1, z) == h:
			flat += 1
		for n: Vector2i in [Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, 3), Vector2i(0, -3)]:
			if PlutoTerrain.is_plain(s.pluto_kind(x + n.x, z + n.y)):
				by_plain += 1
	assert_gt(blocks, 800, "a range of mountains (%d)" % blocks)
	assert_gt(tops.size(), 12, "jumbled blocks of many heights (%d)" % tops.size())
	assert_gt(flat, blocks / 2, "each block flat-topped (%d of %d)" % [flat, blocks])
	assert_gt(by_plain, 10, "rising right out of the plain's shore")


func test_the_red_brown_lands_lie_west_with_snowy_tops_and_craters() -> void:
	for seed in SEEDS:
		var s := _pluto(seed)
		var sp := s.spawn_column()
		var dark := s.pluto.first_dark_west_of(sp)
		assert_ne(dark, PlutoTerrain.NONE, "seed %d" % seed)
		assert_between(float(sp.x - dark.x), 60.0, 200.0, "seed %d: a walk west of the pad" % seed)
	var s := _pluto()
	var counts := {}
	for i in 8000:
		var x := -250 - (i * 17) % 500
		var z := (i * 31) % 800 - 400
		var k := s.pluto_kind(x, z)
		counts[k] = int(counts.get(k, 0)) + 1
		var h := s.height_at(x, z)
		match k:
			PlutoTerrain.DARK:
				assert_eq(s.block_at(x, h - 1, z), BlockIds.THOLIN_DUST, "red-brown tholin dust")
				assert_eq(s.block_at(x, h - 2, z), BlockIds.THOLIN_DUST)
				assert_eq(s.block_at(x, h - 5, z), BlockIds.RED_ICE, "red-stained ice under it")
			PlutoTerrain.SNOWCAP:
				assert_eq(s.block_at(x, h - 1, z), BlockIds.METHANE_SNOW, "methane frost on the tops")
			PlutoTerrain.CRATER:
				assert_eq(s.block_at(x, h - 1, z), BlockIds.RED_ICE, "a crater's red ice")
	assert_gt(int(counts.get(PlutoTerrain.DARK, 0)), 4000, "mostly red-brown dust")
	assert_gt(int(counts.get(PlutoTerrain.SNOWCAP, 0)), 80, "snowy hilltops and crater rims")
	assert_gt(int(counts.get(PlutoTerrain.CRATER, 0)), 80, "old craters")


func test_every_step_is_one_pluto_jump_and_the_plains_step_one_block() -> void:
	for seed in SEEDS:
		var s := _pluto(seed)
		var p := s.pluto
		var pts: Array[Vector2i] = []
		for i in 3000:
			pts.append(Vector2i((i * 13) % 1400 - 700, (i * 7) % 1400 - 700))
		for c: Vector2i in [p.peak_centre(), p.heart_west(), s.spawn_column(), p.nearest_hill(s.spawn_column()),
				p.first_dark_west_of(s.spawn_column())]:
			for dz in range(-60, 61, 4):
				for dx in range(-60, 61):
					pts.append(c + Vector2i(dx, dz))
		for q in pts:
			for n: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
				var a := s.ground_at(q.x, q.y)
				var b := s.ground_at(q.x + n.x, q.y + n.y)
				assert_lte(absi(a - b), PlutoTerrain.MAX_STEP, "seed %d (%d, %d)" % [seed, q.x, q.y])
				var ka := s.pluto_kind(q.x, q.y)
				var kb := s.pluto_kind(q.x + n.x, q.y + n.y)
				var gentle := [PlutoTerrain.UPLANDS, PlutoTerrain.RIM, PlutoTerrain.PLAIN, PlutoTerrain.EDGE, PlutoTerrain.BRIGHT]
				if gentle.has(ka) and gentle.has(kb):
					assert_lte(absi(a - b), 1, "seed %d (%d, %d): the plain, its rim and the uplands step one block" % [
						seed, q.x, q.y])
				if PlutoTerrain.is_dark(ka) and PlutoTerrain.is_dark(kb):
					assert_lte(absi(a - b), 2, "seed %d (%d, %d): rolling red-brown hills" % [seed, q.x, q.y])


func test_the_pad_is_on_calm_uplands_between_the_heart_and_the_red_brown_lands() -> void:
	for seed in SEEDS:
		var s := _pluto(seed)
		var p := s.pluto
		var sp := s.spawn_column()
		assert_eq(s.pluto_kind(sp.x, sp.y), PlutoTerrain.UPLANDS, "seed %d" % seed)
		assert_gt(p.plain_sd(sp.x, sp.y), 50.0, "seed %d: the plain's shore a walk away" % seed)
		assert_false(p.near_mountain(float(sp.x), float(sp.y), 60.0), "seed %d" % seed)
		assert_gt(float(sp.x) - p.dark_edge(float(sp.y)), 60.0, "seed %d: the red-brown lands a walk west" % seed)


func test_the_charon_lookout_stands_west_of_the_pad() -> void:
	for seed in SEEDS:
		var s := _pluto(seed)
		var p := s.pluto
		var sp := s.spawn_column()
		var lk := p.lookout
		assert_ne(lk, PlutoTerrain.NONE)
		assert_lt(lk.x, sp.x - 8, "seed %d: west of the pad, towards Charon" % seed)
		assert_lte(Vector2(lk - sp).length(), 14.0, "seed %d: a few steps from it" % seed)
		assert_true(s.tree_at(lk.x, lk.y), "its ground is kept: nothing else stands there")
		var y := p.lookout_y
		assert_eq(p.built_at(Vector3i(lk.x, y - 1, lk.y)), BlockIds.FROST_BRICK, "a round floor of frost bricks")
		assert_eq(p.built_at(Vector3i(lk.x, y, lk.y)), BlockIds.TRUSS, "a stand")
		assert_eq(p.built_at(Vector3i(lk.x, y + 2, lk.y)), BlockIds.TELESCOPE, "its telescope")
		assert_eq(p.built_at(Vector3i(lk.x - 2, y + 3, lk.y)), BlockIds.TELESCOPE, "looking west and up at Charon")
		assert_eq(p.built_at(Vector3i(lk.x + 1, y + 1, lk.y + 1)), BlockIds.CHARON_GLOBE, "a globe of Charon")
		assert_eq(p.built_at(Vector3i(lk.x + 6, y, lk.y)), -1)
		for dz in range(-2, 3):
			for dx in range(-2, 3):
				if dx * dx + dz * dz <= 5:
					assert_lte(y - s.height_at(lk.x + dx, lk.y + dz), 2, "a step or two up onto its floor")


func test_boulders_on_the_uplands_and_frost_crystals_on_the_bright_side() -> void:
	var s := _pluto()
	var boulders := 0
	var crystals := 0
	for i in 80000:   # a grid over 1800 × 1800 blocks
		var x := (i % 400) * 4 - 600
		var z := (i / 400) * 9 - 900
		if not s.tree_at(x, z) or s.pluto.on_lookout(x, z):
			continue
		var id := s.feature_at(x, s.height_at(x, z), z)
		var k := s.pluto_kind(x, z)
		if id == BlockIds.WATER_ICE:
			boulders += 1
			assert_true(k == PlutoTerrain.UPLANDS or PlutoTerrain.is_dark(k), "boulders on the uplands and dark lands")
		elif id == BlockIds.FROST_CRYSTAL:
			crystals += 1
			assert_eq(k, PlutoTerrain.BRIGHT, "frost crystals on the bright side")
		assert_false(PlutoTerrain.is_plain(k), "nothing stands on the plain's smooth ice")
	assert_gt(boulders, 20, "boulders of water ice")
	assert_gt(crystals, 4, "glowing frost crystals")


func test_the_sights_where_a_child_learns_a_fact() -> void:
	var s := _pluto()
	var p := s.pluto
	var sp := s.spawn_column()
	assert_eq(s.sight_at(p.lookout.x, p.lookout.y), &"lookout", "the Charon Lookout by the pad")
	var shore := p.plain_shore_toward(sp)
	assert_eq(s.sight_at(shore.x, shore.y), &"heart", "on the heart's plain")
	var hill := p.nearest_hill(sp)
	assert_eq(s.sight_at(hill.x, hill.y), &"hills")
	assert_eq(s.sight_at(p.peak_centre().x, p.peak_centre().y), &"mountains")
	var dark := p.first_dark_west_of(sp)
	assert_eq(s.sight_at(dark.x, dark.y), &"dark")
	assert_eq(s.sight_at(p.bright_centre().x, p.bright_centre().y), &"bright")
	assert_eq(s.sight_at(sp.x, sp.y), &"", "nothing at the pad")
	var ids: Array = s.sights().map(func(e: Dictionary) -> StringName: return e.id)
	assert_eq(ids, [&"lookout", &"heart", &"hills", &"mountains", &"dark", &"bright"], "MY MAP shows all six")
	for e: Dictionary in s.sights():
		var at: Vector3 = e.pos
		assert_eq(s.sight_at(floori(at.x), floori(at.z)), e.id, "%s's mark is on it" % e.id)


func test_the_same_seed_is_the_same_pluto() -> void:
	var a := _pluto()
	var b := _pluto()
	assert_eq(a.spawn_column(), b.spawn_column())
	assert_eq(a.pluto.peak_centre(), b.pluto.peak_centre())
	assert_eq(a.pluto.hills(), b.pluto.hills())
	for i in 50:
		assert_eq(a.height_at(i * 13, -i * 7), b.height_at(i * 13, -i * 7))
	var other := _pluto(777)
	assert_ne(other.pluto.heart_west(), a.pluto.heart_west(), "another seed, another Pluto")


## The generator's path (columns) is exactly the reference (column), over a block.
func test_the_fast_columns_are_the_reference() -> void:
	var s := _pluto()
	var p := s.pluto
	for c: Vector2i in [p.peak_centre(), p.heart_west(), p.nearest_hill(s.spawn_column()), Vector2i(-160, 30)]:
		var x0 := c.x - 8
		var z0 := c.y - 8
		var cols := s.pluto_columns(x0, z0, 16, 16)
		var g: PackedInt32Array = cols[0]
		var k: PackedByteArray = cols[1]
		for z in 16:
			for x in 16:
				assert_eq(g[x + z * 16], s.ground_at(x0 + x, z0 + z), "(%d, %d)" % [x0 + x, z0 + z])
				assert_eq(k[x + z * 16], s.pluto_kind(x0 + x, z0 + z))
