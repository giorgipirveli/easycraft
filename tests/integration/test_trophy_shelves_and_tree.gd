extends GutTest
## M3 Task 21b: trophy shelves near the child show the world owner's badges (one cached mesh per shelf content, a
## few shelves' worth at most), and the Hub Tree shows its state as one cached mesh whose fruits and stars shine.

var _cells: Array[Vector3i] = []


func _shelves(at: Vector3) -> TrophyShelves:
	var s := TrophyShelves.new()
	s.center = func() -> Vector3: return at
	s.index.scan_chunk = func(chunk: Vector3i) -> Array[Vector3i]:
		var out: Array[Vector3i] = []
		for c in _cells:
			if BlockIndex.chunk_of(c) == chunk:
				out.append(c)
		return out
	add_child_autofree(s)
	s.set_process(false)
	return s


func test_shelves_near_the_child_show_the_badges() -> void:
	_cells = [Vector3i(2, 10, 2), Vector3i(3, 10, 2), Vector3i(200, 10, 2)]
	var s := _shelves(Vector3(0, 10, 0))
	s.badges = ["first_buddy", "first_pet", "golem", "builder", "say_cheese"] as Array[String]
	for i in 4:
		s.refresh()   # a few chunks a look
	var shown := s.shown()
	assert_eq(shown.size(), 2, "the far shelf shows nothing")
	assert_eq(shown[Vector3i(2, 10, 2)], ["first_buddy", "first_pet", "golem", "builder"])
	assert_eq(shown[Vector3i(3, 10, 2)], ["say_cheese"])
	for m in s.get_children():
		assert_true(m is MeshInstance3D)
		assert_not_null((m as MeshInstance3D).mesh)


func test_one_mesh_per_shelf_content() -> void:
	var a := TrophyShelves.mesh_for(["golem"] as Array[String])
	assert_same(TrophyShelves.mesh_for(["golem"] as Array[String]), a, "cached")
	assert_ne(TrophyShelves.mesh_for(["builder"] as Array[String]), a)
	assert_eq(a.get_surface_count(), 1, "one draw call a shelf")


func test_a_new_badge_changes_what_a_shelf_shows() -> void:
	_cells = [Vector3i(1, 10, 1)]
	var s := _shelves(Vector3(0, 10, 0))
	s.badges = ["first_buddy"] as Array[String]
	s.refresh()
	var m := s.get_child(0) as MeshInstance3D
	var before := m.mesh
	s.badges = ["first_buddy", "golem"] as Array[String]
	s.refresh()
	assert_ne(m.mesh, before)
	assert_eq(s.shown()[Vector3i(1, 10, 1)], ["first_buddy", "golem"])


func test_a_broken_shelf_goes_away() -> void:
	_cells = [Vector3i(1, 10, 1)]
	var s := _shelves(Vector3(0, 10, 0))
	s.refresh()
	assert_eq(s.shown().size(), 1)
	s.index.note_block(Vector3i(1, 10, 1), BlockIds.TROPHY_SHELF, BlockIds.AIR)
	s.refresh()
	assert_eq(s.shown().size(), 0)


func test_not_too_many_shelves_at_once() -> void:
	_cells.clear()
	for x in 30:
		_cells.append(Vector3i(x - 15, 10, 3))
	var s := _shelves(Vector3(0, 10, 0))
	for i in 6:
		s.refresh()
	assert_lte(s.shown().size(), TrophyRules.MAX_SHELVES)


func test_the_hub_tree_is_one_cached_mesh_that_grows() -> void:
	var small := HubTreeRules.clean({"u": [1]})
	var big := HubTreeRules.clean({"u": [1, 2], "b": ["golem"], "p": ["secrets"]})
	var tree := HubTree.new()
	tree.set_state(small)
	add_child_autofree(tree)
	var first := tree.shown_mesh()
	assert_not_null(first)
	assert_eq(first.get_surface_count(), 1, "nothing shines yet")
	tree.set_state(small)
	assert_same(tree.shown_mesh(), first, "the same state keeps its mesh")
	tree.set_state(big)
	var grown := tree.shown_mesh() as ArrayMesh
	assert_eq(grown.get_surface_count(), 2, "the fruit and the star shine")
	assert_same(grown.surface_get_material(1), HubTree.glow_material(), "one shared glow material")
	assert_gt(grown.get_aabb().size.y, first.get_aabb().size.y, "taller")
	assert_same(HubTree.mesh_for(big), grown)
