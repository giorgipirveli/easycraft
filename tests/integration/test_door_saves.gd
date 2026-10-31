extends GutTest
## M2 Task 8: doors in the real VoxelTerrain (headless): an open door stays open and a closed one closed
## through a save and a load (its SQLite stream), and the terrain's physics lets bodies through an open
## door only (the defense smoke run found monsters pressing on an open door: the physics is built from
## mesh surfaces with collision on, not from collision_aabbs). Doors, traps and lanterns are ordinary ids.

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_door_saves_%d/" % OS.get_process_id()


func before_all() -> void:
	_wipe()


func after_all() -> void:
	_wipe()


func _wipe() -> void:
	var abs_dir := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		for f in DirAccess.get_files_at(abs_dir):
			DirAccess.remove_absolute(abs_dir.path_join(f))
		DirAccess.remove_absolute(abs_dir)


func _open_world() -> WorldService:
	DirAccess.make_dir_recursive_absolute(DIR)
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup(DIR, 42)
	add_child(world)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.requires_collisions = true
	viewer.position = Vector3(0, 60, 0)
	world.add_child(viewer)
	return world


func test_doors_traps_and_lanterns_keep_their_state_through_a_save() -> void:
	var cells := {Vector3i(1, 60, 1): BlockIds.DOOR_OPEN, Vector3i(1, 61, 1): BlockIds.DOOR_OPEN,
		Vector3i(3, 60, 1): BlockIds.DOOR, Vector3i(3, 61, 1): BlockIds.DOOR,
		Vector3i(5, 60, 1): BlockIds.SPIKE_TRAP, Vector3i(7, 60, 1): BlockIds.LANTERN}
	var world := _open_world()
	await wait_until(func() -> bool: return world.is_editable(Vector3i(1, 60, 1)) and world.is_editable(Vector3i(7, 61, 1)),
		15.0, "terrain loads")
	for p: Vector3i in cells:
		world.set_block(p, cells[p])
	await world.save_and_wait(5.0)
	world.free()
	var again := _open_world()
	await wait_until(func() -> bool: return again.is_editable(Vector3i(1, 60, 1)) and again.is_editable(Vector3i(7, 61, 1)),
		15.0, "terrain loads again")
	for p: Vector3i in cells:
		assert_eq(again.get_block(p), cells[p], "%s at %s" % [BlockIds.display_name(cells[p]), p])
	again.free()


func test_the_terrain_lets_bodies_through_an_open_door_only() -> void:
	var world := _open_world()
	var open := Vector3i(20, 70, 20)
	var closed := Vector3i(23, 70, 20)
	await wait_until(func() -> bool: return world.is_editable(open) and world.is_editable(closed), 15.0, "terrain loads")
	world.set_block(open, BlockIds.DOOR_OPEN)
	world.set_block(closed, BlockIds.DOOR)
	await wait_until(func() -> bool: return _ray_hits(world, closed), 10.0, "the closed door gets its collision")
	await wait_physics_frames(10)
	assert_true(_ray_hits(world, closed), "a closed door stops bodies")
	assert_false(_ray_hits(world, open), "an open door lets them through")
	world.free()


## Does a physics ray across the cell (on the world layer) hit something?
func _ray_hits(world: WorldService, cell: Vector3i) -> bool:
	var c := Vector3(cell) + Vector3(0.5, 0.5, 0.5)
	var q := PhysicsRayQueryParameters3D.create(c + Vector3(0, 0, -2), c + Vector3(0, 0, 2), 1)
	return not world.get_world_3d().direct_space_state.intersect_ray(q).is_empty()
