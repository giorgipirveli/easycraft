class_name BabbleVoices
extends Node
## Babble voices on this device (M3 Task 21a, research F7): buddies, bot friends, Tilly and the story friends,
## and a pet parrot "talk" in cute nonsense syllables at their own pitch (BabbleRules: kind, size, a personality
## from the name). One per world, on every peer (the sandbox adds it; cosmetic, nothing is sent). A bot friend's
## chat line babbles by itself (it hears Session.chat_received); others call BabbleVoices.say(). The syllables
## are Audio's pooled players (&"babble"); the animals' chorus keeps quiet while a line plays (it hears them).

const GROUP := &"babble_voices"
const ANSWER_TIME := 4.0          # a bot friend's line this soon after the child spoke answers the child

## A line started: who, how many syllables, at what pitch (tests and tools).
signal said(speaker: Node3D, syllables: int, pitch: float)

var rules := BabbleRules.new()
var rng := RandomNumberGenerator.new()
## Where this device hears from (default: the current camera; tests set a Callable returning a Vector3).
var listener := Callable()

var _now := 0.0
var _lines: Array[Dictionary] = []   # {speaker, at: Array[float], next, start, pitch, volume, head}
var _child_spoke_at := -INF


func _ready() -> void:
	add_to_group(GROUP)
	rng.randomize()
	Session.chat_received.connect(_on_chat)


## `speaker` (a character in the world) babbles a line as long as `text`; `answer`: it answers the child's own
## tap or words (never held back). False when it keeps quiet (another line plays, it just talked, too far).
static func say(speaker: Node3D, kind: StringName, size: float, text: String, answer := false, who := "") -> bool:
	if not is_instance_valid(speaker) or not speaker.is_inside_tree():
		return false
	var voices := speaker.get_tree().get_first_node_in_group(GROUP) as BabbleVoices
	return voices != null and voices.speak(speaker, kind, size, text, answer, who)


func speak(speaker: Node3D, kind: StringName, size: float, text: String, answer := false, who := "") -> bool:
	var ear := _ear()
	if not ear.is_finite() or not is_instance_valid(speaker):
		return false
	var id := who if who != "" else str(speaker.name)
	var dist := speaker.global_position.distance_to(ear)
	if not rules.may_talk(id, _now, dist, answer):
		return false
	var at := BabbleRules.schedule(BabbleRules.syllables(text), rng)
	var pitch := BabbleRules.pitch(kind, size, BabbleRules.personality(id))
	rules.talked(id, _now, BabbleRules.line_seconds(at))
	_lines.append({"speaker": speaker, "at": at, "next": 0, "start": _now, "pitch": pitch,
		"volume": BabbleRules.volume_db(dist), "head": Vector3(0, clampf(size * 0.6, 0.4, 3.0), 0)})
	said.emit(speaker, at.size(), pitch)
	_play_due()
	return true


func _process(delta: float) -> void:
	if not _lines.is_empty():
		step(delta)
	else:
		_now += delta


## `delta` seconds of babble (tests step it directly).
func step(delta: float) -> void:
	_now += delta
	_play_due()


## Lines still playing.
func talking() -> int:
	return _lines.size()


func _play_due() -> void:
	for i in range(_lines.size() - 1, -1, -1):
		var line := _lines[i]
		if not is_instance_valid(line.speaker):   # owner #37: gone while it talked (Nico's cart at sunset)
			_lines.remove_at(i)
			continue
		var speaker := line.speaker as Node3D
		var at: Array[float] = line.at
		if not speaker.is_inside_tree():
			_lines.remove_at(i)
			continue
		while int(line.next) < at.size() and _now - float(line.start) >= at[int(line.next)]:
			Audio.play(BabbleRules.SOUND, speaker.global_position + line.head, float(line.volume), float(line.pitch))
			line.next = int(line.next) + 1
		if int(line.next) >= at.size():
			_lines.remove_at(i)


func _ear() -> Vector3:
	if listener.is_valid():
		return listener.call()
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	return cam.global_position if cam else Vector3.INF


## A bot friend's line babbles at that friend (the chat shows its words; players' own lines never babble).
func _on_chat(from: String, text: String, kind: StringName) -> void:
	if kind == &"chat" and from == str(Session.chat_names.get(multiplayer.get_unique_id(), "")):
		_child_spoke_at = _now
		return
	if kind != &"bot" or not is_inside_tree():
		return
	for b in get_tree().get_nodes_in_group(&"bot_friends"):
		var bot := b as Node3D
		if bot and BotRules.chat_name(str(bot.get("bot_name"))) == from:
			speak(bot, &"bot", BabbleRules.NORMAL_SIZE, text, _now - _child_spoke_at <= ANSWER_TIME, str(bot.get("bot_name")))
			return
