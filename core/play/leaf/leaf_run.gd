class_name LeafRun
extends RefCounted
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.5, §3.5b, §3.8, §3.10, rulings 8, 25, 32): one voyage inside
## the plant, from the moment the child is inside to the bud's "Let's grow back!": the clock, the leaf (LeafSim), the
## weather (LeafWeather), the judge (LeafBeats), help and Hoot's cues. Pure (no nodes): B2's host steps it every frame,
## passes on the child's acts (a door, a sugar, a pipe, SHOW ME) and acts on its cues (`take_cues`):
## - {say: line id}: Hoot says it (LeafVoyages.line, PlayVoice.say);
## - {ghost: "door", door: i} / {ghost: "carry"}: the ghost shows a step; the door moves (the sugar goes in) GHOST_TAP
##   later, here, so the host's finger or hands arrive as it happens;
## - {phase: name}, {weather: LeafWeather.at(...)} at each new segment, {beat: LeafBeats' result}, {rescue: true},
##   {bud_full: true}.
## The flow: ACT1 (5.1: the doors open and the leaf drooping; Hoot's line, the ghost shuts one door unless the child acts
## first, "Your turn!"; the hint and a second ghost only after idling, which makes B1 helped), FILL (every door shut: the
## vein refills the cells fast, B1 is judged as the leaf stands, the see-why line), PLAY (the weather's script; the
## first cloud and blaze voiced, the rest silent and judged; help only after two misses of a kind (Hoot says the cue,
## then the ghost does a door: helped) and a 30 % longer cloud; the "too dry" rescue; extra turns at the evening while
## the bud lacks sugar, up to the voyage's most), DONE (the bud full: the reverse dive is the host's).

const ACT1 := "act1"
const FILL := "fill"
const PLAY := "play"
const DONE := "done"
## The ghost shows a step this long before it happens (PlayHost.GHOST_TAP).
const GHOST_TAP := 1.1
## Between the two lines of a pair (L6 then the demonstration; L10 then L11).
const LINE_GAP := 3.0
## Act 1: this long after "Your turn!" (or the child's last act) without a door: the hint; as long again: a ghost door.
const ACT1_HINT := 10.0
const ACT1_GHOST := 10.0
## The trap: this long waiting with the doors shut, "Wait for the sun to hide."
const WAIT_LINE := 6.0
## The desert's first day: this long with the doors shut, "No clouds in the desert…"
const NO_CLOUDS := 12.0
## After two misses of a kind, into its next window with the doors still wrong: Hoot says the cue, then the ghost.
const HELP_HINT := 6.0
const HELP_GHOST := 10.0
## The child's doors in the weather before Hoot names them (L17).
const NAME_AFTER := 10
## The voiced blaze: the ghost carries a sugar to the gold pipe this far in.
const CARRY_AT := 3.0
## After "Let's grow back and see!" the voyage ends.
const END_AFTER := 2.0
## The fill ends with the leaf this full (the design's Act 2 starts at 0.95), or after FILL_MAX s.
const FILL_TO := 0.9
const FILL_MAX := 15.0
## A wrong window: under half the doors open where the rule opens them, more than two where it shuts them.
const WRONG_SHUT := 2

var voyage_id := ""
var voyage := {}
var sim: LeafSim
var weather: LeafWeather
var beats: LeafBeats
var phase := ""
## Seconds into the weather's script (PLAY).
var t := 0.0
## Seconds since start().
var clock := 0.0

var _cues: Array[Dictionary] = []
var _pending: Array[Dictionary] = []
var _said := {}
var _phase_t := 0.0
var _seg := -1
var _seg_id := ""
var _child_acted := false
var _demo_at := -1.0
var _turn_at := -1.0
var _act_t := 0.0           # since the child's last act (or "Your turn!") in act 1
var _act1_hinted := false
var _act1_help := false
var _standing_at := -1.0
var _why_at := -1.0
var _play_at := -1.0
var _child_doors := 0
var _misses := {}
var _help_due := {}
var _help_armed := ""
var _help_hint_at := -1.0
var _help_ghost_at := -1.0
var _rescuing := false
var _carry_at := -1.0
var _praise_from := 0
var _last_praise := ""
var _end_at := -1.0
var _wrong_pipe := 0
var _jar_seen := false
var _shut_build := false
var _made_before := 0.0


static func make(id: String, seed: int = 0) -> LeafRun:
	var r := LeafRun.new()
	r.voyage_id = id
	r.voyage = LeafVoyages.voyage(id)
	r.sim = LeafSim.make(r.voyage.get("sim", {}))
	r.weather = LeafWeather.for_voyage(id)
	r.beats = LeafBeats.for_voyage(id, r.weather)
	r._praise_from = posmod(seed, 97)
	return r


## The child is inside: act 1 (a voyage with one) or the weather.
func start() -> void:
	clock = 0.0
	_say("inside")
	if voyage.has("act1"):
		_set_phase(ACT1)
		_demo_at = LINE_GAP
	else:
		_begin_play()


func step(dt: float) -> void:
	if phase == "" or phase == DONE:
		return
	clock += dt
	_phase_t += dt
	_run_pending()
	match phase:
		ACT1:
			_act1(dt)
		FILL:
			_fill(dt)
		PLAY:
			_play(dt)


## The child's act on a door: its new state (open).
func toggle(door: int) -> bool:
	if phase == "" or phase == DONE or door < 0 or door >= sim.doors.size():
		return false
	_child_acted = true
	_act_t = 0.0
	var was := sim.doors[door]
	var now := sim.toggle(door)
	if phase == ACT1 and was and not now:
		_say_once("first_door")
	elif phase == PLAY:
		_child_doors += 1
		if _child_doors == NAME_AFTER:
			_say_once("name")
		var w := weather.at(t)
		if now and not bool(w.open) and (not beats.judges(int(w.index)) or (voyage_id == "5.T1" and int(w.index) == 0)):
			_say_once("too_hot")
	return now


## The child picks up a waiting sugar.
func take() -> bool:
	return phase != DONE and sim.take()


## The child puts a carried sugar into a pipe: the gold one takes it (to the bud); the blue one brings water in, so it
## bobs back (still carried).
func deliver(pipe: String) -> bool:
	if pipe != "gold":
		if _wrong_pipe < 2:
			_say("wrong_pipe")
		_wrong_pipe += 1
		return false
	if sim.deliver(1) <= 0:
		return false
	if sim.delivered == 1:
		_praise("deliver")
	return true


## SHOW ME: the ghost does the next step (help).
func show_me() -> void:
	if phase == ACT1:
		_act1_help = true
		_ghost_door(_first_door(true), false)
	elif phase == PLAY:
		var w := weather.at(t)
		var door := _first_door(not bool(w.open))
		if door >= 0:
			_ghost_door(door, bool(w.open))
		elif sim.waiting() > 0:
			_ghost_carry()
		else:
			return   # nothing to show: no help given
		beats.help(LeafBeats.SHOW_ME)


func take_cues() -> Array[Dictionary]:
	var out := _cues
	_cues = []
	return out


## The weather now: the script's (LeafWeather.at) while it plays; act 1 and the fill happen in the noon blaze.
func weather_now() -> Dictionary:
	if phase == PLAY or phase == DONE:
		return weather.at(t)
	var act: Dictionary = voyage.get("act1", {})
	var kind := str(act.get("kind", "blaze"))
	var k: Dictionary = weather.kinds.get(kind, {})
	return {"index": -1, "id": phase, "kind": kind, "since": _phase_t, "left": 0.0, "seconds": 0.0,
		"heat": float(k.get("heat", 1.0)), "light": float(k.get("light", 1.0)), "night": false, "open": false,
		"voiced": true, "longer": false, "dawn": 0.0}


## Sugar the child carries.
func carried() -> int:
	return sim.taken - sim.delivered


func finished() -> bool:
	return phase == DONE


## Every judged beat as a SkillShown event for the voyage's unit (the host records once, when the voyage ends).
func record(shown: SkillShown) -> void:
	beats.record(shown)


# --- The phases ----------------------------------------------------------------------------------------------------

func _act1(dt: float) -> void:
	var w := weather_now()
	w.floor = float(voyage.act1.get("floor", 0.0))
	sim.step(dt, w)
	_act_t += dt
	if _demo_at >= 0.0 and clock >= _demo_at:
		_demo_at = -1.0
		if not _child_acted:
			_ghost_door(_first_door(true), false, "your_turn")
		else:
			_turn_at = clock
	if _turn_at >= 0.0 and not _child_acted:
		if not _act1_hinted and clock - _turn_at >= ACT1_HINT:
			_act1_hinted = true
			_say("hint")
		elif _act1_hinted and not _act1_help and clock - _turn_at >= ACT1_HINT + ACT1_GHOST:
			_act1_help = true
			_ghost_door(_first_door(true), false)
	if sim.open_count() == 0:
		_set_phase(FILL)


func _fill(dt: float) -> void:
	var act: Dictionary = voyage.get("act1", {})
	var w := weather_now()
	w.refill = float(act.get("refill", 1.0))
	sim.step(dt, w)
	if sim.open_count() > 0 and _standing_at < 0.0:
		_set_phase(ACT1)
		return
	if _standing_at < 0.0 and sim.standing():
		_standing_at = clock
		_cues.append({"beat": beats.act1_done(_act1_help)})
		_say("all_shut")
		_why_at = clock + LINE_GAP
	if _why_at >= 0.0 and clock >= _why_at:
		_why_at = -1.0
		_say("why_doors")
		_play_at = clock + LINE_GAP
	if (_play_at >= 0.0 and clock >= _play_at and sim.water >= FILL_TO) or _phase_t >= FILL_MAX:
		if _standing_at < 0.0:
			_standing_at = clock
			_cues.append({"beat": beats.act1_done(_act1_help)})
		_begin_play()


func _begin_play() -> void:
	_set_phase(PLAY)
	t = 0.0
	_seg = -1
	_made_before = sim.made


func _play(dt: float) -> void:
	var w := weather.at(t)
	if int(w.index) != _seg or str(w.id) != _seg_id:
		w = _segment_started(w)
	var before := sim.made
	sim.step(dt, w)
	for r in beats.observe(w, sim, dt):
		_beat_judged(r)
	_during(w, sim.made - before)
	t += dt
	if weather.ended(t) and _end_at < 0.0:
		for r in beats.finish():
			_beat_judged(r)
		_top_up()
		_say("bud_full")
		_end_at = clock + END_AFTER
	elif _end_at < 0.0 and sim.bud_full() and _past_judged_turns():
		_cues.append({"bud_full": true})
		_say("bud_full")
		_end_at = clock + END_AFTER
	if _end_at >= 0.0 and clock >= _end_at:
		for r in beats.finish():
			_beat_judged(r)
		_set_phase(DONE)


## A new segment of the script began (`w`): its cues, and at the evening, one more turn while the bud still lacks sugar
## (a slower child gets more time: "the bud asks for more clouds when it isn't full").
func _segment_started(w: Dictionary) -> Dictionary:
	var need := int(sim.params.get("bud", 12))
	if str(w.kind) == "evening" and sim.delivered < need and weather.add_turn():
		w = weather.at(t)
	_seg = int(w.index)
	_seg_id = str(w.id)
	_cues.append({"weather": w})
	_help_armed = ""
	_carry_at = -1.0   # the ghost's carry is the voiced blaze's only
	var rule := _rule_of(str(w.kind))
	if _seg_id == "trap":
		_say("act2")
	elif bool(w.voiced) and bool(w.open):
		_say("first_open")
	elif bool(w.voiced):
		_say("first_shut")
		_carry_at = clock + CARRY_AT
	elif bool(w.night):
		_say_once("dusk")
	if bool(_help_due.get(rule, false)) and beats.judges(_seg):
		_help_armed = rule
		_help_hint_at = clock + HELP_HINT
		_help_ghost_at = clock + HELP_GHOST
	return w


## What the moment asks for while the weather plays.
func _during(w: Dictionary, built: float) -> void:
	var open := sim.open_count()
	if _seg_id == "trap" and open == 0 and float(w.since) >= WAIT_LINE:
		_say_once("wait")
	if voyage_id == "5.T1" and int(w.index) == 0 and open == 0 and float(w.since) >= NO_CLOUDS:
		_say_once("no_clouds")
	if sim.made >= 1.0 and _made_before < 1.0:
		_say_once("first_sugar")
	_made_before = sim.made
	if not _jar_seen and sim.jars >= 1.0:
		_jar_seen = true
		_say_once("first_jar")
	if not _shut_build and sim.model == LeafSim.CAM and not bool(w.night) and open == 0 and built > 0.0 \
			and _jar_seen:
		_shut_build = true
		_say_once("builds_shut")
	if _carry_at >= 0.0 and clock >= _carry_at and sim.waiting() > 0:
		_carry_at = -1.0
		_ghost_carry()
		_say("carry")
	if _help_armed != "" and _wrong(w):
		if _help_hint_at >= 0.0 and clock >= _help_hint_at:
			_help_hint_at = -1.0
			if _say("hint_open" if bool(w.open) else "hint_shut"):
				beats.help(LeafBeats.HINT)   # help counts only when it was really given
		elif _help_ghost_at >= 0.0 and clock >= _help_ghost_at:
			_help_ghost_at = -1.0
			_ghost_door(_first_door(not bool(w.open)), bool(w.open))
			beats.help(LeafBeats.GHOST)
	if sim.too_dry() and not _rescuing:
		_rescuing = true
		_say("too_dry")
		_cues.append({"rescue": true})
		beats.help(LeafBeats.RESCUE)
		var k := 0
		for i in sim.doors.size():
			if sim.doors[i]:
				_pending.append({"at": clock + GHOST_TAP * (k + 1), "door": i, "open": false})
				_cues.append({"ghost": "door", "door": i})
				k += 1
	elif _rescuing and sim.standing():
		_rescuing = false


func _beat_judged(r: Dictionary) -> void:
	if r.is_empty():
		return
	_cues.append({"beat": r})
	var rule := str(r.rule)
	if rule == "act1":
		return
	if str(r.help) != "":
		_help_due[rule] = false
	if bool(r.passed):
		_misses[rule] = 0
		if SkillShown.COUNTS.has(str(r.kind)):
			_praise("open" if rule in ["cloud", "night"] else "shut")
		return
	_misses[rule] = int(_misses.get(rule, 0)) + 1
	var adapt: Dictionary = voyage.get("adapt", {})
	if adapt.is_empty() or int(_misses[rule]) < int(adapt.get("misses", 2)):
		return
	_misses[rule] = 0
	_help_due[rule] = true
	if rule == "cloud":
		for i in range(weather.index_at(t) + 1, weather.segments.size()):
			if str(weather.segments[i].kind) == "cloud":
				weather.lengthen(i, float(adapt.get("longer", 0.3)))
				break


# --- Helpers -------------------------------------------------------------------------------------------------------

func _run_pending() -> void:
	var keep: Array[Dictionary] = []
	for p in _pending:
		if clock + 0.0001 < float(p.at):
			keep.append(p)
			continue
		if p.has("door"):
			sim.set_door(int(p.door), bool(p.open))
			if str(p.get("then", "")) == "your_turn" and phase == ACT1 and sim.open_count() > 0:
				_say("your_turn")
				_turn_at = clock
		elif p.has("carry"):
			if sim.take():
				sim.deliver(1)
	_pending = keep


func _ghost_door(door: int, open: bool, then: String = "") -> void:
	if door < 0:
		return
	_cues.append({"ghost": "door", "door": door})
	_pending.append({"at": clock + GHOST_TAP, "door": door, "open": open, "then": then})


func _ghost_carry() -> void:
	_cues.append({"ghost": "carry"})
	_pending.append({"at": clock + GHOST_TAP * 2.0, "carry": true})


## The first door that is open (`open`) or shut; -1 when none is.
func _first_door(open: bool) -> int:
	for i in sim.doors.size():
		if sim.doors[i] == open:
			return i
	return -1


## The doors are wrong for the window: too few open where the rule opens them, too many where it shuts them.
func _wrong(w: Dictionary) -> bool:
	var n := sim.open_count()
	if bool(w.open):
		return n * 2 < sim.doors.size()
	return n > WRONG_SHUT


func _rule_of(kind: String) -> String:
	match kind:
		"desert_day":
			return "day"
		"desert_night":
			return "night"
	return kind


## Whether the judged turns are all played (the evening, or the script's end): the bud's "grow back" waits for them.
func _past_judged_turns() -> bool:
	var i := weather.index_at(t)
	for j in range(i, weather.segments.size()):
		if beats.judges(j):
			return false
	return true


## At the end the plant never fails: what waits goes up the gold pipe and arrives as the child grows back.
func _top_up() -> void:
	var need := int(sim.params.get("bud", 12))
	while sim.delivered < need and sim.take():
		sim.deliver(1)
	sim.bud = maxf(sim.bud, float(sim.delivered))
	if sim.bud_full():
		_cues.append({"bud_full": true})


func _praise(kind: String) -> void:
	var plant := str(voyage.get("plant", ""))
	var choices: Array[String] = []
	for l in LeafVoyages.lines():
		var for_what := str(l.get("for", ""))
		var plants: Array = l.get("plants", [])
		if for_what != "" and (for_what == kind or for_what == "any") and (plants.is_empty() or plants.has(plant)):
			choices.append(str(l.id))
	choices.erase(_last_praise)
	if choices.is_empty():
		return
	_last_praise = choices[_praise_from % choices.size()]
	_praise_from += 1
	_cues.append({"say": _last_praise})


## Says the voyage's line for `cue`; false when the voyage has none.
func _say(cue: String) -> bool:
	var id: Variant = voyage.get("lines", {}).get(cue, "")
	if id is String and str(id) != "":
		_cues.append({"say": str(id)})
		_said[cue] = true
		return true
	return false


func _say_once(cue: String) -> void:
	if not _said.has(cue):
		_say(cue)


func _set_phase(p: String) -> void:
	phase = p
	_phase_t = 0.0
	_cues.append({"phase": p})
