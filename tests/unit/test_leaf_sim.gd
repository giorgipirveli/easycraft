extends GutTest
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.5, §3.5b, §4.6): the leaf's simulation, whose rules are the
## science: open doors let air in and water out (faster in the heat); sugar needs air, light and water; the leaf droops
## below 0.55 and stands above; the bud fills only while it stands; a cactus keeps the night's air in jars and builds
## with it by day behind shut doors. The expected numbers are worked by hand from the phase A models' formulas
## (docs/design/games/leaf-voyage/model/).

const BLAZE := {"heat": 1.0, "light": 1.0}
const CLOUD := {"heat": 0.25, "light": 0.7}
const NIGHT := {"heat": 0.0, "light": 0.0, "night": true}
const DESERT_DAY := {"heat": 1.3, "light": 1.0}


func _sunflower(water: float = 0.95, open: bool = false) -> LeafSim:
	var sim := LeafSim.make(LeafVoyages.voyage("5.1").sim)
	sim.water = water
	for i in sim.doors.size():
		sim.set_door(i, open)
	return sim


func _cactus(water: float = 0.9, open: bool = false) -> LeafSim:
	var sim := LeafSim.make(LeafVoyages.voyage("5.T1").sim)
	sim.water = water
	for i in sim.doors.size():
		sim.set_door(i, open)
	return sim


func test_a_voyage_starts_as_its_data_says() -> void:
	var s := LeafSim.make(LeafVoyages.voyage("5.1").sim)
	assert_eq(s.doors.size(), 6)
	assert_eq(s.open_count(), 6, "Act 1: the doors are open and the mist pours")
	assert_almost_eq(s.water, 0.5, 0.0001, "drooping")
	var c := LeafSim.make(LeafVoyages.voyage("5.T1").sim)
	assert_eq(c.open_count(), 0, "the cactus starts with its doors shut")
	assert_almost_eq(c.water, 0.9, 0.0001)


func test_open_doors_lose_water_and_faster_in_the_heat() -> void:
	var blaze := _sunflower(0.95, true)
	blaze.step(1.0, BLAZE)
	# 0.95 + 0.035 * (1.05 - 0.95) - (6 * 0.006 * (0.10 + 1.0) + 0.0006) = 0.95 + 0.0035 - 0.0402
	assert_almost_eq(blaze.water, 0.9133, 0.0001, "six open doors in the blaze")
	var cloud := _sunflower(0.95, true)
	cloud.step(1.0, CLOUD)
	# 0.95 + 0.0035 - (6 * 0.006 * 0.35 + 0.0006) = 0.95 + 0.0035 - 0.0132
	assert_almost_eq(cloud.water, 0.9403, 0.0001, "the same doors in a cloud lose less")
	var shut := _sunflower(0.95, false)
	shut.step(1.0, BLAZE)
	assert_almost_eq(shut.water, 0.9529, 0.0001, "shut doors: only the skin's 0.0006, the vein refills")


func test_air_comes_in_only_through_open_doors() -> void:
	var shut := _sunflower(0.95, false)
	for i in 10:
		shut.step(1.0, NIGHT)
	assert_eq(shut.air, 0.0, "shut doors keep the air out")
	var half := _sunflower(0.95, false)
	for i in 3:
		half.set_door(i, true)
	half.step(1.0, NIGHT)
	assert_almost_eq(half.air, 0.44, 0.0001, "0.22 x 3/6 x (1 - 0) x 4 a second")
	var all := _sunflower(0.95, true)
	all.step(0.5, NIGHT)
	assert_almost_eq(all.air, 0.44, 0.0001, "0.22 x 6/6 x 4 for half a second")


func test_sugar_needs_air_light_and_water() -> void:
	var no_air := _sunflower(0.95, false)
	for i in 20:
		no_air.step(0.5, BLAZE)
	assert_eq(no_air.made, 0.0, "no air: nothing is built, however bright")
	var dark := _sunflower(0.95, true)
	for i in 20:
		dark.step(0.5, NIGHT)
	assert_gt(dark.air, 0.5, "the air came in")
	assert_eq(dark.made, 0.0, "no light: nothing is built (light is the energy)")
	var wet := _sunflower(0.95, false)
	wet.air = 1.0
	wet.step(0.1, BLAZE)
	var dry := _sunflower(0.3, false)
	dry.air = 1.0
	dry.step(0.1, BLAZE)
	# air 1.0 - min(1, 1.0 x 1 x 0.35 x 0.1 x 4) = 0.86, still over 0.5: 0.35 x 1 x 1 x 0.1
	assert_almost_eq(wet.made, 0.035, 0.0001, "air, light and water: 0.35 a second")
	assert_almost_eq(dry.made, 0.0105, 0.0001, "too dry: 30 % of it")


func test_the_leaf_droops_below_0_55_and_stands_above() -> void:
	var s := _sunflower(0.549)
	assert_false(s.standing())
	s.water = 0.55
	assert_true(s.standing())
	assert_false(s.too_dry())
	s.water = 0.349
	assert_true(s.too_dry())


func test_the_bud_fills_only_while_the_leaf_stands() -> void:
	var s := _sunflower(0.5, true)
	s.made = 3.0
	for i in 3:
		assert_true(s.take())
	assert_eq(s.deliver(3), 3, "three sugars into the gold pipe")
	for i in 30:
		s.step(0.1, BLAZE)
	assert_lt(s.water, 0.55, "still drooping (the doors are open in the blaze)")
	assert_eq(s.bud, 0.0, "a drooping stem holds the sugar back")
	s.water = 0.9
	for i in 6:
		s.set_door(i, false)
	s.step(1.0, BLAZE)
	assert_almost_eq(s.bud, 1.0, 0.0001, "standing: a sugar a second climbs to the bud")
	for i in 10:
		s.step(1.0, BLAZE)
	assert_almost_eq(s.bud, 3.0, 0.0001, "never more than was delivered")
	assert_false(s.bud_full(), "the bud needs 12")


func test_sugar_is_taken_from_the_workshops_and_carried_to_the_pipe() -> void:
	var s := _sunflower()
	s.made = 2.6
	assert_eq(s.waiting(), 2, "two whole hexagons wait at the workshops")
	assert_true(s.take())
	assert_true(s.take())
	assert_false(s.take(), "none left")
	assert_eq(s.deliver(5), 2, "only what was carried goes in")
	assert_eq(s.deliver(1), 0)
	assert_eq(s.delivered, 2)


func test_a_door_toggles_and_a_wrong_door_does_nothing() -> void:
	var s := _sunflower(0.9, false)
	assert_true(s.toggle(2), "now open")
	assert_eq(s.open_count(), 1)
	assert_almost_eq(s.open_share(), 1.0 / 6.0, 0.0001)
	assert_false(s.toggle(2), "shut again")
	assert_false(s.toggle(9), "no such door")
	assert_false(s.toggle(-1))
	assert_eq(s.open_count(), 0)


func test_a_teaching_act_never_dries_the_leaf_past_its_floor() -> void:
	var s := _sunflower(0.5, true)
	for i in 600:
		s.step(0.1, {"heat": 1.0, "light": 1.0, "floor": 0.4})
	assert_almost_eq(s.water, 0.4, 0.0001, "Act 1 waits for the child (the design's 0.5 start, never a rescue)")


func test_closing_the_doors_refills_faster_while_the_cells_fill() -> void:
	var slow := _sunflower(0.6, false)
	var fast := _sunflower(0.6, false)
	slow.step(1.0, BLAZE)
	fast.step(1.0, {"heat": 1.0, "light": 1.0, "refill": 6.0})
	# 0.6 + 6 x 0.035 x 0.45 - 0.0006 = 0.6939; the plain vein: 0.6 + 0.01575 - 0.0006
	assert_almost_eq(fast.water, 0.6939, 0.0001)
	assert_almost_eq(slow.water, 0.61515, 0.0001)


func test_a_cactus_keeps_the_night_air_in_jars_and_builds_with_it_by_day() -> void:
	var c := _cactus(0.9, false)
	for i in 10:
		c.step(1.0, NIGHT)
	assert_eq(c.jars, 0.0, "shut doors at night: the jars stay empty")
	for i in 6:
		c.set_door(i, true)
	for i in 10:
		c.step(1.0, NIGHT)
	assert_almost_eq(c.jars, 3.6, 0.0001, "0.06 a second for each of 6 open doors, 10 s")
	assert_eq(c.made, 0.0, "nothing is built in the dark")
	assert_eq(c.air, 0.0, "the night's air goes into the jars")
	for i in 6:
		c.set_door(i, false)
	c.step(1.0, DESERT_DAY)
	assert_almost_eq(c.made, 0.35, 0.0001, "by day, behind shut doors, the jars feed the workshops")
	assert_almost_eq(c.jars, 3.25, 0.0001)
	for i in 30:
		c.step(1.0, NIGHT)
	assert_almost_eq(c.jars, 3.25, 0.0001, "the jars keep their air while the doors stay shut")


func test_the_jars_hold_at_most_their_fill() -> void:
	var c := _cactus(0.9, true)
	for i in 100:
		c.step(1.0, NIGHT)
	assert_almost_eq(c.jars, 8.0, 0.0001, "8 sugars' worth")


func test_a_sunflower_keeps_no_air_in_jars() -> void:
	var s := _sunflower(0.95, true)
	for i in 10:
		s.step(1.0, NIGHT)
	assert_eq(s.jars, 0.0, "jars are the cactus's")


func test_the_workshops_glow_only_when_they_build() -> void:
	var s := _sunflower(0.95, false)
	s.step(0.1, BLAZE)
	assert_eq(s.work(), 0.0, "no air: dim")
	s.air = 1.0
	s.step(0.01, BLAZE)
	assert_gt(s.work(), 0.9, "air and the blaze's light: lit")
	s.step(0.01, NIGHT)
	assert_eq(s.work(), 0.0, "the dark: dim")
