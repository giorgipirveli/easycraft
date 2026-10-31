extends GutTest
## Owner #79, #84, #86 (spec §25.3): the cockpit. Big controls a child's thumb finds (the THROTTLE lever, the round
## ACTION button saying what to do now, OUTSIDE/INSIDE, MENU) that fit a phone's screen and a PC's, never on top of one
## another or of the words; the keys on a PC (WASD or the arrows steer, Shift the throttle, Space the action); a drag
## anywhere else steers; the dials in words a child reads.

const PC := {PlatformRules.WEB: true, PlatformRules.WEB_WINDOWS: true}
const PHONE := {PlatformRules.MOBILE: true, PlatformRules.ANDROID: true}

var cockpit: FlightCockpit
var holder: Control


func _make(screen: Vector2, platform: Dictionary, skippable: bool = true) -> FlightCockpit:
	holder = Control.new()
	holder.size = screen
	add_child_autofree(holder)
	cockpit = FlightCockpit.new()
	cockpit.platform = platform
	cockpit.skippable = skippable
	holder.add_child(cockpit)
	await wait_frames(2)
	cockpit._build_later()   # the screens come on its first frame; the test's frames are physics frames
	return cockpit


func after_each() -> void:
	for a: StringName in [&"rocket_steer_left", &"rocket_steer_up", &"rocket_throttle"]:
		Input.action_release(a)


func _controls() -> Dictionary:
	return {"throttle": cockpit.lever, "action": cockpit.action, "view": cockpit.view_button, "menu": cockpit.menu_button,
		"skip": cockpit.skip_button}


func test_it_fits_a_phone_and_a_pc_and_nothing_covers_anything() -> void:
	for pair: Array in [[PlatformRules.PHONE_CANVAS, PHONE], [PlatformRules.PC_CANVAS, PC]]:
		await _make(pair[0], pair[1])
		var screen := Rect2(Vector2.ZERO, pair[0])
		var rects := {}
		for n: String in _controls():
			var c: Control = _controls()[n]
			rects[n] = Rect2(c.position, c.size)
			assert_true(screen.encloses(rects[n]), "%s on the %s screen: %s" % [n, pair[0], rects[n]])
		var words := Rect2(cockpit._words_box.position, cockpit._words_box.get_combined_minimum_size())
		rects["words"] = words
		var names := rects.keys()
		for i in names.size():
			for j in range(i + 1, names.size()):
				assert_false((rects[names[i]] as Rect2).intersects(rects[names[j]]),
					"%s and %s apart on %s" % [names[i], names[j], pair[0]])
		for s: Control in cockpit.screens + [cockpit.fuel_screen, cockpit.hologram]:
			assert_true(screen.encloses(Rect2(s.position, s.get_combined_minimum_size().max(s.size))), "%s on screen" % s.name)
		holder.queue_free()
		await wait_frames(1)


func test_the_controls_are_big_enough_for_a_child() -> void:
	await _make(PlatformRules.PHONE_CANVAS, PHONE)
	assert_gte(cockpit.action.size.x, 180.0, "ACTION")
	assert_gte(cockpit.lever.size.x, 110.0, "THROTTLE")
	assert_gte(cockpit.lever.size.y, 300.0)
	for b: TouchButton in [cockpit.view_button, cockpit.menu_button, cockpit.skip_button]:
		assert_gte(b.size.y, 80.0, b.name)
		assert_gte(b.size.x, 110.0, b.name)


func test_skip_shows_only_on_a_repeat_visit() -> void:
	await _make(PlatformRules.PHONE_CANVAS, PHONE, false)
	assert_false(cockpit.skip_button.visible)


func test_the_action_button_says_what_to_do_now() -> void:
	await _make(PlatformRules.PHONE_CANVAS, PHONE)
	var cases := {FlightPlan.THROTTLE: "LIFT-OFF!", FlightPlan.STAGE: "STAGE", FlightPlan.BURN: "BURN",
		FlightPlan.LEGS: "LEGS", FlightPlan.PARACHUTE: "CHUTE"}
	for a: StringName in cases:
		cockpit.show_state({"waiting": a, "action": a, "done": false})
		assert_eq(cockpit.action.text, cases[a])
		assert_true(cockpit.action.waiting, "it glows")
	cockpit.show_state({"waiting": &"", "action": &"", "done": true})
	assert_false(cockpit.action.visible, "nothing to do: no button")


func test_a_pc_shows_its_keys_and_the_keys_fly() -> void:
	await _make(PlatformRules.PC_CANVAS, PC)
	assert_eq(cockpit.lever.key_word, "Shift")
	assert_eq(cockpit.action.key_word, "Space")
	Input.action_press(&"rocket_steer_left")
	Input.action_press(&"rocket_steer_up")
	Input.action_press(&"rocket_throttle")
	await wait_frames(20)
	assert_lt(cockpit.stick.x, -0.5, "A or the left arrow steers left")
	assert_gt(cockpit.stick.y, 0.5, "W or the up arrow: nose up")
	assert_gt(cockpit.throttle, 0.5, "Shift pushes the throttle")
	Input.action_release(&"rocket_throttle")
	Input.action_release(&"rocket_steer_left")
	Input.action_release(&"rocket_steer_up")
	await wait_frames(30)
	assert_eq(cockpit.throttle, 0.0, "let go, it springs back")
	assert_eq(cockpit.stick, Vector2.ZERO)
	await _make(PlatformRules.PHONE_CANVAS, PHONE)
	assert_eq(cockpit.lever.key_word, "", "a phone has no keys to show")


func test_a_drag_steers() -> void:
	await _make(PlatformRules.PHONE_CANVAS, PHONE)
	var from := Vector2(640, 300)   # the window: no control there
	var down := InputEventScreenTouch.new()
	down.index = 3
	down.position = from
	down.pressed = true
	cockpit._input(down)
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = from + Vector2(-FlightCockpit.DRAG_REACH, 0)
	cockpit._input(drag)
	await wait_frames(2)
	assert_almost_eq(cockpit.stick.x, -1.0, 0.01, "dragged a full reach left")
	var up := InputEventScreenTouch.new()
	up.index = 3
	up.position = drag.position
	up.pressed = false
	cockpit._input(up)
	await wait_frames(2)
	assert_eq(cockpit.stick, Vector2.ZERO)


func test_the_dials_read_like_a_child_reads() -> void:
	assert_eq(FlightCockpit.km(384400.0), "384,400")
	assert_eq(FlightCockpit.km(225000000.0), "225,000,000")
	assert_eq(FlightCockpit.km(7.8), "7.8")
	assert_eq(FlightCockpit.km(65.0), "65")
	assert_eq(FlightCockpit.km(0.0), "0.0")
	await _make(PlatformRules.PHONE_CANVAS, PHONE)
	cockpit.show_state({})
	cockpit.show_state({"dials": {"speed": FlightDials.LIGHT_SPEED, "light_speed": true, "height": 12.0,
		"height_of": "the Moon", "distance": -1.0, "clock": "3 days", "fuel": [1.0]}})
	assert_eq(cockpit.speed_value.text, "LIGHT SPEED!")
	assert_eq(cockpit.height_name.text, "HEIGHT ABOVE THE MOON")
	assert_eq(cockpit.dist_value.text, "far, far away")
	assert_eq(cockpit.clock_value.text, "TRIP: 3 days")
