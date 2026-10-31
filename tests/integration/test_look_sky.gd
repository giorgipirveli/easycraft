extends GutTest
## The look on a real world (the visuals brief, 2026-10-01; docs/devlog/parts/visuals.md): SkyCycle puts the fog's
## colour under the horizon (Earth's sky and every world's own), the photo sky takes the fog's colour at dusk and at
## night (the blocky sky never), and the far hills are hazy (the fog starts well before the end of the view).

var world: WorldService
var sky: SkyCycle


func before_each() -> void:
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	world.apply_graphics({"graphics": "medium", "view_distance": 128})
	sky = SkyCycle.new()
	sky.world = world
	add_child_autofree(sky)


func after_each() -> void:
	BlockLibrary.set_style("blocky")


func _blocky_sky() -> ProceduralSkyMaterial:
	return world.environment().sky.sky_material as ProceduralSkyMaterial


func _meets_fog(what: String) -> void:
	var s := _blocky_sky()
	var fog := world.ambience_base.fog_color as Color
	assert_true(s.ground_horizon_color.is_equal_approx(fog), "%s: the ground's horizon is the fog" % what)
	assert_true(s.ground_bottom_color.is_equal_approx(fog), "%s: under it too" % what)
	assert_true(s.sky_horizon_color.is_equal_approx(fog), "%s: no line along the horizon" % what)


func test_the_sky_under_the_horizon_is_the_fog_at_every_hour() -> void:
	for t: float in [DayCycle.MIDNIGHT, DayCycle.SUNRISE, 0.3, DayCycle.NOON, 0.8, DayCycle.SUNSET, 0.95]:
		sky.set_time(t)
		_meets_fog("t=%.2f" % t)


func test_every_world_s_own_sky_meets_its_fog() -> void:
	for u in [2, 3, 4, 5, SpaceRules.MARS, SpaceRules.VENUS, SpaceRules.MOON, SpaceRules.RINGS]:
		sky.palette = UniverseRegistry.sky(u)
		sky.space = UniverseRegistry.space_sky(u)
		for t: float in [DayCycle.NOON, DayCycle.SUNSET, DayCycle.MIDNIGHT]:
			sky.set_time(t)
			_meets_fog("world %d t=%.2f" % [u, t])


func test_climbing_to_space_keeps_the_horizon_met() -> void:
	sky.set_time(DayCycle.NOON)
	sky.set_space_climb(0.5)
	_meets_fog("half way to space")


func test_the_photo_sky_takes_the_night_s_blue_and_the_blocky_sky_never() -> void:
	var env := world.environment()
	sky.set_time(DayCycle.MIDNIGHT)
	assert_eq(env.fog_sky_affect, 0.0, "the blocky sky is painted in the night's colours already")
	world.apply_style("realistic")
	sky.refresh()
	assert_almost_eq(env.fog_sky_affect, float(DayCycle.look(DayCycle.MIDNIGHT).photo_fog), 0.001, "night")
	sky.set_time(DayCycle.SUNSET)
	assert_gt(env.fog_sky_affect, 0.3, "sunset")
	sky.set_time(DayCycle.NOON)
	assert_eq(env.fog_sky_affect, 0.0, "a clear day")
	sky.set_time(DayCycle.MIDNIGHT)
	world.apply_style("blocky")
	sky._process(0.0)
	assert_eq(env.fog_sky_affect, 0.0, "back to blocky")


func test_the_far_hills_are_hazy() -> void:
	var env := world.environment()
	assert_almost_eq(env.fog_depth_end, 128.0, 0.001, "the fog ends at the view's end (the chunk edge hides in it)")
	assert_almost_eq(env.fog_depth_begin, 128.0 * WorldService.FOG_BEGIN, 0.001)
	assert_lt(WorldService.FOG_BEGIN, 0.5, "the haze starts before half the view")
	assert_almost_eq(world.ambience_base.fog_begin as float, env.fog_depth_begin, 0.001)
	world.apply_graphics({"graphics": "low", "view_distance": 128})
	assert_almost_eq(env.fog_depth_end, 64.0, 0.001, "LOW sees 64 blocks")
	assert_almost_eq(env.fog_depth_begin, 64.0 * WorldService.FOG_BEGIN, 0.001)


## The painted colours at noon: ACES at a lower exposure (the colours decoded once came out about twice as bright), and
## the moon's light raised with it, so the night stays moonlit (as bright as before the exposure came down, 0.4 x 1.0).
func test_the_exposure_keeps_the_painted_colours_and_the_moonlit_night() -> void:
	var env := world.environment()
	assert_eq(env.tonemap_mode, Environment.TONE_MAPPER_ACES)
	assert_between(env.tonemap_exposure, 0.6, 0.9)
	sky.set_time(DayCycle.MIDNIGHT)
	assert_gte(world.ambience_base.sun * env.tonemap_exposure, 0.4, "the moon's light as it reaches the eye")


## A world's own sunlight (UniverseRegistry.sun_light) dims its day's light only: the moon's stays home's.
func test_a_world_s_sunlight_dims_its_day_not_its_moon() -> void:
	sky.set_time(DayCycle.NOON)
	var home: float = world.ambience_base.sun
	sky.sun_light = 0.7
	sky.set_time(DayCycle.NOON)
	assert_almost_eq(float(world.ambience_base.sun), home * 0.7, 0.001, "Mars's noon")
	sky.set_time(DayCycle.MIDNIGHT)
	var moon: float = world.ambience_base.sun
	sky.sun_light = 1.0
	sky.set_time(DayCycle.MIDNIGHT)
	assert_almost_eq(float(world.ambience_base.sun), moon, 0.001, "the moon's light is the same")
