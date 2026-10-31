class_name LeafJourney
extends RefCounted
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.5 steps 1-3 and 9-11, §3.5b steps 1-2 and 8, §3.8; the B2
## brief): a voyage from the garden and back, as LeafVoyageHost plays it. Pure (no nodes), stepped by the host, which
## passes on the child's acts and acts on the cues (`take_cues`: {say: line id}, {glow: [targets]}, {ghost: "can" or
## "leaf"}, {stage: name}, and inside the plant B1's LeafRun's own).
## - HOOK, the garden: Hoot's hook; 5.1's can glows (the soil is watered: "Good! But it still droops", the leaf glows,
##   "Touch the leaf"); 5.T1 has no can (the sand is dry): the cactus's green stem glows at once. Nothing for GHOST_AFTER
##   s: the ghost shows the can, then the leaf (once each: teaching, not help).
## - DIVE (the leaf touched, DIVE_TIME s: Size Magic's steps), UNDER (under the leaf, UNDER_TIME s: "Up through a door!"),
##   INSIDE (LeafRun: act 1 and the weather, until the bud is full and "Let's grow back and see!" is said), RETURN (the
##   reverse dive, RETURN_TIME s), ANSWER (the world's answer, a line every ANSWER_GAP s: the bloom, the scales, the
##   idea, the honest end; the desert's night flower and its rule), END (the end card's line; the host's card).

const HOOK := "hook"
const DIVE := "dive"
const UNDER := "under"
const INSIDE := "inside"
const RETURN := "return"
const ANSWER := "answer"
const END := "end"
const GHOST_AFTER := 6.0
const LINE_GAP := 3.0
const DIVE_TIME := 3.0
const UNDER_TIME := 3.0
const RETURN_TIME := 3.0
const ANSWER_GAP := 3.2
## The world's answer, line by line (the voyage's cue names).
const ANSWERS := {"5.1": ["bloom", "scales", "idea", "honesty"], "5.T1": ["flower", "rule"]}

var voyage_id := ""
var voyage := {}
var run: LeafRun
var stage := ""
## Seconds into the stage.
var t := 0.0
var watered := false

var _cues: Array[Dictionary] = []
var _idle := 0.0
var _ghosted := {}
var _touch_line_at := -1.0
var _answer := 0


static func make(id: String, seed: int = 0) -> LeafJourney:
	var j := LeafJourney.new()
	j.voyage_id = id
	j.voyage = LeafVoyages.voyage(id)
	j.run = LeafRun.make(id, seed)
	return j


## 5.1 waters its soil first; the desert has no can.
func has_can() -> bool:
	return _line_of("watered") != ""


func start() -> void:
	_set_stage(HOOK)
	_say("hook")
	_cues.append({"glow": ["can"] if has_can() else ["leaf"]})


## The can poured on the soil (the hook's first step); false when there is nothing to water.
func water() -> bool:
	if stage != HOOK or not has_can() or watered:
		return false
	watered = true
	_idle = 0.0
	_say("watered")
	_cues.append({"glow": ["leaf"]})
	_touch_line_at = t + LINE_GAP
	return true


## The leaf (the cactus's stem) touched: the dive; false while the soil still waits for water.
func touch_leaf() -> bool:
	if stage != HOOK or (has_can() and not watered):
		return false
	_set_stage(DIVE)
	_say("dive")
	return true


func step(dt: float) -> void:
	if stage == "" or stage == END:
		return
	t += dt
	match stage:
		HOOK:
			_hook(dt)
		DIVE:
			if t >= DIVE_TIME:
				_set_stage(UNDER)
				_say("under_leaf")
		UNDER:
			if t >= UNDER_TIME:
				_set_stage(INSIDE)
				run.start()
		INSIDE:
			run.step(dt)
			if run.finished():
				_set_stage(RETURN)
		RETURN:
			if t >= RETURN_TIME:
				_set_stage(ANSWER)
				_next_answer()
		ANSWER:
			if t >= ANSWER_GAP:
				t = 0.0
				_next_answer()


## How far the stage has gone (0-1: the dive, under the leaf, the return; 0 elsewhere).
func progress() -> float:
	match stage:
		DIVE:
			return clampf(t / DIVE_TIME, 0.0, 1.0)
		UNDER:
			return clampf(t / UNDER_TIME, 0.0, 1.0)
		RETURN:
			return clampf(t / RETURN_TIME, 0.0, 1.0)
	return 0.0


## The cues since the last call: the journey's, then the run's.
func take_cues() -> Array[Dictionary]:
	var out := _cues
	_cues = []
	if run.phase != "":
		out.append_array(run.take_cues())
	return out


func _hook(dt: float) -> void:
	_idle += dt
	if _touch_line_at >= 0.0 and t >= _touch_line_at:
		_touch_line_at = -1.0
		_say("touch_leaf")
	var want := "can" if has_can() and not watered else "leaf"
	if _idle >= GHOST_AFTER and not _ghosted.has(want):
		_ghosted[want] = true
		_cues.append({"ghost": want})


func _next_answer() -> void:
	var lines: Array = ANSWERS.get(voyage_id, [])
	if _answer < lines.size():
		_say(str(lines[_answer]))
		_answer += 1
		return
	_set_stage(END)
	_say("end")


func _set_stage(s: String) -> void:
	stage = s
	t = 0.0
	_cues.append({"stage": s})


func _say(cue: String) -> void:
	var id := _line_of(cue)
	if id != "":
		_cues.append({"say": id})


func _line_of(cue: String) -> String:
	var id: Variant = voyage.get("lines", {}).get(cue, "")
	return str(id) if id is String else ""
