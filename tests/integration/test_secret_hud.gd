extends GutTest
## M2 Task 16: the Secret Book button (beside CHAT since M2 Task 17), the book's page, surprise banners, the
## riddle panel with picture answers (for children who can't read yet) and the treasure map's compass.

var _book_before := {}
var _shelf_before: Array[int] = []


func before_each() -> void:
	_book_before = Profile.data.secret_book.duplicate()
	_shelf_before = Profile.data.treasures.duplicate()


func after_each() -> void:
	Profile.data.secret_book = _book_before
	Profile.data.treasures = _shelf_before


func _hud() -> Hud:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.add_secret_controls(null)
	return hud


## M2 Task 17: MIRROR went into the MORE panel; BOOK sits beside CHAT, under the hearts, as big as the
## other buttons.
func test_the_book_button_sits_beside_chat_under_the_hearts() -> void:
	var hud := _hud()
	var b := hud.book_button
	var chat := hud.chat.button
	assert_eq(Vector2(b.anchor_left, b.anchor_top), Vector2.ZERO, "top-left corner")
	assert_eq(b.offset_top, chat.offset_top, "the CHAT row")
	assert_gt(b.offset_left, chat.offset_right, "right of CHAT")
	assert_gt(b.offset_top, hud.stealth_meter.offset_bottom, "under the hearts and the eye")
	assert_eq(Vector2(b.offset_right - b.offset_left, b.offset_bottom - b.offset_top), Vector2(135, 135))
	assert_eq(b.text, "BOOK")
	assert_eq(b.symbol, &"book")
	assert_true(b.visible, "on every device")
	assert_true(hud.look_area.blockers.has(b), "a tap on it never builds")


func test_the_book_shows_question_marks_until_a_kind_is_found() -> void:
	Profile.data.secret_book = {"temple": 2}
	var book := _hud().secret_book
	book.refresh()
	var texts := book.slot_texts()
	assert_eq(texts.size(), SecretRules.KINDS.size() + 1, "a slot per kind of secret (M3 Task 21c: and the mouse village last)")
	for i in SecretRules.KINDS.size():
		if SecretRules.KINDS[i] == SecretRules.TEMPLE:
			assert_eq(texts[i], "Puzzle Temple\n× 2")
		else:
			assert_eq(texts[i], "???")


func test_the_book_counts_this_worlds_finds_in_the_explored_places() -> void:
	var d := SecretDirector.new()
	d.auto_tick = false
	add_child_autofree(d)
	var state := SecretState.new()
	state.explore(Vector2i(1, 2), 3)
	state.found["temple_1_2_3"] = true
	d.setup(12345, state)
	var book := _hud().secret_book
	book.director = d
	book.refresh()
	assert_eq(book.world_line(), "In this world: 1 of 3 secrets found in the places you explored")


func test_the_shelf_puts_a_found_treasure_in_hand() -> void:
	Profile.data.treasures = [BlockIds.TROPHY] as Array[int]
	var book := _hud().secret_book
	book.refresh()
	assert_eq(book.shelf_ids(), [BlockIds.TROPHY] as Array[int])
	watch_signals(book)
	book.open()
	var b := book.find_children("*", "Button", true, false).filter(func(n: Node) -> bool: return n.has_meta(&"id"))[0] as Button
	b.pressed.emit()
	assert_signal_emitted_with_parameters(book, "treasure_picked", [BlockIds.TROPHY])
	assert_false(book.visible)


func test_surprise_banners_wait_their_turn() -> void:
	var banner := _hud().banner
	banner.show_banner("You found a hidden room!", Riddles.ROOM_DOOR)
	banner.show_banner("Treasure! 40 gold")
	assert_eq(banner.showing(), "You found a hidden room!")
	assert_eq(banner.waiting(), 1)
	assert_eq(banner.picture.texture, Pictures.texture(Riddles.ROOM_DOOR))
	assert_eq(banner.mouse_filter, Control.MOUSE_FILTER_IGNORE, "never takes a tap")


func test_the_wanderers_answers_are_big_picture_buttons_with_a_word() -> void:
	var panel := _hud().riddle_panel
	var picked: Array[int] = []
	panel.show_riddle("I shine all day. What am I?", [Riddles.MOON, Riddles.SUN, Riddles.FISH],
		func(i: int) -> void: picked.append(i))
	assert_true(panel.visible)
	var buttons := panel.choice_buttons()
	assert_eq(buttons.size(), 3)
	assert_eq(buttons[1].icon, Pictures.texture(Riddles.SUN))
	assert_eq(buttons[1].text, "sun")
	assert_gte(buttons[1].custom_minimum_size.x, 120.0, "big enough for small fingers")
	buttons[1].pressed.emit()
	assert_eq(picked, [1] as Array[int])
	assert_false(panel.visible)


func test_a_temple_note_shows_the_plates_pictures_in_order() -> void:
	var panel := _hud().riddle_panel
	panel.show_note(Riddles.TEMPLE_TEXT, [Riddles.MOON, Riddles.STAR, Riddles.SUN])
	assert_eq(panel.picture_ids(), [Riddles.MOON, Riddles.STAR, Riddles.SUN] as Array[int])
	assert_eq(panel.choice_buttons().size(), 0)
	assert_eq(panel.text_label.text, Riddles.TEMPLE_TEXT)


func test_the_compass_points_at_the_treasure_and_says_how_far() -> void:
	var compass := _hud().compass
	assert_false(compass.holding_map(), "no map in hand: no compass")
	compass.set_target({"chest": Vector3i(0, 30, -51)})
	compass.update(Vector3(0.5, 40, 0.5), 0.0)
	assert_eq(compass.distance, 51)
	assert_almost_eq(compass.angle, 0.0, 0.01, "straight ahead")
	compass.update(Vector3(0.5, 40, 0.5), PI / 2)   # turned to face -X: the treasure is to the right
	assert_almost_eq(compass.angle, PI / 2, 0.01)
	compass.set_target({})
	compass.update(Vector3.ZERO, 0.0)
	assert_eq(compass.distance, -1, "no treasure near")


func test_back_closes_the_secret_panels_first() -> void:
	var hud := _hud()
	assert_false(hud.close_secret_panels())
	hud.secret_book.open()
	assert_true(hud.close_secret_panels())
	assert_false(hud.secret_book.visible)
