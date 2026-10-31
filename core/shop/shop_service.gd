class_name ShopService
extends RefCounted
## The shop's flow (owner feedback #35, spec §18): buys through a Billing store, records what was
## bought in the profile (Entitlements.grant: the product and its items), acknowledges it, restores the
## store account's purchases (at start and on RESTORE), and knows the store's prices. Session makes
## one (Session.shop()); the grown-up area's SHOP page (ShopPage) is the only place that buys.
##
## The parent gate in front of every purchase: buy() refuses unless the grown-up area is open
## (enter_grown_up_area / leave_grown_up_area, called by the area's shop page, which only exists after
## the gate was passed). A purchase that finishes later (a pending payment) is recorded whatever is on
## screen: recording is not buying.

## What was bought, the prices or the wish list changed (pages redraw).
signal changed
## A purchase started by buy() ended, or one finished later: Billing.PAID / CANCELLED / FAILED / PENDING /
## OWNED_ALREADY.
signal purchase_finished(product: String, status: StringName)
## A restore finished; `added`: the products it gave that the profile didn't have.
signal restore_done(ok: bool, added: Array)

## buy()'s answers.
const STARTED := &"started"
const NEEDS_GATE := &"needs_gate"
const OWNED := &"owned"
const NOT_FOR_SALE := &"not_for_sale"
const NO_STORE := &"no_store"
const BUSY := &"busy"

## Debug builds' pretend store keeps its purchase history here (a new profile can restore it).
const FAKE_STORE_PATH := "user://fake_store.json"

var billing: Billing
var profile: ProfileData
## Saves the profile (default: Profile.save).
var save_profile := Callable()
## The owner's server can check a receipt later (spec §18.6): (purchase {product, token, order_id,
## signature, original_json}) -> bool. Empty: trusted on the device (no server check yet).
var verify_receipt := Callable()
## The store's prices: product -> price text in the buyer's currency.
var prices := {}

var _grown_up := false
var _buying := ""
var _started := false


## The store for this build: Google Play when the APK has the plugin and the owner set product ids;
## the pretend store in debug builds; otherwise none (release builds before the shop opens).
static func billing_for_this_build() -> Billing:
	if OS.has_feature("android"):
		var play := PlayBilling.for_device()
		if play.is_available():
			return play
	if OS.is_debug_build():
		return FakeBilling.new(FAKE_STORE_PATH)
	return Billing.new()


func start() -> void:
	if _started:
		return
	_started = true
	billing.products_loaded.connect(_on_prices)
	billing.purchase_updated.connect(_on_purchase_updated)
	billing.restore_finished.connect(_on_restore_finished)
	billing.start()
	billing.load_prices(ShopCatalog.for_sale())


func store_open() -> bool:
	return billing != null and billing.is_available()


func is_test_store() -> bool:
	return billing != null and billing.is_test()


# --- The parent gate ---

## The grown-up area's shop page is showing (it exists only behind the parent gate).
func enter_grown_up_area() -> void:
	_grown_up = true


func leave_grown_up_area() -> void:
	_grown_up = false


func in_grown_up_area() -> bool:
	return _grown_up


# --- Buying ---

func owns(product: String) -> bool:
	return Entitlements.owns(profile.purchases, product)


func universe_open(u: int) -> bool:
	return Entitlements.universe_open(u, profile.purchases, store_open())


func busy() -> bool:
	return _buying != ""


## Why `product` can't be bought now (&"" = it can).
func refusal(product: String) -> StringName:
	if not ShopCatalog.is_for_sale(product):
		return NOT_FOR_SALE
	if owns(product):
		return OWNED
	if not _grown_up:
		return NEEDS_GATE
	if not store_open():
		return NO_STORE
	if busy():
		return BUSY
	return &""


## Opens the store's purchase sheet for `product`: STARTED, or why not. The end comes as purchase_finished.
func buy(product: String) -> StringName:
	var why := refusal(product)
	if why != &"":
		return why
	_buying = product
	billing.buy(product)
	return STARTED


func price_words(product: String) -> String:
	return str(prices.get(product, ShopCatalog.reference_price(product)))


func _on_prices(store_prices: Dictionary) -> void:
	for p: Variant in store_prices:
		if ShopCatalog.is_product(str(p)) and str(store_prices[p]) != "":
			prices[str(p)] = str(store_prices[p])
	changed.emit()


func _on_purchase_updated(r: Dictionary) -> void:
	var product := str(r.get("product", ""))
	var status: StringName = r.get("status", Billing.FAILED)
	if product == _buying:
		_buying = ""
	if not ShopCatalog.is_for_sale(product):
		return   # not about anything this game sells
	if status == Billing.PAID:
		var trusted: bool = await _verified(r)
		if not trusted:
			status = Billing.FAILED
		else:
			var one: Array[String] = [product]
			_record(one)
			if not bool(r.get("acknowledged", false)):
				billing.acknowledge(str(r.get("token", "")))
	elif status == Billing.OWNED_ALREADY:
		billing.restore()   # the store account has it: bring it back
	elif status == Billing.UNAVAILABLE:
		status = Billing.FAILED
	purchase_finished.emit(product, status)


# --- Restoring ---

## Asks the store what this account owns (RESTORE in the grown-up area).
func restore() -> void:
	billing.restore()


## At the game's start: the same, quietly, when there is a store.
func restore_at_start() -> void:
	if store_open():
		billing.restore()


func _on_restore_finished(r: Dictionary) -> void:
	var ok := bool(r.get("ok", false))
	var added: Array = []
	if ok:
		var products: Array[String] = []
		for o: Variant in r.get("owned", []):
			if not o is Dictionary:
				continue
			var trusted: bool = await _verified(o)
			if not trusted:
				continue
			var product := str(o.get("product", ""))
			if ShopCatalog.is_for_sale(product) and not owns(product) and not added.has(product):
				added.append(product)
			products.append(product)
			if not bool(o.get("acknowledged", false)):
				billing.acknowledge(str(o.get("token", "")))
		_record(products)
	restore_done.emit(ok, added)


## The receipt hook's answer (it may wait for the server: a coroutine is awaited).
func _verified(purchase: Dictionary) -> bool:
	if not verify_receipt.is_valid():
		return true
	var ok: Variant = await verify_receipt.call(purchase)
	return ok is bool and ok


## Grants products (only ever adds), takes gifts off the wish list, saves once when anything changed.
func _record(products: Array[String]) -> void:
	var before := profile.purchases.size()
	var got := 0
	for product in products:
		got += Entitlements.grant(profile, product).size()
	var wishes := profile.wishes.size()
	WishList.tidy(profile)
	if profile.purchases.size() != before or got > 0 or profile.wishes.size() != wishes:
		if save_profile.is_valid():
			save_profile.call()
		changed.emit()
