extends GutTest
## Owner #98: BUILD IT FOR ME. The host's Launch Site (LaunchDirector.build) builds Mission Control's plan on its pad
## layer by layer (at most BUILD_CELLS_PER_FRAME cells a frame, a layer about every BUILD_LAYER_SECONDS), with a caption
## and a spoken line per stage. It keeps the cells already right, clears the stray rocket parts in the build box (they
## would join the rocket), never breaks a child's other blocks (it says how many to move first), refuses before the pad
## is stamped, on a friend's game and while it already builds, waits while someone stands in the build box, and goes
## through the sandbox's write hook (Survivor: the bag pays). At the end the board opens on MY ROCKET if the child is
## still at it.

const SEED := 12345
const SITE := [40, 70, -12, 1, 1]


## A flat world: what was written, air everywhere else; it counts the cells written each frame.
class FlatWorld:
	extends Node
	var cells := {}
	var writes: Array = []   # the size of each set_blocks call
	var editable := true

	func get_block(p: Vector3i) -> int:
		return int(cells.get(p, BlockIds.AIR))

	func box_reader(_origin: Vector3i, _size: Vector3i) -> Callable:
		return get_block

	func is_editable(_p: Vector3i) -> bool:
		return editable

	func set_blocks(changes: Array) -> Array:
		writes.append(changes.size())
		var out: Array = []
		for c: Array in changes:
			var old := get_block(c[0])
			if int(c[1]) == BlockIds.AIR:
				cells.erase(c[0])
			else:
				cells[c[0]] = c[1]
			out.append([c[0], old, c[1]])
		return out


var world: FlatWorld
var said: Array = []
var bodies: Array = []
var feet := Vector3.INF
var ended: Array = []


func before_each() -> void:
	world = FlatWorld.new()
	add_child_autofree(world)
	said = []
	bodies = []
	feet = Vector3.INF
	ended = []


func _director(saved: Array = SITE, host := true) -> LaunchDirector:
	var d := LaunchDirector.new()
	d.search_later = false
	d.world = world
	d.host = host
	d.player_position = func() -> Vector3: return feet
	d.say = func(text: String) -> void: said.append(text)
	d.bodies = func() -> Array: return bodies
	d.is_paused = func() -> bool: return false
	d.build_finished.connect(func(why: String) -> void: ended.append(why))
	add_child_autofree(d)
	d.setup(MeadowsShape.new(SEED), saved, [], self)
	return d


func _moon_plan() -> Dictionary:
	return RocketPlan.cells(MissionRules.for_world(SpaceRules.MOON), 1)


func _build(d: LaunchDirector, plan: Dictionary) -> String:
	return d.build(plan, RocketPlan.stage_words(plan), "the Moon")


func _run(d: LaunchDirector, seconds: float, step := 1.0 / 60.0) -> void:
	var t := 0.0
	while t < seconds:
		d._process(step)
		t += step


func _on_pad(d: LaunchDirector) -> Dictionary:
	return RocketCheck.find_rocket(d.read_pad())


func test_it_builds_the_plan_layer_by_layer_with_a_line_per_stage() -> void:
	var d := _director()
	var plan := _moon_plan()
	assert_eq(_build(d, plan), "")
	assert_true(d.building())
	assert_string_contains(said[0], "the Moon")
	_run(d, 0.2)
	assert_lt(world.cells.size(), plan.size(), "not all at once")
	_run(d, RocketPlan.layers(plan).size() * LaunchDirector.BUILD_LAYER_SECONDS + 2.0)
	assert_false(d.building())
	assert_eq(ended, [""], "it finished")
	assert_eq(d.read_pad(), plan, "the whole plan stands on the pad")
	for n: int in world.writes:
		assert_lte(n, LaunchDirector.BUILD_CELLS_PER_FRAME, "at most 16 cells a frame")
	var words := RocketPlan.stage_words(plan)
	for w in words:
		assert_has(said, w, "a line per stage")
	assert_lt(said.find(words[0]), said.find(words[words.size() - 1]), "bottom stage first")
	assert_true(RocketCheck.check(d.read_pad(), MissionRules.for_world(SpaceRules.MOON)).ok, "it flies")


func test_the_layers_come_one_at_a_time() -> void:
	var d := _director()
	var plan := _moon_plan()
	_build(d, plan)
	_run(d, 0.05)
	var low := 99
	var high := -1
	for p: Vector3i in d.read_pad():
		low = mini(low, p.y)
		high = maxi(high, p.y)
	assert_eq([low, high], [0, 0], "the first layer first")
	_run(d, LaunchDirector.BUILD_LAYER_SECONDS * 0.8)
	high = -1
	for p: Vector3i in d.read_pad():
		high = maxi(high, p.y)
	assert_lte(high, 1, "about one layer every %.1f s" % LaunchDirector.BUILD_LAYER_SECONDS)


func test_it_refuses_until_the_pad_is_ready_on_a_guest_and_while_building() -> void:
	var unstamped := _director([40, 70, -12, 1, 0])
	assert_eq(_build(unstamped, _moon_plan()), LaunchDirector.PAD_NOT_READY)
	var guest := _director(SITE, false)
	assert_eq(_build(guest, _moon_plan()), MissionRules.message(MissionRules.GUEST), "a friend's pad: LAUNCH's words")
	var d := _director()
	assert_eq(_build(d, _moon_plan()), "")
	assert_eq(_build(d, _moon_plan()), LaunchDirector.BUSY)


## A half-built rocket: the cells already right stay; other rocket parts in the build box go (they would join the
## rocket); a child's other blocks off the rocket stay.
func test_it_keeps_what_is_right_and_clears_stray_parts() -> void:
	var d := _director()
	var corner := LaunchSite.corner(d.site)
	var plan := _moon_plan()
	var right := 0
	for p: Vector3i in plan:
		if p.y == 0:
			world.cells[corner + p] = plan[p]
			right += 1
	world.cells[corner + Vector3i(0, 20, 0)] = BlockIds.FUEL_TANK      # a stray part high in the box
	world.cells[corner + Vector3i(8, 0, 8)] = BlockIds.PLANKS          # a child's bench in a corner of the pad
	world.writes.clear()
	_build(d, plan)
	_run(d, 12.0)
	assert_eq(ended, [""])
	var written := 0
	for n: int in world.writes:
		written += n
	assert_eq(written, plan.size() - right + 1, "only what was missing, and the stray part cleared")
	assert_false(world.cells.has(corner + Vector3i(0, 20, 0)), "the stray part is gone")
	assert_eq(world.get_block(corner + Vector3i(8, 0, 8)), BlockIds.PLANKS, "the bench stays")
	assert_eq(_on_pad(d), plan)


func test_it_never_breaks_a_child_s_blocks() -> void:
	var d := _director()
	var corner := LaunchSite.corner(d.site)
	var plan := _moon_plan()
	var spots: Array = plan.keys().slice(0, 3)
	for p: Vector3i in spots:
		world.cells[corner + p] = BlockIds.BRICK
	world.writes.clear()
	assert_eq(_build(d, plan), RocketPlan.blocked_words(3), "it says how many to move first")
	assert_false(d.building())
	assert_eq(world.writes, [], "nothing written")
	for p: Vector3i in spots:
		assert_eq(world.get_block(corner + p), BlockIds.BRICK)


func test_it_waits_while_someone_stands_on_the_pad() -> void:
	var d := _director()
	var plan := _moon_plan()
	var corner := Vector3(LaunchSite.corner(d.site))
	bodies = [PlacementRules.player_aabb(corner + Vector3(4.5, 0, 4.5))]
	_build(d, plan)
	_run(d, 2.0)
	assert_eq(world.cells.size(), 0, "nothing while a child stands in the build box")
	assert_eq(said.count(LaunchDirector.STEP_OFF), 1, "said once")
	bodies = [PlacementRules.player_aabb(corner + Vector3(-6.0, 0, 4.5))]   # off the pad, by the board
	_run(d, 12.0)
	assert_eq(ended, [""], "then it goes on")
	assert_eq(d.read_pad(), plan)


func test_it_gives_up_when_the_pad_never_clears() -> void:
	var d := _director()
	bodies = [PlacementRules.player_aabb(Vector3(LaunchSite.corner(d.site)) + Vector3(4.5, 3, 4.5))]
	_build(d, _moon_plan())
	_run(d, LaunchDirector.BUILD_WAIT_SECONDS + 1.0, 0.25)
	assert_false(d.building())
	assert_eq(ended, [LaunchDirector.GAVE_UP])
	assert_has(said, LaunchDirector.GAVE_UP)


## Survivor: the sandbox's write hook pays from the bag; when it can't, the build stops and says why.
func test_the_write_hook_pays_and_can_stop_the_build() -> void:
	var d := _director()
	var paid := [0]
	d.write_cells = func(changes: Array) -> String:
		if paid[0] + changes.size() > 20:
			return "You need 3 more Fuel Tank!"
		paid[0] += changes.size()
		world.set_blocks(changes)
		return ""
	_build(d, _moon_plan())
	_run(d, 12.0)
	assert_eq(ended, ["You need 3 more Fuel Tank!"])
	assert_has(said, "You need 3 more Fuel Tank!")
	assert_lte(world.cells.size(), 20)


## A chunk not loaded yet: the build waits for it.
func test_it_waits_for_the_world_to_load() -> void:
	var d := _director()
	world.editable = false
	_build(d, _moon_plan())
	_run(d, 1.0)
	assert_eq(world.cells.size(), 0)
	world.editable = true
	_run(d, 12.0)
	assert_eq(ended, [""])


func test_at_the_end_the_board_opens_on_my_rocket_for_a_child_still_there() -> void:
	var d := _director()
	feet = LaunchSite.board_position(d.site)
	_run(d, 0.3)
	assert_true(d.board.visible)
	d.board.close()   # BUILD IT FOR ME closes the board so the child watches
	_build(d, _moon_plan())
	_run(d, 12.0)
	assert_true(d.board.visible, "it opens again")
	assert_eq(d.board.page, MissionBoard.ROCKET_PAGE)
	assert_string_contains(d.board.message(), "ready")
