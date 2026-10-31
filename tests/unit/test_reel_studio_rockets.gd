extends GutTest
## Owner #96 (spec §5.12b, the Reel Studio): the rockets the cinematic reels film are real rockets by the game's own
## rules (RocketCheck), built from the missions' parts, so a child who copies one can fly it.


func _lines_not_ok(r: Dictionary) -> String:
	var out: Array[String] = []
	for l: Dictionary in r.lines:
		if not bool(l.ok):
			out.append(str(l.text))
	return "\n".join(out)


func test_the_moon_rocket_flies_to_the_moon() -> void:
	var r := RocketCheck.check(StudioRockets.cells("moon"), MissionRules.for_world(SpaceRules.MOON))
	assert_true(r.ok, _lines_not_ok(r))
	assert_eq((r.stages as Array).size(), 3, "three stages")
	var parts := RocketParts.count(StudioRockets.cells("moon"))
	for id: int in parts:
		assert_true(RocketParts.is_part(id), "only the missions' parts: %s" % BlockIds.display_name(id))


func test_the_flight_takes_it_in_three_stages() -> void:
	var r := StudioRockets.rocket("moon")
	assert_eq(RocketStages.stage_count(r), 3)
	var top := RocketStages.lander(r)
	assert_true(top.values().has(BlockIds.CREW_CAPSULE), "the capsule rides on the top stage")
	assert_true(top.values().has(BlockIds.LANDING_LEGS), "which lands on its legs")


func test_the_lander_is_the_moon_rocket_s_top() -> void:
	var lander := StudioRockets.cells("lander")
	var top := RocketStages.lander(StudioRockets.rocket("moon"))
	assert_eq(lander.size(), top.size())
	assert_eq(RocketParts.count(lander), RocketParts.count(top))
