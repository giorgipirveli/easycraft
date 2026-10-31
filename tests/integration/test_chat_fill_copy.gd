extends GutTest
## M3 Task 8 (and owner feedback #40's list): /fill builds a box of a block two blocks ahead (like /build), only in
## empty cells, as one tool request (one undo step); /copy copies the build you look at into the COPY tool (in
## your hand, ready to paste). Sandbox only.

var lines: Array = []
var _mode_before: StringName


## Stone up to y = 9, air above, plus `cells` (a brick build).
class BuildWorld:
	extends WorldService
	var cells := {}

	func get_block(p: Vector3i) -> int:
		return cells.get(p, BlockIds.STONE if p.y <= 9 else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		cells[pos] = id

	func is_editable(_pos: Vector3i) -> bool:
		return true


class FakeSandbox:
	extends Node3D
	var player: Player
	var world: WorldService


func before_each() -> void:
	lines.clear()
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	Session.chat_reset()
	Session.commands_enabled = true
	Session.tool_reset()
	Session.chat_received.connect(_on_line)


func after_each() -> void:
	Session.chat_received.disconnect(_on_line)
	Session.chat_reset()
	Session.register_world(null)
	Session.tool_reset()
	Game.mode = _mode_before


func _on_line(_from: String, text: String, _kind: StringName) -> void:
	lines.append(text)


func _last() -> String:
	return str(lines.back()) if not lines.is_empty() else ""


func _setup(at: Vector3) -> Array:
	var sandbox := FakeSandbox.new()
	add_child_autofree(sandbox)
	var world := BuildWorld.new()
	sandbox.add_child(world)
	Session.register_world(world)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = world
	sandbox.add_child(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = at
	p.rig.yaw = 0.0   # looking north (-Z)
	sandbox.player = p
	sandbox.world = world
	var runner := ChatCommandRunner.new()
	runner.sandbox = sandbox
	add_child_autofree(runner)
	return [runner, world, p]


func test_fill_builds_a_box_ahead_in_one_undo_step() -> void:
	var s := _setup(Vector3(0.5, 10.0, 0.5))
	var runner: ChatCommandRunner = s[0]
	var world: BuildWorld = s[1]
	var p: Player = s[2]
	world.cells[Vector3i(0, 10, -2)] = BlockIds.BRICK   # a block in the way stays
	runner.run("/fill glass 3 2 4")
	var glass := 0
	for c: Vector3i in world.cells:
		if world.cells[c] == BlockIds.GLASS:
			glass += 1
			assert_between(c.z, -5, -2, "two blocks ahead, reaching away")
			assert_between(c.x, -1, 1, "centred")
			assert_between(c.y, 10, 11)
	assert_eq(glass, 23, "3 x 2 x 4, less the brick")
	assert_eq(world.cells[Vector3i(0, 10, -2)], BlockIds.BRICK)
	assert_eq((p.get_node("BlockInteractor") as BlockInteractor).undo_size(), 1, "one undo step")
	assert_string_contains(_last(), "UNDO")


func test_copy_puts_the_build_you_look_at_in_the_copy_tool() -> void:
	var s := _setup(Vector3(0.5, 10.0, 0.5))
	var runner: ChatCommandRunner = s[0]
	var world: BuildWorld = s[1]
	var p: Player = s[2]
	for y in 3:
		world.cells[Vector3i(0, 10 + y, -3)] = BlockIds.BRICK
	world.cells[Vector3i(1, 12, -3)] = BlockIds.PAINTED_RED
	runner.copy_target = func() -> Vector3i: return Vector3i(0, 11, -3)
	runner.run("/copy")
	var interactor := p.get_node("BlockInteractor") as BlockInteractor
	assert_eq(interactor.selected_block(), ItemIds.COPY_TOOL, "COPY in the hand")
	assert_eq(interactor.tools.clipboard.size(), 4, "the whole build, not the ground")
	assert_string_contains(_last(), "Copied 4 blocks")
	runner.copy_target = func() -> Vector3i: return Vector3i(5, 9, 5)
	runner.run("/copy")
	assert_eq(_last(), ChatCommandRunner.COPY_LOOK)


func test_both_are_sandbox_only() -> void:
	var s := _setup(Vector3(0.5, 10.0, 0.5))
	var runner: ChatCommandRunner = s[0]
	Game.mode = ModeRules.SURVIVOR
	runner.run("/fill stone")
	assert_eq(_last(), ChatCommands.SANDBOX_ONLY_MESSAGE)
	runner.run("/copy")
	assert_eq(_last(), ChatCommands.SANDBOX_ONLY_MESSAGE)
