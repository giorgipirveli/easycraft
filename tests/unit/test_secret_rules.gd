extends GutTest
## M2 Task 16 (spec §12.16): where Green Meadows hides its secrets. SecretRules decides them from the world
## seed and the 128 × 128 area alone: a few per area, never in water, never in the spawn clearing, never on
## top of each other, and every structure's blocks.

const SEED := 12345

var rules: SecretRules
var shape: MeadowsShape


func before_all() -> void:
	rules = SecretRules.new(SEED)
	shape = MeadowsShape.new(SEED)


## Every secret in the areas -r..r-1 on both axes.
func _all(r: int = 4) -> Array:
	var out: Array = []
	for az in range(-r, r):
		for ax in range(-r, r):
			out.append_array(rules.secrets_in_area(Vector2i(ax, az)))
	return out


func _first(kind: StringName) -> Dictionary:
	for s: Dictionary in _all(6):
		if s.kind == kind:
			return s
	fail_test("no %s near the origin of seed %d" % [kind, SEED])
	return {}


func test_the_same_world_always_has_the_same_secrets() -> void:
	var again := SecretRules.new(SEED)
	for az in range(-3, 3):
		for ax in range(-3, 3):
			var a: Array = rules.secrets_in_area(Vector2i(ax, az))
			var b: Array = again.secrets_in_area(Vector2i(ax, az))
			assert_eq(a.size(), b.size())
			for i in mini(a.size(), b.size()):
				assert_eq(a[i].id, b[i].id)
				assert_eq(a[i].anchor, b[i].anchor)
				assert_eq(a[i].boxes, b[i].boxes)


func test_another_world_has_other_secrets() -> void:
	var other := SecretRules.new(SEED + 1)
	var same := 0
	var total := 0
	for az in range(-3, 3):
		for ax in range(-3, 3):
			for s: Dictionary in rules.secrets_in_area(Vector2i(ax, az)):
				total += 1
				for o: Dictionary in other.secrets_in_area(Vector2i(ax, az)):
					if o.anchor == s.anchor:
						same += 1
	assert_gt(total, 0)
	assert_lt(same, total / 4 + 1)


func test_every_area_has_a_few_secrets() -> void:
	var counts: Array[int] = []
	for az in range(-4, 4):
		for ax in range(-4, 4):
			counts.append(rules.secrets_in_area(Vector2i(ax, az)).size())
	var total := 0
	for n in counts:
		total += n
		assert_lte(n, SecretRules.ATTEMPTS.size() + rules.more.attempts().size())   # owner 42: and the pack's
	var average := total / float(counts.size())
	assert_between(average, 1.5, 5.0, "secrets per 128 × 128 area: %.2f" % average)


func test_every_kind_of_generated_secret_is_somewhere() -> void:
	var kinds := {}
	for s: Dictionary in _all(6):
		kinds[s.kind] = int(kinds.get(s.kind, 0)) + 1
	for kind in SecretRules.PLACED:
		assert_gt(int(kinds.get(kind, 0)), 0, String(kind))
	gut.p("secrets in 144 areas: %s" % kinds)


func test_secrets_stay_inside_their_own_area() -> void:
	for s: Dictionary in _all():
		var a: Vector2i = s.area
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi
		assert_true(lo.x >= a.x * SecretRules.AREA and hi.x <= (a.x + 1) * SecretRules.AREA, s.id)
		assert_true(lo.z >= a.y * SecretRules.AREA and hi.z <= (a.y + 1) * SecretRules.AREA, s.id)
		assert_eq(SecretRules.area_of(s.anchor.x, s.anchor.z), a, s.id)


func test_never_in_water() -> void:
	var checked := 0
	for s: Dictionary in _all():
		if not [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE].has(s.kind):
			continue
		var at: Vector3i = s.anchor
		assert_gt(shape.height_at(at.x, at.z), MeadowsShape.SEA_LEVEL + 1, s.id)
		assert_false(shape.is_river(at.x, at.z), s.id)
		checked += 1
	assert_gt(checked, 5)


func test_never_inside_the_spawn_clearing() -> void:
	var spawn := shape.spawn_column()
	assert_eq(rules.spawn, spawn)
	var home := SecretRules.area_of(spawn.x, spawn.y)
	for az in range(home.y - 1, home.y + 2):
		for ax in range(home.x - 1, home.x + 2):
			for s: Dictionary in rules.secrets_in_area(Vector2i(ax, az)):
				var lo: Vector3i = s.lo
				var hi: Vector3i = s.hi
				var dx := maxi(maxi(lo.x - spawn.x, spawn.x - (hi.x - 1)), 0)
				var dz := maxi(maxi(lo.z - spawn.y, spawn.y - (hi.z - 1)), 0)
				assert_gte(Vector2(dx, dz).length(), SecretRules.SPAWN_CLEARING, s.id)


func test_never_on_top_of_each_other() -> void:
	for az in range(-4, 4):
		for ax in range(-4, 4):
			var list: Array = rules.secrets_in_area(Vector2i(ax, az))
			for i in list.size():
				for j in range(i + 1, list.size()):
					var a: Dictionary = list[i]
					var b: Dictionary = list[j]
					var apart: bool = a.hi.x <= b.lo.x or b.hi.x <= a.lo.x or a.hi.z <= b.lo.z or b.hi.z <= a.lo.z
					assert_true(apart, "%s and %s share ground" % [a.id, b.id])


func test_ids_find_their_secret() -> void:
	for s: Dictionary in _all(2):
		assert_eq(rules.find(s.id).get("anchor"), s.anchor, s.id)
		assert_true(s.id.validate_node_name() == s.id, "an id is a valid node name: %s" % s.id)
	assert_true(rules.find("temple_99_99_9").is_empty())
	assert_true(rules.find("nonsense").is_empty())


# --- Each structure's blocks ---

func test_buried_treasure_is_a_chest_under_an_x() -> void:
	var s := _first(SecretRules.TREASURE)
	var chest: Vector3i = s.chest
	var h := shape.height_at(chest.x, chest.z)
	for c: Vector2i in SecretRules.X_CELLS:
		var top := Vector3i(chest.x + c.x, shape.height_at(chest.x + c.x, chest.z + c.y) - 1, chest.z + c.y)
		assert_eq(rules.block_at(top), BlockIds.SAND, "the X at %s" % top)
	assert_between(h - 1 - chest.y, 2, 4, "2 to 4 blocks to dig")
	assert_eq(rules.block_at(chest), BlockIds.AIR, "room for the chest")
	assert_eq(s.chest_kind, &"buried")


func test_a_hidden_room_hides_behind_a_fake_wall() -> void:
	var s := _first(SecretRules.ROOM)
	var fake: Array = s.fake_wall
	assert_eq(fake.size(), 2)
	for cell: Vector3i in fake:
		assert_eq(rules.block_at(cell), BlockIds.FAKE_WALL)
	assert_eq(rules.block_at(s.chest), BlockIds.AIR)
	assert_eq(rules.block_at(s.chest + Vector3i.DOWN), BlockIds.PLANKS, "a wooden floor")
	var lamps := 0
	for b: Array in s.boxes:
		if b[2] == BlockIds.LIGHT:
			lamps += 1
	assert_eq(lamps, 4, "a lamp in every corner")
	var top: Vector3i = s.stairs_top
	assert_eq(rules.block_at(top + Vector3i.UP), BlockIds.AIR)
	var out: Vector3i = top + (s.dir as Vector3i)
	assert_lte(shape.height_at(out.x, out.z), top.y + 1, "the stairs come out at the ground")
	assert_eq(s.chest_kind, &"room")


func test_some_hidden_rooms_have_a_riddle_note() -> void:
	var notes := 0
	var rooms := 0
	for s: Dictionary in _all(6):
		if s.kind != SecretRules.ROOM:
			continue
		rooms += 1
		if s.has("note"):
			notes += 1
			assert_eq(rules.block_at(s.note.cell), BlockIds.AIR)
			assert_lte((s.note.text as String).length(), 40, "short, simple words")
			assert_eq((s.note.pictures as Array).size(), 1)
	assert_gt(notes, 0)
	assert_lt(notes, rooms, "sometimes, not always")


func test_a_puzzle_temple_has_three_picture_plates_and_a_vault() -> void:
	var s := _first(SecretRules.TEMPLE)
	var plates: Array = s.plates
	assert_eq(plates.size(), 3)
	for p: Vector3i in plates:
		assert_eq(rules.block_at(p), BlockIds.PRESSURE_PLATE)
		assert_eq(rules.block_at(p + Vector3i.UP), BlockIds.AIR)
	var symbols: Array = (s.symbols as Array).duplicate()
	symbols.sort()
	var expected: Array = Riddles.TEMPLE_SYMBOLS.duplicate()
	expected.sort()
	assert_eq(symbols, expected, "sun, moon and star, one on each plate")
	var order: Array = (s.order as Array).duplicate()
	order.sort()
	assert_eq(order, [0, 1, 2])
	var pictures: Array = s.note.pictures
	for i in 3:
		assert_eq(pictures[i], s.symbols[s.order[i]], "the note draws the plates in the order to step on them")
	for v: Vector3i in s.vault:
		assert_eq(rules.block_at(v), BlockIds.YELLOW, "a golden (bright yellow) vault door")
	assert_eq(rules.block_at(s.chest), BlockIds.AIR)
	assert_true(s.locked, "the vault's chest is locked until the plates are solved")
	assert_eq(s.chest_kind, &"temple")


## A landmark children spot from afar: a stepped roof with a golden top, and lamps beside the door.
func test_a_temple_has_a_stepped_roof_with_a_golden_top_and_lamps_by_its_door() -> void:
	var s := _first(SecretRules.TEMPLE)
	var c: Vector3i = (s.anchor as Vector3i) + Vector3i.DOWN
	assert_eq(rules.block_at(c + Vector3i(0, 8, 0)), BlockIds.GOLD, "a golden top")
	assert_eq(rules.block_at(c + Vector3i(0, 7, 0)), BlockIds.STONE)
	assert_eq(rules.block_at(c + Vector3i(4, 6, -4)), BlockIds.STONE, "the first step")
	assert_eq(rules.block_at(c + Vector3i(5, 6, 5)), BlockIds.AIR)
	assert_eq(rules.block_at(c + Vector3i(3, 7, 3)), BlockIds.AIR, "the second step is smaller")
	var dir: Vector3i = s.dir
	var side := Vector3i(-dir.z, 0, dir.x)
	for across in [-2, 2]:
		assert_eq(rules.block_at(c + dir * 5 + side * across + Vector3i(0, 3, 0)), BlockIds.LIGHT, "a lamp by the door")


func test_a_sky_island_floats_high_with_a_golden_chest() -> void:
	var s := _first(SecretRules.ISLAND)
	var chest: Vector3i = s.chest
	assert_eq(rules.block_at(chest + Vector3i.DOWN), BlockIds.GRASS)
	assert_lte(rules.block_at(chest), BlockIds.AIR, "open sky over the island")
	assert_gt(chest.y, shape.height_at(chest.x, chest.z) + 20, "well above the ground")
	assert_eq(rules.block_at(chest + Vector3i(0, -12, 0)), -1, "floating: nothing far below the island")
	assert_eq(s.chest_kind, &"sky")


func test_a_crystal_geode_is_a_hollow_crystal_ball_deep_down() -> void:
	var s := _first(SecretRules.GEODE)
	var c: Vector3i = s.anchor
	var r: int = s.radius
	assert_lt(c.y + r, -20, "deep underground")
	assert_eq(rules.block_at(c), BlockIds.AIR, "hollow")
	for d: Vector3i in [Vector3i(r, 0, 0), Vector3i(-r, 0, 0), Vector3i(0, r, 0), Vector3i(0, -r, 0), Vector3i(0, 0, r), Vector3i(0, 0, -r)]:
		assert_true([BlockIds.CRYSTAL, BlockIds.DIAMOND].has(rules.block_at(c + d)), "shell at %s" % d)
	assert_false(s.has("chest"))


func test_nothing_is_built_where_there_is_no_secret() -> void:
	var spawn := rules.spawn
	for y in [-40, 0, 30, 60, 120]:
		assert_eq(rules.block_at(Vector3i(spawn.x, y, spawn.y)), -1)


# --- Fake walls and treasure maps ---

func test_a_fake_wall_opens_as_one_piece() -> void:
	var cells := {Vector3i(0, 1, 0): BlockIds.FAKE_WALL, Vector3i(0, 2, 0): BlockIds.FAKE_WALL,
		Vector3i(0, 3, 0): BlockIds.STONE, Vector3i(5, 1, 0): BlockIds.FAKE_WALL}
	var at := func(p: Vector3i) -> int: return cells.get(p, BlockIds.STONE)
	var group := SecretRules.fake_wall_group(Vector3i(0, 2, 0), at)
	group.sort()
	assert_eq(group, [Vector3i(0, 1, 0), Vector3i(0, 2, 0)] as Array[Vector3i])
	assert_eq(SecretRules.fake_wall_group(Vector3i(0, 3, 0), at), [] as Array[Vector3i], "stone is just stone")
	var long := func(p: Vector3i) -> int: return BlockIds.FAKE_WALL if p.y == 0 and p.z == 0 else BlockIds.STONE
	assert_eq(SecretRules.fake_wall_group(Vector3i.ZERO, long, 6).size(), 6, "capped")


func test_the_treasure_map_points_to_the_nearest_unopened_buried_treasure() -> void:
	var from := Vector3(10, 40, -20)
	var first := rules.nearest_buried(from)
	assert_false(first.is_empty())
	assert_eq(first.kind, SecretRules.TREASURE)
	var d1 := Vector2(first.chest.x - from.x, first.chest.z - from.z).length()
	for s: Dictionary in _all(3):
		if s.kind == SecretRules.TREASURE:
			assert_gte(Vector2(s.chest.x - from.x, s.chest.z - from.z).length() + 0.01, d1, "nearest")
	var next := rules.nearest_buried(from, {first.id: true})
	assert_false(next.is_empty())
	assert_ne(next.id, first.id, "opened chests are skipped: the map leads on to the next one")
	assert_gte(Vector2(next.chest.x - from.x, next.chest.z - from.z).length() + 0.01, d1)


func test_secrets_near_a_point() -> void:
	var s := _first(SecretRules.TEMPLE)
	var near := rules.secrets_near(Vector3(s.anchor), 30.0)
	assert_true(near.any(func(o: Dictionary) -> bool: return o.id == s.id))
	var far := rules.secrets_near(Vector3(s.anchor) + Vector3(5000, 0, 5000), 30.0)
	assert_false(far.any(func(o: Dictionary) -> bool: return o.id == s.id))
