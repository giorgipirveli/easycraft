class_name LootRules
extends RefCounted
## What treasure holds (M2 Task 16, spec §12.16), as pure rules. Deterministic per chest (the world seed and
## the chest's cell: chest_key), so a chest always holds the same things. Gold is 20–150 × 2^(u−1) in
## Survivor only (Sandbox gold is ∞); every chest has rare blocks, and sometimes a treasure map, a potion, a
## better tool or a decoration that exists only in treasure. Treasure is found by playing, never bought
## (§6). The rarity (§13.2) is the best thing inside: chests glow in its colour.

const COMMON := 0
const UNCOMMON := 1
const RARE := 2
const EPIC := 3
const LEGENDARY := 4
## grey, green, blue, purple, gold (§13.2; Task 6 uses the same colours for tiers).
const RARITY_COLORS: Array[Color] = ItemRarity.COLORS   # one table with tier items (§13.2)

## Things that exist only in treasure: in no palette row, no shop, never given by /give.
const TREASURE_ONLY: Array[int] = [BlockIds.TROPHY, BlockIds.GOLD_LAMP, ItemIds.TREASURE_MAP,
	BlockIds.CHEESE]   # M3 Task 21c: the mice's present (a mouse village's tiny chest)
const DECORATIONS: Array[int] = [BlockIds.TROPHY, BlockIds.GOLD_LAMP]
const STONE_TOOLS: Array[int] = [ItemIds.SWORD_STONE, ItemIds.PICKAXE_STONE, ItemIds.AXE_STONE, ItemIds.BOW_STONE,
	ItemIds.SHIELD_STONE]
const IRON_TOOLS: Array[int] = [ItemIds.SWORD_IRON, ItemIds.PICKAXE_IRON, ItemIds.AXE_IRON, ItemIds.BOW_IRON,
	ItemIds.SHIELD_IRON]
const CRYSTAL_TOOLS: Array[int] = [ItemIds.SWORD_CRYSTAL, ItemIds.PICKAXE_CRYSTAL, ItemIds.AXE_CRYSTAL,
	ItemIds.BOW_CRYSTAL, ItemIds.SHIELD_CRYSTAL]
const COSMIC_TOOLS: Array[int] = [ItemIds.SWORD_COSMIC, ItemIds.PICKAXE_COSMIC, ItemIds.AXE_COSMIC,
	ItemIds.BOW_COSMIC, ItemIds.SHIELD_COSMIC]

## Per kind of treasure: gold [min, max] (Survivor, × 2^(u−1)); blocks [[id, min, max], ...] (one is
## picked); the chance of a map, a potion, a better tool (from `tools`) and a decoration.
const TABLES := {
	&"buried": {"gold": [20, 60], "blocks": [[BlockIds.IRON, 4, 8], [BlockIds.GOLD, 2, 5], [BlockIds.COAL, 6, 12]],
		"map": 0.35, "potion": 0.25, "tool": 0.15, "tools": STONE_TOOLS, "decoration": 0.2},
	&"room": {"gold": [40, 90], "blocks": [[BlockIds.GOLD, 3, 6], [BlockIds.DIAMOND, 1, 3], [BlockIds.IRON, 6, 10]],
		"map": 0.3, "potion": 0.3, "tool": 0.25, "tools": STONE_TOOLS + IRON_TOOLS, "decoration": 0.35},
	&"temple": {"gold": [70, 120], "blocks": [[BlockIds.DIAMOND, 2, 4], [BlockIds.CRYSTAL, 2, 4]],
		"map": 0.2, "potion": 0.4, "tool": 0.4, "tools": IRON_TOOLS + CRYSTAL_TOOLS, "decoration": 1.0},
	&"sky": {"gold": [100, 150], "blocks": [[BlockIds.DIAMOND, 3, 5], [BlockIds.CRYSTAL, 3, 6]],
		"map": 0.3, "potion": 0.3, "tool": 0.5, "tools": IRON_TOOLS + CRYSTAL_TOOLS, "decoration": 1.0},
	&"wanderer": {"gold": [30, 60], "blocks": [[BlockIds.CRYSTAL, 2, 4], [BlockIds.GOLD, 2, 4]],
		"map": 0.5, "potion": 0.5, "tool": 0.0, "tools": [], "decoration": 0.3},
	# Hook for the Party Piñata (spec §13.5, M3 content): supplies, no gold.
	&"pinata": {"gold": [0, 0], "blocks": [[BlockIds.PLANKS, 8, 16], [BlockIds.GLASS, 4, 8], [BlockIds.RED, 4, 8],
		[BlockIds.YELLOW, 4, 8], [BlockIds.BLUE, 4, 8]], "map": 0.0, "potion": 0.6, "tool": 0.0, "tools": [],
		"decoration": 0.0},
}
const GOLDEN_GOLD := Vector2i(60, 100)   # a golden animal's pile of gold (Survivor)


## A number that stands for one chest (or one Wanderer visit, one golden animal) in one world.
static func chest_key(world_seed: int, cell: Vector3i) -> int:
	var h := cell.x * 73856093 ^ cell.y * 19349663 ^ cell.z * 83492791 ^ world_seed * 2654435761 ^ 0x51ed27
	h = (h ^ (h >> 13)) * 1274126177
	return (h ^ (h >> 16)) & 0x7fffffffffffffff


## The treasure of kind `kind` for `key` in universe u: {"gold": int, "items": [[id, count], ...], "rarity"}.
## survivor: gold counts (Sandbox gets the same things, no gold). The random numbers are always drawn in
## the same order, so both modes find the same things in the same chest.
static func roll(kind: StringName, key: int, universe: int, survivor: bool) -> Dictionary:
	if kind == MouseVillages.CHEST_KIND:
		return MouseVillages.loot(key, universe, survivor)   # M3 Task 21c: the mice's tiny chest
	if TreasureLoot.handles(kind):
		return TreasureLoot.roll(kind, key, universe, survivor)   # owner 42: the chest rarities
	var t: Dictionary = TABLES.get(kind, TABLES[&"buried"])
	var rng := RandomNumberGenerator.new()
	rng.seed = key
	rng.randi_range(int(t.gold[0]), int(t.gold[1]))   # drawn as before, so each chest keeps its things
	var gold := fixed_gold(kind) * _scale(universe)   # owner 42 / spec 6: never random for money
	var items: Array = []
	var blocks: Array = t.blocks
	var pick: Array = blocks[rng.randi() % blocks.size()]
	items.append([int(pick[0]), rng.randi_range(int(pick[1]), int(pick[2]))])
	var map_roll := rng.randf()
	var potion_roll := rng.randf()
	var potion := ItemIds.POTIONS[rng.randi() % ItemIds.POTIONS.size()]
	var tool_roll := rng.randf()
	var tool_index := rng.randi()
	var decoration_roll := rng.randf()
	var decoration := DECORATIONS[rng.randi() % DECORATIONS.size()]
	if map_roll < float(t.map):
		items.append([ItemIds.TREASURE_MAP, 1])
	if potion_roll < float(t.potion):
		items.append([potion, 1])
	var tools: Array = t.tools
	if tool_roll < float(t.tool) and not tools.is_empty():
		items.append([int(tools[tool_index % tools.size()]), 1])
	if decoration_roll < float(t.decoration):
		items.append([decoration, 1])
	return {"gold": gold if survivor else 0, "items": items, "rarity": best_rarity(items)}


## A kind's Survivor gold in Green Meadows: the middle of its range, the same for every chest (spec §6: no
## random rewards for any currency; owner 42's ruling fixed the M2 kinds' gold too).
static func fixed_gold(kind: StringName) -> int:
	var t: Dictionary = TABLES.get(kind, TABLES[&"buried"])
	return (int(t.gold[0]) + int(t.gold[1])) / 2


## A caught golden animal: a pile of gold in Survivor, a golden trophy in Sandbox (spec §12.16). The pile is
## always the same size (§6).
static func golden_reward(_key: int, universe: int, survivor: bool) -> Dictionary:
	if not survivor:
		return {"gold": 0, "items": [[BlockIds.TROPHY, 1]], "rarity": LEGENDARY}
	return {"gold": (GOLDEN_GOLD.x + GOLDEN_GOLD.y) / 2 * _scale(universe), "items": [], "rarity": LEGENDARY}


static func rarity_of(id: int) -> int:
	if TREASURE_ONLY.has(id):
		return EPIC if id == ItemIds.TREASURE_MAP else LEGENDARY
	if COSMIC_TOOLS.has(id):
		return LEGENDARY
	if CRYSTAL_TOOLS.has(id) or id == BlockIds.DIAMOND or id == BlockIds.CRYSTAL:
		return EPIC
	if IRON_TOOLS.has(id) or ItemIds.POTIONS.has(id) or id == BlockIds.GOLD:
		return RARE
	if STONE_TOOLS.has(id) or id == BlockIds.IRON:
		return UNCOMMON
	return COMMON


static func best_rarity(items: Array) -> int:
	var best := COMMON
	for e: Array in items:
		best = maxi(best, rarity_of(int(e[0])))
	return best


static func rarity_color(rarity: int) -> Color:
	return RARITY_COLORS[clampi(rarity, COMMON, LEGENDARY)]


## A short line for the banner: "85 gold, 6 Diamond, Golden Trophy".
static func describe(loot: Dictionary) -> String:
	var parts: Array[String] = []
	if int(loot.get("gold", 0)) > 0:
		parts.append(Lang.t("%d gold") % int(loot.gold))
	for e: Array in loot.get("items", []):
		var n := int(e[1])
		parts.append(ItemIds.display_name(int(e[0])) if n == 1 else "%d %s" % [n, ItemIds.display_name(int(e[0]))])
	return ", ".join(parts)


static func _scale(universe: int) -> int:
	return 1 << clampi(SpaceRules.scaling(universe) - 1, 0, 20)   # owner #55: never in space
