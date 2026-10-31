class_name WishList
extends RefCounted
## The child's wish list (owner feedback #35, spec §18.5; research R3): things a grown-up could give —
## pack items and EasyCraft Plus — marked in the avatar editor with WISH, kept in the profile's `wishes`,
## and shown in the grown-up area (behind the parent gate) with what each is and its price. The child
## side never shows a price or a buy button, and nothing ever tells the child to ask. Gold items stay
## the child's own goals (M3 Task 21b's have/need bar): they are never sold, so never wished here.

const MAX := 24
## How a grown-up can give a wish (the grown-up area's row).
const GIFT := &"gift"
const OWNED := &"owned"


## Whether `id` can go on the list: an item of a pack on sale, or a product on sale — and, with a
## profile, not owned already.
static func can_wish(id: String, profile: ProfileData = null) -> bool:
	var product := product_for(id)
	if product == "" or not ShopCatalog.is_for_sale(product):
		return false
	if profile == null:
		return true
	if ShopCatalog.is_product(id):
		return not Entitlements.owns(profile.purchases, id)
	return not AvatarUnlocks.is_owned(id, profile.cosmetics)


## The product that gives `id` (an item's pack, or the product itself); "" when nothing sells it.
static func product_for(id: String) -> String:
	if ShopCatalog.is_product(id):
		return id
	return ShopCatalog.pack_of(id)


static func has(profile: ProfileData, id: String) -> bool:
	return profile.wishes.has(id)


## Puts `id` on the list; false when it can't go there (not giftable, owned, the list is full).
static func add(profile: ProfileData, id: String) -> bool:
	if has(profile, id):
		return true
	if not can_wish(id, profile) or profile.wishes.size() >= MAX:
		return false
	profile.wishes.append(id)
	return true


static func remove(profile: ProfileData, id: String) -> void:
	profile.wishes.erase(id)


## On if it was off, off if it was on; returns whether it is on the list now. The caller saves.
static func toggle(profile: ProfileData, id: String) -> bool:
	if has(profile, id):
		remove(profile, id)
		return false
	return add(profile, id)


## Takes what arrived (a gift, a restore) off the list.
static func tidy(profile: ProfileData) -> void:
	var keep: Array[String] = []
	for id in profile.wishes:
		if can_wish(id, profile):
			keep.append(id)
	profile.wishes = keep


## The grown-up area's rows, in the child's order: {id, name, product, product_name, price, how}. `prices`:
## the store's own prices (ShopService.prices); the reference price otherwise.
static func for_grown_up(profile: ProfileData, prices: Dictionary = {}) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in profile.wishes:
		var product := product_for(id)
		if product == "":
			continue
		var name := ShopCatalog.product_name(id) if ShopCatalog.is_product(id) else AvatarCatalog.display_name(id)
		out.append({"id": id, "name": name, "product": product, "product_name": ShopCatalog.product_name(product),
			"price": str(prices.get(product, ShopCatalog.reference_price(product))),
			"how": OWNED if Entitlements.owns(profile.purchases, product) else GIFT})
	return out


## The profile's wishes from saved data: giftable ids, once each, at most MAX.
static func sanitize(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return out
	for v: Variant in value:
		if typeof(v) == TYPE_STRING and can_wish(v) and not out.has(v) and out.size() < MAX:
			out.append(v)
	return out
