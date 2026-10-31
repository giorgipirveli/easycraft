class_name SuccessPlaces
extends RefCounted
## Owner #115 (Success S2; the brief: "each a Life Experience or a Life-map place in the Success strand"): what the Life
## screen does for the Success strand, through owner #115's small hooks in ui/life/ (marked there):
## - fit_grid: the map's Success row holds its six areas in one row (the strand grows: smaller cards, the same frame);
## - add_places: an area with a place (data/life/life.json's "place") shows its button under its units: MY GOAL BOARD
##   (the Goal Board and the habit garden), MY CONNECTIONS BOOK, THE STORY SHELF; page() makes the place's page;
## - record_try: a finished try's book (people met and helped, promises, introductions, mentors) and the stories acted
##   (a step's "story"), into SuccessData;
## - grown_ups: the grown-ups' page's lines: the goal and its plan, the habit's days, the people, the stories.
## Success S3 (owner #115 (S3)): Money and business has two places, MY SHOP (MyShopPage) and THE PRICE BOARD
## (PriceBoardPage) (AREA_PLACES: the area is My Money Stall's, so its places are named here, not in life.json). Its
## units fill two rows, and the School's frame has no room for a row of buttons under two rows, so they are two cards
## among the units (the grid made one column wider when it needs it). after_try: a shop try (finished, or stopped for
## now) records its day in the ledger and pays its customers' gold (SuccessShop.pay); a finished market try is counted,
## the Big track's dice lesson marked seen.

const TITLES := {"goal_board": "MY GOAL BOARD", "connections_book": "MY CONNECTIONS BOOK", "story_shelf": "THE STORY SHELF",
	"shop": "MY SHOP", "price_board": "THE PRICE BOARD"}
const ICONS := {"goal_board": "goal", "connections_book": "connections", "story_shelf": "story_book", "shop": "shop",
	"price_board": "price_board"}
const ABOUT := "Goals, the habit and the Connections Book are picked from pictures in the game: nothing is typed, " \
	+ "and nothing is sent anywhere but this account's backup. Habits are counted in all, never in a row: a missed day " \
	+ "takes nothing away (habits take weeks to form). The people are the practice village's, not real people. The " \
	+ "stories are true, their facts checked with their sources."
const ABOUT_S3 := "The shop and the market use pretend market coins. The shop pays the game's own gold only for " \
	+ "customers served while your child plays (%d a customer, at most %d a day, within the game's limits): it never " \
	+ "runs by itself. The dice lesson uses pretend counters only, never gold and never a bet: it shows why games of " \
	+ "chance lose over time. No real money anywhere; for real money, the game says to talk to a grown-up."
const WORDS := {"goal_board": "Your goal, your plan and your habit garden", "connections_book": "The people you know",
	"story_shelf": "Twenty true stories", "shop": "Your shop's ledger and reviews", "price_board": "Today's market prices"}
## Owner #115 (S3): the places of an area that has more than one (or whose entry in life.json is another strand's).
const AREA_PLACES := {"money": ["shop", "price_board"]}
const CARD_COLOUR := Color("c49a12")


## The map's Success row: as many columns as areas when there are more than four, each card narrower.
static func fit_grid(grid: GridContainer) -> void:
	var n := grid.get_child_count()
	if n <= 4:
		return
	grid.columns = n
	var wide := floorf((SchoolUi.FRAME.x - 24.0 - 14.0 * (n - 1)) / n)
	for c in grid.get_children():
		if c is Button:
			(c as Button).custom_minimum_size.x = wide
			(c as Button).add_theme_font_size_override("font_size", 18)


static func place_of(area_id: String) -> String:
	return str(LifeCatalog.area(area_id).get("place", ""))


## Every place of an area (S3: Money and business has two).
static func places_of(area_id: String) -> Array[String]:
	var out: Array[String] = []
	for p: Variant in AREA_PLACES.get(area_id, []):
		out.append(str(p))
	var one := place_of(area_id)
	if one != "" and not out.has(one):
		out.append(one)
	return out


## Under an area's units: its place's big button (none for an area without a place). S3: an area with AREA_PLACES shows
## them as cards among its units.
static func add_places(screen: Control, area_id: String, open: Callable) -> void:
	if AREA_PLACES.has(area_id):
		_add_place_cards(screen, area_id, open)
		return
	var place := place_of(area_id)
	if not TITLES.has(place):
		return
	var row := HBoxContainer.new()
	row.name = "SuccessPlaces"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	var b := SchoolUi.button(str(TITLES[place]), Color(str(LifeCatalog.area(area_id).get("colour", "2f7f6a"))).darkened(0.15),
		Vector2(460, 84))
	b.name = "Place_" + place
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(open.bind(place))
	row.add_child(LifeIcons.new(str(ICONS[place]), 72.0))
	row.add_child(b)
	var words := SchoolUi.words(str(WORDS[place]), 20, 300)
	words.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	row.add_child(words)
	screen.add_child(row)


## Owner #115 (S3): the area's places as cards at the end of its units' grid (the last GridContainer the screen added),
## the grid laid out again for the cards it holds now: one row of up to five, else two rows of the same width.
static func _add_place_cards(screen: Control, area_id: String, open: Callable) -> void:
	var grid: GridContainer = null
	for c in screen.get_children():
		if c is GridContainer:
			grid = c
	if grid == null:
		return
	for place in places_of(area_id):
		var card := LifeCards.picture_button(str(TITLES[place]), str(ICONS[place]), CARD_COLOUR.darkened(0.2),
			Vector2(220, 230), 18)
		card.name = "Place_" + place
		card.pressed.connect(open.bind(place))
		grid.add_child(card)
	var n := grid.get_child_count()
	var per_row := n if n <= LifeScreen.AREA_ROW else ceili(n / 2.0)
	grid.columns = maxi(per_row, 1)
	var wide := floorf(minf(270.0, (SchoolUi.FRAME.x - 24.0 - 14.0 * (per_row - 1)) / maxf(per_row, 1.0)))
	var tall := 300.0 if n <= LifeScreen.AREA_ROW else 230.0
	for c in grid.get_children():
		if c is Button:
			(c as Button).custom_minimum_size = Vector2(wide, tall)
			(c as Button).add_theme_font_size_override("font_size", 20 if tall >= 300.0 else 18)


## The place's page (a SuccessPage: its `closed` goes back).
static func page(place: String, profile: ProfileData, save: Callable, today: int, region: String, track: String) -> SuccessPage:
	match place:
		"goal_board":
			return GoalBoardPage.new(profile, save, today, region, track)
		"connections_book":
			return ConnectionsBookPage.new(profile, save, today, region, track)
		"story_shelf":
			return StoryShelfPage.new(profile, save, today, region, track)
		"shop":   # owner #115 (S3)
			return MyShopPage.new(profile, save, today, region, track)
		"price_board":
			return PriceBoardPage.new(profile, save, today, region, track)
	return null


## A finished try of any Experience: its steps' "book" entries for the steps done (the Connections Book), and the stories
## its steps acted (a step's "story": the story shelf ticks them as read).
static func record_try(d: SuccessData, steps: Array, outcome: Dictionary, today: int) -> void:
	if not bool(outcome.get("finished", false)):
		return
	var log: Array = outcome.get("log", [])
	SuccessPeople.record(d, SuccessPeople.actions_from(steps, log), today)
	var done := {}
	for e: Variant in log:
		if e is Dictionary:
			done[str((e as Dictionary).get("id", ""))] = true
	for s: Variant in steps:
		if s is Dictionary and (s as Dictionary).has("story") and done.has(str((s as Dictionary).get("id", ""))):
			SuccessStories.read(d, str(s.story), today, false)


## Owner #115 (S3): after a try of any Experience, finished or stopped for now (the caller saves): My Business's shop day
## goes into the ledger (only the steps done: customers come while the child is there) and its customers pay the shop's
## gold (SuccessShop.pay: within the day's cap, through EarnRules.credit); a finished Market Square try is counted, and its
## dice lesson marked seen once its chart was watched. The gold paid (0 for any other Experience).
static func after_try(profile: ProfileData, exp_id: String, steps: Array, outcome: Dictionary, today: int) -> int:
	var d := profile.life.success
	var log: Array = outcome.get("log", [])
	match exp_id:
		"my_shop":
			var day := SuccessShop.day_from(steps, log)
			SuccessShop.record(d, day, today)
			return SuccessShop.pay(profile, int(day.customers), today)
		"market_square":
			if bool(outcome.get("finished", false)):
				d.market.t = mini(int(d.market.get("t", 0)) + 1, SuccessData.MAX_COUNT)
			for e: Variant in log:
				if e is Dictionary and str((e as Dictionary).get("id", "")) == "chart":
					d.market.x = true
	return 0


## The grown-ups' page's Success sections: [[heading, [lines]]], only what happened (honest numbers).
static func grown_ups(profile: ProfileData, _today: int) -> Array:
	var d := profile.life.success
	var out := []
	var goals: Array[String] = []
	for l: String in [SuccessGoals.grown_ups_line(d, profile), SuccessHabits.grown_ups_line(d)]:
		if l != "":
			goals.append(l)
	if d.goals_reached > 0:
		goals.append("Goals reached so far: %d." % d.goals_reached)
	if not goals.is_empty():
		out.append(["Goals and habits", goals])
	var people: Array[String] = []
	for l: String in [SuccessPeople.grown_ups_line(d), SuccessStories.grown_ups_line(d)]:
		if l != "":
			people.append(l)
	if not people.is_empty():
		out.append(["People and stories", people])
	var business: Array[String] = []   # owner #115 (S3)
	for l: String in [SuccessShop.grown_ups_line(d), SuccessMarket.grown_ups_line(d)]:
		if l != "":
			business.append(l)
	if not business.is_empty():
		business.append(ABOUT_S3 % [SuccessShop.GOLD_PER_CUSTOMER, SuccessShop.DAY_CAP])
		out.append(["My Business and the market", business])
	if not out.is_empty():
		out.append(["About Success", [ABOUT]])
	return out
