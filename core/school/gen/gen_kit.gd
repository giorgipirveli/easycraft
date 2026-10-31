class_name GenKit
extends RefCounted
## Owner #68: helpers the School's generators share (core/school/gen/): building exercises in ExerciseCheck's form, seeded
## shuffles, numbers written the way the lessons write them.

const PLACES: Array[String] = ["ones", "tens", "hundreds", "thousands", "ten thousands", "hundred thousands", "millions"]


## A choice exercise: `right` and `wrongs` shuffled by the rng (every choice different).
static func choice(rng: RandomNumberGenerator, prompt: String, right: Variant, wrongs: Array, hint: String,
		explain: String = "", picture: Dictionary = {}) -> Dictionary:
	var choices: Array = [right]
	for w: Variant in wrongs:
		if not choices.has(w):
			choices.append(w)
	shuffle(rng, choices)
	return _with({"type": "choice", "prompt": prompt, "choices": choices, "answer": choices.find(right), "hint": hint},
		explain, picture)


static func number(prompt: String, answer: Variant, hint: String, explain: String = "", picture: Dictionary = {}) -> Dictionary:
	return _with({"type": "number", "prompt": prompt, "answer": str(answer), "hint": hint}, explain, picture)


static func truefalse(prompt: String, answer: bool, hint: String, explain: String = "", picture: Dictionary = {}) -> Dictionary:
	return _with({"type": "truefalse", "prompt": prompt, "answer": answer, "hint": hint}, explain, picture)


## An order exercise: `in_order` is the right order; the items are shown shuffled (never already in order).
static func order(rng: RandomNumberGenerator, prompt: String, in_order: Array, hint: String, explain: String = "",
		picture: Dictionary = {}) -> Dictionary:
	var idx: Array = range(in_order.size())
	for _i in 8:
		shuffle(rng, idx)
		if idx != range(in_order.size()):
			break
	if idx == range(in_order.size()):
		idx.reverse()
	var items: Array = []
	for i: int in idx:
		items.append(in_order[i])
	var answer: Array = []
	for item: Variant in in_order:
		answer.append(items.find(item))
	return _with({"type": "order", "prompt": prompt, "items": items, "answer": answer, "hint": hint}, explain, picture)


static func build(prompt: String, board: Dictionary, goal: Dictionary, hint: String, explain: String = "",
		picture: Dictionary = {}) -> Dictionary:
	return _with({"type": "build", "prompt": prompt, "board": board, "goal": goal, "hint": hint}, explain, picture)


## Fisher-Yates with the rng (the same seed, the same order).
static func shuffle(rng: RandomNumberGenerator, a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = a[i]
		a[i] = a[j]
		a[j] = t


## A whole number with thousands commas: 472305 -> "472,305".
static func fmt(n: int) -> String:
	return ("-" if n < 0 else "") + NumberPad.group(str(absi(n)))


## A random whole number with exactly `digits` digits.
static func with_digits(rng: RandomNumberGenerator, digits: int) -> int:
	var lo := int(pow(10, digits - 1))
	return rng.randi_range(lo, lo * 10 - 1)


static func pow10(k: int) -> int:
	return int(pow(10, k))


## "a/b"
static func frac(num: int, den: int) -> String:
	return "%d/%d" % [num, den]


## `count` different whole numbers near `right` (never `right`, never below `floor`), for wrong choices.
static func near(rng: RandomNumberGenerator, right: int, count: int, spread: int, floor_value: int = 0) -> Array:
	var out: Array = []
	var tries := 0
	while out.size() < count and tries < 200:
		tries += 1
		var v := right + rng.randi_range(-spread, spread)
		if v != right and v >= floor_value and not out.has(v):
			out.append(v)
	var step := 1
	while out.size() < count:
		var v := right + step
		if not out.has(v):
			out.append(v)
		step += 1
	return out


static func _with(ex: Dictionary, explain: String, picture: Dictionary) -> Dictionary:
	if explain != "":
		ex.explain = explain
	if not picture.is_empty():
		ex.picture = picture
	return ex
