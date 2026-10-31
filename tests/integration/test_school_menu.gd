extends GutTest
## Owner #68 (spec §22.1): the main menu's SCHOOL, beside AVATAR and SETTINGS, opens the School inside the menu's panel;
## its BACK brings the main menu back. Every button of the School's pages is on the screen at 16:9 (1280 × 720) and on a
## 20:9 phone (2400 × 1080). The School here works on a private profile: the real one is never written.

const SCREENS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(2400, 1080)]

var menu: Node
var window: Vector2i


func before_all() -> void:
	window = get_window().size


func after_all() -> void:
	get_window().size = window
	Audio.stop_all()


func before_each() -> void:
	ParentGate.reset_tries()


func _open_menu(px: Vector2i) -> void:
	get_window().size = px
	menu = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_frames(3)
	menu.call("_show_main")
	await wait_frames(2)


func _button(text: String) -> Button:
	for b in menu.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b
	return null


func _school() -> SchoolScreen:
	for n in menu.find_children("*", "", true, false):
		if n is SchoolScreen and (n as SchoolScreen).is_inside_tree():
			return n
	return null


## Owner #122 (G0): for children the School's button says DISCOVER ("we are not school, we are something more").
func test_school_sits_beside_avatar_and_settings() -> void:
	await _open_menu(SCREENS[0])
	var school := _button("DISCOVER")
	var avatar := _button("AVATAR")
	assert_not_null(school, "DISCOVER on the main menu")
	assert_null(_button("SCHOOL"), "owner #122: never SCHOOL for children")
	assert_not_null(avatar)
	if school and avatar:
		assert_eq(school.get_global_rect().position.y, avatar.get_global_rect().position.y, "one row with AVATAR")
		assert_true(Rect2(Vector2.ZERO, menu.get_viewport().get_visible_rect().size).encloses(school.get_global_rect()))


func test_school_opens_and_its_back_returns_to_the_menu() -> void:
	await _open_menu(SCREENS[0])
	_button("DISCOVER").pressed.emit()
	await wait_frames(2)
	var screen := _school()
	assert_not_null(screen, "the School in the menu's panel")
	if screen == null:
		return
	screen.closed.emit()
	await wait_frames(2)
	assert_not_null(_button("SANDBOX\nBuild anything!"), "the main menu again")


func test_every_school_button_is_on_the_screen() -> void:
	for px in SCREENS:
		await _open_menu(px)
		_button("DISCOVER").pressed.emit()
		await wait_seconds(0.4)   # the panel pops in (a 0.18 s tween)
		var screen := _school()
		assert_not_null(screen)
		if screen == null:
			continue
		var mine := ProfileData.new()
		mine.school.grade = 4
		screen.profile = mine
		screen.save_profile = func() -> void: pass
		var pages := {
			"welcome": func() -> void: screen.show_welcome(),
			"map": func() -> void: screen.show_map("maths"),
			"unit": func() -> void: screen.show_unit("g4.maths.big_numbers"),
			"lesson": func() -> void: screen.show_lesson("g4.maths.big_numbers", 0),
			"round": func() -> void: screen.show_round("g4.maths.big_numbers"),
			"gate": func() -> void: screen.show_grown_ups(),
			"grown-ups": func() -> void: screen.show_grown_ups_page(),
		}
		var view := Rect2(Vector2.ZERO, menu.get_viewport().get_visible_rect().size)
		for name: String in pages:
			(pages[name] as Callable).call()
			await wait_frames(2)
			var shown := 0
			for b in screen.find_children("*", "Button", true, false):
				if (b as Control).is_visible_in_tree():
					shown += 1
					assert_true(view.encloses((b as Control).get_global_rect()), "%s %s: %s at %s" % [px, name,
						(b as Button).text, (b as Control).get_global_rect()])
			assert_gt(shown, 0, "%s %s shows buttons" % [px, name])
		menu.queue_free()
		await wait_frames(1)
