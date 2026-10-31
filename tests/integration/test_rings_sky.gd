extends GutTest
## Cosmos: Saturn's rings' sky on a real world's SkyCycle (spec §21b.2). No air: space's black sky with stars by day
## (never Earth's photo sky, in both styles); the Sun about ten times smaller than at home (Saturn is 9.5 times farther
## from it); Saturn huge over the northern horizon, banded, its rings seen edge-on as a bright line across its middle
## with their shadow on its clouds and its own shadow cutting them just past its edge; Titan and other moons, the F ring's
## little shepherds low in the south; no moon disc of home's.

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


func _rings_sky() -> void:
	sky.palette = UniverseRegistry.sky(SpaceRules.RINGS)
	sky.space = UniverseRegistry.space_sky(SpaceRules.RINGS)
	sky.sun_size = UniverseRegistry.sun_size(SpaceRules.RINGS)
	sky.sun_west = UniverseRegistry.sun_rises_west(SpaceRules.RINGS)
	sky.show_planet(UniverseRegistry.sky_planet(SpaceRules.RINGS))
	sky.refresh()


func test_a_black_starry_sky_by_day_and_a_small_far_sun() -> void:
	_rings_sky()
	var top := _material().sky_top_color
	assert_lt(top.get_luminance(), 0.05, "space's black sky (%s)" % top)
	assert_true(sky.get_node("NightSky/Stars").visible, "stars by day: no air")
	assert_almost_eq(_material().sun_angle_max, DayCycle.SUN_GLOW * 0.1, 0.001, "the Sun about ten times smaller")
	assert_gt(world.ambience_base.sun, 0.5, "still bright and friendly (spec §3c)")


func test_saturn_huge_over_the_northern_horizon() -> void:
	_rings_sky()
	var planet := sky.planet()
	assert_not_null(planet, "Saturn")
	assert_true(planet.visible)
	var size := (planet.mesh as QuadMesh).size.x
	assert_gte(size, 300.0, "huge (%.0f)" % size)
	var dir := planet.position.normalized()
	assert_lt(dir.z, -0.9, "north, towards Saturn (%s)" % dir)
	assert_between(dir.y, -0.1, 0.1, "centred on the horizon: we stand in its rings' plane")
	var disc := 0.3 * size   # planet_image: the globe's radius on the quad (room round it for the rings)
	var across := rad_to_deg(2.0 * atan(disc / SkyCycle.MOON_RADIUS))
	assert_between(across, 55.0, 90.0, "about 70° across, as from the B ring (%.0f°)" % across)
	var shown := sky.moons().filter(func(m: MeshInstance3D) -> bool: return m.visible)
	assert_gte(shown.size(), 3, "Titan and other moons")
	sky.time = 0.0
	sky.refresh()
	assert_false(sky.get_node("NightSky/Moon").visible, "Saturn's moons, never home's big moon disc")


## The picture: pale gold zones and tan belts, the rings a bright line across the middle and out past the edge, cut dark
## by Saturn's shadow just past its right edge, their shadow a dark band on its clouds.
func test_saturns_picture_its_bands_rings_and_shadows() -> void:
	var p := UniverseRegistry.sky_planet(SpaceRules.RINGS)
	var t0 := Time.get_ticks_usec()
	var img := SkyCycle.planet_image(p)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	gut.p("RINGS_SATURN_IMAGE %d px: %.1f ms" % [img.get_width(), ms])
	assert_lt(ms, 400.0, "made once at the world's load")
	var n := img.get_width()
	assert_eq(n, int(p.pixels), "a bigger picture for a huge planet")
	var c := n / 2
	var r := int(n * 0.3)
	var line := img.get_pixel(c + r + int(r * 0.6), c)
	assert_gt(line.a, 0.8, "the rings reach out past its edge")
	assert_gt(line.get_luminance(), 0.8, "bright ice, edge-on (%s)" % line)
	var shadow := img.get_pixel(c + r + int(r * 0.15), c)
	assert_lt(shadow.get_luminance(), 0.45, "Saturn's shadow across its rings (%s)" % shadow)
	var left := img.get_pixel(c - r - int(r * 0.15), c)
	assert_gt(left.get_luminance(), 0.8, "the sunlit side's rings")
	var ring_shadow := img.get_pixel(c, c + int(r * 0.1))
	var cloud := img.get_pixel(c, c + int(r * 0.3))
	assert_lt(ring_shadow.get_luminance(), cloud.get_luminance() - 0.1, "the rings' shadow on its clouds")
	var outside := img.get_pixel(2, 2)
	assert_lt(outside.a, 0.1, "space round it")


func test_the_realistic_style_keeps_the_black_sky() -> void:
	world.photo_sky = UniverseRegistry.photo_sky(SpaceRules.RINGS)
	world.apply_style("realistic")
	_rings_sky()
	assert_true(world.environment().sky.sky_material is ProceduralSkyMaterial, "its own painted sky, never Earth's photo")
	assert_lt(_material().sky_top_color.get_luminance(), 0.05, "space's black")
	world.apply_style("blocky")
