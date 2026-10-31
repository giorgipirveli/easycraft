extends GutTest
## Cosmos: Mars (world 19, spec §21b.2): its secrets (SpaceSecretRules with Mars's palette). Buried treasure under an X
## of gypsum crystals, a hidden explorers' room of basalt behind a fake basalt door, an old lander's puzzle (the temple
## in gold foil and rover panels, friendly and made up), gypsum geodes, and the landmark: a six-wheeled rover a short
## walk from the landing pad (the world's one ISLAND secret: climb onto its deck to find its golden chest). No other
## world's blocks, no treasure pack, no mouse villages.

const SEED := 12345
const MEADOWS_ONLY: Array[int] = [BlockIds.STONE, BlockIds.PLANKS, BlockIds.BRICK, BlockIds.FAKE_WALL, BlockIds.SAND,
	BlockIds.GRASS, BlockIds.DIRT, BlockIds.CRYSTAL, BlockIds.LIGHT, BlockIds.GOLD, BlockIds.MOON_ROCK, BlockIds.MOON_DUST]


func _rules(seed: int = SEED) -> SpaceSecretRules:
	return SpaceSecretRules.new(seed, SpaceShape.new(seed, SpaceShape.MARS))


func _all(rules: SpaceSecretRules, n: int = 5) -> Array:
	var out: Array = []
	for az in range(-n, n):
		for ax in range(-n, n):
			out.append_array(rules.secrets_in_area(Vector2i(ax, az)))
	return out


func test_every_book_kind_in_mars_blocks() -> void:
	var rules := _rules()
	var kinds := {}
	var used := {}
	for s: Dictionary in _all(rules):
		kinds[s.kind] = int(kinds.get(s.kind, 0)) + 1
		for b: Array in s.boxes:
			assert_false(MEADOWS_ONLY.has(int(b[2])), "%s: %s is another world's" % [s.id, BlockIds.display_name(b[2])])
			used[int(b[2])] = true
	for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.GEODE]:
		assert_gt(int(kinds.get(k, 0)), 0, "Mars has %s" % k)
	assert_eq(int(kinds.get(SecretRules.ISLAND, 0)), 1, "one landmark: the rover")
	for id in [BlockIds.GYPSUM, BlockIds.BASALT, BlockIds.FAKE_BASALT, BlockIds.LANDER_FOIL, BlockIds.ROVER_LIGHT,
			BlockIds.STAR_GOLD]:
		assert_true(used.has(id), "%s is used" % BlockIds.display_name(id))
	assert_null(rules.more, "no treasure pack on Mars")
	assert_null(rules.tiny, "no mouse villages on Mars")


func test_the_hidden_room_is_basalt_behind_a_fake_basalt_door() -> void:
	var rules := _rules()
	var rooms := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.ROOM:
			continue
		rooms += 1
		for c: Vector3i in s.fake_wall:
			assert_eq(rules.block_at(c), BlockIds.FAKE_BASALT, "a knock opens it")
		var walls := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.BASALT:
				walls += 1
		assert_gt(walls, 0)
	assert_gt(rooms, 0)


func test_the_old_lander_is_a_friendly_puzzle_in_gold_foil() -> void:
	var rules := _rules()
	var landers := 0
	for s: Dictionary in _all(rules):
		if s.kind != SecretRules.TEMPLE:
			continue
		landers += 1
		var foil := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.LANDER_FOIL:
				foil += 1
		assert_gt(foil, 0, "gold foil walls")
		assert_eq(s.plates.size(), 3, "its puzzle stays the Secret Book's")
	assert_gt(landers, 0)


func test_the_rover_is_a_short_walk_from_the_pad() -> void:
	var rules := _rules()
	var lm := rules.landmark()
	assert_eq(lm.kind, SecretRules.ISLAND)
	assert_eq(lm.name, "Mars Rover")
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


func test_the_rover_has_six_wheels_a_solar_deck_and_a_camera_mast() -> void:
	var rules := _rules()
	var lm := rules.landmark()
	var wheels := 0
	var solar := 0
	var lights := 0
	for b: Array in lm.boxes:
		var cells := (b[1] as Vector3i) - (b[0] as Vector3i)
		var n := cells.x * cells.y * cells.z
		match int(b[2]):
			BlockIds.ROVER_WHEEL:
				wheels += 1
			BlockIds.SOLAR_PANEL:
				solar += n
			BlockIds.ROVER_LIGHT:
				lights += n
	assert_eq(wheels, 6, "six wheels, like real Mars rovers")
	assert_gt(solar, 30, "a deck of solar panels")
	assert_gte(lights, 2, "the camera's two eyes")
	var chest: Vector3i = lm.chest
	assert_eq(rules.block_at(chest + Vector3i.DOWN), BlockIds.SOLAR_PANEL, "the chest stands on the deck")
	var dir: Vector3i = lm.dir
	var sp := rules.shape.spawn_column()
	var to_pad := Vector2(sp.x - chest.x, sp.y - chest.z).normalized()
	assert_gt(Vector2(dir.x, dir.z).dot(to_pad), 0.5, "it faces the landing pad")
	var ground := rules.shape.height_at(chest.x, chest.z)
	assert_lte(chest.y - ground, 6, "a child can climb up (wheels are steps)")


func test_the_rover_leaves_tracks_behind_it() -> void:
	var rules := _rules()
	var lm := rules.landmark()
	var dir: Vector3i = lm.dir
	var c: Vector3i = lm.anchor
	var tracks := 0
	for k in range(7, 13):
		var p := c - dir * k
		var side := Vector3i(-dir.z, 0, dir.x)
		for s: int in [-3, 3]:
			var q := p + side * s
			var h := rules.shape.height_at(q.x, q.z)
			if rules.block_at(Vector3i(q.x, h - 1, q.z)) == BlockIds.MARS_REGOLITH:
				tracks += 1
	assert_gt(tracks, 8, "two lines of wheel tracks in the dust")


func test_the_same_seed_the_same_secrets() -> void:
	var a := _rules()
	var b := _rules()
	assert_eq(a.landmark().id, b.landmark().id)
	assert_eq(a.landmark().anchor, b.landmark().anchor)
	assert_eq(a.secrets_in_area(Vector2i(1, -1)).size(), b.secrets_in_area(Vector2i(1, -1)).size())
