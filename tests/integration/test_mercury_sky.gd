extends GutTest
## Cosmos: Mercury's sky on a real world's SkyCycle (spec §21b.2). Almost no air: space's black sky with stars even at
## noon; the Sun three times as big as at home (the descriptor's `sun_size` scales the sky's sun: SkyCycle.sun_size), in
## both styles (Mercury keeps its painted sky when realistic); Venus, Earth and our Moon as tiny points; no moon of its
## own, so the big round moon disc of home never shows.

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


func _mercury_sky() -> void:
	sky.palette = UniverseRegistry.sky(SpaceRules.MERCURY)
	sky.space = UniverseRegistry.space_sky(SpaceRules.MERCURY)
	sky.sun_size = UniverseRegistry.sun_size(SpaceRules.MERCURY)
	sky.show_planet(UniverseRegistry.sky_planet(SpaceRules.MERCURY))
	sky.refresh()


func test_home_has_the_usual_sun() -> void:
	assert_eq(sky.sun_size, 1.0)
	assert_almost_eq(_material().sun_angle_max, DayCycle.SUN_GLOW, 0.001, "home's Sun")


func test_a_black_sky_with_stars_at_noon_and_a_sun_three_times_as_big() -> void:
	_mercury_sky()
	var top := _material().sky_top_color
	assert_lt(top.get_luminance(), 0.05, "space's black overhead at noon (%s)" % top)
	assert_true(sky.get_node("NightSky/Stars").visible, "stars even by day")
	assert_almost_eq(_material().sun_angle_max, DayCycle.SUN_GLOW * 3.0, 0.001, "the Sun three times as big")
	assert_gt(world.ambience_base.sun, 0.5, "and it shines bright: never dark")


func test_the_night_light_stays_the_usual_size() -> void:
	_mercury_sky()
	sky.time = 0.0   # midnight: the one light is the night's
	sky.refresh()
	assert_almost_eq(_material().sun_angle_max, DayCycle.MOON_GLOW, 0.001, "only the Sun is bigger")
	assert_false(sky.get_node("NightSky/Moon").visible, "Mercury has no moon: home's big moon never shows")


func test_venus_earth_and_our_moon_are_tiny_points() -> void:
	_mercury_sky()
	assert_not_null(sky.planet(), "Venus")
	assert_true(sky.planet().visible)
	assert_lt((sky.planet().mesh as QuadMesh).size.x, 10.0, "a tiny bright point, not a big planet")
	var shown := sky.moons().filter(func(m: MeshInstance3D) -> bool: return m.visible)
	assert_eq(shown.size(), 2, "Earth and our Moon")
	for m: MeshInstance3D in shown:
		assert_lt((m.mesh as QuadMesh).size.x, 8.0, "tiny points")


func test_the_realistic_style_keeps_mercurys_sky_and_its_big_sun() -> void:
	world.photo_sky = UniverseRegistry.photo_sky(SpaceRules.MERCURY)
	world.apply_style("realistic")
	_mercury_sky()
	assert_true(world.environment().sky.sky_material is ProceduralSkyMaterial, "its own painted sky, never Earth's photo")
	assert_almost_eq(_material().sun_angle_max, DayCycle.SUN_GLOW * 3.0, 0.001, "the big Sun in both styles")
	world.apply_style("blocky")
