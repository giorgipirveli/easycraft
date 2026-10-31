class_name Entitlements
extends RefCounted
## What a grown-up's purchase opens (owner feedback #35, spec §18), as pure rules over the profile's
## `purchases` (ShopCatalog product ids, account-wide). A purchase is recorded once and gives its
## pack's avatar items (AvatarUnlocks.grant), so the avatar editor, the look sync and the backup work
## as for any owned item. Nothing is ever taken away here: a restore only adds (the refund ruling).

const MAX := 32
## The travel refusal key for a universe that comes with Plus (sandbox.travel_to says ShopWords.plus_line).
const NEEDS_PLUS := "plus"


static func owns(owned: Array, product: String) -> bool:
	return product != "" and owned.has(product)


## Whether Survivor universe u may be played: the free ones always, Plus's with Plus.
## `store_open`: this build can sell (Session.shop().store_open()). Without a store nothing is locked behind Plus:
## a release build before Play Billing is set up keeps every universe open, as before the shop (lead, merge).
static func universe_open(u: int, owned: Array, store_open: bool = true) -> bool:
	return not store_open or not ShopCatalog.needs_plus(u) or owns(owned, ShopCatalog.PLUS)


## "" or NEEDS_PLUS: why travelling to universe u (already unlocked by its boss) can't happen.
static func travel_refusal(u: int, owned: Array, store_open: bool = true) -> String:
	return "" if universe_open(u, owned, store_open) else NEEDS_PLUS


## Records `product` (once) and gives its items. Returns the items that are new to the profile (for a
## "New!" line). Unknown products and slots that are not for sale give nothing. The caller saves.
static func grant(profile: ProfileData, product: String) -> Array[String]:
	var got: Array[String] = []
	if not ShopCatalog.is_for_sale(product):
		return got
	if not profile.purchases.has(product) and profile.purchases.size() < MAX:
		profile.purchases.append(product)
	for item in ShopCatalog.items_of(product):
		if not AvatarUnlocks.is_owned(item, profile.cosmetics):
			AvatarUnlocks.grant(profile, item)
			got.append(item)
	return got


## The profile's purchases from saved data: known product ids, once each.
static func sanitize(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return out
	for v: Variant in value:
		if typeof(v) == TYPE_STRING and ShopCatalog.is_product(v) and not out.has(v) and out.size() < MAX:
			out.append(v)
	return out
