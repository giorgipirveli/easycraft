extends GutTest
## Cosmos: Saturn's rings' sights (spec §21b.2: "facts at sights"). SpaceSights watches this game's player: standing at
## the Saturn scope on the landing chunk's north rim (760 Earths fit inside Saturn), at the Ring Station's door (sunlight
## takes 80 minutes to get here), by the beacon at the Cassini Division (a gap 4,700 km wide, seen in 1675), by the C
## ring's beacon (darker, dustier chunks), by the F ring's beacon (its two shepherd moons) or on top of Pan (a walnut-
## shaped little moon sweeping the Encke Gap) says its real fact once per world, with a sparkle. MY MAP shows all six from
## the landing; the planet guide's checklist lists them. The rings have no vents: no geysers.

var shape: SpaceShape
var sights: SpaceSights
var at := Vector3.INF
var said: Array[String] = []
var marks: Array[Dictionary] = []


func before_each() -> void:
	shape = SpaceShape.new(12345, SpaceShape.RINGS)
	said.clear()
	marks.clear()
	at = Vector3.INF
	sights = SpaceSights.new()
	sights.auto_tick = false
	sights.shape = shape
	sights.sights = UniverseRegistry.sights(SpaceRules.RINGS)
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


func _spot(id: StringName) -> Vector2i:
	for e: Array in shape.rings.sight_spots():
		if e[0] == id:
			return e[1]
	return RingsTerrain.NONE


func test_the_six_sights_are_on_the_map_from_the_landing() -> void:
	var ids: Array = marks.map(func(m: Dictionary) -> String: return str(m.id))
	assert_eq(ids, ["sight_scope", "sight_station", "sight_cassini", "sight_c_ring", "sight_f_ring", "sight_pan"])
	assert_eq(marks[0].name, "Saturn Scope")
	assert_eq(marks[1].name, "Ring Station")
	assert_eq(marks[2].name, "Cassini Division")
	assert_eq(marks[3].name, "C Ring")
	assert_eq(marks[4].name, "F Ring")
	assert_eq(marks[5].name, "Pan")
	for m: Dictionary in marks:
		var p: Vector3 = m.pos
		assert_gt(p.y, RingsTerrain.LIFT_Y, "%s: on a chunk (or Pan), over the void line" % m.id)


func test_the_saturn_scope_by_the_pad_says_how_big_saturn_is() -> void:
	var s := _spot(&"scope")
	_stand(s, 30.0)
	sights.tick()
	assert_true(said.is_empty(), "floating high over it finds nothing yet")
	_stand(s)
	sights.tick()
	assert_eq(said.size(), 1)
	assert_string_contains(said[0], "760 Earths")
	assert_true(sights.found.has("sight:scope"))
	sights.tick()
	assert_eq(said.size(), 1, "once per world")


func test_the_station_the_gaps_the_rings_and_pan() -> void:
	for id: StringName in [&"station", &"cassini", &"c_ring", &"f_ring", &"pan"]:
		_stand(_spot(id))
		sights.tick()
	assert_eq(said.size(), 5)
	assert_string_contains(said[0], "80 minutes")
	assert_string_contains(said[1], "Cassini Division")
	assert_string_contains(said[2], "dustier")
	assert_string_contains(said[3], "Prometheus and Pandora")
	assert_string_contains(said[4], "walnut")


func test_the_planet_guides_checklist_lists_them() -> void:
	var list := PlanetGuideRules.checklist(shape.sights(), UniverseRegistry.sights(SpaceRules.RINGS), {}, Vector3.ZERO)
	assert_eq(list.size(), 6, "six places to explore")


func test_the_rings_have_no_geysers() -> void:
	assert_false(shape.has_vents(), "no vents in the rings")
	assert_eq(shape.vents_near(0, 0, 500.0).size(), 0)
