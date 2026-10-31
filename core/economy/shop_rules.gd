class_name ShopRules
extends RefCounted
## Tilly the trader's prices (M2 spec §12.7) and trades against a Wallet and an Inventory. Pure: the
## host runs the same checks for every trade (Session, "M2 Task 7"). A trade is all or nothing.
## Buying never costs less per block than selling pays, so no loop can mint gold.
## M3 Task 5 (§14.1): in universe u every price, bought or sold, is × 2^(u−1) (UniverseRules.price), and
## the universe's descriptor adds its local things (UniverseRegistry.trader_stock) to the BLOCKS section.

const TIER_PRICES: Array[int] = [5, 30, 120, 400, 1200]   # wood, stone, iron, crystal, cosmic (per tool)
const BLOCKS_PER_GOLD := 4

## Tool lines, wood tier first (the M1b sword, bow, pickaxe and axe are the wood tier).
const TOOL_LINES: Array = [
	[ItemIds.SWORD, ItemIds.SWORD_STONE, ItemIds.SWORD_IRON, ItemIds.SWORD_CRYSTAL, ItemIds.SWORD_COSMIC],
	[ItemIds.BOW, ItemIds.BOW_STONE, ItemIds.BOW_IRON, ItemIds.BOW_CRYSTAL, ItemIds.BOW_COSMIC],
	[ItemIds.PICKAXE, ItemIds.PICKAXE_STONE, ItemIds.PICKAXE_IRON, ItemIds.PICKAXE_CRYSTAL, ItemIds.PICKAXE_COSMIC],
	[ItemIds.AXE, ItemIds.AXE_STONE, ItemIds.AXE_IRON, ItemIds.AXE_CRYSTAL, ItemIds.AXE_COSMIC],
	[ItemIds.SHIELD_WOOD, ItemIds.SHIELD_STONE, ItemIds.SHIELD_IRON, ItemIds.SHIELD_CRYSTAL, ItemIds.SHIELD_COSMIC],
]
## Task 6's spear and mace lines, looked up by name so this file works before and after they exist.
const NAMED_LINES: Array = ["SPEAR", "MACE"]
const TIER_SUFFIXES: Array = ["", "_STONE", "_IRON", "_CRYSTAL", "_COSMIC"]
## Tools without tiers (M1b) cost like a stone tool; practice targets like a wooden one.
const OTHER_TOOL_PRICES := {ItemIds.HAMMER: 30, ItemIds.BOOMERANG: 30}
const TARGET_PRICES := {ItemIds.DUMMY: 5, ItemIds.BULLSEYE: 5}
const POTION_PRICES := {ItemIds.POTION_JUMP: 25, ItemIds.POTION_INVIS: 40, ItemIds.POTION_SPEED: 30}
## M3 Task 11: pet treats, cheap, on the potions shelf (one shelf for things that are used up).
const TREAT_PRICES := {ItemIds.TREAT_BISCUIT: PetRules.TREAT_PRICE, ItemIds.TREAT_FISH: PetRules.TREAT_PRICE,
	ItemIds.TREAT_BERRIES: PetRules.TREAT_PRICE, ItemIds.TREAT_SEEDS: PetRules.TREAT_PRICE,
	ItemIds.TREAT_BOLT: PetRules.TREAT_PRICE}
const HOME_PRICES := {BlockIds.BED: 20, BlockIds.LANTERN: 5, BlockIds.DOOR: 10, BlockIds.SPIKE_TRAP: 15,
	BlockIds.BARREL: 10, BlockIds.CLOSET: 20, BlockIds.BUSH: 3,
	BlockIds.PORTAL_FRAME: 5, BlockIds.PORTAL_CORE: 30,   # M3 Task 5: portals
	# M3 Task 7: smart blocks, Game Blocks and the Physics Lab's pads (fixed prices, × 2^(u-1) per universe)
	BlockIds.BUTTON: 3, BlockIds.LEVER: 3, BlockIds.PRESSURE_PLATE: 3, BlockIds.POWERED_DOOR: 10, BlockIds.LAMP: 4,
	BlockIds.LIGHT_SWITCH: 3, BlockIds.TELEPORT_PAD: 25, BlockIds.START: 5, BlockIds.CHECKPOINT: 3,
	BlockIds.FINISH: 5, BlockIds.COIN: 2, BlockIds.BOUNCE: 8, BlockIds.JUMP_PAD: 6, BlockIds.SPEED_PAD: 6,
	BlockIds.SADDLE: 60,   # M3 Task 20a: rides a buddy (a dragon flies free: six minutes of paid flying)
	BlockIds.TROPHY_SHELF: 15, BlockIds.BOOKSHELF: 10,   # M3 Task 21b: shows your badges; opens your books
	BlockIds.PUMPKIN: 3, BlockIds.JACK_O_LANTERN: 6, BlockIds.SNOWMAN_HEAD: 4,   # M3 Task 21c: things the wand wakes
	BlockIds.REFINERY: 40,   # spec §26: crude oil into kerosene and plastic next to it
	BlockIds.KEROSENE: 10,   # owner #98: the jet's and the rocket's fuel without another universe (the Desert's oil: free)
	BlockIds.SOLAR_OVEN: 30,   # spec §26.5: mirrors and sunlight bake dust into bricks and melt the finds
	ItemIds.FARM: FarmRules.PRICE}   # M3 Task 10: the Gold Farm (one per world; FarmRules.buy_refusal on the host)
## M2 Task 8: a doorway is two doors stacked, so doors come in pairs (one doorway for 10 gold).
## M3 Task 5: portal frames come in fours (a small frame needs 6, corners 10).
const PACKS := {BlockIds.DOOR: 2, BlockIds.PORTAL_FRAME: 4,
	BlockIds.POWERED_DOOR: 2, BlockIds.TELEPORT_PAD: 2, BlockIds.COIN: 4,   # M3 Task 7: a doorway, a pair, a row
	BlockIds.ZIPLINE_POST: 2, ItemIds.IMPULSE_ORB: 3, ItemIds.DANCE_ORB: 3}   # M3 Task 14a: a line's two posts, orbs by three
## 1 gold per 4. Never ores (they are sold), water (it flows) or bedrock.
const BUILDING_BLOCKS: Array[int] = [BlockIds.GRASS, BlockIds.DIRT, BlockIds.STONE, BlockIds.SAND, BlockIds.LOG,
	BlockIds.PLANKS, BlockIds.LEAVES, BlockIds.GLASS, BlockIds.BRICK, BlockIds.LIGHT, BlockIds.RED, BlockIds.YELLOW,
	BlockIds.GREEN, BlockIds.BLUE, BlockIds.PURPLE, BlockIds.DEEPSTONE]
## Gold per block sold, cheapest first (the Sell tab's order). Everything else is not bought.
## Spec §26: what refining makes (RefiningRules.SELL, held equal by the tests): table salt, crude oil, plastic, copper,
## kerosene; spec §26.5: hydrogen fuel, titanium, helium-3, rare earth powder (space's riches, never sold by Tilly).
const SELL_PRICES := {BlockIds.COAL: 1, BlockIds.TABLE_SALT: 1, BlockIds.CRUDE_OIL: 2, BlockIds.IRON: 3,
	BlockIds.PLASTIC: 3, BlockIds.COPPER: 5, BlockIds.KEROSENE: 6, BlockIds.GOLD: 8, BlockIds.CRYSTAL: 12,
	BlockIds.DIAMOND: 20, BlockIds.HYDROGEN_FUEL: 4, BlockIds.TITANIUM: 6, BlockIds.HELIUM_3: 8, BlockIds.RARE_EARTHS: 10}

## The Buy tab's sections, in order.
const TOOLS := &"tools"
const POTIONS := &"potions"
const HOME := &"home"
const BLOCKS := &"blocks"
const GADGETS := &"gadgets"   # M3 Task 14a: the action kit's gadgets (GadgetRules.PRICES)
const SECTIONS: Array[StringName] = [TOOLS, POTIONS, GADGETS, HOME, BLOCKS]

const _MESSAGES := {
	"gold": "You need more gold!",
	"full": "Your bag is full of those!",
	"have_it": "You already have one!",
	"not_for_sale": "Tilly doesn't sell that.",
	"not_sellable": "Tilly doesn't buy that.",
	"none": "You don't have that.",
	"too_far": "Come closer to Tilly!",
	"survivor_only": "Tilly trades in Survivor worlds.",
}

static var _lines: Array = []   # TOOL_LINES plus the named lines that exist


## Every tool line (ids, wood first), including Task 6's spear and mace once ItemIds has them.
static func tool_lines() -> Array:
	if _lines.is_empty():
		_lines = TOOL_LINES.duplicate()
		var ids: Dictionary = (ItemIds as GDScript).get_script_constant_map()
		for line_name: String in NAMED_LINES:
			var line: Array = []
			for suffix: String in TIER_SUFFIXES:
				if ids.has(line_name + suffix):
					line.append(int(ids[line_name + suffix]))
			if line.size() == TIER_SUFFIXES.size():
				_lines.append(line)
	return _lines


## 0 (wood) … 4 (cosmic) for a tiered tool, else -1.
static func tier_of(id: int) -> int:
	for line: Array in tool_lines():
		var i := line.find(id)
		if i >= 0:
			return i
	return -1


## The wood-tier tool of a tiered tool's line (its icon stands in until the tier has its own), else id.
static func base_tool(id: int) -> int:
	for line: Array in tool_lines():
		if line.has(id):
			return line[0]
	return id


## Tools and shields: nobody needs two, so the shop never sells one you already have.
static func is_tool_item(id: int) -> bool:
	return tier_of(id) >= 0 or OTHER_TOOL_PRICES.has(id) or BlasterRules.is_blaster(id) \
		or GadgetRules.is_kept(id)   # M3 Task 14b: blasters too; 14a: gadgets


## Gold for one purchase (amount(id) of it) in universe u; 0 = not sold. The same in every Survivor game
## (`game`: Build to Survive changes only amount()).
static func price(id: int, universe: int = 1, _game: StringName = &"classic") -> int:
	return UniverseRules.price(_base_price(id, universe), universe)


static func _base_price(id: int, universe: int) -> int:
	if universe > 1:
		var local := UniverseRegistry.trader_stock(universe)
		if local.has(id):
			return local[id]
	var tier := tier_of(id)
	if tier >= 0:
		return TIER_PRICES[tier]
	if BlasterRules.shop_price(id) > 0:
		return BlasterRules.shop_price(id)   # M3 Task 14b: blasters by rarity, ammo by the pack
	for table: Dictionary in [OTHER_TOOL_PRICES, TARGET_PRICES, POTION_PRICES, HOME_PRICES, GadgetRules.PRICES, TREAT_PRICES]:
		if table.has(id):
			return table[id]
	if CrystalRules.is_crystal(id):
		return CrystalRules.base_price(id, universe)   # owner 39: copies of the crystals up to this universe
	return 1 if BUILDING_BLOCKS.has(id) else 0


## How many one purchase gives (Build to Survive: more building blocks, _game_blocks_per_gold).
static func amount(id: int, game: StringName = &"classic") -> int:
	if BUILDING_BLOCKS.has(id):
		return _game_blocks_per_gold(id, game)
	return PACKS.get(id, BlasterRules.pack(id))   # M3 Task 14b: ammo packs


## Gold per block sold in universe u; 0 = Tilly doesn't buy it.
static func sell_price(id: int, universe: int = 1) -> int:
	return UniverseRules.price(SELL_PRICES.get(id, 0), universe)


## Sold, and something an inventory can hold (tier and potion ids become items with Task 6).
static func for_sale(id: int, universe: int = 1) -> bool:
	return price(id, universe) > 0 and Inventory.ownable(id)


## What the Buy tab shows in `section`, in order (in universe u: its local things at the end of BLOCKS).
static func catalog(section: StringName, universe: int = 1) -> Array[int]:
	var ids: Array[int] = []
	match section:
		TOOLS:
			for line: Array in tool_lines():
				for id: int in line:
					ids.append(id)
			for id: int in OTHER_TOOL_PRICES:
				ids.append(id)
			for id: int in TARGET_PRICES:
				ids.append(id)
			ids.append_array(ItemIds.BLASTERS + ItemIds.AMMO)   # M3 Task 14b
		POTIONS:
			for id: int in POTION_PRICES:
				ids.append(id)
			for id: int in TREAT_PRICES:   # M3 Task 11
				ids.append(id)
		HOME:
			for id: int in HOME_PRICES:
				ids.append(id)
			ids.append_array(CrystalRules.for_sale_in(universe))   # owner 39: universe crystals
		GADGETS:   # M3 Task 14a
			for id: int in GadgetRules.PRICES:
				ids.append(id)
		BLOCKS:
			ids.append_array(BUILDING_BLOCKS)
			if universe > 1:
				for id: int in UniverseRegistry.trader_stock(universe):
					ids.append(id)
	var listed: Array[int] = []
	for id in ids:
		if for_sale(id, universe) and not listed.has(id):
			listed.append(id)
	return listed


## What `inv` holds that Tilly buys, cheapest first (the Sell tab).
static func sellable(inv: Inventory) -> Array[int]:
	var ids: Array[int] = []
	for id: int in SELL_PRICES:
		if inv.count(id) > 0:
			ids.append(id)
	return ids


## Why buying id with `gold` into `inv` can't happen ("" = it can): a key for message().
static func buy_refusal(id: int, gold: int, inv: Inventory, universe: int = 1, game: StringName = &"classic") -> String:
	if not for_sale(id, universe):
		return "not_for_sale"
	if one_only(id) and inv.count(id) > 0:
		return "have_it"
	if inv.count(id) + amount(id, game) > Inventory.MAX_COUNT:
		return "full"
	if gold < price(id, universe, game):
		return "gold"
	return ""


## Buys one purchase of id: {ok, error, gold (paid), id, count (got)}. Nothing changes on a refusal.
static func buy(id: int, wallet: Wallet, inv: Inventory, universe: int = 1, game: StringName = &"classic") -> Dictionary:
	var error := buy_refusal(id, wallet.balance, inv, universe, game)
	var cost := price(id, universe, game)
	if error == "" and not wallet.spend(cost):
		error = "gold"
	if error != "":
		return {"ok": false, "error": error, "gold": 0, "id": id, "count": 0}
	inv.add(id, amount(id, game))
	return {"ok": true, "error": "", "gold": cost, "id": id, "count": amount(id, game)}


## Why selling n of id from `inv` can't happen ("" = it can).
static func sell_refusal(id: int, n: int, inv: Inventory, universe: int = 1) -> String:
	if sell_price(id, universe) <= 0:
		return "not_sellable"
	if n <= 0 or inv.count(id) < n:
		return "none"
	return ""


## Sells n of id: {ok, error, gold (got), id, count (sold)}. Nothing changes on a refusal.
static func sell(id: int, n: int, wallet: Wallet, inv: Inventory, universe: int = 1) -> Dictionary:
	var error := sell_refusal(id, n, inv, universe)
	if error != "" or not inv.take(id, n):
		return {"ok": false, "error": error if error != "" else "none", "gold": 0, "id": id, "count": 0}
	wallet.add(sell_price(id, universe) * n)
	return {"ok": true, "error": "", "gold": sell_price(id, universe) * n, "id": id, "count": n}


static func message(error: String) -> String:
	return _MESSAGES.get(error, FarmRules.message(error))   # M3 Task 10: the farm's own refusals


## "You got 4 Planks!", "You got an Iron Sword!", "Sold! +40 gold".
static func done_message(buying: bool, id: int, count: int, gold: int) -> String:
	if not buying:
		return Lang.t("Sold! %s gold") % GoldFormat.change(gold)
	var item_name := Lang.t(ItemIds.display_name(id))   # M3 Task 21a
	if count != 1:
		var plural := PACKS.has(id) and not item_name.ends_with("s")   # "2 Doors" (blocks stay "4 Stone")
		return Lang.t("You got %d %s%s!") % [count, item_name, Lang.plural_s(count) if plural else ""]
	var article := Lang.article(item_name)
	return Lang.t("You got %s %s!") % [article, item_name]

# --- Survivor games and crafting (owner feedback #33, spec §12.18) ---------------------------------------
# Build to Survive: building blocks come BUILD_BLOCKS_PER_GOLD a gold, except logs (charcoal, 3 logs + a fuel
# log, must never sell for more than its logs cost). (Monster Hunter's cheaper weapons went with #44.)

const BUILD_BLOCKS_PER_GOLD := 8


static func _game_blocks_per_gold(id: int, game: StringName) -> int:
	return BUILD_BLOCKS_PER_GOLD if game == &"build" and id != BlockIds.LOG else BLOCKS_PER_GOLD
# --- M3 Task 10: the Gold Farm ---

## Things nobody needs two of in a bag: tools and shields, and the Gold Farm (one per world).
static func one_only(id: int) -> bool:
	return is_tool_item(id) or id == ItemIds.FARM
