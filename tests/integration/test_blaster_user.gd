extends GutTest
## M3 Task 14b: the local player's blaster controls. With a blaster in the hand, ATTACK fires it (and keeps
## firing at its rate while held, a magazine then the reload), a tap fires where it points, the hand holds
## it; without ammo in Survivor nothing kicks and the host says what is missing. Other items are left to
## the WeaponUser.

var world: WorldService
var p: Player
var interactor: BlockInteractor
var _mode_before: StringName
var _now := [100000]
var _feedback: Array[String] = []


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	p = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = world
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3(0.5, 80, 0.5)
	interactor = p.get_node("BlockInteractor")
	interactor.weapons.blasters.clock = func() -> int: return _now[0]
	Session.blaster_reset()
	_feedback.clear()
	Session.magic_feedback.connect(_on_feedback)


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_feedback)
	Game.mode = _mode_before
	Session.blaster_reset()
	Session.survivor_reset()


func _on_feedback(text: String) -> void:
	_feedback.append(text)


func _hold(id: int) -> void:
	interactor.hotbar[0] = id
	interactor.select_slot(0)


func test_attack_with_a_blaster_fires_it() -> void:
	_hold(ItemIds.FOAM_BLASTER)
	watch_signals(Session)
	interactor.weapons.attack_pressed()
	assert_signal_emit_count(Session, "blast_requested", 1)
	assert_signal_not_emitted(Session, "attack_requested", "not a melee swing")
	assert_eq(interactor.weapons.blasters.shots_sent, 1)
	interactor.weapons.attack_released()
	assert_false(interactor.weapons.blasters.holding)
	assert_true(interactor.weapons.handles(ItemIds.FOAM_BLASTER), "a tap never places it as a block")


func test_holding_attack_keeps_firing_at_the_blasters_rate_then_reloads() -> void:
	_hold(ItemIds.FOAM_BLASTER)
	var b := interactor.weapons.blasters
	b.pressed()
	assert_eq(b.shots_sent, 1)
	b._process(0.016)
	assert_eq(b.shots_sent, 1, "not faster than its rate")
	var iv := int(BlasterRules.interval(ItemIds.FOAM_BLASTER) * 1000.0)
	for i in 12:
		_now[0] += iv
		b._process(0.016)
	assert_eq(b.shots_sent, BlasterRules.magazine(ItemIds.FOAM_BLASTER), "one magazine, then the reload")
	assert_gt(b.reload_left(ItemIds.FOAM_BLASTER), 0.0)
	_now[0] += int(BlasterRules.reload_time(ItemIds.FOAM_BLASTER) * 1000.0)
	b._process(0.016)
	assert_eq(b.shots_sent, BlasterRules.magazine(ItemIds.FOAM_BLASTER) + 1, "reloaded, it fires on")
	b.released()
	_now[0] += 5000
	b._process(0.016)
	assert_eq(b.shots_sent, BlasterRules.magazine(ItemIds.FOAM_BLASTER) + 1, "let go: it stops")


func test_another_slot_stops_the_firing() -> void:
	_hold(ItemIds.FOAM_BLASTER)
	var b := interactor.weapons.blasters
	b.pressed()
	interactor.hotbar[1] = BlockIds.DIRT
	interactor.select_slot(1)
	_now[0] += 1000
	b._process(0.016)
	assert_false(b.holding)
	assert_eq(b.shots_sent, 1)


func test_the_hand_holds_the_selected_blaster() -> void:
	_hold(ItemIds.CONFETTI_ROCKET)
	interactor.weapons._process(0.016)
	assert_eq(p.held_item, ItemIds.CONFETTI_ROCKET, "everyone sees it (held_item is synced)")


func test_a_tap_fires_where_it_points() -> void:
	_hold(ItemIds.PAINT_SPLATTER)
	watch_signals(Session)
	var center := get_viewport().get_visible_rect().size * 0.5
	assert_true(interactor.weapons.use_at_screen(center))
	assert_signal_emit_count(Session, "blast_requested", 1)


func test_the_snowball_is_lobbed_to_land_where_you_aim() -> void:
	var b := interactor.weapons.blasters
	var eye := p.eye_position()
	var target := eye + Vector3(0, -1.0, -20)
	var dir := b._aim(ItemIds.SNOWBALL_LAUNCHER, eye, target)
	assert_gt(dir.normalized().y, (target - eye).normalized().y + 0.05, "aimed above: it falls onto it")
	var foam := b._aim(ItemIds.FOAM_BLASTER, eye, target)
	assert_almost_eq(foam.normalized().dot((target - eye).normalized()), 1.0, 0.001, "darts fly straight")


func test_without_ammo_in_survivor_nothing_kicks_and_the_host_says_why() -> void:
	Game.mode = ModeRules.SURVIVOR
	var inv := Inventory.new()
	inv.add(ItemIds.FOAM_BLASTER, 1)
	Session.set_inventory(p.peer_id, inv)
	_hold(ItemIds.FOAM_BLASTER)
	watch_signals(Session)
	interactor.weapons.attack_pressed()
	assert_eq(interactor.weapons.blasters.shots_sent, 0)
	assert_signal_not_emitted(Session, "blast_requested")
	assert_eq(_feedback.size(), 1)
	assert_string_contains(_feedback[0], "Foam Darts")


func test_attack_without_a_blaster_is_left_to_the_weapons() -> void:
	_hold(BlockIds.DIRT)
	assert_false(interactor.weapons.blasters.pressed())
	assert_false(interactor.weapons.blasters.holding)
