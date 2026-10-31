class_name SavingRules
extends RefCounted
## The saving list, "SAVE UP" (M3 Task 21b; research R3): gold things the child wants — a tool or a block at
## Tilly's (SHOP, an item id) or an avatar item with a gold price (LOOK) — each with a have/need bar of the
## child's Survivor gold. A goal the child chose: it never spends gold, never nags, never counts down. Kept in
## the profile (WonderData.saving). Owner #35's wish list is the other list (things a grown-up could give: pack
## items); a pack item never goes on this one and a gold item never on that one.

const MAX := 6
const SHOP := "shop"
const LOOK := "look"

## The button on Tilly's shop and in the avatar editor, off and on.
const SAVE_WORD := "SAVE UP"
const SAVING_WORD := "SAVING ✓"
## The book's page.
const TITLE := "Saving up"
const EMPTY_WORDS := "Tap SAVE UP at Tilly's shop or in the avatar editor on something you would like."
const ON_WORDS := "It's on your saving list!"
const OFF_WORDS := "Taken off your saving list."
const FULL_WORDS := "Your saving list is full."


static func entry(kind: String, id: String) -> Dictionary:
	return {"kind": kind, "id": id}


## A saved entry from the profile: {kind, id}, or {} for anything that isn't a gold thing (JSON numbers are
## read back as the item they were).
static func clean(v: Variant) -> Dictionary:
	if not v is Dictionary:
		return {}
	var kind: Variant = (v as Dictionary).get("kind")
	var id: Variant = (v as Dictionary).get("id")
	if typeof(id) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(id)) and float(id) == floorf(float(id)):
		id = str(int(id))
	if not (kind is String and id is String) or not can_save(kind, id):
		return {}
	return entry(kind, id)


## Whether (kind, id) is a gold thing a child can save for — and, with a profile, not owned already.
static func can_save(kind: String, id: String, profile: ProfileData = null) -> bool:
	match kind:
		SHOP:
			return id.is_valid_int() and ShopRules.for_sale(id.to_int())
		LOOK:
			if not AvatarCatalog.ITEMS.has(id) or AvatarCatalog.ITEMS[id].kind != AvatarCatalog.GOLD:
				return false
			return profile == null or not AvatarUnlocks.is_owned(id, profile.cosmetics)
	return false


static func has(d: WonderData, kind: String, id: String) -> bool:
	for e in d.saving:
		if e.kind == kind and e.id == id:
			return true
	return false


static func remove(d: WonderData, kind: String, id: String) -> void:
	for i in range(d.saving.size() - 1, -1, -1):
		if d.saving[i].kind == kind and d.saving[i].id == id:
			d.saving.remove_at(i)


## On if it was off, off if it was on; returns whether it is on the list now (false also when it can't go on:
## not a gold thing, owned, the list full). The caller saves.
static func toggle(d: WonderData, kind: String, id: String, profile: ProfileData = null) -> bool:
	if has(d, kind, id):
		remove(d, kind, id)
		return false
	if not can_save(kind, id, profile) or d.saving.size() >= MAX:
		return false
	d.saving.append(entry(kind, id))
	return true


## The gold it takes: Tilly's price in universe `universe` (her prices double each universe) or the avatar
## item's fixed price.
static func price(e: Dictionary, universe: int = 1, game: StringName = &"classic") -> int:
	if e.get("kind") == SHOP:
		return ShopRules.price(str(e.id).to_int(), universe, game)
	return AvatarCatalog.price(str(e.get("id", "")))


## Vector2i(the gold toward it, the gold it takes): the bar stops when it is full.
static func have_need(e: Dictionary, gold: int, universe: int = 1, game: StringName = &"classic") -> Vector2i:
	var need := price(e, universe, game)
	return Vector2i(clampi(gold, 0, need), need)


## "120 / 400", and a tick when it is full.
static func bar_words(hn: Vector2i) -> String:
	return "%s / %s%s" % [GoldFormat.short(hn.x), GoldFormat.short(hn.y), " ✓" if hn.y > 0 and hn.x >= hn.y else ""]


## Owned avatar items leave the list (the wish came true).
static func tidy(d: WonderData, profile: ProfileData) -> void:
	for i in range(d.saving.size() - 1, -1, -1):
		var e: Dictionary = d.saving[i]
		if e.kind == LOOK and AvatarUnlocks.is_owned(e.id, profile.cosmetics):
			d.saving.remove_at(i)


static func name_of(e: Dictionary) -> String:
	if e.get("kind") == SHOP:
		return ItemIds.display_name(str(e.id).to_int())
	return AvatarCatalog.display_name(str(e.get("id", "")))


## Where it is found.
static func where_words(e: Dictionary) -> String:
	return "At Tilly's shop" if e.get("kind") == SHOP else "In the avatar editor"
