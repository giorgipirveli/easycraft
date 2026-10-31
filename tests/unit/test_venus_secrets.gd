extends GutTest
## Cosmos: Venus's cloud city (world 24, spec §21b.2): its secrets (SpaceSecretRules with Venus's palette), all held by
## the city's platforms (never on a bridge or over the clouds, never on the aliens' camp deck or the show deck, clear of
## the city's built parts): buried treasure under an X of glowing cloud crystals in a deck, a hidden room in a float
## hull behind a fake hull door, the explorers' station (the puzzle temple in home panels with cloud lamps: friendly and
## made up), cloud crystal geodes inside the hulls, and the landmark: the Research Blimp moored at the airship dock (the
## world's one ISLAND secret): a white envelope with a teal stripe, solar film on its back, tail fins and a lamp on its
## nose, over a gondola with round windows reached by a gangway from the dock, a golden chest inside. Scientists have
## imagined airships floating in Venus's clouds and robot balloons really floated there; the game's blimp is made up
## and named by no mission. No other world's blocks, no treasure pack, no mouse villages.

const SEED := 12345
const SEEDS: Array[int] = [12345, 77, 777, 42]
const OTHERS_ONLY: Array[int] = [BlockIds.STONE, BlockIds.PLANKS, BlockIds.BRICK, BlockIds.FAKE_WALL, BlockIds.SAND,
	BlockIds.GRASS, BlockIds.DIRT, BlockIds.CRYSTAL, BlockIds.LIGHT, BlockIds.GOLD, BlockIds.MOON_ROCK, BlockIds.MOON_DUST,
	BlockIds.BASE_PANEL, BlockIds.BASALT, BlockIds.ROVER_PANEL, BlockIds.DEEP_ICE, BlockIds.PROBE_PANEL, BlockIds.SALT,
	BlockIds.IO_ROCK, BlockIds.HEAT_TILE, BlockIds.SULPHUR_CRYSTAL, BlockIds.ICY_ROCK, BlockIds.TITAN_BRICK,
	BlockIds.SHORE_CRYSTAL, BlockIds.PROBE_LAMP, BlockIds.MERCURY_ROCK, BlockIds.EXPLORER_BRICK, BlockIds.ICE_CRYSTAL]


func _rules(seed: int = SEED) -> SpaceSecretRules:
	return SpaceSecretRules.new(seed, SpaceShape.new(seed, SpaceShape.VENUS))


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
		for y in range(lo.y, hi.y):
			for z in range(lo.z, hi.z):
				for x in range(lo.x, hi.x):
					out.append(Vector3i(x, y, z))
	return out


func test_every_book_kind_in_venus_blocks() -> void:
	var rules := _rules()
	var kinds := {}
	var used := {}
	for s: Dictionary in _all(rules):
		kinds[s.kind] = int(kinds.get(s.kind, 0)) + 1
		for b: Array in s.boxes:
			assert_false(OTHERS_ONLY.has(int(b[2])), "%s: %s is another world's" % [s.id, BlockIds.display_name(b[2])])
			used[int(b[2])] = true
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.GEODE]:
		assert_gt(int(kinds.get(k, 0)), 1, "Venus has %s (%d)" % [k, int(kinds.get(k, 0))])
	assert_eq(int(kinds.get(SecretRules.ISLAND, 0)), 1, "one landmark: the Research Blimp")
	for id in [BlockIds.CLOUD_CRYSTAL, BlockIds.FLOAT_HULL, BlockIds.FAKE_FLOAT_HULL, BlockIds.HOME_PANEL,
			BlockIds.CLOUD_LAMP, BlockIds.STAR_GOLD, BlockIds.BLIMP_SKIN, BlockIds.BLIMP_STRIPE, BlockIds.GONDOLA,
			BlockIds.SOLAR_FILM, BlockIds.SKY_BRIDGE, BlockIds.CLOUD_DECK]:
		assert_true(used.has(id), "%s is used" % BlockIds.display_name(id))
	assert_null(rules.more, "no treasure pack on Venus")
	assert_null(rules.tiny, "no mouse villages on Venus")


## Every secret is held by a platform: its whole box over decks (never a bridge, never the clouds) whose hulls reach
## under it, off the camp and show decks and clear of the built parts.
func test_the_city_holds_every_secret() -> void:
	for seed: int in [SEED, 77]:
		var rules := _rules(seed)
		var v := rules.space.venus
		for s: Dictionary in _all(rules, 4):
			if s.kind == SecretRules.ISLAND:
				continue
			var lo: Vector3i = s.lo
			var hi: Vector3i = s.hi
			assert_true(v.holds(s.boxes, lo, hi, 0), "seed %d: %s is held by a platform" % [seed, s.id])
			for b: Array in s.boxes:
				var a: Vector3i = b[0]
				var e: Vector3i = b[1]
				for z in range(a.z, e.z):
					for x in range(a.x, e.x):
						var k := v.kind_at(x, z)
						assert_true(k != VenusTerrain.CLOUD and k != VenusTerrain.BRIDGE,
							"seed %d: %s over a deck (%d, %d)" % [seed, s.id, x, z])


func test_the_treasure_is_marked_by_a_glowing_x_in_a_deck() -> void:
	var rules := _rules()
	var n := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.TREASURE:
			continue
		n += 1
		var chest: Vector3i = s.chest
		assert_eq(rules.block_at(Vector3i(chest.x, VenusTerrain.DECK_Y - 1, chest.z)), BlockIds.CLOUD_CRYSTAL, "the X")
		assert_lt(chest.y, VenusTerrain.DECK_Y - 2, "buried in the hull")
	assert_gt(n, 0)


func test_the_hidden_room_is_in_a_float_hull_behind_a_fake_door() -> void:
	var rules := _rules()
	var rooms := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.ROOM:
			continue
		rooms += 1
		for c: Vector3i in s.fake_wall:
			assert_eq(rules.block_at(c), BlockIds.FAKE_FLOAT_HULL, "a knock opens it")
		var walls := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.FLOAT_HULL:
				walls += 1
		assert_gt(walls, 0, "walls of float hull")
		var top: Vector3i = s.stairs_top
		assert_eq(top.y, VenusTerrain.DECK_Y - 1, "its stairs come up through the deck")
	assert_gt(rooms, 0)


func test_the_explorers_station_is_a_friendly_puzzle_in_home_panels() -> void:
	var rules := _rules()
	var stations := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.TEMPLE:
			continue
		stations += 1
		var panels := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.HOME_PANEL:
				panels += 1
		assert_gt(panels, 0, "home panel walls")
		assert_eq(s.plates.size(), 3, "its puzzle stays the Secret Book's")
	assert_gt(stations, 0)


func test_cloud_crystal_geodes_inside_the_hulls() -> void:
	var rules := _rules()
	var geodes := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.GEODE:
			continue
		geodes += 1
		var c: Vector3i = s.anchor
		assert_lt(c.y + int(s.radius), VenusTerrain.DECK_Y - 1, "under the deck")
		assert_gt(c.y - int(s.radius), VenusTerrain.LIFT_Y, "high over the lift line: a child can dig to it")
		var crystal := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.CLOUD_CRYSTAL:
				crystal += 1
		assert_gt(crystal, 0, "a shell of cloud crystal")
	assert_gt(geodes, 0)


func test_the_research_blimp_is_moored_at_the_dock() -> void:
	for seed in SEEDS:
		var rules := _rules(seed)
		var v := rules.space.venus
		var lm := rules.landmark()
		assert_eq(lm.kind, SecretRules.ISLAND)
		assert_eq(lm.name, "Research Blimp")
		var sp := rules.shape.spawn_column()
		var at: Vector3i = lm.anchor
		assert_between(Vector2(at.x - sp.x, at.z - sp.y).length(), 30.0, 70.0, "seed %d: a short walk" % seed)
		var dock := v.centre(VenusTerrain.DOCK)
		assert_eq(at.x, dock.x, "seed %d: straight out from the dock" % seed)
		assert_eq(signi(at.z - dock.y), v.north().y, "seed %d: beyond it" % seed)
		assert_eq(rules.find(lm.id), lm)
		var inside: Array = lm.inside
		assert_true(SecretRules._contains(inside[0], inside[1], lm.chest), "found where its chest is")
		assert_eq(rules.block_at(lm.chest), BlockIds.AIR, "room for the chest")
		assert_eq(rules.block_at(lm.chest + Vector3i.DOWN), BlockIds.CLOUD_DECK, "the gondola's floor")
		var area := SecretRules.area_of(at.x, at.z)
		var a0 := area * SecretRules.AREA
		assert_true(lm.lo.x >= a0.x and lm.lo.z >= a0.y and lm.hi.x <= a0.x + SecretRules.AREA
			and lm.hi.z <= a0.y + SecretRules.AREA, "seed %d: inside its own area" % seed)
		# from the pad to the chest: every step on a deck, a bridge, the gangway or the gondola's floor, all level
		var y := VenusTerrain.DECK_Y
		var n := v.north()
		var way: Array[Vector2i] = []
		for k in range(0, 80):
			way.append(Vector2i(dock.x, dock.y) + n * (k - 46))
		var walked := 0
		for c: Vector2i in way:
			if Vector2(c - sp).length() > Vector2(Vector2i(at.x, at.z) - sp).length():
				break
			var floor_id := rules.block_at(Vector3i(c.x, y - 1, c.y))
			if floor_id < 0:
				floor_id = rules.space.block_at(c.x, y - 1, c.y)
			assert_true(BlockIds.is_solid(floor_id), "seed %d: a floor at %s (%s)" % [seed, c,
				BlockIds.display_name(floor_id)])
			var head := rules.block_at(Vector3i(c.x, y, c.y))
			assert_true(head < 0 or head == BlockIds.AIR, "seed %d: nothing in the way at %s" % [seed, c])
			walked += 1
		assert_gt(walked, 50, "seed %d: a level walk from the pad into the gondola" % seed)


func test_the_blimp_its_stripe_solar_film_fins_and_gondola() -> void:
	var rules := _rules()
	var lm := rules.landmark()
	var chest: Vector3i = lm.chest
	var skin := _cells(lm, BlockIds.BLIMP_SKIN)
	assert_gt(skin.size(), 400, "a big white envelope (%d)" % skin.size())
	var low := 1000
	var long_x := 0
	var min_x := 100000
	var max_x := -100000
	for p in skin:
		low = mini(low, p.y)
		min_x = mini(min_x, p.x)
		max_x = maxi(max_x, p.x)
	long_x = max_x - min_x
	assert_gt(low, chest.y + 2, "floating over the gondola")
	assert_gt(long_x, 18, "long along east-west (%d)" % long_x)
	assert_gt(_cells(lm, BlockIds.BLIMP_STRIPE).size(), 30, "its teal stripe and fins")
	assert_gt(_cells(lm, BlockIds.SOLAR_FILM).size(), 10, "solar film on its back")
	assert_gte(_cells(lm, BlockIds.GONDOLA).size(), 30, "a gondola with round windows")
	assert_gt(_cells(lm, BlockIds.CLOUD_LAMP).size(), 2, "lamps")
	assert_gt(_cells(lm, BlockIds.SKY_BRIDGE).size(), 6, "a gangway from the dock")


func test_the_same_seed_the_same_secrets() -> void:
	var a := _rules()
	var b := _rules()
	assert_eq(a.landmark().id, b.landmark().id)
	assert_eq(a.landmark().anchor, b.landmark().anchor)
	assert_eq(a.secrets_in_area(Vector2i(1, -1)).size(), b.secrets_in_area(Vector2i(1, -1)).size())
