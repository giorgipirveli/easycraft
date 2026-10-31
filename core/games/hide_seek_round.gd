class_name HideSeekRound
extends RefCounted
## Hide-and-seek as pure rules (M4 Wave 3, agent H; spec §17.5, research T6). One seeker (chosen, or
## random) counts COUNT_TIME at the base while the others hide within AREA_RADIUS of it; then seekers
## find hiders by seeing them (StealthRules' sight: a 120° view and a clear line, never through walls)
## within FIND_DISTANCE, or in the hiding spot they tap; a found hider joins the seekers (nobody sits
## out); hints after HINT_AFTER; the round ends when everyone is found or after SEEK_TIME of seeking.
## Participants are keys (GameRules.player_key / bot_key). The host keeps one; every game gets a copy
## through to_state / from_state.

enum Phase { IDLE, COUNTING, SEEKING, OVER }

const COUNT_TIME := 30.0
const SEEK_TIME := 180.0
const FIND_DISTANCE := 3.0        # blocks, eyes to eyes
const FIND_SLACK := 0.75          # the host's slack for a guest's request (latency)
const SPOT_REACH := StealthRules.HIDE_REACH + StealthRules.HIDE_SLACK   # eyes to a tapped spot's centre
const AREA_RADIUS := 40.0         # hiders stay this close to the base (gently pushed back)
const HINT_AFTER := 120.0         # seconds of seeking before the first hint (nobody waits forever)
const HINT_EVERY := 20.0
const MIN_PLAYERS := 2

## advance() events.
const SEEK := &"seek"             # the counting is over: ready or not
const HINT := &"hint"
const TIME_UP := &"time_up"
## Results.
const ALL_FOUND := &"all_found"
const ENDED := &"ended"           # the seekers all left

var phase: Phase = Phase.IDLE
var elapsed := 0.0                # seconds in this phase
var base := Vector3.ZERO          # where the first seeker counts
var seekers: Array[String] = []   # the first seeker, then everyone found, in order
var hiders: Array[String] = []    # everyone who hid (found ones too)
var found: Array[String] = []
var found_by := {}                # hider key -> seeker key
var names := {}                   # key -> the name shown ("Pip (bot)")
var result: StringName = &""

var _next_hint := HINT_AFTER


## The seeker: the one chosen when they play, else participants[roll] ("" when nobody plays).
static func pick_seeker(participants: Array[String], choice: String, roll: int) -> String:
	if participants.is_empty():
		return ""
	if participants.has(choice):
		return choice
	return participants[posmod(roll, participants.size())]


## Starts counting with `seeker` at `base`; false (and nothing changes) without two players or a
## seeker who plays.
func start(participants: Array[String], seeker: String, at: Vector3) -> bool:
	if participants.size() < MIN_PLAYERS or not participants.has(seeker) or not at.is_finite():
		return false
	phase = Phase.COUNTING
	elapsed = 0.0
	base = at
	seekers = [seeker]
	hiders.clear()
	for k in participants:
		if k != seeker and not hiders.has(k):
			hiders.append(k)
	found.clear()
	found_by.clear()
	result = &""
	_next_hint = HINT_AFTER
	return true


## Moves the clock; returns what happened (SEEK, HINT, TIME_UP).
func advance(dt: float) -> Array[StringName]:
	var events: Array[StringName] = []
	if phase == Phase.COUNTING:
		elapsed += dt
		if elapsed >= COUNT_TIME:
			elapsed -= COUNT_TIME
			phase = Phase.SEEKING
			events.append(SEEK)
		else:
			return events
	if phase != Phase.SEEKING:
		return events
	if not SEEK in events:
		elapsed += dt
	if elapsed >= SEEK_TIME:
		_end(TIME_UP)
		events.append(TIME_UP)
		return events
	if elapsed >= _next_hint:
		_next_hint += HINT_EVERY
		events.append(HINT)
	return events


## Seconds left in this phase.
func time_left() -> float:
	match phase:
		Phase.COUNTING:
			return maxf(COUNT_TIME - elapsed, 0.0)
		Phase.SEEKING:
			return maxf(SEEK_TIME - elapsed, 0.0)
	return 0.0


func seek_elapsed() -> float:
	return elapsed if phase == Phase.SEEKING else 0.0


func is_seeker(key: String) -> bool:
	return seekers.has(key)


func is_hiding(key: String) -> bool:
	return hiders.has(key) and not found.has(key)


func is_playing(key: String) -> bool:
	return seekers.has(key) or hiders.has(key)


func hiders_left() -> Array[String]:
	var out: Array[String] = []
	for k in hiders:
		if not found.has(k):
			out.append(k)
	return out


## A seeker found a hider: the hider joins the seekers. True when it counted.
func find(seeker: String, hider: String) -> bool:
	if phase != Phase.SEEKING or not seekers.has(seeker) or not is_hiding(hider):
		return false
	found.append(hider)
	found_by[hider] = seeker
	seekers.append(hider)
	if hiders_left().is_empty():
		_end(ALL_FOUND)
	return true


## Someone joins a round already on: hides while counting, else helps seek.
func join(key: String) -> void:
	if is_playing(key) or phase == Phase.IDLE or phase == Phase.OVER:
		return
	if phase == Phase.COUNTING:
		hiders.append(key)
	else:
		seekers.append(key)


## Someone left the world (or a bot friend went home).
func leave(key: String) -> void:
	seekers.erase(key)
	hiders.erase(key)
	found.erase(key)
	found_by.erase(key)
	if phase != Phase.COUNTING and phase != Phase.SEEKING:
		return
	if seekers.is_empty():
		_end(ENDED)
	elif hiders_left().is_empty():
		_end(ALL_FOUND)


func _end(why: StringName) -> void:
	phase = Phase.OVER
	result = why
	elapsed = 0.0


# --- Every game's copy ---

func to_state() -> Dictionary:
	return {"phase": int(phase), "elapsed": elapsed, "base": [base.x, base.y, base.z], "seekers": seekers.duplicate(),
		"hiders": hiders.duplicate(), "found": found.duplicate(), "found_by": found_by.duplicate(),
		"names": names.duplicate(), "result": String(result)}


## A copy from the host's state; anything broken is no round (IDLE).
static func from_state(d: Dictionary) -> HideSeekRound:
	var r := HideSeekRound.new()
	var p: Variant = d.get("phase")
	var b: Variant = d.get("base")
	if not typeof(p) in [TYPE_INT, TYPE_FLOAT] or int(p) < 0 or int(p) >= Phase.size() or not _nums3(b):
		return r
	r.phase = int(p) as Phase
	r.elapsed = clampf(float(d.get("elapsed", 0.0)), 0.0, SEEK_TIME) if typeof(d.get("elapsed")) in [TYPE_INT, TYPE_FLOAT] else 0.0
	r.base = Vector3(float(b[0]), float(b[1]), float(b[2]))
	r.seekers = _keys(d.get("seekers"))
	r.hiders = _keys(d.get("hiders"))
	r.found = _keys(d.get("found"))
	var by: Variant = d.get("found_by")
	if by is Dictionary:
		for k: Variant in by:
			r.found_by[str(k)] = str(by[k])
	var n: Variant = d.get("names")
	if n is Dictionary:
		for k: Variant in n:
			r.names[str(k)] = str(n[k]).substr(0, 40)
	r.result = StringName(str(d.get("result", "")))
	return r


static func _keys(v: Variant) -> Array[String]:
	var out: Array[String] = []
	if v is Array:
		for k: Variant in v:
			if k is String and not out.has(k) and out.size() < 16:
				out.append(k)
	return out


static func _nums3(v: Variant) -> bool:
	return v is Array and (v as Array).size() == 3 and (v as Array).all(
		func(x: Variant) -> bool: return typeof(x) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(x)))


# --- Seeing, hiding spots and the play area ---

## Does a seeker whose eyes are at `eye`, facing `facing`, see a hider whose eyes are at `target` and who
## is `vis` visible (StealthRules.visibility: 0 in a barrel, a closet or crouching in a bush)? The
## monsters' sight rules (FULL sight: in the view, a clear line, within 16 × vis) and FIND_DISTANCE
## (+ `slack` on the host). is_blocking(cell) -> bool.
static func can_see(eye: Vector3, facing: Vector3, target: Vector3, vis: float, is_blocking: Callable,
		slack: float = 0.0) -> bool:
	if not eye.is_finite() or not target.is_finite() or eye.distance_to(target) > FIND_DISTANCE + slack:
		return false
	var v := vis if vis <= 0.0 else minf(vis + slack / StealthRules.SIGHT, 1.0)   # hidden stays hidden
	return StealthRules.sight(eye, facing, target, v, is_blocking) == StealthRules.Sight.FULL


## Is a body inside the spot at `cell`: in it (a barrel or closet: `hidden_in`), or its feet or body
## in it (a bush)?
static func in_spot(cell: Vector3i, hidden_in: Vector3i, feet: Vector3) -> bool:
	if hidden_in == cell:
		return true
	if not feet.is_finite():
		return false
	var f := Vector3i(feet.floor())
	return f == cell or f + Vector3i.UP == cell


## Can a seeker whose eyes are at `eye` look into the spot at `cell` (a barrel, closet or bush)?
static func spot_in_reach(eye: Vector3, cell: Vector3i) -> bool:
	return eye.is_finite() and PlacementRules.in_reach(eye, cell, SPOT_REACH)


## A gentle push back towards the base for a body at `pos` outside the play area (flat; ZERO inside).
static func area_push(pos: Vector3, at: Vector3) -> Vector3:
	return StormRun.push(pos, Vector2(at.x, at.z), AREA_RADIUS)
