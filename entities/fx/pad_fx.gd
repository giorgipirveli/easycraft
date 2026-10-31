class_name PadFx
extends RefCounted
## What a pad firing looks and sounds like (M3 Task 6), in every game: a jump pad's boing and a green
## puff bursting up, a speed pad's whoosh and a yellow spray of dust. One small burst each with the
## shared particle material (Fx). time_scale: the body's own time, so a slow-motion player's puff
## is slow too.

const JUMP_COLOR := Color(0.55, 1.0, 0.45)
const SPEED_COLOR := Color(1.0, 0.86, 0.3)
const BOUNCE_COLOR := Color(1.0, 0.45, 0.55)
const LAUNCH_COLOR := Color(1.0, 0.55, 0.11)   # M3 Task 14a
const PLUME_COLOR := Color(0.9, 0.96, 1.0)     # cosmos: Europa's water plume (white vapour)
const SULPHUR_COLOR := Color(1.0, 0.9, 0.45)   # cosmos: an Io volcano's plume (sulphur)
const LAVA_COLOR := Color(1.0, 0.55, 0.15)     # cosmos: Io's hot lava (warm sparks)
const DUST_COLOR := Color(0.36, 0.34, 0.38)    # cosmos: a Triton geyser's dark dust ...
const FROST_COLOR := Color(0.95, 0.93, 0.97)   # ... and its nitrogen frost


static func play(parent: Node, feet: Vector3, pad: int, time_scale: float = 1.0) -> void:
	var p: CPUParticles3D
	match pad:
		BlockIds.JUMP_PAD:
			Audio.play(&"boing", feet)
			p = Fx.burst(parent, feet + Vector3(0, 0.1, 0), JUMP_COLOR, 18, 4.5, 0.14, 0.55, 6.0, 70.0)
		BlockIds.BOUNCE:   # M3 Task 7: the trampoline
			Audio.play(&"boing", feet, 2.0)
			p = Fx.burst(parent, feet + Vector3(0, 0.1, 0), BOUNCE_COLOR, 22, 5.5, 0.14, 0.6, 6.0, 70.0)
		BlockIds.LAUNCH_PAD:   # M3 Task 14a: up, up and away
			Audio.play(&"boing", feet, 4.0)
			Audio.play(&"whoosh", feet)
			p = Fx.burst(parent, feet + Vector3(0, 0.1, 0), LAUNCH_COLOR, 26, 7.0, 0.16, 0.7, 6.0, 40.0)
		BlockIds.GEYSER_VENT:   # cosmos: a water plume throws the child up
			Audio.play(&"whoosh", feet, 2.0)
			p = Fx.burst(parent, feet + Vector3(0, 0.2, 0), PLUME_COLOR, 30, 9.0, 0.22, 1.2, 1.5, 12.0)
		BlockIds.VOLCANO_VENT:   # cosmos: an Io volcano's plume throws the child up
			Audio.play(&"whoosh", feet, 2.0)
			p = Fx.burst(parent, feet + Vector3(0, 0.2, 0), SULPHUR_COLOR, 30, 9.0, 0.22, 1.2, 1.5, 12.0)
		BlockIds.NITROGEN_GEYSER:   # cosmos: a Triton geyser puffs the child up: dark dust and frost, drifting north-east
			Audio.play(&"whoosh", feet, 0.0, 0.8)
			var frost := Fx.burst(parent, feet + Vector3(0, 0.2, 0), FROST_COLOR, 14, 6.0, 0.2, 1.6, 0.8, 14.0)
			frost.gravity += PadRules.WIND * 2.0
			frost.speed_scale = time_scale
			p = Fx.burst(parent, feet + Vector3(0, 0.2, 0), DUST_COLOR, 22, 7.0, 0.24, 1.6, 0.8, 14.0)
			p.gravity += PadRules.WIND * 2.0
		BlockIds.HOT_LAVA:   # cosmos: Io's hot lava bounces the child out, with warm sparks
			Audio.play(&"boing", feet, -2.0, 0.8)
			p = Fx.burst(parent, feet + Vector3(0, 0.1, 0), LAVA_COLOR, 16, 4.0, 0.14, 0.6, 2.0, 30.0)
		BlockIds.SPEED_PAD:
			Audio.play(&"whoosh", feet)
			p = Fx.burst(parent, feet + Vector3(0, 0.15, 0), SPEED_COLOR, 14, 3.0, 0.1, 0.45, 2.0, 90.0)
		_:
			return
	p.speed_scale = time_scale
