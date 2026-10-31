class_name PlayVoice
extends RefCounted
## Owner #133, rule 0 ("consider no one will start reading in the game … deliver education without just reading"):
## the play's voice. Every challenge's question, the hook, the coach's lines, the world's answer and the hint are spoken
## at once, by themselves (ReadAloud.speak: each cuts in, so the newest is heard), and a thing says its name when it is
## touched. The screen keeps only `caption`: the numbers themselves when they are the question ("300 + 40 + 7 = ?"),
## else the mechanic's few words ("Sort them!").
## `on()`: the device has a voice for the game's language and "Read to me" is on (on for everyone since owner #133, a
## grown-up may turn it off). Off, the play shows its words in full, as for a reader (PlayHud): a ruling, its cost
## in the notes (docs/devlog/parts/play-g0.md).

## A question this short (words with letters; numbers are not words) is shown as it is: it is mostly its numbers.
const CAPTION_WORDS := 3
const CAPTION_CHARS := 40


static func on() -> bool:
	return ReadAloud.available() and bool(Profile.data.settings.get("read_to_me", true))


## Says `text` now (as the School says it: SchoolSpeech), when the voice is on.
static func say(text: String) -> void:
	if on() and text.strip_edges() != "":
		ReadAloud.speak(SchoolSpeech.spoken(text))


## The few words on the screen while `ex` is spoken.
static func caption(ex: Dictionary) -> String:
	var prompt := str(ex.get("prompt", "")).strip_edges()
	if PlayReadless.words(prompt) <= CAPTION_WORDS and prompt.length() <= CAPTION_CHARS:
		return prompt
	return PlayMechanics.say_of(PlayMechanics.of_exercise(ex))
