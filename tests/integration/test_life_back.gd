extends GutTest
## L1's follow-up (Life L2, owner #112): Android Back inside a practice room asks "Leave the practice?" (the room's own
## calm card: CARRY ON or LEAVE) instead of leaving the School; a second Back carries on; LEAVE ends the practice calmly
## (nothing lost) and Life is still there. Back with no room open still steps back through the menu as before.

var menu: Node


func after_each() -> void:
	if is_instance_valid(menu):
		for h in get_tree().get_nodes_in_group(LifeRoomHost.GROUP):
			(h as LifeRoomHost).close()
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _life_in_the_menu() -> LifeScreen:
	Profile.data.life.track = "little"
	Profile.data.life.set_skill("calm_corner.little", {"b": 1, "q": 4})   # the before-check done: straight into the room
	menu = load("res://ui/menus/menu.tscn").instantiate()
	menu.set("quit_game", func() -> void: pass)
	add_child_autofree(menu)
	await wait_process_frames(3)
	menu.call("_show_school")
	await wait_process_frames(2)
	var school: SchoolScreen = menu.find_children("*", "SchoolScreen", true, false)[0]
	school.show_life()
	await wait_process_frames(2)
	return school.life


func _back() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await wait_process_frames(2)


func test_back_in_a_room_asks_leave_the_practice_and_the_school_stays() -> void:
	var life := await _life_in_the_menu()
	life.start_experience("calm_corner", "little", false)
	await wait_until(func() -> bool: return is_instance_valid(life.host) and life.host.hud != null, 2.0, "the room")
	assert_true(LifeRoomHost.any_open(get_tree()))
	await _back()
	assert_true(is_instance_valid(life) and life.is_inside_tree(), "the School and Life are still there")
	assert_true(life.host.hud.break_open(), "the room's calm card")
	assert_eq(life.host.hud.break_words.text, LifeRoomHud.LEAVE_WORDS, "Leave the practice?")
	assert_eq(life.host.hud.stop_button.text, "LEAVE")
	await _back()
	assert_false(life.host.hud.break_open(), "a second Back carries on")
	await _back()
	life.host.hud.stop_button.pressed.emit()
	await wait_process_frames(2)
	assert_eq(life.page, LifeScreen.CALM, "LEAVE: the calm words, nothing lost")
	assert_false(LifeRoomHost.any_open(get_tree()))


func test_i_need_a_break_keeps_its_own_words() -> void:
	var life := await _life_in_the_menu()
	life.start_experience("calm_corner", "little", false)
	await wait_until(func() -> bool: return is_instance_valid(life.host) and life.host.hud != null, 2.0, "the room")
	life.host.hud.open_break()
	assert_eq(life.host.hud.break_words.text, LifeRoomHud.BREAK_WORDS)
	assert_eq(life.host.hud.stop_button.text, "STOP FOR NOW")


func test_back_without_a_room_still_leaves_the_school() -> void:
	var life := await _life_in_the_menu()
	assert_false(LifeRoomHost.any_open(get_tree()))
	await _back()
	await wait_process_frames(2)
	assert_false(is_instance_valid(life) and life.is_inside_tree() and not life.is_queued_for_deletion(),
		"the menu stepped back as before")
