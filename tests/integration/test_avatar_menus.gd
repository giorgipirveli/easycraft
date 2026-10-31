extends GutTest
## M3 Task 9: the avatar editor opens from the main menu (next to SETTINGS) and from the pause menu
## (under RESUME); DONE goes back. In a Survivor world the pause menu's editor lets the host take the
## gold. The editors' save hooks are swapped, so the real profile file is never written.

const SCREEN := Vector2i(2400, 1080)   # the emulator's landscape screen

var _window_size: Vector2i
var _mode_before: StringName


func before_all() -> void:
	_window_size = get_window().size


func after_all() -> void:
	get_window().size = _window_size


func before_each() -> void:
	_mode_before = Game.mode


func after_each() -> void:
	Game.mode = _mode_before


func _button(from: Node, text: String) -> Button:
	for b in from.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b
	return null


func _editor(from: Node) -> AvatarEditor:
	for n in from.find_children("*", "", true, false):
		if n is AvatarEditor and (n as AvatarEditor).is_inside_tree():
			return n
	return null


func test_the_main_menu_opens_the_editor_and_done_comes_back() -> void:
	get_window().size = SCREEN
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_process_frames(3)
	menu.call("_show_main")
	await wait_process_frames(2)
	var avatar := _button(menu, "AVATAR")
	assert_not_null(avatar, "an AVATAR button on the main screen")
	assert_not_null(_button(menu, "SETTINGS"), "next to SETTINGS")
	avatar.pressed.emit()
	await wait_process_frames(2)
	var editor := _editor(menu)
	assert_not_null(editor)
	assert_false(editor.world_economy, "outside a world the editor spends the profile's gold itself")
	var viewport := Rect2(Vector2.ZERO, menu.get_viewport().get_visible_rect().size)
	assert_true(viewport.encloses(editor.get_global_rect()), "the editor fits on the screen")
	editor.save_profile = func() -> void: pass
	editor.done_button.pressed.emit()
	await wait_process_frames(2)
	assert_not_null(_button(menu, "SANDBOX\nBuild anything!"), "back on the main screen")


func test_the_pause_menu_opens_the_editor_under_resume() -> void:
	Game.mode = ModeRules.SURVIVOR
	var pause := PauseMenu.new()
	add_child_autofree(pause)
	pause.visible = true
	pause.call("_show_buttons")
	await wait_process_frames(1)
	var resume := _button(pause, "RESUME")
	var avatar := _button(pause, "AVATAR")
	assert_not_null(avatar)
	assert_gte(avatar.get_global_rect().position.y, resume.get_global_rect().end.y, "under RESUME (on the row below it)")
	avatar.pressed.emit()
	await wait_process_frames(2)
	var editor := _editor(pause)
	assert_not_null(editor)
	assert_true(editor.world_economy, "in a Survivor world the host takes the gold")
	assert_eq(editor.process_mode, Node.PROCESS_MODE_INHERIT, "it runs while the game is paused (the menu is ALWAYS)")
	editor.save_profile = func() -> void: pass
	editor.done_button.pressed.emit()
	await wait_process_frames(1)
	assert_not_null(_button(pause, "RESUME"), "back to the pause buttons")


func test_a_sandbox_pause_menu_editor_uses_the_profile_gold() -> void:
	Game.mode = ModeRules.SANDBOX
	var pause := PauseMenu.new()
	add_child_autofree(pause)
	pause.call("_show_avatar")
	await wait_process_frames(1)
	assert_false(_editor(pause).world_economy, "Sandbox gold never pays; the profile's Survivor gold does")
