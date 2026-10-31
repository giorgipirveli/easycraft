extends GutTest
## M4 ghost races through SHARE (M4 I's panel; spec §17.5): MY SHOWCASE takes the child's best runs on the
## courses inside the golden frame along (friends race them when they visit), and GIFT A BUILD of a whole course
## (START and FINISH in the picked build) sends the child's race with it. Through the real OnlineService against
## the fake server, a stand-in world of cells.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const START := Vector3i(3, 10, 3)
const FINISH := Vector3i(8, 10, 3)
const WORLD := "sandbox_1:7"

var DIR := "user://test_share_ghosts_%d/" % OS.get_process_id()
var server: RefCounted
var service: OnlineService
var panel: SharePanel
var world: CellWorld
var spot: Node3D
var interactor: BlockInteractor
var book: CourseBook
var toasts: Array = []
var mia := ""


class CellWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.GRASS if pos.y < 10 else BlockIds.AIR)

	func copy_box(origin: Vector3i, size: Vector3i) -> VoxelBuffer:
		var buf := VoxelBuffer.new()
		buf.create(size.x, size.y, size.z)
		for x in size.x:
			for y in size.y:
				for z in size.z:
					buf.set_voxel(get_block(origin + Vector3i(x, y, z)), x, y, z, VoxelBuffer.CHANNEL_TYPE)
		return buf


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	var me: String = server.make_account("dev-me", "Hopper")
	mia = server.make_account("dev-mia", "Mia_2")
	server.befriend(me, mia)
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
	service.prefs.safe_card_seen = int(Time.get_unix_time_from_system())
	assert_eq(await service.sign_in(), "")
	await service.refresh_friends()
	world = CellWorld.new()
	add_child_autofree(world)
	for x in range(START.x, FINISH.x + 1):         # a planks course from START to FINISH
		world.cells[Vector3i(x, 10, 3)] = BlockIds.PLANKS
	world.cells[START] = BlockIds.START
	world.cells[FINISH] = BlockIds.FINISH
	book = CourseBook.new()
	var run := RecordedRun.new(CourseRules.top_of(START))
	for i in 31:
		run.add(CourseRules.top_of(START).lerp(CourseRules.top_of(FINISH), i / 30.0))
	book.finished(START, FINISH, 3000, "Hopper", run, true)
	spot = Node3D.new()
	add_child_autofree(spot)
	spot.global_position = Vector3(4.5, 11.0, 4.5)
	interactor = BlockInteractor.new()
	autofree(interactor)
	panel = SharePanel.new()
	panel.service = service
	panel.world = world
	panel.player = spot
	panel.interactor = interactor
	panel.outline = BuildOutline.new()
	add_child_autofree(panel.outline)
	panel.player_toast = func(t: String) -> void: toasts.append(t)
	panel.course_book = func() -> CourseBook: return book
	panel.world_key = WORLD
	panel.look_code = func() -> String: return "{\"hat\":\"crown\"}"
	add_child_autofree(panel)
	toasts.clear()


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)
	Audio.stop_all()


func _press(name_pattern: String) -> void:
	var b := panel.find_child(name_pattern, true, false) as Button
	assert_not_null(b, name_pattern)
	if b:
		b.pressed.emit()


func test_show_it_takes_my_best_runs_in_the_frame_along() -> void:
	panel.open()
	_press("MyShowcase")
	await panel.publish()
	assert_true(server.showcases.has(service.backend.user_id()), "the showcase is up")
	var ghosts: Array = server.showcase_ghosts.get(service.backend.user_id(), [])
	assert_eq(ghosts.size(), 1, "my course's best run went with it")
	assert_eq(int(ghosts[0].ms), 3000)
	assert_eq(ghosts[0].look, "{\"hat\":\"crown\"}", "in my look")
	assert_eq(toasts.back(), "Your showcase is up! Friends can visit it and race your course.")
	assert_true(service.ghost_book.in_my_showcase(WORLD, START), "remembered: a new best can replace it")


func test_a_showcase_without_my_courses_shares_no_race() -> void:
	book = CourseBook.new()
	panel.open()
	_press("MyShowcase")
	await panel.publish()
	assert_false(server.calls.has("share_ghost"))
	assert_eq(toasts.back(), "Your showcase is up! Friends can visit it now.")


func test_gifting_a_whole_course_sends_my_race_with_it() -> void:
	panel.open()
	_press("GiftABuild")
	panel.pick_cell(START)
	assert_eq((panel.picked.blocks as Dictionary).size(), 6)
	assert_not_null(panel.picked_ghost, "START and FINISH are in it, with my run")
	assert_not_null(panel.find_child("RaceComes", true, false), "the panel says the race comes too")
	_press("SendToAFriend")
	_press("Friend_Mia_2")
	await wait_until(func() -> bool: return not (server.gifts.get(mia, []) as Array).is_empty(), 5.0)
	var gift: Dictionary = server.gifts[mia][0]
	assert_true(gift.has("ghost"))
	assert_eq(gift.ghost.start, [0, 0, 0], "in the build's cells")
	assert_eq(gift.ghost.finish, [5, 0, 0])


func test_a_build_without_a_whole_course_is_a_plain_gift() -> void:
	world.cells[Vector3i(20, 10, 3)] = BlockIds.PLANKS
	world.cells[Vector3i(20, 11, 3)] = BlockIds.PLANKS
	panel.open()
	_press("GiftABuild")
	panel.pick_cell(Vector3i(20, 10, 3))
	assert_null(panel.picked_ghost)
	assert_null(panel.find_child("RaceComes", true, false))
	_press("SendToAFriend")
	_press("Friend_Mia_2")
	await wait_until(func() -> bool: return not (server.gifts.get(mia, []) as Array).is_empty(), 5.0)
	assert_false((server.gifts[mia][0] as Dictionary).has("ghost"))
	assert_false(server.calls.has("share_ghost"))
