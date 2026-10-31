class_name JumpTaps
extends RefCounted
## Taps on JUMP (owner feedback #54, 2026-09-28, and #75, 2026-09-29: "when i click on jump several times i should start
## fliying and going up not only down"; spec §3b). A row of taps goes on while each tap comes within DOUBLE_TAP_TIME of
## the one before. The row takes off flying at once on its `needed()`-th tap: the second where flying is free (the
## Sandbox), the third where it costs gold (Survivor, whose double jump stays two taps), if every tap of the row was
## made where taps count (counts()). Flying, each further tap lifts the player (TAP_LIFT, the player's part). One tap
## and slow taps never take off. The touch button and Space press the same action, so both work alike. Call tap() on
## every JUMP press and tick() once a physics frame, in real time (not the Physics Lab's slow motion: a child's thumb).

const DOUBLE_TAP_TIME := 0.35   # s from one tap to the next that still belongs to the row (a child's thumb)
const TAKE_OFF_LIFT := 0.45     # s of UP when the taps take off: a clear rise, then hovering
const TAP_LIFT := 0.3           # s of UP for each tap on JUMP while flying: tapping on keeps going up
const MAX_LIFT := 2.0           # s of UP at most, however fast the taps come

## Taps in the current row.
var taps := 0
var _since := INF        # s since the row's last tap
var _spoiled := false    # a tap of this row came where taps do not count


## A press on JUMP; `counts`: may taps take off here now (counts()); `need`: the row's tap that takes off (needed()).
## True when this tap takes off.
func tap(counts: bool = true, need: int = 2) -> bool:
	if _since > DOUBLE_TAP_TIME:
		taps = 0
		_spoiled = false
	taps += 1
	_spoiled = _spoiled or not counts
	_since = 0.0
	return taps == need and not _spoiled


## One physics frame.
func tick(delta: float) -> void:
	_since += delta


func reset() -> void:
	taps = 0
	_since = INF
	_spoiled = false


## The quick taps that take off: two where flying is free (the Sandbox), three where it costs gold (Survivor: two taps
## are its double jump, and a child should mean it before gold is spent).
static func needed(free_fly: bool) -> int:
	return 2 if free_fly else 3


## Taps take off only where flying is allowed (not Monster Wave: there the taps are the jumps, then the glider) and
## only a walking body (not flying already, a ghost or zero-G), not swimming (JUMP swims up) and with no gadget moving
## it (the glider keeps its taps; on a zipline JUMP lets go).
static func counts(fly_allowed: bool, walking: bool, water_state: int, gadget_move: int) -> bool:
	return fly_allowed and walking and water_state < SwimRules.State.SWIMMING and gadget_move == GadgetRules.Move.NONE
