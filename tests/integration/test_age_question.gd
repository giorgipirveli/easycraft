extends GutTest
## Owner #57: first launch asks "How old are you?" with a box and the game's number pad; OK keeps only the age band,
## then the name. No decades or years any more.

var menu: Node
var _saved_band: StringName


func before_each() -> void:
	_saved_band = Profile.data.age_band
	menu = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_process_frames(3)


func after_each() -> void:
	Profile.data.age_band = _saved_band


func _screen_buttons() -> Dictionary:
	var out := {}
	var center: Node = menu.get("_center")
	for b in center.find_children("*", "Button", true, false):
		if not b.is_queued_for_deletion():
			out[(b as Button).text] = b
	return out


func _screen_text() -> String:
	var text := ""
	var center: Node = menu.get("_center")
	for l in center.find_children("*", "Label", true, false):
		if not l.is_queued_for_deletion():
			text += (l as Label).text + "\n"
	return text


func _age(digits: String) -> void:
	menu.call("_show_age")
	await wait_process_frames(2)
	for d in digits:
		(_screen_buttons()[d] as Button).pressed.emit()
	await wait_process_frames(1)


func test_the_question_is_how_old_with_a_number_pad() -> void:
	menu.call("_show_age")
	await wait_process_frames(2)
	assert_string_contains(_screen_text(), "How old are you?")
	var buttons := _screen_buttons()
	for d in "0123456789":
		assert_true(buttons.has(d), "the pad has %s" % d)
	assert_true(buttons.has("OK"))
	assert_true((buttons["OK"] as Button).disabled, "OK waits for an age")
	assert_false(_screen_text().contains("When were you born"))


func test_a_child_of_nine_is_under_13_then_the_name() -> void:
	await _age("9")
	assert_string_contains(_screen_text(), "9")
	(_screen_buttons()["OK"] as Button).pressed.emit()
	await wait_process_frames(2)
	assert_eq(Profile.data.age_band, AgeBand.UNDER_13)
	assert_string_contains(_screen_text(), "Pick your name")


func test_fifteen_is_thirteen_plus() -> void:
	await _age("15")
	(_screen_buttons()["OK"] as Button).pressed.emit()
	await wait_process_frames(2)
	assert_eq(Profile.data.age_band, AgeBand.TEEN_PLUS)


func test_play_leads_to_the_age_question() -> void:
	menu.call("_show_start")
	await wait_process_frames(2)
	(_screen_buttons()["PLAY"] as Button).pressed.emit()
	await wait_process_frames(2)
	assert_string_contains(_screen_text(), "How old are you?")
