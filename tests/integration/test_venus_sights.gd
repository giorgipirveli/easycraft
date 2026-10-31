extends GutTest
## Cosmos: Venus's cloud city's sights (spec §21b.2: "facts at sights"). SpaceSights watches this game's player: standing
## at the cloud scope by the pad (the acid clouds far below), by the airship dock's mooring mast (the air we breathe
## floats on Venus), round the sky garden's pond (50 km up the air presses like home's), in the cloud homes' square (a
## day longer than a year) or at the west lookout's telescope (the Sun rises in the west) says its real fact once per
## world, with a sparkle. MY MAP shows all five from the landing; the planet guide's checklist lists them. Venus has no
## vents: no geysers.

var shape: SpaceShape
var sights: SpaceSights
var at := Vector3.INF
var said: Array[String] = []
var marks: Array[Dictionary] = []


func before_each() -> void:
	shape = SpaceShape.new(12345, SpaceShape.VENUS)
	said.clear()
	marks.clear()
	at = Vector3.INF
	sights = SpaceSights.new()
	sights.auto_tick = false
	sights.shape = shape
	sights.sights = UniverseRegistry.sights(SpaceRules.VENUS)
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
	for e: Array in shape.venus.sight_spots():
		if e[0] == id:
			return e[1]
	return VenusTerrain.NONE


func test_the_five_sights_are_on_the_map_from_the_landing() -> void:
	var ids: Array = marks.map(func(m: Dictionary) -> String: return str(m.id))
	assert_eq(ids, ["sight_scope", "sight_dock", "sight_garden", "sight_homes", "sight_lookout"])
	assert_eq(marks[0].name, "Cloud Scope")
	assert_eq(marks[1].name, "Airship Dock")
	assert_eq(marks[2].name, "Sky Garden")
	assert_eq(marks[3].name, "Cloud Homes")
	assert_eq(marks[4].name, "West Lookout")


func test_the_cloud_scope_by_the_pad_says_what_the_clouds_are() -> void:
	var s := _spot(&"scope")
	_stand(s, 30.0)
	sights.tick()
	assert_true(said.is_empty(), "flying high over it finds nothing yet")
	_stand(s)
	sights.tick()
	assert_eq(said.size(), 1)
	assert_string_contains(said[0], "sulfuric acid")
	assert_true(sights.found.has("sight:scope"))
	sights.tick()
	assert_eq(said.size(), 1, "once per world")


func test_the_dock_the_garden_the_homes_and_the_west_lookout() -> void:
	for id: StringName in [&"dock", &"garden", &"homes", &"lookout"]:
		_stand(_spot(id))
		sights.tick()
	assert_eq(said.size(), 4)
	assert_string_contains(said[0], "air we breathe")
	assert_string_contains(said[1], "50 km")
	assert_string_contains(said[2], "243")
	assert_string_contains(said[3], "west")


func test_the_planet_guides_checklist_lists_them() -> void:
	var list := PlanetGuideRules.checklist(shape.sights(), UniverseRegistry.sights(SpaceRules.VENUS), {}, Vector3.ZERO)
	assert_eq(list.size(), 5, "five places to explore")


func test_venus_has_no_geysers() -> void:
	assert_false(shape.has_vents(), "no vents on Venus")
	assert_eq(shape.vents_near(0, 0, 500.0).size(), 0)
