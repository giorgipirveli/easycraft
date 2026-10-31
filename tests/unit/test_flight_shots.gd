extends GutTest
## Owner #79, #86, #87 (spec §25.3): what the flight shows at every moment (FlightShots.pose), as pure rules: the rocket
## on the pad in the real world, rising, through the clouds into the space set, the sky turning black, the Earth below
## then behind, the destination ahead and growing, the engines' fire only when they burn, the stage falling, the legs,
## the parachute, the heat shield's glow, the ground rising under the landing, and the movie-style moments.


func _info(extra: Dictionary = {}) -> Dictionary:
	var info := {"destination": SpaceRules.MOON, "time": 10.0, "waiting": &"", "done": false, "throttle": 0.0,
		"auto_burn": false, "flown": true, "burn_at": 0.5}
	info.merge(extra, true)
	return info


func test_on_the_pad_the_rocket_stands_in_the_real_world() -> void:
	var p := FlightShots.pose(FlightPlan.BOARD, 0.5, _info())
	assert_true(p.world)
	assert_eq(p.rise, 0.0)
	assert_eq(p.fire, 0.0)
	assert_eq(p.sky, 0.0)
	var early := FlightShots.pose(FlightPlan.COUNTDOWN, 0.5, _info())
	assert_eq(early.fire, 0.0, "no fire at 5")
	var late := FlightShots.pose(FlightPlan.COUNTDOWN, 0.8, _info())
	assert_gt(late.fire, 0.0, "the engines light at 3")
	assert_true(late.smoke, "smoke on the pad")


func test_lift_off_waits_for_the_throttle_then_rises_and_shakes() -> void:
	var waiting := FlightShots.pose(FlightPlan.LIFTOFF, 0.0, _info({"waiting": FlightPlan.THROTTLE}))
	assert_eq(waiting.rise, 0.0)
	var pushed := FlightShots.pose(FlightPlan.LIFTOFF, 0.0, _info({"waiting": FlightPlan.THROTTLE, "throttle": 1.0}))
	assert_gt(pushed.fire, waiting.fire, "more throttle, more fire")
	var up := FlightShots.pose(FlightPlan.LIFTOFF, 0.8, _info({"done": true}))
	assert_gt(up.rise, 10.0)
	assert_gt(up.shake, 0.0, "the pad shakes")
	assert_true(up.world)


func test_the_clouds_hide_the_step_from_the_world_into_space() -> void:
	var before := FlightShots.pose(FlightPlan.ASCENT, FlightShots.CLOUD_AT - 0.05, _info())
	var peak := FlightShots.pose(FlightPlan.ASCENT, FlightShots.CLOUD_AT, _info())
	var after := FlightShots.pose(FlightPlan.ASCENT, FlightShots.CLOUD_AT + 0.05, _info())
	assert_true(before.world)
	assert_false(after.world, "above the clouds: the space set")
	assert_gt(peak.cloud, 0.9, "all white where the scene changes")
	assert_gt(before.rise, 100.0, "high over the pad")
	assert_lt(FlightShots.pose(FlightPlan.ASCENT, 0.9, _info()).cloud, 0.01)


func test_the_sky_turns_black_and_the_rocket_turns_over() -> void:
	var sky := -1.0
	var pitch := -1.0
	for q in [0.0, 0.3, 0.5, 0.8, 1.0]:
		var p := FlightShots.pose(FlightPlan.ASCENT, q, _info())
		assert_gte(p.sky, sky)
		assert_gte(p.pitch, pitch)
		sky = p.sky
		pitch = p.pitch
	assert_eq(FlightShots.pose(FlightPlan.ORBIT, 0.2, _info()).sky, 1.0, "space is black")
	assert_almost_eq(FlightShots.pose(FlightPlan.ORBIT, 0.2, _info()).pitch, 90.0, 0.1, "flying level round the Earth")


func test_the_earth_is_below_then_behind_and_the_moon_ahead_growing() -> void:
	var orbit := FlightShots.pose(FlightPlan.ORBIT, 0.2, _info())
	assert_true(orbit.earth.show)
	assert_lt(orbit.earth.dir.y, -0.9, "below")
	var cruise := FlightShots.pose(FlightPlan.CRUISE, 0.8, _info())
	assert_gt(cruise.earth.dir.z, 0.5, "behind us")
	assert_true(cruise.dest.show)
	assert_lt(cruise.dest.dir.z, -0.9, "ahead")
	var far := FlightShots.pose(FlightPlan.CRUISE, 0.2, _info())
	assert_gt(far.dest.alt, cruise.dest.alt, "growing as we come")
	assert_gt(cruise.earth.alt, orbit.earth.alt, "the Earth falls behind")


func test_the_engines_burn_only_when_they_burn() -> void:
	assert_eq(FlightShots.pose(FlightPlan.ORBIT, 0.2, _info()).fire, 0.0, "coasting round the Earth")
	var held := FlightShots.pose(FlightPlan.ORBIT, 0.5, _info({"waiting": FlightPlan.BURN, "throttle": 1.0}))
	assert_gt(held.fire, 0.5)
	var idle := FlightShots.pose(FlightPlan.ORBIT, 0.5, _info({"waiting": FlightPlan.BURN}))
	assert_eq(idle.fire, 0.0, "waiting for the child's burn")
	var auto := FlightShots.pose(FlightPlan.ORBIT, 0.5, _info({"waiting": FlightPlan.BURN, "auto_burn": true}))
	assert_gt(auto.fire, 0.5, "the autopilot burns")
	assert_eq(FlightShots.pose(FlightPlan.CRUISE, 0.5, _info()).fire, 0.0)
	assert_gt(FlightShots.pose(FlightPlan.DEORBIT, 0.5, _info()).fire, 0.5, "the burn down from orbit")
	var staging := FlightShots.pose(FlightPlan.STAGING, 0.1, _info({"waiting": FlightPlan.STAGE}))
	assert_eq(staging.fire, 0.0, "the empty stage is quiet")


func test_the_ground_rises_under_the_landing_and_the_legs_come_out() -> void:
	var start := FlightShots.pose(FlightPlan.LANDING, 0.0, _info({"waiting": FlightPlan.LEGS}))
	assert_true(start.ground)
	assert_eq(start.legs, 0.0, "the child puts them out")
	var mid := FlightShots.pose(FlightPlan.LANDING, 0.5, _info({"done": true}))
	assert_lt(mid.ground_h, start.ground_h)
	assert_eq(mid.legs, 1.0)
	assert_gt(mid.fire, 0.0)
	var down := FlightShots.pose(FlightPlan.LANDED, 0.1, _info())
	assert_eq(down.ground_h, 0.0)
	assert_eq(down.fire, 0.0)
	assert_eq(down.legs, 1.0)
	var alone := FlightShots.pose(FlightPlan.LANDING, 0.5, _info({"flown": false}))
	assert_eq(alone.legs, 1.0, "a landing on its own puts them out by itself")
	var deorbit := FlightShots.pose(FlightPlan.DEORBIT, 0.5, _info())
	assert_false(deorbit.ground)
	assert_true(deorbit.dest.show)
	assert_lt(deorbit.dest.dir.y, -0.9, "the world below")


func test_air_brings_the_heat_shield_s_glow_and_the_parachute() -> void:
	var info := _info({"destination": SpaceRules.MARS})
	assert_gt(FlightShots.pose(FlightPlan.ENTRY, 0.5, info).heat, 0.8)
	assert_eq(FlightShots.pose(FlightPlan.CHUTE, 0.0, _info({"destination": SpaceRules.MARS,
		"waiting": FlightPlan.PARACHUTE})).chute, 0.0)
	assert_eq(FlightShots.pose(FlightPlan.CHUTE, 0.6, _info({"destination": SpaceRules.MARS, "done": true})).chute, 1.0)
	assert_eq(FlightShots.pose(FlightPlan.CHUTE, 0.6, _info({"destination": SpaceRules.MARS, "flown": false})).chute, 1.0,
		"on its own it opens by itself")
	var landing := FlightShots.pose(FlightPlan.LANDING, 0.6, _info({"destination": SpaceRules.MARS, "done": true}))
	assert_eq(landing.chute, 0.0, "let go: the engines land us")
	assert_true(landing.air)


func test_the_movie_moments() -> void:
	var info := _info({"destination": SpaceRules.MARS})
	var flash := 0.0
	for q in [0.0, 0.2, 0.4, 0.45, 0.5, 0.7, 1.0]:
		var p := FlightShots.pose(FlightPlan.JUMP, q, info)
		assert_eq(p.moment, FlightPlan.JUMP)
		flash = maxf(flash, p.flash)
	assert_gt(flash, 0.9, "a flash")
	assert_gt(FlightShots.pose(FlightPlan.JUMP, 0.3, info).stretch, 5.0, "stars stretch into lines")
	assert_eq(FlightShots.pose(FlightPlan.WARP, 0.5, info).moment, FlightPlan.WARP)
	assert_false(FlightShots.pose(FlightPlan.WARP, 0.5, info).earth.show)
	assert_eq(FlightShots.pose(FlightPlan.CRUISE, 0.5, _info()).moment, &"")
