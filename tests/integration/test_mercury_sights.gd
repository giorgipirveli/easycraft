extends GutTest
## Cosmos: Mercury's sights (spec §21b.2: "its facts to discover"). SpaceSights watches this game's player: standing by the
## explorers' thermometer (a few steps from the pad: the burning days and the freezing nights), on a long cliff's face, on
## a big crater's floor or peak, or on the ice of a shadowed crater near a pole says its real fact once per world, with a
## sparkle. MY MAP shows all four from the landing. Mercury has no vents: no geysers.

var shape: SpaceShape
var sights: SpaceSights
var at := Vector3.INF
var said: Array[String] = []
var marks: Array[Dictionary] = []


func before_each() -> void:
	shape = SpaceShape.new(12345, SpaceShape.MERCURY)
	said.clear()
	marks.clear()
	at = Vector3.INF
	sights = SpaceSights.new()
	sights.auto_tick = false
	sights.shape = shape
	sights.sights = UniverseRegistry.sights(SpaceRules.MERCURY)
	sights.found = {}
	sights.player_position = func() -> Vector3: return at
	sights.toast = func(text: String) -> void: said.append(text)
	sights.mark = func(entry: Dictionary) -> void: marks.append(entry)
	add_child_autofree(sights)
	sights.setup()


func after_each() -> void:
	UniverseRegistry.reset()


func _stand(x: int, z: int, above: float = 0.0) -> void:
	at = Vector3(x + 0.5, shape.height_at(x, z) + above, z + 0.5)


func test_the_four_sights_are_on_the_map_from_the_landing() -> void:
	var ids: Array = marks.map(func(m: Dictionary) -> String: return str(m.id))
	assert_eq(ids, ["sight_thermometer", "sight_scarp", "sight_crater", "sight_ice"])
	assert_eq(marks[0].name, "Thermometer")
	assert_eq(marks[1].name, "Long Cliff")
	assert_eq(marks[2].name, "Big Crater")
	assert_eq(marks[3].name, "Ice Crater")


func test_the_thermometer_says_the_burning_days_and_freezing_nights() -> void:
	var t := shape.thermometer_column()
	_stand(t.x + 2, t.y, 30.0)
	sights.tick()
	assert_true(said.is_empty(), "flying high over it finds nothing yet")
	_stand(t.x + 2, t.y)
	sights.tick()
	assert_eq(said.size(), 1)
	assert_string_contains(said[0], "430 °C")
	assert_string_contains(said[0], "−180 °C")
	assert_true(sights.found.has("sight:thermometer"))
	_stand(t.x, t.y + 2)
	sights.tick()
	assert_eq(said.size(), 1, "once per world")


func test_a_long_cliff_a_big_crater_and_the_ice() -> void:
	var face := shape.mercury.great_face_toward(shape.spawn_column())
	_stand(face.x, face.y)
	sights.tick()
	var c := shape.mercury.nearest_crater(shape.spawn_column())
	_stand(c.x, c.y)
	sights.tick()
	var ic := shape.mercury.ice_centre()
	_stand(ic.x, ic.y)
	sights.tick()
	assert_eq(said.size(), 3)
	assert_string_contains(said[0], "shrank")
	assert_string_contains(said[1], "artists")
	assert_string_contains(said[2], "poles")


func test_mercury_has_no_geysers() -> void:
	assert_false(shape.has_vents(), "no vents on Mercury")
	assert_eq(shape.vents_near(0, 0, 500.0).size(), 0)
