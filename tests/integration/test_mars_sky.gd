extends GutTest
## Cosmos: Mars's sky on a real world's SkyCycle (spec §21b.2). By day the universe's butterscotch colours; at sunset
## the glow at the horizon turns blue (a palette's `sunset`, as on the real Mars); its two small moons hang in the sky
## day and night, Phobos and the smaller Deimos, lumpy like potatoes, and the big round moon disc of home never shows.

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


func test_a_butterscotch_day_and_a_blue_sunset_glow() -> void:
	sky.palette = UniverseRegistry.sky(SpaceRules.MARS)
	sky.refresh()
	var day_top := _material().sky_top_color
	assert_gt(day_top.r, day_top.b, "butterscotch overhead at noon (%s)" % day_top)
	var day_horizon := _material().sky_horizon_color
	sky.time = DayCycle.SUNSET   # the sun on the horizon: the glow at its strongest
	sky.refresh()
	var dusk := _material().sky_horizon_color
	assert_gt(dusk.b, dusk.r, "a blue glow at the horizon at sunset (%s)" % dusk)
	assert_gt(dusk.b - dusk.r, day_horizon.b - day_horizon.r)
	sky.palette = UniverseRegistry.sky(1)
	sky.refresh()
	assert_lt(_material().sky_horizon_color.b - _material().sky_horizon_color.r, dusk.b - dusk.r,
		"only Mars's sunsets are blue")


func test_phobos_and_deimos_hang_in_the_sky_and_no_moon_disc() -> void:
	sky.show_planet(UniverseRegistry.sky_planet(SpaceRules.MARS))
	assert_not_null(sky.planet(), "Phobos")
	assert_true(sky.planet().visible)
	var moons := sky.moons()
	assert_eq(moons.size(), 1, "Deimos")
	assert_true(moons[0].visible)
	assert_lt((moons[0].mesh as QuadMesh).size.x, (sky.planet().mesh as QuadMesh).size.x, "Deimos is smaller")
	assert_gt(moons[0].position.distance_to(sky.planet().position), 20.0, "in another part of the sky")
	sky.time = 0.0   # midnight
	sky.refresh()
	assert_true(sky.planet().visible, "by night too")
	assert_false(sky.get_node("NightSky/Moon").visible, "home's big moon never shows over Mars")
	sky.show_planet({})
	assert_false(sky.planet().visible)
	assert_false(moons[0].visible, "the small moon goes with it")
	sky.refresh()
	assert_true(sky.get_node("NightSky/Moon").visible, "a world without its own moons keeps the moon disc")


func test_a_lumpy_moon_is_not_a_perfect_disc() -> void:
	var round := SkyCycle.planet_image({"color": Color("8a7f74"), "size": 20.0})
	var lumpy := SkyCycle.planet_image({"color": Color("8a7f74"), "size": 20.0, "lumpy": true})
	var differ := 0
	for y in round.get_height():
		for x in round.get_width():
			if (round.get_pixel(x, y).a > 0.5) != (lumpy.get_pixel(x, y).a > 0.5):
				differ += 1
	assert_gt(differ, 40, "a potato shape, like the real Phobos and Deimos")
