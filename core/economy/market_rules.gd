class_name MarketRules
extends RefCounted
## Market day (owner #37, spec §14.23). Pure. A Survivor world counts its days (a day begins at sunrise; the host
## counts them and saves the count in WorldMeta.market); every MARKET_EVERY-th day from FIRST_MARKET on is market
## day, when Nico the traveller's cart stands beside Tilly's stall from sunrise to sunset. He brings the same things
## every time, at fixed prices × 2^(u−1) (UniverseRules.price): the wild meadows' village blocks, which no shop sells
## and nobody buys back (so no loop can mint gold). No countdown, nothing gone for ever: it happens like weather.

const MARKET_EVERY := 7
const FIRST_MARKET := 2
const MAX_DAY := 1_000_000
## The cart this far (at least) from any other landmark by the spawn (the Totem, the hub circle, a helper, …).
const CLEAR_OF := 4.0
## The cart's candidate spots beside the stall, in the stall's own frame (x to its side, z behind), nearest first.
const SIDES: Array[float] = [4.0, 5.0, 6.0, 3.5]
const BACKS: Array[float] = [0.0, 1.0, -1.0, 2.0]

## id -> [gold for one purchase (Green Meadows), how many one purchase gives].
const STOCK := {
	BlockIds.STONE_BRICK: [2, 4], BlockIds.MOSSY_BRICK: [2, 4], BlockIds.PLASTER: [2, 4], BlockIds.ROOF_TILES: [2, 4],
	BlockIds.HAY: [2, 4], BlockIds.PATH: [2, 4], BlockIds.BIRCH_LOG: [2, 4], BlockIds.DARK_LOG: [2, 4],
	BlockIds.SAIL: [3, 4], BlockIds.FLOWERS: [3, 4], BlockIds.WHEAT: [3, 4], BlockIds.LILY_PAD: [3, 4],
	BlockIds.GLOW_MUSHROOM: [5, 2],
}

const TRADER_NAME := "Nico"
const SHOP_TITLE := "Nico's Market"
const ARRIVED := "Market day! Nico the traveller came to Tilly's stall."


## How many sunrises the clock passed going from `before` to `after` (a time of day, 0..1): 0 or 1 (a tick, a
## sleep or /time never moves it a whole day).
static func sunrises(before: float, after: float) -> int:
	var span := fposmod(after - before, 1.0)
	var to_sunrise := fposmod(DayCycle.SUNRISE - before, 1.0)
	return 1 if to_sunrise > 0.0 and to_sunrise <= span else 0


static func is_market_day(day: int) -> bool:
	return day >= FIRST_MARKET and (day - FIRST_MARKET) % MARKET_EVERY == 0


## The cart stands from sunrise to sunset of market day.
static func is_open(day: int, time_of_day: float) -> bool:
	var t := DayCycle.wrap_time(time_of_day)
	return is_market_day(day) and t >= DayCycle.SUNRISE and t < DayCycle.SUNSET


## What Nico brings, in the order his cards show (the same every market day).
static func stock() -> Array[int]:
	var ids: Array[int] = []
	for id: int in STOCK:
		if Inventory.ownable(id):
			ids.append(id)
	return ids


static func sells(id: int) -> bool:
	return STOCK.has(id) and Inventory.ownable(id)


## Gold for one purchase of id in universe u (0: not sold at the market).
static func price(id: int, universe: int = 1) -> int:
	return UniverseRules.price(int(STOCK[id][0]), universe) if sells(id) else 0


static func amount(id: int) -> int:
	return int(STOCK[id][1]) if sells(id) else 0


## Why buying id can't happen ("" = it can): a key for ShopRules.message.
static func buy_refusal(id: int, gold: int, inv: Inventory, universe: int = 1) -> String:
	if not sells(id):
		return "not_for_sale"
	if inv.count(id) + amount(id) > Inventory.MAX_COUNT:
		return "full"
	if gold < price(id, universe):
		return "gold"
	return ""


## Buys one purchase of id: {ok, error, gold (paid), id, count (got)}. Nothing changes on a refusal.
static func buy(id: int, wallet: Wallet, inv: Inventory, universe: int = 1) -> Dictionary:
	var error := buy_refusal(id, wallet.balance, inv, universe)
	if error == "" and not wallet.spend(price(id, universe)):
		error = "gold"
	if error != "":
		return {"ok": false, "error": error, "gold": 0, "id": id, "count": 0}
	inv.add(id, amount(id))
	return {"ok": true, "error": "", "gold": price(id, universe), "id": id, "count": amount(id)}


## Where the cart stands: beside Tilly's stall (her feet at `tilly`, her counter facing `yaw`), on dry ground no
## steeper than a block around it, no tree trunk next to it, CLEAR_OF from every landmark in `marks`. With no such
## spot, the first one beside her anyway (on the ground). {pos: Vector3 (feet, cell centre), yaw}.
static func cart_spot(tilly: Vector3, yaw: float, height_at: Callable, ground_ok: Callable, tree_at: Callable,
		marks: Array) -> Dictionary:
	var first := Vector2i.MAX
	for side: float in SIDES:
		for back: float in BACKS:
			for sign: float in [1.0, -1.0]:
				var off := Vector3(side * sign, 0.0, back).rotated(Vector3.UP, yaw)
				var c := Vector2i(floori(tilly.x + off.x), floori(tilly.z + off.z))
				if first == Vector2i.MAX:
					first = c
				if _clear(c, marks) and _good(c, height_at, ground_ok, tree_at):
					return _spot(c, yaw, height_at)
	return _spot(first, yaw, height_at)


## A saved market ({"day": n}); broken or missing values start at day 1.
static func clean(v: Variant) -> Dictionary:
	var day := 1
	if v is Dictionary:
		var d: Variant = (v as Dictionary).get("day")
		if typeof(d) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(d)):
			day = int(clampf(float(d), 1.0, float(MAX_DAY)))
	return {"day": day}


static func _clear(c: Vector2i, marks: Array) -> bool:
	var p := Vector2(c.x + 0.5, c.y + 0.5)
	for m: Variant in marks:
		if m is Vector3 and (m as Vector3).is_finite() and p.distance_to(Vector2((m as Vector3).x, (m as Vector3).z)) < CLEAR_OF:
			return false
	return true


static func _good(c: Vector2i, height_at: Callable, ground_ok: Callable, tree_at: Callable) -> bool:
	var h := int(height_at.call(c.x, c.y))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			if absi(int(height_at.call(c.x + dx, c.y + dz)) - h) > 1 or not ground_ok.call(c.x + dx, c.y + dz):
				return false
			if tree_at.call(c.x + dx, c.y + dz):
				return false
	return true


static func _spot(c: Vector2i, yaw: float, height_at: Callable) -> Dictionary:
	return {"pos": Vector3(c.x + 0.5, float(height_at.call(c.x, c.y)), c.y + 0.5), "yaw": yaw}
