extends GutTest
## Cosmos: Europa (world 20, spec §21b.2): its secrets (SpaceSecretRules with Europa's palette). Buried treasure under an
## X of salt crystals, a hidden room of deep ice behind a fake deep-ice door, the explorers' ice station (the puzzle
## temple in ice bricks: friendly and made up), salt crystal geodes, and the landmark: the Ice Lander a short walk from
## the landing pad (the world's one ISLAND secret): a lander on four legs whose melt probe goes down into a glowing hole in
## the ice (real scientists design such probes to reach the ocean), a golden chest on its deck. No secret is built into
## the ocean well or a geyser's mound. No other world's blocks, no treasure pack, no mouse villages.

const SEED := 12345
const MEADOWS_ONLY: Array[int] = [BlockIds.STONE, BlockIds.PLANKS, BlockIds.BRICK, BlockIds.FAKE_WALL, BlockIds.SAND,
	BlockIds.GRASS, BlockIds.DIRT, BlockIds.CRYSTAL, BlockIds.LIGHT, BlockIds.GOLD, BlockIds.MOON_ROCK, BlockIds.MOON_DUST,
	BlockIds.BASALT, BlockIds.ROVER_PANEL]


func _rules(seed: int = SEED) -> SpaceSecretRules:
	return SpaceSecretRules.new(seed, SpaceShape.new(seed, SpaceShape.EUROPA))


func _all(rules: SpaceSecretRules, n: int = 5) -> Array:
	var out: Array = []
	for az in range(-n, n):
		for ax in range(-n, n):
			out.append_array(rules.secrets_in_area(Vector2i(ax, az)))
	return out


func test_every_book_kind_in_europas_blocks() -> void:
	var rules := _rules()
	var kinds := {}
	var used := {}
	for s: Dictionary in _all(rules):
		kinds[s.kind] = int(kinds.get(s.kind, 0)) + 1
		for b: Array in s.boxes:
			assert_false(MEADOWS_ONLY.has(int(b[2])), "%s: %s is another world's" % [s.id, BlockIds.display_name(b[2])])
			used[int(b[2])] = true
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.GEODE]:
		assert_gt(int(kinds.get(k, 0)), 0, "Europa has %s" % k)
	assert_eq(int(kinds.get(SecretRules.ISLAND, 0)), 1, "one landmark: the Ice Lander")
	for id in [BlockIds.SALT, BlockIds.DEEP_ICE, BlockIds.FAKE_DEEP_ICE, BlockIds.ICE_BRICK, BlockIds.GLOW_ICE,
			BlockIds.STAR_GOLD, BlockIds.PROBE_PANEL, BlockIds.MELT_PROBE, BlockIds.PROBE_LIGHT]:
		assert_true(used.has(id), "%s is used" % BlockIds.display_name(id))
	assert_null(rules.more, "no treasure pack on Europa")
	assert_null(rules.tiny, "no mouse villages on Europa")


func test_the_hidden_room_is_deep_ice_behind_a_fake_deep_ice_door() -> void:
	var rules := _rules()
	var rooms := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.ROOM:
			continue
		rooms += 1
		for c: Vector3i in s.fake_wall:
			assert_eq(rules.block_at(c), BlockIds.FAKE_DEEP_ICE, "a knock opens it")
		var walls := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.DEEP_ICE:
				walls += 1
		assert_gt(walls, 0)
	assert_gt(rooms, 0)


func test_the_ice_station_is_a_friendly_puzzle_in_ice_bricks() -> void:
	var rules := _rules()
	var stations := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.TEMPLE:
			continue
		stations += 1
		var bricks := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.ICE_BRICK:
				bricks += 1
		assert_gt(bricks, 0, "ice brick walls")
		assert_eq(s.plates.size(), 3, "its puzzle stays the Secret Book's")
	assert_gt(stations, 0)


func test_no_secret_is_built_into_the_ocean_well_or_a_geysers_mound() -> void:
	var rules := _rules()
	var e := rules.space.europa
	var wc := e.well_centre()
	for n in [5, 9]:
		for az in range(-n, n):
			for ax in range(-n, n):
				for s: Dictionary in rules.secrets_in_area(Vector2i(ax, az)):
					var lo: Vector3i = s.lo
					var hi: Vector3i = s.hi
					var near := Vector2(clampi(wc.x, lo.x, hi.x - 1) - wc.x, clampi(wc.y, lo.z, hi.z - 1) - wc.y).length()
					assert_gt(near, EuropaTerrain.BELL + 2.0, "%s keeps clear of the well" % s.id)
					for v: Vector2i in e.vents_near((lo.x + hi.x) / 2, (lo.z + hi.z) / 2, 80):
						var dv := Vector2(clampi(v.x, lo.x, hi.x - 1) - v.x, clampi(v.y, lo.z, hi.z - 1) - v.y).length()
						assert_gt(dv, EuropaTerrain.MOUND_R + 1.0, "%s keeps clear of the vent at %s" % [s.id, v])


func test_the_ice_lander_is_a_short_walk_from_the_pad() -> void:
	var rules := _rules()
	var lm := rules.landmark()
	assert_eq(lm.kind, SecretRules.ISLAND)
	assert_eq(lm.name, "Ice Lander")
	var sp := rules.shape.spawn_column()
	var at: Vector3i = lm.anchor
	assert_between(Vector2(at.x - sp.x, at.z - sp.y).length(), 30.0, 70.0)
	assert_eq(rules.find(lm.id), lm)
	var inside: Array = lm.inside
	assert_true(SecretRules._contains(inside[0], inside[1], lm.chest), "found where its chest is")
	assert_eq(rules.block_at(lm.chest), BlockIds.AIR, "room for the chest")
	var area := SecretRules.area_of(at.x, at.z)
	var a0 := area * SecretRules.AREA
	assert_true(lm.lo.x >= a0.x and lm.lo.z >= a0.y and lm.hi.x <= a0.x + SecretRules.AREA and lm.hi.z <= a0.y + SecretRules.AREA,
		"inside its own area")


func test_the_ice_lander_stands_on_four_legs_with_its_probe_in_a_glowing_hole() -> void:
	var rules := _rules()
	var lm := rules.landmark()
	var c: Vector3i = lm.anchor
	var legs := 0
	for b: Array in lm.boxes:
		var lo: Vector3i = b[0]
		var hi: Vector3i = b[1]
		if int(b[2]) == BlockIds.MELT_PROBE and hi.x - lo.x == 1 and hi.z - lo.z == 1 and (lo.x != c.x or lo.z != c.z):
			legs += 1
	assert_eq(legs, 4, "four legs")
	assert_eq(rules.block_at(c + Vector3i(0, -2, 0)), BlockIds.MELT_PROBE, "the melt probe goes down into the ice")
	var glow := 0
	for d: Vector3i in [Vector3i(1, -1, 0), Vector3i(-1, -1, 0), Vector3i(0, -1, 1), Vector3i(0, -1, -1)]:
		if rules.block_at(c + d) == BlockIds.GLOW_ICE:
			glow += 1
	assert_eq(glow, 4, "a glowing melt hole round it")
	var chest: Vector3i = lm.chest
	assert_eq(rules.block_at(chest + Vector3i.DOWN), BlockIds.PROBE_PANEL, "the chest stands on the deck")
	var dir: Vector3i = lm.dir
	var sp := rules.shape.spawn_column()
	var to_pad := Vector2(sp.x - chest.x, sp.y - chest.z).normalized()
	assert_gt(Vector2(dir.x, dir.z).dot(to_pad), 0.5, "it faces the landing pad")
	var ground := rules.shape.height_at(chest.x, chest.z)
	assert_lte(chest.y - ground, EuropaTerrain.MAX_STEP, "one Europa jump up to the deck")
	var lights := 0
	for b: Array in lm.boxes:
		if int(b[2]) == BlockIds.PROBE_LIGHT:
			lights += 1
	assert_gte(lights, 4, "its lights")


func test_the_same_seed_the_same_secrets() -> void:
	var a := _rules()
	var b := _rules()
	assert_eq(a.landmark().id, b.landmark().id)
	assert_eq(a.landmark().anchor, b.landmark().anchor)
	assert_eq(a.secrets_in_area(Vector2i(1, -1)).size(), b.secrets_in_area(Vector2i(1, -1)).size())
