extends GutTest
## Owner feedback #55 (spec §21): the sky of space on a real world's SkyCycle. Climbing toward the line turns the day
## sky black and starry (a few steps, not every frame); a space world's own sky can be space's all day (the Moon), and
## a planet hangs in it (the home planet over the Moon) while the night's moon disc stays away.

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


func _top() -> Color:
	return (world.environment().sky.sky_material as ProceduralSkyMaterial).sky_top_color


func _stars() -> MeshInstance3D:
	return sky.get_node("NightSky/Stars")


func test_climbing_turns_the_day_sky_to_space() -> void:
	var day := _top()
	assert_false(_stars().visible, "no stars at noon")
	assert_true(sky.set_space_climb(1.0))
	assert_lt(_top().get_luminance(), 0.1, "black at the line")
	assert_lt(_top().get_luminance(), day.get_luminance())
	assert_true(_stars().visible, "the stars are out at noon up there")
	assert_true(sky.set_space_climb(0.0))
	assert_eq(_top(), day, "back down: the day again")


func test_small_steps_do_not_relight_the_sky() -> void:
	assert_false(sky.set_space_climb(0.02))
	assert_true(sky.set_space_climb(0.3))
	assert_false(sky.set_space_climb(0.32))
	assert_true(sky.set_space_climb(1.0), "the line itself always counts")


func test_a_space_world_is_space_all_day() -> void:
	sky.space = 1.0
	sky.refresh()
	assert_lt(_top().get_luminance(), 0.1)
	assert_true(_stars().visible)


func test_a_planet_hangs_in_a_space_worlds_sky_and_the_moon_disc_stays_away() -> void:
	assert_null(sky.planet(), "no planet at home")
	sky.space = 1.0
	sky.show_planet({"color": Color("3f8fe0"), "land": Color("5cb85c"), "ring": false, "size": 60.0})
	assert_not_null(sky.planet())
	assert_true(sky.planet().visible)
	sky.time = 0.0   # midnight
	sky.refresh()
	assert_true(sky.planet().visible, "by night too")
	assert_false(sky.get_node("NightSky/Moon").visible, "no moon disc over the Moon")
	sky.show_planet({})
	assert_false(sky.planet().visible)


func test_the_photo_sky_dims_in_space() -> void:
	world.apply_style("realistic")
	sky.refresh()
	var day := (world.environment().sky.sky_material as PanoramaSkyMaterial).energy_multiplier
	sky.set_space_climb(1.0)
	assert_lt((world.environment().sky.sky_material as PanoramaSkyMaterial).energy_multiplier, day)
	world.apply_style("blocky")
	BlockLibrary.set_style("blocky")


## Cosmos: a space world with an air sky of its own (Planet Boing's violet, Rainbow Planet's lilac, Mars's butterscotch)
## keeps it in the realistic style (the photo sky is Earth's blue with clouds); the Moon's black space sky dims the
## photo sky instead. And none has a dark band under its horizon.
func test_every_space_world_keeps_its_own_sky() -> void:
	for u in SpaceRules.WORLDS:
		if UniverseRegistry.space_sky(u) >= 1.0:
			continue
		assert_false(UniverseRegistry.photo_sky(u), "world %d keeps its own sky when realistic" % u)
		var sky := UniverseRegistry.sky(u)
		var ground: Color = sky.get("ground_bottom", Color.WHITE)
		var fog: Color = sky.get("fog", Color.WHITE)
		assert_gt(ground.get_luminance(), fog.get_luminance() * 0.7, "world %d: no dark band under the horizon" % u)

