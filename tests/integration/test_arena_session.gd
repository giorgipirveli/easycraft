extends GutTest
## Monster Wave on the host (spec §12.20): nothing is built or broken in the arena (a child can't wall
## themselves in, and the arena stays the same for every run) — single edits, batches and bot friends' builds
## are refused, with kind words; flying is refused too.

class BoxWorld:
	extends WorldService

	var blocks := {}

	func get_block(pos: Vector3i) -> int:
		return blocks.get(pos, BlockIds.GRASS if pos.y < 10 else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		blocks[pos] = id

	func is_editable(_pos: Vector3i) -> bool:
		return true


var _world: BoxWorld
var _world_before: WorldService
var _mode_before: StringName
var _me: Player
var _said: Array[String] = []


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.WAVE
	_world_before = Session.world
	_world = BoxWorld.new()
	autofree(_world)
	Session.world = _world
	_said.clear()
	Session.magic_feedback.connect(_on_said)
	_me = load("res://entities/player/player.tscn").instantiate()
	_me.name = str(multiplayer.get_unique_id())
	_me.world = _world
	add_child_autofree(_me)
	_me.viewer.free()
	_me.set_physics_process(false)
	_me.global_position = Vector3(0.5, 10, 0.5)
	Session.set_inventory(_me.peer_id, ArenaRules.kit(1))


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_said)
	Session.world = _world_before
	Game.mode = _mode_before
	Session.survivor_reset()


func _on_said(text: String) -> void:
	_said.append(text)


func test_nothing_is_built_or_broken_in_the_arena() -> void:
	assert_false(Session.request_set_block(Vector3i(2, 10, 0), BlockIds.STONE))
	assert_false(_world.blocks.has(Vector3i(2, 10, 0)))
	assert_has(_said, ArenaRules.NO_BUILDING_WORDS)
	assert_false(Session.request_set_block(Vector3i(2, 9, 0), BlockIds.AIR), "no breaking either")
	assert_eq(_world.get_block(Vector3i(2, 9, 0)), BlockIds.GRASS)
	assert_false(Session.request_set_blocks([[Vector3i(3, 10, 0), BlockIds.STONE], [Vector3i(4, 10, 0), BlockIds.STONE]]))
	assert_true(_world.blocks.is_empty())


func test_bot_friends_build_nothing_in_the_arena() -> void:
	assert_eq(Session.bot_set_blocks([[Vector3i(3, 10, 3), BlockIds.PLANKS]], Vector3(0.5, 11.5, 0.5)), 0)
	assert_true(_world.blocks.is_empty())


func test_no_flying_in_the_arena() -> void:
	_me.set_physics_mode(PhysicsMode.Mode.FLY)
	assert_eq(_me.physics_mode, PhysicsMode.Mode.NORMAL)
	assert_has(_said, ArenaRules.NO_FLYING_WORDS)


func test_the_sandbox_still_builds() -> void:
	Game.mode = ModeRules.SANDBOX
	assert_true(Session.request_set_block(Vector3i(2, 10, 0), BlockIds.STONE))
	assert_eq(_world.get_block(Vector3i(2, 10, 0)), BlockIds.STONE)
