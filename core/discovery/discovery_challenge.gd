class_name DiscoveryChallenge
extends RefCounted
## Owner #132 (W1), stage 2: one crystal's play, its rules alone (DiscoveryPlays makes the challenges; DiscoveryCrystal
## shows them). take(i) is the child's move: a gem taken (MAKE: its value added; ORDER: it is the smallest left). The
## world answers: TAKEN (it flew in), MADE (the challenge is solved), BOUNCED (it bounced off: past or farther from the
## number, or not the smallest; a miss, nothing lost). After two misses in a challenge the helpful gem is shown
## (shown_hint: rule 4, shown not told). first_try counts the challenges solved with no miss: what the play records.

const TAKEN := &"taken"
const MADE := &"made"
const BOUNCED := &"bounced"
const PLAYING := &"playing"
const DONE := &"done"
## Misses before the helpful gem glows.
const HINT_AFTER := 2

var challenges: Array[Dictionary] = []
var index := 0
## MAKE: the number on the crystal now (in 1/scale units). ORDER: unused.
var total := 0
## ORDER: the gems taken (indices), in order.
var taken: Array[int] = []
var misses := 0
var first_try := 0
var _solved := false


func _init(list: Array[Dictionary]) -> void:
	challenges = list
	_begin()


func current() -> Dictionary:
	return challenges[index] if index < challenges.size() else {}


func state() -> StringName:
	return DONE if _solved else PLAYING


## Every challenge solved (next() said there is no other).
func finished() -> bool:
	return _solved and index >= challenges.size() - 1


## The child takes gem `i` of the current challenge.
func take(i: int) -> StringName:
	var c := current()
	if c.is_empty() or _solved:
		return BOUNCED
	if str(c.kind) == "make":
		return _take_make(c, i)
	return _take_order(c, i)


## On to the next challenge; false when this was the last.
func next() -> bool:
	if index >= challenges.size() - 1:
		return false
	index += 1
	_begin()
	return true


## The gem that helps now (MAKE: the biggest step towards the number that does not go past it; ORDER: the smallest
## left); -1 when none.
func hint() -> int:
	var c := current()
	if c.is_empty() or _solved:
		return -1
	if str(c.kind) == "make":
		var gap := int(c.target) - total
		var best := -1
		var gems: Array = c.gems
		for i in gems.size():
			var v := int(gems[i])
			if v != 0 and signi(v) == signi(gap) and absi(v) <= absi(gap) and (best == -1 or absi(v) > absi(int(gems[best]))):
				best = i
		return best
	var values: Array = c.values
	var small := -1
	for i in values.size():
		if not taken.has(i) and (small == -1 or float(values[i]) < float(values[small])):
			small = i
	return small


## The helpful gem once the child has missed HINT_AFTER times in this challenge, else -1.
func shown_hint() -> int:
	return hint() if misses >= HINT_AFTER else -1


func _begin() -> void:
	var c := current()
	total = int(c.get("start", 0))
	taken.clear()
	misses = 0
	_solved = false


func _take_make(c: Dictionary, i: int) -> StringName:
	var gems: Array = c.gems
	if i < 0 or i >= gems.size():
		return BOUNCED
	var target := int(c.target)
	var after := total + int(gems[i])
	var farther := absi(target - after) >= absi(target - total)
	var past := not bool(c.get("signed", false)) and signi(target - after) != signi(target - total) and after != target
	if farther or past:
		misses += 1
		return BOUNCED
	total = after
	if total == target:
		return _solve()
	return TAKEN


func _take_order(c: Dictionary, i: int) -> StringName:
	var values: Array = c.values
	if i < 0 or i >= values.size() or taken.has(i) or i != hint():
		misses += 1
		return BOUNCED
	taken.append(i)
	if taken.size() == values.size():
		return _solve()
	return TAKEN


func _solve() -> StringName:
	_solved = true
	if misses == 0:
		first_try += 1
	return MADE
