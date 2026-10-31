extends GutTest
## Deferred M1 minor, on a real Player with real physics: a giant walks up a 1-block step the way a
## normal player does, and growing into a giant beside a wall lifts you on top of it (unstuck checks
## the whole footprint, not only the centre column).
## The world is a fake with a flat floor (rows <= 9) and a 1-block step from x = 8 on, plus
## matching collision boxes.

const STEP_X := 8


## Blocks of the fake world. Extra solid cells can be added (no collision for those).
class StepWorld:
	extends WorldService
	var extra := {}

	func get_block(pos: Vector3i) -> int:
		if pos.y <= 9 or (pos.y == 10 and pos.x >= 8) or extra.has(pos):
			return BlockIds.STONE
		return BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return 10

	func is_area_ready(_center: Vector3) -> bool:
		return true


var world: StepWorld
var player: Player


func before_each() -> void:
	world = StepWorld.new()
	add_child_autofree(world)
	var ground := StaticBody3D.new()
	_box(ground, Vector3(200, 10, 200), Vector3(0, 5, 0))                    # floor, top at y = 10
	_box(ground, Vector3(100, 1, 200), Vector3(STEP_X + 50, 10.5, 0))        # the step, top at y = 11
	world.add_child(ground)
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child_autofree(player)


func after_each() -> void:
	Input.action_release(&"move_forward")


func _box(body: StaticBody3D, size: Vector3, center: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = center
	body.add_child(shape)


## Spawns at start_x in `mode` and walks along +X into the step for 2 s.
func _walk_into_the_step(mode: int, start_x: float) -> void:
	player.set_size_mode(mode)
	player.spawn_at(Vector3(start_x, 10.05, 0.5))
	await wait_until(func() -> bool: return player.is_spawned(), 2.0, "spawned")
	player.rig.yaw = -PI / 2.0     # forward is +X
	Input.action_press(&"move_forward")
	await wait_physics_frames(120)
	Input.action_release(&"move_forward")


func test_a_normal_player_walks_up_a_one_block_step() -> void:
	await _walk_into_the_step(SizeMagic.Mode.NORMAL, 5.5)
	assert_gt(player.global_position.x, STEP_X + 0.5, "past the step's edge")
	assert_gt(player.global_position.y, 10.9, "standing on the step")


func test_a_giant_walks_up_a_one_block_step() -> void:
	await _walk_into_the_step(SizeMagic.Mode.GIANT, 3.5)
	assert_gt(player.global_position.x, STEP_X + 1.0, "past the step's edge")
	assert_gt(player.global_position.y, 10.9, "standing on the step")


func test_growing_into_a_giant_beside_a_wall_climbs_onto_it() -> void:
	for y in range(10, 13):
		world.extra[Vector3i(6, y, 0)] = true    # a 3-high wall column right beside the player
	player.global_position = Vector3(5.5, 10.05, 0.5)
	player.set_size_mode(SizeMagic.Mode.GIANT)
	assert_almost_eq(player.global_position.y, 13.05, 0.001, "the giant's side was inside the wall")
