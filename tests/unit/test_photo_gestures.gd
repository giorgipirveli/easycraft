extends GutTest
## Photo mode's touch gestures (M3 Task 16): one finger turns the camera around the player, two
## fingers pinch to zoom and move together to pan.

var g: PhotoGestures


func before_each() -> void:
	g = PhotoGestures.new()


func test_one_finger_drag_orbits() -> void:
	g.press(0, Vector2(100, 100))
	var m := g.move(0, Vector2(130, 90))
	assert_eq(m.orbit, Vector2(30, -10))
	assert_eq(m.zoom, 1.0)
	assert_eq(m.pan, Vector2.ZERO)


func test_an_unknown_finger_does_nothing() -> void:
	var m := g.move(3, Vector2(10, 10))
	assert_eq(m.orbit, Vector2.ZERO)
	assert_eq(m.zoom, 1.0)
	assert_eq(m.pan, Vector2.ZERO)


func test_spreading_two_fingers_zooms_in() -> void:
	g.press(0, Vector2(500, 300))
	g.press(1, Vector2(600, 300))
	var m := g.move(1, Vector2(700, 300))
	assert_almost_eq(m.zoom, 0.5, 0.0001, "twice as far apart: half the distance")
	assert_eq(m.orbit, Vector2.ZERO, "two fingers never orbit")


func test_pinching_two_fingers_zooms_out() -> void:
	g.press(0, Vector2(400, 300))
	g.press(1, Vector2(800, 300))
	var m := g.move(0, Vector2(600, 300))
	assert_almost_eq(m.zoom, 2.0, 0.0001)


func test_two_fingers_moving_together_pan() -> void:
	g.press(0, Vector2(400, 300))
	g.press(1, Vector2(600, 300))
	var m := g.move(0, Vector2(420, 330))
	assert_eq(m.pan, Vector2(10, 15), "the middle of the two fingers moves by half")
	var first_zoom: float = m.zoom
	m = g.move(1, Vector2(620, 330))
	assert_eq(m.pan, Vector2(10, 15))
	assert_almost_eq(first_zoom * m.zoom, 1.0, 0.0001, "the same distance apart again: no zoom overall")


func test_lifting_one_of_two_fingers_goes_back_to_orbit() -> void:
	g.press(0, Vector2(400, 300))
	g.press(1, Vector2(600, 300))
	g.release(1)
	var m := g.move(0, Vector2(410, 300))
	assert_eq(m.orbit, Vector2(10, 0))
	assert_eq(g.count(), 1)


func test_a_third_finger_is_ignored() -> void:
	g.press(0, Vector2(400, 300))
	g.press(1, Vector2(600, 300))
	g.press(2, Vector2(100, 100))
	var m := g.move(2, Vector2(300, 300))
	assert_eq(m.orbit, Vector2.ZERO)
	assert_eq(m.zoom, 1.0)
	assert_eq(m.pan, Vector2.ZERO)


func test_cancel_forgets_every_finger() -> void:
	g.press(0, Vector2(400, 300))
	g.press(1, Vector2(600, 300))
	g.cancel()
	assert_eq(g.count(), 0)
	assert_false(g.owns(0))
