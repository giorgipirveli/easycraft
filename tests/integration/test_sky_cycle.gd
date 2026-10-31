extends GutTest
## SkyCycle (M1b Task 10) drives a real world's sky from DayCycle: the open-air light goes into
## ambience_base (Ambience adds caves and water on top), the sun turns into the moon at night, and
## both graphics styles get darker at night.

var world: WorldService
var sky: SkyCycle


func before_each() -> void:
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	world.apply_graphics({"graphics": "medium", "view_distance": 96})
	sky = SkyCycle.new()
	sky.world = world
	add_child_autofree(sky)


func after_each() -> void:
	BlockLibrary.set_style("blocky")


func _light_travel() -> Vector3:
	return -world.sun().global_transform.basis.z


func _blocky_sky() -> ProceduralSkyMaterial:
	return world.environment().sky.sky_material as ProceduralSkyMaterial


func test_noon_is_the_worlds_day_look() -> void:
	sky.set_time(DayCycle.NOON)
	assert_almost_eq(world.ambience_base.sun, 1.0, 0.001)
	assert_almost_eq(world.ambience_base.ambient, 0.65, 0.001)
	assert_true((world.ambience_base.fog_color as Color).is_equal_approx(DayCycle.DAY_FOG))
	assert_lt(_light_travel().y, -0.8, "the sun shines down from high up")
	assert_false(sky._stars.visible)
	assert_false(sky._moon.visible)


func test_midnight_is_dark_but_moonlit_and_keeps_the_fog_distances() -> void:
	sky.set_time(DayCycle.MIDNIGHT)
	var base := world.ambience_base
	assert_between(base.ambient as float, 0.4, 0.64, "darker, never black")
	assert_between(base.sun as float, 0.25, 0.9, "moonlight")
	assert_almost_eq(base.fog_begin as float, 96 * WorldService.FOG_BEGIN, 0.001, "fog distances stay apply_graphics'")
	assert_almost_eq(base.fog_end as float, 96.0, 0.001)
	assert_lt(_light_travel().y, -0.5, "the moon shines down")
	assert_gt(world.sun().light_color.b, world.sun().light_color.r, "blue moonlight")
	assert_true(sky._stars.visible)
	assert_true(sky._moon.visible)
	assert_lt(_blocky_sky().sky_top_color.v, 0.3, "a dark blue blocky sky")


func test_the_realistic_sky_is_dimmed_at_night() -> void:
	world.apply_style("realistic")
	sky.set_time(DayCycle.MIDNIGHT)
	var pano := world.environment().sky.sky_material as PanoramaSkyMaterial
	assert_not_null(pano)
	assert_lt(pano.energy_multiplier, 0.3)
	sky.set_time(DayCycle.NOON)
	assert_almost_eq(pano.energy_multiplier, 1.0, 0.001)


func test_a_style_switch_gets_the_night_look_at_once() -> void:
	sky.set_time(DayCycle.MIDNIGHT)
	world.apply_style("realistic")          # a fresh, full-brightness HDRI sky
	sky._process(0.0)
	assert_lt((world.environment().sky.sky_material as PanoramaSkyMaterial).energy_multiplier, 0.3)
	world.apply_style("blocky")
	sky._process(0.0)
	assert_lt(_blocky_sky().sky_top_color.v, 0.3)


## Review M7: every settings change (even the volume) re-applied the style, which built a new
## full-brightness HDRI sky: a flash at night and a new sky radiance map on the phone each time.
func test_reapplying_the_same_style_keeps_the_sky() -> void:
	world.apply_style("realistic")
	sky.set_time(DayCycle.MIDNIGHT)
	var pano := world.environment().sky.sky_material
	world.apply_style("realistic")
	assert_same(world.environment().sky.sky_material, pano, "the same sky")
	assert_lt((pano as PanoramaSkyMaterial).energy_multiplier, 0.3, "still dimmed for the night")


func test_the_clock_runs_and_can_stop() -> void:
	sky.set_time(0.2)
	sky._process(60.0)
	assert_almost_eq(sky.time, 0.25, 0.0001, "a minute is a twentieth of the day")
	sky.running = false
	sky._process(60.0)
	assert_almost_eq(sky.time, 0.25, 0.0001)


## Survivor games (spec §12.18): Build to Survive's clock runs 4× by day and 2× at night; the others as before.
func test_build_to_survive_runs_the_clock_fast() -> void:
	sky.game = SurvivorGames.BUILD
	sky.set_time(0.3)
	sky._process(15.0)
	assert_almost_eq(sky.time, 0.35, 0.0001, "15 s of day are a minute of the usual clock")
	sky.set_time(DayCycle.MIDNIGHT)
	sky._process(30.0)
	assert_almost_eq(sky.time, 0.05, 0.0001, "30 s of night are a minute")
	sky.game = SurvivorGames.CLASSIC
	sky.set_time(0.3)
	sky._process(60.0)
	assert_almost_eq(sky.time, 0.35, 0.0001, "Classic keeps the usual clock")
