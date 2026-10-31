extends GutTest
## Owner #84: a PC game tells its keys. The KEYS card lists the keyboard and the mouse (move, look, jump and fly, break
## and place, the blocks' numbers, the modes, chat, photo, the menu), each key read from the game's own input map so the
## card never lies. It shows once at the first world on a PC (settings.keys_seen), and F1 (or KEYS in the pause menu)
## opens it again. A phone never sees it.

const PC := {PlatformRules.WEB: true, PlatformRules.WEB_WINDOWS: true}
const PHONE := {PlatformRules.MOBILE: true, PlatformRules.ANDROID: true}


func after_each() -> void:
	PlatformRules.simulated = {}


func test_every_line_is_a_real_binding() -> void:
	assert_gte(KeysRules.LINES.size(), 12)
	for line: Array in KeysRules.LINES:
		for action: String in line[0]:
			if action.begins_with("mouse:"):
				continue
			assert_true(InputMap.has_action(action), action)
			assert_ne(KeysRules.key_text(action), "", "%s has a key" % action)
	assert_eq(KeysRules.key_text("jump"), "Space")
	assert_eq(KeysRules.key_text("move_forward"), "W")
	assert_eq(KeysRules.key_text("pause"), "Esc")
	assert_eq(KeysRules.key_text("break"), "Left click")
	assert_eq(KeysRules.key_text("place"), "Right click")


func test_it_shows_once_on_a_pc_never_on_a_phone() -> void:
	assert_true(ProfileData.DEFAULT_SETTINGS.has("keys_seen"))
	assert_true(KeysRules.due({"keys_seen": false}, PC))
	assert_false(KeysRules.due({"keys_seen": true}, PC))
	assert_false(KeysRules.due({"keys_seen": false}, PHONE))


func test_the_card_fits_a_pc_screen() -> void:
	var card := KeysCard.new()
	add_child_autofree(card)
	await wait_frames(2)
	var need := card.get_combined_minimum_size()
	assert_lte(need.x, PlatformRules.PC_CANVAS.x - 40.0, "width %s" % need)
	assert_lte(need.y, PlatformRules.PC_CANVAS.y - 40.0, "height %s" % need)
	var words := card.find_children("*", "Label", true, false).map(func(l: Node) -> String: return (l as Label).text)
	assert_has(words, "Space")
	card.close_button.pressed.emit()
	assert_false(card.visible, "CLOSE hides it")
