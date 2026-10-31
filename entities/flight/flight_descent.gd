class_name FlightDescent
extends RefCounted
## Owner #106 (2026-10-15: "landing a rocket to the moon is simply too easy"): the lander's final descent, flown by the
## child, as pure rules. Every mission's flight ends with it (FlightPlan.DESCENT; the Star Map's LAND is a practice
## one). The lander starts START_HEIGHT metres over the pad falling at START_SPEED; the world pulls it down
## (`gravity`: the real surface gravity, kept between G_LEAST and G_MOST so every world plays); the engine pushes up to
## THRUST times that pull at full throttle (40% holds it still), burning the lander's fuel (seconds of full throttle,
## from its real tanks: fuel_for). Touching down at or under SAFE_SPEED lands; faster crashes, and so does running out
## of fuel above the ground (nothing slows the fall then). There is no autopilot: nobody touching the throttle crashes.
## The dials' colours (zone): GREEN there is room to slow down (and, near the ground, a safe touchdown), YELLOW slow down
## now, RED too fast, UP going up. A beep that quickens near the ground (beep_every), short kind words (words). The easy
## first try (`easy`: never landed on that world) starts lower, slower, with half as much fuel again, and holds still
## for its hint card (HINT) until GO (release) or HINT_HOLD seconds. A crew member's descent shows the pilot's (follow).

const FLYING := 0
const LANDED := 1
const CRASHED := 2

const GREEN := &"green"
const YELLOW := &"yellow"
const RED := &"red"
const UP := &"up"
const COLORS := {GREEN: Color(0.35, 1.0, 0.5), YELLOW: Color(1.0, 0.85, 0.25), RED: Color(1.0, 0.32, 0.25),
	UP: Color(0.45, 0.75, 1.0)}

## m/s: at or under it the legs take the touchdown. The real Moon landers' legs were built for 3.05 m/s (10 ft/s)
## straight down (the notes give the source).
const SAFE_SPEED := 3.0
## The lead (2026-10-16, VR-RIG's finding): green means "you will land". The dial is green while a child who keeps
## coasting for REACTION seconds (a child's reaction, with room) and then brakes at GREEN_BRAKE of the engine still
## touches down at or under SAFE_SPEED; when the ground comes sooner than that, green only if it lands as it falls.
## A child who only keeps the dial green lands on every world (tested 0.3 s late).
const REACTION := 0.45
## Green keeps this far under SAFE_SPEED (m/s): a touchdown on the dial's green edge still lands.
const GREEN_MARGIN := 0.15
## The engine's push at full throttle, as many times the world's pull.
const THRUST := 2.5
const START_HEIGHT := 120.0       # m over the pad
const START_SPEED := 8.0          # m/s down
const EASY_HEIGHT := 80.0
const EASY_SPEED := 4.0
const EASY_FUEL := 1.5
## Seconds of full throttle in a lander with no tank of its own, and each fuel tank's more, up to FUEL_MOST.
const FUEL_SECONDS := 20.0
const FUEL_PER_TANK := 2.0
const FUEL_MOST := 30.0
## m over the start a lander that climbs goes no higher.
const CEILING := 40.0
## GREEN while half the engine's braking stops it in time, YELLOW up to 85%, then RED.
const GREEN_BRAKE := 0.5
const RED_BRAKE := 0.85
const NEAR_GROUND := 25.0
## Seconds the first try's hint card holds the descent at most.
const HINT_HOLD := 10.0
## The fuel call-outs: seconds of hovering left.
const CALL_FUEL := [30.0, 10.0]
const G_LEAST := 1.0
const G_MOST := 3.71              # Mars's (and so Mercury's 3.70): the strongest pull kept as it is
## Real surface gravity, m/s² (the notes give the sources); our own planets: the game's.
const GRAVITY := {SpaceRules.MOON: 1.62, SpaceRules.MARS: 3.71, SpaceRules.MERCURY: 3.70, SpaceRules.VENUS: 8.87,
	SpaceRules.EUROPA: 1.31, SpaceRules.IO: 1.80, SpaceRules.GANYMEDE: 1.43, SpaceRules.TITAN: 1.35,
	SpaceRules.PLUTO: 0.62, SpaceRules.TRITON: 0.78, SpaceRules.RINGS: 0.49, SpaceRules.BOING: 5.89,
	SpaceRules.RAINBOW: 1.62}
const STEP := 1.0 / 60.0          # the physics' own step (the same landing whatever the frame rate)

const HINT := ("Land it yourself! Hold the THROTTLE (or BURN) to slow the fall. Keep the speed GREEN and touch down "
	+ "slower than 3 m/s. Watch your fuel!")
const LANDED_WORDS := "Touchdown! A soft landing!"
const CRASH_WORDS := "Too fast! The lander crashed."

var destination := SpaceRules.MOON
var easy := false
## m over the ground, and m/s falling (less than 0: going up).
var height := START_HEIGHT
var speed := START_SPEED
## Seconds of full throttle left, and what the tanks held.
var fuel := FUEL_SECONDS
var fuel_max := FUEL_SECONDS
var gravity := 1.62
## The engine's push at full throttle (m/s²).
var thrust := 1.62 * THRUST
var state := FLYING
## m/s at touchdown.
var touchdown_speed := 0.0
## The throttle last used (0..1).
var throttle := 0.0
## Seconds flown (not counting the card's hold).
var time := 0.0

var _hold := 0.0
var _start_h := START_HEIGHT
var _start_v := START_SPEED


func _init(dest: int = SpaceRules.MOON, p_easy: bool = false, tanks: int = 0) -> void:
	destination = dest
	easy = p_easy
	gravity = gravity_of(dest)
	thrust = gravity * THRUST
	_start_h = EASY_HEIGHT if easy else START_HEIGHT
	_start_v = EASY_SPEED if easy else START_SPEED
	fuel_max = fuel_for(tanks, easy)
	reset()
	_hold = HINT_HOLD if easy else 0.0


## The world's pull in the game: its real one kept between G_LEAST and G_MOST (Pluto's 0.62 would take a minute to come
## down; Venus's thick air brakes most of its 8.87).
static func gravity_of(dest: int) -> float:
	return clampf(real_gravity(dest), G_LEAST, G_MOST)


static func real_gravity(dest: int) -> float:
	return float(GRAVITY.get(dest, 1.62))


## Seconds of full throttle in a lander with `tanks` fuel tanks of its own (the easy first try: half as much again).
static func fuel_for(tanks: int, p_easy: bool = false) -> float:
	var s := minf(FUEL_SECONDS + FUEL_PER_TANK * maxi(tanks, 0), FUEL_MOST)
	return s * (EASY_FUEL if p_easy else 1.0)


## The fuel tanks among the lander's blocks ({cell: id}).
static func tanks_of(lander: Dictionary) -> int:
	var n := 0
	for c: Variant in lander:
		if int(lander[c]) == BlockIds.FUEL_TANK:
			n += 1
	return n


## Back at the top, full (a practice landing's next try).
func reset() -> void:
	height = _start_h
	speed = _start_v
	fuel = fuel_max
	state = FLYING
	touchdown_speed = 0.0
	throttle = 0.0
	time = 0.0
	_hold = 0.0


func done() -> bool:
	return state != FLYING


## The hint card holds it still (the first try).
func held() -> bool:
	return _hold > 0.0 and state == FLYING


## GO on the hint card.
func release() -> void:
	_hold = 0.0


func tick(delta: float, p_throttle: float) -> void:
	if state != FLYING or delta <= 0.0:
		return
	if _hold > 0.0:
		_hold = maxf(_hold - delta, 0.0)
		return
	throttle = clampf(p_throttle, 0.0, 1.0)
	time += delta
	var left := delta
	while left > 1e-9 and state == FLYING:
		var dt := minf(left, STEP)
		left -= dt
		var push := 0.0
		if fuel > 0.0:
			var burn := minf(throttle * dt, fuel)
			fuel -= burn
			push = thrust * (burn / dt)
		speed += (gravity - push) * dt
		height -= speed * dt
		var top := _start_h + CEILING
		if height > top:
			height = top
			speed = maxf(speed, 0.0)
		if height <= 0.0:
			height = 0.0
			touchdown_speed = speed
			state = LANDED if speed <= SAFE_SPEED + 0.0001 else CRASHED


func fuel_fraction() -> float:
	return clampf(fuel / fuel_max, 0.0, 1.0) if fuel_max > 0.0 else 0.0


## Seconds of hovering the fuel left keeps (the throttle at 40%).
func hover_seconds() -> float:
	return fuel * THRUST


## What the speed dial says now (its colour: COLORS).
func zone() -> StringName:
	if speed < -0.5:
		return UP
	var brake := thrust - gravity
	var h := maxf(height, 0.0)
	if _lands_after(speed, h, REACTION, GREEN_BRAKE * brake):
		return GREEN
	if speed <= sqrt(SAFE_SPEED * SAFE_SPEED + 2.0 * RED_BRAKE * brake * h):
		return YELLOW
	return RED


## Whether falling at `v` from `h`, coasting `react` seconds and then braking at `decel` (m/s²) touches down at or
## under SAFE_SPEED less GREEN_MARGIN (the ground sooner than `react`: whether it lands as it falls).
func _lands_after(v: float, h: float, react: float, decel: float) -> bool:
	var safe := SAFE_SPEED - GREEN_MARGIN
	var fall := v * react + 0.5 * gravity * react * react
	if fall >= h:
		return sqrt(maxf(v * v + 2.0 * gravity * h, 0.0)) <= safe
	return v + gravity * react <= sqrt(safe * safe + 2.0 * decel * (h - fall))


## The short words for now ("" while the hint card shows).
func words() -> String:
	if state == LANDED:
		return LANDED_WORDS
	if state == CRASHED:
		return CRASH_WORDS
	if held():
		return ""
	if fuel <= 0.0:
		return "Out of fuel!"
	var z := zone()
	if z == UP:
		return "Going up! Ease off the throttle."
	if z == RED:
		return "Slow down! Hold the throttle!"
	var left := hover_seconds()
	if left <= CALL_FUEL[1]:
		return "10 seconds of fuel left! Land now!"
	if left <= CALL_FUEL[0]:
		return "30 seconds of fuel left: down gently, not too slow."
	if z == YELLOW:
		return "Careful: slow down a little."
	if height < NEAR_GROUND:
		return "Good: gently now."
	return "Good speed. Watch the colours."


## Seconds between two beeps: quicker near the ground, quicker still when too fast.
func beep_every() -> float:
	var t := lerpf(0.18, 1.0, clampf(height / START_HEIGHT, 0.0, 1.0))
	return t * (0.7 if zone() == RED else 1.0)


## For a crew member's descent: the pilot's (follow).
func snapshot() -> Dictionary:
	return {"h": height, "v": speed, "f": fuel, "fm": fuel_max, "s": state, "hold": _hold, "thr": throttle,
		"tv": touchdown_speed, "e": easy}


## A crew member's descent shows the pilot's `s` (snapshot).
func follow(s: Dictionary) -> void:
	height = float(s.get("h", height))
	speed = float(s.get("v", speed))
	fuel = float(s.get("f", fuel))
	fuel_max = maxf(float(s.get("fm", fuel_max)), 0.001)
	_hold = float(s.get("hold", 0.0))
	throttle = float(s.get("thr", throttle))
	touchdown_speed = float(s.get("tv", touchdown_speed))
	easy = bool(s.get("e", easy))
	var st := int(s.get("s", state))
	state = st if st in [FLYING, LANDED, CRASHED] else state


## Tests and the smoke tools: the throttle a good pilot holds now (the game never flies the descent for a child).
static func test_pilot(d: FlightDescent) -> float:
	var brake := d.thrust - d.gravity
	var want := sqrt(1.0 + 2.0 * 0.35 * brake * maxf(d.height, 0.0))
	return clampf((d.gravity + 3.0 * (d.speed - want)) / d.thrust, 0.0, 1.0)
