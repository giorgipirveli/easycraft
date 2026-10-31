class_name MonsterMinds
extends RefCounted
## The fair-fun guards around a world's monster minds (M2 Task 18 part 2, spec §12.17): how much they
## learn (normally; slowly with Sandbox's gentle monsters; never in Cozy worlds), easing off after a
## child's knock-outs (honest help: that child meets plain, straight-coming monsters and they stop
## learning from it until it fades), and the one-time hint that tells children what a species learned
## (once per world, saved). The host's sandbox sets `current` up with the world; pure code.

signal hint(text: String)

const GENTLE_LEARNING := 0.3      # Sandbox's gentle monsters learn this much of normal
const EASE_PER_KNOCKOUT := 0.5
const EASE_HALF_LIFE := 120.0     # seconds
const MAX_HINTS := 32
const LEARNED := 0.2              # a tactic's own score must have risen this much for its hint

## The world being played (the host's; tests make their own).
static var current := MonsterMinds.new()

var difficulty: StringName = DifficultyRules.NORMAL
var gentle := false               # Sandbox's gentle monsters (ModeRules.GENTLE_MONSTERS)
var hints_given: Array[String] = []
var _ease := {}                   # peer id -> 0..1


## How much a monster after the child `peer` learns (1 = normally; 0 = never).
func learning(peer: int) -> float:
	if KnockoutRules.valid_difficulty(difficulty) == DifficultyRules.COZY:
		return 0.0
	return (GENTLE_LEARNING if gentle else 1.0) * (1.0 - ease_of(peer))


## The tactics a monster may pick against the child `peer` (`mask`): in Cozy worlds, and (with the
## chance ease_of(peer), rolled as `roll` 0..1) after that child's knock-outs, only straight at you or backing off.
func restrict(mask: int, peer: int, roll: float) -> int:
	var plain := MonsterSpecies.bit(MonsterSpecies.STRAIGHT) | MonsterSpecies.bit(MonsterSpecies.BACK_OFF)
	if KnockoutRules.valid_difficulty(difficulty) == DifficultyRules.COZY:
		return mask & plain
	var e := ease_of(peer)
	if e > 0.0 and roll < e:
		return mask & (MonsterSpecies.bit(MonsterSpecies.STRAIGHT) if e >= 1.0 else plain)
	return mask


func ease_of(peer: int) -> float:
	return float(_ease.get(peer, 0.0))


## The child `peer` was knocked out: the monsters ease off.
func note_knockout(peer: int) -> void:
	_ease[peer] = minf(ease_of(peer) + EASE_PER_KNOCKOUT, 1.0)


## `dt` seconds pass: easing fades.
func tick(dt: float) -> void:
	var k := pow(0.5, dt / EASE_HALF_LIFE)
	for peer: int in _ease.keys():
		_ease[peer] = float(_ease[peer]) * k
		if _ease[peer] < 0.01:
			_ease.erase(peer)


## After a lesson of `kind`'s table `net`: the first time a tactic that worked became the species' first
## choice in the situation it is for, every child is told once (`hint`). At most one forward pass per
## tactic not told yet (lessons are rare: hits).
func check_hints(kind: StringName, net: TinyNet) -> void:
	var straight := MonsterSpecies.index(MonsterSpecies.STRAIGHT)
	for tactic in MonsterSpecies.ACTIONS:
		var key := "%s:%s" % [kind, tactic]
		if not MonsterSpecies.HINTS.has(key) or hints_given.has(key):
			continue
		var scores := net.forward(MonsterSpecies.hint_situation(tactic))
		var base := _default_scores(kind, tactic)
		var i := MonsterSpecies.index(tactic)
		# It learned it: the tactic itself worked (its score rose), it is now their first choice there,
		# and it wasn't at the start.
		if scores[i] - base[i] >= LEARNED and _best(scores) == i and _best(base) != i:
			hints_given.append(key)
			hint.emit(str(MonsterSpecies.HINTS[key]))
			return                       # one hint at a time


func load_hints(saved: Variant) -> void:
	hints_given = clean_hints(saved)


## Known hint keys only, each once, at most MAX_HINTS.
static func clean_hints(saved: Variant) -> Array[String]:
	var out: Array[String] = []
	if saved is Array:
		for v: Variant in saved:
			if v is String and MonsterSpecies.HINTS.has(v) and not out.has(v) and out.size() < MAX_HINTS:
				out.append(v)
	return out


static var _defaults := {}


static func _best(scores: PackedFloat32Array) -> int:
	var best := 0
	for i in scores.size():
		if scores[i] > scores[best]:
			best = i
	return best


## The untouched table's scores in a tactic's situation (to tell a learned preference from a default one).
static func _default_scores(kind: StringName, tactic: StringName) -> PackedFloat32Array:
	var key := "%s:%s" % [kind, tactic]
	if not _defaults.has(key):
		var table := MonsterSpecies.table(kind)
		var net := TinyNet.create(table.actions.size(), 0, table.hidden_defaults, table.output_defaults, 0.0)
		_defaults[key] = net.forward(MonsterSpecies.hint_situation(tactic))
	return _defaults[key]
