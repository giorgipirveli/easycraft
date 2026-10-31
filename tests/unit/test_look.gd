extends GutTest
## The look (the visuals brief, 2026-10-01; docs/devlog/parts/visuals.md): the sky under the horizon, the golden light
## of a low sun and the photo sky's colour at dusk and at night, as rules (the colours on OpenGL: test_look_colours.gd).


# --- The sky under the horizon -------------------------------------------------------------------------------------

## Beyond the streamed land (and under the horizon, seen from a hill) the sky shows its lower half: it is the fog's own
## colour, so the fogged far hills melt into it instead of standing as a pale wall over a dark blue band; and the fog is
## the sky's horizon colour, so no line runs along the horizon.
func test_the_sky_under_the_horizon_is_the_fog_s_colour_all_day() -> void:
	for i in 96:
		var look := DayCycle.look(i / 96.0)
		assert_true((look.ground_horizon as Color).is_equal_approx(look.fog_color), "ground horizon at %d" % i)
		assert_true((look.ground_bottom as Color).is_equal_approx(look.fog_color), "ground bottom at %d" % i)
		assert_true((look.sky_horizon as Color).is_equal_approx(look.fog_color), "the horizon at %d" % i)


## A world's own sky (Mars's butterscotch): its horizon colour stays as it was painted; the haze and the sky under the
## horizon take it.
func test_a_world_s_own_sky_meets_its_fog_too() -> void:
	var look := DayCycle.look(DayCycle.NOON)
	look.ground_bottom = Color.RED
	look.ground_horizon = Color.GREEN
	look.sky_horizon = Color(0.9, 0.7, 0.5)
	look.fog_color = Color(0.5, 0.5, 0.5)
	var met := DayCycle.sky_meets_fog(look)
	for key: String in ["ground_bottom", "ground_horizon", "fog_color", "sky_horizon"]:
		assert_true((met[key] as Color).is_equal_approx(Color(0.9, 0.7, 0.5)), key)


# --- The light ------------------------------------------------------------------------------------------------------

func _warmth(c: Color) -> float:
	return c.r - c.b


## Morning and evening: a low sun is golden (its light and its long shadows); by noon it is white again.
func test_a_low_sun_is_golden_and_a_high_sun_is_white() -> void:
	var morning := DayCycle.look(0.2)
	var evening := DayCycle.look(0.8)
	var noon := DayCycle.look(DayCycle.NOON)
	assert_false(morning.moon_up)
	assert_gt(_warmth(morning.light_color), 0.3, "the morning sun")
	assert_gt(_warmth(evening.light_color), 0.3, "the evening sun")
	assert_true((noon.light_color as Color).is_equal_approx(DayCycle.DAY_LIGHT), "noon stays the world scene's light")
	assert_lt(_warmth(DayCycle.look(0.4).light_color), 0.15, "late morning: nearly white")


func test_the_light_s_colour_changes_smoothly() -> void:
	var prev: Color = DayCycle.look(0.0).light_color
	for i in range(1, 1201):
		var look := DayCycle.look(i / 1200.0)
		var c: Color = look.light_color
		if look.moon_up == DayCycle.look((i - 1) / 1200.0).moon_up:   # the sun becomes the moon under the horizon
			assert_lt(maxf(maxf(absf(c.r - prev.r), absf(c.g - prev.g)), absf(c.b - prev.b)), 0.03, "step %d" % i)
		prev = c


# --- The photo sky (REALISTIC) at dusk and at night -----------------------------------------------------------------

## The photo sky is a picture of a clear day: at dusk and at night the fog's colour (orange, then the night's blue)
## washes over it (Environment.fog_sky_affect), so it is never a dim noon or a black hole.
func test_the_photo_sky_takes_the_fog_s_colour_at_dusk_and_at_night() -> void:
	assert_eq(DayCycle.look(DayCycle.NOON).photo_fog, 0.0, "a clear day")
	assert_gt(DayCycle.look(DayCycle.SUNSET).photo_fog, 0.3, "sunset")
	assert_gt(DayCycle.look(DayCycle.SUNRISE).photo_fog, 0.3, "sunrise")
	var night: float = DayCycle.look(DayCycle.MIDNIGHT).photo_fog
	assert_between(night, 0.5, 0.8, "the night's blue, the clouds still there")


func test_the_photo_sky_s_fog_changes_smoothly() -> void:
	var prev: float = DayCycle.look(0.0).photo_fog
	for i in range(1, 1201):
		var f: float = DayCycle.look(i / 1200.0).photo_fog
		assert_lt(absf(f - prev), 0.03, "step %d" % i)
		prev = f


# --- A world's own sunlight ----------------------------------------------------------------------------------------

## Mars gets under half of Earth's sunlight and Venus's cloud city sits under a glaring deck: their noon light is a
## share of home's (a descriptor's `sun_light`), so their painted ground keeps its colour (Mars's red dust came out a
## pale orange-yellow in Earth's full sun); every other world has home's.
func test_a_world_s_own_sunlight() -> void:
	assert_eq(UniverseRegistry.sun_light(1), 1.0, "home")
	assert_eq(UniverseRegistry.sun_light(SpaceRules.MOON), 1.0, "a world without the field")
	assert_between(UniverseRegistry.sun_light(SpaceRules.MARS), 0.6, 0.8, "Mars")
	assert_between(UniverseRegistry.sun_light(SpaceRules.VENUS), 0.7, 0.9, "Venus's cloud deck")
	assert_eq(UniverseRegistry.sun_light(9999), 1.0, "no such world")
