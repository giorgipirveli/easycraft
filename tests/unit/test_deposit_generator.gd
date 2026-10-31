extends GutTest
## Prospecting (spec §26.1): the terrain generators write the deposits (DepositRules) into the world with the secrets:
## the old and the wild meadows their gold, iron and coal, the desert its copper, oil and salt. A deposit's sign is
## there on the ground where the rules say; the fast path still equals the slow reference (reference_block) on a
## deposit's chunks; with deposits off (the bench) the ground is the world's own; other universes have none.

const CH := VoxelBuffer.CHANNEL_TYPE
const WORLD_SEED := 12345


func _gen(which: StringName) -> MeadowsGenerator:
	var g: MeadowsGenerator
	match which:
		&"desert":
			g = DesertGenerator.new()
		&"wild":
			g = MeadowsBiomeGenerator.new()
		_:
			g = MeadowsGenerator.new()
	g.world_seed = WORLD_SEED
	return g


func _generate(g: MeadowsGenerator, origin: Vector3i) -> VoxelBuffer:
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	g._generate_block(buf, origin, 0)
	return buf


func _chunk_of(p: Vector3i) -> Vector3i:
	return DepositRules.chunk_key(p) * 16


func test_each_generator_writes_its_deposits_signs() -> void:
	for which: StringName in [&"old", &"wild", &"desert"]:
		var g := _gen(which)
		var rules := g.deposits()
		assert_not_null(rules, "%s has deposits" % which)
		var sp := rules.spawn
		for kind in rules.kinds:
			var d := rules.nearest(kind, Vector3(sp.x, 0, sp.y))
			assert_false(d.is_empty(), "%s: %s" % [which, kind])
			if d.is_empty():
				continue
			var p: Vector3i = d.signs[0][0]
			var origin := _chunk_of(p)
			var buf := _generate(g, origin)
			var got := buf.get_voxel(p.x - origin.x, p.y - origin.y, p.z - origin.z, CH)
			var want: int = DepositRules.cells_of(d)[p]
			assert_eq(got, want, "%s %s: its sign (%s) at %s" % [which, d.id, BlockIds.display_name(want), p])


func test_with_deposits_off_the_ground_is_the_worlds_own() -> void:
	var g := _gen(&"desert")
	var rules := g.deposits()
	var d := rules.nearest(DepositKinds.SALT, Vector3(rules.spawn.x, 0, rules.spawn.y))
	var p: Vector3i = d.signs[0][0]
	g.deposits_enabled = false
	var origin := _chunk_of(p)
	var got := _generate(g, origin).get_voxel(p.x - origin.x, p.y - origin.y, p.z - origin.z, CH)
	assert_eq(got, BlockIds.SAND, "the desert's own sand under the salt flat")
	assert_eq(g.reference_block(p.x, p.y, p.z), BlockIds.SAND)
	g.deposits_enabled = true
	assert_eq(g.reference_block(p.x, p.y, p.z), BlockIds.SALT_CRUST)


## Every block of a deposit's chunks is the reference's, away from trees and plants (like the generators' own tests).
func test_the_fast_path_equals_the_reference_on_deposits() -> void:
	for which: StringName in [&"old", &"wild", &"desert"]:
		var g := _gen(which)
		if which == &"wild":
			(g as MeadowsBiomeGenerator).giant_mushrooms = false
		var rules := g.deposits()
		var sp := rules.spawn
		var bad := 0
		for kind in rules.kinds:
			var d := rules.nearest(kind, Vector3(sp.x, 0, sp.y))
			var origins: Array[Vector3i] = []
			for signs: Array in d.signs:
				if not signs.is_empty():
					origins.append(_chunk_of(signs[0]))
			var any_ore := DepositRules.cells_of(d).keys().filter(func(p: Vector3i) -> bool:
				return DepositRules.cells_of(d)[p] == int(DepositKinds.data(kind).ore))
			if not any_ore.is_empty():
				origins.append(_chunk_of(any_ore[any_ore.size() / 2]))
			for origin in origins:
				var buf := _generate(g, origin)
				for z in 16:
					for x in 16:
						if _plant_near(g, which, origin.x + x, origin.z + z):
							continue
						for y in 16:
							var w := origin + Vector3i(x, y, z)
							var want := g.reference_block(w.x, w.y, w.z)
							if buf.get_voxel(x, y, z, CH) != want:
								bad += 1
								if bad < 4:
									assert_eq(buf.get_voxel(x, y, z, CH), want, "%s %s: block at %s" % [which, d.id, w])
		assert_eq(bad, 0, "%s: blocks that differ from the reference" % which)


func test_other_universes_have_no_deposits() -> void:
	for g: MeadowsGenerator in [FrostGenerator.new(), CandyGenerator.new(), DragonGenerator.new()]:
		g.world_seed = WORLD_SEED
		assert_null(g.deposits(), g.get_script().get_global_name())


func _plant_near(g: MeadowsGenerator, which: StringName, x: int, z: int) -> bool:
	var shape := g._shape
	for dz in range(-3, 4):
		for dx in range(-3, 4):
			if which == &"desert":
				if (shape as DesertShape).plant_at(x + dx, z + dz) != DesertShape.NO_PLANT:
					return true
			elif which == &"wild":
				if (shape as MeadowsBiomeShape).tree_kind(x + dx, z + dz) != MeadowsBiomeShape.NO_TREE:
					return true
			elif shape.tree_at(x + dx, z + dz):
				return true
	return false
