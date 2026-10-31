extends GutTest
## Visiting a friend's showcase (M4 Wave 3, agent I; spec §17.5, research T3): a small island of its own
## with the showcase in the middle, the friend's name on a sign, the friend's buddy waving where it waits,
## the visitor's own player; read-only (no edit of any kind reaches it), no monsters or animals; the bar's
## STICKER leaves a preset sticker, REPORT keeps the build for the reviewer, LEAVE goes back.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const VISIT := preload("res://world/visit/visit.tscn")

var DIR := "user://test_visit_world_%d/" % OS.get_process_id()
var server: RefCounted
var service: OnlineService
var owner_id := ""
var left: Array = []


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	owner_id = server.make_account("dev-mia", "Mia_2")
	server.make_account("dev-me", "Hopper")
	server.befriend(owner_id, server.id_of("Hopper"))
	service = OnlineService.new()
	service.backend = FakeBackend.new(server)
	service.device_id = "dev-me"
	service.profile = ProfileData.new()
	service.profile.username = "Hopper"
	service.save_profile = func() -> void: pass
	service.prefs_path = DIR + "me.json"
	service.gift_book = GiftStampBook.new()
	service.gift_book_path = DIR + "gifts.json"
	add_child_autofree(service)
	service.prefs.safe_card_seen = int(Time.get_unix_time_from_system())
	assert_eq(await service.sign_in(), "")
	left.clear()


func after_each() -> void:
	PlatformRules.simulated = {}
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


## A 6 x 4 x 6 area: a grass floor with a hole, a planks tower, and Mia's crystal buddy at (4, 1, 4).
func _showcase() -> Dictionary:
	var area := {}
	for x in 6:
		for z in 6:
			if not (x == 0 and z == 0):
				area[Vector3i(x, 0, z)] = BlockIds.GRASS
	for y in range(1, 4):
		area[Vector3i(2, y, 2)] = BlockIds.PLANKS
	var buddy := BuildCodec.encode({Vector3i(0, 0, 0): BlockIds.CRYSTAL, Vector3i(0, 1, 0): BlockIds.CRYSTAL})
	var raw := {"owner_id": owner_id, "owner_username": "Mia_2", "build": BuildCodec.encode(area),
		"buddy": {"build": buddy, "at": [4, 1, 4]}}
	return GiftRules.showcase(raw)


func _visit() -> VisitWorld:
	var v: VisitWorld = VISIT.instantiate()
	v.showcase = _showcase()
	v.service = service
	v.leave_to = func() -> void: left.append(true)
	add_child_autofree(v)
	# M5 Task 3: wait for what the tests read, not for a time. Under a load of 28-35 the visitor could be standing
	# (its own column meshed) while the showcase's corner, 12+ blocks away, was not loaded yet: get_block read air
	# there ("the island's grass stays" failed now and then). A long limit costs nothing when the world is quick.
	await wait_until(func() -> bool: return v.player.is_spawned() and _showcase_loaded(v), 90.0)
	await wait_physics_frames(2)
	return v


## Every cell of the showcase's box (and the layer under it) is loaded, so get_block reads the island, not air.
func _showcase_loaded(v: VisitWorld) -> bool:
	var o := v.generator.origin
	for corner: Vector3i in [Vector3i(0, -1, 0), Vector3i(5, -1, 0), Vector3i(0, -1, 5), Vector3i(5, -1, 5),
			Vector3i(0, 5, 0), Vector3i(5, 5, 0), Vector3i(0, 5, 5), Vector3i(5, 5, 5)]:
		if not v.world.is_editable(o + corner):
			return false
	return true


func test_the_showcase_stands_on_the_island_with_the_friends_name_on_a_sign() -> void:
	var v := await _visit()
	assert_true(v.player.is_spawned(), "the visitor arrives")
	var o := v.generator.origin
	assert_eq(o.y, VisitGenerator.GROUND_TOP, "its bottom layer is the ground's")
	assert_eq(v.world.get_block(o + Vector3i(2, 2, 2)), BlockIds.PLANKS, "the tower")
	assert_eq(v.world.get_block(o), BlockIds.GRASS, "where the showcase has air at the bottom, the island's grass stays")
	assert_eq(v.world.get_block(o + Vector3i(2, 5, 2)), BlockIds.AIR)
	assert_string_contains(v.sign_label.text, "Mia_2")
	var feet := v.player.global_position
	assert_almost_eq(feet.y, VisitGenerator.GROUND_TOP + 1.0, 1.0, "on the grass")
	assert_true(Vector2(feet.x, feet.z).distance_to(Vector2.ZERO) > 10.0, "in front of it, not inside")


func test_the_friends_buddy_waits_there_and_waves() -> void:
	var v := await _visit()
	assert_not_null(v.buddy)
	assert_true(v.buddy.visiting)
	assert_eq(v.buddy.buddy_name, BuddyNames.name_for(BuildCodec.decode(v.showcase.buddy.build, BuildCodec.BUDDY)),
		"named from its blocks: no name travels")
	var start := v.buddy.global_position
	await wait_seconds(1.0)
	assert_lt(Vector2(v.buddy.global_position.x, v.buddy.global_position.z).distance_to(Vector2(start.x, start.z)), 0.3,
		"it stays in the showcase, it does not follow the visitor")


func test_nothing_can_change_in_a_visit() -> void:
	var v := await _visit()
	var o := v.generator.origin
	var tower := o + Vector3i(2, 2, 2)
	assert_null(Session.world, "the visit world never registers with Session")
	assert_false(Session.request_set_block(tower, BlockIds.AIR))
	assert_false(Session.request_set_blocks([[tower, BlockIds.AIR], [o + Vector3i(1, 1, 1), BlockIds.STONE]]))
	assert_false(Session.request_door(tower))
	var interactor: BlockInteractor = v.player.get_node("BlockInteractor")
	assert_eq(interactor.hotbar, [ItemIds.WAND] as Array[int], "only the wand, which sparkles")
	var centre := v.get_viewport().get_visible_rect().size * 0.5
	interactor.place_at_screen(centre)
	interactor.break_at_screen(centre)
	interactor.hotbar = [ItemIds.STAMP_HOUSE] as Array[int]
	interactor.place_at_screen(centre)
	await wait_physics_frames(2)
	assert_eq(v.world.get_block(tower), BlockIds.PLANKS)
	assert_eq(v.world.get_block(o + Vector3i(1, 1, 1)), BlockIds.AIR)
	assert_eq(v.find_children("*", "Monster", true, false).size(), 0, "no monsters")
	assert_eq(get_tree().get_nodes_in_group(&"animals").size(), 0, "no animals")
	assert_false(v.hud.hotbar.visible, "no building here")


func test_a_sticker_goes_into_the_friends_guestbook() -> void:
	server.showcases[owner_id] = {"build": _showcase().build, "size": [6, 4, 6], "count": 38, "updated_ms": 1}
	var v := await _visit()
	(v.panel.find_child("Sticker", true, false) as Button).pressed.emit()
	await wait_process_frames(1)
	assert_true(v.panel.sheet_open(), "the eight stickers show")
	assert_eq(v.panel.find_children("Sticker_*", "Button", true, false).size(), GiftRules.STICKERS.size())
	(v.panel.find_child("Sticker_rainbow", true, false) as Button).pressed.emit()
	await wait_until(func() -> bool: return not v.panel.sheet_open(), 5.0)
	var book: Array = server.guestbooks.get(owner_id, [])
	assert_eq(book.size(), 1)
	assert_eq(book[0].sticker, "rainbow")
	assert_eq(book[0].from_username, "Hopper")


func test_report_keeps_the_build_for_the_reviewer_and_leave_goes_back() -> void:
	var v := await _visit()
	(v.panel.find_child("Report", true, false) as Button).pressed.emit()
	await wait_process_frames(1)
	(v.panel.find_child("Reason_scary", true, false) as Button).pressed.emit()
	await wait_until(func() -> bool: return server.build_reports.size() == 1, 5.0)
	assert_eq(server.build_reports[0].what, "showcase")
	assert_eq(server.build_reports[0].reason, "scary")
	assert_true(service.is_muted(owner_id), "muted on this device")
	(v.panel.find_child("Leave", true, false) as Button).pressed.emit()
	assert_eq(left, [true])


func test_the_bar_never_covers_a_hud_button() -> void:
	var v := await _visit()
	await wait_process_frames(2)
	var bar: Control = v.panel.blockers()[0]
	for b: Control in v.hud.find_children("*", "TouchButton", true, false):
		if b.is_visible_in_tree():
			assert_false(bar.get_global_rect().intersects(b.get_global_rect()), "the bar and %s" % b.name)


## M7 (spec §20.3): a phone browser gets the touch HUD exactly as the phone game; a desktop browser (and the desktop)
## keyboard and mouse.
func test_a_phone_browser_gets_the_thumb_stick() -> void:
	PlatformRules.simulated = {PlatformRules.WEB: true, PlatformRules.WEB_IOS: true, PlatformRules.TOUCH_SCREEN: true}
	var v := await _visit()
	assert_true(v.hud.joystick.visible, "the thumb stick")
	assert_true(v.hud.jump_button.visible)


func test_a_desktop_browser_gets_keyboard_and_mouse() -> void:
	PlatformRules.simulated = {PlatformRules.WEB: true, PlatformRules.WEB_WINDOWS: true}
	var v := await _visit()
	assert_false(v.hud.joystick.visible, "no thumb stick")
