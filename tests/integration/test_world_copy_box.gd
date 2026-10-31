extends GutTest
## WorldService.copy_box on a real VoxelTerrain (M2 Task 15): one bulk copy of a box that the explorer
## friend searches with BotRules.find_in_buffer (no call per cell).

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_copy_box_%d/" % OS.get_process_id()

var world: WorldService


func before_each() -> void:
	_wipe()
	DirAccess.make_dir_recursive_absolute(DIR)
	world = load("res://world/world.tscn").instantiate()
	world.setup(DIR, 42)
	add_child_autofree(world)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 48
	viewer.position = Vector3(0, 40, 0)
	world.add_child(viewer)


func after_all() -> void:
	_wipe()


func _wipe() -> void:
	var abs_dir := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		for f in DirAccess.get_files_at(abs_dir):
			DirAccess.remove_absolute(abs_dir.path_join(f))
		DirAccess.remove_absolute(abs_dir)


func test_a_copied_box_holds_the_worlds_blocks_and_its_ores_are_found() -> void:
	var c := world.spawn_column()
	var top := world.surface_height(c.x, c.y)
	var origin := Vector3i(c.x - 4, top - 2, c.y - 4)
	var size := Vector3i(9, 5, 9)
	var loaded := func() -> bool:
		for y in size.y:
			for z in size.z:
				for x in size.x:
					if not world.is_editable(origin + Vector3i(x, y, z)):
						return false
		return true
	await wait_until(loaded, 10.0, "terrain loads (every block the box touches)")
	var gold := Vector3i(c.x + 2, top + 1, c.y - 1)
	world.set_block(gold, BlockIds.GOLD)
	var buf := world.copy_box(origin, size)
	for y in size.y:
		for z in size.z:
			for x in size.x:
				var p := origin + Vector3i(x, y, z)
				assert_eq(buf.get_voxel(x, y, z, VoxelBuffer.CHANNEL_TYPE), world.get_block(p), "cell %s" % p)
	var finds := BotRules.find_in_buffer(buf, origin, BotRules.SHINY)
	assert_has(finds, gold)
	assert_eq(BotRules.nearest_open(gold + Vector3i.UP, finds, world.get_block, {}), gold, "open to the air")
