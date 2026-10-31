extends GutTest
## The co-op games' screens (M4 Wave 3, agent H; spec §17.5): the pause menu's FRIENDS panel has GAMES
## (beside BACK, so the panel keeps its height), which opens the GAMES page in its place — who seeks
## first (RANDOM, or anyone here, bots marked as bots), PLAY for hide-and-seek and Storm Run (a request
## the host checks; the pause menu closes so the round begins), the child's stickers, END GAME while a
## round is on. The HUD's round line follows the round and TEAM PHOTO the offer after a boss; the counting
## screen covers the counting seeker's view; the end card shows the words and the sticker.

class FlatWorld:
	extends WorldService

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < 10 else BlockIds.AIR

	func is_area_ready(_center: Vector3) -> bool:
		return true

	func find_standing_y(_x: int, _z: int) -> int:
		return 10


var world: FlatWorld
var me: Player
var bots: BotDirector
var games: GamesDirector
var _stickers: Dictionary
var _session_world: WorldService


func before_each() -> void:
	_session_world = Session.world
	_stickers = Profile.data.stickers.duplicate()
	world = FlatWorld.new()
	autofree(world)
	Session.register_world(world)


func after_each() -> void:
	Session.world = _session_world
	Profile.data.stickers = _stickers
	get_tree().paused = false


func _setup() -> void:
	me = load("res://entities/player/player.tscn").instantiate()
	me.name = str(multiplayer.get_unique_id())
	me.world = world
	add_child_autofree(me)
	me.set_physics_process(false)
	me.viewer.free()
	me._spawned = true
	me.global_position = Vector3(0.5, 10, 0.5)
	var container := Node3D.new()
	add_child_autofree(container)
	bots = BotDirector.new()
	bots.container = container
	bots.world = world
	bots.spawn = func(data: Dictionary) -> Node:
		var b := BotFriend.new()
		b.setup(data)
		b.world = world
		container.add_child(b)
		b.set_physics_process(false)
		return b
	add_child_autofree(bots)
	games = GamesDirector.new()
	games.world = world
	games.bot_list = bots.bots
	games.tell = func(_peer: int, _text: String) -> void: pass
	games.save_profile = func() -> void: pass
	games.find_spots = func(_o: Vector3i, _s: Vector3i) -> Array[Vector3i]: return [] as Array[Vector3i]
	games.local_player = me
	add_child_autofree(games)
	games.set_process(false)
	games.set_physics_process(false)
	await get_tree().physics_frame
	bots.add(BotRules.EXPLORER)


func _find(root: Node, node_name: String) -> Button:
	return root.find_child(node_name, true, false) as Button


func test_the_friends_panel_opens_the_games_page_in_its_place() -> void:
	await _setup()
	var menu := PauseMenu.new()
	add_child_autofree(menu)
	menu.friends = bots
	menu.visible = true   # open, without pausing the test's tree
	menu._show_buttons()
	await get_tree().process_frame
	_find(menu, "Friends").pressed.emit()
	await wait_process_frames(2)
	var panel := menu.find_children("*", "FriendsPanel", true, false)[0] as FriendsPanel
	var games_button := _find(panel, "Games")
	assert_not_null(games_button, "GAMES beside BACK")
	assert_not_null(_find(panel, "Back"))
	var height := panel.get_combined_minimum_size().y
	games_button.pressed.emit()
	await wait_process_frames(2)
	var page := panel.find_children("*", "GamesPanel", true, false)
	assert_eq(page.size(), 1, "the GAMES page")
	assert_false(_find(panel, "AddBuilder").is_visible_in_tree(), "in the friends' place")
	assert_lte(panel.get_combined_minimum_size().y, 700.0, "it fits the 720 px screen")
	assert_lte(height, 700.0)
	_find(panel, "GamesBack").pressed.emit()
	await wait_process_frames(2)
	assert_eq(panel.find_children("*", "GamesPanel", true, false).size(), 0)
	assert_true(_find(panel, "AddBuilder").is_visible_in_tree(), "back to the friends")


func test_play_asks_for_a_round_with_the_chosen_seeker_and_closes_the_menu() -> void:
	await _setup()
	var menu := PauseMenu.new()
	add_child_autofree(menu)
	menu.visible = true   # open, without pausing the test's tree
	var page := GamesPanel.new()
	page.director = games
	menu._set_content(page)
	await wait_process_frames(2)
	assert_eq(page.seeker_button.text, "SEEKER: RANDOM")
	page.seeker_button.pressed.emit()
	assert_eq(page.seeker_choice(), GameRules.player_key(me.peer_id))
	page.seeker_button.pressed.emit()
	var bot := bots.bots()[0]
	assert_eq(page.seeker_button.text, "SEEKER: %s" % BotRules.chat_name(bot.bot_name), "a bot is marked as a bot")
	page.hide_play.pressed.emit()
	assert_true(games.running(), "the host started the round")
	assert_eq(games.hide.seekers, [GameRules.bot_key(bot.bot_name)] as Array[String])
	assert_false(menu.visible, "the pause menu closes: the round begins")
	assert_false(get_tree().paused)
	page.refresh()
	assert_true(page.hide_play.disabled and page.storm_play.disabled, "one round at a time")
	assert_true(page.end_button.visible)
	page.end_button.pressed.emit()
	assert_false(games.running(), "END GAME")


func test_the_page_shows_the_best_and_the_childs_stickers() -> void:
	await _setup()
	games.storm_best = 17
	Profile.data.stickers = {"hide_seek": 3}
	var page := GamesPanel.new()
	page.director = games
	add_child_autofree(page)
	assert_eq(page.best_label.text, "Best: 17 stars")
	assert_string_contains(page.stickers_label.text, "Hide & Seek 3")
	assert_false(page.end_button.visible, "no round on")


func test_the_hud_follows_the_round_and_the_photo_offer() -> void:
	await _setup()
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(me, "Kid", true, false)
	hud.setup_games(games)
	assert_false(hud.game_line.visible, "no round, no line")
	assert_false(hud.team_photo_button.visible)
	games.start_storm(me.global_position)
	assert_true(hud.game_line.visible)
	assert_string_contains(hud.game_line.label.text, "Stars: 0")
	assert_false(hud.game_line.mouse_filter == Control.MOUSE_FILTER_STOP, "a label, never a button")
	games.offer_photo()
	assert_true(hud.team_photo_button.visible, "TEAM PHOTO after a boss")
	assert_has(hud.look_area.blockers, hud.team_photo_button, "a tap on it never builds")
	hud.team_photo_button.pressed.emit()
	assert_false(games._photo.is_empty(), "a tap asks for the photo")
	assert_false(hud.team_photo_button.visible, "and it goes")


func test_the_counting_screen_covers_the_seekers_view_only() -> void:
	await _setup()
	var overlay := GameOverlay.new()
	overlay.director = games
	add_child_autofree(overlay)
	var bot := bots.bots()[0]
	games.start_hide_seek(games._participants(), GameRules.bot_key(bot.bot_name))
	await wait_process_frames(2)
	assert_false(overlay.counting.visible, "a hider sees the world to hide in")
	games.hide = HideSeekRound.new()
	games.start_hide_seek(games._participants(), GameRules.player_key(me.peer_id))
	await wait_process_frames(2)
	assert_true(overlay.counting.visible, "the seeker counts")
	assert_eq(overlay.number.text, "30")
	assert_eq(overlay.mouse_filter, Control.MOUSE_FILTER_IGNORE, "never takes a tap")
	games.hide.advance(HideSeekRound.COUNT_TIME + 0.1)
	await wait_process_frames(2)
	assert_false(overlay.counting.visible, "ready or not")
	games.found(GameRules.player_key(me.peer_id), GameRules.bot_key(bot.bot_name))
	await wait_process_frames(1)
	assert_true(overlay.end_card.visible, "the end card")
	assert_eq(overlay.end_text.text, GameWords.end_hide(HideSeekRound.ALL_FOUND))
	assert_string_contains(overlay.sticker_text.text, "Hide & Seek sticker")
