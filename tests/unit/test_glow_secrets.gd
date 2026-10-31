extends GutTest
## Universe 6, the Glow Caves (spec §5.7, §12.16 adapted): where the caves hide their secrets (GlowSecretRules): buried
## treasure under an X of cave pearls on the cavern floor, hidden rooms under the floor behind a door of fake cave
## stone (spore lamps, fungus planks; a riddle note in some), the puzzle temple (a flowstone hall under a high
## ceiling: plates, a note, a golden door, a vault), hidden grottos (a round chamber under the floor with a glow-worm
## ceiling, a pool of cave pearls and a golden chest, its stairs behind a fake cave stone door in a rock mound) and
## selenite geodes with cave gold and diamonds; the treasure pack's places in the caves' blocks. Each in its 128 x 128
## area, on open floor with room under the ceiling: nothing pokes through a ceiling, nothing stands in a wall, a shaft
## or a lake.

const SEED := 20261017
const AREAS := 5

var _rules: GlowSecretRules
var _shape: GlowShape
var _all: Array = []


func before_all() -> void:
	_shape = GlowShape.new(SEED)
	_rules = GlowSecretRules.new(SEED, _shape)
	for az in range(-AREAS, AREAS):
		for ax in range(-AREAS, AREAS):
			_all.append_array(_rules.secrets_in_area(Vector2i(ax, az)))


func _of(kind: StringName) -> Array:
	return _all.filter(func(s: Dictionary) -> bool: return s.kind == kind)


func _blocks(s: Dictionary) -> Dictionary:
	var out := {}
	for b: Array in s.boxes:
		out[b[2]] = true
	return out


func test_it_is_a_secret_rules_on_the_caves() -> void:
	assert_true(_rules is SecretRules)
	assert_true(_rules.shape is GlowShape)
	assert_true(GlowSecretRules.new(SEED).shape is GlowShape, "made without a shape: the caves'")
	assert_eq(_rules.spawn, _shape.spawn_column())
	assert_not_null(_rules.more, "the treasure pack")
	assert_eq(_rules.more.style, TreasurePlaces.GLOW, "in the caves' blocks")


func test_all_five_kinds_are_placed_and_the_same_every_time() -> void:
	var counts := {}
	for s: Dictionary in _all:
		counts[s.kind] = counts.get(s.kind, 0) + 1
	for kind: StringName in SecretRules.PLACED:
		assert_gte(int(counts.get(kind, 0)), 3, "%s: %s" % [kind, counts])
	var pack := 0
	for kind: StringName in TreasurePlaces.PLACED:
		pack += int(counts.get(kind, 0))
	assert_gt(pack, 2, "and some of the treasure pack's places: %s" % [counts])
	var again := GlowSecretRules.new(SEED, GlowShape.new(SEED))
	for s: Dictionary in _rules.secrets_in_area(Vector2i(1, -2)):
		assert_eq(again.find(s.id).get("boxes"), s.boxes, s.id)


func test_every_secret_stays_in_its_area_and_away_from_the_spawn() -> void:
	for s: Dictionary in _all:
		var a0: Vector2i = s.area * SecretRules.AREA
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi
		assert_true(lo.x >= a0.x and lo.z >= a0.y and hi.x <= a0.x + SecretRules.AREA and hi.z <= a0.y + SecretRules.AREA, s.id)
		assert_gt(Vector2(s.anchor.x - _rules.spawn.x, s.anchor.z - _rules.spawn.y).length(), SecretRules.SPAWN_CLEARING, s.id)
		assert_gt(lo.y, GlowShape.BED_BOTTOM + 3, "%s over the bedrock" % s.id)


## Every secret stands on open floor under the caves' roof: no column under it is a wall or a daylight shaft, none is
## a lake, and nothing reaches up into a ceiling (a building's top stays a block under it).
func test_secrets_fit_their_caves() -> void:
	for s: Dictionary in _all:
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi
		for z in range(lo.z, hi.z, 2):
			for x in range(lo.x, hi.x, 2):
				var c := _shape.column(x, z)
				if c.x == c.y or _shape.in_shaft(x, z):
					assert_true(false, "%s in rock or a shaft at %d,%d" % [s.id, x, z])
					return
				if hi.y > c.y:
					assert_true(false, "%s pokes into the ceiling at %d,%d (%d > %d)" % [s.id, x, z, hi.y, c.y])
					return
				if c.x <= GlowShape.LAKE_LEVEL + 1:
					assert_true(false, "%s in a lake at %d,%d" % [s.id, x, z])
					return
	assert_true(true)


func test_buried_treasure_lies_under_an_x_of_cave_pearls() -> void:
	for s: Dictionary in _of(SecretRules.TREASURE):
		var x_cells := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.CAVE_PEARL:
				x_cells += 1
				var cell: Vector3i = b[0]
				assert_eq(cell.y, _shape.height_at(cell.x, cell.z) - 1, "on the floor: %s" % s.id)
		assert_eq(x_cells, SecretRules.X_CELLS.size(), s.id)
		var chest: Vector3i = s.chest
		assert_lt(chest.y, _shape.height_at(chest.x, chest.z) - 1, "under the floor")


func test_hidden_rooms_are_in_the_caves_blocks() -> void:
	for s: Dictionary in _of(SecretRules.ROOM):
		var used := _blocks(s)
		assert_true(used.has(BlockIds.FAKE_CAVE_STONE), "a door of fake cave stone: %s" % s.id)
		assert_true(used.has(BlockIds.SPORE_LAMP), "spore lamps")
		assert_true(used.has(BlockIds.FUNGUS_PLANKS), "a fungus-plank floor")
		for id in [BlockIds.STONE, BlockIds.PLANKS, BlockIds.LIGHT, BlockIds.FAKE_WALL]:
			assert_false(used.has(id), "no meadows block %s in %s" % [BlockIds.display_name(id), s.id])
		for p: Vector3i in s.fake_wall:
			assert_true(SecretRules.is_fake_wall(BlockIds.FAKE_CAVE_STONE))


func test_the_puzzle_temple_is_a_flowstone_hall_with_its_plates() -> void:
	var temples := _of(SecretRules.TEMPLE)
	for s: Dictionary in temples:
		var used := _blocks(s)
		assert_true(used.has(BlockIds.FLOWSTONE), s.id)
		assert_true(used.has(BlockIds.PRESSURE_PLATE), s.id)
		assert_true(used.has(BlockIds.CAVE_GOLD), "a cave gold tip")
		assert_eq((s.plates as Array).size(), 3)
		assert_true(s.has("note"))
		assert_false(used.has(BlockIds.STONE))


## A hidden grotto: a round chamber under the floor, its ceiling of glow-worms, a pool with cave pearls, a golden chest
## inside, its stairs behind a door of fake cave stone in a rock mound on the floor.
func test_hidden_grottos() -> void:
	var grottos := _of(SecretRules.ISLAND)
	assert_gt(grottos.size(), 2)
	for s: Dictionary in grottos:
		var used := _blocks(s)
		for id in [BlockIds.GLOW_WORMS, BlockIds.CAVE_PEARL, BlockIds.WATER, BlockIds.FAKE_CAVE_STONE]:
			assert_true(used.has(id), "%s has %s" % [s.id, BlockIds.display_name(id)])
		var chest: Vector3i = s.chest
		assert_lt(chest.y, _shape.height_at(chest.x, chest.z), "the chest is under the floor")
		assert_eq(s.chest_kind, &"sky", "a golden chest")
		assert_true(s.has("fake_wall"), "a door that knocks open")
		assert_true(s.has("inside"))


func test_geodes_are_selenite_with_cave_gold_and_diamonds() -> void:
	for s: Dictionary in _of(SecretRules.GEODE):
		var used := _blocks(s)
		assert_true(used.has(BlockIds.SELENITE), s.id)
		assert_true(used.has(BlockIds.CAVE_GOLD) or used.has(BlockIds.DIAMOND), s.id)
		var c: Vector3i = s.anchor
		assert_lt(c.y + s.radius, _shape.height_at(c.x, c.z) - 2, "rock over it")


## The treasure pack builds its places the caves' way.
func test_the_pack_builds_in_the_caves_blocks() -> void:
	var places := _all.filter(func(s: Dictionary) -> bool: return TreasurePlaces.is_kind(s.kind))
	assert_false(places.is_empty())
	for s: Dictionary in places:
		assert_true(TreasurePlaces.KINDS_BY_STYLE[TreasurePlaces.GLOW].has(s.kind), "%s fits the caves" % s.kind)
		var used := _blocks(s)
		for id in [BlockIds.GRASS, BlockIds.LOG, BlockIds.LEAVES]:
			assert_false(used.has(id), "%s has no %s" % [s.id, BlockIds.display_name(id)])
