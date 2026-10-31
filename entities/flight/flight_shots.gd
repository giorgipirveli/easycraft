class_name FlightShots
extends RefCounted
## What the flight shows at every moment (owner #79: "you actually fly into moon, here we need real animations and
## visuals"; #86 the movie-style moments; #87 a real landing), as pure rules. pose(phase, q, info) is a dictionary the
## RocketFlight node applies each frame:
##   world (the rocket is at the pad in the real world; false: in the flight's own space set), rise (m over the pad),
##   pitch (degrees the nose leans from straight up toward the flight's way, -Z), turn (0..1: turned round, engine first),
##   upright (0..1: stood up for landing), sky (0 the day's blue .. 1 space's black), air_sky (0..1 the destination's own
##   sky, a world with air), cloud (0..1 the clouds' white-out: the step from the world into space happens under it),
##   fire (0..1 the engines' flame), smoke (the pad's smoke), shake, earth / dest ({show, dir (from the rocket to the
##   body's centre), alt (set units from its ground: VISUAL_R is its radius close up)}), ground (the landing ground shows)
##   and ground_h (m under the rocket's feet), legs, chute, heat (0..1), air, moment (a movie moment's phase or &""),
##   stretch, flash, tunnel, swirl, rocks, nebula (the moments' strengths), target (what the child steers at: &"ring",
##   &"dest", &"pad", &""), chase (&"behind", &"front", &"side": where the outside camera sits), look_pitch (degrees the
##   inside camera looks above the horizon). Owner #106: tilt (degrees a crashed lander tips over), side (m beside the
##   pad where the capsule comes home in the world, never on the rocket standing there), wreck (0..1 the rocket's fall by
##   the Launch Site, -1 none), look (&"pad": the launch camera looks at the pad).
## info: {"destination", "time" (s), "waiting" (the action the rocket waits for), "done" (the step's action is done),
## "throttle", "auto_burn", "flown" (a whole flight; false: a landing on its own), "burn_at" (the step's action point, 0..1),
## owner #106: "descent" ({h, v, thr, state, fuel}: the child's descent, FlightDescent), "descent_from" (m: where it
## starts)}.

## Where in the climb the clouds are thickest: the scene changes from the world to the space set there.
const CLOUD_AT := 0.32
## Owner #101/#108: the climb goes on at the lift-off's last speed (its 40 m over 6 s end at 13.3 m/s) instead of
## stopping dead at 40 m and speeding up again (a seated head in VR feels that jolt): the metres that speed covers over
## the climb under the clouds (CLOUD_AT of its 18 s).
const ASCENT_CARRY := 77.0
## A body's radius in the set when it is close (set units); far away it is drawn smaller and nearer (RocketFlight keeps
## its size in the sky right).
const VISUAL_R := 20000.0
const EARTH_KM := 6371.0
## Radii (km) of the worlds a trip can go to (a make-believe planet: 3,000).
const RADIUS_KM := {SpaceRules.MOON: 1737.0, SpaceRules.MARS: 3390.0, SpaceRules.EUROPA: 1561.0, SpaceRules.IO: 1822.0,
	SpaceRules.TITAN: 2575.0, SpaceRules.MERCURY: 2440.0, SpaceRules.VENUS: 6052.0, SpaceRules.RINGS: 58232.0,
	SpaceRules.PLUTO: 1188.0, SpaceRules.TRITON: 1353.0, SpaceRules.GANYMEDE: 2634.0}
const AHEAD := Vector3(0.0, 0.08, -1.0)
const BEHIND := Vector3(0.0, -0.35, 1.0)
const LAND_FROM := 180.0          # m of ground under the lander as the landing starts
const CHUTE_FROM := 900.0
## Owner #106: how far a crashed lander tips over; where the capsule comes home (m beside the pad, and from how high);
## when the falling rocket hits the ground (0..1 through WRECK).
const CRASH_TILT := 28.0
const HOME_SIDE := 14.0
const HOME_FROM := 140.0
const WRECK_HIT := 0.45

const _SHORTCUTS: Array[StringName] = [FlightPlan.JUMP, FlightPlan.WARP, FlightPlan.WORMHOLE, FlightPlan.ASTEROIDS,
	FlightPlan.NEBULA]


static func radius_km(destination: int) -> float:
	return RADIUS_KM.get(destination, 3000.0)


static func pose(phase: StringName, q: float, info: Dictionary) -> Dictionary:
	var dest := int(info.get("destination", SpaceRules.MOON))
	var air := FlightPlan.has_air(dest)
	var flown := bool(info.get("flown", true))
	var done := bool(info.get("done", false))
	var waiting: StringName = info.get("waiting", &"")
	var throttle := float(info.get("throttle", 0.0))
	var burning := waiting == FlightPlan.BURN and (throttle >= 0.5 or bool(info.get("auto_burn", false)))
	var burn_at := float(info.get("burn_at", 1.0))
	var p := {"world": false, "rise": 0.0, "pitch": 90.0, "turn": 0.0, "upright": 0.0, "sky": 1.0, "air_sky": 0.0,
		"cloud": 0.0, "fire": 0.0, "smoke": false, "shake": 0.0, "ground": false, "ground_h": 0.0, "legs": 0.0,
		"chute": 0.0, "heat": 0.0, "air": false, "moment": &"", "stretch": 1.0, "flash": 0.0, "tunnel": 0.0,
		"swirl": 0.0, "rocks": 0.0, "nebula": 0.0, "target": &"", "chase": &"behind", "look_pitch": 0.0,
		"tilt": 0.0, "side": 0.0, "wreck": -1.0, "look": &"",
		"earth": {"show": false, "dir": Vector3.DOWN, "alt": 1000.0},
		"dest": {"show": false, "dir": AHEAD.normalized(), "alt": 1e9}}
	var dest_scale := VISUAL_R / radius_km(dest)
	var earth_scale := VISUAL_R / EARTH_KM
	match phase:
		FlightPlan.BOARD, FlightPlan.COUNTDOWN:
			p.world = true
			p.pitch = 0.0
			p.sky = 0.0
			p.look_pitch = 8.0
			if phase == FlightPlan.COUNTDOWN and q >= 0.7:
				p.fire = lerpf(0.2, 0.45, (q - 0.7) / 0.3)
				p.smoke = true
				p.shake = 0.05
		FlightPlan.LIFTOFF:
			p.world = true
			p.pitch = 0.0
			p.sky = 0.0
			p.look_pitch = 8.0
			p.smoke = true
			if waiting == FlightPlan.THROTTLE:
				p.fire = 0.45 + 0.4 * throttle
				p.shake = 0.08 + 0.1 * throttle
			else:
				p.fire = 1.0
				p.rise = 40.0 * q * q
				p.shake = 0.3
		FlightPlan.ASCENT:
			p.fire = 1.0
			p.target = &"ring"
			p.cloud = smoothstep(CLOUD_AT - 0.1, CLOUD_AT, q) if q <= CLOUD_AT else 1.0 - smoothstep(CLOUD_AT, CLOUD_AT + 0.12, q)
			if q < CLOUD_AT:
				var w := q / CLOUD_AT
				p.world = true
				p.rise = 40.0 + ASCENT_CARRY * w + (280.0 - ASCENT_CARRY) * pow(w, 1.7)
				p.pitch = 20.0 * w
				p.sky = 0.35 * w
				p.smoke = p.rise < 60.0
				p.shake = lerpf(0.25, 0.12, w)
				p.look_pitch = 8.0
			else:
				var s := (q - CLOUD_AT) / (1.0 - CLOUD_AT)
				p.pitch = lerpf(20.0, 75.0, s)
				p.sky = lerpf(0.35, 1.0, clampf(s / 0.8, 0.0, 1.0))
				p.shake = 0.06
				p.earth = {"show": true, "dir": Vector3.DOWN, "alt": lerpf(350.0, 900.0, s)}
				p.look_pitch = lerpf(8.0, -35.0, s)
		FlightPlan.STAGING:
			var first := float(info.get("nth", 0)) == 0.0
			p.pitch = lerpf(75.0, 88.0, q) if first else 90.0
			p.fire = 0.7 if done else 0.0
			p.shake = 0.25 if done and q < 0.35 else 0.0
			p.chase = &"side"
			p.look_pitch = -35.0
			p.earth = {"show": true, "dir": Vector3.DOWN if first else BEHIND.normalized(),
				"alt": lerpf(900.0, 950.0, q) if first else lerpf(4000.0, 6000.0, q)}
			if not first:
				p.dest = {"show": true, "dir": AHEAD.normalized(), "alt": _far_alt(dest, dest_scale)}
		FlightPlan.ORBIT:
			var before := clampf(q / burn_at, 0.0, 1.0)
			var gone := clampf((q - burn_at) / (1.0 - burn_at), 0.0, 1.0) if done else 0.0
			p.fire = 1.0 if burning else 0.0
			p.target = &"dest"
			p.chase = &"behind" if not done else &"front"
			p.look_pitch = lerpf(-35.0, 0.0, clampf(before * 2.0 - 1.0, 0.0, 1.0))
			p.earth = {"show": true, "dir": Vector3.DOWN.slerp(BEHIND.normalized(), smoothstep(0.0, 1.0, gone)),
				"alt": lerpf(950.0, 1100.0, before) + lerpf(0.0, 3000.0, gone)}
			p.dest = {"show": q >= burn_at * 0.3, "dir": AHEAD.normalized(), "alt": _far_alt(dest, dest_scale)}
		FlightPlan.JUMP, FlightPlan.WARP, FlightPlan.WORMHOLE, FlightPlan.ASTEROIDS, FlightPlan.NEBULA:
			p.moment = phase
			p.chase = &"front"
			var fade := smoothstep(0.0, 0.12, q) * (1.0 - smoothstep(0.88, 1.0, q))
			match phase:
				FlightPlan.JUMP:
					p.stretch = 1.0 + 79.0 * smoothstep(0.0, 0.4, q)
					p.flash = clampf(1.0 - absf(q - 0.45) / 0.07, 0.0, 1.0)
					p.earth = {"show": q < 0.45, "dir": BEHIND.normalized(), "alt": 8000.0}
				FlightPlan.WARP:
					p.tunnel = fade
				FlightPlan.WORMHOLE:
					p.swirl = smoothstep(0.0, 0.3, q) * (1.0 - smoothstep(0.3, 0.4, q))
					p.tunnel = smoothstep(0.3, 0.4, q) * (1.0 - smoothstep(0.88, 1.0, q))
					p.flash = clampf(1.0 - absf(q - 0.35) / 0.05, 0.0, 1.0)
				FlightPlan.ASTEROIDS:
					p.rocks = fade
					p.target = &"ring"
				FlightPlan.NEBULA:
					p.nebula = fade
		FlightPlan.CRUISE:
			p.target = &"dest"
			p.chase = &"front"
			var km: float
			if FlightPlan.moments(dest).is_empty():   # the Moon: its whole way, the Earth falling behind
				var e := 1.0 - pow(1.0 - q, 1.6)
				km = lerpf(384400.0, 2400.0, e)
				p.earth = {"show": true, "dir": BEHIND.normalized(), "alt": lerpf(4000.0, (384400.0 - 2400.0) * earth_scale, e)}
			else:
				km = lerpf(1000000.0, 5000.0, 1.0 - pow(1.0 - q, 2.5))
			p.dest = {"show": true, "dir": AHEAD.normalized().slerp(Vector3.FORWARD, q), "alt": km * dest_scale}
		FlightPlan.ARRIVE:
			p.turn = smoothstep(0.0, 0.3, q)
			p.fire = 1.0 if burning else 0.0
			p.chase = &"above"
			p.look_pitch = lerpf(0.0, -30.0, q)
			p.dest = {"show": true, "dir": Vector3.FORWARD.slerp(Vector3.DOWN, smoothstep(0.0, 1.0, q)),
				"alt": lerpf(2400.0, FlightDials.ORBIT_HEIGHT, q) * dest_scale}
		FlightPlan.DEORBIT:
			p.turn = 1.0
			p.upright = smoothstep(0.0, 1.0, q)
			p.fire = 0.8
			p.shake = 0.05
			p.chase = &"above"
			p.look_pitch = -35.0
			p.dest = {"show": true, "dir": Vector3.DOWN,
				"alt": lerpf(FlightDials.ORBIT_HEIGHT, FlightDials.DEORBIT_TO, q) * dest_scale}
		FlightPlan.ENTRY:
			p.upright = 0.75
			p.turn = 1.0
			p.heat = sin(PI * q)
			p.shake = 0.3 * p.heat
			p.chase = &"side"
			p.look_pitch = -30.0
			p.air_sky = 0.6 * q
			p.dest = {"show": true, "dir": Vector3(0, -0.5, -1).normalized().slerp(Vector3.DOWN, q),
				"alt": lerpf(FlightDials.ENTRY_HEIGHT, FlightDials.CHUTE_HEIGHT, q) * dest_scale}
		FlightPlan.CHUTE:
			p.upright = 1.0
			p.air = true
			p.air_sky = lerpf(0.6, 1.0, q)
			p.ground = true
			p.ground_h = lerpf(CHUTE_FROM, LAND_FROM, q)
			p.chute = 1.0 if (done if flown else q >= 0.2) else 0.0
			p.chase = &"side"
			p.look_pitch = -40.0
		FlightPlan.LANDING:
			p.upright = 1.0
			p.air = air
			p.air_sky = 1.0 if air else 0.0
			p.ground = true
			# owner #106: down to where the child's descent starts
			p.ground_h = lerpf(LAND_FROM, float(info.get("descent_from", FlightDescent.START_HEIGHT)), smoothstep(0.0, 1.0, q))
			p.target = &"pad"
			p.chase = &"side"
			p.look_pitch = -45.0
			p.shake = 0.06
			var legs_out := done if flown else q >= 0.12
			p.legs = 1.0 if legs_out else 0.0
			if air and q < 0.1:
				p.chute = 1.0
			else:
				p.fire = 0.45 + 0.4 * throttle if (legs_out or not flown) else 0.4
		FlightPlan.LANDED:
			p.upright = 1.0
			p.air = air
			p.air_sky = 1.0 if air else 0.0
			p.ground = true
			p.legs = 1.0
			p.chase = &"side"
			p.look_pitch = -20.0
			p.shake = 0.25 if q < 0.1 else 0.0
		FlightPlan.DESCENT, FlightPlan.CRASH, FlightPlan.ESCAPE, FlightPlan.HOME_ENTRY, FlightPlan.HOME_CHUTE, \
				FlightPlan.WRECK, FlightPlan.HOME:
			_crash_pose(p, phase, q, info, air, dest_scale, earth_scale)
	p.air = p.air or (air and phase in [FlightPlan.CHUTE, FlightPlan.LANDING, FlightPlan.DESCENT, FlightPlan.LANDED,
		FlightPlan.CRASH])
	return vr_pose(p) if bool(info.get("vr", false)) else p


## Owner #106: the descent the child flies, and the way home after a crash.
static func _crash_pose(p: Dictionary, phase: StringName, q: float, info: Dictionary, air: bool, dest_scale: float,
		earth_scale: float) -> void:
	match phase:
		FlightPlan.DESCENT:
			var d: Dictionary = info.get("descent", {})
			var state := int(d.get("state", FlightDescent.FLYING))
			p.upright = 1.0
			p.air_sky = 1.0 if air else 0.0
			p.ground = true
			p.ground_h = maxf(float(d.get("h", info.get("descent_from", FlightDescent.START_HEIGHT))), 0.0)
			p.legs = 1.0
			p.target = &"pad"
			p.chase = &"side"
			p.look_pitch = -45.0
			var thr := float(d.get("thr", info.get("throttle", 0.0)))
			if state == FlightDescent.FLYING:
				p.fire = 0.12 + 0.88 * thr if float(d.get("fuel", 1.0)) > 0.0 else 0.0
				p.shake = 0.03 + 0.07 * thr
			elif state == FlightDescent.CRASHED:
				p.tilt = CRASH_TILT * smoothstep(0.0, 0.4, q)
				p.shake = 0.4 * (1.0 - smoothstep(0.0, 0.6, q))
			else:
				p.shake = 0.2 if q < 0.15 else 0.0
		FlightPlan.CRASH:   # tipped over in the dust; then the capsule's rescue rockets lift it up and away
			var lift := smoothstep(0.55, 1.0, q)
			p.upright = 1.0
			p.air_sky = 1.0 if air else 0.0
			p.ground = true
			p.ground_h = 140.0 * lift
			p.legs = 1.0
			p.tilt = CRASH_TILT * (1.0 - smoothstep(0.5, 0.75, q))
			p.fire = 1.0 if q >= 0.55 else 0.0
			p.shake = 0.3 if q < 0.12 else (0.12 if q >= 0.55 else 0.0)
			p.chase = &"side"
			p.look_pitch = -25.0
		FlightPlan.ESCAPE:   # home: the Earth ahead and growing, the world behind
			var e := 1.0 - pow(1.0 - q, 1.6)
			p.fire = 1.0 if q < 0.3 else 0.0
			p.chase = &"front"
			p.target = &"dest"
			p.earth = {"show": true, "dir": AHEAD.normalized().slerp(Vector3.DOWN, smoothstep(0.7, 1.0, q)),
				"alt": lerpf(200000.0 * earth_scale, 900.0, e)}   # (set units: 900 is where the re-entry starts)
			p.dest = {"show": true, "dir": BEHIND.normalized(), "alt": lerpf(300.0, 60000.0, e) * dest_scale}
			p.look_pitch = lerpf(0.0, -20.0, q)
		FlightPlan.HOME_ENTRY:   # a fiery re-entry, down into the clouds (the real world is under them)
			p.upright = 0.75
			p.turn = 1.0
			p.heat = sin(PI * clampf(q / 0.85, 0.0, 1.0))
			p.shake = 0.3 * float(p.heat)
			p.chase = &"side"
			p.look_pitch = -30.0
			p.earth = {"show": true, "dir": Vector3.DOWN, "alt": lerpf(900.0, 350.0, q)}
			p.cloud = smoothstep(0.7, 1.0, q)
		FlightPlan.HOME_CHUTE:   # the real world: under the parachute, down beside the pad
			p.world = true
			p.sky = 0.0
			p.upright = 1.0
			p.chute = 1.0
			p.legs = 1.0 if q > 0.5 else 0.0
			p.side = HOME_SIDE
			p.rise = HOME_FROM * (1.0 - smoothstep(0.0, 1.0, q))
			p.cloud = 1.0 - smoothstep(0.0, 0.15, q)
			p.chase = &"side"
			p.look_pitch = -20.0
			p.shake = 0.15 if q > 0.96 else 0.0
		FlightPlan.WRECK, FlightPlan.HOME:   # the capsule down; the rocket falls by the Launch Site
			p.world = true
			p.sky = 0.0
			p.upright = 1.0
			p.legs = 1.0
			p.side = HOME_SIDE
			p.look = &"pad"
			p.chase = &"side"
			if phase == FlightPlan.WRECK:
				p.wreck = q
				p.shake = 0.35 if q >= WRECK_HIT and q < WRECK_HIT + 0.12 else 0.0
			else:
				p.wreck = 1.0


## Owner #101: the shots in a headset (info "vr"): never a shake (the engine's rumble is the controllers' buzz and the
## sound), the light-speed flash halved and the clouds' white-out softer (a headset fills the eyes: photosensitivity),
## and the inside camera's look_pitch gone (the child's own head looks round the capsule). Owner #106/#108: a crashed
## lander never tips over (from inside a tip is only the seat lurching sideways; the crash is the dimming, the bump's
## sound and the controllers' buzz).
const VR_FLASH := 0.5
const VR_CLOUD := 0.6


static func vr_pose(p: Dictionary) -> Dictionary:
	p.shake = 0.0
	p.tilt = 0.0
	p.flash = float(p.flash) * VR_FLASH
	p.cloud = float(p.cloud) * VR_CLOUD
	p.look_pitch = 0.0
	return p


## Far away: the destination a dot the sky keeps visible (RocketFlight keeps a target at least a little round).
static func _far_alt(destination: int, dest_scale: float) -> float:
	var km: float = FlightDials.DISTANCE.get(destination, 1000000.0)
	return km * dest_scale
