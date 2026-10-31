extends GutTest
## Owner #133, rule 0 (docs/design/games/leaf-voyage.md §3.8, §3.9 "Mute"; the B2 brief): a child never has to read in a
## voyage. Every line Hoot says is spoken by itself, at once (PlayVoice); while a voyage plays not one word is on the
## screen (PlayHud.screen_words() is 0: the bar shows Hoot and the ear, the buttons are pictures, the end card is the
## plant, stars and numbers); the ear says Hoot's last line again. Without a voice (a grown-up turned Read to me off,
## or no English voice) the lines show as words (G0's ruling 28).

class FakeVoice:
	extends ReadAloud.Voice
	var said: Array[String] = []

	func has_voice(language: String) -> bool:
		return language == "en"

	func speak(text: String, _language: String) -> void:
		said.append(text)


const UNIT := "g5.science.plants_air_water"
## The lines a child who plays by the rule always hears in 5.1 (the hook to the end card).
const HEARD_5_1 := ["L1", "L2", "L3", "L4", "L5", "L6", "L8", "L10", "L11", "L12", "L15", "L18", "L21", "L22", "L23",
	"L24", "L25", "L26"]
const HEARD_5_T1 := ["D1", "D2", "D3", "D5", "D8", "D9", "D10"]

var host: LeafVoyageHost
var layer: CanvasLayer
var screen: Control
var voice: FakeVoice
var _old_voice: ReadAloud.Voice
var _read_to_me := true
var _path := ""
var _most_words := 0


func before_each() -> void:
	voice = FakeVoice.new()
	_old_voice = ReadAloud.voice
	ReadAloud.voice = voice
	ReadAloud.queue.clear()
	_read_to_me = bool(Profile.data.settings.read_to_me)
	Profile.data.settings.read_to_me = true
	Profile.data.settings.reduce_motion = true
	_path = "user://test_leaf_voice_%d.json" % OS.get_process_id()
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(_path)
	layer = CanvasLayer.new()
	add_child_autofree(layer)
	screen = Control.new()
	layer.add_child(screen)
	_most_words = 0


func after_each() -> void:
	if is_instance_valid(host) and not host.closed:
		host.close()
	ReadAloud.voice = _old_voice
	ReadAloud.queue.clear()
	Profile.data.settings.read_to_me = _read_to_me
	Profile.data.settings.reduce_motion = false
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(_path)
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _open(voyage: String) -> void:
	host = LeafVoyageHost.new()
	host.progress_path = _path
	host.setup(UNIT, {"id": UNIT, "exercises": [], "play": {"game": "leaf_voyage", "params": {"voyage": voyage}}}, 7,
		0, {})
	host.open(screen)
	await wait_process_frames(2)
	host.set_process(false)


func _said(id: String) -> bool:
	return voice.said.has(Lang.t(SchoolSpeech.spoken(LeafVoyages.line(id))))


func _tap(t: String) -> void:
	var at := host.screen_of(t)
	host.finger_down(at)
	host.finger_up(at)


## Plays the whole voyage by the rule (taps), counting the most words ever on the screen.
func _play_through() -> void:
	var t := 0.0
	while t < 900.0 and is_instance_valid(host) and host.journey.stage != LeafJourney.END:
		match host.journey.stage:
			LeafJourney.HOOK:
				if host.journey.has_can() and not host.journey.watered:
					if not host.busy():
						_tap("can")
				elif not host.journey.has_can() or _said("L3"):   # a child who listens: "Touch the leaf"
					_tap("leaf")
			LeafJourney.INSIDE:
				_rule_tap()
		host.step(0.1)
		_most_words = maxi(_most_words, host.hud.screen_words())
		t += 0.1


func _rule_tap() -> void:
	if host.busy():
		return
	var run := host.journey.run
	var want := run.phase == LeafRun.PLAY and bool(run.weather_now().open)
	for i in run.sim.doors.size():
		if run.sim.doors[i] != want:
			_tap("door_%d" % i)
			return
	if run.carried() > 0:
		_tap("gold_pipe")
	elif run.sim.waiting() > 0 and run.phase == LeafRun.PLAY:
		_tap(host.waiting_sugar())


func test_every_line_of_the_sunflower_is_spoken_and_no_word_is_on_the_screen() -> void:
	await _open("5.1")
	await _play_through()
	assert_eq(host.journey.stage, LeafJourney.END)
	for id: String in HEARD_5_1:
		assert_true(_said(id), "%s is spoken: %s" % [id, LeafVoyages.line(id)])
	assert_eq(_most_words, 0, "not one word on the screen while the voyage plays")
	assert_eq(host.hud.screen_words(), 0, "the end card: the plant, stars and numbers")


func test_every_line_of_the_desert_is_spoken_and_no_word_is_on_the_screen() -> void:
	await _open("5.T1")
	await _play_through()
	for id: String in HEARD_5_T1:
		assert_true(_said(id), "%s is spoken: %s" % [id, LeafVoyages.line(id)])
	assert_eq(_most_words, 0)


func test_the_ear_says_hoots_last_line_again() -> void:
	await _open("5.1")
	var n := voice.said.size()
	host.hud.ear.pressed.emit()
	assert_eq(voice.said.size(), n + 1)
	assert_eq(voice.said[-1], Lang.t(SchoolSpeech.spoken(LeafVoyages.line("L1"))), "the hook again")


func test_without_a_voice_the_lines_show_as_words() -> void:
	Profile.data.settings.read_to_me = false
	await _open("5.1")
	assert_eq(host.hud.say_label.text, LeafVoyages.line("L1"), "as for a reader")
