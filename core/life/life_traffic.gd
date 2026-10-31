class_name LifeTraffic
extends RefCounted
## Owner #112 (docs/design/life-skills.md §5 #4, Safe Streets): the practice street's traffic, scripted (never the
## world's cars): real gaps between real-sized cars at real town speeds, which is what the VR road-crossing trials train
## [L3]. The street runs along x; the crossing is at x = 0; the child's pavement is on +z, so the NEAR lane (+z) carries
## the cars that come from the child's left where cars drive on the right (LifeRegion.drive), from the right where they
## drive on the left.
##
## Cars come in bunches that reach the crossing BUNCH seconds apart each CYCLE (seeded jitter, lanes and speeds of 30 to
## 40 km/h), so a real safe gap comes every cycle and busy moments come between. safe_gap(): no car in the crossing
## (|x| < ZONE) and none that would reach it in the CROSS_SECONDS a child takes to walk across. stop_for_child(): a child
## stepped out at an unsafe moment: every car still coming brakes gently to a stop before the crossing, waits WAIT
## seconds and drives on (never a crash: the child is still on the kerb). press_button(): a button crossing: the cars'
## light goes amber, then red (they stop at their stop line) while the green man shows, flashing at the end, then green
## again. A following car keeps GAP behind the one ahead. Units: metres, seconds.

const NEAR := 0
const FAR := 1
const LANE_Z := 1.5
const ROAD_HALF := 3.0
const ENTER_X := 60.0
const ZONE := 4.0
const CROSS_SECONDS := 6.0
const STOP_X := 7.0
const GAP := 6.0
const BRAKE := 4.0
const HARD_BRAKE := 7.0
const SPEEDUP := 2.5
const WAIT := 2.5
const CYCLE := 16.0
const BUNCH: Array[float] = [0.0, 2.8, 5.4]
const JITTER := 0.35
## 30, 35 and 40 km/h.
const SPEEDS: Array[float] = [8.33, 9.72, 11.11]
## The street's cars: town kinds from the cars (#109), most often the off-roader and the pickup.
const KINDS: Array[StringName] = [&"off_roader", &"pickup", &"off_roader", &"race_car", &"pickup", &"bus"]
## The button crossing: the wait after the button, the amber light, the green man (flashing for its last FLASH).
const BUTTON_WAIT := 2.0
const AMBER := 2.0
const GREEN_MAN := 9.0
const FLASH := 3.0

var drive := "right"
var seed := 0
## The lanes cars come in (the Big track's practice car stands in the near lane: only the far lane drives).
var lanes: Array[int] = [NEAR, FAR]
## The next green man is short and flashes at once (the Middle track's Expert try: wait for the next one).
var flash_next := false
## The cars' light stays red until let go (the Big track's driver waits at it).
var hold_red := false
var clock := 0.0
## {id, lane, dir (+1 / -1 along x), x, v, top, kind, colour, length, hold (s), stop_at (x or NAN), why ("child" /
## "light" / "")}
var cars: Array[Dictionary] = []
var lights := "go"
var _light_t := 0.0
var _pending: Array[Dictionary] = []
var _next_cycle := -2
var _ids := 0


func _init(traffic_seed: int = 0, drive_side: String = "right", only: Array[int] = []) -> void:
	seed = traffic_seed
	drive = drive_side if drive_side in ["left", "right"] else "right"
	if not only.is_empty():
		lanes = only
	_plan()
	_spawn_due()


## The near lane's direction along x (+1: towards +x).
func near_dir() -> int:
	return 1 if drive == "right" else -1


func dir_of(lane: int) -> int:
	return near_dir() if lane == NEAR else -near_dir()


static func lane_z(lane: int) -> float:
	return LANE_Z if lane == NEAR else -LANE_Z


func step(dt: float) -> void:
	clock += dt
	_plan()
	_spawn_due()
	_step_lights(dt)
	for lane in [NEAR, FAR]:
		var list := cars.filter(func(c: Dictionary) -> bool: return int(c.lane) == lane)
		list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.x) * int(a.dir) > float(b.x) * int(b.dir))
		for i in list.size():
			_drive(list[i], list[i - 1] if i > 0 else {}, dt)
	cars = cars.filter(func(c: Dictionary) -> bool: return float(c.x) * int(c.dir) < ENTER_X + 5.0)


## How far a car still is before the crossing place `at_x` (m; negative once past it).
static func ahead_of(c: Dictionary, at_x: float = 0.0) -> float:
	return (at_x - float(c.x)) * int(c.dir)


## The cars that have not reached the zone of the crossing place `at_x` yet, nearest first.
func coming(at_x: float = 0.0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in cars:
		if ahead_of(c, at_x) > ZONE:
			out.append(c)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return ahead_of(a, at_x) < ahead_of(b, at_x))
	return out


## Seconds until a car reaches the zone of the crossing place `at_x` (INF for none coming); 0 when one is in it.
func time_to_next(at_x: float = 0.0) -> float:
	var best := INF
	for c in cars:
		var ahead := ahead_of(c, at_x)
		if absf(float(c.x) - at_x) < ZONE:
			return 0.0
		if ahead <= ZONE:
			continue
		var v := float(c.v)
		var t := (ahead - ZONE) / maxf(v, 0.1)
		if v < 0.5:   # stopped: it drives on after its wait (or at the green light)
			t = float(c.hold) + (ahead - ZONE) / float(c.top) if str(c.why) != "light" else INF
		best = minf(best, t)
	return best


## Safe to walk across at `at_x` now by the gap: nothing in its zone, nothing reaching it while a child walks across.
func safe_gap(at_x: float = 0.0) -> bool:
	return time_to_next(at_x) >= CROSS_SECONDS


## A child stepped out at `at_x` when it was not safe: every coming car brakes gently and stops before the place, waits
## a moment and drives on. Returns how many stop.
func stop_for_child(at_x: float = 0.0) -> int:
	var n := 0
	for c in cars:
		var ahead := ahead_of(c, at_x)
		if ahead <= ZONE:
			continue
		var v := float(c.v)
		var at := maxf(minf(STOP_X, ahead - v * v / (2.0 * HARD_BRAKE)), ZONE + 0.5)
		c.stop_at = at_x - float(c.dir) * at
		c.why = "child"
		n += 1
	return n


## The button of a button crossing: the green man comes after the wait and the amber light.
func press_button() -> void:
	if lights == "go" and _light_t <= 0.0:
		lights = "wait"
		_light_t = BUTTON_WAIT


## The Big track: the cars' light turns red (amber first) and stays red until release_red().
func turn_red() -> void:
	hold_red = true
	if lights == "go":
		lights = "wait"
		_light_t = 0.01


func release_red() -> void:
	hold_red = false
	if lights == "stop":
		_light_t = 0.0


func waiting_for_green() -> bool:
	return lights in ["wait", "amber"]


func green_man() -> bool:
	return lights == "stop"


func green_flashing() -> bool:
	return lights == "stop" and _light_t <= FLASH


## Safe to cross at a button crossing: the green man shows (not flashing: never start then) and every car before the
## crossing has stopped.
func safe_green() -> bool:
	if not green_man() or green_flashing():
		return false
	for c in cars:
		var ahead := ahead_of(c)
		if absf(float(c.x)) < ZONE or (ahead > 0.0 and ahead < STOP_X + 15.0 and float(c.v) > 0.3):
			return false
		if ahead > 0.0 and ahead < STOP_X - 0.5:
			return false   # past its line (on at amber, or stopped there for a child): it still has to cross
	return true


func _step_lights(dt: float) -> void:
	if lights == "go":
		return
	_light_t -= dt
	if _light_t > 0.0:
		return
	match lights:
		"wait":
			lights = "amber"
			_light_t = AMBER
			for c in cars:   # every car that can stop comfortably stops at its line
				var ahead := ahead_of(c)
				if ahead > STOP_X and float(c.v) * float(c.v) / (2.0 * BRAKE) < ahead - STOP_X + 0.5:
					c.stop_at = -float(c.dir) * STOP_X
					c.why = "light"
		"amber":
			lights = "stop"
			_light_t = FLASH if flash_next else GREEN_MAN
			flash_next = false
		"stop":
			if hold_red:
				_light_t = FLASH + 0.5
				return
			lights = "go"
			_light_t = 0.0
			for c in cars:
				if str(c.why) == "light":
					c.stop_at = NAN
					c.why = ""


func _drive(c: Dictionary, ahead_car: Dictionary, dt: float) -> void:
	var allowed := float(c.top)
	if float(c.hold) > 0.0:
		c.hold = float(c.hold) - dt
		allowed = 0.0
		if float(c.hold) <= 0.0:
			c.stop_at = NAN
			c.why = ""
	elif not is_nan(float(c.stop_at)):
		var d := (float(c.stop_at) - float(c.x)) * int(c.dir)
		if d <= 0.15:
			allowed = 0.0
			if str(c.why) == "child" and float(c.v) < 0.05:
				c.hold = WAIT
		else:
			allowed = minf(allowed, sqrt(2.0 * HARD_BRAKE * d))
	if lights in ["amber", "stop"] and is_nan(float(c.stop_at)) and ahead_of(c) > STOP_X:
		var d2 := ahead_of(c) - STOP_X
		if float(c.v) * float(c.v) / (2.0 * BRAKE) < d2 + 0.5:   # a car arriving at a red light stops at its line
			c.stop_at = -float(c.dir) * STOP_X
			c.why = "light"
	if not ahead_car.is_empty():
		var gap := (float(ahead_car.x) - float(c.x)) * int(c.dir) - (float(ahead_car.length) + float(c.length)) * 0.5
		allowed = minf(allowed, sqrt(2.0 * HARD_BRAKE * maxf(gap - GAP, 0.0)) + float(ahead_car.v) * 0.5)
		if gap - GAP <= 0.0:
			allowed = minf(allowed, float(ahead_car.v))
	var v := float(c.v)
	v = minf(v + SPEEDUP * dt, allowed) if allowed >= v else maxf(allowed, v - HARD_BRAKE * 1.5 * dt)
	if allowed <= 0.0 and v < 0.3:
		v = 0.0
	c.v = maxf(v, 0.0)
	c.x = float(c.x) + int(c.dir) * float(c.v) * dt


## The cars of the next cycles (each car's start time, so it reaches the crossing at its moment).
func _plan() -> void:
	while _next_cycle <= int(floorf(clock / CYCLE)) + 1:
		var k := _next_cycle
		_next_cycle += 1
		for j in BUNCH.size():
			var h := absi(hash([seed, k, j]))
			var top := SPEEDS[h % SPEEDS.size()]
			var arrive := k * CYCLE + BUNCH[j] + (float(h % 1000) / 1000.0 - 0.5) * 2.0 * JITTER
			var lane: int = lanes[(h / 7) % lanes.size()]
			var kind: StringName = KINDS[(h / 13) % KINDS.size()]
			_pending.append({"at": arrive - ENTER_X / top, "arrive": arrive, "lane": lane, "top": top, "kind": kind,
				"colour": (h / 31) % CarKinds.COLOURS})
		_pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.at) < float(b.at))


func _spawn_due() -> void:
	while not _pending.is_empty() and float(_pending[0].at) <= clock:
		var p: Dictionary = _pending.pop_front()
		var dir := dir_of(int(p.lane))
		var x := -dir * ENTER_X + dir * float(p.top) * (clock - float(p.at))
		if x * dir > ENTER_X:
			continue   # long gone by the time the street was opened
		var v := float(p.top)
		var length := CarKinds.size(p.kind).z
		for c in cars:   # never on top of (or past) the last car in its lane: behind it, at its speed
			if int(c.lane) != int(p.lane):
				continue
			var room := (float(c.length) + length) * 0.5 + GAP + 1.0
			if (float(c.x) - x) * dir < room:
				x = float(c.x) - dir * room
				v = minf(v, float(c.v))
		_ids += 1
		cars.append({"id": _ids, "lane": int(p.lane), "dir": dir, "x": x, "v": v, "top": float(p.top),
			"kind": p.kind, "colour": int(p.colour), "length": length, "hold": 0.0, "stop_at": NAN,
			"why": ""})
