extends GutTest
## M2 Task 5 (spec §12.5): the player's side of stealth — crouching (half speed, a lower body and
## camera, synced), how visible the player is, and hiding inside a barrel or closet (the body and the
## camera go in, the avatar vanishes for everyone, moving asks to come out).

const CELL := Vector3i(4, 10, 0)


func after_each() -> void:
	for action: StringName in [&"move_forward", &"crouch", &"jump"]:
		Input.action_release(action)


func _player(peer: int = 0) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer if peer != 0 else multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)   # no world here: the test steps the body itself
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3(2.5, 10, 0.5)
	return p


# --- Crouching ---

func test_crouching_halves_walking_speed() -> void:
	var p := _player()
	p._move_normal(1.0, Vector3(1, 0, 0))
	var walking := p.velocity.x
	assert_almost_eq(walking, Player.WALK_SPEED, 0.001)
	p.velocity = Vector3.ZERO
	p.set_crouching(true)
	p._move_normal(1.0, Vector3(1, 0, 0))
	assert_almost_eq(p.velocity.x, walking * 0.5, 0.001, "half speed")


func test_c_toggles_crouching() -> void:
	var p := _player()
	assert_true(InputMap.has_action(&"crouch"), "the C key (tools/setup_input_map.gd)")
	var c := false
	for e in InputMap.action_get_events(&"crouch"):
		c = c or (e is InputEventKey and (e as InputEventKey).physical_keycode == KEY_C)
	assert_true(c, "bound to C")
	p._stealth_input(true)
	assert_true(p.crouching)
	p._stealth_input(true)
	assert_false(p.crouching, "again: stand up")


func test_crouching_lowers_the_body_the_camera_and_the_eyes() -> void:
	var p := _player()
	var eyes := p.stealth_eye().y
	p.set_crouching(true)
	p._process(0.016)
	assert_lt(p.avatar.scale.y, 0.9, "a lower body")
	assert_almost_eq(p.avatar.scale.x, 1.0, 0.001)
	assert_lt(p.rig.height_factor, 0.7, "a lower camera")
	assert_lt(p.stealth_eye().y, eyes - 0.5, "lower eyes: a low wall hides them")
	p.set_crouching(false)
	p._process(0.016)
	assert_almost_eq(p.avatar.scale.y, 1.0, 0.001)
	assert_eq(p.rig.height_factor, 1.0)


func test_crouching_is_synced_on_change() -> void:
	var p := _player()
	var cfg := (p.get_node("Sync") as MultiplayerSynchronizer).replication_config
	var path := NodePath(".:crouching")
	assert_true(cfg.has_property(path))
	assert_eq(cfg.property_get_replication_mode(path), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	assert_true(cfg.property_get_spawn(path))


func test_a_remote_player_who_crouches_looks_crouched() -> void:
	var p := _player(7)
	p.crouching = true            # what the synchronizer writes
	p._process(0.016)
	assert_lt(p.avatar.scale.y, 0.9)


func test_no_crouching_while_flying() -> void:
	var p := _player()
	p.set_crouching(true)
	p.set_physics_mode(PhysicsMode.Mode.FLY)
	p._stealth_input(false)
	assert_false(p.crouching, "taking off stands up")
	p.set_crouching(true)
	assert_false(p.crouching)


# --- Visibility ---

func test_visibility_follows_the_light_crouching_bushes_hiding_and_the_potion() -> void:
	var p := _player()
	assert_eq(p.stealth_visibility(), 1.0, "daylight")
	p.stealth_light = StealthRules.NIGHT
	assert_eq(p.stealth_visibility(), 0.45)
	p.set_crouching(true)
	assert_almost_eq(p.stealth_visibility(), 0.225, 0.0001)
	p.stealth_in_bush = true
	assert_eq(p.stealth_visibility(), 0.0, "crouching in a bush: hidden")
	assert_true(p.is_hidden())
	p.set_crouching(false)
	assert_eq(p.stealth_visibility(), 0.45, "standing up in the bush: seen again")
	p.stealth_in_bush = false
	p.drink(ItemIds.POTION_INVIS)
	assert_eq(p.stealth_visibility(), 0.0, "the Invisibility potion")


# --- Hiding inside ---

func test_hiding_puts_the_body_and_the_camera_inside() -> void:
	var p := _player()
	watch_signals(p)
	p.set_crouching(true)
	p.set_hidden(true, CELL)
	assert_true(p.is_hiding())
	assert_true(p.is_hidden())
	assert_false(p.crouching, "stands up inside")
	assert_eq(p.stealth_visibility(), 0.0)
	assert_almost_eq(p.global_position, Vector3(4.5, 10, 0.5), Vector3.ONE * 0.001, "the body is in the block")
	assert_eq(p.collision_mask, 0, "and does not push out of it")
	assert_true(p.rig.peek_from.is_finite(), "the camera looks out from inside")
	assert_almost_eq(p.rig.peek_from, Vector3(4.5, 10.6, 0.5), Vector3.ONE * 0.001)
	p._process(0.016)
	assert_false(p.avatar.visible, "nobody sees the body")
	assert_signal_emitted_with_parameters(p, "hidden_changed", [true])


func test_coming_out_steps_out_where_it_went_in() -> void:
	var p := _player()
	p.set_hidden(true, CELL)
	p.set_hidden(false, CELL)
	assert_false(p.is_hiding())
	assert_almost_eq(p.global_position, Vector3(2.5, 10, 0.5), Vector3.ONE * 0.001, "no world here: back where it stood")
	assert_eq(p.collision_mask, Player.WORLD_COLLISION_MASK)
	assert_false(p.rig.peek_from.is_finite(), "the camera is back behind the player")
	assert_eq(p.rig.arm.spring_length, CameraRig.THIRD_PERSON_DISTANCE)


func test_a_hidden_body_holds_still() -> void:
	var p := _player()
	p.set_hidden(true, CELL)
	p.velocity = Vector3(3, 0, 0)
	p._physics_process(0.016)
	assert_almost_eq(p.global_position, Vector3(4.5, 10, 0.5), Vector3.ONE * 0.001)
	assert_eq(p.velocity, Vector3.ZERO)


func test_moving_while_hidden_asks_to_come_out_once() -> void:
	var p := _player()
	p.set_hidden(true, CELL)
	watch_signals(Session)
	Input.action_press(&"move_forward")
	p._physics_process(0.016)
	p._physics_process(0.016)
	assert_signal_emit_count(Session, "stealth_unhide_requested", 1, "solo: this game is the host")


func test_a_remote_hidden_player_is_not_drawn() -> void:
	var p := _player(7)
	p.set_hidden(true, CELL)
	p._process(0.016)
	assert_false(p.avatar.visible)
	p.set_hidden(false, CELL)
	p._process(0.016)
	assert_true(p.avatar.visible)
