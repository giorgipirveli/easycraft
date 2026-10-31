extends GutTest
## Owner #85 (Wordle's lesson; brief 2026-09-30 item 1): TODAY'S MISSION in the School's own panel. The map's gold button
## opens it; its intro says the same mission goes to every child of the grade today and names today's subjects; the
## round is DailyMission's 5 exercises, each answer kept at once (STOP and GO ON go on at the next); the end shows the
## result card (the date, the grade, the stars, "Today's Mission: 4 of 5!", the invite code, never an answer), the gold
## once a day, the mission days and rest days, SHARE / COPY / SAVE PICTURE and the grown-ups' line. A finished day opens
## on its card again. Every page fits the School's frame. The page works on its own profile, day and hooks.

const DAY := 20_726   # 2026-09-30

var profile: ProfileData
var saves := 0
var screen: SchoolScreen
var page: DailyPage
var copied: Array[String] = []
var shared: Array = []
var kept: Array = []


func before_each() -> void:
	Curriculum.clear_cache()
	profile = ProfileData.new()
	profile.survivor_gold = 25
	profile.school.grade = 4
	profile.invite.code = "BLUE-OTTER-42"
	saves = 0
	copied.clear()
	shared.clear()
	kept.clear()


func after_each() -> void:
	Curriculum.clear_cache()


func after_all() -> void:
	Audio.stop_all()


func _school() -> SchoolScreen:
	screen = SchoolScreen.new()
	screen.profile = profile
	screen.save_profile = func() -> void: saves += 1
	screen.today = func() -> int: return 7
	screen.daily_today = func() -> int: return DAY
	screen.next_seed = func() -> int: return 7
	add_child_autofree(screen)
	await wait_process_frames(2)
	return screen


func _page(sharing: bool = true, picture: bool = true) -> DailyPage:
	page = DailyPage.new()
	page.profile = profile
	page.save_profile = func() -> void: saves += 1
	page.today = func() -> int: return DAY
	page.grade = 4
	page.copy_text = func(t: String) -> void: copied.append(t)
	page.can_share = func() -> bool: return sharing
	page.share = func(t: String, u: String, png: PackedByteArray) -> String:
		shared.append([t, u, png.size()])
		return ""
	page.save_png = func(png: PackedByteArray) -> Dictionary:
		kept.append(png.size())
		return {"text": "Saved to your Gallery!", "path": "user://x.png"}
	page.render = func(c: Control) -> Image:
		c.free()
		return Image.create_empty(64, 40, false, Image.FORMAT_RGB8) if picture else null
	add_child_autofree(page)
	await wait_process_frames(2)
	return page


func _labels(root: Node) -> Array[String]:
	var out: Array[String] = []
	for l in root.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out.append((l as Label).text)
	return out


func _button(root: Node, node_name: String) -> Button:
	var found := root.find_children(node_name, "Button", true, false)
	return found[0] if not found.is_empty() and (found[0] as Button).is_visible_in_tree() else null


func _answer_all(rights: Array) -> void:
	for right: bool in rights:
		assert_eq(page.page, DailyPage.ROUND)
		page.exercise_panel.answered.emit(right)
		await wait_process_frames(1)


func test_the_map_has_todays_mission_and_it_opens_in_the_school() -> void:
	await _school()
	var b := _button(screen, "DailyMission")
	assert_not_null(b, "the gold button on the map")
	assert_eq(b.text, "TODAY'S MISSION")
	b.pressed.emit()
	await wait_process_frames(2)
	assert_eq(screen.page, SchoolScreen.DAILY)
	assert_not_null(screen.daily)
	assert_eq(screen.daily.page, DailyPage.INTRO)
	assert_has(_labels(screen), DailyMission.intro_words(4))
	_button(screen, "Back").pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.page, SchoolScreen.MAP, "BACK: the map")


func test_the_intro_names_the_day_and_todays_subjects() -> void:
	await _page()
	assert_eq(page.page, DailyPage.INTRO)
	var labels := _labels(page)
	assert_has(labels, "30 September 2026")
	assert_has(labels, DailyMission.intro_words(4))
	var subjects := page.find_children("Subjects", "", true, false)[0] as HBoxContainer
	assert_eq(subjects.get_child_count(), 5, "five subjects today")
	assert_eq(_button(page, "Start").text, "START")
	assert_eq(page.find_children("Week", "", true, false).size(), 0, "no week row before the first mission day")


func test_five_answers_make_the_card_and_pay_the_days_gold_once() -> void:
	await _page()
	_button(page, "Start").pressed.emit()
	await wait_process_frames(1)
	assert_eq(page.page, DailyPage.ROUND)
	assert_eq(page.exercise_panel.first_try_gold, Callable(), "no answer gold in the mission: its own line pays")
	await _answer_all([true, false, true, true, true])
	assert_eq(page.page, DailyPage.DONE)
	assert_eq(profile.daily.stars_of(DAY), "10111")
	assert_eq(profile.daily.total, 1)
	assert_eq(profile.survivor_gold, 25 + 4 * EarnRules.DAILY_STAR_GOLD)
	var labels := _labels(page)
	assert_has(labels, "Today's Mission: 4 of 5!")
	assert_has(labels, EarnRules.daily_words(4 * EarnRules.DAILY_STAR_GOLD))
	assert_has(labels, DailyMission.GROWN_UPS_LINE)
	assert_has(labels, "BLUE-OTTER-42", "the card carries the invite code")
	assert_eq(profile.social.learned_day, DailyMission.today(), "friends will hear this child learned today")
	# The card: the date, the grade, the stars, never a question.
	var card := page.card
	assert_eq(card.stars, "10111")
	assert_eq(card.grade, 4)
	for ex: Dictionary in page.plan:
		assert_does_not_have(_labels(card), str(ex.get("prompt", "")), "no question on the card")
	# Opening it again the same day: the card, no gold again.
	page.queue_free()
	await wait_process_frames(1)
	await _page()
	assert_eq(page.page, DailyPage.DONE)
	assert_eq(profile.survivor_gold, 25 + 4 * EarnRules.DAILY_STAR_GOLD, "once a day")
	assert_does_not_have(_labels(page), EarnRules.daily_words(4 * EarnRules.DAILY_STAR_GOLD))


func test_stop_keeps_the_answers_and_go_on_comes_back_to_the_next() -> void:
	await _page()
	_button(page, "Start").pressed.emit()
	await wait_process_frames(1)
	await _answer_all([true, true])
	_button(page, "Stop").pressed.emit()
	await wait_process_frames(1)
	assert_eq(page.page, DailyPage.INTRO)
	assert_eq(profile.daily.stars_of(DAY), "11", "kept")
	var go_on := _button(page, "Start")
	assert_eq(go_on.text, "GO ON: 2 OF 5 DONE")
	go_on.pressed.emit()
	await wait_process_frames(1)
	assert_eq(page.index, 2)
	assert_eq(page.exercise_panel.ex, page.plan[2], "the third question: the same mission all day")


func test_share_copy_and_save_the_picture() -> void:
	for right: bool in [true, true, true, false, true]:
		profile.daily.answer(DAY, 4, right)
	await _page(true)
	_button(page, "Copy").pressed.emit()
	assert_eq(copied, [DailyMission.share_text(DAY, 4, "11101", "BLUE-OTTER-42")] as Array[String])
	_button(page, "Share").pressed.emit()
	await wait_process_frames(2)
	assert_eq(shared.size(), 1)
	assert_eq(shared[0][0], DailyMission.share_text(DAY, 4, "11101", "BLUE-OTTER-42"))
	assert_eq(shared[0][1], InviteRules.link("BLUE-OTTER-42"))
	assert_gt(int(shared[0][2]), 0, "the picture goes with it")
	_button(page, "SavePicture").pressed.emit()
	await wait_process_frames(2)
	assert_eq(kept.size(), 1)
	assert_has(_labels(page), "Saved to your Gallery!")


func test_no_share_sheet_no_share_button_and_a_failed_picture_says_so_kindly() -> void:
	for i in DailyMission.SIZE:
		profile.daily.answer(DAY, 4, true)
	await _page(false, false)
	assert_null(_button(page, "Share"), "no share sheet here: COPY and SAVE only")
	assert_not_null(_button(page, "Copy"))
	_button(page, "SavePicture").pressed.emit()
	await wait_process_frames(2)
	assert_eq(kept.size(), 0)
	assert_has(_labels(page), CardPicture.FAILED)


func test_the_week_shows_mission_days_and_rest_days_never_missed() -> void:
	for d: int in [DAY - 3, DAY - 1]:
		for i in DailyMission.SIZE:
			profile.daily.answer(d, 4, true)
	await _page()
	var week := page.find_children("DailyWeek", "", true, false)[0] as DailyWeek
	assert_eq(week.row, [0, 0, 0, 1, 0, 1, 0] as Array[int])
	var labels := " ".join(_labels(page))
	assert_string_contains(labels, "2 mission days so far.")
	assert_string_contains(labels, DailyMission.REST_LINE)
	assert_false(labels.to_lower().contains("missed"))


func test_every_page_fits_the_frame_and_has_a_speaker() -> void:
	await _page()
	var pages := {"intro": func() -> void: page.show_intro(), "round": func() -> void: page.show_round()}
	for name: String in pages:
		(pages[name] as Callable).call()
		await wait_process_frames(2)
		var size := page.get_combined_minimum_size()
		assert_lte(size.x, SchoolUi.FRAME.x, "%s is %s" % [name, size])
		assert_lte(size.y, SchoolUi.FRAME.y, "%s is %s" % [name, size])
		assert_gt(page.find_children("ReadAloud", "", true, false).size(), 0, "%s has a speaker" % name)
	await _answer_all([true, true, false, true, true])
	await wait_process_frames(2)
	var done := page.get_combined_minimum_size()
	assert_lte(done.x, SchoolUi.FRAME.x, "the card page is %s" % done)
	assert_lte(done.y, SchoolUi.FRAME.y, "the card page is %s" % done)
	for b in page.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree():
			assert_gte((b as Button).size.y, OnlineUi.MIN_HEIGHT - 0.5, "%s is big enough" % (b as Button).text)


func test_the_map_header_still_fits_with_the_mission_button_in_every_grade() -> void:
	for g in Curriculum.grades():
		profile.school.grade = g
		await _school()
		for s: Dictionary in Curriculum.subjects(g):
			screen.show_map(str(s.id))
			await wait_process_frames(1)
			var size := screen.get_combined_minimum_size()
			assert_lte(size.x, SchoolUi.FRAME.x, "grade %d %s: %s" % [g, s.id, size])
			assert_lte(size.y, SchoolUi.FRAME.y, "grade %d %s: %s" % [g, s.id, size])
		screen.queue_free()
		await wait_process_frames(1)
