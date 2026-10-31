extends GutTest
## Cosmos: Triton's sights and geysers (spec §21b.2: "facts at sights"). SpaceSights watches this game's player: standing at
## the Neptune Lookout by the pad (Triton always shows Neptune the same face), at a geyser (nitrogen gas and dark dust
## about 8 km high), on a dark streak (the thin wind carried the dust), on the pink polar cap (sunlight turns its methane
## pink), in the cantaloupe terrain (a melon's skin), on the frozen lake (icy lava of water) or in the lone crater (its
## ground is young) says its real fact once per world, with a sparkle. MY MAP shows all seven from the landing; the planet
## guide's checklist lists them. SpaceGeysers makes the geysers near the player erupt now and then: puffs of dark dust
## and nitrogen frost, drifting north-east on the thin wind.

var shape: SpaceShape
var sights: SpaceSights
var at := Vector3.INF
var said: Array[String] = []
var marks: Array[Dictionary] = []


func before_each() -> void:
	shape = SpaceShape.new(12345, SpaceShape.TRITON)
	said.clear()
	marks.clear()
	at = Vector3.INF
	sights = SpaceSights.new()
	sights.auto_tick = false
	sights.shape = shape
	sights.sights = UniverseRegistry.sights(SpaceRules.TRITON)
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
	assert_eq(ids, ["sight_lookout", "sight_geyser", "sight_trail", "sight_cap", "sight_melon", "sight_lake",
		"sight_crater"])
	assert_eq(marks[0].name, "Neptune Lookout")
	assert_eq(marks[1].name, "Geyser")
	assert_eq(marks[2].name, "Dark Streaks")
	assert_eq(marks[3].name, "Pink Polar Cap")
	assert_eq(marks[4].name, "Cantaloupe Terrain")
	assert_eq(marks[5].name, "Frozen Lake")
	assert_eq(marks[6].name, "Lone Crater")


func test_the_neptune_lookout_by_the_pad_says_neptune_never_moves() -> void:
	var lk := shape.triton.lookout
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


func test_the_geyser_the_streak_the_cap_the_melon_the_lake_and_the_crater() -> void:
	var t := shape.triton
	var sp := shape.spawn_column()
	var g := t.first_geyser()
	for spot: Vector2i in [g + Vector2i(2, 0), t.streak_centre(g, 16.0), t.cap_point_south_of(sp), t.first_melon_toward(sp),
			t.lake_centre(), t.crater_centre()]:
		_stand(spot)
		sights.tick()
	assert_eq(said.size(), 6)
	assert_string_contains(said[0], "8 km")
	assert_string_contains(said[1], "wind")
	assert_string_contains(said[2], "pink")
	assert_string_contains(said[3], "melon")
	assert_string_contains(said[4], "lava")
	assert_string_contains(said[5], "young")


func test_the_planet_guides_checklist_lists_them() -> void:
	var list := PlanetGuideRules.checklist(shape.sights(), UniverseRegistry.sights(SpaceRules.TRITON), {}, Vector3.ZERO)
	assert_eq(list.size(), 7, "seven places to explore")


# --- The geysers erupt ---

func test_triton_has_geysers_that_erupt_on_their_own_beats() -> void:
	assert_true(shape.has_vents())
	var vents := shape.vents_near(0, 250, 400.0)
	assert_gt(vents.size(), 3)
	var on := {}
	for v: Vector2i in vents:
		on[v] = SpaceGeysers.erupting(3.0, v)
	assert_eq(on.values().count(true) > 0 and on.values().count(false) > 0, true, "not all at once")


## Dark dust and nitrogen frost, carried north-east on the thin wind (the real plumes' dust drifted downwind and fell in
## the dark streaks); Europa's plumes stay white and straight up.
func test_the_plumes_are_dark_dust_drifting_north_east() -> void:
	var dust := SpaceGeysers.plume_color(shape)
	assert_lt(dust.get_luminance(), 0.5, "dark dust (%s)" % dust)
	var wind := SpaceGeysers.plume_wind(shape)
	assert_gt(wind.x, 0.5, "east")
	assert_lt(wind.z, -0.5, "and north")
	var europa := SpaceShape.new(12345, SpaceShape.EUROPA)
	assert_eq(SpaceGeysers.plume_wind(europa), Vector3.ZERO, "Europa's plumes rise straight")
	assert_eq(SpaceGeysers.plume_color(europa), SpaceGeysers.VAPOUR)


func test_the_plumes_near_the_player_blow() -> void:
	var g := SpaceGeysers.new()
	g.auto_tick = false
	g.shape = shape
	var v := shape.triton.first_geyser()
	at = Vector3(v.x + 5.5, shape.height_at(v.x, v.y), v.y + 0.5)
	g.player_position = func() -> Vector3: return at
	var puffs: Array[Vector3] = []
	g.plume = func(p: Vector3) -> void: puffs.append(p)
	add_child_autofree(g)
	for i in 120:
		g.tick(0.1)
	assert_gt(puffs.size(), 3, "it blew while the child was near")
	assert_true(puffs.any(func(p: Vector3) -> bool: return floori(p.x) == v.x and floori(p.z) == v.y), "from the vent")
