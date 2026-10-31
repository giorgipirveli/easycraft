extends GutTest
## Cosmos: Ganymede's sky on a real world's SkyCycle (spec §21b.2). Almost no air: space's black starry sky all day (never
## Earth's photo sky, in both styles); the Sun small (5.2 times farther than from Earth); Jupiter big and banded with its
## Great Red Spot up in the east, day and night in the same place (Ganymede always shows it the same face); Io and Europa
## swinging back and forth past it (GanymedeSky: they go round Jupiter inside Ganymede's orbit, out to 23° and 39° from
## it, in front of it and behind it); no moon disc of home's. And the auroras (GanymedeSky): glowing belts over both
## poles at night only, green low down and pink higher up, with the night sky's own material settings (no new shader):
## from the pad the north belt hangs low over the northern horizon and the south belt over the southern; from the frost
## the north belt is overhead; the belts rock slowly to and fro.

var world: WorldService
var sky: SkyCycle
var shape: SpaceShape
var show: GanymedeSky
var at := Vector3.ZERO
var now := DayCycle.MIDNIGHT


func before_each() -> void:
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	sky = SkyCycle.new()
	sky.world = world
	add_child_autofree(sky)
	sky.time = DayCycle.NOON
	sky.refresh()
	shape = SpaceShape.new(12345, SpaceShape.GANYMEDE)
	var sp := shape.spawn_column()
	at = Vector3(sp.x, shape.height_at(sp.x, sp.y) + 1.6, sp.y)
	now = DayCycle.MIDNIGHT


func after_each() -> void:
	UniverseRegistry.reset()


func _material() -> ProceduralSkyMaterial:
	return world.environment().sky.sky_material as ProceduralSkyMaterial


func _ganymede_sky() -> void:
	sky.palette = UniverseRegistry.sky(SpaceRules.GANYMEDE)
	sky.space = UniverseRegistry.space_sky(SpaceRules.GANYMEDE)
	sky.sun_size = UniverseRegistry.sun_size(SpaceRules.GANYMEDE)
	sky.sun_west = UniverseRegistry.sun_rises_west(SpaceRules.GANYMEDE)
	sky.show_planet(UniverseRegistry.sky_planet(SpaceRules.GANYMEDE))
	sky.refresh()


func _show() -> GanymedeSky:
	_ganymede_sky()
	show = GanymedeSky.new()
	show.shape = shape
	show.sky = sky
	show.auto_tick = false
	show.viewer_position = func() -> Vector3: return at
	show.sky_time = func() -> float: return now
	add_child_autofree(show)
	return show


func test_a_black_starry_sky_and_a_small_sun() -> void:
	_ganymede_sky()
	assert_lt(_material().sky_top_color.get_luminance(), 0.05, "black overhead")
	assert_true(sky.get_node("NightSky/Stars").visible, "stars by day: almost no air")
	assert_almost_eq(_material().sun_angle_max, DayCycle.SUN_GLOW * 0.19, 0.0001, "the Sun about 5 times smaller")
	assert_gt(world.ambience_base.sun, 0.5, "still bright and friendly (spec §3c)")


func test_jupiter_big_banded_and_still_in_the_east_day_and_night() -> void:
	_ganymede_sky()
	var jupiter := sky.planet()
	assert_not_null(jupiter, "Jupiter")
	assert_true(jupiter.visible)
	var size := (jupiter.mesh as QuadMesh).size.x
	assert_between(size, 70.0, 104.0, "big (%.0f)" % size)
	var dir := jupiter.position.normalized()
	assert_gt(dir.x, 0.6, "in the east (%s)" % dir)
	assert_between(dir.y, 0.25, 0.6, "up in the sky")
	var noon := jupiter.position
	sky.time = 0.0
	sky.refresh()
	assert_eq(jupiter.position, noon, "never moves: Ganymede always shows Jupiter the same face")
	assert_false(sky.get_node("NightSky/Moon").visible, "Jupiter's moons, never home's big moon disc")
	var shown := sky.moons().filter(func(m: MeshInstance3D) -> bool: return m.visible)
	assert_eq(shown.size(), 2, "Io and Europa")


## Io and Europa swing back and forth past Jupiter, never farther than they really get from it seen from Ganymede (Io
## 23°, Europa 39°), to both sides; behind Jupiter they are hidden.
func test_io_and_europa_swing_past_jupiter() -> void:
	_show()
	var j := sky.planet().position.normalized()
	var io := sky.moons()[0]
	var europa := sky.moons()[1]
	var io_max := 0.0
	var eu_max := 0.0
	var io_sides := {}
	var eu_sides := {}
	var hidden := 0
	var moved := false
	var first := io.position
	for i in 240:
		show.tick(5.0)
		if io.position != first:
			moved = true
		for e: Array in [[io, GanymedeSky.IO_SWING, io_sides], [europa, GanymedeSky.EUROPA_SWING, eu_sides]]:
			var m: MeshInstance3D = e[0]
			var a := rad_to_deg(j.angle_to(m.position.normalized()))
			assert_lte(a, float(e[1]) + 0.5, "never farther from Jupiter than it really gets (%.1f°)" % a)
			if a > 5.0:
				(e[2] as Dictionary)[signf(m.position.normalized().cross(j).dot(Vector3(0.2, 0.9, 0.3)))] = true
			if not m.visible:
				hidden += 1
		io_max = maxf(io_max, rad_to_deg(j.angle_to(io.position.normalized())))
		eu_max = maxf(eu_max, rad_to_deg(j.angle_to(europa.position.normalized())))
	assert_true(moved, "they move")
	assert_gt(io_max, GanymedeSky.IO_SWING - 2.0, "Io swings out to ~23° (%.1f)" % io_max)
	assert_gt(eu_max, GanymedeSky.EUROPA_SWING - 3.0, "Europa out to ~39° (%.1f)" % eu_max)
	assert_eq(io_sides.size(), 2, "Io to both sides of Jupiter")
	assert_eq(eu_sides.size(), 2, "Europa to both sides")
	assert_gt(hidden, 0, "now and then behind Jupiter")


## The pure rule: a moon's angle from Jupiter swings like a pendulum (a circle seen edge-on), in front half the time.
func test_a_swing_is_a_circle_seen_edge_on() -> void:
	var s0 := GanymedeSky.swing(0.0, 100.0, 30.0, 0.0)
	var s1 := GanymedeSky.swing(25.0, 100.0, 30.0, 0.0)
	var s2 := GanymedeSky.swing(75.0, 100.0, 30.0, 0.0)
	assert_almost_eq(s0.x, 0.0, 0.01, "in line with Jupiter")
	assert_almost_eq(s1.x, 30.0, 0.01, "farthest out a quarter turn later")
	assert_almost_eq(s2.x, -30.0, 0.01, "and on the other side three quarters later")
	assert_ne(signf(GanymedeSky.swing(0.0, 100.0, 30.0, 0.0).y), signf(GanymedeSky.swing(50.0, 100.0, 30.0, 0.0).y),
		"once in front, once behind")


func test_the_auroras_glow_only_at_night() -> void:
	_show()
	now = DayCycle.NOON
	show.tick(0.2)
	assert_false(show.north.visible, "by day they cannot be seen")
	assert_false(show.south.visible)
	now = DayCycle.MIDNIGHT
	show.tick(0.2)
	assert_true(show.north.visible, "at night the northern auroras glow")
	assert_true(show.south.visible, "and the southern ones")
	for m: MeshInstance3D in show.curtains():
		var mat := m.mesh.surface_get_material(0) as StandardMaterial3D
		assert_eq(mat.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED, "the night sky's settings: unshaded")
		assert_true(mat.disable_fog, "never fogged")
		assert_eq(mat.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA, "see-through")
		assert_true(mat.vertex_color_use_as_albedo, "vertex colours: green low, pink high")
		assert_gt(mat.albedo_color.a, 0.3, "bright at midnight")


## From the pad: the north belt low over the northern horizon, the south belt low over the southern one; both inside
## the camera's far plane. From the north frost: overhead.
func test_from_the_pad_low_in_the_north_and_south_and_overhead_on_the_frost() -> void:
	_show()
	show.tick(0.2)
	var n := show.north.global_position - at
	assert_lt(n.z, 0.0, "the north belt is north (%s)" % n)
	var up := rad_to_deg(atan2(n.y, -n.z))
	assert_between(up, 8.0, 40.0, "low over the northern horizon (%.0f°)" % up)
	assert_lte(n.length(), GanymedeSky.BELT_FAR + 0.5, "inside the far plane")
	var s := show.south.global_position - at
	assert_gt(s.z, 0.0, "the south belt is south (%s)" % s)
	assert_between(rad_to_deg(atan2(s.y, s.z)), 5.0, 40.0, "low over the southern horizon")
	var bz := show.belt_z(true)
	at = Vector3(at.x, 60.0, bz)
	show.tick(0.2)
	var o := show.north.global_position - at
	assert_gt(rad_to_deg(atan2(o.y, Vector2(o.x, o.z).length())), 70.0, "overhead from the frost under it")
	assert_almost_eq(show.north.global_position.x, at.x, 0.01, "it runs east and west round the pole, over the child")


## The belts rock slowly to and fro (Jupiter's own magnetic field changes as it spins; Ganymede's salty ocean keeps the
## rocking small: how scientists found the ocean).
func test_the_belts_rock_slowly() -> void:
	_show()
	var zs: Array[float] = []
	for i in 40:
		show.tick(GanymedeSky.ROCK_PERIOD / 40.0)
		zs.append(show.belt_z(true))
	var lo: float = zs.min()
	var hi: float = zs.max()
	assert_between(hi - lo, GanymedeSky.ROCK * 1.5, GanymedeSky.ROCK * 2.0 + 0.01, "to and fro (%.1f)" % (hi - lo))


## A long belt never ends in a hard edge: its curtains dissolve at both ends.
func test_the_belts_curtains_dissolve_at_their_ends() -> void:
	var mesh := GanymedeSky.belt_mesh(400.0, 60.0, 0.0, NatureSky.star_material())
	var arrays := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var c: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var ends := 0.0
	var middle := 0.0
	for i in v.size():
		if absf(v[i].x) >= 199.9:
			ends = maxf(ends, c[i].a)
		elif absf(v[i].x) < 20.0:
			middle = maxf(middle, c[i].a)
	assert_almost_eq(ends, 0.0, 0.001, "nothing at its ends")
	assert_gt(middle, 0.8, "bright in its middle")
