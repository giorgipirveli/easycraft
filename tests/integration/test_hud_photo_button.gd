extends GutTest
## The photo button (M3 Task 16): in the MORE panel since M2 Task 17 (a button used now and then; top
## right before), as big as the others, with a camera over its word, under the palette overlay; it asks
## for photo mode when pressed, and the panel closes (photo mode hides the HUD).


func test_the_photo_button_waits_in_the_more_panel() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	assert_true(hud.more.is_ancestor_of(hud.photo_button))
	assert_eq(hud.photo_button.custom_minimum_size, Vector2(HudLayout.BUTTON, HudLayout.BUTTON), "as big as the others")
	assert_eq(hud.photo_button.symbol, &"photo", "a camera")
	assert_eq(hud.photo_button.text, "PHOTO")


func test_the_photo_button_is_under_the_palette_and_asks_for_photo_mode() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	assert_lt(hud.more.get_index(), hud.palette.get_index(), "the palette overlay covers it")
	assert_true(hud.photo_button.visible, "on phones and desktop")
	hud.more.open()
	watch_signals(hud)
	hud.photo_button.pressed.emit()
	assert_signal_emitted(hud, "photo_requested")
	assert_false(hud.more.is_open(), "photo mode takes over: the panel closes")
