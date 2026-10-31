extends GutTest
## Owner #106: the rocket crashed down by the Launch Site comes back to the pad damaged (LaunchDirector.crash_damage,
## host only): a random share of its parts (CrashRules: 15-35%, seeded) is gone from the pad, the rest stands, nothing
## else is touched. The Mission Board says it ("Your rocket crashed: 9 parts broke. Rebuild them: 120 gold.") on MY
## ROCKET when the child is home at the board, and BUILD IT FOR ME and BUY THE PARTS FOR THIS ROCKET work on the damaged
## rocket as on any.

const SAVED := [40, 70, -12, 1, 1]


class FakeWorld:
	extends Node
	var cells := {}

	func block(p: Vector3i) -> int:
		return int(cells.get(p, BlockIds.AIR))

	func get_block(p: Vector3i) -> int:
		return block(p)

	func box_reader(_origin: Vector3i, _size: Vector3i) -> Callable:
		return block

	func is_editable(_p: Vector3i) -> bool:
		return true

	func set_blocks(changes: Array) -> Array:
		for c: Array in changes:
			if int(c[1]) == BlockIds.AIR:
				cells.erase(c[0])
			else:
				cells[c[0]] = c[1]
		return changes


var world: FakeWorld
var feet := Vector3.INF
var plan := {}


func before_each() -> void:
	world = FakeWorld.new()
	add_child_autofree(world)
	feet = Vector3.INF
	plan = RocketPlan.cells(MissionRules.for_world(SpaceRules.MOON), 1)


func _director(host := true) -> LaunchDirector:
	var d := LaunchDirector.new()
	d.search_later = false
	d.world = world
	d.host = host
	d.player_position = func() -> Vector3: return feet
	add_child_autofree(d)
	d.setup(MeadowsShape.new(12345), SAVED, [], self)
	return d


func _build_on_pad(d: LaunchDirector) -> void:
	var corner := LaunchSite.corner(d.site)
	for c: Vector3i in plan:
		world.cells[corner + c] = plan[c]


func _run(d: LaunchDirector, frames: int, delta := 0.05) -> void:
	for i in frames:
		d._process(delta)


func test_a_crash_breaks_15_to_35_percent_of_the_pads_rocket() -> void:
	var d := _director()
	_build_on_pad(d)
	var corner := LaunchSite.corner(d.site)
	var bench := Vector3i(0, 0, 0) if not plan.has(Vector3i(0, 0, 0)) else Vector3i(8, 0, 8)
	assert_false(plan.has(bench))
	world.cells[corner + bench] = BlockIds.PLANKS   # a child's bench on the pad's edge
	var before := RocketCheck.find_rocket(d.read_pad())
	assert_eq(before, plan)
	var res := d.crash_damage(7)
	var after := RocketCheck.find_rocket(d.read_pad())
	var broke := int(res.count)
	assert_between(float(broke) / plan.size(), CrashRules.LEAST - 0.001, CrashRules.MOST + 0.001)
	assert_eq(d.read_pad().size(), plan.size() + 1 - broke, "the broken parts are gone from the pad")
	for c: Vector3i in res.broken:
		assert_eq(world.block(corner + c), BlockIds.AIR)
	assert_eq(world.block(corner + bench), BlockIds.PLANKS, "never a child's other block")
	assert_eq(res.parts, RocketParts.count(res.broken))
	assert_eq(res.rocket, RocketParts.count(plan), "what the rocket had, for the rebuild's price")
	assert_lt(after.size(), plan.size())


func test_the_same_seed_breaks_the_same_cells() -> void:
	var d := _director()
	_build_on_pad(d)
	var a: Dictionary = d.crash_damage(11).broken
	_build_on_pad(d)
	assert_eq(d.crash_damage(11).broken, a)


func test_a_guest_never_breaks_and_an_empty_pad_has_nothing_to_break() -> void:
	var guest := _director(false)
	_build_on_pad(guest)
	assert_eq(guest.crash_damage(3), {}, "the host's pad is the host's")
	assert_eq(RocketCheck.find_rocket(guest.read_pad()), plan)
	world.cells.clear()
	var host := _director()
	assert_eq(host.crash_damage(3), {}, "no rocket on the pad")


func test_home_at_the_board_it_opens_on_my_rocket_with_the_crash() -> void:
	var d := _director()
	_build_on_pad(d)
	feet = LaunchSite.board_position(d.site)
	_run(d, 3)
	assert_true(d.board.visible)
	d.board.close()   # LAUNCH closed it; the child stood at the board all along
	_run(d, 3)
	assert_false(d.board.visible)
	d.crash_damage(5)
	d.notice_crash(CrashRules.words(9, 120))
	_run(d, 3)
	assert_false(d.board.visible, "a moment first: home, the hearts, the words")
	_run(d, int(LaunchDirector.NOTICE_SECONDS / 0.05) + 4)
	assert_true(d.board.visible, "then the board")
	assert_eq(d.board.page, MissionBoard.ROCKET_PAGE)
	assert_eq(d.board.message(), "Your rocket crashed: 9 parts broke. Rebuild them: 120 gold.")
	d.board.close()
	feet = LaunchSite.board_position(d.site) + Vector3(30, 0, 0)
	_run(d, 3)
	feet = LaunchSite.board_position(d.site)
	_run(d, 3)
	assert_ne(d.board.message(), "Your rocket crashed: 9 parts broke. Rebuild them: 120 gold.", "said once")


func test_away_from_the_board_the_crash_waits_for_the_walk_up() -> void:
	var d := _director()
	_build_on_pad(d)
	feet = LaunchSite.board_position(d.site) + Vector3(40, 0, 0)
	d.crash_damage(5)
	d.notice_crash(CrashRules.words(6, 90))
	_run(d, int(LaunchDirector.NOTICE_SECONDS / 0.05) + 4)
	assert_false(d.board.visible)
	feet = LaunchSite.board_position(d.site)
	_run(d, 3)
	assert_true(d.board.visible)
	assert_eq(d.board.message(), CrashRules.words(6, 90))


func test_build_it_for_me_and_buy_work_on_the_damaged_rocket() -> void:
	var d := _director()
	d.stamped = true
	_build_on_pad(d)
	var owned := RocketParts.count(plan)   # the Sandbox: every part was bought
	var res := d.crash_damage(9)
	for id: int in res.parts:
		owned[id] = int(owned[id]) - int(res.parts[id])   # MissionData.lose_parts
	var board := d.board
	board.read_rocket = d.read_pad
	board.owned = func() -> Variant: return owned
	board.gold = func() -> int: return 5000
	board.build = func(w: int, crew_n: int) -> String:
		var m := MissionRules.for_world(w)
		var p := RocketPlan.cells(m, crew_n)
		return d.build(p, RocketPlan.stage_words(p), str(m.get("place", "space")))
	board.open()
	board.choose(SpaceRules.MOON)
	assert_true(board.build_button.visible or board.pad_has_parts(), "MY ROCKET")
	assert_eq(board.press_build(), "", "BUILD IT FOR ME on the damaged rocket")
	_run(d, 2000, 0.05)
	assert_false(d.building())
	assert_eq(RocketCheck.find_rocket(d.read_pad()), plan, "the rocket whole again")
	board.check()
	assert_eq(board.missing_cost(), int(res.gold), "BUY THE PARTS FOR THIS ROCKET: the broken parts' gold")
	assert_eq(CrashRules.rebuild_gold(res.rocket, owned), int(res.gold))
