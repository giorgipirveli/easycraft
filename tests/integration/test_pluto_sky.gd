extends GutTest
## Cosmos: Pluto's sky on a real world's SkyCycle (spec §21b.2). A thin nitrogen air: black and starry overhead by day
## with a blue haze along the horizon (never Earth's photo sky, in both styles); the Sun a very bright star (40 times
## farther than from Earth, 1/40 as wide); Charon big and grey with its red cap, low in the west, day and night in the
## same place; Nix and Hydra tiny points; no moon disc of home's.

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


func _pluto_sky() -> void:
	sky.palette = UniverseRegistry.sky(SpaceRules.PLUTO)
	sky.space = UniverseRegistry.space_sky(SpaceRules.PLUTO)
	sky.sun_size = UniverseRegistry.sun_size(SpaceRules.PLUTO)
	sky.sun_west = UniverseRegistry.sun_rises_west(SpaceRules.PLUTO)
	sky.show_planet(UniverseRegistry.sky_planet(SpaceRules.PLUTO))
	sky.refresh()


func test_a_black_starry_sky_a_blue_haze_and_a_star_like_sun() -> void:
	_pluto_sky()
	var top := _material().sky_top_color
	assert_lt(top.get_luminance(), 0.06, "black overhead (%s)" % top)
	var haze := _material().sky_horizon_color
	assert_gt(haze.b, haze.r + 0.15, "a blue haze along the horizon (%s)" % haze)
	assert_gt(haze.get_luminance(), top.get_luminance() + 0.12, "glowing brighter than the black above (%s)" % haze)
	assert_true(sky.get_node("NightSky/Stars").visible, "stars by day: the air is very thin")
	assert_almost_eq(_material().sun_angle_max, DayCycle.SUN_GLOW * 0.025, 0.0001, "the Sun a tiny bright point")
	assert_gt(world.ambience_base.sun, 0.5, "still bright and friendly (spec §3c)")
	var fog: Color = world.ambience_base.fog_color
	assert_gt(fog.b, fog.r + 0.1, "a blue haze over the far ground too (%s)" % fog)


func test_charon_big_and_still_in_the_west_day_and_night() -> void:
	_pluto_sky()
	var charon := sky.planet()
	assert_not_null(charon, "Charon")
	assert_true(charon.visible)
	var size := (charon.mesh as QuadMesh).size.x
	assert_gte(size, 50.0, "big (%.0f)" % size)
	var dir := charon.position.normalized()
	assert_lt(dir.x, -0.8, "in the west (%s)" % dir)
	assert_between(dir.y, 0.15, 0.5, "low over the horizon")
	var noon := charon.position
	sky.time = 0.0
	sky.refresh()
	assert_eq(charon.position, noon, "never moves: Pluto and Charon always face each other")
	assert_false(sky.get_node("NightSky/Moon").visible, "Pluto's moons, never home's big moon disc")
	var shown := sky.moons().filter(func(m: MeshInstance3D) -> bool: return m.visible)
	assert_eq(shown.size(), 2, "Nix and Hydra")


## The picture: a grey globe with its red cap on top.
func test_charons_picture_grey_with_a_red_cap() -> void:
	var img := SkyCycle.planet_image(UniverseRegistry.sky_planet(SpaceRules.PLUTO))
	var n := img.get_width()
	var c := n / 2
	var r := int(n * 0.46)
	var top := img.get_pixel(c, c - int(r * 0.85))
	assert_gt(top.r, top.b + 0.15, "the red cap at its top (%s)" % top)
	var middle := img.get_pixel(c, c + int(r * 0.2))
	assert_lt(absf(middle.r - middle.b), 0.1, "grey below it (%s)" % middle)
	assert_lt(img.get_pixel(1, 1).a, 0.1, "space round it")
	var plain := SkyCycle.planet_image({"color": Color("a8a39d"), "land": Color("8f8a84")})
	var no_cap := plain.get_pixel(c, c - int(r * 0.85))
	assert_lt(absf(no_cap.r - no_cap.b), 0.1, "no cap without one (%s)" % no_cap)


func test_the_realistic_style_keeps_its_own_sky() -> void:
	world.photo_sky = UniverseRegistry.photo_sky(SpaceRules.PLUTO)
	world.apply_style("realistic")
	_pluto_sky()
	assert_true(world.environment().sky.sky_material is ProceduralSkyMaterial, "its own painted sky, never Earth's photo")
	assert_lt(_material().sky_top_color.get_luminance(), 0.06, "black overhead")
	world.apply_style("blocky")
