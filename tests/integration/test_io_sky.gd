extends GutTest
## Cosmos: Io's sky on a real world's SkyCycle (spec §21b.2). Almost no air: space's black sky with stars all day, the sun
## bright on the yellow sulphur; giant Jupiter (bigger than over Europa: Io is closer to it) hangs in it day and night,
## banded, with its Great Red Spot; Europa and Ganymede, two of its other moons, small elsewhere in the sky; the big round
## moon disc of home never shows.

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


func test_a_black_starry_sky_by_day() -> void:
	sky.palette = UniverseRegistry.sky(SpaceRules.IO)
	sky.space = UniverseRegistry.space_sky(SpaceRules.IO)
	sky.refresh()
	assert_lt(_material().sky_top_color.get_luminance(), 0.05, "black overhead at noon")
	assert_true(sky.get_node("NightSky/Stars").visible, "stars by day: almost no air to hide them")


func test_giant_jupiter_and_two_small_moons_hang_in_the_sky_and_no_moon_disc() -> void:
	sky.show_planet(UniverseRegistry.sky_planet(SpaceRules.IO))
	assert_not_null(sky.planet(), "Jupiter")
	assert_true(sky.planet().visible)
	var size := (sky.planet().mesh as QuadMesh).size.x
	assert_gt(size, 120.0, "huge: bigger than over Europa")
	var moons := sky.moons()
	assert_eq(moons.size(), 2, "Europa and Ganymede")
	for m in moons:
		assert_true(m.visible)
		assert_lt((m.mesh as QuadMesh).size.x, size * 0.2)
		assert_gt(m.position.distance_to(sky.planet().position), 80.0, "away from Jupiter")
	sky.time = 0.0   # midnight
	sky.refresh()
	assert_true(sky.planet().visible, "by night too")
	assert_false(sky.get_node("NightSky/Moon").visible, "home's big moon never shows over Io")
