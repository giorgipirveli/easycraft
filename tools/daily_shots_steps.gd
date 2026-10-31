extends Node
## The steps of tools/daily_shots.gd (a Node, so it may use the autoloads and the game's classes).

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")

var _out := ""
var _panel: PanelContainer
var _ui: Control
var _profile := ProfileData.new()


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_window().size = Vector2i(1600, 720) if OS.get_cmdline_user_args().has("--wide") else Vector2i(1280, 720)
	_out = ProjectSettings.globalize_path("user://daily_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	_stage()
	_profile.school.grade = 4
	_profile.invite.code = "BLUE-OTTER-42"
	var today := DailyMission.today()
	for d: int in [today - 5, today - 4, today - 2]:
		for i in DailyMission.SIZE:
			_profile.daily.answer(d, 4, i != 2)
	# The School: the map's button, the intro, a question, the card.
	var school := SchoolScreen.new()
	school.profile = _profile
	school.save_profile = func() -> void: pass
	school.next_seed = func() -> int: return 11
	_show(school)
	await _shot("school_map", func() -> void: school.show_map("maths"))
	await _shot("daily_intro", func() -> void: school.show_daily())
	school.daily.show_round()
	await _wait(0.4)
	await _save("daily_question_1")
	for right: bool in [true, true, false, true, true]:
		school.daily.exercise_panel.answered.emit(right)
		await _wait(0.1)
	await _wait(0.6)
	await _save("daily_card_page")
	var img: Image = await CardPicture.render(self, DailyCard.new(today, 4, _profile.daily.stars_of(today), "BLUE-OTTER-42"),
		DailyPage.CARD_PX)
	_keep(img, "daily_card_picture")
	# Postcards: the School's, and one offered in a world.
	await _shot("postcard_school", func() -> void: school.show_postcard(PostcardRules.unit("g4.maths.big_numbers", "Big numbers")))
	img = await CardPicture.render(self, PostcardView.new("I landed on the Moon!", "BLUE-OTTER-42", _moon()), PostcardPage.CARD_PX)
	_keep(img, "postcard_picture")
	_clear_panel()
	var offer := PostcardOffer.offer(_ui, PostcardRules.landed("moon"), _profile)
	offer.frees_mouse = false
	offer.capture = func() -> Image: return _moon().get_image()
	await _wait(0.4)
	await _save("postcard_offer")
	offer.make_postcard()
	await _wait(0.6)
	await _save("postcard_over_the_game")
	offer.close()
	await _friends()
	get_tree().quit()


func _friends() -> void:
	var server := FakeServer.new()
	var ids: Array[String] = []
	for n: String in ["Alex_7", "Sam_22", "Mia_5", "Bo_9", "Kim_3"]:
		ids.append(server.make_account("dev-" + n, n))
	for i in range(1, ids.size()):
		server.befriend(ids[0], ids[i])
	var s: Array[OnlineService] = []
	for n: String in ["Alex_7", "Sam_22", "Mia_5", "Bo_9"]:
		s.append(_service(server, "dev-" + n, n))
		await s[-1].sign_in()
	# Days together, a study buddy, presents, a moment to cheer, a crew with its week.
	for d in 8:
		server.soc_day = 20_700 + d
		for k in [0, 1]:
			SocialSender.learned("", s[k].profile)
			s[k].profile.social.learned_day = 20_700 + d
			await s[k].send_social_events()
	await s[0].study_buddy("ask", ids[1])
	await s[1].study_buddy("yes", ids[0])
	await s[1].send_present(ids[0], "buddy_egg")
	await s[2].send_present(ids[0], "rocket_part")
	SocialSender.moment(PostcardRules.landed("moon"), s[2].profile)
	await s[2].send_social_events()
	SocialSender.moment(PostcardRules.unit("g4.maths.big_numbers", "Big numbers"), s[3].profile)
	await s[3].send_social_events()
	var made := await s[0].crew_action("make", {"adjective": "Brave", "noun": "Comets", "badge": "rocket"})
	for k in [1, 2]:
		await s[0].crew_action("invite", {"user_id": ids[k]})
		await s[k].crew_action("join", {"crew": str(made.crew.id)})
	server.soc[ids[1]].week = {"days": 3, "units": ["g4.maths.big_numbers", "g4.maths.multiply"]}
	server.soc[ids[2]].week = {"days": 1, "units": []}
	var page := FriendsPage.new()
	page.service = s[0]
	_show(page)
	for i in 40:
		await _wait(0.05)
		if page.view == FriendsPage.FRIENDS:
			break
	await _wait(0.3)
	await _save("friends_tab")
	await _shot("friends_cheer", func() -> void: page.show_cheer(page.info.feed[0]))
	await _shot("friends_gift", func() -> void: page.show_pick_present(page.info.friends[0]))
	await _shot("friends_presents", func() -> void: page.show_presents())
	await _shot("friends_crew", func() -> void: page.show_crew())
	await _shot("friends_make_crew", func() -> void: page.show_make_crew())


func _service(server: RefCounted, device: String, username: String) -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.profile = ProfileData.new()
	s.profile.username = username
	s.profile.age_band = AgeBand.TEEN_PLUS
	s.save_profile = func() -> void: pass
	s.prefs_path = "user://daily_shots_%s.json" % device
	s.in_online_world = func() -> bool: return false
	add_child(s)
	return s


## A stand-in photo of the Moon (a grey disc on a black sky) for the postcards.
func _moon() -> ImageTexture:
	var img := Image.create_empty(640, 360, false, Image.FORMAT_RGB8)
	img.fill(Color(0.02, 0.02, 0.06))
	for y in 360:
		for x in 640:
			var d := Vector2(x - 320, y - 180).length()
			if d < 120.0:
				img.set_pixel(x, y, Color(0.72, 0.72, 0.7).darkened(0.2 * sin(x * 0.07) * sin(y * 0.05)))
	return ImageTexture.create_from_image(img)


func _stage() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.theme = UiKit.theme()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_ui)
	var back := ColorRect.new()
	back.color = Color(0.36, 0.55, 0.42)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(back)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(center)
	_panel = PanelContainer.new()
	center.add_child(_panel)


func _show(c: Control) -> void:
	_clear_panel()
	_panel.visible = true
	_panel.add_child(c)


func _clear_panel() -> void:
	for c in _panel.get_children():
		_panel.remove_child(c)
		c.queue_free()
	_panel.visible = false


func _keep(img: Image, shot: String) -> void:
	if img == null:
		print("DAILY_SHOT %s: nothing drawn" % shot)
		return
	var path := _out.path_join(shot + ".png")
	img.save_png(path)
	print("DAILY_SHOT %s %dx%d" % [path, img.get_width(), img.get_height()])


func _shot(name: String, show: Callable) -> void:
	show.call()
	await _wait(0.4)
	await _save(name)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _save(shot: String) -> void:
	await RenderingServer.frame_post_draw
	_keep(get_viewport().get_texture().get_image(), shot)
