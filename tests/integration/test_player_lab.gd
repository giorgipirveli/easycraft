extends GutTest
## Physics Lab on a real Player with real physics (M3 Task 6, spec §14.3): Moon gravity, Zero-G, slow
## motion, jump pads and speed pads; the lab mode and the WALK/FLY/GHOST switch stay in step;
## Survivor refuses the lab; other games see a slow-motion player and its pads' boing.
##
## The fake world: a stone floor with its top at y = 10 everywhere, a stone wall from x = 20 up to
## y = 30, and pads set into the floor (their tops level with it) where a test puts them.

class LabWorld:
	extends WorldService
	var pads := {}   # Vector3i -> pad id

	func get_block(p: Vector3i) -> int:
		if pads.has(p):
			return pads[p]
		if p.y <= 9 or (p.x >= 20 and p.y <= 30):
			return BlockIds.STONE
		return BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return 10

	func is_area_ready(_center: Vector3) -> bool:
		return true


const L := LabRules.Mode

var world: LabWorld
var player: Player


func after_each() -> void:
	for a: StringName in [&"move_forward", &"jump", &"fly_down"]:
		Input.action_release(a)
	Game.mode = ModeRules.SANDBOX


func _setup() -> void:
	world = LabWorld.new()
	add_child_autofree(world)
	var ground := StaticBody3D.new()
	_box(ground, Vector3(400, 10, 400), Vector3(0, 5, 0))       # the floor, its top at 10
	_box(ground, Vector3(10, 40, 400), Vector3(25, 20, 0))      # the wall, its face at x = 20
	world.add_child(ground)
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child_autofree(player)


func _box(body: StaticBody3D, size: Vector3, center: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = center
	body.add_child(shape)


func _spawn(pos: Vector3) -> void:
	player.spawn_at(pos)
	await wait_until(func() -> bool: return player.is_spawned(), 2.0, "spawned")
	await wait_physics_frames(10)   # standing


## Jumps once (the jump button, through the jump buffer) and returns the highest the feet got.
func _jump_peak(frames: int) -> float:
	var y0 := player.global_position.y
	var peak := y0
	player._jumps.press_jump()
	for i in frames:
		await wait_physics_frames(1)
		peak = maxf(peak, player.global_position.y)
	return peak - y0


func _world_particles() -> Array[CPUParticles3D]:
	var list: Array[CPUParticles3D] = []
	for n in world.get_children():
		if n is CPUParticles3D and not n.is_queued_for_deletion():
			list.append(n)
	return list


# --- The lab mode and the physics switch ---

func test_a_lab_mode_sets_how_the_body_moves_and_the_switch_follows() -> void:
	_setup()
	watch_signals(player)
	player.set_lab_mode(L.ZERO_G)
	assert_eq(player.lab_mode, L.ZERO_G)
	assert_eq(player.physics_mode, PhysicsMode.Mode.FLY, "floats, still bumps into blocks")
	assert_signal_emitted_with_parameters(player, "lab_mode_changed", [L.ZERO_G])
	player.cycle_physics_mode()                       # the WALK/FLY/GHOST button
	assert_eq(player.physics_mode, PhysicsMode.Mode.GHOST)
	assert_eq(player.lab_mode, L.GHOST, "the lab mode follows the switch")
	player.set_lab_mode(L.MOON)
	assert_eq(player.physics_mode, PhysicsMode.Mode.NORMAL)
	player.set_physics_mode(PhysicsMode.Mode.NORMAL)  # /walk, a bed, the autopilot…
	assert_eq(player.lab_mode, L.NORMAL, "back to plain walking")


func test_the_lab_button_cycles_the_modes() -> void:
	_setup()
	var seen: Array[int] = []
	for i in LabRules.CYCLE.size():
		player.cycle_lab_mode()
		seen.append(player.lab_mode)
	assert_eq(seen, [L.MOON, L.ZERO_G, L.FLY, L.GHOST, L.SLOW, L.NORMAL])


func test_survivor_has_no_lab() -> void:
	_setup()
	Game.mode = ModeRules.SURVIVOR
	player.set_lab_mode(L.MOON)
	assert_eq(player.lab_mode, L.NORMAL, "refused")
	player.cycle_lab_mode()
	assert_eq(player.lab_mode, L.NORMAL, "no LAB button in Survivor: flying costs gold there (M2)")
	assert_eq(player.physics_mode, PhysicsMode.Mode.NORMAL)


func test_the_lab_mode_is_synced_to_every_game() -> void:
	_setup()
	var cfg := (player.get_node("Sync") as MultiplayerSynchronizer).replication_config
	var path := NodePath(".:lab_mode")
	assert_true(cfg.has_property(path))
	assert_true(cfg.property_get_spawn(path), "a player who joins later sees it too")
	assert_eq(cfg.property_get_replication_mode(path), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)


# --- Moon gravity ---

func test_moon_jumps_are_almost_three_times_as_high() -> void:
	_setup()
	await _spawn(Vector3(5.5, 10.0, 0.5))
	var normal := await _jump_peak(90)
	await wait_physics_frames(20)
	player.set_lab_mode(L.MOON)
	var moon := await _jump_peak(200)
	assert_almost_eq(normal, LabRules.jump_height(L.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY), 0.2)
	assert_almost_eq(moon / normal, 1.0 / LabRules.MOON_GRAVITY, 0.35, "moon %.2f vs normal %.2f" % [moon, normal])


# --- Slow motion ---

func test_slow_motion_walks_at_four_tenths_speed() -> void:
	_setup()
	await _spawn(Vector3(-60.5, 10.0, 0.5))
	player.rig.yaw = -PI / 2.0     # forward is +X
	Input.action_press(&"move_forward")
	await wait_physics_frames(30)
	var x0 := player.global_position.x
	await wait_physics_frames(60)
	var normal := player.global_position.x - x0
	player.set_lab_mode(L.SLOW)
	await wait_physics_frames(30)
	x0 = player.global_position.x
	await wait_physics_frames(60)
	var slow := player.global_position.x - x0
	assert_almost_eq(slow / normal, LabRules.SLOW_TIME, 0.05, "slow %.2f m vs %.2f m" % [slow, normal])
	assert_almost_eq(Vector2(player.velocity.x, player.velocity.z).length(), Player.WALK_SPEED, 0.2,
		"its own speed is its walking speed, in slow time")


func test_a_slow_motion_jump_is_as_high_and_the_walk_cycle_is_slow() -> void:
	_setup()
	await _spawn(Vector3(5.5, 10.0, 0.5))
	player.set_lab_mode(L.SLOW)
	var peak := await _jump_peak(240)
	assert_almost_eq(peak, LabRules.jump_height(L.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY), 0.2)
	await wait_physics_frames(30)
	var avatar := player.avatar as BlockyAvatar
	var phase := avatar._phase
	await wait_physics_frames(30)
	var slow := avatar._phase - phase
	player.set_lab_mode(L.NORMAL)
	phase = avatar._phase
	await wait_physics_frames(30)
	var normal := avatar._phase - phase
	assert_almost_eq(slow / normal, LabRules.SLOW_TIME, 0.02, "the avatar moves in slow time too")


# --- Zero-G ---

func test_zero_g_floats_where_it_is() -> void:
	_setup()
	await _spawn(Vector3(5.5, 10.0, 0.5))
	player.set_lab_mode(L.ZERO_G)
	player.global_position = Vector3(5.5, 15.0, 0.5)
	player.velocity = Vector3.ZERO
	await wait_physics_frames(60)
	assert_almost_eq(player.global_position.y, 15.0, 0.001, "no gravity")


func test_zero_g_jump_thrusts_up_gently() -> void:
	_setup()
	await _spawn(Vector3(5.5, 10.0, 0.5))
	player.set_lab_mode(L.ZERO_G)
	player.global_position = Vector3(5.5, 15.0, 0.5)
	Input.action_press(&"jump")
	await wait_physics_frames(60)
	assert_gt(player.velocity.y, 1.0, "going up")
	assert_lte(player.velocity.y, LabRules.THRUST_SPEED + 0.01, "gently")
	Input.action_release(&"jump")
	var v := player.velocity.y
	await wait_physics_frames(30)
	assert_gt(player.velocity.y, v * 0.8, "drifts on after letting go")


func test_zero_g_pushes_off_a_wall_it_moves_into() -> void:
	_setup()
	await _spawn(Vector3(5.5, 10.0, 0.5))
	player.set_lab_mode(L.ZERO_G)
	player.global_position = Vector3(18.5, 15.0, 0.5)
	player.rig.yaw = -PI / 2.0     # forward is +X, into the wall
	Input.action_press(&"move_forward")
	var pushed := false
	for i in 180:
		await wait_physics_frames(1)
		if player.velocity.x < -LabRules.PUSH_OFF_SPEED * 0.8:
			pushed = true
			break
	assert_true(pushed, "kicked off the wall")
	assert_lt(player.global_position.x, 20.0)


func test_zero_g_down_on_the_floor_kicks_up() -> void:
	_setup()
	await _spawn(Vector3(5.5, 10.0, 0.5))
	player.set_lab_mode(L.ZERO_G)
	player.global_position = Vector3(5.5, 10.3, 0.5)
	Input.action_press(&"fly_down")
	var kicked := false
	for i in 90:
		await wait_physics_frames(1)
		if player.velocity.y > LabRules.PUSH_OFF_SPEED * 0.8:
			kicked = true
			break
	assert_true(kicked)


# --- Pads ---

func test_a_jump_pad_launches_the_player_high_with_a_puff() -> void:
	_setup()
	world.pads[Vector3i(0, 9, 0)] = BlockIds.JUMP_PAD
	player.spawn_at(Vector3(0.5, 10.0, 0.5))
	await wait_until(func() -> bool: return player.is_spawned(), 2.0, "spawned")
	var peak := 10.0
	var puffed := false
	for i in 90:
		await wait_physics_frames(1)
		peak = maxf(peak, player.global_position.y)
		puffed = puffed or not _world_particles().is_empty()
	assert_gt(peak, 14.0, "about 5 blocks up")
	assert_true(puffed, "a puff at the pad")


func test_a_moon_pad_jump_goes_even_higher() -> void:
	_setup()
	world.pads[Vector3i(0, 9, 0)] = BlockIds.JUMP_PAD
	player.set_lab_mode(L.MOON)
	player.spawn_at(Vector3(0.5, 10.0, 0.5))
	await wait_until(func() -> bool: return player.is_spawned(), 2.0, "spawned")
	var peak := 10.0
	for i in 150:
		await wait_physics_frames(1)
		peak = maxf(peak, player.global_position.y)
	assert_gt(peak, 20.0)


func test_a_speed_pad_bursts_the_player_along_for_a_moment() -> void:
	_setup()
	world.pads[Vector3i(0, 9, 0)] = BlockIds.SPEED_PAD
	await _spawn(Vector3(2.5, 10.0, 0.5))
	player.rig.yaw = PI / 2.0      # forward is -X, over the pad
	Input.action_press(&"move_forward")
	var top := 0.0
	var boosted_at := -1
	for i in 60:
		await wait_physics_frames(1)
		var speed := Vector2(player.velocity.x, player.velocity.z).length()
		top = maxf(top, speed)
		if boosted_at < 0 and speed > Player.WALK_SPEED * 1.5:
			boosted_at = i
	assert_almost_eq(top, PadRules.BOOST_SPEED, 0.3, "a burst of speed")
	assert_lt(player.velocity.x, 0.0, "the way it was walking")
	await wait_physics_frames(roundi((PadRules.BOOST_TIME + 0.3) * 60.0))
	assert_almost_eq(Vector2(player.velocity.x, player.velocity.z).length(), Player.WALK_SPEED, 0.3, "over after 1.5 s")


func test_a_ghost_floats_through_pads() -> void:
	_setup()
	world.pads[Vector3i(0, 9, 0)] = BlockIds.JUMP_PAD
	await _spawn(Vector3(5.5, 10.0, 0.5))
	player.set_lab_mode(L.GHOST)
	player.global_position = Vector3(0.5, 10.0, 0.5)
	await wait_physics_frames(30)
	assert_lt(player.global_position.y, 10.5, "a ghost touches nothing")


# --- Other games ---

func test_a_remote_player_in_slow_motion_animates_slowly() -> void:
	_setup()
	var fast := _remote("701")
	var slow := _remote("702")
	slow.lab_mode = L.SLOW
	for p: Player in [fast, slow]:
		p.velocity = Vector3(Player.WALK_SPEED, 0, 0)
		p._update_remote(0.016)
	var f0 := (fast.avatar as BlockyAvatar)._phase
	var s0 := (slow.avatar as BlockyAvatar)._phase
	for i in 10:
		fast._update_remote(0.016)
		slow._update_remote(0.016)
	var ratio := ((slow.avatar as BlockyAvatar)._phase - s0) / ((fast.avatar as BlockyAvatar)._phase - f0)
	assert_almost_eq(ratio, LabRules.SLOW_TIME, 0.001, "the same slow walk in every game")


func test_a_remote_lab_mode_is_checked() -> void:
	_setup()
	var remote := _remote("703")
	remote.lab_mode = 99   # tampered
	remote._update_remote(0.016)
	assert_eq(remote.lab_mode, L.NORMAL)


func test_other_games_see_and_hear_a_pad_fire() -> void:
	_setup()
	var remote := _remote("704")
	remote.position = Vector3(3, 10, 3)
	remote._update_remote(0.016)
	remote._rpc_pad_fx(BlockIds.JUMP_PAD)
	remote._rpc_pad_fx(BlockIds.SPEED_PAD)
	assert_eq(_world_particles().size(), 2, "a puff each")
	remote._rpc_pad_fx(BlockIds.STONE)   # nonsense from the network does nothing
	assert_eq(_world_particles().size(), 2)


func test_a_slow_motion_pad_puff_is_slow_too() -> void:
	_setup()
	var remote := _remote("705")
	remote.lab_mode = L.SLOW
	remote._rpc_pad_fx(BlockIds.JUMP_PAD)
	assert_almost_eq(_world_particles()[0].speed_scale, LabRules.SLOW_TIME, 0.0001)


func _remote(peer: String) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = peer                   # a peer other than this game: its body is remote here
	p.world = world
	add_child_autofree(p)
	return p
