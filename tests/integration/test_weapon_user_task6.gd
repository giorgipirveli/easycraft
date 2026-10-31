extends GutTest
## The local player's controls for M2 Task 6: a tap on a potion's hotbar slot drinks it (picking one
## from the palette does not), shields are held and carried (Sandbox: the best one in the hotbar),
## and the spear thrusts on a tap of ATTACK and is thrown when ATTACK is held and let go.

var world: WorldService
var p: Player
var interactor: BlockInteractor
var _mode_before: StringName


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
	Session._last_attack.erase(p.peer_id)


func after_each() -> void:
	Game.mode = _mode_before
	Session._last_attack.erase(multiplayer.get_unique_id())


# --- Potions from the hotbar ---

func test_tapping_a_potion_slot_drinks_it() -> void:
	interactor.hotbar[4] = ItemIds.POTION_SPEED
	interactor.tap_slot(4)
	assert_eq(interactor.selected_slot, 4)
	assert_true(p.potions.is_active(ItemIds.POTION_SPEED))


func test_tapping_a_block_slot_only_selects_it() -> void:
	interactor.tap_slot(1)
	assert_eq(interactor.selected_slot, 1)
	assert_eq(p.potions.active_ids(), [])


func test_picking_a_potion_from_the_palette_does_not_drink_it() -> void:
	interactor.set_slot_block(3, ItemIds.POTION_JUMP)
	assert_eq(interactor.hotbar[3], ItemIds.POTION_JUMP)
	assert_false(p.potions.is_active(ItemIds.POTION_JUMP))


func test_the_hotbar_slot_button_drinks_too() -> void:
	var bar := Hotbar.new()
	add_child_autofree(bar)
	bar.setup(interactor)
	interactor.hotbar[2] = ItemIds.POTION_INVIS
	(bar.get_child(2) as TouchButton).pressed.emit()
	assert_true(p.is_invisible())


# --- Shields ---

func test_a_selected_shield_is_held_and_the_best_one_in_the_hotbar_is_carried() -> void:
	interactor.hotbar[0] = ItemIds.SHIELD_STONE
	interactor.hotbar[1] = ItemIds.SHIELD_CRYSTAL
	interactor.select_slot(0)
	interactor.weapons._process(0.016)
	assert_eq(p.held_item, ItemIds.SHIELD_STONE, "in the hand")
	assert_eq(p.carried_shield, ItemIds.SHIELD_CRYSTAL, "the best one protects")
	assert_true(interactor.weapons.handles(ItemIds.SHIELD_STONE), "a tap never tries to place it as a block")
	assert_true(interactor.weapons.handles(ItemIds.POTION_SPEED))
	interactor.hotbar[1] = BlockIds.DIRT
	interactor.hotbar[0] = BlockIds.DIRT
	interactor.weapons._process(0.016)
	assert_eq(p.carried_shield, 0)


# --- Spear ---

func test_a_quick_attack_thrusts_the_spear() -> void:
	interactor.hotbar[0] = ItemIds.SPEAR_IRON
	interactor.select_slot(0)
	watch_signals(Session)
	interactor.weapons.attack_pressed()
	assert_true(interactor.weapons.drawing, "holding: the crosshair shows")
	interactor.weapons.attack_released()
	assert_signal_emitted(Session, "attack_requested")
	assert_signal_not_emitted(Session, "spear_throw_requested")


func test_holding_attack_and_letting_go_throws_the_spear() -> void:
	interactor.hotbar[0] = ItemIds.SPEAR_IRON
	interactor.select_slot(0)
	watch_signals(Session)
	interactor.weapons.attack_pressed()
	interactor.weapons._process(WeaponRules.SPEAR_THROW_HOLD + 0.05)
	interactor.weapons.attack_released()
	assert_signal_emitted(Session, "spear_throw_requested")
	assert_signal_not_emitted(Session, "attack_requested")


func test_no_spear_attack_while_it_is_out_there() -> void:
	interactor.hotbar[0] = ItemIds.SPEAR
	interactor.select_slot(0)
	var spear := ThrownSpear.new()
	spear.setup({"id": "SpearT", "origin": Vector3(0, 70, 0), "velocity": Vector3.ZERO, "shooter": p.peer_id})
	spear.set_physics_process(false)
	add_child_autofree(spear)
	var feedback: Array = []
	var listen := func(text: String) -> void: feedback.append(text)
	Session.magic_feedback.connect(listen)
	watch_signals(Session)
	assert_false(interactor.weapons.attack_towards(ItemIds.SPEAR, p.eye_position() + Vector3(0, 0, -2), 1.0))
	Session.magic_feedback.disconnect(listen)
	assert_signal_not_emitted(Session, "attack_requested")
	assert_eq(feedback.size(), 1)
	assert_string_contains(str(feedback[0]), "spear")
