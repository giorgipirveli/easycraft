extends GutTest
## Cosmos: Io (world 21, spec §21b.2): its secrets (SpaceSecretRules with Io's palette). Buried treasure under an X of
## sulphur crystals, a hidden warm room of black lava rock (like a lava tube) behind a fake Io-rock door, lit by glowing
## lava crust, the explorers' station (the puzzle temple in sulphur bricks: friendly and made up), sulphur crystal geodes,
## and the landmark: the Volcano Lander a short walk from the landing pad (the world's one ISLAND secret): a lander on
## four legs with heat tiles, a heat camera on a mast looking out, a dish, lights, a heat probe down into the ground, a
## golden chest on its deck. No secret is built into the lava lake or onto a volcano. No other world's blocks, no
## treasure pack, no mouse villages.

const SEED := 12345
const OTHERS_ONLY: Array[int] = [BlockIds.STONE, BlockIds.PLANKS, BlockIds.BRICK, BlockIds.FAKE_WALL, BlockIds.SAND,
	BlockIds.GRASS, BlockIds.DIRT, BlockIds.CRYSTAL, BlockIds.LIGHT, BlockIds.GOLD, BlockIds.MOON_ROCK, BlockIds.MOON_DUST,
	BlockIds.BASALT, BlockIds.ROVER_PANEL, BlockIds.DEEP_ICE, BlockIds.PROBE_PANEL, BlockIds.SALT]


func _rules(seed: int = SEED) -> SpaceSecretRules:
	return SpaceSecretRules.new(seed, SpaceShape.new(seed, SpaceShape.IO))


func _all(rules: SpaceSecretRules, n: int = 5) -> Array:
	var out: Array = []
	for az in range(-n, n):
		for ax in range(-n, n):
			out.append_array(rules.secrets_in_area(Vector2i(ax, az)))
	return out


func test_every_book_kind_in_ios_blocks() -> void:
	var rules := _rules()
	var kinds := {}
	var used := {}
	for s: Dictionary in _all(rules):
		kinds[s.kind] = int(kinds.get(s.kind, 0)) + 1
		for b: Array in s.boxes:
			assert_false(OTHERS_ONLY.has(int(b[2])), "%s: %s is another world's" % [s.id, BlockIds.display_name(b[2])])
			used[int(b[2])] = true
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.GEODE]:
		assert_gt(int(kinds.get(k, 0)), 0, "Io has %s" % k)
	assert_eq(int(kinds.get(SecretRules.ISLAND, 0)), 1, "one landmark: the Volcano Lander")
	for id in [BlockIds.SULPHUR_CRYSTAL, BlockIds.IO_ROCK, BlockIds.BLACK_LAVA, BlockIds.FAKE_IO_ROCK,
			BlockIds.SULPHUR_BRICK, BlockIds.LAVA_CRUST, BlockIds.STAR_GOLD, BlockIds.HEAT_TILE, BlockIds.LANDER_LEG,
			BlockIds.HEAT_CAMERA]:
		assert_true(used.has(id), "%s is used" % BlockIds.display_name(id))
	assert_null(rules.more, "no treasure pack on Io")
	assert_null(rules.tiny, "no mouse villages on Io")


func test_the_hidden_room_is_black_lava_behind_a_fake_io_rock_door() -> void:
	var rules := _rules()
	var rooms := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.ROOM:
			continue
		rooms += 1
		for c: Vector3i in s.fake_wall:
			assert_eq(rules.block_at(c), BlockIds.FAKE_IO_ROCK, "a knock opens it")
		var walls := 0
		var lamps := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.BLACK_LAVA:
				walls += 1
			elif b[2] == BlockIds.LAVA_CRUST:
				lamps += 1
		assert_gt(walls, 0, "walls of black lava rock, like a lava tube")
		assert_gt(lamps, 0, "lit by glowing lava crust")
	assert_gt(rooms, 0)


func test_the_explorers_station_is_a_friendly_puzzle_in_sulphur_bricks() -> void:
	var rules := _rules()
	var stations := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.TEMPLE:
			continue
		stations += 1
		var bricks := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.SULPHUR_BRICK:
				bricks += 1
		assert_gt(bricks, 0, "sulphur brick walls")
		assert_eq(s.plates.size(), 3, "its puzzle stays the Secret Book's")
	assert_gt(stations, 0)


func test_no_secret_is_built_into_the_lava_lake_or_onto_a_volcano() -> void:
	var rules := _rules()
	var io := rules.space.io
	var lc := io.lake_centre()
	for n in [5, 9]:
		for az in range(-n, n):
			for ax in range(-n, n):
				for s: Dictionary in rules.secrets_in_area(Vector2i(ax, az)):
					var lo: Vector3i = s.lo
					var hi: Vector3i = s.hi
					var near := Vector2(clampi(lc.x, lo.x, hi.x - 1) - lc.x, clampi(lc.y, lo.z, hi.z - 1) - lc.y).length()
					assert_gt(near, IoTerrain.LAKE_R + IoTerrain.RIM_W + 2.0, "%s keeps clear of the lava lake" % s.id)
					for v: Vector2i in io.vents_near((lo.x + hi.x) / 2, (lo.z + hi.z) / 2, 80):
						var dv := Vector2(clampi(v.x, lo.x, hi.x - 1) - v.x, clampi(v.y, lo.z, hi.z - 1) - v.y).length()
						assert_gt(dv, IoTerrain.CONE_R + IoTerrain.SKIRT, "%s keeps clear of the volcano at %s" % [s.id, v])


func test_the_volcano_lander_is_a_short_walk_from_the_pad() -> void:
	var rules := _rules()
	var lm := rules.landmark()
	assert_eq(lm.kind, SecretRules.ISLAND)
	assert_eq(lm.name, "Volcano Lander")
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


func test_the_volcano_lander_stands_on_four_legs_with_a_heat_camera_looking_out() -> void:
	var rules := _rules()
	var lm := rules.landmark()
	var c: Vector3i = lm.anchor
	var legs := 0
	for b: Array in lm.boxes:
		var lo: Vector3i = b[0]
		var hi: Vector3i = b[1]
		if int(b[2]) == BlockIds.LANDER_LEG and hi - lo == Vector3i(1, 3, 1) and lo.y == c.y \
				and (lo.x != c.x or lo.z != c.z):   # standing on the ground (the masts stand on the deck)
			legs += 1
	assert_eq(legs, 4, "four legs")
	assert_eq(rules.block_at(c + Vector3i(0, -2, 0)), BlockIds.LANDER_LEG, "a heat probe down into the ground")
	var chest: Vector3i = lm.chest
	assert_eq(rules.block_at(chest + Vector3i.DOWN), BlockIds.HEAT_TILE, "the chest stands on the deck")
	var dir: Vector3i = lm.dir
	var sp := rules.shape.spawn_column()
	var to_pad := Vector2(sp.x - chest.x, sp.y - chest.z).normalized()
	assert_gt(Vector2(dir.x, dir.z).dot(to_pad), 0.5, "it faces the landing pad")
	var ground := rules.shape.height_at(chest.x, chest.z)
	assert_lte(chest.y - ground, IoTerrain.MAX_STEP, "one Io jump up to the deck")
	var eye := c + dir * 3 + Vector3i(0, 8, 0)
	assert_eq(rules.block_at(eye), BlockIds.HEAT_CAMERA, "the heat camera on its mast looks out")
	var lights := 0
	for b: Array in lm.boxes:
		if int(b[2]) == BlockIds.HEAT_CAMERA:
			lights += 1
	assert_gte(lights, 5, "its camera and its lights")


func test_the_same_seed_the_same_secrets() -> void:
	var a := _rules()
	var b := _rules()
	assert_eq(a.landmark().id, b.landmark().id)
	assert_eq(a.landmark().anchor, b.landmark().anchor)
	assert_eq(a.secrets_in_area(Vector2i(1, -1)).size(), b.secrets_in_area(Vector2i(1, -1)).size())
