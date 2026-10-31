class_name DayCycle
extends RefCounted
## The gentle day/night cycle, as pure rules. The time of day t runs 0..1 like a clock face
## (t × 24 = hours): midnight is 0, noon 0.5. A whole cycle lasts 20 minutes: 12 minutes of day,
## 2 of dusk, 4 of night and 2 of dawn. The sun rises in the middle of dawn and sets in the middle
## of dusk; the moon is opposite the sun. Nights are moonlit and never pitch black (it is a game for
## children). look() is everything SkyCycle shows at a time of day.

enum Phase { DAY, DUSK, NIGHT, DAWN }

const LENGTH := 1200.0            # seconds per cycle (20 minutes)
const MIDNIGHT := 0.0
const DAWN_START := 0.1
const SUNRISE := 0.15             # the sun on the horizon
const DAY_START := 0.2
const START := 0.3                # a new world starts in the morning
const NOON := 0.5
const DUSK_START := 0.8
const SUNSET := 0.85
const NIGHT_START := 0.9
const TILT := 0.5236              # the sun's path leans 30° towards +Z, so noon shadows are not straight down
const HORIZON_FADE := 0.25        # sun or moon height (sine) at which its light is full

const SUN := 1.0                  # light energies, as a share of the day sun
const MOON := 0.55                 # the visuals brief: brighter moonlight under the lower exposure (was 0.4)
const NIGHT_AMBIENT := 0.8        # ambient energy at night, as a share of the day's: moonlit, never black
const NIGHT_SKY_ENERGY := 0.12    # the realistic (HDRI) sky at night
const SUN_GLOW := 20.0            # degrees of glow around the sun in the blocky sky
const MOON_GLOW := 6.0
const TWILIGHT_STRENGTH := 0.85
## The visuals brief (docs/devlog/parts/visuals.md): a low sun is golden. Under GOLDEN_HEIGHT (the sun's height, a
## sine) its light turns toward GOLDEN_LIGHT, fully on the horizon; above it, the day's white light.
const GOLDEN_HEIGHT := 0.5
const GOLDEN_LIGHT := Color(1.0, 0.8, 0.56)
## The photo sky (REALISTIC) is a clear day's picture: at night the fog's colour (the night's blue) washes this much
## over it, at sunrise and sunset (the orange fog) this much (Environment.fog_sky_affect, SkyCycle); never by day.
const NIGHT_PHOTO_FOG := 0.65
const DUSK_PHOTO_FOG := 0.45

## Day colours are world/world.tscn's (tested).
const DAY_SKY_TOP := Color(0.25, 0.55, 0.95)
const DAY_SKY_HORIZON := Color(0.6, 0.78, 0.98)
const DAY_FOG := DAY_SKY_HORIZON   # the haze is the horizon (sky_meets_fog)
const DAY_LIGHT := Color(1.0, 0.97, 0.9)
const DAY_AMBIENT := Color(0.9, 0.95, 1.0)
const TWILIGHT_SKY_TOP := Color(0.32, 0.36, 0.66)
const TWILIGHT_SKY_HORIZON := Color(1.0, 0.62, 0.4)
const TWILIGHT_LIGHT := Color(1.0, 0.62, 0.38)
const NIGHT_SKY_TOP := Color(0.03, 0.05, 0.16)
const NIGHT_SKY_HORIZON := Color(0.12, 0.17, 0.34)
const MOON_LIGHT := Color(0.62, 0.72, 1.0)
const NIGHT_AMBIENT_COLOR := Color(0.55, 0.65, 1.0)


static func wrap_time(t: float) -> float:
	return fposmod(t, 1.0)


## The time of day after `seconds` of play.
static func advance(t: float, seconds: float) -> float:
	return wrap_time(t + seconds / LENGTH)


static func phase(t: float) -> Phase:
	var u := wrap_time(t)
	if u >= DAY_START and u < DUSK_START:
		return Phase.DAY
	if u >= DUSK_START and u < NIGHT_START:
		return Phase.DUSK
	if u >= DAWN_START and u < DAY_START:
		return Phase.DAWN
	return Phase.NIGHT


## The sun is below the horizon.
static func is_night(t: float) -> bool:
	var u := wrap_time(t)
	return u >= SUNSET or u < SUNRISE


## When a sleeper wakes up: the next sunrise at night (or once it is getting dark at dusk), else
## the next sunset.
static func wake_time(t: float) -> float:
	var u := wrap_time(t)
	return SUNRISE if u >= DUSK_START or u < SUNRISE else SUNSET


## The sun's angle along its path: 0 rising in the east, PI/2 at noon, PI setting in the west, and
## on round under the ground at night (faster, because the night is shorter than the day).
static func sun_angle(t: float) -> float:
	var u := wrap_time(t)
	var day_span := SUNSET - SUNRISE
	if u >= SUNRISE and u < SUNSET:
		return PI * (u - SUNRISE) / day_span
	return PI + PI * fposmod(u - SUNSET, 1.0) / (1.0 - day_span)


## Unit vector pointing at the sun. It rises at +X and sets at -X.
static func sun_direction(t: float) -> Vector3:
	var a := sun_angle(t)
	return Vector3(cos(a), sin(a) * cos(TILT), sin(a) * sin(TILT))


static func moon_direction(t: float) -> Vector3:
	return -sun_direction(t)


## 1 by day, 0 at night, easing through dawn and dusk.
static func daylight(t: float) -> float:
	var u := wrap_time(t)
	match phase(u):
		Phase.DAY:
			return 1.0
		Phase.DUSK:
			return 1.0 - smoothstep(DUSK_START, NIGHT_START, u)
		Phase.DAWN:
			return smoothstep(DAWN_START, DAY_START, u)
	return 0.0


## 0..1: the orange glow of sunrise and sunset, strongest when the sun is on the horizon.
static func twilight(t: float) -> float:
	var u := wrap_time(t)
	match phase(u):
		Phase.DUSK:
			return sin(PI * (u - DUSK_START) / (NIGHT_START - DUSK_START))
		Phase.DAWN:
			return sin(PI * (u - DAWN_START) / (DAY_START - DAWN_START))
	return 0.0


## Cosmos (spec §21b.2): a look `look` in a world that spins backwards (Venus): the Sun rises in the west (-X) and sets
## in the east, the Moon's path turned the same way; everything else as it was.
static func backwards(look: Dictionary) -> Dictionary:
	for key: String in ["light_dir", "moon_dir"]:
		if look.get(key) is Vector3:
			var d: Vector3 = look[key]
			look[key] = Vector3(-d.x, d.y, d.z)
	return look


## How golden a sun `height` (a sine, 0 on the horizon) above the horizon shines: 1 on it, 0 from GOLDEN_HEIGHT up.
static func golden(height: float) -> float:
	return 1.0 - smoothstep(0.0, GOLDEN_HEIGHT, height)


## The haze and the sky under the horizon (the blocky sky's ground_horizon and ground_bottom) take the sky's horizon
## colour: the fogged far land melts into the sky with no line along the horizon (the visuals brief: before, the pale
## fogged hills stood over a dark blue band there, and a world whose haze differed from its horizon had a seam).
static func sky_meets_fog(look: Dictionary) -> Dictionary:
	if look.get("sky_horizon") is Color:
		look.fog_color = look.sky_horizon
		look.ground_horizon = look.sky_horizon
		look.ground_bottom = look.sky_horizon
	return look


## Everything the sky shows at time t:
## - light_dir (towards the light), light_energy (share of the day sun), light_color, moon_up: the
##   one directional light is the sun by day and the moon by night.
## - ambient (share of the day's ambient energy), ambient_color.
## - sky_top, sky_horizon, ground_bottom, ground_horizon (blocky sky), fog_color (the haze; the ground's and the fog are
##   the horizon's, sky_meets_fog), sun_glow (degrees).
## - sky_energy (the realistic HDRI sky) and photo_fog (how much of the fog's colour washes over it), stars and moon
##   (0..1 visibility), moon_dir.
static func look(t: float) -> Dictionary:
	var day := daylight(t)
	var glow := twilight(t) * TWILIGHT_STRENGTH
	var sun := sun_direction(t)
	var moon_up := sun.y < 0.0
	var light_dir := -sun if moon_up else sun
	var rise := smoothstep(0.0, HORIZON_FADE, light_dir.y)
	var horizon := NIGHT_SKY_HORIZON.lerp(DAY_SKY_HORIZON, day).lerp(TWILIGHT_SKY_HORIZON, glow)
	var sunlight := DAY_LIGHT.lerp(GOLDEN_LIGHT, golden(sun.y)).lerp(TWILIGHT_LIGHT, twilight(t))
	return {
		"light_dir": light_dir,
		"light_energy": (MOON if moon_up else SUN) * rise,
		"light_color": MOON_LIGHT if moon_up else sunlight,
		"moon_up": moon_up,
		"ambient": lerpf(NIGHT_AMBIENT, 1.0, day),
		"ambient_color": NIGHT_AMBIENT_COLOR.lerp(DAY_AMBIENT, day),
		"sky_top": NIGHT_SKY_TOP.lerp(DAY_SKY_TOP, day).lerp(TWILIGHT_SKY_TOP, glow),
		"sky_horizon": horizon,
		"ground_bottom": horizon,   # the far land melts into the sky (sky_meets_fog)
		"ground_horizon": horizon,
		"fog_color": horizon,
		"sun_glow": MOON_GLOW if moon_up else SUN_GLOW,
		"sky_energy": lerpf(NIGHT_SKY_ENERGY, 1.0, day),
		"photo_fog": maxf(NIGHT_PHOTO_FOG * (1.0 - day), DUSK_PHOTO_FOG * twilight(t)),
		"stars": (1.0 - day) * (1.0 - day),
		"moon": (1.0 - day) * smoothstep(-0.05, 0.05, -sun.y),
		"moon_dir": -sun,
	}
