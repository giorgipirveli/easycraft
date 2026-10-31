extends GutTest
## Cosmos: lightning far below Venus's cloud city (spec §21b.2: "lightning far below"; spacecraft picked up radio signals
## that may come from lightning in Venus's clouds). VenusLightning, for this game's own player: now and then a soft,
## silent flash deep in the yellow clouds, NEAR to FAR sideways, never under a deck or a bridge: a zig-zag bolt shown for
## a moment, a flicker, once more, gone. Friendly: never near the child, never over the city.

var shape: SpaceShape
var node: VenusLightning
var at := Vector3.INF


func before_each() -> void:
	shape = SpaceShape.new(12345, SpaceShape.VENUS)
	var sp := shape.spawn_column()
	at = Vector3(sp.x + 0.5, VenusTerrain.DECK_Y, sp.y + 0.5)
	node = VenusLightning.new()
	node.auto_tick = false
	node.shape = shape
	node.player_position = func() -> Vector3: return at
	node.rng.seed = 7
	add_child_autofree(node)


func test_a_flash_starts_deep_in_the_clouds_far_from_the_child_never_under_the_city() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 3
	var found := 0
	for i in 200:
		var p := VenusLightning.spot(shape, at, r)
		if not p.is_finite():
			continue
		found += 1
		var d := Vector2(p.x - at.x, p.z - at.z).length()
		assert_between(d, VenusLightning.NEAR - 1.0, VenusLightning.FAR + 1.0, "far from the child (%.0f)" % d)
		var x := floori(p.x)
		var z := floori(p.z)
		assert_eq(shape.venus.kind_at(x, z), VenusTerrain.CLOUD, "never under a deck or a bridge")
		assert_lt(p.y, float(shape.venus.cloud_top(x, z)), "inside the clouds")
		assert_lt(p.y, VenusTerrain.LIFT_Y - 10.0, "far below the city")
	assert_gt(found, 150, "the clouds are everywhere round the city")


func test_a_bolt_zig_zags_mostly_sideways() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 5
	var from := Vector3(10, 30, 10)
	var points := VenusLightning.bolt_points(from, 14.0, 0.3, r)
	assert_eq(points.size(), VenusLightning.SEGMENTS + 1)
	assert_eq(points[0], from)
	var end := points[points.size() - 1]
	assert_gt(Vector2(end.x - from.x, end.z - from.z).length(), 8.0, "it reaches out sideways")
	assert_lt(end.y, from.y, "and a little down")
	var mesh := VenusLightning.bolt_mesh(points)
	assert_gt(mesh.get_surface_count(), 0)
	assert_same(mesh.surface_get_material(0), VenusLightning.material(), "one material for every bolt")
	var m := VenusLightning.material()
	assert_eq(m.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED, "a glow")
	assert_true(m.disable_fog, "seen through the haze, like the stars")
	assert_true(m.vertex_color_use_as_albedo)


func test_it_flashes_flickers_and_is_gone() -> void:
	assert_null(node.bolt(), "nothing yet")
	node.tick(VenusLightning.FIRST + 0.01)
	var b := node.bolt()
	assert_not_null(b, "a flash")
	assert_true(b.visible)
	node.tick(VenusLightning.SHOW + 0.01)
	assert_false(b.visible, "a flicker")
	node.tick(VenusLightning.DARK)
	assert_true(b.visible, "once more")
	node.tick(VenusLightning.AGAIN + 0.01)
	assert_null(node.bolt(), "gone")
	node.tick(VenusLightning.EVERY.x * 0.5)
	assert_null(node.bolt(), "a while before the next one")
	node.tick(VenusLightning.EVERY.y)
	assert_not_null(node.bolt(), "and then the next")


func test_nothing_without_a_child() -> void:
	at = Vector3.INF
	node.tick(VenusLightning.FIRST + VenusLightning.EVERY.y)
	assert_null(node.bolt())
