extends GutTest
## Owner feedback #42: the treasure pack's pictures (for children who can't read yet: the Secret Book's page and
## riddles, banners, the ghosts' answers, the pictures over the vault's levers) live in their own small atlas,
## data/secrets/treasure_pictures.png (tools/make_treasure_pictures.gd), so the M2 atlas never changes; its
## sounds (tools/make_treasure_sfx.py) are registered.

const USED := 22                  # tiles drawn so far (TreasureRules.FIRST_PICTURE .. DROP)


func _tile(img: Image, k: int) -> Image:
	var at := Vector2i(k % Pictures.COLUMNS, k / Pictures.COLUMNS) * Pictures.TILE
	return img.get_region(Rect2i(at, Vector2i(Pictures.TILE, Pictures.TILE)))


func test_every_picture_of_the_pack_is_drawn_and_different() -> void:
	var img := Pictures.pack_atlas().get_image()
	assert_eq(img.get_size(), Vector2i(Pictures.COLUMNS, Pictures.PACK_ROWS) * Pictures.TILE)
	assert_eq(TreasureRules.DROP - TreasureRules.FIRST_PICTURE + 1, USED)
	var seen := {}
	for k in USED:
		var tile := _tile(img, k)
		var n := 0
		for y in Pictures.TILE:
			for x in Pictures.TILE:
				if tile.get_pixel(x, y).a > 0.5:
					n += 1
		assert_gt(n, 20, "picture %d" % (TreasureRules.FIRST_PICTURE + k))
		assert_false(seen.has(tile.get_data()), "picture %d is a copy" % (TreasureRules.FIRST_PICTURE + k))
		seen[tile.get_data()] = true


func test_pictures_pick_their_atlas() -> void:
	var ship := Pictures.texture(TreasureRules.SHIPWRECK_PICTURE)
	assert_eq(ship.atlas, Pictures.pack_atlas())
	assert_eq(ship.region, Rect2(0, 0, 16, 16))
	assert_eq(Pictures.texture(TreasureRules.ANCHOR).region, Rect2(64, 16, 16, 16))
	assert_eq(Pictures.texture(Riddles.MOON).atlas, Pictures.atlas(), "the M2 pictures stay in theirs")
	var crown := Pictures.material(TreasureRules.CROWN)
	assert_same(crown, Pictures.material(TreasureRules.CROWN), "one shared material per picture")
	assert_eq(crown.albedo_texture, Pictures.pack_atlas())
	assert_almost_eq(crown.uv1_scale, Vector3(1.0 / Pictures.COLUMNS, 1.0 / Pictures.PACK_ROWS, 1.0), Vector3.ONE * 0.0001)
	assert_almost_eq(crown.uv1_offset, Vector3(5.0 / Pictures.COLUMNS, 1.0 / Pictures.PACK_ROWS, 0.0), Vector3.ONE * 0.0001)


func test_the_packs_sounds_exist() -> void:
	for key in [&"giggle", &"coin_toss", &"rainbow"]:
		assert_true(Audio.SOUNDS.has(key), String(key))
		for path: String in Audio.SOUNDS.get(key, []):
			assert_true(ResourceLoader.exists(path), path)


func test_notes_hint_at_the_pack_with_short_words() -> void:
	var pack := 0
	for note: Dictionary in Riddles.ROOM_NOTES:
		assert_lte((note.text as String).length(), 40)
		assert_eq((note.pictures as Array).size(), 1)
		if int(note.pictures[0]) >= TreasureRules.FIRST_PICTURE:
			pack += 1
	assert_gte(pack, 5, "hidden rooms' and ruins' notes hint at the new secrets")
