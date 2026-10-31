extends GutTest
## Missions (spec §21d.1): a home world's Launch Site in a world. The site is found from the seed (avoiding the
## Theater), the buildings stand, the host stamps the pad once its ground is loaded and still the world's own (never over
## a child's build), the save keeps it; walking up to the Mission Board opens it, walking away closes it; the check reads
## the pad's cells relative to its corner.

const SEED := 12345


## The world's blocks: the generator's ground (grass on stone) and whatever was written.
class FakeWorld:
	extends Node
	var shape: MeadowsShape
	var cells := {}
	var writes := 0

	func block(p: Vector3i) -> int:
		if cells.has(p):
			return cells[p]
		var h := shape.height_at(p.x, p.z)
		if p.y < h - 1:
			return BlockIds.STONE
		return BlockIds.GRASS if p.y == h - 1 else BlockIds.AIR

	func box_reader(_origin: Vector3i, _size: Vector3i) -> Callable:
		return block

	func is_editable(_p: Vector3i) -> bool:
		return true

	func set_blocks(changes: Array) -> Array:
		writes += 1
		for c: Array in changes:
			cells[c[0]] = c[1]
		return changes


var shape := MeadowsShape.new(SEED)
var world: FakeWorld
var placed: Array = []
var feet := Vector3.INF


func before_each() -> void:
	shape = MeadowsShape.new(SEED)
	world = FakeWorld.new()
	world.shape = shape
	add_child_autofree(world)
	placed = []
	feet = Vector3.INF


func _director(saved: Array = [], host := true) -> LaunchDirector:
	var d := LaunchDirector.new()
	d.search_later = false
	d.world = world
	d.host = host
	d.player_position = func() -> Vector3: return feet
	d.site_placed.connect(func(s: Array) -> void: placed.append(s))
	add_child_autofree(d)
	d.setup(shape, saved, [], self)
	return d


func _run(d: LaunchDirector, frames: int) -> void:
	for i in frames:
		d._process(0.05)


func test_a_new_world_finds_its_site_and_stamps_the_pad_once() -> void:
	var d := _director()
	var expected := LaunchSite.pick_for(shape, TheaterSite.pick_for(shape))
	assert_false(expected.is_empty())
	assert_eq(d.site, expected, "from the seed, clear of the Theater")
	assert_not_null(d.buildings, "the tower and Mission Control stand")
	assert_eq(placed, [LaunchSite.to_save(expected, false)], "the save keeps it at once")
	assert_false(d.stamped)
	_run(d, 20)
	assert_true(d.stamped, "the pad went in, a batch a frame")
	assert_gt(world.writes, 3, "in batches")
	assert_eq(placed.back(), LaunchSite.to_save(expected, true))
	var p: Vector3i = expected.pos
	assert_eq(world.block(p), BlockIds.PAD_CONCRETE, "the pad's middle")
	assert_eq(world.block(p + Vector3i(LaunchSite.PAD_HALF, 0, 0)), BlockIds.PAD_STRIPE, "its ring")
	var writes := world.writes
	_run(d, 10)
	assert_eq(world.writes, writes, "once")


func test_a_saved_site_stands_where_it_was() -> void:
	var saved := [40, 70, -12, 1, 1]
	var d := _director(saved)
	assert_eq(d.site.pos, Vector3i(40, 70, -12))
	assert_true(d.stamped)
	_run(d, 10)
	assert_eq(world.writes, 0, "a stamped pad is never stamped again")
	assert_eq(d.saved_site(), saved)


func test_never_over_a_childs_build() -> void:
	shape = MeadowsShape.new(777)   # a seed with room for a second site (12345 has one spot only)
	world.shape = shape
	var first := LaunchSite.pick_for(shape, TheaterSite.pick_for(shape))
	var p: Vector3i = first.pos
	world.cells[p + Vector3i(0, 2, 0)] = BlockIds.PLANKS   # a child's hut stands there
	var d := _director()
	_run(d, 30)
	assert_ne(d.site.pos, p, "another place")
	assert_true(d.stamped)
	assert_eq(world.block(p + Vector3i(0, 2, 0)), BlockIds.PLANKS, "the hut is untouched")


func test_a_guest_never_stamps() -> void:
	var d := _director([], false)
	assert_false(d.site.is_empty(), "a guest finds the site from the seed like the host")
	_run(d, 20)
	assert_eq(world.writes, 0)
	assert_eq(placed, [], "a guest saves nothing")


func test_walking_up_to_the_board_opens_it() -> void:
	var d := _director([40, 70, -12, 1, 1])
	var board_at := LaunchSite.board_position(d.site)
	feet = board_at + Vector3(0, 0, 0)
	_run(d, 3)
	assert_true(d.board.visible, "walking up opens it")
	d.board.close_button.pressed.emit()
	_run(d, 3)
	assert_false(d.board.visible, "X: it stays closed while the child stands there")
	feet = board_at + Vector3(20, 0, 0)
	_run(d, 3)
	feet = board_at
	_run(d, 3)
	assert_true(d.board.visible, "walking away and back opens it again")
	feet = board_at + Vector3(20, 0, 0)
	_run(d, 3)
	assert_false(d.board.visible, "walking away closes it")


func test_the_check_reads_the_pad_relative_to_its_corner() -> void:
	var d := _director([40, 70, -12, 1, 1])
	var corner := LaunchSite.corner(d.site)
	world.cells[corner] = BlockIds.ROCKET_ENGINE
	world.cells[corner + Vector3i(0, 1, 0)] = BlockIds.FUEL_TANK
	world.cells[corner + Vector3i(8, 3, 8)] = BlockIds.CREW_CAPSULE
	var cells := d.read_pad()
	assert_eq(cells.get(Vector3i.ZERO), BlockIds.ROCKET_ENGINE)
	assert_eq(cells.get(Vector3i(0, 1, 0)), BlockIds.FUEL_TANK)
	assert_eq(cells.get(Vector3i(8, 3, 8)), BlockIds.CREW_CAPSULE)
	assert_false(cells.has(Vector3i(0, -1, 0)), "the pad itself is not the rocket")
