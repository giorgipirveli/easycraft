class_name MindMemory
extends RefCounted
## A creature's small memory (M2 Task 18, spec §12.17): up to MAX_PLAYERS players by name (how much
## it likes and fears each, when it saw them last) and up to MAX_PLACES places (food, its den, danger,
## a favourite spot). Feelings fade over time — a fright in about a minute, liking in about ten —
## and faded strangers and places are forgotten. An owner is pinned: never forgotten, always liked.
## Pets and bot friends save it with the world; wild animals keep it while they live.

const MAX_PLAYERS := 8
const MAX_PLACES := 8
const FOOD := &"food"
const DEN := &"den"
const DANGER := &"danger"
const FAVOURITE := &"favourite"
const KINDS: Array[StringName] = [FOOD, DEN, DANGER, FAVOURITE]
const OWNER_LIKE := 0.8           # a pinned player is liked at least this much
const FEAR_HALF_LIFE := 45.0      # seconds
const LIKE_HALF_LIFE := 600.0
const PLACE_HALF_LIFE := 600.0
const FORGET_AFTER := 300.0       # a stranger with no feelings left, unseen this long, is forgotten
const FADED := 0.05
const PLACE_MERGE := 4.0          # spots of one kind this close are one place
const MAX_NAME := 32
const NOBODY := {}                # entry() of a stranger

## [{name: String, like: float, fear: float, seen: float, pinned: bool}]
var players: Array[Dictionary] = []
## [{kind: StringName, pos: Vector3, weight: float, seen: float}]
var places: Array[Dictionary] = []


func knows(who: String) -> bool:
	return _find(who) >= 0


## Seeing `who` at time `now`. True when it is a new face.
func saw(who: String, now: float) -> bool:
	var i := _find(who)
	if i >= 0:
		players[i].seen = now
		return false
	_add(who, now)
	return true


## How it feels about `who` changes by these amounts (like and fear stay 0..1).
func feel_about(who: String, like_delta: float, fear_delta: float, now: float) -> void:
	var i := _find(who)
	if i < 0:
		i = _add(who, now)
		if i < 0:
			return
	var e := players[i]
	e.like = clampf(float(e.like) + _finite(like_delta), OWNER_LIKE if e.pinned else 0.0, 1.0)
	e.fear = clampf(float(e.fear) + _finite(fear_delta), 0.0, 1.0)
	e.seen = now


func like(who: String) -> float:
	var i := _find(who)
	return float(players[i].like) if i >= 0 else 0.0


func fear(who: String) -> float:
	var i := _find(who)
	return float(players[i].fear) if i >= 0 else 0.0


## `who` is this creature's owner: never forgotten, always liked.
func pin(who: String) -> void:
	var i := _find(who)
	if i < 0:
		i = _add(who, 0.0)
	if i >= 0:
		players[i].pinned = true
		players[i].like = maxf(float(players[i].like), OWNER_LIKE)


## Remembers a place of `kind` at `pos` (a spot next to one of the same kind makes it stronger).
func note_place(kind: StringName, pos: Vector3, weight: float, now: float) -> void:
	if not KINDS.has(kind) or not pos.is_finite():
		return
	for e in places:
		if e.kind == kind and (e.pos as Vector3).distance_to(pos) <= PLACE_MERGE:
			e.pos = ((e.pos as Vector3) + pos) * 0.5
			e.weight = minf(float(e.weight) + maxf(weight, 0.0), 4.0)
			e.seen = now
			return
	places.append({"kind": kind, "pos": pos, "weight": clampf(weight, 0.0, 4.0), "seen": now})
	if places.size() > MAX_PLACES:
		var weakest := 0
		for i in places.size():
			if float(places[i].weight) < float(places[weakest].weight):
				weakest = i
		places.remove_at(weakest)


## The place of `kind` nearest to `near` (or the strongest one without `near`), or Vector3.INF.
func place(kind: StringName, near := Vector3.INF) -> Vector3:
	var best := Vector3.INF
	var best_v := INF
	for e in places:
		if e.kind != kind:
			continue
		var v: float = near.distance_squared_to(e.pos) if near.is_finite() else -float(e.weight)
		if v < best_v:
			best_v = v
			best = e.pos
	return best


## Lets `dt` seconds pass (at time `now`): feelings and places fade; faded strangers and places go.
func forget(now: float, dt: float) -> void:
	var fear_k := pow(0.5, dt / FEAR_HALF_LIFE)
	var like_k := pow(0.5, dt / LIKE_HALF_LIFE)
	for i in range(players.size() - 1, -1, -1):
		var e := players[i]
		e.fear = float(e.fear) * fear_k
		e.like = maxf(float(e.like) * like_k, OWNER_LIKE if e.pinned else 0.0)
		if not e.pinned and e.like < FADED and e.fear < FADED and now - float(e.seen) > FORGET_AFTER:
			players.remove_at(i)
	var place_k := pow(0.5, dt / PLACE_HALF_LIFE)
	for i in range(places.size() - 1, -1, -1):
		places[i].weight = float(places[i].weight) * place_k
		if places[i].weight < FADED:
			places.remove_at(i)


func to_save() -> Dictionary:
	var p: Array = []
	for e in players:
		p.append([e.name, snappedf(e.like, 0.01), snappedf(e.fear, 0.01), 1 if e.pinned else 0])
	var l: Array = []
	for e in places:
		var pos: Vector3 = e.pos
		l.append([String(e.kind), snappedf(pos.x, 0.1), snappedf(pos.y, 0.1), snappedf(pos.z, 0.1), snappedf(e.weight, 0.01)])
	return {"p": p, "l": l}


## A memory from a save; anything broken is left out.
static func from_save(d: Variant) -> MindMemory:
	var m := MindMemory.new()
	if not d is Dictionary:
		return m
	var p: Variant = (d as Dictionary).get("p")
	if p is Array:
		for e: Variant in p:
			if not e is Array or (e as Array).size() != 4 or not e[0] is String or str(e[0]) == "":
				continue
			if not _num(e[1]) or not _num(e[2]) or not _num(e[3]):
				continue
			if m.players.size() >= MAX_PLAYERS:
				break
			var who := str(e[0]).substr(0, MAX_NAME)
			m.feel_about(who, clampf(float(e[1]), 0.0, 1.0), clampf(float(e[2]), 0.0, 1.0), 0.0)
			if int(e[3]) == 1:
				m.pin(who)
	var l: Variant = (d as Dictionary).get("l")
	if l is Array:
		for e: Variant in l:
			if not e is Array or (e as Array).size() != 5 or not KINDS.has(StringName(str(e[0]))):
				continue
			if not (_num(e[1]) and _num(e[2]) and _num(e[3]) and _num(e[4])):
				continue
			m.note_place(StringName(str(e[0])), Vector3(float(e[1]), float(e[2]), float(e[3])), float(e[4]), 0.0)
	return m


## Everything it remembers about `who` ({name, like, fear, seen, pinned}), or an empty dictionary
## for a stranger. One lookup for all of it (a creature reads this every decision).
func entry(who: String) -> Dictionary:
	var i := _find(who)
	return players[i] if i >= 0 else NOBODY


func _find(who: String) -> int:
	var key := who if who.length() <= MAX_NAME else who.substr(0, MAX_NAME)
	for i in players.size():
		if players[i].name == key:
			return i
	return -1


## Adds `who`; when the memory is full, the least important face it isn't bound to goes. -1 if
## there is no room (every face is pinned).
func _add(who: String, now: float) -> int:
	if who == "":
		return -1
	if players.size() >= MAX_PLAYERS:
		var out := -1
		var out_v := INF
		for i in players.size():
			var e := players[i]
			if e.pinned:
				continue
			var v := float(e.like) + float(e.fear) + float(e.seen) * 0.0001
			if v < out_v:
				out_v = v
				out = i
		if out < 0:
			return -1
		players.remove_at(out)
	players.append({"name": who.substr(0, MAX_NAME), "like": 0.0, "fear": 0.0, "seen": now, "pinned": false})
	return players.size() - 1


static func _finite(v: float) -> float:
	return v if is_finite(v) else 0.0


static func _num(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v))
