extends GutTest
## Owner feedback #39 (spec §14.2a): "the portal back stands at the arrival point". A child who came through a
## universe portal arrives in front of a portal to the universe they came from: the world's own portal to it when
## it has one, else ReturnGate builds one a few steps in front of them (frames and that universe's core, the
## doorway cleared, never inside the child), and walking out of it leads the child back towards where they stand.

const FLOOR := 30

var cells := {}


func before_each() -> void:
	cells = {}


func _at(p: Vector3i) -> int:
	if cells.has(p):
		return cells[p]
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _apply(edits: Array) -> void:
	for e: Array in edits:
		cells[e[0]] = e[1]


func test_it_builds_a_whole_portal_to_the_universe_left_in_front_of_the_child() -> void:
	for yaw: float in [0.0, PI * 0.5, PI, -PI * 0.5, 0.4]:
		cells = {}
		var feet := Vector3(10.5, FLOOR, -3.5)
		var plan := ReturnGate.plan(feet, yaw, 2, _at)
		assert_false(plan.is_empty(), "yaw %.2f" % yaw)
		_apply(plan.edits)
		var core: Vector3i = plan.core
		assert_eq(_at(core), BlockIds.CORE_DESERT, "the desert's core in its core slot")
		var p := PortalRules.find(core, _at)
		assert_false(p.is_empty(), "a whole frame round an open doorway (yaw %.2f)" % yaw)
		var forward := Vector3(-sin(yaw), 0, -cos(yaw))
		var to_gate := PortalRules.center(p) - feet
		to_gate.y = 0.0
		assert_gt(forward.dot(to_gate.normalized()), 0.6, "in front of the child")
		assert_between(to_gate.length(), 2.5, 5.0, "a few steps away")
		var exit := PortalRules.exit_spot(p, _at)
		assert_true(exit.is_finite(), "its exit is open")


func test_never_inside_the_child_and_clears_what_stands_in_the_doorway() -> void:
	var feet := Vector3(0.5, FLOOR, 0.5)
	for x in range(-6, 7):
		for z in range(-6, 7):
			for y in range(FLOOR, FLOOR + 4):
				cells[Vector3i(x, y, z)] = BlockIds.LEAVES   # a thicket all round
	for y in range(FLOOR, FLOOR + 2):
		cells[Vector3i(0, y, 0)] = BlockIds.AIR               # the child's own cell
	var plan := ReturnGate.plan(feet, 0.0, 1, _at)
	for e: Array in plan.edits:
		var c: Vector3i = e[0]
		assert_false(c.x == 0 and c.z == 0 and c.y >= FLOOR and c.y <= FLOOR + 1, "never in the child's cells")
	_apply(plan.edits)
	var p := PortalRules.find(plan.core, _at)
	assert_false(p.is_empty(), "the doorway was cleared")
	for c in PortalRules.opening_cells(p):
		assert_eq(_at(c), BlockIds.AIR)


func test_no_plan_for_a_universe_without_a_core() -> void:
	assert_true(ReturnGate.plan(Vector3(0, FLOOR, 0), 0.0, 99, _at).is_empty())
	assert_true(ReturnGate.plan(Vector3.INF, 0.0, 1, _at).is_empty())


func test_the_arrival_is_in_front_of_the_worlds_own_portal_when_it_has_one() -> void:
	var gates := PortalGates.new()
	var plan := ReturnGate.plan(Vector3(20.5, FLOOR, 20.5), 0.0, 3, _at)
	_apply(plan.edits)
	var p := PortalRules.find(plan.core, _at)
	p.exit = PortalRules.exit_spot(p, _at)
	gates.add(plan.core, 3)
	gates.set_shape(plan.core, p)
	var a := ReturnGate.arrival(gates, 3)
	assert_false(a.is_empty(), "the world's portal to Frostpeak")
	assert_almost_eq(a.pos as Vector3, p.exit as Vector3, Vector3.ONE * 0.001, "out in front of it")
	assert_almost_eq(float(a.yaw), PortalRules.exit_yaw(p, p.exit), 0.001, "facing away from it")
	assert_true(ReturnGate.arrival(gates, 2).is_empty(), "none to the desert: one is built instead")
