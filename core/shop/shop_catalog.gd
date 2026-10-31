class_name ShopCatalog
extends RefCounted
## What EasyCraft sells (owner feedback #35, spec §18) — THE ONE TABLE the owner changes. Parents pay,
## for clear value, in the grown-up area behind the parent gate: EasyCraft Plus and cosmetic packs.
## Every product is a one-time unlock at a fixed price; there is no random, consumable, currency or
## timed kind, and nothing here makes anyone stronger or can be earned by playing (a pack's items
## exist only in it: AvatarCatalog kind PACK, with "pack": <product id>).
##
## Prices: `price_cents` is the reference price in US dollars, the one the owner sets for the product in
## Play Console; the grown-up sees the store's own price in their currency when the store answers
## (ShopService.price_words), this one otherwise (the fake store, a first start offline).

const PLUS := "plus"
const PACK_SKY := "pack_sky"
const PACK_OCEAN := "pack_ocean"
const PACK_STORYBOOK := "pack_storybook"   # a slot: owner #36's storybook costumes, if the owner sells them
const PACK_GLIDERS := "pack_gliders"       # a slot: glider looks, when gliders exist (M3 Task 14a)

## The only kind: bought once, kept for good (Play: a one-time, non-consumable product).
const ONE_TIME := &"one_time"
const KINDS: Array[StringName] = [ONE_TIME]

## Survivor universes free forever, by ladder name (UniverseRegistry.LADDER). Every other universe of the
## ladder — and every universe added to it later, like the Dragon Realm — comes with EasyCraft Plus.
const FREE_UNIVERSES: Array[StringName] = [&"meadows", &"desert"]

## id -> {name, kind, price_cents, ready (on sale; a slot is not), about (one line for the grown-up)}.
const PRODUCTS := {
	PLUS: {"name": "EasyCraft Plus", "kind": ONE_TIME, "price_cents": 499, "ready": true,
		"about": "Every Survivor universe after the first two, now and in later updates, and the Plus outfit set."},
	PACK_SKY: {"name": "Sky Pack", "kind": ONE_TIME, "price_cents": 199, "ready": true,
		"about": "Four looks for flying high: wings, a cape, a trail and a cap."},
	PACK_OCEAN: {"name": "Ocean Pack", "kind": ONE_TIME, "price_cents": 199, "ready": true,
		"about": "Four sea looks: a diving suit, a cape, a trail and a cap."},
	PACK_STORYBOOK: {"name": "Storybook Pack", "kind": ONE_TIME, "price_cents": 199, "ready": false,
		"about": "Costumes of storybook heroes (owner feedback #36)."},
	PACK_GLIDERS: {"name": "Glider Looks", "kind": ONE_TIME, "price_cents": 199, "ready": false,
		"about": "Looks for the glider (when gliders are in the game)."},
}

## Plus's extras that need the owner's server: never listed or sold until `ready`.
const PLUS_LATER := {
	"world_backup": {"name": "Worlds saved on the server", "ready": false},
	"friends_worlds": {"name": "Visiting friends' worlds while they are away", "ready": false},
}

## The owner's product ids in Play Console, per product ("" = not made yet). While any product on sale
## has none, the Google Play store stays off (PlayBilling) and the grown-up area says the shop isn't open.
const PLAY_IDS := {PLUS: "", PACK_SKY: "", PACK_OCEAN: "", PACK_STORYBOOK: "", PACK_GLIDERS: ""}

## Free forever (spec §18.2), shown in the grown-up area.
const FREE_FOREVER: Array[StringName] = [&"sandbox", &"first_universes", &"bots", &"lan", &"online_friends",
	&"earned_items", &"backup"]
const _FREE_WORDS := {
	&"sandbox": "Sandbox: every block and every building tool",
	&"bots": "Bot friends",
	&"lan": "Playing together at home (LAN)",
	&"online_friends": "Playing online with friends",
	&"earned_items": "The avatar editor's free set and everything earned in the game",
	&"backup": "The online backup of the player's profile",
}


static func ids() -> Array[String]:
	var out: Array[String] = []
	out.assign(PRODUCTS.keys())
	return out


static func is_product(id: String) -> bool:
	return PRODUCTS.has(id)


static func product(id: String) -> Dictionary:
	return PRODUCTS.get(id, {})


static func product_name(id: String) -> String:
	return str(product(id).get("name", ""))


## The products a grown-up can buy now, in table order (slots and unknown ids are not).
static func for_sale() -> Array[String]:
	var out: Array[String] = []
	for id: String in PRODUCTS:
		if bool(PRODUCTS[id].ready):
			out.append(id)
	return out


static func is_for_sale(id: String) -> bool:
	return is_product(id) and bool(PRODUCTS[id].ready)


## "US$4.99": the reference price in words.
static func reference_price(id: String) -> String:
	if not is_product(id):
		return ""
	var cents := int(PRODUCTS[id].price_cents)
	return "US$%d.%02d" % [floori(cents / 100.0), cents % 100]


# --- Universes ---

## Whether a universe with this ladder name comes with Plus (any name not free, even one not on the ladder yet).
static func needs_plus_name(ladder_name: StringName) -> bool:
	return not FREE_UNIVERSES.has(ladder_name)


## Whether Survivor universe u comes with Plus. Green Meadows never does, whatever the table says.
static func needs_plus(u: int) -> bool:
	if u <= UniverseRules.FIRST or SpaceRules.is_away(u):   # owner #55: the Moon and the planets are free (ruling 3); #78: Earth's too
		return false
	var n := UniverseRegistry.ladder_name(u)
	return n == &"" or needs_plus_name(n)


## Plus's universes on the ladder now, in order.
static func plus_universes() -> Array[int]:
	var out: Array[int] = []
	for u in range(UniverseRules.FIRST, UniverseRegistry.size() + 1):
		if needs_plus(u):
			out.append(u)
	return out


# --- Items ---

## A product's avatar items, in catalog order (AvatarCatalog items of kind PACK naming it).
static func items_of(id: String) -> Array[String]:
	var out: Array[String] = []
	for item: String in AvatarCatalog.ITEMS:
		if str(AvatarCatalog.ITEMS[item].get("pack", "")) == id and id != "":
			out.append(item)
	return out


## The product an avatar item comes in ("" = not sold).
static func pack_of(item: String) -> String:
	var d: Dictionary = AvatarCatalog.ITEMS.get(item, {})
	return str(d.get("pack", "")) if d.get("kind", &"") == AvatarCatalog.PACK else ""


## Everything a product gives, one line each, for the grown-up's page: Plus's universes by name, the
## later extras once ready, and every item.
static func contents(id: String) -> Array[String]:
	var out: Array[String] = []
	if id == PLUS:
		var names: Array[String] = []
		for u in plus_universes():
			names.append(UniverseRegistry.display_name(u))
		out.append(Lang.t("New Survivor universes: %s, and each new one added later") % ", ".join(names))
		for key: String in PLUS_LATER:
			if bool(PLUS_LATER[key].ready):
				out.append(str(PLUS_LATER[key].name))
	for item in items_of(id):
		out.append(AvatarCatalog.display_name(item))
	return out


static func free_words(key: StringName) -> String:
	if key == &"first_universes":
		var names: Array[String] = []
		for u in range(UniverseRules.FIRST, UniverseRegistry.size() + 1):
			if not needs_plus(u):
				names.append(UniverseRegistry.display_name(u))
		return Lang.t("Survivor in %s, with their bosses") % " and ".join(names)
	return str(_FREE_WORDS.get(key, ""))


# --- Google Play ---

## Whether every product on sale has a Play product id (the Play store stays off until then).
static func play_ready(play_ids: Dictionary = PLAY_IDS) -> bool:
	var sale := for_sale()
	if sale.is_empty():
		return false
	for id in sale:
		if str(play_ids.get(id, "")) == "":
			return false
	return true


static func play_id(id: String, play_ids: Dictionary = PLAY_IDS) -> String:
	return str(play_ids.get(id, ""))


## Our product id for a Play product id ("" = not ours).
static func from_play_id(pid: String, play_ids: Dictionary = PLAY_IDS) -> String:
	if pid == "":
		return ""
	for id: String in play_ids:
		if str(play_ids[id]) == pid and is_product(id):
			return id
	return ""
