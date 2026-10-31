extends GutTest
## M3 Task 3 (spec §14.1, §12.16 adapted): where Frostpeak hides its five kinds of secrets
## (FrostSecretRules): buried treasure under a blue-ice X in the snow, hidden rooms under igloos (a fake
## packed-snow floor opens onto stairs down), ice temples (the puzzle: three plates, a golden door, the
## treasure behind it), floating icebergs with a golden chest, and crystal geodes deep down. Every one is
## chosen from the seed and its 128 x 128 area alone, and stays inside its area.

const SEED := 12345
const AREAS := 7                  # areas -7..6 on each side are searched

var _rules: FrostSecretRules
var _shape: FrostShape


func before_all() -> void:
	_shape = FrostShape.new(SEED)
	_rules = FrostSecretRules.new(SEED, _shape)


func _all() -> Array:
	var out: Array = []
	for az in range(-AREAS, AREAS):
		for ax in range(-AREAS, AREAS):
			out.append_array(_rules.secrets_in_area(Vector2i(ax, az)))
	return out


func _of(kind: StringName) -> Array:
	return _all().filter(func(s: Dictionary) -> bool: return s.kind == kind)


func test_it_is_a_secret_rules_on_frost_terrain() -> void:
	assert_true(_rules is SecretRules)
	assert_true(_rules.shape is FrostShape)
	assert_true(FrostSecretRules.new(SEED).shape is FrostShape, "made without a shape: a frost one")
	assert_eq(_rules.spawn, _shape.spawn_column())


func test_all_five_kinds_are_placed_and_the_same_every_time() -> void:
	var counts := {}
	for s: Dictionary in _all():
		counts[s.kind] = counts.get(s.kind, 0) + 1
	for kind: StringName in SecretRules.PLACED:
		assert_gte(int(counts.get(kind, 0)), 3, "%s: %d" % [kind, counts.get(kind, 0)])
	var again := FrostSecretRules.new(SEED, FrostShape.new(SEED))
	for s: Dictionary in _rules.secrets_in_area(Vector2i(1, -2)):
		assert_eq(again.find(s.id).get("boxes"), s.boxes, s.id)
	gut.p("frost secrets in %d areas: %s" % [AREAS * AREAS * 4, counts])


func test_every_secret_stays_in_its_area_and_away_from_the_spawn() -> void:
	for s: Dictionary in _all():
		var a0: Vector2i = s.area * SecretRules.AREA
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi
		assert_true(lo.x >= a0.x and lo.z >= a0.y and hi.x <= a0.x + SecretRules.AREA and hi.z <= a0.y + SecretRules.AREA, s.id)
		assert_gt(Vector2(s.anchor.x - _rules.spawn.x, s.anchor.z - _rules.spawn.y).length(), SecretRules.SPAWN_CLEARING, s.id)


func test_buried_treasure_lies_under_a_blue_ice_x_in_the_snow() -> void:
	for s: Dictionary in _of(SecretRules.TREASURE):
		var c: Vector3i = s.chest
		assert_ne(_shape.terrain_at(c.x, c.z), FrostShape.LAKE, "%s is not on a lake" % s.id)
		var top := _shape.height_at(c.x, c.z) - 1
		assert_eq(_rules.block_at(Vector3i(c.x, top, c.z)), BlockIds.BLUE_ICE, "the X's middle")
		assert_eq(_rules.block_at(Vector3i(c.x - 2, _shape.height_at(c.x - 2, c.z - 2) - 1, c.z - 2)), BlockIds.BLUE_ICE, "a corner")
		assert_eq(_rules.block_at(c), BlockIds.AIR, "room for the chest")
		assert_between(top - c.y, 2, 4, "2-4 blocks down")


## "Igloos, with a secret inside sometimes": under some igloos a fake packed-snow floor opens onto stairs
## that go down to a hidden room (lanterns, a chest). The stairs are a path a child can walk: every step
## is at most one block down with room overhead, and nothing opens to the sky outside the igloo.
func test_hidden_rooms_are_under_igloos_behind_a_fake_snow_floor() -> void:
	var rooms := _of(SecretRules.ROOM)
	assert_gt(rooms.size(), 2)
	for s: Dictionary in rooms:
		var ig := _shape.igloo_near(s.stairs_top.x, s.stairs_top.z)
		assert_false(ig.is_empty(), "%s: under an igloo" % s.id)
		var c: Vector3i = ig.center
		assert_eq(s.stairs_top, c)
		for cell: Vector3i in s.fake_wall:
			assert_eq(_rules.block_at(cell), BlockIds.FAKE_SNOW, s.id)
			assert_eq(cell.y, c.y - 1, "in the igloo's floor")
			assert_lte(Vector2(cell.x - c.x, cell.z - c.z).length(), FrostShape.IGLOO_R - 1.0, "inside the igloo")
		assert_eq(SecretRules.fake_wall_group(s.fake_wall[0], _rules.block_at).size(), 2, "one knock opens both")
		assert_eq((s.fake_wall[0] as Vector3i) + (s.dir as Vector3i), (s.fake_wall[0] as Vector3i) + Vector3i.UP,
			"/secret sends a child into the igloo, over the floor")
		var a: Vector3i = s.anchor
		assert_eq(_rules.block_at(a), BlockIds.AIR, "the room is hollow")
		assert_lt(a.y, c.y - 4, "deep under the igloo")
		assert_true(SecretRules._contains(s.inside[0], s.inside[1], a), "standing in it finds it")
		assert_eq(_rules.block_at(s.chest), BlockIds.AIR)
		# the path down: from the hole, step by step, to the room
		var path: Array = s.path
		assert_gt(path.size(), 3)
		var prev: Vector3i = path[0]
		for p: Vector3i in path:
			assert_lte(prev.y - p.y, 1, "%s: at most one block down at %s" % [s.id, p])
			assert_lte(absi(prev.x - p.x) + absi(prev.z - p.z), 1, "a step at a time")
			assert_true(BlockIds.is_solid(_rules.block_at(p + Vector3i.DOWN)), "%s: a floor under %s" % [s.id, p])
			for up in 3:
				var q := p + Vector3i(0, up, 0)
				if not (s.fake_wall as Array).has(q):   # the fake floor opens with a knock
					assert_eq(_rules.block_at(q), BlockIds.AIR, "%s: room to walk at %s" % [s.id, q])
			var outside := Vector2(p.x - c.x, p.z - c.z).length() > FrostShape.IGLOO_R + 0.5
			if outside:
				assert_gte(_shape.height_at(p.x, p.z), p.y + 4, "%s: under the ground at %s" % [s.id, p])
			prev = p
		assert_true(SecretRules._contains(s.inside[0], s.inside[1], path[path.size() - 1]), "the path ends in the room")
		assert_gte(_shape.height_at(a.x, a.z), a.y + 5, "ground over the room")


func test_ice_temples_have_a_puzzle_vault() -> void:
	var temples := _of(SecretRules.TEMPLE)
	assert_gt(temples.size(), 0)
	for s: Dictionary in temples:
		var a: Vector3i = s.anchor
		assert_ne(_shape.terrain_at(a.x, a.z), FrostShape.LAKE, "%s is on dry ground" % s.id)
		assert_eq(s.plates.size(), 3)
		for p: Vector3i in s.plates:
			assert_eq(_rules.block_at(p), BlockIds.PRESSURE_PLATE)
		assert_eq(s.vault.size(), 2)
		for v: Vector3i in s.vault:
			assert_eq(_rules.block_at(v), BlockIds.YELLOW, "the golden door the plates open")
		assert_true(s.locked, "the chest waits for the puzzle")
		assert_eq(_rules.block_at(s.chest), BlockIds.AIR)
		assert_true(s.has("note"), "the note shows the order")
		assert_eq(_rules.block_at(a), BlockIds.AIR, "a hall inside")
		assert_eq(_rules.block_at(a + Vector3i.DOWN), BlockIds.PACKED_SNOW, "a floor of packed snow (not slippery)")
		var walls := 0
		for d: Vector3i in FrostShape.DIRS:
			if _rules.block_at(a + d * 5) == BlockIds.SNOW_BRICK:
				walls += 1
		assert_gte(walls, 3, "snow-brick walls (one side is the door)")
		assert_true(SecretRules._contains(s.inside[0], s.inside[1], a))


func test_floating_icebergs_carry_a_golden_chest_high_above_the_ground() -> void:
	for s: Dictionary in _of(SecretRules.ISLAND):
		var c: Vector3i = s.chest
		assert_eq(_rules.block_at(c + Vector3i.DOWN), BlockIds.SNOW, "snow on top")
		assert_eq(_rules.block_at(c + Vector3i(0, -4, 0)), BlockIds.BLUE_ICE, "an iceberg under it")
		assert_gt(c.y, _shape.height_at(c.x, c.z) + 20, "high above the ground")


func test_the_secret_director_can_find_them_by_id() -> void:
	for s: Dictionary in _all().slice(0, 12):
		assert_eq(_rules.find(s.id).id, s.id)
