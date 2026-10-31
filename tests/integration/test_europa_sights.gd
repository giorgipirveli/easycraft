extends GutTest
## Cosmos: Europa's sights and its water plumes (spec §21b.2: "its facts to discover"). SpaceSights watches this game's
## player: reaching the ocean at the bottom of the well, standing on the ice cliffs, a water plume's mound or a reddish
## crack says its real fact once per world, with a sparkle. MY MAP shows the ocean, the cliffs and the plume nearest the
## pad from the landing, a crack where one was found. SpaceGeysers makes the plumes near the player erupt now and then
## (each vent on its own beat): a column of white vapour rising from the vent.

var shape: SpaceShape
var sights: SpaceSights
var at := Vector3.INF
var said: Array[String] = []
var marks: Array[Dictionary] = []


func before_each() -> void:
	shape = SpaceShape.new(12345, SpaceShape.EUROPA)
	said.clear()
	marks.clear()
	at = Vector3.INF
	sights = SpaceSights.new()
	sights.auto_tick = false
	sights.shape = shape
	sights.sights = UniverseRegistry.sights(SpaceRules.EUROPA)
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
	assert_eq(ids, ["sight_ocean", "sight_cliffs", "sight_plume"])
	assert_eq(marks[0].name, "Ocean Under the Ice")
	assert_eq(marks[1].name, "Ice Cliffs")
	assert_eq(marks[2].name, "Water Plume")


func test_swimming_in_the_ocean_at_the_bottom_of_the_well_says_its_fact() -> void:
	var wc := shape.europa.well_centre()
	at = Vector3(wc.x + 0.5, shape.europa.well_top() + 2.0, wc.y + 0.5)
	sights.tick()
	assert_true(said.is_empty(), "looking down from the rim finds nothing yet")
	at = Vector3(wc.x + 0.5, EuropaTerrain.OCEAN_TOP - 0.5, wc.y + 0.5)
	sights.tick()
	assert_eq(said.size(), 1)
	assert_string_contains(said[0], "twice as much water")
	assert_true(sights.found.has("sight:ocean"))


func test_the_cliffs_a_plume_and_a_crack() -> void:
	var mc := shape.europa.mesa_centre()
	_stand(mc.x, mc.y)
	sights.tick()
	var v := shape.europa.nearest_vent(shape.spawn_column())
	_stand(v.x + 2, v.y)
	sights.tick()
	assert_eq(said.size(), 2)
	assert_string_contains(said[0], "15 to 25 km")
	assert_string_contains(said[1], "100 km")
	var crack := Vector2i(999999, 0)
	for i in 5000:
		var x := (i * 19) % 1000 - 500
		var z := (i * 23) % 1000 - 500
		if shape.europa_kind(x, z) == EuropaTerrain.LINEA and Vector2(Vector2i(x, z) - shape.spawn_column()).length() > 20.0:
			crack = Vector2i(x, z)
			break
	var before := marks.size()
	_stand(crack.x, crack.y)
	sights.tick()
	assert_eq(said.size(), 3)
	assert_string_contains(said[2], "salts and sulphur")
	assert_eq(marks.size(), before + 1, "the crack goes on the map where it was found")
	assert_eq(marks[-1].id, "sight_linea")


# --- The water plumes erupt ---

func test_each_vent_erupts_on_its_own_beat() -> void:
	var vents := shape.europa.vents_near(0, 0, 600)
	assert_gt(vents.size(), 3)
	var on := {}
	for v: Vector2i in vents:
		var share := 0
		for i in 400:
			if SpaceGeysers.erupting(i * 0.1, v):
				share += 1
		assert_between(share, 60, 200, "erupting now and then, not always (%d of 400)" % share)
		on[v] = SpaceGeysers.erupting(3.0, v)
	assert_eq(on.values().count(true) > 0 and on.values().count(false) > 0, true, "not all at once")


func test_the_plumes_near_the_player_blow_and_far_ones_rest() -> void:
	var g := SpaceGeysers.new()
	g.auto_tick = false
	g.shape = shape
	var v := shape.europa.nearest_vent(shape.spawn_column())
	at = Vector3(v.x + 5.5, shape.height_at(v.x, v.y), v.y + 0.5)
	g.player_position = func() -> Vector3: return at   # a member: the lambda sees it move
	var puffs: Array[Vector3] = []
	g.plume = func(p: Vector3) -> void: puffs.append(p)
	add_child_autofree(g)
	for i in 120:
		g.tick(0.1)
	assert_gt(puffs.size(), 3, "it blew while the child was near")
	for p in puffs:
		assert_lt(Vector2(p.x - at.x, p.z - at.z).length(), SpaceGeysers.RANGE + 1.0)
	assert_true(puffs.any(func(p: Vector3) -> bool: return floori(p.x) == v.x and floori(p.z) == v.y), "from the vent")
	at = Vector3(v.x + 900.5, 60.0, v.y + 900.5)
	for i in 12:   # it looks for the vents near the child once a second
		g.tick(0.1)
	puffs.clear()
	for i in 120:
		g.tick(0.1)
	for p in puffs:
		assert_lt(Vector2(p.x - at.x, p.z - at.z).length(), SpaceGeysers.RANGE + 1.0, "only plumes near the child")
