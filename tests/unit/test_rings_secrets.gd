extends GutTest
## Cosmos: Saturn's rings (world 25, spec §21b.2): its secrets (SpaceSecretRules with the rings' palette), all held by
## the big chunks (never over open space, a lump or Pan, never on the aliens' camp chunk or the show chunk, clear of the
## built parts): buried treasure under an X of glowing ring crystals, a hidden room in a chunk's ice behind a fake ice
## door, the explorers' station (the puzzle temple in station panels with station lamps: friendly and made up), ring
## crystal geodes inside the chunks, and the landmark: the Ring Explorer resting on its own chunk (the world's one ISLAND
## secret): a body in gold foil with a white deck, a big radio dish over it with a lamp on its feed, three glowing power
## packs on arms, a long boom, little feet; its door toward the pad, a golden chest inside. A spacecraft really dived
## between Saturn and its rings; the game's is made up and named by no mission. No other world's blocks, no treasure
## pack, no mouse villages.

const SEED := 12345
const SEEDS: Array[int] = [12345, 77, 777, 42]
const OTHERS_ONLY: Array[int] = [BlockIds.STONE, BlockIds.PLANKS, BlockIds.BRICK, BlockIds.FAKE_WALL, BlockIds.SAND,
	BlockIds.GRASS, BlockIds.DIRT, BlockIds.CRYSTAL, BlockIds.LIGHT, BlockIds.GOLD, BlockIds.MOON_ROCK, BlockIds.MOON_DUST,
	BlockIds.BASE_PANEL, BlockIds.BASALT, BlockIds.ROVER_PANEL, BlockIds.DEEP_ICE, BlockIds.PROBE_PANEL, BlockIds.SALT,
	BlockIds.IO_ROCK, BlockIds.HEAT_TILE, BlockIds.SULPHUR_CRYSTAL, BlockIds.ICY_ROCK, BlockIds.TITAN_BRICK,
	BlockIds.SHORE_CRYSTAL, BlockIds.PROBE_LAMP, BlockIds.MERCURY_ROCK, BlockIds.EXPLORER_BRICK, BlockIds.ICE_CRYSTAL,
	BlockIds.FLOAT_HULL, BlockIds.HOME_PANEL, BlockIds.CLOUD_CRYSTAL, BlockIds.CLOUD_LAMP, BlockIds.CLOUD_DECK]


func _rules(seed: int = SEED) -> SpaceSecretRules:
	return SpaceSecretRules.new(seed, SpaceShape.new(seed, SpaceShape.RINGS))


func _all(rules: SpaceSecretRules, n: int = 5) -> Array:
	var out: Array = []
	var a := SecretRules.area_of(rules.shape.spawn_column().x, rules.shape.spawn_column().y)
	for az in range(a.y - n, a.y + n):
		for ax in range(a.x - n, a.x + n):
			out.append_array(rules.secrets_in_area(Vector2i(ax, az)))
	return out


func _cells(lm: Dictionary, id: int) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for b: Array in lm.boxes:
		if int(b[2]) != id:
			continue
		var lo: Vector3i = b[0]
		var hi: Vector3i = b[1]
		for y in range(lo.y, hi.y):
			for z in range(lo.z, hi.z):
				for x in range(lo.x, hi.x):
					out.append(Vector3i(x, y, z))
	return out


func test_every_book_kind_in_the_rings_blocks() -> void:
	var rules := _rules()
	var kinds := {}
	var used := {}
	for s: Dictionary in _all(rules):
		kinds[s.kind] = int(kinds.get(s.kind, 0)) + 1
		for b: Array in s.boxes:
			assert_false(OTHERS_ONLY.has(int(b[2])), "%s: %s is another world's" % [s.id, BlockIds.display_name(b[2])])
			used[int(b[2])] = true
	gut.p("RINGS secrets: %s" % kinds)
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.GEODE]:
		assert_gt(int(kinds.get(k, 0)), 1, "the rings have %s (%d)" % [k, int(kinds.get(k, 0))])
	assert_eq(int(kinds.get(SecretRules.ISLAND, 0)), 1, "one landmark: the Ring Explorer")
	for id in [BlockIds.RING_CRYSTAL, BlockIds.RING_ICE, BlockIds.FAKE_RING_ICE, BlockIds.STATION_PANEL,
			BlockIds.STATION_LAMP, BlockIds.STAR_GOLD, BlockIds.RADIO_DISH, BlockIds.POWER_PACK, BlockIds.TRUSS,
			BlockIds.LANDER_FOIL]:
		assert_true(used.has(id), "%s is used" % BlockIds.display_name(id))
	assert_null(rules.more, "no treasure pack in the rings")
	assert_null(rules.tiny, "no mouse villages in the rings")


## Every secret is held by a big chunk: its whole box over one (never open space, a lump or Pan), whose ice reaches under
## what goes down into it, off the camp and show chunks and clear of the built parts.
func test_the_chunks_hold_every_secret() -> void:
	for seed: int in [SEED, 77]:
		var rules := _rules(seed)
		var r := rules.space.rings
		for s: Dictionary in _all(rules, 4):
			if s.kind == SecretRules.ISLAND:
				continue
			assert_true(r.holds(s.boxes, s.lo, s.hi, 0), "seed %d: %s is held by a chunk" % [seed, s.id])
			for b: Array in s.boxes:
				var a: Vector3i = b[0]
				var e: Vector3i = b[1]
				for z in range(a.z, e.z):
					for x in range(a.x, e.x):
						var k := r.kind_at(x, z)
						assert_true(k == RingsTerrain.ICE_FLAT or k == RingsTerrain.DUSTY_FLAT,
							"seed %d: %s over a big chunk (%d, %d)" % [seed, s.id, x, z])


func test_the_treasure_is_marked_by_a_glowing_x() -> void:
	var rules := _rules()
	var n := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.TREASURE:
			continue
		n += 1
		var chest: Vector3i = s.chest
		var top := rules.shape.height_at(chest.x, chest.z)
		assert_eq(rules.block_at(Vector3i(chest.x, top - 1, chest.z)), BlockIds.RING_CRYSTAL, "the X")
		assert_lt(chest.y, top - 2, "buried in the ice")
	assert_gt(n, 0)


func test_the_hidden_room_is_in_the_ice_behind_a_fake_door() -> void:
	var rules := _rules()
	var rooms := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.ROOM:
			continue
		rooms += 1
		for c: Vector3i in s.fake_wall:
			assert_eq(rules.block_at(c), BlockIds.FAKE_RING_ICE, "a knock opens it")
		var walls := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.RING_ICE:
				walls += 1
		assert_gt(walls, 0, "walls of ring ice")
		var top: Vector3i = s.stairs_top
		assert_eq(top.y, rules.shape.height_at(top.x, top.z) - 1, "its stairs come up through the chunk's top")
	assert_gt(rooms, 0)


func test_the_explorers_station_is_a_friendly_puzzle_in_station_panels() -> void:
	var rules := _rules()
	var stations := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.TEMPLE:
			continue
		stations += 1
		var panels := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.STATION_PANEL:
				panels += 1
		assert_gt(panels, 0, "station panel walls")
		assert_eq(s.plates.size(), 3, "its puzzle stays the Secret Book's")
	assert_gt(stations, 0)


func test_ring_crystal_geodes_inside_the_chunks() -> void:
	var rules := _rules()
	var geodes := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.GEODE:
			continue
		geodes += 1
		var c: Vector3i = s.anchor
		assert_lt(c.y + int(s.radius), rules.shape.height_at(c.x, c.z) - 1, "under the chunk's top")
		assert_gt(c.y - int(s.radius), RingsTerrain.LIFT_Y - 8, "inside the chunk: a child can dig to it")
		var crystal := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.RING_CRYSTAL:
				crystal += 1
		assert_gt(crystal, 0, "a shell of ring crystal")
	assert_gt(geodes, 0)


func test_the_ring_explorer_rests_on_its_chunk() -> void:
	for seed in SEEDS:
		var rules := _rules(seed)
		var r := rules.space.rings
		var lm := rules.landmark()
		assert_eq(lm.kind, SecretRules.ISLAND)
		assert_eq(lm.name, "Ring Explorer")
		var sp := rules.shape.spawn_column()
		var at: Vector3i = lm.anchor
		assert_between(Vector2(at.x - sp.x, at.z - sp.y).length(), 30.0, 70.0, "seed %d: a short hop" % seed)
		assert_eq(Vector2i(at.x, at.z), r.centre(RingsTerrain.EXPLORER), "on the explorer's chunk")
		assert_eq(rules.find(lm.id), lm)
		var inside: Array = lm.inside
		assert_true(SecretRules._contains(inside[0], inside[1], lm.chest), "found where its chest is")
		assert_eq(rules.block_at(lm.chest), BlockIds.AIR, "room for the chest")
		assert_eq(rules.space.block_at(lm.chest.x, lm.chest.y - 1, lm.chest.z), BlockIds.RING_FROST, "on the chunk's top")
		var dir: Vector3i = lm.dir
		var door := at + dir * 2
		assert_eq(rules.block_at(door), BlockIds.AIR, "the door")
		assert_eq(rules.block_at(door + Vector3i.UP), BlockIds.AIR)
		var to_pad := Vector2(sp.x - at.x, sp.y - at.z).normalized()
		assert_gt(Vector2(dir.x, dir.z).dot(to_pad), 0.5, "the door faces the landing pad")
		var area := SecretRules.area_of(at.x, at.z)
		var a0 := area * SecretRules.AREA
		assert_true(lm.lo.x >= a0.x and lm.lo.z >= a0.y and lm.hi.x <= a0.x + SecretRules.AREA
			and lm.hi.z <= a0.y + SecretRules.AREA, "seed %d: inside its own area" % seed)
		for p: Vector3i in _cells(lm, BlockIds.TRUSS) + _cells(lm, BlockIds.LANDER_FOIL):
			if p.y == at.y:   # every foot and wall stands on the chunk
				assert_ne(rules.space.block_at(p.x, p.y - 1, p.z), BlockIds.AIR, "seed %d: stands on ice at %s" % [seed, p])


func test_the_explorer_its_dish_power_packs_and_boom() -> void:
	var rules := _rules()
	var lm := rules.landmark()
	var at: Vector3i = lm.anchor
	assert_gt(_cells(lm, BlockIds.LANDER_FOIL).size(), 40, "a body wrapped in gold foil")
	var dish := _cells(lm, BlockIds.RADIO_DISH)
	assert_gt(dish.size(), 20, "a big radio dish (%d)" % dish.size())
	for p in dish:
		assert_gt(p.y, at.y + 3, "over the body")
	assert_eq(_cells(lm, BlockIds.POWER_PACK).size(), 6, "three glowing power packs")
	assert_gt(_cells(lm, BlockIds.TRUSS).size(), SpaceSecretRules.BOOM, "a long boom, the feet, the dish's truss")
	assert_gt(_cells(lm, BlockIds.STATION_LAMP).size(), 1, "lamps")


func test_the_same_seed_the_same_secrets() -> void:
	var a := _rules()
	var b := _rules()
	assert_eq(a.landmark().id, b.landmark().id)
	assert_eq(a.landmark().anchor, b.landmark().anchor)
	assert_eq(a.secrets_in_area(Vector2i(1, -1)).size(), b.secrets_in_area(Vector2i(1, -1)).size())
