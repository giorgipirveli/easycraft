extends GutTest
## Owner #123: an installed Android app (the Quest's, the phone's) feeds the menu's note (ui/menus/update_note.gd, the
## web's "A new EasyCraft is ready!" RESTART) from its updater (autoloads/updater.gd). An app cannot restart itself (the
## engine's restart is the desktop's), so there the note has no RESTART and says the new game starts next time. The
## menu tells the updater it showed (the pack in use started the game: its tries clear) in the line that makes the note.

var update_is_ready := false


func test_an_installed_apps_note_says_next_time_and_has_no_restart() -> void:
	var n := UpdateNote.new(func() -> bool: return update_is_ready, Callable())
	add_child_autofree(n)
	n.poll()
	assert_false(n.visible, "nothing until a new game is ready")
	update_is_ready = true
	n.poll()
	assert_true(n.visible)
	assert_eq(n.words.text, UpdateRules.READY_WORDS)
	assert_false(n.restart_button.visible, "no RESTART where restarting does not work")


func test_the_webs_note_keeps_its_restart() -> void:
	var n := UpdateNote.new(func() -> bool: return true, func() -> void: pass)
	add_child_autofree(n)
	n.poll()
	assert_true(n.restart_button.visible)
	assert_eq(n.words.text, UpdateNote.WORDS)


func test_the_menu_tells_the_updater_and_lets_it_feed_the_note() -> void:
	var menu := FileAccess.get_file_as_string("res://ui/menus/menu.gd")
	assert_string_contains(menu, "UpdateNote.new(Updater.has_ready, Callable()) if Updater.menu_shown() else UpdateNote.new()")


func test_an_idle_updater_leaves_the_note_to_the_web() -> void:
	assert_false(Updater.menu_shown(), "the tests, the editor, the web: the page's note")
