extends GutTest
## Owner feedback #30 ("i cannt get from water without filying"). Every river bank in Green Meadows is
## 1 block above the water, with water 2 deep at the bank (MeadowsShape; a scan of 5 seeds found no
## other bank near the spawn). Swimming at the bank with the view level climbs out (M2 Task 14), but
## with the view tilted down past the dive dead zone (third-person pitch < -0.5, easy on a phone) a push
## forward dives: in 2-deep water the swimmer sinks to the bottom against the bank, where the climb
## (only near the surface) never starts, and it stays there pushing. Also UP next to a bank only bobbed.
## Now a push against a bank never dives (the swimmer floats up to it and climbs), UP alone next to a
## bank climbs it, and UP with a push also climbs a wall 2 blocks above the water.
## Real Player, real Jolt physics: a fake river with matching collision boxes, and the real terrain.

## Water rows 22 and 23 (the surface at 24, like SEA_LEVEL) over a floor whose top is `floor_top`,
## and at x >= 20 a bank whose top is `bank_top`.
class RiverWorld:
	extends WorldService
	var floor_top := 22
	var bank_top := 25

	func get_block(p: Vector3i) -> int:
		if p.x >= 20:
			return BlockIds.GRASS if p.y < bank_top else BlockIds.AIR
		if p.y < floor_top:
			return BlockIds.STONE
		return BlockIds.WATER if p.y < 24 else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return 25

	func is_area_ready(_center: Vector3) -> bool:
		return true


const SURFACE := 24.0

var player: Player


func after_each() -> void:
	for a: StringName in [&"move_forward", &"jump", &"fly_down"]:
		Input.action_release(a)


func _river(floor_top: int = 22, bank_top: int = 25) -> void:
	var world := RiverWorld.new()
	world.floor_top = floor_top
	world.bank_top = bank_top
	add_child_autofree(world)
	var ground := StaticBody3D.new()
	_box(ground, Vector3(40, floor_top, 400), Vector3(0, floor_top * 0.5, 0))
	_box(ground, Vector3(100, bank_top, 400), Vector3(70, bank_top * 0.5, 0))
	world.add_child(ground)
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child_autofree(player)
	player.spawn_at(Vector3(16.5, SURFACE - SwimRules.FLOAT_DEPTH, 0.5))
	await wait_until(func() -> bool: return player.is_spawned(), 2.0, "spawned")
	await wait_physics_frames(30)
	player.rig.yaw = -PI / 2.0     # the camera looks along +X, at the bank


func _box(body: StaticBody3D, size: Vector3, center: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = center
	body.add_child(shape)


func _on_the_bank(top: float) -> Callable:
	return func() -> bool: return player.global_position.x > 20.35 and player.is_on_floor() \
		and absf(player.global_position.y - top) < 0.1


func test_swimming_into_the_bank_with_the_view_tilted_down_still_climbs_out() -> void:
	await _river()
	player.rig.pitch = -0.7        # looking down a little more than the resting third-person view
	Input.action_press(&"move_forward")
	await wait_until(_on_the_bank(25.0), 4.0, "climbed out")
	assert_true(_on_the_bank(25.0).call(), "standing on the bank (at %s)" % player.global_position)
	assert_eq(player.water_state, SwimRules.State.DRY)


func test_looking_straight_down_at_the_bank_climbs_out_too() -> void:
	await _river()
	player.rig.pitch = CameraRig.PITCH_MIN
	Input.action_press(&"move_forward")
	await wait_until(_on_the_bank(25.0), 4.0, "climbed out")
	assert_true(_on_the_bank(25.0).call(), "standing on the bank (at %s)" % player.global_position)


func test_up_next_to_a_bank_climbs_out_without_pushing() -> void:
	await _river()
	player.global_position.x = 19.5     # beside the bank, treading water
	player.rig.yaw = 0.0                # looking along the bank, not at it
	await wait_physics_frames(10)
	Input.action_press(&"jump")
	await wait_until(_on_the_bank(25.0), 4.0, "climbed out")
	assert_true(_on_the_bank(25.0).call(), "UP alone climbs the bank beside the body (at %s)" % player.global_position)


func test_up_in_open_water_only_swims_up() -> void:
	await _river()
	player.global_position.x = 10.5
	await wait_physics_frames(10)
	Input.action_press(&"jump")
	await wait_physics_frames(90)
	assert_lt(player.global_position.x, 11.0, "nowhere to climb")
	assert_eq(player.water_state, SwimRules.State.SWIMMING, "still swimming, the chest in the water")


func test_up_and_forward_climb_a_wall_two_blocks_above_the_water() -> void:
	await _river(19, 26)
	Input.action_press(&"move_forward")
	Input.action_press(&"jump")
	await wait_until(_on_the_bank(26.0), 4.0, "climbed out")
	assert_true(_on_the_bank(26.0).call(), "on top of the 2-block wall (at %s)" % player.global_position)


func test_a_push_alone_never_climbs_a_two_block_wall() -> void:
	await _river(19, 26)
	Input.action_press(&"move_forward")
	await wait_physics_frames(150)
	assert_lt(player.global_position.x, 20.0, "still in the water")
	assert_eq(player.water_state, SwimRules.State.SWIMMING)


func test_a_wall_three_blocks_above_the_water_is_never_climbed() -> void:
	await _river(19, 27)
	Input.action_press(&"move_forward")
	Input.action_press(&"jump")
	await wait_physics_frames(150)
	assert_lt(player.global_position.x, 20.0, "still in the water")


func test_down_held_at_the_bank_dives_and_never_climbs() -> void:
	await _river(19, 25)
	Input.action_press(&"move_forward")
	Input.action_press(&"fly_down")
	await wait_physics_frames(90)
	assert_lt(player.global_position.x, 20.0, "still in the water")
	assert_eq(player.water_state, SwimRules.State.DIVING)


# --- The owner's case on the real terrain (seed 42): a river bank near the spawn ---

## A water column with a 1-block bank east of it (and water west, north and south).
func _river_edge(shape: MeadowsShape, from: Vector2i) -> Vector2i:
	for r in range(0, 200):
		for dz in range(-r, r + 1):
			for dx in [-r, r]:
				var c := from + Vector2i(dx, dz)
				if shape.height_at(c.x, c.y) < MeadowsShape.SEA_LEVEL \
						and shape.height_at(c.x + 1, c.y) == MeadowsShape.SEA_LEVEL + 1 \
						and shape.height_at(c.x - 1, c.y) < MeadowsShape.SEA_LEVEL \
						and shape.height_at(c.x, c.y + 1) <= MeadowsShape.SEA_LEVEL \
						and shape.height_at(c.x, c.y - 1) <= MeadowsShape.SEA_LEVEL:
					return c
	return Vector2i(99999, 0)


func test_a_real_river_bank_is_climbed_with_the_view_tilted_down() -> void:
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	var c := _river_edge(world.generator_shape(), world.spawn_column())
	assert_ne(c.x, 99999, "a river bank near the spawn")
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child_autofree(player)
	player.set_view_distance(GraphicsPreset.MIN_VIEW_DISTANCE)
	player.spawn_at(Vector3(c.x - 1.5, SURFACE - SwimRules.FLOAT_DEPTH, c.y + 0.5))
	await wait_until(func() -> bool: return player.is_spawned(), 15.0, "spawned")
	await wait_physics_frames(120)   # the terrain's collision around the river
	assert_eq(world.get_block(Vector3i(c.x, 23, c.y)), BlockIds.WATER)
	assert_true(BlockIds.is_solid(world.get_block(Vector3i(c.x + 1, 24, c.y))), "the bank")
	player.rig.yaw = -PI / 2.0
	player.rig.pitch = -0.7
	Input.action_press(&"move_forward")
	var out := func() -> bool: return player.global_position.x > c.x + 1.35 and player.is_on_floor() \
		and player.global_position.y >= SURFACE + 0.95
	await wait_until(out, 5.0, "climbed out")
	assert_true(out.call(), "out of the real river (at %s, the bank at x %d)" % [player.global_position, c.x + 1])
