extends GutTest
## Cosmos: Saturn's rings (world 25, spec §21b.2): the terrain as pure rules (SpaceShape with planet RINGS; the rings in
## RingsTerrain). Countless chunks of water ice float in a thin sheet, in bands with gaps (NASA): from north (towards
## Saturn) to south the C ring's darker, dustier chunks, the bright, dense B ring (the landing chunk with the pad, the
## Ring Station and the Saturn scope; the aliens' camp chunk, the show chunk, the explorer's chunk, the edge chunk), the
## Cassini Division (a wide gap with a few small lumps), the A ring with the Encke Gap (where Pan, a walnut-shaped little
## moon, sweeps a clear lane) and the Keeler Gap, the thin braided F ring, and space. Every chunk's top floats high over
## the void line (a fall is caught long before it), and at 0.05 of Earth's gravity a jump carries a child far.

const SEED := 12345
const SEEDS: Array[int] = [12345, 77, 777, 42]


func _rings(seed: int = SEED) -> SpaceShape:
	return SpaceShape.new(seed, SpaceShape.RINGS)


func test_the_rings_are_a_space_planet_with_their_own_rules() -> void:
	assert_has(SpaceShape.PLANETS, SpaceShape.RINGS)
	var s := _rings()
	assert_eq(s.planet, SpaceShape.RINGS)
	assert_not_null(s.rings, "the rings' rules")
	assert_null(s.venus)
	assert_null(SpaceShape.new(SEED, SpaceShape.VENUS).rings, "Venus has none")
	assert_eq(s.rock_ids(), [] as Array[int], "no ore veins in the rings' ice")
	var jump := Player.JUMP_VELOCITY * Player.JUMP_VELOCITY / (2.0 * Player.GRAVITY * 0.05)
	assert_gt(jump, 30.0, "a jump at 0.05 gravity goes very high (%.1f)" % jump)


func test_the_landing_chunk_round_the_pad() -> void:
	for seed in SEEDS:
		var s := _rings(seed)
		var r := s.rings
		var sp := s.spawn_column()
		assert_eq(sp, r.spawn())
		assert_eq(s.height_at(sp.x, sp.y), RingsTerrain.TOP_BASE, "the pad is on the landing chunk")
		assert_eq(s.block_at(sp.x, RingsTerrain.TOP_BASE - 1, sp.y), BlockIds.LANDING_PAD)
		assert_eq(s.block_at(sp.x, RingsTerrain.TOP_BASE, sp.y), BlockIds.AIR)
		assert_eq(s.block_at(sp.x + 5, RingsTerrain.TOP_BASE - 1, sp.y), BlockIds.RING_FROST, "a frosty top")
		assert_eq(s.block_at(sp.x + 5, RingsTerrain.TOP_BASE - 3, sp.y), BlockIds.RING_ICE, "ice under the frost")
		for d: Vector2i in [Vector2i(20, 0), Vector2i(-20, 0), Vector2i(0, 20), Vector2i(0, -20), Vector2i(14, 14)]:
			assert_eq(s.height_at(sp.x + d.x, sp.y + d.y), RingsTerrain.TOP_BASE, "a wide landing chunk (%s)" % d)
		assert_false(s.is_river(sp.x + 12, sp.y), "Tilly's ring is dry land")
		var c := r.column(sp.x, sp.y)
		assert_lt(c[2], RingsTerrain.TOP_BASE - 15, "the landing chunk is deep in its middle")
		assert_eq(s.block_at(sp.x, c[2] - 1, sp.y), BlockIds.AIR, "space under it")


func test_the_fixed_chunks_round_the_landing_chunk() -> void:
	for seed in SEEDS:
		var r := _rings(seed).rings
		var sp := r.spawn()
		for role: StringName in [RingsTerrain.CAMP, RingsTerrain.SHOW]:
			assert_between(Vector2(r.centre(role) - sp).length(), 34.0, 42.0, "%s a short hop from the pad" % role)
		assert_between(Vector2(r.centre(RingsTerrain.EXPLORER) - sp).length(), 44.0, 56.0, "the explorer's chunk")
		var all: Array = r.fixed_chunks()
		for i in all.size():
			for j in range(i + 1, all.size()):
				var a: Array = all[i]
				var b: Array = all[j]
				var gap: float = Vector2(a[1] - b[1], a[2] - b[2]).length() - a[3] - b[3]
				assert_gt(gap, 3.0, "%s and %s never touch (%.1f)" % [a[7], b[7], gap])
		for e: Array in [[RingsTerrain.CAMP, RingsTerrain.LANDING, 8.0], [RingsTerrain.SHOW, RingsTerrain.LANDING, 8.0],
				[RingsTerrain.EXPLORER, RingsTerrain.LANDING, 20.0], [RingsTerrain.EDGE, RingsTerrain.EXPLORER, 25.0]]:
			var a: Array = r.fixed(e[0])
			var b: Array = r.fixed(e[1])
			var gap: float = Vector2(a[1] - b[1], a[2] - b[2]).length() - a[3] - b[3]
			assert_lt(gap, float(e[2]), "%s: a short hop from %s (%.1f)" % [e[0], e[1], gap])
		assert_true(r.camp_spot(r.centre(RingsTerrain.CAMP).x, r.centre(RingsTerrain.CAMP).y))
		assert_true(r.show_spot(r.centre(RingsTerrain.SHOW).x, r.centre(RingsTerrain.SHOW).y))
		assert_false(r.camp_spot(sp.x, sp.y))


## The rings' order from Saturn outward (NASA, NSSDC): C, B, the Cassini Division, A with the Encke and Keeler gaps, F.
func test_the_bands_in_their_real_order() -> void:
	var r := _rings().rings
	var z0 := r.spawn().y
	assert_eq(r.band(z0), RingsTerrain.B_BAND, "the landing is in the bright B ring")
	assert_eq(r.band(z0 + RingsTerrain.C_IN + 5), RingsTerrain.C_BAND, "the C ring nearer Saturn (north)")
	assert_eq(r.band(z0 + RingsTerrain.C_IN - 5), RingsTerrain.NO_BAND, "space between the C ring and Saturn")
	assert_eq(r.band(z0 + RingsTerrain.B_OUT + 5), RingsTerrain.CASSINI_BAND, "the Cassini Division")
	assert_eq(r.band(z0 + RingsTerrain.A_IN + 5), RingsTerrain.A_BAND)
	assert_eq(r.band(z0 + RingsTerrain.ENCKE_IN + 5), RingsTerrain.NO_BAND, "the Encke Gap")
	assert_eq(r.band(z0 + RingsTerrain.KEELER_IN + 2), RingsTerrain.NO_BAND, "the Keeler Gap")
	assert_eq(r.band(z0 + RingsTerrain.F_MID), RingsTerrain.F_BAND, "the thin F ring")
	assert_eq(r.band(z0 + RingsTerrain.F_MID + 40), RingsTerrain.NO_BAND, "space beyond the rings")
	assert_lt(RingsTerrain.C_IN, RingsTerrain.B_IN)
	assert_lt(RingsTerrain.B_OUT - RingsTerrain.B_IN, 300, "a band a child can cross")
	assert_gt(RingsTerrain.A_IN - RingsTerrain.B_OUT, 40, "the Cassini Division is a wide gap")


## The share of each band's ground a child can stand on: the B ring the densest, the C ring sparser, the gaps nearly (the
## Cassini Division: a few lumps) or quite empty, nothing beyond the rings.
func test_the_bands_are_dense_sparse_and_empty() -> void:
	var s := _rings()
	var r := s.rings
	var z0 := r.spawn().y
	var shares := {}
	for e: Array in [["b", RingsTerrain.B_IN + 20, 110], ["c", RingsTerrain.C_IN + 10, 120],
			["cassini", RingsTerrain.B_OUT + 5, 50], ["a", RingsTerrain.A_IN + 10, 100], ["encke", RingsTerrain.ENCKE_IN, 56],
			["beyond", RingsTerrain.F_MID + 20, 200], ["north", RingsTerrain.C_IN - 200, 190]]:
		var solid := 0
		var flat := 0
		var n := 0
		for z in range(z0 + int(e[1]), z0 + int(e[1]) + int(e[2]), 3):
			for x in range(-400, 400, 3):
				if absi(x - r.centre(&"pan").x) < 20 and e[0] == "encke":
					continue
				var c := r.column(x, z)
				n += 1
				if c[0] != RingsTerrain.VOID:
					solid += 1
				if c[0] == RingsTerrain.ICE_FLAT or c[0] == RingsTerrain.DUSTY_FLAT:
					flat += 1
		shares[e[0]] = [float(solid) / n, float(flat) / n]
	gut.p("RINGS shares (solid, flat): %s" % shares)
	assert_gt(shares.b[1], 0.17, "the B ring: plenty of big chunks")
	assert_lt(shares.b[1], 0.6, "... with gaps between them to hop over")
	assert_gt(shares.a[1], 0.12)
	assert_gt(shares.c[1], 0.02)
	assert_lt(shares.c[1], shares.b[1], "the C ring is sparser")
	assert_eq(shares.cassini[1], 0.0, "no big chunk in the Cassini Division")
	assert_gt(shares.cassini[0], 0.005, "... only a few small lumps to hop on")
	assert_eq(shares.encke[0], 0.0, "the Encke Gap is swept clean (but for Pan)")
	assert_eq(shares.beyond[0], 0.0, "space beyond the F ring")
	assert_eq(shares.north[0], 0.0, "space between the C ring and Saturn")


func test_chunks_float_in_a_thin_sheet_high_over_the_void_line() -> void:
	var s := _rings()
	var r := s.rings
	var seen := {}
	for i in 4000:
		var x := (i * 37) % 900 - 450
		var z := r.spawn().y + (i * 53) % 700 - 300
		var c := r.column(x, z)
		seen[c[0]] = int(seen.get(c[0], 0)) + 1
		if c[0] == RingsTerrain.VOID:
			assert_eq(s.height_at(x, z), MeadowsShape.SEA_LEVEL, "no ground here (the Dragon Realm's rule)")
			assert_true(s.is_river(x, z), "no dry land for a spawner in open space")
			for y in [0, 40, 60, 80, -40]:
				assert_eq(s.block_at(x, y, z), BlockIds.AIR, "open space (%d, %d, %d)" % [x, y, z])
			continue
		assert_between(c[1], RingsTerrain.TOP_BASE - RingsTerrain.TOP_SPREAD - 1,
			RingsTerrain.TOP_BASE + RingsTerrain.TOP_SPREAD + 4, "a thin sheet (%d, %d)" % [x, z])
		assert_gt(float(c[1]), RingsTerrain.LIFT_Y + 5.0, "every top high over the void line")
		assert_lt(c[2], c[1], "a chunk has blocks")
		assert_eq(s.height_at(x, z), c[1])
		assert_eq(s.block_at(x, c[1], z), BlockIds.AIR, "air over it")
		assert_eq(s.block_at(x, c[2] - 1, z), BlockIds.AIR, "space under it")
		assert_ne(s.block_at(x, c[2], z), BlockIds.AIR, "its lowest block")
		if not s.pad_at(x, z):
			assert_eq(s.block_at(x, c[1] - 1, z), RingsTerrain.top_block(c[0]))
		assert_eq(s.is_river(x, z), c[0] != RingsTerrain.ICE_FLAT and c[0] != RingsTerrain.DUSTY_FLAT,
			"spawners keep to the big chunks")
	for k in [RingsTerrain.VOID, RingsTerrain.ICE_FLAT, RingsTerrain.DUSTY_FLAT, RingsTerrain.ICE_LUMP,
			RingsTerrain.DUSTY_LUMP, RingsTerrain.ROCK_LUMP]:
		assert_gt(int(seen.get(k, 0)), 3, "some of kind %d" % k)
	assert_gt(int(seen.get(RingsTerrain.VOID, 0)), 1500, "open space between the chunks")


## From dust to house-sized (NASA): pebbles, boulders and big chunks; the big ones round underneath, deepest in the
## middle, with a rounded rim; their tops flat, so a child walks and builds on them.
func test_big_chunks_are_flat_on_top_and_round_underneath() -> void:
	var r := _rings().rings
	var checked := 0
	for bz in range(-3, 4):
		for bx in range(-6, 6):
			var b := r.big_chunk(Vector2i(bx, bz))
			if b.is_empty():
				continue
			checked += 1
			var cx := int(b[1])
			var cz := int(b[2])
			var mid := r.column(cx, cz)
			assert_eq(mid[1], int(b[4]), "its top at the middle")
			for d: Vector2i in [Vector2i(2, 0), Vector2i(0, 2), Vector2i(-2, -1), Vector2i(1, -2)]:
				assert_eq(r.column(cx + d.x, cz + d.y)[1], int(b[4]), "a flat top")
			var edge := r.column(cx + int(b[3]) - 3, cz)
			if int(b[3]) >= 9:
				assert_gt(edge[2], mid[2], "shallower towards the rim (%d vs %d)" % [edge[2], mid[2]])
			assert_lt(mid[2], int(b[4]) - int(b[3]) / 2, "deep in its middle")
			assert_between(int(b[3]), RingsTerrain.BIG_R.x, RingsTerrain.BIG_R.y)
	assert_gt(checked, 10, "big chunks near the pad")


func test_columns_equal_column() -> void:
	for seed in [SEED, 77]:
		var r := _rings(seed).rings
		var z0 := r.spawn().y
		for o: Vector2i in [Vector2i(16, z0 - 16), Vector2i(-48, z0 + 80), Vector2i(96, z0 - 208), Vector2i(0, z0 + 288),
				Vector2i(r.centre(&"pan").x - 8, r.centre(&"pan").y - 8), Vector2i(32, z0 + RingsTerrain.F_MID - 8),
				Vector2i(-160, z0 + 100), Vector2i(320, z0 + 400)]:
			var cols := r.columns(o.x, o.y, 16, 16)
			for z in 16:
				for x in 16:
					var c := r.column(o.x + x, o.y + z)
					var i := x + z * 16
					assert_eq([cols[1][i], cols[0][i], cols[2][i]], [c[0], c[1], c[2]], "(%d, %d)" % [o.x + x, o.y + z])
					if [cols[1][i], cols[0][i], cols[2][i]] != [c[0], c[1], c[2]]:
						return


## Pan, the little moon in the Encke Gap (NASA: walnut-shaped, a ridge round its middle): a round body, the ridge, its
## top a hop above the rings' sheet, its beacon, its sight.
func test_pan_sweeps_the_encke_gap() -> void:
	for seed in SEEDS:
		var s := _rings(seed)
		var r := s.rings
		var p := r.centre(&"pan")
		assert_eq(r.band(p.y), RingsTerrain.NO_BAND, "in the Encke Gap")
		assert_eq(p.y - r.spawn().y, (RingsTerrain.ENCKE_IN + RingsTerrain.ENCKE_OUT) / 2)
		var mid := r.column(p.x, p.y)
		assert_eq(mid[0], RingsTerrain.MOONLET)
		assert_eq(mid[1], RingsTerrain.PAN_Y + RingsTerrain.PAN_HALF + 1, "its round top")
		assert_eq(s.block_at(p.x, mid[1] - 1, p.y), BlockIds.MOONLET_ICE)
		var ridge := r.column(p.x + RingsTerrain.PAN_RIDGE - 1, p.y)
		assert_eq(ridge[0], RingsTerrain.RIDGE, "the ridge sticks out round its middle")
		assert_eq(ridge[1] - ridge[2], 2, "a thin ridge")
		assert_eq(s.block_at(p.x + RingsTerrain.PAN_RIDGE - 1, RingsTerrain.PAN_Y, p.y), BlockIds.RIDGE_DUST)
		assert_eq(r.column(p.x + RingsTerrain.PAN_RIDGE + 2, p.y)[0], RingsTerrain.VOID, "clear round it")
		assert_eq(r.sight_at(p.x, p.y), &"pan")
		assert_eq(r.built_at(Vector3i(p.x, mid[1], p.y)), BlockIds.RING_BEACON, "a beacon on its top")


func test_the_f_ring_is_two_braided_strands() -> void:
	var r := _rings().rings
	var zf := r.spawn().y + RingsTerrain.F_MID
	var lumps := 0
	for x in range(-300, 300):
		for z in range(zf - 8, zf + 9):
			var c := r.column(x, z)
			if c[0] == RingsTerrain.ICE_LUMP:
				lumps += 1
				assert_lte(absi(z - zf), ceili(RingsTerrain.F_SWING) + 3, "on a strand")
	assert_gt(lumps, 300, "a long line of little lumps (%d)" % lumps)
	var f := r.centre(RingsTerrain.F_SPOT)
	assert_eq(r.column(f.x, f.y)[0], RingsTerrain.ICE_FLAT, "a chunk to stand on in the F ring")
	assert_eq(r.sight_at(f.x, f.y - 2), &"f_ring")


func test_the_built_parts_and_the_sights() -> void:
	for seed in SEEDS:
		var s := _rings(seed)
		var r := s.rings
		var sp := r.spawn()
		var y := RingsTerrain.TOP_BASE
		var ids := {}
		for e: Array in r.sight_spots():
			ids[e[0]] = e[1]
			var at: Vector2i = e[1]
			assert_eq(r.sight_at(at.x, at.y), e[0])
			assert_false(s.is_river(at.x, at.y) and e[0] != &"pan", "%s: stand on a chunk there" % e[0])
		assert_eq(ids.keys(), [&"scope", &"station", &"cassini", &"c_ring", &"f_ring", &"pan"])
		var scope: Vector2i = ids.scope
		assert_lt(scope.y, sp.y, "the Saturn scope looks north, towards Saturn")
		assert_eq(r.built_at(Vector3i(sp.x, y + 1, sp.y - RingsTerrain.SCOPE_OUT)), BlockIds.TELESCOPE)
		var sx := -1 if r.flip else 1
		var st := sp + Vector2i(RingsTerrain.STATION.x * sx, RingsTerrain.STATION.y)
		assert_eq(r.built_at(Vector3i(st.x + 1, y + 1, st.y - RingsTerrain.STATION_HALF.y)), BlockIds.STATION_WINDOW)
		assert_eq(r.built_at(Vector3i(st.x, y + 1, st.y - RingsTerrain.STATION_HALF.y)), BlockIds.STATION_PANEL)
		assert_eq(r.built_at(Vector3i(st.x, y, st.y)), BlockIds.AIR, "room inside")
		var door := Vector2i(st.x - RingsTerrain.STATION_HALF.x * sx, st.y)
		assert_eq(r.built_at(Vector3i(door.x, y, door.y)), BlockIds.AIR, "a door towards the pad")
		assert_eq(r.built_at(Vector3i(door.x, y + 2, door.y)), BlockIds.STATION_PANEL)
		assert_lt(Vector2(door - sp).length(), Vector2(st - sp).length(), "the door faces the pad")
		assert_between(Vector2(st - sp).length(), 9.0, 16.0, "beside the pad, clear of the portal, the lander, the robot")
		var edge := r.centre(RingsTerrain.EDGE)
		assert_gt(edge.y, sp.y + 60, "the edge chunk is south, at the Cassini Division")
		var cassini: Vector2i = ids.cassini
		assert_gt(cassini.y, edge.y, "its beacon at its south rim")
		var cr: Vector2i = ids.c_ring
		assert_lt(cr.y - sp.y, -150, "the C ring's sight is north, towards Saturn")
		assert_true(s.tree_at(st.x, st.y), "Tilly and the Totem keep off the station")
		assert_false(s.tree_at(sp.x, sp.y))


func test_the_seed_mirrors_the_fixed_chunks() -> void:
	var flips := {}
	for seed in range(1, 40):
		var r := _rings(seed).rings
		flips[r.flip] = true
		var camp := r.centre(RingsTerrain.CAMP)
		assert_eq(signi(camp.x - r.spawn().x), -1 if r.flip else 1)
	assert_eq(flips.size(), 2, "both ways")


func test_the_same_seed_is_the_same_rings() -> void:
	var a := _rings()
	var b := _rings()
	var other := _rings(777)
	var differ := 0
	for i in 200:
		var x := i * 13 - 900
		var z := a.rings.spawn().y + (i * 29) % 400 - 150
		assert_eq(a.height_at(x, z), b.height_at(x, z))
		if a.height_at(x, z) != other.height_at(x, z):
			differ += 1
	assert_gt(differ, 20, "another seed, other chunks")


func test_no_bedrock_nothing_under_the_rings() -> void:
	var s := _rings()
	var sp := s.spawn_column()
	for y in [MeadowsShape.WORLD_BOTTOM, MeadowsShape.WORLD_BOTTOM + 2, -10, 0, 20]:
		assert_eq(s.block_at(sp.x, y, sp.y), BlockIds.AIR, "open space all the way down (%d)" % y)
	assert_eq(s.deep_block(), BlockIds.AIR)
