extends GutTest
## M3 Task 21a (read-aloud, research O6, spec §5.15): the game's words can be read aloud through the system's
## text-to-speech (owner #45a's ReadAloud, extended). A speaker button reads a panel at once; "Read to me" (off by
## default) reads tips, toasts, banners, riddles and menu titles as they appear, one at a time. The chat is never
## read (other players' words never are), nor a player's name; where the device has no voice for the game's
## language nothing is read and the speaker buttons hide. Headless: a fake voice records what it would say.

class FakeVoice:
	extends ReadAloud.Voice
	var languages: Array[String] = ["en"]
	var said: Array[String] = []
	var said_in: Array[String] = []
	var speaking := false
	var stops := 0

	func has_voice(language: String) -> bool:
		return languages.has(language)

	func speak(text: String, language: String) -> void:
		said.append(text)
		said_in.append(language)
		speaking = true

	func stop() -> void:
		stops += 1
		speaking = false

	func is_speaking() -> bool:
		return speaking


var voice: FakeVoice
var _old_voice: ReadAloud.Voice
var _read_to_me := false
var _locale := ""
var _names := {}


func before_each() -> void:
	voice = FakeVoice.new()
	_old_voice = ReadAloud.voice
	ReadAloud.voice = voice
	ReadAloud.queue.clear()
	_read_to_me = bool(Profile.data.settings.read_to_me)
	_locale = TranslationServer.get_locale()
	_names = Session.chat_names.duplicate()
	Lang.apply()


func after_each() -> void:
	ReadAloud.voice = _old_voice
	ReadAloud.queue.clear()
	Profile.data.settings.read_to_me = _read_to_me
	TranslationServer.set_locale(_locale)
	Session.chat_names = _names


func _pump() -> void:
	voice.speaking = false
	ReadAloud.pump(Time.get_ticks_msec() / 1000.0)


## Owner #133 ("no one will start reading in the game"): the voice is on from the start (a grown-up can turn it off).
func test_read_to_me_is_on_on_a_new_profile() -> void:
	assert_true(ProfileData.new().settings.read_to_me)


func test_read_to_me_reads_only_when_it_is_on() -> void:
	Profile.data.settings.read_to_me = false
	ReadAloud.auto("Mirror ON: everything you build is copied")
	_pump()
	assert_eq(voice.said, [] as Array[String])
	Profile.data.settings.read_to_me = true
	ReadAloud.auto("Mirror ON: everything you build is copied")
	_pump()
	assert_eq(voice.said, ["Mirror ON: everything you build is copied"] as Array[String])


func test_a_speaker_button_reads_even_with_read_to_me_off() -> void:
	Profile.data.settings.read_to_me = false
	ReadAloud.speak("Stay safe online.")
	_pump()
	assert_eq(voice.said, ["Stay safe online."] as Array[String])


func test_lines_are_read_one_after_another() -> void:
	Profile.data.settings.read_to_me = true
	ReadAloud.auto("Wave 1 won!")
	voice.speaking = true
	ReadAloud.auto("Get ready! The monsters are coming.")
	ReadAloud.pump(Time.get_ticks_msec() / 1000.0)
	assert_eq(voice.said.size(), 1, "the second waits while the first is read")
	_pump()
	assert_eq(voice.said, ["Wave 1 won!", "Get ready! The monsters are coming."] as Array[String])


func test_a_speaker_button_stops_what_is_being_read() -> void:
	Profile.data.settings.read_to_me = true
	ReadAloud.auto("Wave 1 won!")
	voice.speaking = true
	ReadAloud.speak("Pick your name")
	assert_gt(voice.stops, 0, "the old line stops")
	assert_eq(voice.said.back(), "Pick your name")


func test_the_chat_is_never_read() -> void:
	Profile.data.settings.read_to_me = true
	var chat := ChatPanel.new()
	add_child_autofree(chat)
	chat.setup("Hopper", AgeBand.TEEN_PLUS)
	chat.add_line("my phone is 555", &"chat", "Stranger")
	chat.add_line("Hi!", &"chat", "Anna")
	chat.add_line("Hi, I'm Pip! Let's build something cool!", &"bot", "Pip (bot)")
	chat.add_line("That isn't a command. Try /help", &"error")
	chat.add_line("Saved!", &"system")
	Session.chat_received.emit("Stranger", "come to my house", &"chat")
	_pump()
	assert_eq(voice.said, [] as Array[String], "nothing in the chat is read aloud")


func test_a_toast_is_read_but_never_a_players_name() -> void:
	Profile.data.settings.read_to_me = true
	Session.chat_names = {1: Profile.data.username, 7: "Anna_B"}
	ReadAloud.auto("Anna_B was knocked out!")
	_pump()
	assert_eq(voice.said, ["A friend was knocked out!"] as Array[String])


func test_a_panel_is_read_without_player_words() -> void:
	var box := VBoxContainer.new()
	add_child_autofree(box)
	box.add_child(UiKit.title("Friends"))
	var name := Label.new()
	name.text = "Anna_B"
	name.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # a player's name: never read
	box.add_child(name)
	var hidden := Label.new()
	hidden.text = "Secret"
	hidden.visible = false
	box.add_child(hidden)
	box.add_child(UiKit.big_button("ADD"))
	box.add_child(ReadAloud.button(func() -> String: return "x"))
	assert_eq(ReadAloud.words_of(box), "Friends. ADD.")


func test_no_voice_for_the_language_reads_nothing_and_hides_the_buttons() -> void:
	voice.languages = []   # a device with no English voice
	Profile.data.settings.read_to_me = true
	assert_false(ReadAloud.available())
	ReadAloud.auto("Settings")
	ReadAloud.speak("Settings")
	_pump()
	assert_eq(voice.said, [] as Array[String])
	var b := ReadAloud.button(func() -> String: return "Settings")
	assert_false(b.visible)
	b.free()
	voice.languages = ["en"]
	assert_true(ReadAloud.available())


## The lead (2026-10-17, the first install on the Quest 3): Android's speech service starts a few seconds after the
## game, so the first question for voices came back empty ("Text to Speech not initialized") and that empty answer
## was kept: no speaker button showed all session. An empty answer is asked again (at most every RETRY_S); a voice
## found is kept.
func test_a_voice_that_is_not_ready_yet_is_asked_again() -> void:
	var asks := [0]
	var ready := [false]
	var now := [100.0]
	var v := ReadAloud.SystemVoice.new()
	v.lookup = func(_language: String) -> PackedStringArray:
		asks[0] += 1
		return PackedStringArray(["en-voice"]) if ready[0] else PackedStringArray()
	v.clock = func() -> float: return now[0]
	v.headless = false
	assert_false(v.has_voice("en"), "not ready yet")
	now[0] += ReadAloud.SystemVoice.RETRY_S * 0.5
	assert_false(v.has_voice("en"))
	assert_eq(asks[0], 1, "not asked again this soon")
	ready[0] = true
	now[0] += ReadAloud.SystemVoice.RETRY_S
	assert_true(v.has_voice("en"), "asked again once the wait is over")
	assert_true(v.has_voice("en"))
	now[0] += 60.0
	assert_true(v.has_voice("en"))
	assert_eq(asks[0], 2, "a voice found is kept")


func test_a_speaker_hidden_for_no_voice_shows_when_the_voice_arrives() -> void:
	voice.languages = []   # the speech service is still starting
	var b := ReadAloud.button(func() -> String: return "Settings")
	add_child_autofree(b)
	assert_false(b.visible)
	b._process(ReadAloud.SystemVoice.RETRY_S + 0.1)
	assert_false(b.visible, "still no voice")
	voice.languages = ["en"]
	b._process(ReadAloud.SystemVoice.RETRY_S + 0.1)
	assert_true(b.visible, "the voice came: the speaker shows")


func test_a_speaker_someone_else_hid_stays_hidden() -> void:
	var b := ReadAloud.button(func() -> String: return "Settings")
	add_child_autofree(b)
	assert_true(b.visible)
	b.visible = false   # its panel's own choice
	b._process(ReadAloud.SystemVoice.RETRY_S + 0.1)
	assert_false(b.visible)


func test_hud_toasts_and_tips_are_read_to_me() -> void:
	Profile.data.settings.read_to_me = true
	var banner := SurpriseBanner.new()
	add_child_autofree(banner)
	banner.show_banner("You found a hidden room!")
	_pump()
	var hint := PictureHint.new()
	add_child_autofree(hint)
	hint.show_hint(null, Color.WHITE, "Shiny ores need an IRON pickaxe!")
	_pump()
	var riddle := RiddlePanel.new()
	add_child_autofree(riddle)
	riddle.show_riddle("I shine all day. What am I?", [], func(_i: int) -> void: pass)
	_pump()
	assert_eq(voice.said, ["You found a hidden room!", "Shiny ores need an IRON pickaxe!",
		"I shine all day. What am I?"] as Array[String])


func test_the_stay_safe_card_has_a_speaker() -> void:
	var card := StaySafeCard.new()
	add_child_autofree(card)
	var b := card.find_child("ReadAloud", true, false) as Button
	assert_not_null(b)
	if b:
		b.pressed.emit()
		assert_eq(voice.said.back(), StaySafeCard.read_aloud_text())
