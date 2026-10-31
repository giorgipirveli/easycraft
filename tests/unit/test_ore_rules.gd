extends GutTest
## Ores: veins by depth (coal high, iron middle, gold deep, diamond only below -30), deterministic,
## each vein inside its own 16³ cell (so chunks never cut a vein in half).

var ores: OreRules


func before_each() -> void:
	ores = OreRules.new(12345)


func _all_veins(rules: OreRules) -> Array:
	var all: Array = []
	for cx in range(-3, 3):
		for cz in range(-3, 3):
			for cy in range(-4, 6):
				all.append_array(rules.veins_in_cell(Vector3i(cx, cy, cz)))
	return all


func test_veins_are_deterministic_and_seeded() -> void:
	var cell := Vector3i(1, -2, 3)
	assert_eq(str(ores.veins_in_cell(cell)), str(OreRules.new(12345).veins_in_cell(cell)))
	var differs := false
	for cy in range(-4, 4):
		if str(ores.veins_in_cell(Vector3i(0, cy, 0))) != str(OreRules.new(999).veins_in_cell(Vector3i(0, cy, 0))):
			differs = true
	assert_true(differs)


func test_each_ore_stays_in_its_depth_band() -> void:
	for vein: Dictionary in _all_veins(ores):
		var band: Vector2i = OreRules.DEPTH[vein.ore]
		for p: Vector3i in vein.blocks:
			assert_between(p.y, band.x, band.y, "%s at %s" % [BlockIds.display_name(vein.ore), p])


func test_diamonds_only_below_minus_30() -> void:
	var found := 0
	for vein: Dictionary in _all_veins(ores):
		if vein.ore == BlockIds.DIAMOND:
			for p: Vector3i in vein.blocks:
				assert_lt(p.y, -30)
				found += 1
	assert_gt(found, 0, "some diamonds exist")


func test_common_ores_are_more_common() -> void:
	var count := {BlockIds.COAL: 0, BlockIds.IRON: 0, BlockIds.GOLD: 0, BlockIds.DIAMOND: 0}
	for vein: Dictionary in _all_veins(ores):
		count[vein.ore] += (vein.blocks as Array).size()
	assert_gt(count[BlockIds.COAL], count[BlockIds.IRON])
	assert_gt(count[BlockIds.IRON], count[BlockIds.GOLD])
	assert_gt(count[BlockIds.GOLD], count[BlockIds.DIAMOND])


func test_veins_stay_inside_their_cell_and_have_sane_sizes() -> void:
	for cx in range(-2, 2):
		for cy in range(-4, 4):
			var cell := Vector3i(cx, cy, 0)
			for vein: Dictionary in ores.veins_in_cell(cell):
				var size := (vein.blocks as Array).size()
				assert_between(size, 1, OreRules.MAX_VEIN)
				for p: Vector3i in vein.blocks:
					assert_eq(Vector3i(floori(p.x / 16.0), floori(p.y / 16.0), floori(p.z / 16.0)), cell)


func test_ore_at_matches_the_veins() -> void:
	var cell := Vector3i(0, -2, 0)
	var veins := ores.veins_in_cell(cell)
	assert_gt(veins.size(), 0)
	var first: Dictionary = veins[0]
	assert_eq(ores.ore_at((first.blocks as Array)[0]), first.ore)
	assert_eq(ores.ore_at(Vector3i(3, 500, 3)), -1, "no ore in the sky")


func test_crystals_only_deep_and_rare() -> void:
	var yes := 0
	for i in 5000:
		var p := Vector3i(i % 97, -60 + i % 80, i / 97)
		if ores.crystal_chance(p):
			yes += 1
			assert_lt(p.y, OreRules.CRYSTAL_MAX_Y)
	assert_between(yes, 20, 500)
