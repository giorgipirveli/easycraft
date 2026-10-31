extends GutTest
## Footsteps by block on a real Player (the audio pass, owner feedback #27): walking over planks sounds
## like wood, over stone like stone, over sand like sand (FootstepRules picks the sound from the block
## under the feet).

class FloorWorld:
	extends WorldService
	var floor_block := BlockIds.PLANKS

	func get_block(p: Vector3i) -> int:
		return floor_block if p.y <= 9 else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return 10

	func is_area_ready(_center: Vector3) -> bool:
		return true


var world: FloorWorld
var player: Player


func after_each() -> void:
	Input.action_release(&"move_forward")
	Audio.stop_all()


func _setup(block: int) -> void:
	world = FloorWorld.new()
	world.floor_block = block
	add_child_autofree(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 10, 400)
	shape.shape = box
	shape.position = Vector3(0, 5, 0)
	ground.add_child(shape)
	world.add_child(ground)
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child_autofree(player)
	player.spawn_at(Vector3(0.5, 10.05, 0.5))
	await wait_until(func() -> bool: return player.is_spawned(), 2.0, "spawned")
	await wait_physics_frames(20)


func _walk_and_listen() -> Array[StringName]:
	var heard: Array[StringName] = []
	Input.action_press(&"move_forward")
	for i in 90:
		await wait_physics_frames(1)
		if Audio.last_sound.begins_with("step") and not heard.has(Audio.last_sound):
			heard.append(Audio.last_sound)
	Input.action_release(&"move_forward")
	return heard


func test_the_block_under_the_feet_picks_the_step() -> void:
	await _setup(BlockIds.STONE)
	assert_eq(player.step_sound(), &"step_stone")
	world.floor_block = BlockIds.SAND
	assert_eq(player.step_sound(), &"step_sand")


func test_walking_on_planks_sounds_like_wood() -> void:
	await _setup(BlockIds.PLANKS)
	Audio.last_sound = &""
	var heard := await _walk_and_listen()
	assert_eq(heard, [&"step_wood"] as Array[StringName])
