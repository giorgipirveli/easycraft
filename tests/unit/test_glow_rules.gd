extends GutTest
## Universe 6, the Glow Caves (spec §5.1, §3c: calm, never scary): GlowRules, the caves' light as pure rules. Under the
## caves' roof the mood is a soft blue-violet dark, never black, the same by day and by night (the glow is the caves'
## own): a blue-violet ambient light (mostly its own colour, little of the sky's), blue-violet fog that lets far halls
## fade softly, the sun's light off, a cool lantern round the child. Under a daylight shaft (no ceiling) the day comes
## back. Readable in a headset too (VR: no pitch black). How far underground a head is, in the caves, is measured from
## the roof's meadow (WorldService.sky_height), so every cavern under the roof is underground however high its ceiling.

const BASE := {"sun": 1.0, "ambient": 0.65, "fog_color": Color(0.6, 0.78, 0.98), "fog_begin": 90.0, "fog_end": 128.0,
	"ambient_color": Color(0.9, 0.95, 1.0), "sky_share": 0.6}


func _mood(u: float, w: float = 0.0, base: Dictionary = BASE) -> Dictionary:
	return GlowRules.mood(AmbienceRules.mood(u, w, base), base, u, w, GlowRules.CAVE_MOOD)


func test_in_the_caves_the_dark_is_soft_blue_violet_never_black() -> void:
	var m := _mood(1.0)
	var fog: Color = m.fog_color
	assert_gt(fog.b, fog.r)
	assert_gt(fog.b, fog.g)
	assert_gt(fog.v, 0.25, "a soft violet, not black")
	assert_gte(m.ambient, 0.35, "the caves stay readable (phones, VR)")
	var amb: Color = m.ambient_color
	assert_gt(amb.b, amb.g, "blue-violet ambient light")
	assert_lt(m.sky_share, 0.2, "little of the sky's light comes down here")
	assert_lt(m.sun, 0.1, "no sunlight through the rock")
	assert_gt(m.fog_end, m.fog_begin)
	assert_gte(m.fog_end, 48.0, "far halls fade softly, never a wall of fog close by")
	assert_gt(m.lantern, 0.5, "the child's lantern")
	var lantern: Color = m.lantern_color
	assert_gt(lantern.b, 0.8, "a cool lantern (glow-light, not fire)")


## Night outside changes nothing in the caves: the glow is their own.
func test_the_caves_are_the_same_by_day_and_by_night() -> void:
	var night := BASE.duplicate()
	night.ambient = 0.2
	night.sun = 0.1
	night.fog_color = Color(0.05, 0.05, 0.1)
	var by_day := _mood(1.0)
	var by_night := _mood(1.0, 0.0, night)
	assert_almost_eq(by_day.ambient, by_night.ambient, 0.001)
	assert_true((by_day.fog_color as Color).is_equal_approx(by_night.fog_color), "the same violet fog")


## Under a shaft (no ceiling) it is the open air again: the base mood untouched.
func test_under_a_shaft_the_day_comes_back() -> void:
	var m := _mood(0.0)
	assert_eq(m.ambient, BASE.ambient)
	assert_eq(m.fog_color, BASE.fog_color)
	assert_eq(m.ambient_color, BASE.ambient_color)
	assert_eq(m.sky_share, BASE.sky_share)
	assert_almost_eq(m.lantern, 0.0, 0.001)


## Under water in a cave lake the view still turns blue and close (the water's own mood wins).
func test_underwater_in_a_lake() -> void:
	var m := _mood(1.0, 1.0)
	assert_almost_eq(float(m.fog_end), AmbienceRules.WATER_FOG_END, 0.01)
