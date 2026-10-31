class_name AmbienceSoundRules
extends RefCounted
## Which ambience loop plays where the player is (the audio pass, owner feedback #27; spec §15.2), as
## pure rules. choose(ctx) reads:
##   time        the time of day 0..1 (DayCycle)
##   underground Ambience's cave amount 0..1      underwater  Ambience's water amount 0..1
##   storm       a sandstorm's strength 0..1      height      the eyes' height above sea level (blocks)
##   sea         the share of the ground around that is open sea 0..1
##   own         the universe's own loops {"day": id, "night": id} (UniverseRegistry.ambience)
## Under water and in a sandstorm (it has its own wind) nothing plays; caves drip; high up it is windy;
## by the sea the waves wash; otherwise the universe's own loops, else birds by day and crickets at night.

const DIR := "res://assets/audio/ambience/"
## Loop -> its volume (dB) on the Effects bus: a quiet bed under the game.
const LOOPS := {&"birds": -8.0, &"crickets": -10.0, &"wind": -9.0, &"waves": -7.0, &"drips": -6.0,
	# M5 Task 2: Frostpeak's cold wind and snowy pine night, the Candy Kingdom's wind chimes and chocolate brook
	&"snow_wind": -8.0, &"snow_night": -10.0, &"chimes": -8.0, &"brook": -10.0}
const PEAK_HEIGHT := 36.0         # blocks above the sea: peaks and flying high are windy
const SEA_SHARE := 0.35           # this much open sea around: the waves
const CAVE := 0.5
const WATER := 0.5
const STORM := 0.3


static func path(id: StringName) -> String:
	return DIR + String(id) + ".ogg" if LOOPS.has(id) else ""


## A loop's volume: its own, evened out across the universes (M5 Task 2, Loudness: every universe's day ambience as
## loud as the birds, its night as loud as the crickets).
static func volume_db(id: StringName) -> float:
	return float(LOOPS.get(id, -80.0)) + (Loudness.ambience_gain_db(id) if LOOPS.has(id) else 0.0)


static func choose(ctx: Dictionary) -> StringName:
	if float(ctx.get("underwater", 0.0)) >= WATER or float(ctx.get("storm", 0.0)) >= STORM:
		return &""
	if float(ctx.get("underground", 0.0)) >= CAVE:
		return &"drips"
	if float(ctx.get("height", 0.0)) >= PEAK_HEIGHT:
		return &"wind"
	if float(ctx.get("sea", 0.0)) >= SEA_SHARE:
		return &"waves"
	var night := DayCycle.is_night(float(ctx.get("time", DayCycle.NOON)))
	var own: Variant = ctx.get("own", {})
	if own is Dictionary:
		var id := StringName(str((own as Dictionary).get("night" if night else "day", "")))
		if LOOPS.has(id):
			return id
	return &"crickets" if night else &"birds"
