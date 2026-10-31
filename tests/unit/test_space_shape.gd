extends GutTest
## Owner feedback #55 (spec §21.2): the space worlds' terrain as pure rules (SpaceShape, one class for every planet,
## chosen by `planet`). Every column is dry land (no seas, no rivers: every spawner's "dry land" holds everywhere), the
## landing pad is a flat disc of LANDING_PAD at the spawn with no plant on it, and each planet has its own ground. The
## Moon: silvery dust over moon rock, round craters with raised rims, glowing moon crystals in the craters.

const SEED := 12345


func _moon() -> SpaceShape:
	return SpaceShape.new(SEED, SpaceShape.MOON)


func test_every_column_is_dry_land_with_no_river() -> void:
	for planet: StringName in SpaceShape.PLANETS:
		var s := SpaceShape.new(SEED, planet)
		for i in 400:
			var x := (i * 37) % 900 - 450
			var z := (i * 91) % 900 - 450
			if s.europa != null and s.europa.in_well(x, z):
				continue   # cosmos: Europa's ocean well goes down through the ice to water (test_europa_shape.gd)
			if s.titan != null and s.is_river(x, z):
				continue   # cosmos: Titan's methane lakes and sea (test_titan_shape.gd)
			if s.venus != null and s.is_river(x, z):
				continue   # cosmos: the clouds far under Venus's cloud city and its bridges (test_venus_shape.gd)
			if s.rings != null and s.is_river(x, z):
				continue   # cosmos: the open space between the rings' chunks, the lumps, Pan (test_rings_shape.gd)
			var h := s.height_at(x, z)
			assert_gt(h, MeadowsShape.SEA_LEVEL + 2, "%s (%d, %d): dry" % [planet, x, z])
			assert_lt(h, WorldService.MAX_Y - 40, "%s: room above for flying and landmarks" % planet)
			assert_false(s.is_river(x, z))


func test_the_same_seed_is_the_same_moon() -> void:
	var a := _moon()
	var b := _moon()
	for i in 50:
		assert_eq(a.height_at(i * 13, -i * 7), b.height_at(i * 13, -i * 7))
	assert_eq(a.spawn_column(), b.spawn_column())
	var other := SpaceShape.new(777, SpaceShape.MOON)
	var differ := 0
	for i in 20:
		if other.height_at(i * 31, i * 17) != a.height_at(i * 31, i * 17):
			differ += 1
	assert_gt(differ, 5, "another seed, another Moon")


func test_the_landing_pad_is_a_flat_glowing_disc_at_the_spawn() -> void:
	for planet: StringName in SpaceShape.PLANETS:
		var s := SpaceShape.new(SEED, planet)
		var sp := s.spawn_column()
		var h := s.height_at(sp.x, sp.y)
		for dz in range(-SpaceShape.FLAT_RADIUS, SpaceShape.FLAT_RADIUS + 1):
			for dx in range(-SpaceShape.FLAT_RADIUS, SpaceShape.FLAT_RADIUS + 1):
				if dx * dx + dz * dz > SpaceShape.FLAT_RADIUS * SpaceShape.FLAT_RADIUS:
					continue
				assert_eq(s.height_at(sp.x + dx, sp.y + dz), h, "%s: flat round the pad" % planet)
				assert_false(s.tree_at(sp.x + dx, sp.y + dz), "%s: nothing grows on the pad" % planet)
		assert_true(s.pad_at(sp.x, sp.y))
		assert_eq(s.block_at(sp.x, h - 1, sp.y), BlockIds.LANDING_PAD, "%s: the pad's top" % planet)
		assert_eq(s.block_at(sp.x + SpaceShape.PAD_RADIUS, h - 1, sp.y), BlockIds.LANDING_PAD)
		assert_false(s.pad_at(sp.x + SpaceShape.PAD_RADIUS + 2, sp.y))
		assert_eq(s.block_at(sp.x, h, sp.y), BlockIds.AIR)
		assert_lt(Vector2(sp).length(), 400.0, "%s: the spawn is near the middle of the world" % planet)


func test_the_moon_has_dust_over_rock_and_bedrock_at_the_bottom() -> void:
	var s := _moon()
	var x := 200
	var z := -130
	var h := s.height_at(x, z)
	assert_eq(s.block_at(x, h - 1, z), BlockIds.MOON_DUST)
	assert_eq(s.block_at(x, h - 2, z), BlockIds.MOON_DUST)
	assert_eq(s.block_at(x, h - 6, z), BlockIds.MOON_ROCK)
	assert_eq(s.block_at(x, -5, z), BlockIds.DEEP_MOON_ROCK)
	assert_eq(s.block_at(x, MeadowsShape.WORLD_BOTTOM, z), BlockIds.BEDROCK)
	assert_eq(s.block_at(x, h + 3, z), BlockIds.AIR)


func test_the_moon_has_round_craters_with_raised_rims() -> void:
	var s := _moon()
	var found := 0
	var bowls := 0
	for cz in range(-6, 6):
		for cx in range(-6, 6):
			var c := s.crater_in_cell(Vector2i(cx, cz))
			if c.is_empty():
				continue
			var at: Vector2i = c.center
			var r: float = c.radius
			if Vector2(at - s.spawn_column()).length() < SpaceShape.BLEND_RADIUS + r * 1.4:
				continue
			found += 1
			assert_lt(s.crater_depth(at.x, at.y), -1.5, "the middle is a bowl (%s)" % at)
			if s.height_at(at.x, at.y) < s.height_at(at.x + roundi(r * 1.12), at.y):
				bowls += 1
	assert_gt(found, 40, "craters everywhere")
	assert_gt(float(bowls) / found, 0.85, "lower in the middle than at the rim")


func test_moon_crystals_grow_in_the_craters() -> void:
	var s := _moon()
	var in_craters := 0
	var total := 0
	for z in range(-300, 300):
		for x in range(-300, 300, 3):
			if s.tree_at(x, z):
				total += 1
				if s.crater_depth(x, z) < -1.0:
					in_craters += 1
				var h := s.height_at(x, z)
				assert_eq(s.feature_at(x, h, z), BlockIds.MOON_CRYSTAL, "a crystal stands on the ground")
				assert_between(s.tree_height(x, z), 1, 4)
	assert_gt(total, 30)
	assert_gt(float(in_craters) / total, 0.6, "mostly in the craters")


func test_features_are_only_above_the_ground() -> void:
	var s := _moon()
	for i in 200:
		var x := i * 7 - 700
		var z := i * 3 - 300
		var h := s.height_at(x, z)
		assert_eq(s.feature_at(x, h - 1, z), -1, "never in the ground")
		assert_eq(s.feature_at(x, h + 9, z), -1, "never high in the sky")


# --- Planet Boing ---

func _boing() -> SpaceShape:
	return SpaceShape.new(SEED, SpaceShape.BOING)


func test_boing_has_moss_on_soil_on_purple_rock_and_flat_jelly_pools_in_its_dips() -> void:
	var s := _boing()
	var pools := 0
	var dry := 0
	for i in 600:
		var x := (i * 53) % 1000 - 500
		var z := (i * 29) % 1000 - 500
		var g := s.ground_at(x, z)
		var h := s.height_at(x, z)
		if g < SpaceShape.JELLY_LEVEL:
			pools += 1
			assert_eq(h, SpaceShape.JELLY_LEVEL, "a pool's top is flat")
			assert_eq(s.block_at(x, h - 1, z), BlockIds.JELLY)
			assert_eq(s.block_at(x, g - 1, z), BlockIds.BOING_SOIL, "a pool's bed is soil")
			assert_true(s.near_pool(x, z))
		else:
			dry += 1
			assert_eq(h, g)
			if not s.pad_at(x, z):
				assert_eq(s.block_at(x, h - 1, z), BlockIds.BOING_MOSS)
			assert_eq(s.block_at(x, h - 3, z), BlockIds.BOING_SOIL)
			assert_eq(s.block_at(x, h - 8, z), BlockIds.BOING_ROCK)
	assert_gt(pools, 20, "jelly pools")
	assert_gt(dry, pools, "mostly rolling moss hills")


func test_boing_grows_spring_mushrooms_with_bouncy_caps() -> void:
	var s := _boing()
	var found := 0
	for z in range(-300, 300, 2):
		for x in range(-300, 300, 2):
			if not s.tree_at(x, z):
				continue
			found += 1
			var base := s.height_at(x, z)
			var stem := s.tree_height(x, z)
			assert_between(stem, 3, 6)
			assert_eq(s.feature_at(x, base, z), BlockIds.SPRING_STEM)
			assert_eq(s.feature_at(x, base + stem, z), BlockIds.SPRING_CAP)
			assert_eq(s.feature_at(x + 2, base + stem, z), BlockIds.SPRING_CAP, "a wide cap")
			assert_false(s.ground_at(x, z) < SpaceShape.JELLY_LEVEL, "never in a pool")
	assert_gt(found, 20)


# --- Rainbow Planet ---

func _rainbow() -> SpaceShape:
	return SpaceShape.new(SEED, SpaceShape.RAINBOW)


func test_rainbow_hills_are_striped_with_prism_grass_on_top() -> void:
	var s := _rainbow()
	for i in 200:
		var x := (i * 41) % 800 - 400
		var z := (i * 67) % 800 - 400
		var h := s.height_at(x, z)
		if not s.pad_at(x, z):
			assert_eq(s.block_at(x, h - 1, z), BlockIds.PRISM_GRASS)
		for y in [h - 2, h - 5, 3, 17]:
			if y >= 0 and y < h - 1:
				assert_eq(s.block_at(x, y, z), RainbowBlocks.STRIPES[posmod(floori(y / float(SpaceShape.STRIPE_HEIGHT)), 6)],
					"stripe at y %d" % y)
		assert_eq(s.block_at(x, -3, z), BlockIds.RAINBOW_VIOLET)


func test_rainbow_terraces_are_walkable_steps() -> void:
	var s := _rainbow()
	var steps := 0
	var cliffs := 0
	var flat := 0
	for i in 2000:
		var x := (i * 13) % 700 - 350
		var z := (i * 7) % 700 - 350
		var d := absi(s.height_at(x, z) - s.height_at(x + 1, z))
		if d == 0:
			flat += 1
		elif d == 1:
			steps += 1
		else:
			cliffs += 1
	assert_gt(flat, steps, "terraces: mostly flat")
	assert_lt(float(cliffs) / 2000.0, 0.05, "one-block steps, a child walks up them")
	var hs := {}
	for i in 400:
		hs[s.height_at(i * 5 - 1000, i * 3)] = true
	assert_gt(hs.size(), 12, "hills of many heights")


func test_rainbow_grows_prism_crystal_spires() -> void:
	var s := _rainbow()
	var found := 0
	for z in range(-300, 300):
		for x in range(-300, 300, 3):
			if s.tree_at(x, z):
				found += 1
				var base := s.height_at(x, z)
				assert_between(s.tree_height(x, z), 3, 7)
				assert_eq(s.feature_at(x, base, z), BlockIds.PRISM_CRYSTAL)
				if not s.tree_at(x + 1, z):
					assert_eq(s.feature_at(x + 1, base, z), -1, "a thin spire")
	assert_gt(found, 20)
