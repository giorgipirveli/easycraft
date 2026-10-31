class_name PriceBoardPage
extends SuccessPage
## Owner #115 (docs/design/success-skills.md §2.2 the Market Square; the S3 brief: "goods' prices move by supply and
## demand with causes you can see, told on the Price Board ... Seasons pass in game days"): THE PRICE BOARD in Money and
## business (Life's map). Today's market day (the School's day): its season with its picture, every good's price in
## pretend market coins with its arrow (up, down or the same) and the reason in words and a picture, and what the next
## season brings (in how many days). The same day always shows the same board: nothing random, nothing to buy here.
## TRY IT AT THE MARKET opens the Market Square's try on the child's track. Reading the board is counted once a day for
## the grown-ups' page (SuccessData.market.b).

const TRY := "TRY IT AT THE MARKET"
const FOOT := "Prices move for reasons you can see: the seasons, the festival, many sellers. A season lasts %d market days."

var rows_shown := 0


func _init(p: ProfileData, save: Callable, day: int, region_id: String, track_id: String) -> void:
	super(p, save, day, region_id, track_id)
	name = "PriceBoardPage"


func _ready() -> void:
	_count_reading()
	show_board()


## Read once a day: the grown-ups' "read the Price Board on N days".
func _count_reading() -> void:
	var m := data().market
	if today > 0 and int(m.get("l", 0)) != today:
		m.l = today
		m.b = int(m.get("b", 0)) + 1
		save()


func next_season_words() -> String:
	var per := SuccessMarket.days_per_season()
	var left := per - posmod(today, per)
	var next := SuccessMarket.season_of(today + left)
	return "In %d %s: %s" % [left, "day" if left == 1 else "days", str(next.get("why", ""))]


func show_board() -> void:
	clear()
	header("The Price Board", func() -> void: closed.emit(), [], func() -> String: return SuccessMarket.board_words(today))
	var season := SuccessMarket.season_of(today)
	var top := centred_row(14)
	top.add_child(LifeIcons.new(str(season.get("icon", "question")), 64.0))
	var name_words := left_words("Market day: %s." % str(season.get("name", "")), 28, 420)
	name_words.name = "Season"
	name_words.add_theme_color_override("font_color", SchoolUi.GOLD)
	top.add_child(name_words)
	var next := left_words(next_season_words(), 18, 560)
	next.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	top.add_child(next)
	add_child(top)
	var panel := paper(1100)
	panel.name = "Board"
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	rows_shown = 0
	for row in SuccessMarket.board(today):
		col.add_child(_row(row))
		rows_shown += 1
	add_child(panel)
	var foot := centred_row(20)
	var words := left_words(FOOT % SuccessMarket.days_per_season(), 18, 620)
	words.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	foot.add_child(words)
	var go := SchoolUi.button(TRY, Color("2f7f6a"), Vector2(380, 76))
	go.name = "TryMarket"
	go.add_theme_font_size_override("font_size", 26)
	go.pressed.connect(func() -> void:
		if try_it.is_valid():
			try_it.call("market_square"))
	foot.add_child(go)
	add_child(foot)
	say(SuccessMarket.board_words(today))


func _row(row: Dictionary) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.name = "Row_" + str(row.good)
	h.add_theme_constant_override("separation", 14)
	h.add_child(LifeIcons.new(str(row.icon), 50.0))
	var name_l := left_words("%s (%s)" % [str(row.name).to_upper(), row.unit], 22, 250)
	h.add_child(name_l)
	var price := SchoolUi.words(str(row.price), 30, 70)
	price.name = "Price"
	price.add_theme_color_override("font_color", SchoolUi.GOLD)
	h.add_child(price)
	h.add_child(LifeIcons.new("price_" + str(row.trend), 46.0))
	var why: Array = row.why
	var icons: Array = row.icons
	h.add_child(LifeIcons.new(str(icons[0]) if not icons.is_empty() else "tick", 40.0))
	var because := left_words(" ".join(PackedStringArray(why)) if not why.is_empty() else "The usual price (%d)." % int(row.base),
		17, 560)
	because.name = "Why"
	h.add_child(because)
	return h
