extends GutTest
## M3 Task 4 (spec §14.1, §12.16 adapted): where the Candy Kingdom hides its five kinds of secrets
## (CandySecretRules): buried treasure under an X of sprinkles, hidden rooms inside cake mountains behind a
## door of fake chocolate, gingerbread houses (the puzzle temple: plates, a note, a golden door and a vault),
## floating cakes with a golden chest, and rock-candy geodes deep down. Every one is chosen from the seed and
## its 128 x 128 area alone, and stays inside its area.

const SEED := 12345
const AREAS := 7                  # areas -7..6 on each side are searched

var _rules: CandySecretRules
var _shape: CandyShape


func before_all() -> void:
	_shape = CandyShape.new(SEED)
	_rules = CandySecretRules.new(SEED, _shape)


func _all() -> Array:
	var out: Array = []
	for az in range(-AREAS, AREAS):
		for ax in range(-AREAS, AREAS):
			out.append_array(_rules.secrets_in_area(Vector2i(ax, az)))
	return out


func _of(kind: StringName) -> Array:
	return _all().filter(func(s: Dictionary) -> bool: return s.kind == kind)


func test_it_is_a_secret_rules_on_candy_terrain() -> void:
	assert_true(_rules is SecretRules)
	assert_true(_rules.shape is CandyShape)
	assert_true(CandySecretRules.new(SEED).shape is CandyShape, "made without a shape: a candy one")
	assert_eq(_rules.spawn, _shape.spawn_column())


func test_all_five_kinds_are_placed_and_the_same_every_time() -> void:
	var counts := {}
	for s: Dictionary in _all():
		counts[s.kind] = counts.get(s.kind, 0) + 1
	for kind: StringName in SecretRules.PLACED:
		assert_gte(int(counts.get(kind, 0)), 3, "%s: %d" % [kind, counts.get(kind, 0)])
	var again := CandySecretRules.new(SEED, CandyShape.new(SEED))
	for s: Dictionary in _rules.secrets_in_area(Vector2i(1, -2)):
		assert_eq(again.find(s.id).get("boxes"), s.boxes, s.id)


func test_every_secret_stays_in_its_area_and_away_from_the_spawn() -> void:
	for s: Dictionary in _all():
		var a0: Vector2i = s.area * SecretRules.AREA
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi
		assert_true(lo.x >= a0.x and lo.z >= a0.y and hi.x <= a0.x + SecretRules.AREA and hi.z <= a0.y + SecretRules.AREA, s.id)
		assert_gt(Vector2(s.anchor.x - _rules.spawn.x, s.anchor.z - _rules.spawn.y).length(), SecretRules.SPAWN_CLEARING, s.id)


func test_buried_treasure_lies_under_an_x_of_sprinkles_on_the_frosting() -> void:
	for s: Dictionary in _of(SecretRules.TREASURE):
		var c: Vector3i = s.chest
		assert_eq(_shape.terrain_at(c.x, c.z), CandyShape.PLAINS, s.id)
		var top := _shape.height_at(c.x, c.z) - 1
		assert_eq(_rules.block_at(Vector3i(c.x, top, c.z)), BlockIds.SPRINKLES, "the X's middle")
		assert_eq(_rules.block_at(Vector3i(c.x + 2, _shape.height_at(c.x + 2, c.z + 2) - 1, c.z + 2)), BlockIds.SPRINKLES, "a corner")
		assert_eq(_rules.block_at(c), BlockIds.AIR, "room for the chest")
		assert_between(top - c.y, 2, 4, "2-4 blocks down")


func test_hidden_rooms_are_inside_cakes_behind_fake_chocolate() -> void:
	var rooms := _of(SecretRules.ROOM)
	assert_gt(rooms.size(), 0)
	for s: Dictionary in rooms:
		var a: Vector3i = s.anchor
		assert_eq(_shape.terrain_at(a.x, a.z), CandyShape.CAKE_MOUNTAIN, "%s is in a cake" % s.id)
		assert_gte(_shape.height_at(a.x, a.z), a.y + 5, "cake over the room")
		assert_eq(_rules.block_at(a), BlockIds.AIR, "the room is hollow")
		for cell: Vector3i in s.fake_wall:
			assert_eq(_rules.block_at(cell), BlockIds.FAKE_CHOCOLATE, s.id)
		var out: Vector3i = (s.fake_wall[0] as Vector3i) + (s.dir as Vector3i)
		assert_eq(_shape.terrain_at(out.x, out.z), CandyShape.PLAINS, "the door is in the cake's side, on frosting")
		assert_lte(absi(_shape.height_at(out.x, out.z) - (s.fake_wall[0] as Vector3i).y), 1, "at the ground outside")
		assert_true(SecretRules.is_fake_wall(BlockIds.FAKE_CHOCOLATE), "a knock opens it")
		assert_eq(SecretRules.fake_wall_group(s.fake_wall[0], _rules.block_at).size(), 2, "one knock opens both")
		assert_eq(_rules.block_at(s.chest), BlockIds.AIR)


func test_gingerbread_houses_have_a_golden_candy_a_puzzle_vault_and_windows() -> void:
	var houses := _of(SecretRules.TEMPLE)
	assert_gt(houses.size(), 0)
	for s: Dictionary in houses:
		var a: Vector3i = s.anchor
		var tip: Vector3i = s.tip
		assert_eq(_rules.block_at(tip), BlockIds.GOLDEN_CANDY, "%s: the golden candy on the roof" % s.id)
		assert_eq(tip.x, a.x)
		assert_eq(tip.z, a.z)
		var n := CandySecretRules.HOUSE_HALF
		assert_eq(_rules.block_at(Vector3i(a.x + n, a.y + 1, a.z + n)), BlockIds.GINGERBREAD, "gingerbread walls")
		var glass := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.SUGAR_GLASS:
				glass += 1
		assert_eq(glass, 2, "a window on each side")
		assert_eq(s.plates.size(), 3)
		for p: Vector3i in s.plates:
			assert_eq(_rules.block_at(p), BlockIds.PRESSURE_PLATE)
		for v: Vector3i in s.vault:
			assert_eq(_rules.block_at(v), BlockIds.YELLOW, "the golden door the plates open")
		assert_true(s.locked, "the chest waits for the puzzle")
		assert_eq(_rules.block_at(s.chest), BlockIds.AIR)
		assert_true(s.has("note"), "the note shows the order")
		assert_eq(_rules.block_at(a), BlockIds.AIR, "room inside")
		assert_true(SecretRules._contains(s.inside[0], s.inside[1], a), "the hall counts as found")
		var door := a + (s.dir as Vector3i) * n
		assert_eq(_rules.block_at(door), BlockIds.AIR, "a way in")


func test_floating_cakes_carry_a_golden_chest_high_above_the_ground() -> void:
	var cakes := _of(SecretRules.ISLAND)
	assert_gt(cakes.size(), 0)
	for s: Dictionary in cakes:
		var c: Vector3i = s.chest
		assert_eq(_rules.block_at(c + Vector3i.DOWN), BlockIds.SPRINKLES, "sprinkles on top")
		assert_eq(_rules.block_at(c + Vector3i.DOWN * 3), BlockIds.CAKE, "a layer cake")
		assert_gt(c.y, _shape.height_at(c.x, c.z) + 20, "high above the ground")
		var gold := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.GOLDEN_CANDY:
				gold += 1
		assert_eq(gold, 2, "golden candy in its side")


func test_the_secret_director_can_find_them_by_id() -> void:
	for s: Dictionary in _all().slice(0, 12):
		assert_eq(_rules.find(s.id).id, s.id)
