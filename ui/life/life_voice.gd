class_name LifeVoice
extends RefCounted
## Owner #113 (docs/design/life-skills.md §10: "heard, not read"): every line of Life is read aloud on the Little track
## (cutting in, one at a time: the newest line is the one that matters), and on the Middle and Big tracks when "Read to
## me" is on (or a speaker button is pressed). The system's own voice through ReadAloud; nothing is recorded.


static func say(text: String, track: String) -> void:
	if text.strip_edges() == "":
		return
	if track == "little":
		ReadAloud.speak(text)
	else:
		ReadAloud.auto(text)
