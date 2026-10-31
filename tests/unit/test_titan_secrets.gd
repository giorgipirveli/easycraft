extends GutTest
## Cosmos: Titan (world 22, spec §21b.2): its secrets (SpaceSecretRules with Titan's palette). Buried treasure under an X
## of shore crystals, a hidden ice room of icy rock behind a fake icy-rock door (lit by shore crystals), the explorers'
## station (the puzzle temple in station bricks with probe lamps: friendly and made up), shore crystal geodes in the icy
## rock, and the landmark: the Landing Probe a short walk from the landing pad (the world's one ISLAND secret): a round
## probe of gold foil and white shell with lamps round its rim, a golden chest on top, a step up its front and its
## striped parachute lying flat on the ground behind it (a probe really landed on Titan in 2005, under a parachute; the
## game's probe is made up and named by no mission). No secret is built into the methane (a lake, the sea or their
## shores). No other world's blocks, no treasure pack, no mouse villages.

const SEED := 12345
const OTHERS_ONLY: Array[int] = [BlockIds.STONE, BlockIds.PLANKS, BlockIds.BRICK, BlockIds.FAKE_WALL, BlockIds.SAND,
	BlockIds.GRASS, BlockIds.DIRT, BlockIds.CRYSTAL, BlockIds.LIGHT, BlockIds.GOLD, BlockIds.MOON_ROCK, BlockIds.MOON_DUST,
	BlockIds.BASE_PANEL, BlockIds.BASALT, BlockIds.ROVER_PANEL, BlockIds.DEEP_ICE, BlockIds.PROBE_PANEL, BlockIds.SALT,
	BlockIds.IO_ROCK, BlockIds.HEAT_TILE, BlockIds.SULPHUR_CRYSTAL]


func _rules(seed: int = SEED) -> SpaceSecretRules:
	return SpaceSecretRules.new(seed, SpaceShape.new(seed, SpaceShape.TITAN))


func _all(rules: SpaceSecretRules, n: int = 5) -> Array:
	var out: Array = []
	for az in range(-n, n):
		for ax in range(-n, n):
			out.append_array(rules.secrets_in_area(Vector2i(ax, az)))
	return out


func test_every_book_kind_in_titans_blocks() -> void:
	var rules := _rules()
	var kinds := {}
	var used := {}
	for s: Dictionary in _all(rules):
		kinds[s.kind] = int(kinds.get(s.kind, 0)) + 1
		for b: Array in s.boxes:
			assert_false(OTHERS_ONLY.has(int(b[2])), "%s: %s is another world's" % [s.id, BlockIds.display_name(b[2])])
			used[int(b[2])] = true
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.GEODE]:
		assert_gt(int(kinds.get(k, 0)), 0, "Titan has %s" % k)
	assert_eq(int(kinds.get(SecretRules.ISLAND, 0)), 1, "one landmark: the Landing Probe")
	for id in [BlockIds.SHORE_CRYSTAL, BlockIds.ICY_ROCK, BlockIds.FAKE_ICY_ROCK, BlockIds.TITAN_BRICK, BlockIds.PROBE_LAMP,
			BlockIds.STAR_GOLD, BlockIds.PROBE_SHELL, BlockIds.PARACHUTE, BlockIds.TITAN_SOIL]:
		assert_true(used.has(id), "%s is used" % BlockIds.display_name(id))
	assert_null(rules.more, "no treasure pack on Titan")
	assert_null(rules.tiny, "no mouse villages on Titan")


func test_the_hidden_room_is_icy_rock_behind_a_fake_door() -> void:
	var rules := _rules()
	var rooms := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.ROOM:
			continue
		rooms += 1
		for c: Vector3i in s.fake_wall:
			assert_eq(rules.block_at(c), BlockIds.FAKE_ICY_ROCK, "a knock opens it")
		var walls := 0
		var lamps := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.ICY_ROCK:
				walls += 1
			elif b[2] == BlockIds.SHORE_CRYSTAL:
				lamps += 1
		assert_gt(walls, 0, "walls of icy rock")
		assert_gt(lamps, 0, "lit by glowing shore crystals")
	assert_gt(rooms, 0)


func test_the_explorers_station_is_a_friendly_puzzle_in_station_bricks() -> void:
	var rules := _rules()
	var stations := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.TEMPLE:
			continue
		stations += 1
		var bricks := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.TITAN_BRICK:
				bricks += 1
		assert_gt(bricks, 0, "station brick walls")
		assert_eq(s.plates.size(), 3, "its puzzle stays the Secret Book's")
	assert_gt(stations, 0)


func test_no_secret_is_built_into_the_methane_or_on_its_shore() -> void:
	for seed: int in [SEED, 77]:
		var rules := _rules(seed)
		var shape := rules.space
		for n in [5, 9]:
			for az in range(-n, n):
				for ax in range(-n, n):
					for s: Dictionary in rules.secrets_in_area(Vector2i(ax, az)):
						var lo: Vector3i = s.lo
						var hi: Vector3i = s.hi
						for z in range(lo.z - 1, hi.z + 1):
							for x in range(lo.x - 1, hi.x + 1):
								var k := shape.titan_kind(x, z)
								assert_false(TitanTerrain.is_bed(k) or TitanTerrain.is_shore(k),
									"seed %d: %s keeps off the methane and its shores (%d, %d)" % [seed, s.id, x, z])


func test_the_landing_probe_is_a_short_walk_from_the_pad() -> void:
	var rules := _rules()
	var lm := rules.landmark()
	assert_eq(lm.kind, SecretRules.ISLAND)
	assert_eq(lm.name, "Landing Probe")
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


func test_the_probe_is_round_with_lamps_and_its_parachute_lies_behind_it() -> void:
	var rules := _rules()
	var lm := rules.landmark()
	var c: Vector3i = lm.anchor
	var dir: Vector3i = lm.dir
	var chest: Vector3i = lm.chest
	assert_eq(rules.block_at(chest + Vector3i.DOWN), BlockIds.PROBE_SHELL, "the chest stands on the probe")
	var ground := rules.shape.height_at(chest.x, chest.z)
	assert_lte(chest.y - ground, TitanTerrain.MAX_STEP, "one Titan jump up to it")
	var sp := rules.shape.spawn_column()
	var to_pad := Vector2(sp.x - chest.x, sp.y - chest.z).normalized()
	assert_gt(Vector2(dir.x, dir.z).dot(to_pad), 0.5, "it faces the landing pad")
	var shell := 0
	var lamps := 0
	var chute: Array[Vector3i] = []
	for b: Array in lm.boxes:
		var lo: Vector3i = b[0]
		var hi: Vector3i = b[1]
		for y in range(lo.y, hi.y):   # a box's hi is past its last cell
			for z in range(lo.z, hi.z):
				for x in range(lo.x, hi.x):
					match int(b[2]):
						BlockIds.PROBE_SHELL:
							shell += 1
						BlockIds.PROBE_LAMP:
							lamps += 1
						BlockIds.PARACHUTE:
							chute.append(Vector3i(x, y, z))
	assert_gt(shell, 20, "a round shell (%d)" % shell)
	assert_gte(lamps, 4, "lamps round its rim")
	assert_gt(chute.size(), 30, "a parachute spread out (%d)" % chute.size())
	var behind := 0
	for p in chute:
		assert_eq(p.y, c.y, "lying flat on the ground")
		if Vector2(p.x - c.x, p.z - c.z).dot(Vector2(dir.x, dir.z)) < 0.0:
			behind += 1
	assert_eq(behind, chute.size(), "behind the probe, away from the pad")


func test_the_same_seed_the_same_secrets() -> void:
	var a := _rules()
	var b := _rules()
	assert_eq(a.landmark().id, b.landmark().id)
	assert_eq(a.landmark().anchor, b.landmark().anchor)
	assert_eq(a.secrets_in_area(Vector2i(1, -1)).size(), b.secrets_in_area(Vector2i(1, -1)).size())
