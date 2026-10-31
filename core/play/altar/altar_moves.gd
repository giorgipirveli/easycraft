class_name AltarMoves
extends RefCounted
## Owner #133, #134 (docs/design/games/balance-altar.md §3.4, §3.5's rules table, rulings 2-6, §4.3; ported from the
## phase A model, model/altar_rules.py): the altar's twin rules, at two levels. Pure, no nodes.
##
## The twin moves (static): an operation is the same done to both pans, as a Dictionary {verb, kind, n}:
## - take(kind, n): lift n gems, balloons or crystals off BOTH pans (both must have them);
## - add(kind, n): put n gems (the gem bag), balloons (the balloon pump) or crystals (the well, phase C) on BOTH pans;
## - share(n): sort BOTH pans into n bowls (2-6, the rack) and keep one share: fair only if every amount divides.
## A gem and a balloon on one pan cancel by themselves (the state's amounts are net).
##
## The hands (an instance: one altar being played): a lift (or a placement from a supply) WAITS for its twin on the
## other pan; more of the same on the same pan grows the batch; the twin on the other pan commits it once it matches. A
## long press takes a handful (every one of that kind on the pan), the twin long press the same number. Anything else
## while something waits is a RULE BREAK (the waiting things spring back, nothing changes): another kind, the other verb,
## a share, tapping the crystal. Carrying a thing across and an uneven share are rule breaks too. Putting back is free.
## Each act returns {ok (something happened), moved (the committed operation, or {}), broke (the break's note, or ""),
## waiting (something still waits)}. The record a judge reads: `breaks`, `notes`, `ops` (the child's operations,
## consecutive ones of the same verb and kind merged: taking three pairs one by one is one "take the gems"), `acts`
## (every act, a tap on nothing too: the ghost finishes an altar after AltarRun.CAP), `helped` and `helps` (which help),
## `freed_by`.

const TAKE := "take"
const ADD := "add"
const SHARE := "share"
const LIFT := "lift"
const PLACE := "place"
## The most one supply move puts on each pan, and the rack's bowls (2-6).
const MAX_ADD := 12
const MIN_SHARE := 2
const MAX_SHARE := 6
## The tools a room offers (taking with the hands is always there).
const BOWLS := "bowls"
const GEM_BAG := "gem_bag"
const PUMP := "pump"
const WELL := "well"
const SUPPLY := {"gem": GEM_BAG, "balloon": PUMP, "crystal": WELL}
## The notes of a rule break (the journal's misconceptions, design §3.10).
const ONE_PAN := "one pan"
const ACROSS := "carried across"
const UNFAIR := "unfair share"
const NO_TWIN := "no twin"
## Who freed the crystal (or did a move).
const CHILD := "child"
const GHOST := "ghost"
const DEMO := "demo"
## The kinds of help (each makes the altar HELPED; the note says which): the ghost's step after a second rule break,
## SHOW ME (the eye), H16's hint (a lift the other pan cannot twin), the ghost freeing the crystal after AltarRun.CAP.
const GHOST_STEP := "ghost step"
const EYE := "eye"
const HINT := "hint"
const FINISHED := "ghost freed it"

var state: AltarState
var start_state: AltarState
var tools: Array[String] = []
## {} or {pan, verb (LIFT or PLACE), kind, count (on the batch's pan), twins (on the other pan)}
var waiting := {}
var breaks := 0
var notes: Array[String] = []
var ops := 0
var acts := 0
var helped := false
## The help given, in order (GHOST_STEP, EYE, HINT, FINISHED).
var helps: Array[String] = []
var freed_by := ""
var _last := ""


static func start(s: AltarState, room_tools: Array[String]) -> AltarMoves:
	var m := AltarMoves.new()
	m.state = s.copy()
	m.start_state = s.copy()
	m.tools = room_tools.duplicate()
	return m


# --- The twin moves ------------------------------------------------------------------------------------------------

static func take(kind: String, n: int) -> Dictionary:
	return {"verb": TAKE, "kind": kind, "n": n}


static func add(kind: String, n: int) -> Dictionary:
	return {"verb": ADD, "kind": kind, "n": n}


static func share(n: int) -> Dictionary:
	return {"verb": SHARE, "kind": "", "n": n}


## "take gem 3", "share 2" (tests, notes and the ghost's cue).
static func name_of(op: Dictionary) -> String:
	if op.is_empty():
		return ""
	if str(op.verb) == SHARE:
		return "share %d" % int(op.n)
	return "%s %s %d" % [op.verb, op.kind, int(op.n)]


## What merges consecutive operations into one: the verb and kind (shares all merge, as the model counts them).
static func tag(op: Dictionary) -> String:
	return SHARE if str(op.verb) == SHARE else "%s %s" % [op.verb, op.kind]


static func legal(s: AltarState, op: Dictionary, room_tools: Array[String]) -> bool:
	var n := int(op.get("n", 0))
	match str(op.get("verb", "")):
		TAKE:
			var kind := str(op.kind)
			return n >= 1 and s.amount(AltarState.LEFT, kind) >= n and s.amount(AltarState.RIGHT, kind) >= n
		ADD:
			return room_tools.has(str(SUPPLY.get(str(op.kind), "-"))) and n >= 1 and n <= MAX_ADD
		SHARE:
			return room_tools.has(BOWLS) and n >= MIN_SHARE and n <= MAX_SHARE and s.lc % n == 0 and s.lk % n == 0 \
				and s.rc % n == 0 and s.rk % n == 0
	return false


## The pans after an operation (a new state; legality is the caller's).
static func apply(s: AltarState, op: Dictionary) -> AltarState:
	var t := s.copy()
	var n := int(op.n)
	match str(op.verb):
		TAKE, ADD:
			var sign := -1 if str(op.verb) == TAKE else 1
			match str(op.kind):
				AltarState.GEM:
					t.lk += sign * n
					t.rk += sign * n
				AltarState.BALLOON:
					t.lk -= sign * n
					t.rk -= sign * n
				AltarState.CRYSTAL:
					t.lc += sign * n
					t.rc += sign * n
				AltarState.CRYSTAL_BALLOON:
					t.lc -= sign * n
					t.rc -= sign * n
		SHARE:
			t.lc /= n
			t.lk /= n
			t.rc /= n
			t.rk /= n
	return t


## Every legal twin move: takes of every size, adds up to `max_add`, shares by every count that divides.
static func legal_ops(s: AltarState, room_tools: Array[String], max_add: int = MAX_ADD) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for kind: String in AltarState.KINDS:
		var most := mini(s.amount(AltarState.LEFT, kind), s.amount(AltarState.RIGHT, kind))
		for n in range(1, most + 1):
			out.append(take(kind, n))
	for kind: String in SUPPLY:
		if room_tools.has(str(SUPPLY[kind])):
			for n in range(1, max_add + 1):
				out.append(add(kind, n))
	if room_tools.has(BOWLS):
		for n in range(MIN_SHARE, MAX_SHARE + 1):
			var op := share(n)
			if legal(s, op, room_tools):
				out.append(op)
	return out


# --- The hands ------------------------------------------------------------------------------------------------------

func freed() -> bool:
	return waiting.is_empty() and state.freed()


## How many things wait (lifted, or placed) on `pan` now.
func lifted(pan: int) -> int:
	if waiting.is_empty():
		return 0
	return int(waiting.count) if int(waiting.pan) == pan else int(waiting.twins)


## The kind waiting ("" when nothing does).
func waiting_kind() -> String:
	return "" if waiting.is_empty() else str(waiting.kind)


## A lift the other pan cannot twin (it hasn't that many of that kind).
func no_twin() -> bool:
	if waiting.is_empty() or str(waiting.verb) != LIFT:
		return false
	return state.amount(1 - int(waiting.pan), str(waiting.kind)) < int(waiting.count)


## A tap on a thing on a pan: it rises and waits (or it is the twin, or it grows the batch).
func lift(pan: int, kind: String) -> Dictionary:
	acts += 1
	if state.freed():
		return _result(false)
	return _batch(LIFT, pan, kind, 1, false)


## A long press on a pan: every thing of that kind there (or the twin handful: the same number).
func handful(pan: int, kind: String) -> Dictionary:
	acts += 1
	if state.freed():
		return _result(false)
	return _batch(LIFT, pan, kind, state.amount(pan, kind), true)


## A thing from the room's supply (the gem bag, the balloon pump) put on a pan: it waits for its twin.
func place(pan: int, kind: String) -> Dictionary:
	acts += 1
	if state.freed() or not tools.has(str(SUPPLY.get(kind, "-"))):
		return _result(false)
	return _batch(PLACE, pan, kind, 1, false)


## A tap on a waiting thing: everything waiting goes back where it was. Free.
func put_back() -> Dictionary:
	acts += 1
	var had := not waiting.is_empty()
	waiting = {}
	return _result(had)


## The bowls set to `n` and the seal pressed: both pans sorted into n shares, one kept.
func share_by(n: int) -> Dictionary:
	acts += 1
	if state.freed() or not tools.has(BOWLS) or n < MIN_SHARE or n > MAX_SHARE:
		return _result(false)
	if not waiting.is_empty():
		return _break(_waiting_break())
	var op := share(n)
	if not legal(state, op, tools):
		return _break(UNFAIR)
	return _commit(op, CHILD)


## A thing lifted off one pan and dropped on the other (the "move it across" shortcut): refused.
func carry_across(pan: int, kind: String) -> Dictionary:
	acts += 1
	if state.freed() or (state.amount(pan, kind) == 0 and waiting.is_empty()):
		return _result(false)
	return _break(ACROSS)


## The crystal tapped: it says its name, or (while something waits) it is a rule break.
func tap_crystal() -> Dictionary:
	acts += 1
	if not waiting.is_empty() and not state.freed():
		return _break(_waiting_break())
	return _result(false)


## A whole twin move at once: a drag from a thing to its twin (the child's), the ghost's step (help) or a taught
## altar's demonstration (no help). An illegal one is a rule break.
func commit(op: Dictionary, by: String = CHILD) -> Dictionary:
	if by == CHILD:
		acts += 1
	if state.freed():
		return _result(false)
	if not legal(state, op, tools):
		if by != CHILD:
			return _result(false)
		return _break(UNFAIR if str(op.verb) == SHARE else ONE_PAN)
	waiting = {}
	return _commit(op, by)


## Help was given on this altar (GHOST_STEP, EYE, HINT, FINISHED): it can no longer be SOLVED.
func note_help(kind: String) -> void:
	helped = true
	if not helps.has(kind):
		helps.append(kind)


func _batch(verb: String, pan: int, kind: String, n: int, whole: bool) -> Dictionary:
	if n <= 0:
		return _result(false)
	if waiting.is_empty():
		if verb == LIFT and state.amount(pan, kind) < 1:
			return _result(false)
		waiting = {"pan": pan, "verb": verb, "kind": kind, "count": mini(n, MAX_ADD) if verb == PLACE else n,
			"twins": 0}
		return _result(true)
	if str(waiting.verb) != verb or str(waiting.kind) != kind:
		return _break(_waiting_break())
	var first := int(waiting.pan) == pan
	if first:
		var most := state.amount(pan, kind) if verb == LIFT else MAX_ADD
		var want := most if whole else int(waiting.count) + 1
		if want > most or want <= int(waiting.count):
			return _result(false)
		waiting.count = want
		return _result(true)
	var room := state.amount(pan, kind) if verb == LIFT else int(waiting.count)
	room = mini(room, int(waiting.count))
	var twins := room if whole else int(waiting.twins) + 1
	if twins > room or twins <= int(waiting.twins):
		return _result(false)
	waiting.twins = twins
	if twins < int(waiting.count):
		return _result(true)
	var op := take(kind, twins) if verb == LIFT else add(kind, twins)
	waiting = {}
	return _commit(op, CHILD)


func _waiting_break() -> String:
	return NO_TWIN if no_twin() else ONE_PAN


func _commit(op: Dictionary, by: String) -> Dictionary:
	state = apply(state, op)
	waiting = {}
	if by == CHILD:
		var t := tag(op)
		if t != _last:
			ops += 1
			_last = t
	else:
		_last = ""
		if by == GHOST:
			helped = true
	if state.freed():
		freed_by = by
	return {"ok": true, "moved": op, "broke": "", "waiting": false}


func _break(note: String) -> Dictionary:
	breaks += 1
	notes.append(note)
	waiting = {}
	return {"ok": true, "moved": {}, "broke": note, "waiting": false}


func _result(ok: bool) -> Dictionary:
	return {"ok": ok, "moved": {}, "broke": "", "waiting": not waiting.is_empty()}
