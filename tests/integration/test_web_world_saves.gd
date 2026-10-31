extends GutTest
## M7 Task 5 (spec §20.3): in a browser a world's saves reach the browser's storage. The real VoxelTerrain and its
## SQLite stream (headless): after the blocks of an edit are written, the world writes the WebStorage stamp, which makes
## the engine copy user:// (the database too) to IndexedDB. Every save point goes through WorldService.save or
## save_and_wait (the autosave, the pause menu, SAVE & QUIT, focus out), so both do it; off the web neither writes.

const PHONE_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true, PlatformRules.TOUCH_SCREEN: true}

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_web_world_saves_%d/" % OS.get_process_id()
var STAMP := "user://test_web_world_saves_%d.txt" % OS.get_process_id()


func before_each() -> void:
	WebStorage.stamp_path = STAMP
	_wipe()


func after_each() -> void:
	WebStorage.stamp_path = WebStorage.STAMP
	PlatformRules.simulated = {}
	_wipe()


func _wipe() -> void:
	if FileAccess.file_exists(STAMP):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(STAMP))
	var abs_dir := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		for f in DirAccess.get_files_at(abs_dir):
			DirAccess.remove_absolute(abs_dir.path_join(f))
		DirAccess.remove_absolute(abs_dir)


func _edited_world() -> WorldService:
	DirAccess.make_dir_recursive_absolute(DIR)
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup(DIR, 42)
	add_child(world)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.position = Vector3(0, 60, 0)
	world.add_child(viewer)
	await wait_until(func() -> bool: return world.is_editable(Vector3i(1, 60, 1)), 15.0, "terrain loads")
	world.set_block(Vector3i(1, 60, 1), BlockIds.DOOR)
	return world


func test_in_a_browser_save_and_quit_pushes_the_world_to_storage() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	var world := await _edited_world()
	assert_false(FileAccess.file_exists(STAMP), "nothing before the save")
	await world.save_and_wait(5.0)
	assert_true(FileAccess.file_exists(STAMP), "the stamp after the blocks are written")
	world.free()


func test_in_a_browser_an_autosave_pushes_the_world_to_storage() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	var world := await _edited_world()
	world.save()
	await wait_until(func() -> bool: return FileAccess.file_exists(STAMP), 5.0, "the stamp once the blocks are written")
	assert_true(FileAccess.file_exists(STAMP))
	world.free()


func test_off_the_web_saves_write_no_stamp() -> void:
	var world := await _edited_world()
	world.save()
	await world.save_and_wait(5.0)
	await wait_process_frames(3)
	assert_false(FileAccess.file_exists(STAMP), "Android and the desktop keep their files as they are")
	world.free()
