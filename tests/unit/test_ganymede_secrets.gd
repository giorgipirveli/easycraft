extends GutTest
## Cosmos: Ganymede (world 28, spec §21b.2): its secrets (SpaceSecretRules with Ganymede's palette). Buried treasure under
## an X of glowing aurora crystals, a hidden room of grooved ice behind a fake grooved-ice door, lit by aurora crystals,
## the explorers' station (the puzzle temple in pale groove bricks with aurora lamps: friendly and made up), aurora crystal
## geodes in the water ice, and the landmark: the Solar Wing Lander a short walk from the landing pad (the world's one
## ISLAND secret): four legs, a body in gold foil, a white deck with lamps and a golden chest, two giant solar wings on
## trusses (sunlight out at Jupiter is about 25 times weaker than at Earth: a real spacecraft on its way there carries
## huge solar wings), a magnetometer on a long boom at its back, a radio dish on a mast, steps up its front (the game's
## lander is made up and named by no mission). No secret is built on the ray crater or a built part.

const SEED := 12345
const OTHERS_ONLY: Array[int] = [BlockIds.STONE, BlockIds.PLANKS, BlockIds.BRICK, BlockIds.FAKE_WALL, BlockIds.SAND,
	BlockIds.GRASS, BlockIds.DIRT, BlockIds.CRYSTAL, BlockIds.LIGHT, BlockIds.GOLD, BlockIds.MOON_ROCK, BlockIds.MOON_DUST,
	BlockIds.BASE_PANEL, BlockIds.BASALT, BlockIds.ROVER_PANEL, BlockIds.PROBE_PANEL, BlockIds.SALT, BlockIds.IO_ROCK,
	BlockIds.HEAT_TILE, BlockIds.ICY_ROCK, BlockIds.TITAN_BRICK, BlockIds.RING_ICE, BlockIds.MERCURY_ROCK,
	BlockIds.FROST_BRICK, BlockIds.FAKE_WATER_ICE, BlockIds.PLUTO_FROST, BlockIds.FROST_CRYSTAL, BlockIds.CAP_BRICK,
	BlockIds.PINK_ICE, BlockIds.NITROGEN_CRYSTAL, BlockIds.FAKE_PINK_ICE]


func _rules(seed: int = SEED) -> SpaceSecretRules:
	return SpaceSecretRules.new(seed, SpaceShape.new(seed, SpaceShape.GANYMEDE))


func _all(rules: SpaceSecretRules, n: int = 5) -> Array:
	var out: Array = []
	for az in range(-n, n):
		for ax in range(-n, n):
			out.append_array(rules.secrets_in_area(Vector2i(ax, az)))
	return out


func test_every_book_kind_in_ganymedes_blocks() -> void:
	var rules := _rules()
	var kinds := {}
	var used := {}
	for s: Dictionary in _all(rules):
		kinds[s.kind] = int(kinds.get(s.kind, 0)) + 1
		for b: Array in s.boxes:
			assert_false(OTHERS_ONLY.has(int(b[2])), "%s: %s is another world's" % [s.id, BlockIds.display_name(b[2])])
			used[int(b[2])] = true
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.GEODE]:
		assert_gt(int(kinds.get(k, 0)), 0, "Ganymede has %s" % k)
	assert_eq(int(kinds.get(SecretRules.ISLAND, 0)), 1, "one landmark: the Solar Wing Lander")
	for id in [BlockIds.AURORA_CRYSTAL, BlockIds.GROOVED_ICE, BlockIds.FAKE_GROOVED_ICE, BlockIds.GROOVE_BRICK,
			BlockIds.AURORA_LAMP, BlockIds.STAR_GOLD, BlockIds.SOLAR_PANEL, BlockIds.LANDER_FOIL, BlockIds.MAGNETOMETER]:
		assert_true(used.has(id), "%s is used" % BlockIds.display_name(id))
	assert_null(rules.more, "no treasure pack on Ganymede")
	assert_null(rules.tiny, "no mouse villages on Ganymede")


func test_the_hidden_room_is_grooved_ice_behind_a_fake_door() -> void:
	var rules := _rules()
	var rooms := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.ROOM:
			continue
		rooms += 1
		for c: Vector3i in s.fake_wall:
			assert_eq(rules.block_at(c), BlockIds.FAKE_GROOVED_ICE, "a knock opens it")
		var walls := 0
		var lamps := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.GROOVED_ICE:
				walls += 1
			elif b[2] == BlockIds.AURORA_CRYSTAL:
				lamps += 1
		assert_gt(walls, 0, "walls of grooved ice")
		assert_gt(lamps, 0, "lit by glowing aurora crystals")
	assert_gt(rooms, 0)


func test_the_explorers_station_is_a_friendly_puzzle_in_groove_bricks() -> void:
	var rules := _rules()
	var stations := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.TEMPLE:
			continue
		stations += 1
		var bricks := 0
		var lamps := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.GROOVE_BRICK:
				bricks += 1
			elif b[2] == BlockIds.AURORA_LAMP:
				lamps += 1
		assert_gt(bricks, 0, "groove brick walls")
		assert_gt(lamps, 0, "aurora lamps")
		assert_eq(s.plates.size(), 3, "its puzzle stays the Secret Book's")
	assert_gt(stations, 0)


func test_no_secret_is_built_on_the_crater_or_a_built_part() -> void:
	for seed: int in [SEED, 77]:
		var rules := _rules(seed)
		var shape := rules.space
		var g := shape.ganymede
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
								var k := shape.ganymede_kind(x, z)
								assert_false(k == GanymedeTerrain.CRATER or k == GanymedeTerrain.PIT or g.on_part(x, z, 1),
									"seed %d: %s keeps off the crater and the built parts (%d, %d)" % [seed, s.id, x, z])


func test_the_solar_wing_lander_is_a_short_walk_from_the_pad() -> void:
	var rules := _rules()
	var lm := rules.landmark()
	assert_eq(lm.kind, SecretRules.ISLAND)
	assert_eq(lm.name, "Solar Wing Lander")
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
	var g := rules.space.ganymede
	for p: Vector2i in [g.lookout, g.drill]:
		var gap := Vector2(clampi(p.x, lm.lo.x, lm.hi.x - 1) - p.x, clampi(p.y, lm.lo.z, lm.hi.z - 1) - p.y).length()
		assert_gt(gap, 4.0, "clear of the lookout and the drill")


func test_the_lander_spreads_two_giant_solar_wings() -> void:
	for seed: int in [SEED, 77, 42]:
		var rules := _rules(seed)
		var lm := rules.landmark()
		var c: Vector3i = lm.anchor
		var dir: Vector3i = lm.dir
		var side := Vector3i(-dir.z, 0, dir.x)
		var chest: Vector3i = lm.chest
		assert_eq(rules.block_at(chest + Vector3i.DOWN), BlockIds.STATION_PANEL, "the chest on its white deck")
		var ground := rules.shape.height_at(chest.x, chest.z)
		assert_lte(chest.y - ground, 7, "an easy Ganymede jump up to it")
		var sp := rules.shape.spawn_column()
		var to_pad := Vector2(sp.x - chest.x, sp.y - chest.z).normalized()
		assert_gt(Vector2(dir.x, dir.z).dot(to_pad), 0.5, "it faces the landing pad")
		var counts := {}
		var left := 0
		var right := 0
		var sensor_out := 0.0
		for b: Array in lm.boxes:
			var lo: Vector3i = b[0]
			var hi: Vector3i = b[1]
			for y in range(lo.y, hi.y):   # a box's hi is past its last cell
				for z in range(lo.z, hi.z):
					for x in range(lo.x, hi.x):
						var id := int(b[2])
						counts[id] = int(counts.get(id, 0)) + 1
						var across := Vector2(x - c.x, z - c.z).dot(Vector2(side.x, side.z))
						if id == BlockIds.SOLAR_PANEL:
							if across < -4.0:
								left += 1
							elif across > 4.0:
								right += 1
						if id == BlockIds.MAGNETOMETER:
							sensor_out = maxf(sensor_out, Vector2(x - c.x, z - c.z).length())
		assert_gt(int(counts.get(BlockIds.LANDER_FOIL, 0)), 20, "a body in gold foil")
		assert_gte(int(counts.get(BlockIds.TRUSS, 0)), 8, "legs, wing arms and a boom")
		assert_gt(left, 12, "seed %d: a giant solar wing to one side (%d)" % [seed, left])
		assert_gt(right, 12, "seed %d: and to the other (%d)" % [seed, right])
		assert_gt(sensor_out, 5.0, "a magnetometer far out on its boom")
		assert_gt(int(counts.get(BlockIds.RADIO_DISH, 0)), 4, "a radio dish to talk to Earth")
		assert_gt(int(counts.get(BlockIds.STATION_LAMP, 0)), 3, "lamps on its deck")


func test_the_same_seed_the_same_secrets() -> void:
	var a := _rules()
	var b := _rules()
	assert_eq(a.landmark().id, b.landmark().id)
	assert_eq(a.landmark().anchor, b.landmark().anchor)
	assert_eq(a.secrets_in_area(Vector2i(1, -1)).size(), b.secrets_in_area(Vector2i(1, -1)).size())
