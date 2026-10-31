extends GutTest
## Cosmos: Titan's sky on a real world's SkyCycle (spec §21b.2). Thick air: never space's black sky; by day an orange
## haze, paler and golden at the horizon, an orange fog; Saturn, pale and banded with its rings, hangs in it day and night;
## the haze hides Saturn's other moons; the big round moon disc of home never shows.

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


func test_an_orange_haze_by_day_never_space_black() -> void:
	sky.palette = UniverseRegistry.sky(SpaceRules.TITAN)
	sky.space = UniverseRegistry.space_sky(SpaceRules.TITAN)
	sky.refresh()
	var top := _material().sky_top_color
	assert_gt(top.r, top.b + 0.2, "orange overhead at noon (%s)" % top)
	assert_gt(top.get_luminance(), 0.3, "a bright haze, not space's black (%s)" % top)
	var horizon := _material().sky_horizon_color
	assert_gt(horizon.get_luminance(), top.get_luminance(), "paler at the horizon")
	assert_false(sky.get_node("NightSky/Stars").visible, "no stars by day: the thick air hides them")
	var fog: Color = world.ambience_base.fog_color
	assert_gt(fog.r, fog.b, "an orange fog far away (%s)" % fog)


func test_saturn_and_its_rings_hang_in_the_sky_and_no_moon_disc() -> void:
	sky.show_planet(UniverseRegistry.sky_planet(SpaceRules.TITAN))
	assert_not_null(sky.planet(), "Saturn")
	assert_true(sky.planet().visible)
	var size := (sky.planet().mesh as QuadMesh).size.x
	assert_gt(size, 120.0, "big, its rings wider still")
	for m in sky.moons():
		assert_false(m.visible, "the haze hides Saturn's other moons")
	var img := SkyCycle.planet_image(UniverseRegistry.sky_planet(SpaceRules.TITAN))
	var ring := 0
	for x in img.get_width():
		var c := img.get_pixel(x, int(img.get_height() * 0.5))   # the ring crosses the middle, wider than the planet
		if c.a > 0.5 and absf(x - img.get_width() * 0.5) > img.get_width() * 0.33:
			ring += 1
	assert_gt(ring, 4, "its rings stick out on both sides")
	sky.time = 0.0   # midnight
	sky.refresh()
	assert_true(sky.planet().visible, "by night too")
	assert_false(sky.get_node("NightSky/Moon").visible, "home's big moon never shows over Titan")
