class_name AnimIdle
extends RefCounted
## Owner #94 (the animations brief §1): a standing avatar's idle life, and what a child cheers for. Standing still for
## FIRST_AFTER seconds, a body glances round, stretches or thinks now and then (GAP apart; a sleepy yawn at night);
## when a friend (another player or a bot) walks up to it, it waves once. Every game plays these for every body it
## shows (Player._idle_tick), nothing is sent: two screens may see a different fidget, which nobody can tell. The
## happy reactions (Player.react_happy: a little jump and spin, EmotePoses "hooray") are the child's own and go to
## everyone like any emote.

const FIRST_AFTER := 7.0
const GAP := Vector2(8.0, 14.0)
## A friend this close (metres, flat) is near.
const FRIEND_NEAR := 5.0
const CHECK_EVERY := 0.5
const DAY_IDLES: Array[StringName] = [&"look", &"stretch", &"look", &"think"]
const NIGHT_IDLES: Array[StringName] = [&"yawn", &"look", &"yawn", &"stretch"]
## Progress kinds (LevelRules, before any "/<detail>") a child cheers for. Not blocks, monsters or exploring (too
## often), nor waves and bosses (Player.celebrate dances for them).
const CHEERS: Array[StringName] = [LevelRules.SECRET, LevelRules.QUEST_STEP, LevelRules.QUEST_DONE, LevelRules.GOAL,
	LevelRules.TAMED]
## Seconds after a rocket's landing (when the world shows) before the child cheers.
const ARRIVAL_DELAY := 0.8

## Set when a rocket lands (the sandbox): the local player cheers once it stands in the world it landed on.
static var cheer_on_arrival := false

## Seconds this body has stood still.
var still := 0.0
var _next := FIRST_AFTER
var _count := 0
var _friend_was_near := false


## One frame of a body: the idle emote it plays now, or &"". `standing`: not moving, on the floor, awake, dry, not
## riding or hiding (else the clock starts again); `free`: no emote or dance playing.
func step(delta: float, standing: bool, free: bool, night: bool, friend_near: bool) -> StringName:
	var arrived := friend_near and not _friend_was_near
	_friend_was_near = friend_near
	if not standing:
		still = 0.0
		_next = FIRST_AFTER
		return &""
	still += delta
	if not free:
		return &""
	if arrived:
		_next = maxf(_next, still + GAP.x)
		return &"wave"
	if still < _next:
		return &""
	_count += 1
	_next = still + lerpf(GAP.x, GAP.y, fposmod(_count * 0.618034, 1.0))
	return pick(night, _count)


static func pick(night: bool, n: int) -> StringName:
	var list := NIGHT_IDLES if night else DAY_IDLES
	return list[posmod(n - 1, list.size())]


## True for a Progress kind worth a happy jump.
static func cheers_for(kind: StringName) -> bool:
	return CHEERS.has(StringName(String(kind).get_slice("/", 0)))


## True at night by the world's clock (Animal.time_source, the sandbox's sky), else day.
static func is_night() -> bool:
	return Animal.time_source.is_valid() and DayCycle.is_night(float(Animal.time_source.call()))
