class_name PlayPlacing
extends RefCounted
## Owner #122 (docs/design/learning-is-play.md §5.1): things put into places, the rule under Sort it (a sort's items into
## its groups' bins: a bin holds many), Order it (an order's items as planks into the bridge's slots, one each), Connect
## it (a match's items as posts wired to its matches' sockets, one each) and Fix it (a label exercise's labels onto its
## picture's pins, one each). `at[thing]` is the place a thing is in (-1: still at home). `response` is ExerciseCheck's
## form: for an order the item in each slot, for the others each thing's place. `ghost_step` is the coach's one step:
## a wrongly placed thing back home first, else the first thing not placed yet into its right place.

var kind := ""
var things := 0
var places := 0
var many := false
var at: Array[int] = []


static func for_exercise(ex: Dictionary) -> PlayPlacing:
	var p := PlayPlacing.new()
	p.kind = str(ex.get("type", ""))
	match p.kind:
		"sort":
			p.things = (ex.get("items", []) as Array).size()
			p.places = (ex.get("groups", []) as Array).size()
			p.many = true
		"order":
			p.things = (ex.get("items", []) as Array).size()
			p.places = p.things
		"match":
			p.things = (ex.get("items", []) as Array).size()
			p.places = (ex.get("matches", []) as Array).size()
		"label":
			p.things = (ex.get("labels", []) as Array).size()
			p.places = (ex.get("spots", []) as Array).size()
	p.clear()
	return p


func clear() -> void:
	at.clear()
	for i in things:
		at.append(-1)


## Puts `thing` into `place` (-1: back home); in a one-thing place the thing already there goes home.
func put(thing: int, place: int) -> void:
	if thing < 0 or thing >= things or place >= places:
		return
	if place >= 0 and not many:
		var there := occupant(place)
		if there >= 0 and there != thing:
			at[there] = -1
	at[thing] = place


func take(thing: int) -> void:
	put(thing, -1)


## The thing in a one-thing place (-1: none; a bin: the first one in it).
func occupant(place: int) -> int:
	return at.find(place)


func placed_count() -> int:
	return at.filter(func(p: int) -> bool: return p >= 0).size()


## Every thing has its place.
func complete() -> bool:
	return things > 0 and placed_count() == things


func response() -> Array[int]:
	var out: Array[int] = []
	if kind == "order":
		for s in places:
			out.append(occupant(s))
		return out
	return at.duplicate()


## Where `thing` belongs (ExerciseCheck's answer; its numbers may be JSON's floats).
func right_place(ex: Dictionary, thing: int) -> int:
	var answer: Array = ex.get("answer", [])
	if kind == "order":
		for s in answer.size():
			if int(answer[s]) == thing:
				return s
		return -1
	return int(answer[thing]) if thing < answer.size() else -1


## The coach's one step: {"thing": i, "place": -1} to take a wrong one back, {"thing": i, "place": p} to place one right,
## {} when everything is right.
func ghost_step(ex: Dictionary) -> Dictionary:
	for i in things:
		if at[i] >= 0 and at[i] != right_place(ex, i):
			return {"thing": i, "place": -1}
	for i in _order_of_things(ex):
		if at[i] < 0:
			return {"thing": i, "place": right_place(ex, i)}
	return {}


func apply(step: Dictionary) -> void:
	if step.has("thing"):
		put(int(step.thing), int(step.get("place", -1)))


## The worked answer: every thing in its right place.
func show_answer(ex: Dictionary) -> void:
	clear()
	for i in things:
		put(i, right_place(ex, i))


## An order's planks are laid from the first slot; the others go thing by thing.
func _order_of_things(ex: Dictionary) -> Array[int]:
	var out: Array[int] = []
	if kind == "order":
		for v: Variant in ex.get("answer", []):
			out.append(int(v))
		return out
	for i in things:
		out.append(i)
	return out
