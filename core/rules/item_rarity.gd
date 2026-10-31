class_name ItemRarity
extends RefCounted
## Rarity colours (M2 spec §13.2): a tier shows its colour everywhere (icon rim, held model tint,
## name). wood/common grey, stone/uncommon green, iron/rare blue, crystal/epic purple,
## cosmic/legendary gold. Colour is never the only sign: tier icons carry 1-5 pips and held
## models 1-5 bands (colourblind children; lead's accessibility ruling, M2 Task 6).

const COMMON := 0
const UNCOMMON := 1
const RARE := 2
const EPIC := 3
const LEGENDARY := 4

const COLORS: Array[Color] = [Color("a7b0ba"), Color("3fca4f"), Color("2f86f0"), Color("a54df2"), Color("f5b01e")]
const LABELS: Array[String] = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
## How strongly a held model takes its rarity colour (the model's vertex colours times the tint).
const MODEL_TINT_STRENGTH := 0.55


## A tier (WeaponRules.TIER_WOOD..TIER_COSMIC) is its rarity.
static func of_tier(tier: int) -> int:
	return tier if tier >= COMMON and tier <= LEGENDARY else -1


## The rarity of an item, or -1 for things without one (M3 Task 14b: a blaster's, and its ammo's).
static func of_item(id: int) -> int:
	if BlasterRules.is_blaster(id) or BlasterRules.is_ammo(id):
		return BlasterRules.rarity(id)
	return of_tier(WeaponRules.tier_of(id))


static func color(rarity: int) -> Color:
	return COLORS[rarity] if rarity >= COMMON and rarity <= LEGENDARY else Color.WHITE


static func label(rarity: int) -> String:
	return LABELS[rarity] if rarity >= COMMON and rarity <= LEGENDARY else ""


## The held model's material colour: white for common (the M1b look), a light rarity colour above.
static func model_tint(rarity: int) -> Color:
	if rarity <= COMMON or rarity > LEGENDARY:
		return Color.WHITE
	return Color.WHITE.lerp(color(rarity), MODEL_TINT_STRENGTH)
