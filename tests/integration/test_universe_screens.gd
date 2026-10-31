extends GutTest
## M5 Task 2 (spec §15.2): a universe's own menu screens (CONTINUE / NEW WORLD, a new world?, how brave, which game)
## show its scene behind the buttons (UniverseBackdrop, under a veil); the screens with no one universe don't.

var menu: Node


func before_each() -> void:
	menu = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_frames(3)


func after_each() -> void:
	UniverseRegistry.reset()


func _panel() -> PanelContainer:
	for c in (menu.get("_center") as Node).get_children():
		if c is PanelContainer and not c.is_queued_for_deletion():
			return c
	return null


func _backdrop() -> UniverseBackdrop:
	var p := _panel()
	if p == null:
		return null
	for c in p.get_children(true):
		if c is UniverseBackdrop:
			return c
	return null


func _buttons() -> Array[String]:
	var out: Array[String] = []
	for b in _panel().find_children("*", "Button", true, false):
		out.append((b as Button).text)
	return out


func test_how_brave_and_which_game_show_the_universes_scene_behind_the_buttons() -> void:
	menu.call("_choose_difficulty", 3)
	await wait_frames(2)
	var b := _backdrop()
	assert_not_null(b, "Frostpeak's scene behind how brave")
	if b:
		assert_eq(b.universe, 3)
		assert_eq(_panel().get_child(0, true), b, "behind everything else in the panel")
		assert_false(_panel().get_child(0) is UniverseBackdrop, "the screen's content stays the panel's first child")
		assert_almost_eq(b.size, (_panel().get_child(0) as Control).size, Vector2.ONE, "as big as the panel's inside")
	assert_true(_buttons().has(DifficultyRules.label(DifficultyRules.COZY)), "the buttons are all there")
	menu.call("_choose_game", DifficultyRules.NORMAL, 4)
	await wait_frames(2)
	assert_eq(_backdrop().universe if _backdrop() else -1, 4, "the Candy Kingdom's behind which game")


func test_a_new_world_question_and_continue_show_it_too() -> void:
	menu.call("_confirm_new_world", ModeRules.SURVIVOR, 2)
	await wait_frames(2)
	assert_eq(_backdrop().universe if _backdrop() else -1, 2)
	menu.call("_confirm_new_world", ModeRules.SANDBOX, 5)
	await wait_frames(2)
	assert_eq(_backdrop().universe if _backdrop() else -1, 5, "a universe's Sandbox world too")


func test_screens_that_are_not_one_universes_have_none() -> void:
	menu.call("_show_main")
	await wait_frames(2)
	assert_null(_backdrop(), "the main screen")
	menu.call("_show_settings")
	await wait_frames(2)
	assert_null(_backdrop(), "settings")
