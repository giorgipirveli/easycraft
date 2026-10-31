extends GutTest
## Cosmos: Mercury (world 23, spec §21b.2): its terrain as pure rules (SpaceShape with planet MERCURY; the regions in
## MercuryTerrain). Grey dust over grey rock, patches of darker dust, craters everywhere (small bowls with raised rims,
## some young ones throwing bright rays; big craters with terraced walls, a flat floor and a central peak), long cliffs
## (lobate scarps: a raised slab with a gentle back and a terraced face, formed as the planet cooled and shrank; one great
## scarp a walk from the pad), the ice crater far to the north (its floor of ice; every big crater near a pole holds ice),
## and the explorers' thermometer by the landing pad. Every step a child meets is one a Mercury jump climbs.

const SEED := 12345
const SEEDS: Array[int] = [12345, 77, 777, 42]


func _mercury(seed: int = SEED) -> SpaceShape:
	return SpaceShape.new(seed, SpaceShape.MERCURY)


func _jump() -> float:
	return Player.JUMP_VELOCITY * Player.JUMP_VELOCITY / (2.0 * Player.GRAVITY * 0.38)


func test_mercury_is_a_space_planet_with_its_terrain() -> void:
	assert_has(SpaceShape.PLANETS, SpaceShape.MERCURY)
	var s := _mercury()
	assert_eq(s.planet, SpaceShape.MERCURY)
	assert_not_null(s.mercury, "Mercury's regions")
	assert_null(s.titan)
	assert_null(s.io)
	assert_null(s.mars)
	assert_null(SpaceShape.new(SEED, SpaceShape.TITAN).mercury, "Titan has none")
	assert_lt(float(MercuryTerrain.MAX_STEP), _jump() - 0.3, "a jump at 0.38 gravity reaches ~4.4 blocks")


func test_heights_stay_between_the_floor_and_the_sky() -> void:
	var s := _mercury()
	var m := s.mercury
	var points: Array[Vector2i] = [m.ice_centre(), m.great_face_toward(s.spawn_column())]
	for i in 900:
		points.append(Vector2i((i * 37) % 2400 - 1200, (i * 91) % 2400 - 1200))
	for p in points:
		var h := s.height_at(p.x, p.y)
		assert_gt(h, MeadowsShape.SEA_LEVEL + 2, "(%d, %d): over the old sea level" % [p.x, p.y])
		assert_lt(h, SpaceGenerator.SKY_TOP - 40, "(%d, %d): far under the sky's limit" % [p.x, p.y])
		assert_false(s.is_river(p.x, p.y), "no liquid anywhere on Mercury")


func test_grey_dust_over_grey_rock_darker_patches_and_bright_rays() -> void:
	var s := _mercury()
	var kinds := {}
	var checked := 0
	for i in 5000:
		var x := (i * 17) % 1400 - 700
		var z := (i * 11) % 1400 - 700
		var k := s.mercury_kind(x, z)
		kinds[k] = int(kinds.get(k, 0)) + 1
		if not MercuryTerrain.is_plains(k) or s.pad_at(x, z) or s.tree_at(x, z):
			continue
		checked += 1
		var h := s.height_at(x, z)
		var top := {MercuryTerrain.PLAINS: BlockIds.MERCURY_DUST, MercuryTerrain.DARK: BlockIds.DARK_DUST,
			MercuryTerrain.RAY: BlockIds.RAY_DUST}
		assert_eq(s.block_at(x, h - 1, z), top[k], "(%d, %d)" % [x, z])
		assert_eq(s.block_at(x, h - 2, z), BlockIds.MERCURY_DUST, "dust under the top")
		assert_eq(s.block_at(x, h - 8, z), BlockIds.MERCURY_ROCK, "grey rock under the dust")
		assert_eq(s.block_at(x, -5, z), BlockIds.MERCURY_ROCK, "rock deep down")
		assert_eq(s.block_at(x, MeadowsShape.WORLD_BOTTOM, z), BlockIds.BEDROCK)
		assert_eq(s.block_at(x, h, z), BlockIds.AIR)
	assert_gt(checked, 2500, "mostly plains")
	assert_gt(float(kinds.get(MercuryTerrain.DARK, 0)) / 5000.0, 0.04, "patches of darker dust")
	assert_gt(float(kinds.get(MercuryTerrain.RAY, 0)) / 5000.0, 0.004, "bright rays round young craters")
	assert_gt(int(kinds.get(MercuryTerrain.PLAINS, 0)), int(kinds.get(MercuryTerrain.DARK, 0)), "mostly grey dust")


## The generator's fast path (a chunk column's grounds at once) is ground_at, everywhere.
func test_the_fast_grounds_are_ground_at() -> void:
	var s := _mercury()
	var m := s.mercury
	var spots: Array[Vector2i] = [s.spawn_column(), m.great_face_toward(s.spawn_column()), m.ice_centre(),
		m.nearest_crater(s.spawn_column()), Vector2i(333, -517)]
	for c in spots:
		var x0 := c.x - 20
		var z0 := c.y - 20
		var g := s.grounds(x0, z0, 40, 40)
		var k: PackedByteArray = s.mercury_columns(x0, z0, 40, 40)[1]
		for i in g.size():
			var x := x0 + i % 40
			var z := z0 + i / 40
			assert_eq(g[i], s.ground_at(x, z), "(%d, %d)" % [x, z])
			assert_eq(int(k[i]), s.mercury_kind(x, z), "(%d, %d)'s kind" % [x, z])
			if g[i] != s.ground_at(x, z) or int(k[i]) != s.mercury_kind(x, z):
				return


func test_every_step_is_one_mercury_jump() -> void:
	for seed in SEEDS:
		var s := _mercury(seed)
		var m := s.mercury
		var sp := s.spawn_column()
		var spots: Array[Vector2i] = [sp, m.great_face_toward(sp), m.ice_centre(), m.nearest_crater(sp)]
		for cz in range(-3, 3):
			for cx in range(-3, 3):
				var a := m.arc_in_cell(Vector2i(cx, cz))
				if not a.is_empty():
					spots.append(Vector2i(roundi(a[0] + cos(a[3]) * a[2]), roundi(a[1] + sin(a[3]) * a[2])))
				var b := m.big_in_cell(Vector2i(cx, cz))
				if not b.is_empty():
					spots.append(Vector2i(roundi(b[0]), roundi(b[1])))
		var worst := 0
		for c in spots:
			if c == MercuryTerrain.NONE:
				continue
			var g := s.grounds(c.x - 60, c.y - 60, 120, 120)
			for z in 120:
				for x in 120:
					var h := g[x + z * 120]
					if x < 119:
						worst = maxi(worst, absi(h - g[x + 1 + z * 120]))
					if z < 119:
						worst = maxi(worst, absi(h - g[x + (z + 1) * 120]))
		assert_lte(worst, MercuryTerrain.MAX_STEP, "seed %d: every step a Mercury jump (%d)" % [seed, worst])
		assert_gte(worst, 3, "seed %d: cliffs and terraces to climb" % seed)


# --- The long cliffs (lobate scarps) ---

func test_a_great_long_cliff_a_walk_from_the_pad() -> void:
	for seed in SEEDS:
		var s := _mercury(seed)
		var m := s.mercury
		var sp := s.spawn_column()
		var face := m.great_face_toward(sp)
		assert_eq(s.mercury_kind(face.x, face.y), MercuryTerrain.SCARP, "seed %d: the cliff's face" % seed)
		var d := Vector2(face - sp).length()
		assert_between(d, 70.0, 330.0, "seed %d: a walk from the pad (%.0f)" % [seed, d])
		assert_eq(s.block_at(face.x, s.height_at(face.x, face.y) - 1, face.y), BlockIds.MERCURY_ROCK, "rock on its face")
		# out from the slab's back, over the crest and down the face: tall, and a terrace at a time
		var a := m.great_arc()
		var out := (Vector2(face) - Vector2(a[0], a[1])).normalized()
		var top := -1000
		var foot := 1000
		var last := s.height_at(face.x, face.y)
		for r in range(-12, 24):
			var p := Vector2(face) + out * r
			var h := s.height_at(roundi(p.x), roundi(p.y))
			top = maxi(top, h)
			foot = mini(foot, h)
			assert_lte(absi(h - last), MercuryTerrain.MAX_STEP, "seed %d: a terrace at a time" % seed)
			last = h
		assert_gte(top - foot, 12, "seed %d: a tall cliff (%d)" % [seed, top - foot])


func test_the_cliffs_are_long_and_curved_and_there_are_many() -> void:
	var s := _mercury()
	var m := s.mercury
	var a := m.great_arc()
	var faces: Array[Vector2] = []
	for f in [-0.6, 0.0, 0.6]:
		var ang: float = a[3] + a[4] * f
		var r0: float = a[2]
		var phase: float = a[6]
		var d := r0 * (1.0 + MercuryTerrain.LOBE * sin(MercuryTerrain.LOBES * ang + phase)) + 1.0
		var p: Vector2 = Vector2(a[0], a[1]) + Vector2.from_angle(ang) * d
		faces.append(p)
		assert_eq(s.mercury_kind(roundi(p.x), roundi(p.y)), MercuryTerrain.SCARP, "the face goes on (%s)" % p)
	assert_gt(faces[0].distance_to(faces[2]), 150.0, "a long cliff")
	var chord_mid := (faces[0] + faces[2]) * 0.5
	assert_gt(chord_mid.distance_to(faces[1]), 8.0, "curved like a lobe, not straight")
	var arcs := 0
	for cz in range(-4, 4):
		for cx in range(-4, 4):
			if not m.arc_in_cell(Vector2i(cx, cz)).is_empty():
				arcs += 1
	assert_gt(arcs, 8, "long cliffs all over Mercury (%d)" % arcs)


# --- Craters ---

func test_small_craters_everywhere_with_raised_rims() -> void:
	var s := _mercury()
	var found := 0
	var bowls := 0
	for cz in range(-8, 8):
		for cx in range(-8, 8):
			var c := s.mercury.small_in_cell(Vector2i(cx, cz))
			if c.is_empty():
				continue
			var at := Vector2i(roundi(c[0]), roundi(c[1]))
			var r: float = c[2]
			if Vector2(at - s.spawn_column()).length() < SpaceShape.BLEND_RADIUS + r * 1.4:
				continue
			found += 1
			if s.height_at(at.x, at.y) < s.height_at(at.x + roundi(r * 1.1), at.y):
				bowls += 1
	assert_gt(found, 60, "craters everywhere")
	assert_gt(float(bowls) / found, 0.85, "lower in the middle than at the rim")


func test_big_craters_have_terraced_walls_a_flat_floor_and_a_central_peak() -> void:
	var s := _mercury()
	var m := s.mercury
	var big := 0
	for cz in range(-5, 5):
		for cx in range(-5, 5):
			var b := m.big_in_cell(Vector2i(cx, cz))
			if b.is_empty() or b[3] > 0.0:
				continue
			big += 1
			var c := Vector2i(roundi(b[0]), roundi(b[1]))
			var r: float = b[2]
			assert_eq(s.mercury_kind(c.x, c.y), MercuryTerrain.PEAK, "a central peak (%s)" % c)
			var fl := c + Vector2i(roundi(r * 0.33), 0)
			assert_eq(s.mercury_kind(fl.x, fl.y), MercuryTerrain.BIG_FLOOR, "a flat floor")
			assert_between(m.plains_height(fl.x, fl.y) - s.height_at(fl.x, fl.y), MercuryTerrain.BIG_DEPTH - 1,
				MercuryTerrain.BIG_DEPTH + 1, "its floor is deep")
			assert_gte(s.height_at(c.x, c.y) - s.height_at(fl.x, fl.y), 4, "the peak stands up from the floor")
			var wall := c + Vector2i(0, roundi(r * 0.8))
			assert_eq(s.mercury_kind(wall.x, wall.y), MercuryTerrain.BIG_WALL, "terraced walls")
			assert_eq(s.block_at(wall.x, s.height_at(wall.x, wall.y) - 1, wall.y), BlockIds.MERCURY_ROCK)
			var rim := c + Vector2i(-roundi(r * 1.05), 0)
			assert_gt(s.height_at(rim.x, rim.y), m.plains_height(rim.x, rim.y), "a raised rim")
	assert_gt(big, 3, "big craters (%d)" % big)


func test_ice_hides_in_the_shadowed_craters_near_the_poles() -> void:
	for seed in SEEDS:
		var s := _mercury(seed)
		var m := s.mercury
		var sp := s.spawn_column()
		var ic := m.ice_centre()
		assert_lt(ic.y, sp.y - 300, "seed %d: the ice crater is far to the north (-z)" % seed)
		assert_lt(Vector2(ic - sp).length(), 650.0, "seed %d: a flight away, not lost" % seed)
		assert_eq(s.mercury_kind(ic.x, ic.y), MercuryTerrain.ICE, "seed %d: ice on its floor" % seed)
		var h := s.height_at(ic.x, ic.y)
		assert_eq(s.block_at(ic.x, h - 1, ic.y), BlockIds.SHADOW_ICE)
		assert_eq(s.block_at(ic.x, h - 2, ic.y), BlockIds.SHADOW_ICE, "ice under the ice")
		assert_between(m.plains_height(ic.x, ic.y) - h, MercuryTerrain.BIG_DEPTH - 1, MercuryTerrain.BIG_DEPTH + 1,
			"seed %d: deep in its crater" % seed)
	var s := _mercury()
	var m := s.mercury
	var crystals := 0
	var ic := m.ice_centre()
	for z in range(ic.y - 12, ic.y + 13):
		for x in range(ic.x - 12, ic.x + 13):
			if s.tree_at(x, z):
				assert_eq(s.mercury_kind(x, z), MercuryTerrain.ICE, "crystals grow on the ice")
				assert_eq(s.feature_at(x, s.height_at(x, z), z), BlockIds.ICE_CRYSTAL)
				crystals += 1
	assert_gt(crystals, 3, "glowing ice crystals on its floor (%d)" % crystals)
	var polar := 0
	for cz in range(-6, 6):
		for cx in range(-6, 6):
			var b := m.big_in_cell(Vector2i(cx, cz))
			if b.is_empty():
				continue
			assert_eq(b[3] > 0.0, absf(b[1]) > MercuryTerrain.POLE, "ice only near the poles (%s)" % [b])
			if b[3] > 0.0:
				polar += 1
				var c := Vector2i(roundi(b[0]) + roundi(b[2] * 0.33), roundi(b[1]))
				assert_eq(s.mercury_kind(c.x, c.y), MercuryTerrain.ICE)
	assert_gt(polar, 0, "more ice craters near the poles")


# --- The landing pad, the thermometer and the sights ---

func test_the_pad_is_on_calm_plains_away_from_cliffs_and_big_craters() -> void:
	for seed in SEEDS:
		var s := _mercury(seed)
		var sp := s.spawn_column()
		assert_true(MercuryTerrain.is_plains(s.mercury_kind(sp.x, sp.y)), "seed %d" % seed)
		for a in 32:
			for r in range(0, 72, 4):
				var p := sp + Vector2i(roundi(cos(TAU * a / 32.0) * r), roundi(sin(TAU * a / 32.0) * r))
				var k := s.mercury_kind(p.x, p.y)
				assert_true(k != MercuryTerrain.SCARP and k != MercuryTerrain.BIG_WALL and k != MercuryTerrain.BIG_FLOOR
					and k != MercuryTerrain.PEAK and k != MercuryTerrain.ICE, "seed %d: calm round the pad (%s)" % [seed, p])


func test_the_thermometer_stands_by_the_pad() -> void:
	for seed in SEEDS:
		var s := _mercury(seed)
		var sp := s.spawn_column()
		var t := s.thermometer_column()
		var d := Vector2(t - sp).length()
		assert_between(d, float(SpaceShape.FLAT_RADIUS) + 1.0, float(SpaceShape.BLEND_RADIUS) - 3.0,
			"seed %d: a few steps from the pad (%.1f)" % [seed, d])
		assert_true(s.tree_at(t.x, t.y), "seed %d: it stands there" % seed)
		var base := s.height_at(t.x, t.y)
		assert_eq(s.feature_at(t.x, base, t.y), BlockIds.EXPLORER_BRICK, "on a little plinth")
		assert_eq(s.feature_at(t.x, base + 1, t.y), BlockIds.THERMO_BULB, "its red bulb")
		for y in range(base + 2, base + SpaceShape.THERMOMETER_H):
			assert_eq(s.feature_at(t.x, y, t.y), BlockIds.THERMOMETER, "its tube")
		assert_eq(s.feature_at(t.x, base + SpaceShape.THERMOMETER_H, t.y), -1, "nothing on top")
		for dz in range(-3, 4):
			for dx in range(-3, 4):
				if dx != 0 or dz != 0:
					assert_false(s.tree_at(t.x + dx, t.y + dz), "seed %d: room round it" % seed)


func test_the_sights_where_a_child_learns_a_fact() -> void:
	var s := _mercury()
	var m := s.mercury
	var sp := s.spawn_column()
	var t := s.thermometer_column()
	assert_eq(s.sight_at(t.x + 2, t.y), &"thermometer", "standing by the thermometer")
	assert_eq(s.sight_at(t.x, t.y + 2), &"thermometer")
	assert_eq(s.sight_at(t.x + 4, t.y + 4), &"", "not from the far side of the pad")
	var face := m.great_face_toward(sp)
	assert_eq(s.sight_at(face.x, face.y), &"scarp", "on the long cliff")
	var c := m.nearest_crater(sp)
	assert_ne(c, MercuryTerrain.NONE, "a big crater near the pad")
	assert_eq(s.sight_at(c.x, c.y), &"crater", "on a big crater's peak")
	var ic := m.ice_centre()
	assert_eq(s.sight_at(ic.x, ic.y), &"ice", "on the ice")
	assert_eq(s.sight_at(sp.x, sp.y), &"", "nothing at the pad")
	var ids: Array = s.sights().map(func(e: Dictionary) -> StringName: return e.id)
	assert_eq(ids, [&"thermometer", &"scarp", &"crater", &"ice"], "MY MAP shows all four from the landing")
	for e: Dictionary in s.sights():
		var p: Vector3 = e.pos
		assert_eq(s.sight_at(floori(p.x), floori(p.z)), e.id, "%s's mark is on it" % e.id)


func test_the_same_seed_is_the_same_mercury() -> void:
	var a := _mercury()
	var b := _mercury()
	assert_eq(a.spawn_column(), b.spawn_column())
	assert_eq(a.mercury.ice_centre(), b.mercury.ice_centre())
	assert_eq(a.thermometer_column(), b.thermometer_column())
	for i in 50:
		assert_eq(a.height_at(i * 13, -i * 7), b.height_at(i * 13, -i * 7))
	var other := _mercury(777)
	assert_ne(other.mercury.great_arc(), a.mercury.great_arc(), "another seed, another Mercury")
