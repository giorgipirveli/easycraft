extends GutTest
## The host's side of M2 Task 6 (solo play: this game is the host): drinking potions (Survivor takes
## one from the inventory, Sandbox is unlimited), spear throws checked like attacks, and shields
## taking their share of a blow from the front (ruling 5).

var _mode_before: StringName
var _feedback: Array[String] = []


func before_each() -> void:
	_mode_before = Game.mode
	_feedback.clear()
	Session.magic_feedback.connect(_on_feedback)
	Session._last_attack.erase(multiplayer.get_unique_id())


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_feedback)
	Game.mode = _mode_before
	Session.survivor_reset()
	Session._last_attack.erase(multiplayer.get_unique_id())


func _on_feedback(text: String) -> void:
	_feedback.append(text)


## This game's own player at the origin, facing -Z (avatar yaw 0).
func _player() -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3.ZERO
	p.avatar.rotation.y = 0.0
	return p


# --- Potions ---

func test_sandbox_potions_are_unlimited() -> void:
	Game.mode = ModeRules.SANDBOX
	var p := _player()
	watch_signals(Session)
	Session.request_drink(ItemIds.POTION_JUMP)
	assert_true(p.potions.is_active(ItemIds.POTION_JUMP))
	assert_signal_emitted_with_parameters(Session, "potion_started", [p.peer_id, ItemIds.POTION_JUMP])
	Session.request_drink(ItemIds.POTION_JUMP)
	assert_eq(_feedback.size(), 1)
	assert_string_contains(_feedback[0], "still working", "a second tap wastes nothing")


func test_survivor_drinks_one_from_the_inventory() -> void:
	Game.mode = ModeRules.SURVIVOR
	var p := _player()
	var inv := Inventory.new()
	inv.add(ItemIds.POTION_SPEED, 2)
	Session.set_inventory(p.peer_id, inv)
	Session.request_drink(ItemIds.POTION_SPEED)
	assert_true(p.potions.is_active(ItemIds.POTION_SPEED))
	assert_eq(inv.count(ItemIds.POTION_SPEED), 1, "one used")
	p.potions.tick(61.0)
	Session.request_drink(ItemIds.POTION_SPEED)
	assert_eq(inv.count(ItemIds.POTION_SPEED), 0)
	p.potions.tick(61.0)
	Session.request_drink(ItemIds.POTION_SPEED)
	assert_false(p.potions.is_active(ItemIds.POTION_SPEED), "none left")
	assert_string_contains(_feedback[-1], "no Speed Potion")


func test_things_that_are_not_potions_are_ignored() -> void:
	var p := _player()
	Session.request_drink(ItemIds.SWORD)
	Session.request_drink(BlockIds.DIRT)
	assert_eq(p.potions.active_ids(), [])
	assert_eq(_feedback, [] as Array[String])


# --- Spear throws ---

func test_the_host_checks_spear_throws_like_attacks() -> void:
	var p := _player()
	watch_signals(Session)
	Session.request_spear_throw(ItemIds.SPEAR_IRON, Vector3(0, 0, -2))
	Session.request_spear_throw(ItemIds.SPEAR_IRON, Vector3(0, 0, -2))
	assert_signal_emit_count(Session, "spear_throw_requested", 1, "the cooldown")
	assert_signal_emitted_with_parameters(Session, "spear_throw_requested", [p.peer_id, ItemIds.SPEAR_IRON, Vector3(0, 0, -1)])
	Session._last_attack.erase(p.peer_id)
	Session.request_spear_throw(ItemIds.SWORD, Vector3(0, 0, -1))
	Session.request_spear_throw(ItemIds.SPEAR, Vector3.ZERO)
	assert_signal_emit_count(Session, "spear_throw_requested", 1, "only spears, only with an aim")


# --- Shields ---

func test_a_carried_shield_blocks_a_blow_from_the_front_in_sandbox() -> void:
	Game.mode = ModeRules.SANDBOX
	var p := _player()
	p.carried_shield = ItemIds.SHIELD_IRON          # 55 %
	watch_signals(Session)
	Session.hurt_player(p.peer_id, 4, Vector3(0, 1, -3))
	assert_eq(p.health.hp, Health.MAX_HP - 1, "4 x 0.45 = 1.8: 1 now, 0.8 carried")
	assert_signal_emitted(Session, "shield_blocked")
	Session.hurt_player(p.peer_id, 4, Vector3(0, 1, -3))
	assert_eq(p.health.hp, Health.MAX_HP - 3, "0.8 + 1.8 = 2.6: 2 more")


func test_a_shield_never_blocks_from_behind() -> void:
	Game.mode = ModeRules.SANDBOX
	var p := _player()
	p.carried_shield = ItemIds.SHIELD_COSMIC
	Session.hurt_player(p.peer_id, 4, Vector3(0, 1, 3))
	assert_eq(p.health.hp, Health.MAX_HP - 4)


func test_survivor_uses_the_best_shield_in_the_inventory() -> void:
	Game.mode = ModeRules.SURVIVOR
	var p := _player()
	p.carried_shield = ItemIds.SHIELD_COSMIC        # the hotbar does not count in Survivor
	var inv := Inventory.new()
	inv.add(ItemIds.SHIELD_WOOD, 1)
	inv.add(ItemIds.SHIELD_CRYSTAL, 1)
	Session.set_inventory(p.peer_id, inv)
	assert_eq(Session.best_shield_of(p.peer_id), ItemIds.SHIELD_CRYSTAL)
	Session.hurt_player(p.peer_id, 10, Vector3(1, 1, -3))
	assert_eq(p.health.hp, Health.MAX_HP - 3, "crystal blocks 70 %")


func test_no_shield_takes_the_whole_blow() -> void:
	Game.mode = ModeRules.SURVIVOR
	var p := _player()
	watch_signals(Session)
	Session.hurt_player(p.peer_id, 3, Vector3(0, 1, -3))
	assert_eq(p.health.hp, Health.MAX_HP - 3)
	assert_signal_not_emitted(Session, "shield_blocked")


# --- What a LAN guest's game hears from the host ---

func test_a_guest_starts_the_potion_the_host_announced() -> void:
	var p := _player()
	watch_signals(Session)
	Session._rpc_potion(p.peer_id, ItemIds.POTION_INVIS, 30.0)
	assert_true(p.is_invisible())
	assert_signal_emitted_with_parameters(Session, "potion_started", [p.peer_id, ItemIds.POTION_INVIS])
	Session._rpc_potion(p.peer_id, ItemIds.SWORD, 30.0)
	Session._rpc_potion(424242, ItemIds.POTION_SPEED, 30.0)
	assert_eq(p.potions.active_ids(), [ItemIds.POTION_INVIS] as Array[int], "junk is ignored")


func test_a_bad_shield_share_from_the_network_is_ignored() -> void:
	var p := _player()
	watch_signals(Session)
	Session._rpc_shield_fx(p.peer_id, NAN)
	assert_signal_not_emitted(Session, "shield_blocked")
	Session._rpc_shield_fx(p.peer_id, 7.0)
	assert_signal_emitted_with_parameters(Session, "shield_blocked", [p.peer_id, 1.0])


# --- Review fixes ---

## Tiers raised the stakes (a cosmic mace hits 27): in Survivor the host only accepts attacks with a
## weapon the player owns. Sandbox has everything.
func test_survivor_attacks_need_the_weapon_in_the_inventory() -> void:
	Game.mode = ModeRules.SURVIVOR
	var p := _player()
	var inv := Inventory.new()
	inv.add(ItemIds.SWORD, 1)
	Session.set_inventory(p.peer_id, inv)
	assert_false(Session.accept_attack(p.peer_id, ItemIds.MACE_COSMIC, Vector3.FORWARD, 1.0, 50000), "not owned")
	assert_true(Session.accept_attack(p.peer_id, ItemIds.SWORD, Vector3.FORWARD, 1.0, 50000))
	watch_signals(Session)
	Session._last_attack.erase(p.peer_id)
	Session.request_spear_throw(ItemIds.SPEAR_COSMIC, Vector3(0, 0, -1))
	assert_signal_not_emitted(Session, "spear_throw_requested", "no spear owned")
	Game.mode = ModeRules.SANDBOX
	Session._last_attack.erase(p.peer_id)
	assert_true(Session.accept_attack(p.peer_id, ItemIds.MACE_COSMIC, Vector3.FORWARD, 1.0, 60000), "Sandbox has everything")


## A guest's timer runs a little behind the host's: when the host lets the player drink again, the
## guest's game must follow the host even if its own copy of the potion is still running.
func test_a_guest_follows_the_hosts_timer() -> void:
	var p := _player()
	p.drink(ItemIds.POTION_SPEED)
	p.potions.tick(59.5)
	Session._rpc_potion(p.peer_id, ItemIds.POTION_SPEED, 60.0)
	assert_almost_eq(p.potions.time_left(ItemIds.POTION_SPEED), 60.0, 0.001, "the host's word wins")
	Session._rpc_potion(p.peer_id, ItemIds.POTION_JUMP, 12.5)
	assert_almost_eq(p.potions.time_left(ItemIds.POTION_JUMP), 12.5, 0.001, "a late joiner gets the seconds left")
	Session._rpc_potion(p.peer_id, ItemIds.POTION_INVIS, NAN)
	assert_almost_eq(p.potions.time_left(ItemIds.POTION_INVIS), 30.0, 0.001, "a broken number: the full time")


func test_the_host_tells_a_late_joiner_which_potions_are_working() -> void:
	var p := _player()
	p.drink(ItemIds.POTION_INVIS)
	p.potions.tick(10.0)
	var sent := Session.working_potions()
	assert_eq(sent.size(), 1)
	assert_eq(sent[0][0], p.peer_id)
	assert_eq(sent[0][1], ItemIds.POTION_INVIS)
	assert_almost_eq(float(sent[0][2]), 20.0, 0.001)
