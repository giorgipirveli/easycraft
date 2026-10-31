extends GutTest

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var SLOT := "test_slot_%d" % OS.get_process_id()


func before_each() -> void:
	WorldSaves.delete(SLOT)


func after_all() -> void:
	WorldSaves.delete(SLOT)


func test_slot_dir_is_under_user_worlds() -> void:
	assert_eq(WorldSaves.dir_for(SLOT), "user://worlds/%s/" % SLOT)


func test_missing_slot_does_not_exist() -> void:
	assert_false(WorldSaves.exists(SLOT))


func test_saved_meta_round_trips_and_marks_slot_existing() -> void:
	var m := WorldMeta.new_random()
	m.seed = 4242
	m.player_pos = Vector3(3, 50, -7)
	assert_eq(WorldSaves.save_meta(SLOT, m), OK)
	assert_true(WorldSaves.exists(SLOT))
	var back := WorldSaves.load_meta(SLOT)
	assert_eq(back.seed, 4242)
	assert_eq(back.player_pos, Vector3(3, 50, -7))


func test_delete_removes_everything() -> void:
	WorldSaves.save_meta(SLOT, WorldMeta.new_random())
	var f := FileAccess.open(WorldSaves.dir_for(SLOT) + "voxels.sqlite", FileAccess.WRITE)
	f.store_string("fake db")
	f.close()
	WorldSaves.delete(SLOT)
	assert_false(WorldSaves.exists(SLOT))
	assert_false(DirAccess.dir_exists_absolute(WorldSaves.dir_for(SLOT)))


func test_load_missing_meta_gives_fresh_world() -> void:
	var m := WorldSaves.load_meta(SLOT)
	assert_false(m.has_player_pos())
