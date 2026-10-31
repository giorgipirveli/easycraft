extends GutTest
## Colonies under domes (owner #77, spec §21c.2: "each part says a real fact the first time a child walks in"). SpaceSights
## watches this game's player on the Moon and Mars: walking into the Great Dome, the greenhouse, the airlock, a smaller
## dome or an outside part says its fact once per world (kept in the world's secrets, so a saved world remembers). MY MAP
## shows the colony from the landing (one mark, its name); its parts are not marked by themselves. The explorer's
## checklist lists the colony as one place (PlanetGuideRules), found by walking into the Great Dome.

var shape: SpaceShape
var sights: SpaceSights
var at := Vector3.INF
var said: Array[String] = []
var marks: Array[Dictionary] = []
var found := {}


func after_each() -> void:
	UniverseRegistry.reset()


func _make(planet: StringName, u: int) -> void:
	shape = SpaceShape.new(12345, planet)
	said.clear()
	marks.clear()
	found = {}
	at = Vector3.INF
	sights = SpaceSights.new()
	sights.auto_tick = false
	sights.shape = shape
	sights.sights = UniverseRegistry.sights(u)
	sights.found = found
	sights.player_position = func() -> Vector3: return at
	sights.toast = func(text: String) -> void: said.append(text)
	sights.mark = func(entry: Dictionary) -> void: marks.append(entry)
	add_child_autofree(sights)
	sights.setup()


func _stand(p: Vector2i, above: float = 0.0) -> void:
	at = Vector3(p.x + 0.5, shape.height_at(p.x, p.y) + above, p.y + 0.5)


func test_the_moon_colony_is_on_my_map_from_the_landing() -> void:
	_make(SpaceShape.MOON, SpaceRules.MOON)
	assert_eq(marks.size(), 1, "one mark: the colony")
	assert_eq(marks[0].id, "sight_colony")
	assert_eq(marks[0].name, "Moon Colony")


func test_every_part_says_its_fact_once_on_both_worlds() -> void:
	for pair: Array in [[SpaceShape.MOON, SpaceRules.MOON], [SpaceShape.MARS, SpaceRules.MARS]]:
		_make(pair[0], pair[1])
		var own := ColonyRules.sights(pair[0])
		var before := marks.size()
		for part: StringName in ColonyRules.PARTS:
			said.clear()
			_stand(shape.colony.part_centre(part))
			sights.tick()
			assert_eq(said, [str(own[part].words)] as Array[String], "%s: %s" % [pair[0], part])
			assert_true(found.has("sight:" + String(part)), "kept in the world's secrets")
			said.clear()
			sights.tick()
			assert_true(said.is_empty(), "once per world: %s" % part)
		assert_eq(marks.size(), before, "the parts are not marked by themselves on MY MAP")


func test_a_saved_world_remembers_and_flying_over_finds_nothing() -> void:
	_make(SpaceShape.MARS, SpaceRules.MARS)
	_stand(shape.colony.part_centre(ColonyRules.LAB), 20.0)
	sights.tick()
	assert_true(said.is_empty(), "flying high over the lab")
	found["sight:" + String(ColonyRules.LAB)] = true   # found in an earlier visit (the world's secrets, saved)
	_stand(shape.colony.part_centre(ColonyRules.LAB))
	sights.tick()
	assert_true(said.is_empty(), "a saved world remembers")
	var tunnel := shape.colony.world(0, -11)
	_stand(tunnel)
	sights.tick()
	assert_true(said.is_empty(), "a tunnel says nothing")


## The explorer's checklist (owner #88): the colony is one place; the Great Dome ticks it.
func test_the_checklist_lists_the_colony_once() -> void:
	_make(SpaceShape.MARS, SpaceRules.MARS)
	var own := UniverseRegistry.sights(SpaceRules.MARS)
	var list := PlanetGuideRules.checklist(shape.sights(), own, found, Vector3(shape.colony.centre.x, 0, shape.colony.centre.y))
	var ids := list.map(func(e: Dictionary) -> StringName: return e.id)
	assert_eq(ids.count(ColonyRules.DOME), 1)
	assert_eq(list.size(), 5, "Mars's four big sights and its colony")
	assert_eq(list[0].id, ColonyRules.DOME, "the colony is the nearest to its own middle")
	assert_eq(list[0].name, "Mars Colony")
	_stand(shape.colony.part_centre(ColonyRules.DOME))
	sights.tick()
	list = PlanetGuideRules.checklist(shape.sights(), own, found, Vector3.ZERO)
	assert_true(list.filter(func(e: Dictionary) -> bool: return e.id == ColonyRules.DOME)[0].found)
	_make(SpaceShape.MOON, SpaceRules.MOON)
	var moon := PlanetGuideRules.checklist(shape.sights(), UniverseRegistry.sights(SpaceRules.MOON), {}, Vector3.ZERO)
	assert_eq(moon.size(), 1)
	assert_string_contains(PlanetGuideRules.intro("The Moon", moon), "Explore 1 place:", "one place, not '1 places'")
