extends GutTest
## M2 Task 7: tapping Tilly (within reach) opens the shop, whatever the player holds; a tap from far
## away does not.

var _player: Player
var _interactor: BlockInteractor
var _tilly: Trader


func before_each() -> void:
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	_player = load("res://entities/player/player.tscn").instantiate()
	_player.name = str(multiplayer.get_unique_id())
	_player.world = world
	add_child_autofree(_player)
	_player.viewer.free()
	_player.set_physics_process(false)
	_player.rig.process_mode = Node.PROCESS_MODE_DISABLED   # the test aims the camera
	_player._spawned = true
	_interactor = _player.get_node("BlockInteractor")
	_tilly = Trader.new()
	_tilly.setup({"pos": Vector3(0.5, 30, 0.5), "yaw": 0.0, "hint": false})
	add_child_autofree(_tilly)


func _look_at_tilly_from(feet: Vector3) -> Vector2:
	_player.global_position = feet
	_player.camera().look_at_from_position(_player.eye_position(), _tilly.global_position + Vector3(0, 1.1, 0))
	return _interactor.get_viewport().get_visible_rect().size * 0.5


func test_a_tap_on_tilly_opens_the_shop() -> void:
	var center := _look_at_tilly_from(Vector3(0.5, 30, -2.5))
	watch_signals(_interactor)
	assert_true(_interactor.place_at_screen(center))
	assert_signal_emitted_with_parameters(_interactor, "trader_tapped", [_tilly])


func test_even_with_a_sword_in_hand() -> void:
	_interactor.hotbar[0] = ItemIds.SWORD
	_interactor.select_slot(0)
	var center := _look_at_tilly_from(Vector3(0.5, 30, -2.5))
	watch_signals(_interactor)
	_interactor.place_at_screen(center)
	assert_signal_emitted(_interactor, "trader_tapped", "a tap is a trade, not a swing")


func test_a_tap_from_far_away_does_not() -> void:
	var center := _look_at_tilly_from(Vector3(0.5, 30, -12))
	watch_signals(_interactor)
	_interactor.place_at_screen(center)
	assert_signal_not_emitted(_interactor, "trader_tapped")
