extends GutTest
## Cosmos: Triton's nitrogen geysers as pads (spec §21b.2; PadRules). Voyager 2 saw geysers blow nitrogen gas and dark dust
## about 8 km up, and the thin wind carry the dust far to the north-east (the dark streaks on the pink cap). In the game a
## geyser's vent is safe and fun: a gentle puff carries a child up (about 32 blocks in Triton's 0.079 gravity, slower than
## Europa's plumes) and the thin wind drifts it north-east while it floats (it can still steer across the wind), until its
## feet touch the ground again. Nothing hurts (there is no fall damage).

const DT := 1.0 / 60.0

var pads: PadRules


func before_each() -> void:
	pads = PadRules.new()


func after_each() -> void:
	LabRules.world_gravity = 1.0


func test_a_gentle_puff_up_slower_than_a_water_plume() -> void:
	assert_true(PadRules.is_pad(BlockIds.NITROGEN_GEYSER))
	var fired := pads.touch(BlockIds.NITROGEN_GEYSER, Vector3(1, 0, 0), Vector3.FORWARD)
	assert_eq(fired, BlockIds.NITROGEN_GEYSER)
	var v := pads.apply(Vector3(1, 0, 0), fired)
	assert_almost_eq(v.y, PadRules.PUFF_SPEED, 0.001, "a puff up")
	assert_lt(PadRules.PUFF_SPEED, PadRules.GEYSER_SPEED, "gentler than Europa's water plumes")
	var up := PadRules.PUFF_SPEED * PadRules.PUFF_SPEED / (2.0 * Player.GRAVITY * 0.079)
	assert_between(up, 25.0, 40.0, "about 30 blocks up in Triton's gravity (%.1f)" % up)
	assert_gt(up, Player.JUMP_VELOCITY * Player.JUMP_VELOCITY / (2.0 * Player.GRAVITY * 0.079),
		"higher than a jump there: a ride")


func test_the_thin_wind_carries_the_rider_north_east() -> void:
	var fired := pads.touch(BlockIds.NITROGEN_GEYSER, Vector3.ZERO, Vector3.FORWARD)
	var v := pads.apply(Vector3.ZERO, fired)
	var wind := PadRules.WIND
	assert_gt(wind.x, 0.5, "east (+x)")
	assert_lt(wind.z, -0.5, "and north (-z): north-east, like the real dust")
	assert_almost_eq(wind.length(), 1.0, 0.001)
	var drifted := Vector3.ZERO
	for i in 120:   # two seconds in the air, no stick: the wind carries the child along
		pads.tick(DT)
		v = pads.apply(Vector3(0.0, v.y, 0.0), 0)
		drifted += Vector3(v.x, 0.0, v.z) * DT
	assert_almost_eq(Vector2(v.x, v.z).length(), PadRules.DRIFT_SPEED, 0.01, "drifting with the wind")
	assert_gt(drifted.dot(wind), 4.0, "north-east (%s)" % drifted)
	var across := Vector3(-wind.z, 0.0, wind.x)
	v = pads.apply(across * 6.0, 0)
	assert_almost_eq(v.dot(across), 6.0, 0.001, "the child steers across the wind")


func test_the_drift_eases_out_and_landing_ends_it() -> void:
	var fired := pads.touch(BlockIds.NITROGEN_GEYSER, Vector3.ZERO, Vector3.FORWARD)
	pads.apply(Vector3.ZERO, fired)
	for i in int(PadRules.DRIFT_TIME / DT) + 2:
		pads.tick(DT)
	assert_eq(pads.apply(Vector3.ZERO, 0), Vector3.ZERO, "the wind lets go after a while")
	fired = pads.touch(BlockIds.NITROGEN_GEYSER, Vector3.ZERO, Vector3.FORWARD)
	pads.apply(Vector3.ZERO, fired)
	pads.tick(0.2)
	assert_eq(pads.touch(0, Vector3.ZERO, Vector3.FORWARD), 0, "still on the vent's rim: the puff just started")
	assert_gt(pads.apply(Vector3.ZERO, 0).length(), 0.1, "the ride goes on")
	pads.tick(PadRules.COOLDOWN)
	pads.touch(0, Vector3.ZERO, Vector3.FORWARD)   # feet on the ground again
	assert_eq(pads.apply(Vector3.ZERO, 0), Vector3.ZERO, "landing ends the drift")
	pads.touch(BlockIds.NITROGEN_GEYSER, Vector3.ZERO, Vector3.FORWARD)
	pads.reset()
	assert_eq(pads.apply(Vector3.ZERO, 0), Vector3.ZERO, "reset clears it")


func test_other_pads_never_drift() -> void:
	for id: int in [BlockIds.JUMP_PAD, BlockIds.GEYSER_VENT, BlockIds.VOLCANO_VENT, BlockIds.LAUNCH_PAD]:
		var p := PadRules.new()
		var fired := p.touch(id, Vector3.ZERO, Vector3.FORWARD)
		var v := p.apply(Vector3.ZERO, fired)
		assert_eq(Vector2(v.x, v.z), Vector2.ZERO, "%s throws straight up" % BlockIds.display_name(id))
