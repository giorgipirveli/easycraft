extends GutTest
## M3 Task 20a: a ridden buddy. Its blocks say how it rides (RideRules); a flyer's wings are meshes of their own
## that beat while it is ridden; it keeps ONE compact collision box whatever its shape (owner feedback #9). The
## host moves it with the rider's stick: a dragon flies where the stick points, climbs and dives and never goes
## faster than paid Fly; a car drives on the ground, bumps gently off a wall and climbs one block, never two; on
## water it floats and sails; a stick not heard for a while lets go. Every game puts the rider on the saddle.

const S := BlockIds.SADDLE
const P := BlockIds.PLANKS
const DT := 1.0 / 60.0


class CellWorld:
	extends WorldService
	var cells := {}
	var floor_y := -1000   # every cell below this is stone

	func get_block(pos: Vector3i) -> int:
		if cells.has(pos):
			return cells[pos]
		return BlockIds.STONE if pos.y < floor_y else BlockIds.AIR


var world: CellWorld


func before_each() -> void:
	world = CellWorld.new()
	add_child_autofree(world)
	Session.register_world(world)


func after_each() -> void:
	Session.register_world(null)


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


static func _dragon() -> Dictionary:
	return {Vector3i(2, 0, 0): P, Vector3i(2, 0, 2): P, Vector3i(2, 1, 0): P, Vector3i(2, 1, 1): P, Vector3i(2, 1, 2): P,
		Vector3i(0, 2, 1): P, Vector3i(1, 2, 1): P, Vector3i(2, 2, 1): S, Vector3i(3, 2, 1): P, Vector3i(4, 2, 1): P,
		Vector3i(0, 2, 0): P, Vector3i(1, 2, 0): P, Vector3i(3, 2, 2): P, Vector3i(4, 2, 2): P}


static func _car() -> Dictionary:
	var b := {}
	for x in 3:
		for z in 3:
			b[Vector3i(x, 1, z)] = P
	for c in [Vector3i(0, 0, 0), Vector3i(2, 0, 0), Vector3i(0, 0, 2), Vector3i(2, 0, 2)]:
		b[c] = P
	b[Vector3i(1, 2, 1)] = S
	return b


static func _pony() -> Dictionary:
	return {Vector3i(0, 0, 0): P, Vector3i(0, 1, 0): S}


func _buddy(blocks: Dictionary, pos: Vector3, buddy_name := "Buddy1") -> Buddy:
	var b := Buddy.new()
	b.setup({"flat": Buddy.pack(blocks), "name": "Rider", "owner": 1, "pos": pos, "yaw": 0.0, "id": buddy_name})
	add_child_autofree(b)
	b.set_physics_process(false)   # stepped by hand
	return b


func _ground(top: float, size := Vector3(200, 1, 200), at := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(at.x, top - size.y * 0.5, at.z)
	add_child_autofree(body)
	return body


func _steps(b: Buddy, seconds: float) -> void:
	for i in int(seconds / DT):
		b._physics_process(DT)


func test_its_blocks_say_how_it_rides() -> void:
	assert_eq(_buddy(_dragon(), Vector3(0, 40, 0)).ride_kind, RideRules.Kind.FLY)
	assert_eq(_buddy(_car(), Vector3(5, 40, 0), "Buddy2").ride_kind, RideRules.Kind.DRIVE)
	assert_eq(_buddy(_pony(), Vector3(10, 40, 0), "Buddy3").ride_kind, RideRules.Kind.WALK)
	var plain := _pony()
	plain[Vector3i(0, 1, 0)] = P
	assert_eq(_buddy(plain, Vector3(15, 40, 0), "Buddy4").ride_kind, RideRules.Kind.NONE, "no saddle")


func test_the_seat_is_on_top_of_the_saddle_wherever_it_faces() -> void:
	var b := _buddy(_car(), Vector3(10, 20, 10))
	assert_almost_eq(b.seat_position(), Vector3(10, 23, 10), Vector3.ONE * 0.001)
	var d := _buddy(_dragon(), Vector3(0, 20, 0), "Buddy2")
	d.rotation.y = PI * 0.5
	var seat := d.seat_position()
	assert_almost_eq(seat.y, 23.0, 0.001)
	assert_almost_eq(Vector2(seat.x, seat.z), Vector2(0, 0), Vector2.ONE * 0.001, "the saddle is in the middle")


## Owner feedback #9: one compact box, whatever the shape (a dragon's wings never get colliders).
func test_a_ridden_buddy_keeps_one_compact_box() -> void:
	var wide := _dragon()
	for x in range(-6, 0):
		wide[Vector3i(x, 2, 1)] = P
	for x in range(5, 11):
		wide[Vector3i(x, 2, 1)] = P
	var shifted := {}
	var lo := 6
	for p: Vector3i in wide:
		shifted[p + Vector3i(lo, 0, 0)] = wide[p]
	var b := _buddy(shifted, Vector3(0, 40, 0))
	assert_eq(b.ride_kind, RideRules.Kind.FLY)
	var shapes := b.find_children("*", "CollisionShape3D", true, false)
	assert_eq(shapes.size(), 1, "one shape")
	var box := (shapes[0] as CollisionShape3D).shape as BoxShape3D
	assert_lte(box.size.x, Buddy.MAX_FOOTPRINT)
	assert_lte(box.size.z, Buddy.MAX_FOOTPRINT)


func test_a_dragons_wings_beat_while_it_is_ridden() -> void:
	var b := _buddy(_dragon(), Vector3(0, 40, 0))
	assert_eq(b._wings.size(), 2, "left and right wings on hinges")
	assert_eq(_buddy(_car(), Vector3(8, 40, 0), "Buddy2")._wings.size(), 0, "a car has no wings")
	b.set_process(false)
	b._process(0.1)
	assert_eq(b._wings[0].rotation.z, 0.0, "resting")
	b.rider_peer = 7
	b.ride_mode = RideRules.Kind.FLY
	var seen := []
	for i in 8:
		b._process(0.05)
		seen.append(snappedf(b._wings[1].rotation.z, 0.01))
	assert_gt(seen.max(), 0.2, "up ...")
	assert_lt(seen.min(), 0.3, "... and down")
	assert_almost_eq(b._wings[0].rotation.z, -b._wings[1].rotation.z, 0.0001, "both together, mirrored")


func test_the_host_flies_a_ridden_dragon_where_the_stick_points() -> void:
	var b := _buddy(_dragon(), Vector3(0, 40, 0))
	b.start_ride(7)
	assert_eq(b.ride_mode, RideRules.Kind.FLY)
	var start := b.global_position
	var top := 0.0
	for i in 120:
		b.set_ride_input(Vector3(0, 1, -1))   # ahead and up, heard every step
		b._physics_process(DT)
		top = maxf(top, Vector2(b.velocity.x, b.velocity.z).length())
	assert_lt(b.global_position.z, start.z - 8.0, "it flew ahead")
	assert_gt(b.global_position.y, start.y + 5.0, "and climbed (no gravity while flying)")
	assert_lte(top, Player.FLY_SPEED + 0.001, "never faster than paid Fly")
	for i in 60:
		b.set_ride_input(Vector3(0, -1, 0))
		b._physics_process(DT)
	assert_almost_eq(b.velocity.y, -RideRules.FLY_DIVE, 0.01, "CROUCH dives")


func test_a_stick_not_heard_for_a_while_lets_go() -> void:
	var b := _buddy(_dragon(), Vector3(0, 40, 0))
	b.start_ride(7)
	for i in 60:
		b.set_ride_input(Vector3(0, 0, -1))
		b._physics_process(DT)
	assert_gt(b.velocity.length(), 5.0)
	_steps(b, RideRules.INPUT_STALE + 2.0)   # the rider's game went quiet
	assert_almost_eq(b.velocity.length(), 0.0, 0.01, "it stops by itself")


func test_nobody_steers_before_the_first_stick_arrives() -> void:
	var b := _buddy(_car(), Vector3(0, 10.05, 0))
	_ground(10.0)
	await get_tree().physics_frame
	b.start_ride(7)
	b.ride_input = Vector3(0, 0, -1)   # not through set_ride_input: never heard
	_steps(b, 0.5)
	assert_lt(Vector2(b.velocity.x, b.velocity.z).length(), 0.01)


func test_a_car_drives_on_the_ground_and_bumps_gently_off_a_wall() -> void:
	world.floor_y = 10
	_ground(10.0)
	for x in range(-4, 5):   # a wall 2 blocks high across the way at z -9
		for y in [10, 11]:
			world.cells[Vector3i(x, y, -9)] = BlockIds.STONE
	_ground(12.0, Vector3(9, 2, 1), Vector3(0.5, 0, -8.5))
	var b := _buddy(_car(), Vector3(0.5, 10.05, 0.5))
	await get_tree().physics_frame
	b.start_ride(7)
	var bumped := false
	for i in 240:
		b.set_ride_input(Vector3(0, 0, -1))
		b._physics_process(DT)
		if b.velocity.z > 0.5:
			bumped = true
		assert_gt(b.global_position.z, -8.0 - 0.1, "never through the wall")
		assert_lte(Vector2(b.velocity.x, b.velocity.z).length(), 10.0 + 0.001, "a car's top speed")
	assert_true(bumped, "it bounced back off the wall")
	assert_lt(b.global_position.y, 11.0, "a 2-block wall: no climbing")


func test_a_car_climbs_a_one_block_step() -> void:
	world.floor_y = 10
	_ground(10.0)
	for x in range(-4, 5):   # a step 1 block high from z -6 on
		for z in range(-40, -5):
			world.cells[Vector3i(x, 10, z)] = BlockIds.STONE
	_ground(11.0, Vector3(9, 1, 35), Vector3(0.5, 0, -23.5))
	var b := _buddy(_car(), Vector3(0.5, 10.05, 0.5))
	await get_tree().physics_frame
	b.start_ride(7)
	for i in 240:
		b.set_ride_input(Vector3(0, 0, -1))
		b._physics_process(DT)
	assert_lt(b.global_position.z, -10.0, "it drove on, up the step")
	assert_gt(b.global_position.y, 10.9, "on top of it")


func test_on_water_it_floats_and_sails() -> void:
	for x in range(-6, 7):
		for z in range(-30, 7):
			for y in range(7, 10):
				world.cells[Vector3i(x, y, z)] = BlockIds.WATER
	_ground(7.0)   # the lake's bed
	var b := _buddy(_pony(), Vector3(0.5, 7.05, 0.5))
	await get_tree().physics_frame
	b.start_ride(7)
	assert_eq(b.ride_mode, RideRules.Kind.SAIL, "a walker on water is a boat")
	for i in 240:
		b.set_ride_input(Vector3(0, 0, -1))
		b._physics_process(DT)
	assert_almost_eq(b.global_position.y, 10.0 - RideRules.DRAFT, 0.15, "floating on the top")
	assert_lt(b.global_position.z, -5.0, "sailing ahead")
	assert_lte(Vector2(b.velocity.x, b.velocity.z).length(), RideRules.SPEED[RideRules.Kind.SAIL] + 0.001)


## A dragon diving onto a lake stops at the water's top (it floats there: landed), never on the lake's bed with
## its rider under water (found by the ride smoke run: a dive into the sea landed on the sea floor).
func test_a_dragon_lands_on_water_not_under_it() -> void:
	for x in range(-6, 7):
		for z in range(-6, 7):
			for y in range(0, 10):
				world.cells[Vector3i(x, y, z)] = BlockIds.WATER
	_ground(0.0)   # the lake's bed, deep down
	var b := _buddy(_dragon(), Vector3(0.5, 16.0, 0.5))
	await get_tree().physics_frame
	b.start_ride(7)
	assert_false(b.resting(), "in the air")
	for i in 240:
		b.set_ride_input(Vector3(0, -1, 0))   # CROUCH: dive
		b._physics_process(DT)
	assert_almost_eq(b.global_position.y, 10.0 - RideRules.DRAFT, 0.2, "on the water's top")
	assert_true(b.resting(), "landed on the water")
	assert_eq(b.ride_mode, RideRules.Kind.FLY, "still a flyer: JUMP takes off again")
	for i in 60:
		b.set_ride_input(Vector3(0, 1, 0))
		b._physics_process(DT)
	assert_gt(b.global_position.y, 12.0, "and up again")


func test_every_game_puts_the_rider_on_the_saddle() -> void:
	var me: Player = load("res://entities/player/player.tscn").instantiate()
	me.name = str(multiplayer.get_unique_id())
	me.world = world
	add_child_autofree(me)
	me.set_physics_process(false)
	me.viewer.free()
	var friend: Player = load("res://entities/player/player.tscn").instantiate()
	friend.name = "5"
	friend.world = world
	add_child_autofree(friend)
	friend.set_physics_process(false)
	var b := _buddy(_car(), Vector3(3, 20, 3))
	var seen: Array = []
	me.ride_changed.connect(func(on: bool) -> void: seen.append(on))
	b.rider_peer = me.peer_id
	assert_eq(me.riding, b)
	assert_true(me.is_riding())
	assert_eq(seen, [true])
	me._process(0.016)
	assert_almost_eq(me.global_position, b.seat_position(), Vector3.ONE * 0.001, "sitting on the saddle")
	assert_eq(me.avatar.emote(), &"sit")
	b.rider_peer = 0
	assert_false(me.is_riding())
	assert_eq(seen, [true, false])
	b.rider_peer = 5   # a friend (another game's player) rides: this game shows them on the saddle too
	friend._process(0.016)
	assert_almost_eq(friend.global_position, b.seat_position(), Vector3.ONE * 0.001)


func test_a_rider_is_let_go_when_the_buddy_goes() -> void:
	var me: Player = load("res://entities/player/player.tscn").instantiate()
	me.name = str(multiplayer.get_unique_id())
	me.world = world
	add_child_autofree(me)
	me.set_physics_process(false)
	me.viewer.free()
	var b := _buddy(_car(), Vector3(3, 20, 3))
	b.rider_peer = me.peer_id
	assert_true(me.is_riding())
	b.free()
	assert_false(me.is_riding())
	assert_null(me.riding)


## Save and load: the saddle and the buddy keep their shape (and so how it rides).
func test_the_saddle_and_its_shape_are_saved() -> void:
	var b := _buddy(_dragon(), Vector3(3, 20, 3))
	b.rotation.y = 1.25
	var m := WorldMeta.new_random()
	m.buddies = [b.to_save()]
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.buddies.size(), 1)
	var blocks := {}
	for e: Array in back.buddies[0].blocks:
		blocks[Vector3i(e[0], e[1], e[2])] = e[3]
	assert_eq(blocks, _dragon(), "every block, the saddle too")
	assert_almost_eq(float(back.buddies[0].yaw), 1.25, 0.001)
	var again := _buddy(blocks, Vector3(3, 20, 3), "Buddy2")
	assert_eq(again.ride_kind, RideRules.Kind.FLY, "it still flies")
	assert_eq(again._wings.size(), 2)
