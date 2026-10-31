extends GutTest
## M5 Task 2 (spec §15.2): while a world loads, a card over the universe's scene shows one picture hint at a time
## (LoadingHints, HINT_TIME each, never the same twice in a row), read aloud with "Read to me", and fades away when
## this device's player stands in the world.


class FakeVoice:
	extends ReadAloud.Voice
	var said: Array[String] = []

	func has_voice(_language: String) -> bool:
		return true

	func speak(text: String, _language: String) -> void:
		said.append(text)

	func is_speaking() -> bool:
		return false


class FakePlayer:
	extends Node
	signal spawned


var voice: FakeVoice
var _old_voice: ReadAloud.Voice
var _read_to_me := false


var _old_queue: SpeechQueue


func before_each() -> void:
	voice = FakeVoice.new()
	_old_voice = ReadAloud.voice
	ReadAloud.voice = voice
	# A fresh queue: owner #133 turned the voice on by default, so an earlier test may have just read this hint, and a
	# queue never reads the same line twice within SpeechQueue.REPEAT_GAP (clear() keeps what it read last).
	_old_queue = ReadAloud.queue
	ReadAloud.queue = SpeechQueue.new()
	_read_to_me = bool(Profile.data.settings.read_to_me)


func after_each() -> void:
	ReadAloud.voice = _old_voice
	ReadAloud.queue = _old_queue
	ReadAloud.queue.clear()
	Profile.data.settings.read_to_me = _read_to_me


func _card(mode: StringName = ModeRules.SURVIVOR, u: int = 3) -> LoadingCard:
	var c := LoadingCard.new()
	c.setup(mode, u)
	add_child_autofree(c)
	c.set_process(false)
	return c


func test_it_covers_the_screen_with_the_universes_scene_and_one_hint() -> void:
	var c := _card(ModeRules.SURVIVOR, 3)
	await wait_frames(1)
	assert_eq(c.backdrop.universe, 3, "Frostpeak's scene behind")
	assert_eq(c.anchor_right, 1.0, "the whole screen")
	assert_eq(c.anchor_bottom, 1.0)
	assert_ne(c.label.text, "", "a hint")
	assert_true(LoadingHints.fitting(ModeRules.SURVIVOR, 3).has(c.hint), "one that fits the world")
	assert_eq(c.label.text, LoadingHints.HINTS[c.hint].text)
	assert_not_null(c.icon.texture, "with its picture")


func test_the_hint_changes_every_few_seconds_never_the_same_twice() -> void:
	var c := _card()
	var shown: Array[int] = [c.hint]
	for i in 6:
		c.step(LoadingCard.HINT_TIME + 0.01)
		assert_ne(c.hint, shown[-1], "a new one")
		shown.append(c.hint)
	c.step(LoadingCard.HINT_TIME * 0.5)
	assert_eq(c.hint, shown[-1], "not before its time")


func test_read_to_me_reads_each_hint() -> void:
	Profile.data.settings.read_to_me = true
	var c := _card()
	ReadAloud.pump(Time.get_ticks_msec() / 1000.0 + 0.01)
	assert_true(voice.said.has(c.label.text), "the first hint is read")
	c.step(LoadingCard.HINT_TIME + 0.01)
	ReadAloud.pump(Time.get_ticks_msec() / 1000.0 + 5.0)
	assert_true(voice.said.has(c.label.text), "and the next")


func test_without_read_to_me_nothing_is_read() -> void:
	Profile.data.settings.read_to_me = false
	_card()
	ReadAloud.pump(Time.get_ticks_msec() / 1000.0 + 0.01)
	assert_eq(voice.said.size(), 0)


func test_it_fades_away_when_the_player_stands_in_the_world() -> void:
	var parent := Node.new()
	add_child_autofree(parent)
	var me := FakePlayer.new()
	add_child_autofree(me)
	var layer := LoadingCard.cover(parent, me, ModeRules.SANDBOX, 1)
	var card := layer.get_child(0) as LoadingCard
	assert_true(card.visible)
	assert_gt(layer.layer, 80, "over the HUD while it loads")
	me.spawned.emit()
	await wait_seconds(LoadingCard.FADE_TIME + 0.15)
	assert_false(is_instance_valid(layer), "gone once the child stands in the world")


## M7 (the shader warm-up): in a browser the card stays after the child stands in the world while something holds it
## (LoadingCard.HOLD_GROUP: the warm-up drawing what a first world shows), never longer than its hold_max.
func test_it_stays_while_something_holds_it_after_the_child_stands() -> void:
	var parent := Node.new()
	add_child_autofree(parent)
	var me := FakePlayer.new()
	add_child_autofree(me)
	var holder := Node.new()
	holder.add_to_group(LoadingCard.HOLD_GROUP)
	add_child_autofree(holder)
	var layer := LoadingCard.cover(parent, me, ModeRules.SANDBOX, 1)
	var card := layer.get_child(0) as LoadingCard
	me.spawned.emit()
	await wait_seconds(LoadingCard.FADE_TIME + 0.15)
	assert_true(is_instance_valid(layer), "held")
	assert_true(card.holding)
	holder.remove_from_group(LoadingCard.HOLD_GROUP)
	await wait_seconds(LoadingCard.FADE_TIME + 0.2)
	assert_false(is_instance_valid(layer), "gone once nothing holds it")


func test_it_never_stays_longer_than_its_hold_max() -> void:
	var parent := Node.new()
	add_child_autofree(parent)
	var me := FakePlayer.new()
	add_child_autofree(me)
	var holder := Node.new()
	holder.add_to_group(LoadingCard.HOLD_GROUP)
	add_child_autofree(holder)
	var layer := LoadingCard.cover(parent, me, ModeRules.SANDBOX, 1)
	(layer.get_child(0) as LoadingCard).hold_max = 0.2
	me.spawned.emit()
	await wait_seconds(0.2 + LoadingCard.FADE_TIME + 0.2)
	assert_false(is_instance_valid(layer), "the child plays; what was still to draw compiles as it shows")


func test_it_is_one_short_hint_card_and_does_not_take_long_to_draw() -> void:
	var c := _card(ModeRules.WAVE, 5)
	await wait_frames(1)
	assert_lte(c.label.get_theme_font_size("font_size"), 40)
	assert_gte(c.label.get_theme_font_size("font_size"), 28, "big enough to read")
	assert_eq(c.find_children("*", "Label", true, false).size(), 1, "one line, nothing else to read")


## M5 Task 6 (the whole-game review): Android Back during a load opens the pause menu (the sandbox's Back chain), which
## lives on the world's own layer, under the loading card (layer 88, a full-screen card that takes every touch). The
## paused game never spawned the player, so the card never went: the load looked stuck and the pause menu could be
## neither seen nor touched. The card steps aside while the game is paused and comes back on RESUME.
func test_the_card_steps_aside_while_the_game_is_paused() -> void:
	var holder := Node.new()
	add_child_autofree(holder)
	var player := FakePlayer.new()
	holder.add_child(player)
	var layer := LoadingCard.cover(holder, player, ModeRules.SURVIVOR, 1)
	var card := layer.get_child(0) as LoadingCard
	assert_true(card.is_visible_in_tree(), "it covers the loading world")
	get_tree().paused = true   # Back: the pause menu, under the card's layer
	var hidden_while_paused := not card.is_visible_in_tree()
	get_tree().paused = false  # RESUME
	assert_true(hidden_while_paused, "the pause menu can be seen and touched")
	assert_true(card.is_visible_in_tree(), "the card again while the world goes on loading")
