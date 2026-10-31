extends GutTest
## Owner #133, rule 0 ("consider no one will start reading in the game"): a child never has to read to play.
## - Say: every challenge's question and every coach line is spoken at once, by itself (Read to me is on for everyone);
##   a big ear button says it again; a thing says its name when it is touched.
## - On the screen while a challenge is played: a few words at most (PlayReadless.screen_words(): the mechanic's short
##   line or the numbers themselves), buttons as pictures; every word on a thing in the place short (a name).
## - World answers: the place and the voice answer, never a written "Correct!".
## - Show: a new unit's first challenge of each kind is shown one step first (the ghost does it; then the child does the
##   rest, and it still counts).
## Without a voice on the device (or with Read to me turned off by a grown-up) the words show, as for a reader.

const Stations := preload("res://tests/integration/test_play_stations.gd")
const UNIT := "g4.maths.big_numbers"
const CONTENT := {"id": UNIT, "lesson": [
		{"text": "Quick memory: what is 3 × 4?"},
		{"text": "A digit's place tells what it is worth."},
		{"text": "We read big numbers in groups of three."},
		{"text": "Try it in the world: build a tower of 347 blocks. Next: tables."}],
	"exercises": [
		{"type": "sort", "prompt": "Sort the numbers into the bins: more than 100, or not more than 100.", "hint": "Hundreds.",
			"groups": ["more", "not more"], "items": ["347", "99", "120"], "answer": [0, 1, 0], "level": 1},
		{"type": "number", "prompt": "300 + 40 + 7 = ?", "answer": "347", "hint": "Put the parts together.", "level": 2},
		{"type": "order", "prompt": "Smallest to biggest.", "items": ["120", "99", "347"], "answer": [1, 0, 2],
			"hint": "Look at the hundreds.", "level": 3}]}


class FakeVoice:
	extends ReadAloud.Voice
	var languages: Array[String] = ["en"]
	var said: Array[String] = []

	func has_voice(language: String) -> bool:
		return languages.has(language)

	func speak(text: String, _language: String) -> void:
		said.append(text)


var host: PlayHost
var layer: CanvasLayer
var screen: Control
var voice: FakeVoice
var outcomes: Array = []
var _old_voice: ReadAloud.Voice
var _read_to_me := true


func before_each() -> void:
	outcomes.clear()
	voice = FakeVoice.new()
	_old_voice = ReadAloud.voice
	ReadAloud.voice = voice
	ReadAloud.queue.clear()
	_read_to_me = bool(Profile.data.settings.read_to_me)
	Profile.data.settings.read_to_me = true
	Profile.data.settings.reduce_motion = true
	layer = CanvasLayer.new()
	add_child_autofree(layer)
	screen = Control.new()
	layer.add_child(screen)


func after_each() -> void:
	if is_instance_valid(host) and not host.closed:
		host.close()
	ReadAloud.voice = _old_voice
	ReadAloud.queue.clear()
	Profile.data.settings.read_to_me = _read_to_me
	Profile.data.settings.reduce_motion = false
	Vr.simulate(false)
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _open(stars: int = 1, content: Dictionary = CONTENT) -> PlayHost:
	host = PlayHost.new()
	host.setup(UNIT, content.duplicate(true), 7, stars, {"title": "Big numbers", "goals": ["Read big numbers"]})
	host.finished.connect(func(o: Dictionary) -> void: outcomes.append(o))
	host.open(screen)
	await wait_process_frames(2)
	host.set_process(false)   # time moves only when a test says so
	return host


func _said(text: String) -> bool:
	var spoken := Lang.t(SchoolSpeech.spoken(text))
	for s in voice.said:
		if s == spoken:
			return true
	return false


## Plays the current challenge right by the coach's own steps (flat taps), then its test.
func _play_right() -> void:
	var st := host.station()
	for i in 200:
		var steps := st.ghost()
		if steps.is_empty():
			break
		for t in steps:
			host.finger_down(host.screen_of(t))
			host.finger_up(host.screen_of(t))
	if not st.answers_by_acting():
		host.hud.go_button.pressed.emit()
	await wait_process_frames(1)


func test_every_challenge_says_its_question_aloud_by_itself() -> void:
	await _open()
	assert_true(_said(host.loop.hook_line), "the hook is spoken")
	host.end_hook()
	for i in host.loop.total():
		assert_true(_said(str(host.loop.current().prompt)), "challenge %d is spoken: %s" % [i, host.loop.current().prompt])
		await _play_right()
		host.hud.next_button.pressed.emit()
		if host.closed:
			break
		if host.loop.phase == PlayLoop.WHY:
			assert_true(_said(host.loop.see_why()), "the coach's line is spoken")
			host.hud.play_on_button.pressed.emit()
	assert_eq(outcomes.size(), 1)


func test_the_ear_button_says_it_again() -> void:
	await _open()
	host.end_hook()
	var n := voice.said.size()
	host.hud.ear.pressed.emit()
	assert_eq(voice.said.size(), n + 1)
	assert_eq(voice.said[-1], Lang.t(SchoolSpeech.spoken(str(host.loop.current().prompt))))
	assert_true(host.hud.ear.custom_minimum_size.x >= 96.0, "a big ear")


func test_a_few_words_at_most_on_the_screen_for_every_game() -> void:
	await _open()
	host.end_hook()
	for key: String in Stations.SAMPLES:
		var ex: Dictionary = JSON.parse_string(JSON.stringify(Stations.SAMPLES[key]))
		if not PlayReadless.plays(ex):
			continue
		host.show_exercise(ex)
		await wait_process_frames(1)
		var words := host.hud.screen_words()
		assert_true(words <= PlayReadless.screen_words(), "%s: %d words on the screen (%s)" % [key, words,
			host.hud.screen_text()])
		for w in host.arena.label_words():
			assert_true(w <= PlayReadless.thing_words(), "%s: a word on a thing in the place is a short name" % key)


func test_the_numbers_themselves_show_when_they_are_the_question() -> void:
	await _open()
	host.end_hook()
	host.show_exercise(CONTENT.exercises[1])
	assert_eq(host.hud.say_label.text, "300 + 40 + 7 = ?")
	host.show_exercise(CONTENT.exercises[0])
	assert_eq(host.hud.say_label.text, PlayMechanics.say_of("sort"), "a long question is said, not shown")


func test_the_world_answers_not_written_words() -> void:
	await _open()
	host.end_hook()
	host.show_exercise(CONTENT.exercises[1])
	var st := host.station()
	st.tap("src_0")
	host.check()
	assert_false(host.loop.answered)
	assert_false(host.hud.feedback.visible, "a miss is answered by the place and the voice")
	assert_string_contains(voice.said[-1], Lang.t(SchoolSpeech.spoken(str(CONTENT.exercises[1].hint))))
	host.show_exercise(CONTENT.exercises[1])
	await _play_right()
	assert_true(host.loop.answered)
	assert_false(host.hud.feedback.visible, "no written Correct!")
	assert_true(host.hud.screen_words() <= PlayReadless.screen_words(), host.hud.screen_text())
	assert_ne(voice.said[-1], Lang.t(SchoolSpeech.spoken(str(CONTENT.exercises[1].prompt))), "the praise is spoken")


func test_a_thing_says_its_name_when_touched() -> void:
	await _open()
	host.end_hook()
	host.show_exercise(CONTENT.exercises[0])
	var st := host.station()
	host.finger_down(host.screen_of("thing_0"))
	host.finger_up(host.screen_of("thing_0"))
	assert_eq(st.carried, "thing_0")
	assert_eq(voice.said[-1], Lang.t(SchoolSpeech.spoken("347")))
	assert_eq(st.spoken_name("bin_1"), "not more")


func test_without_a_voice_the_words_show_as_for_a_reader() -> void:
	voice.languages.clear()
	await _open()
	host.end_hook()
	assert_eq(host.hud.say_label.text, str(host.loop.current().prompt), "the whole question, written")
	assert_eq(host.hud.show_me_button.text, "SHOW ME")


func test_a_new_unit_shows_one_step_of_each_kind_first() -> void:
	await _open(0)
	host.end_hook()
	var st := host.station() as PlacingStation
	assert_eq(st.mechanic, "sort")
	assert_eq(st.demo_kind(), PlayStation.DEMO_DO, "several things to sort: the ghost sorts one")
	for i in 6:
		host._process(PlayHost.GHOST_TAP)
	assert_false(host.ghost_busy())
	assert_eq(st.placing.placed_count(), 1, "one step was shown and done")
	assert_eq(st.carried, "")
	assert_false(host.loop.helped, "a demonstration is not help: the challenge still counts")
	await _play_right()
	assert_true(host.loop.first_try, "the child did the rest: right the first time")


func test_a_one_act_answer_is_never_shown_first() -> void:
	await _open(0)
	host.end_hook()
	host.show_exercise(JSON.parse_string(JSON.stringify(Stations.SAMPLES["point"])))
	assert_eq(host.station().demo_kind(), PlayStation.DEMO_NONE, "one tap answers it: showing it would answer it")


func test_a_kind_already_shown_and_a_known_unit_are_not_shown_again() -> void:
	await _open(0)
	host.end_hook()
	for i in 6:
		host._process(PlayHost.GHOST_TAP)
	host.show_exercise(CONTENT.exercises[0].duplicate(true))
	for i in 6:
		host._process(PlayHost.GHOST_TAP)
	assert_eq((host.station() as PlacingStation).placing.placed_count(), 0, "sorting was shown once this round")
	host.close()
	await wait_process_frames(1)
	await _open(1)
	host.end_hook()
	for i in 6:
		host._process(PlayHost.GHOST_TAP)
	assert_eq((host.station() as PlacingStation).placing.placed_count(), 0, "a unit played before is not shown")
