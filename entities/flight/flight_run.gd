class_name FlightRun
extends RefCounted
## Plays a trip's steps (FlightPlan.steps) in time, as pure rules (owner #79, spec §25.3: the flight is played, not
## watched). A step runs its seconds; at its action's point (`at`) it holds and waits for the child: THROTTLE (the
## throttle up to 0.8 or more, or the big button), STAGE, LEGS, PARACHUTE (the ACTION button), BURN (the throttle held
## at 0.5 or more for FlightPlan.BURN_SECONDS in all). A child who does not act gets the autopilot after
## FlightPlan.ACTION_WAIT: it does it for them (a burn: it holds the throttle itself), kindly, so a trip never sticks.
## STAGE lets a stage go (dropped()): the last staging of a trip lets every lower stage go, so only the lander lands.
## The cockpit sets `throttle` (0..1, the child's) every frame; RocketFlight reads the phase, the progress, the waits.
## Owner #106: DESCEND (the DESCENT step) is never the autopilot's: the run gives the throttle to its FlightDescent
## until the touchdown. A soft one lands; too fast crashes and the rest of the trip becomes the way home
## (FlightPlan.crash_steps; crashed()). A practice descent (the Star Map's LAND) tries again after a crash, and after
## PRACTICE_TRIES Mission Control lands it (helped()), so a trip never sticks.

signal step_started(index: int)
## The rocket waits for the child to do `action` now.
signal action_needed(action: StringName)
## `action` is done, by the child or (by_autopilot) for them.
signal action_done(action: StringName, by_autopilot: bool)
signal finished
## Owner #106: the descent touched down (landed: soft, or Mission Control's after the practice tries; else a crash).
signal descent_over(landed: bool)

## Owner #106: a practice descent's tries before Mission Control lands it, and the pause on the ground between two.
const PRACTICE_TRIES := 3
const RETRY_SECONDS := 1.5

## The child's throttle, 0..1 (the cockpit's lever, Shift on a PC).
var throttle := 0.0
var steps: Array[Dictionary] = []
var stages := 1
var index := -1
## Seconds into the current step (it holds while the rocket waits for an action).
var t := 0.0
## Seconds since the flight started (waits included).
var time := 0.0
## Owner #106: the world the descent is on (its pull), whether it is the easy first try, the lander's own fuel tanks,
## whether it is a practice (the Star Map's LAND). Set before the DESCENT step starts.
var destination := SpaceRules.MOON
var descent_easy := false
var lander_tanks := 0
var practice := false
## The descent under way (made as the DESCENT step starts), else null.
var descent: FlightDescent

var _done := false          # the current step's action is done
var _asked := false         # action_needed was sent for the current step
var _waited := 0.0
var _burned := 0.0
var _auto_burn := false
var _dropped := 0
var _finished := false
var _last_staging := -1
var _crashed := false
var _tries := 0
var _retry := 0.0
var _helped := false


func _init(p_steps: Array[Dictionary], stage_count: int = 1) -> void:
	steps = p_steps
	stages = maxi(stage_count, 1)
	for i in steps.size():
		if steps[i].phase == FlightPlan.STAGING:
			_last_staging = i


func start() -> void:
	_enter(0)


func step() -> Dictionary:
	return steps[index] if index >= 0 and index < steps.size() else {}


func phase() -> StringName:
	return step().get("phase", &"")


## 0..1 through the current step.
func progress() -> float:
	var s := step()
	return clampf(t / float(s.seconds), 0.0, 1.0) if not s.is_empty() else 1.0


func is_finished() -> bool:
	return _finished


## The action the rocket waits for now (&"" when it waits for none).
func waiting_for() -> StringName:
	var s := step()
	if s.is_empty() or s.action == &"" or _done or t < float(s.at):
		return &""
	return s.action


## The current step's action is done (or it has none).
func action_done_here() -> bool:
	return _done or step().get("action", &"") == &""


## How much of the current burn is done, 0..1.
func burn_progress() -> float:
	return clampf(_burned / FlightPlan.BURN_SECONDS, 0.0, 1.0)


## The autopilot holds the throttle for a child who waited.
func autopilot_burning() -> bool:
	return _auto_burn


## How many stages have fallen away.
func dropped() -> int:
	return _dropped


## Seconds waited at the current action.
func waited() -> float:
	return _waited


## Owner #106: the descent crashed: the trip is the way home now.
func crashed() -> bool:
	return _crashed


## Owner #106: Mission Control landed a practice descent after PRACTICE_TRIES.
func helped() -> bool:
	return _helped


## Tests and the smoke tools: the throttle a child who does what is asked holds now (full for a lift-off and a burn; in
## the descent a good pilot's, FlightDescent.test_pilot). The game itself never flies the descent.
func test_throttle() -> float:
	match waiting_for():
		FlightPlan.THROTTLE, FlightPlan.BURN:
			return 1.0
		FlightPlan.DESCEND:
			return FlightDescent.test_pilot(descent) if descent != null else 0.0
	return 0.0


## The child did `action` (the ACTION button, Space; THROTTLE is the big button's lift-off: full throttle). True when it
## was what the rocket waits for (a burn is held, not pressed: true while waiting for it).
func act(action: StringName) -> bool:
	if action == FlightPlan.THROTTLE:
		throttle = 1.0
		if waiting_for() == FlightPlan.THROTTLE:
			_complete(false)
			return true
		return step().get("action", &"") == FlightPlan.THROTTLE and not _done
	if waiting_for() != action:
		return false
	if action == FlightPlan.BURN or action == FlightPlan.DESCEND:   # held on the throttle, never pressed done
		return true
	_complete(false)
	return true


## SKIP (repeat visits): straight to step i, every lower stage let go.
func jump_to(i: int) -> void:
	if i <= index or i >= steps.size() or _finished:
		return
	_dropped = stages - 1
	_enter(i)


func tick(delta: float) -> void:
	if _finished or index < 0:
		return
	time += delta
	var s := step()
	var action: StringName = s.action
	if action != &"" and not _done and t >= float(s.at):
		if not _asked:
			_asked = true
			action_needed.emit(action)
		_wait(action, delta)
		if not _done:
			return
	t += delta
	if t >= float(s.seconds):
		if action != &"" and not _done:   # never skipped: a step's action happens in it
			_complete(true)
		if index + 1 >= steps.size():
			_finished = true
			finished.emit()
			return
		_enter(index + 1)


# --- Crew flights (spec §21d.6 phase 2): a crew member's run plays the pilot's -------------------------------------

## Where this (the pilot's) run is, for the crew: {i: step, t: seconds into it, done: its action done, dropped: stages
## let go, burn: seconds of the burn held, auto: the autopilot burning, thr: the throttle}.
func snapshot() -> Dictionary:
	var s := {"i": index, "t": t, "done": _done, "dropped": _dropped, "burn": _burned, "auto": _auto_burn,
		"thr": throttle}
	if descent != null:   # owner #106: the pilot's descent, and whether it crashed (the crew crashes with it)
		s["d"] = descent.snapshot()
	if _crashed:
		s["crash"] = true
	return s


## A crew member's run follows the pilot's `host` snapshot, never its own: behind, straight to the pilot's step (its
## words; the stages fall); in the pilot's step, the time runs on (catching up when far behind) up to `upto` seconds
## into it and holds there (a fast device waits, the pilot never does); an action happens when the pilot's did, never
## by this run's autopilot. The last step's end lands it (`finished`) like the pilot's. Owner #106: the descent shows
## the pilot's (FlightDescent.follow), and the pilot's crash is everyone's (the same way home).
func follow(delta: float, host: Dictionary, upto: float) -> void:
	if _finished or index < 0:
		return
	time += delta
	if bool(host.get("crash", false)) and not _crashed:
		_crash()
		if descent != null and host.get("d") is Dictionary:
			descent.follow(host.d)
		descent_over.emit(false)
	var i := mini(int(host.get("i", index)), steps.size() - 1)
	if i > index:
		_enter(i)
		t = minf(upto, float(step().seconds))
	if i < index:
		return   # (never: the pilot's run only goes forward)
	var s := step()
	var action: StringName = s.action
	var dropped := clampi(int(host.get("dropped", _dropped)), 0, stages - 1)
	_burned = float(host.get("burn", _burned))
	_auto_burn = bool(host.get("auto", false))
	throttle = float(host.get("thr", throttle))
	if action == FlightPlan.DESCEND and descent != null and host.get("d") is Dictionary:
		descent.follow(host.d)
	if action != &"" and not _done and bool(host.get("done", false)):
		_done = true
		_dropped = maxi(_dropped, dropped)
		action_done.emit(action, false)
		if action == FlightPlan.DESCEND and not _crashed:
			descent_over.emit(true)
	_dropped = maxi(_dropped, dropped)
	var until := minf(upto, float(s.seconds))
	if action != &"" and not _done:
		until = minf(until, float(s.at))   # it waits at the action for the pilot
	if t < until - CrewFlightRules.CATCH_UP:
		t = until
	elif t < until:
		t = minf(t + delta, until)
	if action != &"" and not _done and t >= float(s.at) and not _asked:
		_asked = true
		action_needed.emit(action)
	if t >= float(s.seconds) and index + 1 >= steps.size():
		_finished = true
		finished.emit()


func _wait(action: StringName, delta: float) -> void:
	match action:
		FlightPlan.THROTTLE:
			if throttle >= 0.8:
				_complete(false)
				return
		FlightPlan.BURN:
			var held := throttle >= 0.5 or _auto_burn
			if held:
				_burned += delta
				if _burned >= FlightPlan.BURN_SECONDS:
					_complete(_auto_burn)
				return
		FlightPlan.DESCEND:
			_descend(delta)
			return   # owner #106: never the autopilot's
	_waited += delta
	if _waited >= FlightPlan.ACTION_WAIT:
		if action == FlightPlan.BURN:
			_auto_burn = true
		else:
			_complete(true)


func _complete(by_autopilot: bool) -> void:
	if _done:
		return
	_done = true
	var action: StringName = step().action
	if action == FlightPlan.THROTTLE and by_autopilot:
		throttle = 1.0
	if action == FlightPlan.STAGE:
		_dropped = stages - 1 if index == _last_staging else mini(_dropped + 1, stages - 1)
	action_done.emit(action, by_autopilot)


func _enter(i: int) -> void:
	index = i
	t = 0.0
	_done = false
	_asked = false
	_waited = 0.0
	_burned = 0.0
	_auto_burn = false
	if step().get("action", &"") == FlightPlan.DESCEND:   # owner #106: the descent starts at the top
		descent = FlightDescent.new(destination, descent_easy, lander_tanks)
		_tries = 0
		_retry = 0.0
	step_started.emit(i)


## Owner #106: the descent flies on the child's throttle; at its touchdown the step's action is done. Too fast: a
## practice tries again from the top (after RETRY_SECONDS on the ground) and after PRACTICE_TRIES Mission Control lands
## it; a mission's crash makes the rest of the trip the way home.
func _descend(delta: float) -> void:
	if descent == null:
		descent = FlightDescent.new(destination, descent_easy, lander_tanks)
	if _retry > 0.0:
		_retry -= delta
		if _retry <= 0.0:
			descent.reset()
		return
	descent.tick(delta, throttle)
	if not descent.done():
		return
	if descent.state == FlightDescent.LANDED:
		descent_over.emit(true)
		_complete(false)
		return
	if practice:
		_tries += 1
		if _tries < PRACTICE_TRIES:
			_retry = RETRY_SECONDS
			descent_over.emit(false)
			return
		descent.state = FlightDescent.LANDED   # Mission Control lands this one (a practice never sticks)
		_helped = true
		descent_over.emit(true)
		_complete(true)
		return
	_crash()
	descent_over.emit(false)
	_complete(false)


## The rest of the trip after the DESCENT step becomes the way home (FlightPlan.crash_steps).
func _crash() -> void:
	if _crashed:
		return
	_crashed = true
	var at := -1
	for k in steps.size():
		if steps[k].phase == FlightPlan.DESCENT:
			at = k
	if at < 0:
		at = index
	var kept: Array[Dictionary] = steps.slice(0, at + 1)
	kept.append_array(FlightPlan.crash_steps(destination))
	steps = kept
