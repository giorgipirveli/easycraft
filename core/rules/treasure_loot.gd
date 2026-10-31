class_name TreasureLoot
extends RefCounted
## Chest rarities of the treasure pack (owner feedback #42, spec §12.16b, §13.2, §6), as pure rules. Every
## chest kind has a rarity — common, rare, epic or legendary — and glows in its §13.2 colour. What it holds
## comes from fixed tables by rarity and universe: a fixed amount of Survivor gold (× 2^(u−1), never random:
## §6), what that rarity always holds, and a pick without repeats from its table that is always the same for
## that chest (the world seed and the chest's cell: LootRules.chest_key). Sandbox finds the same things
## without the gold. LootRules.roll hands these kinds here.

const COMMON := ItemRarity.COMMON
const RARE := ItemRarity.RARE
const EPIC := ItemRarity.EPIC
const LEGENDARY := ItemRarity.LEGENDARY

## Chest kind -> its rarity (a mineshaft's chest is its loot cart).
const CHESTS := {&"camp": COMMON, &"ruins": COMMON, &"shipwreck": RARE, &"sunken": RARE, &"cart": RARE,
	&"hollowtree": RARE, &"cove": EPIC, &"waterfall": EPIC, &"haunted": EPIC, &"vault": LEGENDARY}
## Survivor gold by rarity (Green Meadows; × 2^(u−1)).
const GOLD := {COMMON: 15, RARE: 40, EPIC: 80, LEGENDARY: 150}
## How many things are picked from the rarity's table.
const PICKS := {COMMON: 2, RARE: 2, EPIC: 2, LEGENDARY: 2}
## What a chest of that rarity always holds.
const ALWAYS := {COMMON: [], RARE: [], EPIC: [[BlockIds.GOLD, 4]], LEGENDARY: [[BlockIds.TROPHY, 1]]}
## [id, count] per rarity, for every universe.
const SHARED := {
	COMMON: [[ItemIds.POTION_SPEED, 1], [BlockIds.GLASS, 6], [BlockIds.COAL, 6]],
	RARE: [[BlockIds.IRON, 6], [BlockIds.GOLD, 3], [BlockIds.COAL, 10], [ItemIds.TREASURE_MAP, 1],
		[ItemIds.POTION_JUMP, 1], [ItemIds.PICKAXE_STONE, 1], [ItemIds.SWORD_STONE, 1]],
	EPIC: [[BlockIds.DIAMOND, 3], [BlockIds.CRYSTAL, 4], [ItemIds.SWORD_IRON, 1], [ItemIds.PICKAXE_IRON, 1],
		[ItemIds.BOW_IRON, 1], [BlockIds.GOLD_LAMP, 1], [ItemIds.POTION_INVIS, 1]],
	LEGENDARY: [[BlockIds.DIAMOND, 5], [BlockIds.CRYSTAL, 6], [BlockIds.GOLD_LAMP, 1], [ItemIds.SWORD_CRYSTAL, 1],
		[ItemIds.PICKAXE_CRYSTAL, 1], [ItemIds.SHIELD_CRYSTAL, 1], [ItemIds.BOW_CRYSTAL, 1]],
}
## [id, count] per rarity and universe (1 Green Meadows, 2 the Sandstorm Desert, 3 Frostpeak): each
## universe's own supplies. A universe without its own uses Green Meadows'.
const LOCAL := {
	COMMON: {
		1: [[BlockIds.LANTERN, 2], [BlockIds.PLANKS, 12], [BlockIds.LOG, 8], [BlockIds.BRICK, 8]],
		2: [[BlockIds.DESERT_LAMP, 2], [BlockIds.SANDSTONE, 12], [BlockIds.PALM_LOG, 8], [BlockIds.CUT_SANDSTONE, 8]],
		3: [[BlockIds.ICE_LANTERN, 2], [BlockIds.PACKED_SNOW, 12], [BlockIds.PINE_LOG, 8], [BlockIds.SNOW_BRICK, 8]],
	},
	RARE: {
		1: [[BlockIds.LANTERN, 4]],
		2: [[BlockIds.DESERT_GLASS, 8]],
		3: [[BlockIds.FROZEN_ORE, 4]],
	},
	EPIC: {1: [], 2: [], 3: []},
	LEGENDARY: {1: [], 2: [], 3: []},
}


static func handles(chest_kind: StringName) -> bool:
	return CHESTS.has(chest_kind)


static func rarity_of(chest_kind: StringName) -> int:
	return int(CHESTS.get(chest_kind, COMMON))


## The table a chest of `rarity` picks from in universe u: the shared things and that universe's own.
static func table(rarity: int, universe: int) -> Array:
	var local: Dictionary = LOCAL.get(rarity, {})
	var own: Array = local.get(universe, local.get(1, []))
	return (SHARED.get(rarity, []) as Array) + own


## The chest of kind `chest_kind` for `key` in universe u: {"gold", "items": [[id, count], ...], "rarity",
## "tier"} ("tier" marks the pack's chests: the banner names the rarity). survivor: gold counts.
static func roll(chest_kind: StringName, key: int, universe: int, survivor: bool) -> Dictionary:
	var rarity := rarity_of(chest_kind)
	var items: Array = (ALWAYS[rarity] as Array).duplicate(true)
	var pool := table(rarity, universe).duplicate(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = key
	for i in mini(int(PICKS[rarity]), pool.size()):
		items.append(pool.pop_at(rng.randi() % pool.size()))
	var gold := int(GOLD[rarity]) * (1 << clampi(SpaceRules.scaling(universe) - 1, 0, 20)) if survivor else 0
	return {"gold": gold, "items": items, "rarity": rarity, "tier": rarity}
