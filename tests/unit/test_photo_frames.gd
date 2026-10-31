extends GutTest
## Photo frames (M3 Task 16): simple frames drawn by the UI over the picture. They must leave the
## middle of the picture (where the player is) free.

const SIZES: Array[Vector2] = [Vector2(1280, 720), Vector2(1600, 720), Vector2(320, 180)]


func test_no_frame_leaves_the_whole_picture() -> void:
	for size in SIZES:
		assert_eq(PhotoFrames.inner_rect(PhotoFrames.Frame.NONE, size), Rect2(Vector2.ZERO, size))


func test_every_frame_leaves_most_of_the_picture_free_and_centred() -> void:
	for f: int in PhotoFrames.ORDER:
		for size in SIZES:
			var inner := PhotoFrames.inner_rect(f, size)
			var screen := Rect2(Vector2.ZERO, size)
			assert_true(screen.encloses(inner), "frame %d inside the picture" % f)
			assert_gte(inner.get_area(), screen.get_area() * 0.7, "frame %d leaves 70 %%" % f)
			assert_almost_eq(inner.get_center().x, size.x * 0.5, 0.5, "frame %d centred" % f)
			assert_true(inner.has_point(size * 0.5), "frame %d keeps the middle" % f)


func test_frames_have_short_labels() -> void:
	assert_eq(PhotoFrames.ORDER.size(), 5)
	assert_eq(PhotoFrames.ORDER[0], PhotoFrames.Frame.NONE, "no frame comes first")
	for f: int in PhotoFrames.ORDER:
		var label: String = PhotoFrames.LABELS[f]
		assert_between(label.length(), 2, 6, label)
