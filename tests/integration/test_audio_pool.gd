extends GutTest
## The Audio autoload's pools and buses (the audio pass, owner feedback #27): pooled players only (no
## player is ever made per sound), a cap on the same sound at once, far sounds skipped, every effect on
## the Effects bus whose volume is the SOUND EFFECTS setting, every UI button and HUD touch button
## clicking by itself, a clink when gold goes up and a pop when blocks come into the bag.

var _saved_sfx: float
var _saved_inventory: Inventory


func before_each() -> void:
	_saved_sfx = float(Profile.data.settings.get("sfx_volume", 0.8))
	_saved_inventory = Session.my_inventory
	Audio.stop_all()


func after_each() -> void:
	Profile.data.settings.sfx_volume = _saved_sfx
	Game.apply_settings()
	Session.my_inventory = _saved_inventory
	Audio.stop_all()


func after_all() -> void:
	Audio.stop_all()


func test_five_hundred_sounds_never_add_a_player() -> void:
	var children := Audio.get_child_count()
	var players := Audio.player_count()
	var names: Array = Audio.SOUNDS.keys()
	for i in 500:
		var at := Vector3(i % 7, 0, i % 5) if i % 2 == 0 else Vector3.INF
		Audio.play(names[i % names.size()], at)
		assert_lte(Audio.playing_count(), players)
	assert_eq(Audio.get_child_count(), children, "no player was added")
	assert_eq(Audio.player_count(), players)
	assert_lte(players, 20, "a small fixed pool")


func test_the_same_sound_at_once_is_capped() -> void:
	var before: int = Audio.played
	for i in 10:
		Audio.play(&"squish", Vector3(1, 0, 0))
	assert_eq(Audio.played - before, Audio.BURST, "ten slimes squishing at once are %d squishes" % Audio.BURST)


func test_sounds_far_from_the_listener_are_not_played() -> void:
	var cam := Camera3D.new()
	add_child_autofree(cam)
	cam.make_current()
	var before: int = Audio.played
	Audio.play(&"moo", Vector3(Audio.HEARING + 10.0, 0, 0))
	assert_eq(Audio.played, before, "too far to hear")
	Audio.play(&"moo", Vector3(5, 0, 0))
	assert_eq(Audio.played, before + 1)
	Audio.play(&"ding")
	assert_eq(Audio.played, before + 2, "flat UI sounds always play")


func test_effects_have_their_own_bus_under_master() -> void:
	var bus := AudioServer.get_bus_index(Audio.BUS)
	assert_gt(bus, 0)
	assert_eq(AudioServer.get_bus_send(bus), &"Master")
	for n in Audio.get_children():
		if n is AudioStreamPlayer:
			assert_eq((n as AudioStreamPlayer).bus, Audio.BUS)
		elif n is AudioStreamPlayer3D:
			assert_eq((n as AudioStreamPlayer3D).bus, Audio.BUS)


func test_the_sound_effects_volume_sets_the_effects_bus() -> void:
	var bus := AudioServer.get_bus_index(Audio.BUS)
	Profile.data.settings.sfx_volume = 0.3
	Game.apply_settings()
	assert_almost_eq(AudioServer.get_bus_volume_db(bus), linear_to_db(0.3), 0.01)
	assert_false(AudioServer.is_bus_mute(bus))
	Profile.data.settings.sfx_volume = 0.0
	Game.apply_settings()
	assert_true(AudioServer.is_bus_mute(bus), "0 is silent")


func test_every_ui_button_clicks_and_toggles_click_softer() -> void:
	var b := Button.new()
	add_child_autofree(b)
	b.pressed.emit()
	assert_eq(Audio.last_sound, &"ui_click")
	var t := CheckButton.new()
	add_child_autofree(t)
	t.pressed.emit()
	assert_eq(Audio.last_sound, &"ui_toggle")


func test_a_button_moved_in_the_tree_still_clicks_once() -> void:
	var box := VBoxContainer.new()
	add_child_autofree(box)
	var b := Button.new()
	box.add_child(b)
	box.remove_child(b)
	box.add_child(b)
	var before: int = Audio.played
	b.pressed.emit()
	assert_eq(Audio.played, before + 1)


func test_a_button_can_ask_for_its_own_sound_or_silence() -> void:
	var b := Button.new()
	b.set_meta(&"ui_sound", &"")
	add_child_autofree(b)
	var before: int = Audio.played
	b.pressed.emit()
	assert_eq(Audio.played, before, "silent on request")


func _touch(symbol: StringName, action: StringName = &"") -> TouchButton:
	var tb := TouchButton.new()
	tb.symbol = symbol
	tb.action = action
	tb.position = Vector2(100, 100)
	tb.size = Vector2(135, 135)
	add_child_autofree(tb)
	var ev := InputEventScreenTouch.new()
	ev.pressed = true
	ev.index = 3
	ev.position = Vector2(167, 167)
	tb._input(ev)
	var up := InputEventScreenTouch.new()
	up.index = 3
	up.position = ev.position
	tb._input(up)
	return tb


func test_hud_touch_buttons_click_but_jump_does_not() -> void:
	Audio.last_sound = &""
	_touch(&"pause")
	assert_eq(Audio.last_sound, &"ui_click")
	Audio.last_sound = &""
	_touch(&"jump", &"jump")
	assert_eq(Audio.last_sound, &"", "JUMP makes its own jump sound")
	_touch(&"")
	assert_eq(Audio.last_sound, &"ui_tick", "a hotbar slot ticks")


func test_gold_going_up_clinks_and_going_down_does_not() -> void:
	Session.gold_changed.emit(10)
	Audio.last_sound = &""
	Session.gold_changed.emit(15)
	assert_eq(Audio.last_sound, &"gold")
	Audio.last_sound = &""
	Session.gold_changed.emit(12)
	assert_eq(Audio.last_sound, &"", "spending is quiet")


func test_blocks_coming_into_the_bag_pop() -> void:
	var inv := Inventory.new()
	Session.my_inventory = inv
	Session.inventory_changed.emit()   # a new bag: nothing to pop about
	Audio.last_sound = &""
	inv.add(BlockIds.DIRT, 1)
	Session.inventory_changed.emit()
	assert_eq(Audio.last_sound, &"pickup")
	Audio.last_sound = &""
	inv.take(BlockIds.DIRT, 1)
	Session.inventory_changed.emit()
	assert_eq(Audio.last_sound, &"", "placing a block is not a pickup")
	var loaded := Inventory.new()
	loaded.add(BlockIds.STONE, 40)
	Session.my_inventory = loaded
	Session.inventory_changed.emit()
	assert_eq(Audio.last_sound, &"", "a world's saved bag arriving is not a pickup")


func test_a_kit_button_clicks_once_and_a_kit_toggle_only_softly() -> void:
	var b := UiKit.big_button("GO")
	add_child_autofree(b)
	var before: int = Audio.played
	b.pressed.emit()
	assert_eq(Audio.played, before + 1, "one click, not two")
	var t := UiKit.big_button("ON")
	t.toggle_mode = true
	add_child_autofree(t)
	before = Audio.played
	t.pressed.emit()
	assert_eq(Audio.played, before + 1)
	assert_eq(Audio.last_sound, &"ui_toggle")


func test_a_button_that_plays_its_own_click_is_heard_once() -> void:
	var b := Button.new()
	b.pressed.connect(Audio.play.bind(&"ui_click"))   # older panels click by themselves
	add_child_autofree(b)
	var before: int = Audio.played
	b.pressed.emit()
	assert_eq(Audio.played, before + 1)


func test_the_first_coin_after_the_game_starts_clinks_too() -> void:
	var fresh: Node = load("res://autoloads/audio.gd").new()   # as the game starts: gold is the profile's
	add_child(fresh)
	Session.gold_changed.emit(Profile.data.survivor_gold + 5)
	assert_eq(fresh.get("last_sound"), &"gold")
	Session.gold_changed.emit(Profile.data.survivor_gold)
	AudioServer.remove_bus_effect(0, int(fresh.call("muffle_index")))
	remove_child(fresh)
	fresh.free()
