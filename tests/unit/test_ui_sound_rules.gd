extends GutTest
## Button sounds (the audio pass, owner feedback #27; spec §15.2 "sound for every button"): one shared
## click for buttons, a softer one for toggles; the HUD's touch buttons click too, except the ones a
## child presses all the time for playing (JUMP, ATTACK, CROUCH, UP, DOWN) or whose action has its own
## sound (UNDO); the hotbar's slots tick.


func test_buttons_click_and_toggles_click_softer() -> void:
	assert_eq(UiSoundRules.button_sound(false), &"ui_click")
	assert_eq(UiSoundRules.button_sound(true), &"ui_toggle")


func test_a_button_can_choose_its_own_sound_or_none() -> void:
	assert_eq(UiSoundRules.button_sound(false, &"ding"), &"ding")
	assert_eq(UiSoundRules.button_sound(true, &""), &"")


func test_playing_buttons_stay_quiet() -> void:
	for symbol: StringName in [&"jump", &"up", &"down", &"crouch", &"attack", &"undo"]:
		assert_eq(UiSoundRules.touch_sound(symbol, &""), &"", String(symbol))


func test_buttons_holding_an_input_action_stay_quiet() -> void:
	assert_eq(UiSoundRules.touch_sound(&"pause", &"jump"), &"")


func test_menu_like_touch_buttons_click() -> void:
	for symbol: StringName in [&"pause", &"more", &"chat", &"book", &"photo", &"emote", &"lab", &"sleep", &"wake",
			&"home", &"heart"]:
		assert_eq(UiSoundRules.touch_sound(symbol, &""), &"ui_click", String(symbol))


func test_switches_click_softer() -> void:
	for symbol: StringName in [&"walk", &"fly", &"ghost", &"moon", &"zero_g", &"slow", &"size", &"camera", &"mirror"]:
		assert_eq(UiSoundRules.touch_sound(symbol, &""), &"ui_toggle", String(symbol))


func test_hotbar_slots_tick() -> void:
	assert_eq(UiSoundRules.touch_sound(&"", &""), &"ui_tick")


func test_every_hud_symbol_has_a_decision() -> void:
	var sounds: Dictionary = load("res://autoloads/audio.gd").SOUNDS
	for symbol: StringName in HudIcons.SYMBOLS:
		var s := UiSoundRules.touch_sound(symbol, &"")
		assert_true(s == &"" or sounds.has(s), "%s -> %s" % [symbol, s])
