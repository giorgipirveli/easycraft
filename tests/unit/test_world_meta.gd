extends GutTest


func test_round_trip() -> void:
	var m := WorldMeta.new_random()
	m.seed = 777
	m.player_pos = Vector3(1.5, 40.0, -3.25)
	m.player_yaw = 1.25
	m.physics_mode = PhysicsMode.Mode.GHOST
	m.hotbar[2] = BlockIds.PURPLE
	m.selected_slot = 4
	var q := WorldMeta.from_json(m.to_json())
	assert_eq(q.seed, 777)
	assert_eq(q.player_pos, Vector3(1.5, 40.0, -3.25))
	assert_almost_eq(q.player_yaw, 1.25, 0.0001)
	assert_eq(q.physics_mode, PhysicsMode.Mode.GHOST)
	assert_eq(q.hotbar[2], BlockIds.PURPLE)
	assert_eq(q.selected_slot, 4)
	assert_true(q.has_player_pos())


func test_new_world_has_no_player_position() -> void:
	assert_false(WorldMeta.new_random().has_player_pos())


func test_truncated_json_gives_defaults() -> void:
	var q := WorldMeta.from_json('{"version":1,"seed":5,"hotb')
	assert_false(q.has_player_pos())
	assert_eq(q.hotbar.size(), 9)
	assert_eq(q.physics_mode, PhysicsMode.Mode.NORMAL)


func test_default_hotbar_has_blocks_wand_and_house_stamp() -> void:
	var q := WorldMeta.new_random()
	assert_eq(q.hotbar, [BlockIds.GRASS, BlockIds.STONE, BlockIds.PLANKS, BlockIds.BRICK, BlockIds.GLASS,
		BlockIds.RED, BlockIds.BLUE, ItemIds.WAND, ItemIds.STAMP_HOUSE])


func test_invalid_hotbar_entries_are_replaced() -> void:
	var q := WorldMeta.from_json('{"version":1,"seed":5,"hotbar":[999,-4,"x"],"selected_slot":50}')
	assert_eq(q.hotbar.size(), 9)
	for id in q.hotbar:
		assert_true(ItemIds.is_hotbar_valid(id))
	assert_between(q.selected_slot, 0, 8)


func test_items_survive_round_trip() -> void:
	var m := WorldMeta.new_random()
	m.hotbar[0] = ItemIds.STAMP_RAINBOW
	assert_eq(WorldMeta.from_json(m.to_json()).hotbar[0], ItemIds.STAMP_RAINBOW)


func test_buddies_round_trip() -> void:
	var m := WorldMeta.new_random()
	m.buddies = [{"blocks": [[0, 0, 0, BlockIds.RED], [0, 1, 0, BlockIds.LIGHT]], "pos": [3.5, 40.0, -2.0], "yaw": 1.5, "name": "Bobble"}]
	var q := WorldMeta.from_json(m.to_json())
	assert_eq(q.buddies.size(), 1)
	assert_eq(q.buddies[0].name, "Bobble")
	assert_eq((q.buddies[0].blocks as Array).size(), 2)


func test_broken_buddies_are_dropped() -> void:
	var q := WorldMeta.from_json('{"version":1,"seed":1,"buddies":[{"blocks":[[0,0,0,999]],"pos":[0,0,0]},{"blocks":"x"},{"blocks":[[0,0,0,12]],"pos":[1,2,3],"name":"Ok"}]}')
	assert_eq(q.buddies.size(), 1)
	assert_eq(q.buddies[0].name, "Ok")


func test_pets_round_trip_and_bad_entries_are_dropped() -> void:
	var m := WorldMeta.new_random()
	m.pets = [{"species": "dog", "name": "Biscuit", "pos": [1.0, 40.0, 2.0], "id": "pet_1"}]
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.pets.size(), 1)
	assert_eq(back.pets[0].species, "dog")
	assert_eq(back.pets[0].name, "Biscuit")
	var bad := WorldMeta.from_json('{"pets":[{"species":"griffin","name":"X","pos":[0,0,0],"id":"a"},{"species":"cat","pos":[1,2],"id":"b"},{"species":"cat","name":"Tom","pos":[1,2,3],"id":"c"}]}')
	assert_eq(bad.pets.size(), 1, "unknown species and broken positions are dropped")


# --- Time of day and homes (M1b Task 10) ---

func test_time_of_day_and_homes_round_trip() -> void:
	var m := WorldMeta.new_random()
	m.time_of_day = 0.82
	m.homes = {"BraveFox42": Vector3i(12, 40, -3)}
	var back := WorldMeta.from_json(m.to_json())
	assert_almost_eq(back.time_of_day, 0.82, 0.0001)
	assert_eq(back.homes, {"BraveFox42": Vector3i(12, 40, -3)})


func test_old_saves_start_in_the_morning_without_homes() -> void:
	var old := WorldMeta.from_json('{"version":1,"seed":5}')
	assert_eq(old.time_of_day, DayCycle.START)
	assert_true(old.homes.is_empty())
	assert_eq(WorldMeta.new_random().time_of_day, DayCycle.START, "a new world starts in the morning")


func test_broken_time_and_homes_are_ignored() -> void:
	var q := WorldMeta.from_json('{"time_of_day":"late","homes":{"a":[1,2],"b":"x","c":[1,2,3],"":[4,5,6],"d":[1,"y",3]}}')
	assert_eq(q.time_of_day, DayCycle.START)
	assert_eq(q.homes, {"c": Vector3i(1, 2, 3)})
	assert_almost_eq(WorldMeta.from_json('{"time_of_day":1.25}').time_of_day, 0.25, 0.0001, "wrapped into one day")
	assert_true(WorldMeta.from_json('{"homes":[1,2,3]}').homes.is_empty())


## Deferred M1 minor: a save with wrong element types (hand-edited, or written by a buggy version)
## must still load, with the broken parts dropped — never lose the whole world to one bad value.
func test_bad_element_types_never_break_loading() -> void:
	var bad := '{"seed": 5, "player_pos": [{}, "x", null], "player_yaw": "north",' \
		+ ' "buddies": [{"blocks": [[{}, 0, 0, 12]], "pos": [1, 2, 3]}, {"blocks": [[0, 0, 0, 12]], "pos": ["a", 2, 3]}],' \
		+ ' "pets": [{"species": "dog", "name": 5, "pos": [[], 2, 3], "id": "p"}],' \
		+ ' "homes": {"Kid": ["a", 1, 2], "Other": 7}, "time_of_day": "noon",' \
		+ ' "targets": [{"item": "sword", "pos": [1, 2, 3], "yaw": 0}, 5]}'
	var m := WorldMeta.from_json(bad)
	assert_not_null(m, "loading never fails")
	if m == null:
		return
	assert_eq(m.seed, 5, "good fields survive")
	assert_false(m.has_player_pos(), "a broken position is dropped")
	assert_eq(m.buddies.size(), 0)
	assert_eq(m.pets.size(), 0)
	assert_true(m.time_of_day >= 0.0 and m.time_of_day < 1.0)


## M2 §12.1–12.2: a world knows its mode, and each player's inventory is saved with it (by name,
## like homes). Old worlds are Sandbox worlds.
func test_mode_and_inventories_round_trip() -> void:
	var m := WorldMeta.new_random()
	assert_eq(m.mode, ModeRules.SANDBOX, "a new or old world is Sandbox unless told")
	m.mode = ModeRules.SURVIVOR
	var inv := Inventory.starter_kit()
	m.inventories["Hopper"] = inv.to_save()
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.mode, ModeRules.SURVIVOR)
	assert_eq(Inventory.from_save(back.inventories["Hopper"]).count(BlockIds.PLANKS), 16)
	var old := WorldMeta.from_json('{"seed": 5}')
	assert_eq(old.mode, ModeRules.SANDBOX)
	assert_eq(old.inventories, {})
	var odd := WorldMeta.from_json('{"seed": 5, "mode": "moon", "inventories": {"a": "junk", "b": [[2, 3]], "": [[2, 1]]}}')
	assert_eq(odd.mode, ModeRules.SANDBOX, "an unknown mode is Sandbox")
	assert_eq(odd.inventories.keys(), ["b"], "junk and nameless entries are dropped")


## M2 Task 4 (§12.15): the Sandbox world setting "Monsters: ON / OFF", ON by default.
func test_monsters_setting_round_trip_and_defaults() -> void:
	assert_true(WorldMeta.new_random().monsters_on, "a new world has monsters")
	var m := WorldMeta.new_random()
	m.monsters_on = false
	assert_false(WorldMeta.from_json(m.to_json()).monsters_on)
	assert_true(WorldMeta.from_json('{"version":1,"seed":5}').monsters_on, "worlds saved before M2 Task 4")
	for bad in ['"no"', '0', '1', 'null', '[false]']:
		assert_true(WorldMeta.from_json('{"version":1,"seed":5,"monsters_on":%s}' % bad).monsters_on, bad)

## M2 Task 16: the world's secrets (found, opened chests, solved temples, explored areas) are saved with it.
func test_secrets_round_trip() -> void:
	var m := WorldMeta.new_random()
	m.secrets.opened["treasure_0_0_1"] = true
	m.secrets.explore(Vector2i(0, 0), 2)
	var back := WorldMeta.from_json(m.to_json())
	assert_true(back.secrets.opened.has("treasure_0_0_1"))
	assert_eq(back.secrets.explored, {Vector2i(0, 0): 2})
	assert_eq(WorldMeta.from_json('{"seed": 5}').secrets.opened, {}, "an old world has found nothing yet")
	assert_eq(WorldMeta.from_json('{"seed": 5, "secrets": "junk"}').secrets.found, {})

## Physics Lab (M3 Task 6): the lab mode is saved with the world, like physics_mode.
func test_the_lab_mode_is_saved_with_the_world() -> void:
	var m := WorldMeta.new_random()
	m.physics_mode = PhysicsMode.Mode.FLY
	m.lab_mode = LabRules.Mode.ZERO_G
	var q := WorldMeta.from_json(m.to_json())
	assert_eq(q.lab_mode, LabRules.Mode.ZERO_G)
	assert_eq(q.physics_mode, PhysicsMode.Mode.FLY)


func test_a_broken_or_missing_lab_mode_is_normal() -> void:
	assert_eq(WorldMeta.new_random().lab_mode, LabRules.Mode.NORMAL)
	assert_eq(WorldMeta.from_json('{"version":1,"seed":5,"physics_mode":1}').lab_mode, LabRules.Mode.NORMAL,
		"a world saved before the lab")
	for bad: String in ['99', '-3', '"moon"', '2.5e40', 'null']:
		assert_eq(WorldMeta.from_json('{"version":1,"seed":5,"lab_mode":%s}' % bad).lab_mode, LabRules.Mode.NORMAL, bad)
	assert_eq(WorldMeta.from_json('{"version":1,"seed":5,"lab_mode":5}').lab_mode, LabRules.Mode.SLOW)
