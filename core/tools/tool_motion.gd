class_name ToolMotion
extends RefCounted
## Owner #116, #117 (docs/design/life-skills.md §13, "Tools: a hand's motion, recognised"): the ten real motions every
## tool is used with, one recogniser for a hand in VR and a finger on a phone. Built once, used by every Life Experience,
## the Lab and the School: a new skill is a new place, its tools and its steps, never new hand code.
##
## **One API for both.** A sample is the tool's working point in the work's own frame (ToolSample makes it): metres, x
## along the work (the line, the bed, the tape), y up out of the surface, z across; the origin is the work point (the
## nail's head, the screw, the start of the line). Keys: dt (s), at (Vector3; missing: the tool is nowhere near), flat
## (a finger, not a hand), touch (flat: the finger is down on it), reach (flat: a fingertip's size there, m), axis (VR:
## the tool's pointing axis), side (VR: its side, for a twist), tilt (VR: radians from upright, for a pour), trigger
## (0..1; flat: 1 while down), other (VR: the other hand, for a cut's claw grip).
## **The checks** (CHECKS, per motion: speed, path, angle, depth, rate, time): a tool's own numbers (the Tool Book) and a
## step's own (`checks` in its data) change any of them. feed() says {progress, done, verdict ("good", "almost" for a
## kind word and no count, "bad" for a use that never counts), said (kind words about the action, never the child, the
## same words at most every SAY_EVERY s), buzz (a soft buzz for a good use: Vr.haptic)}.
##
## LifeCheck.MOTIONS (core/life, Life L1) holds the same ten words in this order; it can point to ALL.

const STRIKE := "strike"
const STROKE := "stroke"
const TWIST := "twist"
const SQUEEZE := "squeeze"
const PRESS := "press"
const SPREAD := "spread"
const MEASURE := "measure"
const POUR := "pour"
const AIM := "aim"
const CUT := "cut"
## The single list (owner #117's table, in the design's order).
const ALL: Array[String] = [STRIKE, STROKE, TWIST, SQUEEZE, PRESS, SPREAD, MEASURE, POUR, AIM, CUT]

## Each motion in words (the design's table): its name, and how it is done in VR and on a phone.
const HOW := {
	STRIKE: {"name": "Strike", "vr": "a swing that lands on the target", "phone": "tap on the target"},
	STROKE: {"name": "Stroke", "vr": "back and forth along a line", "phone": "drag back and forth"},
	TWIST: {"name": "Twist", "vr": "the wrist turns while the tool touches", "phone": "draw a circle"},
	SQUEEZE: {"name": "Squeeze", "vr": "the trigger held, firmly or gently", "phone": "press and hold"},
	PRESS: {"name": "Press", "vr": "pushed in, deep enough, at the right rate", "phone": "press, or tap to a beat"},
	SPREAD: {"name": "Spread", "vr": "a smooth pass low over a surface", "phone": "drag over the surface"},
	MEASURE: {"name": "Measure", "vr": "from the start to the end, held still", "phone": "drag from the start to the end"},
	POUR: {"name": "Pour", "vr": "tilted over the target, stopped at the line", "phone": "hold, then let go at the line"},
	AIM: {"name": "Aim", "vr": "held still and pointed true", "phone": "point and hold"},
	CUT: {"name": "Cut", "vr": "slowly along the line, fingers tucked in", "phone": "drag along the line"},
}

## Each motion's checks. Distances in metres, speeds in m/s, angles in radians, times in seconds.
const CHECKS := {
	# a swing that lands on the target: `hits` good ones, the approach speed in min..max, within `on` of the middle,
	# within `square` of straight in
	STRIKE: {"hits": 3, "min_speed": 1.0, "max_speed": 6.0, "on": 0.04, "square": 0.6},
	# back and forth along the line: `strokes` of at least `min_len`, within `line` of it, at most `max_rate` a second
	STROKE: {"strokes": 6, "min_len": 0.08, "line": 0.025, "max_rate": 2.5, "contact": 0.02},
	# the wrist turns while the tool touches: `turns` the `dir` way (1 clockwise from the tool's side: tighten, -1:
	# loosen, open a tap), in line within `align`, on it within `reach`; flat: a circle of at least `circle`
	TWIST: {"turns": 2.0, "dir": 1, "align": 0.35, "reach": 0.03, "contact": 0.02, "circle": 0.012},
	# the trigger held in lo..hi for `seconds` (`steady`: letting go starts again)
	SQUEEZE: {"seconds": 1.5, "lo": 0.55, "hi": 1.0, "steady": true},
	# pushed in `depth` past the surface within `on`, held `seconds`, `presses` times; rate_lo..rate_hi a minute if set
	PRESS: {"depth": 0.01, "seconds": 0.0, "presses": 1, "on": 0.05, "rate_lo": 0.0, "rate_hi": 0.0},
	# a pass over the bed (`length` along x from 0, `width` across): `cover` of its `cells`, the tool within `lift`
	# of it, no faster than `max_speed`
	SPREAD: {"cover": 0.8, "length": 0.9, "width": 0.1, "cells": 12, "lift": 0.03, "max_speed": 1.6},
	# hooked on the start (within `start_tol`), held `hold` s at `length` along x (within `tol`)
	MEASURE: {"length": 1.0, "tol": 0.02, "start_tol": 0.03, "hold": 0.6},
	# tilted past start_tilt over the target (within `over`): `rate` of it a second at full_tilt; stopped at want ± tol
	POUR: {"want": 0.5, "tol": 0.08, "rate": 0.35, "start_tilt": 0.5, "full_tilt": 1.3, "over": 0.08},
	# the tool's axis within `tol` of `dir` (`either`: both ways round), held `hold` s moving under `still`; `touch`:
	# lying on the surface
	AIM: {"dir": [1, 0, 0], "tol": 0.06, "hold": 1.0, "still": 0.02, "either": false, "touch": false, "contact": 0.02},
	# along the line from 0 to `length` within `line`, no faster than `max_speed`; the other hand never within `claw`
	# of the line ahead of the blade
	CUT: {"length": 0.3, "line": 0.012, "max_speed": 0.4, "claw": 0.05, "contact": 0.02},
}

const HARDER := "A little harder: swing from the elbow."
const SOFTER := "Gently: steady taps do it."
const CENTRE := "Right on the middle of it."
const STRAIGHT := "Straight in, not at a slant."
const LONGER := "Longer strokes: use the whole blade."
const LINE := "Keep to the line."
const SLOWER := "Slow and steady: let the tool do the work."
const OTHER_WAY := "The other way round."
const HARDER_SQUEEZE := "Squeeze a little harder."
const GENTLER := "Gently: not so hard."
const KEEP := "Keep squeezing a moment longer."
const FURTHER := "Push a little further in."
const ON_MARK := "Right on the mark."
const KEEP_PRESSING := "Keep pressing a moment longer."
const FASTER := "A little faster, to the beat."
const SLOWER_BEAT := "A little slower, to the beat."
const SMOOTHER := "Slower: a smooth, even layer."
const ON_SURFACE := "Keep it on the surface."
const LOWER := "Keep the tool low and flat."
const HOOK := "Hook the end on the start first."
const FURTHER_TAPE := "A little further, to the end."
const BACK := "Back a little: just to the end."
const OVER := "Over the top of it!"
const MORE := "A little more."
const TOO_MUCH := "A little too much: tip a little back."
const NEARLY := "Nearly: a tiny bit more."
const STILL := "Hold it still."
const SLOWLY := "Slowly and carefully."
const FOLLOW := "Follow the line."
const CLAW := "Fingers back: tuck them in like a claw."
const WORDS: Array[String] = [HARDER, SOFTER, CENTRE, STRAIGHT, LONGER, LINE, SLOWER, OTHER_WAY, HARDER_SQUEEZE,
	GENTLER, KEEP, FURTHER, ON_MARK, KEEP_PRESSING, FASTER, SLOWER_BEAT, SMOOTHER, ON_SURFACE, LOWER, HOOK, FURTHER_TAPE,
	BACK, OVER, MORE, TOO_MUCH, NEARLY, STILL, SLOWLY, FOLLOW, CLAW]

const SAY_EVERY := 3.0
## A stroke turns back once the tool has come this far back from its furthest point.
const TURN_BACK := 0.01
## A strike's swing slower than this share of min_speed is the tool resting on it, not a swing.
const RESTING := 0.4
## Twist: a little buzz every quarter turn.
const QUARTER := TAU / 4.0
## A strike's speed and slant are the swing's over this long (s), not one frame's.
const SWING_WINDOW := 0.06
## Aim and measure look this far back for stillness (s).
const STILL_WINDOW := 0.25
const GOOD_BUZZ := 0.55
const SOFT_BUZZ := 0.25

var motion := ""
var checks := {}
## Good uses so far: hits, strokes, presses.
var count := 0
## What it reads: the tape's length (m), the pour's level (0..1).
var reading := 0.0
var done := false
var clock := 0.0

var _last: Variant = null   # the last sample's `at` (Vector3) or null
var _was_on := false
var _said := {}
# per motion
var _angle := 0.0
var _wrong := 0.0
var _last_angle := NAN
var _quarters := 0
var _t := 0.0
var _squeezed := false
var _pressed := false
var _press_times: Array[float] = []
var _cells: Array[bool] = []
var _hooked := false
var _still_t := 0.0
var _poured := false
var _recent: Array = []   # [[clock, at]]
var _trail: Array = []   # the swing's last moments: [[clock, at]]
var _stroke_from := NAN
var _stroke_ext := NAN
var _stroke_dir := 0
var _stroke_t := 0.0
var _stroke_dev := 0.0
var _cut_x := 0.0


## `tool_checks`: the tool's own numbers (ToolBook); `step_checks`: the step's (they win).
func _init(motion_name: String, tool_checks: Dictionary = {}, step_checks: Dictionary = {}) -> void:
	motion = motion_name
	checks = (CHECKS.get(motion, {}) as Dictionary).duplicate(true)
	checks.merge(tool_checks, true)
	checks.merge(step_checks, true)
	if motion == SPREAD:
		_cells.resize(maxi(int(checks.cells), 1))
		_cells.fill(false)


## What is wrong with a motion and its checks ("" when nothing).
static func problem(motion_name: String, step_checks: Dictionary) -> String:
	if not ALL.has(motion_name):
		return "unknown motion %s (one of %s)" % [motion_name, ALL]
	var c := (CHECKS[motion_name] as Dictionary).duplicate(true)
	for k: Variant in step_checks:
		if not c.has(k):
			return "%s has no check %s" % [motion_name, k]
	c.merge(step_checks, true)
	var needs := {STRIKE: "hits", STROKE: "strokes", TWIST: "turns", SQUEEZE: "seconds", PRESS: "presses",
		SPREAD: "cover", MEASURE: "length", POUR: "want", AIM: "hold", CUT: "length"}
	if float(c[needs[motion_name]]) <= 0.0:
		return "%s needs %s above 0" % [motion_name, needs[motion_name]]
	if motion_name == POUR and float(c.want) + float(c.tol) > 1.0:
		return "pour: the level wanted must fit"
	return ""


## How far along it is (0..1), for the HUD's bar.
func fraction() -> float:
	if done:
		return 1.0
	match motion:
		STRIKE:
			return clampf(float(count) / float(checks.hits), 0.0, 1.0)
		STROKE:
			return clampf(float(count) / float(checks.strokes), 0.0, 1.0)
		TWIST:
			return clampf(_angle / (float(checks.turns) * TAU), 0.0, 1.0)
		SQUEEZE:
			return clampf(_t / float(checks.seconds), 0.0, 1.0)
		PRESS:
			return clampf(float(count) / float(checks.presses), 0.0, 1.0)
		SPREAD:
			return clampf(float(_cells.count(true)) / float(_cells_needed()), 0.0, 1.0)
		MEASURE:
			return clampf(reading / float(checks.length), 0.0, 1.0) if _hooked else 0.0
		POUR:
			return clampf(reading / float(checks.want), 0.0, 1.0)
		AIM:
			return clampf(_t / float(checks.hold), 0.0, 1.0)
		CUT:
			return clampf(_cut_x / float(checks.length), 0.0, 1.0)
	return 0.0


## A measure's tape is hooked on its start (the host shows the reading, and in VR walks the child to the end).
func hooked() -> bool:
	return _hooked


## One frame's sample (the header's keys).
func feed(s: Dictionary) -> Dictionary:
	var e := {"progress": false, "done": false, "verdict": "", "said": "", "buzz": 0.0}
	if done or not ALL.has(motion):
		return e
	var dt := float(s.get("dt", 0.0))
	clock += dt
	var at: Variant = s.get("at")
	if at is Vector3 and not (at as Vector3).is_finite():
		at = null
	match motion:
		STRIKE:
			_strike(s, at, dt, e)
		STROKE:
			_stroke(s, at, e)
		TWIST:
			_twist(s, at, e)
		SQUEEZE:
			_squeeze(s, at, dt, e)
		PRESS:
			_press(s, at, dt, e)
		SPREAD:
			_spread(s, at, dt, e)
		MEASURE:
			_measure(s, at, dt, e)
		POUR:
			_pour(s, at, dt, e)
		AIM:
			_aim(s, at, dt, e)
		CUT:
			_cut(s, at, dt, e)
	_was_on = _on(s, at, float(checks.get("contact", checks.get("lift", 0.0))))
	_last = at
	if e.done:
		done = true
	return e


# --- The motions --------------------------------------------------------------------------------------------------

func _strike(s: Dictionary, at: Variant, dt: float, e: Dictionary) -> void:
	var on := float(checks.on)
	if bool(s.get("flat", false)):
		var down := bool(s.get("touch", false))
		if down and not _was_on and at != null:
			var d := _xz(at).length()
			on = maxf(on, float(s.get("reach", 0.0)))
			if d <= on:
				_good(e)
			elif d <= on * 2.5:
				_almost(e, CENTRE)
		e.done = count >= int(checks.hits)
		return
	if at == null:
		_trail.clear()
		return
	_trail.append([clock, at])
	while _trail.size() > 2 and clock - float(_trail[0][0]) > SWING_WINDOW:
		_trail.pop_front()
	if _last == null or dt <= 0.0:
		return
	var a: Vector3 = at
	var b: Vector3 = _last
	if not (b.y > 0.0 and a.y <= 0.0):
		return   # only a crossing into the surface is a hit
	var k := b.y / maxf(b.y - a.y, 0.0001)
	var hit := b.lerp(a, k)
	var d := _xz(hit).length()
	if d > on * 2.5:
		return   # a swing at something else
	var from: Array = _trail[0]
	var v := (a - (from[1] as Vector3)) / maxf(clock - float(from[0]), dt)   # the swing's way over its last moments
	var speed := -v.y
	if speed < float(checks.min_speed) * RESTING:
		return   # resting it there
	if speed < float(checks.min_speed):
		_almost(e, HARDER)
	elif speed > float(checks.max_speed):
		_almost(e, SOFTER)
	elif d > on:
		_almost(e, CENTRE)
	elif v.normalized().angle_to(Vector3.DOWN) > float(checks.square):
		_almost(e, STRAIGHT)
	else:
		_good(e)
	e.done = count >= int(checks.hits)


func _stroke(s: Dictionary, at: Variant, e: Dictionary) -> void:
	if not _on(s, at, float(checks.contact)):
		_stroke_from = NAN
		return
	var p: Vector3 = at
	if is_nan(_stroke_from):
		_begin_stroke(p.x, p)
		return
	_stroke_dev = maxf(_stroke_dev, absf(p.z))
	if _stroke_dir == 0:
		if absf(p.x - _stroke_from) > TURN_BACK:
			_stroke_dir = 1 if p.x > _stroke_from else -1
			_stroke_ext = p.x
		return
	if (p.x - _stroke_ext) * _stroke_dir > 0.0:
		_stroke_ext = p.x
		e.progress = true
		return
	if (_stroke_ext - p.x) * _stroke_dir < TURN_BACK:
		return
	# turned back: one stroke from _stroke_from to _stroke_ext
	var length := absf(_stroke_ext - _stroke_from)
	var seconds := clock - _stroke_t
	var line := float(checks.line)
	if bool(s.get("flat", false)):
		line = maxf(line, float(s.get("reach", 0.0)) * 0.5)
	if _stroke_dev > line * 2.0:
		_bad(e, LINE)
	elif _stroke_dev > line:
		_almost(e, LINE)
	elif length < float(checks.min_len):
		_almost(e, LONGER)
	elif seconds > 0.0 and 1.0 / seconds > float(checks.max_rate):
		_almost(e, SLOWER)
	else:
		_good(e, SOFT_BUZZ)
	var back := -_stroke_dir
	_begin_stroke(_stroke_ext, p)
	_stroke_dir = back
	_stroke_ext = p.x
	e.done = count >= int(checks.strokes)


func _begin_stroke(from_x: float, p: Vector3) -> void:
	_stroke_from = from_x
	_stroke_ext = from_x
	_stroke_dir = 0
	_stroke_t = clock
	_stroke_dev = absf(p.z)


func _twist(s: Dictionary, at: Variant, e: Dictionary) -> void:
	var flat := bool(s.get("flat", false))
	var a := NAN
	if flat:
		if at != null and bool(s.get("touch", false)) and _xz(at).length() >= float(checks.circle):
			a = atan2((at as Vector3).z, (at as Vector3).x)
	elif _on(s, at, float(checks.contact)) and _xz(at).length() <= float(checks.reach):
		var axis: Vector3 = s.get("axis", Vector3.DOWN)
		if axis.length() > 0.0 and axis.normalized().angle_to(Vector3.DOWN) > float(checks.align):
			_almost(e, STRAIGHT)
			_last_angle = NAN
			return
		var side: Vector3 = s.get("side", Vector3.RIGHT)
		if Vector2(side.x, side.z).length() > 0.1:
			a = atan2(side.z, side.x)
	if is_nan(a):
		_last_angle = NAN
		return
	if is_nan(_last_angle):
		_last_angle = a
		return
	var delta := wrapf(a - _last_angle, -PI, PI) * float(int(checks.dir))
	_last_angle = a
	if delta > 0.0:
		_angle += delta
		_wrong = 0.0
		e.progress = true
		var q := floori(_angle / QUARTER)
		if q > _quarters:
			_quarters = q
			e.buzz = SOFT_BUZZ
	elif delta < 0.0:
		_angle = maxf(_angle + delta, 0.0)   # turned back: undone
		_wrong -= delta
		if _wrong > 0.6:
			_almost(e, OTHER_WAY)
	e.done = _angle >= float(checks.turns) * TAU
	if e.done:
		e.verdict = "good"
		e.buzz = GOOD_BUZZ


func _squeeze(s: Dictionary, at: Variant, dt: float, e: Dictionary) -> void:
	var flat := bool(s.get("flat", false))
	var v := float(s.get("trigger", 0.0))
	if flat:
		v = 1.0 if bool(s.get("touch", false)) and at != null else 0.0
	var in_band := v > 0.15 and (flat or (v >= float(checks.lo) and v <= float(checks.hi) + 0.02))
	if in_band:
		_t += dt
		_squeezed = true
		e.progress = true
	elif v > float(checks.hi) + 0.02:
		_almost(e, GENTLER)
	elif v > 0.15:
		_almost(e, HARDER_SQUEEZE)
	elif _squeezed:
		_squeezed = false
		if _t < float(checks.seconds):
			_say(e, KEEP)
			if bool(checks.steady):
				_t = 0.0
	e.done = _t >= float(checks.seconds)
	if e.done:
		_good(e)


func _press(s: Dictionary, at: Variant, dt: float, e: Dictionary) -> void:
	var flat := bool(s.get("flat", false))
	var on := float(checks.on)
	var need := float(checks.depth)
	var d := INF
	var depth := 0.0
	if at != null:
		d = _xz(at).length()
		depth = -(at as Vector3).y
	if flat:
		on = maxf(on, float(s.get("reach", 0.0)))
		depth = need if bool(s.get("touch", false)) and at != null else 0.0
	if d <= on and depth >= need:
		if not _pressed:
			_pressed = true
			_t = 0.0
			_press_times.append(clock)
			if float(checks.seconds) <= 0.0:
				_count_press(e)
		_t += dt
		if float(checks.seconds) > 0.0 and _t >= float(checks.seconds) and _t - dt < float(checks.seconds):
			_count_press(e)
		e.progress = true
	elif depth < need * 0.3:
		if _pressed and float(checks.seconds) > 0.0 and _t < float(checks.seconds):
			_say(e, KEEP_PRESSING)
		_pressed = false
	elif not _pressed:
		if d <= on:
			_almost(e, FURTHER)
		elif d <= on * 2.5:
			_almost(e, ON_MARK)
	e.done = count >= int(checks.presses)


func _count_press(e: Dictionary) -> void:
	var lo := float(checks.rate_lo)
	var hi := float(checks.rate_hi)
	if lo > 0.0 and _press_times.size() >= 2:
		var gap := _press_times[-1] - _press_times[-2]
		var rate := 60.0 / maxf(gap, 0.001)
		if rate < lo:
			_almost(e, FASTER)
			return
		if hi > 0.0 and rate > hi:
			_almost(e, SLOWER_BEAT)
			return
	_good(e)


func _spread(s: Dictionary, at: Variant, dt: float, e: Dictionary) -> void:
	if at == null:
		return
	var p: Vector3 = at
	var flat := bool(s.get("flat", false))
	var length := float(checks.length)
	var half := float(checks.width) * 0.5
	var lift := float(checks.lift)
	var down: bool = bool(s.get("touch", false)) if flat else (p.y <= lift and p.y >= -0.05)
	var inside := p.x >= -0.03 and p.x <= length + 0.03 and absf(p.z) <= half + 0.03
	if not flat and not down and p.y <= lift * 2.5 and p.y > lift and inside:
		_almost(e, LOWER)
		return
	if not down:
		return
	if not inside:
		if p.x >= -0.3 and p.x <= length + 0.3 and absf(p.z) <= half + 0.4:
			_almost(e, ON_SURFACE)
		return
	if _last != null and dt > 0.0 and _was_on:
		var speed := _xz(p - (_last as Vector3)).length() / dt
		if speed > float(checks.max_speed):
			_almost(e, SMOOTHER)
			return
	var from_x: float = (_last as Vector3).x if _last != null and _was_on else p.x
	var n := _cells.size()
	var i0 := clampi(floori(minf(from_x, p.x) / length * n), 0, n - 1)
	var i1 := clampi(floori(maxf(from_x, p.x) / length * n), 0, n - 1)
	for i in range(i0, i1 + 1):
		if not _cells[i]:
			_cells[i] = true
			e.progress = true
	e.done = _cells.count(true) >= _cells_needed()
	if e.done:
		_good(e)


func _cells_needed() -> int:
	return maxi(ceili(_cells.size() * float(checks.cover) - 0.0001), 1)


func _measure(s: Dictionary, at: Variant, dt: float, e: Dictionary) -> void:
	var flat := bool(s.get("flat", false))
	var reach := float(s.get("reach", 0.0)) if flat else 0.0
	if at == null or (flat and not bool(s.get("touch", false))):
		if flat and _hooked:
			_hooked = false   # the finger came up: the tape springs back
			_still_t = 0.0
		return
	var p: Vector3 = at
	_keep_recent(p)
	if not _hooked:
		var start_tol := maxf(float(checks.start_tol), reach)
		if p.length() <= start_tol and (flat or p.y <= 0.03):
			_hooked = true
			e.progress = true
			e.buzz = SOFT_BUZZ
		elif (flat or p.y <= 0.03) and p.length() > start_tol * 3.0:
			_say(e, HOOK)
		return
	reading = maxf(p.x, 0.0)
	var tol := maxf(float(checks.tol), reach * 0.5)
	var off := reading - float(checks.length)
	if _moving():
		_still_t = 0.0
		_t = 0.0
		e.progress = true
		return
	_still_t += dt
	if absf(off) <= tol:
		_t += dt
		if _t >= float(checks.hold):
			reading = float(checks.length)
			e.done = true
			_good(e)
	elif _still_t >= 1.0:
		_almost(e, FURTHER_TAPE if off < 0.0 else BACK)


func _pour(s: Dictionary, at: Variant, dt: float, e: Dictionary) -> void:
	var flat := bool(s.get("flat", false))
	var flow := 0.0
	var over := false
	if flat:
		if bool(s.get("touch", false)) and at != null:
			flow = float(checks.rate) * 0.6
			over = true
	else:
		var tilt := float(s.get("tilt", 0.0))
		var span := maxf(float(checks.full_tilt) - float(checks.start_tilt), 0.01)
		flow = float(checks.rate) * clampf((tilt - float(checks.start_tilt)) / span, 0.0, 1.0)
		over = at != null and _xz(at).length() <= float(checks.over) and (at as Vector3).y >= -0.02
	if flow > 0.0:
		if over:
			reading = minf(reading + flow * dt, 1.0)
			_poured = true
			e.progress = true
		else:
			_say(e, OVER)
		return
	if not _poured:
		return
	_poured = false
	var want := float(checks.want)
	var tol := float(checks.tol)
	if absf(reading - want) <= tol:
		e.done = true
		_good(e)
	elif reading < want:
		_almost(e, MORE)
	else:
		_almost(e, TOO_MUCH)
		reading = maxf(want - tol * 2.0, 0.0)   # a little goes back: never a miss
		e.progress = true


func _aim(s: Dictionary, at: Variant, dt: float, e: Dictionary) -> void:
	var flat := bool(s.get("flat", false))
	if flat:
		if bool(s.get("touch", false)) and at != null:
			_t += dt
			e.progress = true
		else:
			_t = 0.0
		e.done = _t >= float(checks.hold)
		if e.done:
			_good(e)
		return
	if at == null:
		_t = 0.0
		return
	var p: Vector3 = at
	_keep_recent(p)
	if bool(checks.touch) and p.y > float(checks.contact):
		_t = 0.0
		return
	var want := _vec(checks.dir)
	var axis: Vector3 = s.get("axis", Vector3.ZERO)
	var err := PI
	if axis.length() > 0.0 and want.length() > 0.0:
		err = axis.normalized().angle_to(want.normalized())
		if bool(checks.either):
			err = minf(err, PI - err)
	var tol := float(checks.tol)
	if err > tol:
		_t = 0.0
		if err <= tol * 3.0:
			_almost(e, NEARLY)
		return
	if _moving():
		_t = 0.0
		_almost(e, STILL)
		return
	_t += dt
	e.progress = true
	e.done = _t >= float(checks.hold)
	if e.done:
		_good(e)


func _cut(s: Dictionary, at: Variant, dt: float, e: Dictionary) -> void:
	if not _on(s, at, float(checks.contact)):
		return
	var p: Vector3 = at
	var flat := bool(s.get("flat", false))
	var line := float(checks.line)
	if flat:
		line = maxf(line, float(s.get("reach", 0.0)) * 0.5)
	var other: Variant = s.get("other")
	if other is Vector3 and (other as Vector3).is_finite():
		var o: Vector3 = other
		if o.x > _cut_x and o.x <= float(checks.length) + 0.05 and absf(o.z) < float(checks.claw) and o.y < 0.1:
			_bad(e, CLAW)
			return
	if p.x < -0.03 or p.x > float(checks.length) + 0.05:
		return
	if absf(p.z) > line:
		if absf(p.z) <= line * 6.0:
			_almost(e, FOLLOW)
		return
	if p.x <= _cut_x:
		return
	if p.x - _cut_x > 0.08:
		_almost(e, FOLLOW)   # a jump ahead: from where the cut is, along the line
		return
	if _last != null and dt > 0.0 and _was_on and (p.x - (_last as Vector3).x) / dt > float(checks.max_speed):
		_almost(e, SLOWLY)
		return
	_cut_x = p.x
	e.progress = true
	e.done = _cut_x >= float(checks.length) - 0.01
	if e.done:
		_good(e)

# --- Helpers ------------------------------------------------------------------------------------------------------

## The tool is on the surface: a finger down (flat), or the working point within `contact` of it (VR).
func _on(s: Dictionary, at: Variant, contact: float) -> bool:
	if at == null:
		return false
	if bool(s.get("flat", false)):
		return bool(s.get("touch", false))
	return (at as Vector3).y <= contact


func _good(e: Dictionary, buzz: float = GOOD_BUZZ) -> void:
	if motion in [STRIKE, STROKE, PRESS]:
		count += 1
	e.verdict = "good"
	e.progress = true
	e.buzz = buzz


func _almost(e: Dictionary, words: String) -> void:
	e.verdict = "almost"
	_say(e, words)


func _bad(e: Dictionary, words: String) -> void:
	e.verdict = "bad"
	_say(e, words)


func _say(e: Dictionary, words: String) -> void:
	if clock - float(_said.get(words, -INF)) >= SAY_EVERY:
		_said[words] = clock
		e.said = words


func _keep_recent(p: Vector3) -> void:
	_recent.append([clock, p])
	while _recent.size() > 2 and clock - float(_recent[0][0]) > STILL_WINDOW:
		_recent.pop_front()


## The tool moved more than `still` within the last STILL_WINDOW s.
func _moving() -> bool:
	if _recent.is_empty():
		return false
	var now: Vector3 = _recent[-1][1]
	var limit := float(checks.get("still", 0.02))
	for r: Array in _recent:
		if (r[1] as Vector3).distance_to(now) > limit:
			return true
	return false


static func _xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


## A direction from data: a Vector3 or [x, y, z].
static func _vec(v: Variant) -> Vector3:
	if v is Vector3:
		return v
	if v is Array and (v as Array).size() == 3:
		return Vector3(float(v[0]), float(v[1]), float(v[2]))
	return Vector3.ZERO
