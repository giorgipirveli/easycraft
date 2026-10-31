extends GutTest
## M3 Task 20a (spec §16 "the dragon you built and fly"): a buddy built with a SADDLE block can be ridden,
## and what it does comes from its shape: wings (blocks sticking out left and right in its upper half, at
## least 2 each side) fly like a dragon, four blocks at the bottom corners (wheels, with a gap between the
## front and back ones) drive like a car, any buddy on water sails like a boat, and anything else is a
## gentle walk mount. Never faster than the M2 paid Fly; getting off never puts anyone inside blocks.

const S := BlockIds.SADDLE
const P := BlockIds.PLANKS


## Blocks from rows of text, one string per layer from the bottom (y 0) up; each layer is rows of z,
## each row x across: "#" planks, "S" the saddle, "." air.
static func _build(layers: Array) -> Dictionary:
	var blocks := {}
	for y in layers.size():
		var rows: Array = layers[y]
		for z in rows.size():
			var row: String = rows[z]
			for x in row.length():
				match row[x]:
					"#":
						blocks[Vector3i(x, y, z)] = P
					"S":
						blocks[Vector3i(x, y, z)] = S
	return blocks


## A dragon: a body 1 wide and 3 long on two legs, wings sticking out 2 blocks each side on its back.
static func _dragon() -> Dictionary:
	return _build([
		["..#..", ".....", "..#.."],   # legs
		["..#..", "..#..", "..#.."],   # the body
		["###.#", "##S##", "##.##"],   # wings left and right, the saddle in the middle
	])


## A car: four wheels at the bottom corners with a gap between front and back, a body and a seat on top.
static func _car() -> Dictionary:
	return _build([
		["#.#", "...", "#.#"],   # wheels
		["###", "###", "###"],   # the body
		["...", ".S.", "..."],   # the seat
	])


func test_no_saddle_no_ride() -> void:
	var blocks := _dragon()
	blocks.erase(RideRules.saddle_of(blocks))
	assert_eq(RideRules.kind_of(blocks), RideRules.Kind.NONE, "a dragon without a saddle is just a buddy")
	assert_false(RideRules.has_saddle(blocks))
	assert_eq(RideRules.kind_of({}), RideRules.Kind.NONE)


func test_wings_fly() -> void:
	assert_eq(RideRules.kind_of(_dragon()), RideRules.Kind.FLY)
	var w := RideRules.wings(_dragon())
	assert_eq((w.left as Array).size(), 6, "two blocks out on the left, in each row")
	assert_eq((w.right as Array).size(), 5)


func test_one_wing_block_a_side_is_not_enough() -> void:
	var blocks := _build([
		[".#.", ".#."],
		["#S#", ".#."],   # one block sticking out each side
	])
	assert_eq(RideRules.kind_of(blocks), RideRules.Kind.WALK)


func test_a_wing_on_one_side_only_does_not_fly() -> void:
	var blocks := _build([
		["..#", "..#"],
		["###", "#S#"],   # two out on the left, none on the right
	])
	assert_eq(RideRules.kind_of(blocks), RideRules.Kind.WALK)


func test_blocks_sticking_out_low_are_not_wings() -> void:
	var blocks := _build([
		["##.##", "##S##"],   # sticking out at the bottom: feet, not wings
		["..#..", "..#.."],
		["..#..", "..#.."],
	])
	assert_ne(RideRules.kind_of(blocks), RideRules.Kind.FLY)


func test_a_plain_box_walks() -> void:
	var blocks := _build([["###", "###"], ["#S#", "###"]])
	assert_eq(RideRules.kind_of(blocks), RideRules.Kind.WALK, "a full bottom is feet, not wheels")


func test_wheels_drive() -> void:
	assert_eq(RideRules.kind_of(_car()), RideRules.Kind.DRIVE)


func test_wheels_need_a_gap_between_front_and_back() -> void:
	var ring := _build([
		["###", "#.#", "###"],   # a ring of walls: the sides have no gap
		["###", "#S#", "###"],
	])
	assert_eq(RideRules.kind_of(ring), RideRules.Kind.WALK, "a hollow house is not a car")


func test_a_table_with_a_saddle_drives() -> void:
	var table := _build([
		["#..#", "....", "....", "#..#"],
		["####", "####", "####", "####"],
		["....", ".S..", "....", "...."],
	])
	assert_eq(RideRules.kind_of(table), RideRules.Kind.DRIVE, "four legs at the corners are wheels")


func test_wings_win_over_wheels() -> void:
	var both := _build([
		["..#.#..", ".......", "..#.#.."],   # wheels under the body
		["..###..", "..###..", "..###.."],
		["###.###", "###S###", "###.###"],   # and wings
	])
	assert_eq(RideRules.kind_of(both), RideRules.Kind.FLY)


func test_a_dragon_built_sideways_is_turned_to_fly_forwards() -> void:
	# The same dragon built with its wings along z: normalise turns the blocks so the wings stick out
	# left and right (its face, -z, looks where it flies) and gives the yaw that keeps its look in the world.
	var sideways := {}
	for p: Vector3i in _dragon():
		sideways[Vector3i(p.z, p.y, p.x)] = _dragon()[p]
	assert_eq(RideRules.kind_of(sideways), RideRules.Kind.FLY, "it flies whichever way it was built")
	var n := RideRules.normalise(sideways)
	assert_true(n.turned)
	var w := RideRules.wings_along(n.blocks, 0)
	assert_false(w.is_empty(), "wings along x after the turn")
	assert_eq((n.blocks as Dictionary).size(), sideways.size())
	# Each block's centre, turned by the yaw, is where it was.
	var size_before := RideRules.size_of(sideways)
	var size_after := RideRules.size_of(n.blocks)
	for p: Vector3i in n.blocks:
		var local := Vector3(p.x + 0.5 - size_after.x * 0.5, p.y, p.z + 0.5 - size_after.z * 0.5)
		var world := Basis(Vector3.UP, n.yaw) * local
		var q := Vector3i(roundi(world.x + size_before.x * 0.5 - 0.5), p.y, roundi(world.z + size_before.z * 0.5 - 0.5))
		assert_eq(sideways.get(q, -1), n.blocks[p], "block %s" % p)
	var plain := RideRules.normalise(_dragon())
	assert_false(plain.turned, "a dragon built along z already flies forwards")
	assert_eq(plain.yaw, 0.0)
	assert_eq(plain.blocks, _dragon())


func test_a_car_built_sideways_is_turned_too() -> void:
	# wheels 3 apart along x and side by side along z: the car drives along x
	var sideways := _build([["#..#", "#..#"], ["####", "####"], ["....", ".S.."]])
	assert_false(RideRules.has_wheels_along(sideways, 2))
	assert_true(RideRules.has_wheels_along(sideways, 0))
	var n := RideRules.normalise(sideways)
	assert_true(n.turned)
	assert_eq(RideRules.kind_of(n.blocks), RideRules.Kind.DRIVE)
	assert_true(RideRules.has_wheels_along(n.blocks, 2), "front and back along z after the turn")


func test_the_saddle_is_the_highest_and_the_seat_is_on_top() -> void:
	var blocks := _car()
	assert_eq(RideRules.saddle_of(blocks), Vector3i(1, 2, 1))
	blocks[Vector3i(0, 1, 0)] = S
	assert_eq(RideRules.saddle_of(blocks), Vector3i(1, 2, 1), "the highest saddle")
	var size := RideRules.size_of(blocks)
	assert_eq(RideRules.seat_offset(blocks, size), Vector3(0.0, 3.0, 0.0), "the rider's feet on top of it, centred")


func test_the_mode_on_water_is_sailing_except_for_flyers() -> void:
	assert_eq(RideRules.mode(RideRules.Kind.WALK, true), RideRules.Kind.SAIL)
	assert_eq(RideRules.mode(RideRules.Kind.DRIVE, true), RideRules.Kind.SAIL)
	assert_eq(RideRules.mode(RideRules.Kind.FLY, true), RideRules.Kind.FLY)
	assert_eq(RideRules.mode(RideRules.Kind.WALK, false), RideRules.Kind.WALK)
	assert_eq(RideRules.mode(RideRules.Kind.DRIVE, false), RideRules.Kind.DRIVE)
	assert_eq(RideRules.mode(RideRules.Kind.NONE, true), RideRules.Kind.NONE)


func test_a_short_line_when_it_wakes() -> void:
	assert_eq(RideRules.wake_line(RideRules.Kind.FLY, false), "Your dragon can fly!")
	assert_eq(RideRules.wake_line(RideRules.Kind.DRIVE, false), "Vroom! A car!")
	assert_eq(RideRules.wake_line(RideRules.Kind.WALK, true), "Ahoy! A boat!")
	assert_ne(RideRules.wake_line(RideRules.Kind.WALK, false), "")
	assert_eq(RideRules.wake_line(RideRules.Kind.NONE, false), "", "no saddle, no line")
	for k in [RideRules.Kind.WALK, RideRules.Kind.FLY, RideRules.Kind.DRIVE, RideRules.Kind.SAIL]:
		assert_lte(RideRules.mount_line(k).split(" ").size(), 8, "short words for early readers")


func test_water_under_a_buddy() -> void:
	var water := func(p: Vector3i) -> int: return BlockIds.WATER if p.y <= 9 and p.y >= 7 else BlockIds.AIR
	assert_true(RideRules.on_water(Vector3(0.5, 9.7, 0.5), water), "floating on the surface")
	assert_true(RideRules.on_water(Vector3(0.5, 8.5, 0.5), water), "in it")
	assert_false(RideRules.on_water(Vector3(0.5, 12.0, 0.5), water), "flying over it")
	assert_almost_eq(RideRules.water_surface(Vector3(0.5, 9.7, 0.5), water), 10.0, 0.001)
	assert_almost_eq(RideRules.water_surface(Vector3(0.5, 7.2, 0.5), water), 10.0, 0.001)
	assert_true(is_nan(RideRules.water_surface(Vector3(0.5, 20.0, 0.5), water)))


# --- Speeds and caps ---

func _run(mode: int, wish: Vector3, vertical: float, seconds: float, yaw := 0.0) -> Dictionary:
	var v := Vector3.ZERO
	var r := {"velocity": v, "yaw": yaw}
	var dt := 1.0 / 60.0
	var top := 0.0
	for i in int(seconds / dt):
		r = RideRules.step(mode, r.velocity, r.yaw, wish, vertical, dt)
		top = maxf(top, Vector2(r.velocity.x, r.velocity.z).length())
	r["top"] = top
	return r


func test_the_top_speeds() -> void:
	var ahead := Vector3(0, 0, -1)
	assert_almost_eq(_run(RideRules.Kind.WALK, ahead, 0.0, 3.0).top, Player.WALK_SPEED * 1.2, 0.01, "the player's speed + 20 %")
	assert_almost_eq(_run(RideRules.Kind.DRIVE, ahead, 0.0, 5.0).top, 10.0, 0.01)
	assert_almost_eq(_run(RideRules.Kind.FLY, ahead, 0.0, 5.0).top, RideRules.SPEED[RideRules.Kind.FLY], 0.01)
	assert_lte(RideRules.SPEED[RideRules.Kind.FLY], 12.0)
	assert_lte(RideRules.SPEED[RideRules.Kind.FLY], Player.FLY_SPEED, "never faster than the M2 paid Fly")
	assert_lt(_run(RideRules.Kind.SAIL, ahead, 0.0, 5.0).top, RideRules.SPEED[RideRules.Kind.DRIVE])
	for mode: int in RideRules.SPEED:
		assert_lte(RideRules.SPEED[mode], Player.FLY_SPEED, "nothing rides faster than paid Fly")


func test_a_dragon_climbs_and_dives_but_holds_its_height_otherwise() -> void:
	var up := _run(RideRules.Kind.FLY, Vector3.ZERO, 1.0, 2.0)
	assert_almost_eq(up.velocity.y, RideRules.FLY_CLIMB, 0.01, "JUMP climbs")
	var down := _run(RideRules.Kind.FLY, Vector3.ZERO, -1.0, 2.0)
	assert_almost_eq(down.velocity.y, -RideRules.FLY_DIVE, 0.01, "CROUCH dives")
	var r := RideRules.step(RideRules.Kind.FLY, Vector3(0, 5, 0), 0.0, Vector3.ZERO, 0.0, 1.0)
	assert_eq(r.velocity.y, 0.0, "no input: it hovers")
	assert_eq(_run(RideRules.Kind.WALK, Vector3.ZERO, 1.0, 1.0).velocity.y, 0.0, "only flyers climb")


func test_caps_even_when_pushed() -> void:
	var fast := Vector3(40, 30, -40)
	for mode: int in RideRules.SPEED:
		var r := RideRules.step(mode, fast, 0.0, Vector3(0, 0, -1), 1.0, 1.0 / 60.0)
		assert_lte(Vector2(r.velocity.x, r.velocity.z).length(), RideRules.SPEED[mode] + 0.001, "mode %d" % mode)
		if mode == RideRules.Kind.FLY:
			assert_lte(r.velocity.y, RideRules.FLY_CLIMB)


func test_a_car_turns_at_its_own_pace() -> void:
	var dt := 1.0 / 60.0
	var r := RideRules.step(RideRules.Kind.DRIVE, Vector3.ZERO, 0.0, Vector3(1, 0, 0), 0.0, dt)
	assert_almost_eq(absf(angle_difference(0.0, r.yaw)), RideRules.TURN[RideRules.Kind.DRIVE] * dt, 0.0001, "a bit per step")
	var round := _run(RideRules.Kind.DRIVE, Vector3(1, 0, 0), 0.0, 3.0)
	assert_almost_eq(round.yaw, atan2(-1.0, 0.0), 0.01, "it ends up facing the stick")
	var turned := RideRules.step(RideRules.Kind.DRIVE, Vector3.ZERO, 0.0, Vector3(0, 0, 1), 0.0, dt)
	var going := Basis(Vector3.UP, turned.yaw) * Vector3.FORWARD
	assert_gt(Vector2(turned.velocity.x, turned.velocity.z).dot(Vector2(going.x, going.z)), -0.001, "a car goes where it faces")


func test_a_walk_mount_goes_where_the_stick_points() -> void:
	var r := _run(RideRules.Kind.WALK, Vector3(1, 0, 0), 0.0, 1.0)
	assert_almost_eq(r.velocity.x, Player.WALK_SPEED * 1.2, 0.01)
	assert_almost_eq(r.velocity.z, 0.0, 0.01)


func test_a_car_bumps_gently_off_a_wall() -> void:
	var v := Vector3(0, 0, -10)
	var back := RideRules.bump(v, Vector3(0, 0, 1))
	assert_gt(back.z, 0.0, "it bounces back")
	assert_lte(back.length(), 10.0 * RideRules.BUMP_BACK + 0.001, "gently")
	var slide := RideRules.bump(Vector3(5, 0, -5), Vector3(0, 0, 1))
	assert_gte(slide.z, 0.0)
	assert_lt(Vector2(slide.x, slide.z).length(), Vector2(5, 5).length(), "slower after a bump")
	assert_eq(RideRules.bump(Vector3(0, 0, 5), Vector3(0, 0, 1)), Vector3(0, 0, 5), "moving away: nothing to bump")


func test_climbs_one_block_never_two() -> void:
	var one := func(p: Vector3i) -> bool: return p.y < 10 or (p.z == -2 and p.y == 10)
	var two := func(p: Vector3i) -> bool: return p.y < 10 or (p.z == -2 and p.y <= 11)
	var feet := Vector3(0.5, 10.0, -0.5)
	assert_eq(RideRules.climb_height(feet, Vector3(0, 0, -1), 1.2, one), 1)
	assert_eq(RideRules.climb_height(feet, Vector3(0, 0, -1), 1.2, two), 2)
	assert_eq(RideRules.climb_height(feet, Vector3(0, 0, 1), 1.2, one), 0, "flat behind")
	assert_true(RideRules.wants_hop(RideRules.Kind.DRIVE, 1))
	assert_true(RideRules.wants_hop(RideRules.Kind.WALK, 1))
	assert_false(RideRules.wants_hop(RideRules.Kind.DRIVE, 2), "a car can't climb more than 1 block")
	assert_false(RideRules.wants_hop(RideRules.Kind.FLY, 1), "a flyer just flies up")
	assert_false(RideRules.wants_hop(RideRules.Kind.DRIVE, 0))


# --- Getting on and off ---

func test_ride_only_near_the_buddy() -> void:
	var center := Vector3(10, 5, 10)
	var size := Vector3i(3, 3, 5)
	assert_true(RideRules.can_mount(Vector3(12.5, 5, 10), center, size), "right beside it")
	assert_true(RideRules.can_mount(Vector3(10, 5, 14.0), center, size))
	assert_false(RideRules.can_mount(Vector3(20, 5, 10), center, size), "too far")
	assert_false(RideRules.can_mount(Vector3(11, 15, 10), center, size), "far above")
	assert_false(RideRules.can_mount(Vector3(NAN, 5, 10), center, size))


func _free_spot(spot: Vector3, is_solid: Callable) -> bool:
	var feet := Vector3i(spot.floor())
	return not is_solid.call(feet) and not is_solid.call(feet + Vector3i.UP)


func test_getting_off_on_open_ground_is_beside_it_on_the_ground() -> void:
	var ground := func(p: Vector3i) -> bool: return p.y < 10
	var spot := RideRules.dismount_spot(Vector3(0.5, 10.0, 0.5), Vector3i(3, 2, 3), 0.0, ground)
	assert_true(_free_spot(spot, ground))
	assert_eq(floori(spot.y), 10, "standing on the ground")
	assert_gt(Vector2(spot.x - 0.5, spot.z - 0.5).length(), 1.5, "beside it, not under it")


func test_getting_off_next_to_a_wall_picks_the_free_side() -> void:
	var walled := func(p: Vector3i) -> bool: return p.y < 10 or p.x <= -2   # a wall on its left
	var spot := RideRules.dismount_spot(Vector3(0.5, 10.0, 0.5), Vector3i(3, 2, 3), 0.0, walled)
	assert_true(_free_spot(spot, walled))
	assert_gt(spot.x, -1.0)


func test_getting_off_in_a_tight_spot_goes_on_top() -> void:
	var tunnel := func(p: Vector3i) -> bool:
		return p.y < 10 or (p.y <= 12 and (absi(p.x) >= 2 or absi(p.z) >= 2))
	var spot := RideRules.dismount_spot(Vector3(0.5, 10.0, 0.5), Vector3i(3, 2, 3), 0.0, tunnel)
	assert_true(_free_spot(spot, tunnel), "never inside blocks: %s" % spot)
	assert_gte(spot.y, 12.0, "on top of the buddy")


func test_getting_off_in_the_air_stays_in_the_air() -> void:
	var sky := func(_p: Vector3i) -> bool: return false
	var spot := RideRules.dismount_spot(Vector3(0.5, 60.0, 0.5), Vector3i(5, 3, 3), 1.0, sky)
	assert_true(_free_spot(spot, sky))
	assert_almost_eq(spot.y, 60.0, 1.01, "beside the dragon (a gentle fall from there)")


func test_getting_off_is_never_inside_blocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2016
	for i in 200:
		var cells := {}
		for n in 60:
			cells[Vector3i(rng.randi_range(-4, 4), rng.randi_range(8, 14), rng.randi_range(-4, 4))] = true
		var solid := func(p: Vector3i) -> bool: return p.y < 8 or cells.has(p)
		var size := Vector3i(rng.randi_range(1, 5), rng.randi_range(1, 4), rng.randi_range(1, 5))
		var spot := RideRules.dismount_spot(Vector3(0.5, 10.0, 0.5), size, rng.randf() * TAU, solid)
		assert_true(spot.is_finite())
		assert_true(_free_spot(spot, solid), "run %d: %s" % [i, spot])


# --- Survivor ---

func test_survivor_a_flight_lasts_until_landing() -> void:
	assert_true(RideRules.ride_over(RideRules.Kind.FLY, false, true, true), "Survivor: landed after flying")
	assert_false(RideRules.ride_over(RideRules.Kind.FLY, false, true, false), "still in the air")
	assert_false(RideRules.ride_over(RideRules.Kind.FLY, false, false, true), "not taken off yet")
	assert_false(RideRules.ride_over(RideRules.Kind.FLY, true, true, true), "Sandbox flies free and lands as it likes")
	assert_false(RideRules.ride_over(RideRules.Kind.DRIVE, false, true, true), "only flights end at landing")


func test_the_host_cleans_a_riders_input() -> void:
	assert_true(RideRules.clean_wish(Vector3(3, 5, 4)).is_equal_approx(Vector3(0.6, 1, 0.8)))
	assert_eq(RideRules.clean_wish(Vector3(NAN, 0, 1)), Vector3.ZERO)
	assert_eq(RideRules.clean_wish(Vector3(INF, 0, 0)), Vector3.ZERO)
	assert_eq(RideRules.clean_wish(Vector3(0, -3, 0)), Vector3(0, -1, 0))
