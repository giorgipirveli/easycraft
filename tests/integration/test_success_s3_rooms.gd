extends GutTest
## Owner #115 (Success S3): the shop's and the Market Square's practice rooms (ShopRoom, MarketSquareRoom). The customer
## comes to the counter and the coins pile up where they go; a review appears when a customer is thanked; the ledger
## shows money in, money out, profit and the week's bars (Big's loss day under the line); the scales show the grams; the
## rival opens across the square. The Price Board shows the usual prices, and each cause moves its row (a dry summer:
## wheat UP; many sellers: apples DOWN; winter: apples UP); the tray goes to Tomas to pay him; the dice shows the try's
## own throws and counts the sixes; the chart draws 600 throws ending under the line. Every room stays inside the mesh
## budget (the Quest).

const MESH_BUDGET := 320


func _room(exp_id: String, track: String, seed: int = 1) -> LifeRoom:
	var r := LifeRooms.make(str(LifeExperience.data(exp_id).room), track, LifeExperience.vars(exp_id, track, seed, "ge"))
	add_child_autofree(r)
	return r


func _meshes(n: Node) -> int:
	var count := 1 if n is MeshInstance3D else 0
	for c in n.get_children():
		count += _meshes(c)
	return count


func before_all() -> void:
	Profile.data.settings.reduce_motion = true


func after_all() -> void:
	Profile.data.settings.reduce_motion = false
	Audio.stop_all()


func test_the_customer_comes_and_the_change_piles_in_their_hand() -> void:
	var room := _room("my_shop", "middle") as ShopRoom
	var v := room.vars
	room.react("customer_1")
	assert_true(room.customer.visible, "the first customer at the counter")
	assert_eq((room.customer.get_node("Name") as Label3D).text, SuccessPeople.name_of(str(v.one)).to_upper(),
		"the Connections Book's person")
	room.progress({"kind": "coins", "target": "hand"}, {"given": [5, 1]})
	assert_eq(room.till.pile_size("hand"), 2)
	room.progress({"kind": "coins", "target": "till"}, {"given": [5, 2, 1]})
	assert_eq(room.till.pile_size("till"), 3)
	assert_eq((room.till.labels.till as Label3D).text, "8", "the till counts what went in")


func test_taking_a_good_holds_it_out_and_thanking_gives_it_and_a_review() -> void:
	var room := _room("my_shop", "middle") as ShopRoom
	room.react("customer_1")
	var bread: MeshInstance3D = room.goods.good_bread
	var home: Vector3 = bread.position
	room.step_done({"id": "take", "kind": "touch", "target": "good_bread"})
	assert_ne(bread.position, home, "held out over the counter")
	room.react("thank_c1")
	assert_false(bread.visible, "given to the customer")
	assert_eq(room.review_count(), 1, "a review on the board")
	room.react("customer_2")
	assert_true(bread.visible, "a fresh one on the shelf for the next customer")


func test_the_ledger_shows_in_out_profit_and_the_weeks_bars() -> void:
	var room := _room("my_shop", "big") as ShopRoom
	room.react("ledger")
	var v := room.vars
	assert_eq((room.ledger_bars.profit[1] as Label3D).text, "PROFIT %d" % (int(v.money_in) - int(v.money_out)))
	var under := 0
	for b in room.week_bars:
		assert_true(b.visible)
		if b.position.y < ShopRoom.LEDGER_AT.y - 0.15:
			under += 1
	assert_eq(under, 1, "the rainy day's bar under the line: a loss")


func test_the_price_tags_follow_the_price_taught() -> void:
	var room := _room("my_shop", "middle") as ShopRoom
	room.react("prices_up")
	assert_eq(room.price_tags[0].text, str(int(SuccessShop.good("bread").price)), "the usual fair price")
	var dear := _room("my_shop", "middle") as ShopRoom
	dear.react("prices_up_dear")
	assert_eq(dear.price_tags[0].text, "4", "the Expert try's dearer flour: a loaf costs 3, its fair price 4")
	var big := _room("my_shop", "big") as ShopRoom
	big.react("prices_up")
	assert_eq(big.price_tags[0].text, str(int(big.vars.new_price)), "Big's new price")


func test_the_scales_show_the_grams_and_the_rival_opens() -> void:
	var room := _room("my_shop", "middle") as ShopRoom
	room.progress({"kind": "pour", "target": "scales"}, {"level": 212.4})
	assert_eq(room.scales_label.text, "212 g")
	room.react("rival")
	assert_true(room.pip.visible)
	assert_eq(room.rival_sign.text, "PIP-POP'S BAKERY")


func test_the_price_board_moves_for_causes_you_can_see() -> void:
	var room := _room("market_square", "middle") as MarketSquareRoom
	var v := room.vars
	for id: String in MarketSquareRoom.ROWS:
		assert_eq(room.price_of(id), int(SuccessMarket.good(id).base), id + ": the usual price")
	room.react("dry")
	room.react("board_wheat")
	assert_eq(room.price_of("wheat"), int(v.wheat_dry))
	assert_eq((room.rows.wheat.arrow as Label3D).text, "UP")
	assert_eq((room.rows.wheat.why as Label3D).text, "DRY SUMMER", "why it moved, on the board")
	room.react("many_apples")
	assert_true(room.extra_carts.visible, "four more apple carts")
	room.react("board_apples")
	assert_eq((room.rows.apples.arrow as Label3D).text, "DOWN")
	room.react("festival")
	assert_true(room.bunting.visible, "the festival's bunting")


## VR: the laser picks the nearest target along its ray; a row inside the whole board's target lost to the board (the
## smoke's VR runs timed out on "find apples"): the board's own target is its title, and no two of them overlap.
func test_the_price_boards_targets_never_overlap() -> void:
	var room := _room("market_square", "middle") as MarketSquareRoom
	var names: Array[String] = ["price_board"]
	for id: String in MarketSquareRoom.ROWS:
		names.append("row_" + id)
	for a in names:
		for b in names:
			if a < b:
				var d := room.target_position(a).distance_to(room.target_position(b))
				assert_gt(d, room.target_radius(a) + room.target_radius(b), "%s and %s" % [a, b])


func test_the_tray_goes_to_tomas_to_pay_him() -> void:
	var room := _room("market_square", "middle") as MarketSquareRoom
	room.step_started({"kind": "coins", "target": "tomas"})
	assert_lt(room.till.tray.global_position.distance_to(room.target_position("tomas")), 0.6, "the coins in front of Tomas")
	room.step_started({"kind": "coins", "target": "hand"})
	assert_eq(room.till.tray.position, MarketSquareRoom.TRAY_AT, "and back at your stall")


func test_the_dice_shows_the_trys_own_throws_and_the_chart_falls() -> void:
	var room := _room("market_square", "big", 5) as MarketSquareRoom
	var v := room.vars
	room.react("dice_game")
	for n in range(1, 7):
		room.progress({"kind": "taps", "target": "dice"}, {"t": n})
		assert_eq(room.dice_face.text, str(v.dice_faces[n - 1]), "throw %d" % n)
	assert_eq(room.dice_count.text, "SIXES: %d" % int(v.dice_sixes))
	room.react("chart")
	assert_eq(room.chart_points.size(), (v.chart_line as Array).size())
	assert_gte(room.chart_points.size(), 20)
	assert_lt(room.chart_points.back().position.y, room.chart_points.front().position.y, "the line ends lower")
	assert_string_contains(room.chart_label.text, str(int(v.chart_net)))


func test_winter_and_the_storm() -> void:
	var room := _room("market_square", "big") as MarketSquareRoom
	room.react("winter")
	assert_eq(room.price_of("apples"), int(room.vars.apple_winter))
	room.react("storm")
	assert_true(room.storm.visible)


func test_the_swap_stall_moves_apples_to_the_table() -> void:
	var room := _room("market_square", "little") as MarketSquareRoom
	room.progress({"kind": "taps", "target": "apples"}, {"t": 2})
	assert_eq(room.apples_on_table.size(), 2)
	room.react("mo_offer")
	assert_true(room.mo.visible)


func test_every_room_keeps_inside_the_mesh_budget() -> void:
	for id: String in ["my_shop", "market_square"]:
		for track in LifeData.TRACKS:
			var room := _room(id, track)
			for s: Dictionary in LifeExperience.steps(id, track, false, 1, "ge"):
				if str(s.get("react", "")) != "":
					room.react(str(s.react))
				if str(s.get("after", "")) != "":
					room.react(str(s.after))
			var n := _meshes(room)
			gut.p("SUCCESS3_MESHES %s.%s %d" % [id, track, n])
			assert_lte(n, MESH_BUDGET, "%s.%s: %d meshes" % [id, track, n])
