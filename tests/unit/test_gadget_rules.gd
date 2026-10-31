extends GutTest
## The action kit's gadgets (M3 Task 14a, spec §13.3, §14.13): the glider, the grappling hook, ziplines,
## instant builds and the orbs. Pure rules: speeds, ranges, cooldowns, walls that stop a hook, the ride
## down a line, what a build costs, and how the orbs push and make monsters dance (bosses only a little).

const DT := 1.0 / 60.0
const GROUND_Y := 10   # stone below y = 10 in the little worlds below


## Stone below GROUND_Y, air above, plus `extra` cells (cell -> id).
func _world(extra: Dictionary = {}) -> Callable:
	return func(p: Vector3i) -> int:
		if extra.has(p):
			return extra[p]
		return BlockIds.STONE if p.y < GROUND_Y else BlockIds.AIR


func _solid(block_at: Callable) -> Callable:
	return func(p: Vector3i) -> bool: return BlockIds.is_solid(block_at.call(p))


# --- Ids and kinds -----------------------------------------------------------------------------------

func test_gadgets_own_ids_400_to_407_and_two_blocks_on_page_10() -> void:
	assert_eq([ItemIds.GLIDER, ItemIds.GRAPPLE, ItemIds.BUILD_WALL, ItemIds.BUILD_FLOOR, ItemIds.BUILD_RAMP,
		ItemIds.BUILD_FORT, ItemIds.IMPULSE_ORB, ItemIds.DANCE_ORB], [400, 401, 402, 403, 404, 405, 406, 407])
	assert_eq(BlockIds.ZIPLINE_POST, 210)
	assert_eq(BlockIds.LAUNCH_PAD, 211)
	assert_eq(BlockLibrary.page_of(BlockIds.ZIPLINE_POST), 10, "the portals' page (208-223)")
	assert_eq(BlockLibrary.page_of(BlockIds.LAUNCH_PAD), 10)
	for id in ItemIds.GADGETS:
		assert_true(GadgetRules.is_gadget(id), ItemIds.display_name(id))
		assert_true(ItemIds.is_item(id))
		assert_false(BlockIds.is_valid(id), "no block takes a gadget's id")
	assert_false(GadgetRules.is_gadget(ItemIds.SWORD))
	assert_true(GadgetRules.is_orb(ItemIds.IMPULSE_ORB))
	assert_true(GadgetRules.is_orb(ItemIds.DANCE_ORB))
	assert_false(GadgetRules.is_orb(ItemIds.GRAPPLE))
	for id in [ItemIds.BUILD_WALL, ItemIds.BUILD_FLOOR, ItemIds.BUILD_RAMP, ItemIds.BUILD_FORT]:
		assert_true(GadgetRules.is_build(id))
	assert_false(GadgetRules.is_build(ItemIds.GLIDER))


func test_our_own_names_for_children() -> void:
	for id in ItemIds.GADGETS:
		assert_ne(ItemIds.display_name(id), "", str(id))
		assert_lte(ItemIds.display_name(id).split(" ").size(), 2, "short: %s" % ItemIds.display_name(id))
	assert_eq(BlockIds.display_name(BlockIds.ZIPLINE_POST), "Zipline Post")
	assert_eq(BlockIds.display_name(BlockIds.LAUNCH_PAD), "Launch Pad")


# --- Glider --------------------------------------------------------------------------------------------

func test_sandbox_always_has_a_glider_and_survivor_needs_one_in_the_bag() -> void:
	assert_true(GadgetRules.has_glider(true, 0), "Sandbox: unlimited")
	assert_false(GadgetRules.has_glider(false, 0))
	assert_true(GadgetRules.has_glider(false, 1))


func test_the_air_under_the_feet_is_counted_up_to_a_limit() -> void:
	var solid := _solid(_world())
	assert_eq(GadgetRules.air_below(Vector3(0.5, GROUND_Y, 0.5), solid), 0, "standing")
	assert_eq(GadgetRules.air_below(Vector3(0.5, GROUND_Y + 2.0, 0.5), solid), 2)
	assert_eq(GadgetRules.air_below(Vector3(0.5, GROUND_Y + 40.0, 0.5), solid), GadgetRules.GLIDE_MIN_AIR, "counts no further")


func test_a_glider_opens_only_in_the_air_with_room_below_while_walking() -> void:
	var dry := SwimRules.State.DRY
	assert_true(GadgetRules.can_open_glider(false, true, dry, GadgetRules.GLIDE_MIN_AIR))
	assert_false(GadgetRules.can_open_glider(true, true, dry, GadgetRules.GLIDE_MIN_AIR), "on the ground")
	assert_false(GadgetRules.can_open_glider(false, true, dry, GadgetRules.GLIDE_MIN_AIR - 1), "too low")
	assert_false(GadgetRules.can_open_glider(false, false, dry, GadgetRules.GLIDE_MIN_AIR), "flying or ghost")
	assert_false(GadgetRules.can_open_glider(false, true, SwimRules.State.SWIMMING, GadgetRules.GLIDE_MIN_AIR), "swimming")


func test_jump_in_the_air_opens_it_once_every_air_jump_is_used() -> void:
	assert_false(GadgetRules.glide_on_jump(1, 3), "the double jump comes first")
	assert_false(GadgetRules.glide_on_jump(2, 3), "and the triple jump")
	assert_true(GadgetRules.glide_on_jump(3, 3))
	assert_true(GadgetRules.glide_on_jump(2, 2), "a double-jump player glides after two")


func test_the_glide_falls_at_most_3_m_a_second_within_half_a_second() -> void:
	var v := Vector3(0, -20, 0)
	var t := 0.0
	while t < 0.5:
		v = GadgetRules.glide_velocity(v, Vector3.ZERO, DT, Player.GRAVITY)
		t += DT
	assert_almost_eq(v.y, -GadgetRules.GLIDE_FALL_SPEED, 0.01)
	for i in 300:
		v = GadgetRules.glide_velocity(v, Vector3(1, 0, 0), DT, Player.GRAVITY)
		assert_gte(v.y, -GadgetRules.GLIDE_FALL_SPEED - 0.001, "slow descent")
	assert_lte(GadgetRules.GLIDE_FALL_SPEED, 3.0)


func test_a_rising_glider_slows_with_gravity_and_then_floats_down() -> void:
	var v := Vector3(0, 12, 0)   # a launch pad's throw
	var top := false
	for i in 120:
		var before := v.y
		v = GadgetRules.glide_velocity(v, Vector3.ZERO, DT, Player.GRAVITY)
		assert_lte(v.y, before + 0.0001, "never climbs")
		top = top or v.y <= 0.0
	assert_true(top)
	assert_almost_eq(v.y, -GadgetRules.GLIDE_FALL_SPEED, 0.01)


func test_the_stick_steers_and_without_it_the_glide_drifts_on() -> void:
	var v := Vector3(0, -3, 0)
	for i in 120:
		v = GadgetRules.glide_velocity(v, Vector3(0, 0, -1), DT, Player.GRAVITY)
	assert_almost_eq(v.z, -GadgetRules.GLIDE_SPEED, 0.01, "steered forward at gliding speed")
	for i in 120:
		v = GadgetRules.glide_velocity(v, Vector3.ZERO, DT, Player.GRAVITY)
	assert_almost_eq(v.z, -GadgetRules.GLIDE_IDLE_SPEED, 0.01, "let go: drifts on the same way, slower")
	assert_almost_eq(v.x, 0.0, 0.001)
	assert_gt(GadgetRules.GLIDE_SPEED / GadgetRules.GLIDE_FALL_SPEED, 2.5, "a glide goes far: more than 2.5 across per 1 down")


func test_a_glide_ends_on_the_ground_and_in_water() -> void:
	assert_true(GadgetRules.glide_ends(true, SwimRules.State.DRY, true))
	assert_true(GadgetRules.glide_ends(false, SwimRules.State.SWIMMING, true))
	assert_true(GadgetRules.glide_ends(false, SwimRules.State.DRY, false), "flying or a ghost")
	assert_false(GadgetRules.glide_ends(false, SwimRules.State.DRY, true))


func test_glider_looks_have_a_free_default_and_bad_values_fall_back() -> void:
	assert_eq(GadgetRules.GLIDER_LOOKS[0], &"classic")
	assert_gte(GadgetRules.GLIDER_LOOKS.size(), 3)
	assert_eq(GadgetRules.glider_look(-1), 0)
	assert_eq(GadgetRules.glider_look(99), 0)
	assert_eq(GadgetRules.glider_look(1), 1)


# --- Grappling hook ------------------------------------------------------------------------------------

func test_the_hook_holds_only_onto_blocks() -> void:
	var solid := _solid(_world())
	var r := GadgetRules.hook_check(Vector3(0.5, 11.6, 0.5), Vector3i(0, 14, -5), solid)
	assert_false(r.ok, "air")
	assert_eq(r.error, "block")
	assert_ne(GadgetRules.hook_message("block"), "")


func test_the_hook_reaches_24_blocks_and_no_further() -> void:
	var eye := Vector3(0.5, 11.6, 0.5)
	var near := _solid(_world({Vector3i(0, 11, -20): BlockIds.STONE}))
	var r := GadgetRules.hook_check(eye, Vector3i(0, 11, -20), near)
	assert_true(r.ok, "20 blocks away")
	var far_world := _solid(_world({Vector3i(0, 11, -30): BlockIds.STONE}))
	r = GadgetRules.hook_check(eye, Vector3i(0, 11, -30), far_world)
	assert_false(r.ok, "30 blocks away")
	assert_eq(r.error, "far")
	assert_eq(GadgetRules.HOOK_RANGE, 24.0)


func test_a_wall_in_between_stops_the_hook_it_never_goes_through() -> void:
	var eye := Vector3(0.5, 11.6, 0.5)
	var world := _world({Vector3i(0, 11, -10): BlockIds.STONE, Vector3i(0, 11, -5): BlockIds.BRICK})
	var r := GadgetRules.hook_check(eye, Vector3i(0, 11, -10), _solid(world))
	assert_false(r.ok)
	assert_eq(r.error, "wall")
	world = _world({Vector3i(0, 11, -10): BlockIds.STONE, Vector3i(0, 11, -5): BlockIds.WATER})
	assert_true(GadgetRules.hook_check(eye, Vector3i(0, 11, -10), _solid(world)).ok, "water does not stop it")


func test_the_hook_point_is_on_the_face_that_faces_the_player() -> void:
	var eye := Vector3(0.5, 11.6, 0.5)
	var r := GadgetRules.hook_check(eye, Vector3i(0, 11, -10), _solid(_world({Vector3i(0, 11, -10): BlockIds.STONE})))
	assert_true(r.ok)
	assert_almost_eq((r.point as Vector3).z, -9.0, 0.001, "the near face (z = -9)")
	assert_almost_eq((r.point as Vector3).x, 0.5, 0.001)


func test_the_hook_waits_a_second_between_throws() -> void:
	assert_true(GadgetRules.hook_ready(-1, 0))
	assert_false(GadgetRules.hook_ready(1000, 1500))
	assert_true(GadgetRules.hook_ready(1000, 2000))
	assert_eq(GadgetRules.HOOK_COOLDOWN, 1.0)


func test_the_pull_flies_straight_at_the_point_and_arrives_with_a_hop() -> void:
	var chest := Vector3(0, 11, 0)
	var point := Vector3(0, 15, -10)
	var v := GadgetRules.hook_velocity(chest, point)
	assert_almost_eq(v.length(), GadgetRules.HOOK_SPEED, 0.001)
	assert_almost_eq(v.normalized().dot((point - chest).normalized()), 1.0, 0.0001)
	assert_false(GadgetRules.hook_arrived(chest, point))
	assert_true(GadgetRules.hook_arrived(point + Vector3(0, 0, 1.0), point))
	var hop := GadgetRules.hook_release(point + Vector3(0, -1, 1), point)
	assert_gt(hop.y, 4.0, "a hop up at the end: onto a ledge")
	assert_lt(hop.z, 0.0, "and on towards the wall")


# --- Ziplines --------------------------------------------------------------------------------------------

func test_the_line_hangs_above_its_posts() -> void:
	var a := GadgetRules.attach_point(Vector3i(3, 10, 4))
	assert_eq(a, Vector3(3.5, 11.0 + GadgetRules.ZIP_ATTACH, 4.5))
	assert_gte(GadgetRules.ZIP_ATTACH - GadgetRules.ZIP_HANG + 1.0, 1.0,
		"a rider on a line between two posts on flat ground hangs clear of the grass")


func test_posts_link_up_to_48_blocks_apart() -> void:
	assert_true(GadgetRules.can_link(Vector3i(0, 10, 0), Vector3i(0, 10, 48)))
	assert_false(GadgetRules.can_link(Vector3i(0, 10, 0), Vector3i(0, 10, 49)))
	assert_false(GadgetRules.can_link(Vector3i(0, 10, 0), Vector3i(0, 10, 1)), "too short to ride")


func test_a_line_through_a_hill_is_not_clear() -> void:
	var from := GadgetRules.attach_point(Vector3i(0, 10, 0))
	var to := GadgetRules.attach_point(Vector3i(0, 10, 20))
	assert_true(GadgetRules.line_clear(from, to, _solid(_world())))
	assert_false(GadgetRules.line_clear(from, to, _solid(_world({Vector3i(0, 13, 10): BlockIds.DIRT}))))


func test_riding_down_speeds_up_and_riding_up_crawls_but_never_stops() -> void:
	var down := Vector3(0, -0.5, -1).normalized()
	var up := Vector3(0, 0.5, -1).normalized()
	var s := GadgetRules.ZIP_START_SPEED
	for i in 60:
		s = GadgetRules.zip_speed(s, down, DT)
	assert_gt(s, GadgetRules.ZIP_START_SPEED + 3.0, "gravity pulls a rider down the line")
	for i in 600:
		s = GadgetRules.zip_speed(s, down, DT)
	assert_eq(s, GadgetRules.ZIP_MAX_SPEED, "never faster than the top speed")
	s = GadgetRules.ZIP_START_SPEED
	for i in 600:
		s = GadgetRules.zip_speed(s, up, DT)
	assert_eq(s, GadgetRules.ZIP_MIN_SPEED, "uphill it crawls")
	assert_gt(GadgetRules.ZIP_MIN_SPEED, 0.0, "a rider is never stuck on a line")


func test_the_rider_hangs_under_the_line_and_gets_off_before_the_far_post() -> void:
	var from := Vector3(0.5, 13.0, 0.5)
	var to := Vector3(0.5, 13.0, 20.5)
	var feet := GadgetRules.zip_feet(from, to, 5.0)
	assert_eq(feet, Vector3(0.5, 13.0 - GadgetRules.ZIP_HANG, 5.5))
	assert_almost_eq(GadgetRules.zip_ride_end(from, to), 20.0 - GadgetRules.ZIP_GAP, 0.001)
	var off := GadgetRules.zip_leave(from, to, 10.0)
	assert_almost_eq(off.z, 10.0, 0.001, "slides off with its speed")


func test_a_rider_grabs_a_line_only_near_its_post() -> void:
	var post := Vector3i(10, 10, 10)
	assert_true(GadgetRules.can_grab(Vector3(12.0, 10.0, 10.5), post))
	assert_false(GadgetRules.can_grab(Vector3(20.0, 10.0, 10.5), post))
	assert_false(GadgetRules.can_grab(Vector3(10.5, 30.0, 10.5), post), "far below or above it")


func test_a_body_fits_where_no_block_is() -> void:
	var solid := _solid(_world({Vector3i(0, 11, 0): BlockIds.PLANKS}))
	assert_true(GadgetRules.body_fits(Vector3(0.5, 13.0, 0.5), solid))
	assert_false(GadgetRules.body_fits(Vector3(0.5, 10.5, 0.5), solid), "a block at the chest")
	assert_false(GadgetRules.body_fits(Vector3(0.5, 9.5, 0.5), solid), "in the ground")


# --- Orbs ----------------------------------------------------------------------------------------------

func test_an_orb_flies_in_an_arc_and_bursts_on_the_ground() -> void:
	var from := Vector3(0.5, 11.6, 0.5)
	var v := GadgetRules.orb_velocity(Vector3(0, 0, -1))
	assert_almost_eq(v.length(), GadgetRules.ORB_SPEED, 0.001)
	assert_gt(v.y, 0.0, "thrown a little upwards")
	var path := GadgetRules.orb_path(from, v, _solid(_world()))
	var p: Vector3 = path.point
	assert_almost_eq(p.y, float(GROUND_Y), 0.2, "on the ground")
	assert_lt(p.z, -5.0, "some way ahead")
	assert_gt(float(path.time), 0.2)
	assert_lt(float(path.time), GadgetRules.ORB_MAX_TIME)


func test_an_orb_thrown_at_a_wall_bursts_at_the_wall() -> void:
	var wall := {}
	for y in range(GROUND_Y, GROUND_Y + 10):
		for x in range(-3, 4):
			wall[Vector3i(x, y, -4)] = BlockIds.BRICK
	var path := GadgetRules.orb_path(Vector3(0.5, 11.6, 0.5), GadgetRules.orb_velocity(Vector3(0, 0, -1)), _solid(_world(wall)))
	assert_gt((path.point as Vector3).z, -3.1, "it never passes through the wall")


func test_an_orb_thrown_off_a_cliff_bursts_after_its_longest_flight() -> void:
	var nothing := func(_p: Vector3i) -> bool: return false
	var path := GadgetRules.orb_path(Vector3.ZERO, GadgetRules.orb_velocity(Vector3.FORWARD), nothing)
	assert_eq(float(path.time), GadgetRules.ORB_MAX_TIME)


func test_the_boing_orb_pushes_away_and_harder_close_by() -> void:
	var center := Vector3(0, 10, 0)
	var near := GadgetRules.impulse_push(center, Vector3(1, 10, 0))
	var far := GadgetRules.impulse_push(center, Vector3(4, 10, 0))
	assert_gt(near.x, 0.0, "away from the burst")
	assert_gt(near.length(), far.length())
	assert_gt(near.y, 0.0, "a little up")
	assert_eq(GadgetRules.impulse_push(center, Vector3(9, 10, 0)), Vector3.ZERO, "outside the bubble")
	var under := GadgetRules.impulse_push(center, center)
	assert_gt(under.length(), 1.0, "right on it: still pushed")


func test_players_in_the_burst_bounce_up_and_are_never_hurt() -> void:
	var b := GadgetRules.impulse_bounce(Vector3(0, 10, 0), Vector3(2, 10, 0))
	assert_gt(b.y, 10.0, "a big bounce")
	assert_gt(b.x, 0.0)
	assert_eq(GadgetRules.impulse_bounce(Vector3(0, 10, 0), Vector3(20, 10, 0)), Vector3.ZERO)
	assert_eq(GadgetRules.ORB_DAMAGE, 0, "orbs never hurt anyone")


func test_the_dance_bubble_is_5_blocks() -> void:
	assert_eq(GadgetRules.ORB_RADIUS, 5.0)
	assert_true(GadgetRules.in_bubble(Vector3.ZERO, Vector3(4.9, 0, 0)))
	assert_false(GadgetRules.in_bubble(Vector3.ZERO, Vector3(5.1, 0, 0)))


func test_monsters_dance_5_s_and_bosses_2_s_once_in_20_s() -> void:
	assert_eq(GadgetRules.dance_seconds(false, -1.0, 0.0), 5.0)
	assert_eq(GadgetRules.dance_seconds(false, 3.0, 4.0), 5.0, "monsters: every time")
	assert_eq(GadgetRules.dance_seconds(true, -1.0, 100.0), 2.0, "a boss's first dance")
	assert_eq(GadgetRules.dance_seconds(true, 100.0, 110.0), 0.0, "not again within 20 s")
	assert_eq(GadgetRules.dance_seconds(true, 100.0, 120.0), 2.0)


func test_orbs_wait_a_second_between_throws() -> void:
	assert_true(GadgetRules.orb_ready(-1, 0))
	assert_false(GadgetRules.orb_ready(0, 999))
	assert_true(GadgetRules.orb_ready(0, 1000))


# --- Instant builds ------------------------------------------------------------------------------------

func test_a_quick_wall_stands_two_blocks_in_front_facing_the_player() -> void:
	var a := GadgetRules.build_anchor(Vector3(0.5, 10.0, 0.5), 0.0, ItemIds.BUILD_WALL)   # yaw 0 looks along -Z
	assert_eq(a.forward, Vector3i(0, 0, -1))
	assert_eq(a.anchor, Vector3i(0, 10, -2))
	var cells := GadgetRules.build_cells(ItemIds.BUILD_WALL, a.anchor, a.forward)
	assert_eq(cells.size(), 12, "3 wide and 4 high")
	for c: Array in cells:
		assert_eq((c[0] as Vector3i).z, -2, "one flat wall across the way")
		assert_eq(c[1], BlockIds.PLANKS)


func test_a_quick_ramp_rises_away_from_the_player() -> void:
	var a := GadgetRules.build_anchor(Vector3(0.5, 10.0, 0.5), PI, ItemIds.BUILD_RAMP)   # looking along +Z
	var by_z := {}
	for c: Array in GadgetRules.build_cells(ItemIds.BUILD_RAMP, a.anchor, a.forward):
		var p: Vector3i = c[0]
		by_z[p.z] = maxi(int(by_z.get(p.z, -1000)), p.y)
	var zs := by_z.keys()
	zs.sort()
	assert_eq(zs.size(), 4, "four steps")
	for i in range(1, zs.size()):
		assert_eq(by_z[zs[i]], by_z[zs[i - 1]] + 1, "one block higher each step")
	assert_eq(zs[0], 1, "it starts right in front")


func test_a_quick_floor_fills_the_ground_in_front() -> void:
	var a := GadgetRules.build_anchor(Vector3(0.5, 10.0, 0.5), 0.0, ItemIds.BUILD_FLOOR)
	var cells := GadgetRules.build_cells(ItemIds.BUILD_FLOOR, a.anchor, a.forward)
	assert_eq(cells.size(), 9)
	for c: Array in cells:
		assert_eq((c[0] as Vector3i).y, 9, "at the level of the ground under the feet")


func test_a_quick_fort_has_a_door_facing_the_player() -> void:
	var a := GadgetRules.build_anchor(Vector3(0.5, 10.0, 0.5), 0.0, ItemIds.BUILD_FORT)
	var cells := {}
	for c: Array in GadgetRules.build_cells(ItemIds.BUILD_FORT, a.anchor, a.forward):
		cells[c[0]] = c[1]
	assert_false(cells.has(a.anchor), "the door")
	assert_false(cells.has(a.anchor + Vector3i.UP))
	assert_true(cells.has(a.anchor + Vector3i(1, 0, 0)), "the wall beside the door")
	assert_false(cells.has(a.anchor + Vector3i(0, 0, -2)), "room inside")
	assert_true(cells.has(a.anchor + Vector3i(0, 0, -4)), "the back wall")
	assert_gt(cells.size(), 40)


func test_only_empty_cells_are_built() -> void:
	var a := GadgetRules.build_anchor(Vector3(0.5, 10.0, 0.5), 0.0, ItemIds.BUILD_WALL)
	var cells := GadgetRules.build_cells(ItemIds.BUILD_WALL, a.anchor, a.forward)
	var world := _world({Vector3i(0, 10, -2): BlockIds.BRICK, Vector3i(1, 10, -2): BlockIds.WATER})
	var free := GadgetRules.empty_cells(cells, world)
	assert_eq(free.size(), 11, "the brick stays; water is filled")
	for c: Array in free:
		assert_ne(c[0], Vector3i(0, 10, -2))


func test_builds_use_planks_then_stone_and_say_what_is_missing() -> void:
	assert_eq(GadgetRules.build_material(12, 0, 12), BlockIds.PLANKS)
	assert_eq(GadgetRules.build_material(5, 30, 12), BlockIds.STONE, "not enough planks: stone")
	assert_eq(GadgetRules.build_material(5, 5, 12), 0, "short of both")
	assert_eq(GadgetRules.short_message(12), "Need 12 Planks!")
	var stone := GadgetRules.with_material([[Vector3i.ZERO, BlockIds.PLANKS]], BlockIds.STONE)
	assert_eq(stone[0][1], BlockIds.STONE)


func test_builds_wait_a_moment_between_taps() -> void:
	assert_true(GadgetRules.build_ready(-1, 0))
	assert_false(GadgetRules.build_ready(0, 100))
	assert_true(GadgetRules.build_ready(0, int(GadgetRules.BUILD_COOLDOWN * 1000.0)))


# --- Launch pad ------------------------------------------------------------------------------------------

func test_a_launch_pad_is_a_pad_that_throws_higher_than_a_bounce_pad() -> void:
	assert_true(PadRules.is_pad(BlockIds.LAUNCH_PAD))
	var pads := PadRules.new()
	var fired := pads.touch(BlockIds.LAUNCH_PAD, Vector3(3, 0, 0), Vector3.FORWARD)
	assert_eq(fired, BlockIds.LAUNCH_PAD)
	var v := pads.apply(Vector3(3, 0, 0), fired)
	assert_eq(v.y, PadRules.LAUNCH_PAD_SPEED)
	assert_eq(v.x, 3.0, "keeps the run")
	assert_gt(PadRules.LAUNCH_PAD_SPEED, PadRules.BOUNCE_SPEED)
	var height := PadRules.LAUNCH_PAD_SPEED * PadRules.LAUNCH_PAD_SPEED / (2.0 * Player.GRAVITY)
	assert_gt(height, 15.0, "high enough to glide far")
	assert_lt(height, 25.0)
	assert_eq(PadRules.new().apply(Vector3(0, 40, 0), BlockIds.LAUNCH_PAD).y, 40.0, "never slows a faster body")


# --- Shop --------------------------------------------------------------------------------------------------

func test_tilly_sells_every_gadget_at_a_fixed_price_scaled_per_universe() -> void:
	var gadgets := ShopRules.catalog(ShopRules.GADGETS)
	for id in ItemIds.GADGETS + [BlockIds.ZIPLINE_POST, BlockIds.LAUNCH_PAD]:
		assert_true(gadgets.has(id), ItemIds.display_name(id))
		assert_gt(ShopRules.price(id), 0)
		assert_eq(ShopRules.price(id, 2), ShopRules.price(id) * 2, "× 2 in universe 2")
	assert_true(ShopRules.SECTIONS.has(ShopRules.GADGETS))
	assert_eq(ShopRules.amount(BlockIds.ZIPLINE_POST), 2, "posts come in pairs: one line")
	assert_eq(ShopRules.amount(ItemIds.IMPULSE_ORB), 3)
	assert_true(ShopRules.is_tool_item(ItemIds.GLIDER), "nobody needs two gliders")
	assert_true(ShopRules.is_tool_item(ItemIds.GRAPPLE))
	assert_false(ShopRules.is_tool_item(ItemIds.DANCE_ORB), "orbs are used up")
	assert_true(ShopRules.catalog(ShopRules.HOME).has(BlockIds.JUMP_PAD), "the Lab's pads stay in HOME")


func test_sandbox_cheats_can_give_every_gadget() -> void:
	for id in ItemIds.GADGETS + [BlockIds.ZIPLINE_POST, BlockIds.LAUNCH_PAD]:
		assert_eq(ChatCommands.item_for_name(ItemIds.display_name(id)), id, ItemIds.display_name(id))
