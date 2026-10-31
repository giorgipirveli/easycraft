class_name ToolDevice
extends RefCounted
## Owner #117 (docs/design/life-skills.md §13, "Devices: buttons, dials, displays and an order of steps"): one model for
## every machine and appliance, at run time. Its data is Life L1's device data (LifeExperience.devices: controls, shows,
## order, safety), as words or as entries:
## - controls: "words" or {id, words}: what can be pressed, turned, opened;
## - shows: "words" or {id, words, start}: a display, a light, a sound, and what it shows at the start;
## - order: "words" or {do (a control's or a safety step's id; words: their slug), words, value (a dial's setting),
##   shows {display: what it shows now}}: the right order;
## - safety: "words" or {id, words, before [control ids it must come before]}: the safety steps (goggles before the
##   trigger) and the rules to know.
## use(control, value) does the next step only when it is that one: a later one says kindly what comes first, a control a
## safety step guards waits for it ("Safety first: goggles on."), nothing is ever skipped or punished.

const FIRST := "First: %s."
const SAFETY_FIRST := "Safety first: %s."

var id := ""
var controls: Array[Dictionary] = []
var shows: Array[Dictionary] = []
var order: Array[Dictionary] = []
var safety: Array[Dictionary] = []
## The next step of the order.
var index := 0
var finished := false
## Display id -> what it shows now.
var displays := {}
## Control id -> its setting now.
var values := {}
var _safe := {}


static func from(data: Dictionary, device_id: String = "") -> ToolDevice:
	var d := ToolDevice.new()
	d.id = device_id
	for c: Variant in data.get("controls", []):
		d.controls.append(_entry(c, "id"))
	for s: Variant in data.get("shows", []):
		var e := _entry(s, "id")
		d.shows.append(e)
		d.displays[str(e.id)] = str(e.get("start", ""))
	for o: Variant in data.get("order", []):
		d.order.append(_entry(o, "do"))
	for s: Variant in data.get("safety", []):
		d.safety.append(_entry(s, "id"))
	d.finished = d.order.is_empty()
	return d


## Words as an id: "Pull the pin!" -> "pull_the_pin".
static func slug(words: String) -> String:
	var out := ""
	for ch in words.strip_edges().to_lower():
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			out += ch
		elif not out.ends_with("_") and out != "":
			out += "_"
	return out.trim_suffix("_")


## An entry from words or a Dictionary (its id key filled from its words when missing).
static func _entry(v: Variant, key: String) -> Dictionary:
	if v is Dictionary:
		var e := (v as Dictionary).duplicate(true)
		if str(e.get(key, "")) == "" and str(e.get("words", "")) != "" and not e.has(key):
			e[key] = slug(str(e.words))
		return e
	return {key: slug(str(v)), "words": str(v)}


## What is wrong with a device's data ([] when nothing).
static func problems(data: Variant) -> Array[String]:
	var out: Array[String] = []
	if not data is Dictionary:
		return ["a device is not an object"]
	for key: String in ["controls", "shows", "order", "safety"]:
		var list: Variant = (data as Dictionary).get(key)
		if not list is Array or (list as Array).is_empty():
			out.append("a device needs its %s" % key)
	if not out.is_empty():
		return out
	var d := from(data)
	var known := {}
	for c in d.controls:
		if str(c.get("id", "")) == "" or str(c.get("words", "")) == "":
			out.append("a control without its id or words")
		known[str(c.get("id", ""))] = true
	for s in d.safety:
		if str(s.get("id", "")) == "" or str(s.get("words", "")) == "":
			out.append("a safety step without its id or words")
		for b: Variant in s.get("before", []):
			if not known.has(str(b)):
				out.append("safety %s guards %s, which is not a control" % [s.id, b])
			elif not d._in_order(str(s.id)):
				out.append("safety %s guards %s but is never in the order" % [s.id, b])
	for o in d.order:
		if str(o.get("do", "")) == "" or str(o.get("words", "")) == "":
			out.append("an order step without what it does or its words")
	for s in d.shows:
		if str(s.get("id", "")) == "" or str(s.get("words", "")) == "":
			out.append("a display without its id or words")
	return out


## Uses a control (or does a safety step: goggles on) with an optional setting: {ok, said, safety (the safety step it
## waits for), done (the whole order)}.
func use(control: String, value: String = "") -> Dictionary:
	var r := {"ok": false, "said": "", "safety": "", "done": finished}
	if finished or not knows(control):
		return r
	var guard := _guard(control)
	if not guard.is_empty():
		r.said = SAFETY_FIRST % str(guard.words)
		r.safety = str(guard.id)
		return r
	if _is_safety(control):
		_safe[control] = true
	var next := order[index]
	if str(next.do) == control and (not next.has("value") or str(next.value) == value or value == ""):
		if next.has("value"):
			values[control] = str(next.value)
		elif value != "":
			values[control] = value
		var now: Variant = next.get("shows", {})
		if now is Dictionary:
			for k: Variant in now:
				displays[str(k)] = str(now[k])
		index += 1
		finished = index >= order.size()
		r.ok = true
		r.done = finished
		return r
	if _is_safety(control) and not _in_order(control):
		r.ok = true   # a rule kept at any time (hands out of the drum)
		return r
	r.said = FIRST % str(next.words)
	return r


## Something this device has: a control, an order step or a safety step.
func knows(thing: String) -> bool:
	for c in controls:
		if str(c.id) == thing:
			return true
	return _in_order(thing) or _is_safety(thing)


## What the next step uses (it glows): a control's or a safety step's id ("" when finished).
func next_do() -> String:
	return "" if finished else str(order[index].do)


func next_words() -> String:
	return "" if finished else str(order[index].words)


func fraction() -> float:
	return 1.0 if finished else float(index) / maxf(order.size(), 1.0)


func display(display_id: String) -> String:
	return str(displays.get(display_id, ""))


func safety_words() -> Array[String]:
	var out: Array[String] = []
	for s in safety:
		out.append(str(s.words))
	return out


## The safety step that guards `control` and is not done yet ({} for none).
func _guard(control: String) -> Dictionary:
	for s in safety:
		if (s.get("before", []) as Array).has(control) and not _safe.has(str(s.id)):
			return s
	return {}


func _is_safety(thing: String) -> bool:
	for s in safety:
		if str(s.id) == thing:
			return true
	return false


func _in_order(thing: String) -> bool:
	for o in order:
		if str(o.do) == thing:
			return true
	return false
