extends GutTest
## Prospecting on the Moon and Mars (spec §26.5): SpaceGenerator writes the planet's deposits (DepositRules) with the
## secrets, like the Earth's generators: a deposit's sign is on the ground where the rules say, a meteorite's lump stands
## on it, and the fast path equals the slow reference (reference_block) block by block on a deposit's chunks; with
## deposits off (the bench) the ground is the planet's own; the other planets have none.

const CH := VoxelBuffer.CHANNEL_TYPE
const WORLD_SEED := 12345


func _gen(planet: StringName) -> SpaceGenerator:
	var g := SpaceGenerator.new()
	g.planet = planet
	g.world_seed = WORLD_SEED
	return g


func _generate(g: SpaceGenerator, origin: Vector3i) -> VoxelBuffer:
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	g._generate_block(buf, origin, 0)
	return buf


func _chunk_of(p: Vector3i) -> Vector3i:
	return DepositRules.chunk_key(p) * 16


func test_the_moon_and_mars_write_their_deposits_signs() -> void:
	for planet: StringName in [SpaceShape.MOON, SpaceShape.MARS]:
		var g := _gen(planet)
		var rules := g.deposits()
		assert_not_null(rules, "%s has deposits" % planet)
		if rules == null:
			continue
		var sp := rules.spawn
		for kind in rules.kinds:
			var d := rules.nearest(kind, Vector3(sp.x, 0, sp.y), [], 3)
			assert_false(d.is_empty(), "%s: %s" % [planet, kind])
			if d.is_empty():
				continue
			var signs: Array = d.signs[(d.signs as Array).size() - 1]
			var p: Vector3i = signs[0]
			var origin := _chunk_of(p)
			var buf := _generate(g, origin)
			var got := buf.get_voxel(p.x - origin.x, p.y - origin.y, p.z - origin.z, CH)
			var want: int = DepositRules.cells_of(d)[p]
			assert_eq(got, want, "%s %s: its sign (%s) at %s" % [planet, d.id, BlockIds.display_name(want), p])


## Every block of each deposit's chunks (its sign's, its ore's middle, a lump's), against the reference.
func test_the_fast_path_equals_the_reference_on_deposits() -> void:
	for planet: StringName in [SpaceShape.MOON, SpaceShape.MARS]:
		var g := _gen(planet)
		var rules := g.deposits()
		var sp := rules.spawn
		var bad := 0
		var riches := 0
		for kind in rules.kinds:
			var d := rules.nearest(kind, Vector3(sp.x, 0, sp.y), [], 3)
			var cells := DepositRules.cells_of(d)
			var origins: Array[Vector3i] = []
			for signs: Array in d.signs:
				if not signs.is_empty():
					origins.append(_chunk_of(signs[0]))
					origins.append(_chunk_of(signs[0] + Vector3i(0, 1, 0)))   # a lump standing on the ground
			var ore := cells.keys().filter(func(p: Vector3i) -> bool: return cells[p] == int(DepositKinds.data(kind).ore))
			if not ore.is_empty():
				origins.append(_chunk_of(ore[ore.size() / 2]))
			for origin in origins:
				var buf := _generate(g, origin)
				for z in 16:
					for x in 16:
						for y in 16:
							var w := origin + Vector3i(x, y, z)
							var got := buf.get_voxel(x, y, z, CH)
							var want := g.reference_block(w.x, w.y, w.z)
							if got != want:
								bad += 1
								if bad < 4:
									assert_eq(got, want, "%s %s: block at %s" % [planet, d.id, w])
							elif ProspectSpacePage.TILES.has(got):
								riches += 1
		assert_eq(bad, 0, "%s: blocks that differ from the reference" % planet)
		assert_gt(riches, 200, "%s: the riches are in the ground (%d)" % [planet, riches])


func test_a_meteorite_lies_on_the_plain() -> void:
	var g := _gen(SpaceShape.MARS)
	var rules := g.deposits()
	var d := rules.nearest(DepositKinds.MARS_METEORITE, Vector3(rules.spawn.x, 0, rules.spawn.y), [], 3)
	var p: Vector3i = d.signs[0][0] + Vector3i(0, 1, 0)
	var origin := _chunk_of(p)
	assert_eq(_generate(g, origin).get_voxel(p.x - origin.x, p.y - origin.y, p.z - origin.z, CH), BlockIds.IRON_METEORITE,
		"the lump stands over the dust")
	assert_eq(g.reference_block(p.x, p.y, p.z), BlockIds.IRON_METEORITE)


func test_with_deposits_off_the_ground_is_the_planets_own() -> void:
	var g := _gen(SpaceShape.MOON)
	var rules := g.deposits()
	var d := rules.nearest(DepositKinds.MOON_ICE, Vector3(rules.spawn.x, 0, rules.spawn.y), [], 3)
	var p: Vector3i = d.signs[1][0]
	g.deposits_enabled = false
	var origin := _chunk_of(p)
	var got := _generate(g, origin).get_voxel(p.x - origin.x, p.y - origin.y, p.z - origin.z, CH)
	assert_eq(got, BlockIds.MOON_DUST, "the Moon's own dust in the crater's floor")
	assert_eq(g.reference_block(p.x, p.y, p.z), BlockIds.MOON_DUST)
	g.deposits_enabled = true
	assert_eq(g.reference_block(p.x, p.y, p.z), BlockIds.ICY_REGOLITH)


func test_the_other_planets_have_no_deposits() -> void:
	for planet: StringName in [SpaceShape.BOING, SpaceShape.RAINBOW, SpaceShape.EUROPA, SpaceShape.IO, SpaceShape.TITAN,
			SpaceShape.MERCURY, SpaceShape.VENUS]:
		assert_null(_gen(planet).deposits(), str(planet))
