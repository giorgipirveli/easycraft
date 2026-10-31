class_name BotAsks
extends RefCounted
## What a bot friend remembers of what its child asks for (owner feedback #38, next to M2 Task 18's mind):
## how often each request came lately, fading by half every HALF_LIFE seconds of play. A child who often
## says "follow me" gets a friend that keeps closer (and "give me space" undoes it); a child who often
## asks for builds gets builds more often. Saved with the friend (WorldMeta.bots[i].mind.a), parsed
## defensively.

const HALF_LIFE := 600.0          # seconds of play
const MAX_CLOSER := 3.0           # blocks, at most, off the friend's comfortable distance
const CLOSER_PER_ASK := 0.75
const BUILD_PER_ASK := 0.08       # each recent build request: builds 8 % sooner
const MIN_BUILD_SHARE := 0.6      # at most 40 % sooner
const MAX_COUNT := 50.0
const SPACE_KEEPS := 0.25         # a "give me space" leaves this much of the follow requests
## The requests remembered (others are not worth keeping).
const KEPT: Array[StringName] = [BotIntents.FOLLOW, BotIntents.SPACE, BotIntents.BUILD, BotIntents.TREASURE,
	BotIntents.FIGHT, BotIntents.DANCE, BotIntents.WAIT, BotIntents.HELP]

var counts := {}                  # intent -> weight at `_at`
var _at := 0.0


## The child asked for `intent` at time `now` (the friend's clock, seconds).
func note(intent: StringName, now: float) -> void:
	if not KEPT.has(intent):
		return
	_fade(now)
	counts[intent] = minf(float(counts.get(intent, 0.0)) + 1.0, MAX_COUNT)
	if intent == BotIntents.SPACE and counts.has(BotIntents.FOLLOW):
		counts[BotIntents.FOLLOW] = float(counts[BotIntents.FOLLOW]) * SPACE_KEEPS   # "give me space" undoes clinging


## How often `intent` was asked lately (faded to `now`).
func count(intent: StringName, now: float) -> float:
	return float(counts.get(intent, 0.0)) * _decay(now - _at)


## Blocks closer than its comfortable distance (0..MAX_CLOSER): asked to follow often, and not for space.
func closeness(now: float) -> float:
	return clampf((count(BotIntents.FOLLOW, now) - count(BotIntents.SPACE, now)) * CLOSER_PER_ASK, 0.0, MAX_CLOSER)


## How often a builder builds on its own (`base` seconds), sooner when its child asks for builds.
func build_every(base: float, now: float) -> float:
	return base * clampf(1.0 - BUILD_PER_ASK * count(BotIntents.BUILD, now), MIN_BUILD_SHARE, 1.0)


## What it remembers at time `now` (its clock; -1: as of the last request).
func to_save(now: float = -1.0) -> Dictionary:
	var c := {}
	var fade := _decay(now - _at) if now >= 0.0 else 1.0
	for k: StringName in counts:
		var v := float(counts[k]) * fade
		if v >= 0.05:
			c[String(k)] = snappedf(v, 0.01)
	return {"c": c}


## A saved memory, as of time `now` on the friend's clock.
static func from_save(d: Variant, now: float = 0.0) -> BotAsks:
	var a := BotAsks.new()
	a._at = now
	if not d is Dictionary or not (d as Dictionary).get("c") is Dictionary:
		return a
	var c: Dictionary = d.c
	for k: Variant in c:
		var intent := StringName(str(k))
		var v: Variant = c[k]
		if KEPT.has(intent) and typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)):
			a.counts[intent] = clampf(float(v), 0.0, MAX_COUNT)
	return a


func _fade(now: float) -> void:
	var k := _decay(now - _at)
	for key: StringName in counts.keys():
		counts[key] = float(counts[key]) * k
	_at = now


static func _decay(dt: float) -> float:
	return pow(0.5, maxf(dt, 0.0) / HALF_LIFE)
