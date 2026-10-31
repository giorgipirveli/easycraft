extends GutTest
## M3 Task 17 (spec §5.12, §14.12): the Shorts Theater in the world. The building (walls you can't walk through,
## an open door), the parent gate, the end card, and walking in and out. Owner #89 ("finish tv shows"): the panel
## with the channels as big picture tabs, a 16:9 player with the title and CLOSE above it, BACK and NEXT beside it
## (never over it), the videos as cards with their titles and makers; nothing starts by itself; the game holds its
## sound while a video is on the screen; Esc, N and B on a PC; the player (Android's plugin or the browser's page)
## through a fake; and the server's list read when the game is online.

const KID := AgeBand.UNDER_13
const TEEN := AgeBand.TEEN_PLUS
const SCREEN := Vector2i(2400, 1080)   # the emulator's landscape screen
const CACHE := "user://test_theater_director_cache.json"


## Stands in for the players (TheaterWebView on Android, TheaterWebPlayer in a browser): records every call.
class FakePlayer:
	extends RefCounted
	signal ended
	signal failed(code: String)
	signal stopped
	var calls: Array[String] = []
	var videos: Array[String] = []
	var autoplay_flags: Array[bool] = []
	var rects: Array[Rect2i] = []
	var close_rects: Array[Rect2i] = []

	func play(video: Dictionary, autoplay: bool, rect: Rect2i, close_rect: Rect2i) -> void:
		calls.append("play")
		videos.append(str(video.id))
		autoplay_flags.append(autoplay)
		rects.append(rect)
		close_rects.append(close_rect)

	func set_rect(rect: Rect2i, close_rect: Rect2i) -> void:
		calls.append("set_rect")
		rects.append(rect)
		close_rects.append(close_rect)

	func hide() -> void:
		calls.append("hide")

	func reveal() -> void:
		calls.append("reveal")

	func close() -> void:
		calls.append("close")


## Stands in for OnlineService: its status (and status_changed) and a backend that answers theater_channels.
class FakeService:
	extends Node
	signal status_changed(status: StringName)
	var status: StringName = OnlineService.OFFLINE
	var backend := FakeBackend.new()


class FakeBackend:
	extends RefCounted
	var reply: Dictionary = {}
	var calls := 0

	func call_rpc(_id: String, _payload: Dictionary = {}) -> Dictionary:
		calls += 1
		return reply


var _window_size: Vector2i
var _saves := 0
var _t := 0   # the gate's clock (a member: a lambda copies a local)
var sample: Dictionary
var bundled: Dictionary


func before_all() -> void:
	_window_size = get_window().size
	sample = TheaterChannels.load_path(TheaterChannels.SAMPLE_PATH)
	bundled = TheaterChannels.load_path(TheaterChannels.BUNDLED_PATH)


func before_each() -> void:
	_saves = 0
	get_window().size = SCREEN
	ParentGate.reset_tries()   # M4 Task 10 review E: one lock for every gate in the app run
	AudioServer.set_bus_mute(TheaterPanel.MASTER_BUS, false)


func after_each() -> void:
	ParentGate.reset_tries()
	AudioServer.set_bus_mute(TheaterPanel.MASTER_BUS, false)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CACHE))


func after_all() -> void:
	get_window().size = _window_size


func _profile(band: StringName, switch: StringName = TheaterRules.SWITCH_AUTO) -> ProfileData:
	var p := ProfileData.new()
	p.username = "Tester"
	p.age_band = band
	p.theater_switch = switch
	return p


func _panel(profile: ProfileData, mobile: bool = false, backend: Object = null, live: bool = false,
		list: Dictionary = sample, keyboard: bool = true) -> TheaterPanel:
	var panel := TheaterPanel.new()
	panel.list = list
	panel.profile = profile
	panel.save_profile = func() -> void: _saves += 1
	panel.is_mobile = mobile
	panel.backend = backend
	panel.live = live
	panel.keyboard = keyboard
	panel.frees_mouse = false
	panel.opens_on_shorts = false   # owner #94: these are the channels' tests (test_theater_shorts.gd: the SHORTS tab)
	add_child_autofree(panel)
	await wait_process_frames(2)
	return panel


## A phone (or a browser) with the real list and a player.
func _playing(band: StringName = TEEN, switch: StringName = TheaterRules.SWITCH_AUTO) -> Array:
	var fake := FakePlayer.new()
	var panel: TheaterPanel = await _panel(_profile(band, switch), true, fake, false, bundled)
	panel.open()
	await wait_process_frames(2)
	return [panel, fake]


func _press(b: Button) -> void:
	assert_not_null(b)
	if b:
		assert_true(b.is_visible_in_tree(), "%s is visible" % b.text)
		assert_false(b.disabled, "%s is enabled" % b.text)
		b.pressed.emit()


func _key(panel: TheaterPanel, code: Key) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	panel._unhandled_key_input(e)


# --- The building ------------------------------------------------------------------------------

func test_the_building_has_solid_walls_and_an_open_door() -> void:
	var boxes := TheaterBuilding.solid_boxes()
	assert_gt(boxes.size(), 5)
	var room := AABB(Vector3(-3.4, 0.1, -3.4), Vector3(6.8, TheaterSite.WALL_HEIGHT - 0.2, 6.8))
	var door := AABB(Vector3(-1.4, 0.1, 3.5), Vector3(2.8, 3.0, 1.0))
	for b: AABB in boxes:
		assert_false(b.intersects(room), "nothing solid inside the room: %s" % b)
		assert_false(b.intersects(door), "the door is open: %s" % b)
	# The other walls are closed: a point just outside each wall, beside the door, is inside a box.
	for p: Vector3 in [Vector3(0, 1, -4.0), Vector3(-4.0, 1, 0), Vector3(4.0, 1, 0), Vector3(-3, 1, 4.0), Vector3(3, 1, 4.0),
			Vector3(0, TheaterSite.WALL_HEIGHT + 0.5, 0), Vector3(0, -1, 0)]:
		var solid := boxes.any(func(b: AABB) -> bool: return b.has_point(p))
		assert_true(solid, "solid at %s" % p)


func test_the_building_node_stands_on_the_site_facing_its_door() -> void:
	var b := TheaterBuilding.new()
	add_child_autofree(b)
	b.setup({"pos": Vector3i(10, 40, -20), "facing": 1})
	assert_eq(b.global_position, Vector3(10.5, 40, -19.5))
	var door_world := b.global_transform.basis * Vector3(0, 0, 1)
	assert_almost_eq(door_world.x, 1.0, 0.001, "facing 1 is +X")
	var bodies := b.find_children("*", "StaticBody3D", true, false)
	assert_eq(bodies.size(), 1)
	var body := bodies[0] as StaticBody3D
	assert_eq(body.collision_layer, 1, "the world layer: players and animals collide with it")
	assert_eq(body.collision_mask, 0)
	assert_eq(body.get_child_count(), TheaterBuilding.solid_boxes().size(), "one shape per solid box")
	var meshes := b.find_children("*", "MeshInstance3D", true, false)
	assert_eq(meshes.size(), 1, "one mesh, one draw call")
	assert_eq((meshes[0] as MeshInstance3D).mesh, TheaterBuilding.shared_mesh(), "shared, built once")
	var labels := b.find_children("*", "Label3D", true, false)
	assert_gt(labels.size(), 0, "a sign")


# --- The panel on desktop (placeholder) -----------------------------------------------------------

func test_desktop_shows_a_still_and_the_title_over_a_16_9_player() -> void:
	var panel: TheaterPanel = await _panel(_profile(TEEN))
	panel.open()
	await wait_process_frames(2)
	assert_eq(panel.view, TheaterPanel.VIEW_PLAY)
	var r := panel.screen_rect()
	assert_almost_eq(r.size.x / r.size.y, 16.0 / 9.0, 0.01, "YouTube's shape")
	var vp := panel.get_viewport_rect()
	assert_almost_eq(r.get_center().x, vp.size.x / 2.0, 1.0, "in the middle of the screen")
	assert_true(panel.still.is_visible_in_tree(), "the placeholder still")
	assert_eq(panel.still.video.title, "Welcome to EasyCraft!")
	assert_eq(panel.title_label.text, "Welcome to EasyCraft!")
	assert_false(panel.title_label.get_global_rect().intersects(r), "the title is not over the player")
	assert_lt(panel.title_label.get_global_rect().end.y, r.position.y + 1.0, "the title is above it")
	assert_false(panel.close_button.is_visible_in_tree(), "no CLOSE without a real player")


func test_the_buttons_sit_beside_the_player_never_over_it() -> void:
	var panel: TheaterPanel = await _panel(_profile(TEEN), false, null, false, bundled)
	panel.open()
	await wait_process_frames(2)
	var r := panel.screen_rect()
	var vp := panel.get_viewport_rect()
	var buttons: Array = panel.find_children("*", "Button", true, false).filter(
		func(b: Node) -> bool: return (b as Control).is_visible_in_tree())
	assert_gt(panel.channel_buttons.size(), 7, "a tab per channel")
	assert_gt(buttons.size(), 15, "tabs, cards, arrows, NEXT, BACK, EXIT, Grown-ups")
	for b: Button in buttons:
		var br := b.get_global_rect()
		assert_false(br.intersects(r), "%s beside the player: %s vs %s" % [b.text.replace("\n", " "), br, r])
		assert_true(vp.encloses(br), "%s on screen" % b.text)
	assert_gt(panel.next_button.get_global_rect().position.x, r.end.x, "NEXT on the right")
	assert_lt(panel.prev_button.get_global_rect().end.x, r.position.x, "BACK on the left")
	assert_gte(panel.next_button.size.y, 110.0, "a big NEXT")
	for tab: Button in panel.channel_buttons:
		assert_lte(tab.get_global_rect().end.y, panel.title_label.get_global_rect().position.y, "%s: the tabs are above the title" % tab.tooltip_text)
	for card: Button in panel.video_cards:
		assert_gt(card.get_global_rect().position.y, r.end.y, "the cards are under the player")
	# Nothing grows out of its place: no two buttons overlap (a tall EXIT once reached the cards' arrow).
	for i in buttons.size():
		for j in range(i + 1, buttons.size()):
			var a: Button = buttons[i]
			var b: Button = buttons[j]
			if a.is_ancestor_of(b) or b.is_ancestor_of(a):
				continue
			assert_false(a.get_global_rect().grow(-0.5).intersects(b.get_global_rect().grow(-0.5)),
				"%s and %s overlap" % [a.name, b.name])
	for b: Button in [panel.next_button, panel.prev_button, panel.exit_button]:
		assert_eq(b.size.y, TheaterPanel.SIDE_BUTTON_H, "%s keeps its height" % b.text)
	assert_lte(panel.exit_button.get_global_rect().end.y, r.end.y + 1.0, "EXIT ends with the player")


## Owner #89: the channels as big picture tabs.
func test_the_channels_are_big_picture_tabs() -> void:
	var panel: TheaterPanel = await _panel(_profile(TEEN), false, null, false, bundled)
	panel.open()
	await wait_process_frames(2)
	assert_eq(panel.channel_buttons.size(), bundled.channels.size())
	for i in panel.channel_buttons.size():
		var tab := panel.channel_buttons[i] as TheaterPanel.ChannelTab
		assert_eq(tab.title, bundled.channels[i].title)
		assert_eq(tab.label.text, tab.title, "its name under its picture")
		assert_not_null(tab.picture.texture, "%s has a picture" % tab.title)
		assert_eq(tab.size, Vector2(tab.custom_minimum_size), "%s keeps its size: a long name wraps inside it" % tab.title)
		assert_gte(tab.size.y, 80.0, "%s is big" % tab.title)
		assert_gte(tab.size.x, 80.0, "%s is big" % tab.title)
	assert_eq((panel.channel_buttons[0] as TheaterPanel.ChannelTab).title, "EasyCraft TV", "EasyCraft TV first")
	assert_true(panel.channel_buttons[0].button_pressed, "the channel on the screen is chosen")
	_press(panel.channel_buttons[1])
	assert_eq(panel.session.current().channel_id, "space")
	assert_true(panel.channel_buttons[1].button_pressed)
	assert_false(panel.channel_buttons[0].button_pressed)


## Owner #89: the videos as cards with their titles (and makers), a page of four; a tap plays one.
func test_the_videos_are_cards_with_their_titles() -> void:
	var panel: TheaterPanel = await _panel(_profile(TEEN), false, null, false, bundled)
	panel.open()
	await wait_process_frames(2)
	_press(panel.channel_buttons[1])   # Space: 10 videos, 3 pages
	var space: Array = bundled.channels[1].videos
	for i in TheaterPanel.CARDS:
		assert_eq(panel.video_cards[i].video.title, space[i].title)
		assert_eq(panel.video_cards[i].video.from, space[i].from, "the maker on the card")
	assert_true(panel.video_cards[0].current, "the card of the video on the screen")
	assert_true(panel.page_next_button.is_visible_in_tree(), "more pages")
	assert_true(panel.page_prev_button.disabled, "the first page")
	_press(panel.page_next_button)
	assert_eq(panel.video_cards[0].video.title, space[4].title, "the next page")
	assert_eq(panel.session.current().index, 0, "turning a page plays nothing")
	_press(panel.video_cards[1])
	assert_eq(panel.session.current().title, space[5].title, "a tap on a card plays it")
	assert_true(panel.video_cards[1].current)
	_press(panel.page_next_button)
	assert_false(panel.video_cards[2].visible, "the last page has two cards")
	assert_true(panel.page_next_button.disabled)


func test_next_back_and_channels_on_desktop() -> void:
	var panel: TheaterPanel = await _panel(_profile(TEEN))
	panel.open()
	await wait_process_frames(1)
	assert_true(panel.prev_button.disabled, "nothing before the first video")
	_press(panel.next_button)
	assert_eq(panel.still.video.title, "Wake up a buddy with the wand")
	assert_false(panel.prev_button.disabled)
	_press(panel.prev_button)
	assert_eq(panel.still.video.title, "Welcome to EasyCraft!")
	_press(panel.channel_buttons[1])
	assert_eq(panel.session.current().channel_id, "animals")
	assert_eq(panel.still.video.title, "Puppies meet a kitten")


func test_everyone_sees_only_videos_made_for_kids() -> void:
	var panel: TheaterPanel = await _panel(_profile(TEEN))
	panel.open()
	for c: Dictionary in panel.session.channels:
		assert_ne(c.platform, TheaterChannels.TIKTOK)
		for v: Dictionary in c.videos:
			assert_true(v.made_for_kids, "%s / %s" % [c.id, v.id])


func test_exit_closes_the_panel() -> void:
	var panel: TheaterPanel = await _panel(_profile(TEEN))
	watch_signals(panel)
	panel.open()
	_press(panel.exit_button)
	assert_signal_emitted(panel, "exit_requested")
	assert_false(panel.is_open())
	assert_false(panel.visible)


# --- A PC: keys ------------------------------------------------------------------------------------

func test_esc_leaves_and_n_and_b_move() -> void:
	var panel: TheaterPanel = await _panel(_profile(TEEN))
	watch_signals(panel)
	panel.open()
	_key(panel, KEY_N)
	assert_eq(panel.session.current().title, "Wake up a buddy with the wand", "N is NEXT")
	_key(panel, KEY_B)
	assert_eq(panel.session.current().title, "Welcome to EasyCraft!", "B is BACK")
	panel.set_covered(true)
	_key(panel, KEY_ESCAPE)
	assert_true(panel.is_open(), "under a menu, Esc is the menu's")
	panel.set_covered(false)
	_key(panel, KEY_ESCAPE)
	assert_false(panel.is_open(), "Esc leaves the Theater")
	assert_signal_emitted(panel, "exit_requested")


func test_a_pc_shows_the_keys_on_the_buttons() -> void:
	var pc: TheaterPanel = await _panel(_profile(TEEN))
	for pair: Array in [[pc.next_button, "N"], [pc.prev_button, "B"], [pc.exit_button, "Esc"]]:
		var cap := (pair[0] as Button).get_node_or_null("Key") as Label
		assert_not_null(cap, "%s shows its key" % (pair[0] as Button).text)
		if cap:
			assert_eq(cap.text, pair[1])
	var phone: TheaterPanel = await _panel(_profile(TEEN), true, null, false, sample, false)
	assert_null(phone.next_button.get_node_or_null("Key"), "a phone has no keys")


# --- Children and the parent gate -----------------------------------------------------------------

func test_a_child_needs_a_grown_up_and_the_gate_turns_it_on() -> void:
	var profile := _profile(KID)
	var panel: TheaterPanel = await _panel(profile)
	panel.open()
	await wait_process_frames(1)
	assert_eq(panel.view, TheaterPanel.VIEW_ASK_PARENT)
	assert_string_contains(panel.card_label.text, "grown-up")
	_press(panel.card_button(TheaterPanel.GROWN_UPS))
	assert_eq(panel.view, TheaterPanel.VIEW_GATE)
	var q: Dictionary = panel.gate_question
	assert_string_contains(panel.card_label.text, ParentGate.words(q.a))
	# A wrong answer keeps the gate shut and asks a new question.
	for digit in str(int(q.answer) + 1):
		_press(panel.pad_buttons[digit])
	_press(panel.pad_buttons["OK"])
	assert_eq(panel.view, TheaterPanel.VIEW_GATE)
	assert_eq(profile.theater_switch, TheaterRules.SWITCH_AUTO)
	q = panel.gate_question
	for digit in str(q.answer):
		_press(panel.pad_buttons[digit])
	_press(panel.pad_buttons["OK"])
	assert_eq(panel.view, TheaterPanel.VIEW_SWITCH)
	_press(panel.card_button(TheaterPanel.TURN_ON))
	assert_eq(profile.theater_switch, TheaterRules.SWITCH_ON)
	assert_eq(_saves, 1, "the switch is saved at once")
	assert_eq(panel.view, TheaterPanel.VIEW_PLAY, "the show starts")
	for c: Dictionary in panel.session.channels:
		assert_ne(c.platform, TheaterChannels.TIKTOK)


## M4 Task 10 review E: three wrong answers rest the Theater's gate for a minute too (the same lock as the grown-up
## pages'), with a kind line saying when; a minute later a new question.
func test_three_wrong_answers_rest_the_theaters_gate_for_a_minute() -> void:
	_t = 900_000
	var profile := _profile(KID)
	var panel: TheaterPanel = await _panel(profile)
	panel.msec = func() -> int: return _t
	panel.open()
	await wait_process_frames(1)
	_press(panel.card_button(TheaterPanel.GROWN_UPS))
	for i in 3:
		var q: Dictionary = panel.gate_question
		for digit in str(int(q.answer) + 1):
			_press(panel.pad_buttons[digit])
		_press(panel.pad_buttons["OK"])
	assert_eq(panel.view, TheaterPanel.VIEW_GATE)
	assert_eq(panel.card_label.text, ParentGate.locked_text(60))
	assert_true(panel.pad_buttons.is_empty(), "no pad while it rests")
	panel.close()
	panel.open()
	_press(panel.card_button(TheaterPanel.GROWN_UPS))
	assert_eq(panel.card_label.text, ParentGate.locked_text(60), "closing and opening again keeps the rest")
	_t += 45_000
	await wait_process_frames(2)
	assert_eq(panel.card_label.text, ParentGate.locked_text(15), "it counts down")
	_t += 15_000
	await wait_process_frames(2)
	assert_false(panel.pad_buttons.is_empty(), "a minute later the pad is back")
	for digit in str(panel.gate_question.answer):
		_press(panel.pad_buttons[digit])
	_press(panel.pad_buttons["OK"])
	assert_eq(panel.view, TheaterPanel.VIEW_SWITCH)
	assert_eq(profile.theater_switch, TheaterRules.SWITCH_AUTO, "nothing changed without a grown-up's choice")


func test_a_parent_can_turn_it_off_again() -> void:
	var profile := _profile(TEEN)
	var panel: TheaterPanel = await _panel(profile)
	panel.open()
	_press(panel.grownups_button)
	assert_eq(panel.view, TheaterPanel.VIEW_GATE)
	for digit in str(panel.gate_question.answer):
		_press(panel.pad_buttons[digit])
	_press(panel.pad_buttons["OK"])
	_press(panel.card_button(TheaterPanel.TURN_OFF))
	assert_eq(profile.theater_switch, TheaterRules.SWITCH_OFF)
	assert_eq(panel.view, TheaterPanel.VIEW_ASK_PARENT)


func test_the_cards_fit_in_the_middle() -> void:
	var panel: TheaterPanel = await _panel(_profile(KID))
	panel.open()
	_press(panel.card_button(TheaterPanel.GROWN_UPS))
	_press(panel.pad_buttons["OK"])   # a wrong (empty) answer adds "Not quite" to the question
	await wait_process_frames(2)
	var r := panel.card_rect()
	assert_true(r.encloses(panel.card_label.get_global_rect()), "the question: %s in %s" % [panel.card_label.get_global_rect(), r])
	for key: String in panel.pad_buttons:
		var b: Button = panel.pad_buttons[key]
		assert_true(r.encloses(b.get_global_rect()), "key %s: %s in %s" % [key, b.get_global_rect(), r])
	assert_false(panel.video_cards[0].is_visible_in_tree(), "the player's parts step aside")
	assert_false(panel.still.is_visible_in_tree())
	panel.profile.theater_switch = TheaterRules.SWITCH_ON
	panel.close()
	panel.open()
	for i in 5:
		_press(panel.next_button)
	await wait_process_frames(2)
	for id: StringName in [TheaterPanel.BACK_TO_WORLD, TheaterPanel.MORE_SHOWS]:
		assert_true(r.encloses(panel.card_button(id).get_global_rect()), "end card: %s" % id)


func test_the_end_card_after_5_videos_for_a_child() -> void:
	var panel: TheaterPanel = await _panel(_profile(KID, TheaterRules.SWITCH_ON))
	panel.open()
	for i in 4:
		_press(panel.next_button)
		assert_eq(panel.view, TheaterPanel.VIEW_PLAY)
	_press(panel.next_button)
	assert_eq(panel.view, TheaterPanel.VIEW_END_CARD)
	assert_string_contains(panel.card_label.text, "That's the show!")
	assert_true(panel.next_button.disabled)
	assert_true(panel.prev_button.disabled)
	var home := panel.card_button(TheaterPanel.BACK_TO_WORLD)
	var more := panel.card_button(TheaterPanel.MORE_SHOWS)
	assert_not_null(home)
	assert_not_null(more)
	assert_eq(home.custom_minimum_size, more.custom_minimum_size, "two equal choices, no nudge")
	assert_eq(home.get_theme_stylebox("normal"), more.get_theme_stylebox("normal"), "the same colour")
	_press(more)
	assert_eq(panel.view, TheaterPanel.VIEW_PLAY, "more shows")
	assert_null(panel.card_button(TheaterPanel.BACK_TO_WORLD), "the card is gone")
	assert_false(panel.next_button.disabled)


func test_the_end_card_home_button_leaves() -> void:
	var panel: TheaterPanel = await _panel(_profile(KID, TheaterRules.SWITCH_ON))
	watch_signals(panel)
	panel.open()
	for i in 5:
		_press(panel.next_button)
	_press(panel.card_button(TheaterPanel.BACK_TO_WORLD))
	assert_false(panel.is_open())
	assert_signal_emitted(panel, "exit_requested")


# --- On a phone or in a browser (a player) --------------------------------------------------------

func test_a_phone_says_coming_soon_with_the_sample_list() -> void:
	var fake := FakePlayer.new()
	var panel: TheaterPanel = await _panel(_profile(TEEN), true, fake)
	panel.open()
	assert_eq(panel.view, TheaterPanel.VIEW_COMING_SOON)
	assert_string_contains(panel.card_label.text, "Coming soon")
	assert_eq(fake.calls, [], "no player while nothing is real")


func test_a_phone_without_a_player_says_coming_soon() -> void:
	var panel: TheaterPanel = await _panel(_profile(TEEN), true, null, false, bundled)
	panel.open()
	assert_eq(panel.view, TheaterPanel.VIEW_COMING_SOON)


## Owner #89: the real list plays wherever there is a player; walking in shows the video still, a pick starts it.
func test_the_real_list_plays_in_the_player_beside_the_buttons() -> void:
	var parts: Array = await _playing()
	var panel: TheaterPanel = parts[0]
	var fake: FakePlayer = parts[1]
	assert_eq(panel.view, TheaterPanel.VIEW_PLAY)
	assert_eq(fake.calls, ["play"])
	assert_eq(fake.videos[0], bundled.channels[0].videos[0].id)
	assert_false(fake.autoplay_flags[0], "walking in shows the video still")
	var px := fake.rects[0]
	gut.p("player rect in screen pixels: %s" % px)
	assert_true(TheaterRules.is_big_enough(px), "at least 200 x 200 pixels")
	assert_almost_eq(float(px.size.x) / px.size.y, 16.0 / 9.0, 0.01)
	assert_eq(fake.close_rects[0], panel.close_pixel_rect(), "the browser's CLOSE goes over the game's")
	assert_false(px.intersects(fake.close_rects[0]), "CLOSE is never over the player")
	assert_true(panel.close_button.is_visible_in_tree())
	assert_false(panel.still.is_visible_in_tree(), "no placeholder under the real player")
	_press(panel.next_button)
	assert_eq(fake.calls[-1], "play")
	assert_eq(fake.videos[-1], bundled.channels[0].videos[1].id)
	assert_true(fake.autoplay_flags[-1], "a picked video starts")
	_press(panel.channel_buttons[2])
	assert_true(fake.autoplay_flags[-1], "a tab starts its first video")
	_press(panel.video_cards[2])
	assert_eq(fake.videos[-1], bundled.channels[2].videos[2].id)
	assert_true(fake.autoplay_flags[-1], "a card starts its video")
	assert_eq(fake.calls.count("play"), 4, "one player: each video replaces the last")
	_press(panel.exit_button)
	assert_eq(fake.calls[-1], "close")


func test_nothing_starts_by_itself_when_a_video_ends() -> void:
	for band: StringName in [KID, TEEN]:
		var parts: Array = await _playing(band, TheaterRules.SWITCH_ON)
		var panel: TheaterPanel = parts[0]
		var fake: FakePlayer = parts[1]
		fake.ended.emit()
		assert_eq(fake.calls.count("play"), 1, "%s: no next video by itself" % band)
		assert_eq(panel.session.current().index, 0)
		assert_true(panel.next_glows, "%s: NEXT lights up" % band)
		_press(panel.next_button)
		assert_false(panel.next_glows)


func test_close_stops_the_video_and_play_starts_it_again() -> void:
	var parts: Array = await _playing()
	var panel: TheaterPanel = parts[0]
	var fake: FakePlayer = parts[1]
	var shown := panel.session.shown
	_press(panel.close_button)
	assert_eq(fake.calls[-1], "close")
	assert_false(panel.player_on)
	assert_false(panel.close_button.is_visible_in_tree())
	assert_true(panel.still.is_visible_in_tree(), "the video's poster waits")
	var poster := panel.find_children("*", "Button", true, false).filter(func(b: Node) -> bool:
		return (b as Button).flat and (b as Control).is_visible_in_tree())
	assert_eq(poster.size(), 1, "the poster is a button")
	_press(poster[0])
	assert_eq(fake.calls[-1], "play")
	assert_eq(fake.videos[-1], fake.videos[0], "the same video again")
	assert_true(fake.autoplay_flags[-1])
	assert_eq(panel.session.shown, shown, "the same video does not count again")


func test_the_pages_close_stops_it_too() -> void:
	var parts: Array = await _playing()
	var panel: TheaterPanel = parts[0]
	var fake: FakePlayer = parts[1]
	fake.stopped.emit()
	assert_false(panel.player_on)
	assert_true(panel.still.is_visible_in_tree())
	assert_true(panel.is_open(), "the Theater stays")


func test_a_video_that_cant_play_says_so() -> void:
	var parts: Array = await _playing()
	var panel: TheaterPanel = parts[0]
	var fake: FakePlayer = parts[1]
	fake.failed.emit("150")
	assert_eq(panel.title_label.text, TheaterPanel.CANT_PLAY)


func test_the_game_holds_its_sound_while_a_video_is_on_the_screen() -> void:
	var parts: Array = await _playing()
	var panel: TheaterPanel = parts[0]
	var master := TheaterPanel.MASTER_BUS
	assert_true(AudioServer.is_bus_mute(master), "a video on the screen")
	panel.set_covered(true)
	assert_false(AudioServer.is_bus_mute(master), "the pause menu is heard")
	panel.set_covered(false)
	assert_true(AudioServer.is_bus_mute(master))
	_press(panel.close_button)
	assert_false(AudioServer.is_bus_mute(master), "CLOSE: the game again")
	_press(panel.next_button)
	assert_true(AudioServer.is_bus_mute(master))
	_press(panel.exit_button)
	assert_false(AudioServer.is_bus_mute(master), "EXIT: the game again")
	var desktop: TheaterPanel = await _panel(_profile(TEEN))
	desktop.open()
	assert_false(AudioServer.is_bus_mute(master), "a still makes no sound to hold")


func test_a_childs_videos_never_start_by_themselves() -> void:
	var parts: Array = await _playing(KID, TheaterRules.SWITCH_ON)
	var fake: FakePlayer = parts[1]
	assert_false(fake.autoplay_flags[0])
	fake.ended.emit()
	assert_eq(fake.videos.size(), 1, "no autoplay of the next video")


func test_menus_over_the_player_hide_it() -> void:
	var parts: Array = await _playing()
	var panel: TheaterPanel = parts[0]
	var fake: FakePlayer = parts[1]
	panel.set_covered(true)
	panel.set_covered(true)
	assert_eq(fake.calls.count("hide"), 1, "once")
	panel.set_covered(false)
	assert_eq(fake.calls[-1], "reveal")


func test_the_end_card_closes_the_player() -> void:
	var parts: Array = await _playing(KID, TheaterRules.SWITCH_ON)
	var panel: TheaterPanel = parts[0]
	var fake: FakePlayer = parts[1]
	for i in 5:
		_press(panel.next_button)
	assert_eq(panel.view, TheaterPanel.VIEW_END_CARD)
	assert_eq(fake.calls[-1], "close", "the card is never under a playing video")
	assert_false(AudioServer.is_bus_mute(TheaterPanel.MASTER_BUS))


func test_the_player_follows_a_resize() -> void:
	var parts: Array = await _playing()
	var fake: FakePlayer = parts[1]
	get_window().size = Vector2i(1280, 720)
	await wait_process_frames(3)
	assert_has(fake.calls, "set_rect")
	assert_true(TheaterRules.is_big_enough(fake.rects[-1]), "%s" % fake.rects[-1])


# --- Walking in and out (the director) -------------------------------------------------------

func _director(list: Dictionary = sample, saved: Array = [], service: Object = null) -> TheaterDirector:
	var d := TheaterDirector.new()
	d.feed_cache = CACHE
	if service:
		d.online = func() -> Object: return service
	add_child_autofree(d)
	var layer := CanvasLayer.new()
	add_child_autofree(layer)
	d.setup(MeadowsShape.new(12345), saved, layer, list)
	if d.panel:
		d.panel.opens_on_shorts = false   # owner #94: the channels' player, as before
	return d


func test_walking_in_opens_the_panel_and_walking_out_closes_it() -> void:
	var d := _director()
	assert_not_null(d.building)
	assert_not_null(d.panel)
	d.panel.profile = _profile(TEEN)
	d.panel.save_profile = func() -> void: _saves += 1
	d.panel.frees_mouse = false
	var c: Vector3i = d.site.pos
	var inside := Vector3(c.x + 0.5, c.y, c.z + 0.5)
	var where := [Vector3.INF]
	d.player_position = func() -> Vector3: return where[0]
	d.overlay_open = func() -> bool: return false
	await wait_process_frames(3)
	assert_false(d.panel.is_open(), "not spawned yet")
	where[0] = inside + Vector3(20, 0, 0)
	await wait_seconds(0.25)
	assert_false(d.panel.is_open(), "outside")
	where[0] = inside
	await wait_seconds(0.25)
	assert_true(d.panel.is_open(), "walked in")
	_press(d.panel.exit_button)
	await wait_seconds(0.25)
	assert_false(d.panel.is_open(), "EXIT keeps it closed while standing inside")
	where[0] = inside + Vector3(20, 0, 0)
	await wait_seconds(0.25)
	where[0] = inside
	await wait_seconds(0.25)
	assert_true(d.panel.is_open(), "walking in again opens it again")
	where[0] = inside + Vector3(0, 0, 20)
	await wait_seconds(0.25)
	assert_false(d.panel.is_open(), "walked out")


func test_a_menu_over_the_screen_hides_the_player() -> void:
	var d := _director(bundled)
	var fake := FakePlayer.new()
	d.panel.profile = _profile(TEEN)
	d.panel.is_mobile = true
	d.panel.backend = fake
	d.panel.frees_mouse = false
	var c: Vector3i = d.site.pos
	d.player_position = func() -> Vector3: return Vector3(c.x + 0.5, c.y, c.z + 0.5)
	var menu := [false]
	d.overlay_open = func() -> bool: return menu[0]
	await wait_seconds(0.25)
	assert_eq(fake.calls, ["play"])
	menu[0] = true
	await wait_seconds(0.25)
	assert_eq(fake.calls[-1], "hide")
	menu[0] = false
	await wait_seconds(0.25)
	assert_eq(fake.calls[-1], "reveal")


func test_the_director_places_the_theater_once_and_keeps_it() -> void:
	var d := _director()
	var saved := d.saved_site()
	assert_eq(saved, TheaterSite.to_save(TheaterSite.pick_for(MeadowsShape.new(12345))))
	var moved := [saved[0] + 7, saved[1], saved[2], saved[3]]
	var again := _director(sample, moved)
	assert_eq(again.saved_site(), moved, "a saved Theater stays where it is")
	assert_eq(again.building.global_position, Vector3(moved[0] + 0.5, moved[1], moved[2] + 0.5))


## M7 (the browser's freezes): a new world's site search took up to ~120 ms here in the world switch's frame. With
## search_later (the sandbox's) it runs on a worker; the Theater then stands where it always did, and the world is told
## where (site_placed) to save it.
func test_a_new_worlds_theater_is_searched_on_a_worker() -> void:
	var d := TheaterDirector.new()
	d.search_later = true
	add_child_autofree(d)
	var layer := CanvasLayer.new()
	add_child_autofree(layer)
	var placed: Array = []
	d.site_placed.connect(func(saved: Array) -> void: placed.append(saved))
	d.setup(MeadowsShape.new(12345), [], layer, sample)
	assert_null(d.building, "not in the frame of setup")
	assert_not_null(d.panel, "the panel is there already")
	assert_eq(d.saved_site(), [])
	await wait_until(func() -> bool: return not placed.is_empty(), 5.0)
	var expected := TheaterSite.to_save(TheaterSite.pick_for(MeadowsShape.new(12345)))
	assert_eq(placed, [expected], "once, where it always stood")
	assert_eq(d.saved_site(), expected)
	assert_not_null(d.building)
	assert_eq(d.building.global_position, Vector3(expected[0] + 0.5, expected[1], expected[2] + 0.5))


func test_a_saved_theater_stands_at_once_even_when_searching_later() -> void:
	var d := TheaterDirector.new()
	d.search_later = true
	add_child_autofree(d)
	var layer := CanvasLayer.new()
	add_child_autofree(layer)
	d.setup(MeadowsShape.new(12345), [31, 44, -7, 3], layer, sample)
	assert_not_null(d.building)
	assert_eq(d.saved_site(), [31, 44, -7, 3])


func test_the_kill_switch_builds_nothing() -> void:
	var off := sample.duplicate(true)
	off.enabled = false
	var d := _director(off, [31, 44, -7, 3])
	assert_null(d.building)
	assert_null(d.panel)
	assert_eq(d.saved_site(), [31, 44, -7, 3], "the place is kept for when it comes back")
	d.player_position = func() -> Vector3: return Vector3(31.5, 44, -6.5)
	await wait_seconds(0.25)
	assert_true(true, "nothing happens inside a hidden Theater")


## Owner #89: an online game reads the server's list (and keeps it); the panel plays it from its next opening.
func test_an_online_game_reads_the_servers_list() -> void:
	var service := FakeService.new()
	add_child_autofree(service)
	service.status = OnlineService.ONLINE
	var server_list := {"enabled": true, "source": "server", "channels": [{"id": "easycraft_tv", "title": "From the server",
		"platform": "youtube", "videos": [{"id": "fYa-hmNzlAQ", "title": "Who is Paxi?", "made_for_kids": true}]}]}
	service.backend.reply = {"ok": true, "list": server_list}
	var d := _director(bundled, [], service)
	await wait_process_frames(3)
	assert_eq(service.backend.calls, 1, "asked once")
	assert_eq(d.list.source, TheaterChannels.SOURCE_SERVER)
	assert_eq(d.panel.list.channels[0].title, "From the server", "the panel plays it next")
	assert_eq(TheaterFeed.load_best(CACHE).channels[0].title, "From the server", "kept for the next start")


func test_a_game_that_signs_in_later_reads_it_then() -> void:
	var service := FakeService.new()
	add_child_autofree(service)
	service.backend.reply = {"ok": true, "list": null}
	var d := _director(bundled, [], service)
	await wait_process_frames(3)
	assert_eq(service.backend.calls, 0, "offline: nothing asked")
	service.status = OnlineService.ONLINE
	service.status_changed.emit(OnlineService.ONLINE)
	await wait_process_frames(2)
	assert_eq(service.backend.calls, 1, "asked once online")
	assert_eq(d.list.source, TheaterChannels.SOURCE_BUNDLED, "no list on the server: the bundled one stays")
