extends GutTest
## M2 Task 17 (spec §5.15, research O1 and A4): a HUD for a child's thumb. On the emulator's 2400 × 1080
## screen and a small 16:9 phone, in Sandbox and in Survivor, awake, riding (M3 Task 20a: HOP OFF, UP and
## DOWN) and asleep: every HUD button on the screen shows a picture with its word under it; JUMP and
## ATTACK are at least 200 px in the 1280 × 720
## design space (JUMP 225, about 2 cm on a phone), every other button at least 135 on its short side;
## no two buttons overlap, none covers the joystick's area or the hotbar, and the hearts, the eye, the
## Brave badge, the gold, the name and the wave and boss lines stay clear of every button and of each
## other. Buttons used now and then (CAM, SIZE, MIRROR, UNDO, emotes, photos, LAB) live in the MORE
## panel, beside the MORE button, as big as the others.

const SCREENS: Array[Vector2i] = [Vector2i(2400, 1080), Vector2i(1334, 750)]

var _window_size: Vector2i
var _mode_before: StringName
var _access := {}   # M5 Task 1: the profile's button size, hand and moves, put back after each test
var _moves := {}


class AirWorld:
	extends WorldService

	func get_block(_pos: Vector3i) -> int:
		return BlockIds.AIR


func before_all() -> void:
	_window_size = get_window().size
	_mode_before = Game.mode


func after_all() -> void:
	get_window().size = _window_size
	Game.mode = _mode_before


func before_each() -> void:
	for key: String in ["button_size", "left_handed"]:
		_access[key] = Profile.data.settings[key]
	_moves = Profile.data.hud_moves


func after_each() -> void:
	Game.mode = _mode_before
	for key: String in _access:
		Profile.data.settings[key] = _access[key]
	Profile.data.hud_moves = _moves
	HudLayout.reset()


func _player() -> Player:
	var w := AirWorld.new()
	autofree(w)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	return p


## A HUD the way the sandbox builds it on a phone (FPS on: the most crowded), holding a sword. M5 Task 1: at a button
## size, for a hand.
func _hud(mode: StringName, screen: Vector2i, size_step: StringName = HudLayout.NORMAL, left := false) -> Hud:
	get_window().size = screen
	Game.mode = mode
	Profile.data.settings.button_size = String(size_step)
	Profile.data.settings.left_handed = left
	var p := _player()
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(p, "Kid", true, true)
	hud.add_health_controls()
	hud.add_revive_controls()
	hud.add_sleep_controls()
	hud.add_secret_controls(null)
	hud.add_ride_controls()   # M3 Task 20a
	hud.show_difficulty_badge(DifficultyRules.BRAVE)
	hud.add_game_clock()   # Survivor games (spec §12.18)
	hud.game_clock.show_build(DayCycle.NOON, 3, 5, ShelterRules.OPEN)
	hud.interactor.set_slot_block(0, ItemIds.SWORD)
	hud.show_race_state({"on": true, "armed": false, "elapsed": 72300, "coins": 99, "event": "go"})   # M3 Task 7
	await wait_process_frames(3)
	return hud


## Every button a child can tap right now (the hotbar's slots are the hotbar's).
func _buttons(hud: Hud) -> Array[Control]:
	var out: Array[Control] = []
	for n in hud.find_children("*", "Control", true, false):
		var c := n as Control
		if (c is TouchButton or c is BaseButton) and c.is_visible_in_tree() and not hud.hotbar.is_ancestor_of(c):
			out.append(c)
	return out


func _name(c: Control) -> String:
	return "%s(%s)" % [c.get("text") if c.get("text") else c.get_class(), c.name]


func _labels(hud: Hud) -> Dictionary:
	return {"hearts": hud.hearts, "eye": hud.stealth_meter, "brave": hud.brave_badge, "gold": hud.gold_counter,
		"name": hud.username_label, "wave": hud.wave_line, "boss": hud.boss_bar, "potions": hud.potion_timers,
		"compass": hud.compass, "fps": hud.fps_label, "race clock": hud.race_clock, "game": hud.game_line,   # M3 Task 7 (under wave and boss), M4 H
		"game_clock": hud.game_clock}   # M3 Task 22 (Monster Wave)


func _check(hud: Hud, what: String) -> void:
	var view := Rect2(Vector2.ZERO, hud.get_viewport_rect().size)
	var buttons := _buttons(hud)
	assert_gt(buttons.size(), 8, "%s: the HUD's buttons are there" % what)
	var main: Array[Control] = [hud.jump_button, hud.attack_button]
	var thumbs: Array[Control] = [hud.crouch_button, hud.fly_down_button, hud.glide_button]   # M5 Task 1: they grow too
	var f := HudLayout.factor()
	for b: Control in main:
		assert_true(b.is_visible_in_tree(), "%s: %s shows" % [what, _name(b)])
	for i in buttons.size():
		var b := buttons[i]
		var r := b.get_global_rect()
		var least := HudLayout.MAIN_MIN * f if main.has(b) else HudLayout.BUTTON_MIN * (f if thumbs.has(b) else 1.0)
		least -= 0.5   # BIG's 148.5 is drawn 149
		assert_gte(minf(r.size.x, r.size.y), least, "%s: %s is big enough (%s)" % [what, _name(b), r.size])
		assert_true(view.encloses(r), "%s: %s is on the screen (%s)" % [what, _name(b), r])
		assert_true(b is TouchButton, "%s: %s is a HUD touch button" % [what, _name(b)])
		if b is TouchButton:
			var t := b as TouchButton
			assert_true(HudIcons.knows(t.symbol), "%s: %s shows a picture" % [what, _name(b)])
			assert_ne(t.text, "", "%s: %s has its word" % [what, _name(b)])
		assert_false(r.intersects(hud.joystick.get_global_rect()), "%s: %s is clear of the joystick" % [what, _name(b)])
		assert_false(r.intersects(hud.hotbar.get_global_rect()), "%s: %s is clear of the hotbar" % [what, _name(b)])
		for other in buttons.slice(i + 1):
			assert_false(r.intersects(other.get_global_rect()), "%s: %s overlaps %s" % [what, _name(b), _name(other)])
	assert_gte(minf(hud.jump_button.size.x, hud.jump_button.size.y), HudLayout.JUMP * f - 0.5, "%s: JUMP about 2 cm" % what)
	assert_almost_eq(hud.joystick.joystick_size, HudLayout.STICK * f, 0.01, "%s: the stick grows with the buttons" % what)
	var stick := hud.joystick.get_global_rect()
	assert_gte(minf(stick.size.x, stick.size.y), hud.joystick.joystick_size, "%s: the stick fits its area" % what)
	var labels := _labels(hud)
	for key: String in labels:
		var r := (labels[key] as Control).get_global_rect()
		assert_true(view.encloses(r), "%s: the %s is on the screen (%s)" % [what, key, r])
		for b in buttons:
			assert_false(r.intersects(b.get_global_rect()), "%s: the %s is clear of %s" % [what, key, _name(b)])
		for other: String in labels:
			if other > key and not (key in ["boss", "wave", "game"] and other in ["boss", "wave", "game"]):   # never together
				assert_false(r.intersects((labels[other] as Control).get_global_rect()),
					"%s: the %s is clear of the %s" % [what, key, other])


## M5 Task 1: at every button size (NORMAL, BIG, BIGGER) and for both hands.
func test_every_button_is_big_with_a_picture_and_nothing_overlaps() -> void:
	for size_step: StringName in HudLayout.STEPS:
		for left: bool in [false, true]:
			await _every_button_at(size_step, left)


func _every_button_at(size_step: StringName, left: bool) -> void:
	for screen in SCREENS:
		for mode: StringName in [ModeRules.SANDBOX, ModeRules.SURVIVOR]:
			var hud := await _hud(mode, screen, size_step, left)
			var what := "%s %s %s %s" % [screen, mode, size_step, "left" if left else "right"]
			hud.show_sleep_button(true)                  # beside a bed
			hud.show_help(true, 0.0)                     # a friend waits for help
			hud.team_photo_button.visible = true         # M4 H: a boss was just beaten
			hud.show_ride_button(true)                   # M3 Task 20a: next to a saddled buddy
			await wait_process_frames(2)
			_check(hud, "%s awake" % what)
			assert_true(hud.sleep_button.is_visible_in_tree() and hud.help_button.is_visible_in_tree())
			assert_true(hud.team_photo_button.is_visible_in_tree())
			assert_true(hud.ride_button.is_visible_in_tree())
			hud.show_ride_button(true, true)             # riding: HOP OFF
			hud.set_ride_up_down(true)                   # a dragon: UP and DOWN
			await wait_process_frames(2)
			_check(hud, "%s riding" % what)
			assert_eq(hud.ride_button.text, "HOP OFF")
			hud.set_ride_up_down(false)
			hud.show_ride_button(false)
			hud.show_help(false, 0.0)
			hud.show_sleep_button(true, "WAKE UP")
			hud.set_sleeping(true)
			await wait_process_frames(2)
			_check(hud, "%s asleep" % what)
			assert_true(hud.stop_button.is_visible_in_tree())
			hud.queue_free()
			await wait_process_frames(1)


func test_the_rare_buttons_live_in_the_more_panel() -> void:
	for mode: StringName in [ModeRules.SANDBOX, ModeRules.SURVIVOR]:
		var hud := await _hud(mode, SCREENS[0])
		var rare: Array[TouchButton] = [hud.emote_button, hud.photo_button, hud.camera_button, hud.size_button,
			hud.mirror_button, hud.undo_button]
		if mode == ModeRules.SANDBOX:
			rare.append(hud.lab_button)
		assert_eq(hud.more.buttons(), rare, "%s: in this order, and nothing else" % mode)
		for b: TouchButton in [hud.jump_button, hud.attack_button, hud.crouch_button, hud.pause_button,
				hud.chat.button, hud.book_button, hud.physics_button, hud.more_button]:
			assert_true(b.is_visible_in_tree(), "%s: %s stays on the screen" % [mode, b.text])
			assert_false(hud.more.is_ancestor_of(b))
		for b in rare:
			assert_false(b.is_visible_in_tree(), "%s: %s waits in the closed panel" % [mode, b.text])
		hud.queue_free()
		await wait_process_frames(1)


## M5 Task 1: the left hand's MORE is top left, and its panel opens on its right.
func test_the_more_panel_opens_beside_more_with_big_buttons() -> void:
	for left: bool in [false, true]:
		await _more_panel_for(left)


func _more_panel_for(left: bool) -> void:
	for screen in SCREENS:
		for mode: StringName in [ModeRules.SANDBOX, ModeRules.SURVIVOR]:
			var hud := await _hud(mode, screen, HudLayout.NORMAL, left)
			var what := "%s %s %s" % [screen, mode, "left" if left else "right"]
			assert_false(hud.more.is_open())
			hud.more_button.pressed.emit()
			await wait_process_frames(2)
			UiMotion.settle(hud.more)   # owner #94: measured at rest, not mid-pop
			assert_true(hud.more.is_open(), what)
			assert_true(hud.more_button.selected, "%s: MORE lights up while open" % what)
			var view := Rect2(Vector2.ZERO, hud.get_viewport_rect().size)
			var box := hud.more.box.get_global_rect()
			assert_true(view.encloses(box), "%s: the panel is on the screen (%s)" % [what, box])
			assert_false(box.intersects(hud.more_button.get_global_rect()), "%s: MORE stays in sight" % what)
			if left:
				assert_gt(box.get_center().x, hud.more_button.get_global_rect().end.x, "%s: beside MORE, on its right" % what)
			else:
				assert_lt(box.get_center().x, hud.more_button.get_global_rect().position.x, "%s: beside MORE, on its left" % what)
			var inside := hud.more.buttons()
			for b in inside:
				var r := b.get_global_rect()
				assert_true(b.is_visible_in_tree())
				assert_gte(minf(r.size.x, r.size.y), HudLayout.BUTTON_MIN, "%s: %s is big" % [what, b.text])
				assert_true(box.encloses(r), "%s: %s is in the box" % [what, b.text])
				assert_true(HudIcons.knows(b.symbol), "%s: %s shows a picture" % [what, b.text])
				assert_ne(b.text, "", "%s: %s has a word" % [what, b.text])
				for other in inside:
					if other != b:
						assert_false(r.intersects(other.get_global_rect()), "%s: %s overlaps %s" % [what, b.text, other.text])
			assert_has(hud.look_area.blockers, hud.more.box, "a touch on the panel never builds")
			hud.more_button.pressed.emit()
			assert_false(hud.more.is_open(), "%s: MORE again closes it" % what)
			assert_false(hud.more_button.selected)
			hud.queue_free()
			await wait_process_frames(1)


func test_an_open_overlay_closes_the_more_panel() -> void:
	var hud := await _hud(ModeRules.SURVIVOR, SCREENS[0])
	hud.more.open()
	var trader := Trader.new()
	trader.setup({"pos": Vector3.ZERO, "yaw": 0.0})
	add_child_autofree(trader)
	hud.open_shop(trader)
	assert_false(hud.more.is_open(), "the shop, and no other overlay")
	hud.shop.close()
	hud.more.open()
	var totem := Totem.new()
	add_child_autofree(totem)
	hud.open_totem(totem)
	assert_false(hud.more.is_open(), "the Totem's panel, and no other overlay")
	hud.totem_panel.close()
	hud.more.open()
	assert_true(hud.close_more())
	assert_false(hud.more.is_open(), "Android Back closes it")
	assert_false(hud.close_more(), "nothing left to close")


func test_the_knock_out_words_stay_above_get_up() -> void:
	for screen in SCREENS:
		var hud := await _hud(ModeRules.SURVIVOR, screen)
		hud.knockout_overlay.knock_out("You were knocked out!", KnockoutRules.TIPS[0])
		hud.get_up_button.visible = true
		await wait_process_frames(2)
		var words := hud.knockout_overlay.words_rect()
		assert_gt(words.size.y, 100.0, "the message and its tip")
		assert_lte(words.end.y, hud.get_up_button.get_global_rect().position.y, "%s: GET UP is under the words" % screen)
		assert_gte(words.position.y, 96.0 + 50.0, "%s: under the toasts" % screen)
		hud.queue_free()
		await wait_process_frames(1)


func test_the_theater_keeps_its_buttons_to_itself() -> void:
	for size_step: StringName in HudLayout.STEPS:   # M5 Task 1: every button size, both hands
		for left: bool in [false, true]:
			await _theater_at(size_step, left)


func _theater_at(size_step: StringName, left: bool) -> void:
	var list := TheaterChannels.load_path(TheaterChannels.SAMPLE_PATH)
	for screen in SCREENS:
		var hud := await _hud(ModeRules.SANDBOX, screen, size_step, left)
		var panel := TheaterPanel.new()
		panel.list = list
		var profile := ProfileData.new()
		profile.age_band = AgeBand.TEEN_PLUS
		panel.profile = profile
		panel.save_profile = func() -> void: pass
		add_child_autofree(panel)
		await wait_process_frames(2)
		panel.open()
		hud.set_theater_open(true, panel)   # M5 Task 1: the HUD knows where the Theater's buttons are
		await wait_process_frames(2)
		var theirs := panel.find_children("*", "Button", true, false).filter(
			func(b: Node) -> bool: return (b as Control).is_visible_in_tree())
		assert_gt(theirs.size(), 3, "NEXT, BACK, EXIT and the channels")
		for mine in _buttons(hud):
			for b: Button in theirs:
				assert_false(mine.get_global_rect().intersects(b.get_global_rect()),
					"%s %s %s: %s is clear of the Theater's %s" % [screen, size_step, "left" if left else "right", _name(mine),
					b.text.replace("\n", " ")])
		if size_step == HudLayout.NORMAL and not left:
			assert_true(hud.jump_button.is_visible_in_tree(), "JUMP and the joystick stay")
		assert_true(hud.joystick.is_visible_in_tree(), "the stick stays")
		panel.close()
		hud.set_theater_open(false)
		await wait_process_frames(2)
		assert_true(hud.book_button.visible and hud.physics_button.visible and hud.more_button.visible,
			"%s: back after the Theater" % screen)
		for b: Control in [hud.jump_button, hud.attack_button, hud.crouch_button]:   # M5 Task 1: the thumbs come back too
			assert_true(b.is_visible_in_tree(), "%s %s %s: %s back after the Theater" % [screen, size_step, left, _name(b)])
		hud.queue_free()
		await wait_process_frames(1)


# --- The table itself ---

func test_every_spot_is_on_a_16_9_and_the_emulators_screen_and_mirrors_onto_it() -> void:
	for screen: Vector2 in [Vector2(1280, 720), Vector2(1600, 720)]:
		var view := Rect2(Vector2.ZERO, screen)
		for spot: StringName in HudLayout.SPOTS:
			var s: Array = HudLayout.SPOTS[spot]
			var r := HudLayout.rect(spot, screen, Vector2(1, 1))   # own-size spots: at least their corner
			assert_true(view.encloses(r), "%s on %s: %s" % [spot, screen, r])
			if (s[2] as Vector2) == Vector2.ZERO:
				continue
			var m: Array = HudLayout.mirrored(s)
			var mr := Rect2((m[0] as Vector2) * screen + (m[1] as Vector2), m[2])
			assert_true(view.encloses(mr), "%s mirrored: %s" % [spot, mr])
			assert_almost_eq(mr.get_center().x, screen.x - r.get_center().x, 0.01, "%s mirrored across the middle" % spot)
	var jump: Array = HudLayout.SPOTS[&"jump"]
	var big: Array = HudLayout.scaled(jump, 1.2)
	assert_eq(big[2], (jump[2] as Vector2) * 1.2, "bigger buttons (M5)")
	assert_eq(big[0], jump[0], "from the same corner")


# --- Real touches (the HUD in its own 1280 × 720 view, touches pushed the way the engine sends them) ---

func _view_hud() -> Array:
	var view := SubViewport.new()
	view.size = Vector2i(1280, 720)
	add_child_autofree(view)
	var hud := Hud.new()
	view.add_child(hud)
	await wait_process_frames(2)
	return [view, hud]


func _touch(view: SubViewport, index: int, pos: Vector2, pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = index
	t.position = pos
	t.pressed = pressed
	view.push_input(t, true)


func test_a_tap_on_more_opens_it_and_a_tap_on_emote_opens_the_wheel() -> void:
	var a: Array = await _view_hud()
	var view: SubViewport = a[0]
	var hud: Hud = a[1]
	var more_at := hud.more_button.get_global_rect().get_center()
	_touch(view, 0, more_at, true)
	_touch(view, 0, more_at, false)
	assert_true(hud.more.is_open(), "a tap on MORE opens the panel")
	assert_false(hud.more_button.is_down(), "and MORE lets go of the finger")
	await wait_process_frames(2)
	var emote_at := hud.emote_button.get_global_rect().get_center()
	assert_true(hud.more.box.get_global_rect().has_point(emote_at), "the emote button is in the box")
	_touch(view, 1, emote_at, true)
	_touch(view, 1, emote_at, false)
	assert_false(hud.more.is_open(), "it opens something else: the panel closes")
	assert_true(hud.emote_wheel.visible, "the wheel stays open after the finger lifts")
	assert_false(hud.emote_button.is_down())


## Owner feedback #32 ("i cannt pause the game"): the HUD pass (M2 Task 17) dropped PAUSE's one
## connection, so a tap did nothing. Every button a child taps must do what it says: a real tap on PAUSE
## asks for the pause menu.
func test_a_tap_on_pause_asks_for_the_pause_menu() -> void:
	var a: Array = await _view_hud()
	var view: SubViewport = a[0]
	var hud: Hud = a[1]
	watch_signals(hud)
	var at := hud.pause_button.get_global_rect().get_center()
	_touch(view, 0, at, true)
	_touch(view, 0, at, false)
	assert_signal_emit_count(hud, "pause_requested", 1)


func test_a_tap_outside_the_box_only_closes_it() -> void:
	var a: Array = await _view_hud()
	var view: SubViewport = a[0]
	var hud: Hud = a[1]
	hud.more.open()
	await wait_process_frames(2)
	var size_at := hud.size_button.get_global_rect().get_center()
	_touch(view, 0, size_at, true)
	_touch(view, 0, size_at, false)
	assert_true(hud.more.is_open(), "SIZE keeps the panel open, to see what changed")
	var jump_at := hud.jump_button.get_global_rect().get_center()
	_touch(view, 1, jump_at, true)
	assert_false(hud.more.is_open(), "a tap anywhere else closes it")
	assert_false(Input.is_action_pressed(&"jump"), "and does nothing else")
	assert_false(hud.jump_button.is_down())
	_touch(view, 1, jump_at, false)
	_touch(view, 2, jump_at, true)
	assert_true(hud.jump_button.is_down(), "the next tap jumps")
	_touch(view, 2, jump_at, false)
	Input.action_release(&"jump")


# --- The pictures ---

## Draws every picture HudIcons knows side by side (an engine error while drawing fails the test).
class IconSheet:
	extends Control
	var drawn: Array[StringName] = []

	func _draw() -> void:
		for i in HudIcons.SYMBOLS.size():
			HudIcons.draw(self, HudIcons.SYMBOLS[i], Rect2(Vector2(8 + i * 72, 8), Vector2(64, 64)))
			drawn.append(HudIcons.SYMBOLS[i])


func test_every_picture_draws() -> void:
	var sheet := IconSheet.new()
	sheet.size = Vector2(HudIcons.SYMBOLS.size() * 72 + 16, 80)
	add_child_autofree(sheet)
	await wait_process_frames(2)
	assert_eq(sheet.drawn.slice(0, HudIcons.SYMBOLS.size()), HudIcons.SYMBOLS, "every picture, once per draw")
	for s: StringName in Hud.MODE_SYMBOLS.values():
		assert_true(HudIcons.knows(s), "the WALK button's %s" % s)


## M3 Task 14a: the GLIDE context button (spot "glide") shows in the air with a glider, on every screen and
## in both modes, big, with its picture and word, clear of every other button and label; DROP while gliding.
func test_the_glide_button_shows_in_the_air_clear_of_everything() -> void:
	var inv_before := Session.my_inventory
	Session.my_inventory = Inventory.new()
	Session.my_inventory.add(ItemIds.GLIDER, 1)   # Survivor: a glider in the bag (Sandbox always has one)
	for size_step: StringName in HudLayout.STEPS:   # M5 Task 1: every button size, both hands
		for left: bool in [false, true]:
			await _glide_at(size_step, left)
	Session.my_inventory = inv_before


func _glide_at(size_step: StringName, left: bool) -> void:
	for screen in SCREENS:
		for mode: StringName in [ModeRules.SANDBOX, ModeRules.SURVIVOR]:
			var hud := await _hud(mode, screen, size_step, left)
			hud.setup_gadgets(hud.player)
			hud.player._spawned = true               # in the air: AirWorld has no ground
			await wait_process_frames(2)
			assert_true(hud.glide_button.is_visible_in_tree(), "%s %s: GLIDE shows in the air" % [screen, mode])
			assert_eq(hud.glide_button.text, "GLIDE")
			_check(hud, "%s %s %s %s gliding" % [screen, mode, size_step, "left" if left else "right"])
			hud.player.open_glider()
			await wait_process_frames(2)
			assert_eq(hud.glide_button.text, "DROP", "while gliding it folds the glider")
			hud.player._spawned = false
			hud.player.toggle_glider()
			await wait_process_frames(2)
			assert_false(hud.glide_button.is_visible_in_tree(), "on the ground (not falling) it is gone")
			hud.queue_free()
			await wait_process_frames(1)


# --- M5 Task 1: button sizes, the left hand, moved controls (spec §15.1a) ---

## Every placed control sits where the table says now (a relayout placed them all again).
func _placed_as_the_table(hud: Hud, what: String) -> void:
	var screen := hud.get_viewport_rect().size
	for b: Control in [hud.jump_button, hud.attack_button, hud.crouch_button, hud.fly_down_button, hud.glide_button,
			hud.joystick, hud.pause_button, hud.chat.button, hud.more_button, hud.book_button]:
		var m: Array = b.get_meta(HudLayout.PLACED)
		assert_eq(b.get_global_rect(), HudLayout.rect(m[0], screen, m[1]), "%s: %s" % [what, _name(b)])


func test_changing_the_settings_places_the_hud_again() -> void:
	var hud := await _hud(ModeRules.SURVIVOR, SCREENS[1])
	var jump := hud.jump_button.get_global_rect()
	assert_gt(jump.get_center().x, 640.0, "JUMP right at first")
	Profile.data.settings.button_size = "bigger"
	Profile.data.settings.left_handed = true
	Game.settings_applied.emit(Profile.data.settings)
	await wait_process_frames(2)
	assert_eq(HudLayout.step, HudLayout.BIGGER)
	assert_true(HudLayout.left_handed)
	_placed_as_the_table(hud, "bigger, left")
	assert_lt(hud.jump_button.get_global_rect().get_center().x, 640.0, "JUMP under the left thumb")
	assert_gt(hud.joystick.get_global_rect().get_center().x, 640.0, "the stick under the right thumb")
	assert_almost_eq(hud.joystick.joystick_size, HudLayout.STICK * 1.2, 0.01)
	assert_gte(hud.jump_button.size.x, HudLayout.JUMP * 1.2 - 0.5)
	assert_eq(hud.username_label.horizontal_alignment, HORIZONTAL_ALIGNMENT_LEFT, "the name reads from its edge")
	Profile.data.settings.button_size = "normal"
	Profile.data.settings.left_handed = false
	Game.settings_applied.emit(Profile.data.settings)
	await wait_process_frames(2)
	_placed_as_the_table(hud, "back to normal")
	assert_eq(hud.jump_button.get_global_rect(), jump)


func test_a_moved_jump_is_where_the_child_put_it_and_a_bad_move_is_not() -> void:
	Profile.data.hud_moves = {"normal": {"jump": [-10.0, -8.0], "attack": [0.0, 150.0]}}   # ATTACK onto JUMP: ignored
	var hud := await _hud(ModeRules.SANDBOX, SCREENS[1])
	var screen := hud.get_viewport_rect().size
	var home: Array = HudLayout.SPOTS[&"jump"]
	var moved := (home[0] as Vector2) * screen + (home[1] as Vector2) + Vector2(-10, -8)
	assert_eq(hud.jump_button.get_global_rect().position, moved)
	var attack: Array = HudLayout.SPOTS[&"attack"]
	assert_eq(hud.attack_button.get_global_rect().position, (attack[0] as Vector2) * screen + (attack[1] as Vector2),
		"ATTACK stays home")
	Profile.data.settings.left_handed = true
	Game.settings_applied.emit(Profile.data.settings)
	await wait_process_frames(2)
	var r := hud.jump_button.get_global_rect()
	assert_eq(r.position.x, screen.x - moved.x - r.size.x, "the left hand sees the move in a mirror")


func test_the_left_hands_chat_bar_runs_from_the_left_edge_to_pause() -> void:
	for left: bool in [false, true]:
		var hud := await _hud(ModeRules.SANDBOX, SCREENS[1], HudLayout.NORMAL, left)
		hud.chat.open()
		await wait_process_frames(2)
		var bar := hud.chat._bar.get_global_rect()
		var pause := hud.pause_button.get_global_rect()
		assert_false(bar.intersects(pause), "the bar never covers pause")
		assert_false(bar.intersects(hud.chat.button.get_global_rect()))
		if left:
			assert_lt(bar.position.x, 40.0, "from the left edge")
			assert_lt(bar.end.x, pause.position.x)
		else:
			assert_gt(bar.position.x, pause.end.x)
		var lines: Rect2 = hud.chat._history_area()
		var view := hud.get_viewport_rect()
		assert_true(view.encloses(lines), "the lines on the screen")
		assert_false(lines.intersects(hud.chat.button.get_global_rect()), "the lines clear of CHAT")
		hud.chat.close()
		hud.queue_free()
		await wait_process_frames(1)
