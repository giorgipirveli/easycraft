extends GutTest
## Survivor games through the host (spec §12.18): Tilly sells Build to Survive's building blocks 8 a gold;
## a guest plays the host's game.

var _gold_before := 0
var _mode_before: StringName
var _game_before: StringName
var _player: Player
var _tilly: Node3D


func before_each() -> void:
	_gold_before = Profile.data.survivor_gold
	_mode_before = Game.mode
	_game_before = Game.survivor_game
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 200
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	_player = load("res://entities/player/player.tscn").instantiate()
	_player.name = str(multiplayer.get_unique_id())
	_player.world = world
	add_child_autofree(_player)
	_player.viewer.free()
	_player.set_physics_process(false)
	_tilly = Node3D.new()
	_tilly.add_to_group(&"traders")
	add_child_autofree(_tilly)
	_tilly.global_position = Vector3(10.5, 30, 4.5)
	_player.global_position = _tilly.global_position + Vector3(0, 0, -3)
	Session.set_inventory(_player.peer_id, Inventory.new())


func after_each() -> void:
	Profile.data.survivor_gold = _gold_before
	Game.mode = _mode_before
	Game.survivor_game = _game_before
	Session.survivor_reset()


func test_build_to_survive_blocks_come_eight_a_gold() -> void:
	Game.survivor_game = SurvivorGames.BUILD
	var r := Session.host_trade(_player.peer_id, true, BlockIds.PLANKS, 1)
	assert_true(r.ok)
	assert_eq(Session.inventory_of(_player.peer_id).count(BlockIds.PLANKS), 8)
	assert_eq(Profile.data.survivor_gold, 199)


func test_classic_prices_as_before() -> void:
	Game.survivor_game = SurvivorGames.CLASSIC
	Session.host_trade(_player.peer_id, true, ItemIds.SWORD_IRON, 1)
	assert_eq(Profile.data.survivor_gold, 80)


func test_a_guest_takes_the_hosts_game() -> void:
	Game.survivor_game = SurvivorGames.CLASSIC
	Session._rpc_sgc_game("build")
	assert_eq(Game.survivor_game, SurvivorGames.BUILD)
	Session._rpc_sgc_game("nonsense")
	assert_eq(Game.survivor_game, SurvivorGames.CLASSIC, "anything unknown is Classic")
