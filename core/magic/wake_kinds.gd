class_name WakeKinds
extends RefCounted
## The Magic Wand wakes more things (M3 Task 21c, spec §16 "wake more objects"), as pure rules. A build made of its
## own blocks comes alive with a personality of its own: a CACTUS (the desert's cacti: its hugs never prickle), a
## PUMPKIN (a pumpkin or jack-o-lantern, or a little scarecrow with a pumpkin head: it rolls as it hops; a
## jack-o-lantern glows orange) and a SNOWMAN (a snowman's head on top of snow blocks: Frostpeak's mouse holes have
## one by the door). Anything else wakes as an ordinary buddy. Task 20b's secret buddy shapes are recipes of their
## own (a snowman of snow blocks with an orange nose is one): a build needs these blocks to be one of these kinds.
## And an empty treasure chest wakes as a CHEST MIMIC: it hops after the child, giggles and gives a small present
## (once per chest; never gold, never treasure), then hops back to sleep. Never scary, never harmful: it has no
## body anyone bumps into and no way to hurt (TinyDirector, ChestMimic).

const NONE := &""
const CACTUS := &"cactus"
const PUMPKIN := &"pumpkin"
const SNOWMAN := &"snowman"

## Builds this small with a pumpkin on top are little scarecrows (bigger ones stay ordinary buddies).
const SCARECROW_MAX := 12
const PUMPKINS: Array[int] = [BlockIds.PUMPKIN, BlockIds.JACK_O_LANTERN]
const SNOWY: Array[int] = [BlockIds.SNOW, BlockIds.PACKED_SNOW, BlockIds.SNOW_BRICK, BlockIds.SNOWMAN_HEAD,
	BlockIds.PAINTED_WHITE]
const NAMES := {
	CACTUS: ["Prickles", "Spike", "Sunny", "Pokey", "Sandy", "Cacto"],
	PUMPKIN: ["Jack", "Patch", "Punky", "Gourdy", "Squash", "Pumpkin"],
	SNOWMAN: ["Frosty", "Flurry", "Chilly", "Snowball", "Button", "Carrot"],
}
const LINES := {
	CACTUS: "%s is awake! Its hugs never prickle.",
	PUMPKIN: "%s is awake! It loves to roll.",
	SNOWMAN: "%s is awake! Brrr, what a cool friend!",
}
## A jack-o-lantern buddy's glow.
const GLOW_COLOR := Color(1.0, 0.62, 0.25)

# --- The chest mimic ---
const MIMIC_HOPS := 6             # hops after the child before the present
const HOP_EVERY := 0.6            # seconds between hops
const HOP_STEP := 1.4             # blocks a hop goes, at most
const HOP_TIME := 0.42            # seconds in the air
const KEEP := 1.6                 # it stops this far from the child (sideways)
const MAX_CLIMB := 1.2            # never hops up or down more than this
const MAX_MIMICS := 3             # awake at once in a world
const PRESENT_TIME := 1.6         # the lid open, the present popping out
const MIMIC_WAKE := "The chest woke up! Hee hee!"
const MIMIC_PRESENT := "Surprise! A present from the chest! "
const MIMIC_AGAIN := "The chest is fast asleep. Zzz..."
const MIMIC_CLOSED := "Open it first! Then the wand can wake it."
const MIMIC_BUSY := "That chest is awake already!"
const MIMIC_SLEEPY := "The other chests are playing. Try again soon!"
## A mimic's small presents (one, fixed by the chest): never gold, never treasure (spec §6).
const PRESENTS: Array = [[BlockIds.PUMPKIN, 2], [BlockIds.JACK_O_LANTERN, 1], [ItemIds.POTION_JUMP, 1],
	[BlockIds.LANTERN, 2], [BlockIds.YELLOW, 4], [ItemIds.POTION_SPEED, 1], [BlockIds.BLUE, 4], [BlockIds.RED, 4]]


## The kind a woken build is (NONE: an ordinary buddy). blocks: {Vector3i offset: block id}.
static func kind_of(blocks: Dictionary) -> StringName:
	var n := 0
	var top := -0x7fffffff
	for p: Vector3i in blocks:
		if BlockIds.is_solid(int(blocks[p])):   # flowers and grass it stood among, taken along, don't count
			n += 1
			top = maxi(top, p.y)
	if n == 0:
		return NONE
	var top_ids := {}
	var snowy := 0
	var pumpkins := 0
	var cacti := 0
	for p: Vector3i in blocks:
		var id: int = blocks[p]
		if not BlockIds.is_solid(id):
			continue
		if p.y == top:
			top_ids[id] = true
		snowy += int(SNOWY.has(id))
		pumpkins += int(PUMPKINS.has(id))
		cacti += int(id == BlockIds.CACTUS)
	if top_ids.has(BlockIds.SNOWMAN_HEAD) and snowy * 2 >= n:
		return SNOWMAN
	if pumpkins * 2 >= n or (n <= SCARECROW_MAX and (top_ids.has(BlockIds.PUMPKIN) or top_ids.has(BlockIds.JACK_O_LANTERN))):
		return PUMPKIN
	if cacti * 2 >= n:
		return CACTUS
	return NONE


## The woken build's name: a kind's own names, else the ordinary buddy's (the same build, the same name).
static func name_for(blocks: Dictionary) -> String:
	var plain := BuddyNames.name_for(blocks)
	var kind := kind_of(blocks)
	if kind == NONE:
		return plain
	var list: Array = NAMES[kind]
	return str(list[posmod(plain.hash(), list.size())])


## What the child hears when it wakes ("" for an ordinary buddy).
static func wake_line(kind: StringName, buddy_name: String) -> String:
	return Lang.t(str(LINES[kind])) % buddy_name if LINES.has(kind) else ""   # translated, then filled in (M3 Task 21a)


## A jack-o-lantern buddy glows orange.
static func glows(blocks: Dictionary) -> bool:
	return blocks.values().has(BlockIds.JACK_O_LANTERN)


## The chest mimic's next landing spot from `from` towards the child at `target`: at most HOP_STEP sideways, never
## closer than KEEP, on the ground there (ground_y(x, z) -> the feet height in that column, NAN when unknown), never
## up or down more than MAX_CLIMB. `from` itself when it stays.
static func mimic_hop(from: Vector3, target: Vector3, ground_y: Callable) -> Vector3:
	var to := Vector2(target.x - from.x, target.z - from.z)
	var d := to.length()
	if d <= KEEP + 0.05:
		return from
	var step := minf(HOP_STEP, d - KEEP)
	var flat := to / d * step
	var x := from.x + flat.x
	var z := from.z + flat.y
	var y: float = ground_y.call(floori(x), floori(z))
	if is_nan(y) or absf(y - from.y) > MAX_CLIMB:
		return from
	return Vector3(x, y, z)


## Where a mimic's feet stand in column (x, z) next to its own height y: its own level, a step up or a step down
## (a solid block under the feet, air at them); NAN for none. solid(cell) -> bool.
static func feet_near(x: int, z: int, y: float, solid: Callable) -> float:
	var base := floori(y + 0.01)
	for dy: int in [0, 1, -1]:
		var fy := base + dy
		if solid.call(Vector3i(x, fy - 1, z)) and not solid.call(Vector3i(x, fy, z)):
			return float(fy)
	return NAN


## A mimic's present for the chest `key` (LootRules.chest_key): one small, fixed thing; never gold.
static func mimic_present(key: int, _universe: int) -> Dictionary:
	var e: Array = PRESENTS[posmod(key, PRESENTS.size())]
	return {"gold": 0, "items": [[int(e[0]), int(e[1])]], "rarity": LootRules.COMMON}
