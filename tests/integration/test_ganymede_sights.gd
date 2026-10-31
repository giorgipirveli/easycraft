extends GutTest
## Cosmos: Ganymede's sights (spec §21b.2: "facts at sights"). SpaceSights watches this game's player: standing at the
## Jupiter Lookout by the pad (Ganymede always shows Jupiter the same face), on the grooved terrain (its ridges, some
## 700 m high, formed as the icy crust stretched), on the dark terrain (about 4 billion years old), at the bright ray
## crater (fresh ice thrown out in rays), on the polar frost (the magnetic field steers Jupiter's particles there), at the
## Aurora Watch (the magnetic field makes auroras) or at the ocean drill (the salty ocean about 150 km down) says its real
## fact once per world, with a sparkle. MY MAP shows all seven from the landing.

var shape: SpaceShape
var sights: SpaceSights
var at := Vector3.INF
var said: Array[String] = []
var marks: Array[Dictionary] = []


func before_each() -> void:
	shape = SpaceShape.new(12345, SpaceShape.GANYMEDE)
	said.clear()
	marks.clear()
	at = Vector3.INF
	sights = SpaceSights.new()
	sights.auto_tick = false
	sights.shape = shape
	sights.sights = UniverseRegistry.sights(SpaceRules.GANYMEDE)
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


func test_the_seven_sights_are_on_the_map_from_the_landing() -> void:
	var ids: Array = marks.map(func(m: Dictionary) -> String: return str(m.id))
	assert_eq(ids, ["sight_lookout", "sight_grooves", "sight_dark", "sight_crater", "sight_frost", "sight_aurora",
		"sight_ocean"])
	assert_eq(marks[0].name, "Jupiter Lookout")
	assert_eq(marks[1].name, "Grooved Terrain")
	assert_eq(marks[2].name, "Dark Terrain")
	assert_eq(marks[3].name, "Bright Ray Crater")
	assert_eq(marks[4].name, "Polar Frost")
	assert_eq(marks[5].name, "Aurora Watch")
	assert_eq(marks[6].name, "Ocean Drill")


func test_the_jupiter_lookout_by_the_pad_says_jupiter_never_moves() -> void:
	var lk := shape.ganymede.lookout
	_stand(lk, 30.0)
	sights.tick()
	assert_true(said.is_empty(), "floating high over it finds nothing yet")
	_stand(lk + Vector2i(2, 1))
	sights.tick()
	assert_eq(said.size(), 1)
	assert_string_contains(said[0], "same face")
	assert_true(sights.found.has("sight:lookout"))
	sights.tick()
	assert_eq(said.size(), 1, "once per world")


func test_the_grooves_the_dark_terrain_the_crater_the_frost_the_watch_and_the_drill() -> void:
	var g := shape.ganymede
	var sp := shape.spawn_column()
	for spot: Vector2i in [g.first_groove_toward(sp), g.first_dark_west_of(sp) + Vector2i(-20, 0),
			g.crater_centre() + Vector2i(g.crater_radius() / 2, 0), g.frost_point_north_of(sp), g.watch + Vector2i(1, 1),
			g.drill + Vector2i(2, 0)]:
		_stand(spot)
		sights.tick()
	assert_eq(said.size(), 6)
	assert_string_contains(said[0], "ridges")
	assert_string_contains(said[1], "4 billion years")
	assert_string_contains(said[2], "fresh ice")
	assert_string_contains(said[3], "magnetic field")
	assert_string_contains(said[4], "auroras")
	assert_string_contains(said[5], "150 km")
	for id in ["grooves", "dark", "crater", "frost", "aurora", "ocean"]:
		assert_true(sights.found.has("sight:" + id), id)


func test_a_ray_far_from_the_crater_is_its_sight_too() -> void:
	var g := shape.ganymede
	var c := g.crater_centre()
	var ray := Vector2i.ZERO
	for a in 360:
		var p := c + Vector2i(roundi(cos(deg_to_rad(a)) * (g.crater_radius() + 25)), roundi(sin(deg_to_rad(a)) * (g.crater_radius() + 25)))
		if shape.ganymede_kind(p.x, p.y) == GanymedeTerrain.RAY:
			ray = p
			break
	assert_ne(ray, Vector2i.ZERO, "a ray out on the ground")
	_stand(ray)
	sights.tick()
	assert_eq(said.size(), 1)
	assert_string_contains(said[0], "rays")
