extends GutTest
## Owner feedback #35 (spec §18.6): the Google Play backend of the Billing adapter. It talks to the
## Godot Google Play Billing plugin's singleton (3.x API: connected, query_product_details_response,
## on_purchase_updated, query_purchases_response, acknowledge_purchase_response; startConnection,
## queryProductDetails, purchase, queryPurchases, acknowledgePurchase). No device here: a stand-in
## singleton with the same names answers the way the plugin's docs say. Off without product ids.

const IDS := {"plus": "ec_plus", "pack_sky": "ec_sky", "pack_ocean": "ec_ocean"}


class FakeSingleton extends Object:
	signal connected
	signal disconnected
	signal connect_error(code: int, message: String)
	signal query_product_details_response(response: Dictionary)
	signal query_purchases_response(response: Dictionary)
	signal on_purchase_updated(response: Dictionary)
	signal acknowledge_purchase_response(response: Dictionary)
	var calls: Array = []
	var launch_code := 0

	func initPlugin() -> void:
		calls.append(["initPlugin"])

	func startConnection() -> void:
		calls.append(["startConnection"])

	func queryProductDetails(list: PackedStringArray, kind: String) -> void:
		calls.append(["queryProductDetails", Array(list), kind])

	func queryPurchases(kind: String, suspended: bool) -> void:
		calls.append(["queryPurchases", kind, suspended])

	func purchase(id: String, option: String, offer: String, personalized: bool) -> Dictionary:
		calls.append(["purchase", id, option, offer, personalized])
		return {"response_code": launch_code, "debug_message": ""}

	func acknowledgePurchase(token: String) -> void:
		calls.append(["acknowledgePurchase", token])


var plugin: FakeSingleton


func before_each() -> void:
	plugin = FakeSingleton.new()


func after_each() -> void:
	plugin.free()


func _billing() -> PlayBilling:
	var b := PlayBilling.new(plugin, IDS)
	b.start()
	return b


func _purchase(pid: String, state: int, token: String = "tok", acked: bool = false) -> Dictionary:
	return {"product_ids": PackedStringArray([pid]), "purchase_state": state, "purchase_token": token,
		"is_acknowledged": acked, "order_id": "GPA.1", "signature": "sig", "original_json": "{}"}


func test_it_is_off_without_the_plugin_or_the_ids() -> void:
	assert_false(PlayBilling.new(null, IDS).is_available(), "no plugin in this APK")
	assert_false(PlayBilling.new(plugin, {}).is_available(), "no product ids from the owner")
	assert_false(PlayBilling.new(plugin, ShopCatalog.PLAY_IDS).is_available(), "the shipped table has none yet")
	assert_true(_billing().is_available())
	assert_false(_billing().is_test())


func test_connecting_asks_for_the_prices_of_every_product_on_sale() -> void:
	var b := _billing()
	assert_has(plugin.calls, ["initPlugin"])
	assert_has(plugin.calls, ["startConnection"])
	var prices: Array = []
	b.products_loaded.connect(func(p: Dictionary) -> void: prices.append(p))
	plugin.connected.emit()
	var query: Array = plugin.calls.filter(func(c: Array) -> bool: return c[0] == "queryProductDetails")
	assert_eq(query.size(), 1)
	assert_eq(query[0][2], "inapp", "one-time products")
	assert_true((query[0][1] as Array).has("ec_plus"))
	plugin.query_product_details_response.emit({"response_code": 0, "product_details": [
		{"product_id": "ec_plus", "one_time_purchase_offer_details_list": [{"formatted_price": "13,99 ₾"}]},
		{"product_id": "ec_sky", "one_time_purchase_offer_details_list": [{"formatted_price": "5,49 ₾"}]},
		{"product_id": "someone_else", "one_time_purchase_offer_details_list": [{"formatted_price": "1"}]}]})
	assert_eq(prices, [{"plus": "13,99 ₾", "pack_sky": "5,49 ₾"}])


func test_a_purchase_goes_through_the_play_sheet_and_comes_back() -> void:
	var b := _billing()
	plugin.connected.emit()
	var got: Array = []
	b.purchase_updated.connect(func(r: Dictionary) -> void: got.append(r))
	b.buy("pack_sky")
	assert_has(plugin.calls, ["purchase", "ec_sky", "", "", false])
	plugin.on_purchase_updated.emit({"response_code": 0, "purchases": [_purchase("ec_sky", 1, "t-1")]})
	assert_eq(got.size(), 1)
	assert_eq(got[0].product, "pack_sky")
	assert_eq(got[0].status, Billing.PAID)
	assert_eq(got[0].token, "t-1")
	assert_false(got[0].acknowledged)
	b.acknowledge("t-1")
	assert_has(plugin.calls, ["acknowledgePurchase", "t-1"])


func test_cancel_pending_failure_and_a_refused_launch() -> void:
	var b := _billing()
	plugin.connected.emit()
	var got: Array = []
	b.purchase_updated.connect(func(r: Dictionary) -> void: got.append([r.product, r.status]))
	b.buy("plus")
	plugin.on_purchase_updated.emit({"response_code": 1, "debug_message": "User canceled"})
	b.buy("plus")
	plugin.on_purchase_updated.emit({"response_code": 0, "purchases": [_purchase("ec_plus", 2)]})
	b.buy("pack_ocean")
	plugin.on_purchase_updated.emit({"response_code": 6, "debug_message": "Error"})
	plugin.launch_code = 3
	b.buy("pack_sky")
	await wait_process_frames(2)
	assert_eq(got, [["plus", Billing.CANCELLED], ["plus", Billing.PENDING], ["pack_ocean", Billing.FAILED],
		["pack_sky", Billing.FAILED]])


func test_already_owned_restores_instead_of_failing() -> void:
	var b := _billing()
	plugin.connected.emit()
	b.buy("plus")
	plugin.on_purchase_updated.emit({"response_code": 7, "debug_message": "Item already owned"})
	assert_eq(plugin.calls.filter(func(c: Array) -> bool: return c[0] == "queryPurchases").size(), 2,
		"one at connect, one to pick the owned item up")


func test_restore_lists_what_the_play_account_owns() -> void:
	var b := _billing()
	var got: Array = []
	b.restore_finished.connect(func(r: Dictionary) -> void: got.append(r))
	plugin.connected.emit()
	assert_has(plugin.calls, ["queryPurchases", "inapp", false], "restored at every start")
	plugin.query_purchases_response.emit({"response_code": 0, "purchases": [
		_purchase("ec_plus", 1, "a", true), _purchase("ec_ocean", 2, "b"), _purchase("unknown_thing", 1, "c")]})
	assert_eq(got.size(), 1)
	assert_true(got[0].ok)
	assert_eq(got[0].owned.size(), 1)
	assert_eq(got[0].owned[0].product, "plus")
	assert_true(got[0].owned[0].acknowledged)
	assert_eq(got[0].pending, ["pack_ocean"])
	plugin.query_purchases_response.emit({"response_code": 2, "debug_message": "offline"})
	assert_false(got[1].ok)


func test_a_restore_asked_before_the_connection_waits_for_it() -> void:
	var b := _billing()
	b.restore()
	assert_eq(plugin.calls.filter(func(c: Array) -> bool: return c[0] == "queryPurchases").size(), 0)
	plugin.connected.emit()
	assert_eq(plugin.calls.filter(func(c: Array) -> bool: return c[0] == "queryPurchases").size(), 1)


func test_a_purchase_before_the_connection_fails_calmly() -> void:
	var b := _billing()
	var got: Array = []
	b.purchase_updated.connect(func(r: Dictionary) -> void: got.append(r.status))
	b.buy("plus")
	await wait_process_frames(2)
	assert_eq(got, [Billing.FAILED])
	assert_eq(plugin.calls.filter(func(c: Array) -> bool: return c[0] == "purchase").size(), 0)


func test_a_stray_answer_without_a_purchase_in_flight_names_no_product() -> void:
	var b := _billing()
	plugin.connected.emit()
	var got: Array = []
	b.purchase_updated.connect(func(r: Dictionary) -> void: got.append(r))
	plugin.on_purchase_updated.emit({"response_code": 7, "debug_message": "Item already owned"})
	plugin.on_purchase_updated.emit({"response_code": 6, "debug_message": "Error"})
	await wait_process_frames(2)
	assert_eq(got, [], "nothing to answer: no purchase was asked for")
