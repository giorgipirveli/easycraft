class_name CrewCall
extends RefCounted
## Crew flights (spec §21d.6 phase 2): the pilot's call to the friends in its world, as a pure state machine. LAUNCH
## with friends here calls them all (their card: "Anna is launching to the Moon! Take your seat." with TAKE MY SEAT and
## STAY HERE, and CrewFlightRules.CALL_SECONDS on the clock). When everyone answered, the time is up or the pilot
## pressed LAUNCH NOW, the takers (in the order they answered, then the ones who never answered: ruling 2) fly if the
## rocket carries them all (CrewFlightRules.room: seats, air and water); else the pilot CHOOSES: fly with the ones who
## fit (the first to take a seat) or wait and add crew capsules (CANCELLED). Everyone called who does not fly is left
## behind: their world flies away with the pilot. A friend who leaves meanwhile is not waited for; one who arrives
## meanwhile is called too. Times are the caller's (seconds).

const CALLING := &"calling"
const CHOOSING := &"choosing"
const GO := &"go"
const CANCELLED := &"cancelled"

var state: StringName = CALLING
## RocketCheck.description of the rocket (its seats and supplies decide the room).
var rocket := {}
## Friends called (peer ids), in the order they were called.
var friends: Array[int] = []

var _answers := {}                 # peer -> true (a seat) / false (stays)
var _order: Array[int] = []        # takers in the order they answered
var _ends := 0.0
var _now_please := false
var _over := false                 # the countdown is over (everyone answered, the time is up or LAUNCH NOW)
var _room := 0
var _flying: Array[int] = []


func _init(p_friends: Array[int], p_rocket: Dictionary, now: float) -> void:
	friends = p_friends.duplicate()
	rocket = p_rocket
	_ends = now + CrewFlightRules.CALL_SECONDS


## A friend's answer (true: TAKE MY SEAT). True when it counts: a friend called, the first answer, while calling.
func answer(peer: int, take: bool) -> bool:
	if state != CALLING or not friends.has(peer) or _answers.has(peer):
		return false
	_answers[peer] = take
	if take:
		_order.append(peer)
	return true


## A friend left the world meanwhile: nobody waits for them, nothing is said to them.
func gone(peer: int) -> void:
	friends.erase(peer)
	_answers.erase(peer)
	_order.erase(peer)
	_flying.erase(peer)


## A friend arrived meanwhile: called too (with the time left).
func add(peer: int) -> void:
	if state == CALLING and not friends.has(peer):
		friends.append(peer)


func seconds_left(now: float) -> float:
	return maxf(_ends - now, 0.0)


## LAUNCH NOW: the pilot decides at once (whoever has not answered counts as ruling 2 says).
func launch_now() -> void:
	_now_please = true


## NOT YET: the call ends, nobody flies.
func cancel() -> void:
	state = CANCELLED
	_flying.clear()


## The call's state after time `now`: CALLING until everyone answered, the time is up or LAUNCH NOW; then GO when the
## rocket carries every taker, else CHOOSING (the pilot's choice).
func tick(now: float) -> StringName:
	if state != CALLING:
		return state
	var all_answered := true
	for f in friends:
		all_answered = all_answered and _answers.has(f)
	if not (all_answered or now >= _ends or _now_please):
		return state
	_over = true
	var wanting := takers()
	_room = CrewFlightRules.room(rocket, wanting.size())
	if _room >= wanting.size():
		_flying = wanting
		state = GO
	else:
		state = CHOOSING
	return state


## The pilot's choice when not everyone fits: fly with the first `room()` takers (true), or wait (false).
func choose(fly: bool) -> void:
	if state != CHOOSING:
		return
	if fly:
		_flying = takers().slice(0, _room)
		state = GO
	else:
		cancel()


## Who wants to fly: took a seat (in the order they answered), then, when the call is over, whoever never answered
## (ruling 2: CrewFlightRules.UNANSWERED_TAKES).
func takers() -> Array[int]:
	var out := _order.duplicate()
	if CrewFlightRules.UNANSWERED_TAKES and _over:
		for f in friends:
			if not _answers.has(f) and not out.has(f):
				out.append(f)
	return out


## How many friends the rocket carries (once decided).
func room() -> int:
	return _room


## The kind words when not everyone fits ("" when they do).
func words() -> String:
	return CrewFlightRules.short_words(rocket, takers().size()) if state == CHOOSING else ""


## Who flies (GO): the pilot's crew, in their seats' order.
func crew() -> Array[int]:
	return _flying.duplicate() if state == GO else [] as Array[int]


## Everyone called who does not fly when the rocket goes (GO); nobody when the launch waits.
func left_behind() -> Array[int]:
	var out: Array[int] = []
	if state != GO:
		return out
	for f in friends:
		if not _flying.has(f):
			out.append(f)
	return out


## The friend chose STAY HERE (not: the rocket was full).
func stayed(peer: int) -> bool:
	return _answers.has(peer) and not bool(_answers[peer])


## A taker's seat (the pilot sits in 0), -1 for none.
func seat_of(peer: int) -> int:
	var i := _order.find(peer)
	if state == GO:
		i = _flying.find(peer)
	return i + 1 if i >= 0 else -1


func answered(peer: int) -> bool:
	return _answers.has(peer)
