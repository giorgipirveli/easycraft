extends GutTest
## M3 Task 8: the building tools read and write many cells at once in the real terrain (WorldService.blocks_at,
## set_blocks): cells that fill their box well are read with one copy and written with one copy and one paste
## (one lock of the voxel data each, instead of one per cell), and every changed cell is still announced
## (block_changed: the guests' world sync, water, smart blocks and the rest hear it). Scattered cells, and a box
## that is not all loaded, go cell by cell.

var world: WorldService
var base: Vector3i


func before_all() -> void:
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child(world)
	var c := world.spawn_column()
	base = Vector3i(c.x, maxi(world.surface_height(c.x, c.y), MeadowsShape.SEA_LEVEL) + 30, c.y)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 48
	world.add_child(viewer)
	viewer.global_position = Vector3(base)
	# The lead (2026-10-01): the whole region the tests write in, not only two corners (a cell at (10, 12, -10) lay in a
	# chunk not loaded yet when the corners were, about 1 run in 3: its set_block did nothing).
	await wait_until(_region_editable, 30.0, "terrain loads")


func _region_editable() -> bool:
	for x in range(-12, 21, 8):
		for y in range(-4, 21, 8):
			for z in range(-12, 21, 8):
				if not world.is_editable(base + Vector3i(x, y, z)):
					return false
	return world.is_editable(base + Vector3i(20, 20, 20))


func after_all() -> void:
	world.free()


func test_a_box_is_written_and_announced_cell_by_cell() -> void:
	var changes: Array = []
	for c in PowerTools.box_cells(base, base + Vector3i(15, 15, 15)):
		changes.append([c, BlockIds.GLASS])
	var heard: Array = []
	var hear := func(p: Vector3i, o: int, n: int) -> void: heard.append([p, o, n])
	world.block_changed.connect(hear)
	var done := world.set_blocks(changes)
	world.block_changed.disconnect(hear)
	assert_eq(done.size(), 4096)
	assert_eq(heard.size(), 4096, "every cell announced")
	assert_eq(heard[0], [base, BlockIds.AIR, BlockIds.GLASS])
	assert_eq(world.get_block(base), BlockIds.GLASS)
	assert_eq(world.get_block(base + Vector3i(15, 15, 15)), BlockIds.GLASS)
	assert_eq(world.get_block(base + Vector3i(16, 15, 15)), BlockIds.AIR, "nothing outside the box")
	var cells: Array = PowerTools.box_cells(base + Vector3i(14, 14, 14), base + Vector3i(16, 16, 16))
	var ids := world.blocks_at(cells)
	for i in cells.size():
		assert_eq(ids[i], world.get_block(cells[i]), str(cells[i]))
	var again := world.set_blocks(changes)
	assert_eq(again.size(), 0, "nothing changes twice")
	var back: Array = changes.map(func(c: Array) -> Array: return [c[0], BlockIds.AIR])
	assert_eq(world.set_blocks(back).size(), 4096)
	assert_eq(world.get_block(base + Vector3i(7, 7, 7)), BlockIds.AIR)


func test_scattered_cells_go_one_by_one() -> void:
	var a := base + Vector3i(-10, 0, 0)
	var b := base + Vector3i(10, 12, -10)
	assert_eq(world.set_blocks([[a, BlockIds.BRICK], [b, BlockIds.PAINTED_RED]]),
		[[a, BlockIds.AIR, BlockIds.BRICK], [b, BlockIds.AIR, BlockIds.PAINTED_RED]])
	assert_eq(world.blocks_at([a, b]), PackedInt32Array([BlockIds.BRICK, BlockIds.PAINTED_RED]))
	world.set_blocks([[a, BlockIds.AIR], [b, BlockIds.AIR]])


func test_a_box_not_all_loaded_goes_cell_by_cell() -> void:
	var far := base + Vector3i(4000, 0, 0)
	var near := base + Vector3i(2, 0, 2)
	var changes: Array = [[near, BlockIds.STONE], [far, BlockIds.STONE]]
	assert_eq(world.set_blocks(changes), [[near, BlockIds.AIR, BlockIds.STONE]], "the far cell is not loaded")
	world.set_blocks([[near, BlockIds.AIR]])
