extends GutTest
## Thought bubbles (M2 Task 18, spec §12.17): a small picture over a creature's head now and then —
## one shared picture atlas, one shared quad and one cached material per picture (never a material
## per bubble), only near this device's camera, at most a few at once, still with Reduce motion.

var _camera: Camera3D
var _motion: bool


func before_each() -> void:
	_motion = bool(Profile.data.settings.get("reduce_motion", false))
	Profile.data.settings.reduce_motion = false
	_camera = Camera3D.new()
	add_child_autofree(_camera)
	_camera.current = true
	_camera.global_position = Vector3(0, 2, 6)
	ThoughtBubble.shown = 0


func after_each() -> void:
	Profile.data.settings.reduce_motion = _motion


func _creature(at := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	add_child_autofree(n)
	n.global_position = at
	return n


func test_the_atlas_has_a_picture_for_every_thought() -> void:
	var img := ThoughtPictures.atlas().get_image()
	assert_not_null(img)
	assert_eq(img.get_size(), Vector2i(ThoughtPictures.TILE * ThoughtPictures.COLUMNS, ThoughtPictures.TILE))
	var tiles := {}
	for id in Thought.COUNT:
		var tile := img.get_region(Rect2i(id * ThoughtPictures.TILE, 0, ThoughtPictures.TILE, ThoughtPictures.TILE))
		assert_false(tile.is_invisible(), "%s is drawn" % Thought.NAMES[id])
		tiles[tile.get_data()] = true
	assert_eq(tiles.size(), Thought.COUNT, "every picture is different")


func test_bubbles_share_one_quad_and_one_material_per_picture() -> void:
	var a := _creature(Vector3(1, 0, 0))
	var b := _creature(Vector3(-1, 0, 0))
	var ba := ThoughtBubble.show_on(a, Thought.HEART, 1.2)
	var bb := ThoughtBubble.show_on(b, Thought.HEART, 1.2)
	assert_not_null(ba)
	assert_not_null(bb)
	assert_same(ba.mesh, bb.mesh, "one quad for every bubble")
	assert_same(ba.material_override, bb.material_override, "one material per picture")
	var zzz := ThoughtBubble.show_on(a, Thought.ZZZ, 1.2)
	assert_same(zzz, ba, "a creature reuses its one bubble")
	assert_ne(zzz.material_override, bb.material_override, "another picture, another (cached) material")
	for round in 5:
		for id in Thought.COUNT:
			ThoughtBubble.hide_on(a)
			ThoughtBubble.show_on(a, id, 1.2)
	assert_lte(ThoughtPictures.material_count(), Thought.COUNT, "no material is ever made per bubble")
	assert_eq(a.find_children("*", "MeshInstance3D", true, false).size(), 1)


func test_a_bubble_goes_away_by_itself() -> void:
	var a := _creature()
	var bubble := ThoughtBubble.show_on(a, Thought.QUESTION, 1.0)
	assert_true(bubble.visible)
	bubble._process(ThoughtBubble.SHOW_TIME * 0.5)
	assert_true(bubble.visible)
	bubble._process(ThoughtBubble.SHOW_TIME)
	assert_false(bubble.visible)
	assert_eq(ThoughtBubble.shown, 0)


func test_it_faces_the_camera() -> void:
	var a := _creature(Vector3(3, 0, 0))
	var bubble := ThoughtBubble.show_on(a, Thought.HEART, 1.0)
	a.rotation.y = 1.3
	bubble._process(0.016)
	var facing := bubble.global_basis.z.normalized()
	var to_camera := (_camera.global_position - bubble.global_position).normalized()
	assert_gt(facing.dot(to_camera), 0.95, "its picture side looks at the camera")


func test_only_near_this_devices_camera() -> void:
	var far := _creature(Vector3(ThoughtBubble.SEE_DISTANCE + 10.0, 0, 0))
	assert_null(ThoughtBubble.show_on(far, Thought.HEART, 1.0), "too far away to see")


func test_at_most_a_few_bubbles_at_once() -> void:
	var shown := 0
	for i in ThoughtBubble.MAX_SHOWN + 3:
		if ThoughtBubble.show_on(_creature(Vector3(i * 0.5, 0, 0)), Thought.ZZZ, 1.0):
			shown += 1
	assert_eq(shown, ThoughtBubble.MAX_SHOWN, "a sleeping herd is not a wall of bubbles")


func test_it_bobs_gently_but_not_with_reduce_motion() -> void:
	var a := _creature()
	var bubble := ThoughtBubble.show_on(a, Thought.HEART, 1.0)
	var heights := {}
	for i in 10:
		bubble._process(0.1)
		heights[snappedf(bubble.position.y, 0.001)] = true
	assert_gt(heights.size(), 1, "floats up and down a little")
	Profile.data.settings.reduce_motion = true
	ThoughtBubble.hide_on(a)
	bubble = ThoughtBubble.show_on(a, Thought.HEART, 1.0)
	assert_eq(bubble.scale, Vector3.ONE, "no pop either")
	heights.clear()
	for i in 10:
		bubble._process(0.1)
		heights[snappedf(bubble.position.y, 0.001)] = true
	assert_eq(heights.size(), 1, "Reduce motion: it stays still")


func test_a_creature_that_goes_away_takes_its_bubble_off_the_count() -> void:
	var a := Node3D.new()
	add_child(a)
	ThoughtBubble.show_on(a, Thought.HEART, 1.0)
	assert_eq(ThoughtBubble.shown, 1)
	a.free()
	assert_eq(ThoughtBubble.shown, 0)
