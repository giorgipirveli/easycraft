class_name AmbienceRules
extends RefCounted
## Cave mood and the underwater view, as pure rules. "Underground" means deeper than START_DEPTH
## below the generated ground AND under a ceiling (an open pit stays bright; a roof or a tree on the
## surface does not darken anything). Caves get dark with a warm lantern around the player, but
## never pitch black. Underwater is blue, foggy and tinted.

const START_DEPTH := 3.0          # blocks below the ground before it starts to get dark
const RAMP := 8.0                 # blocks over which it gets fully dark
const RATE := 1.5                 # factor change per second (smooth transitions)
const CAVE_SUN := 0.08
const CAVE_AMBIENT := 0.18        # of the base ambient energy: dark, never black
const CAVE_FOG := Color(0.03, 0.03, 0.05)
const CAVE_FOG_BEGIN := 18.0
const CAVE_FOG_END := 56.0
const LANTERN := 1.3
const WATER_FOG := Color(0.08, 0.32, 0.55)
const WATER_FOG_BEGIN := 1.0
const WATER_FOG_END := 22.0
const WATER_TINT := Color(0.1, 0.35, 0.75, 0.28)


## Sounds are muffled once the view is mostly under water (M2 Task 14).
static func muffled(underwater: float) -> bool:
	return underwater >= 0.5


static func underwater_target(camera_block: int) -> float:
	return 1.0 if camera_block == BlockIds.WATER else 0.0


## head_y: the player's head height; surface: the generated ground height at the player's column;
## has_ceiling: a solid block somewhere above the head.
static func underground_target(head_y: float, surface: int, has_ceiling: bool) -> float:
	if not has_ceiling:
		return 0.0
	return clampf((surface - head_y - START_DEPTH) / RAMP, 0.0, 1.0)


static func approach(current: float, target: float, delta: float) -> float:
	return move_toward(current, target, RATE * delta)


## base: {"sun", "ambient", "fog_color", "fog_begin", "fog_end"} for open air.
## Returns the same keys plus "lantern" (light energy) and "tint" (screen overlay colour).
static func mood(underground: float, underwater: float, base: Dictionary) -> Dictionary:
	var u := clampf(underground, 0.0, 1.0)
	var w := clampf(underwater, 0.0, 1.0)
	var sun := lerpf(base.sun, base.sun * CAVE_SUN, u)
	var ambient := lerpf(base.ambient, base.ambient * CAVE_AMBIENT, u)
	var fog_color: Color = (base.fog_color as Color).lerp(CAVE_FOG, u)
	var fog_begin := lerpf(base.fog_begin, minf(base.fog_begin, CAVE_FOG_BEGIN), u)
	var fog_end := lerpf(base.fog_end, minf(base.fog_end, CAVE_FOG_END), u)
	return {
		"sun": sun * lerpf(1.0, 0.7, w),
		"ambient": ambient,
		"fog_color": fog_color.lerp(WATER_FOG, w),
		"fog_begin": lerpf(fog_begin, WATER_FOG_BEGIN, w),
		"fog_end": lerpf(fog_end, WATER_FOG_END, w),
		"lantern": LANTERN * u,
		"tint": Color(WATER_TINT, WATER_TINT.a * w),
	}
