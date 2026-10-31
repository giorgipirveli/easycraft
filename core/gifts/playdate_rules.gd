class_name PlaydateRules
extends RefCounted
## Buddy playdates (M4 Wave 3, agent I; research T4, spec §3a "Buddies meet friends' buddies"): when
## friends play together, two buddies of different owners within NOTICE blocks notice each other and
## wave (WAVE), walk to the middle between them (MEET, until MEET_GAP apart or MEET_TIME), dance together
## (DANCE), the first follows the second a little (FOLLOW), then both go back to their owners and the
## pair rests REST seconds. A buddy plays with one friend at a time, its nearest first. Pure: the host
## calls step() at most 10 times a second (TICK) with where the buddies are; the answer says where each
## buddy in a playdate walks (none: it follows its owner as always) and what every game shows.

const NOTICE := 16.0
const LOST := 24.0          # a pair this far apart (teleported, pushed) ends
const TICK := 0.1
const WAVE_TIME := 1.2
const MEET_TIME := 6.0
const MEET_GAP := 2.5
const DANCE_TIME := 4.0
const FOLLOW_TIME := 5.0
const REST := 60.0

const WAVE := &"wave"
const MEET := &"meet"
const DANCE := &"dance"
const FOLLOW := &"follow"

var _pairs := {}            # key -> {"a", "b", "phase", "since"}
var _resting := {}          # key -> until (seconds)


## buddies: [{"name", "owner", "pos"}]; now in seconds. {"targets": {name: Vector3}, "events": [[kind, a, b]]}
## (kind "wave" when a playdate starts, "dance" when the dance starts).
func step(buddies: Array, now: float) -> Dictionary:
	var by_name := {}
	for b: Dictionary in buddies:
		by_name[b.name] = b
	var events: Array = []
	for key: String in _pairs.keys():
		var p: Dictionary = _pairs[key]
		if not by_name.has(p.a) or not by_name.has(p.b) or _dist(by_name[p.a], by_name[p.b]) > LOST:
			_end(key, now)
			continue
		_advance(key, p, by_name, now, events)
	_start_new(buddies, by_name, now, events)
	var targets := {}
	for key: String in _pairs:
		var p: Dictionary = _pairs[key]
		var a: Vector3 = by_name[p.a].pos
		var b: Vector3 = by_name[p.b].pos
		match p.phase:
			WAVE, DANCE:
				targets[p.a] = a
				targets[p.b] = b
			MEET:
				targets[p.a] = (a + b) * 0.5
				targets[p.b] = (a + b) * 0.5
			FOLLOW:
				targets[p.a] = b
	return {"targets": targets, "events": events}


## The phase of a buddy's playdate (&"" when it has none).
func phase_of(buddy_name: String) -> StringName:
	for key: String in _pairs:
		if _pairs[key].a == buddy_name or _pairs[key].b == buddy_name:
			return _pairs[key].phase
	return &""


func _advance(key: String, p: Dictionary, by_name: Dictionary, now: float, events: Array) -> void:
	var t := now - float(p.since)
	match p.phase:
		WAVE:
			if t >= WAVE_TIME - 0.0001:
				_to(p, MEET, now)
		MEET:
			if _dist(by_name[p.a], by_name[p.b]) <= MEET_GAP or t >= MEET_TIME - 0.0001:
				_to(p, DANCE, now)
				events.append(["dance", p.a, p.b])
		DANCE:
			if t >= DANCE_TIME - 0.0001:
				_to(p, FOLLOW, now)
		FOLLOW:
			if t >= FOLLOW_TIME - 0.0001:
				_end(key, now)


func _start_new(buddies: Array, by_name: Dictionary, now: float, events: Array) -> void:
	var busy := {}
	for key: String in _pairs:
		busy[_pairs[key].a] = true
		busy[_pairs[key].b] = true
	var names: Array = by_name.keys()
	names.sort()
	for n: String in names:
		if busy.has(n):
			continue
		var me: Dictionary = by_name[n]
		var best := ""
		var best_d := INF
		for other: Dictionary in buddies:
			if busy.has(other.name) or other.name == n or int(other.owner) == int(me.owner):
				continue
			var d := _dist(me, other)
			if d <= NOTICE and d < best_d and float(_resting.get(_key(n, other.name), -INF)) <= now:
				best = other.name
				best_d = d
		if best == "":
			continue
		var pair := [n, best]
		pair.sort()
		_pairs[_key(n, best)] = {"a": pair[0], "b": pair[1], "phase": WAVE, "since": now}
		busy[n] = true
		busy[best] = true
		events.append(["wave", pair[0], pair[1]])


func _to(p: Dictionary, phase: StringName, now: float) -> void:
	p.phase = phase
	p.since = now


func _end(key: String, now: float) -> void:
	_pairs.erase(key)
	_resting[key] = now + REST


static func _key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


static func _dist(a: Dictionary, b: Dictionary) -> float:
	return (a.pos as Vector3).distance_to(b.pos)
