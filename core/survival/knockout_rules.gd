class_name KnockoutRules
extends RefCounted
## Knock-outs and pickup bags (M2 §12.3, §12.15) as pure rules. At 0 HP a Survivor player gets up at
## their bed (the world spawn without one) and every carried block (never tools, weapons, potions or
## gold) waits in a glowing bag where they fell; a Sandbox player pops back up on the spot keeping
## everything. A bag is its owner's for OWNER_ONLY_TIME, then anyone's (ruling in
## docs/devlog/parts/m2-task-2.md). Bags never lose or duplicate a block: what does not fit back into
## a full inventory stays in the bag, and extra bags merge into old ones instead of being dropped.

const KO_TIME := 1.6               # seconds of "You were knocked out!" before getting up
const OWNER_ONLY_TIME := 300.0     # a bag is its owner's for 5 minutes, then anyone's
const MERGE_DISTANCE := 2.5        # a new drop this close to the owner's bag goes into it
const MAX_BAGS_PER_PLAYER := 8     # more knock-outs fill the owner's oldest bag
const MAX_BAGS := 64               # in one world; more fill the oldest bag
const MAX_COUNT := 99999           # of one block in one bag (merged bags may hold more than 999)
const MAX_RISE := 8                # a bag inside blocks rises at most this far
const MAX_DROP := 64               # and falls at most this far to the ground
const REACH := PlacementRules.REACH + PlacementRules.REACH_TOLERANCE   # eye to bag, host check

## Survivor difficulty per world (the lead's child-psychology research, docs/design/; the lead adds
## the world setting). The knock-out part: Cozy drops no bag. Monster damage is scaled elsewhere.
const COZY := &"cozy"
const NORMAL := &"normal"
const BRAVE := &"brave"
const DIFFICULTIES: Array[StringName] = [COZY, NORMAL, BRAVE]

## One picture tip after each knock-out (the lead): an icon (block or item id) and a short, kind
## line that says what helps, never what went wrong. The first is for players without a bed.
const TIPS: Array[Dictionary] = [
	{"icon": BlockIds.BED, "text": "Sleep in a bed to wake up there next time."},
	{"icon": BlockIds.LANTERN, "text": "Lanterns keep monsters away."},
	{"icon": BlockIds.BARREL, "text": "Hide in a barrel when monsters come near."},
	{"icon": BlockIds.DOOR, "text": "Monsters can't open doors. Build a door!"},
	{"icon": BlockIds.BUSH, "text": "Crouch in a bush and monsters can't see you."},
	{"icon": ItemIds.SWORD, "text": "Tap ATTACK with your sword to fight back!"},
]


## Survivor gets up at home (bed or world spawn); Sandbox pops back up where it was.
static func respawns_at_home(mode: StringName) -> bool:
	return ModeRules.allows(mode, ModeRules.LOSSES)


## Whether a knock-out drops the carried blocks: Survivor, except in Cozy worlds.
static func drops_bag(mode: StringName, difficulty: StringName = NORMAL) -> bool:
	return ModeRules.allows(mode, ModeRules.LOSSES) and valid_difficulty(difficulty) != COZY


static func valid_difficulty(difficulty: StringName) -> StringName:
	return difficulty if DIFFICULTIES.has(difficulty) else NORMAL


## The tip for this game's knock-out number n (0, 1, ...): the bed tip while a Survivor player who
## gets up at home has no bed, else the others take turns.
static func tip(n: int, at_home: bool, has_bed: bool) -> Dictionary:
	if at_home and not has_bed:
		return TIPS[0]
	return TIPS[1 + posmod(n, TIPS.size() - 1)]


## Blocks drop into the bag; items (tools, weapons, potions, shields, magic) are kept.
static func drops(id: int) -> bool:
	return BlockIds.is_valid(id) and BlockIds.is_breakable(id)


## Takes every block out of inv; returns them as bag items [[id, count], ...].
static func take_blocks(inv: Inventory) -> Array:
	var out := []
	for id in inv.ids():
		if drops(id):
			var n := inv.count(id)
			if inv.take(id, n):
				out.append([id, n])
	return out


## Puts bag items into inv; returns what did not fit (it stays in the bag).
static func put_back(items: Array, inv: Inventory) -> Array:
	var left := []
	for e: Array in items:
		var n: int = e[1]
		var added := inv.add(e[0], n)
		if added < n:
			left.append([e[0], n - added])
	return left


static func merge_items(a: Array, b: Array) -> Array:
	return clean_items(a + b)


## Bag items from anything (a save, the network): only droppable blocks with finite counts >= 1;
## duplicates merge; counts cap at MAX_COUNT. Never fails.
static func clean_items(data: Variant) -> Array:
	var counts := {}
	if data is Array:
		for e: Variant in data:
			if not (e is Array and (e as Array).size() == 2):
				continue
			if not (typeof(e[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(e[1]) in [TYPE_INT, TYPE_FLOAT]):
				continue
			if not (is_finite(float(e[0])) and is_finite(float(e[1]))) or float(e[1]) < 1.0:
				continue
			var id := int(e[0])
			if drops(id):
				counts[id] = mini(int(counts.get(id, 0)) + int(minf(float(e[1]), MAX_COUNT)), MAX_COUNT)
	var out := []
	for id: int in counts:
		out.append([id, counts[id]])
	return out


static func can_take(bag_owner: String, taker: String, age: float) -> bool:
	return bag_owner == "" or taker == bag_owner or age >= OWNER_ONLY_TIME


## "" when taker may take the bag, else what to tell them.
static func refusal(bag_owner: String, taker: String, age: float) -> String:
	if can_take(bag_owner, taker, age):
		return ""
	var left := ceili(OWNER_ONLY_TIME - age)
	var wait := ""
	if left >= 60:
		var minutes := ceili(left / 60.0)
		wait = "1 minute" if minutes == 1 else Lang.t("%d minutes") % minutes
	else:
		wait = "1 second" if left == 1 else Lang.t("%d seconds") % left
	return Lang.t("This is %s's bag. You can take it in %s.") % [bag_owner, wait]


static func in_reach(eye: Vector3, bag_center: Vector3) -> bool:
	return eye.is_finite() and bag_center.is_finite() and eye.distance_to(bag_center) <= REACH


## Where a bag lands for a player knocked out at `feet`: out of any blocks, then down to the ground
## (through air and water), in the middle of the cell. With no ground within MAX_DROP (terrain not
## loaded) it stays where they fell. is_solid: func(cell: Vector3i) -> bool. INF for a broken position.
static func bag_spot(feet: Vector3, is_solid: Callable) -> Vector3:
	if not feet.is_finite():
		return Vector3.INF
	var cell := Vector3i(feet.floor())
	var rise := 0
	while is_solid.call(cell) and rise < MAX_RISE:
		cell += Vector3i.UP
		rise += 1
	var top := cell
	var fall := 0
	while not is_solid.call(cell + Vector3i.DOWN) and fall < MAX_DROP:
		cell += Vector3i.DOWN
		fall += 1
	if fall >= MAX_DROP:
		cell = top
	return Vector3(cell.x + 0.5, cell.y, cell.z + 0.5)


## Which existing bag a new drop of `bag_owner`'s at `spot` goes into, or -1 for a new bag.
## bags: [{owner: String, pos: Vector3, age: float}]. The owner's bag within MERGE_DISTANCE; else,
## when they already have MAX_BAGS_PER_PLAYER, their oldest; else, when the world has MAX_BAGS, the
## oldest of all (long free for anyone by then).
static func merge_index(bags: Array, bag_owner: String, spot: Vector3) -> int:
	var own := 0
	var oldest_own := -1
	var oldest := -1
	for i in bags.size():
		var b: Dictionary = bags[i]
		if oldest < 0 or float(b.age) > float(bags[oldest].age):
			oldest = i
		if str(b.owner) != bag_owner:
			continue
		if (b.pos as Vector3).distance_to(spot) <= MERGE_DISTANCE:
			return i
		own += 1
		if oldest_own < 0 or float(b.age) > float(bags[oldest_own].age):
			oldest_own = i
	if own >= MAX_BAGS_PER_PLAYER:
		return oldest_own
	if bags.size() >= MAX_BAGS:
		return oldest
	return -1
