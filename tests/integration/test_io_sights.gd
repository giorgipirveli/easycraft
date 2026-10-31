extends GutTest
## Cosmos: Io's sights and its volcanoes' plumes (spec §21b.2: "its facts to discover"). SpaceSights watches this game's
## player: reaching the lava lake (its rim first, before the hot lava), the mountain's top, a volcano's cone or a red
## sulphur ring says its real fact once per world, with a sparkle. MY MAP shows the lava lake, the mountain and the
## volcano nearest the pad from the landing, a red ring where one was found. SpaceGeysers makes the volcanoes near the
## player erupt now and then (each vent on its own beat): puffs of yellow sulphur rising from the vent.

var shape: SpaceShape
var sights: SpaceSights
var at := Vector3.INF
var said: Array[String] = []
var marks: Array[Dictionary] = []


func before_each() -> void:
	shape = SpaceShape.new(12345, SpaceShape.IO)
	said.clear()
	marks.clear()
	at = Vector3.INF
	sights = SpaceSights.new()
	sights.auto_tick = false
	sights.shape = shape
	sights.sights = UniverseRegistry.sights(SpaceRules.IO)
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
	assert_eq(ids, ["sight_lake", "sight_mountain", "sight_plume"])
	assert_eq(marks[0].name, "Lava Lake")
	assert_eq(marks[1].name, "Tall Mountain")
	assert_eq(marks[2].name, "Volcano")


func test_the_lava_lakes_rim_says_its_fact_before_the_hot_lava() -> void:
	var lc := shape.io.lake_centre()
	_stand(lc.x + IoTerrain.LAKE_R + 1, lc.y, 30.0)
	sights.tick()
	assert_true(said.is_empty(), "flying high over it finds nothing yet")
	_stand(lc.x + IoTerrain.LAKE_R + 1, lc.y)
	sights.tick()
	assert_eq(said.size(), 1)
	assert_string_contains(said[0], "200 km")
	assert_true(sights.found.has("sight:lake"))


func test_the_mountain_a_volcano_and_a_red_ring() -> void:
	var pk := shape.io.peak_centre()
	_stand(pk.x, pk.y)
	sights.tick()
	var v := shape.io.nearest_vent(shape.spawn_column())
	_stand(v.x + 3, v.y)
	sights.tick()
	assert_eq(said.size(), 2)
	assert_string_contains(said[0], "Mount Everest")
	assert_string_contains(said[1], "400 km")
	var before := marks.size()
	var ring := v + Vector2i(roundi((IoTerrain.RING_IN + IoTerrain.RING_OUT) / 2.0), 0)
	_stand(ring.x, ring.y)
	sights.tick()
	assert_eq(said.size(), 3)
	assert_string_contains(said[2], "red sulphur")
	assert_eq(marks.size(), before + 1, "the ring goes on the map where it was found")
	assert_eq(marks[-1].id, "sight_ring")


# --- The volcanoes erupt ---

func test_the_volcanoes_near_the_player_puff_sulphur_and_far_ones_rest() -> void:
	var g := SpaceGeysers.new()
	g.auto_tick = false
	g.shape = shape
	var v := shape.io.nearest_vent(shape.spawn_column())
	at = Vector3(v.x + 5.5, shape.height_at(v.x, v.y), v.y + 0.5)
	g.player_position = func() -> Vector3: return at   # a member: the lambda sees it move
	var puffs: Array[Vector3] = []
	g.plume = func(p: Vector3) -> void: puffs.append(p)
	add_child_autofree(g)
	for i in 120:
		g.tick(0.1)
	assert_gt(puffs.size(), 3, "it blew while the child was near")
	assert_true(puffs.any(func(p: Vector3) -> bool: return floori(p.x) == v.x and floori(p.z) == v.y), "from the vent")
	at = Vector3(v.x + 900.5, 60.0, v.y + 900.5)
	for i in 12:   # it looks for the vents near the child once a second
		g.tick(0.1)
	puffs.clear()
	for i in 120:
		g.tick(0.1)
	for p in puffs:
		assert_lt(Vector2(p.x - at.x, p.z - at.z).length(), SpaceGeysers.RANGE + 1.0, "only volcanoes near the child")


func test_an_io_plume_is_yellow_sulphur_and_a_europa_plume_white_vapour() -> void:
	var io := SpaceGeysers.plume_color(shape)
	assert_gt(io.r, io.b + 0.3, "yellow sulphur (%s)" % io)
	var europa := SpaceGeysers.plume_color(SpaceShape.new(12345, SpaceShape.EUROPA))
	assert_eq(europa, SpaceGeysers.VAPOUR, "Europa's stays white vapour")
