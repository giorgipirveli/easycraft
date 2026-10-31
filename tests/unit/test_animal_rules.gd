extends GutTest
## Animals: the species table, deterministic spawning (land animals on grass, fish in deep water),
## the per-player cap, despawning, taming dogs and cats, safe steps and fleeing.

const SEED := 12345

var shape: MeadowsShape


func before_all() -> void:
	shape = MeadowsShape.new(SEED)


func _spawns(cells: int) -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for cx in range(-cells, cells):
		for cz in range(-cells, cells):
			all.append_array(AnimalRules.spawns_for_cell(shape, Vector2i(cx, cz)))
	return all


func test_species_table_is_complete() -> void:
	for sp in [&"dog", &"cat", &"pig", &"cow", &"sheep", &"chicken", &"rabbit", &"fish"]:
		assert_true(AnimalRules.SPECIES.has(sp), str(sp))
		var d: Dictionary = AnimalRules.SPECIES[sp]
		assert_true(d.habitat in [&"land", &"water"], str(sp))
		assert_gt((d.size as Vector3).x, 0.0)
		assert_gt(d.speed, 0.0)
		assert_false((d.colors as Array).is_empty())
		assert_ne(d.sound, &"")
		assert_lte((d.herd as Vector2i).x, (d.herd as Vector2i).y)
	assert_eq(AnimalRules.SPECIES[&"fish"].habitat, &"water")
	assert_true(AnimalRules.SPECIES[&"dog"].tameable)
	assert_true(AnimalRules.SPECIES[&"cat"].tameable)
	assert_false(AnimalRules.SPECIES[&"cow"].tameable)


func test_spawns_are_deterministic_per_cell() -> void:
	var cell := Vector2i(3, -2)
	assert_eq(str(AnimalRules.spawns_for_cell(shape, cell)), str(AnimalRules.spawns_for_cell(MeadowsShape.new(SEED), cell)))


func test_land_animals_stand_on_grass_and_fish_swim_in_deep_water() -> void:
	var spawns := _spawns(12)
	assert_gt(spawns.size(), 30)
	var species := {}
	for s in spawns:
		var p: Vector3 = s.pos
		var x := floori(p.x)
		var z := floori(p.z)
		var h := shape.height_at(x, z)
		species[s.species] = true
		if AnimalRules.SPECIES[s.species].habitat == &"land":
			assert_gt(h, MeadowsShape.SEA_LEVEL + 1, "%s on grass above the sea" % s.species)
			assert_false(shape.is_river(x, z))
			assert_eq(shape.column_block(h - 1, h), BlockIds.GRASS)
			assert_eq(p.y, float(h), "stands on the ground")
		else:
			assert_gte(MeadowsShape.SEA_LEVEL - h, 2, "fish in water at least 2 deep")
			assert_between(p.y, float(h), float(MeadowsShape.SEA_LEVEL))
	assert_gte(species.size(), 6, "a mix of animals: %s" % [species.keys()])
	assert_true(species.has(&"fish"), "fish in the rivers and seas")


func test_spawn_ids_are_unique_and_stable() -> void:
	var ids := {}
	for s in _spawns(6):
		assert_false(ids.has(s.id), "duplicate id %s" % s.id)
		ids[s.id] = true


func test_spawn_budget_caps_animals_per_player() -> void:
	assert_eq(AnimalRules.spawn_budget(0), AnimalRules.MAX_PER_PLAYER)
	assert_eq(AnimalRules.spawn_budget(AnimalRules.MAX_PER_PLAYER - 3), 3)
	assert_eq(AnimalRules.spawn_budget(AnimalRules.MAX_PER_PLAYER + 5), 0)


func test_wild_animals_far_from_everyone_despawn_but_pets_never() -> void:
	var players: Array[Vector3] = [Vector3.ZERO, Vector3(500, 0, 0)]
	assert_true(AnimalRules.should_despawn(Vector3(0, 0, 200), players, false))
	assert_false(AnimalRules.should_despawn(Vector3(0, 0, 20), players, false))
	assert_false(AnimalRules.should_despawn(Vector3(510, 0, 0), players, false), "near the second player")
	assert_false(AnimalRules.should_despawn(Vector3(0, 0, 900), players, true), "pets stay")


func test_three_pets_within_four_seconds_tames_a_dog() -> void:
	var taps: Array[float] = []
	var r := AnimalRules.tame_tap(taps, 1.0)
	r = AnimalRules.tame_tap(r.taps, 2.0)
	assert_false(r.tamed)
	r = AnimalRules.tame_tap(r.taps, 3.5)
	assert_true(r.tamed)


func test_slow_petting_does_not_tame() -> void:
	var taps: Array[float] = []
	var r := AnimalRules.tame_tap(taps, 1.0)
	r = AnimalRules.tame_tap(r.taps, 4.0)
	r = AnimalRules.tame_tap(r.taps, 8.0)
	assert_false(r.tamed)


func test_only_dogs_and_cats_up_to_three_pets() -> void:
	assert_true(AnimalRules.can_tame(&"dog", 0))
	assert_true(AnimalRules.can_tame(&"cat", 2))
	assert_false(AnimalRules.can_tame(&"dog", AnimalRules.MAX_PETS))
	assert_false(AnimalRules.can_tame(&"pig", 0))
	assert_false(AnimalRules.can_tame(&"fish", 0))


func test_land_animals_never_step_into_water_or_off_a_cliff() -> void:
	var world := {}
	var block_at := func(p: Vector3i) -> int: return world.get(p, BlockIds.STONE if p.y < 0 else BlockIds.AIR)
	assert_true(AnimalRules.can_step(&"sheep", Vector3i(1, 0, 0), block_at), "flat grass")
	world[Vector3i(1, -1, 0)] = BlockIds.WATER
	assert_false(AnimalRules.can_step(&"sheep", Vector3i(1, 0, 0), block_at), "water ahead")
	world[Vector3i(2, 0, 0)] = BlockIds.WATER
	assert_false(AnimalRules.can_step(&"sheep", Vector3i(2, 0, 0), block_at), "water at the feet")
	for y in range(-4, 0):
		world[Vector3i(3, y, 0)] = BlockIds.AIR
	assert_false(AnimalRules.can_step(&"sheep", Vector3i(3, 0, 0), block_at), "a deep drop")
	world[Vector3i(4, -1, 0)] = BlockIds.AIR   # a 1-block dip is fine
	assert_true(AnimalRules.can_step(&"sheep", Vector3i(4, 0, 0), block_at))


func test_fish_never_leave_the_water() -> void:
	var block_at := func(p: Vector3i) -> int: return BlockIds.WATER if p.x < 2 else BlockIds.AIR
	assert_true(AnimalRules.can_step(&"fish", Vector3i(1, 0, 0), block_at))
	assert_false(AnimalRules.can_step(&"fish", Vector3i(2, 0, 0), block_at))


func test_animals_flee_from_a_player_rushing_at_them() -> void:
	var away := AnimalRules.flee_direction(Vector3(3, 0, 0), Vector3.ZERO, Vector3(6, 0, 0))
	assert_gt(away.x, 0.5, "runs away from the player")
	assert_eq(AnimalRules.flee_direction(Vector3(3, 0, 0), Vector3.ZERO, Vector3(1, 0, 0)), Vector3.ZERO, "a slow walk is fine")
	assert_eq(AnimalRules.flee_direction(Vector3(30, 0, 0), Vector3.ZERO, Vector3(6, 0, 0)), Vector3.ZERO, "too far to care")


## Review I3: /summon had no cap, so a held-down chat line could fill the world with animals (and
## bring back the 3 FPS the owner reported for buddies).
func test_summon_stops_at_the_animal_cap() -> void:
	var near := Vector3(10, 30, 10)
	var herd: Array[Vector3] = []
	for i in AnimalRules.SUMMON_CAP - 1:
		herd.append(near + Vector3(i % 5, 0, i / 5))
	assert_eq(AnimalRules.summon_refusal(&"dog", near, herd, near), "", "room for one more")
	herd.append(near)
	assert_eq(AnimalRules.summon_refusal(&"dog", near, herd, near), AnimalRules.CROWDED_MESSAGE)
	var far: Array[Vector3] = []
	for i in AnimalRules.SUMMON_CAP:
		far.append(near + Vector3(AnimalRules.SPAWN_RADIUS * 2.0, 0, 0))
	assert_eq(AnimalRules.summon_refusal(&"dog", near, far, near), "", "animals far away don't count")


## Review M3: a fish summoned on dry land flopped on the grass.
func test_fish_are_only_summoned_into_water() -> void:
	var pond := {Vector3i(12, 29, 10): BlockIds.WATER}
	var block_at := func(p: Vector3i) -> int: return pond.get(p, BlockIds.AIR if p.y >= 30 else BlockIds.GRASS)
	var near := Vector3(10.3, 30, 10.6)
	var spot := AnimalRules.water_spot(near, block_at)
	assert_eq(spot, Vector3(12.5, 29.5, 10.5), "the pond next to the player")
	var none: Array[Vector3] = []
	assert_eq(AnimalRules.summon_refusal(&"fish", near, none, spot), "")
	var dry := func(p: Vector3i) -> int: return BlockIds.AIR if p.y >= 30 else BlockIds.GRASS
	var nowhere := AnimalRules.water_spot(near, dry)
	assert_false(nowhere.is_finite())
	assert_eq(AnimalRules.summon_refusal(&"fish", near, none, nowhere), AnimalRules.NO_WATER_MESSAGE)


## Spec §3b (review M11): animals look at nearby players; pets wear their owner's colour.
func test_animals_look_at_the_nearest_player_close_by() -> void:
	var near: Array[Vector3] = [Vector3(10, 0, 0), Vector3(3, 0, 0)]
	assert_almost_eq(AnimalRules.look_yaw(Vector3.ZERO, near), -PI / 2.0, 0.001, "turns to face +X (models face -Z)")
	var far: Array[Vector3] = [Vector3(AnimalRules.LOOK_DISTANCE + 1.0, 0, 0)]
	assert_true(is_nan(AnimalRules.look_yaw(Vector3.ZERO, far)), "nobody close: keeps its heading")
	var none: Array[Vector3] = []
	assert_true(is_nan(AnimalRules.look_yaw(Vector3.ZERO, none)))


func test_each_owner_has_a_collar_colour() -> void:
	assert_eq(AnimalRules.collar_color(7), AnimalRules.collar_color(7), "always the same for a player")
	assert_ne(AnimalRules.collar_color(1), AnimalRules.collar_color(2), "the host and the first guest differ")
	assert_ne(AnimalRules.collar_color(2), AnimalRules.collar_color(3))


## Emulator frame spikes (M1b acceptance run 1): ~20 animals simulated every physics step cost up
## to 77 ms a frame. Only animals near a player are simulated; far ones rest (pets always follow).
func test_only_animals_near_a_player_are_simulated() -> void:
	var players: Array[Vector3] = [Vector3(0, 30, 0)]
	assert_true(AnimalRules.is_active(Vector3(10, 30, 5), players, false), "close by")
	assert_false(AnimalRules.is_active(Vector3(AnimalRules.ACTIVE_DISTANCE + 2.0, 30, 0), players, false), "far: resting")
	assert_true(AnimalRules.is_active(Vector3(500, 30, 0), players, true), "pets always follow their owner")
	var nobody: Array[Vector3] = []
	assert_false(AnimalRules.is_active(Vector3.ZERO, nobody, false), "nobody here")
	assert_gt(AnimalRules.ACTIVE_DISTANCE, AnimalRules.LOOK_DISTANCE + AnimalRules.FLEE_DISTANCE, "everything a player sees up close still happens")


## Found by the acceptance tour: /summon put the animal half a block above the player's feet up to
## 1.5 blocks away, without looking at the ground; beside a 1-block rise it started inside the
## block and fell out of the world. It now stands on the ground of a column next to the player.
func test_a_summoned_animal_stands_on_the_ground_next_to_the_player() -> void:
	var blocks := {}
	for x in range(-3, 4):
		for z in range(-3, 4):
			blocks[Vector3i(x, 9, z)] = BlockIds.STONE           # floor: feet at y = 10
			if x >= 1:
				blocks[Vector3i(x, 10, z)] = BlockIds.STONE      # a 1-block rise to the east
	var at := func(p: Vector3i) -> int: return blocks.get(p, BlockIds.STONE if p.y < 9 else BlockIds.AIR)
	var near := Vector3(0.5, 10.0, 0.5)
	for start in 8:
		var spot := AnimalRules.summon_spot(near, at, start)
		var cell := Vector3i(spot.floor())
		assert_false(BlockIds.is_solid(at.call(cell)), "never inside a block (start %d): %s" % [start, spot])
		assert_false(BlockIds.is_solid(at.call(cell + Vector3i.UP)), "room above it")
		assert_true(BlockIds.is_solid(at.call(cell + Vector3i.DOWN)), "on the ground")
		assert_lte(Vector2(spot.x - near.x, spot.z - near.z).length(), 1.5, "next to the player")
	var boxed := func(p: Vector3i) -> int: return BlockIds.AIR if p == Vector3i(0, 10, 0) or p == Vector3i(0, 11, 0) else BlockIds.STONE
	assert_eq(AnimalRules.summon_spot(near, boxed, 0), Vector3(0.5, 10.0, 0.5), "no room around: at the player's feet")


## Like monsters: a moment with no spawned player (a knock-out's getting up) sends no animal away.
func test_no_players_for_a_moment_sends_no_animal_away() -> void:
	assert_false(AnimalRules.should_despawn(Vector3(0, 0, 200), [] as Array[Vector3], false))


# --- Owner feedback #26: animals can be defeated ---

func test_drops_are_a_little_building_and_never_gold_or_anything_tilly_buys() -> void:
	for sp: StringName in AnimalRules.SPECIES:
		for i in 20:
			var items := AnimalRules.drops(sp, "a%d_0_%d" % [i, i])
			var total := 0
			for e: Array in items:
				var id := int(e[0])
				total += int(e[1])
				assert_true(BlockIds.is_valid(id), "%s drops a real block" % sp)
				assert_false(ShopRules.SELL_PRICES.has(id), "%s never drops what Tilly buys (no gold farm)" % sp)
				assert_ne(id, BlockIds.GOLD, str(sp))
			assert_lte(total, 3, "%s leaves only a little" % sp)
	for sp: StringName in [&"dog", &"cat"]:
		assert_eq(AnimalRules.drops(sp, "a1_1_1"), [], "%s: nothing (the pets-to-be are not hunted for loot)" % sp)
	for sp: StringName in [&"chicken", &"rabbit", &"fish", &"pig", &"sheep", &"cow"]:
		assert_false(AnimalRules.drops(sp, "a1_1_1").is_empty(), "%s leaves something" % sp)


func test_a_sheep_always_gives_its_own_colour() -> void:
	assert_eq(AnimalRules.drops(&"sheep", "a3_4_1"), AnimalRules.drops(&"sheep", "a3_4_1"), "stable per sheep")
	var colours := {}
	for i in 40:
		colours[int(AnimalRules.drops(&"sheep", "a%d_2_0" % i)[0][0])] = true
	assert_gt(colours.size(), 2, "sheep come in several colours")


func test_the_drop_message_is_plain_and_kind() -> void:
	assert_eq(AnimalRules.drop_text([[BlockIds.BLUE, 2]]), "You got 2 Blue!")
	assert_eq(AnimalRules.drop_text([[BlockIds.YELLOW, 1], [BlockIds.DIRT, 2]]), "You got 1 Yellow and 2 Dirt!")
	assert_eq(AnimalRules.drop_text([]), "")


func test_pets_and_golden_animals_are_never_hurt() -> void:
	assert_true(AnimalRules.can_be_hurt(false, false), "a wild animal")
	assert_false(AnimalRules.can_be_hurt(true, false), "a pet: by nobody")
	assert_false(AnimalRules.can_be_hurt(false, true), "a golden animal: it is caught")


func test_herds_refill_slowly() -> void:
	assert_between(AnimalRules.REFILL_TIME, 60.0, 600.0, "minutes, not seconds, and never never")
