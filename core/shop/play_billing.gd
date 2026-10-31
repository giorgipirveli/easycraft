class_name PlayBilling
extends Billing
## Google Play through the Godot Google Play Billing plugin (owner feedback #35, spec §18.6):
## github.com/godot-sdk-integrations/godot-google-play-billing, MIT, 3.3.0 (Play Billing Library 9.1),
## Godot 4.2+. The plugin is an Android v2 plugin, so it is only in APKs built with the Gradle build and
## the plugin installed (docs/devlog/parts/owner-35-shop.md says how); this adapter talks to its engine
## singleton "GodotGooglePlayBilling" directly (the same calls as the plugin's own BillingClient.gd),
## so the game needs none of the plugin's files until the owner turns it on. It is **off** — never
## available — without the singleton or without Play product ids for every product on sale
## (ShopCatalog.PLAY_IDS). All products are one-time ("inapp"), acknowledged after delivery.

const SINGLETON := "GodotGooglePlayBilling"
const INAPP := "inapp"
## The plugin's BillingResponseCode values used here.
const CODE_OK := 0
const CODE_USER_CANCELED := 1
const CODE_ITEM_ALREADY_OWNED := 7
## The plugin's PurchaseState values.
const STATE_PURCHASED := 1
const STATE_PENDING := 2

var play_ids := {}
var _plugin: Object
var _started := false
var _connected := false
var _restore_wanted := false
var _buying := ""


## `plugin`: the plugin's singleton (tests give a stand-in); `ids`: our product id -> Play product id.
func _init(plugin: Object = null, ids: Dictionary = ShopCatalog.PLAY_IDS) -> void:
	_plugin = plugin
	play_ids = ids


## The Play backend for this device: the singleton when the APK has the plugin (Android only).
static func for_device() -> PlayBilling:
	var plugin: Object = Engine.get_singleton(SINGLETON) if Engine.has_singleton(SINGLETON) else null
	return PlayBilling.new(plugin)


func store_name() -> String:
	return "google_play"


func is_available() -> bool:
	return _plugin != null and ShopCatalog.play_ready(play_ids)


func start() -> void:
	if _started or not is_available():
		return
	_started = true
	_plugin.call("initPlugin")
	_plugin.connect("connected", _on_connected)
	_plugin.connect("disconnected", _on_disconnected)
	_plugin.connect("connect_error", _on_connect_error)
	_plugin.connect("query_product_details_response", _on_product_details)
	_plugin.connect("query_purchases_response", _on_purchases)
	_plugin.connect("on_purchase_updated", _on_purchase_updated)
	_plugin.call("startConnection")


func load_prices(_products: Array[String]) -> void:
	if _connected:
		_query_details()


func buy(product: String) -> void:
	var pid := ShopCatalog.play_id(product, play_ids)
	if not _connected or pid == "":
		_answer(product, Billing.FAILED, true)
		return
	_buying = product
	var launched: Variant = _plugin.call("purchase", pid, "", "", false)
	var code := int((launched as Dictionary).get("response_code", -1)) if launched is Dictionary else -1
	if code != CODE_OK:
		_buying = ""
		_answer(product, Billing.CANCELLED if code == CODE_USER_CANCELED else Billing.FAILED, true)


func restore() -> void:
	if not is_available():
		super.restore()
		return
	if _connected:
		_plugin.call("queryPurchases", INAPP, false)
	else:
		_restore_wanted = true   # asked at the connection (every start restores anyway)


func acknowledge(token: String) -> void:
	if _connected and token != "":
		_plugin.call("acknowledgePurchase", token)


func _on_connected() -> void:
	_connected = true
	_query_details()
	_restore_wanted = false
	_plugin.call("queryPurchases", INAPP, false)   # restore at every start: a reinstall, a pending payment paid


func _on_disconnected() -> void:
	_connected = false
	if _buying != "":
		_answer(_buying, Billing.FAILED, false)
		_buying = ""


func _on_connect_error(_code: int, _message: String) -> void:
	_connected = false


func _query_details() -> void:
	var list := PackedStringArray()
	for id in ShopCatalog.for_sale():
		list.append(ShopCatalog.play_id(id, play_ids))
	_plugin.call("queryProductDetails", list, INAPP)


func _on_product_details(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) != CODE_OK:
		return
	var prices := {}
	for d: Variant in response.get("product_details", []):
		if not d is Dictionary:
			continue
		var product := ShopCatalog.from_play_id(str(d.get("product_id", "")), play_ids)
		var price := price_of(d)
		if product != "" and price != "":
			prices[product] = price
	products_loaded.emit(prices)


## The formatted one-time price of a product details dictionary ("" = none).
static func price_of(details: Dictionary) -> String:
	var offers: Variant = details.get("one_time_purchase_offer_details_list")
	if offers is Array and not (offers as Array).is_empty() and offers[0] is Dictionary:
		return str(offers[0].get("formatted_price", ""))
	var one: Variant = details.get("one_time_purchase_offer_details")   # older plugin versions
	return str(one.get("formatted_price", "")) if one is Dictionary else ""


func _on_purchase_updated(response: Dictionary) -> void:
	var code := int(response.get("response_code", -1))
	var buying := _buying
	_buying = ""
	if code == CODE_OK:
		var answered := false
		for p: Variant in response.get("purchases", []):
			var r := read_purchase(p, play_ids)
			if r.is_empty():
				continue
			answered = answered or r.product == buying
			purchase_updated.emit(r)
		if not answered and buying != "":
			_answer(buying, Billing.FAILED, false)
	elif code == CODE_ITEM_ALREADY_OWNED:
		if buying != "":
			_answer(buying, Billing.OWNED_ALREADY, false)
		_plugin.call("queryPurchases", INAPP, false)   # picks it up as a restore
	elif buying != "":
		_answer(buying, Billing.CANCELLED if code == CODE_USER_CANCELED else Billing.FAILED, false)


func _on_purchases(response: Dictionary) -> void:
	var result := {"ok": int(response.get("response_code", -1)) == CODE_OK, "owned": [], "pending": []}
	if result.ok:
		for p: Variant in response.get("purchases", []):
			var r := read_purchase(p, play_ids)
			if r.is_empty():
				continue
			if r.status == Billing.PAID:
				result.owned.append({"product": r.product, "token": r.token, "acknowledged": r.acknowledged})
			elif r.status == Billing.PENDING:
				result.pending.append(r.product)
	restore_finished.emit(result)


## One of the plugin's purchase dictionaries as {product, status, token, acknowledged} ({} = not ours,
## or a state that is neither paid nor pending).
static func read_purchase(p: Variant, ids: Dictionary) -> Dictionary:
	if not p is Dictionary:
		return {}
	var product := ""
	for pid: Variant in p.get("product_ids", []):
		product = ShopCatalog.from_play_id(str(pid), ids)
		if product != "":
			break
	var state := int(p.get("purchase_state", 0))
	if product == "" or state not in [STATE_PURCHASED, STATE_PENDING]:
		return {}
	return {"product": product, "status": Billing.PAID if state == STATE_PURCHASED else Billing.PENDING,
		"token": str(p.get("purchase_token", "")), "acknowledged": bool(p.get("is_acknowledged", false)),
		"order_id": str(p.get("order_id", "")), "signature": str(p.get("signature", "")),
		"original_json": str(p.get("original_json", ""))}


func _answer(product: String, status: StringName, deferred: bool) -> void:
	var r := {"product": product, "status": status, "token": "", "acknowledged": false}
	if deferred:
		purchase_updated.emit.call_deferred(r)
	else:
		purchase_updated.emit(r)
