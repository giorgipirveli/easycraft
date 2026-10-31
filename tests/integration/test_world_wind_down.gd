extends GutTest
## Freeing a world while it streams (M4 Wave 2 A2, found by the net test's rejoin): Voxel Tools waits
## for every queued generation task before the terrain goes, 6-13 s on this PC (4,700 tasks at a
## view distance of 128), and the game froze under "Trying again…". Without viewers the queue is
## dropped within about 150 ms, and then the world goes in a few milliseconds.

var nodes: Array[Node] = []


func after_each() -> void:
	for n in nodes:
		if is_instance_valid(n):
			n.free()
	nodes.clear()


func test_a_wound_down_world_goes_at_once() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 20260924, true)
	add_child(w)
	nodes.append(w)
	var holder := Node3D.new()   # like a player: the viewers are its children
	add_child(holder)
	nodes.append(holder)
	for d in [128, 48]:
		var v := VoxelViewer.new()
		v.view_distance = d
		holder.add_child(v)
	holder.position = Vector3(16, 40, 0)
	await wait_seconds(1.0)
	assert_gt(WorldService.voxel_tasks(), 100, "the world is still streaming (generation queued)")
	assert_eq(WorldService.stop_viewers(self), 2, "both viewers")
	var t0 := Time.get_ticks_msec()
	await WorldService.drain(get_tree(), 3.0)
	assert_eq(holder.get_child_count(), 0)
	gut.p("drained in %d ms" % (Time.get_ticks_msec() - t0))
	assert_eq(WorldService.voxel_tasks(), 0)
	var t1 := Time.get_ticks_msec()
	w.free()
	assert_lt(Time.get_ticks_msec() - t1, 1000, "freed without waiting for thousands of tasks")
