extends GutTest
## Jump pads and speed pads work on animals too (M3 Task 6, spec §14.3). The host simulates animals,
## so the host's game fires the pad and tells the others (a boing and a puff everywhere). Monsters
## (M2) use the same PadRules in their host tick.

class PadWorld:
	extends WorldService
	const GROUND := 10
	var pads := {}   # Vector3i -> pad id

	func get_block(pos: Vector3i) -> int:
		if pads.has(pos):
			return pads[pos]
		return BlockIds.STONE if pos.y < GROUND else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return GROUND - 1

	func is_area_ready(_center: Vector3) -> bool:
		return true


func _setup(pad: int) -> Animal:
	var w := PadWorld.new()
	w.pads[Vector3i(2, PadWorld.GROUND - 1, 2)] = pad
	add_child_autofree(w)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 10, 200)
	shape.shape = box
	shape.position = Vector3(0, PadWorld.GROUND - 5, 0)
	ground.add_child(shape)
	w.add_child(ground)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = "77"                      # a guest standing close by: the animal is simulated
	add_child_autofree(p)
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3(8, PadWorld.GROUND, 2)
	var a := Animal.new()
	a.setup({"species": &"sheep", "id": "pad_sheep", "pos": Vector3(2.5, PadWorld.GROUND, 2.5), "yaw": 0.0,
		"owner": 0, "name": "", "sitting": false})
	a.world = w
	add_child_autofree(a)
	return a


func _particles() -> int:
	var n := 0
	for c in get_tree().root.get_children():
		if c is CPUParticles3D and not c.is_queued_for_deletion():
			n += 1
	return n


func test_a_jump_pad_throws_an_animal_up() -> void:
	var a := _setup(BlockIds.JUMP_PAD)
	await get_tree().physics_frame        # players join between frames
	var before := _particles()
	var peak := a.global_position.y
	var puffed := false
	for i in 60:
		a._physics_process(1.0 / 60.0)
		peak = maxf(peak, a.global_position.y)
		puffed = puffed or _particles() > before
	assert_gt(peak, PadWorld.GROUND + 3.0, "boing")
	assert_true(puffed, "with a puff")


func test_a_speed_pad_sends_an_animal_running() -> void:
	var a := _setup(BlockIds.SPEED_PAD)
	await get_tree().physics_frame
	var top := 0.0
	for i in 30:
		a._physics_process(1.0 / 60.0)
		top = maxf(top, Vector2(a.velocity.x, a.velocity.z).length())
	assert_gt(top, PadRules.BOOST_SPEED * 0.8)


func test_an_animal_away_from_pads_just_stands() -> void:
	var a := _setup(BlockIds.STONE)
	await get_tree().physics_frame
	for i in 30:
		a._physics_process(1.0 / 60.0)
	assert_lt(a.global_position.y, PadWorld.GROUND + 0.6, "only its little walking hops")
