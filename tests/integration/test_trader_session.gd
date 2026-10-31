extends GutTest
## M2 Task 7: the host checks every trade with Tilly (Survivor only, the player near her, then gold,
## room and what is for sale), moves the gold and the blocks, and tells the player; and it charges
## Survivor flyers 10 gold a minute, landing them gently when the gold runs out. Owner #78: flying needs an invented
## flying machine; the child here invented the plane (its fuel is the 10 gold a minute).

var _gold_before := 0
var _mode_before: StringName
var _player: Player
var _tilly: Node3D
var _done: Array = []
var _inventories: Array = []
var _toasts: Array[String] = []
var _inventions_before: InventionData


func before_each() -> void:
	_gold_before = Profile.data.survivor_gold
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 30
	_inventions_before = Profile.data.inventions
	Profile.data.inventions = InventionData.invented_to(InventionLine.PLANE)
	_done.clear()
	_inventories.clear()
	_toasts.clear()
	Session.trade_done.connect(_on_done)
	Session.trade_inventory_received.connect(_on_inventory)
	Session.magic_feedback.connect(_on_toast)
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	_player = load("res://entities/player/player.tscn").instantiate()
	_player.name = str(multiplayer.get_unique_id())
	_player.world = world
	add_child_autofree(_player)
	_player.viewer.free()
	_player.set_physics_process(false)   # the test moves it
	_tilly = Node3D.new()                # the host only needs where she stands
	_tilly.add_to_group(&"traders")
	add_child_autofree(_tilly)
	_tilly.global_position = Vector3(10.5, 30, 4.5)
	_player.global_position = _tilly.global_position + Vector3(0, 0, -3)
	Session.set_inventory(_player.peer_id, Inventory.new())


func after_each() -> void:
	Session.trade_done.disconnect(_on_done)
	Session.trade_inventory_received.disconnect(_on_inventory)
	Session.magic_feedback.disconnect(_on_toast)
	Profile.data.survivor_gold = _gold_before
	Profile.data.inventions = _inventions_before
	Game.mode = _mode_before
	Session.survivor_reset()
	Session.fly_reset()


func _on_done(ok: bool, text: String, id: int, count: int, gold: int) -> void:
	_done.append([ok, text, id, count, gold])


func _on_inventory(items: Array) -> void:
	_inventories.append(items)


func _on_toast(text: String) -> void:
	_toasts.append(text)


func _me() -> int:
	return _player.peer_id


func test_buying_near_tilly_takes_gold_and_gives_the_thing() -> void:
	Session.request_trade(true, BlockIds.LANTERN, 1)
	assert_eq(Profile.data.survivor_gold, 25)
	assert_eq(Session.inventory_of(_me()).count(BlockIds.LANTERN), 1)
	assert_eq(_done, [[true, "You got a Lantern!", BlockIds.LANTERN, 1, 5]])
	assert_eq(_inventories.back(), [[BlockIds.LANTERN, 1]], "the player hears what they own now")


func test_selling_gives_gold_and_takes_the_blocks() -> void:
	Session.inventory_of(_me()).add(BlockIds.DIAMOND, 3)
	Session.request_trade(false, BlockIds.DIAMOND, 2)
	assert_eq(Profile.data.survivor_gold, 70)
	assert_eq(Session.inventory_of(_me()).count(BlockIds.DIAMOND), 1)
	assert_eq(_done, [[true, "Sold! +40 gold", BlockIds.DIAMOND, 2, 40]])


func test_too_far_from_tilly_is_refused() -> void:
	_player.global_position = _tilly.global_position + Vector3(0, 0, -(TraderRules.HOST_REACH + 1))
	Session.request_trade(true, BlockIds.LANTERN, 1)
	assert_eq(Profile.data.survivor_gold, 30)
	assert_false(Session.inventory_of(_me()).has(BlockIds.LANTERN))
	assert_eq(_done, [[false, ShopRules.message("too_far"), BlockIds.LANTERN, 0, 0]])


func test_a_world_without_tilly_has_no_trades() -> void:
	_tilly.remove_from_group(&"traders")
	Session.request_trade(true, BlockIds.LANTERN, 1)
	assert_eq(Profile.data.survivor_gold, 30)
	assert_false(_done[0][0])


func test_not_enough_gold_is_refused() -> void:
	Profile.data.survivor_gold = 19
	Session.request_trade(true, BlockIds.BED, 1)
	assert_eq(Profile.data.survivor_gold, 19)
	assert_false(Session.inventory_of(_me()).has(BlockIds.BED))
	assert_eq(_done, [[false, ShopRules.message("gold"), BlockIds.BED, 0, 0]])


func test_selling_what_you_do_not_have_is_refused() -> void:
	Session.request_trade(false, BlockIds.GOLD, 5)
	assert_eq(Profile.data.survivor_gold, 30)
	assert_eq(_done, [[false, ShopRules.message("none"), BlockIds.GOLD, 0, 0]])


func test_sandbox_has_no_trades() -> void:
	Game.mode = ModeRules.SANDBOX
	Session.request_trade(true, BlockIds.LANTERN, 1)
	assert_false(Session.inventory_of(_me()).has(BlockIds.LANTERN))
	assert_eq(_done, [[false, ShopRules.message("survivor_only"), BlockIds.LANTERN, 0, 0]])


func test_opening_the_shop_sends_the_players_things() -> void:
	Session.inventory_of(_me()).add(BlockIds.COAL, 7)
	Session.request_shop()
	assert_eq(_inventories, [[[BlockIds.COAL, 7]]])


func test_a_guest_without_a_body_can_not_trade() -> void:
	var r := Session.host_trade(424242, true, BlockIds.LANTERN, 1)
	assert_false(r.ok)
	assert_eq(r.error, "too_far")


# --- Flying costs gold ---

func test_flying_in_survivor_costs_a_gold_every_six_seconds() -> void:
	_player._spawned = true
	_player.set_physics_mode(PhysicsMode.Mode.FLY)
	Session.fly_tick(0.016)
	assert_eq(Profile.data.survivor_gold, 29, "the first 6 s are paid at take-off")
	for i in 60 * 6:
		Session.fly_tick(1.0 / 60.0)
	assert_eq(Profile.data.survivor_gold, 28)
	_player.set_physics_mode(PhysicsMode.Mode.NORMAL)
	Session.fly_tick(60.0)
	assert_eq(Profile.data.survivor_gold, 28, "walking is free")


func test_out_of_gold_the_flyer_lands_gently() -> void:
	Profile.data.survivor_gold = 1
	_player._spawned = true
	_player.set_physics_mode(PhysicsMode.Mode.FLY)
	Session.fly_tick(0.016)
	assert_eq(Profile.data.survivor_gold, 0)
	assert_eq(_player.physics_mode, PhysicsMode.Mode.FLY, "still paid for")
	Session.fly_tick(6.0)
	assert_eq(_player.physics_mode, PhysicsMode.Mode.NORMAL, "down to walking")
	assert_true(_player.soft_falling(), "drifting down, not dropping")
	assert_has(_toasts, FlyCost.LANDED_MESSAGE)
	assert_eq(Profile.data.survivor_gold, 0, "never negative")


func test_with_no_gold_fly_is_refused() -> void:
	Profile.data.survivor_gold = 0
	_player.cycle_physics_mode()
	assert_eq(_player.physics_mode, PhysicsMode.Mode.NORMAL)
	assert_has(_toasts, FlyCost.REFUSED_MESSAGE)


func test_sandbox_flies_free() -> void:
	Game.mode = ModeRules.SANDBOX
	Profile.data.survivor_gold = 0
	_player._spawned = true
	_player.set_physics_mode(PhysicsMode.Mode.FLY)
	assert_eq(_player.physics_mode, PhysicsMode.Mode.FLY)
	for i in 10:
		Session.fly_tick(6.0)
	assert_eq(_player.physics_mode, PhysicsMode.Mode.FLY)
	assert_eq(Profile.data.survivor_gold, 0)
	assert_eq(_toasts, [] as Array[String])
