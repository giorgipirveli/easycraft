class_name MonsterChorusRules
extends RefCounted
## The monsters' idle voices heard on one device, as pure rules (M5 Task 2, spec §15.2; the M5 plan's note after
## owner feedback #50's animal chorus). Before, every monster rolled its own 6-14 s timer, so a night of 20 goblins
## round a child was about 120 grunts a minute. Now one chorus per device (MonsterChorus) asks next_call():
## - one budget: at most one idle voice every GAP_MIN..GAP_MAX seconds, however many monsters are near;
## - a kind rests KIND_REST seconds after it spoke and the kind heard least lately comes first (a lone pack of
##   goblins: a grunt every 12-13 s);
## - the nearest first (a kind's score loses DIST_COST per block; within the kind, nearer ones are picked more),
##   farther ones rarer (call_chance) and quieter (volume_db), nothing beyond RADIUS;
## - a hurt cry or the growl of a monster spotting a child is never held back: heard() lets that kind rest and
##   keeps the chorus quiet for AFTER_VOICE seconds.
## Monsters speak a little more often than #50's animals (4.5-7.5 s, a 12 s rest against 6-10 s and 20 s): at night
## their voices tell a child that something is near.

const RADIUS := 20.0              # blocks from the listener (Monster.SOUND_DISTANCE: as far as one was ever heard)
const GAP_MIN := 4.5              # seconds between two idle voices heard on a device
const GAP_MAX := 7.5
const KIND_REST := 12.0           # a kind that spoke waits this long
const RETRY := 1.0                # nobody near (or every kind near resting): look again after this
const NEAR := 6.0                 # blocks: this close, a full voice and it always speaks
const FAR_CHANCE := 0.4           # at RADIUS a chosen monster speaks only this often
const BASE_DB := -6.0             # an idle voice nearby (as the audio pass played them); Audio adds the fall-off
const FAR_DB := -5.0              # and this much quieter at RADIUS
const AGE_CAP := 40.0             # seconds: "not heard for a long time" counts no more than this
const DIST_COST := 1.5            # seconds of "not heard lately" one block of distance is worth
const AFTER_VOICE := 2.0          # a cry or a growl keeps the chorus quiet this long

var _next := 0.0
var _heard := {}                  # kind -> when it was last heard


## Which of `candidates` ({kind: MonsterRules kind, dist: blocks from the listener}) speaks at `now`: its index,
## or -1 (not yet, nobody near, or a far one kept quiet). A voice spends the budget and lets its kind rest.
func next_call(now: float, candidates: Array, rng: RandomNumberGenerator) -> int:
	if now < _next:
		return -1
	var pick := choose(candidates, now, rng)
	if pick < 0:
		_next = now + RETRY
		return -1
	_next = now + rng.randf_range(GAP_MIN, GAP_MAX)
	if rng.randf() >= call_chance(float(candidates[pick].dist)):
		return -1
	_heard[candidates[pick].kind] = now
	return pick


## The pick, without the budget or the far roll: the kind heard least lately (and near), then one of its monsters,
## nearer ones more often. -1 when every kind near is resting or nobody is near.
func choose(candidates: Array, now: float, rng: RandomNumberGenerator) -> int:
	var nearest := {}
	for c: Dictionary in candidates:
		var d := float(c.dist)
		if d <= RADIUS and now - last_heard(c.kind) >= KIND_REST:
			nearest[c.kind] = minf(float(nearest.get(c.kind, INF)), d)
	var best: StringName = &""
	var best_score := -INF
	for kind: StringName in nearest:
		var score := minf(now - last_heard(kind), AGE_CAP) - DIST_COST * float(nearest[kind])
		if score > best_score:
			best_score = score
			best = kind
	if best == &"":
		return -1
	var total := 0.0
	var weights: Array[float] = []
	for c: Dictionary in candidates:
		var w := 0.0
		if c.kind == best and float(c.dist) <= RADIUS:
			w = 1.0 / (1.0 + pow(float(c.dist) / NEAR, 2.0))
		weights.append(w)
		total += w
	var roll := rng.randf() * total
	for i in weights.size():
		roll -= weights[i]
		if weights[i] > 0.0 and roll <= 0.0:
			return i
	return weights.rfind(weights.max())


## A voice of `kind` was heard at `now` that the chorus did not choose (a cry, a growl on spotting a child): it
## was not held back; its kind rests and the chorus keeps quiet a moment.
func heard(kind: StringName, now: float) -> void:
	_heard[kind] = now
	_next = maxf(_next, now + AFTER_VOICE)


func next_time() -> float:
	return _next


func last_heard(kind: StringName) -> float:
	return float(_heard.get(kind, -INF))


## How often a chosen monster `dist` blocks away really speaks: always within NEAR, FAR_CHANCE at RADIUS, never
## beyond.
static func call_chance(dist: float) -> float:
	if dist > RADIUS:
		return 0.0
	return lerpf(1.0, FAR_CHANCE, clampf((dist - NEAR) / (RADIUS - NEAR), 0.0, 1.0))


## An idle voice's volume (dB, before Audio's distance fall-off): quieter when far, plus the kind's gain
## (VoiceRules.monster_gain_db: the recordings evened out through a phone speaker).
static func volume_db(kind: StringName, dist: float) -> float:
	return BASE_DB + FAR_DB * clampf((dist - NEAR) / (RADIUS - NEAR), 0.0, 1.0) + VoiceRules.monster_gain_db(kind)
