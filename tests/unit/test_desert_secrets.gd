extends GutTest
## M3 Task 2 (spec §14.1, §12.16 adapted): where the Sandstorm Desert hides its five kinds of secrets
## (DesertSecretRules): buried treasure under a red X in the sand, hidden rooms inside mesas behind a
## fake sandstone wall, pyramids (traps: arrow slits and a sand pit in the way in; a treasure room behind
## a golden door the pressure plates open), floating mesas with a golden chest, and crystal geodes deep
## down. Every one is chosen from the seed and its 128 x 128 area alone, and stays inside its area.

const SEED := 12345
const AREAS := 7                  # areas -7..6 on each side are searched


var _rules: DesertSecretRules
var _shape: DesertShape


func before_all() -> void:
	_shape = DesertShape.new(SEED)
	_rules = DesertSecretRules.new(SEED, _shape)


func _all() -> Array:
	var out: Array = []
	for az in range(-AREAS, AREAS):
		for ax in range(-AREAS, AREAS):
			out.append_array(_rules.secrets_in_area(Vector2i(ax, az)))
	return out


func _of(kind: StringName) -> Array:
	return _all().filter(func(s: Dictionary) -> bool: return s.kind == kind)


func test_it_is_a_secret_rules_on_desert_terrain() -> void:
	assert_true(_rules is SecretRules)
	assert_true(_rules.shape is DesertShape)
	assert_true(DesertSecretRules.new(SEED).shape is DesertShape, "made without a shape: a desert one")
	assert_eq(_rules.spawn, _shape.spawn_column())


func test_all_five_kinds_are_placed_and_the_same_every_time() -> void:
	var counts := {}
	for s: Dictionary in _all():
		counts[s.kind] = counts.get(s.kind, 0) + 1
	for kind: StringName in SecretRules.PLACED:
		assert_gte(int(counts.get(kind, 0)), 3, "%s: %d" % [kind, counts.get(kind, 0)])
	var again := DesertSecretRules.new(SEED, DesertShape.new(SEED))
	for s: Dictionary in _rules.secrets_in_area(Vector2i(1, -2)):
		assert_eq(again.find(s.id).get("boxes"), s.boxes, s.id)


func test_every_secret_stays_in_its_area_and_away_from_the_spawn() -> void:
	for s: Dictionary in _all():
		var a0: Vector2i = s.area * SecretRules.AREA
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi
		assert_true(lo.x >= a0.x and lo.z >= a0.y and hi.x <= a0.x + SecretRules.AREA and hi.z <= a0.y + SecretRules.AREA, s.id)
		assert_gt(Vector2(s.anchor.x - _rules.spawn.x, s.anchor.z - _rules.spawn.y).length(), SecretRules.SPAWN_CLEARING, s.id)


func test_buried_treasure_lies_under_a_red_x_in_the_open_sand() -> void:
	for s: Dictionary in _of(SecretRules.TREASURE):
		var c: Vector3i = s.chest
		assert_eq(_shape.terrain_at(c.x, c.z), DesertShape.DESERT, s.id)
		var top := _shape.height_at(c.x, c.z) - 1
		assert_eq(_rules.block_at(Vector3i(c.x, top, c.z)), BlockIds.RED_SAND, "the X's middle")
		assert_eq(_rules.block_at(Vector3i(c.x + 2, _shape.height_at(c.x + 2, c.z + 2) - 1, c.z + 2)), BlockIds.RED_SAND, "a corner")
		assert_eq(_rules.block_at(c), BlockIds.AIR, "room for the chest")
		assert_between(top - c.y, 2, 4, "2-4 blocks down")


func test_hidden_rooms_are_inside_mesas_behind_fake_sandstone() -> void:
	var rooms := _of(SecretRules.ROOM)
	assert_gt(rooms.size(), 0)
	for s: Dictionary in rooms:
		var a: Vector3i = s.anchor
		assert_eq(_shape.terrain_at(a.x, a.z), DesertShape.MESA, "%s is in a mesa" % s.id)
		assert_gte(_shape.height_at(a.x, a.z), a.y + 5, "rock over the room")
		assert_eq(_rules.block_at(a), BlockIds.AIR, "the room is hollow")
		for cell: Vector3i in s.fake_wall:
			assert_eq(_rules.block_at(cell), BlockIds.FAKE_SANDSTONE, s.id)
		var out: Vector3i = (s.fake_wall[0] as Vector3i) + (s.dir as Vector3i)
		assert_ne(_shape.terrain_at(out.x, out.z), DesertShape.MESA, "the wall is in the mesa's side")
		assert_lte(absi(_shape.height_at(out.x, out.z) - (s.fake_wall[0] as Vector3i).y), 1, "at the ground outside")
		assert_true(SecretRules.fake_wall_group(s.fake_wall[0], _rules.block_at).size() == 2, "one knock opens both")
		var chest: Vector3i = s.chest
		assert_eq(_rules.block_at(chest), BlockIds.AIR)


func test_pyramids_have_a_golden_tip_a_puzzle_vault_and_traps() -> void:
	var pyramids := _of(SecretRules.TEMPLE)
	assert_gt(pyramids.size(), 0)
	for s: Dictionary in pyramids:
		var a: Vector3i = s.anchor
		var tip: Vector3i = s.tip
		assert_eq(_rules.block_at(tip), BlockIds.PYRAMID_GOLD, "%s: the golden tip" % s.id)
		assert_eq(_rules.block_at(tip + Vector3i.UP), -1, "nothing on top")
		assert_eq(tip.x, a.x)
		assert_eq(tip.z, a.z)
		assert_eq(s.plates.size(), 3)
		for p: Vector3i in s.plates:
			assert_eq(_rules.block_at(p), BlockIds.PRESSURE_PLATE)
		assert_eq(s.vault.size(), 2)
		for v: Vector3i in s.vault:
			assert_eq(_rules.block_at(v), BlockIds.YELLOW, "the golden door the plates open")
		assert_true(s.locked, "the chest waits for the puzzle")
		assert_eq(_rules.block_at(s.chest), BlockIds.AIR)
		assert_true(s.has("note"), "the note shows the order")
		# the way in: open to the outside, with the arrow slits and a sand pit in it
		var entrance: Vector3i = s.entrance
		assert_eq(_rules.block_at(entrance), BlockIds.AIR, "the doorway")
		assert_eq(_rules.block_at(entrance + Vector3i.UP), BlockIds.AIR)
		assert_gte(s.traps.size(), 2, "arrow slits")
		for t: Dictionary in s.traps:
			assert_eq(_rules.block_at(t.cell), BlockIds.ARROW_SLIT, "a slit at %s" % t.cell)
			assert_eq(_rules.block_at(t.cell + (t.dir as Vector3i)), BlockIds.AIR, "it faces the corridor")
		assert_gt(s.pits.size(), 0, "a sand pit")
		for p: Vector3i in s.pits:
			assert_eq(_rules.block_at(p), BlockIds.TRAP_SAND, "the pit's lid")
			assert_eq(_rules.block_at(p + Vector3i.DOWN), BlockIds.AIR, "room to fall")
			assert_true(BlockIds.is_solid(_rules.block_at(p + Vector3i.DOWN * 2)), "a floor to stand on")
		assert_true(SecretRules._contains(s.inside[0], s.inside[1], a), "the chamber counts as found")


## A pyramid stands on open, fairly flat sand (not on a mesa or in an oasis) and never floats: its
## foundation reaches under the lowest ground of its footprint.
func test_pyramids_stand_on_the_open_desert() -> void:
	for s: Dictionary in _of(SecretRules.TEMPLE):
		var a: Vector3i = s.anchor
		var half := DesertSecretRules.PYRAMID_HALF
		for dz in [-half, 0, half]:
			for dx in [-half, 0, half]:
				var x: int = a.x + dx
				var z: int = a.z + dz
				assert_eq(_shape.terrain_at(x, z), DesertShape.DESERT, "%s at %d,%d" % [s.id, x, z])
				var floor_y: int = a.y - 1          # the chamber's floor level: the pyramid's ground row
				var under := mini(_shape.height_at(x, z) - 1, floor_y)
				assert_true(BlockIds.is_solid(_rules.block_at(Vector3i(x, under, z))), "no gap under it at %d,%d" % [x, z])


func test_floating_mesas_carry_a_golden_chest_high_above_the_ground() -> void:
	for s: Dictionary in _of(SecretRules.ISLAND):
		var c: Vector3i = s.chest
		assert_eq(_rules.block_at(c + Vector3i.DOWN), BlockIds.RED_SAND, "red sand on top")
		assert_gt(c.y, _shape.height_at(c.x, c.z) + 20, "high above the ground")


func test_the_secret_director_can_find_them_by_id() -> void:
	for s: Dictionary in _all().slice(0, 12):
		assert_eq(_rules.find(s.id).id, s.id)
