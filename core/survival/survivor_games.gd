class_name SurvivorGames
extends RefCounted
## The game a Survivor world plays (owner feedback #33, spec §12.18), chosen after COZY / NORMAL / BRAVE
## when the world is made and saved with it (WorldMeta.game; older worlds are CLASSIC):
## - CLASSIC: today's Survivor.
## - BUILD: Build to Survive. Night comes fast (BuildRules' clock); a shelter (ShelterRules) keeps a
##   player safe; outside, nights are fiercer; nights survived are the score.
## (The first plan's third game, Monster Hunter, was folded into the MONSTER WAVE mode by owner feedback #44,
## spec §12.20; a world saved as "hunter" reads as CLASSIC.)
## Children are knocked out, never killed (§12.3). Pure rules: the host asks them, every game shows them.

const CLASSIC := &"classic"
const BUILD := &"build"
const CHOICES: Array[StringName] = [CLASSIC, BUILD]

const _LABELS := {CLASSIC: "CLASSIC", BUILD: "BUILD TO SURVIVE"}
const _ABOUT := {CLASSIC: "Explore, build and trade.", BUILD: "Night comes fast. Build a house!"}

## Build to Survive's quick start (on top of Inventory.starter_kit): planks, a doorway, a lantern.
const BUILD_KIT := {BlockIds.PLANKS: 32, BlockIds.DOOR: 2, BlockIds.LANTERN: 1}
## Build to Survive: more monsters per player outside at night (20 in all stays), a level higher.
const BUILD_PER_PLAYER := 14
const BUILD_LEVEL_BONUS := 1


static func valid(game: StringName) -> StringName:
	return game if CHOICES.has(game) else CLASSIC


static func label(game: StringName) -> String:
	return _LABELS[valid(game)]


## One short, kind line under the game's card.
static func about(game: StringName) -> String:
	return _ABOUT[valid(game)]


## A new world's kit in this game.
static func starter_kit(game: StringName) -> Inventory:
	var kit := Inventory.starter_kit()
	if valid(game) == BUILD:
		for id: int in BUILD_KIT:
			kit.add(id, BUILD_KIT[id])
	return kit


## A new world's hotbar in this game (`hotbar` stays as it is): Build to Survive puts its doorway and its
## lantern in the last two slots.
static func starter_hotbar(game: StringName, hotbar: Array[int]) -> Array[int]:
	var out: Array[int] = hotbar.duplicate()
	if valid(game) == BUILD and out.size() >= 2:
		out[out.size() - 2] = BlockIds.DOOR
		out[out.size() - 1] = BlockIds.LANTERN
	return out


## The time of day a new world of this game starts at.
static func new_world_time(game: StringName) -> float:
	return BuildRules.START_TIME if valid(game) == BUILD else DayCycle.START


## How many times faster than DayCycle's the clock runs at time of day t.
static func clock_speed(game: StringName, t: float) -> float:
	return BuildRules.speed(t) if valid(game) == BUILD else 1.0


## Night monsters per player (MonsterRules.MAX_PER_PLAYER, more in Build to Survive).
static func per_player_cap(game: StringName) -> int:
	return BUILD_PER_PLAYER if valid(game) == BUILD else MonsterRules.MAX_PER_PLAYER


static func level_bonus(game: StringName) -> int:
	return BUILD_LEVEL_BONUS if valid(game) == BUILD else 0


## A night monster's level in this game (at most MonsterRules.MAX_LEVEL).
static func night_level(level: int, game: StringName) -> int:
	return MonsterRules.level_of(level + level_bonus(game))
