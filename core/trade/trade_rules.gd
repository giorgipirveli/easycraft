class_name TradeRules
extends RefCounted
## Trading between players (owner #37, spec §14.23). Pure: what an offer may hold, the all-or-nothing swap, the
## under-13 friends rule and the words. The host runs these for every trade (Session section "Trading"); the
## open trades live in a TradeTable.
##
## An offer is {"items": {id: count}, "gold": int}: up to MAX_KINDS kinds of tradable things from the Survivor bag
## and at most gold_cap(u) Survivor gold. Nothing leaves a bag until the swap, which checks everything again
## (each still owns what they offered, each bag and purse has room) and then moves both sides at once, taking every
## give before adding anything, so nothing is ever copied or lost.

const MAX_KINDS := 8
const GOLD_BASE_MAX := 500
## A tap on another player's name tag reaches this far (eye to tag), and this close to the tag's middle.
const TAP_REACH := 8.0
const TAG_RADIUS := 0.9

const MESSAGES := {
	"survivor_only": "Trading is for Survivor worlds.",
	"self": "That's you!",
	"gone": "%s is not here any more.",
	"busy": "%s is busy trading. Try again soon.",
	"you_busy": "Finish your trade first.",
	"too_soon": "Wait a moment, then ask again.",
	"friends_only": "You can trade with %s once you are friends.",
	"asked": "You asked %s to trade. Waiting for an answer...",
	"said_no": "%s said no thanks. Maybe later!",
	"not_owned": "%s doesn't have all of that any more.",
	"not_owned_you": "You don't have all of that any more.",
	"no_room": "%s has no room for that many %s.",
	"no_room_you": "Your bag has no room for that many %s.",
	"gold_room": "%s can't carry that much gold.",
	"empty": "Put something in first!",
	"not_tradable": "That can't be traded.",
	"stopped": "The trade stopped. Nothing changed.",
	"left": "%s left, so the trade stopped. Nothing changed.",
	"changed": "Your bag changed, so your offer changed too.",
	"done": "Traded!",
}


## Things in the Survivor bag that may change hands: never a universe crystal (a child earns one by reaching its
## universe, and it opens that universe's portals) or the Gold Farm (one per world, its owner's).
static func tradable(id: int) -> bool:
	return Inventory.ownable(id) and not ItemIds.CRYSTALS.has(id) and id != ItemIds.FARM


## The most gold one trade may carry in universe u (under the online server's award limit).
static func gold_cap(universe: int = 1) -> int:
	return UniverseRules.price(GOLD_BASE_MAX, universe)


static func empty_offer() -> Dictionary:
	return {"items": {}, "gold": 0}


## An offer from whatever a game sent: items as [[id, count], ...] (or {id: count}); untradable things, bad
## entries and counts ≤ 0 are dropped, counts capped at Inventory.MAX_COUNT, at most MAX_KINDS kinds (the first
## ones), gold clamped to 0..gold_cap(universe).
static func clean_offer(items: Variant, gold: Variant, universe: int = 1) -> Dictionary:
	var pairs: Array = []
	if items is Dictionary:
		for k: Variant in items:
			pairs.append([k, items[k]])
	elif items is Array:
		pairs = items
	var out := {}
	for e: Variant in pairs:
		if not (e is Array) or (e as Array).size() != 2 or not _is_num(e[0]) or not _is_num(e[1]):
			continue
		var id := int(e[0])
		var n := int(clampf(float(e[1]), 0.0, float(Inventory.MAX_COUNT)))
		if n <= 0 or not tradable(id) or (not out.has(id) and out.size() >= MAX_KINDS):
			continue
		out[id] = mini(int(out.get(id, 0)) + n, Inventory.MAX_COUNT)
	var g := int(clampf(float(gold), 0.0, float(gold_cap(universe)))) if _is_num(gold) else 0
	return {"items": out, "gold": g}


static func is_empty(offer: Dictionary) -> bool:
	return (offer.items as Dictionary).is_empty() and int(offer.gold) <= 0


static func same(a: Dictionary, b: Dictionary) -> bool:
	return int(a.gold) == int(b.gold) and (a.items as Dictionary) == (b.items as Dictionary)


## The part of `offer` its owner still has (their bag `inv` and `gold`).
static func covered(offer: Dictionary, inv: Inventory, gold: int) -> Dictionary:
	var items := {}
	for id: int in offer.items:
		var n := mini(int(offer.items[id]), inv.count(id))
		if n > 0:
			items[id] = n
	return {"items": items, "gold": clampi(int(offer.gold), 0, maxi(gold, 0))}


## Why swapping offer_a (from a's bag and gold) with offer_b can't happen: {"error": key ("" = it can), "side":
## 0 (about a) or 1 (about b), "id": the thing it is about, or -1}.
static func swap_check(inv_a: Inventory, gold_a: int, offer_a: Dictionary, inv_b: Inventory, gold_b: int,
		offer_b: Dictionary) -> Dictionary:
	if is_empty(offer_a) and is_empty(offer_b):
		return _why("empty", 0)
	var sides := [[inv_a, gold_a, offer_a], [inv_b, gold_b, offer_b]]
	for s in 2:
		var inv: Inventory = sides[s][0]
		var offer: Dictionary = sides[s][2]
		for id: int in offer.items:
			if not tradable(id):
				return _why("not_tradable", s, id)
			if inv.count(id) < int(offer.items[id]):
				return _why("not_owned", s, id)
		if int(offer.gold) < 0 or int(sides[s][1]) < int(offer.gold):
			return _why("not_owned", s)
	for s in 2:   # side s receives what the other side gives
		var inv: Inventory = sides[s][0]
		var own: Dictionary = sides[s][2]
		var got: Dictionary = sides[1 - s][2]
		for id: int in got.items:
			if inv.count(id) - int(own.items.get(id, 0)) + int(got.items[id]) > Inventory.MAX_COUNT:
				return _why("no_room", s, id)
		if int(sides[s][1]) - int(own.gold) + int(got.gold) > Wallet.MAX_GOLD:
			return _why("gold_room", s)
	return _why("", 0)


## Moves both offers' things (after swap_check said yes): every give is taken first, then everything is added.
static func move_items(inv_a: Inventory, items_a: Dictionary, inv_b: Inventory, items_b: Dictionary) -> void:
	for id: int in items_a:
		inv_a.take(id, int(items_a[id]))
	for id: int in items_b:
		inv_b.take(id, int(items_b[id]))
	for id: int in items_a:
		inv_b.add(id, int(items_a[id]))
	for id: int in items_b:
		inv_a.add(id, int(items_b[id]))


## The whole swap on plain wallets (tests, and the rules the host follows with the real gold): all or nothing.
static func swap(inv_a: Inventory, wallet_a: Wallet, offer_a: Dictionary, inv_b: Inventory, wallet_b: Wallet,
		offer_b: Dictionary) -> Dictionary:
	var why := swap_check(inv_a, wallet_a.balance, offer_a, inv_b, wallet_b.balance, offer_b)
	if why.error != "":
		return {"ok": false, "error": why.error, "side": why.side, "id": why.id}
	wallet_a.spend(int(offer_a.gold))
	wallet_b.spend(int(offer_b.gold))
	wallet_b.add(int(offer_a.gold))
	wallet_a.add(int(offer_b.gold))
	move_items(inv_a, offer_a.items, inv_b, offer_b.items)
	return {"ok": true, "error": "", "side": 0, "id": -1}


## Online, a player under 13 trades only with players on their own friends list; LAN players are together at home
## and trade freely (like LAN chat). a_lists_b: b is on a's friends list. "" = allowed, else "friends_only".
static func age_refusal(band_a: StringName, band_b: StringName, a_lists_b: bool, b_lists_a: bool, online: bool) -> String:
	if not online:
		return ""
	if ChatRules.effective_band(band_a) != AgeBand.TEEN_PLUS and not a_lists_b:
		return "friends_only"
	if ChatRules.effective_band(band_b) != AgeBand.TEEN_PLUS and not b_lists_a:
		return "friends_only"
	return ""


## An offer as it travels: {"items": [[id, count], ...], "gold"}.
static func to_wire(offer: Dictionary) -> Dictionary:
	var items: Array = []
	for id: int in offer.items:
		items.append([id, int(offer.items[id])])
	return {"items": items, "gold": int(offer.gold)}


## "10 Stone and 5 gold", "1 Iron Sword", "nothing" (in the language the game speaks: no English plural "s").
static func describe(offer: Dictionary) -> String:
	var parts: Array[String] = []
	for id: int in offer.items:
		parts.append("%d %s" % [int(offer.items[id]), Lang.t(ItemIds.display_name(id))])
	if int(offer.gold) > 0:
		parts.append(Lang.t("%d gold") % int(offer.gold))
	if parts.is_empty():
		return Lang.t("nothing")
	if parts.size() == 1:
		return parts[0]
	return Lang.t("%s and %s") % [", ".join(parts.slice(0, parts.size() - 1)), parts[-1]]


## The chat line each trader gets after a swap.
static func log_line(other_name: String, gave: Dictionary, got: Dictionary) -> String:
	return Lang.t("You traded with %s: you gave %s; you got %s.") % [other_name, describe(gave), describe(got)]


## Kind words for a key; `who` fills a name, `id` a thing.
static func message(key: String, who: String = "", id: int = -1) -> String:
	var text := Lang.t(MESSAGES.get(key, MESSAGES.stopped))
	match key:
		"no_room":
			return text % [who, Lang.t(ItemIds.display_name(id))]
		"no_room_you":
			return text % Lang.t(ItemIds.display_name(id))
	return text % who if text.contains("%s") else text


static func _why(error: String, side: int, id: int = -1) -> Dictionary:
	return {"error": error, "side": side, "id": id}


static func _is_num(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v))
