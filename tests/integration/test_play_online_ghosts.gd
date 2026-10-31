extends GutTest
## M4 ghost races offline (spec §17.5: "works offline against ghosts already downloaded"): when PLAY ONLINE can't
## reach the game, FRIENDS' RACES opens the friends' showcases kept on this device, and a tap visits one to race
## its ghosts, no server needed. The page fits the main menu's panel with big buttons; with nothing kept it is
## not offered.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const PANEL_CONTENT := Vector2(1280 - 56, 720 - 130 - 56)   # the main menu's panel (test_online_screens.gd)
const BUILD := "AQEBAQHLAQ=="                                # any showcase text: the book keeps it as it came

var DIR := "user://test_play_online_ghosts_%d/" % OS.get_process_id()
var server: RefCounted
var service: OnlineService
var screen: PlayOnlineScreen


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	server.make_account("dev-me", "Hopper")
	server.down = true
	service = OnlineService.new()
	service.backend = FakeBackend.new(server)
	service.device_id = "dev-me"
	service.profile = ProfileData.new()
	service.profile.username = "Hopper"
	service.save_profile = func() -> void: pass
	service.prefs_path = DIR + "me.json"
	service.gift_book = GiftStampBook.new()
	service.gift_book_path = DIR + "gifts.json"
	service.ghost_book = GhostBook.new()
	service.ghost_book_path = DIR + "ghosts.json"
	add_child_autofree(service)


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func _ghost(id: String) -> RaceGhost:
	var g := RaceGhost.new()
	g.id = id
	g.start = Vector3i.ZERO
	g.finish = Vector3i.ZERO
	g.ms = 1000
	for i in 6:
		g.points.append(Vector3.ZERO)
	return g


func _screen() -> PlayOnlineScreen:
	var holder := Control.new()
	holder.theme = UiKit.theme()
	holder.size = Vector2(1280, 720)
	add_child_autofree(holder)
	var panel := PanelContainer.new()
	holder.add_child(panel)
	screen = PlayOnlineScreen.new()
	screen.service = service
	screen.visit_starts = false
	panel.add_child(screen)
	await wait_until(func() -> bool: return screen.view == PlayOnlineScreen.VIEW_FAILED, 5.0)
	await wait_process_frames(2)
	return screen


func test_no_races_kept_no_button() -> void:
	var s := await _screen()
	assert_null(s.button("FRIENDS'"), "nothing kept: nothing offered")
	assert_not_null(s.button("TRY AGAIN"))


func test_offline_the_kept_races_open_and_a_tap_visits_one() -> void:
	service.ghost_book.names_ok = true
	service.ghost_book.keep_showcase("u-mia", "Mia_2", BUILD, [_ghost("h1_a")] as Array[RaceGhost], 100)
	service.ghost_book.keep_showcase("u-leo", "Leo_4", BUILD, [_ghost("h2_a"), _ghost("h2_b")] as Array[RaceGhost], 200)
	var s := await _screen()
	var open := s.button("FRIENDS'")
	assert_not_null(open, "offered on the can't-connect page")
	open.pressed.emit()
	await wait_process_frames(3)
	assert_eq(s.view, PlayOnlineScreen.VIEW_RACES)
	var size := s.page.get_combined_minimum_size()
	assert_lte(size.y, PANEL_CONTENT.y, "fits the menu's panel (%d)" % size.y)
	assert_lte(size.x, PANEL_CONTENT.x)
	for b: Button in s.page.find_children("*", "Button", true, false):
		assert_gte(b.size.x, OnlineUi.MIN_WIDTH, "big: %s" % b.name)
	var visits: Array = []
	s.visit_requested.connect(func(sc: Dictionary) -> void: visits.append(sc))
	var leo := s.button("Leo_4")
	assert_not_null(leo, "the newest first, by name")
	leo.pressed.emit()
	assert_eq(visits.size(), 1)
	assert_eq(visits[0].owner, "Leo_4")
	assert_true(visits[0].offline)
	assert_eq((visits[0].ghosts as Array).size(), 2)
	s.button("BACK").pressed.emit()
	await wait_process_frames(2)
	assert_eq(s.view, PlayOnlineScreen.VIEW_FAILED, "back to the can't-connect page")


func test_no_names_for_a_viewer_who_may_not_see_them() -> void:
	service.ghost_book.names_ok = false
	service.ghost_book.keep_showcase("u-mia", "Mia_2", BUILD, [_ghost("h1_a")] as Array[RaceGhost], 100)
	var s := await _screen()
	s.button("FRIENDS'").pressed.emit()
	await wait_process_frames(2)
	assert_null(s.button("Mia_2"))
	assert_not_null(s.button("A FRIEND"))
