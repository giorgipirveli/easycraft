class_name GlowRules
extends RefCounted
## Universe 6, the Glow Caves' light as pure rules (spec §5.1, §3c: calm, never scary; the brief: "never truly dark:
## the darkness is soft blue-violet, and the glow always shows the way"). The caves' glow is their blocks' own (the
## page's unshaded material): no real light per mushroom. Under the caves' roof (a ceiling over the head, at any depth:
## the cavern floor is the ground there, so AmbienceRules' depth rule would never see a cave) the mood is CAVE_MOOD:
## a blue-violet ambient light of its own colour (little of the sky's), blue-violet fog in which far halls fade softly,
## no sunlight, a cool lantern round the child; the same by day and by night. Under a daylight shaft the day comes back.
## A universe asks for it with its descriptor's `cave_mood` (UniverseRegistry.cave_mood); Ambience applies it.

## The caves' mood under a ceiling: absolute values (the outside's day and night never reach in).
const CAVE_MOOD := {
	"fog": Color(0.31, 0.27, 0.56),         # soft blue-violet
	"fog_begin": 14.0,
	"fog_end": 64.0,
	"ambient": 0.42,                         # the ambient light's energy: readable on a phone and in a headset
	"ambient_color": Color(0.58, 0.55, 1.0), # blue-violet
	"sky_share": 0.1,                        # ambient_light_sky_contribution: little of the sky's colour down here
	"sun": 0.05,                             # of the base sun (shadows off on phones: the roof would not stop it)
	"lantern": 1.0,                          # the child's lantern (Ambience's one light)
	"lantern_color": Color(0.78, 0.9, 1.0),  # cool glow-light, not fire
}


## `m` (AmbienceRules.mood of `base`) turned to the caves' mood by how far underground (0..1) the head is; the water's
## own view still wins under water. Adds "ambient_color", "sky_share" and "lantern_color" (Ambience writes them).
static func mood(m: Dictionary, base: Dictionary, underground: float, underwater: float, cave: Dictionary) -> Dictionary:
	var u := clampf(underground, 0.0, 1.0)
	var w := clampf(underwater, 0.0, 1.0)
	var out := m.duplicate()
	var fog: Color = (base.fog_color as Color).lerp(cave.fog, u)
	out.fog_color = fog.lerp(AmbienceRules.WATER_FOG, w)
	out.fog_begin = lerpf(lerpf(base.fog_begin, cave.fog_begin, u), AmbienceRules.WATER_FOG_BEGIN, w)
	out.fog_end = lerpf(lerpf(base.fog_end, cave.fog_end, u), AmbienceRules.WATER_FOG_END, w)
	out.ambient = lerpf(base.ambient, cave.ambient, u)
	out.sun = lerpf(base.sun, base.sun * float(cave.sun), u) * lerpf(1.0, 0.7, w)
	out.lantern = float(cave.lantern) * u
	out.lantern_color = cave.lantern_color
	out.ambient_color = (base.get("ambient_color", Color.WHITE) as Color).lerp(cave.ambient_color, u)
	out.sky_share = lerpf(float(base.get("sky_share", 0.6)), cave.sky_share, u)
	return out
