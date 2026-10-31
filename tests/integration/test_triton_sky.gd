extends GutTest
## Cosmos: Triton's sky on a real world's SkyCycle (spec §21b.2). A very thin nitrogen air: black and starry by day with a
## faint cold haze low down (never Earth's photo sky, in both styles); the Sun a very bright star (30 times farther than
## from Earth, 1/30 as wide); Neptune huge and deep blue with its faint bands and its great dark spot, up in the
## north-east, day and night in the same place (Triton always shows it the same face); two of Neptune's small moons as
## points; no moon disc of home's.

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


func _triton_sky() -> void:
	sky.palette = UniverseRegistry.sky(SpaceRules.TRITON)
	sky.space = UniverseRegistry.space_sky(SpaceRules.TRITON)
	sky.sun_size = UniverseRegistry.sun_size(SpaceRules.TRITON)
	sky.sun_west = UniverseRegistry.sun_rises_west(SpaceRules.TRITON)
	sky.show_planet(UniverseRegistry.sky_planet(SpaceRules.TRITON))
	sky.refresh()


func test_a_black_starry_sky_a_faint_haze_and_a_star_like_sun() -> void:
	_triton_sky()
	var top := _material().sky_top_color
	assert_lt(top.get_luminance(), 0.05, "black overhead (%s)" % top)
	var haze := _material().sky_horizon_color
	assert_gte(haze.b, haze.r, "a faint cold haze low down (%s)" % haze)
	assert_true(sky.get_node("NightSky/Stars").visible, "stars by day: the air is very thin")
	assert_almost_eq(_material().sun_angle_max, DayCycle.SUN_GLOW * 0.033, 0.0001, "the Sun a tiny bright point")
	assert_gt(world.ambience_base.sun, 0.5, "still bright and friendly (spec §3c)")


func test_neptune_huge_blue_and_still_in_the_north_east_day_and_night() -> void:
	_triton_sky()
	var neptune := sky.planet()
	assert_not_null(neptune, "Neptune")
	assert_true(neptune.visible)
	var size := (neptune.mesh as QuadMesh).size.x
	assert_gte(size, 90.0, "huge (%.0f)" % size)
	var dir := neptune.position.normalized()
	assert_gt(dir.x, 0.4, "in the east (%s)" % dir)
	assert_lt(dir.z, -0.4, "and the north")
	assert_between(dir.y, 0.15, 0.4, "low over the horizon, in the day views there")
	var noon := neptune.position
	sky.time = 0.0
	sky.refresh()
	assert_eq(neptune.position, noon, "never moves: Triton always shows Neptune the same face")
	assert_false(sky.get_node("NightSky/Moon").visible, "Neptune's moons, never home's big moon disc")
	var shown := sky.moons().filter(func(m: MeshInstance3D) -> bool: return m.visible)
	assert_eq(shown.size(), 2, "two small moons")


## The picture: a deep blue globe with paler bands and a great dark spot (not Jupiter's red one).
func test_neptunes_picture_deep_blue_with_a_dark_spot() -> void:
	var p := UniverseRegistry.sky_planet(SpaceRules.TRITON)
	var img := SkyCycle.planet_image(p)
	var n := img.get_width()
	var c := n / 2
	var r := int(n * 0.46)
	var middle := img.get_pixel(c - int(r * 0.4), c - int(r * 0.2))
	assert_gt(middle.b, middle.r + 0.25, "deep blue (%s)" % middle)
	var spot := img.get_pixel(c + int(r * 0.25), c + int(r * 0.32))
	assert_lt(spot.get_luminance(), 0.25, "the dark spot (%s)" % spot)
	assert_gt(SkyCycle.SPOT.r - spot.r, 0.4, "not Jupiter's red spot (%s)" % spot)
	assert_lt(img.get_pixel(1, 1).a, 0.1, "space round it")
	var jupiter := SkyCycle.planet_image({"color": Color("e3cfa8"), "land": Color("b0714a"), "bands": true, "spot": true})
	var red := jupiter.get_pixel(c + int(r * 0.25), c + int(r * 0.32))
	assert_gt(red.r, red.b + 0.2, "Jupiter's spot stays red without a spot colour (%s)" % red)


func test_the_realistic_style_keeps_its_own_sky() -> void:
	world.photo_sky = UniverseRegistry.photo_sky(SpaceRules.TRITON)
	world.apply_style("realistic")
	_triton_sky()
	assert_true(world.environment().sky.sky_material is ProceduralSkyMaterial, "its own painted sky, never Earth's photo")
	assert_lt(_material().sky_top_color.get_luminance(), 0.05, "black overhead")
	world.apply_style("blocky")
