class_name LeafWeather
extends RefCounted
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.3, §3.5, §3.5b, §3.10, ruling 25): the weather is the music the
## child plays along to. A voyage's script (LeafVoyages: `script`), segment after segment: blaze, cloud, evening, night,
## the desert's day (its first seconds a dawn that warms) and night. `at(t)` is the weather at `t` seconds into the
## script, with which way a plant that knows the rule sets its doors (`open`: the ghost's and the rule's direction).
## The script can change while it plays: a window lasts longer after two missed turns (`lengthen`), and the bud asks for
## more turns when it isn't full (`add_turn`, up to the voyage's `turns.max`). Pure.

var segments: Array[Dictionary] = []
var kinds := {}
## {max, cloud, blaze}: extra turns (a cloud and a blaze before the evening) while the bud isn't full; {} for none.
var turns := {}


static func for_voyage(id: String) -> LeafWeather:
	var v := LeafVoyages.voyage(id)
	return make(v.get("script", []), LeafVoyages.weather_kinds(), v.get("turns", {}))


static func make(script: Array, weather_kinds: Dictionary, extra_turns: Dictionary = {}) -> LeafWeather:
	var w := LeafWeather.new()
	for s: Dictionary in script:
		var seg := s.duplicate()
		seg.seconds = float(s.get("seconds", 0.0))
		w.segments.append(seg)
	w.kinds = weather_kinds
	w.turns = extra_turns
	return w


## The weather `t` seconds into the script: {index, id, kind, since, left, seconds, heat, light, night, open, voiced,
## longer}; after the end the last segment holds; {} when there is no script.
func at(t: float) -> Dictionary:
	if segments.is_empty():
		return {}
	var i := index_at(t)
	var seg := segments[i]
	var since := t - start_of(i)
	var seconds := float(seg.seconds)
	var kind := str(seg.kind)
	var k: Dictionary = kinds.get(kind, {})
	var heat := float(k.get("heat", 0.0))
	var light := float(k.get("light", 0.0))
	var dawn := float(seg.get("dawn", 0.0))
	if dawn > 0.0 and since < dawn:
		var f := clampf(since / dawn, 0.0, 1.0)
		heat = lerpf(float(k.get("dawn_heat", heat)), heat, f)
		light = lerpf(float(k.get("dawn_light", light)), light, f)
	return {"index": i, "id": str(seg.get("id", "")), "kind": kind, "since": since, "left": maxf(seconds - since, 0.0),
		"seconds": seconds, "heat": heat, "light": light, "night": bool(k.get("night", false)),
		"open": str(k.get("doors", "shut")) == "open", "voiced": bool(seg.get("voiced", false)),
		"longer": bool(seg.get("longer", false)), "dawn": dawn}


## The segment playing at `t` (the last one after the end).
func index_at(t: float) -> int:
	var acc := 0.0
	for i in segments.size():
		acc += float(segments[i].seconds)
		if t < acc:
			return i
	return maxi(segments.size() - 1, 0)


func start_of(index: int) -> float:
	var acc := 0.0
	for i in mini(index, segments.size()):
		acc += float(segments[i].seconds)
	return acc


func index_of(id: String) -> int:
	for i in segments.size():
		if str(segments[i].get("id", "")) == id:
			return i
	return -1


func total() -> float:
	return start_of(segments.size())


func ended(t: float) -> bool:
	return t >= total()


## Ruling 25: after two missed silent turns the next window lasts `extra` longer (0.3: 30 %); the beat is still judged
## and its note says so (`longer`).
func lengthen(index: int, extra: float) -> void:
	if index < 0 or index >= segments.size():
		return
	segments[index].seconds = float(segments[index].seconds) * (1.0 + extra)
	segments[index].longer = true


## The turns so far (each cloud is one).
func turn_count() -> int:
	return segments.filter(func(s: Dictionary) -> bool: return str(s.kind) == "cloud").size()


## One more cloud and blaze before the evening (the bud isn't full yet); false at the voyage's most turns, or when its
## script has no extra turns.
func add_turn() -> bool:
	if turns.is_empty() or turn_count() >= int(turns.get("max", 0)):
		return false
	var n := turn_count() + 1
	var at := segments.size()
	if at > 0 and str(segments[at - 1].kind) == "evening":
		at -= 1
	segments.insert(at, {"id": "blaze%d" % n, "kind": "blaze", "seconds": float(turns.get("blaze", 15.0)), "extra": true})
	segments.insert(at, {"id": "cloud%d" % n, "kind": "cloud", "seconds": float(turns.get("cloud", 20.0)), "extra": true})
	return true
