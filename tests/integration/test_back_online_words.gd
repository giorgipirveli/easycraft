extends GutTest
## Owner #95: when the game signs in again by itself after an offline spell (ReconnectWatch -> Session.back_online),
## the main menu says so for a few seconds: what was played offline is on the account now.


func _menu() -> Node:
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	return menu


func _shown(root: Node, text: String) -> bool:
	for l in root.find_children("*", "Label", true, false):
		if (l as Label).text == text and (l as Label).is_visible_in_tree():
			return true
	return false


func test_the_menu_says_back_online() -> void:
	var menu := _menu()
	await wait_process_frames(3)
	assert_false(_shown(menu, ReconnectRules.BACK_WORDS))
	Session.back_online.emit()
	await wait_process_frames(2)
	assert_true(_shown(menu, ReconnectRules.BACK_WORDS), "the words are on the menu")


func test_the_words_are_short_and_kind() -> void:
	assert_lte(ReconnectRules.BACK_WORDS.split(" ").size(), 14)
	assert_string_contains(ReconnectRules.BACK_WORDS, "saved")
