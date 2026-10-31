class_name ShopWords
extends RefCounted
## Every word about the shop (owner feedback #35, spec §18), in two kinds. The child's words are
## short, calm and never carry a price, a buy word, a currency or a nudge to ask; the one line about
## Plus that mentions a grown-up is said once per profile (plus_line). The grown-up's words are plain
## adult sentences (they may be longer) and always say the price before a purchase.

# --- The child's side ---
const PLUS_CARD := "EasyCraft Plus"
const PLUS_ONCE := "With EasyCraft Plus — ask a grown-up to look in the grown-up area."
const PLUS_AGAIN := "This universe comes with EasyCraft Plus."
const HINT_PLUS := "shop_plus_universe"   # ProfileData.hints_seen: the once-line was said
const WISH := "WISH"
const WISHED := "WISHED"
const WISH_FULL := "Your wish list is full."


## The line about a universe that comes with Plus: PLUS_ONCE the first time for this profile (it is
## remembered in hints_seen; the caller saves), PLUS_AGAIN after that.
static func plus_line(profile: ProfileData) -> String:
	if profile.hints_seen.has(HINT_PLUS):
		return PLUS_AGAIN
	if profile.hints_seen.size() < ProfileData.MAX_HINTS:
		profile.hints_seen.append(HINT_PLUS)
	return PLUS_ONCE


## Whether the once-line is still to be said (the menus show it under the cards once).
static func plus_once_due(profile: ProfileData) -> bool:
	return not profile.hints_seen.has(HINT_PLUS)


static func wished(on: bool) -> String:
	return "It's on your wish list." if on else "It's off your wish list."


## A pack item's line in the avatar editor: where it comes from, nothing more.
static func pack_line(product: String) -> String:
	return Lang.t("Part of the %s.") % ShopCatalog.product_name(product) if product != ShopCatalog.PLUS \
		else "Comes with EasyCraft Plus."


# --- The grown-up's side ---
const TITLE_TRUST := "Everything here is optional: the game is complete without it."
const TRUST := "No ads. Nothing random. No timers. You see every price and every item before you pay, and what you buy stays on this Google account."
const TEST_STORE := "Test store: nothing is charged (a developer build)."
const STORE_OFF := "The shop isn't open in this version yet. Nothing can be bought, and the whole game still works."
const ONE_TIME := "paid once"
const OWNED_WORD := "Owned"
const RESTORING := "Checking your purchases..."
const WAITING := "One moment..."


## What a finished purchase says to the grown-up.
static func result(status: StringName, product: String) -> String:
	var name := ShopCatalog.product_name(product)
	match status:
		Billing.PAID:
			return Lang.t("Thank you! %s is ready. Everything it has shows in the game now.") % name
		Billing.CANCELLED:
			return "Cancelled. Nothing was charged."
		Billing.PENDING:
			return Lang.t("The payment is waiting to be finished. %s opens as soon as it is paid.") % name
		Billing.OWNED_ALREADY:
			return Lang.t("%s was bought before on this Google account. It is back now.") % name
	return "That didn't work, and nothing was charged. Please try again later."


## Why a purchase couldn't start (ShopService.buy).
static func refusal(status: StringName) -> String:
	match status:
		ShopService.OWNED:
			return "You own this already."
		ShopService.NO_STORE:
			return STORE_OFF
		ShopService.BUSY:
			return "The store is still busy with the last purchase."
		ShopService.NEEDS_GATE:
			return "Purchases are only made in the grown-up area."
	return "This isn't for sale."


static func restored(ok: bool, added: Array) -> String:
	if not ok:
		return "The store couldn't be reached. Nothing was changed; try again later."
	if added.is_empty():
		return "All your purchases are here."
	var names: Array[String] = []
	for id: String in added:
		names.append(ShopCatalog.product_name(id))
	return Lang.t("Restored: %s.") % ", ".join(names)
