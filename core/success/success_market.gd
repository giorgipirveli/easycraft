class_name SuccessMarket
extends RefCounted
## Owner #115 (docs/design/success-skills.md §2.2 the Market Square, §3 the guardrails; the S3 brief): the Market Square
## as rules, from data/success/market.json:
## - the goods its buddy merchants sell (Tomas's flour, Ana's wheat and apples, Kenji's honey, Amara's cakes) and their
##   usual prices in pretend market coins;
## - the Price Board of a market day (board): every price is the usual one moved by supply and demand with causes you can
##   see: the season (seven market days each: spring's busy bees, a dry summer, autumn's harvest, winter) and the day's
##   events (the festival, many sellers), each with its words and picture. Pure: the same day always shows the same
##   board (nothing random, nothing to buy). A market day is the School's day (SchoolClock), so the seasons pass in days;
##   in the practice room a season passes on a time-lapse;
## - specialising (specialise): each doing what they do best and trading makes both richer (the numbers of the Middle
##   track's lesson);
## - the dice lesson (dice_run): a pretend fair game "pay 1 counter, throw a 6 and get DICE_PAYS back", thrown many times
##   with pretend counters only (never gold, never a bet): the line of counters over the throws falls, because a 6 comes
##   once in six throws on average and the game pays back less than it takes (loss_per_throw);
## - a try's values for each track and seed (vars: "vary": "success" in data/success/experiences/market_square.json).

const PATH := "res://data/success/market.json"
const DICE_PAYS := 4
const CHART_EVERY := 20
const TRACKS_LINE := "(pretend market coins)"

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


static func days_per_season() -> int:
	return maxi(int(data().get("days_per_season", 7)), 1)


static func seasons() -> Array:
	return data().get("seasons", [])


static func season(id: String) -> Dictionary:
	for s: Dictionary in seasons():
		if str(s.id) == id:
			return s
	return {}


## The season of market day `day` (each lasts days_per_season days; four make a year).
static func season_of(day: int) -> Dictionary:
	var list := seasons()
	if list.is_empty():
		return {}
	return list[posmod(floori(float(day) / days_per_season()), list.size())]


## The market's events on `day` (the festival, many sellers), in the data's order.
static func events_of(day: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Variant in data().get("events", []):
		if e is Dictionary and int((e as Dictionary).get("every", 0)) > 0 \
				and posmod(day, int(e.every)) == int(e.get("at", 0)):
			out.append(e)
	return out


static func event(id: String) -> Dictionary:
	for e: Variant in data().get("events", []):
		if e is Dictionary and str((e as Dictionary).get("id", "")) == id:
			return e
	return {}


## Day `day`'s Price Board: [{good, name, unit, icon, base, price, trend ("up", "down", "same"), why [words], icons
## [pictures of the causes]}], in the goods' order.
static func board(day: int) -> Array[Dictionary]:
	var causes: Array[Dictionary] = [season_of(day)]
	causes.append_array(events_of(day))
	var out: Array[Dictionary] = []
	for id: String in goods():
		var g := good(id)
		var price := int(g.base)
		var why: Array = []
		var icons: Array = []
		for c in causes:
			var fx: Dictionary = c.get("effects", {})
			if fx.has(id) and int(fx[id]) != 0:
				price += int(fx[id])
				why.append(str(c.why))
				icons.append(str(c.icon))
		price = maxi(price, 1)
		var trend := "same" if price == int(g.base) else ("up" if price > int(g.base) else "down")
		out.append({"good": id, "name": str(g.name), "unit": str(g.unit), "icon": str(g.icon), "base": int(g.base),
			"price": price, "trend": trend, "why": why, "icons": icons})
	return out


## The board in words (read aloud): the season, then each price that moved and why.
static func board_words(day: int) -> String:
	var lines: Array[String] = ["Market day: %s." % str(season_of(day).get("name", ""))]
	var said := {}
	for row in board(day):
		for w: String in row.why:
			if not said.has(w):
				said[w] = true
				lines.append(w)
	if lines.size() == 1:
		lines.append("Every price is the usual one today.")
	return " ".join(PackedStringArray(lines))


## Specialising: in a day you bake 10 loaves or pick 4 bags of apples; Ana picks 10 bags or bakes 2 loaves. Each doing a
## half of both makes less than each doing what they do best and trading 4 loaves for 4 bags: both end up with more.
static func specialise() -> Dictionary:
	var s := {"you_loaves": 10, "you_bags": 4, "ana_bags": 10, "ana_loaves": 2, "trade": 4}
	s.you_loaves_before = int(s.you_loaves) / 2
	s.you_bags_before = int(s.you_bags) / 2
	s.ana_loaves_before = int(s.ana_loaves) / 2
	s.ana_bags_before = int(s.ana_bags) / 2
	s.mixed_loaves = int(s.you_loaves_before) + int(s.ana_loaves_before)
	s.mixed_bags = int(s.you_bags_before) + int(s.ana_bags_before)
	s.together_loaves = int(s.you_loaves)
	s.together_bags = int(s.ana_bags)
	s.you_loaves_after = int(s.you_loaves) - int(s.trade)
	s.you_bags_after = int(s.trade)
	s.ana_loaves_after = int(s.trade)
	s.ana_bags_after = int(s.ana_bags) - int(s.trade)
	return s


## The pretend dice game thrown `throws` times (seeded: the same try, the same throws): {faces (the throws, kept for up
## to 60), sixes, paid (a counter a throw), back (DICE_PAYS for each 6), net, line (the counters won minus paid every
## CHART_EVERY throws, and at the end: the chart)}.
static func dice_run(seed: int, throws: int, pays: int = DICE_PAYS) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["dice", seed])
	var faces: Array = []
	var line: Array = []
	var sixes := 0
	for i in throws:
		var f := rng.randi_range(1, 6)
		if faces.size() < 60:
			faces.append(f)
		if f == 6:
			sixes += 1
		if (i + 1) % CHART_EVERY == 0 or i == throws - 1:
			line.append(sixes * pays - (i + 1))
	return {"faces": faces, "sixes": sixes, "paid": throws, "back": sixes * pays, "net": sixes * pays - throws, "line": line}


## On average a throw loses this many counters: it costs 1 and a 6 (one throw in six) pays DICE_PAYS.
static func loss_per_throw(pays: int = DICE_PAYS) -> float:
	return 1.0 - pays / 6.0


## The values of a try on `track` for `seed` (they always add up; the data's steps fill them in).
static func vars(track: String, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["market_square", track, seed])
	var summer: Dictionary = season("summer").get("effects", {})
	var autumn: Dictionary = season("autumn").get("effects", {})
	var winter: Dictionary = season("winter").get("effects", {})
	var v := {"wheat_base": int(good("wheat").get("base", 2)), "flour_price": int(good("flour").get("base", 4)),
		"apple_base": int(good("apples").get("base", 3)), "honey_base": int(good("honey").get("base", 5)),
		"cake_base": int(good("cakes").get("base", 4))}
	v.wheat_dry = int(v.wheat_base) + int(summer.get("wheat", 2))
	v.wheat_autumn = int(v.wheat_base) + int(autumn.get("wheat", -1))
	v.cake_festival = int(v.cake_base) + int((event("festival").get("effects", {}) as Dictionary).get("cakes", 2))
	v.apple_many = int(v.apple_base) + int((event("many_sellers").get("effects", {}) as Dictionary).get("apples", -1))
	v.apple_autumn = int(v.apple_base) + int(autumn.get("apples", -1))
	v.apple_winter = int(v.apple_base) + int(winter.get("apples", 2))
	match track:
		"little":
			v.swap_n = rng.randi_range(2, 3)
		"big":
			v.shed = 20
			v.per_month = rng.randi_range(4, 6)
			v.stock = 3 * int(v.per_month)
			v.stock_wrong = int(v.shed)
			v.sale_bags = rng.randi_range(2, 3)
			v.sale_total = int(v.sale_bags) * int(v.apple_winter)
			v.sale_change = 20 - int(v.sale_total)
			var throws := dice_run(seed, 6)
			v.dice_faces = throws.faces
			v.dice_sixes = int(throws.sixes)
			var chart := dice_run(seed + 1000, 600)
			v.chart_line = chart.line
			v.chart_net = int(chart.net)
			v.chart_lost = -int(chart.net)
			v.dice_pays = DICE_PAYS
			v.expert_throws = 60
			v.expert_pays = 5
			v.expert_back = int(v.expert_throws) / 6 * int(v.expert_pays)
			v.expert_lost = int(v.expert_throws) - int(v.expert_back)
		_:
			v.flour_sacks = rng.randi_range(1, 2)
			v.flour_total = int(v.flour_sacks) * int(v.flour_price)
			v.flour_words = "1 sack" if int(v.flour_sacks) == 1 else "%d sacks" % int(v.flour_sacks)
			v.haggle_bags = rng.randi_range(4, 5)
			v.haggle_full = int(v.haggle_bags) * int(v.apple_base)
			v.haggle_ask = int(v.haggle_full) - 2
			v.cake_change = 10 - int(v.cake_festival)
	var s := specialise()
	for k: String in s:
		v["sp_" + k] = s[k]
	return v


static func grown_ups_line(d: SuccessData) -> String:
	var tries := int(d.market.get("t", 0))
	var read := int(d.market.get("b", 0))
	if tries <= 0 and read <= 0 and not bool(d.market.get("x", false)):
		return ""
	var bits: Array[String] = []
	if tries > 0:
		bits.append("practised trading at the Market Square %d %s %s" % [tries, "time" if tries == 1 else "times",
			TRACKS_LINE])
	if read > 0:
		bits.append("read the Price Board (prices that move for reasons) on %d %s" % [read, "day" if read == 1 else "days"])
	if bool(d.market.get("x", false)):
		bits.append("did the dice lesson: why a game of chance loses over time (pretend counters only, never a bet)")
	return "The Market Square: " + "; ".join(PackedStringArray(bits)) + "."
