extends GutTest
## Owner #115 (docs/design/success-skills.md §2.1, §2.2, §3; the S3 brief): Success S3's two Life Experiences as data,
## data/success/experiences/my_shop.json (My Business: Little keeps the stand, Middle runs the shop, Big has its harder
## days) and market_square.json (Little's swap stall, Middle's supply and demand, Big's honest trading and the dice
## lesson). They are Life's (stamps, checks, Try it for real, every Life rule on every track); the brief's parts are on
## the right tracks; the guardrails hold in their words (never gambling but the lesson that shows why it loses, with
## pretend counters only; no real money; no pressure tricks; honesty rewarded, tricks never the answer); the customers
## and merchants are the Connections Book's people; every step's device is in the Tool Book.

const S3: Array[String] = ["my_shop", "market_square"]
const PRESSURE: Array[String] = ["hurry", "only today", "last chance", "before it's gone", "gone for ever", "right now!",
	"don't miss", "limited time", "countdown"]


func _steps(id: String, track: String, expert: bool = false, seed: int = 1) -> Array[Dictionary]:
	return LifeExperience.steps(id, track, expert, seed, "ge")


func _step(id: String, track: String, step_id: String, expert: bool = false) -> Dictionary:
	for s in _steps(id, track, expert):
		if str(s.id) == step_id:
			return s
	return {}


func _words(id: String) -> String:
	return JSON.stringify(LifeExperience.data(id)).to_lower()


func _right(step: Dictionary) -> Dictionary:
	return (step.choices as Array)[int(step.answer)]


func test_the_two_are_life_experiences_with_their_rooms_and_units() -> void:
	for id in S3:
		assert_has(SuccessExperiences.IDS, id)
		assert_has(LifeExperience.IDS, id)
		assert_eq(LifeExperience.problems(id), [] as Array[String], id)
		assert_eq(str(LifeExperience.data(id).area), "money", id + ": in Money and business, beside My Money Stall")
		for track in LifeData.TRACKS:
			var room := LifeRooms.make(str(LifeExperience.data(id).room), track, LifeExperience.vars(id, track, 1, "ge"))
			assert_true(room is ShopRoom or room is MarketSquareRoom, "%s.%s: its own room" % [id, track])
			room.free()
			assert_false(LifeCatalog.experience_unit(id, track).is_empty(), "%s.%s has its unit" % [id, track])


func test_little_keeps_the_stand_and_middle_runs_the_shop() -> void:
	var stand := LifeRooms.make("shop", "little", LifeExperience.vars("my_shop", "little", 1, "ge"))
	add_child(stand)   # a room builds itself when it enters the tree
	assert_false(stand.has_target("scales"), "Little's stand: no bakery")
	assert_true(stand.has_target("box") and stand.has_target("flour_jar"), "the cash box and the FLOUR jar")
	stand.free()
	var shop := LifeRooms.make("shop", "middle", LifeExperience.vars("my_shop", "middle", 1, "ge"))
	add_child(shop)
	for t: String in ["scales", "till", "bobo", "reviews", "ledger", "good_bread", "good_cake", "good_honey_bun", "customer"]:
		assert_true(shop.has_target(t), "the shop's " + t)
	shop.free()


func test_the_shop_has_every_part_the_brief_names() -> void:
	var m := _steps("my_shop", "middle")
	var kinds := {}
	for s in m:
		kinds[str(s.id)] = s
	assert_string_contains(str(_right(kinds.sign).text), "FRESH BREAD", "an honest, clear sign")
	assert_string_contains(str(_right(kinds.ask).text).to_lower(), "what would you like", "ask what they want")
	assert_eq(str(kinds.weigh.device), "scales", "make it: the farm's flour weighed on the scales")
	var price: Dictionary = kinds.price
	assert_string_contains(str(_right(price).text).to_lower(), "cost and a little profit")
	var whys := " ".join(PackedStringArray((price.choices as Array).map(func(c: Dictionary) -> String: return str(c.get("why", "")))))
	assert_string_contains(whys.to_lower(), "nobody buys", "too high: nobody buys")
	assert_string_contains(whys.to_lower(), "no money left for more flour", "too low: no money for more flour")
	assert_eq(str(kinds.reviews.target), "reviews", "the review board")
	assert_string_contains(str(_right(kinds.listen).text).to_lower(), "listen", "a complaint listened to")
	assert_true((kinds.fix.shop as Dictionary).has("fixed"), "and fixed")
	assert_eq(str(kinds.ledger.device), "ledger", "the ledger in pictures")
	assert_eq(str(kinds.week.device), "ledger", "a week's bars")
	assert_eq(str(kinds.wage.target), "bobo", "a buddy helper paid a wage")
	assert_true((kinds.wage.shop as Dictionary).has("out"), "the wage is money out")
	var rival: Dictionary = kinds.rival
	assert_string_contains(str(_right(rival).text).to_lower(), "better bread and kinder service", "quality or service")
	for c: Dictionary in rival.choices:
		if c != _right(rival):
			assert_ne(str(c.get("why", "")), "", "the coach says why a trick is never the way: %s" % c.text)
	var big := {}
	for s in _steps("my_shop", "big"):
		big[str(s.id)] = s
	for id: String in ["costs", "price", "rain", "order", "weigh", "deliver", "hours", "wage", "week", "price_war",
			"unfair_review", "save"]:
		assert_true(big.has(id), "Big's harder days: " + id)


func test_the_market_has_every_part_the_brief_names() -> void:
	var little := {}
	for s in _steps("market_square", "little"):
		little[str(s.id)] = s
	assert_string_contains(str(_right(little.why).text).to_lower(), "both", "swapping: good for both")
	assert_string_contains(str(_right(little.unfair).text).to_lower(), "no, thank you", "an unfair swap: no, kindly")
	var m := {}
	for s in _steps("market_square", "middle"):
		m[str(s.id)] = s
	assert_eq(str(m.read.device), "price_board", "the Price Board")
	assert_eq(str(m.dry.react), "dry", "a dry season...")
	assert_eq(str(_right(m.wheat_up).text), "It goes up", "...wheat goes up")
	assert_eq(str(_right(m.festival).text), "It goes up", "a festival: cakes go up")
	assert_eq(str(_right(m.many).text), "It goes down", "many sellers: the price falls")
	assert_eq(str(m.buy_flour.kind), "coins", "buy")
	assert_eq(str(m.sell.kind), "coins", "sell")
	assert_string_contains(str(_right(m.haggle).text).to_lower(), "could you do", "haggle politely")
	assert_string_contains(str(m.specialise.done).to_lower(), "more than before", "specialise: both richer")
	assert_eq(str(m.autumn.kind), "timelapse", "the seasons pass")
	var b := {}
	for s in _steps("market_square", "big"):
		b[str(s.id)] = s
	assert_string_contains(str(_right(b.plan).text).to_lower(), "sell in winter at a fair price", "buy low, sell high, honestly")
	assert_eq(str(b.stock.kind), "count", "keep a stock")
	assert_eq(str(b.spread.kind), "find", "spread across goods")
	assert_eq(str(b.storm.react), "storm", "a storm hits one")
	assert_eq(str(b.throws.target), "dice", "the dice lesson")
	assert_eq(str(b.chart.react), "chart", "the averages drawn as a chart")
	assert_string_contains(str(_right(b.why_down).text).to_lower(), "about 6 throws")


func test_never_gambling_only_the_lesson_that_shows_why_it_loses() -> void:
	for id in S3:
		for track in LifeData.TRACKS:
			for expert: bool in [false, true]:
				for s in _steps(id, track, expert):
					var said := (str(s.say) + " " + JSON.stringify(s.get("choices", []))).to_lower()
					assert_null(RegEx.create_from_string("\\b(place a bet|bet on|your bet|wager|jackpot|spin|lottery|loot box)\\b")
						.search(said), "%s.%s %s: never an offer to bet" % [id, track, s.id])
	var dice := 0
	for s in _steps("market_square", "big") + _steps("market_square", "big", true):
		var words := (str(s.get("say", "")) + str(s.get("done", ""))).to_lower()
		if words.contains("dice") or words.contains("throw"):
			dice += 1
			assert_false(words.contains("gold"), "%s: the dice lesson never mentions gold" % s.id)
			assert_false(words.contains("coin"), "%s: pretend counters, never coins" % s.id)
	assert_gte(dice, 5, "the dice lesson's steps")
	assert_string_contains(str(_step("market_square", "big", "dice_intro").say).to_lower(), "pretend counters")
	assert_string_contains(str(_step("market_square", "big", "dice_intro").say).to_lower(), "nobody bets")
	for track: String in ["little", "middle"]:
		assert_false(_words("market_square").contains("dice") and JSON.stringify(_steps("market_square", track)).to_lower()
			.contains("dice"), track + ": the dice lesson is the Big track's")


func test_no_real_money_and_no_pressure_tricks() -> void:
	for id in S3:
		var words := _words(id)
		var at := words.find("real money")
		while at >= 0:
			assert_true(words.substr(maxi(at - 10, 0), 60).contains("for real money, talk to a grown-up")
				or words.substr(maxi(at - 30, 0), 60).contains("with a grown-up"), id + ": real money only with a grown-up")
			at = words.find("real money", at + 1)
		for w in PRESSURE:
			assert_false(words.contains(w), "%s: no pressure trick (%s)" % [id, w])
		assert_string_contains(words, "pretend coins", id + ": the coins are pretend")


func test_honesty_is_always_the_answer_and_a_trick_never_is() -> void:
	var tricks := 0
	for id in S3:
		for track in LifeData.TRACKS:
			for expert: bool in [false, true]:
				for s in _steps(id, track, expert):
					if not s.has("choices") or str(s.kind) == "feel":
						continue
					for i in (s.choices as Array).size():
						var c: Dictionary = s.choices[i]
						if str(c.get("icon", "")) in ["fake_review", "fib", "fake_claim"]:
							tricks += 1
							assert_ne(i, int(s.answer), "%s.%s %s: a trick is never the right answer" % [id, track, s.id])
							assert_ne(str(c.get("why", "")), "", "%s.%s %s: the coach says why" % [id, track, s.id])
	assert_gte(tricks, 6, "fake reviews, untrue words and too-big claims are shown, to be turned down")


func test_the_customers_and_merchants_are_the_connections_books_people() -> void:
	for seed in 12:
		for track in LifeData.TRACKS:
			var v := LifeExperience.vars("my_shop", track, seed, "ge")
			for key: String in ["one", "two"]:
				if v.has(key):
					assert_false(SuccessPeople.person(str(v[key])).is_empty(), "%s %s: %s" % [track, key, v[key]])
	for s in _steps("market_square", "middle"):
		var book: Variant = s.get("book")
		if book is Dictionary and (book as Dictionary).has("meet"):
			for id: Variant in book.meet:
				assert_false(SuccessPeople.person(str(id)).is_empty(), str(id))


func test_every_step_device_is_in_the_tool_book() -> void:
	var named := {}
	for id in S3:
		for track in LifeData.TRACKS:
			for expert: bool in [false, true]:
				for s in _steps(id, track, expert):
					if s.has("device"):
						named[str(s.device)] = true
						assert_true(ToolBook.has(str(s.device)), "%s %s: the Tool Book's %s" % [id, s.id, s.device])
					if s.has("tool"):
						assert_true(ToolBook.has(str(s.tool)), "%s %s: the Tool Book's %s" % [id, s.id, s.tool])
	for d: String in ["till", "scales", "ledger", "price_board"]:
		assert_true(named.has(d), "the brief's Tool Book entries: " + d)


func test_a_shop_try_serves_customers_on_every_track() -> void:
	for track in LifeData.TRACKS:
		for expert: bool in [false, true]:
			var run := LifeRun.new(_steps("my_shop", track, expert, 3), expert)
			var frames := 0
			while not run.finished and frames < 5000:
				run.feed(LifeAuto.sample(run.current(), run.state, 0.1))
				frames += 1
			assert_true(run.finished, "%s expert=%s" % [track, expert])
			var day := SuccessShop.day_from(run.steps, run.steps_log)
			assert_gte(int(day.customers), 2, "%s: customers served while the child plays" % track)
			assert_gt(int(day.money_in), int(day.money_out), "%s: a profit on a fair day" % track)
			for r: Dictionary in day.reviews:
				assert_eq(int(r.s), 5, "%s: no hint, every review 5 stars" % track)


func test_each_try_varies_a_little() -> void:
	for id in S3:
		for track in LifeData.TRACKS:
			var seen := {}
			for seed in 12:
				seen[JSON.stringify(_steps(id, track, false, seed))] = true
			assert_gt(seen.size(), 1, "%s.%s: a repeat comes back a little different" % [id, track])


## Owner #115 (S3): the shop's page was first a second `class_name ShopPage` (the grown-ups' SHOP page has it): the
## global name then went to either script, by the class cache's order, and MY SHOP failed to load ("Too many arguments
## for new()"). No two scripts of the game may share a class name.
func test_no_class_name_is_used_twice() -> void:
	var seen := {}
	var twice: Array[String] = []
	var dirs: Array[String] = ["res://"]
	while not dirs.is_empty():
		var dir: String = dirs.pop_back()
		for sub in DirAccess.get_directories_at(dir):
			if not sub.begins_with(".") and sub != "addons":
				dirs.append(dir.path_join(sub))
		for f in DirAccess.get_files_at(dir):
			if not f.ends_with(".gd"):
				continue
			var path := dir.path_join(f)
			var text := FileAccess.get_file_as_string(path)
			for i in 3:   # after an @tool or @icon line at most
				var line := text.get_slice("\n", i)
				if line.begins_with("class_name "):
					var n := line.trim_prefix("class_name ").get_slice(" ", 0).strip_edges()
					if seen.has(n):
						twice.append("%s: %s and %s" % [n, seen[n], path])
					seen[n] = path
					break
	assert_eq(twice, [] as Array[String], "\n".join(twice))
	assert_gt(seen.size(), 500, "the whole game was read")


func test_every_fact_has_its_source() -> void:
	for id in S3:
		for track in LifeData.TRACKS:
			var sources: Array = LifeExperience.track_data(id, track).sources
			assert_gte(sources.size(), 3, "%s.%s: three sources or more" % [id, track])
			for s: Dictionary in sources:
				assert_true(str(s.url).begins_with("https://"), str(s))
				assert_ne(str(s.fact), "")
	assert_string_contains(str(LifeExperience.track_data("my_shop", "middle").try_real), "compare two prices",
		"the brief's Try it for real")
