extends GutTest
## M5 Task 6 (the whole-game review, a reviewer's finding): Android Back while MOVE BUTTONS (M5 Task 1's HudEditor, on a
## layer of its own over everything) is open. Android's Back reaches the game as a notification every node gets
## (NOTIFICATION_WM_GO_BACK_REQUEST), not as the ui_cancel the editor listened to, so it went past the editor: in a
## world it closed the pause menu under it (the game ran on, unseen, behind the editor), and at the main menu it took
## the menu back to its first screen under the editor, freeing the settings panel that opened it. Back now closes the
## editor (nothing saved) and nothing else, and an editor never outlives the settings panel that opened it.

var _moves := {}


func before_each() -> void:
	_moves = Profile.data.hud_moves.duplicate(true)


func after_each() -> void:
	get_tree().paused = false
	Profile.data.hud_moves = _moves
	HudLayout.reset()
	for n in get_tree().root.get_children():
		if n is CanvasLayer and String(n.name).begins_with("HudEditorLayer"):
			n.free()


## The MOVE BUTTONS editors still open.
func _editors() -> Array[HudEditor]:
	var out: Array[HudEditor] = []
	for n in get_tree().root.find_children("HudEditor", "", true, false):
		if n is HudEditor and not n.is_queued_for_deletion():
			out.append(n as HudEditor)
	return out


func _settings(parent: Node) -> SettingsPanel:
	var s := SettingsPanel.new()
	s.saver = func() -> void: pass   # the profile file is shared by every worktree
	parent.add_child(s)
	return s


func _box() -> PanelContainer:
	var box := PanelContainer.new()
	box.theme = UiKit.theme()
	add_child_autofree(box)
	return box


func test_back_closes_move_buttons_and_saves_nothing() -> void:
	var s := _settings(_box())
	s.open_move_buttons()
	assert_eq(_editors().size(), 1)
	_editors()[0].notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await wait_process_frames(2)
	assert_eq(_editors().size(), 0, "Back closes MOVE BUTTONS")
	assert_eq(Profile.data.hud_moves, _moves, "nothing saved")


func test_back_in_a_world_closes_only_the_editor_and_the_game_stays_paused() -> void:
	var pause := PauseMenu.new()
	add_child_autofree(pause)
	var sandbox: Node = load("res://scenes/sandbox.gd").new()
	sandbox.set("pause_menu", pause)
	pause.open()
	var s := _settings(pause)
	s.open_move_buttons()
	assert_eq(_editors().size(), 1)
	sandbox.call("go_back")
	var still_paused := get_tree().paused
	var menu_shown := pause.visible
	var editors := _editors().size()
	await get_tree().process_frame   # a second press comes in a later frame (the tree's frames run while paused)
	await get_tree().process_frame
	sandbox.call("go_back")   # a second Back: the pause menu closes, as before
	var paused_after := get_tree().paused
	_free_sandbox(sandbox)
	assert_true(still_paused, "the world stays paused under the editor")
	assert_true(menu_shown, "the pause menu stays")
	assert_eq(editors, 0, "Back closed MOVE BUTTONS")
	assert_false(paused_after, "the next Back closes the pause menu")


func test_back_at_the_main_menu_closes_only_the_editor() -> void:
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_process_frames(3)
	menu.call("_show_settings")
	var s: SettingsPanel = null
	for n in menu.find_children("*", "", true, false):
		if n is SettingsPanel and not n.is_queued_for_deletion():
			s = n
	assert_not_null(s, "SETTINGS")
	if s == null:
		return
	s.open_move_buttons()
	assert_eq(_editors().size(), 1)
	menu.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await wait_process_frames(2)
	assert_eq(_editors().size(), 0, "Back closed MOVE BUTTONS")
	assert_true(is_instance_valid(s) and s.is_inside_tree() and not s.is_queued_for_deletion(),
		"and nothing else: SETTINGS is still there")


func test_the_editor_goes_with_the_settings_panel_that_opened_it() -> void:
	var box := _box()
	var s := _settings(box)
	s.open_move_buttons()
	assert_eq(_editors().size(), 1)
	box.free()   # the world (or the menu) closed under it: a LAN guest whose host quit
	await wait_process_frames(2)
	assert_eq(_editors().size(), 0, "no MOVE BUTTONS left over the next screen")


## A sandbox made without its scene (only its Back chain is used): its own member nodes are freed with it.
func _free_sandbox(sandbox: Node) -> void:
	for prop in sandbox.get_property_list():
		if int(prop.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and prop.name != "pause_menu":
			var v: Variant = sandbox.get(prop.name)
			if v is Node and is_instance_valid(v) and not (v as Node).is_inside_tree():
				(v as Node).free()
	sandbox.free()
