extends GutTest
## M3 Task 3 (spec §14.1): Frostpeak's ice lakes are slippery for players, animals and monsters alike
## (FrostRules.grip): on ice a body keeps sliding after it stops walking; on stone it stops at once. The
## Frost Giant's icy ground (IcyGround) is slippery the same way, without any block changing.
##
## The fake world: a floor with its top at y = 10; ice for x >= 0, stone for x < 0.

class IceWorld:
	extends WorldService
	const GROUND := 10

	func get_block(p: Vector3i) -> int:
		if p.y < GROUND:
			return BlockIds.ICE if p.x >= 0 else BlockIds.STONE
		return BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return GROUND

	func is_area_ready(_center: Vector3) -> bool:
		return true


const DT := 1.0 / 60.0

var world: IceWorld


func after_each() -> void:
	Input.action_release(&"move_forward")
	IcyGround.clear()


func _world() -> void:
	world = IceWorld.new()
	add_child_autofree(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 10, 400)
	shape.shape = box
	shape.position = Vector3(0, IceWorld.GROUND - 5, 0)
	ground.add_child(shape)
	world.add_child(ground)


func _player_at(pos: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = world
	add_child_autofree(p)
	p.spawn_at(pos)
	await wait_until(func() -> bool: return p.is_spawned(), 2.0, "spawned")
	await wait_physics_frames(10)
	return p


## Walks forward (+X) for a second, lets go, and returns how far the player slid after letting go.
func _slide(p: Player) -> float:
	p.rig.yaw = -PI * 0.5                 # forward is +X
	Input.action_press(&"move_forward")
	await wait_physics_frames(60)
	Input.action_release(&"move_forward")
	var from := p.global_position.x
	await wait_physics_frames(90)
	return p.global_position.x - from


func test_a_child_slides_on_ice_and_stops_on_stone() -> void:
	_world()
	var on_ice := await _player_at(Vector3(20.5, IceWorld.GROUND, 0.5))
	var ice := await _slide(on_ice)
	on_ice.queue_free()
	await wait_physics_frames(2)
	var on_stone := await _player_at(Vector3(-60.5, IceWorld.GROUND, 0.5))
	var stone := await _slide(on_stone)
	assert_lt(stone, 0.6, "stone: stops at once (%.2f)" % stone)
	assert_gt(ice, 1.8, "ice: a slide (%.2f)" % ice)


func test_the_giants_icy_ground_is_slippery_too() -> void:
	_world()
	var p := await _player_at(Vector3(-60.5, IceWorld.GROUND, 0.5))
	IcyGround.add(p.global_position, 10.0, 30.0, Time.get_ticks_msec() / 1000.0)
	var slid := await _slide(p)
	assert_gt(slid, 1.2, "the stomp's icy ring makes stone slippery (%.2f)" % slid)


func _monster(pos: Vector3) -> Monster:
	var m := Monster.new()
	m.setup({"kind": MonsterRules.GOBLIN, "level": 1, "id": "ice_goblin_%d" % int(pos.x), "pos": pos, "yaw": 0.0,
		"wild": true, "universe": 3})
	m.block_at = world.get_block
	add_child_autofree(m)
	m.set_physics_process(false)
	return m


func test_monsters_slide_on_ice() -> void:
	_world()
	var on_ice := _monster(Vector3(20.5, IceWorld.GROUND, 0.5))
	var on_stone := _monster(Vector3(-20.5, IceWorld.GROUND, 0.5))
	await get_tree().physics_frame
	for m in [on_ice, on_stone]:
		m.update_grip()
		m.velocity = Vector3(3, 0, 0)
		for i in 15:
			m._walk_step(DT)                  # it wants to stand still (no way to go)
	assert_eq(on_stone.velocity.x, 0.0, "stone: stopped after 0.25 s")
	assert_gt(on_ice.velocity.x, 2.0, "ice: still sliding")


func test_animals_slide_on_ice() -> void:
	_world()
	var list: Array[Animal] = []
	for x in [20.5, -20.5]:
		var a := Animal.new()
		a.setup({"species": &"sheep", "id": "ice_sheep_%d" % int(x), "pos": Vector3(x, IceWorld.GROUND, 0.5), "yaw": 0.0,
			"owner": 0, "name": "", "sitting": true})     # sitting: it wants to stand still
		a.world = world
		add_child_autofree(a)
		a.set_physics_process(false)
		list.append(a)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = "77"                      # a guest close by: the animals are simulated
	add_child_autofree(p)
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3(0.5, IceWorld.GROUND, 8.5)
	await get_tree().physics_frame
	for a in list:
		a.velocity = Vector3(3, 0, 0)
		for i in 18:
			a._physics_process(DT)
	assert_lt(list[1].velocity.x, 0.1, "stone: stopped")
	assert_gt(list[0].velocity.x, 2.0, "ice: still sliding")
