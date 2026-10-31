class_name FakeBilling
extends Billing
## A pretend store for tests and debug builds (owner feedback #35, spec §18.6). Nothing is ever charged;
## the grown-up area says "Test store". `outcome` decides what the next purchase does (tests set it;
## debug builds always succeed). Its purchase history stands for the store account's: kept in memory,
## or in a file (`path`, debug builds: user://fake_store.json) so a new profile on the same device can
## restore what was "bought", like a reinstall with the same Google account.

var outcome: StringName = Billing.PAID
var history: Array[String] = []      # products this pretend account owns
var acknowledged := {}               # token -> true
var calls: Array[String] = []        # "buy:<product>", "restore" (tests read it)
var prices := {}                     # the store's price texts, if a test gives some
var restore_fails := false
var path := ""

var _pending: Array[String] = []


func _init(store_path: String = "") -> void:
	path = store_path
	if path != "":
		var text := JsonStore.read_text(path)
		var json := JSON.new()
		if text != "" and json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
			for v: Variant in (json.data as Dictionary).get("history", []):
				if typeof(v) == TYPE_STRING and ShopCatalog.is_product(v) and not history.has(v):
					history.append(v)


func store_name() -> String:
	return "test"


func is_available() -> bool:
	return true


func is_test() -> bool:
	return true


func load_prices(_products: Array[String]) -> void:
	if not prices.is_empty():
		products_loaded.emit.call_deferred(prices.duplicate())


func buy(product: String) -> void:
	calls.append("buy:" + product)
	if history.has(product):
		_answer(product, Billing.OWNED_ALREADY)
		return
	match outcome:
		Billing.PAID:
			_owned(product)
		Billing.PENDING:
			if not _pending.has(product):
				_pending.append(product)
			_answer(product, Billing.PENDING)
		_:
			_answer(product, outcome)


## Tests: a pending payment is paid now (the store tells the game, whatever screen is open).
func complete_pending(product: String) -> void:
	if _pending.has(product):
		_pending.erase(product)
		_owned(product)


func restore() -> void:
	calls.append("restore")
	if restore_fails:
		restore_finished.emit.call_deferred({"ok": false, "owned": [], "pending": []})
		return
	var owned: Array = []
	for product in history:
		var token := _token(product)
		owned.append({"product": product, "token": token, "acknowledged": acknowledged.has(token)})
	restore_finished.emit.call_deferred({"ok": true, "owned": owned, "pending": _pending.duplicate()})


func acknowledge(token: String) -> void:
	if token != "":
		acknowledged[token] = true


func _owned(product: String) -> void:
	if not history.has(product):
		history.append(product)
		_save()
	var token := _token(product)
	purchase_updated.emit.call_deferred({"product": product, "status": Billing.PAID, "token": token,
		"acknowledged": acknowledged.has(token)})


func _answer(product: String, status: StringName) -> void:
	purchase_updated.emit.call_deferred({"product": product, "status": status, "token": "", "acknowledged": false})


func _token(product: String) -> String:
	return "fake-" + product


func _save() -> void:
	if path != "":
		JsonStore.write_atomic(path, JSON.stringify({"history": history}))
