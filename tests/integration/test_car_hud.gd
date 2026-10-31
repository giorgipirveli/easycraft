extends GutTest
## Owner #109: driving on a phone. In a car the HUD shows HOP OFF (the RIDE button), HORN and, for a flying car's driver,
## FLY / LAND, with UP and DOWN while it flies: every button big with a picture and its word, none over another one
## that can show with it (a friend waiting for help, TEAM PHOTO after a boss), clear of the joystick and the hotbar, at
## every button size, for both hands, on the emulator's screen and a small phone's. Next to a car the RIDE button says
## DRIVE with a car's picture.

const SCREENS: Array[Vector2i] = [Vector2i(2400, 1080), Vector2i(1334, 750)]

var _window_size: Vector2i
var _access := {}
var _moves := {}


class AirWorld:
	extends WorldService

	func get_block(_pos: Vector3i) -> int:
		return BlockIds.AIR


func before_all() -> void:
	_window_size = get_window().size


func after_all() -> void:
	get_window().size = _window_size


func before_each() -> void:
	for key: String in ["button_size", "left_handed"]:
		_access[key] = Profile.data.settings[key]
	_moves = Profile.data.hud_moves


func after_each() -> void:
	for key: String in _access:
		Profile.data.settings[key] = _access[key]
	Profile.data.hud_moves = _moves
	HudLayout.reset()


func _hud(screen: Vector2i, size_step: StringName, left: bool) -> Hud:
	get_window().size = screen
	Profile.data.settings.button_size = String(size_step)
	Profile.data.settings.left_handed = left
	var w := AirWorld.new()
	autofree(w)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(p, "Kid", true, true)
	hud.add_health_controls()
	hud.add_revive_controls()
	hud.add_sleep_controls()
	hud.add_secret_controls(null)
	hud.add_ride_controls()
	hud.add_car_controls()
	hud.add_game_clock()
	hud.game_clock.show_build(DayCycle.NOON, 3, 5, ShelterRules.OPEN)
	await wait_process_frames(3)
	return hud


func _buttons(hud: Hud) -> Array[Control]:
	var out: Array[Control] = []
	for n in hud.find_children("*", "Control", true, false):
		var c := n as Control
		if (c is TouchButton or c is BaseButton) and c.is_visible_in_tree() and not hud.hotbar.is_ancestor_of(c):
			out.append(c)
	return out


func _check(hud: Hud, what: String) -> void:
	var view := Rect2(Vector2.ZERO, hud.get_viewport_rect().size)
	var buttons := _buttons(hud)
	for b: Control in [hud.horn_button, hud.car_fly_button, hud.ride_button]:
		assert_true(b.is_visible_in_tree(), "%s: %s shows" % [what, (b as TouchButton).text])
	for i in buttons.size():
		var b := buttons[i]
		var r := b.get_global_rect()
		assert_gte(minf(r.size.x, r.size.y), HudLayout.BUTTON_MIN - 0.5, "%s: %s is big enough" % [what, b.name])
		assert_true(view.encloses(r), "%s: %s is on the screen" % [what, b.name])
		if b is TouchButton:
			assert_true(HudIcons.knows((b as TouchButton).symbol), "%s: %s shows a picture" % [what, b.name])
			assert_ne((b as TouchButton).text, "", "%s: %s has its word" % [what, b.name])
		assert_false(r.intersects(hud.joystick.get_global_rect()), "%s: %s is clear of the joystick" % [what, b.name])
		assert_false(r.intersects(hud.hotbar.get_global_rect()), "%s: %s is clear of the hotbar" % [what, b.name])
		for other in buttons.slice(i + 1):
			assert_false(r.intersects(other.get_global_rect()), "%s: %s overlaps %s" % [what, b.name, other.name])


func test_driving_buttons_are_big_with_pictures_and_overlap_nothing() -> void:
	for size_step: StringName in HudLayout.STEPS:
		for left: bool in [false, true]:
			for screen in SCREENS:
				var hud := await _hud(screen, size_step, left)
				var what := "%s %s %s" % [screen, size_step, "left" if left else "right"]
				hud.show_ride_button(true, true)   # in a car: HOP OFF
				hud.horn_button.visible = true
				hud.car_fly_button.visible = true
				hud.set_ride_up_down(true)   # a flying car in the air: UP and DOWN
				hud.show_help(true, 0.0)
				hud.team_photo_button.visible = true
				await wait_process_frames(2)
				_check(hud, what)
				assert_eq(hud.ride_button.text, "HOP OFF")
				assert_eq(hud.jump_button.text, "UP")
				hud.queue_free()
				await wait_process_frames(1)


func test_next_to_a_car_ride_says_drive_with_a_car() -> void:
	var hud := await _hud(SCREENS[0], HudLayout.NORMAL, false)
	hud.show_ride_button(true, false, "DRIVE", &"car")
	assert_eq(hud.ride_button.text, "DRIVE")
	assert_eq(hud.ride_button.symbol, &"car")
	hud.show_ride_button(true, false, "GET IN", &"car")
	assert_eq(hud.ride_button.text, "GET IN")
	hud.show_ride_button(true, true)
	assert_eq(hud.ride_button.text, "HOP OFF")
	assert_eq(hud.ride_button.symbol, &"ride", "in it: the rides' HOP OFF")
	hud.show_ride_button(true)
	assert_eq(hud.ride_button.text, "RIDE", "a buddy again")
	assert_eq(hud.ride_button.symbol, &"ride")
	assert_true(HudIcons.knows(&"car") and HudIcons.knows(&"horn"))
