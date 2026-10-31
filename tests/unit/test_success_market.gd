extends GutTest
## Owner #115 (docs/design/success-skills.md §2.2 the Market Square, §3; the S3 brief): the Market Square as rules
## (SuccessMarket, data/success/market.json). Goods' prices move by supply and demand with causes you can see, told on the
## Price Board (a dry summer: wheat goes up; the festival: cakes go up; many sellers: apples go down; the harvest: down
## again); the same day always shows the same board (nothing random, nothing paid); the seasons pass in days. Specialising
## and trading makes both richer. The dice lesson shows, with pretend counters only (never gold, never a bet), why a game
## that pays less than it takes always loses over many throws: the averages drawn as a chart.

const DAY := 20_000


func test_the_goods_have_their_seller_and_picture() -> void:
	for id: String in SuccessMarket.goods():
		var g := SuccessMarket.good(id)
		assert_gt(int(g.base), 0, id)
		assert_true(LifeIcons.has(str(g.icon)), id + ": its picture")
		assert_true(SuccessPeople.person(str(g.who)).size() > 0, id + ": sold by a person of the Connections Book")


func test_the_seasons_pass_in_days() -> void:
	var seen := []
	for i in 4:
		var s := SuccessMarket.season_of(DAY + i * SuccessMarket.days_per_season())
		assert_false(seen.has(s.id), "four different seasons")
		seen.append(s.id)
		assert_true(LifeIcons.has(str(s.icon)), str(s.id))
	assert_eq(SuccessMarket.season_of(DAY).id, SuccessMarket.season_of(DAY + 4 * SuccessMarket.days_per_season()).id,
		"a year of four seasons comes round again")


func test_every_price_that_moves_has_a_cause_you_can_see() -> void:
	for day in range(DAY, DAY + 60):
		var board := SuccessMarket.board(day)
		assert_eq(board.size(), SuccessMarket.goods().size())
		for row: Dictionary in board:
			assert_gte(int(row.price), 1)
			if int(row.price) != int(row.base):
				assert_false((row.why as Array).is_empty(), "day %d %s: why it moved" % [day, row.good])
				assert_eq(str(row.trend), "up" if int(row.price) > int(row.base) else "down")
			else:
				assert_eq(str(row.trend), "same")
		assert_eq(JSON.stringify(SuccessMarket.board(day)), JSON.stringify(board), "the same day, the same board")


func test_supply_and_demand_move_the_right_way() -> void:
	var summer := _a_day_of("summer")
	assert_gt(_price(summer, "wheat"), int(SuccessMarket.good("wheat").base), "a dry summer: less wheat, dearer")
	var autumn := _a_day_of("autumn")
	assert_lt(_price(autumn, "wheat"), int(SuccessMarket.good("wheat").base), "the harvest: lots of wheat, cheaper")
	var festival := -1
	var many := -1
	for day in range(DAY, DAY + 28):
		for e: Dictionary in SuccessMarket.events_of(day):
			if str(e.id) == "festival" and festival < 0:
				festival = day
			if str(e.id) == "many_sellers" and many < 0:
				many = day
	assert_gt(festival, 0, "a festival comes round")
	assert_gt(many, 0, "and a day of many sellers")
	assert_gt(_price(festival, "cakes"), _price(festival - 1, "cakes"), "the festival: everyone wants cakes")
	var plain := many - 1
	while not SuccessMarket.events_of(plain).is_empty() or SuccessMarket.season_of(plain).id != SuccessMarket.season_of(many).id:
		plain -= 1
	assert_lt(_price(many, "apples"), _price(plain, "apples"), "many sellers: the price falls")


func _a_day_of(season: String) -> int:
	for day in range(DAY, DAY + 28):
		if SuccessMarket.season_of(day).id == season and SuccessMarket.events_of(day).is_empty():
			return day
	return -1


func _price(day: int, good: String) -> int:
	for row: Dictionary in SuccessMarket.board(day):
		if str(row.good) == good:
			return int(row.price)
	return -1


func test_specialising_and_trading_makes_both_richer() -> void:
	var s := SuccessMarket.specialise()
	assert_gt(int(s.together_loaves), int(s.mixed_loaves))
	assert_gt(int(s.together_bags), int(s.mixed_bags))
	assert_gt(int(s.you_loaves_after), int(s.you_loaves_before), "you have more bread after the trade")
	assert_gt(int(s.you_bags_after), int(s.you_bags_before), "and more apples")
	assert_gt(int(s.ana_loaves_after), int(s.ana_loaves_before), "so does Ana")
	assert_gt(int(s.ana_bags_after), int(s.ana_bags_before))


func test_the_dice_game_always_loses_over_many_throws() -> void:
	var nets := 0.0
	for seed in 30:
		var run := SuccessMarket.dice_run(seed, 600)
		assert_eq(int(run.paid), 600, "1 pretend counter a throw")
		assert_eq(int(run.back), int(run.sixes) * SuccessMarket.DICE_PAYS)
		assert_eq(int(run.net), int(run.back) - int(run.paid))
		assert_lt(int(run.net), 0, "seed %d: over many throws the game keeps more than it gives" % seed)
		assert_gte((run.line as Array).size(), 20, "a chart's points")
		assert_eq(int((run.line as Array).back()), int(run.net))
		nets += float(run.net)
	assert_almost_eq(nets / 30.0, -200.0, 30.0, "about a third of a counter lost a throw, on average")
	assert_almost_eq(SuccessMarket.loss_per_throw(), 1.0 / 3.0, 0.001)
	var short := SuccessMarket.dice_run(3, 6)
	assert_eq((short.faces as Array).size(), 6)
	for f: int in short.faces:
		assert_between(f, 1, 6)
	assert_eq(JSON.stringify(SuccessMarket.dice_run(3, 6)), JSON.stringify(short), "seeded: the same try, the same throws")


func test_each_tracks_values_add_up() -> void:
	for seed in 40:
		var little := SuccessMarket.vars("little", seed)
		assert_between(int(little.swap_n), 2, 3)
		var m := SuccessMarket.vars("middle", seed)
		assert_gt(int(m.wheat_dry), int(m.wheat_base))
		assert_gt(int(m.cake_festival), int(m.cake_base))
		assert_lt(int(m.apple_many), int(m.apple_base))
		assert_lt(int(m.wheat_autumn), int(m.wheat_base))
		assert_eq(int(m.flour_total), int(m.flour_sacks) * int(m.flour_price))
		assert_eq(int(m.haggle_full), int(m.haggle_bags) * int(m.apple_base))
		assert_lt(int(m.haggle_ask), int(m.haggle_full))
		assert_eq(int(m.cake_change), 10 - int(m.cake_festival))
		var b := SuccessMarket.vars("big", seed)
		assert_lt(int(b.apple_autumn), int(b.apple_winter))
		assert_eq(int(b.stock), 3 * int(b.per_month))
		assert_lte(int(b.stock), int(b.shed))
		assert_eq(int(b.sale_change), 20 - int(b.sale_bags) * int(b.apple_winter))
		assert_gt(int(b.sale_change), 0)
		assert_eq((b.dice_faces as Array).size(), 6)
		assert_eq(int(b.dice_sixes), (b.dice_faces as Array).count(6))
		assert_lt(int(b.chart_net), 0)
		assert_eq(int(b.expert_lost), int(b.expert_throws) - int(b.expert_throws) / 6 * int(b.expert_pays))
		assert_gt(int(b.expert_lost), 0, "even a game that pays 5 for a 6 loses")


func test_the_price_board_words_and_the_grown_ups_line() -> void:
	var words := SuccessMarket.board_words(DAY)
	assert_string_contains(words, SuccessMarket.season_of(DAY).name)
	var d := SuccessData.new()
	assert_eq(SuccessMarket.grown_ups_line(d), "")
	d.market = {"t": 2, "x": true, "b": 3}
	var line := SuccessMarket.grown_ups_line(d)
	assert_string_contains(line, "2")
	assert_string_contains(line, "dice")
	assert_string_contains(line, "pretend counters")
