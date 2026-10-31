extends GutTest
## Prospecting (spec §26.1, owner #80): rich deposits where real geology puts them, from the seed and the terrain alone.
## Green Meadows: gold where water runs below a hill (flakes in the gravel, the quartz vein in the hill), iron under
## rusty rock on a hilltop, coal in a seam running into a hillside under fern shale. The Sandstorm Desert: copper in a
## mesa's edge under green malachite, oil under a dome on the open floor with a dark seep on its flank, salt under a
## white crust on level ground. Never by the spawn, never on a secret, the same for a seed.

const SEEDS: Array[int] = [12345, 777, 20260925, 99, 4242]
const SEA := MeadowsShape.SEA_LEVEL

var _rules := {}


func _deposits(world_seed: int, which: StringName) -> DepositRules:
	var key := "%s:%d" % [which, world_seed]
	if not _rules.has(key):
		var shape: MeadowsShape = DesertShape.new(world_seed) if which == &"desert" else (
			MeadowsBiomeShape.new(world_seed) if which == &"wild" else MeadowsShape.new(world_seed))
		_rules[key] = DepositRules.for_world(world_seed, shape, SecretRules.new(world_seed, shape))
	return _rules[key]


func test_the_kinds_of_each_terrain() -> void:
	assert_eq(DepositRules.kinds_for(MeadowsShape.new(1)), [DepositKinds.GOLD, DepositKinds.IRON, DepositKinds.COAL] as Array[StringName])
	assert_eq(DepositRules.kinds_for(MeadowsBiomeShape.new(1)), [DepositKinds.GOLD, DepositKinds.IRON, DepositKinds.COAL] as Array[StringName])
	assert_eq(DepositRules.kinds_for(DesertShape.new(1)), [DepositKinds.COPPER, DepositKinds.OIL, DepositKinds.SALT] as Array[StringName])
	for other: MeadowsShape in [FrostShape.new(1), CandyShape.new(1), DragonShape.new(1)]:
		assert_eq(DepositRules.kinds_for(other), [] as Array[StringName], other.get_script().get_global_name())
		assert_null(DepositRules.for_world(1, other))
	assert_null(DepositRules.for_world(1, null))


func test_every_kind_has_a_deposit_near_every_spawn() -> void:
	for world_seed in SEEDS:
		for which: StringName in [&"old", &"wild", &"desert"]:
			var rules := _deposits(world_seed, which)
			var sp := rules.spawn
			for kind in rules.kinds:
				var d := rules.nearest(kind, Vector3(sp.x, 0, sp.y))
				assert_false(d.is_empty(), "seed %d %s: a %s deposit" % [world_seed, which, kind])
				if d.is_empty():
					continue
				var a: Vector3i = d.anchor
				var far := Vector2(a.x - sp.x, a.z - sp.y).length()
				assert_gte(far, DepositRules.MIN_FROM_SPAWN, "%s %s is an adventure away" % [which, d.id])
				assert_lt(far, 1300.0, "seed %d %s: %s is %d blocks out" % [world_seed, which, d.id, far])


func test_the_same_seed_gives_the_same_deposits() -> void:
	var a := DepositRules.for_world(777, MeadowsShape.new(777))
	var b := DepositRules.for_world(777, MeadowsShape.new(777))
	for region: Vector2i in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, -1)]:
		var da := a.deposits_in_region(region)
		var db := b.deposits_in_region(region)
		assert_eq(da.size(), db.size())
		for i in da.size():
			assert_eq(da[i].id, db[i].id)
			assert_eq(da[i].anchor, db[i].anchor)
			assert_eq(DepositRules.cells_of(da[i]), DepositRules.cells_of(db[i]))
	var c := DepositRules.for_world(778, MeadowsShape.new(778))
	assert_ne(str(a.deposits_in_region(Vector2i(1, 0)).map(func(d: Dictionary) -> Vector3i: return d.anchor)),
		str(c.deposits_in_region(Vector2i(1, 0)).map(func(d: Dictionary) -> Vector3i: return d.anchor)), "another seed, other places")


func test_deposits_stay_in_their_region_apart_and_off_the_secrets() -> void:
	for which: StringName in [&"wild", &"desert"]:
		var rules := _deposits(12345, which)
		for region: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 1)]:
			var list := rules.deposits_in_region(region)
			for d: Dictionary in list:
				var lo: Vector3i = d.lo
				var hi: Vector3i = d.hi
				var r0 := region * DepositRules.REGION
				assert_true(lo.x >= r0.x and lo.z >= r0.y and hi.x <= r0.x + DepositRules.REGION and hi.z <= r0.y + DepositRules.REGION,
					"%s stays in its region" % d.id)
				assert_eq(DepositRules.region_of(d.anchor.x, d.anchor.z), region)
				assert_true(DepositRules.is_id(d.id))
				assert_eq(rules.find(d.id).get("anchor"), d.anchor)
				for s: Dictionary in rules.secrets.secrets_near(Vector3(d.anchor), 200.0):
					assert_false(DepositRules._overlaps(lo, hi, s.lo, s.hi), "%s is off the secret %s" % [d.id, s.id])
				for e: Dictionary in list:
					if e.id != d.id:
						assert_gte(Vector2(d.anchor.x - e.anchor.x, d.anchor.z - e.anchor.z).length(), DepositRules.APART)


## The signs a child learns to read are on top, where they can be seen: each sign cell is its column's top block.
func test_signs_are_on_top_where_a_child_sees_them() -> void:
	for which: StringName in [&"old", &"wild", &"desert"]:
		var rules := _deposits(20260925, which)
		for kind in rules.kinds:
			var d := rules.nearest(kind, Vector3(rules.spawn.x, 0, rules.spawn.y))
			if d.is_empty():
				continue
			var cells := DepositRules.cells_of(d)
			assert_eq((d.signs as Array).size(), (d.spots as Array).size(), "%s: a sign per spot" % d.id)
			assert_gt((d.signs[0] as Array).size(), 3, "%s shows its sign" % d.id)
			for signs: Array in d.signs:
				for p: Vector3i in signs:
					assert_eq(p.y, rules.shape.height_at(p.x, p.z) - 1, "%s's sign at %s is the top block" % [d.id, p])
					assert_true(cells.has(p) and cells[p] != BlockIds.AIR, "%s writes its sign at %s" % [d.id, p])


func test_gold_is_where_water_runs_below_a_hill() -> void:
	for world_seed in SEEDS:
		var rules := _deposits(world_seed, &"wild")
		var d := rules.nearest(DepositKinds.GOLD, Vector3(rules.spawn.x, 0, rules.spawn.y))
		if d.is_empty():
			continue
		var gravel: Array = d.signs[0]
		var wet := 0
		for p: Vector3i in gravel:
			assert_lte(rules.shape.height_at(p.x, p.z), SEA + 2, "the gravel is on the low bank or the bed")
			if rules.shape.height_at(p.x, p.z) < SEA:
				wet += 1
		assert_gt(wet, 0, "%s: some gravel lies under the water" % d.id)
		var vein: Vector3i = d.spots[1]
		assert_gte(rules.shape.height_at(vein.x, vein.z), SEA + 6, "the vein is in the hill")
		var cells := DepositRules.cells_of(d)
		assert_eq(cells.get(d.signs[1][0]), BlockIds.GOLD_QUARTZ, "a white quartz stripe")
		assert_eq(cells.get(gravel[0]), BlockIds.GOLD_GRAVEL, "flakes in the gravel")
		assert_lt(Vector2(vein.x - gravel[0].x, vein.z - gravel[0].z).length(), 48.0, "the vein is just upstream")


func test_iron_coal_copper_oil_and_salt_are_where_geology_puts_them() -> void:
	var meadows := _deposits(12345, &"wild")
	var sp := Vector3(meadows.spawn.x, 0, meadows.spawn.y)
	var iron := meadows.nearest(DepositKinds.IRON, sp)
	var cells := DepositRules.cells_of(iron)
	assert_gte(meadows.shape.height_at(iron.anchor.x, iron.anchor.z), SEA + DepositRules.IRON_HILL - 1, "a hilltop")
	assert_eq(cells.get(iron.signs[0][0]), BlockIds.RUSTY_ROCK, "rusty rock on top")
	assert_gt(iron.count, 60, "a lens of banded iron under it (%d)" % iron.count)
	var coal := meadows.nearest(DepositKinds.COAL, sp)
	cells = DepositRules.cells_of(coal)
	var seam := 0
	for p: Vector3i in cells:
		if cells[p] == BlockIds.COAL:
			seam += 1
			var above := p + Vector3i(0, 1, 0)
			assert_true(cells.get(above) in [BlockIds.COAL, BlockIds.FERN_SHALE], "coal lies under shale at %s" % p)
	assert_gt(seam, 150, "a seam two blocks thick (%d)" % seam)
	var desert := _deposits(12345, &"desert")
	var dshape := desert.shape as DesertShape
	var dsp := Vector3(desert.spawn.x, 0, desert.spawn.y)
	var copper := desert.nearest(DepositKinds.COPPER, dsp)
	for p: Vector3i in copper.signs[0]:
		assert_eq(dshape.terrain_at(p.x, p.z), DesertShape.MESA, "malachite on the mesa at %s" % p)
	assert_gt(copper.count, 100, "a body of copper ore (%d)" % copper.count)
	var oil := desert.nearest(DepositKinds.OIL, dsp)
	assert_has(DepositRules.OIL_DEPTHS, int(oil.depth_m))
	assert_eq(int(oil.drums), DepositRules.OIL_DRUMS)
	for p: Vector3i in oil.signs[0]:
		assert_eq(dshape.terrain_at(p.x, p.z), DesertShape.DESERT, "the seep is on the open floor")
	assert_eq(DepositRules.cells_of(oil).get(oil.signs[0][0]), BlockIds.OIL_SEEP)
	var salt := desert.nearest(DepositKinds.SALT, dsp)
	cells = DepositRules.cells_of(salt)
	for p: Vector3i in salt.signs[0]:
		assert_lte(absi(p.y - salt.anchor.y), 1, "a level flat")
		assert_eq(cells.get(p + Vector3i(0, -1, 0)), BlockIds.ROCK_SALT, "rock salt under the crust")
	assert_gt((salt.signs[0] as Array).size(), 150, "a wide flat")


## The generator's reference: a deposit's block over the world's own ground only (a cave stays a cave).
func test_block_at_only_over_the_worlds_ground() -> void:
	var rules := _deposits(12345, &"desert")
	var salt := rules.nearest(DepositKinds.SALT, Vector3(rules.spawn.x, 0, rules.spawn.y))
	var p: Vector3i = salt.signs[0][0]
	assert_eq(rules.block_at(p, BlockIds.SAND), BlockIds.SALT_CRUST)
	assert_eq(rules.block_at(p, BlockIds.AIR), -1, "never in the air")
	assert_eq(rules.block_at(p, BlockIds.WATER), -1, "never in water")
	assert_eq(rules.block_at(p + Vector3i(0, 40, 0), BlockIds.SAND), -1, "nothing where it has no cell")
