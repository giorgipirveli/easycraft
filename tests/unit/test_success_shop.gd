extends GutTest
## Owner #115 (docs/design/success-skills.md §2.1 My Business, §3, §4; the S3 brief): My Business's shop as rules
## (SuccessShop, data/success/shop.json). Prices are what it costs + a little profit (too high: nobody buys; too low: no
## money for more flour); customers are the Connections Book's people, each with a wish, a budget and a mood; a try's
## steps say what was sold, what went out and what was fixed, and the shop's ledger keeps each day (money in, money out,
## profit, a week's bars) and the customers' honest, kind reviews. The shop pays real gold only for customers served while
## the child plays (a try's finished steps), GOLD_PER_CUSTOMER each, never more than DAY_CAP a day, through the game's own
## award path (EarnRules.credit: the wallet sync takes it to the server, under its caps).

const DAY := 20_000


func _profile() -> ProfileData:
	var p := ProfileData.new()
	p.survivor_gold = 0
	return p


func test_the_goods_have_a_cost_and_a_fair_price() -> void:
	for id: String in SuccessShop.goods():
		var g := SuccessShop.good(id)
		assert_gt(int(g.cost), 0, id)
		assert_eq(int(g.price), SuccessShop.fair_price(int(g.cost)), id + ": the cost and a little profit")
		assert_true(LifeIcons.has(str(g.icon)), id + ": its picture")
		assert_ne(str(g.one), "", id)
	assert_eq(SuccessShop.fair_price(2), 3, "bread: 2 to make, 3 to sell (My Money Stall's own price)")


func test_a_price_too_high_or_too_low_says_why() -> void:
	assert_eq(SuccessShop.price_verdict(3, 2), "fair")
	assert_eq(SuccessShop.price_verdict(2, 2), "low", "no profit: no money for more flour")
	assert_eq(SuccessShop.price_verdict(1, 2), "low")
	assert_eq(SuccessShop.price_verdict(9, 2), "high", "nobody buys")
	for v: String in ["fair", "low", "high"]:
		assert_ne(SuccessShop.price_words(v), "", v)


func test_the_customers_are_the_connections_books_people_with_wishes() -> void:
	var people := {}
	for p in SuccessPeople.list():
		people[str(p.id)] = true
	assert_gte(SuccessShop.customers().size(), 8)
	for id: String in SuccessShop.customers():
		assert_true(people.has(id), id + " is in the Connections Book")
		var w := SuccessShop.wish(id)
		assert_true(SuccessShop.goods().has(str(w.good)), id)
		assert_ne(str(w.words), "", id)
	for m: Dictionary in SuccessShop.moods():
		assert_has(LifeBuddy.FEELINGS, str(m.face), str(m.id))
		assert_string_contains(str(m.words), "{name}")


func test_each_tracks_values_add_up_for_every_seed() -> void:
	for seed in 40:
		var little := SuccessShop.vars("little", seed)
		assert_eq(int(little.two_change), int(little.two_paid) - int(little.two_cost), "little change")
		assert_gt(int(little.two_change), 0)
		assert_eq(int(little.left), int(little.money_in) - int(little.flour_out))
		assert_ne(str(little.one), str(little.two), "two different customers")
		var m := SuccessShop.vars("middle", seed)
		var g := SuccessShop.good(str(m.one_good))
		assert_eq(int(m.one_total), int(m.one_qty) * int(g.price))
		assert_eq(int(m.one_change), 10 - int(m.one_total))
		assert_gt(int(m.one_change), 0, "the first customer pays with a 10")
		assert_eq(int(m.two_count) * int(SuccessShop.good("honey_bun").price), int(m.two_budget), "the budget buys whole buns")
		assert_eq(int(m.money_in), int(m.one_total) + int(m.two_budget))
		assert_eq(int(m.money_out), int(m.flour_cost) + int(m.wage))
		assert_eq(int(m.profit), int(m.money_in) - int(m.money_out))
		assert_gt(int(m.profit), 0, "a fair price makes a profit")
		assert_true(str(m.one) != str(m.two) and str(m.two) != "mo" and str(m.one) != "mo", "Mo comes back with the complaint")
		var bars: Array = m.week
		assert_eq(bars.size(), 7)
		assert_eq(int(bars.max()), int(bars[SuccessShop.DAYS.find(str(m.best_day))]), "the best day is the tallest bar")
		var b := SuccessShop.vars("big", seed)
		assert_eq(int(b.new_cost), int(b.old_cost) + int(b.flour_up))
		assert_eq(int(b.new_price), SuccessShop.fair_price(int(b.new_cost)))
		assert_gt(int(b.greedy_price), int(b.new_price) + 2)
		assert_eq(int(b.rain_loaves) * 2, int(b.normal_loaves))
		assert_eq(int(b.order_total), int(b.order_n) * int(SuccessShop.good("honey_bun").price))
		assert_eq(int(b.one_change), 20 - 2 * int(b.new_price))
		assert_eq(int(b.wage), int(b.hours) * int(b.rate))
		assert_eq(int(b.months) * int(b.save_part), int(b.oven))
		var week: Array = b.week
		assert_lt(int(week[SuccessShop.DAYS.find(str(b.loss_day))]), 0, "the rainy day lost money")
		assert_eq(week.filter(func(v: int) -> bool: return v < 0).size(), 1, "only that day")


func test_the_values_vary_with_the_seed() -> void:
	var seen := {}
	for seed in 20:
		var v := SuccessShop.vars("middle", seed)
		seen["%s %s %d" % [v.one, v.two, int(v.two_budget)]] = true
	assert_gt(seen.size(), 4, "a repeat comes back a little different")


func _shop_steps() -> Array:
	return [
		{"id": "sale_1", "kind": "coins", "shop": {"sale": "lina", "in": 4, "review": "asked"}},
		{"id": "sale_2", "kind": "coins", "shop": {"sale": "okafor", "in": 8, "review": "fair"}},
		{"id": "flour", "kind": "pour", "shop": {"out": 3}},
		{"id": "fix", "kind": "touch", "shop": {"fixed": "mo"}},
		{"id": "wage", "kind": "coins", "shop": {"out": 3}},
	]


func _log(ids: Array, hinted: Array = []) -> Array:
	var out := []
	for id: String in ids:
		out.append({"id": id, "kind": "coins", "seconds": 3.0, "hinted": hinted.has(id), "mistakes": 0})
	return out


func test_a_tries_steps_make_its_day() -> void:
	var day := SuccessShop.day_from(_shop_steps(), _log(["sale_1", "sale_2", "flour", "fix", "wage"], ["sale_2"]))
	assert_eq(int(day.customers), 3, "two sales and a complaint fixed: three happy customers")
	assert_eq(int(day.money_in), 12)
	assert_eq(int(day.money_out), 6)
	assert_eq(int(day.fixed), 1)
	var reviews: Array = day.reviews
	assert_eq(reviews.size(), 3)
	assert_eq(int(reviews[0].s), 5, "Lina: asked what she wanted")
	assert_eq(int(reviews[1].s), 4, "Mr Okafor: the coach helped with the change, an honest 4 in kind words")
	assert_eq(str(reviews[1].k), "quicker")
	assert_eq(str(reviews[2].k), "fixed", "Mo: listened to and fixed")
	var half := SuccessShop.day_from(_shop_steps(), _log(["sale_1"]))
	assert_eq(int(half.customers), 1, "only the steps done count: customers come while you are there")
	assert_eq(int(half.money_out), 0)


func test_every_review_is_kind_and_honest() -> void:
	for k: String in SuccessShop.review_kinds():
		var r := SuccessShop.review_kind(k)
		assert_between(int(r.stars), 4, 5, k)
		var words := str(r.words).to_lower()
		for bad: String in ["bad", "worst", "terrible", "awful", "never again", "rubbish"]:
			assert_false(words.contains(bad), "%s: %s" % [k, words])
	assert_string_contains(SuccessShop.review_line({"w": "lina", "s": 5, "k": "asked"}), "Lina")


func test_the_ledger_keeps_each_day_and_a_weeks_bars() -> void:
	var d := SuccessData.new()
	SuccessShop.record(d, {"customers": 3, "money_in": 12, "money_out": 6, "fixed": 1, "reviews": []}, DAY - 2)
	SuccessShop.record(d, {"customers": 2, "money_in": 9, "money_out": 4, "fixed": 0, "reviews": []}, DAY)
	SuccessShop.record(d, {"customers": 1, "money_in": 3, "money_out": 3, "fixed": 0, "reviews": []}, DAY)
	var week := SuccessShop.week(d, DAY)
	assert_eq(week.size(), 7)
	assert_eq(int(week[6].day), DAY, "today last")
	assert_eq(int(week[6].profit), 5, "two tries today: 12 in, 7 out")
	assert_eq(int(week[4].profit), 6)
	assert_eq(int(week[5].profit), 0, "a day without the shop is an empty bar")
	assert_eq(SuccessShop.totals(d).customers, 6)
	assert_eq(SuccessShop.totals(d).profit, 11)
	assert_eq(SuccessShop.totals(d).days, 2)


func test_the_shop_pays_gold_only_for_customers_served_within_a_days_cap() -> void:
	var p := _profile()
	assert_eq(SuccessShop.pay(p, 3, DAY), 3 * SuccessShop.GOLD_PER_CUSTOMER)
	assert_eq(p.survivor_gold, 15, "through EarnRules.credit, the account's gold")
	assert_eq(SuccessShop.pay(p, 0, DAY), 0, "no customers, no gold: never for time")
	for i in 10:
		SuccessShop.pay(p, 3, DAY)
	assert_eq(p.survivor_gold, SuccessShop.DAY_CAP, "never more than the day's cap")
	assert_eq(SuccessShop.gold_left(p.life.success, DAY), 0)
	assert_eq(SuccessShop.pay(p, 2, DAY + 1), 10, "a new day")
	assert_eq(SuccessShop.pay(p, 2, DAY - 5), 0, "the clock turned back pays nothing again")
	assert_lte(SuccessShop.DAY_CAP, WalletReport.AWARD_MAX_BASE, "well inside the server's limits for one award")
	assert_lt(SuccessShop.DAY_CAP, EarnRules.ANSWER_DAY_CAP, "learning stays the main way to earn")
	assert_eq(SuccessShop.GOLD_PER_CUSTOMER, EarnRules.ANSWER_GOLD, "a customer served pays like an answer right the first time")


func test_the_gold_words_say_why() -> void:
	assert_string_contains(SuccessShop.gold_words(15), "15")
	assert_string_contains(SuccessShop.gold_words(15), "customer")
	assert_eq(SuccessShop.gold_words(0), "")


func test_the_grown_ups_line_says_what_the_shop_did() -> void:
	var d := SuccessData.new()
	assert_eq(SuccessShop.grown_ups_line(d), "", "nothing before a shop day")
	SuccessShop.record(d, {"customers": 3, "money_in": 12, "money_out": 6, "fixed": 1, "reviews": []}, DAY)
	var line := SuccessShop.grown_ups_line(d)
	for w: String in ["1 day", "3 customers", "6", "1 complaint"]:
		assert_string_contains(line, w)


func test_reviews_are_kept_newest_last_and_limited() -> void:
	var d := SuccessData.new()
	for i in SuccessShop.MAX_REVIEWS + 5:
		SuccessShop.record(d, {"customers": 1, "money_in": 3, "money_out": 0, "fixed": 0,
			"reviews": [{"w": "lina", "s": 5, "k": "asked"}]}, DAY + i)
	assert_eq(SuccessShop.reviews(d).size(), SuccessShop.MAX_REVIEWS)
	assert_almost_eq(SuccessShop.stars(d), 5.0, 0.01)


# --- The shop and the market in the profile (SuccessData) ---

func test_the_shop_and_the_market_round_trip_in_the_profile_and_the_backup() -> void:
	var p := _profile()
	var d := p.life.success
	d.shop.s = "golden"
	SuccessShop.record(d, {"customers": 3, "money_in": 12, "money_out": 6, "fixed": 1,
		"reviews": [{"w": "lina", "s": 5, "k": "asked"}]}, DAY)
	SuccessShop.pay(p, 3, DAY)
	d.market = {"t": 2, "x": true, "b": 4}
	assert_false(d.is_empty())
	var back := ProfileData.from_json(p.to_json())
	var e: SuccessData = back.life.success
	assert_eq(str(e.shop.s), "golden")
	assert_eq(SuccessShop.totals(e).profit, 6)
	assert_eq(SuccessShop.reviews(e).size(), 1)
	assert_eq(SuccessShop.gold_left(e, DAY), SuccessShop.DAY_CAP - 15, "the day's gold is remembered")
	assert_eq(int(e.shop.t), 15)
	assert_eq(int(e.market.t), 2)
	assert_true(bool(e.market.x))


func test_bad_shop_and_market_fields_fall_back_on_their_own() -> void:
	var d := SuccessData.from_dict({"shop": {"s": "Not A Sign!", "l": [{"d": "x"}, {"d": DAY, "i": -4, "o": 2, "c": 1},
		"junk"], "r": [{"w": "lina", "s": 99, "k": "asked"}, {"w": 7}], "g": {"d": DAY, "g": 1e12}, "t": "lots"},
		"market": {"t": -3, "x": "yes", "b": 2.0}})
	assert_false(d.shop.has("s"), "an unknown sign is dropped")
	assert_eq((d.shop.l as Array).size(), 1)
	assert_eq(int(d.shop.l[0].i), 0, "never below 0")
	assert_eq(int(d.shop.r[0].s), 5, "stars 1..5")
	assert_eq((d.shop.r as Array).size(), 1)
	assert_eq(SuccessShop.gold_left(d, DAY), 0, "a huge number is clamped to the cap, never past it")
	assert_eq(int(d.shop.get("t", 0)), 0)
	assert_eq(int(d.market.get("t", 0)), 0)
	assert_false(bool(d.market.get("x", false)))
	assert_eq(int(d.market.b), 2)
	assert_true(SuccessData.from_dict({"shop": "x", "market": []}).is_empty())


func test_the_merge_never_loses_a_shop_day_or_the_dice_lesson() -> void:
	var a := SuccessData.new()
	var b := SuccessData.new()
	SuccessShop.record(a, {"customers": 2, "money_in": 9, "money_out": 4, "fixed": 0, "reviews": []}, DAY)
	SuccessShop.record(b, {"customers": 2, "money_in": 9, "money_out": 4, "fixed": 0, "reviews": []}, DAY)
	SuccessShop.record(b, {"customers": 4, "money_in": 14, "money_out": 6, "fixed": 1,
		"reviews": [{"w": "mo", "s": 5, "k": "fixed"}]}, DAY - 3)
	b.shop.s = "honey"
	b.shop.g = {"d": DAY, "g": 20}
	b.market = {"t": 3, "x": true, "b": 1}
	a.market = {"t": 1, "x": false, "b": 5}
	a.merge_from(b)
	assert_eq(SuccessShop.totals(a).days, 2, "the older copy's day comes too")
	assert_eq(SuccessShop.totals(a).customers, 6, "the same day is never counted twice")
	assert_eq(str(a.shop.s), "honey", "a sign from either")
	assert_eq(SuccessShop.gold_left(a, DAY), SuccessShop.DAY_CAP - 20, "the most gold paid that day")
	assert_eq(SuccessShop.reviews(a).size(), 1)
	assert_eq(int(a.market.t), 3)
	assert_true(bool(a.market.x))
	assert_eq(int(a.market.b), 5)


## S3's follow-up (the lead, 2026-10-17): the Gold Shop's "How to earn" list names the shop (EarnRules.TABLE), with the
## shop's own numbers.
func test_the_gold_shops_how_to_earn_names_the_shop() -> void:
	var rows := EarnRules.TABLE.filter(func(r: Dictionary) -> bool: return str(r.id) == "shop_customer")
	assert_eq(rows.size(), 1)
	if rows.is_empty():
		return
	assert_eq(int(rows[0].gold), SuccessShop.GOLD_PER_CUSTOMER, "a customer served")
	assert_eq(str(rows[0].by), "game")
	assert_string_contains(str(rows[0].when), "shop")
	assert_string_contains(str(rows[0].limit), str(SuccessShop.DAY_CAP))
