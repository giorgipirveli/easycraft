class_name ArenaRules
extends RefCounted
## Monster Wave's rules (owner feedback #44, spec §12.20), pure. Waves come one after another (FIRST_DELAY
## after arriving, then BREATHER after each is cleared); wave FINAL_WAVE is the raid boss. The run ends when
## every player is knocked out at once, and pays run_gold for the time survived and the waves cleared (more
## time, more gold; × 2^(u−1)). Every defeat pays its defeater a small kill bonus, Monster Hunter's combo (owner
## #33): 1 gold × 1, × 2, × 3 for defeats within COMBO_WINDOW seconds of each other. The kit is the same for
## everyone and fixed per universe. Each player's best time and wave are kept per universe (the arena world's
## WorldMeta.arena). Never random, never lost.

const FINAL_WAVE := 10
const FIRST_DELAY := 8.0
const BREATHER := 8.0
const SECONDS_PER_GOLD := 10.0
const GOLD_PER_WAVE := 5
const KILL_GOLD := 1
const COMBO_WINDOW := 5.0
const MAX_MULTIPLIER := 3
const MAX_PLAYERS := 16
const MAX_TIME := 359999.0   # 99:59:59: a saved best above it is broken
const READY_WORDS := "Get ready! The monsters are coming."
const BOSS_WORDS := "The raid boss is here!"
const STAY_WORD := "STAY"
const NEXT_WORD := "NEXT UNIVERSE"
const AGAIN_WORD := "PLAY AGAIN"
const LEAVE_WORD := "LEAVE"
const NO_BUILDING_WORDS := "No building in Monster Wave. Stay alive!"
const NO_FLYING_WORDS := "No flying in Monster Wave. Stay alive!"


static func is_boss_wave(n: int) -> bool:
	return n >= FINAL_WAVE


## Gold at the run's end: a gold for every SECONDS_PER_GOLD seconds survived and GOLD_PER_WAVE for every wave
## cleared, × 2^(u−1).
static func run_gold(seconds: float, waves_cleared: int, universe: int) -> int:
	var base := floori(maxf(seconds, 0.0) / SECONDS_PER_GOLD) + GOLD_PER_WAVE * maxi(waves_cleared, 0)
	return UniverseRules.gold(base, universe)


## The combo's multiplier after `count` defeats in a row.
static func multiplier(count: int) -> int:
	return clampi(count, 1, MAX_MULTIPLIER)


## One defeat's kill bonus: KILL_GOLD × the combo × 2^(u−1).
static func kill_gold(combo_count: int, universe: int) -> int:
	return UniverseRules.gold(KILL_GOLD * multiplier(combo_count), universe)


## "+4 × 2!" (just "+1" without a combo).
static func paid_line(gold: int, combo_count: int) -> String:
	var m := multiplier(combo_count)
	return "+%s" % GoldFormat.short(gold) if m <= 1 else "+%s × %d!" % [GoldFormat.short(gold), m]


## The HUD's line: the time survived and the wave ("3:24 · Wave 5", "1:01 · Raid boss!").
static func run_line(seconds: float, wave: int) -> String:
	var t := _clock(seconds)
	return Lang.t("%s · Raid boss!") % t if is_boss_wave(wave) else Lang.t("%s · Wave %d") % [t, maxi(wave, 1)]


## The line under it: the best of this universe's arena ("Best 3:10 · Wave 5", or "Your first run!").
static func best_line(record: Dictionary) -> String:
	var t := float(record.get("best_time", 0.0))
	var w := int(record.get("best_wave", 0))
	if t <= 0.0 and w <= 0:
		return "Your first run!"
	return Lang.t("Best %s · Wave %d") % [_clock(t), w]


## The result panel's line.
static func result_line(seconds: float, waves_cleared: int, gold: int) -> String:
	var t := _clock(seconds)
	if waves_cleared <= 0:
		return Lang.t("You lasted %s! +%s gold") % [t, GoldFormat.short(gold)]
	return Lang.t("You lasted %s and cleared %d wave%s! +%s gold") % [t, waves_cleared, Lang.plural_s(waves_cleared),
		GoldFormat.short(gold)]


static func _clock(seconds: float) -> String:
	var s := maxi(floori(seconds), 0)
	return "%d:%02d" % [s / 60, s % 60] if s < 3600 else "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]


# --- The best per universe --------------------------------------------------------------------------------

static func new_record() -> Dictionary:
	return {"best_time": 0.0, "best_wave": 0}


## A run of `seconds` that cleared `waves` waves: raises the best time and the best wave. True when either rose.
static func better(r: Dictionary, seconds: float, waves: int) -> bool:
	var rose := false
	if seconds > float(r.best_time):
		r.best_time = minf(seconds, MAX_TIME)
		rose = true
	if waves > int(r.best_wave):
		r.best_wave = mini(waves, FINAL_WAVE)
		rose = true
	return rose


static func clean(v: Variant) -> Dictionary:
	var r := new_record()
	if not v is Dictionary:
		return r
	var t: Variant = (v as Dictionary).get("best_time")
	var w: Variant = (v as Dictionary).get("best_wave")
	if typeof(t) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(t)):
		r.best_time = clampf(float(t), 0.0, MAX_TIME)
	if typeof(w) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(w)):
		r.best_wave = int(clampf(float(w), 0.0, FINAL_WAVE))
	return r


## Every player's best, {name: record}; broken entries and empty names dropped, at most MAX_PLAYERS.
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


# --- The kit ----------------------------------------------------------------------------------------------

const KIT_KINDS: Array[int] = [ItemIds.SWORD, ItemIds.BOW, ItemIds.SPEAR, ItemIds.MACE, ItemIds.SHIELD_WOOD]
const KIT_POTIONS := {ItemIds.POTION_SPEED: 2, ItemIds.POTION_JUMP: 2}


## The universe's tier for the kit (WeaponRules.TIERS: 1 stone, 2 iron, 3 crystal, 4 cosmic).
static func kit_tier(universe: int) -> int:
	return clampi(universe, 1, WeaponRules.TIER_NAMES.size() - 1)


## Everyone's kit in universe u's arena: a sword, a bow, a spear, a mace and a shield of its tier, and potions.
static func kit(universe: int) -> Inventory:
	var inv := Inventory.new()
	for kind in KIT_KINDS:
		inv.add(WeaponRules.TIERS[kind][kit_tier(universe)], 1)
	for id: int in KIT_POTIONS:
		inv.add(id, KIT_POTIONS[id])
	return inv


## The kit's hotbar: the five weapons, the two potions, then the sword and the bow again.
static func kit_hotbar(universe: int) -> Array[int]:
	var t := kit_tier(universe)
	var bar: Array[int] = []
	for kind in KIT_KINDS:
		bar.append(WeaponRules.TIERS[kind][t])
	for id: int in KIT_POTIONS:
		bar.append(id)
	bar.append(WeaponRules.TIERS[ItemIds.SWORD][t])
	bar.append(WeaponRules.TIERS[ItemIds.BOW][t])
	return bar


## One player's combo: defeat(now) counts a defeat at `now` seconds and returns the count so far.
class Combo:
	extends RefCounted

	var count := 0
	var last := -INF

	func defeat(now: float) -> int:
		count = count + 1 if count > 0 and now - last <= COMBO_WINDOW else 1
		last = now
		return count

	func reset() -> void:
		count = 0
		last = -INF
