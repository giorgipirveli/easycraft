extends GutTest
## Cosmos (Europa, spec §21b.2; friendly, §3c): walking into a 1-block ledge hops onto it (the player's auto-step). In
## very low gravity that hop flew a child far too high: on Europa (0.13) a 1-block step threw them about 9 blocks up and
## held them in the air for 5 seconds. Under the Moon's gravity the hop keeps the Moon's height (LabRules.step_velocity);
## at the Moon's gravity and above nothing changes (the Moon, Mars, every universe).


func _hop(velocity: float, g: float) -> float:
	return velocity * velocity / (2.0 * Player.GRAVITY * g)


func test_the_hop_is_unchanged_down_to_the_moons_gravity() -> void:
	for g: float in [1.0, 0.8, 0.6, 0.38, LabRules.MOON_GRAVITY]:
		assert_eq(LabRules.step_velocity(Player.AUTO_STEP_VELOCITY, g), Player.AUTO_STEP_VELOCITY, "gravity %.2f" % g)


func test_in_lower_gravity_the_hop_is_as_high_as_on_the_moon() -> void:
	var moon := _hop(Player.AUTO_STEP_VELOCITY, LabRules.MOON_GRAVITY)
	for g: float in [0.3, 0.18, 0.13, 0.06]:
		var v := LabRules.step_velocity(Player.AUTO_STEP_VELOCITY, g)
		assert_lt(v, Player.AUTO_STEP_VELOCITY, "gravity %.2f: a gentler push" % g)
		assert_almost_eq(_hop(v, g), moon, 0.01, "gravity %.2f: the Moon's hop (%.1f blocks)" % [g, moon])
		assert_gt(_hop(v, g), 1.2, "still onto the ledge")
	assert_gt(_hop(Player.AUTO_STEP_VELOCITY, 0.13), 8.0, "before: a 1-block step flew a child 9 blocks up on Europa")


func test_no_gravity_keeps_the_push() -> void:
	assert_eq(LabRules.step_velocity(Player.AUTO_STEP_VELOCITY, 0.0), Player.AUTO_STEP_VELOCITY, "zero-g has no hop")
