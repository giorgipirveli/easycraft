extends GutTest
## Prospecting on the Moon and Mars (spec §26.5, owner #80): rich deposits where real geology puts them, from the seed
## and the planet alone. The Moon: ice on the floors of deep craters that never see the Sun, ilmenite under the dark
## "seas" (low, flat plains of old lava), helium-3 in the oldest sun-soaked dust of a wide sea, KREEP rock (rare earths)
## thrown onto a crater's rim, an iron meteorite in a small crater. Mars: ice under the dust in the mid-latitudes (a
## small fresh crater shows it), hematite "blueberries" on the plains near an old river bed, dark iron-rich sand on a
## crater's floor, salt where an old lake dried in a low basin, an iron meteorite lying on the plains. Never by the
## landing pad, never on the colony's ground (spec §21c), never on a secret or the landmark, the same for a seed.

const SEEDS: Array[int] = [12345, 777, 20260925, 99, 4242]
const MOON_KINDS: Array[StringName] = [DepositKinds.MOON_ICE, DepositKinds.ILMENITE, DepositKinds.HELIUM_3,
	DepositKinds.KREEP, DepositKinds.MOON_METEORITE]
const MARS_KINDS: Array[StringName] = [DepositKinds.MARS_ICE, DepositKinds.HEMATITE, DepositKinds.DARK_SAND,
	DepositKinds.MARS_SALT, DepositKinds.MARS_METEORITE]

var _rules := {}


func _deposits(world_seed: int, planet: StringName) -> DepositRules:
	var key := "%s:%d" % [planet, world_seed]
	if not _rules.has(key):
		var shape := SpaceShape.new(world_seed, planet)
		_rules[key] = DepositRules.for_world(world_seed, shape, SpaceSecretRules.new(world_seed, shape))
	return _rules[key]


func _space(rules: DepositRules) -> SpaceShape:
	return rules.shape as SpaceShape


func test_the_kinds_of_the_moon_and_mars() -> void:
	assert_eq(DepositRules.kinds_for(SpaceShape.new(1, SpaceShape.MOON)), MOON_KINDS)
	assert_eq(DepositRules.kinds_for(SpaceShape.new(1, SpaceShape.MARS)), MARS_KINDS)
	assert_eq(DepositKinds.in_universe(SpaceRules.MOON), MOON_KINDS)
	assert_eq(DepositKinds.in_universe(SpaceRules.MARS), MARS_KINDS)
	for planet: StringName in [SpaceShape.BOING, SpaceShape.RAINBOW, SpaceShape.EUROPA, SpaceShape.IO, SpaceShape.TITAN,
			SpaceShape.MERCURY, SpaceShape.VENUS]:
		assert_eq(DepositRules.kinds_for(SpaceShape.new(1, planet)), [] as Array[StringName], str(planet))
		assert_null(DepositRules.for_world(1, SpaceShape.new(1, planet)), str(planet))


func test_every_kind_has_a_deposit_near_every_landing() -> void:
	for world_seed in SEEDS:
		for planet: StringName in [SpaceShape.MOON, SpaceShape.MARS]:
			var rules := _deposits(world_seed, planet)
			var sp := rules.spawn
			for kind in rules.kinds:
				var d := rules.nearest(kind, Vector3(sp.x, 0, sp.y), [], 3)
				assert_false(d.is_empty(), "seed %d %s: a %s deposit" % [world_seed, planet, kind])
				if d.is_empty():
					continue
				var a: Vector3i = d.anchor
				var far := Vector2(a.x - sp.x, a.z - sp.y).length()
				assert_gte(far, DepositRules.MIN_FROM_SPAWN, "%s %s is an adventure away" % [planet, d.id])
				assert_lt(far, 1300.0, "seed %d %s: %s is %d blocks out" % [world_seed, planet, d.id, far])


func test_the_same_seed_gives_the_same_deposits() -> void:
	for planet: StringName in [SpaceShape.MOON, SpaceShape.MARS]:
		var a := DepositRules.for_world(777, SpaceShape.new(777, planet))
		var b := DepositRules.for_world(777, SpaceShape.new(777, planet))
		for region: Vector2i in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
			var da := a.deposits_in_region(region)
			var db := b.deposits_in_region(region)
			assert_eq(da.size(), db.size())
			for i in da.size():
				assert_eq(da[i].id, db[i].id)
				assert_eq(da[i].anchor, db[i].anchor)
				assert_eq(DepositRules.cells_of(da[i]), DepositRules.cells_of(db[i]))


## Never on the colony's ground (its flat ground and the blend round it), never on a secret or the landmark, inside its
## region, apart from the region's other deposits.
func test_deposits_keep_off_the_colony_and_the_secrets() -> void:
	for world_seed in [12345, 99]:
		for planet: StringName in [SpaceShape.MOON, SpaceShape.MARS]:
			var rules := _deposits(world_seed, planet)
			var colony := _space(rules).colony
			assert_not_null(colony)
			var home := DepositRules.region_of(rules.spawn.x, rules.spawn.y)
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					var region := home + Vector2i(dx, dz)
					var list := rules.deposits_in_region(region)
					for d: Dictionary in list:
						var lo: Vector3i = d.lo
						var hi: Vector3i = d.hi
						assert_false(colony.near_box(lo, hi, DepositRules.GAP), "%s is off the colony's ground" % d.id)
						var r0 := region * DepositRules.REGION
						assert_true(lo.x >= r0.x and lo.z >= r0.y and hi.x <= r0.x + DepositRules.REGION
							and hi.z <= r0.y + DepositRules.REGION, "%s stays in its region" % d.id)
						for s: Dictionary in rules.secrets.secrets_near(Vector3(d.anchor), 200.0):
							assert_false(DepositRules._overlaps(lo, hi, s.lo, s.hi), "%s is off the secret %s" % [d.id, s.id])
						for e: Dictionary in list:
							if e.id != d.id:
								assert_gte(Vector2(d.anchor.x - e.anchor.x, d.anchor.z - e.anchor.z).length(),
									DepositRules.APART)
					var landmark: Dictionary = (rules.secrets as SpaceSecretRules).landmark()
					for d: Dictionary in list:
						if not landmark.is_empty():
							assert_false(DepositRules._overlaps(d.lo, d.hi, landmark.lo, landmark.hi), "%s is off the landmark" % d.id)


## The signs a child learns to read are on top, where they can be seen: each sign cell is its column's top block.
func test_signs_are_on_top_where_a_child_sees_them() -> void:
	for world_seed in [20260925, 4242]:
		for planet: StringName in [SpaceShape.MOON, SpaceShape.MARS]:
			var rules := _deposits(world_seed, planet)
			for kind in rules.kinds:
				var d := rules.nearest(kind, Vector3(rules.spawn.x, 0, rules.spawn.y), [], 3)
				if d.is_empty():
					continue
				var cells := DepositRules.cells_of(d)
				assert_eq((d.signs as Array).size(), (d.spots as Array).size(), "%s: a sign per spot" % d.id)
				var shown := 0
				for signs: Array in d.signs:
					shown += signs.size()
					for p: Vector3i in signs:
						assert_eq(p.y, rules.shape.height_at(p.x, p.z) - 1, "%s's sign at %s is the top block" % [d.id, p])
						assert_eq(cells.get(p), int(DepositKinds.data(kind).sign_block), "%s writes its sign at %s" % [d.id, p])
				assert_gt(shown, 3, "%s shows its sign" % d.id)


func test_the_moons_riches_are_where_geology_puts_them() -> void:
	for world_seed in [12345, 777]:
		var rules := _deposits(world_seed, SpaceShape.MOON)
		var moon := _space(rules)
		var sp := Vector3(rules.spawn.x, 0, rules.spawn.y)
		# Ice: the floor of a deep crater (a bowl at least 4 deep), the icy dust 3 deep.
		var ice := rules.nearest(DepositKinds.MOON_ICE, sp, [], 3)
		var cells := DepositRules.cells_of(ice)
		var floor_cells: Array = ice.signs[1]
		assert_true((ice.signs[0] as Array).is_empty(), "the first place is the crater's rim")
		for p: Vector3i in floor_cells:
			assert_lt(moon.crater_depth(p.x, p.z), -1.5, "the ice is on a crater's floor at %s" % p)
			assert_eq(cells.get(p + Vector3i(0, -2, 0)), BlockIds.ICY_REGOLITH, "icy dust 3 deep at %s" % p)
		var rim: Vector3i = ice.spots[0]
		assert_gt(moon.crater_depth(rim.x, rim.z), -0.5, "the rim is on the crater's edge, not in it")
		assert_gt(ice.count, 120, "%s holds a lot of ice (%d)" % [ice.id, ice.count])
		# Ilmenite: a dark sea (mare dust) on low, flat ground, a lens of ilmenite under it, black crystals at the top.
		var ilm := rules.nearest(DepositKinds.ILMENITE, sp, [], 3)
		cells = DepositRules.cells_of(ilm)
		for p: Vector3i in ilm.signs[0]:
			assert_lt(absf(moon.crater_depth(p.x, p.z)), 0.5, "the sea is no crater at %s" % p)
		var glints := 0
		for p: Vector3i in cells:
			if cells[p] == BlockIds.ILMENITE and p.y == moon.height_at(p.x, p.z) - 1:
				glints += 1
		assert_gt(glints, 0, "black ilmenite crystals glint in the dark dust")
		assert_lte(ilm.anchor.y, int(SpaceShape.MOON_BASE), "the seas are low plains")
		assert_gt(ilm.count, 60, "a lens of ilmenite (%d)" % ilm.count)
		# Helium-3: a wide sea of old dust, no young crater near.
		var he := rules.nearest(DepositKinds.HELIUM_3, sp, [], 3)
		assert_gt(he.count, 300, "lots of dark dust (%d)" % he.count)
		for p: Vector3i in he.signs[0]:
			assert_lt(absf(moon.crater_depth(p.x, p.z)), 0.5, "old ground, no crater at %s" % p)
		# KREEP: pale rock thrown onto a crater's rim, a body of it under the rim.
		var kreep := rules.nearest(DepositKinds.KREEP, sp, [], 3)
		var on_rim := 0
		for p: Vector3i in kreep.signs[0]:
			if moon.crater_depth(p.x, p.z) > 0.0:
				on_rim += 1
		assert_gt(on_rim, (kreep.signs[0] as Array).size() / 2, "KREEP lies on a raised rim")
		assert_gt(kreep.count, 60, "a body of KREEP rock (%d)" % kreep.count)
		# A meteorite: iron in a small crater, a lump of it standing out of the dust.
		var met := rules.nearest(DepositKinds.MOON_METEORITE, sp, [], 3)
		cells = DepositRules.cells_of(met)
		var lump: Vector3i = met.spots[1]
		assert_lt(moon.crater_depth(lump.x, lump.z), -0.5, "in a small crater")
		assert_true(_stands(rules, cells, BlockIds.IRON_METEORITE), "a lump stands out of the dust")


func test_mars_riches_are_where_geology_puts_them() -> void:
	for world_seed in [12345, 777]:
		var rules := _deposits(world_seed, SpaceShape.MARS)
		var mars := _space(rules)
		var sp := Vector3(rules.spawn.x, 0, rules.spawn.y)
		# Ice: a small crater on the plains away from the warm middle (the canyon runs along the equator); bright ice
		# in its floor and a sheet of ice under the dust round it.
		var ice := rules.nearest(DepositKinds.MARS_ICE, sp, [], 3)
		var cells := DepositRules.cells_of(ice)
		var lump: Vector3i = ice.spots[1]
		assert_lt(mars.crater_depth(lump.x, lump.z), -0.5, "in a crater's floor")
		assert_gte(absf(lump.z - mars.mars.canyon_z(lump.x)), float(DepositRules.MARS_ICE_LATITUDE), "in the mid-latitudes")
		assert_eq(mars.mars_kind(lump.x, lump.z), MarsTerrain.PLAINS)
		var under_dust := 0
		for p: Vector3i in cells:
			if cells[p] == BlockIds.GROUND_ICE and mars.height_at(p.x, p.z) - 1 > p.y \
					and not cells.has(Vector3i(p.x, mars.height_at(p.x, p.z) - 1, p.z)):
				under_dust += 1
		assert_gt(under_dust, 30, "ice hides under the dust round the crater (%d)" % under_dust)
		# Hematite: blueberries on the plains near an old river bed, hematite rock under them.
		var hem := rules.nearest(DepositKinds.HEMATITE, sp, [], 3)
		cells = DepositRules.cells_of(hem)
		assert_true(_valley_near(mars, hem.anchor, 64), "%s: water flowed near here" % hem.id)
		for p: Vector3i in hem.signs[0]:
			assert_eq(cells.get(p + Vector3i(0, -1, 0)), BlockIds.HEMATITE, "hematite under the blueberries at %s" % p)
		# Dark sand: a crater's floor.
		var sand := rules.nearest(DepositKinds.DARK_SAND, sp, [], 3)
		for p: Vector3i in sand.signs[1]:
			assert_lt(mars.crater_depth(p.x, p.z), -0.5, "dark sand in a crater's floor at %s" % p)
		# Salt: a low, flat basin.
		var salt := rules.nearest(DepositKinds.MARS_SALT, sp, [], 3)
		for p: Vector3i in salt.signs[0]:
			assert_lte(absi(p.y - salt.anchor.y), 1, "a level flat")
		assert_lt(salt.anchor.y, int(MarsTerrain.BASE), "a low basin")
		assert_gt((salt.signs[0] as Array).size(), 150, "a wide crust")
		# A meteorite lying on the plains.
		var met := rules.nearest(DepositKinds.MARS_METEORITE, sp, [], 3)
		cells = DepositRules.cells_of(met)
		assert_eq(mars.mars_kind(met.anchor.x, met.anchor.z), MarsTerrain.PLAINS)
		assert_true(_stands(rules, cells, BlockIds.IRON_METEORITE), "it sits on the ground")


## The generator's reference: a deposit's block over the planet's own ground only; a meteorite's lump over the air only.
func test_block_at_over_the_ground_and_the_lump_over_the_air() -> void:
	var rules := _deposits(12345, SpaceShape.MARS)
	var met := rules.nearest(DepositKinds.MARS_METEORITE, Vector3(rules.spawn.x, 0, rules.spawn.y), [], 3)
	var p: Vector3i = met.signs[0][0]
	assert_eq(rules.block_at(p, BlockIds.MARS_DUST), BlockIds.IRON_METEORITE)
	assert_eq(rules.block_at(p, BlockIds.AIR), -1, "a ground cell is never put in the air")
	var up := p + Vector3i(0, 1, 0)
	var cells := DepositRules.cells_of(met)
	assert_eq(cells.get(up), BlockIds.IRON_METEORITE, "the lump stands over its sunk cell")
	assert_eq(rules.block_at(up, BlockIds.AIR), BlockIds.IRON_METEORITE, "the lump fills the air over the ground")
	assert_eq(rules.block_at(up, BlockIds.BASALT), -1, "a boulder standing there stays")
	var ice := rules.nearest(DepositKinds.MARS_ICE, Vector3(rules.spawn.x, 0, rules.spawn.y), [], 3)
	var q: Vector3i = ice.signs[1][0]
	assert_eq(rules.block_at(q, BlockIds.MARS_DUST), BlockIds.GROUND_ICE)
	assert_eq(rules.block_at(q, BlockIds.ROVER_PANEL), -1, "never over something built")


## Some cell of `id` stands over its column's own ground (a lump over the air).
func _stands(rules: DepositRules, cells: Dictionary, id: int) -> bool:
	for p: Vector3i in cells:
		if cells[p] == id and p.y == rules.shape.height_at(p.x, p.z):
			return true
	return false


func _valley_near(mars: SpaceShape, a: Vector3i, r: int) -> bool:
	for dz in range(-r, r + 1, 4):
		for dx in range(-r, r + 1, 4):
			if mars.mars_kind(a.x + dx, a.z + dz) == MarsTerrain.VALLEY:
				return true
	return false
