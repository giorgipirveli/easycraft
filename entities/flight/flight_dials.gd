class_name FlightDials
extends RefCounted
## The cockpit's dials (owner #79, spec §25.3: "the real numbers on the dials"), as pure rules of the trip's steps
## (FlightPlan), the step now, its progress, the burn and the stages let go. read() gives:
##   speed (km/s; LIGHT_SPEED during the game's shortcuts, light_speed true), height (km, above height_of: "Earth" until
##   the destination's own steps, then its name), distance (km to the destination, counting down from the real one: the
##   Moon's 384,400; -1: too far to say, our own make-believe planets), fuel (per stage 0..1, -1 once it fell away),
##   clock (the real trip's time since lift-off in words: "12 min", "3 days", "7 months"; "" when nobody knows) and
##   clock_hours.
## The numbers are real and rounded (the notes give their sources): orbit at ~7.8 km/s, the burn to the Moon to
## ~10.9 km/s, the Moon's 3 days; Mars's 7 months; the other trips' lengths from FlightPlan.REAL_TRIP's missions.

const LIGHT_SPEED := 299792.0
const ORBIT_SPEED := 7.8
## Average distances from Earth, km (for a planet: the middle of its nearest and farthest; a moon: its planet's).
const DISTANCE := {
	SpaceRules.MOON: 384400.0, SpaceRules.MARS: 225000000.0, SpaceRules.VENUS: 150000000.0,
	SpaceRules.MERCURY: 150000000.0, SpaceRules.EUROPA: 778000000.0, SpaceRules.IO: 778000000.0,
	SpaceRules.TITAN: 1430000000.0, SpaceRules.RINGS: 1430000000.0, SpaceRules.PLUTO: 5900000000.0,
	SpaceRules.TRITON: 4500000000.0, SpaceRules.GANYMEDE: 778000000.0,
}
## The real trip's hours (FlightPlan.REAL_TRIP).
const TRIP_HOURS := {
	SpaceRules.MOON: 72.0, SpaceRules.MARS: 5110.0, SpaceRules.VENUS: 2920.0, SpaceRules.MERCURY: 61320.0,
	SpaceRules.EUROPA: 52560.0, SpaceRules.IO: 52560.0, SpaceRules.TITAN: 61320.0, SpaceRules.RINGS: 61320.0,
	SpaceRules.PLUTO: 83220.0, SpaceRules.TRITON: 105120.0, SpaceRules.GANYMEDE: 102240.0,
}
## Leaving Earth: the Moon's burn ends at ~10.9 km/s, a planet's at ~11.5.
const LEAVE_SPEED := {SpaceRules.MOON: 10.9}
## Arriving (km/s): at the Moon ~2.3, at a planet with air the entry speed (Mars ~5.6).
const ARRIVE_SPEED := {SpaceRules.MOON: 2.3, SpaceRules.MARS: 5.6, SpaceRules.TITAN: 6.0, SpaceRules.VENUS: 11.0}
## A low orbit round the destination (km/s): the Moon 1.6.
const LOW_ORBIT := {SpaceRules.MOON: 1.6, SpaceRules.MERCURY: 3.0, SpaceRules.IO: 1.8, SpaceRules.EUROPA: 1.4,
	SpaceRules.GANYMEDE: 1.9}
const ORBIT_HEIGHT := 110.0       # km over the destination when in orbit round it
const ENTRY_HEIGHT := 125.0       # km where a world's air begins to glow on the heat shield
const CHUTE_HEIGHT := 11.0
const LAND_FROM := 1.5            # km: the parachute lets go, the engines take over
const DEORBIT_TO := 15.0          # km: the burn down from orbit ends, the landing begins
const DEORBIT_SPEED := 0.3        # km/s left after the burn down
const RESERVE := 0.15             # the lander keeps this much fuel (the way home)

## Each step's weight of fuel. Owner #106: most of the lander's is kept for the descent the child flies (its own gauge
## then: the descent's fuel, FlightDescent).
const _BURNS := {FlightPlan.LIFTOFF: 0.5, FlightPlan.ASCENT: 3.0, FlightPlan.ORBIT: 2.0, FlightPlan.ARRIVE: 1.0,
	FlightPlan.LANDING: 1.5, FlightPlan.DESCENT: 6.0}
## Owner #106: the way home after a crash.
const _HOME: Array[StringName] = [FlightPlan.ESCAPE, FlightPlan.HOME_ENTRY, FlightPlan.HOME_CHUTE, FlightPlan.WRECK,
	FlightPlan.HOME]
const _SHORTCUTS: Array[StringName] = [FlightPlan.JUMP, FlightPlan.WARP, FlightPlan.WORMHOLE, FlightPlan.ASTEROIDS,
	FlightPlan.NEBULA]


## The dials at step `index` of `steps`, `p` (0..1) through it; `burn` (0..1) the burn of a step that holds one (1 once
## done), `dropped` the stages let go. Owner #106: `descent` ({h (m), v (m/s), fuel (0..1)}: the child's FlightDescent)
## gives the descent's numbers and the lander's fuel from then on; the way home after a crash says "home" (TO EARTH).
static func read(steps: Array[Dictionary], index: int, p: float, destination: int, stages: int, burn: float = 0.0,
		dropped: int = 0, descent: Dictionary = {}) -> Dictionary:
	var s: Dictionary = steps[clampi(index, 0, steps.size() - 1)]
	var phase: StringName = s.phase
	var q := clampf(p, 0.0, 1.0)
	var far := DISTANCE.get(destination, -1.0) as float
	var hours := TRIP_HOURS.get(destination, -1.0) as float
	var leave: float = LEAVE_SPEED.get(destination, 11.5)
	var arrive: float = ARRIVE_SPEED.get(destination, 5.0 if FlightPlan.has_air(destination) else 2.5)
	var low: float = LOW_ORBIT.get(destination, 1.6)
	var out := {"speed": 0.0, "height": 0.0, "height_of": "Earth", "distance": far, "light_speed": false,
		"clock_hours": 0.0}
	var burn_at: float = float(s.at) / float(s.seconds) if s.action == FlightPlan.BURN else 1.0
	var b := clampf(burn, 0.0, 1.0)
	match phase:
		FlightPlan.LIFTOFF:
			out.speed = lerpf(0.0, 0.05, q)
			out.height = lerpf(0.0, 0.5, q * q)
			out.clock_hours = q * 10.0 / 3600.0
		FlightPlan.ASCENT:
			out.speed = lerpf(0.05, 2.4, q * q)
			out.height = lerpf(0.5, 65.0, pow(q, 1.5))
			out.clock_hours = lerpf(10.0 / 3600.0, 0.05, q)
		FlightPlan.STAGING:
			var second := _nth_staging(steps, index) > 0
			out.speed = lerpf(10.9 if second else 2.4, 10.95 if second else 2.6, q) if not second else leave
			out.height = lerpf(65.0, 75.0, q) if not second else lerpf(300.0, 900.0, q)
			out.clock_hours = lerpf(0.05, 0.06, q) if not second else lerpf(2.7, 2.8, q)
		FlightPlan.ORBIT:
			var before := clampf(q / burn_at, 0.0, 1.0)
			out.speed = lerpf(2.6, ORBIT_SPEED, before) + (leave - ORBIT_SPEED) * b
			out.height = lerpf(75.0, 190.0, before) + lerpf(0.0, 110.0, clampf((q - burn_at) / (1.0 - burn_at), 0.0, 1.0))
			out.clock_hours = lerpf(0.06, 0.2, before) + 2.5 * b
		FlightPlan.CRUISE, FlightPlan.JUMP, FlightPlan.WARP, FlightPlan.WORMHOLE, FlightPlan.ASTEROIDS, FlightPlan.NEBULA:
			_cruise(out, steps, index, q, destination, leave, arrive, far, hours)
		FlightPlan.ARRIVE:
			out.height_of = FlightPlan.body_name(destination)
			out.speed = lerpf(arrive, low, b)
			out.height = lerpf(2400.0, ORBIT_HEIGHT, q)
			out.distance = out.height
			out.clock_hours = _there(hours, 0.0 + 4.0 * q)
		FlightPlan.DEORBIT:
			out.height_of = FlightPlan.body_name(destination)
			out.speed = lerpf(low, DEORBIT_SPEED, q)
			out.height = lerpf(ORBIT_HEIGHT, DEORBIT_TO, q)
			out.distance = out.height if far >= 0.0 else -1.0
			out.clock_hours = _there(hours, 4.0 + q)
		FlightPlan.ENTRY:
			out.height_of = FlightPlan.body_name(destination)
			out.speed = lerpf(arrive, 0.45, q)
			out.height = lerpf(ENTRY_HEIGHT, CHUTE_HEIGHT, q)
			out.distance = out.height if far >= 0.0 else -1.0
			out.clock_hours = _there(hours, q * 0.1)
		FlightPlan.CHUTE:
			out.height_of = FlightPlan.body_name(destination)
			out.speed = lerpf(0.45, 0.09, q)
			out.height = lerpf(CHUTE_HEIGHT, LAND_FROM, q)
			out.distance = out.height if far >= 0.0 else -1.0
			out.clock_hours = _there(hours, 0.1 + q * 0.05)
		FlightPlan.LANDING:
			out.height_of = FlightPlan.body_name(destination)
			var h0 := LAND_FROM if FlightPlan.has_air(destination) else DEORBIT_TO
			var h1 := FlightDescent.START_HEIGHT / 1000.0   # owner #106: down to where the child's descent starts
			out.speed = lerpf(0.09 if FlightPlan.has_air(destination) else DEORBIT_SPEED, FlightDescent.START_SPEED / 1000.0, q)
			out.height = lerpf(h0, h1, 1.0 - (1.0 - q) * (1.0 - q))
			out.distance = out.height if far >= 0.0 else -1.0
			out.clock_hours = _there(hours, (5.0 if not FlightPlan.has_air(destination) else 0.15) + q * 2.0)
		FlightPlan.DESCENT:   # owner #106: the child's descent, in metres
			out.height_of = FlightPlan.body_name(destination)
			out.speed = maxf(float(descent.get("v", 0.0)), 0.0) / 1000.0
			out.height = maxf(float(descent.get("h", 0.0)), 0.0) / 1000.0
			out.distance = out.height if far >= 0.0 else -1.0
			out.clock_hours = _there(hours, (7.0 if not FlightPlan.has_air(destination) else 2.15))
		FlightPlan.CRASH:
			out.height_of = FlightPlan.body_name(destination)
			out.distance = 0.0 if far >= 0.0 else -1.0
			out.clock_hours = _there(hours, 7.0)
		FlightPlan.ESCAPE, FlightPlan.HOME_ENTRY, FlightPlan.HOME_CHUTE, FlightPlan.WRECK, FlightPlan.HOME:
			_home(out, phase, q, far)
		FlightPlan.LANDED:
			out.height_of = FlightPlan.body_name(destination)
			out.distance = 0.0 if far >= 0.0 else -1.0
			out.clock_hours = _there(hours, (7.0 if not FlightPlan.has_air(destination) else 2.15))
	if far < 0.0 and phase not in [FlightPlan.BOARD, FlightPlan.COUNTDOWN, FlightPlan.LIFTOFF, FlightPlan.ASCENT,
			FlightPlan.STAGING, FlightPlan.ORBIT]:
		out.clock_hours = -1.0
	out.fuel = fuel(steps, index, q, stages, dropped)
	if not descent.is_empty():   # owner #106: from the descent on, the lander's fuel is what the child's descent left
		var at := _descent_index(steps)
		if at >= 0 and index >= at:
			var f0: Array = fuel(steps, at, 0.0, stages, dropped)
			var last := (out.fuel as Array).size() - 1
			out.fuel[last] = float(f0[last]) * clampf(float(descent.get("fuel", 1.0)), 0.0, 1.0)
	out.home = phase in _HOME
	if out.home and phase != FlightPlan.ESCAPE:
		out.clock_hours = -1.0
	out.clock = clock_words(out.clock_hours)
	return out


## Owner #106: on the way home the distance and the height are Earth's.
static func _home(out: Dictionary, phase: StringName, q: float, far: float) -> void:
	out.height_of = "Earth"
	match phase:
		FlightPlan.ESCAPE:
			out.speed = lerpf(2.5, 10.9, q)
			out.distance = lerpf(far if far > 0.0 else 384400.0, ENTRY_HEIGHT, 1.0 - pow(1.0 - q, 1.6))
			out.height = out.distance
			out.clock_hours = -1.0
		FlightPlan.HOME_ENTRY:
			out.speed = lerpf(10.9, 0.45, q)
			out.height = lerpf(ENTRY_HEIGHT, CHUTE_HEIGHT * 0.15, q)
			out.distance = out.height
		FlightPlan.HOME_CHUTE:
			out.speed = lerpf(0.02, 0.007, q)   # a capsule comes down at about 7 m/s under its parachutes
			out.height = lerpf(FlightShots.HOME_FROM / 1000.0, 0.0, q)
			out.distance = out.height
		_:
			out.distance = 0.0


static func _descent_index(steps: Array[Dictionary]) -> int:
	for i in steps.size():
		if steps[i].phase == FlightPlan.DESCENT:
			return i
	return -1


## Through the long way: the moments (light speed, a tunnel, the belt, a nebula) cover the distance down to a million km
## at light speed; the last cruise brings it down to a few thousand, arriving. The Moon: its 3 days in one cruise.
static func _cruise(out: Dictionary, steps: Array[Dictionary], index: int, q: float, destination: int, leave: float,
		arrive: float, far: float, hours: float) -> void:
	var first := index
	while first > 0 and _SHORTCUTS.has(steps[first - 1].phase):
		first -= 1
	var last := index
	while last + 1 < steps.size() and (_SHORTCUTS.has(steps[last + 1].phase) or steps[last + 1].phase == FlightPlan.CRUISE):
		last += 1
	var n := last - first + 1
	var along := (float(index - first) + q) / float(n)   # 0..1 through the whole long way
	var phase: StringName = steps[index].phase
	if phase == FlightPlan.CRUISE and n == 1:   # the Moon: the real trip, slowing down away from Earth, then falling in
		out.speed = lerpf(leave, 0.9, q / 0.85) if q < 0.85 else lerpf(0.9, arrive, (q - 0.85) / 0.15)
		out.height = lerpf(300.0, far - 2400.0, 1.0 - pow(1.0 - q, 1.6)) if far > 0.0 else 0.0
		out.distance = maxf(far - out.height, 2400.0) if far > 0.0 else -1.0
		out.clock_hours = lerpf(2.8, hours, q) if hours > 0.0 else -1.0
		return
	if phase == FlightPlan.CRUISE:   # arriving after the shortcuts
		out.speed = arrive
		out.distance = lerpf(1000000.0, 5000.0, q) if far > 0.0 else -1.0
	else:
		out.speed = LIGHT_SPEED
		out.light_speed = true
		var shortcut := (float(index - first) + q) / float(maxi(n - 1, 1))
		out.distance = lerpf(far, 1000000.0, clampf(shortcut, 0.0, 1.0)) if far > 0.0 else -1.0
	out.height = maxf(far - out.distance, 0.0) if far > 0.0 else 0.0
	out.clock_hours = lerpf(2.8, hours, along) if hours > 0.0 else -1.0


static func _there(hours: float, extra: float) -> float:
	return hours + extra if hours > 0.0 else -1.0


## Which staging step this is (0 the first).
static func _nth_staging(steps: Array[Dictionary], index: int) -> int:
	var n := 0
	for i in index:
		if steps[i].phase == FlightPlan.STAGING:
			n += 1
	return n


## Each stage's fuel 0..1 at step `index`, `q` through it (-1: let go). The bottom stage burns the lift-off and the climb,
## a middle stage the burn in orbit, the lander the rest and keeps RESERVE for the way home; one stage burns it all.
static func fuel(steps: Array[Dictionary], index: int, q: float, stages: int, dropped: int) -> Array:
	var n := maxi(stages, 1)
	var owner := {}   # step index -> stage that burns it
	for i in steps.size():
		var phase: StringName = steps[i].phase
		if not _BURNS.has(phase):
			continue
		var st := n - 1
		if n >= 2 and phase in [FlightPlan.LIFTOFF, FlightPlan.ASCENT]:
			st = 0
		elif n >= 3 and phase == FlightPlan.ORBIT:
			st = 1
		owner[i] = st
	var total := []
	var used := []
	total.resize(n)
	used.resize(n)
	total.fill(0.0)
	used.fill(0.0)
	for i: int in owner:
		var w: float = _BURNS[steps[i].phase]
		total[owner[i]] += w
		if i < index:
			used[owner[i]] += w
		elif i == index:
			used[owner[i]] += w * q
	var out := []
	for k in n:
		if k < dropped:
			out.append(-1.0)
			continue
		var reserve := RESERVE if k == n - 1 else 0.03
		out.append(1.0 - (used[k] / total[k]) * (1.0 - reserve) if total[k] > 0.0 else 1.0)
	return out


## The trip's real time in words: "12 min", "5 h", "1 day 5 h", "3 days", "7 months", "6 years"; "" for none.
static func clock_words(hours: float) -> String:
	if hours < 0.0:
		return ""
	if hours < 1.0:
		return "%d min" % roundi(hours * 60.0)
	if hours < 24.0:
		return "%d h" % floori(hours)
	var days := hours / 24.0
	if days < 3.0 - 0.01:
		return "%d day %d h" % [floori(days), floori(hours - floorf(days) * 24.0)] if floori(days) == 1 \
			else "%d days %d h" % [floori(days), floori(hours - floorf(days) * 24.0)]
	if days < 60.0:
		return "%d days" % roundi(days)
	var months := days / 30.44
	if months < 24.0:
		return "%d months" % roundi(months)
	return "%d years" % roundi(months / 12.0)
