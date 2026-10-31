extends GutTest
## Cosmos: Pluto (world 26, spec §21b.2): its secrets (SpaceSecretRules with Pluto's palette). Buried treasure under an X
## of glowing frost crystals, a hidden room of water ice (as hard as rock here) behind a fake water-ice door, lit by frost
## crystals, the explorers' station (the puzzle temple in frost bricks with warm lamps: friendly and made up), frost
## crystal geodes in the water ice, and the landmark: the Balloon Lander a short walk from the landing pad (the world's one
## ISLAND secret): four legs, a body in gold foil, a white deck with lamps and a golden chest, a glowing power pack (far
## from the Sun, electricity from heat), a radio dish, steps up its front, and its silvery drag balloon lying spread out
## on the ground behind it (scientists have studied landing on Pluto slowed by a giant balloon in its thin air; the
## game's lander is made up and named by no mission). No secret is built on the ice mountains or among the floating hills.

const SEED := 12345
const OTHERS_ONLY: Array[int] = [BlockIds.STONE, BlockIds.PLANKS, BlockIds.BRICK, BlockIds.FAKE_WALL, BlockIds.SAND,
	BlockIds.GRASS, BlockIds.DIRT, BlockIds.CRYSTAL, BlockIds.LIGHT, BlockIds.GOLD, BlockIds.MOON_ROCK, BlockIds.MOON_DUST,
	BlockIds.BASE_PANEL, BlockIds.BASALT, BlockIds.ROVER_PANEL, BlockIds.DEEP_ICE, BlockIds.PROBE_PANEL, BlockIds.SALT,
	BlockIds.IO_ROCK, BlockIds.HEAT_TILE, BlockIds.ICY_ROCK, BlockIds.TITAN_BRICK, BlockIds.RING_ICE, BlockIds.MERCURY_ROCK]


func _rules(seed: int = SEED) -> SpaceSecretRules:
	return SpaceSecretRules.new(seed, SpaceShape.new(seed, SpaceShape.PLUTO))


func _all(rules: SpaceSecretRules, n: int = 5) -> Array:
	var out: Array = []
	for az in range(-n, n):
		for ax in range(-n, n):
			out.append_array(rules.secrets_in_area(Vector2i(ax, az)))
	return out


func test_every_book_kind_in_plutos_blocks() -> void:
	var rules := _rules()
	var kinds := {}
	var used := {}
	for s: Dictionary in _all(rules):
		kinds[s.kind] = int(kinds.get(s.kind, 0)) + 1
		for b: Array in s.boxes:
			assert_false(OTHERS_ONLY.has(int(b[2])), "%s: %s is another world's" % [s.id, BlockIds.display_name(b[2])])
			used[int(b[2])] = true
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.GEODE]:
		assert_gt(int(kinds.get(k, 0)), 0, "Pluto has %s" % k)
	assert_eq(int(kinds.get(SecretRules.ISLAND, 0)), 1, "one landmark: the Balloon Lander")
	for id in [BlockIds.FROST_CRYSTAL, BlockIds.WATER_ICE, BlockIds.FAKE_WATER_ICE, BlockIds.FROST_BRICK,
			BlockIds.STATION_LAMP, BlockIds.STAR_GOLD, BlockIds.DRAG_BALLOON, BlockIds.LANDER_FOIL, BlockIds.POWER_PACK]:
		assert_true(used.has(id), "%s is used" % BlockIds.display_name(id))
	assert_null(rules.more, "no treasure pack on Pluto")
	assert_null(rules.tiny, "no mouse villages on Pluto")


func test_the_hidden_room_is_water_ice_behind_a_fake_door() -> void:
	var rules := _rules()
	var rooms := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.ROOM:
			continue
		rooms += 1
		for c: Vector3i in s.fake_wall:
			assert_eq(rules.block_at(c), BlockIds.FAKE_WATER_ICE, "a knock opens it")
		var walls := 0
		var lamps := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.WATER_ICE:
				walls += 1
			elif b[2] == BlockIds.FROST_CRYSTAL:
				lamps += 1
		assert_gt(walls, 0, "walls of water ice")
		assert_gt(lamps, 0, "lit by glowing frost crystals")
	assert_gt(rooms, 0)


func test_the_explorers_station_is_a_friendly_puzzle_in_frost_bricks() -> void:
	var rules := _rules()
	var stations := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.TEMPLE:
			continue
		stations += 1
		var bricks := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.FROST_BRICK:
				bricks += 1
		assert_gt(bricks, 0, "frost brick walls")
		assert_eq(s.plates.size(), 3, "its puzzle stays the Secret Book's")
	assert_gt(stations, 0)


func test_no_secret_is_built_on_the_mountains_or_among_the_floating_hills() -> void:
	for seed: int in [SEED, 77]:
		var rules := _rules(seed)
		var shape := rules.space
		for n in [5, 9]:
			for az in range(-n, n):
				for ax in range(-n, n):
					for s: Dictionary in rules.secrets_in_area(Vector2i(ax, az)):
						if s.kind == SecretRules.ISLAND:
							continue
						var lo: Vector3i = s.lo
						var hi: Vector3i = s.hi
						for z in range(lo.z - 1, hi.z + 1):
							for x in range(lo.x - 1, hi.x + 1):
								var k := shape.pluto_kind(x, z)
								assert_false(k == PlutoTerrain.MOUNTAIN or k == PlutoTerrain.PEAK or k == PlutoTerrain.HILL,
									"seed %d: %s keeps off the mountains and the hills (%d, %d)" % [seed, s.id, x, z])


func test_the_balloon_lander_is_a_short_walk_from_the_pad() -> void:
	var rules := _rules()
	var lm := rules.landmark()
	assert_eq(lm.kind, SecretRules.ISLAND)
	assert_eq(lm.name, "Balloon Lander")
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


func test_the_lander_stands_on_legs_with_its_drag_balloon_spread_behind_it() -> void:
	for seed: int in [SEED, 77, 42]:
		var rules := _rules(seed)
		var lm := rules.landmark()
		var c: Vector3i = lm.anchor
		var dir: Vector3i = lm.dir
		var chest: Vector3i = lm.chest
		assert_eq(rules.block_at(chest + Vector3i.DOWN), BlockIds.STATION_PANEL, "the chest on its white deck")
		var ground := rules.shape.height_at(chest.x, chest.z)
		assert_lte(chest.y - ground, PlutoTerrain.MAX_STEP, "one Pluto jump up to it")
		var sp := rules.shape.spawn_column()
		var to_pad := Vector2(sp.x - chest.x, sp.y - chest.z).normalized()
		assert_gt(Vector2(dir.x, dir.z).dot(to_pad), 0.5, "it faces the landing pad")
		var foil := 0
		var legs := 0
		var balloon: Array[Vector3i] = []
		var power := 0
		var dish := 0
		for b: Array in lm.boxes:
			var lo: Vector3i = b[0]
			var hi: Vector3i = b[1]
			for y in range(lo.y, hi.y):   # a box's hi is past its last cell
				for z in range(lo.z, hi.z):
					for x in range(lo.x, hi.x):
						match int(b[2]):
							BlockIds.LANDER_FOIL:
								foil += 1
							BlockIds.TRUSS:
								legs += 1
							BlockIds.DRAG_BALLOON:
								balloon.append(Vector3i(x, y, z))
							BlockIds.POWER_PACK:
								power += 1
							BlockIds.RADIO_DISH:
								dish += 1
		assert_gt(foil, 20, "a body in gold foil (%d)" % foil)
		assert_gte(legs, 8, "four legs")
		assert_gt(power, 0, "a glowing power pack: sunlight is weak out here")
		assert_gt(dish, 4, "a radio dish to talk to Earth")
		assert_gt(balloon.size(), 60, "its drag balloon spread out (%d)" % balloon.size())
		var behind := 0
		for p in balloon:
			assert_lte(p.y - c.y, 1, "lying on the ground")
			if Vector2(p.x - c.x, p.z - c.z).dot(Vector2(dir.x, dir.z)) < 0.0:
				behind += 1
		assert_eq(behind, balloon.size(), "seed %d: behind the lander, away from the pad" % seed)


func test_the_same_seed_the_same_secrets() -> void:
	var a := _rules()
	var b := _rules()
	assert_eq(a.landmark().id, b.landmark().id)
	assert_eq(a.landmark().anchor, b.landmark().anchor)
	assert_eq(a.secrets_in_area(Vector2i(1, -1)).size(), b.secrets_in_area(Vector2i(1, -1)).size())
