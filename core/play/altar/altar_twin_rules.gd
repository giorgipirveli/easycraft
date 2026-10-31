class_name AltarTwinRules
extends RefCounted
## Owner #133, #134 (docs/design/games/balance-altar.md §4.4 "VR", ruling 23): the twin move with two hands in a headset
## (Cook, Mitchell & Goldin-Meadow's two-hand "equalizer" gesture [C7]): a grip near a pan lifts what is under that hand
## (an open hand over a pile scoops what it covers); while one hand holds a lift from one pan, the other hand's grip on
## the other pan takes its twin, and both are one twin move; a held thing let go over its own pan goes back (free), over
## the other pan it was carried across (refused). One-handed (a comfort setting, or one controller): a trigger on a thing
## lifts it, a trigger on its twin completes it: the altar's own waiting batch (AltarMoves). Pure geometry, in the
## altar's space (metres); B2's altar claims the grips (VrGrabber.claimers) and feeds these.

## A hand is over a pan within this of its middle (across), from just under its rim to this high above it.
const PAN_REACH := 0.22
const ABOVE := 0.3
const BELOW := 0.06
## An open hand scoops the things within this of its palm.
const SCOOP := 0.09
## Two hands' grips this close in time are one twin move.
const TOGETHER := 1.2
## What letting go does.
const BACK := "back"
const ACROSS := "across"


## The pan under a hand (an index of `pans`, their middles), or -1.
static func pan_under(hand: Vector3, pans: Array[Vector3]) -> int:
	var best := -1
	var best_d := INF
	for i in pans.size():
		var p := pans[i]
		var up := hand.y - p.y
		var across := Vector2(hand.x - p.x, hand.z - p.z).length()
		if up >= -BELOW and up <= ABOVE and across <= PAN_REACH and across < best_d:
			best = i
			best_d = across
	return best


## How many things (their places) an open hand at `hand` scoops.
static func scoop(hand: Vector3, items: Array[Vector3], radius: float = SCOOP) -> int:
	var n := 0
	for p in items:
		if p.distance_to(hand) <= radius:
			n += 1
	return n


## Two hands' grips ({pan, kind, n, t}) as one twin move (a take), or {} when they are not a twin: the same kind and
## number on the two pans, close enough in time.
static func pair(a: Dictionary, b: Dictionary) -> Dictionary:
	if int(a.pan) == int(b.pan) or str(a.kind) != str(b.kind) or int(a.n) != int(b.n) or int(a.n) < 1:
		return {}
	if absf(float(a.t) - float(b.t)) > TOGETHER:
		return {}
	return AltarMoves.take(str(a.kind), int(a.n))


## A held thing (lifted from `from_pan`) let go at `hand`: BACK over its own pan or anywhere else, ACROSS over the other.
static func release(hand: Vector3, pans: Array[Vector3], from_pan: int) -> String:
	var under := pan_under(hand, pans)
	return ACROSS if under >= 0 and under != from_pan else BACK


## One-handed play: a trigger on a thing on a pan is the altar's own lift (a trigger on its twin completes the move).
static func trigger(moves: AltarMoves, pan: int, kind: String) -> Dictionary:
	return moves.lift(pan, kind)
