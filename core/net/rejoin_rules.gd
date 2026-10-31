class_name RejoinRules
extends RefCounted
## Getting back in after the internet drops (M4 Wave 1 A, spec §17.0). A guest whose link to the
## server is lost (the socket closed, or no word from the host for SILENCE seconds) tries to join the
## same world again: at once, then less and less often, for WINDOW seconds, while the game shows
## "The internet went away. Trying again…". Then it gives up and goes back to the menu. The host
## keeps an away guest's player in the world for the same WINDOW (Away).

const PLAYING := &"playing"
const REJOINING := &"rejoining"
const GAVE_UP := &"gave_up"
## Owner #92 (a friend joining "shut the server down"): 8 s of silence was shorter than a phone's or a browser's
## freeze while a world loads, so guests left working games and rejoined in a loop; the host now gets 15 s, and a
## guest's own frozen frames never count as the host's silence (frame()).
const WINDOW := 45.0
const SILENCE := 15.0
## A frame this long is the guest's own freeze: the time it took moves the last word on.
const FREEZE := 1.0
## Waits between tries (seconds after a failed try), then MAX_WAIT.
const WAITS: Array[float] = [1.0, 2.0, 3.0]
const MAX_WAIT := 5.0

var state: StringName = PLAYING
var tries := 0
var _lost_at := 0.0
var _next_try := 0.0
var _trying := false
var _heard_at := 0.0


## Anything arrived from the host.
func heard(now: float) -> void:
	_heard_at = now


## Every frame: a long one (the guest's own freeze) is not the host's silence.
func frame(now: float, delta: float) -> void:
	if delta >= FREEZE:
		_heard_at = minf(_heard_at + delta, now)


func silent_too_long(now: float) -> bool:
	return state == PLAYING and now - _heard_at > SILENCE


func lost(now: float) -> void:
	if state != PLAYING:
		return
	state = REJOINING
	_lost_at = now
	_next_try = now
	_trying = false
	tries = 0


func should_try(now: float) -> bool:
	return state == REJOINING and not _trying and now >= _next_try and now < _lost_at + WINDOW


func trying(_now: float) -> void:
	_trying = true
	tries += 1


func failed(now: float) -> void:
	_trying = false
	_next_try = now + (WAITS[tries - 1] if tries - 1 < WAITS.size() else MAX_WAIT)


func joined() -> void:
	state = PLAYING
	_trying = false


func seconds_left(now: float) -> float:
	return maxf(_lost_at + WINDOW - now, 0.0) if state == REJOINING else 0.0


## The state after the clock moved on: REJOINING turns to GAVE_UP when the window is over.
func tick(now: float) -> StringName:
	if state == REJOINING and now >= _lost_at + WINDOW:
		state = GAVE_UP
		_trying = false
	return state


## Host: guests whose link dropped, kept (their player stays in the world) until back or WINDOW ends.
class Away:
	extends RefCounted

	var _until := {}   # peer -> seconds

	func went(peer: int, now: float) -> void:
		_until[peer] = now + RejoinRules.WINDOW

	func has(peer: int) -> bool:
		return _until.has(peer)

	## True (once) when an away guest came back in time.
	func back(peer: int) -> bool:
		return _until.erase(peer)

	## The guests whose time ran out (and forgets them).
	func expired(now: float) -> Array[int]:
		var out: Array[int] = []
		for peer: int in _until.keys():
			if now >= float(_until[peer]):
				out.append(peer)
				_until.erase(peer)
		return out

	func peers() -> Array:
		return _until.keys()
