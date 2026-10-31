extends GutTest
## Colonies under domes (owner #77, spec §21c): the Moon's and Mars's SpaceGenerator write the colony (ColonyLayout's
## boxes) into their chunks, fast and equal to the slow per-block reference (terrain, ores, the colony, secrets), with no
## seams; nothing else is built on the colony's ground: no crystal or boulder grows there, no secret is buried or built
## there, and the planet's landmark (the Moon Base, the rover) stands clear of it.

const CH := VoxelBuffer.CHANNEL_TYPE


func _gen(planet: StringName, seed: int = 12345) -> SpaceGenerator:
	var g := SpaceGenerator.new()
	g.planet = planet
	g.world_seed = seed
	return g


func _generate(gen: SpaceGenerator, origin: Vector3i) -> VoxelBuffer:
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	gen._generate_block(buf, origin, 0)
	return buf


func _chunk(x: int, y: int, z: int) -> Vector3i:
	return Vector3i(floori(x / 16.0), floori(y / 16.0), floori(z / 16.0)) * 16


## Every part's chunks (and the rocket's top, the mine's floor), block by block, against the reference.
func test_the_colonys_chunks_match_the_reference_block_rule() -> void:
	for planet: StringName in ColonyRules.PLANETS:
		var g := _gen(planet)
		var c := g.space_shape().colony
		assert_not_null(c, str(planet))
		var checked := 0
		var colony_blocks := 0
		for part: StringName in ColonyRules.PARTS:
			var at := c.part_centre(part)
			var ys: Array[int] = [c.ground - 6, c.ground + 2]
			if part == ColonyRules.ROCKET:
				ys.append(c.ground + ColonyLayout.ROCKET_TOP)
			for y in ys:
				var origin := _chunk(at.x, y, at.y)
				var buf := _generate(g, origin)
				var bad := 0
				for z in 16:
					for x in 16:
						for yy in 16:
							var w := origin + Vector3i(x, yy, z)
							var got := buf.get_voxel(x, yy, z, CH)
							if got != g.reference_block(w.x, w.y, w.z):
								bad += 1
							elif ColonyBlocks.TILES.has(got):
								colony_blocks += 1
							checked += 1
				assert_eq(bad, 0, "%s %s chunk %s" % [planet, part, origin])
		assert_gt(colony_blocks, 1000, "the colony's own blocks are written (%s: %d)" % [planet, colony_blocks])
		assert_gt(checked, 40000)


## The chunk above the ground and every feature still gets the colony's tall parts (the rocket reaches 30 up).
func test_the_rocket_reaches_into_the_sky_chunks() -> void:
	var g := _gen(SpaceShape.MARS)
	var c := g.space_shape().colony
	var k := c.world(ColonyLayout.ROCKET.x, ColonyLayout.ROCKET.y)
	var tip := Vector3i(k.x, c.ground + ColonyLayout.ROCKET_TOP, k.y)
	var origin := _chunk(tip.x, tip.y, tip.z)
	var buf := _generate(g, origin)
	var l := tip - origin
	assert_eq(buf.get_voxel(l.x, l.y, l.z, CH), BlockIds.COLONY_LIGHT, "the light on the rocket's tip")
	var body := Vector3i(k.x, c.ground + 20, k.y)
	var b2 := _generate(g, _chunk(body.x, body.y, body.z))
	var lb := body - _chunk(body.x, body.y, body.z)
	assert_eq(b2.get_voxel(lb.x, lb.y, lb.z, CH), BlockIds.ROCKET_HULL)


func test_nothing_grows_or_hides_on_the_colonys_ground() -> void:
	for planet: StringName in ColonyRules.PLANETS:
		for seed in [12345, 77, 4242]:
			var g := _gen(planet, seed)
			var s := g.space_shape()
			var c := s.colony
			var r := ColonyLayout.R_FLAT
			for dz in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if dx * dx + dz * dz <= r * r and s.tree_at(c.centre.x + dx, c.centre.y + dz):
						fail_test("%s %d: a feature at %s on the colony's ground" % [planet, seed, Vector2i(dx, dz)])
						return
			var rules := g._secrets as SpaceSecretRules
			for s2: Dictionary in rules.secrets_near(Vector3(c.centre.x, 0, c.centre.y), 200.0):
				assert_false(c.near_box(s2.lo, s2.hi, 0), "%s %d: %s stays off the colony's ground" % [planet, seed, s2.id])
			var lm := rules.landmark()
			assert_false(c.near_box(lm.lo, lm.hi, 4), "%s %d: the landmark (%s) stands clear of the colony" % [planet, seed,
				lm.name])


## The Shorts Theater (about 30 blocks from the pad, on flat ground) never stands on the colony's flat ground; a site
## saved before the colony came is picked again.
func test_the_theater_stands_off_the_colony() -> void:
	for planet: StringName in ColonyRules.PLANETS:
		for seed in [12345, 77, 4242, 99, 20260930]:
			var s := SpaceShape.new(seed, planet)
			var site := TheaterSite.pick_for(s)
			assert_false(site.is_empty(), "%s %d has a Theater" % [planet, seed])
			assert_false(TheaterSite.stands_on_colony(s, site), "%s %d: the Theater at %s" % [planet, seed, site.get("pos")])
			var old := {"pos": Vector3i(s.colony.centre.x, s.colony.ground, s.colony.centre.y), "facing": 0}
			assert_true(TheaterSite.stands_on_colony(s, old), "an old site on the colony is picked again")
	var meadows := MeadowsShape.new(12345)
	assert_false(TheaterSite.stands_on_colony(meadows, TheaterSite.pick_for(meadows)), "home worlds have no colony")


## The Moon's colony stands on the side away from the Moon Base (the landmark's first try), a walk from both.
func test_the_moon_base_and_the_colony_are_on_opposite_sides() -> void:
	for seed in [12345, 77, 4242, 99, 1]:
		var g := _gen(SpaceShape.MOON, seed)
		var s := g.space_shape()
		var pad := Vector2(s.spawn_column())
		var lm: Dictionary = (g._secrets as SpaceSecretRules).landmark()
		var to_base := Vector2(lm.anchor.x, lm.anchor.z) - pad
		var to_colony := Vector2(s.colony.centre) - pad
		assert_gt(absf(to_base.angle_to(to_colony)), PI / 2, "seed %d" % seed)


## Mars's ground under the colony is its plains' red dust (a river bed there is flattened away).
func test_mars_dust_under_the_colony() -> void:
	var g := _gen(SpaceShape.MARS)
	var s := g.space_shape()
	var c := s.colony
	var at := c.world(20, 20)
	assert_eq(s.mars_kind(at.x, at.y), MarsTerrain.PLAINS)
	assert_eq(g.reference_block(at.x, c.ground - 1, at.y), BlockIds.MARS_DUST)
	assert_eq(s.sight_at(at.x, at.y), &"", "the open ground between the parts is no sight")
	var dome := c.part_centre(ColonyRules.DOME)
	assert_eq(s.sight_at(dome.x, dome.y), ColonyRules.DOME)


## The generator stays as it was on every planet without a colony, and the colony's reach is small (a few chunks).
func test_other_planets_have_no_colony() -> void:
	for p: StringName in [SpaceShape.BOING, SpaceShape.EUROPA, SpaceShape.MERCURY]:
		assert_null(_gen(p).space_shape().colony, str(p))
