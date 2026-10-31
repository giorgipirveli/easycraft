class_name ReadAloud
extends RefCounted
## Game text read out loud for children who can't read yet (research O6, spec §5.15; owner #45a's quest
## stories; M3 Task 21a): the system's text-to-speech (DisplayServer.tts_*; the project setting
## audio/general/text_to_speech is on), in the language the game speaks (Lang), with that language's voice.
## - A speaker button (button()) reads its panel at once, cutting in.
## - "Read to me" (settings.read_to_me, on by default since owner #133) reads tips, toasts, banners, riddles and menu titles as
##   they appear (auto()), one at a time (SpeechQueue: never twice in a row, never late).
## - Never chat: nothing in the chat is ever read (ChatPanel never calls this), and other players' names are read
##   as "a friend". A panel is read without player words (labels that don't translate themselves: names, chat).
## - Where the device has no voice for the game's language nothing is read and the speaker buttons hide.
## Tests put a fake Voice in `voice`.

const PUMP_EVERY := 0.25   # seconds between looks while lines wait

## The voice the game reads with (the system's; tests set a fake).
static var voice: Voice = SystemVoice.new()
## The lines waiting (one queue per device).
static var queue := SpeechQueue.new()
static var _pumping := false
static var _letters := RegEx.create_from_string("\\p{L}")


## What reads aloud: the system's text-to-speech, or a fake in tests.
class Voice:
	extends RefCounted

	func has_voice(_language: String) -> bool:
		return false

	func speak(_text: String, _language: String) -> void:
		pass

	func stop() -> void:
		pass

	func is_speaking() -> bool:
		return false


## Godot's DisplayServer text-to-speech (Android, iOS, desktops); nothing when headless. Owner #94: a language's voices
## are asked for once and kept (on a Linux desktop each question to the speech service took ~70 ms, and EasyCraft Shorts
## read every scene).
## The lead (2026-10-17, the first install on the Quest 3): Android's speech service starts seconds after the game, so
## an empty answer ("Text to Speech not initialized") is asked again, at most every RETRY_S; a voice found is kept.
class SystemVoice:
	extends Voice
	const RETRY_S := 2.0
	## Where the voices come from and the time (tests set fakes).
	var lookup: Callable = func(language: String) -> PackedStringArray:
		return DisplayServer.tts_get_voices_for_language(language)
	var clock: Callable = func() -> float: return Time.get_ticks_msec() / 1000.0
	var headless := DisplayServer.get_name() == "headless"
	var _voices := {}
	var _asked := {}

	func has_voice(language: String) -> bool:
		return not headless and not _voices_for(language).is_empty()

	func speak(text: String, language: String) -> void:
		var voices := _voices_for(language)
		if not voices.is_empty():
			DisplayServer.tts_speak(text, voices[0])

	func _voices_for(language: String) -> PackedStringArray:
		var kept: PackedStringArray = _voices.get(language, PackedStringArray())
		if not kept.is_empty():
			return kept
		var now: float = clock.call()
		if _asked.has(language) and now - float(_asked[language]) < RETRY_S:
			return kept
		_asked[language] = now
		_voices[language] = lookup.call(language)
		return _voices[language]

	func stop() -> void:
		if not headless:
			DisplayServer.tts_stop()

	func is_speaking() -> bool:
		return not headless and DisplayServer.tts_is_speaking()


## A button with a drawn speaker (no font needs an emoji).
class ReadAloudSpeaker:
	extends Button

	## P5 (VR draws): redraws as one batch in a headset (tests count them).
	var vr_draws := 0
	## Hidden because the device had no voice yet: it looks again every RETRY_S for a minute and shows itself when one
	## comes (the Quest 3's speech service starts after the game); never once anything else has shown it.
	var waiting_for_voice := false
	var _since := 0.0
	var _looks := 0

	func _process(delta: float) -> void:
		if not waiting_for_voice or visible or _looks >= 30:
			waiting_for_voice = false
			set_process(false)
			return
		_since += delta
		if _since < SystemVoice.RETRY_S:
			return
		_since = 0.0
		_looks += 1
		if ReadAloud.available():
			waiting_for_voice = false
			visible = true

	func _draw() -> void:
		var u := minf(size.x, size.y)
		var c := size * 0.5
		var ink := Color.WHITE
		# P5: in a headset (its canvas is drawn every frame) the box, the cone and the waves are one draw, not four
		var on: Object = CanvasBatch.new() if GraphicsPreset.vr_session else self
		on.draw_rect(Rect2(c + Vector2(-0.3, -0.1) * u, Vector2(0.14, 0.2) * u), ink)
		on.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.16, -0.1) * u, c + Vector2(0.02, -0.26) * u,
			c + Vector2(0.02, 0.26) * u, c + Vector2(-0.16, 0.1) * u]), ink)
		for i in 2:
			on.draw_arc(c + Vector2(0.04, 0.0) * u, u * (0.12 + 0.11 * i), -0.8, 0.8, 10, ink, u * 0.045)
		if on is CanvasBatch:
			vr_draws += 1
			(on as CanvasBatch).flush(self)


## True when the device can read the game's language aloud.
static func available() -> bool:
	return voice.has_voice(Lang.current())


## Reads `text` now (a speaker button: it cuts in), whatever "Read to me" says.
static func speak(text: String) -> void:
	_say(text, true)


## "Read to me": reads `text` when its turn comes, only while the setting is on.
static func auto(text: String) -> void:
	if bool(Profile.data.settings.get("read_to_me", false)):
		_say(text, false)


## Reads the next waiting line when the voice is free (called by itself while lines wait; tests call it).
static func pump(now: float) -> void:
	if queue.interrupting():
		voice.stop()
	var line := queue.next(now, voice.is_speaking())
	if line != "":
		voice.speak(line, Lang.current())
	if queue.waiting() > 0:
		_keep_pumping()


## Everything a panel shows, in order, as one text to read: titles, words and buttons that are visible, in the
## game's language; never player words (labels that don't translate themselves: names, chat lines).
static func words_of(root: Node) -> String:
	var parts: Array[String] = []
	_collect(root, parts)
	return " ".join(parts)


## A speaker button that reads `text.call()` aloud (hidden where there is no voice).
static func button(text: Callable, side := 72.0) -> Button:
	var b := ReadAloudSpeaker.new()
	b.name = "ReadAloud"
	b.tooltip_text = "Read it to me"
	b.custom_minimum_size = Vector2(side, side)
	b.visible = available()
	b.waiting_for_voice = not b.visible
	b.set_process(b.waiting_for_voice)
	b.pressed.connect(func() -> void: speak(str(text.call())))
	return b


## `title` with a speaker button beside it (M3 Task 21a): it reads `text.call()`, or everything `what` shows.
## Where there is no voice the button hides and the row is just the title.
static func with_speaker(title: Control, what: Node, text := Callable()) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Titled"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.add_child(title)
	var b := button(func() -> String: return str(text.call()) if text.is_valid() else words_of(what), 56.0)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	return row


## The first words `root` shows (its title), "" for none.
static func title_of(root: Node) -> String:
	for n in root.find_children("*", "Label", true, false):
		var l := n as Label
		if l.is_visible_in_tree() and l.can_auto_translate() and l.text.strip_edges() != "":
			return l.text
	return ""


static func _say(text: String, urgent: bool) -> void:
	if not available():
		return
	var line := SpeechQueue.without_names(Lang.t(text), _other_names(), Lang.t("a friend"))
	if queue.push(line, _now(), urgent):
		pump(_now())


## The names of the other players in this game (Session's chat names but this child's own).
static func _other_names() -> Array:
	var out := []
	for n: Variant in Session.chat_names.values():
		if str(n) != Profile.data.username:
			out.append(str(n))
	return out


static func _collect(node: Node, parts: Array[String]) -> void:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return
	if node is ReadAloudSpeaker or node is LineEdit:
		return
	var c := node as Control
	if c and c.can_auto_translate():
		var text := ""
		if c is Label:
			text = c.atr((c as Label).text)
		elif c is Button:
			text = c.atr((c as Button).text)
		elif c is RichTextLabel:
			text = (c as RichTextLabel).get_parsed_text()
		text = text.replace("\n", " ").strip_edges()
		if _letters.search(text) != null:   # arrows and crosses are not read
			parts.append(text if text.right(1) in [".", "!", "?", ":", "…"] else text + ".")
	for child in node.get_children():
		_collect(child, parts)


static func _keep_pumping() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if _pumping or tree == null:
		return
	_pumping = true
	tree.create_timer(PUMP_EVERY, true).timeout.connect(func() -> void:
		_pumping = false
		pump(_now()))


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
