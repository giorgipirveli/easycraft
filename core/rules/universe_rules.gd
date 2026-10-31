class_name UniverseRules
extends RefCounted
## The universe ladder as pure rules (M3 spec §14.1, §5.1; M3 Task 5). Universe 1 is Green Meadows
## (M1–M2); each later Survivor universe is its own world, opened by beating the boss of the one before
## (its portal leads there) and listed in the portal hub once unlocked. A universe whose descriptor file
## doesn't exist yet (UniverseRegistry) is "coming soon". Gold, monster health and hits and Tilly's
## prices are multiplied by 2^(u−1) in universe u.

const FIRST := 1
const MAX_UNIVERSE := 60          # the ladder (1-15), space (16-40, SpaceRules) and Earth's own (41-60, EarthRules, owner #78);
                                  # only the ladder scales (at most 2^14)

const _TRAVEL_MESSAGES := {
	"locked": "Beat the boss to open this universe!",
	"coming_soon": "This universe is coming soon!",
	"friends": "Travel works when you play alone.",
	"here": "You are here!",
}


## 1 for anything that isn't a universe number (0, negative); at most MAX_UNIVERSE.
static func valid(u: int) -> int:
	return clampi(u, FIRST, MAX_UNIVERSE)


## 2^(u−1): 1, 2, 4, 8 for universes 1–4.
static func scale(u: int) -> int:
	return 1 << (valid(SpaceRules.scaling(u)) - 1)   # owner #55: a space world is never scaled


## Owner 39: the universe whose scale applies in a world of `mode` played in universe u: Sandbox never scales
## (everything free, gentle monsters), every other mode is its universe's.
static func scale_universe(mode: StringName, u: int) -> int:
	return FIRST if ModeRules.valid(mode) == ModeRules.SANDBOX else valid(u)


static func gold(base: int, u: int) -> int:
	return maxi(base, 0) * scale(u)


static func monster_hp(base: int, u: int) -> int:
	return maxi(base, 0) * scale(u)


static func monster_hit(base: int, u: int) -> int:
	return maxi(base, 0) * scale(u)


## Tilly's price for something that costs `base` in Green Meadows (buying and selling alike, so buying
## never costs less than selling pays in any universe).
static func price(base: int, u: int) -> int:
	return maxi(base, 0) * scale(u)


## A Survivor universe's save slot: universe 1 keeps M2's "survivor_1" (old saves keep working).
static func slot(u: int) -> String:
	var v := valid(u)
	return "survivor_1" if v == FIRST else "survivor_u%d" % v


static func next_universe(u: int) -> int:
	return valid(u) + 1


# --- M3 Task 4: after the last universe --------------------------------------------------------------------

## A boss portal's target that is not a universe: the portal hub (every universe the child opened). The last
## universe of the ladder (the Candy Kingdom) opens one of these when its boss is beaten.
const HUB := 0
const HUB_WORDS := "Walk in: every universe you opened!"


## Where the boss portal of universe u leads: the next universe, or the hub after the last one of the ladder.
static func boss_portal_target(u: int, ladder_size: int) -> int:
	return HUB if valid(u) >= ladder_size else next_universe(u)


## The profile's highest universe after beating the boss of universe `beaten_in`: never lowered.
static func unlocked_after_boss(unlocked: int, beaten_in: int) -> int:
	return maxi(valid(unlocked), next_universe(beaten_in))


## Where the boss portal of universe u leads: the next universe when its descriptor exists, else 0
## (coming soon). `available`: the universes whose descriptor files exist (UniverseRegistry.available()).
static func portal_target(u: int, available: Array[int]) -> int:
	var next := next_universe(u)
	return next if available.has(next) else 0


## The words over a boss portal to `target_name`: M2's words while that universe isn't here yet; in a
## Sandbox world the portal is only a peek (a Sandbox universe is reached through a portal the child builds: owner #39).
static func portal_words(target_name: String, open: bool, mode: StringName) -> String:
	if not open:
		return Lang.t("%s opens in the next update!") % target_name
	if ModeRules.allows(mode, ModeRules.CHEATS):
		return Lang.t("%s waits in Survivor!") % target_name
	return Lang.t("Walk in: %s!") % target_name


## The portal hub's list: every unlocked universe of the ladder (Green Meadows always), in order, each
## {universe, open}; open is false for one whose descriptor file doesn't exist yet (coming soon).
static func hub_entries(unlocked: int, ladder_size: int, available: Array[int]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u in range(FIRST, mini(valid(unlocked), maxi(ladder_size, FIRST)) + 1):
		out.append({"universe": u, "open": available.has(u)})
	return out


## The portal hub's stone circle stands in Survivor worlds (Sandbox universes are reached through built portals: owner #39).
static func wants_hub(mode: StringName) -> bool:
	return ModeRules.valid(mode) == ModeRules.SURVIVOR


## The SURVIVOR menu lists the universes once there is more than one to choose.
static func shows_hub(unlocked: int) -> bool:
	return valid(unlocked) > FIRST


## Why travelling from universe `here` to `to` can't happen ("" = it can): a key for travel_message.
## peers: other players in this game (friends can't be taken along yet).
static func travel_refusal(to: int, unlocked: int, available: Array[int], peers: int, here: int) -> String:
	if to < FIRST or to > valid(unlocked):
		return "locked"
	if not available.has(to):
		return "coming_soon"
	if to == here:
		return "here"
	if peers > 0:
		return "friends"
	return ""


static func travel_message(key: String) -> String:
	return _TRAVEL_MESSAGES.get(key, "")


## A sky colour of the day cycle (`look`) tinted toward the universe's (`own`): the full day is the
## universe's colour, the night stays the night's. daylight 0..1 (DayCycle.daylight).
static func sky_color(look: Color, own: Color, daylight: float) -> Color:
	return look.lerp(own, clampf(daylight, 0.0, 1.0))


# --- Travelling between universes ---------------------------------------------------------------------

## The world a child arrives in: `existing` (a world of universe u visited before), or a new Survivor
## world of universe u with the difficulty of the world they came from. Either way they arrive by the
## world spawn (and its stone circle), not where they last stood. A new world gives `key` (the player's
## name) M2's starter kit, like every new Survivor world (§12.1); the carried bag comes on top.
static func arrival_meta(existing: WorldMeta, u: int, difficulty: StringName, key: String = "") -> WorldMeta:
	var m := existing
	if m == null:
		m = WorldMeta.new_random()
		m.mode = ModeRules.SURVIVOR
		m.difficulty = KnockoutRules.valid_difficulty(difficulty)
		if key != "":
			m.inventories[key] = Inventory.starter_kit().to_save()
	m.universe = valid(u)
	m.player_pos = Vector3.INF
	return m


## Owner 39: the Sandbox world of universe u a child arrives in through a universe portal from universe `from`:
## `existing` (made before), or a new one; they arrive in front of its portal back to `from`, not where they last
## stood there.
static func sandbox_arrival_meta(existing: WorldMeta, u: int, from: int) -> WorldMeta:
	var m := existing
	if m == null:
		m = WorldMeta.new_random()
		m.mode = ModeRules.SANDBOX
	m.universe = valid(u)
	m.player_pos = Vector3.INF
	m.arrival_gate = from if CrystalRules.CORES.has(from) else 0
	return m


## Moves a child's bag (their live inventory, Inventory.to_save) and hotbar through a portal: everything
## is added to what waits for `key` in `to`; whatever doesn't fit (Inventory.MAX_COUNT each) stays behind
## in `from`, so nothing is ever copied or lost. Other players' bags are left alone.
static func carry(from: WorldMeta, to: WorldMeta, key: String, bag: Array, hotbar: Array[int], selected: int) -> void:
	var arrived := Inventory.from_save(to.inventories.get(key, []))
	var left := Inventory.new()
	for e: Array in Inventory.from_save(bag).to_save():
		var fitted := arrived.add(int(e[0]), int(e[1]))
		left.add(int(e[0]), int(e[1]) - fitted)
	to.inventories[key] = arrived.to_save()
	from.inventories[key] = left.to_save()
	to.hotbar = hotbar.duplicate()
	to.selected_slot = clampi(selected, 0, WorldMeta.HOTBAR_SIZE - 1)
