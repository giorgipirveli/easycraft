class_name WeaponStrength
extends RefCounted
## How strong a weapon is next to how hard it is to get (owner feedback #53, spec §13.5). How hard: its rarity
## (ItemRarity: the colour it shows; Tilly's price follows it). How strong: the damage it does per second to one
## monster over a whole fight (a blaster's magazine and reload, a boomerang's round trip). Every fighting weapon's
## strength sits in its rarity's band (BANDS[r] up to BANDS[r + 1]); the bands never overlap, so a rarer weapon
## always hits harder. Tools (a block power: pickaxe, axe, hammer) stay under the band of their rarity.

## Damage per second: common from 7, uncommon from 12, rare from 18, epic from 26, legendary from 40 (under 60).
## The sword of each tier sits inside its band (11.4, 17.1, 22.9, 34.3, 51.4).
const BANDS: Array[float] = [7.0, 12.0, 18.0, 26.0, 40.0, 60.0]
## Weapons without tiers: priced like a stone tool (ShopRules.OTHER_TOOL_PRICES), so uncommon.
const UNTIERED := {ItemIds.BOOMERANG: ItemRarity.UNCOMMON, ItemIds.HAMMER: ItemRarity.UNCOMMON}
## The kinds made for fighting (every tier of each).
const FIGHTING_KINDS: Array[int] = [ItemIds.SWORD, ItemIds.BOW, ItemIds.SPEAR, ItemIds.MACE]


## Every weapon made for fighting: each tier of the sword, bow, spear and mace, the boomerang and the blasters.
static func fighting_weapons() -> Array[int]:
	var out: Array[int] = []
	for kind in FIGHTING_KINDS:
		for id: int in WeaponRules.TIERS[kind]:
			out.append(id)
	out.append(ItemIds.BOOMERANG)
	out.append_array(ItemIds.BLASTERS)
	return out


## How hard it is to get: ItemRarity.COMMON .. LEGENDARY (-1: not a weapon).
static func rarity(id: int) -> int:
	if UNTIERED.has(id):
		return int(UNTIERED[id])
	return ItemRarity.of_item(id)


## Damage of one hit.
static func hit(id: int) -> int:
	if BlasterRules.is_blaster(id):
		return BlasterRules.damage(id)
	return int(WeaponRules.stats(id).get("damage", 0))


## Damage per second to one monster over a whole fight.
static func dps(id: int) -> float:
	if BlasterRules.is_blaster(id):
		var shots := BlasterRules.magazine(id)
		var cycle := (shots - 1) * BlasterRules.interval(id) + BlasterRules.reload_time(id)
		return shots * BlasterRules.damage(id) / cycle
	var w := WeaponRules.stats(id)
	if w.is_empty():
		return 0.0
	var every := float(w.cooldown)
	if w.kind == WeaponRules.BOOMERANG:
		every = maxf(every, WeaponRules.boomerang_round_trip())
	return float(w.damage) / every
