class_name RoundPlan
extends RefCounted
## Owner #68 (spec §22.1): a practice round: ROUND_SIZE exercises, easy to harder, picked from a unit's hand-written
## exercises and its generators with a seeded rng (every round is new; the same seed, the same round). A unit with
## more stars gets harder rounds (TARGETS). A level the unit lacks takes the nearest one (the lower on a tie).
## Hand-written exercises are not repeated in a round while there are others of that level; generators never run out.
## A hand-written choice's choices are shown in a seeded order (the files write the right one first).

const TARGETS: Array = [[1, 1, 2, 2, 2, 3], [1, 2, 2, 2, 3, 3], [2, 2, 3, 3, 3, 3]]


static func plan(content: Dictionary, seed: int, stars: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var slots := _slots(content)
	if slots.is_empty():
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var used := {}
	for level: int in TARGETS[clampi(stars, 0, TARGETS.size() - 1)]:
		var near := _nearest_level(slots, level)
		var fresh: Array = slots.filter(func(s: Dictionary) -> bool:
			return int(s.level) == near and not used.has(s.key))
		if fresh.is_empty():
			fresh = slots.filter(func(s: Dictionary) -> bool: return int(s.level) == near)
		var pick: Dictionary = fresh[rng.randi_range(0, fresh.size() - 1)]
		if pick.has("gen"):
			out.append(SchoolGen.make(str(pick.gen), rng.randi(), near))
		else:
			used[pick.key] = true
			out.append(_mixed((pick.ex as Dictionary).duplicate(true), seed))
	return out


## A hand-written choice with its choices in a seeded order, the answer following its choice: the data files write the
## right one first, and a child must not learn "the first button". Its own rng, so the round's picks stay the same.
static func _mixed(ex: Dictionary, seed: int) -> Dictionary:
	var choices: Variant = ex.get("choices")
	if str(ex.get("type", "")) != "choice" or not choices is Array or typeof(ex.get("answer")) not in [TYPE_INT, TYPE_FLOAT]:
		return ex
	var n := (choices as Array).size()
	if int(ex.answer) < 0 or int(ex.answer) >= n:
		return ex
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, str(ex.get("id", "")), str(ex.get("prompt", ""))])
	var order: Array = range(n)
	GenKit.shuffle(rng, order)
	var mixed: Array = []
	for i: int in order:
		mixed.append(choices[i])
	ex.choices = mixed
	ex.answer = order.find(int(ex.answer))
	return ex


## Every choice the unit offers: {level, key, ex} for a hand-written exercise, {level, key, gen} for a generator that
## exists.
static func _slots(content: Dictionary) -> Array:
	var out: Array = []
	var exercises: Variant = content.get("exercises", [])
	if exercises is Array:
		for i in (exercises as Array).size():
			var ex: Dictionary = exercises[i]
			out.append({"level": clampi(int(ex.get("level", 1)), 1, 3), "key": "ex%d" % i, "ex": ex})
	var gens: Variant = content.get("generators", [])
	if gens is Array:
		for i in (gens as Array).size():
			var g: Dictionary = gens[i]
			if SchoolGen.exists(str(g.get("gen", ""))):
				out.append({"level": clampi(int(g.get("level", 1)), 1, 3), "key": "gen%d" % i, "gen": g.gen})
	return out


static func _nearest_level(slots: Array, level: int) -> int:
	var best := -1
	for s: Dictionary in slots:
		var l := int(s.level)
		if best < 0 or absi(l - level) < absi(best - level) or (absi(l - level) == absi(best - level) and l < best):
			best = l
	return best
