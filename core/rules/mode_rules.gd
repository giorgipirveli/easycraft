class_name ModeRules
extends RefCounted
## What each game mode allows (M2 spec §12.1, §12.15). Sandbox: everything unlimited, and gentle night
## monsters (a knock-out costs nothing). Survivor: blocks and items are counted, gold is earned, nights
## bring real monsters, a knock-out drops your blocks, and cheats (Ghost, free flying, cheat commands)
## are off. Monster Wave (owner feedback #44, spec §12.20): hearts and the Totem's waves in a flat arena, real gold,
## nothing to build, no flying, no night monsters; a knock-out ends the run (ArenaDirector), no bags.

const SANDBOX := &"sandbox"
const SURVIVOR := &"survivor"
const WAVE := &"wave"                          # Monster Wave (owner feedback #44, spec §12.20)
const MODES: Array[StringName] = [SANDBOX, SURVIVOR, WAVE]

const GHOST := &"ghost"                        # Ghost mode (fly through blocks)
const FREE_FLY := &"free_fly"                  # flying costs nothing (Survivor: gold per minute)
const UNLIMITED_BLOCKS := &"unlimited_blocks"  # every block and item, never counted
const CHEATS := &"cheats"                      # /tp /give /time … (ChatCommands.CHEATS)
const INFINITE_GOLD := &"infinite_gold"        # the HUD shows ∞; nothing is earned or spent
const DAMAGE := &"damage"                      # players have hearts and can be knocked out
const LOSSES := &"losses"                      # a knock-out drops blocks and respawns at the bed
const MONSTER_SPAWNS := &"monster_spawns"      # monsters come by themselves at night
const GENTLE_MONSTERS := &"gentle_monsters"    # fewer, weaker monsters, no gold (Sandbox, §12.15)
const PHYSICS_LAB := &"physics_lab"            # the LAB button: Moon, Zero-G, Slow motion (M3 §14.3)
const BUILDING := &"building"                  # placing and breaking blocks (spec §12.20: not in the arena)
const FLYING := &"flying"                      # FLY at all (Survivor pays for it; not in the arena)
const TOTEM := &"totem"                        # the Monster Totem's waves (owner #44: no longer in Survivor)

const _ALLOWED := {
	SANDBOX: [GHOST, FREE_FLY, UNLIMITED_BLOCKS, CHEATS, INFINITE_GOLD, DAMAGE, MONSTER_SPAWNS, GENTLE_MONSTERS,
		PHYSICS_LAB, BUILDING, FLYING, TOTEM],
	SURVIVOR: [DAMAGE, LOSSES, MONSTER_SPAWNS, BUILDING, FLYING],
	WAVE: [DAMAGE, TOTEM],
}
const _SLOTS := {SANDBOX: "sandbox_1", SURVIVOR: "survivor_1", WAVE: "wave_1"}


static func valid(mode: StringName) -> StringName:
	return mode if MODES.has(mode) else SANDBOX


static func allows(mode: StringName, rule: StringName) -> bool:
	return (_ALLOWED[valid(mode)] as Array).has(rule)


## The world save slot of a mode (each mode keeps its own world); Survivor has one world per universe
## (M3 Task 5: UniverseRules.slot, universe 1 keeps "survivor_1"), Sandbox one world.
static func slot(mode: StringName, universe: int = 1) -> String:
	if valid(mode) == SURVIVOR:
		return UniverseRules.slot(universe)
	if valid(mode) == WAVE:
		return "wave_%d" % UniverseRules.valid(universe)   # one arena per universe (spec §12.20)
	return "sandbox_%d" % UniverseRules.valid(universe)   # owner 39: a Sandbox world per universe (1 = M1's)


## Owner 39: the universe a world of `mode` is played in (every mode keeps it: Survivor's worlds, Monster Wave's
## arenas and Sandbox's worlds are per universe).
static func world_universe(_mode: StringName, universe: int) -> int:
	return UniverseRules.valid(universe)
