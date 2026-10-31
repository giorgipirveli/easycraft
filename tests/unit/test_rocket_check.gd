extends GutTest
## Missions (spec §21d.3): the check, like real rockets. It reads the parts standing on the pad (cells relative to the
## pad's corner, y up), splits them into stages at the stage separators (the bottom stage fires first, then drops), and
## says in words and numbers: lift-off (the engines' push against the weight, with a margin), how far the fuel takes
## you (the rocket equation per stage: Δv = Isp × g₀ × ln(full ÷ empty), each stage carrying the ones above), against
## the mission's need, and the crew's needs. Every number here is worked out by hand.

const G0 := 9.80665
const E := BlockIds.ROCKET_ENGINE
const V := BlockIds.SPACE_ENGINE
const T := BlockIds.FUEL_TANK
const N := BlockIds.NOSE_CONE
const C := BlockIds.CREW_CAPSULE
const S := BlockIds.SERVICE_MODULE
const H := BlockIds.HEAT_SHIELD
const L := BlockIds.LANDING_LEGS
const F := BlockIds.ROCKET_FINS
const X := BlockIds.STAGE_SEPARATOR
const P := BlockIds.SOLAR_ARRAY
const R := BlockIds.PARACHUTE_PACK


func _moon() -> Dictionary:
	return MissionRules.for_world(SpaceRules.MOON)


func _mars() -> Dictionary:
	return MissionRules.for_world(SpaceRules.MARS)


## A column of parts at (4, y, 4), bottom first.
func _column(ids: Array, at := Vector3i(4, 0, 4)) -> Dictionary:
	var out := {}
	for i in ids.size():
		out[at + Vector3i(0, i, 0)] = ids[i]
	return out


## A rocket that flies to the Moon: stage 1 (8 engines, 10 tanks, 4 fins, a separator), stage 2 (2 space engines,
## 4 tanks, a separator), stage 3 (a space engine, a tank, the service module, the capsule, the nose cone, 3 legs, a
## solar array).
func _moon_rocket() -> Dictionary:
	var c := {}
	for x in range(2, 6):
		for z in range(3, 5):
			c[Vector3i(x, 0, z)] = E   # 8 engines on the pad
			c[Vector3i(x, 1, z)] = T   # 8 tanks on them
	c[Vector3i(3, 2, 3)] = T
	c[Vector3i(3, 2, 4)] = T   # 10 tanks
	for f: Vector3i in [Vector3i(1, 0, 3), Vector3i(6, 0, 3), Vector3i(3, 0, 2), Vector3i(4, 0, 5)]:
		c[f] = F
	c[Vector3i(3, 3, 4)] = X
	c[Vector3i(3, 4, 4)] = V
	c[Vector3i(3, 4, 3)] = V
	for y in [5, 6]:
		c[Vector3i(3, y, 3)] = T
		c[Vector3i(3, y, 4)] = T
	c[Vector3i(3, 7, 4)] = X
	c[Vector3i(3, 8, 4)] = V
	c[Vector3i(3, 9, 4)] = T
	c[Vector3i(3, 10, 4)] = S
	c[Vector3i(3, 11, 4)] = C
	c[Vector3i(3, 12, 4)] = N
	for leg: Vector3i in [Vector3i(2, 8, 4), Vector3i(4, 8, 4), Vector3i(3, 8, 5)]:
		c[leg] = L
	c[Vector3i(2, 10, 4)] = P
	return c


func _line(result: Dictionary, key: StringName) -> Dictionary:
	for l: Dictionary in result.lines:
		if l.key == key:
			return l
	return {}


func test_an_empty_pad_has_no_rocket() -> void:
	var r := RocketCheck.check({}, _moon())
	assert_true(r.empty)
	assert_false(r.ok)
	assert_eq(r.lines.size(), 1)
	assert_false(r.lines[0].ok)
	assert_string_contains(r.lines[0].text, "Build a rocket")


func test_one_stage_lifts_off_and_the_rocket_equation_says_how_far() -> void:
	# 1 engine (4 t, pushes 250), 2 full tanks (100 t each, 6 t empty), a capsule (5 t): 209 t full, 21 t empty.
	var r := RocketCheck.check(_column([E, T, T, C]), _moon())
	assert_false(r.empty)
	assert_eq(r.stages.size(), 1)
	assert_almost_eq(float(r.mass), 209.0, 0.001)
	assert_almost_eq(float(r.stages[0].full), 209.0, 0.001)
	assert_almost_eq(float(r.stages[0].empty), 21.0, 0.001)
	assert_almost_eq(float(r.push), 250.0, 0.001)
	assert_true(_line(r, &"liftoff").ok, "250 beats 209 × 1.1 = 229.9: lift-off")
	assert_string_contains(_line(r, &"liftoff").text, "250")
	assert_string_contains(_line(r, &"liftoff").text, "209")
	var dv := 300.0 * G0 * log(209.0 / 21.0) / 1000.0   # 6.76 km/s
	assert_almost_eq(float(r.dv), dv, 0.001)
	assert_almost_eq(float(r.need), 15.3, 0.001, "the Moon: 9.4 to Earth orbit, 3.3 to the Moon, 2.6 into orbit and down")
	assert_false(_line(r, &"speed").ok, "6.8 of 15.3 km/s")
	assert_string_contains(_line(r, &"speed").text, "6.8")
	assert_string_contains(_line(r, &"speed").text, "15.3")
	assert_false(r.ok)


func test_too_heavy_to_lift_off() -> void:
	# 1 engine and 3 tanks and a capsule: 309 t; the engine pushes 250, less than 309 × 1.1.
	var r := RocketCheck.check(_column([E, T, T, T, C]), _moon())
	assert_almost_eq(float(r.mass), 309.0, 0.001)
	var l := _line(r, &"liftoff")
	assert_false(l.ok)
	assert_string_contains(l.text, "Too heavy")
	assert_ne(l.why, "", "what real rockets do")


func test_two_stages_the_bottom_one_drops_and_the_rest_goes_faster() -> void:
	# Stage 1: 2 engines, 2 tanks, a separator (209 t full, 21 t empty); stage 2: a space engine, a tank, a capsule
	# (108 t full, 14 t empty). Stage 1 carries stage 2 (108 t) all the way; stage 2 flies on alone.
	var c := _column([E, T, T, X, V, T, C])
	c[Vector3i(5, 0, 4)] = E
	var r := RocketCheck.check(c, _moon())
	assert_eq(r.stages.size(), 2)
	assert_almost_eq(float(r.stages[0].full), 209.0, 0.001)
	assert_almost_eq(float(r.stages[0].carries), 108.0, 0.001)
	assert_almost_eq(float(r.stages[1].full), 108.0, 0.001)
	assert_almost_eq(float(r.stages[1].carries), 0.0, 0.001)
	var dv1 := 300.0 * G0 * log(317.0 / 129.0) / 1000.0
	var dv2 := 450.0 * G0 * log(108.0 / 14.0) / 1000.0
	assert_almost_eq(float(r.stages[0].dv), dv1, 0.001)
	assert_almost_eq(float(r.stages[1].dv), dv2, 0.001)
	assert_almost_eq(float(r.dv), dv1 + dv2, 0.001, "11.7 km/s: more than one stage of the same parts gives")
	assert_almost_eq(float(r.push), 500.0, 0.001)
	assert_eq(r.stages[0].cells.size(), 5)
	assert_eq(r.stages[1].cells.size(), 3)


func test_a_rocket_that_flies_to_the_moon() -> void:
	var r := RocketCheck.check(_moon_rocket(), _moon())
	assert_eq(r.stages.size(), 3)
	# Stage 3: 116.5 t full, 22.5 t empty; stage 2: 407 t full, 31 t empty, carries 116.5; stage 1: 1035 t full,
	# 95 t empty, carries 523.5; the whole rocket: 1558.5 t, pushed by 8 × 250 = 2000 t at lift-off.
	assert_almost_eq(float(r.stages[2].full), 116.5, 0.001)
	assert_almost_eq(float(r.stages[1].full), 407.0, 0.001)
	assert_almost_eq(float(r.stages[0].full), 1035.0, 0.001)
	assert_almost_eq(float(r.mass), 1558.5, 0.001)
	var dv3 := 450.0 * G0 * log(116.5 / 22.5) / 1000.0
	var dv2 := 450.0 * G0 * log(523.5 / 147.5) / 1000.0
	var dv1 := 300.0 * G0 * log(1558.5 / 618.5) / 1000.0
	assert_almost_eq(float(r.dv), dv1 + dv2 + dv3, 0.001, "15.57 km/s")
	assert_gt(float(r.dv), 15.3)
	for l: Dictionary in r.lines:
		assert_true(l.ok, "%s: %s" % [l.key, l.text])
	assert_true(r.ok)
	assert_eq(r.seats, 1)


func test_mars_needs_more_than_the_moon() -> void:
	var r := RocketCheck.check(_moon_rocket(), _mars())
	assert_false(r.ok)
	assert_false(_line(r, &"speed").ok, "Mars needs 16.1 km/s")
	assert_false(_line(r, &"heat_shield").ok, "Mars has air: coming down through it needs a heat shield")
	assert_false(_line(r, &"parachute").ok, "and a parachute")
	assert_true(_line(r, &"supplies").ok, "owner #98: one service module keeps its astronaut for the whole 7 months")
	assert_string_contains(_line(r, &"supplies").text, "about 7 months", "the line still says the real trip")


## Owner #98: a service module keeps one astronaut for the whole trip, however long (it reuses air and water like the
## space station and grows a little food): the supplies line wants one on the top stage for each astronaut.
func test_a_service_module_keeps_one_astronaut_for_the_whole_trip() -> void:
	var triton := MissionRules.for_world(27)
	var one := RocketCheck.check(_moon_rocket(), triton, 1)
	assert_true(_line(one, &"supplies").ok, "12 years: still one module for one astronaut")
	assert_eq(int(one.kept), 1)
	assert_string_contains(_line(one, &"supplies").text, "about 12 years")
	var two := RocketCheck.check(_moon_rocket(), _moon(), 2)
	var l := _line(two, &"supplies")
	assert_false(l.ok, "two astronauts need two service modules, even for 3 days")
	assert_string_contains(l.text, "2 astronauts need 2 service modules")
	assert_string_contains(l.text, "you have 1")
	assert_string_contains(l.why, "space station")
	var none := RocketCheck.check(_column([E, T, C]), _moon())
	assert_string_contains(_line(none, &"supplies").text, "you have none")


func test_an_engine_needs_room_for_its_flame() -> void:
	# The engine sits on a tank of its own stage: its nozzle is blocked, it pushes nothing.
	var r := RocketCheck.check(_column([T, E, C]), _moon())
	assert_almost_eq(float(r.push), 0.0, 0.001)
	assert_false(_line(r, &"blocked").ok)
	assert_false(_line(r, &"liftoff").ok)


func test_space_engines_are_made_for_space() -> void:
	var r := RocketCheck.check(_column([V, T, C]), _moon())
	assert_almost_eq(float(r.push), 0.0, 0.001, "a space engine in stage 1 does not lift off")
	assert_false(_line(r, &"space_engine").ok)


func test_an_upper_stage_must_push_at_least_half_of_what_it_carries() -> void:
	# Stage 2: one space engine (150) under 4 tanks and a capsule: 408 t; half of it is 204.
	var c := _column([E, T, X, V, T, T, T, T, C])
	for x in [3, 5]:
		c[Vector3i(x, 0, 4)] = E
	var r := RocketCheck.check(c, _moon())
	var l := _line(r, &"upper_push")
	assert_false(l.ok)
	assert_string_contains(l.text, "Stage 2")


func test_fuel_without_an_engine_and_an_engine_without_fuel() -> void:
	var r := RocketCheck.check(_column([E, T, X, T, T, C]), _moon())
	assert_false(_line(r, &"no_engine").ok, "stage 2 has tanks and no engine to burn them")
	var r2 := RocketCheck.check(_column([E, X, V, T, C]), _moon())
	assert_false(_line(r2, &"no_fuel").ok, "stage 1 has an engine and no tank")


func test_the_crew_needs_a_seat_supplies_legs_power_and_a_pointed_top() -> void:
	var r := RocketCheck.check(_column([E, T, C]), _moon())
	assert_true(_line(r, &"seats").ok, "one seat, one astronaut")
	assert_false(_line(r, &"supplies").ok, "no service module: no air and water")
	assert_false(_line(r, &"legs").ok)
	assert_false(_line(r, &"power").ok)
	assert_false(_line(r, &"fins").ok)
	assert_true(_line(r, &"top").ok, "a capsule's cone is pointed")
	var two := RocketCheck.check(_column([E, T, C]), _moon(), 2)
	assert_false(_line(two, &"seats").ok, "two astronauts need two seats")
	var flat := RocketCheck.check(_column([E, T, C, T]), _moon())
	assert_false(_line(flat, &"top").ok, "a tank on top is flat")
	var none := RocketCheck.check(_column([E, T, N]), _moon())
	assert_false(_line(none, &"seats").ok, "no capsule, no seat")


func test_the_crew_rides_the_last_stage() -> void:
	# The capsule sits in stage 1, which falls away.
	var r := RocketCheck.check(_column([E, T, C, X, V, T, N]), _moon())
	assert_false(_line(r, &"seats").ok)
	assert_string_contains(_line(r, &"seats").text, "stage 1")


func test_the_rocket_is_the_biggest_piece_standing_on_the_pad() -> void:
	var c := _column([E, T, C])
	c[Vector3i(0, 0, 0)] = E   # another little one in a corner
	c[Vector3i(8, 5, 8)] = T   # floating: not standing on the pad
	c[Vector3i(4, 0, 9)] = T   # off the build square
	c[Vector3i(4, 3, 4)] = BlockIds.STONE   # not a part: it stays on the pad
	var rocket := RocketCheck.find_rocket(c)
	assert_eq(rocket.size(), 3)
	assert_eq(rocket.get(Vector3i(4, 2, 4)), C)
	assert_false(rocket.has(Vector3i(0, 0, 0)))


func test_sandbox_launches_only_the_parts_you_bought() -> void:
	var owned := {E: 8, V: 3, T: 15, X: 2, F: 4, S: 1, C: 1, N: 1, L: 3}
	var r := RocketCheck.check(_moon_rocket(), _moon(), 1, owned)
	var l := _line(r, &"paid")
	assert_false(l.ok, "a solar array is not bought yet")
	assert_eq(r.missing, {P: 1})
	assert_string_contains(l.text, "1 solar array")
	var fewer := owned.duplicate()
	fewer.erase(E)
	fewer.erase(T)
	assert_string_contains(_line(RocketCheck.check(_moon_rocket(), _moon(), 1, fewer), &"paid").text,
		"8 rocket engines, 15 fuel tanks and 1 solar array", "owner #98: plurals, in the shop's order")
	owned[P] = 1
	assert_true(RocketCheck.check(_moon_rocket(), _moon(), 1, owned).ok)
	assert_true(_line(RocketCheck.check(_moon_rocket(), _moon()), &"paid").is_empty(), "Survivor: the bag paid already")


func test_the_description_the_flight_gets() -> void:
	var r := RocketCheck.check(_moon_rocket(), _moon())
	var d := RocketCheck.description(r, SpaceRules.MOON)
	assert_eq(d.destination, SpaceRules.MOON)
	assert_eq((d.cells as Dictionary).size(), _moon_rocket().size())
	assert_eq(d.cells[Vector3i(3, 12, 4)], N)
	assert_eq((d.stages as Array).size(), 3, "bottom stage first")
	assert_has(d.stages[0], Vector3i(2, 0, 3))
	assert_has(d.stages[2], Vector3i(3, 11, 4))
	assert_eq(d.seats, 1)
