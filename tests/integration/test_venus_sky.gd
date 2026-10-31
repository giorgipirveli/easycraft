extends GutTest
## Cosmos: Venus's sky on a real world's SkyCycle (spec §21b.2). Thick air: a hazy golden sky of its own (never space's
## black, never Earth's photo sky, in both styles), the Sun a little bigger than at home and rising in the west (Venus
## spins backwards: SkyCycle.sun_west turns its path, DayCycle.backwards); Earth and our Moon as tiny points; no moon of
## its own, so the big round moon disc of home never shows.

var world: WorldService
var sky: SkyCycle


func before_each() -> void:
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	sky = SkyCycle.new()
	sky.world = world
	add_child_autofree(sky)
	sky.time = DayCycle.NOON
	sky.refresh()


func after_each() -> void:
	UniverseRegistry.reset()


func _material() -> ProceduralSkyMaterial:
	return world.environment().sky.sky_material as ProceduralSkyMaterial


func _venus_sky() -> void:
	sky.palette = UniverseRegistry.sky(SpaceRules.VENUS)
	sky.space = UniverseRegistry.space_sky(SpaceRules.VENUS)
	sky.sun_size = UniverseRegistry.sun_size(SpaceRules.VENUS)
	sky.sun_west = UniverseRegistry.sun_rises_west(SpaceRules.VENUS)
	sky.show_planet(UniverseRegistry.sky_planet(SpaceRules.VENUS))
	sky.refresh()


## Toward the light (the sun by day) at time t.
func _toward(t: float) -> Vector3:
	sky.time = t
	sky.refresh()
	return world.sun().global_transform.basis.z.normalized()   # the light shines along its -z, away from the sun


func test_at_home_the_sun_rises_in_the_east() -> void:
	assert_false(sky.sun_west)
	assert_gt(_toward(DayCycle.SUNRISE + 0.03).x, 0.3, "morning: the Sun in the east (+x)")
	assert_lt(_toward(DayCycle.SUNSET - 0.03).x, -0.3, "evening: in the west")


func test_on_venus_the_sun_rises_in_the_west_and_sets_in_the_east() -> void:
	_venus_sky()
	var morning := _toward(DayCycle.SUNRISE + 0.03)
	assert_lt(morning.x, -0.3, "morning: the Sun in the west (%s)" % morning)
	assert_gt(morning.y, 0.0, "up over the horizon")
	assert_gt(_toward(DayCycle.SUNSET - 0.03).x, 0.3, "evening: in the east")
	var noon := _toward(DayCycle.NOON)
	assert_gt(noon.y, 0.8, "high at noon, as ever")
	assert_gt(noon.z, 0.0, "leaning south at noon, as ever")


func test_a_hazy_golden_sky_and_a_bigger_sun() -> void:
	_venus_sky()
	var top := _material().sky_top_color
	assert_gt(top.get_luminance(), 0.5, "a bright sky, never space's black (%s)" % top)
	assert_gt(top.r, top.b + 0.2, "golden (%s)" % top)
	assert_false(sky.get_node("NightSky/Stars").visible, "no stars by day")
	assert_almost_eq(_material().sun_angle_max, DayCycle.SUN_GLOW * 1.4, 0.001, "the Sun a little bigger")
	assert_gt(world.ambience_base.sun, 0.5, "bright")


func test_earth_and_our_moon_tiny_and_no_moon_disc_at_night() -> void:
	_venus_sky()
	assert_not_null(sky.planet(), "Earth")
	assert_lt((sky.planet().mesh as QuadMesh).size.x, 8.0, "a tiny bright point")
	assert_eq(sky.moons().filter(func(m: MeshInstance3D) -> bool: return m.visible).size(), 1, "and our Moon")
	sky.time = 0.0
	sky.refresh()
	assert_false(sky.get_node("NightSky/Moon").visible, "Venus has no moon: home's big moon never shows")


func test_the_realistic_style_keeps_venus_sky() -> void:
	world.photo_sky = UniverseRegistry.photo_sky(SpaceRules.VENUS)
	world.apply_style("realistic")
	_venus_sky()
	assert_true(world.environment().sky.sky_material is ProceduralSkyMaterial, "its own painted sky, never Earth's photo")
	assert_lt(_toward(DayCycle.SUNRISE + 0.03).x, -0.3, "and its Sun still rises in the west")
	world.apply_style("blocky")


## The painted sky draws the Sun's disc in its light's colour × energy: low over the horizon (Venus's sets in the east,
## where a child looks) it would be a dark blot on the bright twilight sky, so it stays out of the sky until its light is
## full, in every world.
func test_no_dark_sun_disc_low_over_the_horizon() -> void:
	sky.time = DayCycle.NOON
	sky.refresh()
	assert_eq(world.sun().sky_mode, DirectionalLight3D.SKY_MODE_LIGHT_AND_SKY, "home's Sun in the sky at noon")
	sky.time = DayCycle.SUNSET - 0.01
	sky.refresh()
	assert_eq(world.sun().sky_mode, DirectionalLight3D.SKY_MODE_LIGHT_ONLY, "at dusk only its light")
	_venus_sky()
	sky.time = DayCycle.SUNRISE + 0.01
	sky.refresh()
	assert_eq(world.sun().sky_mode, DirectionalLight3D.SKY_MODE_LIGHT_ONLY, "Venus's dawn in the west: only its light")
	assert_gt(world.ambience_base.sun, 0.0, "and it still lights the city")
	sky.time = DayCycle.NOON
	sky.refresh()
	assert_eq(world.sun().sky_mode, DirectionalLight3D.SKY_MODE_LIGHT_AND_SKY, "its big Sun by day")
