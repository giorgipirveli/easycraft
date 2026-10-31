extends GutTest
## Cosmos: Europa's sky on a real world's SkyCycle (spec §21b.2). Almost no air: space's black sky with stars all day
## (like the Moon's), the sun bright on the white ice; giant Jupiter hangs in it day and night (it never moves in
## Europa's sky: Europa always shows Jupiter the same face), drawn with its cloud bands and its Great Red Spot; Io and
## Ganymede, two of its other moons, small elsewhere in the sky; the big round moon disc of home never shows.

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
	sky.palette = UniverseRegistry.sky(SpaceRules.EUROPA)
	sky.space = UniverseRegistry.space_sky(SpaceRules.EUROPA)
	sky.refresh()
	assert_lt(_material().sky_top_color.get_luminance(), 0.05, "black overhead at noon")
	assert_true(sky.get_node("NightSky/Stars").visible, "stars by day: no air to hide them")


func test_giant_jupiter_and_two_small_moons_hang_in_the_sky_and_no_moon_disc() -> void:
	sky.show_planet(UniverseRegistry.sky_planet(SpaceRules.EUROPA))
	assert_not_null(sky.planet(), "Jupiter")
	assert_true(sky.planet().visible)
	var size := (sky.planet().mesh as QuadMesh).size.x
	assert_gt(size, 90.0, "huge")
	var moons := sky.moons()
	assert_eq(moons.size(), 2, "Io and Ganymede")
	for m in moons:
		assert_true(m.visible)
		assert_lt((m.mesh as QuadMesh).size.x, size * 0.25)
		assert_gt(m.position.distance_to(sky.planet().position), 60.0, "away from Jupiter")
	sky.time = 0.0   # midnight
	sky.refresh()
	assert_true(sky.planet().visible, "by night too")
	assert_false(sky.get_node("NightSky/Moon").visible, "home's big moon never shows over Europa")


func test_a_banded_planet_is_striped_with_a_red_spot() -> void:
	var jupiter := UniverseRegistry.sky_planet(SpaceRules.EUROPA)
	var img := SkyCycle.planet_image(jupiter)
	var n := img.get_width()
	var c := n / 2
	var down := 0.0   # the colour changes going down (across the bands) ...
	var along := 0.0  # ... far more than going sideways (along them)
	for i in range(c - 20, c + 20):
		down += _diff(img.get_pixel(c - 6, i), img.get_pixel(c - 6, i + 1))
		along += _diff(img.get_pixel(i, c - 6), img.get_pixel(i + 1, c - 6))
	assert_gt(down, along * 2.0, "cloud bands (down %.2f, along %.2f)" % [down, along])
	var red := 0
	for y in n:
		for x in n:
			var p := img.get_pixel(x, y)
			if p.a > 0.9 and p.r > p.g + 0.25 and p.r > p.b + 0.3:
				red += 1
	assert_gt(red, 20, "the Great Red Spot")
	var plain := SkyCycle.planet_image({"color": jupiter.color, "land": jupiter.land, "size": 20.0})
	var plain_red := 0
	for y in n:
		for x in n:
			var p := plain.get_pixel(x, y)
			if p.a > 0.9 and p.r > p.g + 0.25 and p.r > p.b + 0.3:
				plain_red += 1
	assert_lt(plain_red, red, "the spot is drawn only when asked for")


static func _diff(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
