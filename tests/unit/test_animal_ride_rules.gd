extends GutTest
## Riding a horse or a camel (owner feedback #41, spec §14.19; M3 Task 20a's RIDE and RideRules): a tamed horse
## or camel that got a SADDLE can be ridden; a horse gallops (faster than walking, never faster than the paid
## Fly), a camel treks slowly and keeps its pace in a sandstorm; a ridden animal never walks into water or off a
## big drop, and getting off puts the child beside it, never inside blocks.


func _solid(cells: Dictionary, ground := 10) -> Callable:
	return func(c: Vector3i) -> bool: return cells.get(c, c.y < ground)


func test_only_a_saddled_horse_or_camel_can_be_ridden() -> void:
	assert_eq(AnimalRideRules.kind_of(&"horse", true), RideRules.Kind.GALLOP)
	assert_eq(AnimalRideRules.kind_of(&"camel", true), RideRules.Kind.TREK)
	assert_eq(AnimalRideRules.kind_of(&"horse", false), RideRules.Kind.NONE, "no saddle, no ride")
	assert_eq(AnimalRideRules.kind_of(&"sheep", true), RideRules.Kind.NONE, "a sheep is never ridden")
	assert_eq(AnimalRideRules.kind_of(&"donkey", true), RideRules.Kind.NONE, "a donkey carries a chest instead")
	assert_true(AnimalRideRules.takes_saddle(&"horse"))
	assert_true(AnimalRideRules.takes_saddle(&"camel"))
	assert_false(AnimalRideRules.takes_saddle(&"cow"))
	assert_eq(AnimalRideRules.SADDLE, BlockIds.SADDLE, "M3 Task 20a's saddle, Tilly's")


func test_a_horse_gallops_a_camel_treks_and_neither_beats_paid_fly() -> void:
	var gallop := float(RideRules.SPEED[RideRules.Kind.GALLOP])
	var trek := float(RideRules.SPEED[RideRules.Kind.TREK])
	assert_gt(gallop, Player.WALK_SPEED * 1.4, "a gallop is much faster than walking")
	assert_lt(gallop, Player.FLY_SPEED, "the gallop is capped under the paid Fly")
	assert_gt(trek, Player.WALK_SPEED, "a camel is still a ride")
	assert_lt(trek, gallop, "slow and steady")
	var v := Vector3.ZERO
	var yaw := 0.0
	for i in 600:
		var r := RideRules.step(RideRules.Kind.GALLOP, v, yaw, Vector3(0, 0, -1), 0.0, 1.0 / 60.0)
		v = r.velocity
		yaw = r.yaw
	assert_almost_eq(Vector2(v.x, v.z).length(), gallop, 0.01, "top speed held, never more")
	assert_true(RideRules.wants_hop(RideRules.Kind.GALLOP, 1), "a horse hops a 1-block step")
	assert_false(RideRules.wants_hop(RideRules.Kind.TREK, 2), "never 2")


func test_a_camel_keeps_its_pace_in_a_sandstorm_a_horse_slows() -> void:
	assert_eq(AnimalRideRules.storm_factor(&"camel", 1.0), 1.0, "a camel is steady in a sandstorm")
	assert_almost_eq(AnimalRideRules.storm_factor(&"horse", 1.0), AnimalRideRules.STORM_SLOW, 0.001)
	assert_lt(AnimalRideRules.STORM_SLOW, 0.9)
	assert_eq(AnimalRideRules.storm_factor(&"horse", 0.0), 1.0, "calm weather: full speed")


func test_a_ridden_animal_never_walks_into_water_or_off_a_big_drop() -> void:
	var cells := {}
	var at := func(c: Vector3i) -> int:
		return cells.get(c, BlockIds.STONE if c.y < 10 else BlockIds.AIR)
	assert_true(AnimalRideRules.can_ride_step(Vector3i(1, 10, 0), at), "flat ground")
	cells[Vector3i(1, 9, 0)] = BlockIds.WATER
	assert_false(AnimalRideRules.can_ride_step(Vector3i(1, 10, 0), at), "water under the next step")
	cells.clear()
	for y in range(6, 10):
		cells[Vector3i(2, y, 0)] = BlockIds.AIR   # a hole 4 deep: a jump down is fine
	assert_true(AnimalRideRules.can_ride_step(Vector3i(2, 10, 0), at), "a 4-block drop is fine (no fall damage)")
	for y in range(3, 10):
		cells[Vector3i(3, y, 0)] = BlockIds.AIR   # a cliff
	assert_false(AnimalRideRules.can_ride_step(Vector3i(3, 10, 0), at), "off a cliff: no")


func test_the_rider_sits_on_the_back_and_gets_off_beside_it() -> void:
	var seat := AnimalRideRules.seat_offset(&"horse")
	assert_between(seat.y, 1.2, 1.5, "on a horse's back")
	assert_gt(AnimalRideRules.seat_offset(&"camel").y, seat.y, "higher on a camel's hump")
	var size := AnimalRideRules.size_blocks(&"horse")
	assert_eq(size, Vector3i(1, 2, 2))
	var solid := _solid({})
	var center := Vector3(0.5, 10, 0.5)
	var spot := RideRules.dismount_spot(center, size, 0.0, solid)
	assert_false(solid.call(Vector3i(spot.floor())), "never inside a block")
	assert_true(solid.call(Vector3i(spot.floor()) + Vector3i.DOWN), "on the ground")
	assert_gt(Vector2(spot.x - center.x, spot.z - center.z).length(), 0.9, "beside it")
