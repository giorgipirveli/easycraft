extends GutTest
## M3 Task 12 (spec §5.8, §14.11): the pause menu's BOARD row, the adventure board (three picture goals,
## progress bars, pick a new one, the title, the pet's present) and the trophy room (badges on shelves,
## the sticker book). Everything is a picture with a few words, and every page fits the screen.

const SCREEN := Vector2(1280, 720)

var d: ProgressData
var survivor := [false]
var asked_gold: Array = []
var _saved := {}


func before_each() -> void:
	_saved = {"survivor": Progress.survivor, "ask_goal_gold": Progress.ask_goal_gold, "ask_present": Progress.ask_present}
	d = ProgressData.new()
	survivor[0] = false
	asked_gold = []
	Progress.begin(d)
	Progress.survivor = func() -> bool: return survivor[0]
	Progress.ask_goal_gold = func(goal_id: StringName) -> void: asked_gold.append(goal_id)
	Progress.ask_present = func(_gift_id: StringName) -> void: pass


func after_each() -> void:
	Progress.end()
	for key: String in _saved:
		Progress.set(key, _saved[key])
	get_tree().paused = false


func _menu() -> PauseMenu:
	var m := PauseMenu.new()
	add_child_autofree(m)
	return m


func _button(root: Node, prefix: String) -> Button:
	for b: Button in root.find_children("*", "Button", true, false):
		if b.visible and b.text.begins_with(prefix):
			return b
	return null


func _named(root: Node, node_name: String) -> Control:
	var found := root.find_children(node_name, "Control", true, false)
	return found[0] as Control if found.size() > 0 else null


func _panel(m: PauseMenu) -> PanelContainer:
	return m.find_children("*", "PanelContainer", true, false)[0] as PanelContainer


func _fits(m: PauseMenu, what: String) -> void:
	await wait_process_frames(2)
	var panel := _panel(m)
	assert_lte(panel.size.y, SCREEN.y - 20.0, "%s fits the screen's height" % what)
	assert_lte(panel.size.x, SCREEN.x - 20.0, "%s fits the screen's width" % what)


func _open_board() -> PauseMenu:
	var m := _menu()
	m.open()
	await wait_process_frames(2)
	_button(m, "BOARD").pressed.emit()
	await wait_process_frames(2)
	return m


func test_the_pause_menu_has_a_board_row_and_still_fits() -> void:
	var m := _menu()
	m.show_monsters_setting(true)
	var director := BotDirector.new()
	add_child_autofree(director)
	m.friends = director
	m.open()
	await wait_process_frames(2)
	assert_lte(_panel(m).size.y, 720.0 - 40.0, "RESUME to SAVE & QUIT with BOARD fits the 720 px screen")
	var ys: Array[float] = []
	for prefix in ["RESUME", "SETTINGS", "FRIENDS", "BOARD", "SAVE"]:
		assert_not_null(_button(m, prefix), prefix)
		ys.append(_button(m, prefix).get_global_rect().position.y)
	var sorted := ys.duplicate()
	sorted.sort()
	assert_eq(ys, sorted, "BOARD right above SAVE & QUIT")
	assert_gte(_button(m, "BOARD").size.y, 86.0, "a big button")


func test_the_board_shows_the_level_and_three_picture_goals() -> void:
	d.record(&"photo_taken")
	var m: PauseMenu = await _open_board()
	var board := m.find_children("*", "AdventureBoard", true, false)[0] as AdventureBoard
	assert_not_null(board)
	assert_string_contains(board.level_label.text, "Level 1")
	assert_almost_eq(board.xp_bar.value, float(d.xp), 0.01)
	assert_eq(board.xp_bar.max_value, float(LevelRules.level_progress(d.xp).y))
	for i in BoardRules.SLOTS:
		var card := _named(m, "Card%d" % i) as Button
		assert_not_null(card, "card %d" % i)
		assert_gte(card.size.x, 135.0)
		assert_gte(card.size.y, 135.0)
		assert_eq(card.find_children("*", "ProgressPicture", true, false).size(), 1, "a picture on every card")
	assert_string_contains(_named(m, "Card2").get_meta(&"words"), "Find 3 secrets")
	await _fits(m, "the board")


func test_tapping_a_card_opens_the_list_and_a_pick_puts_the_goal_up() -> void:
	var m: PauseMenu = await _open_board()
	(_named(m, "Card1") as Button).pressed.emit()
	await wait_process_frames(2)
	var tiles := m.find_children("Pick_*", "Button", true, false)
	assert_eq(tiles.size(), BoardRules.choices(d).size(), "every goal not on the board")
	for t: Button in tiles:
		assert_gte(t.size.x, 120.0)
		assert_eq(t.find_children("*", "ProgressPicture", true, false).size(), 1, "each goal a picture")
	await _fits(m, "the goal list")
	(_named(m, "Pick_find_geode") as Button).pressed.emit()
	await wait_process_frames(2)
	assert_eq(d.board[1].goal, "find_geode")
	assert_not_null(_named(m, "Card1"), "back on the board")
	assert_string_contains(_named(m, "Card1").get_meta(&"words"), "Find a geode")


func test_a_done_goal_says_so_and_waits_for_a_new_pick() -> void:
	Progress.event(&"photo_taken")
	assert_true(d.board[0].done)
	var m: PauseMenu = await _open_board()
	assert_string_contains(_named(m, "Card0").get_meta(&"words"), "Done")
	(_named(m, "Card0") as Button).pressed.emit()
	await wait_process_frames(2)
	assert_not_null(_named(m, "Pick_take_photos"))


func test_the_title_page_offers_the_earned_titles() -> void:
	d.style_xp = {"builder": 300, "photo": 60}
	var m: PauseMenu = await _open_board()
	(_named(m, "Title") as Button).pressed.emit()
	await wait_process_frames(2)
	assert_false((_named(m, "Title_builder") as Button).disabled)
	assert_false((_named(m, "Title_photo") as Button).disabled)
	assert_true((_named(m, "Title_boss") as Button).disabled, "a title still to earn shows, locked")
	await _fits(m, "the titles")
	(_named(m, "Title_photo") as Button).pressed.emit()
	await wait_process_frames(2)
	assert_eq(Progress.shown_title(), &"photo")
	assert_string_contains((_named(m, "Title") as Button).text, "Photographer")


## Owner #45a: a goal that counts somewhere else says where ("in Monster Wave", "in the Sandstorm Desert").
func test_the_list_says_where_a_goal_counts_when_it_is_not_here() -> void:
	var mode_before := Game.mode
	var universe_before := Game.universe
	Game.mode = ModeRules.SANDBOX
	Game.universe = 1
	var m: PauseMenu = await _open_board()
	(_named(m, "Card0") as Button).pressed.emit()
	await wait_process_frames(2)
	var where := func(id: String) -> String:
		var tile := _named(m, "Pick_%s" % id)
		return " ".join(tile.find_children("Where", "Label", true, false).map(func(l: Label) -> String: return l.text))
	assert_eq(where.call("beat_serpent"), "in Monster Wave")
	assert_eq(where.call("desert_secrets"), "in the Sandstorm Desert")
	assert_eq(where.call("craft_glass"), "in Survivor")
	assert_eq(where.call("find_geode"), "", "a goal of every mode and place says nothing")
	await _fits(m, "the goal list")
	Game.mode = mode_before
	Game.universe = universe_before


## Owner #45a: a quest story done gives its title to pick (only once it is done), and the page still fits.
func test_a_finished_storys_title_can_be_picked() -> void:
	d.quests.done.append("zara_scarab")
	var m: PauseMenu = await _open_board()
	(_named(m, "Title") as Button).pressed.emit()
	await wait_process_frames(2)
	assert_null(_named(m, "Title_q_tilly_map"), "a story not done yet gives no title")
	var b := _named(m, "Title_q_zara_scarab") as Button
	assert_not_null(b)
	assert_eq(b.text, "Pyramid Pal")
	await _fits(m, "the titles with a story's")
	b.pressed.emit()
	await wait_process_frames(2)
	assert_eq(Progress.shown_title(), &"q_zara_scarab")
	assert_eq(Progress.tag(), "1:q_zara_scarab")
	assert_false(Progress.choose_title(&"q_tilly_map"), "not earned")


func test_a_waiting_present_opens_a_choice_of_three_gifts() -> void:
	d.present_waiting = true
	var m: PauseMenu = await _open_board()
	assert_not_null(_named(m, "Present"), "the present waits on the board")
	await _fits(m, "the board with a present")
	(_named(m, "Present") as Button).pressed.emit()
	await wait_process_frames(2)
	var gifts := m.find_children("Gift_*", "Button", true, false)
	assert_eq(gifts.size(), 3)
	await _fits(m, "the present")
	(_named(m, "Gift_gift_star") as Button).pressed.emit()
	await wait_process_frames(2)
	assert_false(d.present_waiting)
	assert_eq(int(d.stickers.get("gift_star", 0)), 1)
	assert_null(_named(m, "Present"), "opened")


func test_the_trophy_room_shows_every_badge_on_shelves() -> void:
	d.achievements = ["first_pet", "say_cheese"] as Array[String]
	var m: PauseMenu = await _open_board()
	_button(m, "TROPHIES").pressed.emit()
	await wait_process_frames(2)
	var badges := m.find_children("Badge_*", "Control", true, false)
	assert_eq(badges.size(), AchievementRules.BADGES.size())
	assert_false((_named(m, "Badge_first_pet").find_children("*", "ProgressPicture", true, false)[0] as ProgressPicture).dim)
	assert_true((_named(m, "Badge_golem").find_children("*", "ProgressPicture", true, false)[0] as ProgressPicture).dim,
		"a badge still to find is a shadow")
	var room := m.find_children("*", "TrophyRoom", true, false)[0] as TrophyRoom
	assert_eq(room.count_label.text, "2 of %d badges" % AchievementRules.BADGES.size())
	await _fits(m, "the trophy room")
	_button(m, "STICKERS").pressed.emit()
	await wait_process_frames(2)
	assert_eq(m.find_children("Sticker_*", "Control", true, false).size(),
		BoardRules.GOALS.size() + PresentRules.STICKERS.size() + BookPages.PAGES.size())   # M3 Task 21b: page stickers
	await _fits(m, "the sticker book")
	_button(m, "BACK").pressed.emit()
	await wait_process_frames(2)
	_button(m, "BACK").pressed.emit()
	await wait_process_frames(2)
	assert_not_null(_named(m, "Card0"), "back to the board")
	_button(m, "BACK").pressed.emit()
	await wait_process_frames(2)
	assert_not_null(_button(m, "RESUME"), "back to the menu")
