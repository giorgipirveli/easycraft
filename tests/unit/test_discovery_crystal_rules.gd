extends GutTest
## Owner #132 (W1), stage 2: the discovery crystal's rules. Where and when one comes (home worlds, a grown-up's switch,
## after a few minutes of play, never two, an untouched one fades), and where it rises: a few metres from the child, on
## ground the child can reach, never in water or in a wall.

const FEET := Vector3(0.5, 70.0, 0.5)


## A flat meadow: grass below y 70, air above; `cells` overrides.
class Meadow:
	var cells := {}
	var ground := 70

	func block(p: Vector3i) -> int:
		if cells.has(p):
			return int(cells[p])
		return BlockIds.GRASS if p.y < ground else BlockIds.AIR


func test_crystals_come_to_home_worlds_only() -> void:
	assert_true(DiscoveryCrystalRules.here(ModeRules.SANDBOX, 1, true))
	assert_true(DiscoveryCrystalRules.here(ModeRules.SURVIVOR, 4, true))
	assert_false(DiscoveryCrystalRules.here(ModeRules.WAVE, 1, true), "never in Monster Wave")
	assert_false(DiscoveryCrystalRules.here(ModeRules.SANDBOX, SpaceRules.FIRST, true), "never in space")
	assert_false(DiscoveryCrystalRules.here(ModeRules.SANDBOX, 1, false), "a grown-up turned them off")


func test_the_grown_ups_switch_is_on_unless_turned_off() -> void:
	assert_true(DiscoveryCrystalRules.switched_on({}))
	assert_true(DiscoveryCrystalRules.switched_on(ProfileData.DEFAULT_SETTINGS))
	assert_false(DiscoveryCrystalRules.switched_on({DiscoveryCrystalRules.SETTING: false}))


func test_the_first_comes_after_a_few_minutes_of_play_then_every_few_minutes() -> void:
	assert_false(DiscoveryCrystalRules.due(DiscoveryCrystalRules.FIRST_SECONDS - 1.0, true))
	assert_true(DiscoveryCrystalRules.due(DiscoveryCrystalRules.FIRST_SECONDS, true))
	assert_false(DiscoveryCrystalRules.due(DiscoveryCrystalRules.EVERY_SECONDS - 1.0, false))
	assert_true(DiscoveryCrystalRules.due(DiscoveryCrystalRules.EVERY_SECONDS, false))
	assert_almost_eq(DiscoveryCrystalRules.EVERY_SECONDS, 300.0, 60.0, "about five minutes (the brief's DISCOVERY_MINUTES)")
	assert_gt(DiscoveryCrystalRules.WAIT_SECONDS, 30.0, "an untouched crystal waits a good while before it fades")


func test_it_rises_a_few_metres_away_on_reachable_ground() -> void:
	var m := Meadow.new()
	var at := DiscoveryCrystalRules.spot_near(FEET, 0.0, m.block)
	assert_true(at.is_finite())
	var d := Vector2(at.x - FEET.x, at.z - FEET.z).length()
	assert_between(d, DiscoveryCrystalRules.NEAR, DiscoveryCrystalRules.FAR + 0.8, "a few metres from the child")
	assert_eq(at.y, 70.0, "standing on the ground")


func test_it_rises_in_front_of_the_child_when_it_can() -> void:
	var m := Meadow.new()
	for yaw: float in [0.0, PI * 0.5, PI]:
		var at := DiscoveryCrystalRules.spot_near(FEET, yaw, m.block)
		var ahead := -Vector3(sin(yaw), 0, cos(yaw))   # the game's forward (-Z at yaw 0)
		var to := (at - FEET)
		to.y = 0
		assert_gt(to.normalized().dot(ahead), 0.7, "ahead at yaw %.2f" % yaw)


func test_never_in_water() -> void:
	var m := Meadow.new()
	for x in range(-8, 9):
		for z in range(-8, 9):
			if abs(x) > 1 or abs(z) > 1:
				m.cells[Vector3i(x, 69, z)] = BlockIds.WATER   # a pond all round the child's little island
	var at := DiscoveryCrystalRules.spot_near(FEET, 0.0, m.block)
	assert_false(at.is_finite(), "no dry ground near: no crystal now")


func test_never_inside_a_wall() -> void:
	var m := Meadow.new()
	for x in range(-8, 9):
		for z in range(-8, 9):
			if abs(x) > 1 or abs(z) > 1:
				for y in range(70, 74):
					m.cells[Vector3i(x, y, z)] = BlockIds.STONE   # walls all round
	var at := DiscoveryCrystalRules.spot_near(FEET, 0.0, m.block)
	assert_false(at.is_finite())


func test_it_finds_dry_ground_beside_water() -> void:
	var m := Meadow.new()
	for x in range(-8, 9):
		for z in range(-8, 0):
			m.cells[Vector3i(x, 69, z)] = BlockIds.WATER   # water ahead, a meadow behind
	var at := DiscoveryCrystalRules.spot_near(FEET, 0.0, m.block)
	assert_true(at.is_finite())
	assert_ne(m.block(Vector3i(floori(at.x), int(at.y) - 1, floori(at.z))), BlockIds.WATER)


func test_a_step_up_or_down_is_reachable_a_cliff_is_not() -> void:
	var m := Meadow.new()
	m.ground = 72   # everything around two blocks up: still reachable
	m.cells[Vector3i(0, 70, 0)] = BlockIds.AIR
	var at := DiscoveryCrystalRules.spot_near(FEET, 0.0, m.block)
	assert_true(at.is_finite())
	assert_eq(at.y, 72.0)
	var cliff := Meadow.new()
	cliff.ground = 80   # a wall of earth ten blocks up all round
	assert_false(DiscoveryCrystalRules.spot_near(FEET, 0.0, cliff.block).is_finite())


func test_its_lines_are_short_and_few_words_show() -> void:
	assert_lte(DiscoveryRules.word_count(DiscoveryCrystalRules.ARRIVE_LINE), 10)
	assert_lte(DiscoveryRules.word_count(DiscoveryCrystalRules.HOOT_CRYSTAL_LINE), 12)
