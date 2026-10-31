extends GutTest
## Real water on a real Player with real physics (M2 Task 14, owner feedback #17): "player should swim
## not walk like on ground, this aplies as top also undeground waters". It floats with the head out,
## never stands on the bottom, swims at swim speed where it looks, dives with DOWN or a look down,
## swims up with JUMP, climbs out over a 1-block bank, and splashes, bubbles and drips.
##
## The fake world is the pool of tests/unit/test_swim_rules.gd with matching collision boxes (every z):
##   x < 0     land, its top at 13 (level with the water surface)
##   0 ... 3   a shallow shelf, its top at 12, water in row 12 (1 deep)
##   4 ... 19  deep water over a floor at 10, the surface at 13 (water_top raises it)
##   x >= 20   a bank, its top at 14 (1 block above the water; bank_top = 14 makes it 2)
## A cave roof (roof_y) can cover the deep water.

class PoolWorld:
	extends WorldService
	var water_top := 12
	var roof_y := 1000
	var bank_top := 13

	func get_block(p: Vector3i) -> int:
		if p.y <= 9:
			return BlockIds.STONE
		if p.x < 0:
			return BlockIds.STONE if p.y <= 12 else BlockIds.AIR
		if p.x < 4:
			if p.y <= 11:
				return BlockIds.STONE
			return BlockIds.WATER if p.y == 12 else BlockIds.AIR
		if p.x < 20:
			if p.y >= roof_y:
				return BlockIds.STONE
			return BlockIds.WATER if p.y <= water_top else BlockIds.AIR
		return BlockIds.STONE if p.y <= bank_top else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return 13

	func is_area_ready(_center: Vector3) -> bool:
		return true


var world: PoolWorld
var player: Player


func after_each() -> void:
	for a: StringName in [&"move_forward", &"jump", &"fly_down"]:
		Input.action_release(a)


func _setup(water_top: int = 12, roof_y: int = 1000, bank_top: int = 13) -> void:
	world = PoolWorld.new()
	world.water_top = water_top
	world.roof_y = roof_y
	world.bank_top = bank_top
	add_child_autofree(world)
	var ground := StaticBody3D.new()
	_box(ground, Vector3(100, 13, 400), Vector3(-50, 6.5, 0))                            # land
	_box(ground, Vector3(4, 12, 400), Vector3(2, 6, 0))                                  # shelf
	_box(ground, Vector3(16, 10, 400), Vector3(12, 5, 0))                                # deep floor
	_box(ground, Vector3(100, bank_top + 1, 400), Vector3(70, (bank_top + 1) * 0.5, 0))  # bank
	if roof_y < 100:
		_box(ground, Vector3(16, 10, 400), Vector3(12, roof_y + 5, 0))                   # cave roof
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


func _world_particles() -> Array[CPUParticles3D]:
	var list: Array[CPUParticles3D] = []
	for n in world.get_children():
		if n is CPUParticles3D and not n.is_queued_for_deletion():
			list.append(n)
	return list


func test_an_idle_swimmer_floats_with_the_head_above_the_water_and_never_stands_on_the_bottom() -> void:
	_setup()
	watch_signals(player)
	await _spawn(Vector3(12.5, 10.05, 0.5))
	await wait_physics_frames(240)
	assert_eq(player.water_state, SwimRules.State.SWIMMING)
	assert_false(player.is_on_floor(), "not standing on the bottom")
	assert_gt(player.global_position.y, 10.5, "floated up off the floor")
	assert_gt(player.eye_position().y, 13.1, "the head is out of the water")
	assert_eq(player.avatar.pose, AvatarModel.POSE_SWIM, "in the swim pose")
	assert_signal_emitted_with_parameters(player, "swimming_changed", [true])


func test_swimming_forward_moves_at_swim_speed_and_stays_at_the_surface() -> void:
	_setup()
	await _spawn(Vector3(5.5, 11.75, 0.5))
	await wait_physics_frames(30)
	player.rig.yaw = -PI / 2.0     # forward is +X
	Input.action_press(&"move_forward")
	await wait_physics_frames(90)
	var flat := Vector2(player.velocity.x, player.velocity.z)
	assert_almost_eq(flat.length(), SwimRules.SWIM_SPEED, 0.3, "swim speed, not walking speed")
	assert_gt(player.global_position.x, 8.0, "it moved along")
	assert_eq(player.water_state, SwimRules.State.SWIMMING, "still at the surface")
	assert_gt(player.eye_position().y, 13.0)


func test_looking_down_and_pushing_forward_dives() -> void:
	_setup()
	await _spawn(Vector3(5.5, 11.75, 0.5))
	await wait_physics_frames(60)
	var start := player.global_position.y
	player.rig.yaw = -PI / 2.0
	player.rig.pitch = -1.3
	Input.action_press(&"move_forward")
	await wait_physics_frames(40)
	assert_lt(player.global_position.y, start - 0.6, "down the look")
	assert_eq(player.water_state, SwimRules.State.DIVING)
	Input.action_release(&"move_forward")
	player.rig.pitch = -0.35
	await wait_physics_frames(240)
	assert_eq(player.water_state, SwimRules.State.SWIMMING, "and floats back up when let go")


func test_down_dives_and_jump_swims_back_up_but_not_out() -> void:
	_setup()
	await _spawn(Vector3(12.5, 11.75, 0.5))
	await wait_physics_frames(60)
	Input.action_press(&"fly_down")
	await wait_physics_frames(45)
	Input.action_release(&"fly_down")
	assert_lt(player.global_position.y, 11.0, "DOWN dives")
	assert_eq(player.water_state, SwimRules.State.DIVING)
	var low := player.global_position.y
	Input.action_press(&"jump")
	await wait_physics_frames(20)
	assert_gt(player.global_position.y, low + 0.5, "JUMP swims up")
	await wait_physics_frames(100)
	assert_gt(player.eye_position().y, 13.0, "up to the surface")
	assert_lt(player.global_position.y, 13.0 - SwimRules.CHEST, "never out of the water")
	assert_eq(player.water_state, SwimRules.State.SWIMMING)


func test_pushing_against_a_one_block_bank_climbs_out_and_drips() -> void:
	_setup()
	await _spawn(Vector3(17.5, 11.75, 0.5))
	await wait_physics_frames(30)
	player.rig.yaw = -PI / 2.0
	Input.action_press(&"move_forward")
	var out := func() -> bool: return player.global_position.x > 20.4 and player.is_on_floor()
	await wait_until(out, 3.0, "climbed out")
	assert_true(out.call(), "standing on the bank")
	assert_almost_eq(player.global_position.y, 14.0, 0.1, "on top of the bank")
	assert_eq(player.water_state, SwimRules.State.DRY)
	assert_eq(player.avatar.pose, AvatarModel.POSE_STAND, "walking again")
	var drips := player.find_children("*", "CPUParticles3D", false, false)
	assert_eq(drips.size(), 1, "water drips off for a moment")


func test_a_two_block_wall_is_not_climbed() -> void:
	_setup(12, 1000, 14)
	await _spawn(Vector3(17.5, 11.75, 0.5))
	await wait_physics_frames(30)
	player.rig.yaw = -PI / 2.0
	Input.action_press(&"move_forward")
	await wait_physics_frames(150)
	assert_lt(player.global_position.x, 20.0, "still in the water")
	assert_eq(player.water_state, SwimRules.State.SWIMMING)


func test_in_a_cave_pool_under_a_roof_the_head_floats_in_the_air_pocket() -> void:
	_setup(12, 16)
	await _spawn(Vector3(12.5, 10.05, 0.5))
	await wait_physics_frames(240)
	assert_eq(player.water_state, SwimRules.State.SWIMMING)
	assert_false(player.is_on_floor())
	assert_gt(player.eye_position().y, 13.1)


func test_in_a_flooded_cave_the_player_floats_up_off_the_bottom() -> void:
	_setup(14, 15)
	await _spawn(Vector3(12.5, 10.05, 0.5))
	await wait_physics_frames(240)
	assert_eq(player.water_state, SwimRules.State.DIVING, "no air: under water")
	assert_false(player.is_on_floor(), "never standing on the cave floor")
	assert_gt(player.global_position.y, 12.5, "floated up to the roof")
	assert_eq(player.avatar.pose, AvatarModel.POSE_SWIM)


func test_jumping_in_splashes() -> void:
	_setup()
	await _spawn(Vector3(12.5, 16.0, 0.5))
	await wait_until(func() -> bool: return player.water_state != SwimRules.State.DRY, 2.0, "in the water")
	await wait_frames(2)
	var fx := _world_particles()
	assert_gte(fx.size(), 2, "drops and a ring")
	assert_true(fx.any(func(p: CPUParticles3D) -> bool: return p.mesh is TorusMesh), "a ring on the water")


func test_a_diver_blows_bubbles() -> void:
	_setup()
	await _spawn(Vector3(12.5, 11.75, 0.5))
	await wait_physics_frames(30)
	Input.action_press(&"fly_down")
	await wait_physics_frames(60)
	var rising := _world_particles().filter(func(p: CPUParticles3D) -> bool: return p.gravity.y > 0.0)
	assert_gt(rising.size(), 0, "bubbles rise")


func test_knee_deep_water_is_waded_through_slowly() -> void:
	_setup()
	await _spawn(Vector3(1.5, 12.05, 0.5))
	await wait_physics_frames(20)
	player.rig.yaw = 0.0           # forward is -Z, along the shelf
	Input.action_press(&"move_forward")
	await wait_physics_frames(60)
	assert_eq(player.water_state, SwimRules.State.WADING)
	assert_true(player.is_on_floor(), "walking on the shelf")
	var flat := Vector2(player.velocity.x, player.velocity.z)
	assert_almost_eq(flat.length(), Player.WALK_SPEED * Player.WATER_SPEED_FACTOR, 0.3, "slowed by the water")
	assert_eq(player.avatar.pose, AvatarModel.POSE_STAND)


func test_the_water_state_reaches_the_other_players() -> void:
	_setup()
	var cfg := (player.get_node("Sync") as MultiplayerSynchronizer).replication_config
	var path := NodePath(".:water_state")
	assert_true(cfg.has_property(path))
	assert_eq(cfg.property_get_replication_mode(path), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	assert_true(cfg.property_get_spawn(path))
