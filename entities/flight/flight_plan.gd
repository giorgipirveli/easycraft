class_name FlightPlan
extends RefCounted
## The rocket flight's steps (owner #79: "you just sit into it at steering wheel and fly to moon, you actually fly into
## moon"; #86: movie-style moments; spec §25.3, §21d.4), as pure rules. A trip is a list of steps, each
## {"phase", "seconds", "action" (what the child does: &"" none), "at" (seconds into the step where the rocket waits for
## it), "steer" (the child steers), "view" (the camera the story picks: INSIDE the capsule, CHASE outside, LAUNCH from the
## ground), "words" (said as it starts), "after" (said once the action is done)}. RocketFlight plays them (FlightRun).
## The trip to the Moon is the real one in a couple of minutes (its 3 days shown in seconds, the words say so); farther
## worlds take our game's shortcuts (light speed, a warp tunnel, a wormhole) and fly past what is really on the way (the
## asteroid belt between Mars and Jupiter), each moment with words that keep the science true. Worlds with air (Mars,
## Titan, Venus, our own playful planets) have a fiery entry and a parachute instead of an engine burn into orbit.
## Owner #106: the landing is the child's own skill. Every trip ends with the DESCENT the child flies (DESCEND: the
## throttle against the world's pull, FlightDescent; no autopilot there); too fast is a crash, and the rest of the trip
## becomes the way home (crash_steps: the crew's capsule back to Earth, a parachute by the Launch Site, the rocket falling
## there too). The Star Map's LAND ends with a practice descent.

const BOARD := &"board"           # the camera glides into the capsule
const COUNTDOWN := &"countdown"   # 10 … 1, spoken
const LIFTOFF := &"liftoff"       # the rocket rises off the pad
const ASCENT := &"ascent"         # through the clouds, the sky turning black, the gravity turn
const STAGING := &"staging"       # an empty stage falls away
const ORBIT := &"orbit"           # round the Earth; aim at the destination and burn
const JUMP := &"jump"             # light speed: stars stretch into lines, a flash (a movie-style moment)
const WARP := &"warp"             # a warp tunnel
const WORMHOLE := &"wormhole"     # a wormhole's swirl
const ASTEROIDS := &"asteroids"   # the asteroid belt (really between Mars and Jupiter)
const NEBULA := &"nebula"         # a coloured cloud of gas and dust
const CRUISE := &"cruise"         # the long way, the destination growing ahead
const ARRIVE := &"arrive"         # turn round and burn to slow down into orbit (airless worlds)
const DEORBIT := &"deorbit"       # from orbit over the world: the engine burns to come down
const ENTRY := &"entry"           # a fiery entry through the air: the heat shield glows
const CHUTE := &"chute"           # the parachute
const LANDING := &"landing"       # legs out, the ground rising
const DESCENT := &"descent"       # owner #106: the child flies the last 120 m down (FlightDescent)
const LANDED := &"landed"
## Owner #106: the way home after a crash (crash_steps).
const CRASH := &"crash"           # the lander hits the ground too fast: dust, a bump; everyone is safe
const ESCAPE := &"escape"         # the capsule's rescue rockets carry the crew home: the Earth ahead
const HOME_ENTRY := &"home_entry" # a fiery re-entry into Earth's air
const HOME_CHUTE := &"home_chute" # in the real world again: the capsule under its parachute, by the Launch Site
const WRECK := &"wreck"           # the rocket falls by the Launch Site too, and parts break
const HOME := &"home"             # what broke; the screen fades

## What the child does (the ACTION button, Space on a PC; the throttle: the lever, Shift on a PC).
const THROTTLE := &"throttle"     # push the throttle all the way up: lift-off
const STAGE := &"stage"           # let the empty stage go
const BURN := &"burn"             # hold the throttle for BURN_SECONDS
const LEGS := &"legs"             # landing legs out
const PARACHUTE := &"parachute"   # open the parachute
const DESCEND := &"descend"       # owner #106: fly the descent down to a soft touchdown (never the autopilot's)

const INSIDE := &"inside"
const CHASE := &"chase"
const LAUNCH := &"launch"

## Seconds the rocket waits for the child at an action before the autopilot does it (kindly: never stuck). Owner #106:
## never at DESCEND (the landing is the child's).
const ACTION_WAIT := 5.0
## Seconds of throttle a burn needs.
const BURN_SECONDS := 2.5

const MOMENT_SECONDS := {JUMP: 6.0, WARP: 8.0, WORMHOLE: 8.0, ASTEROIDS: 10.0, NEBULA: 8.0}

## How long real spacecraft take (rounded; the notes give the sources).
const REAL_TRIP := {
	SpaceRules.MOON: "3 days", SpaceRules.MARS: "about 7 months", SpaceRules.VENUS: "about 5 months",
	SpaceRules.MERCURY: "about 7 years", SpaceRules.EUROPA: "about 6 years", SpaceRules.IO: "about 6 years",
	SpaceRules.TITAN: "about 7 years", SpaceRules.RINGS: "about 7 years", SpaceRules.PLUTO: "about 9 and a half years",
	SpaceRules.TRITON: "about 12 years", SpaceRules.GANYMEDE: "almost 12 years",
}
const _AIR: Array[int] = [SpaceRules.MARS, SpaceRules.TITAN, SpaceRules.VENUS, SpaceRules.BOING, SpaceRules.RAINBOW]
const _NEAR: Array[int] = [SpaceRules.MARS, SpaceRules.VENUS, SpaceRules.MERCURY]
const _JUPITER: Array[int] = [SpaceRules.EUROPA, SpaceRules.IO, SpaceRules.GANYMEDE]
const _FAR: Array[int] = [SpaceRules.TITAN, SpaceRules.RINGS, SpaceRules.PLUTO, SpaceRules.TRITON]


## The steps of a trip to world `destination` in a rocket of `stages` stages.
static func steps(destination: int, stages: int) -> Array[Dictionary]:
	var name := body_name(destination)
	var out: Array[Dictionary] = []
	out.append(_step(BOARD, 3.0, INSIDE, "Climb in and buckle up! You are the pilot."))
	out.append(_step(COUNTDOWN, 10.0, INSIDE, "Get ready for lift-off!"))
	out.append(_act(LIFTOFF, 6.0, LAUNCH, "Push the throttle all the way up!", THROTTLE, 0.0, "Lift-off! We have lift-off!"))
	out.append(_step(ASCENT, 18.0, INSIDE, "Steer into the green ring! Up through the clouds!", true))
	if stages >= 2:
		out.append(_act(STAGING, 5.0, CHASE, "Stage 1 is empty. Let it go: press STAGE!", STAGE, 1.0,
			"It falls back to Earth. Now the rocket is lighter!"))
	var aim := "Aim at %s and hold the throttle to burn!" % name
	out.append(_act(ORBIT, 16.0, CHASE, "We are in orbit! Going round the Earth at almost 8 km every second!", BURN, 9.0,
		"Off we go to %s!" % name, true, aim))
	if stages >= 3:
		out.append(_act(STAGING, 5.0, CHASE, "Stage 2 is empty too: press STAGE!", STAGE, 1.0,
			"Only the lander is left. It will land us!"))
	var shortcuts := moments(destination)
	for m in shortcuts:
		out.append(_step(m, MOMENT_SECONDS[m], INSIDE if m != ASTEROIDS else CHASE, _moment_words(m, destination),
			m == ASTEROIDS))
	if shortcuts.is_empty():
		out.append(_step(CRUISE, 22.0, INSIDE, trip_words(destination), true))
	else:
		out.append(_step(CRUISE, 7.0, INSIDE, "Here comes %s!" % name, true))
	if not has_air(destination):
		out.append(_act(ARRIVE, 12.0, CHASE, "Turn round: the engine must push against our way to slow us down!", BURN, 4.0,
			"We are in orbit round %s!" % name, false, "Hold the throttle to burn, or we fly past!"))
	out.append_array(landing_steps(destination, true))
	return out


## The landing (owner #87: "landing on mercury should be done like real landing"): from orbit over the world the engine
## burns to come down (DEORBIT; a world with air: a fiery ENTRY and the parachute instead), the legs come out, the
## ground rises, dust at touchdown on the pad. A whole flight ends with it (`flown`: the child presses LEGS and CHUTE);
## on its own (the Star Map's LAND, RocketFlight.land) the autopilot puts the legs out and opens the parachute. Owner
## #106: either way the last 120 m are the child's (DESCENT: the throttle slows the fall; on its own a practice one).
static func landing_steps(destination: int, flown: bool = false) -> Array[Dictionary]:
	var name := body_name(destination)
	var out: Array[Dictionary] = []
	if has_air(destination):
		var hot := "%s has air! Rushing through it makes the heat shield glow hot!" % _capital(name)
		if flown:
			out.append(_step(ENTRY, 9.0, CHASE, hot))
			out.append(_act(CHUTE, 7.0, CHASE, "Open the parachute: press CHUTE!", PARACHUTE, 1.0,
				"The parachute slows us down!"))
		else:
			out.append(_step(ENTRY, 3.5, CHASE, hot))
			out.append(_step(CHUTE, 3.0, CHASE, "The parachute opens and slows us down!"))
	else:
		out.append(_step(DEORBIT, 4.0 if flown else 3.5, CHASE,
			"Coming down from orbit over %s: the engine burns to slow us down!" % name))
	if flown:
		out.append(_act(LANDING, 6.0, CHASE, "Landing legs out: press LEGS!", LEGS, 1.5,
			"Legs out! Steer over the landing pad: the landing is yours.", true))
		out.append(descent_step(destination, false))
		out.append(_step(LANDED, 4.0, CHASE, "Touchdown! You flew to %s!" % name))
	else:
		out.append(_step(LANDING, 3.5 if not has_air(destination) else 3.0, CHASE,
			"Landing legs out! The ground is coming up: steer over the pad!", true))
		out.append(descent_step(destination, true))
		out.append(_step(LANDED, 2.5, CHASE, "Touchdown on %s!" % name))
	return out


## Owner #106: the descent the child flies (DESCEND waits until the touchdown: FlightRun gives it to FlightDescent).
## `practice`: the Star Map's LAND (a crash tries again).
static func descent_step(destination: int, practice: bool = false) -> Dictionary:
	var words := "Now you land it! Hold the throttle to slow the fall. Touch down slower than 3 m/s."
	if practice:
		words = "Practice landing! Hold the throttle to slow the fall. Touch down slower than 3 m/s."
	return _act(DESCENT, 1.0, CHASE, words, DESCEND, 0.0, "Touchdown! A soft landing on %s!" % body_name(destination),
		true)


## Owner #106: the way home after a crash (the rest of the trip becomes this). Nothing waits for the child. The crew is
## safe: the capsule's rescue rockets carry it home (a real fact on the way), a fiery re-entry, the parachute down by the
## home world's Launch Site (in the real world again), the rocket falling there too and breaking some of its parts.
static func crash_steps(destination: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		_step(CRASH, 3.5, CHASE, ("Too fast: the lander crashed on %s! Everyone is safe: the capsule's rescue rockets "
			+ "carry the crew up and away.") % body_name(destination)),
		_step(ESCAPE, 6.0, INSIDE, "Heading home to Earth. " + CrashRules.FACT),
		_step(HOME_ENTRY, 4.0, CHASE, "Into Earth's air: the heat shield glows hot!"),
		_step(HOME_CHUTE, 6.0, CHASE, "The parachute opens. Home, by the Launch Site!"),
		_step(WRECK, 4.5, LAUNCH, "Look up: your rocket falls too!"),
		_step(HOME, 3.5, LAUNCH, "Some parts broke. Rebuild them at the Mission Board and try again!"),
	]
	return out


## Seconds of all the steps (without the waits for the child).
static func total_seconds(list: Array[Dictionary]) -> float:
	var t := 0.0
	for s in list:
		t += float(s.seconds)
	return t


## The movie-style moments on the way (owner #86), in our own look.
static func moments(destination: int) -> Array[StringName]:
	if destination == SpaceRules.MOON:
		return []
	if _NEAR.has(destination):
		return [JUMP, WARP]
	if _JUPITER.has(destination):
		return [JUMP, ASTEROIDS, WARP]
	if _FAR.has(destination):
		return [JUMP, ASTEROIDS, WORMHOLE]
	return [WORMHOLE, NEBULA]


static func has_air(destination: int) -> bool:
	return _AIR.has(destination)


## The destination's name in a sentence ("the Moon", "Mars", "Planet Boing").
static func body_name(destination: int) -> String:
	if destination == SpaceRules.MOON:
		return "the Moon"
	var body := FlightLooks.star_body(destination)
	if not body.is_empty():
		return str(body.get("name", "the planet"))
	var shown := UniverseRegistry.display_name(destination) if destination >= 1 and destination <= UniverseRegistry.size() else ""
	return shown if shown != "" else "the planet"


## What the long cruise says: the real trip's length, and when the game takes a shortcut, that it is one.
static func trip_words(destination: int) -> String:
	var name := body_name(destination)
	if destination == SpaceRules.MOON:
		return "Off to the Moon! The real trip takes 3 days: we show it in 20 seconds."
	if REAL_TRIP.has(destination):
		return ("Real rockets take %s to reach %s. Real rockets cannot go faster than light: light speed is our game's "
			+ "shortcut!") % [REAL_TRIP[destination], name]
	return "%s is far, far away: only our game's shortcuts get us there!" % _capital(name)


static func _moment_words(m: StringName, destination: int) -> String:
	match m:
		JUMP:
			return "Light speed! The stars stretch into lines. " + (trip_words(destination) if REAL_TRIP.has(destination)
				else "Real rockets cannot go faster than light: this is our game's shortcut!")
		WARP:
			return "A warp tunnel! Only in stories and games: our shortcut through space."
		ASTEROIDS:
			return "The asteroid belt: millions of rocks going round the Sun between Mars and Jupiter. Steer past them! (Really they are far apart.)"
		WORMHOLE:
			return "A wormhole! Scientists wonder if shortcuts like this could exist. Nobody has found one yet."
		NEBULA:
			return "A nebula: a giant glowing cloud of gas and dust, where new stars are born."
	return ""


static func _step(phase: StringName, seconds: float, view: StringName, words: String, steer: bool = false) -> Dictionary:
	return {"phase": phase, "seconds": seconds, "action": &"", "at": 0.0, "steer": steer, "view": view, "words": words,
		"after": "", "prompt": ""}


## A step with an action: `prompt` is said when the rocket starts waiting for it (when it is not at the step's start).
static func _act(phase: StringName, seconds: float, view: StringName, words: String, action: StringName, at: float,
		after: String, steer: bool = false, prompt: String = "") -> Dictionary:
	var s := _step(phase, seconds, view, words, steer)
	s.action = action
	s.at = at
	s.after = after
	s.prompt = prompt
	return s


static func _capital(text: String) -> String:
	return text.substr(0, 1).to_upper() + text.substr(1)
