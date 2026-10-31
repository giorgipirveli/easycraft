extends GutTest
## Owner #101 (VR on the Meta Quest): when the headset loses the focus (the Quest's own menu, the headset taken off) the
## game's pause menu opens, as a phone's does when the app goes to the background; getting the focus back leaves it open
## (the child resumes when ready). Off VR nothing listens.

var menu: PauseMenu


func before_each() -> void:
	menu = PauseMenu.new()
	add_child_autofree(menu)
	await get_tree().process_frame


func after_each() -> void:
	if is_instance_valid(menu) and menu.visible:
		menu.close()
	get_tree().paused = false
	Vr.simulate(false)


func test_losing_the_headsets_focus_opens_the_pause_menu() -> void:
	assert_false(menu.visible)
	Vr.focus_changed.emit(false)
	assert_true(menu.visible, "the Quest's menu or the headset off: the game pauses")


func test_getting_the_focus_back_leaves_the_pause_menu_open() -> void:
	Vr.focus_changed.emit(false)
	Vr.focus_changed.emit(true)
	assert_true(menu.visible, "the child resumes when ready")


func test_an_open_pause_menu_stays_open_and_is_not_opened_twice() -> void:
	menu.open()
	watch_signals(menu)
	Vr.focus_changed.emit(false)
	assert_true(menu.visible)
	assert_signal_not_emitted(menu, "opened", "already open: no second save, no second sound")
