extends GutTest
## Owner feedback #42 (spec §12.16b): the treasure pack's places. TreasurePlaces builds them after the M2
## kinds inside SecretRules' areas: decided from the seed and the area alone, inside their area, apart from
## the other secrets, never in the spawn's landmark zone nor across a river, entrances open; each kind's
## structure; each universe's own kinds and blocks; the M2 secrets stay exactly where they were.

const SEED := 12345
const R := 8                      # areas -R..R-1 on both axes

var rules: SecretRules
var shape: MeadowsShape
var _all_cache: Array = []


func before_all() -> void:
	rules = SecretRules.new(SEED)
	shape = rules.shape
	for az in range(-R, R):
		for ax in range(-R, R):
			_all_cache.append_array(rules.secrets_in_area(Vector2i(ax, az)))


func _new_ones() -> Array:
	return _all_cache.filter(func(s: Dictionary) -> bool: return TreasurePlaces.is_kind(s.kind))


func _first(kind: StringName, list: Array = _all_cache) -> Dictionary:
	for s: Dictionary in list:
		if s.kind == kind:
			return s
	fail_test("no %s near the origin of seed %d" % [kind, SEED])
	return {}


func _count(kind: StringName, list: Array) -> int:
	return list.filter(func(s: Dictionary) -> bool: return s.kind == kind).size()


func _boxes_with(s: Dictionary, id: int) -> int:
	var n := 0
	for b: Array in s.boxes:
		if int(b[2]) == id:
			var size: Vector3i = (b[1] as Vector3i) - (b[0] as Vector3i)
			n += size.x * size.y * size.z
	return n


## Where feet stand on generated ground (natural ground where the secrets put nothing).
func _solid(p: Vector3i) -> bool:
	var id := rules.block_at(p)
	if id < 0:
		return p.y < shape.height_at(p.x, p.z)
	return BlockIds.is_solid(id)


# --- The pack in general ---

func test_the_same_world_always_has_the_same_treasure_places() -> void:
	var again := SecretRules.new(SEED)
	for az in range(-3, 3):
		for ax in range(-3, 3):
			var a: Array = rules.secrets_in_area(Vector2i(ax, az))
			var b: Array = again.secrets_in_area(Vector2i(ax, az))
			assert_eq(a.size(), b.size())
			for i in mini(a.size(), b.size()):
				assert_eq(a[i].id, b[i].id)
				assert_eq(a[i].boxes, b[i].boxes)


func test_the_m2_secrets_stay_exactly_where_they_were() -> void:
	var before := SecretRules.new(SEED, null, false)   # the world without the treasure pack
	for az in range(-4, 4):
		for ax in range(-4, 4):
			var old: Array = before.secrets_in_area(Vector2i(ax, az))
			var now: Array = rules.secrets_in_area(Vector2i(ax, az)).filter(
				func(s: Dictionary) -> bool: return not TreasurePlaces.is_kind(s.kind))
			assert_eq(now.size(), old.size(), "area %d %d" % [ax, az])
			for i in mini(now.size(), old.size()):
				assert_eq(now[i].id, old[i].id, "saved ids keep their meaning")
				assert_eq(now[i].boxes, old[i].boxes)


func test_every_kind_of_the_pack_is_somewhere_in_green_meadows() -> void:
	var kinds := {}
	for s: Dictionary in _new_ones():
		kinds[s.kind] = int(kinds.get(s.kind, 0)) + 1
	gut.p("treasure places in %d areas: %s" % [4 * R * R, kinds])
	for kind in TreasurePlaces.PLACED:
		assert_gt(int(kinds.get(kind, 0)), 0, String(kind))


func test_a_few_secrets_per_area_in_all() -> void:
	var average := _all_cache.size() / float(4 * R * R)
	assert_between(average, 2.5, 5.5, "secrets per 128 x 128 area: %.2f" % average)
	var added := _new_ones().size() / float(4 * R * R)
	assert_between(added, 0.8, 3.0, "the pack's places per area: %.2f" % added)


func test_ids_are_valid_node_names_that_find_their_secret() -> void:
	for s: Dictionary in _new_ones().slice(0, 40):
		assert_eq(rules.find(s.id).get("anchor"), s.anchor, s.id)
		assert_eq(s.id.validate_node_name(), s.id)
		assert_eq((s.id as String).split("_").size(), 4, "kind names have no underscore: %s" % s.id)


func test_they_stay_inside_their_area_and_apart_from_every_other_secret() -> void:
	for az in range(-R, R):
		for ax in range(-R, R):
			var list: Array = rules.secrets_in_area(Vector2i(ax, az))
			for i in list.size():
				var a: Dictionary = list[i]
				var lo: Vector3i = a.lo
				var hi: Vector3i = a.hi
				assert_true(lo.x >= ax * SecretRules.AREA and hi.x <= (ax + 1) * SecretRules.AREA, a.id)
				assert_true(lo.z >= az * SecretRules.AREA and hi.z <= (az + 1) * SecretRules.AREA, a.id)
				for j in range(i + 1, list.size()):
					var b: Dictionary = list[j]
					var apart: bool = a.hi.x + SecretRules.GAP <= b.lo.x or b.hi.x + SecretRules.GAP <= a.lo.x \
						or a.hi.z + SecretRules.GAP <= b.lo.z or b.hi.z + SecretRules.GAP <= a.lo.z
					assert_true(apart, "%s and %s share ground" % [a.id, b.id])


## The spawn's landmarks (Tilly, the Totem, the hub circle, the Theater) and the ways between them.
func test_never_in_the_spawn_landmark_zone() -> void:
	var spawn := shape.spawn_column()
	for s: Dictionary in _new_ones():
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi
		var dx := maxi(maxi(lo.x - spawn.x, spawn.x - (hi.x - 1)), 0)
		var dz := maxi(maxi(lo.z - spawn.y, spawn.y - (hi.z - 1)), 0)
		assert_gte(Vector2(dx, dz).length(), TreasurePlaces.CLEAR_OF_SPAWN, s.id)
	assert_gte(TreasurePlaces.CLEAR_OF_SPAWN, 56.0, "past the Theater's farthest spot (48) and its size")


## Never across a river: no land kind stands on a river channel.
func test_land_places_never_cross_a_river_or_the_sea() -> void:
	var checked := 0
	for s: Dictionary in _new_ones():
		if [TreasurePlaces.SHIPWRECK, TreasurePlaces.SUNKEN, TreasurePlaces.COVE].has(s.kind):
			continue
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi
		for z in range(lo.z, hi.z, 2):
			for x in range(lo.x, hi.x, 2):
				assert_false(shape.is_river(x, z), "%s crosses a river at %d %d" % [s.id, x, z])
		var a: Vector3i = s.anchor
		assert_gt(shape.height_at(a.x, a.z), MeadowsShape.SEA_LEVEL + 1, s.id)
		checked += 1
	assert_gt(checked, 10)


## Every place can be walked into: its door is open and has ground under it.
func test_every_entrance_is_open_and_walkable() -> void:
	var checked := 0
	for s: Dictionary in _new_ones():
		if not s.has("door"):
			continue
		var door: Vector3i = s.door
		assert_false(_solid(door), "%s: its door %s is open" % [s.id, door])
		assert_false(_solid(door + Vector3i.UP), "%s: two blocks high" % s.id)
		if s.kind != TreasurePlaces.SUNKEN:
			assert_true(_solid(door + Vector3i.DOWN), "%s: ground under the door" % s.id)
		checked += 1
	assert_gt(checked, 20)


# --- Each kind ---

func test_a_shipwreck_lies_on_a_beach_by_the_sea() -> void:
	var s := _first(TreasurePlaces.SHIPWRECK)
	var at: Vector3i = s.anchor
	var beach: Vector2i = s.beach
	assert_between(shape.height_at(beach.x, beach.y), MeadowsShape.SEA_LEVEL, MeadowsShape.SEA_LEVEL + 2, "on the beach")
	var sea: Vector2i = beach + Vector2i((s.dir as Vector3i).x, (s.dir as Vector3i).z) * int(s.water)
	assert_lte(int(s.water), 16, "the water a few blocks on")
	assert_lte(shape.height_at(sea.x, sea.y), MeadowsShape.SEA_LEVEL - 2, "the sea is right there")
	assert_gt(_boxes_with(s, BlockIds.PLANKS), 20, "a plank hull")
	assert_gt(_boxes_with(s, BlockIds.LOG), 4, "a mast")
	assert_eq(rules.block_at(s.chest), BlockIds.AIR)
	assert_eq(s.chest_kind, &"shipwreck")
	assert_eq(rules.block_at(at), BlockIds.AIR, "a deck to stand on")


func test_a_sunken_chest_lies_on_the_seabed() -> void:
	var s := _first(TreasurePlaces.SUNKEN)
	var c: Vector3i = s.chest
	var h := shape.height_at(c.x, c.z)
	assert_eq(c.y, h, "on the seabed")
	assert_between(MeadowsShape.SEA_LEVEL - h, TreasurePlaces.SUNKEN_DEPTH.x, TreasurePlaces.SUNKEN_DEPTH.y, "4-12 blocks deep")
	assert_eq(rules.block_at(c), BlockIds.WATER, "in the water")
	assert_false(shape.is_river(c.x, c.z), "the sea, not a river")
	assert_gt(_boxes_with(s, BlockIds.PLANKS), 1, "broken planks around it")
	assert_eq(s.chest_kind, &"sunken")


func test_a_mineshaft_has_stairs_rails_lanterns_and_a_loot_cart() -> void:
	var s := _first(TreasurePlaces.MINESHAFT)
	var tunnel: Array = s.inside
	var lo: Vector3i = tunnel[0]
	var hi: Vector3i = tunnel[1]
	var fy := lo.y - 1
	assert_lt(fy, shape.height_at(s.door.x, s.door.z) - TreasurePlaces.MINE_STAIRS + 1, "the tunnel is under the ground")
	assert_gt(_boxes_with(s, BlockIds.PLANKS), 10, "plank rails and beams")
	assert_gt(_boxes_with(s, BlockIds.LOG), 6, "sleepers, posts and the frame")
	assert_gt(_boxes_with(s, BlockIds.LANTERN), 1, "lanterns")
	assert_eq(s.chest_kind, &"cart", "the loot cart")
	assert_true(SecretRules._contains(lo, hi, s.chest), "the cart waits in the tunnel")
	for x in range(lo.x, hi.x, 3):
		for z in range(lo.z, hi.z, 3):
			assert_gte(shape.height_at(x, z), hi.y + 1, "a roof of ground over the tunnel at %d %d" % [x, z])


func test_a_dungeon_vault_waits_deep_behind_three_levers() -> void:
	var s := _first(TreasurePlaces.VAULT)
	var levers: Array = s.levers
	assert_eq(levers.size(), 3)
	for cell: Vector3i in levers:
		assert_eq(rules.block_at(cell), BlockIds.LEVER, "an off lever")
	var symbols: Array = (s.symbols as Array).duplicate()
	symbols.sort()
	var expected: Array = TreasureRules.VAULT_SYMBOLS.duplicate()
	expected.sort()
	assert_eq(symbols, expected, "a key, a crown and a gem")
	var order: Array = (s.order as Array).duplicate()
	order.sort()
	assert_eq(order, [0, 1, 2])
	for cell: Vector3i in s.vault:
		assert_eq(rules.block_at(cell), BlockIds.YELLOW, "the golden door")
	assert_true(bool(s.locked))
	assert_eq(s.chest_kind, &"vault")
	var top: Vector3i = s.door
	assert_gte(top.y - (s.chest as Vector3i).y, TreasurePlaces.VAULT_DEPTH - 2, "deep underground")
	assert_eq((s.note.pictures as Array).size(), 3, "the note draws the order")
	assert_gt(_boxes_with(s, BlockIds.LANTERN), 0, "a lantern shows the way down")


## The spiral stairs: every step is one lower than the one before and next to it, down to the hall.
func test_the_vault_stairs_go_down_step_by_step() -> void:
	var s := _first(TreasurePlaces.VAULT)
	var steps: Array = s.steps
	assert_gte(steps.size(), TreasurePlaces.VAULT_DEPTH - 3)
	for i in range(1, steps.size()):
		var a: Vector3i = steps[i - 1]
		var b: Vector3i = steps[i]
		assert_eq(b.y, a.y - 1, "one block down")
		assert_eq(absi(b.x - a.x) + absi(b.z - a.z), 1, "right next to the last one")
		assert_true(_solid(b), "a step at %s" % b)
		for up in range(1, 3):
			assert_false(_solid(b + Vector3i(0, up, 0)), "headroom over %s" % b)


func test_a_waterfall_pours_over_a_crystal_cave() -> void:
	var s := _first(TreasurePlaces.WATERFALL)
	assert_gt(_boxes_with(s, BlockIds.WATER), 6, "a curtain of water")
	assert_gt(_boxes_with(s, BlockIds.CRYSTAL), 2, "crystals light the cave")
	var cave: Array = s.inside
	assert_true(SecretRules._contains(cave[0], cave[1], s.chest))
	var curtain: Array = s.curtain
	assert_gt(curtain.size(), 3)
	for cell: Vector3i in curtain:
		assert_eq(rules.block_at(cell), BlockIds.WATER)
	assert_eq(s.chest_kind, &"waterfall")


func test_a_hollow_tree_has_a_chest_in_its_trunk() -> void:
	var s := _first(TreasurePlaces.HOLLOW)
	assert_gt(_boxes_with(s, BlockIds.LOG), 60, "a giant trunk")
	assert_gt(_boxes_with(s, BlockIds.LEAVES), 60, "a big crown of leaves")
	var hollow: Array = s.inside
	assert_true(SecretRules._contains(hollow[0], hollow[1], s.chest))
	assert_eq(rules.block_at(s.chest), BlockIds.AIR)
	assert_eq(s.chest_kind, &"hollowtree")


func test_a_wishing_well_stands_in_a_cobbled_clearing() -> void:
	var s := _first(TreasurePlaces.WELL)
	var well: Vector3i = s.well
	assert_eq(rules.block_at(well), BlockIds.AIR, "an open well")
	assert_eq(rules.block_at(well + Vector3i.DOWN), BlockIds.WATER, "water in it")
	for d: Vector3i in SecretRules.DIRS:
		assert_eq(rules.block_at(well + d), BlockIds.BRICK, "its rim")
	assert_gt(_boxes_with(s, BlockIds.LANTERN), 1, "lamp posts")
	assert_false(s.has("chest"), "a well gives a gift, not a chest")


func test_a_pirate_cove_opens_to_the_sea() -> void:
	var s := _first(TreasurePlaces.COVE)
	var mouth: Vector3i = s.door
	var d: Vector3i = s.dir
	var out := mouth + d * 2
	assert_lte(shape.height_at(out.x, out.z), MeadowsShape.SEA_LEVEL + 1, "the mouth faces the water")
	assert_gt(_boxes_with(s, BlockIds.BARREL), 1, "barrels")
	assert_gt(_boxes_with(s, BlockIds.RED), 1, "a flag")
	assert_eq(s.chest_kind, &"cove")


func test_ruins_have_pillars_a_riddle_note_and_a_chest() -> void:
	var s := _first(TreasurePlaces.RUINS)
	assert_gt(_boxes_with(s, BlockIds.BRICK), 30, "old stones")
	assert_true(s.has("note"), "an old note")
	assert_lte((s.note.text as String).length(), 40)
	assert_eq(s.chest_kind, &"ruins")


func test_a_haunted_house_has_ghosts_and_a_locked_chest() -> void:
	var s := _first(TreasurePlaces.HAUNTED)
	assert_eq((s.ghosts as Array).size(), 2, "two friendly ghosts")
	var inside: Array = s.inside
	for g: Vector3 in s.ghosts:
		assert_true(SecretRules._contains(inside[0], inside[1], Vector3i(g.floor())), "ghosts float inside")
	assert_true(bool(s.locked), "the ghosts' riddle opens it")
	assert_between(int(s.riddle), 0, TreasureRules.GHOST_RIDDLES.size() - 1)
	assert_gt(_boxes_with(s, BlockIds.GLASS), 0, "windows")
	assert_eq(s.chest_kind, &"haunted")


func test_a_campsite_has_a_tent_a_fire_and_a_supply_chest() -> void:
	var s := _first(TreasurePlaces.CAMP)
	assert_gt(_boxes_with(s, BlockIds.RED) + _boxes_with(s, BlockIds.YELLOW), 6, "a striped tent")
	assert_gt(_boxes_with(s, BlockIds.LANTERN), 0, "a fire's glow")
	assert_eq(s.chest_kind, &"camp")


# --- Universes ---

func test_the_desert_builds_its_own_kinds_in_sandstone() -> void:
	var desert := DesertSecretRules.new(SEED)
	var kinds := {}
	var list: Array = []
	for az in range(-5, 5):
		for ax in range(-5, 5):
			for s: Dictionary in desert.secrets_in_area(Vector2i(ax, az)):
				if TreasurePlaces.is_kind(s.kind):
					kinds[s.kind] = true
					list.append(s)
	gut.p("desert kinds: " + str(kinds.keys()))
	for kind: StringName in kinds:
		assert_true(TreasurePlaces.KINDS_BY_STYLE[TreasurePlaces.DESERT].has(kind), String(kind))
	assert_gte(kinds.size(), 4)
	var s := _first(TreasurePlaces.RUINS, list)
	assert_gt(_boxes_with(s, BlockIds.CUT_SANDSTONE) + _boxes_with(s, BlockIds.CHISELED_SANDSTONE), 20, "sandstone ruins")
	assert_eq(_boxes_with(s, BlockIds.BRICK), 0)


func test_frostpeak_builds_its_own_kinds_in_snow_and_pine() -> void:
	var frost := FrostSecretRules.new(SEED)
	var kinds := {}
	var list: Array = []
	for az in range(-5, 5):
		for ax in range(-5, 5):
			for s: Dictionary in frost.secrets_in_area(Vector2i(ax, az)):
				if TreasurePlaces.is_kind(s.kind):
					kinds[s.kind] = true
					list.append(s)
	gut.p("frost kinds: " + str(kinds.keys()))
	for kind: StringName in kinds:
		assert_true(TreasurePlaces.KINDS_BY_STYLE[TreasurePlaces.FROST].has(kind), String(kind))
	assert_gte(kinds.size(), 4)
	var s := _first(TreasurePlaces.CAMP, list)
	assert_gt(_boxes_with(s, BlockIds.PINE_LOG), 0, "pine logs")
	assert_gt(_boxes_with(s, BlockIds.ICE_LANTERN), 0, "an ice lantern")


# --- Chunks meet without seams ---

func test_green_meadows_writes_each_kind_without_seams() -> void:
	var gen := MeadowsGenerator.new()
	gen.world_seed = SEED
	_check_kinds(gen, rules, TreasurePlaces.PLACED)


func test_the_desert_writes_its_kinds_without_seams() -> void:
	var gen := DesertGenerator.new()
	gen.world_seed = SEED
	_check_kinds(gen, DesertSecretRules.new(SEED), [TreasurePlaces.MINESHAFT, TreasurePlaces.WELL, TreasurePlaces.CAMP])


func test_frostpeak_writes_its_kinds_without_seams() -> void:
	var gen := FrostGenerator.new()
	gen.world_seed = SEED
	_check_kinds(gen, FrostSecretRules.new(SEED), [TreasurePlaces.VAULT, TreasurePlaces.HAUNTED, TreasurePlaces.HOLLOW])


func _check_kinds(gen: VoxelGenerator, r: SecretRules, kinds: Array) -> void:
	var done := {}
	var crossed := 0
	for az in range(-5, 5):
		for ax in range(-5, 5):
			for s: Dictionary in r.secrets_in_area(Vector2i(ax, az)):
				if kinds.has(s.kind) and not done.has(s.kind):
					done[s.kind] = true
					crossed += _check_secret(gen, r, s)
	assert_eq(done.size(), kinds.size(), "one of each kind checked: " + str(done.keys()))
	assert_gt(crossed, 0, "some cross chunk borders")


## Generates every chunk the secret touches and compares its cells with SecretRules.block_at.
func _check_secret(gen: VoxelGenerator, r: SecretRules, s: Dictionary) -> int:
	var lo: Vector3i = s.lo
	var hi: Vector3i = s.hi
	var c0 := Vector3i(floori(lo.x / 16.0), floori(lo.y / 16.0), floori(lo.z / 16.0))
	var c1 := Vector3i(floori((hi.x - 1) / 16.0), floori((hi.y - 1) / 16.0), floori((hi.z - 1) / 16.0))
	var bad := 0
	for cz in range(c0.z, c1.z + 1):
		for cy in range(c0.y, c1.y + 1):
			for cx in range(c0.x, c1.x + 1):
				var origin := Vector3i(cx, cy, cz) * 16
				var buf := VoxelBuffer.new()
				buf.create(16, 16, 16)
				gen.generate_block(buf, origin, 0)
				var a := lo.max(origin)
				var b := hi.min(origin + Vector3i(16, 16, 16))
				for z in range(a.z, b.z):
					for y in range(a.y, b.y):
						for x in range(a.x, b.x):
							var want := r.block_at(Vector3i(x, y, z))
							if want >= 0 and buf.get_voxel(x - origin.x, y - origin.y, z - origin.z, VoxelBuffer.CHANNEL_TYPE) != want:
								bad += 1
	assert_eq(bad, 0, "%s: every block where the rules put it" % s.id)
	return 1 if c0 != c1 else 0


## The Candy Kingdom (M3 Task 4, merged after the pack) builds its own treasure places from candy, like the
## desert and Frostpeak: never Meadows' planks, stone, grass or dirt in the kingdom.
func test_the_candy_kingdom_builds_its_treasure_places_from_candy() -> void:
	var places := TreasurePlaces.new(CandyShape.new(7), Vector2i.ZERO)
	assert_eq(places.style, TreasurePlaces.CANDY)
	var meadows_only := [BlockIds.PLANKS, BlockIds.STONE, BlockIds.GRASS, BlockIds.DIRT, BlockIds.LOG, BlockIds.LEAVES,
		BlockIds.BRICK, BlockIds.LANTERN]
	for role: String in TreasurePlaces.PALETTE[TreasurePlaces.MEADOWS]:
		assert_true(places.palette.has(role), "the candy palette has a block for " + role)
		assert_false(meadows_only.has(places.palette.get(role)), "no Meadows block for " + role)
	for pair: Array in places.attempts():
		assert_true(TreasurePlaces.KINDS_BY_STYLE[TreasurePlaces.CANDY].has(pair[0]), str(pair[0]))
