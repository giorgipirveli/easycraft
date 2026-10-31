extends GutTest
## M3 Task 15 (spec §14.9): the playground's cells go into the world while the tutorial runs and nothing of them is
## ever kept — every changed cell is recorded with what it held; clearing puts back exactly that, and gives the
## child back any block of theirs the clearing takes away. Only natural ground may be built over.

const SITE := {"origin": Vector3i(0, 40, 0), "dir": 0}


## A small voxel world: grass on top of dirt up to y 39 (ground height `h` per column), air above.
class Cells:
	extends RefCounted
	var cells := {}
	var heights := {}

	func ground(x: int, z: int) -> int:
		return int(heights.get(Vector2i(x, z), 40))

	func get_block(p: Vector3i) -> int:
		if cells.has(p):
			return cells[p]
		var h := ground(p.x, p.z)
		if p.y >= h:
			return BlockIds.AIR
		return BlockIds.GRASS if p.y == h - 1 else BlockIds.DIRT

	func apply(changes: Array) -> void:
		for c: Array in changes:
			cells[c[0]] = c[1]


func _plan(w: Cells) -> Array:
	return TutorialProps.plan(SITE, w.get_block)


func test_the_plan_digs_the_holes_builds_the_wall_the_bushes_and_the_workbench() -> void:
	var w := Cells.new()
	var record := _plan(w)
	w.apply(TutorialProps.changes_of(record))
	var at := func(a: int, s: int, dy: int) -> int: return w.get_block(TutorialCourse.cell(SITE, a, s, dy))
	for a in range(TutorialCourse.GAP_FROM, TutorialCourse.GAP_TO + 1):
		for s in range(-TutorialCourse.S_HALF, TutorialCourse.S_HALF + 1):
			assert_eq(at.call(a, s, -1), BlockIds.AIR, "the hole to jump")
			assert_eq(at.call(a, s, -2), BlockIds.AIR)
			assert_true(BlockIds.is_solid(at.call(a, s, -3)), "it has a floor")
	for a in range(TutorialCourse.BRIDGE_FROM, TutorialCourse.BRIDGE_TO + 1):
		assert_eq(at.call(a, 0, -1), BlockIds.AIR, "the hole to bridge")
	for s in range(-TutorialCourse.S_HALF, TutorialCourse.S_HALF + 1):
		assert_true(BlockIds.is_solid(at.call(TutorialCourse.WALL_A, s, 0)), "the wall")
		assert_true(BlockIds.is_solid(at.call(TutorialCourse.WALL_A, s, 1)))
	for b: Vector2i in TutorialCourse.BUSHES:
		assert_eq(at.call(b.x, b.y, 0), BlockIds.BUSH)
	assert_eq(w.get_block(TutorialCourse.bench(SITE)), BlockIds.CRAFTING_TABLE, "Pip's Workbench")
	assert_eq(at.call(0, 0, -1), BlockIds.GRASS, "the start is plain ground")
	assert_eq(at.call(0, 0, 0), BlockIds.AIR)


func test_a_bumpy_site_gets_a_level_pad() -> void:
	var w := Cells.new()
	w.heights[TutorialCourse.column(SITE, 0, 0)] = 42   # a hump two blocks high at the start
	w.heights[TutorialCourse.column(SITE, 9, 1)] = 38   # a dip two blocks deep on the landing
	w.cells[TutorialCourse.cell(SITE, 1, 1, 0)] = BlockIds.FLOWERS
	w.apply(TutorialProps.changes_of(_plan(w)))
	assert_eq(w.get_block(TutorialCourse.cell(SITE, 0, 0, 0)), BlockIds.AIR, "the hump is cut")
	assert_eq(w.get_block(TutorialCourse.cell(SITE, 0, 0, 1)), BlockIds.AIR)
	assert_eq(w.get_block(TutorialCourse.cell(SITE, 0, 0, -1)), BlockIds.GRASS, "grass on top of the cut")
	assert_eq(w.get_block(TutorialCourse.cell(SITE, 9, 1, -1)), BlockIds.GRASS, "the dip is filled, grass on top")
	assert_eq(w.get_block(TutorialCourse.cell(SITE, 9, 1, -2)), BlockIds.DIRT)
	assert_eq(w.get_block(TutorialCourse.cell(SITE, 1, 1, 0)), BlockIds.AIR, "flowers on the pad go (and come back)")


func test_clearing_puts_back_exactly_what_was_there() -> void:
	var w := Cells.new()
	w.cells[TutorialCourse.cell(SITE, 1, 1, 0)] = BlockIds.FLOWERS
	var before := {}
	var record := _plan(w)
	for e: Array in record:
		var p := Vector3i(e[0], e[1], e[2])
		before[p] = w.get_block(p)
		assert_eq(int(e[3]), before[p], "the record keeps what the cell held")
	assert_gt(record.size(), 100)
	w.apply(TutorialProps.changes_of(record))
	var out := TutorialProps.clear(record, w.get_block)
	w.apply(out.changes)
	for p: Vector3i in before:
		assert_eq(w.get_block(p), before[p], "put back: %s" % p)
	assert_true((out.returns as Dictionary).is_empty(), "the child built nothing into it")


func test_the_childs_bridge_and_blocks_come_back_to_their_bag() -> void:
	var w := Cells.new()
	var record := _plan(w)
	w.apply(TutorialProps.changes_of(record))
	for a in range(TutorialCourse.BRIDGE_FROM, TutorialCourse.BRIDGE_TO + 1):
		w.cells[TutorialCourse.cell(SITE, a, 0, -1)] = BlockIds.PLANKS   # the child's bridge
	w.cells[TutorialCourse.cell(SITE, TutorialCourse.WALL_A, 0, 0)] = BlockIds.AIR   # broke the wall
	w.cells[TutorialCourse.cell(SITE, TutorialCourse.WALL_A, 0, 1)] = BlockIds.AIR
	w.cells[TutorialCourse.cell(SITE, 4, 0, -2)] = BlockIds.STONE   # a block dropped into the hole
	var out := TutorialProps.clear(record, w.get_block)
	assert_eq(out.returns, {BlockIds.PLANKS: 3, BlockIds.STONE: 1}, "every block of theirs the clearing takes")
	w.apply(out.changes)
	assert_eq(w.get_block(TutorialCourse.cell(SITE, TutorialCourse.BRIDGE_FROM, 0, -1)), BlockIds.GRASS, "the ground is back")


func test_the_childs_blocks_outside_the_record_stay_theirs() -> void:
	var w := Cells.new()
	var record := _plan(w)
	w.apply(TutorialProps.changes_of(record))
	var mine := Vector3i(30, 40, 30)
	w.cells[mine] = BlockIds.PLANKS
	var out := TutorialProps.clear(record, w.get_block)
	w.apply(out.changes)
	assert_eq(w.get_block(mine), BlockIds.PLANKS, "never touched")


func test_only_natural_ground_may_be_built_over() -> void:
	var w := Cells.new()
	assert_true(TutorialProps.natural(SITE, w.get_block))
	w.cells[TutorialCourse.cell(SITE, 1, 1, 0)] = BlockIds.FLOWERS
	w.cells[TutorialCourse.cell(SITE, 2, -1, 1)] = BlockIds.LEAVES
	assert_true(TutorialProps.natural(SITE, w.get_block), "flowers and leaves are nature")
	w.cells[TutorialCourse.cell(SITE, 12, 2, 1)] = BlockIds.PLANKS
	assert_false(TutorialProps.natural(SITE, w.get_block), "a child's build: another site")


func test_the_record_saves_and_reads_back_safely() -> void:
	var w := Cells.new()
	var record := _plan(w)
	assert_eq(TutorialProps.clean(record), record)
	assert_eq(TutorialProps.clean([[1, 2, 3, 4, 5], "x", [1, 2], [1.5, 2, 3, 99999, 0], null]), [[1, 2, 3, 4, 5]])
	assert_eq(TutorialProps.clean(null), [])
	var box := TutorialProps.box(record)
	for e: Array in record:
		assert_true(box.grow(0.01).has_point(Vector3(e[0], e[1], e[2]) + Vector3(0.5, 0.5, 0.5)))


func test_the_world_meta_keeps_the_record_for_a_crash() -> void:
	var m := WorldMeta.new()
	m.tutorial_props = _plan(Cells.new())
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.tutorial_props, m.tutorial_props)
	assert_eq(WorldMeta.from_json("{}").tutorial_props, [])


func test_it_knows_when_it_would_go_under_or_into_the_child() -> void:
	var record := _plan(Cells.new())
	var feet := func(a: int, s: int) -> Vector3: return TutorialCourse.spot(SITE, a, s)
	assert_true(TutorialProps.touches(record, feet.call(4, 0)), "a hole under their feet")
	assert_true(TutorialProps.touches(record, feet.call(TutorialCourse.WALL_A, 1)), "a wall through them")
	assert_true(TutorialProps.touches(record, feet.call(TutorialCourse.BRIDGE_FROM - 1, 0)), "at a hole's edge (their body is wider than a block)")
	assert_false(TutorialProps.touches(record, feet.call(9, 0)), "the landing is plain ground")
	assert_false(TutorialProps.touches(record, Vector3(30, 40, 30)))


func test_the_plan_and_the_checks_read_only_inside_the_courses_box() -> void:
	var w := Cells.new()
	w.heights[TutorialCourse.column(SITE, 0, 0)] = 44   # a hump: the scan reaches the top of the box
	var box: Array = TutorialCourse.box(SITE)   # one bulk copy of it serves every read
	var lo: Vector3i = box[0]
	var hi: Vector3i = lo + (box[1] as Vector3i)
	var outside := []
	var reader := func(p: Vector3i) -> int:
		if p.x < lo.x or p.y < lo.y or p.z < lo.z or p.x >= hi.x or p.y >= hi.y or p.z >= hi.z:
			outside.append(p)
		return w.get_block(p)
	var record := TutorialProps.plan(SITE, reader)
	TutorialProps.natural(SITE, reader)
	w.apply(TutorialProps.changes_of(record))
	TutorialProps.clear(record, reader)
	TutorialChecks.bridge_done(SITE, reader)
	TutorialChecks.wall_open(SITE, reader)
	assert_eq(outside, [], "every read inside the box")
	assert_lte((box[1] as Vector3i).x * (box[1] as Vector3i).y * (box[1] as Vector3i).z, 2000, "a small copy")



func test_cells_not_written_yet_give_nothing_back() -> void:
	var w := Cells.new()
	var record := _plan(w)
	var half := record.slice(0, record.size() / 2)   # it went in a batch a tick: stopped (or a crash) half way
	w.apply(TutorialProps.changes_of(half))
	var out := TutorialProps.clear(record, w.get_block)
	assert_true((out.returns as Dictionary).is_empty(), "a cell still holding what it held is nobody's block")
	w.apply(out.changes)
	for e: Array in record:
		assert_eq(w.get_block(Vector3i(e[0], e[1], e[2])), int(e[3]))
