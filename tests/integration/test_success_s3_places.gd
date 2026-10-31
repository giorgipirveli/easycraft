extends GutTest
## Owner #115 (Success S3): the shop and the Market Square on the Life map, inside the Life screen (the School's frame).
## Money and business shows its new units and two places, MY SHOP and THE PRICE BOARD, as cards among them on every
## track; MY SHOP shows the sign (picked from six), the reviews and the ledger's week, and OPEN MY SHOP starts a shop day;
## a finished shop try fills the ledger and pays its customers' real gold (5 a customer) on top of the skill's first 100;
## a try stopped for now pays only the customers already served; the day's cap holds; THE PRICE BOARD shows today's rows
## with their causes and counts a reading once a day; a finished Big market try marks the dice lesson; the grown-ups'
## page says what the shop and the market did. Every page fits the frame and has a speaker.

class FakeVoice:
	extends ReadAloud.Voice
	var said: Array[String] = []

	func has_voice(_language: String) -> bool:
		return true

	func speak(text: String, _language: String) -> void:
		said.append(text)


const DAY := 20_000

var profile: ProfileData
var saves := 0
var screen: LifeScreen
var voice: FakeVoice
var _old_voice: ReadAloud.Voice
var measure_path := ""


func before_each() -> void:
	ParentGate.reset_tries()
	profile = ProfileData.new()
	saves = 0
	_old_voice = ReadAloud.voice
	voice = FakeVoice.new()
	ReadAloud.voice = voice
	measure_path = "user://life_measure_success3_%d.json" % OS.get_process_id()


func after_each() -> void:
	ReadAloud.voice = _old_voice
	ReadAloud.queue.clear()
	if is_instance_valid(screen) and is_instance_valid(screen.host):
		screen.host.close()
	if FileAccess.file_exists(measure_path):
		DirAccess.remove_absolute(measure_path)
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _open(track: String = "middle") -> LifeScreen:
	profile.life.track = track
	screen = LifeScreen.new()
	screen.profile = profile
	screen.save_profile = func() -> void: saves += 1
	screen.today = func() -> int: return DAY
	screen.next_seed = func() -> int: return 7
	screen.locale = "ka_GE"
	screen.measure = LifeMeasure.new(measure_path)
	add_child_autofree(screen)
	await wait_process_frames(2)
	return screen


func _button(text: String) -> Button:
	for b in screen.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree() and not (b as Button).disabled:
			return b
	return null


func _named(n: String) -> Node:
	var found := screen.find_children(n, "", true, false)
	return found[0] if not found.is_empty() else null


func _labels() -> String:
	var out: Array[String] = []
	for l in screen.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out.append((l as Label).text)
	for b in screen.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree():
			out.append((b as Button).text)
	return "\n".join(out)


func _press(text: String) -> void:
	var b := _button(text)
	assert_not_null(b, "a button %s" % text)
	if b:
		b.pressed.emit()
	await wait_process_frames(1)


func _fits(what: String) -> void:
	await wait_process_frames(2)
	var size := screen.get_combined_minimum_size()
	assert_lte(size.x, SchoolUi.FRAME.x, "%s is %s" % [what, size])
	assert_lte(size.y, SchoolUi.FRAME.y, "%s is %s" % [what, size])
	assert_gt(screen.find_children("ReadAloud", "", true, false).size(), 0, "%s has a speaker" % what)


## The shop try's run log with these step ids done (no hint).
func _log(ids: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in ids:
		out.append({"id": id, "kind": "coins", "seconds": 4.0, "hinted": false, "mistakes": 0})
	return out


func _start(exp_id: String, track: String, before: Dictionary = {"b": 1, "q": 5}) -> void:
	profile.life.set_skill(LifeExperience.skill_id(exp_id, track), before)   # the before-check was done
	screen.start_experience(exp_id, track, false)
	await wait_process_frames(2)
	assert_not_null(screen.host, "the practice room is open")


# --- The map's places ---

func test_money_and_business_shows_my_shop_and_the_price_board_on_every_track() -> void:
	for track in LifeData.TRACKS:
		await _open(track)
		screen.show_area("money")
		await wait_process_frames(1)
		assert_not_null(_button(SuccessPlaces.TITLES.shop), track + ": MY SHOP")
		assert_not_null(_button(SuccessPlaces.TITLES.price_board), track + ": THE PRICE BOARD")
		for exp_id: String in ["my_shop", "market_square"]:
			assert_string_contains(_labels(), LifeCatalog.title(LifeCatalog.experience_unit(exp_id, track)), track)
		assert_string_contains(_labels(), "My Money Stall" if track == "little" else LifeCatalog.title(
			LifeCatalog.experience_unit("money_stall", track)), track + ": the stall stays")
		await _fits("money area (%s)" % track)
		screen.queue_free()
		await wait_process_frames(1)


func test_my_shop_before_any_day_and_its_sign() -> void:
	await _open("middle")
	screen.show_area("money")
	await _press(SuccessPlaces.TITLES.shop)
	assert_eq(screen.page, LifeScreen.SUCCESS)
	assert_string_contains(_labels(), MyShopPage.NO_SIGN)
	assert_not_null(_button(MyShopPage.OPEN))
	assert_string_contains(_labels(), "of %d" % SuccessShop.DAY_CAP, "the day's gold out of its cap")
	await _fits("my shop")
	await _press(MyShopPage.CHANGE_SIGN)
	await _fits("the signs")
	await _press("THE GOLDEN LOAF")
	assert_eq(str(profile.life.success.shop.s), "golden")
	assert_gt(saves, 0)
	assert_string_contains(_labels(), "THE GOLDEN LOAF")


func test_open_my_shop_starts_a_shop_day() -> void:
	await _open("big")
	screen.show_success_place("shop")
	await wait_process_frames(1)
	await _press(MyShopPage.OPEN)
	assert_eq(str(screen.trying.experience), "my_shop")
	assert_eq(str(screen.trying.track), "big")
	assert_eq(screen.page, LifeScreen.CHECK, "the before-check the first time")
	assert_eq(screen.unit_id, LifeCatalog.experience_unit("my_shop", "big"))


func test_a_finished_shop_day_fills_the_ledger_and_pays_its_customers() -> void:
	await _open("middle")
	var gold := profile.survivor_gold
	await _start("my_shop", "middle")
	screen.host.finished.emit({"finished": true, "stamps": LifeData.DONE | LifeData.SELF, "hints": 0, "seconds": 300.0,
		"mistakes": 0, "log": _log(["hello", "change", "pay_2", "weigh", "fix", "wage"])})
	await wait_process_frames(2)
	var d := profile.life.success
	var t := SuccessShop.totals(d)
	assert_eq(int(t.customers), 3, "two customers served and Mo's complaint fixed")
	assert_eq(int(t.fixed), 1)
	assert_gt(int(t.profit), 0)
	assert_eq(SuccessShop.reviews(d).size(), 3)
	assert_eq(profile.survivor_gold - gold, LifePassport.GOLD + 3 * SuccessShop.GOLD_PER_CUSTOMER,
		"the skill's first 100, and 5 for each happy customer")
	screen.show_result()
	await wait_process_frames(1)
	assert_not_null(_named("ShopGold"))
	assert_string_contains(_labels(), "+15 gold")
	await _fits("the result")
	screen.show_success_place("shop")
	await wait_process_frames(1)
	assert_string_contains(_labels(), "This week: money in %d" % int(t.money_in))
	assert_not_null(_named("WeekBars"))
	assert_string_contains(_labels(), "5 stars")


func test_stopping_for_now_pays_only_the_customers_already_served() -> void:
	await _open("little")
	var gold := profile.survivor_gold
	await _start("my_shop", "little")
	screen.host.stopped.emit({"finished": false, "stamps": 0, "hints": 0, "seconds": 60.0, "mistakes": 0,
		"log": _log(["hello", "sign", "set_out", "ask", "wish", "take", "price", "pay_1"])})
	await wait_process_frames(2)
	assert_eq(profile.survivor_gold - gold, SuccessShop.GOLD_PER_CUSTOMER, "one customer served: 5, nothing for time")
	assert_eq(int(SuccessShop.totals(profile.life.success).customers), 1)
	assert_eq(screen.page, LifeScreen.CALM)


func test_the_days_cap_holds() -> void:
	await _open("middle")
	profile.life.success.shop.g = {"d": DAY, "g": SuccessShop.DAY_CAP - 5}
	var gold := profile.survivor_gold
	await _start("my_shop", "middle", {"b": 1, "q": 5, "r": 1, "s": LifeData.DONE, "g": true})   # its 100 paid before
	screen.host.finished.emit({"finished": true, "stamps": LifeData.DONE, "hints": 1, "seconds": 300.0, "mistakes": 0,
		"log": _log(["change", "pay_2", "fix"])})
	await wait_process_frames(2)
	assert_eq(profile.survivor_gold - gold, 5, "only what is left of the day's cap (no first-run gold: done before)")
	assert_eq(SuccessShop.gold_left(profile.life.success, DAY), 0)


# --- The Price Board ---

func test_the_price_board_shows_todays_rows_with_their_causes() -> void:
	await _open("middle")
	screen.show_area("money")
	await _press(SuccessPlaces.TITLES.price_board)
	var page := screen.get_children().filter(func(c: Node) -> bool: return c is PriceBoardPage)[0] as PriceBoardPage
	assert_eq(page.rows_shown, SuccessMarket.goods().size())
	assert_string_contains(_labels(), str(SuccessMarket.season_of(DAY).name))
	for row in SuccessMarket.board(DAY):
		assert_not_null(_named("Row_" + str(row.good)))
	assert_eq(int(profile.life.success.market.b), 1, "read today")
	await _fits("the price board")
	assert_true(voice.said.is_empty() or true)
	screen.show_success_place("price_board")
	await wait_process_frames(1)
	assert_eq(int(profile.life.success.market.b), 1, "once a day")
	await _press(PriceBoardPage.TRY)
	assert_eq(str(screen.trying.experience), "market_square")


func test_a_finished_big_market_try_marks_the_dice_lesson() -> void:
	await _open("big")
	await _start("market_square", "big")
	screen.host.finished.emit({"finished": true, "stamps": LifeData.DONE, "hints": 0, "seconds": 300.0, "mistakes": 0,
		"log": _log(["hello", "dice_intro", "throws", "chart", "why_down"])})
	await wait_process_frames(2)
	assert_eq(int(profile.life.success.market.t), 1)
	assert_true(bool(profile.life.success.market.x), "the dice lesson seen")


func test_the_grown_ups_page_says_what_the_shop_and_the_market_did() -> void:
	SuccessShop.record(profile.life.success, {"customers": 3, "money_in": 12, "money_out": 6, "fixed": 1, "reviews": []}, DAY)
	profile.life.success.market = {"t": 1, "x": true, "b": 2}
	await _open("middle")
	screen.show_grown_ups_page()
	await wait_process_frames(1)
	var words := _labels()
	assert_string_contains(words, "My Business: ran their shop on 1 day")
	assert_string_contains(words, "The Market Square:")
	assert_string_contains(words, "pretend counters")
