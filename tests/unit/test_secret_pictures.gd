extends GutTest
## M2 Task 16 (lead's ruling on picture riddles): children who can't read yet go by pictures — the temple's
## plates and note, the Wanderer's answers and the Secret Book's slots. One small atlas, shared textures
## and materials.


func _opaque(img: Image, id: int) -> int:
	var tile := Vector2i(id % Pictures.COLUMNS, id / Pictures.COLUMNS) * Pictures.TILE
	var n := 0
	for y in Pictures.TILE:
		for x in Pictures.TILE:
			if img.get_pixel(tile.x + x, tile.y + y).a > 0.5:
				n += 1
	return n


func test_every_picture_is_drawn() -> void:
	var img := Pictures.atlas().get_image()
	assert_eq(img.get_size(), Vector2i(Pictures.COLUMNS, Pictures.ROWS) * Pictures.TILE)
	for id in Riddles.PICTURE_COUNT:
		assert_gt(_opaque(img, id), 20, "picture %d" % id)


func test_pictures_differ_from_each_other() -> void:
	var img := Pictures.atlas().get_image()
	var seen := {}
	for id in Riddles.PICTURE_COUNT:
		var tile := Vector2i(id % Pictures.COLUMNS, id / Pictures.COLUMNS) * Pictures.TILE
		var data := img.get_region(Rect2i(tile, Vector2i(Pictures.TILE, Pictures.TILE))).get_data()
		assert_false(seen.has(data), "picture %d is a copy" % id)
		seen[data] = true


func test_textures_are_shared_atlas_tiles() -> void:
	var moon := Pictures.texture(Riddles.MOON)
	assert_eq(moon.region, Rect2(16, 0, 16, 16))
	assert_same(moon, Pictures.texture(Riddles.MOON))
	assert_eq(Pictures.texture(Riddles.KEY).region, Rect2(0, 16, 16, 16))


func test_one_shared_3d_material_per_picture() -> void:
	var star := Pictures.material(Riddles.STAR)
	assert_same(star, Pictures.material(Riddles.STAR))
	assert_almost_eq(star.uv1_scale, Vector3(1.0 / Pictures.COLUMNS, 1.0 / Pictures.ROWS, 1.0), Vector3.ONE * 0.0001)
	assert_almost_eq(star.uv1_offset, Vector3(2.0 / Pictures.COLUMNS, 0.0, 0.0), Vector3.ONE * 0.0001)
	assert_eq(star.texture_filter, BaseMaterial3D.TEXTURE_FILTER_NEAREST)


## Every sound the secrets play is registered and its file exists (tools/make_secret_sfx.py).
func test_the_secrets_sounds_exist() -> void:
	for key in [&"sparkle", &"chime", &"knock", &"chest_open", &"star_fall", &"star_land", &"plate_click", &"plate_wrong"]:
		assert_true(Audio.SOUNDS.has(key), String(key))
		for path: String in Audio.SOUNDS.get(key, []):
			assert_true(ResourceLoader.exists(path), path)


func test_every_riddle_answer_has_a_picture_and_a_word() -> void:
	for r: Dictionary in Riddles.WANDERER_RIDDLES:
		for picture: int in r.choices:
			assert_between(picture, 0, Riddles.PICTURE_COUNT - 1)
			assert_ne(Riddles.word(picture), "")
	for picture in Riddles.TEMPLE_SYMBOLS:
		assert_ne(Riddles.word(picture), "")
