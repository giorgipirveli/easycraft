extends GutTest
## Owner #90: hints show the controller when one was used last. The KEYS card becomes the CONTROLLER card: the pad's own
## words for its buttons (a PlayStation's Cross, R2, Touchpad; an Xbox's A, RT, View, by the pad's name), the face buttons
## drawn in their colours and shapes, every line of GamepadRules.CARD_LINES, and it fits a phone's screen (a pad plays on
## a phone or a TV too). It switches between the keys and the pad as the child switches. The first time a pad is used
## in a world it shows by itself (settings.pad_seen); SETTINGS → HELP chooses how fast the right stick looks.

const PHONE := Vector2(1280, 720)


func _words(card: Control) -> Array:
	return card.find_children("*", "Label", true, false).map(func(l: Node) -> String: return (l as Label).text)


func test_the_playstation_card_names_its_buttons() -> void:
	var card := KeysCard.new(GamepadRules.PLAYSTATION)
	add_child_autofree(card)
	await wait_process_frames(2)
	var words := _words(card)
	assert_has(words, "PLAYSTATION CONTROLLER")
	for w: String in ["Cross", "R2", "L2", "L1 / R1", "Square", "Triangle", "Touchpad", "Options", "Left stick",
			"Right stick", "D-pad up / down", "Circle"]:
		assert_has(words, w)
	assert_does_not_have(words, "Space", "no keys on the controller's card")
	for line: Array in GamepadRules.CARD_LINES:
		assert_has(words, str(line[1]), "every line: %s" % line[1])
	assert_gt(card.find_children("*", "PadGlyph", true, false).size(), 3, "the face buttons are drawn")


func test_the_xbox_card_names_its_buttons() -> void:
	var card := KeysCard.new(GamepadRules.XBOX)
	add_child_autofree(card)
	await wait_process_frames(2)
	var words := _words(card)
	assert_has(words, "XBOX CONTROLLER")
	for w: String in ["A", "RT", "LT", "LB / RB", "X", "Y", "View", "Menu", "B"]:
		assert_has(words, w)
	var any := KeysCard.new(GamepadRules.GENERIC)
	add_child_autofree(any)
	await wait_process_frames(1)
	assert_has(_words(any), "CONTROLLER", "any other pad: just CONTROLLER")


func test_it_fits_a_phone_s_screen() -> void:
	for fam: StringName in [GamepadRules.PLAYSTATION, GamepadRules.XBOX]:
		var card := KeysCard.new(fam)
		add_child_autofree(card)
		await wait_process_frames(2)
		var need := card.get_combined_minimum_size()
		assert_lte(need.x, PHONE.x - 40.0, "%s width %s" % [fam, need])
		assert_lte(need.y, PHONE.y - 40.0, "%s height %s" % [fam, need])


func test_it_follows_the_hands() -> void:
	var card := KeysCard.new()
	add_child_autofree(card)
	await wait_process_frames(1)
	assert_has(_words(card), "KEYS")
	card.show_for(GamepadRules.PLAYSTATION)
	await wait_process_frames(1)
	assert_has(_words(card), "PLAYSTATION CONTROLLER")
	assert_does_not_have(_words(card), "KEYS")
	card.show_for(&"")
	await wait_process_frames(1)
	assert_has(_words(card), "Space")
	card.show_for(GamepadRules.XBOX)
	card.close_button.pressed.emit()
	assert_false(card.visible, "CLOSE still closes after a switch")


func test_the_card_comes_once_for_a_pad() -> void:
	assert_true(ProfileData.DEFAULT_SETTINGS.has("pad_seen"))
	assert_true(GamepadRules.card_due({"pad_seen": false}))
	assert_false(GamepadRules.card_due({"pad_seen": true}))


func test_the_look_speed_is_a_setting() -> void:
	assert_eq(ProfileData.DEFAULT_SETTINGS.get("pad_look"), "normal")
	var p := ProfileData.from_json(JSON.stringify({"settings": {"pad_look": "fast"}}))
	assert_eq(p.settings.pad_look, "fast")
	p = ProfileData.from_json(JSON.stringify({"settings": {"pad_look": "warp"}}))
	assert_eq(p.settings.pad_look, "normal", "an unknown speed is NORMAL")


func test_settings_help_page_has_the_controller_look() -> void:
	var saved: Variant = Profile.data.settings.get("pad_look", "normal")
	var box := PanelContainer.new()   # as the menu shows it: its theme, its panel
	box.theme = UiKit.theme()
	var panel := SettingsPanel.new()
	panel.saver = func() -> void: pass
	box.add_child(panel)
	add_child_autofree(box)
	await wait_process_frames(2)
	panel.show_page(SettingsPanel.WORDS)
	var fast := panel.find_child("PadLook_fast", true, false) as Button
	assert_not_null(fast, "SLOW / NORMAL / FAST on the HELP page")
	assert_true(fast.is_visible_in_tree())
	fast.pressed.emit()
	assert_eq(Profile.data.settings.pad_look, "fast")
	assert_true(fast.button_pressed)
	Profile.data.settings.pad_look = saved
	var need := box.get_combined_minimum_size()
	assert_lte(need.y, 720.0, "the HELP page still fits (%s)" % need)
	assert_lte(need.x, 1280.0, "and its row with the Controller look (%s)" % need)
