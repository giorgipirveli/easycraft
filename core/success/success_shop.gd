class_name SuccessShop
extends RefCounted
## Owner #115 (docs/design/success-skills.md §2.1 My Business, §3 the guardrails, §4 parents; the S3 brief): My Business's
## shop as rules, from data/success/shop.json:
## - the goods (bread, cake, honey buns), each with what it costs to make and its fair price: the cost and a little profit
##   (PROFIT). Too high and nobody buys; too low and there is no money for more flour (price_verdict, price_words);
## - the customers: the Connections Book's people, each with a wish (a good and their words), and their moods;
## - a try's values for each track and seed (vars: "vary": "success" in data/success/experiences/my_shop.json): the
##   customers, what they buy and pay, the change, the flour, the helper's wage, the ledger's money in, money out and
##   profit, a week's bars; on the Big track the harder days (dearer flour, a rainy day, a big order, the hours' wage, the
##   oven to save for);
## - a try's day (day_from): a step's "shop" says what it did: {"sale": person, "in": coins, "review": kind} (a customer
##   served), {"out": coins} (flour, a wage), {"fixed": person} (a complaint listened to and fixed). Only the steps done
##   count: customers come while the child is there;
## - the ledger (record, week, totals) and the customers' reviews (honest and kind: 5 stars, or 4 with "next time it will
##   be even quicker" when the coach helped with that sale), kept in SuccessData.shop;
## - the real gold (pay): GOLD_PER_CUSTOMER for each customer served in a try, never more than DAY_CAP a day, through the
##   game's own award path (EarnRules.credit: the account's Survivor gold, which the wallet sync takes to the server under
##   its per-award and per-hour caps). Never for time, never while away: a shop day is a try in the practice room.
## The coins in the shop are pretend market coins (My Money Stall's ruling): the gold is the game's reward for running the
## shop well, like learning's.

const PATH := "res://data/success/shop.json"
const PROFIT := 1
## Owner #115 (S3), the ruling on how much: an answer right the first time pays 5 (EarnRules.ANSWER_GOLD); a customer
## served kindly at a fair price pays the same. A day's shop gold stops at DAY_CAP (ten customers: two or three shop days),
## a third of the School's answer cap, so learning stays the main way to earn and the shop can never be farmed.
## It equals EarnRules.ANSWER_GOLD (test_success_shop.gd checks): written as a number, because a constant made from
## another class's constant needs that class compiled first, and EarnRules's own constants reach the worlds' loot
## rules, which load in the profile's chain before the Life screen (a compile cycle: MY SHOP failed to load).
const GOLD_PER_CUSTOMER := 5
const DAY_CAP := SuccessData.SHOP_DAY_CAP
const MAX_DAYS := SuccessData.SHOP_MAX_DAYS
const MAX_REVIEWS := SuccessData.SHOP_MAX_REVIEWS
const MAX_COINS := SuccessData.SHOP_MAX_COINS
const DAYS: Array[String] = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
const VERDICT_WORDS := {"fair": "A fair price: what it costs to make, and a little profit for your work.",
	"low": "Too low: you make nothing, and there is no money left for more flour.",
	"high": "Too high: customers go somewhere else, and nobody buys."}

static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var json := JSON.new()
		var text := FileAccess.get_file_as_string(PATH) if FileAccess.file_exists(PATH) else ""
		_data = json.data if text != "" and json.parse(text) == OK and json.data is Dictionary else {}
	return _data


static func goods() -> Dictionary:
	return data().get("goods", {})


static func good(id: String) -> Dictionary:
	return goods().get(id, {})


static func customers() -> Array[String]:
	var out: Array[String] = []
	for id: String in data().get("customers", {}):
		out.append(id)
	return out


static func wish(id: String) -> Dictionary:
	return (data().get("customers", {}) as Dictionary).get(id, {})


static func moods() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for m: Variant in data().get("moods", []):
		if m is Dictionary:
			out.append(m)
	return out


static func signs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s: Variant in data().get("signs", []):
		if s is Dictionary:
			out.append(s)
	return out


static func sign_text(id: String) -> String:
	for s in signs():
		if str(s.id) == id:
			return str(s.text)
	return ""


static func review_kinds() -> Array[String]:
	var out: Array[String] = []
	for k: String in data().get("reviews", {}):
		out.append(k)
	return out


static func review_kind(k: String) -> Dictionary:
	return (data().get("reviews", {}) as Dictionary).get(k, {"stars": 5, "words": ""})


static func fair_price(cost: int) -> int:
	return cost + PROFIT


## "fair", "low" (no profit) or "high" (customers go elsewhere: more than twice the fair price's profit over the cost).
static func price_verdict(price: int, cost: int) -> String:
	if price <= cost:
		return "low"
	if price > fair_price(cost) + 2:
		return "high"
	return "fair"


static func price_words(verdict: String) -> String:
	return str(VERDICT_WORDS.get(verdict, ""))


static func name_of(id: String) -> String:
	return SuccessPeople.name_of(id)


## The values of a try on `track` for `seed` (they always add up; the data's steps fill them in).
static func vars(track: String, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["my_shop", track, seed])
	var v := {"sign_line": str(data().get("sign_line", "")), "rival": str((data().get("rival", {}) as Dictionary).get("name",
		"Pip-pop")), "rival_shop": str((data().get("rival", {}) as Dictionary).get("shop", ""))}
	var mood: Dictionary = moods()[rng.randi_range(0, moods().size() - 1)] if not moods().is_empty() else {}
	match track:
		"little":
			var pool := customers().filter(func(id: String) -> bool:
				return id != "mo" and str(wish(id).get("good", "")) in ["bread", "cake"])
			var one: String = pool[rng.randi_range(0, pool.size() - 1)]
			_person(v, "one", one, mood)
			v.one_good = str(wish(one).good)
			v.one_other = "cake" if v.one_good == "bread" else "bread"
			_good_words(v, "one_good", str(v.one_good))
			_good_words(v, "one_other", str(v.one_other))
			v.price = 2
			v.cost = 1
			v.two = "mo"
			v.two_name = name_of("mo")
			v.two_cost = 2
			v.two_paid = rng.randi_range(3, 5)
			v.two_change = int(v.two_paid) - int(v.two_cost)
			v.money_in = 4
			v.flour_out = 2
			v.left = int(v.money_in) - int(v.flour_out)
		"big":
			var pool := customers().filter(func(id: String) -> bool: return id != "mo" and id != "okafor")
			var one: String = pool[rng.randi_range(0, pool.size() - 1)]
			_person(v, "one", one, mood)
			v.old_cost = good("bread").get("cost", 2)
			v.old_price = fair_price(int(v.old_cost))
			v.flour_up = rng.randi_range(1, 2)
			v.new_cost = int(v.old_cost) + int(v.flour_up)
			v.new_price = fair_price(int(v.new_cost))
			v.new_cost_wrong = int(v.new_cost) + 2
			v.greedy_price = int(v.new_price) + 4
			v.normal_loaves = [20, 24][rng.randi_range(0, 1)]
			v.rain_loaves = int(v.normal_loaves) / 2
			v.double_loaves = int(v.normal_loaves) * 2
			v.order_n = [8, 10, 12][rng.randi_range(0, 2)]
			v.order_total = int(v.order_n) * int(good("honey_bun").get("price", 2))
			v.order_wrong = int(v.order_n) + int(good("honey_bun").get("price", 2))
			v.honey_g = [150, 200, 250][rng.randi_range(0, 2)]
			v.honey_cost = 4
			v.one_total = 2 * int(v.new_price)
			v.one_change = 20 - int(v.one_total)
			v.hours = rng.randi_range(2, 4)
			v.rate = 3
			v.wage = int(v.hours) * int(v.rate)
			v.wage_wrong = int(v.hours) + int(v.rate)
			v.month_profit = [40, 60, 80][rng.randi_range(0, 2)]
			v.save_part = int(v.month_profit) / 2
			v.oven = 120
			v.months = int(v.oven) / int(v.save_part)
			v.months_wrong = int(v.oven) / int(v.month_profit) if int(v.oven) % int(v.month_profit) == 0 \
				else int(v.months) + 2
			if int(v.months_wrong) == int(v.months):
				v.months_wrong = int(v.months) + 2
			var loss_i := rng.randi_range(1, 2)
			var week: Array = []
			for i in 7:
				week.append(-rng.randi_range(2, 4) if i == loss_i else rng.randi_range(4, 12))
			_unique_best(week, loss_i)
			v.week = week
			v.loss_day = DAYS[loss_i]
			v.loss = -int(week[loss_i])
			v.best_day = DAYS[week.find(week.max())]
			v.money_in = int(v.one_total) + int(v.order_total)
			v.money_out = int(v.wage) + int(v.honey_cost)
		_:   # the Middle track: the shop
			var pool := customers().filter(func(id: String) -> bool: return id != "mo")
			var one: String = pool[rng.randi_range(0, pool.size() - 1)]
			pool.erase(one)
			var two: String = pool[rng.randi_range(0, pool.size() - 1)]
			_person(v, "one", one, mood)
			_person(v, "two", two, {})
			v.one_good = str(wish(one).good)
			var g := good(str(v.one_good))
			v.one_good_name = str(g.name)
			v.one_good_one = str(g.one)
			v.one_qty = 1 if str(v.one_good) == "cake" else rng.randi_range(1, 2)
			v.one_price = int(g.price)
			v.one_total = int(v.one_qty) * int(g.price)
			v.one_change = 10 - int(v.one_total)
			v.one_what = str(g.one) if int(v.one_qty) == 1 else "2 %s" % g.many
			_good_words(v, "one_good", str(v.one_good))
			var others := goods().keys().filter(func(id: String) -> bool: return id != str(v.one_good))
			_good_words(v, "one_other_a", str(others[0]))
			_good_words(v, "one_other_b", str(others[1]))
			v.two_budget = [6, 8, 10][rng.randi_range(0, 2)]
			v.two_count = int(v.two_budget) / int(good("honey_bun").get("price", 2))
			v.two_count_wrong = int(v.two_count) + 2
			v.flour_g = [300, 400, 500][rng.randi_range(0, 2)]
			v.flour_cost = 3
			v.wage = 3
			v.money_in = int(v.one_total) + int(v.two_budget)
			v.money_out = int(v.flour_cost) + int(v.wage)
			v.profit = int(v.money_in) - int(v.money_out)
			v.profit_wrong_a = int(v.money_in) + int(v.money_out)
			v.profit_wrong_b = int(v.money_in)
			var week: Array = []
			for i in 7:
				week.append(rng.randi_range(2, 12))
			_unique_best(week, -1)
			v.week = week
			var best := week.find(week.max())
			v.best_day = DAYS[best]
			v.day_wrong_a = DAYS[(best + 2) % 7]
			v.day_wrong_b = DAYS[(best + 4) % 7]
	v.week_labels = DAYS.map(func(d: String) -> String: return d.substr(0, 3).to_upper())
	return v


static func _person(v: Dictionary, key: String, id: String, mood: Dictionary) -> void:
	v[key] = id
	v[key + "_name"] = name_of(id)
	v[key + "_wish"] = str(wish(id).get("words", ""))
	if not mood.is_empty():
		v[key + "_mood"] = str(mood.words).replace("{name}", name_of(id))
		v[key + "_face"] = str(mood.face)


## A good's words for a picture answer: <key>_word ("A cake"), <key>_icon, <key>_one ("a cake").
static func _good_words(v: Dictionary, key: String, id: String) -> void:
	var g := good(id)
	v[key + "_word"] = str(g.get("label", id))
	v[key + "_icon"] = str(g.get("icon", "question"))
	v[key + "_one"] = str(g.get("one", id))


## The week's tallest bar is one day only (the question has one answer); never the day `keep` (the loss).
static func _unique_best(week: Array, keep: int) -> void:
	var top := -INF
	var at := -1
	for i in week.size():
		if i != keep and int(week[i]) > top:
			top = int(week[i])
			at = i
	week[at] = int(week[at]) + 3


# --- A try's day ---------------------------------------------------------------------------------------------------

## What a try did, from its steps' "shop" (only the steps in `log`, the finished ones): {customers (served: a sale or a
## complaint fixed), money_in, money_out, fixed, reviews [{w (who), s (stars), k (the review's kind)}]}.
static func day_from(steps: Array, log: Array) -> Dictionary:
	var done := {}
	for e: Variant in log:
		if e is Dictionary:
			done[str((e as Dictionary).get("id", ""))] = bool((e as Dictionary).get("hinted", false))
	var day := {"customers": 0, "money_in": 0, "money_out": 0, "fixed": 0, "reviews": []}
	for s: Variant in steps:
		if not s is Dictionary or not done.has(str((s as Dictionary).get("id", ""))):
			continue
		var shop: Variant = (s as Dictionary).get("shop")
		if not shop is Dictionary:
			continue
		var hinted: bool = done[str(s.id)]
		if (shop as Dictionary).has("sale"):
			day.customers = int(day.customers) + 1
			var kind := "quicker" if hinted else str(shop.get("review", "fresh"))
			(day.reviews as Array).append({"w": str(shop.sale), "s": int(review_kind(kind).stars), "k": kind})
		if (shop as Dictionary).has("fixed"):
			day.customers = int(day.customers) + 1
			day.fixed = int(day.fixed) + 1
			(day.reviews as Array).append({"w": str(shop.fixed), "s": int(review_kind("fixed").stars), "k": "fixed"})
		day.money_in = int(day.money_in) + _coins(shop.get("in", 0))
		day.money_out = int(day.money_out) + _coins(shop.get("out", 0))
	return day


static func _coins(v: Variant) -> int:
	return clampi(int(v), 0, MAX_COINS) if typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) else 0


# --- The ledger and the reviews (SuccessData.shop) ----------------------------------------------------------------

## A day of the shop into its ledger (a second try on the same day adds to it) and its reviews (newest last).
static func record(d: SuccessData, day: Dictionary, today: int) -> void:
	if today <= 0 or (int(day.get("customers", 0)) <= 0 and int(day.get("money_in", 0)) <= 0
			and int(day.get("money_out", 0)) <= 0):
		return
	var ledger: Array = d.shop.get("l", [])
	var entry := {}
	for e: Variant in ledger:
		if e is Dictionary and int((e as Dictionary).get("d", 0)) == today:
			entry = e
	if entry.is_empty():
		entry = {"d": today, "i": 0, "o": 0, "c": 0, "k": 0}
		ledger.append(entry)
	entry.i = mini(int(entry.i) + int(day.get("money_in", 0)), MAX_COINS)
	entry.o = mini(int(entry.o) + int(day.get("money_out", 0)), MAX_COINS)
	entry.c = mini(int(entry.c) + int(day.get("customers", 0)), MAX_COINS)
	entry.k = mini(int(entry.k) + int(day.get("fixed", 0)), MAX_COINS)
	ledger.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.d) < int(b.d))
	d.shop.l = ledger.slice(maxi(ledger.size() - MAX_DAYS, 0))
	var reviews: Array = d.shop.get("r", [])
	for r: Variant in day.get("reviews", []):
		if r is Dictionary and SuccessData.valid_id((r as Dictionary).get("w")):
			reviews.append({"w": str(r.w), "s": clampi(int(r.get("s", 5)), 1, 5), "k": str(r.get("k", "fresh"))})
	d.shop.r = reviews.slice(maxi(reviews.size() - MAX_REVIEWS, 0))


## The last seven days to `today` (oldest first): {day, money_in, money_out, profit, customers} (0 on a day without the
## shop).
static func week(d: SuccessData, today: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in 7:
		var day := today - 6 + i
		var row := {"day": day, "money_in": 0, "money_out": 0, "profit": 0, "customers": 0}
		for e: Variant in d.shop.get("l", []):
			if e is Dictionary and int((e as Dictionary).get("d", 0)) == day:
				row.money_in = int(e.i)
				row.money_out = int(e.o)
				row.customers = int(e.c)
				row.profit = int(e.i) - int(e.o)
		out.append(row)
	return out


static func totals(d: SuccessData) -> Dictionary:
	var t := {"days": 0, "customers": 0, "money_in": 0, "money_out": 0, "profit": 0, "fixed": 0}
	for e: Variant in d.shop.get("l", []):
		if e is Dictionary:
			t.days += 1
			t.customers += int(e.get("c", 0))
			t.money_in += int(e.get("i", 0))
			t.money_out += int(e.get("o", 0))
			t.fixed += int(e.get("k", 0))
	t.profit = int(t.money_in) - int(t.money_out)
	return t


static func reviews(d: SuccessData) -> Array:
	return d.shop.get("r", [])


## The reviews' stars on average (0 before any).
static func stars(d: SuccessData) -> float:
	var list := reviews(d)
	if list.is_empty():
		return 0.0
	var sum := 0
	for r: Dictionary in list:
		sum += int(r.get("s", 5))
	return float(sum) / list.size()


## "Lina: 5 stars. "You asked what I wanted. Just right!""
static func review_line(r: Dictionary) -> String:
	return "%s: %d stars. \"%s\"" % [name_of(str(r.get("w", ""))), int(r.get("s", 5)),
		str(review_kind(str(r.get("k", "fresh"))).words)]


# --- The real gold --------------------------------------------------------------------------------------------------

## Shop gold still to earn on `today` (0 when the clock went back to before the last day paid).
static func gold_left(d: SuccessData, today: int) -> int:
	var g: Dictionary = d.shop.get("g", {})
	var day := int(g.get("d", -1))
	if today < day:
		return 0
	var had := int(g.get("g", 0)) if day == today else 0
	return maxi(DAY_CAP - had, 0)


## Pays `customers` served in a try on `today`: GOLD_PER_CUSTOMER each while the day's cap has room, into the account's
## Survivor gold (EarnRules.credit; the caller saves). What was paid.
static func pay(profile: ProfileData, customers: int, today: int) -> int:
	var d := profile.life.success
	var pay_now := mini(gold_left(d, today), maxi(customers, 0) * GOLD_PER_CUSTOMER)
	if pay_now <= 0:
		return 0
	var g: Dictionary = d.shop.get("g", {})
	var had := int(g.get("g", 0)) if int(g.get("d", -1)) == today else 0
	d.shop.g = {"d": today, "g": had + pay_now}
	var paid := EarnRules.credit(profile, pay_now)
	d.shop.t = mini(int(d.shop.get("t", 0)) + paid, SuccessData.MAX_COUNT)
	return paid


static func gold_words(gold: int) -> String:
	return "" if gold <= 0 else "+%d gold for Survivor from your shop's happy customers!" % gold


static func gold_today_words(d: SuccessData, today: int) -> String:
	return "Your shop's gold today: %d of %d. (%d for each happy customer.)" % [DAY_CAP - gold_left(d, today), DAY_CAP,
		GOLD_PER_CUSTOMER]


static func grown_ups_line(d: SuccessData) -> String:
	var t := totals(d)
	if int(t.days) <= 0:
		return ""
	var line := "My Business: ran their shop on %d %s: %d %s served, %d coins profit (pretend market coins)" % [t.days,
		"day" if int(t.days) == 1 else "days", t.customers, "customer" if int(t.customers) == 1 else "customers", t.profit]
	if int(t.fixed) > 0:
		line += ", %d %s listened to and fixed" % [t.fixed, "complaint" if int(t.fixed) == 1 else "complaints"]
	line += "."
	if int(d.shop.get("t", 0)) > 0:
		line += " The shop earned %d game gold for Survivor in all (%d a customer, at most %d a day, only while playing)." \
			% [int(d.shop.t), GOLD_PER_CUSTOMER, DAY_CAP]
	return line
