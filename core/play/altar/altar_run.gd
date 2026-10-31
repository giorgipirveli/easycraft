class_name AltarRun
extends RefCounted
## Owner #133, #134 (docs/design/games/balance-altar.md §3.5, §3.5b, §3.8, §3.10, rulings 4, 14; §4.3): one room
## played, altar after altar: the flow both B2's host (AltarTempleHost) and the cheat bots drive, so the bots test what a
## child meets. Pure, no nodes, seeded: `make(room, seed)` draws the room's numbers (new every visit; the taught altars'
## are fixed).
##
## The child's acts (`lift`, `handful`, `place`, `put_back`, `share_by`, `carry_across`, `tap_crystal`, `drag`) go to
## the current altar's AltarMoves; then the help policy: every second rule break the ghost does the next step of a
## shortest solution (H15, the altar HELPED); after CAP acts without the crystal freed the ghost frees it (SHOWN). SHOW ME
## (`show_me`) does one step any time; H16's hint (`hint_no_twin`, the host calls it 8 s into a lift the other pan cannot
## twin) is help too. A taught altar's demonstration (the ghost's twin take, the bowls) is not help. A freed altar is
## judged at once (AltarBeats); the host shows the free, then calls `next_altar`.
##
## What the host shows and says comes as cues (`take_cues`): {altar, n, state} an altar begins; {read} the rune line read
## at its start; {say} a line (first times once; praise never twice in a row); {ghost: op, demo} the ghost's move;
## {moved: op} a twin move; {broke: note}; {freed: n, weight, glimmer, by}; {count: [words]} the gems counting
## themselves; {judged: result}; {room_done}.

## Acts on one altar before the ghost frees its crystal.
const CAP := 40
## Every this many rule breaks, the ghost does one step.
const GHOST_EVERY := 2

var room_id := ""
var tools: Array[String] = []
var stage := AltarRunes.PICTURES
var index := -1
var moves: AltarMoves
var beats: AltarBeats

var _defs: Array[Dictionary] = []
var _starts: Array[AltarState] = []
var _cues: Array[Dictionary] = []
var _once := {}
var _judged := -1
var _praised := ""


static func make(id: String, seed: int, fade_stage: int = AltarRunes.PICTURES) -> AltarRun:
	var run := AltarRun.new()
	run.room_id = id
	run.tools = AltarHalls.tools(id)
	run.stage = fade_stage
	run.beats = AltarBeats.for_room(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for a: Dictionary in AltarHalls.altars(id):
		run._defs.append(a)
		run._starts.append(AltarHalls.altar_state(a, rng))
	return run


func count() -> int:
	return _defs.size()


## An altar's pans as the room begins it.
func start_state(i: int) -> AltarState:
	return _starts[i].copy()


## The current altar's catalogue entry ({} before the start and after the end).
func altar() -> Dictionary:
	return _defs[index] if index >= 0 and index < _defs.size() else {}


func is_done() -> bool:
	return index >= _defs.size()


func freed() -> bool:
	return moves != null and moves.freed()


## The room opens: Hoot's hook (and the Sky Room's frame), then the first altar.
func start() -> void:
	for cue: String in ["arrive", "hook", "frame"]:
		_say_cue(cue)
	index = 0
	_begin()


## After a free: the next altar (false, and the room's end lines, when there is none).
func next_altar() -> bool:
	if is_done():
		return false
	index += 1
	if index < _defs.size():
		_begin()
		return true
	_cues.append({"room_done": true})
	var why: Array = AltarHalls.cues(room_id).get("see_why", [])
	for cue: String in ["sings", "see_why_last", "name", "door", "end", "end_card"]:
		if cue == "see_why_last":
			if not why.is_empty():
				_say(str(why[-1]))
		else:
			_say_cue(cue)
	return false


# --- The child's acts ------------------------------------------------------------------------------------------------

func lift(pan: int, kind: String) -> Dictionary:
	return _after(moves.lift(pan, kind))


func handful(pan: int, kind: String) -> Dictionary:
	return _after(moves.handful(pan, kind))


func place(pan: int, kind: String) -> Dictionary:
	return _after(moves.place(pan, kind))


func put_back() -> Dictionary:
	return _after(moves.put_back())


func share_by(n: int) -> Dictionary:
	return _after(moves.share_by(n))


func carry_across(pan: int, kind: String) -> Dictionary:
	return _after(moves.carry_across(pan, kind))


func tap_crystal() -> Dictionary:
	return _after(moves.tap_crystal())


## A drag from a thing to its twin on the other pan: both at once (a twin take of one, or of a handful).
func drag(op: Dictionary) -> Dictionary:
	return _after(moves.commit(op))


## SHOW ME (the eye): the ghost does one step (help).
func show_me() -> void:
	if moves == null or moves.freed():
		return
	moves.note_help(AltarMoves.EYE)
	_ghost_step()


## H16: a lift the other pan cannot twin, after a wait (help: it tells the move back).
func hint_no_twin() -> void:
	if moves == null or not moves.no_twin():
		return
	moves.note_help(AltarMoves.HINT)
	_say_cue("no_twin")


## S3, once, after a long wait in the Sky Room: the goal restated, never the move (not help, ruling 16).
func remind_goal() -> void:
	if _once.has("wait"):
		return
	_once["wait"] = true
	_say_cue("wait")


func take_cues() -> Array[Dictionary]:
	var out := _cues
	_cues = []
	return out


## Adds the judged altars' events to `shown`.
func record(shown: SkillShown) -> int:
	return beats.record(shown)


# --- The flow -------------------------------------------------------------------------------------------------------

func _begin() -> void:
	var a := altar()
	moves = AltarMoves.start(_starts[index], tools)
	_cues.append({"altar": index, "n": int(a.n), "state": moves.state.copy()})
	if bool(a.get("great", false)):
		_say_cue("great")
	_cues.append({"read": AltarRunes.say(moves.state, stage)})
	match str(a.get("demo", "")):
		"twin_take":
			_say_cue("watch")
			_demo(AltarMoves.take(AltarState.GEM, 1))
			_say_cue("your_turn")
		"bowls":
			_say_cue("watch_bowls")
			_demo(AltarSolver.next_step(moves.state, tools))


func _demo(op: Dictionary) -> void:
	if op.is_empty():
		return
	moves.commit(op, AltarMoves.DEMO)
	_cues.append({"ghost": op, "demo": true})
	if moves.freed():
		_freed()


func _after(r: Dictionary) -> Dictionary:
	if moves == null or index < 0 or is_done():
		return r
	var note := str(r.get("broke", ""))
	var moved: Dictionary = r.get("moved", {})
	if note != "":
		_cues.append({"broke": note})
		if _first("first_break"):
			_say_cue("first_break")
			_say_cue("see_why_break")
		if note == AltarMoves.ACROSS and _first("across"):
			_say_cue("across")
		if note == AltarMoves.UNFAIR:
			_say_cue("uneven")
		if moves.breaks % GHOST_EVERY == 0 and not moves.freed():
			moves.note_help(AltarMoves.GHOST_STEP)
			_say_cue("ghost_step")
			_ghost_step()
	elif not moved.is_empty():
		_cues.append({"moved": moved})
		if _first("first_twin"):
			_say_cue("first_twin")
		if _popped(moved) and _first("first_pop"):
			_say_cue("first_pop")
	if moves.freed():
		_freed()
	elif moves.acts >= CAP:
		_finish()
	return r


## A gem put on a pan with balloons, or a balloon on a pan with gems: a zero pair floated off.
func _popped(op: Dictionary) -> bool:
	if str(op.verb) != AltarMoves.ADD:
		return false
	var n := int(op.n)
	var s := moves.state
	if str(op.kind) == AltarState.GEM:
		return s.lk - n < 0 or s.rk - n < 0
	if str(op.kind) == AltarState.BALLOON:
		return s.lk + n > 0 or s.rk + n > 0
	return false


func _ghost_step() -> void:
	var op := AltarSolver.next_step(moves.state, tools)
	if op.is_empty():
		return
	moves.commit(op, AltarMoves.GHOST)
	_cues.append({"ghost": op, "demo": false})
	if moves.freed():
		_freed()


## The ghost frees an altar the child has not freed after CAP acts.
func _finish() -> void:
	moves.note_help(AltarMoves.FINISHED)
	for i in AltarSolver.DEPTH:
		if moves.freed():
			break
		var op := AltarSolver.next_step(moves.state, tools)
		if op.is_empty():
			break
		moves.commit(op, AltarMoves.GHOST)
		_cues.append({"ghost": op, "demo": false})
	if moves.freed():
		_freed()


func _freed() -> void:
	if _judged == index:
		return
	_judged = index
	var a := altar()
	var weight := moves.state.shown_weight()
	var result := beats.judge(a, moves)
	_cues.append({"freed": int(a.n), "weight": weight, "glimmer": str(a.get("glimmer", "")), "by": moves.freed_by})
	_say_cue("freed", {"n": weight})
	var words: Array[String] = []
	for i in range(1, weight + 1):
		words.append(AltarRunes.number_word(i))
	_cues.append({"count": words})
	if _first("first_glimmer"):
		_say_cue("first_glimmer")
	if str(a.get("demo", "")) == "bowls":
		_say_cue("see_why_share")
	_cues.append({"judged": result})
	if bool(result.counts):
		_praise(result)


## Praise names the strategy, never the same line twice in a row.
func _praise(result: Dictionary) -> void:
	var lines: Array = AltarHalls.cues(room_id).get("praise", [])
	if lines.is_empty():
		return
	var want := "any"
	var form := str(result.form)
	if int(result.ops) > 1 and int(result.ops) <= int(result.budget) - 1:
		want = "shortest"
	elif form.begins_with("add") or form.begins_with("sub"):
		want = "take"
	elif form.begins_with("mul"):
		want = "share"
	var pick := ""
	for l: Variant in lines:
		var id := str(l)
		if id == _praised:
			continue
		if _praise_for(id) == want:
			pick = id
			break
	if pick == "":
		var any := lines.filter(func(l: Variant) -> bool: return str(l) != _praised and _praise_for(str(l)) == "any")
		pick = str(any[(index + int(result.n)) % any.size()]) if not any.is_empty() else ""
	if pick != "":
		_praised = pick
		_say(pick)


static func _praise_for(id: String) -> String:
	for l: Dictionary in AltarHalls.lines():
		if str(l.get("id", "")) == id:
			return str(l.get("for", "any"))
	return "any"


func _first(key: String) -> bool:
	if _once.has(key):
		return false
	_once[key] = true
	return true


func _say_cue(cue: String, vars: Dictionary = {}) -> void:
	var id: Variant = AltarHalls.cues(room_id).get(cue, "")
	if id is String and str(id) != "":
		_say(str(id), vars)


func _say(id: String, vars: Dictionary = {}) -> void:
	var text := AltarHalls.say(id, vars)
	if text != "":
		_cues.append({"say": text, "line": id})
