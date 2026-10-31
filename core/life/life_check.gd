class_name LifeCheck
extends RefCounted
## Owner #112, #113 (docs/design/life-skills.md §3, §10): how each kind of Experience step is checked, from one sample a
## frame that the room host makes of fingers (flat) or hands and the head (VR). A step reads "the hand is here and
## squeezing" (`held`), "it was pressed" (`pressed`), "the laser is on it" (`aimed`), never a particular button, so VR
## round 4's shared grab can feed the same samples later without a rule changing.
##
## A sample's keys (all optional): dt (s), time (the run's clock, s), pressed / held / aimed (target names this frame),
## pushes (pushes on the step's target this frame), low (the head is low or GET LOW is on), action (the body action seen
## now: low, still, cover, roll, look) and action_tap (its big button was pressed: done at once), answer (a choice's
## index, -1 none), ok (A, OK or a tap on the words), sweep_u (the laser across the target while squeezing, -1..1).
##
## A step's data: kind (KINDS), say (what the coach says), done (kind words after), and per kind:
## - info: OK goes on.                    - touch / go: target, pressed.
## - hold / hands: target, seconds (2 / 1) held (hands: the host wants both hands in VR).
## - taps: target, count.                 - sequence: targets in order (a wrong one is a miss).
## - find: targets in any order, need (all), lines {target: words said when found}.
## - choose / count: choices [{text, icon}], answer (index), miss (words for a wrong choice).
## - action: action, seconds (0.6).       - point: target, seconds (1) aimed (a flat tap aims at once).
## - rhythm: target, pushes (30), good (20): pushes counted at the beat (LifeBeat: 100-120 a minute).
## - coins: target (where the coins go), sum, coins [values]; "coin_<value>" adds one, "coins_back" takes one back.
## - basket: items [{target, price, need}], budget; "till" pays: every need in and the total within the budget.
## - sweep: target, sweeps (3) side to side.  - timelapse: seconds (6), label: plays by itself.
## Life L2 (owner #112: Safe Streets, The Kitchen, Calm Corner):
## - look: sides ["left", "right", "left"] (the region's, {look_sides}) looked at in order: `looked` (a LOOK swipe or
##   button: "left" / "right") or `look_yaw` (VR: the head's turn from the spot's facing, radians, left is +); the wrong
##   way first is kind words, never a miss.
## - cross: target (the other side): pressed while `safe` (the room's traffic) is done; pressed while not safe is a kind
##   miss (`miss` words; the host plays its `on_miss` event: the car stops gently); waiting while it is not safe counts as
##   progress (the coach never nags a child who waits). It glows only while safe, never with "glow": false (the Expert
##   try judges the gap alone).
## - rub: target, seconds (20): only the time spent rubbing counts (`rubbing`: the finger moving, both hands moving).
## - pour: target, want, full, tol, rate (a second, while held: the jug tilted in VR): let go inside want ± tol; under
##   it, "a little more"; over it, a little goes back (never a miss). Also the scales (spooning on: "measure").
## - breathe: target, breaths, in (s), out (s): held is breathing in (VR: the hands rise), let go is out.
## - feel: choices [{text, icon, reply}]: any picture is right (nothing marked; nothing is kept: the log keeps no answer).
## - steady: target, lo, hi, top, up / down (a second), seconds: held raises the needle, let go lowers it; the seconds
##   inside lo..hi count.
## Any step may say "low": true: it waits while the child stands (STAY_LOW, kindly).
## Owner #117 (docs/design/life-skills.md §13): a step that uses a real motion names it, `motion`: one of MOTIONS (the
## shared tool recogniser's ten, built later: the rules here never read it, so it can take over without a rule
## changing); `tool`: the thing in the hand (cloth, tap, coins); `device`: a device of the Experience (LifeExperience
## .devices: its controls, what it shows, the right order, its safety steps).
## Life L3a (owner #118, design §14: "dangerous things, learned safely"):
## - `safe_mistake` {wrong (the wrong way in words), try, event (the room's gentle picture of what would happen), icon (the
##   why card's picture), why (the coach's calm why), right (the right way, said as the step goes on)}: the child may do
##   the wrong thing: `try` names a target (pressing it is the mistake) or "action:<name>" (a body action: "stand" is the
##   head coming up after being low, or the STAND UP button; or one of ACTIONS); on a choose step the picture marked
##   `"mistake": true` is it. feed() says `mistake` (never a miss: the host freezes the room and the coach explains, then
##   the step goes on). Only on the Middle and Big tracks (on Little the coach guides before any mistake).
## - `not` {target: words}: a wrong but harmless tap on a touch or go step (a playing buddy when the quiet one needs help):
##   a kind miss with its words.
## - `within` (s of the room's time, `room_dt`: slowed on the first tries) and `late` (words): a danger moment's action
##   wanted in time; too late is a kind miss and its clock starts again.
## Life L3b (owner #118): a safe mistake's `try` may be "unsafe": the right target at the wrong moment (a crossing pressed
## while a car comes, a tool used before its safety gear is on): pressed while the sample's `safe` is false it is the
## mistake; pressed while safe, the step goes on as ever. Only where a moment can be wrong (a cross step; a step with
## `safety`). The body action "tree" (a dog runs at you: be a tree: still, arms folded in, looking at your feet).
## feed() returns {progress, done, miss, mistake, said}: `said` is a line to say now ("" for none).

const KINDS: Array[String] = ["info", "touch", "hold", "hands", "taps", "sequence", "find", "choose", "count", "action",
	"go", "point", "rhythm", "coins", "basket", "sweep", "timelapse", "look", "cross", "rub", "pour", "breathe", "feel",
	"steady"]
const ACTIONS: Array[String] = ["low", "still", "cover", "roll", "look", "tree"]   # Life L3b: "tree" (be a tree)
## Life L3a: a body action that can only be a safe mistake's `try` ("action:stand": standing up on the ice).
const WRONG_ACTIONS: Array[String] = ["stand"]
const SAFE_MISTAKE_KEYS: Array[String] = ["wrong", "event", "why", "right"]
## Life L3b: a safe mistake's try that is the step's own target at the wrong moment (the sample says it is not safe).
const UNSAFE := "unsafe"
const LATE := "Quickly now: do it straight away."
const MOTIONS: Array[String] = ToolMotion.ALL   # owner #117: the one list (core/tools/tool_motion.gd)
const STAY_LOW := "Stay low, under the smoke."
const FASTER := "A little faster, to the beat."
const SLOWER := "A little slower, to the beat."
const TOO_MUCH := "That's too much. That coin comes back."
const LIST_MISSING := "Something on your list is missing."
const OVER_BUDGET := "That's more than you have. Put a want back."
const LOOK_FIRST := "First look %s: the nearest cars come from there."
const LOOK_NEXT := "Now look %s."
const WAIT_WORDS := "Wait! A car is coming. Stay on the pavement until there is a big gap."
const POUR_MORE := "A little more."
const POUR_TOO_MUCH := "A little too much: tip a little back."
const BREATHE_SLOWLY := "Slowly, like filling a balloon. In... and out."
const TOO_FAST := "Ease off: the needle is over the limit."
const SIDES: Array[String] = ["left", "right"]
## A head turned this far from the spot's facing (VR) is a look that way; back under half of it is the middle again.
const LOOK_YAW := 0.61   # 35 degrees
## A sentence the coach says at most every this many seconds (the low reminder, the beat).
const SAY_EVERY := 3.0
const MAX_SAY := 220
const NEEDS_TARGET: Array[String] = ["touch", "hold", "hands", "taps", "go", "point", "rhythm", "coins", "sweep", "cross",
	"rub", "pour", "breathe", "steady"]


## What is wrong with a step's data ("" when nothing).
static func problem(step: Dictionary) -> String:
	var kind := str(step.get("kind", ""))
	if not KINDS.has(kind):
		return "unknown kind %s" % kind
	if str(step.get("say", "")).strip_edges() == "":
		return "%s says nothing" % kind
	if str(step.get("say", "")).length() > MAX_SAY or str(step.get("done", "")).length() > MAX_SAY:
		return "%s: its words are longer than %d letters" % [kind, MAX_SAY]
	if NEEDS_TARGET.has(kind) and str(step.get("target", "")) == "":
		return "%s needs its target" % kind
	if step.has("motion") and not MOTIONS.has(str(step.motion)):
		return "unknown motion %s (one of %s)" % [step.motion, MOTIONS]
	for key: String in ["tool", "device"]:
		if step.has(key) and (not step[key] is String or str(step[key]) == ""):
			return "%s must name a %s" % [kind, key]
	var why_mistake := _mistake_problem(step, kind)
	if why_mistake != "":
		return why_mistake
	if step.has("not"):
		if not step.not is Dictionary or (step.not as Dictionary).is_empty() or not kind in ["touch", "go"]:
			return "%s: not is {target: words}, on a touch or go step" % kind
		if (step.not as Dictionary).has(str(step.get("target", ""))):
			return "%s: the right target is never one of its not taps" % kind
		for t: Variant in step.not:
			if str(step.not[t]).strip_edges() == "" or str(step.not[t]).length() > MAX_SAY:
				return "%s: not %s needs its kind words" % [kind, t]
	if step.has("within") and float(step.within) <= 0.0:
		return "%s: within is seconds of the room's time" % kind
	match kind:
		"sequence", "find":
			var t: Variant = step.get("targets")
			if not t is Array or (t as Array).is_empty():
				return "%s needs its targets" % kind
			if kind == "find" and int(step.get("need", (t as Array).size())) > (t as Array).size():
				return "find needs more than it has"
		"choose", "count", "feel":
			var c: Variant = step.get("choices")
			if not c is Array or (c as Array).size() < 2:
				return "%s needs two choices or more" % kind
			if kind == "feel":
				for ch: Variant in c:
					if not ch is Dictionary or str((ch as Dictionary).get("text", "")).strip_edges() == "":
						return "feel: a choice without words"
				return ""
			var a: Variant = step.get("answer")
			if typeof(a) not in [TYPE_INT, TYPE_FLOAT] or int(a) < 0 or int(a) >= (c as Array).size():
				return "%s's answer is not one of its choices" % kind
			for ch: Variant in c:
				if not ch is Dictionary or str((ch as Dictionary).get("text", "")).strip_edges() == "":
					return "%s: a choice without words" % kind
		"action":
			if not ACTIONS.has(str(step.get("action", ""))):
				return "unknown action %s" % step.get("action", "")
		"taps":
			if int(step.get("count", 0)) < 1:
				return "taps needs a count"
		"look":
			var sides: Variant = step.get("sides")
			if not sides is Array or (sides as Array).is_empty():
				return "look needs its sides"
			for side: Variant in sides:
				if not SIDES.has(str(side)):
					return "look: %s is not left or right" % side
		"rub":
			if float(step.get("seconds", 20.0)) <= 0.0:
				return "rub needs its seconds"
		"pour":
			var want := float(step.get("want", 0.0))
			if want <= 0.0 or want > float(step.get("full", 1.0)) or float(step.get("tol", 0.07)) <= 0.0:
				return "pour: the level wanted must fit the jug, with a band round it"
		"breathe":
			if int(step.get("breaths", 3)) < 1:
				return "breathe needs its breaths"
		"steady":
			var lo := float(step.get("lo", 0.0))
			var hi := float(step.get("hi", 0.0))
			if lo < 0.0 or lo >= hi or hi > float(step.get("top", 0.0)) or float(step.get("seconds", 0.0)) <= 0.0:
				return "steady needs lo < hi <= top and its seconds"
		"rhythm":
			if int(step.get("good", 20)) > int(step.get("pushes", 30)) or int(step.get("pushes", 30)) < 1:
				return "rhythm: more good pushes than pushes"
		"coins":
			var coins: Variant = step.get("coins")
			if not coins is Array or (coins as Array).is_empty() or int(step.get("sum", 0)) < 1:
				return "coins needs coins and a sum"
		"basket":
			var items: Variant = step.get("items")
			if not items is Array or (items as Array).size() < 2 or int(step.get("budget", 0)) < 1:
				return "basket needs items and a budget"
			var needs := 0
			for it: Variant in items:
				if not it is Dictionary or str((it as Dictionary).get("target", "")) == "":
					return "basket: an item without its target"
				if bool((it as Dictionary).get("need", false)):
					needs += int((it as Dictionary).get("price", 0))
			if needs > int(step.budget):
				return "basket: the needs cost more than the budget"
	return ""


## Life L3a: what is wrong with a step's safe mistake ("" when nothing, or when it has none).
static func _mistake_problem(step: Dictionary, kind: String) -> String:
	if not step.has("safe_mistake"):
		return ""
	var m: Variant = step.safe_mistake
	if not m is Dictionary:
		return "%s: a safe mistake is {wrong, try, event, icon, why, right}" % kind
	for key in SAFE_MISTAKE_KEYS:
		var w := str((m as Dictionary).get(key, "")).strip_edges()
		if w == "" or w.length() > MAX_SAY:
			return "%s: its safe mistake needs its %s" % [kind, key]
	if kind in ["choose", "count"]:
		var choices: Array = step.get("choices", [])
		for i in choices.size():
			if choices[i] is Dictionary and bool((choices[i] as Dictionary).get("mistake", false)) \
					and i == int(step.get("answer", -1)):
				return "%s: its mistake picture (\"mistake\": true) is never the right one" % kind
		return ""
	var try := str((m as Dictionary).get("try", ""))
	if try == "":
		return ""   # shaped only (Real Builder's: the room's event and the why, no wrong way to try): tries_mistake
	if try == UNSAFE:   # Life L3b: the right target at the wrong moment
		if kind != "cross" and str(step.get("safety", "")) == "":
			return "%s: an unsafe moment needs a moment that can be wrong (a crossing, or a tool's safety gear)" % kind
		return ""
	if try.begins_with("action:"):
		var a := try.trim_prefix("action:")
		if not ACTIONS.has(a) and not WRONG_ACTIONS.has(a):
			return "%s: its safe mistake's action %s is not one the body does" % [kind, a]
	elif try == str(step.get("target", "")) or (step.get("targets", []) as Array).has(try):
		return "%s: the wrong way is never the right one (%s)" % [kind, try]
	return ""


## Life L3a: whether a step's safe mistake can be tried (a `try`, or a choice marked as the mistake). One without either
## is only shaped (round 4b's Real Builder: its why and its event, played by the tool engine).
static func tries_mistake(step: Dictionary) -> bool:
	var m: Variant = step.get("safe_mistake")
	if not m is Dictionary:
		return false
	if str((m as Dictionary).get("try", "")) != "":
		return true
	for c: Variant in step.get("choices", []):
		if c is Dictionary and bool((c as Dictionary).get("mistake", false)):
			return true
	return false


## Every target the step uses (for the room: each must be there).
static func targets_of(step: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if step.has("target"):
		out.append(str(step.target))
	for t: Variant in step.get("targets", []):
		out.append(str(t))
	var m: Variant = step.get("safe_mistake")
	if m is Dictionary and str((m as Dictionary).get("try", "")) not in ["", UNSAFE] and not str(m.try).begins_with("action:"):
		out.append(str(m.try))   # Life L3a: the wrong way is a thing in the room too (L3b: never the unsafe moment)
	if step.get("not") is Dictionary:
		for t: Variant in step.not:
			out.append(str(t))
	match str(step.get("kind", "")):
		"look":
			out.append_array(["look_left", "look_right"])
		"coins":
			for v: Variant in step.get("coins", []):
				out.append("coin_%d" % int(v))
			out.append("coins_back")
		"basket":
			for it: Dictionary in step.get("items", []):
				out.append(str(it.target))
			out.append("till")
	return out


static func begin(step: Dictionary) -> Dictionary:
	match str(step.get("kind", "")):
		"sequence":
			return {"i": 0}
		"find":
			return {"found": []}
		"rhythm":
			return {"times": [], "count": 0, "good": 0, "said_at": -INF}
		"coins":
			return {"sum": 0, "given": []}
		"basket":
			return {"in": []}
		"sweep":
			return {"side": 0, "crossings": 0}
		"look":
			return {"i": 0, "last": ""}
		"cross":
			return {"safe": false}
		"pour":
			return {"level": 0.0, "pouring": false}
		"breathe":
			return {"phase": "rest", "t": 0.0, "count": 0}
		"steady":
			return {"value": 0.0, "t": 0.0, "said_at": -INF}
	return {"t": 0.0}


static func feed(step: Dictionary, state: Dictionary, sample: Dictionary) -> Dictionary:
	var out := {"progress": false, "done": false, "miss": false, "mistake": false, "said": ""}
	var dt := float(sample.get("dt", 0.0))
	state["clock"] = float(state.get("clock", 0.0)) + dt
	state["room_t"] = float(state.get("room_t", 0.0)) + float(sample.get("room_dt", dt))   # Life L3a: the room's time
	if bool(sample.get("low", false)):
		state["was_low"] = true
	if _tried_mistake(step, state, sample):   # Life L3a (owner #118): the wrong way tried, safely
		out.mistake = true
		state["mistakes"] = int(state.get("mistakes", 0)) + 1
		state["was_low"] = false
		state["room_t"] = 0.0
		return out
	if bool(step.get("low", false)) and not bool(sample.get("low", false)):
		if _wants_any(step, sample) and float(state.clock) - float(state.get("low_said", -INF)) >= SAY_EVERY:
			out.said = STAY_LOW
			state["low_said"] = state.clock
		_late(step, state, out)
		return out
	var pressed: Array = sample.get("pressed", [])
	var held: Array = sample.get("held", [])
	var target := str(step.get("target", ""))
	match str(step.get("kind", "")):
		"info":
			out.done = bool(sample.get("ok", false))
		"touch", "go":
			out.done = pressed.has(target)
			if not out.done and step.get("not") is Dictionary:   # Life L3a: a harmless wrong tap, kindly
				for p: Variant in pressed:
					if (step.not as Dictionary).has(str(p)):
						out.miss = true
						out.said = str(step.not[str(p)])
						break
		"hold", "hands":
			if held.has(target):
				state.t = float(state.t) + dt
				out.progress = true
			out.done = float(state.t) >= float(step.get("seconds", 1.0 if step.kind == "hands" else 2.0))
		"taps":
			if pressed.has(target):
				state.t = int(state.t) + 1
				out.progress = true
			out.done = int(state.t) >= int(step.get("count", 1))
		"sequence":
			var list: Array = step.targets
			for p: Variant in pressed:
				var i := int(state.i)
				if i >= list.size():
					break
				if str(p) == str(list[i]):
					state.i = i + 1
					out.progress = true
				elif list.has(p) or str(p).begins_with("key_"):
					out.miss = true
			out.done = int(state.i) >= list.size()
		"find":
			var found: Array = state.found
			for p: Variant in pressed:
				if (step.targets as Array).has(p) and not found.has(p):
					found.append(p)
					out.progress = true
					out.said = str((step.get("lines", {}) as Dictionary).get(p, ""))
			out.done = found.size() >= int(step.get("need", (step.targets as Array).size()))
		"choose", "count":
			var a := int(sample.get("answer", -1))
			if a >= 0:
				if a == int(step.answer):
					out.done = true
				else:
					out.miss = true
					var why := str(((step.choices as Array)[a] as Dictionary).get("why", "")) \
						if a < (step.choices as Array).size() else ""
					out.said = why if why != "" else str(step.get("miss", ""))
		"action":
			var name := str(step.action)
			var doing := str(sample.get("action", "")) == name or (name == "low" and bool(sample.get("low", false)))
			if doing and bool(sample.get("action_tap", false)):
				out.done = true
			elif doing:
				state.t = float(state.t) + dt
				out.progress = true
				out.done = float(state.t) >= float(step.get("seconds", 0.6))
		"point":
			if pressed.has(target):
				out.done = true
			elif (sample.get("aimed", []) as Array).has(target):
				state.t = float(state.t) + dt
				out.progress = true
				out.done = float(state.t) >= float(step.get("seconds", 1.0))
		"rhythm":
			_rhythm(step, state, sample, out)
		"coins":
			_coins(step, state, pressed, out)
		"basket":
			_basket(step, state, pressed, out)
		"sweep":
			if sample.has("sweep_u") and not is_nan(float(sample.sweep_u)):
				var u := float(sample.sweep_u)
				var side := 1 if u > 0.3 else (-1 if u < -0.3 else 0)
				if side != 0 and side != int(state.side):
					if int(state.side) != 0:
						state.crossings = int(state.crossings) + 1
					state.side = side
					out.progress = true
			out.done = int(state.crossings) >= int(step.get("sweeps", 3))
		"timelapse":
			state.t = float(state.t) + dt
			out.done = float(state.t) >= float(step.get("seconds", 6.0))
		"look":
			_look(step, state, sample, out)
		"cross":
			var safe := bool(sample.get("safe", false))
			state.safe = safe
			if pressed.has(target):
				if safe:
					out.done = true
				else:
					out.miss = true
					out.said = str(step.get("miss", WAIT_WORDS))
			elif not safe:
				out.progress = true   # waiting at the kerb while a car comes: the right thing
		"rub":
			if (sample.get("rubbing", []) as Array).has(target):
				state.t = float(state.t) + dt
				out.progress = true
			out.done = float(state.t) >= float(step.get("seconds", 20.0))
		"pour":
			_pour(step, state, held.has(target), dt, out)
		"breathe":
			_breathe(step, state, held.has(target), dt, out)
		"feel":
			var a := int(sample.get("answer", -1))
			var choices: Array = step.get("choices", [])
			if a >= 0 and a < choices.size():
				out.done = true
				out.said = str((choices[a] as Dictionary).get("reply", "")) if choices[a] is Dictionary else ""
		"steady":
			_steady(step, state, held.has(target), dt, out)
	_late(step, state, out)
	return out


## Life L3a (owner #118): whether this frame tried the step's safe mistake (its target pressed, its body action done,
## its picture picked). "stand" is the head coming up after being low in this step (VR), or the STAND UP button (flat).
static func _tried_mistake(step: Dictionary, state: Dictionary, sample: Dictionary) -> bool:
	var m: Variant = step.get("safe_mistake")
	if not m is Dictionary:
		return false
	if str(step.get("kind", "")) in ["choose", "count"]:
		var a := int(sample.get("answer", -1))
		var choices: Array = step.get("choices", [])
		return a >= 0 and a < choices.size() and choices[a] is Dictionary \
			and bool((choices[a] as Dictionary).get("mistake", false))
	var try := str((m as Dictionary).get("try", ""))
	if try == UNSAFE:   # Life L3b: the step's own target pressed while it is not safe (the sample says so)
		return (sample.get("pressed", []) as Array).has(str(step.get("target", ""))) and sample.has("safe") \
			and not bool(sample.safe)
	if try.begins_with("action:"):
		var action := try.trim_prefix("action:")
		if str(sample.get("action", "")) == action:
			return true
		return action == "stand" and bool(step.get("low", false)) and sample.has("low") and not bool(sample.low) \
			and bool(state.get("was_low", false))
	return try != "" and (sample.get("pressed", []) as Array).has(try)


## Life L3a: a danger moment's action not done within its seconds of the room's time: a kind miss, its clock again.
static func _late(step: Dictionary, state: Dictionary, out: Dictionary) -> void:
	var within := float(step.get("within", 0.0))
	if within <= 0.0 or bool(out.done) or float(state.get("room_t", 0.0)) < within:
		return
	out.miss = true
	if str(out.said) == "":
		out.said = str(step.get("late", LATE))
	state.room_t = 0.0


## How far along the step is (0..1), for the HUD's little bar.
static func fraction(step: Dictionary, state: Dictionary) -> float:
	match str(step.get("kind", "")):
		"hold", "hands":
			return clampf(float(state.get("t", 0.0)) / float(step.get("seconds", 2.0)), 0.0, 1.0)
		"taps":
			return clampf(float(state.get("t", 0)) / float(step.get("count", 1)), 0.0, 1.0)
		"sequence":
			return float(state.get("i", 0)) / maxf((step.targets as Array).size(), 1.0)
		"find":
			return float((state.get("found", []) as Array).size()) / float(step.get("need", (step.targets as Array).size()))
		"rhythm":
			return clampf(float(state.get("count", 0)) / float(step.get("pushes", 30)), 0.0, 1.0)
		"coins":
			return clampf(float(state.get("sum", 0)) / float(step.get("sum", 1)), 0.0, 1.0)
		"sweep":
			return clampf(float(state.get("crossings", 0)) / float(step.get("sweeps", 3)), 0.0, 1.0)
		"timelapse":
			return clampf(float(state.get("t", 0.0)) / float(step.get("seconds", 6.0)), 0.0, 1.0)
		"look":
			return float(state.get("i", 0)) / maxf((step.get("sides", []) as Array).size(), 1.0)
		"rub":
			return clampf(float(state.get("t", 0.0)) / float(step.get("seconds", 20.0)), 0.0, 1.0)
		"pour":
			return clampf(float(state.get("level", 0.0)) / maxf(float(step.get("want", 1.0)), 0.001), 0.0, 1.0)
		"breathe":
			var part := 0.0
			if str(state.get("phase", "")) == "in":
				part = 0.5 * clampf(float(state.t) / float(step.get("in", 3.0)), 0.0, 1.0)
			elif str(state.get("phase", "")) == "out":
				part = 0.5 + 0.5 * clampf(float(state.t) / float(step.get("out", 3.0)), 0.0, 1.0)
			return clampf((float(state.get("count", 0)) + part) / float(step.get("breaths", 3)), 0.0, 1.0)
		"steady":
			return clampf(float(state.get("t", 0.0)) / float(step.get("seconds", 1.0)), 0.0, 1.0)
	return 0.0


## The one next thing (it glows; the coach shows it): what to press, hold or aim at now ([] for words and choices).
static func next_targets(step: Dictionary, state: Dictionary) -> Array[String]:
	var out: Array[String] = []
	match str(step.get("kind", "")):
		"touch", "go", "hold", "hands", "taps", "point", "rhythm", "sweep", "rub", "pour", "breathe", "steady":
			out.append(str(step.target))
		"look":
			var i := int(state.get("i", 0))
			var sides: Array = step.get("sides", [])
			if i < sides.size():
				out.append("look_" + str(sides[i]))
		"cross":
			if bool(state.get("safe", false)) and bool(step.get("glow", true)):
				out.append(str(step.target))
		"sequence":
			var i := int(state.get("i", 0))
			if i < (step.targets as Array).size():
				out.append(str(step.targets[i]))
		"find":
			for t: Variant in step.targets:
				if not (state.get("found", []) as Array).has(t):
					out.append(str(t))
					break
		"coins":
			var left := int(step.sum) - int(state.get("sum", 0))
			var values: Array = (step.coins as Array).duplicate()
			values.sort()
			values.reverse()
			for v: Variant in values:
				if int(v) <= left:
					out.append("coin_%d" % int(v))
					break
		"basket":
			for it: Dictionary in step.items:
				if bool(it.get("need", false)) and not (state.get("in", []) as Array).has(it.target):
					out.append(str(it.target))
					return out
			out.append("till")
	return out


## The basket's total so far.
static func basket_total(step: Dictionary, state: Dictionary) -> int:
	var total := 0
	for it: Dictionary in step.get("items", []):
		if (state.get("in", []) as Array).has(it.target):
			total += int(it.get("price", 0))
	return total


static func _wants_any(step: Dictionary, sample: Dictionary) -> bool:
	return not (sample.get("pressed", []) as Array).is_empty() or not (sample.get("held", []) as Array).is_empty() \
		or str(step.get("kind", "")) == "go" and not (sample.get("aimed", []) as Array).is_empty()


static func _rhythm(step: Dictionary, state: Dictionary, sample: Dictionary, out: Dictionary) -> void:
	var n := int(sample.get("pushes", 0))
	for i in n:
		(state.times as Array).append(float(sample.get("time", state.clock)))
		state.count = int(state.count) + 1
		out.progress = true
		var r := LifeBeat.rate(state.times)
		if LifeBeat.good(r):
			state.good = int(state.good) + 1
		elif r > 0.0 and float(state.clock) - float(state.said_at) >= SAY_EVERY:
			out.said = FASTER if r < LifeBeat.MIN_RATE else SLOWER
			state.said_at = state.clock
	out.done = int(state.count) >= int(step.get("pushes", 30)) and int(state.good) >= int(step.get("good", 20))


static func _coins(step: Dictionary, state: Dictionary, pressed: Array, out: Dictionary) -> void:
	for p: Variant in pressed:
		var name := str(p)
		if name == "coins_back" and not (state.given as Array).is_empty():
			state.sum = int(state.sum) - int((state.given as Array).pop_back())
			out.progress = true
		elif name.begins_with("coin_") and _values(step.coins).has(int(name.substr(5))):
			var v := int(name.substr(5))
			if int(state.sum) + v > int(step.sum):
				out.said = TOO_MUCH
			else:
				state.sum = int(state.sum) + v
				(state.given as Array).append(v)
				out.progress = true
	out.done = int(state.sum) == int(step.sum)


## A list of numbers as whole numbers (JSON gives 1.0 for 1).
static func _values(list: Variant) -> Array[int]:
	var out: Array[int] = []
	if list is Array:
		for v: Variant in list:
			out.append(int(v))
	return out


static func _basket(step: Dictionary, state: Dictionary, pressed: Array, out: Dictionary) -> void:
	var inside: Array = state.in
	for p: Variant in pressed:
		if str(p) == "till":
			for it: Dictionary in step.items:
				if bool(it.get("need", false)) and not inside.has(it.target):
					out.miss = true
					out.said = LIST_MISSING
					return
			if basket_total(step, state) > int(step.budget):
				out.miss = true
				out.said = OVER_BUDGET
				return
			out.done = true
			return
		for it: Dictionary in step.items:
			if str(it.target) == str(p):
				if inside.has(p):
					inside.erase(p)
				else:
					inside.append(p)
				out.progress = true


## Owner #112, Safe Streets: a look each way, in the region's order (a flat look is one event; a VR look is the head
## turned past LOOK_YAW, once until it comes back towards the middle or turns the other way).
static func _look(step: Dictionary, state: Dictionary, sample: Dictionary, out: Dictionary) -> void:
	var sides: Array = step.get("sides", [])
	var side := str(sample.get("looked", ""))
	if side == "" and sample.has("look_yaw"):
		var y := float(sample.look_yaw)
		if absf(y) < LOOK_YAW * 0.5:
			state.last = ""
		var now := "left" if y >= LOOK_YAW else ("right" if y <= -LOOK_YAW else "")
		if now != "" and now != str(state.last):
			state.last = now
			side = now
	var i := int(state.i)
	if side == "" or i >= sides.size():
		out.done = i >= sides.size()
		return
	if side == str(sides[i]):
		state.i = i + 1
		out.progress = true
	else:
		out.said = (LOOK_FIRST if i == 0 else LOOK_NEXT) % sides[i]
	out.done = int(state.i) >= sides.size()


## Owner #112, The Kitchen: pouring (or spooning onto the scales) while held; let go inside the band to be done.
static func _pour(step: Dictionary, state: Dictionary, holding: bool, dt: float, out: Dictionary) -> void:
	var want := float(step.get("want", 0.5))
	var tol := float(step.get("tol", 0.07))
	if holding:
		state.level = minf(float(state.level) + float(step.get("rate", 0.25)) * dt, float(step.get("full", 1.0)))
		state.pouring = true
		out.progress = true
		return
	if not bool(state.pouring):
		return
	state.pouring = false
	var level := float(state.level)
	if absf(level - want) <= tol:
		out.done = true
	elif level < want:
		out.said = POUR_MORE
	else:
		out.said = POUR_TOO_MUCH
		state.level = maxf(want - tol * 2.0, 0.0)
		out.progress = true


## Owner #112, Calm Corner: balloon breathing. Held is in (at least `in` s), let go is out (at least `out` s): one
## breath. Too quick is a kind word, never a miss.
static func _breathe(step: Dictionary, state: Dictionary, breathing_in: bool, dt: float, out: Dictionary) -> void:
	var phase := str(state.phase)
	if breathing_in:
		if phase == "out":
			out.said = BREATHE_SLOWLY
		if phase != "in":
			state.phase = "in"
			state.t = dt
		else:
			state.t = float(state.t) + dt
		out.progress = true
	elif phase == "in":
		if float(state.t) >= float(step.get("in", 3.0)):
			state.phase = "out"
			state.t = dt
			out.progress = true
		else:
			out.said = BREATHE_SLOWLY
			state.phase = "rest"
			state.t = 0.0
	elif phase == "out":
		state.t = float(state.t) + dt
		out.progress = true
		if float(state.t) >= float(step.get("out", 3.0)):
			state.count = int(state.count) + 1
			state.phase = "rest"
			state.t = 0.0
	out.done = int(state.count) >= int(step.get("breaths", 3))


## Owner #112, Safe Streets (Big): a pedal held raises the needle, let go lowers it; seconds inside the band count.
static func _steady(step: Dictionary, state: Dictionary, holding: bool, dt: float, out: Dictionary) -> void:
	var v := float(state.value) + (float(step.get("up", 12.0)) if holding else -float(step.get("down", 8.0))) * dt
	v = clampf(v, 0.0, float(step.get("top", 60.0)))
	state.value = v
	if v >= float(step.get("lo", 0.0)) and v <= float(step.get("hi", 0.0)):
		state.t = float(state.t) + dt
		out.progress = true
	elif v > float(step.get("hi", 0.0)) and float(state.clock) - float(state.said_at) >= SAY_EVERY:
		out.said = TOO_FAST
		state.said_at = state.clock
	if holding:
		out.progress = true
	out.done = float(state.t) >= float(step.get("seconds", 1.0))
