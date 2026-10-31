extends GutTest
## Cosmos: Mars's sights (spec §21b.2: "its facts to discover"). SpaceSights watches this game's player: walking onto
## the volcano's summit, the canyon's floor, an ice cap or a dry river bed says its real fact once per world (kept in
## the world's secrets, so a saved world remembers), with a sparkle. MY MAP shows the big sights from the landing (the
## giant volcano, the great canyon, the two ice caps) and a river bed where one was found. Flying high over a sight
## finds nothing: it is walked on.

var shape: SpaceShape
var sights: SpaceSights
var at := Vector3.INF
var said: Array[String] = []
var marks: Array[Dictionary] = []


func before_each() -> void:
	shape = SpaceShape.new(12345, SpaceShape.MARS)
	said.clear()
	marks.clear()
	at = Vector3.INF
	sights = _make({})


func after_each() -> void:
	UniverseRegistry.reset()


func _make(found: Dictionary) -> SpaceSights:
	var s := SpaceSights.new()
	s.auto_tick = false
	s.shape = shape
	s.sights = UniverseRegistry.sights(SpaceRules.MARS)
	s.found = found
	s.player_position = func() -> Vector3: return at
	s.toast = func(text: String) -> void: said.append(text)
	s.mark = func(entry: Dictionary) -> void: marks.append(entry)
	add_child_autofree(s)
	s.setup()
	return s


func _stand(x: int, z: int, above: float = 0.0) -> void:
	at = Vector3(x + 0.5, shape.height_at(x, z) + above, z + 0.5)


func test_the_big_sights_are_on_the_map_from_the_landing() -> void:
	var ids: Array = marks.map(func(m: Dictionary) -> String: return str(m.id))
	assert_eq(ids, ["sight_volcano", "sight_canyon", "sight_north_cap", "sight_south_cap", "sight_colony"],
		"spec §21c: and the colony (its parts are not marked by themselves)")
	for m: Dictionary in marks:
		assert_ne(str(m.name), "")
		assert_true(m.pos is Vector3)
	assert_eq(marks[0].name, "Giant Volcano")


func test_the_volcanos_summit_says_its_fact_once() -> void:
	var sp := shape.spawn_column()
	_stand(sp.x, sp.y)
	sights.tick()
	assert_true(said.is_empty(), "nothing on the landing pad")
	var vc := shape.mars.volcano_centre()
	_stand(vc.x, vc.y)
	sights.tick()
	assert_eq(said.size(), 1)
	assert_string_contains(said[0], "Olympus Mons")
	assert_true(sights.found.has("sight:volcano"), "kept with the world's secrets")
	sights.tick()
	_stand(vc.x + 2, vc.y + 1)
	sights.tick()
	assert_eq(said.size(), 1, "once")


func test_flying_high_over_the_canyon_finds_nothing_its_floor_does() -> void:
	var cz := roundi(shape.mars.canyon_z(0))
	_stand(0, cz, 40.0)
	sights.tick()
	assert_true(said.is_empty(), "flying over")
	_stand(0, cz)
	sights.tick()
	assert_eq(said.size(), 1)
	assert_string_contains(said[0], "Valles Marineris")


func test_the_ice_caps_and_a_dry_river_bed() -> void:
	_stand(10, shape.mars.north_edge() - 60)
	sights.tick()
	_stand(-10, shape.mars.south_edge() + 60)
	sights.tick()
	assert_eq(said.size(), 2)
	assert_string_contains(said[0], "frozen water and frozen carbon dioxide")
	assert_string_contains(said[1], "dry ice")
	var river := Vector2i(999999, 0)
	for i in 3000:
		var x := (i * 13) % 1000 - 500
		var z := (i * 7) % 600 - 400
		if shape.mars_kind(x, z) == MarsTerrain.VALLEY:
			river = Vector2i(x, z)
			break
	var before := marks.size()
	_stand(river.x, river.y)
	sights.tick()
	assert_eq(said.size(), 3)
	assert_string_contains(said[2], "water")
	assert_eq(marks.size(), before + 1, "the river bed goes on the map where it was found")
	assert_eq(marks[-1].id, "sight_river")


func test_a_saved_world_remembers_its_sights() -> void:
	var vc := shape.mars.volcano_centre()
	_stand(vc.x, vc.y)
	sights.tick()
	var again := _make(sights.found)
	said.clear()
	again.tick()
	assert_true(said.is_empty(), "found before: no second banner")
	var state := SecretState.new()
	state.found = sights.found
	assert_eq(state.counts(), Vector2i.ZERO, "sights never count as the Secret Book's secrets")
	assert_true(SecretState.from_save(state.to_save()).found.has("sight:volcano"), "saved with the world")
