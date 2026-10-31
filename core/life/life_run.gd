class_name LifeRun
extends RefCounted
## Owner #112, #113 (docs/design/life-skills.md §3, §10): one run of an Experience on a track, step by step (LifeCheck),
## whatever shows it (LifeRoomHost: flat or VR). Never stuck: after COACH_AFTER s without progress the coach shows the
## step again (by doing: ghost hands or a ghost finger), and again every COACH_AFTER s; the Expert try waits
## EXPERT_COACH_AFTER. A miss shows the step and it goes again. "Show me" is always there. Every coach showing is a hint.
## Stamps: Done it (finished), By myself (finished with no hint), Expert (the Expert try finished with no hint). The log
## (each step's seconds, whether it needed a hint, its safe mistakes tried) is the device's measurement (LifeMeasure),
## never sent. Life L3a (owner #118): a safe mistake (the wrong way tried: LifeCheck) is never a hint on a normal try
## (trying it and seeing why is learning), and one on the Expert try.

const COACH_AFTER := 10.0
const EXPERT_COACH_AFTER := 20.0
## Life L3a (owner #118, design §14: "time slows at danger moments on early tries and runs at real speed for the Expert
## stamp"): the room's time on a danger step (a step with "danger": true) on the first SLOW_TRIES tries, then later.
const SLOW_FIRST := 0.5
const SLOW_LATER := 0.75
const SLOW_TRIES := 2
## Kinds that are words or play by themselves: nothing to show, no hints counted. Life L2: a feeling (any picture is
## right: the coach never picks one for a child).
const NO_HINTS: Array[String] = ["info", "timelapse", "feel"]

var steps: Array[Dictionary] = []
var expert := false
var index := 0
var state := {}
var clock := 0.0
var step_clock := 0.0
var idle := 0.0
var finished := false
## Step index -> hints given on it.
var hints := {}
## Step index -> safe mistakes tried on it (Life L3a, owner #118).
var mistakes := {}
## Per finished step: {id, kind, seconds, hinted, mistakes}.
var steps_log: Array[Dictionary] = []


func _init(run_steps: Array[Dictionary] = [], expert_try: bool = false) -> void:
	steps = run_steps
	expert = expert_try
	if not steps.is_empty():
		state = LifeCheck.begin(steps[0])
	else:
		finished = true


func current() -> Dictionary:
	return steps[index] if index < steps.size() else {}


func hints_on(i: int) -> int:
	return int(hints.get(i, 0))


func mistakes_on(i: int) -> int:
	return int(mistakes.get(i, 0))


func total_mistakes() -> int:
	var n := 0
	for i: int in mistakes:
		n += int(mistakes[i])
	return n


## Life L3a: the room's time scale on a danger step: slow on the first tries, a little slow later, real time on the
## Expert try and when a grown-up chose "more real" (the Big track).
static func time_scale(runs_finished: int, expert_try: bool, real: bool = false) -> float:
	if expert_try or real:
		return 1.0
	return SLOW_FIRST if runs_finished < SLOW_TRIES else SLOW_LATER


func total_hints() -> int:
	var n := 0
	for i: int in hints:
		n += int(hints[i])
	return n


## One frame's sample (LifeCheck's keys): {progress, done, miss, mistake (Life L3a: the wrong way tried: the host
## freezes the room and the coach explains; a hint only on the Expert try), said, coach (show the step now), next (a new
## step began), finished}.
func feed(sample: Dictionary) -> Dictionary:
	var events := {"progress": false, "done": false, "miss": false, "mistake": false, "said": "", "coach": false,
		"next": false, "finished": false}
	if finished:
		return events
	var dt := float(sample.get("dt", 0.0))
	clock += dt
	step_clock += dt
	idle += dt
	if not sample.has("time"):
		sample["time"] = clock
	var step := current()
	var r := LifeCheck.feed(step, state, sample)
	events.progress = r.progress
	events.miss = r.miss
	events.said = r.said
	if r.progress:
		idle = 0.0
	if r.miss:
		_hint()
		events.coach = true
		idle = 0.0
	if bool(r.get("mistake", false)):
		events.mistake = true
		mistakes[index] = mistakes_on(index) + 1
		idle = 0.0
		if expert:
			_hint()   # the Expert stamp is the honest test: it waits for a try without the wrong way
	if r.done:
		events.done = true
		steps_log.append({"id": str(step.get("id", "")), "kind": str(step.get("kind", "")), "seconds": step_clock,
			"hinted": hints_on(index) > 0, "mistakes": mistakes_on(index)})
		index += 1
		step_clock = 0.0
		idle = 0.0
		if index >= steps.size():
			finished = true
			events.finished = true
		else:
			state = LifeCheck.begin(steps[index])
			events.next = true
		return events
	if not NO_HINTS.has(str(step.get("kind", ""))) and idle >= (EXPERT_COACH_AFTER if expert else COACH_AFTER):
		_hint()
		events.coach = true
		idle = 0.0
	return events


## The child asked the coach to show it.
func show_me() -> void:
	if not finished:
		_hint()
		idle = 0.0


func next_targets() -> Array[String]:
	return LifeCheck.next_targets(current(), state) if not finished else ([] as Array[String])


func fraction() -> float:
	return LifeCheck.fraction(current(), state) if not finished else 1.0


## {finished, stamps (LifeData's bits earned by this run), hints, seconds}.
func outcome() -> Dictionary:
	var stamps := 0
	if finished:
		stamps = LifeData.DONE
		if total_hints() == 0:
			stamps |= LifeData.SELF
			if expert:
				stamps |= LifeData.EXPERT
	return {"finished": finished, "stamps": stamps, "hints": total_hints(), "mistakes": total_mistakes(), "seconds": clock}


func _hint() -> void:
	if NO_HINTS.has(str(current().get("kind", ""))):
		return
	hints[index] = hints_on(index) + 1
