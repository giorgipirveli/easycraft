class_name GameScores
extends RefCounted
## Build to Survive's score (spec §12.18), one record per player name in a world (WorldMeta.game_scores,
## like inventories and homes): nights survived in a row without a knock-out, and the best. A score inside
## one world: nothing is lost by being away or playing something else (§6). (Monster Hunter's hunt and packs
## went with owner feedback #44; old keys are dropped when read.)
## Records are plain dictionaries; the functions change them in place.

const MAX_SCORE := 99999
const MAX_PLAYERS := 16
const _KEYS: Array[String] = ["nights", "best_nights"]


static func new_record() -> Dictionary:
	return {"nights": 0, "best_nights": 0}


## A night got through without a knock-out. True when it is a new best.
static func night_survived(r: Dictionary) -> bool:
	r.nights = mini(int(r.nights) + 1, MAX_SCORE)
	if r.nights > int(r.best_nights):
		r.best_nights = r.nights
		return true
	return false


## A knock-out in `game`: Build to Survive's run starts again (the best stays).
static func knocked_out(r: Dictionary, game: StringName) -> void:
	if SurvivorGames.valid(game) == SurvivorGames.BUILD:
		r.nights = 0


## A saved record read defensively: whole numbers 0..MAX_SCORE, a best never below its run.
static func clean(v: Variant) -> Dictionary:
	var r := new_record()
	if not v is Dictionary:
		return r
	var d: Dictionary = v
	for key in _KEYS:
		var n: Variant = d.get(key)
		if typeof(n) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(n)):
			r[key] = clampi(int(clampf(float(n), 0.0, MAX_SCORE)), 0, MAX_SCORE)
	r.best_nights = maxi(int(r.best_nights), int(r.nights))
	return r


## Every player's record, {name: record}; broken entries and empty names are dropped, at most MAX_PLAYERS.
static func clean_all(v: Variant) -> Dictionary:
	var out := {}
	if not v is Dictionary:
		return out
	for key: Variant in v:
		var n := str(key).substr(0, 32)
		if n == "" or not (v as Dictionary)[key] is Dictionary or out.size() >= MAX_PLAYERS:
			continue
		out[n] = clean((v as Dictionary)[key])
	return out
