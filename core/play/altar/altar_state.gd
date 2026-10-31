class_name AltarState
extends RefCounted
## Owner #133, #134 (docs/design/games/balance-altar.md §3.4, §3.5's rules table, §4.3; ported from the phase A model,
## docs/design/games/balance-altar/model/altar_rules.py): one balance altar's two pans. Pure, no nodes.
##
## A pan holds net amounts, so a gem and a balloon on one pan have already cancelled (the zero pair floats off as a move
## commits):
## - crystals `lc`, `rc`: positive are frozen crystals (each weighs the hidden `x`); negative are crystal balloons
##   (each lifts x: wing 7);
## - gems `lk`, `rk`: positive are gems (+1 each), negative are balloons (-1 each: the Sky Room).
## The altar holds (is level) when lc·x + lk = rc·x + rk. The crystal is freed when it stands alone on its pan (one
## crystal, nothing else) and the other pan holds no crystal: that pan then shows what the crystal weighs (a balloon
## there would be a floaty crystal, a negative answer: wing 7). Whole numbers in phase B (shards are phase C's).

const LEFT := 0
const RIGHT := 1
const GEM := "gem"
const BALLOON := "balloon"
const CRYSTAL := "crystal"
const CRYSTAL_BALLOON := "crystal_balloon"
const KINDS: Array[String] = [GEM, BALLOON, CRYSTAL, CRYSTAL_BALLOON]

var lc := 0
var lk := 0
var rc := 0
var rk := 0
## The crystal's weight in gems: the child never sees it until the crystal is freed.
var x := 0


static func make(left_crystals: int, left_gems: int, right_crystals: int, right_gems: int, weight: int) -> AltarState:
	var s := AltarState.new()
	s.lc = left_crystals
	s.lk = left_gems
	s.rc = right_crystals
	s.rk = right_gems
	s.x = weight
	return s


## Both pans weigh the same for the hidden weight.
func holds() -> bool:
	return lc * x + lk == rc * x + rk


## A pan's crystals (net: negative are crystal balloons).
func crystals(pan: int) -> int:
	return lc if pan == LEFT else rc


## A pan's gems (net: negative are balloons).
func gems(pan: int) -> int:
	return lk if pan == LEFT else rk


## How many of one kind a pan holds (gems, balloons, crystals or crystal balloons; never negative).
func amount(pan: int, kind: String) -> int:
	var c := crystals(pan)
	var k := gems(pan)
	match kind:
		GEM:
			return maxi(k, 0)
		BALLOON:
			return maxi(-k, 0)
		CRYSTAL:
			return maxi(c, 0)
		CRYSTAL_BALLOON:
			return maxi(-c, 0)
	return 0


## The crystal alone on its pan (one crystal, nothing else) and no crystal on the other pan.
func freed() -> bool:
	return (lc == 1 and lk == 0 and rc == 0) or (rc == 1 and rk == 0 and lc == 0)


## The pan the crystal is to be freed on: the only pan with crystals (or crystal balloons), else the one with more
## (the left on a tie).
func crystal_pan() -> int:
	if lc != 0 and rc == 0:
		return LEFT
	if rc != 0 and lc == 0:
		return RIGHT
	return LEFT if lc >= rc else RIGHT


## How far the crystal is from alone: extra crystals and loose things on its pan, crystals on the other pan.
func clutter() -> int:
	var side := crystal_pan()
	return absi(crystals(side) - 1) + absi(gems(side)) + absi(crystals(1 - side))


## What the other pan shows once the crystal is freed (its gems: the crystal's weight); -1 while it is not.
func shown_weight() -> int:
	if not freed():
		return -1
	return gems(1 - crystal_pan())


func copy() -> AltarState:
	return AltarState.make(lc, lk, rc, rk, x)


## The pans as one value (the solver's and the caches' key; the weight is left out: the moves don't depend on it).
func key() -> Vector4i:
	return Vector4i(lc, lk, rc, rk)


func same(other: AltarState) -> bool:
	return other != null and key() == other.key() and x == other.x


func _to_string() -> String:
	return "[%d, %d | %d, %d] x=%d" % [lc, lk, rc, rk, x]
