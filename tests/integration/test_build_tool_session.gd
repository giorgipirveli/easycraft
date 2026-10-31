extends GutTest
## M3 Task 8 through the host (Session section "M3 Task 8"): paint (Sandbox and Survivor; blocks with a job never,
## precious blocks never in Survivor, free both ways, a painted block breaks into itself), LINE, FILL and PASTE
## (Sandbox only; capped and refused whole beyond; only into empty cells; within reach of the eyes), one undo step
## per request and its undo through the host's log (a guest can't undo what its tools didn't do), guests'
## requests checked.

const ME_AT := Vector3(0.5, 10.0, 0.5)


## Stands in for the terrain: grass below y = 10, air above, plus `cells`.
class EditWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.GRASS if pos.y < 10 else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		var old := get_block(pos)
		if old == id:
			return
		cells[pos] = id
		block_changed.emit(pos, old, id)

	func is_editable(_pos: Vector3i) -> bool:
		return true


var world: EditWorld
var me: Player
var interactor: BlockInteractor
var _said: Array = []
var _steps: Array = []
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	Session.tool_reset()
	world = EditWorld.new()
	add_child_autofree(world)
	Session.register_world(world)
	me = _player(multiplayer.get_unique_id(), ME_AT)
	interactor = me.get_node("BlockInteractor")
	_said.clear()
	_steps.clear()
	Session.magic_feedback.connect(_on_said)
	Session.tool_undo_step_received.connect(_on_step)


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_said)
	Session.tool_undo_step_received.disconnect(_on_step)
	Game.mode = _mode_before
	Session.register_world(null)
	Session.survivor_reset()
	Session.tool_reset()
	Session.tool_frame_ms = Session.TOOL_FRAME_MS


func _on_said(text: String) -> void:
	_said.append(text)


func _on_step(step: Array) -> void:
	_steps.append(step)


func _player(peer: int, feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	p.world = world
	add_child_autofree(p)
	p.set_physics_process(false)
	p.global_position = feet
	p._spawned = true
	return p


func _handle_rpc_errors() -> void:
	for e in get_errors():   # a guest's undo step goes by RPC, and in a test there is no network peer
		e.handled = true

# --- Paint -------------------------------------------------------------------------------------------------

func test_paint_turns_a_plain_block_into_its_tint_as_one_undo_step() -> void:
	var cell := Vector3i(2, 10, 0)
	world.cells[cell] = BlockIds.BRICK
	assert_true(Session.request_build_tool(Session.TOOL_PAINT, [[cell, BlockIds.PAINTED_RED]]))
	assert_eq(world.get_block(cell), BlockIds.PAINTED_RED)
	assert_eq(_steps, [[[cell, BlockIds.BRICK, BlockIds.PAINTED_RED]]], "one undo step")
	assert_true(Session.request_build_tool(Session.TOOL_UNDO, [[cell, BlockIds.BRICK]]))
	assert_eq(world.get_block(cell), BlockIds.BRICK, "undo gives the brick back")
	assert_false(Session.request_build_tool(Session.TOOL_UNDO, [[cell, BlockIds.BRICK]]), "only once")
	world.cells[cell] = BlockIds.PAINTED_RED
	assert_false(Session.request_build_tool(Session.TOOL_UNDO, [[cell, BlockIds.DIAMOND]]),
		"an undo the host's log doesn't know changes nothing")
	assert_eq(world.get_block(cell), BlockIds.PAINTED_RED)


func test_paint_never_touches_a_block_with_a_job_or_the_air() -> void:
	var door := Vector3i(1, 10, 1)
	world.cells[door] = BlockIds.DOOR
	assert_false(Session.request_build_tool(Session.TOOL_PAINT, [[door, BlockIds.PAINTED_BLUE]]))
	assert_eq(world.get_block(door), BlockIds.DOOR)
	assert_has(_said, "Doors can't be painted!")
	assert_false(Session.request_build_tool(Session.TOOL_PAINT, [[Vector3i(1, 12, 1), BlockIds.PAINTED_BLUE]]))
	assert_eq(world.get_block(Vector3i(1, 12, 1)), BlockIds.AIR, "air is never painted into a block")
	assert_false(Session.request_build_tool(Session.TOOL_PAINT, [[Vector3i(1, 9, 1), BlockIds.BRICK]]),
		"paint only paints: never a brick")
	assert_eq(world.get_block(Vector3i(1, 9, 1)), BlockIds.GRASS)
	assert_false(Session.request_build_tool(Session.TOOL_PAINT, [[Vector3i(1, 9, 1), BlockIds.PAINTED_BLUE],
		[Vector3i(2, 9, 1), BlockIds.PAINTED_BLUE], [Vector3i(3, 9, 1), BlockIds.PAINTED_BLUE]]),
		"a tap and its mirror copy, never three")
	assert_eq(world.get_block(Vector3i(1, 9, 1)), BlockIds.GRASS)


## Survivor: paint is free (nothing taken, nothing given), undoing it too; a precious block is never painted; a
## painted block breaks into itself.
func test_survivor_paint_is_free_keeps_diamonds_and_breaks_into_itself() -> void:
	Game.mode = ModeRules.SURVIVOR
	var inv := Inventory.new()
	Session.set_inventory(me.peer_id, inv)
	var stone := Vector3i(3, 9, 0)
	world.cells[stone] = BlockIds.STONE
	assert_true(Session.request_build_tool(Session.TOOL_PAINT, [[stone, BlockIds.PAINTED_YELLOW]]))
	assert_eq(world.get_block(stone), BlockIds.PAINTED_YELLOW)
	assert_eq(inv.ids().size(), 0, "free: no stone in the bag, no paint taken")
	assert_true(Session.request_build_tool(Session.TOOL_UNDO, [[stone, BlockIds.STONE]]))
	assert_eq(world.get_block(stone), BlockIds.STONE)
	assert_eq(inv.ids().size(), 0, "undoing paint is free too (no stone needed)")
	var gem := Vector3i(4, 9, 0)
	world.cells[gem] = BlockIds.DIAMOND
	assert_false(Session.request_build_tool(Session.TOOL_PAINT, [[gem, BlockIds.PAINTED_RED]]))
	assert_eq(world.get_block(gem), BlockIds.DIAMOND, "never lost to paint")
	assert_has(_said, "Diamond is too precious to paint!")
	Session.request_build_tool(Session.TOOL_PAINT, [[stone, BlockIds.PAINTED_PINK]])
	assert_true(Session.request_set_block(stone, BlockIds.AIR), "a painted block breaks by hand")
	assert_eq(inv.count(BlockIds.PAINTED_PINK), 1, "into itself")
	assert_eq(inv.count(BlockIds.STONE), 0)
	assert_false(Session.request_build_tool(Session.TOOL_UNDO, [[stone, BlockIds.STONE]]),
		"the painted block is gone: its paint can't be undone into a free stone")
	assert_eq(world.get_block(stone), BlockIds.AIR)


func test_the_power_tools_are_sandbox_only() -> void:
	Game.mode = ModeRules.SURVIVOR
	Session.set_inventory(me.peer_id, Inventory.new())
	for kind: StringName in [Session.TOOL_LINE, Session.TOOL_FILL, Session.TOOL_PASTE]:
		assert_false(Session.request_build_tool(kind, [[Vector3i(1, 10, 1), BlockIds.STONE]]), String(kind))
	assert_eq(world.get_block(Vector3i(1, 10, 1)), BlockIds.AIR)
	assert_has(_said, Session.TOOLS_SANDBOX_ONLY)
	Game.mode = ModeRules.WAVE
	assert_false(Session.request_build_tool(Session.TOOL_PAINT, [[Vector3i(1, 9, 1), BlockIds.PAINTED_RED]]))
	assert_has(_said, ArenaRules.NO_BUILDING_WORDS, "Monster Wave's arena stays as it is")

# --- Line, fill, paste ---------------------------------------------------------------------------------------

func _written() -> bool:
	return not Session.tool_busy()


func _glass() -> int:
	var n := 0
	for c: Vector3i in world.cells:
		if world.cells[c] == BlockIds.GLASS:
			n += 1
	return n


func test_a_fill_of_4096_is_one_undo_step() -> void:
	var edits := PowerTools.fill_edits(Vector3i(-8, 10, -20), Vector3i(7, 25, -5), BlockIds.GLASS, world.get_block)
	assert_eq(edits.size(), 4096)
	assert_true(Session.request_build_tool(Session.TOOL_FILL, edits))
	await wait_until(_written, 5.0, "written")
	assert_eq(world.get_block(Vector3i(-8, 10, -20)), BlockIds.GLASS)
	assert_eq(world.get_block(Vector3i(7, 25, -5)), BlockIds.GLASS)
	assert_eq(_steps.size(), 1, "one undo step for the whole box")
	assert_eq((_steps[0] as Array).size(), 4096)
	assert_eq(interactor.undo_size(), 1)
	assert_true(interactor.undo(), "BlockInteractor undoes it through the host (more than a batch's 1,600)")
	await wait_until(_written, 5.0, "undone")
	assert_eq(world.get_block(Vector3i(-8, 10, -20)), BlockIds.AIR)
	assert_eq(world.get_block(Vector3i(7, 25, -5)), BlockIds.AIR)
	assert_eq(_glass(), 0, "every block of the box went")


## No frame pays for a whole big edit (phones are 3-5 times slower, and every changed cell is announced): the host
## writes TOOL_CHUNK cells at a time until the frame's budget is spent (here 0 ms: one chunk a frame), and a block
## someone puts in the box meanwhile stays.
func test_a_big_fill_is_written_a_chunk_at_a_time() -> void:
	var edits := PowerTools.fill_edits(Vector3i(-8, 10, -20), Vector3i(7, 25, -5), BlockIds.GLASS, world.get_block)
	Session.set_physics_process(false)   # the test steps it
	Session.tool_frame_ms = 0.0
	assert_eq(Session.host_build_tool(me.peer_id, Session.TOOL_FILL, edits), 4096, "accepted whole")
	assert_eq(_glass(), 0, "nothing written yet")
	assert_true(Session.tool_busy())
	Session._tool_tick()
	assert_eq(_glass(), Session.TOOL_CHUNK, "one chunk in a frame")
	world.cells[Vector3i(7, 25, -5)] = BlockIds.BRICK   # a friend's block, in the last layer
	var frames := 1
	while Session.tool_busy() and frames < 1000:
		Session._tool_tick()
		frames += 1
	Session.tool_frame_ms = Session.TOOL_FRAME_MS
	Session.set_physics_process(true)
	assert_eq(frames, 4096 / Session.TOOL_CHUNK)
	assert_eq(_glass(), 4095)
	assert_eq(world.get_block(Vector3i(7, 25, -5)), BlockIds.BRICK, "never written over")
	assert_eq(_steps.size(), 1, "one undo step, at the end")
	assert_eq((_steps[0] as Array).size(), 4095)


## With the frame's budget, a frame writes chunks until the time is spent.
func test_a_frame_writes_chunks_until_its_time_is_spent() -> void:
	var edits := PowerTools.fill_edits(Vector3i(-8, 10, -20), Vector3i(7, 25, -5), BlockIds.GLASS, world.get_block)
	Session.set_physics_process(false)
	Session.tool_frame_ms = 1000.0
	Session.host_build_tool(me.peer_id, Session.TOOL_FILL, edits)
	Session._tool_tick()
	Session.tool_frame_ms = Session.TOOL_FRAME_MS
	Session.set_physics_process(true)
	assert_false(Session.tool_busy(), "a second is plenty for 4,096 cells in this test world")
	assert_eq(_glass(), 4096)


func test_a_fill_over_the_cap_is_refused_whole() -> void:
	var edits := PowerTools.fill_edits(Vector3i(-8, 10, -20), Vector3i(7, 25, -5), BlockIds.GLASS, world.get_block)
	edits.append([Vector3i(0, 26, -5), BlockIds.GLASS])
	assert_false(Session.request_build_tool(Session.TOOL_FILL, edits), "4,097 blocks")
	assert_eq(world.get_block(Vector3i(-8, 10, -20)), BlockIds.AIR, "nothing at all")
	assert_has(_said, PowerTools.message(PowerTools.TOO_BIG))
	var line: Array = []
	for i in PowerTools.LINE_MAX + 1:
		line.append([Vector3i(i - 30, 10, 3), BlockIds.STONE])
	assert_false(Session.request_build_tool(Session.TOOL_LINE, line))
	assert_eq(world.get_block(Vector3i(-30, 10, 3)), BlockIds.AIR)
	assert_has(_said, PowerTools.message(PowerTools.TOO_LONG))


## Nothing is ever broken or replaced: only air and water take a block, never a body, never beyond reach.
func test_tools_only_fill_empty_cells_within_reach_and_never_a_body() -> void:
	world.cells[Vector3i(3, 10, 0)] = BlockIds.BRICK
	world.cells[Vector3i(4, 10, 0)] = BlockIds.WATER
	var n := Session.host_build_tool(me.peer_id, Session.TOOL_PASTE, [[Vector3i(3, 10, 0), BlockIds.STONE],
		[Vector3i(4, 10, 0), BlockIds.STONE], [Vector3i(0, 10, 0), BlockIds.STONE], [Vector3i(5, 10, 0), BlockIds.AIR],
		[Vector3i(0, 10, 60), BlockIds.STONE], [Vector3i(5, 11, 0), BlockIds.STONE]])
	assert_eq(n, 2)
	assert_eq(world.get_block(Vector3i(3, 10, 0)), BlockIds.BRICK, "a block stays")
	assert_eq(world.get_block(Vector3i(4, 10, 0)), BlockIds.STONE, "water is filled")
	assert_eq(world.get_block(Vector3i(0, 10, 0)), BlockIds.AIR, "never inside the player")
	assert_eq(world.get_block(Vector3i(0, 10, 60)), BlockIds.AIR, "too far from the eyes")
	assert_eq(world.get_block(Vector3i(5, 11, 0)), BlockIds.STONE)
	assert_false(Session.request_build_tool(Session.TOOL_FILL, [[Vector3i(1, 9, 1), BlockIds.STONE]]), "all ground")
	assert_has(_said, PowerTools.message(PowerTools.NOTHING), "the child hears why nothing happened")

# --- Guests --------------------------------------------------------------------------------------------------

func test_a_guests_requests_are_checked_where_the_host_sees_the_guest() -> void:
	var guest := _player(7, Vector3(100.5, 10.0, 0.5))
	assert_eq(Session.host_build_tool(7, Session.TOOL_FILL, [[Vector3i(101, 10, 3), BlockIds.STONE],
		[Vector3i(2, 10, 3), BlockIds.STONE]]), 1, "near the guest, not near the host")
	assert_eq(world.get_block(Vector3i(101, 10, 3)), BlockIds.STONE)
	assert_eq(world.get_block(Vector3i(2, 10, 3)), BlockIds.AIR)
	world.cells[Vector3i(1, 9, 0)] = BlockIds.STONE
	assert_eq(Session.host_build_tool(7, Session.TOOL_PAINT, [[Vector3i(1, 9, 0), BlockIds.PAINTED_RED]]), 0,
		"the host's own blocks are too far from the guest to paint")
	assert_eq(Session.host_build_tool(7, &"explode", [[Vector3i(101, 10, 4), BlockIds.STONE]]), 0, "no such tool")
	assert_eq(Session.host_build_tool(99, Session.TOOL_FILL, [[Vector3i(101, 10, 4), BlockIds.STONE]]), 0,
		"nobody plays as 99")
	assert_eq(Session.host_build_tool(7, Session.TOOL_FILL, [["x", 3], [Vector3i(101, 10, 5)], 7]), 0, "junk")
	assert_true(is_instance_valid(guest))
	_handle_rpc_errors()


## The host's log is per player: a guest's undo can't take away what the host built, nor turn a cell into
## something it never held.
func test_a_guest_can_only_undo_its_own_tool_steps() -> void:
	var guest := _player(7, Vector3(4.5, 10.0, 0.5))
	var mine := Vector3i(2, 10, 2)
	assert_true(Session.request_build_tool(Session.TOOL_LINE, [[mine, BlockIds.BRICK]]))
	assert_eq(Session.host_build_tool(7, Session.TOOL_UNDO, [[mine, BlockIds.AIR]]), 0, "not the guest's")
	assert_eq(world.get_block(mine), BlockIds.BRICK)
	var theirs := Vector3i(6, 10, 2)
	assert_eq(Session.host_build_tool(7, Session.TOOL_LINE, [[theirs, BlockIds.GLASS]]), 1)
	assert_eq(Session.host_build_tool(7, Session.TOOL_UNDO, [[theirs, BlockIds.DIAMOND]]), 0, "never held a diamond")
	assert_eq(Session.host_build_tool(7, Session.TOOL_UNDO, [[theirs, BlockIds.AIR]]), 1)
	assert_eq(world.get_block(theirs), BlockIds.AIR)
	assert_true(is_instance_valid(guest))
	_handle_rpc_errors()


## An undo that would put a block back where someone now stands waits (a new undo step) and works later.
func test_an_undo_waits_while_someone_stands_there() -> void:
	var cell := Vector3i(3, 10, 3)
	world.cells[cell] = BlockIds.WATER
	assert_true(Session.request_build_tool(Session.TOOL_FILL, [[cell, BlockIds.STONE]]))
	world.cells[cell] = BlockIds.STONE
	assert_true(Session.request_build_tool(Session.TOOL_PAINT, [[cell, BlockIds.PAINTED_TEAL]]))
	_steps.clear()
	var friend := _player(8, Vector3(3.5, 10.0, 3.5))
	assert_false(Session.request_build_tool(Session.TOOL_UNDO, [[cell, BlockIds.STONE]]), "the friend stands there")
	assert_eq(_steps, [[[cell, BlockIds.STONE, BlockIds.PAINTED_TEAL]]], "kept for later")
	friend.global_position = Vector3(20.5, 10.0, 20.5)
	assert_true(Session.request_build_tool(Session.TOOL_UNDO, [[cell, BlockIds.STONE]]))
	assert_eq(world.get_block(cell), BlockIds.STONE)


## The M3 review (M3 Task 19): the host's queue of tool edits had no cap per player, so a modified game could queue
## big edits without end. A player has at most TOOL_JOBS_PER_PLAYER unfinished edits; one more is refused kindly and
## goes through once they are written.
func test_a_player_has_at_most_two_unfinished_tool_edits() -> void:
	Session.set_physics_process(false)   # the test steps it
	Session.tool_frame_ms = 0.0
	var boxes: Array = []
	for i in 3:   # 128 cells each: bigger than TOOL_AT_ONCE, so each one waits in the queue
		boxes.append(PowerTools.fill_edits(Vector3i(-8, 10, -20 + i * 5), Vector3i(-1, 13, -17 + i * 5), BlockIds.GLASS,
			world.get_block))
	assert_gt(Session.host_build_tool(me.peer_id, Session.TOOL_FILL, boxes[0]), 0)
	assert_gt(Session.host_build_tool(me.peer_id, Session.TOOL_FILL, boxes[1]), 0)
	assert_eq(Session.host_build_tool(me.peer_id, Session.TOOL_FILL, boxes[2]), 0, "a third one waits")
	assert_true(_said.has(Session.TOOLS_STILL_BUILDING), str(_said))
	var frames := 0
	while Session.tool_busy() and frames < 1000:
		Session._tool_tick()
		frames += 1
	Session.tool_frame_ms = Session.TOOL_FRAME_MS
	Session.set_physics_process(true)
	assert_gt(Session.host_build_tool(me.peer_id, Session.TOOL_FILL, boxes[2]), 0, "once they are written")
