extends GutTest
## Owner feedback #39 (spec §14.2a, §12.16 adapted): where the Dragon Realm hides its secrets (DragonSecretRules):
## buried treasure under an X of ember scales, hidden rooms inside islands behind a door of fake floatstone, sky shrines
## (the puzzle temple: plates, a note, a golden door and a vault), dragon nests (little floating islands just off a big
## one, each with a dragon egg's cell in its nest) and amethyst geodes inside thick islands; the treasure pack's places
## in the realm's blocks. Every one stays inside its 128 x 128 area and, but a nest, stands on an island: nothing hangs
## over the void.

const SEED := 12345
const AREAS := 6                  # areas -6..5 on each side are searched

var _rules: DragonSecretRules
var _shape: DragonShape
var _all_cache: Array = []


func before_all() -> void:
	_shape = DragonShape.new(SEED)
	_rules = DragonSecretRules.new(SEED, _shape)
	for az in range(-AREAS, AREAS):
		for ax in range(-AREAS, AREAS):
			_all_cache.append_array(_rules.secrets_in_area(Vector2i(ax, az)))


func _of(kind: StringName) -> Array:
	return _all_cache.filter(func(s: Dictionary) -> bool: return s.kind == kind)


func test_it_is_a_secret_rules_on_dragon_terrain() -> void:
	assert_true(_rules is SecretRules)
	assert_true(_rules.shape is DragonShape)
	assert_true(DragonSecretRules.new(SEED).shape is DragonShape, "made without a shape: the realm's")
	assert_eq(_rules.spawn, _shape.spawn_column())
	assert_eq(_rules.more.style, TreasurePlaces.DRAGON, "the treasure pack builds in the realm's blocks")


func test_all_five_kinds_are_placed_and_the_same_every_time() -> void:
	var counts := {}
	for s: Dictionary in _all_cache:
		counts[s.kind] = counts.get(s.kind, 0) + 1
	for kind: StringName in SecretRules.PLACED:
		assert_gte(int(counts.get(kind, 0)), 3, "%s: %d" % [kind, counts.get(kind, 0)])
	var pack := 0
	for kind: StringName in TreasurePlaces.PLACED:
		pack += int(counts.get(kind, 0))
	assert_gt(pack, 2, "and some of the treasure pack's places: %s" % [counts])
	var again := DragonSecretRules.new(SEED, DragonShape.new(SEED))
	for s: Dictionary in _rules.secrets_in_area(Vector2i(1, -2)):
		assert_eq(again.find(s.id).get("boxes"), s.boxes, s.id)


func test_every_secret_stays_in_its_area_and_away_from_the_spawn() -> void:
	for s: Dictionary in _all_cache:
		var a0: Vector2i = s.area * SecretRules.AREA
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi
		assert_true(lo.x >= a0.x and lo.z >= a0.y and hi.x <= a0.x + SecretRules.AREA and hi.z <= a0.y + SecretRules.AREA, s.id)
		assert_gt(Vector2(s.anchor.x - _rules.spawn.x, s.anchor.z - _rules.spawn.y).length(), SecretRules.SPAWN_CLEARING, s.id)
		assert_gte(lo.y, DragonShape.MIN_BOTTOM, "%s never down in the void" % s.id)


## Nothing hangs over the void or pokes out of an island's underside: every column under a secret (a nest aside) is
## island rock reaching below its lowest block.
func test_no_secret_hangs_over_the_void() -> void:
	for s: Dictionary in _all_cache:
		if s.kind == SecretRules.ISLAND:
			continue
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi
		for z in range(lo.z, hi.z):
			for x in range(lo.x, hi.x):
				var c := _shape.column(x, z)
				if c.x <= c.y or c.y >= lo.y:
					assert_true(false, "%s over the void at %d,%d (island %s)" % [s.id, x, z, c])
					return
	assert_true(true)


func test_buried_treasure_lies_under_an_x_of_ember_scales() -> void:
	for s: Dictionary in _of(SecretRules.TREASURE):
		var c: Vector3i = s.chest
		assert_true(_shape.is_island(c.x, c.z), s.id)
		var top := _shape.height_at(c.x, c.z) - 1
		assert_eq(_rules.block_at(Vector3i(c.x, top, c.z)), BlockIds.EMBER_SCALE, "the X's middle")
		assert_eq(_rules.block_at(Vector3i(c.x + 2, _shape.height_at(c.x + 2, c.z + 2) - 1, c.z + 2)), BlockIds.EMBER_SCALE, "a corner")
		assert_eq(_rules.block_at(c), BlockIds.AIR, "room for the chest")
		assert_between(top - c.y, 2, 4, "2-4 blocks down")
		assert_lt(_shape.column(c.x, c.z).y, c.y, "rock under the chest, not the void")


func test_hidden_rooms_are_inside_islands_behind_fake_floatstone() -> void:
	var rooms := _of(SecretRules.ROOM)
	assert_gt(rooms.size(), 0)
	for s: Dictionary in rooms:
		var a: Vector3i = s.anchor
		assert_gte(_shape.height_at(a.x, a.z), a.y + 5, "rock over the room")
		assert_eq(_rules.block_at(a), BlockIds.AIR, "the room is hollow")
		for cell: Vector3i in s.fake_wall:
			assert_eq(_rules.block_at(cell), BlockIds.FAKE_FLOATSTONE, s.id)
		assert_eq(SecretRules.fake_wall_group(s.fake_wall[0], _rules.block_at).size(), 2, "one knock opens both")
		var top: Vector3i = s.stairs_top
		assert_true(_shape.is_island(top.x, top.z), "the stairs come out on the island")
		assert_eq(_rules.block_at(s.chest), BlockIds.AIR)


func test_sky_shrines_have_dragon_gold_a_puzzle_vault_and_windows() -> void:
	var shrines := _of(SecretRules.TEMPLE)
	assert_gt(shrines.size(), 0)
	for s: Dictionary in shrines:
		var a: Vector3i = s.anchor
		var tip: Vector3i = s.tip
		assert_eq(_rules.block_at(tip), BlockIds.DRAGON_GOLD, "%s: dragon gold on the roof" % s.id)
		var n := DragonSecretRules.SHRINE_HALF
		assert_eq(_rules.block_at(Vector3i(a.x + n, a.y + 1, a.z + n)), BlockIds.FLOATSTONE_BRICK, "brick walls")
		var glass := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.STARGLASS:
				glass += 1
		assert_eq(glass, 2, "a window on each side")
		assert_eq(s.plates.size(), 3)
		for p: Vector3i in s.plates:
			assert_eq(_rules.block_at(p), BlockIds.PRESSURE_PLATE)
		for v: Vector3i in s.vault:
			assert_eq(_rules.block_at(v), BlockIds.YELLOW, "the golden door the plates open")
		assert_true(s.locked)
		assert_true(s.has("note"))
		assert_eq(_rules.block_at(a), BlockIds.AIR, "room inside")
		assert_eq(_rules.block_at(a + (s.dir as Vector3i) * n), BlockIds.AIR, "a way in")


## A dragon nest (the realm's ISLAND kind): a small floating island of its own, clear of the others, a short bridge
## from a bigger one, with a nest on top and the egg's cell in it: air, on a nest block, with air above, inside.
func test_every_nest_has_an_egg_cell_on_its_nest() -> void:
	var nests := _of(SecretRules.ISLAND)
	assert_gt(nests.size(), 2)
	for s: Dictionary in nests:
		assert_true(s.has("egg"), "%s has an egg" % s.id)
		var egg: Vector3i = s.egg
		assert_eq(_rules.block_at(egg), BlockIds.AIR, "the egg's cell is air")
		assert_eq(_rules.block_at(egg + Vector3i.UP), BlockIds.AIR, "air above it")
		assert_eq(_rules.block_at(egg + Vector3i.DOWN), BlockIds.NEST, "it lies on the nest")
		assert_true(BlockIds.is_solid(BlockIds.NEST))
		assert_true(SecretRules._contains(s.inside[0], s.inside[1], egg), "inside the island's box")
		var rim := 0
		for d: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
			if BlockIds.is_solid(_rules.block_at(egg + d)):
				rim += 1
		assert_eq(rim, 4, "the nest's rim round the egg")
		assert_eq(_rules.block_at(s.chest), BlockIds.AIR, "room for the golden chest")
		assert_true(BlockIds.is_solid(_rules.block_at((s.chest as Vector3i) + Vector3i.DOWN)), "the chest stands on the island")
		var gold := 0
		for b: Array in s.boxes:
			if b[2] == BlockIds.DRAGON_GOLD:
				gold += 1
		assert_gt(gold, 0, "dragon gold in its side")


func test_a_nest_floats_on_its_own_a_short_bridge_from_an_island() -> void:
	for s: Dictionary in _of(SecretRules.ISLAND):
		var egg: Vector3i = s.egg
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi
		for z in range(lo.z, hi.z):
			for x in range(lo.x, hi.x):
				assert_false(_shape.is_island(x, z), "%s floats clear of the islands" % s.id)
		var near := 0x7fffffff
		var top_near := 0
		for dz in range(-16, 17):
			for dx in range(-16, 17):
				var c := _shape.column(egg.x + dx, egg.z + dz)
				if c.x > c.y and dx * dx + dz * dz < near:
					near = dx * dx + dz * dz
					top_near = c.x
		assert_lte(sqrt(near), 4 + 1 + DragonSecretRules.NEST_REACH + 1, "%s is near an island" % s.id)
		assert_between(egg.y - 2 - top_near, -4, DragonSecretRules.NEST_RISE + 3, "about level with it")


func test_geodes_hide_inside_thick_islands() -> void:
	var geodes := _of(SecretRules.GEODE)
	assert_gt(geodes.size(), 0)
	for s: Dictionary in geodes:
		var c: Vector3i = s.anchor
		var r: int = s.radius
		assert_eq(_rules.block_at(c), BlockIds.AIR, "hollow")
		assert_eq(_rules.block_at(c + Vector3i(r, 0, 0)) != BlockIds.AIR, true, "a shell")
		assert_gt(_shape.height_at(c.x, c.z), c.y + r + DragonSecretRules.GEODE_COVER - 1, "covered by rock")


func test_the_secret_director_can_find_them_by_id() -> void:
	for s: Dictionary in _all_cache.slice(0, 12):
		assert_eq(_rules.find(s.id).id, s.id)
