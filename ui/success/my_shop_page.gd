class_name MyShopPage
extends SuccessPage
## Owner #115 (docs/design/success-skills.md §2.1 My Business, §4; the S3 brief): MY SHOP, the child's own shop in Money
## and business (Life's map); MyShopPage, as the grown-ups' SHOP page is ShopPage. Its sign (picked from six, never typed), its customers' reviews (honest and kind, with the
## stars on average), the ledger in pictures (the last seven days' profit as bars, a day under the line red; this week's
## money in, money out and profit; the shop's days, customers and complaints fixed in all, in pretend market coins), the
## gold the shop earned today out of its day's cap, and OPEN MY SHOP: a shop day in the practice room (My Business's try
## on the child's track), where customers come while the child is there. Nothing is ever left running.

const OPEN := "OPEN MY SHOP"
const CHANGE_SIGN := "CHANGE SIGN"
const NO_SIGN := "No sign yet: pick one!"
const NO_DAYS := "Your shop hasn't opened yet. Open it, and customers will come while you are here."
const PAYS := "Your shop pays real gold for Survivor only while you play: %d for each happy customer, up to %d a day."
const LEDGER_WORDS := "THE LEDGER (pretend coins)"
const SHOP_GOLD := Color("d9772b")

var page := "shop"


func _init(p: ProfileData, save: Callable, day: int, region_id: String, track_id: String) -> void:
	super(p, save, day, region_id, track_id)
	name = "MyShopPage"


func _ready() -> void:
	show_shop()


func sign_words() -> String:
	var t := SuccessShop.sign_text(str(data().shop.get("s", "")))
	return t if t != "" else NO_SIGN


func summary() -> String:
	var t := SuccessShop.totals(data())
	if int(t.days) <= 0:
		return NO_DAYS
	return "%s. Your shop opened on %d %s and served %d %s. Reviews: %.1f stars." % [sign_words(), t.days,
		"day" if int(t.days) == 1 else "days", t.customers, "customer" if int(t.customers) == 1 else "customers",
		SuccessShop.stars(data())]


func show_shop() -> void:
	page = "shop"
	clear()
	header("My Shop", func() -> void: closed.emit(), [], summary)
	var body := centred_row(16)
	body.add_child(_front_panel())
	body.add_child(_ledger_panel())
	add_child(body)
	var foot := centred_row(20)
	var gold := left_words(SuccessShop.gold_today_words(data(), today), 22, 420)
	gold.name = "GoldToday"
	gold.add_theme_color_override("font_color", SchoolUi.GOLD)
	foot.add_child(gold)
	var open := SchoolUi.button(OPEN, SHOP_GOLD, Vector2(360, 86))
	open.name = "OpenShop"
	open.add_theme_font_size_override("font_size", 30)
	open.pressed.connect(func() -> void:
		if try_it.is_valid():
			try_it.call("my_shop"))
	foot.add_child(open)
	var pays := left_words(PAYS % [SuccessShop.GOLD_PER_CUSTOMER, SuccessShop.DAY_CAP], 18, 300)
	pays.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	foot.add_child(pays)
	add_child(foot)
	say(summary())


func _front_panel() -> PanelContainer:
	var panel := paper(540)
	panel.name = "Front"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(LifeIcons.new("shop", 80.0))
	var sign := SchoolUi.words(sign_words(), 28, 270)
	sign.name = "Sign"
	sign.add_theme_color_override("font_color", SchoolUi.GOLD)
	row.add_child(sign)
	var change := small(CHANGE_SIGN, show_signs, 130)
	change.name = "ChangeSign"
	row.add_child(change)
	col.add_child(row)
	var d := data()
	var reviews := SuccessShop.reviews(d)
	if reviews.is_empty():
		col.add_child(left_words(NO_DAYS, 22, 500))
	else:
		col.add_child(left_words("Reviews: %.1f stars on average, from %d customers." % [SuccessShop.stars(d), reviews.size()],
			22, 500))
		for i in range(reviews.size() - 1, maxi(reviews.size() - 4, -1), -1):
			var l := left_words(SuccessShop.review_line(reviews[i]), 19, 500)
			l.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
			col.add_child(l)
	return panel


func _ledger_panel() -> PanelContainer:
	var panel := paper(540)
	panel.name = "Ledger"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	var title := HBoxContainer.new()
	title.add_theme_constant_override("separation", 10)
	title.add_child(LifeIcons.new("ledger", 48.0))
	title.add_child(left_words(LEDGER_WORDS, 24, 420))
	col.add_child(title)
	var week := SuccessShop.week(data(), today)
	var values: Array[int] = []
	var labels: Array[String] = []
	var w_in := 0
	var w_out := 0
	for row: Dictionary in week:
		values.append(int(row.profit))
		w_in += int(row.money_in)
		w_out += int(row.money_out)
		labels.append(_day_letter(int(row.day)))
	var bars := ShopWeekBars.new(values, labels)
	bars.name = "WeekBars"
	col.add_child(bars)
	col.add_child(left_words("This week: money in %d, money out %d, profit %d." % [w_in, w_out, w_in - w_out], 20, 500))
	var t := SuccessShop.totals(data())
	if int(t.days) > 0:
		var all := left_words("In all: %d %s, %d customers served, %d %s fixed kindly." % [t.days,
			"day" if int(t.days) == 1 else "days", t.customers, t.fixed, "complaint" if int(t.fixed) == 1 else "complaints"], 18, 500)
		all.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
		col.add_child(all)
	return panel


## The first three letters of the School day's weekday (SchoolClock days count from 1970-01-01, a Thursday).
static func _day_letter(day: int) -> String:
	return SuccessShop.DAYS[posmod(day + 3, 7)].substr(0, 3).to_upper()


func show_signs() -> void:
	page = "signs"
	clear()
	header("Pick your sign", show_shop)
	var words := left_words("Which name for your shop? Every sign also says: %s." % SuccessShop.data().get("sign_line", ""), 22,
		1000)
	add_child(words)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for s in SuccessShop.signs():
		var b := LifeCards.picture_button(str(s.text), "shop_sign", Color(0.2, 0.3, 0.5), Vector2(360, 190), 22)
		b.name = "Sign_" + str(s.id)
		b.pressed.connect(pick_sign.bind(str(s.id)))
		grid.add_child(b)
	add_child(grid)
	say(words.text)


func pick_sign(id: String) -> void:
	if SuccessShop.sign_text(id) == "":
		return
	data().shop.s = id
	save()
	show_shop()
