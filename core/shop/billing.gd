class_name Billing
extends RefCounted
## The billing adapter (owner feedback #35, spec §18.6): how the game talks to a store, whichever it is.
## This base class is "no store": nothing is available and every purchase fails at once (a release build
## before the owner sets product ids, the desktop). Backends: FakeBilling (tests and debug builds: a
## pretend store that never charges) and PlayBilling (Google Play through the Godot Google Play Billing
## plugin). ShopService is the only caller; results always come back later, as signals, like a real
## store's (never during the call).

## The store's prices, when it knows them: product id -> the price in the buyer's currency ("4,99 €").
signal products_loaded(prices: Dictionary)
## A purchase changed: {product, status, token, acknowledged}. May come any time (a pending payment
## finishing), not only after buy().
signal purchase_updated(result: Dictionary)
## What the store account owns: {ok, owned: [{product, token, acknowledged}], pending: [product ids]}.
signal restore_finished(result: Dictionary)

const PAID := &"paid"
const CANCELLED := &"cancelled"
const FAILED := &"failed"
const PENDING := &"pending"
const OWNED_ALREADY := &"owned_already"
const UNAVAILABLE := &"unavailable"


## A short name for the notes and logs ("none", "test", "google_play").
func store_name() -> String:
	return "none"


## Whether purchases can be made through this store now.
func is_available() -> bool:
	return false


## A pretend store (the grown-up area says so).
func is_test() -> bool:
	return false


func start() -> void:
	pass


func load_prices(_products: Array[String]) -> void:
	pass


## Opens the store's own purchase sheet for `product`; the answer comes as purchase_updated.
func buy(product: String) -> void:
	purchase_updated.emit.call_deferred({"product": product, "status": UNAVAILABLE, "token": "", "acknowledged": false})


## Asks the store what this account owns; the answer comes as restore_finished.
func restore() -> void:
	restore_finished.emit.call_deferred({"ok": false, "owned": [], "pending": []})


## Tells the store a purchase was delivered (Google Play refunds one-time purchases not acknowledged
## within three days).
func acknowledge(_token: String) -> void:
	pass
