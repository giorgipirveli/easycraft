class_name AnimalChorusRules
extends RefCounted
## The animals' idle calls heard on one device, as pure rules (owner feedback #50, 2026-09-24: "please
## improve sounds, now there is a lot chicken sounds only everywhere"; docs/devlog/parts/owner-50-sounds.md).
## Before, every animal rolled its own 8-20 s timer, so the calls grew with the herd (20 chickens: ~90 a
## minute, nearly all clucks). Now one chorus per device (AnimalChorus) asks next_call() what to play:
## - one budget: at most one idle call every GAP_MIN..GAP_MAX seconds, whatever the number of animals;
## - a kind rests KIND_REST seconds after it called, and the kind heard least lately comes first, so one
##   kind never dominates (a lone flock calls every 20 s or so);
## - the nearest animals first (a kind's score loses DIST_COST per block; within the kind, nearer ones are
##   picked more); farther ones are rarer (call_chance) and quieter (volume_db); beyond RADIUS: never;
## - the loudest recordings are evened out (VoiceRules.call_gain_db: the chickens were 4-13 dB louder than
##   the others through a phone's speaker);
## - take(): a sound never plays the same take twice in a row (Audio uses it for every sound).
## A child's own animal voice (hurt when hit, happy when petted or fed) is never blocked: heard() only lets
## that kind rest and keeps the chorus quiet for AFTER_VOICE seconds after it.

const RADIUS := VoiceRules.CALL_RADIUS   # blocks from the listener (this device's camera)
const GAP_MIN := 6.0              # seconds between two idle calls heard on a device
const GAP_MAX := 10.0
const KIND_REST := 20.0           # a kind that called waits this long
const RETRY := 1.0                # nobody near (or every kind near resting): look again after this
const NEAR := 6.0                 # blocks: this close, a full voice and it always calls
const FAR_CHANCE := 0.35          # at RADIUS a chosen animal calls only this often (it rolls again later)
const BASE_DB := -4.0             # an idle call's volume nearby (Audio adds the distance fall-off)
const FAR_DB := -6.0              # and this much quieter at RADIUS
const AGE_CAP := 60.0             # seconds: "not heard for a long time" counts no more than this
const DIST_COST := 1.5            # seconds of "not heard lately" that one block of distance is worth
const AFTER_VOICE := 3.0          # a child's own animal voice keeps the chorus quiet this long

var _next := 0.0                  # the chorus clock's time of the next idle call
var _heard := {}                  # kind -> when it was last heard


## Which of `candidates` ({kind: species, dist: blocks from the listener}) calls at `now`: its index, or -1
## (not yet, nobody near, or a far one kept quiet). A call spends the budget and lets its kind rest.
func next_call(now: float, candidates: Array, rng: RandomNumberGenerator) -> int:
	if now < _next:
		return -1
	var pick := choose(candidates, now, rng)
	if pick < 0:
		_next = now + RETRY
		return -1
	_next = now + gap(rng)
	if rng.randf() >= call_chance(float(candidates[pick].dist)):
		return -1                 # a far animal kept quiet this time: farther ones are rarer
	_heard[candidates[pick].kind] = now
	return pick


## The pick, without the budget or the far roll: the kind with the best score (heard least lately, near),
## then one of its animals, nearer ones more often. -1 when every kind near is resting or nobody is near.
func choose(candidates: Array, now: float, rng: RandomNumberGenerator) -> int:
	var nearest := {}
	for c: Dictionary in candidates:
		var d := float(c.dist)
		if d <= RADIUS and VoiceRules.animal_call(c.kind) != &"" and now - last_heard(c.kind) >= KIND_REST:
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


## A voice of `kind` was heard at `now` that the chorus did not choose (a child's own: hurt or happy). It
## was not blocked; its kind rests and the chorus keeps quiet a moment.
func heard(kind: StringName, now: float) -> void:
	_heard[kind] = now
	_next = maxf(_next, now + AFTER_VOICE)


## When the chorus next looks for a call (the chorus clock).
func next_time() -> float:
	return _next


## When `kind` was last heard (-INF: never).
func last_heard(kind: StringName) -> float:
	return float(_heard.get(kind, -INF))


## How often a chosen animal `dist` blocks away really calls: always within NEAR, FAR_CHANCE at RADIUS,
## never beyond.
static func call_chance(dist: float) -> float:
	if dist > RADIUS:
		return 0.0
	return lerpf(1.0, FAR_CHANCE, clampf((dist - NEAR) / (RADIUS - NEAR), 0.0, 1.0))


## An idle call's volume (dB, before Audio's distance fall-off): quieter when far, and the kind's recordings
## evened out (VoiceRules.call_gain_db).
static func volume_db(kind: StringName, dist: float) -> float:
	return BASE_DB + FAR_DB * clampf((dist - NEAR) / (RADIUS - NEAR), 0.0, 1.0) + VoiceRules.call_gain_db(kind)


static func gap(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(GAP_MIN, GAP_MAX)


## Which of `count` takes plays, never `last` again (when there is another): Audio picks every sound's take
## with it.
static func take(count: int, last: int, rng: RandomNumberGenerator) -> int:
	if count <= 1:
		return 0
	if last < 0 or last >= count:
		return rng.randi_range(0, count - 1)
	var i := rng.randi_range(0, count - 2)
	return i + 1 if i >= last else i
