extends GutTest
## Riding a horse or a camel (owner feedback #41, spec §14.19) with M3 Task 20a's RIDE button and RideDirector: the
## button shows next to a saddled horse nobody rides (never an unsaddled one), the host puts the child on its back,
## the stick moves it at a gallop (capped under the paid Fly), a camel keeps its pace in a sandstorm while a horse
## slows, a ridden animal stops at the water, only its rider steers it, and HOP OFF puts the child beside it on the
## ground, never inside blocks.

const DT := 1.0 / 60.0
const ME_AT := Vector3(0.5, 10.0, 0.5)


class CellWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		if cells.has(pos):
			return cells[pos]
		return BlockIds.STONE if pos.y < 10 else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return 9

	func box_reader(_origin: Vector3i, _size: Vector3i) -> Callable:
		return get_block


var world: CellWorld
var animals: Node3D
var director: RideDirector
var me: Player
var hud: Hud
var said: Array = []
var _mode_before: StringName
var _storm: Callable


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	_storm = Animal.storm_source
	world = CellWorld.new()
	add_child_autofree(world)
	Session.register_world(world)
	animals = Node3D.new()
	animals.name = "Animals"
	add_child_autofree(animals)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 400)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0, 9.5, 0)
	add_child_autofree(ground)
	said = []
	Session.magic_feedback.connect(_heard)


func after_each() -> void:
	Session.magic_feedback.disconnect(_heard)
	Session.register_world(null)
	Game.mode = _mode_before
	Animal.storm_source = _storm


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _heard(text: String) -> void:
	said.append(text)


func _local() -> void:
	me = load("res://entities/player/player.tscn").instantiate()
	me.name = str(multiplayer.get_unique_id())
	me.world = world
	add_child_autofree(me)
	me.set_physics_process(false)
	me.global_position = ME_AT
	me._spawned = true
	director = RideDirector.new()
	director.name = "Rides"
	director.buddies_root = Node3D.new()
	add_child_autofree(director.buddies_root)
	director.animals_root = animals
	director.host_checks = false
	add_child_autofree(director)
	director.set_process(false)
	hud = Hud.new()
	add_child_autofree(hud)
	hud.setup(me, "Kid", true, false)
	director.setup_local(me, hud)


func _mount(species: StringName, id: String, pos: Vector3, saddled := true) -> Animal:
	var a := Animal.new()
	a.setup({"species": species, "id": id, "pos": pos, "yaw": 0.0, "owner": multiplayer.get_unique_id(),
		"name": "Maple", "saddled": saddled})
	a.world = world
	animals.add_child(a)
	a.set_physics_process(false)
	return a


## Steps `a` in real physics frames (move_and_slide then moves by the physics step) with the stick held.
func _run(a: Animal, seconds: float, wish: Vector3) -> float:
	var top := 0.0
	for i in roundi(seconds / DT):
		await get_tree().physics_frame
		if i % 10 == 0:
			a.set_ride_input(wish)
		a._physics_process(get_physics_process_delta_time())
		top = maxf(top, Vector2(a.velocity.x, a.velocity.z).length())
	return top


func _free_spot(at: Vector3) -> bool:
	var feet := Vector3i(at.floor())
	return not BlockIds.is_solid(world.get_block(feet)) and not BlockIds.is_solid(world.get_block(feet + Vector3i.UP))


func test_ride_shows_next_to_a_saddled_horse_and_hop_off_gets_off_beside_it() -> void:
	_local()
	var plain := _mount(&"horse", "h_plain", Vector3(-3.5, 10, 0.5), false)
	var horse := _mount(&"horse", "h_test", Vector3(3.0, 10, 0.5))
	director.scan()
	assert_eq(director.nearby, horse, "the saddled one")
	assert_true(hud.ride_button.visible, "RIDE shows")
	horse.global_position = Vector3(40, 10, 0.5)
	me.global_position = plain.global_position + Vector3(1.5, 0, 0)
	director.scan()
	assert_false(hud.ride_button.visible, "never next to a horse without a saddle")
	me.global_position = ME_AT
	horse.global_position = Vector3(3.0, 10, 0.5)
	director.scan()
	director.press_ride()
	assert_eq(horse.rider_peer, me.peer_id, "the host said yes")
	assert_true(me.is_riding())
	assert_eq(me.riding_animal, horse)
	assert_has(said, RideRules.mount_line(RideRules.Kind.GALLOP))
	me._process(DT)
	assert_almost_eq(me.global_position, horse.seat_position(), Vector3.ONE * 0.001, "on the horse's back")
	assert_gt(me.global_position.y, 11.0, "up on its back")
	director.scan()
	assert_eq(hud.ride_button.text, "HOP OFF")
	director.press_ride()
	assert_eq(horse.rider_peer, 0)
	assert_false(me.is_riding())
	assert_true(_free_spot(me.global_position), "never inside blocks: %s" % me.global_position)
	assert_gt(Vector2(me.global_position.x - 3.0, me.global_position.z - 0.5).length(), 0.9, "beside it")
	assert_almost_eq(me.global_position.y, 10.0, 0.05, "on the ground")


func test_the_stick_gallops_a_horse_never_faster_than_the_paid_fly() -> void:
	_local()
	var horse := _mount(&"horse", "h_test", Vector3(3.0, 10, 0.5))
	assert_eq(director.host_ride(me.peer_id, "h_test"), "")
	var start := horse.global_position
	var top: float = await _run(horse, 3.0, Vector3(0, 0, -1))
	assert_almost_eq(top, float(RideRules.SPEED[RideRules.Kind.GALLOP]), 0.05, "a gallop")
	assert_lt(top, Player.FLY_SPEED)
	assert_gt(start.z - horse.global_position.z, 18.0, "it went where the stick points")


func test_a_camel_keeps_its_pace_in_a_sandstorm_a_horse_slows() -> void:
	_local()
	Animal.storm_source = func() -> float: return 1.0
	var horse := _mount(&"horse", "h_test", Vector3(3.0, 10, 0.5))
	var camel := _mount(&"camel", "k_test", Vector3(-3.0, 10, 0.5))
	horse.start_ride(7)
	camel.start_ride(8)
	var horse_top: float = await _run(horse, 2.0, Vector3(0, 0, -1))
	var camel_top: float = await _run(camel, 2.0, Vector3(0, 0, -1))
	assert_almost_eq(camel_top, float(RideRules.SPEED[RideRules.Kind.TREK]), 0.05, "a camel is steady")
	assert_almost_eq(horse_top, float(RideRules.SPEED[RideRules.Kind.GALLOP]) * AnimalRideRules.STORM_SLOW, 0.05,
		"a horse slows in the storm")


func test_a_ridden_horse_stops_at_the_water() -> void:
	_local()
	for x in range(-3, 4):
		for z in range(-12, -7):
			world.cells[Vector3i(x, 9, z)] = BlockIds.WATER
	var horse := _mount(&"horse", "h_test", Vector3(0.5, 10, 0.5))
	horse.start_ride(7)
	await _run(horse, 4.0, Vector3(0, 0, -1))
	assert_gt(horse.global_position.z, -7.5, "it stopped at the water's edge (%.2f)" % horse.global_position.z)
	assert_lt(horse.global_position.z, -4.0, "after going there")


func test_only_its_rider_steers_it_and_an_unsaddled_horse_is_refused() -> void:
	_local()
	var horse := _mount(&"horse", "h_test", Vector3(3.0, 10, 0.5))
	var plain := _mount(&"horse", "h_plain", Vector3(-3.0, 10, 0.5), false)
	assert_eq(director.host_ride(me.peer_id, "h_plain"), "no_saddle")
	assert_eq(plain.rider_peer, 0)
	assert_has(said, RideDirector.NO_SADDLE_ANIMAL)
	assert_eq(director.host_ride(me.peer_id, "h_test"), "")
	director.host_ride_input(99, "h_test", Vector3(1, 0, 0))
	assert_eq(horse.ride_input, Vector3.ZERO, "someone else's stick does nothing")
	director.host_ride_input(me.peer_id, "h_test", Vector3(1, 0, 0))
	assert_eq(horse.ride_input, Vector3(1, 0, 0), "its rider's does")
	assert_eq(director.host_ride(me.peer_id, "h_plain"), "no_saddle")
