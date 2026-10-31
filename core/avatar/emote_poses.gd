class_name EmotePoses
extends RefCounted
## Emote and dance poses over time (M3 Task 9; spec §5.9, research X4), shared by both avatar
## styles: the blocky body turns its limb boxes, the realistic one its bones (EmotePoser), so every
## emote looks the same in both. The kenney clips have no emotes; these are code poses.
##
## A pose (sample) is a Dictionary:
##   l_arm, r_arm: Vector2(pitch, spread): the arm hangs down, is spread out to its side by `spread`
##     (rad, < 0 crosses in front), then swung forward and up about X by `pitch` (> 0 forward and up;
##     PI is straight up). The same convention as BlockyAvatar's arms and SwimStrokes.arm_turn.
##   l_leg, r_leg: pitch (> 0 forward).
##   hop: the body's lift (blocks), spin: its turn about Y (rad), lean: its tilt (> 0 back, rad),
##   sit: 0..1, how far it has sat down (the avatar lowers the body by its own SIT_DROP).
##   head (owner #94): Vector3(nod, turn, tilt) in rad: > 0 looks up, turns to its left, tilts; both bodies turn it.
## Owner #94: think, yawn and stretch (free on the wheel), and the body's own look (an idle glance round) and hooray (a
## happy little jump and spin: Player.react_happy); AnimIdle picks the idle ones.

## Moving faster than this (m/s) stops an emote (like any game: walk away and it ends).
const STOP_SPEED := 0.8
## Seconds; INF = until the player moves (sit and the dances).
const DURATIONS := {
	&"wave": 2.2, &"cheer": 1.8, &"laugh": 2.0, &"thumbs_up": 1.6, &"clap": 2.0, &"bow": 1.6,
	&"sit": INF, &"dance_hop": INF, &"dance_robot": INF, &"dance_star": INF, &"victory": 3.2,
	&"think": 2.6, &"yawn": 2.4, &"stretch": 2.2, &"look": 2.8, &"hooray": 1.1,
}
const STAR_TURN := 1.5          # seconds per turn of the Star Spin
const ROBOT_STEP := 0.5         # seconds per Robot move


static func has(emote: StringName) -> bool:
	return DURATIONS.has(emote)


static func duration(emote: StringName) -> float:
	return float(DURATIONS.get(emote, 0.0))


static func finished(emote: StringName, t: float) -> bool:
	return t >= duration(emote)


static func stops_at(speed: float) -> bool:
	return speed > STOP_SPEED


static func rest() -> Dictionary:
	return {"l_arm": Vector2.ZERO, "r_arm": Vector2.ZERO, "l_leg": 0.0, "r_leg": 0.0, "hop": 0.0, "spin": 0.0,
		"lean": 0.0, "sit": 0.0, "head": Vector3.ZERO}


## The pose of `emote` at `t` seconds after it started.
static func sample(emote: StringName, t: float) -> Dictionary:
	var p := rest()
	match emote:
		&"wave":
			p.r_arm = Vector2(2.75, 0.35 + 0.35 * sin(t * 10.0))
		&"cheer":
			var up := Vector2(2.85, 0.45 + 0.1 * sin(t * 8.0))
			p.l_arm = up
			p.r_arm = up
			p.hop = absf(sin(t * 6.0)) * 0.22
		&"laugh":
			p.l_arm = Vector2(0.6, -0.25)
			p.r_arm = Vector2(0.6, -0.25)
			p.lean = 0.18 + 0.06 * sin(t * 22.0)
			p.hop = absf(sin(t * 11.0)) * 0.03
		&"thumbs_up":
			p.r_arm = Vector2(1.5 + 0.05 * sin(t * 6.0), 0.15)
		&"clap":
			var clap := Vector2(1.35, lerpf(-0.3, 0.1, 0.5 + 0.5 * sin(t * 14.0)))
			p.l_arm = clap
			p.r_arm = clap
		&"bow":
			var dip := sin(clampf(t / duration(emote), 0.0, 1.0) * PI)
			p.lean = -0.65 * dip
			p.r_arm = Vector2(0.9 * dip, -0.3 * dip)   # the hand to the tummy
		&"sit":
			var s := smoothstep(0.0, 0.45, t)
			p.sit = s
			p.l_leg = 1.5 * s
			p.r_leg = 1.5 * s
			p.l_arm = Vector2(0.5 * s, 0.15 * s)
			p.r_arm = Vector2(0.5 * s, 0.15 * s)
			p.lean = 0.08 * s
		&"dance_hop":   # Bunny Hop: paws up, hop, kick a foot out each time
			var beat := sin(t * TAU)
			p.hop = absf(beat) * 0.25
			p.l_leg = 0.5 * maxf(beat, 0.0)
			p.r_leg = 0.5 * maxf(-beat, 0.0)
			var paws := Vector2(1.2 + 0.2 * sin(t * 2.0 * TAU), 0.5)
			p.l_arm = paws
			p.r_arm = paws
			p.spin = 0.25 * sin(t * PI)
		&"dance_robot":   # Robot: stiff moves in steps, turning left and right
			_robot(p, t)
		&"dance_star":   # Star Spin: arms out like a star, spinning and bobbing
			p.spin = wrapf(t * TAU / STAR_TURN, -PI, PI)
			var sway := 0.3 + 0.3 * sin(t * TAU * 1.33)
			p.l_arm = Vector2(sway, 1.35)
			p.r_arm = Vector2(sway, 1.35)
			p.l_leg = 0.25 * sin(t * TAU * 1.33)
			p.r_leg = -0.25 * sin(t * TAU * 1.33)
			p.hop = absf(sin(t * TAU / 0.75)) * 0.12
		&"think":   # a hand to the chin, the head on one side, the other arm across the tummy
			p.r_arm = Vector2(2.3, -0.6)
			p.l_arm = Vector2(0.8, -0.6)
			p.head = Vector3(0.12, 0.1, 0.22 + 0.05 * sin(t * 2.5))
			p.lean = 0.04
		&"yawn":   # the arms stretch up wide as the head tips back, then a sleepy sway
			var up := smoothstep(0.0, 0.8, t)
			p.l_arm = Vector2(2.7 * up, 0.6 * up)
			p.r_arm = Vector2(2.7 * up, 0.6 * up)
			p.head = Vector3(0.38 * up, 0.0, 0.1 * sin(t * 2.2))
			p.lean = 0.12 * up
		&"stretch":   # arms up high on tiptoe, then out to the sides
			var k := smoothstep(0.9, 1.4, t)
			var arm := Vector2(lerpf(3.0, 0.25, k), lerpf(0.15, 1.45, k))
			p.l_arm = arm
			p.r_arm = arm
			p.hop = 0.05 * (1.0 - k)
			p.lean = 0.1 * (1.0 - k)
			p.head = Vector3(0.2 * (1.0 - k), 0.0, 0.0)
		&"look":   # a glance round: the head turns one way, then the other, then ahead
			var s := sin(TAU * clampf(t / duration(emote), 0.0, 1.0))
			p.head = Vector3(0.05, 0.75 * s, 0.0)
			p.spin = 0.12 * s
		&"hooray":   # a happy little jump and a whole spin, arms up
			var k := clampf(t / 0.8, 0.0, 1.0)
			var jump := sin(k * PI)
			p.hop = 0.45 * jump
			p.spin = TAU * smoothstep(0.0, 1.0, k)
			p.l_arm = Vector2(2.8 * jump, 0.5)
			p.r_arm = Vector2(2.8 * jump, 0.5)
			p.l_leg = 0.3 * jump
			p.r_leg = -0.2 * jump
			p.head = Vector3(0.2 * jump, 0.0, 0.0)
		&"victory":   # fist pumps and hops (Player.celebrate after a won wave or boss)
			var pump := 0.5 + 0.5 * sin(t * TAU * 1.5)
			p.r_arm = Vector2(lerpf(1.0, 2.95, pump), 0.3)
			p.l_arm = Vector2(lerpf(2.95, 1.0, pump), 0.3)
			p.hop = absf(sin(t * TAU * 1.5)) * 0.3
			p.spin = sin(t * PI) * 0.5
	return p


## The Robot's moves: each step snaps (quickly, not instantly) from the previous pose to the next.
static func _robot(p: Dictionary, t: float) -> void:
	const ARMS := [Vector2(1.57, 0.0), Vector2(0.3, 0.0)]
	const TURNS := [0.0, 0.4, 0.0, -0.4]
	var step := int(floor(t / ROBOT_STEP))
	var k := smoothstep(0.0, 0.25, fmod(t, ROBOT_STEP) / ROBOT_STEP)
	var even := step % 2 == 0
	var r_to: Vector2 = ARMS[0] if even else ARMS[1]
	var l_to: Vector2 = ARMS[1] if even else ARMS[0]
	p.r_arm = (l_to as Vector2).lerp(r_to, k)
	p.l_arm = (r_to as Vector2).lerp(l_to, k)
	p.spin = lerpf(TURNS[posmod(step - 1, 4)], TURNS[step % 4], k)
