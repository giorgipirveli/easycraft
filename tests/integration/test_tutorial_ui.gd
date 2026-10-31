extends GutTest
## M3 Task 15 (spec §14.9): the tutorial's screens. The step card (a picture, very short words, the steps as dots,
## a speaker and a small X) sits under the toasts, clear of every HUD button, label and the find arrow, on the
## emulator's and a 16:9 screen. The offer (PLAY WITH PIP / SKIP) and the reward card fit
## the screen (English only: owner #52); the words are read aloud with "Read to me" (and the speaker reads them any time).

const SCREENS: Array[Vector2i] = [Vector2i(2400, 1080), Vector2i(1334, 750)]


class FakeVoice:
	extends ReadAloud.Voice
	var said: Array[String] = []

	func has_voice(_language: String) -> bool:
		return true

	func speak(text: String, _language: String) -> void:
		said.append(text)

	func is_speaking() -> bool:
		return false


class AirWorld:
	extends WorldService

	func get_block(_pos: Vector3i) -> int:
		return BlockIds.AIR


var voice: FakeVoice
var _old_voice: ReadAloud.Voice
var _read_to_me := false
var _window_size: Vector2i
var _mode_before: StringName
var _text_size := ""


func before_all() -> void:
	_window_size = get_window().size


func after_all() -> void:
	get_window().size = _window_size


func before_each() -> void:
	voice = FakeVoice.new()
	_old_voice = ReadAloud.voice
	ReadAloud.voice = voice
	ReadAloud.queue.clear()
	_read_to_me = bool(Profile.data.settings.read_to_me)
	_mode_before = Game.mode
	_text_size = str(Profile.data.settings.get("text_size", "normal"))


func after_each() -> void:
	ReadAloud.voice = _old_voice
	ReadAloud.queue.clear()
	Profile.data.settings.read_to_me = _read_to_me
	Game.mode = _mode_before
	Profile.data.settings.text_size = _text_size


func _pump() -> void:
	ReadAloud.pump(Time.get_ticks_msec() / 1000.0 + 0.01)


func _card() -> TutorialCard:
	var layer := Control.new()
	layer.theme = UiKit.theme()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child_autofree(layer)
	var card := TutorialCard.new()
	layer.add_child(card)
	return card


func test_the_card_shows_the_steps_picture_words_and_where_it_is() -> void:
	var card := _card()
	card.show_step(2, TutorialRules.count())
	assert_true(card.visible)
	assert_eq(card.words.text, TutorialRules.words(2))
	assert_eq(card.picture.picture, TutorialRules.picture(2))
	assert_eq(card.dots.count, TutorialRules.count())
	assert_eq(card.dots.current, 2)
	var stopped := []
	card.stop_pressed.connect(func() -> void: stopped.append(true))
	card.stop_button.pressed.emit()
	assert_eq(stopped.size(), 1, "the small X stops it")


func test_the_speaker_reads_the_step_any_time() -> void:
	Profile.data.settings.read_to_me = false
	var card := _card()
	card.show_step(0, TutorialRules.count())
	card.speaker.pressed.emit()
	_pump()
	assert_eq(voice.said, [TutorialRules.words(0)] as Array[String])


func test_every_step_picture_draws() -> void:
	for i in TutorialRules.count():
		assert_true(TutorialPicture.draws(TutorialRules.picture(i)), "step %d" % i)


func test_the_card_fits_every_step() -> void:
	var card := _card()
	for i in TutorialRules.count():
		card.show_step(i, TutorialRules.count())
		var size := card.get_combined_minimum_size()
		assert_lte(size.x, TutorialCard.WIDTH, "step %d width %d" % [i, size.x])
		assert_lte(size.y, TutorialCard.MAX_HEIGHT, "step %d height %d" % [i, size.y])


## M5 Task 6 (the whole-game review): TEXT SIZE BIG (M5 Task 1) grows every word a child reads while playing, but the
## step card kept its 22 px words. At BIG they grow too; the card keeps its box (the step's picture and the dots step
## aside for the words), so it stays clear of the HUD and above the crosshair.
func test_the_cards_words_grow_with_text_size_big_and_it_keeps_its_box() -> void:
	Profile.data.settings.text_size = "big"
	var card := _card()
	for i in TutorialRules.count():
		card.show_step(i, TutorialRules.count())
		assert_eq(card.words.get_theme_font_size("font_size"), TextSize.px(22), "step %d: BIG words" % i)
		var size := card.get_combined_minimum_size()
		assert_lte(size.x, TutorialCard.WIDTH, "step %d width %d" % [i, size.x])
		assert_lte(size.y, TutorialCard.MAX_HEIGHT, "step %d height %d" % [i, size.y])
	Profile.data.settings.text_size = "normal"
	Game.settings_applied.emit(Profile.data.settings)   # changed in SETTINGS while it plays
	assert_eq(card.words.get_theme_font_size("font_size"), 22, "back to NORMAL")
	assert_true(card.picture.visible and card.dots.visible, "the picture and the dots are back")
	Profile.data.settings.text_size = "big"
	Game.settings_applied.emit(Profile.data.settings)
	assert_eq(card.words.get_theme_font_size("font_size"), TextSize.px(22), "BIG again, without a new step")
	assert_lte(card.get_combined_minimum_size().y, TutorialCard.MAX_HEIGHT)


func _hud(screen: Vector2i) -> Hud:
	get_window().size = screen
	Game.mode = ModeRules.SURVIVOR
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
	hud.add_sleep_controls()
	hud.add_secret_controls(null)
	hud.add_ride_controls()
	hud.show_difficulty_badge(DifficultyRules.BRAVE)
	hud.show_ride_button(true)
	hud.interactor.set_slot_block(0, ItemIds.SWORD)
	return hud


func test_the_card_is_clear_of_the_hud() -> void:
	for screen in SCREENS:
		var hud := _hud(screen)
		var card := _card()
		card.show_step(4, TutorialRules.count())
		await wait_process_frames(3)
		var r := card.get_global_rect()
		var view := hud.get_viewport_rect()
		assert_true(view.encloses(r), "%s: on the screen %s" % [screen, r])
		var others: Array[Control] = [hud.hearts, hud.stealth_meter, hud.brave_badge, hud.gold_counter, hud.username_label,
			hud.wave_line, hud.boss_bar, hud.potion_timers, hud.fps_label, hud.joystick, hud.hotbar]
		for n in hud.find_children("*", "Control", true, false):
			var c := n as Control
			if (c is TouchButton or c is BaseButton) and c.is_visible_in_tree() and not hud.hotbar.is_ancestor_of(c):
				others.append(c)
		for c: Control in others:
			assert_false(r.intersects(c.get_global_rect()), "%s: clear of %s" % [screen, c.name])
		var arrow := HudLayout.rect(&"compass", view.size, FindArrow.SIZE + Vector2(0, 40))
		assert_false(r.intersects(arrow), "%s: clear of the find arrow and its name" % screen)
		assert_lt(r.end.y, view.size.y * 0.5 - 26.0, "%s: above the crosshair" % screen)
		for b: Control in card.blockers():
			assert_gte(minf(b.size.x, b.size.y), 52.0, "%s: %s big enough" % [screen, b.name])
		hud.queue_free()
		card.get_parent().queue_free()
		await wait_process_frames(1)


# --- The offer and the reward ---

func _overlay() -> TutorialOffer:
	var o := TutorialOffer.new()
	o.theme = UiKit.theme()
	add_child_autofree(o)
	return o


func test_the_offer_asks_play_with_pip_or_skip() -> void:
	Profile.data.settings.read_to_me = true
	var o := _overlay()
	o.offer(false)
	assert_true(o.is_open())
	assert_has(o.texts(), TutorialRules.line(&"tutorial_hello"))
	assert_has(o.texts(), TutorialRules.line(&"tutorial_offer"))
	assert_has(o.texts(), "PLAY WITH PIP")
	assert_has(o.texts(), "SKIP")
	_pump()
	assert_gt(voice.said.size(), 0, "read aloud with Read to me")
	var got := []
	o.play.connect(func() -> void: got.append(&"play"))
	o.skip.connect(func() -> void: got.append(&"skip"))
	o.play_button.pressed.emit()
	assert_eq(got, [&"play"])
	assert_false(o.is_open())
	o.offer(true)
	assert_has(o.texts(), TutorialRules.line(&"tutorial_resume"), "a stopped tutorial goes on")
	o.skip_button.pressed.emit()
	assert_eq(got, [&"play", &"skip"])


func test_a_tap_outside_the_offer_decides_nothing() -> void:
	var o := _overlay()
	var got := []
	o.play.connect(func() -> void: got.append(&"play"))
	o.skip.connect(func() -> void: got.append(&"skip"))
	var later := []
	o.later.connect(func() -> void: later.append(true))
	o.offer(false)
	o.close()
	assert_true(got.is_empty(), "never a skip by accident")
	assert_eq(later.size(), 1)


func test_the_reward_card() -> void:
	var o := _overlay()
	o.reward(true)
	for line: StringName in [&"tutorial_done", &"tutorial_reward_gold", &"tutorial_reward_hat", &"tutorial_reward_pip"]:
		assert_has(o.texts(), TutorialRules.line(line))
	o.ok_button.pressed.emit()
	assert_false(o.is_open())
	o.reward(false)
	assert_has(o.texts(), TutorialRules.line(&"tutorial_again_done"))
	assert_does_not_have(o.texts(), TutorialRules.line(&"tutorial_reward_gold"), "no second reward")


func test_the_cards_fit_the_screen() -> void:
	var o := _overlay()
	for show: Callable in [func() -> void: o.offer(false), func() -> void: o.offer(true), func() -> void: o.reward(true)]:
		show.call()
		var size := o.box.get_combined_minimum_size()
		assert_lte(size.x, 1280.0, "width %d" % size.x)
		assert_lte(size.y, 720.0, "height %d" % size.y)
