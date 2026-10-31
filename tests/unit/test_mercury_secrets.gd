extends GutTest
## Cosmos: Mercury (world 23, spec §21b.2): its secrets (SpaceSecretRules with Mercury's palette). Buried treasure under an
## X of ice crystals, a hidden room of Mercury rock behind a fake rock door, the explorers' station (the puzzle temple in
## explorer bricks with explorer lamps: friendly and made up), ice crystal geodes in the rock, and the landmark: the
## Sunshade Lander a short walk from the landing pad (the world's one ISLAND secret): four legs, a body in a silvery heat
## blanket, mirror panels out to both sides, lamps on its deck, a golden chest on top (two steps up its front), and its
## big white sunshade standing on its sunny side (south, where the Sun is at noon). Spacecraft really carry sunshades to
## Mercury; the game's lander is made up and named by no mission. No secret is built on a long cliff's face or into a
## big crater. No other world's blocks, no treasure pack, no mouse villages.

const SEED := 12345
const OTHERS_ONLY: Array[int] = [BlockIds.STONE, BlockIds.PLANKS, BlockIds.BRICK, BlockIds.FAKE_WALL, BlockIds.SAND,
	BlockIds.GRASS, BlockIds.DIRT, BlockIds.CRYSTAL, BlockIds.LIGHT, BlockIds.GOLD, BlockIds.MOON_ROCK, BlockIds.MOON_DUST,
	BlockIds.BASE_PANEL, BlockIds.BASALT, BlockIds.ROVER_PANEL, BlockIds.DEEP_ICE, BlockIds.PROBE_PANEL, BlockIds.SALT,
	BlockIds.IO_ROCK, BlockIds.HEAT_TILE, BlockIds.SULPHUR_CRYSTAL, BlockIds.ICY_ROCK, BlockIds.TITAN_BRICK,
	BlockIds.SHORE_CRYSTAL, BlockIds.PROBE_LAMP]


func _rules(seed: int = SEED) -> SpaceSecretRules:
	return SpaceSecretRules.new(seed, SpaceShape.new(seed, SpaceShape.MERCURY))


func _all(rules: SpaceSecretRules, n: int = 5) -> Array:
	var out: Array = []
	for az in range(-n, n):
		for ax in range(-n, n):
			out.append_array(rules.secrets_in_area(Vector2i(ax, az)))
	return out


func _cells(lm: Dictionary, id: int) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for b: Array in lm.boxes:
		if int(b[2]) != id:
			continue
		var lo: Vector3i = b[0]
		var hi: Vector3i = b[1]
		for y in range(lo.y, hi.y):   # a box's hi is past its last cell
			for z in range(lo.z, hi.z):
				for x in range(lo.x, hi.x):
					out.append(Vector3i(x, y, z))
	return out


func test_every_book_kind_in_mercurys_blocks() -> void:
	var rules := _rules()
	var kinds := {}
	var used := {}
	for s: Dictionary in _all(rules):
		kinds[s.kind] = int(kinds.get(s.kind, 0)) + 1
		for b: Array in s.boxes:
			assert_false(OTHERS_ONLY.has(int(b[2])), "%s: %s is another world's" % [s.id, BlockIds.display_name(b[2])])
			used[int(b[2])] = true
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.GEODE]:
		assert_gt(int(kinds.get(k, 0)), 0, "Mercury has %s" % k)
	assert_eq(int(kinds.get(SecretRules.ISLAND, 0)), 1, "one landmark: the Sunshade Lander")
	for id in [BlockIds.ICE_CRYSTAL, BlockIds.MERCURY_ROCK, BlockIds.FAKE_MERCURY_ROCK, BlockIds.EXPLORER_BRICK,
			BlockIds.EXPLORER_LAMP, BlockIds.STAR_GOLD, BlockIds.SUNSHADE, BlockIds.HEAT_BLANKET, BlockIds.MIRROR_PANEL,
			BlockIds.MERCURY_DUST]:
		assert_true(used.has(id), "%s is used" % BlockIds.display_name(id))
	assert_null(rules.more, "no treasure pack on Mercury")
	assert_null(rules.tiny, "no mouse villages on Mercury")


func test_the_hidden_room_is_mercury_rock_behind_a_fake_door() -> void:
	var rules := _rules()
	var rooms := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.ROOM:
			continue
		rooms += 1
		for c: Vector3i in s.fake_wall:
			assert_eq(rules.block_at(c), BlockIds.FAKE_MERCURY_ROCK, "a knock opens it")
		var walls := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.MERCURY_ROCK:
				walls += 1
		assert_gt(walls, 0, "walls of Mercury rock")
	assert_gt(rooms, 0)


func test_the_explorers_station_is_a_friendly_puzzle_in_explorer_bricks() -> void:
	var rules := _rules()
	var stations := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.TEMPLE:
			continue
		stations += 1
		var bricks := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.EXPLORER_BRICK:
				bricks += 1
		assert_gt(bricks, 0, "explorer brick walls")
		assert_eq(s.plates.size(), 3, "its puzzle stays the Secret Book's")
	assert_gt(stations, 0)


func test_no_secret_on_a_cliffs_face_or_in_a_big_crater() -> void:
	for seed: int in [SEED, 77]:
		var rules := _rules(seed)
		var shape := rules.space
		for az in range(-6, 6):
			for ax in range(-6, 6):
				for s: Dictionary in rules.secrets_in_area(Vector2i(ax, az)):
					var lo: Vector3i = s.lo
					var hi: Vector3i = s.hi
					for z in range(lo.z - 1, hi.z + 1, 2):
						for x in range(lo.x - 1, hi.x + 1, 2):
							var k := shape.mercury_kind(x, z)
							assert_false(k == MercuryTerrain.SCARP or k == MercuryTerrain.BIG_WALL
								or k == MercuryTerrain.BIG_FLOOR or k == MercuryTerrain.PEAK or k == MercuryTerrain.ICE,
								"seed %d: %s keeps off the cliffs and the big craters (%d, %d)" % [seed, s.id, x, z])


func test_the_sunshade_lander_is_a_short_walk_from_the_pad() -> void:
	var rules := _rules()
	var lm := rules.landmark()
	assert_eq(lm.kind, SecretRules.ISLAND)
	assert_eq(lm.name, "Sunshade Lander")
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


func test_the_lander_its_mirrors_its_steps_and_its_sunshade() -> void:
	for seed: int in [SEED, 77, 777, 42]:
		var rules := _rules(seed)
		var lm := rules.landmark()
		var c: Vector3i = lm.anchor
		var dir: Vector3i = lm.dir
		var chest: Vector3i = lm.chest
		assert_eq(rules.block_at(chest + Vector3i.DOWN), BlockIds.HEAT_BLANKET, "seed %d: the chest on its deck" % seed)
		var sp := rules.shape.spawn_column()
		var to_pad := Vector2(sp.x - c.x, sp.y - c.z).normalized()
		assert_gt(Vector2(dir.x, dir.z).dot(to_pad), 0.5, "seed %d: it faces the landing pad" % seed)
		# up its front: the ground, a step, a higher step, the deck: each one Mercury jump (at most 3)
		var tops: Array[int] = [c.y]
		for a: int in [5, 4, 3]:
			var col: Vector3i = c + dir * a
			var y := c.y + 12
			while y > c.y - 1 and rules.block_at(Vector3i(col.x, y, col.z)) <= BlockIds.AIR:
				y -= 1
			tops.append(y + 1)
		for i in range(1, tops.size()):
			assert_between(tops[i] - tops[i - 1], 0, 3, "seed %d: a step at a time up its front (%s)" % [seed, tops])
		assert_eq(tops[-1], chest.y, "seed %d: the deck where the chest stands" % seed)
		var shade := _cells(lm, BlockIds.SUNSHADE)
		assert_gt(shade.size(), 60, "seed %d: a big sunshade (%d)" % [seed, shade.size()])
		var high := -1000
		for p in shade:
			assert_gt(p.z, chest.z + 2, "seed %d: on its sunny side, the south (+z), where the Sun is at noon" % seed)
			high = maxi(high, p.y)
		assert_gte(high, chest.y + 3, "seed %d: taller than the lander" % seed)
		var mirrors := _cells(lm, BlockIds.MIRROR_PANEL)
		assert_gte(mirrors.size(), 12, "seed %d: mirror panels" % seed)
		var side := Vector3i(-dir.z, 0, dir.x)
		var left := mirrors.filter(func(p: Vector3i) -> bool: return Vector3(p - c).dot(Vector3(side)) > 3.0).size()
		var right := mirrors.filter(func(p: Vector3i) -> bool: return Vector3(p - c).dot(Vector3(side)) < -3.0).size()
		assert_true(left > 0 and right > 0, "seed %d: out to both sides" % seed)
		assert_gte(_cells(lm, BlockIds.EXPLORER_LAMP).size(), 4, "seed %d: lamps on its deck" % seed)


func test_the_same_seed_the_same_secrets() -> void:
	var a := _rules()
	var b := _rules()
	assert_eq(a.landmark().id, b.landmark().id)
	assert_eq(a.landmark().anchor, b.landmark().anchor)
	assert_eq(a.secrets_in_area(Vector2i(1, -1)).size(), b.secrets_in_area(Vector2i(1, -1)).size())
