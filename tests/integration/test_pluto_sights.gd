extends GutTest
## Cosmos: Pluto's sights (spec §21b.2: "facts at sights"). SpaceSights watches this game's player: standing at the
## Charon Lookout by the pad (Pluto and Charon always face each other), on the heart's plain (frozen nitrogen churning in
## cells), on a floating hill (water ice floats on nitrogen ice), on the ice mountains' snowy top (named after Tenzing
## Norgay and Edmund Hillary), in the red-brown lands (tholins) or on the heart's bright side (nitrogen frost carried
## through the air) says its real fact once per world, with a sparkle. MY MAP shows all six from the landing; the planet
## guide's checklist lists them. Pluto has no vents: no geysers.

var shape: SpaceShape
var sights: SpaceSights
var at := Vector3.INF
var said: Array[String] = []
var marks: Array[Dictionary] = []


func before_each() -> void:
	shape = SpaceShape.new(12345, SpaceShape.PLUTO)
	said.clear()
	marks.clear()
	at = Vector3.INF
	sights = SpaceSights.new()
	sights.auto_tick = false
	sights.shape = shape
	sights.sights = UniverseRegistry.sights(SpaceRules.PLUTO)
	sights.found = {}
	sights.player_position = func() -> Vector3: return at
	sights.toast = func(text: String) -> void: said.append(text)
	sights.mark = func(entry: Dictionary) -> void: marks.append(entry)
	add_child_autofree(sights)
	sights.setup()


func after_each() -> void:
	UniverseRegistry.reset()


func _stand(p: Vector2i, above: float = 0.0) -> void:
	at = Vector3(p.x + 0.5, shape.height_at(p.x, p.y) + above, p.y + 0.5)


func test_the_six_sights_are_on_the_map_from_the_landing() -> void:
	var ids: Array = marks.map(func(m: Dictionary) -> String: return str(m.id))
	assert_eq(ids, ["sight_lookout", "sight_heart", "sight_hills", "sight_mountains", "sight_dark", "sight_bright"])
	assert_eq(marks[0].name, "Charon Lookout")
	assert_eq(marks[1].name, "Heart Plain")
	assert_eq(marks[2].name, "Floating Hills")
	assert_eq(marks[3].name, "Ice Mountains")
	assert_eq(marks[4].name, "Red-Brown Lands")
	assert_eq(marks[5].name, "Bright Side")


func test_the_charon_lookout_by_the_pad_says_they_face_each_other() -> void:
	var lk := shape.pluto.lookout
	_stand(lk, 30.0)
	sights.tick()
	assert_true(said.is_empty(), "floating high over it finds nothing yet")
	_stand(lk + Vector2i(2, 1))
	sights.tick()
	assert_eq(said.size(), 1)
	assert_string_contains(said[0], "face each other")
	assert_true(sights.found.has("sight:lookout"))
	sights.tick()
	assert_eq(said.size(), 1, "once per world")


func test_the_heart_the_hills_the_mountains_the_lands_and_the_bright_side() -> void:
	var p := shape.pluto
	var sp := shape.spawn_column()
	for spot: Vector2i in [p.plain_shore_toward(sp), p.nearest_hill(sp), p.peak_centre(), p.first_dark_west_of(sp),
			p.bright_centre()]:
		_stand(spot)
		sights.tick()
	assert_eq(said.size(), 5)
	assert_string_contains(said[0], "frozen nitrogen")
	assert_string_contains(said[1], "iceberg")
	assert_string_contains(said[2], "Everest")
	assert_string_contains(said[3], "tholins")
	assert_string_contains(said[4], "frost")


func test_the_planet_guides_checklist_lists_them() -> void:
	var list := PlanetGuideRules.checklist(shape.sights(), UniverseRegistry.sights(SpaceRules.PLUTO), {}, Vector3.ZERO)
	assert_eq(list.size(), 6, "six places to explore")


func test_pluto_has_no_geysers() -> void:
	assert_false(shape.has_vents(), "no vents on Pluto")
	assert_eq(shape.vents_near(0, 0, 500.0).size(), 0)
