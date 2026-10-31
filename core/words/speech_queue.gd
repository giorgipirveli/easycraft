class_name SpeechQueue
extends RefCounted
## The lines waiting to be read aloud on this device (M3 Task 21a, research O6), as pure rules: ReadAloud asks
## next() when the speaker is free. A speaker button reads at once (it cuts in and clears what waits); "Read to
## me" lines wait their turn, are never read twice in a row, never read late (a toast long gone) and never more
## than MAX_WAITING wait (the oldest goes). Other players' names are never read out (without_names): their
## words never are (the chat is never read at all).

const MAX_WAITING := 3
const MAX_AGE := 8.0        # seconds a line may wait before it is too late to read
const REPEAT_GAP := 6.0     # seconds before the same line may be read again

var _waiting: Array = []    # [text, pushed_at]
var _interrupt := false
var _last_text := ""
var _last_at := -INF


## Adds a line pushed at `now` (seconds); `urgent` (a speaker button) reads it next, cutting in. False when
## it is not read (empty, or the same line waits or was just read).
func push(text: String, now: float, urgent := false) -> bool:
	var t := text.strip_edges()
	if t == "":
		return false
	if urgent:
		_waiting.clear()
		_waiting.append([t, now])
		_interrupt = true
		return true
	if t == _last_text and now - _last_at < REPEAT_GAP:
		return false
	for w: Array in _waiting:
		if w[0] == t:
			return false
	_waiting.append([t, now])
	while _waiting.size() > MAX_WAITING:
		_waiting.pop_front()
	return true


## The line to read now ("" for none): only when the speaker is free, or at once after a button's cut-in.
func next(now: float, speaking: bool) -> String:
	if speaking and not _interrupt:
		return ""
	while not _waiting.is_empty() and not _interrupt and now - float(_waiting[0][1]) > MAX_AGE:
		_waiting.pop_front()
	_interrupt = false
	if _waiting.is_empty():
		return ""
	var line: Array = _waiting.pop_front()
	_last_text = line[0]
	_last_at = now
	return line[0]


## True while a button's line waits to cut in (the speaker should stop what it says).
func interrupting() -> bool:
	return _interrupt


func waiting() -> int:
	return _waiting.size()


func clear() -> void:
	_waiting.clear()
	_interrupt = false


## `text` with every one of `names` (other players', as whole words) read as `instead`.
static func without_names(text: String, names: Array, instead: String) -> String:
	var out := text
	for n: Variant in names:
		var name := str(n).strip_edges()
		if name == "":
			continue
		var re := RegEx.create_from_string("(?<![\\p{L}\\p{N}_])" + _escaped(name) + "(?![\\p{L}\\p{N}_])")
		var first := re.search(out)
		if first and first.get_start() == 0:   # a sentence starts with it: "A friend was …" (English letters only)
			var cap := instead.left(1).to_upper() + instead.substr(1) if instead.unicode_at(0) < 128 else instead
			out = cap + out.substr(first.get_end())
		out = re.sub(out, instead, true)
	return out


static func _escaped(s: String) -> String:
	var out := ""
	for ch in s:
		out += ("\\" + ch) if "\\^$.|?*+()[]{}".contains(ch) else ch
	return out
