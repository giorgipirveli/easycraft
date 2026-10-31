extends GutTest
## Owner feedback #55 (spec §21.2): the space worlds' secrets (SpaceSecretRules): the Secret Book's kinds built in the
## planet's own blocks (the Moon: crystals mark buried treasure, the hidden rooms are cheese behind fake moon rock, the
## star temple is silver with star gold on top, the geodes are moon crystal), and the planet's landmark — the Moon Base
## — as the world's one ISLAND secret: near the landing pad (a short walk), its door facing the pad, a golden chest
## inside, found by walking in. No Green Meadows block, no treasure pack or mouse village in space.

const SEED := 12345
const MEADOWS_ONLY: Array[int] = [BlockIds.STONE, BlockIds.PLANKS, BlockIds.BRICK, BlockIds.FAKE_WALL, BlockIds.SAND,
	BlockIds.GRASS, BlockIds.DIRT, BlockIds.CRYSTAL, BlockIds.LIGHT, BlockIds.GOLD]


func _rules(planet: StringName = SpaceShape.MOON) -> SpaceSecretRules:
	return SpaceSecretRules.new(SEED, SpaceShape.new(SEED, planet))


func _all(rules: SpaceSecretRules, n: int = 5) -> Array:
	var out: Array = []
	for az in range(-n, n):
		for ax in range(-n, n):
			out.append_array(rules.secrets_in_area(Vector2i(ax, az)))
	return out


func test_the_book_kinds_are_there_in_the_planets_blocks() -> void:
	for planet: StringName in SpaceShape.PLANETS:
		var rules := _rules(planet)
		var kinds := {}
		for s: Dictionary in _all(rules):
			kinds[s.kind] = int(kinds.get(s.kind, 0)) + 1
			for b: Array in s.boxes:
				assert_false(MEADOWS_ONLY.has(int(b[2])), "%s %s: %s is Green Meadows'" % [planet, s.id, BlockIds.display_name(b[2])])
			if s.has("fake_wall"):
				for c: Vector3i in s.fake_wall:
					assert_true(SecretRules.is_fake_wall(rules.block_at(c)), "%s: a knock opens it" % s.id)
		for k: StringName in [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE, SecretRules.GEODE]:
			assert_gt(int(kinds.get(k, 0)), 0, "%s has %s" % [planet, k])
		assert_eq(int(kinds.get(SecretRules.ISLAND, 0)), 1, "%s: one landmark" % planet)
		assert_null(rules.more, "no treasure pack in space")
		assert_null(rules.tiny, "no mouse villages in space")


func test_the_moons_rooms_are_cheese() -> void:
	var rules := _rules()
	var cheese := 0
	for s: Dictionary in _all(rules):
		if s.kind == SecretRules.ROOM:
			for b: Array in s.boxes:
				if b[2] == BlockIds.MOON_CHEESE:
					cheese += 1
			for c: Vector3i in s.fake_wall:
				assert_eq(rules.block_at(c), BlockIds.FAKE_MOON_ROCK)
	assert_gt(cheese, 0, "the Moon IS made of cheese")


func test_the_landmark_is_a_short_walk_from_the_pad_and_found_inside() -> void:
	for planet: StringName in SpaceShape.PLANETS:
		var rules := _rules(planet)
		var shape := rules.shape
		var lm := rules.landmark()
		assert_eq(lm.kind, SecretRules.ISLAND)
		var sp := shape.spawn_column()
		var at: Vector3i = lm.anchor
		var d := Vector2(at.x - sp.x, at.z - sp.y).length()
		assert_between(d, 30.0, 70.0, "%s: a short walk from the pad (%.0f)" % [planet, d])
		assert_true(lm.has("chest") and lm.has("inside"), planet)
		assert_eq(lm.chest_kind, &"sky", "a golden chest")
		assert_eq(rules.find(lm.id), lm, "the Secret Book finds it by id")
		var inside: Array = lm.inside
		assert_true(SecretRules._contains(inside[0], inside[1], lm.chest), "%s: the chest is where it is found" % planet)
		assert_eq(rules.block_at(lm.chest), BlockIds.AIR, "the chest's cell is free")
		var area := SecretRules.area_of(at.x, at.z)
		var a0 := area * SecretRules.AREA
		assert_true(lm.lo.x >= a0.x and lm.lo.z >= a0.y and lm.hi.x <= a0.x + SecretRules.AREA and lm.hi.z <= a0.y + SecretRules.AREA,
			"%s: inside its own area" % planet)
		for s: Dictionary in rules.secrets_in_area(area):
			if s.id != lm.id:
				var clear: bool = s.hi.x + SecretRules.GAP <= lm.lo.x or lm.hi.x + SecretRules.GAP <= s.lo.x \
					or s.hi.z + SecretRules.GAP <= lm.lo.z or lm.hi.z + SecretRules.GAP <= s.lo.z
				assert_true(clear, "%s: nothing built into the landmark" % planet)


func test_the_moon_base_is_a_silver_dome_with_a_door_toward_the_pad() -> void:
	var rules := _rules()
	var lm := rules.landmark()
	var c: Vector3i = lm.anchor
	assert_eq(rules.block_at(c + Vector3i(0, -1, 0)), BlockIds.BASE_PANEL, "a floor")
	assert_eq(rules.block_at(c + Vector3i(0, 2, 0)), BlockIds.AIR, "room inside")
	var dir: Vector3i = lm.dir
	var door := c + dir * SpaceSecretRules.DOME_RADIUS
	assert_eq(rules.block_at(door), BlockIds.AIR, "the door")
	assert_eq(rules.block_at(door + Vector3i.UP), BlockIds.AIR)
	var sp := rules.shape.spawn_column()
	var to_pad := Vector2(sp.x - c.x, sp.y - c.z).normalized()
	assert_gt(Vector2(dir.x, dir.z).dot(to_pad), 0.5, "the door faces the landing pad")
	var panels := 0
	var portholes := 0
	for b: Array in lm.boxes:
		if b[2] == BlockIds.BASE_PANEL:
			panels += 1
		if b[2] == BlockIds.PORTHOLE:
			portholes += 1
	assert_gt(panels, 10)
	assert_gte(portholes, 3, "round windows")


func test_the_same_seed_gives_the_same_secrets() -> void:
	var a := _rules()
	var b := _rules()
	assert_eq(a.landmark().id, b.landmark().id)
	assert_eq(a.secrets_in_area(Vector2i(1, -1)).size(), b.secrets_in_area(Vector2i(1, -1)).size())
