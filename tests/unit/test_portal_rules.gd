extends GutTest
## M3 Task 5 (spec §14.2): portal frames and cores, as pure rules. A portal is an upright ring of Portal
## Frame blocks round a doorway (1–3 wide, 2–3 high; corners optional) with one Portal Core in its bottom
## row. Cores link in pairs in the order they were placed; a pair works while both frames are whole; the
## traveller comes out in front of the other doorway, never into a wall. Links and frames are saved.

const F := BlockIds.PORTAL_FRAME
const C := BlockIds.PORTAL_CORE
const S := BlockIds.STONE

var cells := {}   # Vector3i -> block id (AIR elsewhere)


func before_each() -> void:
	cells = {}


func _at(p: Vector3i) -> int:
	return cells.get(p, BlockIds.AIR)


## An upright frame round a doorway `w` x `h` whose bottom-left opening cell is `lo`, along X (axis X,
## facing ±Z) or Z; the core at bottom-row index `core_i`; corners filled unless told not to.
func _frame(lo: Vector3i, w: int, h: int, along_x: bool, core_i: int = 0, corners: bool = true) -> Vector3i:
	var a := Vector3i(1, 0, 0) if along_x else Vector3i(0, 0, 1)
	for i in range(-1, w + 1):
		var corner := i == -1 or i == w
		if not corner or corners:
			cells[lo + a * i + Vector3i(0, -1, 0)] = F
			cells[lo + a * i + Vector3i(0, h, 0)] = F
	for j in h:
		cells[lo - a + Vector3i(0, j, 0)] = F
		cells[lo + a * w + Vector3i(0, j, 0)] = F
	var core := lo + a * core_i + Vector3i(0, -1, 0)
	cells[core] = C
	return core


func _floor(center: Vector3i, r: int, y: int) -> void:
	for x in range(center.x - r, center.x + r + 1):
		for z in range(center.z - r, center.z + r + 1):
			if not cells.has(Vector3i(x, y, z)):
				cells[Vector3i(x, y, z)] = S


# --- Finding a frame ---

func test_a_doorway_framed_along_x_is_found_from_its_core() -> void:
	var core := _frame(Vector3i(10, 21, 5), 1, 2, true)
	var p := PortalRules.find(core, _at)
	assert_false(p.is_empty())
	assert_eq(p.core, core)
	assert_eq(p.axis, PortalRules.AXIS_X)
	assert_eq(p.lo, Vector3i(10, 21, 5))
	assert_eq(p.size, Vector2i(1, 2))


func test_a_bigger_doorway_along_z_with_the_core_anywhere_in_the_bottom_row() -> void:
	var core := _frame(Vector3i(-4, 30, 7), 3, 3, false, 2)
	var p := PortalRules.find(core, _at)
	assert_eq(p.axis, PortalRules.AXIS_Z)
	assert_eq(p.lo, Vector3i(-4, 30, 7))
	assert_eq(p.size, Vector2i(3, 3))


func test_corners_are_optional() -> void:
	var core := _frame(Vector3i(0, 10, 0), 2, 3, true, 1, false)
	assert_eq(PortalRules.find(core, _at).size, Vector2i(2, 3))


func test_no_whole_frame_no_portal() -> void:
	assert_true(PortalRules.find(Vector3i(0, 10, 0), _at).is_empty(), "no core")
	cells[Vector3i(0, 10, 0)] = C
	assert_true(PortalRules.find(Vector3i(0, 10, 0), _at).is_empty(), "a core alone")
	var core := _frame(Vector3i(20, 10, 0), 1, 2, true)
	cells.erase(Vector3i(20, 12, 0))   # the top of the frame
	assert_true(PortalRules.find(core, _at).is_empty(), "a gap in the frame")


func test_a_blocked_doorway_or_a_second_core_is_no_portal() -> void:
	var core := _frame(Vector3i(0, 10, 0), 1, 2, true)
	cells[Vector3i(0, 11, 0)] = S
	assert_true(PortalRules.find(core, _at).is_empty(), "stone in the doorway")
	cells.erase(Vector3i(0, 11, 0))
	cells[Vector3i(-1, 10, 0)] = C   # a second core in the ring
	assert_true(PortalRules.find(core, _at).is_empty(), "one core per frame")


func test_other_blocks_do_not_make_a_frame() -> void:
	var core := _frame(Vector3i(0, 10, 0), 1, 2, true)
	cells[Vector3i(1, 10, 0)] = S
	assert_true(PortalRules.find(core, _at).is_empty())


func test_breaking_a_frame_block_stops_it() -> void:
	var core := _frame(Vector3i(0, 10, 0), 2, 2, true)
	var p := PortalRules.find(core, _at)
	assert_true(PortalRules.frame_ok(p, _at))
	cells.erase(Vector3i(2, 10, 0))
	assert_false(PortalRules.frame_ok(p, _at))
	cells[Vector3i(2, 10, 0)] = F
	cells[Vector3i(0, 10, 0)] = BlockIds.WATER
	assert_true(PortalRules.frame_ok(p, _at), "water in the doorway is fine: walk through it")


# --- Walking in and coming out ---

func test_walking_into_the_doorway() -> void:
	var core := _frame(Vector3i(0, 10, 0), 1, 2, true)
	var p := PortalRules.find(core, _at)
	assert_true(PortalRules.in_opening(Vector3(0.5, 10.0, 0.5), p), "standing in it")
	assert_true(PortalRules.in_opening(Vector3(0.4, 10.0, 1.1), p), "half through")
	assert_false(PortalRules.in_opening(Vector3(0.5, 10.0, 2.5), p), "in front of it")
	assert_false(PortalRules.in_opening(Vector3(2.5, 10.0, 0.5), p), "beside it")
	assert_false(PortalRules.in_opening(Vector3(0.5, 14.0, 0.5), p), "above it")


func test_the_traveller_comes_out_in_front_on_the_ground() -> void:
	var core := _frame(Vector3i(0, 10, 0), 1, 2, true)
	_floor(Vector3i(0, 9, 0), 3, 9)
	var p := PortalRules.find(core, _at)
	var out := PortalRules.exit_spot(p, _at)
	assert_true(out.is_finite())
	assert_eq(Vector3i(out.floor()), Vector3i(0, 10, 1), "in front of the doorway, on the ground")


func test_never_into_a_wall() -> void:
	var core := _frame(Vector3i(0, 10, 0), 1, 2, true)
	_floor(Vector3i(0, 9, 0), 3, 9)
	cells[Vector3i(0, 10, 1)] = S
	var p := PortalRules.find(core, _at)
	assert_eq(Vector3i(PortalRules.exit_spot(p, _at).floor()), Vector3i(0, 10, -1), "the other side")
	cells[Vector3i(0, 11, -1)] = S
	assert_false(PortalRules.exit_spot(p, _at).is_finite(), "walled in on both sides: nowhere to come out")


func test_the_traveller_faces_away_from_the_doorway() -> void:
	var core := _frame(Vector3i(0, 10, 0), 1, 2, true)
	_floor(Vector3i(0, 9, 0), 3, 9)
	var p := PortalRules.find(core, _at)
	var out := PortalRules.exit_spot(p, _at)
	var yaw := PortalRules.exit_yaw(p, out)
	var forward := Vector3(-sin(yaw), 0, -cos(yaw))
	assert_gt(forward.dot(out - PortalRules.center(p)), 0.0, "looking out, not back in")


# --- Links ---

func test_cores_link_in_pairs_in_the_order_they_were_placed() -> void:
	var l := PortalLinks.new()
	var a := Vector3i(0, 0, 0)
	var b := Vector3i(10, 0, 0)
	var c := Vector3i(20, 0, 0)
	var d := Vector3i(30, 0, 0)
	for core in [a, b, c]:
		assert_true(l.add(core))
	assert_eq(l.partner_of(a), b)
	assert_eq(l.partner_of(b), a)
	assert_eq(l.partner_of(c), null, "the third waits")
	l.add(d)
	assert_eq(l.partner_of(c), d)


func test_breaking_a_core_frees_its_partner_for_the_next() -> void:
	var l := PortalLinks.new()
	var a := Vector3i(0, 0, 0)
	var b := Vector3i(10, 0, 0)
	var c := Vector3i(20, 0, 0)
	l.add(a)
	l.add(b)
	l.remove(b)
	assert_eq(l.partner_of(a), null)
	l.add(c)
	assert_eq(l.partner_of(a), c, "the waiting core links with the next one")
	assert_false(l.add(a), "a core is added once")


func test_a_pair_works_only_while_both_frames_are_whole() -> void:
	var l := PortalLinks.new()
	var a := Vector3i(0, 0, 0)
	var b := Vector3i(10, 0, 0)
	l.add(a)
	l.add(b)
	assert_false(l.works(a), "no frames yet")
	l.set_shape(a, {"core": a, "axis": 0, "lo": a + Vector3i.UP, "size": Vector2i(1, 2), "exit": Vector3(0.5, 1, 1.5)})
	assert_false(l.works(a), "the other frame isn't whole")
	l.set_shape(b, {"core": b, "axis": 0, "lo": b + Vector3i.UP, "size": Vector2i(1, 2), "exit": Vector3(10.5, 1, 1.5)})
	assert_true(l.works(a) and l.works(b))
	assert_eq(l.active().size(), 2, "both swirl")
	l.set_shape(b, {})
	assert_false(l.works(a))
	assert_eq(l.active().size(), 0)


func test_there_is_a_limit_of_portals_per_world() -> void:
	var l := PortalLinks.new()
	for i in PortalLinks.MAX:
		assert_true(l.add(Vector3i(i * 5, 0, 0)))
	assert_false(l.add(Vector3i(-5, 0, 0)))


func test_links_and_frames_are_saved_and_loaded() -> void:
	var l := PortalLinks.new()
	var a := Vector3i(1, 20, -3)
	var b := Vector3i(40, 25, 9)
	var c := Vector3i(-7, 30, 2)
	for core in [a, b, c]:
		l.add(core)
	l.set_shape(a, {"core": a, "axis": PortalRules.AXIS_X, "lo": a + Vector3i.UP, "size": Vector2i(2, 3), "exit": Vector3(1.5, 21, -1.5)})
	l.set_shape(b, {"core": b, "axis": PortalRules.AXIS_Z, "lo": b + Vector3i.UP, "size": Vector2i(1, 2), "exit": Vector3(41.5, 26, 9.5)})
	var back := PortalLinks.from_save(JSON.parse_string(JSON.stringify(l.to_save())))
	assert_eq(back.order, l.order)
	assert_eq(back.partner_of(a), b)
	assert_eq(back.partner_of(c), null)
	assert_eq(back.shape_of(a), l.shape_of(a))
	assert_eq(back.shape_of(b), l.shape_of(b))
	assert_true(back.works(a))


func test_cores_saved_without_partners_pair_up_two_by_two() -> void:
	var l := PortalLinks.from_save([{"core": [1, 0, 0]}, {"core": [2, 0, 0]}, {"core": [3, 0, 0]}, {"core": [4, 0, 0]}])
	assert_eq(l.partner_of(Vector3i(1, 0, 0)), Vector3i(2, 0, 0))
	assert_eq(l.partner_of(Vector3i(2, 0, 0)), Vector3i(1, 0, 0))
	assert_eq(l.partner_of(Vector3i(3, 0, 0)), Vector3i(4, 0, 0))
	assert_eq(l.partner_of(Vector3i(4, 0, 0)), Vector3i(3, 0, 0))


func test_broken_saves_are_dropped_safely() -> void:
	assert_eq(PortalLinks.from_save("nonsense").order.size(), 0)
	var l := PortalLinks.from_save([
		{"core": [1, 2, 3], "partner": [9, 9, 9]},               # its partner isn't in the list
		{"core": [1e30, 2, 3]},                                  # not a cell
		{"core": [5, 6, 7], "axis": 7, "lo": [5, 7, 7], "size": [9, 9]},   # a shape no frame has
		"core",
	])
	assert_eq(l.order, [Vector3i(1, 2, 3), Vector3i(5, 6, 7)] as Array[Vector3i])
	assert_eq(l.partner_of(Vector3i(1, 2, 3)), Vector3i(5, 6, 7), "the waiting cores pair up again")
	assert_true(l.shape_of(Vector3i(5, 6, 7)).is_empty(), "a broken frame reads as no frame")
