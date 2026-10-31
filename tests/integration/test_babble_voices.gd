extends GutTest
## M3 Task 21a (babble voices, research F7): a bot friend's chat line, a buddy's cheer, Tilly and the story
## friends' hellos and the parrot's echo babble at the speaker, in nonsense syllables at its own pitch, through
## Audio's pooled players; one line at a time on a device, and the animals' chorus keeps quiet meanwhile.

class FakeBot:
	extends Node3D
	var bot_name := ""


var voices: BabbleVoices
var played: Array = []    # [at, pitch]
var _names := {}


func before_each() -> void:
	Audio.stop_all()
	played.clear()
	_names = Session.chat_names.duplicate()
	voices = BabbleVoices.new()
	voices.listener = func() -> Vector3: return Vector3.ZERO
	add_child_autofree(voices)
	Audio.sound_played.connect(_on_sound)


func after_each() -> void:
	Audio.sound_played.disconnect(_on_sound)
	Session.chat_names = _names
	Audio.stop_all()


func after_all() -> void:
	Audio.stop_all()


func _on_sound(sound: StringName, at: Vector3, _volume_db: float) -> void:
	if sound == BabbleRules.SOUND:
		played.append([at, Audio.last_voice_pitch])


func _bot(bot_name: String, at: Vector3) -> FakeBot:
	var b := FakeBot.new()
	b.bot_name = bot_name
	b.name = bot_name
	add_child_autofree(b)
	b.global_position = at
	b.add_to_group(&"bot_friends")
	return b


func _speaker(at: Vector3, speaker_name := "Buddy") -> Node3D:
	var n := Node3D.new()
	n.name = speaker_name
	add_child_autofree(n)
	n.global_position = at
	return n


func _run(seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		voices.step(0.05)
		t += 0.05


func test_a_bot_friends_line_babbles_at_the_bot() -> void:
	var bolt := _bot("Bolt", Vector3(3, 0, 0))
	Session.chat_received.emit(BotRules.chat_name("Bolt"), "I love your builds!", &"bot")
	_run(2.0)
	assert_eq(played.size(), BabbleRules.syllables("I love your builds!"), "one sound a syllable")
	for p: Array in played:
		assert_almost_eq((p[0] as Vector3).x, bolt.global_position.x, 0.01, "at the bot")
		assert_almost_eq(float(p[1]), BabbleRules.pitch(&"bot", BabbleRules.NORMAL_SIZE, BabbleRules.personality("Bolt")),
			0.001, "in its own voice")


func test_players_lines_never_babble() -> void:
	_bot("Bolt", Vector3(3, 0, 0))
	Session.chat_received.emit("Anna", "Hi!", &"chat")
	Session.chat_received.emit("", "Saved!", &"system")
	_run(2.0)
	assert_eq(played.size(), 0)


func test_a_tiny_buddy_squeaks_and_a_big_one_rumbles() -> void:
	var tiny := _speaker(Vector3(2, 0, 0), "Tiny")
	var big := _speaker(Vector3(-2, 0, 0), "Big")
	assert_true(BabbleVoices.say(tiny, &"buddy", 1.0, "Yay!", true))
	_run(1.5)
	var tiny_pitch: float = played[0][1]
	played.clear()
	assert_true(BabbleVoices.say(big, &"buddy", 12.0, "Yay!", true))
	_run(1.5)
	assert_gt(tiny_pitch, float(played[0][1]))


func test_one_line_at_a_time_on_a_device() -> void:
	_bot("Bolt", Vector3(3, 0, 0))
	_bot("Zuzu", Vector3(-3, 0, 0))
	Session.chat_received.emit(BotRules.chat_name("Bolt"), "What's over that hill?", &"bot")
	Session.chat_received.emit(BotRules.chat_name("Zuzu"), "This world is so big!", &"bot")
	assert_eq(voices.talking(), 1, "the second bot waits its turn: its words are still in the chat")


func test_far_speakers_are_not_heard() -> void:
	var far := _speaker(Vector3(BabbleRules.RADIUS + 5.0, 0, 0))
	assert_false(BabbleVoices.say(far, &"tilly", 3.0, "Hello!", true))
	_run(1.0)
	assert_eq(played.size(), 0)


func test_the_pools_never_grow() -> void:
	var before := Audio.player_count()
	for i in 6:
		BabbleVoices.say(_speaker(Vector3(i, 0, 0), "S%d" % i), &"buddy", 3.0, "Hello there friend!", true)
	_run(2.0)
	assert_eq(Audio.player_count(), before)


func test_the_animal_chorus_keeps_quiet_while_a_line_plays() -> void:
	var chorus := AnimalChorus.new()
	add_child_autofree(chorus)
	var quiet_until := chorus.rules.next_time()
	BabbleVoices.say(_speaker(Vector3(1, 0, 0)), &"buddy", 3.0, "Hello!", true)
	assert_gt(chorus.rules.next_time(), quiet_until, "the chorus waits after the babble")


func test_the_parrot_babbles_the_childs_words_back() -> void:
	assert_true(BabbleVoices.say(_speaker(Vector3(1, 0, 0), "Kiwi"), &"pet", 1.0, "Squawk! hello", true))
	_run(1.0)
	assert_gt(played.size(), 0)
	assert_gt(float(played[0][1]), BabbleRules.pitch(&"bot", BabbleRules.NORMAL_SIZE, 1.0), "a parrot chirps high")


func test_a_speaker_that_goes_while_it_talks_just_stops() -> void:   # owner #37: Nico's cart leaves at sunset
	var cart := Node3D.new()
	add_child(cart)
	cart.global_position = Vector3(2, 0, 0)
	assert_true(voices.speak(cart, &"tilly", BabbleRules.NORMAL_SIZE, "Hello! What would you like?", true, "Nico"))
	cart.free()
	voices.step(0.3)
	voices.step(0.3)
	assert_eq(voices.talking(), 0, "the line went with its speaker")
