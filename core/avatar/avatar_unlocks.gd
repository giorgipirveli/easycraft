class_name AvatarUnlocks
extends RefCounted
## The one rule for avatar items' price and ownership (M3 Task 9; spec §5.9, §6). Items are
## account-wide: the profile's `cosmetics` lists what was bought or earned (free items are never
## listed). Gold items have a fixed price in Survivor gold; earned items (achievements, bosses,
## secrets) and code items can't be bought at any price. Nothing is random.
##
## Two callers spend gold: the main menu's editor changes the profile directly (buy), and in a
## Survivor world the host decides (Session.request_cosmetic_buy -> gold_spend), after check_buy.

const OK := &"ok"
const OWNED := &"owned"
const NOT_ENOUGH := &"not_enough"
const NOT_FOR_SALE := &"not_for_sale"
const UNKNOWN := &"unknown"

const MAX_OWNED := 512
## The default of each single-item slot (what an item that isn't owned is swapped for).
const DEFAULTS := {"face": &"smile", "hair": &"none", "hat": &"none", "cape": &"none", "wings": &"none",
	"trail": &"none", "outfit": &"none", "clothes": &"none"}


## Owner 36: an earned costume owns everything it wears (CostumeRules.gives).
static func is_owned(id: String, owned: Array) -> bool:
	return AvatarCatalog.is_free(id) or (AvatarCatalog.ITEMS.has(id) and (owned.has(id) or CostumeRules.gives(id, owned)))


## Whether `id` can be bought now with `gold`: OK, OWNED, NOT_FOR_SALE (free, earned or code),
## NOT_ENOUGH or UNKNOWN.
static func check_buy(id: String, owned: Array, gold: int) -> StringName:
	if not AvatarCatalog.is_item(id):
		return UNKNOWN
	if is_owned(id, owned):
		return OWNED
	if AvatarCatalog.ITEMS[id].kind != AvatarCatalog.GOLD:
		return NOT_FOR_SALE
	if gold < AvatarCatalog.price(id):
		return NOT_ENOUGH
	return OK


## Buys `id` with the profile's Survivor gold (outside a world: the main menu). The caller saves.
static func buy(profile: ProfileData, id: String) -> StringName:
	var status := check_buy(id, profile.cosmetics, profile.survivor_gold)
	if status != OK:
		return status
	var wallet := Wallet.new(profile.survivor_gold)
	if not wallet.spend(AvatarCatalog.price(id)):
		return NOT_ENOUGH
	profile.survivor_gold = wallet.balance
	profile.cosmetics.append(id)
	return OK


## Gives `id` to the profile (bought through the host, earned, or a code). False for anything that
## isn't a real item. Giving what is already owned is fine (nothing changes).
static func grant(profile: ProfileData, id: String) -> bool:
	if not AvatarCatalog.ITEMS.has(id):
		return false
	if not is_owned(id, profile.cosmetics) and profile.cosmetics.size() < MAX_OWNED:
		profile.cosmetics.append(id)
	return true


## Something happened (AvatarCatalog.EARN_*): gives every item earned by it that the profile didn't
## have yet, and returns those (for a "New!" message). The caller saves.
static func earn(profile: ProfileData, event: StringName) -> Array[String]:
	var got: Array[String] = []
	for id: String in AvatarCatalog.ITEMS:
		var item: Dictionary = AvatarCatalog.ITEMS[id]
		if item.get("earn", &"") == event and not is_owned(id, profile.cosmetics):
			grant(profile, id)
			got.append(id)
	return got


## Why an item is locked, for the editor: its price, how to earn it, or "" when it is free.
static func lock_reason(id: String) -> String:
	if not AvatarCatalog.ITEMS.has(id):
		return ""
	var item: Dictionary = AvatarCatalog.ITEMS[id]
	match item.kind:
		AvatarCatalog.GOLD:
			return Lang.t("%d gold") % AvatarCatalog.price(id)
		AvatarCatalog.CODE:
			return AvatarCatalog.CODE_REASON
		AvatarCatalog.PACK:
			return ShopWords.pack_line(ShopCatalog.pack_of(id))   # Owner 35: where it comes from, no price
		AvatarCatalog.FREE:
			return ""
		AvatarCatalog.IN_COSTUME:
			return CostumeRules.line(StringName(item.get("costume", "")))   # Owner 36: which costume brings it, and how
	return str(AvatarCatalog.EARN_REASONS.get(item.get("earn", &""), ""))


## A short line for the player after trying to buy `id`.
static func message(status: StringName, id: String, gold: int) -> String:
	match status:
		OK:
			return Lang.t("You got the %s!") % Lang.t(AvatarCatalog.display_name(id))
		OWNED:
			return "It's yours already!"
		NOT_ENOUGH:
			return Lang.t("You need %d more gold.") % maxi(AvatarCatalog.price(id) - gold, 1)
		NOT_FOR_SALE:
			return lock_reason(id)
	return "That item doesn't exist."


## The look with everything not owned taken off (a saved or tried-on look): each such slot goes back
## to its default, and the wheel keeps only owned emotes (filled up from the free set).
static func wearable(look: AvatarLook, owned: Array) -> AvatarLook:
	var worn := look.duplicate()
	for field: String in DEFAULTS:
		var id := AvatarCatalog.item_id(AvatarLook.FIELDS[field], worn.get(field))
		if not is_owned(id, owned):
			worn.set(field, DEFAULTS[field])
	var wheel: Array[StringName] = worn.emotes.duplicate()
	for i in wheel.size():
		if not is_owned(AvatarCatalog.item_id(AvatarCatalog.EMOTE, wheel[i]), owned):
			wheel[i] = &""
	var pool := AvatarCatalog.DEFAULT_WHEEL + AvatarCatalog.items_in(AvatarCatalog.EMOTE)
	for i in wheel.size():
		if wheel[i] != &"":
			continue
		for e: StringName in pool:
			if not wheel.has(e) and is_owned(AvatarCatalog.item_id(AvatarCatalog.EMOTE, e), owned):
				wheel[i] = e
				break
	worn.emotes = wheel
	return worn


## The profile's owned list from saved data: known, non-free item ids only, no repeats, capped.
static func sanitize_owned(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return out
	for v: Variant in value:
		if typeof(v) != TYPE_STRING or out.size() >= MAX_OWNED:
			continue
		var id := v as String
		if AvatarCatalog.ITEMS.has(id) and not AvatarCatalog.is_free(id) and not out.has(id):
			out.append(id)
	return out
