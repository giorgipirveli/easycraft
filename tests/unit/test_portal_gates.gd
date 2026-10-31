extends GutTest
## Owner feedback #39 (spec §14.2a): a universe portal is §14.2's frame ring with a universe crystal's core in its
## core slot (PortalRules finds it like a linking core's frame); it needs no partner. PortalGates keeps a world's
## universe portals (which core leads where, its frame, its exit), saved and loaded without ever failing.

const F := BlockIds.PORTAL_FRAME
const FLOOR := 20
const LO := Vector3i(4, FLOOR, 2)

var cells := {}


func before_each() -> void:
	cells = {}


func _at(p: Vector3i) -> int:
	if cells.has(p):
		return cells[p]
	return BlockIds.STONE if p.y < FLOOR else BlockIds.AIR


## A 1 x 2 doorway along X at `lo` with `core` in its bottom row. Returns the core cell.
func _frame(lo: Vector3i, core: int) -> Vector3i:
	for c in [lo + Vector3i(-1, -1, 0), lo + Vector3i(1, -1, 0), lo + Vector3i(-1, 0, 0), lo + Vector3i(1, 0, 0),
			lo + Vector3i(-1, 1, 0), lo + Vector3i(1, 1, 0), lo + Vector3i(0, 2, 0)]:
		cells[c] = F
	cells[lo + Vector3i.DOWN] = core
	return lo + Vector3i.DOWN


func test_a_frame_with_a_universe_core_is_a_portal() -> void:
	var core := _frame(LO, BlockIds.CORE_DESERT)
	var p := PortalRules.find(core, _at)
	assert_false(p.is_empty(), "the ring round the desert's core is a portal")
	assert_eq(p.lo, LO)
	assert_eq(p.size, Vector2i(1, 2))
	assert_true(PortalRules.is_core(BlockIds.CORE_DESERT))
	assert_true(PortalRules.is_core(BlockIds.PORTAL_CORE))
	assert_false(PortalRules.is_core(F))


func test_two_cores_in_one_ring_are_no_portal() -> void:
	var core := _frame(LO, BlockIds.CORE_FROST)
	cells[LO + Vector3i(1, -1, 0)] = BlockIds.CORE_CANDY   # the ring's bottom corner... is optional
	assert_false(PortalRules.find(core, _at).is_empty(), "a corner is not part of the ring")
	cells[LO + Vector3i(-1, 0, 0)] = BlockIds.CORE_CANDY   # a side cell holding a second core
	assert_true(PortalRules.find(core, _at).is_empty(), "the core must be the ring's only core")


func test_a_blocked_doorway_or_a_missing_frame_is_no_portal() -> void:
	var core := _frame(LO, BlockIds.CORE_MEADOWS)
	cells[LO + Vector3i.UP] = BlockIds.STONE
	assert_true(PortalRules.find(core, _at).is_empty(), "the doorway must be open")
	cells.erase(LO + Vector3i.UP)
	cells.erase(LO + Vector3i(0, 2, 0))
	assert_true(PortalRules.find(core, _at).is_empty(), "the ring must be whole")


func test_gates_know_where_each_leads_and_which_work() -> void:
	var g := PortalGates.new()
	var core := _frame(LO, BlockIds.CORE_FROST)
	assert_true(g.add(core, 3))
	assert_false(g.add(core, 3), "known already")
	assert_eq(g.universe_of(core), 3)
	assert_true(g.active().is_empty(), "no frame worked out yet")
	var p := PortalRules.find(core, _at)
	p.exit = PortalRules.exit_spot(p, _at)
	g.set_shape(core, p)
	assert_eq(g.active().size(), 1)
	assert_eq(int(g.active()[0].universe), 3, "the active list says where it leads (its swirl's colour)")
	assert_eq(g.gate_to(3), core, "the world's portal to Frostpeak")
	assert_eq(g.gate_to(2), null, "none to the desert")
	g.remove(core)
	assert_false(g.has(core))
	assert_eq(g.gate_to(3), null)


func test_at_most_max_gates() -> void:
	var g := PortalGates.new()
	for i in PortalGates.MAX:
		assert_true(g.add(Vector3i(i * 10, FLOOR, 0), 2))
	assert_false(g.add(Vector3i(-50, FLOOR, 0), 2), "a world keeps at most MAX universe portals")


func test_saved_and_loaded() -> void:
	var g := PortalGates.new()
	var core := _frame(LO, BlockIds.CORE_CANDY)
	g.add(core, 4)
	var p := PortalRules.find(core, _at)
	p.exit = PortalRules.exit_spot(p, _at)
	g.set_shape(core, p)
	g.add(Vector3i(90, FLOOR, 90), 2)   # a core whose frame isn't whole
	var back := PortalGates.from_save(JSON.parse_string(JSON.stringify(g.to_save())))
	assert_eq(back.order, g.order)
	assert_eq(back.universe_of(core), 4)
	assert_eq(back.shape_of(core).lo, LO)
	assert_almost_eq(back.shape_of(core).exit as Vector3, p.exit as Vector3, Vector3.ONE * 0.001)
	assert_true(back.shape_of(Vector3i(90, FLOOR, 90)).is_empty())
	assert_eq(back.gate_to(4), core)


func test_a_broken_save_is_no_gates_and_never_fails() -> void:
	for bad: Variant in [null, 3, "x", {}, [1, 2], [{"core": [1, 2]}], [{"core": [1, 2, 3], "universe": 99}],
			[{"core": [1, 2, 3], "universe": "desert"}], [{"core": [INF, 0, 0], "universe": 2}]]:
		assert_true(PortalGates.from_save(bad).order.is_empty(), str(bad))
	var ok := PortalGates.from_save([{"core": [1, 2, 3], "universe": 2, "axis": 7, "lo": [1, 3, 3], "size": [1, 2]}])
	assert_eq(ok.order.size(), 1, "a good core with a broken frame stays")
	assert_true(ok.shape_of(Vector3i(1, 2, 3)).is_empty(), "the broken frame reads as none")
