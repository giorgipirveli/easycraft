extends GutTest
## Cosmos: Titan's sights (spec §21b.2: "its facts to discover"). SpaceSights watches this game's player: reaching the
## methane sea (its beach or swimming in it), a methane lake, a dune or the icy mountains' top says its real fact once per
## world, with a sparkle. MY MAP shows the sea, the dunes and the mountains from the landing, a lake where one was found.
## Titan has no vents: no geysers.

var shape: SpaceShape
var sights: SpaceSights
var at := Vector3.INF
var said: Array[String] = []
var marks: Array[Dictionary] = []


func before_each() -> void:
	shape = SpaceShape.new(12345, SpaceShape.TITAN)
	said.clear()
	marks.clear()
	at = Vector3.INF
	sights = SpaceSights.new()
	sights.auto_tick = false
	sights.shape = shape
	sights.sights = UniverseRegistry.sights(SpaceRules.TITAN)
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


func test_the_big_sights_are_on_the_map_from_the_landing() -> void:
	var ids: Array = marks.map(func(m: Dictionary) -> String: return str(m.id))
	assert_eq(ids, ["sight_sea", "sight_dunes", "sight_mountain"])
	assert_eq(marks[0].name, "Methane Sea")
	assert_eq(marks[1].name, "Dark Dunes")
	assert_eq(marks[2].name, "Icy Mountains")


func test_the_seas_beach_says_its_fact() -> void:
	var beach := shape.titan.sea_beach_toward(shape.spawn_column())
	_stand(beach.x, beach.y, 30.0)
	sights.tick()
	assert_true(said.is_empty(), "flying high over it finds nothing yet")
	_stand(beach.x, beach.y)
	sights.tick()
	assert_eq(said.size(), 1)
	assert_string_contains(said[0], "north pole")
	assert_true(sights.found.has("sight:sea"))
	_stand(beach.x, beach.y - 5)
	sights.tick()
	assert_eq(said.size(), 1, "once per world")


func test_a_lake_the_dunes_and_the_mountains() -> void:
	var lake := Vector3i.ZERO
	for cz in range(-6, 6):
		for cx in range(-6, 6):
			if lake.z == 0:
				lake = shape.titan.lake_in_cell(Vector2i(cx, cz))
	_stand(lake.x, lake.y)   # swimming in it (its top is the methane's)
	sights.tick()
	assert_eq(said.size(), 1)
	assert_string_contains(said[0], "rain")
	assert_eq(marks[-1].id, "sight_lake", "a lake goes on the map where it was found")
	var dune := shape.titan.first_dune_south_of(shape.spawn_column())
	_stand(dune.x, dune.y)
	sights.tick()
	var pk := shape.titan.peak_centre()
	_stand(pk.x, pk.y)
	sights.tick()
	assert_eq(said.size(), 3)
	assert_string_contains(said[1], "haze")
	assert_string_contains(said[2], "3.3 km")


func test_titan_has_no_geysers() -> void:
	assert_false(shape.has_vents(), "no vents on Titan")
	assert_eq(shape.vents_near(0, 0, 500.0).size(), 0)
